#

"""
$(TYPEDEF)
See [`FiniteEnumerationSort`](@ref), [`CyclicEnumerationSort`](@ref).
Both hold an ordered collection of `FEConstant` REFIDs.
"""
abstract type EnumerationSort <: AbstractSort end

"""
    refs(sort::EnumerationSort) -> Vector{REFID}

Return `Vector` of `FEConstant` `REFID`s.
"""
refs(sort::EnumerationSort) = sort.fec_refs # NTuple

"""
    sortelements(sort::EnumerationSort, ::APN) -> Iterator

Return iteratable ordered collection of keys into `feconstant(net)` dictionary.
"""
sortelements(sort::EnumerationSort, ::APN) = refs(sort)

#"Return number of `FEConstants` contained by this sort."
Base.length(sort::EnumerationSort) = length(refs(sort))
Base.eltype(::Type{<:EnumerationSort}) = Symbol

function Base.show(io::IO, esort::EnumerationSort)
    print(io, nameof(typeof(esort)), "([")
    io = inc_indent(io)
    for (i, finite_enum_const_refid) in enumerate(refs(esort))
        print(io, '\n', indent(io), finite_enum_const_refid);
        i < length(esort) && print(io, ",")
    end
    print(io, "])")
end

"""
$(TYPEDEF)

 Orderedcollection of REFIDs into feconstant(net).

Operations differ between `EnumerationSort`s. All wrap a tuple of symbols and
metadata, allowing attachment of Partition/PartitionElement.

See ISO/IEC 15909-2:2011/Cor.1:2013(E) defect 11 power or nth successor/predecessor

MCC2023/SharedMemory-COL-100000 has cyclic enumeration with 100000 <feconstant> elements.
"""
@auto_hash_equals struct CyclicEnumerationSort <: EnumerationSort
    # Difference of Cyclic from Finite EnumerationSort is successor/predecessor operators.
    fec_refs::Vector{REFID} # ordered collection of FEConstant REFIDs
end

#TODO successor/predecessor methods

"""
    FiniteEnumerationSort(ntuple) -> FiniteEnumerationSort{M}
Wraps a collection of `FEConstant` REFIDs. Usage: `feconstant(net)[refid]`.
"""
@auto_hash_equals struct FiniteEnumerationSort <: EnumerationSort
    fec_refs::Vector{REFID} # ordered collection of FEConstant REFIDs
    #TODO! Constructor version with start,end attributes. See ISO/IEC 15909-2:2011/Cor.1:2013(E) defect 10
end

"""
    $(TYPEDEF)
    FiniteIntRangeSort(start::T, stop::T) where {T<:Integer}
"""
@auto_hash_equals struct FiniteIntRangeSort{T<:Integer} <: AbstractSort
    start::T
    stop::T # XML Schema calls this 'end'.
end

Base.eltype(::Type{FiniteIntRangeSort{T}}) where {T<:Integer} = T
start(fir::FiniteIntRangeSort) = fir.start
stop(fir::FiniteIntRangeSort) = fir.stop

"""
    $(TYPEDEF)
Return iterator from `start` to `stop`, inclusive.
"""
sortelements(fir::FiniteIntRangeSort, ::APN) = Iterators.map(identity, start(fir):stop(fir))

function Base.show(io::IO, fir::FiniteIntRangeSort)
    print(io, "FiniteIntRangeSort(", start(fir), ", ", stop(fir), ")")
end
