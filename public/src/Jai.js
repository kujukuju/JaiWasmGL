// TODO replace
function make_environment(...envs) {
    return new Proxy(envs, {
        get(target, prop, receiver) {
            for (const env of envs) {
                if (env.hasOwnProperty(prop)) {
                    return env[prop];
                }
            }
            return (...args) => {console.error('NOT IMPLEMENTED: ' + prop, args)}
        }
    });
}

const NULL64 = 0n;
const EBADF = 9;

// 16 mb
const DEFAULT_HEAP = 0x1000000;

if (DEFAULT_HEAP & (DEFAULT_HEAP - 1) !== 0) {
    console.error('The default heap size must be a power of two.');
}

const Jai = {
    // TODO get rid of this if I can
    instance: null,
    context: null,
    gl: null,
    initialize: (canvas) => {
        Jai.gl = canvas.getContext('webgl2') || canvas.getContext('webgl');
        if (!Jai.gl) {
            console.error('Could not initialize webgl context.');
        }

        WebAssembly.instantiateStreaming(fetch('/wasm/main32.wasm'), {
            'env': make_environment(std, demo)
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
        
            // console.log(Jai.instance.exports.main);
            Jai.instance.exports.main(0, BigInt(0));

            // TODO im not really sure technically whats a valid function name in jai, js, and both. should consider this then spit out warnings for incompat.
            const validRegex = new RegExp('^[a-zA-Z0-9][a-zA-Z0-9_]+_[0-9a-z]+$');

            for (const name in Jai.instance.exports) {
                if (validRegex.test(name)) {
                    const nameParts = name.split('_');
                    nameParts.length -= 1;
                    const validName = nameParts.join('_');
                    
                    if (Jai[validName]) {
                        console.warn('Jai binding already exists. ', validName, Jai[validName]);
                        continue;
                    }

                    console.log('valid name ', validName, Jai.instance.exports[name]);
    
                    Jai[validName] = Jai.instance.exports[name].bind(this, Jai.context);
                }
            }

            Jai.resize(window.innerWidth, window.innerHeight);

            // const update = find_name_by_regexp(w.instance.exports, "update");
        
            initialized();
        }).catch(console.error);
    },
}

// maybe this is too large? im not sure
// but its definitely faster for the program to just grab a block and allocated it rather than find the most accurate size
// if your program is for some reason allocating a ton of tiny blocks, this will need to be reduced
// but that seems less likely than large blocks
const MIN_MEMORY_BYTES = 32768;

if (MIN_MEMORY_BYTES & (MIN_MEMORY_BYTES - 1) !== 0) {
    console.error('The minimum memory byte block size must be a power of two.');
}

const ACCESS_FREE = 0;
const ACCESS_DIVIDED = 1;
const ACCESS_CLAIMED = 2;

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

                // console.log('desired depth: ' + depth);
                // console.log('position: ' + currentDepth + ', ' + (currentIndex - Memory.getIndexForDepth(currentDepth)) + ' = ' + currentIndex);
                // console.log('information: ' + currentAccessState + ', ' + Memory.getAccessAvailableFromValue(currentAccessValue));

                if (currentAccessState === ACCESS_FREE) {
                    if (currentDepth === depth) {
                        Memory.access[currentIndex] = Memory.createAccessValue(ACCESS_CLAIMED, 0);
                        Memory.rebuildParentAvailableSize(currentIndex);

                        console.log('Claiming ', Memory.getPointerFromIndex(currentIndex));
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
        console.log('Freeing ', pointer);
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

        console.error('Unable to find claimed memory to free. ', pointer);
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

        // idk what the old purpoes of this was so im leaving it in case I messed up bc im tired
        // 0 = 0  1 = 1 - 1 = 0
        // 1 = 1  2 = 2 - 1 = 1
        // 2 = 1  3 = 2 - 1 = 1
        // 3 = 3  4 = 4 - 1 = 3
        // 4 = 3  5 = 4 - 1 = 3
        // 5 = 3  6 = 4 - 1 = 3
        // 6 = 3  7 = 4 - 1 = 3
        // 7 = 7  8 = 8 - 1 = 7
        // (previous power of two of (value + 1)) - 1

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
        // Memory.heapSize = Math.floor(Memory.allocated.buffer.byteLength / 0x10000);

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

const Pointers = {
    available: [],
    // the first object should already exist because a lot of gl names use 0 as null and this uses indices as names
    objects: [null],
    availableCount: 0,
    addPointerObject: (object) => {
        if (Pointers.availableCount === 0) {
            Pointers.objects.push(object);
            return Pointers.objects.length - 1;
        }

        const index = Pointers.available[Pointers.availableCount - 1];
        Pointers.availableCount -= 1;

        Pointers.objects[index] = object;
        return index;
    },
    freePointerObject: (pointer) => {
        Pointers.available[Pointers.availableCount] = pointer;
        Pointers.availableCount += 1;
    },
};

const Helpers = {
    writeData: (pointer, data) => {
        if (Number.isInteger(data)) {
            const ints = new Int32Array(Memory.allocated.buffer, Number(pointer), 1);
            ints[0] = data;
        } else if (data === true) {
            const ints = new Int32Array(Memory.allocated.buffer, Number(pointer), 1);
            ints[0] = 1;
        } else if (data === false) {
            const ints = new Int32Array(Memory.allocated.buffer, Number(pointer), 1);
            ints[0] = 0;
        }
    },
};

const std = {
    'memset': (dest, value, length) => {
        const bytes = new Uint8Array(Memory.allocated.buffer, Number(dest), Number(length));
        bytes.fill(value);
        return dest;
    },
    'SetUnhandledExceptionFilter': value => BigInt(0),
    'SymSetOptions': value => 0,
    'SymInitialize': value => 0,
    'fabs': Math.abs,
    'powf': Math.pow,
    'set_context': (context) => Jai.context = BigInt(context),
    'sigemptyset': () => {},
    'sigaction': () => {},
    'malloc': (size) => {
        console.log('requesting ', size);
        return BigInt(Memory.alloc(Number(size)));
    },
    'realloc': (pointer, size) => {
        if (!pointer) {
            return BigInt(Memory.alloc(Number(size)));
        }
        // TODO try not to move the content
        // TODO using typed array copy might be faster if I can guarantee itll never have to copy right to left
        // pointer = Number(pointer);
        const oldSize = Memory.free(Number(pointer));
        const newPointer = BigInt(Memory.alloc(Number(size)));

        console.log('freeing ', pointer);

        if (newPointer === pointer) {
            // no need to copy data, yay
            return newPointer;
        } else if (newPointer <= pointer) {
            // copy left to right
            for (let i = 0; i < oldSize; i++) {
                Memory.allocated.buffer[newPointer + i] = Memory.allocated.buffer[pointer + i];
            }

            return newPointer;
        } else {
            // copy right to left
            for (let i = oldSize - 1; i >= 0; i--) {
                Memory.allocated.buffer[newPointer + i] = Memory.allocated.buffer[pointer + i];
            }

            return newPointer;
        }
    },
    'free': (pointer) => {
        Memory.free(Number(pointer));
    },
    'memcpy': (dest, src, length) => {
        const write = new Uint8Array(Memory.allocated.buffer, Number(dest), Number(length));
        const read = new Uint8Array(Memory.allocated.buffer, Number(src), Number(length));
        write.set(read);
        return dest;
    },
    'EnterCriticalSection': () => {/*does nothing since we dont require thread sync, probably*/},
    'WriteFile': (handle, buffer, buffer_length, written_result, overlapped) => {
        // TODO handle handle

        const bytes = new Uint8Array(Memory.allocated.buffer, Number(buffer), Number(buffer_length));
        const string = new TextDecoder().decode(bytes);
        console.log(string);

        return 1;
    },
    'LeaveCriticalSection': () => {/*does nothing since we dont require thread sync, probably*/},
    'glCreateShader': (type) => {
        const shader = Jai.gl.createShader(type);
        const pointer = Pointers.addPointerObject(shader);
        return pointer;
    },
    'glShaderSource': (shader, count, str, length) => {
        shader = Pointers.objects[shader];
        // TODO handle null terminated strings
        // build the strings
        let source = '';
        const strPointerList = new BigUint64Array(Memory.allocated.buffer, Number(str), count);
        const lengthList = new Uint32Array(Memory.allocated.buffer, Number(length), count);
        for (let i = 0; i < count; i++) {
            const strPointer = strPointerList[i];
            const length = lengthList[i];

            const bytes = new Uint8Array(Memory.allocated.buffer, Number(strPointer), length);
            const string = new TextDecoder().decode(bytes);

            source += string;
        }

        Jai.gl.shaderSource(shader, source);
    },
    'glCompileShader': (shader) => {
        shader = Pointers.objects[shader];
        Jai.gl.compileShader(shader);
    },
    'glGetShaderiv': (shader, pname, params) => {
        shader = Pointers.objects[shader];
        const data = Jai.gl.getShaderParameter(shader, pname);
        Helpers.writeData(params, data);
    },
    'glGetShaderInfoLog': (shader, bufSize, length, infoLog) => {
        shader = Pointers.objects[shader];
        const message = Jai.gl.getShaderInfoLog(shader);
        console.log('wahtever ', message); // TODO
    },
    'glCreateProgram': ()  => {
        const program = Jai.gl.createProgram();
        const pointer = Pointers.addPointerObject(program);
        return pointer;
    },
    'glAttachShader': (program, shader) => {
        program = Pointers.objects[program];
        shader = Pointers.objects[shader];
        Jai.gl.attachShader(program, shader);
    },
    'glLinkProgram': (program) => {
        program = Pointers.objects[program];
        Jai.gl.linkProgram(program);
    },
    'glGetProgramiv': (program, pname, params) => {
        program = Pointers.objects[program];
        const data = Jai.gl.getProgramParameter(program, pname);
        Helpers.writeData(params, data);
    },
    'glDeleteShader': (shader) => {
        shader = Pointers.objects[shader];
        Jai.gl.deleteShader(shader);
    },
    'glGenVertexArrays': (n, arrays) => {
        // this is webgl2 only
        console.log(arrays);
        const arrayPointers = new Uint32Array(Memory.allocated.buffer, Number(arrays), n);
        for (let i = 0; i < n; i++) {
            const array = Jai.gl.createVertexArray();
            const pointer = Pointers.addPointerObject(array);
            arrayPointers[i] = pointer;
        }
    },
    'glGenBuffers': (n, buffers) => {
        const bufferPointers = new Uint32Array(Memory.allocated.buffer, Number(buffers), n);
        for (let i = 0; i < n; i++) {
            const buffer = Jai.gl.createBuffer();
            const pointer = Pointers.addPointerObject(buffer);
            bufferPointers[i] = pointer;
            console.log('buffer pointer ', pointer);
        }
    },
    'glBindVertexArray': (array) => {
        if (array === 0) {
            Jai.gl.bindVertexArray(null);
        } else {
            array = Pointers.objects[array];
            Jai.gl.bindVertexArray(array);
        }
    },
    'glBindBuffer': (target, buffer) => {
        if (buffer === 0) {
            Jai.gl.bindBuffer(target, null);
        } else {
            console.log('binding ', buffer);
            buffer = Pointers.objects[buffer];
            Jai.gl.bindBuffer(target, buffer);
        }
    },
    'glBufferData': (target, size, data, usage) => {
        // console.error('idk');
        const bytes = new Uint8Array(Memory.allocated.buffer, Number(data), Number(size));
        Jai.gl.bufferData(target, bytes, usage);
    },
    'glVertexAttribPointer': (index, size, type, normalized, stride, pointer) => {
        console.log(index, size, type, normalized, stride, pointer);
        Jai.gl.vertexAttribPointer(index, size, type, !!normalized, stride, Number(pointer));
    },
    'glEnableVertexAttribArray': (index) => {
        Jai.gl.enableVertexAttribArray(index);
    },
    'glClear': (mask) => {
        Jai.gl.clear(mask);
    },
    'glClearColor': (red, green, blue, alpha) => {
        Jai.gl.clearColor(red, green, blue, alpha);
    },
    'glUseProgram': (program) => {
        program = Pointers.objects[program];
        Jai.gl.useProgram(program);
    },
    'glDrawElements': (mode, count, type, indices) => {
        Jai.gl.drawElements(mode, count, type, Number(indices));
    },
    // 'glDeleteVertexArrays': (n, arrays) => {
    //     // TODO in jai assert n is 1
    //     Jai.gl.deleteVertexArray(array[0]);
    // },
    // 'glDeleteBuffers': (n, buffers) => {
    //     // TODO in jai assert n is 1
    //     Jai.gl.deleteBuffer(buffers[0]);
    // },
    // 'glDeleteProgram': (program) => {
    //     Jai.gl.deleteProgram(program);
    // },
    'glViewport': (x, y, width, height) => {
        Jai.gl.viewport(x, y, width, height);
    },
    'glGetProgramInfoLog': (program, bufSize, length, infoLog) => {
        program = Pointers.objects[program];
        const message = Jai.gl.getProgramInfoLog(program);
        console.log('wahtever ', message); // TODO
    },
    'glGetAttribLocation': (program, name) => {
        program = Pointers.objects[program];
        name = Number(name);
        const bytes = new Uint8Array(Memory.allocated.buffer);
        let string = '';
        while (bytes[name] !== 0) {
            string += String.fromCharCode(bytes[name]);
            name += 1;
        }
        return Jai.gl.getAttribLocation(program, string);
    },
};

const demo = {
    'render': (pixels_ptr, width, height) => {
        const buffer = Jai.instance.exports.memory.buffer;
        app.width = width;
        app.height = height;
        const pixels = new Uint8ClampedArray(buffer, Number(pixels_ptr), app.width*app.height*4);
        ctx.putImageData(new ImageData(pixels, app.width, app.height), 0, 0);
    },
};
