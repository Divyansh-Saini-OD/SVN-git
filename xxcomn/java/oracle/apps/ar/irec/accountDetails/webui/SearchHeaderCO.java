package oracle.apps.ar.irec.accountDetails.webui;



import java.io.Serializable;

import oracle.apps.ar.irec.homepage.server.TemplateLocaleVOImpl;
import oracle.apps.fnd.common.VersionInfo;

import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OATableLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAStackLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.ar.irec.accountDetails.server.TransactionStatusPoplistVOImpl;
import oracle.apps.fnd.framework.webui.beans.form.OAFormValueBean ;
import oracle.apps.fnd.framework.webui.OAUrl;
import oracle.apps.fnd.framework.webui.beans.layout.OASeparatorBean; 
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.Collection;
import com.sun.java.util.collections.Iterator;
import com.sun.java.util.collections.ArrayList;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.webui.beans.layout.OADefaultHideShowBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageRichTextEditorBean;
import oracle.apps.fnd.framework.webui.beans.nav.OAButtonBean;

/*----------------------------------------------------------------------------
 -- Author: Sridevi Kondoju
 -- Component Id: E1329
 -- Script Location: $CUSTOM_JAVA_TOP/oracle/apps/ar/irec/accountdetails/webui
 -- Description: Seeded java file customised.
 -- History:
 -- Name            Date         Version    Description
 -- -----           -----        -------    -----------
 -- Sridevi Kondoju 19-Jan-2015   1.0       Retrofitted for RPC p19052386 patch.
 -- Vasu Raparla    18-Aug-2016   2.0       Retrofitted for R12.2.5 upgrade.
---------------------------------------------------------------------------*/
/*===========================================================================+
 |      Copyright (c) 2000, 2014 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 |    14-Aug-00  sjamall       Created.                                      |
 |    05-Apr-01  krmenon       Removed logic for page header.                |
 |                             Moved processFormRequest to one level above   |
 |    26-Apr-01  sjamall       replaced Strings with constant strings        |
 |                             GO_CONTROL and TRANSACTION_TYPE. added default|
 |                             values to the Status and Type poplists so that|
 |                             we get the poplists show the correct entry    |
 |                             when you come into the account details page   |
 |                             from another page.                            |
 |   04-May-01  sjamall        bugfix 1766751 : setting caching off for the  |
 |                             currency poplist                              |
 |   17-May-01  sjamall        bugfix 1550887 : removed spacing in between   |
 |                             cells to tighen up Search Region.             |
 |   25-Jun-01  sjamalll       bugfix 1824217 : workaround : started using   |
 |                             static method AccountDetailsPageCO.getParameter|
 |   10-Sep-01  sjamall        bugfix 1788892                                |
 |   26-Oct-02  albowicz       Online Aging -- Added Code to initialize the  |
 |                             TrxStatusPoplistVO.                           |
 |   20-May-03  hikumar       Bug # 2967730 - Export button not working      |
 |                            after Browser Back Button                      |
 |    11-June-03  hikumar      Bug # 1766614 - modified to logic of function |
 |                             Browser Back Button                           |
 |    19-Nov-03  hikumar      Bug # 3266491 - ATG Remove Results Header from |
 |                            Results Region                                 |
 |    13-Jan-04  vnb          Bug # 3131362 - Added code to save attachments |
 |    12-Feb-04  vnb          Bugfix # 3423721 - HotKey Implementation       |
 |    22-Mar-04  vnb          Bug # 3520646 - Removed numeric Hotkeys        |
 |    26-Apr-04  vnb          Bug # 3467287 - Transaction List button to be  |
 |						      enabled always; code to enable/disable the     |
 |							  button has been removed.                       |
 |    14-Jun-04  vnb          Bug # 3458134 - Added a new region for Discount|
 |                            Invoices on Account Details page               |
 |    24-May-05  vnb         Bug 4197060 - MOAC Uptake                       |
 |    28-Feb-08 avepati       Bug 6748005 - ADS12.0.03 :FIN:NEED CONSOLIDATED|
 |                             NUMBER FILTER ON ACCOUNT DETAILS PAGE         |
 |    01-Apr-11   nkanchan  Bug 11871875 - fp:9193514 :transaction     |
 |                           list disappears in ireceivables           |
 |    02-Apr-13   shvimal   BUG 12780056 - TST122.XB7.QA.TRANSACTION NUMBER VANISHES ON CHANGING TRX TYPE | 
 |    20-Jun-12   shvimal Bug 16977409 - CANNOT PRINT ONLY 1 INVOICE IN A SET OF INSTALLMENTS |
 |    20-Feb-14   rsurimen  Bug 18260226 Session Language Display in Loacale Field|
 +===========================================================================*/
/**
 * This class is does the layout for the Account Details page's Search Region
 * (which describes the Search Criteria)
 *
 * @author 	Mohammad Shoaib Jamall
 */


public class SearchHeaderCO extends AccountDetailsBaseCO
{

  public static final String RCS_ID="$Header: SearchHeaderCO.java 120.27.12020000.3 2014/02/21 07:45:15 rsurimen ship $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "oracle.apps.ar.irec.accountDetails.webui");

  public static final String GO_CONTROL = "Iracctdtlgocontrol";
  public static final String TRANSACTION_TYPE = "Iracctdtlstype";
  public static final String TRANSACTION_STATUS = "Iraccountstatus";
  public static final String RESTRICT_ACCT_DETAILS = "IrAcctDetailsRestrict";
  public static final String ACCT_DETAILS_QUERY = "IrAcctDetailsQuery";
  public static final String ACCT_DETAILS_QUERY_PARAMS = "IrAcctDetailsQueryParams";

  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    // get the view object to be used for Looking Up Codes.
    OAViewObject transactionTypeVO = (OAViewObject)pageContext.getApplicationModule
        (webBean).findViewObject("TransactionTypeVO");

    initializeTransactionStatusPoplist(pageContext, webBean);

    String simpleMsg = pageContext.getMessage("AR", "ARI_ACCT_DTL_SEARCH", null);
    String advMsg = pageContext.getMessage("AR", "ARI_ACCT_DTL_ADV_SEARCH", null);

    OAStackLayoutBean stackLayout = (OAStackLayoutBean) createWebBean(pageContext, STACK_LAYOUT_BEAN, null, "SrchHdrStackLayout");
    webBean.addIndexedChild(stackLayout);

    // Search Instruction.
    //{
      /*OATableLayoutBean table =
        (OATableLayoutBean)createWebBean((pageContext, TABLE_LAYOUT_BEAN,null,"SearchHeaderTable");
      stackLayout.addIndexedChild(table);*/

      OATableLayoutBean table =
        (OATableLayoutBean)createWebBean(pageContext, webBean,"SearchHeaderTable",null);
      stackLayout.addIndexedChild(table);      
      
        // Bug # 3266491 - hikumar
        OASeparatorBean  seperationLine = (OASeparatorBean)createWebBean(pageContext, webBean, "item1");
        stackLayout.addIndexedChild(seperationLine);

      stackLayout.addIndexedChild(createWebBean(pageContext, webBean, "SearchDtlRN"));

        SaveSearchCriteria(pageContext, webBean ); // Bug # 2890539
        
        String regionName = SetupResultsRegion(pageContext, webBean);
        OAStackLayoutBean region = (OAStackLayoutBean)createWebBean(pageContext,webBean,regionName);
        stackLayout.addIndexedChild(region);

      OAApplicationModule am=(OAApplicationModule)pageContext.getApplicationModule(webBean);
      String type=pageContext.getParameter(SearchHeaderCO.TRANSACTION_TYPE);
      am.invokeMethod("initAccountDetailsPVO",new Serializable[]{type});
        
        // Set Attributes
         setAttributes(pageContext);
        
      // set java script function
      setJSFunction(pageContext, webBean);

      stackLayout.addIndexedChild(createWebBean(pageContext, webBean, "SelectedTrxTotalsReg"));

        // Bug # 5236417 ABHISJAI
        // Adding XDORegion to the AccountDetails Page
        stackLayout.addIndexedChild(createWebBean(pageContext, webBean, "XDORegion"));
       

      // bug # 4959504 - hikumar
      // add discounts filter for discounts search and expand the advance search region
      String sDiscountInvoices = pageContext.getParameter("IracctDiscInvoices");
      if ((sDiscountInvoices != null) && ("Y".equals(sDiscountInvoices)))
      {
        OADefaultHideShowBean advSearch = (OADefaultHideShowBean) stackLayout.findIndexedChildRecursive("AdvancedSearch");
        advSearch.setDisclosed(true);

        String discFilterValue = (String) pageContext.getParameter("IrDiscountFilter");
        OAMessageChoiceBean discFilter = (OAMessageChoiceBean) advSearch.findIndexedChildRecursive("DiscountAlertFilter");
        discFilter.setRendered(true);
        if(discFilterValue!=null) discFilter.setSelectionValue(pageContext,discFilterValue);
      }    


        //stackLayout.addIndexedChild(createWebBean(pageContext,webBean,regionName));
        
        //Bug # 3467287 - Transaction List global button to remain enabled always.
        //Bug3070364 : Enable/Disable global button .
        /*
         * if (pageContext.getSessionValue("RecordsInTransactionList") == "YES" )
          setTransactionListGlobalButton(pageContext,false);
        else
          setTransactionListGlobalButton(pageContext,true);  
        */

        //Bugfix # 3520646 - Removed numeric Hotkeys

        //Bug 3922771 - Moved programmtic code to ensure attachments are saved,
        //              to declarative approach on the XML beans.
       
            
    //}

      String approverStatus = pageContext.getProfile("OIR_PMT_APPROVER_STATUS");
      if(isNullString(approverStatus) || "DISABLED".equals(approverStatus) )
      {
       OAMessageChoiceBean approvalStatusChoiceBean = (OAMessageChoiceBean)webBean.findIndexedChildRecursive("IrApprovalStatus");
          approvalStatusChoiceBean.setRendered(false);
      }
      

    super.processRequest(pageContext, webBean);

    // Bug # 1766614  - hikumar
    // save the current URL in session variable to be accessed from isBrowserBackButton function
    // in AccountDetailsBaseCO.java
    String currentUrl = OAUrl.decode(pageContext, pageContext.getCurrentUrl()); 
    pageContext.putSessionValue("ACCOUNT_DETAILS_PAGE_LAST_URL", currentUrl); 
  }
  
    /**
     * @param pageContext is a OAPageContext Object
     */
    protected void setAttributes(OAPageContext pageContext)
    {
        setAttribute("SearchGoButton", "Iracctdtlgocontrol");
        setAttribute("SearchClearButton", "IrClearBtn");
        


        ArrayList list = new ArrayList();
        list.add("OrgContext");   
        list.add("CustomerContextList");
        list.add("Iraccountstatus");
        list.add("Iracctdtlskeyword");
        list.add("Ircurrencycode");
        list.add("Iracctdtlstype");
        list.add("Ariamountfrom");
        list.add("Ariamountto");
        list.add("Aritransdatefrom");
        list.add("Aritransdateto");
        list.add("Ariduedatefrom");
        list.add("Ariduedateto");
        //Added for iRec Enhancement
        list.add("XXShipToLOV");
        list.add("XXDesktop");
        list.add("XXDept");
        list.add("XXRelease");
        list.add("XXPurchaseOrder");
        list.add("XXConsBill");
        list.add("XXTransactions");
        setClearableCriteriaNames(list);
    }



    /**
     * @param pageContext the current OA page context
     * @param webBean the web bean corresponding to the AK region
     */
    protected void setJSFunction(OAPageContext pageContext, OAWebBean webBean)
    {
      if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this,
                                     "IRec:" + this.getClass().getName() +
                                     ".setJSFunction(OAPageContext) starts.",
                                     OAFwkConstants.PROCEDURE);

      // clear button
      String clearButton = getAttribute("SearchClearButton");
      if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
        pageContext.writeDiagnostics(this,
                                     "clearButton = " + clearButton,
                                     OAFwkConstants.STATEMENT);

      if (clearButton != null) {
        // prepare the function first
        String onClickJSFuncName = "clear" + clearButton;
        generateClearOnClickJS(onClickJSFuncName, clearButton, pageContext, webBean);

        // set text of search fields
        //OASubmitButtonBean clearBean = (OASubmitButtonBean)pageContext.getPageLayoutBean().findChildRecursive(clearButton);
         OAButtonBean clearBean = (OAButtonBean)pageContext.getPageLayoutBean().findChildRecursive(clearButton);
        if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
          pageContext.writeDiagnostics(this,
                                       "clearBean = " + clearBean,
                                       OAFwkConstants.STATEMENT);

        clearBean.setOnClick(onClickJSFuncName + "();");      
      }

      if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this,
                                     "IRec: " + this.getClass().getName() +
                                     ".setJSFunction(OAPageContext) done.",
                                     OAFwkConstants.PROCEDURE);
    }


    protected HashMap attributeHash = new HashMap();
    
    protected Collection mClearableCriteriaNames ;

    /**
     * @param c collection
     */
    protected void setClearableCriteriaNames(Collection c)
    {
      mClearableCriteriaNames = c;
    }

    /**
     */
    protected Collection getClearableCriteriaNames()
    {
      return mClearableCriteriaNames;
    }
    
    

    /**
     * @param key
     */
    protected String getAttribute(String key)
    {
      return (String)attributeHash.get(key);
    }

    /**
     * @param key
     * @param value
     */
    protected void setAttribute(String key, String value)
    {
      attributeHash.put(key, value);
    }

    /**
       * generate java script function for clear button
       */
      private void generateClearOnClickJS(
          String funcName,
          String uiNodeName,
          OAPageContext pageContext,
          OAWebBean webBean)
      {
        StringBuffer onClickJS = new StringBuffer("function ");
        onClickJS.append(funcName).append("(){");

        Collection paramNames = getClearableCriteriaNames();

        // set default value
        Iterator iterator = paramNames.iterator();
        while (iterator.hasNext()) {
          String name = (String)iterator.next();
          if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
            pageContext.writeDiagnostics(this,
                                         "name = " + name,
                                         OAFwkConstants.STATEMENT);

            onClickJS.append(LOV_CLEAR_VALUE)
                     .append("(")
                     .append("document.")
                     .append(DEFAULT_FORM_NAME).append(".")
                     .append(name).append(");");
        }
        onClickJS.append("return false;");
        onClickJS.append("}");



        if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
          pageContext.writeDiagnostics(this,
                                       "onClickJS = " + onClickJS,
                                       OAFwkConstants.STATEMENT);

        pageContext.putJavaScriptFunction(funcName, onClickJS.toString());
      }



  private void setupChoiceBean(OAMessageChoiceBean choiceBean, OAViewObject vo,
                               String lookupType,  OAPageContext pageContext)
  {
    Serializable [] params = {lookupType};
    /*
      vo.invokeMethod("initQuery", params);
SELECT lookup_code, meaning FROM apps.ar_lookups WHERE ( lookup_type = :1 )
    */
    vo.setWhereClauseParams(null);
    vo.setWhereClause( " lookup_type = :1 ");
    vo.setWhereClauseParam (0, lookupType);

    choiceBean.setListDisplayAttribute("Meaning");
    choiceBean.setListValueAttribute("LookupCode");
    choiceBean.setPickListViewUsageName(vo.getFullName());
  }

  // The TransactionStatusPoplistVO requires the aging bucket name as input.
  private void initializeTransactionStatusPoplist(OAPageContext pageContext, OAWebBean webBean)
  {
    TransactionStatusPoplistVOImpl vo = (TransactionStatusPoplistVOImpl)pageContext.getApplicationModule
      (webBean).findViewObject("TransactionStatusPoplistVO");

    String bucket_name = (String)pageContext.getSessionValue("AgingBucketUsage");

    if(bucket_name == null)
    {
      bucket_name = pageContext.getProfile("OIR_AGING_BUCKETS");
      if(bucket_name != null && "".equals(bucket_name) == false)
        pageContext.putSessionValue("AgingBucketUsage", bucket_name);
    }  

    vo.initQuery(bucket_name);   
  }

  private void setHiddenValue(OAPageContext pageContext,OAWebBean webBean,String parName,String value)
  {
      OAFormValueBean formValueBean = (OAFormValueBean)createWebBean(pageContext, webBean, parName); 
      formValueBean.setValue(pageContext,value);
      webBean.addIndexedChild(formValueBean);
  }


  private String SetupResultsRegion(OAPageContext pageContext, OAWebBean webBean)
  {
    String type     = getSearchType(pageContext, webBean);
    String status   = getSearchStatus(pageContext, webBean);

    String sDiscountInvoices = pageContext.getParameter("IracctDiscInvoices");

    String resultsRegionName = "Ariacctcombview";

    if(type.equals("ALL_TRX"))
      resultsRegionName = "Ariacctcombview";
    else if(type.equals("INVOICES"))
      {
        if ((sDiscountInvoices != null) && ("Y".equals(sDiscountInvoices))) {
          resultsRegionName = "Ariacctdiscinvoiceview";
          pageContext.putSessionValue("IracctDiscInvoices","Y");
        }
        else
          resultsRegionName = "Ariacctinvoiceview";
      }   
    else if(type.equals("PAYMENTS"))
      resultsRegionName = "Ariacctpmtview";
    else if(type.equals("CREDIT_MEMOS"))
      resultsRegionName = "Ariacctcmview";
    else if(type.equals("CREDIT_REQUESTS"))
      resultsRegionName = "Ariacctreqview";
    else if(type.equals("DEBIT_MEMOS"))
      resultsRegionName = "Ariacctdmview";
    else if(type.equals("DEPOSITS"))
      resultsRegionName = "Ariacctdepview";
    else if(type.equals("CONSBILLNUMBER"))
        resultsRegionName = "AriacctconsInvview";
    // Bug # 3000512 - hikumar
    // if the type is not equal to any of these is a custom added attribute
    else if(type.equals("CHARGEBACKS"))
      resultsRegionName = "AriacctChargeBackView";
    else if(type.equals("GUARANTEES"))
      resultsRegionName = "AriacctGuaranteeView";
    else if(type.equals("ALL_DEBIT_TRX"))
      resultsRegionName = "AriacctAllDebitTrxView";
    else
      resultsRegionName = "Aricustomtrxsearchview" ;

    // also if status is not any of defined values , its a custom added attribute
    if(!status.equals("ANY_STATUS") && !status.equals("CLOSED") && 
       !status.equals("OPEN") && !status.equals("PAST_DUE_INVOICE") &&
       !status.startsWith("OIR_AGING_") )
       {
         resultsRegionName = "Aricustomtrxsearchview" ;
       }
       // Bug # 3000512  -hikumar  
 
    //OAWebBean results = createWebBean(pageContext, webBean, resultsRegionName);
    //webBean.addIndexedChild(results);

    //OAWebBean results = webBean.findChildRecursive(resultsRegionName);
    //results.setRendered(true);
    return(resultsRegionName);
  }

  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean) 
  {
    super.processFormRequest(pageContext, webBean);
    OAApplicationModule am=(OAApplicationModule)pageContext.getApplicationModule(webBean);
    String event = pageContext.getParameter("event");
    if("trxTypeChange".equals(event)) 
    {
      String type=pageContext.getParameter(SearchHeaderCO.TRANSACTION_TYPE);
      am.invokeMethod("handleTrxTypeChangeEvent",new Serializable[]{type});
      
      // Bug 12780056 - To retain SearchKeyword 
      String sKeyWord = (String)pageContext.getParameter("Iracctdtlskeyword");
      if (sKeyWord != null)
      {
        OAMessageRichTextEditorBean srchkeyword= (OAMessageRichTextEditorBean)webBean.findIndexedChildRecursive("Iracctdtlskeyword");
        srchkeyword.setText(sKeyWord);
      }
    }
    
    // Bug 16977409  -  print installment number
       if("setInstallmentPrintSelected".equals(event)) 
       {
           String printInstallmentNumber = pageContext.getParameter("PrintInstallmentNumber");
           if("on".equals(printInstallmentNumber)) printInstallmentNumber ="Y"; 
           else printInstallmentNumber ="N";
           OADBTransaction trx      = (OADBTransaction)am.getOADBTransaction();
           if(trx!=null)  trx.putValue("PrintInstallmentNumber",printInstallmentNumber);    

       }

    // Bug # 8371146
    String templateCode = pageContext.getParameter("TemplateCode");
    String sLang=null;
    if("TemplateChange".equals(event))
    {
    templateCode = pageContext.getParameter("TemplateCode");
    // Bug # 18260226 - Session Language Display in Locale Field
     sLang=pageContext.getCurrentLanguage();  
     ((TemplateLocaleVOImpl)am.findViewObject("TemplateLocaleVO")).initQuery(sLang,templateCode);
    }


  }

}