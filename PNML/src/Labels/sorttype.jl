#=
    Place Sort Type

find . -name '*.pnml' -type f -print | xargs grep -nHPA5 '<type>' |  grep -PA1 '<structure>' | grep -vE '</?structure>' | grep -v -- '--' | grep -v '<usersort'
shows that ePNK examples uses built-in sorts.
The rest of the examples, especially MCC, only contain usersorts.

Some built-in sorts are atoms, examples: </dot>, <natural>.
These are represented by an empty xml element, but not necessarily of the form </dot>.
Lists are not atoms and are not supported by symmetric nets in the standard.
#~That kind of restriction to HLPNGs makes Symmetric Nets more tractable.
Note that <productsorts> are not atoms and are required by symmetric nets.

And note that PTNets are HLPNGs restricted even further: place type must be </dot>.

One place in standard says:
> built-in sorts of Symmetric Nets are...: Bool, range of integers, finite enumerations, cyclic enumerations and dots.
by which they mean in addition to PNML core and HL core layers (a.k.a. meta-models) definitions.
That pulls in </integer>, et al.

The implementation needs to assume that it will support full HLPNGs including:
arbitrary sorts, arbitrary operators, strings, lists.
It is acceptable for test files (but not precompilation) to produce errors/output
when unsupported(yet) feature are encountered in an input XML file.

Precompile input files need a management scheme.
  - pnmlcore, hlcore, ptnet, symmetric, hlpng, experimental?
Should allow for user tuning by setting a preference.


=#
"""
$(TYPEDEF)
$(TYPEDFIELDS)

A places's <type> label wraps a `UserSortRef` that holds a REFID to the sort of a place,
hence use of `sorttype`. It is the type (or set) concept of the many-sorted algebra.

For high-level nets there will be a declaration section with a rich language of sorts
using `UserSortRef`, `NamedSort`, `PartitionSort`, or `ArbitrarySort`
defined in the xml input.

For other PnmlNet's they are used internally to allow common implementations.

> defines the type by referring to some sort; by the fixed interpretation of built-in sorts,
this sort defines the type of the place.

> By the fixed interpretation of sorts, this implicitly refers to a set, which is the type of that place.

"refers to set" excludes multiset (as stated elsewhere in standard)

this is a sort, not a term, so no variables or operators.

> The initial marking function M0 is defined by the label Marking of the places.
> ... this is a ground term of the corresponding multiset sort.

Ground terms have no variables and can be evaluated outside of a transition firing rule.
"""
@kwdef struct SortType{N <: APN} <: Annotation # Label not limited to high-level dialects.
    text::Maybe{String} = nothing # Supposed to be for human consumption.
    sort::SortRef # NOT PartitionSort.  #! ePNK uses inline sorts.
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    net::N
end

# >The label Type of a place defines the type by referring to some sort;
# > by the fixed interpretation of built-in sorts, this sort defines the type of the place.

SortType(sort::SortRef, net) = SortType(; sort, net)
SortType(s::AbstractString, sort::SortRef, net) = SortType(; text=s, sort, net)

text(t::SortType)   = ifelse(isnothing(t.text), "", t.text) # See text(::AbstractLabel)
sortref(t::SortType) = t.sort
refid(t::SortType) = refid(sortref(t))::Symbol
sortelements(t::SortType, net::APN) = sortelements(sortdefinition(namedsort(net, sortref(t))), net)

"""
    def_sort_element(x)

Return an arbitrary element of sort `x`.
All sorts are expected to be iteratable and non-empty, so we return `first`.
Uses include default inscription value and default initial marking value sorts.

`x` can be anything with a `sortelements(x, net)` method that returns an iterator with length.
See [`AbstractSort`](@ref), [`SortType`](@ref PNML.Labels.SortType).
"""
function def_sort_element(placetype::SortType)
    first(sortelements(placetype, placetype.net))
end

function Base.show(io::IO, st::SortType)
    print(io, indent(io), "SortType(")
    show(io, text(st)); print(io, ", ")
    show(io, sortref(st))
    if has_graphics(st)
        print(io, ", ")
        show(io, graphics(st))
    end
    if has_tools(st)
        print(io, ", ")
        show(io, toolinfos(st));
    end
    print(io, ")")
end

"""
$(TYPEDSIGNATURES)

Return `SortRef` for default `SortType` of a `PNTD`.
"""
function default_typesort end

default_typesort(::APNTD) = NamedSortRef(:natural)
default_typesort(::AbstractContinuousNet) = NamedSortRef(:real)
# High-level nets are expected to provide a useful value. PT_HLPNG uses the minimum: 'dot'.
# We provide an implementation of 'dot', so this is a safe assumption.
default_typesort(::PT_HLPNG) = NamedSortRef(:dot)
function default_typesort(pntd::AbstractHLCore)
    error("default_typesort($pntd) is not defined, you should provide a place type in the XML")
end
