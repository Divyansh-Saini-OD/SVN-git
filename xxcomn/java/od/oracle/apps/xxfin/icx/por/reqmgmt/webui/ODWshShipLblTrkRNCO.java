/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 | Madhu Bolli   12-May-2017    1.0        defect# - Shipping Label Track |
 +===========================================================================*/
package od.oracle.apps.xxfin.icx.por.reqmgmt.webui;

import od.oracle.apps.xxfin.icx.por.reqmgmt.server.ODWshShipLblTrkVOImpl;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.jbo.domain.Number;

/**
 * Controller for ...
 */
public class ODWshShipLblTrkRNCO extends OAControllerImpl
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


    OAApplicationModule reqLineRootAM = pageContext.getRootApplicationModule();





    Number orderNumber = null;

    OAViewObject internalOrderVO = (OAViewObject)reqLineRootAM.findViewObject("InternalOrderVO");
    if(internalOrderVO != null) {
      OARow internalOrderVORow = (OARow)internalOrderVO.first();
      if(internalOrderVORow != null) {
        orderNumber = (Number)internalOrderVORow.getAttribute("OrderNumber");
      }
    }    
    Number orderHeaderId = null;
    String sourceTypeCode = "";
    OAViewObject reqLineVO = (OAViewObject)reqLineRootAM.findViewObject("ReqLineVO");
    if(reqLineVO != null) {
      OARow reqLineVORow = (OARow)reqLineVO.first();
      if(reqLineVORow != null) {
        orderHeaderId = (Number)reqLineVORow.getAttribute("HeaderId");
        sourceTypeCode = (String)reqLineVORow.getAttribute("SourceTypeCode");
      }
    }

    
        if ((orderNumber != null) && (!"VENDOR".equals(sourceTypeCode)))
        {
            OAApplicationModule am = pageContext.getApplicationModule(webBean);
            pageContext.writeDiagnostics(this, "ODWshShipLblTrkRNCO.PR() - invoking ODWshShipLblTrkVOImpl.initQuery() for orderNumber "+orderNumber, 1);
            ODWshShipLblTrkVOImpl shipLblTrkVO = (ODWshShipLblTrkVOImpl)am.findViewObject("ODWshShipLblTrkVO");
            shipLblTrkVO.initQuery(orderNumber);
          pageContext.writeDiagnostics(this, "ODWshShipLblTrkRNCO.PR() - Executed ODWshShipLblTrkVOImpl.initQuery()", 1);
        }
        else
        {
              // If the sourceTypeCode is VENDOR means, it should be purchase order. This page dosen't require for 'Purchase Order' and according to design, the controller wont execute at all
              // In case if it executes, throw error
              throw new OAException("The custom region for 'Ship Label Track' should not shown for Purchase Orders OR the orderHeaderId for Internal Order doesnt exist. Please contact System Administrator.");

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
  }

}
