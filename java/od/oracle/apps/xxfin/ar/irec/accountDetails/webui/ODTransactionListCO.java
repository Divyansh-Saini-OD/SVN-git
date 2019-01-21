
package od.oracle.apps.xxfin.ar.irec.accountDetails.webui;

/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |                       Oracle WIPRO Consulting Organization                |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODTransactionListCO                                           |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    This java file is extended from TransactionListCO                      |
 |                                                                           |
 |                                                                           |
 |                                                                           |
 |Change Record:                                                             |
 |===============                                                            |
 | Date         Author                Remarks                                |
 | ==========   =============         =======================                |
 | 15-APR-2010  Jude Felix Antony.A  Created for the Defect  #4445           |
 | 08-Oct-2013  Suraj Charan         modified for the Defect #25448          | 
 |                                                                           |
 +===========================================================================+*/

import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.ar.irec.accountDetails.webui.TransactionListCO;

public class ODTransactionListCO extends TransactionListCO
{

    public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
       OAViewObject vo = null;
       OAApplicationModule oaapplicationmodule;
       int savedRangeStart = 0;
       int savedRangeSize = 25;
      
	   //Modified for R12 upgrade retrofit as part of Defect 25448
       //if(oapagecontext.getParameter("TrxListRemove") != null) {
       if(oapagecontext.getParameter("TrxListClear") != null) {    
          try {
          oapagecontext.writeDiagnostics(this,"##### Inside PFR TrxListClear",1);
            oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
            vo = (OAViewObject)oaapplicationmodule.findViewObject("TransactionListVO");
            savedRangeStart = vo.getRangeStart();
            savedRangeSize = vo.getRangeSize();
            oapagecontext.putSessionValue("ClearTransaction","TRUE");
          }
          catch(Exception _ex) {}
       }

       super.processFormRequest(oapagecontext, oawebbean);

	   //Modified for R12 upgrade retrofit as part of Defect 25448
       //if(oapagecontext.getParameter("TrxListRemove") != null) {
       if(oapagecontext.getParameter("TrxListClear") != null) {          
          try {
              oapagecontext.writeDiagnostics(this,"##### Inside PFR TrxListClear",1);          
            vo.setRangeSize(savedRangeSize);
            vo.setRangeStart(savedRangeStart);
            oapagecontext.putSessionValue("ClearTransaction","TRUE");
          }
          catch(Exception _ex) {}
       }
    }
}