/**
 * @file paste.h
 *
 * Paste utilities - validate and encode paste data for terminal input.
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


@(default_calling_convention="c", link_prefix="ghostty_")
foreign lib {
	/**
	* Check if paste data is safe to paste into the terminal.
	*
	* Data is considered unsafe if it contains:
	* - Newlines (`\n`) which can inject commands
	* - The bracketed paste end sequence (`\x1b[201~`) which can be used
	*   to exit bracketed paste mode and inject commands
	*
	* This check is conservative and considers data unsafe regardless of
	* current terminal state.
	*
	* @param data The paste data to check (must not be NULL)
	* @param len The length of the data in bytes
	* @return true if the data is safe to paste, false otherwise
	*/
	paste_is_safe :: proc(data: cstring, len: c.size_t) -> bool ---

	/**
	* Encode paste data for writing to the terminal pty.
	*
	* This function prepares paste data for terminal input by:
	* - Stripping unsafe control bytes (NUL, ESC, DEL, etc.) by replacing
	*   them with spaces
	* - Wrapping the data in bracketed paste sequences if @p bracketed is true
	* - Replacing newlines with carriage returns if @p bracketed is false
	*
	* The input @p data buffer is modified in place during encoding. The
	* encoded result (potentially with bracketed paste prefix/suffix) is
	* written to the output buffer.
	*
	* If the output buffer is too small, the function returns
	* GHOSTTY_OUT_OF_SPACE and sets the required size in @p out_written.
	* The caller can then retry with a sufficiently sized buffer.
	*
	* @param data The paste data to encode (modified in place, may be NULL)
	* @param data_len The length of the input data in bytes
	* @param bracketed Whether bracketed paste mode is active
	* @param buf Output buffer to write the encoded result into (may be NULL)
	* @param buf_len Size of the output buffer in bytes
	* @param[out] out_written On success, the number of bytes written. On
	*             GHOSTTY_OUT_OF_SPACE, the required buffer size.
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_OUT_OF_SPACE if the buffer
	*         is too small
	*/
	paste_encode :: proc(data: cstring, data_len: c.size_t, bracketed: bool, buf: cstring, buf_len: c.size_t, out_written: ^c.size_t) -> Result ---
}

