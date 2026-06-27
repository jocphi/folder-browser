use crate::cxxqt_object::qobject;
use cxx_qt::CxxQtType;

impl qobject::FolderBrowserController {
    pub fn file_is_dir(&self, row: i32) -> bool {
        if row < 0 {
            return false;
        }

        self.rust()
            .rows
            .get(row as usize)
            .map(|row| row.is_dir)
            .unwrap_or(false)
    }
}
