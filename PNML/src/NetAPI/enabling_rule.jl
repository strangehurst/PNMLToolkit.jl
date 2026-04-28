# Enabling Rule

"""
    accum_var_binding_sets!(tr_binding_sets, arc_binding_sets) -> Bool

Collect variable bindings, intersecting among arc's sets.
Return enabled status of false if any variable does not have a substitution.
"""
function accum_var_binding_sets!(tr_binding_sets::OrderedDict,
                                 arc_binding_sets::OrderedDict)
    for v in keys(arc_binding_sets)
        #accum_binding_set!(tr_var_binding_sets, arc_var_binding_sets, v)
        @assert !isempty(arc_binding_sets[v])
        if !haskey(tr_binding_sets, v)
            tr_binding_sets[v] = arc_binding_sets[v] # Initial value from 1st use.
        else
            @assert eltype(tr_binding_sets[v]) == eltype(arc_binding_sets[v])
            intersect!(tr_binding_sets[v], arc_binding_sets[v])
        end
        isempty(tr_binding_sets[v]) && return false
    end
    # Transition enabled when all(s->cardinality(s) > 0, values(tr_var_binding_sets)).
    all(!isempty, values(tr_binding_sets))
end

"""
    unwrap_pmset(mark) -> Multiset

If marking wraps a PnmlMultiset, extract a singleton.
"""
function unwrap_pmset(mark)
    if mark isa PnmlMultiset
        # That contains PnmlMultisets
        if eltype(mark) <: PnmlMultiset
            single = only(multiset(mark))
            eltype(single) <: PnmlMultiset &&
                error("recursive PnmlMultisets not allowed here")
            return single # Replace mark with the wrapped PnmlMultiset
        end
    end
    return mark
end

"""
    labeled_places(net::PnmlNet, marking_vector)

Return Vector of place_id=>marking_value of that pace.
"""
function labeled_places(net::PnmlNet, markings)
    [k=>v for (k,v) in zip(map(pid, places(net)), markings)]
end


"""
    enabled(::PnmlNet, marking) -> Vector{Bool}

Return vector of booleans where `true` means the matching transition
is enabled at current `marking`. Has the same order as the `transitions` dictionary.
Used in the firing rule.

Update tr.vars Set and tr.varsubs, NamedTuple.
"""
function enabled end

function enabled(net::AbstractPnmlNet, marking)
    # Start by assuming all transitions are enabled.
    # dictionary with key of transaction id, value of enabled state boolean
    enabled_dict = OrderedDict{Symbol, Bool}(id=>true for (id,_) in pairs(transitiondict(net)))

    # dictionary with key of place id, value of its marking value (from marking vector)
    mark_dict = OrderedDict{Symbol, value_type(Marking, net)}(labeled_places(net, marking))

   for tr in transitions(net)
        transition_id = pid(tr)
        empty!(tr.varsubs) #~ clear cached NamedTuple[]
        enabled_dict[transition_id] || continue
        #TODO other filters reducing work done by token_load! Cannot use variables.

        # Build tr.varsubs while accessing token sufficency part of enabling rule.
        enabled = sufficient_tokens!(mark_dict, net, transition_id, tr.vars, tr.varsubs)
        enabled_dict[transition_id] &= enabled
        enabled_dict[transition_id] || continue

        # transition_guard evaluated as part of sufficient_tokens!

        foreach(filters(net)) do f
            # @show typeof(f) f
            # filters modifying e_dict, may use variables
            f(enabled_dict, mark_dict, net, transition_id)
        end
    end
    return collect(values(enabled_dict))
end

"""
    sufficient_tokens!(mark_dict, net::AbstractPnmlNet, transition_id, vars, varsubs)

Return enabled state of transition by testing that all its input places have enough tokens
and trasnsition guard is true.
"""
function sufficient_tokens! end

function sufficient_tokens!(mark_dict::AbstractDict, net::AbstractPnmlNet,
                            transition_id, _vars, _varsubs)
    # There are no varibles possible here and the guard is `true`.
    # Evaluate preset inscription expressions, compare to mark value.
    all(mark_dict[place_id] >= inscription(arc(net, place_id, transition_id))()
                                         for place_id in preset(net, transition_id))
end

function sufficient_tokens!(mark_dict::AbstractDict, net::PnmlNet{T},
                            transition_id, vars, varsubs) where (T <: AbstractHLCore)
    # During enabling rule, tr_var_binding_set maps variable to a set of elements.
    tr_var_binding_set = OrderedDict{REFID, Any}()
    #~ marking = PnmlMultiset{B, T}(Multiset(T() => 1)) singleton
    # varsub maps a variable to 1 element value of multiset(marking[transition_id])
    # when enabling/firing transition.
    # Multiset type set from first use

    # Get transition variable substitution from preset arcs.
    # Update tr.vars, tr_var_binding_set.
    get_variable_substitutions!(tr_var_binding_set, net, transition_id,
                                vars, mark_dict) || return false # no substution found
    #^--------------------------------------------------------------------------------
    #& XXX variable substitutions fully specified by preset of transition XXX
    #& tr.vars is complete. tr_var_binding_set has valid substitutions for all variables.
    #^--------------------------------------------------------------------------------

    # Return enabled status based on comparing mark and inscription.
    # Update tr.varsubs, a vector of possible substitutions.
    comp_mark_inscription(net, mark_dict, transition_id,
                            term(condition(transition(net, transition_id))),
                            tr_var_binding_set, vars, varsubs)
    #! REMEMBER marking multiset element may be a PnmlMultiset.
end

"""
Evaluate preset inscription expressions, compare to mark value.
Update varsubs
"""
function comp_mark_inscription(net::APN, mark_dict, transition_id, cond_term,
                                tr_var_binding_set, vars, varsubs)
    enabled = true
    for place_id in preset(net, transition_id)
        ar = arc(net, place_id, transition_id)
        mark = mark_dict[place_id]

        if isempty(vars) # 0-ary operators or constants
            # This includes the non-HL net types that do not have variables.
            eval(toexpr(cond_term, NamedTuple(), net)) || return false  #! XXX CACHE eval
            inscription_val = _cvt_inscription_value(pntd(net), ar,
                                        zero_marking(place(net, place_id)), NamedTuple())
            mark >= inscription_val || return false
        else
            # Use the transition-level variable substitution binding map `tr_var_binding_set`.
            # Iterate over the cartesian product to produce a list of candidate firings.
            # A candidate firing is a NamedTuple variable_id => marking_value of substitutions.
            vids = tuple(keys(tr_var_binding_set)...) # Tuple of variable ids
            vtup = tuple(values(tr_var_binding_set)...) # Tuple of Multisets{PnmlMultiset}
            sub1 = tuple((keys.(vtup))...) # Tuple of iterators
            vsubiter = Iterators.product(sub1...)
            for candidate_params in vsubiter
                # Assume order of tr_var_binding_set and product are the same.
                vsub = namedtuple(vids, candidate_params)
                # condition expression may contain variables.
                eval(toexpr(cond_term, vsub, net)) || continue #! XXX CACHE eval
                inscription_val = _cvt_inscription_value(pntd(net), ar,
                                    zero_marking(place(net, place_id)), vsub)
                mark = unwrap_pmset(mark)
                issubset(inscription_val, mark) || continue # not a valid substitution
                push!(varsubs, vsub)
            end
            isempty(varsubs) && return false # no sunstitution found
        end
    end
    return true
end

"""
    get_variable_substitutions!(binding_sets, net::APN, transition_id, tr_vars, mark_dict)
# Arguments
 - binding_sets map from variable id to set of substitution values
 - net contains
 - transition_id
 - tr_vars variable ids of transition
 - mark_dict

Return enabled state, update `tr_vars`  and `binding_sets`.
"""
function get_variable_substitutions!(binding_sets, net::APN, transition_id, tr_vars, mark_dict)
    for place_id in preset(net, transition_id)
        ar = arc(net, place_id, transition_id)
        isnothing(ar) && error("did not find arc: $place_id -> $transition_id")
        mark = unwrap_pmset(mark_dict[place_id])
        arc_vars = Multiset(variables(PNML.inscription(ar))...) # Count variables.
        isempty(arc_vars) || union!(tr_vars, keys(arc_vars)) # Cache variable ids.

        place_sort = sortref(place(net, place_id))
        enabled, arc_binding_sets = get_arc_var_binding_sets!(arc_vars, place_sort, mark, net)
        enabled || return false # transition not enabled
        accum_var_binding_sets!(binding_sets, arc_binding_sets) || return false
    end # preset arcs
    #TODO sanity check substitutions.
    return true # enabled, binding_sets is valid
end


"""
    get_arc_var_binding_setss!(arc_var_binding_set, arc_vars, placesort, mark, net) -> Bool

Fill `arc_var_binding_set` with an entry for each key in `arc_vars`.
Return `true` if no variables are present or all variables have at least 1 substition.
Indicates that transition is able to fire (enabled fro selection to fire).
"""
function get_arc_var_binding_sets!(arc_vars::Multiset, placesort::SortRef, mark, net::APN)
    arc_binding_sets = OrderedDict{Symbol, Multiset{Symbol}}()
    for v in keys(arc_vars)
        # Each variable must have a non-empty substitution.
        #! variable sorts are never ProductSort. Just one sort.
        # Start with empty substution set for variable.
        # Use multiset as a counter.
        arc_binding_sets[v] = Multiset{Symbol}()
        v_decl = variabledecl(net, v)
        v_sortref = sortref(v_decl)
        v_refid = refid(v_sortref)

        # Verify variable sort matches placesort.
        if is_productsort(placesort)
            any(==(v_refid), Sorts.sorts(placesort, net)) ||
                    error("none of product sorts are '$v_refid': ", repr(placesort))
        else
            placesort !== v_sortref &&
                error("not equal sorts ($placesort, $v_sortref)")
        end

        # Examine mark
        for (element, multiplicity) in pairs(multiset(mark))
            @show typeof(element)
            #! arc_binding_set counts possible substitutions in source place's marking.
            # Multiple of same variable in arc inscription expression
            # means arc_binding_set only includes values of mark elements with
            # multiplicity at least as that large.
            if multiplicity >= arc_vars[v]
                # Variable multiplicity is per-arc, value is shared among arcs.
                if element isa Tuple # mark is a ProductSort.
                    # Select the tuple member(s) matching variable sort.
                    for expr in element
                        if refid(expr) === v_refid
                            push!(arc_binding_sets[v], expr())
                        else
                            @warn "refid(expr) !== v_refid"
                        end
                    end
                else #! element may be a PnmlMultiset
                    push!(arc_binding_sets[v], element())
                end
            end
        end

        if !isempty(arc_vars) && isempty(arc_binding_sets[v])
            return false, arc_binding_sets # A variable has no substitution.
        end
    end
    return true, arc_binding_sets # No variables or all of them have at least 1 substution.
end
