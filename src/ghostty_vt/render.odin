package ghostty_vt

import vt_c "../ghostty_vt_c"

Render_State :: struct {
	handle: vt_c.RenderState,
}

render_state_new :: proc() -> (Render_State, Error) {
	rs: Render_State
	if r := vt_c.render_state_new(nil, &rs.handle); r != .SUCCESS {
		return {}, result_to_error(r)
	}
	return rs, .None
}

render_state_destroy :: proc(rs: ^Render_State) {
	vt_c.render_state_free(rs.handle)
	rs.handle = nil
}

render_state_update :: proc(rs: Render_State, t: Terminal) -> Error {
	return result_to_error(vt_c.render_state_update(rs.handle, t.handle))
}
