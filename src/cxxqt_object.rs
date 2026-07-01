/// CXX-Qt QObject bridge for the folder-browser scaffold.
///
/// Rust stores structured file rows, exposes them through invokable accessors,
/// and calculates directory sizes on a throttled background thread.
#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qproperty(i32, click_count, cxx_name = "clickCount")]
        #[qproperty(QString, current_path, cxx_name = "currentPath")]
        #[qproperty(QString, status_text, cxx_name = "statusText")]
        #[qproperty(i32, row_count, cxx_name = "rowCount")]
        #[qproperty(i32, update_generation, cxx_name = "updateGeneration")]
        #[qproperty(bool, follow_symlinks, cxx_name = "followSymlinks")]
        #[qproperty(bool, is_scanning, cxx_name = "isScanning")]
        #[qproperty(i32, size_scan_done, cxx_name = "sizeScanDone")]
        #[qproperty(i32, size_scan_total, cxx_name = "sizeScanTotal")]
        #[namespace = "folder_browser"]
        type FolderBrowserController = super::FolderBrowserControllerRust;

        #[qinvokable]
        #[cxx_name = "incrementClickCount"]
        fn increment_click_count(self: Pin<&mut Self>);

        #[qinvokable]
        #[cxx_name = "setPathFromQml"]
        fn set_path_from_qml(self: Pin<&mut Self>, path: &QString);

        #[qinvokable]
        #[cxx_name = "scanPath"]
        fn scan_path(self: Pin<&mut Self>, path: &QString);

        #[qinvokable]
        #[cxx_name = "trashPaths"]
        fn trash_paths(self: Pin<&mut Self>, paths: &QString);

        #[qinvokable]
        #[cxx_name = "trashPreviewItems"]
        fn trash_preview_items(&self, paths: &QString) -> QString;

        #[qinvokable]
        #[cxx_name = "previewText"]
        fn preview_text(&self, path: &QString) -> QString;

        #[qinvokable]
        #[cxx_name = "previewVideoFrames"]
        fn preview_video_frames(&self, path: &QString) -> QString;

        #[qinvokable]
        #[cxx_name = "fileName"]
        fn file_name(&self, row: i32) -> QString;

        #[qinvokable]
        #[cxx_name = "fileKind"]
        fn file_kind(&self, row: i32) -> QString;

        #[qinvokable]
        #[cxx_name = "fileMimeType"]
        fn file_mime_type(&self, row: i32) -> QString;

        #[qinvokable]
        #[cxx_name = "fileMimeStatus"]
        fn file_mime_status(&self, row: i32) -> QString;

        #[qinvokable]
        #[cxx_name = "fileSizeBytes"]
        fn file_size_bytes(&self, row: i32) -> i64;

        #[qinvokable]
        #[cxx_name = "fileSizeText"]
        fn file_size_text(&self, row: i32) -> QString;

        #[qinvokable]
        #[cxx_name = "fileSizeStatus"]
        fn file_size_status(&self, row: i32) -> QString;

        #[qinvokable]
        #[cxx_name = "fileModifiedSecs"]
        fn file_modified_secs(&self, row: i32) -> i64;

        #[qinvokable]
        #[cxx_name = "filePath"]
        fn file_path(&self, row: i32) -> QString;

        #[qinvokable]
        #[cxx_name = "fileIsDir"]
        fn file_is_dir(&self, row: i32) -> bool;

        #[qinvokable]
        #[cxx_name = "fileDurationSecs"]
        fn file_duration_secs(&self, row: i32) -> f64;

        #[qinvokable]
        #[cxx_name = "fileCodec"]
        fn file_codec(&self, row: i32) -> QString;

        #[qinvokable]
        #[cxx_name = "fileVideoCodec"]
        fn file_video_codec(&self, row: i32) -> QString;

        #[qinvokable]
        #[cxx_name = "fileAudioCodec"]
        fn file_audio_codec(&self, row: i32) -> QString;

        #[qinvokable]
        #[cxx_name = "fileBitrate"]
        fn file_bitrate(&self, row: i32) -> i64;

        #[qinvokable]
        #[cxx_name = "fileFps"]
        fn file_fps(&self, row: i32) -> f64;

        #[qinvokable]
        #[cxx_name = "fileMediaWidth"]
        fn file_media_width(&self, row: i32) -> i32;

        #[qinvokable]
        #[cxx_name = "fileMediaHeight"]
        fn file_media_height(&self, row: i32) -> i32;

        #[qinvokable]
        #[cxx_name = "fileMediaStatus"]
        fn file_media_status(&self, row: i32) -> QString;
    }

    impl cxx_qt::Threading for FolderBrowserController {}
}

use core::pin::Pin;
use cxx_qt::{CxxQtType, Threading};
use cxx_qt_lib::QString;
use crate::formatting::normalize_local_path;
use crate::file_row::FileRow;
use crate::file_size_status::{DirectorySizeStatusUpdate, SizeStatus};
use crate::scanner::{probe_mime_type, scan_directory};
use crate::signals::bump_update_generation;
use crate::media_metadata::{apply_media_metadata, is_media_path, mark_media_metadata_unavailable, probe_media_metadata};
use crate::dir_size_worker::{calculate_directory_size, DirectorySizeBatch};
use std::path::{Path, PathBuf};
use std::time::{Duration, Instant};

#[derive(Default)]
pub struct FolderBrowserControllerRust {
    click_count: i32,
    current_path: QString,
    status_text: QString,
    row_count: i32,
    update_generation: i32,
    follow_symlinks: bool,
    is_scanning: bool,
    size_scan_done: i32,
    size_scan_total: i32,
    pub(crate) rows: Vec<FileRow>,
    pub(crate) scan_generation: u64,
}









fn trash_percent_encode_path(path: &std::path::Path) -> String {
    let mut out = String::new();
    for byte in path.to_string_lossy().as_bytes() {
        let ch = *byte as char;
        if ch.is_ascii_alphanumeric() || matches!(ch, '/' | '-' | '_' | '.' | '~') {
            out.push(ch);
        } else {
            out.push_str(&format!("%{byte:02X}"));
        }
    }
    out
}

fn trash_deletion_date() -> String {
    std::process::Command::new("date")
        .arg("+%Y-%m-%dT%H:%M:%S")
        .output()
        .ok()
        .and_then(|output| if output.status.success() { Some(String::from_utf8_lossy(&output.stdout).trim().to_string()) } else { None })
        .filter(|value| !value.is_empty())
        .unwrap_or_else(|| "1970-01-01T00:00:00".to_string())
}

fn trash_current_uid() -> String {
    std::process::Command::new("id")
        .arg("-u")
        .output()
        .ok()
        .and_then(|output| if output.status.success() { Some(String::from_utf8_lossy(&output.stdout).trim().to_string()) } else { None })
        .filter(|value| !value.is_empty())
        .or_else(|| std::env::var("UID").ok())
        .unwrap_or_else(|| "1000".to_string())
}

fn trash_absolute_path(path: &std::path::Path) -> Result<std::path::PathBuf, String> {
    if path.is_absolute() {
        Ok(path.to_path_buf())
    } else {
        std::env::current_dir()
            .map(|cwd| cwd.join(path))
            .map_err(|error| format!("Could not make path absolute: {error}"))
    }
}

fn trash_mount_root(path: &std::path::Path) -> std::path::PathBuf {
    use std::os::unix::fs::MetadataExt;
    let metadata_path = if path.exists() { path } else { path.parent().unwrap_or(path) };
    let Ok(metadata) = std::fs::symlink_metadata(metadata_path) else { return std::path::PathBuf::from("/"); };
    let dev = metadata.dev();
    let mut current = if metadata_path.is_dir() { metadata_path.to_path_buf() } else { metadata_path.parent().unwrap_or(std::path::Path::new("/")).to_path_buf() };
    loop {
        let Some(parent) = current.parent() else { return current; };
        if parent == current { return current; }
        let Ok(parent_metadata) = std::fs::symlink_metadata(parent) else { return current; };
        if parent_metadata.dev() != dev { return current; }
        current = parent.to_path_buf();
    }
}

fn trash_base_dir(path: &std::path::Path) -> std::path::PathBuf {
    if let Some(home) = std::env::var_os("HOME") {
        let home_path = std::path::PathBuf::from(home);
        if path.starts_with(&home_path) {
            return home_path.join(".local/share/Trash");
        }
    }
    trash_mount_root(path).join(format!(".Trash-{}", trash_current_uid()))
}

fn trash_unique_destination(files_dir: &std::path::Path, file_name: &std::ffi::OsStr) -> std::path::PathBuf {
    let candidate = files_dir.join(file_name);
    if !candidate.exists() {
        return candidate;
    }
    let base = file_name.to_string_lossy();
    for index in 1..10000 {
        let candidate = files_dir.join(format!("{base}.{index}"));
        if !candidate.exists() {
            return candidate;
        }
    }
    files_dir.join(format!("{base}.{}", trash_deletion_date().replace(':', "-")))
}

fn move_path_to_trash(path: &std::path::Path) -> Result<(), String> {
    let absolute_path = trash_absolute_path(path)?;
    if !absolute_path.exists() {
        return Err(format!("Path does not exist: {}", absolute_path.display()));
    }
    let Some(file_name) = absolute_path.file_name() else {
        return Err(format!("Cannot trash path without a file name: {}", absolute_path.display()));
    };

    let trash_base = trash_base_dir(&absolute_path);
    let files_dir = trash_base.join("files");
    let info_dir = trash_base.join("info");
    std::fs::create_dir_all(&files_dir).map_err(|error| format!("Could not create {}: {error}", files_dir.display()))?;
    std::fs::create_dir_all(&info_dir).map_err(|error| format!("Could not create {}: {error}", info_dir.display()))?;

    let destination = trash_unique_destination(&files_dir, file_name);
    let info_name = format!("{}.trashinfo", destination.file_name().unwrap_or(file_name).to_string_lossy());
    let info_path = info_dir.join(info_name);
    let info = format!(
        "[Trash Info]\nPath={}\nDeletionDate={}\n",
        trash_percent_encode_path(&absolute_path),
        trash_deletion_date()
    );
    std::fs::write(&info_path, info).map_err(|error| format!("Could not write {}: {error}", info_path.display()))?;

    match std::fs::rename(&absolute_path, &destination) {
        Ok(()) => Ok(()),
        Err(error) => {
            let _ = std::fs::remove_file(&info_path);
            Err(format!("Could not move {} to Trash: {error}", absolute_path.display()))
        }
    }
}



#[derive(Clone)]
struct TrashPreviewItem {
    path: PathBuf,
    display_name: String,
    size_bytes: u64,
}

fn json_escape_string(value: &str) -> String {
    let mut out = String::new();
    for ch in value.chars() {
        match ch {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            ch if ch < ' ' => out.push_str(&format!("\\u{:04x}", ch as u32)),
            ch => out.push(ch),
        }
    }
    out
}

fn trash_preview_json(items: &[TrashPreviewItem]) -> String {
    let mut json = String::from("[");
    for (index, item) in items.iter().enumerate() {
        if index > 0 { json.push(','); }
        json.push_str(&format!(
            "{{\"checked\":true,\"path\":\"{}\",\"name\":\"{}\",\"sizeBytes\":{}}}",
            json_escape_string(&item.path.to_string_lossy()),
            json_escape_string(&item.display_name),
            item.size_bytes
        ));
    }
    json.push(']');
    json
}

fn collect_trash_preview_path(path: &std::path::Path, display_name: String, items: &mut Vec<TrashPreviewItem>) {
    let Ok(metadata) = std::fs::symlink_metadata(path) else { return; };
    if metadata.is_dir() && !metadata.file_type().is_symlink() {
        let Ok(entries) = std::fs::read_dir(path) else { return; };
        let mut children: Vec<std::path::PathBuf> = entries.filter_map(|entry| entry.ok().map(|entry| entry.path())).collect();
        children.sort_by(|a, b| a.file_name().cmp(&b.file_name()));
        for child in children {
            let Some(name) = child.file_name().map(|name| name.to_string_lossy().to_string()) else { continue; };
            collect_trash_preview_path(&child, format!("{display_name}/{name}"), items);
        }
    } else {
        items.push(TrashPreviewItem {
            path: path.to_path_buf(),
            display_name,
            size_bytes: metadata.len(),
        });
    }
}

fn trash_preview_items_for_paths(paths: &[String]) -> Vec<TrashPreviewItem> {
    let mut items = Vec::new();
    for raw_path in paths {
        let raw_path = raw_path.trim();
        if raw_path.is_empty() { continue; }
        let path = std::path::PathBuf::from(raw_path);
        let Ok(absolute_path) = trash_absolute_path(&path) else { continue; };
        let Some(name) = absolute_path.file_name().map(|name| name.to_string_lossy().to_string()) else { continue; };
        let Ok(metadata) = std::fs::symlink_metadata(&absolute_path) else { continue; };
        if metadata.is_dir() && !metadata.file_type().is_symlink() {
            collect_trash_preview_path(&absolute_path, name, &mut items);
        } else {
            collect_trash_preview_path(&absolute_path, format!("./{name}"), &mut items);
        }
    }
    items
}



fn preview_json_escape(value: &str) -> String {
    let mut escaped = String::new();
    for ch in value.chars() {
        match ch {
            '"' => escaped.push_str("\\\""),
            '\\' => escaped.push_str("\\\\"),
            '\n' => escaped.push_str("\\n"),
            '\r' => escaped.push_str("\\r"),
            '\t' => escaped.push_str("\\t"),
            ch if ch < ' ' => escaped.push_str(&format!("\\u{:04x}", ch as u32)),
            ch => escaped.push(ch),
        }
    }
    escaped
}

fn preview_cache_key(path: &str) -> String {
    use std::hash::{Hash, Hasher};
    let mut hasher = std::collections::hash_map::DefaultHasher::new();
    path.hash(&mut hasher);
    format!("{:016x}", hasher.finish())
}

fn preview_cache_dir_for(path: &str) -> PathBuf {
    std::env::temp_dir().join("folder-browser-preview").join(preview_cache_key(path))
}

fn ffprobe_duration_seconds(path: &std::path::Path) -> Option<f64> {
    let output = std::process::Command::new("ffprobe")
        .arg("-v").arg("error")
        .arg("-show_entries").arg("format=duration")
        .arg("-of").arg("default=noprint_wrappers=1:nokey=1")
        .arg(path)
        .output()
        .ok()?;
    if !output.status.success() { return None; }
    String::from_utf8_lossy(&output.stdout).trim().parse::<f64>().ok().filter(|value| *value > 0.0)
}

fn preview_video_frame_paths(path: &std::path::Path) -> Vec<PathBuf> {
    let path_string = path.to_string_lossy().to_string();
    let cache_dir = preview_cache_dir_for(&path_string);
    let _ = std::fs::create_dir_all(&cache_dir);
    let Some(duration) = ffprobe_duration_seconds(path) else { return Vec::new(); };
    let mut frames = Vec::new();
    for percent in 1..=9 {
        let timestamp = duration * (percent as f64) / 10.0;
        let output_path = cache_dir.join(format!("frame_{percent:02}.jpg"));
        if !output_path.exists() {
            let _ = std::process::Command::new("ffmpeg")
                .arg("-y")
                .arg("-hide_banner")
                .arg("-loglevel").arg("error")
                .arg("-ss").arg(format!("{timestamp:.3}"))
                .arg("-i").arg(path)
                .arg("-frames:v").arg("1")
                .arg("-q:v").arg("3")
                .arg(&output_path)
                .output();
        }
        if output_path.exists() {
            frames.push(output_path);
        }
    }
    frames
}

fn read_text_preview(path: &std::path::Path, max_bytes: usize) -> String {
    let Ok(bytes) = std::fs::read(path) else { return String::new(); };
    let bytes = if bytes.len() > max_bytes { &bytes[..max_bytes] } else { &bytes[..] };
    if bytes.iter().take(4096).any(|byte| *byte == 0) {
        return String::new();
    }
    String::from_utf8_lossy(bytes).to_string()
}


impl qobject::FolderBrowserController {
    pub fn increment_click_count(mut self: Pin<&mut Self>) {
        let previous = *self.click_count();
        let next = previous + 1;
        self.as_mut().set_click_count(next);
        self.as_mut().set_status_text(QString::from(format!(
            "Rust received button click #{next}"
        )));
    }

    pub fn set_path_from_qml(mut self: Pin<&mut Self>, path: &QString) {
        self.as_mut().set_current_path(path.clone());
        self.as_mut().set_status_text(QString::from(format!(
            "Path set from QML: {}",
            path.to_string()
        )));
    }

    pub fn trash_paths(mut self: Pin<&mut Self>, paths: &QString) {
        let paths: Vec<String> = paths
            .to_string()
            .lines()
            .map(|line| line.trim().to_string())
            .filter(|line| !line.is_empty())
            .collect();
        if paths.is_empty() {
            return;
        }

        let count = paths.len();
        let qt_thread = self.qt_thread();
        self.as_mut().set_status_text(QString::from(format!("Moving {count} item(s) to Trash…")));

        std::thread::spawn(move || {
            let mut errors = Vec::new();
            for path in &paths {
                if let Err(error) = move_path_to_trash(std::path::Path::new(path)) {
                    errors.push(error);
                }
            }
            let _ = qt_thread.queue(move |mut controller| {
                let error_count = errors.len();
                let moved_count = count.saturating_sub(error_count);
                if error_count == 0 {
                    controller.as_mut().set_status_text(QString::from(format!("Moved {count} item(s) to Trash")));
                } else {
                    controller.as_mut().set_status_text(QString::from(format!(
                        "Moved {moved_count} / {count} item(s) to Trash; {error_count} error(s)"
                    )));
                }

                if moved_count > 0 {
                    let requested_paths: std::collections::HashSet<PathBuf> = paths
                        .iter()
                        .map(PathBuf::from)
                        .collect();
                    let rows = &mut controller.as_mut().rust_mut().rows;
                    rows.retain(|row| !requested_paths.contains(&row.path));
                    let row_count = rows.len().min(i32::MAX as usize) as i32;
                    controller.as_mut().set_row_count(row_count);
                    bump_update_generation(controller.as_mut());
                }
            });
        });
    }

    pub fn preview_text(&self, path: &QString) -> QString {
        let raw_path = path.to_string();
        let local_path = normalize_local_path(&raw_path);
        QString::from(read_text_preview(std::path::Path::new(&local_path), 512 * 1024))
    }

    pub fn preview_video_frames(&self, path: &QString) -> QString {
        let raw_path = path.to_string();
        let local_path = normalize_local_path(&raw_path);
        let frames = preview_video_frame_paths(std::path::Path::new(&local_path));
        let mut json = String::from("[");
        for (index, frame) in frames.iter().enumerate() {
            if index > 0 { json.push(','); }
            json.push_str(&format!("\"{}\"", preview_json_escape(&frame.to_string_lossy())));
        }
        json.push(']');
        QString::from(json)
    }

    pub fn trash_preview_items(&self, paths: &QString) -> QString {
        let paths: Vec<String> = paths
            .to_string()
            .lines()
            .map(|line| line.trim().to_string())
            .filter(|line| !line.is_empty())
            .collect();
        QString::from(trash_preview_json(&trash_preview_items_for_paths(&paths)))
    }


            pub fn scan_path(mut self: Pin<&mut Self>, path: &QString) {
        let qt_thread = self.qt_thread();
        let raw_path = path.to_string();
        let local_path = normalize_local_path(&raw_path);
        let directory = Path::new(&local_path);
        let follow_symlinks = *self.follow_symlinks();

        self.as_mut().set_current_path(QString::from(local_path.clone()));
        let next_generation = self.rust().scan_generation.wrapping_add(1);
        self.as_mut().rust_mut().scan_generation = next_generation;
        let generation = next_generation;

        if !directory.exists() {
            self.as_mut().rust_mut().rows.clear();
            self.as_mut().set_row_count(0);
            self.as_mut().set_is_scanning(false);
            self.as_mut().set_size_scan_done(0);
            self.as_mut().set_size_scan_total(0);
            bump_update_generation(self.as_mut());
            self.as_mut().set_status_text(QString::from(format!("Path does not exist: {local_path}")));
            return;
        }

        if !directory.is_dir() {
            self.as_mut().rust_mut().rows.clear();
            self.as_mut().set_row_count(0);
            self.as_mut().set_is_scanning(false);
            self.as_mut().set_size_scan_done(0);
            self.as_mut().set_size_scan_total(0);
            bump_update_generation(self.as_mut());
            self.as_mut().set_status_text(QString::from(format!("Not a directory: {local_path}")));
            return;
        }

        let previous_directory_sizes: std::collections::HashMap<PathBuf, (Option<u64>, String)> = self
            .rust()
            .rows
            .iter()
            .filter(|row| row.is_dir)
            .map(|row| (row.path.clone(), (row.size_bytes, row.size_text.clone())))
            .collect();

        self.as_mut().rust_mut().rows.clear();
        self.as_mut().set_row_count(0);
        self.as_mut().set_size_scan_done(0);
        self.as_mut().set_size_scan_total(0);
        self.as_mut().set_is_scanning(true);
        bump_update_generation(self.as_mut());
        self.as_mut().set_status_text(QString::from(format!("Scanning {local_path}…")));

        let directory_for_scan = PathBuf::from(local_path.clone());
        let scan_qt_thread = qt_thread.clone();
        std::thread::spawn(move || {
            let scan_result = scan_directory(&directory_for_scan, follow_symlinks);
            let apply_qt_thread = scan_qt_thread.clone();
            let _ = scan_qt_thread.queue(move |mut controller| {
                if controller.rust().scan_generation != generation { return; }

                let rows = match scan_result {
                    Ok(rows) => rows,
                    Err(error) => {
                        controller.as_mut().rust_mut().rows.clear();
                        controller.as_mut().set_row_count(0);
                        controller.as_mut().set_is_scanning(false);
                        controller.as_mut().set_size_scan_done(0);
                        controller.as_mut().set_size_scan_total(0);
                        bump_update_generation(controller.as_mut());
                        controller.as_mut().set_status_text(QString::from(format!(
                            "Could not read directory {local_path}: {error}"
                        )));
                        return;
                    }
                };

                let directory_jobs: Vec<(usize, PathBuf)> = rows
                    .iter()
                    .enumerate()
                    .filter(|(_, row)| row.is_dir)
                    .map(|(index, row)| (index, row.path.clone()))
                    .collect();

                let analysis_jobs: Vec<(usize, PathBuf)> = rows
                    .iter()
                    .enumerate()
                    .filter(|(_, row)| row.mime_status == "scanning")
                    .map(|(index, row)| (index, row.path.clone()))
                    .collect();

                let mut rows = rows;
                for (row_index, _) in &directory_jobs {
                    if let Some(row) = rows.get_mut(*row_index) {
                        if let Some((previous_size_bytes, previous_size_text)) = previous_directory_sizes.get(&row.path) {
                            row.size_bytes = *previous_size_bytes;
                            row.size_text = previous_size_text.clone();
                            row.size_status = SizeStatus::Stale;
                        } else {
                            row.size_bytes = None;
                            row.size_text.clear();
                            row.size_status = SizeStatus::Scanning;
                        }
                    }
                }

                let count = rows.len();
                let size_scan_total = directory_jobs.len().min(i32::MAX as usize) as i32;
                let analysis_total = analysis_jobs.len();
                controller.as_mut().rust_mut().rows = rows;
                controller.as_mut().set_row_count(count.min(i32::MAX as usize) as i32);
                controller.as_mut().set_size_scan_done(0);
                controller.as_mut().set_size_scan_total(size_scan_total);
                controller.as_mut().set_is_scanning(size_scan_total > 0 || analysis_total > 0);
                bump_update_generation(controller.as_mut());

                let mut status_parts = Vec::new();
                status_parts.push(format!("Scanned {count} entries in {local_path}"));
                if !directory_jobs.is_empty() {
                    status_parts.push(format!("calculating {} directory sizes", directory_jobs.len()));
                }
                if analysis_total > 0 {
                    status_parts.push(format!("analyzing {analysis_total} files"));
                }
                controller.as_mut().set_status_text(QString::from(status_parts.join("; ")));

                // Combined per-file analysis worker. For each regular file, read the MIME type first;
                // if the same file is media, immediately run ffprobe before moving to the next file.
                // This avoids two cross-cutting passes that repeatedly open the same files.
                if !analysis_jobs.is_empty() {
                    let analysis_qt_thread = apply_qt_thread.clone();
                    std::thread::spawn(move || {
                        for (row_index, analysis_path) in analysis_jobs {
                            let mime_type = probe_mime_type(&analysis_path);
                            let should_probe_media = mime_type.starts_with("video/")
                                || mime_type.starts_with("audio/")
                                || is_media_path(&analysis_path);
                            let metadata = if should_probe_media {
                                Some(probe_media_metadata(&analysis_path))
                            } else {
                                None
                            };
                            let path_for_match = analysis_path.clone();
                            let _ = analysis_qt_thread.queue(move |mut controller| {
                                if controller.rust().scan_generation != generation { return; }
                                let changed = {
                                    let rows = &mut controller.as_mut().rust_mut().rows;
                                    if let Some(row) = rows.get_mut(row_index) {
                                        if row.path == path_for_match {
                                            row.mime_type = mime_type;
                                            row.mime_status = "done".to_string();
                                            if let Some(metadata) = metadata {
                                                if metadata.is_empty() {
                                                    mark_media_metadata_unavailable(row);
                                                } else {
                                                    apply_media_metadata(row, metadata);
                                                }
                                            } else if row.media_status == "scanning" {
                                                row.media_status = "none".to_string();
                                            }
                                            true
                                        } else { false }
                                    } else { false }
                                };
                                if changed { bump_update_generation(controller.as_mut()); }
                            });
                        }

                        let _ = analysis_qt_thread.queue(move |mut controller| {
                            if controller.rust().scan_generation == generation {
                                let still_sizing = *controller.size_scan_done() < *controller.size_scan_total();
                                if !still_sizing {
                                    controller.as_mut().set_is_scanning(false);
                                }
                                controller.as_mut().set_status_text(QString::from("File analysis finished"));
                            }
                        });
                    });
                }

                if !directory_jobs.is_empty() {
                    let size_qt_thread = apply_qt_thread.clone();
                    std::thread::spawn(move || {
                        let status_qt_thread = size_qt_thread.clone();
                        let mut batch = DirectorySizeBatch::new(size_qt_thread, generation);

                        for (row_index, dir_path) in directory_jobs {
                            let mut last_progress_update = Instant::now();

                            let result = calculate_directory_size(&dir_path, follow_symlinks, |partial_size| {
                                if last_progress_update.elapsed() >= Duration::from_secs(2) {
                                    batch.push(
                                        row_index,
                                        Some(partial_size),
                                        DirectorySizeStatusUpdate::Scanning,
                                    );
                                    batch.flush_if_needed(16, Duration::from_millis(750));
                                    last_progress_update = Instant::now();
                                }
                            });

                            match result {
                                Ok(final_size) => batch.push(
                                    row_index,
                                    Some(final_size),
                                    DirectorySizeStatusUpdate::Done,
                                ),
                                Err(_) => batch.push(row_index, None, DirectorySizeStatusUpdate::Error),
                            }

                            let progress_qt_thread = status_qt_thread.clone();
                            let _ = progress_qt_thread.queue(move |mut controller| {
                                if controller.rust().scan_generation == generation {
                                    let total = *controller.size_scan_total();
                                    let next = (*controller.size_scan_done()).saturating_add(1).min(total);
                                    controller.as_mut().set_size_scan_done(next);
                                    controller.as_mut().set_status_text(QString::from(format!(
                                        "Directory sizes: {next} / {total}"
                                    )));
                                }
                            });

                            batch.flush_if_needed(32, Duration::from_millis(750));
                            std::thread::sleep(Duration::from_millis(5));
                        }

                        batch.flush();

                        let _ = status_qt_thread.queue(move |mut controller| {
                            if controller.rust().scan_generation == generation {
                                let total = *controller.size_scan_total();
                                controller.as_mut().set_size_scan_done(total);
                                let still_analyzing = controller.rust().rows.iter().any(|row| {
                                    row.mime_status == "scanning" || row.media_status == "scanning"
                                });
                                if !still_analyzing {
                                    controller.as_mut().set_is_scanning(false);
                                }
                                controller.as_mut().set_status_text(QString::from(format!(
                                    "Directory size calculation finished ({total} / {total})"
                                )));
                            }
                        });
                    });
                }
            });
        });
    }










}
