/*
  -- +===========================================================================+
  -- |                  Office Depot - Project Simplify                          |
  -- |                         Office Depot                                      |
  -- +===========================================================================+
  -- | Name        :  ODUnNumbersCO                                              |
  -- | Rice id     :  Defect28000                                                |
  -- | Description :                                                             |
  -- | This is the controller for Setup -> Purchasing -> UN Numbers              |
  -- |                                                                           |
  -- |                                                                           |
  -- |                                                                           |
  -- |Change Record:                                                             |
  -- |===============                                                            |
  -- |Version  Date        Author               Remarks                          |
  -- |======== =========== ================     ================================ |
  -- |1.0      14-Feb-2014 Sridevi K            Modified for Defect28000         |
  -- |===========================================================================|
*/
package od.oracle.apps.xxfin.po.setup.webui;

import oracle.apps.po.setup.webui.UnNumbersCO;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.table.OAAdvancedTableBean;
import oracle.apps.po.common.webui.ClientUtil;

public class ODUnNumbersCO extends UnNumbersCO {
    public ODUnNumbersCO() {
    }
    
    public void processRequest(OAPageContext pageContext, OAWebBean webBean)
    {
		pageContext.writeDiagnostics(this, 
                                           "XXOD: Start od.oracle.apps.xxfin.po.setup.webui.ODUnNumbersCO processRequest", 
                                           1);
        super.processRequest(pageContext, webBean);

		OAAdvancedTableBean advtableBean = (OAAdvancedTableBean)webBean.findIndexedChildRecursive("advancedTableRN");
        ClientUtil.setViewOnlyRecursive(pageContext, advtableBean);
		pageContext.writeDiagnostics(this, 
                                           "XXOD: End od.oracle.apps.xxfin.po.setup.webui.ODUnNumbersCO processRequest", 
                                           1);
    }
}
