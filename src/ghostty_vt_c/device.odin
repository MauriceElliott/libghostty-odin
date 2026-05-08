/**
 * @file device.h
 *
 * Device types used by the terminal for device status and device attribute
 * queries.
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


/* DA1 conformance levels (Pp parameter). */
GHOSTTY_DA_CONFORMANCE_VT100   :: 1
GHOSTTY_DA_CONFORMANCE_VT101   :: 1
GHOSTTY_DA_CONFORMANCE_VT102   :: 6
GHOSTTY_DA_CONFORMANCE_VT125   :: 12
GHOSTTY_DA_CONFORMANCE_VT131   :: 7
GHOSTTY_DA_CONFORMANCE_VT132   :: 4
GHOSTTY_DA_CONFORMANCE_VT220   :: 62
GHOSTTY_DA_CONFORMANCE_VT240   :: 62
GHOSTTY_DA_CONFORMANCE_VT320   :: 63
GHOSTTY_DA_CONFORMANCE_VT340   :: 63
GHOSTTY_DA_CONFORMANCE_VT420   :: 64
GHOSTTY_DA_CONFORMANCE_VT510   :: 65
GHOSTTY_DA_CONFORMANCE_VT520   :: 65
GHOSTTY_DA_CONFORMANCE_VT525   :: 65
GHOSTTY_DA_CONFORMANCE_LEVEL_2  :: 62
GHOSTTY_DA_CONFORMANCE_LEVEL_3  :: 63
GHOSTTY_DA_CONFORMANCE_LEVEL_4  :: 64
GHOSTTY_DA_CONFORMANCE_LEVEL_5  :: 65

/* DA1 feature codes (Ps parameters). */
GHOSTTY_DA_FEATURE_COLUMNS_132          :: 1
GHOSTTY_DA_FEATURE_PRINTER              :: 2
GHOSTTY_DA_FEATURE_REGIS                :: 3
GHOSTTY_DA_FEATURE_SIXEL                :: 4
GHOSTTY_DA_FEATURE_SELECTIVE_ERASE      :: 6
GHOSTTY_DA_FEATURE_USER_DEFINED_KEYS    :: 8
GHOSTTY_DA_FEATURE_NATIONAL_REPLACEMENT :: 9
GHOSTTY_DA_FEATURE_TECHNICAL_CHARACTERS :: 15
GHOSTTY_DA_FEATURE_LOCATOR              :: 16
GHOSTTY_DA_FEATURE_TERMINAL_STATE       :: 17
GHOSTTY_DA_FEATURE_WINDOWING            :: 18
GHOSTTY_DA_FEATURE_HORIZONTAL_SCROLLING :: 21
GHOSTTY_DA_FEATURE_ANSI_COLOR           :: 22
GHOSTTY_DA_FEATURE_RECTANGULAR_EDITING  :: 28
GHOSTTY_DA_FEATURE_ANSI_TEXT_LOCATOR    :: 29
GHOSTTY_DA_FEATURE_CLIPBOARD            :: 52

/* DA2 device type identifiers (Pp parameter). */
GHOSTTY_DA_DEVICE_TYPE_VT100  :: 0
GHOSTTY_DA_DEVICE_TYPE_VT220  :: 1
GHOSTTY_DA_DEVICE_TYPE_VT240  :: 2
GHOSTTY_DA_DEVICE_TYPE_VT330  :: 18
GHOSTTY_DA_DEVICE_TYPE_VT340  :: 19
GHOSTTY_DA_DEVICE_TYPE_VT320  :: 24
GHOSTTY_DA_DEVICE_TYPE_VT382  :: 32
GHOSTTY_DA_DEVICE_TYPE_VT420  :: 41
GHOSTTY_DA_DEVICE_TYPE_VT510  :: 61
GHOSTTY_DA_DEVICE_TYPE_VT520  :: 64
GHOSTTY_DA_DEVICE_TYPE_VT525  :: 65

/**
* Color scheme reported in response to a CSI ? 996 n query.
*
* @ingroup terminal
*/
GHOSTTY_ENUM_TYPED :: enum u32 {
	LIGHT     = 0,
	DARK      = 1,
	MAX_VALUE = 2147483647,
}

/**
* Color scheme reported in response to a CSI ? 996 n query.
*
* @ingroup terminal
*/
ColorScheme :: GHOSTTY_ENUM_TYPED

/**
* Primary device attributes (DA1) response data.
*
* Returned as part of GhosttyDeviceAttributes in response to a CSI c query.
* The conformance_level is the Pp parameter and features contains the Ps
* feature codes.
*
* @ingroup terminal
*/
DeviceAttributesPrimary :: struct {
	/** Conformance level (Pp parameter). E.g. 62 for VT220. */
	conformance_level: u16,

	/** DA1 feature codes. Only the first num_features entries are valid. */
	features: [64]u16,

	/** Number of valid entries in the features array. */
	num_features: c.size_t,
}

/**
* Secondary device attributes (DA2) response data.
*
* Returned as part of GhosttyDeviceAttributes in response to a CSI > c query.
* Response format: CSI > Pp ; Pv ; Pc c
*
* @ingroup terminal
*/
DeviceAttributesSecondary :: struct {
	/** Terminal type identifier (Pp). E.g. 1 for VT220. */
	device_type: u16,

	/** Firmware/patch version number (Pv). */
	firmware_version: u16,

	/** ROM cartridge registration number (Pc). Always 0 for emulators. */
	rom_cartridge: u16,
}

/**
* Tertiary device attributes (DA3) response data.
*
* Returned as part of GhosttyDeviceAttributes in response to a CSI = c query.
* Response format: DCS ! | D...D ST (DECRPTUI).
*
* @ingroup terminal
*/
DeviceAttributesTertiary :: struct {
	/** Unit ID encoded as 8 uppercase hex digits in the response. */
	unit_id: u32,
}

/**
* Device attributes response data for all three DA levels.
*
* Filled by the device_attributes callback in response to CSI c,
* CSI > c, or CSI = c queries. The terminal uses whichever sub-struct
* matches the request type.
*
* @ingroup terminal
*/
DeviceAttributes :: struct {
	primary:   DeviceAttributesPrimary,
	secondary: DeviceAttributesSecondary,
	tertiary:  DeviceAttributesTertiary,
}

