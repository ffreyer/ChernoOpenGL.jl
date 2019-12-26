mutable struct VertexArray
    m_renderer_id::Ref{UInt32}
end

function VertexArray()
    m_renderer_id = Ref{UInt32}()
    @GL_call ModernGL.glGenVertexArrays(1, m_renderer_id)
    va = VertexArray(m_renderer_id)
    finalizer(free!, va)
    va
end

free!(va::VertexArray) = @GL_call glDeleteVertexArrays(1, va.m_renderer_id)
bind!(va::VertexArray) = @GL_call ModernGL.glBindVertexArray(va.m_renderer_id[])
unbind!(va::VertexArray) = @GL_call ModernGL.glBindVertexArray(0)

function add_buffer!(va::VertexArray, vbo::VertexBuffer, layout::VertexBufferLayout)
    bind!(va)
    bind!(vbo)
    offset = 0
    for (i, element) in enumerate(elements(layout))
        # Julia starts at 1, remember?
        @GL_call ModernGL.glEnableVertexAttribArray(i-1)
        @GL_call ModernGL.glVertexAttribPointer(
            i-1,
            element.count,
            element.gl_type,
            element.normalized,
            stride(layout),
            Ptr{Nothing}(offset) # This is what GLAbstraction.jl does...
        )
        offset += element.count * gl_sizeof(element.gl_type)
    end
    nothing
end
