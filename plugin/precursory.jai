
#import "Basic";
#import "Compiler";
#import "Process";

get_plugin :: () -> *Metaprogram_Plugin {
    p := New(Metaprogram_Plugin);

    p.before_intercept = before_intercept;
    p.shutdown = shutdown;
    // p.add_source = add_source;

    return p;
}

add_source :: (p: *Metaprogram_Plugin) {
    add_build_string("WASM :: #library \"WASM\";", p.workspace);
}

before_intercept :: (p: *Metaprogram_Plugin, flags: *Intercept_Flags) {
    options := get_build_options(p.workspace);

    // options.llvm_options.enable_split_modules = false;
    // options.llvm_options.function_sections = true;
    options.lazy_foreign_function_lookups = true;

    set_build_options(options, p.workspace);
}

shutdown :: (p: *Metaprogram_Plugin) {
    free(p);
}