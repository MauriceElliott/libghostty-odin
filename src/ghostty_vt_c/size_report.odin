/**
 * @file size_report.h
 *
 * Size report encoding - encode terminal size reports into escape sequences.
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
* Size report style.
*
* Determines the output format for the terminal size report.
*/
SizeReportStyle :: enum u32 {
	/** In-band size report (mode 2048): ESC [ 48 ; rows ; cols ; height ; width t */
	MODE_2048 = 0,

	/** XTWINOPS text area size in pixels: ESC [ 4 ; height ; width t */
	CSI_14_T  = 1,

	/** XTWINOPS cell size in pixels: ESC [ 6 ; height ; width t */
	CSI_16_T  = 2,

	/** XTWINOPS text area size in characters: ESC [ 8 ; rows ; cols t */
	CSI_18_T  = 3,
}

/**
* Terminal size information for encoding size reports.
*/
SizeReportSize :: struct {
	/** Terminal row count in cells. */
	rows: u16,

	/** Terminal column count in cells. */
	columns: u16,

	/** Width of a single terminal cell in pixels. */
	cell_width: u32,

	/** Height of a single terminal cell in pixels. */
	cell_height: u32,
}

@(default_calling_convention="c", link_prefix="ghostty_")
foreign lib {
	/**
	* Encode a terminal size report into an escape sequence.
	*
	* Encodes a size report in the format specified by @p style into the
	* provided buffer.
	*
	* If the buffer is too small, the function returns GHOSTTY_OUT_OF_SPACE
	* and writes the required buffer size to @p out_written. The caller can
	* then retry with a sufficiently sized buffer.
	*
	* @param style The size report format to encode
	* @param size Terminal size information
	* @param buf Output buffer to write the encoded sequence into (may be NULL)
	* @param buf_len Size of the output buffer in bytes
	* @param[out] out_written On success, the number of bytes written. On
	*             GHOSTTY_OUT_OF_SPACE, the required buffer size.
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_OUT_OF_SPACE if the buffer
	*         is too small
	*/
	size_report_encode :: proc(style: SizeReportStyle, size: SizeReportSize, buf: cstring, buf_len: c.size_t, out_written: ^c.size_t) -> Result ---
}

