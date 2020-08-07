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
import oracle.apps.fnd.framework.webui.beans.message.OAMessageDateFieldBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;

/**
 * Controller for ...
 */
public class XXCSMPSStalePrinterRptCO extends OAControllerImpl
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

     System.out.println("Before Search Click");
    OAApplicationModule mpsStalePrinterAM = pageContext.getApplicationModule(webBean);
    if(pageContext.getParameter("SubmitBtn") != null)
    {
        System.out.println("Search CustomerNameParam=" + pageContext.getParameter("txtPName"));
        String customerName = pageContext.getParameter("txtPName");
        String NoofDays = pageContext.getParameter("txtItem");
        String managedStatus = pageContext.getParameter("ManagedStatusInput");
        String activeStatus = pageContext.getParameter("ActiveStatusInput");
        Serializable params[] = {
            customerName,NoofDays, managedStatus, activeStatus
            };
        mpsStalePrinterAM.invokeMethod("initMPSStalePrinter", params);
    }
  if(pageContext.getParameter("ClearBtn") != null){
        System.out.println("Before ClearBtn Click");
        clear(pageContext, webBean, mpsStalePrinterAM);
        System.out.println("After ClearBtn Click");
   }
  }

  public void clear(OAPageContext pageContext, OAWebBean webBean, OAApplicationModule mpsStalePrinterAM)
  {
      System.out.println("Inside ClearBtn Click");
      OAMessageLovInputBean customerNameBean = (OAMessageLovInputBean)webBean.findChildRecursive("txtPName");
      OAMessageTextInputBean NoofDaysBean = (OAMessageTextInputBean)webBean.findChildRecursive("txtItem");
      if(customerNameBean != null)
          customerNameBean.setValue(pageContext, ""); 
      if(NoofDaysBean != null)
          NoofDaysBean.setValue(pageContext, "");
          Serializable params[] = {
          "-1","-1", null, null
      };
      mpsStalePrinterAM.invokeMethod("initMPSStalePrinter", params);

  }

}
