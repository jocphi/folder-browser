#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-folder-browser-feature-src-b64.txt}"

FILES=(
    Cargo.toml
    build.rs
    src/main.rs
    src/cxxqt_object.rs
    src/scanner.rs
    src/dir_size_worker.rs
    src/file_row.rs
    src/file_size_status.rs
    src/formatting.rs
    src/signals.rs
    qml/main.qml
    qml/PathBar.qml
    qml/StatusBar.qml
    qml/FileListView.qml
)

rm -f "$OUT"

{
    echo "===== BASE64 SOURCE SNAPSHOT START ====="
    echo "Project: folder-browser-cxxqt-minimal"
    echo "Generated: $(date -Is)"
    echo

    for file in "${FILES[@]}"; do
        if [[ -f "$file" ]]; then
            echo "===== FILE START: $file ====="
            echo "sha256: $(sha256sum "$file" | awk '{print $1}')"
            echo "bytes: $(wc -c < "$file")"
            echo "base64:"
            base64 -w 0 "$file"
            echo
            echo "===== FILE END: $file ====="
            echo
        else
            echo "===== MISSING FILE: $file ====="
            echo
        fi
    done

    echo "===== BASE64 SOURCE SNAPSHOT END ====="
} > "$OUT"

echo "Wrote: $OUT"
wc -l "$OUT"
wc -c "$OUT"
