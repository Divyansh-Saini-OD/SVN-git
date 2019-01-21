package od.oracle.apps.xxfin.ar.irec.accountDetails.pay.webui;
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
 | 2-Sep-2013  Sridevi K           For R12 upgrade retrofit                  |
 |                                  added diagnostics debug messages.        |
 |                                  commented code related to                |
 |                                  NewCCSaveAddressFlag.                    |
 | 14-May-2014 Sridevi K            Modified for Mod4A - ACH and CC Flag     |
 |                                  for external users                       |
 +============================================================================+*/

import oracle.apps.ar.irec.accountDetails.pay.webui.AdvNewCreditCardCO;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageCheckBoxBean;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;
import oracle.apps.po.common.webui.ClientUtil;
import oracle.apps.fnd.framework.webui.beans.layout.OAStackLayoutBean;


public class ODAdvNewCreditCardCO extends AdvNewCreditCardCO {

    public void processRequest(OAPageContext oapagecontext, 
                               OAWebBean oawebbean) {
        String s = null;
        String errormessage = null;
        try {

            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: Start oracle.apps.ar.irec.accountDetails.pay.webui.AdvNewCreditCardCO processRequest", 
                                           1);
            s = "Step 10.10";
            super.processRequest(oapagecontext, oawebbean);
            s = "Step 10.20";
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: after super process request", 
                                           1);


            OAApplicationModule oaapplicationmodule = 
                oapagecontext.getApplicationModule(oawebbean);
            OAViewObject vo = 
                (OAViewObject)oaapplicationmodule.findViewObject("CreditCardTypesPVO");
            s = "Step 10.30";
            OARow oarow = (OARow)vo.getCurrentRow();
            s = "Step 10.40";
            if (oarow == null) {
                vo.insertRow(vo.createRow());
                oarow = (OARow)vo.first();
            }
            s = "Step 10.50";
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: after CreditCardTypesPVO", 
                                           1);

            oarow.setAttribute("NEW_CC_ADDRESS_RENDER", Boolean.FALSE);
			s = "Step 10.50.1";
			/*Commenting as part of R12 upgrade *
			/*NewCCSaveAddressFlag is not present in R12 page*/
			/*
            OAMessageCheckBoxBean oamessagecheckboxbean = 
                (OAMessageCheckBoxBean)oawebbean.findChildRecursive("NewCCSaveAddressFlag");
            oamessagecheckboxbean.setRendered(false);
			*/
			s = "Step 10.50.2";
			//modified for R12 upgrade retrofit
            //String lc_bep_value = (String)oapagecontext.getSessionValue("x_bep_value");

			String lc_bep_value = null;

			if (oapagecontext.getSessionValue("x_bep_value") != null)
			{
		     s = "Step 10.50.3";		 
             lc_bep_value = (String)oapagecontext.getSessionValue("x_bep_value");


			}
 
            s = "Step 10.50.4";
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: lc_bep_value" + lc_bep_value, 
                                           1);
            s = "Step 10.60";

            if (lc_bep_value != null && lc_bep_value.equals("2")) {
                OAMessageChoiceBean oamessagechoicebean = 
                    (OAMessageChoiceBean)oawebbean.findChildRecursive("NewCreditCardType");
                OAMessageTextInputBean oamessagetextinputbean = 
                    (OAMessageTextInputBean)oawebbean.findChildRecursive("NewCreditCardHolderName");
                OAMessageTextInputBean oamessagetextinputbean1 = 
                    (OAMessageTextInputBean)oawebbean.findChildRecursive("NewCreditCardNumber");
                OAMessageChoiceBean oamessagechoicebean1 = 
                    (OAMessageChoiceBean)oawebbean.findChildRecursive("NewCreditCardExpMonth");
                OAMessageChoiceBean oamessagechoicebean2 = 
                    (OAMessageChoiceBean)oawebbean.findChildRecursive("NewCreditCardExpYear");
                String x_render_value = 
                    (String)oapagecontext.getSessionValue("x_render");
                s = "Step 10.70";
                if (x_render_value != null && x_render_value.equals("TRUE")) {
                    oapagecontext.writeDiagnostics(this, 
                                                   "XXOD: x_render_value != null", 
                                                   1);

                    oamessagetextinputbean.setReadOnly(true);
                    oamessagetextinputbean1.setReadOnly(true);
                    //oamessagetextinputbean1.setValue(oapagecontext, "xxxxxxxxxxxxxxxxxxx");
                    oamessagechoicebean.setReadOnly(true);
                    oamessagechoicebean1.setReadOnly(true);
                    oamessagechoicebean2.setReadOnly(true);


	            OAStackLayoutBean newPayPageRN = (OAStackLayoutBean)oawebbean.findChildRecursive("NewPayPageRN");
                    if(newPayPageRN != null)
                     {
			newPayPageRN.setRendered(false);
	             }



                    s = "Step 10.80";
                }
                
            }

            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: End oracle.apps.ar.irec.accountDetails.pay.webui.AdvNewCreditCardCO processRequest", 
                                           1);
        String sCCFlag = "";
		String sACHFlag = "";
		
		sCCFlag = (String)oapagecontext.getSessionValue("XXOD_CC_FLAG");
		sACHFlag = (String)oapagecontext.getSessionValue("XXOD_ACH_FLAG");

        oapagecontext.writeDiagnostics(this, "In ODAdvNewCreditCardCO PR XXOD_CC_FLAG" + sCCFlag,  1);
        oapagecontext.writeDiagnostics(this, "In ODAdvNewCreditCardCO PR XXOD_ACH_FLAG" + sACHFlag, 1);
        OAPageLayoutBean oapagelayoutbean = oapagecontext.getPageLayoutBean();
        OAHeaderBean header2 = (OAHeaderBean)oapagelayoutbean.findIndexedChildRecursive("CreditCardTypeRegion"); //"oracle.apps.ar.irec.accountDetails.pay.webui.AdvNewCreditCardCO"
        OAHeaderBean header3 = (OAHeaderBean)oapagelayoutbean.findIndexedChildRecursive("CreditCardDetailsRegion");		
        /* Added - For internal customers - CC is allowed */
        boolean bExternalUser = isExternalCustomer(oapagecontext, oawebbean);

        if ( ("Y".equals(sACHFlag) && "N".equals(sCCFlag)) && (bExternalUser))
          {
          ClientUtil.setViewOnlyRecursive(oapagecontext, header2);		
          ClientUtil.setViewOnlyRecursive(oapagecontext, header3);		
		  if (header2 != null)
            header2.setRendered(false);              
		  if (header3 != null)
            header3.setRendered(false);
        } else {
		  if (header2 != null)
            header2.setRendered(true);              
		  if (header3 != null)
            header3.setRendered(true);
        }	

		
        } catch (Exception e) {
            throw new OAException("Encountered error " + s + " " + e);


        }

    }

    public void processFormData(OAPageContext oapagecontext, 
                                OAWebBean oawebbean) {
        oapagecontext.writeDiagnostics(this, "XXOD: start processFormData", 1);

        super.processFormData(oapagecontext, oawebbean);
        oapagecontext.writeDiagnostics(this, "XXOD: end processFormData", 1);
    }

    public void processFormRequest(OAPageContext oapagecontext, 
                                   OAWebBean oawebbean) {
        oapagecontext.writeDiagnostics(this, "XXOD: start processFormRequest", 
                                       1);

        super.processFormRequest(oapagecontext, oawebbean);

		/*Commenting as part of R12 upgrade *
	    /*NewCCSaveAddressFlag is not present in R12 page*/
		/*
        OAMessageCheckBoxBean oamessagecheckboxbean = 
            (OAMessageCheckBoxBean)oawebbean.findChildRecursive("NewCCSaveAddressFlag");
        oamessagecheckboxbean.setRendered(false);
        */
        oapagecontext.writeDiagnostics(this, "XXOD: end processFormRequest", 
                                       1);
    }

    public void setDefaultVisibility(OAPageContext oapagecontext, 
                                     OAWebBean oawebbean) {
        oawebbean.setRendered(true);
    }

    protected String[] queriesToInvoke() {
        return null;
    }

    protected String[] advancedQueriesToInvoke() {
        return null;
    }

    protected String getRegionID() {
        return "NEW_CC";
    }

    public ODAdvNewCreditCardCO() {
    }
}
