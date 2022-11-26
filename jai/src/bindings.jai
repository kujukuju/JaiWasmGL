
set_context :: (c: *Context) #foreign #compiler;

Replacements :: struct {
    #import "Basic";

    print_to_builder :: (builder : *String_Builder, format_string : string, args: .. Any) -> bool {
        implicit_index_cursor := 0;

        cursor := 0;
        printed := 0;
        while cursor < format_string.count {
            c := format_string.data[cursor];
            if c != #char "%" {
                cursor += 1;
                continue;
            }

            append(builder, format_string.data + printed, cursor - printed);
            cursor += 1;  // Skip the %.

            value := implicit_index_cursor; // Will get bumped below.

            if cursor < format_string.count {
                next := format_string.data[cursor];
                if next == #char "%" {  // Double-percent means to actually output a percent.
                    append(builder, "%");
                    cursor += 1;
                    printed = cursor;
                    continue;
                }

                if is_digit(next) {
                    if next == #char "0" {  // %00 outputs the empty string; %0 is like a regular %.
                        cursor += 1;
                        if (cursor < format_string.count) && (format_string.data[cursor] == #char "0") {
                            // Empty string.
                            cursor += 1;
                            printed = cursor;
                            continue;
                        } else {
                            // Fall through and do the thing.
                        }
                    } else {
                        // @Robustness: We probably want to test that parse_number does not overflow!
                        cursor, value = parse_number(format_string, cursor);
                        value -= 1;      // Arguments are 0-based indices from here on.
                    }
                }
            }

            if value < 0 {
                if context.print_style.log_runtime_errors {
                    log_error("Invalid negative %% index % in the format string at character %. Skipping.\n", value, cursor);
                }

                implicit_index_cursor = 0;
                printed = cursor;
                continue;
            }

            if value >= args.count {
                if context.print_style.log_runtime_errors {
                    do_free := false;
                    arguments_string := "(There are no insertable arguments.)";
                    if value == 1 {
                        arguments_string = "(There is only 1 insertable argument.)";
                    } else {
                        arguments_string = sprint("(There are only % insertable arguments.)", value);
                        do_free = true;
                    }
                    
                    log_error("Invalid %% index % in the format string \"%\" at character %. %\n", value+1, format_string, cursor, arguments_string);
                    if do_free free(arguments_string);
                }

                implicit_index_cursor = 0;
                printed = cursor;
                continue;
            }

            print_item_to_builder(builder, args[value], false);
            implicit_index_cursor = value + 1;

            printed = cursor;   // Next time we append, start here.
        }

        append(builder, format_string.data + printed, cursor - printed);

        if builder.failed return false;
        return true;
    } @PrintLike
}
