"""
Petri Net Type Definition (pntd) URI mapped to AbstractPNTD subtype singleton.
"""
module PnmlTypes

using DocStringExtensions
using SciMLLogging: @SciMLMessage

# Abstract Types
export APNTD, AbstractContinuousPNTD, AbstractHLPNTD, AbstractDiscretePNTD, AbstractPNTD
# Concrete Types
export ContinuousNet, HLCoreNet, HLPNG, PTNet, PT_HLPNG, PnmlCoreNet, SymmetricNet
# Functions
export is_collective_token, is_continuous, is_discrete, is_highlevel, is_individual_token,
    pnmltype
export ContinuousPNML, DiscretePNML, HighLevelPNML, OtherPNTD, PNMLVariant, pntd2variant,
    pntd_symbol, core_nettypes, all_nettypes

"""
$(TYPEDEF)
Abstract root of a dispatch type based on Petri Net Type Definitions (pntd).

Each Petri Net Markup Language (PNML) `<net>` element will have a 'type' XML attribute.
That string should refer to a RelaxNG schema defining the syntax and semantics of a meta-module
of a Petri net family. Some examples are Place/Transition and High-level.
See ISO 15909-2, http://www.pnml.org/ for details.

Selected abbreviations and URIs that do not resolve to a valid schema file
are suported by this tool. See [`pntd_map`](@ref).

Refer to [`pntd_symbol`](@ref) and [`pnmltype`](@ref) for
how to get from the string to a pntd singleton.
"""
abstract type AbstractPNTD end
"Abbreviation for AbstractPNTD"
const APNTD = AbstractPNTD

"""
$(TYPEDEF)
Base of token/integer-based Petri Net pntds.

See [`PnmlCoreNet`](@ref), [`PTNet`](@ref) and others.
"""
abstract type AbstractDiscretePNTD <: AbstractPNTD end

"""
$(TYPEDEF)
The most minimal concrete Petri Net.

Used to implement and test the core PNML support.
Covers the complete graph infrastructure including labels attached to nodes and arcs.
"""
struct PnmlCoreNet <: AbstractDiscretePNTD end

"""
$(TYPEDEF)
Place-Transition Petri Nets add small extensions to core PNML.
Integer-valued initialMarking and inscription.

The grammer file is ptnet.pnml so we name it PTNet.
Note that 'PT' is often the prefix for XML tags specialized for this net type.
"""
struct PTNet <: AbstractDiscretePNTD end

"""
$(TYPEDEF)
Base of High Level Petri Net pntds which add large extensions to PNML core.
hlinitialMarking, hlinscription, and defined label structures.

See [`PnmlTypes.HLCoreNet`](@ref), [`PnmlTypes.SymmetricNet`](@ref),
[`PnmlTypes.PT_HLPNG`](@ref) and others.
"""
abstract type AbstractHLPNTD <: AbstractPNTD end

"""
$(TYPEDEF)
`HLCoreNet` can be used for generic high-level nets.
We try to implement and test all function at `PnmlCoreNet level, but
expect to find use for a concrete type at this level for testing high-level extensions.
"""
struct HLCoreNet <: AbstractHLPNTD end

"""

$(TYPEDEF)
High-Level Petri Net Graphs (HLPNGs) are the most intricate High-Level Petri Net schema.
It extends [`SymmetricNet`](@ref), including with
   - declarations for sorts and functions (ArbitraryDeclarations)
   - sorts for Integer, String, and List
"""
struct HLPNG <: AbstractHLPNTD end

"""
$(TYPEDEF)
Place-Transition Net in HLCoreNet notation.
"""
struct PT_HLPNG <: AbstractHLPNTD end

"""
$(TYPEDEF)
Symmetric Petri Net is the best-worked use case in the `primer`
and ISO 15909 standard part 2.
"""
struct SymmetricNet <: AbstractHLPNTD end

"""
$(TYPEDEF)
Uses floating point numbers for markings, inscriptions.
Most of the functionality is shared with [`AbstractDiscretePNTD`](@ref).
This seperates the
"""
abstract type AbstractContinuousPNTD <: AbstractPNTD end

"""
$(TYPEDEF)
TODO: Continuous Petri Net
"""
struct ContinuousNet <: AbstractContinuousPNTD end

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

            "continuous" => :continuous, # PTNet with Float64
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
:pnmlcore
:hlcore
:ptnet
:hlnet
:pt_hlpng
:symmetric
:continuous

Values are concrete singletons.
"""
const pnmltype_map = Dict{Symbol, AbstractPNTD}(
        :pnmlcore => PnmlCoreNet(),
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
all_nettypes() = keys(pnmltype_map)
all_nettypes(p) = Iterators.filter(p, keys(pnmltype_map))

"""
    core_nettypes() -> Tuple{<:AbstractPNTD}

Useful for testing the 3 kinds of tokens corresponding to
abstract subclasses of `AbstractPNTD` (or `AbstractPNTD`) .
"""
core_nettypes() = (:pnmlcore, :hlcore, :continuous)


"Tokens represented by integers."
function is_discrete end
is_discrete(::AbstractPNTD) = false
is_discrete(::AbstractDiscretePNTD) = true
is_discrete(::Type{<:AbstractPNTD}) = false
is_discrete(::Type{<:AbstractDiscretePNTD}) = true

function is_discrete(s::Symbol)
    s === :pnmlcore ||
    s === :ptnet # || s === :pt_hlpng
end
is_discrete(::Val{:pnmlcore}) = true
is_discrete(::Val{:hlcore}) = false
is_discrete(::Val{:ptnet}) = true
is_discrete(::Val{:hlnet}) = false
is_discrete(::Val{:pt_hlpng}) = false
is_discrete(::Val{:symmetric}) = false
is_discrete(::Val{:continuous}) = false

"Tokens represented by floating point."
function is_continuous end
is_continuous(::AbstractPNTD) = false
is_continuous(::AbstractContinuousPNTD) = true
is_continuous(::Type{<:AbstractPNTD}) = false
is_continuous(::Type{<:AbstractContinuousPNTD}) = true

function is_continuous(s::Symbol)
    s === :continuous
end
is_continuous(::Val{:pnmlcore}) = true
is_continuous(::Val{:hlcore}) = false
is_continuous(::Val{:ptnet}) = true
is_continuous(::Val{:hlnet}) = false
is_continuous(::Val{:pt_hlpng}) = false
is_continuous(::Val{:symmetric}) = false
is_continuous(::Val{:continuous}) = true

"Tokens represented by multiset (aka bag)."
function is_highlevel end
is_highlevel(::AbstractPNTD) = false
is_highlevel(::AbstractHLPNTD) = true
is_highlevel(::Type{<:AbstractPNTD}) = false
is_highlevel(::Type{<:AbstractHLPNTD}) = true
function is_highlevel(s::Symbol)
    s === :hlcore ||
    s === :pt_hlpng ||
    s === :hlnet ||
    s === :symmetric
end
is_highlevel(::Val{:pnmlcore}) = true
is_highlevel(::Val{:hlcore}) = false
is_highlevel(::Val{:ptnet}) = true
is_highlevel(::Val{:hlnet}) = false
is_highlevel(::Val{:pt_hlpng}) = false
is_highlevel(::Val{:symmetric}) = false
is_highlevel(::Val{:continuous}) = false

"Token identity is collective."
function is_collective_token end
is_collective_token(pntd::AbstractPNTD) = is_discrete(pntd) || is_continuous(pntd)
is_collective_token(s::Symbol) = is_discrete(Val(s)) || is_continuous(Val(s))

is_collective_token(::Val{:pnmlcore}) = true
is_collective_token(::Val{:hlcore}) = false
is_collective_token(::Val{:ptnet}) = true
is_collective_token(::Val{:hlnet}) = false
is_collective_token(::Val{:pt_hlpng}) = true
is_collective_token(::Val{:symmetric}) = false
is_collective_token(::Val{:continuous}) = true


"Token identity is individual."
function is_individual_token end
is_individual_token(pntd::AbstractPNTD) = is_highlevel(pntd)
is_individual_token(s::Symbol) = is_highlevel(Val(s))

is_individual_token(::Val{:pnmlcore}) = false
is_individual_token(::Val{:hlcore}) = true
is_individual_token(::Val{:ptnet}) = false
is_individual_token(::Val{:hlnet}) = true
is_individual_token(::Val{:pt_hlpng}) = false
is_individual_token(::Val{:symmetric}) = true
is_individual_token(::Val{:continuous}) = false


#-----------------------------------------------------------------------------------------
"""
$(TYPEDSIGNATURES)

Add or replace mapping from Symbol `s` to [`AbstractPNTD`](@ref) singleton `pntd`.
"""
function add_nettype!(dict::AbstractDict, s::Symbol, pntd::Symbol)
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
    pnmltype(pntd::AbstractPNTD) -> AbstractPNTD
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
    @inbounds pnmltype_map[s]
else
    throw(DomainError("Unknown PNTD symbol $s"))
end


abstract type PNMLVariant end

# a tag known as the vartype
"""
    $TYPEDEF

One of the possible values of the `PnmlNet` `vartype`.
This variant is a Place Transition Petri net where
the marking and inscription are restricted to integers.

`pntd_of(net)` is  `AbstractDiscretePNTD` || `PT_HLPNG`.
"""
abstract type DiscretePNML <: PNMLVariant end
"""
    $TYPEDEF

One of the possible values of the `PnmlNet` `vartype`.
This variant is a Place Transition Petri net where
the marking and inscription are floaing point numbers.

`pntd_of(net)` is `<:AbstractContinuousPNTD`.
"""
abstract type ContinuousPNML <: PNMLVariant end
"""
    $TYPEDEF

One of the possible values of the ``PnmlNet` vartype`.
This variant is a High-levl Petri net were
the marking and insciption is a multi-sorted algebra expression.

`pntd_of(net)` is `AbstractHLPNTD && !PT_HLPNG`
"""
abstract type HighLevelPNML <: PNMLVariant end
"""
    $TYPEDEF

One of the possible values of the `PnmlNet` `vartype`.
This variant is for non-Petri net uses.

`pntd_of(net)` is `AbstractPNTD && !AbstractHLPNTD && !AbstractContinuousPNTD && !AbstractDiscretePNTD
"""
abstract type OtherPNTD <: PNMLVariant end

"""
    $TYPEDSIGNATURES

Deduce `PNMLVariant`.
"""
function pntd2variant end
function pntd2variant(s::Symbol)
    pntd2variant(pnmltype_map[s])
    if is_continuous(s)
        return ContinuousPNML
    elseif is_discrete(s) # || s === :pt_hlpng
        return DiscretePNML
    elseif is_highlevel(s)
        return HighLevelPNML
    else
        return OtherPNTD
    end
end
function pntd2variant(pntd::AbstractPNTD)
    if pntd isa AbstractContinuousPNTD
        return ContinuousPNML
    elseif pntd isa Union{AbstractDiscretePNTD, PT_HLPNG}
        return DiscretePNML
    elseif pntd isa AbstractHLPNTD
        return HighLevelPNML
    else
        return OtherPNTD
    end
end

#=
Traits multiset, dot, number
- AbstractHLPNTD: marking, inscriptions are `multiset`s includes SymmetricNet and HLPNG
- PT_HLPNG: HL restricted to multiset over dot constant and dot2int
- AbstractPNTD: marking, inscriptions are `Number`s,
  includes AbstractDiscretePNTD, AbstractContinuousPNTD
=#
end # module PnmlTypes
