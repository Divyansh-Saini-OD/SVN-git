package od.oracle.apps.fnd.wf.builder.webui;

import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.wf.builder.webui.WorkflowsLovRGCO;

public class XXODWorkflowsLovRGCO extends WorkflowsLovRGCO {
    public XXODWorkflowsLovRGCO() {
    }
    
    public void processRequest(OAPageContext paramOAPageContext, OAWebBean paramOAWebBean) {
        super.processRequest(paramOAPageContext, paramOAWebBean);
        paramOAPageContext.writeDiagnostics(this, "In XXODWorkflowsLovRGCO", 2);
        paramOAPageContext.writeDiagnostics(this, "Responsibility is: " + paramOAPageContext.getResponsibilityName(), 2);
        paramOAPageContext.writeDiagnostics(this, "Responsibility is: " + paramOAPageContext.getResponsibilityId(), 2);
        
        if("OD PO Superuser Non-Trade".equals(paramOAPageContext.getResponsibilityName())) {
            paramOAPageContext.writeDiagnostics(this, "Lov values should be: PO Requisition Approval, PO Approval", 2);
            OAViewObject localOAViewObject = (OAViewObject)paramOAPageContext.getApplicationModule(paramOAWebBean).findViewObject("WorkflowItemTypesLOVVO");
            paramOAPageContext.writeDiagnostics(this, "set where clause: display_name IN ('PO Requisition Approval', 'PO Approval') ", 2);
            if(localOAViewObject!=null) {
                localOAViewObject.setWhereClause(null);
                localOAViewObject.setWhereClauseParams(null);
                localOAViewObject.setWhereClause(" display_name IN ('PO Requisition Approval', 'PO Approval') ");
                //localOAViewObject.executeQuery();
            }
        }
    }
    
    public void processFormRequest(OAPageContext paramOAPageContext, OAWebBean paramOAWebBean) {
        super.processFormRequest(paramOAPageContext, paramOAWebBean);
    }
}
