/*
  -- +===========================================================================+
  -- |                  Office Depot - Project Simplify                          |
  -- |                         Office Depot                                      |
  -- +===========================================================================+
  -- | Name        :  ODPurchasingBuyersCO                                       |
  -- | Rice id     :  Defect28000                                                |
  -- | Description :                                                             |
  -- | This is the controller for Setup -> Personnel -> Buyer                    |
  -- |                                                                           |
  -- |                                                                           |
  -- |                                                                           |
  -- |Change Record:                                                             |
  -- |===============                                                            |
  -- |Version  Date        Author               Remarks                          |
  -- |======== =========== ================     ================================ |
  -- |1.0      13-Feb-2014 Sridevi K            Modified for Defect28000         |
  -- |===========================================================================|
*/
package od.oracle.apps.xxfin.po.setup.webui;

import oracle.apps.po.setup.webui.PurchasingBuyersCO;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.table.OAAdvancedTableBean;
import oracle.apps.po.common.webui.ClientUtil;

public class ODPurchasingBuyersCO extends PurchasingBuyersCO {
    public ODPurchasingBuyersCO() {
    }
    
    public void processRequest(OAPageContext pageContext, OAWebBean webBean)
    {
		pageContext.writeDiagnostics(this, 
                                           "XXOD: Start od.oracle.apps.xxfin.po.setup.webui.ODPurchasingBuyersCO processRequest", 
                                           1);
        super.processRequest(pageContext, webBean);

		OAAdvancedTableBean advtableBean = (OAAdvancedTableBean)webBean.findIndexedChildRecursive("BuyerDetailTableRN");
        ClientUtil.setViewOnlyRecursive(pageContext, advtableBean);
		pageContext.writeDiagnostics(this, 
                                           "XXOD: End od.oracle.apps.xxfin.po.setup.webui.ODPurchasingBuyersCO processRequest", 
                                           1);
    }
}
