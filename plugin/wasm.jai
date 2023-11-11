
#import "Basic";
#import "Compiler";
#import "String";
#import "Process";
#import "File";
#import "File_Utilities";

wasm64232_path :: #run () -> string {
    wasm64232_file := ifx OS == .WINDOWS then "wasm64232.exe" else "wasm64232";
    wasm64232_path := tprint("%/../wasm64232/%", #filepath, wasm64232_file);

    return wasm64232_path;
}();

stack_size :: 4194304 - 1024 * 12;

replacement_list: [..] *Code_Procedure_Header;

get_plugin :: () -> *Metaprogram_Plugin {
    p := New(Metaprogram_Plugin);

    p.message = message;
    p.shutdown = shutdown;
    // p.add_source = add_source;
    p.before_intercept = before_intercept;
    p.finish = finish;

    return p;
}

use_plugin_first :: (w: Workspace, plugin: *Metaprogram_Plugin) {
    plugin.workspace = w;

    intercept_flags: Intercept_Flags;

    if plugin.before_intercept plugin.before_intercept(plugin, *intercept_flags);
    
    compiler_begin_intercept(w, intercept_flags);

    if plugin.add_source plugin.add_source(plugin);
}

use_plugin_last :: (plugin: *Metaprogram_Plugin) {
    if plugin.message {
        while true {
            message := compiler_wait_for_message();

            plugin.message(plugin, message);

            if message.kind == .COMPLETE break;
        }
    }

    compiler_end_intercept(plugin.workspace);

    if plugin.finish plugin.finish(plugin);
    if plugin.shutdown plugin.shutdown(plugin);
}

add_source :: (p: *Metaprogram_Plugin) {
    add_build_string("WASM :: #library \"WASM\";", p.workspace);
}

before_intercept :: (p: *Metaprogram_Plugin, flags: *Intercept_Flags) {
    options := get_build_options(p.workspace);

    options.llvm_options.enable_split_modules = false;
    options.llvm_options.function_sections = true;
    options.llvm_options.target_system_triple = "wasm64-unknown-unknown";
    // options.llvm_options.output_bitcode = true;
    options.use_custom_link_command = true;
    options.output_type = .DYNAMIC_LIBRARY;
    // options.output_type = .OBJECT_FILE;
    // options.output_type = .NO_OUTPUT;
    options.lazy_foreign_function_lookups = true;

    set_build_options(options, p.workspace);

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
}

message :: (p: *Metaprogram_Plugin, message: *Message) {
    if message.kind == {
        case .TYPECHECKED;
            typechecked := cast(*Message_Typechecked) message;

            for typechecked.procedure_bodies {
                body: *Code_Procedure_Body = it.expression;
                if body.body_flags & .ALREADY_MODIFIED {
                    continue;
                }

                // don't replace things inside bindings
                if ends_with(body.header.location.enclosing_load.fully_pathed_filename, "bindings.jai") {
                    continue;
                }

                replaced_body := false;
                for replacement_header: replacement_list {
                    if equals(body.header, replacement_header) {
                        replacement_body := replacement_header.body_or_null;
                        if replacement_body {
                            body.block.statements = replacement_body.block.statements;
                            compiler_modify_procedure(p.workspace, body);
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
                    compiler_modify_procedure(p.workspace, body);
                }
            }

        case .PHASE;
            phase := cast(*Message_Phase) message;

            if phase.phase == .READY_FOR_CUSTOM_LINK_COMMAND {
                o := get_build_options(p.workspace);

                object_path := phase.compiler_generated_object_files[0];
                // bc_path := tprint("%.bc", path_strip_extension(object_path));

                wasm64_file_path := tprint("%1/%2%0064.wasm", path_strip_filename(object_path), o.output_executable_name);
                wasm32_file_path := tprint("%1/public/%2%0032.wasm", get_working_directory(), o.output_executable_name);

                // TODO do I actually watn stdlib now?
                // cmd("clang", "--target=wasm64", "-nostdlib", "-o", object_path, "-c", bc_path);
                cmd("wasm-ld", "-m", "wasm64", "--no-entry", "--stack-first", "--export-all", "-z", tprint("stack-size=%", stack_size), "--allow-undefined", object_path, "-o", wasm64_file_path);
                cmd(wasm64232_path, "-o", wasm32_file_path, wasm64_file_path);
                compiler_custom_link_command_is_complete(p.workspace);
            }

        case .COMPLETE;
            return;
    }
}

finish :: (p: *Metaprogram_Plugin) {
    
}

shutdown :: (p: *Metaprogram_Plugin) {
    free(p);
}

#scope_file

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

        if a[i].name != b[i].name {
            return false;
        }

        // TODO check actual types and dont check names I guess
    }

    return true;
}

Replacements :: struct {
    #import "Basic";
    #import "GL";
    #import,file "./jai/bindings.jai";

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

    read_entire_file :: (name: string, zero_terminated := false, log_errors := true) -> string, bool {
        result: string;

        // can you load a file successfully with no data?
        read_entire_file_wasm(name.data, name.count, log_errors, *result.data, *result.count);
        view: [] u8;
        view.data = result.data;
        view.count = result.count;
        return result, !!result.data;
    }

    init_time :: () {
        init_time_wasm();
    }

    get_time :: () -> float64 {
        unix_ish := get_time_wasm();
        return cast(float64) unix_ish / 1000.0;
    }

    file_exists :: (file_path: string) -> bool {
        return file_exists_wasm(file_path.data, file_path.count);
    }

    write_string_unsynchronized :: (s: string, to_standard_error := false) #no_context {
        WASM :: #library "WASM";
        WriteFile :: (handle: *void, buffer: *void, buffer_length: u32, written_result: *u32, overlapped: *void) -> s32 #foreign WASM;

        written: u32;
        // TODO eventually support stderror
        status := WriteFile(null, s.data, cast(u32) s.count, *written, null);
    }

    // heap_alloc :: (heap: *Heap, size: s64) -> *void {
    //     return alloc_wasm(heap, size);
    // }

    // heap_realloc :: (heap: *Heap, ptr: *void, size: s64) -> *void {
    //     return realloc_wasm(heap, ptr, size);
    // }

    // heap_free :: (heap: *Heap, ptr: *void) {
    //     free_wasm(heap, ptr);
    // }
}

