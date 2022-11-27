
wasm_configure_build_options :: (workspace: Workspace) -> Build_Options {
    build_options := get_build_options(workspace);
    build_options.output_executable_name = "jaiwasm";
    build_options.llvm_options.output_bitcode = true;
    build_options.llvm_options.enable_split_modules = false;

    return build_options;
}

wasm_replace_methods_and_generate_object :: (workspace: Workspace) -> string {
    replacement_list: [..] *Code_Procedure_Header;

    #insert #run () -> string {
        replacements := compiler_get_nodes(code_of(Replacements));
        assert(replacements.kind == .TYPE_DEFINITION);
        replacements_type_definition := cast(*Code_Type_Definition) replacements;
        replacements_type := replacements_type_definition.info;
        assert(replacements_type.type == .STRUCT);
        replacements_struct := cast(*Type_Info_Struct) replacements_type;

        builder: String_Builder;
        for i: 0..replacements_struct.members.count - 1 {
            member := replacements_struct.members[i];
            if member.offset_into_constant_storage == -1 {
                continue;
            }
            
            append(*builder, tprint("array_add(*replacement_list, cast(*Code_Procedure_Header) compiler_get_nodes(code_of(Replacements.%)));\n", member.name));
        }

        return builder_to_string(*builder);
    }();

    for replacement: replacement_list {
        assert(replacement.kind == .PROCEDURE_HEADER);
    }

    object_file_to_translate_to_wasm := "";
    while true {
        message := compiler_wait_for_message();
        if !message break;

        if message.kind == {
            case .TYPECHECKED;
                typechecked := cast(*Message_Typechecked) message;

                for typechecked.procedure_bodies {
                    body: *Code_Procedure_Body = it.expression;
                    if body.body_flags & .ALREADY_MODIFIED {
                        continue;
                    }

                    // if we can replace this with a replacement function then do it and continue
                    replaced_body := false;
                    for replacement_header: replacement_list {
                        if equals(body.header, replacement_header) {
                            replacement_body := replacement_header.body_or_null;
                            if replacement_body {
                                body.block.statements = replacement_body.block.statements;
                                compiler_modify_procedure(workspace, body);
                                replaced_body = true;
                                break;
                            }
                        }
                    }

                    if replaced_body {
                        continue;
                    }

                    contains_asm := false;
                    for it.subexpressions {
                        if it.kind == .ASM {
                            contains_asm = true;
                        }
                    }
                    if contains_asm {
                        body := it.expression;
                        compiler_report(tprint("Removing the body of %.", body.header.name), make_location(body), .WARNING);
                        new_statements: [..] *Code_Node;
                        body.block.statements = new_statements;
                        compiler_modify_procedure(workspace, body);
                    }
                }

            case .PHASE;
                phase := cast(*Message_Phase) message;
                if phase.phase == .POST_WRITE_EXECUTABLE {
                    assert(phase.compiler_generated_object_files.count == 1, "The build process supports only a single object file compilation");
                    assert(object_file_to_translate_to_wasm.count == 0, "The build process supports only a single object file compilation");
                    object_file_to_translate_to_wasm = phase.compiler_generated_object_files[0];
                }

            case .COMPLETE;
                break;
        }
    }

    return object_file_to_translate_to_wasm;
}

wasm_generate_compiled :: (workspace: Workspace, object_path: string) {
    if object_path.count > 0 {
        build_wasm(object_path);
    } else {
        print("Could not generate the object file. Skipping WASM translation step...\n");
    }

    set_build_options_dc(.{do_output=false});
}

#scope_file

STACK_SIZE :: 4194304 - 1024 * 12;

build_wasm :: (object_path: string, stack_size: int = STACK_SIZE) {
    cmd :: (args: .. string, redirect_stdout_to_file := "", loc := #caller_location) {
        log("[CMD] %\n", get_quoted_command_string(args));

        result, output_string, error_string := run_command(..args, capture_and_return_output = redirect_stdout_to_file != "");
        if result.exit_code {
            if output_string then log("%", output_string);
            if error_string then log("%", error_string);
            compiler_report(tprint("Command failed with exit code '%'.\n", result.exit_code), loc);
            exit(result.exit_code);
        }

        if redirect_stdout_to_file then write_entire_file(redirect_stdout_to_file, output_string);
    }

    bc_path := tprint("%.bc", path_strip_extension(object_path));

    wasm64232_file := ifx OS == .WINDOWS then "wasm64232.exe" else "wasm64232";
    wasm64232_name := tprint("%wasm64232/%", #filepath, wasm64232_file);

    // wasm stack is by default 64 kb so we should probably increase it
    // also javascript wont set the heap size to >= 64 kb by default
    // so subtract these values to get it extremely small, then add my own page to the heap in javascript
    // this way we can continue increasing the heap by pages without worrying about wasted memory

    // --stack-first will move the stack memory to the start of the array so if you ever go over
    // it will crash instead of starting to override globals in the adjacent memory

    // im not sure how to prevent linux from spitting out a ton of undefined symbol errors
    cmd("clang", "--target=wasm64", "-nostdlib", "-o", object_path, "-c", bc_path);
    cmd("wasm-ld", "-m", "wasm64", "--no-entry", "--stack-first", "--export-all", "-z", tprint("stack-size=%", stack_size), "--allow-undefined", object_path, "-o", "./main64.wasm");
    cmd(wasm64232_name, "-o", "public/main32.wasm", "./main64.wasm");
}

equals :: (h1: *Code_Procedure_Header, h2: *Code_Procedure_Header) -> bool {
    // TODO do this better matching argument and return types
    return h1.name == h2.name && equals(h1.arguments, h2.arguments) && equals(h1.returns, h2.returns);
}

equals :: (a: [] *Code_Declaration, b: [] *Code_Declaration) -> bool {
    if a.count != b.count {
        return false;
    }

    count := min(a.count, b.count);
    for i: 0..count - 1 {
        if a[i].kind != b[i].kind {
            return false;
        }

        if a[i].flags != b[i].flags {
            return false;
        }

        if a[i].name != b[i].name {
            return false;
        }

        // TODO check actual types and dont check names I guess
    }

    return true;
}

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

#import "Basic";
#import "Compiler";
#import "BuildCpp";
#import "Process";
#import "File";
#import "File_Utilities";
#import "String";