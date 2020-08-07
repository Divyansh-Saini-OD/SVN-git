/*===========================================================================+
 |      Copyright (c) 2000 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 |       12-Jul-01  sjamall       Created.                                   |
 |       13-May-02  albowicz      Modified for enhancement request 2006628.  |
 |                                The customer search now supports external  |
 |                                users and trx number searches.  This file  |
 |                                was specifically modified to support       |
 |                                linking to trx details pages by making     |
 |                                sure that certain session values are being |
 |                                setup properly.                            |
 |       19-Aug-02  albowicz      Modified for bug 1658316.  The e-mail      |
 |                                address used by the Contact Us Icon is now |
 |                                configurable by the implementor. This file |
 |                                was modified to call the helper function   |
 |                                setContactUsURL.   
 |                                                                           |
 |       13-Jan-03   bchowdar     Modified                                   |
 |       30-May-03  albowicz      Modified for Attachments feature 2979312   |
 |    21-Oct-03  hikumar      Bug # 3186472 - Modified for URL security      |
 |    13-Jan-04  vnb          Bug # 3131362 - Modified for saving attachments|
 |                            'DomAttachAutoCommit' removed.                 |
 |                            Replaced by 'setAutoCommitEnabled' in          |
 |                            accountDetails/webui/SearchHeaderCO.java       |    
 |    26-Apr-04  vnb          Bug # 3467287 - The Transaction List button    |
 |							  will always remain enabled.                    |
 |    09-Dec-04  vnb          Bug 4057491 - Cross-site verification not      |
 |                            required when coming from workflow notification|
 |    10-Feb-05  rsinthre     Bug - 4162002 'ARI_SWITCH_CUST_CONTEXT_INSTR'  |
 |                            appears in the confirmation page               |
 |    19-Jul-05   rsinthre   Bug 4495145 - Setting inContext branding and    |
 |                           renaming disableLogoutButton                    |
 |    27-Sep-05   rsinthre   Bug 4621415 - Getting an error in navigating    |
 |                           to the Invoice Details page                     |
 |    28-oct-09  avepati  bug 9054556 - custmr detials are notshown in header|
 |    20-apr-10  avepati     Bug 9585019 -iRec Apply payments fails if no    |
 |                              customer context is set                      |
 |   12-May-2010  nkanchan bug # 9695691 - tst1213.xb1.qa:sql exception on    |
 |                               accessing 'pay within' related customer data |
 |  21-Jun-2010  nkanchan - 9795698 - CUSTOMER CONTEXT NOT GETTING CHANGED FROM TRANSACTION LIST |
 |  06-Aug-2010 nkanchan - Bug 9892323 - error in transactiontablevo -- accountdetailsam |
 |  24-Aug-2010 nkanchan - Bug 10048984name doesn't change back to null if view changed to all cust|
 |    18-Mar-11   nkanchan  Bug 11871875 - fp:9193514 :transaction     |
 |                           list disappears in ireceivables           |
 |  29-Feb-12   parln     Bug#13769019 - Cannot View Transaction Details WHEN|
 |                             Different Location on Receipt and invoice     |  
 +===========================================================================*/
package oracle.apps.ar.irec.framework.webui;

import oracle.apps.fnd.common.VersionInfo;

import java.io.Serializable;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.ar.irec.framework.webui.IROAControllerImpl;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.jbo.Row;
import oracle.jbo.ViewObject;
import oracle.apps.fnd.framework.webui.OADialogPage ;
import oracle.apps.fnd.common.MessageToken;

import oracle.cabo.ui.UIConstants;

import oracle.jdbc.OraclePreparedStatement;
import oracle.jdbc.OracleResultSet;

import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;
import oracle.apps.ar.irec.util.BusinessObjectsUtils;
import oracle.apps.fnd.framework.OAFwkConstants;

import oracle.jdbc.OracleCallableStatement;
import java.sql.Types;

/**
 * This class is the super class of all page level region controller objects
 * for iReceivables. It provides basic functionality that is required on page
 * level region controllers.
 *
 * List of functionality:
 * 1. default form submission - to use this functionality you need to override
 *    the getDefaultSubmitButton() method to provide the mapping between the
 *    form submitted and the default key that needs to be used.
 *    Once you use this API, you should be able to code the rest of your page
 *    level logic without regard to the way the submit key works.
 *    for an Example:
 *    @see oracle.apps.accountDetails.webui.AccountDetailsPageCO#getDgetDefaultSubmitButton(String)
 *
 * @author 	Mohammad Shoaib Jamall
 */

public abstract class PageCO  extends IROAControllerImpl
{

  public static final String RCS_ID="$Header: PageCO.java 120.16.12010000.13 2012/03/09 10:38:37 parln ship $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "oracle.apps.ar.irec.framework.webui");
  // Bug # 3412087  - hikumar
  private static String previousPageUrl = null ;
  private static String currentPageUrl = null ;

  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
    
     // brought code out of if for bug # 9695691
     previousPageUrl = currentPageUrl ;
     currentPageUrl = pageContext.getCurrentUrlForRedirect();
     
    pageContext.writeDiagnostics(this,"PageCO processRequest previousPageUrl " + previousPageUrl, 1);
    pageContext.writeDiagnostics(this,"PageCO processRequest currentPageUrl " + currentPageUrl, 1);
    
    String customerId    = pageContext.getDecryptedParameter(CUSTOMER_ID_KEY );
    String siteUseId     = pageContext.getDecryptedParameter(CUSTOMER_SITE_ID_KEY );

    pageContext.writeDiagnostics(this,"PageCO processRequest customerId " + customerId, 1);
    pageContext.writeDiagnostics(this,"PageCO processRequest siteUseId " + siteUseId, 1);

    if( customerId != null && siteUseId != null)
    {
      getActiveCustomerId(pageContext, customerId);
      getActiveCustomerUseId(pageContext, siteUseId);
    }

    pageContext.writeDiagnostics(this,"PageCO processRequest customerId 2 " + customerId, 1);
    pageContext.writeDiagnostics(this,"PageCO processRequest custSiteUseId 2 " + siteUseId, 1);
    
    //Bug 4621415 - Set CustomerContext information only when not printable page.
    if(!isPrintablePageMode(pageContext))
    {
      // These functions have the side effect of setting the CustomerId
    // and Use Id which is necessary for many of the details pages to work properly.
    // Bug # 3186472 - hikumar
    // Modified to replace getParameter with getDecryptedParameter
      
//      if( customerId != null)
  //      getActiveCustomerId(pageContext, customerId);
        
      if( customerId != null && siteUseId != null)
      {
        getActiveCustomerId(pageContext, customerId);
        getActiveCustomerUseId(pageContext, siteUseId);
//        setCustomerInformation(pageContext, webBean, customerId, siteUseId);
      }
      /* Commented for bug # 10048984
      //Bug 9054556 - Customer Header details are not refreshed
      String custId = getActiveCustomerId(pageContext);
      String custSiteUseId =  getActiveCustomerUseId(pageContext);
      setCustomerInformation(pageContext, webBean,custId ,custSiteUseId); */
      
      //setContactUsURL(pageContext, webBean);
    }
    // Brought down this code for bug 10048984
    //Bug 9054556 - Customer Header details are not refreshed
    String custId = getActiveCustomerId(pageContext);
    String custSiteUseId =  getActiveCustomerUseId(pageContext);
    String strCurrencyCode = (String)getActiveCurrencyCode(pageContext, pageContext.getParameter( CURRENCY_CODE_KEY ));
    
    pageContext.writeDiagnostics(this,"PageCO processRequest custId " + custId, 1);
    pageContext.writeDiagnostics(this,"PageCO processRequest custSiteUseId " + custSiteUseId, 1);
    pageContext.writeDiagnostics(this,"PageCO processRequest strCurrencyCode " + strCurrencyCode, 1);

    if (custId == null)
      custId = (String)pageContext.getSessionValue("Ircustomerid");
    if (custSiteUseId == null)
      custSiteUseId = (String)pageContext.getSessionValue("Ircustomersiteuseid");
    pageContext.writeDiagnostics(this,"PageCO processRequest custId " + custId, 1);
    pageContext.writeDiagnostics(this,"PageCO processRequest custSiteUseId " + custSiteUseId, 1);


    //String strLargeCust = isLargeCustomer( pageContext, webBean, custId);
    
    if( custId != null)
      pageContext.putSessionValue("Ircustomerid",custId);    
    if( custSiteUseId != null)
      pageContext.putSessionValue("Ircustomersiteuseid",custSiteUseId);    
    if( strCurrencyCode != null)
      pageContext.putSessionValue("Irorgid",strCurrencyCode);    
  

    //pageContext.writeDiagnostics(this,"PageCO processRequest strLargeCust " + strLargeCust, 1);
    //if( "N".equals(strLargeCust))
     crossAccountTransaction(pageContext , webBean);

    
    String icxPrintablePageButton = pageContext.getParameter("IcxPrintablePageButton");
    String oarf = pageContext.getParameter("OARF");
    if(icxPrintablePageButton == null && oarf == null)
      setCustomerInformation(pageContext, webBean,custId ,custSiteUseId);
    //13-Jan-03 - BCHOWDAR - Changes
      
      
    // Bug# 3467287 - The Transaction List global button
    // will always remain enabled.      
    //Bug3098364:
    
    /*
     * if (pageContext.getSessionValue("RecordsInTransactionList") == "YES" )
      setTransactionListGlobalButton(pageContext,false);
    else
      setTransactionListGlobalButton(pageContext,false); 
    */
    
       
    handlePrintablePage(pageContext);
  }

  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormRequest(pageContext, webBean);
    
    handlePrintablePage(pageContext);
  }

  public void processFormData(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormData(pageContext, webBean);

    String defaultKey = getDefaultSubmitButton(pageContext.getFormSubmitName());
    if (null != defaultKey)
    {
      // if the form submit has happened as a result of the 'Enter' key being pressed.
      if ( "".equals(pageContext.getParameter("event")) &&
           ("".equals(pageContext.getParameter("_FORMEVENT"))) )
      {
        pageContext.putParameter(defaultKey, "");
      }
    }

  }

  /**
   * Provide the mapping from form submitted to default form submit key to be used.
   * This is to be used to default a form submit button in the case when an enter
   * key is pressed.
   * for Example:
   * @see oracle.apps.ar.irec.accountDetails.webui.AccountDetailsPageCO#getDgetDefaultSubmitButton(String)
   */
  protected String getDefaultSubmitButton(String formName)
  {
    return null;
  }

  private void handlePrintablePage(OAPageContext pageContext)
  {
    //Bug 4621415 - rsinthre
    if (isPrintablePageMode(pageContext)) {
      String icxPrintablePageButton = pageContext.getParameter("IcxPrintablePageButton");
      String oarf = pageContext.getParameter("OARF");
    // Bug 9892323 - nkanchan - Eventhough the isPrintablePageMode returns true, we have one scenario i.e 
    //when grouoping of accounts enabled and navigated with all Customers we should not release AM
    // So we are releasing AM if below condition satisfies.  
      if(icxPrintablePageButton != null || oarf != null) {
        pageContext.releaseRootApplicationModule();
        pageContext.putSessionValue("Requery","Y");
      }
    }
  }

  protected void nullOutMenusIfNoCustomerInfoInSession
    (OAPageContext pageContext, OAWebBean webBean)
  {
        try
    {
      // Bug # 3186472 - hikumar
      // Modified to replace getParameter with getDecryptedParameter
      getActiveCustomerId(pageContext, pageContext.getDecryptedParameter( CUSTOMER_ID_KEY ));
      getActiveCustomerUseId(pageContext,
                             pageContext.getDecryptedParameter( CUSTOMER_SITE_ID_KEY ));
    }
    catch(OAException ex)
    {
      pageContext.resetMenuContext(null);
    }

  }

    public abstract String getQueryString(OAPageContext pageContext );

  public void crossAccountTransaction(OAPageContext pageContext , OAWebBean webBean )
  {

    String sCustomerId = pageContext.getDecryptedParameter(CUSTOMER_ID_KEY);
    String sCustomerSiteUseId = pageContext.getDecryptedParameter(CUSTOMER_SITE_ID_KEY);

    //Bug 4057491 - When coming from workflow notification,
    //there is no value for customer id and customer site id,
    //but there is no verification required in that case also
    String ntfId = pageContext.getParameter("NtfId");
    // Added for bug # 9795698 - Customer context switching
      OAApplicationModule am = ( OAApplicationModule) pageContext.getApplicationModule(webBean) ;
      //Uncommented and made changes  for bug # 10058402
      //Commented for bugs # 10053227 and 10052911
      boolean isCustContextChanged = isCustomerContextChanged(pageContext);
      if(isCustContextChanged) {
          // Bug 11871875 - nkanchan - 
          pageContext.putSessionValue("Requery","Y");
          
          String isInternalCustomer=(isInternalCustomer(pageContext,webBean))?"Y":"N";
          Long sessionID=new Long(pageContext.getSessionId());
          Long custId = (sCustomerId==null) ? null : new Long(sCustomerId);          
          boolean relCustContextSwitch = false;//relExtCustContextSwitch(sCustomerId);
          OADBTransaction txn = am.getOADBTransaction();
          OracleResultSet rs = null;
          OraclePreparedStatement pStmt = null;
          String queryString = "select * from ar_irec_user_acct_sites_all where customer_id="+sCustomerId+" and session_id="+sessionID;
          try
          {
             pStmt =  (OraclePreparedStatement)txn.createPreparedStatement(queryString,1);
             pStmt.execute();
             rs = (OracleResultSet)pStmt.getResultSet();
             if ( rs.next() )
               relCustContextSwitch = false;
             else
               relCustContextSwitch = true;
        
           }catch(Exception e)    {  throw OAException.wrapperException(e);  }
           finally 
           {
              try { if(rs != null) rs.close();
                  if(pStmt != null) pStmt.close(); 
              }
              catch(Exception e)  { throw OAException.wrapperException(e);   }
           }

          if("Y".equals(isInternalCustomer) || relCustContextSwitch) {
            String personPartyID = (String)pageContext.getSessionValue("CUSTOMER_SEARCH_PERSON_ID");
            Long partyID=((personPartyID==null ||"".equals(personPartyID)) ? null : new Long(personPartyID));
            String sOrgContext = getActiveOrgId(pageContext);
            Long orgID=  (sOrgContext==null) ? null : new Long(sOrgContext);
            Long userID=new Long(pageContext.getUserId());
            Long custSiteUseId = (sCustomerSiteUseId==null) ? null : new Long(sCustomerSiteUseId);            
            String eventName = pageContext.getParameter(UIConstants.EVENT_PARAM);
            String acctGroupOption = pageContext.getProfile("OIR_ACCOUNT_GROUPING");
            String isAccountGroup = (("groupAccountEvent".equals(eventName))
                                    ||"ALWAYS_GROUP".equals(acctGroupOption)) ?"Y":"N";

          Serializable[] params = {partyID,orgID,userID,sessionID,custId,custSiteUseId,isInternalCustomer,isAccountGroup};
          am.invokeMethod("initAccountsAndSites",params,getInitAccountSitesClassParam(pageContext,webBean));
          }
      }
    //if ( sCustomerId !=null || sCustomerSiteUseId != null || ntfId != null)
    //nkanchan - Modified for bug # 9695691
     if ( (sCustomerId !=null && !"".equals(sCustomerId))|| sCustomerSiteUseId != null || ntfId != null)
        return ; // If either customer Id or Customer Site Use Id is present in URL
              // then no need to do any verification and return

    String queryString = getQueryString (pageContext) ;
    if ( queryString == null ) 
      return ;     // This is a error condition , the code should not return here
    
    String activeCustomerId = getActiveCustomerId(pageContext );
    String activeCustomerSiteId = getActiveCustomerUseId(pageContext);

    String trxCustomerId = null ;
    String trxCustomerSiteId = null ;
    Row row = null ;


    ViewObject customerContextVo = null ;

    
    customerContextVo = (ViewObject) am.createViewObjectFromQueryStmt(null , queryString );
    customerContextVo.executeQuery();

    //Bug	4057491 - When customer site id is null, handle the scenario
    if(customerContextVo.hasNext())
     {
        row = customerContextVo.next();
        trxCustomerId = row.getAttribute(0).toString() ;
        Object customerSiteId = row.getAttribute(1);
        if (customerSiteId != null)
          trxCustomerSiteId = customerSiteId.toString();
     }
   
     customerContextVo.remove(); 
    
    
    if( ! compareString(activeCustomerId , trxCustomerId ) || 
                ( !"".equals(activeCustomerSiteId) && activeCustomerSiteId !=null &&  !compareString(activeCustomerSiteId , trxCustomerSiteId ) ))
    {
       // if the customer id or site id of current transaction is different from 
       // the active customer id or customer site id
       String trxCustName ;
       String trxCustLocation ;
       String activeCustName ;
       String activeCustLocation ;

       OAViewObject custVO =  (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("CustomerInformationVO");

        {
          Serializable [] params = { trxCustomerId, trxCustomerSiteId };
          custVO.invokeMethod("initQuery", params);
         // get Trx Customer Name Name
          Serializable [] paramName = { "CustomerName" };
          Serializable [] paramLoc = { "Location" };
          trxCustName = (String)custVO.invokeMethod("getFirstObject", paramName);
          trxCustLocation = (String)custVO.invokeMethod("getFirstObject", paramLoc);
        }

        {
          Serializable [] params = { activeCustomerId, activeCustomerSiteId };
          custVO.invokeMethod("initQuery", params);
         // get Trx Customer Name Name
          Serializable [] paramName = { "CustomerName" };
          Serializable [] paramLoc = { "Location" };
          activeCustName = (String)custVO.invokeMethod("getFirstObject", paramName);
          activeCustLocation = (String)custVO.invokeMethod("getFirstObject", paramLoc);
        }

       MessageToken [] msgToken = new MessageToken[] {
                            new MessageToken("ACTIVE_CUST_NAME", activeCustName),
                            new MessageToken("ACTIVE_CUST_LOCATION", activeCustLocation),
                            new MessageToken("TRANS_CUST_NAME", trxCustName),
                            new MessageToken("TRANS_CUST_LOCATION", trxCustLocation) };
      

       String descMessage = pageContext.getMessage("AR" , "ARI_SWITCH_CUST_CONTEXT_DESC" , msgToken );
              
       OAException descExcMsg = new OAException(descMessage) ;
       //Bug 4162002 - 'ARI_SWITCH_CUST_CONTEXT_INSTR' appears in the confirmation page
       OAException instExcMsg = new OAException(pageContext.getMessage("AR","ARI_SWITCH_CUST_CONTEXT_INFO",null) );
        String okButtonUrl;
	//Bug#13769019- if trxCustomerSiteId is null do not encrypt this value as it fails to encrypt if null.
       if(trxCustomerSiteId!=null)
       {
       okButtonUrl = pageContext.getCurrentUrlForRedirect() + "&Ircustomerid={!!"+pageContext.encrypt(trxCustomerId) +"}"+
                              "&Ircustomersiteuseid={!!"+pageContext.encrypt(trxCustomerSiteId)+"}"+"&isCustomerContextChanged={!!"+pageContext.encrypt("Y")+"}";
       }
       else{
      okButtonUrl = pageContext.getCurrentUrlForRedirect() + "&Ircustomerid={!!"+pageContext.encrypt(trxCustomerId) +"}"+
                            "&isCustomerContextChanged={!!"+pageContext.encrypt("Y")+"}";
       }
       OADialogPage confirmPage = new OADialogPage( OAException.CONFIRMATION ,  descExcMsg , instExcMsg ,
                                                      okButtonUrl , previousPageUrl );

       pageContext.redirectToDialogPage(confirmPage);

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

  
}
