package od.oracle.apps.xxcrm.ar.hz.relman.webui;

import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.po.common.webui.ClientUtil;
import oracle.apps.ar.hz.relman.webui.HzRmCreateRelCO;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.apps.fnd.framework.webui.beans.table.OAAddTableRowBean;
import oracle.apps.fnd.framework.webui.beans.layout.OARowLayoutBean;

public class ODHzRmCreateRelCO extends HzRmCreateRelCO{
	public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
	pageContext.writeDiagnostics(this, "In Custom Controller Begin", 1);
    ClientUtil.setViewOnlyRecursive(pageContext, webBean);
	OATableBean tableBean = ((OATableBean)webBean.findIndexedChildRecursive("CreateRelTable"));
	OAAddTableRowBean addRowBean = (OAAddTableRowBean)tableBean.getColumnFooter();
	addRowBean.setRendered(false);
    pageContext.writeDiagnostics(this, "In Custom Controller End", 1);
  }
}