# https://www.youtube.com/watch?v=W3gAzLwfIP0&list=PLlrATfBNZ98foTJPJ_Ev03o2oq3-GGOS2
# Documentation: docs.gl


using GLFW, ModernGL
using FileIO

# Maths (+ StaticArrays, useful shortcuts)
using GeometryTypes, Quaternions, StaticArrays
include("GLMath.jl")

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
    window = GLFW.CreateWindow(960, 540, "GLFW.jl")

    # Make the window's context current
    GLFW.MakeContextCurrent(window)
    GLFW.SwapInterval(1) # Seems to be my default

    # vertex = position, texture coordinate, normals, ...
    #              ^- these things are called attributes
    positions = Float32[
        -50, -50, 0.0, 0.0,
         50, -50, 1.0, 0.0,
         50,  50, 1.0, 1.0,
        -50,  50, 0.0, 1.0
    ]

    # Hey, that's a GeometryTypes Face
    # MUST be unsigned, can be Int8, 16, 32 (64?)
    indices = UInt32[
        0, 1, 2,
        2, 3, 0
    ]

    # 'case you got transparency
    @GL_call glEnable(GL_BLEND)
    @GL_call glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

    va = VertexArray()
    vbo = VertexBuffer(positions)

    # add_buffer!(va, vbo)
    layout = VertexBufferLayout()
    push!(layout, Float32, 2)
    push!(layout, Float32, 2)
    add_buffer(va, vbo, layout)

    # Generate Index Buffer
    ibo = IndexBuffer(indices)

    # -2..2 = 4, -1.5..1.5 = 3 => 4x3 ratio
    # proj = orthographicprojection(-2f0, 2f0, -1.5f0, 1.5f0, -1f0, 1f0)
    proj = orthographicprojection(0f0, 960f0, 0f0, 540f0, -1f0, 1f0)
    view = translationmatrix(Vec3f0(0, 0, 0)) # translate camera right / world left
    model = translationmatrix(Vec3f0(0, 0, 0))
    mvp = proj * view * model

    shader = Shader((@__DIR__) * "/resources/shaders/basic.shader")
    bind(shader)
    uniformMat4f(shader, "u_MVP", mvp)

    # texture = Texture((@__DIR__) * "/resources/textures/thumbs_up.png")
    texture = Texture((@__DIR__) * "/resources/textures/transparent_thumbs_up.png")
    bind(texture)
    uniform1i(shader, "u_Texture", Int32(0)) # must match slot from texture

    unbind(va)
    unbind(shader)
    unbind(vbo)
    unbind(ibo)

    renderer = Renderer()

    # Loop until the user closes the window
    while !GLFW.WindowShouldClose(window)
        clear(renderer)

    	# Render here
        let
            model = translationmatrix(Vec3f0(200, 200, 0))
            mvp = proj * view * model
            bind(shader)
            uniformMat4f(shader, "u_MVP", mvp)
            draw(renderer, va, ibo, shader)
        end

        let
            model = translationmatrix(Vec3f0(400, 200, 0))
            mvp = proj * view * model
            bind(shader)
            uniformMat4f(shader, "u_MVP", mvp)
            draw(renderer, va, ibo, shader)
        end


    	# Swap front and back buffers
    	GLFW.SwapBuffers(window)

    	# Poll for and process events
    	GLFW.PollEvents()
    end

    # GLFW.Terminate() # requires re-initialization when re-running
    GLFW.DestroyWindow(window)
end

main()
