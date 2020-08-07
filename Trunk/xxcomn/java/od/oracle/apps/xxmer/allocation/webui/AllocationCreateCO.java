/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxmer.allocation.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import java.io.Serializable;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
/**
 * Controller for ...
 */
public class AllocationCreateCO extends OAControllerImpl
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
     String all = "false";
     String batchNbr = pageContext.getParameter("batchNo");      
     Serializable[] parmsList = {batchNbr,all};
     OAApplicationModule am = pageContext.getApplicationModule(webBean);
       am.invokeMethod("initPOCreateList",parmsList);
        OAMessageChoiceBean poplist = (OAMessageChoiceBean)webBean.findChildRecursive("PO");
         
      // poplist.setSelectedIndex(0);
        am.invokeMethod("initCreateAllocLine");
       
       am.invokeMethod("initCreatePPRVO");
     
    
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
    if("shipToChange".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))){
      am.invokeMethod("handleShipToChangeEvent");
    }
    if("locationChange".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))){
      System.out.println("loc change");
      am.invokeMethod("handleLocChangeEvent");
    }
    if(pageContext.getParameter("Apply")!= null)
    {
      am.invokeMethod("apply");
      am.invokeMethod("refreshDetail");
     
      pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxmer/allocation/webui/AllocationPG&retainAM=Y",
null,
  OAWebBeanConstants.KEEP_MENU_CONTEXT,
  null,
  null,
  true, // Retain AM
  OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
  OAWebBeanConstants.IGNORE_MESSAGES);
        
    }
        if(pageContext.getParameter("Cancel")!= null)
    {
     am.invokeMethod("refreshDetail");
     
   
      pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxmer/allocation/webui/AllocationPG&retainAM=Y",
null,
  OAWebBeanConstants.KEEP_MENU_CONTEXT,
  null,
  null,
  true, // Retain AM
  OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
  OAWebBeanConstants.IGNORE_MESSAGES);
        
    }
    }
  

}
