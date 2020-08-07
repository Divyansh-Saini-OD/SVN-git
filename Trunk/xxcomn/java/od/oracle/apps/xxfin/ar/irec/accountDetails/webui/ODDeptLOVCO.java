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

import oracle.apps.fnd.framework.webui.beans.table.OASortableHeaderBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;
import oracle.apps.fnd.framework.webui.beans.OAStaticStyledTextBean;

import java.util.Enumeration;
import oracle.cabo.ui.UINode;

/**
 * Controller for ...
 */
public class ODDeptLOVCO extends IROAControllerImpl // OAControllerImpl
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

   private String myEnum(UINode webBean, OAPageContext pageContext) {
    String sResult = "";
    Enumeration childNames = webBean.getChildNames(pageContext.getRenderingContext());

    String childName;
    if (childNames != null) {
       while (childNames.hasMoreElements()) {
         childName = (String)childNames.nextElement();
         sResult = sResult + myEnum(webBean.getNamedChild(pageContext.getRenderingContext(), childName),pageContext);
       }
    }
    int count = webBean.getIndexedChildCount();
    for (int i=0; i<count; i++) {
      UINode uiNode = webBean.getIndexedChild(i);
      sResult = sResult + uiNode.getLocalName() + ":" + uiNode.getClass().getName() + ";";
    }

    return sResult;
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

      OAViewObject vo = (OAViewObject)oapagecontext.getApplicationModule(oawebbean).findViewObject("ODDeptVO1");
      vo.setWhereClauseParams(null);
      vo.setWhereClause(null);
      vo.setWhereClauseParam(0, customerID);   // customerID
      vo.setWhereClauseParam(1, billToSiteID); // billToSiteID
  }
}
