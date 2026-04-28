using PNML, Test, JET, XMLDict

include("TestUtils.jl")
using .TestUtils

#---------------------------------------------
# PLACE
#---------------------------------------------

@testset "place $pntd" for pntd in PnmlTypes.all_nettypes(!is_highlevel)
    node = xml"""
        <place id="place1">
        <name> <text>with text</text> </name>
        <initialMarking>
            <text>100</text>
            <!-- standard does not use/allow structure here
            <structure><numberconstant value="100"><integer/></numberconstant></structure>
            -->
        </initialMarking>
        </place>
    """
    net = make_net(pntd, :pt_place_net)

    placetype = SortType("XXX", NamedSortRef(:natural), net)

    place  = parse_place(node, net)::Place
    # pntd isa PnmlCoreNet &&
    #     @test_opt target_modules=t_modules broken=false parse_place(node, net)
    @test_call target_modules=t_modules parse_place(node, net)
    @test @inferred(pid(place)) === :place1
    @test @inferred(name(place)) == "with text"
    @test_call initial_marking(place)
    #@show pntd, initial_marking(place)
    @test initial_marking(place)::Number == 100
    @test PNML.get_label(place, :nosuchlabel) === nothing
    @test PNML.has_tools(place) == false
end

@testset "place $pntd" for pntd in PnmlTypes.all_nettypes(is_highlevel)
    node = xml"""
        <place id="place1">
        <name> <text>with text</text> </name>
        <type><structure><dot/></structure></type>
        <hlinitialMarking>
            <text>101</text>
            <structure>
            <numberof>
                <subterm><numberconstant value="101"><positive/></numberconstant></subterm>
                <subterm><dotconstant/></subterm>
            </numberof>
            </structure>
        </hlinitialMarking>
        </place>
    """
    net = make_net(pntd, :hl_place_net)

    place = parse_place(node, net)::Place
    #!@test_call target_modules=t_modules parse_place(node, net)

    @test @inferred(pid(place)) === :place1
    @test @inferred(name(place)) == "with text"
    @test_call target_modules=t_modules initial_marking(place)
    #@show pntd, initial_marking(place)
    @test PNML.cardinality(initial_marking(place)::PnmlMultiset) == 101
    @test PNML.get_label(place, :nosuchlabel) === nothing
end

@testset "place unknown label $pntd" for pntd in PnmlTypes.all_nettypes(is_highlevel)
    node = xml"""
        <place id="place1">
        <type><structure><dot/></structure></type>
        <hlinitialMarking>
            <text>101</text>
            <structure>
            <numberof>
                <subterm><numberconstant value="101"><positive/></numberconstant></subterm>
                <subterm><dotconstant/></subterm>
            </numberof>
            </structure>
        </hlinitialMarking>
        <somelabel1 a="text">
            <another b="more" />
        </somelabel1>
        <somelabel2 c="value" />
        </place>
    """
    net = make_net(pntd, :place_unknown_label)
    place = @test_logs((:info, "add PnmlLabel :somelabel1 to :place1"),
                       (:info, "add PnmlLabel :somelabel2 to :place1"),
                       parse_place(node, net)::Place)
    @test pid(place) === :place1
    @test name(place) == ""
    @test PNML.get_label(place, :nosuchlabel) === nothing
    @test elements(get_label(place, :somelabel1))[:a] == "text"
    @test elements(get_label(place, :somelabel1))["another"][:b] == "more"
    @test elements(get_label(place, :somelabel2))[:c] == "value"
end

#---------------------------------------------
# REFERENCE PLACE
#---------------------------------------------

@testset "ref Place $pntd" for pntd in PnmlTypes.all_nettypes()
    node = xml"""
    <referencePlace id="rp1" ref="p1">
        <name>
            <text>refPlace name</text>
        </name>
        <graphics><offset x="0" y="0"/></graphics>
        <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
    </referencePlace>"""

    net = make_net(pntd, :refplace_net)
    place = parse_refPlace(node, net)::RefPlace
    @test pid(place) === :rp1
    @test PNML.refid(place) === :p1
    @test PNML.get_label(place, :nosuchlabel) === nothing
end

@testset "ref Place $pntd" for pntd in PnmlTypes.all_nettypes()
    node = xml"""
    <referencePlace id="rp1" ref="p1">
        <name>
            <text>refPlace name</text>
        </name>
        <graphics><offset x="0" y="0"/></graphics>
        <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
        <somelabel2 c="value" />
    </referencePlace>"""

    net = make_net(pntd, :refplace_extra_net)
    place = @test_logs((:info, "add PnmlLabel :somelabel2 to :rp1"),
            parse_refPlace(node, net)::RefPlace)
    @test pid(place) === :rp1
    @test PNML.refid(place) === :p1
    @test elements(labels(place)[:somelabel2])[:c] == "value"
    @test PNML.get_label(place, :nosuchlabel) === nothing
end
