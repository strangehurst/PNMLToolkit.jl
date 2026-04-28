using PNML, Test,
JET, XMLDict

include("TestUtils.jl")
using .TestUtils

#---------------------------------------------
# ARC
#---------------------------------------------
function insc_xml(pntd)
    if is_highlevel(pntd)
        """<hlinscription>
            <text>6</text>
            <structure>
                <numberof>
                    <subterm>
                        <numberconstant value="6"> <positive/> </numberconstant>
                    </subterm>
                    <subterm> <dotconstant/> </subterm>
                </numberof>
            </structure>
           </hlinscription>"""
    else
        """<inscription> <text>6</text> </inscription>"""
    end
end
#! arc needs :place1 for adjacent place
"Parse place with marking, add to dict & id set"
function pl_node(net, netdata, netsets)
    node = if is_highlevel(net)
        xml"""
            <place id="place1">
            <name> <text>with text</text> </name>
            <type><structure><dot/></structure></type>
            <hlinitialMarking>
                <text>101</text>
                <structure>
                    <numberof>
                        <subterm>
                            <numberconstant value="11"><positive/></numberconstant>
                        </subterm>
                        <subterm><dotconstant/></subterm>
                    </numberof>
                </structure>
            </hlinitialMarking>
            </place>
            """
    else
        xml"""
            <place id="place1">
            <initialMarking> <text>1</text> </initialMarking>
            </place>
            """
    end
    pl = parse_place(node, net)
    push!(place_idset(netsets), pid(pl))
    placedict(netdata)[pid(pl)] = pl
end

#! arc needs :transition1 for adjacent transition
"Parse empty transition, add to dict & id set"
function tr_node(net, netdata, netsets)
    node = xml"""<transition id="transition1" />"""
    tr = parse_transition(node, net)
    push!(transition_idset(netsets), pid(tr))
    transitiondict(netdata)[pid(tr)] = tr
end

println("\nARC\n")
@testset "arc $pntd" for pntd in PnmlTypes.all_nettypes()
    net = make_net(pntd, :arc_net)
    netsets = PnmlNetKeys()
    pl_node(net, netdata(net), netsets)
    tr_node(net, netdata(net), netsets)

     node = xmlnode("""
      <arc source="transition1" target="place1" id="arc1">
        <name> <text>Some arc</text> </name>
        $(insc_xml(PNML.pntd(net)))
        <unknown id="unkn">
            <name> <text>unknown label</text> </name>
            <text>content text</text>
        </unknown>
        <graphics/>
        <toolspecific tool=":test" version="1.0.0" />
      </arc>
    """)

    a = @test_logs(match_mode=:any,
                  (:info, "add PnmlLabel :unknown to :arc1"),
                  parse_arc(node, net))
    @test typeof(a) <: Arc
    @test pid(a) === :arc1
    @test name(a) == "Some arc"
    @test has_graphics(a)
    @test_call inscription(a)
    #@show a inscription(a)(NamedTuple())
    if is_highlevel(net) # assumes storttype of dot
        @test cardinality(inscription(a)(NamedTuple())) == 6
    else
        @test inscription(a)(NamedTuple()) == 6
    end
    @test has_tools(a) == true
end

@testset "arc unknown label for $pntd" for pntd in PnmlTypes.all_nettypes()
    net = make_net(pntd, :arc_unknown)
    netsets = PnmlNetKeys()
    pl_node(net, netdata(net), netsets)
    tr_node(net, netdata(net), netsets)
    node = xmlnode("""
      <arc source="transition1" target="place1" id="arc1">
        <name> <text>Some arc</text> </name>
        $insc_xml(pntd(net))
        <unknown id="unkn">
            <name> <text>unknown label</text> </name>
            <text>content text</text>
        </unknown>
        <graphics/>
        <toolspecific tool=":test" version="1.0.0" />
      </arc>
    """)
   a = @test_logs(match_mode=:any,
                  (:info, "add PnmlLabel :unknown to :arc1"),
                  parse_arc(node, net))
end
