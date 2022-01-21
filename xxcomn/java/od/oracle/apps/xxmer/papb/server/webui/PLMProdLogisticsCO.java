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
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import od.oracle.apps.xxmer.papb.server.prdLogisticsVOImpl;
import od.oracle.apps.xxmer.papb.server.PrdLogisticsImpDtlVOImpl;
import od.oracle.apps.xxmer.papb.server.PrdLogisticsImpDtlVORowImpl;
import od.oracle.apps.xxmer.papb.server.prdLogisticsVORowImpl;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAImageBean;
import oracle.apps.fnd.framework.webui.OADecimalValidater;
import oracle.cabo.ui.validate.Formatter;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;



/**
 * Controller for ...
 */
public class PLMProdLogisticsCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  protected String m_strSuccessMsgToken;
  protected String m_strErrorMsgToken;
  
  public PLMProdLogisticsCO()
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
    
    prdLogisticsVOImpl vo1 = am.getprdLogisticsVO1();
    /*if(vo1==null)
    {
      MessageToken[] errTokens = {new MessageToken("OBJECT_NAME","SSCapsMultiVO2")};
      throw new OAException("XXMER","XXMER_VC_OBJECT_NOT_FOUND",errTokens);
    }*/
    vo1.setWhereClause("PROD_DTL_ID = :1");
    vo1.setWhereClauseParams(null); //Always reset
    vo1.setWhereClauseParam(0, strProdDtlId);
    vo1.executeQuery();
    
    PrdLogisticsImpDtlVOImpl vo2 = am.getPrdLogisticsImpDtlVO1();
    /*if(vo2==null)
    {
      MessageToken[] errTokens = {new MessageToken("OBJECT_NAME","SSCapsMultiVO2")};
      throw new OAException("XXMER","XXMER_VC_OBJECT_NOT_FOUND",errTokens);
    }*/
    vo2.setWhereClause("PROD_DTL_ID = :1");
    vo2.setWhereClauseParams(null); //Always reset
    vo2.setWhereClauseParam(0, strProdDtlId);
    vo2.executeQuery();

    OAPageLayoutBean pageLayoutBean = (OAPageLayoutBean)webBean;
    OAImageBean imgBean = (OAImageBean) pageLayoutBean.findChildRecursive("ProductImg");
    imgBean.setSource(row.getProductImage());  

    //Format numeric columns
    OATableBean table = (OATableBean)webBean.findIndexedChildRecursive("PkgDetailTable");
    /*if (table == null)
    {
      MessageToken[] tokens = { new MessageToken("OBJECT_NAME", "OrdersTable") };
      throw new OAException("AK", "FWK_TBX_OBJECT_NOT_FOUND", tokens);
    }*/
    Formatter formatter = new OADecimalValidater("#,##0.0;(#,##0.0)","#,##0.0;(#,##0.0)");

    OAWebBean LenBean = table.findChildRecursive("Len");
    LenBean.setAttributeValue(ON_SUBMIT_VALIDATER_ATTR, formatter); 

    OAWebBean WidthBean = table.findChildRecursive("Width");
    WidthBean.setAttributeValue(ON_SUBMIT_VALIDATER_ATTR, formatter); 

    OAWebBean HeightBean = table.findChildRecursive("Height");
    HeightBean.setAttributeValue(ON_SUBMIT_VALIDATER_ATTR, formatter); 

    OAWebBean WeightBean = table.findChildRecursive("Weight");
    WeightBean.setAttributeValue(ON_SUBMIT_VALIDATER_ATTR, formatter); 

    OAWebBean CmbBean = table.findChildRecursive("Cmb");
    CmbBean.setAttributeValue(ON_SUBMIT_VALIDATER_ATTR, formatter); 

    OAWebBean CuftBean = table.findChildRecursive("Cuft");
    CuftBean.setAttributeValue(ON_SUBMIT_VALIDATER_ATTR, formatter); 
    

  
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
    if (pageContext.getParameter("DutyTariffBtn") != null)
    {
      pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxmer/papb/webui/PLMProdDutyTariffPG"
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
      PAPBAMImpl am = (PAPBAMImpl)pageContext.getApplicationModule(webBean);
      GenPrdDtlVOImpl vo3 = am.getGenPrdDtlVO1();
      GenPrdDtlVORowImpl row = (GenPrdDtlVORowImpl) vo3.getCurrentRow();
      String str = row.getProdDtlId().toString();

      prdLogisticsVOImpl vo1 = am.getprdLogisticsVO1();
      prdLogisticsVORowImpl logisticsRow = (prdLogisticsVORowImpl) vo1.getCurrentRow();
    
      PrdLogisticsImpDtlVOImpl vo2 = am.getPrdLogisticsImpDtlVO1();
      for (int i=0; i < vo2.getRowCount(); i++)
      {
        PrdLogisticsImpDtlVORowImpl row2 = (PrdLogisticsImpDtlVORowImpl)vo2.getRowAtRangeIndex(i);
        if (row2.getPkgType().equalsIgnoreCase("Sell Unit"))
        {
          logisticsRow.setSlQty(row2.getQty());
          logisticsRow.setSlLength(row2.getLen());
          logisticsRow.setSlWidth(row2.getWidth());
          logisticsRow.setSlHeight(row2.getHeight());
          logisticsRow.setSlWeight(row2.getWeight());
          logisticsRow.setSlCmb(row2.getCmb());
          logisticsRow.setSlCuft(row2.getCuft());
        }
        else if (row2.getPkgType().equalsIgnoreCase("Inner Carton"))
        {
          logisticsRow.setIcQty(row2.getQty());
          logisticsRow.setIcLength(row2.getLen());
          logisticsRow.setIcWidth(row2.getWidth());
          logisticsRow.setIcHeight(row2.getHeight());
          logisticsRow.setIcWeight(row2.getWeight());
          logisticsRow.setIcCmb(row2.getCmb());
          logisticsRow.setIcCuft(row2.getCuft());
        }
        else if (row2.getPkgType().equalsIgnoreCase("Master Carton"))
        {
          logisticsRow.setMcQty(row2.getQty());
          logisticsRow.setMcLength(row2.getLen());
          logisticsRow.setMcWidth(row2.getWidth());
          logisticsRow.setMcHeight(row2.getHeight());
          logisticsRow.setMcWeight(row2.getWeight());
          logisticsRow.setMcCmb(row2.getCmb());
          logisticsRow.setMcCuft(row2.getCuft());
        }
      }

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
