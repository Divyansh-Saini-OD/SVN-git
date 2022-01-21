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
public class XXCSTDSLinksRNCO3 extends  oracle.apps.cs.csz.incident.webui.IncidentUpdateCO
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
    OAButtonBean shippingButton = (OAButtonBean)pageContext.getWebBeanFactory().createWebBean(pageContext, OAWebBeanConstants.BUTTON_BEAN, null, "xxShippingButton");
    shippingButton.setText("Shipping Label");
    shippingButton.setLabel("Shipping Label");
    String strShipVal = "";
    IncidentUpdateAMImpl iupam = (IncidentUpdateAMImpl)pageContext.getRootApplicationModule();
    OAViewObject xxcsIncidentVO = (OAViewObject)(iupam.getSRAM()).findViewObject("IncidentEOVO");

    Row curRow = xxcsIncidentVO.getCurrentRow();
    String strConnInfo2 = (String)curRow.getAttribute("ExternalAttribute15");

      if (strConnInfo2 != null)
	    {
	      shippingButton.setDestination(strConnInfo2);
	      shippingButton.setTargetFrame("_blank");
		  /*Commented and Added for R12 Upgrade Retrofit
	      webBean.findIndexedChildRecursive("SRHeaderxRN").addIndexedChild(shippingButton);*/
		  webBean.findIndexedChildRecursive("LeftTable").addIndexedChild(shippingButton);
    }

    /*** Quotation */
	OAButtonBean quotationButton = (OAButtonBean)pageContext.getWebBeanFactory().createWebBean(pageContext, OAWebBeanConstants.BUTTON_BEAN, null, "xxQuotationButton");
	quotationButton.setText("Order Part");
	quotationButton.setLabel("Order Part");
	String strQuoteVal = "";

    String strConnInfo3 = (String)curRow.getAttribute("ExternalAttribute13");

      if (strConnInfo3 != null)
	    {
	      strConnInfo3 = (String)curRow.getAttribute("ExternalAttribute13")+(String)curRow.getAttribute("ExternalAttribute2");
	      quotationButton.setDestination(strConnInfo3);
	      quotationButton.setTargetFrame("_blank");
		  /*Commented and Added for R12 Upgrade Retrofit
	      webBean.findIndexedChildRecursive("SRHeaderxRN").addIndexedChild(quotationButton);*/
		  webBean.findIndexedChildRecursive("LeftTable").addIndexedChild(quotationButton);
    	}

    /*** Parts */
	OAButtonBean partsButton = (OAButtonBean)pageContext.getWebBeanFactory().createWebBean(pageContext, OAWebBeanConstants.BUTTON_BEAN, null, "xxPartsButton");
	partsButton.setText("PartsDetails");
	partsButton.setLabel("PartsDetails");
	String strPartVal = "";

    String strConnInfo4 = (String)curRow.getAttribute("ExternalAttribute6");

	  if (strConnInfo4 != null)
	    {
	      partsButton.setDestination(strConnInfo4);
	      /*partsButton.setTargetFrame("_blank"); */
		  /*Commented and Added for R12 Upgrade Retrofit
	      webBean.findIndexedChildRecursive("SRHeaderxRN").addIndexedChild(partsButton);*/
		  webBean.findIndexedChildRecursive("LeftTable").addIndexedChild(partsButton);
    }

    /*** PrintOrder */
	OAButtonBean printButton = (OAButtonBean)pageContext.getWebBeanFactory().createWebBean(pageContext, OAWebBeanConstants.BUTTON_BEAN, null, "xxPrintButton");
	printButton.setText("PrintPartOrder");
	printButton.setLabel("PrintPartOrder");
	String strPrintVal = "";

    String strConnInfo5 = (String)curRow.getAttribute("ExternalAttribute4");

    if (strConnInfo5 != null)
	    {
	      printButton.setDestination(strConnInfo5);
	      printButton.setTargetFrame("_blank");
		  /*Commented and Added for R12 Upgrade Retrofit
	      webBean.findIndexedChildRecursive("SRHeaderxRN").addIndexedChild(printButton);*/
		  webBean.findIndexedChildRecursive("LeftTable").addIndexedChild(printButton);
    }

   /*** Warranty */
	OAButtonBean warrantyButton = (OAButtonBean)pageContext.getWebBeanFactory().createWebBean(pageContext, OAWebBeanConstants.BUTTON_BEAN, null, "xxWarrantyButton");
	warrantyButton.setText("Warranty");
	warrantyButton.setLabel("Warranty");
	String strWarrantyVal = "";

    String strConnInfo6 = (String)curRow.getAttribute("ExternalAttribute5");

    /****/

    if (strConnInfo6 != null)
    {
      warrantyButton.setDestination(strConnInfo6);
      warrantyButton.setTargetFrame("_blank");
	  /*Commented and Added for R12 Upgrade Retrofit
      webBean.findIndexedChildRecursive("SRHeaderxRN").addIndexedChild(warrantyButton);*/
	  webBean.findIndexedChildRecursive("LeftTable").addIndexedChild(warrantyButton);
    }
    pageContext.writeDiagnostics(METHOD_NAME, "strConnInfo2: " + strConnInfo2, OAFwkConstants.PROCEDURE);

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

