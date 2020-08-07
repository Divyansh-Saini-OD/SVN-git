/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.pos.supplier.webui;

import java.sql.SQLException;

import java.sql.Types;

import od.oracle.apps.pos.supplier.server.SupplierSiteTolAMImpl;
//import od.oracle.apps.pos.supplier.server.XXOrgVOImpl;
//import od.oracle.apps.pos.supplier.server.XXSupplierSiteVOImpl;
import od.oracle.apps.pos.supplier.server.XxApCustomTolerancesVOImpl;


import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import oracle.jdbc.OracleCallableStatement;

/**
 * Controller for ...
 */
public class SubTabTolCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");
  public SupplierSiteTolAMImpl am;
  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
    am = (SupplierSiteTolAMImpl)pageContext.getApplicationModule(webBean);
    XxApCustomTolerancesVOImpl vo1 = (XxApCustomTolerancesVOImpl)am.getXxApCustomTolerancesVO1();
    String s = (String)pageContext.getSessionValue("PosVendorId");

      vo1.setWhereClause("SUPPLIER_id = "+s);
    System.out.println("vo1.Query: "+vo1.getQuery());
      pageContext.writeDiagnostics(this,"vo1.Query: "+vo1.getQuery(),OAFwkConstants.EXCEPTION) ;
    vo1.executeQuery();
      System.out.println("vo1.Query: executed");
    
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
