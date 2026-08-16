"""
$(TYPEDEF)
$(TYPEDFIELDS)

Holds one or more `PnmlNet`s and a `namespace` string.
"""
struct PnmlModel{T <: NamedTuple}
    nets::T
    namespace::String
end

"""
$(TYPEDSIGNATURES)

Return iterator over `nets` of `model`.
"""
nets(model::PnmlModel) = values(model.nets)
namespace(model::PnmlModel) = model.namespace

"""
$(TYPEDSIGNATURES)
Return iterator of nets matching Petri net type definition given as string, symbol or AbstractPNTD subtype instance.
"""
function find_nets end
find_nets(model, str::AbstractString) = find_nets(model, PnmlTypes.pntd_symbol(str))
find_nets(model, sym::Symbol) = find_nets(model, pnmltype(sym))
function find_nets(model, @nospecialize(pntd::AbstractPNTD))
    P = typeof(pntd)
    Iterators.filter(n -> Fix2(isa, P)(pntd_of(n)),
        nets(model))
end

firstnet(model::PnmlModel) = first(nets(model))::PnmlNet

"""
$(TYPEDSIGNATURES)

Return `PnmlNet` having `id` or `nothing`.
"""
function find_net(model::PnmlModel, id::Symbol)
    haskey(model.nets, id) ? model.nets[id]::APN : nothing
end

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

function Base.summary(io::IO, m::PnmlModel)
    println("PnmlModel namespace = ", namespace(m), ", has ", length(nets(m)), " net(s)")
    for (i, net) in enumerate(nets(m))
        println(io, "$i: ", summary(net))
    end
end
