package main

import "core:fmt"
import vt_c "../../src/ghostty_vt_c"
import vt "../../src/ghostty_vt"

main :: proc() {
    opts := vt_c.TerminalOptions{cols = 80, rows = 24, max_scrollback = 1000}
    t, err := vt.terminal_new(opts)
    if err != .None {
        fmt.eprintln("terminal_new failed:", err)
        return
    }
    defer vt.terminal_destroy(&t)

    vt.terminal_vt_write(t, transmute([]u8)string("Hello\r\n"))

    fmt.println("OK: terminal created, wrote VT bytes, destroyed")
}
