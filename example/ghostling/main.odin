package main

import vt "../../src/ghostty_vt"
import vt_c "../../src/ghostty_vt_c"
import "core:fmt"
import "core:math"
import rl "vendor:raylib"

grid_size :: proc(win_w: f32, win_h: f32, cell_w: f32, cell_h: f32) -> (f32, f32) {
	max_width := math.max(1, math.floor(win_w - 2 * padding) / cell_w)
	max_height := math.max(1, math.floor(win_h - 2 * padding) / cell_h)
	return max_width, max_height

}

font_size :: 10
padding :: 6.0
cell_gap :: 0.0
row_gap :: 12.0

init :: proc() -> vt.Terminal {
	font := rl.LoadFontEx("resources/fonts/jetbrains.ttf", font_size, nil, 0)
	glyph := rl.MeasureTextEx(font, "m", font_size, 0)
	win_w := cast(f32)rl.GetScreenWidth()
	win_h := cast(f32)rl.GetScreenHeight()
	cell_width := glyph.x + cell_gap
	cell_height := glyph.y + row_gap

	cols, rows := grid_size(win_w, win_h, cell_width, cell_height)

	terminal, err := vt.terminal_new(cast(u16)cols, cast(u16)rows, 1000)

	if err != nil {
		fmt.eprintln("Error retrieving new terminal:", err)
	}

	return terminal
}

main :: proc() {
	rl.InitWindow(800, 600, "Ghostling")

	defer rl.CloseWindow()
	for !rl.WindowShouldClose() {
		term := init()
		defer vt.terminal_destroy(&term)

		vt.terminal_vt_write(term, transmute([]u8)string("Hello\r\n"))

		fmt.println("OK: terminal created, wrote VT bytes, destroyed")
	}
}

