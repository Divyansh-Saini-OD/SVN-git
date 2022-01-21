/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxmer.papb.server.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import od.oracle.apps.xxmer.papb.server.GenPrdDtlVOImpl;
import od.oracle.apps.xxmer.papb.server.GenPrdDtlVORowImpl;
import od.oracle.apps.xxmer.papb.server.PAPBAMImpl;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import od.oracle.apps.xxmer.papb.server.LogisticsTariffApprvVOImpl;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.beans.OAImageBean;


/**
 * Controller for ...
 */
public class PLMProdDutyTariffCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  protected String m_strSuccessMsgToken;
  protected String m_strErrorMsgToken;
  
  public PLMProdDutyTariffCO()
  {
      m_strSuccessMsgToken = "XXMER_PA_PB_EXCEL_UPLOAD_SUC";
      m_strErrorMsgToken = "XXMER_PA_PB_EXCEL_UPLOAD_ERR";
  }

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);

    PAPBAMImpl am = (PAPBAMImpl)pageContext.getApplicationModule(webBean);
    GenPrdDtlVOImpl vo = am.getGenPrdDtlVO1();
    GenPrdDtlVORowImpl row = (GenPrdDtlVORowImpl) vo.getCurrentRow();
    String strProdDtlId = row.getProdDtlId().toString();
    
    LogisticsTariffApprvVOImpl vo1 = am.getLogisticsTariffApprvVO1();
    /*if(vo1==null)
    {
      MessageToken[] errTokens = {new MessageToken("OBJECT_NAME","SSCapsMultiVO2")};
      throw new OAException("XXMER","XXMER_VC_OBJECT_NOT_FOUND",errTokens);
    }*/
    vo1.setWhereClause("PrdLogisticsEO.PROD_DTL_ID = :1");
    vo1.setWhereClauseParams(null); //Always reset
    vo1.setWhereClauseParam(0, strProdDtlId);
    vo1.executeQuery();

    OAPageLayoutBean pageLayoutBean = (OAPageLayoutBean)webBean;
    OAImageBean imgBean = (OAImageBean) pageLayoutBean.findChildRecursive("ProductImg");
    imgBean.setSource(row.getProductImage());
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

    if (pageContext.getParameter("ProdDtlbtn") != null)
    {
      pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxmer/papb/webui/PLMProductInfoHeaderPG"
                                    ,null
                                    ,OAWebBeanConstants.KEEP_MENU_CONTEXT
                                    ,null
                                    ,null
                                    ,true
                                    ,OAWebBeanConstants.ADD_BREAD_CRUMB_YES
                                    ,OAWebBeanConstants.IGNORE_MESSAGES);
      return;
    }
    if (pageContext.getParameter("Logisticsbtn") != null)
    {
      pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxmer/papb/webui/PLMProdLogisticsPG"
                                    ,null
                                    ,OAWebBeanConstants.KEEP_MENU_CONTEXT
                                    ,null
                                    ,null
                                    ,true
                                    ,OAWebBeanConstants.ADD_BREAD_CRUMB_YES
                                    ,OAWebBeanConstants.IGNORE_MESSAGES);
      return;
    }
    if (pageContext.getParameter("QaTestBtn") != null)
    {
      pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxmer/papb/webui/PLMProdQAPG"
                                    ,null
                                    ,OAWebBeanConstants.KEEP_MENU_CONTEXT
                                    ,null
                                    ,null
                                    ,true
                                    ,OAWebBeanConstants.ADD_BREAD_CRUMB_YES
                                    ,OAWebBeanConstants.IGNORE_MESSAGES);
      return;
    }
    if (pageContext.getParameter("SearchPageBtn") != null)
    {
      pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxmer/papb/webui/PLMProdInfoSearchPG"
                                    ,null
                                    ,OAWebBeanConstants.KEEP_MENU_CONTEXT
                                    ,null
                                    ,null
                                    ,true
                                    ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
                                    ,OAWebBeanConstants.IGNORE_MESSAGES);
      return;
    }

    // Currently we support Updat eonly for this screen
    if (pageContext.getParameter("Apply") != null)
    {
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      try
      {
        am.getTransaction().commit();
        OAException successMessage = new OAException("XXMER", m_strSuccessMsgToken, 
                                  null, OAException.INFORMATION, null); 
        //pageContext.releaseRootApplicationModule();
        pageContext.putDialogMessage(successMessage);
      }
      catch(Exception e)
      {
        am.getTransaction().rollback();
        MessageToken[] tokens = { new MessageToken("P_ERROR_MSG", e.getMessage())};
        OAException errMessage = new OAException("XXMER", m_strErrorMsgToken, 
                                  tokens, OAException.ERROR, null);
        //pageContext.releaseRootApplicationModule();
        pageContext.putDialogMessage(errMessage);
      }
    }
  }

}
