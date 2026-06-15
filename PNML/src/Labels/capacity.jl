# Place capacity Lockable
"""
$(TYPEDSIGNATURES)
"""
function capacity_value(p)
    label = get_label(p, :capacity)
    return isnothing(label) ? 0 : label[:capacity]
end
