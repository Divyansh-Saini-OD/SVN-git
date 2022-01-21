package od.oracle.apps.xxfin.ar.irec.accountDetails.pay.webui;

import java.text.DateFormat;
import java.text.SimpleDateFormat;

import java.util.Date;
import java.util.Enumeration;

import oracle.apps.ar.irec.accountDetails.pay.server.BankAccountsVOImpl;
import oracle.apps.ar.irec.accountDetails.pay.server.BankAccountsVORowImpl;
import oracle.apps.ar.irec.accountDetails.pay.server.MultipleInvoicesPayListSummaryVOImpl;
import oracle.apps.ar.irec.accountDetails.pay.server.MultipleInvoicesPayListSummaryVORowImpl;
import oracle.apps.ar.irec.accountDetails.pay.server.MultipleInvoicesPayListVOImpl;
import oracle.apps.ar.irec.accountDetails.pay.server.MultipleInvoicesPayListVORowImpl;
import oracle.apps.ar.irec.accountDetails.pay.server.NewBankAccountVOImpl;
import oracle.apps.ar.irec.accountDetails.pay.server.NewBankAccountVORowImpl;
import oracle.apps.ar.irec.accountDetails.pay.server.PaymentAMImpl;
import oracle.apps.ar.irec.accountDetails.pay.server.PaymentTypesVOImpl;
import oracle.apps.ar.irec.accountDetails.pay.server.PaymentTypesVORowImpl;
import oracle.apps.ar.irec.accountDetails.pay.utilities.PaymentUtilities;
import oracle.apps.ar.irec.accountDetails.pay.webui.PaymentFormCO;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanFactory;
import oracle.apps.fnd.framework.webui.beans.OABodyBean;
import oracle.apps.fnd.framework.webui.beans.OARawTextBean;
import oracle.apps.fnd.framework.webui.beans.OAScriptBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAFlowLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;

import oracle.apps.fnd.framework.webui.beans.layout.OAMessageComponentLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAStackLayoutBean;


import oracle.jbo.RowSetIterator;

import oracle.jdbc.OracleCallableStatement;

import oracle.apps.po.common.webui.ClientUtil;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.nav.OAButtonBean;

import oracle.cabo.style.CSSStyle;
/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |                       Oracle WIPRO Consulting Organization                |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODPaymentFormCO.java                                          |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    This java file fis extended from PaymentFormCO for the CR2462           |
 |                                                                           |
 |  RICE  CR868                                                              |
 |Change Record:                                                             |
 |===============                                                            |
 | Date         Author              Remarks                                  |
 | ==========   =============       =======================                  |
 | 12-Nov-2007  MadanKumar J        Initial Draft                            |
 |                                                                           |
 | 19-Dec-2007  Madankumar J        Updated to get the validation response   |
 |                                  for collector/responsibility validation  |
 | 23-Oct-2012  Suraj               Added the condition to catch error after |
 |                                  calling BPEL Service.                    |
 | 18-Dec-2012  Suraj               V4.0 Defect# 21172                       |
 | 13-Feb-2013  Suraj               Account Number for New Bank Account      |
 |                                  should be atleast 4 digit.               |
 | 17-Aug-2013  Sridevi K           For R12 upgrade retrofit                 |
 |                                  added diagnostics debug messages         |
 |                                  Added exception handling logic           |
 | 3-Oct-2013  Sridevi K            For Defect 25677                         |
 | 3-Jan-2013  Sridevi K            For Defect 27242                         |
 | 27-Mar-2015  Sridevi K            E0255 CR1120 CDH Additional Attributes  |
 |                                  for Echeck Defect 33515                  |
 | 22-Apr-2015  Sridevi K           E1356 Defect1080                         |
 | 10-May-2015  Sridevi K           E1356 Added for Email validation         |
 |                                  for prev saved bank account              |
 | 01-Jul-2013  Shaik Ghouse         For Defect 33771                        |
 | 26-Aug-2016  Sridevi K           updated for Vantiv                       |
 | 24-Jan-2017  Sreedhar Mohan      Comment the code, which hides the CC regions for Vantiv|
 | 17-FEB-2017  Madhu Bolli			Thread Leak 12.2.5 Upgrade - close all statements, resultsets |
 | 28-Aug-2017  Madhu Bolli         payframe-client.min.js taking directly from vantiv site |
 +============================================================================+*/

//import oracle.apps.ar.irec.accountDetails.pay.server.*;


public class ODPaymentFormCO extends PaymentFormCO {

    public void processRequest(OAPageContext oapagecontext, 
                               OAWebBean oawebbean) {


        String s = null;
        String errormessage = null;

        s = "Step 10.10";
        oapagecontext.writeDiagnostics(this, 
                                       "XXOD: start processrequest oracle.apps.ar.irec.accountDetails.pay.webui.ODPaymentFormCO", 
                                       1);
									   
									   
        initializeAchCCAttribs(oapagecontext, 
                               oapagecontext.getRootApplicationModule());

        oapagecontext.putSessionValue("applyClicked", 
                                      "N"); //33771 //flag initiated to N

        // Start V4.0
        OAWebBean body = oapagecontext.getRootWebBean();


        if (body instanceof OABodyBean) {
            ((OABodyBean)body).setBlockOnEverySubmit(true);
        }


        OAScriptBean scriptBean = null;
        String str = null;
        final OAWebBeanFactory fac = oapagecontext.getWebBeanFactory();
               
        scriptBean = 
                (OAScriptBean)fac.createWebBean(oapagecontext, SCRIPT_BEAN);
        scriptBean.setSource(oapagecontext.getAppsHtmlDirectory() + 
                             "jquery.min.js");
        oawebbean.addIndexedChild(scriptBean);



      
      scriptBean = (OAScriptBean)fac.createWebBean(oapagecontext, SCRIPT_BEAN);
      scriptBean.setSource(oapagecontext.getAppsHtmlDirectory() + "jquery.xml2json.js");
      oawebbean.addIndexedChild(scriptBean);
      
      DateFormat dateFormat = new SimpleDateFormat("yyyyMMdd");
      Date date = new Date();
      String todaysDateFormat = dateFormat.format(date);
      
      String vantivPayFrameURL = oapagecontext.getProfile("XX_OD_IREC_PAYPAGE_URL");
      
      scriptBean = (OAScriptBean)fac.createWebBean(oapagecontext, SCRIPT_BEAN);
      scriptBean.setSource(vantivPayFrameURL+"?d="+todaysDateFormat);
      oawebbean.addIndexedChild(scriptBean);        


        String strPrevSavedEmailAddress = "";
        strPrevSavedEmailAddress = 
                (String)oapagecontext.getParameter("OD_CustomEmailAddress");
        oapagecontext.writeDiagnostics(this, 
                                       "##### ODPaymentFormCO PFR CustomEmailAddress=" + 
                                       strPrevSavedEmailAddress, 1);

        //if (strPrevSavedEmailAddress != null && !"".equals(strPrevSavedEmailAddress))
        //   oapagecontext.putSessionValue("PREV_SAVED_CUSTOM_EMAIL_ADDRESS", strPrevSavedEmailAddress);

        // End V4.0
        s = "Step 10.20";
        String lc_bepValue = 
            (String)oapagecontext.getSessionValue("x_bep_value");
        oapagecontext.writeDiagnostics(this, "XXOD: lc_bepValue" + lc_bepValue, 
                                       1);
        s = "Step 10.30";
		OracleCallableStatement oraclecallablestatement1 = null;
        try //Included for the CR2462 by Madankumar J,Wipro Technologies.                
        {
            String username = oapagecontext.getUserName();
            OAApplicationModuleImpl oaapplicationmoduleimpl2 = 
                (OAApplicationModuleImpl)oapagecontext.getRootApplicationModule();
            OAApplicationModuleImpl oaapplicationmoduleimpl3 = 
                (OAApplicationModuleImpl)oapagecontext.getApplicationModule(oawebbean);
            OADBTransaction oadbtransaction1 = 
                (OADBTransaction)oaapplicationmoduleimpl2.getDBTransaction();

            s = "Step 10.40";
            String q = 
                "BEGIN XX_AR_IREC_PAYMENTS.VERBAL_AUTH_CODE(p_user_name => :1,x_return_value => :" + 
                "2);END;";
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: calling verbal_auth_code" + 
                                           q, 1);
            s = "Step 10.50";
            oraclecallablestatement1 = 
                (OracleCallableStatement)oadbtransaction1.createCallableStatement(q, 
                                                                                  1);
            oraclecallablestatement1.setString(1, username);
            oraclecallablestatement1.registerOutParameter(2, 12, 0, 6000);
            oraclecallablestatement1.execute();
            s = "Step 10.60";
            String lc_return_value = oraclecallablestatement1.getString(2);
            oapagecontext.putSessionValue("x_render", lc_return_value);
            s = "Step 10.70";
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: verbal_auth_code outparameter" + 
                                           lc_return_value, 1);
        } catch (Exception ex_user_rest) {
            s = "Step 10.80";
            ex_user_rest.printStackTrace();
            throw OAException.wrapperException(ex_user_rest);
        }
		finally {
			try {
				if (oraclecallablestatement1 != null)
					oraclecallablestatement1.close();
			}
			catch(Exception exc) {  }
		}	  		

        s = "Step 10.90";
        if (lc_bepValue != null && "2".equals(lc_bepValue)) {
            s = "Step 10.100";
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: putparameter null for IracctdtlexportINV CM PMT REQ TRX DM DEP AriExportButton", 
                                           1);
            oapagecontext.putParameter("IracctdtlexportINV", null);
            oapagecontext.putParameter("IracctdtlexportCM", null);
            oapagecontext.putParameter("IracctdtlexportPMT", null);
            oapagecontext.putParameter("IracctreqexportREQ", null);
            oapagecontext.putParameter("IracctcombexportTRX", null);
            oapagecontext.putParameter("IracctdtlexportDM", null);
            oapagecontext.putParameter("IracctdtlexportDEP", null);
            oapagecontext.putParameter("AriExportButton", null);
            lc_bepValue = null;
            s = "Step 10.110";
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: calling processFormRequest from processRequest start", 
                                           1);
										   

            processFormRequest(oapagecontext, oawebbean);
            s = "Step 10.120";
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: calling processFormRequest from processRequest end", 
                                           1);
        } else {
            s = "Step 10.130";
			
			oapagecontext.writeDiagnostics(this, 
                                           "XXOD: calling super processRequest", 
                                           1);
										   
            super.processRequest(oapagecontext, oawebbean);
            s = "Step 10.140";
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: calling super processRequest end", 
                                           1);
        }
        s = "Step 10.150";
        oapagecontext.writeDiagnostics(this, 
                                       "XXOD: end processrequest oracle.apps.ar.irec.accountDetails.pay.webui.ODPaymentFormCO", 
                                       1);


    }

    public void processFormRequest(OAPageContext oapagecontext, 
                                   OAWebBean oawebbean) {
        oapagecontext.writeDiagnostics(this, 
                                       "XXOD: **************** processFormRequest", 
                                       1);

        OAPageLayoutBean page = oapagecontext.getPageLayoutBean();
        OAFlowLayoutBean flowBean = 
                (OAFlowLayoutBean)page.findChildRecursive("PaymentRegion");

				
         CSSStyle customCss = new CSSStyle();
        customCss.setProperty("display", "none");

        OAMessageChoiceBean  chBean = 
                (OAMessageChoiceBean)oawebbean.findChildRecursive("NewCreditCardExpMonth");
        if (chBean != null) {
            chBean.setInlineStyle(customCss);
        }

        chBean = 
                (OAMessageChoiceBean)oawebbean.findChildRecursive("NewCreditCardExpYear");
        if (chBean != null) {
            chBean.setInlineStyle(customCss);
        }

       OAMessageTextInputBean  txtBean = 
            (OAMessageTextInputBean)oawebbean.findChildRecursive("NewCreditCardNumber");
        if (txtBean != null) {
            txtBean.setInlineStyle(customCss);
        }


        txtBean = 
                (OAMessageTextInputBean)oawebbean.findChildRecursive("XXOD_PAYCC_MSGS");
        if (txtBean != null) {
            txtBean.setInlineStyle(customCss);
        }

       txtBean = 
                (OAMessageTextInputBean)oawebbean.findChildRecursive("XXODStatus");
        if (txtBean != null) {
            txtBean.setInlineStyle(customCss);
        }


       txtBean = 
                (OAMessageTextInputBean)oawebbean.findChildRecursive("NewCreditCardHolderName");
        if (txtBean != null) {
            txtBean.setInlineStyle(customCss);
        }








        /*   Added the below code as part of patch# 10224271. This code will initialize the session values
		*    before calling the Super method. These session values will used to retain the
		*    Creditcard details in the page once user comes back from OADialogue page.
		*    Please refer the ODAdvPaymentMethodCO.java for the getting these values
		*/

        //33771 added start 
        //if flag = Y ( process error , initial click)
        //throw error
        if (oapagecontext.getParameter("PaymentButton") != null) {

            if (oapagecontext.getSessionValue("applyClicked") != null) {
                if (oapagecontext.getSessionValue("applyClicked").equals("Y")) {
                    throw new OAException("Payment process already initiated, Please wait for completion.", 
                                          OAException.WARNING);
                }
            }
        }


        //33771 added end

        String s = null;
        String errormessage = null;

        s = "Step 20.10";
        oapagecontext.writeDiagnostics(this, 
                                       "XXOD: start oracle.apps.ar.irec.accountDetails.pay.webui.ODPaymentFormCO processFormRequest", 
                                       1);
        PaymentAMImpl am = 
            (PaymentAMImpl)oapagecontext.getApplicationModule(oawebbean);
        s = "Step 20.20";
        if (oapagecontext.getParameter("PaymentButton") != null) {
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: PaymentButton not null", 1);
            s = "Step 20.30";


            validateCC(oapagecontext, oawebbean);

            String lc_CreditCardType = 
                (String)oapagecontext.getParameter("NewCreditCardType");
            String lc_CreditCardHolderName = 
                (String)oapagecontext.getParameter("NewCreditCardHolderName");
            String lc_CreditCardNumber = 
                (String)oapagecontext.getParameter("NewCreditCardNumber");
            String lc_CreditCardExpDate = 
                (String)oapagecontext.getParameter("NewCreditCardExpMonth");
            String lc_CreditCardExpYear = 
                (String)oapagecontext.getParameter("NewCreditCardExpYear");
            s = "Step 20.40";
            if (lc_CreditCardType != null && lc_CreditCardHolderName != null && 
                lc_CreditCardNumber != null && lc_CreditCardExpDate != null && 
                lc_CreditCardExpYear != null) {
                s = "Step 20.50";
                oapagecontext.writeDiagnostics(this, 
                                               "XXOD: inside if lc_CreditCardType != null && lc_CreditCardHolderName != null && lc_CreditCardNumber != null && lc_CreditCardExpDate != null && lc_CreditCardExpYear != null", 
                                               1);

                oapagecontext.putSessionValue("xx_CreditCardType", 
                                              lc_CreditCardType);
                oapagecontext.putSessionValue("xx_CreditCardHolderName", 
                                              lc_CreditCardHolderName);
                oapagecontext.putSessionValue("xx_CreditCardNumber", 
                                              lc_CreditCardNumber);
                oapagecontext.putSessionValue("xx_CreditCardExpDate", 
                                              lc_CreditCardExpDate);
                oapagecontext.putSessionValue("xx_CreditCardExpYear", 
                                              lc_CreditCardExpYear);
											  
											  
                				  
											  
                s = "Step 20.60";
            }
        }
        s = "Step 20.70";
        oapagecontext.writeDiagnostics(this, 
                                       "XXOD: ##### In ODPaymentFormCO PFR payment Button=" + 
                                       oapagecontext.getParameter("PaymentButton"), 
                                       1);
        oapagecontext.writeDiagnostics(this, 
                                       "XXOD: ##### ODPaymentFormCO PFR EVENT=" + 
                                       oapagecontext.getParameter("event"), 1);
        if ("update".equals(oapagecontext.getParameter("event"))) {
            s = "Step 20.80";
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: ##### ODPaymentFormCO PFR EVENT = update ", 
                                           1);
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: ##### In PFR ODPaymentFormCO", 
                                           1);
            OAMessageTextInputBean customAcctName = 
                (OAMessageTextInputBean)oawebbean.findChildRecursive("OD_Bank_Account_Name");
            s = "Step 20.90";
            if (customAcctName != null) {
                oapagecontext.writeDiagnostics(this, 
                                               "XXOD: ##### In PR ODPaymentFormCO customAcctName.getText(oapagecontext)=" + 
                                               customAcctName.getText(oapagecontext), 
                                               1);
                //            oapagecontext.writeDiagnostics(this, "##### ODPaymentFormCO PFR oapagecontext.getSessionValue(OD_CUST_ACCNT_HOLDER_NAME)=" + oapagecontext.getSessionValue("OD_CUST_ACCNT_HOLDER_NAME"), 1);
                //            if(oapagecontext.getSessionValue("OD_CUST_ACCNT_HOLDER_NAME") != null){
                s = "Step 20.100";
                if ((customAcctName.getText(oapagecontext)) != null && 
                    !"".equals(customAcctName.getText(oapagecontext))) {
                    oapagecontext.writeDiagnostics(this, 
                                                   "XXOD: ##### ODPaymentFormCO PFR in side IFFF ,,,...oapagecontext.getSessionValue(OD_CUST_ACCNT_HOLDER_NAME)=" + 
                                                   oapagecontext.getSessionValue("OD_CUST_ACCNT_HOLDER_NAME"), 
                                                   1);
                    oapagecontext.putSessionValue("OD_CUST_ACCNT_HOLDER_NAME", 
                                                  customAcctName.getText(oapagecontext));
                    customAcctName.setText(oapagecontext.getSessionValue("OD_CUST_ACCNT_HOLDER_NAME").toString());
                    s = "Step 20.110";
                }
            }

            s = "Step 20.120";
            NewBankAccountVOImpl newBankAcctVO = am.getNewBankAccountVO();
            NewBankAccountVORowImpl newBankAcctVORow = 
                (NewBankAccountVORowImpl)newBankAcctVO.first();
            s = "Step 20.130";
            if (newBankAcctVO != null) {
                oapagecontext.writeDiagnostics(this, 
                                               "XXOD: ##### ODPaymentFormCO PFR newBankAcctVO !=null ", 
                                               1);
                //            if(newBankAcctVORow != null)
                //            {
                //              oapagecontext.writeDiagnostics(this, "##### ODPaymentFormCO PFR newBankAcctVORow !=null ", 1);
                //              if(newBankAcctVORow.getRoutingNumber() == null)
                //              {
                //                oapagecontext.writeDiagnostics(this, "##### ODPaymentFormCO PFR newBankAcctVORow.getRoutingNumber() ==null ", 1);
                //                customAcctName.setText(null);
                //                oapagecontext.removeSessionValue("OD_CUST_ACCNT_HOLDER_NAME");
                //              }
                //              oapagecontext.writeDiagnostics(this, "##### ODPaymentFormCO PFR newBankAcctVORow.getRoutingNumber()="+newBankAcctVORow.getRoutingNumber(), 1);
                //            }
                s = "Step 20.140";
            } else {
                oapagecontext.writeDiagnostics(this, 
                                               "XXOD: ##### ODPaymentFormCO PFR newBankAcctVO ==null ", 
                                               1);
                customAcctName.setText(null);
                oapagecontext.removeSessionValue("OD_CUST_ACCNT_HOLDER_NAME");
                s = "Step 20.150";
            }
            s = "Step 20.160";
        }
        oapagecontext.writeDiagnostics(this, "XXOD: newBankAcctVO done ", 1);
        s = "Step 20.170";
        if ("paymentMethodSelected".equals(oapagecontext.getParameter("event"))) {

            s = "Step 20.180";
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: ##### ODPaymentFormCO PFR EVENT = paymentMethodSelected ", 
                                           1);

       OAScriptBean scriptBean = null;
        String str = null;
        final OAWebBeanFactory fac = oapagecontext.getWebBeanFactory();
               
        scriptBean = 
                (OAScriptBean)fac.createWebBean(oapagecontext, SCRIPT_BEAN);
        scriptBean.setSource(oapagecontext.getAppsHtmlDirectory() + 
                             "jquery.min.js");
        oawebbean.addIndexedChild(scriptBean);

        scriptBean = (OAScriptBean)fac.createWebBean(oapagecontext, SCRIPT_BEAN);
        scriptBean.setSource(oapagecontext.getAppsHtmlDirectory() + "jquery.xml2json.js");
        oawebbean.addIndexedChild(scriptBean);
        
          DateFormat dateFormat = new SimpleDateFormat("yyyyMMdd");
          Date date = new Date();
          String todaysDateFormat = dateFormat.format(date);
          
          String vantivPayFrameURL = oapagecontext.getProfile("XX_OD_IREC_PAYPAGE_URL");
          
          scriptBean = (OAScriptBean)fac.createWebBean(oapagecontext, SCRIPT_BEAN);
          scriptBean.setSource(vantivPayFrameURL+"?d="+todaysDateFormat);
        
      
        scriptBean = (OAScriptBean)fac.createWebBean(oapagecontext, SCRIPT_BEAN);
        scriptBean.setSource(oapagecontext.getAppsHtmlDirectory() + "payframe-form.js");
        oawebbean.addIndexedChild(scriptBean);

            //Added for CR1120
            //setViewBasingOnACHCC(oapagecontext, oawebbean);
            //End - Added for CR1120

            NewBankAccountVOImpl newBankAcctVO = am.getNewBankAccountVO();
            NewBankAccountVORowImpl newBankAcctVORow = 
                (NewBankAccountVORowImpl)newBankAcctVO.first();
            OAMessageTextInputBean customAcctName = 
                (OAMessageTextInputBean)oawebbean.findChildRecursive("OD_Bank_Account_Name");
            if (newBankAcctVO != null) {
                s = "Step 20.190";
                oapagecontext.writeDiagnostics(this, 
                                               "XXOD: ##### ODPaymentFormCO PFR EVENT = paymentMethodSelected newBankAcctVO !=null ", 
                                               1);
                if (newBankAcctVORow != null) {
                    s = "Step 20.200";
                    oapagecontext.writeDiagnostics(this, 
                                                   "XXOD: ##### ODPaymentFormCO PFR EVENT = paymentMethodSelected newBankAcctVORow !=null ", 
                                                   1);
                    if (newBankAcctVORow.getRoutingNumber() == null) {
                        s = "Step 20.210";
                        oapagecontext.writeDiagnostics(this, 
                                                       "XXOD: ##### ODPaymentFormCO PFR EVENT = paymentMethodSelected newBankAcctVORow.getRoutingNumber() ==null ", 
                                                       1);
                        customAcctName.setText(null);
                        oapagecontext.removeSessionValue("OD_CUST_ACCNT_HOLDER_NAME");
                    }
                    s = "Step 20.220";
                    oapagecontext.writeDiagnostics(this, 
                                                   "XXOD: ##### ODPaymentFormCO PFR EVENT = paymentMethodSelected newBankAcctVORow.getRoutingNumber()=" + 
                                                   newBankAcctVORow.getRoutingNumber(), 
                                                   1);
                }
            } else {
                s = "Step 20.230";
                oapagecontext.writeDiagnostics(this, 
                                               "XXOD: ##### ODPaymentFormCO PFR newBankAcctVO ==null ", 
                                               1);
                customAcctName.setText(null);
                oapagecontext.removeSessionValue("OD_CUST_ACCNT_HOLDER_NAME");
            }
        }

        s = "Step 20.240";
        OAPageLayoutBean oapagelayoutbean = oapagecontext.getPageLayoutBean();
        OAMessageChoiceBean payTypeBean = 
            (OAMessageChoiceBean)oapagelayoutbean.findChildRecursive("PaymentType");
        /* Commented for Testing */
        if (oapagecontext.getParameter("PaymentButton") != null) {
            s = "Step 20.250";
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: ##### In ODPaymentFormCO PFR clicked on PaymentButton", 
                                           1);


            if (oapagecontext.getParameter("AccountNumber") != null && 
                !"".equals(oapagecontext.getParameter("AccountNumber"))) {
                s = "Step 20.260";
                String acdtNumber = 
                    oapagecontext.getParameter("AccountNumber").toString();
                oapagecontext.writeDiagnostics(this, 
                                               "XXOD: ##### In ODPaymentFormCO PFR acdtNumber=" + 
                                               acdtNumber, 1);
                if (acdtNumber.length() < 4)
                    throw new OAException("XXFIN", 
                                          "OD_IREC_ACCT_NUMBER_DIGIT_FOUR", 
                                          null, OAException.ERROR, null);
            }


            /**Added for CR1120**/
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: When Apply clicked..Checking for Account number and Re Enter Account Number", 
                                           1);

            OAWebBean rootWebBean = (OAWebBean)oapagecontext.getRootWebBean();
            OAMessageTextInputBean customReenterAcctNo = 
                (OAMessageTextInputBean)oawebbean.findChildRecursive("OD_Reenter_Acct_Number");
            String acdtNumber1 = null;
            String reacctNumber = null;
            if (customReenterAcctNo != null) {
                oapagecontext.writeDiagnostics(this, 
                                               "XXOD: customReenterAcctNo != null", 
                                               1);


                if (oapagecontext.getParameter("OD_Reenter_Acct_Number") != 
                    null && 
                    oapagecontext.getParameter("AccountNumber") != null) {

                    oapagecontext.writeDiagnostics(this, 
                                                   "XXOD: OD_Reenter_Acct_Number and AccountNumber not null", 
                                                   1);


                    reacctNumber = 
                            oapagecontext.getParameter("OD_Reenter_Acct_Number").toString();
                    acdtNumber1 = 
                            oapagecontext.getParameter("AccountNumber").toString();

                    oapagecontext.writeDiagnostics(this, 
                                                   "XXOD: reacctNumber:" + 
                                                   reacctNumber, 1);
                    oapagecontext.writeDiagnostics(this, 
                                                   "XXOD: acdtNumber1:" + acdtNumber1, 
                                                   1);

                    if (!(acdtNumber1.equals(reacctNumber)))
                        throw new OAException("XXFIN", 
                                              "OD_IREC_ACCT_NUM_REACCT_NUM", 
                                              null, OAException.ERROR, null);
                }
            }


            String email = null;
            String confirmemail = null;
            OAMessageTextInputBean customEmail = 
                (OAMessageTextInputBean)oawebbean.findChildRecursive("txtOdEmailAddress");

            /* Start - Validate Email Address - New bank Account */

            if (oapagecontext.getParameter("txtOdEmailAddress") != null) {
                ODPaymentHelper payHelper = new ODPaymentHelper();


                Boolean bValidEmailFlag = 
                    payHelper.isEmailValid(oapagecontext.getParameter("txtOdEmailAddress").toString());
                oapagecontext.writeDiagnostics(this, 
                                               "txtOdEmailAddress:" + oapagecontext.getParameter("txtOdEmailAddress").toString() + 
                                               bValidEmailFlag.toString(), 1);

                if (!(bValidEmailFlag))
                    throw new OAException("Please enter a valid Email Address ", 
                                          OAException.ERROR);
            }

            /* End- Validate Email Address - New bank Account */


            OAMessageTextInputBean customConfirmEmail = 
                (OAMessageTextInputBean)oawebbean.findChildRecursive("txtOdConfirmEmailAddress");

            if (customConfirmEmail != null) {

                oapagecontext.writeDiagnostics(this, 
                                               "XXOD: customConfirmEmail != null", 
                                               1);


                if (oapagecontext.getParameter("txtOdConfirmEmailAddress") != 
                    null && 
                    oapagecontext.getParameter("txtOdEmailAddress") != null) {

                    oapagecontext.writeDiagnostics(this, 
                                                   "XXOD: txtOdConfirmEmailAddress and txtOdEmailAddress not null", 
                                                   1);

                    confirmemail = 
                            oapagecontext.getParameter("txtOdConfirmEmailAddress").toString();
                    email = 
                            oapagecontext.getParameter("txtOdEmailAddress").toString();

                    oapagecontext.writeDiagnostics(this, 
                                                   "XXOD: confirmemail:" + 
                                                   confirmemail, 1);
                    oapagecontext.writeDiagnostics(this, "XXOD:email:" + email, 
                                                   1);


                    if (!(email.equals(confirmemail)))
                        throw new OAException("XXFIN", 
                                              "OD_IREC_EMAIL_CONFIRMEMAIL", 
                                              null, OAException.ERROR, null);
                    else {
                        oapagecontext.putSessionValue("OD_CONFIRMEMAIL", 
                                                      confirmemail);
                        oapagecontext.writeDiagnostics(this, 
                                                       "XXOD: after putting confirmemail in session", 
                                                       1);
                    }

                }
            }
            /**End-Add**/

            s = "Step 20.270";
            NewBankAccountVOImpl newBankAcctVO = am.getNewBankAccountVO();
            NewBankAccountVORowImpl newBankAcctVORow = 
                (NewBankAccountVORowImpl)newBankAcctVO.first();
            MultipleInvoicesPayListSummaryVOImpl mulInvSummVO = 
                am.getMultipleInvoicesPayListSummaryVO();
            MultipleInvoicesPayListSummaryVORowImpl mulInvSummVOrow = 
                (MultipleInvoicesPayListSummaryVORowImpl)mulInvSummVO.first();
            MultipleInvoicesPayListVOImpl mulInPayListVO = 
                am.getMultipleInvoicesPayListVO();
            MultipleInvoicesPayListVORowImpl mulInPayListVORow = 
                (MultipleInvoicesPayListVORowImpl)mulInPayListVO.first();
            BankAccountsVOImpl bankAcctVO = am.getBankAccountsVO();
            String bankAccountId = bankAcctVO.getSelectedBankAccount();
            BankAccountsVORowImpl bankAcctVORow = 
                (BankAccountsVORowImpl)bankAcctVO.getCurrentRow();
            s = "Step 20.280";
            if (bankAcctVORow != null)
                oapagecontext.writeDiagnostics(this, 
                                               "XXOD: ##### In ODPaymentFormCO PFR getBankAccountType=" + 
                                               bankAcctVORow.getAccountType(), 
                                               1);
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: ##### In ODPaymentFormCO PFR getRoutingNumber=" + 
                                           newBankAcctVORow.getRoutingNumber(), 
                                           1);
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: ##### In ODPaymentFormCO PFR getBankAccountNumber=" + 
                                           newBankAcctVORow.getBankAccountNumber(), 
                                           1);
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: ##### In ODPaymentFormCO PFR getAccountHolderName=" + 
                                           newBankAcctVORow.getAccountHolderName(), 
                                           1);
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: ##### In ODPaymentFormCO PFR mulInPayListVORow.getReceiptDate()=" + 
                                           mulInPayListVORow.getReceiptDate(), 
                                           1);
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: ##### In ODPaymentFormCO PFR mulInvSummVOrow.getReceiptDate()=" + 
                                           mulInvSummVOrow.getReceiptDate(), 
                                           1);
            s = "Step 20.290";
            newBankAcctVORow.getBankAccountId();
            s = "Step 20.290.1";
            mulInPayListVORow.getPaymentAmt();
            s = "Step 20.290.2";
            //code to add routing number contatenated with accout number and set to accout holder name to overcome lock box standard process /*Date:03-08-2012. By: Suraj*/
            newBankAcctVORow.setAccountHolderName(newBankAcctVORow.getRoutingNumber() + 
                                                  " " + 
                                                  newBankAcctVORow.getBankAccountNumber());
            s = "Step 20.290.3";
            OAMessageTextInputBean customAcctName = 
                (OAMessageTextInputBean)oawebbean.findChildRecursive("OD_Bank_Account_Name");
            s = "Step 20.290.4";
            //Added if condition Defect 25677
            if (customAcctName != null) {
                s = "Step 20.290.4.1";
                if (customAcctName.getText(oapagecontext) != null && 
                    !"".equals(customAcctName.getText(oapagecontext))) {
                    s = "Step 20.290.4.2";
                    oapagecontext.putParameter("customAcctName", 
                                               customAcctName.getText(oapagecontext));
                    s = "Step 20.290.4.3";
                }
                s = "Step 20.290.4.4";
            }

            s = "Step 20.290.5";
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: ##### In ODPaymentFormCO PFR customAcctName=" + 
                                           oapagecontext.getParameter("customAcctName"), 
                                           1);
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: ##### In ODPaymentFormCO PFR Standard Accout Holder routing+acctNumber=" + 
                                           newBankAcctVORow.getAccountHolderName(), 
                                           1);
            // oapagecontext.writeDiagnostics(this, 
            //                              "XXOD: ##### In ODPaymentFormCO PFR Custom Account Holder NAMe=" + 
            //                                customAcctName.getText(oapagecontext), 
            //                                1);

            // Calling BPEL procedure 
            s = "Step 20.300";
            OracleCallableStatement oraclecallablestatement = null;
            OADBTransaction oadbtransaction = am.getOADBTransaction();
            String confirmationNumber = null;
            PaymentTypesVOImpl payTypeVO = am.getPaymentTypesVO();
            PaymentTypesVORowImpl payTypeVORow = 
                (PaymentTypesVORowImpl)payTypeVO.getCurrentRow();
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: ##### In ODPaymentFormCO PFR payTypeVORow.getLookupCode()=" + 
                                           payTypeVORow.getLookupCode() + 
                                           " meaning=" + 
                                           payTypeVORow.getMeaning(), 1);
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: ##### In ODPaymentFormCO PFR payTypeBean.getSelectionValue(oapagecontext)=" + 
                                           payTypeBean.getSelectionValue(oapagecontext), 
                                           1);
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: ##### In ODPaymentFormCO PFR payTypeBean.getSelectedValue()=" + 
                                           payTypeBean.getSelectedValue(), 1);
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: ##### In ODPaymentFormCO PFR payTypeBean.getSelectedIndex()=" + 
                                           payTypeBean.getSelectedIndex(), 1);
            s = "Step 20.310";
            if ((payTypeBean.getSelectionValue(oapagecontext) != null && 
                 !"NEW_CC".equals(payTypeBean.getSelectionValue(oapagecontext))) && 
                (payTypeBean.getSelectionValue(oapagecontext) != null && 
                 !"EXISTING_CC".equals(payTypeBean.getSelectionValue(oapagecontext)))) {
                //                boolean proceed = true;
                if ("EXISTING_BA".equals(payTypeBean.getSelectionValue(oapagecontext))) {
                    if (bankAcctVORow == null)
                        throw new OAException("Please Select Payment Method as New Credit.", 
                                              OAException.ERROR);
                }

                //Code Added on 26-Jun-2012
                s = "Step 20.320";
                oapagecontext.writeDiagnostics(this, 
                                               "##### Start validatePage", 1);
                s = "Step 20.320.1";
                OADBTransactionImpl oadbtransactionimpl = 
                    (OADBTransactionImpl)am.getDBTransaction();
                String s5 = getActiveCustomerId(oapagecontext);
                String s6 = getActiveCustomerUseId(oapagecontext);
                oapagecontext.putParameter("OrgContextId", 
                                           getActiveOrgId(oapagecontext));
                oapagelayoutbean = oapagecontext.getPageLayoutBean();
                OAFlowLayoutBean oaflowlayoutbean = 
                    (OAFlowLayoutBean)oapagelayoutbean.findChildRecursive("PaymentRegion");
                s = "Step 20.320.2";
                oapagecontext.writeDiagnostics(this, 
                                               "XXOD: validatePage - CustomerId" + 
                                               s5, 1);
                oapagecontext.writeDiagnostics(this, 
                                               "XXOD: validatePage - CustomerUseId" + 
                                               s6, 1);
                oapagecontext.writeDiagnostics(this, 
                                               "XXOD: validatePage - OrgId" + 
                                               getActiveOrgId(oapagecontext), 
                                               1);

                /*s = "Step 20.320.1";
                    String s5 = getActiveCustomerId(oapagecontext);
					s = "Step 20.320.2";
                    String s6 = getActiveCustomerUseId(oapagecontext);
					s = "Step 20.320.3";
                    OADBTransactionImpl oadbtransactionimpl =
                        (OADBTransactionImpl)am.getDBTransaction();
					s = "Step 20.320.4";
                    OAFlowLayoutBean oaflowlayoutbean =
                        (OAFlowLayoutBean)oapagelayoutbean.findChildRecursive("PaymentRegion");
                    */
                try {
                    s = "Step 20.320.5";
                    oapagecontext.writeDiagnostics(this, 
                                                   "applyClicked in before Try intialized vlaue N :  " + 
                                                   oapagecontext.getSessionValue("applyClicked"), 
                                                   1);

                    oapagecontext.putSessionValue("applyClicked", 
                                                  "Y"); //33771 //process initiated , flag =y
                    oapagecontext.writeDiagnostics(this, 
                                                   "applyClicked in Try assigned to Y:  " + 
                                                   oapagecontext.getSessionValue("applyClicked"), 
                                                   1);

                    oapagecontext.writeDiagnostics(this, 
                                                   "IREC PAY Status before PU call:  " + 
                                                   oapagecontext.getSessionValue("XX_AR_IREC_PAY_STATUS"), 
                                                   1);


                    oapagecontext.writeDiagnostics(this, 
                                                   "Web Service Receipt Number before PU call:  " + 
                                                   oapagecontext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER"), 
                                                   1);


                    oapagecontext.writeDiagnostics(this, 
                                                   "PaymentUtilities.validatePage Call Started:  " + 
                                                   oapagecontext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER"), 
                                                   1);

                    PaymentUtilities.validatePage(this, oapagecontext, 
                                                  oaflowlayoutbean, s5, s6);
                    oapagecontext.writeDiagnostics(this, 
                                                   "applyClicked After PU is coming as Y:  " + 
                                                   oapagecontext.getSessionValue("applyClicked"), 
                                                   1);

                    oapagecontext.writeDiagnostics(this, 
                                                   "IREC PAY Status After PU call:  " + 
                                                   oapagecontext.getSessionValue("XX_AR_IREC_PAY_STATUS"), 
                                                   1);


                    oapagecontext.writeDiagnostics(this, 
                                                   "Web Service Receipt Number after PU call:  " + 
                                                   oapagecontext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER"), 
                                                   1);

                    oapagecontext.putSessionValue("applyClicked", 
                                                  "N"); //33771 //process initiated , flag =C

                    oapagecontext.writeDiagnostics(this, 
                                                   "applyClicked After PU call should be N:  " + 
                                                   oapagecontext.getSessionValue("applyClicked"), 
                                                   1);

                    //33771 added start
                    /*    if ("S".equals(oapagecontext.getSessionValue("XX_AR_IREC_PAY_STATUS")) &&
                       oapagecontext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER") !=
                       null &&
                       !"".equals(oapagecontext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER")))
                       {
                       oapagecontext.putSessionValue("applyClicked", "N");
                       }
                       else
                       {
                       oapagecontext.putSessionValue("applyClicked", "N");
                       }
                       */
                    //33771 added end
                    s = "Step 20.320.6";
                } catch (OAException oaexception) {
                    oapagecontext.writeDiagnostics(this, 
                                                   "XXOD: ##### Exception in validatePage", 
                                                   1);
                    oapagecontext.putSessionValue("applyClicked", 
                                                  "N"); //33771 //process errored , flag =N
                    oadbtransactionimpl.putValue("PaymentInProcess", "N");
                    oadbtransactionimpl.putValue("PaymentProcessFailed", "Y");
                    oapagecontext.writeDiagnostics(this, 
                                                   "XXOD: ##### End validatePage" + 
                                                   oaexception, 1);


                    oaexception.setApplicationModule(am);
                    throw oaexception;


                }
                s = "Step 20.320.8";
                oapagecontext.writeDiagnostics(this, 
                                               "XXOD: ##### End validatePage", 
                                               1);
                s = "Step 20.330";

                //Re-design code Start
                s = "Step 20.340";
                if (bankAcctVORow != null) {
                    if (bankAcctVORow.getBankNum() != null && 
                        !"".equals(bankAcctVORow.getBankNum()))
                        oapagecontext.putSessionValue("p_bank_routing_number", 
                                                      bankAcctVORow.getBankNum());
                    //Re-desing code End.
                } else {
                    if (newBankAcctVORow.getRoutingNumber() != null && 
                        !"".equals(newBankAcctVORow.getRoutingNumber()))
                        oapagecontext.putSessionValue("p_bank_routing_number", 
                                                      newBankAcctVORow.getRoutingNumber());
                }
                s = "Step 20.350";
                if (newBankAcctVORow.getBankAccountType() != null && 
                    !"".equals(newBankAcctVORow.getBankAccountType()))
                    oapagecontext.putSessionValue("p_bank_account_type", 
                                                  newBankAcctVORow.getBankAccountType());

                oapagecontext.writeDiagnostics(this, 
                                               "XXOD: ##### Before  EXISTING_BA", 
                                               1);
                s = "Step 20.360";
                if ("EXISTING_BA".equals(payTypeBean.getSelectionValue(oapagecontext))) {
                    s = "Step 20.370";
                    OAViewObject oaviewobject = 
                        (OAViewObject)am.findViewObject("BankAccountsVO");
                    RowSetIterator rowsetiterator = 
                        oaviewobject.createRowSetIterator("iter");
                    rowsetiterator.reset();
                    while (rowsetiterator.hasNext()) {
                        BankAccountsVORowImpl bankaccountsvorowimpl = 
                            (BankAccountsVORowImpl)rowsetiterator.next();
                        String s1 = 
                            bankaccountsvorowimpl.getSelectedAccount() != 
                            null ? bankaccountsvorowimpl.getSelectedAccount() : 
                            "N";
                        if ("Y".equals(s1)) {
                            oapagecontext.writeDiagnostics(this, 
                                                           "XXOD: ##### When  EXISTING_BA CustomAccountType Attribute3 =" + 
                                                           bankaccountsvorowimpl.getAttribute("CustomAccountType"), 
                                                           1);
                            //					  oraclecallablestatement.setString(5,bankaccountsvorowimpl.getAttribute("CustomAccountType").toString());//newBankAcctVORow.getAccountHolderName());

                            if (bankaccountsvorowimpl.getAttribute("CustomAccountType") != 
                                null && 
                                !"".equals(bankaccountsvorowimpl.getAttribute("CustomAccountType")))
                                oapagecontext.putSessionValue("p_bank_account_type", 
                                                              bankaccountsvorowimpl.getAttribute("CustomAccountType").toString());
                            oapagecontext.writeDiagnostics(this, 
                                                           "##### When  EXISTING_BA CustomAccountHolderName=" + 
                                                           bankaccountsvorowimpl.getAttribute("CustomAccountHolderName"), 
                                                           1);
                            //Re-design code Start
                            if (bankaccountsvorowimpl.getAttribute("CustomAccountHolderName") != 
                                null && 
                                !"".equals(bankaccountsvorowimpl.getAttribute("CustomAccountHolderName"))) {
                                oapagecontext.putSessionValue("p_bank_account_name", 
                                                              bankaccountsvorowimpl.getAttribute("CustomAccountHolderName").toString()); //P_attr1
                                oapagecontext.putSessionValue("PREV_SAVED_CUSTOM_ACCT_HOLDER_NAME", 
                                                              bankaccountsvorowimpl.getAttribute("CustomAccountHolderName").toString());
                                //					  oraclecallablestatement.setString(8,bankaccountsvorowimpl.getAttribute("CustomAccountHolderName").toString());//newBankAcctVORow.getAccountHolderName());
                            }
                            //Added for Defect 1080
                            if (bankaccountsvorowimpl.getAttribute("CustomEmailAddress") != 
                                null && 
                                !"".equals(bankaccountsvorowimpl.getAttribute("CustomEmailAddress"))) {

                                oapagecontext.writeDiagnostics(this, 
                                                               "##### When  EXISTING_BA CustomEmailAddress=" + 
                                                               bankaccountsvorowimpl.getAttribute("CustomEmailAddress"), 
                                                               1);
                                oapagecontext.putSessionValue("PREV_SAVED_CUSTOM_EMAIL_ADDRESS", 
                                                              bankaccountsvorowimpl.getAttribute("CustomEmailAddress").toString());
                            }
                            //else {
                            //  oapagecontext.putSessionValue("PREV_SAVED_CUSTOM_EMAIL_ADDRESS", "no.replies@officedepot.com");
                            //}							   
                            String strPrevSavedEmailAddress = "";
                            strPrevSavedEmailAddress = 
                                    (String)oapagecontext.getParameter("OD_CustomEmailAddress");
                            oapagecontext.writeDiagnostics(this, 
                                                           "##### ODPaymentFormCO PFR CustomEmailAddress=" + 
                                                           strPrevSavedEmailAddress, 
                                                           1);

                            oapagecontext.writeDiagnostics(this, 
                                                           "##### ODPaymentFormCO PFR CustomEmailAddress2=" + 
                                                           bankaccountsvorowimpl.getAttribute("CustomEmailAddress"), 
                                                           1);

                            String strPrevSavedBankEmailAddress = "";
                            if (bankaccountsvorowimpl.getAttribute("CustomEmailAddress") != 
                                null) {
                                //10May2015 - Added for Email Validation incase of Prev Saved Bank Account
                                ODPaymentHelper payHelper = 
                                    new ODPaymentHelper();

                                Boolean bValidEmailFlag = 
                                    payHelper.isEmailValid(bankaccountsvorowimpl.getAttribute("CustomEmailAddress").toString());
                                if (bValidEmailFlag) {
                                    strPrevSavedBankEmailAddress = 
                                            bankaccountsvorowimpl.getAttribute("CustomEmailAddress").toString();
                                } else {
                                    throw

                                        new OAException("For the selected Account, please enter a valid Email Address by clicking + Show.", 
                                                        OAException.ERROR);
                                }

                            } else {
                                //throw new OAException("XXFIN", "OD_IREC_EMAIL_REQUIRED", null, OAException.ERROR, null);
                                //"Please Select Payment Method as New Credit.", OAException.ERROR
                                throw

                                    new OAException("For the selected Account, please enter a valid Email Address by clicking + Show.", 
                                                    OAException.ERROR);
                            }

                            if (strPrevSavedEmailAddress != null && 
                                !"".equals(strPrevSavedEmailAddress))
                                oapagecontext.putSessionValue("PREV_SAVED_CUSTOM_EMAIL_ADDRESS", 
                                                              strPrevSavedEmailAddress);

                            if (!"".equals(strPrevSavedEmailAddress)) {
                                oapagecontext.writeDiagnostics(this, 
                                                               "##### ODPaymentFormCO PFR CustomEmailAddress3=" + 
                                                               strPrevSavedBankEmailAddress, 
                                                               1);


                                oapagecontext.putSessionValue("PREV_SAVED_CUSTOM_EMAIL_ADDRESS", 
                                                              strPrevSavedBankEmailAddress);
                            }
                            //End Added for Defect 1080


                            //Re-desing code End.
                        }
                    }
                    rowsetiterator.closeRowSetIterator();
                    //                      oapagecontext.writeDiagnostics(this, "##### When  EXISTING_BA CustomAccountHolderName=" + odBankAcctVORow.getAttribute("CustomAccountHolderName"), 1);
                    //                      oraclecallablestatement.setString(8,odBankAcctVORow.getAttribute("CustomAccountHolderName").toString());//newBankAcctVORow.getAccountHolderName());
                    s = "Step 20.380";
                } else {
                    s = "Step 20.390";
                    //			  oraclecallablestatement.setString(8,customAcctName.getText(oapagecontext));//newBankAcctVORow.getAccountHolderName());
                    oapagecontext.writeDiagnostics(this, 
                                                   "XXOD: ##### For New Bank Accout customAcctName.getText(oapagecontext)=" + 
                                                   customAcctName.getText(oapagecontext), 
                                                   1);
                    //Re-design code Start
                    if (customAcctName.getText(oapagecontext) != null && 
                        !"".equals(customAcctName.getText(oapagecontext)))
                        oapagecontext.putSessionValue("p_bank_account_name", 
                                                      customAcctName.getText(oapagecontext)); //P_attr1
                    //Re-desing code End.
                    s = "Step 20.400";
                }


                s = "Step 20.410";
            }
            oapagecontext.putSessionValue("PAYMENT_METHOD", 
                                          payTypeBean.getSelectionValue(oapagecontext));
            s = "Step 20.420";


        }
        oapagecontext.writeDiagnostics(this, 
                                       "XXOD: ##### In ODPaymentFormCO PFR Bedore super.PFR", 
                                       1);
        super.processFormRequest(oapagecontext, oawebbean);
        s = "Step 20.430";

        oapagecontext.writeDiagnostics(this, 
                                       "XXOD: End processformrequest oracle.apps.ar.irec.accountDetails.pay.webui.ODPaymentFormCO processFormRequest", 
                                       1);

        /*								
			//33771 added start
			if ("S".equals(oapagecontext.getSessionValue("XX_AR_IREC_PAY_STATUS")) &&
			oapagecontext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER") !=
			null &&
			!"".equals(oapagecontext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER")))
			{
			oapagecontext.putSessionValue("applyClicked", "N");
			}
			else
			{
			oapagecontext.putSessionValue("applyClicked", "N");
			}
			//33771 added end
                        */
    }


    public void initializeAchCCAttribs(OAPageContext pageContext, 
                                       OAApplicationModule am) {
        pageContext.writeDiagnostics(this, 
                                     "XXOD: Start initializeAchCCAttribs", 1);
        ODPaymentHelper payHelper;
        OAPageLayoutBean oapagelayoutbean = pageContext.getPageLayoutBean();
        OAHeaderBean header2 = 
            (OAHeaderBean)oapagelayoutbean.findIndexedChildRecursive("CreditCardTypeRegion"); //"oracle.apps.ar.irec.accountDetails.pay.webui.AdvNewCreditCardCO"
        OAHeaderBean header3 = 
            (OAHeaderBean)oapagelayoutbean.findIndexedChildRecursive("CreditCardDetailsRegion");

        String sCustomerId = getActiveCustomerId(pageContext);
        pageContext.writeDiagnostics(this, "XXOD: sCustomerId" + sCustomerId, 
                                     1);
        payHelper = new ODPaymentHelper(sCustomerId);
        pageContext.writeDiagnostics(this, "XXOD: calling get_achccattributes", 
                                     1);

        payHelper.get_achccattributes(pageContext, am);
        //pageContext.putParameter("XXOD_CC_FLAG", payHelper.getCCFlag());
        //pageContext.putParameter("XXOD_ACH_FLAG", payHelper.getACHFlag());
        String sCCFlag = "";
        String sACHFlag = "";

        if (payHelper.getCCFlag() != null)
            sCCFlag = payHelper.getCCFlag();

        if (payHelper.getACHFlag() != null)
            sACHFlag = payHelper.getACHFlag();

        if (sCCFlag != null)
            pageContext.putSessionValue("XXOD_CC_FLAG", sCCFlag);

        if (sACHFlag != null)
            pageContext.putSessionValue("XXOD_ACH_FLAG", sACHFlag);

        pageContext.writeDiagnostics(this, 
                                     "##### In ODPaymentFormCO initializeAchCCAttribs XXOD_CC_FLAG" + 
                                     pageContext.getSessionValue("XXOD_CC_FLAG"), 
                                     1);
        pageContext.writeDiagnostics(this, 
                                     "##### In ODPaymentFormCO initializeAchCCAttribs  XXOD_ACH_FLAG" + 
                                     pageContext.getSessionValue("XXOD_ACH_FLAG"), 
                                     1);
        pageContext.writeDiagnostics(this, "XXOD: End initializeAchCCAttribs", 
                                     1);

    }


    public void setViewBasingOnACHCC(OAPageContext pageContext, 
                                     OAWebBean webBean) {

        pageContext.writeDiagnostics(this, "XXOD: Start setViewBasingOnACHCC", 
                                     1);

        String sCCFlag = (String)pageContext.getSessionValue("XXOD_CC_FLAG");
        String sACHFlag = (String)pageContext.getSessionValue("XXOD_ACH_FLAG");
        String sErrMessage = "XXOD_ACHCC_CONTROL_MSG";
        pageContext.writeDiagnostics(this, "XXOD: XXOD_CC_FLAG" + sCCFlag, 1);
        pageContext.writeDiagnostics(this, "XXOD: XXOD_ACH_FLAG" + sACHFlag, 
                                     1);

        OAPageLayoutBean oapagelayoutbean = pageContext.getPageLayoutBean();

        String strpay = "";
        OAMessageChoiceBean payTypeBean1 = 
            (OAMessageChoiceBean)webBean.findChildRecursive("PaymentType");
        if (payTypeBean1 != null) {
            strpay = payTypeBean1.getSelectionValue(pageContext);
            pageContext.writeDiagnostics(this, 
                                         "XXOD: paytype value : " + strpay, 1);
        }


        String sPayMethod = 
            (String)pageContext.getSessionValue("XXOD_INITIALVALUE_PAYMETHOD");
        if ((strpay != null) && (!sPayMethod.equals(strpay))) {
            pageContext.writeDiagnostics(this, 
                                         "XXOD: sPayMethod : " + sPayMethod, 
                                         1);
            pageContext.putSessionValue("XXOD_INITIALVALUE_PAYMETHOD", 
                                        sPayMethod);

        }

        if (("NEW_BA".equals(strpay)) && ("N".equals(sACHFlag))) {
            //OATableBean tableBean = ((OATableBean)webBean.findIndexedChildRecursive("ResultsTable"));
            //  ClientUtil.setViewOnlyRecursive(pageContext, tableBean);
            OAHeaderBean header1 = 
                (OAHeaderBean)oapagelayoutbean.findIndexedChildRecursive("NewBankAccountRegion");
            ClientUtil.setViewOnlyRecursive(pageContext, header1);

            MessageToken[] tokens = { new MessageToken("NAME", "ACH") };
            OAException msg = 
                new OAException("XXFIN", sErrMessage, tokens, OAException.INFORMATION, 
                                null);
            pageContext.putDialogMessage(msg);


        }

        if (("NEW_CC".equals(strpay)) && ("N".equals(sCCFlag))) {
            //OATableBean tableBean = ((OATableBean)webBean.findIndexedChildRecursive("ResultsTable"));
            //  ClientUtil.setViewOnlyRecursive(pageContext, tableBean);
            OAHeaderBean header2 = 
                (OAHeaderBean)oapagelayoutbean.findIndexedChildRecursive("CreditCardTypeRegion");
            ClientUtil.setViewOnlyRecursive(pageContext, header2);

            OAHeaderBean header3 = 
                (OAHeaderBean)oapagelayoutbean.findIndexedChildRecursive("CreditCardDetailsRegion");
            ClientUtil.setViewOnlyRecursive(pageContext, header3);

            MessageToken[] tokens = 
            { new MessageToken("NAME", "Credit Card") };
            OAException msg = 
                new OAException("XXFIN", sErrMessage, tokens, OAException.INFORMATION, 
                                null);
            pageContext.putDialogMessage(msg);


        }

        if (("EXISTING_BA".equals(strpay)) && ("N".equals(sACHFlag))) {
            //OATableBean tableBean = ((OATableBean)webBean.findIndexedChildRecursive("ResultsTable"));
            //  ClientUtil.setViewOnlyRecursive(pageContext, tableBean);
            OAHeaderBean header1 = 
                (OAHeaderBean)oapagelayoutbean.findIndexedChildRecursive("SavedBankAccountRegion");
            ClientUtil.setViewOnlyRecursive(pageContext, header1);

            MessageToken[] tokens = { new MessageToken("NAME", "ACH") };
            OAException msg = 
                new OAException("XXFIN", sErrMessage, tokens, OAException.INFORMATION, 
                                null);
            pageContext.putDialogMessage(msg);

        }

        pageContext.writeDiagnostics(this, "XXOD: End setViewBasingOnACHCC", 
                                     1);

    }

    public void validateCC(OAPageContext oapagecontext, OAWebBean oawebbean) {

        oapagecontext.writeDiagnostics(this, "XXOD: Start validateCC", 1);

        String sPayStatus = "";
        String sPayType = "";


        if (oapagecontext.getParameter("PaymentButton") != null) {

            OAPageLayoutBean page = oapagecontext.getPageLayoutBean();
            OAFlowLayoutBean flowBean = 
                (OAFlowLayoutBean)page.findChildRecursive("PaymentRegion");


            //Getting payment type
            OAMessageChoiceBean xxodPayType = 
                (OAMessageChoiceBean)flowBean.findChildRecursive("PaymentType");

            if (flowBean.findChildRecursive("PaymentType") == null) {
                oapagecontext.writeDiagnostics(this, 
                                               "XXOD: flowBean PaymentType null", 
                                               1);
            } else {

                if (xxodPayType.getSelectionValue(oapagecontext) != null && 
                    (!"".equals(xxodPayType.getSelectionValue(oapagecontext))))
                    sPayType = xxodPayType.getSelectionValue(oapagecontext);
                else
                    oapagecontext.writeDiagnostics(this, 
                                                   "XXOD: flowBean xxodPayType.getSelectionValue(oapagecontext) value null", 
                                                   1);
            }
            oapagecontext.writeDiagnostics(this, "XXOD: sPayType:" + sPayType, 
                                           1);
            if (("NEW_CC").equals(sPayType)) {
			
			
			   //Setting Session Values
				String lc_CreditCardType = "";
				String lc_CreditCardHolderName = "";
				String  lc_CreditCardExpDate ="";
				String lc_CreditCardExpYear ="";
				
				String lc_CreditCardNumber = "";
				if (((OAMessageChoiceBean)flowBean.findChildRecursive("NewCreditCardType")) != null)
				  lc_CreditCardType = ((OAMessageChoiceBean)flowBean.findChildRecursive("NewCreditCardType")).getText(oapagecontext);
                
                if (((OAMessageTextInputBean)flowBean.findChildRecursive("NewCreditCardHolderName")) != null)
				  lc_CreditCardHolderName = ((OAMessageTextInputBean)flowBean.findChildRecursive("NewCreditCardHolderName")).getText(oapagecontext);
               

			 	if (((OAMessageChoiceBean)flowBean.findChildRecursive("NewCreditCardExpMonth")) != null)
				  lc_CreditCardExpDate = ((OAMessageChoiceBean)flowBean.findChildRecursive("NewCreditCardExpMonth")).getText(oapagecontext);
            

   			    if (((OAMessageChoiceBean)flowBean.findChildRecursive("NewCreditCardExpYear")) != null)
				  lc_CreditCardExpYear = ((OAMessageChoiceBean)flowBean.findChildRecursive("NewCreditCardExpYear")).getText(oapagecontext);
              
			   
			   if (((OAMessageTextInputBean)flowBean.findChildRecursive("NewCreditCardNumber")) != null)
				  lc_CreditCardNumber  = ((OAMessageTextInputBean)flowBean.findChildRecursive("NewCreditCardNumber")).getText(oapagecontext);
               
			 			
				
                 oapagecontext.writeDiagnostics(this, "XXOD: flowBean lc_CreditCardType "+lc_CreditCardType, 
                                               1);
				

                 oapagecontext.writeDiagnostics(this, "XXOD: flowBean lc_CreditCardHolderName "+lc_CreditCardHolderName, 
                                               1);				
				
				oapagecontext.writeDiagnostics(this, "XXOD: flowBean lc_CreditCardExpDate "+lc_CreditCardExpDate, 
                                               1);
				
				oapagecontext.writeDiagnostics(this, "XXOD: flowBean lc_CreditCardExpYear "+lc_CreditCardExpYear, 
                                               1);
											   
				oapagecontext.writeDiagnostics(this, "XXOD: flowBean lc_CreditCardNumber  "+lc_CreditCardNumber , 
                                               1);
				
			 
			    if (lc_CreditCardType != null && lc_CreditCardHolderName != null && 
                   lc_CreditCardNumber != null && lc_CreditCardExpDate != null && 
                   lc_CreditCardExpYear != null) {
       
                   oapagecontext.writeDiagnostics(this, 
                                               "XXOD: inside if lc_CreditCardType != null && lc_CreditCardHolderName != null && lc_CreditCardNumber != null && lc_CreditCardExpDate != null && lc_CreditCardExpYear != null", 
                                               1);

                   oapagecontext.putSessionValue("xx_CreditCardType", 
                                              lc_CreditCardType);
                   oapagecontext.putSessionValue("xx_CreditCardHolderName", 
                                              lc_CreditCardHolderName);
                   oapagecontext.putSessionValue("xx_CreditCardNumber", 
                                              lc_CreditCardNumber);
                   oapagecontext.putSessionValue("xx_CreditCardExpDate", 
                                              lc_CreditCardExpDate);
                   oapagecontext.putSessionValue("xx_CreditCardExpYear", 
                                              lc_CreditCardExpYear);
											  
											  
					
							
         
                }
			
         
				//End Setting Session Values
				
				
                // Getting Payframe registrationid status
                OAMessageTextInputBean xxodStatus = 
                    (OAMessageTextInputBean)flowBean.findChildRecursive("XXODStatus");

                if (flowBean.findChildRecursive("XXODStatus") == null) {
                    oapagecontext.writeDiagnostics(this, 
                                                   "XXOD: flowBean XXODStatus null", 
                                                   1);
                } else {

                    if ((xxodStatus.getText(oapagecontext)) != null && 
                        (!"".equals(xxodStatus.getText(oapagecontext))))
                        sPayStatus = 
                                xxodStatus.getText(oapagecontext).toString();
                    else
                        oapagecontext.writeDiagnostics(this, 
                                                       "XXOD: flowBean XXODStatus value null", 
                                                       1);
                }
                oapagecontext.writeDiagnostics(this, 
                                               "XXOD: sPayStatus:" + sPayStatus, 
                                               1);

                if (sPayStatus == null || "".equals(sPayStatus) || 
                    "000".equals(sPayStatus) || (!"870".equals(sPayStatus))) {


                    OAStackLayoutBean newPayPageRN = (OAStackLayoutBean)flowBean.findChildRecursive("NewPayPageRN");
                    if(newPayPageRN != null)
                    {
                      oapagecontext.writeDiagnostics(this,  "XXOD: newPayPageRN found..rendering false", 1);
                      //newPayPageRN.setRendered(false);
                    }
                    else
                     oapagecontext.writeDiagnostics(this,  "XXOD: newPayPageRN not found..", 1);
  
                   OAMessageComponentLayoutBean  seededCCRN = (OAMessageComponentLayoutBean)flowBean.findChildRecursive("NewCCMessageCompLayout");
                   if(seededCCRN != null)
                   {
                    oapagecontext.writeDiagnostics(this,  "XXOD: seeded CC RN found ..rendering false", 1);
                    //seededCCRN.setRendered(false);
	               }
		        else
		           oapagecontext.writeDiagnostics(this,  "XXOD: seeded CC RN not found..", 1);


                    throw new OAException("XXFIN", "XXOD_AR_IREC_PAYCC_ERR", 
                                          null, OAException.ERROR, null);
                }

                    

            }
        }


        oapagecontext.writeDiagnostics(this, "XXOD: End validateCC", 1);

    }
}
