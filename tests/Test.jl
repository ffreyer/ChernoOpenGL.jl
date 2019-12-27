abstract type AbstractTest end

update(::AbstractTest, dt::Float32) = nothing
render(::AbstractTest) = nothing

include("ClearColorTest.jl")
