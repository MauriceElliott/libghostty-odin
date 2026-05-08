/**
 * @file sgr.h
 *
 * SGR (Select Graphic Rendition) attribute parsing and handling.
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
* SGR attribute tags.
*
* These values identify the type of an SGR attribute in a tagged union.
* Use the tag to determine which field in the attribute value union to access.
*
* @ingroup sgr
*/
SgrAttributeTag :: enum u32 {
	UNSET                 = 0,
	UNKNOWN               = 1,
	BOLD                  = 2,
	RESET_BOLD            = 3,
	ITALIC                = 4,
	RESET_ITALIC          = 5,
	FAINT                 = 6,
	UNDERLINE             = 7,
	UNDERLINE_COLOR       = 8,
	UNDERLINE_COLOR_256   = 9,
	RESET_UNDERLINE_COLOR = 10,
	OVERLINE              = 11,
	RESET_OVERLINE        = 12,
	BLINK                 = 13,
	RESET_BLINK           = 14,
	INVERSE               = 15,
	RESET_INVERSE         = 16,
	INVISIBLE             = 17,
	RESET_INVISIBLE       = 18,
	STRIKETHROUGH         = 19,
	RESET_STRIKETHROUGH   = 20,
	DIRECT_COLOR_FG       = 21,
	DIRECT_COLOR_BG       = 22,
	BG_8                  = 23,
	FG_8                  = 24,
	RESET_FG              = 25,
	RESET_BG              = 26,
	BRIGHT_BG_8           = 27,
	BRIGHT_FG_8           = 28,
	BG_256                = 29,
	FG_256                = 30,
}

/**
* Underline style types.
*
* @ingroup sgr
*/
SgrUnderline :: enum u32 {
	NONE   = 0,
	SINGLE = 1,
	DOUBLE = 2,
	CURLY  = 3,
	DOTTED = 4,
	DASHED = 5,
}

/**
* Unknown SGR attribute data.
*
* Contains the full parameter list and the partial list where parsing
* encountered an unknown or invalid sequence.
*
* @ingroup sgr
*/
SgrUnknown :: struct {
	full_ptr:    ^u16,
	full_len:    c.size_t,
	partial_ptr: ^u16,
	partial_len: c.size_t,
}

/**
* SGR attribute value union.
*
* This union contains all possible attribute values. Use the tag field
* to determine which union member is active. Attributes without associated
* data (like bold, italic) don't use the union value.
*
* @ingroup sgr
*/
SgrAttributeValue :: struct #raw_union {
	unknown:             SgrUnknown,
	underline:           SgrUnderline,
	underline_color:     ColorRgb,
	underline_color_256: ColorPaletteIndex,
	direct_color_fg:     ColorRgb,
	direct_color_bg:     ColorRgb,
	bg_8:                ColorPaletteIndex,
	fg_8:                ColorPaletteIndex,
	bright_bg_8:         ColorPaletteIndex,
	bright_fg_8:         ColorPaletteIndex,
	bg_256:              ColorPaletteIndex,
	fg_256:              ColorPaletteIndex,
	_padding:            [8]u64,
}

/**
* SGR attribute (tagged union).
*
* A complete SGR attribute with both its type tag and associated value.
* Always check the tag field to determine which value union member is valid.
*
* Attributes without associated data (e.g., GHOSTTY_SGR_ATTR_BOLD) can be
* identified by tag alone; the value union is not used for these and
* the memory in the value field is undefined.
*
* @ingroup sgr
*/
SgrAttribute :: struct {
	tag:   SgrAttributeTag,
	value: SgrAttributeValue,
}

@(default_calling_convention="c", link_prefix="ghostty_")
foreign lib {
	/**
	* Create a new SGR parser instance.
	*
	* Creates a new SGR (Select Graphic Rendition) parser using the provided
	* allocator. The parser must be freed using ghostty_sgr_free() when
	* no longer needed.
	*
	* @param allocator Pointer to the allocator to use for memory management, or
	* NULL to use the default allocator
	* @param parser Pointer to store the created parser handle
	* @return GHOSTTY_SUCCESS on success, or an error code on failure
	*
	* @ingroup sgr
	*/
	sgr_new :: proc(allocator: ^Allocator, parser: ^SgrParser) -> Result ---

	/**
	* Free an SGR parser instance.
	*
	* Releases all resources associated with the SGR parser. After this call,
	* the parser handle becomes invalid and must not be used. This includes
	* any attributes previously returned by ghostty_sgr_next().
	*
	* @param parser The parser handle to free (may be NULL)
	*
	* @ingroup sgr
	*/
	sgr_free :: proc(parser: SgrParser) ---

	/**
	* Reset an SGR parser instance to the beginning of the parameter list.
	*
	* Resets the parser's iteration state without clearing the parameters.
	* After calling this, ghostty_sgr_next() will start from the beginning
	* of the parameter list again.
	*
	* @param parser The parser handle to reset, must not be NULL
	*
	* @ingroup sgr
	*/
	sgr_reset :: proc(parser: SgrParser) ---

	/**
	* Set SGR parameters for parsing.
	*
	* Sets the SGR parameter list to parse. Parameters are the numeric values
	* from a CSI SGR sequence (e.g., for `ESC[1;31m`, params would be {1, 31}).
	*
	* The separators array optionally specifies the separator type for each
	* parameter position. Each byte should be either ';' for semicolon or ':'
	* for colon. This is needed for certain color formats that use colon
	* separators (e.g., `ESC[4:3m` for curly underline). Any invalid separator
	* values are treated as semicolons. The separators array must have the same
	* length as the params array, if it is not NULL.
	*
	* If separators is NULL, all parameters are assumed to be semicolon-separated.
	*
	* This function makes an internal copy of the parameter and separator data,
	* so the caller can safely free or modify the input arrays after this call.
	*
	* After calling this function, the parser is automatically reset and ready
	* to iterate from the beginning.
	*
	* @param parser The parser handle, must not be NULL
	* @param params Array of SGR parameter values
	* @param separators Optional array of separator characters (';' or ':'), or
	* NULL
	* @param len Number of parameters (and separators if provided)
	* @return GHOSTTY_SUCCESS on success, or an error code on failure
	*
	* @ingroup sgr
	*/
	sgr_set_params :: proc(parser: SgrParser, params: ^u16, separators: cstring, len: c.size_t) -> Result ---

	/**
	* Get the next SGR attribute.
	*
	* Parses and returns the next attribute from the parameter list.
	* Call this function repeatedly until it returns false to process
	* all attributes in the sequence.
	*
	* @param parser The parser handle, must not be NULL
	* @param attr Pointer to store the next attribute
	* @return true if an attribute was returned, false if no more attributes
	*
	* @ingroup sgr
	*/
	sgr_next :: proc(parser: SgrParser, attr: ^SgrAttribute) -> bool ---

	/**
	* Get the full parameter list from an unknown SGR attribute.
	*
	* This function retrieves the full parameter list that was provided to the
	* parser when an unknown attribute was encountered. Primarily useful in
	* WebAssembly environments where accessing struct fields directly is difficult.
	*
	* @param unknown The unknown attribute data
	* @param ptr Pointer to store the pointer to the parameter array (may be NULL)
	* @return The length of the full parameter array
	*
	* @ingroup sgr
	*/
	sgr_unknown_full :: proc(unknown: SgrUnknown, ptr: ^^u16) -> c.size_t ---

	/**
	* Get the partial parameter list from an unknown SGR attribute.
	*
	* This function retrieves the partial parameter list where parsing stopped
	* when an unknown attribute was encountered. Primarily useful in WebAssembly
	* environments where accessing struct fields directly is difficult.
	*
	* @param unknown The unknown attribute data
	* @param ptr Pointer to store the pointer to the parameter array (may be NULL)
	* @return The length of the partial parameter array
	*
	* @ingroup sgr
	*/
	sgr_unknown_partial :: proc(unknown: SgrUnknown, ptr: ^^u16) -> c.size_t ---

	/**
	* Get the tag from an SGR attribute.
	*
	* This function extracts the tag that identifies which type of attribute
	* this is. Primarily useful in WebAssembly environments where accessing
	* struct fields directly is difficult.
	*
	* @param attr The SGR attribute
	* @return The attribute tag
	*
	* @ingroup sgr
	*/
	sgr_attribute_tag :: proc(attr: SgrAttribute) -> SgrAttributeTag ---

	/**
	* Get the value from an SGR attribute.
	*
	* This function returns a pointer to the value union from an SGR attribute. Use
	* the tag to determine which field of the union is valid. Primarily useful in
	* WebAssembly environments where accessing struct fields directly is difficult.
	*
	* @param attr Pointer to the SGR attribute
	* @return Pointer to the attribute value union
	*
	* @ingroup sgr
	*/
	sgr_attribute_value :: proc(attr: ^SgrAttribute) -> ^SgrAttributeValue ---
}

