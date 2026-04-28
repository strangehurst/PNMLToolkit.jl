"""
$(TYPEDEF)
$(TYPEDFIELDS)

Variable refers to a [`VariableDeclaration`](@ref).
Example input: <variable refvariable="varx"/>.

#TODO examples of use, modifying and accessing
"""
struct Variable{N <: APN} <: AbstractVariable
    refvariable::Symbol # of VariableDeclaration{N} that gives name and Type
    net::N

    function Variable(v::Symbol, net::APN)
        # Check that REFID is valid in DeclDict.
        has_variabledecl(net, v) ||
            throw(ArgumentError("$(v) not a variable reference ID"))
        new{typeof(net)}(v, net)
    end
end

refid(v::Variable) = v.refvariable

function (var::Variable)()
    value(var)
end
value(v::Variable) = error("not well defined: value($v)") #! XXX FIXME XXX
sortref(v::Variable) = sortref(variabledecl(v.net, refid(v)))::SortRef

function Base.show(io::IO, v::Variable)
    print(io, nameof(typeof(v)), "(", repr(v.refvariable), ")")
end
