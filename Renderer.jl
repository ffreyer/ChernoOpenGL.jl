struct Renderer end

clear(r::Renderer) = @GL_call glClear(GL_COLOR_BUFFER_BIT)

function draw(r::Renderer, va::VertexArray, ibo::IndexBuffer, shader::Shader)
    bind(shader)
    bind(va)
    bind(ibo)
    @GL_call glDrawElements(GL_TRIANGLES, length(ibo), GL_UNSIGNED_INT, C_NULL)

    nothing
end
