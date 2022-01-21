/*===========================================================================+
 |      		       Office Depot - Project Simplify                       |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODCDHEntStatCO.java                                           |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Controller Class to view the concurrent request for the                |
 |     program - OD: CDH TCA Entities Statistical Info Program               |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    01/13/2009     Sathya Prabha Rani       Created                        |
 |                                                                           |
 +===========================================================================*/

package od.oracle.apps.xxcrm.cdh.reports.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import java.io.Serializable;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.OAException;

/**
 * Controller for ...
 */
public class ODCDHEntStatCO extends OAControllerImpl
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
    
       
    if (pageContext.getParameter("RprtBtn") != null) 
    {
        Serializable params[] = {"XXCDHTCASTAT"};
        
        String requestId = (String)am.invokeMethod("runReport", params);
        if(requestId != null)
        {
           String url = "OA.jsp?akRegionCode=FNDCPREQUESTVIEWPAGE&akRegionApplicationId=0&requestId="+requestId;

           pageContext.setForwardURL(url,
                                     null,
                                     OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                     null,
                                     null,// parameters,
                                     true,
                                     OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
                                     OAWebBeanConstants.IGNORE_MESSAGES);
        } else
        {
            OAHeaderBean head = (OAHeaderBean)webBean.findChildRecursive("HeaderRN");
            ((OAPageLayoutBean)webBean).removeIndexedChild(0);
            ((OAPageLayoutBean)webBean).prepareForRendering(pageContext);
            throw new OAException("The report OD: CDH TCA Entities Statistical Info Program has not yet been run");
        }
    }
  }
}
