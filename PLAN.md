# libghostty-odin LLM Initial Research and Plan

The below is the initial planning document produced by sonnet/gpt-5.4 and using libghostty-rs as a basis. It is not the difinitive plan, nor has it been fully checked over, it is just what I ran in the background while playing Dark Souls 3 with a friend. Consider just an initial investigation that will most likely be thrown away.

## Goal

Create an Odin repository that provides:

1. a **raw binding layer** for `libghostty-vt`,
2. a **thin, idiomatic Odin wrapper** over the most useful parts of the C API,
3. and a **small example application** proving the API shape against a real terminal loop.

This plan uses `../libghostty-rs/` as the reference implementation for scope, build strategy, and feature ordering, but does **not** copy Rust-specific API patterns into Odin.

## What has been researched

### From `libghostty-rs`

The Rust reference already gives a strong map of the surfaces that matter first:

- vendored Ghostty build via **Zig** from a pinned Ghostty commit,
- checked-in generated raw bindings against `ghostty/vt.h`,
- a higher-level wrapper around:
  - terminal creation and resize,
  - VT input feeding,
  - terminal callbacks/effects,
  - render state snapshots, row iteration, and cell iteration,
  - build info queries,
  - key encoder and mouse encoder,
  - optional Kitty graphics support.

Important implementation details in the Rust repo worth preserving conceptually:

- `libghostty-vt` is built from Ghostty, not hand-maintained independently.
- the public API is split into **raw FFI** and **friendlier wrapper** layers.
- the C API is rich in **opaque handles**, **sized structs**, **typed get/set selectors**, and **callbacks with userdata**.
- `ghostty_type_json()` exists and can be used as a validation aid for struct layout-sensitive bindings.

### From Odin conventions

The Odin-friendly shape is different from Rust:

- use **directory packages** with straightforward names,
- use **procedures**, not methods,
- use **multiple return values** for `(value, err)` or `(value, ok)`,
- keep **allocation explicit**,
- model opaque C handles as **distinct handle types** or incomplete-struct pointer types,
- avoid a Rust-style `Result<T, E>` façade or builder-heavy APIs.

## Default design decisions

These are the defaults this repository should follow unless a later implementation phase proves one of them wrong.

### 1. Repository and package layout

Recommended layout:

```text
.
├── README.md
├── PLAN.md
├── src/
│   ├── ghostty_vt_c/
│   │   ├── types.odin
│   │   ├── enums.odin
│   │   ├── terminal.odin
│   │   ├── render_state.odin
│   │   ├── key.odin
│   │   ├── mouse.odin
│   │   ├── build_info.odin
│   │   └── link_linux.odin
│   └── ghostty_vt/
│       ├── errors.odin
│       ├── terminal.odin
│       ├── render.odin
│       ├── input.odin
│       ├── build_info.odin
│       └── callbacks.odin
├── example/
│   └── ghostling_odin/
└── scripts/
    ├── sync_ghostty.sh
    ├── build_libghostty_vt.sh
    └── verify_layouts.sh
```

### 2. Build strategy

**Default choice:** follow the Rust repo's Zig-first approach.

**Zig version required: 0.15.2** (from `flake.nix` in the Rust reference repo).
**Pinned Ghostty commit:** `6590196661f769dd8f2b3e85d6c98262c4ec5b3b`

The exact `zig build` invocation is:
```sh
zig build -Demit-lib-vt -Doptimize=ReleaseFast \
          -Demit-xcframework=false -Dapp-runtime=none \
          --prefix <install-dir>
```
Env vars `GHOSTTY_SOURCE_DIR` and `GHOSTTY_ZIG_SYSTEM_DIR` control the source and Zig zig-cache paths (required for Nix sandboxed builds).

Initial implementation should:

1. pin a Ghostty commit in-repo,
2. support `GHOSTTY_SOURCE_DIR` as a local override,
3. build `libghostty-vt` through `zig build -Demit-lib-vt`,
4. keep generated/curated Odin bindings checked into the repo,
5. avoid requiring network access during normal consumer builds.

This should be done with repository scripts rather than Cargo-style build scripts.

#### Recommended build contract

- `scripts/build_libghostty_vt.sh`
  - builds/install-copies `libghostty-vt` and headers into a predictable local output directory
- `scripts/sync_ghostty.sh`
  - updates the pinned Ghostty source revision intentionally
- `scripts/verify_layouts.sh`
  - validates Odin struct layouts against `ghostty_type_json()`

**Decision:** vendored Zig build first; `pkg-config` support later.

Reason:

- the vendored path is the most reliable way to stay aligned with the exact C API version being wrapped,
- it matches the `libghostty-rs` design,
- and it avoids making the first Odin implementation depend on arbitrary system `libghostty-vt` revisions.

### 3. Binding generation strategy

**Default choice:** checked-in curated Odin bindings, not "generate on every build".

Why:

- Odin users should not need `clang`, bindgen, or a generator at normal build time.
- `ghostty/vt.h` is stable enough to pin against a Ghostty revision.
- Odin FFI is explicit enough that a curated raw package is workable.

However, this repository should still automate updates:

- generate or translate from `ghostty/vt.h` into a staging artifact,
- review and normalize names into Odin conventions,
- commit the result,
- validate sizes and field offsets against `ghostty_type_json()`.

**Decision:** use `ghostty_type_json()` as a hard validation tool, even if bindings are hand-curated.

This is especially valuable for:

- sized structs,
- structs whose fields must match Zig/C layout exactly,
- future Ghostty updates.

### 4. Error model

**Default choice:** expose Odin-style returns, not Rust-style wrappers.

At the raw layer:

- preserve the C result enum directly, including `No_Value = -4` which is a **non-error sentinel** meaning "this field has no value" (e.g. a cell has no hyperlink) — do not treat it as a failure.

At the wrapper layer:

- return `(value, Error)` for fallible constructors and queries,
- return `Error` for operations with no payload,
- return `(value, bool)` for optional data where absence is not exceptional.

Example:

```odin
package ghostty_vt_c

Error :: enum i32 {
    Ok              =  0,
    OutOfMemory     = -1,
    InvalidHandle   = -2,
    InvalidArgument = -3,
    No_Value        = -4,   // non-error sentinel: "this field has no value"
}
```

```odin
package ghostty_vt

Terminal :: struct {
    handle: ghostty_vt_c.Terminal_Handle,
}

terminal_new :: proc(opts: Options) -> (Terminal, Error) {
    h := ghostty_vt_c.terminal_new(opts)
    if h == nil {
        return {}, .OutOfMemory
    }
    return Terminal{handle = h}, .Ok
}
```

### 5. Handle ownership and lifetime

**Default choice:** make ownership explicit in the wrapper layer.

Raw layer:

- expose opaque handles exactly as handles.

Wrapper layer:

- wrap each owned handle in a small struct,
- pair every successful constructor with an explicit `destroy` proc,
- avoid hidden finalizers or implicit destruction schemes.

Example:

```odin
package ghostty_vt

destroy_terminal :: proc(t: ^Terminal) {
    if t.handle != nil {
        ghostty_vt_c.terminal_free(t.handle)
        t.handle = nil
    }
}
```

### 6. Allocator strategy

The underlying C API exposes a Zig-style allocator vtable.

**Default choice for v1:** do not make custom allocator bridging a launch blocker.

Phase 1 behavior:

- pass `nil` allocator to libghostty by default,
- use Odin allocators for wrapper-owned buffers and state,
- design the package so allocator bridging can be added without breaking the API.

Phase 2 behavior:

- add an adapter from Odin allocator conventions to Ghostty's allocator vtable where it provides real value.

Reason:

- allocator bridging is possible, but it is one of the trickiest parts to get perfectly right,
- and the core terminal/render/input API does not need it to become useful.

Example shape for the future adapter:

```odin
package ghostty_vt

import rt "base:runtime"

Allocator_Bridge :: struct {
    odin_allocator: rt.Allocator,
    c_allocator:    ghostty_vt_c.Allocator,
    vtable:         ghostty_vt_c.Allocator_Vtable,
}
```

### 7. Callback/effect model

The terminal API supports callbacks such as:

- PTY write-back,
- size reports,
- device attributes,
- XTVERSION,
- color scheme,
- and more.

**Default choice:** the wrapper owns callback state explicitly and registers C thunks plus userdata.

Design rules:

- callback state lives in an Odin struct owned by the terminal wrapper,
- the wrapper sets userdata and function pointers into the terminal,
- callbacks must respect libghostty's non-reentrancy rule for `vt_write`.

Example shape:

```odin
package ghostty_vt

Pty_Write_Fn :: #type proc(data: []u8, user_data: rawptr) -> Error

Terminal_Callbacks :: struct {
    pty_write: Pty_Write_Fn,
    user_data: rawptr,
}

Terminal :: struct {
    handle:    ghostty_vt_c.Terminal_Handle,
    callbacks: ^Terminal_Callbacks,
}
```

### 8. Public API philosophy

**Default choice:** the wrapper should be thin and honest.

That means:

- prefer direct nouns and procedures over "smart" abstractions,
- keep the raw API available for advanced use,
- expose wrapper helpers only where they remove repeated boilerplate,
- do not hide important concepts like dirty tracking, row iterators, or encoder buffers.

In practice, the Odin wrapper should feel closer to:

- "a careful ergonomic layer over C"

than to:

- "a Rust-style ownership/lifetime abstraction ported into another language".

## Proposed public surface for v1

The first useful version should cover the same high-value area as the Rust crate, but in a phased order.

### v1 raw package: `ghostty_vt_c`

Must include:

- core result enums and common types,
- opaque handles,
- terminal create/free/reset/resize/write/get/set,
- render state create/free/update/get,
- row iterator and row cell iterator APIs,
- build info queries,
- key encoder APIs,
- mouse encoder APIs.

May be deferred:

- OSC helpers,
- formatter helpers,
- SGR parser helpers,
- Kitty graphics wrappers beyond raw exposure.

### v1 wrapper package: `ghostty_vt`

Must include:

- `Terminal`
- `Render_State`
- `Row_Iterator`
- `Cell_Iterator`
- `Key_Encoder`
- `Mouse_Encoder`
- `Build_Info`
- error mapping helpers

Wrapper conveniences worth adding immediately:

- option structs with Odin names,
- `vt_write` from `[]u8`,
- `resize`,
- typed accessors for common terminal/render state fields,
- buffer-growing helpers for encoder output,
- callback registration helpers for common effects.

### Example target

Ship one real example:

- `example/ghostling_odin`

Scope:

- spawn PTY,
- create terminal,
- register PTY write callback,
- update render state,
- draw rows/cells,
- forward keyboard/mouse input through encoders.

The example should be the proof that the wrapper is correctly shaped.

## Implementation plan

### Phase 1 - Bootstrap the repo

Deliverables:

- directory/package layout,
- pinned Ghostty revision metadata,
- build script for `libghostty-vt`,
- platform link files for Linux first,
- minimal README and usage notes.

Exit criteria:

- repository builds or at least locates a local `libghostty-vt` artifact predictably,
- a tiny Odin program can link the raw package.

### Phase 2 - Raw FFI package

Deliverables:

- `ghostty_vt_c` package with:
  - handles,
  - enums,
  - structs,
  - foreign declarations,
  - layout validation support.

Exit criteria:

- a smoke test can:
  - call `ghostty_build_info`,
  - create/free a terminal,
  - create/update/free a render state.

### Phase 3 - Core wrapper

Deliverables:

- error mapping,
- terminal wrapper,
- render state wrapper,
- row/cell iterator wrapper,
- typed helpers for common get/set operations.

Exit criteria:

- wrapper can feed VT bytes and iterate visible rows/cells.

### Phase 4 - Input encoders and callbacks

Deliverables:

- key encoder wrapper,
- mouse encoder wrapper,
- callback registration helpers for the most useful terminal effects.

Exit criteria:

- a PTY-backed example can round-trip keyboard and mouse input correctly.

### Phase 5 - Example application

Deliverables:

- `ghostling_odin`,
- basic renderer,
- PTY integration,
- resize handling,
- readable demo instructions.

Exit criteria:

- a local interactive terminal example works on Linux.

### Phase 6 - Packaging and CI

Deliverables:

- CI for Linux first, then macOS,
- script or docs for vendored build,
- pinned upgrade workflow,
- optional system-lib path if still wanted after the vendored path is stable.

Exit criteria:

- reproducible CI build,
- documented update process for moving to a new Ghostty revision.

## API sketches

### Raw handle types

```odin
package ghostty_vt_c

// Opaque handle types — all are distinct rawptr
Terminal_Handle                  :: distinct rawptr
Render_State_Handle              :: distinct rawptr
Render_State_Row_Iterator_Handle :: distinct rawptr  // NOT "Row_Iterator"
Render_State_Row_Cells_Handle    :: distinct rawptr  // NOT "Row_Cells"
Key_Encoder_Handle               :: distinct rawptr
Mouse_Encoder_Handle             :: distinct rawptr
Formatter_Handle                 :: distinct rawptr
// BORROWED handles — invalidated by any mutating terminal call
Kitty_Graphics_Handle            :: distinct rawptr
Kitty_Graphics_Image_Handle      :: distinct rawptr

// Value types — NOT pointers. Passed and returned by value.
// Cell packs: codepoint, style index, cell width, and flags into a u64.
// Row  is a u64 index into render-state row storage.
// Using distinct u64 makes accidental pointer-cast a compile error.
Cell :: distinct u64
Row  :: distinct u64
```

### Raw foreign imports

```odin
package ghostty_vt_c

// Use an explicit relative path — NOT "system:ghostty-vt".
// "system:..." searches system library paths; we vendor the build ourselves.
when ODIN_OS == .Linux {
    foreign import libghostty_vt "../../build/ghostty-install/lib/libghostty-vt.so"
} else when ODIN_OS == .Darwin {
    foreign import libghostty_vt "../../build/ghostty-install/lib/libghostty-vt.dylib"
} else when ODIN_OS == .Windows {
    foreign import libghostty_vt "../../build/ghostty-install/lib/ghostty-vt.lib"
}

@(default_calling_convention="c", link_prefix="ghostty_")
foreign libghostty_vt {
    // Memory — library-allocated buffers MUST be freed with ghostty_free,
    // not the system allocator (mandatory on Windows, required everywhere).
    alloc :: proc(size: uint) -> rawptr ---
    free  :: proc(ptr: rawptr) ---

    // terminal_new takes Terminal_Options BY VALUE (not by pointer).
    terminal_new    :: proc(opts: Terminal_Options) -> Terminal_Handle ---
    terminal_free   :: proc(t: Terminal_Handle) ---
    terminal_resize :: proc(t: Terminal_Handle, cols, rows: u16,
                            cell_width_px, cell_height_px: u32) -> Error ---

    // vt_write returns VOID — no error code. Do not wrap with -> Error.
    // Callbacks fire synchronously from inside this call.
    terminal_vt_write :: proc(t: Terminal_Handle, data: [^]u8, len: uint) ---
}
```

### Thin wrapper use

```odin
package main

import "core:fmt"
import vt "../src/ghostty_vt"

main :: proc() {
    term, err := vt.terminal_new(vt.Options{
        cols = 80,
        rows = 24,
        max_scrollback = 10_000,
    })
    if err != .None {
        fmt.eprintln("terminal_new failed:", err)
        return
    }
    defer vt.destroy_terminal(&term)

    vt.vt_write(&term, transmute([]u8)"Hello, \x1b[1;32mworld\x1b[0m!\r\n")
}
```

### Render snapshot iteration

```odin
snapshot, err := vt.render_update(&render_state, term)
if err != .None {
    return
}

rows := vt.row_iterator(snapshot)
for vt.next_row(&rows) {
    cells := vt.cell_iterator(rows)
    for vt.next_cell(&cells) {
        text, ok := vt.cell_text(cells)
        if ok {
            // draw text
        }
    }
}
```

## Important technical notes

### 1. Sized structs need deliberate handling

The Ghostty C API uses structs with exact layouts that must match C ABI. Key sizes (from the actual C API):

- `Style`: 72 bytes, align 8
- `GridRef`: 24 bytes
- `Selection`: 64 bytes
- `Terminal_Options`: 16 bytes, align 8 — **has 4 bytes of implicit C padding** between `rows` (u16, offset 2) and `max_scrollback` (usize, offset 8). The Odin struct **must** include an explicit `_pad: u32` field or the layout will be silently wrong.

Plan:

- use `#assert(size_of(T) == N)` for every struct passed across the FFI boundary — catches mismatches at compile time rather than at runtime,
- validate struct field names and offsets against `ghostty_type_json()`,
- avoid repeating manual size initialization in user code.

Example:

```odin
package ghostty_vt_c

// CRITICAL: _pad is required to match implicit C ABI padding.
Terminal_Options :: struct #align(8) {
    cols:           u16,
    rows:           u16,
    _pad:           u32,      // DO NOT REMOVE — matches C padding
    max_scrollback: uintptr,  // matches C size_t on 64-bit
}
#assert(size_of(Terminal_Options) == 16)

Style :: struct #align(8) { /* fields from vt.h */ }
#assert(size_of(Style) == 72)
```

### 2. Terminal state uses a selector-enum pattern

The C API does not have per-field getter functions like `ghostty_terminal_get_title()`. All state reads and writes go through:

```c
ghostty_terminal_get(handle, GHOSTTY_TERMINAL_SELECTOR_TITLE, &out_value)
ghostty_terminal_set(handle, GHOSTTY_TERMINAL_OPTION_COLS, &value)
```

The wrapper should provide typed `get_*` / `set_*` procs that call through this pattern.

### 3. Bulk get APIs are worth supporting

The C API has `get_multi` variants for terminal and render state.

Plan:

- expose them raw immediately,
- add wrapper helpers only if a clear Odin-friendly pattern emerges,
- do not over-abstract them before real usage proves a good shape.

### 4. Encoder APIs need dynamic buffer helpers

Both key and mouse encoders can return "out of space" with required size.

Plan:

- add wrapper helpers that retry with a grown Odin slice,
- still expose the raw "caller provides buffer" APIs.

### 5. Callback reentrancy

Callbacks fire **synchronously** from inside `vt_write`. Never call `vt_write` on the same terminal from within a callback — that is undefined behaviour. The wrapper should document this and add a debug-mode `is_writing: bool` guard on the Terminal struct.

### 6. Linux first, macOS next

The Rust repo already supports Linux and macOS, but this Odin repo should stage work:

1. Linux first,
2. macOS once the raw layer and example are stable.

This reduces noise while the package shape is still moving.

## Risks and mitigations

| Risk | Why it matters | Mitigation |
| --- | --- | --- |
| Struct layout mismatch | Padding fields and sized-struct requirements are easy to get wrong | `#assert(size_of(T) == N)` compile-time checks; validate against `ghostty_type_json()` |
| Callback reentrancy | `vt_write` from a callback is UB | `is_writing` debug guard; prominent doc comment |
| Borrowed Kitty handles used after invalidation | Kitty handles become invalid after any mutating terminal call | Document clearly; thin wrapper with `valid: bool` guard |
| Link setup differences by platform | Odin build/link ergonomics differ from Cargo | isolate link files per OS and keep vendored build contract simple |
| Callback lifetime mistakes | userdata/callback mismatch can crash | terminal wrapper owns callback state explicitly |
| Allocator bridge complexity | easy to get wrong across FFI | defer custom allocator bridge until core API is stable |
| Over-porting Rust ideas | would make the API feel unnatural in Odin | keep procedures, explicit ownership, and multiple returns |

## Decisions still relevant later

These do not block the plan, but they should be revisited at implementation time:

1. **Whether to expose `pkg-config` in v1 or after vendored build stability**
   - default chosen here: **after**
2. **Whether to commit generated raw bindings or commit normalized hand-curated bindings**
   - default chosen here: **commit curated bindings plus validation**
3. **How much Kitty graphics support belongs in the first wrapper**
   - default chosen here: **raw exposure first, wrapper later**
4. **Whether allocator bridging is public in v1**
   - default chosen here: **no**

## Recommended first execution slice

The first implementation pass after this plan should do exactly this:

1. create `src/ghostty_vt_c` and define the minimal core types,
2. add Linux-only linking and a local vendored build script,
3. expose build info plus terminal/render-state create/free/update/write/resize,
4. write one smoke example that creates a terminal, writes text, and reads back a render snapshot,
5. only then start wrapping callbacks and input encoders.

That sequence gets to a meaningful "it works" point quickly without locking the repo into bad API decisions.
