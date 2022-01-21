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
public class ODConsBillLOVCO extends IROAControllerImpl // OAControllerImpl
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
//      Dictionary passiveCriteriaItems = oapagecontext.getLovCriteriaItems();
//      String customerID = (String) passiveCriteriaItems.get("XXcompany_id"); //"34049"
//      String billToSiteID = (String) passiveCriteriaItems.get("XXbill_to_site_id"); //"1537"

//      String customerID   = (String)oapagecontext.getDecryptedParameter(oapagecontext, "Ircustomerid"));
//      String billToSiteID = (String)oapagecontext.getDecryptedParameter(oapagecontext, "Ircustomersiteuseid"));

//      String customerID   = (String)oapagecontext.getParameter("Ircustomerid");
//      String billToSiteID = (String)oapagecontext.getParameter("Ircustomersiteuseid");

      String customerID   = (String) getActiveCustomerId(oapagecontext);
      String billToSiteID = (String) getActiveCustomerUseId(oapagecontext);

//    throw new OAException("hello world", OAException.ERROR);
//      companyID = "34049";
//      billToSiteID = "1537";
      OAViewObject vo = (OAViewObject)oapagecontext.getApplicationModule(oawebbean).findViewObject("ODConsBillVO1");
      vo.setWhereClauseParams(null);
      vo.setWhereClause(null);
      vo.setWhereClauseParam(0, customerID);   // customerID
      vo.setWhereClauseParam(1, billToSiteID); // billToSiteID
  }
}
