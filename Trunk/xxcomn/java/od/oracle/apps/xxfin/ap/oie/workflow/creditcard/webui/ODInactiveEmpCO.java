package od.oracle.apps.xxfin.ap.oie.workflow.creditcard.webui;

import oracle.apps.ap.oie.workflow.creditcard.webui.InactiveEmpCO;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;

public class ODInactiveEmpCO extends InactiveEmpCO {
    public ODInactiveEmpCO() {
    }

    public void processRequest(OAPageContext pageContext, OAWebBean webBean)
    {
      super.processRequest(pageContext, webBean);

        String instMsg = pageContext.getMessage("XXFIN", "OD_OIE_INACT_INSTRUCTIONS", null);
        //"Click Accept in order to be able to create and submit expense report(s) for the inactive employee listed above. In order to submit an expense report for the terminated employee, please sign in to OD iExpenses , click Create Expense Report and select the terminated employee’s name from the drop down list of values in the Name field."; 
        OAMessageStyledTextBean instBn = (OAMessageStyledTextBean)webBean.findIndexedChildRecursive("Instructions");
        if (instBn != null && instMsg != null)
        {
            instBn.setText(instMsg);
            instBn.setCSSClass("OraInstructionText");
        }      
    }    
}
