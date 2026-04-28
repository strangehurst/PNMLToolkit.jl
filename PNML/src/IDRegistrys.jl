"""
Petri Net Markup Language identifier registry.
"""
module IDRegistrys

using Preferences
using Base: Base.IdSet
using DocStringExtensions
import SciMLPublic: @public
import Base: eltype

export IDRegistry, register_id!, isregistered, DuplicateIDException
@public reset_reg!


"""
$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct DuplicateIDException <: Exception
    msg::String
end

"""
Holds a set of PNML ID symbols and, optionally, a lock to allow safe reentrancy.

$(TYPEDEF)
"""
@kwdef struct IDRegistry
    idset::IdSet{Symbol} = IdSet{Symbol}()
    lk::ReentrantLock = ReentrantLock()
end

function Base.show(io::IO, reg::IDRegistry)
    print(io, nameof(typeof(reg)), "(", collect(values(reg)), ")")
end

duplicate_id_action(id::Symbol)  = throw(DuplicateIDException("ID already registered: $id"))

"""
$(TYPEDSIGNATURES)

Register `id` symbol and return the symbol.
"""
function register_id!(registry::IDRegistry, id::Symbol)
    @lock registry.lk _reg!(registry, id)
    return id
end

_reg!(registry, id) = begin
    id ∈ registry.idset ? duplicate_id_action(id) : push!(registry.idset, id)
    return nothing
end

"""
$(TYPEDSIGNATURES)

Return `true` if `id` is registered in `registry`.
"""
function isregistered(registry::IDRegistry, id::Symbol)
    @lock registry.lk id ∈ registry.idset
end

"""
$(TYPEDSIGNATURES)

Empty the set of id symbols. Use case is tests.
"""
function reset_reg!(registry::IDRegistry)
    @lock registry.lk empty!(registry.idset)
    return registry
end

function Base.isempty(registry::IDRegistry)
    @lock registry.lk isempty(registry.idset)::Bool
end

function Base.length(registry::IDRegistry)
    @lock registry.lk length(registry.idset)
end

function Base.values(registry::IDRegistry)
    @lock registry.lk values(registry.idset)
end

end # module IDRegistrys
