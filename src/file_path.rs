use crate::cxxqt_object::qobject;
use cxx_qt::CxxQtType;
use cxx_qt_lib::QString;

impl qobject::FolderBrowserController {
    pub fn file_path(&self, row: i32) -> QString {
        if row < 0 {
            return QString::default();
        }

        self.rust()
            .rows
            .get(row as usize)
            .map(|row| QString::from(row.path.to_string_lossy().to_string()))
            .unwrap_or_default()
    }
}
