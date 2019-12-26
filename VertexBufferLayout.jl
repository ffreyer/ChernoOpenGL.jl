gl_sizeof(gl_type::UInt32) = gl_sizeof(Val(gl_type))
gl_sizeof(::Val{GL_FLOAT}) = 4
gl_sizeof(::Val{GL_UNSIGNED_INT}) = 4
gl_sizeof(::Val{GL_UNSIGNED_BYTE}) = 1


struct VertexBufferElement
    gl_type::UInt32
    count::UInt32
    normalized::UInt32
end

mutable struct VertexBufferLayout
    m_elements::Vector{VertexBufferElement}
    m_stride::UInt32
end

function VertexBufferLayout()
    VertexBufferLayout(
        VertexBufferElement[],
        0
    )
end

# Generate those push! methods...
for (type, gl_type, normalize) in [
        (Float32, GL_FLOAT, GL_FALSE),
        (UInt32, GL_UNSIGNED_INT, GL_FALSE),
        (UInt8, GL_UNSIGNED_BYTE, GL_TRUE),
    ]
    @eval function Base.push!(layout::VertexBufferLayout, ::Type{$type}, count)
        push!(layout.m_elements, VertexBufferElement($gl_type, UInt32(count), $normalize))
        layout.m_stride += $(gl_sizeof(gl_type)) * count
        nothing
    end
end

function Base.stride(layout::VertexBufferLayout)
    layout.m_stride
end

function elements(layout::VertexBufferLayout)
    layout.m_elements
end
