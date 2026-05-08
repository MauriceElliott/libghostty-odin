/**
 * @file modes.h
 *
 * Terminal mode utilities - pack and unpack ANSI/DEC mode identifiers.
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
* A packed 16-bit terminal mode.
*
* Encodes a mode value (bits 0–14) and an ANSI flag (bit 15) into a
* single 16-bit integer. Use the inline helper functions to construct
* and inspect modes rather than manipulating bits directly.
*/
Mode :: u16

/**
* DECRPM report state values.
*
* These correspond to the Ps2 parameter in a DECRPM response
* sequence (CSI ? Ps1 ; Ps2 $ y).
*/
ModeReportState :: enum u32 {
	/** Mode is not recognized */
	NOT_RECOGNIZED    = 0,

	/** Mode is set (enabled) */
	SET               = 1,

	/** Mode is reset (disabled) */
	RESET             = 2,

	/** Mode is permanently set */
	PERMANENTLY_SET   = 3,

	/** Mode is permanently reset */
	PERMANENTLY_RESET = 4,
}

@(default_calling_convention="c", link_prefix="ghostty_")
foreign lib {
	/**
	* Encode a DECRPM (DEC Private Mode Report) response sequence.
	*
	* Writes a mode report escape sequence into the provided buffer.
	* The generated sequence has the form:
	* - DEC private mode: CSI ? Ps1 ; Ps2 $ y
	* - ANSI mode:        CSI Ps1 ; Ps2 $ y
	*
	* If the buffer is too small, the function returns GHOSTTY_OUT_OF_SPACE
	* and writes the required buffer size to @p out_written. The caller can
	* then retry with a sufficiently sized buffer.
	*
	* @param mode The mode identifying the mode to report on
	* @param state The report state for this mode
	* @param buf Output buffer to write the encoded sequence into (may be NULL)
	* @param buf_len Size of the output buffer in bytes
	* @param[out] out_written On success, the number of bytes written. On
	*             GHOSTTY_OUT_OF_SPACE, the required buffer size.
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_OUT_OF_SPACE if the buffer
	*         is too small
	*/
	mode_report_encode :: proc(mode: Mode, state: ModeReportState, buf: cstring, buf_len: c.size_t, out_written: ^c.size_t) -> Result ---
}

