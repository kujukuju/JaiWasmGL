set_context :: (c: *Context) #foreign wasm;
write :: (text: *u8) #foreign wasm;
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

GLenum :: u32;
GLuint :: u32;
GLsizei :: u32;
GLchar :: u8;
GLint :: s32;
GLsizeiptr :: s64;
GLboolean :: bool;
GLbitfield :: u32;
GLfloat :: float32;

#scope_file

wasm :: #foreign_library "../libwasmstub";
