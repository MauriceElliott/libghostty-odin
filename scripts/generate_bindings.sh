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

BINDGEN_DIR="$REPO_ROOT/bindgen"
TEMP_CONFIG="$BINDGEN_DIR/bindgen_macos_temp.sjson"

# libclang (Homebrew LLVM) can't auto-locate its own resource directory when run
# via symlinked paths, so stdbool.h / stdint.h / stddef.h / limits.h are not found.
# Resolve the resource dir explicitly from the same clang that libclang belongs to.
CLANG_RESOURCE_INCLUDE="$($(brew --prefix llvm)/bin/clang -print-resource-dir)/include"

python3 -c "
import pathlib
content = pathlib.Path('$BINDGEN_DIR/bindgen.sjson').read_text()
patched = content.replace(
    '\"build/ghostty-install/include\"',
    '\"build/ghostty-install/include\",\n    \"$CLANG_RESOURCE_INCLUDE\"'
)
pathlib.Path('$TEMP_CONFIG').write_text(patched)
"
trap 'rm -f "$TEMP_CONFIG"' EXIT
"$TOOL_BIN" "$TEMP_CONFIG"
