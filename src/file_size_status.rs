#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub(crate) enum SizeStatus {
    #[default]
    File,
    Unknown,
    Stale,
    Scanning,
    Done,
    Error,
}

impl SizeStatus {
    pub(crate) fn as_str(self) -> &'static str {
        match self {
            SizeStatus::File => "file",
            SizeStatus::Unknown => "unknown",
            SizeStatus::Stale => "stale",
            SizeStatus::Scanning => "scanning",
            SizeStatus::Done => "done",
            SizeStatus::Error => "error",
        }
    }
}

#[derive(Clone, Copy, Debug)]
pub(crate) enum DirectorySizeStatusUpdate {
    Scanning,
    Done,
    Error,
}

impl DirectorySizeStatusUpdate {
    pub(crate) fn to_size_status(self) -> SizeStatus {
        match self {
            DirectorySizeStatusUpdate::Scanning => SizeStatus::Scanning,
            DirectorySizeStatusUpdate::Done => SizeStatus::Done,
            DirectorySizeStatusUpdate::Error => SizeStatus::Error,
        }
    }
}
