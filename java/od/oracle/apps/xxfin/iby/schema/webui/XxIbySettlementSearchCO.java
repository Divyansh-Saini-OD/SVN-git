/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxfin.iby.schema.webui;

import java.io.Serializable;

import od.oracle.apps.xxfin.iby.settlement.server.SettlementAMImpl;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OADefaultListBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageDateFieldBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLayoutBean;

import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;

import sun.security.x509.SerialNumber;


/**
 * Controller for ...
 */
public class XxIbySettlementSearchCO extends OAControllerImpl
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
      OAApplicationModule am = pageContext.getApplicationModule(webBean);

      if(pageContext.getParameter("Search") != null)
      {
 
      String lsLowDate = pageContext.getParameter("LowDate");
      String lsHighDate = pageContext.getParameter("HighDate");
      String lsRecptNum = pageContext.getParameter("RecptNum1");
      String lsStoreNum = pageContext.getParameter("StoreNum1");
      String lsRegNum  = pageContext.getParameter("RegNum1");
      String lsTrxNum =  pageContext.getParameter("TrxNum1");
      String lsBatchNum = pageContext.getParameter("BatchNum1");
      String lsDollarAmt =  pageContext.getParameter("DollarAmt1");
      String lsTrxType =  pageContext.getParameter("TrxType1");
      String lsOrdType1 =  pageContext.getParameter("OrdType1");
      
      Serializable[] params = {lsLowDate, lsHighDate, lsRecptNum, lsStoreNum, lsRegNum, lsTrxNum,
                               lsBatchNum, lsDollarAmt, lsTrxType, lsOrdType1
                              };
    
    am.invokeMethod("initIbyBatchTrxnsHistory",params);
      }
      
      if(pageContext.getParameter("Clear") != null)  
      {
        clear( pageContext, webBean, am);
      } 
      
  }
      public void clear(OAPageContext pageContext,OAWebBean webBean, OAApplicationModule am)
       {
       
     
       
       
       
         OAMessageDateFieldBean LowDateBean = (OAMessageDateFieldBean)webBean.findChildRecursive("LowDate");
         OAMessageDateFieldBean HighDateBean = (OAMessageDateFieldBean)webBean.findChildRecursive("HighDate");
         OAMessageTextInputBean RecptNumBean = (OAMessageTextInputBean)webBean.findChildRecursive("RecptNum1");
         OAMessageTextInputBean StoreNumBean = (OAMessageTextInputBean)webBean.findChildRecursive("StoreNum1");
         OAMessageTextInputBean RegNumBean = (OAMessageTextInputBean)webBean.findChildRecursive("RegNum1");
         OAMessageTextInputBean TrxNumBean = (OAMessageTextInputBean)webBean.findChildRecursive("TrxNum1");
         OAMessageTextInputBean DollarAmtBean = (OAMessageTextInputBean)webBean.findChildRecursive("DollarAmt1");
         OAMessageChoiceBean TrxTypeBean = (OAMessageChoiceBean)webBean.findChildRecursive("TrxType1");
         OAMessageChoiceBean OrdType1Bean = (OAMessageChoiceBean)webBean.findChildRecursive("OrdType1");


         if(LowDateBean != null)
         LowDateBean.setValue(pageContext,"");
         if(HighDateBean != null)
         HighDateBean.setValue(pageContext,"");
         if(RecptNumBean != null)
         RecptNumBean.setValue(pageContext,"");
         if(StoreNumBean != null)
         StoreNumBean.setValue(pageContext,"");    
         if(RegNumBean != null)
         RegNumBean.setValue(pageContext,""); 
         if(TrxNumBean != null)
         TrxNumBean.setValue(pageContext,""); 

         if(DollarAmtBean != null)
         DollarAmtBean.setValue(pageContext,"");
         if(TrxTypeBean != null)
         TrxTypeBean.setValue(pageContext,"");
         if(OrdType1Bean != null)
         OrdType1Bean.setValue(pageContext,"");
 

         
         Serializable[] params = { "01-JAN-0001","01-JAN-9999", "-1","-1","-1"
                                 ,"-1","-1","-1","-1","-1"
                                 };
         am.invokeMethod("initIbyBatchTrxnsHistory",params);    
       }  
        

}