
const NULL64 = 0n;
const ACCESS_FREE = 0;
const ACCESS_DIVIDED = 1;
const ACCESS_CLAIMED = 2;

// 16 mb
const DEFAULT_HEAP = 0x1000000;
if (DEFAULT_HEAP & (DEFAULT_HEAP - 1) !== 0) {
    console.error('The default heap size must be a power of two.');
}

// maybe this is too large? im not sure
// but its definitely faster for the program to just grab a block and allocated it rather than find the most accurate size
// if your program is for some reason allocating a ton of tiny blocks, this will need to be reduced
// but that seems less likely than large blocks
const MIN_MEMORY_BYTES = 32768;
if (MIN_MEMORY_BYTES & (MIN_MEMORY_BYTES - 1) !== 0) {
    console.error('The minimum memory byte block size must be a power of two.');
}

// methods get imported into this struct
const Jai = {
    instance: null,
    context: null,
    gl: null,
    initialize: (canvas, path, exported) => {
        Jai.gl = canvas.getContext('webgl2') || canvas.getContext('webgl');
        if (!Jai.gl) {
            console.error('Could not initialize webgl context.');
        }

        // TODO deal with the context being lost gl.isContextLost

        exported = exported || {};
        const merged = {
            ...exported,
            ...bindings,
            ...standard,
            ...mongoose,
            ...opengl,
            ...glfw,
        }

        WebAssembly.instantiateStreaming(fetch(path), {
            'env': new Proxy(merged, {
                get(target, prop, receiver) {
                    if (target.hasOwnProperty(prop)) {
                        return target[prop];
                    }
                    return () => console.error('Missing function: ' +  prop);
                },
            }),
        }).then(wasm => {
            Jai.instance = wasm.instance;

            const pages = DEFAULT_HEAP / 0x10000;
            if (Math.floor(pages) !== pages) {
                console.error('Your default heap size must be an increment of the size of a page, which is 64kb.');
                return;
            }

            Memory.allocated = Jai.instance.exports.memory;
            Memory.allocated.grow(pages);
            Memory.rebuildAccess();
        
            Jai.instance.exports.main(0, BigInt(0));

            // TODO im not really sure technically whats a valid function name in jai, js, and both. should consider this then spit out warnings for incompat
            const validRegex = new RegExp('^[a-zA-Z0-9][a-zA-Z0-9_]+_[0-9a-z]+$');

            for (const name in Jai.instance.exports) {
                if (validRegex.test(name)) {
                    // this blanket split affects things that arent appended with jibberish but I'm not sure why some methods have jibberish and others dont
                    const nameParts = name.split('_');
                    nameParts.length -= 1;
                    const validName = nameParts.join('_');
                    
                    if (Jai[validName]) {
                        console.warn('Jai binding already exists. ', validName, name, Jai[validName]);
                        continue;
                    }
    
                    Jai[validName] = Jai.instance.exports[name].bind(this, Jai.context);
                }
            }

            Jai.resize(window.innerWidth, window.innerHeight);
        
            initialized();
        }).catch(console.error);
    },
}

const Memory = {
    allocated: null,
    heapPointer: 0,
    heapSize: 0,
    // a number that represents if its available, divided with a free child, divided with no free child, or claimed
    access: [],
    indexRequests: [],
    nextPowerOfTwo: (value) => {
        value -= 1;
        value |= value >> 1;
        value |= value >> 2;
        value |= value >> 4;
        value |= value >> 8;
        value |= value >> 16;
        value += 1;
        return value;
    },
    previousPowerOfTwo: (value) => {
        value |= value >> 1;
        value |= value >> 2;
        value |= value >> 4;
        value |= value >> 8;
        value |= value >> 16;
        value -= value >> 1;
        return value;
    },
    alloc: (bytes) => {
        bytes = Math.max(bytes, MIN_MEMORY_BYTES);

        const size = Memory.nextPowerOfTwo(bytes);
        // its assumed that it should at least fit inside the memory
        while (size > Memory.heapSize) {
            Memory.grow();
        }

        // keep growing until available memory is found
        while (true) {
            const depth = Memory.getDepthForBytes(size);

            Memory.indexRequests[0] = 0;
            let indexRequestsLength = 1;

            while (indexRequestsLength > 0) {
                // pop from last and push to last
                const currentIndex = Memory.indexRequests[indexRequestsLength - 1];
                const currentDepth = Memory.getDepthForIndex(currentIndex);
                indexRequestsLength -= 1;

                const currentAccessValue = Memory.access[currentIndex];
                const currentAccessState = Memory.getAccessStateFromValue(currentAccessValue);

                if (currentAccessState === ACCESS_FREE) {
                    if (currentDepth === depth) {
                        Memory.access[currentIndex] = Memory.createAccessValue(ACCESS_CLAIMED, 0);
                        Memory.rebuildParentAvailableSize(currentIndex);

                        return Memory.getPointerFromIndex(currentIndex);
                    } else {
                        // this memory cannot end without finding a valid spot since the previous iterations criteria were met
                        // the new available memory will be updated later by climbing back up the tree
                        Memory.access[currentIndex] = Memory.createAccessValue(ACCESS_DIVIDED, 0);
                        const offset = currentIndex - Memory.getIndexForDepth(currentDepth);

                        // if the memory is free, only traverse one path
                        const childIndexLeft = Memory.getIndexForDepth(currentDepth + 1) + offset * 2;
                        Memory.indexRequests[indexRequestsLength] = childIndexLeft;
                        indexRequestsLength += 1;
                    }
                } else if (currentAccessState === ACCESS_DIVIDED) {
                    const currentAccessAvailable = Memory.getAccessAvailableFromValue(currentAccessValue);
                    if (currentAccessAvailable >= size) {
                        // check both children for access
                        const offset = currentIndex - Memory.getIndexForDepth(currentDepth);
                        const childIndexLeft = Memory.getIndexForDepth(currentDepth + 1) + offset * 2;

                        // its best to not split contiguous memory, so go that path first
                        const leftChildAccessValue = Memory.access[childIndexLeft];
                        const leftChildAccessState = Memory.getAccessStateFromValue(leftChildAccessValue);
                        const rightChildAccessValue = Memory.access[childIndexLeft + 1];
                        const rightChildAccessState = Memory.getAccessStateFromValue(rightChildAccessValue);

                        // try to find the smallest available memory that fits it
                        if (leftChildAccessState === ACCESS_DIVIDED && rightChildAccessState === ACCESS_DIVIDED) {
                            const leftChildAccessAvailable = Memory.getAccessAvailableFromValue(leftChildAccessValue);
                            const rightChildAccessAvailable = Memory.getAccessAvailableFromValue(rightChildAccessValue);

                            if (leftChildAccessAvailable >= size && rightChildAccessAvailable >= size) {
                                if (leftChildAccessAvailable <= rightChildAccessAvailable) {
                                    Memory.indexRequests[indexRequestsLength] = childIndexLeft;
                                    indexRequestsLength += 1;
                                    continue;
                                } else {
                                    Memory.indexRequests[indexRequestsLength] = childIndexLeft + 1;
                                    indexRequestsLength += 1;
                                    continue;
                                }
                            }
                        }
                        
                        if (leftChildAccessState === ACCESS_DIVIDED) {
                            const leftChildAccessAvailable = Memory.getAccessAvailableFromValue(leftChildAccessValue);
                            if (leftChildAccessAvailable >= size) {
                                Memory.indexRequests[indexRequestsLength] = childIndexLeft;
                                indexRequestsLength += 1;
                                continue;
                            }
                        }

                        if (rightChildAccessState === ACCESS_DIVIDED) {
                            const rightChildAccessAvailable = Memory.getAccessAvailableFromValue(rightChildAccessValue);
                            if (rightChildAccessAvailable >= size) {
                                Memory.indexRequests[indexRequestsLength] = childIndexLeft + 1;
                                indexRequestsLength += 1;
                                continue;
                            }
                        }

                        // now either the left one is completely free, or the right one is completely free
                        // and we know the size is correct because it's gotten to this point
                        if (leftChildAccessState === ACCESS_FREE) {
                            Memory.indexRequests[indexRequestsLength] = childIndexLeft;
                            indexRequestsLength += 1;
                        } else {
                            Memory.indexRequests[indexRequestsLength] = childIndexLeft + 1;
                            indexRequestsLength += 1;
                        }
                    }
                }
            }

            Memory.grow();
        }
    },
    rebuildParentAvailableSize: (currentIndex) => {
        // go a straight line up the tree and set all the memory values
        let currentDepth = Memory.getDepthForIndex(currentIndex);
        let parentDepth = currentDepth - 1;
        while (parentDepth >= 0) {
            const currentOffset = currentIndex - Memory.getIndexForDepth(currentDepth);
            const parentOffset = Math.floor(currentOffset / 2);
            const parentIndex = Memory.getIndexForDepth(parentDepth) + parentOffset;

            const childDepthIndex = Memory.getIndexForDepth(currentDepth);
            const leftChildIndex = childDepthIndex + parentOffset * 2;
            const rightChildIndex = childDepthIndex + parentOffset * 2 + 1;

            const leftChildAvailable = Memory.getAccessAvailableFromValue(Memory.access[leftChildIndex]);
            const rightChildAvailable = Memory.getAccessAvailableFromValue(Memory.access[rightChildIndex]);

            Memory.access[parentIndex] = Memory.createAccessValue(ACCESS_DIVIDED, Math.max(leftChildAvailable, rightChildAvailable));

            currentIndex = parentIndex;
            currentDepth = parentDepth;
            parentDepth = currentDepth - 1;
        }
    },
    rebuildParentClaimed: (currentIndex) => {
        // go a straight line up the tree and set all the memory values
        let currentDepth = Memory.getDepthForIndex(currentIndex);
        let parentDepth = currentDepth - 1;
        while (parentDepth >= 0) {
            const currentOffset = currentIndex - Memory.getIndexForDepth(currentDepth);
            const parentOffset = Math.floor(currentOffset / 2);
            const parentIndex = Memory.getIndexForDepth(parentDepth) + parentOffset;

            const childDepthIndex = Memory.getIndexForDepth(currentDepth);
            const leftChildIndex = childDepthIndex + parentOffset * 2;
            const rightChildIndex = childDepthIndex + parentOffset * 2 + 1;

            const leftChildState = Memory.getAccessStateFromValue(Memory.access[leftChildIndex]);
            const leftChildAvailable = Memory.getAccessAvailableFromValue(Memory.access[leftChildIndex]);
            const rightChildState = Memory.getAccessStateFromValue(Memory.access[rightChildIndex]);
            const rightChildAvailable = Memory.getAccessAvailableFromValue(Memory.access[rightChildIndex]);

            if (leftChildState === ACCESS_FREE && rightChildState === ACCESS_FREE) {
                Memory.access[parentIndex] = Memory.createAccessValue(ACCESS_FREE, leftChildAvailable + rightChildAvailable);
            } else {
                Memory.access[parentIndex] = Memory.createAccessValue(ACCESS_DIVIDED, Math.max(leftChildAvailable, rightChildAvailable));
            }

            currentIndex = parentIndex;
            currentDepth = parentDepth;
            parentDepth = currentDepth - 1;
        }
    },
    free: (pointer) => {
        pointer -= Memory.heapPointer;
        // returns the size of the freed memory
        // the pointer only tells you where horizontally in the tree it is, so we still need to potentially check every depth
        // first we need to get the minimum possible depth
        // so
        // 256 / 256 = 1        1 / 1 = 1
        // 256 / 512 = 0.5      1 / 2 = 0.5
        // 256 / 1024 = 0.25    1 / 4 = 0.25
        // 256 / 2048 = 0.125   1 / 8 = 0.125
        // 1024 / 256 = 4       4 / 1 = 4
        // 1024 / 512 = 2       4 / 2 = 2
        // 1024 / 1024 = 1      4 / 4 = 1
        // 1280 / 256 = 5       5 / 1 = 5
        // 1280 / 512 = 2.5     5 / 2 = 2.5
        // 1280 / 1024 = 1.25   5 / 4 = 1.25
        // so basically we need to get the maximum stable denominator
        // idk this seems to be wrong so im just gonna do it another way

        let currentDepth = Memory.getDepthForIndex(Memory.access.length - 1);
        let currentBlockSize = MIN_MEMORY_BYTES;
        // add heap size to avoid issues at 0
        while ((pointer + Memory.heapSize) % currentBlockSize === 0) {
            const offset = pointer / currentBlockSize;
            const index = Memory.getIndexForDepth(currentDepth) + offset;

            if (Memory.getAccessStateFromValue(Memory.access[index]) === ACCESS_CLAIMED) {
                Memory.access[index] = Memory.createAccessValue(ACCESS_FREE, currentBlockSize);
                Memory.rebuildParentClaimed(index);
                return currentBlockSize;
            }

            currentDepth -= 1;
            currentBlockSize *= 2;
        }

        console.error('Unable to find allocated memory to free. ', pointer);
    },
    createAccessValue: (state, available) => {
        // 28 because javascript sucks and becomes innaccurate with their dumb floating point integer shit at 30
        // also we divide by min memory bytes so that we can allocate more than 128 or 256 mb if we want to, otherwise it breaks
        return (state << 28) | (available / MIN_MEMORY_BYTES);
    },
    getAccessStateFromValue: (value) => {
        return (value & 0xF0000000) >> 28;
    },
    getAccessAvailableFromValue: (value) => {
        return (value & 0x0FFFFFFF) * MIN_MEMORY_BYTES;
    },
    getAccessPointer: (depth, offset) => {
        // top level is depth 0, offset 0
        // second level is depth 1, offset 0 and 1

        // 0, 0 = 1  correct = 0
        // 1, 0 = 2  correct = 1
        // 2, 0 = 4  correct = 3
        // 3, 0 = 8  correct = 7
        // 3, 1 = 9  correct = 8
        return Math.pow(2, depth) + offset - 1;
    },
    getPointerFromIndex: (index) => {
        const depth = Memory.getDepthForIndex(index);
        const chunk = Memory.getChunkSizeForDepth(depth);
        const start = Memory.getIndexForDepth(depth);
        return (index - start) * chunk + Memory.heapPointer;
    },
    printAccessStates: () => {
        let currentDepth = 0;
        let line = '';
        for (let i = 0; i < Memory.access.length; i++) {
            const depth = Memory.getDepthForIndex(i);

            if (currentDepth !== depth) {
                currentDepth = depth;
                console.log(line);
                line = '';
            }
            
            const accessState = Memory.getAccessStateFromValue(Memory.access[i]);
            if (accessState === ACCESS_FREE) {
                line += 'F ';
            } else if (accessState === ACCESS_DIVIDED) {
                line += 'D ';
            } else if (accessState === ACCESS_CLAIMED) {
                line += 'C ';
            }
        }
        console.log(line);
    },
    grow: () => {
        console.log('Growing heap memory.');
        // one page is 65536 bytes
        const currentPageCount = Memory.heapSize / 0x10000;
        if (Math.floor(currentPageCount) !== currentPageCount) {
            console.error('Cannot have fractional page counts. If this ever happens, you need to manually instantiate the size of the original memory buffer to be a power of 65536.');
            return;
        }

        // we only double buffer size
        Memory.allocated.grow(currentPageCount);
        Memory.rebuildAccess();
    },
    getChunkSizeForDepth: (depth) => {
        return Memory.heapSize / Memory.getLengthForDepth(depth);
    },
    getDepthForIndex: (index) => {
        // 0 = 0
        // 1 = 1
        // 2 = 1
        // 3 = 2
        // 4 = 2
        // 5 = 2
        // 6 = 2
        // 7 = 3
        // 8 = 3
        // https://oeis.org/A070939
        return Math.floor(Math.log2(index + 1));
    },
    getLengthForDepth: (depth) => {
        // 0 = 1
        // 1 = 2
        // 2 = 4
        // 3 = 8
        return Math.pow(2, depth);
    },
    getIndexForDepth: (depth) => {
        // 0 = 0
        // 1 = 1
        // 2 = 3
        // 3 = 7

        return Math.pow(2, depth) - 1;
    },
    getDepthForBytes: (bytes) => {
        // bytes must be a power of 2
        // bytes == bufferSize      then 0
        // bytes == bufferSize / 2  then 1
        // bytes == bufferSize / 4  then 2
        // bytes == bufferSize / 8  then 3
        // so conversely
        // 0 = 1
        // 1 = 2
        // 2 = 4
        // 3 = 8
        // idk if round is necessary here but im worried about floating point precision
        return Math.round(Math.log2(Memory.heapSize / bytes));
    },
    rebuildAccess: () => {
        Memory.heapPointer = Number(Jai.instance.exports.__heap_base.value);
        Memory.heapSize = Memory.previousPowerOfTwo(Memory.allocated.buffer.byteLength - Memory.heapPointer);
        Helpers.u8 = new Uint8Array(Memory.allocated.buffer);
        Helpers.u32 = new Uint32Array(Memory.allocated.buffer);
        Helpers.s32 = new Int32Array(Memory.allocated.buffer);
        Helpers.u64 = new BigUint64Array(Memory.allocated.buffer);
        Helpers.s64 = new BigInt64Array(Memory.allocated.buffer);

        // if the most granular level of access will fit N entries
        // then the size of access is always N + N / 2 + N / 4 + N / 8 ...
        // so N * 2 - 1
        const memoryEntries = Memory.heapSize / MIN_MEMORY_BYTES;
        if (Math.floor(memoryEntries) !== memoryEntries) {
            console.error('Cannot cleanly divide the memory into minimal chunks. You must allocate larger blocks of memory with each grow, or reduce the minimum memory block byte size. Or maybe the memory isn\'t initialized as a power of 2.');
            return;
        }

        const fresh = Memory.access.length === 0;
        Memory.access.length = memoryEntries * 2 - 1;

        if (fresh) {
            for (let i = 0; i < Memory.access.length; i++) {
                const depth = Memory.getDepthForIndex(i);
                const size = Memory.getChunkSizeForDepth(depth);
                Memory.access[i] = Memory.createAccessValue(ACCESS_FREE, size);
            }
        } else {
            // fill in the available memory
            // the left half of each depth is the old tree, so copy the left values, and create new right values
            // and start at the second index because we'll manually correct the first index later
            // this can also be done in place because all the memory is just being moved down one depth, so update backwards
            for (let i = Memory.access.length - 1; i >= 1; i--) {
                const depth = Memory.getDepthForIndex(i);
                const depthLength = Memory.getLengthForDepth(depth);
                const depthOffset = i - Memory.getIndexForDepth(depth);

                if (depthOffset < depthLength / 2) {
                    const offset = i - Memory.getIndexForDepth(depth);
                    const previous = Memory.getIndexForDepth(depth - 1) + offset;
                    Memory.access[i] = Memory.access[previous];
                } else {
                    const size = Memory.getChunkSizeForDepth(depth);
                    Memory.access[i] = Memory.createAccessValue(ACCESS_FREE, size);
                }
            }

            // the first index into access is the old tree, so correct the new root node
            if (Memory.getAccessStateFromValue(Memory.access[1]) !== ACCESS_FREE) {
                Memory.access[0] = Memory.createAccessValue(ACCESS_DIVIDED, Memory.heapSize / 2);
            } else {
                Memory.access[0] = Memory.createAccessValue(ACCESS_FREE, Memory.heapSize);
            }
        }
    },
};

// stores gl names and maps them to their real values
const Names = {
    available: [],
    // the first object should already exist because a lot of gl names use 0 as null and this uses indices as names
    objects: [null],
    availableCount: 0,
    addPointerObject: (object) => {
        if (Names.availableCount === 0) {
            Names.objects.push(object);
            return Names.objects.length - 1;
        }

        const index = Names.available[Names.availableCount - 1];
        Names.availableCount -= 1;

        Names.objects[index] = object;
        return index;
    },
    freePointerObject: (pointer) => {
        Names.available[Names.availableCount] = pointer;
        Names.availableCount += 1;
    },
};

const Helpers = {
    u8: null,
    u32: null,
    s32: null,
    u64: null,
    s64: null,
    decoder: new TextDecoder(),
    encoder: new TextEncoder(),
    writeData32: (pointer, data) => {
        if (Number.isInteger(data)) {
            Helpers.s32[Number(pointer) / 4] = data;
        } else if (data === true) {
            Helpers.s32[Number(pointer) / 4] = 1;
        } else if (data === false) {
            Helpers.s32[Number(pointer) / 4] = 0;
        }
    },
    writeData64: (pointer, data) => {
        if (Number.isInteger(data)) {
            Helpers.s64[Number(pointer) / 8] = BigInt(data);
        } else if (data === true) {
            Helpers.s64[Number(pointer) / 8] = 1n;
        } else if (data === false) {
            Helpers.s64[Number(pointer) / 8] = 0n;
        }
    },
    writeNullString: (pointer, string, length) => {
        // this is assumed to be null terminated
        for (let i = 0; i < length - 1; i++) {
            if (i < string.length) {
                Helpers.u8[pointer + i] = string.charCodeAt(i);
            } else {
                Helpers.u8[pointer + i] = 0;
            }
        }
        Helpers.u8[pointer + length - 1] = 0;

        return Math.min(string.length, length - 1);
    },
    readString64: (pointer, length) => {
        const bytes = Helpers.u8.subarray(Number(pointer), Number(pointer) + Number(length));
        return Helpers.decoder.decode(bytes);
    },
    readBool: (pointer) => {
        return !!Helpers.u8[pointer];
    },
    getNullStringLength: (pointer) => {
        let length = 0;
        while (Helpers.u8[pointer + length]) {
            length += 1;
        }
        return length;
    },
    readNullString64: (pointer) => {
        const length = Helpers.getNullStringLength(pointer);
        return Helpers.readString64(pointer, length);
    },
    getSubArray: (pointer, length) => {
        return Helpers.u8.subarray(Number(pointer), Number(pointer) + Number(length));
    },
};

// the goal is to avoid memory allocations and new objects in js at all costs
// gc frame drops and stutters are probably harder to deal with than slower performance

let getTimeStartTime = 0;

const bindings = {
    set_context: (context) => Jai.context = BigInt(context),
    read_entire_file_wasm: (name_data, name_count, log_errors, data, count) => {
        const name = Helpers.readString64(name_data, name_count);

        const request = new XMLHttpRequest();
        request.onload = () => {
            if (request.status === 404) {
                Helpers.writeData64(data, 0);
                Helpers.writeData64(count, 0);
                return;
            }

            if (request.status !== 200) {
                if (log_errors) {
                    console.error('Request had an unknown error.', name, request.status, request.responseText);
                }
                
                Helpers.writeData64(data, 0);
                Helpers.writeData64(count, 0);
                return;
            }

            const string = request.response;
            if (!string) {
                if (log_errors) {
                    console.error('Request had an incorrect response.', name, request.status, request.responseText);
                }
                
                Helpers.writeData64(data, 0);
                Helpers.writeData64(count, 0);
                return;
            }

            // assuming each character is u8, which could be wrong for all I know because this is really weird
            const pointer = Memory.alloc(string.length);
            const subarray = Helpers.getSubArray(pointer, string.length);
            Helpers.encoder.encodeInto(string, subarray);

            Helpers.writeData64(data, pointer);
            Helpers.writeData64(count, string.length);
        };
        request.onerror = () => {
            if (log_errors) {
                console.error('Request could not be completed.', name, request.status, request.responseText);
            }

            Helpers.writeData64(data, 0);
            Helpers.writeData64(count, 0);
        };
        // its not possible to set responseType in synchronous mode, and if you spin lock you never get the callback
        request.overrideMimeType("text/plain; charset=x-user-defined");
        request.open('GET', name, false);
        
        try {
            request.send();
        } catch {
            
        }
    },
    file_exists_wasm: (name_data, name_count) => {
        const name = Helpers.readString64(name_data, name_count);

        let found = false;
        const request = new XMLHttpRequest();
        request.onload = () => {
            if (request.status === 200) {
                found = true;
            }
        };
        request.open('HEAD', name, false);
        try {
            request.send();
        } catch {

        }

        console.log('returning ', found);
        return found;
    },
    init_time_wasm: () => {
        if (!getTimeStartTime) {
            getTimeStartTime = Date.now();
        }
    },
    get_time_wasm: () => {
        if (!getTimeStartTime) {
            getTimeStartTime = Date.now();
        }

        return BigInt(Date.now() - getTimeStartTime);
    },
};

const standard = {
    memset: (dest, value, length) => {
        Helpers.u8.fill(value, Number(dest), Number(dest + length));
        return dest;
    },
    memcpy: (dest, src, length) => {
        // TODO I want to compare the speeds here
        // const write = new Uint8Array(Memory.allocated.buffer, Number(dest), Number(length));
        // const read = new Uint8Array(Memory.allocated.buffer, Number(src), Number(length));
        // write.set(read);
        dest = Number(dest);
        src = Number(src);
        length = Number(length);
        if (dest <= src) {
            for (let i = 0; i < length; i++) {
                Helpers.u8[dest + i] = Helpers.u8[src + i];
            }
        } else {
            for (let i = length - 1; i >= 0; i--) {
                Helpers.u8[dest + i] = Helpers.u8[src + i];
            }
        }
        return BigInt(dest);
    },
    memcmp: (a, b, count) => {
        a = Number(a);
        b = Number(b);
        count = Number(count);
        for (let i = 0; i < count; i++) {
            if (Helpers.u8[a + i] !== Helpers.u8[b + i]) {
                return Helpers.u8[a + i] - Helpers.u8[b + i];
            }
        }

        return 0;
    },
    SetUnhandledExceptionFilter: value => NULL64,
    SymSetOptions: value => 0,
    SymInitialize: value => 0,
    fabs: Math.abs,
    powf: Math.pow,
    sqrtf: Math.sqrt,
    sigemptyset: () => {},
    sigaction: () => {},
    malloc: (size) => {
        return BigInt(Memory.alloc(Number(size)));
    },
    realloc: (pointer, size) => {
        if (!pointer) {
            return BigInt(Memory.alloc(Number(size)));
        }

        // TODO try not to move the content, but this will handle most cases already
        const oldSize = Memory.free(Number(pointer));
        const newPointer = BigInt(Memory.alloc(Number(size)));

        // im not sure if you can realloc down, but maybe
        const copySize = Math.min(oldSize, Number(size));

        if (newPointer === pointer) {
            // no need to copy data, yay
            return newPointer;
        } else {
            bindings.memcpy(newPointer, pointer, copySize);
        }
    },
    free: (pointer) => {
        Memory.free(Number(pointer));
    },
    EnterCriticalSection: () => {/*does nothing since we dont require thread sync, probably*/},
    WriteFile: (handle, buffer, buffer_length, written_result, overlapped) => {
        // const bytes = Helpers.u8.subarray(Number(buffer), Number(buffer) + buffer_length);

        return 1;
    },
    LeaveCriticalSection: () => {/*does nothing since we dont require thread sync, probably*/},
    pthread_mutex_lock: (mutex) => {
        return 0;
    },
    pthread_mutex_unlock: (mutex) => {
        return 0;
    },
    write: (fd, buf, count) => {
        const string = Helpers.readString64(buf, count);
        if (fd == 1) {
            console.log(string);
        } else if (fd == 2) {
            console.error(string);
        } else {
            console.error('Unhandled fd value.', fd);
        }
        return count;
    },
};

const mongoose = {
    MongooseConnection: function(url) {
        this.websocket = new WebSocket(url);
    },
    closeConnection: (connectionPointer) => {
        const fdPointer = Number(connectionPointer) + 72;
        const fd = Helpers.u64[fdPointer / 8];
        if (fd) {
            const websocket = Names.objects[Number(fd)];
            websocket.close();

            Names.freePointerObject(Number(fd));
            Helpers.u64[fdPointer / 8] = 0;
        }
    },
    mg_mgr_init: (mgr) => {
        // do nothing I guess
    },
    mg_mgr_free: (mgr) => {
        const connectionPointer = Helpers.u64[mgr / 8];
        if (connectionPointer) {
            mongoose.closeConnection(connectionPointer);
        }
    },
    mg_mgr_poll: (mgr, millis) => {
        // this function has to read packets, send queued packets, close websockets marked is_closing, and flush and close websockets marked is_dumping
        // if mgr -> connection -> is_closing, close it
        const connectionPointer = Helpers.u64[Number(mgr) / 8];
        if (connectionPointer) {
            // deal with is_closing and is_flushing
            const isClosingPointer = Number(connectionPointer) + 276;
            const isDumpingointer = Number(connectionPointer) + 272;
            let shouldClose = false;
            // is closing
            shouldClose = shouldClose || Helpers.u32[isClosingPointer / 4];
            // is dumping
            shouldClose = shouldClose || Helpers.u32[isDumpingointer / 4];
            if (shouldClose) {
                mongoose.closeConnection(connectionPointer);
            }
        }
    },
    mg_ws_connect: (mgr, url, fn, fn_data, fmt) => {
        const string = Helpers.readNullString64(Number(url));
        const websocket = new WebSocket(string);
        const websocketPointer = Names.addPointerObject(websocket);

        // TODO this needs to all be asserted in mongooseJai
        const connection = Memory.alloc(288);
        const fdPointer = connection + 72;
        Helpers.u64[fdPointer / 8] = BigInt(websocketPointer);
        const fnPointer = connection + 136;
        Helpers.u64[fnPointer / 8] = BigInt(fn);
        const fnDataPointer = connection + 144;
        Helpers.u64[fnDataPointer / 8] = BigInt(fn_data);

        // write into the connection pointer of the manager
        Helpers.u64[Number(mgr) / 8] = connection;

        // TODO set up something to write packets

        return BigInt(connection);
    },
    mg_ws_send: (conn, buf, buflen, op) => {
        const fdPointer = Number(conn) + 72;
        const fd = Helpers.u64[fdPointer / 8];
        if (fd) {
            const bytes = Helpers.u8.subarray(Number(buf), Number(buf) + Number(buflen));

            const websocket = Names.objects[Number(fd)];
            websocket.send(bytes);
        }
    },
};

const opengl = {
    // opengl
    glActiveTexture: (texture /*GLenum*/) => {
        Jai.gl.activeTexture(texture);
    },
    glAttachShader: (program /*GLuint*/, shader /*GLuint*/) => {
        program = Names.objects[program];
        shader = Names.objects[shader];
        Jai.gl.attachShader(program, shader);
    },
    glBindAttribLocation: (program /*GLuint*/, index /*GLuint*/, name /**GLchar*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glBindBuffer: (target /*GLenum*/, buffer /*GLuint*/) => {
        if (buffer === 0) {
            Jai.gl.bindBuffer(target, null);
        } else {
            buffer = Names.objects[buffer];
            Jai.gl.bindBuffer(target, buffer);
        }
    },
    glBindFramebuffer: (target /*GLenum*/, framebuffer /*GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glBindRenderbuffer: (target /*GLenum*/, renderbuffer /*GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glBindTexture: (target /*GLenum*/, texture /*GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glBlendColor: (red /*GLfloat*/, green /*GLfloat*/, blue /*GLfloat*/, alpha /*GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glBlendEquation: (mode /*GLenum*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glBlendEquationSeparate: (modeRGB /*GLenum*/, modeAlpha /*GLenum*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glBlendFunc: (sfactor /*GLenum*/, dfactor /*GLenum*/) => {
        Jai.gl.blendFunc(sfactor, dfactor);
    },
    glBlendFuncSeparate: (sfactorRGB /*GLenum*/, dfactorRGB /*GLenum*/, sfactorAlpha /*GLenum*/, dfactorAlpha /*GLenum*/) => {
        Jai.gl.blendFuncSeparate(sfactorRGB, dfactorRGB, sfactorAlpha, dfactorAlpha);
    },
    glBufferData: (target /*GLenum*/, size /*GLsizeiptr*/, data /**void*/, usage /*GLenum*/) => {
        const bytes = new Uint8Array(Memory.allocated.buffer, Number(data), Number(size));
        Jai.gl.bufferData(target, bytes, usage);
    },
    glBufferSubData: (target /*GLenum*/, offset /*GLintptr*/, size /*GLsizeiptr*/, data /**void*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glCheckFramebufferStatus: (target /*GLenum*/) => /*GLenum*/ {
        console.error('Not implemented.', getCallerName());
    },
    glClear: (mask /*GLbitfield*/) => {
        Jai.gl.clear(mask);
    },
    glClearColor: (red /*GLfloat*/, green /*GLfloat*/, blue /*GLfloat*/, alpha /*GLfloat*/) => {
        Jai.gl.clearColor(red, green, blue, alpha);
    },
    glClearDepth: (depth /*GLdouble*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glClearStencil: (s /*GLint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glColorMask: (red /*GLboolean*/, green /*GLboolean*/, blue /*GLboolean*/, alpha /*GLboolean*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glCommit: () => {
        console.error('Not implemented.', getCallerName());
    },
    glCompileShader: (shader /*GLuint*/) => {
        shader = Names.objects[shader];
        Jai.gl.compileShader(shader);
    },
    glCompressedTexImage2D: (target /*GLenum*/, level /*GLint*/, internalformat /*GLenum*/, width /*GLsizei*/, height /*GLsizei*/, border /*GLint*/, imageSize /*GLsizei*/, data /**void*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glCompressedTexImage3D: (target /*GLenum*/, level /*GLint*/, internalformat /*GLenum*/, width /*GLsizei*/, height /*GLsizei*/, depth /*GLsizei*/, border /*GLint*/, imageSize /*GLsizei*/, data /**void*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glCompressedTexSubImage2D: (target /*GLenum*/, level /*GLint*/, xoffset /*GLint*/, yoffset /*GLint*/, width /*GLsizei*/, height /*GLsizei*/, format /*GLenum*/, imageSize /*GLsizei*/, data /**void*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glCopyTexImage2D: (target /*GLenum*/, level /*GLint*/, internalformat /*GLenum*/, x /*GLint*/, y /*GLint*/, width /*GLsizei*/, height /*GLsizei*/, border /*GLint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glCopyTexSubImage2D: (target /*GLenum*/, level /*GLint*/, xoffset /*GLint*/, yoffset /*GLint*/, x /*GLint*/, y /*GLint*/, width /*GLsizei*/, height /*GLsizei*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glGenBuffers: (n /*GLsizei*/, buffers /**GLuint*/) => {
        buffers = Number(buffers);
        for (let i = 0; i < n; i++) {
            const buffer = Jai.gl.createBuffer();
            const pointer = Names.addPointerObject(buffer);
            Helpers.u32[buffers / 4 + i] = pointer;
        }
    }, // glCreateBuffer
    glGenFramebuffers: (n /*GLsizei*/, framebuffers /**GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glCreateFramebuffer
    glCreateProgram: () => /*GLuint*/ {
        const program = Jai.gl.createProgram();
        return Names.addPointerObject(program);
    },
    glCreateRenderbuffers: (n /*GLsizei*/, renderbuffers /**GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glCreateRenderbuffer
    glCreateShader: (type /*GLenum*/) => /*GLuint*/ {
        const shader = Jai.gl.createShader(type);
        const pointer = Names.addPointerObject(shader);
        return pointer;
    },
    glCreateTextures: (target /*GLenum*/, n /*GLsizei*/, textures /**GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glCreateTexture
    glCullFace: (mode /*GLenum*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glDeleteBuffers: (n /*GLsizei*/, buffers /**GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glDeleteBuffer
    glDeleteFramebuffers: (n /*GLsizei*/, framebuffers /**GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glDeleteFramebuffer
    glDeleteProgram: (program /*GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glDeleteRenderbuffers: (n /*GLsizei*/, renderbuffers /**GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glDeleteRenderbuffer
    glDeleteShader: (shader /*GLuint*/) => {
        shader = Names.objects[shader];
        Jai.gl.deleteShader(shader);
    },
    glDeleteTextures: (n /*GLsizei*/, textures /**GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glDeleteTexture
    glDepthFunc: (func /*GLenum*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glDepthMask: (flag /*GLboolean*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glDepthRange: (near /*GLdouble*/, far /*GLdouble*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glDetachShader: (program /*GLuint*/, shader /*GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glDisable: (cap /*GLenum*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glDisableVertexAttribArray: (index /*GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glDrawArrays: (mode /*GLenum*/, first /*GLint*/, count /*GLsizei*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glDrawElements: (mode /*GLenum*/, count /*GLsizei*/, type /*GLenum*/, indices /**void*/) => {
        Jai.gl.drawElements(mode, count, type, Number(indices));
    },
    glEnable: (cap /*GLenum*/) => {
        Jai.gl.enable(cap);
    },
    glEnableVertexAttribArray: (index /*GLuint*/) => {
        Jai.gl.enableVertexAttribArray(index);
    },
    glFinish: () => {
        console.error('Not implemented.', getCallerName());
    },
    glFlush: () => {
        console.error('Not implemented.', getCallerName());
    },
    glFramebufferRenderbuffer: (target /*GLenum*/, attachment /*GLenum*/, renderbuffertarget /*GLenum*/, renderbuffer /*GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glFramebufferTexture2D: (target /*GLenum*/, attachment /*GLenum*/, textarget /*GLenum*/, texture /*GLuint*/, level /*GLint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glFrontFace: (mode /*GLenum*/) => {
        Jai.gl.frontFace(mode);
    },
    glGenTextures: (n /*GLsizei*/, textures /**GLuint*/) => {

    },
    glGenerateMipmap: (target /*GLenum*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glGetActiveAttrib: (program /*GLuint*/, index /*GLuint*/, bufSize /*GLsizei*/, length /**GLsizei*/, size /**GLint*/, type /**GLenum*/, name /**GLchar*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glGetActiveUniform: (program /*GLuint*/, index /*GLuint*/, bufSize /*GLsizei*/, length /**GLsizei*/, size /**GLint*/, type /**GLenum*/, name /**GLchar*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glGetAttachedShaders: (program /*GLuint*/, maxCount /*GLsizei*/, count /**GLsizei*/, shaders /**GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glGetAttribLocation: (program /*GLuint*/, name /**GLchar*/) => /*GLint*/ {
        program = Names.objects[program];
        name = Number(name);
        const bytes = new Uint8Array(Memory.allocated.buffer);
        let string = '';
        while (bytes[name] !== 0) {
            string += String.fromCharCode(bytes[name]);
            name += 1;
        }
        return Jai.gl.getAttribLocation(program, string);
    },
    glGetBufferParameteriv: (target /*GLenum*/, pname /*GLenum*/, params /**GLint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetBufferParameter
    glGetContextAttributes: () => /*GLint*/ {
        console.error('Not implemented.', getCallerName());
    },
    glGetError: () => /*GLenum*/ {
        console.error('Not implemented.', getCallerName());
    },
    glGetExtension: (name /**GLchar*/, length /*GLsizei*/) => /*GLint*/ {
        console.error('Not implemented.', getCallerName());
    },
    glGetFramebufferAttachmentParameteriv: (target /*GLenum*/, attachment /*GLenum*/, pname /*GLenum*/, params /**GLint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetFramebufferAttachmentParameter
    glGetBooleanv: (pname /*GLenum*/, data /**GLboolean*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetParameter
    glGetDoublev: (pname /*GLenum*/, data /**GLdouble*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetParameter
    glGetFloatv: (pname /*GLenum*/, data /**GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetParameter
    glGetIntegerv: (pname /*GLenum*/, data /**GLint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetParameter
    glGetString: (name /*GLenum*/) => /**GLubyte*/ {
        if (name == Jai.gl.VERSION) {
            const versionString = Jai.gl.getParameter(Jai.gl.VERSION);
            const versionIndex = versionString.indexOf('OpenGL ES');
            const versionRemainder = versionString.substring(versionIndex + 'OpenGL ES'.length + 1, versionString.length - 1);

            const versionPointer = Memory.alloc(versionRemainder.length + 1);
            Helpers.writeNullString(versionPointer, versionRemainder, versionRemainder.length + 1);

            return BigInt(versionPointer);
        } else {
            console.error('Not implemented.', getCallerName());
        }
    }, // glGetParameter
    glGetInteger64v: (pname /*GLenum*/, data /**GLint64*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetParameter
    glGetBooleani_v: (target /*GLenum*/, index /*GLuint*/, data /**GLboolean*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetParameter
    glGetIntegeri_v: (target /*GLenum*/, index /*GLuint*/, data /**GLint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetParameter
    glGetFloati_v: (target /*GLenum*/, index /*GLuint*/, data /**GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetParameter
    glGetDoublei_v: (target /*GLenum*/, index /*GLuint*/, data /**GLdouble*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetParameter
    glGetInteger64i_v: (target /*GLenum*/, index /*GLuint*/, data /**GLint64*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetParameter
    glGetProgramInfoLog: (program /*GLuint*/, bufSize /*GLsizei*/, length /**GLsizei*/, infoLog /**GLchar*/) => {
        program = Names.objects[program];
        const message = Jai.gl.getProgramInfoLog(program);
        const written = Helpers.writeNullString(Number(infoLog), message, bufSize);
        if (length) {
            Helpers.u32[Number(length) / 4] = written;
        }
    },
    glGetProgramiv: (program /*GLuint*/, pname /*GLenum*/, params /**GLint*/) => {
        program = Names.objects[program];
        const data = Jai.gl.getProgramParameter(program, pname);
        Helpers.writeData32(Number(params), data);
    }, // glGetProgramParameter
    glGetRenderbufferParameteriv: (target /*GLenum*/, pname /*GLenum*/, params /**GLint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetRenderbufferParameter
    glGetShaderInfoLog: (shader /*GLuint*/, bufSize /*GLsizei*/, length /**GLsizei*/, infoLog /**GLchar*/) => {
        shader = Names.objects[shader];
        const message = Jai.gl.getShaderInfoLog(shader);
        const written = Helpers.writeNullString(Number(infoLog), message, bufSize);
        if (length) {
            Helpers.u32[Number(length) / 4] = written;
        }
    },
    glGetShaderiv: (shader /*GLuint*/, pname /*GLenum*/, params /**GLint*/) => {
        shader = Names.objects[shader];
        const data = Jai.gl.getShaderParameter(shader, pname);
        Helpers.writeData32(Number(params), data);
    }, // getShaderParameter
    glGetShaderPrecisionFormat: (shadertype /*GLenum*/, precisiontype /*GLenum*/, range /**GLint*/, precision /**GLint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glGetShaderSource: (shader /*GLuint*/, bufSize /*GLsizei*/, length /**GLsizei*/, source /**GLchar*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glGetSupportedExtensions: (names /***GLchar*/, lengths /**GLsizei*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glGetTexParameterfv: (target /*GLenum*/, pname /*GLenum*/, params /**GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetTexParameter
    glGetTexParameteriv: (target /*GLenum*/, pname /*GLenum*/, params /**GLint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetTexParameter
    glGetUniformfv: (program /*GLuint*/, location /*GLint*/, params /**GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetUniform
    glGetUniformiv: (program /*GLuint*/, location /*GLint*/, params /**GLint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetUniform
    glGetUniformLocation: (program /*GLuint*/, name /**GLchar*/) => /*GLint*/ {
        console.error('Not implemented.', getCallerName());
    },
    glGetVertexAttribdv: (index /*GLuint*/, pname /*GLenum*/, params /**GLdouble*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetVertexAttrib
    glGetVertexAttribfv: (index /*GLuint*/, pname /*GLenum*/, params /**GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetVertexAttrib
    glGetVertexAttribiv: (index /*GLuint*/, pname /*GLenum*/, params /**GLint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetVertexAttrib
    glGetVertexAttribPointerv: (index /*GLuint*/, pname /*GLenum*/, pointer /***void*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetVertexAttribOffset
    glHint: (target /*GLenum*/, mode /*GLenum*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glIsBuffer: (buffer /*GLuint*/) => /*GLboolean*/ {
        console.error('Not implemented.', getCallerName());
    },
    glIsContextLost: () => /*GLboolean*/ {
        console.error('Not implemented.', getCallerName());
    },
    glIsEnabled: (cap /*GLenum*/) => /*GLboolean*/ {
        console.error('Not implemented.', getCallerName());
    },
    glIsFramebuffer: (framebuffer /*GLuint*/) => /*GLboolean*/ {
        console.error('Not implemented.', getCallerName());
    },
    glIsProgram: (program /*GLuint*/) => /*GLboolean*/ {
        console.error('Not implemented.', getCallerName());
    },
    glIsRenderbuffer: (renderbuffer /*GLuint*/) => /*GLboolean*/ {
        console.error('Not implemented.', getCallerName());
    },
    glIsShader: (shader /*GLuint*/) => /*GLboolean*/ {
        console.error('Not implemented.', getCallerName());
    },
    glIsTexture: (texture /*GLuint*/) => /*GLboolean*/ {
        console.error('Not implemented.', getCallerName());
    },
    glLineWidth: (width /*GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glLinkProgram: (program /*GLuint*/) => {
        program = Names.objects[program];
        Jai.gl.linkProgram(program);
    },
    glMakeXRCompatible: () => /*GLboolean*/ {
        console.error('Not implemented.', getCallerName());
    },
    glPixelStorei: (pname /*GLenum*/, param /*GLint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glPolygonOffset: (factor /*GLfloat*/, units /*GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glReadPixels: (x /*GLint*/, y /*GLint*/, width /*GLsizei*/, height /*GLsizei*/, format /*GLenum*/, type /*GLenum*/, pixels /**void*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glRenderbufferStorage: (target /*GLenum*/, internalformat /*GLenum*/, width /*GLsizei*/, height /*GLsizei*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glSampleCoverage: (value /*GLfloat*/, invert /*GLboolean*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glScissor: (x /*GLint*/, y /*GLint*/, width /*GLsizei*/, height /*GLsizei*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glShaderSource: (shader /*GLuint*/, count /*GLsizei*/, str /***GLchar*/, length /**GLint*/) => {
        shader = Names.objects[shader];

        // build the strings
        let source = '';
        for (let i = 0; i < count; i++) {
            const strPointer = Helpers.u64[Number(str) / 8 + i];
            let strLength;
            if (length) {
                strLength = Helpers.u32[Number(length) / 4 + i];
            } else {
                strLength = Helpers.getNullStringLength(Number(strPointer));
            }

            const bytes = Helpers.u8.subarray(Number(strPointer), Number(strPointer) + strLength);
            source += Helpers.decoder.decode(bytes);
        }

        Jai.gl.shaderSource(shader, source);
    },
    glStencilFunc: (func /*GLenum*/, ref /*GLint*/, mask /*GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glStencilFuncSeparate: (face /*GLenum*/, func /*GLenum*/, ref /*GLint*/, mask /*GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glStencilMask: (mask /*GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glStencilMaskSeparate: (face /*GLenum*/, mask /*GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glStencilOp: (fail /*GLenum*/, zfail /*GLenum*/, zpass /*GLenum*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glStencilOpSeparate: (face /*GLenum*/, sfail /*GLenum*/, dpfail /*GLenum*/, dppass /*GLenum*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glTexImage2D: (target /*GLenum*/, level /*GLint*/, internalformat /*GLint*/, width /*GLsizei*/, height /*GLsizei*/, border /*GLint*/, format /*GLenum*/, type /*GLenum*/, pixels /**void*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glTexParameterf: (target /*GLenum*/, pname /*GLenum*/, param /*GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glTexParameteri: (target /*GLenum*/, pname /*GLenum*/, param /*GLint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glTexSubImage2D: (target /*GLenum*/, level /*GLint*/, xoffset /*GLint*/, yoffset /*GLint*/, width /*GLsizei*/, height /*GLsizei*/, format /*GLenum*/, type /*GLenum*/, pixels /**void*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniform1f: (location /*GLint*/, v0 /*GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniform1fv: (location /*GLint*/, count /*GLsizei*/, value /**GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniform1i: (location /*GLint*/, v0 /*GLint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniform1iv: (location /*GLint*/, count /*GLsizei*/, value /**GLint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniform2f: (location /*GLint*/, v0 /*GLfloat*/, v1 /*GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniform2fv: (location /*GLint*/, count /*GLsizei*/, value /**GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniform2i: (location /*GLint*/, v0 /*GLint*/, v1 /*GLint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniform2iv: (location /*GLint*/, count /*GLsizei*/, value /**GLint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniform3f: (location /*GLint*/, v0 /*GLfloat*/, v1 /*GLfloat*/, v2 /*GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniform3fv: (location /*GLint*/, count /*GLsizei*/, value /**GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniform3i: (location /*GLint*/, v0 /*GLint*/, v1 /*GLint*/, v2 /*GLint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniform3iv: (location /*GLint*/, count /*GLsizei*/, value /**GLint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniform4f: (location /*GLint*/, v0 /*GLfloat*/, v1 /*GLfloat*/, v2 /*GLfloat*/, v3 /*GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniform4fv: (location /*GLint*/, count /*GLsizei*/, value /**GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniform4i: (location /*GLint*/, v0 /*GLint*/, v1 /*GLint*/, v2 /*GLint*/, v3 /*GLint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniform4iv: (location /*GLint*/, count /*GLsizei*/, value /**GLint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniformMatrix2fv: (location /*GLint*/, count /*GLsizei*/, transpose /*GLboolean*/, value /**GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniformMatrix3fv: (location /*GLint*/, count /*GLsizei*/, transpose /*GLboolean*/, value /**GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniformMatrix4fv: (location /*GLint*/, count /*GLsizei*/, transpose /*GLboolean*/, value /**GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUseProgram: (program /*GLuint*/) => {
        program = Names.objects[program];
        Jai.gl.useProgram(program);
    },
    glValidateProgram: (program /*GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glVertexAttrib1f: (index /*GLuint*/, x /*GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glVertexAttrib2f: (index /*GLuint*/, x /*GLfloat*/, y /*GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glVertexAttrib3f: (index /*GLuint*/, x /*GLfloat*/, y /*GLfloat*/, z /*GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glVertexAttrib4f: (index /*GLuint*/, x /*GLfloat*/, y /*GLfloat*/, z /*GLfloat*/, w /*GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glVertexAttrib1fv: (index /*GLuint*/, v /**GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glVertexAttrib2fv: (index /*GLuint*/, v /**GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glVertexAttrib3fv: (index /*GLuint*/, v /**GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glVertexAttrib4fv: (index /*GLuint*/, v /**GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glVertexAttribPointer: (index /*GLuint*/, size /*GLint*/, type /*GLenum*/, normalized /*GLboolean*/, stride /*GLsizei*/, pointer /**void*/) => {
        Jai.gl.vertexAttribPointer(index, size, type, !!normalized, stride, Number(pointer));
    },
    glViewport: (x /*GLint*/, y /*GLint*/, width /*GLsizei*/, height /*GLsizei*/) => {
        Jai.gl.viewport(x, y, width, height);
    },
    glBeginQuery: (target /*GLenum*/, id /*GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glBeginTransformFeedback: (primitiveMode /*GLenum*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glBindBufferBase: (target /*GLenum*/, index /*GLuint*/, buffer /*GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glBindBufferRange: (target /*GLenum*/, index /*GLuint*/, buffer /*GLuint*/, offset /*GLintptr*/, size /*GLsizeiptr*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glBindSampler: (unit /*GLuint*/, sampler /*GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glBindTransformFeedback: (target /*GLenum*/, id /*GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glBindVertexArray: (array /*GLuint*/) => {
        if (array === 0) {
            Jai.gl.bindVertexArray(null);
        } else {
            array = Names.objects[array];
            Jai.gl.bindVertexArray(array);
        }
    },
    glBlitFramebuffer: (srcX0 /*GLint*/, srcY0 /*GLint*/, srcX1 /*GLint*/, srcY1 /*GLint*/, dstX0 /*GLint*/, dstY0 /*GLint*/, dstX1 /*GLint*/, dstY1 /*GLint*/, mask /*GLbitfield*/, filter /*GLenum*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glClearBufferiv: (buffer /*GLenum*/, drawbuffer /*GLint*/, value /**GLint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glClearBufferiv
    glClearBufferuiv: (buffer /*GLenum*/, drawbuffer /*GLint*/, value /**GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glClearBufferuiv
    glClearBufferfv: (buffer /*GLenum*/, drawbuffer /*GLint*/, value /**GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glClearBufferfv
    glClearBufferfi: (buffer /*GLenum*/, drawbuffer /*GLint*/, depth /*GLfloat*/, stencil /*GLint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glClearBufferfi
    glClientWaitSync: (sync /*GLsync*/, flags /*GLbitfield*/, timeout /*GLuint64*/) => /*GLenum*/ {
        console.error('Not implemented.', getCallerName());
    },
    glCompressedTexSubImage3D: (target /*GLenum*/, level /*GLint*/, xoffset /*GLint*/, yoffset /*GLint*/, zoffset /*GLint*/, width /*GLsizei*/, height /*GLsizei*/, depth /*GLsizei*/, format /*GLenum*/, imageSize /*GLsizei*/, data /**void*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glCopyBufferSubData: (readTarget /*GLenum*/, writeTarget /*GLenum*/, readOffset /*GLintptr*/, writeOffset /*GLintptr*/, size /*GLsizeiptr*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glCopyTexSubImage3D: (target /*GLenum*/, level /*GLint*/, xoffset /*GLint*/, yoffset /*GLint*/, zoffset /*GLint*/, x /*GLint*/, y /*GLint*/, width /*GLsizei*/, height /*GLsizei*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glCreateQueries: (target /*GLenum*/, n /*GLsizei*/, ids /**GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glCreateQuery
    glCreateSamplers: (n /*GLsizei*/, samplers /**GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glCreateSampler
    glCreateTransformFeedbacks: (n /*GLsizei*/, ids /**GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glCreateTransformFeedback
    glGenVertexArrays: (n /*GLsizei*/, arrays /**GLuint*/) => {
        arrays = Number(arrays);
        for (let i = 0; i < n; i++) {
            const array = Jai.gl.createVertexArray();
            const pointer = Names.addPointerObject(array);
            Helpers.u32[arrays / 4 + i] = pointer;
        }
    }, // glCreateVertexArray
    glDeleteQueries: (n /*GLsizei*/, ids /**GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glDeleteQuery
    glDeleteSamplers: (count /*GLsizei*/, samplers /**GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glDeleteSampler
    glDeleteSync: (sync /*GLsync*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glDeleteTransformFeedbacks: (n /*GLsizei*/, ids /**GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glDeleteTransformFeedback
    glDeleteVertexArrays: (n /*GLsizei*/, arrays /**GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glDeleteVertexArray
    glDrawArraysInstanced: (mode /*GLenum*/, first /*GLint*/, count /*GLsizei*/, instancecount /*GLsizei*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glDrawBuffers: (n /*GLsizei*/, bufs /**GLenum*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glDrawElementsInstanced: (mode /*GLenum*/, count /*GLsizei*/, type /*GLenum*/, indices /**void*/, instancecount /*GLsizei*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glDrawRangeElements: (mode /*GLenum*/, start /*GLuint*/, end /*GLuint*/, count /*GLsizei*/, type /*GLenum*/, indices /**void*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glEndQuery: (target /*GLenum*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glEndTransformFeedback: () => {
        console.error('Not implemented.', getCallerName());
    },
    glFenceSync: (condition /*GLenum*/, flags /*GLbitfield*/) => /*GLsync*/ {
        console.error('Not implemented.', getCallerName());
    },
    glFramebufferTextureLayer: (target /*GLenum*/, attachment /*GLenum*/, texture /*GLuint*/, level /*GLint*/, layer /*GLint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glGetActiveUniformBlockName: (program /*GLuint*/, uniformBlockIndex /*GLuint*/, bufSize /*GLsizei*/, length /**GLsizei*/, uniformBlockName /**GLchar*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glGetActiveUniformBlockiv: (program /*GLuint*/, uniformBlockIndex /*GLuint*/, pname /*GLenum*/, params /**GLint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetActiveUniformBlockParameter
    glGetActiveUniformsiv: (program /*GLuint*/, uniformCount /*GLsizei*/, uniformIndices /**GLuint*/, pname /*GLenum*/, params /**GLint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetActiveUniforms
    glGetBufferSubData: (target /*GLenum*/, offset /*GLintptr*/, size /*GLsizeiptr*/, data /**void*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glGetFragDataLocation: (program /*GLuint*/, name /**GLchar*/) => /*GLint*/ {
        console.error('Not implemented.', getCallerName());
    },
    glGetIndexedParameter: (target /*GLenum*/, index /*GLuint*/) => /*GLint*/ {
        console.error('Not implemented.', getCallerName());
    },
    glGetInternalformativ: (target /*GLenum*/, internalformat /*GLenum*/, pname /*GLenum*/, bufSize /*GLsizei*/, params /**GLint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetInternalformatParameter
    glGetQueryObjectiv: (id /*GLuint*/, pname /*GLenum*/, params /**GLint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetQuery
    glGetQueryObjectuiv: (id /*GLuint*/, pname /*GLenum*/, params /**GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetQuery
    glGetQueryiv: (target /*GLenum*/, pname /*GLenum*/, params /**GLint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetQueryParameter
    glGetSamplerParameteriv: (sampler /*GLuint*/, pname /*GLenum*/, params /**GLint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetSamplerParameter
    glGetSamplerParameterfv: (sampler /*GLuint*/, pname /*GLenum*/, params /**GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetSamplerParameter
    glGetSynciv: (sync /*GLsync*/, pname /*GLenum*/, bufSize /*GLsizei*/, length /**GLsizei*/, values /**GLint*/) => {
        console.error('Not implemented.', getCallerName());
    }, // glGetSyncParameter
    glGetTransformFeedbackVarying: (program /*GLuint*/, index /*GLuint*/, bufSize /*GLsizei*/, length /**GLsizei*/, size /**GLsizei*/, type /**GLenum*/, name /**GLchar*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glGetUniformBlockIndex: (program /*GLuint*/, uniformBlockName /**GLchar*/) => /*GLuint*/ {
        console.error('Not implemented.', getCallerName());
    },
    glGetUniformIndices: (program /*GLuint*/, uniformCount /*GLsizei*/, uniformNames /***GLchar*/, uniformIndices /**GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glInvalidateFramebuffer: (target /*GLenum*/, numAttachments /*GLsizei*/, attachments /**GLenum*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glInvalidateSubFramebuffer: (target /*GLenum*/, numAttachments /*GLsizei*/, attachments /**GLenum*/, x /*GLint*/, y /*GLint*/, width /*GLsizei*/, height /*GLsizei*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glIsQuery: (id /*GLuint*/) => /*GLboolean*/ {
        console.error('Not implemented.', getCallerName());
    },
    glIsSampler: (sampler /*GLuint*/) => /*GLboolean*/ {
        console.error('Not implemented.', getCallerName());
    },
    glIsSync: (sync /*GLsync*/) => /*GLboolean*/ {
        console.error('Not implemented.', getCallerName());
    },
    glIsTransformFeedback: (id /*GLuint*/) => /*GLboolean*/ {
        console.error('Not implemented.', getCallerName());
    },
    glIsVertexArray: (array /*GLuint*/) => /*GLboolean*/ {
        console.error('Not implemented.', getCallerName());
    },
    glPauseTransformFeedback: () => {
        console.error('Not implemented.', getCallerName());
    },
    glReadBuffer: (src /*GLenum*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glRenderbufferStorageMultisample: (target /*GLenum*/, samples /*GLsizei*/, internalformat /*GLenum*/, width /*GLsizei*/, height /*GLsizei*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glResumeTransformFeedback: () => {
        console.error('Not implemented.', getCallerName());
    },
    glSamplerParameteri: (sampler /*GLuint*/, pname /*GLenum*/, param /*GLint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glSamplerParameterf: (sampler /*GLuint*/, pname /*GLenum*/, param /*GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glTexImage3D: (target /*GLenum*/, level /*GLint*/, internalformat /*GLint*/, width /*GLsizei*/, height /*GLsizei*/, depth /*GLsizei*/, border /*GLint*/, format /*GLenum*/, type /*GLenum*/, pixels /**void*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glTexStorage2D: (target /*GLenum*/, levels /*GLsizei*/, internalformat /*GLenum*/, width /*GLsizei*/, height /*GLsizei*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glTexStorage3D: (target /*GLenum*/, levels /*GLsizei*/, internalformat /*GLenum*/, width /*GLsizei*/, height /*GLsizei*/, depth /*GLsizei*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glTexSubImage3D: (target /*GLenum*/, level /*GLint*/, xoffset /*GLint*/, yoffset /*GLint*/, zoffset /*GLint*/, width /*GLsizei*/, height /*GLsizei*/, depth /*GLsizei*/, format /*GLenum*/, type /*GLenum*/, pixels /**void*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glTransformFeedbackVaryings: (program /*GLuint*/, count /*GLsizei*/, varyings /***GLchar*/, bufferMode /*GLenum*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniform1ui: (location /*GLint*/, v0 /*GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniform1uiv: (location /*GLint*/, count /*GLsizei*/, value /**GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniform2uiv: (location /*GLint*/, count /*GLsizei*/, value /**GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniform3uiv: (location /*GLint*/, count /*GLsizei*/, value /**GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniform4uiv: (location /*GLint*/, count /*GLsizei*/, value /**GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniformBlockBinding: (program /*GLuint*/, uniformBlockIndex /*GLuint*/, uniformBlockBinding /*GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniformMatrix3x2fv: (location /*GLint*/, count /*GLsizei*/, transpose /*GLboolean*/, value /**GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniformMatrix4x2fv: (location /*GLint*/, count /*GLsizei*/, transpose /*GLboolean*/, value /**GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniformMatrix2x3fv: (location /*GLint*/, count /*GLsizei*/, transpose /*GLboolean*/, value /**GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniformMatrix4x3fv: (location /*GLint*/, count /*GLsizei*/, transpose /*GLboolean*/, value /**GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniformMatrix2x4fv: (location /*GLint*/, count /*GLsizei*/, transpose /*GLboolean*/, value /**GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glUniformMatrix3x4fv: (location /*GLint*/, count /*GLsizei*/, transpose /*GLboolean*/, value /**GLfloat*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glVertexAttribDivisor: (index /*GLuint*/, divisor /*GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glVertexAttribI4i: (index /*GLuint*/, x /*GLint*/, y /*GLint*/, z /*GLint*/, w /*GLint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glVertexAttribI4ui: (index /*GLuint*/, x /*GLuint*/, y /*GLuint*/, z /*GLuint*/, w /*GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glVertexAttribI4iv: (index /*GLuint*/, v /**GLint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glVertexAttribI4uiv: (index /*GLuint*/, v /**GLuint*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glVertexAttribIPointer: (index /*GLuint*/, size /*GLint*/, type /*GLenum*/, stride /*GLsizei*/, pointer /**void*/) => {
        console.error('Not implemented.', getCallerName());
    },
    glWaitSync: (sync /*GLsync*/, flags /*GLbitfield*/, timeout /*GLuint64*/) => {
        console.error('Not implemented.', getCallerName());
    },
};

const glfw = {
    glfwSetErrorCallback: (cbfun) => {
        return cbfun;
    },
    glfwInit: () => {
        return 1;
    },
    glfwGetPrimaryMonitor: () => {
        return NULL64;
    },
    glfwGetVideoMode: (monitor) => {
        return NULL64;
    },
    glfwWindowHint: (hint, value) => {

    },
    glfwCreateWindow: (width, height, title, monitor, share) => {
        return BigInt(1);
    },
    glfwSetWindowPos: (win, xpos, ypos) => {

    },
    glfwMakeContextCurrent: (win) => {
        
    },
    glfwGetProcAddress: () => {

    },
    glfwSetInputMode: (win, mode, value) => {
        
    },
    glfwSetScrollCallback: (win, cbfun) => {
        return cbfun
    },
    glfwSwapInterval: (interval) => {

    },
};

const getCallerName = () => {
    const e = new Error();
    const name = e.stack.split('\n')[2].split(' ')[5];
    return name;
};
