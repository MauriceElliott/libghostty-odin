# libghostty-odin

Odin bindings for `libghostty-vt`, the virtual terminal library extracted from [Ghostty](https://ghostty.org).

## Status

This repository is currently in the design and planning stage.

The immediate goal is to build this in a way that:

- keeps the raw C surface available,
- adds a thin, idiomatic Odin wrapper on top,

## Planned shape

- `ghostty_vt_c` — raw FFI bindings to `ghostty/vt.h`
- `ghostty_vt` — Odin-friendly wrapper API
- `example/ghostling_odin` — minimal terminal example, similar in spirit to `ghostling_rs`

The working design and implementation plan lives in [`PLAN.md`](./PLAN.md).
