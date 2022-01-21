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
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.jbo.domain.Number;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import java.io.Serializable;

import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;

/**
 * Controller for ...
 */
public class ODQuickLinksCreateCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");
  String respKey;

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
        int respId = pageContext.getResponsibilityId();
        Serializable[] parameters = { String.valueOf(respId) };
        OAApplicationModule am = pageContext.getApplicationModule(webBean);
        // respKey = (String) am.invokeMethod("getRespKey",parameters);
        if (!pageContext.isFormSubmission())
        {
        //pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM).equals("create")
        if ("create".equals(pageContext.getParameter(EVENT_PARAM))){
        am.invokeMethod("createQuickLinks", parameters);
        ((OAPageLayoutBean)webBean).setTitle("Create Quick Links");
        ((OAPageLayoutBean)webBean).setWindowTitle("Create Quick Links");
        }
        else if ("update".equals(pageContext.getParameter(EVENT_PARAM)))
        {
        String idParam = pageContext.getParameter("quickLinkId");
        Serializable[] parameter = { idParam };
        am.invokeMethod("updateQuickLinks", parameter);
        ((OAPageLayoutBean)webBean).setTitle("Update Quick Links");
        ((OAPageLayoutBean)webBean).setWindowTitle("Update Quick Links");
        }
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
    if (pageContext.getParameter("Apply") != null)
    {
    OAViewObject vo = (OAViewObject)am.findViewObject("ODDashboardQuickLinksDisplayVO1");
    Number quicklinkIdNum = (Number)vo.getCurrentRow().getAttribute("QuicklinkId");
    String quicklinkIdStr = String.valueOf(quicklinkIdNum.intValue());
    String label = (String)vo.getCurrentRow().getAttribute("Label");
    String Description = (String)vo.getCurrentRow().getAttribute("Description");
    Number orderOfDisp = (Number)vo.getCurrentRow().getAttribute("OrderOfDisplay");
    String orderOfDisplay = String.valueOf(orderOfDisp.intValue());
    String path = (String)vo.getCurrentRow().getAttribute("Path");
    String fullPath = (String)vo.getCurrentRow().getAttribute("FullPath");
    /*
    String respKey = (String)vo.getCurrentRow().getAttribute("RespKeyFv");
    pageContext.writeDiagnostics("SMJ","respKey:"+respKey,OAFwkConstants.STATEMENT);
    vo.getCurrentRow().setAttribute("ResponsibilityKey",respKey);
    String actRespKey = (String)vo.getCurrentRow().getAttribute("ResponsibilityKey");
    pageContext.writeDiagnostics("SMJ","actRespKey:"+actRespKey,OAFwkConstants.STATEMENT);
    */
    am.invokeMethod("apply");
    pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxcrm/bis/custom/webui/ODQuickLinksMaintainPG",
                                 null,
                                 OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                 null,
                                 null,
                                 false, // do not retain AM
                                 OAWebBeanConstants.ADD_BREAD_CRUMB_NO);
   }
    else if (pageContext.getParameter("Cancel") != null)
    {
    am.getOADBTransaction().rollback();
    pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxcrm/bis/custom/webui/ODQuickLinksMaintainPG",
                                 null,
                                 OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                 null,
                                 null,
                                 false, // do not retain AM
                                 OAWebBeanConstants.ADD_BREAD_CRUMB_NO);
    }
  }

}
