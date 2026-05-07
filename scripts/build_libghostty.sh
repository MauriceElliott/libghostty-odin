#!/usr/bin/env bash
set -euo pipefail

GHOSTTY_COMMIT="6590196661f769dd8f2b3e85d6c98262c4ec5b3b"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GHOSTTY_SRC="${GHOSTTY_SOURCE_DIR:-$REPO_ROOT/build/ghostty-src}"
INSTALL_DIR="$REPO_ROOT/build/ghostty-install"

if [[ -z "${GHOSTTY_SOURCE_DIR:-}" ]]; then
    if [[ ! -f "$GHOSTTY_SRC/.ghostty-commit" ]] || [[ "$(cat "$GHOSTTY_SRC/.ghostty-commit")" != "$GHOSTTY_COMMIT" ]]; then
        rm -rf "$GHOSTTY_SRC"
        git clone --filter=blob:none --no-checkout "https://github.com/ghostty-org/ghostty.git" "$GHOSTTY_SRC"
        git -C "$GHOSTTY_SRC" checkout "$GHOSTTY_COMMIT"
        echo "$GHOSTTY_COMMIT" > "$GHOSTTY_SRC/.ghostty-commit"
    fi
fi

ZIG_ARGS=(build -Demit-lib-vt -Doptimize=ReleaseFast -Demit-xcframework=false -Dapp-runtime=none --prefix "$INSTALL_DIR" --cache-dir "$REPO_ROOT/build/zig-cache")

if [[ -n "${GHOSTTY_ZIG_SYSTEM_DIR:-}" ]]; then
    ZIG_ARGS+=(--system "$GHOSTTY_ZIG_SYSTEM_DIR" --global-cache-dir "$REPO_ROOT/build/zig-global-cache")
fi

(cd "$GHOSTTY_SRC" && zig "${ZIG_ARGS[@]}")
