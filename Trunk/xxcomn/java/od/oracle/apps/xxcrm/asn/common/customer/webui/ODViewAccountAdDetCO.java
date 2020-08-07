/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.common.customer.webui;


import java.io.Serializable;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;


/**
 * Controller for ...
 */
public class ODViewAccountAdDetCO extends OAControllerImpl
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

   //   OATableBean  mytable = (OATableBean) webBean.findChildRecursive("AccountDetailsTBL");

  //   OATableBean  mytable = (OATableBean) webBean.findChildRecursive("region1");

  // OAMessageTextInputBean mytextbox = (OAMessageTextInputBean) mytable.findChildRecursive("AttributeVal");

 // Taking parameters from page context and invoking AM method fireVO with parameters
      String party_id = pageContext.getParameter("partyId");
      String custAccRoleId =  pageContext.getParameter("custAccRoleId");

      Serializable[] parameters = {custAccRoleId,party_id};
      am.invokeMethod("fireVO",parameters);
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
