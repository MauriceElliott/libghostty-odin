# libghostty-odin

Odin bindings for `libghostty-vt`, the virtual terminal library extracted from [Ghostty](https://ghostty.org).

## Status
Using [odin-c-bindings](https://github.com/karl-zylinski/odin-c-bindgen) by the wonderful Karl Zylenski I have now created a script that will generate the C FFI bindings based api output by libghostty-vt.

## Planned shape

- `ghostty_vt_c` — raw FFI bindings to `ghostty/vt.h`
- `ghostty_vt` — Odin-friendly wrapper API
- `example/ghostling` — minimal terminal example based on  [ghostling](https://github.com/ghostty-org/ghostling)

