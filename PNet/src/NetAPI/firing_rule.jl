# Firing Rule

"""
$(TYPEDSIGNATURES)

When net has collective token values, construct an `enabled_vector` using the
current `marking` vector.

Return `marking + incidence * enabled_vector`, a new marking vector.
"""
function fire2(C, net::PnmlNet, marking)
    if is_collective_token(pntd_of(net))
        muladd(permutedims(C), enabled(net, marking), marking)
    else
        error("firing $(pntdsym(net)) not implemented")
    end
end

"""
    fire(incidence, enabled_vector, marking) -> ArbitraryOperator

Return the marking vector after firing transition: marking + incidence * enabled_vector

`marking` values added to product of `incidence'` matrix and firing `enabled_vector`.
"""
function fire(incidence, enabled_vector, marking)
    #println("fire $incidence $enabled $m₀ ")
    #@show typeof(incidence) enabled typeof(m₀)
    #@show permutedims(incidence) * enabled
    #! Multisets do not have negative multiplicities so fail here with incorrect marking!
    muladd(permutedims(incidence), enabled_vector, marking)
end
