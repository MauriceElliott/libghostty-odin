/**
 * @file formatter.h
 *
 * Format terminal content as plain text, VT sequences, or HTML.
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
* Output format.
*
* @ingroup formatter
*/
FormatterFormat :: enum u32 {
	/** Plain text (no escape sequences). */
	PLAIN     = 0,

	/** VT sequences preserving colors, styles, URLs, etc. */
	VT        = 1,

	/** HTML with inline styles. */
	HTML      = 2,
	MAX_VALUE = 2147483647,
}

/**
* Extra screen state to include in styled output.
*
* @ingroup formatter
*/
FormatterScreenExtra :: struct {
	/** Size of this struct in bytes. Must be set to sizeof(GhosttyFormatterScreenExtra). */
	size: c.size_t,

	/** Emit cursor position using CUP (CSI H). */
	cursor: bool,

	/** Emit current SGR style state based on the cursor's active style_id. */
	style: bool,

	/** Emit current hyperlink state using OSC 8 sequences. */
	hyperlink: bool,

	/** Emit character protection mode using DECSCA. */
	protection: bool,

	/** Emit Kitty keyboard protocol state using CSI > u and CSI = sequences. */
	kitty_keyboard: bool,

	/** Emit character set designations and invocations. */
	charsets: bool,
}

/**
* Extra terminal state to include in styled output.
*
* @ingroup formatter
*/
FormatterTerminalExtra :: struct {
	/** Size of this struct in bytes. Must be set to sizeof(GhosttyFormatterTerminalExtra). */
	size: c.size_t,

	/** Emit the palette using OSC 4 sequences. */
	palette: bool,

	/** Emit terminal modes that differ from their defaults using CSI h/l. */
	modes: bool,

	/** Emit scrolling region state using DECSTBM and DECSLRM sequences. */
	scrolling_region: bool,

	/** Emit tabstop positions by clearing all tabs and setting each one. */
	tabstops: bool,

	/** Emit the present working directory using OSC 7. */
	pwd: bool,

	/** Emit keyboard modes such as ModifyOtherKeys. */
	keyboard: bool,

	/** Screen-level extras. */
	screen: FormatterScreenExtra,
}

/**
* Options for creating a terminal formatter.
*
* @ingroup formatter
*/
FormatterTerminalOptions :: struct {
	/** Size of this struct in bytes. Must be set to sizeof(GhosttyFormatterTerminalOptions). */
	size: c.size_t,

	/** Output format to emit. */
	emit: FormatterFormat,

	/** Whether to unwrap soft-wrapped lines. */
	unwrap: bool,

	/** Whether to trim trailing whitespace on non-blank lines. */
	trim: bool,

	/** Extra terminal state to include in styled output. */
	extra: FormatterTerminalExtra,

	/** Optional selection to restrict output to a range.
	*  If NULL, the entire screen is formatted. */
	selection: ^Selection,
}

@(default_calling_convention="c", link_prefix="ghostty_")
foreign lib {
	/**
	* Create a formatter for a terminal's active screen.
	*
	* The terminal must outlive the formatter. The formatter stores a borrowed
	* reference to the terminal and reads its current state on each format call.
	*
	* @param allocator Pointer to allocator, or NULL to use the default allocator
	* @param formatter Pointer to store the created formatter handle
	* @param terminal The terminal to format (must not be NULL)
	* @param options Formatting options
	* @return GHOSTTY_SUCCESS on success, or an error code on failure
	*
	* @ingroup formatter
	*/
	formatter_terminal_new :: proc(allocator: ^Allocator, formatter: ^Formatter, terminal: Terminal, options: FormatterTerminalOptions) -> Result ---

	/**
	* Run the formatter and produce output into the caller-provided buffer.
	*
	* Each call formats the current terminal state. Pass NULL for buf to
	* query the required buffer size without writing any output; in that case
	* out_written receives the required size and the return value is
	* GHOSTTY_OUT_OF_SPACE.
	*
	* If the buffer is too small, returns GHOSTTY_OUT_OF_SPACE and sets
	* out_written to the required size. The caller can then retry with a
	* larger buffer.
	*
	* @param formatter The formatter handle (must not be NULL)
	* @param buf Pointer to the output buffer, or NULL to query size
	* @param buf_len Length of the output buffer in bytes
	* @param out_written Pointer to receive the number of bytes written,
	*                    or the required size on failure
	* @return GHOSTTY_SUCCESS on success, or an error code on failure
	*
	* @ingroup formatter
	*/
	formatter_format_buf :: proc(formatter: Formatter, buf: ^u8, buf_len: c.size_t, out_written: ^c.size_t) -> Result ---

	/**
	* Run the formatter and return an allocated buffer with the output.
	*
	* Each call formats the current terminal state. The buffer is allocated
	* using the provided allocator (or the default allocator if NULL).
	* The caller is responsible for freeing the returned buffer with
	* ghostty_free(), passing the same allocator (or NULL for the default)
	* that was used for the allocation.
	*
	* @param formatter The formatter handle (must not be NULL)
	* @param allocator Pointer to allocator, or NULL to use the default allocator
	* @param out_ptr Pointer to receive the allocated buffer
	* @param out_len Pointer to receive the length of the output in bytes
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_OUT_OF_MEMORY on allocation
	*         failure
	*
	* @ingroup formatter
	*/
	formatter_format_alloc :: proc(formatter: Formatter, allocator: ^Allocator, out_ptr: ^^u8, out_len: ^c.size_t) -> Result ---

	/**
	* Free a formatter instance.
	*
	* Releases all resources associated with the formatter. After this call,
	* the formatter handle becomes invalid.
	*
	* @param formatter The formatter handle to free (may be NULL)
	*
	* @ingroup formatter
	*/
	formatter_free :: proc(formatter: Formatter) ---
}

