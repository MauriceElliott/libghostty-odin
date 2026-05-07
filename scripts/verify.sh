#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="$REPO_ROOT/build/ghostty-install"
PROBE="$REPO_ROOT/build/verify_probe"

cc -o "$PROBE" \
    -I"$INSTALL_DIR/include" \
    -L"$INSTALL_DIR/lib" \
    -Wl,-rpath,"$INSTALL_DIR/lib" \
    -lghostty-vt \
    - <<'EOF'
#include <stdio.h>
#include "ghostty/vt.h"
int main(void) { puts(ghostty_type_json()); return 0; }
EOF

EXPECTED_PASS=1

check() {
    local name="$1" field="$2" expected="$3" actual
    actual=$("$PROBE" | jq -r ".${name}.${field}")
    if [[ "$actual" == "$expected" ]]; then
        echo "ok  $name.$field == $expected"
    else
        echo "FAIL $name.$field: expected $expected, got $actual"
        EXPECTED_PASS=0
    fi
}

check "GhosttyStyle"           size  72
check "GhosttyStyle"           align 8
check "GhosttyTerminalOptions" size  16
check "GhosttyTerminalOptions" align 8

rm "$PROBE"

[[ $EXPECTED_PASS -eq 1 ]]
