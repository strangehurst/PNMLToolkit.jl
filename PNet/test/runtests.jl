using PNet, Test, SafeTestsets
using OrderedCollections
using Documenter
using JET, Aqua

@show ARGS

# Use default display width for printing.
if !haskey(ENV, "COLUMNS")
    ENV["COLUMNS"] = 180
end

#! include("TestUtils.jl")
#! using .TestUtils

isempty(ARGS) && push!(ARGS, "ALL")
"Return true if `ARGS` is empty or one of `y`  and none of `n` is found in `ARGS`."
select(y::Tuple, n::Tuple=()) = any(∈(ARGS), y) && !any(∈(ARGS), n)
select(y, n) = select(y, tuple(n))
select(y::AbstractString) = select(tuple(y))

const FAILFAST = parse(Bool, get(ENV, "JULIA_TEST_FAILFAST", "true"))
@show FAILFAST

#############################################################################
@time "TESTS" begin
@testset verbose=true failfast=FAILFAST showtiming=true "PNet" begin
    if !isempty(ARGS) && select("NONE")
        return nothing # Have chosen to bail before any tests.
    end
    if select(("ALL","AQUA"), "!AQUA")
        @testset "Aqua" begin
            Aqua.test_all(PNet;
                ambiguities=(recursive=false),
                unbound_args=true,
                undefined_exports=true,
                project_extras=true,
                stale_deps=(ignore=[:Compat],),
                #deps_compat=(ignore=[:Metatheory],),
                #project_toml_formatting=true,

                piracies=false,
                persistent_tasks=false, # Metatheory ale/3.0 is not in registry
            )
        end
    end
     if select(("ALL", "NET3"), ("!NET3",))
        println("# NET3 #")
        #! @safetestset "rate"         begin include("rate.jl") end
        @safetestset "simplenet"    begin include("simplenet.jl") end
        @safetestset "netapi"       begin include("netapi.jl") end
    end

    # if select(("ALL", "DOC"), ("!DOC",))
    #     println("# DOC #")
    #     @testset "doctest" begin doctest(PNet, manual = true) end
    # end
end
end # time
