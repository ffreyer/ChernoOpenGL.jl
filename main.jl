# https://www.youtube.com/watch?v=W3gAzLwfIP0&list=PLlrATfBNZ98foTJPJ_Ev03o2oq3-GGOS2
# Documentation: docs.gl


using GLFW, ModernGL
using FileIO

# Maths (+ StaticArrays, useful shortcuts)
using GeometryTypes, Quaternions, StaticArrays
import GeometryTypes: update
include("GLMath.jl")

include("GL_util.jl")
include("VertexBuffer.jl")
include("IndexBuffer.jl")
include("VertexBufferLayout.jl")
include("VertexArray.jl")
include("Shader.jl")
include("Renderer.jl")
include("Texture.jl")

include("tests/Test.jl")


function main()
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 3)
    GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)

    # Create a window and its OpenGL context
    window = GLFW.CreateWindow(960, 540, "GLFW.jl")

    # Make the window's context current
    GLFW.MakeContextCurrent(window)
    GLFW.SwapInterval(1) # Seems to be my default


    # 'case you got transparency
    @GL_call glEnable(GL_BLEND)
    @GL_call glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

    renderer = Renderer()

    test = ClearColorTest()

    # Loop until the user closes the window
    while !GLFW.WindowShouldClose(window)
        clear(renderer)

        update(test, 0f0)
        render(test)

    	GLFW.SwapBuffers(window)
    	GLFW.PollEvents()
    end

    GLFW.DestroyWindow(window)
end

main()
