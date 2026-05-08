/**
 * @file point.h
 *
 * Terminal point types for referencing locations in the terminal grid.
 */
package ghostty_vt_c

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
* A coordinate in the terminal grid.
*
* @ingroup point
*/
PointCoordinate :: struct {
	/** Column (0-indexed). */
	x: u16,

	/** Row (0-indexed). May exceed page size for screen/history tags. */
	y: u32,
}

/**
* Point reference tag.
*
* Determines which coordinate system a point uses.
*
* @ingroup point
*/
GHOSTTY_ENUM_TYPED :: enum u32 {
	/** Active area where the cursor can move. */
	ACTIVE    = 0,

	/** Visible viewport (changes when scrolled). */
	VIEWPORT  = 1,

	/** Full screen including scrollback. */
	SCREEN    = 2,

	/** Scrollback history only (before active area). */
	HISTORY   = 3,
	MAX_VALUE = 2147483647,
}

/**
* Point reference tag.
*
* Determines which coordinate system a point uses.
*
* @ingroup point
*/
PointTag :: GHOSTTY_ENUM_TYPED

/**
* Point value union.
*
* @ingroup point
*/
PointValue :: struct #raw_union {
	/** Coordinate (used for all tag variants). */
	coordinate: PointCoordinate,

	/** Padding for ABI compatibility. Do not use. */
	_padding: [2]u64,
}

/**
* Tagged union for a point in the terminal grid.
*
* @ingroup point
*/
Point :: struct {
	tag:   PointTag,
	value: PointValue,
}

