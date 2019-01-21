/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.mps.reports.webui;

import java.io.Serializable;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;

/**
 * Controller for ...
 */
public class XXCSMPSDevicThresholdReportCO extends OAControllerImpl
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
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if(pageContext.getParameter("SearchBtn") != null) 
    {
        System.out.println("Inside search button click event");
        String customerName = pageContext.getParameter("CustomerName");
        String activeStatus = pageContext.getParameter("ActiveStatus");
        
        System.out.println("customerName: " + customerName);
        System.out.println("activeStatus: " + activeStatus);
        
        Serializable[] params = { customerName, activeStatus };
        am.invokeMethod("initMPSDeviceThresholdVO", params);
    }
    if(pageContext.getParameter("ClearBtn") != null) 
    {
        System.out.println("Clear button event");
        
        OAMessageLovInputBean custNamBean = (OAMessageLovInputBean)webBean.findChildRecursive("CustomerName");
        OAMessageTextInputBean activeStatusBean = (OAMessageTextInputBean)webBean.findChildRecursive("ActiveStatus");
        
        if(custNamBean != null)
          custNamBean.setValue(pageContext, "");
        if(activeStatusBean != null)
          activeStatusBean.setValue(pageContext, "");
          
        Serializable[] params1 = { "-1", "-1" };
        am.invokeMethod("initMPSDeviceThresholdVO", params1);
    }
  }

}
