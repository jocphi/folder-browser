use std::collections::HashSet;
use std::fs;
use std::path::{Path, PathBuf};

#[derive(Clone, Debug, Default)]
pub(crate) struct TreeCountResult {
    pub(crate) path: String,
    pub(crate) direct_files: u64,
    pub(crate) recursive_files: u64,
    pub(crate) direct_folders: u64,
    pub(crate) recursive_folders: u64,
    pub(crate) complete: bool,
}

pub(crate) fn count_tree_path(path: &Path, follow_symlinks: bool) -> TreeCountResult {
    let path_string = path.to_string_lossy().into_owned();
    let mut result = TreeCountResult {
        path: path_string,
        complete: true,
        ..TreeCountResult::default()
    };

    let Ok(entries) = fs::read_dir(path) else {
        result.complete = false;
        return result;
    };

    let mut subfolders = Vec::new();
    for entry_result in entries {
        let Ok(entry) = entry_result else {
            result.complete = false;
            continue;
        };
        let Ok(file_type) = entry.file_type() else {
            result.complete = false;
            continue;
        };
        let entry_path = entry.path();
        if file_type.is_dir() {
            result.direct_folders = result.direct_folders.saturating_add(1);
            subfolders.push(entry_path);
        } else if file_type.is_file() {
            result.direct_files = result.direct_files.saturating_add(1);
        } else if follow_symlinks && file_type.is_symlink() {
            match fs::metadata(&entry_path) {
                Ok(metadata) if metadata.is_dir() => {
                    result.direct_folders = result.direct_folders.saturating_add(1);
                    subfolders.push(entry_path);
                }
                Ok(metadata) if metadata.is_file() => {
                    result.direct_files = result.direct_files.saturating_add(1);
                }
                _ => {}
            }
        }
    }

    let mut visited = HashSet::new();
    for folder in subfolders {
        count_descendants(&folder, follow_symlinks, &mut visited, &mut result);
    }

    result
}

fn count_descendants(
    directory: &Path,
    follow_symlinks: bool,
    visited: &mut HashSet<PathBuf>,
    result: &mut TreeCountResult,
) {
    let identity = if follow_symlinks {
        fs::canonicalize(directory).unwrap_or_else(|_| directory.to_path_buf())
    } else {
        directory.to_path_buf()
    };
    if !visited.insert(identity) {
        return;
    }

    let Ok(entries) = fs::read_dir(directory) else {
        result.complete = false;
        return;
    };

    for entry_result in entries {
        let Ok(entry) = entry_result else {
            result.complete = false;
            continue;
        };
        let Ok(file_type) = entry.file_type() else {
            result.complete = false;
            continue;
        };
        let entry_path = entry.path();
        if file_type.is_dir() {
            result.recursive_folders = result.recursive_folders.saturating_add(1);
            count_descendants(&entry_path, follow_symlinks, visited, result);
        } else if file_type.is_file() {
            result.recursive_files = result.recursive_files.saturating_add(1);
        } else if follow_symlinks && file_type.is_symlink() {
            match fs::metadata(&entry_path) {
                Ok(metadata) if metadata.is_dir() => {
                    result.recursive_folders = result.recursive_folders.saturating_add(1);
                    count_descendants(&entry_path, follow_symlinks, visited, result);
                }
                Ok(metadata) if metadata.is_file() => {
                    result.recursive_files = result.recursive_files.saturating_add(1);
                }
                _ => {}
            }
        }
    }
}

pub(crate) fn tree_count_json(result: &TreeCountResult) -> String {
    format!(
        "{{\"path\":\"{}\",\"directFiles\":{},\"recursiveFiles\":{},\"directFolders\":{},\"recursiveFolders\":{},\"done\":{}}}",
        json_escape(&result.path),
        result.direct_files,
        result.recursive_files,
        result.direct_folders,
        result.recursive_folders,
        if result.complete { "true" } else { "false" }
    )
}

fn json_escape(value: &str) -> String {
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
