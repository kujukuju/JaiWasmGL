WasmBindings :: struct #type_info_procedures_are_void_pointers {
    set_context :: (c: *Context) #foreign #compiler;
    write :: (text: *u8) #foreign #compiler;
    wasm_print :: ($value: string) {
        wasm_print_ :: (value: *u8, count: int) #foreign #compiler "wasm_print";

        pointer := alloc(value.count);
        defer free(pointer);
        memcpy(pointer, value.data, value.count);
        wasm_print_(pointer, value.count);
    }
    // wasm_alloc :: (size: int) -> *void {
    //     wasm_alloc_ :: (size: u32) -> u32 #foreign #compiler "wasm_alloc";
    //     return xx wasm_alloc_(xx size);
    // }
    // wasm_free :: (pointer: *void) {
    //     wasm_free_ :: (pointer: u32) #foreign #compiler "wasm_free";
    //     wasm_free_(xx pointer);
    // }
    glCreateShader :: (type: GLenum) -> GLuint #foreign #compiler;
    glShaderSource :: (shader: GLuint, count: GLsizei, str: **GLchar, length: *GLint) #foreign #compiler;
    glCompileShader :: (shader: GLuint) #foreign #compiler;
    glGetShaderiv :: (shader: GLuint, pname: GLenum, params: *GLint) #foreign #compiler;
    glCreateProgram :: () -> GLuint #foreign #compiler;
    glAttachShader :: (program: GLuint, shader: GLuint) #foreign #compiler;
    glLinkProgram :: (program: GLuint) #foreign #compiler;
    glGetProgramiv :: (program: GLuint, pname: GLenum, params: *GLint) #foreign #compiler;
    glDeleteShader :: (shader: GLuint) #foreign #compiler;
    glGenVertexArrays :: (n: GLsizei, arrays: *GLuint) #foreign #compiler;
    glGenBuffers :: (n: GLsizei, buffers: *GLuint) #foreign #compiler;
    glBindVertexArray :: (array: GLuint) #foreign #compiler;
    glBindBuffer :: (target: GLenum, buffer: GLuint) #foreign #compiler;
    glBufferData :: (target: GLenum, size: GLsizeiptr, data: *void, usage: GLenum) #foreign #compiler;
    glVertexAttribPointer :: (index: GLuint, size: GLint, type: GLenum, normalized: GLboolean, stride: GLsizei, pointer: *void) #foreign #compiler;
    glEnableVertexAttribArray :: (index: GLuint) #foreign #compiler;
    glClear :: (mask: GLbitfield) #foreign #compiler;
    glClearColor :: (red: GLfloat, green: GLfloat, blue: GLfloat, alpha: GLfloat) #foreign #compiler;
    glUseProgram :: (program: GLuint) #foreign #compiler;
    glDrawElements :: (mode: GLenum, count: GLsizei, type: GLenum, indices: *void) #foreign #compiler;
    glDeleteVertexArrays :: (n: GLsizei, arrays: *GLuint) #foreign #compiler;
    glDeleteBuffers :: (n: GLsizei, buffers: *GLuint) #foreign #compiler;
    glDeleteProgram :: (program: GLuint) #foreign #compiler;
    glViewport :: (x: GLint, y: GLint, width: GLsizei, height: GLsizei) #foreign #compiler;
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
    #import "Basic";

    print_to_builder :: (builder : *String_Builder, format_string : string, args: .. Any) -> bool {
        implicit_index_cursor := 0;

        cursor := 0;
        printed := 0;
        while cursor < format_string.count {
            c := format_string.data[cursor];
            if c != #char "%" {
                cursor += 1;
                continue;
            }

            append(builder, format_string.data + printed, cursor - printed);
            cursor += 1;  // Skip the %.

            value := implicit_index_cursor; // Will get bumped below.

            if cursor < format_string.count {
                next := format_string.data[cursor];
                if next == #char "%" {  // Double-percent means to actually output a percent.
                    append(builder, "%");
                    cursor += 1;
                    printed = cursor;
                    continue;
                }

                if is_digit(next) {
                    if next == #char "0" {  // %00 outputs the empty string; %0 is like a regular %.
                        cursor += 1;
                        if (cursor < format_string.count) && (format_string.data[cursor] == #char "0") {
                            // Empty string.
                            cursor += 1;
                            printed = cursor;
                            continue;
                        } else {
                            // Fall through and do the thing.
                        }
                    } else {
                        // @Robustness: We probably want to test that parse_number does not overflow!
                        cursor, value = parse_number(format_string, cursor);
                        value -= 1;      // Arguments are 0-based indices from here on.
                    }
                }
            }


            if value < 0 {
                if context.print_style.log_runtime_errors {
                    log_error("Invalid negative %% index % in the format string at character %. Skipping.\n", value, cursor);
                }

                implicit_index_cursor = 0;
                printed = cursor;
                continue;
            }

            if value >= args.count {
                if context.print_style.log_runtime_errors {
                    do_free := false;
                    arguments_string := "(There are no insertable arguments.)";
                    if value == 1 {
                        arguments_string = "(There is only 1 insertable argument.)";
                    } else {
                        arguments_string = sprint("(There are only % insertable arguments.)", value);
                        do_free = true;
                    }
                    
                    log_error("Invalid %% index % in the format string \"%\" at character %. %\n", value+1, format_string, cursor, arguments_string);
                    if do_free free(arguments_string);
                }

                implicit_index_cursor = 0;
                printed = cursor;
                continue;
            }

            print_item_to_builder(builder, args[value], false);
            implicit_index_cursor = value + 1;

            printed = cursor;   // Next time we append, start here.
        }

        append(builder, format_string.data + printed, cursor - printed);

        if builder.failed return false;
        return true;
    } @PrintLike
}

#scope_file

// wasm :: #foreign_library "../libwasmstub";
