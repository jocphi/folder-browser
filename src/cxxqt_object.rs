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
use crate::formatting::normalize_local_path;
use crate::file_row::FileRow;
use crate::file_size_status::DirectorySizeStatusUpdate;
use crate::scanner::scan_directory;
use crate::signals::bump_update_generation;
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

        self.as_mut().set_current_path(QString::from(local_path.clone()));
        let next_generation = self.rust().scan_generation.wrapping_add(1);
        self.as_mut().rust_mut().scan_generation = next_generation;
        let generation = next_generation;

        if !directory.exists() {
            self.as_mut().rust_mut().rows.clear();
            self.as_mut().set_row_count(0);
            bump_update_generation(self.as_mut());
            self.as_mut().set_status_text(QString::from(format!("Path does not exist: {local_path}")));
            return;
        }

        if !directory.is_dir() {
            self.as_mut().rust_mut().rows.clear();
            self.as_mut().set_row_count(0);
            bump_update_generation(self.as_mut());
            self.as_mut().set_status_text(QString::from(format!("Not a directory: {local_path}")));
            return;
        }

        let rows = match scan_directory(directory) {
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

        let count = rows.len();
        self.as_mut().rust_mut().rows = rows;
        self.as_mut().set_row_count(count.min(i32::MAX as usize) as i32);
        bump_update_generation(self.as_mut());
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










}
