use crate::cxxqt_object::qobject;
use cxx_qt::CxxQtType;
use cxx_qt_lib::QString;

impl qobject::FolderBrowserController {
    pub fn file_size_text(&self, row: i32) -> QString {
        if row < 0 {
            return QString::default();
        }

        self.rust()
            .rows
            .get(row as usize)
            .map(|row| QString::from(row.size_text.clone()))
            .unwrap_or_default()
    }
}
