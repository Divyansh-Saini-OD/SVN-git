/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.errorhandler.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import java.io.Serializable;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.common.MessageToken;
//import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;

/**
 * Controller for ...
 */
public class ErrorResolutionCO extends OAControllerImpl
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
    // Get the messageName parameter from the URL
    String messageName = pageContext.getParameter("messageName");
    // Now we want to initialize the query for resolution
    // with all of its details.
    OAApplicationModule am =  pageContext.getApplicationModule(webBean);
    Serializable[] parameters = { messageName };
    am.invokeMethod("initDetails", parameters);
    
   // -- to display the message name
   // Always use a translated value from Message Dictionary when setting
   // strings in your controllers.
   // Instantiate an array of message tokens and set the value for the
   // EMP_NAME token.
   MessageToken[] tokens = { new MessageToken("MESSAGE_CODE", messageName)};
   // Now, get the translated message text including the token value.
   //String pageHeaderText = pageContext.getMessage("AK", "FWK_TBX_T_EMP_HEADER_TEXT", tokens);
   // Set the employee-specific page title (which also appears in
   // the breadcrumbs). Note that we know this controller is
   // associated wit the pageLayout region, which is why we cast the
   // webBean to an OAPageLayoutBean before calling setTitle.
  //((OAPageLayoutBean)webBean).setTitle(pageHeaderText);

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

}
