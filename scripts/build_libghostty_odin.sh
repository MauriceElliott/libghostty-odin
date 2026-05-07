#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="$REPO_ROOT/build/odin/"

odin build "$REPO_ROOT/example/ghostling/" -out:$INSTALL_DIR -debug -o:speed
