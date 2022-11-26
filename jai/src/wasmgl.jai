
// webgl 1
glAttachShader :: (program: GLuint, shader: GLuint) #foreign #compiler;
glBindAttribLocation :: (program: GLuint, index: GLuint, name: *GLchar) #foreign #compiler;
glBindBuffer :: (target: GLenum, buffer: GLuint) #foreign #compiler;
glBindFramebuffer :: (target: GLenum, framebuffer: GLuint) #foreign #compiler;
glBindRenderbuffer :: (target: GLenum, renderbuffer: GLuint) #foreign #compiler;
glBindTexture :: (target: GLenum, texture: GLuint) #foreign #compiler;
glBlendColor :: (red: GLfloat, green: GLfloat, blue: GLfloat, alpha: GLfloat) #foreign #compiler;
glBlendEquation :: (mode: GLenum) #foreign #compiler;
glBlendEquationSeparate :: (modeRGB: GLenum, modeAlpha: GLenum) #foreign #compiler;
glBlendFunc :: (sfactor: GLenum, dfactor: GLenum) #foreign #compiler;
glBlendFuncSeparate :: (sfactorRGB: GLenum, dfactorRGB: GLenum, sfactorAlpha: GLenum, dfactorAlpha: GLenum) #foreign #compiler;
glBufferData :: (target: GLenum, size: GLsizeiptr, data: *void, usage: GLenum) #foreign #compiler;
glBufferSubData :: (target: GLenum, offset: GLintptr, size: GLsizeiptr, data: *void) #foreign #compiler;
glCheckFramebufferStatus :: (target: GLenum) -> GLenum #foreign #compiler;
glClear :: (mask: GLbitfield) #foreign #compiler;
glClearColor :: (red: GLfloat, green: GLfloat, blue: GLfloat, alpha: GLfloat) #foreign #compiler;
glClearDepth :: (depth: GLdouble) #foreign #compiler;
glClearStencil :: (s: GLint) #foreign #compiler;
glColorMask :: (red: GLboolean, green: GLboolean, blue: GLboolean, alpha: GLboolean) #foreign #compiler;
glCommit :: () #foreign #compiler;
glCompileShader :: (shader: GLuint) #foreign #compiler;
glCompressedTexImage2D :: (target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, height: GLsizei, border: GLint, imageSize: GLsizei, data: *void) #foreign #compiler;
glCompressedTexImage3D :: (target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei, border: GLint, imageSize: GLsizei, data: *void) #foreign #compiler;
glCompressedTexSubImage2D :: (target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, width: GLsizei, height: GLsizei, format: GLenum, imageSize: GLsizei, data: *void) #foreign #compiler;
glCopyTexImage2D :: (target: GLenum, level: GLint, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei, height: GLsizei, border: GLint) #foreign #compiler;
glCopyTexSubImage2D :: (target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, x: GLint, y: GLint, width: GLsizei, height: GLsizei) #foreign #compiler;
glGenBuffers :: (n: GLsizei, buffers: *GLuint) #foreign #compiler; // glCreateBuffer
glGenFramebuffers :: (n: GLsizei, framebuffers: *GLuint) #foreign #compiler; // glCreateFramebuffer
glCreateProgram :: () -> GLuint #foreign #compiler;
glCreateRenderbuffers :: (n: GLsizei, renderbuffers: *GLuint) #foreign #compiler; // glCreateRenderbuffer
glCreateShader :: (type: GLenum) -> GLuint #foreign #compiler;
glCreateTextures :: (target: GLenum, n: GLsizei, textures: *GLuint) #foreign #compiler; // glCreateTexture
glCullFace :: (mode: GLenum) #foreign #compiler;
glDeleteBuffers :: (n: GLsizei, buffers: *GLuint) #foreign #compiler; // glDeleteBuffer
glDeleteFramebuffers :: (n: GLsizei, framebuffers: *GLuint) #foreign #compiler; // glDeleteFramebuffer
glDeleteProgram :: (program: GLuint) #foreign #compiler;
glDeleteRenderbuffers :: (n: GLsizei, renderbuffers: *GLuint) #foreign #compiler; // glDeleteRenderbuffer
glDeleteShader :: (shader: GLuint) #foreign #compiler;
glDeleteTextures :: (n: GLsizei, textures: *GLuint) #foreign #compiler; // glDeleteTexture
glDepthFunc :: (func: GLenum) #foreign #compiler;
glDepthMask :: (flag: GLboolean) #foreign #compiler;
glDepthRange :: (near: GLdouble, far: GLdouble) #foreign #compiler;
glDetachShader :: (program: GLuint, shader: GLuint) #foreign #compiler;
glDisable :: (cap: GLenum) #foreign #compiler;
glDisableVertexAttribArray :: (index: GLuint) #foreign #compiler;
glDrawArrays :: (mode: GLenum, first: GLint, count: GLsizei) #foreign #compiler;
glDrawElements :: (mode: GLenum, count: GLsizei, type: GLenum, indices: *void) #foreign #compiler;
glEnable :: (cap: GLenum) #foreign #compiler;
glEnableVertexAttribArray :: (index: GLuint) #foreign #compiler;
glFinish :: () #foreign #compiler;
glFlush :: () #foreign #compiler;
glFramebufferRenderbuffer :: (target: GLenum, attachment: GLenum, renderbuffertarget: GLenum, renderbuffer: GLuint) #foreign #compiler;
glFramebufferTexture2D :: (target: GLenum, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint) #foreign #compiler;
glFrontFace :: (mode: GLenum) #foreign #compiler;
glGenerateMipmap :: (target: GLenum) #foreign #compiler;
glGetActiveAttrib :: (program: GLuint, index: GLuint, bufSize: GLsizei, length: *GLsizei, size: *GLint, type: *GLenum, name: *GLchar) #foreign #compiler;
glGetActiveUniform :: (program: GLuint, index: GLuint, bufSize: GLsizei, length: *GLsizei, size: *GLint, type: *GLenum, name: *GLchar) #foreign #compiler;
glGetAttachedShaders :: (program: GLuint, maxCount: GLsizei, count: *GLsizei, shaders: *GLuint) #foreign #compiler;
glGetAttribLocation :: (program: GLuint, name: *GLchar) -> GLint #foreign #compiler;
glGetBufferParameteriv :: (target: GLenum, pname: GLenum, params: *GLint) #foreign #compiler; // glGetBufferParameter
glGetContextAttributes :: () -> GLint #foreign #compiler;
glGetError :: () -> GLenum #foreign #compiler;
glGetExtension :: (name: *GLchar, length: GLsizei) -> GLint #foreign #compiler;
glGetFramebufferAttachmentParameteriv :: (target: GLenum, attachment: GLenum, pname: GLenum, params: *GLint) #foreign #compiler; // glGetFramebufferAttachmentParameter
glGetBooleanv :: (pname: GLenum, data: *GLboolean) #foreign #compiler; // glGetParameter
glGetDoublev :: (pname: GLenum, data: *GLdouble) #foreign #compiler; // glGetParameter
glGetFloatv :: (pname: GLenum, data: *GLfloat) #foreign #compiler; // glGetParameter
glGetIntegerv :: (pname: GLenum, data: *GLint) #foreign #compiler; // glGetParameter
glGetString :: (name: GLenum) -> *GLubyte #foreign #compiler; // glGetParameter
glGetInteger64v :: (pname: GLenum, data: *GLint64) #foreign #compiler; // glGetParameter
glGetBooleani_v :: (target: GLenum, index: GLuint, data: *GLboolean) #foreign #compiler; // glGetParameter
glGetIntegeri_v :: (target: GLenum, index: GLuint, data: *GLint) #foreign #compiler; // glGetParameter
glGetFloati_v :: (target: GLenum, index: GLuint, data: *GLfloat) #foreign #compiler; // glGetParameter
glGetDoublei_v :: (target: GLenum, index: GLuint, data: *GLdouble) #foreign #compiler; // glGetParameter
glGetInteger64i_v :: (target: GLenum, index: GLuint, data: *GLint64) #foreign #compiler; // glGetParameter
glGetProgramInfoLog :: (program: GLuint, bufSize: GLsizei, length: *GLsizei, infoLog: *GLchar) #foreign #compiler;
glGetProgramiv :: (program: GLuint, pname: GLenum, params: *GLint) #foreign #compiler; // glGetProgramParameter
glGetRenderbufferParameteriv :: (target: GLenum, pname: GLenum, params: *GLint) #foreign #compiler; // glGetRenderbufferParameter
glGetShaderInfoLog :: (shader: GLuint, bufSize: GLsizei, length: *GLsizei, infoLog: *GLchar) #foreign #compiler;
glGetShaderiv :: (shader: GLuint, pname: GLenum, params: *GLint) #foreign #compiler; // getShaderParameter
glGetShaderPrecisionFormat :: (shadertype: GLenum, precisiontype: GLenum, range: *GLint, precision: *GLint) #foreign #compiler;
glGetShaderSource :: (shader: GLuint, bufSize: GLsizei, length: *GLsizei, source: *GLchar) #foreign #compiler;
glGetSupportedExtensions :: (names: **GLchar, lengths: *GLsizei) #foreign #compiler;
glGetTexParameterfv :: (target: GLenum, pname: GLenum, params: *GLfloat) #foreign #compiler; // glGetTexParameter
glGetTexParameteriv :: (target: GLenum, pname: GLenum, params: *GLint) #foreign #compiler; // glGetTexParameter
glGetUniformfv :: (program: GLuint, location: GLint, params: *GLfloat) #foreign #compiler; // glGetUniform
glGetUniformiv :: (program: GLuint, location: GLint, params: *GLint) #foreign #compiler; // glGetUniform
glGetUniformLocation :: (program: GLuint, name: *GLchar) -> GLint #foreign #compiler;
glGetVertexAttribdv :: (index: GLuint, pname: GLenum, params: *GLdouble) #foreign #compiler; // glGetVertexAttrib
glGetVertexAttribfv :: (index: GLuint, pname: GLenum, params: *GLfloat) #foreign #compiler; // glGetVertexAttrib
glGetVertexAttribiv :: (index: GLuint, pname: GLenum, params: *GLint) #foreign #compiler; // glGetVertexAttrib
glGetVertexAttribPointerv :: (index: GLuint, pname: GLenum, pointer: **void) #foreign #compiler; // glGetVertexAttribOffset
glHint :: (target: GLenum, mode: GLenum) #foreign #compiler;
glIsBuffer :: (buffer: GLuint) -> GLboolean #foreign #compiler;
glIsContextLost :: () -> GLboolean #foreign #compiler;
glIsEnabled :: (cap: GLenum) -> GLboolean #foreign #compiler;
glIsFramebuffer :: (framebuffer: GLuint) -> GLboolean #foreign #compiler;
glIsProgram :: (program: GLuint) -> GLboolean #foreign #compiler;
glIsRenderbuffer :: (renderbuffer: GLuint) -> GLboolean #foreign #compiler;
glIsShader :: (shader: GLuint) -> GLboolean #foreign #compiler;
glIsTexture :: (texture: GLuint) -> GLboolean #foreign #compiler;
glLineWidth :: (width: GLfloat) #foreign #compiler;
glLinkProgram :: (program: GLuint) #foreign #compiler;
glMakeXRCompatible :: () -> GLboolean #foreign #compiler;
glPixelStorei :: (pname: GLenum, param: GLint) #foreign #compiler;
glPolygonOffset :: (factor: GLfloat, units: GLfloat) #foreign #compiler;
glReadPixels :: (x: GLint, y: GLint, width: GLsizei, height: GLsizei, format: GLenum, type: GLenum, pixels: *void) #foreign #compiler;
glRenderbufferStorage :: (target: GLenum, internalformat: GLenum, width: GLsizei, height: GLsizei) #foreign #compiler;
glSampleCoverage :: (value: GLfloat, invert: GLboolean) #foreign #compiler;
glScissor :: (x: GLint, y: GLint, width: GLsizei, height: GLsizei) #foreign #compiler;
glShaderSource :: (shader: GLuint, count: GLsizei, str: **GLchar, length: *GLint) #foreign #compiler;
glStencilFunc :: (func: GLenum, ref: GLint, mask: GLuint) #foreign #compiler;
glStencilFuncSeparate :: (face: GLenum, func: GLenum, ref: GLint, mask: GLuint) #foreign #compiler;
glStencilMask :: (mask: GLuint) #foreign #compiler;
glStencilMaskSeparate :: (face: GLenum, mask: GLuint) #foreign #compiler;
glStencilOp :: (fail: GLenum, zfail: GLenum, zpass: GLenum) #foreign #compiler;
glStencilOpSeparate :: (face: GLenum, sfail: GLenum, dpfail: GLenum, dppass: GLenum) #foreign #compiler;
glTexImage2D :: (target: GLenum, level: GLint, internalformat: GLint, width: GLsizei, height: GLsizei, border: GLint, format: GLenum, type: GLenum, pixels: *void) #foreign #compiler;
glTexParameterf :: (target: GLenum, pname: GLenum, param: GLfloat) #foreign #compiler;
glTexParameteri :: (target: GLenum, pname: GLenum, param: GLint) #foreign #compiler;
glTexSubImage2D :: (target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, width: GLsizei, height: GLsizei, format: GLenum, type: GLenum, pixels: *void) #foreign #compiler;
glUniform1f :: (location: GLint, v0: GLfloat) #foreign #compiler;
glUniform1fv :: (location: GLint, count: GLsizei, value: *GLfloat) #foreign #compiler;
glUniform1i :: (location: GLint, v0: GLint) #foreign #compiler;
glUniform1iv :: (location: GLint, count: GLsizei, value: *GLint) #foreign #compiler;
glUniform2f :: (location: GLint, v0: GLfloat, v1: GLfloat) #foreign #compiler;
glUniform2fv :: (location: GLint, count: GLsizei, value: *GLfloat) #foreign #compiler;
glUniform2i :: (location: GLint, v0: GLint, v1: GLint) #foreign #compiler;
glUniform2iv :: (location: GLint, count: GLsizei, value: *GLint) #foreign #compiler;
glUniform3f :: (location: GLint, v0: GLfloat, v1: GLfloat, v2: GLfloat) #foreign #compiler;
glUniform3fv :: (location: GLint, count: GLsizei, value: *GLfloat) #foreign #compiler;
glUniform3i :: (location: GLint, v0: GLint, v1: GLint, v2: GLint) #foreign #compiler;
glUniform3iv :: (location: GLint, count: GLsizei, value: *GLint) #foreign #compiler;
glUniform4f :: (location: GLint, v0: GLfloat, v1: GLfloat, v2: GLfloat, v3: GLfloat) #foreign #compiler;
glUniform4fv :: (location: GLint, count: GLsizei, value: *GLfloat) #foreign #compiler;
glUniform4i :: (location: GLint, v0: GLint, v1: GLint, v2: GLint, v3: GLint) #foreign #compiler;
glUniform4iv :: (location: GLint, count: GLsizei, value: *GLint) #foreign #compiler;
glUniformMatrix2fv :: (location: GLint, count: GLsizei, transpose: GLboolean, value: *GLfloat) #foreign #compiler;
glUniformMatrix3fv :: (location: GLint, count: GLsizei, transpose: GLboolean, value: *GLfloat) #foreign #compiler;
glUniformMatrix4fv :: (location: GLint, count: GLsizei, transpose: GLboolean, value: *GLfloat) #foreign #compiler;
glUseProgram :: (program: GLuint) #foreign #compiler;
glValidateProgram :: (program: GLuint) #foreign #compiler;
glVertexAttrib1f :: (index: GLuint, x: GLfloat) #foreign #compiler;
glVertexAttrib2f :: (index: GLuint, x: GLfloat, y: GLfloat) #foreign #compiler;
glVertexAttrib3f :: (index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat) #foreign #compiler;
glVertexAttrib4f :: (index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat) #foreign #compiler;
glVertexAttrib1fv :: (index: GLuint, v: *GLfloat) #foreign #compiler;
glVertexAttrib2fv :: (index: GLuint, v: *GLfloat) #foreign #compiler;
glVertexAttrib3fv :: (index: GLuint, v: *GLfloat) #foreign #compiler;
glVertexAttrib4fv :: (index: GLuint, v: *GLfloat) #foreign #compiler;
glVertexAttribPointer :: (index: GLuint, size: GLint, type: GLenum, normalized: GLboolean, stride: GLsizei, pointer: *void) #foreign #compiler;
glViewport :: (x: GLint, y: GLint, width: GLsizei, height: GLsizei) #foreign #compiler;

// webgl 2
glBeginQuery :: (target: GLenum, id: GLuint) #foreign #compiler;
glBeginTransformFeedback :: (primitiveMode: GLenum) #foreign #compiler;
glBindBufferBase :: (target: GLenum, index: GLuint, buffer: GLuint) #foreign #compiler;
glBindBufferRange :: (target: GLenum, index: GLuint, buffer: GLuint, offset: GLintptr, size: GLsizeiptr) #foreign #compiler;
glBindSampler :: (unit: GLuint, sampler: GLuint) #foreign #compiler;
glBindTransformFeedback :: (target: GLenum, id: GLuint) #foreign #compiler;
glBindVertexArray :: (array: GLuint) #foreign #compiler;
glBlitFramebuffer :: (srcX0: GLint, srcY0: GLint, srcX1: GLint, srcY1: GLint, dstX0: GLint, dstY0: GLint, dstX1: GLint, dstY1: GLint, mask: GLbitfield, filter: GLenum) #foreign #compiler;
glClearBufferiv :: (buffer: GLenum, drawbuffer: GLint, value: *GLint) #foreign #compiler; // glClearBufferiv
glClearBufferuiv :: (buffer: GLenum, drawbuffer: GLint, value: *GLuint) #foreign #compiler; // glClearBufferuiv
glClearBufferfv :: (buffer: GLenum, drawbuffer: GLint, value: *GLfloat) #foreign #compiler; // glClearBufferfv
glClearBufferfi :: (buffer: GLenum, drawbuffer: GLint, depth: GLfloat, stencil: GLint) #foreign #compiler; // glClearBufferfi
glClientWaitSync :: (sync: GLsync, flags: GLbitfield, timeout: GLuint64) -> GLenum #foreign #compiler;
glCompressedTexSubImage3D :: (target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, format: GLenum, imageSize: GLsizei, data: *void) #foreign #compiler;
glCopyBufferSubData :: (readTarget: GLenum, writeTarget: GLenum, readOffset: GLintptr, writeOffset: GLintptr, size: GLsizeiptr) #foreign #compiler;
glCopyTexSubImage3D :: (target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, x: GLint, y: GLint, width: GLsizei, height: GLsizei) #foreign #compiler;
glCreateQueries :: (target: GLenum, n: GLsizei, ids: *GLuint) #foreign #compiler; // glCreateQuery
glCreateSamplers :: (n: GLsizei, samplers: *GLuint) #foreign #compiler; // glCreateSampler
glCreateTransformFeedbacks :: (n: GLsizei, ids: *GLuint) #foreign #compiler; // glCreateTransformFeedback
glGenVertexArrays :: (n: GLsizei, arrays: *GLuint) #foreign #compiler; // glCreateVertexArray
glDeleteQueries :: (n: GLsizei, ids: *GLuint) #foreign #compiler; // glDeleteQuery
glDeleteSamplers :: (count: GLsizei, samplers: *GLuint) #foreign #compiler; // glDeleteSampler
glDeleteSync :: (sync: GLsync) #foreign #compiler;
glDeleteTransformFeedbacks :: (n: GLsizei, ids: *GLuint) #foreign #compiler; // glDeleteTransformFeedback
glDeleteVertexArrays :: (n: GLsizei, arrays: *GLuint) #foreign #compiler; // glDeleteVertexArray
glDrawArraysInstanced :: (mode: GLenum, first: GLint, count: GLsizei, instancecount: GLsizei) #foreign #compiler;
glDrawBuffers :: (n: GLsizei, bufs: *GLenum) #foreign #compiler;
glDrawElementsInstanced :: (mode: GLenum, count: GLsizei, type: GLenum, indices: *void, instancecount: GLsizei) #foreign #compiler;
glDrawRangeElements :: (mode: GLenum, start: GLuint, end: GLuint, count: GLsizei, type: GLenum, indices: *void) #foreign #compiler;
glEndQuery :: (target: GLenum) #foreign #compiler;
glEndTransformFeedback :: () #foreign #compiler;
glFenceSync :: (condition: GLenum, flags: GLbitfield) -> GLsync #foreign #compiler;
glFramebufferTextureLayer :: (target: GLenum, attachment: GLenum, texture: GLuint, level: GLint, layer: GLint) #foreign #compiler;
glGetActiveUniformBlockName :: (program: GLuint, uniformBlockIndex: GLuint, bufSize: GLsizei, length: *GLsizei, uniformBlockName: *GLchar) #foreign #compiler;
glGetActiveUniformBlockiv :: (program: GLuint, uniformBlockIndex: GLuint, pname: GLenum, params: *GLint) #foreign #compiler; // glGetActiveUniformBlockParameter
glGetActiveUniformsiv :: (program: GLuint, uniformCount: GLsizei, uniformIndices: *GLuint, pname: GLenum, params: *GLint) #foreign #compiler; // glGetActiveUniforms
glGetBufferSubData :: (target: GLenum, offset: GLintptr, size: GLsizeiptr, data: *void) #foreign #compiler;
glGetFragDataLocation :: (program: GLuint, name: *GLchar) -> GLint #foreign #compiler;
glGetIndexedParameter :: (target: GLenum, index: GLuint) -> GLint #foreign #compiler;
glGetInternalformativ :: (target: GLenum, internalformat: GLenum, pname: GLenum, bufSize: GLsizei, params: *GLint) #foreign #compiler; // glGetInternalformatParameter
glGetQueryObjectiv :: (id: GLuint, pname: GLenum, params: *GLint) #foreign #compiler; // glGetQuery
glGetQueryObjectuiv :: (id: GLuint, pname: GLenum, params: *GLuint) #foreign #compiler; // glGetQuery
glGetQueryiv :: (target: GLenum, pname: GLenum, params: *GLint) #foreign #compiler; // glGetQueryParameter
glGetSamplerParameteriv :: (sampler: GLuint, pname: GLenum, params: *GLint) #foreign #compiler; // glGetSamplerParameter
glGetSamplerParameterfv :: (sampler: GLuint, pname: GLenum, params: *GLfloat) #foreign #compiler; // glGetSamplerParameter
glGetSynciv :: (sync: GLsync, pname: GLenum, bufSize: GLsizei, length: *GLsizei, values: *GLint) #foreign #compiler; // glGetSyncParameter
glGetTransformFeedbackVarying :: (program: GLuint, index: GLuint, bufSize: GLsizei, length: *GLsizei, size: *GLsizei, type: *GLenum, name: *GLchar) #foreign #compiler;
glGetUniformBlockIndex :: (program: GLuint, uniformBlockName: *GLchar) -> GLuint #foreign #compiler;
glGetUniformIndices :: (program: GLuint, uniformCount: GLsizei, uniformNames: **GLchar, uniformIndices: *GLuint) #foreign #compiler;
glInvalidateFramebuffer :: (target: GLenum, numAttachments: GLsizei, attachments: *GLenum) #foreign #compiler;
glInvalidateSubFramebuffer :: (target: GLenum, numAttachments: GLsizei, attachments: *GLenum, x: GLint, y: GLint, width: GLsizei, height: GLsizei) #foreign #compiler;
glIsQuery :: (id: GLuint) -> GLboolean #foreign #compiler;
glIsSampler :: (sampler: GLuint) -> GLboolean #foreign #compiler;
glIsSync :: (sync: GLsync) -> GLboolean #foreign #compiler;
glIsTransformFeedback :: (id: GLuint) -> GLboolean #foreign #compiler;
glIsVertexArray :: (array: GLuint) -> GLboolean #foreign #compiler;
glPauseTransformFeedback :: () #foreign #compiler;
glReadBuffer :: (src: GLenum) #foreign #compiler;
glRenderbufferStorageMultisample :: (target: GLenum, samples: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei) #foreign #compiler;
glResumeTransformFeedback :: () #foreign #compiler;
glSamplerParameteri :: (sampler: GLuint, pname: GLenum, param: GLint) #foreign #compiler;
glSamplerParameterf :: (sampler: GLuint, pname: GLenum, param: GLfloat) #foreign #compiler;
glTexImage3D :: (target: GLenum, level: GLint, internalformat: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, border: GLint, format: GLenum, type: GLenum, pixels: *void) #foreign #compiler;
glTexStorage2D :: (target: GLenum, levels: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei) #foreign #compiler;
glTexStorage3D :: (target: GLenum, levels: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei) #foreign #compiler;
glTexSubImage3D :: (target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, format: GLenum, type: GLenum, pixels: *void) #foreign #compiler;
glTransformFeedbackVaryings :: (program: GLuint, count: GLsizei, varyings: **GLchar, bufferMode: GLenum) #foreign #compiler;
glUniform1ui :: (location: GLint, v0: GLuint) #foreign #compiler;
glUniform1uiv :: (location: GLint, count: GLsizei, value: *GLuint) #foreign #compiler;
glUniform2uiv :: (location: GLint, count: GLsizei, value: *GLuint) #foreign #compiler;
glUniform3uiv :: (location: GLint, count: GLsizei, value: *GLuint) #foreign #compiler;
glUniform4uiv :: (location: GLint, count: GLsizei, value: *GLuint) #foreign #compiler;
glUniformBlockBinding :: (program: GLuint, uniformBlockIndex: GLuint, uniformBlockBinding: GLuint) #foreign #compiler;
glUniformMatrix3x2fv :: (location: GLint, count: GLsizei, transpose: GLboolean, value: *GLfloat) #foreign #compiler;
glUniformMatrix4x2fv :: (location: GLint, count: GLsizei, transpose: GLboolean, value: *GLfloat) #foreign #compiler;
glUniformMatrix2x3fv :: (location: GLint, count: GLsizei, transpose: GLboolean, value: *GLfloat) #foreign #compiler;
glUniformMatrix4x3fv :: (location: GLint, count: GLsizei, transpose: GLboolean, value: *GLfloat) #foreign #compiler;
glUniformMatrix2x4fv :: (location: GLint, count: GLsizei, transpose: GLboolean, value: *GLfloat) #foreign #compiler;
glUniformMatrix3x4fv :: (location: GLint, count: GLsizei, transpose: GLboolean, value: *GLfloat) #foreign #compiler;
glVertexAttribDivisor :: (index: GLuint, divisor: GLuint) #foreign #compiler;
glVertexAttribI4i :: (index: GLuint, x: GLint, y: GLint, z: GLint, w: GLint) #foreign #compiler;
glVertexAttribI4ui :: (index: GLuint, x: GLuint, y: GLuint, z: GLuint, w: GLuint) #foreign #compiler;
glVertexAttribI4iv :: (index: GLuint, v: *GLint) #foreign #compiler;
glVertexAttribI4uiv :: (index: GLuint, v: *GLuint) #foreign #compiler;
glVertexAttribIPointer :: (index: GLuint, size: GLint, type: GLenum, stride: GLsizei, pointer: *void) #foreign #compiler;
glWaitSync :: (sync: GLsync, flags: GLbitfield, timeout: GLuint64) #foreign #compiler;

GLenum :: u32;
GLboolean :: bool;
GLbitfield :: u32;
GLbyte :: s8;
GLshort :: s16;
GLint :: s32;
// GLclampx :: s32;
GLubyte :: u8;
// GLushort :: u16;
GLuint :: u32;
GLsizei :: u32;
GLfloat :: float32;
// GLclampf :: float32;
GLdouble :: float64;
// GLclampd :: float64;
GLchar :: u8;
// GLcharARB :: u8;
// GLhandleARB :: u32;
// GLhalfARB :: u16;
// GLhalf :: u16;
// GLfixed :: s32;
GLintptr :: s64;
GLsizeiptr :: s64;
GLint64 :: s64;
GLuint64 :: u64;
// GLintptrARB :: s64;
// GLsizeiptrARB :: u64;
// GLint64EXT :: s64;
// GLuint64EXT :: u64;
GLsync :: u64;
// GLhalfNV :: u16;

GL_FALSE :: false;
GL_TRUE :: true;
GL_ACTIVE_ATTRIBUTES :: 0x8B89;
GL_ACTIVE_ATTRIBUTE_MAX_LENGTH :: 0x8B8A;
GL_ACTIVE_TEXTURE :: 0x84E0;
GL_ACTIVE_UNIFORMS :: 0x8B86;
GL_ACTIVE_UNIFORM_MAX_LENGTH :: 0x8B87;
GL_ALIASED_LINE_WIDTH_RANGE :: 0x846E;
GL_ALIASED_POINT_SIZE_RANGE :: 0x846D;
GL_ALPHA :: 0x1906;
GL_ALPHA_BITS :: 0x0D55;
GL_ALWAYS :: 0x0207;
GL_ARRAY_BUFFER :: 0x8892;
GL_ARRAY_BUFFER_BINDING :: 0x8894;
GL_ATTACHED_SHADERS :: 0x8B85;
GL_BACK :: 0x0405;
GL_BLEND :: 0x0BE2;
GL_BLEND_COLOR :: 0x8005;
GL_BLEND_DST_ALPHA :: 0x80CA;
GL_BLEND_DST_RGB :: 0x80C8;
GL_BLEND_EQUATION :: 0x8009;
GL_BLEND_EQUATION_ALPHA :: 0x883D;
GL_BLEND_EQUATION_RGB :: 0x8009;
GL_BLEND_SRC_ALPHA :: 0x80CB;
GL_BLEND_SRC_RGB :: 0x80C9;
GL_BLUE_BITS :: 0x0D54;
GL_BOOL :: 0x8B56;
GL_BOOL_VEC2 :: 0x8B57;
GL_BOOL_VEC3 :: 0x8B58;
GL_BOOL_VEC4 :: 0x8B59;
GL_BROWSER_DEFAULT_WEBGL :: 0x9244;
GL_BUFFER_SIZE :: 0x8764;
GL_BUFFER_USAGE :: 0x8765;
GL_BYTE :: 0x1400;
GL_CCW :: 0x0901;
GL_CLAMP_TO_EDGE :: 0x812F;
GL_COLOR_ATTACHMENT0 :: 0x8CE0;
GL_COLOR_BUFFER_BIT :: 0x00004000;
GL_COLOR_CLEAR_VALUE :: 0x0C22;
GL_COLOR_WRITEMASK :: 0x0C23;
GL_COMPILE_STATUS :: 0x8B81;
GL_COMPRESSED_TEXTURE_FORMATS :: 0x86A3;
GL_CONSTANT_ALPHA :: 0x8003;
GL_CONSTANT_COLOR :: 0x8001;
GL_CONTEXT_LOST_WEBGL :: 0x9242;
GL_CULL_FACE :: 0x0B44;
GL_CULL_FACE_MODE :: 0x0B45;
GL_CURRENT_PROGRAM :: 0x8B8D;
GL_CURRENT_VERTEX_ATTRIB :: 0x8626;
GL_CW :: 0x0900;
GL_DECR :: 0x1E03;
GL_DECR_WRAP :: 0x8508;
GL_DELETE_STATUS :: 0x8B80;
GL_DEPTH_ATTACHMENT :: 0x8D00;
GL_DEPTH_BITS :: 0x0D56;
GL_DEPTH_BUFFER_BIT :: 0x00000100;
GL_DEPTH_CLEAR_VALUE :: 0x0B73;
GL_DEPTH_COMPONENT :: 0x1902;
GL_DEPTH_COMPONENT16 :: 0x81A5;
GL_DEPTH_FUNC :: 0x0B74;
GL_DEPTH_RANGE :: 0x0B70;
GL_DEPTH_STENCIL :: 0x84F9;
GL_DEPTH_STENCIL_ATTACHMENT :: 0x821A;
GL_DEPTH_TEST :: 0x0B71;
GL_DEPTH_WRITEMASK :: 0x0B72;
GL_DITHER :: 0x0BD0;
GL_DONT_CARE :: 0x1100;
GL_DST_ALPHA :: 0x0304;
GL_DST_COLOR :: 0x0306;
GL_DYNAMIC_DRAW :: 0x88E8;
GL_ELEMENT_ARRAY_BUFFER :: 0x8893;
GL_ELEMENT_ARRAY_BUFFER_BINDING :: 0x8895;
GL_EQUAL :: 0x0202;
GL_FASTEST :: 0x1101;
GL_FLOAT :: 0x1406;
GL_FLOAT_MAT2 :: 0x8B5A;
GL_FLOAT_MAT3 :: 0x8B5B;
GL_FLOAT_MAT4 :: 0x8B5C;
GL_FLOAT_VEC2 :: 0x8B50;
GL_FLOAT_VEC3 :: 0x8B51;
GL_FLOAT_VEC4 :: 0x8B52;
GL_FRAGMENT_SHADER :: 0x8B30;
GL_FRAMEBUFFER :: 0x8D40;
GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME :: 0x8CD1;
GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE :: 0x8CD0;
GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE :: 0x8CD3;
GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL :: 0x8CD2;
GL_FRAMEBUFFER_BINDING :: 0x8CA6;
GL_FRAMEBUFFER_COMPLETE :: 0x8CD5;
GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT :: 0x8CD6;
GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS :: 0x8cd9;
GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT :: 0x8CD7;
GL_FRAMEBUFFER_UNSUPPORTED :: 0x8CDD;
GL_FRONT :: 0x0404;
GL_FRONT_AND_BACK :: 0x0408;
GL_FRONT_FACE :: 0x0B46;
GL_FUNC_ADD :: 0x8006;
GL_FUNC_REVERSE_SUBTRACT :: 0x800B;
GL_FUNC_SUBTRACT :: 0x800A;
GL_GENERATE_MIPMAP_HINT :: 0x8192;
GL_GEQUAL :: 0x0206;
GL_GREATER :: 0x0204;
GL_GREEN_BITS :: 0x0D53;
GL_HIGH_FLOAT :: 0x8DF2;
GL_HIGH_INT :: 0x8DF5;
GL_INCR :: 0x1E02;
GL_INCR_WRAP :: 0x8507;
GL_INFO_LOG_LENGTH :: 0x8B84;
GL_INT :: 0x1404;
GL_INT_VEC2 :: 0x8B53;
GL_INT_VEC3 :: 0x8B54;
GL_INT_VEC4 :: 0x8B55;
GL_INVALID_ENUM :: 0x0500;
GL_INVALID_FRAMEBUFFER_OPERATION :: 0x0506;
GL_INVALID_OPERATION :: 0x0502;
GL_INVALID_VALUE :: 0x0501;
GL_INVERT :: 0x150A;
GL_KEEP :: 0x1E00;
GL_LEQUAL :: 0x0203;
GL_LESS :: 0x0201;
GL_LINEAR :: 0x2601;
GL_LINEAR_MIPMAP_LINEAR :: 0x2703;
GL_LINEAR_MIPMAP_NEAREST :: 0x2701;
GL_LINES :: 0x0001;
GL_LINE_LOOP :: 0x0002;
GL_LINE_STRIP :: 0x0003;
GL_LINE_WIDTH :: 0x0B21;
GL_LINK_STATUS :: 0x8B82;
GL_LOW_FLOAT :: 0x8DF0;
GL_LOW_INT :: 0x8DF3;
GL_LUMINANCE :: 0x1909;
GL_LUMINANCE_ALPHA :: 0x190A;
GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS :: 0x8B4D;
GL_MAX_CUBE_MAP_TEXTURE_SIZE :: 0x851C;
GL_MAX_FRAGMENT_UNIFORM_VECTORS :: 0x8DFD;
GL_MAX_RENDERBUFFER_SIZE :: 0x84E8;
GL_MAX_TEXTURE_IMAGE_UNITS :: 0x8872;
GL_MAX_TEXTURE_SIZE :: 0x0D33;
GL_MAX_VARYING_VECTORS :: 0x8DFC;
GL_MAX_VERTEX_ATTRIBS :: 0x8869;
GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS :: 0x8B4C;
GL_MAX_VERTEX_UNIFORM_VECTORS :: 0x8DFB;
GL_MAX_VIEWPORT_DIMS :: 0x0D3A;
GL_MEDIUM_FLOAT :: 0x8DF1;
GL_MEDIUM_INT :: 0x8DF4;
GL_MIRRORED_REPEAT :: 0x8370;
GL_NEAREST :: 0x2600;
GL_NEAREST_MIPMAP_LINEAR :: 0x2702;
GL_NEAREST_MIPMAP_NEAREST :: 0x2700;
GL_NEVER :: 0x0200;
GL_NICEST :: 0x1102;
GL_NONE :: 0;
GL_NOTEQUAL :: 0x0205;
GL_NO_ERROR :: 0;
GL_NUM_COMPRESSED_TEXTURE_FORMATS :: 0x86A2;
GL_ONE :: 1;
GL_ONE_MINUS_CONSTANT_ALPHA :: 0x8004;
GL_ONE_MINUS_CONSTANT_COLOR :: 0x8002;
GL_ONE_MINUS_DST_ALPHA :: 0x0305;
GL_ONE_MINUS_DST_COLOR :: 0x0307;
GL_ONE_MINUS_SRC_ALPHA :: 0x0303;
GL_ONE_MINUS_SRC_COLOR :: 0x0301;
GL_OUT_OF_MEMORY :: 0x0505;
GL_PACK_ALIGNMENT :: 0x0D05;
GL_POINTS :: 0x0000;
GL_POLYGON_OFFSET_FACTOR :: 0x8038;
GL_POLYGON_OFFSET_FILL :: 0x8037;
GL_POLYGON_OFFSET_UNITS :: 0x2A00;
GL_RED_BITS :: 0x0D52;
GL_RENDERBUFFER :: 0x8D41;
GL_RENDERBUFFER_ALPHA_SIZE :: 0x8D53;
GL_RENDERBUFFER_BINDING :: 0x8CA7;
GL_RENDERBUFFER_BLUE_SIZE :: 0x8D52;
GL_RENDERBUFFER_DEPTH_SIZE :: 0x8D54;
GL_RENDERBUFFER_GREEN_SIZE :: 0x8D51;
GL_RENDERBUFFER_HEIGHT :: 0x8D43;
GL_RENDERBUFFER_INTERNAL_FORMAT :: 0x8D44;
GL_RENDERBUFFER_RED_SIZE :: 0x8D50;
GL_RENDERBUFFER_STENCIL_SIZE :: 0x8D55;
GL_RENDERBUFFER_WIDTH :: 0x8D42;
GL_RENDERER :: 0x1F01;
GL_REPEAT :: 0x2901;
GL_REPLACE :: 0x1E01;
GL_RGB :: 0x1907;
GL_RGB5_A1 :: 0x8057;
GL_RGB565 :: 0x8D62;
GL_RGBA :: 0x1908;
GL_RGBA4 :: 0x8056;
GL_SAMPLER_2D :: 0x8B5E;
GL_SAMPLER_CUBE :: 0x8B60;
GL_SAMPLES :: 0x80A9;
GL_SAMPLE_ALPHA_TO_COVERAGE :: 0x809E;
GL_SAMPLE_BUFFERS :: 0x80A8;
GL_SAMPLE_COVERAGE :: 0x80A0;
GL_SAMPLE_COVERAGE_INVERT :: 0x80AB;
GL_SAMPLE_COVERAGE_VALUE :: 0x80AA;
GL_SCISSOR_BOX :: 0x0C10;
GL_SCISSOR_TEST :: 0x0C11;
GL_SHADER_COMPILER :: 0x8DFA;
GL_SHADER_SOURCE_LENGTH :: 0x8B88;
GL_SHADER_TYPE :: 0x8B4F;
GL_SHADING_LANGUAGE_VERSION :: 0x8B8C;
GL_SHORT :: 0x1402;
GL_SRC_ALPHA :: 0x0302;
GL_SRC_ALPHA_SATURATE :: 0x0308;
GL_SRC_COLOR :: 0x0300;
GL_STATIC_DRAW :: 0x88E4;
GL_STENCIL_ATTACHMENT :: 0x8D20;
GL_STENCIL_BACK_FAIL :: 0x8801;
GL_STENCIL_BACK_FUNC :: 0x8800;
GL_STENCIL_BACK_PASS_DEPTH_FAIL :: 0x8802;
GL_STENCIL_BACK_PASS_DEPTH_PASS :: 0x8803;
GL_STENCIL_BACK_REF :: 0x8CA3;
GL_STENCIL_BACK_VALUE_MASK :: 0x8CA4;
GL_STENCIL_BACK_WRITEMASK :: 0x8CA5;
GL_STENCIL_BITS :: 0x0D57;
GL_STENCIL_BUFFER_BIT :: 0x00000400;
GL_STENCIL_CLEAR_VALUE :: 0x0B91;
GL_STENCIL_FAIL :: 0x0B94;
GL_STENCIL_FUNC :: 0x0B92;
GL_STENCIL_INDEX :: 0x1901;
GL_STENCIL_INDEX8 :: 0x8D48;
GL_STENCIL_PASS_DEPTH_FAIL :: 0x0B95;
GL_STENCIL_PASS_DEPTH_PASS :: 0x0B96;
GL_STENCIL_REF :: 0x0B97;
GL_STENCIL_TEST :: 0x0B90;
GL_STENCIL_VALUE_MASK :: 0x0B93;
GL_STENCIL_WRITEMASK :: 0x0B98;
GL_STREAM_DRAW :: 0x88E0;
GL_SUBPIXEL_BITS :: 0x0D50;
GL_TEXTURE :: 0x1702;
GL_TEXTURE0 :: 0x84C0;
GL_TEXTURE1 :: 0x84C1;
GL_TEXTURE2 :: 0x84C2;
GL_TEXTURE3 :: 0x84C3;
GL_TEXTURE4 :: 0x84C4;
GL_TEXTURE5 :: 0x84C5;
GL_TEXTURE6 :: 0x84C6;
GL_TEXTURE7 :: 0x84C7;
GL_TEXTURE8 :: 0x84C8;
GL_TEXTURE9 :: 0x84C9;
GL_TEXTURE10 :: 0x84CA;
GL_TEXTURE11 :: 0x84CB;
GL_TEXTURE12 :: 0x84CC;
GL_TEXTURE13 :: 0x84CD;
GL_TEXTURE14 :: 0x84CE;
GL_TEXTURE15 :: 0x84CF;
GL_TEXTURE16 :: 0x84D0;
GL_TEXTURE17 :: 0x84D1;
GL_TEXTURE18 :: 0x84D2;
GL_TEXTURE19 :: 0x84D3;
GL_TEXTURE20 :: 0x84D4;
GL_TEXTURE21 :: 0x84D5;
GL_TEXTURE22 :: 0x84D6;
GL_TEXTURE23 :: 0x84D7;
GL_TEXTURE24 :: 0x84D8;
GL_TEXTURE25 :: 0x84D9;
GL_TEXTURE26 :: 0x84DA;
GL_TEXTURE27 :: 0x84DB;
GL_TEXTURE28 :: 0x84DC;
GL_TEXTURE29 :: 0x84DD;
GL_TEXTURE30 :: 0x84DE;
GL_TEXTURE31 :: 0x84DF;
GL_TEXTURE_2D :: 0x0DE1;
GL_TEXTURE_BINDING_2D :: 0x8069;
GL_TEXTURE_BINDING_CUBE_MAP :: 0x8514;
GL_TEXTURE_CUBE_MAP :: 0x8513;
GL_TEXTURE_CUBE_MAP_NEGATIVE_X :: 0x8516;
GL_TEXTURE_CUBE_MAP_NEGATIVE_Y :: 0x8518;
GL_TEXTURE_CUBE_MAP_NEGATIVE_Z :: 0x851A;
GL_TEXTURE_CUBE_MAP_POSITIVE_X :: 0x8515;
GL_TEXTURE_CUBE_MAP_POSITIVE_Y :: 0x8517;
GL_TEXTURE_CUBE_MAP_POSITIVE_Z :: 0x8519;
GL_TEXTURE_MAG_FILTER :: 0x2800;
GL_TEXTURE_MIN_FILTER :: 0x2801;
GL_TEXTURE_WRAP_S :: 0x2802;
GL_TEXTURE_WRAP_T :: 0x2803;
GL_TRIANGLES :: 0x0004;
GL_TRIANGLE_FAN :: 0x0006;
GL_TRIANGLE_STRIP :: 0x0005;
GL_UNPACK_ALIGNMENT :: 0x0CF5;
GL_UNPACK_COLORSPACE_CONVERSION_WEBGL :: 0x9243;
GL_UNPACK_FLIP_Y_WEBGL :: 0x9240;
GL_UNPACK_PREMULTIPLY_ALPHA_WEBGL :: 0x9241;
GL_UNSIGNED_BYTE :: 0x1401;
GL_UNSIGNED_INT :: 0x1405;
GL_UNSIGNED_SHORT :: 0x1403;
GL_UNSIGNED_SHORT_4_4_4_4 :: 0x8033;
GL_UNSIGNED_SHORT_5_5_5_1 :: 0x8034;
GL_UNSIGNED_SHORT_5_6_5 :: 0x8363;
GL_VALIDATE_STATUS :: 0x8B83;
GL_VENDOR :: 0x1F00;
GL_VERSION :: 0x1F02;
GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING :: 0x889F;
GL_VERTEX_ATTRIB_ARRAY_ENABLED :: 0x8622;
GL_VERTEX_ATTRIB_ARRAY_NORMALIZED :: 0x886A;
GL_VERTEX_ATTRIB_ARRAY_POINTER :: 0x8645;
GL_VERTEX_ATTRIB_ARRAY_SIZE :: 0x8623;
GL_VERTEX_ATTRIB_ARRAY_STRIDE :: 0x8624;
GL_VERTEX_ATTRIB_ARRAY_TYPE :: 0x8625;
GL_VERTEX_SHADER :: 0x8B31;
GL_VIEWPORT :: 0x0BA2;
GL_ZERO :: 0;
