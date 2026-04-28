using PNML, JET, OrderedCollections

include("TestUtils.jl")
using .TestUtils

#
# copied from pnmlframework-2.2.16/pnmlFw-Tests/XMLTestFilesRepository/Oracle
#
oracle = "data/XMLTestFilesRepository/Oracle"

println("\n-----------------------------------------")
println("full_coremodel.xml")
println("-----------------------------------------")
@testset let fname=joinpath(@__DIR__, oracle, "full_coremodel.xml")
    model = pnmlmodel(fname)::PnmlModel
    summary(stdout, model) #first(nets(model)))
    n = first(nets(model))::PnmlNet
    n = flatten_pages!(n; verbose=true)::PnmlNet
    vc = vertex_codes(n)::AbstractDict
    vl = vertex_labels(n)::AbstractDict
    # for a in arcs(n)
    #     println("Edge ",
    #             vc[source(a)], " -> ",  vc[target(a)], " or ",
    #             vl[vc[source(a)]], " -> ",  vl[vc[target(a)]]
    #             )
    # end
    if !(narcs(n) > 0 && nplaces(n) > 0 && ntransitions(n) > 0)
        @test_throws ArgumentError metagraph(n)
    else
        @test contains(sprint(show, metagraph(n)),
            "Meta graph based on a Graphs.SimpleGraphs.SimpleDiGraph{Int64}")
    end
end

println("\n-----------------------------------------")
println("full_ptnet.xml")
println("-----------------------------------------")
@testset let fname=joinpath(@__DIR__, oracle, "full_ptnet.xml")
    model = pnmlmodel(fname)::PnmlModel
    summary(stdout, model) #first(nets(model)))
    n = first(nets(model))::PnmlNet
    n = flatten_pages!(n)::PnmlNet
    vc = vertex_codes(n)::AbstractDict
    vl = vertex_labels(n)::AbstractDict
     if !(narcs(n) > 0 && nplaces(n) > 0 && ntransitions(n) > 0)
        @test_throws ArgumentError metagraph(n)
    else
        @test contains(sprint(show, metagraph(n)),
            "Meta graph based on a Graphs.SimpleGraphs.SimpleDiGraph{Int64}")
    end
end

println("\n-----------------------------------------")
println("full_sn.xml") # modified
println("-----------------------------------------")
# finiteenumeration
@testset let fname=joinpath(@__DIR__, oracle, "full_sn.xml")
    model = @test_logs((:error, r".*inscription not provided for arc.*"),
                       (:error, r".*has neither a mark nor sorttype, use :dot.*"),
                       match_mode=:any,
        pnmlmodel(fname)::PnmlModel)
    summary(stdout, model)
    n = first(nets(model))::PnmlNet
    n = flatten_pages!(n)::PnmlNet
    @test vertex_codes(n) isa AbstractDict
    @test vertex_labels(n) isa AbstractDict
    if !(narcs(n) > 0 && nplaces(n) > 0 && ntransitions(n) > 0)
        @test_throws ArgumentError metagraph(n)
    else
        @test contains(sprint(show, metagraph(n)),
           "Meta graph based on a Graphs.SimpleGraphs.SimpleDiGraph{Int64}")
    end
end

println("\n-----------------------------------------")
println("full_hlpn.xml") # modified
println("-----------------------------------------")
@testset let fname=joinpath(@__DIR__, oracle, "full_hlpn.xml")
    model = @test_logs((:error, r".*inscription not provided for arc.*"),
                       (:error, r".*has neither a mark nor sorttype, use :dot.*"),
                       match_mode=:any,
        pnmlmodel(fname)::PnmlModel)
    summary(stdout, model)
    n = first(nets(model))::PnmlNet
    n = flatten_pages!(n)::PnmlNet
    @test vertex_codes(n) isa AbstractDict
    @test vertex_labels(n) isa AbstractDict
    if !(narcs(n) > 0 && nplaces(n) > 0 && ntransitions(n) > 0)
        @test_throws ArgumentError metagraph(n)
    else
        @test contains(sprint(show, metagraph(n)),
            "Meta graph based on a Graphs.SimpleGraphs.SimpleDiGraph{Int64}")
    end
end
