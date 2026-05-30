-- =============================================================================
-- ghostling illustrated in Lua pseudocode
-- Maps 1:1 to libghostty-rs/example/ghostling_rs/src/main.rs
-- =============================================================================

local ghostty   = require("libghostty_vt")   -- safe wrapper (libghostty-vt)
local window    = require("macroquad")        -- window/render backend
local pty_lib   = require("pty")              -- pseudo-terminal helper

-- ---------------------------------------------------------------------------
-- 1. STARTUP — measure font, derive grid, spawn child
-- ---------------------------------------------------------------------------

local FONT_SIZE = 10
local PADDING   = 6.0
local CELL_GAP  = 0.0
local ROW_GAP   = 12.0

-- Measure a representative glyph to get monospace cell dimensions.
-- This drives every downstream calculation (grid size, mouse hit-testing, etc.)
local glyph  = window.measure_text("M", font, FONT_SIZE, window.dpi_scale())
local cell_w = glyph.width  + CELL_GAP  -- pixels per column
local cell_h = glyph.height + ROW_GAP   -- pixels per row

local function grid_size(win_w, win_h)
    return
        math.max(1, math.floor((win_w - 2 * PADDING) / cell_w)),
        math.max(1, math.floor((win_h - 2 * PADDING) / cell_h))
end

local cols, rows = grid_size(window.width(), window.height())

-- grid_size is stored in a mutable cell so both the main loop and the
-- on_size effect handler can read/write it without aliasing conflicts.
-- (In Rust this is `Cell<(u16,u16)>` — a single-threaded interior-mutable box.)
local grid_size_cell = { cols = cols, rows = rows }

-- Spawn $SHELL inside a pseudo-terminal at the computed winsize.
-- forkpty() gives us a master fd (non-blocking) and the child PID.
local pty, child = pty_lib.new({ cols=cols, rows=rows,
                                  px_w=window.width(), px_h=window.height() })

-- ---------------------------------------------------------------------------
-- 2. TERMINAL — create the virtual terminal state machine
-- ---------------------------------------------------------------------------

-- Terminal holds ALL parsed VT state: screen grid, scrollback, cursor,
-- SGR styles, mode flags, Kitty graphics storage, etc.
-- It knows NOTHING about the PTY or the window — purely a VT parser + model.
local terminal = ghostty.Terminal.new({
    cols           = cols,
    rows           = rows,
    max_scrollback = 1000,
})

-- Push the pixel cell dimensions in so Kitty graphics placement_rect
-- doesn't divide by zero.
terminal:resize(cols, rows, cell_w, cell_h)

-- Allow images up to 64 MiB and all transmission mediums.
terminal:set_kitty_image_storage_limit(64 * 1024 * 1024)
terminal:set_kitty_image_from_file_allowed(true)
terminal:set_kitty_image_from_temp_file_allowed(true)
terminal:set_kitty_image_from_shared_mem_allowed(true)

-- ---------------------------------------------------------------------------
-- 3. EFFECTS — teach the terminal how to respond to VT queries
--
-- Effects are callbacks fired synchronously inside vt_write().
-- Without them, device-attribute queries, size reports, etc. are silently
-- dropped — vim / tmux / htop will hang or degrade.
-- ---------------------------------------------------------------------------

-- on_pty_write: the terminal needs to send a response back down the PTY
-- (e.g. answering a DECRQM mode query with CSI ? 7 ; 1 $ y).
terminal:on_pty_write(function(t, data)
    pty:write(data)
end)

-- on_size: answer XTWINOPS size queries (CSI 14 / 16 / 18 t).
-- Shared state is captured by reference so the closure sees live values
-- without copying — same pattern as Rust's `let gs = &grid_size`.
terminal:on_size(function(t)
    return {
        rows        = grid_size_cell.rows,
        columns     = grid_size_cell.cols,
        cell_width  = cell_w,
        cell_height = cell_h,
    }
end)

-- on_device_attributes: answer DA1 / DA2 / DA3 capability queries.
-- We claim VT220 with a modest feature set so vim/tmux don't complain.
terminal:on_device_attributes(function(t)
    return {
        primary = {
            conformance_level = ghostty.ConformanceLevel.VT220,
            features = {
                ghostty.DeviceAttributeFeature.COLUMNS_132,
                ghostty.DeviceAttributeFeature.SELECTIVE_ERASE,
                ghostty.DeviceAttributeFeature.ANSI_COLOR,
            },
        },
        secondary = {
            device_type      = ghostty.DeviceType.VT220,
            firmware_version = 1,
            rom_cartridge    = 0,
        },
        tertiary = { unit_id = 0 },
    }
end)

terminal:on_xtversion(function(t) return "ghostling-lua" end)
terminal:on_color_scheme(function(t) return nil end)  -- don't report OS theme

-- ---------------------------------------------------------------------------
-- 4. RENDER OBJECTS — pre-allocate iterators (reused every frame)
--
-- RenderState takes a snapshot of the terminal's grid once per frame.
-- RowIterator / CellIterator are cursor-like handles that walk that snapshot.
-- Pre-allocating them avoids per-frame heap pressure.
-- ---------------------------------------------------------------------------

local render_state   = ghostty.RenderState.new()
local row_iter       = ghostty.RowIterator.new()
local cell_iter      = ghostty.CellIterator.new()
local placement_iter = ghostty.PlacementIterator.new()

-- ---------------------------------------------------------------------------
-- 5. INPUT OBJECTS — pre-allocate encoders + event structs
--
-- The key encoder translates macroquad key events into correct VT escape
-- sequences, respecting terminal modes (app cursor keys, Kitty kbd protocol).
-- The mouse encoder does the same for pointer events.
-- ---------------------------------------------------------------------------

local key_encoder   = ghostty.key.Encoder.new()
local key_event     = ghostty.key.Event.new()
local mouse_encoder = ghostty.mouse.Encoder.new()
local mouse_event   = ghostty.mouse.Event.new()
local response_buf  = {}  -- bytes to write back to the PTY this frame

-- ---------------------------------------------------------------------------
-- 6. MAIN LOOP — resize → read PTY → input → render, every frame
-- ---------------------------------------------------------------------------

while true do

    -- 6a. RESIZE — recalculate grid when the window changes size.
    --     Notify both the terminal model (reflow) and the PTY (SIGWINCH).
    if window.width() ~= cell_w_prev or window.height() ~= cell_h_prev then
        cols, rows = grid_size(window.width(), window.height())
        grid_size_cell.cols = cols
        grid_size_cell.rows = rows
        terminal:resize(cols, rows, cell_w, cell_h)
        pty:resize({ cols=cols, rows=rows,
                     px_w=window.width(), px_h=window.height() })
    end

    -- 6b. PTY READ / INPUT — only while the child shell is alive
    if child:is_active() then

        -- --- KEYBOARD ---
        -- Drain macroquad's char queue for printable text this frame.
        local text = window.get_chars_pressed()

        for _, key_info in ipairs(ALL_KEYS) do
            local kc, key, ucp = key_info[1], key_info[2], key_info[3]

            local action = nil
            if     window.is_key_released(kc) then action = ghostty.key.Action.Release
            elseif window.is_key_pressed(kc)  then action = ghostty.key.Action.Press
            end
            if not action then goto continue end

            local mods = keyboard_mods()

            -- consumed_mods: shift is "used up" when it produces uppercase text.
            local consumed = ghostty.key.Mods.empty()
            if ucp ~= '\0' and mods:has(ghostty.key.Mods.SHIFT) then
                consumed = ghostty.key.Mods.SHIFT
            end

            key_event
                :set_action(action)
                :set_key(key)
                :set_mods(mods)
                :set_consumed_mods(consumed)
                :set_unshifted_codepoint(ucp)
                :set_utf8(action ~= ghostty.key.Action.Release and text or nil)

            -- Sync encoder from terminal so mode changes are respected,
            -- then encode to VT bytes.
            key_encoder
                :set_options_from_terminal(terminal)
                :encode_to_vec(key_event, response_buf)

            if #response_buf > 0 then text = nil end  -- encoder consumed it
            ::continue::
        end

        -- Fallback: char arrived a frame late with no matching key event.
        if text and #text > 0 then
            for b in text:bytes() do response_buf[#response_buf + 1] = b end
        end

        -- --- MOUSE ---
        local mx, my      = window.mouse_position()
        local any_pressed = any_mouse_button_down()

        mouse_event
            :set_mods(keyboard_mods())
            :set_position({ x=mx, y=my })

        mouse_encoder
            :set_options_from_terminal(terminal)  -- respects SGR/X10 mode
            :set_size({
                screen_width   = window.width(),   screen_height  = window.height(),
                cell_width     = cell_w,           cell_height    = cell_h,
                padding_top    = PADDING,          padding_bottom = PADDING,
                padding_left   = PADDING,          padding_right  = PADDING,
            })
            :set_any_button_pressed(any_pressed)
            :set_track_last_cell(true)  -- suppress duplicate cell-motion events

        for _, btn_info in ipairs(ALL_MOUSE_BUTTONS) do
            local mb, btn = btn_info[1], btn_info[2]
            local action  = nil
            if     window.is_mouse_button_released(mb) then action = ghostty.mouse.Action.Release
            elseif window.is_mouse_button_pressed(mb)  then action = ghostty.mouse.Action.Press
            end
            if not action then goto continue end
            mouse_event:set_action(action):set_button(btn)
            mouse_encoder:encode_to_vec(mouse_event, response_buf)
            ::continue::
        end

        -- Motion: send a motion event with whatever button is held, if any.
        local dx, dy = window.mouse_delta()
        if math.abs(dx) > 1e-6 or math.abs(dy) > 1e-6 then
            mouse_event
                :set_action(ghostty.mouse.Action.Motion)
                :set_button(held_button())
            mouse_encoder:encode_to_vec(mouse_event, response_buf)
        end

        -- Scroll wheel: forward to the app as button 4/5 when mouse tracking
        -- is active, otherwise scroll the viewport through the scrollback buffer.
        local wx, wy = window.mouse_wheel()
        if math.abs(wy) > 1e-6 then
            if any_mouse_tracking_mode_active(terminal) then
                local btn = wy > 0 and ghostty.mouse.Button.Four or ghostty.mouse.Button.Five
                mouse_event:set_button(btn):set_action(ghostty.mouse.Action.Press)
                mouse_encoder:encode_to_vec(mouse_event, response_buf)
                mouse_event:set_action(ghostty.mouse.Action.Release)
                mouse_encoder:encode_to_vec(mouse_event, response_buf)
            else
                terminal:scroll_viewport(ghostty.ScrollViewport.Delta(math.floor(wy * -2.5)))
            end
        end

        -- Flush encoded input back to the shell.
        pty:write(response_buf)
        response_buf = {}

        -- Feed raw PTY output into the terminal's VT parser.
        -- vt_write() is the ONLY entry point; it handles everything:
        -- text, colors, cursor movement, mode changes, OSC, Kitty graphics…
        local ok, err = pty:read(function(chunk)
            terminal:vt_write(chunk)
        end)
        if err == "eof" then child:mark_exited() end

    elseif child:is_exited() then
        -- Reap the child process so we don't leave a zombie.
        child:waitpid_no_hang()
        window.quit()
    end

    -- -----------------------------------------------------------------------
    -- 6c. RENDER
    -- -----------------------------------------------------------------------

    -- Snapshot the terminal into the render state. This is the ONE place
    -- we touch the terminal during rendering — after this the snapshot is
    -- self-contained and the terminal is free to receive more data.
    local snapshot = render_state:update(terminal)

    -- Clear window to the terminal's background color.
    local colors = snapshot:colors()
    window.clear(colors.background)

    local graphics = terminal:kitty_graphics()

    -- Layer 1: images that must sit BELOW cell backgrounds (z < INT32_MIN/2)
    render_kitty_layer(terminal, placement_iter, graphics, "below_bg")

    -- Walk every row in the viewport.
    local y      = PADDING
    local row_it = row_iter:update(snapshot)
    while row_it:next() do
        local x       = PADDING
        local cell_it = cell_iter:update(row_it)

        while cell_it:next() do
            local ngraphemes = cell_it:graphemes_len()
            local bg         = cell_it:bg_color()  -- nil → use terminal default

            if ngraphemes == 0 then
                -- Empty cell: only draw background if explicitly colored.
                if bg then
                    window.draw_rect(x, y, cell_w, cell_h, bg)
                end
            else
                local text  = table.concat(cell_it:graphemes())
                local fg    = cell_it:fg_color() or colors.foreground
                bg          = bg or colors.background
                local style = cell_it:style()

                -- Reverse video: swap fg/bg so highlighted text inverts.
                if style.inverse then fg, bg = bg, fg end

                window.draw_rect(x, y, cell_w, cell_h, bg)
                window.draw_text(text, x, y + FONT_SIZE + ROW_GAP, {
                    font  = font,
                    size  = FONT_SIZE * window.dpi_scale(),
                    color = fg,
                })

                -- Fake bold: draw text twice, second pass shifted 1px right
                -- to thicken strokes without needing a separate bold font face.
                if style.bold then
                    window.draw_text(text, x + 1, y + FONT_SIZE + ROW_GAP, {
                        font  = font,
                        size  = FONT_SIZE * window.dpi_scale(),
                        color = fg,
                    })
                end
            end

            x = x + cell_w
        end

        row_it:set_dirty(false)  -- mark row clean so next frame can skip it
        y = y + cell_h
    end

    -- Layer 2: images below text but above cell backgrounds
    render_kitty_layer(terminal, placement_iter, graphics, "below_text")

    -- Draw the cursor (block, rendered as a filled rect over the cell).
    if snapshot:cursor_visible() then
        local vp = snapshot:cursor_viewport()  -- nil when scrolled off-screen
        if vp then
            local cursor_color = colors.cursor or colors.foreground
            window.draw_rect(
                PADDING + vp.x * cell_w,
                PADDING + vp.y * cell_h,
                cell_w, cell_h,
                cursor_color
            )
        end
    end

    -- Layer 3: images that sit ON TOP of text (z >= 0)
    render_kitty_layer(terminal, placement_iter, graphics, "above_text")

    -- Reset global dirty flag so the next update knows what actually changed.
    snapshot:set_dirty("clean")

    window.next_frame()
end

-- ---------------------------------------------------------------------------
-- Kitty graphics helper
-- Iterates image placements for a given z-layer and blits each one.
-- ---------------------------------------------------------------------------
function render_kitty_layer(terminal, placement_iter, graphics, layer)
    if not graphics then return end

    local placements = placement_iter:update(graphics)
    placements:set_layer(layer)

    while placements:next() do
        local img = graphics:image(placements:image_id())
        if not img then goto skip end

        local info = placements:placement_render_info(img, terminal)

        -- Skip images outside the viewport or with zero dimensions.
        if not info.viewport_visible
            or info.pixel_width  == 0 or info.pixel_height == 0
            or info.grid_cols    == 0 or info.grid_rows    == 0
        then goto skip end

        -- We only handle RGBA — the registered PNG decoder converts everything.
        if img:format() ~= "rgba" then goto skip end

        -- Build a GPU texture from raw RGBA pixels and blit it into the grid.
        local tex = window.Texture2D.from_rgba8(img:width(), img:height(), img:data())
        window.draw_texture(tex,
            PADDING + info.viewport_col * cell_w + placements:x_offset(),
            PADDING + info.viewport_row * cell_h + placements:y_offset(),
            {
                dest_size = { info.grid_cols * cell_w, info.grid_rows * cell_h },
                source    = {
                    info.source_x, info.source_y,
                    info.source_width, info.source_height,
                },
            }
        )
        ::skip::
    end
end
