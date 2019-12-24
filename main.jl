# https://www.youtube.com/watch?v=W3gAzLwfIP0&list=PLlrATfBNZ98foTJPJ_Ev03o2oq3-GGOS2
# Documentation: docs.gl


using GLFW, ModernGL


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

    # deselect buffer
    ModernGL.glBindBuffer(ModernGL.GL_ARRAY_BUFFER, 0)

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
    # GLFW.Terminate() # requires re-initialization when re-running
    GLFW.DestroyWindow(window)
end

main()
