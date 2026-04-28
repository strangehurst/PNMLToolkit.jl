"""
    metagraph(net::PnmlNet) -> MetaGraphsNext.MetaGraph

Create a graph.
Note that when `is_collective_token` is true the graph `weight_function` becomes complex.
"""
function metagraph end
metagraph(model::PnmlModel) = metagraph(first(nets(model)))
function metagraph(net::PnmlNet{P})where {P <: AbstractPnmlType}
    #! println("\nmetagraph $(pntd(net)) $(pid(net))")

    if !(narcs(net) > 0 && nplaces(net) > 0 && ntransitions(net) > 0)
        msg = string("Attempted to create a `MetaGraph` from an incomplete $(pntd(net)) graph: ",
                  " net id = ", pid(net),
                  " narcs = ", narcs(net),
                  " nplaces = ", nplaces(net),
                  " ntransitions = ", ntransitions(net))
        throw(ArgumentError(msg))
    end

    # map pnml id symbol to vertex code.
    vcode  = vertex_codes(net) # inverse is vertex_labels(net)
    vlabel = vertex_labels(net)
    @assert length(vlabel) == length(vcode)

    # Create a directed graph from every arc in the petri net graph.
    graph = SimpleDiGraphFromIterator(Edge(vcode[source(a)] => vcode[target(a)]) for a in arcs(net))
    @assert length(vcode) == Graphs.nv(graph)

    # Map place/pransition pid to (vertex code, label).
    vdata = Dict{Symbol, Tuple{Int, Union{Place, Transition}}}()
    vertex_data!(vdata, net, vcode)
    @assert length(vdata) == Graphs.nv(graph)

    # Map from (src,dst) to arc. Uses pid, not vertex codes of graph.
    edge_data = Dict((source(a), target(a)) => a for a in arcs(net))
    @assert length(edge_data) == Graphs.ne(graph)

    #todo weight function for MetaGraph
    weight_function, default_weight = if is_collective_token(pntd(net))
        tuple(a -> inscription(a)(NamedTuple()), # No variable substitutions here.
              PNML.Parser.default(Inscription, net))
    else
        @error "graph edge weight function of multiset in $(pntd(net)) $(pid(net))"
        tuple(a -> 1, 1)
    end

    MetaGraph(graph, vlabel, vdata,
                edge_data, # edge metadata is an `Arc`
                name(net), # graph metadata
                weight_function,
                default_weight)
end

"pnml id symbol mapped to graph vertex code integer."
vertex_codes(n::PnmlNet) = Dict(s=>i for (i,s) in enumerate(union(place_idset(n),
                                                                  transition_idset(n))))

"graph vertex code integer mapped to pnml id symbol."
vertex_labels(n::PnmlNet) = Dict(i=>s for (i,s) in enumerate(union(place_idset(n),
                                                                   transition_idset(n))))

"""
Fill `vdata` dictionary where keys are pnml ids,
values are tuples of vertex code, place or transition.
`vcode` is a dictionary mapping pnml ids to vertex codes.
"""
function vertex_data!(vdata::Dict{Symbol, Tuple{Int, Union{Place, Transition}}},
                     net::PnmlNet,
                     vcode::AbstractDict)
    for p in places(net)
        vdata[pid(p)] = (vcode[pid(p)], p)
    end
    for t in transitions(net)
        vdata[pid(t)] = (vcode[pid(t)], t)
    end
    return vdata
end
