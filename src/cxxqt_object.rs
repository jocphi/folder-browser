/// CXX-Qt QObject bridge for the folder-browser scaffold.
///
/// This version removes JSON transfer. Rust stores structured file rows and QML
/// reads them through invokable row accessors into a real Qt/QML ListModel.
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
        #[cxx_name = "fileModifiedSecs"]
        fn file_modified_secs(&self, row: i32) -> i64;

        #[qinvokable]
        #[cxx_name = "filePath"]
        fn file_path(&self, row: i32) -> QString;

        #[qinvokable]
        #[cxx_name = "fileIsDir"]
        fn file_is_dir(&self, row: i32) -> bool;
    }
}

use core::pin::Pin;
use cxx_qt::CxxQtType;
use cxx_qt_lib::QString;
use std::fs;
use std::path::{Path, PathBuf};
use std::time::UNIX_EPOCH;

#[derive(Default)]
pub struct FolderBrowserControllerRust {
    click_count: i32,
    current_path: QString,
    status_text: QString,
    row_count: i32,
    rows: Vec<FileRow>,
}

#[derive(Clone, Debug, Default)]
struct FileRow {
    name: String,
    kind: String,
    size_bytes: Option<u64>,
    size_text: String,
    modified_secs: Option<u64>,
    path: PathBuf,
    is_dir: bool,
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
        let raw_path = path.to_string();
        let local_path = normalize_local_path(&raw_path);
        let directory = Path::new(&local_path);

        self.as_mut().set_current_path(QString::from(local_path.clone()));

        if !directory.exists() {
            self.as_mut().rust_mut().rows.clear();
            self.as_mut().set_row_count(0);
            self.as_mut().set_status_text(QString::from(format!(
                "Path does not exist: {local_path}"
            )));
            return;
        }

        if !directory.is_dir() {
            self.as_mut().rust_mut().rows.clear();
            self.as_mut().set_row_count(0);
            self.as_mut().set_status_text(QString::from(format!(
                "Not a directory: {local_path}"
            )));
            return;
        }

        let rows = match scan_directory(directory) {
            Ok(rows) => rows,
            Err(error) => {
                self.as_mut().rust_mut().rows.clear();
                self.as_mut().set_row_count(0);
                self.as_mut().set_status_text(QString::from(format!(
                    "Could not read directory {local_path}: {error}"
                )));
                return;
            }
        };

        let count = rows.len();
        self.as_mut().rust_mut().rows = rows;
        self.as_mut().set_row_count(count.min(i32::MAX as usize) as i32);
        self.as_mut().set_status_text(QString::from(format!(
            "Scanned {count} entries in {local_path}"
        )));
    }

    pub fn file_name(&self, row: i32) -> QString {
        self.row(row)
            .map(|row| QString::from(row.name.clone()))
            .unwrap_or_default()
    }

    pub fn file_kind(&self, row: i32) -> QString {
        self.row(row)
            .map(|row| QString::from(row.kind.clone()))
            .unwrap_or_default()
    }

    pub fn file_size_bytes(&self, row: i32) -> i64 {
        self.row(row)
            .and_then(|row| row.size_bytes)
            .and_then(|value| i64::try_from(value).ok())
            .unwrap_or(-1)
    }

    pub fn file_size_text(&self, row: i32) -> QString {
        self.row(row)
            .map(|row| QString::from(row.size_text.clone()))
            .unwrap_or_default()
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

        let size_bytes = if is_file {
            metadata.as_ref().map(|metadata| metadata.len())
        } else {
            None
        };

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

fn format_size(size_bytes: Option<u64>) -> String {
    let Some(bytes) = size_bytes else {
        return String::new();
    };

    const UNITS: [&str; 5] = ["B", "KiB", "MiB", "GiB", "TiB"];
    let mut value = bytes as f64;
    let mut unit_index = 0usize;

    while value >= 1024.0 && unit_index < UNITS.len() - 1 {
        value /= 1024.0;
        unit_index += 1;
    }

    if unit_index == 0 {
        format!("{bytes} B")
    } else {
        format!("{value:.1} {}", UNITS[unit_index])
    }
}

fn normalize_local_path(input: &str) -> String {
    input.strip_prefix("file://").unwrap_or(input).to_string()
}
