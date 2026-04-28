using PNML, Test, JET, XMLDict

include("TestUtils.jl")
using .TestUtils

#---------------------------------------------
# TRANSITION
#---------------------------------------------

@testset "transition $pntd" for pntd in PnmlTypes.all_nettypes()
    node = xml"""
      <transition id="transition1">
        <name> <text>Some transition</text> </name>
        <condition> <text>always true</text>
                    <structure> <booleanconstant value="true"/></structure>
        </condition>
      </transition>
    """
    net = make_net(pntd, :transition_net)

    trans = @inferred Transition parse_transition(node, net)
    @test trans isa Transition
    @test pid(trans) === :transition1
    @test name(trans) == "Some transition"
    #@show condition(trans)()
    @test condition(trans)() isa Bool
    @test isempty(PNML.Labels.variables(condition(trans))::Vector{Symbol})

    @test varsubs(trans) isa Vector{NamedTuple}
    @test isempty(varsubs(trans))

    node = xml"""<transition id ="t1"> <condition><text>test w/o structure</text></condition></transition>"""
    @test_throws PNML.MalformedException parse_transition(node, net)

    node = xml"""<transition id ="t2"> <condition/> </transition>"""
    @test_throws Exception parse_transition(node, net)

    node = xml"""<transition id ="t3"> <condition><structure/></condition> </transition>"""
    @test_throws "ArgumentError: missing condition term in <structure>" parse_transition(node, net)

    node = xml"""<transition id ="t4">
        <condition>
        <text>test true 1</text>
            <structure> true </structure>
        </condition>
    </transition>"""
    @test_throws "ArgumentError: missing condition term in <structure>" parse_transition(node, net)

    node = xml"""<transition id ="t5">
        <condition>
            <text>test true 2</text>
            <structure> <booleanconstant value="true"/> </structure>
        </condition>
    </transition>"""
    t = parse_transition(node, net)
    @test t isa Transition
    @test condition(t)() == true
end

@testset "transition unknown label $pntd" for pntd in PnmlTypes.all_nettypes()
    node = xml"""
      <transition id="transition1">
        <name> <text>Some transition</text> </name>
        <condition> <text>always true</text>
                    <structure><booleanconstant value="true"/></structure>
        </condition>
        <somelabel2 c="value" />
     </transition>
    """
    net = make_net(pntd, :tran_unknown_label)

    trans = @test_logs((:info, "add PnmlLabel :somelabel2 to :transition1"),
                parse_transition(node, net)::Transition)
    @test pid(trans) === :transition1
    @test elements(labels(trans)[:somelabel2])[:c] == "value"
    @test get_label(trans, :somelabel2) !== nothing
    @test get_label(trans, :nosuchlabel) === nothing
    @test has_tools(trans) == false
end

#---------------------------------------------
# REFERENCE TRANSITION
#---------------------------------------------

@testset "ref Trans $pntd" for pntd in PnmlTypes.all_nettypes()
    node = xml"""
    <referenceTransition id="rt1" ref="t1">
        <name> <text>refTrans name</text> </name>
        <graphics><offset x="0" y="0"/></graphics>
        <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
    </referenceTransition>
    """
    net = make_net(pntd, :refrans_net)

    rtrans = parse_refTransition(node, net)::RefTransition
    @test pid(rtrans) === :rt1
    @test PNML.refid(rtrans) === :t1
    @test PNML.has_graphics(rtrans) && startswith(repr(PNML.graphics(rtrans)), "Graphics")
end

@testset "ref Trans unknown label $pntd" for pntd in PnmlTypes.all_nettypes()
    node = xml"""
    <referenceTransition id="rt1" ref="t1">
        <name> <text>refTrans name</text> </name>
        <graphics><offset x="0" y="0"/></graphics>
        <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
        <somelabel2 c="value" />
    </referenceTransition>
    """
    net = make_net(pntd, :refrans_unkn_net)

    trans = @test_logs((:info, "add PnmlLabel :somelabel2 to :rt1"),
            parse_refTransition(node, net)::RefTransition)
    @test pid(trans) === :rt1
    @test PNML.refid(trans) === :t1
    @test PNML.has_graphics(trans) && startswith(repr(PNML.graphics(trans)), "Graphics")
    @test labels(trans)[:somelabel2] == PNML.get_label(trans, :somelabel2)
    @test elements(PNML.get_label(trans, :somelabel2))[:c] == "value"
end
