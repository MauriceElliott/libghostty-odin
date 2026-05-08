/**
 * @file allocator.h
 *
 * Memory management interface for libghostty-vt.
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
* Function table for custom memory allocator operations.
*
* This vtable defines the interface for a custom memory allocator. All
* function pointers must be valid and non-NULL.
*
* @ingroup allocator
*
* If you're not going to use a custom allocator, you can ignore all of
* this. All functions that take an allocator pointer allow NULL to use a
* default allocator.
*
* The interface is based on the Zig allocator interface. I'll say up front
* that it is easy to look at this interface and think "wow, this is really
* overcomplicated". The reason for this complexity is well thought out by
* the Zig folks, and it enables a diverse set of allocation strategies
* as shown by the Zig ecosystem. As a consolation, please note that many
* of the arguments are only needed for advanced use cases and can be
* safely ignored in simple implementations. For example, if you look at
* the Zig implementation of the libc allocator in `lib/std/heap.zig`
* (search for CAllocator), you'll see it is very simple.
*
* We chose to align with the Zig allocator interface because:
*
*   1. It is a proven interface that serves a wide variety of use cases
*      in the real world via the Zig ecosystem. It's shown to work.
*
*   2. Our core implementation itself is Zig, and this lets us very
*      cheaply and easily convert between C and Zig allocators.
*
* NOTE(mitchellh): In the future, we can have default implementations of
* resize/remap and allow those to be null.
*/
AllocatorVtable :: struct {
	/**
	* Return a pointer to `len` bytes with specified `alignment`, or return
	* `NULL` indicating the allocation failed.
	*
	* @param ctx The allocator context
	* @param len Number of bytes to allocate
	* @param alignment Required alignment for the allocation. Guaranteed to
	*   be a power of two between 1 and 16 inclusive.
	* @param ret_addr First return address of the allocation call stack (0 if not provided)
	* @return Pointer to allocated memory, or NULL if allocation failed
	*/
	alloc: proc "c" (ctx: rawptr, len: c.size_t, alignment: u8, ret_addr: c.uintptr_t) -> rawptr,

	/**
	* Attempt to expand or shrink memory in place.
	*
	* `memory_len` must equal the length requested from the most recent
	* successful call to `alloc`, `resize`, or `remap`. `alignment` must
	* equal the same value that was passed as the `alignment` parameter to
	* the original `alloc` call.
	*
	* `new_len` must be greater than zero.
	*
	* @param ctx The allocator context
	* @param memory Pointer to the memory block to resize
	* @param memory_len Current size of the memory block
	* @param alignment Alignment (must match original allocation)
	* @param new_len New requested size
	* @param ret_addr First return address of the allocation call stack (0 if not provided)
	* @return true if resize was successful in-place, false if relocation would be required
	*/
	resize: proc "c" (ctx: rawptr, memory: rawptr, memory_len: c.size_t, alignment: u8, new_len: c.size_t, ret_addr: c.uintptr_t) -> bool,

	/**
	* Attempt to expand or shrink memory, allowing relocation.
	*
	* `memory_len` must equal the length requested from the most recent
	* successful call to `alloc`, `resize`, or `remap`. `alignment` must
	* equal the same value that was passed as the `alignment` parameter to
	* the original `alloc` call.
	*
	* A non-`NULL` return value indicates the resize was successful. The
	* allocation may have same address, or may have been relocated. In either
	* case, the allocation now has size of `new_len`. A `NULL` return value
	* indicates that the resize would be equivalent to allocating new memory,
	* copying the bytes from the old memory, and then freeing the old memory.
	* In such case, it is more efficient for the caller to perform the copy.
	*
	* `new_len` must be greater than zero.
	*
	* @param ctx The allocator context
	* @param memory Pointer to the memory block to remap
	* @param memory_len Current size of the memory block
	* @param alignment Alignment (must match original allocation)
	* @param new_len New requested size
	* @param ret_addr First return address of the allocation call stack (0 if not provided)
	* @return Pointer to resized memory (may be relocated), or NULL if manual copy is needed
	*/
	remap: proc "c" (ctx: rawptr, memory: rawptr, memory_len: c.size_t, alignment: u8, new_len: c.size_t, ret_addr: c.uintptr_t) -> rawptr,

	/**
	* Free and invalidate a region of memory.
	*
	* `memory_len` must equal the length requested from the most recent
	* successful call to `alloc`, `resize`, or `remap`. `alignment` must
	* equal the same value that was passed as the `alignment` parameter to
	* the original `alloc` call.
	*
	* @param ctx The allocator context
	* @param memory Pointer to the memory block to free
	* @param memory_len Size of the memory block
	* @param alignment Alignment (must match original allocation)
	* @param ret_addr First return address of the allocation call stack (0 if not provided)
	*/
	free: proc "c" (ctx: rawptr, memory: rawptr, memory_len: c.size_t, alignment: u8, ret_addr: c.uintptr_t),
}

/**
* Custom memory allocator.
*
* For functions that take an allocator pointer, a NULL pointer indicates
* that the default allocator should be used. The default allocator will
* be libc malloc/free if we're linking to libc. If libc isn't linked,
* a custom allocator is used (currently Zig's SMP allocator).
*
* @ingroup allocator
*
* Usage example:
* @code
* GhosttyAllocator allocator = {
*     .vtable = &my_allocator_vtable,
*     .ctx = my_allocator_state
* };
* @endcode
*/
Allocator :: struct {
	/**
	* Opaque context pointer passed to all vtable functions.
	* This allows the allocator implementation to maintain state
	* or reference external resources needed for memory management.
	*/
	ctx: rawptr,

	/**
	* Pointer to the allocator's vtable containing function pointers
	* for memory operations (alloc, resize, remap, free).
	*/
	vtable: ^AllocatorVtable,
}

@(default_calling_convention="c", link_prefix="ghostty_")
foreign lib {
	/**
	* Allocate a buffer of `len` bytes.
	*
	* Uses the provided allocator, or the default allocator if NULL is passed.
	* The returned buffer must be freed with ghostty_free() using the same
	* allocator.
	*
	* @param allocator Pointer to the allocator to use, or NULL for the default
	* @param len Number of bytes to allocate
	* @return Pointer to the allocated buffer, or NULL if allocation failed
	*
	* @ingroup allocator
	*/
	alloc :: proc(allocator: ^Allocator, len: c.size_t) -> ^u8 ---

	/**
	* Free memory that was allocated by a libghostty-vt function.
	*
	* Use this to free buffers returned by functions such as
	* ghostty_formatter_format_alloc(). Pass the same allocator that was
	* used for the allocation, or NULL if the default allocator was used.
	*
	* On platforms where the library's internal allocator differs from the
	* consumer's C runtime (e.g. Windows, where Zig's libc and MSVC's CRT
	* maintain separate heaps), calling the standard C free() on memory
	* allocated by the library causes undefined behavior. This function
	* guarantees the correct allocator is used regardless of platform.
	*
	* It is safe to pass a NULL pointer; the call is a no-op in that case.
	*
	* @param allocator Pointer to the allocator that was used to allocate the
	*   memory, or NULL if the default allocator was used
	* @param ptr Pointer to the memory to free (may be NULL)
	* @param len Length of the allocation in bytes (must match the original
	*   allocation size)
	*
	* @ingroup allocator
	*/
	free :: proc(allocator: ^Allocator, ptr: ^u8, len: c.size_t) ---
}

