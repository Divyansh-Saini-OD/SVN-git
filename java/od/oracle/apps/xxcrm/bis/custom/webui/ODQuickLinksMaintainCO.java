/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.bis.custom.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.OAApplicationModule;
import com.sun.java.util.collections.HashMap;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
import java.io.Serializable;


/**
 * Controller for ...
 */
public class ODQuickLinksMaintainCO extends OAControllerImpl
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
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    OAViewObject vo = (OAViewObject)am.findViewObject("ODDashboardQuickLinksDisplayVO1");
    am.invokeMethod("initializeQuicklinksVO");
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
        if ("create".equals(pageContext.getParameter(EVENT_PARAM)) )
    {
      pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxcrm/bis/custom/webui/ODQuickLinksCreatePG",
                                null,
                                OAWebBeanConstants.KEEP_MENU_CONTEXT, 
                                null,
                                null,
                                true, // Retain AM
                                OAWebBeanConstants.ADD_BREAD_CRUMB_YES,
                                OAWebBeanConstants.IGNORE_MESSAGES);
    } 
    else if ("delete".equals(pageContext.getParameter(EVENT_PARAM)))
    {
      String idParam = pageContext.getParameter("quickLinkId");
      Serializable[] parameters = { idParam };
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      am.invokeMethod("deleteQuickLinks", parameters);
    }
    else if ("update".equals(pageContext.getParameter(EVENT_PARAM)))
    {  
    pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxcrm/bis/custom/webui/ODQuickLinksCreatePG",
                              null,
                              OAWebBeanConstants.KEEP_MENU_CONTEXT,
                              null,
                              null,
                              true, // Retain AM
                              OAWebBeanConstants.ADD_BREAD_CRUMB_NO, // Do not display breadcrumbs
                              OAWebBeanConstants.IGNORE_MESSAGES);
    }

  }

}
