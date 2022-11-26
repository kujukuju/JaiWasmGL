#import "Basic";
#import "Compiler";
#import "BuildCpp";
#import "Process";
#import "File";
#import "File_Utilities";
#import "String";

build_wasm :: (base_name: string) {
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

    BC_NAME := tprint("%.bc", base_name);
    O_NAME := tprint("%.obj", base_name);

    WASM6432_FILE := ifx OS == .WINDOWS then "wasm64232.exe" else "wasm64232";
    WASM6432_NAME := tprint("../jai/3rd_party/%", WASM6432_FILE);

    // wasm stack is by default 64 kb so we should probably increase it
    // also javascript wont set the heap size to >= 64 kb by default
    // so subtract these values to get it extremely small, then add my own page to the heap in javascript
    // this way we can continue increasing the heap by pages without worrying about wasted memory
    STACK_SIZE :: 4194304 - 1024 * 12;

    // --stack-first will move the stack memory to the start of the array so if you ever go over
    // it will crash instead of starting to override globals in the adjacent memory
    cmd("clang", "--target=wasm64", "-nostdlib", "-o", O_NAME, "-c", BC_NAME);
    cmd("wasm-ld", "-m", "wasm64", "--no-entry", "--stack-first", "--export-all", "-z", tprint("stack-size=%", STACK_SIZE), "--allow-undefined", O_NAME, "-o", "./main64.wasm");
    cmd(WASM6432_NAME, "-o", "public/main32.wasm", "./main64.wasm");
}

Bindings :: #import,file "../module.jai";

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

prepare_object_file_for_build_wasm :: (w: Workspace) -> string {
    replacement_list: [..] *Code_Procedure_Header;

    #insert #run () -> string {
        replacements := compiler_get_nodes(code_of(Bindings.Replacements));
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
            
            append(*builder, tprint("array_add(*replacement_list, cast(*Code_Procedure_Header) compiler_get_nodes(code_of(Bindings.Replacements.%)));\n", member.name));
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
                            print("replaced body of %\n", body.header.name);
                            if replacement_body {
                                body.block.statements = replacement_body.block.statements;
                                compiler_modify_procedure(w, body);
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
                            // NOTE: #asm blocks are not translatable to WASM, we need to remove them
                            // compiler_report("ASM DETECTED!", make_location(it), .WARNING);
                            contains_asm = true;
                        }
                    }
                    if contains_asm {
                        body := it.expression;
                        compiler_report(tprint("Removing the body of %.", body.header.name), make_location(body), .WARNING);
                        new_statements: [..] *Code_Node;
                        body.block.statements = new_statements;
                        compiler_modify_procedure(w, body);
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

#run {
    workspace := compiler_create_workspace("Jai WASM");
    if !workspace {
        print("Error: Could not create a workspace\n");
        exit(1);
    }

    build_options := get_build_options(workspace);
    build_options.output_executable_name = "jaiwasm";
    build_options.llvm_options.output_bitcode = true;
    build_options.llvm_options.enable_split_modules = false;
    build_options.import_path = .["C:/jai/modules", #run tprint("%../../", #filepath)];
    set_build_options(build_options, workspace);

    compiler_begin_intercept(workspace);
    files := file_list(tprint("%src", #filepath), true);
    for file: files {
        if !ends_with(file, ".jai") {
            continue;
        }

        print("Build file: %\n", file);
        add_build_file(file, workspace);
    }

    object_file_to_translate_to_wasm := prepare_object_file_for_build_wasm(workspace);
    compiler_end_intercept(workspace);

    if object_file_to_translate_to_wasm.count > 0 {
        build_wasm(path_strip_extension(object_file_to_translate_to_wasm));
    } else {
        print("Could not generate the object file. Skipping WASM translation step...\n");
    }

    set_build_options_dc(.{do_output=false});
}
