/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODSiteBusinessActivitiesCO.java                               |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Controller class for site level Business Activities.                   |
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

import com.sun.java.util.collections.ArrayList;

import java.io.Serializable;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAStackLayoutBean;

/**
 * Controller for ...
 */
public class ODSiteBusinessActivitiesCO extends OAControllerImpl
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
    final String METHOD_NAME = "xxcrm.asn.partysite.common.webui.ODSiteBusinessActivitiesCO.processRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStmtLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);

    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processRequest(pageContext, webBean);
    OAApplicationModule amActs = pageContext.getApplicationModule(webBean);
    String addressId = (String) pageContext.getTransactionValue("ASNTxnAddressId");
    String BusActLkpType = (String) pageContext.getTransactionValue("ASNTxnSiteBusActLkpTyp");
    String appId = "0";

    if (isStmtLogEnabled)
    {
    StringBuffer buf = new StringBuffer();
    buf.append("addressId = ");
    buf.append(addressId);
    buf.append(" ,BusActLkpType = ");
    buf.append(BusActLkpType);
    pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
    }

    if ((addressId == null)||("".equals(addressId))||BusActLkpType ==null||("".equals(BusActLkpType)))
    {
      webBean.setRendered(false);
      return;
    }

    if (BusActLkpType != null && !"".equals(BusActLkpType.trim()))
    {
       Serializable[] parametersForBusActPoplist = { BusActLkpType, appId };
       amActs.invokeMethod("initBusActPoplistQuery", parametersForBusActPoplist);
    }

    ArrayList busActRegionNames = (ArrayList)amActs.invokeMethod("busActLookupCodes");
    for (int i = 0; i < busActRegionNames.size(); i++)
      {
        String regionName = (String) busActRegionNames.get(i);
        String regionPath = null;
        if (regionName != null && !"".equals(regionName.trim()))
        {
          Serializable[] parametersForRegionName = { regionName };
          regionPath = (String) amActs.invokeMethod("getRegionPath", parametersForRegionName);
        }

        if (regionPath != null && !"".equals(regionPath.trim()))
        {
          OAStackLayoutBean busActRN = (OAStackLayoutBean)createWebBean(pageContext,regionPath,regionName,true);
          if (busActRN != null)
            webBean.addIndexedChild(busActRN);
        }
      }

    String selectedValue = null;
    selectedValue = (String) amActs.invokeMethod("busActSelectedValue");
    if(selectedValue!=null)
    {
      pageContext.putParameter("ODSiteBusActsPoplist",selectedValue);
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
    final String METHOD_NAME = "xxcrm.asn.partysite.common.webui.ODSiteBusinessActivitiesCO.processFormRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);

    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processFormRequest(pageContext, webBean);
    
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME,"End", OAFwkConstants.PROCEDURE);
    }
  }

}
