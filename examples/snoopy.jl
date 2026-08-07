#!/usr/bin/env bash
# -*- mode: julia -*-
#=
exec julia --startup-file=no -q --project=.
=#

using PNML, EzXML
#using SnoopCompileCore
#using Profile, ProfileView

str = """<?xml version="1.0"?>
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
const pnmlroot = PNML.xmlnode(str)

#tinf = @snoopi_deep begin end
function test1(proot, n=10)
    for i in 1:n
        model = parse_pnml(proot, registry())
    end
end

#test1(pnmlroot)
#PnmlIDRegistrys.reset_reg!(reg)
#ProfileView.
#@profview test1(pnmlroot)
#@profview registry()
