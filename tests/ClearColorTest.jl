mutable struct ClearColorTest <: AbstractTest
    m_clear_color::Vector{Float32}
end

function ClearColorTest()
    cct = ClearColorTest(
        Float32[0.2, 0.3, 0.8, 1.0]
    )
end

function render(cct::ClearColorTest)
    @GL_call glClearColor(cct.m_clear_color...)
    @GL_call glClear(GL_COLOR_BUFFER_BIT)
end
