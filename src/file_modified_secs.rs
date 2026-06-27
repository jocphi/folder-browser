use crate::cxxqt_object::qobject;
use cxx_qt::CxxQtType;

impl qobject::FolderBrowserController {
    pub fn file_modified_secs(&self, row: i32) -> i64 {
        if row < 0 {
            return -1;
        }

        self.rust()
            .rows
            .get(row as usize)
            .and_then(|row| row.modified_secs)
            .and_then(|value| i64::try_from(value).ok())
            .unwrap_or(-1)
    }
}
