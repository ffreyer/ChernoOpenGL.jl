# https://www.youtube.com/watch?v=W3gAzLwfIP0&list=PLlrATfBNZ98foTJPJ_Ev03o2oq3-GGOS2
# Documentation: docs.gl


using GLFW, ModernGL


function gl_clear_error!()
    while ModernGL.glGetError() != ModernGL.GL_NO_ERROR
    end
    nothing
end

function gl_check_error()
    error = ModernGL.glGetError()
    error == ModernGL.GL_NO_ERROR && return ""
    # @error "An OpenGL Error has occured!"
    errors = typeof(error)[]
    while error != ModernGL.GL_NO_ERROR
        # println(error)
        push!(errors, error)
        error = ModernGL.glGetError()
    end
    # or Atom.JunoDebugger.add_breakpoint_args or whatever
    "$(join(errors, ", "))"
end

# This messes up stacktraces :(
macro GL_call(arg)
    arg_string = string(arg)
    quote
        gl_clear_error!()
        $(esc(arg))
        errors = gl_check_error()
        !isempty(errors) && throw(ErrorException(
            "An OpenGL Error occured when executing $($arg_string). ($errors)"
        ))
    end
end



# NOTE: Needs to be called after a context is bound
function version_to_string()
    if GLFW.GetCurrentContext().handle == C_NULL
        throw(ErrorException("Context must be bound!"))
    end

    buffer = UInt8[]
    @GL_call ptr = ModernGL.glGetString(GL_VERSION)
    for i in 1:100
        value = unsafe_load(ptr, i)
        if value == 0x00
            break
        else
            push!(buffer, value)
        end
    end
    join(Char.(buffer))
end


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
    @GL_call id = ModernGL.glCreateShader(gl_type)
    c_str = Vector{UInt8}(source)
    shader_code_ptrs = Ptr{UInt8}[pointer(c_str)]
    len = Ref{GLint}(length(c_str))
    @GL_call ModernGL.glShaderSource(id, 1, shader_code_ptrs, len)
    @GL_call ModernGL.glCompileShader(id)

    # Error handling
    result = Ref{Int32}() #Int32[]
    @GL_call ModernGL.glGetShaderiv(id, ModernGL.GL_COMPILE_STATUS, result)
    if result[] == GL_FALSE
        L = Ref{Int32}()
        @GL_call ModernGL.glGetShaderiv(id, ModernGL.GL_INFO_LOG_LENGTH, L)
        msg = Vector{UInt8}(undef, L[])
        @GL_call ModernGL.glGetShaderInfoLog(id, L[], C_NULL, msg)
        @GL_call ModernGL.glDeleteShader(id)

        throw(ErrorException(
            "Failed to compile " *
            (gl_type == ModernGL.GL_VERTEX_SHADER ? "vertex" : "fragment") *
            " shader!\n\n" * String(msg)
        ))
    end

    return id
end


function create_shader(vertex_shader, fragment_shader)
    @GL_call program = ModernGL.glCreateProgram()
    @GL_call vs = compile_shader(ModernGL.GL_VERTEX_SHADER, vertex_shader)
    @GL_call fs = compile_shader(ModernGL.GL_FRAGMENT_SHADER, fragment_shader)

    @GL_call ModernGL.glAttachShader(program, vs)
    @GL_call ModernGL.glAttachShader(program, fs)
    @GL_call ModernGL.glLinkProgram(program)
    @GL_call ModernGL.glValidateProgram(program)

    # Clear temporary stuff
    @GL_call ModernGL.glDeleteShader(vs)
    @GL_call ModernGL.glDeleteShader(fs)

    return program
end


function main()
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 3)
    GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)

    # Create a window and its OpenGL context
    window = GLFW.CreateWindow(640, 480, "GLFW.jl")

    # Make the window's context current
    GLFW.MakeContextCurrent(window)
    GLFW.SwapInterval(1) # Seems to be my default

    # vertex = position, texture coordinate, normals, ...
    #              ^- these things are called attributes
    positions = Float32[
        -0.5, -0.5,
         0.5, -0.5,
         0.5,  0.5,
        -0.5,  0.5
    ]

    # Hey, that's a GeometryTypes Face
    # MUST be unsigned, can be Int8, 16, 32 (64?)
    indices = UInt32[
        0, 1, 2,
        2, 3, 0
    ]

    # Generate Vertex array object
    vao = Ref{UInt32}()
    @GL_call ModernGL.glGenVertexArrays(1, vao)
    @GL_call ModernGL.glBindVertexArray(vao[])

    # Generate Vertex Buffer
    vbo = Ref{ModernGL.GLuint}()
    @GL_call ModernGL.glGenBuffers(1, vbo)
    # Select the buffer, mark as array buffer
    @GL_call ModernGL.glBindBuffer(ModernGL.GL_ARRAY_BUFFER, vbo[])
    # Add data
    @GL_call ModernGL.glBufferData(
        ModernGL.GL_ARRAY_BUFFER,
        sizeof(positions),
        positions,                   # Not interpreted as float, rather just a some pointer
        ModernGL.GL_STATIC_DRAW
    )

    # Tell opengl what its looking at
    @GL_call ModernGL.glEnableVertexAttribArray(0)
    # v this links vao and vbo (via index!?)
    @GL_call ModernGL.glVertexAttribPointer(
        0,                      # index - what the shader accesses via indexing
        2,                      # vertex component size
        ModernGL.GL_FLOAT,      # type
        ModernGL.GL_FALSE,      # should normalize?
        2sizeof(Float32),       # vertex size
        C_NULL                  # offset of vertex components
    )


    # Generate Index Buffer
    ibo = Ref{ModernGL.GLuint}()
    @GL_call ModernGL.glGenBuffers(1, ibo)
    # Select the buffer, mark as array buffer
    @GL_call ModernGL.glBindBuffer(ModernGL.GL_ELEMENT_ARRAY_BUFFER, ibo[])
    # Add data
    @GL_call ModernGL.glBufferData(
        ModernGL.GL_ELEMENT_ARRAY_BUFFER,
        sizeof(indices),
        indices,
        ModernGL.GL_STATIC_DRAW
    )


    shaders = parse_shader((@__DIR__) * "/resources/shaders/basic.shader")
    shader = create_shader(shaders[:vertex], shaders[:fragment])
    @GL_call ModernGL.glUseProgram(shader)

    # case sensitive
    location = glGetUniformLocation(shader, "u_color")
    @assert location != -1 "Uniform not found. Did you name it correctly? Is it used?"

    @GL_call ModernGL.glBindVertexArray(0)
    @GL_call ModernGL.glUseProgram(0)
    @GL_call ModernGL.glBindBuffer(ModernGL.GL_ARRAY_BUFFER, 0)
    @GL_call ModernGL.glBindBuffer(ModernGL.GL_ELEMENT_ARRAY_BUFFER, 0)


    r = 0f0
    increment = 0.05f0

    # Loop until the user closes the window
    while !GLFW.WindowShouldClose(window)
        @GL_call ModernGL.glClear(ModernGL.GL_COLOR_BUFFER_BIT)

    	# Render here
        @GL_call ModernGL.glUseProgram(shader)
        @GL_call ModernGL.glUniform4f(location, r, 0.3f0, 0.8f0, 1f0)
        @GL_call ModernGL.glBindVertexArray(vao[])
        # @GL_call ModernGL.glBindBuffer(ModernGL.GL_ARRAY_BUFFER, vbo[])
        # @GL_call ModernGL.glEnableVertexAttribArray(0)
        # @GL_call ModernGL.glVertexAttribPointer(
        #     0, 2, ModernGL.GL_FLOAT, ModernGL.GL_FALSE, 2sizeof(Float32), C_NULL                  # offset of vertex components
        # )
        @GL_call ModernGL.glBindBuffer(ModernGL.GL_ELEMENT_ARRAY_BUFFER, ibo[])

        @GL_call ModernGL.glDrawElements(
            ModernGL.GL_TRIANGLES,
            length(indices),
            ModernGL.GL_UNSIGNED_INT,
            C_NULL # indexbuffer currently active
        )

        if r > 1f0; increment = -0.05f0
        elseif r < 0f0; increment = 0.05f0
        end
        r += increment


    	# Swap front and back buffers
    	GLFW.SwapBuffers(window)

    	# Poll for and process events
    	GLFW.PollEvents()
    end

    # Cleanup shader
    @GL_call ModernGL.glDeleteProgram(shader)

    # GLFW.Terminate() # requires re-initialization when re-running
    GLFW.DestroyWindow(window)
end

main()
