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
        #[qproperty(bool, follow_symlinks, cxx_name = "followSymlinks")]
        #[qproperty(bool, is_scanning, cxx_name = "isScanning")]
        #[qproperty(i32, size_scan_done, cxx_name = "sizeScanDone")]
        #[qproperty(i32, size_scan_total, cxx_name = "sizeScanTotal")]
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

        #[qinvokable]
        #[cxx_name = "fileDurationSecs"]
        fn file_duration_secs(&self, row: i32) -> f64;

        #[qinvokable]
        #[cxx_name = "fileCodec"]
        fn file_codec(&self, row: i32) -> QString;

        #[qinvokable]
        #[cxx_name = "fileBitrate"]
        fn file_bitrate(&self, row: i32) -> i64;

        #[qinvokable]
        #[cxx_name = "fileFps"]
        fn file_fps(&self, row: i32) -> f64;

        #[qinvokable]
        #[cxx_name = "fileMediaWidth"]
        fn file_media_width(&self, row: i32) -> i32;

        #[qinvokable]
        #[cxx_name = "fileMediaHeight"]
        fn file_media_height(&self, row: i32) -> i32;
    }

    impl cxx_qt::Threading for FolderBrowserController {}
}

use core::pin::Pin;
use cxx_qt::{CxxQtType, Threading};
use cxx_qt_lib::QString;
use crate::formatting::normalize_local_path;
use crate::file_row::FileRow;
use crate::file_size_status::{DirectorySizeStatusUpdate, SizeStatus};
use crate::scanner::scan_directory;
use crate::signals::bump_update_generation;
use crate::media_metadata::{apply_media_metadata, media_jobs, probe_media_metadata};
use crate::dir_size_worker::{calculate_directory_size, DirectorySizeBatch};
use std::path::{Path, PathBuf};
use std::time::{Duration, Instant};

#[derive(Default)]
pub struct FolderBrowserControllerRust {
    click_count: i32,
    current_path: QString,
    status_text: QString,
    row_count: i32,
    update_generation: i32,
    follow_symlinks: bool,
    is_scanning: bool,
    size_scan_done: i32,
    size_scan_total: i32,
    pub(crate) rows: Vec<FileRow>,
    pub(crate) scan_generation: u64,
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
        let follow_symlinks = *self.follow_symlinks();

        self.as_mut().set_current_path(QString::from(local_path.clone()));
        let next_generation = self.rust().scan_generation.wrapping_add(1);
        self.as_mut().rust_mut().scan_generation = next_generation;
        let generation = next_generation;

        if !directory.exists() {
            self.as_mut().rust_mut().rows.clear();
            self.as_mut().set_row_count(0);
            self.as_mut().set_is_scanning(false);
            self.as_mut().set_size_scan_done(0);
            self.as_mut().set_size_scan_total(0);
            bump_update_generation(self.as_mut());
            self.as_mut().set_status_text(QString::from(format!("Path does not exist: {local_path}")));
            return;
        }

        if !directory.is_dir() {
            self.as_mut().rust_mut().rows.clear();
            self.as_mut().set_row_count(0);
            self.as_mut().set_is_scanning(false);
            self.as_mut().set_size_scan_done(0);
            self.as_mut().set_size_scan_total(0);
            bump_update_generation(self.as_mut());
            self.as_mut().set_status_text(QString::from(format!("Not a directory: {local_path}")));
            return;
        }

        let previous_directory_sizes: std::collections::HashMap<PathBuf, (Option<u64>, String)> = self
            .rust()
            .rows
            .iter()
            .filter(|row| row.is_dir)
            .map(|row| (row.path.clone(), (row.size_bytes, row.size_text.clone())))
            .collect();

        let rows = match scan_directory(directory, follow_symlinks) {
            Ok(rows) => rows,
            Err(error) => {
                self.as_mut().rust_mut().rows.clear();
                self.as_mut().set_row_count(0);
                bump_update_generation(self.as_mut());
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

        let media_jobs = media_jobs(&rows);

        let mut rows = rows;
        for (row_index, _) in &directory_jobs {
            if let Some(row) = rows.get_mut(*row_index) {
                if let Some((previous_size_bytes, previous_size_text)) = previous_directory_sizes.get(&row.path) {
                    row.size_bytes = *previous_size_bytes;
                    row.size_text = previous_size_text.clone();
                    row.size_status = SizeStatus::Stale;
                } else {
                    row.size_bytes = None;
                    row.size_text.clear();
                    row.size_status = SizeStatus::Scanning;
                }
            }
        }

        let count = rows.len();
        let size_scan_total = directory_jobs.len().min(i32::MAX as usize) as i32;
        self.as_mut().rust_mut().rows = rows;
        self.as_mut().set_row_count(count.min(i32::MAX as usize) as i32);
        self.as_mut().set_size_scan_done(0);
        self.as_mut().set_size_scan_total(size_scan_total);
        self.as_mut().set_is_scanning(size_scan_total > 0);
        bump_update_generation(self.as_mut());
        if directory_jobs.is_empty() {
            self.as_mut().set_status_text(QString::from(format!(
                "Scanned {count} entries in {local_path}"
            )));
        } else {
            self.as_mut().set_status_text(QString::from(format!(
                "Scanned {count} entries in {local_path}; calculating {} directory sizes",
                directory_jobs.len()
            )));
        }

        // Media metadata scanning is independent of directory-size scanning.
        if !media_jobs.is_empty() {
            let media_qt_thread = qt_thread.clone();
            std::thread::spawn(move || {
                for (row_index, media_path) in media_jobs {
                    let metadata = probe_media_metadata(&media_path);
                    if metadata.is_empty() { continue; }
                    let path_for_match = media_path.clone();
                    let _ = media_qt_thread.queue(move |mut controller| {
                        if controller.rust().scan_generation != generation { return; }
                        let changed = {
                            let rows = &mut controller.as_mut().rust_mut().rows;
                            if let Some(row) = rows.get_mut(row_index) {
                                if row.path == path_for_match {
                                    apply_media_metadata(row, metadata);
                                    true
                                } else { false }
                            } else { false }
                        };
                        if changed { bump_update_generation(controller.as_mut()); }
                    });
                }
            });
        }

        if !directory_jobs.is_empty() {


            std::thread::spawn(move || {
                let status_qt_thread = qt_thread.clone();
                let mut batch = DirectorySizeBatch::new(qt_thread, generation);

                for (row_index, dir_path) in directory_jobs {
                    let mut last_progress_update = Instant::now();

                    let result = calculate_directory_size(&dir_path, follow_symlinks, |partial_size| {
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

                    let progress_qt_thread = status_qt_thread.clone();
                    let _ = progress_qt_thread.queue(move |mut controller| {
                        if controller.rust().scan_generation == generation {
                            let total = *controller.size_scan_total();
                            let next = (*controller.size_scan_done()).saturating_add(1).min(total);
                            controller.as_mut().set_size_scan_done(next);
                            controller.as_mut().set_status_text(QString::from(format!(
                                "Directory sizes: {next} / {total}"
                            )));
                        }
                    });

                    batch.flush_if_needed(32, Duration::from_millis(750));
                    std::thread::sleep(Duration::from_millis(5));
                }

                batch.flush();

                let _ = status_qt_thread.queue(move |mut controller| {
                    if controller.rust().scan_generation == generation {
                        let total = *controller.size_scan_total();
                        controller.as_mut().set_size_scan_done(total);
                        controller.as_mut().set_is_scanning(false);
                        controller.as_mut().set_status_text(QString::from(format!(
                            "Directory size calculation finished ({total} / {total})"
                        )));
                    }
                });
            });
        }
    }










}
