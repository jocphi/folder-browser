use crate::cxxqt_object::qobject;
use cxx_qt::CxxQtType;

pub(crate) fn option_u64_to_qml_i64(value: Option<u64>) -> i64 {
    value.and_then(|value| i64::try_from(value).ok()).unwrap_or(-1)
}

impl qobject::FolderBrowserController {
    pub fn file_size_bytes(&self, row: i32) -> i64 {
        if row < 0 {
            return -1;
        }

        self.rust()
            .rows
            .get(row as usize)
            .and_then(|row| row.size_bytes)
            .map(Some)
            .map(option_u64_to_qml_i64)
            .unwrap_or(-1)
    }
}
