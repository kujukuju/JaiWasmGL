#import "Basic";
#import "Compiler";
#import "BuildCpp";
#import "Process";
#import "File";
#import "File_Utilities";
#import "String";
#import,file "../plugin/wasm.jai";
// #import "Default_Metaprogram";
// #import "Metaprogram_Plugins";

// #import,file "../compiler.jai";

build :: () {
    workspace := compiler_create_workspace("Jai WASM");
    if !workspace {
        print("Error: Could not create a workspace\n");
        exit(1);
    }

    wasm_plugin := get_plugin();

    build_options := get_build_options(workspace);
    build_options.output_executable_name = "wasm";

    import_paths: [..] string;
    array_copy(*import_paths, build_options.import_path);
    array_add(*import_paths, #run tprint("%../../", #filepath));
    // array_add(*import_paths, #run tprint("%../plugin/", #filepath));
    build_options.import_path = import_paths;
    set_build_options(build_options, workspace);

    use_plugin_first(workspace, wasm_plugin);

    files := file_list(tprint("%src", #filepath), true);
    for file: files {
        if !ends_with(file, ".jai") {
            continue;
        }

        print("Build file: %\n", file);
        add_build_file(file, workspace);
    }

    use_plugin_last(wasm_plugin);

    set_working_directory(#filepath);
}

#run,stallable build();
