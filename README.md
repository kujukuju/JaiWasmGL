## Jai Wasm GL

See the example folder for how to use.

### Jai Exports
Jai functions are automatically added into the `Jai` struct in javascript.

### Javascript Exports
To import a javascript function into jai, mark it as `#foreign #compiler`.
From javascript, all functions passed into `Jai.initialize` in the `exported` object will linked to jai.

### Memory Notes
Wasm by default has a 64 kb stack, and a heap size of less than 64 kb. The initialization code in the `compiler.jai` file increases this to a 4 mb stack, and the code in `jai.js` increases the heap size to 32 mb.

Wasm requires you to implement your own heap allocator. I've implemented an allocator based on a contiguous binary tree structure, but to avoid lots of depth travel, the minimum allocation size is by default 32kb. This is probably optimal unless you need to do a ton of tiny allocations. You can change this in the javascript code.

Wasm also by default allocates the stack in the middle of the contiguous memory block you're provided. If you ever overflow your stack you'll start automatically overriding the global function table in the memory block without any error. The `compiler.jai` code sets the stack to be the first block in the memory so if you ever overflow it will appropriately error and crash.

### Notes
Almost all the javasript webgl functions are added into the bindings object. However, most of these functions are not yet implemented. I only have implemented the bare minimum to render a triangle.