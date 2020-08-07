package od.oracle.apps.xxfin.ar.irec.accountDetails.webui;
/*===========================================================================+
 |      		      Office Depot - CR868                                   |
 |                    Oracle GSD                                             |
 +===========================================================================+
 | Filename    ODPaymentResultsRegionCO.java                                 |
 | Description To restrict to pay Payment Transaction         .              |
 |                                                                           |
 | History                                                                   |
 | Ver  Date       Name           Revision Description                       |
 | ===  =========  ============== ===========================================|
 | 1.0  12-Nov-12  Suraj Charan   Initial                                    |
 |                                                                           |
 +===========================================================================*/

import com.sun.java.util.collections.ArrayList;

import oracle.apps.ar.irec.accountDetails.server.PaymentVOImpl;
import oracle.apps.ar.irec.accountDetails.server.PaymentVORowImpl;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import oracle.jbo.RowSetIterator;
import oracle.apps.ar.irec.accountDetails.webui.PaymentResultsRegionCO;

public class ODPaymentResultsRegionCO extends PaymentResultsRegionCO
{

  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
  }

  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    OAApplicationModuleImpl oaapplicationmodule = (OAApplicationModuleImpl)pageContext.getApplicationModule(webBean);
    pageContext.writeDiagnostics(this, "##### IN PFR ODPaymentResultsRegionCO",1);
    if(pageContext.getParameter("pmtPay") != null || pageContext.getParameter("pmtTransactionList") != null)
    {
      pageContext.writeDiagnostics(this, "##### IN PFR ODPaymentResultsRegionCO When PAY Button Clicked",1);
      ArrayList arraylist = new ArrayList();
      PaymentVORowImpl transVORow = null;
      OAViewObject transVO = (OAViewObject)oaapplicationmodule.findViewObject("PaymentVO");
      OADBTransaction txn=oaapplicationmodule.getOADBTransaction();
      RowSetIterator rowsetiterator = transVO.createRowSetIterator("selectedListIter");
      RowSetIterator hdrIter  = transVO.findRowSetIterator("transIter");
      if(hdrIter!=null)
        hdrIter.closeRowSetIterator();

      hdrIter=transVO.createRowSetIterator("transIter");
      int fetchedRowCount=transVO.getRowCount();
      if(fetchedRowCount>0)
      {
        hdrIter.setRangeStart(0);
        hdrIter.setRangeSize(fetchedRowCount);
        Boolean val = Boolean.FALSE;
        for (int count = 0; count < fetchedRowCount; count++)
        {
		  pageContext.writeDiagnostics(this, "##### IN PFR ODPaymentResultsRegionCO Iterator value="+count,1);
		  transVORow=(PaymentVORowImpl)hdrIter.getRowAtRangeIndex(count);
		  if("Y".equals(transVORow.getAttribute("SelectedFlag")) )
		  {
		    transVORow.setAttribute("SelectedFlag",null);
		    val = Boolean.TRUE;
		  }
        } // end loop
        rowsetiterator.closeRowSetIterator();
        if(val==Boolean.TRUE)
        {
         /*
          String msg1 = "<html><body><font face=Script size=20 color=red><b>You are not able to use a 'payment' to net against the transaction(s) you selected.  The payment has been unchecked.  Please press the 'Add to Transaction list' or 'Pay' button to continue.</b></body></html>";
          OAException warnMsg = new OAException(msg1,OAException.WARNING);
          //pageContext.putDialogMessage(warnMsg);
          //throw new OAException("You are not able to use a 'payment' to net against the transaction(s) you selected.  The payment has been unchecked.  Please press the 'Add to Transaction list' or 'Pay' button to continue.",OAException.WARNING);
          throw new OAException(msg1,OAException.WARNING);
          */
          throw new OAException("XXFIN","OD_IREC_AGAINST_PAYMENT_TYPE",null,OAException.WARNING,null);
	    }
        //else
        //  super.processFormRequest(pageContext, webBean);
      }  // if(fetchedRowCount>0)
    }  // if(pageContext.getParameter("pmtPay")
    else
      super.processFormRequest(pageContext, webBean);
  }  // processFormRequest

}  // ODPaymentResultsRegionCO