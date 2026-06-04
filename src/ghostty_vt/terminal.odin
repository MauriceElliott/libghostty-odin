package ghostty_vt

import vt_c "../ghostty_vt_c"

#assert(size_of(vt_c.TerminalOptions) == 16)

Terminal :: struct {
	handle: vt_c.Terminal,
}

terminal_new :: proc(cols: u16, rows: u16, max_scroll: uint) -> (Terminal, Error) {
	opts: vt_c.TerminalOptions = {
		cols           = cols,
		rows           = rows,
		max_scrollback = max_scroll,
	}
	h: vt_c.Terminal
	if r := vt_c.terminal_new(nil, &h, opts); r != .SUCCESS {
		return {}, result_to_error(r)
	}
	return Terminal{handle = h}, .None
}

terminal_destroy :: proc(t: ^Terminal) {
	vt_c.terminal_free(t.handle)
	t.handle = nil
}

terminal_reset :: proc(t: ^Terminal) {
	vt_c.terminal_reset(t.handle)
}

terminal_resize :: proc(
	t: ^Terminal,
	cols, rows: u16,
	cell_width_px, cell_height_px: u32,
) -> Error {
	return result_to_error(
		vt_c.terminal_resize(t.handle, cols, rows, cell_width_px, cell_height_px),
	)
}

terminal_write :: proc(t: ^Terminal, data: []u8) {
	if len(data) == 0 {return}
	vt_c.terminal_vt_write(t.handle, raw_data(data), uint(len(data)))
}

