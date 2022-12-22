
set_context :: (c: *Context) #foreign #compiler;
read_entire_file_wasm :: (name_data: *u8, name_count: int, log_errors: bool, data: **u8, count: *int) #foreign #compiler;
file_exists_wasm :: (name_data: *u8, name_count: int) -> bool #foreign #compiler;
init_time_wasm :: () #foreign #compiler;
get_time_wasm :: () -> u64 #foreign #compiler;

#scope_file

File :: #import "File";
#poke_name File read_entire_file_wasm;

File_Utilities :: #import "File_Utilities";
#poke_name File_Utilities file_exists_wasm;

Basic :: #import "Basic";
#poke_name Basic init_time_wasm;
#poke_name Basic get_time_wasm;