
Replacements :: struct {
    // print_to_builder :: (builder : *String_Builder, format_string : string, args: .. Any) -> bool {
    //     implicit_index_cursor := 0;

    //     cursor := 0;
    //     printed := 0;
    //     while cursor < format_string.count {
    //         c := format_string.data[cursor];
    //         if c != #char "%" {
    //             cursor += 1;
    //             continue;
    //         }

    //         append(builder, format_string.data + printed, cursor - printed);
    //         cursor += 1;  // Skip the %.

    //         value := implicit_index_cursor; // Will get bumped below.

    //         if cursor < format_string.count {
    //             next := format_string.data[cursor];
    //             if next == #char "%" {  // Double-percent means to actually output a percent.
    //                 append(builder, "%");
    //                 cursor += 1;
    //                 printed = cursor;
    //                 continue;
    //             }

    //             if is_digit(next) {
    //                 if next == #char "0" {  // %00 outputs the empty string; %0 is like a regular %.
    //                     cursor += 1;
    //                     if (cursor < format_string.count) && (format_string.data[cursor] == #char "0") {
    //                         // Empty string.
    //                         cursor += 1;
    //                         printed = cursor;
    //                         continue;
    //                     } else {
    //                         // Fall through and do the thing.
    //                     }
    //                 } else {
    //                     // @Robustness: We probably want to test that parse_number does not overflow!
    //                     cursor, value = parse_number(format_string, cursor);
    //                     value -= 1;      // Arguments are 0-based indices from here on.
    //                 }
    //             }
    //         }

    //         if value < 0 {
    //             if context.print_style.log_runtime_errors {
    //                 log_error("Invalid negative %% index % in the format string at character %. Skipping.\n", value, cursor);
    //             }

    //             implicit_index_cursor = 0;
    //             printed = cursor;
    //             continue;
    //         }

    //         if value >= args.count {
    //             if context.print_style.log_runtime_errors {
    //                 do_free := false;
    //                 arguments_string := "(There are no insertable arguments.)";
    //                 if value == 1 {
    //                     arguments_string = "(There is only 1 insertable argument.)";
    //                 } else {
    //                     arguments_string = sprint("(There are only % insertable arguments.)", value);
    //                     do_free = true;
    //                 }
                    
    //                 log_error("Invalid %% index % in the format string \"%\" at character %. %\n", value+1, format_string, cursor, arguments_string);
    //                 if do_free free(arguments_string);
    //             }

    //             implicit_index_cursor = 0;
    //             printed = cursor;
    //             continue;
    //         }

    //         print_item_to_builder(builder, args[value], false);
    //         implicit_index_cursor = value + 1;

    //         printed = cursor;   // Next time we append, start here.
    //     }

    //     append(builder, format_string.data + printed, cursor - printed);

    //     if builder.failed return false;
    //     return true;
    // } @PrintLike

    // read_entire_file :: (name: string, zero_terminated := false, log_errors := true) -> string, bool {
    //     result: string;

    //     // can you load a file successfully with no data?
    //     read_entire_file_wasm(name.data, name.count, log_errors, *result.data, *result.count);
    //     view: [] u8;
    //     view.data = result.data;
    //     view.count = result.count;
    //     return result, !!result.data;
    // }

    // init_get_seconds :: () {
    //     get_seconds_base_time = get_unix_time_wasm();
    // }

    // seconds_since_init :: () -> float64 {
    //     if !is_get_seconds_initialized {
    //         is_get_seconds_initialized = true;
    //         init_get_seconds();
    //     }
        
    //     return cast(float64) (get_unix_time_wasm() - get_seconds_base_time) / 1000.0;
    // }

    alloc :: (size: s64) -> *void {
        return alloc_wasm(size);
    }

    free :: (memory: *void) {
        free_wasm(memory);
    }

    realloc :: (memory: *void, size: s64, old_size: s64) -> *void {
        return realloc_wasm(memory, size, old_size);
    }

    // write_builder :: (using builder: *String_Builder, do_reset := true, to_standard_error := false) -> s64 {
    //     //
    //     // Future expanded functionality: We can make a macro
    //     // that calls its argument code with a string representing
    //     // the contents of each bucket. Then you can do whatever
    //     // operation you want.
    //     //              -jblow, 19 July 2019
    //     //

    //     if !allocator.proc return 0;

    //     final: [..] u8;
    //     defer array_free(final);

    //     buffer  := get_base_buffer(builder);
    //     while buffer {
    //         s: string = ---;
    //         s.data  = get_buffer_data(buffer);
    //         s.count = buffer.count;

    //         string_bytes: [] u8;
    //         string_bytes.data = s.data;
    //         string_bytes.count = s.count;
    //         array_add(*final, ..string_bytes);

    //         buffer = buffer.next;
    //     }

    //     if do_reset reset(builder);

    //     wasm_write_string(final.count, final.data, to_standard_error);

    //     return final.count;
    // }

    // file_exists :: (file_path: string) -> bool {
    //     return file_exists_wasm(file_path.data, file_path.count);
    // }
}

#scope_file

is_get_seconds_initialized: bool;
get_seconds_base_time: u64;

#import "Basic";
#import "System";
