# see VertexBuffer
mutable struct IndexBuffer
    m_renderer_id::Ref{UInt32}
    m_count::UInt32
end

# TODO maybe type data as AbstractArray?
IndexBuffer(data) = IndexBuffer(data, length(data))
IndexBuffer(data, count) = IndexBuffer(data, UInt32(count))
function IndexBuffer(data, count::UInt32)
    @assert sizeof(GLuint) == 4
    m_renderer_id = Ref{ModernGL.GLuint}()
    @GL_call glGenBuffers(1, m_renderer_id)
    @GL_call glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_renderer_id[])
    @GL_call glBufferData(GL_ELEMENT_ARRAY_BUFFER, 4count, data, GL_STATIC_DRAW)
    ibo = IndexBuffer(m_renderer_id, count)
    finalizer(free, ibo)
    ibo
end

free(ibo::IndexBuffer) = @GL_call glDeleteBuffers(1, ibo.m_renderer_id)


function Base.bind(ibo::IndexBuffer)
    @GL_call glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo.m_renderer_id[])
    nothing
end

function unbind(ibo::IndexBuffer)
    @GL_call glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo.m_renderer_id[])
    nothing
end

# GetCount would be length in standard Julia, right?
Base.length(ibo::IndexBuffer) = ibo.m_count
