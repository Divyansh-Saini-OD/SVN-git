/*===========================================================================+
 |   Copyright (c) 2007 Office Depot, Delray Beach, FL, USA                  |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
 //javadoc_private
package od.oracle.apps.xxfin.icx.webui;

//import od.oracle.apps.xxfin.icx.server.ICXCatsAMImpl;

//import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

/**
 * Controller for od.oracle.apps.xxfin.icx.webui.ODCatsPG
 * page.
 */

public class ICXCatsCO extends OAControllerImpl
{
  // Required for Applications source control
  public static final String RCS_ID="$Header: ICXCatsCO.java 115.9 2004/08/04 03:47:07 atgops1 noship $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "od.oracle.apps.xxfin.icx.webui");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
  if(pageContext.isLoggingEnabled(2))
        {
            pageContext.writeDiagnostics(this, "Inside Controller", 2);
        }
    super.processRequest(pageContext, webBean);
  } // end processRequest()

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean){   
    
    super.processFormRequest(pageContext, webBean);  

    if (pageContext.getParameter("Save") != null)
    {      
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      
      am.invokeMethod("apply"); 

      OAException confirmMessage = new OAException("Saved", OAException.CONFIRMATION);
      pageContext.putDialogMessage(confirmMessage);  // or:  throw new OAException(message, OAException.INFORMATION);

/*
      pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxfin/icx/webui/CategoryAttributesPG",
                                      null,
                                      OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                      null,
                                      null,
                                      true, // retain AM
                                      OAWebBeanConstants.ADD_BREAD_CRUMB_NO); 
*/

//        pageContext.putParameter("SearchOUApprover",pageContext.getUserName());
//         String OrgId = pageContext.getParameter("OrgId");
//         Serializable[] parameters = { OrgId };
//         OAApplicationModule am = pageContext.getApplicationModule(webBean);
//         am.invokeMethod("getCats", parameters);

//       String userContent = pageContext.getParameter("HelloName");      
//       String message = "Hello, " + userContent + "!";
//       throw new OAException(message, OAException.INFORMATION);
    }
  }
}

