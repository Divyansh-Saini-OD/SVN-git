/*===========================================================================+
 |   Copyright (c) 2001, 2003 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 |    - copied from oracle.apps.imc.three_sixty.webui.DynamicTableCO
 |      to fix Account Number --> Billing Number change   
 |      see line # 202 (label change fix)
 +===========================================================================*/
package od.oracle.apps.xxcrm.imc.three_sixty.webui;

import com.sun.java.util.collections.HashMap;
import java.io.Serializable;
import java.util.Enumeration;
import java.util.Vector;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.*;
import oracle.apps.fnd.framework.server.*;
import oracle.apps.fnd.framework.webui.*;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.layout.*;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.cabo.ui.beans.BaseWebBean;
import oracle.cabo.ui.beans.layout.CellFormatBean;
import oracle.cabo.ui.beans.layout.TableLayoutBean;
import oracle.cabo.ui.data.DictionaryData;
import oracle.jbo.*;
import oracle.jbo.server.ApplicationModuleImpl;
import oracle.jdbc.driver.OracleConnection;
import oracle.apps.imc.three_sixty.webui.ThreeSixtyControllerImpl;

public class ODDynamicTableCO extends ThreeSixtyControllerImpl
{
    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processRequest(oapagecontext, oawebbean);
        boolean flag = false;
        String s = "";
        Object obj = null;
        Object obj1 = null;
        String s2 = "";
        boolean flag1 = false;
        String s4 = "";
        String s6 = "";
        String s7 = "";
        boolean flag2 = false;
        String s8 = oapagecontext.getParameter("QUERY_ID");
        String s9 = oapagecontext.getParameter("TxnPageTitle");
        String s10 = oapagecontext.getParameter("ImcTxnBeCode");
        if(s10 == null || s10.length() == 0 || s10.equals("IMC_TXN_BE_PARTY"))
        {
            s10 = "IMC_TXN_BE_PARTY";
            s6 = oapagecontext.getParameter("ImcPartyId");
            s7 = oapagecontext.getParameter("ImcPartyName");
            oapagecontext.putParameter("ImcPartyName", s7);
            oapagecontext.putParameter("ImcTxnBeCode", s10);
            s9 = s7;
        }
        DictionaryData dictionarydata = new DictionaryData();
        if(s10.equals("IMC_TXN_BE_PARTY"))
        {
            dictionarydata.put("ImcPartyId", s6);
            dictionarydata.put("ImcPartyName", s7);
        }
        dictionarydata.put("ImcTxnBeCode", s10);
        oapagecontext.setFunctionParameterDataObject(dictionarydata);
        OAApplicationModuleImpl oaapplicationmoduleimpl = (OAApplicationModuleImpl)oapagecontext.getApplicationModule(oawebbean);
        OADBTransaction oadbtransaction = oapagecontext.getApplicationModule(oawebbean).getOADBTransaction();
        OracleConnection _tmp = (OracleConnection)oadbtransaction.getJdbcConnection();
        OAHeaderBean oaheaderbean = (OAHeaderBean)oawebbean.findIndexedChildRecursive("mainHeader");
        OATableLayoutBean oatablelayoutbean = (OATableLayoutBean)oawebbean.findIndexedChildRecursive("tableLayout");
        oaheaderbean.setLabel(s9 + ": " + oaheaderbean.getLabel());
        oaheaderbean.setCSSClass("OraHeaderSub");
        oaheaderbean.setLabelCSSClassName("OraHeaderSub");
        OAMessageChoiceBean oamessagechoicebean = (OAMessageChoiceBean)oawebbean.findIndexedChildRecursive("productsPickList");
        OASubmitButtonBean oasubmitbuttonbean = (OASubmitButtonBean)oawebbean.findIndexedChildRecursive("listViewBtn");
        OASpacerRowBean oaspacerrowbean = (OASpacerRowBean)createWebBean(oapagecontext, "SPACER_ROW");
        if(s8 != null)
        {
            oawebbean.findIndexedChildRecursive("instructionText").setRendered(false);
            oamessagechoicebean.setSelectionValue(oapagecontext, s8);
        } else
        {
            oawebbean.findIndexedChildRecursive("instructionText").setRendered(true);
            oasubmitbuttonbean.setRendered(false);
        }
        Serializable aserializable[] = {
            s8, s10
        };
        OAViewObject oaviewobject1 = (OAViewObject)oaapplicationmoduleimpl.findViewObject("ThreeSixtyQueryVO");
        oaapplicationmoduleimpl.invokeMethod("initQueryHeader", aserializable);
        OAViewObject oaviewobject2 = (OAViewObject)oaapplicationmoduleimpl.findViewObject("ProductsPickListVO");
        oaviewobject2.setWhereClauseParam(0, s10);
        if(oaviewobject1 == null)
        {
            MessageToken amessagetoken[] = {
                new MessageToken("VIEW_NAME", "ThreeSixtyQueryVO")
            };
            throw new OAException(oapagecontext.getMessage("IMC", "IMC_THREE_SIXTY_VO_NOT_OK", amessagetoken), (byte)0);
        }
        oaviewobject1.reset();
        while(oaviewobject1.hasNext()) 
        {
            oracle.jbo.Row row = oaviewobject1.next();
            String s11 = (String)row.getAttribute("SecurityFunction");
            boolean flag3;
            if(s11 != null)
            {
                if(oapagecontext.testFunction(s11))
                    flag3 = true;
                else
                    flag3 = false;
            } else
            {
                flag3 = true;
            }
            if(flag3)
            {
                String s12 = row.getAttribute("QueryId").toString();
                if(Integer.parseInt(s12) < Integer.parseInt("999"))
                {
                    String s13 = (String)row.getAttribute("TransactionName");
                    String _tmp1 = (String)row.getAttribute("HeaderText");
                    int l = Integer.parseInt(row.getAttribute("FilterCount").toString());
                    String s14 = (String)row.getAttribute("QueryTypeFlag");
                    String s15 = getTrxQueryString(row);
                    HashMap hashmap = (HashMap)getQueryParamValues(oapagecontext, oawebbean, s12, s14);
                    if(s8 != null)
                        renderFilters(oapagecontext, oawebbean, s12, l);
                    OAViewDef oaviewdef = createViewDef(oaapplicationmoduleimpl);
                    oaviewdef.setSql(s15);
                    String s1 = "DynamicVO" + s12;
                    OAViewObject oaviewobject = (OAViewObject)oaapplicationmoduleimpl.findViewObject(s1);
                    if(oaviewobject != null)
                        oaviewobject.remove();
                    oaapplicationmoduleimpl.createViewObject(s1, oaviewdef);
                    oaviewobject = (OAViewObject)oaapplicationmoduleimpl.findViewObject(s1);
                    int i1 = hashmap.size();
                    String s16 = "";
                    if(i1 > 0)
                    {
                        for(int k = 0; k < i1; k++)
                        {
                            String s17 = Integer.toString(k);
                            String _tmp2 = (String)hashmap.get(s17);
                            oaviewobject.setWhereClauseParam(k, hashmap.get(s17));
                        }

                    }
                    oaviewobject.setMaxFetchSize(-1);
                    if(oaviewobject == null)
                    {
                        MessageToken amessagetoken1[] = {
                            new MessageToken("VIEW_NAME", s1)
                        };
                        throw new OAException(oapagecontext.getMessage("IMC", "IMC_THREE_SIXTY_VO_NOT_OK", amessagetoken1), (byte)0);
                    }
                    HashMap hashmap1 = new HashMap();
                    int i = 0;
                    hashmap1 = getColDetails(oapagecontext, oawebbean, s12);
                    i = Integer.parseInt((String)hashmap1.get("mTotalCols"));
                    String s3 = "/oracle/apps/imc/three_sixty/webui/TABLETEMPLATE" + i;
                    OAWebBean oawebbean1 = getHeaderBean(oapagecontext, "header" + s12, s13);
                    oatablelayoutbean.addIndexedChild(oawebbean1);
                    OATableLayoutBean oatablelayoutbean1 = (OATableLayoutBean)createWebBean(oapagecontext, "TABLE_LAYOUT");
                    oatablelayoutbean1.setWidth("100%");
                    oatablelayoutbean1.setHAlign("end");
                    oawebbean1.addIndexedChild(oatablelayoutbean1);
                    OACellFormatBean oacellformatbean = (OACellFormatBean)createWebBean(oapagecontext, "CELL_FORMAT");
                    OACellFormatBean oacellformatbean1 = (OACellFormatBean)createWebBean(oapagecontext, "CELL_FORMAT");
                    oatablelayoutbean1.addIndexedChild(oacellformatbean);
                    oatablelayoutbean1.addIndexedChild(oacellformatbean1);
                    oacellformatbean1.setHAlign("end");
                    OATableBean oatablebean = createTable(oapagecontext, oawebbean, s1, s3);
                    oacellformatbean1.addIndexedChild(oatablebean);
                    oatablelayoutbean1.addIndexedChild(oaspacerrowbean);
                    oatablelayoutbean1.addIndexedChild(oaspacerrowbean);
                    if(s8 == null)
                    {
                        oatablebean.setNumberOfRowsDisplayed(5);
                        oatablebean.setTableNavigationDisplayed(false);
                    } else
                    {
                        oatablebean.setNumberOfRowsDisplayed(30);
                        oatablebean.setTableNavigationDisplayed(true);
                    }
                    for(int j = 1; j <= i; j++)
                    {
                        String s5 = "column" + j;
                        OAMessageStyledTextBean oamessagestyledtextbean = (OAMessageStyledTextBean)oatablebean.findIndexedChildRecursive("col" + j);
                        oamessagestyledtextbean.setID(s5);
                        if(hashmap1.get("mColumnDataType" + j).equals("NUMBER"))
                            oamessagestyledtextbean.setDataType("NUMBER");
                        if(hashmap1.get("mSortFlag" + j).equals("Y"))
                            oamessagestyledtextbean.setSortable(true);
                        String _tmp3 = (String)hashmap1.get("mColumnLabel" + j);

//---- label change fix
            if ("Account Number".equalsIgnoreCase(_tmp3)) {
                oamessagestyledtextbean.setLabel("Billing Number");     
            } else {
                        oamessagestyledtextbean.setLabel((String)hashmap1.get("mColumnLabel" + j));
            }
                        oamessagestyledtextbean.setLabelCSSClassName("OraTableColumnHeader");
                        MapSqlAttr(oaviewdef, "Column" + j, "COLUMN" + j, "VARCHAR");
                    }

                    oaviewobject.executeQuery();
                    oatablebean.prepareForRendering(oapagecontext);
                    if(s8 == null)
                    {
                        Serializable aserializable1[] = {
                            s10
                        };
                        Vector vector = new Vector();
                        vector = (Vector)oaapplicationmoduleimpl.invokeMethod("getParamNames", aserializable1);
                        oracle.apps.fnd.framework.webui.beans.layout.OARowLayoutBean oarowlayoutbean = moreButtonLayout(oapagecontext, oatablelayoutbean, s12, vector);
                        oatablelayoutbean1.addIndexedChild(oarowlayoutbean);
                        oatablelayoutbean1.addIndexedChild(oaspacerrowbean);
                        oatablelayoutbean1.addIndexedChild(oaspacerrowbean);
                        oatablelayoutbean1.addIndexedChild(oaspacerrowbean);
                        oatablelayoutbean1.addIndexedChild(oaspacerrowbean);
                    }
                    OAPageLayoutBean oapagelayoutbean = oapagecontext.getPageLayoutBean();
                    oapagelayoutbean.prepareForRendering(oapagecontext);
                }
            }
        }
    }

    public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        HashMap hashmap = new HashMap();
        int i = 0;
        boolean flag = false;
        String s = "";
        String s2 = "";
        String s3 = "";
        super.processFormRequest(oapagecontext, oawebbean);
        OAApplicationModuleImpl oaapplicationmoduleimpl = (OAApplicationModuleImpl)oapagecontext.getApplicationModule(oawebbean);
        Object obj = null;
        String s5 = "";
        Object obj1 = null;
        String s8 = oapagecontext.getParameter("QUERY_ID");
        HashMap hashmap1 = new HashMap();
        String s9 = oapagecontext.getParameter("btnStatus");
        hashmap1.put("ImcPartyId", oapagecontext.getParameter("ImcPartyId"));
        hashmap1.put("ImcPartyName", oapagecontext.getParameter("ImcPartyName"));
        hashmap1.put("ImcTxnBeCode", oapagecontext.getParameter("ImcTxnBeCode"));
        if("ALL".equals(s9))
        {
            hashmap1.put("QUERY_ID", null);
            oapagecontext.forwardImmediatelyToCurrentPage(hashmap1, false, "Y");
            return;
        }
        if("ONE".equals(s9))
        {
            String s7 = oapagecontext.getParameter("productsPickList");
            if(s7 == null || s7.equals("") || s7.equals("999"))
                hashmap1.put("QUERY_ID", null);
            else
                hashmap1.put("QUERY_ID", s7);
            oapagecontext.forwardImmediatelyToCurrentPage(hashmap1, false, "Y");
            return;
        }
        if(oapagecontext.getParameter("filterBtn") != null)
        {
            for(Enumeration enumeration = oapagecontext.getParameterNames(); enumeration.hasMoreElements();)
            {
                String s10 = (String)enumeration.nextElement();
                if(s10.length() > 7 && s10.substring(0, 7).equals("FILTER_"))
                {
                    String s15 = oawebbean.findIndexedChildRecursive(s10).getStyle();
                    String s16 = oapagecontext.getParameter(s10);
                    if(s16 != null && !s16.equals(""))
                    {
                        String s6 = s10.substring(7);
                        i++;
                        hashmap.put("FilterName" + i, s6);
                        hashmap.put("FilterValue" + i, s16);
                        hashmap.put("FilterStyle" + i, s15);
                    }
                }
            }

            for(int j = 1; j <= i; j++)
            {
                String s4 = "";
                String s1;
                if(j == 1)
                    s1 = "";
                else
                    s1 = " AND";
                s4 = (String)hashmap.get("FilterName" + j);
                String s11 = "";
                if(hashmap.get("FilterStyle" + j).equals("MESSAGE_DATE_FIELD") || hashmap.get("FilterStyle" + j).equals("MESSAGE_TEXT_INPUT"))
                    if(s4.substring(0, 2).equalsIgnoreCase("FR"))
                    {
                        String s12 = s4.substring(2);
                        s2 = s2 + s1 + " " + s12 + "  >= '" + hashmap.get("FilterValue" + j) + "'";
                    } else
                    if(s4.substring(0, 2).equalsIgnoreCase("TO"))
                    {
                        String s13 = s4.substring(2);
                        s2 = s2 + s1 + " " + s13 + "  <= '" + hashmap.get("FilterValue" + j) + "'";
                    } else
                    {
                        String s14 = s4;
                        s2 = s2 + s1 + " " + s4 + "  LIKE '" + hashmap.get("FilterValue" + j) + "%'";
                    }
                if(hashmap.get("FilterStyle" + j).equals("MESSAGE_POPLIST"))
                    s2 = s2 + s1 + " " + s4 + "  = '" + hashmap.get("FilterValue" + j) + "'";
            }

            OAViewObject oaviewobject = (OAViewObject)oaapplicationmoduleimpl.findViewObject("DynamicVO" + s8);
            oaviewobject.setWhereClause(s2);
            oaviewobject.executeQuery();
        }
    }

    public ODDynamicTableCO()
    {
    }

    public static final String RCS_ID = "$Header: ODDynamicTableCO.java 115.22 2004/12/20 22:40:13 smattegu noship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: ODDynamicTableCO.java 115.22 2004/12/20 22:40:13 smattegu noship $", "oracle.apps.imc.three_sixty.webui");

}
