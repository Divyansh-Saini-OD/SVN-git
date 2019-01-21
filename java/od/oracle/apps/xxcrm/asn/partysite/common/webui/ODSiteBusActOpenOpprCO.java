/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODSiteBusActOpenOpprCO.java                                     |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Controller class for site level Business Activity Open Opportunities.  |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    No dependencies.                                                       |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    10/09/2007 Ashok Kumar   Created                                       |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.partysite.common.webui;

import com.sun.java.util.collections.HashMap;

import java.io.Serializable;

import od.oracle.apps.xxcrm.asn.common.fwk.webui.ODASNControllerObjectImpl;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.OADataBoundValueViewObject;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;

/**
 * Controller for ...
 */
public class ODSiteBusActOpenOpprCO extends ODASNControllerObjectImpl
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
    final String METHOD_NAME = "xxcrm.asn.partysite.common.webui.ODSiteBusActOpenOpprCO.processRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStmtLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);

    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processRequest(pageContext, webBean);
    OAApplicationModule amActs = pageContext.getApplicationModule(webBean);
    String addressId = (String) pageContext.getTransactionValue("ASNTxnAddressId");
    String selectedValue = pageContext.getParameter("ODSiteBusActsPoplist");

    if (isStmtLogEnabled)
    {
      StringBuffer buf = new StringBuffer();
      buf.append("addressId = ");
      buf.append(addressId);
      buf.append(" ,selectedValue = ");
      buf.append(selectedValue);
      pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
    }

    // currency format
    OAMessageStyledTextBean oppAmount = (OAMessageStyledTextBean) webBean.findIndexedChildRecursive("TotalAmount");
    if(oppAmount != null)
    {
      oppAmount.setAttributeValue(CURRENCY_CODE,
        new OADataBoundValueViewObject(oppAmount, "CurrencyCode"));
    }

    Serializable[] parametersForPvo = { selectedValue };
    amActs.invokeMethod("initOpenOpptyPVO", parametersForPvo);

    if (addressId != null && !"".equals(addressId.trim()))
    {
      Serializable[] parametersForVo = { addressId, selectedValue };
      amActs.invokeMethod("initOpenOpptyVO", parametersForVo);
    }

    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME,"End", OAFwkConstants.PROCEDURE);
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
    final String METHOD_NAME = "xxcrm.asn.partysite.common.webui.ODSiteBusActOpenOpprCO.processFormRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStmtLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);

    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processFormRequest(pageContext, webBean);
    OAApplicationModule amActs = pageContext.getApplicationModule(webBean);
    String addressId = (String) pageContext.getTransactionValue("ASNTxnAddressId");
    String selectedValue = pageContext.getParameter("ODSiteBusActsPoplist");
    String event = pageContext.getParameter(EVENT_PARAM);
    String pageEvent = pageContext.getParameter("ASNReqPgAct");

    if (isStmtLogEnabled)
    {
      StringBuffer buf = new StringBuffer();
      buf.append("addressId = ");
      buf.append(addressId);
      buf.append(" ,selectedValue = ");
      buf.append(selectedValue);
      buf.append(" ,event = ");
      buf.append(event);
      buf.append(" ,pageEvent = ");
      buf.append(pageEvent);
      pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
    }    

    if("SITEBUSACTSPPR".equals(event) )
    {
      Serializable[] parameters = { selectedValue };
      amActs.invokeMethod("initOpenOpptyPVO", parameters);

      if (addressId!= null && !"".equals(addressId.trim()))
      {
        Serializable[] parametersForActs = { addressId, selectedValue };
        amActs.invokeMethod("initOpenOpptyVO", parametersForActs);
      }

    }
    // lead detail link clicked
    if("OPPTYDET".equals(pageEvent))
    {
      // This api will get the event parameters given in the actions property of the attribute.
      HashMap urlParams = this.getFrmParamsFromEvtParams(pageContext);
      processTargetURL(pageContext,null,urlParams);
    }

    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME,"End", OAFwkConstants.PROCEDURE);
    }
    
  }

}
