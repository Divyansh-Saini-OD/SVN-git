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
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.beans.OAImageBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import od.oracle.apps.xxmer.papb.server.GenPrdDtlVOImpl;
import od.oracle.apps.xxmer.papb.server.GenPrdDtlVORowImpl;
import od.oracle.apps.xxmer.papb.server.PAPBAMImpl;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAImageBean;
import oracle.apps.fnd.framework.webui.OADecimalValidater;
import oracle.cabo.ui.validate.Formatter;



/**
 * Controller for ...
 */
public class PLMProductInfoHeaderCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  protected String m_strSuccessMsgToken;
  protected String m_strErrorMsgToken;
  
  public PLMProductInfoHeaderCO()
  {
      m_strSuccessMsgToken = "FND_CONFIRM_UPDATE";
      m_strErrorMsgToken = "XXMER_PA_PB_UPDATE_RECORD_ERR";
  }
  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
    if (!pageContext.isFormSubmission())
    {
      String strProjNum = pageContext.getParameter("PROJNUM"); 
      if (strProjNum != null)
      {
        String strImgSrc = pageContext.getParameter("IMGSRC");
        String strVPC = pageContext.getParameter("VPC");

        OAPageLayoutBean pageLayoutBean = (OAPageLayoutBean)webBean;
        OAImageBean imgBean = (OAImageBean) pageLayoutBean.findChildRecursive("ProductImg");
        imgBean.setSource(strImgSrc);

        PAPBAMImpl am = (PAPBAMImpl)pageContext.getApplicationModule(webBean);
        GenPrdDtlVOImpl vo = am.getGenPrdDtlVO1();
        /*if(vo==null)
        {
          MessageToken[] errTokens = {new MessageToken("OBJECT_NAME","SSCapsMultiVO2")};
          throw new OAException("XXMER","XXMER_VC_OBJECT_NOT_FOUND",errTokens);
        }*/
        vo.setWhereClause("PROJECT_NO = :1 and VPC = :2");
        vo.setWhereClauseParams(null); //Always reset
        vo.setWhereClauseParam(0, strProjNum);
        vo.setWhereClauseParam(1, strVPC);
        vo.executeQuery();
      }
      else
      {
        PAPBAMImpl am = (PAPBAMImpl)pageContext.getApplicationModule(webBean);
        GenPrdDtlVOImpl vo = am.getGenPrdDtlVO1();
        GenPrdDtlVORowImpl row = (GenPrdDtlVORowImpl) vo.getCurrentRow();
        OAPageLayoutBean pageLayoutBean = (OAPageLayoutBean)webBean;
        OAImageBean imgBean = (OAImageBean) pageLayoutBean.findChildRecursive("ProductImg");
        imgBean.setSource(row.getProductImage());
      }
      
      OAPageLayoutBean pageLayoutBean = (OAPageLayoutBean)webBean;
      Formatter formatter = new OADecimalValidater("#,##0.00;(#,##0.00)","#,##0.00;(#,##0.00)");
      OAWebBean DDPBean = pageLayoutBean.findChildRecursive("txtDDP");
      DDPBean.setAttributeValue(ON_SUBMIT_VALIDATER_ATTR, formatter);        
      OAWebBean FOBBean = pageLayoutBean.findChildRecursive("txtFOB");
      FOBBean.setAttributeValue(ON_SUBMIT_VALIDATER_ATTR, formatter);
      OAWebBean GMBean = pageLayoutBean.findChildRecursive("textProjectedDolGM");
      GMBean.setAttributeValue(ON_SUBMIT_VALIDATER_ATTR, formatter);

      Formatter formatter1 = new OADecimalValidater("#,##0.0;(#,##0.0)","#,##0.0;(#,##0.0)");
      OAWebBean PctGMBean = pageLayoutBean.findChildRecursive("txtpctProjGM");
      PctGMBean.setAttributeValue(ON_SUBMIT_VALIDATER_ATTR, formatter1); 
      OAWebBean ASPBean = pageLayoutBean.findChildRecursive("txtProjASPDol");
      ASPBean.setAttributeValue(ON_SUBMIT_VALIDATER_ATTR, formatter1);

      
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
      try
      {
        //Calculated fields
        
        GenPrdDtlVOImpl vo3 = am.getGenPrdDtlVO1();
        GenPrdDtlVORowImpl row = (GenPrdDtlVORowImpl) vo3.getCurrentRow();
        if(row.getProjectsAsp() == null)
        {
          if(row.getDdpAmnt() != null)
          {
            double dDDP= row.getDdpAmnt().doubleValue();
            if(row.getProjectedGmPct() != null)
            {
              double dPctGM = (row.getProjectedGmPct().doubleValue())/100.0;
              double dASP = dDDP/(1.0-dPctGM);
              oracle.jbo.domain.Number x = new oracle.jbo.domain.Number(dASP);
              row.setProjectsAsp(x);
            }
          }
        }
        else if(row.getProjectedGmPct() == null)
        {
          if (row.getDdpAmnt() != null)
          {
            double dDDP= row.getDdpAmnt().doubleValue();
            if(row.getProjectsAsp() != null)
            {
              double dASP = row.getProjectsAsp().doubleValue();
              double dPctGM = (1.0-(dDDP/dASP))*100.0;
              oracle.jbo.domain.Number x = new oracle.jbo.domain.Number(dPctGM);
              row.setProjectedGmPct(x);
            }
          }
        }
        else
        {
          if (row.getDdpAmnt() != null)
          {
            double dDDP= row.getDdpAmnt().doubleValue();
            double dASP = row.getProjectsAsp().doubleValue();
            double dPctGM = row.getProjectedGmPct().doubleValue()/100.0;
            if (Math.abs(dDDP-(1.0-dPctGM)*dASP) > 0.01)
              throw new Exception("DDP, ASP, %GM did not match");
          }
        }

        if(row.getProjectedGm() == null)
        {
          if (row.getDdpAmnt() != null)
          {
            double dDDP= row.getDdpAmnt().doubleValue();
            if(row.getProjectsAsp() != null)
            {
              double dASP = row.getProjectsAsp().doubleValue();
              double dProjGM = dASP-dDDP;
              oracle.jbo.domain.Number x = new oracle.jbo.domain.Number(dProjGM);
              row.setProjectedGm(x);
            }
          }
        }
        else
        {
          double dProjGM = row.getProjectedGm().doubleValue();
          if (row.getDdpAmnt() != null)
          {
            double dDDP= row.getDdpAmnt().doubleValue();
            if(row.getProjectsAsp() != null)
            {
              double dASP = row.getProjectsAsp().doubleValue();
              if (Math.abs(dProjGM - dASP + dDDP) > 0.01)
                throw new Exception("DDP, ASP, Projected GM did not match");
            }
          }
        }
        
        am.getTransaction().commit();
        vo3.executeQuery();
        MessageToken[] tokens = { new MessageToken("OBJECT", "General Product Information ")};
        OAException successMessage = new OAException("FND", m_strSuccessMsgToken, 
                                  tokens, OAException.INFORMATION, null); 
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
