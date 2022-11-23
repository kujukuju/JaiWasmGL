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
    WASM6432_NAME := tprint("./3rd_party/%", WASM6432_FILE);

    cmd("clang", "--target=wasm64", "-o", O_NAME, "-c", BC_NAME);
    cmd("wasm-ld", "-m", "wasm64", "--no-entry", "--export-all", "--allow-undefined", O_NAME, "-o", "./wasm/main64.wasm");
    cmd(WASM6432_NAME, "-o", "../public/wasm/main32.wasm", "./wasm/main64.wasm");
}

Bindings :: #import,file "src/bindings.jai";

equals :: (h1: *Code_Procedure_Header, h2: *Code_Procedure_Header) -> bool {
    // TODO do this better matching argument and return types
    return h1.name == h2.name && equals(h1.arguments, h2.arguments) && equals(h1.returns, h2.returns);
}

equals :: (a: [] *Code_Declaration, b: [] *Code_Declaration) -> bool {
    // I can't check the parameter count, because overriding the print method requires that .. args is the last parameter
    // if a.count != b.count {
    //     return false;
    // }

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
        // TODO although it might be necessary to keep names for the purpose of the body still working, but im not sure
        // print("% %\n", a[i].name, b[i].name);
        // if a[i].expression {
        //     print("%\n%\n\n", << a[i].expression, << b[i].expression);
        // }
    }

    return true;
}

prepare_object_file_for_build_wasm :: (w: Workspace) -> string {
    alloc_code := code_of(Bindings.Replacements.print);
    alloc_root := compiler_get_nodes(alloc_code);
    assert(alloc_root.kind == .PROCEDURE_HEADER);
    alloc_header := cast(*Code_Procedure_Header) alloc_root;

    print("header %\n", << alloc_header);
    print("body %\n", alloc_header.body_or_null);

    object_file_to_translate_to_wasm := "";
    while true {
        message := compiler_wait_for_message();
        if !message break;

        if message.kind == {
            case .TYPECHECKED; {
                typechecked := cast(*Message_Typechecked) message;

                // for typechecked.declarations {
                //     expression: *Code_Node = it.expression.expression;
                //     if !expression {
                //         continue;
                //     }
                //     if expression.kind != .PROCEDURE_HEADER {
                //         // if expression.kind == .TYPE_DEFINITION {
                //         //     print("TYPE_DEFINITION %\n", << cast(*Code_Type_Definition) expression);
                //         // }
                //         // if expression.kind == .DECLARATION {
                //         //     print("DECLARATION %\n", << cast(*Code_Declaration) expression);
                //         // }
                //         continue;
                //     }
                //     header := cast(*Code_Procedure_Header) expression;

                //     if header.name == "print" {
                //         print("modifying print\n");
                //     }
                //     if equals(header, alloc_header) {
                //         print("really modifying print\n");
                //         print("real header %\n", << it.expression);

                //         if header.body_or_null {
                //             new_statements: [..] *Code_Node;
                //             header.body_or_null.block.statements = new_statements;
                //             compiler_modify_procedure(w, header.body_or_null);
                //         }

                //         // TODO do I need to override parameters?
                //         // header.constants_block = alloc_header.constants_block;
                //         header.arguments = array_copy(alloc_header.arguments);
                //         header.returns = array_copy(alloc_header.returns);
                //         header.parameter_usings = array_copy(alloc_header.parameter_usings);
                //         header.name = copy_string(alloc_header.name);
                //         header.foreign_function_name = copy_string(alloc_header.foreign_function_name);
                //         header.body_or_null = null;
                //         header.procedure_flags = alloc_header.procedure_flags;

                //         // new_statements: [..] *Code_Node;

                //         compiler_make_procedure_live(w, header);
                //         // compiler_modify_procedure(w, it.expression);
                //     }
                // }

                for typechecked.procedure_headers {
                    if it.expression.name == "print" {
                        print("modifying print\n");
                    }
                    if equals(it.expression, alloc_header) {
                        print("really modifying print\n");
                        print("real header %\n", << it.expression);

                        // TODO do I need to override parameters?
                        // it.expression.constants_block = alloc_header.constants_block;
                        it.expression.arguments = array_copy(alloc_header.arguments);
                        it.expression.returns = array_copy(alloc_header.returns);
                        it.expression.parameter_usings = array_copy(alloc_header.parameter_usings);
                        it.expression.name = copy_string(alloc_header.name);
                        it.expression.foreign_function_name = copy_string(alloc_header.foreign_function_name);
                        it.expression.body_or_null = null;
                        it.expression.procedure_flags = alloc_header.procedure_flags;

                        // new_statements: [..] *Code_Node;

                        print("final result %\n", << it.expression);
                        compiler_make_procedure_live(w, it.expression);
                        // compiler_modify_procedure(w, it.expression);
                    }
                }

                for typechecked.procedure_bodies {
                    if it.expression.body_flags & .ALREADY_MODIFIED {
                        continue;
                    }

                    contains_asm := false;
                    for it.subexpressions {
                        if it.kind == .ASM {
                            // NOTE: #asm blocks are not translatable to WASM, we need to remove them
                            compiler_report("ASM DETECTED!!!", make_location(it), .WARNING);
                            contains_asm = true;
                        }
                    }
                    if contains_asm {
                        body := it.expression;
                        // TODO: delete only the ASM blocks
                        // I'm just too lazy to write such a surgically precise code right now, sorry
                        if body.header.name == "print_to_builder" {
                            continue;
                        }
                        compiler_report(tprint("Removing the whole body of the function %. DON'T USE IT!!!", body.header.name),
                                        make_location(body),
                                        .WARNING);
                        new_statements: [..] *Code_Node;
                        body.block.statements = new_statements;
                        compiler_modify_procedure(w, body);
                    }
                }
            }

            case .PHASE; {
                phase := cast(*Message_Phase) message;
                if phase.phase == .POST_WRITE_EXECUTABLE {
                    assert(phase.compiler_generated_object_files.count == 1, "The build process supports only a single object file compilation");
                    assert(object_file_to_translate_to_wasm.count == 0, "The build process supports only a single object file compilation");
                    object_file_to_translate_to_wasm = phase.compiler_generated_object_files[0];
                }
            }

            case .COMPLETE; break;
        }
    }

    return object_file_to_translate_to_wasm;
}

#run {
    // assert(OS == .LINUX, "TODO: Only Linux is supported for now");

    workspace := compiler_create_workspace("Jai WASM");
    if !workspace {
        print("Error: Could not create a workspace\n");
        exit(1);
    }

    // if !build_cpp_dynamic_lib("libwasmstub", "wasmstub.c") {
    //     print("Error: Could not build dynamic lib with external names");
    //     exit(1);
    // }

    build_options := get_build_options(workspace);
    build_options.output_executable_name = "jaiwasm";
    build_options.llvm_options.output_bitcode = true;
    build_options.llvm_options.enable_split_modules = false;
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
