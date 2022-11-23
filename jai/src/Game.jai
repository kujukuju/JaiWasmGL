main :: () {
    set_context(*context);

    wasm_print("test");

    values := NewArray(128, u8);
    array_free(values);

    print("test?\n");

    // test: [..] u8;
    // array_add(*test, 0);
    // array_free(test);

    // this cant work right? anything passed to wasm has to be allocated memory afaik
    // vertexShaderSource: *u8 : "#version 330 core\n"
    // "layout (location = 0) in vec3 aPos;\n"
    // "void main()\n"
    // "{\n"
    // "   gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);\n"
    // "}\0";
    // fragmentShaderSource: *u8 : "#version 330 core\n"
    // "out vec4 FragColor;\n"
    // "void main()\n"
    // "{\n"
    // "   FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);\n"
    // "}\n\0";

    // build and compile our shader program
    // ------------------------------------
    // vertex shader
    // vertexShader: u32 = glCreateShader(GL_VERTEX_SHADER);
    // glShaderSource(vertexShader, 1, *vertexShaderSource, 0);
    // glCompileShader(vertexShader);
    // // check for shader compile errors
    // success: s32;
    // char infoLog[512];
    // glGetShaderiv(vertexShader, GL_COMPILE_STATUS, *success);
    // if (!success) {
    //     js_print("shader error\n");
    //     // glGetShaderInfoLog(vertexShader, 512, NULL, infoLog);
    //     // std::cout << "ERROR::SHADER::VERTEX::COMPILATION_FAILED\n" << infoLog << std::endl;
    // }
    // // fragment shader
    // fragmentShader: u32 = glCreateShader(GL_FRAGMENT_SHADER);
    // glShaderSource(fragmentShader, 1, *fragmentShaderSource, NULL);
    // glCompileShader(fragmentShader);
    // // check for shader compile errors
    // glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, &success);
    // if (!success) {
    //     glGetShaderInfoLog(fragmentShader, 512, NULL, infoLog);
    //     std::cout << "ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n" << infoLog << std::endl;
    // }
    // // link shaders
    // shaderProgram: u32 = glCreateProgram();
    // glAttachShader(shaderProgram, vertexShader);
    // glAttachShader(shaderProgram, fragmentShader);
    // glLinkProgram(shaderProgram);
    // // check for linking errors
    // glGetProgramiv(shaderProgram, GL_LINK_STATUS, &success);
    // if (!success) {
    //     glGetProgramInfoLog(shaderProgram, 512, NULL, infoLog);
    //     std::cout << "ERROR::SHADER::PROGRAM::LINKING_FAILED\n" << infoLog << std::endl;
    // }
    // glDeleteShader(vertexShader);
    // glDeleteShader(fragmentShader);

    // // set up vertex data (and buffer(s)) and configure vertex attributes
    // // ------------------------------------------------------------------
    // float vertices[] = {
    //      0.5f,  0.5f, 0.0f,  // top right
    //      0.5f, -0.5f, 0.0f,  // bottom right
    //     -0.5f, -0.5f, 0.0f,  // bottom left
    //     -0.5f,  0.5f, 0.0f   // top left 
    // };
    // unsigned int indices[] = {  // note that we start from 0!
    //     0, 1, 3,  // first Triangle
    //     1, 2, 3   // second Triangle
    // };
    // unsigned int VBO, VAO, EBO;
    // glGenVertexArrays(1, &VAO);
    // glGenBuffers(1, &VBO);
    // glGenBuffers(1, &EBO);
    // // bind the Vertex Array Object first, then bind and set vertex buffer(s), and then configure vertex attributes(s).
    // glBindVertexArray(VAO);

    // glBindBuffer(GL_ARRAY_BUFFER, VBO);
    // glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    // glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    // glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

    // glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
    // glEnableVertexAttribArray(0);

    // // note that this is allowed, the call to glVertexAttribPointer registered VBO as the vertex attribute's bound vertex buffer object so afterwards we can safely unbind
    // glBindBuffer(GL_ARRAY_BUFFER, 0); 

    // // remember: do NOT unbind the EBO while a VAO is active as the bound element buffer object IS stored in the VAO; keep the EBO bound.
    // //glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

    // // You can unbind the VAO afterwards so other VAO calls won't accidentally modify this VAO, but this rarely happens. Modifying other
    // // VAOs requires a call to glBindVertexArray anyways so we generally don't unbind VAOs (nor VBOs) when it's not directly necessary.
    // glBindVertexArray(0); 
}

// print_stack_trace :: () {
//     node := context.stack_trace;
//     while node {
//         // There are two different line numbers available.
//         // node.info.location has a line number, but this is the location of
//         // the start of the procedure. That may be useful in some cases, but often
//         // what we really want is the line number of the procedure call, which is
//         // stored in node.line_number. That's what we print in this case.
        
//         if node.info print("'%' at %:% ; call depth %, hash 0x%\n", node.info.name, node.info.location.fully_pathed_filename, node.line_number, node.call_depth, formatInt(node.hash, base=16));
//         node = node.next;
//     }
// }

update :: (test: float) {

}

#import "Basic";

// TODO compile time replace some functions, such as print, with js binded versions