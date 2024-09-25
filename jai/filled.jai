// #import "System";

// get_number_of_processors :: ($type: Processor_Query_Type = .PERFORMANCE_LOGICAL) -> s32 {
//     return 16;
// }

#if OS == .WASM {
    current_time_monotonic :: () -> Apollo_Time {
        return milliseconds_to_apollo(cast(s64) get_unix_time_wasm());
    }

    #program_export
    get_glfw_vid_mode :: (width: s32, height: s32, redBits: s32, greenBits: s32, blueBits: s32, refreshRate: s32) -> *GLFWvidmode {
        print("HUH?\n");
        vidmode.width = width;
        vidmode.height = height;
        vidmode.redBits = redBits;
        vidmode.greenBits = greenBits;
        vidmode.blueBits = blueBits;
        vidmode.refreshRate = refreshRate;
        return *vidmode;
    }
}

#program_export "wasm_init"
wasm_init :: () {
    ctx := __jai_runtime_init(0, null);

    set_context(ctx);
}

#scope_file

Basic :: #import "Basic";
using Basic;

#if OS == .WASM {
    #poke_name Basic current_time_monotonic;

    vidmode: GLFWvidmode;

    #import "JaiGLFW";
}