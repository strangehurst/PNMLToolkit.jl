"""
$(TYPEDEF)
$(TYPEDFIELDS)

One or more Petri Nets.
"""
struct PnmlModel{T <: AbstractDict}
    nets::T #Dict{Symbol, PnmlNet{<:APNTD}}
    namespace::String
end

"""
$(TYPEDSIGNATURES)

Return all `nets` of `model`.
"""
nets(model::PnmlModel) = values(model.nets)
namespace(model::PnmlModel) = model.namespace

"""
$(TYPEDSIGNATURES)
Return nets matching pntd `type` given as string, symbol or pnmltype instance.
"""
function find_nets end
find_nets(model, str::AbstractString) = find_nets(model, PnmlTypes.pntd_symbol(str))
find_nets(model, sym::Symbol)    = find_nets(model, pnmltype(sym))
find_nets(model, pntd::APNTD) = Iterators.filter(n -> Fix1(isa, pntd)(nettype(n)), nets(model))

firstnet(model::PnmlModel) = first(nets(model))::PnmlNet

"""
$(TYPEDSIGNATURES)

Return `PnmlNet` having `id` or `nothing`.
"""
function find_net(model, id::Symbol)
    haskey(model.nets, id) ? model.nets[id] : nothing
end

# No indent done here.
function Base.show(io::IO, model::PnmlModel)
    print(io, "PnmlModel(", namespace(model), ", ",)
    println(io, length(nets(model)), " nets:" )
    for (i, net) in enumerate(nets(model))
        show(io, net)
        if i < length(nets(model))
            println(io)
        end
    end
end

#Base.summary(io::IO, pns::PnmlModel) = print(io, summary(pns))
function Base.summary(io::IO, m::PnmlModel)
    println("model, namespace = ", namespace(m), ", has ", length(nets(m)), " net(s)")
    for (i, net) in enumerate(nets(m))
        println(io, "$i: ", summary(net))
    end
end
