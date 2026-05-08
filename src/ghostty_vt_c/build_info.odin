/**
 * @file build_info.h
 *
 * Build info - query compile-time build configuration of libghostty-vt.
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
* Build optimization mode.
*/
OptimizeMode :: enum u32 {
	DEBUG          = 0,
	RELEASE_SAFE   = 1,
	RELEASE_SMALL  = 2,
	RELEASE_FAST   = 3,
	MODE_MAX_VALUE = 2147483647,
}

/**
* Build info data types that can be queried.
*
* Each variant documents the expected output pointer type.
*/
BuildInfo :: enum u32 {
	/** Invalid data type. Never results in any data extraction. */
	INVALID           = 0,

	/**
	* Whether SIMD-accelerated code paths are enabled.
	*
	* Output type: bool *
	*/
	SIMD              = 1,

	/**
	* Whether Kitty graphics protocol support is available.
	*
	* Output type: bool *
	*/
	KITTY_GRAPHICS    = 2,

	/**
	* Whether tmux control mode support is available.
	*
	* Output type: bool *
	*/
	TMUX_CONTROL_MODE = 3,

	/**
	* The optimization mode the library was built with.
	*
	* Output type: GhosttyOptimizeMode *
	*/
	OPTIMIZE          = 4,

	/**
	* The full version string (e.g. "1.2.3" or "1.2.3-dev+abcdef").
	*
	* Output type: GhosttyString *
	*/
	VERSION_STRING    = 5,

	/**
	* The major version number.
	*
	* Output type: size_t *
	*/
	VERSION_MAJOR     = 6,

	/**
	* The minor version number.
	*
	* Output type: size_t *
	*/
	VERSION_MINOR     = 7,

	/**
	* The patch version number.
	*
	* Output type: size_t *
	*/
	VERSION_PATCH     = 8,

	/**
	* The pre metadata string (e.g. "alpha", "beta", "dev"). Has zero length if
	* no pre metadata is present.
	*
	* Output type: GhosttyString *
	*/
	VERSION_PRE       = 9,

	/**
	* The build metadata string (e.g. commit hash). Has zero length if
	* no build metadata is present.
	*
	* Output type: GhosttyString *
	*/
	VERSION_BUILD     = 10,
	MAX_VALUE         = 2147483647,
}

@(default_calling_convention="c", link_prefix="ghostty_")
foreign lib {
	/**
	* Query a compile-time build configuration value.
	*
	* The caller must pass a pointer to the correct output type for the
	* requested data (see GhosttyBuildInfo variants for types).
	*
	* @param data The build info field to query
	* @param out Pointer to store the result (type depends on data parameter)
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_INVALID_VALUE if the
	*         data type is invalid
	*
	* @ingroup build_info
	*/
	build_info :: proc(data: BuildInfo, out: rawptr) -> Result ---
}

