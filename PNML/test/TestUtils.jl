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
@reexport using PNML.Labels:
    Condition,  PnmlLabel, TokenGraphics, get_toolinfo, text, version, get_label
@reexport using PNML.Parser:
    allchildren, anyelement, default, firstchild, parse_arc,
    parse_declaration!, parse_declarations!, parse_fifoinitialMarking, parse_graphics,
    parse_hlinitialMarking, parse_hlinscription, parse_initialMarking, parse_inscription,
    parse_name, parse_net, parse_page!, parse_place, parse_refPlace, parse_refTransition,
    parse_sort, parse_text, parse_toolspecific, parse_transition, pnmlmodel, to_sort,
    xmldict
@reexport using PNML.Parser
@reexport using PNML.NetAPI
@reexport using PNML.Declarations
@reexport using PNML.IDRegistrys
@reexport using PNML.PnmlTypes
@reexport using PNML.PnmlGraphics

@reexport using PNML: @xml_str, AbstractDeclaration, AbstractOperator, AbstractSort, AbstractTerm,
    AbstractVariable, AnyElement, ArbitrarySort, Arc, BoolSort, BooleanConstant,
    Coordinate, CyclicEnumerationSort, DeclDict, Declaration, DotConstant, DotConstantEx,
    DotSort, DuplicateIDException, FEConstant, FiniteEnumerationSort, FiniteIntRangeSort,
    IntegerSort, ListSort, MalformedException, Maybe, MissingIDException, MultisetSort,
    NamedSort, NaturalSort, NumberConstant, Page, PartitionElement, PartitionSort, Place,
    PnmlException, PnmlExpr, PnmlModel, PnmlMultiset, PnmlNet, PnmlNetData, PnmlNetKeys,
    PositiveSort, ProductSort, RealSort, RefPlace, RefTransition, SortType, StringSort,
    Transition, XMLNode, XmlDictType, allpages, arbitrarysort, arbitrarysorts, arc,
    arc_idset, arcdict, arcs, arity, cardinality, condition, decldict, elements,
    extralabels,
    fill_builtin_labelparsers!, fill_builtin_sorts!, fill_builtin_toolparsers!,
    fill_sort_tag!, firstpage, flatten_pages!, graphics, has_arc, has_graphics,
    has_place, has_tools, has_transition, initial_marking, inputs, inscription, ispid,
    length, make_net, multiplicity, multiset, name, namedsort, namedsort, namedsorts,
    narcs, netdata, nets, netsets, nettype, npages, nplaces, nrefplaces, nreftransitions,
    ntransitions, page_idset, pagedict, pagedict, pages, partitionsort, partitionsorts,
    pid, place, place_idset, placedict, places, pntd, refid, refplace, refplace_idset,
    refplacedict, refplaces, reftransition, reftransition_idset, reftransitiondict,
    reftransitions, registry_of, sortdefinition, sortelements, sortref, source, tag,
    target, term, toexpr, toolinfos, transition, transition_idset, transitiondict,
    transitions, value, value_type, varsubs, xmlnode, zero

@reexport using PNML.SortRefImpl: UserSortRef, NamedSortRef, PartitionSortRef,
                    ProductSortRef, MultisetSortRef, ArbitrarySortRef

@reexport using PNML.Expressions
@reexport using PNML.NetAPI: metagraph, vertex_codes, vertex_labels




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
