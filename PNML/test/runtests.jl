using PNML, Test, SafeTestsets
using OrderedCollections
using Documenter
using JET, Aqua

@show ARGS

# Use default display width for printing.
if !haskey(ENV, "COLUMNS")
    ENV["COLUMNS"] = 180
end

include("TestUtils.jl")
using .TestUtils

isempty(ARGS) && push!(ARGS, "ALL")
"Return true if `ARGS` is empty or one of `y`  and none of `n` is found in `ARGS`."
select(y::Tuple, n::Tuple=()) = any(∈(ARGS), y) && !any(∈(ARGS), n)
select(y, n) = select(y, tuple(n))
select(y::AbstractString) = select(tuple(y))

const FAILFAST = parse(Bool, get(ENV, "JULIA_TEST_FAILFAST", "true"))
@show FAILFAST

#############################################################################
@time "TESTS" begin
@testset verbose=true failfast=FAILFAST showtiming=true "PNML.jl" begin
    if !isempty(ARGS) && select("NONE")
        return nothing # Have chosen to bail before any tests.
    end
    if select(("ALL","AQUA"), "!AQUA")
        @testset "Aqua" begin
            Aqua.test_all(PNML;
                ambiguities=(recursive=false),
                #unbound_args=true,
                #undefined_exports=true,
                #project_extras=true,
                stale_deps=(ignore=[:Compat],),
                #deps_compat=(ignore=[:Metatheory],),
                #project_toml_formatting=true,

                piracies=false,
                persistent_tasks=false, # Metatheory ale/3.0 is not in registry
            )
        end
    end
    if select(("ALL", "BASE"), "!BASE")
        println("# BASE #")
        @safetestset "typedefs"  begin include("typedefs.jl") end
        @safetestset "registry"  begin include("idregistry.jl") end
        @safetestset "utils"     begin include("utils.jl") end
    end
    if select(("ALL", "REWRITE"), "!REWRITE")
        println("# REWRITE #")
        @safetestset "rewrite"     begin include("rewrite.jl") end
    end
    if select(("ALL", "CORE"), "!CORE")
        println("# CORE #")
        @safetestset "graphics"     begin include("graphics.jl") end
        @safetestset "toolspecific" begin include("toolspecific.jl") end
        @safetestset "labels"       begin include("labels.jl") end
        @safetestset "labels_hl"    begin include("labels_hl.jl") end

        @safetestset "initialMarkings" begin include("initialMarkings.jl") end
        @safetestset "inscriptions"    begin include("inscriptions.jl") end
        @safetestset "conditions"      begin include("conditions.jl") end
        @safetestset "namelabel"       begin include("namelabel.jl") end
        @safetestset "sorttype"        begin include("sorttype.jl") end
        @safetestset "arctypes"        begin include("arctypes.jl") end
        @safetestset "times"           begin include("times.jl") end
        @safetestset "priorities"      begin include("priorities.jl") end
    end

    if select(("ALL", "CORE1"), ("!CORE1",))
        println("# CORE1 #")

        @safetestset "sorts"        begin include("sorts.jl") end
        @safetestset "declarations" begin include("declarations.jl") end
    end

    if select(("ALL", "CORE2"), ("!CORE2",))
        println("# CORE2 #")
        @safetestset "places"       begin include("places.jl") end
        @safetestset "transitions"  begin include("transitions.jl") end
        @safetestset "arcs"         begin include("arcs.jl") end
        @safetestset "pages"        begin include("pages.jl") end
        @safetestset "exceptions"   begin include("exceptions.jl") end
    end

    if select(("ALL", "CORE2", "FLAT"), ("!CORE2", "!FLAT"))
        @safetestset "flatten"      begin include("flatten.jl") end
    end

    if select(("ALL", "EXPR"), ("!EXPR",))
        println("# EXPR #")
        @safetestset "pnmlexpr"     begin include("pnmlexpr.jl") end
    end

    if select(("ALL", "NET1"), ("!NET1",))
        println("# NET1 #")
        @safetestset "pnmlmodel"     begin include("pnmlmodel.jl") end
    end

    if select(("ALL", "TEST1",), ("!TEST1",))
        println("# TEST1 #")
        @safetestset "test1"   begin include("test1.jl") end
    end

    if select(("ALL", "NET2"), ("!NET2",))
        println("# NET2 #")
        select(("ALL", "NET2", "sampleSNPrio",), ("!sampleSNPrio",)) &&
            @safetestset "sampleSNPrio"   begin include("sampleSNPrio.jl") end
        select(("ALL", "NET2", "fulls",), ("!fulls",)) &&
            @safetestset "fulls"          begin include("fulls.jl") end
        select(("ALL", "NET2", "sharedmemory",), ("!sharedmemory",)) &&
            @safetestset "sharedmemory"   begin include("sharedmemory.jl") end
    end
    if select(("TEST19",), ("!TEST19",)) #! Not part of ALL
        println("# TEST19 #")
        @safetestset "test19"   begin include("test19.jl") end
    end

     if select(("ALL", "NET3"), ("!NET3",))
        println("# NET3 #")
        @safetestset "rate"         begin include("rate.jl") end
        @safetestset "netapi"       begin include("netapi.jl") end
    end

    if select(("ALL", "DOC"), ("!DOC",))
        println("# DOC #")
        @testset "doctest" begin doctest(PNML, manual = true) end
    end
end
end # time
