
set_context :: (c: *Context) #foreign;
read_entire_file_wasm :: (name_data: *u8, name_count: int, log_errors: bool, data: **u8, count: *int) #foreign;
file_exists_wasm :: (name_data: *u8, name_count: int) -> bool #foreign;
init_time_wasm :: () #foreign;
get_time_wasm :: () -> u64 #foreign;
alloc_wasm :: (heap: *Heap, size: s64) -> *void #foreign;
realloc_wasm :: (heap: *Heap, ptr: *void, size: s64) -> *void #foreign;
free_wasm :: (heap: *Heap, ptr: *void) #foreign;

Heap :: struct {}

#scope_file

File :: #import "File";
#poke_name File read_entire_file_wasm;

File_Utilities :: #import "File_Utilities";
#poke_name File_Utilities file_exists_wasm;

Basic :: #import "Basic";
#poke_name Basic init_time_wasm;
#poke_name Basic get_time_wasm;

Default_Allocator :: #import "Default_Allocator";
#poke_name Default_Allocator alloc_wasm;
#poke_name Default_Allocator realloc_wasm;
#poke_name Default_Allocator free_wasm;
