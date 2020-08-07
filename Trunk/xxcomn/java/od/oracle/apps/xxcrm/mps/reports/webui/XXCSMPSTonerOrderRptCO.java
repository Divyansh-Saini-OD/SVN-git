/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 |  DESCRIPTION                                                              |
 |    Class to show Order Details as report for MPS.                         |
 |                                                                           |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |                                                                           |
 |  HISTORY                                                                  |
 | Ver  Date       Name           Revision Description                       |
 | ===  =========  ============== ===========================================|
 | 1.0  -Aug-13  Suraj Charan     Initial. 
 +===========================================================================*/
package od.oracle.apps.xxcrm.mps.reports.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageDateFieldBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import java.io.Serializable;
/**
 * Controller for ...
 */
public class XXCSMPSTonerOrderRptCO extends OAControllerImpl
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
    if(pageContext.getParameter("Search") != null)
    {
      System.out.println("##### Search CustomerNameParam="+pageContext.getParameter("CustomerNameParam"));
      String customerName = pageContext.getParameter("CustomerNameParam");
      String fromDeliveryDate = pageContext.getParameter("FromDeliveryDateParam");
      String toDeliveryDate = pageContext.getParameter("ToDeliveryDateParam");
      String suppliesLabel = pageContext.getParameter("SuppliesLabelParam");
      Serializable[] params = {customerName, toDeliveryDate, fromDeliveryDate, suppliesLabel};
      mpsTonerOrderAM.invokeMethod("initMPSTonerOrder",params);
//      System.out.println("##### Search partyId="+partyId);
    }

    if(pageContext.getParameter("Clear") != null)  
    {
      clear( pageContext, webBean, mpsTonerOrderAM);
    }    
          
  }

 public void clear(OAPageContext pageContext,OAWebBean webBean, OAApplicationModule mpsTonerOrderAM)
  {
    OAMessageTextInputBean customerNameBean = (OAMessageTextInputBean)webBean.findChildRecursive("CustomerNameParam");
    OAMessageDateFieldBean fromDeliveryDateBean = (OAMessageDateFieldBean)webBean.findChildRecursive("FromDeliveryDateParam");
    OAMessageDateFieldBean toDeliveryDateBean = (OAMessageDateFieldBean)webBean.findChildRecursive("ToDeliveryDateParam");
    OAMessageTextInputBean suppliesLabelBean = (OAMessageTextInputBean)webBean.findChildRecursive("SuppliesLabelParam");
    if(customerNameBean != null)
    customerNameBean.setValue(pageContext,"");
    if(fromDeliveryDateBean != null)
    fromDeliveryDateBean.setValue(pageContext,"");
    if(toDeliveryDateBean != null)
    toDeliveryDateBean.setValue(pageContext,"");
    if(suppliesLabelBean != null)
    suppliesLabelBean.setValue(pageContext,"");    

    Serializable[] params = {"-1", "-1","-1", "-1"};
    mpsTonerOrderAM.invokeMethod("initMPSTonerOrder",params);    
  }

}
