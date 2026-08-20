### A Pluto.jl notebook ###
# v0.19.8

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ f4c883b8-e2e9-11ec-28de-addab043979e
begin
	import Pkg
    Pkg.activate(Base.current_project())
    Pkg.instantiate()

	using PlutoUI, LabelledArrays, EzXML, BenchmarkTools
    using Plots, MetaGraphsNext, Graphs, GraphPlot, Compose
    using PNML: PNML, pid
end

# ╔═╡ f87a98af-6af6-4a0a-819b-3e472eafe54a
# ╠═╡ show_logs = false
let
	versioninfo()
	Pkg.status()
end

# ╔═╡ 41566501-e86b-41af-bd01-2d2f999cc54f
md"""
birth rate $(@bind BR_slider NumberField(0.0:0.01:1.0; default=0.3))

death rate $(@bind DR_slider NumberField(0.0:0.01:1.0; default=0.7))

predatation rate $(@bind PR_slider NumberField(0.0:0.001:0.2; default=0.015))
"""

# ╔═╡ 812bda06-fd40-4b65-b5fa-0aae0c2c8832
xml2 = """<?xml version="1.0"?>
<pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
<net id="net0" type="continuous">
<page id="page0">
  <place id="rabbits"> <initialMarking>100.0</initialMarking> </place>
  <place id="wolves">  <initialMarking> <text>10.0</text> </initialMarking> </place>
  <transition id ="birth">     <rate> $BR_slider </rate> </transition>
  <transition id ="death">     <rate> $DR_slider </rate> </transition>
  <transition id ="predation"> <rate> $PR_slider </rate> </transition>
  <arc id="a1" source="rabbits"   target="birth">     <inscription><text>1</text> </inscription> </arc>
  <arc id="a2" source="birth"     target="rabbits">   <inscription><text>2</text> </inscription> </arc>
  <arc id="a3" source="wolves"    target="predation"> <inscription><text>1</text> </inscription> </arc>
  <arc id="a4" source="rabbits"   target="predation"> <inscription><text>1</text> </inscription> </arc>
  <arc id="a5" source="predation" target="wolves">    <inscription><text>2</text> </inscription> </arc>
  <arc id="a6" source="wolves"    target="death">     <inscription><text>1</text> </inscription> </arc>
</page>
</net>
</pnml>
"""

# ╔═╡ 602978fa-4e05-4546-b205-d027880f0ccd
net = PNML.SimpleNet(xml2)

# ╔═╡ 221681e3-656d-4fa1-8425-cece133df01d
S = PNML.place_idset(net)

# ╔═╡ ccb4e098-51b1-46dd-b563-1074a7ea9d82
T = PNML.transition_idset(net)

# ╔═╡ 9f5d18d5-f8b7-44d2-8ddf-8b38be57a0a4
A = PNML.arc_idset(net)

# ╔═╡ f282f10d-8e6a-462e-be8a-4c072df82d0a
# LabelledArrays when empty (dimension 0) use Union{} as the element type.
# Which errors under Pluto and suggests fix of defining this method.
Base.show(io::IO, ::MIME{Symbol("image/svg+xml")}, ::AbstractVector{Union{}}) = print(io, "∅")

# ╔═╡ 0e9edbf3-df2c-474b-b747-6789dac7a398
Δ = PNML.transition_function(net)

# ╔═╡ 7d77e7ca-ad32-435a-895e-697dc91c340d
petri = MetaGraph( DiGraph();
		VertexData = PNML.AbstractPnmlNode, #String, # marking, condition
		EdgeData = PNML.Arc, #Symbol,  # inscription
		graph_data = "graph_of_pnml")

# ╔═╡ c163301f-964e-4b79-b5f2-39c7bb17d085
for p in S
	petri[p] = PNML.place(net, p)
end

# ╔═╡ 7fc99e91-963a-4ffc-bea3-c54adc652c78
for t in T
	petri[t] = PNML.transition(net, t)
end

# ╔═╡ 596c2657-01ce-4f0a-99d6-10aeae963271
for a in A
	arc = PNML.arc(net, a)
	petri[PNML.source(arc), PNML.target(arc)] = arc
end

# ╔═╡ a127b05a-fcea-4712-be3c-03f96739de82
petri

# ╔═╡ 9b6e1948-e841-42b3-b315-e08b136bf047
PNML.inscription(petri[:birth, :rabbits])

# ╔═╡ c6e10d0d-019d-4fac-98a9-8774dce3af18
petri[:wolves]

# ╔═╡ c4802576-8425-4e66-aa3d-3fdb405a315e
petri[:rabbits, :birth]

# ╔═╡ 1ae71749-88eb-4b76-9ba0-901892bce079
collect(label_for.(Ref(petri),vertices(petri)))

# ╔═╡ 8ed47098-345d-46d6-aaec-1799ce2f3264
map(vertices(petri)) do v
	pid(petri[label_for(petri,v)])
end

# ╔═╡ 715e160e-e1cc-4cf8-9f0e-283146abb17f
collect(edges(petri))

# ╔═╡ f16359db-8e21-42ae-bb4d-eb8a6a75b992
@benchmark collect(edges(petri))

# ╔═╡ 2700ad27-4a1e-4410-b9c3-e288059473f9
# ╠═╡ show_logs = false
map(edges(petri)) do e
	@show src(e) dst(e)
	pid(petri[label_for(petri,src(e)), label_for(petri,dst(e))])
end

# ╔═╡ 9c706202-e11b-410e-bf73-f3b66cdd9c77
@benchmark map(edges(petri)) do e
	pid(petri[label_for(petri,src(e)), label_for(petri,dst(e))])
end

# ╔═╡ 1cfda3d4-e653-4629-b377-cad4ea8ce85a
[pid(petri[label_for(petri,src(e)), label_for(petri,dst(e))]) for e in edges(petri)]

# ╔═╡ 5229c597-0941-465b-abbf-fb1f76595bd4
@benchmark [pid(petri[label_for(petri,src(e)), label_for(petri,dst(e))]) for e in edges(petri)]

# ╔═╡ ed61c205-1b45-45f2-b6fa-76095e7c898e
gplot(petri;
	nodelabel=collect(label_for.(Ref(petri),vertices(petri))),
	edgelabel=[pid(petri[label_for(petri,src(e)), label_for(petri,dst(e))]) for e in edges(petri)]
	)

# ╔═╡ 13b8de0b-84ee-4ba8-abba-0fe353df206c
md"""
#### Appendix

Utilities, references, et al.
"""

# ╔═╡ a7990ebd-2d2a-4174-9b4c-173489dd4d83
html"<hr/>"

# ╔═╡ 22a5da67-b163-4cde-9a8b-9231b0585318
md"### Analysis"

# ╔═╡ c880b360-30e6-43b4-a484-5d0e6e778233
md"""
Incidence Matrix

D = D- - D+-
"""

# ╔═╡ 327bb59d-7426-47a3-9cda-01986d6e89e1


# ╔═╡ 4c4c48e6-6a26-4a7a-b1b0-343b2a8c75db
md"S, T Invariantrs"

# ╔═╡ 00125b01-60ef-4602-b7a7-4443a38a665c
md"Coverability Tree"

# ╔═╡ 3d5a2730-d9ca-4b4c-a193-173403dd6dee
md"Reachability Graph"

# ╔═╡ 8e740237-eb79-45d1-a974-c026cc827820


# ╔═╡ Cell order:
# ╠═f4c883b8-e2e9-11ec-28de-addab043979e
# ╠═f87a98af-6af6-4a0a-819b-3e472eafe54a
# ╠═812bda06-fd40-4b65-b5fa-0aae0c2c8832
# ╟─41566501-e86b-41af-bd01-2d2f999cc54f
# ╠═602978fa-4e05-4546-b205-d027880f0ccd
# ╠═221681e3-656d-4fa1-8425-cece133df01d
# ╠═ccb4e098-51b1-46dd-b563-1074a7ea9d82
# ╠═9f5d18d5-f8b7-44d2-8ddf-8b38be57a0a4
# ╟─f282f10d-8e6a-462e-be8a-4c072df82d0a
# ╠═0e9edbf3-df2c-474b-b747-6789dac7a398
# ╠═7d77e7ca-ad32-435a-895e-697dc91c340d
# ╠═c163301f-964e-4b79-b5f2-39c7bb17d085
# ╠═7fc99e91-963a-4ffc-bea3-c54adc652c78
# ╠═596c2657-01ce-4f0a-99d6-10aeae963271
# ╠═a127b05a-fcea-4712-be3c-03f96739de82
# ╠═9b6e1948-e841-42b3-b315-e08b136bf047
# ╠═c6e10d0d-019d-4fac-98a9-8774dce3af18
# ╠═c4802576-8425-4e66-aa3d-3fdb405a315e
# ╠═1ae71749-88eb-4b76-9ba0-901892bce079
# ╠═8ed47098-345d-46d6-aaec-1799ce2f3264
# ╠═715e160e-e1cc-4cf8-9f0e-283146abb17f
# ╠═f16359db-8e21-42ae-bb4d-eb8a6a75b992
# ╠═2700ad27-4a1e-4410-b9c3-e288059473f9
# ╠═9c706202-e11b-410e-bf73-f3b66cdd9c77
# ╠═1cfda3d4-e653-4629-b377-cad4ea8ce85a
# ╠═5229c597-0941-465b-abbf-fb1f76595bd4
# ╠═ed61c205-1b45-45f2-b6fa-76095e7c898e
# ╟─13b8de0b-84ee-4ba8-abba-0fe353df206c
# ╟─a7990ebd-2d2a-4174-9b4c-173489dd4d83
# ╠═22a5da67-b163-4cde-9a8b-9231b0585318
# ╠═c880b360-30e6-43b4-a484-5d0e6e778233
# ╠═327bb59d-7426-47a3-9cda-01986d6e89e1
# ╠═4c4c48e6-6a26-4a7a-b1b0-343b2a8c75db
# ╠═00125b01-60ef-4602-b7a7-4443a38a665c
# ╠═3d5a2730-d9ca-4b4c-a193-173403dd6dee
# ╠═8e740237-eb79-45d1-a974-c026cc827820
