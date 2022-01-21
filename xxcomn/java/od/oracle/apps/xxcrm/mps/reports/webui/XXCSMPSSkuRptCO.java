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
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;

/**
 * Controller for ...
 */
public class XXCSMPSSkuRptCO extends OAControllerImpl
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
    OAApplicationModule mpsReportsAM = pageContext.getApplicationModule(webBean);
    if(pageContext.getParameter("btnSubmit") != null)
    {
        System.out.println("Search CustomerNameParam=" + pageContext.getParameter("txtPName"));
        String partyId = pageContext.getParameter("PartyIDFV");        
        String customerName = pageContext.getParameter("txtPName");
        String fromDeliveryDate = pageContext.getParameter("txtFromDelDt");
        String toDeliveryDate = pageContext.getParameter("txtToDelDt");
        String item = pageContext.getParameter("txtItem");
        String managedStatus = pageContext.getParameter("ManagedStatusInput");
        String activeStatus = pageContext.getParameter("ActiveStatusInput");
        Serializable params[] = {
            partyId, toDeliveryDate, fromDeliveryDate, item, managedStatus, activeStatus
        };
        mpsReportsAM.invokeMethod("initMPSSkuRpt", params);
    }
    if(pageContext.getParameter("btnClear") != null)
        clear(pageContext, webBean, mpsReportsAM);
  }

  public void clear(OAPageContext pageContext, OAWebBean webBean, OAApplicationModule mpsReportsAM)
  {
      OAMessageLovInputBean customerNameBean = (OAMessageLovInputBean)webBean.findChildRecursive("PartyName2");
      OAMessageDateFieldBean fromDeliveryDateBean = (OAMessageDateFieldBean)webBean.findChildRecursive("txtFromDelDt");
      OAMessageDateFieldBean toDeliveryDateBean = (OAMessageDateFieldBean)webBean.findChildRecursive("txtToDelDt");
      OAMessageTextInputBean itemBean = (OAMessageTextInputBean)webBean.findChildRecursive("txtItem");
      OAMessageTextInputBean managedStatusBean = (OAMessageTextInputBean)webBean.findChildRecursive("ManagedStatusInput");
      OAMessageTextInputBean activeStatusBean = (OAMessageTextInputBean)webBean.findChildRecursive("ActiveStatusInput");
      if(customerNameBean != null)
          customerNameBean.setValue(pageContext, "");
      if(fromDeliveryDateBean != null)
          fromDeliveryDateBean.setValue(pageContext, "");
      if(toDeliveryDateBean != null)
          toDeliveryDateBean.setValue(pageContext, "");
      if(itemBean != null)
          itemBean.setValue(pageContext, "");
      if(managedStatusBean != null)
          managedStatusBean.setValue(pageContext, "");
      if(activeStatusBean != null)
          activeStatusBean.setValue(pageContext, "");
      Serializable params[] = {
          "-1", "-1", "-1", "-1", null, null
      };
      mpsReportsAM.invokeMethod("initMPSSkuRpt", params);
  }

}
