/**
 * @file focus.h
 *
 * Focus encoding - encode focus in/out events into terminal escape sequences.
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
* Focus event types for focus reporting mode (mode 1004).
*/
FocusEvent :: enum u32 {
	/** Terminal window gained focus */
	GAINED = 0,

	/** Terminal window lost focus */
	LOST   = 1,
}

@(default_calling_convention="c", link_prefix="ghostty_")
foreign lib {
	/**
	* Encode a focus event into a terminal escape sequence.
	*
	* Encodes a focus gained (CSI I) or focus lost (CSI O) report into the
	* provided buffer.
	*
	* If the buffer is too small, the function returns GHOSTTY_OUT_OF_SPACE
	* and writes the required buffer size to @p out_written. The caller can
	* then retry with a sufficiently sized buffer.
	*
	* @param event The focus event to encode
	* @param buf Output buffer to write the encoded sequence into (may be NULL)
	* @param buf_len Size of the output buffer in bytes
	* @param[out] out_written On success, the number of bytes written. On
	*             GHOSTTY_OUT_OF_SPACE, the required buffer size.
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_OUT_OF_SPACE if the buffer
	*         is too small
	*/
	focus_encode :: proc(event: FocusEvent, buf: cstring, buf_len: c.size_t, out_written: ^c.size_t) -> Result ---
}

