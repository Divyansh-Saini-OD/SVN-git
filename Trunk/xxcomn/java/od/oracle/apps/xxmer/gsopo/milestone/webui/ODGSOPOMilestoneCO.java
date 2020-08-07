/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxmer.gsopo.milestone.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.OAApplicationModule;
import java.io.Serializable;

/**
 * Controller for ...
 */
public class ODGSOPOMilestoneCO extends OAControllerImpl
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
    /*
     * The below value is coming from PO page, which is parent 
     * of this page.
     */
    String poHeaderId = pageContext.getParameter("poHeaderId")==null?"1234":pageContext.getParameter("poHeaderId");//"1234";
    Serializable poHdrId[] = {poHeaderId};
    /*
     * Below session value will be set if user click on Add or View attachments
     * And using to avoid the VO object execution in this case
     */
    String getAttachSessionValue = (String)pageContext.getSessionValue("ReturnFromAttachement");

    if((getAttachSessionValue!= null && getAttachSessionValue.equalsIgnoreCase("Y"))) 
    {
        pageContext.putSessionValue("ReturnFromAttachement", "N");
    }
    else
    {
      /*
       * Calling AM method to execute the ODmilestoneInfoVO for 
       * default initialization
       */
      am.invokeMethod("initDetailsMilestoneInfo",poHdrId);    
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
    String  rowReference           =   "";
    String eventName = pageContext.getParameter(EVENT_PARAM); 
    /*
     * Code to set attachment session value
     */
    if(eventName.equals(OA_ADD_ATTACHMENT) || eventName.equals(OA_GOTO_ATTACHMENTS))
    {
      pageContext.putSessionValue("ReturnFromAttachement", "Y");
    }

    if("upDate".equals(pageContext.getParameter(EVENT_PARAM)))
    {
       am.invokeMethod("validateSingleUpdate"); 
       rowReference = pageContext.getParameter(EVENT_SOURCE_ROW_REFERENCE);
       Serializable[] s1 = {rowReference};       
       am.invokeMethod("upDateAction",s1);
    }
    if("addLineAcion".equals(pageContext.getParameter(EVENT_PARAM)))
    {
      am.invokeMethod("validateSingleUpdate"); 
      am.invokeMethod("addLine");
    }
    if(pageContext.isLovEvent())
    {
      String lovInputSource = pageContext.getLovInputSourceId();
      if(lovInputSource.equals("MilestoneName"))
      {
         rowReference = pageContext.getParameter(EVENT_SOURCE_ROW_REFERENCE);
         Serializable[] s1 = {rowReference};
         /*
          * Calling AM method to search duplicate Milestone names
          */
         am.invokeMethod("lovAction",s1);
      }
    }      
    if(pageContext.getParameter("Cancel") != null)
    {
      /*
       * On click of Cancel button, redirecting to parent page
       */
//        pageContext.setForwardURLToCurrentPage(null,
//                                              false,
//                                              OAWebBeanConstants.ADD_BREAD_CRUMB_YES,
//                                              OAWebBeanConstants.IGNORE_MESSAGES);
       pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxmer/xxGsoPlmPOTracking/webui/xxGsoPOsearchPG",
                          null,
                          OAWebBeanConstants.KEEP_MENU_CONTEXT,
                          null,
                          null,
                          true, // Retain AM
                          OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
                          OAWebBeanConstants.IGNORE_MESSAGES);                                              
      
    }
    if (pageContext.getParameter("Apply") != null) 
    {
      am.invokeMethod("validateMilestone");
      am.invokeMethod("saveMilestone");
    }    
  }

}
