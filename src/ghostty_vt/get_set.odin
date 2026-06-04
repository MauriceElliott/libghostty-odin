package ghostty_vt

import vt_c "../ghostty_vt_c"

terminal_get_cols :: proc(t: ^Terminal) -> (v: u16, err: Error) {
	err = result_to_error(vt_c.terminal_get(t.handle, .COLS, &v))
	return
}

terminal_get_rows :: proc(t: ^Terminal) -> (v: u16, err: Error) {
	err = result_to_error(vt_c.terminal_get(t.handle, .ROWS, &v))
	return
}

terminal_get_cursor_pos :: proc(t: ^Terminal) -> (x, y: u16, err: Error) {
	if r := vt_c.terminal_get(t.handle, .CURSOR_X, &x); r != .SUCCESS {
		return 0, 0, result_to_error(r)
	}
	if r := vt_c.terminal_get(t.handle, .CURSOR_Y, &y); r != .SUCCESS {
		return 0, 0, result_to_error(r)
	}
	return
}

// terminal_get_title returns a copy of the terminal title.
// The caller must free the returned string with delete().
terminal_get_title :: proc(t: ^Terminal) -> string {
	v: vt_c.String
	vt_c.terminal_get(t.handle, .TITLE, &v)
	buf := make([]u8, v.len)
	copy(buf, ([^]u8)(v.ptr)[:v.len])
	return string(buf)
}

terminal_set_title :: proc(t: ^Terminal, title: string) -> Error {
	buf := make([]u8, len(title))
	copy(buf, transmute([]u8)title)
	defer delete(buf)

	v := vt_c.String {
		ptr = raw_data(buf),
		len = uint(len(buf)),
	}
	return result_to_error(vt_c.terminal_set(t.handle, .TITLE, &v))
}

// terminal_get_default_fg returns the default foreground color.
// ok is false when no default has been set.
terminal_get_default_fg :: proc(t: ^Terminal) -> (color: vt_c.ColorRgb, ok: bool) {
	r := vt_c.terminal_get(t.handle, .COLOR_FOREGROUND, &color)
	return color, r == .SUCCESS
}

// terminal_get_default_bg returns the default background color.
// ok is false when no default has been set.
terminal_get_default_bg :: proc(t: ^Terminal) -> (color: vt_c.ColorRgb, ok: bool) {
	r := vt_c.terminal_get(t.handle, .COLOR_BACKGROUND, &color)
	return color, r == .SUCCESS
}

terminal_set_kitty_image_protocol_storage_limit :: proc(t: ^Terminal, limit: u64) {
	l := new(u64)
	l^ = limit
	vt_c.terminal_set(t.handle, .KITTY_IMAGE_STORAGE_LIMIT, rawptr(&l))
}

terminal_set_kitty_image_from_file_allowed :: proc(t: ^Terminal, allowed: bool) {
	a := new(bool)
	a^ = allowed
	vt_c.terminal_set(t.handle, .KITTY_IMAGE_MEDIUM_FILE, rawptr(&a))
}

