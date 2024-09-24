
set_context :: (c: *Context) #foreign;
read_entire_file_wasm :: (name_data: *u8, name_count: int, log_errors: bool, data: **u8, count: *int) #foreign;
file_exists_wasm :: (name_data: *u8, name_count: int) -> bool #foreign;
get_unix_time_wasm :: () -> u64 #foreign;
alloc_wasm :: (size: s64) -> *void #foreign;
realloc_wasm :: (memory: *void, size: s64, old_size: s64) -> *void #foreign;
free_wasm :: (memory: *void) #foreign;
// wasm_write_string :: (count: s64, data: *void, to_standard_error: bool) #foreign;

#scope_file

Basic :: #import "Basic";
#poke_name Basic get_unix_time_wasm;
#poke_name Basic alloc_wasm;
#poke_name Basic realloc_wasm;
#poke_name Basic free_wasm;
// #poke_name Basic wasm_write_string;

File :: #import "File";
#poke_name File read_entire_file_wasm;
#poke_name File file_exists_wasm;

// Default_Allocator :: #import "Default_Allocator";
// #poke_name Default_Allocator alloc_wasm;
// #poke_name Default_Allocator realloc_wasm;
// #poke_name Default_Allocator free_wasm;
