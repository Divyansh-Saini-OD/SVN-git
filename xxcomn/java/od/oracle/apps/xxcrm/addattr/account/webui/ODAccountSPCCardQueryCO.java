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
import java.io.Serializable;
import oracle.apps.fnd.framework.OAException;

/**
 * Controller for ...
 */
public class ODAccountSPCCardQueryCO extends OAControllerImpl
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
    initParams(pageContext, webBean);
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

 /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public static void initParams(OAPageContext pageContext, OAWebBean webBean)
  {
    OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);
    /**
     * Code to obtain the function parameters passed to this page
     */
      String custAcctId   = pageContext.getParameter("CustAcctId");
      if("".equals(custAcctId))
        custAcctId = null;      
      String attrGrpId = pageContext.getParameter("AttrGrpId");
      if("".equals(attrGrpId))
        attrGrpId = null;
      if(custAcctId== null || attrGrpId==null)
      {
        throw new OAException("Unable to initialize page as either the Customer Account ID or the Attribute Group ID is invalid.");
      }
      Serializable[] params = {attrGrpId,custAcctId};
      am.invokeMethod("initSPCVO",params);
  }
  

}
