/**
 * @file osc.h
 *
 * OSC (Operating System Command) sequence parser and command handling.
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
* OSC command types.
*
* @ingroup osc
*/
OscCommandType :: enum u32 {
	INVALID                            = 0,
	CHANGE_WINDOW_TITLE                = 1,
	CHANGE_WINDOW_ICON                 = 2,
	SEMANTIC_PROMPT                    = 3,
	CLIPBOARD_CONTENTS                 = 4,
	REPORT_PWD                         = 5,
	MOUSE_SHAPE                        = 6,
	COLOR_OPERATION                    = 7,
	KITTY_COLOR_PROTOCOL               = 8,
	SHOW_DESKTOP_NOTIFICATION          = 9,
	HYPERLINK_START                    = 10,
	HYPERLINK_END                      = 11,
	CONEMU_SLEEP                       = 12,
	CONEMU_SHOW_MESSAGE_BOX            = 13,
	CONEMU_CHANGE_TAB_TITLE            = 14,
	CONEMU_PROGRESS_REPORT             = 15,
	CONEMU_WAIT_INPUT                  = 16,
	CONEMU_GUIMACRO                    = 17,
	CONEMU_RUN_PROCESS                 = 18,
	CONEMU_OUTPUT_ENVIRONMENT_VARIABLE = 19,
	CONEMU_XTERM_EMULATION             = 20,
	CONEMU_COMMENT                     = 21,
	KITTY_TEXT_SIZING                  = 22,
	TYPE_MAX_VALUE                     = 2147483647,
}

/**
* OSC command data types.
*
* These values specify what type of data to extract from an OSC command
* using `ghostty_osc_command_data`.
*
* @ingroup osc
*/
OscCommandData :: enum u32 {
	/** Invalid data type. Never results in any data extraction. */
	INVALID                 = 0,

	/**
	* Window title string data.
	*
	* Valid for: GHOSTTY_OSC_COMMAND_CHANGE_WINDOW_TITLE
	*
	* Output type: const char ** (pointer to null-terminated string)
	*
	* Lifetime: Valid until the next call to any ghostty_osc_* function with
	* the same parser instance. Memory is owned by the parser.
	*/
	CHANGE_WINDOW_TITLE_STR = 1,
	MAX_VALUE               = 2147483647,
}

@(default_calling_convention="c", link_prefix="ghostty_")
foreign lib {
	/**
	* Create a new OSC parser instance.
	*
	* Creates a new OSC (Operating System Command) parser using the provided
	* allocator. The parser must be freed using ghostty_vt_osc_free() when
	* no longer needed.
	*
	* @param allocator Pointer to the allocator to use for memory management, or NULL to use the default allocator
	* @param parser Pointer to store the created parser handle
	* @return GHOSTTY_SUCCESS on success, or an error code on failure
	*
	* @ingroup osc
	*/
	osc_new :: proc(allocator: ^Allocator, parser: ^OscParser) -> Result ---

	/**
	* Free an OSC parser instance.
	*
	* Releases all resources associated with the OSC parser. After this call,
	* the parser handle becomes invalid and must not be used.
	*
	* @param parser The parser handle to free (may be NULL)
	*
	* @ingroup osc
	*/
	osc_free :: proc(parser: OscParser) ---

	/**
	* Reset an OSC parser instance to its initial state.
	*
	* Resets the parser state, clearing any partially parsed OSC sequences
	* and returning the parser to its initial state. This is useful for
	* reusing a parser instance or recovering from parse errors.
	*
	* @param parser The parser handle to reset, must not be null.
	*
	* @ingroup osc
	*/
	osc_reset :: proc(parser: OscParser) ---

	/**
	* Parse the next byte in an OSC sequence.
	*
	* Processes a single byte as part of an OSC sequence. The parser maintains
	* internal state to track the progress through the sequence. Call this
	* function for each byte in the sequence data.
	*
	* When finished pumping the parser with bytes, call ghostty_osc_end
	* to get the final result.
	*
	* @param parser The parser handle, must not be null.
	* @param byte The next byte to parse
	*
	* @ingroup osc
	*/
	osc_next :: proc(parser: OscParser, byte: u8) ---

	/**
	* Finalize OSC parsing and retrieve the parsed command.
	*
	* Call this function after feeding all bytes of an OSC sequence to the parser
	* using ghostty_osc_next() with the exception of the terminating character
	* (ESC or ST). This function finalizes the parsing process and returns the
	* parsed OSC command.
	*
	* The return value is never NULL. Invalid commands will return a command
	* with type GHOSTTY_OSC_COMMAND_INVALID.
	*
	* The terminator parameter specifies the byte that terminated the OSC sequence
	* (typically 0x07 for BEL or 0x5C for ST after ESC). This information is
	* preserved in the parsed command so that responses can use the same terminator
	* format for better compatibility with the calling program. For commands that
	* do not require a response, this parameter is ignored and the resulting
	* command will not retain the terminator information.
	*
	* The returned command handle is valid until the next call to any
	* `ghostty_osc_*` function with the same parser instance with the exception
	* of command introspection functions such as `ghostty_osc_command_type`.
	*
	* @param parser The parser handle, must not be null.
	* @param terminator The terminating byte of the OSC sequence (0x07 for BEL, 0x5C for ST)
	* @return Handle to the parsed OSC command
	*
	* @ingroup osc
	*/
	osc_end :: proc(parser: OscParser, terminator: u8) -> OscCommand ---

	/**
	* Get the type of an OSC command.
	*
	* Returns the type identifier for the given OSC command. This can be used
	* to determine what kind of command was parsed and what data might be
	* available from it.
	*
	* @param command The OSC command handle to query (may be NULL)
	* @return The command type, or GHOSTTY_OSC_COMMAND_INVALID if command is NULL
	*
	* @ingroup osc
	*/
	osc_command_type :: proc(command: OscCommand) -> OscCommandType ---

	/**
	* Extract data from an OSC command.
	*
	* Extracts typed data from the given OSC command based on the specified
	* data type. The output pointer must be of the appropriate type for the
	* requested data kind. Valid command types, output types, and memory
	* safety information are documented in the `GhosttyOscCommandData` enum.
	*
	* @param command The OSC command handle to query (may be NULL)
	* @param data The type of data to extract
	* @param out Pointer to store the extracted data (type depends on data parameter)
	* @return true if data extraction was successful, false otherwise
	*
	* @ingroup osc
	*/
	osc_command_data :: proc(command: OscCommand, data: OscCommandData, out: rawptr) -> bool ---
}

