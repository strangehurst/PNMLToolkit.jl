using Test, SafeTestsets, Pkg

@show ARGS
isempty(ARGS) && push!(ARGS, "ALL")

Pkg.test("PNML"; test_args=ARGS)
Pkg.test("PNet"; test_args=ARGS)
