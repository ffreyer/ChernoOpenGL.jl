mutable struct Texture2DTest <: AbstractTest
    renderer::Renderer
    vbo::VertexBuffer
    va::VertexArray
    ibo::IndexBuffer
    shader::Shader
end

function Texture2DTest()
    positions = Float32[
        -50, -50, 0.0, 0.0,
         50, -50, 1.0, 0.0,
         50,  50, 1.0, 1.0,
        -50,  50, 0.0, 1.0
    ]

    indices = UInt32[
        0, 1, 2,
        2, 3, 0
    ]

    # 'case you got transparency
    # @GL_call glEnable(GL_BLEND)
    # @GL_call glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

    va = VertexArray()

    vbo = VertexBuffer(positions)
    layout = VertexBufferLayout()
    push!(layout, Float32, 2)
    push!(layout, Float32, 2)
    add_buffer(va, vbo, layout)

    ibo = IndexBuffer(indices)

    proj = orthographicprojection(0f0, 960f0, 0f0, 540f0, -1f0, 1f0)
    view = translationmatrix(Vec3f0(300, 300, 0))
    model = translationmatrix(Vec3f0(0, 0, 0))
    mvp = proj * view * model

    src_dir = joinpath(splitpath(@__DIR__)[1:end-1]...)
    shader = Shader(src_dir * "/resources/shaders/basic.shader")
    bind(shader)
    uniformMat4f(shader, "u_MVP", mvp)

    texture = Texture(src_dir * "/resources/textures/transparent_thumbs_up.png")
    bind(texture)
    uniform1i(shader, "u_Texture", Int32(0))

    @GL_call glClearColor(0f0, 0f0, 0f0, 1f0)

    Texture2DTest(Renderer(), vbo, va, ibo, shader)
end

function render(t::Texture2DTest)
    draw(t.renderer, t.va, t.ibo, t.shader)

    nothing
end

# function update(::AbstractTest, dt::Float32)
#
# end
