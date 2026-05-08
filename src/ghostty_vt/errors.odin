
package ghostty_vt

import vt_c "../ghostty_vt_c"

Error :: enum {
	None,
	Out_Of_Memory,
	Invalid_Value,
	Out_Of_Space,
}

@(private)
result_to_error :: proc(r: vt_c.Result) -> Error {
	#partial switch r {
	case .OUT_OF_MEMORY: return .Out_Of_Memory
	case .INVALID_VALUE: return .Invalid_Value
	case .OUT_OF_SPACE:  return .Out_Of_Space
	}
	return .None
}
