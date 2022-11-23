// these are the callable js functions

#if defined(WIN32) || defined(_WIN32)
#define EXPORT __declspec(dllexport)
#elif
#define EXPORT
#endif


EXPORT void set_context(void) {}
EXPORT void alloc(void) {}
EXPORT void write(void) {}
EXPORT void print(void) {}
EXPORT void sprint(void) {}
EXPORT void wasm_print(void) {}
EXPORT void wasm_alloc(void) {}
EXPORT void wasm_free(void) {}
EXPORT void glCreateShader(void) {}
EXPORT void glShaderSource(void) {}
EXPORT void glCompileShader(void) {}
EXPORT void glGetShaderiv(void) {}
EXPORT void glCreateProgram(void) {}
EXPORT void glAttachShader(void) {}
EXPORT void glLinkProgram(void) {}
EXPORT void glGetProgramiv(void) {}
EXPORT void glDeleteShader(void) {}
EXPORT void glGenVertexArrays(void) {}
EXPORT void glGenBuffers(void) {}
EXPORT void glBindVertexArray(void) {}
EXPORT void glBindBuffer(void) {}
EXPORT void glBufferData(void) {}
EXPORT void glVertexAttribPointer(void) {}
EXPORT void glEnableVertexAttribArray(void) {}
EXPORT void glClear(void) {}
EXPORT void glClearColor(void) {}
EXPORT void glUseProgram(void) {}
EXPORT void glDrawElements(void) {}
EXPORT void glDeleteVertexArrays(void) {}
EXPORT void glDeleteBuffers(void) {}
EXPORT void glDeleteProgram(void) {}
EXPORT void glViewport(void) {}
EXPORT void empty(void) {}