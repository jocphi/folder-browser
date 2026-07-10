use crate::cxxqt_object::qobject;
use cxx_qt_lib::QString;

impl qobject::FolderBrowserController {
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

    pub fn file_mime_type(&self, row: i32) -> QString {
        self.row(row)
            .map(|row| QString::from(row.mime_type.clone()))
            .unwrap_or_default()
    }

    pub fn file_mime_status(&self, row: i32) -> QString {
        self.row(row)
            .map(|row| QString::from(row.mime_status.clone()))
            .unwrap_or_default()
    }


    pub fn file_size_status(&self, row: i32) -> QString {
        self.row(row)
            .map(|row| QString::from(row.size_status.as_str()))
            .unwrap_or_else(|| QString::from("unknown"))
    }


}
