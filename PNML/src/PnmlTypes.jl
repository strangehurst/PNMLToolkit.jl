"""
Petri Net Type Definition (pntd) URI mapped to AbstractPNTD subtype singleton.
"""
module PnmlTypes

using DocStringExtensions
using SciMLLogging: @SciMLMessage

# Abstract Types
export APNTD, AbstractContinuousNet, AbstractHLCore, AbstractPnmlCore, AbstractPNTD
# Concrete Types
export ContinuousNet, HLCoreNet, HLPNG, PTNet, PT_HLPNG, PnmlCoreNet, SymmetricNet
# Functions
export is_collective_token, is_continuous, is_discrete, is_highlevel, is_individual_token,
    pnmltype

"""
$(TYPEDEF)
Abstract root of a dispatch type based on Petri Net Type Definitions (pntd).

Each Petri Net Markup Language (PNML) `<net>` element will have a single URI
as a required 'type' XML attribute. That URI should refer to a RelaxNG schema defining
the syntax and semantics of the XML model.
See ISO 15909-2, http://www.pnml.org/ for details.

Selected abbreviations and URIs that do not resolve to a valid schema file
are suported by this tool. See [`pntd_map`](@ref).

Refer to [`pntd_symbol`](@ref) and [`pnmltype`](@ref) for
how to get from the URI to a singleton.
"""
abstract type AbstractPNTD end
"Abbreviation for AbstractPNTD"
const APNTD = AbstractPNTD

"""
$(TYPEDEF)
Base of token/integer-based Petri Net pntds.

See [`PnmlCoreNet`](@ref), [`PTNet`](@ref) and others.
"""
abstract type AbstractPnmlCore <: AbstractPNTD end

"""
$(TYPEDEF)
The most minimal concrete Petri Net.

Used to implement and test the core PNML support.
Covers the complete graph infrastructure including labels attached to nodes and arcs.
"""
struct PnmlCoreNet <: AbstractPnmlCore end

"""
$(TYPEDEF)
Place-Transition Petri Nets add small extensions to core PNML.
Integer-valued initialMarking and inscription.

The grammer file is ptnet.pnml so we name it PTNet.
Note that 'PT' is often the prefix for XML tags specialized for this net type.
"""
struct PTNet <: AbstractPnmlCore end

"""
$(TYPEDEF)
Base of High Level Petri Net pntds which add large extensions to PNML core.
hlinitialMarking, hlinscription, and defined label structures.

See [`PnmlTypes.HLCoreNet`](@ref), [`PnmlTypes.SymmetricNet`](@ref),
[`PnmlTypes.PT_HLPNG`](@ref) and others.
"""
abstract type AbstractHLCore <: AbstractPNTD end

"""
$(TYPEDEF)
`HLCoreNet` can be used for generic high-level nets.
We try to implement and test all function at `PnmlCoreNet level, but
expect to find use for a concrete type at this level for testing high-level extensions.
"""
struct HLCoreNet <: AbstractHLCore end

"""

$(TYPEDEF)
High-Level Petri Net Graphs (HLPNGs) are the most intricate High-Level Petri Net schema.
It extends [`SymmetricNet`](@ref), including with
   - declarations for sorts and functions (ArbitraryDeclarations)
   - sorts for Integer, String, and List
"""
struct HLPNG <: AbstractHLCore end

"""
$(TYPEDEF)
Place-Transition Net in HLCoreNet notation.
"""
struct PT_HLPNG <: AbstractHLCore end

"""
$(TYPEDEF)
Symmetric Petri Net is the best-worked use case in the `primer`
and ISO 15909 standard part 2.
"""
struct SymmetricNet <: AbstractHLCore end

"""
$(TYPEDEF)
Uses floating point numbers for markings, inscriptions.
Most of the functionality is shared with [`AbstractPnmlCore`](@ref).
This seperates the
"""
abstract type AbstractContinuousNet <: AbstractPNTD end

"""
$(TYPEDEF)
TODO: Continuous Petri Net
"""
struct ContinuousNet <: AbstractContinuousNet end

#----------------------------------------------------------------------------------------

"""
$(TYPEDEF)

Map from Petri Net Type Definition (pntd) URI to Symbol.
Allows multiple strings to map to the same pntd.

There is a companion map [`pnmltype_map`](@ref) that takes the symbol to a type object.

The URI is a string and may be the full URL of a pntd schema,
just the schema file name, or a placeholder for a future schema.

For readability, the 'pntd symbol' should match the name used in the URI
with inconvinient characters removed or replaced. For example, '-' is replaced by '_'.
"""
const pntd_map = Dict{String, Symbol}(
            "http://www.pnml.org/version-2009/grammar/pnmlcore" => :pnmlcore,
            "http://www.pnml.org/version-2009/grammar/pnmlcoremodel" => :pnmlcore,
            "http://www.pnml.org/version-2009/grammar/ptnet" => :ptnet,
            "http://www.pnml.org/version-2009/grammar/highlevelnet" => :hlnet,
            "http://www.pnml.org/version-2009/grammar/pt-hlpng" => :pt_hlpng,
            "http://www.pnml.org/version-2009/grammar/symmetricnet" => :symmetric,

            "pnmlcore" => :pnmlcore,
            "ptnet" => :ptnet,
            "highlevelnet" => :hlnet,
            "hlnet" => :hlnet,
            "hlcore" => :hlcore,
            "pt-hlpng" => :pt_hlpng,
            "pt_hlpng" => :pt_hlpng,
            "symmetric" => :symmetric,
            "symmetricnet" => :symmetric,

            "https://www.pnml.org/version-2009/extensions/resetptnet" => :ptnet,
            "https://www.pnml.org/version-2009/extensions/inhibitorptnet" => :ptnet,
            "https://www.pnml.org/version-2009/extensions/resetinhibitorptnet" => :ptnet,

            "resetptnet" => :ptnet, #^ `ArcType` arc label
            "inhibitorptnet" => :ptnet,
            "resetinhibitorptnet" => :ptnet,

            "continuous" => :continuous,
            #"stochastic" => :stochastic, #^ `rate` transition label
            #"capacity" => :capacity #^ `capacity` place label
            #"priority" => :priority #^ `priority` transition label
            #"timed" => :timednet, #^ `delay` transition label
            #"timednet" => :timednet,
            #"tpn" => :timednet,
            "nonstandard" => :pnmlcore,
            "open" => :pnmlcore,
            )

"""
$(TYPEDEF)

The key Symbols are the supported kinds of PNML Nets (PNTDs).
Values are concrete singletons.
"""
const pnmltype_map = IdDict{Symbol, AbstractPNTD}(:pnmlcore => PnmlCoreNet(),
                                            :hlcore => HLCoreNet(),
                                            :ptnet => PTNet(),
                                            :hlnet => HLPNG(),
                                            :pt_hlpng => PT_HLPNG(),
                                            :symmetric => SymmetricNet(),
                                            :continuous => ContinuousNet()
                                            )

"""
    all_nettypes([predicate])

Return iterator over [`AbstractPNTD`](@ref) singletons.
Filtered by a predicate `p` if one is provided.
"""
all_nettypes() = values(pnmltype_map)
all_nettypes(p) = Iterators.filter(p, values(pnmltype_map))

"""
    core_nettypes() -> Tuple{AbstractPNTD}

Useful for testing the 3 kinds of tokens corresponding to
abstract subclasses of `AbstractPNTD` (or `AbstractPNTD`) .
"""
core_nettypes() = (PnmlCoreNet(), HLCoreNet(), ContinuousNet())

"""
$(TYPEDSIGNATURES)

Add or replace mapping from Symbol `s` to [`AbstractPNTD`](@ref) singleton `pntd`.
"""
function add_nettype!(dict::AbstractDict, s::Symbol, pntd::AbstractPNTD)
    action = s ∈ keys(dict) ? "updating" : "adding"
    @info  "$action mapping from $s to $pntd in $(typeof(dict))"
    dict[s] = pntd
    return dict
end

"""
$(TYPEDSIGNATURES)

Map string `s` to a pntd symbol using [`pntd_map`](@ref).
Any unknown `s` is mapped to `:pnmlcore`.
Returned symbol is a key of [`pnmltype_map`](@ref).

# Examples

```jldoctest; setup=:(using PNML)
julia> PNML.PnmlTypes.pntd_symbol("foo")
:pnmlcore
```
"""
pntd_symbol(s::AbstractString) = get(pntd_map, s, :pnmlcore)::Symbol

"""
    pnmltype(pntd::AbstractPNTD) -> pntd
    pnmltype(uri::AbstractString) -> AbstractPNTD
    pnmltype(s::Symbol; pnmltype_map) -> AbstractPNTD

Map either a text string or a symbol to a dispatch type object.

While that string may be a URI for a pntd, we treat it as a simple string without parsing.
The [`PnmlTypes.pnmltype_map`](@ref) and [`PnmlTypes.pntd_map`](@ref)
are both assumed to be correct here.

Unknown or empty `uri` will map to symbol `:pnmlcore`.
Unknown `symbol` throws a `DomainError` exception.

# Examples

```
jldoctest; setup=:(using PNML; using PNML: pnmltype, pntd_symbol)
julia> pnmltype("nonstandard")
PnmlCoreNet()

julia> pnmltype(:symmetric)
SymmetricNet()
```
"""
function pnmltype end
pnmltype(pntd::AbstractPNTD) = pntd
pnmltype(uri::AbstractString) = pnmltype(pntd_symbol(uri))
pnmltype(s::Symbol) = if haskey(pnmltype_map, s)
    pnmltype_map[s]
else
    throw(DomainError("Unknown PNTD symbol $s"))
end

"Tokens represented by integers."
function is_discrete end
is_discrete(::AbstractPNTD) = false
is_discrete(::AbstractPnmlCore) = true
is_discrete(::Type{<:AbstractPNTD}) = false
is_discrete(::Type{<:AbstractPnmlCore}) = true

"Tokens represented by floating point."
function is_continuous end
is_continuous(::AbstractPNTD) = false
is_continuous(::AbstractContinuousNet) = true
is_continuous(::Type{<:AbstractPNTD}) = false
is_continuous(::Type{<:AbstractContinuousNet}) = true

"Tokens represented by multiset (aka bag)."
function is_highlevel end
is_highlevel(::AbstractPNTD) = false
is_highlevel(::AbstractHLCore) = true
is_highlevel(::Type{<:AbstractPNTD}) = false
is_highlevel(::Type{<:AbstractHLCore}) = true

"Token identity is collective."
function is_collective_token end
is_collective_token(pntd::AbstractPNTD) = is_discrete(pntd) || is_continuous(pntd)

"Token identity is individual."
function is_individual_token end
is_individual_token(pntd::AbstractPNTD) = is_highlevel(pntd)


end # module PnmlTypes
