package od.oracle.apps.xxcrm.ar.hz.relman.webui;

import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.po.common.webui.ClientUtil;
import oracle.apps.ar.hz.relman.webui.HzRmEditRelCO;

public class ODHzRmEditRelCO extends HzRmEditRelCO{
	public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
	pageContext.writeDiagnostics(this, "In Custom Controller Begin", 1);
    ClientUtil.setViewOnlyRecursive(pageContext, webBean);
    pageContext.writeDiagnostics(this, "In Custom Controller End", 1);
  }
}