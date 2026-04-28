using PNML, Test, JET, NamedTupleTools

include("TestUtils.jl")
using .TestUtils

using EzXML: EzXML
using XMLDict: XMLDict
using ExproniconLite: JLCall, JLExpr, JLFor, JLIfElse, JLFunction,
                      JLField, JLKwField, JLStruct, JLKwStruct
using ExproniconLite: xtuple, xnamedtuple, xcall, xpush, xgetindex, xfirst, xlast,
                      xprint, xprintln, xmap, xmapreduce, xiterate

using PNML: mcontains

const pntd = HLCoreNet()
const net = make_net(pntd, :pnmlexpr_net)
const varsub = NamedTuple()

const node = xml"""
    <declaration>
        <structure>
            <declarations>
                <namedsort id="pluck" name="PLUCK">
                    <finiteenumeration>
                        <feconstant id="b1" name="b1" />
                        <feconstant id="b2" name="b2" />
                        <feconstant id="b3" name="b3" />
                        <feconstant id="b4" name="b4" />
                   </finiteenumeration>
                </namedsort>
           </declarations>
        </structure>
    </declaration>
    """

parse_declaration!(net, [node])

#^ Multiset Expression tests
#^------------------------------------------------------------------------

@testset "multiset add $pntd" begin
    # When will it be noticed that `:pro` is not a valid REFID?
    b1 = @inferred Bag(NamedSortRef(:pro), 1, NumberEx(NamedSortRef(:natural), 1))
    b2 = @inferred Bag(NamedSortRef(:pro), 2, NumberEx(NamedSortRef(:natural), 1))
    b3 = @inferred Bag(NamedSortRef(:pro), 3, NumberEx(NamedSortRef(:natural), 2))
    b4 = @inferred Bag(NamedSortRef(:pro), 4, NumberEx(NamedSortRef(:natural), 2))
    b5 = @inferred Bag(NamedSortRef(:pro), 4, NumberEx(NamedSortRef(:natural), 1))

    a = @inferred PNML.Add([b1, b2, b3])
    ex = @inferred toexpr(a, varsub, net)
    val = eval(ex)
    @test val == eval(toexpr(b1, varsub, net)) +
                 eval(toexpr(b2, varsub, net)) +
                 eval(toexpr(b3, varsub, net))
end

@testset "multiset contains $pntd" begin
    #println("multiset contains")
    b1 = Bag(NamedSortRef(:pro), 1, NumberEx(NamedSortRef(:natural), 1))
    b2 = Bag(NamedSortRef(:pro), 2, NumberEx(NamedSortRef(:natural), 1))
    b3 = Bag(NamedSortRef(:pro), 3, NumberEx(NamedSortRef(:natural), 2))
    b4 = Bag(NamedSortRef(:pro), 4, NumberEx(NamedSortRef(:natural), 2))
    b5 = Bag(NamedSortRef(:pro), 4, NumberEx(NamedSortRef(:natural), 1))

    aex = toexpr(PNML.Add([b1, b2, b4]), varsub, net)
    bex = toexpr(PNML.Add([b1, b2, b5]), varsub, net)

    a = eval(aex)
    b = eval(bex)
    Bag(a) # 1'1 2'1 3'2 4'2
    Bag(b) # 1'1 2'1 3'2 4'1
    # is bag(a) contains bag(b) or bag(b) issubset bag(a)
    c = @inferred Contains(Bag(a), Bag(b))
    ex = @inferred toexpr(c, varsub, net)
    @test eval(ex) == true

    c2 = Contains(Bag(b), Bag(a))
    @test eval(toexpr(c2, varsub, net)) == false

    println()
end

@testset "multiset and $pntd" begin
    b1 = BooleanEx(BooleanConstant(true))
    b2 = BooleanEx(BooleanConstant(false))
    b3 = BooleanEx(BooleanConstant(true))
    b4 = BooleanEx(BooleanConstant(false))

    a = PNML.And([b1, b2, b3, b4])
    ex = toexpr(a, varsub, net)
    val = eval(ex)
    @test val == eval(toexpr(b1, varsub, net)) &
                 eval(toexpr(b2, varsub, net)) &
                 eval(toexpr(b3, varsub, net)) &
                 eval(toexpr(b3, varsub, net))
end

@testset "multiset or $pntd" begin
    b1 = PNML.BooleanEx(BooleanConstant(true))
    b2 = PNML.BooleanEx(BooleanConstant(false))
    b3 = PNML.BooleanEx(BooleanConstant(true))
    b4 = PNML.BooleanEx(BooleanConstant(false))

    a = PNML.Or([b1, b2, b3, b4])
    ex = toexpr(a, varsub, net)
    val = eval(ex)
    @test val == eval(toexpr(b1, varsub, net)) |
                 eval(toexpr(b2, varsub, net)) |
                 eval(toexpr(b3, varsub, net)) |
                 eval(toexpr(b3, varsub, net))
end

#^ Boolean Expression tests
#^------------------------------------------------------------------------
function _test_abstractboolexpr(x::AbstractBoolExpr, net)
    #@show x
    @test PNML.basis(x) == NamedSortRef(:bool)
    @test sortref(x) == NamedSortRef(:bool)
    @test expr_sortref(x, net) == sortref(x)

end

@testset "AbstractBoolExpr" begin
    x = PNML.BooleanEx(BooleanConstant(true))
    _test_abstractboolexpr(x, net)
end

@testset "boolean not $pntd" begin
    b1 = PNML.BooleanEx(BooleanConstant(true))
    b2 = PNML.BooleanEx(BooleanConstant(false))

    a = PNML.Not([b1, b2])
    ex = toexpr(a, varsub, net)
    val = eval(ex)
    @test val == false

    @test eval(toexpr(PNML.Not([b2, b1]), varsub, net)) == false
    @test eval(toexpr(PNML.Not([b1, b1]), varsub, net)) == false
    @test eval(toexpr(PNML.Not([b2, b2]), varsub, net)) == true
end

# And, Or
