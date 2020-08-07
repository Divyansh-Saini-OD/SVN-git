/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxfin.ap.idms.traitmatrix.webui;

import com.sun.java.util.collections.HashMap;

import java.awt.Window;

import java.io.Serializable;

import java.util.Hashtable;

import od.oracle.apps.xxfin.ap.idms.traitmatrix.server.SupplierMatrixAdvVOImpl;
import od.oracle.apps.xxfin.ap.idms.traitmatrix.server.XXSuppMatrixVOImpl;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.toolbox.labsolutions.Supplier;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OAFormValueBean;

import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;

import oracle.jbo.Row;

/**
 * Controller for ...
 */
public class XXSupplierMatrixCreateCO extends OAControllerImpl
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
    
    OAApplicationModule am = pageContext.getRootApplicationModule();
      String  sNumber = null;
    if(pageContext.getParameter("uTId")!=null  && !"".equals(pageContext.getParameter("uTId"))) {
    
        String  traId  = pageContext.getParameter("uTId");
        sNumber = pageContext.getParameter("uNo");
        String straitid = pageContext.getParameter("uTraitId");
        System.out.println("Sup Num "+sNumber +" --- Trait Id "+straitid);
        OAViewObject XxSupMatrixVO = 
               (OAViewObject)am.findViewObject("XXSuppMatrixVO1");
        XxSupMatrixVO.clearCache();
        XxSupMatrixVO.setWhereClause(null);
        String wclause  = " SUPPLIER = '"+sNumber+"'  AND  SUP_TRAIT_ID = '"+straitid+"'";
        XxSupMatrixVO.setWhereClause(wclause); 
        System.out.println("TRAIT "+traId+" -- Sno "+sNumber);
        System.out.println("SuppMatriv Query "+XxSupMatrixVO.getQuery());
        XxSupMatrixVO.executeQuery();
        //SupplierMatrixAdvVOImpl svo =getSupplierMatrixAdvVO1();
         //XXSuppMatrixVOImpl  vo =  getXXSuppMatrixVO1();
         
        Serializable[]  parms  = {traId,sNumber,straitid};
        am.invokeMethod("updMatrixRow",parms);
       // Serializable[]  parms1  = {sNumber};
       // am.invokeMethod("initSuppTraitLov",parms1);
    }
    else
    {
        sNumber = pageContext.getParameter("supNum");
        System.out.println("Sup Num "+sNumber);
        Serializable[]  parms  = {sNumber};
        am.invokeMethod("initMatrixRow",parms);
        
       // am.invokeMethod("initSuppTraitLov",parms);
        //System.out.println("supplier Trait LOV");
    }
     // pageContext.putSessionValue("SuppNum","816190");
      OAViewObject XxSuppTraitVO = 
             (OAViewObject)am.findViewObject("XXSuppTrait1");
      //XXSuppTraitImpl   vo =this.getXXSuppTrait1();
     //String Vendor_site_id = (String)pageContext.getSessionValue("SuppNum");
      String sql =  " 1=1 ";
       sql =  "NOT EXISTS (SELECT 1    FROM XX_AP_SUP_TRAITS_MATRIX xx  WHERE 1 =1 AND xx.SUP_TRAIT_ID= QRSLT.SUP_TRAIT_ID AND xx.SUPPLIER = "+sNumber+" )";
      XxSuppTraitVO.clearCache();
      XxSuppTraitVO.setWhereClause(null);
      XxSuppTraitVO.setWhereClause(sql);
      /*XxSuppTraitVO.clearCache();
          XxSuppTraitVO.setWhereClause(null);
          XxSuppTraitVO.setWhereClauseParams(null);
          XxSuppTraitVO.setWhereClauseParam(0,null);
          XxSuppTraitVO.setWhereClauseParam(0,Integer.parseInt(Vendor_site_id));  */
          
          XxSuppTraitVO.executeQuery();
          System.out.println("Supplier Trait lov query "+XxSuppTraitVO.getQuery());
       //  System.out.println("Vendor Site "+Vendor_site_id);
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
      OAApplicationModule am = (OAApplicationModule)pageContext.getRootApplicationModule();
      //OAApplicationModule mainAM =              (OAApplicationModule)pageContext.getApplicationModule(webBean);
           
     
     
      
      
      System.out.println("inside process form request "+pageContext.getParameter("Save"));
      if(pageContext.isLovEvent())  
       {   
            String lovInputSourceId = pageContext.getLovInputSourceId();  
            if("SupTrait".equals(lovInputSourceId)) {  
                 System.out.println("Inside isLovEvent of SupTrait from AdvancedTable");  
                 Hashtable lovResults = pageContext.getLovResultsFromSession(pageContext.getParameter(SOURCE_PARAM));  
                 if(lovResults!=null)  
                 {  
                      String supTraitId =(String)lovResults.get("formSupTraitID"); 
                      System.out.println("formSupTraitID:" + supTraitId);
                     String rowReference = pageContext.getParameter(EVENT_SOURCE_ROW_REFERENCE);
                     OAViewObject xxsuptraitvo =     (OAViewObject)am.findViewObject("XXSuppMatrixVO1");
                      Row r =xxsuptraitvo.first();
                      if (r !=null)
                      {
                          System.out.println("inside row not null");                          
                          r.setAttribute("SupTraitId",supTraitId);  
                      }
                                             
                 }
            }
       }   
      if(pageContext.getParameter("Save")!=null) {
      
          System.out.println("inside save");         
          am.getOADBTransaction().commit();
          throw new OAException("Record(s) Saved Successfully",OAException.CONFIRMATION);
                   
      }
      
      HashMap hashMap = new HashMap(1);    
      hashMap.put("pMode","createPG");
      
      if(pageContext.getParameter("Cancel")!=null) {
          pageContext.putSessionValue("sesClear","N");
                 
          pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxfin/ap/idms/traitmatrix/webui/XXSupplierMatrixPG",
                                       null,
                                       OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                       null,
                                       hashMap,
                                       true,
                                       OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
                                       OAWebBeanConstants.IGNORE_MESSAGES);


     
      }
    
  }

}
