/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.common.customer.webui;

import java.io.Serializable;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

/**
 * Controller for ...
 */
public class ODCtctCrteCO extends OAControllerImpl
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
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);        
    if (isStatLogEnabled) {
          pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.STATEMENT);
      }
      if ("Y".equals(pageContext.getTransactionValue("ASNTxnAddrSelFlow")))
         {
        if (isProcLogEnabled) 
           {
          pageContext.writeDiagnostics(METHOD_NAME, "AM already exists. Setting CPUI parameter HzPuiPersonCompositeExist to avoid creating new row.", OAFwkConstants.PROCEDURE);
        }

        // Following CPUI parameter should be placed in context when returning from
        // address selection page to indicate TCA to avoid inserting a new row into the VO.
        // This is to avoid bug 5246947
        pageContext.putParameter("HzPuiPersonCompositeExist", "YES");

        // Remove the parameter from transaction since user returned from the flow.
        pageContext.removeTransactionValue("ASNTxnAddrSelFlow");
      }

    super.processRequest(pageContext, webBean);
    if (isStatLogEnabled) {
        pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.STATEMENT);
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
