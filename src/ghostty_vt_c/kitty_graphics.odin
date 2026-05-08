/**
 * @file kitty_graphics.h
 *
 * Kitty graphics protocol 
 *
 * See @ref kitty_graphics for a full usage guide.
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


/**
* Queryable data kinds for ghostty_kitty_graphics_get().
*
* @ingroup kitty_graphics
*/
KittyGraphicsData :: enum u32 {
	/** Invalid / sentinel value. */
	INVALID            = 0,

	/**
	* Populate a pre-allocated placement iterator with placement data from
	* the storage. Iterator data is only valid as long as the underlying
	* terminal is not mutated.
	*
	* Output type: GhosttyKittyGraphicsPlacementIterator *
	*/
	PLACEMENT_ITERATOR = 1,
	MAX_VALUE          = 2147483647,
}

/**
* Queryable data kinds for ghostty_kitty_graphics_placement_get().
*
* @ingroup kitty_graphics
*/
KittyGraphicsPlacementData :: enum u32 {
	/** Invalid / sentinel value. */
	INVALID       = 0,

	/**
	* The image ID this placement belongs to.
	*
	* Output type: uint32_t *
	*/
	IMAGE_ID      = 1,

	/**
	* The placement ID.
	*
	* Output type: uint32_t *
	*/
	PLACEMENT_ID  = 2,

	/**
	* Whether this is a virtual placement (unicode placeholder).
	*
	* Output type: bool *
	*/
	IS_VIRTUAL    = 3,

	/**
	* Pixel offset from the left edge of the cell.
	*
	* Output type: uint32_t *
	*/
	X_OFFSET      = 4,

	/**
	* Pixel offset from the top edge of the cell.
	*
	* Output type: uint32_t *
	*/
	Y_OFFSET      = 5,

	/**
	* Source rectangle x origin in pixels.
	*
	* Output type: uint32_t *
	*/
	SOURCE_X      = 6,

	/**
	* Source rectangle y origin in pixels.
	*
	* Output type: uint32_t *
	*/
	SOURCE_Y      = 7,

	/**
	* Source rectangle width in pixels (0 = full image width).
	*
	* Output type: uint32_t *
	*/
	SOURCE_WIDTH  = 8,

	/**
	* Source rectangle height in pixels (0 = full image height).
	*
	* Output type: uint32_t *
	*/
	SOURCE_HEIGHT = 9,

	/**
	* Number of columns this placement occupies.
	*
	* Output type: uint32_t *
	*/
	COLUMNS       = 10,

	/**
	* Number of rows this placement occupies.
	*
	* Output type: uint32_t *
	*/
	ROWS          = 11,

	/**
	* Z-index for this placement.
	*
	* Output type: int32_t *
	*/
	Z             = 12,
	MAX_VALUE     = 2147483647,
}

/**
* Z-layer classification for kitty graphics placements.
*
* Based on the kitty protocol z-index conventions:
* - BELOW_BG:   z < INT32_MIN/2  (drawn below cell background)
* - BELOW_TEXT:  INT32_MIN/2 <= z < 0  (above background, below text)
* - ABOVE_TEXT:  z >= 0  (above text)
* - ALL:         no filtering (current behavior)
*
* @ingroup kitty_graphics
*/
KittyPlacementLayer :: enum u32 {
	ALL        = 0,
	BELOW_BG   = 1,
	BELOW_TEXT = 2,
	ABOVE_TEXT = 3,
	MAX_VALUE  = 2147483647,
}

/**
* Settable options for ghostty_kitty_graphics_placement_iterator_set().
*
* @ingroup kitty_graphics
*/
KittyGraphicsPlacementIteratorOption :: enum u32 {
	/**
	* Set the z-layer filter for the iterator.
	*
	* Input type: GhosttyKittyPlacementLayer *
	*/
	LAYER     = 0,
	MAX_VALUE = 2147483647,
}

/**
* Pixel format of a Kitty graphics image.
*
* @ingroup kitty_graphics
*/
KittyImageFormat :: enum u32 {
	RGB        = 0,
	RGBA       = 1,
	PNG        = 2,
	GRAY_ALPHA = 3,
	GRAY       = 4,
	MAX_VALUE  = 2147483647,
}

/**
* Compression of a Kitty graphics image.
*
* @ingroup kitty_graphics
*/
KittyImageCompression :: enum u32 {
	NONE         = 0,
	ZLIB_DEFLATE = 1,
	MAX_VALUE    = 2147483647,
}

/**
* Queryable data kinds for ghostty_kitty_graphics_image_get().
*
* @ingroup kitty_graphics
*/
KittyGraphicsImageData :: enum u32 {
	/** Invalid / sentinel value. */
	INVALID     = 0,

	/**
	* The image ID.
	*
	* Output type: uint32_t *
	*/
	ID          = 1,

	/**
	* The image number.
	*
	* Output type: uint32_t *
	*/
	NUMBER      = 2,

	/**
	* Image width in pixels.
	*
	* Output type: uint32_t *
	*/
	WIDTH       = 3,

	/**
	* Image height in pixels.
	*
	* Output type: uint32_t *
	*/
	HEIGHT      = 4,

	/**
	* Pixel format of the image.
	*
	* Output type: GhosttyKittyImageFormat *
	*/
	FORMAT      = 5,

	/**
	* Compression of the image.
	*
	* Output type: GhosttyKittyImageCompression *
	*/
	COMPRESSION = 6,

	/**
	* Borrowed pointer to the raw pixel data. Valid as long as the
	* underlying terminal is not mutated.
	*
	* Output type: const uint8_t **
	*/
	DATA_PTR    = 7,

	/**
	* Length of the raw pixel data in bytes.
	*
	* Output type: size_t *
	*/
	DATA_LEN    = 8,
	MAX_VALUE   = 2147483647,
}

/**
* Combined rendering geometry for a placement in a single sized struct.
*
* Combines the results of ghostty_kitty_graphics_placement_pixel_size(),
* ghostty_kitty_graphics_placement_grid_size(),
* ghostty_kitty_graphics_placement_viewport_pos(), and
* ghostty_kitty_graphics_placement_source_rect() into one call. This is
* an optimization over calling those four functions individually,
* particularly useful in environments with high per-call overhead such
* as FFI or Cgo.
*
* This struct uses the sized-struct ABI pattern. Initialize with
* GHOSTTY_INIT_SIZED(GhosttyKittyGraphicsPlacementRenderInfo) before calling
* ghostty_kitty_graphics_placement_render_info().
*
* @ingroup kitty_graphics
*/
KittyGraphicsPlacementRenderInfo :: struct {
	/** Size of this struct in bytes. Must be set to sizeof(GhosttyKittyGraphicsPlacementRenderInfo). */
	size: c.size_t,

	/** Rendered width in pixels. */
	pixel_width: u32,

	/** Rendered height in pixels. */
	pixel_height: u32,

	/** Number of grid columns the placement occupies. */
	grid_cols: u32,

	/** Number of grid rows the placement occupies. */
	grid_rows: u32,

	/** Viewport-relative column (may be negative for partially visible placements). */
	viewport_col: i32,

	/** Viewport-relative row (may be negative for partially visible placements). */
	viewport_row: i32,

	/** False when the placement is fully off-screen or virtual. */
	viewport_visible: bool,

	/** Resolved source rectangle x origin in pixels. */
	source_x: u32,

	/** Resolved source rectangle y origin in pixels. */
	source_y: u32,

	/** Resolved source rectangle width in pixels. */
	source_width: u32,

	/** Resolved source rectangle height in pixels. */
	source_height: u32,
}

@(default_calling_convention="c", link_prefix="ghostty_")
foreign lib {
	/**
	* Get data from a kitty graphics storage instance.
	*
	* The output pointer must be of the appropriate type for the requested
	* data kind.
	*
	* Returns GHOSTTY_NO_VALUE when Kitty graphics are disabled at build time.
	*
	* @param graphics The kitty graphics handle
	* @param data The type of data to extract
	* @param[out] out Pointer to store the extracted data
	* @return GHOSTTY_SUCCESS on success
	*
	* @ingroup kitty_graphics
	*/
	kitty_graphics_get :: proc(graphics: KittyGraphics, data: KittyGraphicsData, out: rawptr) -> Result ---

	/**
	* Look up a Kitty graphics image by its image ID.
	*
	* Returns NULL if no image with the given ID exists or if Kitty graphics
	* are disabled at build time.
	*
	* @param graphics The kitty graphics handle
	* @param image_id The image ID to look up
	* @return An opaque image handle, or NULL if not found
	*
	* @ingroup kitty_graphics
	*/
	kitty_graphics_image :: proc(graphics: KittyGraphics, image_id: u32) -> KittyGraphicsImage ---

	/**
	* Get data from a Kitty graphics image.
	*
	* The output pointer must be of the appropriate type for the requested
	* data kind.
	*
	* @param image The image handle (NULL returns GHOSTTY_INVALID_VALUE)
	* @param data The data kind to query
	* @param[out] out Pointer to receive the queried value
	* @return GHOSTTY_SUCCESS on success
	*
	* @ingroup kitty_graphics
	*/
	kitty_graphics_image_get :: proc(image: KittyGraphicsImage, data: KittyGraphicsImageData, out: rawptr) -> Result ---

	/**
	* Get multiple data fields from a Kitty graphics image in a single call.
	*
	* This is an optimization over calling ghostty_kitty_graphics_image_get()
	* repeatedly, particularly useful in environments with high per-call
	* overhead such as FFI or Cgo.
	*
	* Each element in the keys array specifies a data kind, and the
	* corresponding element in the values array receives the result.
	* The type of each values[i] pointer must match the output type
	* documented for keys[i].
	*
	* Processing stops at the first error; on success out_written
	* is set to count, on error it is set to the index of the
	* failing key (i.e. the number of values successfully written).
	*
	* @param image The image handle (NULL returns GHOSTTY_INVALID_VALUE)
	* @param count Number of key/value pairs
	* @param keys Array of data kinds to query
	* @param values Array of output pointers (types must match each key's
	*               documented output type)
	* @param[out] out_written On return, receives the number of values
	*             successfully written (may be NULL)
	* @return GHOSTTY_SUCCESS if all queries succeed
	*
	* @ingroup kitty_graphics
	*/
	kitty_graphics_image_get_multi :: proc(image: KittyGraphicsImage, count: c.size_t, keys: ^KittyGraphicsImageData, values: ^rawptr, out_written: ^c.size_t) -> Result ---

	/**
	* Create a new placement iterator instance.
	*
	* All fields except the allocator are left undefined until populated
	* via ghostty_kitty_graphics_get() with
	* GHOSTTY_KITTY_GRAPHICS_DATA_PLACEMENT_ITERATOR.
	*
	* @param allocator Pointer to allocator, or NULL to use the default allocator
	* @param[out] out_iterator On success, receives the created iterator handle
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_OUT_OF_MEMORY on allocation
	*         failure
	*
	* @ingroup kitty_graphics
	*/
	kitty_graphics_placement_iterator_new :: proc(allocator: ^Allocator, out_iterator: ^KittyGraphicsPlacementIterator) -> Result ---

	/**
	* Free a placement iterator.
	*
	* @param iterator The iterator handle to free (may be NULL)
	*
	* @ingroup kitty_graphics
	*/
	kitty_graphics_placement_iterator_free :: proc(iterator: KittyGraphicsPlacementIterator) ---

	/**
	* Set an option on a placement iterator.
	*
	* Use GHOSTTY_KITTY_GRAPHICS_PLACEMENT_ITERATOR_OPTION_LAYER with a
	* GhosttyKittyPlacementLayer value to filter placements by z-layer.
	* The filter is applied during iteration: ghostty_kitty_graphics_placement_next()
	* will skip placements that do not match the configured layer.
	*
	* The default layer is GHOSTTY_KITTY_PLACEMENT_LAYER_ALL (no filtering).
	*
	* @param iterator The iterator handle (NULL returns GHOSTTY_INVALID_VALUE)
	* @param option The option to set
	* @param value Pointer to the value (type depends on option; NULL returns
	*              GHOSTTY_INVALID_VALUE)
	* @return GHOSTTY_SUCCESS on success
	*
	* @ingroup kitty_graphics
	*/
	kitty_graphics_placement_iterator_set :: proc(iterator: KittyGraphicsPlacementIterator, option: KittyGraphicsPlacementIteratorOption, value: rawptr) -> Result ---

	/**
	* Advance the placement iterator to the next placement.
	*
	* If a layer filter has been set via
	* ghostty_kitty_graphics_placement_iterator_set(), only placements
	* matching that layer are returned.
	*
	* @param iterator The iterator handle (may be NULL)
	* @return true if advanced to the next placement, false if at the end
	*
	* @ingroup kitty_graphics
	*/
	kitty_graphics_placement_next :: proc(iterator: KittyGraphicsPlacementIterator) -> bool ---

	/**
	* Get data from the current placement in a placement iterator.
	*
	* Call ghostty_kitty_graphics_placement_next() at least once before
	* calling this function.
	*
	* @param iterator The iterator handle (NULL returns GHOSTTY_INVALID_VALUE)
	* @param data The data kind to query
	* @param[out] out Pointer to receive the queried value
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_INVALID_VALUE if the
	*         iterator is NULL or not positioned on a placement
	*
	* @ingroup kitty_graphics
	*/
	kitty_graphics_placement_get :: proc(iterator: KittyGraphicsPlacementIterator, data: KittyGraphicsPlacementData, out: rawptr) -> Result ---

	/**
	* Get multiple data fields from the current placement in a single call.
	*
	* This is an optimization over calling ghostty_kitty_graphics_placement_get()
	* repeatedly, particularly useful in environments with high per-call
	* overhead such as FFI or Cgo.
	*
	* Each element in the keys array specifies a data kind, and the
	* corresponding element in the values array receives the result.
	* The type of each values[i] pointer must match the output type
	* documented for keys[i].
	*
	* Processing stops at the first error; on success out_written
	* is set to count, on error it is set to the index of the
	* failing key (i.e. the number of values successfully written).
	*
	* @param iterator The iterator handle (NULL returns GHOSTTY_INVALID_VALUE)
	* @param count Number of key/value pairs
	* @param keys Array of data kinds to query
	* @param values Array of output pointers (types must match each key's
	*               documented output type)
	* @param[out] out_written On return, receives the number of values
	*             successfully written (may be NULL)
	* @return GHOSTTY_SUCCESS if all queries succeed
	*
	* @ingroup kitty_graphics
	*/
	kitty_graphics_placement_get_multi :: proc(iterator: KittyGraphicsPlacementIterator, count: c.size_t, keys: ^KittyGraphicsPlacementData, values: ^rawptr, out_written: ^c.size_t) -> Result ---

	/**
	* Compute the grid rectangle occupied by the current placement.
	*
	* Uses the placement's pin, the image dimensions, and the terminal's
	* cell/pixel geometry to calculate the bounding rectangle. Virtual
	* placements (unicode placeholders) return GHOSTTY_NO_VALUE.
	*
	* @param terminal The terminal handle
	* @param image The image handle for this placement's image
	* @param iterator The placement iterator positioned on a placement
	* @param[out] out_selection On success, receives the bounding rectangle
	*             as a selection with rectangle=true
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_INVALID_VALUE if any handle
	*         is NULL or the iterator is not positioned, GHOSTTY_NO_VALUE for
	*         virtual placements or when Kitty graphics are disabled
	*
	* @ingroup kitty_graphics
	*/
	kitty_graphics_placement_rect :: proc(iterator: KittyGraphicsPlacementIterator, image: KittyGraphicsImage, terminal: Terminal, out_selection: ^Selection) -> Result ---

	/**
	* Compute the rendered pixel size of the current placement.
	*
	* Takes into account the placement's source rectangle, specified
	* columns/rows, and aspect ratio to calculate the final rendered
	* pixel dimensions.
	*
	* @param iterator The placement iterator positioned on a placement
	* @param image The image handle for this placement's image
	* @param terminal The terminal handle
	* @param[out] out_width On success, receives the width in pixels
	* @param[out] out_height On success, receives the height in pixels
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_INVALID_VALUE if any handle
	*         is NULL or the iterator is not positioned, GHOSTTY_NO_VALUE when
	*         Kitty graphics are disabled
	*
	* @ingroup kitty_graphics
	*/
	kitty_graphics_placement_pixel_size :: proc(iterator: KittyGraphicsPlacementIterator, image: KittyGraphicsImage, terminal: Terminal, out_width: ^u32, out_height: ^u32) -> Result ---

	/**
	* Compute the grid cell size of the current placement.
	*
	* Returns the number of columns and rows that the placement occupies
	* in the terminal grid. If the placement specifies explicit columns
	* and rows, those are returned directly; otherwise they are calculated
	* from the pixel size and cell dimensions.
	*
	* @param iterator The placement iterator positioned on a placement
	* @param image The image handle for this placement's image
	* @param terminal The terminal handle
	* @param[out] out_cols On success, receives the number of columns
	* @param[out] out_rows On success, receives the number of rows
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_INVALID_VALUE if any handle
	*         is NULL or the iterator is not positioned, GHOSTTY_NO_VALUE when
	*         Kitty graphics are disabled
	*
	* @ingroup kitty_graphics
	*/
	kitty_graphics_placement_grid_size :: proc(iterator: KittyGraphicsPlacementIterator, image: KittyGraphicsImage, terminal: Terminal, out_cols: ^u32, out_rows: ^u32) -> Result ---

	/**
	* Get the viewport-relative grid position of the current placement.
	*
	* Converts the placement's internal pin to viewport-relative column and
	* row coordinates. The returned coordinates represent the top-left
	* corner of the placement in the viewport's grid coordinate space.
	*
	* The row value can be negative when the placement's origin has
	* scrolled above the top of the viewport. For example, a 4-row
	* image that has scrolled up by 2 rows returns row=-2, meaning
	* its top 2 rows are above the visible area but its bottom 2 rows
	* are still on screen. Embedders should use these coordinates
	* directly when computing the destination rectangle for rendering;
	* the embedder is responsible for clipping the portion of the image
	* that falls outside the viewport.
	*
	* Returns GHOSTTY_SUCCESS for any placement that is at least
	* partially visible in the viewport. Returns GHOSTTY_NO_VALUE when
	* the placement is completely outside the viewport (its bottom edge
	* is above the viewport or its top edge is at or below the last
	* viewport row), or when the placement is a virtual (unicode
	* placeholder) placement.
	*
	* @param iterator The placement iterator positioned on a placement
	* @param image The image handle for this placement's image
	* @param terminal The terminal handle
	* @param[out] out_col On success, receives the viewport-relative column
	* @param[out] out_row On success, receives the viewport-relative row
	*             (may be negative for partially visible placements)
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_NO_VALUE if fully
	*         off-screen or virtual, GHOSTTY_INVALID_VALUE if any handle
	*         is NULL or the iterator is not positioned
	*
	* @ingroup kitty_graphics
	*/
	kitty_graphics_placement_viewport_pos :: proc(iterator: KittyGraphicsPlacementIterator, image: KittyGraphicsImage, terminal: Terminal, out_col: ^i32, out_row: ^i32) -> Result ---

	/**
	* Get the resolved source rectangle for the current placement.
	*
	* Applies kitty protocol semantics: a width or height of 0 in the
	* placement means "use the full image dimension", and the resulting
	* rectangle is clamped to the actual image bounds. The returned
	* values are in pixels and are ready to use for texture sampling.
	*
	* @param iterator The placement iterator positioned on a placement
	* @param image The image handle for this placement's image
	* @param[out] out_x Source rect x origin in pixels
	* @param[out] out_y Source rect y origin in pixels
	* @param[out] out_width Source rect width in pixels
	* @param[out] out_height Source rect height in pixels
	* @return GHOSTTY_SUCCESS on success, GHOSTTY_INVALID_VALUE if any
	*         handle is NULL or the iterator is not positioned
	*
	* @ingroup kitty_graphics
	*/
	kitty_graphics_placement_source_rect :: proc(iterator: KittyGraphicsPlacementIterator, image: KittyGraphicsImage, out_x: ^u32, out_y: ^u32, out_width: ^u32, out_height: ^u32) -> Result ---

	/**
	* Get all rendering geometry for a placement in a single call.
	*
	* Combines pixel size, grid size, viewport position, and source
	* rectangle into one struct. Initialize with
	* GHOSTTY_INIT_SIZED(GhosttyKittyGraphicsPlacementRenderInfo).
	*
	* When viewport_visible is false, the placement is fully off-screen
	* or is a virtual placement; viewport_col and viewport_row may
	* contain meaningless values in that case.
	*
	* @param iterator The iterator positioned on a placement
	* @param image The image handle for this placement's image
	* @param terminal The terminal handle
	* @param[out] out_info Pointer to receive the rendering geometry
	* @return GHOSTTY_SUCCESS on success
	*
	* @ingroup kitty_graphics
	*/
	kitty_graphics_placement_render_info :: proc(iterator: KittyGraphicsPlacementIterator, image: KittyGraphicsImage, terminal: Terminal, out_info: ^KittyGraphicsPlacementRenderInfo) -> Result ---
}

