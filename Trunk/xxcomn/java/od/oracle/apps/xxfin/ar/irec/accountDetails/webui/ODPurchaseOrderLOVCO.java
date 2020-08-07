/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxfin.ar.irec.accountDetails.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAViewObject;

//import java.util.Dictionary;
//import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.ar.irec.framework.webui.IROAControllerImpl;

/**
 * Controller for ...
 */
public class ODPurchaseOrderLOVCO extends IROAControllerImpl // OAControllerImpl
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
    initQuery(pageContext,webBean);
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
    initQuery(pageContext,webBean);
  }

  public void initQuery(OAPageContext oapagecontext, OAWebBean oawebbean)
  {
      String customerID   = (String) getActiveCustomerId(oapagecontext);
      String billToSiteID = (String) getActiveCustomerUseId(oapagecontext);

      OAViewObject vo = (OAViewObject)oapagecontext.getApplicationModule(oawebbean).findViewObject("ODPurchaseOrderVO1");
      vo.setWhereClauseParams(null);
      vo.setWhereClause(null);
      vo.setWhereClauseParam(0, customerID);   // customerID
      vo.setWhereClauseParam(1, billToSiteID); // billToSiteID
  }
}
