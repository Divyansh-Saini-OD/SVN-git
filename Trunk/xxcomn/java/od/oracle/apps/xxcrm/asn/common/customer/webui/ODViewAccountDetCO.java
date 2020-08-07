/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.common.customer.webui;

/* Subversion Info:
*
* $HeadURL: http://svn.na.odcorp.net/svn/od/common/trunk/xxcomn/java/od/oracle/apps/xxcrm/asn/common/customer/webui/ODViewAccountDetCO.java $
* $Rev: 90888 $
* $Date: 2010-01-15 03:22:59 -0500 (Fri, 15 Jan 2010) $
*/


import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import java.io.Serializable;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.util.provider.OAFrameworkProviderUtil;
import oracle.apps.fnd.framework.webui.*;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import od.oracle.apps.xxcrm.hz.account.customer.server.ODAccountSitesVOImpl;
import od.oracle.apps.xxcrm.hz.account.customer.server.ODAccountSitesVORowImpl;
import od.oracle.apps.xxcrm.asn.common.customer.server.ODViewAccountDetAMImpl;
import oracle.jbo.Row;
import com.sun.java.util.collections.HashMap;
import oracle.apps.ar.irec.common.server.CustomerSearchAMImpl;
import oracle.apps.ar.irec.common.server.ExternalUserSearchResultsVOImpl;
import oracle.apps.ar.irec.common.server.InternalCustomerSearchByCustomerIdVOImpl;
import oracle.apps.ar.irec.common.server.InternalCustomerSearchByCustomerIdVORowImpl;
import oracle.jbo.domain.Number;
import oracle.jdbc.OracleCallableStatement;
import oracle.apps.fnd.framework.server.OADBTransaction;
import java.sql.*;
import oracle.apps.ar.irec.common.server.ArwSearchCustomers;


/**
 * Controller for ...
 */
public class ODViewAccountDetCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header: /home/cvs/repository/Office_Depot/SRC/CRM/E0806_SalesCustomerAccountCreation/3.\040Source\040Code\040&\040Install\040Files/ODViewAccountDetCO.java,v 1.1 2007/09/18 09:21:41 vjmohan Exp $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
   OAApplicationModule am = pageContext.getApplicationModule(webBean);

/* For passing party_id from page context and initilaizing all the required methods
   or for passing request_id if call is from Account Setup subtab */
   String pageReq = null;
   pageReq = pageContext.getParameter("pagerequestId");
  if (pageReq != null)
  {
   String partyid =  pageContext.getParameter("pagePartyid");
   String requestID=  pageContext.getParameter("pagerequestId");
   Serializable[] methodParam = {partyid,requestID};
     am.invokeMethod("initCustAcc",methodParam);
      am.invokeMethod("initAccContacts");
      am.invokeMethod("initRelAcc");
      am.invokeMethod("initCreditDunn");
      am.invokeMethod("initAccSites");
      am.invokeMethod("initAccSitesContacts");
  }

    String partyid =  pageContext.getParameter("ASNReqFrmCustId");
    if(partyid ==null) partyid = pageContext.getParameter("reqPartyid");
   Serializable[] methodParam = {partyid,null};

     am.invokeMethod("initCustAcc",methodParam);
      am.invokeMethod("initAccContacts");
      am.invokeMethod("initRelAcc");
      am.invokeMethod("initCreditDunn");
      am.invokeMethod("initAccSites");
      am.invokeMethod("initAccSitesContacts");



  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean) 
  {
      super.processFormRequest(pageContext, webBean);
      OAApplicationModule am = pageContext.getApplicationModule(webBean);

  //For navigating to Account Setup subtab
     if ("ACCOUNTDETAIL".equals(pageContext.getParameter("AccDtl"))
         )
       {
         String partyID =  pageContext.getParameter("reqPartyid");
         String RequestId = pageContext.getParameter("RequestId");

         HashMap params = new HashMap();
      //   params.put("ASNReqFrmCustId",partyID);
         pageContext.putParameter("ASNReqFrmCustId",partyID);
         params.put("pid",partyID);
         params.put("Source","AccountDetail");
         params.put("AccountRequestId", RequestId);

         pageContext.forwardImmediately("ASN_ORGUPDATEPG",
                               OAWebBeanConstants.KEEP_MENU_CONTEXT,
                               null,
                               params, //pageParams
                               false, // Retain AM
                               OAWebBeanConstants.ADD_BREAD_CRUMB_NO); // Do not display breadcrums

    }
     // For Viewing Account Summary page of ARI
      if ("accSumclick".equals(pageContext.getParameter(EVENT_PARAM)))
       {
        String custAccID = pageContext.getParameter("paramCust");
        String billSiteId = pageContext.getParameter("paramBillsiteid");
        String Currency = pageContext.getParameter("paramCurrencyCode");

//Begin Change, Vasan, 23-Dec-2009
        String partyid =  pageContext.getParameter("ASNReqFrmCustId");
        if(partyid ==null) partyid = pageContext.getParameter("reqPartyid");
        pageContext.writeDiagnostics(this, "Vasan: partyID :"+partyid,3);
        pageContext.writeDiagnostics(this, "Vasan: Currency :"+Currency,3);
        pageContext.writeDiagnostics(this, "Vasan: CustAccID :"+custAccID+" billSiteId: "+billSiteId, 3);
        pageContext.writeDiagnostics(this, "Vasan: OrgID :"+pageContext.getOrgId(), 3);
        pageContext.writeDiagnostics(this, "Vasan: SessionID :"+pageContext.getSessionId(),3);
        pageContext.writeDiagnostics(this, "Vasan: UserID :"+pageContext.getUserId(),3);

        OADBTransaction dbtransaction = am.getOADBTransaction();

        OracleCallableStatement oraclecallablestatement = null;
        try
        {
            Number n;
            if(partyid !=null) n=new Number(partyid); else n=null;
            Number n1=new Number(pageContext.getOrgId());
            Number n2=new Number(pageContext.getSessionId());
            Number n3=new Number(pageContext.getUserId());
            Number n4=new Number(custAccID);
            Number n5=null;
            /*Number n5=null;
            if(billSiteId !=null) n5=new Number(billSiteId); else n5=null;*/
            String s= "Y";

            //Calling AR Java class to call arw_search_customers_w API

            ArwSearchCustomers.CustsiteRec acustsiterec[];
            ArwSearchCustomers.CustsiteRec custsiterec = new ArwSearchCustomers.CustsiteRec();
            custsiterec.setCustomerid(n4);
            custsiterec.setSiteuseid(n5);
            acustsiterec = (new ArwSearchCustomers.CustsiteRec[] {custsiterec});
            ArwSearchCustomers.initializeAccountSites(dbtransaction, acustsiterec, n, n2, n3, n1, s);
        //acustsiterec = getCustsiteRecArray();
        }//try
        catch(SQLException sqlexception)
        {
              pageContext.writeDiagnostics(this, "Vasan Exception : "+sqlexception,3);
        }//catch(SQLException sqlexception)

//End Change, Vasan, 23-Dec-2009
         HashMap params = new HashMap();
         params.put("Ircustomerid",custAccID);
         params.put("Ircustomersiteuseid",billSiteId);
         pageContext.putSessionValue("ARI_HIDE_CUSTOMER_SEARCH_LINK","YES");
         OAViewObject ODCreditDunningVO = (OAViewObject)am.findViewObject("ODCreditDunningVO");
         String cc = (String)ODCreditDunningVO.getCurrentRow().getAttribute("CurrencyCode");
         pageContext.writeDiagnostics(this, "Vasan: Currency Code :"+cc,3);


       
       pageContext.setForwardURL( pageContext.getApplicationJSP()
                                      +"?akRegionCode=ARIHOMEPAGE&akRegionApplicationId=222"
                                      +"&Ircustomerid={!!"
                                      +pageContext.encrypt(custAccID)
                                      +"}&Ircustomersiteuseid={!!"
                                      +pageContext.encrypt(billSiteId)+"}&Ircurrencycode="+cc,
                                       null,
                               KEEP_MENU_CONTEXT,
                               "",
                               null, //pageParams
                               true, // Retain AM
                               ADD_BREAD_CRUMB_YES,
                               OAException.ERROR);
        
        
       }

  // Getting parameters from pageContext
    String pageEvent = pageContext.getParameter("EventParam1");
    String pageEvent2 = pageContext.getParameter("EventParam3");
    String pageParam1 = pageContext.getParameter("EventParam2");
    String pageParam2 = pageContext.getParameter("EventParam4");

  // Invoking methods for current account radio selection
   if("RADIOCHANGE".equals(pageEvent))
     {
    String custId = pageParam1;
    String siteID = pageParam2;
    Serializable[] params= {custId};
    Serializable[] siteParam={siteID};
    am.invokeMethod("initAccContactsCur",params);
    am.invokeMethod("initRelAccCur",params);
    am.invokeMethod("initCreditDunnCur",params);
    am.invokeMethod("initAccSitesCur",params);
    am.invokeMethod("initAccSitesContactsCur",siteParam);
  }

 // Invoking method for current site radio selection
 if("RADIOCHANGE2".equals(pageEvent2))
     {
	  String custSid = pageParam2;
    Serializable[] params= {custSid};
    am.invokeMethod("initAccSitesContactsCur",params);
     }

  }
}
