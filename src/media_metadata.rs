use crate::cxxqt_object::qobject;
use crate::file_row::FileRow;
use cxx_qt_lib::QString;
use std::path::{Path, PathBuf};
use std::process::Command;

#[derive(Clone, Debug, Default)]
pub(crate) struct MediaMetadata {
    pub(crate) duration_secs: Option<f64>,
    pub(crate) codec: String,
    pub(crate) bitrate: Option<u64>,
    pub(crate) fps: Option<f64>,
    pub(crate) media_width: Option<u32>,
    pub(crate) media_height: Option<u32>,
}

impl MediaMetadata {
    pub(crate) fn is_empty(&self) -> bool {
        self.duration_secs.is_none() && self.codec.is_empty() && self.bitrate.is_none()
            && self.fps.is_none() && self.media_width.is_none() && self.media_height.is_none()
    }
}

pub(crate) fn is_media_path(path: &Path) -> bool {
    let Some(ext) = path.extension().and_then(|v| v.to_str()) else { return false; };
    matches!(ext.to_ascii_lowercase().as_str(),
        "3g2"|"3gp"|"aac"|"aiff"|"ape"|"asf"|"avi"|"flac"|"flv"|"m2ts"|"m4a"|"m4v"|
        "mka"|"mkv"|"mov"|"mp3"|"mp4"|"mpeg"|"mpg"|"mts"|"ogg"|"opus"|"ts"|"wav"|
        "webm"|"wma"|"wmv")
}

fn parse_fraction(value: &str) -> Option<f64> {
    let value = value.trim();
    if value.is_empty() || value == "N/A" || value == "0/0" { return None; }
    if let Some((n, d)) = value.split_once('/') {
        let n = n.parse::<f64>().ok()?;
        let d = d.parse::<f64>().ok()?;
        return if d > 0.0 { Some(n / d) } else { None };
    }
    value.parse::<f64>().ok()
}

fn parse_output(output: &str) -> MediaMetadata {
    let mut m = MediaMetadata::default();
    let mut first_codec = String::new();
    let mut is_video = false;
    let mut is_audio = false;
    for line in output.lines() {
        let Some((key, value)) = line.split_once('=') else { continue; };
        let value = value.trim();
        if value.is_empty() || value == "N/A" { continue; }
        match key.trim() {
            "codec_type" => { is_video = value == "video"; is_audio = value == "audio"; }
            "codec_name" => {
                if first_codec.is_empty() { first_codec = value.to_string(); }
                if m.codec.is_empty() && (is_video || is_audio) { m.codec = value.to_string(); }
            }
            "width" => if is_video && m.media_width.is_none() { m.media_width = value.parse::<u32>().ok(); },
            "height" => if is_video && m.media_height.is_none() { m.media_height = value.parse::<u32>().ok(); },
            "r_frame_rate" | "avg_frame_rate" => if is_video && m.fps.is_none() { m.fps = parse_fraction(value); },
            "duration" => if m.duration_secs.is_none() { m.duration_secs = value.parse::<f64>().ok(); },
            "bit_rate" => if m.bitrate.is_none() { m.bitrate = value.parse::<u64>().ok(); },
            _ => {}
        }
    }
    if m.codec.is_empty() { m.codec = first_codec; }
    m
}

pub(crate) fn probe_media_metadata(path: &Path) -> MediaMetadata {
    let output = Command::new("ffprobe")
        .arg("-v").arg("error")
        .arg("-show_entries")
        .arg("format=duration,bit_rate:stream=codec_type,codec_name,width,height,r_frame_rate,avg_frame_rate,bit_rate")
        .arg("-of").arg("default=noprint_wrappers=1")
        .arg(path)
        .output();
    let Ok(output) = output else { return MediaMetadata::default(); };
    if !output.status.success() { return MediaMetadata::default(); }
    parse_output(&String::from_utf8_lossy(&output.stdout))
}

pub(crate) fn apply_media_metadata(row: &mut FileRow, metadata: MediaMetadata) {
    row.duration_secs = metadata.duration_secs;
    row.codec = metadata.codec;
    row.bitrate = metadata.bitrate;
    row.fps = metadata.fps;
    row.media_width = metadata.media_width;
    row.media_height = metadata.media_height;
}

pub(crate) fn media_jobs(rows: &[FileRow]) -> Vec<(usize, PathBuf)> {
    rows.iter().enumerate()
        .filter(|(_, row)| !row.is_dir && is_media_path(&row.path))
        .map(|(index, row)| (index, row.path.clone()))
        .collect()
}

impl qobject::FolderBrowserController {
    pub fn file_duration_secs(&self, row: i32) -> f64 { self.row(row).and_then(|r| r.duration_secs).unwrap_or(-1.0) }
    pub fn file_codec(&self, row: i32) -> QString { self.row(row).map(|r| QString::from(r.codec.clone())).unwrap_or_default() }
    pub fn file_bitrate(&self, row: i32) -> i64 { self.row(row).and_then(|r| r.bitrate).map(|v| v.min(i64::MAX as u64) as i64).unwrap_or(-1) }
    pub fn file_fps(&self, row: i32) -> f64 { self.row(row).and_then(|r| r.fps).unwrap_or(-1.0) }
    pub fn file_media_width(&self, row: i32) -> i32 { self.row(row).and_then(|r| r.media_width).map(|v| v.min(i32::MAX as u32) as i32).unwrap_or(-1) }
    pub fn file_media_height(&self, row: i32) -> i32 { self.row(row).and_then(|r| r.media_height).map(|v| v.min(i32::MAX as u32) as i32).unwrap_or(-1) }
}
