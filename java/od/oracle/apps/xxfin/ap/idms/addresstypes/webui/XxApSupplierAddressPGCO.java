/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxfin.ap.idms.addresstypes.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OAExportBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;

import oracle.jbo.Row;


/**
 * Controller for ...
 */
public class XxApSupplierAddressPGCO extends OAControllerImpl
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
      OAViewObject XxApSupAddressVO = 
             (OAViewObject)mainAM.findViewObject("XXSupAddressVO1");
     // XxApSupAddressVO.setWhereClause("1=2");
     // XxApSupAddressVO.executeQuery();
     
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
      OAViewObject XxApSupAddressVO = 
             (OAViewObject)mainAM.findViewObject("XXSupAddressVO1");
             
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
      
  
      if(pageContext.getParameter("Save")!=null) 
      {
          
          XxApSupAddressVO.clearCache();
                 //  CreateT.setDisabled(false);
                    ExportT.setDisabled(false);
                   // UpdateT.setDisabled(false);
                   // DeleteT.setDisabled(false);                   
               System.out.println("Save");
               try
               {
               mainAM.getOADBTransaction().commit();
               }
          catch (Exception e) {
                   throw new OAException("Please enter Unique value for Addr Type"+e, OAException.ERROR);
              }
          XxApSupAddressVO.setWhereClauseParams(null);
          String where="1=1 ";          
          XxApSupAddressVO.setWhereClause(where);
                   XxApSupAddressVO.executeQuery();
                   XxApSupAddressVO.first();
                   for(int i=0;i<XxApSupAddressVO.getRowCount();i++) {
                       XxApSupAddressVO.getCurrentRow().setAttribute("DisableTrans",Boolean.TRUE);
                       XxApSupAddressVO.next();             
                   }
          XxApSupAddressVO.first();
                   SaveT.setDisabled(true);          
          CancelT.setDisabled(true);
          throw new OAException("Record(s) Saved Successfully",OAException.CONFIRMATION);
      }
      
      if(pageContext.getParameter("Cancel")!=null) {
      
         // CreateT.setDisabled(false);
           ExportT.setDisabled(false);
          // UpdateT.setDisabled(false);
          // DeleteT.setDisabled(false);
          
      System.out.println("Roll Back");
      mainAM.getOADBTransaction().rollback();
          XxApSupAddressVO.first();
          for(int i=0;i<XxApSupAddressVO.getRowCount();i++) {
              XxApSupAddressVO.getCurrentRow().setAttribute("DisableTrans",Boolean.TRUE);
              XxApSupAddressVO.next();
              SaveT.setDisabled(true);
              CancelT.setDisabled(true);
          }
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
          //createFirst = "N";
      
         if("".equals(pageContext.getParameter("AddressType")))
         {
          try{
//          String where="address_type= nvl(:1,address_type)";
//          XxApSupAddressVO.setWhereClause(where);
//              XxApSupAddressVO.setWhereClauseParam(0,null);
//           XxApSupAddressVO.setMaxFetchSize(-1);
          String where="1=1 ";
          XxApSupAddressVO.setWhereClause(where);
          XxApSupAddressVO.executeQuery();
          
          System.out.println("Query  Here...."+XxApSupAddressVO.getQuery() +"Count ::"+XxApSupAddressVO.getRowCount());
             
              XxApSupAddressVO.first();
              for(int i=0;i<XxApSupAddressVO.getRowCount();i++) {
                  XxApSupAddressVO.getCurrentRow().setAttribute("DisableTrans",Boolean.TRUE);
                  XxApSupAddressVO.next();
              }
                                                 
          }
          catch (Exception e){
          pageContext.writeDiagnostics(this,"e :"+e,1);   
          pageContext.writeDiagnostics(this,"XxApSupTraitsVO query :"+XxApSupAddressVO.getQuery(),1);
          System.out.println("XxApSupAddressVO query :"+XxApSupAddressVO.getQuery());
          throw new OAException("Error Message "+e.getMessage());
          }
         }
         else 
         {
              String addresstype=(String)pageContext.getParameter("AddressType");
          java.lang.Number AddresstypeNum= pageContext.getOANLSServices().stringToNumber(addresstype ); 
              String where="address_type=:1"; 
             
              XxApSupAddressVO.setWhereClause(where);
          XxApSupAddressVO.setWhereClauseParam(0,AddresstypeNum);
              XxApSupAddressVO.executeQuery();
          
          XxApSupAddressVO.first();
          for(int i=0;i<XxApSupAddressVO.getRowCount();i++) {
              XxApSupAddressVO.getCurrentRow().setAttribute("DisableTrans",Boolean.TRUE);
              XxApSupAddressVO.next();
          }
      }
      }
        
      if(pageContext.getParameter("Create")!=null) 
      {
      
         // CreateT.setDisabled(false);
           ExportT.setDisabled(false);
          // UpdateT.setDisabled(false);
          // DeleteT.setDisabled(false);
          SaveT.setDisabled(false);
          CancelT.setDisabled(false);
          
          
              if("".equals(pageContext.getParameter("AddressType")))
          {
              System.out.println("inside addresstype null");
              String where="1=1 ";
              XxApSupAddressVO.setWhereClause(where);
              XxApSupAddressVO.executeQuery();
              XxApSupAddressVO.first(); 
          }
          else {
              String addresstype=(String)pageContext.getParameter("AddressType");
                        System.out.println("inside addresstype not null");
                        java.lang.Number AddresstypeNum= pageContext.getOANLSServices().stringToNumber(addresstype );
                        String where="address_type=:1"; 
                        
                        XxApSupAddressVO.setWhereClause(where);
                        XxApSupAddressVO.setWhereClauseParam(0,AddresstypeNum);
                        XxApSupAddressVO.executeQuery();
                        XxApSupAddressVO.first();
                        XxApSupAddressVO.previous();
          }
          /*if (createFirst == "Y")
          {
          
          XxApSupAddressVO.first();
          XxApSupAddressVO.previous();
          }
          else {
              String where="1=2 ";
              XxApSupAddressVO.setWhereClause(where);
              XxApSupAddressVO.executeQuery();
              XxApSupAddressVO.first();
          }*/
          /*XxApSupTraitsVO.last();
          XxApSupTraitsVO.next(); */
          Row row=XxApSupAddressVO.createRow();
          XxApSupAddressVO.insertRow(row);
          Object HeaderID=mainAM.getOADBTransaction().getSequenceValue("XX_AP_SUP_ADDRESS_SEQ");
          row.setAttribute("AddrTypeId",HeaderID);
          row.setAttribute("EnableFlag","Y");
          //row.setNewRowState(Row.STATUS_INITIALIZED);
          //row.setAttribute("Attribute1",'A');
      } 
        
        
              
      
      if ("update".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) 
       {
       
         //  CreateT.setDisabled(false);
            ExportT.setDisabled(false);
           // UpdateT.setDisabled(false);
           // DeleteT.setDisabled(false);
           SaveT.setDisabled(false);
           CancelT.setDisabled(false);
       
     //  String UpdateAddress=pageContext.getParameter("UpdateAddress");    
       String rowRef = pageContext.getParameter(OAWebBeanConstants.EVENT_SOURCE_ROW_REFERENCE);     
        Row  row=   mainAM.findRowByRef(rowRef);
        XxApSupAddressVO.setCurrentRow(row);    
          /* XxApSupTraitsVO.first();
           for(int i=0;i<XxApSupTraitsVO.getRowCount();i++) {  */
               XxApSupAddressVO.getCurrentRow().setAttribute("DisableTrans",Boolean.FALSE);
              // XxApSupAddressVO.getCurrentRow().setAttribute("Attribute1",'U');
             /*  XxApSupTraitsVO.next();
           } */
           
             // throw new OAException("Record Updated Successfully",OAException.CONFIRMATION);
       }
       
      if (pageContext.getParameter("Clear") != null) 
      { // retain AM
               pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxfin/ap/idms/addresstypes/webui/XXSupplierAddressPG",
                                           null,
                                           OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                           null, null, false,
                                           OAWebBeanConstants.ADD_BREAD_CRUMB_NO);
      }
      
  }

}
