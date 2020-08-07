/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODOpptyUwqCO.java                                             |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Page Controller class for Opportunity UWQ Page.                        |
 |                                                                           |
 |  NOTES                                                                    |
 |         Used for the Opportunity UWQ Page                                 |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    No dependencies.                                                       |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |   22-Nov-2007 Jasmine Sujithra   Created                                  |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.opportunity.webui;

import oracle.apps.fnd.common.VersionInfo;

import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.asn.opportunity.webui.OpptyUwqCO;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.asn.opportunity.server.OpportunityDetailsVORowImpl;
import od.oracle.apps.xxcrm.asn.common.server.ODAddressIdVORowImpl;
import oracle.apps.fnd.framework.OAFwkConstants;
import java.io.Serializable;
import oracle.apps.fnd.framework.server.OAViewRowImpl;

/**
 * Controller for ...
 */
public class ODOpptyUwqCO extends OpptyUwqCO
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
    final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.opportunity.webui.ODOpptyUwqCO.processRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);

    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }
    super.processRequest(pageContext, webBean);

    /*pageContext.putParameter("ASNReqAccessOverride", "T");*/
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
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

    final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.opportunity.webui.ODOpptyUwqCO.processFormRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);

    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }
    super.processFormRequest(pageContext, webBean);
     /* Added Custom Code for ASN Party Site Attributes */
    OAApplicationModule oaapplicationmodule = pageContext.getRootApplicationModule();
    OAViewObject oaviewobject = (OAViewObject)oaapplicationmodule.findViewObject("OpportunityDetailsVO1");

    if(oaviewobject == null)
    {
            MessageToken amessagetoken[] = {
                new MessageToken("NAME", "OpportunityDetailsVO1")
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
    }
      OAApplicationModule am = (OAApplicationModule) pageContext.getRootApplicationModule();
      String opptyId = (String)am.invokeMethod("getLeadId", new Serializable[]{"OpportunityDetailsVO1"});
      pageContext.writeDiagnostics(METHOD_NAME,"Oppty Id is :"+opptyId, 1);
      if (opptyId != null)
      {

          OAViewObject addressIdVO  = (OAViewObject)am.findViewObject("ODAddressIdVO");
          if (addressIdVO == null)
          {
            addressIdVO = (OAViewObject)am.createViewObject("ODAddressIdVO","od.oracle.apps.xxcrm.asn.common.server.ODAddressIdVO");
          }
          Serializable[] params  = { opptyId };
          addressIdVO.invokeMethod("initQuery",params);
          //ODAddressIdVORowImpl addressidvorowimpl = (ODAddressIdVORowImpl)addressIdVO.first();
          OAViewRowImpl addressidvorowimpl = (OAViewRowImpl)addressIdVO.first();
          String addressid = (String)addressidvorowimpl.getAttribute("AddressId").toString();


          if (isStatLogEnabled)
          {
              pageContext.writeDiagnostics(METHOD_NAME,"Value of AddressId is :"+addressid, 1);
          }
          pageContext.putTransactionValue("ASNPartySiteId", addressid);
      }


    /* End Of Custom Code */

    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }
  }

}
