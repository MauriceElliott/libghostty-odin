/**
 * @file style.h
 *
 * Terminal cell style types.
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
* Style identifier type.
*
* Used to look up the full style from a grid reference.
* Obtain this from a cell via GHOSTTY_CELL_DATA_STYLE_ID.
*
* @ingroup style
*/
StyleId :: u16

/**
* Style color tags.
*
* These values identify the type of color in a style color.
* Use the tag to determine which field in the color value union to access.
*
* @ingroup style
*/
StyleColorTag :: enum u32 {
	NONE    = 0,
	PALETTE = 1,
	RGB     = 2,
}

/**
* Style color value union.
*
* Use the tag to determine which field is active.
*
* @ingroup style
*/
StyleColorValue :: struct #raw_union {
	palette:  ColorPaletteIndex,
	rgb:      ColorRgb,
	_padding: u64,
}

/**
* Style color (tagged union).
*
* A color used in a style attribute. Can be unset (none), a palette
* index, or a direct RGB value.
*
* @ingroup style
*/
StyleColor :: struct {
	tag:   StyleColorTag,
	value: StyleColorValue,
}

/**
* Terminal cell style.
*
* Describes the complete visual style for a terminal cell, including
* foreground, background, and underline colors, as well as text
* decoration flags. The underline field uses the same values as
* GhosttySgrUnderline.
*
* This is a sized struct. Use GHOSTTY_INIT_SIZED() to initialize it.
*
* @ingroup style
*/
Style :: struct {
	size:            c.size_t,
	fg_color:        StyleColor,
	bg_color:        StyleColor,
	underline_color: StyleColor,
	bold:            bool,
	italic:          bool,
	faint:           bool,
	blink:           bool,
	inverse:         bool,
	invisible:       bool,
	strikethrough:   bool,
	overline:        bool,
	underline:       i32, /**< One of GHOSTTY_SGR_UNDERLINE_* values */
}

@(default_calling_convention="c", link_prefix="ghostty_")
foreign lib {
	/**
	* Get the default style.
	*
	* Initializes the style to the default values (no colors, no flags).
	*
	* @param style Pointer to the style to initialize
	*
	* @ingroup style
	*/
	style_default :: proc(style: ^Style) ---

	/**
	* Check if a style is the default style.
	*
	* Returns true if all colors are unset and all flags are off.
	*
	* @param style Pointer to the style to check
	* @return true if the style is the default style
	*
	* @ingroup style
	*/
	style_is_default :: proc(style: ^Style) -> bool ---
}

