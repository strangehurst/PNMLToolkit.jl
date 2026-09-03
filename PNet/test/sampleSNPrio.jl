using PNML, JET, OrderedCollections, Test, Multisets
using PNet
using PNet: metagraph, fire2
using PNML
using PNML.Parser: xmlnode
using PNML: @xml_str, Arc, Page, Place, PnmlModel, PnmlNet, Transition, arc, arcs,
    condition, enabled, firstpage, has_arc, has_place, has_transition, initial_marking,
    initial_markings, input_matrix, inscription, narcs, nets, nplaces, ntransitions,
    output_matrix, pages, pid, place, places, pnmlmodel, pntd_of, rates, transition,
    transitions, xmlnode, place_ids, arc_ids, transition_ids, firstpage

# Read a SymmetricNet with partitions & tuples from pnmlframework test file.
# NB: This model is from part 2 of the ISO 15909 standard as informative.
# From ePNK
println("\n-----------------------------------------")
println("sampleSNPrio.pnml")
# finiteenumeration, feconstant, partition, productsort, tuple,
Multisets.set_key_value_show()
@testset let fname=joinpath(@__DIR__, "data", "sampleSNPrio.pnml")
    #false &&
    model = pnmlmodel(fname)::PnmlModel
    summary(stdout, model)
    n = PNML.firstnet(model)::PnmlNet
    # @test vertex_codes(n) isa AbstractDict
    # @test vertex_labels(n) isa AbstractDict
    # PNML.show_sorts(n)
    #@show PNML.elabelT PNML.tparserT PNML.efilterT PNML.lparserT
    println()
    @show PNML.vsubT
    println()
    @show PNML.varsT
    println()

    # if !(narcs(n) > 0 && nplaces(n) > 0 && ntransitions(n) > 0)
    #     @test_throws ArgumentError PNML.metagraph(n)
    # else
    #     @test contains(sprint(show, PNML.metagraph(n)),
    #         "Meta graph based on a Graphs.SimpleGraphs.SimpleDiGraph{Int64}")
    # end
    #TODO more tests
    @show m₀ = initial_markings(n)
    @show e = enabled(n, m₀)
    @show C  = PNML.incidence_matrix(n) # Matrix of PnmlMultiset
    @show m₁ = fire2(C, n, m₀)
    #@test PNML.verify(net, true)
end

println("\n-----------------------------------------")
println("Sudoku-COL-BN01.pnml")
# productsort, tuple, finiteintrangeconstant, or, and, equality
@testset let fname=joinpath(@__DIR__, "data", "MCC/Sudoku-COL-BN01.pnml")
    model = pnmlmodel(fname)::PnmlModel
    summary(stdout, model) #first(PNML.nets(model)))
    n = first(PNML.nets(model))::PnmlNet
    # @test vertex_codes(n) isa AbstractDict
    # @test vertex_labels(n) isa AbstractDict
    # if !(narcs(n) > 0 && nplaces(n) > 0 && ntransitions(n) > 0)
    #     @test_throws ArgumentError PNML.metagraph(n)
    # else
    #     @test contains(sprint(show, PNML.metagraph(n)),
    #         "Meta graph based on a Graphs.SimpleGraphs.SimpleDiGraph{Int64}")
    # end
    #TODO more tests
end
