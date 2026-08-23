using PNML, JET, OrderedCollections, Test

include("TestUtils.jl")
using .TestUtils

# from ePNK
println("'n-----------------------------------------")
println("test19.pnml") # modified
@testset let fname=joinpath(@__DIR__, "data/ePNK", "test19.pnml")
    model = pnmlmodel(fname)::PnmlModel
    # println("model = ", model) #! debug
end
