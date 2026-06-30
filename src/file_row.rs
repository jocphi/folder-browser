use std::path::PathBuf;
use crate::file_size_status::{DirectorySizeStatusUpdate, SizeStatus};


#[derive(Clone, Debug, Default)]
pub(crate) struct FileRow {
    pub(crate) name: String,
    pub(crate) kind: String,
    pub(crate) mime_type: String,
    pub(crate) media_status: String,
    pub(crate) size_bytes: Option<u64>,
    pub(crate) size_text: String,
    pub(crate) size_status: SizeStatus,
    pub(crate) modified_secs: Option<u64>,
    pub(crate) duration_secs: Option<f64>,
    pub(crate) codec: String,
    pub(crate) video_codec: String,
    pub(crate) audio_codec: String,
    pub(crate) bitrate: Option<u64>,
    pub(crate) fps: Option<f64>,
    pub(crate) media_width: Option<u32>,
    pub(crate) media_height: Option<u32>,
    pub(crate) path: PathBuf,
    pub(crate) is_dir: bool,
}


#[derive(Clone, Debug)]
pub(crate) struct PendingDirectorySizeUpdate {
    pub(crate) row_index: usize,
    pub(crate) size_bytes: Option<u64>,
    pub(crate) status: DirectorySizeStatusUpdate,
}
