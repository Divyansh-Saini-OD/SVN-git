/*===========================================================================+
 |   Copyright (c) 2007 Office Depot, Delray Beach, FL, USA                  |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxfin.icx.webui;


import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.apps.po.common.webui.ClientUtil;


public class RoICXCatsCO extends ICXCatsCO
{
  
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
	pageContext.writeDiagnostics(this, "In Custom Controller Begin", 1);
	OATableBean tableBean = ((OATableBean)webBean.findIndexedChildRecursive("ResultsTable"));
    ClientUtil.setViewOnlyRecursive(pageContext, tableBean);
	pageContext.writeDiagnostics(this, "In Custom Controller End", 1);
  }
}

