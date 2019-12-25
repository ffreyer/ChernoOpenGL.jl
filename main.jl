# https://www.youtube.com/watch?v=W3gAzLwfIP0&list=PLlrATfBNZ98foTJPJ_Ev03o2oq3-GGOS2
# Documentation: docs.gl


using GLFW, ModernGL


function parse_shader(filepath)
    shaders = Dict{Symbol, String}()
    open(filepath, "r") do f
        write_to = :none
        for line in eachline(f)
            if startswith(line, "#shader")
                write_to = Symbol(line[9:end])
                push!(shaders, write_to => "")
                continue
            end
            if (write_to == :none) && !isempty(line)
                @warn "Ignored line\n\t>> $line"
            else
                shaders[write_to] = shaders[write_to] * "\n" * line
            end
        end
    end
    shaders
end


function compile_shader(gl_type, source::String)
    id = ModernGL.glCreateShader(gl_type)
    c_str = Vector{UInt8}(source)
    shader_code_ptrs = Ptr{UInt8}[pointer(c_str)]
    len = Ref{GLint}(length(c_str))
    ModernGL.glShaderSource(id, 1, shader_code_ptrs, len)
    ModernGL.glCompileShader(id)

    # Error handling
    result = Ref{Int32}() #Int32[]
    ModernGL.glGetShaderiv(id, ModernGL.GL_COMPILE_STATUS, result)
    if result[] == GL_FALSE
        L = Ref{Int32}()
        ModernGL.glGetShaderiv(id, ModernGL.GL_INFO_LOG_LENGTH, L)
        msg = Vector{UInt8}(undef, L[])
        ModernGL.glGetShaderInfoLog(id, L[], C_NULL, msg)
        ModernGL.glDeleteShader(id)

        throw(ErrorException(
            "Failed to compile " *
            (gl_type == ModernGL.GL_VERTEX_SHADER ? "vertex" : "fragment") *
            " shader!\n\n" * String(msg)
        ))
    end

    return id
end


function create_shader(vertex_shader, fragment_shader)
    program = ModernGL.glCreateProgram()
    vs = compile_shader(ModernGL.GL_VERTEX_SHADER, vertex_shader)
    fs = compile_shader(ModernGL.GL_FRAGMENT_SHADER, fragment_shader)

    glAttachShader(program, vs)
    glAttachShader(program, fs)
    glLinkProgram(program)
    glValidateProgram(program)

    # Clear temporary stuff
    glDeleteShader(vs)
    glDeleteShader(fs)

    return program
end


function main()
    # Create a window and its OpenGL context
    window = GLFW.CreateWindow(640, 480, "GLFW.jl")

    # Make the window's context current
    GLFW.MakeContextCurrent(window)

    # vertex = position, texture coordinate, normals, ...
    #              ^- these things are called attributes
    positions = Float32[
        -0.5, -0.5,
        0.0, 0.5,
        0.5, -0.5
    ]

    # Generate GPU Buffer
    vbo = Ref{ModernGL.GLuint}()
    ModernGL.glGenBuffers(1, vbo)
    # Select the buffer, mark as array buffer
    ModernGL.glBindBuffer(ModernGL.GL_ARRAY_BUFFER, vbo[])
    # Add data
    ModernGL.glBufferData(
        ModernGL.GL_ARRAY_BUFFER,
        sizeof(positions),
        positions,                   # Not interpreted as float, rather just a some pointer
        ModernGL.GL_STATIC_DRAW
    )

    # Tell opengl what its looking at
    ModernGL.glEnableVertexAttribArray(0)
    ModernGL.glVertexAttribPointer(
        0,                      # index - what the shader accesses via indexing
        2,                      # vertex component size
        ModernGL.GL_FLOAT,      # type
        ModernGL.GL_FALSE,      # should normalize?
        2sizeof(Float32),       # vertex size
        C_NULL                  # offset of vertex components
    )


    shaders = parse_shader((@__DIR__) * "/resources/shaders/basic.shader")
    shader = create_shader(shaders[:vertex], shaders[:fragment])
    ModernGL.glUseProgram(shader)

    # Loop until the user closes the window
    while !GLFW.WindowShouldClose(window)
        ModernGL.glClear(ModernGL.GL_COLOR_BUFFER_BIT)

    	# Render here
        ModernGL.glDrawArrays(ModernGL.GL_TRIANGLES, 0, 3)

    	# Swap front and back buffers
    	GLFW.SwapBuffers(window)

    	# Poll for and process events
    	GLFW.PollEvents()
    end

    # Cleanup shader
    ModernGL.glDeleteProgram(shader)

    # GLFW.Terminate() # requires re-initialization when re-running
    GLFW.DestroyWindow(window)
end

main()
