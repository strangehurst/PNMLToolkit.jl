using PNML, JET, Test

include("TestUtils.jl")
using .TestUtils

# String so that pntd can be embedded in the XML.
const core_types = ("pnmlcore","ptnet",)
const ex_types = ("continuous",)
const hl_types = ("pt_hlpng",) #"hlcore","symmetric") #,"hlnet",)

@warn "hl nets do not currently do linear algebra! 'fire' will error."

@testset "firing rule: $pntd" for pntd in tuple(core_types..., ex_types..., hl_types...)
    if pntd in hl_types
        #^ Only PT_HLPNG supported here
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
    elseif pntd == "continuous"
        marking = """
        <initialMarking>
            <text>1.0</text>
        </initialMarking>
        """
    else
        marking = """
        <initialMarking>
            <text>1</text>
        </initialMarking>
        """
    end #= if pntd in hl_types =#
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

    model = pnmlmodel(xmlnode(str3))
    anet = first(nets(model))::PnmlNet
    #~ @show anet
    @test_logs PNML.metagraph(anet)
    #@show mg

    m₀ = PNML.initial_markings(anet)
    imatrix  = PNML.incidence_matrix(anet) # Matrix of PnmlMultiset
    enabled_vec  = PNML.enabled(anet, m₀)
    #~ @show pntd m₀ imatrix enabled_vec #typeof(e)
    # 3 representations of the enabled vector.
    @test enabled_vec == Bool[1,0,0,0]
    @test enabled_vec == [true,false,false,false]
    @test enabled_vec == [1,0,0,0]

    m₁ = PNML.fire2(imatrix, anet, m₀)
    @test PNML.enabled(anet, m₁) == [false,true,false,false]

    m₂ = PNML.fire2(imatrix, anet, m₁)
    @test PNML.enabled(anet, m₂) == [false,false,true,false]

    m₃ = PNML.fire2(imatrix, anet, m₂)
    @test PNML.enabled(anet, m₃) == [false,false,false,true]

    m₄ = PNML.fire2(imatrix, anet, m₃)
    @test PNML.enabled(anet, m₄) == [true,false,false,false]

    let mx = m₀
        for n in 1:10
            mx = PNML.fire2(imatrix, anet, mx)
        end
        @test PNML.enabled(anet, mx) == [false,false,true,false]
        @show mx
    end
end
