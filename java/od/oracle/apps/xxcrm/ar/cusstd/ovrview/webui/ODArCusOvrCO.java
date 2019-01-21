package od.oracle.apps.xxcrm.ar.cusstd.ovrview.webui;

import oracle.apps.ar.cusstd.ovrview.webui.ArCusOvrCO;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.po.common.webui.ClientUtil;

public class ODArCusOvrCO extends ArCusOvrCO {
    public ODArCusOvrCO() {
    }
    public void processRequest(OAPageContext pageContext, OAWebBean webBean)
    {
        super.processRequest(pageContext, webBean);
        pageContext.writeDiagnostics(this, "In Custom Controller Begin" , 1);
        ClientUtil.setViewOnlyRecursive(pageContext, webBean);
        pageContext.writeDiagnostics(this, "In Custom Controller End" , 1);
    }    
}
