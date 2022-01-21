/*
  -- +===========================================================================+
  -- |                  Office Depot - Project Simplify                          |
  -- |                         Office Depot                                      |
  -- +===========================================================================+
  -- | Name        :  ODPurchasingOptionsCO.java                                 |
  -- | Rice id     :  Defect28000                                                |
  -- | Description :                                                             |
  -- | This is the controller for                                                |
  -- | View Setup -> Organizations -> Purchasing Parameters                      |
  -- |                                                                           |
  -- |                                                                           |
  -- |                                                                           |
  -- |Change Record:                                                             |
  -- |===============                                                            |
  -- |Version  Date        Author               Remarks                          |
  -- |======== =========== ================     ================================ |
  -- |1.0      13-Feb-2014 Sridevi K            Created for Defect28000          |
  -- |===========================================================================|
*/
package od.oracle.apps.xxfin.po.setup.webui;

import oracle.apps.po.setup.webui.PurchasingOptionsCO;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.po.common.webui.ClientUtil;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;

public class ODPurchasingOptionsCO extends PurchasingOptionsCO {
    public ODPurchasingOptionsCO() {
    }
    
    public void processRequest(OAPageContext pageContext, OAWebBean webBean)
    {
		pageContext.writeDiagnostics(this, 
                                           "XXOD: Start od.oracle.apps.xxfin.po.setup.webui.ODPurchasingOptionsCO processRequest", 
                                           1);
        super.processRequest(pageContext, webBean);

		OAHeaderBean header1 = (OAHeaderBean) webBean.findIndexedChildRecursive("DocumentControlRN");
		OAHeaderBean header2 = (OAHeaderBean) webBean.findIndexedChildRecursive("DocumentDefaultsRN");
		OAHeaderBean header3 = (OAHeaderBean) webBean.findIndexedChildRecursive("ReceiptAccountingRN");
		OAHeaderBean header4 = (OAHeaderBean) webBean.findIndexedChildRecursive("DocumentNumberingRN");
		OAHeaderBean header5 = (OAHeaderBean) webBean.findIndexedChildRecursive("AdditionalInfoRN");
		
        ClientUtil.setViewOnlyRecursive(pageContext, header1);
		ClientUtil.setViewOnlyRecursive(pageContext, header2);
		ClientUtil.setViewOnlyRecursive(pageContext, header3);
		ClientUtil.setViewOnlyRecursive(pageContext, header4);
		ClientUtil.setViewOnlyRecursive(pageContext, header5);

		pageContext.writeDiagnostics(this, 
                                           "XXOD: End od.oracle.apps.xxfin.po.setup.webui.ODPurchasingOptionsCO processRequest", 
                                           1);
    }
}
