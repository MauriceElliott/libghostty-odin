/**
 * @file color.h
 *
 * Color types and utilities.
 */
package ghostty_vt_c

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
* RGB color value.
*
* @ingroup sgr
*/
ColorRgb :: struct {
	r: u8, /**< Red component (0-255) */
	g: u8, /**< Green component (0-255) */
	b: u8, /**< Blue component (0-255) */
}

/**
* Palette color index (0-255).
*
* @ingroup sgr
*/
ColorPaletteIndex :: u8

/** @addtogroup sgr
* @{
*/

/** Black color (0) @ingroup sgr */
GHOSTTY_COLOR_NAMED_BLACK :: 0

/** Red color (1) @ingroup sgr */
GHOSTTY_COLOR_NAMED_RED :: 1

/** Green color (2) @ingroup sgr */
GHOSTTY_COLOR_NAMED_GREEN :: 2

/** Yellow color (3) @ingroup sgr */
GHOSTTY_COLOR_NAMED_YELLOW :: 3

/** Blue color (4) @ingroup sgr */
GHOSTTY_COLOR_NAMED_BLUE :: 4

/** Magenta color (5) @ingroup sgr */
GHOSTTY_COLOR_NAMED_MAGENTA :: 5

/** Cyan color (6) @ingroup sgr */
GHOSTTY_COLOR_NAMED_CYAN :: 6

/** White color (7) @ingroup sgr */
GHOSTTY_COLOR_NAMED_WHITE :: 7

/** Bright black color (8) @ingroup sgr */
GHOSTTY_COLOR_NAMED_BRIGHT_BLACK :: 8

/** Bright red color (9) @ingroup sgr */
GHOSTTY_COLOR_NAMED_BRIGHT_RED :: 9

/** Bright green color (10) @ingroup sgr */
GHOSTTY_COLOR_NAMED_BRIGHT_GREEN :: 10

/** Bright yellow color (11) @ingroup sgr */
GHOSTTY_COLOR_NAMED_BRIGHT_YELLOW :: 11

/** Bright blue color (12) @ingroup sgr */
GHOSTTY_COLOR_NAMED_BRIGHT_BLUE :: 12

/** Bright magenta color (13) @ingroup sgr */
GHOSTTY_COLOR_NAMED_BRIGHT_MAGENTA :: 13

/** Bright cyan color (14) @ingroup sgr */
GHOSTTY_COLOR_NAMED_BRIGHT_CYAN :: 14

/** Bright white color (15) @ingroup sgr */
GHOSTTY_COLOR_NAMED_BRIGHT_WHITE :: 15

@(default_calling_convention="c", link_prefix="ghostty_")
foreign lib {
	/**
	* Get the RGB color components.
	*
	* This function extracts the individual red, green, and blue components
	* from a GhosttyColorRgb value. Primarily useful in WebAssembly environments
	* where accessing struct fields directly is difficult.
	*
	* @param color The RGB color value
	* @param r Pointer to store the red component (0-255)
	* @param g Pointer to store the green component (0-255)
	* @param b Pointer to store the blue component (0-255)
	*
	* @ingroup sgr
	*/
	color_rgb_get :: proc(color: ColorRgb, r: ^u8, g: ^u8, b: ^u8) ---
}

