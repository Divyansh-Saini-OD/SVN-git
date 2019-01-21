/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.ar.cusstd.srch.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAQueryBean;

/**
 * Controller for ...
 */
public class XXODMICRSrchCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
      super.processRequest(pageContext, webBean);
      String srchConducted = pageContext.getParameter("srchConducted");
      OAApplicationModule am = (OAApplicationModule)pageContext.getRootApplicationModule();
      OAViewObject vo = (OAViewObject)am.findViewObject("XXODMICRSrchVO1");
    
      pageContext.writeDiagnostics(this, "XXODMICRSrchCO2: srchConducted="+srchConducted, 1);
      OAQueryBean queryBean = (OAQueryBean)webBean.findChildRecursive("MICRSrchRN"); 
      queryBean.clearSearchPersistenceCache(pageContext); 
      pageContext.writeDiagnostics(this, "XXODMICRSrchCO2: Cleared search persistence", 1);
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
    pageContext.writeDiagnostics(this, "XXODMICRSrchCO: in PFR Begin", 1);
      if ("viewAccountName".equals(pageContext.getParameter("event"))) {
          pageContext.writeDiagnostics(this, "XXODMICRSrchCO: in viewAccountName event", 1);
          String custAcctId = pageContext.getParameter("HzPuiCustAccountId");
          String partyId = pageContext.getParameter("PartyId");
          String str3 = (String)pageContext.getSessionValue("OAPB");
          
          pageContext.writeDiagnostics(this, "XXODMICRSrchCO: in viewAccountName event - custAcctId " + custAcctId, 1);
          pageContext.writeDiagnostics(this, "XXODMICRSrchCO: in viewAccountName event - partyId " + partyId, 1);
          pageContext.writeDiagnostics(this, "XXODMICRSrchCO: in viewAccountName event - OAPB " + str3, 1);
          
          pageContext.putParameter("AcctId", custAcctId);
          pageContext.putParameter("PartyId", partyId);
          pageContext.putParameter("AcctOviewCaller", "AR_CUS_SRCH");
          pageContext.putParameter("OAPB", str3);
          pageContext.forwardImmediately("AR_ACCOUNT_OVERVIEW", (byte) 0, null, null, false, "Y");
      }
      pageContext.writeDiagnostics(this, "XXODMICRSrchCO: in PFR End", 1);
  }

}
