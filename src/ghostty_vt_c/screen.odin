/**
 * @file screen.h
 *
 * Terminal screen cell and row types.
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
* Opaque cell value.
*
* Represents a single terminal cell. The internal layout is opaque and
* must be queried via ghostty_cell_get(). Obtain cell values from
* terminal query APIs.
*
* @ingroup screen
*/
Cell :: u64

/**
* Opaque row value.
*
* Represents a single terminal row. The internal layout is opaque and
* must be queried via ghostty_row_get(). Obtain row values from
* terminal query APIs.
*
* @ingroup screen
*/
Row :: u64

/**
* Cell content tag.
*
* Describes what kind of content a cell holds.
*
* @ingroup screen
*/
CellContentTag :: enum u32 {
	/** A single codepoint (may be zero for empty). */
	CODEPOINT          = 0,

	/** A codepoint that is part of a multi-codepoint grapheme cluster. */
	CODEPOINT_GRAPHEME = 1,

	/** No text; background color from palette. */
	BG_COLOR_PALETTE   = 2,

	/** No text; background color as RGB. */
	BG_COLOR_RGB       = 3,
}

/**
* Cell wide property.
*
* Describes the width behavior of a cell.
*
* @ingroup screen
*/
CellWide :: enum u32 {
	/** Not a wide character, cell width 1. */
	NARROW      = 0,

	/** Wide character, cell width 2. */
	WIDE        = 1,

	/** Spacer after wide character. Do not render. */
	SPACER_TAIL = 2,

	/** Spacer at end of soft-wrapped line for a wide character. */
	SPACER_HEAD = 3,
}

/**
* Semantic content type of a cell.
*
* Set by semantic prompt sequences (OSC 133) to distinguish between
* command output, user input, and shell prompt text.
*
* @ingroup screen
*/
CellSemanticContent :: enum u32 {
	/** Regular output content, such as command output. */
	OUTPUT = 0,

	/** Content that is part of user input. */
	INPUT  = 1,

	/** Content that is part of a shell prompt. */
	PROMPT = 2,
}

/**
* Cell data types.
*
* These values specify what type of data to extract from a cell
* using `ghostty_cell_get`.
*
* @ingroup screen
*/
CellData :: enum u32 {
	/** Invalid data type. Never results in any data extraction. */
	INVALID          = 0,

	/**
	* The codepoint of the cell (0 if empty or bg-color-only).
	*
	* Output type: uint32_t *
	*/
	CODEPOINT        = 1,

	/**
	* The content tag describing what kind of content is in the cell.
	*
	* Output type: GhosttyCellContentTag *
	*/
	CONTENT_TAG      = 2,

	/**
	* The wide property of the cell.
	*
	* Output type: GhosttyCellWide *
	*/
	WIDE             = 3,

	/**
	* Whether the cell has text to render.
	*
	* Output type: bool *
	*/
	HAS_TEXT         = 4,

	/**
	* Whether the cell has non-default styling.
	*
	* Output type: bool *
	*/
	HAS_STYLING      = 5,

	/**
	* The style ID for the cell (for use with style lookups).
	*
	* Output type: uint16_t *
	*/
	STYLE_ID         = 6,

	/**
	* Whether the cell has a hyperlink.
	*
	* Output type: bool *
	*/
	HAS_HYPERLINK    = 7,

	/**
	* Whether the cell is protected.
	*
	* Output type: bool *
	*/
	PROTECTED        = 8,

	/**
	* The semantic content type of the cell (from OSC 133).
	*
	* Output type: GhosttyCellSemanticContent *
	*/
	SEMANTIC_CONTENT = 9,

	/**
	* The palette index for the cell's background color.
	* Only valid when content_tag is GHOSTTY_CELL_CONTENT_BG_COLOR_PALETTE.
	*
	* Output type: GhosttyColorPaletteIndex *
	*/
	COLOR_PALETTE    = 10,

	/**
	* The RGB value for the cell's background color.
	* Only valid when content_tag is GHOSTTY_CELL_CONTENT_BG_COLOR_RGB.
	*
	* Output type: GhosttyColorRgb *
	*/
	COLOR_RGB        = 11,
}

/**
* Row semantic prompt state.
*
* Indicates whether any cells in a row are part of a shell prompt,
* as reported by OSC 133 sequences.
*
* @ingroup screen
*/
RowSemanticPrompt :: enum u32 {
	/** No prompt cells in this row. */
	NONE                = 0,

	/** Prompt cells exist and this is a primary prompt line. */
	PROMPT              = 1,

	/** Prompt cells exist and this is a continuation line. */
	PROMPT_CONTINUATION = 2,
}

/**
* Row data types.
*
* These values specify what type of data to extract from a row
* using `ghostty_row_get`.
*
* @ingroup screen
*/
RowData :: enum u32 {
	/** Invalid data type. Never results in any data extraction. */
	INVALID                   = 0,

	/**
	* Whether this row is soft-wrapped.
	*
	* Output type: bool *
	*/
	WRAP                      = 1,

	/**
	* Whether this row is a continuation of a soft-wrapped row.
	*
	* Output type: bool *
	*/
	WRAP_CONTINUATION         = 2,

	/**
	* Whether any cells in this row have grapheme clusters.
	*
	* Output type: bool *
	*/
	GRAPHEME                  = 3,

	/**
	* Whether any cells in this row have styling (may have false positives).
	*
	* Output type: bool *
	*/
	STYLED                    = 4,

	/**
	* Whether any cells in this row have hyperlinks (may have false positives).
	*
	* Output type: bool *
	*/
	HYPERLINK                 = 5,

	/**
	* The semantic prompt state of this row.
	*
	* Output type: GhosttyRowSemanticPrompt *
	*/
	SEMANTIC_PROMPT           = 6,

	/**
	* Whether this row contains a Kitty virtual placeholder.
	*
	* Output type: bool *
	*/
	KITTY_VIRTUAL_PLACEHOLDER = 7,

	/**
	* Whether this row is dirty and requires a redraw.
	*
	* Output type: bool *
	*/
	DIRTY                     = 8,
}

@(default_calling_convention="c", link_prefix="ghostty_")
foreign lib {
	/**
	* Get data from a cell.
	*
	* Extracts typed data from the given cell based on the specified
	* data type. The output pointer must be of the appropriate type for the
	* requested data kind. Valid data types and output types are documented
	* in the `GhosttyCellData` enum.
	*
	* @param cell The cell value
	* @param data The type of data to extract
	* @param out Pointer to store the extracted data (type depends on data parameter)
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_INVALID_VALUE if the
	*         data type is invalid
	*
	* @ingroup screen
	*/
	cell_get :: proc(cell: Cell, data: CellData, out: rawptr) -> Result ---

	/**
	* Get multiple data fields from a cell in a single call.
	*
	* Each element in the keys array specifies a data kind, and the
	* corresponding element in the values array receives the result.
	*
	* Processing stops at the first error; on success out_written
	* is set to count, on error it is set to the index of the
	* failing key (i.e. the number of values successfully written).
	*
	* @param cell The cell value
	* @param count Number of key/value pairs
	* @param keys Array of data kinds to query
	* @param values Array of output pointers (types must match each key's
	*               documented output type)
	* @param[out] out_written On return, receives the number of values
	*             successfully written (may be NULL)
	* @return GHOSTTY_SUCCESS if all queries succeed
	*
	* @ingroup screen
	*/
	cell_get_multi :: proc(cell: Cell, count: c.size_t, keys: ^CellData, values: ^rawptr, out_written: ^c.size_t) -> Result ---

	/**
	* Get data from a row.
	*
	* Extracts typed data from the given row based on the specified
	* data type. The output pointer must be of the appropriate type for the
	* requested data kind. Valid data types and output types are documented
	* in the `GhosttyRowData` enum.
	*
	* @param row The row value
	* @param data The type of data to extract
	* @param out Pointer to store the extracted data (type depends on data parameter)
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_INVALID_VALUE if the
	*         data type is invalid
	*
	* @ingroup screen
	*/
	row_get :: proc(row: Row, data: RowData, out: rawptr) -> Result ---

	/**
	* Get multiple data fields from a row in a single call.
	*
	* Each element in the keys array specifies a data kind, and the
	* corresponding element in the values array receives the result.
	*
	* Processing stops at the first error; on success out_written
	* is set to count, on error it is set to the index of the
	* failing key (i.e. the number of values successfully written).
	*
	* @param row The row value
	* @param count Number of key/value pairs
	* @param keys Array of data kinds to query
	* @param values Array of output pointers (types must match each key's
	*               documented output type)
	* @param[out] out_written On return, receives the number of values
	*             successfully written (may be NULL)
	* @return GHOSTTY_SUCCESS if all queries succeed
	*
	* @ingroup screen
	*/
	row_get_multi :: proc(row: Row, count: c.size_t, keys: ^RowData, values: ^rawptr, out_written: ^c.size_t) -> Result ---
}

