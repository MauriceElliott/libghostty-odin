/**
 * @file selection.h
 *
 * Selection range type for specifying a region of terminal content.
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

