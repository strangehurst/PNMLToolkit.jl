"""
$(TYPEDEF)

One Petri Net of a PNML model.

$(FIELDS)

"""
@kwdef mutable struct PnmlNet{PNTD <: AbstractPNTD} <: AbstractPnmlNet
    #"The meta-model type this net implements."
    const type::PNTD
    # PNML ID needed here for multiple nets of same `type` in a `<pnml>` model.
    const id::Symbol
    # Ensure that each PNML ID in a net is unique using a registry.
    const idregistry::IDRegistry
    # Holds all pages. Shared by pages that may have sub-pages.
    # All PNML net objects are attached to a `Page`. And there must be at least one `Page`.
    pagedict::OrderedDict{Symbol, Page{PnmlNet{PNTD}}} # abstract Page
    # Shared by pages, holds all places, transitions, arcs, refs
    netdata::PnmlNetData = PnmlNetData()
    # Keys of pages in `pagedict` owned by this net.
    # Use only `page_idset` not full `netsets` collection as net only contains pages.
    page_idset::OrderedSet{Symbol} = OrderedSet{Symbol}()

    # Declarations dictionarys filled with built-ins & when parsing `declaration`.
    # We use the declarations toolkit for non-high-level nets,
    # and assume a minimum level of function for high-level nets.
    # Declarations present in the input file will overwrite these. Particulary '<dot>'.
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
    #todo Reference to label parser interface.
    labelparser::LittleDict{Symbol, Any} =  LittleDict{Symbol, Any}()
    """
        Collection that associates a tool name & version with a callable parser.
        The parser turns `<toolspecific name="" version="">` into `ToolInfo` objects.
    """
    toolparser::LittleDict{String, LittleDict{String, Any}} =
                LittleDict{String, LittleDict{String, Any}}()

    # Collection of filters used by enabling rule.
    enabled_filters::LittleDict{Symbol, Any} = LittleDict{Symbol, Any}()

    # keys are transition ids, values are sets of variable ids
    "Cache of variable ids used by expressions related to the transition."
    vars::LittleDict{Symbol, Set{Symbol}} = LittleDict{Symbol, Set{Symbol}}()

    # keys are transition ids, values are vectors of substution namedtuples
    "Cache of variable substitutons for this transition"
    varsubs::LittleDict{Symbol, Vector{NamedTuple}} = LittleDict{Symbol, Vector{NamedTuple}}()

end #= mutable struct PnmlNet =#

"Iterate enable filters"
function filters(net::AbstractPnmlNet)
    # @show net.enabled_filters
    values(net.enabled_filters)
end

"Create empty net with builtins installed for use in test scaffolding."
function make_net(type::AbstractPNTD, id=:make_net,)
    net = PnmlNet(; type, id,
                    idregistry=IDRegistry(),
                    pagedict=OrderedDict{Symbol, Page{PnmlNet{typeof(type)}}}())

    net.ddict[] = DeclDict(net) # Empty DeclDict
    net.declaration = Declaration(; ddict=decldict(net)) # Empty Declarations

    fill_builtin_sorts!(net)
    fill_builtin_labelparsers!(net)
    fill_builtin_toolparsers!(net)
    fill_builtin_enabled_filters!(net)
    return net
end

pntd_of(net::PnmlNet) = net.type
nettype(net::PnmlNet) = typeof(net.type)

"Return IDRegistry of a PnmlNet."
registry_of(net::PnmlNet) = net.idregistry
decldict(net::PnmlNet) = net.ddict[]
declarations(net::PnmlNet) =  declarations(decldict(net))

# `pagedict` is all pages in `net`, `page_idset` only for direct pages of net.
pagedict(net::PnmlNet) = net.pagedict # Will be ordered.
page_idset(net::PnmlNet) = net.page_idset # Indices into `pagedict` directly owned by net.

netdata(net::PnmlNet) = net.netdata
netsets(net::PnmlNet) = throw(DomainError("PnmlNet $(pid(net)) does not have a PnmlKeySet, did you mean `netdata`?"))

placedict(net::PnmlNet)         = placedict(netdata(net))
transitiondict(net::PnmlNet)    = transitiondict(netdata(net))
arcdict(net::PnmlNet)           = arcdict(netdata(net))
inhibit_arcdict(net::PnmlNet)   = inhibit_arcdict(netdata(net))
read_arcdict(net::PnmlNet)      = read_arcdict(netdata(net))
refplacedict(net::PnmlNet)      = refplacedict(netdata(net))
reftransitiondict(net::PnmlNet) = reftransitiondict(netdata(net))

#"Return iterator over keys of a dictionary" #! verify same as PnmlKeySet for flattened page
place_idset(net::PnmlNet)         = keys(placedict(net))
transition_idset(net::PnmlNet)    = keys(transitiondict(net))
arc_idset(net::PnmlNet)           = keys(arcdict(net))
refplace_idset(net::PnmlNet)      = keys(refplacedict(net))
reftransition_idset(net::PnmlNet) = keys(reftransitiondict(net))

npages(net::PnmlNet)          = length(pagedict(net))
nplaces(net::PnmlNet)         = length(placedict(net))
ntransitions(net::PnmlNet)    = length(transitiondict(net))
narcs(net::PnmlNet)           = length(arcdict(net))
nrefplaces(net::PnmlNet)      = length(refplacedict(net))
nreftransitions(net::PnmlNet) = length(reftransitiondict(net))
ndeclarations(net::PnmlNet)   = length(decldict(net))

"""
    allpages(net::PnmlNet|dict::OrderedDict) -> Iterator

Return iterator over all pages in the net. Maintains insertion order.
"""
allpages(net::PnmlNet) = allpages(pagedict(net))
allpages(pd::OrderedDict) = values(pd)

"Iterator of `Pages` directly owned by `net`."
pages(net::PnmlNet) = Iterators.filter(pg -> in(pid(pg), page_idset(net)), allpages(net))

"Usually the only interesting page."
firstpage(net::PnmlNet) = first(values(pagedict(net)))

has_tools(net::PnmlNet) = !isnothing(net.toolspecinfos)
has_place(net::PnmlNet, id::Symbol)    = haskey(placedict(net), id)
has_transition(net::PnmlNet, id::Symbol)  = haskey(transitiondict(net), id)
has_arc(net::PnmlNet, id::Symbol)  = haskey(arcdict(net), id)
has_refplace(net::PnmlNet, id::Symbol)      = haskey(refplacedict(net), id)
has_reftransition(net::PnmlNet, id::Symbol) = haskey(reftransitiondict(net), id)

toolinfos(net::PnmlNet) = net.toolspecinfos

places(net::PnmlNet)         = values(placedict(net))
transitions(net::PnmlNet)    = values(transitiondict(net))
arcs(net::PnmlNet)           = values(arcdict(net))
refplaces(net::PnmlNet)      = values(refplacedict(net))
reftransitions(net::PnmlNet) = values(reftransitiondict(net))

place(net::PnmlNet, id::Symbol)         = placedict(net)[id]
transition(net::PnmlNet, id::Symbol)    = transitiondict(net)[id]
arc(net::PnmlNet, id::Symbol)           = arcdict(net)[id]
refplace(net::PnmlNet, id::Symbol)      = refplacedict(net)[id]
reftransition(net::PnmlNet, id::Symbol) = reftransitiondict(net)[id]
"""
Return `Arc` from 'src' to 'tgt' or `nothing`.
Useful for graphs where arcs are represented by a tuple or pair (source,target).
"""
function arc(net, src::Symbol, tgt::Symbol, dict=arcs)
    x = Iterators.filter(a -> source(a) === src && target(a) === tgt, dict(net))
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
inhibitor(net::PnmlNet, arc_id::Symbol) = inscription(inhibit_arcdict(net)[arc_id])
reader(net::PnmlNet, arc_id::Symbol) = inscription(read_arcdict(net)[arc_id])
condition(net::PnmlNet, trans_id::Symbol) = condition(transition(net, trans_id))

#------------------------------------------------------------------------------
# DeclDict access
#------------------------------------------------------------------------------
useroperators(net::AbstractPnmlNet)  = useroperators(decldict(net))
variabledecls(net::AbstractPnmlNet)  = variabledecls(decldict(net))
namedsorts(net::AbstractPnmlNet)     = namedsorts(decldict(net))
arbitrarysorts(net::AbstractPnmlNet) = arbitrarysorts(decldict(net))
partitionsorts(net::AbstractPnmlNet) = partitionsorts(decldict(net))
namedoperators(net::AbstractPnmlNet) = namedoperators(decldict(net))
arbitraryops(net::AbstractPnmlNet)   = arbitraryops(decldict(net))
partitionops(net::AbstractPnmlNet)   = partitionops(decldict(net))
feconstants(net::AbstractPnmlNet)    = feconstants(decldict(net))
multisetsorts(net::AbstractPnmlNet)  = multisetsorts(decldict(net))
productsorts(net::AbstractPnmlNet)   = productsorts(decldict(net))

variabledecl(net::AbstractPnmlNet, id::Symbol)  = variabledecls(net)[id]
namedsort(net::AbstractPnmlNet, id::Symbol)     = namedsorts(net)[id]
arbitrarysort(net::AbstractPnmlNet, id::Symbol) = arbitrarysorts(net)[id]
partitionsort(net::AbstractPnmlNet, id::Symbol) = partitionsorts(net)[id]
multisetsort(net::AbstractPnmlNet, id::Symbol)  = multisetsorts(net)[id]
productsort(net::AbstractPnmlNet, id::Symbol)   = productsorts(net)[id]
namedop(net::AbstractPnmlNet, id::Symbol)       = namedoperators(net)[id]
arbitraryop(net::AbstractPnmlNet, id::Symbol)   = arbitraryops(net)[id]
partitionop(net::AbstractPnmlNet, id::Symbol)   = partitionops(net)[id]
feconstant(net::AbstractPnmlNet, id::Symbol)    = feconstants(net)[id]
useroperator(net::AbstractPnmlNet, id::Symbol)  = useroperators(net)[id]

#useroperator(net::AbstractPnmlNet)  = useroperator(decldict(net))
#variabledecl(net::AbstractPnmlNet)  = variabledecl(decldict(net))
namedsort(net::AbstractPnmlNet, ref::SortRef)     = namedsort(net, refid(ref))
arbitrarysort(net::AbstractPnmlNet, ref::SortRef) = arbitrarysort(net, refid(ref))
partitionsort(net::AbstractPnmlNet, ref::SortRef) = partitionsort(net, refid(ref))
#namedoperator(net::AbstractPnmlNet) = namedoperator(decldict(net))
#arbitraryop(net::AbstractPnmlNet)   = arbitraryoperator(decldict(net))
#partitionop(net::AbstractPnmlNet)   = partitionop(decldict(net))
feconstant(net::AbstractPnmlNet, ref::SortRef)    = feconstant(net, refid(ref))
multisetsort(net::AbstractPnmlNet, ref::SortRef)  = multisetsort(net, refid(ref))
productsort(net::AbstractPnmlNet, ref::SortRef)   = productsort(net, refid(ref))

"Lookup operator with `id` in DeclDict.::Symbol May be namedop, feconstant, etc"
operator(net::AbstractPnmlNet, id::Symbol) = operator(decldict(net), id)
"""
    operators(net::AbstractPnmlNet)-> Iterator
Iterate over each operator in the operator subset of declaration dictionaries .
"""
operators(net::AbstractPnmlNet) = operators(decldict(net))

has_operator(net::AbstractPnmlNet, id::Symbol) = has_operator(decldict(net), id)

"""
    has_key(net::AbstractPnmlnet, dict, key::Symbol) -> Bool
Where `dict` is the access method for a dictionary in `DeclDict`.
"""
has_key(net::AbstractPnmlNet, dict, key::Symbol) = haskey(dict(decldict(net)), key)

has_variabledecl(net::AbstractPnmlNet, id::Symbol)   = has_key(net, variabledecls, id)
has_namedsort(net::AbstractPnmlNet, id::Symbol)      = has_key(net, namedsorts, id)
has_arbitrarysort(net::AbstractPnmlNet, id::Symbol)  = has_key(net, arbitrarysorts, id)
has_partitionsort(net::AbstractPnmlNet, id::Symbol)  = has_key(net, partitionsorts, id)
has_multisetsort(net::AbstractPnmlNet, id::Symbol)   = has_key(net, multisetsorts, id)
has_productsort(net::AbstractPnmlNet, id::Symbol)    = has_key(net, productsorts, id)
has_namedop(net::AbstractPnmlNet, id::Symbol)        = has_key(net, namedoperators, id)
has_arbitraryop(net::AbstractPnmlNet, id::Symbol)    = has_key(net, arbitraryops, id)
has_partitionop(net::AbstractPnmlNet, id::Symbol)    = has_key(net, partitionops, id)
has_feconstant(net::AbstractPnmlNet, id::Symbol)     = has_key(net, feconstants, id)
has_useroperator(net::AbstractPnmlNet, id::Symbol)   = has_key(net, useroperators, id)

has_variabledecl(net::AbstractPnmlNet, ref::SortRef)  = has_key(net, variabledecls, refid(ref))
has_namedsort(net::AbstractPnmlNet, ref::SortRef)     = has_key(net, namedsorts, refid(ref))
has_arbitrarysort(net::AbstractPnmlNet, ref::SortRef) = has_key(net, arbitrarysorts, refid(ref))
has_partitionsort(net::AbstractPnmlNet, ref::SortRef) = has_key(net, partitionsorts, refid(ref))
has_multisetsort(net::AbstractPnmlNet, ref::SortRef)  = has_key(net, multisetsorts, refid(ref))
has_productsort(net::AbstractPnmlNet, ref::SortRef)   = has_key(net, productsorts,refid(ref) )
has_namedop(net::AbstractPnmlNet, ref::SortRef)       = has_key(net, namedoperators, refid(ref))
has_arbitraryop(net::AbstractPnmlNet, ref::SortRef)   = has_key(net, arbitraryops, refid(ref))
has_partitionop(net::AbstractPnmlNet, ref::SortRef)   = has_key(net, partitionops, refid(ref))
has_feconstant(net::AbstractPnmlNet, ref::SortRef)    = has_key(net, feconstants, refid(ref))
has_useroperator(net::AbstractPnmlNet, ref::SortRef)  = has_key(net, useroperators, refid(ref))


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
    # foreach(x -> verify!(errors, x, verbose, net), extralabels(net))

    if npages(net) == 1
        @assert npages(net) == length(page_idset(net))
        nrefplaces(net) == 0 ||
            push!(errors, "npages==1 && refplacedict not empty")
        isempty(refplace_idset(net)) ||
            push!(errors, "npages==1 && refplace_idset not empty")
        nreftransitions(net) == 0 ||
            push!(errors, "npages==1 && reftransitiondict not empty")
        isempty(reftransition_idset(net)) ||
            push!(errors, "npages==1 && reftransition_idset not empty")
    end
    return errors
end

"""
    verify_ids!(errors, str, iterable, net::AbstractPnmlNet) -> Vector{String}

Iterate over `iterable` testing that `pid` is registered in `net`.
`str` used in message appended to `errors` vector of strings.
"""
function verify_ids!(errors, str::AbstractString, iterable, net::AbstractPnmlNet)
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
            " type ", nettype(net), ", ",
            npages(net), " pages, ",
            ndeclarations(net), " declarations, ",
            has_tools(net) ? length(toolinfos(net)) : 0, " toolinfos, ")::String
end

# No indent here.
function Base.show(io::IO, net::PnmlNet)
    print(io, indent(io), nameof(typeof(net)), "(", )
    print(repr(pid(net)), ", ")
    print(repr(name(net)), ", ")
    print(repr(nettype(net)), ", ")
    iio = inc_indent(io)
    println(io)

    print(io, "Pages = ", repr(page_idset(net)))
    for page in values(pagedict(net))
        print(iio, '\n', indent(iio)); show(iio, page)
    end
    println(io)
    println(io, "Declarations = ", repr(decldict(net)))
    show(io, toolinfos(net)); println(io, ", ")
    show(io, extralabels(net)); println(io, ", ")
    show(io, nettype(net)); println(io, ")")

    println(io, "Arcs:")
    map(arcs(net)) do a
        show(io, a); println(io)
    end
    println(io, "Places:")
    map(places(net)) do p
        show(io, p); println(io)
    end
    println(io, "Transitions:")
    map(transitions(net)) do t
        show(io, t); println(io)
    end

    println(io, "Reference Places:")
    map(refplaces(net)) do rp
        show(io, rp); println(io)
    end

    println(io, "Reference Transitions:")
    map(reftransitions(net)) do rt
        show(io, rt); println(io)
    end
end

show_sorts(net::AbstractPnmlNet) = show_sorts(decldict(net))
