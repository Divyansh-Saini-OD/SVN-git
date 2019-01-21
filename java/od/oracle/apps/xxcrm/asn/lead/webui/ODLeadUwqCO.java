/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODLeadUwqCO.java                                              |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Page Controller class for Lead UWQ Page.                               |
 |                                                                           |
 |  NOTES                                                                    |
 |         Used for the Lead UWQ Page                                        |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    No dependencies.                                                       |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |   22-Nov-2007 Jasmine Sujithra   Created                                  |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.lead.webui;

import oracle.apps.fnd.common.VersionInfo;

import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.asn.lead.webui.LeadUwqCO;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAFwkConstants;
import com.sun.java.util.collections.HashMap;
import java.io.Serializable;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OAViewRowImpl;

/**
 * Controller for ...
 */
public class ODLeadUwqCO extends LeadUwqCO
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
    final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.lead.webui.ODLeadUwqCO.processRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
  /* pageContext.putParameter("ASNReqAccessOverride", "T");*/
    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }
    super.processRequest(pageContext, webBean);

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
     final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.lead.webui.ODLeadUwqCO.processFormRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);

    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }
    super.processFormRequest(pageContext, webBean);

     /* Added Custom Code for ASN Party Site Attributes */

      OAApplicationModule oaapplicationmodule = pageContext.getRootApplicationModule();

      String leadid = pageContext.getParameter("ASNReqFrmLeadId");
      pageContext.writeDiagnostics(METHOD_NAME,"Lead ID is :" + leadid, 1);



        String leadIdUWQ = (String)oaapplicationmodule.invokeMethod("getLeadId", new Serializable[]{"LeadDetailsVO"});
         pageContext.writeDiagnostics(METHOD_NAME,"leadIdUWQ ID is :" + leadIdUWQ, 1);

         Serializable aserializable[] = {
            "LeadHeaderDetailsVO", leadIdUWQ
        };

      HashMap hashmap = (HashMap)oaapplicationmodule.invokeMethod("getLeadInfo", aserializable);
      String addressid = null;
      if (hashmap != null)
      {
          //Object addidobj = (Object)hashmap.get("AddressId");
          //addressid = (String)addidobj;
          addressid = (String)hashmap.get("AddressId");
      }
      else
          pageContext.writeDiagnostics(METHOD_NAME,"hashmap is null" + leadIdUWQ, 1);

      pageContext.writeDiagnostics(METHOD_NAME,"Value of AddressId after hashmap is :" + addressid, 1);
      //pageContext.writeDiagnostics(METHOD_NAME,"Value of Address is :" + address, 1);


      if(addressid != null)
            pageContext.putTransactionValue("ASNPartySiteId", addressid);
      else
      {
          if (leadIdUWQ != null)
          {
              OAViewObject addressIdVO  = (OAViewObject)oaapplicationmodule.findViewObject("ODAddressIdVO");
              if (addressIdVO == null)
              {
                  addressIdVO = (OAViewObject)oaapplicationmodule.createViewObject("ODAddressIdVO","od.oracle.apps.xxcrm.asn.common.server.ODAddressIdVO");
              }
              Serializable[] params  = { leadIdUWQ };
              addressIdVO.invokeMethod("initQuery",params);
              //ODAddressIdVORowImpl addressidvorowimpl = (ODAddressIdVORowImpl)addressIdVO.first();
              OAViewRowImpl addressidvorowimpl = (OAViewRowImpl)addressIdVO.first();
              //  addressid = (String)addressidvorowimpl.getAttribute("AddressId").toString();
              if (isStatLogEnabled)
              {
                  pageContext.writeDiagnostics(METHOD_NAME,"Value of AddressId is :"+addressid, 1);
              }
              pageContext.putTransactionValue("ASNPartySiteId", addressid);
          }
      }

  }

}
