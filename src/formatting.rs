pub(crate) fn format_size(size_bytes: Option<u64>) -> String {
    let Some(bytes) = size_bytes else {
        return String::new();
    };

    const UNITS: [&str; 5] = ["B", "kB", "MB", "GB", "TB"];
    let mut value = bytes as f64;
    let mut unit_index = 0usize;

    while value >= 1000.0 && unit_index < UNITS.len() - 1 {
        value /= 1000.0;
        unit_index += 1;
    }

    if unit_index == 0 {
        format!("{bytes} B")
    } else {
        format!("{value:.2} {}", UNITS[unit_index])
    }
}

pub(crate) fn normalize_local_path(input: &str) -> String {
    input.strip_prefix("file://").unwrap_or(input).to_string()
}
