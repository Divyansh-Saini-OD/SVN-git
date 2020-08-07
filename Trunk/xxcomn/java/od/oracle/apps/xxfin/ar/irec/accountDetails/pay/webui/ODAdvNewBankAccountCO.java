package od.oracle.apps.xxfin.ar.irec.accountDetails.pay.webui;

import oracle.apps.ar.irec.accountDetails.pay.webui.AdvNewBankAccountCO;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.webui.beans.OABodyBean;

import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;

import oracle.cabo.ui.action.FireAction;

import oracle.cabo.ui.action.FirePartialAction;

import oracle.apps.po.common.webui.ClientUtil;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;

/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |                       Oracle WIPRO Consulting Organization                |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODAdvNewCreditCardCO.java                                     |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    This java file is extended from AdvNewCreditCardCO for Defect 6528     |
 |                                                                           |
 |  RICE  CR868                                                              |
 |Change Record:                                                             |
 |===============                                                            |
 | Date         Author              Remarks                                  |
 | ==========   =============       =======================                  |
 | 22-Feb-2008  Anitha Devarajulu   Initial Draft                            |
 |                                                                           |
 | 05-May-2008  Anitha Devarajulu   Modified for the Defect 6528             |
 | 2-Sep-2013  Sridevi K            R12 upgrade retrofit                     |
 |                                  added diagnostics debug messages.         |
 |                                  Code Added for                           |
 |                                  Standard "Account Holder" rendering false. |
 | 27-Mar-2015     Sridevi K      E0255 CR1120 CDH Additional Attributes     |
 |                                for Echeck Defect 33515                    |
 | 14-May-2015     Sridevi K      For email addr validation                  |
 | 20-May-2015     Sridevi K      For email addr validation                  |
 | 24-Jan-2017     Sreedhar Mohan Modified javascript on KeyListener . Check whether undefined or null |
  +============================================================================+*/


public class ODAdvNewBankAccountCO extends AdvNewBankAccountCO {
    public void processRequest(OAPageContext oapagecontext, 
                               OAWebBean oawebbean) {
        String s = null;
        String errormessage = null;

        try {

            oapagecontext.writeDiagnostics(this, 
                                           "XXOD::::: Start oracle.apps.ar.irec.accountDetails.pay.webui.ODAdvNewBankAccountCO processRequest", 
                                           1);
            s = "Step 10.10";
            super.processRequest(oapagecontext, oawebbean);


            oapagecontext.putJavaScriptFunction("click()", 
                                                "document.oncontextmenu=new Function(\"return false;\")");

            oapagecontext.putJavaScriptFunction("keyListener", 
                                                "function keyListener(e){if (window.event) { if ((window.event.keyCode==17) || (window.event.keyCode==18)) {" + 
                                                "alert(\"For security, copy and paste is not available in this field, please re-type your information.\"); \n" + 
                                                " return false;} else {" + 
                                                "//alert (\"IE not ctrl\");\n" + 
                                                " return true;} } else " + 
                                                " {if ((e.keyCode==17) || (e.keyCode==18)){" + 
                                                "alert(\"For security, copy and paste is not available in this field, please re-type your information. \"); \n" + 
                                                " return false;} else { return true;}} \n}" + 
                                                " if ((document.getElementById(\"OD_Reenter_Acct_Number\") != 'undefined')    && (document.getElementById(\"OD_Reenter_Acct_Number\") != null )) { document.getElementById(\"OD_Reenter_Acct_Number\").onkeypress=keyListener;   " +
                                                " document.getElementById(\"OD_Reenter_Acct_Number\").onkeydown=keyListener;  }  " +
                                                "if ((document.getElementById(\"txtOdConfirmEmailAddress\") != 'undefined')    && (document.getElementById(\"txtOdConfirmEmailAddress\") != null )) { document.getElementById(\"txtOdConfirmEmailAddress\").onkeypress=keyListener; " +
                                                " document.getElementById(\"txtOdConfirmEmailAddress\").onkeydown=keyListener;	}" );
                                                //"document.onkeypress=keyListener;" + 
                                                //"document.onkeydown=keyListener;");


         /*
		 oapagecontext.putJavaScriptFunction("validateEmail", 
                                                 "function validateEmail(){ \n"+
                                                " if (/^\\w+([\\.-]?\\w+)*@\\w+([\\.-]?\\w+)*(\\.\\w{2,3})+$/.test(document.getElementById(\"txtOdEmailAddress\").value)) \n"+  
                                                " { \n"+ 
                                                "   return (true); \n"+  
                                                " } \n"+  
                                                " alert(\"Please enter valid Email Address!\"); \n"+  
                                                "   return (false); \n"+ 
                                                 "}"+
                                                 " document.getElementById(\"txtOdEmailAddress\").onblur=validateEmail;  " );


         oapagecontext.putJavaScriptFunction("validateReenterEmail", 
                                             "function validateReenterEmail(){ \n"+
                                            " if (/^\\w+([\\.-]?\\w+)*@\\w+([\\.-]?\\w+)*(\\.\\w{2,3})+$/.test(document.getElementById(\"txtOdConfirmEmailAddress\").value)) \n"+  
                                            " { \n"+ 
                                            "   return (true); \n"+  
                                            " } \n"+  
                                            " alert(\"Please enter valid Confirm Email Address!\"); \n"+  
                                            "   return (false); \n"+ 
                                             "}"+
                                             " document.getElementById(\"txtOdConfirmEmailAddress\").onblur=validateReenterEmail;  " );

         */
  
                               
                            


            OABodyBean oabean = (OABodyBean)oapagecontext.getRootWebBean();

            oapagecontext.writeDiagnostics(this, "XXOD: Set keylistener", 1);
            //oabean.setOnKeyPress("keyListener(e)");
            //oabean.setOnKeyDown("keyListener(e)");
            OAMessageTextInputBean customReenterAcctNo = 
                (OAMessageTextInputBean)oawebbean.findChildRecursive("OD_Reenter_Acct_Number");
            if (customReenterAcctNo != null) {

                oapagecontext.writeDiagnostics(this, 
                                               "#####XXXX PPR set .............", 
                                               1);

                FireAction firePartialAction = new FirePartialAction("pprEvent");
                customReenterAcctNo.setAttributeValue(PRIMARY_CLIENT_ACTION_ATTR, firePartialAction);
                customReenterAcctNo.setFireActionForSubmit("pprEvent", null, null, true);
                customReenterAcctNo.setOnKeyPress("return keyListener(event)");
                customReenterAcctNo.setOnKeyDown("return keyListener(event)");
               

            }

            OAMessageTextInputBean customReenterEmail = 
                (OAMessageTextInputBean)oawebbean.findChildRecursive("txtOdConfirmEmailAddress");
            if (customReenterEmail != null) {

                oapagecontext.writeDiagnostics(this, 
                                               "#####XXXX PPR set for confirm email.............", 
                                               1);

                FireAction firePartialActionEmail =  new FirePartialAction("pprEventEmail");
                customReenterEmail.setAttributeValue(PRIMARY_CLIENT_ACTION_ATTR, firePartialActionEmail);
                customReenterEmail.setFireActionForSubmit("pprEventEmail", null, null, true);
                customReenterEmail.setOnKeyPress("return keyListener(event)");
                customReenterEmail.setOnKeyDown("return keyListener(event)");
                //customReenterEmail.setOnBlur("return validateReenterEmail()");
				

            }
            
            
           /*
		   OAMessageTextInputBean customEmail = 
                (OAMessageTextInputBean)oawebbean.findChildRecursive("txtOdEmailAddress");
            if (customEmail != null) {

                oapagecontext.writeDiagnostics(this, 
                                               "#####XXXX PPR set for email.............", 
                                               1);

                FireAction firePartialActionEmail =  new FirePartialAction("pprEventEmailAddr");
                customEmail.setAttributeValue(PRIMARY_CLIENT_ACTION_ATTR, firePartialActionEmail);
                customEmail.setFireActionForSubmit("pprEventEmailAddr", null, null, true);
                //customEmail.setOnBlur("return validateEmail()");
                                

            }
			*/
            //******************************************


            /* Added for R12 upgrade retrofit*/
            OAMessageTextInputBean AccountHolder = 
                (OAMessageTextInputBean)oawebbean.findChildRecursive("AccountHolder");

            AccountHolder.setRendered(false);
            /* End - Added for R12 upgrade retrofit*/
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: after rendering false Accountholder", 
                                           1);
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: after super processrequest", 
                                           1);
            OAMessageTextInputBean customAcctName = 
                (OAMessageTextInputBean)oawebbean.findChildRecursive("OD_Bank_Account_Name");
            /*
            if (customAcctName != null) {
                oapagecontext.writeDiagnostics(this, 
                                               "XXOD: ##### In PR AdvNewBankAccountCO  customAcctName != null////  customAcctName.getText(oapagecontext)=" + 
                                               customAcctName.getText(oapagecontext), 
                                               1);
                //      if((customAcctName.getText(oapagecontext)) != null && !"".equals(customAcctName.getText(oapagecontext))){
                if (oapagecontext.getSessionValue("OD_CUST_ACCNT_HOLDER_NAME") != 
                    null) {
                    oapagecontext.putSessionValue("OD_CUST_ACCNT_HOLDER_NAME", 
                                                  oapagecontext.getSessionValue("OD_CUST_ACCNT_HOLDER_NAME").toString());
                    oapagecontext.writeDiagnostics(this, 
                                                   "XXOD: ##### In PR AdvNewBankAccountCO Inside IFF... oapagecontext.getSessionValue(OD_CUST_ACCNT_HOLDER_NAME)=" + 
                                                   oapagecontext.getSessionValue("OD_CUST_ACCNT_HOLDER_NAME"), 
                                                   1);
                } else if (customAcctName.getText(oapagecontext) != null) {
                    oapagecontext.writeDiagnostics(this, 
                                                   "XXOD: ##### In PR AdvNewBankAccountCO of customAcctName.getText(oapagecontext) != null////////// customAcctName.getText(oapagecontext)=" + 
                                                   customAcctName.getText(oapagecontext), 
                                                   1);
                    oapagecontext.putSessionValue("OD_CUST_ACCNT_HOLDER_NAME", 
                                                  customAcctName.getText(oapagecontext));
                } else {
                    customAcctName.setText(null);
                    oapagecontext.writeDiagnostics(this, 
                                                   "XXOD: custacctname set to null", 
                                                   1);
                }
            }
			*/
          
			oapagecontext.writeDiagnostics(this, 
                                           "XXOD: ##### In PR AdvNewBankAccountCO customAcctName=" + 
                                           customAcctName, 1);


            OAMessageTextInputBean confirmemail = 
                (OAMessageTextInputBean)oawebbean.findChildRecursive("txtOdConfirmEmailAddress");

            if (confirmemail != null) {
                oapagecontext.writeDiagnostics(this, 
                                               "XXOD: ##### In PR AdvNewBankAccountCO  confirmemail" + 
                                               confirmemail.getText(oapagecontext), 
                                               1);
                if (oapagecontext.getSessionValue("OD_CONFIRMEMAIL") != null) {

                    oapagecontext.putSessionValue("OD_CONFIRMEMAIL", 
                                                  oapagecontext.getSessionValue("OD_CONFIRMEMAIL").toString());

                    oapagecontext.writeDiagnostics(this, 
                                                   "XXOD: ##### In PR AdvNewBankAccountCO OD_CONFIRMEMAIL=" + 
                                                   oapagecontext.getSessionValue("OD_CONFIRMEMAIL"), 
                                                   1);
                } else if (confirmemail.getText(oapagecontext) != null) {
                    oapagecontext.writeDiagnostics(this, 
                                                   "XXOD: ##### In PR AdvNewBankAccountCO of confirmemail.getText(oapagecontext) != null" + 
                                                   confirmemail.getText(oapagecontext), 
                                                   1);
                    oapagecontext.putSessionValue("OD_CONFIRMEMAIL", 
                                                  confirmemail.getText(oapagecontext));
                } /*else {
                    confirmemail.setText(null);
                    oapagecontext.writeDiagnostics(this,
                                                   "XXOD: confirmemail set to null",
                                                   1);
                }*/
            }

            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: ##### In PR AdvNewBankAccountCO confirmemail=" + 
                                           confirmemail, 1);


	
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: End oracle.apps.ar.irec.accountDetails.pay.webui.ODAdvNewBankAccountCO processRequest", 
                                           1);
        } catch (Exception e) {
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: End oracle.apps.ar.irec.accountDetails.pay.webui.ODAdvNewBankAccountCO processRequest", 
                                           1);
            throw new OAException("Encountered error " + s + " " + e);
        }


        //setViewBasingOnACHCC(oapagecontext, oawebbean);

    }

    public void processFormRequest(OAPageContext oapagecontext, 
                                   OAWebBean oawebbean) {
        super.processFormRequest(oapagecontext, oawebbean);



       
	
        OABodyBean oabean = (OABodyBean)oapagecontext.getRootWebBean();
		 
        /*
		reacctNumber = "";
        if ( oapagecontext.getParameter("OD_Reenter_Acct_Number") != null)
          reacctNumber = oapagecontext.getParameter("OD_Reenter_Acct_Number").toString();
        acdtNumber1 = "";        
        if ( oapagecontext.getParameter("AccountNumber") != null)
          acdtNumber1 = oapagecontext.getParameter("AccountNumber").toString();
        
        if (!(acdtNumber1.equals(reacctNumber))) {
            //oabean.setInitialFocusId("OD_Reenter_Acct_Number");
            oapagecontext.putParameter("from_AcctNbr_ppr", "Y");
            throw new OAException("XXFIN", 
                                  "OD_IREC_ACCT_NUM_REACCT_NUM", 
                                  null, OAException.ERROR, null);
            
        } else {
			;
            //oabean.setInitialFocusId("txtOdEmailAddress");
        }

        String email = null;
        String confirmemail = null;		
        confirmemail = "";
        if( oapagecontext.getParameter("txtOdConfirmEmailAddress") != null)
          confirmemail = oapagecontext.getParameter("txtOdConfirmEmailAddress").toString();
        email = "";
        if( oapagecontext.getParameter("txtOdEmailAddress") != null)
          email = oapagecontext.getParameter("txtOdEmailAddress").toString();
        
        if (!(email.equals(confirmemail))) {
            //oabean.setInitialFocusId("txtOdConfirmEmailAddress");
            oapagecontext.putParameter("from_email_ppr", "Y");
            throw new OAException("XXFIN", 
                                  "OD_IREC_EMAIL_CONFIRMEMAIL", 
                                  null, OAException.ERROR, null);
        } else {
            //oabean.setInitialFocusId("OD_Bank_Account_Name");
            oapagecontext.putSessionValue("OD_CONFIRMEMAIL", 
                                          confirmemail);
        }	
		*/
		
		String acdtNumber1 = null;
        String reacctNumber = null;

		reacctNumber = "";
        if ( oapagecontext.getParameter("OD_Reenter_Acct_Number") != null)
          reacctNumber = oapagecontext.getParameter("OD_Reenter_Acct_Number").toString();
        acdtNumber1 = "";        
        if ( oapagecontext.getParameter("AccountNumber") != null)
          acdtNumber1 = oapagecontext.getParameter("AccountNumber").toString();

        if ("pprEvent".equals(oapagecontext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {
            
          	if (reacctNumber != null) {
                if (oapagecontext.getParameter("OD_Reenter_Acct_Number") != 
                    null && 
                    oapagecontext.getParameter("AccountNumber") != null) {
                    oapagecontext.writeDiagnostics(this, 
                                                   "#####XXXX PPR inside .............", 
                                                   1);
                    
                    if (!(acdtNumber1.equals(reacctNumber))) {
                        oabean.setInitialFocusId("OD_Reenter_Acct_Number");
						
                        throw new OAException("XXFIN", 
                                              "OD_IREC_ACCT_NUM_REACCT_NUM", 
                                              null, OAException.ERROR, null);
                        
                    } else {
						oabean.setInitialFocusId("txtOdEmailAddress");
                    }
                }
            }
        }

        String email = null;
        String confirmemail = null;		
        confirmemail = "";
        if( oapagecontext.getParameter("txtOdConfirmEmailAddress") != null)
          confirmemail = oapagecontext.getParameter("txtOdConfirmEmailAddress").toString();
        email = "";
        if( oapagecontext.getParameter("txtOdEmailAddress") != null)
          email = oapagecontext.getParameter("txtOdEmailAddress").toString();

        if ("pprEventEmail".equals(oapagecontext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {
     
   
            if (confirmemail != null) {
                if (oapagecontext.getParameter("txtOdConfirmEmailAddress") != 
                    null && 
                    oapagecontext.getParameter("txtOdEmailAddress") != null) {
                    oapagecontext.writeDiagnostics(this, 
                                                   "#####XXXX PPR inside confirm email.............", 
                                                   1);
                    
                    if (!(email.equals(confirmemail))) {
                         oabean.setInitialFocusId("txtOdConfirmEmailAddress");
						  throw new OAException("XXFIN", 
                                              "OD_IREC_EMAIL_CONFIRMEMAIL", 
                                              null, OAException.ERROR, null);
                    } else {
                        oabean.setInitialFocusId("OD_Bank_Account_Name");
                        oapagecontext.putSessionValue("OD_CONFIRMEMAIL", 
                                                      confirmemail);
                    }

                }
            }
			
        }

	
    }


    public void setViewBasingOnACHCC(OAPageContext pageContext, 
                                     OAWebBean webBean) {

        pageContext.writeDiagnostics(this, "XXOD: Start setViewBasingOnACHCC", 
                                     1);
        //Inital payment method value set in ODAdvPaymentMethodCO
        String sInitialPaymentMethod = 
            (String)pageContext.getSessionValue("XXOD_INITIALVALUE_PAYMETHOD");
        pageContext.writeDiagnostics(this, 
                                     "XXOD: sInitialPaymentMethod" + sInitialPaymentMethod, 
                                     1);

        String sCCFlag = (String)pageContext.getSessionValue("XXOD_CC_FLAG");
        String sACHFlag = (String)pageContext.getSessionValue("XXOD_ACH_FLAG");
        String sErrMessage = "XXOD_ACHCC_CONTROL_MSG";
        pageContext.writeDiagnostics(this, "XXOD: XXOD_CC_FLAG" + sCCFlag, 1);
        pageContext.writeDiagnostics(this, "XXOD: XXOD_ACH_FLAG" + sACHFlag, 
                                     1);

        OAPageLayoutBean oapagelayoutbean = pageContext.getPageLayoutBean();


        if (("NEW_BA".equals(sInitialPaymentMethod)) && 
            ("N".equals(sACHFlag))) {
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


        pageContext.writeDiagnostics(this, "XXOD: End setViewBasingOnACHCC", 
                                     1);

    }

}
