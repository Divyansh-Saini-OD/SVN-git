/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.cdh.reports.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageDateFieldBean;
import java.io.Serializable;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;

/**
 * Controller for ...
 */
public class ODCDHAopsRptCO extends OAControllerImpl
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
  
    DateFormat dateFormat = new SimpleDateFormat("dd-MMM-yy");
    java.util.Date date = new java.util.Date();
    String datetime = dateFormat.format(date);

    OAMessageDateFieldBean dateField = (OAMessageDateFieldBean)
                                   webBean.findIndexedChildRecursive("batchDT");
    if(dateField != null)
            dateField.setValue(pageContext,datetime);
      
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

     DateFormat formatter ; 
     
     
     if (pageContext.getParameter("getDataBtn") != null)
     {
       String strBatchID = "0";  

       OAMessageDateFieldBean dateField = (OAMessageDateFieldBean)
                                     webBean.findIndexedChildRecursive("batchDT");

       try{
           formatter = new SimpleDateFormat("MMddyy");
           strBatchID = formatter.format(dateField.getValue(pageContext));
         } catch (Exception e){} 
         
       Serializable [] parameters = {strBatchID};
       am.invokeMethod("exeVO", parameters);
     
      //pageContext.forwardImmediatelyToCurrentPage(null, true,ADD_BREAD_CRUMB_YES);

       pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxcrm/cdh/reports/webui/ODCDHAopsRptPG",
                                 null,
                                 OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                 null,
                                 null,
                                 true, // retain AM
                                 OAWebBeanConstants.ADD_BREAD_CRUMB_YES); 
     }

     
    
  }

}
