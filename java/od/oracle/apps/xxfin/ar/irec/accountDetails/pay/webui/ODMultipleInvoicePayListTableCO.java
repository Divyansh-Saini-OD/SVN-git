package od.oracle.apps.xxfin.ar.irec.accountDetails.pay.webui;
/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |                       Oracle WIPRO Consulting Organization                |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODMultipleInvoicePayListTableCO                               |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    This java file is extended from MultipleInvoicePayListTableCO for the  |
 |    Extension E1294                                                        |
 |                                                                           |
 |                                                                           |
 |Change Record:                                                             |
 |===============                                                            |
 | Date         Author              Remarks                                  |
 | ==========   =============       =======================                  |
 | 14-Aug-2007  MadanKumar J        Initial Draft                            |
 | 20-Nov-2007  Madankumar J        Modified for the CR2462                  |
 | 15-Aug-2013  Sridevi K           For R12 upgrade retrofit                 |
 | 17-FEB-2017  MBolli			   Thread Leak 12.2.5 Upgrade - close all statements, resultsets |
 |                                                                           |
 +============================================================================+*/
import oracle.apps.ar.irec.accountDetails.pay.webui.MultipleInvoicePayListTableCO;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
/*import oracle.jdbc.driver.OracleCallableStatement;*/
//Added for R12 upgrade
import oracle.jdbc.OracleCallableStatement;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import od.oracle.apps.xxfin.ar.irec.accountDetails.pay.server.ODMultipleInvoicesPayListVOImpl;
import od.oracle.apps.xxfin.ar.irec.accountDetails.pay.server.ODMultipleInvoicesPayListVORowImpl;


public class ODMultipleInvoicePayListTableCO extends MultipleInvoicePayListTableCO
{
public static String Gc_Authcode = null;

    public ODMultipleInvoicePayListTableCO()
    {
    }

    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
		oapagecontext.writeDiagnostics(this, "XXOD: start processRequest", 1); 

        super.processRequest(oapagecontext, oawebbean);
		OracleCallableStatement oraclecallablestatement = null;
        try
        {
            String username = oapagecontext.getUserName();
            oapagecontext.writeDiagnostics(this, username, 1);
            OAApplicationModuleImpl oaapplicationmoduleimpl = (OAApplicationModuleImpl)oapagecontext.getRootApplicationModule();
            OAApplicationModuleImpl oaapplicationmoduleimpl1 = (OAApplicationModuleImpl)oapagecontext.getApplicationModule(oawebbean);
            OADBTransaction oadbtransaction = (OADBTransaction)oaapplicationmoduleimpl.getDBTransaction();
  		    oapagecontext.writeDiagnostics(this, "XXOD: calling XX_AR_IREC_PAYMENTS.VERBAL_AUTH_CODE", 1); 

            String s = "BEGIN XX_AR_IREC_PAYMENTS.VERBAL_AUTH_CODE(p_user_name => :1,x_return_value => :" +
"2);END;"
;
            oraclecallablestatement = (OracleCallableStatement)oadbtransaction.createCallableStatement(s, 1);
            oraclecallablestatement.setString(1, username);
            oraclecallablestatement.registerOutParameter(2, 12, 0, 6000);
            oraclecallablestatement.execute();
            String lc_return_value = oraclecallablestatement.getString(2);
            String lc_bep_value =(String)oapagecontext.getSessionValue("x_bep_value");

			 oapagecontext.writeDiagnostics(this, "XXOD: x_bep_value"+lc_bep_value, 1); 

            if(lc_bep_value != null && lc_bep_value.equals("2"))//Included for the CR2462 by Madankumar J,Wipro Technologies
            {
			    oapagecontext.writeDiagnostics(this, "XXOD: in if", 1); 

                if(lc_return_value.equals("TRUE"))
                {
                    OAMessageTextInputBean oamessagetextinputbean1 = (OAMessageTextInputBean)oawebbean.findChildRecursive("AuthCode_Item");
                    oamessagetextinputbean1.setRendered(true);
                } else
                {
                    OAMessageTextInputBean oamessagetextinputbean1 = (OAMessageTextInputBean)oawebbean.findChildRecursive("AuthCode_Item");
                    oamessagetextinputbean1.setRendered(false);
                }
            } else
            {
	            oapagecontext.writeDiagnostics(this, "XXOD: in else", 1); 
                OAMessageTextInputBean oamessagetextinputbean1 = (OAMessageTextInputBean)oawebbean.findChildRecursive("AuthCode_Item");
                oamessagetextinputbean1.setRendered(false);
            }
        }
        catch(Exception exception2)
        {
            throw OAException.wrapperException(exception2);
        }
		finally {
			try {
				if (oraclecallablestatement != null)
					oraclecallablestatement.close();
			}
			catch(Exception exc) {  }
		}	  		
		oapagecontext.writeDiagnostics(this, "XXOD: end processRequest", 1); 
    }

    public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
		oapagecontext.writeDiagnostics(this, "XXOD: start processFormRequest", 1); 
        super.processFormRequest(oapagecontext, oawebbean);
        String lc_authcode=oapagecontext.getParameter("AuthCode_Item");
		oapagecontext.writeDiagnostics(this, "XXOD: lc_authcode"+lc_authcode, 1); 
        
		
		if (lc_authcode!=null) 
        {
        OAApplicationModule oaapplicationmodule1 = oapagecontext.getApplicationModule((OAMessageTextInputBean)oawebbean.findChildRecursive("AuthCode_Item"));
        ODMultipleInvoicesPayListVOImpl multipleinvoicespaylistvoimpl1 = (ODMultipleInvoicesPayListVOImpl)oaapplicationmodule1.findViewObject("MultipleInvoicesPayListVO");
        ODMultipleInvoicesPayListVORowImpl multipleinvoicespaylistvorowimpl1 = (ODMultipleInvoicesPayListVORowImpl)multipleinvoicespaylistvoimpl1.first();
        multipleinvoicespaylistvorowimpl1.setXXODAuthCode(lc_authcode);
        }
		
		oapagecontext.writeDiagnostics(this, "XXOD: end processFormRequest", 1); 
    }

}
