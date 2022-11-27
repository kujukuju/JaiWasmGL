#import "Basic";
#import "Compiler";
#import "BuildCpp";
#import "Process";
#import "File";
#import "File_Utilities";
#import "String";

#import,file "../compiler.jai";

#run {
    workspace := compiler_create_workspace("Jai WASM");
    if !workspace {
        print("Error: Could not create a workspace\n");
        exit(1);
    }

    build_options := wasm_configure_build_options(workspace);
    import_path: [2] string;
    import_path[0] = build_options.import_path[0];
    import_path[1] = #run tprint("%../../", #filepath);
    build_options.import_path = import_path;
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

    object_path := wasm_replace_methods_and_generate_object(workspace);

    compiler_end_intercept(workspace);

    wasm_generate_compiled(workspace, object_path);
}
