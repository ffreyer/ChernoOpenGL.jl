# https://www.youtube.com/watch?v=W3gAzLwfIP0&list=PLlrATfBNZ98foTJPJ_Ev03o2oq3-GGOS2
# Documentation: docs.gl


using GLFW, ModernGL
using FileIO

include("GL_util.jl")
include("VertexBuffer.jl")
include("IndexBuffer.jl")
include("VertexBufferLayout.jl")
include("VertexArray.jl")
include("Shader.jl")
include("Renderer.jl")
include("Texture.jl")




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
        -0.5, -0.5, 0.0, 0.0,
         0.5, -0.5, 1.0, 0.0,
         0.5,  0.5, 1.0, 1.0,
        -0.5,  0.5, 0.0, 1.0
    ]

    # Hey, that's a GeometryTypes Face
    # MUST be unsigned, can be Int8, 16, 32 (64?)
    indices = UInt32[
        0, 1, 2,
        2, 3, 0
    ]

    # 'case you got transparency
    # @GL_call glEnable(GL_BLEND)
    # @GL_call glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

    va = VertexArray()
    vbo = VertexBuffer(positions)

    # add_buffer!(va, vbo)
    layout = VertexBufferLayout()
    push!(layout, Float32, 2)
    push!(layout, Float32, 2)
    add_buffer(va, vbo, layout)

    # Generate Index Buffer
    ibo = IndexBuffer(indices)


    shader = Shader((@__DIR__) * "/resources/shaders/basic.shader")
    bind(shader)

    texture = Texture((@__DIR__) * "/resources/textures/thumbs_up.png")
    bind(texture)
    uniform1i(shader, "u_Texture", Int32(0)) # must match slot from texture

    unbind(va)
    unbind(shader)
    unbind(vbo)
    unbind(ibo)

    renderer = Renderer()

    r = 0f0
    increment = 0.05f0

    # Loop until the user closes the window
    while !GLFW.WindowShouldClose(window)
        clear(renderer)

    	# Render here
        bind(shader)

        draw(renderer, va, ibo, shader)

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
