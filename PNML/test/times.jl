using PNML, Test, JET, NamedTupleTools
using EzXML: EzXML
using XMLDict: XMLDict

include("TestUtils.jl")
using .TestUtils

# timed petri net is a metamodel

println("DELAY")
@testset "delay label $pntd" for pntd in PnmlTypes.all_nettypes()
    #println("delay label $pntd")
    net = make_net(pntd, :delay_label_net)
    # From [Tina .pnml formt](file://~/PetriNet/tina-3.7.5/doc/html/formats.html#5)
    # This bit may be from the pre-standard era.
    # <ci> is a variable(constant) like pi, infinity.
    # <cn> is a number (real)
    # interval [4,9]
    node = xml"""<transition id ="t6">
        <delay>
            <interval xmlns="http://www.w3.org/1998/Math/MathML" closure="closed">
                <cn>4.0</cn>
                <cn>9.0</cn>
            </interval>
        </delay>
    </transition>"""
    #! This has Float64 and Int
    trans = @test_logs((:info, "add PnmlLabel :delay to :t6"),
        parse_transition(node, net)::Transition)

    del = PNML.get_label(trans, :delay)
    @test PNML.get_label(trans, :delay) == del
    @test PNML.get_label(trans, :missinglabel) == nothing

    #@show elements(del)["interval"]
    #! XXX where did xmlns dissappear
    #@test elements(del)["interval"][:xmlns] == "http://www.w3.org/1998/Math/MathML"
    @test elements(del)["interval"][:closure] == "closed"
    @test elements(del)["interval"]["cn"] == ["4.0", "9.0"]

    node = xml"""<transition id ="t7">
        <delay>
            <interval xmlns="http://www.w3.org/1998/Math/MathML" closure="closed-open">
                <cn>4</cn>
                <ci>infty</ci>
            </interval>
        </delay>
    </transition>"""
    trans = @test_logs((:info, "add PnmlLabel :delay to :t7"),
        parse_transition(node, net)::Transition)
    del = PNML.get_label(trans, :delay)
    @test PNML.get_label(trans, :delay) == del
    @test elements(del)["interval"][:closure] == "closed-open"
    @test elements(del)["interval"]["cn"] == "4"
    @test elements(del)["interval"]["ci"] == "infty"

    node = xml"""<transition id ="t8">
        <delay>
            <interval xmlns="http://www.w3.org/1998/Math/MathML" closure="open">
                <cn>3</cn>
                <cn>5</cn>
            </interval>
        </delay>
    </transition>"""
    trans = @test_logs((:info, "add PnmlLabel :delay to :t8"),
        parse_transition(node, net)::Transition)
    del = PNML.get_label(trans, :delay)
    @test PNML.get_label(trans, :delay) == del
    @test elements(del)["interval"][:closure] == "open"
    @test elements(del)["interval"]["cn"] == ["3", "5"]
end
