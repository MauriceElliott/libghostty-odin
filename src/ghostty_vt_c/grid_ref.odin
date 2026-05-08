/**
 * @file grid_ref.h
 *
 * Terminal grid reference type for referencing a resolved position in the
 * terminal grid.
 */
package ghostty_vt_c

import "core:c"

when ODIN_OS == .Linux {
    foreign import lib "../../build/ghostty-install/lib/libghostty-vt.so"
} else when ODIN_OS == .Darwin {
    foreign import lib "../../build/ghostty-install/lib/libghostty-vt.dylib"
} else when ODIN_OS == .Windows {
    foreign import lib "../../build/ghostty-install/lib/ghostty-vt.lib"
}
// Suppress "lib declared but not used" in generated files that only contain types.
_ :: lib


/**
* A resolved reference to a terminal cell position.
*
* This is a sized struct. Use GHOSTTY_INIT_SIZED() to initialize it.
*
* @ingroup grid_ref
*/
GridRef :: struct {
	size: c.size_t,
	node: rawptr,
	x:    u16,
	y:    u16,
}

@(default_calling_convention="c", link_prefix="ghostty_")
foreign lib {
	/**
	* Get the cell from a grid reference.
	*
	* @param ref Pointer to the grid reference
	* @param[out] out_cell On success, set to the cell at the ref's position (may be NULL)
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_INVALID_VALUE if the ref's
	*         node is NULL
	*
	* @ingroup grid_ref
	*/
	grid_ref_cell :: proc(ref: ^GridRef, out_cell: ^Cell) -> Result ---

	/**
	* Get the row from a grid reference.
	*
	* @param ref Pointer to the grid reference
	* @param[out] out_row On success, set to the row at the ref's position (may be NULL)
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_INVALID_VALUE if the ref's
	*         node is NULL
	*
	* @ingroup grid_ref
	*/
	grid_ref_row :: proc(ref: ^GridRef, out_row: ^Row) -> Result ---

	/**
	* Get the grapheme cluster codepoints for the cell at the grid reference's
	* position.
	*
	* Writes the full grapheme cluster (the cell's primary codepoint followed by
	* any combining codepoints) into the provided buffer. If the cell has no text,
	* out_len is set to 0 and GHOSTTY_SUCCESS is returned.
	*
	* If the buffer is too small (or NULL), the function returns
	* GHOSTTY_OUT_OF_SPACE and writes the required number of codepoints to
	* out_len. The caller can then retry with a sufficiently sized buffer.
	*
	* @param ref Pointer to the grid reference
	* @param buf Output buffer of uint32_t codepoints (may be NULL)
	* @param buf_len Number of uint32_t elements in the buffer
	* @param[out] out_len On success, the number of codepoints written. On
	*             GHOSTTY_OUT_OF_SPACE, the required buffer size in codepoints.
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_INVALID_VALUE if the ref's
	*         node is NULL, GHOSTTY_OUT_OF_SPACE if the buffer is too small
	*
	* @ingroup grid_ref
	*/
	grid_ref_graphemes :: proc(ref: ^GridRef, buf: ^u32, buf_len: c.size_t, out_len: ^c.size_t) -> Result ---

	/**
	* Get the hyperlink URI for the cell at the grid reference's position.
	*
	* Writes the URI bytes into the provided buffer. If the cell has no
	* hyperlink, out_len is set to 0 and GHOSTTY_SUCCESS is returned.
	*
	* If the buffer is too small (or NULL), the function returns
	* GHOSTTY_OUT_OF_SPACE and writes the required number of bytes to
	* out_len. The caller can then retry with a sufficiently sized buffer.
	*
	* @param ref Pointer to the grid reference
	* @param buf Output buffer for the URI bytes (may be NULL)
	* @param buf_len Size of the output buffer in bytes
	* @param[out] out_len On success, the number of bytes written. On
	*             GHOSTTY_OUT_OF_SPACE, the required buffer size in bytes.
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_INVALID_VALUE if the ref's
	*         node is NULL, GHOSTTY_OUT_OF_SPACE if the buffer is too small
	*
	* @ingroup grid_ref
	*/
	grid_ref_hyperlink_uri :: proc(ref: ^GridRef, buf: ^u8, buf_len: c.size_t, out_len: ^c.size_t) -> Result ---

	/**
	* Get the style of the cell at the grid reference's position.
	*
	* @param ref Pointer to the grid reference
	* @param[out] out_style On success, set to the cell's style (may be NULL)
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_INVALID_VALUE if the ref's
	*         node is NULL
	*
	* @ingroup grid_ref
	*/
	grid_ref_style :: proc(ref: ^GridRef, out_style: ^Style) -> Result ---
}

