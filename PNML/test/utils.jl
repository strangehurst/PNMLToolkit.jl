using PNML
using PNML.PnmlTypes
using EzXML
using InteractiveUtils
using JET
using OrderedCollections
using Test
using XMLDict

include("TestUtils.jl")
using .TestUtils

@testset "CONFIG" begin
    @show PNML.CONFIG
    #@SciMLMessage  repr(PNML.CONFIG) PNML.verbose :information :options
    @show collect(PnmlTypes.core_nettypes())
    @show collect(PnmlTypes.all_nettypes())
    @show collect(PnmlTypes.all_nettypes(is_highlevel))
    @show collect(PnmlTypes.all_nettypes(!is_highlevel))
    @show collect(PnmlTypes.all_nettypes(is_discrete))
    @show collect(PnmlTypes.all_nettypes(!is_discrete))
    @show collect(PnmlTypes.all_nettypes(is_continuous))
    @show collect(PnmlTypes.all_nettypes(!is_continuous))
    @show collect(PnmlTypes.all_nettypes(is_collective_token))
    @show collect(PnmlTypes.all_nettypes(!is_collective_token))
    @show collect(PnmlTypes.all_nettypes(is_individual_token))
    @show collect(PnmlTypes.all_nettypes(!is_individual_token))
end

@testset "pntdsym pntd" for pntd in PnmlTypes.all_nettypes()
    let v = Val(pntd)
        @show v
        for pred in (is_discrete, is_continuous, is_highlevel, is_individual_token, is_collective_token)
            @test pred(v) isa Bool
            @test_call pred(Val(pntd))
            @test_opt pred(Val(pntd))
        end
    end
    for pred in (is_individual_token, is_collective_token)
        @test pred(pntd) isa Bool
        @test_call pred(pntd)
        #@test_opt pred(pntd)
    end
end
# @testset "add_nettype" begin
#     f=nothing # JETLS is confused
#     add_type! = PnmlTypes.add_nettype!
#     typemap   = PnmlTypes.pnmltype_map
#     @test_logs (:info, r"^updating mapping") @inferred add_type!(typemap, :pnmlcore, :pnmlcore)
#     @test_logs (:info, r"^updating mapping") @inferred add_type!(typemap, :hlcore, :hlcore)
#     @test_logs (:info, r"^updating mapping") @inferred add_type!(typemap, :ptnet, :ptnet)
#     @test_logs (:info, r"^updating mapping") @inferred add_type!(typemap, :hlnet, :hlpng)
#     @test_logs (:info, r"^updating mapping") @inferred add_type!(typemap, :pt_hlpng, PT_HLPNG())
#     @test_logs (:info, r"^updating mapping") @inferred add_type!(typemap, :symmetric, SymmetricNet())
#     @test_logs (:info, r"^updating mapping") @inferred add_type!(typemap, :continuous, ContinuousNet())

#     @test :newpntd ∉ keys(typemap)
#     @test_logs((:info, r"adding mapping from newpntd to"),
#          @inferred add_type!(typemap, :newpntd, :pnmlcore))
#     @test :newpntd in keys(typemap)
#     @test typemap[:newpntd] === PnmlCoreNet()
#     @show collect(PnmlTypes.all_nettypes())
# end

@testset "ExXML" begin
    @test_throws ArgumentError xml""
    @test_throws "empty XML string" xml""
end

@testset "getfirst XMLNode" begin
    node = xml"""<test>
        <a name="a1"/>
        <a name="a2"/>
        <a name="a3"/>
        <c name="c1"/>
        <c name="c2"/>
    </test>
    """
    @test_call target_modules=t_modules firstchild(node, "a")
    @test_call EzXML.nodename(firstchild(node, "a"))
    @test EzXML.nodename(firstchild(node, "a")) == "a"
    @test firstchild(node, "a")["name"] == "a1"
    @test firstchild(node, "b") === nothing
    @test EzXML.nodename(firstchild(node, "c")) == "c"

    @test_call target_modules=t_modules allchildren(node, "a")
    @test map(c->c["name"], @inferred(allchildren(node, "a"))) == ["a1", "a2", "a3"]
end


# @testset "default Condition, $pntd)" for pntd in PnmlTypes.all_nettypes()
#     c = @inferred default(Labels.Condition, net)
#     @test c() == true
# end

#println()
@testset "default inscription $pntd" for pntd in PnmlTypes.all_nettypes()
    net = make_net(pntd, :utils_net)
    # placetype = if is_highlevel(pntd)
    #     @inferred SortType("dummy", NamedSortRef(:dot), net)
    # elseif is_continuous(pntd)
    #     @inferred SortType("dummy", NamedSortRef(:real), net)
    # elseif is_discrete(pntd)
    #     @inferred SortType("dummy", NamedSortRef(:positive), net)
    # else
    #     error("pntd not known")
    # end
    if is_collective_token(pntd)
        @inferred Inscription default(Inscription, net)
    else
        @inferred Inscription default(Inscription, net,
                                      SortType("dummy", NamedSortRef(:dot), net))
    end
end

@testset "value_type(Rate, $pntd)" for pntd in PnmlTypes.all_nettypes()
    r = value_type(Rate, pntd)
    #println("value_type(Rate, $pntd) = ", r)
    @test r == eltype(RealSort) == Float64
end
@testset "sortref" begin
    @test @inferred(sortref(1)) == @inferred NamedSortRef(:integer)
    @test @inferred(sortref(0x1)) == @inferred NamedSortRef(:natural)
    @test @inferred(sortref(0x1234)) == @inferred NamedSortRef(:natural)
    @test @inferred(sortref(0x12345678)) == @inferred NamedSortRef(:natural)
    @test @inferred(sortref(0x1234567812345678)) == @inferred NamedSortRef(:natural)
    @test @inferred(sortref(1.0)) == @inferred NamedSortRef(:real)

    @test @inferred(sortref(Int64)) == NamedSortRef(:integer)
    @test @inferred(sortref(UInt64)) == NamedSortRef(:natural)
    @test @inferred(sortref(UInt32)) == NamedSortRef(:natural)
    @test @inferred(sortref(UInt16)) == NamedSortRef(:natural)
    @test @inferred(sortref(UInt8)) == NamedSortRef(:natural)
    @test @inferred(sortref(Float64)) == NamedSortRef(:real)
end
