#= Example from sampleSNPrio.pnml
<declaration>
<text>Fs
    Without the following structure this Symmetric net
    example will not be a structurally conformant High-level Petri Net.
</text>
<structure>
    <declarations>
        <!-- Sorts declaration -->
        <namedsort id="usersnamed" name="USERS">
            <finiteenumeration>
                <feconstant id="apacheId" name="apache" />
                <feconstant id="iisId" name="iis" />
                <feconstant id="chrisId" name="chris" />
                <feconstant id="deniseId" name="denise" />
                <feconstant id="rootId" name="root" />
            </finiteenumeration>
        </namedsort>

        <partition id="accessrightId" name="AccessRight">
            <usersort declaration="usersnamed" />
            <partitionelement id="wwwId" name="www">
                <useroperator declaration="apacheId" />
                <useroperator declaration="iisId" />
            </partitionelement>
            <partitionelement id="workId" name="work">
                <useroperator declaration="chrisId" />
                <useroperator declaration="deniseId" />
            </partitionelement>
            <partitionelement id="adminId" name="admin">
                <useroperator declaration="rootId" />
            </partitionelement>
        </partition>

    </declarations>
</structure>
=#

"""
    PartitionElement(id::Symbol, name, Vector{IDREF}, REFID)

$(TYPEDFIELDS)

Establishes an equivalence class over a [`Declarations.PartitionSort`](@ref)'s emumeration.
See also [`FiniteEnumerationSort`](@ref).
Gives a name to an element of a partition. The element is an equivalence class.

PartitionElement is different from FiniteEnumeration, CyclicEnumeration, FiniteIntRangeSort
in that it holds UserOperators, not FEConstants.
The UserOperator refers to the FEConstants of the sort over which the partition is defined.
NB: FEConstants are 0-arity operators.
UserOperator is how operation declarations are accessed.

NB: The "PartitionElementOf" operator maps each element of the FiniteEnumeration
(referenced by the partition) to the PartitionElement (of the partition) to which it belongs.

PartitionElementOf(partition, feconstant) -> PartitionElement
partitionelementof(partition, feconstant) -> PartitionElement

PartitionElementOf is passed a REFID of the partition whose
PartitionElement membership is being queried.

Each PartitionElement contains a collection of REFIDs to UserOperators which refer to
a finite sort's (FiniteEnumeration, CyclicEnumeration, FiniteIntRangeSort) FEConstant by REFID.

Test for membership by iterating over each partition element, and over each term.
"""
struct PartitionElement <: OperatorDeclaration
    id::Symbol
    name::Union{String,SubString{String}}
    terms::Vector{REFID} # 1 or more ref to feconstant in partitions's referenced sort.
    partition::REFID
end

# verify terms are in parent partitions's referenced sort elements.
function verify!(errors::Vector{String}, pe::PartitionElement,
                 verbose::Bool, net::APN)
    sdiff = setdiff(pe.terms,
                    sortelements(sortdefinition(partitionsort(net, pe.partition)), net))
    verbose && println("## verify $(typeof(pe))")
    if !isempty(sdiff)
        msg = string("PartitionElement term(s) not in partition def sort")
        verbose && println("verify error: $msg, sdiff = ", sdiff)
        push!(errors, msg)
    end
end

"Return Bool true if partition contains the FEConstant"
function contains end
contains(pe::PartitionElement, fec::Symbol) = fec in pe.terms

function Base.show(io::IO, pe::PartitionElement)
    print(io, nameof(typeof(pe)), "(", pid(pe), ", ", repr(name(pe)), ", ")
    show(io,  pe.terms)
    print(io, ", ",  repr(pe.partition), ")")
 end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Partition sort declaration is a finite enumeration that is partitioned into sub-ranges of enumerations.
Is the sort at the partition or the element level (1 sort or many sorts?)

Like [`NamedSort`](@ref), will add an `id` and `name` to a sort,
may be accessed by `UserSortRef` indirection.
"""
struct PartitionSort{N <: APN} <: SortDeclaration
    id::Symbol
    name::Union{String, SubString{String}}
    def::SortRef # Like a NamedSort, refers to a sort (EnumerationSort)
    elements::Vector{PartitionElement} # 1 or more PartitionElements that index into `def` #TODO a set?
    net::N

    # function PartitionSort(i, n, d, e, dd)
    #     # has_namedsort(d) || throw(ArgumentError("REFID $(repr(d)) is not a NamedSort"))
    #     # # Look at what is wrapped.
    #     # @assert tag(sortdefinition(namedsort(d))) in (:finiteenumeration, :cyclicenumeration, :finiteintenumeration)
    #     new(i, n, d, e, dd)
    # end
end

#TODO also do AbstractSort, another SortDeclaration
sortdefinition(p::PartitionSort) = sortdefinition(namedsort(p.net, p.def))
sortelements(p::PartitionSort, ::APN) = p.elements

# TODO Add Partition/PartitionElement methods here
# list PartitionElement ids & names
# list PartitionElement terms
# access by partition id, element id

"Iterator over partition element REFIDs of a `PartitionSort"
function element_ids(ps::PartitionSort)
    Iterators.map(pid, sortelements(ps, ps.net))
end

"Iterator over partition element names"
function element_names(ps::PartitionSort)
    Iterators.map(name, sortelements(ps, ps.net))
end

function verify!(errors::Vector{String}, psort::PartitionSort, verbose::Bool, net::APN)
    #psort = partitionsort(net, pe.partition)
    for pe in psort.elements
        verify!(errors, pe, verbose, net)
    end
    # if !isempty(setdiff(pe.terms,
    #                     sortelements(sortdefinition(psort))))
    #           #? pid needed?
    #     push!(errors, string("PartitionElement $(pid(pe)) term(s) not in partition def sort")::String)
    # end
    verify_partition(psort) ||
        push!(errors, string("PartitionSort $(pid(psort)) elemenet terms mismatch")::String)

end

function verify_partition(part::PartitionSort)
    defelements = sortelements(sortdefinition(part), part.net)
    partels = collect(Iterators.flatmap(e->e.terms, sortelements(part, part.net)))
    defelements == partels
end

function Base.show(io::IO, ps::PartitionSort)
    println(io, nameof(typeof(ps)), "(", pid(ps), ", ", repr(name(ps)), ", ", repr(ps.def), ",")
    io = inc_indent(io)
    print(io, indent(io), "[")
    e = sortelements(ps, ps.net)
    for  (i, c) in enumerate(e)
        show(io, c)
        i < length(e) && print(io, ",\n", indent(io), " ")
    end
    print(io, "])")
end
