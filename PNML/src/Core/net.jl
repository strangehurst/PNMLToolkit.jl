const elabelT =  LittleDict{Symbol, Any}
const tparserT = LittleDict{String, LittleDict{String, Any}}
const efilterT = LittleDict{Symbol, Any}
const lparserT = LittleDict{Symbol, Any}
const vsubT =    LittleDict{Symbol, Vector{NamedTuple}}
const varsT =    LittleDict{Symbol, Set{Symbol}}

"""
$(TYPEDEF)

One Petri Net of a PNML model.

$(FIELDS)

"""
@kwdef mutable struct PnmlNet{T <: PNMLVariant} <: AbstractPnmlNet
    #"The meta-model type this net implements."
    const type::Symbol# PNTD
    # PNML ID needed here for multiple nets of same `type` in a `<pnml>` model.
    const id::Symbol
    # Ensure that each PNML ID in a net is unique using a registry.
    const idregistry::IDRegistry
    # Holds all pages. Shared by pages that may have sub-pages.
    # All PNML net objects are attached to a `Page` by ID. There must be at least one `Page`.
    pagedict::OrderedDict{Symbol, Page{PnmlNet{T}}}
    # These dictionaries hold all places, transitions, arcs, refs. Was in PnmlNetData
    place_dict::OrderedDict{Symbol, Any} = OrderedDict{Symbol, Any}()
    transition_dict::OrderedDict{Symbol, Any} = OrderedDict{Symbol, Any}()
    arc_dict::OrderedDict{Symbol, Any} = OrderedDict{Symbol, Any}()
    refplace_dict::OrderedDict{Symbol, Any} = OrderedDict{Symbol, Any}()
    reftransition_dict::OrderedDict{Symbol, Any} = OrderedDict{Symbol, Any}()
    # Keys of pages in `pagedict` owned by this net.
    # Use only `page_idset` not full `netsets` collection as net only contains pages.
    page_idset::OrderedSet{Symbol} = OrderedSet{Symbol}()

    # Declarations dictionarys filled with built-ins & when parsing `declaration`.
    # We use the declarations toolkit for non-high-level nets,
    # and assume a minimum level of function for high-level nets.
    # Declarations present in the input file will overwrite thesenet. Particulary '<dot>'.
    ddict::RefValue{DeclDict} = Ref{DeclDict}() # undef

    # PNML Label with `Text` `Graphics`, `ToolInfo` and zero or more `Declarations`.
    # Yes, The ISO 15909-2 Standard uses `Declarations` inside `Declaration`.
    declaration::Maybe{Declaration} = nothing
    # PNML Label with `Text` `Graphics`, `ToolInfo`.
    namelabel::Maybe{Name} = nothing
    # Zero or more `<toolspecific>` may be attched to net.
    toolspecinfos::Vector{ToolInfo} = ToolInfo[]
    # Zero or more extra PNML Labels may be attched to net.
    extralabels::LittleDict{Symbol, Any} = LittleDict{Symbol,Any}()
    # Map xml tag symbol to parser callable for built-in labels and extension labels.
    #todo Referplugins!ence to label parser interface.
    labelparser::lparserT = lparserT() #LittleDict{Symbol, Any} =  LittleDict{Symbol, Any}()
    """
        Collection that associates a tool name & version with a callable parser.
        The parser turns `<toolspecific name="" version="">` into `ToolInfo` objects.
    """
    toolparser::tparserT = tparserT()  #LittleDict{String, LittleDict{String, Any}} =
                #LittleDict{String, LittleDict{String, Any}}()

    # Collection of filters used by enabling rule.
    enabled_filters::efilterT = efilterT() #LittleDict{Symbol, Any} = LittleDict{Symbol, Any}()

    # keys are transition ids, values are sets of variable ids
    "Cache of variable ids used by expressions related to the transition."
    vars::varsT = varsT() #LittleDict{Symbol, Set{Symbol}} = LittleDict{Symbol, Set{Symbol}}()

    # keys are transition ids, values are vectors of substution namedtuples
    "Cache of variable substitutons for this transition"
    varsubs::vsubT = vsubT() # = LittleDict{Symbol, Vector{NamedTuple}} = LittleDict{Symbol, Vector{NamedTuple}}()

end #= mutable struct PnmlNet =#
"Iterate enable filters"
function filters(net::PnmlNet{T}) where {T <: PNMLVariant}
    # @show net.enabled_filters
    values(net.enabled_filters)
end

"Create empty net with builtins installed for use in test scaffolding."
function make_net(pntd::Symbol, id=:make_net,)
    var = pntd2variant(pntd)
    net = PnmlNet{var}(; type=pntd, id,
                    idregistry=IDRegistry(),
                    pagedict=OrderedDict{Symbol, Page{PnmlNet{var}}}())

    net.ddict[] = DeclDict(net) # Empty DeclDict
    net.declaration = Declaration(; ddict=decldict(net)) # Empty Declarations

    fill_builtin_sorts!(net)
    fill_builtin_labelparsers!(net)
    fill_builtin_toolparsers!(net)
    fill_builtin_enabled_filters!(net)
    return net
end
"""
$METHODLIST

Extract the variant type of a `PnmlNet`.
"""
function vartype end
vartype(::PnmlNet{T}) where {T <: PNMLVariant} = T
vartype(::Type{PnmlNet{T}}) where {T <: PNMLVariant} = T
"""
$METHODLIST

Extract the PNTD symbol of a `PnmlNet`.
"""
function pntdsym(net::AbstractPnmlNet)
    if net isa PnmlNet
        return net.type
    end
    error("expected PnmlNet found $(typeof(net))")
end
pntd_of(net::AbstractPnmlNet) = pnmltype(net.type)

"Return IDRegistry of a PnmlNet."
registry_of(net::PnmlNet) = net.idregistry
decldict(net::PnmlNet) = net.ddict[]
declarations(net::PnmlNet) =  declarations(decldict(net))

# `pagedict` is all pages in `net`, `page_idset` only for direct pages of net.
pagedict(net::PnmlNet) = net.pagedict # Will be ordered.
page_idset(net::PnmlNet) = net.page_idset

placedict(net::PnmlNet)         = net.place_dict
transitiondict(net::PnmlNet)    = net.transition_dict
arcdict(net::PnmlNet)           = net.arc_dict
refplacedict(net::PnmlNet)      = net.refplace_dict
reftransitiondict(net::PnmlNet) = net.reftransition_dict

#"Return iterator over keys of a dictionary" #! verify same as PnmlKeySet for flattened page
# iterate over all pages' idsets
# place_idset(net::PnmlNet)         = net.place_idset #Iterators.map(place_idset, allpages(net))
# transition_idset(net::PnmlNet)    = net.transition_idset #Iterators.map(transition_idset, allpages(net))
# arc_idset(net::PnmlNet)           = net.arc_idset #Iterators.map(arc_idset, allpages(net))
# refplace_idset(net::PnmlNet)      = net.refplace_idset #Iterators.map(refplace_idset, allpages(net))
# reftransition_idset(net::PnmlNet) = net.reftransition_idset #Iterators.map(reftransition_idset, allpages(net))

npages(net::PnmlNet)          = length(pagedict(net))
nplaces(net::PnmlNet)         = length(placedict(net))
ntransitions(net::PnmlNet)    = length(transitiondict(net))
narcs(net::PnmlNet)           = length(arcdict(net))
nrefplaces(net::PnmlNet)      = length(refplacedict(net))
nreftransitions(net::PnmlNet) = length(reftransitiondict(net))

"""
    allpages(net::PnmlNet|dict::OrderedDict) -> Iterator

Return iterator over all pages in the net. Maintains insertion order.
"""
allpages(net::PnmlNet) = allpages(pagedict(net))
allpages(pd::OrderedDict) = values(pd)

"Iterator of `Pages` directly owned by `net`."
pages(net::PnmlNet) = Iterators.map(pg -> pagedict(net)[pg], page_idset(net))

"Usually the only interesting page."
firstpage(net::PnmlNet) = first(values(pagedict(net)))

has_tools(net::PnmlNet) = !isnothing(net.toolspecinfos)
has_place(net::PnmlNet, id::Symbol)    = haskey(placedict(net), id)
has_transition(net::PnmlNet, id::Symbol)  = haskey(transitiondict(net), id)
has_arc(net::PnmlNet, id::Symbol)  = haskey(arcdict(net), id)
has_refplace(net::PnmlNet, id::Symbol)      = haskey(refplacedict(net), id)
has_reftransition(net::PnmlNet, id::Symbol) = haskey(reftransitiondict(net), id)

toolinfos(net::PnmlNet) = net.toolspecinfos

# Return iterator of dictionary values.
places(net::PnmlNet)         = values(placedict(net))
transitions(net::PnmlNet)    = values(transitiondict(net))
arcs(net::PnmlNet)           = values(arcdict(net))
refplaces(net::PnmlNet)      = values(refplacedict(net))
reftransitions(net::PnmlNet) = values(reftransitiondict(net))

# Return iterator of dictionary keys.
place_ids(net::PnmlNet)         = keys(placedict(net))
transition_ids(net::PnmlNet)    = keys(transitiondict(net))
arc_ids(net::PnmlNet)           = keys(arcdict(net))
refplace_ids(net::PnmlNet)      = keys(refplacedict(net))
reftransition_ids(net::PnmlNet) = keys(reftransitiondict(net))

place(net::PnmlNet, id::Symbol)         = placedict(net)[id]
transition(net::PnmlNet, id::Symbol)    = transitiondict(net)[id]
arc(net::PnmlNet, id::Symbol)           = arcdict(net)[id]
refplace(net::PnmlNet, id::Symbol)      = refplacedict(net)[id]
reftransition(net::PnmlNet, id::Symbol) = reftransitiondict(net)[id]

"""
Return `Arc` from 'src' to 'tgt' or `nothing`.
Useful for graphs where arcs are represented by a tuple or pair (source,target).
"""
function arc(net, src::Symbol, tgt::Symbol)
    x = Iterators.filter(a -> source(a) === src &&
                                          target(a) === tgt, values(arcdict(net)))
    isempty(x) ? nothing : first(x)
end

# Iterate IDs of arcs that have given source or target.
function all_arcs(net::PnmlNet, id::Symbol)
    Iterators.map(pid, Iterators.filter(a -> (source(a) === id || target(a) === id),
                                              values(arcdict(net))))
end
function src_arcs(net::PnmlNet, id::Symbol)
    Iterators.map(pid, Iterators.filter(a -> (source(a) === id), values(arcdict(net))))
end
function tgt_arcs(net::PnmlNet, id::Symbol)
    Iterators.map(pid, Iterators.filter(a -> (target(a) === id), values(arcdict(net))))
end

initial_marking(net::PnmlNet, placeid::Symbol) = initial_marking(place(net, placeid))
inscription(net::PnmlNet, arc_id::Symbol) = inscription(arcdict(net)[arc_id])
inhibitor(net::PnmlNet, arc_id::Symbol) = inscription(arcdict(net)[arc_id])
reader(net::PnmlNet, arc_id::Symbol) = inscription(arcdict(net)[arc_id])
condition(net::PnmlNet, trans_id::Symbol) = condition(transition(net, trans_id))

"""
    inscriptions(net::PnmlNet) -> Iterator

Return iterator over REFID => inscription(arc) pairs of `net`. This is the same order as `arcs`.
"""
function inscriptions end
function inscriptions(net::AbstractPnmlNet)
    # empty varible substitutions
    Iterators.map((arc_id, a) -> arc_id => inscription(a)(NamedTuple()), pairs(arcdict(net)))
end

function inscriptions(net::PnmlNet{HighLevelPNML}) #TODO! non-ground terms for HL
    @error "high level net $(pid(net)) needs variable substitution"
    varsubs = NamedTuple()
    Iterators.map((arc_id, a) -> arc_id => inscription(a)(varsubs), pairs(arcdict(net)))
end

"""
$(TYPEDSIGNATURES)

Return iterator  over REFID => condition(transaction) pairs of `net`.
This is the same order as `transactions`.
"""
function conditions end
function conditions(net::AbstractPnmlNet)
    Iterators.map((tr_id, t)->tr_id => condition(t)(NamedTuple()), pairs(transitiondict(net)))
end

function conditions(net::PnmlNet{HighLevelPNML}) #TODO! non-ground terms for HL
    @error "high level net $(pid(net)) needs variable substitution"
end

function rates(net::AbstractPnmlNet)
    #[tid => rate_value(t) for (tid, t) in pairs(transitiondict(net))]
    Iterators.map((tr_id::Symbol, t)->tr_id => rate_value(t), pairs(transitiondict(net)))
end


#------------------------------------------------------------------------------
# DeclDict access
#------------------------------------------------------------------------------
useroperators(@nospecialize(net::PnmlNet))  = useroperators(decldict(net))
variabledecls(@nospecialize(net::PnmlNet))  = variabledecls(decldict(net))
namedsorts(@nospecialize(net::PnmlNet))     = namedsorts(decldict(net))
arbitrarysorts(@nospecialize(net::PnmlNet)) = arbitrarysorts(decldict(net))
partitionsorts(@nospecialize(net::PnmlNet)) = partitionsorts(decldict(net))
namedoperators(@nospecialize(net::PnmlNet)) = namedoperators(decldict(net))
arbitraryops(@nospecialize(net::PnmlNet))   = arbitraryops(decldict(net))
partitionops(@nospecialize(net::PnmlNet))   = partitionops(decldict(net))
feconstants(@nospecialize(net::PnmlNet))    = feconstants(decldict(net))
multisetsorts(@nospecialize(net::PnmlNet))  = multisetsorts(decldict(net))
productsorts(@nospecialize(net::PnmlNet))   = productsorts(decldict(net))

variabledecl(net::PnmlNet, id::Symbol)  = variabledecls(net)[id]::VariableDeclaration
namedsort(net::PnmlNet, id::Symbol)               = namedsorts(net)[id]::NamedSort
arbitrarysort(net::PnmlNet, id::Symbol)       = arbitrarysorts(net)[id]::ArbitrarySort
partitionsort(net::PnmlNet, id::Symbol) = partitionsorts(net)[id]::PartitionSort
multisetsort(net::PnmlNet, id::Symbol)  = multisetsorts(net)[id]::MultisetSort
productsort(net::PnmlNet, id::Symbol)   = productsorts(net)[id]::ProductSort
namedop(net::PnmlNet, id::Symbol)      = namedoperators(net)[id]::NamedOperator
arbitraryop(net::PnmlNet, id::Symbol)   = arbitraryops(net)[id]::ArbitraryOperator
partitionop(net::PnmlNet, id::Symbol)   = partitionops(net)[id] ############# TODO! WHAT TYPE?
feconstant(net::PnmlNet, id::Symbol)    = feconstants(net)[id]::FEConstant
useroperator(net::PnmlNet, id::Symbol)  = useroperators(net)[id]::UserOperator

#useroperator(net::PnmlNet)  = useroperator(decldict(net)) # no SortRef
#variabledecl(net::PnmlNet)  = variabledecl(decldict(net))
namedsort(net::PnmlNet, ref::SortRef)     = namedsort(net, refid_of(ref))
arbitrarysort(net::PnmlNet, ref::SortRef) = arbitrarysort(net, refid_of(ref))
partitionsort(net::PnmlNet, ref::SortRef) = partitionsort(net, refid_of(ref))
#namedoperator(net::PnmlNet) = namedoperator(decldict(net))
#arbitraryop(net::PnmlNet)   = arbitraryoperator(decldict(net))
#partitionop(net::PnmlNet)   = partitionop(decldict(net))
feconstant(net::PnmlNet, ref::SortRef)    = feconstant(net, refid_of(ref))
multisetsort(net::PnmlNet, ref::SortRef)  = multisetsort(net, refid_of(ref))
productsort(net::PnmlNet, ref::SortRef)   = productsort(net, refid_of(ref))

"Lookup operator with `id` in DeclDict.::Symbol May be namedop, feconstant, etc"
operator(net::PnmlNet, id::Symbol) = operator(decldict(net), id)
"""
    operators(net::PnmlNet)-> Iterator
Iterate over each operator in the operator subset of declaration dictionaries .
"""
operators(net::PnmlNet) = operators(decldict(net))

has_operator(net::PnmlNet, id::Symbol) = has_operator(decldict(net), id)

"""
    has_key(net::PnmlNet, dict, key::Symbol) -> Bool
Where `dict` is the access method for a dictionary in `DeclDict`.
"""
has_key(net::PnmlNet, dict, key::Symbol) = haskey(dict(decldict(net)), key)::Bool

has_variabledecl(net::PnmlNet, id::Symbol)   = has_key(net, variabledecls, id)
has_namedsort(net::PnmlNet, id::Symbol)      = has_key(net, namedsorts, id)
has_arbitrarysort(net::PnmlNet, id::Symbol)  = has_key(net, arbitrarysorts, id)
has_partitionsort(net::PnmlNet, id::Symbol)  = has_key(net, partitionsorts, id)
has_multisetsort(net::PnmlNet, id::Symbol)   = has_key(net, multisetsorts, id)
has_productsort(net::PnmlNet, id::Symbol)    = has_key(net, productsorts, id)
has_namedop(net::PnmlNet, id::Symbol)        = has_key(net, namedoperators, id)
has_arbitraryop(net::PnmlNet, id::Symbol)    = has_key(net, arbitraryops, id)
has_partitionop(net::PnmlNet, id::Symbol)    = has_key(net, partitionops, id)
has_feconstant(net::PnmlNet, id::Symbol)     = has_key(net, feconstants, id)
has_useroperator(net::PnmlNet, id::Symbol)   = has_key(net, useroperators, id)

has_variabledecl(net::PnmlNet, ref::SortRef)  = has_key(net, variabledecls, refid_of(ref))
has_namedsort(net::PnmlNet, ref::SortRef)     = has_key(net, namedsorts, refid_of(ref))
has_arbitrarysort(net::PnmlNet, ref::SortRef) = has_key(net, arbitrarysorts, refid_of(ref))
has_partitionsort(net::PnmlNet, ref::SortRef) = has_key(net, partitionsorts, refid_of(ref))
has_multisetsort(net::PnmlNet, ref::SortRef)  = has_key(net, multisetsorts, refid_of(ref))
has_productsort(net::PnmlNet, ref::SortRef)   = has_key(net, productsorts,refid_of(ref) )
has_namedop(net::PnmlNet, ref::SortRef)       = has_key(net, namedoperators, refid_of(ref))
has_arbitraryop(net::PnmlNet, ref::SortRef)   = has_key(net, arbitraryops, refid_of(ref))
has_partitionop(net::PnmlNet, ref::SortRef)   = has_key(net, partitionops, refid_of(ref))
has_feconstant(net::PnmlNet, ref::SortRef)    = has_key(net, feconstants, refid_of(ref))
has_useroperator(net::PnmlNet, ref::SortRef)  = has_key(net, useroperators, refid_of(ref))


#------------------------------------------------------------------------------
"""
Error if any diagnostic messages are collected. Especially intended to detect semantc error.
"""
function verify(net::PnmlNet, verbose::Bool)
    verbose && println("## verify $(typeof(net)) $(pid(net))")
    errors = String[]
    verify!(errors, net, verbose)
    verify!(errors, decldict(net), verbose, net)
    isempty(errors) || error("verify(net) $(pid(net)) error(s):\n ", join(errors, ",\n "))
    return true
end

function verify!(errors::Vector{String}, net::PnmlNet, verbose::Bool)
    # pagedict
    # netdata
    # page_set
    # toolspecifics
    # extralabels

    # Are the things with PNML IDs in the IDRegistry?
    verify_ids!(errors, "net id", (net,), net)
    verify_ids!(errors, "pages id", pages(net), net)
    verify_ids!(errors, "allpages id", allpages(net), net)
    verify_ids!(errors, "places id", places(net), net)
    verify_ids!(errors, "transition id", transitions(net), net)
    verify_ids!(errors, "arcs id", arcs(net), net)
    verify_ids!(errors, "refplaces id", refplaces(net), net)
    verify_ids!(errors, "reftransitions id", reftransitions(net), net)

    verify!(errors, decldict(net), verbose, net)

    let d = net.declaration
        @assert !isnothing(d)
        isnothing(d) || verify!(errors, d, verbose, net)
    end

    # Call net object's verify method.
    foreach(x -> verify!(errors, x, verbose, net), allpages(net))
    foreach(x -> verify!(errors, x, verbose, net), places(net))
    foreach(x -> verify!(errors, x, verbose, net), transitions(net))
    foreach(x -> verify!(errors, x, verbose, net), arcs(net))
    foreach(x -> verify!(errors, x, verbose, net), refplaces(net))
    foreach(x -> verify!(errors, x, verbose, net), reftransitions(net))

    !isnothing(toolinfos(net)) &&
        foreach(x -> verify!(errors, x, verbose, net), toolinfos(net))

    if npages(net) == 1
        nrefplaces(net) == 0 ||
            push!(errors, "npages==1 && refplacedict not empty")
        isempty(refplacedict(net)) ||
            push!(errors, "npages==1 && refplacedict not empty")
        nreftransitions(net) == 0 ||
            push!(errors, "npages==1 && reftransitiondict not empty")
        isempty(reftransitiondict(net)) ||
            push!(errors, "npages==1 && reftransitiondict not empty")
    end
    return errors
end

"""
    verify_ids!(errors, str, iterable, net::PnmlNet) -> Vector{String}

Iterate over `iterable` testing that `pid` is registered in `net`.
`str` used in message appended to `errors` vector of strings.
"""
function verify_ids!(errors, str::AbstractString, iterable, net::PnmlNet)
    for x in iterable
        if !isregistered(registry_of(net), pid(x))
            push!(errors, string(str, " ", pid(x), " not registered")::String)
        end
    end
end


#------------------------------------------------------------------------------
function Base.summary(net::PnmlNet)
    string(typeof(net), " id ", repr(pid(net)),
            " name ", repr(name(net)), ", ",
            " pntd ", pntdsym(net), ", ",
            npages(net), " pages, ",
            has_tools(net) ? length(toolinfos(net)) : 0, " toolinfos")::String
end

# No indent here.
function Base.show(io::IO, net::PnmlNet)
    print(io, indent(io), typeof(net), "(", )
    print(io, repr(pid(net)), ", ")
    print(io, repr(name(net)), ", ")
    print(io, repr(pntdsym(net)), ", ")
    iio = inc_indent(io)
    println(io)

    print(io, "Pages = ", collect(keys(pagedict(net))))
    for page in values(pagedict(net))
        print(iio, '\n', indent(iio))
        println(iio, page)
    end
    println(io)
    println(io, "Declarations = ", repr(decldict(net)))
    println(io, toolinfos(net))
    println(io, extralabels(net))

    println(io, "Arcs:")
    foreach(arcs(net)) do a
        println(io, a)
    end
    foreach(arc_ids(net)) do id
        println(io, id)
    end
    println(io, "Places:")
    foreach(places(net)) do p
        println(io, p)
    end
    foreach(place_ids(net)) do p
        show(io, p); println(io)
    end
    println(io, "Transitions:")
    foreach(transitions(net)) do t
        println(io, t)
    end

    println(io, "Reference Places:")
    foreach(refplaces(net)) do rp
        println(io, rp)
    end

    println(io, "Reference Transitions:")
    foreach(reftransitions(net)) do rt
        println(io, rt)
    end
end

show_sorts(net::PnmlNet) = show_sorts(decldict(net))
