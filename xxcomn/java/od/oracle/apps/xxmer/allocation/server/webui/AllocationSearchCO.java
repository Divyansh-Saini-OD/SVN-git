/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxmer.allocation.server.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;

/**
 * Controller for ...
 */
public class AllocationSearchCO extends OAControllerImpl
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
  //Retrieve PO Number if Entered  
  
  /*
   OAQueryBean queryBean = (OAQueryBean)webBean.findChildRecursive("AllocationListRN");
  String Go = queryBean.getGoButtonName();
  if(pageContext.getParameter(Go) != null) {  
   OAQueryUtils.checkSelectiveSearchCriteria(pageContext, webBean);
   // Get the user's search criteria from the request.
   
 }*/
 if("view".equals(pageContext.getParameter(EVENT_PARAM)))
 {
    System.out.println("Nav to New page"); 
/*
    String po = pageContext.getParameter("SearchPO");
   System.out.println("PO: "+ po);
   ;*/
   pageContext.putParameter("PO", pageContext.getParameter("PO"));
  pageContext.putParameter("batchNO",pageContext.getParameter("batchNbr"));



pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxmer/allocation/webui/AllocationPG",
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
