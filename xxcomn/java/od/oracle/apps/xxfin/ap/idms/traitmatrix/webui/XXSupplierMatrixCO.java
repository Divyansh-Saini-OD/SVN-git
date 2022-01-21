/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxfin.ap.idms.traitmatrix.webui;

import java.io.Serializable;

import com.sun.java.util.collections.HashMap; 

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OAExportBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;

import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;

import oracle.jbo.Row;

/**
 * Controller for ...
 */
public class XXSupplierMatrixCO extends OAControllerImpl
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
      OAViewObject XxSupTraitMatrixVO = 
             (OAViewObject)mainAM.findViewObject("SupplierMatrixAdvVO1");
    
     // XxSupTraitMatrixVO.setWhereClause("1=2"); 
     // XxSupTraitMatrixVO.executeQuery();
     
    /* Serializable[] params ={"F"};
     mainAM.invokeMethod("enableTarget",params);*/
     
     System.out.println("pmode-->"+pageContext.getParameter("pMode"));
     if(pageContext.getParameter("pMode")!=null){
     
     if(!pageContext.isFormSubmission()  && pageContext.getSessionValue("sesClear")!=null )
     {
     if("Y".equals(pageContext.getSessionValue("sesClear")))
     {
     }
     else
     {
     if("createPG".equalsIgnoreCase(pageContext.getParameter("pMode")))
     {
     
     String Supplier  = null;
     String altSupp   = null;
     String  regId    = null;
     String  inActDt  = null;
     String  alias    = null;
     
       
       String sql = "1=1";
   
     try{
        OAMessageTextInputBean supNum = (OAMessageTextInputBean)webBean.findChildRecursive("XXSupplierNumber"); 
        OAMessageTextInputBean altSup = (OAMessageTextInputBean)webBean.findChildRecursive("AlternateSupplier");
        if(supNum.getValue(pageContext)!=null)
          Supplier  = supNum.getValue(pageContext).toString();
       if(altSup.getValue(pageContext)!=null)
          altSupp= altSup.getValue(pageContext).toString();
       regId= pageContext.getParameter("RegistryID");
       inActDt= pageContext.getParameter("InactiveDate");
       alias= pageContext.getParameter("Alias");
       System.out.println("Supplier"+Supplier+"altSupp"+altSupp+"regId"+inActDt+"alias"+alias);

     if(Supplier!=null && !"".equals(Supplier)) {
     
     sql = sql + " AND SUPPLIER ='"+Supplier+"'";
     
     }
     
     if(altSupp!=null && !"".equals(altSupp)) {
           
           sql = sql + " AND ALTERNATE_SUPPLIER ='"+altSupp+"'";
           
       }
       
       
     if(inActDt!=null && !"".equals(inActDt)) {
                
                sql = sql + " AND INACTIVE_DATE ='"+inActDt+"'";
                
            }  

         XxSupTraitMatrixVO.setWhereClause(sql);
         
         System.out.println("Checking Query "+XxSupTraitMatrixVO.getQuery());
         XxSupTraitMatrixVO.executeQuery();
         
         if(XxSupTraitMatrixVO.getRowCount()>0) {
             Serializable[] params ={"N"};
             mainAM.invokeMethod("enableTarget",params);
         }
     
     XxSupTraitMatrixVO.first();
     for(int i=0;i<XxSupTraitMatrixVO.getRowCount();i++) {
         XxSupTraitMatrixVO.getCurrentRow().setAttribute("DisableTrans",Boolean.TRUE);
         XxSupTraitMatrixVO.next();
     }
         OASubmitButtonBean CreateT = (OASubmitButtonBean)webBean.findChildRecursive("Create");
         CreateT.setDisabled(false);
         OAExportBean ExportT = (OAExportBean)webBean.findChildRecursive("Export");
         ExportT.setDisabled(false);
         
     
     }
     catch (Exception e){
     pageContext.writeDiagnostics(this,"e :"+e,1);
     pageContext.writeDiagnostics(this,"XxApSupTraitsVO query :"+XxSupTraitMatrixVO.getQuery(),1);
     System.out.println("XxApSupTraitsVO query :"+XxSupTraitMatrixVO.getQuery());
     }
     }
     }
     }
     }
     else
     { 
     OASubmitButtonBean CreateT = (OASubmitButtonBean)webBean.findChildRecursive("Create");
 CreateT.setDisabled(true);
 OAExportBean ExportT = (OAExportBean)webBean.findChildRecursive("Export");
 ExportT.setDisabled(true);
     }
      System.out.println("Responsibility Name" + 
                         pageContext.getResponsibilityName());
                         
      String respname = pageContext.getResponsibilityName();
      
       if("OD SCM Supplier Setup".equals(respname)) {
      //if("System Administrator".equals(respname)) { 
          OAViewObject XxApSupplierLov = 
              (OAViewObject)mainAM.findViewObject("xxsuppliernamelov1");
         String where = "1=1";
              where = where + " AND pay_site_flag = '" + "Y" + "'";
              XxApSupplierLov.setWhereClause(where);
          System.out.println("XxApSupplierLov query " +XxApSupplierLov.getQuery());
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
    System.out.println("in PFR");
      OAApplicationModule mainAM = 
                    (OAApplicationModule)pageContext.getApplicationModule(webBean);
           OAViewObject XxSupTraitMatrixVO = 
                  (OAViewObject)mainAM.findViewObject("SupplierMatrixAdvVO1");
                  
      
 
                  
           if(pageContext.getParameter("Save")!=null)
           {

           System.out.println("Save");
           mainAM.getOADBTransaction().commit();
               XxSupTraitMatrixVO.first();
               for(int i=0;i<XxSupTraitMatrixVO.getRowCount();i++)
               {
                   XxSupTraitMatrixVO.getCurrentRow().setAttribute("DisableTrans",Boolean.TRUE);
                   XxSupTraitMatrixVO.next();
               }
           
           } 
           
      if(pageContext.getParameter("Cancel")!=null)
      {
 
      System.out.println("Cancel");
      mainAM.getOADBTransaction().rollback();
          XxSupTraitMatrixVO.first();
          for(int i=0;i<XxSupTraitMatrixVO.getRowCount();i++) 
          {
              XxSupTraitMatrixVO.getCurrentRow().setAttribute("DisableTrans",Boolean.TRUE);
              XxSupTraitMatrixVO.next();
          }
      
      } 
           
    String Supplier  = null;
    String altSupp   = null;
    String  regId    = null;
    String  inActDt  = null;
    String  alias    = null;
    
      
      String sql = "1=1";
 if(pageContext.getParameter("Go")!=null) 
                   {  
     OASubmitButtonBean CreateT = (OASubmitButtonBean)webBean.findChildRecursive("Create");
     CreateT.setDisabled(false);

                       try{
//                     OAMessageStyledTextBean  bean = (OAMessageStyledTextBean)webBean.findChildRecursive("XXSupplierNumber");
//                         System.out.println("Supplier Number is :"+bean.getValue(pageContext));
//                     if(bean!=null && bean.getValue(pageContext)!=null)
//                     {

                       
                        Supplier  = pageContext.getParameter("XXSupplierNumber");//bean.getValue(pageContext);
                        altSupp= pageContext.getParameter("AlternateSupplier");
                         regId= pageContext.getParameter("RegistryID");
                         inActDt= pageContext.getParameter("InactiveDate");
                         alias= pageContext.getParameter("Alias");
                       
//                       System.out.println("Supplier Number is :"+Supplier);
//                           String where="supplier="+Supplier;
//              

                   if(Supplier!=null && !"".equals(Supplier)) {
                       
                       sql = sql + " AND SUPPLIER ='"+Supplier+"'";
                       
                   }
                   
                    if(altSupp!=null && !"".equals(altSupp)) {
                             
                             sql = sql + " AND ALTERNATE_SUPPLIER ='"+altSupp+"'";
                             
                         }
                         
                         
                    if(inActDt!=null && !"".equals(inActDt)) {
                                  
                                  sql = sql + " AND INACTIVE_DATE ='"+inActDt+"'";
                                  
                              }  
                   
                   
                   
                        // XxSupTraitMatrixVO.setWhereClause(null);
                        //sql= sql+ "AND (attribute1 IS NULL OR attribute1 <>'D') ";
                           XxSupTraitMatrixVO.setWhereClause(sql);
                           
                           System.out.println("Checking Query "+XxSupTraitMatrixVO.getQuery());
                           XxSupTraitMatrixVO.executeQuery();
                           
                           if(XxSupTraitMatrixVO.getRowCount()>0) {
                               Serializable[] params ={"N"};
                               mainAM.invokeMethod("enableTarget",params);                               
                               OAExportBean ExportT = (OAExportBean)webBean.findChildRecursive("Export");
                               ExportT.setDisabled(false);
                               
                           }
                       
                       XxSupTraitMatrixVO.first();
                       for(int i=0;i<XxSupTraitMatrixVO.getRowCount();i++) {
                           XxSupTraitMatrixVO.getCurrentRow().setAttribute("DisableTrans",Boolean.TRUE);
                           XxSupTraitMatrixVO.next();
                       }
                     //}
                       
                     }
      catch (Exception e){
      pageContext.writeDiagnostics(this,"e :"+e,1);   
      pageContext.writeDiagnostics(this,"XxApSupTraitsVO query :"+XxSupTraitMatrixVO.getQuery(),1);
      System.out.println("XxApSupTraitsVO query :"+XxSupTraitMatrixVO.getQuery());
      }
                  
 }
                   
      Supplier  = pageContext.getParameter("XXSupplierNumber");//bean.getValue(pageContext);
      altSupp= pageContext.getParameter("AlternateSupplier");
      
      if(Supplier!=null && !"".equals(Supplier)) {
          
          sql = sql + " AND SUPPLIER ='"+Supplier+"'";
          
      }
      
       if(altSupp!=null && !"".equals(altSupp)) {
                
                sql = sql + " AND ALTERNATE_SUPPLIER ='"+altSupp+"'";
                
         }             
                   
      /* if("Site_Status".equals(pageContext.getParameter("event"))) {
           
           
             String SiteStatus = pageContext.getParameter("SiteStatus");
             
             if(SiteStatus!=null  && !"".equals(SiteStatus))
             {
             
               sql = sql + " AND SITE_STATUS = '"+SiteStatus+"'";
             }
             
          // XxSupTraitMatrixVO.setWhereClause(null);
          // sql= sql+ "AND (attribute1 IS NULL OR attribute1 <>'D') ";
           XxSupTraitMatrixVO.setWhereClause(sql);
           System.out.println("Checking Query1 "+XxSupTraitMatrixVO.getQuery());
           XxSupTraitMatrixVO.executeQuery();
             
           if(XxSupTraitMatrixVO.getRowCount()>0) {
               Serializable[] params ={"N"};
               mainAM.invokeMethod("enableTarget",params);
           }
           
           XxSupTraitMatrixVO.first();
           for(int i=0;i<XxSupTraitMatrixVO.getRowCount();i++) {
               XxSupTraitMatrixVO.getCurrentRow().setAttribute("DisableTrans",Boolean.TRUE);
               XxSupTraitMatrixVO.next();
           }
             
       }
       
      
      if("SITE_NAME".equals(pageContext.getParameter("event"))) {
      
      
      String SiteName = pageContext.getParameter("SiteName");
      
      if(SiteName!=null  && !"".equals(SiteName))
      {
      
      sql = sql + "AND SITENAME LIKE  NVL('"+SiteName+"',' ')";
      }
      
      // XxSupTraitMatrixVO.setWhereClause(null);
      // sql= sql+ " AND (attribute1 IS NULL OR attribute1 <> 'D') ";
      XxSupTraitMatrixVO.setWhereClause(sql);
      System.out.println("Checking Query1 "+XxSupTraitMatrixVO.getQuery());
      XxSupTraitMatrixVO.executeQuery();
          if(XxSupTraitMatrixVO.getRowCount()>0) {
              Serializable[] params ={"N"};
              mainAM.invokeMethod("enableTarget",params);
          }
          
          XxSupTraitMatrixVO.first();
          for(int i=0;i<XxSupTraitMatrixVO.getRowCount();i++) {
              XxSupTraitMatrixVO.getCurrentRow().setAttribute("DisableTrans",Boolean.TRUE);
              XxSupTraitMatrixVO.next();
          }
      
      }*/
                   
      if (pageContext.getParameter("Clear") != null)
            { // retain AM
            System.out.println("in clear");
            
                pageContext.putSessionValue("sesClear","Y"); 
                      pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxfin/ap/idms/traitmatrix/webui/XXSupplierMatrixPG",
                                                  null,
                                                  OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                                  null, null, false,
                                                  OAWebBeanConstants.ADD_BREAD_CRUMB_NO);
            }
            
          
            
            if(pageContext.getParameter("Create")!=null) 
        {                             
               // hash             
             HashMap hashMap = new HashMap(1);    
             hashMap.put("supNum",pageContext.getParameter("XXSupplierNumber"));
                
             pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxfin/ap/idms/traitmatrix/webui/XXSupplierMatrixCreatePG",
                                          null,
                                          OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                          null,
                                          hashMap,
                                          true,
                                          OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
                                          OAWebBeanConstants.IGNORE_MESSAGES);
                               
         }
            
            
            String event = pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM);
            
            
            if("UPD_MATRIX".equals(event)) { 
            
                String url = "OA.jsp?page=/od/oracle/apps/xxfin/ap/idms/traitmatrix/webui/XXSupplierMatrixCreatePG";
                
                pageContext.setForwardURL(url,
                                          null,
                                          OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                          null,
                                          null,
                                          true,
                                          OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
                                          OAWebBeanConstants.IGNORE_MESSAGES);
                
            }
            
     if ("Delete".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM)))  {
          String rowReference = pageContext.getParameter(OAWebBeanConstants.EVENT_SOURCE_ROW_REFERENCE);
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
          if (pageContext.getParameter("DeleteYesButton")!= null) 
          {
                    String  row=pageContext.getParameter("pRowRef");      
                    //XxSupTraitMatrixVO.setCurrentRow(row);
                  //  row.removeFromCollection();              
                    // mainAM.getOADBTransaction().commit();;
                    
                    Serializable[] params = {row};
                    mainAM.invokeMethod("updateFlag",params);
                     OAException confirmation = new OAException("Record deleted Successfully", OAException.CONFIRMATION);
                     pageContext.putDialogMessage(confirmation); 
            } 
            
          if (pageContext.getParameter("Clear") != null)
          { // retain AM
                  pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxfin/ap/idms/traitmatrix/webui/XXSupplierMatrixPG",
                                              null,
                                              OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                              null, null, false,
                                              OAWebBeanConstants.ADD_BREAD_CRUMB_NO);
          }
          
                         
          
      
           
  }

}
