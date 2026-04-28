#!--------------------
#! see decldictcore.jl for  struct DeclDict
#!--------------------

function Base.show(io::IO, dd::ADDicts)

    println(io, nameof(typeof(dd)), "(")

    io = inc_indent(io)
    iio = inc_indent(io)

    print(io, indent(io), "NamedSort[")
    print(iio, keys(namedsorts(dd)))
    println(io, "]")

    print(io,  indent(io), "NamedOperator[")
    print(iio, keys(namedoperators(dd)))
    println(io, "]")

    print(io,  indent(io), "VariableDeclaration[")
    print(iio, values(variabledecls(dd)))
    println(io, "]")

    print(io,  indent(io), "MultisetSort[")
    print(iio, keys(multisetsorts(dd)))
    println(io, "]")

    print(io,  indent(io), "ProductSort[")
    print(iio, keys(productsorts(dd)))
    println(io, "]")

    print(io,  indent(io), "PartitionSort[")
    print(iio, keys(partitionsorts(dd)))
    println(io, "]")

    print(io,  indent(io), "PartitionElement[")
    print(iio, keys(partitionops(dd)))
    println(io, "]")

    print(io,  indent(io), "ArbitrarySort[")
    print(iio, keys(arbitrarysorts(dd)))
    println(io, "]")

    print(io,  indent(io), "ArbitraryOperator[")
    print(iio, keys(arbitraryops(dd)))
    println(io, "]")

    print(io,  indent(io), "FEConstant[")
    print(iio, values(feconstants(dd)))
    println(io, "]")

    print(io, ")")
end
