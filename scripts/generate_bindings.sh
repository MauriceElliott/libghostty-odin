#!/usr/bin/env bash

# Generate the ghostty_vt_c Odin bindings from Ghostty's vt/*.h using [odin-c-bindgen](https://github.com/karl-zylinski/odin-c-bindgen) (package/odin-c-bindgen).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOL_BIN="$REPO_ROOT/build/bindgen/bindgen"

# Build the tool if missing or if any source file is newer than the binary.
if [[ ! -f "$TOOL_BIN" ]] || find "$REPO_ROOT/package/odin-c-bindgen" -name '*.odin' -newer "$TOOL_BIN" | grep -q .; then
    mkdir -p "$(dirname "$TOOL_BIN")"
    odin build "$REPO_ROOT/package/odin-c-bindgen/src" -out:"$TOOL_BIN" -o:speed
fi

rm -rf "$REPO_ROOT/src/ghostty_vt_c"

cd "$REPO_ROOT"
"$TOOL_BIN" "$REPO_ROOT/bindgen"
