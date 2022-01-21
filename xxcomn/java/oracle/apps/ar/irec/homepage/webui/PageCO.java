/*===========================================================================+
 |      Copyright (c) 2000, 2014 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 |       14-Aug-00  sjamall       Created.
 |       16-Mar-01  sjamall + aizadpan  commenting code; eliminated {} Blocks.                                |
 |       03-Apr-01  sjamall       added workaround for bug 1718439           |
 |       04-Apr-01  sjamall  fix for bug 1718466                             |
 |       08-May-01  sjamall  bugfix 1772584 : customer site use id is now    |
 |                           made null in the case where we don't have a customer
 |                           site use id passed in the url from the internal |
 |                           customer search page.                           |
 |       08-Jun-01  sjamall  bugfix 1821862 : checking for Customer Search   |
 |                           Function 'ARIHOME'                              |
 |       22-Jun-01  sjamall  bugfix 1841331                                  |
 |       31-Dec-01  sjamall       bugfix 2167273                             |
 |       19-Aug-02  albowicz  Modified for bug 1658316.  The e-mail address  |
 |                            used by the Contact Us Icon is now configurable|
 |                            by the implementor. This file was modified to  |
 |                            return the Page Name which is passed as part   |
 |                            of the API provided in ARI_CONFIG.             |
 |       26-Oct-02  albowicz  Online Aging  
 |       13-Jan-03  bchowdar  Modified
 |
 |
 |    21-Oct-03  hikumar      Bug # 3186472 - Modified for URL security      |
 |       09-Dec-2003 vnb      Bug # 3303162 - Modified to remove Go button   |
 |                            for the Currency Code choice list              | 
 |       10-Feb-04    vnb    Bug # 3367661 - Check isLoggingEnabled before   |
 |                           calling writeDiagnostics                        |
 |       27-Feb-04    vnb    Bug # 3418666 - Modified Aging bean to HideShow.|
 |                           Modified 'initialize': Removed code pointing to |
 |                           displayAging, which is no longer relevant.      |
 |    26-Apr-04   vnb        Bug # 3467287 - Customer and Customer Site ID   |
 |	   		     appended to Transaction List global button URL  |
 |    24-May-05  vnb         Bug 4197060 - MOAC Uptake                       |
 |    19-Jul-05  rsinthre    Bug 4495145 - Setting inContext branding and    |
 |                           renaming disableLogoutButton                    |
 |    12-Sep-05  rsinthre    Bug 4586621 - R12: Allow internal users to      |
 |                           assign a preferred contact for self service role|
 |    25-Oct-07  abathini    Bug 6071835 -Discount filter not working properly |
 |    10-Mar-08  rsinthre    Bug 6874406 - TST1205.XB1.QA: Other currencies not|
 |                           appearing on home page while navigating back    |
 |  24-Aug-2010 nkanchan - Bug 10048984name doesn't change back to null if view changed to all cust|
 |    18-Mar-11   nkanchan  Bug 11871875 - fp:9193514 :transaction           |
 |                           list disappears in ireceivables                 |
 |    13-May-13   melapaku   Bug 16720962 - ENDECA SUPPORT IN OIR            |
 |    28-Aug-13   melapaku   Bug 16983167 - UNABLE TO OPEN HOME/ACCOUNT TAB  |
 |                                          WHEN ACCESSING THRU PRINT NOTIFN  |
 |    12-Nov-16  ssiddams     Bug 19948462 - CHECKBOX ON IREC ACCOUNT SUMMARY | 
                           SCREEN DOES NOT RESET AFTER CLEARING AND RE-OPE    |
 +===========================================================================*/

/**
 * homepage controller class.
 *
 * the hierarchy of the homepage:
 ARIHOMEPAGE:PageAM:Page Layout:PageCO {4 sub regions}
	// below is only specific to the main content of the page.
	ARIHOMEPAGEDETAILS:Flow Layout:DetailsCO
		ARIHOMEPAGECOLUMNONE:Flow Layout:ColumnOneCO
			Discount Alerts
			Dispute Status
		ARIHOMEPAGECOLUMNTWO:Flow Layout:ColumnTwoCO
			Home Page Account Summary
		ARIHOMEPAGECOLUMNTHREE:Flow Layout:ColumnThreeCO
			Home Page News
			Home Page FAQs
			Home Page Policies


  checks to see if customer id is defined.
  if not, then get from securing attributes and set internal customer.

 * @author 	Mohammad Shoaib Jamall
 */

package oracle.apps.ar.irec.homepage.webui;

import java.io.Serializable;

import oracle.apps.ar.hz.components.base.webui.HzPuiConstants;
import oracle.apps.ar.irec.framework.webui.IROAControllerImpl;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.layout.OARowLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.nav.OALinkBean;
import oracle.apps.fnd.framework.webui.beans.table.OAAdvancedTableBean;
import oracle.apps.fnd.framework.webui.beans.table.OAColumnBean;

import oracle.jbo.domain.Number;

import oracle.jdbc.OracleCallableStatement;
import java.sql.Types;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;
import oracle.apps.ar.irec.util.BusinessObjectsUtils;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.common.*;
import oracle.apps.fnd.framework.*;
import oracle.apps.fnd.framework.server.*;
import oracle.apps.fnd.framework.webui.*;
import oracle.apps.fnd.framework.webui.beans.*;
import oracle.apps.fnd.framework.webui.beans.layout.*;
import oracle.apps.fnd.framework.webui.beans.message.*;
import oracle.apps.fnd.framework.webui.beans.nav.*;

public class PageCO extends IROAControllerImpl
{

  public static final String RCS_ID="$Header: PageCO.java 120.23.12020000.4 2014/11/12 08:50:33 ssiddams ship $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "oracle.apps.ar.irec.homepage.webui");
  protected String strLargeCust = "N";

  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    String customerId    = pageContext.getDecryptedParameter(CUSTOMER_ID_KEY );
    String siteUseId     = pageContext.getDecryptedParameter(CUSTOMER_SITE_ID_KEY );
    String strCurrencyCode = (String)getActiveCurrencyCode(pageContext, pageContext.getParameter( CURRENCY_CODE_KEY ));
    
    pageContext.writeDiagnostics(this,"PageCO processRequest customerId " + customerId, 1);
    pageContext.writeDiagnostics(this,"PageCO processRequest siteUseId " + siteUseId, 1);
    pageContext.writeDiagnostics(this,"PageCO processRequest strCurrencyCode " + strCurrencyCode, 1);
    
    if( customerId != null && siteUseId != null)
    {
      getActiveCustomerId(pageContext, customerId);
      getActiveCustomerUseId(pageContext, siteUseId);
    }
    
    pageContext.writeDiagnostics(this,"PageCO processRequest customerId 2 " + customerId, 1);
    pageContext.writeDiagnostics(this,"PageCO processRequest custSiteUseId 2 " + siteUseId, 1);
    
    String custId = getActiveCustomerId(pageContext);
    String custSiteUseId =  getActiveCustomerUseId(pageContext);
    
    pageContext.writeDiagnostics(this,"PageCO processRequest custId " + customerId, 1);
    pageContext.writeDiagnostics(this,"PageCO processRequest custSiteUseId " + siteUseId, 1);
    
    
    strLargeCust = isLargeCustomer( pageContext, webBean, customerId);
    
    pageContext.writeDiagnostics(this,"PageCO processRequest strLargeCust " + strLargeCust, 1); 
    
    if( customerId != null)
      pageContext.putSessionValue("Ircustomerid",customerId);    
    if( siteUseId != null)
      pageContext.putSessionValue("Ircustomersiteuseid",siteUseId);    
    if( strCurrencyCode != null)
      pageContext.putSessionValue("Irorgid",strCurrencyCode);    
          
    //Bug 8221702   
    String dataSourceCode = "ARI_CUST_STMT"; 
    initalizeTemplateVOs(pageContext,webBean,dataSourceCode);
    
    OAMessageChoiceBean orgChoiceBean =(OAMessageChoiceBean)webBean.findChildRecursive("OrgContext");
      orgChoiceBean.setPickListCacheEnabled(false);  // bug # 5050717 - fixed the issue of caching of org list - hikumar
       deleteRelCustPayAcctSites(pageContext, webBean);  //bug # 7721379 - NEED TO SHOW ONLY  GROUPED  CUSTOMERS IN  ACCT DETAILS CUSTOMER DROP DOWN -veapti
    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this, "start processRequest", OAFwkConstants.PROCEDURE);
    super.processRequest(pageContext, webBean);
    //Added for Bug 16720962 : Start
    //Modified if condition for Bug 16983167
    if(pageContext.getSessionValue("FromEndecaPage") == null && pageContext.getSessionValue("FromEndecaDisputePage") == null) 
       pageContext.putSessionValue("FromCustomerSearchPage","Y");
    else if((pageContext.getSessionValue("FromEndecaPage") != null && ! "Y".equals((String)pageContext.getSessionValue("FromEndecaPage"))) && (pageContext.getSessionValue("FromEndecaDisputePage") != null && ! "Y".equals((String)pageContext.getSessionValue("FromEndecaDisputePage"))))
       pageContext.putSessionValue("FromCustomerSearchPage","Y");
    OALinkBean returnToLink = (OALinkBean)webBean.findChildRecursive("AriReturnToCustSearch");
    adjustReturnToLocation(pageContext,returnToLink);
    //Added for Bug 16720962 : End
    //Initialise Multi-Org and policy context
    //MoGlobal.setCookie((OAApplicationModuleImpl)pageContext.getRootApplicationModule(), "AR"); 
    setMultiOrgPolicyContext(pageContext, webBean);

   
    /**
     * sjamall 06/07/2001 : bugfix 1821862 : checking for Customer Search
     * Function 'ARIHOME'
     */
    boolean allowViewing;
    Serializable [] params = { "ARIHOME" };
    {
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      allowViewing =
        ((Boolean)am.invokeMethod("testFunctionValid", params)).booleanValue();
    }

    if (!allowViewing)
    {
      // bugfix 1841331 : sjamall 06/22/2001
      if (pageContext.isLoggingEnabled(OAFwkConstants.EXCEPTION))
          pageContext.writeDiagnostics(this, "access denied: user does not have ARIHOME function enabled", OAFwkConstants.EXCEPTION);
      OADialogPage dialogPage = new OADialogPage();
      dialogPage.setDescriptionMessage(new OAException("AR", "ARI_ACCESS_DENIED"));
      pageContext.redirectToDialogPage(dialogPage);
    }
    
    // Bug # 5862963 (All Locations)
    // initialize the context and then initialize the page
    String acctGroupOption = pageContext.getProfile("OIR_ACCOUNT_GROUPING");
    boolean isExternal = isExternalCustomer(pageContext, webBean);
    OALinkBean returnLink =(OALinkBean)webBean.findChildRecursive("AriReturnToCustSearch");
  
    if((acctGroupOption!=null) && acctGroupOption.equals("ALWAYS_GROUP")&& isExternal){
      if(returnLink!=null)
      returnLink.setRendered(false);
    }
    initCurrentCustomerContext(pageContext,webBean);
        
    initialize(pageContext, webBean);

    //13-Jan-03 - BCHOWDAR - Changes
    //Bug 4495145 - Setting inContext branding and renaming disableLogoutButton
	handleMenusAndCustomerBranding(pageContext, webBean);
    
    if("N".equals(strLargeCust))
      setContactUsURL(pageContext, webBean);

    //Bug#3467287 - Customer and Customer Site appended to Transaction List global button URL
    appendParamstoTransactionListUrl(pageContext);

/* Bug 6071835 -Discount filter not working properly and throwing stale date error.
 It occurs only the when lesser no. of invoices(non-zero number) are to be
 shown than those that are already displayed based on the previous selection
 value in the 'Discounts' drop-down. 
 DiscountAlertsVO is being queried in the processFormData() of
 oracle.apps.ar.irec.homepage.webui.TableRegionCO during the poplist value
 change event.
 This results in the rowset containing less number of rows(1) than the number
 of rows on the UI(3) when the page is submitted. And stale data error is
 thrown which is expected behavior.

 To overcome this,since the table is a readonly table, we must use
 tableBean.setSkipProcessFormData(pageContext, true) in the page's
 controller.
*/ 
      OAAdvancedTableBean tableBean = (OAAdvancedTableBean)webBean.findIndexedChildRecursive("Arinestedregion3");
      if(tableBean != null) tableBean.setSkipProcessFormData(pageContext, true);      
    //Bug#3467287 - The Transaction List button will always remain enabled.
    //Bug3098364:
    
    /*
     * if (pageContext.getSessionValue("RecordsInTransactionList") == "YES" )
      setTransactionListGlobalButton(pageContext,false);
    else
      setTransactionListGlobalButton(pageContext,false);*/
      
     
    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))                
        pageContext.writeDiagnostics(this, "end processRequest", OAFwkConstants.PROCEDURE);

    //Bug 4586621 - Display the region assign preferred contact only for internal users
    if(isInternalCustomer(pageContext, webBean))
    {
      assignPreferredContact(pageContext, webBean);
    }  
    
    //Bug-19732203 : Removed the requery parameter in pagecontext and session to reexecute the query 
    pageContext.removeParameter("Requery");
    pageContext.removeSessionValue("Requery");
    
  }
  //This method will render assign preferred contact region.
  private void assignPreferredContact(OAPageContext pageContext, OAWebBean webBean)
  {
    OARowLayoutBean preferredContactRow = (OARowLayoutBean)webBean.findIndexedChildRecursive("PreferredContactRow");
    OARowLayoutBean seperatorRow        = (OARowLayoutBean)webBean.findIndexedChildRecursive("SeperatorRow");
    if(preferredContactRow!=null)
      preferredContactRow.setRendered(true);
    if(seperatorRow!=null)
      seperatorRow.setRendered(true);
    if(pageContext.getParameter(HzPuiConstants.HZ_PUI_ACT_CON_VIEW_MODE)==null)
    {
      pageContext.putParameter(HzPuiConstants.HZ_PUI_ACT_CON_VIEW_MODE, HzPuiConstants.HZ_PUI_ACTIVE_MODE);      
    }
    pageContext.putParameter(HzPuiConstants.HZ_PUI_CUST_ACCOUNT_ID, getActiveCustomerId(pageContext));
    OAViewObject custVO = (OAViewObject)pageContext.getRootApplicationModule().findViewObject("CustomerInformationVO");
    String custAcctSiteId = null;
    if(custVO!=null)
    {
        Serializable [] param = { "CustAcctSiteId" };
        custAcctSiteId = (String)custVO.invokeMethod("getFirstObject", param);        
    }
    else {
        Serializable [] param = { getActiveCustomerId(pageContext), getActiveCustomerUseId(pageContext) };
        custVO.invokeMethod("initQuery", param);        
    }
    pageContext.putParameter(HzPuiConstants.HZ_PUI_CUST_ACT_SITE_ID, custAcctSiteId); 
    //Assign primary role and create contact buttons are hidden, as their functionality is not supprted
    renderBean(webBean, "button", "AsgnPrBtn", false);
    renderBean(webBean, "button", "CrActConBtn", false);
    renderBean(webBean, "column", "ConViewDet", false);
    renderBean(webBean, "column", "ConUpdateCol", false);
    renderBean(webBean, "column", "ConRemoveCol", false);
    //Display maximum three rows in Active contacts Advanced table
    OAAdvancedTableBean tableBean = (OAAdvancedTableBean)webBean.findChildRecursive("ActContactsAdvTab");
    if(tableBean!=null)      
    {
      String sDisplayLimit = pageContext.getProfile("OIR_ACTIVE_CONTACTS_DISP_LIMIT");      
      if(sDisplayLimit!=null)
      {
        try
        {
          int displayLimit = Integer.parseInt(sDisplayLimit);
          tableBean.setNumberOfRowsDisplayed(displayLimit);
        }
        catch(NumberFormatException ex){}
      }
    }       
  }

   private void renderBean(OAWebBean webBean, String beanType, String beanId, boolean render)    
   {
      OAWebBean bean = null;
      if("button".equals(beanType))
        bean = (OASubmitButtonBean)webBean.findChildRecursive(beanId);
      else
        bean = (OAColumnBean)webBean.findChildRecursive(beanId);
      if(bean!=null)
        bean.setRendered(render);
   }

  public void initialize(OAPageContext pageContext, OAWebBean webBean)
  {
    OAApplicationModule am = pageContext.getApplicationModule(webBean);

    {
      String customerId = null;
      String customerSiteUseId = null;
      // Bug # 3186472 - hikumar
      // Modified to replace getParameter with getDecryptedParameter
      customerId = pageContext.getDecryptedParameter(CUSTOMER_ID_KEY );
      customerSiteUseId = pageContext.getDecryptedParameter( CUSTOMER_SITE_ID_KEY );
      
      //Bug 6874406 - While navigating back to Home Page, customerid will not be there in parameters
      //Read customer id from session, then run CustomerInformationVO to show currencies of active customer
      if(customerId == null) 
      {
        customerId = getActiveCustomerId(pageContext);
        customerSiteUseId = getActiveCustomerUseId(pageContext);
        if(customerId!=null && !"".equals(customerId))
        {    
            OAViewObject custVO = (OAViewObject)pageContext.getRootApplicationModule().findViewObject("CustomerInformationVO");
            Serializable [] param = { customerId, customerSiteUseId };
            custVO.invokeMethod("initQuery", param);               
        }
      }
      // the framework returns a '{}' for parameters when they have
      // a null value and they are encrypted out of the database.
      // see bug 1718439
      if (customerId != null)
      {
        try{ Number customerIdNumber = new Number(customerId);  }
        catch (Exception e)  { customerId = null; }
      }
      if (customerSiteUseId != null)
      {
        // bugfix 1772584 : customer site use id being changed to "~"
        // so that it can be set to "" in the session cache in the
        // call to getActiveCustomerUseId(pageContext, customerSiteUseId)
        try{ Number customerSiteUseIdNumber = new Number(customerSiteUseId);  }
        catch (Exception e) { customerSiteUseId = "~"; }
      }

      if (!(isNullString(customerId)))
      {
        getActiveCustomerId(pageContext, customerId);
        // bugfix 1772584 : customer site use id being updated
        // whenever the customerId is non-null
        if (null != customerSiteUseId)
         customerSiteUseId = getActiveCustomerUseId(pageContext, customerSiteUseId);
         
        // Commented for bug # 10048984    
        //setCustomerInformation(pageContext, webBean, customerId, customerSiteUseId);

      }
      // Added for bug # 10048984
      //if("N".equals(strLargeCust))      
        setCustomerInformation(pageContext, webBean, customerId, customerSiteUseId);
    
      // bug # 7387297 nkanchan
      OAViewObject custVO = (OAViewObject)pageContext.getRootApplicationModule().findViewObject("CustomerInformationVO");
      Serializable [] param = { getActiveCustomerId(pageContext), getActiveCustomerUseId(pageContext) };
      custVO.invokeMethod("initQuery", param);        
    }

    // get securing attributes(customer id and customer site use id) from database
    // if they haven't been set already.
    if (!(isSetActiveCustomerId(pageContext)))
    {
      OAViewObject sec_attr = (OAViewObject)am.findViewObject("SecuringAttributesVO");
      Object customerId, customerSiteId;

      Serializable [] params1 = {};
      sec_attr.invokeMethod("initQuery", params1);

      Serializable [] params2 = {"CustomerId"};
      customerId = sec_attr.invokeMethod("getFirstObject", params2);

      Serializable [] params3 = {"CustomerSiteUseId"};
      customerSiteId = sec_attr.invokeMethod("getFirstObject", params3);
      if (null != customerId)
      {
        getActiveCustomerId(pageContext, customerId.toString());
      }
      if (null != customerSiteId)
        getActiveCustomerUseId(pageContext, customerSiteId.toString());

    }

    String currCode = null;
    String custId = null;
    String custUseId = null;

    // bugfix 1841331 : sjamall 06/22/2001
    try
    {
      getActiveCurrencyCode(pageContext, pageContext.getParameter( CURRENCY_CODE_KEY ));
      currCode = getActiveCurrencyCode(pageContext);
      custId = getActiveCustomerId(pageContext);
      custUseId = getActiveCustomerUseId(pageContext);
    }
    catch(OAException e)
    {
      OADialogPage dialogPage = new OADialogPage();
      dialogPage.setDescriptionMessage(new OAException("AR", "ARI_ACCESS_DENIED"));
      pageContext.redirectToDialogPage(dialogPage);
    }

    //Bugfix # 3418666
    //Removed code pointing to displayAging, which is no longer relevant.
    Serializable [] params4 = { currCode,
                                custId,
                                custUseId};
                                
     if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))    
          pageContext.writeDiagnostics
            (this, "oracle.apps.ar.irec.homepage.server.PageAM.initQuery(" +
                "<currency code>" + currCode + ", <customer id>" + custId +
                ", <customer site use id>" + custUseId + ")", OAFwkConstants.STATEMENT);


    // Setup Aging Bucket Usage for the session, this is the only
    // place where this session varible is set.
    String agingBucketUsage = (String)am.invokeMethod("initQuery", params4);
    if(agingBucketUsage != null)
      pageContext.putSessionValue("AgingBucketUsage", agingBucketUsage); 
      
  }

  public void processFormData(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormData(pageContext, webBean);

    // change Active Currency Code if a currency code has been selected.
    
    //String currentCurrencyCode = getActiveCurrencyCode(pageContext);

    //PPR Implementation - removal of GO button for Currency Code poplist 
    //This is to check if the event "currCodeChanged" is fired as a firePartialAction
    //on update of the Currency Code Message Choice bean
    //String eventName = pageContext.getParameter(UIConstants.EVENT_PARAM);
    //String sourceName = pageContext.getParameter(UIConstants.SOURCE_PARAM);

    if (pageContext.getParameter("IcxGoControl") != null)
    {
      String selectedCurrencyCode = pageContext.getParameter("AriCurrency");
      String sOrgContext = pageContext.getParameter("OrgContext");
      if (sOrgContext != null)
        setActiveOrgId(pageContext, sOrgContext);
        
      String selectedCustomerId = pageContext.getParameter("CustomerContextList");
      // Bug 11871875
      String currentCurrencyCode = getActiveCurrencyCode(pageContext);
      String currentCustomerId  = getActiveCustomerId(pageContext);
      if (currentCustomerId ==null || "".equals(currentCustomerId) ) 
        currentCustomerId = "-1"; // this is to avoid null pointer exception in the following if conditon
              
      if(!currentCurrencyCode.equals(selectedCurrencyCode) || !currentCustomerId.equals(selectedCustomerId))
        pageContext.putSessionValue("Requery","Y"); //since customer context is changed accountDetails have to requery 
        
      setActiveCustomerId(pageContext, selectedCustomerId);
      
      getActiveCurrencyCode (pageContext, selectedCurrencyCode);
      
      pageContext.forwardImmediatelyToCurrentPage(null,true,null);
    }
  
  }

   public String isLargeCustomer(OAPageContext pageContext, OAWebBean webBean, String strCustomerId){
    OADBTransaction txn = ((OAApplicationModuleImpl)pageContext.getApplicationModule(webBean)).getOADBTransaction();
    OracleCallableStatement oraclecallablestatement =  null;
    String strIsLargeCust = "N";
    String populateSession = "Y";
    Long sessionID=new Long(pageContext.getSessionId());
    try {
        String strSqlStmt = "BEGIN :1 := XX_FIN_ARI_UTIL.IS_LARGE_CUSTOMER(p_customer_id => :2, p_session_id => :3, p_populate_session => :4); END;";

        oraclecallablestatement = 
            (OracleCallableStatement)txn.createCallableStatement(strSqlStmt, 1);
            if (oraclecallablestatement != null) {
              oraclecallablestatement.registerOutParameter(1, Types.VARCHAR, 0, 1);
              oraclecallablestatement.setString(2, strCustomerId);
              oraclecallablestatement.setLong(3, sessionID);              
              oraclecallablestatement.setString(4, populateSession);
              oraclecallablestatement.execute();
              strIsLargeCust = oraclecallablestatement.getString(1);
            }

    } catch (Exception ex) {
        try {
            if (oraclecallablestatement != null)
                oraclecallablestatement.close();
        } catch (Exception ex2) {
        }
    }
    return strIsLargeCust;
  }

  // This function is called by IROAController to determine the page name. 
  // The page name is used for the Contact Us feature which customers can 
  // implement in the ARI_CONFIG package.
  
  public String getPageName(OAPageContext pageContext, OAWebBean webBean)
  {
    return "ARI_HOME_PAGE";
  }

}

