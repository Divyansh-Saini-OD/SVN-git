package oracle.apps.ar.irec.accountDetails.webui;


import oracle.apps.fnd.common.VersionInfo;
import java.lang.StringBuffer;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.ar.irec.framework.webui.PageCO;
import com.sun.java.util.collections.HashMap ;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.OAException;
import java.util.Date;
import java.text.SimpleDateFormat;
import java.text.DateFormat;

import java.io.Serializable;

import oracle.jbo.domain.Number;

/*----------------------------------------------------------------------------
 -- Author: Sridevi Kondoju
 -- Component Id: E1327 and E2052
 -- Script Location: $XXCOMN_TOP/oracle/apps/ar/irec/accountDetails/webui
 -- Description: Considered R12 code version and added custom code.
 -- History:
 -- Name            Date         Version    Description
 -- -----           -----        -------    -----------
 -- Sridevi Kondoju 4-Aug-2016  1.0        Retrofitted for R12.2.5 Upgrade.
 -- Havish Kasina  31-Mar-2017  2.0        Added for the Defect 41179
---------------------------------------------------------------------------*/
/*===========================================================================+
 |      Copyright (c) 2000, 2014 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 |       14-Aug-00  sjamall       Created.                                   |
 |       20-Mar-01  sjamall + aizadpan  Comments added                       |
 |       05-Apr-01  krmenon       Moved logic from SearchHeaderCO to display |
 |                                proper header. (As per UI changes)         |
 |                                Added a new region to display the balances |
 |       25-Jun-01  sjamalll      bugfix 1824217 : workaround : Added and    |
 |                                started using static method getParameter   |
 |                                this method will append '_ext' to parameter|
 |                                if getParameter(<parameter>) returned a    |
 |                                null. the assumption is that coming into   |
 |                                the page from the outside we are going to  |
 |                                get <parameter>_ext instead of <parameter> |
 |                                passed in the url.                         |
 |       12-Jul-01  sjamall       bugfix 1879315 : subclassing from PageCO   |
 |                                and overriding method                      |
 |                                getDefaultSubmitButton(String)             |
 |       10-Sep-01  sjamall       bugfix 1788892                             |
 |       06-may-02  yreddy        Bugfix 2272203: Append "," to the string   |
 |                                when the parameter is null .               |
 |       19-Aug-02  albowicz      Modified for bug 1658316.  The e-mail      |
 |                                address used by the Contact Us Icon is now |
 |                                configurable by the implementor. This file |
 |                                was modified to return the Page Name which |
 |                                is passed as part of the API provided in   |
 |                                ARI_CONFIG.                                |
 |       26-Oct-02  albowicz      Online Aging -- Added Balances Region      |
 |       13-Jan-03  bchowdar      Modified                                   |
 |       08-May-03  albowicz      Modified for Export Feature                |
 |       20-May-03  hikumar       Bug # 2967730 - Export button not working  |
 |                                after Browser Back Button                  |
 |       20-May-03  albowicz      Modified code to set parameters to the     | 
 |                                saved parameters for back button case.     |
 |       10-June-03  hikumar      Modified for Custom Transaction Search     |
 |                                Feature Bug # 3000512                      |
 |       23-Jun-03   yreddy       Bug3019729: MultiplePay functionality      |
 |       03-Jul-03   albowicz     Bug3037819: Changed function name for      |
 |                                redirect to ARIACCOUNT.                    |
 |    14-Aug-03   hikumar      Bug # 3098364 : Multiple Transaction          |
 |                                Operations Functionality                   |
 |       8-Oct-03   hikumar  Bug # 3182247 - To make region label            |
 |                             customizable                                  |
 |      21-Oct-03   hikumar       Bug # 3186472 - Added function             |
 |                                getDecryptedParameter()                    |
 |    19-Nov-03  hikumar      Bug # 3266491 - ATG Remove Results Header from |
 |                            Results Region                                 |
 |    26-Apr-04   vnb        Bug # 3467287 - Customer and Customer Site ID   |
 |							 appended to Transaction List global button URL  |
 |    20-May-04   vnb        Bug # 3585876 - Multi-Print Confirmation Message|
 |    14-Jun-04   vnb        Bug # 3458134 - Added a new region for Discount |
 |							 Invoices on Account Details page                |
 |    01-Oct-04   vnb        Bug 3922771 - Set the search params in the URL  |
 |    01-Oct-04   vnb          Bug 3933606 - Multi-Print Enhancement         |
 |    07-Dec-04   rsinthre   Bug 4017887 - Forward port bug 4017823 on OIR.G |
 |    24-May-05  vnb         Bug 4197060 - MOAC Uptake                       |
 |    08-Jun-05  vnb         Bug 4417906 - Cust Label has extra line spacing |
 |    19-Jul-05   rsinthre   Bug 4495145 - Setting inContext branding and    |
 |                           renaming disableLogoutButton                    |
 |      22-Jul-05   rsinthre     Bug 4508705 - ATG: R12: REMOVE DEPRECATED APIS|
 |  20-Sep-05  rsinthre   Bug # 4604121 - Unable to add payments to          |
 |                        transaction list in r12 sep drop                   |
 |   28-Feb-08 avepati       Bug 6748005 - ADS12.0.03 :FIN:NEED CONSOLIDATED |
 |                             NUMBER FILTER ON ACCOUNT DETAILS PAGE         |
 |   27-Mar-2010 nkanchan Bug # 9596820 - page displays 'all locatns' data although user has selected 1 org |
 |       31-Jan-11  avepati     Bug 7154650-Support Multiple Dispute feature |
 |    17-Mar-11   nkanchan  Bug 11871875 - fp:9193514 :transaction     |
 |                           list disappears in ireceivables           |
 |   27-Apr-11 nkanchan Bug # 11871930 - fp:10151772:provide multi transaction search in account details page|
 |   10-Dec-12 shvimal  Bug 15934955 - ACCOUNT SUMMARY SCREEN STATUS DEFAULTS TO ANY STATUS INSTEAD OF OPEN |
 |   18-Apr-12 shvimal Bug 16626666 - GSIAP: ACC DETAILS PAGE DEFAULT TRANSACTION TYPE SHOULD BE ALL TRANSACTIONS |
 |   08-Jul-13 shvimal Bug 16355174 - IRECEIVABLES ISSUE: PAY BUTTON SPORADICALLY MISSING |
 |   02-Jul-14 melapaku Bug 19075248 - Pay button disappears when you        |
 |                            pay from invoice detail and cancel             |
 +===========================================================================*/

/**
 * details for account details.
 * lays out the basic <search> and <results> regions in a Stack.
 * @author 	Mohammad Shoaib Jamall
 */

public class AccountDetailsPageCO extends PageCO
{

  public static final String RCS_ID="$Header: AccountDetailsPageCO.java 120.43.12020000.5 2014/07/03 07:15:24 melapaku ship $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "oracle.apps.ar.irec.accountDetails.webui");

  // This static varible serves as a timestamp.  This timestamp is incremented and 
  // added to the url every time the page renders.  This forces
  // the framework to consider each page render as unique and
  // force the processRequest method to be called.
  static int searchnum = 0 ;  

  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
	 pageContext.writeDiagnostics(this, "XXOD: processRequest", 1);

    if(!"Y".equals(pageContext.getSessionValue("releaseListenerAdded"))) // Bug 10095174
    {
      pageContext.addReleaseListener("oracle.apps.ar.irec.accountDetails.AccountDetailsReleaseListener");
      pageContext.putSessionValue("releaseListenerAdded", "Y");
    }

    String   releaseAccountDetailsAM = (String)pageContext.getSessionValue("RELEASE_ACCT_DTL_AM");
    
    if("Y".equals(releaseAccountDetailsAM)) // Bug 10095174
    {
      HashMap hmpar = getPageParameters(pageContext);
      pageContext.releaseRootApplicationModule();
      pageContext.removeSessionValue("RELEASE_ACCT_DTL_AM");
      pageContext.removeParameter("Requery");
      pageContext.removeSessionValue("Requery");
      pageContext.removeParameter("fromHomePage");
      pageContext.putSessionValue("Iracctdtlskeyword", "");

      pageContext.putParameter("AcctDtlPageRefresh","Y"); 
      pageContext.putParameter("IracctDiscInvoices",""); 
      pageContext.removeSessionValue("IracctDiscInvoices"); 
      pageContext.forwardImmediately("ARIACCOUNT", OAWebBeanConstants.KEEP_MENU_CONTEXT, null, hmpar, true, ADD_BREAD_CRUMB_SAVE);      
    }
    
    String requeryAcctDtls = pageContext.getParameter("fromHomePage");
        if(requeryAcctDtls ==null || "".equals(requeryAcctDtls))
        requeryAcctDtls = (String)pageContext.getSessionValue("Requery");
        
        if("Y".equals(requeryAcctDtls)) 
        {
            String empty="";
            HashMap hmpar = new HashMap();
            pageContext.removeParameter("Requery");
            pageContext.removeSessionValue("Requery");
            // when navigating from home page by clicking on balances links or discount invoices/credit requests
            // full list button need to empty the keywordList stored in seesion and requery account details
            pageContext.putSessionValue("Iracctdtlskeyword", empty);
            pageContext.removeSessionValue("IracctDiscInvoices"); 
            pageContext.removeParameter("fromHomePage");
      
            pageContext.putSessionValue("RETURN_ACCT_DETAILS_LINK_STATUS", empty);
            pageContext.putSessionValue("RETURN_ACCT_DETAILS_LINK_TYPE", empty);
            pageContext.putSessionValue("RETURN_ACCT_DETAILS_LINK_CURRENCY", empty);
            pageContext.putSessionValue("RETURN_ACCT_DETAILS_LINK_KEYWORD", empty);
            pageContext.putSessionValue("RETURN_ACCT_DETAILS_LINK_AMTFROM", empty);
            pageContext.putSessionValue("RETURN_ACCT_DETAILS_LINK_AMTTO", empty);
            pageContext.putSessionValue("RETURN_ACCT_DETAILS_LINK_TRXDATEFROM", empty);
            pageContext.putSessionValue("RETURN_ACCT_DETAILS_LINK_TRXDATETO", empty);
            pageContext.putSessionValue("RETURN_ACCT_DETAILS_LINK_DUEDATEFROM", empty);
            pageContext.putSessionValue("RETURN_ACCT_DETAILS_LINK_DUEDATETO", empty);
            pageContext.putSessionValue("RETURN_ACCT_DETAILS_LINK_SALESORDER", empty);
        }

        //  when discount alerts are accessed first and if navigating to acct details by
      // clicking on account tab/return to acct details lnk should all ways requery account details.
        String discInvoices = (String)pageContext.getSessionValue("IracctDiscInvoices");
        if("Y".equals(discInvoices)) 
        {
            pageContext.removeParameter("Requery");
            pageContext.removeSessionValue("Requery");
        }
        
           
     //Initialise Multi-Org and policy context
     setMultiOrgPolicyContext(pageContext, webBean);
    
    if( AccountDetailsBaseCO.isBrowserBackButton(pageContext) )
      restorePageParameters(pageContext, webBean);
      
    String acctDtlPageRefresh = pageContext.getParameter("AcctDtlPageRefresh");
    if(! "Y".equals(acctDtlPageRefresh))
      checkSavedSearchCriteria(pageContext, webBean);

    /* Bug # 3744935 - Two forms on page cause buttons stop working
     * 
    OAFormBean formBean = (OAFormBean) createWebBean(pageContext, FORM_BEAN, null, null);
    webBean.addIndexedChild(formBean);
    */

    /**
    * get company name and location from the transaction cache and
    * display it as part of the header label for the Search Region.
    * OACTECH needs to debug this part.
    */
    // Bug # 3182247 - hikumar
    // Commented out programmatically setting of Account Details Page Label
    /*String companyName = getCompanySiteString (pageContext, webBean,

                     getActiveCustomerId(pageContext,
                         getParameter(pageContext, CUSTOMER_ID_KEY )),
                     getActiveCustomerUseId(pageContext,
                         getParameter( pageContext, CUSTOMER_SITE_ID_KEY )));


  //    String companyLabel = webBean.getLabel() + companyName;
    String companyLabel = ((OAHeaderBean)webBean).getText(pageContext) + companyName;

    // webBean.setLabel(companyLabel); 
    ((OAHeaderBean)webBean).setText(pageContext, companyLabel); */

    //Add a stack layout to the page
    /*OAStackLayoutBean stackLayout =
      (OAStackLayoutBean) createWebBean(pageContext, STACK_LAYOUT_BEAN, null, null);
    webBean.addIndexedChild(stackLayout);

    //add total region

  stackLayout.addIndexedChild(createWebBean(pageContext,
                                              webBean,
                                              "AriAccountBalances"));

    // add search region
    stackLayout.addIndexedChild(createWebBean(pageContext,
                                              webBean,
                                              "Ariacctdtlsearch"));*/
    
    /**
     * bugfix 1868785 : sjamall : adjust parameters SearchHeaderCO.GO_CONTROL,
     * SearchHeaderCO.TRANSACTION_TYPE
     */  
    // Bug 15934955 - Set default status to Open/Pending on AccountDetails Page
     String trx_status_from_session  = (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_STATUS"); 
     String trx_status = AccountDetailsPageCO.getParameter(pageContext, SearchHeaderCO.TRANSACTION_STATUS);     
     
     String trx_type_from_session   = (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_TYPE");
     String trx_type = AccountDetailsPageCO.getParameter(pageContext, SearchHeaderCO.TRANSACTION_TYPE);
    
    String go =
      pageContext.getParameter(SearchHeaderCO.GO_CONTROL);
    if (null == go)
      go = pageContext.getParameter(SearchHeaderCO.GO_CONTROL + "_ext");
    if (null != go)
      pageContext.putParameter(SearchHeaderCO.GO_CONTROL, go);
    
    String type =
      pageContext.getParameter(SearchHeaderCO.TRANSACTION_TYPE);
    if (null == type)
      type = pageContext.getParameter(SearchHeaderCO.TRANSACTION_TYPE + "_ext");   
    /*if(null == type && isNullString(trx_type_from_session) && isNullString(trx_type))
       type = "ALL_DEBIT_TRX";*/   // Bug 16626666 - Default Transaction Type from Accounts Tab should be All Transactions
    if (null != type)
      pageContext.putParameter(SearchHeaderCO.TRANSACTION_TYPE, type);   
    
    //Bug 4017887 - Forward port bug 4017823 on OIR.G
    String status = pageContext.getParameter(SearchHeaderCO.TRANSACTION_STATUS);
    if (null == status)
      status = pageContext.getParameter(SearchHeaderCO.TRANSACTION_STATUS + "_ext");   
    if(null == status && isNullString(trx_status_from_session) && isNullString(trx_status))
      status = "OPEN";
    if (null != status)
      pageContext.putParameter(SearchHeaderCO.TRANSACTION_STATUS, status);
      
    //Bug 5649716 - Set Customer context info in a parameters
    String currentCustContext = pageContext.getParameter("CustomerContextList");
    if (null == currentCustContext)
      currentCustContext = pageContext.getParameter("CustomerContextList_ext");
    if (null != currentCustContext)
      pageContext.putParameter("CustomerContextList", currentCustContext);
      
    //This will get the Related Customer Name 
    String irSelectCustomer = pageContext.getParameter("IrSelectCustomer");
    if(null == irSelectCustomer)
      irSelectCustomer = pageContext.getParameter("IrSelectCustomer_ext");
    if(irSelectCustomer!=null)     
        pageContext.putParameter("IrSelectCustomer", irSelectCustomer);
    //This will get the Related Customer Id
    String searchRelCustomerValue = pageContext.getParameter("SearchRelCustomerValue");
    if(null == searchRelCustomerValue)
      searchRelCustomerValue = pageContext.getParameter("SearchRelCustomerValue_ext");
    if(searchRelCustomerValue!=null)     
        pageContext.putParameter("SearchRelCustomerValue", searchRelCustomerValue);
      
    setExtraQuery(pageContext);

    String restrict =
      pageContext.getParameter(SearchHeaderCO.RESTRICT_ACCT_DETAILS);
    if (!("true".equals(restrict)))
      restrict = "false";

      setValueInSession(pageContext, SearchHeaderCO.RESTRICT_ACCT_DETAILS,
                           restrict);

      //Bug 4508705 - Removed Deprecated api setSelectedFunction(String) and replaced with OAPageContext.resetMenuContext(String)
      pageContext.resetMenuContext("ARIACCOUNT");
	  /* Start - 16Dec2014 - Added for iRec Enhancement changes */
        pageContext.writeDiagnostics(this, "XXOD: init current customer context", 1);
        super.initCurrentCustomerContext(pageContext, webBean);

        pageContext.writeDiagnostics(this, "XXOD: handle menu and customer branding",
                              1);
        OAApplicationModule am = pageContext.getApplicationModule(webBean);
        String customerId = null;
        String customerSiteUseId = null;

        customerId = pageContext.getDecryptedParameter(CUSTOMER_ID_KEY);
        customerSiteUseId = pageContext.getDecryptedParameter(CUSTOMER_SITE_ID_KEY);

        pageContext.writeDiagnostics(this, "XXOD: customerId" + customerId, 1);
       pageContext.writeDiagnostics(this,
                              "XXOD: customerSiteUseId" + customerSiteUseId,
                              1);
        if (customerId == null) {

            pageContext.writeDiagnostics(this, "XXOD: inside if customer id null", 1);
            customerId = getActiveCustomerId(pageContext);
            customerSiteUseId = getActiveCustomerUseId(pageContext);

            pageContext.writeDiagnostics(this, "XXOD: customerId**" + customerId, 1);
            pageContext.writeDiagnostics(this,
                                  "XXOD: customerSiteUseId**" + customerSiteUseId,
                                  1);

            if (customerId != null && !"".equals(customerId)) {
                OAViewObject custVO =
                    (OAViewObject)pageContext.getRootApplicationModule().findViewObject("CustomerInformationVO");
                Serializable[] param = { customerId, customerSiteUseId };
                custVO.invokeMethod("initQuery", param);
                pageContext.writeDiagnostics(this,
                                      "XXOD: after customer information vo query" +
                                      customerId, 1);

            }
        }
        // the framework returns a '{}' for parameters when they have
        // a null value and they are encrypted out of the database.
        // see bug 1718439
        if (customerId != null) {
            pageContext.writeDiagnostics(this,
                                  "XXOD: inside if customerid not null**", 1);

            try {
                Number customerIdNumber = new Number(customerId);
            } catch (Exception e) {
                customerId = null;
            }
        }
        if (customerSiteUseId != null) {
            pageContext.writeDiagnostics(this,
                                  "XXOD: inside if customersiteuseid not null**",
                                  1);
            // bugfix 1772584 : customer site use id being changed to "~"
            // so that it can be set to "" in the session cache in the
            // call to getActiveCustomerUseId(pageContext, customerSiteUseId)
            try {
                Number customerSiteUseIdNumber = new Number(customerSiteUseId);
            } catch (Exception e) {
                customerSiteUseId = "~";
            }
        }

        if (!(isNullString(customerId))) {
            getActiveCustomerId(pageContext, customerId);
            // bugfix 1772584 : customer site use id being updated
            // whenever the customerId is non-null
            if (null != customerSiteUseId)
                customerSiteUseId =
                        getActiveCustomerUseId(pageContext, customerSiteUseId);
        }
        // Added for bug # 10048984

        pageContext.writeDiagnostics(this, "XXOD: customerId==**" + customerId, 1);
        pageContext.writeDiagnostics(this,
                              "XXOD: customerSiteUseId==**" + customerSiteUseId,
                              1);

        setCustomerInformation(pageContext, webBean, customerId, customerSiteUseId);

        /* End - 16Dec2014 - Added for iRec Enhancement changes */
    
      //Added for bug # 9596820
      super.initCurrentCustomerContext(pageContext, webBean);
   
   	  handleMenusAndCustomerBranding(pageContext, webBean);
      setContactUsURL(pageContext, webBean);
      
	  //Bug#3467287 - Customer and Customer Site appended to Transaction List global button URL
      appendParamstoTransactionListUrl(pageContext);
      
     //Bug#3467287 - The Transaction List button will always remain enabled.
    //Bug3098364:
    /*if (pageContext.getSessionValue("RecordsInTransactionList") == "YES" )
      setTransactionListGlobalButton(pageContext,false);
    else
      setTransactionListGlobalButton(pageContext,true);
    */
    
    // Show confirmation message.
    //Bug 3585876-Multi-Print Confirmation Message
    //The Print Request IDs are retrieved to be displayed in the confirmation message
    //Bug 3933606 - Multi-Print Enhancement - confirmation message on the Account Details page not reqd
    /*String sPrintRequest = (String)pageContext.getSessionValue("PrintRequest");
    if ((sPrintRequest != null) && !(sPrintRequest.equals("")))
    {
      OAException message1 = new OAException("AR",
                                            "ARI_PRINT_CONFIRMATION_MSG",
                                            null,
                                            OAException.CONFIRMATION,
                                            null); 
      pageContext.putDialogMessage(message1);

      MessageToken [] msgToken = new MessageToken[] {
                            new MessageToken("PRINT_REQUESTS", sPrintRequest)};
      OAException message2 = new OAException("AR",
                                            "ARI_PRINT_REQUEST_NOTIFICATION",
                                            msgToken,
                                            OAException.CONFIRMATION,
                                            null);
      pageContext.putDialogMessage(message2);
                            
      pageContext.putSessionValue("PrintRequest","");
    }*/
    
//    String acctPayingPageName = pageContext.getParameter("Iracctpagename");
//    
//    if("ARI_ACCT_DTLS_PAYING_ACCT".equals(acctPayingPageName) && irSelectCustomer ==null) 
//    {
//      pageContext.putParameter(SearchHeaderCO.TRANSACTION_TYPE, null);
//      pageContext.putParameter("Iracctpagename", null);
//    } 
      // Bug 16355174 - Clear Transaction List if Payment is Cancelled from Pay Button click
      String paymentCancelled = pageContext.getParameter("PaymentCancelled");
      //Added for Bug 19075248
      if(paymentCancelled == null || "".equals(paymentCancelled)){
        paymentCancelled = (String)pageContext.getSessionValue("PaymentCancelled");
        pageContext.removeSessionValue("PaymentCancelled");
      }
      if("Y".equals(paymentCancelled) && isRecordInTransactionList(pageContext)) 
      {  
           clearTransactionList(pageContext);
           pageContext.putSessionValue("TransactionListCleared", "Yes");
        
      }
  
  }

  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
	  
	// Added for the Defect 41179 --> when in Account Details Page, if user selects to search for ""Any"" status and ""All"" transactions,then throw a warning message
	pageContext.writeDiagnostics(this, "AccountDetailsPageCO.PR() - After Super PR()", 1);
	
    String goParam = pageContext.getParameter(SearchRegionCO.GO_CONTROL);
	String sXXTransactions   = getParameter(pageContext, "XXTransactions");
	String sXXShipToIDValue  = getParameter(pageContext, "XXShipToIDValue");
	String sXXConsBill       = getParameter(pageContext, "XXConsBill");
	String sXXPurchaseOrder  = getParameter(pageContext, "XXPurchaseOrder");
	String sXXDept           = getParameter(pageContext, "XXDept");
	String sXXDesktop        = getParameter(pageContext, "XXDesktop");
	String sXXRelease        = getParameter(pageContext, "XXRelease");
	pageContext.writeDiagnostics(this, "AccountDetailsPageCO.PR() - Transaction Number "+sXXTransactions, 1);
	String type         = getParameter(pageContext, SearchHeaderCO.TRANSACTION_TYPE);
    String status       = getParameter(pageContext, SearchHeaderCO.TRANSACTION_STATUS);
	String trxDateFrom  = getParameter(pageContext, "Aritransdatefrom");
    String trxDateTo    = getParameter(pageContext, "Aritransdateto");
	String amountFrom   = getParameter(pageContext, "Ariamountfrom");
    String amountTo     = getParameter(pageContext, "Ariamountto");
    String dueDateFrom  = getParameter(pageContext, "Ariduedatefrom");
    String dueDateTo    = getParameter(pageContext, "Ariduedateto");
	
	pageContext.writeDiagnostics(this, "AccountDetailsPageCO.PR() - Transaction Type "+type, 1);
	pageContext.writeDiagnostics(this, "AccountDetailsPageCO.PR() - Transaction Status "+status, 1); 
	pageContext.writeDiagnostics(this, "AccountDetailsPageCO.PR() - Transaction Date From "+trxDateFrom, 1);
	pageContext.writeDiagnostics(this, "AccountDetailsPageCO.PR() - Transaction Date To "+trxDateTo, 1);

    if(goParam != null) 
    {
	  pageContext.writeDiagnostics(this, "AccountDetailsPageCO.PR() - Clicked GO Button", 1);
	  
	if ((sXXTransactions.startsWith("%")))
	{ 
         throw new OAException("XXFIN", "XX_ARI_ACTDET_LEADING_WILSRCH", null, OAException.WARNING, null);
    }	  
	  
	  Date localDate1 = null;
      Date localDate2 = null;
	  long diffInMilliSeconds = 0;
	  int diffInDays =0;
      DateFormat sdf = new SimpleDateFormat("dd-MMM-yyyy");
	  pageContext.writeDiagnostics(this, "Simple Date Format "+sdf, 1);
	  String transactionrange = pageContext.getProfile("XX_AR_IREC_TRXDATE_RANGE");
	  int transactionrange1 = 5000;
	  if ("ANY_STATUS".equals(status) || "CLOSED".equals(status))
	  {
	  if (transactionrange != null) 
	   {
	     transactionrange1 = Integer.parseInt(transactionrange);
		 pageContext.writeDiagnostics(this, "Transaction Range "+transactionrange1, 1);
		 try
          {
           if ((trxDateFrom != null) && !("".equals(trxDateFrom.trim())))
		    {
            localDate1 = sdf.parse(trxDateFrom);
			pageContext.writeDiagnostics(this, "Transaction Date From "+localDate1, 1);
            }
           if ((trxDateTo != null) && !("".equals(trxDateTo.trim())))
		    {
             localDate2 = sdf.parse(trxDateTo);
		     pageContext.writeDiagnostics(this, "Transaction Date To "+localDate2, 1);
            }
		   if ((trxDateFrom != null) && !"".equals(trxDateFrom.trim()) && (trxDateTo != null) && !"".equals(trxDateTo.trim()))
		    {
			  diffInMilliSeconds = localDate2.getTime() - localDate1.getTime();
	          diffInDays = (int) (diffInMilliSeconds / (1000 * 60 * 60 * 24));
		      pageContext.writeDiagnostics(this, "Transaction Date Difference Days "+diffInDays, 1);
		    }
          }
         catch (Exception localException2) 
		 {
           throw OAException.wrapperException(localException2);
         }
		 
	   }
	  }
	  
	 if (   (sXXTransactions == null || "".equals(sXXTransactions.trim()))
		 && (sXXShipToIDValue == null || "".equals(sXXShipToIDValue.trim()))
	     && (sXXConsBill == null || "".equals(sXXConsBill.trim()))
		 && (sXXPurchaseOrder == null || "".equals(sXXPurchaseOrder.trim()))
		 && (sXXDept == null || "".equals(sXXDept.trim()))
		 && (sXXDesktop == null || "".equals(sXXDesktop.trim()))
		 && (sXXRelease == null || "".equals(sXXRelease.trim()))
		 && (amountFrom == null || "".equals(amountFrom.trim()))
		 && (amountTo == null || "".equals(amountTo.trim()))
		 && (dueDateFrom == null || "".equals(dueDateFrom.trim()))
		 && (dueDateTo == null || "".equals(dueDateTo.trim()))
		)
	   {
         if ("ANY_STATUS".equals(status) && (diffInDays >= transactionrange1 || (trxDateFrom == null || "".equals(trxDateFrom.trim())) || (trxDateTo == null|| "".equals(trxDateTo.trim()))))
         {
            throw new OAException("XXFIN", "XX_ARI_ACTDET_WILSRCH_ERR", null, OAException.WARNING, null); 
         }
         if ("CLOSED".equals(status) && (diffInDays >= transactionrange1 || (trxDateFrom == null || "".equals(trxDateFrom.trim())) || (trxDateTo == null|| "".equals(trxDateTo.trim()))))
         {
            throw new OAException("XXFIN", "XX_ARI_ACTDET_WILSRCH_ERR1", null, OAException.WARNING, null); 
         }
	   }
    }
	

  pageContext.writeDiagnostics(this, "AccountDetailsPageCO.PR() - End", 1);
	  
  // End of adding changes for the Defect 41179
  
    super.processFormRequest(pageContext, webBean);

    //Bug3019729: Added more conditions for MultiplePay functionality
    if(pageContext.getParameter(SearchHeaderCO.GO_CONTROL) != null          &&
       pageContext.getParameter("InvoiceExportButton") == null              &&
       pageContext.getParameter("CombinedTransactionsExportButton") == null &&
       pageContext.getParameter("CreditRequestsExportButton") == null       &&
       pageContext.getParameter("CreditMemoExportButton") == null           &&
       pageContext.getParameter("PaymentExportButton") == null              &&
       pageContext.getParameter("DebitMemoExportButton") == null            &&
       pageContext.getParameter("DepositExportButton") == null              &&
       pageContext.getParameter("CustomTrxSearchExportButton") == null      &&
       pageContext.getParameter("DiscountInvoicesExportButton") == null     &&
       pageContext.getParameter("Print") == null                            &&
       pageContext.getParameter("invPrint") == null                         &&
       pageContext.getParameter("depPrint") == null                         &&
       pageContext.getParameter("dmPrint") == null                          &&
       pageContext.getParameter("cmPrint") == null                         &&
       pageContext.getParameter("CustTrxPrint") == null                     &&
       pageContext.getParameter("discInvPrint") == null                         &&
       pageContext.getParameter("TransactionList") == null                  &&
       pageContext.getParameter("invTransactionList") == null               &&
       pageContext.getParameter("depTransactionList") == null               &&
       pageContext.getParameter("dmTransactionList") == null                &&
       pageContext.getParameter("cmTransactionList") == null                &&
       pageContext.getParameter("CustTrxTransactionList") == null           &&
       pageContext.getParameter("discInvTransactionList") == null               &&
       pageContext.getParameter("pmtTransactionList") == null               &&
       pageContext.getParameter("Pay") == null                              &&
       pageContext.getParameter("invPay") == null                           &&
       pageContext.getParameter("depPay") == null                           &&
       pageContext.getParameter("dmPay") == null                            &&       
       pageContext.getParameter("cmPay") == null                           &&
       pageContext.getParameter("discInvPay") == null                           &&
        pageContext.getParameter("CustTrxPay") == null                      &&
       pageContext.getParameter("pmtPay") == null                           &&
       pageContext.getParameter("ApplyCredits") == null                              &&
       pageContext.getParameter("invApplyCredits") == null                           &&
       pageContext.getParameter("depApplyCredits") == null                           &&
       pageContext.getParameter("dmApplyCredits") == null                            &&       
       pageContext.getParameter("cmApplyCredits") == null                            &&
       pageContext.getParameter("discInvApplyCredits") == null                       &&
       pageContext.getParameter("CustTrxApplyCredits") == null                      &&
       pageContext.getParameter("pmtApplyCredits") == null  &&      
       pageContext.getParameter("invDispute") == null                         &&
       pageContext.getParameter("Dispute") == null                         &&
       pageContext.getParameter("dmDispute") == null                         &&
       pageContext.getParameter("depDispute") == null                         &&    
        pageContext.getParameter("CustTrxDispute") == null                         && 
       pageContext.getParameter("discInvDispute") == null                         &&
       pageContext.getParameter("consInvDispute") == null                         &&      
        pageContext.getParameter("consInvTransactionList") == null &&
        pageContext.getParameter("consInvPay") == null &&
        pageContext.getParameter("consInvPrint") == null       &&
        pageContext.getParameter("consInvApplyCredits") == null &&
        pageContext.getParameter("consolidatedInvoiceExportButton") == null &&

       pageContext.getParameter("cbTransactionList") == null &&
       pageContext.getParameter("cbPay") == null &&
       pageContext.getParameter("cbPrint") == null       &&
       pageContext.getParameter("cbApplyCredits") == null &&
        pageContext.getParameter("cbDispute") == null       &&       
       pageContext.getParameter("ChargebackExportButton") == null &&

       pageContext.getParameter("guarTransactionList") == null &&
       pageContext.getParameter("guarPay") == null &&
       pageContext.getParameter("guarPrint") == null       &&
       pageContext.getParameter("guarApplyCredits") == null &&
       pageContext.getParameter("guarDispute") == null       &&       
       pageContext.getParameter("GuaranteeExportButton") == null &&

       pageContext.getParameter("debTrxTransactionList") == null &&
       pageContext.getParameter("debTrxPay") == null &&
       pageContext.getParameter("debTrxPrint") == null       &&
       pageContext.getParameter("debTrxApplyCredits") == null &&
       pageContext.getParameter("debTrxDispute") == null &&
       pageContext.getParameter("DebtTrxExportButton") == null &&
       pageContext.getParameter("approveButton") == null &&
       pageContext.getParameter("approveAllButton") == null &&       
       pageContext.getParameter("Go") == null  &&
       pageContext.getParameter("RecalculateSelectTotals")==null &&
       pageContext.getParameter("XDOExportResults")==null )

       // Bug #  3000512 -- added for customtrxsearch export button
       // Bug # 8371146 -- removed Export and added XDOExportResults

    {      
      // add this dummy variable to to URL of Accounts Details page to make
      // the URL of each page different , so as the web Bean is re-created upon 
      //any form submit after Browser back buton
      Integer count = new Integer(searchnum);
      HashMap hmpar = new HashMap() ;
      searchnum++;
      
      //Bug 3922771 - Set the search params in the URL
      //In case the user choosed to personalize/modify attachments/change preferences,
      //this will ensure that the user is returned to the correct page. 
     
      //String type         = getParameter(pageContext, SearchHeaderCO.TRANSACTION_TYPE);
      //String status       = getParameter(pageContext, SearchHeaderCO.TRANSACTION_STATUS);
      String currency     = getParameter(pageContext, SearchHeaderCO.CURRENCY_CODE_KEY);
      String keyword      = getParameter(pageContext,"Iracctdtlskeyword");
      //String amountFrom   = getParameter(pageContext, "Ariamountfrom");
      //String amountTo     = getParameter(pageContext, "Ariamountto");
      //String trxDateFrom  = getParameter(pageContext, "Aritransdatefrom");
      //String trxDateTo    = getParameter(pageContext, "Aritransdateto");
      //String dueDateFrom  = getParameter(pageContext, "Ariduedatefrom");
      //String dueDateTo    = getParameter(pageContext, "Ariduedateto");
      String orgContext   = getParameter(pageContext, "OrgContext");
      String currentCustContext  = getParameter(pageContext, "CustomerContextList");
      String relCustomer  = getParameter(pageContext, "IrSelectCustomer");
      String relCustId    = getParameter(pageContext, "SearchRelCustomerValue");
      
      hmpar.put((Object)("Search_Number"),(Object)(count));
      //Bug 5649716 - set the current customer context to reflect the dropdown correctly
     
      if (currentCustContext != null) {
          setActiveCustomerId(pageContext,currentCustContext);  
          hmpar.put("CustomerContextList_ext", currentCustContext); 
      }      
      if (type != null)
        hmpar.put(SearchHeaderCO.TRANSACTION_TYPE + "_ext", type);
      if (status != null)
        hmpar.put(SearchHeaderCO.TRANSACTION_STATUS + "_ext", status);
      if (currency != null)
        hmpar.put(SearchHeaderCO.CURRENCY_CODE_KEY + "_ext", currency);
      /*if (keyword != null)
        hmpar.put("Iracctdtlskeyword_ext", keyword);*/
      // pagecontext cannot handle more than 1000 trx numbers, so using session
      if (keyword != null)
        pageContext.putSessionValue("Iracctdtlskeyword",keyword);
      else 
        pageContext.putSessionValue("Iracctdtlskeyword","");
      if (amountFrom != null)
        hmpar.put("Ariamountfrom_ext", amountFrom);
      if (amountTo != null)
        hmpar.put("Ariamountto_ext", amountTo);
      if (trxDateFrom != null)
        hmpar.put("Aritransdatefrom_ext", trxDateFrom);      
      if (trxDateTo != null)
        hmpar.put("Aritransdateto_ext", trxDateTo);
      if (dueDateFrom != null)
        hmpar.put("Ariduedatefrom_ext", dueDateFrom);
      if (dueDateTo != null)
        hmpar.put("Ariduedateto_ext", dueDateTo);
      if (orgContext != null)
      {
        setActiveOrgId(pageContext, orgContext);
        //Org Id may be there in the URL - If present, this needs to be changed too.
        hmpar.put("Irorgid", orgContext);
        /*if ((pageContext.getParameter("Irorgid") != null))
          pageContext.putParameter("Irorgid",orgContext); */
      }
         

      //Setting Related Customer Name     
      if (relCustomer != null)
      {  
        hmpar.put("IrSelectCustomer_ext", relCustomer);
      }  
      //Setting Related Customer Id
      if (relCustId != null)
      {  
        hmpar.put("SearchRelCustomerValue_ext", relCustId);
      }
      
       pageContext.putParameter("AcctDtlPageRefresh","Y");
      
      // Bug 11871875   - If the Requery paramter is not removed from page context then it will always be "N"
      // and on click on 'GO' button will not re-execute the VO.
      pageContext.removeParameter("Requery"); 
      pageContext.removeSessionValue("Requery");
      pageContext.removeParameter("fromHomePage"); 
      pageContext.removeSessionValue("IracctDiscInvoices"); 
       
      //Bug 3458134 - If the "Go" button is pressed, set the Discount Invoices parameter 
      //to empty string, so that discounted invoices don't get picked up.
      pageContext.putParameter("IracctDiscInvoices","");      
      //  pageContext.forwardImmediately("ARIACCOUNT", OAWebBeanConstants.KEEP_MENU_CONTEXT, null, hmpar, true, ADD_BREAD_CRUMB_SAVE);
       pageContext.forwardImmediatelyToCurrentPage(hmpar, true, ADD_BREAD_CRUMB_SAVE);      
     }
  }



  public void processFormData(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormData(pageContext, webBean);

    String currencyCode = getParameter(pageContext, CURRENCY_CODE_KEY);
    currencyCode = getActiveCurrencyCode(pageContext, currencyCode);
  }

  protected static String getParameter
    (OAPageContext pageContext, String paramName)
  {
    String retVal = null;
    retVal = pageContext.getParameter(paramName);
    if ((null != paramName) && (null == retVal))
    {
      paramName += "_ext";
      retVal = pageContext.getParameter(paramName);
    }
    return retVal;
  }


 protected static String getDecryptedParameter
    (OAPageContext pageContext, String paramName)
  {
    String retVal = null;
    retVal = pageContext.getDecryptedParameter(paramName);
    if ((null != paramName) && (null == retVal))
    {
      paramName += "_ext";
      retVal = pageContext.getDecryptedParameter(paramName);
    }
    return retVal;
  }
  
  protected String getDefaultSubmitButton(String formName)
  {
    if(DEFAULT_FORM_NAME.equals(formName))
      return SearchHeaderCO.GO_CONTROL;
    else
      return null;
  }

  /**
   * author : Mohammad Shoaib Jamall
   *
   * this method will use the url parameter IrAcctDetailsQuery_ext to form the
   * a new url parameter IrAcctDetailsQuery which contains the query string to
   * be added to the account details query.
   * It will also add the IrAcctDetailsQueryParams based on parameters named
   * IrAcctDetailsQueryParams<i>_ext. The IrAcctDetailsQueryParams parameter
   * is basically going to be a "~~" delimited string of the parameters for
   * the query clause that is being added.
   *
   */
  private void setExtraQuery(OAPageContext pageContext)
  {
    String query =
      pageContext.getParameter(SearchHeaderCO.ACCT_DETAILS_QUERY + "_ext");
    if (null != query)
      pageContext.putParameter(SearchHeaderCO.ACCT_DETAILS_QUERY, query);

    StringBuffer params = new StringBuffer();

    int i = 0;
    String currentParam = pageContext.getParameter
      (SearchHeaderCO.ACCT_DETAILS_QUERY_PARAMS + i + "_ext");
    while (null != currentParam)
    {
      params.append(currentParam);

      i++;
      currentParam = pageContext.getParameter
        (SearchHeaderCO.ACCT_DETAILS_QUERY_PARAMS + i + "_ext");
      if (null != currentParam)
        params.append("~~");

      // Bugfix 2272203 : Append "," for null parameters .
      try{
        if (currentParam.equals(""))
          params.append(",");
      }catch(Exception e){  }
    }
    pageContext.putParameter(SearchHeaderCO.ACCT_DETAILS_QUERY_PARAMS, params.toString());

  }

  // This function is called by IROAController to determine the page name. 
  // The page name is used for the Contact Us feature which customers can 
  // implement in the ARI_CONFIG package.
  
  public String getPageName(OAPageContext pageContext, OAWebBean webBean)
  {
    return "ARI_ACCOUNT_DETAILS";
  }

  //This method is called when we click on Account Tab or Account Link button.
    //If the search criteria exists, then retain the search .
    public void checkSavedSearchCriteria(OAPageContext pageContext, OAWebBean webBean)
    {
      String trx_status = (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_STATUS");
      String trx_type   = (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_TYPE");
      String currency = (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_CURRENCY");
      // bug # 11871930  - nkanchan
      //String keyword = (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_KEYWORD");
      String amountFrom = (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_AMTFROM");
      String amountTo = (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_AMTTO");
      String trxDateFrom = (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_TRXDATEFROM");
      String trxDateTo = (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_TRXDATETO");
      String dueDateFrom = (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_DUEDATEFROM");
      String dueDateTo = (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_DUEDATETO");
	  
	   /* Added for R12 upgrade retrofit */
        // Bushrod added for E1327
        String sXXShipToIDValue =
            (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_XXSHIPTOIDVALUE");
        // Bushrod added for E2052
        String sXXConsBill =
            (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_XXCONSBILL");
        String sXXTransactions =
            (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_XXTRANSACTIONS");
        String sXXPurchaseOrder =
            (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_XXPURCHASEORDER");
        String sXXDept =
            (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_XXDEPT");
        String sXXDesktop =
            (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_XXDESKTOP");
        String sXXRelease =
            (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_XXRELEASE");


        /* End - Added for R12 upgrade retrofit */

      if(! isNullString(trx_status) )
            pageContext.putParameter(SearchHeaderCO.TRANSACTION_STATUS, trx_status);
      if(! isNullString(trx_type) )
            pageContext.putParameter(SearchHeaderCO.TRANSACTION_TYPE, trx_type);
      if(! isNullString(currency) )
          pageContext.putParameter(SearchHeaderCO.CURRENCY_CODE_KEY, currency);
      // bug # 11871930  - nkanchan
      /*if(! isNullString(keyword) )
          pageContext.putParameter("Iracctdtlskeyword", keyword);*/
      if(! isNullString(amountFrom) )
          pageContext.putParameter("Ariamountfrom", amountFrom);
      if(! isNullString(amountTo) )
            pageContext.putParameter("Ariamountto", amountTo);
      if(! isNullString(trxDateFrom) )
          pageContext.putParameter("Aritransdatefrom", trxDateFrom);
      if(! isNullString(trxDateTo) )
          pageContext.putParameter("Aritransdateto", trxDateTo);
      if(! isNullString(dueDateFrom) )
          pageContext.putParameter("Ariduedatefrom", dueDateFrom);
      if(! isNullString(dueDateTo) )   
          pageContext.putParameter("Ariduedateto", dueDateTo);
		  
		  
       /*Added for R12 upgrade Retrofit*/
        // Bushrod added for E1327
        if (!isNullString(sXXShipToIDValue))
            pageContext.putParameter("XXShipToIDValue", sXXShipToIDValue);
        // Bushrod added for E2052
        if (!isNullString(sXXConsBill))
            pageContext.putParameter("XXConsBill", sXXConsBill);
        if (!isNullString(sXXTransactions))
            pageContext.putParameter("XXTransactions", sXXTransactions);
        if (!isNullString(sXXPurchaseOrder))
            pageContext.putParameter("XXPurchaseOrder", sXXPurchaseOrder);
        if (!isNullString(sXXDept))
           pageContext.putParameter("XXDept", sXXDept);
        if (!isNullString(sXXDesktop))
            pageContext.putParameter("XXDesktop", sXXDesktop);
        if (!isNullString(sXXRelease))
            pageContext.putParameter("XXRelease", sXXRelease);

        /*End - Added for R12 upgrade Retrofit*/
    }

  // This procedure restores the state of the various account
  // details parameters to the same state as how the current 
  // page was rendered.  

  // Pre-Condition:  1. isBrowserBackButton returns true.
  //                 2. called from processRequest.
  public void restorePageParameters(OAPageContext pageContext, OAWebBean webBean)
  {
     // if Browser back button has been clicked, get search Status value from the
     // hidden values and set pageContext so as webBean is re-created properly
     String currentCustContext = pageContext.getParameter("SearchCustomerContextValue");
     pageContext.putParameter("CustomerContextList", currentCustContext);

     String status = pageContext.getParameter("SearchStatusValue");
     pageContext.putParameter(SearchHeaderCO.TRANSACTION_STATUS, status);

     String type = pageContext.getParameter("SearchTypeValue");
     pageContext.putParameter(SearchHeaderCO.TRANSACTION_TYPE, type);

     String currency = pageContext.getParameter("SearchCurrencyValue");
     pageContext.putParameter(SearchHeaderCO.CURRENCY_CODE_KEY, currency);

     // bug # 11871930  - nkanchan
     /*String keyword = pageContext.getParameter("SearchKeywordValue");
     pageContext.putParameter("Iracctdtlskeyword", keyword);*/

     String amountFrom = pageContext.getParameter("SearchAmtFromValue");
     pageContext.putParameter("Ariamountfrom", amountFrom);

     String amountTo = pageContext.getParameter("SearchAmtToValue");
     pageContext.putParameter("Ariamountto", amountTo);

     String trxDateFrom = pageContext.getParameter("SearchTransDateFromValue");
     pageContext.putParameter("Aritransdatefrom", trxDateFrom);

     String trxDateTo = pageContext.getParameter("SearchTransDateToValue");
     pageContext.putParameter("Aritransdateto", trxDateTo);

     String dueDateFrom = pageContext.getParameter("SearchDueDateFromValue");
     pageContext.putParameter("Ariduedatefrom", dueDateFrom);
         
     String dueDateTo = pageContext.getParameter("SearchDueDateToValue");
     pageContext.putParameter("Ariduedateto", dueDateTo);

     String irSelectCustomer = pageContext.getParameter("IrSelectCustomer");
     if(irSelectCustomer!=null)     
        pageContext.putParameter("IrSelectCustomer", irSelectCustomer);    
     String searchRelCustomerValue = pageContext.getParameter("SearchRelCustomerValue");
     if(searchRelCustomerValue!=null)     
        pageContext.putParameter("SearchRelCustomerValue", searchRelCustomerValue);     
     
  }  
    
 //Bug # 3412087
  public String getQueryString(OAPageContext pageContext)
  {
    return null ;
  }

  // Bug 11871875
  public HashMap getPageParameters(OAPageContext pageContext) 
  {

      // add this dummy variable to to URL of Accounts Details page to make
      // the URL of each page different , so as the web Bean is re-created upon 
      //any form submit after Browser back buton
      Integer count = new Integer(searchnum);
      HashMap hmpar = new HashMap() ;
      searchnum++;
      
    //Bug 3922771 - Set the search params in the URL
      //In case the user choosed to personalize/modify attachments/change preferences,
      //this will ensure that the user is returned to the correct page.    
      String currentCustContext  = getParameter(pageContext, "CustomerContextList");
      // bug # 11871930  - nkanchan
      //String keyword = (String)pageContext.getSessionValue("Iracctdtlskeyword");
      String status = (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_STATUS");
      String type   = (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_TYPE");
      String currency = (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_CURRENCY");
      //String keyword = (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_KEYWORD");
      String amountFrom = (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_AMTFROM");
      String amountTo = (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_AMTTO");
      String trxDateFrom = (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_TRXDATEFROM");
      String trxDateTo = (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_TRXDATETO");
      String dueDateFrom = (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_DUEDATEFROM");
      String dueDateTo = (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_DUEDATETO");
      String salesOrder = (String)pageContext.getSessionValue("RETURN_ACCT_DETAILS_LINK_SALESORDER");
      
      hmpar.put((Object)("Search_Number"),(Object)(count));
    //Bug 5649716 - set the current customer context to reflect the dropdown correctly
    // we have to set customerId only if currentCustContext is not null, added if condition for bug # 7524192
      if (currentCustContext != null) {
         setActiveCustomerId(pageContext,currentCustContext);  
         hmpar.put("CustomerContextList_ext", currentCustContext); 
      } 
    
    if (currentCustContext != null)
        hmpar.put("CustomerContextList_ext", currentCustContext);
      if (type != null)
        hmpar.put(SearchHeaderCO.TRANSACTION_TYPE + "_ext", type);
      if (status != null)
        hmpar.put(SearchHeaderCO.TRANSACTION_STATUS + "_ext", status);
      if (currency != null)
        hmpar.put(SearchHeaderCO.CURRENCY_CODE_KEY + "_ext", currency);
      // bug # 11871930  - nkanchan
      /*if (keyword != null)
        hmpar.put("Iracctdtlskeyword_ext", keyword);*/
      if (amountFrom != null)
        hmpar.put("Ariamountfrom_ext", amountFrom);
      if (amountTo != null)
        hmpar.put("Ariamountto_ext", amountTo);
      if (trxDateFrom != null)
        hmpar.put("Aritransdatefrom_ext", trxDateFrom);      
      if (trxDateTo != null)
        hmpar.put("Aritransdateto_ext", trxDateTo);
      if (dueDateFrom != null)
        hmpar.put("Ariduedatefrom_ext", dueDateFrom);
      if (dueDateTo != null)
        hmpar.put("Ariduedateto_ext", dueDateTo);
      if (salesOrder != null)
        hmpar.put("AriSalesOrder_ext", salesOrder);

        return hmpar;
  }
}

