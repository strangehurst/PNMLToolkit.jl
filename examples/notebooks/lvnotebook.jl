### A Pluto.jl notebook ###
# v0.19.32

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

# ╔═╡ a68432ac-b7eb-4985-8232-67bde7bcfd0a
# ╠═╡ show_logs = false
begin
	import Pkg
    Pkg.activate(Base.current_project())
    Pkg.instantiate()
	Pkg.add("PlutoUI")

	using PlutoUI
	using PNML, EzXML, LabelledArrays, OrdinaryDiffEq, Plots, Petri
end


# ╔═╡ e6e05790-dd20-11ec-39b0-eb0589d76e44
md"""
# PNML Lotka-Volterra Notebook
"""

# ╔═╡ 0143155c-a570-4a03-9cab-5704b7e49968


# ╔═╡ cff98b32-c6d1-4c4d-beba-ab46f9a54172
# ╠═╡ show_logs = false
TableOfContents(title="TOC", aside=true)

# ╔═╡ 97ed66fd-e8aa-4291-81f2-c4981c521862
# ╠═╡ show_logs = false
versioninfo()

# ╔═╡ 9420e502-ed69-443b-944b-9339f2e699b1
# ╠═╡ show_logs = false
Pkg.status()

# ╔═╡ 5db3c534-07dc-4a9d-8782-41423da2ccfe
md"""
## Scratchpad
"""

# ╔═╡ a995864c-937e-4a0d-b99a-31fd134e23dc
let
	d = PNML.PnmlLabel[]
	reg = registry()
	pntd = PnmlCoreNet()
	PNML.add_label!(d, PNML.xmlnode("<test1> 1 </test1>"), pntd)
	PNML.add_label!(d, PNML.xmlnode("<test2> 2.0 </test2>"), pntd)
	PNML.add_label!(d, PNML.xmlnode("<test3> true </test3>"), pntd)
end

# ╔═╡ ddacb450-31cb-4f7d-b62f-c81d0c2df858
md"""
## Step 1: Define the states and transitions of the Petri Net

Here we have 2 states, wolves and rabbits, and transitions to model predation between the two species in the system.
"""

# ╔═╡ 22a06164-6096-4a7e-a205-c1686c4b03d8
xml = """<?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        <net id="net0" type="nonstandard">
        <page id="page0">
            <place id="rabbits"> <initialMarking> <text>100.0</text> </initialMarking> </place>
            <place id="wolves">  <initialMarking> <text>10.0</text> </initialMarking> </place>
            <transition id ="birth">     <rate> <text>0.3</text> </rate> </transition>
            <transition id ="death">     <rate> <text>0.7</text> </rate> </transition>
            <transition id ="predation"> <rate> <text>0.015</text> </rate> </transition>
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

# ╔═╡ 706313c3-946c-46cd-a32d-05a4103ba9a4
md"""
## Step 2:Define the parameters and transition rates

Once a model is defined, we can define out initial parameters `u0`, a time
span `tspan`, and the transition rates of the interactions `β`.
"""

# ╔═╡ c8bf4d0a-f9a2-4a67-85f1-16ff4e53eea2
tspan = (0.0,100.0)

# ╔═╡ a3044403-467e-4002-9139-69dfefbf9990
md"""
## Step 3: Generate a solver and solve
Finally we can generate a solver and solve the simulation.
"""

# ╔═╡ 5979a601-8b07-4f33-a766-f8e3cd421891
md"""
birth rate $(@bind BR_slider Slider(0.0:0.01:1.0; show_value=true, default=0.3))
"""

# ╔═╡ db25d962-4bb3-44b2-b844-ae4e4b8a9f37
md"""
death rate $(@bind DR_slider Slider(0.0:0.01:1.0; show_value=true, default=0.7))
"""

# ╔═╡ 502fbe5a-8ef5-42d6-84b1-3bf09d8c4998
md"""
predatation rate $(@bind PR_slider Slider(0.0:0.001:0.2; show_value=true, default=0.015))
"""

# ╔═╡ 55da1e63-bdef-4eff-8353-48a2a0e4bb1c
xml2 = """<?xml version="1.0"?>
<pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
<net id="net0" type="continuous">
<page id="page0">
  <place id="rabbits"> <initialMarking>100.0</initialMarking> </place>
  <place id="wolves">  <initialMarking> <text>10.0</text> </initialMarking> </place>
  <transition id ="birth">     <rate> <text>$BR_slider</text> </rate> </transition>
  <transition id ="death">     <rate> <text>$DR_slider</text> </rate> </transition>
  <transition id ="predation"> <rate> <text>$PR_slider</text> </rate> </transition>
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

# ╔═╡ fa79b9c4-188a-4cde-9af3-b956cb0a60cd
net = PNML.SimpleNet(xml2)

# ╔═╡ a73fda08-7414-4d21-9f0e-0edf5f7cb876
# ╠═╡ show_logs = false
lotka = let
	# **Step 1:**
	@show S = PNML.place_idset(net) # [:rabbits, :wolves]
	@show Δ = PNML.transition_function(net)
	Petri.Model(S, Δ)
end;

# ╔═╡ c1dbe979-b219-452f-9f4c-0e4de84d4395
Graph(lotka)

# ╔═╡ 0c300670-010b-42c9-8f62-f681668050c3
u0 = PNML.initial_markings(net)

# ╔═╡ 2a1dc647-9aa8-4907-89f3-a15f13b45eb2
β = PNML.rates(net)

# ╔═╡ 3bc171e2-307d-4868-bd7a-e44857a1131e
prob = ODEProblem(lotka, u0, tspan, β)

# ╔═╡ 512a12f5-fd88-432b-9a56-880e2bf6879a
sol = OrdinaryDiffEq.solve(prob, Tsit5(), reltol=1e-6, abstol=1e-6)

# ╔═╡ 91f5cd89-8c4b-4ffb-958e-25dafebbf77d
plot(sol)

# ╔═╡ Cell order:
# ╟─e6e05790-dd20-11ec-39b0-eb0589d76e44
# ╠═0143155c-a570-4a03-9cab-5704b7e49968
# ╟─a68432ac-b7eb-4985-8232-67bde7bcfd0a
# ╠═cff98b32-c6d1-4c4d-beba-ab46f9a54172
# ╠═97ed66fd-e8aa-4291-81f2-c4981c521862
# ╠═9420e502-ed69-443b-944b-9339f2e699b1
# ╟─5db3c534-07dc-4a9d-8782-41423da2ccfe
# ╠═a995864c-937e-4a0d-b99a-31fd134e23dc
# ╟─ddacb450-31cb-4f7d-b62f-c81d0c2df858
# ╟─22a06164-6096-4a7e-a205-c1686c4b03d8
# ╠═55da1e63-bdef-4eff-8353-48a2a0e4bb1c
# ╠═fa79b9c4-188a-4cde-9af3-b956cb0a60cd
# ╟─a73fda08-7414-4d21-9f0e-0edf5f7cb876
# ╠═c1dbe979-b219-452f-9f4c-0e4de84d4395
# ╟─706313c3-946c-46cd-a32d-05a4103ba9a4
# ╟─0c300670-010b-42c9-8f62-f681668050c3
# ╟─2a1dc647-9aa8-4907-89f3-a15f13b45eb2
# ╟─c8bf4d0a-f9a2-4a67-85f1-16ff4e53eea2
# ╟─a3044403-467e-4002-9139-69dfefbf9990
# ╠═3bc171e2-307d-4868-bd7a-e44857a1131e
# ╠═512a12f5-fd88-432b-9a56-880e2bf6879a
# ╟─5979a601-8b07-4f33-a766-f8e3cd421891
# ╟─db25d962-4bb3-44b2-b844-ae4e4b8a9f37
# ╟─502fbe5a-8ef5-42d6-84b1-3bf09d8c4998
# ╟─91f5cd89-8c4b-4ffb-958e-25dafebbf77d
