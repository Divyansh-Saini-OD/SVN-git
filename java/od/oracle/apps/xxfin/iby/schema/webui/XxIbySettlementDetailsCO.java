/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxfin.iby.schema.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

/**
 * Controller for ...
 */
public class XxIbySettlementDetailsCO extends OAControllerImpl
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
      System.out.println("XxIbySettlementDetailsCO PR");
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      String sReceiptNum = (String)pageContext.getParameter("ReceiptNum");
      System.out.println("sReceiptNum: " + sReceiptNum);
      String sBatchNum = (String)pageContext.getParameter("BatchtNum");
      System.out.println("sBatchNum: " + sBatchNum);
               
      OAViewObject vo = (OAViewObject)am.findViewObject("XxIbyBatchTrxns201HistoryVO1");
      if (vo !=null)
      {
      vo.setWhereClause(null);
      vo.setWhereClauseParams(null);
      vo.setWhereClause("ixreceiptnumber = :1");
      vo.setWhereClauseParam(0,sReceiptNum);
      //vo.setWhereClauseParam(1,sBatchNum);
      
      System.out.println("XxIbySettlementDetailsCO vo.getQuery: " + vo.getQuery());
      vo.clearCache();
      vo.executeQuery();    
      System.out.println("XxIbySettlementDetailsCO vo.getRowCount: " + vo.getRowCount());
      
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
