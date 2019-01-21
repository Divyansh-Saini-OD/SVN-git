/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.stl.admin.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants; 
/**
 * Controller for ...
 */
public class ODRepStoreCrteCO extends OAControllerImpl
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
         if (!pageContext.isFormSubmission())
    {
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      am.invokeMethod("createMapping", null);
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
        OAApplicationModule am = pageContext.getApplicationModule(webBean);
    
     if (pageContext.getParameter("Save") != null) {
 
             am.invokeMethod("apply",null );
    
                pageContext.forwardImmediately( "OA.jsp?page=/od/oracle/apps/xxcrm/stl/admin/webui/ODRepStoreSrchPG", null, 
                                               OAWebBeanConstants.KEEP_MENU_CONTEXT, 
                                               null, null, true, 
                                               OAWebBeanConstants.ADD_BREAD_CRUMB_YES);
  

    }
    else if (pageContext.getParameter("Cancel") != null) {
      am.invokeMethod("cancel",null );
       String URL =    "OA.jsp?page=/od/oracle/apps/xxcrm/stl/admin/webui/ODRepStoreSrchPG";
            System.out.println(URL); // retain AM
                pageContext.forwardImmediately(URL, null, 
                                               OAWebBeanConstants.KEEP_MENU_CONTEXT, 
                                               null, null, true, 
                                               OAWebBeanConstants.ADD_BREAD_CRUMB_YES);
  

    }

  }

}
