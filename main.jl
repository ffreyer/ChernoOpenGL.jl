# https://www.youtube.com/watch?v=W3gAzLwfIP0&list=PLlrATfBNZ98foTJPJ_Ev03o2oq3-GGOS2
# Documentation: docs.gl


using GLFW, ModernGL
using FileIO

# Maths (+ StaticArrays, useful shortcuts)
using GeometryTypes, Quaternions, StaticArrays
import GeometryTypes: update
include("GLMath.jl")

# We may not have ImGUI, but at least we have observables...
using Observables
# To access observables defined in random places. Obviously suboptimal
obs = Dict{Symbol, Observable}()


include("GL_util.jl")
include("VertexBuffer.jl")
include("IndexBuffer.jl")
include("VertexBufferLayout.jl")
include("VertexArray.jl")
include("Shader.jl")
include("Renderer.jl")
include("Texture.jl")

include("tests/Test.jl")

function renderloop(window, renderer, test::Ref{AbstractTest})
    while true
        clear(renderer)

        update(test[], 0f0)
        render(test[])

    	GLFW.SwapBuffers(window)
    	GLFW.PollEvents()

        if GLFW.WindowShouldClose(window)
            GLFW.DestroyWindow(window)
            break
        end

        yield()
    end
end


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

    test_picker = Observable(ClearColorTest())
    test = Ref{AbstractTest}(ClearColorTest())
    _ = on(test_picker) do t
        try
            test[] = t
        catch e
            @error "Failed to update test." exception=e
        end
        nothing
    end
    global obs
    push!(obs, :test => test_picker)

    # Loop until the user closes the window
    @async renderloop(window, renderer, test)
end

main()
