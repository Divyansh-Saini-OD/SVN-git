package od.oracle.apps.xxfin.po.setup.webui;

import oracle.apps.po.setup.webui.CntrlPurchasingPeriodCO;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.po.common.webui.ClientUtil;
import oracle.apps.fnd.framework.webui.beans.table.OAAdvancedTableBean;


public class ODRoCntrlPurchasingPeriodCO extends CntrlPurchasingPeriodCO
{

    public ODRoCntrlPurchasingPeriodCO()
    {
    }

    public void processRequest(OAPageContext pageContext, OAWebBean webBean)
    {
		pageContext.writeDiagnostics(this, "od.oracle.apps.xxfin.po.setup.webui.ODRoCntrlPurchasingPeriodCO processRequest", 1);
        super.processRequest(pageContext, webBean);

		OAAdvancedTableBean advtableBean = (OAAdvancedTableBean)webBean.findIndexedChildRecursive("PurchPrdTableResultsRN");
        ClientUtil.setViewOnlyRecursive(pageContext, advtableBean);
		pageContext.writeDiagnostics(this, "od.oracle.apps.xxfin.po.setup.webui.ODRoCntrlPurchasingPeriodCO processRequest", 1);
    }
}