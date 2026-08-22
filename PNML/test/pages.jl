using PNML, JET, Test

include("TestUtils.jl")
using .TestUtils

println("\nPAGES\n")

function verify_sets(net::PnmlNet)
    println("\nverify sets and structure ++++++++++++++++++++++")
    # @show net
    # @show keys(pagedict(net))
    # @show pageids(net)  page_idset(firstpage(net))

    @test !isempty(setdiff(page_idset(net), page_idset(firstpage(net))))

    # @test arc_ids(net) isa AbstractSet
    # @test arc_idset(firstpage(net)) isa AbstractSet
    # #@show arc_ids(net) arc_idset(firstpage(net))
    # @test !isempty(setdiff(arc_ids(net), arc_idset(firstpage(net))))

    # @test place_ids(net) isa AbstractSet
    # @test place_idset(firstpage(net)) isa AbstractSet
    # @test !isempty(setdiff(place_ids(net), place_idset(firstpage(net))))

    # @test transition_ids(net) isa AbstractSet
    # @test transition_idset(firstpage(net)) isa AbstractSet
    # @test !isempty(setdiff(transition_ids(net), transition_idset(firstpage(net))))

    # @test refplace_ids(net) isa AbstractSet
    # @test refplace_idset(firstpage(net)) isa AbstractSet
    # @test !isempty(setdiff(refplace_ids(net), refplace_idset(firstpage(net))))

    # @test reftransition_ids(net) isa AbstractSet
    # @test reftransition_idset(firstpage(net)) isa AbstractSet
    # @test !isempty(setdiff(reftransition_ids(net), reftransition_idset(firstpage(net))))

    for page in allpages(net)
        @test pagedict(net) === pagedict(page) # There is only 1 pagedict.
    end

    @test PNML.has_tools(net) == true
end

const model = @inferred PNML.PnmlModel pnmlmodel(xml"""<?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        <net id="net0" type="pnmlcore">
            <page id="page1">
                <place id="p1"/>
                <transition id ="t1"/>
                <arc id="a11" source="p1" target="t1"/>
                <arc id="a12" source="t1" target="rp1"/>
                <referencePlace id="rp1" ref="p2"/>
                <page id="page11">
                    <place id="p11" />
                    <page id="page111">
                        <place id="p111" />
                    </page>
                </page>
                <page id="page12" />
                <page id="page13" />
                <page id="page14" />
            </page>
            <page id="page2">
                <place id="p2"/>
                <transition id ="t2"/>
                <arc id="a21" source="t2" target="p2"/>
                <arc id="a22" source="t2" target="rp2"/>
                <referencePlace id="rp2" ref="p3111"/>
                <referenceTransition id="rt2" ref="t3"/>
            </page>
            <page id="page3">
                <place id="p3"/>
                <transition id ="t3"/>
                <arc id="a31" source="t3" target="p4"/>
                <page id="page31">
                    <place id="p31"/>
                    <transition id ="t31"/>
                    <arc id="a311" source="t31" target="p1"/>
                    <page id="page311">
                        <place id="p311" />
                        <page id="page3111">
                            <place id="p3111" />
                        </page>
                    </page>
                    <page id="page312" />
                    <page id="page313" />
                    <page id="page314" />
                </page>
            </page>
        </net>
    </pnml>
""")
summary(stdout, model)
net = firstnet(model)
@test net isa PnmlNet  # Any concrete subtype.
@test isconcretetype(typeof(net))
@test startswith(sprint(show, model), "PnmlModel")
@test firstpage(net) isa Page # add parameters? #! @inferred
@test length(PNML.allpages(net)) == 14

@test_logs sprint(println, PNML.allpages(net))
verify_sets(net)

@testset "by pntd $pntd" for pntd in PnmlTypes.core_nettypes()
    for ot in (PNML.Coordinate, Inscription, PNML.Labels.Condition, Marking,
                Priority, Rate, PNML.Labels.Time)
        @test_opt function_filter=pff target_modules=t_modules value_type(ot, Val(pntd))
        @test_call value_type(ot, Val(pntd))
    end

    # default test is not page specific
    # for ot in (Inscription, PNML.Labels.Condition, Marking)
    #     @test_opt function_filter=pff target_modules=t_modules PNML.default(ot, XXX)
    #     @test_call PNML.default(ot, XXX)
    # end
end

exp_arc_ids           = [:a11, :a12, :a21, :a22, :a31, :a311]
exp_place_ids         = [:p1, :p11, :p111, :p2, :p3, :p31, :p311, :p3111]
exp_transition_ids    = [:t1, :t2, :t3, :t31]
exp_refplace_ids      = [:rp1, :rp2]
exp_reftransition_ids = [:rt2]

@test isempty(setdiff(@inferred(PNML.place_ids(net)), exp_place_ids))
@test isempty(setdiff(@inferred(PNML.arc_ids(net)), exp_arc_ids))
@test isempty(setdiff(@inferred(PNML.transition_ids(net)), exp_transition_ids))
@test isempty(setdiff(@inferred(PNML.refplace_ids(net)), exp_refplace_ids))
@test isempty(setdiff(@inferred(PNML.reftransition_ids(net)), exp_reftransition_ids))

for arcid in exp_arc_ids
    @test !isnothing(arc(net, arcid))
end

@test arcs(net) !== nothing
@test places(net) !== nothing
@test transitions(net) !== nothing
@test refplaces(net) !== nothing
@test reftransitions(net) !== nothing

@test narcs(net) != 0
@test nplaces(net) != 0
@test ntransitions(net) != 0
@test nrefplaces(net) != 0
@test nreftransitions(net) != 0

@testset "flatten" begin
    println("---------------"^4)
    flatten_pages!(net; verbose=false)
    println("---------------"^4)

    expected_a = [:a11, :a12, :a21, :a22, :a31, :a311]
    expected_p = [:p1, :p11, :p111, :p2, :p3, :p31, :p311, :p3111]
    expected_t = [:t1, :t2, :t3, :t31]
    expected_rt = [] # removed by flatten
    expected_rp = [] # removed by flatten
    @show arc_ids(net)
    @show arc_idset(firstpage(net))
    @show expected_a
    @show setdiff(arc_ids(net), expected_a)

    @test isempty(setdiff(arc_ids(net), expected_a))
    @test isempty(setdiff(arc_idset(firstpage(net)), expected_a))
    @test isempty(setdiff(arc_ids(net), arc_idset(firstpage(net))))
    @test_call target_modules=t_modules arc_ids(net)
    @test_call arc_idset(firstpage(net))
    for a ∈ expected_a
        @test a ∈ arc_ids(net)
        @test a ∈ arc_idset(firstpage(net))
    end

    @test isempty(setdiff(place_ids(net), expected_p))
    @test isempty(setdiff(place_idset(firstpage(net)), expected_p))
    @test isempty(setdiff(place_ids(net), place_idset(firstpage(net))))
    @test_call target_modules=t_modules place_ids(net)
    @test_call place_idset(firstpage(net))
    for p ∈ expected_p
        @test p ∈ place_ids(net)
    end

    @test (sort ∘ collect)(transition_ids(net)) == expected_t
    @test (sort ∘ collect)(transition_idset(firstpage(net))) == expected_t
    @test (sort ∘ collect)(transition_ids(net)) == (sort ∘ collect)(transition_idset(firstpage(net)))
    @test_call target_modules=t_modules transition_ids(net)
    @test_call transition_idset(firstpage(net))
    for t ∈ expected_t
        @test t ∈ transition_ids(net)
    end

    @test isempty(reftransition_ids(net))
    @test isempty(reftransition_idset(firstpage(net)))
    @test (sort ∘ collect)(reftransition_ids(net)) == expected_rt
    @test (sort ∘ collect)(reftransition_idset(firstpage(net))) == expected_rt
    @test (sort ∘ collect)(reftransition_ids(net)) == (sort ∘ collect)(reftransition_idset(firstpage(net)))
    @test_call target_modules=t_modules reftransition_ids(net)
    @test_call reftransition_idset(firstpage(net))
    for rt ∈ expected_rt
        @test rt ∈ reftransition_ids(net)
    end

    @test isempty(refplace_ids(net))
    @test isempty(refplace_idset(firstpage(net)))
    @test (sort ∘ collect)(refplace_ids(net)) == expected_rp
    @test (sort ∘ collect)(refplace_idset(firstpage(net))) == expected_rp
    @test (sort ∘ collect)(refplace_ids(net)) == (sort ∘ collect)(refplace_idset(firstpage(net)))
    @test_call target_modules=t_modules refplace_ids(net)
    @test_call refplace_idset(firstpage(net))
    for rp ∈ expected_rp
        @test rp ∈ refplace_ids(net)
    end
end

@testset "lookup types $pntd" for pntd in PnmlTypes.all_nettypes()
    if is_highlevel(pntd)
        @show pntd
        @show value_type(Inscription, Val(pntd)) #<: PnmlMultiset
        @show value_type(Marking, Val(pntd)) #<: PNML.PnmlMultiset
    else
        @test value_type(Inscription, Val(pntd)) <: Number
        @test value_type(Marking, Val(pntd)) <: Number
    end
    @test value_type(PNML.Labels.Condition, Val(pntd)) <: Bool
    @test value_type(Rate, Val(pntd)) <: Float64
end
