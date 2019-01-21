package od.oracle.apps.xxfin.ar.irec.accountDetails.pay.webui;

import oracle.apps.ar.irec.accountDetails.pay.webui.PaymentPageButtonsCO;
import oracle.apps.ar.irec.accountDetails.server.AccountDetailsAMImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OABodyBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;

/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 +===========================================================================+
 |  FILENAME                                                                 |
 |            ODPaymentPageButtonsCO                                         |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    This java file is extended from PaymentPageButtonsCO                   |
 |                                                                           |
 |  RICE  CR868                                                              |
 |Change Record:                                                             |
 |===============                                                            |
 | Date         Author              Remarks                                  |
 | ==========   =============       =======================                  |
 | 14-May-2014  Sridevi K           Code added for Mod4A                     |
 +============================================================================+*/

public class ODPaymentPageButtonsCO extends PaymentPageButtonsCO
{

    public ODPaymentPageButtonsCO()
    {
    }

    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        OASubmitButtonBean oasubmitbuttonbean2 = (OASubmitButtonBean)oawebbean.findIndexedChildRecursive("PaymentButton");
        oasubmitbuttonbean2.setRendered(false);
        super.processRequest(oapagecontext, oawebbean);
        String lc_bep_value = (String)oapagecontext.getSessionValue("x_bep_value");
        if(lc_bep_value != null && lc_bep_value.equals("2"))
        {
            OASubmitButtonBean oasubmitbuttonbean1 = (OASubmitButtonBean)oawebbean.findIndexedChildRecursive("AdvPaymentButton");
            oasubmitbuttonbean1.setRendered(false);
            OASubmitButtonBean oasubmitbuttonbean3 = (OASubmitButtonBean)oawebbean.findIndexedChildRecursive("PaymentButton");
            oasubmitbuttonbean3.setRendered(true);
            oapagecontext.putSessionValue("x_bep_value", "null");
        }
		
		//Added for Mod4A eCheck enhancement. When both restriction applies to Credit Card and ACH payments, this button should be hidden
        String sCCFlag = "N";
        String sACHFlag = "N";
		
        sACHFlag = (String)oapagecontext.getSessionValue("XXOD_ACH_FLAG");
        sCCFlag = (String)oapagecontext.getSessionValue("XXOD_CC_FLAG");	



        /* Added - For internal customers - CC is allowed 
		   For External User Apply button rendered false basing on attributes 
		*/
        boolean bExternalUser = isExternalCustomer(oapagecontext, oawebbean);

        if (("Y".equals(sACHFlag) && "N".equals(sCCFlag)) && (bExternalUser))
        {
          oasubmitbuttonbean2.setRendered(false);
        }	

/* Added for defect 33771. To disable the Pay button incase the SOA process has executed successfully. This is in addition to the Mod4A check done in the code above.*/

	if ( ("S".equals(oapagecontext.getSessionValue("XX_AR_IREC_PAY_STATUS")) && 
            oapagecontext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER") != null && 
            !"".equals(oapagecontext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER"))) )
	{
		oasubmitbuttonbean2.setDisabled(true);

	}

	if ( (!"S".equals(oapagecontext.getSessionValue("XX_AR_IREC_PAY_STATUS")) && 
            oapagecontext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER") == null && 
            "".equals(oapagecontext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER")))  )
	{
		oasubmitbuttonbean2.setDisabled(false);

	}
					
    }

    public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
      super.processFormRequest(oapagecontext, oawebbean);
   /* Added for defect 33771. To disable the Pay button incase the SOA process has executed successfully. This is in addition to the Mod4A check done in the code above.*/

    OASubmitButtonBean oasubmitbuttonbean2 = (OASubmitButtonBean)oawebbean.findIndexedChildRecursive("PaymentButton");
	if(oapagecontext.getParameter("PaymentButton") !=null)
	{
		if ( ("S".equals(oapagecontext.getSessionValue("XX_AR_IREC_PAY_STATUS")) && 
            oapagecontext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER") != null && 
            !"".equals(oapagecontext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER")))  )
	{
		oasubmitbuttonbean2.setDisabled(true);

	}

	if ( (!"S".equals(oapagecontext.getSessionValue("XX_AR_IREC_PAY_STATUS")) && 
            oapagecontext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER") == null && 
            "".equals(oapagecontext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER")))  )
	{
		oasubmitbuttonbean2.setDisabled(false);

	}
       }
	

    }
}
