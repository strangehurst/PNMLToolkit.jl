# Flatten the pages of a Petri Net Markup Language
# TODO Check for illegal intra-page references? WHERE?

"""
    flatten_pages!(net::AbstractPnmlNet[; options])

Merge page content into the 1st page of the net.

Options
  - trim::Bool Remove refrence nodes (default `true`). See [`deref!`](@ref).
  - verbose::Bool Print breadcrumbs See [`CONFIG`](@ref).
"""
function flatten_pages! end

# Most content is already in the net database so mostly involves shuffling keys
function flatten_pages!(net::AbstractPnmlNet; trim::Bool = true, verbose::Bool = CONFIG.verbose)
    if length(pagedict(net)) > 1 # Place content of other pages into 1st page.
        pageids = keys(pagedict(net))

        # Choose the surviving page from those owned directly by net.
        key1,val1 = popfirst!(pagedict(net))
        @assert key1 ∉ pageids # Note the coupling of pageids and net.pagedict.
        while !isempty(pagedict(net))
            cutid, cutpage = popfirst!(pagedict(net))
            @assert cutid ∉ pageids
            append_page!(val1, cutpage; verbose)
        end
        @assert isempty(pagedict(net))
        empty!(net.page_idset)  # Remove from set of page ids owned by net.
        # Put the one-true-page back in the dictionary.
        push!(net.page_idset, key1)
        pagedict(net)[key1] = val1
        @assert length(page_idset(net)) == 1
        @assert length(pagedict(net)) == 1
        @assert key1 ∈ page_idset(net) # We never removed the one-true key.
        @assert key1 ∈ pageids # Note the coupling of pageids and net.pagedict.
        # Collapse refplace and reftransition
        deref!(net; trim, verbose)
    end
    return net
end

"Verify a `PnmlNet` after it has been flattened or is otherwise expected to be a single-page net."
function post_flatten_verify(net::AbstractPnmlNet, verbose::Bool = CONFIG.verbose)
    verbose && @info "post_flatten_verify"
    errors = String[]

    npages(net) == 1 ||
        push!(errors, "wrong pagedict length: expected 1 found $(npages(net)))")
    @assert npages(net) == length(page_idset(net))

    nrefplaces(net) == 0 || push!(errors, "refplacedict not empty")
    isempty(refplacedict(net)) || push!(errors, "refplacedict not empty")
    isempty(refplace_idset(firstpage(net))) || push!(errors, "refplace_idset(fistpage) not empty")

    nreftransitions(net) == 0 || push!(errors, "reftransitiondict not empty")
    isempty(reftransitiondict(net)) || push!(errors, "reftransitiondict not empty")
    isempty(reftransition_idset(firstpage(net))) || push!(errors, "reftransition_idset(fistpage) not empty")

    isempty(errors) ||
        error("net $(pid(net)) post flatten errors: ", join(errors, ",\n "))
    return nothing
end

"""
Append selected fields of `r` to fields of `l`.
Some, like Names and xml, are omitted because they are scalar values, not collections.

Per-net data is not modified here.
The idsets hold pnml IDs of per-net data "owned" by some page.
"""
function append_page!(lpage::Page, rpage::Page;
            keys = (:toolspecinfos,), # non-idset and non-dict fields of page to merge
            idsets = (place_idset, transition_idset, arc_idset,# except for page_idset
                      refplace_idset, reftransition_idset,),
            verbose::Bool = CONFIG.verbose)
    verbose && println("## append_page!($(pid(lpage)), $(pid(rpage))")
    for k in keys
        _update_maybe!(lpage, rpage, k)
    end

    for (k,v) in pairs(rpage.extralabels)
        if !haskey(lpage.extralabels, k) # do not overwrite
            lpage.extralabels[k] = v
        end
    end
    #
    for s in idsets
        union!(s(lpage), s(rpage))
    end

    delete!(page_idset(lpage), pid(rpage))
    @assert pid(rpage) ∉ page_idset(lpage)
    #~ ensure empty page garbage collected?

    return lpage
end

# Property/Field `key` is to be set or appended.
# Used to merge pages.
# Scalar fields should not be overwritten to preserve first page identity, name.
# Also means that the graphics, gui data is not merged (how would it work?), but one of
# the merged page's field could replace an optional field of the first page.
# Implemented by testing lhs.key for nothing. This works because anything else is assumed
# to be appendable.
function _update_maybe!(l, r, key::Symbol) # pass a type for assertion
    rval = getproperty(r, key)::Maybe{AbstractVector}
    isnothing(rval) && return
    lval = getproperty(l, key)::Maybe{AbstractVector}
    if isnothing(lval)
        setproperty!(l, key, rval)
    else
        @outline(lval, rval, @info "append! " lval rval) #!debug
        append!(lval, rval)
    end
end

"""
$(TYPEDSIGNATURES)

Collapse reference node chains into a single arc.

Expects that the [`PnmlNetKeys`](@ref) of the firstpage will have to be cleaned
as part of [`flatten_pages!`](@ref),

# Axioms
  1) All ids in a network are unique in that they only have one instance in the XML.
  2) A chain of reference Places (or Transitions) always ends at a Place (or Transition).
  3) All ids are valid.
  4) No cycles.
"""
function deref!(net::AbstractPnmlNet; trim::Bool = true, verbose::Bool = CONFIG.verbose)
    if isempty(refplacedict(net)) && isempty(reftransitiondict(net))
        verbose && println("no references")
        return nothing
    end
    isempty(arcdict(net)) && error("no arcs")

    for (_,arc::Arc) in arcdict(net)
        while arc.source[] ∈ refplace_ids(net)
            arc.source[] = deref_place(net, arc.source[]; trim)
        end
        while arc.target[] ∈ refplace_ids(net)
            arc.target[] = deref_place(net, arc.target[]; trim)
        end
        while arc.source[] ∈ reftransition_ids(net)
            arc.source[] = deref_transition(net, arc.source[]; trim)
        end
        while arc.target[] ∈ reftransition_ids(net)
            arc.target[] = deref_transition(net, arc.target[]; trim)
        end
    end
    if trim
        # Remove any reference node idsets from the only remaining page after flattening.
        empty!(refplace_idset(firstpage(net)))
        empty!(reftransition_idset(firstpage(net)))
        # And the nodes themselves.
        empty!(refplacedict(net))
        empty!(reftransitiondict(net))
    end
    return nothing # net
end

"""
    deref_place(net, id[], trim::Bool]) -> Symbol

Return id of referenced place. If trim is `true` (default) the reference is removed.
"""
function deref_place(net::AbstractPnmlNet, id::Symbol; trim::Bool = true)
    netid = pid(net)
    has_refplace(net, id) ||
        throw(ArgumentError("expected refplace $id to be found in net $netid"))

    rid = refid_of(refplace(net, id))
    isnothing(rid) && # Something is really, really wrong.
        throw(ArgumentError("failed to lookup reference place id $id in net $netid)"))
    has_place(net, rid) || has_refplace(net, rid) ||
        throw(ArgumentError("$(rid) is not a place or reference place"))

    if trim
        delete!(refplacedict(net), id)
        has_refplace(net, id) &&
            error("did not expect refplace $id in net $netid after delete")
    end
    return rid
end

"""
    deref_transition(net, id[, trim::Bool] ) -> Symbol

Return id of referenced transition. If trim is `true` (default) the reference is removed.
"""
function deref_transition(net::AbstractPnmlNet, id::Symbol; trim::Bool = true)
    netid = pid(net)
    has_reftransition(net, id) || (throw ∘ ArgumentError)("expected reftransition $id in net $netid")
    rt = reftransition(net, id)
    isnothing(rt) && # Something is really, really wrong.
        throw(ArgumentError("failed to lookup reference transition id $id in net $netid"))
    has_transition(net, refid_of(rt)) || has_reftransition(net, refid_of(rt)) ||
        throw(ArgumentError("$(refid_of(rt)) is not a transition or reference transition in net $netid"))
    if trim
        delete!(reftransitiondict(net), id)
        has_reftransition(net, id) &&
            error("did not expect reftransition $id in net $netid after delete")
    end
    return refid_of(rt)
end
