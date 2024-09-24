
#if WASM {

    #program_export
    heap_base: u64;

    #scope_module

    kalloc :: (size: s64) -> *void #foreign;
    krealloc :: (p: *void, size: s64) -> *void #foreign;
    kfree :: (p: *void) #foreign;

    #scope_export

    kalloc_allocator :: Allocator.{kalloc_allocator_proc, null};

    kalloc_allocator_proc :: (mode: Allocator_Mode, requested_size: s64, old_size: s64, old_memory: *void, allocator_data: *void) -> *void {
        if mode == {
            case .STARTUP;
                return null;

            case .ALLOCATE;
                return kalloc(requested_size);

            case .RESIZE;
                return krealloc(old_memory, requested_size);

            case .FREE;
                kfree(old_memory);
                return null;

            case;
                context.assertion_failed(#location(), "WALLOC ALLOCATOR DOES NOT SUPPORT FLAG");
                return null;
        }
    }

} else {

    

}

#import "Basic";
