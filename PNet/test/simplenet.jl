using Graphs, JET, Logging, MetaGraphsNext, PNet, Test
import PNML
using PNML: @xml_str, Arc, Page, Place, PnmlModel, PnmlNet, Transition, arc, arcs, condition,
    enabled, firstpage, has_arc, has_place, has_transition, initial_marking,
    initial_markings, inscription, narcs, nets, nplaces, ntransitions, pages, pid, place,
    places, pnmlmodel, pntd_of, rates, transition, transitions, xmlnode
using PNML.Parser
:xmlnode
using PNML.NetAPI

const t_modules = (PNML,PNet)

#testlogger = TestLogger()
println("SIMPLENET")
const str1 = """
<?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        <net id="net0" type="what">
            <page id="page0">
            <place id="p1"> <initialMarking> <text>1</text> </initialMarking> </place>
            <place id="p2"> <initialMarking> <text>2</text> </initialMarking> </place>
            <place id="p3">
                <structure att1="doo"/>
                <frog name="hoppy" />
            </place>
            <transition id ="t1"> </transition>
            <transition id ="t2"> </transition>
            <transition id ="t3"> </transition>
            <arc id="a1" source="p1" target="t1"> <inscription/> </arc>
            <arc id="a2" source="p2" target="t1"> <inscription/> </arc>
            <arc id="a3" source="t1" target="p3"> <inscription/> </arc>
            <arc id="a4" source="p3" target="t2"> <inscription/> </arc>
            <arc id="a5" source="t2" target="p1"> <inscription/> </arc>
            <arc id="a6" source="t2" target="p2"> <inscription/> </arc>
            </page>
        </net>
    </pnml>
"""
#@show t_modules

@testset "SIMPLENET" begin
    #!@test_call target_modules=t_modules pnmlmodel(xmlnode(str1))
    model = @test_logs(match_mode=:any,
                       (:info, "add PnmlLabel :structure to :p3"),
                       (:info, "add PnmlLabel :frog to :p3"),
                pnmlmodel(xmlnode(str1))::PnmlModel) #
    net0 = @inferred PnmlNet first(PNML.nets(model))

    simp1 = @inferred SimpleNet SimpleNet(model)
    simp  = @inferred SimpleNet SimpleNet(net0)

    #@test_opt target_modules=t_modules SimpleNet(net0)
    @test_call broken=false SimpleNet(net0)

    #@test_opt target_modules=t_modules SimpleNet(model)
    @test_call broken=false SimpleNet(model)

    for accessor in [PNML.pid,
                     PNML.place_idset, PNML.transition_idset, PNML.arc_idset,
                     PNML.reftransition_idset, PNML.refplace_idset]
        #@show accessor
        @test accessor(pnmlnet(simp1)) == accessor(pnmlnet(simp))
    end

    @testset "inferred" begin
        # First @inferred failure throws exception ending testset.
        @test firstpage(simp.net) === first(pages(simp.net))

        #@inferred places(first(pages(net.net)))
        #@inferred transitions(first(pages(net.net)))
        #@inferred arcs(first(pages(net.net)))

        #@inferred places(net.net)
        #@inferred transitions(net.net)
        #@inferred arcs(net.net)

        @inferred Base.ValueIterator places(simp.net)
        @inferred Base.ValueIterator transitions(simp.net)
        @inferred Base.ValueIterator arcs(simp.net)
    end

    # page, pnmlnet, petrinet, the 3 top=levels
    #@show typeof(first(pages(simp.net))) typeof(simp.net) typeof(simp)
    @test first(pages(pnmlnet(simp))) isa Page
    @test simp.net isa PnmlNet
    @test simp isa AbstractPetriNet

    # For a flattened net these should have the same behavior.
    for top in [first(pages(simp.net)), simp.net]

        @test_call target_modules=t_modules places(top)
        for placeid in PNML.place_idset(top)
            PNML.has_place(top, placeid)
            @test_call PNML.has_place(top, placeid)
            @test @inferred PNML.has_place(top, placeid)
            p = @inferred Union{Nothing,PNML.Place} PNML.place(top, placeid)
        end

        @test_call target_modules=t_modules PNML.transitions(top)
        for t in PNML.transitions(top)
            @test PNML.ispid(pid(t))(pid(t))
            @test_call has_transition(top, pid(t))
            @test @inferred Union{Nothing,Bool} has_transition(top, pid(t))
            t == @inferred Union{Nothing,Transition} transition(top, pid(t))
            @test pid(t) === t.id

            @test @inferred(condition(t)()) !== nothing
        end

        @test_call target_modules=t_modules PNML.arcs(top)
        for a in PNML.arcs(top)
            @test @inferred Union{Nothing,Bool} has_arc(top, pid(a))
            a == @inferred Union{Nothing,Arc} arc(top, pid(a))
            @test pid(a) === a.id
                        @test @inferred(PNML.source(a)) !== nothing
            @test @inferred(PNML.target(a)) !== nothing
            @test @inferred(Number, inscription(a)(NamedTuple())) !== nothing
        end
    end

    # PetriNet-only methods.
    @testset "initialMarking" begin
        u1 = @inferred Vector initial_markings(simp)
    end
end

# Used in precompile.
@testset "simple ptnet" begin
    #@show "precompile's SimpleNet"
    @test SimpleNet(xml"""<?xml version="1.0"?>
        <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        <net id="smallnet" type="http://www.pnml.org/version-2009/grammar/ptnet">
            <name> <text>P/T Net with one place</text> </name>
            <page id="page1">
            <place id="place1">
                <initialMarking> <text>100</text> </initialMarking>
            </place>
            <transition id="transition1">
                <name><text>Some transition</text></name>
            </transition>
            <arc source="transition1" target="place1" id="arc1">
                <inscription><text>12</text></inscription>
            </arc>
            </page>
        </net>
        </pnml>""") isa SimpleNet
end

@testset "rate" begin
    model = @inferred PNML.PnmlModel PNML.pnmlmodel(xml"""<?xml version="1.0"?>
        <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
            <net id="net0" type="core">
            <page id="page0">
                <transition id ="birth"><rate> <text>0.3</text> </rate> </transition>
            </page>
            </net>
        </pnml>
        """)
    net = @inferred PnmlNet first(PNML.nets(model))
    simp = @inferred SimpleNet(net)
    @test contains(sprint(show, simp), "SimpleNet")
    #@show simp.net
    β = [pid(tr) => PNML.rate_value(tr) for tr in PNML.transitions(simp.net)]
    @test β == [:birth=>0.3]
end


@testset "lotka-volterra" begin
    str3 = """<?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        <net id="net0" type="continuous">
        <page id="page0">
            <place id="wolves">  <initialMarking> <text>10.0</text> </initialMarking> </place>
            <place id="rabbits"> <initialMarking> <text>100.0</text> </initialMarking> </place>
            <transition id ="birth">     <rate> <text>0.3</text> </rate> </transition>
            <transition id ="predation"> <rate> <text>0.015</text> </rate> </transition>
            <transition id ="death">     <rate> <text>0.7</text> </rate> </transition>
            <arc id="a1" source="rabbits"   target="birth"> <inscription><text>1.0</text> </inscription> </arc>
            <arc id="a2" source="birth"     target="rabbits"> <inscription><text>2.0</text> </inscription> </arc>
            <arc id="a3" source="wolves"    target="predation"> <inscription><text>1.0</text> </inscription> </arc>
            <arc id="a4" source="rabbits"   target="predation"> <inscription><text>1.0</text> </inscription> </arc>
            <arc id="a5" source="predation" target="wolves"> <inscription><text>2.0</text> </inscription> </arc>
            <arc id="a6" source="wolves"    target="death"> <inscription><text>1.0</text> </inscription> </arc>
        </page>
        </net>
    </pnml>
    """
    model = @inferred PnmlModel PNML.pnmlmodel(PNML.Parser.xmlnode(str3))
    net1 = first(nets(model));          #@show typeof(net1)
    simp = @inferred SimpleNet(net1); #@show typeof(simp)

    @show S = @inferred collect(PNML.place_idset(simp.net)) # [:rabbits, :wolves]
    @show T = @inferred collect(PNML.transition_idset(simp.net))
    @show m₀ = initial_markings(simp.net)
    @show input = input_matrix(pnmlnet(simp))
    @show output_matrix(pnmlnet(simp))
    @show dt = PNML.incidence_matrix(pnmlnet(simp))

    #@show lp = collect(PNML.labeled_places(net1))
    #@show lt = collect(PNML.labeled_transitions(net1))
    #@show t = collect(PNML.counted_transitions(net1))


    @show PNML.enabled(simp.net, m₀)

    println("all arcs :wolves = ", collect(PNML.all_arcs(simp.net, :wolves)))
    println("src arcs :wolves = ", collect(PNML.src_arcs(simp.net, :wolves)))
    println("tgt arcs :wolves = ", collect(PNML.tgt_arcs(simp.net, :wolves)))

    # # keys are transition ids
    # # values are input, output vectors of "tuples" place id -> inscription of arc
    # Δ = PNML.PNet.transition_function(simp.net)#,T)
    # @show Δ
    # println()

    # # Expected result
    # expected_transition_function = LVector(
    #     birth=(LVector(rabbits=1.0), LVector(rabbits=2.0)),
    #     predation=(LVector(wolves=1.0, rabbits=1.0), LVector(wolves=2.0)),
    #     death=(LVector(wolves=1.0), LVector()),
    # )

    # @test Δ.birth     == expected_transition_function.birth
    # @test Δ.predation == expected_transition_function.predation
    # @test Δ.death     == expected_transition_function.death

    expected_u0 = [10.0, 100.0] # initialMarking
    @show u0 = initial_markings(simp.net)
    @test u0 == expected_u0

    expected_β = [:birth=>0.3, :predation=>0.015, :death=>0.7] # transition rate
    @show β = [pid(tr) => PNML.rate_value(tr) for tr in PNML.transitions(simp.net)]
    @test β == expected_β

    let net = pnmlnet(simp)
        @show du = map(last, initial_markings(simp.net))
        #map(last, collect(du))
        @show valtype(du)
        @show rate_vals = zeros(valtype(du), ntransitions(net)) # φ in paper
        # φ = [βₜ Σ\_(s∈r(t)) uₛ for t in preset(net, transition_id)]
        # r : T → N^S is preset(net, transition_id)
        # p : S → N^T is preset(net, place_id)
        # r^-1 : S → N^T is preset(net, place_id)

        for (i, t) in enumerate(PNML.transitions(net))
            @show PNML.rate_value(t)
            @show [pid(p) for (j,p) in enumerate(PNML.places(net))]
            @show collect(PNML.preset(net, pid(t)))
            @show collect(PNML.postset(net, pid(t)))
            for (j,p) in enumerate(PNML.places(net))
                @show collect(PNML.preset(net, pid(p)))
                @show collect(PNML.postset(net, pid(p)))
            end
            @show [pid(p) for (j,p) in enumerate(PNML.places(net)) if pid(p) in PNML.preset(net, pid(t))]
            rate_vals[i] = PNML.rate_value(t) * prod(initial_marking(p) ^ input[i, j]
                for (j,p) in enumerate(PNML.places(net)) if pid(p) in PNML.preset(net, pid(t)))
        end
        @show rate_vals
        for j in 1:nplaces(net)
            du[j] = sum(rate_vals[i] * dt[i, j] for i in 1:ntransitions(net); init=0.0)
        end
        @show du
    end
end


# String so that pntd can be embedded in the XML.
const core_types = ("pnmlcore","ptnet",)
@warn "hl nets do not currently do linear algebra! 'fire' will error."
const hl_types = ("pt_hlpng",) # ("hlcore","symmetric") #,"pt_hlpng","hlnet",)
const ex_types = ("continuous",)

@testset "extract a graph $pntd" for pntd in tuple(core_types..., hl_types..., ex_types...)
    if pntd in hl_types
        marking = """
        <hlinitialMarking>
            <text>1</text>
            <structure>
                <numberof>
                    <subterm><numberconstant value="1"><positive/></numberconstant></subterm>
                    <subterm><dotconstant/></subterm>
                </numberof>
            </structure>
        </hlinitialMarking>
        """
        insctag = "hlinscription"
    elseif pntd == "continuous"
        marking = """
        <initialMarking>
            <text>1.0</text>
        </initialMarking>
        """
        insctag = "inscription"
    else
        marking = """
        <initialMarking>
            <text>1</text>
        </initialMarking>
        """
        insctag = "inscription"
    end
    #println()
    #println(marking)
    str3 = """<?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        <net id="net0" type="$pntd">
        <name><text>test petri net</text></name>
        <page id="page0">
            <place id="p1"> $marking </place>
            <place id="p2"/>
            <place id="p3"/>
            <place id="p4"/>
            <place id="pcount"/>

            <transition id="t1">
                <condition>
                    <text></text><structure><booleanconstant value="true"/></structure>
                </condition>
            </transition>
            <transition id="t2"/>
            <transition id="t3"/>
            <transition id="t4"/>

            <arc id="a1" source="p1"   target="t1"/>
            <arc id="a2" source="t1"   target="p2"/>

            <arc id="a3" source="p2"   target="t2"/>
            <arc id="a4" source="t2"   target="p3"/>

            <arc id="a5" source="p3"   target="t3"/>
            <arc id="a6" source="t3"   target="p4"/>

            <arc id="a7" source="p4"   target="t4"/>
            <arc id="a8" source="t4"   target="p1"/>

            <arc id="a9" source="t4"   target="pcount"/> <!-- of loops completed -->
        </page>
        </net>
    </pnml>
    """
    anet = SimpleNet(PNML.Parser.xmlnode(str3))::AbstractPetriNet
    mg = PNML.metagraph(pnmlnet(anet))
    #! mg2 = PNML.metagraph(anet)

    m₀ = initial_markings(anet.net)
    C  = PNML.incidence_matrix(anet.net) # Matrix of PnmlMultiset
    e  = PNML.enabled(anet.net, m₀)
    #@show m₀ C e typeof(e)

    @test e == Bool[1,0,0,0]
    @test e == [true,false,false,false] # 3 representations of the enabled vector.
    @test e == [1,0,0,0]

    m₁ = PNML.fire2(C, anet.net, m₀)
    @test PNML.enabled(anet.net, m₁) == [false,true,false,false]

    m₂ = PNML.fire2(C, anet.net, m₁)
    @test PNML.enabled(anet.net, m₂) == [false,false,true,false]

    m₃ = PNML.fire2(C, anet.net, m₂)
    @test PNML.enabled(anet.net, m₃) == [false,false,false,true]

    m₄ = PNML.fire2(C, anet.net, m₃)
    @test PNML.enabled(anet.net, m₄) == [true,false,false,false]

    let mx = m₀
        for n in 1:10
            mx = PNML.fire2(C, anet.net, mx)
        end
        @test PNML.enabled(anet.net, mx) == [false,false,true,false]
    end
end
