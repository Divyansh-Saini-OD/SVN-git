// Decompiled by DJ v3.9.9.91 Copyright 2005 Atanas Neshkov  Date: 2/9/2007 10:28:33 PM
// Home Page : http://members.fortunecity.com/neshkov/dj.html  - Check often for new version!
// Decompiler options: packimports(3) 
// Source File Name:   ShoppingSearchVOBuilder.java

package oracle.apps.icx.icatalog.shopping.server;

import com.sun.java.util.collections.HashSet;
import java.sql.Types;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.server.*;
import oracle.apps.icx.catalog.loader.elements.CategoryElement;
import oracle.apps.icx.catalog.loader.elements.DescriptorElement;
import oracle.apps.icx.icatalog.common.BuilderContext;
import oracle.apps.icx.icatalog.common.server.*;
import oracle.jbo.AttributeDef;
import oracle.jbo.server.ApplicationModuleImpl;
import oracle.jbo.server.ViewDefImpl;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.cabo.ui.UIConstants;
import oracle.cabo.ui.beans.BaseWebBean;
import oracle.cabo.ui.beans.form.TextInputBean;
import oracle.apps.fnd.framework.webui.*; 
import com.sun.java.util.collections.HashMap;
import java.io.Serializable;
import java.util.Hashtable;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.*;

// Referenced classes of package oracle.apps.icx.icatalog.shopping.server:
//            ShoppingVOBuilder, ShoppingAMImpl

/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |                       Oracle WIPRO Consulting Organization                |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             shoppingSearchVOBuilder.java                                  |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    This java file is modified for the Extension E0990 Restrict Items      |
 | Able to restrict certain users from requesting certain items that are     |
 | available in iProc. Requestor should only view the items that belong to   |
 | his Group or Department                                                   |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    This class file is called from searhEmpCO.java                         |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    04/11/2007 Anusha R     Modified                                       |
 |                                                                           |
 +===========================================================================*/
public class ShoppingSearchVOBuilder extends ShoppingVOBuilder
{
    protected boolean includeDescriptorInSearchQuery(DescriptorElement descriptorelement)
    {
        String s = descriptorelement.getKey();
        String s1 = descriptorelement.getSearchResultsVisible();
        return ("1".equals(s1) || ShoppingVOBuilder.s_attributesToIncludeAlways.contains(s)) && !ShoppingVOBuilder.s_attributesToNotInclude.contains(s);
    }

    protected String constructHintClause(CategoryElement categoryelement, CategoryElement categoryelement1, BuilderContext buildercontext, OAApplicationModuleImpl oaapplicationmoduleimpl)
    {
        String s = null;
        String s1 = getType();
        OADBTransaction oadbtransaction = oaapplicationmoduleimpl.getOADBTransaction();
        String s2 = (String)oadbtransaction.getValue("sortBy");
        if("Relevance".equals(s2) && super.m_type.equals("Shopping Search"))
            s = "FIRST_ROWS";
        else
        if(!"Favorite List Item".equals(s1) && !"Public List Item".equals(s1))
            s = "LEADING(ICX_CAT_ITEMS_TLP)";
        return s;
    }

    protected String constructWhereClause(CategoryElement categoryelement, CategoryElement categoryelement1, BuilderContext buildercontext, OAApplicationModuleImpl oaapplicationmoduleimpl)
    {
        OADBTransaction oadbtransaction = oaapplicationmoduleimpl.getOADBTransaction();
        String s = (String)oadbtransaction.getValue("searchOrigin");
        if("favoriteList".equals(s))
            return constructWhereClauseForFavoriteItem(categoryelement, categoryelement1, buildercontext, oaapplicationmoduleimpl);
        if("publicList".equals(s))
            return constructWhereClauseForPublicListItem(categoryelement, categoryelement1, buildercontext, oaapplicationmoduleimpl);
        String s1 = oadbtransaction.getProfile("POR_APPROVED_PRICING_ONLY");
        boolean flag = s1.equals("Y");
        String s2 = String.valueOf(oadbtransaction.getEmployeeId());
        String s3 = ((ShoppingAMImpl)oaapplicationmoduleimpl).getItemSourceSetting(s2);
        String s4 = String.valueOf(oadbtransaction.getResponsibilityId());
        String s5 = ((ShoppingAMImpl)oaapplicationmoduleimpl).isCategoryRealmsEnabled(s4);
        boolean flag1 = s5.equals("Y");
        StringBuffer stringbuffer = new StringBuffer(3500);
        boolean flag2 = ((Boolean)buildercontext.getParameter("Include Category Descriptors")).booleanValue();
        stringbuffer.append("ICX_CAT_ITEMS_TLP");
        stringbuffer.append(".rt_item_id = ");
        stringbuffer.append("ICX_CAT_ITEM_PRICES");
        stringbuffer.append(".rt_item_id");
        stringbuffer.append(" AND ");
        stringbuffer.append("ICX_CAT_ITEMS_TLP");
// View statement is added for the E0990 Restrict Items by Anusha on 11 Apr 2007
        stringbuffer.append(".internal_item_id IN (select inventory_item_id from XX_PO_RESP_CATSETS_V) ");
        stringbuffer.append(" AND ");
        stringbuffer.append("ICX_CAT_ITEMS_TLP");
        stringbuffer.append(".language = :");

        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        if(flag2)
        {
            stringbuffer.append(" AND ");
            stringbuffer.append("ICX_CAT_EXT_ITEMS_TLP");
            stringbuffer.append(".rt_item_id = ");
            stringbuffer.append("ICX_CAT_ITEMS_TLP");
            stringbuffer.append(".rt_item_id");
            stringbuffer.append(" AND ");
            stringbuffer.append("ICX_CAT_EXT_ITEMS_TLP");
            stringbuffer.append(".language = ");
            stringbuffer.append("ICX_CAT_ITEMS_TLP");
            stringbuffer.append(".language");
        }
        stringbuffer.append(" AND CONTAINS(");
        stringbuffer.append("ICX_CAT_ITEMS_TLP");
        stringbuffer.append(".ctx_desc,  :");
        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        stringbuffer.append(", 1) > 0");
        if(!super.m_type.equals("Public List Matches"))
        {
            stringbuffer.append(" AND ");
            stringbuffer.append("ICX_CAT_ITEM_PRICES");
            stringbuffer.append(".active_flag = 'Y'");
        }
        if(flag)
        {
            stringbuffer.append(" AND ");
            stringbuffer.append("ICX_CAT_ITEM_PRICES");
            stringbuffer.append(".org_id = :");
            stringbuffer.append(super.m_bindIndex);
            super.m_bindIndex++;
            stringbuffer.append(" AND ");
            stringbuffer.append("ICX_CAT_ITEM_PRICES");
            stringbuffer.append(".price_type in ('TEMPLATE', 'BLANKET', 'QUOTATION', 'GLOBAL_AGREEMENT')");
        } else
        {
            stringbuffer.append(" AND (");
            stringbuffer.append("ICX_CAT_ITEM_PRICES");
            stringbuffer.append(".org_id = :");
            stringbuffer.append(super.m_bindIndex);
            super.m_bindIndex++;
            stringbuffer.append(" OR (");
            stringbuffer.append("ICX_CAT_ITEM_PRICES");
            stringbuffer.append(".org_id = -2 AND NOT EXISTS (");
            stringbuffer.append(" SELECT NULL FROM ");
            stringbuffer.append("ICX_CAT_ITEMS_B");
            stringbuffer.append(" ITEMS2, ");
            stringbuffer.append("ICX_CAT_ITEM_PRICES");
            stringbuffer.append(" PRICES2");
            stringbuffer.append(" WHERE ITEMS2.supplier_part_num = ");
            stringbuffer.append("ICX_CAT_ITEMS_TLP");
            stringbuffer.append(".supplier_part_num");
            stringbuffer.append(" AND ITEMS2.supplier = ");
            stringbuffer.append("ICX_CAT_ITEMS_TLP");
            stringbuffer.append(".supplier");
            stringbuffer.append(" AND ITEMS2.supplier_part_auxid = ");
            stringbuffer.append("ICX_CAT_ITEMS_TLP");
            stringbuffer.append(".supplier_part_auxid");
            stringbuffer.append(" AND ITEMS2.rt_item_id = PRICES2.rt_item_id");
            stringbuffer.append(" AND PRICES2.active_flag = 'Y'");
            stringbuffer.append(" AND PRICES2.org_id = :");
            stringbuffer.append(super.m_bindIndex);
            stringbuffer.append(" )))");
            super.m_bindIndex++;
        }
        if("SUPPLIER".equals(s3))
        {
            stringbuffer.append(" AND ");
            stringbuffer.append("ICX_CAT_ITEM_PRICES");
            stringbuffer.append(".search_type = :");
            stringbuffer.append(super.m_bindIndex);
            super.m_bindIndex++;
        } else
        if("INTERNAL".equals(s3))
        {
            stringbuffer.append(" AND ");
            stringbuffer.append("ICX_CAT_ITEM_PRICES");
            stringbuffer.append(".search_type = :");
            stringbuffer.append(super.m_bindIndex);
            super.m_bindIndex++;
        } else
        if(!super.m_type.equals("Public List Matches"))
        {
            stringbuffer.append(" AND ");
            stringbuffer.append("ICX_CAT_ITEMS_TLP");
            stringbuffer.append(".search_type = ");
            stringbuffer.append("ICX_CAT_ITEM_PRICES");
            stringbuffer.append(".search_type");
        }
        stringbuffer.append(" AND ");
        stringbuffer.append("ICX_CAT_ITEM_PRICES");
        stringbuffer.append(".unit_of_measure = ");
        stringbuffer.append("MTL_UNITS_OF_MEASURE_TL");
        stringbuffer.append(".uom_code(+)");
        stringbuffer.append(" AND ");
        stringbuffer.append("MTL_UNITS_OF_MEASURE_TL");
        stringbuffer.append(".language(+) = :");
        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        if(flag1)
            stringbuffer.append(constructRealmForWhereClause());
        return stringbuffer.toString();
    }

    protected String constructOrderByClause(CategoryElement categoryelement, CategoryElement categoryelement1, BuilderContext buildercontext, OAApplicationModuleImpl oaapplicationmoduleimpl)
    {
        OADBTransaction oadbtransaction = oaapplicationmoduleimpl.getOADBTransaction();
        String s = (String)oadbtransaction.getValue("sortBy");
        String s1 = (String)oadbtransaction.getValue("sortOrder");
        String s2 = null;
        String s3 = (String)oadbtransaction.getValue("searchOrigin");
        if(!"publicList".equals(s3) && !"favoriteList".equals(s3))
        {
            if("Relevance".equals(s))
                s2 = "score(1) " + s1;
        } else
        if("publicList".equals(s3))
            s2 = " TemplateLineId ASC";
        return s2;
    }

    public OAViewObjectImpl getViewObject(BuilderContext buildercontext, OAApplicationModuleImpl oaapplicationmoduleimpl, String s)
    {
        if("Shopping Search".equals(getType()) || "Public List Item".equals(getType()))
            return getViewObjectFromCache(buildercontext, oaapplicationmoduleimpl, s);
        if("Favorite List Item".equals(getType()))
            return getViewObjectFavoriteListItems(buildercontext, oaapplicationmoduleimpl, s);
        if("Filter: Distinct Values".equals(getType()))
            return getViewObjectDistinctFilterValues(buildercontext, oaapplicationmoduleimpl, s);
        if("Category Matches".equals(getType()))
            return getViewObjectCategoryMatches(buildercontext, oaapplicationmoduleimpl, s);
        if("Public List Matches".equals(getType()))
            return getViewObjectPublicListMatches(buildercontext, oaapplicationmoduleimpl, s);
        if("Favorite List Matches".equals(getType()))
            return getViewObjectFavoriteListMatches(buildercontext, oaapplicationmoduleimpl, s);
        if("Search Governor".equals(getType()))
            return getViewObjectSearchGovernor(buildercontext, oaapplicationmoduleimpl, s);
        else
            return null;
    }

    protected OAViewObjectImpl getViewObjectSearchGovernor(BuilderContext buildercontext, OAApplicationModuleImpl oaapplicationmoduleimpl, String s)
    {
        return getAuxiliaryViewObject(buildercontext, oaapplicationmoduleimpl, s, "Search Governor");
    }

    protected OAViewObjectImpl getViewObjectCategoryMatches(BuilderContext buildercontext, OAApplicationModuleImpl oaapplicationmoduleimpl, String s)
    {
        return getAuxiliaryViewObject(buildercontext, oaapplicationmoduleimpl, s, "Category Matches");
    }

    protected OAViewObjectImpl getViewObjectPublicListMatches(BuilderContext buildercontext, OAApplicationModuleImpl oaapplicationmoduleimpl, String s)
    {
        return getAuxiliaryViewObject(buildercontext, oaapplicationmoduleimpl, s, "Public List Matches");
    }

    protected OAViewObjectImpl getViewObjectFavoriteListMatches(BuilderContext buildercontext, OAApplicationModuleImpl oaapplicationmoduleimpl, String s)
    {
        return getAuxiliaryViewObject(buildercontext, oaapplicationmoduleimpl, s, "Favorite List Matches");
    }

    protected OAViewObjectImpl getViewObjectDistinctFilterValues(BuilderContext buildercontext, OAApplicationModuleImpl oaapplicationmoduleimpl, String s)
    {
        return getAuxiliaryViewObject(buildercontext, oaapplicationmoduleimpl, s, "Filter: Distinct Values");
    }

    protected OAViewObjectImpl getViewObjectFavoriteListItems(BuilderContext buildercontext, OAApplicationModuleImpl oaapplicationmoduleimpl, String s)
    {
        return getAuxiliaryViewObject(buildercontext, oaapplicationmoduleimpl, s, "Favorite List Item");
    }

    protected OAViewObjectImpl getAuxiliaryViewObject(BuilderContext buildercontext, OAApplicationModuleImpl oaapplicationmoduleimpl, String s, String s1)
    {
        CatalogViewDefImpl catalogviewdefimpl = new CatalogViewDefImpl();
        boolean flag = ((Boolean)buildercontext.getParameter("Include Category Descriptors")).booleanValue();
        String s2 = (String)buildercontext.getParameter("Language");
        int i = 0;
        if(flag)
        {
            String s3 = (String)buildercontext.getParameter("Category Id");
            if(s3 != null)
                i = Integer.parseInt(s3);
        }
        SchemaAMImpl schemaamimpl = (SchemaAMImpl)oaapplicationmoduleimpl.findApplicationModule("SchemaAM");
        CategoryElement categoryelement = schemaamimpl.getCategoryElement(0, s2);
        CategoryElement categoryelement1 = null;
        if(flag)
            categoryelement1 = schemaamimpl.getCategoryElement(i, s2);
        String s4 = null;
        String s5 = null;
        if(s1.equals("Filter: Distinct Values"))
        {
            s5 = (String)((OADBTransactionImpl)oaapplicationmoduleimpl.getTransaction()).getValue("distinctValueColumn");
            s4 = "DISTINCT " + s5 + " AS Value, 'N' as FilterCheckBox";
            catalogviewdefimpl.addViewAttribute("Value", "Value", "java.lang.String", 12, 700, false, true, (byte)0);
            catalogviewdefimpl.addViewAttribute("FilterCheckBox", "FilterCheckBox", "java.lang.String", 12, 10, false, true, (byte)2);
        } else
        if(s1.equals("Category Matches"))
        {
            s4 = "DISTINCT ICX_CAT_ITEMS_TLP.primary_category_id  AS CategoryId, ICX_CAT_ITEMS_TLP.primary_category_name AS CategoryName";
            catalogviewdefimpl.addViewAttribute("CategoryId", "CategoryId", "oracle.jbo.domain.Number", 2, -1, false, true, (byte)0);
            catalogviewdefimpl.addViewAttribute("CategoryName", "CategoryName", "java.lang.String", 12, 250, false, true, (byte)0);
        } else
        if(s1.equals("Public List Matches"))
        {
            s4 = "DISTINCT ICX_CAT_ITEM_PRICES.template_id AS TemplateId";
            catalogviewdefimpl.addViewAttribute("TemplateId", "TemplateId", "java.lang.String", 12, 25, false, true, (byte)0);
        } else
        if(s1.equals("Favorite List Matches"))
        {
            s4 = "1 AS FavoriteListMatch";
            catalogviewdefimpl.addViewAttribute("FavoriteListMatch", "FavoriteListMatch", "oracle.jbo.domain.Number", 2, -1, false, true, (byte)0);
        } else
        if(s1.equals("Search Governor"))
        {
            s4 = "count(*) as ItemCount";
            catalogviewdefimpl.addViewAttribute("ItemCount", "ItemCount", "oracle.jbo.domain.Number", 2, -1, false, true, (byte)0);
        } else
        if(s1.equals("Favorite List Item"))
        {
            buildercontext.setParameter("searchOrigin", "favoriteList");
            s4 = constructSelectClause(categoryelement, categoryelement1, buildercontext, oaapplicationmoduleimpl, catalogviewdefimpl);
        }
        String s6 = constructFromClause(categoryelement, categoryelement1, buildercontext);
        if(s1.equals("Favorite List Matches"))
            s6 = s6 + " , " + "POR_FAVORITE_LIST_HEADERS" + ", " + "POR_FAVORITE_LIST_LINES";
        String s7 = constructWhereClause(categoryelement, categoryelement1, buildercontext, oaapplicationmoduleimpl);
        if(s1.equals("Filter: Distinct Values"))
        {
            String s8 = " AND " + s5 + " is not null";
            s7 = s7 + s8;
        } else
        if(s1.equals("Public List Matches"))
        {
            String s9 = " AND template_id is not null AND template_id <> '-2'";
            s7 = s7 + s9;
        } else
        if(s1.equals("Favorite List Matches"))
        {
            StringBuffer stringbuffer = new StringBuffer(100);
            stringbuffer.append(" AND POR_FAVORITE_LIST_HEADERS.favorite_list_id = POR_FAVORITE_LIST_LINES.favorite_list_id ");
            stringbuffer.append(" AND POR_FAVORITE_LIST_HEADERS.employee_id = :");
            stringbuffer.append(super.m_bindIndex);
            super.m_bindIndex++;
            stringbuffer.append(" AND POR_FAVORITE_LIST_LINES.rt_item_id = ");
            stringbuffer.append("ICX_CAT_ITEMS_TLP");
            stringbuffer.append(".rt_item_id");
            s7 = s7 + stringbuffer.toString();
        } else
        if(s1.equals("Search Governor"))
        {
            String s10 = " AND rownum <= :" + super.m_bindIndex;
            super.m_bindIndex++;
            s7 = s7 + s10;
        }
        if(s1.equals("Filter: Distinct Values"))
            catalogviewdefimpl.setViewObjectClass("oracle.apps.icx.icatalog.shopping.server.DistinctFilterValuesVOImpl");
        else
        if(s1.equals("Favorite List Item"))
            catalogviewdefimpl.setViewObjectClass("oracle.apps.icx.icatalog.common.server.CatalogViewObjectImpl");
        else
            catalogviewdefimpl.setViewObjectClass("oracle.apps.fnd.framework.server.OAViewObjectImpl");
        catalogviewdefimpl.setViewRowClass("oracle.apps.fnd.framework.server.OAViewRowImpl");
        catalogviewdefimpl.setFullSql(false);
        catalogviewdefimpl.setSelectClause(s4);
        catalogviewdefimpl.setFromClause(s6);
        catalogviewdefimpl.setWhereClause(s7);
        catalogviewdefimpl.setOrderByClause(null);
        catalogviewdefimpl.setQueryHint(constructHintClause(categoryelement, categoryelement1, buildercontext, oaapplicationmoduleimpl));
        catalogviewdefimpl.setFetchSize((short)11);
        catalogviewdefimpl.resolveDefObject();
        OAViewObjectImpl oaviewobjectimpl = (OAViewObjectImpl)oaapplicationmoduleimpl.findViewObject(s);
        if(oaviewobjectimpl != null)
        oaviewobjectimpl.remove();
		OAViewObjectImpl oaviewobjectimpl1;
		oaviewobjectimpl1 = (OAViewObjectImpl)oaapplicationmoduleimpl.createViewObject(s,(OAViewDef)catalogviewdefimpl);
        return oaviewobjectimpl1;
    }

    protected String constructKey(BuilderContext buildercontext, OAApplicationModuleImpl oaapplicationmoduleimpl)
    {
        int i = 0;
        Boolean boolean1 = (Boolean)buildercontext.getParameter("Include Category Descriptors");
        if(Boolean.TRUE.equals(boolean1))
        {
            String s = (String)buildercontext.getParameter("Category Id");
            if(s != null)
                i = Integer.parseInt(s);
        }
        OADBTransaction oadbtransaction = oaapplicationmoduleimpl.getOADBTransaction();
        String s1 = oadbtransaction.getProfile("POR_APPROVED_PRICING_ONLY");
        s1.equals("Y");
        String s2 = String.valueOf(oadbtransaction.getEmployeeId());
        String s3 = ((ShoppingAMImpl)oaapplicationmoduleimpl).getItemSourceSetting(s2);
        String s4 = String.valueOf(oadbtransaction.getResponsibilityId());
        String s5 = ((ShoppingAMImpl)oaapplicationmoduleimpl).isCategoryRealmsEnabled(s4);
        String s6 = (String)oadbtransaction.getValue("sortBy");
        String s7 = (String)oadbtransaction.getValue("sortOrder");
        String s8 = "";
        if("Relevance".equals(s6))
            s8 = s6 + "#" + s7;
        return Integer.toString(i) + "#" + s1 + "#" + s3 + "#" + s5 + "#" + s8;
    }

    protected String constructWhereClauseForFavoriteItem(CategoryElement categoryelement, CategoryElement categoryelement1, BuilderContext buildercontext, OAApplicationModuleImpl oaapplicationmoduleimpl)
    {
        OADBTransaction oadbtransaction = oaapplicationmoduleimpl.getOADBTransaction();
        String s = String.valueOf(oadbtransaction.getResponsibilityId());
        String s1 = ((ShoppingAMImpl)oaapplicationmoduleimpl).isCategoryRealmsEnabled(s);
        boolean flag = s1.equals("Y");
        StringBuffer stringbuffer = new StringBuffer(3500);
        stringbuffer.append("POR_FAVORITE_LIST_HEADERS.employee_id = :");
        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        stringbuffer.append(" and POR_FAVORITE_LIST_HEADERS.favorite_list_id = ");
        stringbuffer.append("POR_FAVORITE_LIST_LINES.favorite_list_id ");
        stringbuffer.append(" and POR_FAVORITE_LIST_LINES.rt_item_id is not null and POR_FAVORITE_LIST_LINES.rt_item_id = ICX_CAT_ITEMS_TLP.rt_item_id ");
        stringbuffer.append(" and ICX_CAT_ITEMS_TLP.rt_item_id = ICX_CAT_ITEM_PRICES.rt_item_id  and ICX_CAT_ITEM_PRICES.active_flag = 'Y' ");
        stringbuffer.append(" and ICX_CAT_ITEMS_TLP.language = :");
        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        stringbuffer.append(" and ICX_CAT_ITEM_PRICES.org_id in (-2, :");
        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        stringbuffer.append(") ");
        stringbuffer.append(" and ((POR_FAVORITE_LIST_LINES.price_list_id is null and ICX_CAT_ITEM_PRICES.price_list_id is null ");
        stringbuffer.append(" and ((POR_FAVORITE_LIST_LINES.SOURCE_DOC_HEADER_ID = ICX_CAT_ITEM_PRICES.contract_id ");
        stringbuffer.append(" and POR_FAVORITE_LIST_LINES.SOURCE_DOC_LINE_ID = ICX_CAT_ITEM_PRICES.contract_line_id) ");
        stringbuffer.append("  or (POR_FAVORITE_LIST_LINES.SOURCE_DOC_HEADER_ID is null and POR_FAVORITE_LIST_LINES.TEMPLATE_NAME = ICX_CAT_ITEM_PRICES.template_id ");
        stringbuffer.append(" and POR_FAVORITE_LIST_LINES.TEMPLATE_LINE_NUM = ICX_CAT_ITEM_PRICES.template_line_id) ");
        stringbuffer.append("  or (POR_FAVORITE_LIST_LINES.SOURCE_DOC_HEADER_ID is null and POR_FAVORITE_LIST_LINES.TEMPLATE_NAME is null ");
        stringbuffer.append(" and POR_FAVORITE_LIST_LINES.asl_id = ICX_CAT_ITEM_PRICES.asl_id) ");
        stringbuffer.append("  or (POR_FAVORITE_LIST_LINES.SOURCE_DOC_HEADER_ID is null and POR_FAVORITE_LIST_LINES.TEMPLATE_NAME is null ");
        stringbuffer.append(" and POR_FAVORITE_LIST_LINES.asl_id is null and POR_FAVORITE_LIST_LINES.item_id = ICX_CAT_ITEM_PRICES.inventory_item_id)) ) ");
        stringbuffer.append("  or  (POR_FAVORITE_LIST_LINES.price_list_id = ICX_CAT_ITEM_PRICES.price_list_id and ");
        stringbuffer.append("   POR_FAVORITE_LIST_LINES.suggested_vendor_site_id = ICX_CAT_ITEM_PRICES.supplier_site_id) ) ");
        stringbuffer.append("  and ICX_CAT_ITEM_PRICES.search_type = decode(:");
        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        stringbuffer.append(", 'BOTH', ICX_CAT_ITEMS_TLP.search_type, :");
        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        stringbuffer.append(") ");
        stringbuffer.append("  and ICX_CAT_ITEM_PRICES.unit_of_measure = MTL_UNITS_OF_MEASURE_TL.uom_code(+) and MTL_UNITS_OF_MEASURE_TL.language(+) = :");
        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        if(flag)
            stringbuffer.append(constructRealmForWhereClause());
        stringbuffer.append(" UNION ALL ");
        stringbuffer.append(" SELECT ");
        String s2 = constructNonCatalogQuery(categoryelement, categoryelement1, buildercontext, oaapplicationmoduleimpl);
        stringbuffer.append(s2);
        stringbuffer.append(" FROM POR_FAVORITE_LIST_HEADERS, POR_FAVORITE_LIST_LINES, ");
        stringbuffer.append("MTL_CATEGORIES_KFV, PO_LINE_TYPES,MTL_UNITS_OF_MEASURE_TL");
        stringbuffer.append(" WHERE POR_FAVORITE_LIST_HEADERS.employee_id = :");
        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        stringbuffer.append(" and POR_FAVORITE_LIST_HEADERS.favorite_list_id = POR_FAVORITE_LIST_LINES.favorite_list_id and POR_FAVORITE_LIST_LINES.rt_item_id is null ");
        stringbuffer.append(" and POR_FAVORITE_LIST_LINES.category_id = MTL_CATEGORIES_KFV.category_id(+) ");
        stringbuffer.append(" and POR_FAVORITE_LIST_LINES.line_type_id = PO_LINE_TYPES.line_type_id ");
        stringbuffer.append(" and POR_FAVORITE_LIST_LINES.UNIT_MEAS_LOOKUP_CODE = MTL_UNITS_OF_MEASURE_TL.unit_of_measure(+) and MTL_UNITS_OF_MEASURE_TL.language(+) = :");
        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        return stringbuffer.toString();
    }

    protected String constructWhereClauseForPublicListItem(CategoryElement categoryelement, CategoryElement categoryelement1, BuilderContext buildercontext, OAApplicationModuleImpl oaapplicationmoduleimpl)
    {
        StringBuffer stringbuffer = new StringBuffer(3500);
        OADBTransaction oadbtransaction = oaapplicationmoduleimpl.getOADBTransaction();
        String s = String.valueOf(oadbtransaction.getEmployeeId());
        String s1 = ((ShoppingAMImpl)oaapplicationmoduleimpl).getItemSourceSetting(s);
        String s2 = String.valueOf(oadbtransaction.getResponsibilityId());
        String s3 = ((ShoppingAMImpl)oaapplicationmoduleimpl).isCategoryRealmsEnabled(s2);
        boolean flag = s3.equals("Y");
        stringbuffer.append("ICX_CAT_ITEMS_TLP");
        stringbuffer.append(".rt_item_id = ");
        stringbuffer.append("ICX_CAT_ITEM_PRICES");
        stringbuffer.append(".rt_item_id");
        stringbuffer.append(" AND ");
        stringbuffer.append("ICX_CAT_ITEMS_TLP");
        stringbuffer.append(".language = :");
        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        stringbuffer.append(" AND ");
        stringbuffer.append("ICX_CAT_ITEM_PRICES");
        stringbuffer.append(".template_id = :");
        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        stringbuffer.append(" AND ");
        stringbuffer.append("ICX_CAT_ITEM_PRICES");
        stringbuffer.append(".org_id = :");
        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        if("SUPPLIER".equals(s1) || "INTERNAL".equals(s1))
        {
            stringbuffer.append(" AND ");
            stringbuffer.append("ICX_CAT_ITEM_PRICES");
            stringbuffer.append(".search_type = :");
            stringbuffer.append(super.m_bindIndex);
            super.m_bindIndex++;
        }
        stringbuffer.append(" AND ");
        stringbuffer.append("ICX_CAT_ITEM_PRICES");
        stringbuffer.append(".unit_of_measure = ");
        stringbuffer.append("MTL_UNITS_OF_MEASURE_TL");
        stringbuffer.append(".uom_code(+)");
        stringbuffer.append(" AND ");
        stringbuffer.append("MTL_UNITS_OF_MEASURE_TL");
        stringbuffer.append(".language(+) = :");
        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        if(flag)
            stringbuffer.append(constructRealmForWhereClause());
        return stringbuffer.toString();
    }

    protected String constructRealmForWhereClause()
    {
        StringBuffer stringbuffer = new StringBuffer(2000);
        stringbuffer.append(" AND (EXISTS ( SELECT 1");
        stringbuffer.append(" FROM  ak_resp_security_attr_values arsav");
        stringbuffer.append(" WHERE arsav.attribute_application_id = :");
        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        stringbuffer.append(" AND   arsav.responsibility_id = :");
        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        stringbuffer.append(" AND   arsav.attribute_code = :");
        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        stringbuffer.append(" AND ");
        stringbuffer.append("ICX_CAT_ITEMS_TLP");
        stringbuffer.append(".primary_category_id = arsav.number_value)");
        stringbuffer.append(" OR EXISTS (SELECT 2");
        stringbuffer.append(" FROM  ak_resp_security_attr_values arsav,");
        stringbuffer.append(" icx_por_realms ipr, icx_por_realm_components iprc");
        stringbuffer.append(" WHERE arsav.attribute_application_id = :");
        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        stringbuffer.append("  AND   arsav.responsibility_id = :");
        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        stringbuffer.append("  AND   arsav.attribute_code = :");
        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        stringbuffer.append("  AND   ipr.realm_id = arsav.number_value");
        stringbuffer.append("  AND   ipr.ak_attribute_code = :");
        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        stringbuffer.append("  AND   ipr.realm_id = iprc.realm_id");
        stringbuffer.append("  AND   iprc.realm_component_value = ");
        stringbuffer.append("ICX_CAT_ITEMS_TLP");
        stringbuffer.append(".primary_category_id)");
        stringbuffer.append("  OR EXISTS (SELECT 3");
        stringbuffer.append("  FROM   ak_web_user_sec_attr_values awusav");
        stringbuffer.append("  WHERE awusav.attribute_application_id = :");
        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        stringbuffer.append("  AND awusav.web_user_id = :");
        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        stringbuffer.append("  AND awusav.attribute_code = :");
        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        stringbuffer.append("  AND ");
        stringbuffer.append("ICX_CAT_ITEMS_TLP");
        stringbuffer.append(".primary_category_id = awusav.number_value)");
        stringbuffer.append("  OR EXISTS(SELECT 4");
        stringbuffer.append("  FROM   ak_web_user_sec_attr_values awusav,");
        stringbuffer.append("  icx_por_realms ipr, icx_por_realm_components iprc");
        stringbuffer.append("  WHERE awusav.attribute_application_id = :");
        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        stringbuffer.append("  AND   awusav.web_user_id = :");
        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        stringbuffer.append("  AND   awusav.attribute_code = :");
        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        stringbuffer.append("  AND   ipr.realm_id = awusav.number_value");
        stringbuffer.append("  AND   ipr.ak_attribute_code = :");
        stringbuffer.append(super.m_bindIndex);
        super.m_bindIndex++;
        stringbuffer.append("  AND   ipr.realm_id = iprc.realm_id");
        stringbuffer.append("  AND   iprc.realm_component_value = ");
        stringbuffer.append("ICX_CAT_ITEMS_TLP");
        stringbuffer.append(".primary_category_id");
        stringbuffer.append("  ))");
        return stringbuffer.toString();
    } 

    public ShoppingSearchVOBuilder()
    {
    }

    public static final String RCS_ID = "$Header: ShoppingSearchVOBuilder.java 115.21 2004/07/09 17:05:45 vkartik ship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: ShoppingSearchVOBuilder.java 115.21 2004/07/09 17:05:45 vkartik ship $", "oracle.apps.icx.icatalog.shopping.server");

}
