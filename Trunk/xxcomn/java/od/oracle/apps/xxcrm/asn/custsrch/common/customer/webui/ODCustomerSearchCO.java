/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODCustomerSearchCO.java                                       |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Page level Controller class for the customer Search Page               |
 |                                                                           |
 |  NOTES                                                                    |
 |         Used for the Customer Search Page                                 |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    No dependencies.                                                       |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 | 17-Mar-2008 Jasmine Sujithra   Created                                    |
 | 15-Apr-2008 Jasmine Sujithra   Updated to display tip bean for all users  |                   
 | 16-Apr-2008 Anirban Chaudhuri  Updated to display TIP for unsecured user  |
 | 21-May-2009 Anirban Chaudhuri  Fixed defect#15377                         |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.custsrch.common.customer.webui;

import oracle.apps.fnd.common.VersionInfo;

import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import od.oracle.apps.xxcrm.asn.common.fwk.webui.ODASNControllerObjectImpl;
import com.sun.java.util.collections.HashMap;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import java.io.Serializable;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.beans.OATipBean;   
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean; 


/**
 * Controller for ...
 */
public class ODCustomerSearchCO  extends ODASNControllerObjectImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.custsrch.common.customer.webui.ODCustomerSearchCO.processRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }
    super.processRequest(pageContext, webBean);
    OAApplicationModule oaapplicationmodule = pageContext.getApplicationModule(webBean);
    pageContext.putParameter("HzPuiSearchPartyType", "ORGANIZATION");
    String searchPartyType = pageContext.getParameter("HzPuiSearchPartyType");
    String relGroupCode = pageContext.getParameter("HzPuiRelGroupCode");
    pageContext.writeDiagnostics(METHOD_NAME, "HzPuiSearchPartyType :  "+searchPartyType, OAFwkConstants.STATEMENT);
    pageContext.writeDiagnostics(METHOD_NAME, "HzPuiRelGroupCode :  "+relGroupCode, OAFwkConstants.STATEMENT);
    Serializable aserializable1[] = {
                searchPartyType, relGroupCode
            };
    oaapplicationmodule.invokeMethod("initSearchRelFilterQuery", aserializable1);

    String custAccess  = pageContext.getProfile("ASN_CUST_ACCESS");
	if(custAccess == null || "".equals(custAccess.trim()))
       custAccess = "S";
    pageContext.writeDiagnostics(METHOD_NAME, "ASN_CUST_ACCESS : "+custAccess, OAFwkConstants.STATEMENT);
    boolean isLoginResourceManager = isLoginResourceManager(pageContext.getApplicationModule(webBean), pageContext);

    OATipBean tip = (OATipBean)((OAPageLayoutBean)webBean).findChildRecursive("SearchCriteriaTip");   
    if("F".equals(custAccess) )   
    {   
      pageContext.writeDiagnostics(METHOD_NAME, "Display Tip Bean for Mandatory Params in unsecured search "+custAccess, OAFwkConstants.STATEMENT);   
      tip.setRendered(true);   
    }   
    else   
    {   
      pageContext.writeDiagnostics(METHOD_NAME, "Hide Tip Bean for Mandatory Params in secured search "+custAccess, OAFwkConstants.STATEMENT);   
      tip.setRendered(false);   
    } 

		

    //String sessionCallingPage =(String)pageContext.getSessionValue("ASNTxnCallingPage");
	String sessionCallingPage = pageContext.getParameter("ASNCustSrchCallPage");
    pageContext.writeDiagnostics(METHOD_NAME, "ASNTxnCallingPage : "+sessionCallingPage, OAFwkConstants.STATEMENT);

  
    
    if ("DASHBOARD".equals(sessionCallingPage)) 
    {
        if(!"F".equals(custAccess) && !isLoginResourceManager)
        {
            pageContext.writeDiagnostics(METHOD_NAME, "Anirban: No Full Access and not manager and coming from Dashboard; Hence calling default search ", OAFwkConstants.STATEMENT);
            String resourceId = getLoginResourceId(pageContext.getApplicationModule(webBean), pageContext);
            pageContext.writeDiagnostics(METHOD_NAME, "Resource Id : "+resourceId, OAFwkConstants.STATEMENT);
            Serializable aserializable2[] = {
                    resourceId
                };
            oaapplicationmodule.invokeMethod("initQueryForDefault", aserializable2);
            pageContext.removeSessionValue("ASNTxnSwitchPanel");
            pageContext.putSessionValue("ASNTxnSwitchPanel","YES");

            pageContext.removeSessionValue("ASNTxnCallingPage");
            pageContext.putSessionValue("ASNTxnCallingPage","DONE");   

            pageContext.removeParameter("ASNCustSrchCallPage");
			pageContext.putParameter("ASNCustSrchCallPage", "DONE");	         
        }
    }
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }
    
  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.custsrch.common.customer.webui.ODCustomerSearchCO.processFormRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }
    super.processFormRequest(pageContext, webBean);
    pageContext.putParameter("ASNReqFrmFuncName", "OD_ASN_CUSTOMER_SEARCHPG");
     HashMap hashmap = new HashMap();    
     
    if(pageContext.getParameter("CreateOrganization") != null)
    {
            pageContext.putParameter("ASNReqPgAct", "SUBFLOW");
            hashmap.put("ASNReqFrmFuncName", "ASN_ORGCREATEPG");
            processTargetURL(pageContext, null, hashmap);
    } else if("PARTYDETAIL".equals(pageContext.getParameter("HzPuiEvent")))
    {
            hashmap.put("ASNReqFrmCustId", pageContext.getParameter("HzPuiPartyId"));
            hashmap.put("ASNReqFrmCustName", pageContext.getParameter("HzPuiPartyName"));
            hashmap.put("ASNReqFrmFuncName", "ASN_ORGVIEWPG");
            pageContext.putParameter("ASNReqPgAct", "CUSTDET");
			
            if("PERSON".equals(getCustomerType(pageContext, pageContext.getParameter("HzPuiPartyId"))))
                    throw new OAException("ASN", "ASN_CMMN_PTYPERSON_ACSS_ERR");

            boolean flag50 = false;            
            pageContext.forwardImmediately("ASN_ORGVIEWPG", OAWebBeanConstants.KEEP_MENU_CONTEXT, null, hashmap, flag50, "Y");
    } else if("ADDRDETAIL".equals(pageContext.getParameter("HzPuiAddrEvent")))
    {
            hashmap.put("ASNReqFrmCustId", pageContext.getParameter("HzPuiAddrPartyId"));
            hashmap.put("ASNReqFrmCustName", pageContext.getParameter("HzPuiAddrPartyName"));
            hashmap.put("ASNReqFrmSiteId", pageContext.getParameter("HzPuiAddrPartySiteId"));            
            hashmap.put("ASNReqFrmFuncName", "XX_ASN_SITEVIEWPG");
			
            boolean flag50 = false;            
            pageContext.forwardImmediately("XX_ASN_SITEVIEWPG", OAWebBeanConstants.KEEP_MENU_CONTEXT, null, hashmap, flag50, "Y");
    } 
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }
    
  }

}
