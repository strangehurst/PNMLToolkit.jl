using PNML, Test, JET

include("TestUtils.jl")
using .TestUtils

@testset "pntd_symbol" begin
    @test_opt PnmlTypes.pntd_symbol("foo")
    @test_call PnmlTypes.pntd_symbol("foo")

    @test PnmlTypes.pntd_symbol("foo") === :pnmlcore

    @test PnmlTypes.pntd_symbol("http://www.pnml.org/version-2009/grammar/ptnet") === :ptnet
    @test PnmlTypes.pntd_symbol("http://www.pnml.org/version-2009/grammar/highlevelnet") === :hlnet
    @test PnmlTypes.pntd_symbol("http://www.pnml.org/version-2009/grammar/pnmlcoremodel") === :pnmlcore
    @test PnmlTypes.pntd_symbol("http://www.pnml.org/version-2009/grammar/pnmlcore") === :pnmlcore
    @test PnmlTypes.pntd_symbol("http://www.pnml.org/version-2009/grammar/pt-hlpng") === :pt_hlpng
    @test PnmlTypes.pntd_symbol("http://www.pnml.org/version-2009/grammar/symmetricnet") === :symmetric
    @test PnmlTypes.pntd_symbol("pnmlcore"  ) === :pnmlcore
    @test PnmlTypes.pntd_symbol("ptnet"     ) === :ptnet
    @test PnmlTypes.pntd_symbol("hlnet"     ) === :hlnet
    @test PnmlTypes.pntd_symbol("hlcore"    ) === :hlcore
    @test PnmlTypes.pntd_symbol("pt-hlpng"  ) === :pt_hlpng
    @test PnmlTypes.pntd_symbol("pt_hlpng"  ) === :pt_hlpng
    @test PnmlTypes.pntd_symbol("symmetric" ) === :symmetric
    @test PnmlTypes.pntd_symbol("symmetricnet") === :symmetric

    @test PnmlTypes.pntd_symbol("nonstandard" ) === :pnmlcore
    @test PnmlTypes.pntd_symbol("open"        ) === :pnmlcore
    @test PnmlTypes.pntd_symbol("continuous"  ) === :continuous
end

@testset "pnmltype" begin
    #@test_call PNML.PnmlTypes.pntd_map()
    @test_call PnmlTypes.pnmltype(PnmlCoreNet())
    @test_call PnmlTypes.pnmltype("pnmlcore")
    @test_call PnmlTypes.pnmltype(:pnmlcore)

    @test_throws MethodError PnmlTypes.pnmltype(Nothing())
    @test_throws MethodError PnmlTypes.pnmltype(Any[])
    @test_throws DomainError PnmlTypes.pnmltype(:garbage)

    @test PnmlTypes.pnmltype(PnmlCoreNet()) === PnmlCoreNet()
    @test PnmlTypes.pnmltype(ContinuousNet()) === ContinuousNet()
    @test PnmlTypes.pnmltype(PTNet()) === PTNet()
    @test PnmlTypes.pnmltype(HLCoreNet()) === HLCoreNet()
    @test PnmlTypes.pnmltype(HLPNG()) === HLPNG()
    @test PnmlTypes.pnmltype(PT_HLPNG()) === PT_HLPNG()
    @test PnmlTypes.pnmltype(SymmetricNet()) === SymmetricNet()

    @test PnmlTypes.pnmltype("foo") === PnmlCoreNet()

    @test PnmlTypes.pnmltype("http://www.pnml.org/version-2009/grammar/ptnet") === PTNet()
    @test PnmlTypes.pnmltype("http://www.pnml.org/version-2009/grammar/highlevelnet") === HLPNG()
    @test PnmlTypes.pnmltype("http://www.pnml.org/version-2009/grammar/pnmlcoremodel") === PnmlCoreNet()
    @test PnmlTypes.pnmltype("http://www.pnml.org/version-2009/grammar/pnmlcore") === PnmlCoreNet()
    @test PnmlTypes.pnmltype("http://www.pnml.org/version-2009/grammar/pt-hlpng") === PT_HLPNG()
    @test PnmlTypes.pnmltype("http://www.pnml.org/version-2009/grammar/symmetricnet") === SymmetricNet()
    @test PnmlTypes.pnmltype("pnmlcore"  ) === PnmlCoreNet()
    @test PnmlTypes.pnmltype("ptnet"     ) === PTNet()
    @test PnmlTypes.pnmltype("hlnet"     ) === HLPNG()
    @test PnmlTypes.pnmltype("hlcore"    ) === HLCoreNet()
    @test PnmlTypes.pnmltype("pt-hlpng"  ) === PT_HLPNG()
    @test PnmlTypes.pnmltype("pt_hlpng"  ) === PT_HLPNG()
    @test PnmlTypes.pnmltype("symmetric" ) === SymmetricNet()
    @test PnmlTypes.pnmltype("symmetricnet") === SymmetricNet()
    @test PnmlTypes.pnmltype("nonstandard" ) === PnmlCoreNet()
    @test PnmlTypes.pnmltype("continuous"  ) === ContinuousNet()

    @test PnmlTypes.pnmltype(:pnmlcore)   === PnmlCoreNet() # most basic
    @test PnmlTypes.pnmltype(:ptnet)      === PTNet() # collective token identity meta-model
    @test PnmlTypes.pnmltype(:hlcore)     === HLCoreNet() # individual token identity meta-model
    @test PnmlTypes.pnmltype(:pt_hlpng)   === PT_HLPNG() # really-restricted meta-model
    @test PnmlTypes.pnmltype(:symmetric)  === SymmetricNet() # restricted meta-model
    @test PnmlTypes.pnmltype(:hlnet)      === HLPNG() # full-fat meta-model
    @test PnmlTypes.pnmltype(:continuous) === ContinuousNet() # not in standard, collective identity
end

@testset "pnml traits $pntd" for pntd in PnmlTypes.all_nettypes()
    #println("pnml traits $pntd: ", [is_discrete(pntd), is_continuous(pntd), is_highlevel(pntd)])
    t = typeof(pntd)
    @test is_discrete(pntd) isa Bool
    @test is_continuous(pntd) isa Bool
    @test is_highlevel(pntd) isa Bool
    @test is_discrete(t) isa Bool
    @test is_continuous(t) isa Bool
    @test is_highlevel(t) isa Bool
    @test is_discrete(pntd) == is_discrete(t)
    @test is_continuous(pntd) == is_continuous(t)
    @test is_highlevel(pntd) == is_highlevel(t)
     #@show [is_discrete(pntd), is_continuous(pntd), is_highlevel(pntd)]
    @test only(filter(==(true), [is_discrete(pntd), is_continuous(pntd), is_highlevel(pntd)]))
    @test only(filter(==(true), [is_discrete(t), is_continuous(t), is_highlevel(t)]))
end
