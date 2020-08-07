package od.oracle.apps.xxcrm.scs.fdk.webui;

/* Subversion Info:

*

* $HeadURL: http://svn.na.odcorp.net/svn/od/common/trunk/xxcomn/java/od/oracle/apps/xxcrm/scs/fdk/webui/ODSCSHomeCO.java $

*

* $Rev: 101732 $

*

* $Date: 2010-05-10 11:48:02 -0400 (Mon, 10 May 2010) $

*/

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAViewObject;
import od.oracle.apps.xxcrm.scs.fdk.server.*;
import oracle.apps.fnd.framework.webui.beans.nav.OALinkBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.beans.layout.OASpacerBean;
import oracle.jbo.domain.Number;
import com.sun.java.util.collections.HashMap;
import oracle.jdbc.OracleCallableStatement;
import oracle.apps.fnd.framework.server.OADBTransaction;
import java.sql.*;
import oracle.apps.ar.irec.common.server.ArwSearchCustomers;

public class ODSCSHomeCO extends OAControllerImpl
{

    public ODSCSHomeCO()
    {
        partySiteId = "";
        siteName = "";
    }

    public void processRequest(OAPageContext pageContext, OAWebBean webBean)
    {
        super.processRequest(pageContext, webBean);

        partySiteId = pageContext.getParameter("StId").toString();
        siteName = pageContext.getParameter("StNm").toString();
		pageContext.putTransactionValue("partySiteId", partySiteId);
		pageContext.putTransactionValue("siteName", siteName);

		OAApplicationModule currentAm = pageContext.getApplicationModule(webBean);

		OAViewObject ODAdditionalLinkInfoVO = (OAViewObject)currentAm.findViewObject("ODAdditionalLinkInfoVO");
		if ( ODAdditionalLinkInfoVO == null )
			ODAdditionalLinkInfoVO = (OAViewObject)currentAm.createViewObject("ODAdditionalLinkInfoVO",
                "od.oracle.apps.xxcrm.scs.fdk.server.ODAdditionalLinkInfoVO");

		ODAdditionalLinkInfoVO.setWhereClause(null);
		ODAdditionalLinkInfoVO.setWhereClauseParam(0, partySiteId);
		ODAdditionalLinkInfoVO.setWhereClauseParam(1, partySiteId);
		ODAdditionalLinkInfoVO.setWhereClauseParam(2, partySiteId);
		ODAdditionalLinkInfoVO.executeQuery();

		ODAdditionalLinkInfoVORowImpl row = (ODAdditionalLinkInfoVORowImpl)ODAdditionalLinkInfoVO.first();
		String orgType = row.getOrgType();

		String mapUrl = row.getMapUrl();
		String mapUrlGoogle = row.getMapUrlGoogle();

		String currencyCode = row.getCurrencyCode();
		pageContext.putTransactionValue("currencyCode", currencyCode);

		Number custAccountId = row.getCustAccountId();
		if (custAccountId!=null)	
		pageContext.putTransactionValue("custAccountId", custAccountId.toString());

		Number partyId = row.getPartyId();
		pageContext.putTransactionValue("partyId", partyId.toString());

		String partyName = row.getPartyName();
		pageContext.putTransactionValue("partyName", partyName);

		String custNumber = row.getCustNumber();
		pageContext.putTransactionValue("custNumber", custNumber);

		String addrSeq = row.getAddrSeq();
		pageContext.putTransactionValue("addrSeq", addrSeq);

		OAViewObject ODAdditionalLinkTerrIdVO = (OAViewObject)currentAm.findViewObject("ODAdditionalLinkTerrIdVO");
		if ( ODAdditionalLinkTerrIdVO == null )
			ODAdditionalLinkTerrIdVO = (OAViewObject)currentAm.createViewObject("ODAdditionalLinkTerrIdVO",
                "od.oracle.apps.xxcrm.scs.fdk.server.ODAdditionalLinkTerrIdVO");

		ODAdditionalLinkTerrIdVO.setWhereClause(null);
		ODAdditionalLinkTerrIdVO.setWhereClauseParam(0, partySiteId);
		ODAdditionalLinkTerrIdVO.setWhereClauseParam(1, "PARTY_SITE");
		ODAdditionalLinkTerrIdVO.executeQuery();

		ODAdditionalLinkTerrIdVORowImpl rowTerrId = (ODAdditionalLinkTerrIdVORowImpl)ODAdditionalLinkTerrIdVO.first();
		String orgTerrId = rowTerrId.getTerrId();
        pageContext.putTransactionValue("orgTerrId", orgTerrId);

		String STARReportPDFDest = "http://reportssq.na.odcorp.net/cognos8/cgi-bin/cognosisapi.dll?b_action=xts.run&m=portal/launch.xts&ui.tool=CognosViewer&ui.object=/content/folder[@name=%27BSD Knowledge%27]/folder[@name=%27Contact Strategy%27]/folder[@name=%27Sub Reports%27]/report[@name=%27Ship To Action Report%27]&ui.action=run&run.outputFormat=PDF&run.prompt=false&ui.header=false&ui.toolbar=true&ui=h1h2h3h4&p_pAccountSiteID="+addrSeq+"&p_pCustomerID="+custNumber+"&p_pTerrID="+orgTerrId;

		OALinkBean STARReportPDF = (OALinkBean)webBean.findChildRecursive("STARReportPDF");
        if (STARReportPDF != null)
		{
         STARReportPDF.setDestination(STARReportPDFDest);
		 STARReportPDF.setTargetFrame("_blank");
		}


        String STARReportDest = "http://reportssq.na.odcorp.net/cognos8/cgi-bin/cognosisapi.dll?b_action=xts.run&m=portal/launch.xts&ui.tool=CognosViewer&ui.object=/content/folder[@name=%27BSD Knowledge%27]/folder[@name=%27Contact Strategy%27]/folder[@name=%27Sub Reports%27]/report[@name=%27Ship To Action Report%27]&ui.action=run&run.prompt=false&ui.header=false&ui.toolbar=true&ui=h1h2h3h4&p_pAccountSiteID="+addrSeq+"&p_pCustomerID="+custNumber+"&p_pTerrID="+orgTerrId;

		OALinkBean STARReport = (OALinkBean)webBean.findChildRecursive("STARReport");
        if (STARReport != null)
		{
         STARReport.setDestination(STARReportDest);
		 STARReport.setTargetFrame("_blank");
		}

		OALinkBean SiteAddressMap = (OALinkBean)webBean.findChildRecursive("SiteAddressMap");
        if (SiteAddressMap != null)
		{
         SiteAddressMap.setDestination("http://maps.google.com/maps?q="+mapUrlGoogle);
		// SiteAddressMap.setDestination(mapUrl);
		 SiteAddressMap.setTargetFrame("_blank");
		}

		//orgType = "C";

		if(orgType.equals("P"))
		{
         OALinkBean STARReport1 = (OALinkBean)webBean.findChildRecursive("STARReport");
          if (STARReport1 != null)
            STARReport1.setRendered(false);
		 OALinkBean STARReportPDF1 = (OALinkBean)webBean.findChildRecursive("STARReportPDF");
          if (STARReportPDF1 != null)
            STARReportPDF1.setRendered(false);
		 OALinkBean BillingDetail = (OALinkBean)webBean.findChildRecursive("BillingDetail");
          if (BillingDetail != null)
            BillingDetail.setRendered(false);
		 OALinkBean PriceCalculator = (OALinkBean)webBean.findChildRecursive("PriceCalculator");
          if (PriceCalculator != null)
            PriceCalculator.setRendered(false);
		 OALinkBean ServiceRequestSummary = (OALinkBean)webBean.findChildRecursive("ServiceRequestSummary");
          if (ServiceRequestSummary != null)
            ServiceRequestSummary.setRendered(false);

		 OASpacerBean Spacer02 = (OASpacerBean)webBean.findChildRecursive("Spacer02");
          if (Spacer02 != null)
            Spacer02.setRendered(false);
		 OASpacerBean Spacer03 = (OASpacerBean)webBean.findChildRecursive("Spacer03");
          if (Spacer03 != null)
            Spacer03.setRendered(false);
		 OASpacerBean Spacer04 = (OASpacerBean)webBean.findChildRecursive("Spacer04");
          if (Spacer04 != null)
            Spacer04.setRendered(false);
		 OASpacerBean Spacer05 = (OASpacerBean)webBean.findChildRecursive("Spacer05");
          if (Spacer05 != null)
            Spacer05.setRendered(false);
		 OASpacerBean Spacer07 = (OASpacerBean)webBean.findChildRecursive("Spacer07");
          if (Spacer07 != null)
            Spacer07.setRendered(false);
		}
else{
   OALinkBean AccountSetupRequest1 = (OALinkBean)webBean.findChildRecursive("AccountSetupRequest");
        if (AccountSetupRequest1 != null)
            AccountSetupRequest1.setRendered(false);
	 OALinkBean ServiceRequestSummary1 = (OALinkBean)webBean.findChildRecursive("ServiceRequestSummary");
          if (ServiceRequestSummary1 != null)
            ServiceRequestSummary1.setRendered(false);

}
    }

    public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
    {
        super.processFormRequest(pageContext, webBean);

		partySiteId = (String)pageContext.getTransactionValue("partySiteId");
        siteName =    (String)pageContext.getTransactionValue("siteName");
		String partyId = (String)pageContext.getTransactionValue("partyId");
		String partyName = (String)pageContext.getTransactionValue("partyName");
		String orgTerrId = (String)pageContext.getTransactionValue("orgTerrId");
		String custNumber = (String)pageContext.getTransactionValue("custNumber");
		String addrSeq = (String)pageContext.getTransactionValue("addrSeq");
		String custAccountId = (String)pageContext.getTransactionValue("custAccountId");
        String currencyCode = (String)pageContext.getTransactionValue("currencyCode");

        OAApplicationModule currentAm = pageContext.getApplicationModule(webBean);

        if("TaskDetails".equals(pageContext.getParameter(EVENT_PARAM)))			
        {
         HashMap params = new HashMap();
         params.put("ASNReqFrmCustId", partyId);  
		 params.put("ASNReqFrmCustName", partyName);
		 params.put("ASNReqFrmSiteId", partySiteId);
		 params.put("ASNReqFrmSiteName", siteName);
		 params.put("AddnInfoTaskDetails", partyId); pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxcrm/asn/partysite/webui/ODSiteUpdatePG&OAFunc=XX_ASN_SITE_UPDATE&ASNReqFrmFuncName=XX_ASN_SITE_UPDATE&retainAM=Y&addBreadCrumb=Y",
                                        null,
                                        KEEP_MENU_CONTEXT,
                                        null,
                                        params,
                                        false,
                                        ADD_BREAD_CRUMB_YES,
		                                IGNORE_MESSAGES);
        }
        if("BillingDetail".equals(pageContext.getParameter(EVENT_PARAM)))			
        {
         OADBTransaction dbtransaction = currentAm.getOADBTransaction();
         OracleCallableStatement oraclecallablestatement = null;
         try
         {
            Number partyIdnum = new Number(partyId);
			Number  n = partyIdnum;
			Number custAccountIdNum = new Number(custAccountId);
			//Number custAccountIdNum = new Number("12345678");
            Number n1 = new Number(pageContext.getOrgId());
            Number n2 = new Number(pageContext.getSessionId());
            Number n3 = new Number(pageContext.getUserId());
            Number n4 = custAccountIdNum;
            Number n5 = null;
            String  s = "Y";

            //Calling AR Java class to call arw_search_customers_w API
            ArwSearchCustomers.CustsiteRec acustsiterec[];
            ArwSearchCustomers.CustsiteRec custsiterec = new ArwSearchCustomers.CustsiteRec();
            custsiterec.setCustomerid(n4);
            custsiterec.setSiteuseid(n5);
            acustsiterec = (new ArwSearchCustomers.CustsiteRec[] {custsiterec});
            ArwSearchCustomers.initializeAccountSites(dbtransaction, acustsiterec, n, n2, n3, n1, s);
        
         }//try
         catch(SQLException sqlexception){}
         
         HashMap params = new HashMap();
         params.put("Ircustomerid",custAccountId);
         params.put("Ircustomersiteuseid",null);
         pageContext.putSessionValue("ARI_HIDE_CUSTOMER_SEARCH_LINK","YES");
                        
         pageContext.setForwardURL(pageContext.getApplicationJSP()
                                      +"?akRegionCode=ARIHOMEPAGE&akRegionApplicationId=222"
                                      +"&Ircustomerid={!!"
                                      +pageContext.encrypt(custAccountId)
                                      +"}&Ircustomersiteuseid={!!"
                                      +pageContext.encrypt(null)+"}&Ircurrencycode="+currencyCode,
                                       null,
                                   KEEP_MENU_CONTEXT,
                                   "",
                                   null, //pageParams
                                   true, // Retain AM
                                   ADD_BREAD_CRUMB_YES,
                                   IGNORE_MESSAGES);
        }
		if("PriceCalculator".equals(pageContext.getParameter(EVENT_PARAM)))
        {
         HashMap params = new HashMap();
		 //custNumber = "12345678";
         params.put("custNumberDefault", custNumber);
		 String fwdUrl = "OA.jsp?page=/od/oracle/apps/xxcrm/netPricer/webui/ODNetPricerPG&retainAM=Y&addBreadCrumb=Y";
		 pageContext.setForwardURL(fwdUrl,
                                   null,
                                   KEEP_MENU_CONTEXT,
                                   null,
                                   params,
                                   false,
                                   ADD_BREAD_CRUMB_YES,
                                   IGNORE_MESSAGES);
        }
		if("ServiceRequestSummary".equals(pageContext.getParameter(EVENT_PARAM)))			
        {
         HashMap params = new HashMap();         pageContext.setForwardURL("OA.jsp?OAFunc=CSZ_SR_T2_H_FN_PULL&addBreadCrumb=Y",
                                        null,
                                        KEEP_MENU_CONTEXT,
                                        null,
                                        params,
                                        false,
                                        ADD_BREAD_CRUMB_YES,
		                                //ADD_BREAD_CRUMB_RESTART,
                                        IGNORE_MESSAGES);
        }
		if("AccountSetupRequest".equals(pageContext.getParameter(EVENT_PARAM)))
        {
         HashMap params = new HashMap();
         params.put("ASNReqFrmCustId", partyId);    
		 params.put("AddnInfoAccountRequestId", partyId); pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxcrm/asn/common/customer/webui/ODOrgUpdatePG&OAFunc=ASN_ORGUPDATEPG&ASNReqFrmFuncName=ASN_ORGUPDATEPG&retainAM=Y&addBreadCrumb=Y",
                                        null,
                                        KEEP_MENU_CONTEXT,
                                        null,
                                        params,
                                        false,
                                        ADD_BREAD_CRUMB_YES,
		                                //ADD_BREAD_CRUMB_RESTART,
                                        IGNORE_MESSAGES);
        }
    }

    public static final String RCS_ID = "$Header$";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header$", "%packagename%");
    String partySiteId;
    String siteName;

}
