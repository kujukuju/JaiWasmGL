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

const Jai = {
    // TODO get rid of this if I can
    instance: null,
    context: null,
    gl: null,
    initialize: (canvas) => {
        WebAssembly.instantiateStreaming(fetch('/wasm/main32.wasm'), {
            'env': make_environment(std, demo)
        }).then(wasm => {
            const instance = wasm.instance;
            Jai.instance = wasm.instance;

            Memory.heap = wasm.instance.exports.memory;
            Memory.rebuildAccess();
        
            instance.exports.main(0, NULL64);

            // TODO im not really sure technically whats a valid function name in jai, js, and both. should consider this then spit out warnings for incompat.
            const validRegex = new RegExp('^[a-zA-Z0-9][a-zA-Z0-9_]+_[0-9a-z]+$');

            for (const name in instance.exports) {
                if (validRegex.test(name)) {
                    const nameParts = name.split('_');
                    nameParts.length -= 1;
                    const validName = nameParts.join('_');
                    
                    if (Jai[validName]) {
                        console.warn('Jai binding already exists. ', validName, Jai[validName]);
                        continue;
                    }

                    console.log('valid name ', validName, instance.exports[name]);
    
                    Jai[validName] = instance.exports[name].bind(this, Jai.context);
                }
            }

            // const update = find_name_by_regexp(w.instance.exports, "update");
        
            initialized();
        }).catch(console.error);

        Jai.gl = canvas.getContext('webgl2') || canvas.getContext('webgl');
        if (!Jai.gl) {
            console.error('Could not initialize webgl context.');
        }
    },
}

const MIN_MEMORY_BYTES = 256;

const ACCESS_FREE = 0;
const ACCESS_DIVIDED = 1;
const ACCESS_CLAIMED = 2;

const Memory = {
    heap: null,
    // a number that represents if its available, divided with a free child, divided with no free child, or claimed
    access: [],
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
        const arrayRemoveFirst = (array) => {
            for (let i = 0; i < array.length - 1; i++) {
                array[i] = array[i + 1];
            }
        
            array.length--;
        };

        bytes = Math.max(bytes, MIN_MEMORY_BYTES);

        const size = Memory.nextPowerOfTwo(bytes);
        // its assumed that it should at least fit inside the memory
        while (size > Memory.heap.buffer.byteLength) {
            Memory.grow();
        }

        // keep growing until available memory is found
        while (true) {
            const depth = Memory.getDepthForBytes(size);

            // depth, offset
            // TODO dont allocate this memory every time
            const indexRequests = [];
            indexRequests.push(0);

            while (indexRequests.length > 0) {
                // pop from last and push to last
                const currentIndex = indexRequests[indexRequests.length - 1];
                const currentDepth = Memory.getDepthForIndex(currentIndex);
                indexRequests.length -= 1;

                const currentAccessValue = Memory.access[currentIndex];
                const currentAccessState = Memory.getAccessStateFromValue(currentAccessValue);

                // console.log('desired depth: ' + depth);
                // console.log('position: ' + currentDepth + ', ' + (currentIndex - Memory.getIndexForDepth(currentDepth)) + ' = ' + currentIndex);
                // console.log('information: ' + currentAccessState + ', ' + Memory.getAccessAvailableFromValue(currentAccessValue));

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
                        indexRequests.push(childIndexLeft);
                    }
                } else if (currentAccessState === ACCESS_DIVIDED) {
                    const currentAccessAvailable = Memory.getAccessAvailableFromValue(currentAccessValue);
                    console.log('Comparing size: ', currentAccessAvailable, size);
                    if (currentAccessAvailable >= size) {
                        // check both children for access
                        const offset = currentIndex - Memory.getIndexForDepth(currentDepth);
                        const childIndexLeft = Memory.getIndexForDepth(currentDepth + 1) + offset * 2;

                        // its best to not split contiguous memory, so go that path first
                        const leftChildAccessValue = Memory.access[childIndexLeft];
                        const leftChildAccessState = Memory.getAccessStateFromValue(leftChildAccessValue);
                        if (leftChildAccessState === ACCESS_DIVIDED) {
                            const leftChildAccessAvailable = Memory.getAccessAvailableFromValue(leftChildAccessValue);
                            if (leftChildAccessAvailable >= size) {
                                indexRequests.push(childIndexLeft);
                                continue;
                            }
                        }

                        const rightChildAccessValue = Memory.access[childIndexLeft + 1];
                        const rightChildAccessState = Memory.getAccessStateFromValue(rightChildAccessValue);
                        if (rightChildAccessState === ACCESS_DIVIDED) {
                            const rightChildAccessAvailable = Memory.getAccessAvailableFromValue(rightChildAccessValue);
                            if (rightChildAccessAvailable >= size) {
                                indexRequests.push(childIndexLeft + 1);
                                continue;
                            }
                        }

                        // now either the left one is completely free, or the right one is completely free
                        // and we know the size is correct because it's gotten to this point
                        if (leftChildAccessState === ACCESS_FREE) {
                            indexRequests.push(childIndexLeft);
                        } else {
                            indexRequests.push(childIndexLeft + 1);
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

            console.log('found ', leftChildAvailable, rightChildAvailable);

            Memory.access[parentIndex] = Memory.createAccessValue(ACCESS_DIVIDED, Math.max(leftChildAvailable, rightChildAvailable));

            currentIndex = parentIndex;
            currentDepth = parentDepth;
            parentDepth = currentDepth - 1;
        }
    },
    getParentIndexFromChild: (index) => {
        
    },
    free: (pointer) => {
        
    },
    createAccessValue: (state, available) => {
        return (state << 28) | available;
    },
    getAccessStateFromValue: (value) => {
        return (value & 0xF0000000) >> 28;
    },
    getAccessAvailableFromValue: (value) => {
        return (value & 0x0FFFFFFF);
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
        return index * MIN_MEMORY_BYTES;
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
        const currentPageCount = Memory.heap.buffer.byteLength / 0x10000;
        if (Math.floor(currentPageCount) !== currentPageCount) {
            console.error('Cannot have fractional page counts. If this ever happens, you need to manually instantiate the size of the original memory buffer to be a power of 65536.');
            return;
        }

        // we only double buffer size
        Memory.heap.grow(currentPageCount);
        Memory.rebuildAccess();
    },
    getChunkSizeForDepth: (depth) => {
        return Memory.heap.buffer.byteLength / Memory.getLengthForDepth(depth);
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
        return Math.round(Math.log2(Memory.heap.buffer.byteLength / bytes));
    },
    rebuildAccess: () => {
        // if the most granular level of access will fit N entries
        // then the size of access is always N + N / 2 + N / 4 + N / 8 ...
        // so N * 2 - 1
        const memoryEntries = Memory.heap.buffer.byteLength / MIN_MEMORY_BYTES;
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
                Memory.access[0] = Memory.createAccessValue(ACCESS_DIVIDED, Memory.heap.buffer.byteLength / 2);
            } else {
                Memory.access[0] = Memory.createAccessValue(ACCESS_FREE, Memory.heap.buffer.byteLength);
            }
        }
    },
};

const std = {
    'write': (fd, buf, count) => {
        let log = undefined;
        switch (fd) {
            case 1: log = console.log;   break;
            case 2: log = console.error; break;
            default: {
                console.error("write: Unsupported file descriptor "+fd);
                return -EBADF;
            }
        }
        const buffer = Jai.instance.exports.memory.buffer;
        const bytes = new Uint8Array(buffer, Number(buf), Number(count));
        let text = new TextDecoder().decode(bytes);
        let index = text.indexOf('\n');
        while (index >= 0) {
            output_buffer += text.slice(0, index);
            text = text.slice(index + 1);
            log(output_buffer);
            output = "";
            index = text.indexOf('\n');
        }
        if (text.length > 0) output_buffer += text;
        return count;
    },
    'memset': (s, c, n) => {
        const buffer = Jai.instance.exports.memory.buffer;
        const bytes = new Uint8Array(buffer, Number(s), Number(n));
        bytes.fill(c);
        return s;
    },
    'fabs': Math.abs,
    'powf': Math.pow,
    'set_context': (context) => Jai.context = BigInt(context),
    'sigemptyset': () => {},
    'sigaction': () => {},
    'glCreateShader': (type) => {
        gl.createShader(type);
        return 0;
    },
    'glShaderSource': (shader, count, str, length) => {
        console.log(shader, count, str, length);
        gl.shaderSource(shader, str[0]);
    },
    'glCompileShader': (shader) => {
        gl.compilerShader(shader);
    },
    'glGetShaderiv': (shader, pname, params) => {
        params[0] = gl.getShaderParameter(shader, pname);
    },
    'glCreateProgram': ()  => {
        return gl.createProgram();
    },
    'glAttachShader': (program, shader) => {
        gl.attachShader(prgram, shader);
    },
    'glLinkProgram': (program) => {
        gl.linkProgram(program);
    },
    'glGetProgramiv': (program, pname, params) => {
        params[0] = gl.getProgramParameter(program, pname);
    },
    'glDeleteShader': (shader) => {
        gl.deleteShader(shader);
    },
    'glGenVertexArrays': (n, arrays) => {
        // TODO assert in jai n must be 1
        // this is webgl2 only
        arrays[0] = gl.createVertexArray();
    },
    'glGenBuffers': (n, buffers) => {
        // TODO assert in jai n must be 1
        buffers[0] = gl.createBuffer();
    },
    'glBindVertexArray': (array) => {
        gl.bindVertexArray(array);
    },
    'glBindBuffer': (target, buffer) => {
        gl.bindBuffer(target, buffer);
    },
    'glBufferData': (target, size, data, usage) => {
        // console.error('idk');
        gl.bufferData(target, data, usage, 0);
        // gl.bufferData(target, size, usage);
    },
    'glVertexAttribPointer': (index, size, type, normalized, stride, pointer) => {
        gl.vertexAttribPointer(index, size, type, normalized, stride, 0);
    },
    'glEnableVertexAttribArray': (index) => {
        gl.enableVertexAttribArray(index);
    },
    'glClear': (mask) => {
        gl.clear(mask);
    },
    'glClearColor': (red, green, blue, alpha) => {
        gl.clearColor(red, green, blue, alpha);
    },
    'glUseProgram': (program) => {
        gl.useProgram(program);
    },
    'glDrawElements': (mode, count, type, indices) => {
        gl.drawElements(mode, count, type, indices);
    },
    'glDeleteVertexArrays': (n, arrays) => {
        // TODO in jai assert n is 1
        gl.deleteVertexArray(array[0]);
    },
    'glDeleteBuffers': (n, buffers) => {
        // TODO in jai assert n is 1
        gl.deleteBuffer(buffers[0]);
    },
    'glDeleteProgram': (program) => {
        gl.deleteProgram(program);
    },
    'glViewport': (x, y, width, height) => {
        gl.viewport(x, y, width, height);
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
