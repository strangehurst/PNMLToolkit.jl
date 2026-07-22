# High level Petri net enamling rule filters.

"Fallback enabled filter always returns `true`."
function enable_filter_true(::AbstractPnmlNet, ::Symbol, _marks)
    #println("enable_filter_true $t")
    return true
end

"""
Return `true` iff ∀p ∈ preset(t): is_inhibitor(arc(p,t)) && inscription != 0 && marks[p] < inscription.``
"""
function enable_filter_inhibit(net::AbstractPnmlNet, t::Symbol, marks)
    for p in preset(net, t)
        iarc = arc(net, p, t)::Arc
        isnothing(iarc) && continue
        is_inhibitor(iarc) || continue
        inhibit = inscription(iarc)
        z = 0 #! TODO make zero of proper type
        if inhibited(inhibit, z, marks[p])
            return false
        end
    end
    return true
end
#! z is a zero of proper type
function inhibited(inhibit, z, mark)
    coalesce(inhibit != z, false) &&
        coalesce(mark >= inhibit, false)
end

"Reset arc filter always returns `true`."
enable_filter_reset(_net::AbstractPnmlNet, _id::Symbol, _marks) = true

"Read filter function is the same as enabled function applied to read arc."
function enable_filter_read(net::AbstractPnmlNet, t_id::Symbol, marks)
    enable_filter_true(net, t_id, marks) #todo!
end

# """
# Capacity filter returns `true` iff
#     [∀p ∈•t: M(p) ≥ Pre(p , t)] ∧ [∀ p' ∈t• : M(p') + Post(p',t) - Pre (p',t) ≤ C(p')]
#  Pre, Post are the backward and forward incidence matrices,
# """
function enable_filter_capacity(net::AbstractPnmlNet, t::Symbol, marks)
    @assert has_transition(net, t)
    for p in preset(net, t)
        @assert has_place(net, p)
        cv = PNML.Labels.capacity_value(place(net,p))
        if cv > 0 && marks[p] >= pre(net, p, t)
            for p2 in postset(net, t)
                @assert has_place(net, p2)
                #@show marks[p2] cv
                if marks[p2] + post(net, t, p2) - pre(net, p2, t) > cv
                    return false
                end
            end
        end
    end
    return true
end

enable_filter_priority(net::AbstractPnmlNet, t_id::Symbol, marks) = enable_filter_true(net, t_id, marks)
enable_filter_tpn(net::AbstractPnmlNet, t_id::Symbol, marks) = enable_filter_true(net, t_id, marks)
