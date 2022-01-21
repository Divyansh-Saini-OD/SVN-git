 /*===========================================================================+
  |      Copyright (c) 2001, 2014 Oracle Corporation, Redwood Shores, CA, USA       |
  |                         All rights reserved.                              |
  +===========================================================================+
  |  HISTORY                                                                  |
  |    22-Jan-2001  Jani Rautiainen       Created.                            |
  |    22-Jan-2001  albowicz          Fixed bug where Global Buttons were     |
  |                                   not being processed on redirect to      |
  |                                   OADialogPage.  See bug 2890625          |
  |    23-Jun-03    yreddy            Bug3019729: MultiplePay functionality   |
  |    21-Oct-03  hikumar      Bug # 3186472 - Modified for URL security      |
  |    09-Dec-03  vnb          Bug # 3303162 - Modified for removal of GO     |
  |                            button for Payment Method choice list          |
  |       10-Feb-04    vnb    Bug # 3367661 - Check isLoggingEnabled before   |
  |                           calling writeDiagnostics                        |
  |    30-Apr-04  vnb         Bug # 3338276 - Enable only "New Credit Card" as|
  |                           payment method if one-time payment is enabled.  |
  |    26-Apr-04  vnb         Bug # 3467287 - ValidatePage method modified to |
  |                                               add Customer and Customer Site as parameters    |
  |    06-Jul-04  vnb         Bug 3630101 - Payment process setup errors to be|
  |                           displayed to internal user                      |
  |    21-Sep-04  vnb         Bug # 3886652 - Customer and Customer site added|
  |                                                       as params to configurable ARI_CONFIG APIs       |
  |    21-Oct-04    vnb       Bug 3961398 - oracle.jbo.domain.Date.getData API|
  |                           not to be used                                  |
  |    03-Nov-04  vnb         Bug 3335944 - One Time Credit Card Verification|
  |    27-Nov-04   vnb          Bug 4033881 - Close RowSetIterator            |
   |    18-Jan-04  rsinthre    Bug 3913875 - Payment Confirmation              |
  |    24-Jan-04  rsinthre    Bug 4135729 - Payment made with one time CC     |
  |                           enabled shows Card saved message                |
  |    03-Feb-05   vnb        Bug 4103494 - Float values should not used for  |
  |                           comparisons                                     |
  |    31-Mar-05   rsinthre   Bug 4243047 - Credit Card validation accepts    |
  |                                                       decimal numbers                                                               |
  |    25-Apr-05   rsinthre   Bug 4322904 - Null pointer exception when       |
  |                           clicking pay button                             |
  |    05-Jul-05  rsinthre  Bug 4221520 - Uptake of consolidated bank accounts|
  |                                               funds capture enhancements                                        |
  |    18-Oct-05  rsinthre  Bug 4673563 - Error making credit card payment    |
  |    03-Nov-05  rsinthre  Bug 4661432 - Update last used payment instrument |
  |                         when save payment instrument profile is Yes       |
  |    10-Nov-05  rsinthre  Bug 4721421 - Card Security Code not shown for    |
  |                         Master Card in Saved CC Pmt Method                |
  |    21-Nov-05  rsinthre  Bug 4744886 - Display CVV Code and Billing Address|
  |                         in Quick Payment Page                             |
  |    24-Nov-05  rsinthre  Bug 4760655 - Payment page shows stale data error |
  |    12-Dec-07   avepati  Bug 6622674 -JAVA CODE CHANGES FOR JDBC 11G ON MT |
  |    29-Dec-08  avepati   Bug 7673372 - WHEN PAYMENT ERRS BECOZ OF IPAYMENT |
  |                                        VALIDATION ERR IS NOT SHOWN        |
  |    12-Mar-09  avepati   Bug 8320027 - UPDATING CREDIT CARD EXPIRATION     |
  |                                            DATE IS NOT CORRECT            |
  |    26-Mar-09  avepati   Bug 8333422 - previously saved credit card detals |
  |                           only if the form is closed and re-opned         |
  |    04-May-09  avepati   Bug 8403708 - Click on Pay Button is allowing to  |
  |                            to pay invoices of different OU's              |
  |    09-Jul-09  avepati   Bug 8663612 - PADSS1O :QA:ERROR IS COMING WHILE   |
  |                                       CLICKING ON PAY                     |
  |    04-Aug-09  avepati   Bug#8664350 Unable to laod federal service ACHdata|
  |   19-Mar-2010 nkanchan  Bug # 8293098 - service charges based on credit   |
  |                              card type when making payments               |
  |    11-Oct-10  avepati     Bug  10121591 - 12I CREDIT CARDS AFTER UPGRADE  |
  |                              DOES NOT HAVE EXPIRY DATES POPULATED         |
  |    10-Feb-11  avepati   Bug 11682485-Need to Restrict Zero Dollar Receipts|
  |    17-Mar-11   nkanchan  Bug 11871875 - fp:9193514 :transaction           |
  |                           list disappears in ireceivables                 |
  |    11-Apr-11  avepati   Bug 9910157 - Auth code not seen in cc payment    |
  |    22-Jul-12  melapaku  Bug 14055345 - Added debug stmts as a part of this|
  |                         bug - Credit Card Payment is upto nearest 100     |
  |    08-Oct-12  melapaku  Bug 14556872 - FIELD REQUIRED ON PAYMENT SCREEN TO|
  |                         GIVE CUSTOMERS OPTION TO SAVE CREDIT CARD         |
  |    15-Oct-12  melapaku  Bug 14672025 - DISCOUNT CALCULATION IS WRONG FOR  |
  |                               FUTURE DATED PAYMENTS.                      |
  |    27-Dec-12  melapaku  Bug 14797865 - ccard billing address defaulting & |
  |                                        q.pymt page appearance inconsiste  |
  |    06-Feb-13  melapaku  Bug 16262617 - cannot remove end date entered via |
  |                                        ireceivables pay function          |
  |    18-Feb-13  melapaku  Bug 14797901 - Message incorrect if save credit   |
  |                                        card is unchecked                  |
  |    11-Mar-13  melapaku  Bug 16471455 - Payment Audit History Feature      |
  |    26-Jun-13  shvimal   Bug 16980426 - CREDIT CARD PAYMENT GIVES JAVA.LANG.STRINGINDEXOUTOFBOUNDSEXCEPTION: STRING INDE |
  |    21-Jul-14  melapaku  Bug 19222335 - Missing bank account after payment |
  |                                        and logout                         |
  |    23-Jul-14  melapaku  Bug 17475275 - TST1223:Credit card details being  |
  |                                        shown twice, when paid part by part|
  +===========================================================================*/

 /**
  * This class contains the controller object for the Payments page
  *
  * @author      Jani Rautiainen
  */
 package oracle.apps.ar.irec.accountDetails.pay.utilities;
 /* +======================================================================================+
  -- |                  Office Depot - Project Simplify                                             |
  -- |                       WIPRO Technologies                                                         |
  -- +======================================================================================+
  -- | Name     :   PaymentUtilities.java                                                                   |
  -- | Rice id  :   E1294, E1356                                                                    |
  -- | Description : Modified the class file for verbal authorization                                       |
  -- |                                                                                                      |
  -- |                                                                                                      |
  -- |Change Record:                                                                                        |
  -- |===============                                                                                       |
  -- |Version   Date              Author              Remarks                                               |
  -- |======   ==========     =============        =======================                          |
  -- |1.0       10-Aug-2007   Madankumar J         Initial version                                      |
  -- |                       Wipro Technologies                                                             |
  -- |                                                                                                      |
  -- |1.1       03-NOv-2007   Madankumar J         Defect 2462(CR 247)                                      |
  -- |                                                                                                      |
  -- |1.2       28-Mar-2008   Madankumar J         As the patch is applied,                                 |
  -- |                                             modified the standard                                    |
  -- |                                             class file to include                                    |
  -- |                                             changes for verbal Auth                                  |
  -- |                                                                                                      |
  -- |1.3       13-Jun-2008   Sambasiva Reddy D    Defect 6326                                              |
  -- |1.4       11-Apr-2009   Rama Krishna K       Defect 14159                                             |
  -- |2.0       2-Sep-2013    Sridevi K            Retrofitted for                                          |
  -- |                                             R12 upgrade                                              |
  -- |3.0       3-Dec-2013   Sridevi K            modified for                                              |
  -- |                                             Defect27242                                              |
  -- |4.0       21-Jan-2014   Sridevi K            modified for                                             |
  -- |                                             Defect27242                                              |
  -- |5.0       30-Jan-2014   Sridevi K            modified for                                             |
  -- |                                             Defect27766 Voice Auth                                   |
  -- |6.0        5-FEB-2014   Sridevi K            Modified for Defect27888                                 |
  -- |7.0        19-Jun-2014  Shubhashree R        For Defect 30058, added the logic to                     |
  -- |                                             replace special characters in Acct                       |
  -- |                                             Holder's name with ""                                    |
  -- |8.0       10-Sep-2014   Rajeev V             Defect 30873 Credit Card Rounding                        |
  -- |9.0       8-Jan-2015    Sridevi K            Retrofitted picking patch version 19052386               |
  -- |10.0      4-Mar-2015    Sridevi K            Modified for CR1120                                      |
  -- |11.0      14-Jun-2016   Sridevi K           Modified for Defect38030                                  |
  -- |12.0      29-Aug-2016   Vasu Raparla        Reretrofitted for 12.2.5 upgrade                          |
  -- |12.1      12-Oct-2016   Sridevi K           Included vantiv changes                                   |
  -- |12.2      17-FEB-2017   MBolli			  Thread Leak 12.2.5 Upgrade - close all statements, resultsets |
    -- +======================================================================================================+*/

  import java.io.Serializable;

  import oracle.apps.fnd.common.VersionInfo;
  import oracle.apps.fnd.framework.webui.OAPageContext;
  import oracle.apps.fnd.framework.webui.beans.OAWebBean;
  import oracle.apps.fnd.framework.OAViewObject;
  import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
  import oracle.apps.fnd.framework.server.OADBTransaction;
  import oracle.apps.fnd.framework.server.OADBTransactionImpl;
  import oracle.apps.ar.irec.accountDetails.pay.server.NewCreditCardVORowImpl;
  import oracle.apps.ar.irec.accountDetails.pay.server.SavedCCAddressVORowImpl;
  import oracle.apps.ar.irec.accountDetails.pay.server.CreditCardsVOImpl;
  import oracle.apps.ar.irec.accountDetails.pay.server.BankAccountsVOImpl;
  import oracle.apps.ar.irec.accountDetails.pay.server.NewBankAccountVORowImpl;
  import oracle.apps.ar.irec.accountDetails.pay.server.DefaultPaymentInstrumentVOImpl;
  import oracle.apps.ar.irec.accountDetails.pay.server.MultipleInvoicesPayListSummaryVOImpl;
  import oracle.apps.ar.irec.accountDetails.pay.server.MultipleInvoicesPayListSummaryVORowImpl;
  import oracle.apps.ar.irec.accountDetails.pay.server.DefaultPaymentInstrumentVORowImpl;
  import oracle.apps.fnd.framework.OAException;
  import oracle.apps.fnd.framework.webui.beans.message.OAMessageCheckBoxBean;

  import oracle.jbo.RowSetIterator;

  import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
  import oracle.apps.fnd.framework.webui.OADialogPage;

  import oracle.jbo.domain.Number;

  import java.sql.Date;

  import oracle.apps.fnd.framework.OAFwkConstants;
  import oracle.apps.fnd.framework.webui.OAWebBeanConstants;

  import oracle.jdbc.OracleCallableStatement;

  import java.text.SimpleDateFormat;

  import java.sql.Types;

  import com.sun.java.util.collections.ArrayList;
  import com.sun.java.util.collections.HashMap;
  import com.sun.java.util.collections.Iterator;

  import java.util.StringTokenizer;

  import oracle.apps.ar.irec.accountDetails.pay.server.PaymentAMImpl;
  import oracle.apps.jtf.base.Logger;

  import java.text.ParseException;

  import oracle.jdbc.OraclePreparedStatement;
  import oracle.jdbc.OracleResultSet;

  import java.sql.SQLException;
  import java.sql.Connection;

  import java.sql.PreparedStatement;
  import java.sql.ResultSet;

  import oracle.apps.fnd.common.MessageToken;

  /*Start - Added for R12 upgrade retrofit*/
  // Added below import by RK for fixing bin patches on Sep 17th 2009
  import oracle.apps.ar.irec.accountDetails.pay.server.MultipleInvoicesPayListVOImpl;
  import oracle.apps.ar.irec.accountDetails.pay.server.MultipleInvoicesPayListVORowImpl;
  import oracle.apps.ar.irec.accountDetails.pay.webui.PaymentFormCO;
  import oracle.apps.fnd.framework.OAApplicationModule;
  import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
  /*End - Added for R12 upgrade retrofit*/

  public class PaymentUtilities {

      public static final String RCS_ID =
          "$Header: PaymentUtilities.java 120.53.12020000.20 2014/11/04 09:57:12 gnramasa ship $";
      public static final boolean RCS_ID_RECORDED =
          VersionInfo.recordClassVersion(RCS_ID,
                                         "oracle.apps.ar.irec.accountDetails.pay.utilities");
      public static final String pkgName =
          "oracle.apps.ar.irec.accountDetails.pay.utilities.PaymentUtilities";
      public static final String G_FAILED = "FAILED";
      public static final String G_SUCCESSFUL = "SUCCESSFUL";

      /*Start - Added for R12 upgrade retrofit*/
      public static String Gc_Authcode =
          null; //Included for E1294 by Madankumar J,Wipro Technologies
      public static String Gc_bep_code =
          null; //Included for the CR2462 by Madankumar J,Wipro Technologies
      /*End - Added for R12 upgrade retrofit*/

      public PaymentUtilities() {
      }

      public static void payInvoiceInstallment(Object callingObject,
                                               String paymentType,
                                               OAPageContext pageContext,
                                               OAWebBean webBean,
                                               String sCustSiteUseIdForPayment) {

          if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
              pageContext.writeDiagnostics(pkgName,
                                           "start payInvoiceInstallment",
                                           OAFwkConstants.PROCEDURE);

          if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
              pageContext.writeDiagnostics(pkgName,
                                           "paymentType = " + paymentType,
                                           OAFwkConstants.STATEMENT);
          //Added for Bug 14055345
          if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT)) {
              pageContext.writeDiagnostics(pkgName,
                                           "paymentType = " + paymentType,
                                           OAFwkConstants.STATEMENT);
              pageContext.writeDiagnostics(pkgName,
                                           "*** Inside payInvoiceInstallment method ****",
                                           OAFwkConstants.STATEMENT);
              pageContext.writeDiagnostics(pkgName,
                                           "paymentType = " + paymentType,
                                           OAFwkConstants.STATEMENT);
              pageContext.writeDiagnostics(pkgName,
                                           "sCustSiteUseIdForPayment = " +
                                           sCustSiteUseIdForPayment,
                                           OAFwkConstants.STATEMENT);
              pageContext.writeDiagnostics(pkgName,
                                           "PageContext Session ID -->>" +
                                           pageContext.getSessionId(),
                                           OAFwkConstants.STATEMENT);
              pageContext.writeDiagnostics(pkgName,
                                           "User Name -->>" + pageContext.getUserName(),
                                           OAFwkConstants.STATEMENT);
              pageContext.writeDiagnostics(pkgName,
                                           "User ID -->>" + pageContext.getUserId(),
                                           OAFwkConstants.STATEMENT);
          }


          //Bug2823323    try {
          OAApplicationModuleImpl rootAM =
              (OAApplicationModuleImpl)pageContext.getRootApplicationModule();
          //Bug3019729: MultiplePay functionality
          OAApplicationModuleImpl pageAM =
              (OAApplicationModuleImpl)pageContext.getApplicationModule(webBean);
          OADBTransaction tx = (OADBTransaction)rootAM.getDBTransaction();

          String status = "";
          String sPaymentScheduleId =
              pageContext.getParameter("Irpaymentscheduleid");
          Number paymentScheduleId = null;
          Number customerId = null;
          Number paymentAmount = null;
          Number discountAmount = null;
          Number serviceCharge = null;
          Number totalPaymentAmount = null;
          Number bankAccountId = null;
          Number bankBranchId = null;
          Number bankId = null;
          Number cashReceiptId = null;
          Number customerSiteUseId = null;
          String currencyCode = "";
          String accountNumber = "";
          String routingNumber = "";
          String accountHolderName = "";
          String accountType = "";
          String sPaymentInstrument =
              "BANK_ACCOUNT"; //Either 'CREDIT_CARD' or 'BANK_ACCOUNT'
          Date expirationDate = null;
          Date receiptDate = null;
          String sql = "";
          Boolean bSingleInstallment = Boolean.FALSE;
          Boolean bCreditCardUpdated = Boolean.FALSE;
          String sNewAccount = "FALSE";
          String cardIssuerCode = null;
          Number CCBillSiteId = null;
          String singleUseFlag = "N";
          String sIban = null;
          Number instr_assignment_id = new Number(0);
          Number bankPartyId = null;
          Number branchPartyId = null;
          String currency = null;
          Number objectVersionNo = null;

          //Bug 3335944 - One Time Credit Card Verification
          String sAddressLine1 = null;
          String sAddressLine2 = null;
          String sAddressLine3 = null;
          String sAddressLine4 = null; //Added for Bug#14797865
          String sCity = null;
          String sCounty = null;
          String sState = null;
          String sCountry = null;
          String sPostalCode = null;

          String sCVV2 = null;
          //Added for Bug 14055345
          Connection pConn =
              pageContext.getApplicationModule(webBean).getOADBTransaction().getJdbcConnection();
          OraclePreparedStatement pStmt = null;
          OracleResultSet rs = null;
          long customer_site_use_id = -1;
          try {
              pStmt =
                      (OraclePreparedStatement)pConn.prepareStatement("select * from ar_irec_payment_list_gt");
              rs = (OracleResultSet)pStmt.executeQuery();
              while (rs.next()) {
                  long customer_id = rs.getLong("CUSTOMER_ID");
                  customer_site_use_id = rs.getLong("CUSTOMER_SITE_USE_ID");
                  String account_number = rs.getString("ACCOUNT_NUMBER");
                  String trx_number = rs.getString("TRX_NUMBER");
                  long payment_schedule_id = rs.getLong("PAYMENT_SCHEDULE_ID");
                  String pay_status = rs.getString("STATUS");
                  String currency_code = rs.getString("CURRENCY_CODE");
                  double amount_due_original =
                      rs.getDouble("AMOUNT_DUE_ORIGINAL");
                  double discount_amount = rs.getDouble("DISCOUNT_AMOUNT");
                  double service_charge = rs.getDouble("SERVICE_CHARGE");
                  double payment_amt = rs.getDouble("PAYMENT_AMT");
                  int number_of_installments =
                      rs.getInt("NUMBER_OF_INSTALLMENTS");
                  double line_amount = rs.getDouble("LINE_AMOUNT");
                  double tax_amount = rs.getDouble("TAX_AMOUNT");
                  double freight_amount = rs.getDouble("FREIGHT_AMOUNT");
                  long cash_receipt_id = rs.getLong("CASH_RECEIPT_ID");
                  double finance_charges = rs.getDouble("FINANCE_CHARGES");
                  double original_discount_amt =
                      rs.getDouble("ORIGINAL_DISCOUNT_AMT");
                  long org_id = rs.getLong("ORG_ID");
                  long pay_for_customer_id = rs.getLong("PAY_FOR_CUSTOMER_ID");
                  long pay_for_customer_site_id =
                      rs.getLong("PAY_FOR_CUSTOMER_SITE_ID");
                  double dispute_amt = rs.getDouble("DISPUTE_AMT");
                  if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT)) {
                      pageContext.writeDiagnostics(pkgName,
                                                   " ---- START : VALUES IN AR_IREC_PAYMENT_LIST_GT TABLE -----",
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "customer_id -->>" + customer_id,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "customer_site_use_id -->>" +
                                                   customer_site_use_id,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "account_number -->>" +
                                                   account_number,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "trx_number -->>" + trx_number,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "payment_schedule_id -->>" +
                                                   payment_schedule_id,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "status -->>" + pay_status,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "currency_code -->>" +
                                                   currency_code,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "amount_due_original -->>" +
                                                   amount_due_original,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "discount_amount -->>" +
                                                   discount_amount,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "service_charge -->>" +
                                                   service_charge,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "payment_amt -->>" + payment_amt,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "number_of_installments -->> " +
                                                   number_of_installments,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "line_amount -->>" + line_amount,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "tax_amount -->>" + tax_amount,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "freight_amount -->>" +
                                                   freight_amount,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "cash_receipt_id -->>" +
                                                   cash_receipt_id,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "finance_charges -->>" +
                                                   finance_charges,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "original_discount_amt -->>" +
                                                   original_discount_amt,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "org_id -->>" + org_id,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "pay_for_customer_id -->>" +
                                                   pay_for_customer_id,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "pay_for_customer_site_id -->>" +
                                                   pay_for_customer_site_id,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "dispute_amt -->>" + dispute_amt,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   " ---- END : VALUES IN AR_IREC_PAYMENT_LIST_GT TABLE -----",
                                                   OAFwkConstants.STATEMENT);
                  }
              }

              rs.close();
              pStmt.close();

          } catch (SQLException e) {


          } finally {
              try {
                  if (rs != null)
                      rs.close();
                  if (pStmt != null)
                      pStmt.close();
              } catch (SQLException e) {

              }
          }

          try {
              if (sPaymentScheduleId != null)
                  paymentScheduleId = new Number(sPaymentScheduleId);
              //Bug3019729: MultiplePay functionality
              RowSetIterator iter =
                  ((MultipleInvoicesPayListSummaryVOImpl)pageAM.findViewObject("MultipleInvoicesPayListSummaryVO")).createRowSetIterator("iter");
              iter.reset();
              MultipleInvoicesPayListSummaryVORowImpl row =
                  (MultipleInvoicesPayListSummaryVORowImpl)iter.next();
              iter.closeRowSetIterator();

              customerId = row.getCustomerId();
              //Modified below code for Bug 19222335 : Start
              // customerSiteUseId  = row.getCustomerSiteUseId();
              String AllLoc = (String)pageContext.getSessionValue("FromAllLoc");
              if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
                  pageContext.writeDiagnostics(pkgName,
                                               "AllLoc session variable value >> " +
                                               AllLoc, OAFwkConstants.STATEMENT);
              if (AllLoc == null ||
                  "".equals(AllLoc) && customer_site_use_id > 0)
                  customerSiteUseId = new Number(customer_site_use_id);
              if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
                  pageContext.writeDiagnostics(pkgName,
                                               "customerSiteUseId  >> " +
                                               customerSiteUseId,
                                               OAFwkConstants.STATEMENT);
              //Modified below code for Bug 19222335 : End
              //Bug 4103494 - Float values should not used for comparisons
              if (row.getTotalNumberOfInstallments().compareTo(1) > 0)
                  bSingleInstallment = Boolean.FALSE;

              String sIsCreditCardUpdated =
                  (String)tx.getValue("CreditCardUpdated");
              if (null != sIsCreditCardUpdated &&
                  "TRUE".equals(sIsCreditCardUpdated))
                  bCreditCardUpdated = Boolean.TRUE;

              discountAmount = row.getTotalDiscount();
              paymentAmount = row.getTotalPaymentAmount();
              serviceCharge = row.getTotalServiceCharge();
              currencyCode = row.getCurrencyCode();
              totalPaymentAmount = paymentAmount.add(serviceCharge);
              // Added for Bug 14055345
              if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT)) {
                  pageContext.writeDiagnostics(pkgName,
                                               "-- Start :: Values inside PaymentUtilities.payInvoiceInstallment() --",
                                               OAFwkConstants.STATEMENT);
                  pageContext.writeDiagnostics(pkgName,
                                               "discountAmount :: " + discountAmount,
                                               OAFwkConstants.STATEMENT);
                  pageContext.writeDiagnostics(pkgName,
                                               "paymentAmount :: " + paymentAmount,
                                               OAFwkConstants.STATEMENT);
                  pageContext.writeDiagnostics(pkgName,
                                               "serviceCharge :: " + serviceCharge,
                                               OAFwkConstants.STATEMENT);
                  pageContext.writeDiagnostics(pkgName,
                                               "currencyCode :: " + currencyCode,
                                               OAFwkConstants.STATEMENT);
                  pageContext.writeDiagnostics(pkgName,
                                               "totalPaymentAmount :: " +
                                               totalPaymentAmount,
                                               OAFwkConstants.STATEMENT);
                  pageContext.writeDiagnostics(pkgName,
                                               "-- End :: Values inside PaymentUtilities.payInvoiceInstallment() --",
                                               OAFwkConstants.STATEMENT);
              }

              String sReceiptDate = (String)tx.getValue("ReceiptDate");
              //Bug 3961398 - oracle.jbo.domain.Date.getData API not to be used by development teams
              //getData replaced by dateValue API
              if (!(null == sReceiptDate))
                  receiptDate = tx.getOANLSServices().stringToDate(sReceiptDate);
              else
                  receiptDate =
                          getJBODomainDate(pageContext.getCurrentDBDate()).dateValue();

              //      String sProfile = pageContext.getProfile("OIR_VERIFY_CREDIT_CARD_DETAILS");

              OADBTransaction trx =
                  (OADBTransaction)pageContext.getApplicationModule(webBean).getOADBTransaction();
              String sProfile = (String)trx.getValue("VerifyCreditCardDetails");

              if (paymentType.equals("NEW_CC")) {

                  /*        OAMessageChoiceBean newCCIssuerList = (OAMessageChoiceBean)webBean.findIndexedChildRecursive("NewCreditCardType");
          cardIssuerCode                     = (String)accountTypeList.getSelectionValue(pageContext); */
                  sPaymentInstrument = "CREDIT_CARD";
                  sNewAccount = "TRUE";

                  sql =
  "BEGIN AR_IREC_PAYMENTS.pay_invoice_installment_new_cc(:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12); END;";

                  RowSetIterator iter2 =
                      ((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("NewCreditCardVO")).createRowSetIterator("iter");
                  iter2.reset();
                  NewCreditCardVORowImpl newCCrow =
                      (NewCreditCardVORowImpl)iter2.next();
                  iter2.closeRowSetIterator();

                  accountNumber = newCCrow.getStrippedCreditCardNumber();
                  accountHolderName = newCCrow.getCreditCardHolderName();
                  cardIssuerCode = newCCrow.getCreditCardType();

                  String savePaymentFlagSql =
                      "BEGIN :1 := ARI_UTILITIES.is_save_payment_instr_enabled(p_customer_id => :2, p_customer_site_use_id => :3); END;";
                  //The below piece of code is used to find out whether the credit card details have to be saved or not.
                  OracleCallableStatement cStmt =
                      (OracleCallableStatement)tx.createCallableStatement(savePaymentFlagSql,
                                                                          1);
                  try {
                      cStmt.registerOutParameter(1, Types.VARCHAR, 0, 4000);
                      String custId = customerId.toString();
                      String custSiteUseId =
                          (customerSiteUseId == null ? null : customerSiteUseId.toString());

                      cStmt.setString(2, custId);
                      cStmt.setString(3, custSiteUseId);

                      cStmt.execute();
                      if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
                          pageContext.writeDiagnostics(pkgName,
                                                       "Save Payment Instrument Info Enabled Value -->>" +
                                                       cStmt.getString(1),
                                                       OAFwkConstants.STATEMENT);
                      // Modified for Bug#14556872 : Start
                      OAMessageCheckBoxBean saveCreditCardFlag =
                          (OAMessageCheckBoxBean)webBean.findIndexedChildRecursive("SaveCreditCard");
                      if ("Y".equals(cStmt.getString(1))) {
                          if (saveCreditCardFlag != null) {
                              Object saveCreditCardCheckBoxObj =
                                  saveCreditCardFlag.getValue(pageContext);
                              if (saveCreditCardCheckBoxObj != null) {
                                  String saveCreditCardCheckBoxValue =
                                      saveCreditCardCheckBoxObj.toString();
                                  if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
                                      pageContext.writeDiagnostics(pkgName,
                                                                   "Save Credit Card CheckBox Value -->>" +
                                                                   saveCreditCardCheckBoxValue,
                                                                   OAFwkConstants.STATEMENT);
                                  if ("Y".equals(saveCreditCardCheckBoxValue))
                                      singleUseFlag = "N";
                                  else
                                      singleUseFlag = "Y";
                              } // if saveCreditCardCheckBoxObj != null
                          }
                      } else // When OIR_SAVE_PAYMENT_INSTR_INFO is set to NO/NULL
                          singleUseFlag = "Y";
                      if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
                          pageContext.writeDiagnostics(pkgName,
                                                       "singleUseFlag Value -->>" +
                                                       singleUseFlag,
                                                       OAFwkConstants.STATEMENT);
                      // Modified for Bug#14556872 : End
                  } catch (Exception e) {
                      throw OAException.wrapperException(e);
                  } finally {
                      try {
                          cStmt.close();
                      } catch (Exception e) {
                          throw OAException.wrapperException(e);
                      }
                  } //finally

                  Integer iYear =
                      Integer.valueOf((String)newCCrow.getExpiryYear());
                  Integer iMonth =
                      Integer.valueOf((String)newCCrow.getExpiryMonth());
                  String sNewCCDate =
                      newCCrow.getExpiryYear() + "-" + newCCrow.getExpiryMonth() +
                      "-" +
                      getLastDayOfMonth(iMonth.intValue(), iYear.intValue());

                  SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
                  java.util.Date d = sdf.parse(sNewCCDate);
                  expirationDate = new java.sql.Date(d.getTime());

                  //Bug 3335944 - One Time Credit Card Verification
                  // Bug 4243047 - Credit Card validation accepts decimal numbers

                  if ("NONE".equals(sProfile) ||
                      ("SECURITY_CODE".equals(sProfile))) {
                      CCBillSiteId = new Number(0);
                  } else {
                      sAddressLine1 = newCCrow.getAddress1();
                      sAddressLine2 = newCCrow.getAddress2();
                      sAddressLine3 = newCCrow.getAddress3();
                      //Added for Bug#14797865
                      sAddressLine4 = newCCrow.getAddress4();
                      sCity = newCCrow.getCity();
                      sCounty = newCCrow.getCounty();
                      sState = newCCrow.getState();
                      sCountry = newCCrow.getCountry();
                      sPostalCode = newCCrow.getPostalCode();
                  }
                  String sCvvCode = newCCrow.getCreditCardCvv();

                  if (sCvvCode != null) {
                      sCvvCode = sCvvCode.trim();
                      if (!checkDigits(sCvvCode)) {
                          //This check is used to ensure that + or - is not entered.
                          throw new OAException("AR",
                                                "ARI_INVALID_CARD_SECURITY_CODE");
                      }

                      try {
                          sCVV2 = sCvvCode;
                      } catch (NumberFormatException e) {
                          //Card security code entered is not in proper number format.
                          throw new OAException("AR",
                                                "ARI_INVALID_CARD_SECURITY_CODE");
                      }

                      //Bug 4721421 - Validate Card Security Code
                      PaymentAMImpl payAM =
                          (PaymentAMImpl)pageContext.getApplicationModule(webBean);
                      boolean validCardSecurityCode =
                          payAM.validateCardSecurityCode(sCvvCode,
                                                         cardIssuerCode);

                      if (!validCardSecurityCode) {
                          throw new OAException("AR",
                                                "ARI_INVALID_CARD_SECURITY_CODE");
                      }
                  }

                  //end

              } else if (paymentType.equals("NEW_BA")) {

                  sNewAccount = "TRUE";
                  sql =
  "BEGIN AR_IREC_PAYMENTS.pay_invoice_installment_new_ba(:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12,:13,:14); END;";

                  RowSetIterator iter3 =
                      ((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("NewBankAccountVO")).createRowSetIterator("iter");
                  iter3.reset();
                  NewBankAccountVORowImpl newBArow =
                      (NewBankAccountVORowImpl)iter3.next();
                  iter3.closeRowSetIterator();

                  accountNumber = newBArow.getStrippedBankAccountNumber();
                  routingNumber = newBArow.getStrippedRoutingNumber();
                  accountHolderName = newBArow.getAccountHolderName();
                  bankId = newBArow.getBankId();
                  bankBranchId = newBArow.getBranchId();
                  sCountry = newBArow.getBankBranchCountry();
                  sIban = newBArow.getIban();
                  //        bankBranchId      = getBankBranchId(pkgName, routingNumber, tx);
                  OAMessageChoiceBean accountTypeList =
                      (OAMessageChoiceBean)webBean.findIndexedChildRecursive("BankAccountType");
                  accountType =
                          (String)accountTypeList.getSelectionValue(pageContext);
                  //SAVED_BA and SAVED_CC changed to EXISTING_CC and EXISTING_BA respectively.
                  //vnb, 9 Dec 2003
              } else if (paymentType.equals("EXISTING_CC") ||
                         paymentType.equals("EXISTING_BA") ||
                         paymentType.equals("DEFAULT")) {

                  if (paymentType.equals("EXISTING_CC")) {
                      sPaymentInstrument = "CREDIT_CARD";
                      sql =
  "BEGIN AR_IREC_PAYMENTS.pay_invoice_installment(:1,:2,:3,:4,:5,:6,:7,:8); END;";
                  } else if (paymentType.equals("EXISTING_BA")) {
                      sql =
  "BEGIN AR_IREC_PAYMENTS.pay_invoice_installment_ba(:1,:2,:3,:4,:5,:6,:7,:8); END;";
                  }

                  String sBankAccountId = "";
                  if (paymentType.equals("EXISTING_CC")) {
                      sPaymentInstrument = "CREDIT_CARD";
                      CreditCardsVOImpl accountVo =
                          ((CreditCardsVOImpl)pageContext.getApplicationModule(webBean).findViewObject("CreditCardsVO"));
                      accountNumber = accountVo.getSelectedCreditCardNumber();
                      cardIssuerCode = accountVo.getSelectedCreditCardBrand();
                      sBankAccountId = accountVo.getSelectedCreditCard();
                      CCBillSiteId = accountVo.getSelectedCCBillSiteId();
                      instr_assignment_id =
                              accountVo.getSelectedInstrAssignmentId();
                      accountHolderName = accountVo.getSelectedCardHolderName();

                      expirationDate = accountVo.getSelectedCardExpiryDate();

                      String sCvvCode =
                          pageContext.getParameter("SavedCCCardSecurityCode");

                      // Bug 16980426 - as CVV can be an empty String if its not a mandatory field
                      if (sCvvCode != null)
                          sCvvCode = sCvvCode.trim();

                      if (sCvvCode != null && sCvvCode.length() > 0) {
                          //sCvvCode = sCvvCode.trim();
                          if (!checkDigits(sCvvCode)) {
                              //This check is used to ensure that + or - is not entered.
                              throw new OAException("AR",
                                                    "ARI_INVALID_CARD_SECURITY_CODE");
                          }

                          try {
                              sCVV2 = sCvvCode;
                          } catch (NumberFormatException e) {
                              //Card security code entered is not in proper number format.
                              throw new OAException("AR",
                                                    "ARI_INVALID_CARD_SECURITY_CODE");
                          }

                          //Bug 4721421 - Validate Card Security Code
                          PaymentAMImpl payAM =
                              (PaymentAMImpl)pageContext.getApplicationModule(webBean);
                          boolean validCardSecurityCode =
                              payAM.validateCardSecurityCode(sCvvCode,
                                                             cardIssuerCode);

                          if (!validCardSecurityCode) {
                              throw new OAException("AR",
                                                    "ARI_INVALID_CARD_SECURITY_CODE");
                          }
                      } else {
                          sCvvCode = null;
                      }

                      if ("NONE".equals(sProfile) ||
                          ("SECURITY_CODE".equals(sProfile))) {
                          CCBillSiteId = new Number(0);
                      } else {
                          RowSetIterator iter2 =
                              ((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("SavedCCAddressVO")).createRowSetIterator("iter");
                          iter2.reset();
                          SavedCCAddressVORowImpl savedCCRow =
                              (SavedCCAddressVORowImpl)iter2.next();
                          iter2.closeRowSetIterator();
                          if (savedCCRow != null) {
                              sAddressLine1 = savedCCRow.getAddress1();
                              sAddressLine2 = savedCCRow.getAddress2();
                              sAddressLine3 = savedCCRow.getAddress3();
                              sAddressLine4 = savedCCRow.getAddress4();
                              sCity = savedCCRow.getCity();
                              sCounty = savedCCRow.getCounty();
                              sState = savedCCRow.getState();
                              sCountry = savedCCRow.getCountry();
                              sPostalCode = savedCCRow.getPostalCode();
                          }
                      }

                  } else if (paymentType.equals("EXISTING_BA")) {

                      BankAccountsVOImpl accountVo =
                          ((BankAccountsVOImpl)pageContext.getApplicationModule(webBean).findViewObject("BankAccountsVO"));
                      sBankAccountId = accountVo.getSelectedBankAccount();
                      instr_assignment_id =
                              accountVo.getSelectedInstrAssignmentId();
                      accountHolderName =
                              accountVo.getSelectedAccountHolderName();
                      accountNumber = accountVo.getSelectedBankAccountNumber();
                      accountType = accountVo.getSelectedBankAccountType();
                      expirationDate =
                              accountVo.getSelectedBankAccountExpiryDate();

                      bankPartyId = accountVo.getSelectedBankPartyId();
                      branchPartyId = accountVo.getSelectedBranchPartyId();
                      currency = accountVo.getSelectedBankCurrency();
                      objectVersionNo = accountVo.getSelectedObjectVersionNo();

                  } else if (paymentType.equals("DEFAULT")) {

                      DefaultPaymentInstrumentVOImpl accountVo =
                          ((DefaultPaymentInstrumentVOImpl)pageContext.getApplicationModule(webBean).findViewObject("DefaultPaymentInstrumentVO"));
                      sBankAccountId = accountVo.getSelectedPaymentInstrument();
                      String sAccountType = accountVo.paymentInstrumentType();

                      RowSetIterator dpIterator =
                          ((DefaultPaymentInstrumentVOImpl)pageAM.findViewObject("DefaultPaymentInstrumentVO")).createRowSetIterator("iter");
                      dpIterator.reset();
                      DefaultPaymentInstrumentVORowImpl dpRow =
                          (DefaultPaymentInstrumentVORowImpl)dpIterator.next();
                      dpIterator.closeRowSetIterator();

                      instr_assignment_id = dpRow.getInstrAssignmentId();
                      accountHolderName = dpRow.getAccountHolder();
                      accountNumber = dpRow.getAccountNumberMasked();


                      //Bug 4744886 - Validate CVV Code and pass CC Bill Site Id when default
                      //payment instrument is Credit Card
                      if ("CREDIT_CARD".equals(sAccountType)) {
                          sPaymentInstrument = "CREDIT_CARD";
                          if ("NONE".equals(sProfile) ||
                              ("SECURITY_CODE".equals(sProfile)))
                              CCBillSiteId = new Number(0);
                          else
                              CCBillSiteId = accountVo.getSelectedCcBillSiteId();

                          String sCvvCode =
                              pageContext.getParameter("QPCardSecurityCode");
                          cardIssuerCode = accountVo.getSelectedCardBrand();
                          if (sCvvCode != null) {
                              sCvvCode = sCvvCode.trim();
                              boolean validCardSecurityCode = false;
                              if ("".equals(sCvvCode))
                                  validCardSecurityCode = false;
                              else {
                                  if (!checkDigits(sCvvCode)) {
                                      //This check is used to ensure that + or - is not entered.
                                      throw new OAException("AR",
                                                            "ARI_INVALID_CARD_SECURITY_CODE");
                                  }

                                  try {
                                      sCVV2 = sCvvCode;
                                  } catch (NumberFormatException e) {
                                      //Card security code entered is not in proper number format.
                                      throw new OAException("AR",
                                                            "ARI_INVALID_CARD_SECURITY_CODE");
                                  }

                                  PaymentAMImpl payAM =
                                      (PaymentAMImpl)pageContext.getApplicationModule(webBean);
                                  validCardSecurityCode =
                                          payAM.validateCardSecurityCode(sCvvCode,
                                                                         cardIssuerCode);
                              }
                              if (!validCardSecurityCode) {
                                  throw new OAException("AR",
                                                        "ARI_INVALID_CARD_SECURITY_CODE");
                              }
                          }

                          if (dpRow.getExpiryYear() != null &&
                              dpRow.getExpiryYear() != "" &&
                              !"XXXX".equals(dpRow.getExpiryYear()) &&
                              dpRow.getExpiryMonth() != "" &&
                              dpRow.getExpiryMonth() != null &&
                              "XX".equals(dpRow.getExpiryMonth())) {
                              Integer iYear =
                                  Integer.valueOf((String)dpRow.getExpiryYear());
                              Integer iMonth =
                                  Integer.valueOf((String)dpRow.getExpiryMonth());
                              String sNewCCDate =
                                  dpRow.getExpiryYear() + "-" + dpRow.getExpiryMonth() +
                                  "-" +
                                  getLastDayOfMonth(iMonth.intValue(), iYear.intValue());

                              SimpleDateFormat sdf =
                                  new SimpleDateFormat("yyyy-MM-dd");
                              java.util.Date d = null;
                              try {
                                  d = sdf.parse(sNewCCDate);
                              } catch (ParseException pE) {
                              }
                              expirationDate = new java.sql.Date(d.getTime());
                          }
                      } else {
                          //For default bank account, set these values
                          accountType = dpRow.getAccountType();
                          bankPartyId = dpRow.getBankPartyId();
                          branchPartyId = dpRow.getBranchPartyId();
                          currency = dpRow.getCurrencyCode();
                          objectVersionNo = dpRow.getObjectVersionNo();
                      }
                  }
                  bankAccountId = new Number(sBankAccountId);
              }

              /* Retofitted for R12 upgrade */
              /* R11 customised code
        *<<BEGIN>> Modification for E1294 by Madankumar J,Wipro Technologies.
               s12 = "BEGIN xx_ar_irec_payments.pay_multiple_invoices( p_payment_amount      => :1 , p_di" +
       "scount_amount     => :2 , p_customer_id         => :3 , p_site_use_id         =>" +
       " :4 , p_account_number      => :5 , p_expiration_date     => :6 , p_account_hold" +
       "er_name => :7 , p_account_type        => :8 , p_payment_instrument  => :9 , p_ad" +
       "dress_line1       => :10 , p_address_line2       => :11 , p_address_line3       " +
       "=> :12 , p_address_city        => :13 , p_address_county      => :14 , p_address" +
       "_state       => :15 , p_address_country     => :16 , p_address_postalcode  => :1" +
       "7 , p_cvv2                => :18 , p_bank_branch_id      => :19 , p_receipt_date" +
       "        => :20 , p_new_account_flag    => :21 , p_receipt_site_id     => :22 , p" +
       "_save_cc_address_flag => :23 , p_cash_receipt_id     => :24 , p_bank_account_id " +
       "    => :25 , p_status              => :26 , x_msg_count           => :27 , x_msg" +
       "_data            => :28,p_auth_code    => :29,x_bep_code   => :30              " +
   //  " p_address_line4 => :31 , p_address_province    => :32 , p_session_id => :33 , p_cc_auth_code => :34 " + //Added the code as per patch# 10224271
   //  ",p_receipt_number => :35 "+ //Added by Suraj for ACHePAy, Oracle.
     ",p_bank_routing_number => :31"+
   //  ",p_attr1 => :36"+ //Date: 10-Aug-2012 Added by Suraj for lockbox issue.
     ",p_bank_account_name => :32 , p_soa_receipt_number => :33 , p_soa_msg => :34"+
       " ); END;"             //x_bep_code included for the CR2462 by Madankumar J,Wipro Technologies
       ;
       //<<END>> Modification for E1294 by Madankumar J,Wipro Technologies.
                */

              // Create the callable statement
              //Bug 3335944 - One Time Credit Card Verification
              sql = null; //Added for Bug#14797865
              sql =
  "BEGIN xx_ar_irec_payments.pay_multiple_invoices( " + "p_payment_amount      => :1 , " +
    "p_discount_amount     => :2 , " + "p_customer_id         => :3 , " +
    "p_site_use_id         => :4 , " + "p_account_number      => :5 , " +
    "p_expiration_date     => :6 , " + "p_account_holder_name => :7 , " +
    "p_account_type        => :8 , " + "p_payment_instrument  => :9 , " +
    "p_address_line1       => :10 , " + "p_address_line2       => :11 , " +
    "p_address_line3       => :12 , " + "p_address_line4       => :13," +
    "p_address_city        => :14 , " + "p_address_county      => :15 , " +
    "p_address_state       => :16 , " + "p_address_country     => :17 , " +
    "p_address_postalcode  => :18 , " + "p_cvv2                => :19 , " +
    "p_bank_branch_id      => :20 , " + "p_receipt_date        => :21 , " +
    "p_new_account_flag    => :22 , " + "p_receipt_site_id     => :23 ," +
    "p_bank_id             => :24,  " + "p_card_brand          => :25,  " +
    "p_cc_bill_to_site_id  => :26,  " + "p_single_use_flag     => :27,  " +
    "p_iban                => :28,  " + "p_routing_number      => :29,  " +
    "p_instr_assign_id     => :30,  " + "p_bank_account_id     => :31 , " +
    "p_cash_receipt_id     => :32 , " + "p_cc_auth_code        => :33,  " +
    "p_status              => :34 , " + "x_msg_count           => :35 , " +
    "x_msg_data            => :36,  " + "p_auth_code           => :37," +
    "x_bep_code            => :38," + "p_bank_routing_number => :39," +
    "p_bank_account_name   => :40," + "p_soa_receipt_number  => :41," +
    "p_soa_msg             => :42,"+
    "p_payment_audit_id    => :43,  " +
    "p_cc_auth_id          => :44,  " +
    "p_status_reason       => :45,  p_confirmemail       => :46);" + "END;";


              //Bug2823323

          } catch (Exception e) {

              try {
                  if (Logger.isEnabled(Logger.EXCEPTION))
                      Logger.out(e, OAFwkConstants.EXCEPTION,
                                 Class.forName("oracle.apps.ar.irec.accountDetails.pay.utilities.PaymentUtilities"));
              } catch (ClassNotFoundException cnfE) {
              }
              //Bug 4760655 - Payment page shows stale data error when exception is raised in above block
              tx.putValue("PaymentInProcess", "N");
              throw OAException.wrapperException(e);
          }


          OracleCallableStatement callStmt =
              (OracleCallableStatement)tx.createCallableStatement(sql, 1);

          String sAuthCode = null;
          String sCashReceiptId = null;
          String pmtStatus = null;
          String statusReason = null;
          //Bug 3630101 - Payment process setup errors to be displayed to internal user
          String sErrorMessage = null;
          int iErrorCount = 0;
          Number receiptSiteId = null;

          pageContext.writeDiagnostics(pkgName,
                                       "XXOD: Inparameters:" + "p_payment_amount      => " +
                                       totalPaymentAmount +
                                       "p_discount_amount     => " +
                                       discountAmount +
                                       "p_customer_id         => " + customerId +
                                       "p_site_use_id         => " +
                                       customerSiteUseId +
                                       "p_account_number      => " +
                                       accountNumber +
                                       "p_expiration_date     => " +
                                       expirationDate +
                                       "p_account_holder_name => " +
                                       accountHolderName +
                                       "p_account_type        => " +
                                       accountType + ":" +
                                       pageContext.getSessionValue("p_bank_account_type") +
                                       "p_payment_instrument  => " +
                                       sPaymentInstrument +
                                       "p_address_line1       => " +
                                       sAddressLine1 +
                                       "p_address_line2       => " +
                                       sAddressLine2 +
                                       "p_address_line3       => " +
                                       sAddressLine3 +
                                       "p_address_line4       => " +
                                       sAddressLine4 +
                                       "p_address_city        => " + sCity +
                                       "p_address_county      => " + sCounty +
                                       "p_address_state       => " + sState +
                                       "p_address_country     => " + sCountry +
                                       "p_address_postalcode  => " +
                                       sPostalCode +
                                       "p_cvv2                => " + sCVV2 +
                                       "p_bank_branch_id      => " +
                                       bankBranchId +
                                       "p_receipt_date        => " +
                                       receiptDate +
                                       "p_new_account_flag    => " +
                                       sNewAccount +
                                       "p_receipt_site_id     => " +
                                       sCustSiteUseIdForPayment +
                                       "p_bank_id             => " + bankId +
                                       "p_card_brand          => " +
                                       cardIssuerCode +
                                       "p_cc_bill_to_site_id  => " +
                                       CCBillSiteId +
                                       "p_single_use_flag     => " +
                                       singleUseFlag +
                                       "p_iban                => " + sIban +
                                       "p_routing_number      => " +
                                       routingNumber +
                                       "p_instr_assign_id     => " +
                                       instr_assignment_id +
                                       "p_bank_account_id     => " +
                                       bankAccountId +
                                       "p_cc_auth_code        => " +
                                       Gc_Authcode +
                                       "p_bank_routing_number => " +
                                       pageContext.getSessionValue("p_bank_routing_number") +
                                       "p_bank_account_name   => " +
                                       pageContext.getParameter("customAcctName"),
                                       OAFwkConstants.STATEMENT);

          if (sCustSiteUseIdForPayment != null) {
              try {
                  receiptSiteId = new Number(sCustSiteUseIdForPayment);
              } catch (Exception e) {
                  throw OAException.wrapperException(e);
              }
          }

          if (receiptSiteId == null)
              receiptSiteId = customerSiteUseId;

          /*Added for R12 upgrade retrofit */
          //        if(oapagecontext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER")!=null){
          //        if(oapagecontext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER").toString() != null && !"".equals(oapagecontext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER").toString()))
          //        {
          String soaReceiptNumber = null;
          String soaMsg = null;

          /*End-Added for R12 upgrade retrofit */

          try {
              long lDummyLong = -1;
              //Added for Bug 16471455
              String pmtStr =
                  (String)pageContext.getSessionValue("paymentAuditId");
              long paymentAuditId = Long.parseLong(pmtStr);
              // Set the parameters
              // Added for Bug 14055345
              if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT)) {
                  pageContext.writeDiagnostics(pkgName,
                                               "Before Setting the Parameters to call xx_ar_irec_payments.pay_multiple_invoices..totalPaymentAmount -->>" +
                                               totalPaymentAmount +
                                               " discountAmount -->>" +
                                               discountAmount,
                                               OAFwkConstants.STATEMENT);
              }

              //Start for bug 19898917 gnramasa 4th Nov 2014
              /*rvallamshetla - changed from setDouble to SetString for defect 30873 */
              //callStmt.setDouble(1,(totalPaymentAmount == null ? 0 : totalPaymentAmount.doubleValue()));
              //callStmt.setDouble(2,(discountAmount == null ? 0 : discountAmount.doubleValue()));
              callStmt.setString(46, null);
              callStmt.setString(1,
                                 (totalPaymentAmount == null ? "0" : totalPaymentAmount.toString()));
              callStmt.setString(2,
                                 (discountAmount == null ? "0" : discountAmount.toString()));

              //End for bug 19898917 gnramasa 4th Nov 2014
              callStmt.setLong(3, customerId.longValue());
              callStmt.setLong(4,
                               (customerSiteUseId == null ? lDummyLong : customerSiteUseId.longValue()));
              callStmt.setString(5, accountNumber);
              callStmt.setDate(6, expirationDate);
              callStmt.setString(7, accountHolderName);

              /*Start - Modified for R12 upgrade retrofit */
              //callStmt.setString(8, accountType);
              //Re-design code and enable stanard for credit card issue.
              if (pageContext.getSessionValue("p_bank_account_type") != null &&
                  !"".equals(pageContext.getSessionValue("p_bank_account_type"))) {
                  callStmt.setString(8,
                                     pageContext.getSessionValue("p_bank_account_type").toString());
              } else {
                  callStmt.setString(8, accountType); // Addded for CC issue
              }
              /*End - Modified for R12 upgrade retrofit */

              callStmt.setString(9, sPaymentInstrument);
              callStmt.setString(10, sAddressLine1);
              callStmt.setString(11, sAddressLine2);
              callStmt.setString(12, sAddressLine3);
              callStmt.setString(13, sAddressLine4);
              callStmt.setString(14, sCity);
              callStmt.setString(15, sCounty);
              callStmt.setString(16, sState);
              callStmt.setString(17, sCountry);
              callStmt.setString(18, sPostalCode);
              //Bug 4322904 - Null pointer exception when clicking pay button
              callStmt.setString(19, sCVV2 );
              callStmt.setLong(20,
                               (bankBranchId == null ? lDummyLong : bankBranchId.longValue()));
              callStmt.setDate(21, receiptDate);
              callStmt.setString(22, sNewAccount);
              callStmt.setLong(23,
                               (receiptSiteId == null ? lDummyLong : receiptSiteId.longValue()));


              callStmt.setLong(24,
                               bankId == null ? lDummyLong : bankId.longValue());
              callStmt.setString(25, cardIssuerCode);
              callStmt.setLong(26,
                               CCBillSiteId == null ? lDummyLong : CCBillSiteId.longValue());
              callStmt.setString(27, singleUseFlag);
              callStmt.setString(28, sIban);
              callStmt.setString(29, routingNumber);
              callStmt.setLong(30,
                               (instr_assignment_id == null ? 0 : instr_assignment_id.longValue()));
              callStmt.setLong(31,
                               (bankAccountId == null ? lDummyLong : bankAccountId.longValue()));


              callStmt.registerOutParameter(31, java.sql.Types.BIGINT, 38, 38);
              callStmt.registerOutParameter(32, java.sql.Types.BIGINT, 38, 38);
              callStmt.registerOutParameter(33, java.sql.Types.VARCHAR, 0, 20);
              callStmt.registerOutParameter(34, java.sql.Types.VARCHAR, 0, 20);
              callStmt.registerOutParameter(35, Types.INTEGER);
              callStmt.registerOutParameter(36, java.sql.Types.VARCHAR, 0, 6000);

              callStmt.setString(37,
                                 Gc_Authcode); //Included for E1294 by Madankumar J,Wipro Technologies

              callStmt.registerOutParameter(38, java.sql.Types.VARCHAR, 0, 80);


              //Added for Bug#14797865
              //callStmt.setString(36, sAddressLine4);


              /*Start - R12 upgrade retrofit */
              //callStmt.registerOutParameter(38, 12, 0, 2); //Included for E1294 by Madankumar J,Wipro Technologies
              //            oraclecallablestatement.setString(31, sAddressLine4);
              //            oraclecallablestatement.setString(32, sProvince);
              //            oraclecallablestatement.setString(33,sSessionId);
              //            oraclecallablestatement.registerOutParameter(34, java.sql.Types.VARCHAR,0,80);
              /*Commented for Re-desing
               if(oapagecontext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER")!=null && !"".equals(oapagecontext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER")))
               oraclecallablestatement.setString(35,oapagecontext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER").toString());//Added by Suraj for ACHePAy, Oracle.
               else
               oraclecallablestatement.setString(35,null);//Added by Suraj for ACHePAy, Oracle.
                           Commented for Re-desing */
              //Re-design code Strat
              callStmt.setString(39, null);
              callStmt.setString(40, null);

              if (pageContext.getSessionValue("p_bank_routing_number") != null &&
                  !"".equals(pageContext.getSessionValue("p_bank_routing_number")))
                  callStmt.setString(39,
                                     pageContext.getSessionValue("p_bank_routing_number").toString()); //Added by Suraj for ACHePAy, Oracle.
              else
                  callStmt.setString(39, null);
              //Re-design code End.
              /*To overcome lock box standard process /*Date:10-08-2012. By: Suraj*/
              if (!paymentType.equals("NEW_CC") &&
                  !paymentType.equals("EXISTING_CC")) { // Date: 30-Oct-2012 Not for Credit Card Version 1.6
                  pageContext.writeDiagnostics(callingObject,
                                               "##### In PaymentUtilities if Payment method is not CREDIT CARD TYPE",
                                               1);
                  if (pageContext.getParameter("customAcctName") != null) {
                      //Added by Shubhashree to replace & in Customer Name - Begin

                      String custAcctName =
                          pageContext.getParameter("customAcctName");

                      /*
                       * The below code is written to check if the user has entered any special cahracter in Accout Holder's name
                       * If so, an exception is thrown before continuing.
                       * Else, continue processing
                       * Defect 30058 changes Begin
                       */
					  
					  PreparedStatement stmt  = null;
					  ResultSet resultset = null;
					  try {
                      Connection conn = tx.getJdbcConnection();
                      String Query =
                          " select lookup_code " + " from fnd_lookup_values " +
                          " where lookup_type = 'XXOD_ACCT_NAME_SPL_CHARS' " +
                          " and   enabled_flag = 'Y'";
                      stmt = conn.prepareStatement(Query);
                      String spclChar = "";
                      String acctHoldersName =
                          pageContext.getParameter("customAcctName");
                      pageContext.writeDiagnostics("oracle.apps.ar.irec.accountDetails.pay.utilities.PaymentUtilities",
                                                   "Defect 30058| Account Holders Name: " +
                                                   acctHoldersName, 1);
                      for (resultset = stmt.executeQuery();
                           resultset.next(); ) {
                          spclChar = resultset.getString("lookup_code");
                          if (acctHoldersName != null) {
                              acctHoldersName =
                                      acctHoldersName.replace(spclChar, "");
                          }
                          pageContext.writeDiagnostics("oracle.apps.ar.irec.accountDetails.pay.utilities.PaymentUtilities",
                                                       "Defect 30058| After replacing the special character : " +
                                                       spclChar, 1);
                          pageContext.writeDiagnostics("oracle.apps.ar.irec.accountDetails.pay.utilities.PaymentUtilities",
                                                       "Defect 30058| acctHoldersName : " +
                                                       acctHoldersName, 1);
                      }

                      //Defect 30058 changes End
                      pageContext.writeDiagnostics(callingObject,
                                                   "##### In PaymentUtilities After String replace=" +
                                                   acctHoldersName, 1);
                      callStmt.setString(40, acctHoldersName);
                      pageContext.writeDiagnostics(callingObject,
                                                   "##### In PaymentUtilities oapagecontext.getParameter(customAcctName)=" +
                                                   pageContext.getParameter("customAcctName"),
                                                   1);
					}
					catch(Exception exc) {
						throw OAException.wrapperException(exc);
					}
					finally {
						try {
							if (resultset != null)
								resultset.close();							
							if (stmt != null)
								stmt.close();
						}
						catch(Exception exc) { 
							throw OAException.wrapperException(exc);
						}
					}	  

                      //callStmt.setString(40,pageContext.getParameter("customAcctName"));
                      //Added by Shubhashree to replace & in Customer Name - End
                      //pageContext.getParameter("customAcctName")); //Date: 10-Aug-2012 Added by Suraj for lockbox issue.
                  } else if (pageContext.getSessionValue("PREV_SAVED_CUSTOM_ACCT_HOLDER_NAME") !=
                             null) {
                      callStmt.setString(40,
                                         pageContext.getSessionValue("PREV_SAVED_CUSTOM_ACCT_HOLDER_NAME").toString());


                      pageContext.writeDiagnostics(callingObject,
                                                   "##### In PaymentUtilities oapagecontext.getSessionValue(PREV_SAVED_CUSTOM_ACCT_HOLDER_NAME).toString()=" +
                                                   pageContext.getSessionValue("PREV_SAVED_CUSTOM_ACCT_HOLDER_NAME").toString(),
                                                   1);


                      String sEmailAddr = (String)pageContext.getSessionValue("PREV_SAVED_CUSTOM_EMAIL_ADDRESS");
                      pageContext.writeDiagnostics(callingObject,
                                                   "##### In PaymentUtilities getSessionValue PREV_SAVED_CUSTOM_EMAIL_ADDRESS=" +
                                                   sEmailAddr,
                                                   1);                      
                  

				      if ((sEmailAddr == null) || ("".equals(sEmailAddr)))
				      {
                             pageContext.writeDiagnostics(callingObject,
                                                   "##### In PaymentUtilities sEmailAddr is null =" +
                                                   sEmailAddr,
                                                   1); 					  
						  String sEmailFromProfile =   pageContext.getProfile("XX_AR_IREC_EMAIL_FROM");
						  pageContext.writeDiagnostics("##### In PaymentUtilities", 
                                                 "##### sEmailFromProfile: " +sEmailFromProfile, 
                                                 1);
						  sEmailAddr = sEmailFromProfile;
				      }
					  
                      pageContext.writeDiagnostics("##### In PaymentUtilities", 
                                                 "##### sEmailAddr: " + sEmailAddr, 
                                                 1);

					  callStmt.setString(46, sEmailAddr);

                      
                      pageContext.writeDiagnostics(callingObject,
                                                   "##### In PaymentUtilities oapagecontext.getSessionValue(PREV_SAVED_CUSTOM_EMAIL_ADDRESS).toString()=" +
                                                   sEmailAddr,
                                                   1);
                  }
              } else {
                  callStmt.setString(40, null);
             
              }
              //Re-design code Strat
              callStmt.registerOutParameter(41, java.sql.Types.VARCHAR, 0, 300);
              callStmt.registerOutParameter(42, java.sql.Types.VARCHAR, 0, 300);

                          callStmt.setLong(43, paymentAuditId);
              callStmt.registerOutParameter(44, java.sql.Types.BIGINT, 38, 38);
              callStmt.registerOutParameter(45, java.sql.Types.VARCHAR, 0, 2000);

              
             String strEmail = (String)pageContext.getSessionValue("OD_CONFIRMEMAIL");

              pageContext.writeDiagnostics(callingObject,
                                                   "##### In PaymentUtilities strEmail=" +
                                                   strEmail,
                                                   1);

              if(strEmail != null
                 && !"".equals(strEmail)){
                  callStmt.setString(46, strEmail);
                 }
            
              /*
                           if(oapagecontext.getSessionValue("p_bank_account_type")!=null && !"".equals(oapagecontext.getSessionValue("p_bank_account_type")))
               oraclecallablestatement.setString(37,oapagecontext.getSessionValue("p_bank_account_type").toString());//Added by Suraj for ACHePAy, Oracle.
               else
               oraclecallablestatement.setString(37,null);



                           if(oapagecontext.getSessionValue("p_bank_account_number")!=null && !"".equals(oapagecontext.getSessionValue("p_bank_account_number")))
               oraclecallablestatement.setString(39,oapagecontext.getSessionValue("p_bank_account_number").toString());//Added by Suraj for ACHePAy, Oracle.
               else
               oraclecallablestatement.setString(39,null);

                           if(oapagecontext.getSessionValue("p_bank_account_number")!=null && !"".equals(oapagecontext.getSessionValue("p_bank_account_number")))
               oraclecallablestatement.setString(39,oapagecontext.getSessionValue("p_bank_account_number").toString());//Added by Suraj for ACHePAy, Oracle.
               else
               oraclecallablestatement.setString(39,null);
                           */
              //Re-design code End.

              /*End - R12 upgrade retrofit */

              pageContext.writeDiagnostics(callingObject,
                                           "##### In PaymentUtilities before plsql execute statement" +
                                           sql, 1);
              callStmt.execute();
              pageContext.writeDiagnostics(callingObject,
                                           "##### In PaymentUtilities After plsql execute statement",
                                           1);

              sCashReceiptId = null;
              String sBankAccountId = null;

              //Bug 3630101 - Payment process setup errors to be displayed to internal user
              iErrorCount = callStmt.getInt(35);
              sErrorMessage = callStmt.getString(36);

              pageContext.writeDiagnostics(callingObject,
                                           "##### iErrorCount " + iErrorCount,
                                           1);

              pageContext.writeDiagnostics(callingObject,
                                           "##### sErrorMessage " +
                                           sErrorMessage, 1);


              /*Start - R12 upgrade retrofit */
              //<<BEGIN>>Modification for the CR2462 by Madankumar J,Wipro Technologies.
              pageContext.writeDiagnostics(callingObject,
                                           "##### before Gc_bep_code" +
                                           Gc_bep_code, 1);
              Gc_bep_code = callStmt.getString(38);
              pageContext.writeDiagnostics(callingObject,
                                           "##### after Gc_bep_code" +
                                           Gc_bep_code, 1);
              try {
                  //if (Gc_bep_code != null && Gc_bep_code.equals("2")) {
                  if (Gc_bep_code != null && "2".equals(Gc_bep_code)) {
                      pageContext.writeDiagnostics(callingObject,
                                                   "##### inside if Gc_bep_code",
                                                   1);
                      HashMap params = new HashMap();
                      pageContext.putSessionValue("x_bep_value", Gc_bep_code);

                      pageContext.writeDiagnostics(callingObject,
                                                   "##### after putting in session " +
                                                   Gc_bep_code, 1);

                      pageContext.forwardImmediatelyToCurrentPage(params, true,
                                                                  null);

                  }
              } catch (Exception ex_ver_auth) {
                  pageContext.writeDiagnostics(callingObject,
                                               "##### gone inside exception" +
                                               ex_ver_auth.getMessage(), 1);
                  rollbackAndDisplayErrorMessage(callingObject, pageContext, tx,
                                                 sPaymentScheduleId, customerId,
                                                 paymentType, bankAccountId,
                                                 customerSiteUseId, webBean);
              }
              //<<END>>Modification for the CR2462 by Madankumar J,Wipro Technologies.
              /*End - R12 upgrade retrofit */

              pageContext.writeDiagnostics(callingObject,
                                           "##### paymentType " + paymentType,
                                           1);

              if (paymentType.equals("NEW_CC") || paymentType.equals("NEW_BA")) {

                  sCashReceiptId = String.valueOf(callStmt.getLong(32));
                  sBankAccountId = String.valueOf(callStmt.getLong(31));
                  cashReceiptId =
                          new oracle.jbo.domain.Number(callStmt.getLong(32));
                  bankAccountId =
                          new oracle.jbo.domain.Number(callStmt.getLong(31));

                  status = callStmt.getString(34);
                  pageContext.writeDiagnostics(callingObject,
                                               "##### status " + status, 1);

                  pageContext.putSessionValue("XX_AR_IREC_PAY_STATUS",
                                              status); //Added for R12 upgrade retrofit


                  sAuthCode = callStmt.getString(33);
                                  //Added for Bug 16471455 : Start
                  long sAuthId = callStmt.getLong(44);
                  statusReason = callStmt.getString(45);

                  if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT)) {
                      pageContext.writeDiagnostics(pkgName,
                                                   "sCashReceiptId = " + sCashReceiptId,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "sBankAccountId = " + sBankAccountId,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName, "status = " + status,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "sAuthCode = " + sAuthCode,
                                                   OAFwkConstants.STATEMENT);

                                          pageContext.writeDiagnostics(pkgName,
                                                   "sAuthId = " + sAuthId,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "statusReason = " + statusReason,
                                                   OAFwkConstants.STATEMENT);
                  }


                  /*
                            //Added for Bug 16471455 : Start
                  long sAuthId = callStmt.getLong(38);
                  statusReason = callStmt.getString(39);

                  if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT)) {
                      pageContext.writeDiagnostics(pkgName,
                                                   "sCashReceiptId = " + sCashReceiptId,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "sBankAccountId = " + sBankAccountId,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName, "status = " + status,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "sAuthCode = " + sAuthCode,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "sAuthId = " + sAuthId,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "statusReason = " + statusReason,
                                                   OAFwkConstants.STATEMENT);
                  }
                  if ("E".equals(status)) {
                      pmtStatus = G_FAILED;
                      cashReceiptId = null;
                  } else
                      pmtStatus = G_SUCCESSFUL;
                  if (statusReason == null || "".equals(statusReason))
                      statusReason = G_SUCCESSFUL;

                  String updatesql =
                      " BEGIN ARI_AUDIT_PKG.Update_Payment_Audit(" +
                      "p_payment_audit_id   => :1," +
                      "p_oir_payment_status => :2," +
                      "p_cash_receipt_id    => :3," +
                      "p_receipt_date       => :4," +
                      "p_receipt_status     => :5";
                  if (sAuthId == 0)
                      updatesql = updatesql + ");END;";
                  else
                      updatesql =
                              updatesql + "," + "p_transaction_id     => :6);END;";
                  pageContext.writeDiagnostics(pkgName,
                                               "Before Calling Payment Audit" +
                                               updatesql,
                                               OAFwkConstants.STATEMENT);
                  if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT)) {
                      pageContext.writeDiagnostics(pkgName,
                                                   "Before Executing ARI_AUDIT_PKG.Update_Payment_Audit to update payment audit",
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "paymentAuditId -->>" +
                                                   paymentAuditId,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "pmtStatus -->>" + pmtStatus,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "statusReason -->>" + statusReason,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "sCashReceiptId -->>" +
                                                   cashReceiptId.longValue(),
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "receiptDate -->>" + receiptDate,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "sAuthId -->>" + sAuthId,
                                                   OAFwkConstants.STATEMENT);
                  }
                  OracleCallableStatement updateCallStmt =
                      (OracleCallableStatement)tx.createCallableStatement(updatesql,
                                                                          1);

                  try {
                      updateCallStmt.setLong(1, paymentAuditId);
                      updateCallStmt.setString(2, pmtStatus);
                      updateCallStmt.setLong(3, cashReceiptId.longValue());
                      updateCallStmt.setDate(4, receiptDate);
                      updateCallStmt.setString(5, statusReason);
                      if (sAuthId > 0)
                          updateCallStmt.setLong(6, sAuthId);

                      updateCallStmt.execute();
                  } //Added for Bug 16471455 : End
                  catch (Exception e) {
                      throw OAException.wrapperException(e);
                  } finally {
                      try {
                          updateCallStmt.close();
                      } catch (Exception e) {
                          throw OAException.wrapperException(e);
                      }
                  }
                                  */
              } else if (paymentType.equals("EXISTING_CC") ||
                         paymentType.equals("EXISTING_BA") ||
                         paymentType.equals("DEFAULT")) {

                  sCashReceiptId = String.valueOf(callStmt.getLong(32));
                  cashReceiptId =
                          new oracle.jbo.domain.Number(callStmt.getLong(32));
                  sBankAccountId = String.valueOf(callStmt.getLong(31));
                  status = String.valueOf(callStmt.getString(34));

                  sAuthCode = callStmt.getString(33);
                                  //Added for Bug 16471455 : Start
                  long sAuthId = callStmt.getLong(44);
                  statusReason = callStmt.getString(45);

                  if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT)) {
                      pageContext.writeDiagnostics(pkgName,
                                                   "sCashReceiptId = " + sCashReceiptId,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName, "status = " + status,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "sAuthCode = " + sAuthCode,
                                                   OAFwkConstants.STATEMENT);

                                            pageContext.writeDiagnostics(pkgName,
                                                   "sAuthId = " + sAuthId,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "statusReason = " + statusReason,
                                                   OAFwkConstants.STATEMENT);
                  }

                  /*
                                  //Added for Bug 16471455 : Start
                  long sAuthId = callStmt.getLong(38);
                  statusReason = callStmt.getString(39);

                  if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT)) {
                      pageContext.writeDiagnostics(pkgName,
                                                   "Inside Existing Bank",
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "sCashReceiptId = " + sCashReceiptId,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName, "status = " + status,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "sAuthCode = " + sAuthCode,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "sAuthId = " + sAuthId,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "statusReason = " + statusReason,
                                                   OAFwkConstants.STATEMENT);
                  }
                  if ("E".equals(status)) {
                      pmtStatus = G_FAILED;
                      sCashReceiptId = null;
                  } else
                      pmtStatus = G_SUCCESSFUL;
                  if (statusReason == null || "".equals(statusReason))
                      statusReason = G_SUCCESSFUL;

                  String updatesql =
                      " BEGIN ARI_AUDIT_PKG.Update_Payment_Audit(" +
                      "p_payment_audit_id   => :1," +
                      "p_oir_payment_status => :2," +
                      "p_cash_receipt_id    => :3," +
                      "p_receipt_date       => :4," +
                      "p_receipt_status     => :5";
                  if (sAuthId == 0)
                      updatesql = updatesql + ");END;";
                  else
                      updatesql =
                              updatesql + "," + "p_transaction_id     => :6);END;";

                  pageContext.writeDiagnostics(pkgName,
                                               "Before Calling Payment Audit" +
                                               updatesql,
                                               OAFwkConstants.STATEMENT);
                  if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT)) {
                      pageContext.writeDiagnostics(pkgName,
                                                   "Before Executing ARI_AUDIT_PKG.Update_Payment_Audit to update payment audit",
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "paymentAuditId -->>" +
                                                   paymentAuditId,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "pmtStatus -->>" + pmtStatus,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "statusReason -->>" + statusReason,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "sCashReceiptId -->>" +
                                                   cashReceiptId.longValue(),
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "receiptDate -->>" + receiptDate,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "sAuthId -->>" + sAuthId,
                                                   OAFwkConstants.STATEMENT);
                  }
                  OracleCallableStatement updateCallStmt =
                      (OracleCallableStatement)tx.createCallableStatement(updatesql,
                                                                          1);

                  try {
                      updateCallStmt.setLong(1, paymentAuditId);
                      updateCallStmt.setString(2, pmtStatus);
                      updateCallStmt.setLong(3, cashReceiptId.longValue());
                      updateCallStmt.setDate(4, receiptDate);
                      updateCallStmt.setString(5, statusReason);
                      if (sAuthId > 0)
                          updateCallStmt.setLong(6, sAuthId);

                      updateCallStmt.execute();
                  } catch (Exception e) {
                      throw OAException.wrapperException(e);
                  } finally {
                      try {
                          updateCallStmt.close();
                      } catch (Exception e) {
                          throw OAException.wrapperException(e);
                      }
                  } //finally
                  //Added for Bug 16471455 : End
                                  */
                  try {
                      if ("EXISTING_BA".equals(paymentType) &&
                          (null != cashReceiptId) &&
                          (cashReceiptId.compareTo(0) > 0)) {
                          //Modified for Bug 17475275 by adding a new parameter instr_assignment_id
                          updateAccountExpiryDate(callingObject, rootAM, tx,
                                                  sBankAccountId, expirationDate,
                                                  sPaymentInstrument,
                                                  branchPartyId, bankPartyId,
                                                  accountNumber, currency,
                                                  objectVersionNo, customerId,
                                                  customerSiteUseId,
                                                  instr_assignment_id);
                      }
                  } catch (Exception ex) { //Ignoring the exception when Expiry date is not updated.
                      //A bug has to be raised to handle when expiration date is not updated and provide an appropriate message.
                      pageContext.writeDiagnostics(pkgName,
                                                   "exception caught = " +
                                                   ex.getMessage(),
                                                   OAFwkConstants.STATEMENT);
                  }
              }
              //Bug2823323
              /*Added for R12 upgrade retrofit*/
              pageContext.writeDiagnostics(callingObject,
                                           "##### In PaymentUtilities Status=" +
                                           status, 1);
              pageContext.putSessionValue("XX_AR_IREC_PAY_STATUS", status);
              pageContext.putSessionValue("XX_AR_IREC_PAY_CASH_RECEIPT_ID",
                                          sCashReceiptId);
              //Re-desing code Start
              soaReceiptNumber = callStmt.getString(41);
              soaMsg = callStmt.getString(42);
              pageContext.writeDiagnostics(callingObject,
                                           "##### In PaymentUtilities soaReceiptNumber=" +
                                           soaReceiptNumber, 1);
              pageContext.writeDiagnostics(callingObject,
                                           "##### In PaymentUtilities soaMsg=" +
                                           soaMsg, 1);
              if (soaReceiptNumber != null && !"".equals(soaReceiptNumber))
                  pageContext.putSessionValue("WEBSERVICE_RECEIPT_NUMBER",
                                              soaReceiptNumber); //sequenceValue);
              //Re-desing code End.
              /*End - Added for R12 upgrade retrofit*/

          } catch (Exception e) { //Modified for Bug 14797901

              pageContext.writeDiagnostics(callingObject,
                                           "exception caught = " + e.getMessage(),
                                           1); //Added for R12 upgrade
              rollbackAndDisplayErrorMessage(callingObject, pageContext, tx,
                                             sPaymentScheduleId, customerId,
                                             paymentType, bankAccountId,
                                             customerSiteUseId, webBean);

              /*
                          rollbackAndDisplayErrorMessage(callingObject, pageContext, tx,
                                             sPaymentScheduleId, customerId,
                                             paymentType, bankAccountId,
                                             customerSiteUseId, webBean,
                                             singleUseFlag);
                                                                                     */
              //throw OAException.wrapperException(e);
          } finally {
              try {
                  callStmt.close();
              } catch (Exception e) {
                  pageContext.writeDiagnostics(callingObject,
                                               "finally exception caught = " +
                                               e.getMessage(),
                                               1); //Added for R12 upgrade

                  throw OAException.wrapperException(e);
              }
          }


          //Bug 3630101 - Payment process setup errors to be displayed to internal user
          //Check if the user logged in is an internal user, and if the profile option:
          //"FND: Diagnostics" is set to Yes.
          //If so, display the payment process setup errors to the current user.

          //Modified for Defect#27242
          //if (cashReceiptId.compareTo(0) <= 0 || "E".equals(status)) {
          pageContext.writeDiagnostics(callingObject,
                                       "XXOD:Reached here status" + status, 1);
          if (status == null || status.equals("E")) {

              /*Start - R12 upgrade retrofit*/
              //Re-design code Start
              pageContext.writeDiagnostics(callingObject,
                                           "XXOD:##### SOA values status=" +
                                           status + " soaReceiptNumber=" +
                                           soaReceiptNumber + " soaMsg=" +
                                           soaMsg + "::sErrorMessage::" +
                                           sErrorMessage,
                                           1); //Added the code as per patch# 10224271


              if (status.equals("E") && soaReceiptNumber == null &&
                  soaMsg != null) {

                  pageContext.writeDiagnostics(callingObject,
                                               "XXOD:##### soa error", 1);

                  ((PaymentFormCO)callingObject).isInternalCustomer(pageContext,
                                                                    webBean);

                  pageContext.writeDiagnostics(callingObject,
                                               "XXOD:##### soa error after checking internal customer",
                                               1);

                  /*
                                  rollbackAndDisplayErrorMessage(callingObject, pageContext, tx,
                                                 sPaymentScheduleId, customerId,
                                                 soaMsg, bankAccountId,
                                                 customerSiteUseId, webBean);

                   */

                  pageContext.writeDiagnostics(callingObject,
                                               "XXOD:##### soaMsg"+soaMsg,
                                               1);

                  rollbackAndDisplayErrorMessage(callingObject, pageContext, tx,
                                                 sPaymentScheduleId, customerId,
                                                 null, soaMsg, bankAccountId,
                                                 customerSiteUseId, webBean);
              }

              if (status.equals("E") && soaReceiptNumber == null &&
                  soaMsg == null) {

                  pageContext.writeDiagnostics(callingObject,
                                               "XXOD:##### else of soa error",
                                               1);

                  ((PaymentFormCO)callingObject).isInternalCustomer(pageContext,
                                                                    webBean);


                  /*
                                  commented for defect 27242
                                  rollbackAndDisplayErrorMessage(callingObject, pageContext, tx,
                                                 sPaymentScheduleId, customerId,
                                                 new String("" + bankId),
                                                 bankAccountId,
                                                 customerSiteUseId, webBean);
                                                                                             */

                  pageContext.writeDiagnostics(callingObject,
                                               "XXOD:#####sErrorMessage", 1);
                  rollbackAndDisplayErrorMessage(callingObject, pageContext, tx,
                                                 sPaymentScheduleId, customerId,
                                                 paymentType, sErrorMessage,
                                                 bankAccountId,
                                                 customerSiteUseId, webBean);
              }
              //                      throw new OAException(soaMsg.toString(),OAException.ERROR);
              //Re-design code End.

              /*End - R12 upgrade retrofit*/
              //Bug 4673563 - Error making credit card payment
              boolean bInternalUser =
                  ((oracle.apps.ar.irec.accountDetails.pay.webui.PaymentFormCO)callingObject).isInternalCustomer(pageContext,
                                                                                                                 webBean);
              String sDiagnostics = pageContext.getProfile("FND_DIAGNOSTICS");

              /*          if ((bInternalUser) && (sDiagnostics.equalsIgnoreCase("Y")))
              rollbackAndDisplayErrorMessage(callingObject, pageContext, tx, sPaymentScheduleId, customerId, paymentType, sErrorMessage, bankAccountId, customerSiteUseId, webBean);
            else
              rollbackAndDisplayErrorMessage(callingObject, pageContext, tx, sPaymentScheduleId, customerId, paymentType, bankAccountId, customerSiteUseId, webBean);
  */

              //Bug 7673372:  WHEN CREDIT CARD LIMIT IS EXCEEDED AND PAYMENT FAILS, NEED BETTER ERROR MESSAGE.
              //We want to display the error message for external user also.
              //The error messages should be displayed irrespective of the value set in the profile FND_DIAGNOSTICS
              //Modified for Bug 14797901
              /*
                          rollbackAndDisplayErrorMessage(callingObject, pageContext, tx,
                                             sPaymentScheduleId, customerId,
                                             paymentType, sErrorMessage,
                                             bankAccountId, customerSiteUseId,
                                             webBean, singleUseFlag);
                                                                                     */
              rollbackAndDisplayErrorMessage(callingObject, pageContext, tx,
                                             sPaymentScheduleId, customerId,
                                             paymentType, sErrorMessage,
                                             bankAccountId, customerSiteUseId,
                                             webBean);


          } else {
              tx.commit();

              PaymentAMImpl payAMImpl =
                  (PaymentAMImpl)pageContext.getApplicationModule(webBean);
              String sCustomerId = customerId.toString();
              String sCustomerSiteUseId =
                  customerSiteUseId == null ? null : customerSiteUseId.toString();
              Serializable[] params = { sCustomerId, sCustomerSiteUseId };
              Boolean bOneTimePayment =
                  (Boolean)payAMImpl.invokeMethod("getOneTimePaymentCustomization",
                                                  params);
              //Bug 4661432 - Updated last used payment instrument, only when Saved Payment Instrument is Yes
              if (!bOneTimePayment.booleanValue())
                  storeLastUsedBA(callingObject, customerId, bankAccountId, tx,
                                  paymentType);

              // Bug 11871875 - When Payment is sucessfull, the account details am has to be released
              pageContext.putSessionValue("RELEASE_ACCT_DTL_AM", "Y");

              /*start - Commented for R12 upgrade*/
              //pageContext.removeSessionValue("paymentAuditId");
              /*End - Commented for R12 upgrade*/

              // Bug#14672025 - When trying to click on Trx Number hyperlink and trying to make payment,
              // it throws stale data error on clicking apply button
              // CVV code doesn't get cleared when coming from payment details page to advanced payment page.
              pageContext.releaseRootApplicationModule();

              StringBuffer url = new StringBuffer("OA.jsp?");
              url.append("akRegionCode=").append("ARI_PAYMENT_DETAILS_PAGE");
              url.append("&akRegionApplicationId=222");
              url.append("&Ircashreceiptid=" + sCashReceiptId);
              url.append("&IrccAuthCode=" + sAuthCode);

              if (bSingleInstallment == Boolean.TRUE)
                  url.append("&Irinstallment=Y");
              else
                  url.append("&Irinstallment=N");


              /*
                     if (paymentType.equals("NEW_CC")) {
                  //Modified for Bug 14797901
                  if (!bOneTimePayment.booleanValue() &&
                      (singleUseFlag != null && !"".equals(singleUseFlag) &&
                       !"Y".equalsIgnoreCase(singleUseFlag)))
                      url.append("&Irccupdated=EXISTING_CC");
              } else if (paymentType.equals("NEW_BA")) {
                  url.append("&Irccupdated=EXISTING_BA");
              } else if (bCreditCardUpdated == Boolean.TRUE) {
                  url.append("&Irccupdated=UPDATED");
              }
                          */

              if (paymentType.equals("NEW_CC")) {
                  if (!bOneTimePayment.booleanValue())
                      url.append("&Irccupdated=EXISTING_CC");
              } else if (paymentType.equals("NEW_BA")) {
                  url.append("&Irccupdated=EXISTING_BA");
              } else if (bCreditCardUpdated == Boolean.TRUE) {
                  url.append("&Irccupdated=UPDATED");
              }

              //pageContext.setRedirectURL(url.toString(), true, OAWebBeanConstants.ADD_BREAD_CRUMB_YES);
              pageContext.setForwardURL(url.toString(), null,
                                        OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                        null, null, true,
                                        OAWebBeanConstants.ADD_BREAD_CRUMB_YES,
                                        OAWebBeanConstants.IGNORE_MESSAGES);
          }


          if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
              pageContext.writeDiagnostics(pkgName, "end payInvoiceInstallment",
                                           OAFwkConstants.PROCEDURE);

      }

      /**
       * Validates the payment page to ensure that all the values are entered correctly
       *
       * Written By: jrautiai
       *
       * @params  Object          Calling object
       * @params  OAPageContext   Page Context
       * @params  OAWebBean       Web Bean
       *
       */
      public static
      //Bug # 3467287 - Added Customer and Customer Site as parameters
      void validatePage(Object callingObject, OAPageContext pageContext,
                        OAWebBean webBean, String sCustomerId,
                        String sCustomerSiteUseId) {

          if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
              pageContext.writeDiagnostics(pkgName, "==============start validatePage***",
                                           OAFwkConstants.PROCEDURE);


          /*Start - R12 upgrade retrofit */
          //<<BEGIN>> Modification for E1294 by Madankumar J,Wipro Technologies.
 pageContext.writeDiagnostics(pkgName, "step 10",1);

                    
		  
          //OAApplicationModule oaapplicationmodule1 =
            //  pageContext.getApplicationModule((OAMessageTextInputBean)webBean.findChildRecursive("AuthCode_Item"));

 pageContext.writeDiagnostics(pkgName, "step 20************",1);
          MultipleInvoicesPayListVOImpl multipleinvoicespaylistvoimpl1 = null;
		  
		 pageContext.writeDiagnostics(pkgName, "step 20.10 ************",1);
		  multipleinvoicespaylistvoimpl1 = (MultipleInvoicesPayListVOImpl) (pageContext.getApplicationModule(webBean)).findViewObject("MultipleInvoicesPayListVO");
		//multipleinvoicespaylistvoimpl1=(MultipleInvoicesPayListVOImpl)oaapplicationmodule1.findViewObject("MultipleInvoicesPayListVO");                                                                                                                                             

																																				
 pageContext.writeDiagnostics(pkgName, "step 30",1);
          MultipleInvoicesPayListVORowImpl multipleinvoicespaylistvorowimpl1 =
              (MultipleInvoicesPayListVORowImpl)multipleinvoicespaylistvoimpl1.first();



 pageContext.writeDiagnostics(pkgName, "step 40",1);

          /*Start - R12 upgrade retrofit */
          /*
          --Changes done for Defect#27766
          --Resetting Gc_Authcode
          */
          if (multipleinvoicespaylistvorowimpl1.getAttribute("XXODAuthCode") !=
              null) {
              Gc_Authcode =
                      (String)multipleinvoicespaylistvorowimpl1.getAttribute("XXODAuthCode");

              pageContext.writeDiagnostics(pkgName,
                                           "in payment utilities gc_authcode set" +
                                           Gc_Authcode, 1);

          } else {
              Gc_Authcode = null;
              pageContext.writeDiagnostics(pkgName,
                                           "in payment utilities else gc_authcode set" +
                                           Gc_Authcode, 1);
          }


          pageContext.writeDiagnostics(pkgName,
                                       "in payment utilities*****************************" +
                                       Gc_Authcode, 1);

          //<<END>> Modification for E1294 by Madankumar J,Wipro Technologies.
          /*End - R12 upgrade retrofit */

          Serializable[] emptyParam = { };

          OAApplicationModuleImpl rootAM =
              (OAApplicationModuleImpl)pageContext.getRootApplicationModule();
          OADBTransaction tx = (OADBTransaction)rootAM.getDBTransaction();
          ArrayList expList = new ArrayList();

          {
              String sAllowZeroPaymentAmt =
                  pageContext.getProfile("OIR_ZERO_AMOUNT_PAYMENT");

              if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT)) {
                  pageContext.writeDiagnostics(pkgName,
                                               "profile OIR_ZERO_AMOUNT_PAYMENT = " +
                                               sAllowZeroPaymentAmt,
                                               OAFwkConstants.STATEMENT);
              }

              if ("N".equals(sAllowZeroPaymentAmt)) {
                  ArrayList invList =
                      (ArrayList)((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("MultipleInvoicesPayListVO")).invokeMethod("validateZeroPaymentAmount",
                                                                                                                                                    emptyParam);
                  if (!invList.isEmpty()) {

                      Iterator itr = invList.iterator();

                      while (itr.hasNext()) {

                          String sTrxNumber = (String)itr.next();
                          MessageToken[] msgToken =
                              new MessageToken[] { new MessageToken("TRX_NUMBER",
                                                                    sTrxNumber) };
                          expList.add(new OAException("AR",
                                                      "ARI_NO_ZERO_AMT_PAYMENT",
                                                      msgToken));
                      }
                      itr.remove();
                  }
              }
          }

          OAWebBean quickPayment =
              (OAWebBean)webBean.findIndexedChildRecursive("QuickPaymentRegion");

          String sPaymentScheduleId = null;
          sPaymentScheduleId =
                  (String)pageContext.getParameter("Irpaymentscheduleid");

          boolean bQuickPage =
              (quickPayment == null ? false : quickPayment.isRendered());

          //Bug 3886652 - Customer Id and Customer Site Use Id added to getOneTimePaymentCustomization API
          String sPaymentType = pageContext.getParameter("PaymentType");
          Boolean bOneTimePayment =
              ((PaymentAMImpl)pageContext.getApplicationModule(webBean)).getOneTimePaymentCustomization(sCustomerId,
                                                                                                        sCustomerSiteUseId);
          if (bOneTimePayment.booleanValue())
              sPaymentType = "NEW_CC";

          if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT)) {
              pageContext.writeDiagnostics(pkgName, "bQuickPage = " + bQuickPage,
                                           OAFwkConstants.STATEMENT);
              pageContext.writeDiagnostics(pkgName,
                                           "sPaymentType = " + sPaymentType,
                                           OAFwkConstants.STATEMENT);
          }

          if (!bQuickPage && (sPaymentType == null)) {
              bQuickPage = true;
              pageContext.putParameter("AdvPaymentButton", "QUICK");
          }

          if (bQuickPage == true) {

              try {

                  ((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("DefaultPaymentInstrumentVO")).invokeMethod("validateDefaultPaymentInstrument",
                                                                                                                                      emptyParam);

              } catch (OAException e) {
                  OAWebBean quickPaymentRegion =
                      (OAWebBean)webBean.findIndexedChildRecursive("QuickPaymentRegion");
                  OAWebBean advancedPaymentRegion =
                      (OAWebBean)webBean.findIndexedChildRecursive("AdvancedPaymentRegion");
                  quickPaymentRegion.setRendered(true);
                  advancedPaymentRegion.setRendered(false);
                  throw e;
              }
          } else {

              try {
                  validatePaymentMethod(callingObject, pageContext, webBean,
                                        sCustomerId, sCustomerSiteUseId);
              } catch (OAException e) {
                  throw e;
              }

              //The following condition statements have been modified to ensure the working of PPR.
              //The Boolean values have been replaced by directly using the PaymentMethod value
              //selected by the user from the pageContext
              //Bug 3844159 - Modified the conditions to ensure the payment methods are validated.
              if ("NEW_CC".equals(sPaymentType)) {
				  OracleCallableStatement callStmt = null;
                  try {
                                       
                     /* New Credit Card - HVT from LVT */
                      Date expirationDate = null;
                      RowSetIterator iter2 =
                                ((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("NewCreditCardVO")).createRowSetIterator("iter");
                      iter2.reset();
                      NewCreditCardVORowImpl newCCrow = (NewCreditCardVORowImpl)iter2.next();
                      iter2.closeRowSetIterator();
                               
                               
                      Integer iYear = Integer.valueOf((String)newCCrow.getExpiryYear());
                      Integer iMonth = Integer.valueOf((String)newCCrow.getExpiryMonth());
                                       
                      if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
                        pageContext.writeDiagnostics(pkgName,
                            "Expiration year -->>" +  newCCrow.getExpiryYear(),  OAFwkConstants.STATEMENT);
                            
                      //newCCrow.setExpiryYear("20"+newCCrow.getExpiryYear());

                             newCCrow.setExpiryYear(newCCrow.getExpiryYear());



                      if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
                        pageContext.writeDiagnostics(pkgName,
                            "After concatenation Expiration year -->>" +  newCCrow.getExpiryYear(),  OAFwkConstants.STATEMENT);

                      String sNewCCDate =
                          newCCrow.getExpiryYear() + "-" + newCCrow.getExpiryMonth() +
                          "-" +
                          getLastDayOfMonth(iMonth.intValue(), iYear.intValue());

                      SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
                      java.util.Date d = sdf.parse(sNewCCDate);
                       expirationDate = new java.sql.Date(d.getTime());
                       
                      if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
                        pageContext.writeDiagnostics(pkgName,
                            "Before getting HVT from LVT",  OAFwkConstants.STATEMENT);
                       
                      if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
                        pageContext.writeDiagnostics(pkgName,
                            "Expiration Date -->>" +  sNewCCDate,  OAFwkConstants.STATEMENT);
                            
                      if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
                        pageContext.writeDiagnostics(pkgName,
                            "getCreditCardNumber() -->>" +  newCCrow.getCreditCardNumber(),  OAFwkConstants.STATEMENT);
                       
                       
                       
                     String hvtsql = " BEGIN XX_AR_IREC_PAYMENTS.get_token_wrapper(:1,:2,:3,:4,:5,:6); END;";
                     callStmt =
                                  (OracleCallableStatement)tx.createCallableStatement(hvtsql, 1);

                     callStmt.setString(1, newCCrow.getCreditCardNumber());
                     callStmt.setDate(2, expirationDate);
                     callStmt.registerOutParameter(3, java.sql.Types.VARCHAR, 0, 250);
                     callStmt.registerOutParameter(4, java.sql.Types.VARCHAR, 0, 250);
                     callStmt.registerOutParameter(5, java.sql.Types.VARCHAR, 0, 2000);
                     callStmt.registerOutParameter(6, java.sql.Types.VARCHAR, 0, 20);
                     
                     
                      callStmt.execute();
                      pageContext.writeDiagnostics(callingObject,
                                          "##### In PaymentUtilities After get_token_wrapper",
                                                                1);

                      String sToken = null;
                      String sStatus = null;
                      String sErrorCode = null;
                      String sErrorMsg = null;
            
                      sToken = callStmt.getString(3);
                      sStatus = callStmt.getString(4);
                      sErrorMsg = callStmt.getString(5);
                      sErrorCode = callStmt.getString(6);
                      
                       pageContext.writeDiagnostics(callingObject,
                                                    "##### sToken " + sToken,
                                                   1);
                                                   
                       pageContext.writeDiagnostics(callingObject,
                                                   "##### sStatus " + sStatus,
                                                  1);

                       pageContext.writeDiagnostics(callingObject,
                                                    "##### sErrorCode " +  sErrorCode, 1);
                                                    
                                                    
                      pageContext.writeDiagnostics(callingObject,
                                                   "##### sErrorMsg " +  sErrorMsg, 1);
                                                   
                      if ("E".equals(sStatus)) {
                          expList.add(new OAException("Error getting HVT "+sErrorMsg,OAException.ERROR));
                          
                      }
                      else {
                          newCCrow.setCreditCardNumber(sToken); 
                          
                          pageContext.writeDiagnostics(pkgName,
                                "After getting HVT -->>" +  newCCrow.getCreditCardNumber(),  OAFwkConstants.STATEMENT);
                           
                      }
                                       
                      /* New Credit Card - HVT from LVT */
                  
                    //  ((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("NewCreditCardVO")).invokeMethod("validateNewCreditCard",
                      //                                                                                                         emptyParam);
                  } catch (Exception e) {
                      pageContext.writeDiagnostics(pkgName,
                            "Error - Step HVT and CC validation ",  OAFwkConstants.STATEMENT);
                       
                      
                     
                  }
					finally {
						try {
							callStmt.close();
						} catch (Exception e) {
								throw OAException.wrapperException(e);
						}
					}				  
              } else if ("EXISTING_CC".equals(sPaymentType)) {
                  try {

                      ((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("CreditCardsVO")).invokeMethod("validateCreditCard",
                                                                                                                             emptyParam);

                  } catch (OAException e) {
                      expList.add(e);
                  }
              } else if ("NEW_BA".equals(sPaymentType)) {
                  try {

                      ((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("NewBankAccountVO")).invokeMethod("validateNewBankAccount",
                                                                                                                                emptyParam);

                  } catch (OAException e) {
                      expList.add(e);
                  }
              } else if ("EXISTING_BA".equals(sPaymentType)) {
                  try {

                      ((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("BankAccountsVO")).invokeMethod("validateBankAccount",
                                                                                                                              emptyParam);

                  } catch (OAException e) {
                      expList.add(e);
                  }

              }

              // Recalculate the amounts to make sure that any changes that were
              // made are incorporated (user may not have hit the recalculate button)
              try {
                  //Bug 3810143 - When the value in the transaction is null,
                  //set it to the current date.
                  String sTrxReceiptDate = (String)tx.getValue("ReceiptDate");
                  // Modified for Bug#14672025
                  if ((sTrxReceiptDate == null) ||
                      (sPaymentType.equals("NEW_CC") ||
                       sPaymentType.equals("EXISTING_CC"))) {
                      String sCurrentDate =
                          pageContext.getOANLSServices().dateToString(pageContext.getCurrentDBDate());
                      tx.putValue("ReceiptDate", sCurrentDate);
                      sTrxReceiptDate = sCurrentDate;
                  }

                  //Bug 3961398 - oracle.jbo.domain.Date.getData API not to be used by development teams
                  //getData replaced by dateValue API
                  java.sql.Date receiptDate =
                      ((MultipleInvoicesPayListSummaryVORowImpl)((PaymentAMImpl)pageContext.getApplicationModule(webBean)).getMultipleInvoicesPayListSummaryVO().first()).getReceiptDate().dateValue();
                  String sReceiptDate = null;
                  if (receiptDate != null)
                      sReceiptDate =
                              pageContext.getOANLSServices().dateToString(receiptDate);
                  if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT)) {
                      pageContext.writeDiagnostics(pkgName,
                                                   "sReceiptDate = " + sReceiptDate,
                                                   OAFwkConstants.STATEMENT);
                      pageContext.writeDiagnostics(pkgName,
                                                   "sTrxReceiptDate = " +
                                                   sTrxReceiptDate,
                                                   OAFwkConstants.STATEMENT);
                  }

                  // Check if the receipt/payment date was changed.
                  // If it was changed, user must press the recalculate button as this may
                  // change the balance (discount calculations depend on payment date)
                  if ((sReceiptDate != null) &&
                      (!sReceiptDate.equals(sTrxReceiptDate))) {
                      // Set the new date in transaction
                      //tx.putValue("ReceiptDate", sReceiptDate);

                      expList.add(new OAException("AR",
                                                  "ARI_ADVPMT_PMTDATE_CHANGED_ERR"));
                  }
                  // Post changes to the database
                  ((OADBTransactionImpl)pageContext.getRootApplicationModule().getOADBTransaction()).postChanges();

                  //Bug #8293098 Surcharge for different card types
                  String sPayType = "BANK_ACCOUNT";
                  String sLookupCode = null;
                  if ("NEW_CC".equals(sPaymentType) ||
                      "EXISTING_CC".equals(sPaymentType)) {
                      String sViewObject;
                      String sMethod;
                      String sCreditCardType;

                      if ("NEW_CC".equals(sPaymentType)) {
                          sViewObject = "NewCreditCardVO";
                          sMethod = "getCreditCardType";

                          RowSetIterator it =
                              ((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject(sViewObject)).createRowSetIterator("iter");
                          NewCreditCardVORowImpl card =
                              (NewCreditCardVORowImpl)it.next();
                          it.reset();
                          it.closeRowSetIterator();
                          sCreditCardType = card.getCreditCardType();
                      } else {
                          sViewObject = "CreditCardsVO";
                          sMethod = "getSelectedCreditCardBrand";
                          sCreditCardType =
                                  (String)((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject(sViewObject)).invokeMethod("getSelectedCreditCardBrand");
                      }
                      sPayType = "CREDIT_CARD";
                      sLookupCode = sCreditCardType;
                  }
                  //Bug # 3467287 - Customer and Customer Site added as parameters for the method
                  Serializable[] params = { sCustomerId, sCustomerSiteUseId };
                  //Bug #8293098 Surcharge for different card types
                  Serializable paramsForSurcharge[] =
                  { sCustomerId, sCustomerSiteUseId, sPayType, sLookupCode };
                  //Bug3019729: MultiplePay functionality
                  // Recalculate the amounts
                  // ((OAApplicationModuleImpl)pageContext.getRootApplicationModule()).invokeMethod("recalculateAmounts");
                  ((OAApplicationModuleImpl)pageContext.getApplicationModule(webBean)).invokeMethod("recalculateAmounts",
                                                                                                    paramsForSurcharge);


                  Boolean bValidAmounts =
                      (Boolean)((OAApplicationModuleImpl)pageContext.getApplicationModule(webBean)).invokeMethod("isAmountsValid");
                  if (bValidAmounts == Boolean.TRUE) {
                      //Bug # 8403708  : added org_id to params list
                      String sOrgId = pageContext.getParameter("OrgContextId");
                      params =
                              new Serializable[] { sCustomerId, sCustomerSiteUseId,
                                                   sOrgId };
                      // Initialize the VO
                      //Bug # 3467287 - VO is striped by Customer and Customer Site.
                      ((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("MultipleInvoicesPayListSummaryVO")).invokeMethod("initQuery",
                                                                                                                                                params);

                      // Re-Query the Table VO
                      pageContext.getApplicationModule(webBean).invokeMethod("initMultipleInvoicePayList",
                                                                             params);
                  } else {
                      expList.add(new OAException("AR",
                                                  "ARI_ADVPMT_AMOUNT_CHANGED_ERR"));
                  }


              } catch (OAException e) {
                  expList.add(e);
              }

          }

          /*if (!(oaExp == null))
      {
        oaExp.setApplicationModule(rootAM);
        throw oaExp;
      }*/
          if (!expList.isEmpty()) {
              OAException tempExp = OAException.getBundledOAException(expList);
              tempExp.setApplicationModule(rootAM);
              throw tempExp;
          }

          if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
              pageContext.writeDiagnostics(pkgName, "end validatePage",
                                           OAFwkConstants.PROCEDURE);
      }

      /**
       * Validate the payment method used for the payment
       *
       * Writte By: jrautia
       *
       * @params  Object          Calling object
       * @params  OAPageContext   Page Context
       * @params  OAWebBean       Web Bean
       *
       */
      public static
      //Bug 3886652 - Customer and Customer Site Id added as params.
      void validatePaymentMethod(Object callingObject, OAPageContext pageContext,
                                 OAWebBean webBean, String sCustomerId,
                                 String sCustomerSiteUseId) {

          if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
              pageContext.writeDiagnostics(pkgName,
                                           "start validatePaymentMethod",
                                           OAFwkConstants.PROCEDURE);

          OAMessageChoiceBean paymentMethod =
              (OAMessageChoiceBean)webBean.findIndexedChildRecursive("PaymentType");
          String sPaymentMethod = (String)paymentMethod.getValue(pageContext);
          //Bug 3886652 - Customer Id and Customer Site Use Id added to getOneTimePaymentCustomization API
          Boolean bOneTimePayment =
              ((PaymentAMImpl)pageContext.getApplicationModule(webBean)).getOneTimePaymentCustomization(sCustomerId,
                                                                                                        sCustomerSiteUseId);
          if (bOneTimePayment.booleanValue())
              sPaymentMethod = "NEW_CC";
          if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
              pageContext.writeDiagnostics(pkgName,
                                           "sPaymentMethod = " + sPaymentMethod,
                                           OAFwkConstants.STATEMENT);

          if (sPaymentMethod == null || sPaymentMethod.equals("")) {

              throw new OAException("AR", "ARI_PAYMENT_METHOD_MISSING");
          }
          /*try {
        crossValidatePaymentMethod(callingObject, pageContext, webBean);
      } catch(OAException e) {
        throw e;
      }*/
          if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
              pageContext.writeDiagnostics(pkgName, "end validatePaymentMethod",
                                           OAFwkConstants.PROCEDURE);
      }


      /**
     * Cross Validate the payment method used for the payment
     *
     * Writte By: jrautia
     *
     * @params  Object          Calling object
     * @params  OAPageContext   Page Context
     * @params  OAWebBean       Web Bean
     *
     */
      /*public static void crossValidatePaymentMethod(Object callingObject, OAPageContext pageContext, OAWebBean webBean) {

        if (pageContext.isLoggingEnabled(OAWebBeanConstants.PROCEDURE))
          pageContext.writeDiagnostics(pkgName, "start crossValidatePaymentMethod", OAWebBeanConstants.PROCEDURE);

        OAWebBean newCreditCard    = (OAWebBean)webBean.findIndexedChildRecursive("NewCreditCardRegion");
        OAWebBean savedCreditCard  = (OAWebBean)webBean.findIndexedChildRecursive("SavedCreditCardRegion");
        OAWebBean newBankAccount   = (OAWebBean)webBean.findIndexedChildRecursive("NewBankAccountRegion");
        OAWebBean savedBankAccount = (OAWebBean)webBean.findIndexedChildRecursive("SavedBankAccountRegion");

        OAMessageChoiceBean paymentMethod = (OAMessageChoiceBean)webBean.findIndexedChildRecursive("PaymentType");
        String sPaymentMethod =  (String)paymentMethod.getValue(pageContext);
        Boolean bOneTimePayment = ((PaymentAMImpl)pageContext.getApplicationModule(webBean)).getOneTimePaymentCustomization();
        if (bOneTimePayment.booleanValue())
          sPaymentMethod = "NEW_CC";

        if (pageContext.isLoggingEnabled(OAWebBeanConstants.STATEMENT))
         {
           //pageContext.writeDiagnostics(pkgName, "bNewCreditCard = " + bNewCreditCard, OAWebBeanConstants.STATEMENT);
            pageContext.writeDiagnostics(pkgName, "sPaymentMethod = " + sPaymentMethod, OAWebBeanConstants.STATEMENT);
         }

        if (bNewCreditCard == true
            && !sPaymentMethod.equals("NEW_CC")) {

          throw new OAException("AR", "ARI_PM_CHANGED");

        } else if (bSavedCreditCard == true
            && !sPaymentMethod.equals("EXISTING_CC")) {

          throw new OAException("AR", "ARI_PM_CHANGED");

        } else if (bNewBankAccount == true
            && !sPaymentMethod.equals("NEW_BA")) {

          throw new OAException("AR", "ARI_PM_CHANGED");


        } else if (bSavedBankAccount == true
            && !sPaymentMethod.equals("EXISTING_BA")) {

          throw new OAException("AR", "ARI_PM_CHANGED");

        }

        if (pageContext.isLoggingEnabled(OAWebBeanConstants.PROCEDURE))
         pageContext.writeDiagnostics(pkgName, "end crossValidatePaymentMethod", OAWebBeanConstants.PROCEDURE);
    }*/


      /**
       * Process the payment
       *
       * Writte By: jrautiai
       *
       * Description: This method is called when all validations are completed and the payment is ready
       *              to be processed. It calls the payInvoiceInstallment method
       *
       * @params  Object          Calling object
       * @params  OAPageContext   Page Context
       * @params  OAWebBean       Web Bean
       *
       */
      public static
      //Bug 3886652 - Customer Id and Customer Site Use Id added as params
      void processPayment(Object callingObject, OAPageContext pageContext,
                          OAWebBean webBean, String sCustomerId,
                          String sCustomerSiteUseId,
                          String sCustSiteUseIdForPayment) {

          if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
              pageContext.writeDiagnostics(pkgName, "start processPayment",
                                           OAFwkConstants.PROCEDURE);

          Serializable[] emptyParam = { };

          OAWebBean quickPayment =
              (OAWebBean)webBean.findIndexedChildRecursive("QuickPaymentRegion");
          OAWebBean newCreditCard =
              (OAWebBean)webBean.findIndexedChildRecursive("NewCreditCardRegion");
          OAWebBean savedCreditCard =
              (OAWebBean)webBean.findIndexedChildRecursive("SavedCreditCardRegion");
          OAWebBean newBankAccount =
              (OAWebBean)webBean.findIndexedChildRecursive("NewBankAccountRegion");
          OAWebBean savedBankAccount =
              (OAWebBean)webBean.findIndexedChildRecursive("SavedBankAccountRegion");

          boolean bQuickPage =
              (quickPayment == null ? false : quickPayment.isRendered());

          String sPaymentType = "";
          //Modified below code for Bug 19222335
          if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT)) {
              pageContext.writeDiagnostics(pkgName, "bQuickPage = " + bQuickPage,
                                           OAFwkConstants.STATEMENT);
              pageContext.writeDiagnostics(pkgName,
                                           "sCustomerId = " + sCustomerId,
                                           OAFwkConstants.STATEMENT);
              pageContext.writeDiagnostics(pkgName,
                                           "sCustomerSiteUseId = " + sCustomerSiteUseId,
                                           OAFwkConstants.STATEMENT);
              /* pageContext.writeDiagnostics(pkgName, "bNewBankAccount = " + bNewBankAccount, OAWebBeanConstants.STATEMENT);
          pageContext.writeDiagnostics(pkgName, "bSavedBankAccount = " + bSavedBankAccount, OAWebBeanConstants.STATEMENT);
          */
          }
          Serializable[] param = { sCustomerId, sCustomerSiteUseId };
          if (bQuickPage == true) {
              //Modified for Bug#16262617
              ((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("DefaultPaymentInstrumentVO")).invokeMethod("processPaymentInstrument",
                                                                                                                                  param);
              sPaymentType = "DEFAULT";
          } else {
              // Bug 3913875 - Payment Confirmation
              //Modified for Bug#16262617
              ((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("CreditCardsVO")).invokeMethod("processCreditCard",
                                                                                                                     param);
              /*
          if (bNewCreditCard == true) {
            sPaymentType  = "NEW_CC";
          } else if (bNewBankAccount == true) {
            sPaymentType  = "NEW_BA";
          } else if (bSavedBankAccount == true) {
            sPaymentType  = "EXISTING_BA";
          } else {
            sPaymentType  = "EXISTING_CC";
            ((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("CreditCardsVO")).invokeMethod("processCreditCard", param);
          } */

              //Bug # 3303162
              //vnb, 9 Dec 2003.
              // Bug 3338276 - If one-time payment is enabled, the payment method defaulted is
              // New Credit Card.
              //Bug 3886652 - Customer Id and Customer Site Use Id added to getOneTimePaymentCustomization API
              Boolean oneTimePaymentEnabled =
                  (Boolean)pageContext.getApplicationModule(webBean).invokeMethod("getOneTimePaymentCustomization",
                                                                                  param);

              if (oneTimePaymentEnabled.booleanValue())
                  sPaymentType = "NEW_CC";
              else {
                  OAMessageChoiceBean paymentMethod =
                      (OAMessageChoiceBean)webBean.findIndexedChildRecursive("PaymentType");
                  sPaymentType = (String)paymentMethod.getValue(pageContext);
              }
          }

          if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
              pageContext.writeDiagnostics(pkgName,
                                           "sPaymentType = " + sPaymentType,
                                           OAFwkConstants.STATEMENT);

          payInvoiceInstallment(callingObject, sPaymentType, pageContext,
                                webBean, sCustSiteUseIdForPayment);

          if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
              pageContext.writeDiagnostics(pkgName, "end processPayment",
                                           OAFwkConstants.PROCEDURE);
      }

      public static String removeWhiteSpace(String source) {
          /*************************************************************
    * This takes a string and removes any character except      *
    * any digits.                                               *
    *************************************************************/
          int i, len = source.length();

          StringBuffer dest = new StringBuffer(len);
          try {
              for (i = 0; i < len; i++) {

                  if (Character.isLetterOrDigit(source.charAt(i))) {
                      dest.append(source.charAt(i));
                  }
              }
          } catch (Exception e) {
              // Just ignore the error if there is a mistake in tokens array
          }

          return dest.toString();

      }

      public static String removeNonDigits(String source) {
          /*************************************************************
    * This takes a string and removes any character except      *
    * any digits.                                               *
    *************************************************************/
          //int i, len = source.length();
		  
		   int i, len;
          
           if (source != null)
              len = source.length();
           else
              len = 0;      

          StringBuffer dest = new StringBuffer(len);
          try {
              for (i = 0; i < len; i++) {

                  if (Character.isDigit(source.charAt(i))) {
                      dest.append(source.charAt(i));
                  }
              }
          } catch (Exception e) {
              // Just ignore the error if there is a mistake in tokens array
          }

          return dest.toString();

      }

      public static boolean checkDigits(String source) {
          /*************************************************************
    * This takes a string and checks whether it consists only   *
    * of digits.                                                *
    *************************************************************/
          int i, len = source.length();

          StringBuffer dest = new StringBuffer(len);
          try {
              for (i = 0; i < len; i++) {

                  if (!Character.isDigit(source.charAt(i))) {
                      return false;
                  }
              }
          } catch (Exception e) {
              return false;
          }

          return true;
      }

      public static String getLastDayOfMonth(int month, int year) {

          int DaysInMonth[] = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
          int numDays; /* number of days in month */

          // Get number of days in month, adding one if February of leap year.
          numDays =
                  DaysInMonth[month - 1] + ((IsLeapYear(year) && (month == 2)) ?
                                            1 : 0);
          return String.valueOf(numDays);

      }

      public static boolean IsLeapYear(int year) {

          /* If multiple of 100, leap year if multiple of 400. */
          if ((year % 100) == 0)
              return ((year % 400) == 0);

          /* Otherwise leap year if multiple of 4. */
          return ((year % 4) == 0);

      } // IsLeapYear
      //Modified for Bug 17475275 by adding new parameter instr_assignment_id

      public static void updateAccountExpiryDate(Object callingObject,
                                                 OAApplicationModuleImpl rootAM,
                                                 OADBTransaction tx,
                                                 String sBankAccountId,
                                                 java.sql.Date dNewBADate,
                                                 String sPaymentInstrument,
                                                 Number branchId, Number bankId,
                                                 String bankAcNo,
                                                 String currency,
                                                 Number object_version_no,
                                                 Number customerId,
                                                 Number customerSiteUseId,
                                                 Number instr_assignment_id) {

          if (tx.isLoggingEnabled(OAFwkConstants.PROCEDURE))
              tx.writeDiagnostics(pkgName, "start updateAccountExpiryDate",
                                  OAFwkConstants.PROCEDURE);

          String sql =
              "BEGIN AR_IREC_PAYMENTS.update_expiration_date(:1,:2, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12, :13, :14); END;";

          // Create the callable statement
          OracleCallableStatement callStmt =
              (OracleCallableStatement)tx.createCallableStatement(sql, 1);
          long lDummyLong = -1;
          try {
              if (tx.isLoggingEnabled(OAFwkConstants.STATEMENT)) {
                  tx.writeDiagnostics(pkgName,
                                      "sBankAccountId = " + sBankAccountId,
                                      OAFwkConstants.STATEMENT);
                  tx.writeDiagnostics(pkgName, "dNewBADate = " + dNewBADate,
                                      OAFwkConstants.STATEMENT);
                  tx.writeDiagnostics(pkgName,
                                      "instr_assignment_id = " + instr_assignment_id,
                                      OAFwkConstants.STATEMENT);
              }
              callStmt.setString(1, sBankAccountId);
              callStmt.setDate(2, dNewBADate);
              callStmt.setString(3, sPaymentInstrument);
              callStmt.setLong(4, branchId == null ? -1 : branchId.longValue());
              callStmt.setLong(5, bankId == null ? -1 : bankId.longValue());
              callStmt.setString(6, bankAcNo);
              callStmt.setString(7, currency);
              callStmt.setLong(8,
                               object_version_no == null ? -1 : object_version_no.longValue());
              callStmt.registerOutParameter(9, java.sql.Types.VARCHAR, 0, 2);
              callStmt.registerOutParameter(10, Types.INTEGER);
              callStmt.registerOutParameter(11, java.sql.Types.VARCHAR, 0, 6000);
              callStmt.setLong(12, customerId.longValue());
              callStmt.setLong(13,
                               (customerSiteUseId == null ? lDummyLong : customerSiteUseId.longValue()));
              //Added for Bug 17475275
              callStmt.setLong(14,
                               (instr_assignment_id == null ? 0 : instr_assignment_id.longValue()));
              callStmt.execute();

              String status = callStmt.getString(9);
              int iErrorCount = callStmt.getInt(10);
              String sErrorMessage = callStmt.getString(11);

              // Set update status in transaction value
              tx.putValue("CreditCardUpdated", "TRUE");

              tx.commit(); //bug 8320027 - UPDATING CREDIT CARD EXPIRATION DATE IS NOT CORRECT

          } catch (Exception e) {
              try {
                  if (Logger.isEnabled(Logger.EXCEPTION))
                      Logger.out(e, OAFwkConstants.EXCEPTION,
                                 Class.forName("oracle.apps.ar.irec.accountDetails.pay.utilities.PaymentUtilities"));
              } catch (ClassNotFoundException cnfE) {
              }
              throw OAException.wrapperException(e);
          } finally {
              try {
                  callStmt.close();
              } catch (Exception e) {
                  throw OAException.wrapperException(e);
              }
          }
          if (tx.isLoggingEnabled(OAFwkConstants.PROCEDURE))
              tx.writeDiagnostics(pkgName, "end updateAccountExpiryDate",
                                  OAFwkConstants.PROCEDURE);
      }

      public static void validateCreditCardExpiryDate(Object callingObject,
                                                      OAApplicationModuleImpl rootAM,
                                                      String sCreditCardExpiryMonth,
                                                      String sCreditCardExpiryYear) {

          OADBTransaction tx = (OADBTransaction)rootAM.getDBTransaction();

          if (tx.isLoggingEnabled(OAFwkConstants.PROCEDURE))
              tx.writeDiagnostics(pkgName, "start validateCreditCardExpiryDate",
                                  OAFwkConstants.PROCEDURE);
          if (tx.isLoggingEnabled(OAFwkConstants.STATEMENT)) {
              tx.writeDiagnostics(pkgName,
                                  "sCreditCardExpiryMonth = " + sCreditCardExpiryMonth,
                                  OAFwkConstants.STATEMENT);
              tx.writeDiagnostics(pkgName,
                                  "sCreditCardExpiryYear = " + sCreditCardExpiryYear,
                                  OAFwkConstants.STATEMENT);
          }

          ArrayList expList = new ArrayList();

          try {
              RowSetIterator iter =
                  ((MultipleInvoicesPayListSummaryVOImpl)rootAM.findViewObject("MultipleInvoicesPayListSummaryVO")).createRowSetIterator("iter");
              iter.reset();
              MultipleInvoicesPayListSummaryVORowImpl row =
                  (MultipleInvoicesPayListSummaryVORowImpl)iter.next();

              String sCurrentMonth = row.getCurrentMonth();
              String sCurrentYear = row.getCurrentYear();
              if (tx.isLoggingEnabled(OAFwkConstants.STATEMENT)) {
                  tx.writeDiagnostics(pkgName,
                                      "sCurrentMonth = " + sCurrentMonth,
                                      OAFwkConstants.STATEMENT);
                  tx.writeDiagnostics(pkgName, "sCurrentYear = " + sCurrentYear,
                                      OAFwkConstants.STATEMENT);
              }

              iter.closeRowSetIterator();

              Integer iCurrentMonth = new Integer(sCurrentMonth);
              Integer iCurrentYear = new Integer(sCurrentYear);

              if (!"XX".equals(sCreditCardExpiryMonth) &&
                  !"XXXX".equals(sCreditCardExpiryYear)) {

                  Integer iExpiryMonth =
                      (("".equals(sCreditCardExpiryMonth) || sCreditCardExpiryMonth ==
                        null) ? new Integer(0) :
                       new Integer(sCreditCardExpiryMonth));
                  Integer iExpiryYear =
                      (("".equals(sCreditCardExpiryYear) || sCreditCardExpiryYear ==
                        null) ? new Integer(0) :
                       new Integer(sCreditCardExpiryYear));

                  if (iExpiryMonth.intValue() == 0 &&
                      iExpiryYear.intValue() != 0) {
                      expList.add(new OAException("AR",
                                                  "ARI_EXPIRY_MONTH_MISSING"));
                  }
                  if (iExpiryYear.intValue() == 0 &&
                      iExpiryMonth.intValue() != 0) {
                      expList.add(new OAException("AR",
                                                  "ARI_EXPIRY_YEAR_MISSING"));
                  }
                  if (iExpiryMonth.intValue() != 0 &&
                      iExpiryYear.intValue() != 0) {

                      if (iExpiryMonth.intValue() < iCurrentMonth.intValue() &&
                          iExpiryYear.intValue() == iCurrentYear.intValue()) {

                          expList.add(new OAException("AR",
                                                      "ARI_EXPIRED_CREDIT_CARD"));
                      }
                  }
              } else if ("XX".equals(sCreditCardExpiryMonth) &&
                         !"XXXX".equals(sCreditCardExpiryYear)) {
                  expList.add(new OAException("AR", "ARI_EXPIRY_MONTH_MISSING"));
              } else if (!"XX".equals(sCreditCardExpiryMonth) &&
                         "XXXX".equals(sCreditCardExpiryYear)) {
                  expList.add(new OAException("AR", "ARI_EXPIRY_YEAR_MISSING"));
              }

          } catch (Exception e) {
              try {
                  if (Logger.isEnabled(Logger.EXCEPTION))
                      Logger.out(e, OAFwkConstants.EXCEPTION,
                                 Class.forName("oracle.apps.ar.irec.accountDetails.pay.utilities.PaymentUtilities"));
              } catch (ClassNotFoundException cnfE) {
              }
              throw OAException.wrapperException(e);
          }

          OAException.raiseBundledOAException(expList);

          if (tx.isLoggingEnabled(OAFwkConstants.PROCEDURE))
              tx.writeDiagnostics(pkgName, "end validateCreditCardExpiryDate",
                                  OAFwkConstants.PROCEDURE);
      }

      public static void storeLastUsedBA(Object callingObject, Number customerId,
                                         Number bankAccountId,
                                         OADBTransaction tx,
                                         String paymentType) {

          if (tx.isLoggingEnabled(OAFwkConstants.PROCEDURE))
              tx.writeDiagnostics(pkgName, "start storeLastUsedBA",
                                  OAFwkConstants.PROCEDURE);

          try {

              String status = "";
              String sql = "";
              if ("NEW_BA".equals(paymentType) ||
                  "EXISTING_BA".equals(paymentType))
                  sql =
  "BEGIN AR_IREC_PAYMENTS.store_last_used_ba(p_customer_id => :1, p_bank_account_id => :2, p_status => :3); END;";
              else
                  sql =
  "BEGIN AR_IREC_PAYMENTS.store_last_used_cc(p_customer_id => :1, p_bank_account_id => :2, p_status => :3); END;";

              // Create the callable statement
              OracleCallableStatement callStmt =
                  (OracleCallableStatement)tx.createCallableStatement(sql, 1);

              try {
                  if (tx.isLoggingEnabled(OAFwkConstants.STATEMENT)) {
                      tx.writeDiagnostics(pkgName, "customerId = " + customerId,
                                          OAFwkConstants.STATEMENT);
                      tx.writeDiagnostics(pkgName,
                                          "bankAccountId = " + bankAccountId,
                                          OAFwkConstants.STATEMENT);
                  }

                  callStmt.setLong(1, customerId.longValue());
                  callStmt.setLong(2, bankAccountId.longValue());
                  callStmt.registerOutParameter(3, java.sql.Types.VARCHAR, 0, 2);

                  callStmt.execute();

                  status = callStmt.getString(3);

              } catch (Exception e) {
                  throw OAException.wrapperException(e);
              } finally {
                  try {
                      callStmt.close();
                  } catch (Exception e) {
                      throw OAException.wrapperException(e);
                  }
              }
          } catch (Exception e) {
              throw OAException.wrapperException(e);
          }
          if (tx.isLoggingEnabled(OAFwkConstants.PROCEDURE))
              tx.writeDiagnostics(pkgName, "end storeLastUsedBA",
                                  OAFwkConstants.PROCEDURE);
      }

      public static Number getBankBranchId(Object callingObject, String sBankNum,
                                           OADBTransaction tx) {

          if (tx.isLoggingEnabled(OAFwkConstants.PROCEDURE))
              tx.writeDiagnostics(pkgName, "start getBankBranchId",
                                  OAFwkConstants.PROCEDURE);

          Number bankBranchId = null;

          try {

              String sql = "";

              sql = "BEGIN ARP_BANK_PKG.get_bank_branch_id(:1,:2); END;";

              // Create the callable statement
              OracleCallableStatement callStmt =
                  (OracleCallableStatement)tx.createCallableStatement(sql, 1);

              try {
                  if (tx.isLoggingEnabled(OAFwkConstants.STATEMENT))
                      tx.writeDiagnostics(pkgName, "sBankNum = " + sBankNum,
                                          OAFwkConstants.STATEMENT);

                  callStmt.setString(1, sBankNum);
                  callStmt.registerOutParameter(2, java.sql.Types.BIGINT, 38,
                                                38);

                  callStmt.execute();

                  bankBranchId =
                          new oracle.jbo.domain.Number(callStmt.getLong(2));

              } catch (Exception e) {
                  throw OAException.wrapperException(e);
              } finally {
                  try {
                      callStmt.close();
                  } catch (Exception e) {
                      throw OAException.wrapperException(e);
                  }
              }
          } catch (Exception e) {
              throw OAException.wrapperException(e);
          }
          if (tx.isLoggingEnabled(OAFwkConstants.PROCEDURE))
              tx.writeDiagnostics(pkgName, "end getBankBranchId",
                                  OAFwkConstants.PROCEDURE);
          return bankBranchId;
      }


      /**
       * Converts a java.util.Date into a oracle.jbo.domain.Date
       */
      private static oracle.jbo.domain.Date getJBODomainDate(java.util.Date javaUtilDate) {
          //java.util.Date today = pageContext.getCurrentDBDate();
          long dateInMilliseconds = javaUtilDate.getTime();
          java.sql.Date javaSqlDate = new java.sql.Date(dateInMilliseconds);
          oracle.jbo.domain.Date jboDomainDate =
              new oracle.jbo.domain.Date(javaSqlDate);

          return jboDomainDate;

      }

      private static Boolean isOneTimePaymentEnabled(OAPageContext pageContext,
                                                     OAWebBean webBean,
                                                     Number customerId,
                                                     Number customerSiteUseId) {
          PaymentAMImpl payAMImpl =
              (PaymentAMImpl)pageContext.getApplicationModule(webBean);
          String sCustomerId = customerId.toString();
          String sCustomerSiteUseId =
              customerSiteUseId == null ? null : customerSiteUseId.toString();
          Serializable[] params = { sCustomerId, sCustomerSiteUseId };
          Boolean bOneTimePayment =
              (Boolean)payAMImpl.invokeMethod("getOneTimePaymentCustomization",
                                              params);
          return bOneTimePayment;
      }

      /*
    // This function should be called in all cases of Payment Processing Errors.
      //Modified for Bug 14797901 - added singleUseFlag parameter in the method signature

      private static void rollbackAndDisplayErrorMessage(Object callingObject,
                                                         OAPageContext pageContext,
                                                         OADBTransaction tx,
                                                         String sPaymentScheduleId,
                                                         Number customerId,
                                                         String paymentType,
                                                         Number bankAccountId,
                                                         Number customerSiteUseId,
                                                         OAWebBean webBean,
                                                         String singleUseFlag) {
          tx.rollback();
          //Bug 3335944 - One Time Credit Card Verification
          String sTxValue = (String)tx.getValue("NewCreditCardVOInitialised");
          if (sTxValue != null)
              tx.putValue("NewCreditCardVOInitialised", "Y");

          StringBuffer okUrl = new StringBuffer("OA.jsp?");
          okUrl.append("akRegionCode=").append("ARI_INVOICE_PAYMENT_PAGE");
          okUrl.append("&akRegionApplicationId=222");
          if (sPaymentScheduleId != null)
              okUrl.append("&Irpaymentscheduleid=" + sPaymentScheduleId);
          // Bug # 3186472 - hikumar
          // Modified to encrypt customerId before sending in URL
          okUrl.append("&Ircustomerid={!!" +
                       pageContext.encrypt(String.valueOf(customerId)) + "}");

          //Bug3062130: Append parameter to avoid re-inserting into temporary table.
          okUrl.append("&Irselected=Y");
          //Bug 4673563 - Error making credit card payment
          String instrumentSuccessMessage = null;
          // bug 8333422
          String sCustomerId = null, sCustoemrSiteUseId = null;
          if (customerId != null && !"".equals(customerId))
              sCustomerId = String.valueOf(customerId);
          if (customerSiteUseId != null && !"".equals(customerSiteUseId))
              sCustoemrSiteUseId = String.valueOf(customerSiteUseId);
          String orgContextId = pageContext.getParameter("OrgContextId");
          Serializable[] customerSiteOrgIdParam =
          { sCustomerId, sCustoemrSiteUseId, orgContextId };

          if ((paymentType.equals("NEW_CC") || paymentType.equals("NEW_BA"))) {


              //When new credit card/bank account, if bankAccountId value is greater than 0, means
              //the instrument has been created. So, should be redirected to Saved instrument page
              if (bankAccountId != null && bankAccountId.compareTo(0) > 0) {
                  Boolean bOneTimePayment =
                      isOneTimePaymentEnabled(pageContext, webBean, customerId,
                                              customerSiteUseId);
                  //Bug 4661432 - Display Saved Payment instrument message only when Saved Payment Instrument is Yes
                  //Modified for Bug 14797901
                  if (!bOneTimePayment.booleanValue() &&
                      (singleUseFlag != null && !"".equals(singleUseFlag) &&
                       !"Y".equalsIgnoreCase(singleUseFlag))) {
                      okUrl.append("&Irpaymethod=SAVED");
                      if (paymentType.equals("NEW_CC")) {
                          ((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("CreditCardsVO")).invokeMethod("initQuery",
                                                                                                                                 customerSiteOrgIdParam); // bug 8333422
                          instrumentSuccessMessage =
                                  pageContext.getMessage("AR", "ARI_CREDIT_CARD_SAVED",
                                                         null);
                      } else {
                          ((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("BankAccountsVO")).invokeMethod("initQuery",
                                                                                                                                  customerSiteOrgIdParam); // bug 8333422
                          instrumentSuccessMessage =
                                  pageContext.getMessage("AR", "ARI_BANK_ACCOUNT_SAVED",
                                                         null);
                      }
                  }
              } else
                  okUrl.append("&Irpaymethod=NEW");

          } else if (paymentType.equals("DEFAULT"))
              okUrl.append("&Irpaymethod=QUICK");
          else if (paymentType.equals("SAVED_CC") ||
                   paymentType.equals("SAVED_BA"))
              okUrl.append("&Irpaymethod=SAVED");

          okUrl.append("&retainAM=Y");
          //If instrument creation is successful, the message should be shown to the user
          String errorMessage =
              instrumentSuccessMessage + pageContext.getMessage("AR",
                                                                "ARI_PMT_PROCESS_ERROR",
                                                                null);
          OADialogPage warningDialog = null;
          warningDialog =
                  new OADialogPage(OAException.ERROR, null, new OAException(errorMessage),
                                   okUrl.toString(), null);

          tx.putValue("PaymentInProcess", "N");

          // Work aound for bug 2890625.  This region will properly set the global
          // buttons in the error page.
          warningDialog.setHeaderNestedRegionRefName("/oracle/apps/ar/irec/regions/DialogGlobalButtonsRegion");

          pageContext.redirectToDialogPage(warningDialog);
      }

      //Bug 3630101 - Payment process setup errors to be displayed to internal user
      // This function should be called in all cases of Payment Processing Errors.
      //Modified for Bug 14797901 - added singleUseFlag parameter in the method signature

      private static void rollbackAndDisplayErrorMessage(Object callingObject,
                                                         OAPageContext pageContext,
                                                         OADBTransaction tx,
                                                         String sPaymentScheduleId,
                                                         Number customerId,
                                                         String paymentType,
                                                         String sErrorMessage,
                                                         Number bankAccountId,
                                                         Number customerSiteUseId,
                                                         OAWebBean webBean,
                                                         String singleUseFlag) {
          //tx.rollback();
          tx.putValue("PaymentInProcess", "N");

          StringTokenizer sTokens = new StringTokenizer(sErrorMessage, "*");

          ArrayList list = new ArrayList();

          // bug 8333422
          String sCustomerId = null, sCustoemrSiteUseId = null;
          if (customerId != null && !"".equals(customerId))
              sCustomerId = String.valueOf(customerId);
          if (customerSiteUseId != null && !"".equals(customerSiteUseId))
              sCustoemrSiteUseId = String.valueOf(customerSiteUseId);
          String orgContextId = pageContext.getParameter("OrgContextId");
          Serializable[] customerSiteOrgIdParam =
          { sCustomerId, sCustoemrSiteUseId, orgContextId };

          String instrumentSuccessMessage = null;
          Boolean bOneTimePayment =
              isOneTimePaymentEnabled(pageContext, webBean, customerId,
                                      customerSiteUseId);
          //Bug 4661432 - Display Saved Payment instrument message only when Saved Payment Instrument is Yes
          //Modified for Bug 14797901
          if (!bOneTimePayment.booleanValue() &&
              (singleUseFlag != null && !"".equals(singleUseFlag) &&
               !"Y".equalsIgnoreCase(singleUseFlag))) {
              if (bankAccountId != null && bankAccountId.compareTo(0) > 0) {
                  if (paymentType.equals("NEW_CC")) {
                      ((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("CreditCardsVO")).invokeMethod("initQuery",
                                                                                                                             customerSiteOrgIdParam); // bug 8333422
                      instrumentSuccessMessage =
                              pageContext.getMessage("AR", "ARI_CREDIT_CARD_SAVED",
                                                     null);
                  } else if (paymentType.equals("NEW_BA")) {
                      ((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("BankAccountsVO")).invokeMethod("initQuery",
                                                                                                                              customerSiteOrgIdParam); // bug 8333422
                      instrumentSuccessMessage =
                              pageContext.getMessage("AR", "ARI_BANK_ACCOUNT_SAVED",
                                                     null);
                  }
              }
          }
          //If instrument creation is successful, the message should be shown to the user
          if (instrumentSuccessMessage != null)
              list.add(new OAException(instrumentSuccessMessage));

          list.add(new OAException("AR", "ARI_PMT_SETUP_ERROR"));

          while (sTokens.hasMoreTokens())
              list.add(new OAException(sTokens.nextToken()));

          //added for bug 6137234   // commented for bug 7673372

      //      list.add(new OAException("AR","ARI_PMT_SEQ_ERROR"));

      //  if(paymentType.equals("NEW_CC"))
       //     list.add(new OAException("AR","ARI_PMT_SITE_NUM_ERROR"));
  //
          if (list.size() > 0)
              OAException.raiseBundledOAException(list);

      }
          */

      // This function should be called in all cases of Payment Processing Errors.

      private static void rollbackAndDisplayErrorMessage(Object callingObject,
                                                         OAPageContext pageContext,
                                                         OADBTransaction tx,
                                                         String sPaymentScheduleId,
                                                         Number customerId,
                                                         String paymentType,
                                                         Number bankAccountId,
                                                         Number customerSiteUseId,
                                                         OAWebBean webBean) {
          pageContext.writeDiagnostics(callingObject,
                                       "XXOD:rollbackAndDisplayErrorMessage -in all cases of Payment Processing Errors ",
                                       1);

          pageContext.writeDiagnostics(callingObject,
                                       "XXOD:" + "sPaymentScheduleId" +
                                       sPaymentScheduleId + "customerId      " +
                                       customerId + "paymentType     " +
                                       paymentType + "bankAccountId          " +
                                       bankAccountId + "customerSiteUseId " +
                                       customerSiteUseId, 1);
          tx.rollback();
          //Bug 3335944 - One Time Credit Card Verification
          String sTxValue = (String)tx.getValue("NewCreditCardVOInitialised");
          if (sTxValue != null)
              tx.putValue("NewCreditCardVOInitialised", "Y");

          StringBuffer okUrl = new StringBuffer("OA.jsp?");
          okUrl.append("akRegionCode=").append("ARI_INVOICE_PAYMENT_PAGE");
          okUrl.append("&akRegionApplicationId=222");
          if (sPaymentScheduleId != null)
              okUrl.append("&Irpaymentscheduleid=" + sPaymentScheduleId);
          // Bug # 3186472 - hikumar
          // Modified to encrypt customerId before sending in URL
          okUrl.append("&Ircustomerid={!!" +
                       pageContext.encrypt(String.valueOf(customerId)) + "}");

          //Bug3062130: Append parameter to avoid re-inserting into temporary table.
          okUrl.append("&Irselected=Y");
          //Bug 4673563 - Error making credit card payment
          String instrumentSuccessMessage = null;
          // bug 8333422
          String sCustomerId = null, sCustoemrSiteUseId = null;
          if (customerId != null && !"".equals(customerId))
              sCustomerId = String.valueOf(customerId);
          if (customerSiteUseId != null && !"".equals(customerSiteUseId))
              sCustoemrSiteUseId = String.valueOf(customerSiteUseId);
          String orgContextId = pageContext.getParameter("OrgContextId");
          Serializable[] customerSiteOrgIdParam =
          { sCustomerId, sCustoemrSiteUseId, orgContextId };
          pageContext.writeDiagnostics(callingObject,
                                       "XXOD: before if statement NEWCC NEWBA ",
                                       1);
          if ((paymentType.equals("NEW_CC") || paymentType.equals("NEW_BA"))) {


              //When new credit card/bank account, if bankAccountId value is greater than 0, means
              //the instrument has been created. So, should be redirected to Saved instrument page
              pageContext.writeDiagnostics(callingObject, "XXOD: Step 10.10", 1);
              if (bankAccountId != null && bankAccountId.compareTo(0) > 0) {
                  pageContext.writeDiagnostics(callingObject, "XXOD: Step 10.20",
                                               1);

                  Boolean bOneTimePayment =
                      isOneTimePaymentEnabled(pageContext, webBean, customerId,
                                              customerSiteUseId);
                  //Bug 4661432 - Display Saved Payment instrument message only when Saved Payment Instrument is Yes
                  if (!bOneTimePayment.booleanValue()) {
                      pageContext.writeDiagnostics(callingObject,
                                                   "XXOD: Step 10.30", 1);

                      okUrl.append("&Irpaymethod=SAVED");
                      if (paymentType.equals("NEW_CC")) {
                          pageContext.writeDiagnostics(callingObject,
                                                       "XXOD: Step 10.40", 1);

                          ((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("CreditCardsVO")).invokeMethod("initQuery",
                                                                                                                                 customerSiteOrgIdParam); // bug 8333422
                          instrumentSuccessMessage =
                                  pageContext.getMessage("AR", "ARI_CREDIT_CARD_SAVED",
                                                         null);
                          pageContext.writeDiagnostics(callingObject,
                                                       "XXOD:if instrumentSuccessMessage " +
                                                       instrumentSuccessMessage,
                                                       1);
                      } else {
                          pageContext.writeDiagnostics(callingObject,
                                                       "XXOD: Step 10.50", 1);

                          ((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("BankAccountsVO")).invokeMethod("initQuery",
                                                                                                                                  customerSiteOrgIdParam); // bug 8333422
                          instrumentSuccessMessage =
                                  pageContext.getMessage("AR", "ARI_BANK_ACCOUNT_SAVED",
                                                         null);
                          pageContext.writeDiagnostics(callingObject,
                                                       "XXOD:else instrumentSuccessMessage " +
                                                       instrumentSuccessMessage,
                                                       1);
                      }
                  }
              } else {
                  pageContext.writeDiagnostics(callingObject, "XXOD: Step 10.60",
                                               1);

                  okUrl.append("&Irpaymethod=NEW");
			  }

          } else if (paymentType.equals("DEFAULT"))
              okUrl.append("&Irpaymethod=QUICK");
          else if (paymentType.equals("SAVED_CC") ||
                   paymentType.equals("SAVED_BA"))
              okUrl.append("&Irpaymethod=SAVED");

          okUrl.append("&retainAM=Y");

          pageContext.writeDiagnostics(callingObject, "XXOD:*** okUrl " + okUrl,
                                       1);

          //If instrument creation is successful, the message should be shown to the user
          String errorMessage =
              instrumentSuccessMessage + pageContext.getMessage("AR",
                                                                "ARI_PMT_PROCESS_ERROR",
                                                                null);
          pageContext.writeDiagnostics(callingObject,
                                       "XXOD: Step 10.70 errorMessage" +
                                       errorMessage, 1);

          // OADialogPage warningDialog = null;
          //Check R12 code
          //     warningDialog =
          //           new OADialogPage(OAException.ERROR, null, new OAException(errorMessage),
          //                          okUrl.toString(), null);


          /*Added for R12 upgrade retrofit*/
          //<<BEGIN>> Modification for the CR2462 by Madankumar J,Wipro Technologies.
          OADialogPage oadialogpage = null;
          String Gc_bep_code2 =
              (String)pageContext.getSessionValue("x_bep_value");
          pageContext.writeDiagnostics(callingObject,
                                       "AJB bep_code value " + Gc_bep_code2, 1);
          if (Gc_bep_code2 != null && Gc_bep_code2.equals("2")) {
              String x_render_value =
                  (String)pageContext.getSessionValue("x_render");
              pageContext.writeDiagnostics(callingObject,
                                           "User-Collector and responsibility validation returns " +
                                           x_render_value, 1);
              if (x_render_value != null && x_render_value.equals("TRUE")) {

                  pageContext.writeDiagnostics(callingObject,
                                               "XXOD: Step 10.80.1"+okUrl.toString(), 1);

                  oadialogpage =
                          new OADialogPage((byte)1, null, new OAException("AR",
                                                                          "XX_AR_IREC_VERB_AUTH1"),
                                           okUrl.toString(), null);


 
                   oadialogpage.setShowInPopup(false);


 

                  //pageContext.writeDiagnostics(callingObject, "XXOD: Step 10.80.2", 1);
              } else if (x_render_value != null &&
                         x_render_value.equals("FALSE")) {

                  pageContext.writeDiagnostics(callingObject,
                                               "XXOD: Step 10.90.1", 1);
                  oadialogpage =
                          new OADialogPage((byte)1, null, new OAException("AR",
                                                                          "XX_AR_IREC_VERB_AUTH2"),
                                           okUrl.toString(), null);
				  oadialogpage.setShowInPopup(false); 
                  pageContext.writeDiagnostics(callingObject,
                                               "XXOD: Step 10.80.2", 1);
              } else {

                  oadialogpage =
                          new OADialogPage((byte)0, null, new OAException("AR",
                                                                          "ARI_PMT_PROCESS_ERROR"),
                                           okUrl.toString(), null);
										   
					oadialogpage.setShowInPopup(false);
              }
          } else {

              pageContext.writeDiagnostics(callingObject, "XXOD: Step 10.100.1",
                                           1);
              pageContext.writeDiagnostics(callingObject,
                                           "okurl " + okUrl.toString(), 1);

              oadialogpage =
                      new OADialogPage((byte)0, null, new OAException("AR",
                                                                      "ARI_PMT_PROCESS_ERROR"),
                                       okUrl.toString(), null);
									   
			  oadialogpage.setShowInPopup(false);
			  
              pageContext.writeDiagnostics(callingObject,
                                           "after ARI_PMT_PROCESS_ERROR", 1);
              pageContext.writeDiagnostics(callingObject, "XXOD: Step 10.100.2",
                                           1);
          }
          //<<END>> Modification for the CR2462 by Madankumar J,Wipro Technologies.
          /*End-*Added for R12 upgrade retrofit*/

          tx.putValue("PaymentInProcess", "N");

          // Work aound for bug 2890625.  This region will properly set the global
          // buttons in the error page.
          pageContext.writeDiagnostics(callingObject, "XXOD: Step 10.110", 1);

          //oadialogpage.setHeaderNestedRegionRefName("/oracle/apps/ar/irec/regions/DialogGlobalButtonsRegion");
          pageContext.writeDiagnostics(callingObject, "XXOD: Step 10.120", 1);

          //pageContext.redirectToDialogPage(oadialogpage);

          pageContext.redirectToDialogPage(oadialogpage);

          pageContext.writeDiagnostics(callingObject, "XXOD: Step 10.130", 1);


          pageContext.writeDiagnostics(callingObject,
                                       "end rollbackAndDisplayErrorMessage", 1);
      }

      //Bug 3630101 - Payment process setup errors to be displayed to internal user
      // This function should be called in all cases of Payment Processing Errors.

      private static void rollbackAndDisplayErrorMessage(Object callingObject,
                                                         OAPageContext pageContext,
                                                         OADBTransaction tx,
                                                         String sPaymentScheduleId,
                                                         Number customerId,
                                                         String paymentType,
                                                         String sErrorMessage,
                                                         Number bankAccountId,
                                                         Number customerSiteUseId,
                                                         OAWebBean webBean) {
          pageContext.writeDiagnostics(callingObject,
                                       "XXOD: Step 20.10 - Start rollbackAndDisplayErrorMessage",
                                       1);

		  pageContext.writeDiagnostics(callingObject,
                                       "XXOD: Step 20.10.1 -sPaymentScheduleId"+sPaymentScheduleId,
                                       1);

          pageContext.writeDiagnostics(callingObject,
                                       "XXOD: Step 20.10.2 -customerId"+customerId,
                                       1);

          pageContext.writeDiagnostics(callingObject,
                                       "XXOD: Step 20.10.3 -paymentType"+paymentType,
                                       1);

          pageContext.writeDiagnostics(callingObject,
                                       "XXOD: Step 20.10.4 -sErrorMessage"+sErrorMessage,
                                       1);


          pageContext.writeDiagnostics(callingObject,
                                       "XXOD: Step 20.10.5 -bankAccountId"+bankAccountId,
                                       1);


          pageContext.writeDiagnostics(callingObject,
                                       "XXOD: Step 20.10.6 -customerSiteUseId"+customerSiteUseId,
                                       1);


		  //tx.rollback();
          tx.putValue("PaymentInProcess", "N");

      

          ArrayList list = new ArrayList();

          // bug 8333422
          String sCustomerId = null, sCustoemrSiteUseId = null;
          if (customerId != null && !"".equals(customerId))
              sCustomerId = String.valueOf(customerId);
          if (customerSiteUseId != null && !"".equals(customerSiteUseId))
              sCustoemrSiteUseId = String.valueOf(customerSiteUseId);
          String orgContextId = pageContext.getParameter("OrgContextId");
          Serializable[] customerSiteOrgIdParam =
          { sCustomerId, sCustoemrSiteUseId, orgContextId };

          String instrumentSuccessMessage = null;
          pageContext.writeDiagnostics(callingObject,
                                       "XXOD: Step 20.10.7",
                                       1);

		  Boolean bOneTimePayment =
              isOneTimePaymentEnabled(pageContext, webBean, customerId,
                                      customerSiteUseId);

		   pageContext.writeDiagnostics(callingObject,
                                       "XXOD: Step 20.10.8",
                                       1);
          //Bug 4661432 - Display Saved Payment instrument message only when Saved Payment Instrument is Yes
          if (!bOneTimePayment.booleanValue()) {
			   pageContext.writeDiagnostics(callingObject,
                                       "XXOD: Step 20.10.9",
                                       1);
              if (bankAccountId != null && bankAccountId.compareTo(0) > 0) {
				 
				   pageContext.writeDiagnostics(callingObject,
                                       "XXOD: Step 20.10.10 paymentType"+ paymentType,
                                       1);
				  if ((paymentType!= null) && (!"".equals(paymentType)) && (!"null".equals(paymentType)))
				  {
					    pageContext.writeDiagnostics(callingObject,
                                       "XXOD: Step 20.10.11",
                                       1);

					  if (paymentType.equals("NEW_CC")) {
						   pageContext.writeDiagnostics(callingObject,
                                       "XXOD: Step 20.10.12",
                                       1);
                      ((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("CreditCardsVO")).invokeMethod("initQuery",
                                                                                                                             customerSiteOrgIdParam); // bug 8333422
                      instrumentSuccessMessage =
                              pageContext.getMessage("AR", "ARI_CREDIT_CARD_SAVED",
                                                     null);
                  } else if (paymentType.equals("NEW_BA")) {
					    pageContext.writeDiagnostics(callingObject,
                                       "XXOD: Step 20.10.13",
                                       1);
                      ((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("BankAccountsVO")).invokeMethod("initQuery",
                                                                                                                              customerSiteOrgIdParam); // bug 8333422
                      instrumentSuccessMessage =
                              pageContext.getMessage("AR", "ARI_BANK_ACCOUNT_SAVED",
                                                     null);
                  }

				  }
                  
              }
          }

		   pageContext.writeDiagnostics(callingObject,
                                       "XXOD: Step 20.10.14",
                                       1);
          //If instrument creation is successful, the message should be shown to the user
          if (instrumentSuccessMessage != null) {
			   pageContext.writeDiagnostics(callingObject,
                                       "XXOD: Step 20.10.15",
                                       1);
              list.add(new OAException(instrumentSuccessMessage));
		  }
 
          list.add(new OAException("AR", "ARI_PMT_SETUP_ERROR"));
         

		/*Start - Modified for Defect38030 */  
		 if(sErrorMessage != null && !"".equals(sErrorMessage))
        {
          StringTokenizer sTokens = new StringTokenizer(sErrorMessage, "*");
          while (sTokens.hasMoreTokens()){
			   pageContext.writeDiagnostics(callingObject,
                                       "XXOD: Step 20.10.16",
                                       1);
              list.add(new OAException(sTokens.nextToken()));
		  }
		  int flag = sErrorMessage.indexOf("ecline");    
		  
		  if (flag != -1) {
			  pageContext.writeDiagnostics(callingObject,
                                       "XXOD: Step 20.10.16.1 Declined error message**",
                                       1);
		    list.add(new OAException("XXFIN", "XXOD_ARI_PMT_SETUP_ERR"));
		  }
        }
		
		
		/*End - Modified for Defect38030 */
          //added for bug 6137234   // commented for bug 7673372

          /*      list.add(new OAException("AR","ARI_PMT_SEQ_ERROR"));

        if(paymentType.equals("NEW_CC"))
            list.add(new OAException("AR","ARI_PMT_SITE_NUM_ERROR"));
  */
          if (list.size() > 0) {
			   pageContext.writeDiagnostics(callingObject,
                                       "XXOD: Step 20.10.17",
                                       1);
              OAException.raiseBundledOAException(list);
		  }

          pageContext.writeDiagnostics(callingObject,
                                       "XXOD: Step 20.20 - Start rollbackAndDisplayErrorMessage",
                                       1);

      }

  } //class PaymentUtilities


