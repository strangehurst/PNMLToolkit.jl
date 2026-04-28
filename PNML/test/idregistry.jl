using PNML, Test, JET, Logging

include("TestUtils.jl")
using .TestUtils

net = make_net(PnmlCoreNet(), :idregistry_net)
IDRegistrys.reset_reg!(net.idregistry)
register_id!(net.idregistry, :p1)
@test @inferred(isregistered(net.idregistry, :p1)) == true
@test !isempty(net.idregistry)
@test length(net.idregistry) > 0
@test !isempty(values(net.idregistry))

IDRegistrys.reset_reg!(net.idregistry)
@test !isregistered(net.idregistry, :p1)
register_id!(net.idregistry, :p1)
@test isregistered(net.idregistry, :p1)
@test_throws DuplicateIDException register_id!(net.idregistry, :p1)
@test isregistered(net.idregistry, :p1) # still registered

@test_opt target_modules=t_modules IDRegistry()
@test_call IDRegistry()
@test_opt target_modules=t_modules register_id!(net.idregistry, :p1)
@test_opt !isregistered(net.idregistry, :p1)
#@test_opt broken=false IDRegistrys.reset_reg!(net.idregistry, )

@test_call register_id!(net.idregistry, :p)
@test_call !isregistered(net.idregistry, :p1)
@test_call IDRegistrys.reset_reg!(net.idregistry, )

@test !isempty(sprint(show, net.idregistry))
