# include("Renderer.jl") # just include this after Renderer in main
mutable struct VertexBuffer
    # mutable required by finalizer
    # can we use UInt32 here? Does m_renderer_id ever change?
    # m_renderer_id::UInt32
    m_renderer_id::Ref{UInt32}
end

# TODO maybe type data as AbstractArray?
VertexBuffer(data) = VertexBuffer(data, UInt32(sizeof(data)))
VertexBuffer(data, bytesize) = VertexBuffer(data, UInt32(bytesize))
function VertexBuffer(data, bytesize::UInt32)
    m_renderer_id = Ref{ModernGL.GLuint}()
    @GL_call glGenBuffers(1, m_renderer_id)
    @GL_call glBindBuffer(GL_ARRAY_BUFFER, m_renderer_id[])
    @GL_call glBufferData(GL_ARRAY_BUFFER, bytesize, data, GL_STATIC_DRAW)
    vbo = VertexBuffer(m_renderer_id)
    finalizer(free!, vbo)
    vbo
end

free!(vbo::VertexBuffer) = @GL_call glDeleteBuffers(1, vbo.m_renderer_id)


function bind!(vbo::VertexBuffer)
    @GL_call glBindBuffer(GL_ARRAY_BUFFER, vbo.m_renderer_id[])
    nothing
end

function unbind!(vbo::VertexBuffer)
    @GL_call glBindBuffer(GL_ARRAY_BUFFER, vbo.m_renderer_id[])
    nothing
end
