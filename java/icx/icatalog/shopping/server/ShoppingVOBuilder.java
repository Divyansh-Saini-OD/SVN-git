package oracle.apps.icx.icatalog.shopping.server;

import java.util.*;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OANLSServices;
import oracle.apps.fnd.framework.server.*;
import oracle.apps.icx.icatalog.common.server.CachedVOBuilder;
import oracle.apps.icx.icatalog.common.server.VOBuilderContext;
import oracle.apps.icx.icatalog.loader.elements.CategoryElement;
import oracle.apps.icx.icatalog.loader.elements.DescriptorElement;
import oracle.apps.icx.por.req.server.RequisitionAMImpl;
import oracle.apps.jtf.base.resources.FrameworkException;
import oracle.jbo.domain.Number;

// Referenced classes of package oracle.apps.icx.icatalog.shopping.server:
//            AdvancedSearchValuesVORowImpl, FilteredAttributesVORowImpl, FilterValuesVORowImpl

// 19-July-2013		Gaurav Powar	Modified for R12 Upgrade Retrofit for E0990 Restrict Items

public abstract class ShoppingVOBuilder extends CachedVOBuilder
{

    public static final String RCS_ID = "$Header: ShoppingVOBuilder.java 120.49.12010000.8 2012/04/24 08:59:36 hliao ship" +
" $"
;
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: ShoppingVOBuilder.java 120.49.12010000.8 2012/04/24 08:59:36 hliao ship" +
" $"
, "oracle.apps.icx.icatalog.shopping.server");
    protected static final String LOCAL_FROM_CLAUSE_COMMON = "po_system_parameters_all psp, mtl_units_of_measure_tl muomtl, icx_cat_attribute_" +
"values av,icx_cat_attribute_values_tlp avtlp, po_vendor_sites_all pvs, mtl_categ" +
"ories_kfv mck, mtl_system_items_kfv msikfv "
;
    protected static final String BASIC_SELECT_CLAUSE_COMMON = "ctxh.inventory_item_id, ctxh.po_line_id, ctxh.req_template_name, ctxh.req_templa" +
"te_line_num, ctxh.org_id, ctxh.language, ctxh.source_type, ctxh.purchasing_org_i" +
"d, ctxh.ip_category_id, ctxh.ip_category_name, ctxh.po_category_id, ctxh.owning_" +
"org_id, ctxh.supplier_id, ctxh.supplier_part_num, ctxh.supplier_part_auxid, ctxh" +
".supplier_site_id, ctxh.item_type, ctxh.item_revision, ctxh.po_header_id, ctxh.d" +
"ocument_number, ctxh.line_num, ctxh.allow_price_override_flag, ctxh.not_to_excee" +
"d_price, ctxh.line_type_id, ctxh.unit_meas_lookup_code, ctxh.unit_price, ctxh.am" +
"ount, nvl(ctxh.currency_code, :FUNC_CURRENCY_KEY11) currency_code, ctxh.rate_typ" +
"e, ctxh.rate_date, ctxh.rate, ctxh.buyer_id, ctxh.supplier_contact_id, ctxh.rfq_" +
"required_flag, ctxh.negotiated_by_preparer_flag, ctxh.description, ctxh.supplier" +
", ctxh.req_template_po_line_id, ctxh.order_type_lookup_code, ctxh.merged_source_" +
"type, ctxh.global_agreement_flag, ctxh.suggested_quantity, score(1) relevance_sc" +
"ore, 1 as is_item_available,  to_number(null) favorite_list_id, to_number(null) " +
"favorite_list_line_id "
;
    protected static final String BASIC_FROM_CLAUSE_COMMON = "icx_cat_items_ctx_hdrs_tlp ctxh ";
    protected static final String BASIC_WHERE_CLAUSE_COMMON = "contains(ctxh.ctx_desc, :INTERMEDIA_KEY1, 1) > 0 AND ICX_CAT_UTIL_PVT.is_item_va" +
"lid_for_search( ctxh.source_type, ctxh.po_line_id, ctxh.req_template_name, ctxh." +
"req_template_line_num, ctxh.po_category_id, ctxh.org_id) = 1 )"
;
    protected static final String BASIC_QUERY = "(SELECT ctxh.inventory_item_id, ctxh.po_line_id, ctxh.req_template_name, ctxh.re" +
"q_template_line_num, ctxh.org_id, ctxh.language, ctxh.source_type, ctxh.purchasi" +
"ng_org_id, ctxh.ip_category_id, ctxh.ip_category_name, ctxh.po_category_id, ctxh" +
".owning_org_id, ctxh.supplier_id, ctxh.supplier_part_num, ctxh.supplier_part_aux" +
"id, ctxh.supplier_site_id, ctxh.item_type, ctxh.item_revision, ctxh.po_header_id" +
", ctxh.document_number, ctxh.line_num, ctxh.allow_price_override_flag, ctxh.not_" +
"to_exceed_price, ctxh.line_type_id, ctxh.unit_meas_lookup_code, ctxh.unit_price," +
" ctxh.amount, nvl(ctxh.currency_code, :FUNC_CURRENCY_KEY11) currency_code, ctxh." +
"rate_type, ctxh.rate_date, ctxh.rate, ctxh.buyer_id, ctxh.supplier_contact_id, c" +
"txh.rfq_required_flag, ctxh.negotiated_by_preparer_flag, ctxh.description, ctxh." +
"supplier, ctxh.req_template_po_line_id, ctxh.order_type_lookup_code, ctxh.merged" +
"_source_type, ctxh.global_agreement_flag, ctxh.suggested_quantity, score(1) rele" +
"vance_score, 1 as is_item_available,  to_number(null) favorite_list_id, to_numbe" +
"r(null) favorite_list_line_id FROM icx_cat_items_ctx_hdrs_tlp ctxh WHERE contain" +
"s(ctxh.ctx_desc, :INTERMEDIA_KEY1, 1) > 0 AND ICX_CAT_UTIL_PVT.is_item_valid_for" +
"_search( ctxh.source_type, ctxh.po_line_id, ctxh.req_template_name, ctxh.req_tem" +
"plate_line_num, ctxh.po_category_id, ctxh.org_id) = 1 ) bq "
;
    protected static final String BASIC_QUERY_WITH_PRECEDENCE = "(SELECT ctxh.inventory_item_id, ctxh.po_line_id, ctxh.req_template_name, ctxh.re" +
"q_template_line_num, ctxh.org_id, ctxh.language, ctxh.source_type, ctxh.purchasi" +
"ng_org_id, ctxh.ip_category_id, ctxh.ip_category_name, ctxh.po_category_id, ctxh" +
".owning_org_id, ctxh.supplier_id, ctxh.supplier_part_num, ctxh.supplier_part_aux" +
"id, ctxh.supplier_site_id, ctxh.item_type, ctxh.item_revision, ctxh.po_header_id" +
", ctxh.document_number, ctxh.line_num, ctxh.allow_price_override_flag, ctxh.not_" +
"to_exceed_price, ctxh.line_type_id, ctxh.unit_meas_lookup_code, ctxh.unit_price," +
" ctxh.amount, nvl(ctxh.currency_code, :FUNC_CURRENCY_KEY11) currency_code, ctxh." +
"rate_type, ctxh.rate_date, ctxh.rate, ctxh.buyer_id, ctxh.supplier_contact_id, c" +
"txh.rfq_required_flag, ctxh.negotiated_by_preparer_flag, ctxh.description, ctxh." +
"supplier, ctxh.req_template_po_line_id, ctxh.order_type_lookup_code, ctxh.merged" +
"_source_type, ctxh.global_agreement_flag, ctxh.suggested_quantity, score(1) rele" +
"vance_score, 1 as is_item_available,  to_number(null) favorite_list_id, to_numbe" +
"r(null) favorite_list_line_id , count(*) over (partition by ctxh.inventory_item_" +
"id, ctxh.org_id, ctxh.language) as source_count FROM icx_cat_items_ctx_hdrs_tlp " +
"ctxh WHERE contains(ctxh.ctx_desc, :INTERMEDIA_KEY1, 1) > 0 AND ICX_CAT_UTIL_PVT" +
".is_item_valid_for_search( ctxh.source_type, ctxh.po_line_id, ctxh.req_template_" +
"name, ctxh.req_template_line_num, ctxh.po_category_id, ctxh.org_id) = 1 ) bq "
;
    protected static final String LOCAL_FROM_CLAUSE = "(SELECT ctxh.inventory_item_id, ctxh.po_line_id, ctxh.req_template_name, ctxh.re" +
"q_template_line_num, ctxh.org_id, ctxh.language, ctxh.source_type, ctxh.purchasi" +
"ng_org_id, ctxh.ip_category_id, ctxh.ip_category_name, ctxh.po_category_id, ctxh" +
".owning_org_id, ctxh.supplier_id, ctxh.supplier_part_num, ctxh.supplier_part_aux" +
"id, ctxh.supplier_site_id, ctxh.item_type, ctxh.item_revision, ctxh.po_header_id" +
", ctxh.document_number, ctxh.line_num, ctxh.allow_price_override_flag, ctxh.not_" +
"to_exceed_price, ctxh.line_type_id, ctxh.unit_meas_lookup_code, ctxh.unit_price," +
" ctxh.amount, nvl(ctxh.currency_code, :FUNC_CURRENCY_KEY11) currency_code, ctxh." +
"rate_type, ctxh.rate_date, ctxh.rate, ctxh.buyer_id, ctxh.supplier_contact_id, c" +
"txh.rfq_required_flag, ctxh.negotiated_by_preparer_flag, ctxh.description, ctxh." +
"supplier, ctxh.req_template_po_line_id, ctxh.order_type_lookup_code, ctxh.merged" +
"_source_type, ctxh.global_agreement_flag, ctxh.suggested_quantity, score(1) rele" +
"vance_score, 1 as is_item_available,  to_number(null) favorite_list_id, to_numbe" +
"r(null) favorite_list_line_id FROM icx_cat_items_ctx_hdrs_tlp ctxh WHERE contain" +
"s(ctxh.ctx_desc, :INTERMEDIA_KEY1, 1) > 0 AND ICX_CAT_UTIL_PVT.is_item_valid_for" +
"_search( ctxh.source_type, ctxh.po_line_id, ctxh.req_template_name, ctxh.req_tem" +
"plate_line_num, ctxh.po_category_id, ctxh.org_id) = 1 ) bq , po_system_parameter" +
"s_all psp, mtl_units_of_measure_tl muomtl, icx_cat_attribute_values av,icx_cat_a" +
"ttribute_values_tlp avtlp, po_vendor_sites_all pvs, mtl_categories_kfv mck, mtl_" +
"system_items_kfv msikfv "
;
    protected static final String LOCAL_FROM_CLAUSE_WITH_PRECEDENCE = "(SELECT ctxh.inventory_item_id, ctxh.po_line_id, ctxh.req_template_name, ctxh.re" +
"q_template_line_num, ctxh.org_id, ctxh.language, ctxh.source_type, ctxh.purchasi" +
"ng_org_id, ctxh.ip_category_id, ctxh.ip_category_name, ctxh.po_category_id, ctxh" +
".owning_org_id, ctxh.supplier_id, ctxh.supplier_part_num, ctxh.supplier_part_aux" +
"id, ctxh.supplier_site_id, ctxh.item_type, ctxh.item_revision, ctxh.po_header_id" +
", ctxh.document_number, ctxh.line_num, ctxh.allow_price_override_flag, ctxh.not_" +
"to_exceed_price, ctxh.line_type_id, ctxh.unit_meas_lookup_code, ctxh.unit_price," +
" ctxh.amount, nvl(ctxh.currency_code, :FUNC_CURRENCY_KEY11) currency_code, ctxh." +
"rate_type, ctxh.rate_date, ctxh.rate, ctxh.buyer_id, ctxh.supplier_contact_id, c" +
"txh.rfq_required_flag, ctxh.negotiated_by_preparer_flag, ctxh.description, ctxh." +
"supplier, ctxh.req_template_po_line_id, ctxh.order_type_lookup_code, ctxh.merged" +
"_source_type, ctxh.global_agreement_flag, ctxh.suggested_quantity, score(1) rele" +
"vance_score, 1 as is_item_available,  to_number(null) favorite_list_id, to_numbe" +
"r(null) favorite_list_line_id , count(*) over (partition by ctxh.inventory_item_" +
"id, ctxh.org_id, ctxh.language) as source_count FROM icx_cat_items_ctx_hdrs_tlp " +
"ctxh WHERE contains(ctxh.ctx_desc, :INTERMEDIA_KEY1, 1) > 0 AND ICX_CAT_UTIL_PVT" +
".is_item_valid_for_search( ctxh.source_type, ctxh.po_line_id, ctxh.req_template_" +
"name, ctxh.req_template_line_num, ctxh.po_category_id, ctxh.org_id) = 1 ) bq , p" +
"o_system_parameters_all psp, mtl_units_of_measure_tl muomtl, icx_cat_attribute_v" +
"alues av,icx_cat_attribute_values_tlp avtlp, po_vendor_sites_all pvs, mtl_catego" +
"ries_kfv mck, mtl_system_items_kfv msikfv "
;
    protected static final String BASIC_QUERY_SIC_PO = "(SELECT ctxh.inventory_item_id, ctxh.po_line_id, ctxh.req_template_name, ctxh.re" +
"q_template_line_num, ctxh.org_id, ctxh.language, ctxh.source_type, ctxh.purchasi" +
"ng_org_id, ctxh.ip_category_id, ctxh.ip_category_name, ctxh.po_category_id, ctxh" +
".owning_org_id, ctxh.supplier_id, ctxh.supplier_part_num, ctxh.supplier_part_aux" +
"id, ctxh.supplier_site_id, ctxh.item_type, ctxh.item_revision, ctxh.po_header_id" +
", ctxh.document_number, ctxh.line_num, ctxh.allow_price_override_flag, ctxh.not_" +
"to_exceed_price, ctxh.line_type_id, ctxh.unit_meas_lookup_code, ctxh.unit_price," +
" ctxh.amount, nvl(ctxh.currency_code, :FUNC_CURRENCY_KEY11) currency_code, ctxh." +
"rate_type, ctxh.rate_date, ctxh.rate, ctxh.buyer_id, ctxh.supplier_contact_id, c" +
"txh.rfq_required_flag, ctxh.negotiated_by_preparer_flag, ctxh.description, ctxh." +
"supplier, ctxh.req_template_po_line_id, ctxh.order_type_lookup_code, ctxh.merged" +
"_source_type, ctxh.global_agreement_flag, ctxh.suggested_quantity, score(1) rele" +
"vance_score, 1 as is_item_available,  to_number(null) favorite_list_id, to_numbe" +
"r(null) favorite_list_line_id , row_number() over (partition by ctxh.inventory_i" +
"tem_id, ctxh.po_line_id, ctxh.req_template_name, ctxh.req_template_line_num, ctx" +
"h.purchasing_org_id, ctxh.language ORDER BY ctxh.inventory_item_id) as rownum1 F" +
"ROM icx_cat_items_ctx_hdrs_tlp ctxh WHERE contains(ctxh.ctx_desc, :INTERMEDIA_KE" +
"Y1, 1) > 0 AND ICX_CAT_UTIL_PVT.is_item_valid_for_search( ctxh.source_type, ctxh" +
".po_line_id, ctxh.req_template_name, ctxh.req_template_line_num, ctxh.po_categor" +
"y_id, ctxh.org_id) = 1 ) bq "
;
    protected static final String BASIC_QUERY_WITH_PRECEDENCE_SIC_PO = "(SELECT ctxh.inventory_item_id, ctxh.po_line_id, ctxh.req_template_name, ctxh.re" +
"q_template_line_num, ctxh.org_id, ctxh.language, ctxh.source_type, ctxh.purchasi" +
"ng_org_id, ctxh.ip_category_id, ctxh.ip_category_name, ctxh.po_category_id, ctxh" +
".owning_org_id, ctxh.supplier_id, ctxh.supplier_part_num, ctxh.supplier_part_aux" +
"id, ctxh.supplier_site_id, ctxh.item_type, ctxh.item_revision, ctxh.po_header_id" +
", ctxh.document_number, ctxh.line_num, ctxh.allow_price_override_flag, ctxh.not_" +
"to_exceed_price, ctxh.line_type_id, ctxh.unit_meas_lookup_code, ctxh.unit_price," +
" ctxh.amount, nvl(ctxh.currency_code, :FUNC_CURRENCY_KEY11) currency_code, ctxh." +
"rate_type, ctxh.rate_date, ctxh.rate, ctxh.buyer_id, ctxh.supplier_contact_id, c" +
"txh.rfq_required_flag, ctxh.negotiated_by_preparer_flag, ctxh.description, ctxh." +
"supplier, ctxh.req_template_po_line_id, ctxh.order_type_lookup_code, ctxh.merged" +
"_source_type, ctxh.global_agreement_flag, ctxh.suggested_quantity, score(1) rele" +
"vance_score, 1 as is_item_available,  to_number(null) favorite_list_id, to_numbe" +
"r(null) favorite_list_line_id , count(*) over (partition by ctxh.inventory_item_" +
"id, ctxh.purchasing_org_id, ctxh.language) as source_count, row_number() over (p" +
"artition by ctxh.inventory_item_id, ctxh.po_line_id, ctxh.req_template_name, ctx" +
"h.req_template_line_num, ctxh.purchasing_org_id, ctxh.language ORDER BY ctxh.inv" +
"entory_item_id) as rownum1 FROM icx_cat_items_ctx_hdrs_tlp ctxh WHERE contains(c" +
"txh.ctx_desc, :INTERMEDIA_KEY1, 1) > 0 AND ICX_CAT_UTIL_PVT.is_item_valid_for_se" +
"arch( ctxh.source_type, ctxh.po_line_id, ctxh.req_template_name, ctxh.req_templa" +
"te_line_num, ctxh.po_category_id, ctxh.org_id) = 1 ) bq "
;
    protected static final String LOCAL_FROM_CLAUSE_SIC_PO = "(SELECT ctxh.inventory_item_id, ctxh.po_line_id, ctxh.req_template_name, ctxh.re" +
"q_template_line_num, ctxh.org_id, ctxh.language, ctxh.source_type, ctxh.purchasi" +
"ng_org_id, ctxh.ip_category_id, ctxh.ip_category_name, ctxh.po_category_id, ctxh" +
".owning_org_id, ctxh.supplier_id, ctxh.supplier_part_num, ctxh.supplier_part_aux" +
"id, ctxh.supplier_site_id, ctxh.item_type, ctxh.item_revision, ctxh.po_header_id" +
", ctxh.document_number, ctxh.line_num, ctxh.allow_price_override_flag, ctxh.not_" +
"to_exceed_price, ctxh.line_type_id, ctxh.unit_meas_lookup_code, ctxh.unit_price," +
" ctxh.amount, nvl(ctxh.currency_code, :FUNC_CURRENCY_KEY11) currency_code, ctxh." +
"rate_type, ctxh.rate_date, ctxh.rate, ctxh.buyer_id, ctxh.supplier_contact_id, c" +
"txh.rfq_required_flag, ctxh.negotiated_by_preparer_flag, ctxh.description, ctxh." +
"supplier, ctxh.req_template_po_line_id, ctxh.order_type_lookup_code, ctxh.merged" +
"_source_type, ctxh.global_agreement_flag, ctxh.suggested_quantity, score(1) rele" +
"vance_score, 1 as is_item_available,  to_number(null) favorite_list_id, to_numbe" +
"r(null) favorite_list_line_id , row_number() over (partition by ctxh.inventory_i" +
"tem_id, ctxh.po_line_id, ctxh.req_template_name, ctxh.req_template_line_num, ctx" +
"h.purchasing_org_id, ctxh.language ORDER BY ctxh.inventory_item_id) as rownum1 F" +
"ROM icx_cat_items_ctx_hdrs_tlp ctxh WHERE contains(ctxh.ctx_desc, :INTERMEDIA_KE" +
"Y1, 1) > 0 AND ICX_CAT_UTIL_PVT.is_item_valid_for_search( ctxh.source_type, ctxh" +
".po_line_id, ctxh.req_template_name, ctxh.req_template_line_num, ctxh.po_categor" +
"y_id, ctxh.org_id) = 1 ) bq , po_system_parameters_all psp, mtl_units_of_measure" +
"_tl muomtl, icx_cat_attribute_values av,icx_cat_attribute_values_tlp avtlp, po_v" +
"endor_sites_all pvs, mtl_categories_kfv mck, mtl_system_items_kfv msikfv "
;
    protected static final String LOCAL_FROM_CLAUSE_WITH_PRECEDENCE_SIC_PO = "(SELECT ctxh.inventory_item_id, ctxh.po_line_id, ctxh.req_template_name, ctxh.re" +
"q_template_line_num, ctxh.org_id, ctxh.language, ctxh.source_type, ctxh.purchasi" +
"ng_org_id, ctxh.ip_category_id, ctxh.ip_category_name, ctxh.po_category_id, ctxh" +
".owning_org_id, ctxh.supplier_id, ctxh.supplier_part_num, ctxh.supplier_part_aux" +
"id, ctxh.supplier_site_id, ctxh.item_type, ctxh.item_revision, ctxh.po_header_id" +
", ctxh.document_number, ctxh.line_num, ctxh.allow_price_override_flag, ctxh.not_" +
"to_exceed_price, ctxh.line_type_id, ctxh.unit_meas_lookup_code, ctxh.unit_price," +
" ctxh.amount, nvl(ctxh.currency_code, :FUNC_CURRENCY_KEY11) currency_code, ctxh." +
"rate_type, ctxh.rate_date, ctxh.rate, ctxh.buyer_id, ctxh.supplier_contact_id, c" +
"txh.rfq_required_flag, ctxh.negotiated_by_preparer_flag, ctxh.description, ctxh." +
"supplier, ctxh.req_template_po_line_id, ctxh.order_type_lookup_code, ctxh.merged" +
"_source_type, ctxh.global_agreement_flag, ctxh.suggested_quantity, score(1) rele" +
"vance_score, 1 as is_item_available,  to_number(null) favorite_list_id, to_numbe" +
"r(null) favorite_list_line_id , count(*) over (partition by ctxh.inventory_item_" +
"id, ctxh.purchasing_org_id, ctxh.language) as source_count, row_number() over (p" +
"artition by ctxh.inventory_item_id, ctxh.po_line_id, ctxh.req_template_name, ctx" +
"h.req_template_line_num, ctxh.purchasing_org_id, ctxh.language ORDER BY ctxh.inv" +
"entory_item_id) as rownum1 FROM icx_cat_items_ctx_hdrs_tlp ctxh WHERE contains(c" +
"txh.ctx_desc, :INTERMEDIA_KEY1, 1) > 0 AND ICX_CAT_UTIL_PVT.is_item_valid_for_se" +
"arch( ctxh.source_type, ctxh.po_line_id, ctxh.req_template_name, ctxh.req_templa" +
"te_line_num, ctxh.po_category_id, ctxh.org_id) = 1 ) bq , po_system_parameters_a" +
"ll psp, mtl_units_of_measure_tl muomtl, icx_cat_attribute_values av,icx_cat_attr" +
"ibute_values_tlp avtlp, po_vendor_sites_all pvs, mtl_categories_kfv mck, mtl_sys" +
"tem_items_kfv msikfv "
;
    protected static final String LOCAL_WHERE_CLAUSE_COMMON = "psp.org_id = :ORG_ID_KEY2 AND bq.unit_meas_lookup_code = muomtl.unit_of_measure(" +
"+) AND bq.language = muomtl.language(+) AND bq.inventory_item_id = av.inventory_" +
"item_id(+) AND bq.owning_org_id = av.org_id(+) AND bq.po_line_id = av.po_line_id" +
"(+) AND bq.req_template_name = av.req_template_name(+) AND bq.req_template_line_" +
"num = av.req_template_line_num(+) AND bq.inventory_item_id = avtlp.inventory_ite" +
"m_id(+) AND bq.owning_org_id = avtlp.org_id(+) AND bq.po_line_id = avtlp.po_line" +
"_id(+) AND bq.req_template_name = avtlp.req_template_name(+) AND bq.req_template" +
"_line_num = avtlp.req_template_line_num(+) AND bq.language = avtlp.language(+) A" +
"ND bq.supplier_site_id = pvs.vendor_site_id(+) AND bq.po_category_id = mck.categ" +
"ory_id(+) AND bq.inventory_item_id = msikfv.inventory_item_id(+) AND msikfv.orga" +
"nization_id(+) = :INV_ORG_ID_KEY1 "
;
    protected static final String LOCAL_WHERE_CLAUSE = "psp.org_id = :ORG_ID_KEY2 AND bq.unit_meas_lookup_code = muomtl.unit_of_measure(" +
"+) AND bq.language = muomtl.language(+) AND bq.inventory_item_id = av.inventory_" +
"item_id(+) AND bq.owning_org_id = av.org_id(+) AND bq.po_line_id = av.po_line_id" +
"(+) AND bq.req_template_name = av.req_template_name(+) AND bq.req_template_line_" +
"num = av.req_template_line_num(+) AND bq.inventory_item_id = avtlp.inventory_ite" +
"m_id(+) AND bq.owning_org_id = avtlp.org_id(+) AND bq.po_line_id = avtlp.po_line" +
"_id(+) AND bq.req_template_name = avtlp.req_template_name(+) AND bq.req_template" +
"_line_num = avtlp.req_template_line_num(+) AND bq.language = avtlp.language(+) A" +
"ND bq.supplier_site_id = pvs.vendor_site_id(+) AND bq.po_category_id = mck.categ" +
"ory_id(+) AND bq.inventory_item_id = msikfv.inventory_item_id(+) AND msikfv.orga" +
"nization_id(+) = :INV_ORG_ID_KEY1 "
;
    protected static final String LOCAL_WHERE_CLAUSE_WITH_PRECEDENCE = "(bq.source_count = 1 OR bq.source_type <> 'MASTER_ITEM') AND psp.org_id = :ORG_I" +
"D_KEY2 AND bq.unit_meas_lookup_code = muomtl.unit_of_measure(+) AND bq.language " +
"= muomtl.language(+) AND bq.inventory_item_id = av.inventory_item_id(+) AND bq.o" +
"wning_org_id = av.org_id(+) AND bq.po_line_id = av.po_line_id(+) AND bq.req_temp" +
"late_name = av.req_template_name(+) AND bq.req_template_line_num = av.req_templa" +
"te_line_num(+) AND bq.inventory_item_id = avtlp.inventory_item_id(+) AND bq.owni" +
"ng_org_id = avtlp.org_id(+) AND bq.po_line_id = avtlp.po_line_id(+) AND bq.req_t" +
"emplate_name = avtlp.req_template_name(+) AND bq.req_template_line_num = avtlp.r" +
"eq_template_line_num(+) AND bq.language = avtlp.language(+) AND bq.supplier_site" +
"_id = pvs.vendor_site_id(+) AND bq.po_category_id = mck.category_id(+) AND bq.in" +
"ventory_item_id = msikfv.inventory_item_id(+) AND msikfv.organization_id(+) = :I" +
"NV_ORG_ID_KEY1 "
;
    protected static final String LOCAL_WHERE_CLAUSE_SIC_PO = "bq.rownum1 = 1 AND psp.org_id = :ORG_ID_KEY2 AND bq.unit_meas_lookup_code = muom" +
"tl.unit_of_measure(+) AND bq.language = muomtl.language(+) AND bq.inventory_item" +
"_id = av.inventory_item_id(+) AND bq.owning_org_id = av.org_id(+) AND bq.po_line" +
"_id = av.po_line_id(+) AND bq.req_template_name = av.req_template_name(+) AND bq" +
".req_template_line_num = av.req_template_line_num(+) AND bq.inventory_item_id = " +
"avtlp.inventory_item_id(+) AND bq.owning_org_id = avtlp.org_id(+) AND bq.po_line" +
"_id = avtlp.po_line_id(+) AND bq.req_template_name = avtlp.req_template_name(+) " +
"AND bq.req_template_line_num = avtlp.req_template_line_num(+) AND bq.language = " +
"avtlp.language(+) AND bq.supplier_site_id = pvs.vendor_site_id(+) AND bq.po_cate" +
"gory_id = mck.category_id(+) AND bq.inventory_item_id = msikfv.inventory_item_id" +
"(+) AND msikfv.organization_id(+) = :INV_ORG_ID_KEY1 "
;
    protected static final String LOCAL_WHERE_CLAUSE_WITH_PRECEDENCE_SIC_PO = "(bq.source_count = 1 OR bq.source_type <> 'MASTER_ITEM') AND bq.rownum1 = 1 AND " +
"psp.org_id = :ORG_ID_KEY2 AND bq.unit_meas_lookup_code = muomtl.unit_of_measure(" +
"+) AND bq.language = muomtl.language(+) AND bq.inventory_item_id = av.inventory_" +
"item_id(+) AND bq.owning_org_id = av.org_id(+) AND bq.po_line_id = av.po_line_id" +
"(+) AND bq.req_template_name = av.req_template_name(+) AND bq.req_template_line_" +
"num = av.req_template_line_num(+) AND bq.inventory_item_id = avtlp.inventory_ite" +
"m_id(+) AND bq.owning_org_id = avtlp.org_id(+) AND bq.po_line_id = avtlp.po_line" +
"_id(+) AND bq.req_template_name = avtlp.req_template_name(+) AND bq.req_template" +
"_line_num = avtlp.req_template_line_num(+) AND bq.language = avtlp.language(+) A" +
"ND bq.supplier_site_id = pvs.vendor_site_id(+) AND bq.po_category_id = mck.categ" +
"ory_id(+) AND bq.inventory_item_id = msikfv.inventory_item_id(+) AND msikfv.orga" +
"nization_id(+) = :INV_ORG_ID_KEY1 "
;
    protected static final Object SELECT_CLAUSE_ARRAY[][] = {
        {
            "bq.relevance_score", "-1", "-1", "Relevance", "oracle.jbo.domain.Number", new Integer(2), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "'l#' || bq.inventory_item_id || '#' || bq.po_line_id ||'#' || bq.req_template_na" +
"me || '#' ||bq.req_template_line_num || '#' || :ORG_ID_KEY1"
, "'n#' || favl.rowid", "'r#' || favl.rowid", "ItemKey", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(255)
        }, {
            "bq.source_type", "'NONCATALOG'", "'EXTERNAL'", "SourceType", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(20)
        }, {
            "DECODE(bq.source_type,'TEMPLATE',decode(least(length(bq.req_template_name) , 20)" +
",20,substr(bq.req_template_name,1,17) ||'...',bq.req_template_name),'INTERNAL_TE" +
"MPLATE',decode(least(length(bq.req_template_name) , 20),20,substr(bq.req_templat" +
"e_name,1,17) ||'...',bq.req_template_name),'QUOTATION',ICX_CAT_UTIL_PVT.get_mess" +
"age('ICX_CAT_QUOTATION_SOURCE','NUMBER',bq.document_number) ,'BLANKET',ICX_CAT_U" +
"TIL_PVT.get_message('ICX_CAT_BLANKET_SOURCE','NUMBER',bq.document_number),'GLOBA" +
"L_BLANKET',ICX_CAT_UTIL_PVT.get_message('ICX_CAT_BLANKET_SOURCE','NUMBER',bq.doc" +
"ument_number), null)"
, "decode(ph.segment1, null, null, ICX_CAT_UTIL_PVT.get_message('ICX_CAT_BLANKET_SO" +
"URCE', 'NUMBER', ph.segment1))"
, "decode(ph.segment1, null, null, ICX_CAT_UTIL_PVT.get_message('ICX_CAT_BLANKET_SO" +
"URCE', 'NUMBER', ph.segment1))"
, "SOURCE", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(20)
        }, {
            "bq.inventory_item_id", "to_number(null)", "to_number(null)", "ItemId", "oracle.jbo.domain.Number", new Integer(2), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "nvl(avtlp.description, bq.description)", "favl.item_description", "favl.item_description", "DESCRIPTION", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(240)
        }, {
            "DECODE(LEAST(LENGTH(decode(1,1, nvl(avtlp.description, bq.description))),25), 25" +
", SUBSTR(decode(1,1, nvl(avtlp.description, bq.description)),1, 22)||'...', deco" +
"de(1,1, nvl(avtlp.description, bq.description)))"
, "DECODE(LEAST(LENGTH(favl.item_description), 25),25, SUBSTR(favl.item_description" +
",1,  22)||'...',favl.item_description)"
, "DECODE(LEAST(LENGTH(favl.item_description), 25),25, SUBSTR(favl.item_description" +
",1,  22)||'...',favl.item_description)"
, "TruncatedDescription", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(25)
        }, {
            "avtlp.long_description", "to_char(null)", "favl.long_description", "LONG_DESCRIPTION", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(2000)
        }, {
            "DECODE(LEAST(LENGTH(avtlp.long_description), 180), 180, SUBSTR(avtlp.long_descri" +
"ption, 1, 177)||'...', avtlp.long_description)"
, "to_char(null)", "DECODE(LEAST(LENGTH(favl.long_description), 180), 180, SUBSTR(favl.long_descript" +
"ion, 1, 177)||'...', favl.long_description)"
, "TruncatedLongDescription", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(180)
        }, {
            "msikfv.concatenated_segments", "to_char(null)", "to_char(null)", "INTERNAL_ITEM_NUM", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(40)
        }, {
            "decode(bq.item_revision, '-2', to_char(null), bq.item_revision)", "to_char(null)", "to_char(null)", "ITEM_REVISION", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(3)
        }, {
            "bq.po_header_id", "favl.po_header_id", "favl.po_header_id", "PoHeaderId", "oracle.jbo.domain.Number", new Integer(2), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "decode(bq.merged_source_type, 'REQ_TEMPLATE',NVL(bq.req_template_po_line_id,-2)," +
" bq.po_line_id)"
, "to_number(null)", "to_number(null)", "PoLineId", "oracle.jbo.domain.Number", new Integer(2), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "bq.document_number", "ph.segment1", "ph.segment1", "DocumentNumber", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(20)
        }, {
            "bq.line_num", "to_number(null)", "to_number(null)", "DocumentLineNumber", "oracle.jbo.domain.Number", new Integer(2), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "bq.req_template_name", "to_char(null)", "to_char(null)", "ReqTemplateName", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(25)
        }, {
            "bq.req_template_line_num", "to_number(null)", "to_number(null)", "ReqTemplateLineNum", "oracle.jbo.domain.Number", new Integer(2), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "decode(bq.order_type_lookup_code, 'AMOUNT', 1, decode(bq.allow_price_override_fl" +
"ag, 'Y', 1, 0))"
, "decode(plt.order_type_lookup_code, 'AMOUNT', 1, 0)", "decode(plt.order_type_lookup_code, 'AMOUNT', 1, 0)", "AllowPriceOverrideFlag", "java.lang.Boolean", new Integer(-7), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "bq.not_to_exceed_price", "to_number(null)", "to_number(null)", "AmountLimit", "oracle.jbo.domain.Number", new Integer(2), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "decode(bq.order_type_lookup_code, 'FIXED PRICE', 1, 0)", "decode(plt.order_type_lookup_code, 'FIXED PRICE', 1, 0)", "decode(plt.order_type_lookup_code, 'FIXED PRICE', 1, 0)", "IsFixedPrice", "java.lang.Boolean", new Integer(-7), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "decode(bq.order_type_lookup_code, 'QUANTITY', 0, 1)", "decode(plt.order_type_lookup_code, 'QUANTITY', 0, 1)", "decode(plt.order_type_lookup_code, 'QUANTITY', 0, 1)", "IsFixedPriceOrAmountBased", "java.lang.Boolean", new Integer(-7), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "decode(bq.order_type_lookup_code, 'AMOUNT', 0, decode(bq.allow_price_override_fl" +
"ag, 'Y', 0, 1))"
, "decode(plt.order_type_lookup_code, 'AMOUNT', 0, 1)", "decode(plt.order_type_lookup_code, 'AMOUNT', 0, 1)", "IsAmountReadOnly", "java.lang.Boolean", new Integer(-7), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "decode(bq.order_type_lookup_code, 'QUANTITY', 1, 0)", "decode(plt.order_type_lookup_code, 'QUANTITY', 1, 0)", "decode(plt.order_type_lookup_code, 'QUANTITY', 1, 0)", "IsQuantityBased", "java.lang.Boolean", new Integer(-7), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "nvl(bq.line_type_id, :GOODS_LINE_TYPE_KEY1)", "favl.line_type_id", "favl.line_type_id", "LineTypeId", "oracle.jbo.domain.Number", new Integer(2), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "bq.po_category_id", "favl.po_category_id", "favl.po_category_id", "PurchasingCategoryId", "oracle.jbo.domain.Number", new Integer(2), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "bq.ip_category_id", "to_number(null)", "to_number(null)", "ShoppingCategoryId", "oracle.jbo.domain.Number", new Integer(2), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "mck.concatenated_segments", "mck.concatenated_segments", "mck.concatenated_segments", "PURCHASING_CATEGORY", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(250)
        }, {
            "bq.ip_category_name", "to_char(null)", "to_char(null)", "SHOPPING_CATEGORY", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(250)
        }, {
            "muomtl.uom_code", "muomtl.uom_code", "muomtl.uom_code", "UomCode", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(25)
        }, {
            "muomtl.unit_of_measure", "muomtl.unit_of_measure", "muomtl.unit_of_measure", "UomForCart", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(25)
        }, {
            "muomtl.unit_of_measure_tl", "muomtl.unit_of_measure_tl", "muomtl.unit_of_measure_tl", "UOM", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(25)
        }, {
            "nvl(bq.suggested_quantity, 1)", "1", "1", "Quantity", "oracle.jbo.domain.Number", new Integer(2), new Boolean(false), new Boolean(true), new Byte((byte)2), new Integer(-1)
        }, {
            "decode(bq.merged_source_type, 'MASTER_ITEM', decode(:ALLOWED_ITEM_TYPE_KEY1, 'IN" +
"TERNAL', to_number(null), bq.unit_price), bq.unit_price)"
, "favl.unit_price", "favl.unit_price", "PRICE", "oracle.jbo.domain.Number", new Integer(2), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "decode(bq.order_type_lookup_code, 'AMOUNT', to_number(null), 'FIXED PRICE', to_n" +
"umber(null), decode(bq.currency_code, :FUNC_CURRENCY_KEY1, decode(bq.merged_sour" +
"ce_type, 'MASTER_ITEM', decode(:ALLOWED_ITEM_TYPE_KEY2, 'INTERNAL', to_number(nu" +
"ll), bq.unit_price), bq.unit_price), icx_cat_util_pvt.convert_amount(bq.currency" +
"_code, :FUNC_CURRENCY_KEY2, decode(bq.currency_code, :FUNC_CURRENCY_KEY3, to_dat" +
"e(null), decode(bq.global_agreement_flag, 'Y', trunc(sysdate), bq.rate_date)), d" +
"ecode(bq.currency_code, :FUNC_CURRENCY_KEY4, to_char(null), decode(bq.global_agr" +
"eement_flag, 'Y', psp.default_rate_type, bq.rate_type)), decode(bq.currency_code" +
", :FUNC_CURRENCY_KEY5, to_number(null), decode(bq.global_agreement_flag, 'Y', to" +
"_number(null), bq.rate)), decode(bq.merged_source_type, 'MASTER_ITEM', decode(:A" +
"LLOWED_ITEM_TYPE_KEY3, 'INTERNAL', to_number(null), bq.unit_price), bq.unit_pric" +
"e))))"
, "decode(plt.order_type_lookup_code, 'AMOUNT', to_number(null), 'FIXED PRICE', to_" +
"number(null), decode(favl.currency, :FUNC_CURRENCY_KEY21, favl.unit_price, icx_c" +
"at_util_pvt.convert_amount(favl.currency, :FUNC_CURRENCY_KEY22, favl.rate_date, " +
"favl.rate_type, favl.rate, favl.unit_price)))"
, "decode(plt.order_type_lookup_code, 'AMOUNT', to_number(null), 'FIXED PRICE', to_" +
"number(null), decode(favl.currency, :FUNC_CURRENCY_KEY28, favl.unit_price, icx_c" +
"at_util_pvt.convert_amount(favl.currency, :FUNC_CURRENCY_KEY29, decode(favl.curr" +
"ency, :FUNC_CURRENCY_KEY30, to_date(null), decode(ph.po_header_id, null, trunc(s" +
"ysdate), decode(ph.global_agreement_flag, 'Y', trunc(sysdate), ph.rate_date))), " +
"decode(favl.currency, :FUNC_CURRENCY_KEY31, to_char(null), decode(ph.po_header_i" +
"d, null, :RATE_TYPE_KEY1, decode(ph.global_agreement_flag, 'Y', psp.default_rate" +
"_type, ph.rate_type))), decode(ph.po_header_id, null, null, decode(ph.global_agr" +
"eement_flag, 'Y', null, ph.rate)), favl.unit_price)))"
, "FUNCTIONAL_PRICE", "oracle.jbo.domain.Number", new Integer(2), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "decode(bq.order_type_lookup_code, 'AMOUNT', nvl(bq.suggested_quantity * bq.unit_" +
"price, 1), bq.amount)"
, "favl.amount", "favl.amount", "Amount", "oracle.jbo.domain.Number", new Integer(2), new Boolean(false), new Boolean(true), new Byte((byte)2), new Integer(-1)
        }, {
            "decode(bq.order_type_lookup_code, 'FIXED PRICE', decode(bq.currency_code, :FUNC_" +
"CURRENCY_KEY6, decode(bq.order_type_lookup_code, 'AMOUNT', 1, bq.amount), icx_ca" +
"t_util_pvt.convert_amount(bq.currency_code, :FUNC_CURRENCY_KEY7, decode(bq.curre" +
"ncy_code, :FUNC_CURRENCY_KEY8, to_date(null), decode(bq.global_agreement_flag, '" +
"Y', trunc(sysdate), bq.rate_date)), decode(bq.currency_code, :FUNC_CURRENCY_KEY9" +
", to_char(null), decode(bq.global_agreement_flag, 'Y', psp.default_rate_type, bq" +
".rate_type)), decode(bq.currency_code, :FUNC_CURRENCY_KEY10, to_number(null), de" +
"code(bq.global_agreement_flag, 'Y', to_number(null), bq.rate)), decode(bq.order_" +
"type_lookup_code, 'AMOUNT', 1, bq.amount))), to_number(null))"
, "decode(plt.order_type_lookup_code, 'FIXED PRICE', decode(favl.currency, :FUNC_CU" +
"RRENCY_KEY23, favl.amount, icx_cat_util_pvt.convert_amount(favl.currency, :FUNC_" +
"CURRENCY_KEY24, favl.rate_date, favl.rate_type, favl.rate, favl.amount)), to_num" +
"ber(null))"
, "decode(plt.order_type_lookup_code, 'FIXED PRICE', decode(favl.currency, :FUNC_CU" +
"RRENCY_KEY32, favl.amount, icx_cat_util_pvt.convert_amount(favl.currency, :FUNC_" +
"CURRENCY_KEY33, decode(favl.currency, :FUNC_CURRENCY_KEY34, to_date(null), decod" +
"e(ph.po_header_id, null, trunc(sysdate), decode(ph.global_agreement_flag, 'Y', t" +
"runc(sysdate), ph.rate_date))), decode(favl.currency, :FUNC_CURRENCY_KEY35, to_c" +
"har(null), decode(ph.po_header_id, null, :RATE_TYPE_KEY2, decode(ph.global_agree" +
"ment_flag, 'Y', psp.default_rate_type, ph.rate_type))), decode(ph.po_header_id, " +
"null, null, decode(ph.global_agreement_flag, 'Y', null, ph.rate)), favl.amount))" +
", to_number(null))"
, "FunctionalAmount", "oracle.jbo.domain.Number", new Integer(2), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "bq.currency_code", "favl.currency", "favl.currency", "CURRENCY", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(15)
        }, {
            ":FUNC_CURRENCY_KEY12", ":FUNC_CURRENCY_KEY25", ":FUNC_CURRENCY_KEY36", "FUNCTIONAL_CURRENCY", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(15)
        }, {
            "decode(bq.currency_code, :FUNC_CURRENCY_KEY13, to_char(null), decode(bq.global_a" +
"greement_flag, 'Y', psp.default_rate_type, bq.rate_type))"
, "favl.rate_type", "decode(favl.currency, :FUNC_CURRENCY_KEY37, to_char(null), decode(ph.po_header_i" +
"d, null, :RATE_TYPE_KEY3, decode(ph.global_agreement_flag, 'Y', psp.default_rate" +
"_type, ph.rate_type)))"
, "RateType", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(30)
        }, {
            "decode(bq.currency_code, :FUNC_CURRENCY_KEY14, to_date(null), decode(bq.global_a" +
"greement_flag, 'Y', trunc(sysdate), bq.rate_date))"
, "favl.rate_date", "decode(favl.currency, :FUNC_CURRENCY_KEY38, to_date(null), decode(ph.po_header_i" +
"d, null, trunc(sysdate), decode(ph.global_agreement_flag, 'Y', trunc(sysdate), p" +
"h.rate_date)))"
, "RateDate", "oracle.jbo.domain.Date", new Integer(91), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(10)
        }, {
            "decode(decode(bq.currency_code, :FUNC_CURRENCY_KEY15, to_char(null), decode(bq.g" +
"lobal_agreement_flag, 'Y', psp.default_rate_type, bq.rate_type)), 'User', decode" +
"(bq.currency_code, :FUNC_CURRENCY_KEY16, to_number(null), decode(bq.global_agree" +
"ment_flag, 'Y', to_number(null), bq.rate)), decode(bq.currency_code, :FUNC_CURRE" +
"NCY_KEY17, to_number(null), ICX_CAT_UTIL_PVT.get_rate(bq.currency_code, :FUNC_CU" +
"RRENCY_KEY18, decode(bq.currency_code, :FUNC_CURRENCY_KEY19, to_date(null),decod" +
"e(bq.global_agreement_flag, 'Y', trunc(sysdate), bq.rate_date)), decode(bq.curre" +
"ncy_code, :FUNC_CURRENCY_KEY20, to_char(null), decode(bq.global_agreement_flag, " +
"'Y', psp.default_rate_type, bq.rate_type)))))"
, "decode(favl.rate_type, 'User', favl.rate, decode(favl.currency, :FUNC_CURRENCY_K" +
"EY26, to_number(null), ICX_CAT_UTIL_PVT.get_rate(favl.currency, :FUNC_CURRENCY_K" +
"EY27, favl.rate_date, favl.rate_type)))"
, "decode(decode(favl.currency, :FUNC_CURRENCY_KEY39, to_char(null), decode(ph.po_h" +
"eader_id, null, :RATE_TYPE_KEY4, decode(ph.global_agreement_flag, 'Y', psp.defau" +
"lt_rate_type, ph.rate_type))), 'User', decode(ph.po_header_id, null, to_number(n" +
"ull), decode(ph.global_agreement_flag, 'Y', to_number(null), ph.rate)), decode(f" +
"avl.currency, :FUNC_CURRENCY_KEY40, to_number(null), ICX_CAT_UTIL_PVT.get_rate(f" +
"avl.currency, :FUNC_CURRENCY_KEY41, decode(favl.currency, :FUNC_CURRENCY_KEY42, " +
"to_date(null), decode(ph.po_header_id, null, trunc(sysdate), decode(ph.global_ag" +
"reement_flag, 'Y', trunc(sysdate), ph.rate_date))), decode(favl.currency, :FUNC_" +
"CURRENCY_KEY43, to_char(null), decode(ph.po_header_id, null, :RATE_TYPE_KEY5, de" +
"code(ph.global_agreement_flag, 'Y', psp.default_rate_type, ph.rate_type))))))"
, "Rate", "oracle.jbo.domain.Number", new Integer(2), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "decode(bq.supplier_id, -2, to_number(null), bq.supplier_id)", "favl.suggested_vendor_id", "favl.suggested_vendor_id", "SupplierId", "oracle.jbo.domain.Number", new Integer(2), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "bq.supplier_site_id", "favl.suggested_vendor_site_id", "favl.suggested_vendor_site_id", "SupplierSiteId", "oracle.jbo.domain.Number", new Integer(2), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "bq.supplier_contact_id", "favl.suggested_vendor_contact_id", "favl.suggested_vendor_contact_id", "SupplierContactId", "oracle.jbo.domain.Number", new Integer(2), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "'N'", "favl.new_supplier", "favl.new_supplier", "NewSupplierFlag", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(1)
        }, {
            "bq.supplier", "decode(favl.new_supplier, 'Y', favl.suggested_vendor_name, pv.vendor_name)", "decode(favl.new_supplier, 'Y', favl.suggested_vendor_name, pv.vendor_name)", "SUPPLIER", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(240)
        }, {
            "pvs.vendor_site_code", "decode(favl.new_supplier, 'Y', favl.suggested_vendor_site, pvs.vendor_site_code)", "decode(favl.new_supplier, 'Y', favl.suggested_vendor_site, pvs.vendor_site_code)", "SUPPLIER_SITE", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(700)
        }, {
            "to_char(null)", "favl.suggested_vendor_contact", "favl.suggested_vendor_contact", "SupplierContactName", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(80)
        }, {
            "to_char(null)", "favl.suggested_vendor_contact_phone", "favl.suggested_vendor_contact_phone", "SupplierContactPhone", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(25)
        }, {
            "to_char(null)", "favl.suggested_vendor_contact_fax", "favl.suggested_vendor_contact_fax", "SupplierContactFax", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(25)
        }, {
            "to_char(null)", "favl.suggested_vendor_contact_email", "favl.suggested_vendor_contact_email", "SupplierContactEmail", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(2000)
        }, {
            "decode(bq.supplier_part_num, '##NULL##', to_char(null), bq.supplier_part_num)", "favl.supplier_item_num", "favl.supplier_item_num", "SUPPLIER_PART_NUM", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(25)
        }, {
            "decode(bq.supplier_part_auxid, '##NULL##', to_char(null), bq.supplier_part_auxid" +
")"
, "to_char(null)", "to_char(null)", "SUPPLIER_PART_AUXID", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(150)
        }, {
            "avtlp.manufacturer", "favl.manufacturer_name", "favl.manufacturer_name", "MANUFACTURER", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(240)
        }, {
            "av.manufacturer_part_num", "favl.manufacturer_part_number", "favl.manufacturer_part_number", "MANUFACTURER_PART_NUM", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(30)
        }, {
            "bq.buyer_id", "favl.suggested_buyer_id", "favl.suggested_buyer_id", "BuyerId", "oracle.jbo.domain.Number", new Integer(2), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "bq.rfq_required_flag", "favl.rfq_required_flag", "'N'", "RfqRequiredFlag", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(1)
        }, {
            "bq.negotiated_by_preparer_flag", "favl.negotiated_by_preparer_flag", "favl.negotiated_by_preparer_flag", "NegotiatedByPreparerFlag", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(1)
        }, {
            "to_number(null)", "favl.noncat_template_id", "to_number(null)", "NonCatTemplateId", "oracle.jbo.domain.Number", new Integer(2), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "to_char(null)", "favl.attribute1", "favl.attribute1", "Attribute1", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(150)
        }, {
            "to_char(null)", "favl.attribute2", "favl.attribute2", "Attribute2", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(150)
        }, {
            "to_char(null)", "favl.attribute3", "favl.attribute3", "Attribute3", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(150)
        }, {
            "to_char(null)", "favl.attribute4", "favl.attribute4", "attribute4", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(150)
        }, {
            "to_char(null)", "favl.attribute5", "favl.attribute5", "Attribute5", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(150)
        }, {
            "to_char(null)", "favl.attribute6", "favl.attribute6", "attribute6", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(150)
        }, {
            "to_char(null)", "favl.attribute7", "favl.attribute7", "Attribute7", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(150)
        }, {
            "to_char(null)", "favl.attribute8", "favl.attribute8", "Attribute8", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(150)
        }, {
            "to_char(null)", "favl.attribute9", "favl.attribute9", "Attribute9", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(150)
        }, {
            "to_char(null)", "favl.attribute10", "favl.attribute10", "Attribute10", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(150)
        }, {
            "to_char(null)", "favl.attribute11", "favl.attribute11", "Attribute11", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(150)
        }, {
            "to_char(null)", "favl.attribute12", "favl.attribute12", "Attribute12", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(150)
        }, {
            "to_char(null)", "favl.attribute13", "favl.attribute13", "Attribute13", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(150)
        }, {
            "to_char(null)", "favl.attribute14", "favl.attribute14", "Attribute14", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(150)
        }, {
            "to_char(null)", "favl.attribute15", "favl.attribute15", "Attribute15", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(150)
        }, {
            "av.thumbnail_image", "to_char(null)", "favl.thumbnail_image", "THUMBNAIL_IMAGE", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(700)
        }, {
            "av.picture", "to_char(null)", "favl.picture", "PICTURE", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(700)
        }, {
            "avtlp.alias", "to_char(null)", "to_char(null)", "ALIAS", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(700)
        }, {
            "avtlp.comments", "to_char(null)", "to_char(null)", "COMMENTS", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(700)
        }, {
            "av.availability", "to_char(null)", "to_char(null)", "AVAILABILITY", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(700)
        }, {
            "av.lead_time", "to_number(null)", "to_number(null)", "LEAD_TIME", "oracle.jbo.domain.Number", new Integer(2), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "av.supplier_url", "to_char(null)", "to_char(null)", "SUPPLIER_URL", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(700)
        }, {
            "av.manufacturer_url", "to_char(null)", "to_char(null)", "MANUFACTURER_URL", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(700)
        }, {
            "av.attachment_url", "to_char(null)", "to_char(null)", "ATTACHMENT_URL", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(700)
        }, {
            "bq.is_item_available", "1", "1", "IsItemAvailable", "java.lang.Boolean", new Integer(-7), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "decode(bq.is_item_available, 1, 0, 1)", "0", "0", "IsItemNotAvailable", "java.lang.Boolean", new Integer(-7), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "decode(nvl(bq.req_template_name, '-2'), '-2', 0, 1)", "0", "0", "IsReqTemplate", "java.lang.Boolean", new Integer(-7), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "DECODE(bq.source_type, 'MASTER_ITEM', DECODE(bq.item_type, 'PURCHASE', 0, 1), 'I" +
"NTERNAL_TEMPLATE', 1, DECODE(msikfv.internal_order_enabled_flag, 'Y', 1, 0))"
, "0", "0", "IsInternallyOrderable", "java.lang.Boolean", new Integer(-7), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "DECODE(bq.source_type, 'MASTER_ITEM', DECODE(bq.item_type, 'INTERNAL', 0, 1), 'I" +
"NTERNAL_TEMPLATE', 0, 1)"
, "1", "1", "IsPurchasable", "java.lang.Boolean", new Integer(-7), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "DECODE(bq.source_type, 'MASTER_ITEM', bq.item_type, 'INTERNAL_TEMPLATE', 'INTERN" +
"AL', DECODE(msikfv.internal_order_enabled_flag, 'Y', 'BOTH', 'PURCHASE'))"
, "'PURCHASE'", "'PURCHASE'", "ItemType", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(8)
        }, {
            "bq.favorite_list_id", "favl.favorite_list_id", "favl.favorite_list_id", "FavoriteListId", "oracle.jbo.domain.Number", new Integer(2), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "bq.favorite_list_line_id", "favl.favorite_list_line_id", "favl.favorite_list_line_id", "FavoriteListLineId", "oracle.jbo.domain.Number", new Integer(2), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(-1)
        }, {
            "av.UNSPSC", "to_char(null)", "favl.unspsc_code", "UNSPSC", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(30)
        }, {
            "to_number(null)", "to_number(null)", "favl.hazard_class_id", "HazardClassId", "oracle.jbo.domain.Number", new Integer(2), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(30)
        }, {
            "'CATALOG'", "'NONCATALOG'", "'EXTERNAL'", "CatalogType", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(255)
        }, {
            "'INTERNAL'", "'INTERNAL'", "'EXTERNAL'", "CatalogSource", "java.lang.String", new Integer(12), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(255)
        }, {
            "to_number(null)", "to_number(null)", "favl.content_zone_id", "ContentZoneId", "oracle.jbo.domain.Number", new Integer(2), new Boolean(false), new Boolean(true), new Byte((byte)0), new Integer(30)
        }
    };
    protected static final ArrayList m_excludeDesciptors;

    public ShoppingVOBuilder()
    {
    }

    public OAViewObjectImpl getViewObject(VOBuilderContext vobuildercontext, String s)
    {
        OAApplicationModuleImpl oaapplicationmoduleimpl = vobuildercontext.getApplicationModule();
        OADBTransaction oadbtransaction = oaapplicationmoduleimpl.getOADBTransaction();
        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "getViewObject.begin", 2);
        }
        OAViewObjectImpl oaviewobjectimpl = null;
        String s1 = getCacheName();
        try
        {
            oaviewobjectimpl = getViewObjectFromCache(vobuildercontext, s, s1);
            if(oaviewobjectimpl.getKeyAttributeDefs().length == 0)
            {
                int i = oaviewobjectimpl.getAttributeIndexOf("ItemKey");
                if(i >= 0)
                {
                    int ai[] = {
                        i
                    };
                    oaviewobjectimpl.setKeyAttributeDefs(ai);
                }
            }
        }
        catch(FrameworkException frameworkexception)
        {
            if(oadbtransaction.isLoggingEnabled(4))
            {
                oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("Got FrameworkException when calling getViewObjectFromCache, e = ").append(frameworkexception).toString(), 4);
            }
        }
        ArrayList arraylist = getAdditionalWhereClauseAndBindKeys(vobuildercontext);
        String s2 = (String)arraylist.get(0);
        ArrayList arraylist1 = (ArrayList)arraylist.get(1);
        if(oadbtransaction.isLoggingEnabled(1))
        {
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("additionalWhereClause = ").append(s2).toString(), 1);
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("additionalBindKeys = ").append(arraylist1).toString(), 1);
        }
        oaviewobjectimpl.setWhereClause(null);
        if(s2 != null && !"".equals(s2))
        {
            oaviewobjectimpl.setWhereClause(s2);
        }
        boolean flag = vobuildercontext.getIsResultsInGrid();
        if(oadbtransaction.isLoggingEnabled(1))
        {
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("isGridFormat = ").append(flag).toString(), 1);
        }
        if(!flag || "publicList".equals(vobuildercontext.getBaseViewBuilderType()))
        {
            String s3 = constructOrderByClause(vobuildercontext);
            if(oadbtransaction.isLoggingEnabled(1))
            {
                oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("orderByClause = ").append(s3).toString(), 1);
            }
            oaviewobjectimpl.setOrderByClause(s3);
        }
        ArrayList arraylist2 = getBindKeys(vobuildercontext);
        if(arraylist1 != null)
        {
            arraylist2.addAll(arraylist1);
        }
        if(oadbtransaction.isLoggingEnabled(1))
        {
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("allBindKeys = ").append(arraylist2).toString(), 1);
        }
        setBindParameters(oaviewobjectimpl, vobuildercontext, arraylist2);
        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "getViewObject.end", 2);
        }
        return oaviewobjectimpl;
    }

    protected ArrayList constructKey(VOBuilderContext vobuildercontext)
    {
        OAApplicationModuleImpl oaapplicationmoduleimpl = vobuildercontext.getApplicationModule();
        OADBTransaction oadbtransaction = oaapplicationmoduleimpl.getOADBTransaction();
        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "constructKey.begin", 2);
        }
        ArrayList arraylist = new ArrayList();
        CategoryElement categoryelement = vobuildercontext.getBaseElement();
        CategoryElement categoryelement1 = vobuildercontext.getCategoryElement();
        String s = (new StringBuilder()).append("").append(vobuildercontext.getCatID()).toString();
        HashSet hashset = vobuildercontext.getIncludedSourceTypes();
        String s1 = vobuildercontext.getShoppingFlow();
        if(oadbtransaction.isLoggingEnabled(1))
        {
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("categoryIdStr = ").append(s).toString(), 1);
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("includedSourceTypes = ").append(hashset).toString(), 1);
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("shoppingFlow = ").append(s1).toString(), 1);
        }
        arraylist.add(s);
        arraylist.add(new Integer(categoryelement != null ? categoryelement.getVersion() : 0));
        arraylist.add(new Integer(categoryelement1 != null ? categoryelement1.getVersion() : 0));
        arraylist.add(hashset != null ? ((Object) (new HashSet(hashset))) : null);
        if("po".equals(s1))
        {
            arraylist.add(new Boolean(true));
        } else
        {
            arraylist.add(new Boolean(false));
        }
        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "constructKey.end", 2);
        }
        return arraylist;
    }

    protected abstract ArrayList getBindKeys(VOBuilderContext vobuildercontext);

    protected String constructOrderByClause(VOBuilderContext vobuildercontext)
    {
        return null;
    }

    public String constructSelectClause(VOBuilderContext vobuildercontext, OAViewDefImpl oaviewdefimpl)
    {
        OAApplicationModuleImpl oaapplicationmoduleimpl = vobuildercontext.getApplicationModule();
        OADBTransaction oadbtransaction = oaapplicationmoduleimpl.getOADBTransaction();
        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "constructSelectClause.begin", 2);
        }
        String s = " * ";
        if(oadbtransaction.isLoggingEnabled(1))
        {
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("selectClause = ").append(s).toString(), 1);
        }
        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "constructSelectClause.end", 2);
        }
        return s;
    }

    public String constructFromClause(VOBuilderContext vobuildercontext, OAViewDefImpl oaviewdefimpl)
    {
        OAApplicationModuleImpl oaapplicationmoduleimpl = vobuildercontext.getApplicationModule();
        OADBTransaction oadbtransaction = oaapplicationmoduleimpl.getOADBTransaction();
        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "constructFromClause.begin", 2);
        }
        StringBuffer stringbuffer = new StringBuffer();
        stringbuffer.append("( ");
        stringbuffer.append(constructLocalQuery(vobuildercontext, oaviewdefimpl));
        stringbuffer.append(") bvoq");
        if(oadbtransaction.isLoggingEnabled(1))
        {
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("fromClauseBuffer = ").append(stringbuffer).toString(), 1);
        }
        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "constructFromClause.end", 2);
        }
        return stringbuffer.toString();
    }

    public String constructWhereClause(VOBuilderContext vobuildercontext)
    {
        OAApplicationModuleImpl oaapplicationmoduleimpl = vobuildercontext.getApplicationModule();
        OADBTransaction oadbtransaction = oaapplicationmoduleimpl.getOADBTransaction();
        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "constructWhereClause.begin", 2);
        }

        String s = null;
        if(oadbtransaction.isLoggingEnabled(1))
        {
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("whereClause = ").append(s).toString(), 1);
        }
        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "constructWhereClause.end", 2);
        }
        return s;
    }

    public String constructLocalQuery(VOBuilderContext vobuildercontext, OAViewDefImpl oaviewdefimpl)
    {
        OAApplicationModuleImpl oaapplicationmoduleimpl = vobuildercontext.getApplicationModule();
        OADBTransaction oadbtransaction = oaapplicationmoduleimpl.getOADBTransaction();
        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "constructLocalQuery.begin", 2);
        }
        StringBuffer stringbuffer = new StringBuffer();
        stringbuffer.append("SELECT ");
        stringbuffer.append(constructLocalSelectClause(vobuildercontext, oaviewdefimpl));
        stringbuffer.append(" FROM ");
        stringbuffer.append(constructLocalFromClause(vobuildercontext));
        stringbuffer.append(" WHERE ");
        stringbuffer.append(constructLocalWhereClause(vobuildercontext));

        if(oadbtransaction.isLoggingEnabled(1))
        {
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("localQueryBuffer = ").append(stringbuffer).toString(), 1);
        }
        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "constructLocalQuery.end", 2);
        }
        return stringbuffer.toString();
    }

    public String constructLocalSelectClause(VOBuilderContext vobuildercontext, OAViewDefImpl oaviewdefimpl)
    {
        OAApplicationModuleImpl oaapplicationmoduleimpl = vobuildercontext.getApplicationModule();
        OADBTransaction oadbtransaction = oaapplicationmoduleimpl.getOADBTransaction();
        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "constructLocalSelectClause.begin", 2);
        }
        String s = constructLocalSelectClause(vobuildercontext, oaviewdefimpl, false);
        if(oadbtransaction.isLoggingEnabled(1))
        {
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("selectClause = ").append(s).toString(), 1);
        }
        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "constructLocalSelectClause.end", 2);
        }
        return s;
    }

    public String constructLocalSelectClause(VOBuilderContext vobuildercontext, OAViewDefImpl oaviewdefimpl, boolean flag)
    {
        OAApplicationModuleImpl oaapplicationmoduleimpl = vobuildercontext.getApplicationModule();
        OADBTransaction oadbtransaction = oaapplicationmoduleimpl.getOADBTransaction();
        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "constructLocalSelectClause.begin", 2);
        }
        StringBuffer stringbuffer = new StringBuffer();
        for(int i = 0; i < SELECT_CLAUSE_ARRAY.length; i++)
        {
            if(i != 0)
            {
                stringbuffer.append(",");
            }
            Object aobj[] = SELECT_CLAUSE_ARRAY[i];
            String s = (String)aobj[0];
            String s1 = (String)aobj[3];
            if(oadbtransaction.isLoggingEnabled(1))
            {
                oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("colExp = ").append(s).toString(), 1);
                oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("alias = ").append(s1).toString(), 1);
            }
            String s2 = (String)aobj[4];
            Integer integer = (Integer)aobj[5];
            Boolean boolean1 = (Boolean)aobj[6];
            Boolean boolean2 = (Boolean)aobj[7];
            Byte byte1 = null;
            if(flag)
            {
                byte1 = new Byte((byte)2);
            } else
            {
                byte1 = (Byte)aobj[8];
            }
            Integer integer1 = (Integer)aobj[9];
            stringbuffer.append(s);
            stringbuffer.append(' ');
            stringbuffer.append(s1);
            if(oaviewdefimpl != null)
            {
                oaviewdefimpl.addSqlDerivedAttrDef(s1, s1, s2, integer.intValue(), boolean1.booleanValue(), boolean2.booleanValue(), byte1.byteValue(), integer1.intValue());
            }
        }

        CategoryElement categoryelement = vobuildercontext.getBaseElement();
        if(flag)
        {
            appendBaseAttributes(vobuildercontext, stringbuffer, categoryelement, false, oaviewdefimpl, true);
        } else
        {
            appendBaseAttributes(vobuildercontext, stringbuffer, categoryelement, false, oaviewdefimpl);
        }
        addTransientAttributes(vobuildercontext, oaviewdefimpl);
        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "constructLocalSelectClause.end", 2);
        }
        return stringbuffer.toString();
    }

    protected void addTransientAttributes(VOBuilderContext vobuildercontext, OAViewDefImpl oaviewdefimpl)
    {
        OAApplicationModuleImpl oaapplicationmoduleimpl = vobuildercontext.getApplicationModule();
        OADBTransaction oadbtransaction = oaapplicationmoduleimpl.getOADBTransaction();
        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "addTransientAttributes.begin", 2);
        }
        if(oaviewdefimpl != null)
        {
            oaviewdefimpl.addTransientAttrDef("SelectAttr", "java.lang.String", "N", true, (byte)2);
            oaviewdefimpl.addTransientAttrDef("MoveToListId", "oracle.jbo.domain.Number", "", false, (byte)2);
            oaviewdefimpl.addTransientAttrDef("SupplierCode", "java.lang.String", "", false, (byte)2);
            oaviewdefimpl.addTransientAttrDef("LineType", "java.lang.String", "", false, (byte)2);
            oaviewdefimpl.addTransientAttrDef("ExternalUom", "java.lang.String", "", false, (byte)2);
            oaviewdefimpl.addTransientAttrDef("CategoryCode", "java.lang.String", "", false, (byte)2);
            oaviewdefimpl.addTransientAttrDef("ContentZoneUrl", "java.lang.String", "", false, (byte)2);
            oaviewdefimpl.addTransientAttrDef("SupplierReferenceNumber", "java.lang.String", "", false, (byte)2);
            oaviewdefimpl.addTransientAttrDef("IsPriceAvailable", "java.lang.Boolean", "", false, (byte)2);
        }
        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "addTransientAttributes.end", 2);
        }
    }

    public String constructLocalFromClause(VOBuilderContext vobuildercontext)
    {
        OAApplicationModuleImpl oaapplicationmoduleimpl = vobuildercontext.getApplicationModule();
        OADBTransaction oadbtransaction = oaapplicationmoduleimpl.getOADBTransaction();
        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "constructLocalFromClause.begin", 2);
        }
        StringBuffer stringbuffer = new StringBuffer();
        HashSet hashset = vobuildercontext.getIncludedSourceTypes();
        if(oadbtransaction.isLoggingEnabled(1))
        {
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("includedSourceTypes = ").append(hashset).toString(), 1);
        }
        boolean flag = hashset.contains("MASTER_ITEM") && hashset.size() > 1;
        String s = vobuildercontext.getShoppingFlow();
        if(oadbtransaction.isLoggingEnabled(1))
        {
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("shoppingFlow = ").append(s).toString(), 1);
        }
        boolean flag1 = "po".equals(s);
        if(oadbtransaction.isLoggingEnabled(1))
        {
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("doPrecedence = ").append(flag).toString(), 1);
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("isSicPoFlow = ").append(flag1).toString(), 1);
        }
        if(flag && flag1)
        {
			// Modified below query for R12 Upgrade Retrofit
            stringbuffer.append("(SELECT ctxh.inventory_item_id, ctxh.po_line_id, ctxh.req_template_name, ctxh.re" +
"q_template_line_num, ctxh.org_id, ctxh.language, ctxh.source_type, ctxh.purchasi" +
"ng_org_id, ctxh.ip_category_id, ctxh.ip_category_name, ctxh.po_category_id, ctxh" +
".owning_org_id, ctxh.supplier_id, ctxh.supplier_part_num, ctxh.supplier_part_aux" +
"id, ctxh.supplier_site_id, ctxh.item_type, ctxh.item_revision, ctxh.po_header_id" +
", ctxh.document_number, ctxh.line_num, ctxh.allow_price_override_flag, ctxh.not_" +
"to_exceed_price, ctxh.line_type_id, ctxh.unit_meas_lookup_code, ctxh.unit_price," +
" ctxh.amount, nvl(ctxh.currency_code, :FUNC_CURRENCY_KEY11) currency_code, ctxh." +
"rate_type, ctxh.rate_date, ctxh.rate, ctxh.buyer_id, ctxh.supplier_contact_id, c" +
"txh.rfq_required_flag, ctxh.negotiated_by_preparer_flag, ctxh.description, ctxh." +
"supplier, ctxh.req_template_po_line_id, ctxh.order_type_lookup_code, ctxh.merged" +
"_source_type, ctxh.global_agreement_flag, ctxh.suggested_quantity, score(1) rele" +
"vance_score, 1 as is_item_available,  to_number(null) favorite_list_id, to_numbe" +
"r(null) favorite_list_line_id , count(*) over (partition by ctxh.inventory_item_" +
"id, ctxh.purchasing_org_id, ctxh.language) as source_count, row_number() over (p" +
"artition by ctxh.inventory_item_id, ctxh.po_line_id, ctxh.req_template_name, ctx" +
"h.req_template_line_num, ctxh.purchasing_org_id, ctxh.language ORDER BY ctxh.inv" +
"entory_item_id) as rownum1 FROM icx_cat_items_ctx_hdrs_tlp ctxh WHERE contains(c" +
"txh.ctx_desc, :INTERMEDIA_KEY1, 1) > 0 AND ICX_CAT_UTIL_PVT.is_item_valid_for_se" +
"arch( ctxh.source_type, ctxh.po_line_id, ctxh.req_template_name, ctxh.req_templa" +
"te_line_num, ctxh.po_category_id, ctxh.org_id) = 1 AND EXISTS (select 1 from XX_" +
"PO_RESP_CATSETS_V WHERE inventory_item_id = ctxh.inventory_item_id)) bq , po_sys" +
"tem_parameters_all psp, mtl_units_of_measure_tl muomtl, icx_cat_attribute_values" +
"av,icx_cat_attribute_values_tlp avtlp, po_vendor_sites_all pvs, mtl_categories_k" +
"fv mck, mtl_system_items_kfv msikfv "
);
        } else
        if(flag && !flag1)
        {
			// Modified below query for R12 Upgrade Retrofit
            stringbuffer.append("(SELECT ctxh.inventory_item_id, ctxh.po_line_id, ctxh.req_template_name, ctxh.re" +
"q_template_line_num, ctxh.org_id, ctxh.language, ctxh.source_type, ctxh.purchasi" +
"ng_org_id, ctxh.ip_category_id, ctxh.ip_category_name, ctxh.po_category_id, ctxh" +
".owning_org_id, ctxh.supplier_id, ctxh.supplier_part_num, ctxh.supplier_part_aux" +
"id, ctxh.supplier_site_id, ctxh.item_type, ctxh.item_revision, ctxh.po_header_id" +
", ctxh.document_number, ctxh.line_num, ctxh.allow_price_override_flag, ctxh.not_" +
"to_exceed_price, ctxh.line_type_id, ctxh.unit_meas_lookup_code, ctxh.unit_price," +
" ctxh.amount, nvl(ctxh.currency_code, :FUNC_CURRENCY_KEY11) currency_code, ctxh." +
"rate_type, ctxh.rate_date, ctxh.rate, ctxh.buyer_id, ctxh.supplier_contact_id, c" +
"txh.rfq_required_flag, ctxh.negotiated_by_preparer_flag, ctxh.description, ctxh." +
"supplier, ctxh.req_template_po_line_id, ctxh.order_type_lookup_code, ctxh.merged" +
"_source_type, ctxh.global_agreement_flag, ctxh.suggested_quantity, score(1) rele" +
"vance_score, 1 as is_item_available,  to_number(null) favorite_list_id, to_numbe" +
"r(null) favorite_list_line_id , count(*) over (partition by ctxh.inventory_item_" +
"id, ctxh.org_id, ctxh.language) as source_count FROM icx_cat_items_ctx_hdrs_tlp " +
"ctxh WHERE contains(ctxh.ctx_desc, :INTERMEDIA_KEY1, 1) > 0 AND ICX_CAT_UTIL_PVT" +
".is_item_valid_for_search( ctxh.source_type, ctxh.po_line_id, ctxh.req_template_" +
"name, ctxh.req_template_line_num, ctxh.po_category_id, ctxh.org_id) = 1 AND EXIS" +
"TS (select 1 from XX_PO_RESP_CATSETS_V WHERE inventory_item_id = ctxh.inventory_" +
"item_id)) bq , po_system_parameters_all psp, mtl_units_of_measure_tl muomtl, icx" +
"_cat_attribute_values av,icx_cat_attribute_values_tlp avtlp, po_vendor_sites_all" +
"pvs, mtl_categories_kfv mck, mtl_system_items_kfv msikfv "
);
        } else
        if(!flag && flag1)
        {
			// Modified below query for R12 Upgrade Retrofit
            stringbuffer.append("(SELECT ctxh.inventory_item_id, ctxh.po_line_id, ctxh.req_template_name, ctxh.re" +
"q_template_line_num, ctxh.org_id, ctxh.language, ctxh.source_type, ctxh.purchasi" +
"ng_org_id, ctxh.ip_category_id, ctxh.ip_category_name, ctxh.po_category_id, ctxh" +
".owning_org_id, ctxh.supplier_id, ctxh.supplier_part_num, ctxh.supplier_part_aux" +
"id, ctxh.supplier_site_id, ctxh.item_type, ctxh.item_revision, ctxh.po_header_id" +
", ctxh.document_number, ctxh.line_num, ctxh.allow_price_override_flag, ctxh.not_" +
"to_exceed_price, ctxh.line_type_id, ctxh.unit_meas_lookup_code, ctxh.unit_price," +
" ctxh.amount, nvl(ctxh.currency_code, :FUNC_CURRENCY_KEY11) currency_code, ctxh." +
"rate_type, ctxh.rate_date, ctxh.rate, ctxh.buyer_id, ctxh.supplier_contact_id, c" +
"txh.rfq_required_flag, ctxh.negotiated_by_preparer_flag, ctxh.description, ctxh." +
"supplier, ctxh.req_template_po_line_id, ctxh.order_type_lookup_code, ctxh.merged" +
"_source_type, ctxh.global_agreement_flag, ctxh.suggested_quantity, score(1) rele" +
"vance_score, 1 as is_item_available,  to_number(null) favorite_list_id, to_numbe" +
"r(null) favorite_list_line_id , row_number() over (partition by ctxh.inventory_i" +
"tem_id, ctxh.po_line_id, ctxh.req_template_name, ctxh.req_template_line_num, ctx" +
"h.purchasing_org_id, ctxh.language ORDER BY ctxh.inventory_item_id) as rownum1 F" +
"ROM icx_cat_items_ctx_hdrs_tlp ctxh WHERE contains(ctxh.ctx_desc, :INTERMEDIA_KE" +
"Y1, 1) > 0 AND ICX_CAT_UTIL_PVT.is_item_valid_for_search( ctxh.source_type, ctxh" +
".po_line_id, ctxh.req_template_name, ctxh.req_template_line_num, ctxh.po_categor" +
"y_id, ctxh.org_id) = 1 AND EXISTS (select 1 from XX_PO_RESP_CATSETS_V WHERE inve" +
"ntory_item_id = ctxh.inventory_item_id)) bq , po_system_parameters_all psp, mtl_" +
"units_of_measure_tl muomtl, icx_cat_attribute_values av,icx_cat_attribute_values" +
"_tlp avtlp, po_vendor_sites_all pvs, mtl_categories_kfv mck, mtl_system_items_kf" +
"v msikfv "
);
        } else
        {
			// Modified below query for R12 Upgrade Retrofit
            stringbuffer.append("(SELECT ctxh.inventory_item_id, ctxh.po_line_id, ctxh.req_template_name, ctxh.re" +
"q_template_line_num, ctxh.org_id, ctxh.language, ctxh.source_type, ctxh.purchasi" +
"ng_org_id, ctxh.ip_category_id, ctxh.ip_category_name, ctxh.po_category_id, ctxh" +
".owning_org_id, ctxh.supplier_id, ctxh.supplier_part_num, ctxh.supplier_part_aux" +
"id, ctxh.supplier_site_id, ctxh.item_type, ctxh.item_revision, ctxh.po_header_id" +
", ctxh.document_number, ctxh.line_num, ctxh.allow_price_override_flag, ctxh.not_" +
"to_exceed_price, ctxh.line_type_id, ctxh.unit_meas_lookup_code, ctxh.unit_price," +
" ctxh.amount, nvl(ctxh.currency_code, :FUNC_CURRENCY_KEY11) currency_code, ctxh." +
"rate_type, ctxh.rate_date, ctxh.rate, ctxh.buyer_id, ctxh.supplier_contact_id, c" +
"txh.rfq_required_flag, ctxh.negotiated_by_preparer_flag, ctxh.description, ctxh." +
"supplier, ctxh.req_template_po_line_id, ctxh.order_type_lookup_code, ctxh.merged" +
"_source_type, ctxh.global_agreement_flag, ctxh.suggested_quantity, score(1) rele" +
"vance_score, 1 as is_item_available,  to_number(null) favorite_list_id, to_numbe" +
"r(null) favorite_list_line_id FROM icx_cat_items_ctx_hdrs_tlp ctxh WHERE contain" +
"s(ctxh.ctx_desc, :INTERMEDIA_KEY1, 1) > 0 AND ICX_CAT_UTIL_PVT.is_item_valid_for" +
"_search( ctxh.source_type, ctxh.po_line_id, ctxh.req_template_name, ctxh.req_tem" +
"plate_line_num, ctxh.po_category_id, ctxh.org_id) = 1 AND EXISTS (select 1 from " +
"XX_PO_RESP_CATSETS_V WHERE inventory_item_id = ctxh.inventory_item_id)) bq , po_" +
"system_parameters_all psp, mtl_units_of_measure_tl muomtl, icx_cat_attribute_val" +
"ues av,icx_cat_attribute_values_tlp avtlp, po_vendor_sites_all pvs, mtl_categori" +
"es_kfv mck, mtl_system_items_kfv msikfv "
);
        }
        if(oadbtransaction.isLoggingEnabled(1))
        {
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("fromClauseBuffer = ").append(stringbuffer).toString(), 1);
        }
        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "constructLocalFromClause.end", 2);
        }
        return stringbuffer.toString();
    }

    public String constructLocalWhereClause(VOBuilderContext vobuildercontext)
    {
        OAApplicationModuleImpl oaapplicationmoduleimpl = vobuildercontext.getApplicationModule();
        OADBTransaction oadbtransaction = oaapplicationmoduleimpl.getOADBTransaction();
        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "constructLocalWhereClause.begin", 2);
        }
        StringBuffer stringbuffer = new StringBuffer();
        HashSet hashset = vobuildercontext.getIncludedSourceTypes();
        if(oadbtransaction.isLoggingEnabled(1))
        {
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("includedSourceTypes = ").append(hashset).toString(), 1);
        }
        boolean flag = hashset.contains("MASTER_ITEM") && hashset.size() > 1;
        String s = vobuildercontext.getShoppingFlow();
        if(oadbtransaction.isLoggingEnabled(1))
        {
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("shoppingFlow = ").append(s).toString(), 1);
        }
        boolean flag1 = "po".equals(s);
        if(oadbtransaction.isLoggingEnabled(1))
        {
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("doPrecedence = ").append(flag).toString(), 1);
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("isSicPoFlow = ").append(flag1).toString(), 1);
        }
        if(flag && flag1)
        {
            stringbuffer.append("(bq.source_count = 1 OR bq.source_type <> 'MASTER_ITEM') AND bq.rownum1 = 1 AND " +
"psp.org_id = :ORG_ID_KEY2 AND bq.unit_meas_lookup_code = muomtl.unit_of_measure(" +
"+) AND bq.language = muomtl.language(+) AND bq.inventory_item_id = av.inventory_" +
"item_id(+) AND bq.owning_org_id = av.org_id(+) AND bq.po_line_id = av.po_line_id" +
"(+) AND bq.req_template_name = av.req_template_name(+) AND bq.req_template_line_" +
"num = av.req_template_line_num(+) AND bq.inventory_item_id = avtlp.inventory_ite" +
"m_id(+) AND bq.owning_org_id = avtlp.org_id(+) AND bq.po_line_id = avtlp.po_line" +
"_id(+) AND bq.req_template_name = avtlp.req_template_name(+) AND bq.req_template" +
"_line_num = avtlp.req_template_line_num(+) AND bq.language = avtlp.language(+) A" +
"ND bq.supplier_site_id = pvs.vendor_site_id(+) AND bq.po_category_id = mck.categ" +
"ory_id(+) AND bq.inventory_item_id = msikfv.inventory_item_id(+) AND msikfv.orga" +
"nization_id(+) = :INV_ORG_ID_KEY1 "
);
        } else
        if(flag && !flag1)
        {
            stringbuffer.append("(bq.source_count = 1 OR bq.source_type <> 'MASTER_ITEM') AND psp.org_id = :ORG_I" +
"D_KEY2 AND bq.unit_meas_lookup_code = muomtl.unit_of_measure(+) AND bq.language " +
"= muomtl.language(+) AND bq.inventory_item_id = av.inventory_item_id(+) AND bq.o" +
"wning_org_id = av.org_id(+) AND bq.po_line_id = av.po_line_id(+) AND bq.req_temp" +
"late_name = av.req_template_name(+) AND bq.req_template_line_num = av.req_templa" +
"te_line_num(+) AND bq.inventory_item_id = avtlp.inventory_item_id(+) AND bq.owni" +
"ng_org_id = avtlp.org_id(+) AND bq.po_line_id = avtlp.po_line_id(+) AND bq.req_t" +
"emplate_name = avtlp.req_template_name(+) AND bq.req_template_line_num = avtlp.r" +
"eq_template_line_num(+) AND bq.language = avtlp.language(+) AND bq.supplier_site" +
"_id = pvs.vendor_site_id(+) AND bq.po_category_id = mck.category_id(+) AND bq.in" +
"ventory_item_id = msikfv.inventory_item_id(+) AND msikfv.organization_id(+) = :I" +
"NV_ORG_ID_KEY1 "
);
        } else
        if(!flag && flag1)
        {
            stringbuffer.append("bq.rownum1 = 1 AND psp.org_id = :ORG_ID_KEY2 AND bq.unit_meas_lookup_code = muom" +
"tl.unit_of_measure(+) AND bq.language = muomtl.language(+) AND bq.inventory_item" +
"_id = av.inventory_item_id(+) AND bq.owning_org_id = av.org_id(+) AND bq.po_line" +
"_id = av.po_line_id(+) AND bq.req_template_name = av.req_template_name(+) AND bq" +
".req_template_line_num = av.req_template_line_num(+) AND bq.inventory_item_id = " +
"avtlp.inventory_item_id(+) AND bq.owning_org_id = avtlp.org_id(+) AND bq.po_line" +
"_id = avtlp.po_line_id(+) AND bq.req_template_name = avtlp.req_template_name(+) " +
"AND bq.req_template_line_num = avtlp.req_template_line_num(+) AND bq.language = " +
"avtlp.language(+) AND bq.supplier_site_id = pvs.vendor_site_id(+) AND bq.po_cate" +
"gory_id = mck.category_id(+) AND bq.inventory_item_id = msikfv.inventory_item_id" +
"(+) AND msikfv.organization_id(+) = :INV_ORG_ID_KEY1 "
);
        } else
        {
            stringbuffer.append("psp.org_id = :ORG_ID_KEY2 AND bq.unit_meas_lookup_code = muomtl.unit_of_measure(" +
"+) AND bq.language = muomtl.language(+) AND bq.inventory_item_id = av.inventory_" +
"item_id(+) AND bq.owning_org_id = av.org_id(+) AND bq.po_line_id = av.po_line_id" +
"(+) AND bq.req_template_name = av.req_template_name(+) AND bq.req_template_line_" +
"num = av.req_template_line_num(+) AND bq.inventory_item_id = avtlp.inventory_ite" +
"m_id(+) AND bq.owning_org_id = avtlp.org_id(+) AND bq.po_line_id = avtlp.po_line" +
"_id(+) AND bq.req_template_name = avtlp.req_template_name(+) AND bq.req_template" +
"_line_num = avtlp.req_template_line_num(+) AND bq.language = avtlp.language(+) A" +
"ND bq.supplier_site_id = pvs.vendor_site_id(+) AND bq.po_category_id = mck.categ" +
"ory_id(+) AND bq.inventory_item_id = msikfv.inventory_item_id(+) AND msikfv.orga" +
"nization_id(+) = :INV_ORG_ID_KEY1 "
);
        }



        if(oadbtransaction.isLoggingEnabled(1))
        {
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("whereClauseBuffer = ").append(stringbuffer).toString(), 1);
        }



        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "constructLocalWhereClause.end", 2);
        }
        return stringbuffer.toString();
    }

    protected void appendBaseAttributes(VOBuilderContext vobuildercontext, StringBuffer stringbuffer, CategoryElement categoryelement, boolean flag, OAViewDefImpl oaviewdefimpl)
    {
        appendAttributes(vobuildercontext, categoryelement, flag, stringbuffer, oaviewdefimpl, m_excludeDesciptors, false);
    }

    protected void appendBaseAttributes(VOBuilderContext vobuildercontext, StringBuffer stringbuffer, CategoryElement categoryelement, boolean flag, OAViewDefImpl oaviewdefimpl, boolean flag1)
    {
        appendAttributes(vobuildercontext, categoryelement, flag, stringbuffer, oaviewdefimpl, m_excludeDesciptors, flag1);
    }

    protected void appendCategoryAttributes(VOBuilderContext vobuildercontext, StringBuffer stringbuffer, CategoryElement categoryelement, boolean flag, OAViewDefImpl oaviewdefimpl)
    {
        appendAttributes(vobuildercontext, categoryelement, flag, stringbuffer, oaviewdefimpl, null, false);
    }

    private void appendAttributes(VOBuilderContext vobuildercontext, CategoryElement categoryelement, boolean flag, StringBuffer stringbuffer, OAViewDefImpl oaviewdefimpl, ArrayList arraylist, boolean flag1)
    {
        OAApplicationModuleImpl oaapplicationmoduleimpl = vobuildercontext.getApplicationModule();
        OADBTransaction oadbtransaction = oaapplicationmoduleimpl.getOADBTransaction();
        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "appendAttributes.begin", 2);
        }
        if(oadbtransaction.isLoggingEnabled(1))
        {
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("nullStoredIn = ").append(flag).toString(), 1);
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("selectClause = ").append(stringbuffer).toString(), 1);
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("excludeDescriptors = ").append(arraylist).toString(), 1);
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("isUpdateable = ").append(flag1).toString(), 1);
        }
        DescriptorElement adescriptorelement[] = categoryelement.getDescriptors();
        Object obj = null;
        String s1 = null;
        Object obj1 = null;
        Object obj2 = null;
        Object obj3 = null;
        byte byte0 = 0;
        if(flag1)
        {
            byte0 = 2;
        }
        for(int i = 0; i < adescriptorelement.length; i++)
        {
            if(adescriptorelement[i] == null)
            {
                continue;
            }
            String s2 = adescriptorelement[i].getStoredInColumn();
            String s3 = adescriptorelement[i].getStoredInTable();
            String s4 = adescriptorelement[i].getKey();
            if(oadbtransaction.isLoggingEnabled(1))
            {
                oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("colName = ").append(s2).toString(), 1);
                oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("storedInTable = ").append(s3).toString(), 1);
                oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("key = ").append(s4).toString(), 1);
            }
            if("PO_ATTRIBUTE_VALUES".equals(s3))
            {
                s1 = "av";
            } else
            if("PO_ATTRIBUTE_VALUES_TLP".equals(s3))
            {
                s1 = "avtlp";
            }
            if(oadbtransaction.isLoggingEnabled(1))
            {
                oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("tableAlias = ").append(s1).toString(), 1);
            }
            String s = s2;
            if("THUMBNAIL_IMAGE".equals(s4))
            {
                stringbuffer.append(", decode(substr(lower(");
                stringbuffer.append(s2);
                stringbuffer.append("), 1, 7), 'http://', 0, decode(substr(lower(");
                stringbuffer.append(s2);
                stringbuffer.append("), 1, 8), 'https://', 0, 1))");
                stringbuffer.append(" AS IsThumbnailFile");
                if(oaviewdefimpl != null)
                {
                    oaviewdefimpl.addSqlDerivedAttrDef("IsThumbnailFile", "IsThumbnailFile", "java.lang.Boolean", -7, false, true, byte0, -1);
                }
            }
            if(s3 == null || arraylist != null && arraylist.contains(adescriptorelement[i].getKey()))
            {
                continue;
            }
            stringbuffer.append(",");
            stringbuffer.append((new StringBuilder()).append(flag ? "null" : (new StringBuilder()).append(s1).append(".").append(s2).toString()).append(" ").append(s).toString());
            if(oaviewdefimpl == null)
            {
                continue;
            }
            byte byte1 = -1;
            char c = '\uFFFF';
            String s5 = "java.lang.String";
            if(1 == Integer.parseInt(adescriptorelement[i].getType()))
            {
                if(oadbtransaction.isLoggingEnabled(1))
                {
                    oadbtransaction.writeDiagnostics(this, "descriptor is numeric", 1);
                }
                s5 = "oracle.jbo.domain.Number";
                byte1 = 2;
                c = '\uFFFF';
            } else
            if("DESCRIPTION".equals(s4))
            {
                byte1 = 12;
                c = '\360';
            } else
            if("LONG_DESCRIPTION".equals(s4))
            {
                byte1 = 12;
                c = '\u07D0';
            } else
            if("SUPPLIER_PART_NUM".equals(s4))
            {
                byte1 = 12;
                c = '\u07D0';
            } else
            if("MANUFACTURER".equals(s4))
            {
                byte1 = 12;
                c = '\u07D0';
            } else
            if("MANUFACTURER_PART_NUM".equals(s4))
            {
                byte1 = 12;
                c = '\u07D0';
            } else
            {
                byte1 = 12;
                c = '\u02BC';
            }
            oaviewdefimpl.addSqlDerivedAttrDef(s, s, s5, byte1, false, true, byte0, c);
        }

        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "appendAttributes.end", 2);
        }
    }

    protected ArrayList getAdditionalWhereClauseAndBindKeys(VOBuilderContext vobuildercontext)
    {
        RequisitionAMImpl requisitionamimpl = (RequisitionAMImpl)vobuildercontext.getApplicationModule();
        OADBTransaction oadbtransaction = requisitionamimpl.getOADBTransaction();
        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "getAdditionalWhereClauseAndBindKeys.begin", 2);
        }
        ArrayList arraylist = new ArrayList(2);
        String s = null;
        ArrayList arraylist1 = null;
        boolean flag = vobuildercontext.getIsSearchFiltered();
        if(oadbtransaction.isLoggingEnabled(1))
        {
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("isSearchFiltered = ").append(flag).toString(), 1);
        }
        if(vobuildercontext.getIsSearchFiltered())
        {
            ArrayList arraylist2 = getFilterWhereClauseAndBindKeys(vobuildercontext, 1);
            s = (String)arraylist2.get(0);
            arraylist1 = (ArrayList)arraylist2.get(1);
        }
        arraylist.add(s);
        arraylist.add(arraylist1);



        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "getAdditionalWhereClauseAndBindKeys.end", 2);
        }
        return arraylist;
    }

    protected ArrayList getAdvSearchWhereClauseAndBindKeys(VOBuilderContext vobuildercontext, int i)
    {
        RequisitionAMImpl requisitionamimpl = (RequisitionAMImpl)vobuildercontext.getApplicationModule();
        OADBTransaction oadbtransaction = requisitionamimpl.getOADBTransaction();
        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "getAdvSearchWhereClauseAndBindKeys.begin", 2);
        }
        StringBuffer stringbuffer = new StringBuffer();
        ArrayList arraylist = new ArrayList();
        HashMap hashmap = vobuildercontext.getBindParamValues();
        if(oadbtransaction.isLoggingEnabled(1))
        {
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("paramValuesMap = ").append(hashmap).toString(), 1);
        }
        OAViewObjectImpl oaviewobjectimpl = (OAViewObjectImpl)requisitionamimpl.findViewObject("AdvancedSearchValuesVO");
        if(oaviewobjectimpl != null)
        {
            oaviewobjectimpl.setMaxFetchSize(0);
            Object obj = null;
            Object obj1 = null;
            Object obj2 = null;
            Object obj3 = null;
            Object obj4 = null;
            Object obj5 = null;
            Object obj6 = null;
            Object obj7 = null;
            boolean flag = true;
            Object obj8 = null;
            for(AdvancedSearchValuesVORowImpl advancedsearchvaluesvorowimpl = (AdvancedSearchValuesVORowImpl)oaviewobjectimpl.first(); advancedsearchvaluesvorowimpl != null; advancedsearchvaluesvorowimpl = (AdvancedSearchValuesVORowImpl)oaviewobjectimpl.next())
            {
                String s = advancedsearchvaluesvorowimpl.getStoredInColumn();
                String s5 = advancedsearchvaluesvorowimpl.getDescriptorKey();
                if("UOM".equals(s5))
                {
                    s = "UomCode";
                }
                if(s == null)
                {
                    s = s5;
                }
                String s1 = advancedsearchvaluesvorowimpl.getCondition();
                String s2 = advancedsearchvaluesvorowimpl.getValue1();
                String s3 = advancedsearchvaluesvorowimpl.getValue2();
                Number number = advancedsearchvaluesvorowimpl.getType();
                String s4 = number.toString();
                if(oadbtransaction.isLoggingEnabled(1))
                {
                    oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("attributeName = ").append(s).toString(), 1);
                    oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("condition = ").append(s1).toString(), 1);
                    oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("value1Str = ").append(s2).toString(), 1);
                    oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("value2Str = ").append(s3).toString(), 1);
                    oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("typeNum = ").append(number).toString(), 1);
                    oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("type = ").append(s4).toString(), 1);
                }
                if(s4.equals("1"))
                {
                    OANLSServices oanlsservices = new OANLSServices(oadbtransaction);
                    if(s2 != null)
                    {
                        obj4 = oanlsservices.stringToNumber(s2);
                    }
                    if(s3 != null)
                    {
                        obj5 = oanlsservices.stringToNumber(s3);
                    }
                } else
                {
                    obj4 = s2;
                    obj5 = s3;
                }
                if(requisitionamimpl.isIntermediaCondition(s5))
                {
                    continue;
                }
                if(flag)
                {
                    flag = false;
                } else
                {
                    stringbuffer.append(" AND ");
                }
                stringbuffer.append("(bvoq.");
                stringbuffer.append(s);
                stringbuffer.append(getWhereCondition(s1));
                stringbuffer.append(":");
                stringbuffer.append(i);
                if(s1.equals("BETWEEN"))
                {
                    hashmap.put((new StringBuilder()).append("AdvancedSearchKey").append(i).toString(), obj4);
                    arraylist.add((new StringBuilder()).append("AdvancedSearchKey").append(i).toString());
                    i++;
                    stringbuffer.append(" AND :");
                    stringbuffer.append(i);
                    hashmap.put((new StringBuilder()).append("AdvancedSearchKey").append(i).toString(), obj5);
                    arraylist.add((new StringBuilder()).append("AdvancedSearchKey").append(i).toString());
                } else
                {
                    hashmap.put((new StringBuilder()).append("AdvancedSearchKey").append(i).toString(), obj4);
                    arraylist.add((new StringBuilder()).append("AdvancedSearchKey").append(i).toString());
                }
                i++;
                stringbuffer.append(" )");
            }

            vobuildercontext.setBindParamValues(hashmap);
        }
        if(oadbtransaction.isLoggingEnabled(1))
        {
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("advSearchWhereClause = ").append(stringbuffer).toString(), 1);
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("advSearchBindKeys = ").append(arraylist).toString(), 1);
        }
        ArrayList arraylist1 = new ArrayList(2);
        arraylist1.add(stringbuffer.toString());
        arraylist1.add(arraylist);
        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "getAdvSearchWhereClauseAndBindKeys.end", 2);
        }
        return arraylist1;
    }

    protected ArrayList getFilterWhereClauseAndBindKeys(VOBuilderContext vobuildercontext, int i)
    {
        OAApplicationModuleImpl oaapplicationmoduleimpl = vobuildercontext.getApplicationModule();
        OADBTransaction oadbtransaction = oaapplicationmoduleimpl.getOADBTransaction();
        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "getFilterWhereClauseAndBindKeys.begin", 2);
        }
        StringBuffer stringbuffer = new StringBuffer();
        ArrayList arraylist = new ArrayList();
        HashMap hashmap = vobuildercontext.getBindParamValues();
        OAViewObjectImpl oaviewobjectimpl = (OAViewObjectImpl)oaapplicationmoduleimpl.findViewObject("FilterValuesVO");
        OAViewObjectImpl oaviewobjectimpl1 = (OAViewObjectImpl)oaapplicationmoduleimpl.findViewObject("FilteredAttributesVO");
        if(oaviewobjectimpl != null && oaviewobjectimpl1 != null)
        {
            oaviewobjectimpl.setMaxFetchSize(0);
            oaviewobjectimpl1.setMaxFetchSize(0);
            Object obj = null;
            Object obj1 = null;
            Object obj2 = null;
            FilteredAttributesVORowImpl filteredattributesvorowimpl = (FilteredAttributesVORowImpl)oaviewobjectimpl1.first();
            Object obj3 = null;
            boolean flag = true;
            boolean flag1 = true;
            for(; filteredattributesvorowimpl != null; filteredattributesvorowimpl = (FilteredAttributesVORowImpl)oaviewobjectimpl1.next())
            {
                if(!flag)
                {
                    stringbuffer.append(") AND ");
                } else
                {
                    flag = false;
                }
                String s = filteredattributesvorowimpl.getStoredInColumn();
                if(oadbtransaction.isLoggingEnabled(1))
                {
                    oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("storedInColumn = ").append(s).toString(), 1);
                }
                stringbuffer.append("bvoq.");
                stringbuffer.append(s);
                stringbuffer.append(" IN (");
                FilterValuesVORowImpl filtervaluesvorowimpl = (FilterValuesVORowImpl)oaviewobjectimpl.first();
                boolean flag2 = true;
                for(; filtervaluesvorowimpl != null; filtervaluesvorowimpl = (FilterValuesVORowImpl)oaviewobjectimpl.next())
                {
                    String s1 = filtervaluesvorowimpl.getStoredInColumn();
                    String s2 = filtervaluesvorowimpl.getValue();
                    if(oadbtransaction.isLoggingEnabled(1))
                    {
                        oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("value = ").append(s2).toString(), 1);
                    }
                    if(!s1.equals(s))
                    {
                        continue;
                    }
                    if(flag2)
                    {
                        flag2 = false;
                    } else
                    {
                        stringbuffer.append(",");
                    }
                    stringbuffer.append(":");
                    stringbuffer.append(i);
                    hashmap.put((new StringBuilder()).append("FilterKey").append(i).toString(), s2);
                    arraylist.add((new StringBuilder()).append("FilterKey").append(i).toString());
                    i++;
                }

            }

            if(stringbuffer.length() > 0)
            {
                stringbuffer.append(")");
            }
            vobuildercontext.setBindParamValues(hashmap);
        }
        if(oadbtransaction.isLoggingEnabled(1))
        {
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("filterWhereClause = ").append(stringbuffer).toString(), 1);
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("filterBindKeys = ").append(arraylist).toString(), 1);
        }
        ArrayList arraylist1 = new ArrayList(2);
        arraylist1.add(stringbuffer.toString());
        arraylist1.add(arraylist);
        if(oadbtransaction.isLoggingEnabled(2))
        {
            oadbtransaction.writeDiagnostics(this, "getFilterWhereClauseAndBindKeys.end", 2);
        }
        return arraylist1;
    }

    protected String getWhereCondition(String s)
    {
        StringBuffer stringbuffer = new StringBuffer();
        stringbuffer.append(' ');
        if(s.equals("BETWEEN"))
        {
            stringbuffer.append("BETWEEN");
        } else
        if(s.equals("GREATER_THAN"))
        {
            stringbuffer.append('>');
        } else
        if(s.equals("LESS_THAN"))
        {
            stringbuffer.append('<');
        } else
        if(s.equals("IS"))
        {
            stringbuffer.append('=');
        }
        stringbuffer.append(' ');
        return stringbuffer.toString();
    }

    protected abstract String getCacheName();

    static
    {
        m_excludeDesciptors = new ArrayList();
        m_excludeDesciptors.add("DESCRIPTION");
        m_excludeDesciptors.add("LONG_DESCRIPTION");
        m_excludeDesciptors.add("UNSPSC");
        m_excludeDesciptors.add("MANUFACTURER");
        m_excludeDesciptors.add("MANUFACTURER_PART_NUM");
        m_excludeDesciptors.add("THUMBNAIL_IMAGE");
        m_excludeDesciptors.add("PICTURE");
        m_excludeDesciptors.add("ALIAS");
        m_excludeDesciptors.add("COMMENTS");
        m_excludeDesciptors.add("AVAILABILITY");
        m_excludeDesciptors.add("LEAD_TIME");
        m_excludeDesciptors.add("SUPPLIER_URL");
        m_excludeDesciptors.add("MANUFACTURER_URL");
        m_excludeDesciptors.add("ATTACHMENT_URL");
    }
}
