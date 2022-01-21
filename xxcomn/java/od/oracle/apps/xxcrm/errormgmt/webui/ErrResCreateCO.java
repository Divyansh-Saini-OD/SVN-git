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
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import java.io.Serializable;

/**
 * Controller for ...
 */
public class ErrResCreateCO extends OAControllerImpl
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

    // Added By Ambarish
    // If isBackNavigationFires = false, we're here after a valid navigation 
    // and we should proceed normally.
    if (!pageContext.isBackNavigationFired(false))
    {
      // Put a value on the transaction cache indicating that create transaction
      // is now in progress. This value will persist as long as the root UI application 
      // module is retained.
      pageContext.putTransactionValue("resStepsCreateTxn","Y");
      am.invokeMethod("createResSteps");
    }
    else
    {
      if (!"Y".equals(pageContext.getTransactionValue("resStepsCreateTxn")))
      {
        // We got here through some use of the browser "Back" button, so we
        // want to display a stale data error and not allow access to the page

        OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
        pageContext.redirectToDialogPage(dialogPage);
        
      }
    }

    String resId = pageContext.getParameter("resId");
    pageContext.putTransactionValue("ResolutionId", resId);

    Serializable[] params = { resId };
    am.invokeMethod("initDetails", params);

    String applName = pageContext.getParameter("applName");
    pageContext.putTransactionValue("ApplicationName", applName);       
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
    
    if(pageContext.getParameter("Apply") != null)
    {
      
      try
      {
        am.invokeMethod("apply");
        OAException confirmMessage = new OAException("Record saved successfully!",OAException.CONFIRMATION );
        pageContext.putDialogMessage(confirmMessage);
      }
      catch (Exception e)
      {
        
        OAException confirmMessage = new OAException("Error : Unique combination of Application Name, Language Code and Message Name already exists.");
        pageContext.putDialogMessage(confirmMessage);
      }
      
      pageContext.removeTransactionValue("resStepsCreateTxn");
//      OAException confirmMessage = new OAException("BIS", "BIS_CREATE_MESSAGE",null,OAException.CONFIRMATION, null);
     

    }

    if(pageContext.getParameter("Cancel") != null)
    {
      am.invokeMethod("rollbackResSteps");
      // Navigate to Search Page
      // Navigate to the "Create Resolution Steps" page
      pageContext.setForwardURL( "OA.jsp?page=/od/oracle/apps/xxcrm/errormgmt/webui/ErrResolutionPG",
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
