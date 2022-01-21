/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxfin.ap.idms.traitmaster.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import oracle.apps.fnd.framework.webui.beans.form.OAExportBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;

import oracle.jbo.Row;
import oracle.jbo.domain.Number;

/**
 * Controller for ...
 */
public class XXTraitMasterPGCO extends OAControllerImpl
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
      OAApplicationModule mainAM = 
               (OAApplicationModule)pageContext.getApplicationModule(webBean);
      OAViewObject XxApSupTraitsVO = 
             (OAViewObject)mainAM.findViewObject("XxApSupTraitsVO1");
//      XxApSupTraitsVO.setWhereClause("1=2");
//      XxApSupTraitsVO.executeQuery();

 //OASubmitButtonBean CreateT = (OASubmitButtonBean)webBean.findChildRecursive("Create");
 //CreateT.setDisabled(true);
 OAExportBean ExportT = (OAExportBean)webBean.findChildRecursive("Export");
 ExportT.setDisabled(true);
 // OASubmitButtonBean UpdateT = (OASubmitButtonBean)webBean.findChildRecursive("Update");
 // UpdateT.setDisabled(true);
 // OASubmitButtonBean DeleteT = (OASubmitButtonBean)webBean.findChildRecursive("Delete");
 // DeleteT.setDisabled(true);
 OASubmitButtonBean SaveT = (OASubmitButtonBean)webBean.findChildRecursive("Save");
 SaveT.setDisabled(true);
 OASubmitButtonBean CancelT = (OASubmitButtonBean)webBean.findChildRecursive("Cancel");
 CancelT.setDisabled(true);
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
      OAApplicationModule mainAM = 
               (OAApplicationModule)pageContext.getApplicationModule(webBean);
      OAViewObject XxApSupTraitsVO = 
             (OAViewObject)mainAM.findViewObject("XxApSupTraitsVO1");
      //OASubmitButtonBean CreateT = (OASubmitButtonBean)webBean.findChildRecursive("Create");
      //CreateT.setDisabled(true);
      OAExportBean ExportT = (OAExportBean)webBean.findChildRecursive("Export");
      ExportT.setDisabled(true);
      // OASubmitButtonBean UpdateT = (OASubmitButtonBean)webBean.findChildRecursive("Update");
      // UpdateT.setDisabled(true);
      // OASubmitButtonBean DeleteT = (OASubmitButtonBean)webBean.findChildRecursive("Delete");
      // DeleteT.setDisabled(true);
      OASubmitButtonBean SaveT = (OASubmitButtonBean)webBean.findChildRecursive("Save");
      SaveT.setDisabled(true);
      OASubmitButtonBean CancelT = (OASubmitButtonBean)webBean.findChildRecursive("Cancel");
      CancelT.setDisabled(true);       
             
             
             String Trait_param = (String)pageContext.getParameter("Trait");
             
             
      if(pageContext.getParameter("Save")!=null) {
          XxApSupTraitsVO.clearCache();
         // CreateT.setDisabled(false);
           ExportT.setDisabled(false);          
      
      System.out.println("Save");
      try
      {
      mainAM.getOADBTransaction().commit();
      }
          catch (Exception e) {
                   throw new OAException("Please enter Unique value for Supp Trait"+e, OAException.ERROR);
              }
           
          XxApSupTraitsVO.setWhereClauseParams(null);
          String where="1=1 ";          
          XxApSupTraitsVO.setWhereClause(where);
          XxApSupTraitsVO.executeQuery();
          XxApSupTraitsVO.first();
          for(int i=0;i<XxApSupTraitsVO.getRowCount();i++) {
              XxApSupTraitsVO.getCurrentRow().setAttribute("DisableTrans",Boolean.TRUE);
              XxApSupTraitsVO.next();
          }
          
          System.out.println(XxApSupTraitsVO.getQuery());  
          SaveT.setDisabled(true);          
          CancelT.setDisabled(true); 
         // if (XxApSupTraitsVO.getCurrentRow().getAttribute("Attribute1")='A'){
          throw new OAException("Record(s) Saved Successfully",OAException.CONFIRMATION);
         
        
      }
      
      if(pageContext.getParameter("Cancel")!=null) 
      {
      
          //CreateT.setDisabled(false);
           ExportT.setDisabled(false);
          // UpdateT.setDisabled(false);
          // DeleteT.setDisabled(false);
//          SaveT.setDisabled(false);
  //        CancelT.setDisabled(false);
      System.out.println("Roll Back");
      mainAM.getOADBTransaction().rollback();
          XxApSupTraitsVO.first();
          for(int i=0;i<XxApSupTraitsVO.getRowCount();i++) {
              XxApSupTraitsVO.getCurrentRow().setAttribute("DisableTrans",Boolean.TRUE);
              XxApSupTraitsVO.next();
          }
          SaveT.setDisabled(true);          
          CancelT.setDisabled(true);
      }
      //String createFirst = "Y";             
             
    if(pageContext.getParameter("Go")!=null) 
        {
        
                // CreateT.setDisabled(false);
                  ExportT.setDisabled(false);
                 // UpdateT.setDisabled(false);
                 // DeleteT.setDisabled(false);
                 SaveT.setDisabled(true);
                 CancelT.setDisabled(true);
                 
        
                if("".equals(pageContext.getParameter("Trait")))
                {
                 try{
                 //String where="sup_trait= nvl(:1,sup_trait)";
                 //XxApSupTraitsVO.setWhereClause(where);
                // XxApSupTraitsVO.setWhereClauseParam(0,null);
                 //XxApSupTraitsVO.setMaxFetchSize(-1); -- not required .
                 // String where="attribute1 IS NULL OR attribute1 <> 'D' ";
                 // XxApSupTraitsVO.setWhereClause(where);
                  String where="1=1 ";
                  XxApSupTraitsVO.setWhereClause(where);
                 XxApSupTraitsVO.executeQuery();
                    
                     XxApSupTraitsVO.first();
                     for(int i=0;i<XxApSupTraitsVO.getRowCount();i++) {
                         //createFirst = "N";
                         XxApSupTraitsVO.getCurrentRow().setAttribute("DisableTrans",Boolean.TRUE);
                         XxApSupTraitsVO.next();
                     }
                                                        
                 }
                 catch (Exception e){
                 pageContext.writeDiagnostics(this,"e :"+e,1);   
                 pageContext.writeDiagnostics(this,"XxApSupTraitsVO query :"+XxApSupTraitsVO.getQuery(),1);
                 System.out.println("XxApSupTraitsVO query :"+XxApSupTraitsVO.getQuery());
                 }
                }
                else 
                {
                     String Trait=(String)pageContext.getParameter("Trait");
                     String where="sup_trait=:1"; 
                 
                     XxApSupTraitsVO.setWhereClause(where);
                 XxApSupTraitsVO.setWhereClauseParam(0,Trait);
                     XxApSupTraitsVO.executeQuery();
                 
                 XxApSupTraitsVO.first();
                 for(int i=0;i<XxApSupTraitsVO.getRowCount();i++) {
                    // createFirst = "N";
                     XxApSupTraitsVO.getCurrentRow().setAttribute("DisableTrans",Boolean.TRUE);
                     XxApSupTraitsVO.next();
                 }
             }
             }
     
             if(pageContext.getParameter("Create")!=null) 
             {
               //  CreateT.setDisabled(false);
                  ExportT.setDisabled(false);
                 // UpdateT.setDisabled(false);
                 // DeleteT.setDisabled(false);
                 SaveT.setDisabled(false);
                 CancelT.setDisabled(false);
                 
                     if("".equals(pageContext.getParameter("Trait")))
                 {
                     String where="1=1 ";
                     XxApSupTraitsVO.setWhereClause(where);
                     XxApSupTraitsVO.executeQuery();
                     XxApSupTraitsVO.first();
                 }
                 else {
                     String trait=(String)pageContext.getParameter("Trait");
                      String where="sup_trait=:1"; 
                      XxApSupTraitsVO.setWhereClause(where);
                      XxApSupTraitsVO.setWhereClauseParam(0,trait);
                      XxApSupTraitsVO.executeQuery();
                      XxApSupTraitsVO.first();
                      XxApSupTraitsVO.previous();
                 }
                 
                 /*XxApSupTraitsVO.last();
                 XxApSupTraitsVO.next(); */
                 Row row=XxApSupTraitsVO.createRow();
                 XxApSupTraitsVO.insertRow(row);
                 OADBTransaction transaction = (OADBTransaction)mainAM.getOADBTransaction();
                 Number HeaderID=transaction.getSequenceValue("XX_AP_SUP_TRAITS_SEQ");
                 //row.setAttribute("SupTrait",HeaderID);
                  row.setAttribute("SupTraitId",HeaderID);
                 row.setAttribute("Attribute1",'A');
                 
             }
             
                
             if ("update".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) 
              {
                 // CreateT.setDisabled(false);
                   ExportT.setDisabled(false);
                  // UpdateT.setDisabled(false);
                  // DeleteT.setDisabled(false);
                  SaveT.setDisabled(false);
                  CancelT.setDisabled(false);
              
             // String UpdateTrait=pageContext.getParameter("UpdateTrait");
             // System.out.println("UpdateTrait---"+UpdateTrait);
              
              String rowRef = pageContext.getParameter(OAWebBeanConstants.EVENT_SOURCE_ROW_REFERENCE);
              
               Row  row=   mainAM.findRowByRef(rowRef);
               
                  XxApSupTraitsVO.setCurrentRow(row);
            
                 /* XxApSupTraitsVO.first();
                  for(int i=0;i<XxApSupTraitsVO.getRowCount();i++) {  */
                      XxApSupTraitsVO.getCurrentRow().setAttribute("DisableTrans",Boolean.FALSE);
                   XxApSupTraitsVO.getCurrentRow().setAttribute("Attribute1",'U');
                 // XxApSupTraitsVO.executeQuery();
                    /*  XxApSupTraitsVO.next();
                  } */
                    // throw new OAException("Record Updated Successfully",OAException.CONFIRMATION);
              }
      if (pageContext.getParameter("Clear") != null) 
            { // retain AM
                      pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxfin/ap/idms/traitmaster/webui/XXTraitMasterPG",
                                                  null,
                                                  OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                                  null, null, false,
                                                  OAWebBeanConstants.ADD_BREAD_CRUMB_NO);
            }
  }

}
