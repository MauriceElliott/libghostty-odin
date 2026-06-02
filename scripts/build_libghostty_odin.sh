#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "$REPO_ROOT/build/odin"
odin build "$REPO_ROOT/example/ghostling/" -out:"$REPO_ROOT/build/odin/ghostling" -debug -extra-linker-flags:"-Wl,-rpath,$REPO_ROOT/build/ghostty-install/lib"
cp -r "$REPO_ROOT/example/ghostling/resources" "$REPO_ROOT/build/odin/"
