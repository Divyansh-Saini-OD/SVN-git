/*===========================================================================+
 |      Copyright (c) 2001, 2014 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 |    23-Jun-03   yreddy       Bug3019729: MultiplePay functionality         |
 |    17-Feb-04   vnb          Bug 3446389 - Reset the Rendered property of  |
 |                             Payment Method regions after rollback, when   |
 |                             "Reset to Defaults" button is pressed.        |
  |    29-Apr-04   vnb          Bug 3559788 - "Reset to Defaults" button has  |
 |                             made a Table Action button                    |
 |    05-May-2004   hikumar   Bug # 3605817 - Removed section Payment Details|
 |                             Moved payment fields to Installment summary   |
 |                              section                                      |
 |    06-May-04   vnb         Bug # 3607343 - If the currency code is not    |
 |                            present in the URL parameters, pick up the     |
 |                            active currency.                               |
 |    26-Apr-04   vnb          Bug # 3467287 - The Transaction List page is  |
 |                             striped by customer and customer site.        |
 |    09-Aug-04   vnb          Bug 3810143 - Payment Date error when Payment |
 |							   Date is hidden
 |    21-Oct-04    vnb       Bug 3961398 - oracle.jbo.domain.Date.getData API|
 |                           not to be used                                  |
 |    20-Jan-05    vnb       Bug 4117211- Modified code logic when 'Reset to |
 |                           Defaults' button is clicked                     |
 |    04-May-09  avepati   Bug # 8403708 - Click on Pay Buttion is allowing  |
 |                           Invoices of Different OU's to pay.              |
 |   19-Mar-2010 nkanchan  Bug # 8293098 - service charges based on credit   |
 |                              card type when making payments               |
 |   15-Oct-12  melapaku  Bug 14672025 - DISCOUNT CALCULATION IS WRONG FOR   |
 |                               FUTURE DATED PAYMENTS.                      |
 |   17-May-13   shvimal    Bug 16819836 - R.TST1222.QA: PAYMENT ERRORS FOR  |
 |                          TRNXN SELECTED FRM DISCOUNT ALERTS AT HOME PAGE  |
 |   10-Jun-14   melapaku   Bug 18948079 - RESET TO DEFAULTS BUTTON NOT      |
 |                          WORKING PROPERLY                                 |
 |   18-Jun-14  melapaku  Bug 19001292 - For a non primary site, discount is | 
 |                                       shown outside discount dates        |
 +===========================================================================*/
package oracle.apps.ar.irec.accountDetails.pay.webui;

/* +======================================================================================+
  -- |                  Office Depot - Project Simplify                                                     |
  -- +======================================================================================+               |
  -- | Name     :   AdvancedPayInvoiceSummaryCO.java                                                                   |
  -- | Rice id  :   E1294, E1356                                                                            |
  -- | Description : Modified the class file for verbal authorization                                       |
  -- |                                                                                                      |
  -- |                                                                                                      |
  -- |Change Record:                                                                                        |
  -- |===============                                                                                       |
  -- |Version   Date              Author              Remarks                                               |
  -- |======   ==========     =============        =======================                                  |
  -- |1.0       5-Oct-2016     Sridevi K           Initial version                                          |
  -- +======================================================================================================+*/

import java.io.Serializable;

import oracle.apps.ar.irec.accountDetails.pay.server.NewCreditCardVORowImpl;
import oracle.apps.ar.irec.accountDetails.pay.webui.MultipleInvoicePayListCO;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;
import oracle.apps.fnd.framework.webui.OADataBoundValueViewObject;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAFlowLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OATableLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;

import oracle.jbo.RowSetIterator;


/**
 * Controller for ...
 */
public class AdvancedPayInvoiceSummaryCO extends MultipleInvoicePayListCO
{
  public static final String RCS_ID="$Header: AdvancedPayInvoiceSummaryCO.java 120.14.12020000.5 2014/06/18 16:21:26 melapaku ship $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "oracle.apps.ar.irec.accountDetails.pay.webui");

  /**
   * Layout and page setup logic for AK region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);

    ((OATableLayoutBean)webBean.findChildRecursive("MultiPayTableLayout")).setWidth("100%");
    webBean.findIndexedChildRecursive("MultiPayRow1").setRendered(true);  // render the date field row
     webBean.findIndexedChildRecursive("MultiPayRow3").setRendered(true);  // render the payment amounts fields row
     Boolean bDiscountAvailable = (Boolean)((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("MultipleInvoicesPayListSummaryVO")).invokeMethod("isDiscountAvailable");
     Boolean bServiceCharge = (Boolean)((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("MultipleInvoicesPayListSummaryVO")).invokeMethod("isServiceChargeApplied");

     // If discounts are available display the discount field
     if (bDiscountAvailable == Boolean.TRUE)
     {
       webBean.findIndexedChildRecursive("DiscountAmtRow1").setRendered(true); // Bug 16819836 - as Discount Amt is moved into rowLayout for 16460868
       webBean.findIndexedChildRecursive("DiscountAmount1").setRendered(true);    
     }

     // If service charges have been applied, display the service charge field
     if (bServiceCharge == Boolean.TRUE)
     {
       webBean.findIndexedChildRecursive("ServiceChargeRow1").setRendered(true); // Bug 16819836 - as Service charge is moved into rowLayout for 16460868 
       webBean.findIndexedChildRecursive("APServiceChargeAmount").setRendered(true);
       webBean.findIndexedChildRecursive("AdvPmtServiceChargeTip").setRendered(true);
     }
  
    
    OAMessageTextInputBean paymentAmtBean = (OAMessageTextInputBean)webBean.findIndexedChildRecursive("PaymentAmt");
    paymentAmtBean.setAttributeValue(TABULAR_FUNCTION_VALUE_ATTR,
                                 new OADataBoundValueViewObject(webBean,
                                                                "TotalPaymentAmountFormatted",
                                                                "MultipleInvoicesPayListSummaryVO"));

    //Bug 3559788 - "Reset to Defaults" button made a TableAction button.
    //Render the Table Actions region in the Advanced Payment page.
    OAFlowLayoutBean resetToDefaultsRegion = (OAFlowLayoutBean)webBean.findChildRecursive("ResetButtonRegion");
    resetToDefaultsRegion.setRendered(true);
  }

  /**
   * Procedure to handle form submissions for form elements in
   * AK region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormRequest(pageContext, webBean);

    String formEvent = pageContext.getParameter("_FORMEVENT");
    String submitButtonValue = pageContext.getParameter(FORM_SUBMIT_BUTTON);    
    String sEvent =  pageContext.getParameter("event");
    
    // If this is a form submission and non of these buttons were pressed
    //Bug 4003058 - 'PMButton' param no more used - removed reference to it
    if (! "PaymentButton".equals(pageContext.getParameter("PaymentButton")) &&
        ! "AdvPaymentButton".equals(pageContext.getParameter("AdvPaymentButton")) &&        
        pageContext.isFormSubmission() && ! "goto".equals(sEvent))
    {
      // Check if the payment is in process ....
      // If so then do nothing .....
      OAApplicationModuleImpl rootAM = (OAApplicationModuleImpl) pageContext.getRootApplicationModule();      
      OADBTransactionImpl tx = (OADBTransactionImpl) rootAM.getDBTransaction();
      
      String sPaymentInProcess = (String)(tx.getValue("PaymentInProcess")==null?"N":tx.getValue("PaymentInProcess"));	 
      
      if ("Y".equals(sPaymentInProcess))
      {
        return;
        //pageContext.redirectToDialogPage(new OADialogPage(STATE_LOSS_ERROR));        
      }

      //Bug3019729: MultiplePay functionality
      OAApplicationModuleImpl pageAM = (OAApplicationModuleImpl) pageContext.getApplicationModule(webBean);      
      //Bug 3467287- The VOs have been striped by Customer and Customer Site.
	    //These have to be passed as parameters.
      String sCustomerId        = getActiveCustomerId(pageContext);
      // Added below code for Bug 19001292
      String sCustomerSiteId = null;
      String AllLoc = (String)pageContext.getSessionValue("FromAllLoc");
      if(AllLoc != null && "Y".equals(AllLoc)){
           sCustomerSiteId = null;
      }
      else
        sCustomerSiteId  = getActiveCustomerUseId(pageContext);
      Serializable [] params = {sCustomerId, sCustomerSiteId};
   //Bug #8293098 Surcharge for different card types
      String sPaymentType = pageContext.getParameter("PaymentType");
      String sPayType = "BANK_ACCOUNT";
      String sLookupCode = null;
      
  if (tx.isLoggingEnabled(OAFwkConstants.PROCEDURE)) {
     tx.writeDiagnostics(this, "Start AdvancedPayInvoiceSummaryCO.processRequest", OAFwkConstants.PROCEDURE);
     tx.writeDiagnostics(this, "Parameters sPayType, sLookupCode: " + sPayType + ", " + sLookupCode, OAFwkConstants.PROCEDURE);
  }
      if ("NEW_CC".equals(sPaymentType) || "EXISTING_CC".equals(sPaymentType)) {
         sPayType = "CREDIT_CARD";
         String sViewObject;
         String sMethod;
         String sCreditCardType;
           if ("NEW_CC".equals(sPaymentType)) {
             sViewObject = "NewCreditCardVO";
             sMethod = "getCreditCardType";
             RowSetIterator it = ((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject(sViewObject)).createRowSetIterator("iter");
             NewCreditCardVORowImpl card = (NewCreditCardVORowImpl)it.next();
             it.reset();
             it.closeRowSetIterator();
             sCreditCardType = card.getCreditCardType();
           }
           else {
             sViewObject = "CreditCardsVO";
             sMethod = "getSelectedCreditCardBrand";
             sCreditCardType = (String)((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject(sViewObject)).invokeMethod("getSelectedCreditCardBrand");
           }
           sLookupCode = sCreditCardType;
      }
      Serializable [] paramsForSurcharge = {sCustomerId, sCustomerSiteId, sPayType, sLookupCode};

      //"Reset to Defaults" button pressed
      if ("resetAmountsButton".equals(sEvent)) 
      {
        // Added below line of code for Bug 18948079 - Post changes to the database       
        tx.postChanges();
        String sReceiptDate = pageContext.getOANLSServices().
                                  dateToString(pageContext.getCurrentDBDate());
        tx.putValue("ReceiptDate", sReceiptDate);

        pageAM.invokeMethod("resetPaymentAmounts", paramsForSurcharge);        
      }
      //"Recalculate" button pressed
      else if ("update".equals(sEvent))
      {
        // Assumption that this means the recalculate button was clicked
        // Post changes to the database       
        tx.postChanges();
        //Modified for Bug#14672025 : Start
        String sReceiptDate = pageContext.getOANLSServices().
                                   dateToString(pageContext.getCurrentDBDate());
        tx.putValue("ReceiptDate", sReceiptDate);
        //Modified for Bug#14672025 : End
        //Bug3019729: MultiplePay functionality
        // Recalculate the amounts               
        pageAM.invokeMethod("recalculateAmounts", paramsForSurcharge);

      }
	  else if ("calculateupd".equals(sEvent))
      {
    	  // Assumption that this means the recalculate button was clicked
        // Post changes to the database       
        tx.postChanges();
        //Modified for Bug#14672025 : Start
        String sReceiptDate = pageContext.getOANLSServices().
                                   dateToString(pageContext.getCurrentDBDate());
        tx.putValue("ReceiptDate", sReceiptDate);
        //Modified for Bug#14672025 : End
        //Bug3019729: MultiplePay functionality
        // Recalculate the amounts               
        pageAM.invokeMethod("recalculateAmounts", paramsForSurcharge);

      }
   
      //Bug # 8403708 : adding orgId to params 
      String sOrgId = getActiveOrgId(pageContext);
             params = new Serializable[] {sCustomerId, sCustomerSiteId,sOrgId};  
            
      // Initialize the VO
      ((OAViewObject)pageAM.findViewObject("MultipleInvoicesPayListSummaryVO")).invokeMethod("initQuery", params);
      
      // Re-Query the Summary Table VO
      pageAM.invokeMethod("initMultipleInvoicePayList", params);

    }
  }


  private void initializePayList(OAPageContext pageContext, OAWebBean webBean)
  {
    String sPaymentScheduleId = (String)pageContext.getParameter("Irpaymentscheduleid");
    String sCurrencyCode = (String)pageContext.getParameter("Ircurrencycode");
    //Bug 3607343 - In case the currency code is not present in the URL parameters,
    //get the active currency.
    if (sCurrencyCode == null)
      sCurrencyCode = getActiveCurrencyCode(pageContext);
    String sCustomerId        = getActiveCustomerId(pageContext);
    String sCustomerSiteUseId = getActiveCustomerUseId(pageContext);
    // KRMENON - HACK TO BE REMOVED!!!
    if ( null == sCustomerId ) 
    {
      sCustomerId = "1003";
      setActiveCustomerId(pageContext, "1003");
    } 
  
    Serializable[] mpParam = {sCustomerId, sCustomerSiteUseId,sCurrencyCode, sPaymentScheduleId};
    Class[] mpParamClass = {java.lang.String.class, java.lang.String.class, java.lang.String.class, java.lang.String.class};
    //Bug3019729: MultiplePay functionality
    // Call the AM to initialize the temporary table
    // pageContext.getRootApplicationModule().invokeMethod("initMultiplePayList",mpParam, mpParamClass);
    pageContext.getApplicationModule(webBean).invokeMethod("initMultiplePayList",mpParam, mpParamClass);    
    
  }
  
}