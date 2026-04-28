using PNML, JET, OrderedCollections

include("TestUtils.jl")
using .TestUtils

println("\n-----------------------------------------")
println("SharedMemory.pnml")
println("-----------------------------------------")
@testset let fname=joinpath(@__DIR__, "data", "SharedMemory.pnml")
    model = @test_logs((:error, r".*nscription term sort mismatch.*"),
                       match_mode=:any,
        pnmlmodel(fname)::PnmlModel)
    summary(stdout, model)
    n = first(PNML.nets(model))
    n = PNML.flatten_pages!(n)
    @test PNML.vertex_codes(n) isa AbstractDict
    @test PNML.vertex_labels(n) isa AbstractDict
    if !(narcs(n) > 0 && nplaces(n) > 0 && ntransitions(n) > 0)
        @test_throws ArgumentError PNML.metagraph(n)
    else
        @test contains(sprint(show, PNML.metagraph(n)),
            "Meta graph based on a Graphs.SimpleGraphs.SimpleDiGraph{Int64}")
    end
    #TODO more tests
end

println("\n-----------------------------------------")
println("SharedMemory-Hlpn.pnml") # modified
println("-----------------------------------------")
@testset let fname=joinpath(@__DIR__, "data", "SharedMemory-Hlpn.pnml")
    model = @test_logs((:error, r".*nscription term sort mismatch.*"),
                       match_mode=:any,
        pnmlmodel(fname)::PnmlModel)
    summary(stdout, model)
    n = first(PNML.nets(model))
    n = PNML.flatten_pages!(n)
    @test PNML.vertex_codes(n) isa AbstractDict
    @test PNML.vertex_labels(n) isa AbstractDict
    if !(narcs(n) > 0 && nplaces(n) > 0 && ntransitions(n) > 0)
        @test_throws ArgumentError PNML.metagraph(n)
    else
        @test contains(sprint(show, PNML.metagraph(n)),
            "Meta graph based on a Graphs.SimpleGraphs.SimpleDiGraph{Int64}")
    end
    #TODO more tests
end
