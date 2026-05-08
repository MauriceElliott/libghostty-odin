/**
 * @file render.h
 *
 * Render state for creating high performance renderers.
 */
package ghostty_vt_c

import "core:c"

// Platform-specific foreign import declarations for libghostty-vt.
//
// This file is included verbatim near the top of the generated binding file
// by odin-c-bindgen (via the `imports_file` setting in bindgen.sjson).
//
// The library is vendored via scripts/build_libghostty.sh into build/ghostty-install/.
// Use an explicit relative path rather than "system:ghostty-vt" so that the
// vendored build is always used, regardless of what is installed system-wide.
when ODIN_OS == .Linux {
    foreign import lib "../../build/ghostty-install/lib/libghostty-vt.so"
} else when ODIN_OS == .Darwin {
    foreign import lib "../../build/ghostty-install/lib/libghostty-vt.dylib"
} else when ODIN_OS == .Windows {
    foreign import lib "../../build/ghostty-install/lib/ghostty-vt.lib"
}


/**
* Dirty state of a render state after update.
*
* @ingroup render
*/
RenderStateDirty :: enum u32 {
	/** Not dirty at all; rendering can be skipped. */
	FALSE     = 0,

	/** Some rows changed; renderer can redraw incrementally. */
	PARTIAL   = 1,

	/** Global state changed; renderer should redraw everything. */
	FULL      = 2,
	MAX_VALUE = 2147483647,
}

/**
* Visual style of the cursor.
*
* @ingroup render
*/
RenderStateCursorVisualStyle :: enum u32 {
	/** Bar cursor (DECSCUSR 5, 6). */
	BAR          = 0,

	/** Block cursor (DECSCUSR 1, 2). */
	BLOCK        = 1,

	/** Underline cursor (DECSCUSR 3, 4). */
	UNDERLINE    = 2,

	/** Hollow block cursor. */
	BLOCK_HOLLOW = 3,
	MAX_VALUE    = 2147483647,
}

/**
* Queryable data kinds for ghostty_render_state_get().
*
* @ingroup render
*/
RenderStateData :: enum u32 {
	/** Invalid / sentinel value. */
	INVALID                   = 0,

	/** Viewport width in cells (uint16_t). */
	COLS                      = 1,

	/** Viewport height in cells (uint16_t). */
	ROWS                      = 2,

	/** Current dirty state (GhosttyRenderStateDirty). */
	DIRTY                     = 3,

	/** Populate a pre-allocated GhosttyRenderStateRowIterator with row data
	*  from the render state (GhosttyRenderStateRowIterator). Row data is
	*  only valid as long as the underlying render state is not updated.
	*  It is unsafe to use row data after updating the render state.
	*  */
	ROW_ITERATOR              = 4,

	/** Default/current background color (GhosttyColorRgb). */
	COLOR_BACKGROUND          = 5,

	/** Default/current foreground color (GhosttyColorRgb). */
	COLOR_FOREGROUND          = 6,

	/** Cursor color when explicitly set by terminal state (GhosttyColorRgb).
	*  Returns GHOSTTY_INVALID_VALUE if no explicit cursor color is set;
	*  use COLOR_CURSOR_HAS_VALUE to check first. */
	COLOR_CURSOR              = 7,

	/** Whether an explicit cursor color is set (bool). */
	COLOR_CURSOR_HAS_VALUE    = 8,

	/** The active 256-color palette (GhosttyColorRgb[256]). */
	COLOR_PALETTE             = 9,

	/** The visual style of the cursor (GhosttyRenderStateCursorVisualStyle). */
	CURSOR_VISUAL_STYLE       = 10,

	/** Whether the cursor is visible based on terminal modes (bool). */
	CURSOR_VISIBLE            = 11,

	/** Whether the cursor should blink based on terminal modes (bool). */
	CURSOR_BLINKING           = 12,

	/** Whether the cursor is at a password input field (bool). */
	CURSOR_PASSWORD_INPUT     = 13,

	/** Whether the cursor is visible within the viewport (bool).
	*  If false, the cursor viewport position values are undefined. */
	CURSOR_VIEWPORT_HAS_VALUE = 14,

	/** Cursor viewport x position in cells (uint16_t).
	*  Only valid when CURSOR_VIEWPORT_HAS_VALUE is true. */
	CURSOR_VIEWPORT_X         = 15,

	/** Cursor viewport y position in cells (uint16_t).
	*  Only valid when CURSOR_VIEWPORT_HAS_VALUE is true. */
	CURSOR_VIEWPORT_Y         = 16,

	/** Whether the cursor is on the tail of a wide character (bool).
	*  Only valid when CURSOR_VIEWPORT_HAS_VALUE is true. */
	CURSOR_VIEWPORT_WIDE_TAIL = 17,
	MAX_VALUE                 = 2147483647,
}

/**
* Settable options for ghostty_render_state_set().
*
* @ingroup render
*/
RenderStateOption :: enum u32 {
	/** Set dirty state (GhosttyRenderStateDirty). */
	DIRTY     = 0,
	MAX_VALUE = 2147483647,
}

/**
* Queryable data kinds for ghostty_render_state_row_get().
*
* @ingroup render
*/
RenderStateRowData :: enum u32 {
	/** Invalid / sentinel value. */
	INVALID   = 0,

	/** Whether the current row is dirty (bool). */
	DIRTY     = 1,

	/** The raw row value (GhosttyRow). */
	RAW       = 2,

	/** Populate a pre-allocated GhosttyRenderStateRowCells with cell data for
	*  the current row (GhosttyRenderStateRowCells). Cell data is only
	*  valid as long as the underlying render state is not updated.
	*  It is unsafe to use cell data after updating the render state. */
	CELLS     = 3,
	MAX_VALUE = 2147483647,
}

/**
* Settable options for ghostty_render_state_row_set().
*
* @ingroup render
*/
RenderStateRowOption :: enum u32 {
	/** Set dirty state for the current row (bool). */
	DIRTY     = 0,
	MAX_VALUE = 2147483647,
}

/**
* Render-state color information.
*
* This struct uses the sized-struct ABI pattern. Initialize with
* GHOSTTY_INIT_SIZED(GhosttyRenderStateColors) before calling
* ghostty_render_state_colors_get().
*
* Example:
* @code
* GhosttyRenderStateColors colors = GHOSTTY_INIT_SIZED(GhosttyRenderStateColors);
* GhosttyResult result = ghostty_render_state_colors_get(state, &colors);
* @endcode
*
* @ingroup render
*/
RenderStateColors :: struct {
	/** Size of this struct in bytes. Must be set to sizeof(GhosttyRenderStateColors). */
	size: c.size_t,

	/** The default/current background color for the render state. */
	background: ColorRgb,

	/** The default/current foreground color for the render state. */
	foreground: ColorRgb,

	/** The cursor color when explicitly set by terminal state. */
	cursor: ColorRgb,

	/**
	* True when cursor contains a valid explicit cursor color value.
	* If this is false, the cursor color should be ignored; it will
	* contain undefined data.
	* */
	cursor_has_value: bool,

	/** The active 256-color palette for this render state. */
	palette: [256]ColorRgb,
}

/**
* Queryable data kinds for ghostty_render_state_row_cells_get().
*
* @ingroup render
*/
RenderStateRowCellsData :: enum u32 {
	/** Invalid / sentinel value. */
	INVALID       = 0,

	/** The raw cell value (GhosttyCell). */
	RAW           = 1,

	/** The style for the current cell (GhosttyStyle). */
	STYLE         = 2,

	/** The total number of grapheme codepoints including the base codepoint
	*  (uint32_t). Returns 0 if the cell has no text. */
	GRAPHEMES_LEN = 3,

	/** Write grapheme codepoints into a caller-provided buffer (uint32_t*).
	*  The buffer must be at least graphemes_len elements. The base codepoint
	*  is written first, followed by any extra codepoints. */
	GRAPHEMES_BUF = 4,

	/** The resolved background color of the cell (GhosttyColorRgb).
	*  Flattens the three possible sources: content-tag bg_color_rgb,
	*  content-tag bg_color_palette (looked up in the palette), or the
	*  style's bg_color. Returns GHOSTTY_INVALID_VALUE if the cell has
	*  no background color, in which case the caller should use whatever
	*  default background color it wants (e.g. the terminal background). */
	BG_COLOR      = 5,

	/** The resolved foreground color of the cell (GhosttyColorRgb).
	*  Resolves palette indices through the palette. Bold color handling
	*  is not applied; the caller should handle bold styling separately.
	*  Returns GHOSTTY_INVALID_VALUE if the cell has no explicit foreground
	*  color, in which case the caller should use whatever default foreground
	*  color it wants (e.g. the terminal foreground). */
	FG_COLOR      = 6,
	MAX_VALUE     = 2147483647,
}

@(default_calling_convention="c", link_prefix="ghostty_")
foreign lib {
	/**
	* Create a new render state instance.
	*
	* @param allocator Pointer to allocator, or NULL to use the default allocator
	* @param state Pointer to store the created render state handle
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_OUT_OF_MEMORY on allocation
	* failure
	*
	* @ingroup render
	*/
	render_state_new :: proc(allocator: ^Allocator, state: ^RenderState) -> Result ---

	/**
	* Free a render state instance.
	*
	* Releases all resources associated with the render state. After this call,
	* the render state handle becomes invalid.
	*
	* @param state The render state handle to free (may be NULL)
	*
	* @ingroup render
	*/
	render_state_free :: proc(state: RenderState) ---

	/**
	* Update a render state instance from a terminal.
	*
	* This consumes terminal/screen dirty state in the same way as the internal
	* render state update path.
	*
	* @param state The render state handle (NULL returns GHOSTTY_INVALID_VALUE)
	* @param terminal The terminal handle to read from (NULL returns GHOSTTY_INVALID_VALUE)
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_INVALID_VALUE if `state` or
	* `terminal` is NULL, GHOSTTY_OUT_OF_MEMORY if updating the state requires
	* allocation and that allocation fails
	*
	* @ingroup render
	*/
	render_state_update :: proc(state: RenderState, terminal: Terminal) -> Result ---

	/**
	* Get a value from a render state.
	*
	* The `out` pointer must point to a value of the type corresponding to the
	* requested data kind (see GhosttyRenderStateData).
	*
	* @param state The render state handle (NULL returns GHOSTTY_INVALID_VALUE)
	* @param data The data kind to query
	* @param[out] out Pointer to receive the queried value
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_INVALID_VALUE if `state` is
	*         NULL or `data` is not a recognized enum value
	*
	* @ingroup render
	*/
	render_state_get :: proc(state: RenderState, data: RenderStateData, out: rawptr) -> Result ---

	/**
	* Get multiple data fields from a render state in a single call.
	*
	* Each element in the keys array specifies a data kind, and the
	* corresponding element in the values array receives the result.
	*
	* Processing stops at the first error; on success out_written
	* is set to count, on error it is set to the index of the
	* failing key (i.e. the number of values successfully written).
	*
	* @param state The render state handle (NULL returns GHOSTTY_INVALID_VALUE)
	* @param count Number of key/value pairs
	* @param keys Array of data kinds to query
	* @param values Array of output pointers (types must match each key's
	*               documented output type)
	* @param[out] out_written On return, receives the number of values
	*             successfully written (may be NULL)
	* @return GHOSTTY_SUCCESS if all queries succeed
	*
	* @ingroup render
	*/
	render_state_get_multi :: proc(state: RenderState, count: c.size_t, keys: ^RenderStateData, values: ^rawptr, out_written: ^c.size_t) -> Result ---

	/**
	* Set an option on a render state.
	*
	* The `value` pointer must point to a value of the type corresponding to the
	* requested option kind (see GhosttyRenderStateOption).
	*
	* @param state The render state handle (NULL returns GHOSTTY_INVALID_VALUE)
	* @param option The option to set
	* @param[in] value Pointer to the value to set (NULL returns
	*            GHOSTTY_INVALID_VALUE)
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_INVALID_VALUE if `state` or
	*         `value` is NULL
	*
	* @ingroup render
	*/
	render_state_set :: proc(state: RenderState, option: RenderStateOption, value: rawptr) -> Result ---

	/**
	* Get the current color information from a render state.
	*
	* This writes as many fields as fit in the caller-provided sized struct.
	* `out_colors->size` must be set by the caller (typically via
	* GHOSTTY_INIT_SIZED(GhosttyRenderStateColors)).
	*
	* @param state The render state handle (NULL returns GHOSTTY_INVALID_VALUE)
	* @param[out] out_colors Sized output struct to receive render-state colors
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_INVALID_VALUE if `state` or
	*         `out_colors` is NULL, or if `out_colors->size` is smaller than
	*         `sizeof(size_t)`
	*
	* @ingroup render
	*/
	render_state_colors_get :: proc(state: RenderState, out_colors: ^RenderStateColors) -> Result ---

	/**
	* Create a new row iterator instance.
	*
	* All fields except the allocator are left undefined until populated
	* via ghostty_render_state_get() with
	* GHOSTTY_RENDER_STATE_DATA_ROW_ITERATOR.
	*
	* @param allocator Pointer to allocator, or NULL to use the default allocator
	* @param[out] out_iterator On success, receives the created iterator handle
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_OUT_OF_MEMORY on allocation
	*         failure
	*
	* @ingroup render
	*/
	render_state_row_iterator_new :: proc(allocator: ^Allocator, out_iterator: ^RenderStateRowIterator) -> Result ---

	/**
	* Free a render-state row iterator.
	*
	* @param iterator The iterator handle to free (may be NULL)
	*
	* @ingroup render
	*/
	render_state_row_iterator_free :: proc(iterator: RenderStateRowIterator) ---

	/**
	* Move a render-state row iterator to the next row.
	*
	* Returns true if the iterator moved successfully and row data is
	* available to read at the new position.
	*
	* @param iterator The iterator handle to advance (may be NULL)
	* @return true if advanced to the next row, false if `iterator` is
	*         NULL or if the iterator has reached the end
	*
	* @ingroup render
	*/
	render_state_row_iterator_next :: proc(iterator: RenderStateRowIterator) -> bool ---

	/**
	* Get a value from the current row in a render-state row iterator.
	*
	* The `out` pointer must point to a value of the type corresponding to the
	* requested data kind (see GhosttyRenderStateRowData).
	* Call ghostty_render_state_row_iterator_next() at least once before
	* calling this function.
	*
	* @param iterator The iterator handle to query (NULL returns GHOSTTY_INVALID_VALUE)
	* @param data The data kind to query
	* @param[out] out Pointer to receive the queried value
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_INVALID_VALUE if
	*         `iterator` is NULL or the iterator is not positioned on a row
	*
	* @ingroup render
	*/
	render_state_row_get :: proc(iterator: RenderStateRowIterator, data: RenderStateRowData, out: rawptr) -> Result ---

	/**
	* Get multiple data fields from the current row in a single call.
	*
	* Each element in the keys array specifies a data kind, and the
	* corresponding element in the values array receives the result.
	*
	* Processing stops at the first error; on success out_written
	* is set to count, on error it is set to the index of the
	* failing key (i.e. the number of values successfully written).
	*
	* @param iterator The iterator handle (NULL returns GHOSTTY_INVALID_VALUE)
	* @param count Number of key/value pairs
	* @param keys Array of data kinds to query
	* @param values Array of output pointers (types must match each key's
	*               documented output type)
	* @param[out] out_written On return, receives the number of values
	*             successfully written (may be NULL)
	* @return GHOSTTY_SUCCESS if all queries succeed
	*
	* @ingroup render
	*/
	render_state_row_get_multi :: proc(iterator: RenderStateRowIterator, count: c.size_t, keys: ^RenderStateRowData, values: ^rawptr, out_written: ^c.size_t) -> Result ---

	/**
	* Set an option on the current row in a render-state row iterator.
	*
	* The `value` pointer must point to a value of the type corresponding to the
	* requested option kind (see GhosttyRenderStateRowOption).
	* Call ghostty_render_state_row_iterator_next() at least once before
	* calling this function.
	*
	* @param iterator The iterator handle to update (NULL returns GHOSTTY_INVALID_VALUE)
	* @param option The option to set
	* @param[in] value Pointer to the value to set (NULL returns
	*            GHOSTTY_INVALID_VALUE)
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_INVALID_VALUE if
	*         `iterator` is NULL or the iterator is not positioned on a row
	*
	* @ingroup render
	*/
	render_state_row_set :: proc(iterator: RenderStateRowIterator, option: RenderStateRowOption, value: rawptr) -> Result ---

	/**
	* Create a new row cells instance.
	*
	* All fields except the allocator are left undefined until populated
	* via ghostty_render_state_row_get() with
	* GHOSTTY_RENDER_STATE_ROW_DATA_CELLS.
	*
	* You can reuse this value repeatedly with ghostty_render_state_row_get() to
	* avoid allocating a new cells container for every row.
	*
	* @param allocator Pointer to allocator, or NULL to use the default allocator
	* @param[out] out_cells On success, receives the created row cells handle
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_OUT_OF_MEMORY on allocation
	*         failure
	*
	* @ingroup render
	*/
	render_state_row_cells_new :: proc(allocator: ^Allocator, out_cells: ^RenderStateRowCells) -> Result ---

	/**
	* Move a render-state row cells iterator to the next cell.
	*
	* Returns true if the iterator moved successfully and cell data is
	* available to read at the new position.
	*
	* @param cells The row cells handle to advance (may be NULL)
	* @return true if advanced to the next cell, false if `cells` is
	*         NULL or if the iterator has reached the end
	*
	* @ingroup render
	*/
	render_state_row_cells_next :: proc(cells: RenderStateRowCells) -> bool ---

	/**
	* Move a render-state row cells iterator to a specific column.
	*
	* Positions the iterator at the given x (column) index so that
	* subsequent reads return data for that cell.
	*
	* @param cells The row cells handle to reposition (NULL returns
	*        GHOSTTY_INVALID_VALUE)
	* @param x The zero-based column index to select
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_INVALID_VALUE if `cells`
	*         is NULL or `x` is out of range
	*
	* @ingroup render
	*/
	render_state_row_cells_select :: proc(cells: RenderStateRowCells, x: u16) -> Result ---

	/**
	* Get a value from the current cell in a render-state row cells iterator.
	*
	* The `out` pointer must point to a value of the type corresponding to the
	* requested data kind (see GhosttyRenderStateRowCellsData).
	* Call ghostty_render_state_row_cells_next() or
	* ghostty_render_state_row_cells_select() at least once before
	* calling this function.
	*
	* @param cells The row cells handle to query (NULL returns GHOSTTY_INVALID_VALUE)
	* @param data The data kind to query
	* @param[out] out Pointer to receive the queried value
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_INVALID_VALUE if
	*         `cells` is NULL or the iterator is not positioned on a cell
	*
	* @ingroup render
	*/
	render_state_row_cells_get :: proc(cells: RenderStateRowCells, data: RenderStateRowCellsData, out: rawptr) -> Result ---

	/**
	* Get multiple data fields from the current cell in a single call.
	*
	* Each element in the keys array specifies a data kind, and the
	* corresponding element in the values array receives the result.
	*
	* Processing stops at the first error; on success out_written
	* is set to count, on error it is set to the index of the
	* failing key (i.e. the number of values successfully written).
	*
	* @param cells The row cells handle (NULL returns GHOSTTY_INVALID_VALUE)
	* @param count Number of key/value pairs
	* @param keys Array of data kinds to query
	* @param values Array of output pointers (types must match each key's
	*               documented output type)
	* @param[out] out_written On return, receives the number of values
	*             successfully written (may be NULL)
	* @return GHOSTTY_SUCCESS if all queries succeed
	*
	* @ingroup render
	*/
	render_state_row_cells_get_multi :: proc(cells: RenderStateRowCells, count: c.size_t, keys: ^RenderStateRowCellsData, values: ^rawptr, out_written: ^c.size_t) -> Result ---

	/**
	* Free a row cells instance.
	*
	* @param cells The row cells handle to free (may be NULL)
	*
	* @ingroup render
	*/
	render_state_row_cells_free :: proc(cells: RenderStateRowCells) ---
}

