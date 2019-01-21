package od.oracle.apps.xxfin.ar.irec.accountDetails.webui;
/*===========================================================================+
 |      		      Office Depot - CR868                                   |
 |                    Oracle GSD                                             |
 +===========================================================================+
 | Filename    ODCombinedResultsCO.java                                      |
 | Description To restrict to pay Payment Transaction         .              |
 |                                                                           |
 | History                                                                   |
 | Ver  Date       Name           Revision Description                       |
 | ===  =========  ============== ===========================================|
 | 1.0  12-Nov-12  Suraj Charan   Initial                                    |
 |                                                                           |
 +===========================================================================*/

import com.sun.java.util.collections.ArrayList;

import oracle.apps.ar.irec.accountDetails.server.TransactionTableVOImpl;
import oracle.apps.ar.irec.accountDetails.server.TransactionTableVORowImpl;
import oracle.apps.ar.irec.accountDetails.webui.CombinedResultsCO;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import oracle.jbo.RowSetIterator;

public class ODCombinedResultsCO extends CombinedResultsCO
{

  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
  }

  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    OAApplicationModuleImpl oaapplicationmodule = (OAApplicationModuleImpl)pageContext.getApplicationModule(webBean);
    pageContext.writeDiagnostics(this, "##### IN PFR ODCombinedResultsCO",1);
    if(pageContext.getParameter("Pay") != null || pageContext.getParameter("TransactionList") != null)
    {
      pageContext.writeDiagnostics(this, "##### IN PFR ODCombinedResultsCO When PAY Button Clicked",1);
      ArrayList arraylist = new ArrayList();
      TransactionTableVORowImpl transVORow = null;
      OAViewObject transVO = (OAViewObject)oaapplicationmodule.findViewObject("TransactionTableVO");
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
          pageContext.writeDiagnostics(this, "##### IN PFR ODCombinedResultsCO Iterator value="+count,1);
          transVORow=(TransactionTableVORowImpl)hdrIter.getRowAtRangeIndex(count);
          if("Payment".equals(transVORow.getAttribute("AcctDtlsViewTrxType")) && "Y".equals(transVORow.getAttribute("SelectedFlag")) )
          {
            val = Boolean.TRUE;
            transVORow.setAttribute("SelectedFlag",null);
          }
        } // end loop

        rowsetiterator.closeRowSetIterator();
        if(val==Boolean.TRUE)
           throw new OAException("XXFIN","OD_IREC_AGAINST_PAYMENT_TYPE",null,OAException.WARNING,null);
//           throw new OAException("You are not able to use a 'payment' to net against the transaction(s) you selected.  The payment has been unchecked.  Please press the 'Add to Transaction list' or 'Pay' button to continue.",OAException.WARNING);
        //else
        //  super.processFormRequest(pageContext, webBean);
      }
    }  // // if(pageContext.getParameter("Pay")
    super.processFormRequest(pageContext, webBean);
  } // processFormRequest

} // ODCombinedResultsCO