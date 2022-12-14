
set_context :: (c: *Context) #foreign #compiler;
read_entire_file_wasm :: (name_data: *u8, name_count: int, log_errors: bool, data: **u8, count: *int) #foreign #compiler;

#scope_file

File :: #import "File";
#poke_name File read_entire_file_wasm;