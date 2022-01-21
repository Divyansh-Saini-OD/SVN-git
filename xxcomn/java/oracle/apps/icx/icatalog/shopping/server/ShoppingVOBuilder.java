/*===========================================================================+
|      Copyright (c) 2001, 2015 Oracle Corporation, Redwood Shores, CA, USA       |
|                         All rights reserved.                              |
+===========================================================================+
|  ShoppingVOBuilder.java                                                   | 
|  19/09/2005     sbora -- Created                                          | 
+===========================================================================*/

// Referenced classes of package oracle.apps.icx.icatalog.shopping.server:
//            AdvancedSearchValuesVORowImpl, FilteredAttributesVORowImpl, FilterValuesVORowImpl

// 19-July-2013		Gaurav Powar	Modified for R12 Upgrade Retrofit for E0990 Restrict Items
// 03-Feb-2013      Darshini.G      Excluded records for source types - 'TEMPLATE' and 'INTERNAL_TEMPLATE' for Defect# 25738
// 12-May-2015  1.2 Madhu Bolli     Retrofit the difference of the versions '120.49.12010000.8' and '120.49.12010000.10' for the punchout patch
// 09-Aug-2016  1.3 Madhu Bolli     Retrofit for 1225(from 1213). Took the seeded code version (120.52.12020000.8) and applied the 2 custom changes.
//                                  Modified the custom code in different logic than the eariler versions.

package oracle.apps.icx.icatalog.shopping.server;

import java.sql.Types;

import java.sql.SQLException;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAViewDefImpl;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.apps.icx.icatalog.common.server.CachedVOBuilder;
import oracle.apps.icx.icatalog.common.server.VOBuilderContext;
import oracle.apps.icx.icatalog.loader.elements.CategoryElement;
import oracle.apps.icx.icatalog.loader.elements.DescriptorElement;
import oracle.apps.icx.icatalog.shopping.ShoppingConstants;
import oracle.apps.icx.icatalog.shopping.server.AdvancedSearchValuesVORowImpl;
import oracle.apps.icx.icatalog.shopping.server.FilterValuesVORowImpl;
import oracle.apps.icx.icatalog.shopping.server.FilteredAttributesVORowImpl;
import oracle.apps.icx.por.req.server.RequisitionAMImpl;
import oracle.apps.jtf.base.resources.FrameworkException;
import oracle.apps.fnd.framework.OANLSServices;

import oracle.jbo.AttributeDef;
import oracle.jbo.domain.Number;
/**
 * The ShoppingVOBuilder is the common super class of VO Builders in shopping
 * Currently they are BaseSearchVOBuilder,FavoriteListVOBuilder,PublicListVOBuilder,
 * ItemCatAttributeVOBuilder,ItemAttributeVOBuilder and CategoryItemCountVOBuilder
 * 
 * This implements functionality common to metioned VOBuilders.
 *
 * @author  Surinder Singh Bora
 * @since   Release 12.0
 */

abstract public class ShoppingVOBuilder extends CachedVOBuilder
{
  public static final String RCS_ID =
    "$Header: ShoppingVOBuilder.java 120.52.12020000.8 2015/06/12 10:38:56 mzhussai(cust) ship $";
  public static final boolean RCS_ID_RECORDED = 
    VersionInfo.recordClassVersion(RCS_ID, "oracle.apps.icx.icatalog.shopping.server");
    
  protected static final String LOCAL_FROM_CLAUSE_COMMON =    
    "po_system_parameters_all psp, " +    
    "mtl_units_of_measure_tl muomtl, " +
    "icx_cat_attribute_values av," +
    "icx_cat_attribute_values_tlp avtlp, " +
    "po_vendor_sites_all pvs, " + 
    "mtl_categories_kfv mck, " +
    "mtl_system_items_kfv msikfv ";
    // 17076597 changes added un number and hazard class
  protected static final String BASIC_SELECT_CLAUSE_COMMON =    
    "ctxh.inventory_item_id, " +
    "ctxh.po_line_id, " +
    "ctxh.req_template_name, " +
    "ctxh.req_template_line_num, " +
    "ctxh.org_id, " +
    "ctxh.language, " +
    "ctxh.source_type, " +
    "ctxh.purchasing_org_id, " +
    "ctxh.ip_category_id, " +
    "ctxh.ip_category_name, " +
    "ctxh.po_category_id, " +
    "ctxh.owning_org_id, " +   
    "ctxh.supplier_id, " +
    "ctxh.supplier_part_num, " +
    "ctxh.supplier_part_auxid, " +  
    "ctxh.supplier_site_id, " +   
    "ctxh.item_type, " +
    "ctxh.item_revision, " +
    "ctxh.po_header_id, " +
    "ctxh.document_number, " +
    "ctxh.line_num, " +
    "ctxh.allow_price_override_flag, " +
    "ctxh.not_to_exceed_price, " +
    "ctxh.line_type_id, " +
    "ctxh.unit_meas_lookup_code, " +
    "ctxh.unit_price, " +
    "ctxh.amount, " +
    "nvl(ctxh.currency_code, :FUNC_CURRENCY_KEY11) currency_code, " +   
    "ctxh.rate_type, " +
    "ctxh.rate_date, " +
    "ctxh.rate, " +
    "ctxh.buyer_id, " +
    "ctxh.supplier_contact_id, " +
    "ctxh.rfq_required_flag, " +
    "ctxh.negotiated_by_preparer_flag, " +
    "ctxh.description, " +    
    "ctxh.supplier, " +    
    "ctxh.req_template_po_line_id, " +
    "ctxh.order_type_lookup_code, " +
    "ctxh.merged_source_type, " +
    "ctxh.global_agreement_flag, " +
    "ctxh.suggested_quantity, " +
    "ctxh.s relevance_score, " +
    "1 as is_item_available,  " +
    "to_number(null) favorite_list_id, " +
    "to_number(null) favorite_list_line_id, "+
    "ctxh.un_number as un_number, " +
    "ctxh.hazard_class as hazard_class ";
  
  protected static final String BASIC_FROM_CLAUSE_COMMON = 
    "(select score(1) s, c.* from icx_cat_items_ctx_hdrs_tlp c " +
    "where contains(c.ctx_desc, :INTERMEDIA_KEY1, 1) > 0) ctxh ";
    
  protected static final String BASIC_WHERE_CLAUSE_COMMON = 
    "ICX_CAT_UTIL_PVT.is_item_valid_for_search( " +
    "ctxh.source_type, ctxh.po_line_id, " + 
    "ctxh.req_template_name, ctxh.req_template_line_num, " +
    "ctxh.po_category_id, ctxh.org_id) = 1 " +
	"AND ctxh.source_type NOT IN ('TEMPLATE','INTERNAL_TEMPLATE')"; // Custom logic 1.3

  protected static final String BASIC_QUERY =
    "(SELECT " + BASIC_SELECT_CLAUSE_COMMON +
    "FROM " + BASIC_FROM_CLAUSE_COMMON +
    "WHERE " + BASIC_WHERE_CLAUSE_COMMON +
    ") bq ";
  
  protected static final String BASIC_QUERY_WITH_PRECEDENCE =
    "(SELECT " + BASIC_SELECT_CLAUSE_COMMON + ", " +
    "count(*) over (partition by ctxh.inventory_item_id, ctxh.org_id, ctxh.language) as source_count " + 
    "FROM " + BASIC_FROM_CLAUSE_COMMON +
    "WHERE " + BASIC_WHERE_CLAUSE_COMMON +
    ") bq ";
  
  // Custom logic 1.3 -- Only for Local Clauses to add extra below criteria, we replace all ") bq" with additional criteria
  protected static final String CUSTOM_LOCAL_WHERE_CLAUSE_CMN = " AND EXISTS (select 1 from XX_PO_RESP_CATSETS_V WHERE inventory_item_id = ctxh.inventory_item_id)";
  protected static final String LOCAL_FROM_CLAUSE =
    //BASIC_QUERY + ", " +
	BASIC_QUERY.replace(") bq", CUSTOM_LOCAL_WHERE_CLAUSE_CMN+") bq") + ", " +  // Custom logic 1.3
    LOCAL_FROM_CLAUSE_COMMON;
          
  protected static final String LOCAL_FROM_CLAUSE_WITH_PRECEDENCE = 
    // BASIC_QUERY_WITH_PRECEDENCE + ", " +
	BASIC_QUERY_WITH_PRECEDENCE.replace(") bq", CUSTOM_LOCAL_WHERE_CLAUSE_CMN+") bq") + ", " +	 // Custom logic 1.3
    LOCAL_FROM_CLAUSE_COMMON;   
    
  protected static final String BASIC_QUERY_SIC_PO =
    "(SELECT " + BASIC_SELECT_CLAUSE_COMMON + ", " +
    "row_number() over (partition by ctxh.inventory_item_id, ctxh.po_line_id, " +
    "ctxh.req_template_name, ctxh.req_template_line_num, ctxh.purchasing_org_id, " +
    "ctxh.language ORDER BY ctxh.inventory_item_id) as rownum1 " +
    "FROM " + BASIC_FROM_CLAUSE_COMMON +
    "WHERE " + BASIC_WHERE_CLAUSE_COMMON +
    ") bq ";            
  
  protected static final String BASIC_QUERY_WITH_PRECEDENCE_SIC_PO =
    "(SELECT " + BASIC_SELECT_CLAUSE_COMMON + ", " +
    "count(*) over (partition by ctxh.inventory_item_id, ctxh.purchasing_org_id, ctxh.language) as source_count, " +
    "row_number() over (partition by ctxh.inventory_item_id, ctxh.po_line_id, " +
    "ctxh.req_template_name, ctxh.req_template_line_num, ctxh.purchasing_org_id, " +
    "ctxh.language ORDER BY ctxh.inventory_item_id) as rownum1 " +
    "FROM " + BASIC_FROM_CLAUSE_COMMON +
    "WHERE " + BASIC_WHERE_CLAUSE_COMMON +
    ") bq ";  
  
  protected static final String LOCAL_FROM_CLAUSE_SIC_PO =
    //BASIC_QUERY_SIC_PO + ", " +
	BASIC_QUERY_SIC_PO.replace(") bq", CUSTOM_LOCAL_WHERE_CLAUSE_CMN+") bq") + ", " +	 // Custom logic 1.3
    LOCAL_FROM_CLAUSE_COMMON;
          
  protected static final String LOCAL_FROM_CLAUSE_WITH_PRECEDENCE_SIC_PO = 
    //BASIC_QUERY_WITH_PRECEDENCE_SIC_PO + ", " +
	BASIC_QUERY_WITH_PRECEDENCE_SIC_PO.replace(") bq", CUSTOM_LOCAL_WHERE_CLAUSE_CMN+") bq") + ", " +	 // Custom logic 1.3
    LOCAL_FROM_CLAUSE_COMMON;
        
  protected static final String LOCAL_WHERE_CLAUSE_COMMON =
    "psp.org_id = :ORG_ID_KEY2 AND " +
    "bq.unit_meas_lookup_code = muomtl.unit_of_measure(+) AND " +
    "bq.language = muomtl.language(+) AND " + 
    "bq.inventory_item_id = av.inventory_item_id(+) AND " +
    "bq.owning_org_id = av.org_id(+) AND " + 
    "bq.po_line_id = av.po_line_id(+) AND " +
    "bq.req_template_name = av.req_template_name(+) AND " +
    "bq.req_template_line_num = av.req_template_line_num(+) AND " +
    "bq.inventory_item_id = avtlp.inventory_item_id(+) AND " +
    "bq.owning_org_id = avtlp.org_id(+) AND " + 
    "bq.po_line_id = avtlp.po_line_id(+) AND " +
    "bq.req_template_name = avtlp.req_template_name(+) AND " +
    "bq.req_template_line_num = avtlp.req_template_line_num(+) AND " + 
    "bq.language = avtlp.language(+) AND " +
    "bq.supplier_site_id = pvs.vendor_site_id(+) AND " +
    // we need to do outer join to mck because if we expire a blanket line, 
    // the row will be deleted from our hdrs table and for favorite list,
    // bq.po_category_id will be null since we outer join to our hdrs table
    // in favorite list    
    "bq.po_category_id = mck.category_id(+) AND " +
    "bq.inventory_item_id = msikfv.inventory_item_id(+) AND " +
    "msikfv.organization_id(+) = :INV_ORG_ID_KEY1 ";
    
  protected static final String LOCAL_WHERE_CLAUSE =   
    LOCAL_WHERE_CLAUSE_COMMON;    
    
  protected static final String LOCAL_WHERE_CLAUSE_WITH_PRECEDENCE =
    "(bq.source_count = 1 OR bq.source_type <> 'MASTER_ITEM') AND " +
    LOCAL_WHERE_CLAUSE_COMMON;
    
  protected static final String LOCAL_WHERE_CLAUSE_SIC_PO =   
    "bq.rownum1 = 1 AND " +
    LOCAL_WHERE_CLAUSE_COMMON;    
    
  protected static final String LOCAL_WHERE_CLAUSE_WITH_PRECEDENCE_SIC_PO =
    "(bq.source_count = 1 OR bq.source_type <> 'MASTER_ITEM') AND " +
    "bq.rownum1 = 1 AND " +
    LOCAL_WHERE_CLAUSE_COMMON;
    
    
  /**
   * Fixed select clause will be handle in a different manner.Instead of 
   * having a constant defined for fixed select clause we will be defining 
   * static two dimensional string which will be used in both building fixed 
   * select clause string as well as adding a view attribute to the view 
   * definition. 
   *	Each entry in object array will specify the following
   * {   Column expression (Local for simple search and favorite list), 
   *     Column expression (Non catalog for favorite list), 
   *     Column expression (Remote for favorite list), 
   *     Alias (String),
   *     AttrType (String),
   *     SqlType (Integer),   
   *     NotNull (Boolean),  
   *     Queriable (Boolean),
   *     Updateable (Integer),
   *     Precision (Integer)
   * }
   */   
  protected static final Object[][] SELECT_CLAUSE_ARRAY =
  {
    {
      "bq.relevance_score",
      "-1",
      "-1",
      "Relevance",
      "oracle.jbo.domain.Number", new Integer(Types.NUMERIC),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },

    //14681433 changes starts
    {
      "bq.inventory_item_id",
      "-1",
      "-1", 
      "INVENTORY_ITEM_ID",
      "oracle.jbo.domain.Number", new Integer(Types.NUMERIC),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
     },
     
     {
       "msikfv.organization_id",
       "-1",
       "-1", 
       "ORGANIZATION_ID",
       "oracle.jbo.domain.Number", new Integer(Types.NUMERIC),
       new Boolean(false), new Boolean(true),
       new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    //14681433 changes ends
    // 17076597 changes starts
    {
      "bq.un_number",
       "'-1'",
       "'-1'",
       "UN_NUMBER",
       "java.lang.String", new Integer(Types.VARCHAR),
       new Boolean(false), new Boolean(true),
       new Byte(AttributeDef.READONLY), new Integer(255)
    },

    {
      "bq.hazard_class",
      "'-1'",
      "'-1'",
      "HAZARD_CLASS",
      "java.lang.String", new Integer(Types.VARCHAR),    
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(255)
    },
    // 17076597 changes ends

    {
      "'l#' || bq.inventory_item_id || '#' || bq.po_line_id ||" +
      "'#' || bq.req_template_name || '#' ||" +
      "bq.req_template_line_num || '#' || :ORG_ID_KEY1",
      "'n#' || favl.rowid",
      "'r#' || favl.rowid", 
      "ItemKey",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(255)
    },
    {
      "bq.source_type", 
      "'NONCATALOG'",
      "'EXTERNAL'", 
      "SourceType",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(20)
    },
    {
      "DECODE(bq.source_type," +
      "'TEMPLATE',decode(least(length(bq.req_template_name) , 20)," +
      "20,substr(bq.req_template_name,1,17) ||'...',bq.req_template_name)," +
      "'INTERNAL_TEMPLATE',decode(least(length(bq.req_template_name) , 20),20," +
      "substr(bq.req_template_name,1,17) ||'...',bq.req_template_name)," +
      "'QUOTATION',ICX_CAT_UTIL_PVT.get_message('ICX_CAT_QUOTATION_SOURCE'," +
      "'NUMBER',bq.document_number) ," +
      "'BLANKET',ICX_CAT_UTIL_PVT.get_message('ICX_CAT_BLANKET_SOURCE','NUMBER'," +
      "bq.document_number),'GLOBAL_BLANKET',ICX_CAT_UTIL_PVT.get_message('ICX_CAT_BLANKET_SOURCE','NUMBER'," +      
      "bq.document_number), null)",      
      "decode(ph.segment1, null, null, " + 
      "ICX_CAT_UTIL_PVT.get_message('ICX_CAT_BLANKET_SOURCE', 'NUMBER', ph.segment1))",      
      "decode(ph.segment1, null, null, ICX_CAT_UTIL_PVT.get_message('ICX_CAT_BLANKET_SOURCE', 'NUMBER', ph.segment1))",            
      "SOURCE",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(20)
    },
    {
      "bq.inventory_item_id",
      "to_number(null)",
      "to_number(null)",
      "ItemId",
      "oracle.jbo.domain.Number", new Integer(Types.NUMERIC),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {                
      "nvl(avtlp.description, bq.description)",
      "favl.item_description",
      "favl.item_description", 
      "DESCRIPTION",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(240)
    },
    {
      "DECODE(LEAST(LENGTH(decode(1,1, nvl(avtlp.description, bq.description)))," +
      "25), 25, SUBSTR(decode(1,1, nvl(avtlp.description, bq.description))," +
      "1, 22)||'...', decode(1,1, nvl(avtlp.description, bq.description)))",      
      "DECODE(LEAST(LENGTH(favl.item_description), 25)," +
      "25, SUBSTR(favl.item_description," +
      "1,  22)||'...',favl.item_description)",       
      "DECODE(LEAST(LENGTH(favl.item_description), 25)," +
      "25, SUBSTR(favl.item_description," +
      "1,  22)||'...',favl.item_description)",       
      "TruncatedDescription",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(25)
    },
    {     
      "avtlp.long_description",
      "to_char(null)", // for non catalog, long description is always null
      "favl.long_description", 
      "LONG_DESCRIPTION",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(2000)
    },
    {
      "DECODE(LEAST(LENGTH(avtlp.long_description), 180), " +
      "180, SUBSTR(avtlp.long_description, 1, 177)||'...', " +
      "avtlp.long_description)",       
      "to_char(null)", // for non catalog, long description is always null      
      "DECODE(LEAST(LENGTH(favl.long_description), 180), " +
      "180, SUBSTR(favl.long_description, 1, 177)||'...', " +
      "favl.long_description)",                   
      "TruncatedLongDescription",  
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(180)
    },
    {
      "msikfv.concatenated_segments",
      "to_char(null)",
      "to_char(null)",  
      "INTERNAL_ITEM_NUM",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(40)
    },
    {
      "decode(bq.item_revision, '-2', to_char(null), bq.item_revision)",      
      "to_char(null)",
      "to_char(null)",
      "ITEM_REVISION",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(3)
    },
    {
      "bq.po_header_id",
      "favl.po_header_id",
      "favl.po_header_id",
      "PoHeaderId",
      "oracle.jbo.domain.Number", new Integer(Types.NUMERIC),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {
      "decode(bq.merged_source_type, 'REQ_TEMPLATE',NVL(bq.req_template_po_line_id,-2), bq.po_line_id)",
      "to_number(null)",
      "to_number(null)",
      "PoLineId",
      "oracle.jbo.domain.Number", new Integer(Types.NUMERIC),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {
      "bq.document_number",
      "ph.segment1",
      "ph.segment1",
      "DocumentNumber",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(20)
    },
    {
      "bq.line_num",
      "to_number(null)",
      "to_number(null)",  
      "DocumentLineNumber",
      "oracle.jbo.domain.Number", new Integer(Types.NUMERIC),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {
      "bq.req_template_name",
      "to_char(null)",
      "to_char(null)",
      "ReqTemplateName",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(25)
    },
    {
      "bq.req_template_line_num",
      "to_number(null)",
      "to_number(null)",
      "ReqTemplateLineNum",
      "oracle.jbo.domain.Number", new Integer(Types.NUMERIC),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {      
      "decode(bq.order_type_lookup_code, 'AMOUNT', 1, decode(bq.allow_price_override_flag, 'Y', 1, 0))",
      "decode(plt.order_type_lookup_code, 'AMOUNT', 1, 0)",
      "decode(plt.order_type_lookup_code, 'AMOUNT', 1, 0)",
      "AllowPriceOverrideFlag", 
      "java.lang.Boolean", new Integer(Types.BIT),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {
      "bq.not_to_exceed_price",
      "to_number(null)",
      "to_number(null)",
      "AmountLimit",
      "oracle.jbo.domain.Number", new Integer(Types.NUMERIC),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {
      "decode(bq.order_type_lookup_code, 'FIXED PRICE', 1, 0)",
      "decode(plt.order_type_lookup_code, 'FIXED PRICE', 1, 0)",
      "decode(plt.order_type_lookup_code, 'FIXED PRICE', 1, 0)",
      "IsFixedPrice",
      "java.lang.Boolean", new Integer(Types.BIT),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {
      "decode(bq.order_type_lookup_code, 'QUANTITY', 0, 1)",
      "decode(plt.order_type_lookup_code, 'QUANTITY', 0, 1)",
      "decode(plt.order_type_lookup_code, 'QUANTITY', 0, 1)",
      "IsFixedPriceOrAmountBased",
      "java.lang.Boolean", new Integer(Types.BIT),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {      
      "decode(bq.order_type_lookup_code, 'AMOUNT', 0, decode(bq.allow_price_override_flag, 'Y', 0, 1))",        
      "decode(plt.order_type_lookup_code, 'AMOUNT', 0, 1)", 
      "decode(plt.order_type_lookup_code, 'AMOUNT', 0, 1)",
      "IsAmountReadOnly",
      "java.lang.Boolean", new Integer(Types.BIT),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {      
      "decode(bq.order_type_lookup_code, 'QUANTITY', 1, 0)",
      "decode(plt.order_type_lookup_code, 'QUANTITY', 1, 0)",
      "decode(plt.order_type_lookup_code, 'QUANTITY', 1, 0)",
      "IsQuantityBased",
      "java.lang.Boolean", new Integer(Types.BIT),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {     
      "nvl(bq.line_type_id, :GOODS_LINE_TYPE_KEY1)",
      "favl.line_type_id",
      "favl.line_type_id",
      "LineTypeId",
      "oracle.jbo.domain.Number", new Integer(Types.NUMERIC),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {
      "bq.po_category_id",
      "favl.po_category_id",
      "favl.po_category_id",
      "PurchasingCategoryId",
      "oracle.jbo.domain.Number", new Integer(Types.NUMERIC),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {
      "bq.ip_category_id",
      "to_number(null)",
      "to_number(null)",
      "ShoppingCategoryId",
      "oracle.jbo.domain.Number", new Integer(Types.NUMERIC),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {
      "mck.concatenated_segments",
      "mck.concatenated_segments",
      "mck.concatenated_segments",
      "PURCHASING_CATEGORY",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(250)
    },
    {         
      "bq.ip_category_name",     
      "to_char(null)",
      "to_char(null)",
      "SHOPPING_CATEGORY",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(250)
    },
    {      
      "muomtl.uom_code",
      "muomtl.uom_code",      
      "muomtl.uom_code",
      "UomCode",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(25)
    },
    {     
      "muomtl.unit_of_measure",
      "muomtl.unit_of_measure",
      "muomtl.unit_of_measure",
      "UomForCart",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(25)
    },
    {      
      "muomtl.unit_of_measure_tl",
      "muomtl.unit_of_measure_tl",
      "muomtl.unit_of_measure_tl", 
      "UOM",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(25)
    },
    {      
      "nvl(bq.suggested_quantity, 1)",
      "1",
      "1", 
      "Quantity",
      "oracle.jbo.domain.Number", new Integer(Types.NUMERIC),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.UPDATEABLE), new Integer(-1)
    },
    {      
      // bq.unit_price will be null for AMOUNT or FIXED PRICE
      "decode(bq.merged_source_type, 'MASTER_ITEM', decode(:ALLOWED_ITEM_TYPE_KEY1, " +
      "'INTERNAL', to_number(null), bq.unit_price), bq.unit_price)",       
      "favl.unit_price",      
      "favl.unit_price",
      "PRICE",
      "oracle.jbo.domain.Number", new Integer(Types.NUMERIC),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {
      // for amount based and fixed price, it's null, otherwise do the conversion          
      "decode(bq.order_type_lookup_code, 'AMOUNT', to_number(null), " +
      "'FIXED PRICE', to_number(null), decode(bq.currency_code, :FUNC_CURRENCY_KEY1, " +
      "decode(bq.merged_source_type, 'MASTER_ITEM', decode(:ALLOWED_ITEM_TYPE_KEY2, 'INTERNAL', to_number(null), bq.unit_price), bq.unit_price), " +
      "icx_cat_util_pvt.convert_amount(bq.currency_code, :FUNC_CURRENCY_KEY2, " +
      "decode(bq.currency_code, :FUNC_CURRENCY_KEY3, to_date(null), decode(bq.global_agreement_flag, 'Y', trunc(sysdate), bq.rate_date)), " +
      "decode(bq.currency_code, :FUNC_CURRENCY_KEY4, to_char(null), decode(bq.global_agreement_flag, 'Y', psp.default_rate_type, bq.rate_type)), " +
      "decode(bq.currency_code, :FUNC_CURRENCY_KEY5, to_number(null), decode(bq.global_agreement_flag, 'Y', to_number(null), bq.rate)), " +
      "decode(bq.merged_source_type, 'MASTER_ITEM', decode(:ALLOWED_ITEM_TYPE_KEY3, 'INTERNAL', to_number(null), bq.unit_price), bq.unit_price))))", 
      
      "decode(plt.order_type_lookup_code, 'AMOUNT', to_number(null), " +
      "'FIXED PRICE', to_number(null), decode(favl.currency, :FUNC_CURRENCY_KEY21, favl.unit_price, " +
      "icx_cat_util_pvt.convert_amount(favl.currency, :FUNC_CURRENCY_KEY22, " +
      "favl.rate_date, favl.rate_type, favl.rate, favl.unit_price)))",
      
      "decode(plt.order_type_lookup_code, 'AMOUNT', to_number(null), " +
      "'FIXED PRICE', to_number(null), decode(favl.currency, :FUNC_CURRENCY_KEY28, favl.unit_price, " +
      "icx_cat_util_pvt.convert_amount(favl.currency, :FUNC_CURRENCY_KEY29, " +
      "decode(favl.currency, :FUNC_CURRENCY_KEY30, to_date(null), decode(ph.po_header_id, null, trunc(sysdate), decode(ph.global_agreement_flag, 'Y', trunc(sysdate), ph.rate_date))), " +
      "decode(favl.currency, :FUNC_CURRENCY_KEY31, to_char(null), decode(ph.po_header_id, null, :RATE_TYPE_KEY1, decode(ph.global_agreement_flag, 'Y', psp.default_rate_type, ph.rate_type))), " +      
      "decode(ph.po_header_id, null, null, decode(ph.global_agreement_flag, 'Y', null, ph.rate)), favl.unit_price)))", 
      "FUNCTIONAL_PRICE",
      "oracle.jbo.domain.Number", new Integer(Types.NUMERIC),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {      
      //"decode(bq.source_type, 'NONCATALOG', bq.amount, decode(nvl(plt.order_type_lookup_code, 'QUANTITY'), 'AMOUNT', 1, bq.amount))", 
      // for bug 13969093, fix when amount based lint type display suggested_quantity * unit_price
      "decode(bq.order_type_lookup_code, 'AMOUNT', nvl(bq.suggested_quantity * bq.unit_price, 1), bq.amount)",
      "favl.amount",
      "favl.amount",  
      "Amount",
      "oracle.jbo.domain.Number", new Integer(Types.NUMERIC),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.UPDATEABLE), new Integer(-1)
    },
    {      
      // if fixed price, convert, else null since we show it only for fixed price               
      "decode(bq.order_type_lookup_code, 'FIXED PRICE', " +
      "decode(bq.currency_code, :FUNC_CURRENCY_KEY6, decode(bq.order_type_lookup_code, 'AMOUNT', 1, bq.amount), " +
      "icx_cat_util_pvt.convert_amount(bq.currency_code, :FUNC_CURRENCY_KEY7, " +
      "decode(bq.currency_code, :FUNC_CURRENCY_KEY8, to_date(null), decode(bq.global_agreement_flag, 'Y', trunc(sysdate), bq.rate_date)), " +
      "decode(bq.currency_code, :FUNC_CURRENCY_KEY9, to_char(null), decode(bq.global_agreement_flag, 'Y', psp.default_rate_type, bq.rate_type)), " +
      "decode(bq.currency_code, :FUNC_CURRENCY_KEY10, to_number(null), decode(bq.global_agreement_flag, 'Y', to_number(null), bq.rate)), " +
      "decode(bq.order_type_lookup_code, 'AMOUNT', 1, bq.amount))), to_number(null))",        
      
      "decode(plt.order_type_lookup_code, 'FIXED PRICE', " +
      "decode(favl.currency, :FUNC_CURRENCY_KEY23, favl.amount, icx_cat_util_pvt.convert_amount(" +
      "favl.currency, :FUNC_CURRENCY_KEY24, favl.rate_date, favl.rate_type, favl.rate, favl.amount)), to_number(null))", 
      
      "decode(plt.order_type_lookup_code, 'FIXED PRICE', " +
      "decode(favl.currency, :FUNC_CURRENCY_KEY32, favl.amount, " +
      "icx_cat_util_pvt.convert_amount(favl.currency, :FUNC_CURRENCY_KEY33, " +
      "decode(favl.currency, :FUNC_CURRENCY_KEY34, to_date(null), decode(ph.po_header_id, null, trunc(sysdate), decode(ph.global_agreement_flag, 'Y', trunc(sysdate), ph.rate_date))), " +
      "decode(favl.currency, :FUNC_CURRENCY_KEY35, to_char(null), decode(ph.po_header_id, null, :RATE_TYPE_KEY2, decode(ph.global_agreement_flag, 'Y', psp.default_rate_type, ph.rate_type))), " +
      "decode(ph.po_header_id, null, null, decode(ph.global_agreement_flag, 'Y', null, ph.rate)), favl.amount)), to_number(null))",
       
      "FunctionalAmount",
      "oracle.jbo.domain.Number", new Integer(Types.NUMERIC),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {      
      "bq.currency_code",
      "favl.currency",
      "favl.currency",
      "CURRENCY",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(15)
    },
    {
      ":FUNC_CURRENCY_KEY12", 
      ":FUNC_CURRENCY_KEY25",
      ":FUNC_CURRENCY_KEY36", 
      "FUNCTIONAL_CURRENCY",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(15)
    },
    {      
      "decode(bq.currency_code, :FUNC_CURRENCY_KEY13, to_char(null), " +
      "decode(bq.global_agreement_flag, 'Y', psp.default_rate_type, bq.rate_type))",
      "favl.rate_type",      
       // there is no rate type specified for punchout one-time item (item not from blanket),
       // so we have to use the default rate type
      "decode(favl.currency, :FUNC_CURRENCY_KEY37, to_char(null), " +      
      "decode(ph.po_header_id, null, :RATE_TYPE_KEY3, " +
      "decode(ph.global_agreement_flag, 'Y', psp.default_rate_type, ph.rate_type)))",      
      "RateType",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(30)
    },
    {      
      "decode(bq.currency_code, :FUNC_CURRENCY_KEY14, to_date(null), " +
      "decode(bq.global_agreement_flag, 'Y', trunc(sysdate), bq.rate_date))",
      "favl.rate_date",
      "decode(favl.currency, :FUNC_CURRENCY_KEY38, to_date(null), " +
      "decode(ph.po_header_id, null, trunc(sysdate), " +
      "decode(ph.global_agreement_flag, 'Y', trunc(sysdate), ph.rate_date)))",
      "RateDate",
      "oracle.jbo.domain.Date", new Integer(Types.DATE),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(10)
    },
    {      
      "decode(decode(bq.currency_code, :FUNC_CURRENCY_KEY15, to_char(null), decode(bq.global_agreement_flag, 'Y', psp.default_rate_type, bq.rate_type)), 'User', " +
      "decode(bq.currency_code, :FUNC_CURRENCY_KEY16, to_number(null), decode(bq.global_agreement_flag, 'Y', to_number(null), bq.rate)), " +
      "decode(bq.currency_code, :FUNC_CURRENCY_KEY17, to_number(null), " +
      "ICX_CAT_UTIL_PVT.get_rate(bq.currency_code, :FUNC_CURRENCY_KEY18, " + 
      "decode(bq.currency_code, :FUNC_CURRENCY_KEY19, to_date(null),decode(bq.global_agreement_flag, 'Y', trunc(sysdate), bq.rate_date)), decode(bq.currency_code, :FUNC_CURRENCY_KEY20, to_char(null), decode(bq.global_agreement_flag, 'Y', psp.default_rate_type, bq.rate_type)))))",         
       
      "decode(favl.rate_type, 'User', favl.rate, " +
      "decode(favl.currency, :FUNC_CURRENCY_KEY26, to_number(null), " +
      "ICX_CAT_UTIL_PVT.get_rate(favl.currency, :FUNC_CURRENCY_KEY27, " + 
      "favl.rate_date, favl.rate_type)))",
       
      "decode(decode(favl.currency, :FUNC_CURRENCY_KEY39, to_char(null), decode(ph.po_header_id, null, :RATE_TYPE_KEY4, decode(ph.global_agreement_flag, 'Y', psp.default_rate_type, ph.rate_type))), " +
      "'User', decode(ph.po_header_id, null, to_number(null), decode(ph.global_agreement_flag, 'Y', to_number(null), ph.rate)), " +
      "decode(favl.currency, :FUNC_CURRENCY_KEY40, to_number(null), " +
      "ICX_CAT_UTIL_PVT.get_rate(favl.currency, :FUNC_CURRENCY_KEY41, " + 
      "decode(favl.currency, :FUNC_CURRENCY_KEY42, to_date(null), decode(ph.po_header_id, null, trunc(sysdate), decode(ph.global_agreement_flag, 'Y', trunc(sysdate), ph.rate_date))), " +
      "decode(favl.currency, :FUNC_CURRENCY_KEY43, to_char(null), decode(ph.po_header_id, null, :RATE_TYPE_KEY5, decode(ph.global_agreement_flag, 'Y', psp.default_rate_type, ph.rate_type))))))",
      "Rate",
      "oracle.jbo.domain.Number", new Integer(Types.NUMERIC),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {
      "decode(bq.supplier_id, -2, to_number(null), bq.supplier_id)",
      "favl.suggested_vendor_id",
      "favl.suggested_vendor_id",
      "SupplierId",
      "oracle.jbo.domain.Number", new Integer(Types.NUMERIC),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {
      "bq.supplier_site_id",
      "favl.suggested_vendor_site_id",
      "favl.suggested_vendor_site_id",
      "SupplierSiteId",
      "oracle.jbo.domain.Number", new Integer(Types.NUMERIC),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {
      "bq.supplier_contact_id",
      "favl.suggested_vendor_contact_id",
      "favl.suggested_vendor_contact_id",
      "SupplierContactId",
      "oracle.jbo.domain.Number", new Integer(Types.NUMERIC),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {
      "'N'",
      "favl.new_supplier",
      "favl.new_supplier",
      "NewSupplierFlag",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(1)
    },
    {     
      "bq.supplier",
      "decode(favl.new_supplier, 'Y', favl.suggested_vendor_name, pv.vendor_name)",
      "decode(favl.new_supplier, 'Y', favl.suggested_vendor_name, pv.vendor_name)",
      "SUPPLIER",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(240)
    },
    {      
      "pvs.vendor_site_code",
      "decode(favl.new_supplier, 'Y', favl.suggested_vendor_site, pvs.vendor_site_code)",
      "decode(favl.new_supplier, 'Y', favl.suggested_vendor_site, pvs.vendor_site_code)",
      "SUPPLIER_SITE",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(700)
    },
    {      
      "to_char(null)",
      "favl.suggested_vendor_contact",
      "favl.suggested_vendor_contact",
      "SupplierContactName",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(80)
    },
    {      
      "to_char(null)",
      "favl.suggested_vendor_contact_phone",
      "favl.suggested_vendor_contact_phone",
      "SupplierContactPhone",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(25)
    },
    {      
      "to_char(null)",
      "favl.suggested_vendor_contact_fax",
      "favl.suggested_vendor_contact_fax",
      "SupplierContactFax",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(25)
    },
    {      
      "to_char(null)",
      "favl.suggested_vendor_contact_email",
      "favl.suggested_vendor_contact_email",
      "SupplierContactEmail",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(2000)
    },
    {
      "decode(bq.supplier_part_num, '##NULL##', to_char(null), bq.supplier_part_num)",    
      "favl.supplier_item_num",
      "favl.supplier_item_num",
      "SUPPLIER_PART_NUM",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(25)
    },
    {
      "decode(bq.supplier_part_auxid, '##NULL##', to_char(null), bq.supplier_part_auxid)",      
      "to_char(null)",
      "to_char(null)", 
      "SUPPLIER_PART_AUXID",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(150)
    },
    {     
      "avtlp.manufacturer",
      "favl.manufacturer_name",
      "favl.manufacturer_name",
      "MANUFACTURER",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(240)
    },
    {     
      "av.manufacturer_part_num",
      "favl.manufacturer_part_number",
      "favl.manufacturer_part_number",
      "MANUFACTURER_PART_NUM",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(30)
    },
    {
      "bq.buyer_id",
      "favl.suggested_buyer_id",
      "favl.suggested_buyer_id",
      "BuyerId",
      "oracle.jbo.domain.Number", new Integer(Types.NUMERIC),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {
      "bq.rfq_required_flag",
      "favl.rfq_required_flag",
      "'N'",
      "RfqRequiredFlag",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(1)
    },
    {
      "bq.negotiated_by_preparer_flag",
      "favl.negotiated_by_preparer_flag",
      "favl.negotiated_by_preparer_flag",
      "NegotiatedByPreparerFlag",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(1)
    },
    {
      "to_number(null)",
      "favl.noncat_template_id",
      "to_number(null)",
      "NonCatTemplateId",
      "oracle.jbo.domain.Number", new Integer(Types.NUMERIC),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {
      "to_char(null)",
      "favl.attribute1",
      "favl.attribute1",
      "Attribute1",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(150)
    },
    {
      "to_char(null)",
      "favl.attribute2",
      "favl.attribute2",
      "Attribute2",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(150)
    },
    {
      "to_char(null)",
      "favl.attribute3",
      "favl.attribute3",
      "Attribute3",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(150)
    },
    {
      "to_char(null)",
      "favl.attribute4",
      "favl.attribute4",
      "attribute4",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(150)
    },
    {
      "to_char(null)",
      "favl.attribute5",
      "favl.attribute5",
      "Attribute5",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(150)
    },
    {
      "to_char(null)",
      "favl.attribute6",
      "favl.attribute6",
      "attribute6",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(150)
    },
    {
      "to_char(null)",
      "favl.attribute7",
      "favl.attribute7",
      "Attribute7",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(150)
    },
    {
      "to_char(null)",
      "favl.attribute8",
      "favl.attribute8",
      "Attribute8",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(150)
    },
    {
      "to_char(null)",
      "favl.attribute9",
      "favl.attribute9",
      "Attribute9",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(150)
    },
    {
      "to_char(null)",
      "favl.attribute10",
      "favl.attribute10",
      "Attribute10",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(150)
    },
    {
      "to_char(null)",
      "favl.attribute11",
      "favl.attribute11",
      "Attribute11",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(150)
    },
    {
      "to_char(null)",
      "favl.attribute12",
      "favl.attribute12",
      "Attribute12",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(150)
    },
    {
      "to_char(null)",
      "favl.attribute13",
      "favl.attribute13",
      "Attribute13",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(150)
    },
    {
      "to_char(null)",
      "favl.attribute14",
      "favl.attribute14",
      "Attribute14",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(150)
    },
    {
      "to_char(null)",
      "favl.attribute15",
      "favl.attribute15",
      "Attribute15",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(150)
    },
    {
      "av.thumbnail_image",
      "to_char(null)",
      "favl.thumbnail_image",
      "THUMBNAIL_IMAGE",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(700)
    },
    {
      "av.picture",
      "to_char(null)",
      "favl.picture",  
      "PICTURE",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(700)
    },
    {
      "avtlp.alias",
      "to_char(null)",
      "to_char(null)",
      "ALIAS",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(700)
    },
    {
      "avtlp.comments",
      "to_char(null)",
      "to_char(null)",
      "COMMENTS",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(700)
    },
    {
      "av.availability",
      "to_char(null)",
      "to_char(null)",
      "AVAILABILITY",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(700)
    },
    {
      "av.lead_time",
      "to_number(null)",
      "to_number(null)",
      "LEAD_TIME",
      "oracle.jbo.domain.Number", new Integer(Types.NUMERIC),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {
      "av.supplier_url",
      "to_char(null)",
      "to_char(null)",
      "SUPPLIER_URL",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(700)
    },
    {
      "av.manufacturer_url",
      "to_char(null)",
      "to_char(null)",
      "MANUFACTURER_URL",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(700)
    },
    {
      "av.attachment_url",
      "to_char(null)",
      "to_char(null)",
      "ATTACHMENT_URL",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(700)
    },
    {
      "bq.is_item_available",
      "1",
      "1",
      "IsItemAvailable",
      "java.lang.Boolean", new Integer(Types.BIT),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {      
      "decode(bq.is_item_available, 1, 0, 1)",
      "0",
      "0",
      "IsItemNotAvailable",
      "java.lang.Boolean", new Integer(Types.BIT),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {
      "decode(nvl(bq.req_template_name, '-2'), '-2', 0, 1)",
      "0",
      "0",
      "IsReqTemplate",
      "java.lang.Boolean", new Integer(Types.BIT),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {      
      "DECODE(bq.source_type, 'MASTER_ITEM', DECODE(bq.item_type, 'PURCHASE', 0, 1), " +
      "'INTERNAL_TEMPLATE', 1, DECODE(msikfv.internal_order_enabled_flag, 'Y', 1, 0))", 
      "0",
      "0",
      "IsInternallyOrderable",
      "java.lang.Boolean", new Integer(Types.BIT),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {
      "DECODE(bq.source_type, 'MASTER_ITEM', DECODE(bq.item_type, 'INTERNAL', 0, 1), " +
      "'INTERNAL_TEMPLATE', 0, 1)",     
      "1",
      "1",
      "IsPurchasable",
      "java.lang.Boolean", new Integer(Types.BIT),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {
      "DECODE(bq.source_type, 'MASTER_ITEM', bq.item_type, " +
      "'INTERNAL_TEMPLATE', 'INTERNAL', DECODE(msikfv.internal_order_enabled_flag, 'Y', 'BOTH', 'PURCHASE'))",  
      "'PURCHASE'",
      "'PURCHASE'",
      "ItemType",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(8)
    },  
    {
      "bq.favorite_list_id",
      "favl.favorite_list_id",
      "favl.favorite_list_id",
      "FavoriteListId",
      "oracle.jbo.domain.Number", new Integer(Types.NUMERIC),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {
      "bq.favorite_list_line_id",
      "favl.favorite_list_line_id",
      "favl.favorite_list_line_id",
      "FavoriteListLineId",
      "oracle.jbo.domain.Number", new Integer(Types.NUMERIC),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    { 
      "to_number(null)",
      "to_number(null)", 
      "favl.content_zone_id", 
      "ContentZoneId",
      "oracle.jbo.domain.Number", new Integer(Types.NUMERIC),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(-1)
    },
    {
      "av.UNSPSC",
      "to_char(null)",
      "favl.unspsc_code", 
      "UNSPSC",
      "java.lang.String", new Integer(Types.VARCHAR),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(30)
    },
    {
      "to_number(null)",
      "to_number(null)",
      "favl.hazard_class_id", 
      "HazardClassId",
      "oracle.jbo.domain.Number", new Integer(Types.NUMERIC),
      new Boolean(false), new Boolean(true),
      new Byte(AttributeDef.READONLY), new Integer(30)
    },
    {
         "'CATALOG'" ,
         "'NONCATALOG'",
         "'EXTERNAL'",
         "CatalogType",
          "java.lang.String", new Integer(Types.VARCHAR),
          new Boolean(false), new Boolean(true),
          new Byte(AttributeDef.READONLY), new Integer(255)
       },
       
       {
         "'INTERNAL'" ,
         "'INTERNAL'",
         "'EXTERNAL'",
         "CatalogSource",
          "java.lang.String", new Integer(Types.VARCHAR),
          new Boolean(false), new Boolean(true),
          new Byte(AttributeDef.READONLY), new Integer(255)
       },
  };

  /**
   * Collection of Base descriptors that are not to be considered <br>
   * while appending in select clause
   */
  protected static final ArrayList m_excludeDesciptors = new ArrayList();
  static
  {
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


  /**
   * @see super's class java doc.
   */
  public OAViewObjectImpl getViewObject(VOBuilderContext context, String voName)
  {   
    OAApplicationModuleImpl am = context.getApplicationModule();
    OADBTransaction txn = am.getOADBTransaction();

    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "getViewObject.begin",
        OAFwkConstants.PROCEDURE);
    }            

    OAViewObjectImpl vo = null;
    String cacheName = getCacheName();
    
    try
    {
      vo = getViewObjectFromCache(context, voName, cacheName);

      // Set ItemKey to be the primary key for the VO
      if (vo.getKeyAttributeDefs().length == 0)
      {
        int itemKeyIndex = vo.getAttributeIndexOf("ItemKey");
        if (itemKeyIndex >= 0)
        {
          int[] primaryKeys = {itemKeyIndex};
          vo.setKeyAttributeDefs(primaryKeys);
        }
      }
    }
    catch (FrameworkException e)
    {
      // should never happen.
      if (txn.isLoggingEnabled(OAFwkConstants.EXCEPTION))
      {
        txn.writeDiagnostics(this, "Got FrameworkException when calling " +
        "getViewObjectFromCache, e = " + e, OAFwkConstants.EXCEPTION);
      }
    }

    // now get the additional where clause (advanced search and filter)
    ArrayList additionalWhereClauseAndBindKeys = 
      getAdditionalWhereClauseAndBindKeys(context);
    String additionalWhereClause = 
      (String)additionalWhereClauseAndBindKeys.get(0);
    ArrayList additionalBindKeys = 
      (ArrayList)additionalWhereClauseAndBindKeys.get(1);   

    if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
    {
      txn.writeDiagnostics(this, "additionalWhereClause = " + additionalWhereClause,
        OAFwkConstants.STATEMENT);
      txn.writeDiagnostics(this, "additionalBindKeys = " + additionalBindKeys,
        OAFwkConstants.STATEMENT);
    }

    // reset the where clause
    vo.setWhereClause(null);
    if (additionalWhereClause != null && !"".equals(additionalWhereClause))
    {      
      vo.setWhereClause(additionalWhereClause);
    }
    
    boolean isGridFormat = context.getIsResultsInGrid();
    if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
    {
      txn.writeDiagnostics(this, "isGridFormat = " + isGridFormat,
        OAFwkConstants.STATEMENT);     
    }

    // set order by clause only if it's not in grid format since OA will handle
    // the order by logic for the table in grid format
     // Bug 11675541 -> allowing to construct orderby clause eventhough it's in grid format for a public list.
     if (!isGridFormat || PUBLIC_LIST_VOB.equals(context.getBaseViewBuilderType())) 
    {
      String orderByClause = constructOrderByClause(context);
      if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
      {
        txn.writeDiagnostics(this, "orderByClause = " + orderByClause,
          OAFwkConstants.STATEMENT);     
      }
    
      vo.setOrderByClause(orderByClause);
    }

    ArrayList allBindKeys = getBindKeys(context);    
    
    if (additionalBindKeys != null)
    {
      allBindKeys.addAll(additionalBindKeys);
    }

    if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
    {
      txn.writeDiagnostics(this, "allBindKeys = " + allBindKeys,
        OAFwkConstants.STATEMENT);     
    }
    
    setBindParameters(vo, context, allBindKeys);

    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "getViewObject.end",
        OAFwkConstants.PROCEDURE);
    } 
    
    return vo;
  }

  /**
   * Constructs the key for mapping the View Definitions in the cache.
   *
   * @param context  Used to construct the unique key for caching purposes.
   * @return  ArrayList of view def keys
   */
  protected ArrayList constructKey(VOBuilderContext context)
  {
    OAApplicationModuleImpl am = context.getApplicationModule();
    OADBTransaction txn = am.getOADBTransaction();

    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "constructKey.begin",
        OAFwkConstants.PROCEDURE);
    } 
    
    ArrayList viewDefKey = new ArrayList();
    CategoryElement baseElement = context.getBaseElement();
    CategoryElement catElement = context.getCategoryElement();        
    String categoryIdStr = "" + context.getCatID();   
    HashSet includedSourceTypes = context.getIncludedSourceTypes();
    String shoppingFlow = context.getShoppingFlow();  
    
    if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
    {
      txn.writeDiagnostics(this, "categoryIdStr = " + categoryIdStr,
        OAFwkConstants.STATEMENT);  
      txn.writeDiagnostics(this, "includedSourceTypes = " + includedSourceTypes,
        OAFwkConstants.STATEMENT);
      txn.writeDiagnostics(this, "shoppingFlow = " + shoppingFlow,
        OAFwkConstants.STATEMENT);
    }
           
    viewDefKey.add(categoryIdStr);         
    viewDefKey.add(new Integer(baseElement == null ? 0 : baseElement.getVersion()));
    viewDefKey.add(new Integer(catElement == null ? 0 : catElement.getVersion())); 
    viewDefKey.add(includedSourceTypes == null ? null : new HashSet(includedSourceTypes));
    if (ShoppingConstants.SHOPPING_FLOW_PO.equals(shoppingFlow))
    {
      viewDefKey.add(new Boolean(true));
    }
    else
    {
      viewDefKey.add(new Boolean(false));
    }
    
    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "constructKey.end",
        OAFwkConstants.PROCEDURE);
    }
    
    return viewDefKey;
  }

  /**
   * Returns a consolidated list of bind value keys.
   * 
   * @parma addBindValueKeys ArrayList Containing additional <br>
   *        bind param keys.
   * @return ArrayList for bind keys
   */
  abstract protected ArrayList getBindKeys(VOBuilderContext context);

  /**
   * Empty implementation for child classes not requiring <br>
   * any special logic in this method.
   * 
   * @param context VOBuilderContext
   * @return  the order by clause
   */
  protected String constructOrderByClause(VOBuilderContext context)
  {
    return null;
  }

  /**
   * Constructs the SELECT clause 
   * 
   * @param context VOBuilderContext
   * @param viewDef OAviewDefImpl
   * @return  the select clause
   */
  public String constructSelectClause(VOBuilderContext context, OAViewDefImpl viewDef)
  {
    OAApplicationModuleImpl am = context.getApplicationModule();
    OADBTransaction txn = am.getOADBTransaction();

    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "constructSelectClause.begin",
        OAFwkConstants.PROCEDURE);
    }

    String selectClause = " * ";

    if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
    {
      txn.writeDiagnostics(this, "selectClause = " + selectClause,
        OAFwkConstants.STATEMENT);     
    }

    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "constructSelectClause.end",
        OAFwkConstants.PROCEDURE);
    }
    
    return selectClause;
  }

  /**
   * Constructs the FROM clause
   * 
   * @param context VOBuilderContext
   * @return  the from clause
   */
  public String constructFromClause(VOBuilderContext context, OAViewDefImpl viewDef)
  {
    OAApplicationModuleImpl am = context.getApplicationModule();
    OADBTransaction txn = am.getOADBTransaction();

    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "constructFromClause.begin",
        OAFwkConstants.PROCEDURE);
    }
    
    StringBuffer fromClauseBuffer = new StringBuffer();   
    
    fromClauseBuffer.append("( ");    
    fromClauseBuffer.append(constructLocalQuery(context, viewDef));  
    fromClauseBuffer.append(") bvoq");    

    if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
    {
      txn.writeDiagnostics(this, "fromClauseBuffer = " + fromClauseBuffer,
        OAFwkConstants.STATEMENT);     
    }

    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "constructFromClause.end",
        OAFwkConstants.PROCEDURE);
    }
    
    return fromClauseBuffer.toString();
  }

  /**
   * Constructs the WHERE clause
   * 
   * @param context handle for VOBuilderContext.
   * @retrun  the where clause
   */
  public String constructWhereClause(VOBuilderContext context)
  {
    OAApplicationModuleImpl am = context.getApplicationModule();
    OADBTransaction txn = am.getOADBTransaction();

    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "constructWhereClause.begin",
        OAFwkConstants.PROCEDURE);
    }

    String whereClause = null;

    if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
    {
      txn.writeDiagnostics(this, "whereClause = " + whereClause,
        OAFwkConstants.STATEMENT);
    }

    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "constructWhereClause.end",
        OAFwkConstants.PROCEDURE);
    }
    
    return whereClause;
  }

  /**
   * Constructs the local query
   * 
   * @param context VOBuilderContext
   * @return  the from clause
   */
  public String constructLocalQuery(VOBuilderContext context, OAViewDefImpl viewDef)
  {
    OAApplicationModuleImpl am = context.getApplicationModule();
    OADBTransaction txn = am.getOADBTransaction();

    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "constructLocalQuery.begin",
        OAFwkConstants.PROCEDURE);
    }
    
    StringBuffer localQueryBuffer = new StringBuffer();   
    
    localQueryBuffer.append("SELECT ");    
    localQueryBuffer.append(constructLocalSelectClause(context, viewDef));
    localQueryBuffer.append(" FROM ");   
    localQueryBuffer.append(constructLocalFromClause(context));
    localQueryBuffer.append(" WHERE ");  
    localQueryBuffer.append(constructLocalWhereClause(context));
        

    if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
    {
      txn.writeDiagnostics(this, "localQueryBuffer = " + localQueryBuffer,
        OAFwkConstants.STATEMENT);     
    }

    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "constructLocalQuery.end",
        OAFwkConstants.PROCEDURE);
    }
    
    return localQueryBuffer.toString();
  }

  /**
   * Construct local select clause
   * 
   * @param context VOBuilderContext 
   * @param viewDef  the select clause for the full query
   * @return the select clause
   */
  public String constructLocalSelectClause(VOBuilderContext context,
    OAViewDefImpl viewDef)
  {
    OAApplicationModuleImpl am = context.getApplicationModule();
    OADBTransaction txn = am.getOADBTransaction();

    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "constructLocalSelectClause.begin",
        OAFwkConstants.PROCEDURE);
    }

    String selectClause = 
      constructLocalSelectClause(context, viewDef, false);
    
    if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
    {
      txn.writeDiagnostics(this, "selectClause = " + selectClause,
        OAFwkConstants.STATEMENT);      
    }

    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "constructLocalSelectClause.end",
        OAFwkConstants.PROCEDURE);
    }

    return selectClause;
  }

  /**
   * Construct local select clause
   * 
   * @param context  VOBuilderContext 
   * @param viewDef  the select clause for the full query
   * @param areAllAttrsUpdatable  whether all the attributes are updatable
   * @return the select clause
   */
  public String constructLocalSelectClause(VOBuilderContext context,
    OAViewDefImpl viewDef, boolean areAllAttrsUpdatable)
  {
    OAApplicationModuleImpl am = context.getApplicationModule();
    OADBTransaction txn = am.getOADBTransaction();

    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "constructLocalSelectClause.begin",
        OAFwkConstants.PROCEDURE);
    }
    
    StringBuffer selectClauseBuffer = new StringBuffer();
    for (int i = 0; i < SELECT_CLAUSE_ARRAY.length; i++)
    {
      if (i != 0)
      {
        selectClauseBuffer.append(",");
      }

      Object[] attrDefEntry = SELECT_CLAUSE_ARRAY[i];
      // Use fixed index to get various values
      String colExp = (String)attrDefEntry[0]; // Basic Expression.
      String alias = (String)attrDefEntry[3];

      if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
      {
        txn.writeDiagnostics(this, "colExp = " + colExp,
          OAFwkConstants.STATEMENT);
        txn.writeDiagnostics(this, "alias = " + alias,
          OAFwkConstants.STATEMENT);
      }
    
      String viewAttrType = (String)attrDefEntry[4];
      Integer sqlType = (Integer)attrDefEntry[5];
      Boolean notNull = (Boolean)attrDefEntry[6];
      Boolean queriable = (Boolean)attrDefEntry[7];
      Byte updatable = null;
      if (areAllAttrsUpdatable) // for item detail, it's always updatable
      {
        updatable = new Byte(AttributeDef.UPDATEABLE);
      }
      else
      {
        updatable = (Byte)attrDefEntry[8];
      }      
      Integer precision = (Integer)attrDefEntry[9];
      selectClauseBuffer.append(colExp);
      selectClauseBuffer.append(SPACE);
      selectClauseBuffer.append(alias);
      if (viewDef != null)
      {
        viewDef.addSqlDerivedAttrDef(alias, alias, viewAttrType, sqlType.intValue(),
          notNull.booleanValue(), queriable.booleanValue(), updatable.byteValue(),
          precision.intValue());
      }
      // Add item to Select Clause using expression for basic query.
      // Add item attributes to ViewDef.
    }
    
    CategoryElement baseElement = context.getBaseElement();

    if (areAllAttrsUpdatable) 
    {
      appendBaseAttributes(context, selectClauseBuffer, baseElement,
        false, viewDef, true);
    }
    else
    {
      appendBaseAttributes(context, selectClauseBuffer, baseElement,
        false, viewDef);
    }  
          
    // now add the transient attributes
    addTransientAttributes(context, viewDef);

    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "constructLocalSelectClause.end",
        OAFwkConstants.PROCEDURE);
    }

    return selectClauseBuffer.toString();
  }
  
  
  /**
   * Adds the transient attributes to the view definition.
   * 
   * @param context  VOBuilderContext 
   * @param viewDef  the view definition 
   */
  protected void addTransientAttributes(VOBuilderContext context, 
    OAViewDefImpl viewDef)
  {
    OAApplicationModuleImpl am = context.getApplicationModule();
    OADBTransaction txn = am.getOADBTransaction();

    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "addTransientAttributes.begin",
        OAFwkConstants.PROCEDURE);
    }
  
    if (viewDef != null)
    {
      viewDef.addTransientAttrDef("SelectAttr", "java.lang.String", 
        "N", true, AttributeDef.UPDATEABLE);
        
      viewDef.addTransientAttrDef("MoveToListId", "oracle.jbo.domain.Number",
        "", false, AttributeDef.UPDATEABLE);
        
      viewDef.addTransientAttrDef("SupplierCode", "java.lang.String",
        "", false, AttributeDef.UPDATEABLE);
        
      viewDef.addTransientAttrDef("LineType", "java.lang.String",
        "", false, AttributeDef.UPDATEABLE);
        
      viewDef.addTransientAttrDef("ExternalUom", "java.lang.String",
        "", false, AttributeDef.UPDATEABLE);
        
      viewDef.addTransientAttrDef("CategoryCode", "java.lang.String",
        "", false, AttributeDef.UPDATEABLE);
        
      viewDef.addTransientAttrDef("ContentZoneUrl", "java.lang.String",
        "", false, AttributeDef.UPDATEABLE);
      
      viewDef.addTransientAttrDef("SupplierReferenceNumber", "java.lang.String",
        "", false, AttributeDef.UPDATEABLE);
        
      viewDef.addTransientAttrDef("IsPriceAvailable", "java.lang.Boolean",
        "", false, AttributeDef.UPDATEABLE);                
    }
    
    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "addTransientAttributes.end",
        OAFwkConstants.PROCEDURE);
    }
  }

  /**
   * Constructs local from clause
   * 
   * @param context VOBuilderContext
   * @return  the from clause for the full query
   */
  public String constructLocalFromClause(VOBuilderContext context)
  {
    OAApplicationModuleImpl am = context.getApplicationModule();
    OADBTransaction txn = am.getOADBTransaction();

    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "constructLocalFromClause.begin",
        OAFwkConstants.PROCEDURE);
    }
    
    StringBuffer fromClauseBuffer = new StringBuffer();
    
    HashSet includedSourceTypes = context.getIncludedSourceTypes();

    if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
    {
      txn.writeDiagnostics(this, "includedSourceTypes = " + includedSourceTypes,
        OAFwkConstants.STATEMENT);
    }
    
    boolean endecaEnabled=txn.testFunction("ICX_ENDECA_ACCESS_PERMISSION");

    // do precedence rules only if includedSourceTypes contains master item 
    // and any document type
    // we now do the precedence rules by using the analytic function count to
    // count the different source types for each master item    
    boolean doPrecedence = 
      includedSourceTypes.contains("MASTER_ITEM") && (includedSourceTypes.size() > 1) && (!endecaEnabled);
    
    String shoppingFlow = context.getShoppingFlow();

    if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
    {
      txn.writeDiagnostics(this, "shoppingFlow = " + shoppingFlow,
        OAFwkConstants.STATEMENT);
    }    
    
    boolean isSicPoFlow = ShoppingConstants.SHOPPING_FLOW_PO.equals(shoppingFlow);
    
    if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
    {
      txn.writeDiagnostics(this, "doPrecedence = " + doPrecedence,
        OAFwkConstants.STATEMENT);
      txn.writeDiagnostics(this, "isSicPoFlow = " + isSicPoFlow,
        OAFwkConstants.STATEMENT);
    } 
    
    if (doPrecedence && isSicPoFlow)
    {
      fromClauseBuffer.append(LOCAL_FROM_CLAUSE_WITH_PRECEDENCE_SIC_PO);
    }
    else if (doPrecedence && !isSicPoFlow)
    {     
      fromClauseBuffer.append(LOCAL_FROM_CLAUSE_WITH_PRECEDENCE);                  
    }
    else if (!doPrecedence && isSicPoFlow)
    {
      fromClauseBuffer.append(LOCAL_FROM_CLAUSE_SIC_PO);
    }
    else // (!doPrecedence && !isSicPoFlow)
    {            
      fromClauseBuffer.append(LOCAL_FROM_CLAUSE);   
    }      

    if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
    {
      txn.writeDiagnostics(this, "fromClauseBuffer = " + fromClauseBuffer,
        OAFwkConstants.STATEMENT);
    }

    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "constructLocalFromClause.end",
        OAFwkConstants.PROCEDURE);
    }
    
    return fromClauseBuffer.toString();
  }

  /**
   * Constructs the local where clause
   * 
   * @return the where clause for the full query
   */
  public String constructLocalWhereClause(VOBuilderContext context)
  {
    OAApplicationModuleImpl am = context.getApplicationModule();
    OADBTransaction txn = am.getOADBTransaction();

    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "constructLocalWhereClause.begin",
        OAFwkConstants.PROCEDURE);
    }
    
    StringBuffer whereClauseBuffer = new StringBuffer();      
    
    HashSet includedSourceTypes = context.getIncludedSourceTypes();

    if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
    {
      txn.writeDiagnostics(this, "includedSourceTypes = " + includedSourceTypes,
        OAFwkConstants.STATEMENT);
    }
    boolean endecaEnabled=txn.testFunction("ICX_ENDECA_ACCESS_PERMISSION");

    // do precedence rules only if includedSourceTypes contains master item 
    // and any document type
    // we now do the precedence rules by using the analytic function count to
    // count the different source types for each master item    
    boolean doPrecedence = 
      includedSourceTypes.contains("MASTER_ITEM") && (includedSourceTypes.size() > 1) && (!endecaEnabled);
    
    String shoppingFlow = context.getShoppingFlow();

    if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
    {
      txn.writeDiagnostics(this, "shoppingFlow = " + shoppingFlow,
        OAFwkConstants.STATEMENT);
    }    
    
    boolean isSicPoFlow = ShoppingConstants.SHOPPING_FLOW_PO.equals(shoppingFlow);    
    
    if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
    {
      txn.writeDiagnostics(this, "doPrecedence = " + doPrecedence,
        OAFwkConstants.STATEMENT);
      txn.writeDiagnostics(this, "isSicPoFlow = " + isSicPoFlow,
        OAFwkConstants.STATEMENT);
    } 
    
    if (doPrecedence && isSicPoFlow)
    {
      whereClauseBuffer.append(LOCAL_WHERE_CLAUSE_WITH_PRECEDENCE_SIC_PO);
    }
    else if (doPrecedence && !isSicPoFlow)
    {     
      whereClauseBuffer.append(LOCAL_WHERE_CLAUSE_WITH_PRECEDENCE);                  
    }
    else if (!doPrecedence && isSicPoFlow)
    {
      whereClauseBuffer.append(LOCAL_WHERE_CLAUSE_SIC_PO);
    }
    else // (!doPrecedence && !isSicPoFlow)
    {            
      whereClauseBuffer.append(LOCAL_WHERE_CLAUSE);   
    }  
        
    if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
    {
      txn.writeDiagnostics(this, "whereClauseBuffer = " + whereClauseBuffer,
        OAFwkConstants.STATEMENT);
    }

    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "constructLocalWhereClause.end",
        OAFwkConstants.PROCEDURE);
    }
    
    return whereClauseBuffer.toString();
  }

  /**
   * Wrapper to append base descriptors.
   * 
   * @param context  the vo builder context
   * @param selectClause  the select clause
   * @param element  Base/Category element.
   * @param nullStoredIn  to put null instead of <table>.<colname>
   * @param viewDef  view defination for the view object.
   */
  protected void appendBaseAttributes(VOBuilderContext context, 
    StringBuffer selectClause, CategoryElement baseElement,
    boolean nullStoredIn, OAViewDefImpl viewDef)
  {
    appendAttributes(context, baseElement, nullStoredIn, selectClause, viewDef, 
      m_excludeDesciptors, false);
  }


  /**
   * Wrapper to append base descriptors.
   * 
   * @param context  the vo builder context
   * @param selectClause  the select clause
   * @param element  Base/Category element.
   * @param nullStoredIn  boolean flag to put null instead of <table>.<colname>
   * @param viewDef  view defination for the view object.
   */
  protected void appendBaseAttributes(VOBuilderContext context,
    StringBuffer selectClause, CategoryElement baseElement, boolean nullStoredIn,
    OAViewDefImpl viewDef, boolean isUpdateable)
  {
    appendAttributes(context, baseElement, nullStoredIn, selectClause, viewDef,
      m_excludeDesciptors, isUpdateable);
  }


  /**
   * Wrapper to append category descriptors.
   * 
   * @param context  the vo builder context
   * @param selectClause  the select clause
   * @param element  Base/Category element.
   * @param nullStoredIn  to put null instead of <table>.<colname>
   * @param viewDef  view defination for the view object.
   */
  protected void appendCategoryAttributes(VOBuilderContext context,
    StringBuffer selectClause, CategoryElement catElement,
    boolean nullStoredIn, OAViewDefImpl viewDef)
  {
    appendAttributes(context, catElement, nullStoredIn, selectClause, viewDef, null, false);
  }

  /**
   * Append descriptors to select clause as well as to view defination <br>
   * 
   * @param context  the vo builder context
   * @param element  Base/Category element.
   * @param nullStoredIn  boolean flag to put null instead of <table>.<colname>
   * @param selectClause  the select clause
   * @param viewDef  view defination for the view object.
   */
  private void appendAttributes(VOBuilderContext context, CategoryElement element, 
    boolean nullStoredIn, StringBuffer selectClause, OAViewDefImpl viewDef,
    ArrayList excludeDescriptors, boolean isUpdateable)
  {
    OAApplicationModuleImpl am = context.getApplicationModule();
    OADBTransaction txn = am.getOADBTransaction();

    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "appendAttributes.begin",
        OAFwkConstants.PROCEDURE);
    }

    if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
    {
      txn.writeDiagnostics(this, "nullStoredIn = " + nullStoredIn,
        OAFwkConstants.STATEMENT);
      txn.writeDiagnostics(this, "selectClause = " + selectClause,
        OAFwkConstants.STATEMENT);
      txn.writeDiagnostics(this, "excludeDescriptors = " + excludeDescriptors,
        OAFwkConstants.STATEMENT);
      txn.writeDiagnostics(this, "isUpdateable = " + isUpdateable,
        OAFwkConstants.STATEMENT);
    }
    
    DescriptorElement[] descriptors = element.getDescriptors();
    String colAlias = null;
    String tableAlias = null;
    String colName = null;
    String storedInTable = null;
    String key = null;
    byte updateableVal = AttributeDef.READONLY;
    if (isUpdateable)
    {
      updateableVal = AttributeDef.UPDATEABLE;
    }

    for (int i = 0; i<descriptors.length; i++)
    {
      if (descriptors[i] == null)
      {
        continue;
      }
      colName = descriptors[i].getStoredInColumn();
      storedInTable = descriptors[i].getStoredInTable();
      key = descriptors[i].getKey();

      if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
      {
        txn.writeDiagnostics(this, "colName = " + colName,
          OAFwkConstants.STATEMENT);
        txn.writeDiagnostics(this, "storedInTable = " + storedInTable,
          OAFwkConstants.STATEMENT);
        txn.writeDiagnostics(this, "key = " + key,
          OAFwkConstants.STATEMENT);       
      }

      if ("PO_ATTRIBUTE_VALUES".equals(storedInTable))
      {
        tableAlias = "av";
      }
      else if ("PO_ATTRIBUTE_VALUES_TLP".equals(storedInTable))
      {
        tableAlias = "avtlp";
      }

      if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
      {
        txn.writeDiagnostics(this, "tableAlias = " + tableAlias,
          OAFwkConstants.STATEMENT);         
      }
      
      colAlias = colName;
      if ("THUMBNAIL_IMAGE".equals(key))
      {
        selectClause.append(", decode(substr(lower(");
        selectClause.append(colName);
        selectClause.append("), 1, 7), 'http://', 0, decode(substr(lower(");
        selectClause.append(colName);
        selectClause.append("), 1, 8), 'https://', 0, 1))");
        selectClause.append(" AS IsThumbnailFile");
        if (viewDef != null)
        {
          viewDef.addSqlDerivedAttrDef("IsThumbnailFile", "IsThumbnailFile", "java.lang.Boolean",
                                       Types.BIT, false, true, updateableVal, -1);

        }
        
      }
      if (storedInTable == null ||
          (excludeDescriptors != null && excludeDescriptors.contains(descriptors[i].getKey())))
      {
        continue;
      }

      selectClause.append(",");
      selectClause.append((nullStoredIn ? "null" : tableAlias + "."
        + colName) + " " + colAlias); // use key as column alias
        
      if (viewDef != null)
      {
        int sqlType = -1;
        int precision = -1;
        String attrType = "java.lang.String";

        // test for numeric descriptors
        if (DescriptorElement.NUMERIC_TYPE == Integer.parseInt(descriptors[i].getType()))
        {
          if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
          {
            txn.writeDiagnostics(this, "descriptor is numeric",
              OAFwkConstants.STATEMENT);         
          }
      
          attrType = "oracle.jbo.domain.Number";
          sqlType = java.sql.Types.NUMERIC;
          precision = -1; // for number we do not set precision
        }
        else if ("DESCRIPTION".equals(key))
        {
          sqlType = java.sql.Types.VARCHAR;
          precision = MAX_DESCRIPTION_LENGTH;
        }
        else if("LONG_DESCRIPTION".equals(key))
        {
          sqlType = java.sql.Types.VARCHAR;
          precision = MAX_LONG_DESCRIPTION_LENGTH;

        }
        else if("SUPPLIER_PART_NUM".equals(key))
        {
          sqlType = java.sql.Types.VARCHAR;
          precision = MAX_LONG_DESCRIPTION_LENGTH;
        
        }
        else if("MANUFACTURER".equals(key))
        {
          sqlType = java.sql.Types.VARCHAR;
          precision = MAX_LONG_DESCRIPTION_LENGTH;

        }
        else if("MANUFACTURER_PART_NUM".equals(key))
        {
          sqlType = java.sql.Types.VARCHAR;
          precision = MAX_LONG_DESCRIPTION_LENGTH;

        }
        else
        {
          sqlType = java.sql.Types.VARCHAR;
          precision = MAX_DESCRIPTOR_VALUE_LENGTH;
        }
        viewDef.addSqlDerivedAttrDef(colAlias, colAlias, attrType, sqlType, false,
          true, updateableVal, precision);
      }
    }

    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "appendAttributes.end",
        OAFwkConstants.PROCEDURE);
    }
  }

  /**
   * Gets the additional where clause and the corresponding bind keys.
   * 
   * @param context  the VO builder context
   * 
   * @return the additional where clause and the corresponding bind keys
   */
  protected ArrayList getAdditionalWhereClauseAndBindKeys(
    VOBuilderContext context)
  {       
    RequisitionAMImpl am = (RequisitionAMImpl)context.getApplicationModule();    
    OADBTransaction txn = (OADBTransaction)am.getOADBTransaction();
    
    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "getAdditionalWhereClauseAndBindKeys.begin",
        OAFwkConstants.PROCEDURE);
    }
    
    ArrayList additionalWhereClauseAndBindkeys = new ArrayList(2);
    String additionalWhereClause = null;
    ArrayList additionalBindKeys = null;

    boolean isSearchFiltered = context.getIsSearchFiltered();
    
    if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
    {
      txn.writeDiagnostics(this, "isSearchFiltered = " + isSearchFiltered,
        OAFwkConstants.STATEMENT);
    }
    
    if (context.getIsSearchFiltered())
    {
      ArrayList filterWhereClauseAndBindKeys = 
        getFilterWhereClauseAndBindKeys(context, 1);
        
      additionalWhereClause = (String)filterWhereClauseAndBindKeys.get(0);
      additionalBindKeys = (ArrayList)filterWhereClauseAndBindKeys.get(1);          
    }

    additionalWhereClauseAndBindkeys.add(additionalWhereClause);
    additionalWhereClauseAndBindkeys.add(additionalBindKeys);

    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "getAdditionalWhereClauseAndBindKeys.end",
        OAFwkConstants.PROCEDURE);
    }
    
    return additionalWhereClauseAndBindkeys;
  }

  /**
   * Constructs the advanced search where clause and its corresponding bind
   * keys. This method assumes that AdvancedSearchValuesVO is populated 
   * correctly.
   * 
   * @param context    the VO builder context
   * @param bindIndex  the starting bind index of the where clause
   *
   * @returns  the advanced search where clause and the bind value keys           
   */
  protected ArrayList getAdvSearchWhereClauseAndBindKeys(
    VOBuilderContext context, int bindIndex)
  {    
    RequisitionAMImpl am = (RequisitionAMImpl)context.getApplicationModule();    
    OADBTransaction txn = (OADBTransaction)am.getOADBTransaction();
    
    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "getAdvSearchWhereClauseAndBindKeys.begin",
        OAFwkConstants.PROCEDURE);
    }

    StringBuffer advSearchWhereClause = new StringBuffer();
    ArrayList advSearchBindKeys = new ArrayList();
    
    HashMap paramValuesMap = context.getBindParamValues();  

    if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
    {
      txn.writeDiagnostics(this, "paramValuesMap = " + paramValuesMap,
        OAFwkConstants.STATEMENT);
    }
        
    OAViewObjectImpl advancedSearchValuesVO = 
      (OAViewObjectImpl)am.findViewObject(ADVANCED_SEARCH_VALUES_VO);
      
    if (advancedSearchValuesVO != null)
    {
      advancedSearchValuesVO.setMaxFetchSize(0);
      String attributeName = null;
      String condition = null;
      String value1Str = null;
      String value2Str = null;
      Object value1 = null;
      Object value2 = null;
      Number typeNum = null;
      String type = null;
      boolean isFirst = true;
      String key = null;
      AdvancedSearchValuesVORowImpl row = 
        (AdvancedSearchValuesVORowImpl)advancedSearchValuesVO.first();
        
      while (row != null)
      {
        // we check if the inner row has the same stored in column
        // only if there is a match we get the values
        attributeName = row.getStoredInColumn();
        key = row.getDescriptorKey();

        if ("UOM".equals(key))
        {
          attributeName = "UomCode";
        }

        if (attributeName == null)
        {
          attributeName = key;
        }

        condition = row.getCondition();
        value1Str = row.getValue1();
        value2Str = row.getValue2();
        typeNum = row.getType();
        type = typeNum.toString();
        
        if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
        {
          txn.writeDiagnostics(this, "attributeName = " + attributeName, 
            OAFwkConstants.STATEMENT);
          txn.writeDiagnostics(this, "condition = " + condition, 
            OAFwkConstants.STATEMENT);
          txn.writeDiagnostics(this, "value1Str = " + value1Str, 
            OAFwkConstants.STATEMENT);  
          txn.writeDiagnostics(this, "value2Str = " + value2Str, 
            OAFwkConstants.STATEMENT);
          txn.writeDiagnostics(this, "typeNum = " + typeNum, 
            OAFwkConstants.STATEMENT);  
          txn.writeDiagnostics(this, "type = " + type, 
            OAFwkConstants.STATEMENT);
        }
        
        if (type.equals(ONE))
        {
          OANLSServices serviceObject = new  OANLSServices(txn);//added for bug#6038133 FP of bug#6015852
          // numeric attribute
          // convert values to numbers
          if (value1Str != null)
          {
              value1 = serviceObject.stringToNumber(value1Str);//added for bug#6038133 FP of bug#6015852, as oracle.jbo.domain.Number class throws exception while converting the formatted number string to number
          }
          if (value2Str != null)
          {
              value2 = serviceObject.stringToNumber(value2Str);////added for bug#6038133 FP of bug#6015852, as oracle.jbo.domain.Number class throws exception while converting the formatted number string to number  
          }
        }
        else
        {
          value1 = value1Str;
          value2 = value2Str;
        }

        if (!am.isIntermediaCondition(key))
        {
          // we add a bind for every
          if (isFirst)
          {
            isFirst = false;
          }
          else
          {            
            advSearchWhereClause.append(" AND ");
          }         
          advSearchWhereClause.append("(bvoq.");
          advSearchWhereClause.append(attributeName);
          advSearchWhereClause.append(getWhereCondition(condition));
          advSearchWhereClause.append(":");
          advSearchWhereClause.append(bindIndex);

          if (condition.equals(BETWEEN))
          {
            paramValuesMap.put(ADVANCED_SEARCH_BIND_KEY_PREFIX + bindIndex, value1);
            advSearchBindKeys.add(ADVANCED_SEARCH_BIND_KEY_PREFIX + bindIndex);
            bindIndex++;
           
            advSearchWhereClause.append(" AND :");           
            advSearchWhereClause.append(bindIndex);
            paramValuesMap.put(ADVANCED_SEARCH_BIND_KEY_PREFIX + bindIndex, value2);
            advSearchBindKeys.add(ADVANCED_SEARCH_BIND_KEY_PREFIX + bindIndex);
          }
          else
          {
            paramValuesMap.put(ADVANCED_SEARCH_BIND_KEY_PREFIX + bindIndex, value1);
            advSearchBindKeys.add(ADVANCED_SEARCH_BIND_KEY_PREFIX + bindIndex);
          }
          bindIndex++;         
          advSearchWhereClause.append(" )");
        }
        row = (AdvancedSearchValuesVORowImpl)advancedSearchValuesVO.next();
      }
      context.setBindParamValues(paramValuesMap);
    }

    if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
    {
      txn.writeDiagnostics(this, "advSearchWhereClause = " + advSearchWhereClause,
        OAFwkConstants.STATEMENT);
      txn.writeDiagnostics(this, "advSearchBindKeys = " + advSearchBindKeys,
        OAFwkConstants.STATEMENT);
    }

    ArrayList advSearchWhereClauseAndBindKeys = new ArrayList(2);
    advSearchWhereClauseAndBindKeys.add(advSearchWhereClause.toString());
    advSearchWhereClauseAndBindKeys.add(advSearchBindKeys);
    
    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "getAdvSearchWhereClauseAndBindKeys.end",
        OAFwkConstants.PROCEDURE);
    }
    
    return advSearchWhereClauseAndBindKeys;
  }

  /**
   * Constructs the filter where clause and its corresponding bind
   * value keys. This method assumes that FilterValuesVO and FilteredAttributesVO
   * are populated correctly and are in sync.
   * 
   * @param context    the VO builder context
   * @param bindIndex  the starting bind index of the where clause
   *
   * @returns  the filter where clause string and the bind value keys           
   */
  protected ArrayList getFilterWhereClauseAndBindKeys(
    VOBuilderContext context, int bindIndex)
  {        
    OAApplicationModuleImpl am = context.getApplicationModule();    
    OADBTransaction txn = (OADBTransaction)am.getOADBTransaction();
    
    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "getFilterWhereClauseAndBindKeys.begin",
        OAFwkConstants.PROCEDURE);
    }

    StringBuffer filterWhereClause = new StringBuffer();
    ArrayList filterBindKeys = new ArrayList();

    HashMap paramValuesMap = context.getBindParamValues();

    OAViewObjectImpl filterValuesVO = 
      (OAViewObjectImpl)am.findViewObject(FILTER_VALUES_VO);
    OAViewObjectImpl filteredAttributesVO = 
      (OAViewObjectImpl)am.findViewObject(FILTER_ATTRIBUTES_VO);

    if (filterValuesVO != null && filteredAttributesVO != null)
    {
      filterValuesVO.setMaxFetchSize(0);
      filteredAttributesVO.setMaxFetchSize(0);
      String storedInColumn = null;
      String innerStoredInColumn = null;
      String value = null;
      
      // filtered attributes VO has a list of distinct attributes
      // one per row
      // we loop through this to get these distinct attributes
      FilteredAttributesVORowImpl row = 
        (FilteredAttributesVORowImpl)filteredAttributesVO.first();
      FilterValuesVORowImpl innerRow = null;
      boolean isFirst = true;
      boolean isInnerFirst = true;

      while (row != null)
      {
        if (!isFirst)
        {
          filterWhereClause.append(") AND ");
        }
        else
        {
          isFirst = false;
        }

        // the stored in column is what we use as the attribute name
        storedInColumn = row.getStoredInColumn();

        if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
        {
          txn.writeDiagnostics(this, "storedInColumn = " + storedInColumn,
            OAFwkConstants.STATEMENT);
        }

        filterWhereClause.append("bvoq.");
        filterWhereClause.append(storedInColumn);
        filterWhereClause.append(" IN (");
        innerRow = (FilterValuesVORowImpl)filterValuesVO.first();
        isInnerFirst = true;
        while (innerRow != null)
        {
          // we check if the inner row has the same stored in column
          // only if there is a match we get the values
          innerStoredInColumn = innerRow.getStoredInColumn();
          value = innerRow.getValue();

          if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
          {
            txn.writeDiagnostics(this, "value = " + value,
              OAFwkConstants.STATEMENT);
          }
        
          if (innerStoredInColumn.equals(storedInColumn))
          {
            // we add a bind for every
            if (isInnerFirst)
            {
              isInnerFirst = false;
            }
            else
            {
              filterWhereClause.append((","));
            }
            filterWhereClause.append(":");
            filterWhereClause.append(bindIndex);
            paramValuesMap.put(FILTER_BIND_KEY_PREFIX + bindIndex, value);
            filterBindKeys.add(FILTER_BIND_KEY_PREFIX + bindIndex);
            bindIndex++;
          }
          innerRow = (FilterValuesVORowImpl)filterValuesVO.next();
        }
        row = (FilteredAttributesVORowImpl)filteredAttributesVO.next();
      }

      if (filterWhereClause.length() > 0)
      {
        filterWhereClause.append(")");
      }
      
      context.setBindParamValues(paramValuesMap);
    }

    if (txn.isLoggingEnabled(OAFwkConstants.STATEMENT))
    {
      txn.writeDiagnostics(this, "filterWhereClause = " + filterWhereClause,
        OAFwkConstants.STATEMENT);
      txn.writeDiagnostics(this, "filterBindKeys = " + filterBindKeys,
        OAFwkConstants.STATEMENT);
    }

    ArrayList filterWhereClauseAndBindValueKeys = new ArrayList(2);
    filterWhereClauseAndBindValueKeys.add(filterWhereClause.toString());
    filterWhereClauseAndBindValueKeys.add(filterBindKeys);
    
    if (txn.isLoggingEnabled(OAFwkConstants.PROCEDURE))
    {
      txn.writeDiagnostics(this, "getFilterWhereClauseAndBindKeys.end",
        OAFwkConstants.PROCEDURE);
    }

    return filterWhereClauseAndBindValueKeys;
  } 

  /**
   * Gets the where condition for advanced searches.
   *
   * @param condition  The condition to be checked.
   * @returns  the where condition for the given condition from advanced search.
   */
  protected String getWhereCondition(String condition)
  {
    StringBuffer whereConditionBuffer = new StringBuffer();
    
    whereConditionBuffer.append(SPACE);
    if (condition.equals(BETWEEN))
    {
      whereConditionBuffer.append(BETWEEN);
    }
    else if (condition.equals(GREATER_THAN))
    {
      whereConditionBuffer.append('>');
    }
    else if (condition.equals(LESS_THAN))
    {
      whereConditionBuffer.append('<');
    }
    else if (condition.equals(IS))
    {
      whereConditionBuffer.append('=');
    }
    whereConditionBuffer.append(SPACE);
    
    return whereConditionBuffer.toString();
  }
  
  /**
   * Implementation will be given by extending VOBuilder's.
   * 
   * @return String VOBuilder's cache name.
   */
  abstract protected String getCacheName();
}