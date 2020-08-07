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
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import oracle.apps.fnd.framework.webui.beans.form.OAExportBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;

import oracle.jbo.Row;

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

 OASubmitButtonBean CreateT = (OASubmitButtonBean)webBean.findChildRecursive("Create");
 CreateT.setDisabled(true);
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
      OASubmitButtonBean CreateT = (OASubmitButtonBean)webBean.findChildRecursive("Create");
      CreateT.setDisabled(true);
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
          CreateT.setDisabled(false);
           ExportT.setDisabled(false);
          // UpdateT.setDisabled(false);
          // DeleteT.setDisabled(false);
          SaveT.setDisabled(true);
          CancelT.setDisabled(false);
      
      System.out.println("Save");
      mainAM.getOADBTransaction().commit();
          XxApSupTraitsVO.first();
          for(int i=0;i<XxApSupTraitsVO.getRowCount();i++) {
              XxApSupTraitsVO.getCurrentRow().setAttribute("DisableTrans",Boolean.TRUE);
              XxApSupTraitsVO.next();
          }
          
          
         // if (XxApSupTraitsVO.getCurrentRow().getAttribute("Attribute1")='A'){
          throw new OAException("Record(s) Saved Successfully",OAException.CONFIRMATION);
        //  }
        
      }
      
      if(pageContext.getParameter("Cancel")!=null) 
      {
      
          CreateT.setDisabled(false);
           ExportT.setDisabled(false);
          // UpdateT.setDisabled(false);
          // DeleteT.setDisabled(false);
          SaveT.setDisabled(false);
          CancelT.setDisabled(false);
      System.out.println("Roll Back");
      mainAM.getOADBTransaction().rollback();
          XxApSupTraitsVO.first();
          for(int i=0;i<XxApSupTraitsVO.getRowCount();i++) {
              XxApSupTraitsVO.getCurrentRow().setAttribute("DisableTrans",Boolean.TRUE);
              XxApSupTraitsVO.next();
          }
      }
             
    if(pageContext.getParameter("Go")!=null) 
        {
        
                 CreateT.setDisabled(false);
                  ExportT.setDisabled(false);
                 // UpdateT.setDisabled(false);
                 // DeleteT.setDisabled(false);
                 SaveT.setDisabled(false);
                 CancelT.setDisabled(false);
        
        
                if("".equals(pageContext.getParameter("Trait")))
                {
                 try{
                 //String where="sup_trait= nvl(:1,sup_trait)";
                 //XxApSupTraitsVO.setWhereClause(where);
                // XxApSupTraitsVO.setWhereClauseParam(0,null);
                 //XxApSupTraitsVO.setMaxFetchSize(-1); -- not required .
                 // String where="attribute1 IS NULL OR attribute1 <> 'D' ";
                 // XxApSupTraitsVO.setWhereClause(where);
                  
                 XxApSupTraitsVO.executeQuery();
                    
                     XxApSupTraitsVO.first();
                     for(int i=0;i<XxApSupTraitsVO.getRowCount();i++) {
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
                     XxApSupTraitsVO.getCurrentRow().setAttribute("DisableTrans",Boolean.TRUE);
                     XxApSupTraitsVO.next();
                 }
             }
             }
     
             if(pageContext.getParameter("Create")!=null) 
             {
                 CreateT.setDisabled(false);
                  ExportT.setDisabled(false);
                 // UpdateT.setDisabled(false);
                 // DeleteT.setDisabled(false);
                 SaveT.setDisabled(false);
                 CancelT.setDisabled(false);
             
                 XxApSupTraitsVO.first();
                 XxApSupTraitsVO.previous();
                 /*XxApSupTraitsVO.last();
                 XxApSupTraitsVO.next(); */
                 Row row=XxApSupTraitsVO.createRow();
                 XxApSupTraitsVO.insertRow(row);
                 Object HeaderID=mainAM.getOADBTransaction().getSequenceValue("XX_AP_SUP_TRAITS_SEQ");
                 row.setAttribute("SupTrait",HeaderID);
                 row.setAttribute("Attribute1",'A');
                 
             }
             
      if ("delete".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) 
       {      
          CreateT.setDisabled(false);
           ExportT.setDisabled(false);
          // UpdateT.setDisabled(false);
          // DeleteT.setDisabled(false);
          SaveT.setDisabled(false);
          CancelT.setDisabled(false);
       
      String rowReference =
         pageContext.getParameter(OAWebBeanConstants.EVENT_SOURCE_ROW_REFERENCE);
                     OAException message = new OAException("Are you sure you want to delete this row?",OAException.WARNING);  
                      //pageContext.putDialogMessage(message);
                     OADialogPage dialogPage = new OADialogPage(OAException.WARNING, message, null, "", "");          
                                      String yes = pageContext.getMessage("AK", "FWK_TBX_T_YES", null); 
                                      String no = pageContext.getMessage("AK", "FWK_TBX_T_NO", null); 
                                      dialogPage.setOkButtonItemName("DeleteYesButton");
                                      dialogPage.setOkButtonToPost(true); 
                                      dialogPage.setNoButtonToPost(true); 
                                      
                                      dialogPage.setOkButtonLabel(yes); 
                                      dialogPage.setNoButtonLabel(no);
                                      java.util.Hashtable   params = new java.util.Hashtable(0);                                    
                                      params.put("pRowRef",rowReference);
                                      dialogPage.setFormParameters(params);
                                      dialogPage.setPostToCallingPage(true); 
                                                                
                                      pageContext.redirectToDialogPage(dialogPage);                                                                           
      }
      
      if (pageContext.getParameter("DeleteYesButton") != null) {
                       // System.out.println(rowReference); 
                       OARow row = (OARow)mainAM.findRowByRef(pageContext.getParameter("pRowRef"));
                      // row.remove();
                       XxApSupTraitsVO.setCurrentRow(row);
                       String Param= (String)row.getAttribute("SupTrait");
                       //System.out.println("Supplier Trait Value is "+Param);
                       
                       /* XxApSupTraitsVO.first();
                       for(int i=0;i<XxApSupTraitsVO.getRowCount();i++) {  */
                       //XxApSupTraitsVO.getCurrentRow().setAttribute("DisableTrans",Boolean.FALSE);
                      // XxApSupTraitsVO.getCurrentRow().setAttribute("Attribute1",'D');
                       mainAM.getOADBTransaction().commit();
                       row.removeFromCollection();
                       
                      
                    //   if("".equals(Trait_param))
                    //   {
                     //  String where="sup_trait=NVL(Trait_param,sup_trait) AND (attribute1 IS NULL OR attribute1 <> 'D') ";
                       //    XxApSupTraitsVO.setWhereClause(where);
                              // XxApSupTraitsVO.setWhereClauseParam(0,null);
                           /* XxApSupTraitsVO.setMaxFetchSize(-1);*/
                           //XxApSupTraitsVO.executeQuery();
                          // System.out.println("Inside If");
                          // XxApSupTraitsVO.first();
                         //  for(int i=0;i<XxApSupTraitsVO.getRowCount();i++)
                          // {
                           //    XxApSupTraitsVO.getCurrentRow().setAttribute("DisableTrans",Boolean.TRUE);
                           //    XxApSupTraitsVO.next();
                          // }
                      // }
                     /*
                       if(Trait_param != null)
                      {
                      
                          String Trait=(String)pageContext.getParameter("Trait");
                          String where="sup_trait=:1 AND attribute1<>'D'"; 
                          
                          XxApSupTraitsVO.setWhereClause(where);
                          XxApSupTraitsVO.setWhereClauseParam(0,Trait);
                          XxApSupTraitsVO.executeQuery();
                          System.out.println("Inside Else");                                
                      }    
                      */
                      // mainAM.getOADBTransaction().commit();
                        OAException confirmation = new OAException("Record deleted Successfully", OAException.CONFIRMATION);
                        pageContext.putDialogMessage(confirmation); 
                   }                     
      
                
             if ("update".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) 
              {
                  CreateT.setDisabled(false);
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
