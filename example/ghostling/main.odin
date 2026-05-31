package main

import "core:fmt"
import vt_c "../../src/ghostty_vt_c"
import vt "../../src/ghostty_vt"
import rl "vendor:raylib"
import "core:math"

grid_size :: proc(win_w: int, win_h: int, cell_w: int, cell_h: int) -> (f32, f32) {
    return math.max(1, math.floor(win_w - 2 * PADDING) / cell_w),
           math.max(1, math.floor(win_h - 2 * PADDING) / cell_h)
}

init :: proc() -> Terminal {
    font_size :: 10
    padding   :: 6.0
    cell_gap  :: 0.0
    row_gap   :: 12.0

    font        := rl.loadfontex("./JetBrainsMono-Medium.ttf", font_size, nil, 0)
    glyph       := rl.measuretextex(font, "m", font_size, 0)
    cell_width  := glyph.x + cell_gap
    cell_height := glyph.y + row_gap

    cols, rows := grid_size(window.width(), window.height(), cell_width, cell_height)

    terminal, err := vt.terminal_new(cols, rows, 1000)

    if err != nil {
        fmt.eprintln("Error retrieving new terminal:", err)
    }

    return terminal
}

main :: proc() {
    term := init()
    defer vt.terminal_destroy(&t)

    vt.terminal_vt_write(t, transmute([]u8)string("Hello\r\n"))

    fmt.println("OK: terminal created, wrote VT bytes, destroyed")
}

