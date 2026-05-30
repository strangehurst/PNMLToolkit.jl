# Declare & Document interface functions of PNML.jl
# Any method defined in this file should operate on `Any`.

"""
    pid(x) -> Symbol

Return pnml id symbol of `x`. An id's value is unique in the XML model of PNML.
[`REFID`](@ref) is used for refrences to pnml ids.

$(METHODLIST)
"""
function pid end

"""
    tag(x) -> Symbol

Return tag symbol. Multiple objects may hold the same tag value.
Often used to refer to an XML tag.

$(METHODLIST)
"""
function tag end


"""
    refid(x) -> REFID

Return reference id symbol. Multiple objects may hold the same refid value.

$(METHODLIST)
"""
function refid end

"""
    name(x) -> String

Return name String. Default to empty string.

$(METHODLIST)
"""
function name end


function toolinfos end

#--------------------------------------------
#--------------------------------------------
"""
$(TYPEDSIGNATURES)

Return the [`APNTD`](@ref) subtype representing the flavor (or pntd) of this kind of
Petri Net Graph.

See also [`pnmltype`](@ref PnmlTypes.pnmltype)

$(METHODLIST)
"""
function nettype end

"""
    pages(net::PnmlLabel|page::Page) -> iterator

Return iterator of pages directly owned by that object.

See [`allpages`](@ref) for an iterator over all pages in the PNML network model.
When there is only one `page` in the `net`, or all pages are owned by the 'net' itself,
'allpages' and 'pages` behave the same.

Maintains order (insertion order).

$(METHODLIST)
"""
function pages end

"""
    netdata(x) -> PnmlNetData

Access PnmlNet-level data structure.

$(METHODLIST)
"""
function netdata end


#--------------------------------------------
# PLACES & MARKINGS
#--------------------------------------------
"""
$(TYPEDSIGNATURES)

Return iterator of all places.

$(METHODLIST)
"""
function places end

"""
$(TYPEDSIGNATURES)

Return iterator of all place IDs.

$(METHODLIST)
"""
function place_idset end

"""
$(TYPEDSIGNATURES)

Return `true` if there is any place with `id`?

$(METHODLIST)
"""
function has_place end

"""
$(TYPEDSIGNATURES)

Return the place with `id`.

$(METHODLIST)
"""
function place end

"""
$(TYPEDSIGNATURES)

Return the initial marking of a place.

$(METHODLIST)
"""
function initial_marking end

#--------------------------------------------
# TRANSITIONS & CONDITIONS
#--------------------------------------------
"""
$(TYPEDSIGNATURES)
Return iterator of all transitions.

$(METHODLIST)
"""
function transitions end

"""
$(TYPEDSIGNATURES)

Is there a transition with `id`?

$(METHODLIST)
"""
function has_transition end

"""
$(TYPEDSIGNATURES)

$(METHODLIST)
"""
function transition end

"""
$(TYPEDSIGNATURES)

$(METHODLIST)
"""
function transition_idset end

"""
    inscriptions(net::PnmlNet) -> Iterator

Return iterator over REFID => inscription(arc) pairs of `net`. This is the same order as `arcs`.

$(METHODLIST)
"""
function inscriptions end

"""
    conditions(net::PnmlNet) -> Iterator

Return iterator  over REFID => condition(transaction) pairs of `net`.
This is the same order as `transactions`.

$(METHODLIST)
"""
function conditions end

"""
    rates(net::PnmlNet) -> Iterator

Return iterator over REFID => rate_value(transaction) pairs of `net`.
This is the same order as `transactions`.

We allow all PNML nets to be stochastic Petri nets. See [`rate_value`](@ref).

$(METHODLIST)
"""
function rates end

"""
$(TYPEDSIGNATURES)

Return condition's value of `transition`.

$(METHODLIST)
"""
function condition end

#--------------------------------------------
# ARCS & INSCRIPTIONS
#--------------------------------------------
"""
    arcs(n::PnmlNet) -> iterator
    arcs(p::AbstractPetriNet) -> iterator

Return iterator over arc ids.

$(METHODLIST)
"""
function arcs end
"""
$(TYPEDSIGNATURES)+

Return `true` if any `arc` has `id`.

$(METHODLIST)
"""
function has_arc end

"""
$(TYPEDSIGNATURES)
Return arc with `id` if found, otherwise `nothing`.

$(METHODLIST)
"""
function arc end

"""
$(TYPEDSIGNATURES)

Return iterator over arc ids.

$(METHODLIST)
"""
function arc_idset end

"""
$(TYPEDSIGNATURES)
Return arcs that have a source or target of transition `id`.

See also [`src_arcs`](@ref), [`tgt_arcs`](@ref).

$(METHODLIST)
"""
function all_arcs end

"""
    source(arc) -> Symbol

Return identity symbol of source of `arc`.

$(METHODLIST)
"""
function source end

"""
    target(arc) -> Symbol

Return identity symbol of target of `arc`.

$(METHODLIST)
"""
function target end

"""
$(TYPEDSIGNATURES)

Return arcs that have a source of transition `id`.

See also [`all_arcs`](@ref), [`tgt_arcs`](@ref).

$(METHODLIST)
"""
function src_arcs end

"""
$(TYPEDSIGNATURES)

Return arcs that have a target of transition `id`.

See also [`all_arcs`](@ref), [`src_arcs`](@ref).

$(METHODLIST)
"""
function tgt_arcs end

function arctype end

function is_normal end
function is_inhibitor end
function is_read end
function is_reset end


"""
$(TYPEDSIGNATURES)
Return incription value of `arc`.

$(METHODLIST)
"""
function inscription end

#--------------------------------------------
# REFERENCES
#--------------------------------------------
"""
$(TYPEDSIGNATURES)
Return vector of all reference places.

$(METHODLIST)
"""
function refplaces end

"""
$(TYPEDSIGNATURES)
Return vector of all reference transitions.

$(METHODLIST)
"""
function reftransitions end

"""
$(TYPEDSIGNATURES)

$(METHODLIST)
"""
function has_refplace end

"""
$(TYPEDSIGNATURES)

$(METHODLIST)
"""
function has_reftransition end

"""
    refplace_idset(x) -> OrderedSet{Symbol}

Return reference place pnml ids.

$(METHODLIST)
"""
function refplace_idset end

"""
    reftransition_idset(x) -> OrderedSet{Symbol}

Return reference transition pnml ids.

$(METHODLIST)
"""
function reftransition_idset end

"""
$(TYPEDSIGNATURES)
Return reference place matching `id`.

$(METHODLIST)
"""
function refplace end

"""
$(TYPEDSIGNATURES)
Return reference transition matching `id`.

$(METHODLIST)
"""
function reftransition end

"""
    value(x)
Return value of x. Can be a wrapped value or a derived value.
May return an Expr that returns the value when eval'ed.

$(METHODLIST)
"""
function value end

"""
    term(x)
Return 'PnmlExpr` term of x.

$(METHODLIST)
"""
function term end

"""
    coordinate_type(x) -> Type(Coordinate)

$(METHODLIST)
"""
function coordinate_type end

"""
    value_type(::Type{<AbstractLabel}, ::APNTD) -> Type

Return the `Type` of a label's value.

$(METHODLIST)
"""
function value_type end

"""
    sortref(x) -> SortRef

Return a REFID wrapped in a [`SortRef`](@ref) ADT.

Things that have a sortref include:
Place, Arc, Inscription, Marking,
MultisetSort,  SortType,
NumberConstant, Int64, Integer, Float64,
FEConstant, FiniteIntRangeConstant, DotConstant, BooleanConstant,
PnmlMultiset, Operator, Variable,

$(METHODLIST)
"""
function sortref end

"""
    sortdefinition(::NamedSort) -> Sort

Return concrete sort attached to a sort declaration object.

Dictionaries in a network-level [`DeclDict`](@ref) hold, among other things,
`NamedSort`, `ArbitrarySort` and `PartitionSort` declarations.
These declarations add an ID and name to a concrete sort,
with the ID symbol used as the dictionary key.

$(METHODLIST)
"""
function sortdefinition end

"""
    basis(x) -> SortRef

Return SortRef referencing a NamedSort, ArbitrarySort or PartitionSort declaration.
`MultisetSort`, `Multiset`, `List` have a `basis` sort.
Place marking & sorttype, arc inscriptions have a `basis` sort.

$(METHODLIST)
"""
function basis end


"""
    sortelements(x, net) -> Iterator

Return iterator over elements of the sort of `x` in `net`.

$(METHODLIST)
"""
function sortelements end

"""
    elements(x) -> LittleDict

Return the dictionary produced by `xmldict` in a `AnyElement`, `PnmlLabel` or `Toolinfo`.
"""
function elements end

"""
    adjacent_place(net::PnmlNet, arc::Arc) -> Place
    adjacent_place(netdata::PnmlNetData, source,::Symbol target::Symbol) -> Place

Adjacent place of an arc is either the `source` or `target`.
"""
function adjacent_place end
# Note that this behavior is suitable to many Petri nets.
# But the PNML core does not have this limit; it is imposed by meta-models.
#todo Remove limitation of requiring arcs to be between place and transition.

"""
    decldict(net::AbstractPnmlNet) -> DeclDict

Access net-level `DeclDict`.

$(METHODLIST)
"""
function decldict end

"""
"Version of tool for this tool specific information element and its parser."

$(METHODLIST)
"""
function version end

# Create and return a ntransitions x nplaces matrix.
# """
function output_matrix end

"""
    verify!(errors::Vector{String}, x, verbose::Bool, net::AbstractPnmlNet)

$(METHODLIST)
"""
function verify! end



"Return dictionary of `id` => `UserOperator`"
function useroperators end
"Return dictionary of `id` => `VariableDecl`"
function variabledecls end
"Return dictionary of ``id` => NamedSort`"
function namedsorts end
"Return dictionary of `id` => `ArbitrarySort`"
function arbitrarysorts end
"Return dictionary of `id` => `PartitionSort`"
function partitionsorts end
"Return dictionary of ``id` => NamedOperator`"
function namedoperators end
"Return dictionary of ``id` => ArbitraryOperator`"
function arbitraryops end
"Return dictionary of `id` => partitionops (`PartitionElement`)"
function partitionops end
"Return dictionary of `id` => `FEConstant`"
function feconstants end
"Return dictionary of `id` => `MultisetSort`"
function multisetsorts end
"Return dictionary of `id` => `ProductSort`"
function productsorts end


"Lookup variable with `id`."
function variabledecl end
"Lookup namedsort with `id`."
function namedsort end
"Lookup arbitrarysort with `id`."
function arbitrarysort end
"Lookup partitionsort with `id`."
function partitionsort end
"Lookup multisetsort with `id`."
function multisetsort end
"Lookup productsort with `id`."
function productsort end
"Lookup namedop with `id`."
function namedop end
"Lookup arbitraryop with `id`."
function arbitraryop end
"Lookup partitionop with `id`."
function partitionop end
"Lookup feconstant with `id`."
function feconstant end
"Lookup useroperator with `id`."
function useroperator end


"Does any operator dictionary contain `id`?"
function has_operator end

"""
    has_key(net::AbstractPnmlnet, dict, key::Symbol) -> Bool
Where `dict` is the access method for a dictionary in `DeclDict`.
"""
function has_key end

function has_variabledecl end
function has_namedsort end
function has_arbitrarysort end
function has_partitionsort end
function has_multisetsort end
function has_productsort end
function has_namedop end
function has_arbitraryop end
function has_partitionop end
function has_feconstant end
function has_useroperator end

"""
    pntd_of(net) -> AbstractPNTD
"""
function pntd_of end
