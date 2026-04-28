"Utilities shared by SafeTestSets"
module TestUtils
using EzXML, Preferences, XMLDict, Reexport, Multisets
Multisets.set_key_value_show()

@reexport import Moshi
@reexport import Moshi.Match: @match
@reexport import Moshi.Data: @data, isa_variant, is_data_type, variant_type

@reexport using PNML
@reexport using PNML.Sorts
@reexport using PNML.Labels
@reexport using PNML.Labels: TokenGraphics, get_toolinfo, version, text
@reexport using PNML.Labels: PnmlLabel, get_label, Condition
@reexport using PNML.Parser: pnmlmodel, parse_net, parse_page!,
    parse_place, parse_arc, parse_transition, parse_refPlace, parse_refTransition,
    parse_name, parse_text, parse_graphics, parse_toolspecific,
    parse_initialMarking, parse_inscription, parse_sort,
    parse_declaration!, parse_declarations!,
    parse_hlinitialMarking, parse_hlinscription, parse_fifoinitialMarking
@reexport using PNML.Parser: to_sort, anyelement, xmldict
@reexport using PNML.Parser
@reexport using PNML.Parser: firstchild, allchildren, default
@reexport using PNML.Declarations
@reexport using PNML.IDRegistrys
@reexport using PNML.PnmlTypes
@reexport using PNML.PnmlGraphics
#!@reexport using PNML.PNet
@reexport using PNML: Maybe, DeclDict, XMLNode, xmlnode, @xml_str
@reexport using PNML: PnmlMultiset, pid, ispid,
    name, length, arity, tag, value, term, elements, value_type,
    graphics, has_graphics,
    XmlDictType, AnyElement,
    multiset,
    fill_sort_tag!,
    fill_builtin_labelparsers!, fill_builtin_sorts!, fill_builtin_toolparsers!
@reexport using PNML: toexpr, PnmlExpr, decldict
@reexport using PNML: PnmlException, MissingIDException, DuplicateIDException, MalformedException

#@reexport using PNML: Context

@reexport using PNML: PnmlNetData, PnmlNetKeys, netsets, netdata, pagedict,
    namedsorts, partitionsorts, arbitrarysorts,
    namedsort, partitionsort, arbitrarysort

@reexport using PNML: PnmlModel,
    PnmlNet, make_net, nets, nettype, registry_of, pntd,
    Page, pages, npages, firstpage, allpages, flatten_pages!,
    Place, place, places, nplaces,  has_place,
    Transition, transition, transitions, ntransitions, has_transition,
    RefPlace, refplace, refplaces, nrefplaces,
    RefTransition, reftransition, reftransitions, nreftransitions,
    Arc, arc, arcs, narcs, source, target, has_arc

@reexport using PNML: labels, varsubs, Coordinate

@reexport using PNML: page_idset, place_idset, transition_idset,
    arc_idset, refplace_idset, reftransition_idset
@reexport using PNML: pagedict, placedict, transitiondict, arcdict,
    refplacedict, reftransitiondict

@reexport using PNML: toolinfos, has_tools, get_label, cardinality

@reexport using PNML: AbstractDeclaration, Declaration, refid, inscription, condition

@reexport using PNML: AbstractSort, SortType, NamedSort, BoolSort, DotSort,
    CyclicEnumerationSort, FiniteEnumerationSort, FiniteIntRangeSort, PartitionElement,
    IntegerSort, NaturalSort, PositiveSort, RealSort,
    MultisetSort, ProductSort, PartitionSort, ListSort, StringSort, ArbitrarySort

@reexport using PNML: sortref, sortdefinition, sortelements, namedsort, initial_marking

@reexport using PNML: metagraph, vertex_codes, vertex_labels

@reexport using PNML: FEConstant, NumberConstant, BooleanConstant, DotConstant, DotConstantEx, zero
@reexport using PNML: AbstractTerm, AbstractVariable, AbstractOperator, inputs

@reexport using PNML: multiplicity

@reexport using PNML.Expressions

@reexport using PNML.SortRefImpl: UserSortRef, NamedSortRef, PartitionSortRef,
                    ProductSortRef, MultisetSortRef, ArbitrarySortRef


#!@reexport using PNet: initial_markings

"Run @test_opt, expect many dynamic dispatch reports."
const runopt::Bool = false

"Print a lot of information as tests run."
const noisy::Bool = false

"Only report for our module."
const t_modules = (PNML,)

"Allow test of print/show methods without creating a file."
const testshow = devnull # nothing turns off redirection

"Ignore some dynamically-designed functions."
function pff(@nospecialize ft)
    #if ft === typeof(IDRegistrys.register_id!) ||
    if  ft === Preferences.load_preference ||
        ft === EzXML.nodename ||
        ft === EzXML.namespace ||
        ft === Base.repr ||
        ft === Base.sprint ||
        ft === Base.string ||
        ft === Base.show ||
        ft === Base.print ||
        ft === Base.println ||
        ft === Base.show_backtrace ||
        ft === PNML.Parser.xmldict ||
        ft === XMLDict.xml_dict ||
        ft === PNML.Parser.anyelement ||
        ft === PNML.verify! ||
        ft === PNML.verify_ids! ||
        ft === PNML.fill_builtin_labelparsers! ||
        false
        return false

        #ft === PNML.Parser.__any_element ||
        #ft === PNML.Parser.add_label! ||
        #ft === Core.kwcall ||
    end
    return true
end

export VERBOSE_PNML, pff, t_modules, runopt, testshow, noisy

end # module TestUtils
