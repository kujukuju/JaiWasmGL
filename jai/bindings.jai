
// set_context :: (c: *Context) #runtime_support;
// read_entire_file_wasm :: (name_data: *u8, name_count: int, log_errors: bool, data: **u8, count: *int) #runtime_support;
// file_exists_wasm :: (name_data: *u8, name_count: int) -> bool #runtime_support;
// init_time_wasm :: () #runtime_support;
// get_time_wasm :: () -> u64 #runtime_support;

// #scope_file

// File :: #import "File";
// #poke_name File read_entire_file_wasm;

// File_Utilities :: #import "File_Utilities";
// #poke_name File_Utilities file_exists_wasm;

// Basic :: #import "Basic";
// #poke_name Basic init_time_wasm;
// #poke_name Basic get_time_wasm;