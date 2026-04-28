using PNML, Test, JET, NamedTupleTools
using EzXML: EzXML
using XMLDict: XMLDict

include("TestUtils.jl")
using .TestUtils

println("PRIORITY")
@testset "get priority label $pntd" for pntd in PnmlTypes.all_nettypes()
    net = make_net(pntd, :priority_label_net)

    trans = PNML.Parser.parse_transition(
        xml"""<transition id ="birth">
                <priority> <text>0.3</text> </priority>
            </transition>""", net)
    #@show lab = PNML.labels(trans)

    @test PNML.get_label(trans, :nosuchlabel) === nothing
    lab = PNML.get_label(trans, :priority)
    @test PNML.get_label(trans, :priority) === PNML.labels(trans)[:priority]
    @test PNML.get_label(trans, :priority) == lab != nothing
    @test PNML.priority_value(trans) ≈ 0.3

    @test_call PNML.get_label(trans, :priority)
    @test_call PNML.labels(trans)
    @test_call PNML.priority_value(trans)

    tr = @inferred PNML.priority_value(trans)
    @test eltype(tr) == value_type(Labels.Priority)
end

@testset "get defaulted priority label $pntd" for pntd in PnmlTypes.all_nettypes()
    net = make_net(pntd, :default_priority_net)
    node = xml"""<transition id ="birth">
                    <priorityX> <text> 0.3 </text> </priorityX>
                 </transition>"""
    tr = @test_logs(match_mode=:any, (:info, r"add PnmlLabel"),
                    PNML.Parser.parse_transition(node, net))
    @test PNML.priority_value(tr) ≈ 1.0
end
