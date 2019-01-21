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
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;
/**
 * Controller for ...
 */
public class XXCSMPSTotalAssetsRptCO extends OAControllerImpl
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
    OAApplicationModule mpsTotalAssetsAM = pageContext.getApplicationModule(webBean);
    if(pageContext.getParameter("SubmitBtn") != null)
    {
        System.out.println("Search CustomerNameParam=" + pageContext.getParameter("txtPName"));
        String customerName = pageContext.getParameter("txtPName");
        String ProgramType = pageContext.getParameter("ProgramTypeParam");
        String Manufacturer = pageContext.getParameter("ManufacturerParam");
	String Model = pageContext.getParameter("ModelLov");
        String managedStatus = pageContext.getParameter("ManagedStatusInput");
        String activeStatus = pageContext.getParameter("ActiveStatusInput");

        pageContext.writeDiagnostics(this, "managedStatus: " + managedStatus, OAFwkConstants.STATEMENT);
        pageContext.writeDiagnostics(this, "activeStatus: " + activeStatus, OAFwkConstants.STATEMENT);
        Serializable params[] = {
            customerName,ProgramType,Manufacturer,Model , managedStatus, activeStatus
            };
        mpsTotalAssetsAM.invokeMethod("initMPSTotalAssetsRpt", params);
    }
  if(pageContext.getParameter("ClearBtn") != null){
        System.out.println("Before ClearBtn Click");
        clear(pageContext, webBean, mpsTotalAssetsAM);
        System.out.println("After ClearBtn Click");
   }
  }

  public void clear(OAPageContext pageContext, OAWebBean webBean, OAApplicationModule mpsTotalAssetsAM)
  {
      System.out.println("Inside ClearBtn Click");
      OAMessageLovInputBean customerNameBean = (OAMessageLovInputBean)webBean.findChildRecursive("txtPName");
      OAMessageChoiceBean ProgramTypeParamBean = (OAMessageChoiceBean)webBean.findChildRecursive("ProgramTypeParam");
      OAMessageChoiceBean ManufacturerParamBean = (OAMessageChoiceBean)webBean.findChildRecursive("ManufacturerParam");
      OAMessageLovInputBean ModelLovBean = (OAMessageLovInputBean)webBean.findChildRecursive("ModelLov");
      OAMessageTextInputBean managedStatusBean = (OAMessageTextInputBean)webBean.findChildRecursive("ManagedStatusInput");
      OAMessageTextInputBean activeStatusBean = (OAMessageTextInputBean)webBean.findChildRecursive("ActiveStatusInput");
      if(customerNameBean != null)
          customerNameBean.setValue(pageContext, ""); 
      if(ProgramTypeParamBean != null)
          ProgramTypeParamBean.setValue(pageContext, "");
       if(ManufacturerParamBean != null)
          ProgramTypeParamBean.setValue(pageContext, "");
       if(ModelLovBean != null)
          ProgramTypeParamBean.setValue(pageContext, "");
      if(managedStatusBean!=null)
          managedStatusBean.setValue(pageContext, "");
      if(activeStatusBean!=null)
          activeStatusBean.setValue(pageContext, "");
          Serializable params[] = {
          "-1","-1","-1","-1", null, null
      };
      mpsTotalAssetsAM.invokeMethod("initMPSTotalAssetsRpt", params);
  }

}
