
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Arbitrary sorts that can be used for constructing terms are reserved
for/supported by `HLPNG` in the pnml standard.

> ...arbitrary sorts and operators do not come with a definition of the sort or operation;
they just introduce a new symbol.

Like `ArbitraryOperator`, does not have an associated algebra, not usable by `SymmetricNet.`
"""
struct ArbitrarySort{N <: APN} <: SortDeclaration
    id::Symbol
    name::Union{String,SubString{String}}
    net::N
end

pid(a::ArbitrarySort) = a.id
name(a::ArbitrarySort) = a.name

function Base.show(io::IO, s::ArbitrarySort)
    print(io, nameof(typeof(s)), "(", repr(pid(s)), ", ", repr(name(s)), ")")
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

> ...arbitrary sorts and operators do not come with a definition of the sort or operation;
they just introduce a new symbol.

Like `ArbitrarySort`, does not have an associated algebra, not usable by `SymmetricNet.`
"""
struct ArbitraryOperator{N <: APN} <: OperatorDeclaration
    id::Symbol
    name::Union{String,SubString{String}}
    declaration::Symbol #! Are id and declaration redundent?
    net::N
end

function Base.show(io::IO, op::ArbitraryOperator)
    print(io, nameof(typeof(op)), "(", repr(pid(op)), ", ",
            repr(name(op)), ", ", repr(op.declaration), ")")
end
