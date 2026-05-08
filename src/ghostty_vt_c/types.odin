/**
 * @file types.h
 *
 * Common types, macros, and utilities for libghostty-vt.
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
* Result codes for libghostty-vt operations.
*/
Result :: enum i32 {
	/** Operation completed successfully */
	SUCCESS       = 0,

	/** Operation failed due to failed allocation */
	OUT_OF_MEMORY = -1,

	/** Operation failed due to invalid value */
	INVALID_VALUE = -2,

	/** Operation failed because the provided buffer was too small */
	OUT_OF_SPACE  = -3,

	/** The requested value has no value */
	NO_VALUE      = -4,
}

TerminalImpl :: struct {}

/**
* Opaque handle to a terminal instance.
*
* @ingroup terminal
*/
Terminal          :: ^TerminalImpl
KittyGraphicsImpl :: struct {}

/**
* Opaque handle to a Kitty graphics image storage.
*
* Obtained via ghostty_terminal_get() with
* GHOSTTY_TERMINAL_DATA_KITTY_GRAPHICS. The pointer is borrowed from
* the terminal and remains valid until the next mutating terminal call
* (e.g. ghostty_terminal_vt_write() or ghostty_terminal_reset()).
*
* @ingroup kitty_graphics
*/
KittyGraphics          :: ^KittyGraphicsImpl
KittyGraphicsImageImpl :: struct {}

/**
* Opaque handle to a Kitty graphics image.
*
* Obtained via ghostty_kitty_graphics_image() with an image ID. The
* pointer is borrowed from the storage and remains valid until the next
* mutating terminal call.
*
* @ingroup kitty_graphics
*/
KittyGraphicsImage                 :: ^KittyGraphicsImageImpl
KittyGraphicsPlacementIteratorImpl :: struct {}

/**
* Opaque handle to a Kitty graphics placement iterator.
*
* @ingroup kitty_graphics
*/
KittyGraphicsPlacementIterator :: ^KittyGraphicsPlacementIteratorImpl
RenderStateImpl                :: struct {}

/**
* Opaque handle to a render state instance.
*
* @ingroup render
*/
RenderState                :: ^RenderStateImpl
RenderStateRowIteratorImpl :: struct {}

/**
* Opaque handle to a render-state row iterator.
*
* @ingroup render
*/
RenderStateRowIterator  :: ^RenderStateRowIteratorImpl
RenderStateRowCellsImpl :: struct {}

/**
* Opaque handle to render-state row cells.
*
* @ingroup render
*/
RenderStateRowCells :: ^RenderStateRowCellsImpl
SgrParserImpl       :: struct {}

/**
* Opaque handle to an SGR parser instance.
*
* This handle represents an SGR (Select Graphic Rendition) parser that can
* be used to parse SGR sequences and extract individual text attributes.
*
* @ingroup sgr
*/
SgrParser     :: ^SgrParserImpl
FormatterImpl :: struct {}

/**
* Opaque handle to a formatter instance.
*
* @ingroup formatter
*/
Formatter     :: ^FormatterImpl
OscParserImpl :: struct {}

/**
* Opaque handle to an OSC parser instance.
*
* This handle represents an OSC (Operating System Command) parser that can
* be used to parse the contents of OSC sequences.
*
* @ingroup osc
*/
OscParser      :: ^OscParserImpl
OscCommandImpl :: struct {}

/**
* Opaque handle to a single OSC command.
*
* This handle represents a parsed OSC (Operating System Command) command.
* The command can be queried for its type and associated data.
*
* @ingroup osc
*/
OscCommand :: ^OscCommandImpl

/**
* A borrowed byte string (pointer + length).
*
* The memory is not owned by this struct. The pointer is only valid
* for the lifetime documented by the API that produces or consumes it.
*/
String :: struct {
	/** Pointer to the string bytes. */
	ptr: ^u8,

	/** Length of the string in bytes. */
	len: c.size_t,
}

@(default_calling_convention="c", link_prefix="ghostty_")
foreign lib {
	/**
	* Return a pointer to a null-terminated JSON string describing the
	* layout of every C API struct for the current target.
	*
	* This is primarily useful for language bindings that can't easily
	* set C struct fields and need to do so via byte offsets. For example,
	* WebAssembly modules can't share struct definitions with the host.
	*
	* Example (abbreviated):
	* @code{.json}
	* {
	*   "GhosttyMouseEncoderSize": {
	*     "size": 40,
	*     "align": 8,
	*     "fields": {
	*       "size":           { "offset": 0,  "size": 8, "type": "u64" },
	*       "screen_width":   { "offset": 8,  "size": 4, "type": "u32" },
	*       "screen_height":  { "offset": 12, "size": 4, "type": "u32" },
	*       "cell_width":     { "offset": 16, "size": 4, "type": "u32" },
	*       "cell_height":    { "offset": 20, "size": 4, "type": "u32" },
	*       "padding_top":    { "offset": 24, "size": 4, "type": "u32" },
	*       "padding_bottom": { "offset": 28, "size": 4, "type": "u32" },
	*       "padding_right":  { "offset": 32, "size": 4, "type": "u32" },
	*       "padding_left":   { "offset": 36, "size": 4, "type": "u32" }
	*     }
	*   }
	* }
	* @endcode
	*
	* The returned pointer is valid for the lifetime of the process.
	*
	* @return Pointer to the null-terminated JSON string.
	*/
	type_json :: proc() -> cstring ---
}

