use crate::file_row::FileRow;
use crate::file_size_status::SizeStatus;
use crate::formatting::format_size;
use std::fs;
use std::path::Path;
use std::time::UNIX_EPOCH;

pub(crate) fn scan_directory(
    directory: &Path,
    follow_symlinks: bool,
) -> Result<Vec<FileRow>, std::io::Error> {
    let mut rows: Vec<FileRow> = Vec::new();

    for entry_result in fs::read_dir(directory)? {
        let entry = match entry_result {
            Ok(entry) => entry,
            Err(error) => {
                rows.push(FileRow {
                    name: format!("<unreadable entry: {error}>"),
                    kind: "error".to_string(),
                    size_bytes: None,
                    size_text: String::new(),
                    size_status: SizeStatus::Error,
                    modified_secs: None,
                    duration_secs: None,
                    codec: String::new(),
                    bitrate: None,
                    fps: None,
                    media_width: None,
                    media_height: None,
                    path: directory.to_path_buf(),
                    is_dir: false,
                });
                continue;
            }
        };

        let path = entry.path();
        let name = entry.file_name().to_string_lossy().into_owned();
        let file_type = entry.file_type();
        let is_symlink = file_type.as_ref().map(|kind| kind.is_symlink()).unwrap_or(false);

        let metadata = if follow_symlinks && is_symlink {
            fs::metadata(&path).ok()
        } else {
            entry.metadata().ok()
        };

        let is_dir = if follow_symlinks && is_symlink {
            metadata.as_ref().map(|metadata| metadata.is_dir()).unwrap_or(false)
        } else {
            file_type.as_ref().map(|kind| kind.is_dir()).unwrap_or(false)
        };
        let is_file = if follow_symlinks && is_symlink {
            metadata.as_ref().map(|metadata| metadata.is_file()).unwrap_or(false)
        } else {
            file_type.as_ref().map(|kind| kind.is_file()).unwrap_or(false)
        };

        let kind = if is_symlink {
            "symlink"
        } else if is_dir {
            "folder"
        } else if is_file {
            "file"
        } else {
            "other"
        }.to_string();

        let size_bytes = if is_file { metadata.as_ref().map(|metadata| metadata.len()) } else { None };
        let size_status = if is_dir { SizeStatus::Unknown } else { SizeStatus::File };

        let modified_secs = metadata
            .as_ref()
            .and_then(|metadata| metadata.modified().ok())
            .and_then(|modified| modified.duration_since(UNIX_EPOCH).ok())
            .map(|duration| duration.as_secs());

        rows.push(FileRow {
            name,
            kind,
            size_bytes,
            size_text: format_size(size_bytes),
            size_status,
            modified_secs,
            duration_secs: None,
            codec: String::new(),
            bitrate: None,
            fps: None,
            media_width: None,
            media_height: None,
            path,
            is_dir,
        });
    }

    rows.sort_by(|left, right| {
        right.is_dir.cmp(&left.is_dir).then_with(|| left.name.to_lowercase().cmp(&right.name.to_lowercase()))
    });

    Ok(rows)
}
