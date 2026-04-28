using PNML, JET, OrderedCollections

include("TestUtils.jl")
using .TestUtils

println("\n-----------------------------------------")
println("test1.pnml")
println("-----------------------------------------\n")
@testset let fname=joinpath(@__DIR__, "data", "test1.pnml")
    # model = @test_logs(match_mode=:any,
    #     (:warn, "ignoring unexpected child of <condition>: 'name'"),
    #     (:warn, "parse unknown declaration: tag = unknowendecl, id = unk1, name = u"),
    #     pnmlmodel(fname)::PnmlModel)
    model = pnmlmodel(fname)::PnmlModel
    summary(stdout, model)

#     # println("----"^10); @show model; println("----"^10)
#     #!@show model
#     #~ repr tests everybody's show() methods. #! Errors exposed warrent test BEFORE HERE!
#     #!@test startswith(repr(model), "PnmlModel")
    for net in PNML.nets(model)
        @test pid(net) in Set([:net1,:net2,:net3,:net4,:net5,:net6,
                               :net7,:net8,:net9,:net10,:net11])
        #println("-----------------------------------------")
        #println(summary(net))
        @test PNML.verify(net, false)
        PNML.flatten_pages!(net; verbose=false)
        @test PNML.verify(net, false)
        vc = PNML.vertex_codes(net)::AbstractDict
        vl = PNML.vertex_labels(net)::AbstractDict
        for a in arcs(net)
            @test vl[vc[PNML.source(a)]] == PNML.source(a)
            @test vl[vc[PNML.target(a)]] == PNML.target(a)
            # println("Edge ", vc[PNML.source(a)], " -> ", vc[PNML.target(a)], " or ",
            #                  vl[vc[PNML.source(a)]], " -> ", vl[vc[PNML.target(a)]],
            #     )
        end
        if !(narcs(net) > 0 && nplaces(net) > 0 && ntransitions(net) > 0)
            @test_throws ArgumentError PNML.metagraph(net)
        else
            @test contains(sprint(show, PNML.metagraph(net)),
                "Meta graph based on a Graphs.SimpleGraphs.SimpleDiGraph{Int64}")
        end
    end
end
