/**
 * @file terminal.h
 *
 * Complete terminal emulator state and rendering.
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
* Terminal initialization options.
*
* @ingroup terminal
*/
TerminalOptions :: struct #align(8) {
	/** Terminal width in cells. Must be greater than zero. */
	cols: u16,

	/** Terminal height in cells. Must be greater than zero. */
	rows: u16,

	/** Maximum number of lines to keep in scrollback history. */
	max_scrollback: c.size_t,
}

/**
* Scroll viewport behavior tag.
*
* @ingroup terminal
*/
TerminalScrollViewportTag :: enum u32 {
	/** Scroll to the top of the scrollback. */
	TOP    = 0,

	/** Scroll to the bottom (active area). */
	BOTTOM = 1,

	/** Scroll by a delta amount (up is negative). */
	DELTA  = 2,
}

/**
* Scroll viewport value.
*
* @ingroup terminal
*/
TerminalScrollViewportValue :: struct #raw_union {
	/** Scroll delta (only used with GHOSTTY_SCROLL_VIEWPORT_DELTA). Up is negative. */
	delta: c.intptr_t,

	/** Padding for ABI compatibility. Do not use. */
	_padding: [2]u64,
}

/**
* Tagged union for scroll viewport behavior.
*
* @ingroup terminal
*/
TerminalScrollViewport :: struct {
	tag:   TerminalScrollViewportTag,
	value: TerminalScrollViewportValue,
}

/**
* Terminal screen identifier.
*
* Identifies which screen buffer is active in the terminal.
*
* @ingroup terminal
*/
TerminalScreen :: enum u32 {
	/** The primary (normal) screen. */
	PRIMARY   = 0,

	/** The alternate screen. */
	ALTERNATE = 1,
}

/**
* Scrollbar state for the terminal viewport.
*
* Represents the scrollable area dimensions needed to render a scrollbar.
*
* @ingroup terminal
*/
TerminalScrollbar :: struct {
	/** Total size of the scrollable area in rows. */
	total: u64,

	/** Offset into the total area that the viewport is at. */
	offset: u64,

	/** Length of the visible area in rows. */
	len: u64,
}

/**
* Callback function type for bell.
*
* Called when the terminal receives a BEL character (0x07).
*
* @param terminal The terminal handle
* @param userdata The userdata pointer set via GHOSTTY_TERMINAL_OPT_USERDATA
*
* @ingroup terminal
*/
TerminalBellFn :: proc "c" (terminal: Terminal, userdata: rawptr)

/**
* Callback function type for color scheme queries (CSI ? 996 n).
*
* Called when the terminal receives a color scheme device status report
* query. Return true and fill *out_scheme with the current color scheme,
* or return false to silently ignore the query.
*
* @param terminal The terminal handle
* @param userdata The userdata pointer set via GHOSTTY_TERMINAL_OPT_USERDATA
* @param[out] out_scheme Pointer to store the current color scheme
* @return true if the color scheme was filled, false to ignore the query
*
* @ingroup terminal
*/
TerminalColorSchemeFn :: proc "c" (terminal: Terminal, userdata: rawptr, out_scheme: ^ColorScheme) -> bool

/**
* Callback function type for device attributes queries (DA1/DA2/DA3).
*
* Called when the terminal receives a device attributes query (CSI c,
* CSI > c, or CSI = c). Return true and fill *out_attrs with the
* response data, or return false to silently ignore the query.
*
* The terminal uses whichever sub-struct (primary, secondary, tertiary)
* matches the request type, but all three should be filled for simplicity.
*
* @param terminal The terminal handle
* @param userdata The userdata pointer set via GHOSTTY_TERMINAL_OPT_USERDATA
* @param[out] out_attrs Pointer to store the device attributes response
* @return true if attributes were filled, false to ignore the query
*
* @ingroup terminal
*/
TerminalDeviceAttributesFn :: proc "c" (terminal: Terminal, userdata: rawptr, out_attrs: ^DeviceAttributes) -> bool

/**
* Callback function type for enquiry (ENQ, 0x05).
*
* Called when the terminal receives an ENQ character. Return the
* response bytes as a GhosttyString. The memory must remain valid
* until the callback returns. Return a zero-length string to send
* no response.
*
* @param terminal The terminal handle
* @param userdata The userdata pointer set via GHOSTTY_TERMINAL_OPT_USERDATA
* @return The response bytes to write back to the pty
*
* @ingroup terminal
*/
TerminalEnquiryFn :: proc "c" (terminal: Terminal, userdata: rawptr) -> String

/**
* Callback function type for size queries (XTWINOPS).
*
* Called in response to XTWINOPS size queries (CSI 14/16/18 t).
* Return true and fill *out_size with the current terminal geometry,
* or return false to silently ignore the query.
*
* @param terminal The terminal handle
* @param userdata The userdata pointer set via GHOSTTY_TERMINAL_OPT_USERDATA
* @param[out] out_size Pointer to store the terminal size information
* @return true if size was filled, false to ignore the query
*
* @ingroup terminal
*/
TerminalSizeFn :: proc "c" (terminal: Terminal, userdata: rawptr, out_size: ^SizeReportSize) -> bool

/**
* Callback function type for title_changed.
*
* Called when the terminal title changes via escape sequences
* (e.g. OSC 0 or OSC 2). The new title can be queried from the
* terminal after the callback returns.
*
* @param terminal The terminal handle
* @param userdata The userdata pointer set via GHOSTTY_TERMINAL_OPT_USERDATA
*
* @ingroup terminal
*/
TerminalTitleChangedFn :: proc "c" (terminal: Terminal, userdata: rawptr)

/**
* Callback function type for write_pty.
*
* Called when the terminal needs to write data back to the pty, for
* example in response to a device status report or mode query. The
* data is only valid for the duration of the call; callers must copy
* it if it needs to persist.
*
* @param terminal The terminal handle
* @param userdata The userdata pointer set via GHOSTTY_TERMINAL_OPT_USERDATA
* @param data Pointer to the response bytes
* @param len Length of the response in bytes
*
* @ingroup terminal
*/
TerminalWritePtyFn :: proc "c" (terminal: Terminal, userdata: rawptr, data: ^u8, len: c.size_t)

/**
* Callback function type for XTVERSION.
*
* Called when the terminal receives an XTVERSION query (CSI > q).
* Return the version string (e.g. "myterm 1.0") as a GhosttyString.
* The memory must remain valid until the callback returns. Return a
* zero-length string to report the default "libghostty" version.
*
* @param terminal The terminal handle
* @param userdata The userdata pointer set via GHOSTTY_TERMINAL_OPT_USERDATA
* @return The version string to report
*
* @ingroup terminal
*/
TerminalXtversionFn :: proc "c" (terminal: Terminal, userdata: rawptr) -> String

/**
* Terminal option identifiers.
*
* These values are used with ghostty_terminal_set() to configure
* terminal callbacks and associated state.
*
* @ingroup terminal
*/
TerminalOption :: enum u32 {
	/**
	* Opaque userdata pointer passed to all callbacks.
	*
	* Input type: void*
	*/
	USERDATA                      = 0,

	/**
	* Callback invoked when the terminal needs to write data back
	* to the pty (e.g. in response to a DECRQM query or device
	* status report). Set to NULL to ignore such sequences.
	*
	* Input type: GhosttyTerminalWritePtyFn
	*/
	WRITE_PTY                     = 1,

	/**
	* Callback invoked when the terminal receives a BEL character
	* (0x07). Set to NULL to ignore bell events.
	*
	* Input type: GhosttyTerminalBellFn
	*/
	BELL                          = 2,

	/**
	* Callback invoked when the terminal receives an ENQ character
	* (0x05). Set to NULL to send no response.
	*
	* Input type: GhosttyTerminalEnquiryFn
	*/
	ENQUIRY                       = 3,

	/**
	* Callback invoked when the terminal receives an XTVERSION query
	* (CSI > q). Set to NULL to report the default "libghostty" string.
	*
	* Input type: GhosttyTerminalXtversionFn
	*/
	XTVERSION                     = 4,

	/**
	* Callback invoked when the terminal title changes via escape
	* sequences (e.g. OSC 0 or OSC 2). Set to NULL to ignore title
	* change events.
	*
	* Input type: GhosttyTerminalTitleChangedFn
	*/
	TITLE_CHANGED                 = 5,

	/**
	* Callback invoked in response to XTWINOPS size queries
	* (CSI 14/16/18 t). Set to NULL to silently ignore size queries.
	*
	* Input type: GhosttyTerminalSizeFn
	*/
	SIZE                          = 6,

	/**
	* Callback invoked in response to a color scheme device status
	* report query (CSI ? 996 n). Return true and fill the out pointer
	* to report the current scheme, or return false to silently ignore.
	* Set to NULL to ignore color scheme queries.
	*
	* Input type: GhosttyTerminalColorSchemeFn
	*/
	COLOR_SCHEME                  = 7,

	/**
	* Callback invoked in response to a device attributes query
	* (CSI c, CSI > c, or CSI = c). Return true and fill the out
	* pointer with response data, or return false to silently ignore.
	* Set to NULL to ignore device attributes queries.
	*
	* Input type: GhosttyTerminalDeviceAttributesFn
	*/
	DEVICE_ATTRIBUTES             = 8,

	/**
	* Set the terminal title manually.
	*
	* The string data is copied into the terminal. A NULL value pointer
	* clears the title (equivalent to setting an empty string).
	*
	* Input type: GhosttyString*
	*/
	TITLE                         = 9,

	/**
	* Set the terminal working directory manually.
	*
	* The string data is copied into the terminal. A NULL value pointer
	* clears the pwd (equivalent to setting an empty string).
	*
	* Input type: GhosttyString*
	*/
	PWD                           = 10,

	/**
	* Set the default foreground color.
	*
	* A NULL value pointer clears the default (unset).
	*
	* Input type: GhosttyColorRgb*
	*/
	COLOR_FOREGROUND              = 11,

	/**
	* Set the default background color.
	*
	* A NULL value pointer clears the default (unset).
	*
	* Input type: GhosttyColorRgb*
	*/
	COLOR_BACKGROUND              = 12,

	/**
	* Set the default cursor color.
	*
	* A NULL value pointer clears the default (unset).
	*
	* Input type: GhosttyColorRgb*
	*/
	COLOR_CURSOR                  = 13,

	/**
	* Set the default 256-color palette.
	*
	* The value must point to an array of exactly 256 GhosttyColorRgb values.
	* A NULL value pointer resets to the built-in default palette.
	*
	* Input type: GhosttyColorRgb[256]*
	*/
	COLOR_PALETTE                 = 14,

	/**
	* Set the Kitty image storage limit in bytes.
	*
	* Applied to all initialized screens (primary and alternate).
	* A value of zero disables the Kitty graphics protocol entirely,
	* deleting all stored images and placements. A NULL value pointer
	* is equivalent to zero (disables). Has no effect when Kitty graphics
	* are disabled at build time.
	*
	* Input type: uint64_t*
	*/
	KITTY_IMAGE_STORAGE_LIMIT     = 15,

	/**
	* Enable or disable Kitty image loading via the file medium.
	*
	* A NULL value pointer is a no-op. Has no effect when Kitty graphics
	* are disabled at build time.
	*
	* Input type: bool*
	*/
	KITTY_IMAGE_MEDIUM_FILE       = 16,

	/**
	* Enable or disable Kitty image loading via the temporary file medium.
	*
	* A NULL value pointer is a no-op. Has no effect when Kitty graphics
	* are disabled at build time.
	*
	* Input type: bool*
	*/
	KITTY_IMAGE_MEDIUM_TEMP_FILE  = 17,

	/**
	* Enable or disable Kitty image loading via the shared memory medium.
	*
	* A NULL value pointer is a no-op. Has no effect when Kitty graphics
	* are disabled at build time.
	*
	* Input type: bool*
	*/
	KITTY_IMAGE_MEDIUM_SHARED_MEM = 18,

	/**
	* Set the maximum bytes the APC handler will buffer for all protocols.
	* This prevents malicious input from causing unbounded memory allocation.
	* A NULL value pointer removes all overrides, reverting to the built-in
	* defaults.
	*
	* Input type: size_t*
	*/
	APC_MAX_BYTES                 = 19,

	/**
	* Set the maximum bytes the APC handler will buffer for Kitty graphics
	* protocol data. A NULL value pointer removes the override, reverting
	* to the built-in default.
	*
	* Input type: size_t*
	*/
	APC_MAX_BYTES_KITTY           = 20,
}

/**
* Terminal data types.
*
* These values specify what type of data to extract from a terminal
* using `ghostty_terminal_get`.
*
* @ingroup terminal
*/
TerminalData :: enum u32 {
	/** Invalid data type. Never results in any data extraction. */
	INVALID                       = 0,

	/**
	* Terminal width in cells.
	*
	* Output type: uint16_t *
	*/
	COLS                          = 1,

	/**
	* Terminal height in cells.
	*
	* Output type: uint16_t *
	*/
	ROWS                          = 2,

	/**
	* Cursor column position (0-indexed).
	*
	* Output type: uint16_t *
	*/
	CURSOR_X                      = 3,

	/**
	* Cursor row position within the active area (0-indexed).
	*
	* Output type: uint16_t *
	*/
	CURSOR_Y                      = 4,

	/**
	* Whether the cursor has a pending wrap (next print will soft-wrap).
	*
	* Output type: bool *
	*/
	CURSOR_PENDING_WRAP           = 5,

	/**
	* The currently active screen.
	*
	* Output type: GhosttyTerminalScreen *
	*/
	ACTIVE_SCREEN                 = 6,

	/**
	* Whether the cursor is visible (DEC mode 25).
	*
	* Output type: bool *
	*/
	CURSOR_VISIBLE                = 7,

	/**
	* Current Kitty keyboard protocol flags.
	*
	* Output type: GhosttyKittyKeyFlags * (uint8_t *)
	*/
	KITTY_KEYBOARD_FLAGS          = 8,

	/**
	* Scrollbar state for the terminal viewport.
	*
	* This may be expensive to calculate depending on where the viewport
	* is (arbitrary pins are expensive). The caller should take care to only
	* call this as needed and not too frequently.
	*
	* Output type: GhosttyTerminalScrollbar *
	*/
	SCROLLBAR                     = 9,

	/**
	* The current SGR style of the cursor.
	*
	* This is the style that will be applied to newly printed characters.
	*
	* Output type: GhosttyStyle *
	*/
	CURSOR_STYLE                  = 10,

	/**
	* Whether any mouse tracking mode is active.
	*
	* Returns true if any of the mouse tracking modes (X10, normal, button,
	* or any-event) are enabled.
	*
	* Output type: bool *
	*/
	MOUSE_TRACKING                = 11,

	/**
	* The terminal title as set by escape sequences (e.g. OSC 0/2).
	*
	* Returns a borrowed string. The pointer is valid until the next call
	* to ghostty_terminal_vt_write() or ghostty_terminal_reset(). An empty
	* string (len=0) is returned when no title has been set.
	*
	* Output type: GhosttyString *
	*/
	TITLE                         = 12,

	/**
	* The terminal's current working directory as set by escape sequences
	* (e.g. OSC 7).
	*
	* Returns a borrowed string. The pointer is valid until the next call
	* to ghostty_terminal_vt_write() or ghostty_terminal_reset(). An empty
	* string (len=0) is returned when no pwd has been set.
	*
	* Output type: GhosttyString *
	*/
	PWD                           = 13,

	/**
	* The total number of rows in the active screen including scrollback.
	*
	* Output type: size_t *
	*/
	TOTAL_ROWS                    = 14,

	/**
	* The number of scrollback rows (total rows minus viewport rows).
	*
	* Output type: size_t *
	*/
	SCROLLBACK_ROWS               = 15,

	/**
	* The total width of the terminal in pixels.
	*
	* This is cols * cell_width_px as set by ghostty_terminal_resize().
	*
	* Output type: uint32_t *
	*/
	WIDTH_PX                      = 16,

	/**
	* The total height of the terminal in pixels.
	*
	* This is rows * cell_height_px as set by ghostty_terminal_resize().
	*
	* Output type: uint32_t *
	*/
	HEIGHT_PX                     = 17,

	/**
	* The effective foreground color (override or default).
	*
	* Returns GHOSTTY_NO_VALUE if no foreground color is set.
	*
	* Output type: GhosttyColorRgb *
	*/
	COLOR_FOREGROUND              = 18,

	/**
	* The effective background color (override or default).
	*
	* Returns GHOSTTY_NO_VALUE if no background color is set.
	*
	* Output type: GhosttyColorRgb *
	*/
	COLOR_BACKGROUND              = 19,

	/**
	* The effective cursor color (override or default).
	*
	* Returns GHOSTTY_NO_VALUE if no cursor color is set.
	*
	* Output type: GhosttyColorRgb *
	*/
	COLOR_CURSOR                  = 20,

	/**
	* The current 256-color palette.
	*
	* Output type: GhosttyColorRgb[256] *
	*/
	COLOR_PALETTE                 = 21,

	/**
	* The default foreground color (ignoring any OSC override).
	*
	* Returns GHOSTTY_NO_VALUE if no default foreground color is set.
	*
	* Output type: GhosttyColorRgb *
	*/
	COLOR_FOREGROUND_DEFAULT      = 22,

	/**
	* The default background color (ignoring any OSC override).
	*
	* Returns GHOSTTY_NO_VALUE if no default background color is set.
	*
	* Output type: GhosttyColorRgb *
	*/
	COLOR_BACKGROUND_DEFAULT      = 23,

	/**
	* The default cursor color (ignoring any OSC override).
	*
	* Returns GHOSTTY_NO_VALUE if no default cursor color is set.
	*
	* Output type: GhosttyColorRgb *
	*/
	COLOR_CURSOR_DEFAULT          = 24,

	/**
	* The default 256-color palette (ignoring any OSC overrides).
	*
	* Output type: GhosttyColorRgb[256] *
	*/
	COLOR_PALETTE_DEFAULT         = 25,

	/**
	* The Kitty image storage limit in bytes for the active screen.
	*
	* A value of zero means the Kitty graphics protocol is disabled.
	* Returns GHOSTTY_NO_VALUE when Kitty graphics are disabled at build time.
	*
	* Output type: uint64_t *
	*/
	KITTY_IMAGE_STORAGE_LIMIT     = 26,

	/**
	* Whether the file medium is enabled for Kitty image loading on the
	* active screen.
	*
	* Returns GHOSTTY_NO_VALUE when Kitty graphics are disabled at build time.
	*
	* Output type: bool *
	*/
	KITTY_IMAGE_MEDIUM_FILE       = 27,

	/**
	* Whether the temporary file medium is enabled for Kitty image loading
	* on the active screen.
	*
	* Returns GHOSTTY_NO_VALUE when Kitty graphics are disabled at build time.
	*
	* Output type: bool *
	*/
	KITTY_IMAGE_MEDIUM_TEMP_FILE  = 28,

	/**
	* Whether the shared memory medium is enabled for Kitty image loading
	* on the active screen.
	*
	* Returns GHOSTTY_NO_VALUE when Kitty graphics are disabled at build time.
	*
	* Output type: bool *
	*/
	KITTY_IMAGE_MEDIUM_SHARED_MEM = 29,

	/**
	* The Kitty graphics image storage for the active screen.
	*
	* Returns a borrowed pointer to the image storage. The pointer is valid
	* until the next mutating terminal call (e.g. ghostty_terminal_vt_write()
	* or ghostty_terminal_reset()).
	*
	* Returns GHOSTTY_NO_VALUE when Kitty graphics are disabled at build time.
	*
	* Output type: GhosttyKittyGraphics *
	*/
	KITTY_GRAPHICS                = 30,
}

@(default_calling_convention="c", link_prefix="ghostty_")
foreign lib {
	/**
	* Create a new terminal instance.
	*
	* @param allocator Pointer to allocator, or NULL to use the default allocator
	* @param terminal Pointer to store the created terminal handle
	* @param options Terminal initialization options
	* @return GHOSTTY_SUCCESS on success, or an error code on failure
	*
	* @ingroup terminal
	*/
	terminal_new :: proc(allocator: ^Allocator, terminal: ^Terminal, options: TerminalOptions) -> Result ---

	/**
	* Free a terminal instance.
	*
	* Releases all resources associated with the terminal. After this call,
	* the terminal handle becomes invalid and must not be used.
	*
	* @param terminal The terminal handle to free (may be NULL)
	*
	* @ingroup terminal
	*/
	terminal_free :: proc(terminal: Terminal) ---

	/**
	* Perform a full reset of the terminal (RIS).
	*
	* Resets all terminal state back to its initial configuration, including
	* modes, scrollback, scrolling region, and screen contents. The terminal
	* dimensions are preserved.
	*
	* @param terminal The terminal handle (may be NULL, in which case this is a no-op)
	*
	* @ingroup terminal
	*/
	terminal_reset :: proc(terminal: Terminal) ---

	/**
	* Resize the terminal to the given dimensions.
	*
	* Changes the number of columns and rows in the terminal. The primary
	* screen will reflow content if wraparound mode is enabled; the alternate
	* screen does not reflow. If the dimensions are unchanged, this is a no-op.
	*
	* This also updates the terminal's pixel dimensions (used for image
	* protocols and size reports), disables synchronized output mode (allowed
	* by the spec so that resize results are shown immediately), and sends an
	* in-band size report if mode 2048 is enabled.
	*
	* @param terminal The terminal handle (NULL returns GHOSTTY_INVALID_VALUE)
	* @param cols New width in cells (must be greater than zero)
	* @param rows New height in cells (must be greater than zero)
	* @param cell_width_px Width of a single cell in pixels
	* @param cell_height_px Height of a single cell in pixels
	* @return GHOSTTY_SUCCESS on success, or an error code on failure
	*
	* @ingroup terminal
	*/
	terminal_resize :: proc(terminal: Terminal, cols: u16, rows: u16, cell_width_px: u32, cell_height_px: u32) -> Result ---

	/**
	* Set an option on the terminal.
	*
	* Configures terminal callbacks and associated state such as the
	* write_pty callback and userdata pointer. The value is passed
	* directly for pointer types (callbacks, userdata) or as a pointer
	* to the value for non-pointer types (e.g. GhosttyString*).
	* NULL clears the option to its default.
	*
	* Callbacks are invoked synchronously during ghostty_terminal_vt_write().
	* Callbacks must not call ghostty_terminal_vt_write() on the same
	* terminal (no reentrancy).
	*
	* @param terminal The terminal handle (may be NULL, in which case this is a no-op)
	* @param option The option to set
	* @param value Pointer to the value to set (type depends on the option),
	*              or NULL to clear the option
	*
	* @ingroup terminal
	*/
	terminal_set :: proc(terminal: Terminal, option: TerminalOption, value: rawptr) -> Result ---

	/**
	* Write VT-encoded data to the terminal for processing.
	*
	* Feeds raw bytes through the terminal's VT stream parser, updating
	* terminal state accordingly. By default, sequences that require output
	* (queries, device status reports) are silently ignored. Use
	* ghostty_terminal_set() with GHOSTTY_TERMINAL_OPT_WRITE_PTY to install
	* a callback that receives response data.
	*
	* This never fails. Any erroneous input or errors in processing the
	* input are logged internally but do not cause this function to fail
	* because this input is assumed to be untrusted and from an external
	* source; so the primary goal is to keep the terminal state consistent and
	* not allow malformed input to corrupt or crash.
	*
	* @param terminal The terminal handle
	* @param data Pointer to the data to write
	* @param len Length of the data in bytes
	*
	* @ingroup terminal
	*/
	terminal_vt_write :: proc(terminal: Terminal, data: ^u8, len: c.size_t) ---

	/**
	* Scroll the terminal viewport.
	*
	* Scrolls the terminal's viewport according to the given behavior.
	* When using GHOSTTY_SCROLL_VIEWPORT_DELTA, set the delta field in
	* the value union to specify the number of rows to scroll (negative
	* for up, positive for down). For other behaviors, the value is ignored.
	*
	* @param terminal The terminal handle (may be NULL, in which case this is a no-op)
	* @param behavior The scroll behavior as a tagged union
	*
	* @ingroup terminal
	*/
	terminal_scroll_viewport :: proc(terminal: Terminal, behavior: TerminalScrollViewport) ---

	/**
	* Get the current value of a terminal mode.
	*
	* Returns the value of the mode identified by the given mode.
	*
	* @param terminal The terminal handle (NULL returns GHOSTTY_INVALID_VALUE)
	* @param mode The mode identifying the mode to query
	* @param[out] out_value On success, set to true if the mode is set, false
	*             if it is reset
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_INVALID_VALUE if the terminal
	*         is NULL or the mode does not correspond to a known mode
	*
	* @ingroup terminal
	*/
	terminal_mode_get :: proc(terminal: Terminal, mode: Mode, out_value: ^bool) -> Result ---

	/**
	* Set the value of a terminal mode.
	*
	* Sets the mode identified by the given mode to the specified value.
	*
	* @param terminal The terminal handle (NULL returns GHOSTTY_INVALID_VALUE)
	* @param mode The mode identifying the mode to set
	* @param value true to set the mode, false to reset it
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_INVALID_VALUE if the terminal
	*         is NULL or the mode does not correspond to a known mode
	*
	* @ingroup terminal
	*/
	terminal_mode_set :: proc(terminal: Terminal, mode: Mode, value: bool) -> Result ---

	/**
	* Get data from a terminal instance.
	*
	* Extracts typed data from the given terminal based on the specified
	* data type. The output pointer must be of the appropriate type for the
	* requested data kind. Valid data types and output types are documented
	* in the `GhosttyTerminalData` enum.
	*
	* @param terminal The terminal handle (may be NULL)
	* @param data The type of data to extract
	* @param out Pointer to store the extracted data (type depends on data parameter)
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_INVALID_VALUE if the terminal
	*         is NULL or the data type is invalid
	*
	* @ingroup terminal
	*/
	terminal_get :: proc(terminal: Terminal, data: TerminalData, out: rawptr) -> Result ---

	/**
	* Get multiple data fields from a terminal in a single call.
	*
	* This is an optimization over calling ghostty_terminal_get()
	* repeatedly, particularly useful in environments with high per-call
	* overhead such as FFI or Cgo.
	*
	* Each element in the keys array specifies a data kind, and the
	* corresponding element in the values array receives the result.
	* The type of each values[i] pointer must match the output type
	* documented for keys[i].
	*
	* Processing stops at the first error; on success out_written
	* is set to count, on error it is set to the index of the
	* failing key (i.e. the number of values successfully written).
	*
	* @param terminal The terminal handle (may be NULL)
	* @param count Number of key/value pairs
	* @param keys Array of data kinds to query
	* @param values Array of output pointers (types must match each key's
	*               documented output type)
	* @param[out] out_written On return, receives the number of values
	*             successfully written (may be NULL)
	* @return GHOSTTY_SUCCESS if all queries succeed
	*
	* @ingroup terminal
	*/
	terminal_get_multi :: proc(terminal: Terminal, count: c.size_t, keys: ^TerminalData, values: ^rawptr, out_written: ^c.size_t) -> Result ---

	/**
	* Resolve a point in the terminal grid to a grid reference.
	*
	* Resolves the given point (which can be in active, viewport, screen,
	* or history coordinates) to a grid reference for that location. Use
	* ghostty_grid_ref_cell() and ghostty_grid_ref_row() to extract the cell
	* and row.
	*
	* Lookups using the `active` and `viewport` tags are fast. The `screen`
	* and `history` tags may require traversing the full scrollback page list
	* to resolve the y coordinate, so they can be expensive for large
	* scrollback buffers.
	*
	* This function isn't meant to be used as the core of render loop. It
	* isn't built to sustain the framerates needed for rendering large screens.
	* Use the render state API for that. This API is instead meant for less
	* strictly performance-sensitive use cases.
	*
	* @param terminal The terminal handle (NULL returns GHOSTTY_INVALID_VALUE)
	* @param point The point specifying which cell to look up
	* @param[out] out_ref On success, set to the grid reference at the given point (may be NULL)
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_INVALID_VALUE if the terminal
	*         is NULL or the point is out of bounds
	*
	* @ingroup terminal
	*/
	terminal_grid_ref :: proc(terminal: Terminal, point: Point, out_ref: ^GridRef) -> Result ---

	/**
	* Convert a grid reference back to a point in the given coordinate system.
	*
	* This is the inverse of ghostty_terminal_grid_ref(): given a grid reference,
	* it returns the x/y coordinates in the requested coordinate system (active,
	* viewport, screen, or history).
	*
	* The grid reference must have been obtained from the same terminal instance.
	* Like all grid references, it is only valid until the next mutating terminal
	* call.
	*
	* Not every grid reference is representable in every coordinate system. For
	* example, a cell in scrollback history cannot be expressed in active
	* coordinates, and a cell that has scrolled off the visible area cannot be
	* expressed in viewport coordinates. In these cases, the function returns
	* GHOSTTY_NO_VALUE.
	*
	* @param terminal The terminal handle (NULL returns GHOSTTY_INVALID_VALUE)
	* @param ref Pointer to the grid reference to convert
	* @param tag The target coordinate system
	* @param[out] out On success, set to the coordinate in the requested system (may be NULL)
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_INVALID_VALUE if the terminal
	*         or ref is NULL/invalid, GHOSTTY_NO_VALUE if the ref falls outside
	*         the requested coordinate system
	*
	* @ingroup terminal
	*/
	terminal_point_from_grid_ref :: proc(terminal: Terminal, ref: ^GridRef, tag: PointTag, out: ^PointCoordinate) -> Result ---
}

