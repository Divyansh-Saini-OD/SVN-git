/*===========================================================================+
 |   Copyright (c) 2001, 2003 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 |    - copied from oracle.apps.imc.customer.account.webui.IMCAccountOverviewCO
 |      to fix Account Number --> Billing Number change   
 |      see line # 80 (label change fix)
 +===========================================================================*/
package od.oracle.apps.xxcrm.imc.customer.account.webui;

import com.sun.java.util.collections.HashMap;
import java.io.Serializable;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.webui.*;
import oracle.apps.fnd.framework.webui.beans.OAStaticStyledTextBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.nav.OAButtonBean;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.cabo.ui.UIConstants;
import oracle.cabo.ui.beans.StyledTextBean;
import oracle.cabo.ui.beans.layout.PageLayoutBean;
import oracle.cabo.ui.beans.nav.LinkBean;
import oracle.cabo.ui.beans.table.TableBean;
import oracle.cabo.ui.beans.table.TableStyle;
import oracle.cabo.ui.data.DataObjectList;
import oracle.cabo.ui.data.DictionaryData;
import oracle.jbo.AttributeList;
import oracle.jbo.RowIterator;
import oracle.jbo.server.ApplicationModuleImpl;


public class ODIMCAccountOverviewCO extends OAControllerImpl
{

    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processRequest(oapagecontext, oawebbean);
        String s = null;
        String s1 = null;
        String s2 = null;
        String s3 = null;
        String s4 = null;
        String s6 = oapagecontext.getParameter("cmReturnFrom");
        oapagecontext.getParameter("ImcCMSumPage");
        OAApplicationModuleImpl oaapplicationmoduleimpl = (OAApplicationModuleImpl)oapagecontext.getApplicationModule(oawebbean);
        if(s6 != null && !"".equals(s6.trim()) && s6.equals("CM"))
        {
            s2 = oapagecontext.getParameter("cmPartyId");
            s3 = OAUrl.decode(oapagecontext, oapagecontext.getParameter("cmPartyName"));
            s1 = oapagecontext.getParameter("cmCustAccountId");
        } else
        {
            s1 = oapagecontext.getParameter("ImcAcctId");
            s2 = oapagecontext.getParameter("ImcPartyId");
            s3 = oapagecontext.getParameter("ImcPartyName");
            s4 = oapagecontext.getParameter("ImcAcctNum");
        }
        oapagecontext.getPageLayoutBean().prepareForRendering(oapagecontext);
        oapagecontext.getPageLayoutBean().setStart(null);
        String s7 = s3;
        if(s4 != null && !"".equals(s4.trim()))
        {
            s7 = s7 + " (#" + s4 + ")";
        } else
        {
            Serializable aserializable[] = {
                s1
            };
            String s5 = (String)oaapplicationmoduleimpl.invokeMethod("getCustAccountNumber", aserializable);
            s7 = s7 + " (#" + s5 + ")";
        }
        oapagecontext.getPageLayoutBean().setTitle(oapagecontext.getPageLayoutBean().getTitle() + s7);
        String s8 = ((OAStaticStyledTextBean)oawebbean.findIndexedChildRecursive("partyName")).getText();
        String s9 = ((OAStaticStyledTextBean)oawebbean.findIndexedChildRecursive("accountNumber")).getText();

//---- label change fix
OAStaticStyledTextBean oacustbean = ((OAStaticStyledTextBean)oawebbean.findIndexedChildRecursive("accountNumber"));
oacustbean.setLabel("Billing Number");

        String s10 = ((OAStaticStyledTextBean)oawebbean.findIndexedChildRecursive("accountName")).getText();
        String s11 = ((OAStaticStyledTextBean)oawebbean.findIndexedChildRecursive("status")).getText();
        String s12 = ((OAStaticStyledTextBean)oawebbean.findIndexedChildRecursive("duns")).getText();
        String s13 = ((OAStaticStyledTextBean)oawebbean.findIndexedChildRecursive("taxpayerId")).getText();
        String s14 = ((OAStaticStyledTextBean)oawebbean.findIndexedChildRecursive("creationDate")).getText();
        String s15 = ((OAStaticStyledTextBean)oawebbean.findIndexedChildRecursive("taxRegistrationNumber")).getText();
        String s16 = ((OAStaticStyledTextBean)oawebbean.findIndexedChildRecursive("collector")).getText();
        String s17 = ((OAStaticStyledTextBean)oawebbean.findIndexedChildRecursive("salesperson")).getText();
        String s18 = ((OAStaticStyledTextBean)oawebbean.findIndexedChildRecursive("profileClass")).getText();
        String s19 = ((OAStaticStyledTextBean)oawebbean.findIndexedChildRecursive("paymentTerms")).getText();
        String s20 = ((OAStaticStyledTextBean)oawebbean.findIndexedChildRecursive("primaryAddress")).getText();
        String s21 = ((OAStaticStyledTextBean)oawebbean.findIndexedChildRecursive("primaryAccountContact")).getText();
        Serializable aserializable1[] = {
            s1, s8, s9, s10, s11, s12, s13, s14, s15, s16, 
            s17, s18, s19, s20, s21
        };
        OAButtonBean oabuttonbean = (OAButtonBean)oawebbean.findIndexedChildRecursive("ACM");
        Serializable aserializable2[] = {
            s2, s1, "-99"
        };
        OAViewObject oaviewobject = (OAViewObject)oaapplicationmoduleimpl.findViewObject("IMCAccountCMSVO1");
        oaviewobject.invokeMethod("initQuery", aserializable2);
        oracle.jbo.Row row = oaviewobject.first();
        if(row != null)
            s = (String)row.getAttribute("Cms");
        if(s.equals("N"))
            oabuttonbean.setDisabled(true);
        oaapplicationmoduleimpl.invokeMethod("initCustAccountDumpQuery", aserializable1);
        OATableBean oatablebean = (OATableBean)oawebbean.findIndexedChildRecursive("IMCCustAccountDumpTable");
        oatablebean.setTableFormat(TableStyle.getColumnBandingFormat());
        oatablebean.prepareForRendering(oapagecontext);
        oatablebean.setColumnHeaderStamp(null);
        DataObjectList dataobjectlist = oatablebean.getColumnFormats();
        DictionaryData dictionarydata = (DictionaryData)dataobjectlist.getItem(oapagecontext.findChildIndex(oatablebean, "Col1"));
        dictionarydata.put("width", "20%");
        dictionarydata.put("columnDataFormat", "numberFormat");
        DictionaryData dictionarydata1 = (DictionaryData)dataobjectlist.getItem(oapagecontext.findChildIndex(oatablebean, "Col2"));
        dictionarydata1.put("width", "30%");
        dictionarydata1.put("columnDataFormat", "textFormat");
        DictionaryData dictionarydata2 = (DictionaryData)dataobjectlist.getItem(oapagecontext.findChildIndex(oatablebean, "Col3"));
        dictionarydata2.put("width", "30%");
        dictionarydata2.put("columnDataFormat", "numberFormat");
        DictionaryData dictionarydata3 = (DictionaryData)dataobjectlist.getItem(oapagecontext.findChildIndex(oatablebean, "Col4"));
        dictionarydata3.put("width", "20%");
        dictionarydata3.put("columnDataFormat", "textFormat");
        String s22 = "A";
        Serializable aserializable3[] = {
            s1, s22
        };
        oaapplicationmoduleimpl.invokeMethod("initCustAccountSitesQuery", aserializable3);
        Serializable aserializable4[] = {
            s1, "", s22
        };
        oaapplicationmoduleimpl.invokeMethod("initCustAccountContactQuery", aserializable4);
        oaapplicationmoduleimpl.invokeMethod("initCustAccountRelationshipQuery", aserializable3);
    }

    public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processFormRequest(oapagecontext, oawebbean);
        HashMap hashmap = new HashMap();
        Object obj = null;
        String s10 = null;
        String s11 = null;
        String s12 = null;
        String s13 = "";
        String s15 = oapagecontext.getParameter("cmReturnFrom");
        if(s15 != null && !"".equals(s15.trim()) && s15.equals("CM"))
        {
            s11 = oapagecontext.getParameter("cmPartyId");
            s12 = OAUrl.decode(oapagecontext, oapagecontext.getParameter("cmPartyName"));
            s10 = oapagecontext.getParameter("cmCustAccountId");
        } else
        {
            s10 = oapagecontext.getParameter("ImcAcctId");
            s11 = oapagecontext.getParameter("ImcPartyId");
            s12 = oapagecontext.getParameter("ImcPartyName");
            String s14 = oapagecontext.getParameter("ImcAcctNum");
        }
        hashmap.put("ImcPartyId", s11);
        hashmap.put("ImcAcctId", s10);
        String s16 = oapagecontext.getParameter("returnParam");
        String s17 = oapagecontext.getParameter("viewSiteDetails");
        String s18 = oapagecontext.getParameter("viewInactive");
        String s19 = oapagecontext.getParameter("viewPurpose");
        String s20 = oapagecontext.getParameter("viewContactRoles");
        String s21 = oapagecontext.getParameter("viewInactiveContact");
        String s22 = oapagecontext.getParameter("viewInactiveRel");
        String s23 = oapagecontext.getParameter("viewSiteContactsRole");
        String s24 = oapagecontext.getParameter("viewAccountCMS");
        String s25 = oapagecontext.getParameter("viewSiteCMS");
        if(s16 != null && !"".equals(s16.trim()))
        {
            String s = "IMC_AU_CUST_ACCOUNTS_EDIT";
            hashmap.put("ImcPartyName", s12);
            hashmap.put("ImcGenPartyId", s11);
            hashmap.put("ImcGenPartyName", s12);
            oapagecontext.forwardImmediately(s, (byte)0, "IMC_NG_CUST", hashmap, false, "Y");
        }
        if(s17 != null && !"".equals(s17.trim()))
        {
            hashmap.put("ImcPartyName", s12);
            hashmap.put("ImcAccountSiteId", oapagecontext.getParameter("ImcAccountSiteIdP"));
            hashmap.put("ImcAccountSiteUseId", oapagecontext.getParameter("ImcAccountSiteUseIdP"));
            hashmap.put("cmReturnFrom", "IMC");
            String s1 = "IMC_NG_ACCOUNT_SITE_DETAIL";
            oapagecontext.forwardImmediately(s1, (byte)0, "IMC_NG_CUST", hashmap, false, "Y");
        }
        if(s18 != null && !"".equals(s18.trim()))
        {
            hashmap.put("ImcPartyName", s12);
            String s2 = "IMC_NG_INACTIVE_ACCOUNT_SITES";
            oapagecontext.forwardImmediately(s2, (byte)0, "IMC_NG_CUST", hashmap, false, "Y");
        }
        if(s19 != null && !"".equals(s19.trim()))
        {
            hashmap.put("ImcPartyName", s12);
            String s3 = "IMC_NG_ACCOUNT_SITES_PURPOSE";
            oapagecontext.forwardImmediately(s3, (byte)0, "IMC_NG_CUST", hashmap, false, "Y");
        }
        if(s20 != null && !"".equals(s20.trim()))
        {
            hashmap.put("ImcPartyName", s12);
            String s4 = "IMC_NG_ACCOUNT_CONTACTS_ROLE";
            oapagecontext.forwardImmediately(s4, (byte)0, "IMC_NG_CUST", hashmap, false, "Y");
        }
        if(s21 != null && !"".equals(s21.trim()))
        {
            hashmap.put("ImcPartyName", s12);
            String s5 = "IMC_NG_ACCT_INACTIVE_CONTACTS";
            oapagecontext.forwardImmediately(s5, (byte)0, "IMC_NG_CUST", hashmap, false, "Y");
        }
        if(s22 != null && !"".equals(s22.trim()))
        {
            hashmap.put("ImcPartyName", s12);
            String s6 = "IMC_NG_ACCT_INATCIVE_RELATIONS";
            oapagecontext.forwardImmediately(s6, (byte)0, "IMC_NG_CUST", hashmap, false, "Y");
        }
        if(s23 != null && !"".equals(s23.trim()))
        {
            hashmap.put("ImcPartyName", s12);
            String s7 = "IMC_NG_ACCT_SITE_CONTACTS_ROLE";
            oapagecontext.forwardImmediately(s7, (byte)0, "IMC_NG_CUST", hashmap, false, "Y");
        }
        if(s24 != null && !"".equals(s24.trim()))
        {
            hashmap.put("ImcPartyName", OAUrl.encode(oapagecontext, s12));
            hashmap.put("cmCallingProduct", "OCO");
            hashmap.put("cmFunctionName", "IMC_NG_ACCOUNT_OVERVIEW");
            hashmap.put("cmSubRegion", "PARTYREGION");
            hashmap.put("cmPartyId", s11);
            hashmap.put("cmCustAccountId", s10);
            hashmap.put("cmSiteUseId", "-99");
            String s8 = "ARCMANALYSISDATACRDSUMMARYALT";
            oapagecontext.forwardImmediately(s8, (byte)1, null, hashmap, false, "Y");
        }
        if(s25 != null && !"".equals(s25.trim()))
        {
            hashmap.put("ImcPartyName", OAUrl.encode(oapagecontext, s12));
            hashmap.put("cmCallingProduct", "OCO");
            hashmap.put("cmFunctionName", "IMC_NG_ACCOUNT_SITE_DETAIL");
            hashmap.put("cmSubRegion", "PARTYREGION");
            hashmap.put("cmPartyId", s11);
            hashmap.put("cmCustAccountId", s10);
            hashmap.put("cmSiteUseId", oapagecontext.getParameter("ImcAccountSiteUseId"));
            String s9 = "ARCMANALYSISDATACRDSUMMARYALT";
            oapagecontext.forwardImmediately(s9, (byte)1, null, hashmap, false, "Y");
        }
    }

    public ODIMCAccountOverviewCO()
    {
    }

    public static final String RCS_ID = "$Header: ODIMCAccountOverviewCO.java 115.20 2005/03/23 20:39:20 achung noship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: ODIMCAccountOverviewCO.java 115.20 2005/03/23 20:39:20 achung noship $", "%packagename%");

}
