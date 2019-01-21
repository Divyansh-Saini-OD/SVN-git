/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.cdh.reports.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.xdo.oa.common.DocumentHelper;
import oracle.apps.fnd.framework.OAApplicationModule;
import java.io.Serializable;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;

/**
 * Controller for ...
 */
public class ODCDHConvStatsReportCO extends OAControllerImpl
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
    pageContext.putParameter("p_DataSource",DocumentHelper.DATA_SOURCE_TYPE_REQUEST_ID);
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    Serializable[] params = {"XXCDHCONVSTATSREP"};
    String requestId = (String)am.invokeMethod("runReport",params);
    if(requestId !=null)
    {
    pageContext.putParameter("p_RequestID",requestId);
    pageContext.putParameter("p_XDORegionHeight","600%");
    }
    else
    {
      OAHeaderBean head =  (OAHeaderBean)webBean.findChildRecursive("HeaderRN");
      ((OAPageLayoutBean)(webBean)).removeIndexedChild(0);
      ((OAPageLayoutBean)(webBean)).prepareForRendering(pageContext);
      throw new OAException("The report has not yet been run");
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
  }

}
