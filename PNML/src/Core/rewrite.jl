
using Metatheory: @rule
#using Metatheory.TermInterface

multiset_alg = Metatheory.@theory p q begin
    (p::Bool == q::Bool) => (p == q) # evaluated during rewrite
end

bool_alg = Metatheory.@theory p q begin
    (p::Bool == q::Bool) => (p == q)
    (p::Bool || q::Bool) => (p || q)
    (p::Bool ⟹ q::Bool) => ((p || q) == q)
    (p::Bool && q::Bool) => (p && q)
    !(p::Bool)           => (!p)
    (p::BooleanConstant) => p() # evaluated during rewrite
end

dot = Metatheory.@theory d begin
    (d::DotConstant) => d()::Number # singelton multiset should be 1
end

pnml_theory = multiset_alg ∪ bool_alg ∪ dot #∪ negt ∪ impl ∪ fold

# Combinators

# SymbolicsUtils: `Assignment`, `Let`, `Func`, `SetArray`, `MakeArray`, `MakeSparseArray` and `MakeTuple`.
# MetaTheory: ./test/tutorials/lambda_theory.jl @matchable struct Let <: LambdaExpr
