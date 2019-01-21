/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.errormgmt.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.OAApplicationModule;


/**
 * Controller for ...
 */
public class ErrResolutionCO extends OAControllerImpl
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
    // Added by Ambarish
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ("Y".equals(pageContext.getTransactionValue("resStepsCreateTxn")))
    {
      am.invokeMethod("rollbackResSteps");
      pageContext.removeTransactionValue("resStepsCreateTxn");
    }
    else if ("Y".equals(pageContext.getTransactionValue("resStepsUpdateTxn")))
    {
      am.invokeMethod("rollbackResSteps");
      pageContext.removeTransactionValue("resStepsUpdateTxn");
    }
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
    if (pageContext.getParameter("Create") != null)
    {
      // Navigate to the "Create Resolution Steps" page
      pageContext.setForwardURL( "OA.jsp?page=/od/oracle/apps/xxcrm/errormgmt/webui/ErrResCreatePG",
                                 null,
                                 OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                 null,
                                 null,
                                 true, //Retain AM
                                 OAWebBeanConstants.ADD_BREAD_CRUMB_YES,
                                 OAWebBeanConstants.IGNORE_MESSAGES );
      
    }
    

    else if ("update".equals(pageContext.getParameter(EVENT_PARAM)))
    {
      // Navigate to the "Create Resolution Steps" page
      pageContext.setForwardURL( "OA.jsp?page=/od/oracle/apps/xxcrm/errormgmt/webui/ErrResCreatePG",
                                 null,
                                 OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                 null,
                                 null,
                                 true, //Retain AM
                                 OAWebBeanConstants.ADD_BREAD_CRUMB_YES,
                                 OAWebBeanConstants.IGNORE_MESSAGES );
      
    }
                               
  }

}
