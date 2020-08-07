/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.cs.csz.globalactions.webui;

import oracle.apps.cs.csz.globalactions.webui.*;
import java.io.Serializable;
import oracle.apps.cs.csz.common.*;
import oracle.apps.cs.csz.globalactions.server.ERecordIDVOImpl;
import oracle.apps.cs.csz.globalactions.server.ERecordIDVORowImpl;
import oracle.apps.cs.csz.incident.server.SRAMImpl;
import oracle.apps.cs.csz.incident.webui.eventhandler.SRGlobalActionsEventHandler;
import oracle.apps.cs.csz.oa.webui.CszUpdateControllerImpl;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.*;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAUrl;
import oracle.apps.fnd.framework.webui.beans.OAScriptBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.jbo.domain.Number;
import oracle.jbo.server.ApplicationModuleImpl;

import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;

/**
 * Controller for ...
 */
public class ODGlobalActionsCO extends GlobalActionsCO
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);

        OASubmitButtonBean oasubmitbuttonbean = (OASubmitButtonBean)webBean.findChildRecursive("SREscBtn");
        if(oasubmitbuttonbean != null)
                  oasubmitbuttonbean.setRendered(false);
  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormRequest(pageContext, webBean);
  }

  //Rajeev 12/9/2014
  private void displaySREscButton(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
   
        OASubmitButtonBean oasubmitbuttonbean = (OASubmitButtonBean)oawebbean.findChildRecursive("SREscBtn");
        if(oasubmitbuttonbean != null)
                  oasubmitbuttonbean.setRendered(false);
    }


}
