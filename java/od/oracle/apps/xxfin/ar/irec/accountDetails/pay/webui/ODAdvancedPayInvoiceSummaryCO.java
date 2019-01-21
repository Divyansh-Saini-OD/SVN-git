
package od.oracle.apps.xxfin.ar.irec.accountDetails.pay.webui;

/*===========================================================================+
 |                       Office Depot - Project Simplify                                                                                                                  |
 |                       Oracle WIPRO Consulting Organization                                                                                                      |
 +===========================================================================+
 |  FILENAME                                                                                                                                                                     |
 |             ODAdvancedPayInvoiceSummaryCO												                        |
 |																						        |
 |  DESCRIPTION																			        |
 |    This java file is extended from AdvancedPayInvoiceSummaryCO											|
 |																							|
 |																						        |
 |																							|
 |Change Record:																		                |
 |===============																	                |
 | Date         Author              Remarks															        |
 | ==========   =============       =======================							        |
 | 28-Feb-2008    MadanKumar J                   Initial Draft												        |	
 | 15-APR-2010   Jude Felix Antony.A             Modified for the Defect #4445									|
 +============================================================================+*/


import od.oracle.apps.xxfin.ar.irec.accountDetails.pay.server.ODMultipleInvoicesPayListVOImpl;
import od.oracle.apps.xxfin.ar.irec.accountDetails.pay.server.ODMultipleInvoicesPayListVORowImpl;
import oracle.apps.ar.irec.accountDetails.pay.webui.AdvancedPayInvoiceSummaryCO;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.jbo.RowSetIterator;
import oracle.jbo.domain.Number;

public class ODAdvancedPayInvoiceSummaryCO extends AdvancedPayInvoiceSummaryCO
{

    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        String lc_totalpayment = (String)oapagecontext.getSessionValue("lc_total");
        String lc_totalcount = (String)oapagecontext.getSessionValue("xx_totalcount");
        String lc_bepValue = (String)oapagecontext.getSessionValue("x_bep_value");
        oapagecontext.writeDiagnostics(this, "Madan outside if loop of ODAdvancedPayInvoiceSummaryCO " + lc_totalpayment, 1);
        if(lc_bepValue != null && "2".equals(lc_bepValue))
        {
            OAApplicationModuleImpl oaapplicationmodule = (OAApplicationModuleImpl)oapagecontext.getApplicationModule((OAMessageTextInputBean)oawebbean.findChildRecursive("PaymentAmt"));
            ODMultipleInvoicesPayListVOImpl multipleinvoicespaylistvoimpl = (ODMultipleInvoicesPayListVOImpl)oaapplicationmodule.findViewObject("MultipleInvoicesPayListVO");
            RowSetIterator rowsetiterator = multipleinvoicespaylistvoimpl.createRowSetIterator("multipleinvoiceslist");
            rowsetiterator.reset();
            int l = 0;
            int count = Integer.parseInt(lc_totalcount);
            for(l = 0; l < count; l++)
            {
                ODMultipleInvoicesPayListVORowImpl multipleinvoicespaylistvorowimpl1 = (ODMultipleInvoicesPayListVORowImpl)rowsetiterator.next();
                Number number = (Number)oapagecontext.getSessionValue("xx_amountValuePFR" + l);
                multipleinvoicespaylistvorowimpl1.setPaymentAmt(number);
            }

            rowsetiterator.closeRowSetIterator();
            super.processRequest(oapagecontext, oawebbean);
        } else
        {
            oapagecontext.writeDiagnostics(this, "Madan inside else loop of ODAdvancedPayInvoiceSummaryCO ", 1);
            super.processRequest(oapagecontext, oawebbean);
        }
    }

    public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {

	String s = oapagecontext.getParameter("event"); /*Added for Defect #4445 By Jude */
	int savedRangeStart=0;   /*Added for Defect #4445 By Jude */
	OAApplicationModuleImpl am = (OAApplicationModuleImpl)oapagecontext.getApplicationModule(oawebbean); /*Added for Defect #4445 By Jude */
	OAViewObject vo = (OAViewObject)am.findViewObject("MultipleInvoicesPayListVO"); /*Added for Defect #4445 By Jude */
       
        if("update".equals(s))      /*Added for Defect #4445 By Jude */
            { 
		
		 try {
			savedRangeStart = vo.getRangeStart();
		     }
		 catch(Exception _ex) {}
       	    }
	
        super.processFormRequest(oapagecontext, oawebbean);    /*Added for Defect #4445 By Jude */
	if("update".equals(s))     /*Added for Defect #4445 By Jude */
            {
		 try {
          	 
            		vo.setRangeStart(savedRangeStart);
         	     }
         	 catch(Exception _ex) {}		 
            }

        OAApplicationModuleImpl oaapplicationmodule = (OAApplicationModuleImpl)oapagecontext.getApplicationModule((OAMessageTextInputBean)oawebbean.findChildRecursive("PaymentAmt"));
        OADBTransaction oadbtransaction = (OADBTransaction)oaapplicationmodule.getDBTransaction();
        ODMultipleInvoicesPayListVOImpl multipleinvoicespaylistvoimpl = (ODMultipleInvoicesPayListVOImpl)oaapplicationmodule.findViewObject("MultipleInvoicesPayListVO");
        RowSetIterator rowsetiterator = multipleinvoicespaylistvoimpl.createRowSetIterator("multipleinvoiceslist");
        OAViewObject oaviewobject1 = (OAViewObject)oaapplicationmodule.findViewObject("MultipleInvoicesPayListVO");
        int i = oaviewobject1.getFetchedRowCount();
        rowsetiterator.reset();
        int j = 0;
        int k;
        for(k = 0; rowsetiterator.hasNext() && j < i; k++)
        {
            ODMultipleInvoicesPayListVORowImpl multipleinvoicespaylistvorowimpl = (ODMultipleInvoicesPayListVORowImpl)rowsetiterator.next();
            oapagecontext.putSessionValue("xx_amountValuePFR" + k, multipleinvoicespaylistvorowimpl.getPaymentAmt());
            j++;
        }

        rowsetiterator.closeRowSetIterator();
        String totalcount = String.valueOf(k);
        oapagecontext.putSessionValue("xx_totalcount", totalcount);
    }

    public ODAdvancedPayInvoiceSummaryCO()
    {
    }
}
