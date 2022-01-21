/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxfin.ar.irec.accountDetails.blkexp.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OASubTabLayoutBean;

/**
 * Controller for ...
 */
public class ODIrecBlkExpMainCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");
        
  public static final String BULK_EXPORT_USER_CP_NAME = "OD: AR Invoice Reprint Individual Invoices";        
  public static final String BULK_EXPORT_CP_REQS_VIEW_DAYS = "7";

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
    //pageContext.putParameter("progApplShortName","XXFIN");
    //pageContext.putParameter("progShortName","XXARINVIND");
    
    pageContext.putTransactionValue("IsBulkExportRequests", "Y");
    pageContext.putParameter("IsBulkExportRequests", "Y");
    /**
    pageContext.putParameter("bulkExportUserCPName", BULK_EXPORT_USER_CP_NAME);
    pageContext.putParameter("bulkExportCPReqViewDays", BULK_EXPORT_CP_REQS_VIEW_DAYS);
**/
  /**
    String dispSubTabInd = pageContext.getParameter("dispSubTabIndex");
    if(dispSubTabInd != null && !"".equals(dispSubTabInd)) {
      OASubTabLayoutBean subTabLytBn = (OASubTabLayoutBean)webBean.findIndexedChildRecursive("ODIrBlExpStbLyt");
      subTabLytBn.setSelectedIndex(pageContext, dispSubTabInd);
      String requestId = pageContext.getParameter("requestId");
    }
    **/
    //hMap.put("OASubTabLayoutBean.OA_SELECTED_SUBTAB_IDX", "1");
    
    
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
