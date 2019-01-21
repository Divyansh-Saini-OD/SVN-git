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
import oracle.apps.fnd.framework.webui.beans.message.OAMessageDateFieldBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;
/**
 * Controller for ...
 */
public class XXCSMPSTonerOrdRptCO extends OAControllerImpl
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
    OAApplicationModule mpsTonerOrderAM = pageContext.getApplicationModule(webBean);
    if(pageContext.getParameter("btnSubmit") != null)
    {
        System.out.println("Search CustomerNameParam=" + pageContext.getParameter("txtPName"));
        String partyId = pageContext.getParameter("PartyIDFV");
        String fromDeliveryDate = pageContext.getParameter("txtFromDelDt");
        String toDeliveryDate = pageContext.getParameter("txtToDelDt");
        String item = pageContext.getParameter("txtItem");
        String managedStatus = pageContext.getParameter("ManagedStatusInput");
        String activeStatus = pageContext.getParameter("ActiveStatusInput");
        pageContext.writeDiagnostics(this, "managedStatus: " + managedStatus, OAFwkConstants.PROCEDURE);
        pageContext.writeDiagnostics(this, "activeStatus: " + activeStatus, OAFwkConstants.PROCEDURE);
        Serializable params[] = {
            partyId, toDeliveryDate, fromDeliveryDate, item, managedStatus, activeStatus
        };
        mpsTonerOrderAM.invokeMethod("initMPSTonerOrder", params);
    }
    if(pageContext.getParameter("btnClear") != null)
        clear(pageContext, webBean, mpsTonerOrderAM);
  }

  public void clear(OAPageContext pageContext, OAWebBean webBean, OAApplicationModule mpsTonerOrderAM)
  {
      OAMessageLovInputBean customerNameBean = (OAMessageLovInputBean)webBean.findChildRecursive("PartyName2");
      OAMessageDateFieldBean fromDeliveryDateBean = (OAMessageDateFieldBean)webBean.findChildRecursive("txtFromDelDt");
      OAMessageDateFieldBean toDeliveryDateBean = (OAMessageDateFieldBean)webBean.findChildRecursive("txtToDelDt");
      OAMessageTextInputBean itemBean = (OAMessageTextInputBean)webBean.findChildRecursive("txtItem");
      if(customerNameBean != null)
          customerNameBean.setValue(pageContext, "");
      if(fromDeliveryDateBean != null)
          fromDeliveryDateBean.setValue(pageContext, "");
      if(toDeliveryDateBean != null)
          toDeliveryDateBean.setValue(pageContext, "");
      if(itemBean != null)
          itemBean.setValue(pageContext, "");
      OAMessageTextInputBean managedStatusBean = (OAMessageTextInputBean)webBean.findChildRecursive("ManagedStatusInput");
      OAMessageTextInputBean activeStatusBean = (OAMessageTextInputBean)webBean.findChildRecursive("ActiveStatusInput");
      if(managedStatusBean!=null)
          managedStatusBean.setValue(pageContext, "");
      if(activeStatusBean!=null)
          activeStatusBean.setValue(pageContext, "");           
      Serializable params[] = {
          "-1", null, null, "-1", null, null
      };
      mpsTonerOrderAM.invokeMethod("initMPSTonerOrder", params);
  }

}
