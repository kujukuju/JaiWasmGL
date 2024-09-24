
// file_write :: inline (file: *File, data: string) -> bool {
//     return file_write(file, data.data, data.count);
// }

// file_write :: (file: *File, builder: *String_Builder, do_reset := true) -> bool #foreign;

write_entire_file :: inline (name: string, data: string) -> bool {
    return write_entire_file(name, data.data, data.count);
}

write_entire_file :: (name: string, data: *void, count: int) -> bool #foreign;

// write_entire_file :: (name: string, builder: *String_Builder, do_reset := true) -> bool {
//     file, success := file_open(name, for_writing=true, keep_existing_content=false);
//     if !success {
//         if do_reset reset(builder);
//         return false;
//     }

//     defer file_close(*file);

//     return file_write(*file, builder, do_reset);
// }

read_entire_file :: (name: string, zero_terminated := false, log_errors := true) -> string, bool {
    result: string;

    // can you load a file successfully with no data?
    read_entire_file_wasm(name.data, name.count, log_errors, *result.data, *result.count);
    view: [] u8;
    view.data = result.data;
    view.count = result.count;
    return result, !!result.data;
}

// USE_MAP_FILE :: (OS == .WINDOWS);
// STORE_MAPPED_FILENAMES :: false;

// Map_File_Info :: struct {
//     data: string;
//     #if STORE_MAPPED_FILENAMES {
//         filename: string;
//     }
//     #if USE_MAP_FILE {
//         map_info: File_Map_Info;
//     }
// }

// string_to_map_file_info :: (data: string) -> Map_File_Info {
//     file_info: Map_File_Info;
//     file_info.data = data;
//     return file_info;
// }

// map_entire_file_start :: (name: string, log_errors := true) -> Map_File_Info, bool {
//     file_info: Map_File_Info;

// #if USE_MAP_FILE {
//     map_info, ret := map_file(name, log_errors);
//     if (ret) {
//         file_info.data = map_info.data;
//         #if STORE_MAPPED_FILENAMES {
//             file_info.filename = copy_string(name);
//         }
//         file_info.map_info = map_info;
//         return file_info, true;
//     }
// } else {
//     data, ret := read_entire_file(name, false, log_errors);
//     if (ret) {
//         file_info.data = data;
//         #if STORE_MAPPED_FILENAMES {
//             file_info.filename = copy_string(name);
//         }
//         return file_info, true;
//     }
// }

//     return .{}, false;
// }

// map_entire_file_end :: (file_info: *Map_File_Info) {
//     free_data := true;

//     #if USE_MAP_FILE {
//         free_data = !munmap_file(*file_info.map_info);
//     }

//     if (free_data) {
//         free(file_info.data);
//     }
//     file_info.data = "";

//     #if STORE_MAPPED_FILENAMES {
//         if (file_info.filename) {
//             free(file_info.filename);
//             file_info.filename = "";
//         }
//     }
// }

// // We could add here a read_entire_file_chunked that returns a String_Builder, with bucket
// // size equal to some parameter. Maybe that parameter could even be a String_Builder if we
// // make that be a

// // read_entire_file_chunked :: (name: string, $chunk_size: s64) -> Chunk_List(chunk_size), bool { ... }

// make_directory_if_it_does_not_exist :: (name: string, recursive := false) -> directory_now_exists: bool {
//     if recursive {
//         start_index := 0;
//         if name && name[0] == #char "/" start_index = 1;

//         index := find_index_from_left(name, #char "/", start_index);
//         #if OS == .WINDOWS {
//             if index == -1 {
//                 index = find_index_from_left(name, #char "\\");
//             }
//         }
//         while index != -1 {
//             success := os_make_directory_if_it_does_not_exist(slice(name, 0, index));
//             if !success return false;
//             start_index = index + 1;
//             index = find_index_from_left(name, #char "/", start_index);
//             #if OS == .WINDOWS {
//                 if index == -1 {
//                     index = find_index_from_left(name, #char "\\", start_index);
//                 }
//             }
//         }
//         if start_index == name.count - 1 {
//             // We already created the innermost directory
//             return true;
//         }
//     }

//     return os_make_directory_if_it_does_not_exist(name);
// }

// // Converts a relative path to an absolute one.
// // The return value is allocated using the temporary allocator.
// //
// // The unix version of this function fails if the path does not exist.
// // The Windows version does not fail for non-existing files.
// // I haven’t found a way around this.
// // -rluba, 2023-01-09
// get_absolute_path :: inline (relative_path: string) -> string, success: bool {
//     #if OS == .WINDOWS {
//         absolute_path, success := get_absolute_path_windows(relative_path);
//     } else {
//         absolute_path, success := get_absolute_path_unix(relative_path);
//     }
//     return absolute_path, success;
// }

#scope_module

// Seek_Type :: enum {
//     START     :: 0;
//     CURRENT   :: 1;
//     END       :: 2;
// }

#import "Basic";
#import "String";
