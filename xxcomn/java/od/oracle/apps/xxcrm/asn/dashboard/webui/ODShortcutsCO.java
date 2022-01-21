/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.dashboard.webui;

import oracle.apps.fnd.common.VersionInfo;

import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.asn.dashboard.webui.ShortcutsCO;
import oracle.apps.fnd.framework.OAFwkConstants;

/**
 * Controller for ...
 */
public class ODShortcutsCO extends ShortcutsCO
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
    final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.dashboard.webui.ODShortcutsCO.processRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }
    super.processRequest(pageContext, webBean);
    pageContext.writeDiagnostics(METHOD_NAME, "Setting the value ASNTxnCallingPage to DASHBOARD in processRequest  ", OAFwkConstants.PROCEDURE);  
    pageContext.removeSessionValue("ASNTxnCallingPage");
   
    pageContext.putSessionValue("ASNTxnCallingPage","DASHBOARD");
   

     if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
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
  final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.dashboard.webui.ODShortcutsCO.processFormRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }
    super.processFormRequest(pageContext, webBean);
   
     if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }
  }

}
