mutable struct Texture
    m_renderer_id::Ref{UInt32}
    filepath::String
    # m_local_buffer::Ref{UInt8}
    m_width::Int32
    m_height::Int32
    m_BPP::Int32
end

function Texture(path::String)
    t = Texture(Ref{UInt32}(), path, 0, 0, 0)

    # This returns a MAtrix of RGBA's
    # transform this to UInt8...
    img = let
        img = load(path)
        # t.m_width, t.m_height = size(img)
        t.m_height, t.m_width = size(img)
        out = UInt8[]
        for i in t.m_height:-1:1, j in 1:t.m_width
            # calling reinterpret causes a world age error, so I'm just gonna
            # access the FixedPointNumber struct...
            push!(out,
                img[i, j].r.i,
                img[i, j].g.i,
                img[i, j].b.i,
                img[i, j].alpha.i,
            )
        end
        out
    end


    @GL_call glGenTextures(1, t.m_renderer_id)
    @GL_call glBindTexture(GL_TEXTURE_2D, t.m_renderer_id[])
    # Required, else black screen
    # methods for resizing
    @GL_call glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    @GL_call glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    # bounardy conditions
    @GL_call glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
    @GL_call glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)

    @GL_call glTexImage2D(
        GL_TEXTURE_2D,
        0, # no levels
        GL_RGBA8, # what openGL turns our img into
        t.m_width,
        t.m_height,
        0, # 0 pixel border
        GL_RGBA, # format of the img we provide
        GL_UNSIGNED_BYTE,
        img # can be null pointer to tell openGL to reserve space
    )
    @GL_call glBindTexture(GL_TEXTURE_2D, 0)

    finalizer(free, t)
    t
end

free(t::Texture) = @GL_call glDeleteTextures(1, t.m_renderer_id)

Base.bind(t::Texture, slot::Integer) = bind(t, UInt32(slot))
function Base.bind(t::Texture, slot::UInt32 = 0)
    # cause TEXTURE0 ... TEXTURE31 are in order
    @GL_call glActiveTexture(GL_TEXTURE0 + slot)
    @GL_call glBindTexture(GL_TEXTURE_2D, t.m_renderer_id[])
end
function unbind(t::Texture)
    @GL_call glBindTexture(GL_TEXTURE_2D, 0)
end
width(t::Texture) = t.m_width
height(t::Texture) = t.m_height
