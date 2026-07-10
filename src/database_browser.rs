use crate::file_row::FileRow;
use crate::file_size_status::SizeStatus;
use crate::formatting::format_size;
use rusqlite::{params, Connection, OptionalExtension};
use std::path::{Path, PathBuf};

// The database row mirrors the reusable everything-rust child-row shape.
// Some fields are reserved for the upcoming database-backed frontend mode.
#[allow(dead_code)]
#[derive(Clone, Debug)]
struct DbChildRow {
    path: String,
    name: String,
    size: i64,
    mtime: i64,
    is_dir: bool,
    ext: String,
}

pub(crate) fn scan_database_directory(path: &str) -> Result<Vec<FileRow>, String> {
    let db_path = default_everything_rust_db_path();
    let conn = Connection::open(&db_path)
        .map_err(|error| format!("open database {}: {error}", db_path.display()))?;
    let rows = query_children(&conn, Path::new(path), 100_000)
        .map_err(|error| format!("query database children for {path}: {error}"))?;

    Ok(rows.into_iter().map(db_row_to_file_row).collect())
}

fn query_children(conn: &Connection, parent: &Path, limit: usize) -> rusqlite::Result<Vec<DbChildRow>> {
    let parent = normalize_db_parent_path(parent);
    let limit = limit.clamp(1, 100_000) as i64;
    let Some(parent_id) = lookup_parent_id(conn, &parent)? else {
        return Ok(Vec::new());
    };

    let mut stmt = conn.prepare(
        "SELECT path, name, size, mtime, is_dir, ext
         FROM files
         WHERE parent_id = ?1
         ORDER BY is_dir DESC, lower(name) ASC, name ASC
         LIMIT ?2",
    )?;

    let rows = stmt.query_map(params![parent_id, limit], |row| {
        Ok(DbChildRow {
            path: row.get(0)?,
            name: row.get(1)?,
            size: row.get(2)?,
            mtime: row.get(3)?,
            is_dir: row.get(4)?,
            ext: row.get(5)?,
        })
    })?;

    let mut out = Vec::new();
    for row in rows {
        out.push(row?);
    }
    Ok(out)
}

fn lookup_parent_id(conn: &Connection, parent: &str) -> rusqlite::Result<Option<i64>> {
    conn.query_row("SELECT id FROM files WHERE path = ?1", params![parent], |row| row.get(0))
        .optional()
}

fn db_row_to_file_row(row: DbChildRow) -> FileRow {
    let size_bytes = if row.is_dir || row.size < 0 {
        None
    } else {
        Some(row.size as u64)
    };
    let kind = if row.is_dir { "folder" } else { "file" }.to_string();
    let mime_type = if row.is_dir {
        "inode/directory".to_string()
    } else {
        String::new()
    };

    FileRow {
        name: row.name,
        kind,
        mime_type,
        mime_status: "done".to_string(),
        media_status: "none".to_string(),
        size_bytes,
        size_text: format_size(size_bytes),
        size_status: if row.is_dir { SizeStatus::Unknown } else { SizeStatus::File },
        modified_secs: if row.mtime >= 0 { Some(row.mtime as u64) } else { None },
        duration_secs: None,
        codec: String::new(),
        video_codec: String::new(),
        audio_codec: String::new(),
        bitrate: None,
        fps: None,
        media_width: None,
        media_height: None,
        path: PathBuf::from(row.path),
        is_dir: row.is_dir,
    }
}

fn normalize_db_parent_path(parent: &Path) -> String {
    let mut s = parent.to_string_lossy().into_owned();
    if s.is_empty() {
        return "/".to_string();
    }
    while s.len() > 1 && s.ends_with('/') {
        s.pop();
    }
    s
}

fn default_everything_rust_db_path() -> PathBuf {
    std::env::var_os("HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from("."))
        .join(".local/share/everything-rust/files.db")
}
