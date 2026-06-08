#=
There are many attribute-label elements.
The common usage is that 'label' usually be read as annotation-label.

Attribute-labels do not have associated graphics elements. Since <graphics> are
optional for annotation-labels they share the same implementation.

Unknown tags get parsed by `xmldict`.
=#


"""
    parse_declaration!(net::AbstractPnmlNet, nodes::Vector{XMLNode}) -> Declaration

Fill `decldict(net)`] from one or more `<declaration>` labels.

Expected format: `<declaration> <structure> <declarations> <namedsort/> <namedsort/> ...`

Assume behavior with the meaning in a <structure> for all nets.

Note the use of both declaration and declarations, which comes from ISO 15909 Standard.
We allow repeated declaration (without the s) here.
All fill the same `DeclDict`. See [`fill_decl_dict!`](@ref)
"""
function parse_declaration!(net::AbstractPnmlNet, nodes::Vector{XMLNode})
    text = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}}  = nothing
    for node in nodes
        check_nodename(node, "declaration")
        for child in EzXML.eachelement(node)
            tag = EzXML.nodename(child)
            if tag == "structure"
                fill_decl_dict!(net, child) # accumulate '<declarations>'
            elseif tag == "text" && isnothing(text) # no overwrite if repeated
                text = string(strip(EzXML.nodecontent(child)))::String
                # Do not expect text here, so it must be important?
                # @info "declaration text: $text"
            elseif tag == "graphics" && isnothing(graphics) # no overwrite if repeated
                graphics = parse_graphics(child, pntd_of(net))
            elseif tag == "toolspecific"
                toolspecinfos = add_toolinfo(toolspecinfos, child, net)
            else
                @warn "ignoring unexpected child of <declaration>: '$tag'"
            end
        end
    end

    Declaration(; text, ddict=decldict(net), graphics, toolspecinfos)
end

"""
    fill_decl_dict!(net::AbstractPnmlNet, node::XMLNode) -> Nothing

Add a `<declaration><structure><declarations>` to DeclDict.
`<declaration>` may be attached to `<net>` and/or `<page>` elements.
Are network-level values even if attached to pages.
"""
function fill_decl_dict!(net::AbstractPnmlNet, node::XMLNode)
    check_nodename(node, "structure")
    EzXML.haselement(node) ||
        throw(ArgumentError("missing <declaration><structure> element"))
    declarations = EzXML.firstelement(node) # Only child node must be `<declarations>`.
    check_nodename(declarations, "declarations")
    unknown_decls = Any[]

    for child in EzXML.eachelement(declarations)
        tag = EzXML.nodename(child)
        if tag == "namedsort"
            ns = parse_namedsort(child, net)
            has_namedsort(net, pid(ns)) || @error "missing namedsort: $ns"
            #namedsorts(net)[pid(ns)] = ns
        elseif tag == "namedoperator"
            no = parse_namedoperator(child, net)
            has_namedop(net, pid(no)) && @warn "overwrite namedoperator $no"
            namedoperators(net)[pid(no)] = no
        elseif tag == "variabledecl"
            vardecl = parse_variabledecl(child, net)
            variabledecls(net)[pid(vardecl)] = vardecl
        elseif tag == "partition"
            # NB: partition is a declaration of a new sort refering to the partitioned sort.
            part = parse_partition(child, net)::SortRef
            has_partitionsort(net, part) || error("no parition sort found: $part")
            @assert is_namedsort(part) "expected partition sort found: $part"
        #! elseif tag === :partitionoperator
        #!      PartitionLessThan, PartitionGreaterThan, PartitionElementOf
        #!      partop = parse_partition_op(child, pntd)
        #!      partitionops(net)[pid(partop)] = partop

        elseif tag == "arbitrarysort"
            arb = parse_arbitrarysort(child, net)::SortRef
            has_arbitrarysort(net, arb) || error("no arbitrary sort found: $arb")
            @assert is_namedsort(arb) "expected arbitrary sort found: $arb"
       else
            push!(unknown_decls, parse_unknowndecl(child, net))
        end
    end
    return nothing
end

"""
    parse_declarations!(net::AbstractPnmlNet, node::XMLNode) -> Declaration

Collect a vector of `<declaration>` `XMLNodes`. Serves as function barrier.
NB: This is NOT where `<declarations>` are parsed, see [`fill_decl_dict!`](@ref) .
"""
function parse_declarations!(net::AbstractPnmlNet, node::XMLNode)
    decls = alldecendents(node, "declaration") # There may be none (empty vector).
    D()&& println("## parse_declarations! $(length(decls)) <declaration> node(s)")
    return parse_declaration!(net, decls)::Declaration
end

"""
$(TYPEDSIGNATURES)

Declaration that wraps a Sort, adding an ID and name.
"""
function parse_namedsort(node::XMLNode, net::AbstractPnmlNet)
    check_nodename(node, "namedsort")
    # Will have created a namedsort for builtin sorts.
    # Replacement of those, in particular :dot, will trigger a `DuplicateIdException`
    # unless the builtin sorts are excluded.
    # So we re-implement `register_idof!` with that check added.
    EzXML.haskey(node, "id") || throw(MissingIDException(EzXML.nodename(node)))
    sort_id = Symbol(@inbounds(node["id"]))
    if !Sorts.is_builtinsort(sort_id)
        register_id!(net.idregistry, sort_id)
    end
    name = attribute(node, "name")

    child = EzXML.firstelement(node)
    isnothing(child) &&
        error("no sort definition element for namedsort $sort_id $name")

    D()&& println("## parse_namedsort $sort_id $name")
    # Sort can be built-in, multiset, product.
    namedsort_def = parse_sort(EzXML.firstelement(node), net, sort_id, name)::SortRef
    isnothing(namedsort_def) &&
        error("failed to parse sort definition of namedsort $sort_id $name")

    # convert SortRef to concrete sort object.
    sort = to_sort(namedsort_def, net)
    #^ NB: We wrap built-ins in a NamedSort to give them an id, name.
    #^ Assume any NamedSort found here, which is illegal in ISO 15909-2,
    #^ is being used to transport a sort definition.
    if isa(sort, NamedSort)
        sort = sortdefinition(sort) # extract concrete sort
    end
    NamedSort(sort_id, name, sort, net) #^ in parse_namedsort
end

"""
$(TYPEDSIGNATURES)

Declaration of an operator expression in many-sorted algebra.

An operator of arity 0 is a constant (ground-term, literal).
When arity > 0, the parameters are variables, using a NamedTuple for values.
"""
function parse_namedoperator(node::XMLNode, net::AbstractPnmlNet)
    check_nodename(node, "namedoperator")
    operator_id = register_idof!(net.idregistry, node)
    name = attribute(node, "name")
    D()&& println("parse_namedoperator $operator_id $name") #! debug

    #^ ePNK uses inline variabledecl, variable in namedoperator declaration
    #! Must register id of variabledecl before seeing variable: `<parameter>` before `<def>`.
    parameters = VariableDeclaration{typeof(net)}[]
    pnode = firstchild(node, "parameter")
    if !isnothing(pnode)
        # Zero or more parameters for operator (arity). Map from id to sort object.
        for vdeclnode in EzXML.eachelement(pnode)
            vardecl = parse_variabledecl(vdeclnode, net)
            variabledecls(net)[pid(vardecl)] = vardecl # parse_namedoperator
            push!(parameters, vardecl)
        end
    end
    D()&& @show parameters #! debug, empty vector allowed

    dnode = firstchild(node, "def")
    # NamedOperators have a def element that is a  term/expression of existing
    # operators &/or variable parameters that define the operation.
    # The sort of the operator is the output sort of def.
    if !isnothing(dnode)
        # contains 1 term
        definition_tj = parse_term(EzXML.firstelement(dnode), net; vars=())::TermJunk
    else
        ERR_MSG ="<namedoperator name=$name id=$operator_id> does not have a <def> element"
        throw(MalformedException(ERR_MSG))
    end

    isempty(definition_tj.vars) ||
        @error("<namedoperator name=$name id=$operator_id> has variables: ", definition_tj)
    @warn "operators are a work in progress"
    NamedOperator(operator_id, name, parameters, definition_tj.exp, net)
end


#=
From ePNK-pnml-examples/NetworkAlgorithms/runtimeValueEval.pnml.

<namedoperator id="id3" name="sum">
    <parameter> <!-- as many variabledecls as operator has variable subterms. -->
        <variabledecl id="id4" name="x"> <integer/> </variabledecl>
        <variabledecl id="id5" name="y"> <integer/> </variabledecl>
    </parameter>
    <def>
        <addition><!-- existing operator -->
            <subterm> <variable refvariable="id4"/> </subterm>
            <subterm> <variable refvariable="id5"/> </subterm>
        </addition>
    </def>
</namedoperator>
=#

"""
    parse_variabledecl(node::XMLNode, net::AbstractPnmlNet) -> VariableDeclaration

Variable declarations associate an `id`, `name` and `sort`.
Stored in DeclDict with key of `id`.

Variable declarationss may appear in the definition of an operator
as well as directly in a declaration.

'<variabledecl>s' are referenced by '<variable>s' in terms.

Variables are used during enabling/firing a transition to identify tokens
removed from input place markings, added to output place markings.

Variables are used to substitute tokens into expressions when evaluating terms.
"""
function parse_variabledecl(node::XMLNode, net::AbstractPnmlNet)
    check_nodename(node, "variabledecl")
    var_id = register_idof!(net.idregistry, node)
    name = attribute(node, "name")
    D()&& println("## parse_variabledecl $var_id $name") #! debug
    # firstelement throws on nothing. Ignore more than 1.
    var_sortref = parse_sort(EzXML.firstelement(node), net, var_id, name)::SortRef
    isnothing(var_sortref) &&
        error("failed to parse sort definition for variabledecl $var_id $name")
    VariableDeclaration{typeof(net)}(var_id, name, var_sortref, net)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_unknowndecl(node::XMLNode, net::AbstractPnmlNet)
    nn = EzXML.nodename(node)
    decl_id = register_idof!(net.idregistry, node)
    name = attribute(node, "name")
    content = anyelement(decl_id, node)
    @warn("parse unknown declaration: tag = $nn, id = $decl_id, name = $name", content)
    return UnknownDeclaration(decl_id, name, nn, content, net)
end

"""
    parse_feconstants(::XMLNode, net::AbstractPnmlNet, ::SortRef) -> Vector{Symbol}

Place the constants into `feconstants(net)` dictionary and return vector of
finite enumeration constant REFIDs.

Access as 0-ary operator indexed by REFID
"""
function parse_feconstants(node::XMLNode, net::AbstractPnmlNet, sortref::SortRef)
    sorttag = EzXML.nodename(node)
    @assert sorttag in ("finiteenumeration", "cyclicenumeration") #? partition also?
    EzXML.haselement(node) ||
        throw(MalformedException("$sorttag has no child element"))

    feconstant_refids = Symbol[]
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag != "feconstant"
            throw(MalformedException("$sorttag has unexpected child element $tag"))
        else
            feconst_id = register_idof!(net.idregistry, child)
            name = attribute(child, "name")
            feconstants(net)[feconst_id] = FEConstant(feconst_id, name, sortref)
            push!(feconstant_refids, feconst_id)
        end
    end
    return feconstant_refids
end

"""
$(TYPEDSIGNATURES)

Return [`SortRef`](@ref) wraping the REFID of a
`NamedSort`, `ArbitrarySort`, or `PartitionSort` declaration.
"""
function parse_usersort(node::XMLNode, net::AbstractPnmlNet)
    check_nodename(node, "usersort")
    decl_id = Symbol(attribute(node, "declaration"))

    # <usersort> holds a reference to a declaration: named, partition, arbitrary.
    # We extract that information and encode it in the SortRefImpl ADT.
    if has_namedsort(net, decl_id)
        NamedSortRef(decl_id)
    elseif has_partitionsort(net, decl_id)
        PartitionSortRef(decl_id)
    elseif has_arbitrarysort(net, decl_id)
        ArbitrarySortRef(decl_id)
    else
        error("Did not find sort declaration for $decl_id")
    end
end

"""
$(TYPEDSIGNATURES)

Returns concrete [`SortRef`](@ref) wraping the REFID of a [`ArbitrarySort`](@ref).
"""
function parse_arbitrarysort(node::XMLNode, net::AbstractPnmlNet)
    check_nodename(node, "arbitrarysort")
    arb_id = register_idof!(net.idregistry, node)
    name = attribute(node, "name")

    @warn("parse arbitrarysort: id = $arb_id, name = $name")
    arb = ArbitrarySort(arb_id, name, net)
    fill_sort_tag!(net, arb_id, arb)
    @assert has_arbitrarysort(net, arb_id) "did not find arbitrary sort $arb_id"
    namedsorts(net)[arb_id] = NamedSort(arb_id, string(arb_id), arb, net)
    return make_sortref(net, arbitrarysorts, arb, "arbitrarysort", arb_id, "")
end

#=
- Some sorts are anonymous (have no id) in the XML.
- NB: sort equality is structural (`==` not `===`).
- We invent a REFID/name duo for anonymous sorts (and built-in sorts)
    with a NamedSort holding the concrete sort.
=#

"""
    parse_sort([:Val{:tag},] node::XMLNode, net::AbstractPnmlNet,
                id::Maybe{REFID}=nothing, name::String="") -> SortRef


Where `tag` is the XML element tag name. Used to dispatch to a specialized parser.

#TODO `id`, `name` are added by/for declarations, anonymous sorts.

See also [`parse_sorttype_term`](@ref), [`parse_namedsort`](@ref), [`parse_variabledecl`](@ref).
"""
function parse_sort end

function parse_sort(node::XMLNode, net::AbstractPnmlNet, sortid::Maybe{REFID}=nothing,  name::String="")
    # Note: Sorts are NOT PNML labels. Will NOT have <text>, <graphics>, <toolspecific>.
    sorttag = Symbol(EzXML.nodename(node))
    D()&& println("## parse_sort $sorttag id=$sortid name=$name tag=$sorttag") #! debug
    return parse_sort(Val(sorttag), node, net, sortid, name)::SortRef
end

# Built-ins sorts
# ! 2025-07-21 SortRef refactor, make these return a direct NamedSortRef.
#! The insertion into decldict in done in `fill_sort_tag!` from `fill_builtin_sorts!`
#! as initial part of `PnmlNet` parsing.
#! Followed by parsing all declarations where `parse_sort is used`.
#! Then the net where terms use sorts.

function parse_sort(::Val{:bool}, _node::XMLNode, _net::AbstractPnmlNet, _sortid, _name)
    NamedSortRef(:bool)
end

function parse_sort(::Val{:integer}, _node::XMLNode, _net::AbstractPnmlNet, _sortid, _name)
    NamedSortRef(:integer)
end

function parse_sort(::Val{:natural}, _node::XMLNode, _net::AbstractPnmlNet, _sortid, _name)
    NamedSortRef(:natural)
end

function parse_sort(::Val{:positive}, _node::XMLNode, _net::AbstractPnmlNet, _sortid, _name)
    NamedSortRef(:positive)
end

function parse_sort(::Val{:real},  _node::XMLNode, _net::AbstractPnmlNet, _sortid, _name)
    NamedSortRef(:real)
end

# In the ISO 15909 standard <usersort> wraps a REFID to a
# NamedSort , ArbitrarySort, or PartitionSort declaration.
#
# We use `NamedSort` declarations to instantiate built-in sorts. The user assumes they
# have the expected and obvious REFID/name duo.

# NB: ePNK examples uses some inlined sorts

function parse_sort(::Val{:dot}, _node::XMLNode, _net::AbstractPnmlNet, _sortid, _name)
    NamedSortRef(:dot) # The user overrides in a declaration.
end

function parse_sort(::Val{:usersort}, node::XMLNode, net::AbstractPnmlNet, _sortid, _name) #! see parse_namedsort
    parse_usersort(node, net)
end

# Any REFID in the input XML must take precedence.
# ? Can multiple REFIDs refer to the same sort? Yes, ISO 15909 says id/name are optional.
# Sorts are expected to be comaparable for equality, that is what matters,
# and specificially inline sorts are allowed and expected in some places.
# Assume parsing is a smallish up-front cost; enabling & firing rules is the big work.
# It is more important (for the big work) to be cache-friendly.
#
#? When is the REFID of a sort meaninful?
#  - Index into DeclDict to access concrete sort object
#       2 or more concrete sort objects (2 entries in dictionary) may be `equalSorts`
#  -



# is a finiteenumeration with additional operators: successor, predecessor
function parse_sort(::Val{:cyclicenumeration}, node::XMLNode, net::AbstractPnmlNet, sort_id, name)
    check_nodename(node, "cyclicenumeration")
    D()&& println("cyclicenumeration $(repr(sort_id)), $(repr(name))") #! debug
    @assert !isnothing(sort_id) "missing enclosing sort id"
    fec_ids = parse_feconstants(node, net, NamedSortRef(sort_id))
    cesort = CyclicEnumerationSort(fec_ids)
    #ce_id = gensym("cyclicenumeration")
    !isregistered(net.idregistry, sort_id) && register_id!(net.idregistry, sort_id)
    namedsorts(net)[sort_id] = NamedSort(sort_id, String(sort_id), cesort, net)
    return make_sortref(net, namedsorts, cesort, "cyclicenumeration", sort_id, name)
end

function parse_sort(::Val{:finiteenumeration}, node::XMLNode, net::AbstractPnmlNet, sort_id, name)
    check_nodename(node, "finiteenumeration")
    D()&& println("finiteenumeration $(repr(sort_id)), $(repr(name))") #! debug
    @assert !isnothing(sort_id) "missing enclosing sort id"
    fec_ids = parse_feconstants(node, net, NamedSortRef(sort_id))
    fesort = FiniteEnumerationSort(fec_ids)
    #@show fe_id = gensym("finiteenumeration")
    !isregistered(net.idregistry, sort_id) && register_id!(net.idregistry, sort_id)
    namedsorts(net)[sort_id] = NamedSort(sort_id, String(sort_id), fesort, net)
    return make_sortref(net, namedsorts, fesort, "finiteenumeration", sort_id, name)
end

function parse_sort(::Val{:finiteintrange}, node::XMLNode, net::AbstractPnmlNet, _parentid, name)
    check_nodename(node, "finiteintrange")
    D()&& println("finiteintrange $(repr(_parentid)), $(repr(name))") #! debug

    startstr = attribute(node, "start")
    startval = tryparse(Int, startstr)
    isnothing(startval) &&
        throw(ArgumentError("start attribute value '$startstr' failed to parse as `Int`"))

    stopstr = attribute(node, "end") # XML Schema uses 'end', we use 'stop'.
    stopval = tryparse(Int, stopstr)
    isnothing(stopval) &&
        throw(ArgumentError("stop attribute value '$stopstr' failed to parse as `Int`"))

    # See function parse_term(::Val{:finiteintrangeconstant} for inline sort use.
    # Look for `sort` in `namedsorts(net)`, else create named/user duo.
    sorttag = isnothing(_parentid) ? Symbol("FiniteIntRange_",startstr,"_",stopstr) : _parentid
    if haskey(namedsorts(net), sorttag)
        return NamedSortRef(sorttag)
    else
        # Did not find namedsort, will instantiate named,user duo for one. See fill_builtin_sorts!
        sort = FiniteIntRangeSort(startval, stopval)
        !isregistered(net.idregistry, sorttag) && register_id!(net.idregistry, sorttag)
        namedsorts(net)[sorttag] = NamedSort(sorttag, String(sorttag), sort, net)
        sref = make_sortref(net, namedsorts, sort, "finiteintrange", sorttag, name)
        D()&& @show sref net
        @assert is_namedsort(sref)
        return sref
    end
end

#   <namedsort id="id2" name="MESSAGE">
#     <productsort>
#       <usersort declaration="id1"/>
#       <natural/>
#     </productsort>
#   </namedsort>

#TODO inline sort like FiniteIntRangeSort, but <tuple> may use non-ground terms to deduce.
#TODO tuples may be nested.
#TODO <tuple> is operator, subterms are expressions (terms) that have sortrefs.


function parse_sort(::Val{:list}, node::XMLNode, net::AbstractPnmlNet, parentid, name)
    check_nodename(node, "list")
    @error("IMPLEMENT ME: :list for pntd=$(pntd_of(net))")
    ls = ListSort(NamedSortRef(:dot)) #! Made up, until we parse `node!
    ls_id = gensym("list")
    !isregistered(net.idregistry, ls_id) && register_id!(net.idregistry, ls_id)
    namedsorts(net)[ls_id] = NamedSort(ls_id, String(ls_id), ls, net)
    sref = make_sortref(net, namedsorts, ls, "list", ls_id, name)
    return sref
end

function parse_sort(::Val{:string}, node::XMLNode, net::AbstractPnmlNet, parentid, name)
    check_nodename(node, "string")
    ss = StringSort()
    ss_id = gensym("string")
    !isregistered(net.idregistry, ss_id) && register_id!(net.idregistry, ss_id)
    namedsorts(net)[ss_id] = NamedSort(ss_id, String(ss_id), ss, net)
    sref = make_sortref(net, namedsorts, ss, "string", ss_id, name)
    return sref
end

function parse_sort(::Val{:multisetsort}, node::XMLNode, net::AbstractPnmlNet, sort_id, name)
    check_nodename(node, "multisetsort")
    EzXML.haselement(node) || throw(ArgumentError("multisetsort missing basis sort"))

    # Expect basis to be a <usersort> wrapping <namedsort> for symmetricnet,
    # but not <partition> or <partitionelement>. Definitely not another multiset.
    # NB: We wrap built-in sorts in a user/named duo.
    #^ ePNK highlevelnet inlines product sort inside a place `<type><structure><multisetsort>`
    # maybe someday <arbitrary## parse_sort multisetsort id=nothing name= tag=:multisetsortsort>

    basis_node = EzXML.firstelement(node) # Assume basis sort will be first and only child.
    tag = Symbol(EzXML.nodename(basis_node))

    tag in (:partition, :partitionelement, :multisetsort) &&
        throw(ArgumentError("multisetsort basis of $tag not allowed")) #todo test this!
    basis_sort = parse_sort(Val(tag), basis_node, net, nothing, "")::SortRef
    @assert is_namedsort(basis_sort)
    #D()&& @warn "parse_sort(::Val{:multisetsort}" basis_sort sortdefinition(to_sort(basis_sort, net))
    #!isnothing(sortid) && @error "inlined multiset" net
    ms = MultisetSort(basis_sort, net)
    # make a named sort duo
    namedsorts(net)[sort_id] = NamedSort(sort_id, string(sort_id),
                                         ms, net)
   return make_sortref(net, multisetsorts, ms, "multiset", sort_id, name)
end

function parse_sort(::Val{:productsort}, node::XMLNode, net::AbstractPnmlNet, sort_id, name)
    check_nodename(node, "productsort")
    isnothing(sort_id) && error("parse_sort(::Val{:productsort} sort id is nothing") #! debug

    sorts = [] # Orderded collection of zero or more Sorts in ISO 15909 Standard.
    for child in EzXML.eachelement(node)
        tag = Symbol(EzXML.nodename(child))
        push!(sorts, parse_sort(Val(tag), child, net, nothing, "")::SortRef)
    end
    isempty(sorts) &&
        @warn "ISO 15909 Standard allows a <productsort> to be empty. And somebody did!"
    # What is the use of an empty productsort? bottom?

    prod_sort = ProductSort(tuple(sorts...), net)

    # See if there exists a matching sort. #! debug?
    for (id,ps) in pairs(productsorts(net))
        if equalSorts(net, ps, prod_sort)
            @info "Found product sort $id while looking for $prod_sort " *
                    "for sortid=$sort_id name=$name" productsorts(net)
         end
    end
    #@warn sort_id prod_sort
    fill_sort_tag!(net, sort_id, prod_sort) # add to productsorts without a sortref
    @assert productsorts(net)[sort_id] == prod_sort
    # make a named sort duo
    namedsorts(net)[sort_id] = NamedSort(sort_id, string(sort_id),
                                         prod_sort, net)
    sr = make_sortref(net, productsorts, prod_sort, "product", sort_id, name)
    #!@show sr net
    #!println("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^")
    return sr
end #= function parse_sort :productsort =#

#=
Partition # id, name, usersort, partitionelement[]
=#
function parse_partition(node::XMLNode, net::AbstractPnmlNet) #! a sort declaration!
    partition_id = register_idof!(net.idregistry, node)
    nameval = attribute(node, "name")
    D()&& println("## parse_partition $partition_id $nameval")
    partitioned_sortref::Maybe{SortRef} = nothing
    elements = PartitionElement[] # References into partitioned_sortref that form a equivalance class.
    for part_child in EzXML.eachelement(node)
        tag = EzXML.nodename(part_child)
        if tag == "usersort" # The sort that partitionelements reference into.
            # The only non-partitionelement child possible,
            partitioned_sortref = parse_usersort(part_child, net)::SortRef
            @assert is_namedsort(partitioned_sortref) string("RelaxNG Schema says: ",
                "defined over a NamedSort which it refers to. Found: ", partitioned_sortref)
        elseif tag === "partitionelement"
            # Each partitionelement holds REFIDs to elements of an enumeration sort.
            parse_partitionelement!(elements, part_child, partition_id; net)
        else
            throw(MalformedException(string("partition child element unknown: ", tag,
                                ". Allowed are usersort, partitionelement")))
        end
    end
    isnothing(partitioned_sortref) &&
        throw(ArgumentError("<partition id=$partition_id, name=$nameval> <usersort> element missing"))

    # One or more partitionelements.
    isempty(elements) &&
        error("partitions must have at least one partition element, found none: ",
                "id = ", repr(partition_id),
                ", name = ", repr(nameval),
                ", sort = ", repr(partitioned_sortref))

    part_sort = PartitionSort(partition_id, nameval, partitioned_sortref, elements, net)

    verify_partition(part_sort) || error("verify_partition failed: $part_sort")

    # add to productsorts
    fill_sort_tag!(net, partition_id, part_sort) # add to partitionsorts without a sortref
    @assert has_partitionsort(net, partition_id) "did not find partition sort $partition_id"
    # make a named sort duo
    namedsorts(net)[partition_id] = NamedSort(partition_id, string(partition_id),
                                              part_sort, net)
    return make_sortref(net, partitionsorts, part_sort, "partition", partition_id, "")
end #= function parse_partition =#

"""
    parse_partitionelement!(elements::Vector{PartitionElement}, node::XMLNode rid::REFID; net::AbstractPnmlNet)

Parse a `<partitionelement>` XML node,
add FEConstant refids to the element and append element to the vector.
"""
function parse_partitionelement!(elements::Vector{PartitionElement}, node::XMLNode,
                                    rid::Symbol; net::AbstractPnmlNet)
    check_nodename(node, "partitionelement")
    element_id = register_idof!(net.idregistry, node)
    nameval = attribute(node, "name")
    terms = REFID[] # Ordered collection, usually feconstant.
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag === "useroperator"
            # PartitionElements refer to the FEConstants of the referenced enumeration sort.
            # UserOperator here holds an REFID to a FEConstant object.
            decl_id = Symbol(attribute(child, "declaration"))
            has_feconstant(net, decl_id) ||
                error("declaration id $decl_id not found in feconstants") #! move to verify?
            push!(terms, decl_id)
        else
            # Are ProductSorts allowed?
            throw(MalformedException("partitionelement child element unknown: $tag"))
        end
    end
    isempty(terms) &&
        throw(ArgumentError("<partitionelement id=$element_id, name=$nameval> has no terms"))
    # rid is REFID to enclosing partition
    push!(elements, PartitionElement(element_id, nameval, terms, rid))
    return elements
end
