Basic :: #import "Basic";
using Basic;
#import "Compiler";
#import "BuildCpp";
#import "Process";
#import "File";
#import "File_Utilities";
#import "String";
#import "Process";

#import,file "../module.jai";
#load "../replacements.jai";
// #import,file "../plugin/wasm.jai";
// #import "Default_Metaprogram";
// #import "Metaprogram_Plugins";

// #import,file "../compiler.jai";

wasm64232_path :: #run () -> string {
    wasm64232_file := ifx OS == .WINDOWS then "wasm64232.exe" else "wasm64232";
    wasm64232_path := tprint("%/../wasm64232/%", #filepath, wasm64232_file);

    return wasm64232_path;
}();

replacement_list: [..] *Code_Procedure_Header;

// #run {
//     set_build_options_dc(.{do_output = false});

//     workspace := compiler_create_workspace("Jai Not WASM");
//     build_options := get_build_options(workspace);

//     import_paths: [..] string;
//     array_copy(*import_paths, build_options.import_path);
//     array_add(*import_paths, #run tprint("%../../", #filepath));
//     build_options.import_path = import_paths;
//     build_options.output_executable_name = "main";
    
//     set_build_options(build_options, workspace);

//     files := file_list(tprint("%src", #filepath), true);
//     for file: files {
//         if !ends_with(file, ".jai") {
//             continue;
//         }

//         print("Build file: %\n", file);
//         add_build_file(file, workspace);
//     }

//     set_working_directory(#filepath);
// }

#run {
    wasm := is_wasm();
    print("\nCompiling for wasm? %\n\n", wasm);

    if wasm {
        build_wasm();
    } else {
        build_exe();
    }
}

build_exe :: () {
    set_build_options_dc(.{do_output = false});

    workspace := compiler_create_workspace("Jai WASM");
    if !workspace {
        print("Error: Could not create a workspace\n");
        exit(1);
    }

    build_options := get_build_options(workspace);
    copy_commonly_propagated_fields(get_build_options(), *build_options);

    build_options.output_type = .EXECUTABLE;
    build_options.output_executable_name = "main";
    import_paths: [..] string;
    for existing_path: build_options.import_path {
        array_add(*import_paths, existing_path);
    }
    array_add(*import_paths, #run tprint("%../../", #filepath));
    build_options.import_path = import_paths;

    set_build_options(build_options, workspace);
    
    add_build_string("WASM :: false;", workspace);

    files := file_list(tprint("%src", #filepath), true);
    for file: files {
        if !ends_with(file, ".jai") {
            continue;
        }

        print("Build file: %\n", file);
        add_build_file(file, workspace);
    }

    set_working_directory(#filepath);
}

build_wasm :: () {
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
        assert(replacement.kind == .PROCEDURE_HEADER, "Replacement kind is %.\n", replacement.kind);
    }

    set_build_options_dc(.{do_output = false});

    workspace := compiler_create_workspace("Jai WASM");
    if !workspace {
        print("Error: Could not create a workspace\n");
        exit(1);
    }

    build_options := get_build_options(workspace);
    copy_commonly_propagated_fields(get_build_options(), *build_options);

    build_options.output_type                         = .EXECUTABLE;
    build_options.backend                             = .LLVM; // WASM only works with the LLVM backend, obviously.
    build_options.os_target                           = .WASM;
    build_options.cpu_target                          = .CUSTOM;
    build_options.emit_debug_info                     = .DWARF;
    build_options.backtrace_on_crash                  = .OFF; // Runtime_Support_Crash_Handler doesn’t support WASM (yet?)
    build_options.output_path                         = "public/";
    build_options.output_executable_name              = "main";
    build_options.use_custom_link_command             = true;
    build_options.lazy_foreign_function_lookups       = true;
    // build_options.dead_code_elimination               = .NONE;
    // this should work but it doesn't work with 64232
    // build_options.llvm_options.target_system_features = "+bulk-memory"; // "This options is needed so that "memcpy" and "memset" are mapped to "memory.copy" and "memory.fill" instructions in WASM.
    build_options.llvm_options.enable_split_modules   = false;
    build_options.llvm_options.function_sections      = true; // To get around "LLVM ERROR: section already has a defining function: .text"

    import_paths: [..] string;
    array_add(*import_paths, #run tprint("%../modules/", #filepath));
    for existing_path: build_options.import_path {
        array_add(*import_paths, existing_path);
    }
    array_add(*import_paths, #run tprint("%../../", #filepath));
    build_options.import_path = import_paths;

    print("import path: %\n", build_options.import_path);

    STACK_SIZE :: 4194304 - 1024 * 12;
    build_options.additional_linker_arguments = .["--stack-first", "-z", tprint("stack-size=%", STACK_SIZE)];

    set_build_options(build_options, workspace);

    intercept_flags: Intercept_Flags;
    compiler_begin_intercept(workspace, intercept_flags);
    
    add_build_string("WASM :: true;", workspace);

    files := file_list(tprint("%src", #filepath), true);
    for file: files {
        if !ends_with(file, ".jai") {
            continue;
        }

        print("Build file: %\n", file);
        add_build_file(file, workspace);
    }

    while true {
        message := compiler_wait_for_message();

        on_message(workspace, message);

        if message.kind == .COMPLETE break;
    }

    compiler_end_intercept(workspace);

    set_working_directory(#filepath);
}

is_wasm :: () -> bool {
    args := get_build_options().compile_time_command_line;

    for args {
        if it == "wasm" {
            return true;
        }
    }

    return false;
}

#scope_file

on_message :: (workspace: Workspace, message: *Message) {
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

                for replacement_header: replacement_list {
                    if equals(body.header, replacement_header) {
                        replacement_body := replacement_header.body_or_null;
                        if replacement_body {
                            body.block.statements = replacement_body.block.statements;
                            compiler_modify_procedure(workspace, body);
                            break;
                        }
                    }
                }
            }

        case .PHASE;
            phase := cast(*Message_Phase) message;

            if phase.phase == .READY_FOR_CUSTOM_LINK_COMMAND {
                o := get_build_options(workspace);

                object_path := phase.compiler_generated_object_files[0];

                wasm64_file_path := tprint("%1/%2%0064.wasm", path_strip_filename(object_path), o.output_executable_name);
                wasm32_file_path := tprint("%1/public/%2%0032.wasm", get_working_directory(), o.output_executable_name);

                // TODO do I actually watn stdlib now?
                // cmd("wasm-ld", "-flavor", "wasm", "-m", "wasm64", "--no-entry", "--stack-first", "--export-all", "-z", "stack-size=4182016", "--allow-undefined", object_path, "-o", wasm64_file_path);
                cmd("lld", "-flavor", "wasm", "-mwasm64", "--no-entry", "--export-dynamic", "--export-all", "--import-undefined", object_path, "-o", wasm64_file_path, "--stack-first", "-z", "stack-size=4182016");
                cmd(wasm64232_path, "-o", wasm32_file_path, wasm64_file_path);
                compiler_custom_link_command_is_complete(workspace);
            }
    }
}

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
