/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.tds.webui;

import java.io.Serializable;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Date;

import java.text.SimpleDateFormat;

import java.util.Vector;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.cp.request.ConcurrentRequest;
import oracle.apps.fnd.cp.request.RequestSubmissionException;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAFlowLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageDateFieldBean;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;




/**
 * Controller for ...
 */
public class xxTDSRetriggerMainCO extends OAControllerImpl
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
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      OAMessageDateFieldBean dateBean = (OAMessageDateFieldBean)webBean.findIndexedChildRecursive("chooseDateFrom");
      
      OATableBean tblNC = 
          (OATableBean)webBean.findIndexedChildRecursive("resultsTbl1"); // No Connect Table
      OATableBean tblNT = 
          (OATableBean)webBean.findIndexedChildRecursive("resultsTbl2"); // No Task table
          
        OASubmitButtonBean reprocessButton = 
               (OASubmitButtonBean)webBean.findIndexedChildRecursive("reprocessOrderBtn"); // Reprocess Button for NC
           OASubmitButtonBean reprocessOrderBtn2 = 
               (OASubmitButtonBean)webBean.findIndexedChildRecursive("reprocessOrderBtn2"); // Reprocess Button for NT
    OATableBean tbl1 =(OATableBean) webBean.findIndexedChildRecursive("resultsTbl1");
    OAFlowLayoutBean btnRow1 = (OAFlowLayoutBean)  tbl1.getTableActions();
      
    OATableBean tbl2 =(OATableBean) webBean.findIndexedChildRecursive("resultsTbl2");
    OAFlowLayoutBean btnRow2 = (OAFlowLayoutBean)  tbl2.getTableActions();
   //Default the date From column to Sysdate -1 
    String defaultDateValue = (String)am.invokeMethod("executeDateDisplay");
      SimpleDateFormat f = new SimpleDateFormat("MM/dd/yyyy");
    try{
      Date sqlDate=new Date(f.parse(defaultDateValue).getTime());
      dateBean.setValue(pageContext, sqlDate);
      }catch(Exception e){ e.printStackTrace();}
      
      if (pageContext.getTransactionValue("ACVAL") != 
          null) { // Code for Action Type 
          if (pageContext.getTransactionValue("ACVAL").equals("NC")) { // No connect Button 
              tblNC.setRendered(true);
              tblNT.setRendered(false);
          }
          if (pageContext.getTransactionValue("ACVAL").equals("NT")) { // No connect Button 
              tblNC.setRendered(false);
              tblNT.setRendered(true);
          }
      }
      
  if (pageContext.getTransactionValue("RPVAL") != 
          null) { // Code for Reprocess Type
          if (pageContext.getTransactionValue("RPVAL").equals("RPONE")) { // Reprocess individually - Rendering logic
              
              //   pageContext.putTransactionValue("RPONE","RPONE");
              reprocessButton.setRendered(true);
              reprocessOrderBtn2.setRendered(true);
              btnRow1.setRendered(false);
              btnRow2.setRendered(false);
          }
          if (pageContext.getTransactionValue("RPVAL").equals("RPALL")) { // Reprocess All - Rendering logic
              
              //pageContext.putTransactionValue("RPONE","RPONE");
              reprocessButton.setRendered(false);
              reprocessOrderBtn2.setRendered(false);
              btnRow1.setRendered(true);
              btnRow2.setRendered(true);
          }
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
         OAApplicationModule am = pageContext.getApplicationModule(webBean);
         OADBTransaction oadbtransaction = am.getOADBTransaction();
         Connection conn = oadbtransaction.getJdbcConnection();
         ResultSet rsProg = null;
         Statement stmt = null;
         String progShortName = "";
         String programName = "";
         String applName = "";
         String strTableName = "";

   
    OAMessageDateFieldBean dateBean = (OAMessageDateFieldBean)webBean.findIndexedChildRecursive("chooseDateFrom");
         String actionTypeValue ="";
         String chooseReprocessValue="";
     OAMessageChoiceBean  chooseActionTypeBean   =(OAMessageChoiceBean) webBean.findIndexedChildRecursive("chooseActionType");
     OAMessageChoiceBean  chooseReprocessTypeBean   =(OAMessageChoiceBean) webBean.findIndexedChildRecursive("chooseReprocessType");

    System.out.println("dateBean="+dateBean);
         System.out.println("chooseActionTypeBean="+chooseActionTypeBean);
    
    actionTypeValue = (String)chooseActionTypeBean.getValue(pageContext);
    chooseReprocessValue = (String)chooseReprocessTypeBean.getValue(pageContext);
         System.out.println("actionTypeValue="+actionTypeValue);
         System.out.println("chooseReprocessValue="+chooseReprocessValue);
    String dateValue = (String)dateBean.getText(pageContext);
    System.out.println("dateBean="+dateValue);
    
    
     if(pageContext.getParameter("search")!=null){
     // Set Transaction Values to use in PR for display of tables
         if (chooseReprocessValue.equals("RPALL")) {
             pageContext.putTransactionValue("RPVAL", "RPALL");
         }
         if (chooseReprocessValue.equals("RPONE")) {
             pageContext.putTransactionValue("RPVAL", "RPONE");
         }
         if (actionTypeValue.equals("NC")) {
             pageContext.putTransactionValue("ACVAL", "NC");
         }
         if (actionTypeValue.equals("NT")) {
             pageContext.putTransactionValue("ACVAL", "NT");
         }
         
     Serializable[] params= { actionTypeValue, dateValue };
      am.invokeMethod("getSearchResults",params);
      pageContext.forwardImmediatelyToCurrentPage(null,true,null);  
     
     
     }//End of Search button loop
     
     
      //Start Action of Reprocess All
      if (( pageContext.getParameter("reprocessAllBtn") != null)  || ( pageContext.getParameter("reprocessAllBtn1")!=null ) )  {
          try {
              applName = "xxcrm";
              progShortName = "XXTDSRETRIGGERPROG";
              programName = "OD TDS Retrigger Work Orders From EBS";
              ConcurrentRequest cr = new ConcurrentRequest(conn);
              // call submit request
              Vector param = new Vector();
              param.addElement(actionTypeValue);
              param.addElement(dateValue);
              int reqId = 
                  cr.submitRequest(applName, progShortName, null, null, 
                                   false, param);
              conn.commit();
              System.out.println("reqId=" + reqId);

              MessageToken[] tokens = 
              { new MessageToken("PROGRAMNAME", programName), 
                new MessageToken("REQID", 
                                 reqId + "") }; //, new MessageToken("FILENAME",(String)pageContext.getTransactionValue("strExcelUploadFileName"))};
              throw new OAException("XXFIN", "XXOD_EXCEL_UPLD_PRG_DET", 
                                    tokens, OAException.INFORMATION, null);
          } catch (RequestSubmissionException exp) {
              System.out.println("Request Submission Exception:" + exp);
          } catch (SQLException sexp) {
              System.out.println("SQL Exception:" + sexp);
          }
      } //end reprocess ALL logic
      
       if (pageContext.getParameter(EVENT_PARAM).equals("reprocessOrderNT")) {
           String incNum = (String)pageContext.getParameter("incNum");
           Serializable[] srParams = { dateValue, incNum };
           String status = 
               (String)am.invokeMethod("reprocessOneNT", srParams);
           System.out.println("status=" + status);
           //pageContext.forwardImmediatelyToCurrentPage(null, true, null);
       } //end reprocess ONE NC logic
       if (pageContext.getParameter(EVENT_PARAM).equals("reprocessOrderNC")) {
           String incNum = (String)pageContext.getParameter("incNum");
           String taskId = (String)pageContext.getParameter("taskId");
           String taskDesc = (String)pageContext.getParameter("taskDesc");
           String taskObjNum = (String)pageContext.getParameter("taskObjNum");
           Serializable[] taskParams = 
           { dateValue, incNum, taskId, taskDesc, taskObjNum };
           String status = 
               (String)am.invokeMethod("reprocessOneNC", taskParams);
           System.out.println("status=" + status);
           //pageContext.forwardImmediatelyToCurrentPage(null, true, null);
       } //end reprocess ONE NT logic
       


     } // end of PFR
     
     
} // end main class file CO.java
