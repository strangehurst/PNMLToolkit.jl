# Enabling Rule
"Debug print switch for enabline rule."
ER() = false

"""
    accum_var_binding_sets!(tr_binding_sets, arc_binding_sets) -> Bool

Collect variable bindings, intersecting among arc's sets.
Return enabled status of false if any variable does not have a substitution.
"""
function accum_var_binding_sets!(tr_binding_sets::OrderedDict,
                                 arc_binding_sets::OrderedDict)
    ER()&& println("#-- accum_var_binding_sets!")
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
    if mark isa PnmlMultiset && eltype(mark) <: PnmlMultiset
        single = only(multiset(mark))
        eltype(single) <: PnmlMultiset &&
            error("recursive PnmlMultisets not allowed here")
        return single # Replace mark with the wrapped PnmlMultiset's only element.
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

Update net's vars and varsubs for each transition.

$(METHODLIST)
"""
function enabled end

function enabled(net::AbstractPnmlNet, marking)
    ER()&& println("#-- enabled $(pid(net)) ", marking)
    # Start by assuming all transitions are enabled.
    # dictionary with key of transaction id, value of enabled state boolean
    enabled_dict = OrderedDict{Symbol, Bool}(id=>true for (id,_) in pairs(transitiondict(net)))

    # dictionary with key of place id, value of its marking value (from marking vector)
    mark_dict = OrderedDict{Symbol, value_type(Marking, net)}(labeled_places(net, marking))

   for tr in transitions(net)
        transition_id = pid(tr)
        #~ clear any cached NamedTuple[]
        haskey(net.varsubs, transition_id) && empty!(net.varsubs[transition_id])

        #TODO other filters reducing work done by token_load! Cannot use variables.

        # Build varsubs while accessing token sufficency part of enabling rule.
        enabled_dict[transition_id] &= sufficient_tokens!(mark_dict, net, transition_id)
        enabled_dict[transition_id] || continue

        # transition_guard evaluated as part of sufficient_tokens!

        for f in filters(net)
            # filters may use variables (aka mark_dict values)
            enabled_dict[transition_id] &= f(net, transition_id, mark_dict)
            enabled_dict[transition_id] || break # next tr
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

function sufficient_tokens!(mark_dict::AbstractDict, net::AbstractPnmlNet, transition_id)
    ER()&& print("#-- sufficient_tokens! ",
                     "$(pntd_of(net)) $(pid(net)) $transition_id = ")
    # There are no varibles possible here and the guard is `true`.
    # Evaluate preset inscription expressions, compare to mark value.
    s = all(skipmissing(mark_dict[place_id] >= inscription(arc(net, place_id, transition_id))()
                                         for place_id in preset(net, transition_id)))
    s = coalesce(s, false)
    ER()&& println(s)
    return s
end

function sufficient_tokens!(mark_dict::AbstractDict, net::PnmlNet{PT_HLPNG}, transition_id)
    ER()&& print("#-- sufficient_tokens! ",
                     "$(pntd_of(net)) $(pid(net)) $transition_id = ")
    # There are no varibles possible here and the guard is `true`.
    # Evaluate preset inscription expressions, compare to mark value.
    s = all(skipmissing(mark_dict[place_id] >= inscription(arc(net, place_id, transition_id))()
                                         for place_id in preset(net, transition_id)))
    s = coalesce(s, false)
    ER()&& println(s)
    return s
end

function sufficient_tokens!(mark_dict::AbstractDict,
                            net::PnmlNet{T}, transition_id) where (T <: AbstractHLCore)
    ER()&& println("#-- sufficient_tokens! ",
                    "$(pntd_of(net)) $(pid(net)) $transition_id")
    tr_vars = haskey(net.vars, transition_id) ? net.vars[transition_id] : Set{Symbol}()
    tr_varsubs = haskey(net.varsubs, transition_id) ? net.varsubs[transition_id] : Vector{NamedTuple}()
    s = sufficient_tokens2!(mark_dict, net,  transition_id,
                            tr_vars, tr_varsubs)
    return coalesce(s, false)
end

function sufficient_tokens2!(mark_dict::AbstractDict, net::PnmlNet{T}, transition_id,
                            tr_vars::Set{Symbol},
                            tr_varsubs::Vector{NamedTuple}) where (T <: AbstractHLCore)
    # During enabling rule, tr_var_binding_set maps variable to a set of elements.
    tr_var_binding_set = OrderedDict{REFID, Any}()
    #~ marking = PnmlMultiset{B, T}(Multiset(T() => 1)) singleton
    # varsub maps a variable to 1 element value of multiset(marking[transition_id])
    # when enabling/firing transition.
    # Multiset type set from first use

    # Get transition variable substitution from preset arcs.
    # Update vars.
    if !get_variable_substitutions!(tr_var_binding_set, net, transition_id,
                                tr_vars, mark_dict)
        ER() && println("#-- sufficient_tokens2! $(pntd_of(net))",
                " $(pid(net))",
                " $transition_id = false")
       return false # no substution found
    end
    #^--------------------------------------------------------------------------------
    #& XXX variable substitutions fully specified by preset of transition XXX
    #& tr.vars is complete. tr_var_binding_set has valid substitutions for all variables.
    #^--------------------------------------------------------------------------------

    # Return enabled status based on comparing mark and inscription.
    # Update varsubs, a vector of possible substitutions.
    r = comp_mark_inscription(net, mark_dict, transition_id,
                              term(condition(transition(net, transition_id))),
                              tr_var_binding_set, tr_vars, tr_varsubs)
    #! REMEMBER marking multiset element may be a tuple.
    ER()&& println("#-- sufficient_tokens2! $(pntd_of(net))",
                " $(pid(net))",
                " $transition_id) = $r")
    return r
end

"""
    comp_mark_inscription(net, mark_dict, transition_id, cond_term,
                          tr_var_binding_set, tr_vars, tr_varsubs)-> Bool

Evaluate transition's preset inscription expressions, compare to mark value.
Update varsubs with feasible variable substitution named tuples.

The firing rule will select from one transition's feasible substutions in its varsubs.
"""
function comp_mark_inscription end
# function comp_mark_inscription(net::PnmlNet{T}, mark_dict, transition_id, cond_term,
#                                 tr_var_binding_set, tr_vars, tr_varsubs) where {T <: AbstractHLCore}
#     for place_id in preset(net, transition_id)
#         mark = mark_dict[place_id]
#         z = zero_marking(place(net, place_idcomp_mark_inscription))
#         __compare_mi_impl(net, mark, cond_term, place_id, transition_id,
#                                 tr_var_binding_set, tr_vars, tr_varsubs, z) || return false
#     end
#     return true # transition is enabled
# end
# function comp_mark_inscription(net::PnmlNet{PT_HLPNG}, mark_dict, transition_id, cond_term,
#                                 tr_var_binding_set, tr_vars, tr_varsubs)
#     for place_id in preset(net, transition_id)
#         mark = mark_dict[place_id]
#         z = zero_marking(place(net, place_id))
#         __compare_mi_impl(net, mark, cond_term, place_id, transition_id,
#                                 tr_var_binding_set, tr_vars, tr_varsubs, z) || return false
#     end
#     return true # transition is enabled
# end
function comp_mark_inscription(net::PnmlNet{T}, mark_dict::AbstractDict, transition_id, cond_term,
                                tr_var_binding_set, tr_vars, tr_varsubs) where {T <: AbstractPNTD}
    ER()&& println("#-- comp_mark_inscription! ",
                    "$(pntd_of(net)) $(pid(net)) ", transition_id)
    for place_id in preset(net, transition_id)
        mark = mark_dict[place_id]
        z = zero_marking(place(net, place_id))
        if !__compare_mi_impl(net, mark, cond_term,
                               place_id, transition_id,
                               tr_var_binding_set, tr_vars, tr_varsubs, z)
            return false
        end
    end
    return true # transition is enabled
end

# Assume no variables
function __compare_mi_impl(net::PnmlNet{T}, mark, cond_term, place_id, transition_id,
                           _, _, _, z) where {T <: AbstractPNTD}
    eval(toexpr(cond_term, NamedTuple(), net)) || return false  #! XXX CACHE eval
    inscription_val = inscription_value(net, place_id, transition_id,z, NamedTuple()) # Number
    return mark >= inscription_val
 end

# Variables supported for High-level nets    s = comp_mark_inscription(net, mark_dict, transition_id,
function __compare_mi_impl(net::PnmlNet{T}, mark, cond_term, place_id, transition_id,
                           tr_var_binding_set, tr_vars, tr_varsubs, z) where {T <: AbstractHLCore}
    if isempty(tr_vars) # 0-ary operators or constants
        # PT_HLPNG will have no vars
        eval(toexpr(cond_term, NamedTuple(), net)) || return false  #! XXX CACHE eval
        inscription_val = inscription_value(net, place_id, transition_id, z, NamedTuple()) # convert bag{dot} to Int
        mark = unwrap_pmset(mark)
        return issubset(inscription_val, mark)
   else
        # Use the transition-level variable substitution binding map `tr_var_binding_set`.
        # Iterate over the cartesian product to produce a list of candidate firings.
        # A candidate firing is a NamedTuple variable_id => marking_value of substitutions.
        vids = tuple(keys(tr_var_binding_set)...) # Tuple of variable ids
        vtup = tuple(values(tr_var_binding_set)...) # Tuple of Multisets{PnmlMultiset}
        sub1 = tuple((keys.(vtup))...) # Tuple of iteratorsero_marking(place(net, place_id))
        for candidate_params in Iterators.product(sub1...)
            # Assume order of tr_var_binding_set and product are the same.
            # Mke named tuple where names are variable ids.
            tr_vsub = namedtuple(vids, candidate_params)
            # Check guard condition expression that may contain variables.
            # Must be evaluated for each candidate_parms.
            eval(toexpr(cond_term, tr_vsub, net)) || continue #! XXX CACHE eval
            inscription_val = inscription_value(net, place_id, transition_id, z, tr_vsub) # bag
            mark = unwrap_pmset(mark)
            issubset(inscription_val, mark) || continue # not a valid substitution
            push!(tr_varsubs, tr_vsub)
        end
        return !isempty(tr_varsubs) # no sunstitution found if empty
    end
end

"""
    get_variable_substitutions!(binding_sets, net::AbstractPnmlNet, transition_id, tr_vars, mark_dict)
# Arguments
 - binding_sets map from variable id to set of substitution values
 - net contains
 - transition_id
 - tr_vars variable ids of transition
 - mark_dict

Return enabled state, update `tr_vars`  and `binding_sets`.
"""
function get_variable_substitutions!(binding_sets, net::AbstractPnmlNet, transition_id, tr_vars, mark_dict)
    ER()&& println("#-- get_variable_substitutions! $(pntd_of(net)) $(pid(net)) ", transition_id)
    for place_id in preset(net, transition_id)
        ar = arc(net, place_id, transition_id)::Maybe{Arc}
        isnothing(ar) && error("did not find arc: $place_id -> $transition_id")
        mark = unwrap_pmset(mark_dict[place_id])
        ER()&& @show place_id => mark
        arc_vars = Multiset(PNML.Labels.variables(PNML.inscription(ar))...) # Count variables.
        isempty(arc_vars) || union!(tr_vars, keys(arc_vars)) # Cache variable ids.

        place_sort = sortref(place(net, place_id))
        enabled, arc_binding_sets = get_arc_var_binding_sets!(arc_vars, place_sort, mark, net)
        enabled || return false # transition not enabled
        accum_var_binding_sets!(binding_sets, arc_binding_sets)::Bool || return false
    end # preset arcs
    #TODO sanity check substitutions.
    return true # enabled, binding_sets is valid
end


"""
    get_arc_var_binding_sets!(arc_vars, placesort, mark, net) -> Bool, AbstractDictionary

Return tuple of boolean status and `arc_var_binding_set` dictionary.

The status is `true` if no variables are present or all variables have at least 1 substition.
Indicates that transition is able to fire (enabled for selection to fire).
The dictioary keys are the variable ids in the arc's inscription.
Dictionary values are multisets of all valid substitutions for key variable.

`arc_vars` is a multiset of variable ids with multiplicities as how many times it must be substituted.
"""
function get_arc_var_binding_sets! end

function get_arc_var_binding_sets!(_arc_vars::Multiset, placesort::SortRef, mark,
                                    net::PnmlNet{T}) where {T <: AbstractPNTD}
    # mark is a Number, no variables
    ER()&& println("#-- get_arc_var_binding_sets! 1 $(pntd_of(net)) $(pid(net)) ", mark)
    return true, OrderedDict{Symbol, Multiset{Symbol}}()
end
function get_arc_var_binding_sets!(_arc_vars::Multiset, _placesort::SortRef, mark,
                                    net::PnmlNet{PT_HLPNG})
    # mark is a singleton multiset. No varibles.
    ER()&& println("#-- get_arc_var_binding_sets! 2 $(pntd_of(net)) $(pid(net)) ", mark)
    return true, OrderedDict{Symbol, Multiset{Symbol}}()
end
function get_arc_var_binding_sets!(arc_vars::Multiset, placesort::SortRef, mark::PnmlMultiset,
                                    net::PnmlNet{T}) where {T <: AbstractHLCore}
    ER()&& println("#-- get_arc_var_binding_sets! 3 $(pntd_of(net)) $(pid(net)) ", mark)
    get_arc_vbs_impl!(arc_vars, placesort, mark, net)
end

"Return tuple of boolean status and `arc_var_binding_set` dictionary."
function get_arc_vbs_impl!(arc_vars::Multiset, placesort::SortRef,
                           mark::PnmlMultiset,
                           net::PnmlNet{T}) where {T <: AbstractHLCore}
   # mark is a
    ER()&& println("#-- get_arc_vbs_impl! mark = ", mark)
    arc_binding_sets = OrderedDict{Symbol, Multiset{Symbol}}()
    for v in keys(arc_vars)
        # Each variable must have a non-empty substitution.
        #! variable sorts are never ProductSort. Just one sort.
        # Start with empty substution set for variable.
        # Use multiset as a counter.
        arc_binding_sets[v] = Multiset{Symbol}()
        v_decl = PNML.variabledecl(net, v)
        v_sortref = sortref(v_decl)
        v_refid = PNML.refid(v_sortref)::Symbol

        # Verify variable sort matches placesort.
        if is_productsort(placesort)
            any(==(v_refid), PNML.Sorts.sorts(placesort, net)) ||
                    error("none of product sorts are '$v_refid': ", repr(placesort))
        else
            placesort !== v_sortref &&
                error("not equal sorts ($placesort, $v_sortref)")
        end

        # Examine mark
        for (element, multiplicity) in pairs(multiset(mark))
            #@show typeof(element)
            #! arc_binding_set counts possible substitutions in source place's marking.
            # Multiple of same variable in arc inscription expression
            # means arc_binding_set only includes values of mark elements with
            # multiplicity at least as that large.
            if multiplicity >= arc_vars[v]
                # Variable multiplicity is per-arc, value is shared among arcs.
                if element isa Tuple # mark is a ProductSort.
                    # Select the tuple member(s) matching variable sort.Return tuple of boolean status and `arc_var_binding_set` dictionary.

                    for expr in element
                        if PNML.refid(expr) === v_refid
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
