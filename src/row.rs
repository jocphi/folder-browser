use crate::cxxqt_object::qobject;
use crate::file_row::FileRow;
use cxx_qt::CxxQtType;

impl qobject::FolderBrowserController {
    pub(crate) fn row(&self, row: i32) -> Option<&FileRow> {
        if row < 0 {
            return None;
        }

        self.rust().rows.get(row as usize)
    }
}
