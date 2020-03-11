// +======================================================================================+
// | Office Depot - Project Simplify                                                      |
// | Providge Consulting                                                                  |
// +======================================================================================+
// |  Class:         XXARInvoiceCopyCO.java                                               |
// |  Description:   This class is the controller for the XXARInvoiceCopy Page Layout     |
// |                                                                                      |
// |  Change Record:                                                                      |
// |  ==========================                                                          |
// |Version   Date          Author             Remarks                                    |
// |=======   ===========   ================   ========================================== |
// |1.0       26-JUN-2007   BLooman            Initial version                            |
// |1.1       22-OCT-2009   BThomas            Updated for R1.2 CR619 for consol bills    |
// |1.3       14-FEB-2017   Madhu Bolli        Defect#40953 - Close all Callablestatements|
// |1.4       13-FEB-2020   M K Pramod Kumar   Modified for NAIT-119893 to send 50 Invoices for Copy
// |                                                                                      |
// +======================================================================================+
package od.oracle.apps.xxfin.ar.irec.invoicecopy.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageCheckBoxBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;

import oracle.apps.fnd.framework.server.OADBTransaction;
import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

import od.oracle.apps.xxfin.ar.irec.invoicecopy.server.InvoiceCopyAMImpl;
import od.oracle.apps.xxfin.ar.irec.invoicecopy.server.CustomerVORowImpl;

import oracle.apps.ar.irec.accountDetails.server.AccountDetailsAMImpl;

import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAMessageComponentLayoutBean;


public class XXARInvoiceCopyCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$ XXARInvoiceCopyCO.java 115.10 2007/07/18 03:00:00 bjl noship ";
  public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion(RCS_ID, "od.oracle.apps.xxfin.ar.irec.invoicecopy.webui");

  public String getTmpTrxList(OADBTransaction txn, String custAccountId) {
	CallableStatement stmt = null;
	String returnVal;
    try {
      // build the pl/sql statement block; this api call reads the global temporary table and generates a comma delimited list of trx numbers in the iRec transaction list (one per record)
      StringBuffer sqlSB = new StringBuffer();
      sqlSB.append("BEGIN ");
      sqlSB.append("  :1 := XX_ARI_INVOICE_COPY_PKG.get_temp_selected_trx_list(:2); ");
      sqlSB.append("END; ");

      stmt = txn.createCallableStatement(sqlSB.toString(),1); // create the callable statement using the pl/sql block

      stmt.registerOutParameter(1, Types.VARCHAR);  // register parameters in statement
      stmt.setString(2, custAccountId);

      stmt.execute(); // execute pl/sql block
	  
      //return stmt.getString(1); // retrieve and return the customer transaction list
	  returnVal = stmt.getString(1);
	  stmt.close();
	  return returnVal;
    }
    catch (SQLException sqlException) {
      throw OAException.wrapperException(sqlException); // if any SQL errors occur, display them to the user
    }
	finally {
		if (stmt != null)
			try {
				stmt.close();
			} catch (Exception e) {
                throw OAException.wrapperException(e);
            }
	}	
  }

  public String getTmpConsBillList(OADBTransaction txn, String custAccountId) {
	 
	String returnVal;
	CallableStatement stmt = null;
    try {
      // build the pl/sql statement block; this api call reads the global temporary table and generates a comma delimited list of trx numbers in the iRec transaction list (one per record)
      StringBuffer sqlSB = new StringBuffer();
      sqlSB.append("BEGIN ");
      sqlSB.append("  :1 := XX_ARI_INVOICE_COPY_PKG.get_temp_selected_conbill_list(:2); ");
      sqlSB.append("END; ");

      stmt = txn.createCallableStatement(sqlSB.toString(),1); // create the callable statement using the pl/sql block

      stmt.registerOutParameter(1, Types.VARCHAR);  // register parameters in statement
      stmt.setString(2, custAccountId);

      stmt.execute(); // execute pl/sql block

      //return stmt.getString(1); // retrieve and return the customer transaction list
	  returnVal = stmt.getString(1);
	  stmt.close();
	  return returnVal;
    }
    catch (SQLException sqlException) {
      throw OAException.wrapperException(sqlException); // if any SQL errors occur, display them to the user
    }
	finally {
		if (stmt != null)
			try {
				stmt.close();
			} catch (Exception e) {
                throw OAException.wrapperException(e);
            }
	}	
  }

  // This returns Y for consolidated bill customers
  public boolean hasConsolidatedBillSetup(OADBTransaction txn, String custAccountId) {
	
	boolean returnVal;
	CallableStatement stmt = null;
    try {
      // build the pl/sql statement block; this api call checks to see if the customer is setup to request emailed/faxed consolidated bills.
      StringBuffer sqlSB = new StringBuffer();
      sqlSB.append("BEGIN ");
      sqlSB.append("  :1 := XX_ARI_INVOICE_COPY_PKG.has_consolidated_bill_setup(:2); ");
      sqlSB.append("END; ");

      stmt = txn.createCallableStatement(sqlSB.toString(),1); // create the callable statement using the pl/sql block

      stmt.registerOutParameter(1, Types.VARCHAR); // register parameters in statement
      stmt.setString(2, custAccountId);

      stmt.execute(); // execute pl/sql block

      //return ((stmt.getString(1).equals("Y")) ? true : false); // retrieve and return boolean representation of Y/N
	  
	  returnVal = ((stmt.getString(1).equals("Y")) ? true : false);
	  stmt.close();
	  return returnVal;
    }
    catch (SQLException sqlException) {
      throw OAException.wrapperException(sqlException); // if any SQL errors occur, display them to the user
    }
	finally {
		if (stmt != null)
			try {
				stmt.close();
			} catch (Exception e) {
                throw OAException.wrapperException(e);
            }
	}	
  }


  public String getUnreprintableTrxs(OADBTransaction txn, String custAccountId, String custTrxList) {
	
	String returnVal;
	CallableStatement stmt = null;
    try {
      // build the pl/sql statement block; this api call returns a list of trxs that have not been printed yet from the list of cust trxs. if empty (""), then no unprinted trxs are included in the list
      StringBuffer sqlSB = new StringBuffer();
      sqlSB.append("BEGIN ");
      sqlSB.append("  :1 := XX_ARI_INVOICE_COPY_PKG.get_unreprintable_trxs(:2,:3); ");
      sqlSB.append("END; ");

      stmt = txn.createCallableStatement(sqlSB.toString(),1); // create the callable statement using the pl/sql block

      stmt.registerOutParameter(1, Types.VARCHAR); // register parameters in statement
      stmt.setString(2, custAccountId);
      stmt.setString(3, custTrxList);

      stmt.execute(); // execute pl/sql block

      // return stmt.getString(1); // retrieve and return boolean representation of Y/N
	  returnVal = stmt.getString(1);
	  stmt.close();
	  return returnVal;	  
    }
    catch (SQLException sqlException) {
      throw OAException.wrapperException(sqlException); // if any SQL errors occur, display them to the user
    }
	finally {
		if (stmt != null)
			try {
				stmt.close();
			} catch (Exception e) {
                throw OAException.wrapperException(e);
            }
	}	
  }

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);

    // declare and initialize variables for expected parameters
    String custAccountId = "";
    String accountNumber = "";
    String customerName = "";
    String custTrxList = "";
    String custConsBillList = "";

    // get the Application Module object
    AccountDetailsAMImpl acctDetailsAM = (AccountDetailsAMImpl)pageContext.getApplicationModule(webBean);
    InvoiceCopyAMImpl appModule = (InvoiceCopyAMImpl)acctDetailsAM.findApplicationModule("InvoiceCopyAMImpl");

    if (appModule == null) appModule = (InvoiceCopyAMImpl)acctDetailsAM.createApplicationModule("InvoiceCopyAMImpl","od.oracle.apps.xxfin.ar.irec.invoicecopy.server.InvoiceCopyAM");

    if (appModule == null) {
      MessageToken tokens[] = { new MessageToken("AM_DEF_NAME", "InvoiceCopyAMImpl") };
      throw new OAException("XXFIN", "XX_ARI_0001_APP_MOD_NOT_FOUND", tokens);
    }

    // get the Customer Account Id parameter
    if (pageContext.getParameter("custAccountId") != null) {
      custAccountId = pageContext.getDecryptedParameter("custAccountId");

      // initialize the CustomerVO query with this Customer Account Id this executes the customer query to get additional customer information
      appModule.initQuery(custAccountId);

      // get a single row from the CustomerVO - should only have one anyhow
      CustomerVORowImpl row = (CustomerVORowImpl)appModule.getCustomerVO1().first();

      // if a Customer record was not found, raise an error
      if (row == null) {
        MessageToken tokens[] = { new MessageToken("KEY_COND", "custAccountId = " + custAccountId) };
        throw new OAException("XXFIN", "XX_ARI_0002_CUSTOMER_NOT_FOUND", tokens);
      }
      // set additional customer information from CustomerVO object
      accountNumber = row.getAccountNumber();
      customerName = row.getCustomerName();
    }
    // get the Customer Account Number parameter
    else if (pageContext.getParameter("accountNumber") != null) {
      accountNumber = pageContext.getDecryptedParameter("accountNumber");

      // initialize the CustomerVO query with this Customer Account Number.  This executes the customer query to get additional customer information
      appModule.initQueryNumber(accountNumber);

      // get a single row from the CustomerVO - should only have one anyhow
      CustomerVORowImpl row = (CustomerVORowImpl)appModule.getCustomerVO1().first();

      // if a Customer record was not found, raise an error
      if (row == null) {
        MessageToken tokens[] = { new MessageToken("KEY_COND", "accountNumber = " + accountNumber) };
        throw new OAException("XXFIN", "XX_ARI_0002_CUSTOMER_NOT_FOUND", tokens);
      }
      // set additional customer information from CustomerVO object
      custAccountId = row.getCustAccountId().stringValue();
      customerName = row.getCustomerName();
    }
    else {
      MessageToken tokens[] = { new MessageToken("REQUIRED_PARAMETER", "custAccountId") };
      throw new OAException("XXFIN", "XX_ARI_0003_PARAMETER_REQUIRED", tokens);
    }

    // get the Customer Account Id Text Input and populate it based on the parameters
    OAMessageTextInputBean custAcctId = (OAMessageTextInputBean)webBean.findIndexedChildRecursive("CustAccountId");
    if (custAcctId != null) custAcctId.setText(pageContext,custAccountId);

    // get the Customer Account Number Text Input and populate it based on the parameters
    OAMessageTextInputBean custAcctNumBean = (OAMessageTextInputBean)webBean.findIndexedChildRecursive("AccountNumber");
    if (custAcctNumBean != null) custAcctNumBean.setText(pageContext,accountNumber);

    // get the Customer Name Text Input and populate it based on the parameters
    OAMessageTextInputBean custNameBean = (OAMessageTextInputBean)webBean.findIndexedChildRecursive("CustomerName");
    if (custNameBean != null) custNameBean.setText(pageContext,customerName);

    boolean bConsolidatedBillCustomer = hasConsolidatedBillSetup(acctDetailsAM.getOADBTransaction(),custAccountId);
    // throw new OAException("XXFIN", "XX_ARI_0012_CUST_NOT_SETUP"); // No longer throwing exceptions for consolidated bill customers as of R1.2 CR619

    // get the Customer Transaction List parameter
    if (pageContext.getParameter("custTrxList") != null) {
      custTrxList = pageContext.getDecryptedParameter("custTrxList");

      // get the Customer Transaction List Text Input and populate it based on the parameters
      OAMessageTextInputBean invoiceNumbersBean = (OAMessageTextInputBean)webBean.findIndexedChildRecursive("InvoiceNumber");
      if (invoiceNumbersBean != null) invoiceNumbersBean.setText(pageContext,custTrxList);
    }
    // get the Customer Transaction List from the standard iReceivables global temporary table that represents the "Transaction List" in Account Details
    else {
      // fetch a comma delimited list of transaction numbers from the global temporary table
      custTrxList = getTmpTrxList(acctDetailsAM.getOADBTransaction(),custAccountId);

      // if no customer transactions were defined, then raise an error
      if (custTrxList == null || custTrxList.equals("") ) {
        MessageToken tokens[] = { new MessageToken("TABLE_NAME", "the iReceivables User Transaction List") };
       throw new OAException("XXFIN", "XX_ARI_0004_NO_DATA_FOUND", tokens); // No records could be found in the iReceivables User Transaction List.
      }

      // get the Customer Transaction List Text Input and populate it based on the parameters
      OAMessageTextInputBean invoiceNumbersBean = (OAMessageTextInputBean)webBean.findIndexedChildRecursive("InvoiceNumber");
      if (invoiceNumbersBean != null) invoiceNumbersBean.setText(pageContext,custTrxList);
    }

    if (bConsolidatedBillCustomer && custTrxList!=null && !custTrxList.equals("")) {
      // get the Customer Transaction List from the standard iReceivables global temporary table that represents the "Transaction List" in Account Details
      // fetch a comma delimited list of distinct consolidated bill from the global temporary table
      custConsBillList = getTmpConsBillList(acctDetailsAM.getOADBTransaction(),custAccountId);

      // show the Customer Consolidated Bill Numbers;
      if (custConsBillList != null && !custConsBillList.equals("")) {
        OAHeaderBean consBillHeader = (OAHeaderBean)webBean.findIndexedChildRecursive("ConsBillHeader");
        if (consBillHeader!=null) consBillHeader.setRendered(true);
        OAMessageComponentLayoutBean consBillRN = (OAMessageComponentLayoutBean)webBean.findIndexedChildRecursive("ConsBillRN");
        if (consBillRN!=null) consBillRN.setRendered(true);
        OAMessageTextInputBean consBillNumbersBean = (OAMessageTextInputBean)webBean.findIndexedChildRecursive("ConsBillNumber");
        if (consBillNumbersBean!=null) consBillNumbersBean.setText(pageContext,custConsBillList);

        String[] trxArray = custConsBillList.split(",");
        //if (trxArray.length > 10) throw new OAException("XXFIN", "XX_ARI_0013_TRX_LIST_SIZE"); // The consolidated bill list contains more than 10.--Commented for V1.3
		if (trxArray.length > 50) throw new OAException("XXFIN", "XX_ARI_0013_001_TRX_LIST_SIZE"); // Added for V1.4 NAIT-119893
      }
    }


//  MessageToken tokens[] = { new MessageToken("CUSTOMER_NAME", customerName ), new MessageToken("TRX_NUMBER_LIST", custTrxList ) };
    MessageToken tokens[] = { new MessageToken("CUSTOMER_NAME", customerName ), new MessageToken("TRX_NUMBER_LIST", "" ) };
    String headerTitle = pageContext.getApplicationModule(webBean).getOADBTransaction().getMessage("XXFIN","XX_ARI_0011_PAGE_LAYOUT_TITLE",tokens);
    ((OAPageLayoutBean)webBean).setTitle(headerTitle); // Invoice Copy: &CUSTOMER_NAME: &TRX_NUMBER_LIST

    if ((!bConsolidatedBillCustomer || custConsBillList==null || custConsBillList.equals("")) && custTrxList!=null && !(custTrxList.equals(""))) {

      String[] trxArray = custTrxList.split(",");
     // if (trxArray.length > 10) throw new OAException("XXFIN", "XX_ARI_0013_TRX_LIST_SIZE"); // The transaction list contains more than 10 invoices.--Commented for V1.3
	  if (trxArray.length > 50) throw new OAException("XXFIN", "XX_ARI_0013_001_TRX_LIST_SIZE");// Added for V1.4 NAIT-119893

      String unreprintedTrxList = getUnreprintableTrxs(acctDetailsAM.getOADBTransaction(), custAccountId, custTrxList);
      if ( unreprintedTrxList != null && unreprintedTrxList.length() > 0 ) throw new OAException("XXFIN", "XX_ARI_0014_CONVERTED_TRXS"); // There is at least one unreprintable trx in the customer trx list.
    }
  }


  /**
   * Procedure to handle form submissions for form elements in a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormRequest(pageContext, webBean);

    // get the Application Module object
    AccountDetailsAMImpl acctDetailsAM = (AccountDetailsAMImpl)pageContext.getApplicationModule(webBean);
    InvoiceCopyAMImpl appModule = (InvoiceCopyAMImpl)acctDetailsAM.findApplicationModule("InvoiceCopyAMImpl");

    if (appModule == null) appModule = (InvoiceCopyAMImpl)acctDetailsAM.createApplicationModule("InvoiceCopyAMImpl","od.oracle.apps.xxfin.ar.irec.invoicecopy.server.InvoiceCopyAM");

    if (appModule == null) {
      MessageToken tokens[] = { new MessageToken("AM_DEF_NAME", "InvoiceCopyAMImpl") };
      throw new OAException("XXFIN", "XX_ARI_0001_APP_MOD_NOT_FOUND", tokens);
    }

    // if user has submitted the send copy request
    if (pageContext.getParameter("SubmitButton") != null) {
      String custAccountId = "";
      String custTrxList = "";
      String emailFlag = "N";
      String emailAddress = "";
      String faxFlag = "N";
      String faxNumber = "";
      String consBillsFlag = "N";
      String custConsBillList = "";

      // get the Customer Account Id from the Text Input field
      OAMessageTextInputBean custAcctIdBean = (OAMessageTextInputBean)webBean.findIndexedChildRecursive("CustAccountId");
      if (custAcctIdBean != null && custAcctIdBean.getText(pageContext) != null) custAccountId = custAcctIdBean.getText(pageContext);

//      if (hasConsolidatedBillSetup(acctDetailsAM.getOADBTransaction(),custAccountId))
//        throw new OAException("XXFIN", "XX_ARI_0012_CUST_NOT_SETUP"); // This is a consolidated bill customer, not individual invoice (no longer an exception as of R1.2 CR619)

      // do they want consolidated bills?
      OAMessageCheckBoxBean consBillsFlagBean = (OAMessageCheckBoxBean)webBean.findIndexedChildRecursive("SendConsBillsCheckBox");
      if (consBillsFlagBean != null && consBillsFlagBean.getValue(pageContext) != null) consBillsFlag = (String)consBillsFlagBean.getValue(pageContext);

      if (consBillsFlag.equals("Y")) {
        // get the Consolidated Bills List from the Text Input field
        OAMessageTextInputBean custConsBillListBean = (OAMessageTextInputBean)webBean.findIndexedChildRecursive("ConsBillNumber");
        if (custConsBillListBean != null && custConsBillListBean.getText(pageContext) != null) custConsBillList = custConsBillListBean.getText(pageContext);

        String[] trxArray = custConsBillList.split(",");
       // if (trxArray.length > 10) throw new OAException("XXFIN", "XX_ARI_0013_TRX_LIST_SIZE"); // The transaction list contains more than 10 invoices.--Commented for V1.3
		if (trxArray.length > 50) throw new OAException("XXFIN", "XX_ARI_0013_001_TRX_LIST_SIZE");// Added for V1.4 NAIT-119893
      }
      else {
        // get the Customer Transaction List from the Text Input field
        OAMessageTextInputBean custTrxListBean = (OAMessageTextInputBean)webBean.findIndexedChildRecursive("InvoiceNumber");
        if (custTrxListBean != null && custTrxListBean.getText(pageContext) != null) custTrxList = custTrxListBean.getText(pageContext);

        String[] trxArray = custTrxList.split(",");
        //if (trxArray.length > 10) throw new OAException("XXFIN", "XX_ARI_0013_TRX_LIST_SIZE"); // The transaction list contains more than 10 invoices.--Commented for V1.3
		if (trxArray.length > 50) throw new OAException("XXFIN", "XX_ARI_0013_001_TRX_LIST_SIZE");// Added for V1.4 NAIT-119893

        String unreprintedTrxList = getUnreprintableTrxs(acctDetailsAM.getOADBTransaction(), custAccountId, custTrxList);
        if ( unreprintedTrxList != null && unreprintedTrxList.length() > 0 ) throw new OAException("XXFIN", "XX_ARI_0014_CONVERTED_TRXS"); // There is at least one unreprintable trx in the customer trx list.
      }

      // get the Email Flag from the Checkbox field
      OAMessageCheckBoxBean emailFlagBean = (OAMessageCheckBoxBean)webBean.findIndexedChildRecursive("EmailCheckbox");
      if (emailFlagBean != null && emailFlagBean.getValue(pageContext) != null) emailFlag = (String)emailFlagBean.getValue(pageContext);

      // get the Email Address from the Text Input field
      OAMessageTextInputBean emailAddressBean = (OAMessageTextInputBean)webBean.findIndexedChildRecursive("EmailAddress");
      if (emailAddressBean != null && emailAddressBean.getText(pageContext) != null) emailAddress = emailAddressBean.getText(pageContext);

      // get the Fax Flag from the Checkbox field
      OAMessageCheckBoxBean faxFlagBean = (OAMessageCheckBoxBean)webBean.findIndexedChildRecursive("FaxCheckbox");
      if (faxFlagBean != null && faxFlagBean.getValue(pageContext) != null) faxFlag = (String)faxFlagBean.getValue(pageContext);

      // get the Fax Number from the Text Input field
      OAMessageTextInputBean faxNumberBean = (OAMessageTextInputBean)webBean.findIndexedChildRecursive("FaxNumber");
      if (faxNumberBean != null && faxNumberBean.getText(pageContext) != null) faxNumber = faxNumberBean.getText(pageContext);

      // raise error if user did not choose a delivery method
      if ((!(emailFlag.equals("Y"))) && (!(faxFlag.equals("Y")))) throw new OAException("XXFIN", "XX_ARI_0005_NO_DELIVERY_MTHD");

      // raise error if user chose the email delivery method, but did not provide an email address
      if (emailFlag.equals("Y") && emailAddress.length() < 3) throw new OAException("XXFIN", "XX_ARI_0006_EMAIL_NOT_DEFINED");

      // raise error if user entered an email address, but did not choose the email delivery method
      if ((!(emailFlag.equals("Y"))) && emailAddress.length() > 0) throw new OAException("XXFIN", "XX_ARI_0007_EMAIL_NOT_CHECKED");

      // raise error if user chose the fax delivery method, but did not provide a valid fax number.  The matches function uses the standard regular expression for US fax numbers
      if (faxFlag.equals("Y") && faxNumber.matches("^(?!\\d[1]{2}|[5]{3})([2-9]\\d{2})([. -]*)\\d{4}$"))
        throw new OAException("XXFIN", "XX_ARI_0008_FAX_NUMBER_FORMAT"); // Please provide the fax number in the format 999-999-9999.

      // raise error if user entered an fax number, but did not choose the fax delivery method
      if ((!(faxFlag.equals("Y"))) && faxNumber.length() > 0) throw new OAException("XXFIN", "XX_ARI_0009_FAX_NOT_CHECKED"); // Please check the fax checkbox to send to this fax number.

      // submit the XDO Request (creates the invoice document and delivers it). Remove the special characters in the fax number; any special fax number prefix will be added by the XDO Request API (i.e. 9,1,...)
      String requestId = appModule.submitXdoRequest( custAccountId, custTrxList, custConsBillList, emailFlag, emailAddress, faxFlag, faxNumber.replaceAll("[-\\(\\) ]","") );

      // after submitting the XDO Request, redirect the user to the Confirmation page
      pageContext.setForwardURL( "OA.jsp?page=/od/oracle/apps/xxfin/ar/irec/invoicecopy/webui/XXARConfirmRequest&requestId=" + requestId, null, OAWebBeanConstants.KEEP_MENU_CONTEXT, null, null, true, OAWebBeanConstants.ADD_BREAD_CRUMB_NO, OAWebBeanConstants.IGNORE_MESSAGES );
    }

    // if user has cancelled the send copy request, close the window
    if (pageContext.getParameter("CancelButton") != null)
      pageContext.setForwardURL( "OALogout.jsp?closeWindow=true&menu=Y", null, OAWebBeanConstants.KEEP_MENU_CONTEXT, null, null, true, OAWebBeanConstants.ADD_BREAD_CRUMB_NO, OAWebBeanConstants.IGNORE_MESSAGES );
  }

}
