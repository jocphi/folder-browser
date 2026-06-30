use crate::cxxqt_object::qobject;
use crate::file_row::FileRow;
use cxx_qt_lib::QString;
use std::path::{Path, PathBuf};
use std::process::Command;

#[derive(Clone, Debug, Default)]
pub(crate) struct MediaMetadata {
    pub(crate) duration_secs: Option<f64>,
    pub(crate) codec: String,
    pub(crate) video_codec: String,
    pub(crate) audio_codec: String,
    pub(crate) bitrate: Option<u64>,
    pub(crate) fps: Option<f64>,
    pub(crate) media_width: Option<u32>,
    pub(crate) media_height: Option<u32>,
}

impl MediaMetadata {
    pub(crate) fn is_empty(&self) -> bool {
        self.duration_secs.is_none()
            && self.codec.is_empty()
            && self.video_codec.is_empty()
            && self.audio_codec.is_empty()
            && self.bitrate.is_none()
            && self.fps.is_none()
            && self.media_width.is_none()
            && self.media_height.is_none()
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
    let mut section = "";
    let mut stream_codec_type = String::new();
    let mut stream_codec_name = String::new();
    let mut stream_width: Option<u32> = None;
    let mut stream_height: Option<u32> = None;
    let mut stream_fps: Option<f64> = None;
    let mut stream_bitrate: Option<u64> = None;

    fn apply_stream(m: &mut MediaMetadata, codec_type: &str, codec_name: &str, width: Option<u32>, height: Option<u32>, fps: Option<f64>, bitrate: Option<u64>) {
        if codec_type == "video" {
            if m.video_codec.is_empty() { m.video_codec = codec_name.to_string(); }
            if m.media_width.is_none() { m.media_width = width; }
            if m.media_height.is_none() { m.media_height = height; }
            if m.fps.is_none() { m.fps = fps; }
            if m.bitrate.is_none() { m.bitrate = bitrate; }
        } else if codec_type == "audio" {
            if m.audio_codec.is_empty() { m.audio_codec = codec_name.to_string(); }
            if m.bitrate.is_none() { m.bitrate = bitrate; }
        }
    }

    for raw_line in output.lines() {
        let line = raw_line.trim();
        if line == "[STREAM]" {
            section = "stream";
            stream_codec_type.clear(); stream_codec_name.clear();
            stream_width = None; stream_height = None; stream_fps = None; stream_bitrate = None;
            continue;
        }
        if line == "[/STREAM]" {
            apply_stream(&mut m, &stream_codec_type, &stream_codec_name, stream_width, stream_height, stream_fps, stream_bitrate);
            section = ""; continue;
        }
        if line == "[FORMAT]" { section = "format"; continue; }
        if line == "[/FORMAT]" { section = ""; continue; }
        let Some((key, value)) = line.split_once('=') else { continue; };
        let value = value.trim();
        if value.is_empty() || value == "N/A" { continue; }
        if section == "stream" {
            match key.trim() {
                "codec_type" => stream_codec_type = value.to_string(),
                "codec_name" => stream_codec_name = value.to_string(),
                "width" => stream_width = value.parse::<u32>().ok(),
                "height" => stream_height = value.parse::<u32>().ok(),
                "r_frame_rate" | "avg_frame_rate" => if stream_fps.is_none() { stream_fps = parse_fraction(value); },
                "bit_rate" => stream_bitrate = value.parse::<u64>().ok(),
                _ => {}
            }
        } else if section == "format" {
            match key.trim() {
                "duration" => if m.duration_secs.is_none() { m.duration_secs = value.parse::<f64>().ok(); },
                "bit_rate" => m.bitrate = value.parse::<u64>().ok().or(m.bitrate),
                _ => {}
            }
        }
    }
    m.codec = if !m.video_codec.is_empty() { m.video_codec.clone() } else { m.audio_codec.clone() };
    m
}

pub(crate) fn probe_media_metadata(path: &Path) -> MediaMetadata {
    let output = Command::new("ffprobe")
        .arg("-v").arg("error")
        .arg("-show_entries")
        .arg("format=duration,bit_rate:stream=codec_type,codec_name,width,height,r_frame_rate,avg_frame_rate,bit_rate")
        .arg("-of").arg("default=noprint_wrappers=0")
        .arg(path)
        .output();
    let Ok(output) = output else { return MediaMetadata::default(); };
    if !output.status.success() { return MediaMetadata::default(); }
    parse_output(&String::from_utf8_lossy(&output.stdout))
}

pub(crate) fn apply_media_metadata(row: &mut FileRow, metadata: MediaMetadata) {
    row.duration_secs = metadata.duration_secs;
    row.codec = metadata.codec;
    row.video_codec = metadata.video_codec;
    row.audio_codec = metadata.audio_codec;
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
    pub fn file_video_codec(&self, row: i32) -> QString { self.row(row).map(|r| QString::from(r.video_codec.clone())).unwrap_or_default() }
    pub fn file_audio_codec(&self, row: i32) -> QString { self.row(row).map(|r| QString::from(r.audio_codec.clone())).unwrap_or_default() }
    pub fn file_bitrate(&self, row: i32) -> i64 { self.row(row).and_then(|r| r.bitrate).map(|v| v.min(i64::MAX as u64) as i64).unwrap_or(-1) }
    pub fn file_fps(&self, row: i32) -> f64 { self.row(row).and_then(|r| r.fps).unwrap_or(-1.0) }
    pub fn file_media_width(&self, row: i32) -> i32 { self.row(row).and_then(|r| r.media_width).map(|v| v.min(i32::MAX as u32) as i32).unwrap_or(-1) }
    pub fn file_media_height(&self, row: i32) -> i32 { self.row(row).and_then(|r| r.media_height).map(|v| v.min(i32::MAX as u32) as i32).unwrap_or(-1) }
}
