#import "Basic";
#import "Compiler";
#import "BuildCpp";
#import "Process";
#import "File";
#import "File_Utilities";
#import "String";

#import,file "../module.jai";
#load "../replacements.jai";
// #import,file "../plugin/wasm.jai";
// #import "Default_Metaprogram";
// #import "Metaprogram_Plugins";

// #import,file "../compiler.jai";

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
    build_options.lazy_foreign_function_lookups       = true;
    build_options.llvm_options.target_system_features = "+bulk-memory"; // "This options is needed so that "memcpy" and "memset" are mapped to "memory.copy" and "memory.fill" instructions in WASM.
    build_options.llvm_options.enable_split_modules   = false;
    build_options.llvm_options.function_sections      = true; // To get around "LLVM ERROR: section already has a defining function: .text"

    import_paths: [..] string;
    array_copy(*import_paths, build_options.import_path);
    array_add(*import_paths, #run tprint("%../../", #filepath));
    build_options.import_path = import_paths;

    STACK_SIZE :: 4194304 - 1024 * 12;
    build_options.additional_linker_arguments = .["--stack-first", "-z", tprint("stack-size=%", STACK_SIZE)];

    set_build_options(build_options, workspace);

    intercept_flags: Intercept_Flags;
    compiler_begin_intercept(workspace, intercept_flags);

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
                    // body := it.expression;
                    // compiler_report(tprint("Removing the body of %.", body.header.name), make_location(body), .WARNING);
                    // new_statements: [..] *Code_Node;
                    // body.block.statements = new_statements;
                    // compiler_modify_procedure(workspace, body);
                }
            }
    }
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
