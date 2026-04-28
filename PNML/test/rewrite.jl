using PNML, JET
import Metatheory

include("TestUtils.jl")
using .TestUtils

println("REWRITE")
# net = make_net(pntd, :fake)
@show d = DotConstant()
@show Metatheory.rewrite(d, PNML.dot)

@show btrue = BooleanConstant(true)
@show bfalse = BooleanConstant(false)

@show Metatheory.rewrite(btrue, PNML.bool_alg)
@show Metatheory.rewrite(bfalse, PNML.bool_alg)
