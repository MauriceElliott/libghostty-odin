package ghostty_vt_c

import "core:fmt"
foreign import libghostty_vt "../../build/ghostty-install/lib/libghostty-vt.so"


hello_world_c :: proc() {
	fmt.printf("Hellope")
}
