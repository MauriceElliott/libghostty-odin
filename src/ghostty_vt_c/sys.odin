/**
 * @file sys.h
 *
 * System interface - runtime-swappable implementations for external dependencies.
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
* Result of decoding an image.
*
* The `data` buffer must be allocated through the allocator provided to
* the decode callback. The library takes ownership and will free it
* with the same allocator.
*/
SysImage :: struct {
	/** Image width in pixels. */
	width: u32,

	/** Image height in pixels. */
	height: u32,

	/** Pointer to the decoded RGBA pixel data. */
	data: ^u8,

	/** Length of the pixel data in bytes. */
	data_len: c.size_t,
}

/**
* Log severity levels for the log callback.
*/
SysLogLevel :: enum u32 {
	ERROR   = 0,
	WARNING = 1,
	INFO    = 2,
	DEBUG   = 3,
}

/**
* Callback type for logging.
*
* When installed, internal library log messages are delivered through
* this callback instead of being discarded. The embedder is responsible
* for formatting and routing log output.
*
* @p scope is the log scope name as UTF-8 bytes (e.g. "osc", "kitty").
* When the log is unscoped (default scope), @p scope_len is 0.
*
* All pointer arguments are only valid for the duration of the callback.
* The callback must be safe to call from any thread.
*
* @param userdata    The userdata pointer set via GHOSTTY_SYS_OPT_USERDATA
* @param level       The severity level of the log message
* @param scope       Pointer to the scope name bytes
* @param scope_len   Length of the scope name in bytes
* @param message     Pointer to the log message bytes
* @param message_len Length of the log message in bytes
*/
SysLogFn :: proc "c" (userdata: rawptr, level: SysLogLevel, scope: ^u8, scope_len: c.size_t, message: ^u8, message_len: c.size_t)

/**
* Callback type for PNG decoding.
*
* Decodes raw PNG data into RGBA pixels. The output pixel data must be
* allocated through the provided allocator. The library takes ownership
* of the buffer and will free it with the same allocator.
*
* @param userdata  The userdata pointer set via GHOSTTY_SYS_OPT_USERDATA
* @param allocator The allocator to use for the output pixel buffer
* @param data      Pointer to the raw PNG data
* @param data_len  Length of the raw PNG data in bytes
* @param[out] out  On success, filled with the decoded image
* @return true on success, false on failure
*/
SysDecodePngFn :: proc "c" (userdata: rawptr, allocator: ^Allocator, data: ^u8, data_len: c.size_t, out: ^SysImage) -> bool

/**
* System option identifiers for ghostty_sys_set().
*/
SysOption :: enum u32 {
	/**
	* Set the userdata pointer passed to all sys callbacks.
	*
	* Input type: void* (or NULL)
	*/
	USERDATA   = 0,

	/**
	* Set the PNG decode function.
	*
	* When set, the terminal can accept PNG images via the Kitty
	* Graphics Protocol. When cleared (NULL value), PNG decoding is
	* unsupported and PNG image data will be rejected.
	*
	* Input type: GhosttySysDecodePngFn (function pointer, or NULL)
	*/
	DECODE_PNG = 1,

	/**
	* Set the log callback.
	*
	* When set, internal library log messages are delivered to this
	* callback. When cleared (NULL value), log messages are silently
	* discarded.
	*
	* Use ghostty_sys_log_stderr as a convenience callback that
	* writes formatted messages to stderr.
	*
	* Which log levels are emitted depends on the build mode of the
	* library and is not configurable at runtime. Debug builds emit
	* all levels (debug and above). Release builds emit info and
	* above; debug-level messages are compiled out entirely and will
	* never reach the callback.
	*
	* Input type: GhosttySysLogFn (function pointer, or NULL)
	*/
	LOG        = 2,
}

@(default_calling_convention="c", link_prefix="ghostty_")
foreign lib {
	/**
	* Set a system-level option.
	*
	* Configures a process-global implementation function. These should be
	* set once at startup before using any terminal functionality that
	* depends on them.
	*
	* @param option The option to set
	* @param value  Pointer to the value (type depends on the option),
	*               or NULL to clear it
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_INVALID_VALUE if the
	*         option is not recognized
	*/
	sys_set :: proc(option: SysOption, value: rawptr) -> Result ---

	/**
	* Built-in log callback that writes to stderr.
	*
	* Formats each message as "[level](scope): message\n".
	* Can be passed directly to ghostty_sys_set():
	*
	* @code
	* ghostty_sys_set(GHOSTTY_SYS_OPT_LOG, &ghostty_sys_log_stderr);
	* @endcode
	*/
	sys_log_stderr :: proc(userdata: rawptr, level: SysLogLevel, scope: ^u8, scope_len: c.size_t, message: ^u8, message_len: c.size_t) ---
}

