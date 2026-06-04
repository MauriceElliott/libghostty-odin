package ghostty_vt

import vt_c "../ghostty_vt_c"

Row_Iterator :: struct {
	handle: vt_c.RenderStateRowIterator,
}

row_iterator_new :: proc() -> (Row_Iterator, Error) {
	ri: Row_Iterator
	if r := vt_c.render_state_row_iterator_new(nil, &ri.handle); r != .SUCCESS {
		return {}, result_to_error(r)
	}
	return ri, .None
}

row_iterator_destroy :: proc(ri: ^Row_Iterator) {
	vt_c.render_state_row_iterator_free(ri.handle)
	ri.handle = nil
}

// Populate from a render state. Must be called before the first next().
row_iterator_populate :: proc(ri: ^Row_Iterator, rs: Render_State) -> Error {
	return result_to_error(vt_c.render_state_get(rs.handle, .ROW_ITERATOR, &ri.handle))
}

row_iterator_next :: proc(ri: Row_Iterator) -> bool {
	return vt_c.render_state_row_iterator_next(ri.handle)
}

Row_Cells :: struct {
	handle: vt_c.RenderStateRowCells,
}

row_cells_new :: proc() -> (Row_Cells, Error) {
	rc: Row_Cells
	if r := vt_c.render_state_row_cells_new(nil, &rc.handle); r != .SUCCESS {
		return {}, result_to_error(r)
	}
	return rc, .None
}

row_cells_destroy :: proc(rc: ^Row_Cells) {
	vt_c.render_state_row_cells_free(rc.handle)
	rc.handle = nil
}

// Populate cells for the current row. Reusable across rows.
row_cells_populate :: proc(rc: ^Row_Cells, ri: Row_Iterator) -> Error {
	return result_to_error(vt_c.render_state_row_get(ri.handle, .CELLS, &rc.handle))
}

row_cells_next :: proc(rc: Row_Cells) -> bool {
	return vt_c.render_state_row_cells_next(rc.handle)
}

// cell_graphemes returns the UTF-32 codepoints for the current cell.
// The returned slice is caller-owned and must be freed with delete().
// Returns nil and false when the cell has no text.
cell_graphemes :: proc(
	rc: Row_Cells,
	allocator := context.allocator,
) -> (
	codepoints: []u32,
	ok: bool,
) {
	n: u32
	if r := vt_c.render_state_row_cells_get(rc.handle, .GRAPHEMES_LEN, &n);
	   r != .SUCCESS || n == 0 {
		return nil, false
	}
	buf := make([]u32, n, allocator)
	if r := vt_c.render_state_row_cells_get(rc.handle, .GRAPHEMES_BUF, raw_data(buf));
	   r != .SUCCESS {
		delete(buf, allocator)
		return nil, false
	}
	return buf, true
}

// cell_fg_color returns the foreground color for the current cell.
// ok is false when NO_VALUE is returned (cell uses the terminal default).
cell_fg_color :: proc(rc: Row_Cells) -> (color: vt_c.ColorRgb, ok: bool) {
	r := vt_c.render_state_row_cells_get(rc.handle, .FG_COLOR, &color)
	return color, r == .SUCCESS
}

// cell_bg_color returns the background color for the current cell.
// ok is false when NO_VALUE is returned (cell uses the terminal default).
cell_bg_color :: proc(rc: Row_Cells) -> (color: vt_c.ColorRgb, ok: bool) {
	r := vt_c.render_state_row_cells_get(rc.handle, .BG_COLOR, &color)
	return color, r == .SUCCESS
}

