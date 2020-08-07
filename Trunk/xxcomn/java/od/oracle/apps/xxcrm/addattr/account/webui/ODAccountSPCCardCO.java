/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.addattr.account.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.OARow;
import java.io.Serializable;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.OAException;
import com.sun.java.util.collections.HashMap;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
/**
 * Controller for ...
 */
public class ODAccountSPCCardCO extends OAControllerImpl
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
    OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);
    String event = pageContext.getParameter(EVENT_PARAM);
    if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
    {
      pageContext.writeDiagnostics("SPC CO:BEGIN", event, OAFwkConstants.STATEMENT);
    }
    if("saveChanges".equals(event))
    {
      am.invokeMethod("commitChanges");
      HashMap params = new HashMap();
      params.put("CustAcctId",pageContext.getParameter("CustAcctId"));
      params.put("AttrGrpId",pageContext.getParameter("AttrGrpId"));
      pageContext.forwardImmediatelyToCurrentPage(params,true,
                                      OAWebBeanConstants.ADD_BREAD_CRUMB_SAVE);
    }
    if("rollbackChanges".equals(event))
    {
      am.invokeMethod("rollbackChanges");
    }
    if("deleteSPCRow".equals(event))
    {
      String extnId = pageContext.getParameter("ExtnID");
      Serializable[] params = {extnId};
      am.invokeMethod("deleteSPCRow",params);
    }
  }

 



}
