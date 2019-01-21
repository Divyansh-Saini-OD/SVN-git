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
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import java.io.Serializable;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.OAException;

/**
 * Controller for ...
 */
public class AllocationCO extends OAControllerImpl
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
    System.out.println("AllocationPG");
    if(pageContext.getParameter("batchNO")!=null){
      
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
    
      String batchNbr =pageContext.getParameter("batchNO");
      String PO = pageContext.getParameter("PO");
      System.out.println(batchNbr);
      String all = "true";
       Serializable[] parms = {batchNbr};
        am.invokeMethod("initHeader",parms);
       Serializable[] parmsList = {batchNbr,all};

      OAMessageChoiceBean poplist = (OAMessageChoiceBean)webBean.findChildRecursive("PO"); 
      poplist.clearIndexedChildren();
       am.invokeMethod("initPOList",parmsList);
      Serializable[] parm2 = {batchNbr,PO};
       am.invokeMethod("initDetail",parm2);
      

      
      if(PO!=null)
      {
      
        poplist.setSelectionValue(pageContext,PO);
        
      }else{
        poplist.setSelectionValue(pageContext,"< All POs >");
        
      }
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
    super.processFormRequest(pageContext, webBean);
     OAApplicationModule am = pageContext.getApplicationModule(webBean);
     
    if("refreshView".equals(pageContext.getParameter(EVENT_PARAM)))
    {
      OAMessageChoiceBean poplist = (OAMessageChoiceBean)webBean.findChildRecursive("PO");
      String batchNbr =pageContext.getParameter("batchNO");
      String PO =   poplist.getSelectionValue(pageContext);
        if(PO==null){
        PO = "";
        }
       Serializable[] parm2 = {batchNbr,PO};
       am.invokeMethod("initDetail",parm2);
     
    }
    if(pageContext.getParameter("Apply")!=null)
    {
      am.invokeMethod("apply");
      am.invokeMethod("refreshHeader");
    }
    if("create".equals(pageContext.getParameter(EVENT_PARAM)))
    {
      
pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxmer/allocation/webui/AllocationCreatePG&retainAM=Y",
null,
  OAWebBeanConstants.KEEP_MENU_CONTEXT,
  null,
  null,
  true, // Retain AM
  OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
  OAWebBeanConstants.IGNORE_MESSAGES);
        
    }
    if(pageContext.getParameter("Delete")!=null)
    {
      Serializable all = am.invokeMethod("deleteSelected");
      String allDeleted = (String) all;
      System.out.println(allDeleted);
      if(allDeleted.equals("true"))
      {OAException message= new OAException("All Deleted");
        OADialogPage dialogPage = new OADialogPage(OAException.INFORMATION,message,null,"","");
        dialogPage.setOkButtonItemName("DeleteAll");
        dialogPage.setOkButtonToPost(true);
        dialogPage.setPostToCallingPage(true);
        dialogPage.setOkButtonLabel("Continue");
        
        
        pageContext.redirectToDialogPage(dialogPage);
      }

    }
    if(pageContext.getParameter("DeleteAll")!=null)
    {
    pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxmer/allocation/webui/AllocationSearchPG&retainAM=Y",
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
