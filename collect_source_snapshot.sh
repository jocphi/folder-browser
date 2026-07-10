#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-folder-browser-current-src.txt}"

rm -f "$OUT"

{
    echo "===== SOURCE SNAPSHOT START ====="
    echo "Project: folder-browser-cxxqt-minimal"
    echo "Generated: $(date -Is)"
    echo

    find Cargo.toml build.rs src qml \
        -type f \
        \( -name '*.rs' -o -name '*.qml' -o -name '*.toml' \) \
        | sort \
        | while IFS= read -r file; do
            echo
            echo "===== FILE START: $file ====="
            echo
            cat "$file"
            echo
            echo "===== FILE END: $file ====="
        done

    echo
    echo "===== SOURCE SNAPSHOT END ====="
} > "$OUT"

echo "Wrote: $OUT"
wc -l "$OUT"
wc -c "$OUT"
