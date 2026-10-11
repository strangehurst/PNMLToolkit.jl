# Enabling Rule
"Debug print switch for enabline rule."
ER() = true
using PNML: elabelT, tparserT, efilterT, lparserT, vsubT, varsT, BagvarT, substT

"""
    BindingT

Dictionary with key of place_id and value is a multiset of marking values
(FEConstant symbol or tuple of symbols for product sorts).

place_id => Union{Symbol, Tuple{Symbol}} # FEConstants
"""
const BindingT = OrderedDict{Symbol, Multiset{Union{Symbol, Tuple{Vararg{Symbol}}}}}

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

Return Vector of `place_id=>marking_value` of that pace.
"""
function labeled_places(net::AbstractPnmlNet, markings)
    Pair{Symbol,Any}[k=>v for (k, v) in zip(map(pid, places(net)), markings)]
end

"""
    enabled(::PnmlNet, marking) -> Vector{Bool}

Return vector of booleans where `true` means the matching transition
is enabled at current `marking`. Has the same order as the `transitions` dictionary.
Used in the firing rule.

$(METHODLIST)
"""
function enabled end

function enabled(net::PnmlNet{T}, marking::Vector) where {T <: PNMLVariant}
    ER()&& println("\n#-- enabled ", pntdsym(net), " id ", pid(net))

    if ER()
        @show PNML.vsubT; println()
        @show PNML.varsT; println()
        @show substT; println()
        @show BagvarT; println()
        @show typeof(net.varsubs); println()
    end

    #~ Map of transition_id to its marking value.
    mark_dict = OrderedDict{Symbol, Any}(labeled_places(net, marking))
    # Place sorttypes may be different. All marks are Multisets of sorttype.
    # See count_sorttypes! and keys(net.scnt)
    if ER()
        println("place sorttypes ", typeof.(keys(net.scnt)))
        println()
        @show typeof(mark_dict)
        foreach(println ∘ typeof, values(mark_dict))
        println()
    end

    #~ Start by assuming all transitions are enabled.
    enabled_dict = OrderedDict{Symbol, Bool}(id=>true for id in PNML.transition_ids(net))
    for tr in transitions(net)
        transition_id = pid(tr)
        if ER()
            let t = term(condition(transition(net, transition_id)))
                println("\ntransition $transition_id = ", t)
            end
            for pl in preset(net, transition_id)
                let a = arc(net, pl, transition_id)::Arc
                    i = inscription(a)
                    println("arc $pl -> $transition_id = ", term(i))
                end
            end
            println()
        end

        #~ Sufficent tokens and guard.
        # Build net.varsubs while accessing token sufficency part of enabling rule.
        enabled_dict[transition_id] &= sufficient_tokens!(mark_dict, net, transition_id)
        enabled_dict[transition_id] || continue

        #~ Enable filters.
        ER()&& println("filters")
        for f in filters(net)
            # filters may use variables
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
function sufficient_tokens!(mark_dict::AbstractDict, net::PnmlNet, transition_id::Symbol)
    ER()&& println("#-- sufficient_tokens! ",
                    "$(pntd_of(net)) $(pid(net)) $transition_id")
    #~ Clear any cached varsubs for transition.
    haskey(net.varsubs, transition_id) && empty!(net.varsubs[transition_id])

    # Evaluate preset inscriptions expression's, compare each to adjacent place's mark's value.
    s = if is_collective_token(net)
        # There are no variables possible here and the guard is `true`.
        if pntdsym(net) === :pt_hlpng
            all(mark_dict[place_id] >= cardinality(inscription_value(arc(net, place_id, transition_id), NamedTuple()))
                    for place_id in preset(net, transition_id))
        else
            all(mark_dict[place_id] >= inscription_value(arc(net, place_id, transition_id), NamedTuple())
                    for place_id in preset(net, transition_id))
        end
    else
        # Individual tokens: symmetric, hlpng
        #!
        #! Construct a context object initialized with varibles used in transition.
        #!
        erc = ERContext(; tr_vars = transition_vars(net, transition_id)::BagvarT,
                          tr_varsubs = haskey(net.varsubs, transition_id) ? net.varsubs[transition_id] : substT() )
        @warn "sufficent_tokens!" erc list_vars(net, erc.tr_vars)
        sufficient_tokens2!(mark_dict, net,  transition_id, erc)
    end
    ER()&& println("#-- sufficient_tokens! return: ", s)
    return coalesce(s, false)
end

@kwdef struct ERContext
    tr_vars::BagvarT
    tr_varsubs::substT = substT()
    tr_var_binding_set::BindingT = BindingT()
end

function Base.show(io::IO, erc::ERContext)
    println(io, "tr_vars ", erc.tr_vars)
    println(io, "tr_varsubs ", erc.tr_varsubs)
    println(io, "tr_var_binding_set ", erc.tr_var_binding_set)
end
function Base.show(io::IO, bind::BindingT)
    print(io::IO, typeof(bind), "(")
    if !isempty(bind)
        for p in pairs(bind)
            print(io, "\n    ", p) #p.first, " => ", p.second)
        end
    end
    println(io, ")")
end
function list_vars(net, m::BagvarT)
    collect(variabledecl(net,k) for k in keys(m))
    #map(Fix1(net, variabledecl), keys(m))
    #foreach(Fix1(net, variabledecl), keys(m))
end

"""
$(TYPEDSIGNATURES)

Handle transition guards
"""
function sufficient_tokens2!(mark_dict::AbstractDict, net::PnmlNet{HighLevelPNML}, transition_id,
                            erc::ERContext)
    ER()&& println("#-- sufficient_tokens2! $(pntd_of(net))",
                " $(pid(net))",
                " $transition_id)")

    # Get transition variable substitution binding set from preset arcs.
    # Update vars.
    if !get_variable_substitutions!(erc, net, transition_id,
                                mark_dict)
        ER() && println("#-- sufficient_tokens2! $(pntd_of(net))",
                " $(pid(net))",
                " $transition_id = false")
       return false # no substution found
    end
    ER()&& @error "after !get_variable_substitutions!" erc
    #^--------------------------------------------------------------------------------
    #& XXX variable substitutions fully specified by preset of transition XXX
    #& tr_vars is complete. tr_var_binding_set has valid substitutions for all variables.
    #^--------------------------------------------------------------------------------

    # Return enabled status based on comparing mark and inscription.
    # Update varsubs, a vector of possible substitutions.
    r = comp_mark_inscription(net, mark_dict, transition_id,
                              condition(transition(net, transition_id)),
                              erc)
    #! REMEMBER marking multiset element may be a tuple.
    #ER()&& @show r
    return r
end

"""
$(TYPEDSIGNATURES)
# Arguments
 - binding_sets map from variable id to set of substitution values
 - net contains
 - transition_id
 - tr_vars variable ids of transition
 - mark_dict

Return enabled state after update of `binding_sets`.
"""
function get_variable_substitutions!(erc::ERContext, net::PnmlNet, transition_id, mark_dict)
    ER()&& println("#-- get_variable_substitutions! $(pntd_of(net)) $(pid(net)) ", transition_id)
    ER()&& @show erc
    for place_id in preset(net, transition_id)
        ar = arc(net, place_id, transition_id)::Maybe{Arc}
        isnothing(ar) && error("did not find arc: $place_id -> $transition_id")

        # Count uses of variables. Keys are variable ids.
        arc_vars = PNML.Labels.variables(PNML.inscription(ar))
        ER()&& @warn "get_variable_substitutions! $transition_id $place_id" erc
        isempty(arc_vars) ||
            @assert issubset(arc_vars, erc.tr_vars)

        place_sort = sortref(place(net, place_id))
        mark = unwrap_pmset(mark_dict[place_id])
        ER()&& @show "Before get_arc_var_binding_sets!" mark_dict[place_id] mark
        enabled, arc_binding_sets::BindingT =
            get_arc_var_binding_sets!(arc_vars, place_sort, mark, net)
        enabled || return false # transition not enabled
        ER()&& @show "enabled get_variable_substitutions! binding sets" arc_binding_sets
        #! tr_var_binding_set
        accum_var_binding_sets!(erc.tr_var_binding_set, arc_binding_sets)::Bool || return false
    end # preset arcs
    #TODO sanity check substitutions.
    return true # enabled, binding_sets is valid
end

"""
$(TYPEDSIGNATURES)
Return `BagvarT` counting variables in preset arc inscriptions and condition of a transition.
"""
function transition_vars(net, transition_id)
    tr_vars = BagvarT() # Count uses of each variable in inscription expressions.
    for place_id in preset(net, transition_id)
        ar = arc(net, place_id, transition_id)::Maybe{Arc}
        # Is it possible that a transition has no preset? # TODO!
        isnothing(ar) && error("did not find arc: $place_id -> $transition_id")
        arc_vars = Multiset(PNML.Labels.variables(PNML.inscription(ar))...)
        #ER()&& @warn arc_vars
        if !isempty(arc_vars)
            tr_vars = union(tr_vars, arc_vars)
        end
    end
    tr_vars = union(tr_vars,
        PNML.Labels.variables(condition(transition(net, transition_id))))
    #@show tr_vars
    return tr_vars
end
"""
    get_arc_var_binding_sets!(arc_vars, placesort, mark, net) -> Bool, BindingT

Return tuple of boolean status and `arc_var_binding_set` dictionary.

The status is `true` if no variables are present or all variables have at least 1 substition.
Indicates that transition is able to fire (enabled for selection to fire).
The dictioary keys are the variable ids in the arc's inscription.
Dictionary values are multisets of all valid substitutions for key variable.

`arc_vars` is a multiset of variable ids with multiplicities as how many times it must be substituted.
"""
function get_arc_var_binding_sets! end

function get_arc_var_binding_sets!(_arc_vars::Multiset, _::SortRef, mark,
                                    net::PnmlNet{T}) where {T <: Union{DiscretePNML, ContinuousPNML}}
    # mark is a Number, no variables
    ER()&& println("#-- get_arc_var_binding_sets! 1 $(pntdsym(net)) $(pid(net)) ", mark)
    return true, BindingT()
end

function get_arc_var_binding_sets!(arc_vars::Multiset, placesort::SortRef, mark,
                                    net::PnmlNet{HighLevelPNML})
    ER()&& println("#-- get_arc_var_binding_sets! 3 $(pntdsym(net)) $(pid(net)) ", mark)
    if net.type === :PT_HLPNG
        # mark is a singleton multiset. No varibles.
        return true, BindingT()
    else
        return get_arc_vbs_impl!(arc_vars, placesort, mark, net)
    end
end

"Return tuple of boolean status and `bindngT` dictionary."
function get_arc_vbs_impl!(arc_vars::Multiset, placesort::SortRef, mark::Multiset,
                           net::PnmlNet{HighLevelPNML})
   # mark is a
    ER()&& println("\n#-- get_arc_vbs_impl! mark = ", mark)

    # Start with empty substution set for each variable.
    # Use multiset as a binding set counter.
    arc_binding_sets = BindingT()

    for v::Symbol in keys(arc_vars)
        match, indxV = varsort_check(net, v, placesort)
        #^ NB indxV is a vector
        #@show indxV typeof(indxV)
        match || error(string("sort mismatch: ", placesort,
                        ", ", sortref(PNML.variabledecl(net, v))))
        # Each variable must have a non-empty substitution. Start with empty set.
        arc_binding_sets[v] = Multiset{Union{Symbol, Tuple{Vararg{Symbol}}}}()

        # Examine `mark`, look for values matching varible declaration sort.
        # `indx` are the tuple elements that are expected to match if a `ProductSort`.
        for (element, multiplicity) in pairs(mark)
            #! arc_binding_set counts possible substitutions in source place's marking.
            # Multiple of same variable in arc inscription expression means
            # `arc_binding_sets` only includes values of mark elements with
            # multiplicity at least as that large.
            if multiplicity >= arc_vars[v]
                if element isa Tuple # mark is a ProductSort.
                    # Select the tuple member(s) matching variable sort
                    # to add to `arc_var_binding_sets` of `v`.
                    for i in indxV
                        #@show element[i] typeof(element[i])
                        push!(arc_binding_sets[v], element[i])
                    end
                else
                    #@show element
                    push!(arc_binding_sets[v], element)
                end
            end
        end

        if !isempty(arc_vars) && isempty(arc_binding_sets[v])
            return false, arc_binding_sets # A variable has no substitution.
        end
    end
    @warn "get_arc_vbs_impl! returning" arc_binding_sets
    return true, arc_binding_sets # No variables or all of them have at least 1 substution.
end #= function get_arc_vbs_impl! =#

"""
$(TYPEDSIGNATURES)

Evaluate transition's preset arc inscription expressions, compare to mark value.
Update varsubs with feasible variable substitution named tuples.

The firing rule will select from one transition's feasible substutions in its varsubs.
"""
function comp_mark_inscription end
function comp_mark_inscription(net::PnmlNet{T}, mark_dict::AbstractDict, transition_id::Symbol,
                                cond, erc::ERContext) where {T <: PNMLVariant}
    ER()&& println("\n#-- comp_mark_inscription! ",
                    "$(pntdsym(net)) $(pid(net)) ", transition_id)
    for place_id in preset(net, transition_id)
        # eltype(sortof(place(net, place_id)))
        mark = mark_dict[place_id]
        a = arc(net, place_id, transition_id)::Arc
        if !__compare_mi_impl(net, mark, cond, a, erc)
            return false
        end
    end
    return true # transition is enabled
end

# Assume no variables
function __compare_mi_impl(net::PnmlNet{T}, mark, cond, a::Arc, ::ERContext) where {T <: PNMLVariant}
    # evaluate condition expression
    #eval(toexpr(cond_term, NamedTuple(), net)) || return false  #! XXX CACHE eval
    PNML.Labels.eval_cond_term(cond, NamedTuple()) ||
        return false  #! XXX CACHE eval
    inscription_val = inscription_value(a, NamedTuple()) # collective tokens have no variables
    return mark >= inscription_val
 end

# Variables supported for High-level nets
function __compare_mi_impl(net::PnmlNet{T}, mark, cond, a::Arc,
                           erc::ERContext) where {T <: HighLevelPNML}
    ER()&& println("\n#-- __compare_mi_impl ")
    if ER()
        println()
        @show mark
        println()
        @show cond
        println()
        @show a
        println()
        @show erc.tr_vars
        @show erc.tr_var_binding_set
        @show erc.tr_varsubs
        println()
    end

    if isempty(erc.tr_vars) # 0-ary operators or constants
        # PT_HLPNG will have no vars
        PNML.Labels.eval_cond_term(cond, NamedTuple()) || return false
        inscription_val = inscription_value(a, NamedTuple())
        mark = unwrap_pmset(mark)
        return issubset(inscription_val, mark)
   else
        # Use the transition-level variable substitution binding map `tr_var_binding_set`.
        # Iterate over the cartesian product to produce a list of candidate firings.
        # A candidate firing is a NamedTuple variable_id => marking_value of substitutions.
        #!var_ids = Tuple{Vararg{Symbol}}(keys(erc.tr_var_binding_set)...) # Tuple of variable ids
        var_ids = tuple(keys(erc.tr_var_binding_set)...) # Tuple of variable ids
        ER()&& @show typeof(var_ids) var_ids
        ER()&& println()

        ER()&& println("values(erc.tr_var_binding_set)")
        ER()&& foreach(println, values(erc.tr_var_binding_set))
        ER()&& println()

        var_sub_tuple = tuple(values(erc.tr_var_binding_set)...) # Tuple of Multisets{PnmlMultiset}
        ER()&& println("var_sub_tuple")
        ER()&& typeof(var_sub_tuple)
        ER()&& @show var_sub_tuple
        ER()&& foreach(println, var_sub_tuple)
        ER()&& println()

        sub1 = tuple((keys.(var_sub_tuple))...) # Tuple of iterators
        ER()&& @show typeof(sub1) sub1
        ER()&& foreach(println, sub1)
        ER()&& println()
        ER()&& foreach(println, Iterators.product(sub1...))
        ER()&& println()

        for candidate_params::Tuple{Vararg{Symbol}} in Iterators.product(sub1...)
            ER()&& println()
            # Assume order of tr_var_binding_set and product are the same.
            # Mke named tuple where names are variable ids.
            #ER()&& @show candidate_params typeof(candidate_params)
            tr_vsub = namedtuple(var_ids, candidate_params)
            # Check guard condition expression that may contain variables.
            # Must be evaluated for each candidate_parms.
            ER()&& @error cond tr_vsub
            @show c = PNML.Labels.eval_cond_term(cond, tr_vsub)
            if c
                inscription_val = inscription_value(a, tr_vsub) # bag
                mark = unwrap_pmset(mark)
                if issubset(inscription_val, mark)
                    push!(erc.tr_varsubs, tr_vsub)
                else
                    ER()&& @warn "not a valid substitution" inscription_val mark
                end
            else
                ER()&& @warn "transition not enabled" cond
            end
        end
        return !isempty(erc.tr_varsubs) # no substitution found if empty
    end
end

"""
    accum_var_binding_sets!(tr_binding_sets, arc_binding_sets) -> Bool

Collect variable bindings, intersecting among arc's sets.
Return enabled status of false if any variable does not have a substitution.
"""
function accum_var_binding_sets!(tr_binding_sets::BindingT, arc_binding_sets)
    ER()&& println("\n#-- accum_var_binding_sets!")
    @show typeof(tr_binding_sets) typeof(arc_binding_sets)
    @show tr_binding_sets arc_binding_sets
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
    v_sort = unwrap_namedsort(net, sortref(PNML.variabledecl(net, v)))
    #@show "varsort_check" v_sort
    indx = Int[]
    placesort = unwrap_namedsort(net, placesort)
    #
    if placesort isa ProductSort
        # Use indices to select values from `mark`s tuple with matching sort.
        for (i, s) in enumerate(PNML.Sorts.sorts(placesort))
            s = unwrap_namedsort(net, s)
            v_sort === s  &&
                push!(indx, i)
        end
    else
        v_sort === placesort  &&
            push!(indx, 1)
    end
    #@show indx
    return isempty(indx) ? false : true, indx
end
