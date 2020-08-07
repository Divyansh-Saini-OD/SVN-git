package od.oracle.apps.xxcrm.cdh.extension.webui;
/*===========================================================================+
 |   Copyright (c) 2001, 2003 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.po.common.webui.ClientUtil;

public class ODRoAttributeExtRnCO extends ODAttributeExtRnCO
{
	public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
		pageContext.putParameter("HzPuiExtMode","VIEW");
		super.processRequest(pageContext, webBean);
		
  }
}