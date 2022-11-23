WasmBindings :: struct #type_info_procedures_are_void_pointers {
    set_context :: (c: *Context) #foreign wasm;
    write :: (text: *u8) #foreign wasm;
    wasm_print :: ($value: string) {
        wasm_print_ :: (value: *u8, count: int) #foreign wasm "wasm_print";

        pointer := alloc(value.count);
        defer free(pointer);
        memcpy(pointer, value.data, value.count);
        wasm_print_(pointer, value.count);
    }
    // wasm_alloc :: (size: int) -> *void {
    //     wasm_alloc_ :: (size: u32) -> u32 #foreign wasm "wasm_alloc";
    //     return xx wasm_alloc_(xx size);
    // }
    // wasm_free :: (pointer: *void) {
    //     wasm_free_ :: (pointer: u32) #foreign wasm "wasm_free";
    //     wasm_free_(xx pointer);
    // }
    glCreateShader :: (type: GLenum) -> GLuint #foreign wasm;
    glShaderSource :: (shader: GLuint, count: GLsizei, str: **GLchar, length: *GLint) #foreign wasm;
    glCompileShader :: (shader: GLuint) #foreign wasm;
    glGetShaderiv :: (shader: GLuint, pname: GLenum, params: *GLint) #foreign wasm;
    glCreateProgram :: () -> GLuint #foreign wasm;
    glAttachShader :: (program: GLuint, shader: GLuint) #foreign wasm;
    glLinkProgram :: (program: GLuint) #foreign wasm;
    glGetProgramiv :: (program: GLuint, pname: GLenum, params: *GLint) #foreign wasm;
    glDeleteShader :: (shader: GLuint) #foreign wasm;
    glGenVertexArrays :: (n: GLsizei, arrays: *GLuint) #foreign wasm;
    glGenBuffers :: (n: GLsizei, buffers: *GLuint) #foreign wasm;
    glBindVertexArray :: (array: GLuint) #foreign wasm;
    glBindBuffer :: (target: GLenum, buffer: GLuint) #foreign wasm;
    glBufferData :: (target: GLenum, size: GLsizeiptr, data: *void, usage: GLenum) #foreign wasm;
    glVertexAttribPointer :: (index: GLuint, size: GLint, type: GLenum, normalized: GLboolean, stride: GLsizei, pointer: *void) #foreign wasm;
    glEnableVertexAttribArray :: (index: GLuint) #foreign wasm;
    glClear :: (mask: GLbitfield) #foreign wasm;
    glClearColor :: (red: GLfloat, green: GLfloat, blue: GLfloat, alpha: GLfloat) #foreign wasm;
    glUseProgram :: (program: GLuint) #foreign wasm;
    glDrawElements :: (mode: GLenum, count: GLsizei, type: GLenum, indices: *void) #foreign wasm;
    glDeleteVertexArrays :: (n: GLsizei, arrays: *GLuint) #foreign wasm;
    glDeleteBuffers :: (n: GLsizei, buffers: *GLuint) #foreign wasm;
    glDeleteProgram :: (program: GLuint) #foreign wasm;
    glViewport :: (x: GLint, y: GLint, width: GLsizei, height: GLsizei) #foreign wasm;
}

bindings: WasmBindings;
using bindings;

memcpy :: (dest: *u8, src: *u8, count: int) {
    for i: 0..count - 1 {
        dest[i] = src[i];
    }
}

GLenum :: u32;
GLuint :: u32;
GLsizei :: u32;
GLchar :: u8;
GLint :: s32;
GLsizeiptr :: s64;
GLboolean :: bool;
GLbitfield :: u32;
GLfloat :: float32;

Replacements :: struct {
    print :: (format_string: string, args: .. Any) -> bytes_printed: s64 #foreign wasm;
}

#scope_file

wasm :: #foreign_library "../libwasmstub";
