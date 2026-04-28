"""
    NumberConstant{T<:Number, S}

Builtin operator that has arity=0 means the same result every time, a constant.
Restricted to NumberSorts, those `Sort`s whose `eltype` isa `Number`.
"""
struct NumberConstant{T<:Number} <: AbstractOperator
    value::T
    sort::SortRef # value isa eltype(to_sort(sort, net), verified by parser.
    # Constant operators are 0-arity by definition. Parameter vector not used here.
end

sortref(nc::NumberConstant) = identity(nc.sort)::SortRef
basis(nc::NumberConstant)   = sortref(nc.value)::SortRef

# others want the value of the value
(c::NumberConstant)() = value(c)
value(nc::NumberConstant) = nc.value


"""
    FEConstant

Finite enumeration constant and its containing sort.

> "...these FEConstants are part of the declaration of the FiniteEnumeration sort.
> On the other hand, each of these FEConstants defines a 0-ary operation,
> i. e. is a declaration of a constant."

# Usage
    fec = FEConstant(:anID, "somevalue", sortref)
    fec() == :anID
    fec.name = "somevalue"
"""
struct FEConstant <: AbstractOperator
    id::Symbol # ID is unique within net.
    name::Union{String, SubString{String}} # Must name be unique within a sort?
    ref::SortRef # of contining partition, enumeration, (or partitionelement?) sort.
end

refid(fec::FEConstant)    = refid(fec.ref)::Symbol
sortref(fec::FEConstant)  = fec.ref
Base.eltype(::FEConstant) = Symbol # Use id symbol as the value. Alternative is name.

(fec::FEConstant)(_args) = fec() # Constants are 0-ary operators. Ignore arguments.
(fec::FEConstant)() = fec.id # A constant literal. We use symbol, could use name string.

function x_sortof(fec::FEConstant, net::APN)
    @match fec.ref begin
        NamedSortRef(refid) => sortdefinition(namedsort(net, refid))::EnumerationSort
        PartitionSortRef(refid) => sortdefinition(partitionsort(net, refid))::PartitionSort
        # Partitions are over a single EnumerationSort
        # partition element?
        _ => error("unsupported SortRef: ", fec)
    end
end

function Base.show(io::IO, fec::FEConstant)
    print(io, nameof(typeof(fec)), "($(repr(fec.id)), $(repr(fec.name)))")
end

"""
    $(TYPEDEF)
Must refer to a value between the start and end of the respective `FiniteIntRangeSort`.
"""
struct FiniteIntRangeConstant{T<:Integer} <: AbstractOperator
    value::T
    sort::SortRef
    #TODO! Assert that T is a sort eltype.
end
tag(::FiniteIntRangeConstant) = :finiteintrangeconstant

# FIRconstants have an embedded sort definition, NOT a namedsort or usersort.
# We create a namedsort duo to match. Is expected to be an IntegerSort.
sortref(c::FiniteIntRangeConstant) = identity(c.sort)::SortRef

#"Special case to ` IntegerSort()`, it is part of the name, innit."
x_sortof(::FiniteIntRangeConstant, ::APN) = IntegerSort()
# or sortdefinition(namedsort(ddict, :integer))::IntegerSort

value(c::FiniteIntRangeConstant) = c.value
(c::FiniteIntRangeConstant)() = value(c)

"""
The only element of `DotSort` is `DotConstant`.
This is a 0-arity opertor term that evaluates to `1`.
"""
struct DotConstant <: AbstractOperator
end

sortref(::DotConstant) = UserSortRef(:dot)
(_dot::DotConstant)() = 1 # true is a number, one

function Base.show(io::IO, c::DotConstant)
    print(io, nameof(typeof(c)), "()")
end

"""
    BooleanConstant("true"|"false")
    BooleanConstant(true|false)

A built-in operator constructor (constants are 0-ary operators).

Examples
```
    c = BooleanConstant("true");
    c == BooleanConstant(true)
    c() == true
```
"""
struct BooleanConstant <: AbstractOperator
    value::Bool
end

"Create by parsing string `s` to value of type `Bool`."
function BooleanConstant(s::Union{AbstractString,SubString{String}})
    BooleanConstant(parse(Bool, s))
end

tag(::BooleanConstant) = :booleanconstant
sortref(::BooleanConstant) = UserSortRef(:bool)

(c::BooleanConstant)() = value(c)
value(bc::BooleanConstant) = bc.value

function Base.show(io::IO, c::BooleanConstant)
    print(io, nameof(typeof(c)), "(", value(c), ")")
end
