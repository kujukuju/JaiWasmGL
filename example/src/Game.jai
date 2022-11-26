
VBO: u32;
VAO: u32;
EBO: u32;
shaderProgram: u32;

#import "JaiWasmGL";

main :: () {
    set_context(*context);

    vertexShaderSource: *u8 = #string DONE
    #version 300 es
    in vec3 aPos;
    void main() {
       gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    }
    DONE
    fragmentShaderSource: *u8 = #string DONE
    #version 300 es
    precision mediump float;
    out vec4 FragColor;
    void main() {
       FragColor = vec4(1.0, 0.5, 0.2, 1.0);
    }
    DONE

    // build and compile our shader program
    // ------------------------------------
    // vertex shader
    vertexShader: u32 = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, *vertexShaderSource, null);
    glCompileShader(vertexShader);
    // check for shader compile errors
    success: s32;
    infoLog: [512] u8;
    infoString: string;
    infoString.data = infoLog.data;
    infoString.count = infoLog.count;
    glGetShaderiv(vertexShader, GL_COMPILE_STATUS, *success);
    if !success {
        glGetShaderInfoLog(vertexShader, 512, null, infoString.data);
        print("ERROR::SHADER::VERTEX::COMPILATION_FAILED\n%\n", infoString);
    }
    // fragment shader
    fragmentShader: u32 = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, *fragmentShaderSource, null);
    glCompileShader(fragmentShader);
    // check for shader compile errors
    glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, *success);
    if !success {
        glGetShaderInfoLog(fragmentShader, 512, null, infoString.data);
        print("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n%\n", infoString);
    }
    // link shaders
    shaderProgram = glCreateProgram();
    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragmentShader);
    glLinkProgram(shaderProgram);
    // check for linking errors
    glGetProgramiv(shaderProgram, GL_LINK_STATUS, *success);
    if !success {
        glGetProgramInfoLog(shaderProgram, 512, null, infoString.data);
        print("ERROR::SHADER::PROGRAM::LINKING_FAILED\n%\n", infoString);
    }
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);

    // set up vertex data (and buffer(s)) and configure vertex attributes
    // ------------------------------------------------------------------
    vertices: [] float = .[
         0.0,  0.5, 0.0,  // top right
         0.5, -0.5, 0.0,  // bottom right
        -0.5, -0.5, 0.0,  // bottom left
    ];
    indices: [] u32 = .[  // note that we start from 0!
        0, 2, 1,  // second Triangle
    ];
    glGenVertexArrays(1, *VAO);
    glGenBuffers(1, *VBO);
    glGenBuffers(1, *EBO);
    // bind the Vertex Array Object first, then bind and set vertex buffer(s), and then configure vertex attributes(s).
    glBindVertexArray(VAO);

    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, size_of(float) * vertices.count, vertices.data, GL_STATIC_DRAW);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) * indices.count, indices.data, GL_STATIC_DRAW);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * size_of(float), cast(*void) 0);
    glEnableVertexAttribArray(0);

    // note that this is allowed, the call to glVertexAttribPointer registered VBO as the vertex attribute's bound vertex buffer object so afterwards we can safely unbind
    glBindBuffer(GL_ARRAY_BUFFER, 0); 

    // remember: do NOT unbind the EBO while a VAO is active as the bound element buffer object IS stored in the VAO; keep the EBO bound.
    //glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

    // You can unbind the VAO afterwards so other VAO calls won't accidentally modify this VAO, but this rarely happens. Modifying other
    // VAOs requires a call to glBindVertexArray anyways so we generally don't unbind VAOs (nor VBOs) when it's not directly necessary.
    glBindVertexArray(0);
}

update :: () {
    glClearColor(0.2, 0.3, 0.3, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    // draw our first triangle
    glUseProgram(shaderProgram);
    glBindVertexArray(VAO); // seeing as we only have a single VAO there's no need to bind it every time, but we'll do so to keep things a bit more organized
    //glDrawArrays(GL_TRIANGLES, 0, 6);
    glDrawElements(GL_TRIANGLES, 3, GL_UNSIGNED_INT, null);
}

resize :: (width: s32, height: s32) {
    glViewport(0, 0, xx width, xx height);
}

#import "Basic";
