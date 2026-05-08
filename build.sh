#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "${1:-}" in
    gen)
        "$REPO_ROOT/scripts/generate_bindings.sh"
        ;;
    "")
        "$REPO_ROOT/scripts/build_libghostty.sh"
        "$REPO_ROOT/scripts/build_libghostty_odin.sh"
        "$REPO_ROOT/build/odin/ghostling"
        ;;
    *)
        echo "Usage: $0 [gen]" >&2
        exit 1
        ;;
esac
