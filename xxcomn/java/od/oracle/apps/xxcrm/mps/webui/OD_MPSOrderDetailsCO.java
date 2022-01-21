/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.mps.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.apps.fnd.framework.webui.OADataBoundValueViewObject;
import oracle.apps.fnd.framework.webui.beans.nav.OALinkBean;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import java.io.Serializable;
/**
 * Controller for ...
 */
public class OD_MPSOrderDetailsCO extends OAControllerImpl
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
    OAApplicationModule mpsCustContAM = pageContext.getApplicationModule(webBean);
    pageContext.putSessionValue("deviceId", pageContext.getParameter("deviceId"));
    pageContext.putSessionValue("partyId", pageContext.getParameter("partyId"));
    pageContext.putSessionValue("serialNo", pageContext.getParameter("serialNo"));
    System.out.println("##### PR OrderDetailsCO from="+pageContext.getParameter("FROM"));
    if(pageContext.getParameter("FROM") != null && "SERIALN0".equals(pageContext.getParameter("FROM")))
    pageContext.putSessionValue("FROM", pageContext.getParameter("FROM").toString());

    OATableBean tblBean = (OATableBean)webBean.findChildRecursive("OrderDetails");
    if(tblBean != null)
    tblBean.setText(tblBean.getText()+" "+pageContext.getParameter("serialNo"));
    Serializable[] params = {pageContext.getParameter("serialNo"), pageContext.getParameter("partyId")};
    mpsCustContAM.invokeMethod("initOrderDetails",params);

    OATableBean tableBean = (OATableBean)webBean.findChildRecursive("OrderDetails");
    OALinkBean linkBean = (OALinkBean) webBean.findIndexedChildRecursive("GmillLink");
    OADataBoundValueViewObject tip1 = new OADataBoundValueViewObject(linkBean, "GmillLink");
    linkBean.setAttributeValue(oracle.cabo.ui.UIConstants.DESTINATION_ATTR, tip1); 
    
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
    if("back".equals(pageContext.getParameter(EVENT_PARAM))){
      System.out.println("##### PFR OrderDetailsCO from="+pageContext.getParameter("FROM"));
      com.sun.java.util.collections.HashMap params = new com.sun.java.util.collections.HashMap(2);
      params.put("deviceId",pageContext.getSessionValue("deviceId"));
      params.put("partyId",pageContext.getSessionValue("partyId"));
      params.put("serialNo",pageContext.getSessionValue("serialNo"));
      if(pageContext.getSessionValue("FROM")!=null && "SERIALN0".equals(pageContext.getParameter("FROM")))
      params.put("FROM",pageContext.getSessionValue("FROM"));
      pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxcrm/mps/webui/OD_MPSCustomerLocationUpdatePG",
                                null,
                                OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                null,
                                params,
                                false, // Retain AM
                                OAWebBeanConstants.ADD_BREAD_CRUMB_NO, OAWebBeanConstants.IGNORE_MESSAGES);      
    }     
  }

}
