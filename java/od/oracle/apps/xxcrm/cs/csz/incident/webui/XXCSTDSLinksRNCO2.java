/*=============================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA      |
 |                         All rights reserved.                                |
 +=============================================================================+
 |  HISTORY                                                                    |
 |  Date           Authors            Remarks                                  |
 |  01-Aug-2013    Darshini           I2117 - Modified for R12 Upgrade Retrofit|
 +=============================================================================*/
package od.oracle.apps.xxcrm.cs.csz.incident.webui;

import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.nav.OAButtonBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAButtonSpacerBean;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.layout.OARowLayoutBean;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.cs.csz.incident.server.IncidentUpdateAMImpl;
import oracle.jbo.Row;

/**
 * Controller for ...
 */
public class XXCSTDSLinksRNCO2 extends  oracle.apps.cs.csz.incident.webui.IncidentUpdateCO
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
    pageContext.writeDiagnostics(METHOD_NAME, "processRequest of XXCSTDSLinksRNCO", OAFwkConstants.PROCEDURE);
    OAButtonSpacerBean spcb = (OAButtonSpacerBean)pageContext.getWebBeanFactory().createWebBean(pageContext, OAWebBeanConstants.BUTTON_SPACER_BEAN 
, null, "xxspcb");
    spcb.setWidth(400);
    spcb.setHeight(10);
    OAButtonBean connectButton = (OAButtonBean)pageContext.getWebBeanFactory().createWebBean(pageContext, OAWebBeanConstants.BUTTON_BEAN, null, "xxConnectButton");
    connectButton.setText("Connect");
    connectButton.setLabel("Connect");

    String strConnectVal = "";
    IncidentUpdateAMImpl iupam = (IncidentUpdateAMImpl)pageContext.getRootApplicationModule();  
    OAViewObject xxcsIncidentVO = (OAViewObject)(iupam.getSRAM()).findViewObject("IncidentEOVO"); 
    //xxcsIncidentVO.setMaxFetchSize(0);
    //xxcsIncidentVO.executeQuery();

    Row curRow = xxcsIncidentVO.getCurrentRow();
    String strConnInfo = (String)curRow.getAttribute("ExternalAttribute14");
    int isi = Integer.parseInt((curRow.getAttribute("IncidentStatusId")).toString());
    if (strConnInfo !=null && isi != 4106)
    {
      /*Commented and added for R12 Upgrade Retrofit
      webBean.findIndexedChildRecursive("SRHeaderxRN").addIndexedChild(spcb);*/
      webBean.findIndexedChildRecursive("LeftTable").addIndexedChild(spcb);
      connectButton.setDestination(strConnInfo);
      connectButton.setTargetFrame("_blank");
      /*Commented and added for R12 Upgrade Retrofit
	  webBean.findIndexedChildRecursive("SRHeaderxRN").addIndexedChild(connectButton);*/
	  webBean.findIndexedChildRecursive("LeftTable").addIndexedChild(connectButton);
    }
    pageContext.writeDiagnostics(METHOD_NAME, "strConnInfo: " + strConnInfo, OAFwkConstants.PROCEDURE);

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

