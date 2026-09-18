# Enabling Rule
"Debug print switch for enabline rule."
ER() = true
using PNML: elabelT, tparserT, efilterT, lparserT, vsubT, varsT, varsetT, substT


"""
    unwrap_pmset(mark) -> Multiset

If mark is a PnmlMultiset that wraps a PnmlMultiset, extract a singleton.
"""
function unwrap_pmset(mark)
    if mark isa PnmlMultiset && eltype(mark) <: PnmlMultiset
        single = only(multiset(mark))
        single isa PnmlMultiset &&
            error("recursive PnmlMultisets not allowed here, found $single")
        return single # Replace mark with the wrapped PnmlMultiset's only element.
    end
    return mark # identity function
end

"""
$(TYPEDSIGNATURES)

Return Vector of place_id=>marking_value of that pace.
`T` is the basis sort of multiset.
"""
function labeled_places(net::AbstractPnmlNet, markings, ::Type{T}) where {T}
    #@show typeof(markings)
    #Pair[k=>v for (k,v::T) in zip(map(pid, places(net)), markings)]
    #foreach(println, zip(map(pid, places(net)), markings))

    Pair[k=>v for (k, v) in zip(map(pid, places(net)), markings)]
end

"Return multiset used to count place sorttypes of a net."
function count_sorttypes(net::PnmlNet)
    #Multiset([(to_sort(net) ∘ sortref)(p) for p in places(net)])
    # if to_sort is a ProductSort, unwrap to tuple
    m = Multiset()
    for p::Place in places(net)
        sref = sortref(p)
        us = unwrap_namedsort(to_sort(sref, net))
        if us isa ProductSort
            ts = tuple(((unwrap_namedsort ∘ to_sort(net)).(sorts(us)))...)
            push!(m, ts)
        else
            push!(m, us)
        end
    end
    return m
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

const enabledT = OrderedDict{Symbol, Bool}

function enabled(net::PnmlNet{T}, marking) where {T <: PNMLVariant}
    ER()&& println("\n#-- enabled ", pntdsym(net), " id ", pid(net))

    @show typeof(marking)
    if is_individual_token(pntd_of(net))
        foreach(println ∘ typeof, marking)
    end

    cnt = count_sorttypes(net)
    if ER()
        println("found sorttypes");
        for (i,c) in enumerate(cnt)
            println(i, ": ", c)
        end
    end

    # Transaction id => boolean enabled. Start by assuming all transitions are enabled.
    enabled_dict = enabledT(id=>true for id in PNML.transition_ids(net))
    ER()&& @show typeof(enabled_dict)
    # dictionary with key of place id, value of its marking value (from marking vector)
    # Place sorttypes may be different. All marks are Multisets of sorttype.
    ER()&& @show T
    vT = value_type(Marking, pntd_of(net))
    # if T <: HighLevelPNML && pntdsym(net) !== :pt_hlpng
    #     Union{Symbol, Tuple{Vararg{Symbol}}}
    # else
    #     value_type(Marking, pntd_of(net))
    # end
    ER()&& @show vT

    ER()&& @show labeled_places(net, marking, vT)
    mark_dict = OrderedDict{Symbol, vT}(labeled_places(net, marking, vT))
    ER()&& @show typeof(mark_dict)
    ER()&& @show typeof(net.varsubs)
    for tr in transitions(net)
        transition_id = pid(tr)
        if ER()
            let t = term(condition(transition(net, transition_id)))
                println("\ntr::Unionansition_id $transition_id = ", t)
            end
            for pl in preset(net, transition_id)
                let a = arc(net, pl, transition_id)::Arc
                    i = inscription(a)
                    println("arc $pl -> $transition_id = ", term(i))
                end
            end
            println()
        end
        #~ Clear any cached NamedTuple[] for transition.
        haskey(net.varsubs, transition_id) && empty!(net.varsubs[transition_id])

        #TODO other filters reducing work done by token_load! Cannot use variables.

        # Build varsubs while accessing token sufficency part of enabling rule.
        enabled_dict[transition_id] &= sufficient_tokens!(mark_dict, net, transition_id)
        enabled_dict[transition_id] || continue

        # transition_guard evaluated as part of sufficient_tokens!
        ER()&& println("filters")
        for f in filters(net)
            # filters may use variables (aka mark_dict values)
            enabled_dict[transition_id] &= f(net, transition_id, mark_dict)
            enabled_dict[transition_id] || break # next tr
        end
    end
    return collect(values(enabled_dict))
end


"""
$(TYPEDSIGNATURES)

Return enabled state of transition by testing that all its input places have enough tokens
and transition guard is true.
"""
function sufficient_tokens!(mark_dict::AbstractDict, net::PnmlNet, transition_id)
    ER()&& println("#-- sufficient_tokens! ",
                    "$(pntd_of(net)) $(pid(net)) $transition_id")
    @show pntdsym(net)
    @show is_collective_token(pntdsym(net))
    s = if is_collective_token(pntdsym(net))
        # There are no variables possible here and the guard is `true`.
        # Evaluate preset inscription expressions, compare to mark value.
        if pntdsym(net) === :pt_hlpng
            all(mark_dict[place_id] >= cardinality(inscription(arc(net, place_id, transition_id))())
                    for place_id in preset(net, transition_id))
        else
            all(mark_dict[place_id] >= inscription(arc(net, place_id, transition_id))()
                    for place_id in preset(net, transition_id))
        end
        # all(skipmissing(mark_dict[place_id]skipmissing( >= inscription(arc(net, place_id, transition_id))()
        #                         for place_id in preset(net, transition_id)))
    else
        tr_vars = haskey(net.vars, transition_id) ? net.vars[transition_id] : varsetT()
        tr_varsubs = haskey(net.varsubs, transition_id) ? net.varsubs[transition_id] : substT()
        sufficient_tokens2!(mark_dict, net,  transition_id,
                                tr_vars, tr_varsubs)
    end
    ER()&& println("#-- sufficient_tokens! return: ", s)
    return coalesce(s, false)
end

"""
$(TYPEDSIGNATURES)

Handle transition guards
"""
function sufficient_tokens2!(mark_dict::AbstractDict, net::PnmlNet{HighLevelPNML}, transition_id,
                            tr_vars::varsetT,
                            tr_varsubs::substT)
    ER()&& println("#-- sufficient_tokens2! $(pntd_of(net))",
                " $(pid(net))",
                " $transition_id)")
    # During enabling rule, tr_var_binding_set maps variable to a set of elements.
    tr_var_binding_set = substT()
    #~ marking = PnmlMultiset{B, T}(Multiset(T() => 1)) singleton
    # varsub maps a variable to 1 element value of multiset(marking[transition_id])
    # when enabling/firing transition.
    # Multiset type set from first use

    # Get transition variable substitution binding setfrom preset arcs.
    # Update vars.
    if !get_variable_substitutions!(tr_var_binding_set, net, transition_id,
                                tr_vars, mark_dict)
        ER() && println("#-- sufficient_tokens2! $(pntd_of(net))",
                " $(pid(net))",
                " $transition_id = false")
       return false # no substution found
    end
    ER()&& @show tr_var_binding_set tr_vars
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
    ER()&& @show r
    return r
end

"""
    get_variable_substitutions!(binding_sets, net::AbstractPnmlNet, transition_id, tr_vars, mark_dict)
# Arguments
 - binding_sets map from variable id to set of substitution values
 - net contains
 - transition_id
 - tr_vars variable ids of transition
 - mark_dict

Return enabled state after update of `tr_vars`  and `binding_sets`.
"""
function get_variable_substitutions!(binding_sets::substT, net::PnmlNet{T}, transition_id,
                                     tr_vars::varsetT, mark_dict) where {T<:PNMLVariant}
    ER()&& println("#-- get_variable_substitutions! $(pntd_of(net)) $(pid(net)) ", transition_id)
    ER()&& @show typeof(binding_sets) typeof(tr_vars) typeof(mark_dict)
    for place_id in preset(net, transition_id)
        ar = arc(net, place_id, transition_id)::Maybe{Arc}
        isnothing(ar) && error("did not find arc: $place_id -> $transition_id")
        mark = unwrap_pmset(mark_dict[place_id])
        ER()&& @show place_id => accum_var_binding_sets!
        # Count uses of variables. Keys are variable ids.
        arc_vars = Multiset(PNML.Labels.variables(PNML.inscription(ar))...)
        isempty(arc_vars) ||
            union!(tr_vars, keys(arc_vars)) #^ Cache variable ids.

        place_sort = sortref(place(net, place_id))
        enabled, arc_binding_sets =
            get_arc_var_binding_sets!(arc_vars, place_sort, mark, net)
        enabled || return false # transition not enabled
        ER()&& @show arc_binding_sets
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

const bindingT = OrderedDict{Symbol, Multiset{Union{Symbol, Tuple{Vararg{Symbol}}}}}

function get_arc_var_binding_sets!(_arc_vars::Multiset, _::SortRef, mark,
                                    net::PnmlNet{T}) where {T <: Union{DiscretePNML, ContinuousPNML}}
    # mark is a Number, no variables
    ER()&& println("#-- get_arc_var_binding_sets! 1 $(pntdsym(net)) $(pid(net)) ", mark)
    return true, bindingT()
end

function get_arc_var_binding_sets!(arc_vars::Multiset, placesort::SortRef, mark,
                                    net::PnmlNet{HighLevelPNML})
    ER()&& println("#-- get_arc_var_binding_sets! 3 $(pntdsym(net)) $(pid(net)) ", mark)
    if net.type === :PT_HLPNG
        # mark is a singleton multiset. No varibles.
        return true, bindingT()
    else
        return get_arc_vbs_impl!(arc_vars, placesort, mark, net)
    end
end

"Return tuple of boolean status and `arc_var_binding_set` dictionary."
function get_arc_vbs_impl!(arc_vars::Multiset, placesort::SortRef, mark::Multiset,
                           net::PnmlNet{HighLevelPNML})
   # mark is a
    ER()&& println("#-- get_arc_vbs_impl! mark = ", mark)

    # Start with empty substution set for each variable.
    # Use multiset as a binding set counter.
    arc_binding_sets = bindingT()

    for v::Symbol in keys(arc_vars)
        match, indx = varsort_check(net, v, placesort)
        #@show indx
        match || error(string("sort mismatch: ", placesort,
                        ", ", sortref(PNML.variabledecl(net, v))))
        # Each variable must have a non-empty substitution. Start with empty set.
        arc_binding_sets[v] = Multiset{Union{Symbol, Tuple{Vararg{Symbol}}}}()

        # Examine `mark`, look for values matching varible declaration sort.
        # `indx` are the tuple elements that are expected to match if a `ProductSort`.
        for (element, multiplicity) in pairs(mark)
            @show typeof(element) element multiplicity
            #! arc_binding_set counts possible substitutions in source place's marking.
            # Multiple of same variable in arc inscription expression means
            # `arc_binding_sets` only includes values of mark elements with
            # multiplicity at least as that large.
            if multiplicity >= arc_vars[v]
                if element isa Tuple # mark is a ProductSort.
                    # Select the tuple member(s) matching variable sort
                    # To add to `arc_var_binding_sets` of `v`.

                    # mark is a member of the marking vector. PnmlExpr has already been evaluated.
                    # Each element of tuple may have a different Sort. At least 1 will match v.
                    # arc_binding_sets counts number of each value.
                    push!(arc_binding_sets[v], element[indx])
                else
                    push!(arc_binding_sets[v], element)
                end
            end
        end

        if !isempty(arc_vars) && isempty(arc_binding_sets[v])
            return false, arc_binding_sets # A variable has no substitution.
        end
    end
    return true, arc_binding_sets # No variables or all of them have at least 1 substution.
end

"""
$(TYPEDSIGNATURES)

Evaluate transition's preset arc inscription expressions, compare to mark value.
Update varsubs with feasible variable substitution named tuples.

The firing rule will select from one transition's feasible substutions in its varsubs.
"""
function comp_mark_inscription end
function comp_mark_inscription(net::PnmlNet{T}, mark_dict::AbstractDict, transition_id::Symbol,
                                cond_term,
                                tr_var_binding_set::substT, tr_vars::varsetT, tr_varsubs::substT) where {T <: PNMLVariant}
    ER()&& println("\n#-- comp_mark_inscription! ",
                    "$(pntdsym(net)) $(pid(net)) ", transition_id)
    for place_id in preset(net, transition_id)
        # eltype(sortof(place(net, place_id)))
        mark = mark_dict[place_id]
        a = arc(net, place_id, transition_id)::Arc
        if !__compare_mi_impl(net, mark, cond_term, a,
                               tr_var_binding_set, tr_vars, tr_varsubs)
            return false
        end
    end
    return true # transition is enabled
end

# Assume no variables
function __compare_mi_impl(net::PnmlNet{T}, mark, cond_term, a::Arc, _, _, _) where {T <: PNMLVariant}
    # evaluate condition expression
    eval(toexpr(cond_term, NamedTuple(), net)) || return false  #! XXX CACHE eval
    inscription_val = inscription_value(a, NamedTuple())
    return mark >= inscription_val
 end

# Variables supported for High-level nets
function __compare_mi_impl(net::PnmlNet{T}, mark, cond_term, a::Arc,
                           tr_var_binding_set::substT, tr_vars::varsetT,
                           tr_varsubs::substT) where {T <: HighLevelPNML}
    ER()&& println("#-- __compare_mi_impl ")
    ER()&& println()
    ER()&& @show typeof(mark) typeof(cond_term)
    ER()&& @show typeof(tr_var_binding_set) typeof(tr_vars) typeof(tr_varsubs)
    ER()&& @show tr_vars
    ER()&& @show tr_var_binding_set
    ER()&& @show tr_varsubs
    ER()&& println()
    ER()&& @show net.vars net.varsubs
    ER()&& println()
    ER()&& @show mark cond_term a
    ER()&& println()

    if isempty(tr_vars) # 0-ary operators or constants
        # PT_HLPNG will have no vars
        eval(toexpr(cond_term, NamedTuple(), net)) || return false  #! XXX CACHE eval
        @show inscription_val = inscription_value(a, NamedTuple())
        @show mark = unwrap_pmset(mark)
        return issubset(inscription_val, mark)
   else
        # Use the transition-level variable substitution binding map `tr_var_binding_set`.
        # Iterate over the cartesian product to produce a list of candidate firings.
        # A candidate firing is a NamedTuple variable_id => marking_value of substitutions.
        var_ids = Tuple{Vararg{Symbol}}(keys(tr_var_binding_set)...) # Tuple of variable ids
        ER()&& @show var_ids typeof(var_ids)
        var_sub_tuple = tuple(values(tr_var_binding_set)...) # Tuple of Multisets{PnmlMultiset}
        ER()&& @show var_sub_tuple typeof(var_sub_tuple)
        sub1 = tuple((keys.(var_sub_tuple))...) # Tuple of iterators
        ER()&& @show sub1 typeof(sub1)

        for candidate_params::Tuple{Vararg{Symbol}} in Iterators.product(sub1...)
            ER()&& println()
            # Assume order of tr_var_binding_set and product are the same.
            # Mke named tuple where names are variable ids.
            ER()&& @show candidate_params typeof(candidate_params)
            tr_vsub = namedtuple(var_ids, candidate_params)
            # Check guard condition expression that may contain variables.
            # Must be evaluated for each candidate_parms.
            eval(toexpr(cond_term, tr_vsub, net)) || continue #! XXX CACHE eval
            @show inscription_val = inscription_value(a, tr_vsub) # bag
            @show mark = unwrap_pmset(mark)
            issubset(inscription_val, mark) || continue # not a valid substitution
            push!(tr_varsubs, tr_vsub)
        end
        return !isempty(tr_varsubs) # no substitution found if empty
    end
end

"""
    accum_var_binding_sets!(tr_binding_sets, arc_binding_sets) -> Bool

Collect variable bindings, intersecting among arc's sets.
Return enabled status of false if any variable does not have a substitution.
"""
function accum_var_binding_sets!(tr_binding_sets::substT, arc_binding_sets)
    ER()&& println("#-- accum_var_binding_sets!")
    for v in keys(arc_binding_sets)
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
$(TYPEDSIGNATURES)

Returm tupl(`true`, Vector{Int}) if the VariableDeclaration `v`'s sortref matches the place's sorttype.
The Vector{Int} is the matching indices of a `PartitionSort`'s `sorts`.
Non-partitions return an empty tuple.
"""
function varsort_check(net::PnmlNet{HighLevelPNML}, v::Symbol, placesort::SortRef)
    v_sortref = sortref(PNML.variabledecl(net, v))
    #@show v_sortref
    indx = Int[]
    if is_productsort(placesort)
        # Use indices to select value from `mark`s tuple with matching sort.
        for (i, s) in enumerate(PNML.Sorts.sorts(placesort, net))
            v_sortref === s  &&
                push!(indx, i)
        end
    else
        #@show placesort
        v_sortref === placesort  &&
            push!(indx, 1)
    end
    #@show indx
    return isempty(indx) ? false : true, indx
end
