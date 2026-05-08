/**
 * @file selection.h
 *
 * Selection range type for specifying a region of terminal content.
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
* A selection range defined by two grid references.
*
* This is a sized struct. Use GHOSTTY_INIT_SIZED() to initialize it.
*
* @ingroup selection
*/
Selection :: struct {
	/** Size of this struct in bytes. Must be set to sizeof(GhosttySelection). */
	size: c.size_t,

	/** Start of the selection range (inclusive). */
	start: GridRef,

	/** End of the selection range (inclusive). */
	end: GridRef,

	/** Whether the selection is rectangular (block) rather than linear. */
	rectangle: bool,
}

