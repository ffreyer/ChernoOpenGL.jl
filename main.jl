# https://www.youtube.com/watch?v=W3gAzLwfIP0&list=PLlrATfBNZ98foTJPJ_Ev03o2oq3-GGOS2
# Documentation: docs.gl


using GLFW, ModernGL

include("Renderer.jl")
include("VertexBuffer.jl")
include("IndexBuffer.jl")
include("VertexBufferLayout.jl")
include("VertexArray.jl")
include("Shader.jl")


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


    va = VertexArray()
    vbo = VertexBuffer(positions)

    # add_buffer!(va, vbo)
    layout = VertexBufferLayout()
    push!(layout, Float32, 2)
    add_buffer!(va, vbo, layout)

    # Generate Index Buffer
    ibo = IndexBuffer(indices)


    shader = Shader((@__DIR__) * "/resources/shaders/basic.shader")
    bind!(shader)
    uniform4f!(shader, "u_color", 0.8f0, 0.3f0, 0.8f0, 1.0f0)

    unbind!(va)
    unbind!(shader)
    unbind!(vbo)
    unbind!(ibo)


    r = 0f0
    increment = 0.05f0

    # Loop until the user closes the window
    while !GLFW.WindowShouldClose(window)
        @GL_call ModernGL.glClear(ModernGL.GL_COLOR_BUFFER_BIT)

    	# Render here
        bind!(shader)
        uniform4f!(shader, "u_color", r, 0.3f0, 0.8f0, 1f0)

        bind!(va)
        bind!(ibo)

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

    # GLFW.Terminate() # requires re-initialization when re-running
    GLFW.DestroyWindow(window)
end

main()
