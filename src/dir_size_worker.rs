use crate::cxxqt_object::qobject;
use crate::file_row::PendingDirectorySizeUpdate;
use crate::file_size_status::DirectorySizeStatusUpdate;
use crate::formatting::format_size;
use crate::signals::bump_update_generation;
use cxx_qt::CxxQtType;
use std::collections::HashSet;
use std::fs;
use std::path::{Path, PathBuf};
use std::time::{Duration, Instant};

pub(crate) struct DirectorySizeBatch {
    qt_thread: cxx_qt::CxxQtThread<qobject::FolderBrowserController>,
    generation: u64,
    pending: Vec<PendingDirectorySizeUpdate>,
    last_flush: Instant,
}

impl DirectorySizeBatch {
    pub(crate) fn new(qt_thread: cxx_qt::CxxQtThread<qobject::FolderBrowserController>, generation: u64) -> Self {
        Self { qt_thread, generation, pending: Vec::new(), last_flush: Instant::now() }
    }

    pub(crate) fn push(&mut self, row_index: usize, size_bytes: Option<u64>, status: DirectorySizeStatusUpdate) {
        self.pending.push(PendingDirectorySizeUpdate { row_index, size_bytes, status });
    }

    pub(crate) fn flush_if_needed(&mut self, max_pending: usize, max_elapsed: Duration) {
        if self.pending.len() >= max_pending || self.last_flush.elapsed() >= max_elapsed { self.flush(); }
    }

    pub(crate) fn flush(&mut self) {
        if self.pending.is_empty() { return; }
        let generation = self.generation;
        let updates = std::mem::take(&mut self.pending);
        self.last_flush = Instant::now();
        let _ = self.qt_thread.queue(move |mut controller| {
            if controller.rust().scan_generation != generation { return; }
            let rows = &mut controller.as_mut().rust_mut().rows;
            for update in updates {
                if let Some(row) = rows.get_mut(update.row_index) {
                    row.size_bytes = update.size_bytes;
                    row.size_text = format_size(update.size_bytes);
                    row.size_status = update.status.to_size_status();
                }
            }
            bump_update_generation(controller.as_mut());
        });
    }
}

pub(crate) fn calculate_directory_size<F>(directory: &Path, follow_symlinks: bool, mut progress: F) -> Result<u64, std::io::Error>
where
    F: FnMut(u64),
{
    let mut total: u64 = 0;
    let mut stack: Vec<PathBuf> = vec![directory.to_path_buf()];
    let mut visited_directories: HashSet<PathBuf> = HashSet::new();

    while let Some(current_directory) = stack.pop() {
        let directory_identity = if follow_symlinks {
            fs::canonicalize(&current_directory).unwrap_or_else(|_| current_directory.clone())
        } else {
            current_directory.clone()
        };
        if !visited_directories.insert(directory_identity) { continue; }

        let read_dir = match fs::read_dir(&current_directory) { Ok(read_dir) => read_dir, Err(_) => continue };
        for entry_result in read_dir {
            let entry = match entry_result { Ok(entry) => entry, Err(_) => continue };
            let file_type = match entry.file_type() { Ok(file_type) => file_type, Err(_) => continue };
            let path = entry.path();
            if file_type.is_dir() {
                stack.push(path);
            } else if file_type.is_file() {
                if let Ok(metadata) = entry.metadata() {
                    total = total.saturating_add(metadata.len());
                    progress(total);
                }
            } else if follow_symlinks && file_type.is_symlink() {
                // Safe symlink-follow mode:
                // the initial directory may itself be a symlinked folder, but nested
                // symlink entries are not descended into during size calculation.
                // This avoids huge scans and symlink cycles while still allowing
                // top-level symlinked folders to be opened and measured.
                continue;
            }
        }
    }
    Ok(total)
}
