/// CXX-Qt QObject bridge for the folder-browser scaffold.
///
/// Rust stores structured file rows, exposes them through invokable accessors,
/// and calculates directory sizes on a throttled background thread.
#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qproperty(i32, click_count, cxx_name = "clickCount")]
        #[qproperty(QString, current_path, cxx_name = "currentPath")]
        #[qproperty(QString, status_text, cxx_name = "statusText")]
        #[qproperty(i32, row_count, cxx_name = "rowCount")]
        #[qproperty(i32, update_generation, cxx_name = "updateGeneration")]
        #[namespace = "folder_browser"]
        type FolderBrowserController = super::FolderBrowserControllerRust;

        #[qinvokable]
        #[cxx_name = "incrementClickCount"]
        fn increment_click_count(self: Pin<&mut Self>);

        #[qinvokable]
        #[cxx_name = "setPathFromQml"]
        fn set_path_from_qml(self: Pin<&mut Self>, path: &QString);

        #[qinvokable]
        #[cxx_name = "scanPath"]
        fn scan_path(self: Pin<&mut Self>, path: &QString);

        #[qinvokable]
        #[cxx_name = "fileName"]
        fn file_name(&self, row: i32) -> QString;

        #[qinvokable]
        #[cxx_name = "fileKind"]
        fn file_kind(&self, row: i32) -> QString;

        #[qinvokable]
        #[cxx_name = "fileSizeBytes"]
        fn file_size_bytes(&self, row: i32) -> i64;

        #[qinvokable]
        #[cxx_name = "fileSizeText"]
        fn file_size_text(&self, row: i32) -> QString;

        #[qinvokable]
        #[cxx_name = "fileSizeStatus"]
        fn file_size_status(&self, row: i32) -> QString;

        #[qinvokable]
        #[cxx_name = "fileModifiedSecs"]
        fn file_modified_secs(&self, row: i32) -> i64;

        #[qinvokable]
        #[cxx_name = "filePath"]
        fn file_path(&self, row: i32) -> QString;

        #[qinvokable]
        #[cxx_name = "fileIsDir"]
        fn file_is_dir(&self, row: i32) -> bool;
    }

    impl cxx_qt::Threading for FolderBrowserController {}
}

use core::pin::Pin;
use cxx_qt::{CxxQtType, Threading};
use cxx_qt_lib::QString;
use crate::formatting::{format_size, normalize_local_path};
use std::fs;
use std::path::{Path, PathBuf};
use std::time::{Duration, Instant, UNIX_EPOCH};

#[derive(Default)]
pub struct FolderBrowserControllerRust {
    click_count: i32,
    current_path: QString,
    status_text: QString,
    row_count: i32,
    update_generation: i32,
    rows: Vec<FileRow>,
    scan_generation: u64,
}

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
enum SizeStatus {
    #[default]
    File,
    Unknown,
    Scanning,
    Done,
    Error,
}

impl SizeStatus {
    fn as_str(self) -> &'static str {
        match self {
            SizeStatus::File => "file",
            SizeStatus::Unknown => "unknown",
            SizeStatus::Scanning => "scanning",
            SizeStatus::Done => "done",
            SizeStatus::Error => "error",
        }
    }
}

#[derive(Clone, Debug, Default)]
struct FileRow {
    name: String,
    kind: String,
    size_bytes: Option<u64>,
    size_text: String,
    size_status: SizeStatus,
    modified_secs: Option<u64>,
    path: PathBuf,
    is_dir: bool,
}

#[derive(Clone, Copy, Debug)]
enum DirectorySizeStatusUpdate {
    Scanning,
    Done,
    Error,
}

impl DirectorySizeStatusUpdate {
    fn to_size_status(self) -> SizeStatus {
        match self {
            DirectorySizeStatusUpdate::Scanning => SizeStatus::Scanning,
            DirectorySizeStatusUpdate::Done => SizeStatus::Done,
            DirectorySizeStatusUpdate::Error => SizeStatus::Error,
        }
    }
}

#[derive(Clone, Debug)]
struct PendingDirectorySizeUpdate {
    row_index: usize,
    size_bytes: Option<u64>,
    status: DirectorySizeStatusUpdate,
}

struct DirectorySizeBatch {
    qt_thread: cxx_qt::CxxQtThread<qobject::FolderBrowserController>,
    generation: u64,
    pending: Vec<PendingDirectorySizeUpdate>,
    last_flush: Instant,
}

impl DirectorySizeBatch {
    fn new(
        qt_thread: cxx_qt::CxxQtThread<qobject::FolderBrowserController>,
        generation: u64,
    ) -> Self {
        Self {
            qt_thread,
            generation,
            pending: Vec::new(),
            last_flush: Instant::now(),
        }
    }

    fn push(&mut self, row_index: usize, size_bytes: Option<u64>, status: DirectorySizeStatusUpdate) {
        self.pending.push(PendingDirectorySizeUpdate {
            row_index,
            size_bytes,
            status,
        });
    }

    fn flush_if_needed(&mut self, max_pending: usize, max_elapsed: Duration) {
        if self.pending.len() >= max_pending || self.last_flush.elapsed() >= max_elapsed {
            self.flush();
        }
    }

    fn flush(&mut self) {
        if self.pending.is_empty() {
            return;
        }

        let generation = self.generation;
        let updates = std::mem::take(&mut self.pending);
        self.last_flush = Instant::now();

        let _ = self.qt_thread.queue(move |mut controller| {
            if controller.rust().scan_generation != generation {
                return;
            }

            let rows = &mut controller.as_mut().rust_mut().rows;
            for update in updates {
                if let Some(row) = rows.get_mut(update.row_index) {
                    row.size_bytes = update.size_bytes;
                    row.size_text = format_size(update.size_bytes);
                    row.size_status = update.status.to_size_status();
                }
            }
            controller.as_mut().bump_update_generation();
        });
    }
}

impl qobject::FolderBrowserController {
    pub fn increment_click_count(mut self: Pin<&mut Self>) {
        let previous = *self.click_count();
        let next = previous + 1;
        self.as_mut().set_click_count(next);
        self.as_mut().set_status_text(QString::from(format!(
            "Rust received button click #{next}"
        )));
    }

    pub fn set_path_from_qml(mut self: Pin<&mut Self>, path: &QString) {
        self.as_mut().set_current_path(path.clone());
        self.as_mut().set_status_text(QString::from(format!(
            "Path set from QML: {}",
            path.to_string()
        )));
    }

    pub fn scan_path(mut self: Pin<&mut Self>, path: &QString) {
        let qt_thread = self.qt_thread();
        let raw_path = path.to_string();
        let local_path = normalize_local_path(&raw_path);
        let directory = Path::new(&local_path);

        self.as_mut().set_current_path(QString::from(local_path.clone()));
        let next_generation = self.rust().scan_generation.wrapping_add(1);
        self.as_mut().rust_mut().scan_generation = next_generation;
        let generation = next_generation;

        if !directory.exists() {
            self.as_mut().rust_mut().rows.clear();
            self.as_mut().set_row_count(0);
            self.as_mut().bump_update_generation();
            self.as_mut().set_status_text(QString::from(format!("Path does not exist: {local_path}")));
            return;
        }

        if !directory.is_dir() {
            self.as_mut().rust_mut().rows.clear();
            self.as_mut().set_row_count(0);
            self.as_mut().bump_update_generation();
            self.as_mut().set_status_text(QString::from(format!("Not a directory: {local_path}")));
            return;
        }

        let rows = match scan_directory(directory) {
            Ok(rows) => rows,
            Err(error) => {
                self.as_mut().rust_mut().rows.clear();
                self.as_mut().set_row_count(0);
                self.as_mut().bump_update_generation();
                self.as_mut().set_status_text(QString::from(format!(
                    "Could not read directory {local_path}: {error}"
                )));
                return;
            }
        };

        let directory_jobs: Vec<(usize, PathBuf)> = rows
            .iter()
            .enumerate()
            .filter(|(_, row)| row.is_dir)
            .map(|(index, row)| (index, row.path.clone()))
            .collect();

        let count = rows.len();
        self.as_mut().rust_mut().rows = rows;
        self.as_mut().set_row_count(count.min(i32::MAX as usize) as i32);
        self.as_mut().bump_update_generation();
        self.as_mut().set_status_text(QString::from(format!(
            "Scanned {count} entries in {local_path}; calculating directory sizes"
        )));

        if !directory_jobs.is_empty() {
            std::thread::spawn(move || {
                let status_qt_thread = qt_thread.clone();
                let mut batch = DirectorySizeBatch::new(qt_thread, generation);

                for (row_index, dir_path) in directory_jobs {
                    let mut last_progress_update = Instant::now();

                    let result = calculate_directory_size(&dir_path, |partial_size| {
                        if last_progress_update.elapsed() >= Duration::from_secs(2) {
                            batch.push(
                                row_index,
                                Some(partial_size),
                                DirectorySizeStatusUpdate::Scanning,
                            );
                            batch.flush_if_needed(16, Duration::from_millis(750));
                            last_progress_update = Instant::now();
                        }
                    });

                    match result {
                        Ok(final_size) => batch.push(
                            row_index,
                            Some(final_size),
                            DirectorySizeStatusUpdate::Done,
                        ),
                        Err(_) => batch.push(row_index, None, DirectorySizeStatusUpdate::Error),
                    }

                    batch.flush_if_needed(32, Duration::from_millis(750));
                }

                batch.flush();

                let _ = status_qt_thread.queue(move |mut controller| {
                    if controller.rust().scan_generation == generation {
                        controller.as_mut().set_status_text(QString::from("Directory size calculation finished"));
                    }
                });
            });
        }
    }

    pub fn file_name(&self, row: i32) -> QString {
        self.row(row).map(|row| QString::from(row.name.clone())).unwrap_or_default()
    }

    pub fn file_kind(&self, row: i32) -> QString {
        self.row(row).map(|row| QString::from(row.kind.clone())).unwrap_or_default()
    }

    pub fn file_size_bytes(&self, row: i32) -> i64 {
        self.row(row)
            .and_then(|row| row.size_bytes)
            .and_then(|value| i64::try_from(value).ok())
            .unwrap_or(-1)
    }

    pub fn file_size_text(&self, row: i32) -> QString {
        self.row(row).map(|row| QString::from(row.size_text.clone())).unwrap_or_default()
    }

    pub fn file_size_status(&self, row: i32) -> QString {
        self.row(row)
            .map(|row| QString::from(row.size_status.as_str()))
            .unwrap_or_else(|| QString::from("unknown"))
    }

    pub fn file_modified_secs(&self, row: i32) -> i64 {
        self.row(row)
            .and_then(|row| row.modified_secs)
            .and_then(|value| i64::try_from(value).ok())
            .unwrap_or(-1)
    }

    pub fn file_path(&self, row: i32) -> QString {
        self.row(row)
            .map(|row| QString::from(row.path.to_string_lossy().to_string()))
            .unwrap_or_default()
    }

    pub fn file_is_dir(&self, row: i32) -> bool {
        self.row(row).map(|row| row.is_dir).unwrap_or(false)
    }

    fn row(&self, row: i32) -> Option<&FileRow> {
        if row < 0 {
            return None;
        }
        self.rust().rows.get(row as usize)
    }

    fn bump_update_generation(mut self: Pin<&mut Self>) {
        let current = *self.update_generation();
        let next = current.wrapping_add(1);
        self.as_mut().set_update_generation(next);
    }
}

fn scan_directory(directory: &Path) -> Result<Vec<FileRow>, std::io::Error> {
    let mut rows: Vec<FileRow> = Vec::new();

    for entry_result in fs::read_dir(directory)? {
        let entry = match entry_result {
            Ok(entry) => entry,
            Err(error) => {
                rows.push(FileRow {
                    name: format!("<unreadable entry: {error}>"),
                    kind: "error".to_string(),
                    size_bytes: None,
                    size_text: String::new(),
                    size_status: SizeStatus::Error,
                    modified_secs: None,
                    path: directory.to_path_buf(),
                    is_dir: false,
                });
                continue;
            }
        };

        let path = entry.path();
        let name = entry.file_name().to_string_lossy().into_owned();
        let file_type = entry.file_type();
        let metadata = entry.metadata().ok();

        let is_dir = file_type.as_ref().map(|kind| kind.is_dir()).unwrap_or(false);
        let is_file = file_type.as_ref().map(|kind| kind.is_file()).unwrap_or(false);
        let is_symlink = file_type.as_ref().map(|kind| kind.is_symlink()).unwrap_or(false);

        let kind = if is_dir {
            "folder"
        } else if is_file {
            "file"
        } else if is_symlink {
            "symlink"
        } else {
            "other"
        }
        .to_string();

        let size_bytes = if is_file { metadata.as_ref().map(|metadata| metadata.len()) } else { None };
        let size_status = if is_dir { SizeStatus::Unknown } else { SizeStatus::File };

        let modified_secs = metadata
            .as_ref()
            .and_then(|metadata| metadata.modified().ok())
            .and_then(|modified| modified.duration_since(UNIX_EPOCH).ok())
            .map(|duration| duration.as_secs());

        rows.push(FileRow {
            name,
            kind,
            size_bytes,
            size_text: format_size(size_bytes),
            size_status,
            modified_secs,
            path,
            is_dir,
        });
    }

    rows.sort_by(|left, right| {
        right
            .is_dir
            .cmp(&left.is_dir)
            .then_with(|| left.name.to_lowercase().cmp(&right.name.to_lowercase()))
    });

    Ok(rows)
}

fn calculate_directory_size<F>(directory: &Path, mut progress: F) -> Result<u64, std::io::Error>
where
    F: FnMut(u64),
{
    let mut total: u64 = 0;
    let mut stack: Vec<PathBuf> = vec![directory.to_path_buf()];

    while let Some(current_directory) = stack.pop() {
        let read_dir = match fs::read_dir(&current_directory) {
            Ok(read_dir) => read_dir,
            Err(_) => continue,
        };

        for entry_result in read_dir {
            let entry = match entry_result {
                Ok(entry) => entry,
                Err(_) => continue,
            };

            let file_type = match entry.file_type() {
                Ok(file_type) => file_type,
                Err(_) => continue,
            };

            if file_type.is_dir() {
                stack.push(entry.path());
            } else if file_type.is_file() {
                if let Ok(metadata) = entry.metadata() {
                    total = total.saturating_add(metadata.len());
                    progress(total);
                }
            }
        }
    }

    Ok(total)
}
