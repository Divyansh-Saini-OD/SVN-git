/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxmer.plmpjrdashboard.webui;

import com.sun.java.util.collections.HashMap;

import java.io.Serializable;

import java.sql.SQLException;
import java.sql.Types;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADataBoundValueViewObject;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.webui.beans.table.OAAdvancedTableBean;
import com.sun.java.util.collections.ArrayList;
import oracle.jbo.Row;
import oracle.jbo.RowSetIterator;
import oracle.jbo.domain.Number;
import oracle.apps.fnd.common.MessageToken;
import oracle.jdbc.OracleCallableStatement;
import com.sun.java.util.collections.HashMap;
/**
 * Controller for ...
 */
public class OD_MyAssignmentsCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");
  String whereD = null;
  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
    System.out.println("### PR EVENT="+pageContext.getParameter(EVENT_PARAM));
    System.out.println("### FROM Page getSessionValue whereD="+pageContext.getSessionValue("whereD"));
    System.out.println("### FROM Page getSessionValue fromPage="+pageContext.getSessionValue("fromPage"));
    OAApplicationModule plmAM = pageContext.getApplicationModule(webBean);
    OAMessageTextInputBean showTaskDaysBean = (OAMessageTextInputBean)webBean.findChildRecursive("ShowTaskDays");
    if("clear".equals(pageContext.getParameter("clear"))){
    }
    else if("MyCollaborationPage".equals(pageContext.getParameter("fromPage"))){
    
//    wherearams.put("fromPage","MyCollaborationPage");
     whereD = pageContext.getParameter("whereD");
     System.out.println("### FROM Page MyCollaborationPage whereD="+whereD);
     Serializable[] where = {whereD};
    plmAM.invokeMethod("invokewhereClause",where);
    }
    else if("oaAddAttachment".equals(pageContext.getSessionValue("fromPage")))
    {
      System.out.println("### FROM Attachment Page oaAddAttachment whereD="+pageContext.getSessionValue("whereD"));
      Serializable[] where = {pageContext.getSessionValue("whereD").toString()};
      pageContext.putSessionValue("fromPage","");
      pageContext.putSessionValue("whereD","");
//      plmAM.invokeMethod("invokewhereClause",where);  
      plmAM.invokeMethod("invokeReExecuteQuery",where);
    }    
    else if("oaGotoAttachments".equals(pageContext.getSessionValue("fromPage")))
    {
      System.out.println("### FROM Attachment Page oaGotoAttachments whereD="+pageContext.getSessionValue("whereD"));
      Serializable[] where = {pageContext.getSessionValue("whereD").toString()};
      pageContext.putSessionValue("fromPage","");
      pageContext.putSessionValue("whereD","");
//      plmAM.invokeMethod("invokewhereClause",where);  
      plmAM.invokeMethod("invokeReExecuteQuery",where);
    }
    else{
    showTaskDaysBean.setValue(pageContext,"14");
    String days = showTaskDaysBean.getValue(pageContext).toString();//pageContext.getParameter("ShowTaskDays");
    System.out.println("### ShowTask Days="+showTaskDaysBean.getValue(pageContext));
    String personId = Integer.toString(pageContext.getEmployeeId());
    if("on".equals(pageContext.getParameter("MyAssignments")))
    whereD = "(scheduled_finish_date <= sysdate or scheduled_finish_date between sysdate and sysdate+"+days;
    else
    whereD = "(scheduled_finish_date <= sysdate or scheduled_finish_date between sysdate and sysdate+"+days+") AND Task_Manager_Person_Id="+personId;
    System.out.println("### ELSE Part of MyAssignment whereD="+whereD);
    Serializable[] paramDays = {days, personId};

    plmAM.invokeMethod("initDefault",paramDays);
    // Code for making the grade color code filling in UI.
    OAAdvancedTableBean auditTableBean = (OAAdvancedTableBean)webBean.findIndexedChildRecursive("ODMyAssignmentsResultsRN");
    OAMessageStyledTextBean grade = (OAMessageStyledTextBean)auditTableBean.findIndexedChildRecursive("DueDate1");
    OADataBoundValueViewObject cssGrade = new OADataBoundValueViewObject(grade,"Statusflag");
    grade.setAttributeValue(oracle.cabo.ui.UIConstants.STYLE_CLASS_ATTR, cssGrade); 
    OAViewObject myAssgnVO = (OAViewObject)plmAM.findViewObject("OD_MyAssignmentsVO");
    myAssgnVO.executeQuery();
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
    System.out.println("### PFR EVENT="+pageContext.getParameter(EVENT_PARAM));
    OAApplicationModule plmProjDBAM = (OAApplicationModule)pageContext.getApplicationModule(webBean);
    com.sun.java.util.collections.HashMap  addParams = new com.sun.java.util.collections.HashMap(1);
    if(pageContext.getParameter("Clear") != null){
     addParams.put("clear","clear");
     pageContext.forwardImmediatelyToCurrentPage(addParams,false,null);      
    }
    if("addinfo".equals(pageContext.getParameter(EVENT_PARAM)))
    {
//      pageContext.setForwardURL("OA.jsp?_rc=PA_SETUP_TAB_SETUP_LAYOUT&_ri=275&paSetupOptionCode=PROJECT_SETUP&_ti=2084736452&menu=Y&oaMenuLevel=2&oapc=26",
//      pageContext.setForwardURL("OA.jsp?page=/oracle/apps/pa/setup/webui/SetupTabSetupPG&paProjectId=104210",
//      pageContext.setForwardURL("OA.jsp?_rc=PA_SETUP_TAB_SETUP_LAYOUT&_ri=275&paSetupOptionCode=PROJECT_SETUP&_ti=54432148&oapc=71&menu=Y&oaMenuLevel=2",
//      pageContext.setForwardURL("OA.jsp?akRegionCode=PA_PROJECT_HOME_LAYOUT&amp;akRegionApplicationId=275&amp;addBreadCrumb=RS&amp;paProjectId=104210&amp;retainAM=Y",
      pageContext.setForwardURL("OA.jsp?akRegionCode=PA_MY_PROJECTS_LAYOUT&akRegionApplicationId=275&addBreadCrumb=RS&paCustPanel=search&OAPB=PA_BRAND",
      null,
      OAWebBeanConstants.KEEP_MENU_CONTEXT,
      null,
      null,
      false,
      OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
      OAException.ERROR);
    }
    if(pageContext.getParameter("Search") != null)
    {
      System.out.println("#### Search Button is Clicked");
      StringBuffer where = new StringBuffer();
//      where.delete(0,where.length());
      int whereCount = 0;
      System.out.println("## whereCount="+whereCount);
      if(pageContext.getParameter("ShowTaskDays") != null && !"".equals(pageContext.getParameter("ShowTaskDays"))){
      if(whereCount != 0)
      where.append(" AND ");
//      where.append("( Scheduled_start_Date between sysdate-"+pageContext.getParameter("ShowTaskDays")+" and sysdate+"+pageContext.getParameter("ShowTaskDays"));
//      where.append(" OR Scheduled_Finish_Date between sysdate-"+pageContext.getParameter("ShowTaskDays")+" and sysdate+"+pageContext.getParameter("ShowTaskDays")+")");
//      where.append("= '"+pageContext.getParameter("ShowTaskDays")+"'");
      where.append("( Scheduled_Finish_Date <= sysdate");
      where.append(" OR Scheduled_Finish_Date between sysdate and sysdate+"+pageContext.getParameter("ShowTaskDays")+")");


      whereCount++;
      }
      if(pageContext.getParameter("ResourcePersonIDFV") != null && !"".equals(pageContext.getParameter("ResourcePersonIDFV"))){
      System.out.println("REsource pesonID=="+pageContext.getParameter("ResourcePersonIDFV"));
      if(whereCount != 0)
      where.append(" AND ");
      where.append("Task_Manager_Person_Id ="+ pageContext.getParameter("ResourcePersonIDFV"));
      whereCount++;  
      }
//      if(pageContext.getParameter("TaskIDFV") != null && !"".equals(pageContext.getParameter("TaskIDFV"))){
      if(pageContext.getParameter("TaskName") != null && !"".equals(pageContext.getParameter("TaskName"))){
      if(whereCount != 0)
      where.append(" AND ");
//      where.append("Task_Id ="+ pageContext.getParameter("TaskIDFV"));
      where.append("Task_Name ='"+ pageContext.getParameter("TaskName")+"'");
      whereCount++;
      }
      if(pageContext.getParameter("DivisionName") != null && !"".equals(pageContext.getParameter("DivisionName"))){
      if(whereCount != 0)
      where.append(" AND ");
      where.append(" Division ='"+ pageContext.getParameter("DivisionID_FV")+"'");
      whereCount++;
      }  
      if(pageContext.getParameter("DepartmentName") != null && !"".equals(pageContext.getParameter("DepartmentName"))){
      if(whereCount != 0)
      where.append(" AND ");
      where.append(" Department ='"+ pageContext.getParameter("DivisionID_FV")+"'");
      whereCount++;
      }
      if(pageContext.getParameter("ProjectId_NameFV") != null && !"".equals(pageContext.getParameter("ProjectId_NameFV"))){
      if(whereCount != 0)
      where.append(" AND ");
      where.append(" Project_Id ='"+ pageContext.getParameter("ProjectId_NameFV")+"'");
      whereCount++;
      }      
      if(pageContext.getParameter("StartDate") != null && !"".equals(pageContext.getParameter("StartDate"))){
      if(whereCount != 0)
      where.append(" AND ");
      where.append(" Scheduled_start_Date ='"+ pageContext.getParameter("StartDate")+"'");
      whereCount++;
      }
      if(pageContext.getParameter("DueDate") != null && !"".equals(pageContext.getParameter("DueDate"))){
      if(whereCount != 0)
      where.append(" AND ");
      where.append(" Scheduled_Finish_Date ='"+ pageContext.getParameter("DueDate")+"'");
      whereCount++;
      }
      if(pageContext.getParameter("ProjectId_NumberFV") != null && !"".equals(pageContext.getParameter("ProjectId_NumberFV"))){
      if(whereCount != 0)
      where.append(" AND ");
      where.append(" Project_Id ="+ pageContext.getParameter("ProjectId_NumberFV"));
      whereCount++;
      }
      if(pageContext.getParameter("ClassName") != null && !"".equals(pageContext.getParameter("ClassName"))){
      if(whereCount != 0)
      where.append(" AND ");
      where.append(" Class ='"+ pageContext.getParameter("ClassName_FV")+"'");
      whereCount++;
      }      
      if(pageContext.getParameter("Status") != null && !"".equals(pageContext.getParameter("Status"))){
      if(whereCount != 0)
      where.append(" AND ");
      where.append(" Task_Status ='"+ pageContext.getParameter("Status")+"'");
      whereCount++;
      }
      System.out.println("### Check box value="+pageContext.getParameter("MyAssignments"));
      if(!"on".equals(pageContext.getParameter("MyAssignments"))){
      if(whereCount != 0)
      where.append(" AND ");      
      String personId = Integer.toString(pageContext.getEmployeeId());
      where.append("Task_Manager_Person_Id="+personId);
      whereCount++;
      }
      String whereClause = where.toString();
      Serializable[] params = {whereClause};
      whereD = whereClause;
      System.out.println("### FROM Search Button whereD="+whereD);
//      System.out.println("#### Where Clause="+whereClause);
      plmProjDBAM.invokeMethod("invokewhereClause",params);
    }
    if("notes".equals(pageContext.getParameter(EVENT_PARAM)))
    {
      System.out.println("Notes....ProjectID"+pageContext.getParameter("projectId"));
      System.out.println("Notes....TaskId"+pageContext.getParameter("taskId"));
      HashMap param = new HashMap(3);
      param.put("projectId",pageContext.getParameter("projectId"));
      param.put("taskId",pageContext.getParameter("taskId"));
      param.put("fromPage","MyAssignments");
      param.put("whereD",whereD);
      pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxmer/plmpjrdashboard/webui/OD_MyCollaborationNotesPG"
      , null
      , OAWebBeanConstants.KEEP_MENU_CONTEXT
      , null
      , param
      , true
      , OAWebBeanConstants.ADD_BREAD_CRUMB_NO);
//      pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxmer/plmpjrdashboard/webui/OD_MyCollaborationNotesPG",
//          null,
//          OAWebBeanConstants.KEEP_MENU_CONTEXT,
//          param,
//          null,
//          true, // retain AM
//          OAWebBeanConstants.ADD_BREAD_CRUMB_NO);
    }
    if("writenotes".equals(pageContext.getParameter(EVENT_PARAM)))
    {
      System.out.println("Notes....ProjectID"+pageContext.getParameter("projectId"));
      System.out.println("Notes....TaskId"+pageContext.getParameter("taskId"));
      HashMap param = new HashMap(3);
      param.put("projectId",pageContext.getParameter("projectId"));
      param.put("taskId",pageContext.getParameter("taskId"));
      param.put("fromPage","writeNotesMyAssignments");
      param.put("whereD",whereD);      
      pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxmer/plmpjrdashboard/webui/OD_MyCollaborationNotesPG"
      , null
      , OAWebBeanConstants.KEEP_MENU_CONTEXT
      , null
      , param
      , true
      , OAWebBeanConstants.ADD_BREAD_CRUMB_NO);      
    }

    if("oaAddAttachment".equals(pageContext.getParameter(EVENT_PARAM)))
    {
      pageContext.putSessionValue("fromPage","oaAddAttachment");
      pageContext.putSessionValue("whereD",whereD);
      System.out.println("#### oaAddAttachment whereD="+whereD);
    }
    if("oaGotoAttachments".equals(pageContext.getParameter(EVENT_PARAM)) )
    {
      pageContext.putSessionValue("fromPage","oaGotoAttachments");
      pageContext.putSessionValue("whereD",whereD);  
      System.out.println("#### oaGotoAttachments whereD="+whereD);
    }
    /*
    if("oaAddAttachment".equals(pageContext.getParameter(EVENT_PARAM))   || "oaGotoAttachments".equals(pageContext.getParameter(EVENT_PARAM)))
    {
      System.out.println("### Execute OAAddAttachment form PFR whereD="+pageContext.getSessionValue("whereD"));
      Serializable[] where = {pageContext.getSessionValue("whereD").toString()};
//      pageContext.putSessionValue("fromPage","");
//      pageContext.putSessionValue("whereD","");
//      plmProjDBAM.invokeMethod("invokewhereClause",where);      
      plmProjDBAM.invokeMethod("invokeReExecuteQuery",where);
    }
    */
    
    /* */
    if(pageContext.getParameter("Complete") != null)
    { 
      taskStatusUpdate(pageContext, plmProjDBAM, "127");//"Completed");
    }
    if(pageContext.getParameter("UndoComplete") != null)
    { 
      taskStatusUpdate(pageContext, plmProjDBAM, "125");//"In Progress");
    }
    
    /* */
    if(pageContext.getParameter("AssingtoUser") != null)
    {
        ArrayList exceptionList = new ArrayList();
        OracleCallableStatement oraclecallablestatement = null;
        OADBTransaction oadbtransaction = plmProjDBAM.getOADBTransaction();
        String status = null;
        Number taskManagerPersonId;
        String msg = null;
        int fetchedRowCount = 0;
        OAViewObject myAssgnVO = (OAViewObject)plmProjDBAM.findViewObject("OD_MyAssignmentsVO");
        fetchedRowCount = myAssgnVO.getFetchedRowCount();
        RowSetIterator selIter = myAssgnVO.findRowSetIterator("SelectIterator");
        if(selIter!=null)
        {
          selIter.closeRowSetIterator();
        }
        selIter=myAssgnVO.createRowSetIterator("SelectIterator");
        if (fetchedRowCount > 0) {
        selIter.setRangeStart(0); 
        selIter.setRangeSize(fetchedRowCount);
        for (int i = 0; i < fetchedRowCount; i++){
        Row row = selIter.getRowAtRangeIndex(i);
        if (row.getAttribute("SelectCheckbox") != null && row.getAttribute("SelectCheckbox").toString().equals("Y")) {
          if(row.getAttribute("ProjectId") != null && row.getAttribute("TaskId") != null){
              try
              {
                  Number projectId = new Number(row.getAttribute("ProjectId"));
                  Number taskId = new Number(row.getAttribute("TaskId"));
                  String sdate = row.getAttribute("ScheduledStartDate").toString();
                  String edate = row.getAttribute("ScheduledFinishDate").toString();
                  String taskName = null;
//                  taskManagerPersonId = new Number(693);
                  if(pageContext.getParameter("AssingUserPersonIDFV") != null && !"".equals(pageContext.getParameter("AssingUserPersonIDFV"))){
                  taskManagerPersonId = new Number(pageContext.getParameter("AssingUserPersonIDFV"));
                  taskName = row.getAttribute("TaskName").toString();
                  }
                  else
                  throw new OAException("XXMER","OD_PLM_PROVIDE_ASSINGN_USER",null,OAException.ERROR,null);
                  System.out.println("#### projectId="+projectId);
                  System.out.println("#### taskId="+taskId);
                  System.out.println("#### taskManagerPersonId="+taskManagerPersonId);   
                  String stmt = "begin OD_PA_PKG.OD_UPDATE_TASK_MANAGER_PERSON(:1,:2,:3,:4,:5,:6); end;";
                  try{
                  oraclecallablestatement = (OracleCallableStatement)oadbtransaction.createCallableStatement(stmt, 10);
                  oraclecallablestatement.setNUMBER(1,projectId);
                  oraclecallablestatement.setNUMBER(2,taskId);
                  oraclecallablestatement.setNUMBER(3,taskManagerPersonId);
                  oraclecallablestatement.setString(4,sdate);
                  oraclecallablestatement.setString(5,edate);
                  oraclecallablestatement.registerOutParameter(6,Types.VARCHAR, 0, 500);
                  oraclecallablestatement.execute();
                  msg = oraclecallablestatement.getString(6);
                  }catch(Exception e)
                  {
                    System.out.println("Exception e="+e);
                  }
                  System.out.println("PLSQL Return MSG:"+oraclecallablestatement.getString(6));
//                  if(msg != null)
//                  throw new OAException("XXMER",msg,null,OAException.ERROR,null);
                  if("S".equals(msg)){
                  String resource = pageContext.getParameter("AssignUser2");
                  MessageToken[] tokens = { new MessageToken("TASK_NAME", taskName), new MessageToken( "RESOURCE_NAME", resource) };
                  exceptionList.add(new OAException("XXMER","OD_PLM_TASK_REASSIGN_USER",tokens,OAException.INFORMATION,null));                    
                  }
                  else
                  exceptionList.add(new OAException("XXMER",msg,null,OAException.ERROR,null));

                  
              }catch(SQLException sqlexception)
              {
               System.out.println("#### Exception="+sqlexception);
              }
              row.setAttribute("SelectCheckbox",null);// To deselect the task after re-assignmment
            }
           }
          }
          OAException.raiseBundledOAException(exceptionList);
         }
         selIter.closeRowSetIterator();
//         com.sun.java.util.collections.HashMap  params = new com.sun.java.util.collections.HashMap(1);
//         params.put("errors",exceptionList);
//         pageContext.forwardImmediatelyToCurrentPage(params,true,null);
//         pageContext.forwardImmediately("OA.jsp?OAFunc=OD_CSZ_SR_DB_FN&OASF=OD_CSZ_SR_DB_FN&OAHP=CSZ_SR_T2_AGENT_HOME_PAGE&OAPB=CSZ_SR_BRAND&addBreadCrumb=RP",
//                                        null,
//                                        OAWebBeanConstants.KEEP_MENU_CONTEXT,
//                                        null,
//                                        null,
//                                        true, // retain AM
//                                        OAWebBeanConstants.ADD_BREAD_CRUMB_NO);         
    }    
    if(pageContext.getParameter("SaveAttachment") != null)
    {
      plmProjDBAM.invokeMethod("apply");
    }
  }

  public void taskStatusUpdate(OAPageContext pageContext, OAApplicationModule plmProjDBAM, String statusType)
  {
        ArrayList exceptionList = new ArrayList();
        OracleCallableStatement oraclecallablestatement = null;
        OADBTransaction oadbtransaction = plmProjDBAM.getOADBTransaction();
        String status = null;
//        String msg = null;
//        String projectId = null;
//        String taskId = null;
//        String statusType = null;
        String msg = null;
        int fetchedRowCount = 0;
        OAViewObject myAssgnVO = (OAViewObject)plmProjDBAM.findViewObject("OD_MyAssignmentsVO");
        fetchedRowCount = myAssgnVO.getFetchedRowCount();
        RowSetIterator selIter = myAssgnVO.findRowSetIterator("SelectIterator");
        if(selIter!=null)
        {
          selIter.closeRowSetIterator();
        }
        selIter=myAssgnVO.createRowSetIterator("SelectIterator");
        if (fetchedRowCount > 0) {
        selIter.setRangeStart(0); 
        selIter.setRangeSize(fetchedRowCount);
        for (int i = 0; i < fetchedRowCount; i++){
        Row row = selIter.getRowAtRangeIndex(i);
        System.out.println("### UPDATE STATUS fetchedRowCount="+fetchedRowCount);
        System.out.println("### Select Value="+row.getAttribute("SelectCheckbox"));
        if (row.getAttribute("SelectCheckbox") != null && row.getAttribute("SelectCheckbox").toString().equals("Y")) {
        System.out.println("#### IN UPDATE STATUS.....");
          if(row.getAttribute("ProjectId") != null && row.getAttribute("TaskId") != null){
//              projectId = row.getAttribute("ProjectId").toString();
//              taskId = row.getAttribute("TaskId").toString();
//              statusType = "Completed";
              if(row.getAttribute("TaskManagerPersonId")!= null) {
              System.out.println("### TaskManagerPersonId != null");
              System.out.println("#### EmployeeID="+pageContext.getEmployeeId());
              int personId = pageContext.getEmployeeId();
              int taskMgrPersonId = Integer.parseInt(row.getAttribute("TaskManagerPersonId").toString());
              /* if( taskMgrPersonId != personId)
               {
               System.out.println("### Inside comparison");
               throw new OAException("XXMER","You are not assigned to this task",null,OAException.ERROR,null);
               }
              */ 
              }
              System.out.println("### TaskManagerPersonId="+row.getAttribute("TaskManagerPersonId"));
              String taskName = null;
              String taskStatus = row.getAttribute("TaskStatus").toString();
             
              try
              {
                  Number projecId = new Number(row.getAttribute("ProjectId"));
                  Number taskId = new Number(row.getAttribute("TaskId"));
                  taskName = row.getAttribute("TaskName").toString();
                  System.out.println("#### projectId="+projecId);
                  System.out.println("#### taskId="+taskId);
                  System.out.println("#### statusType="+statusType);                  
                  String stmt = "begin OD_PA_PKG.OD_UPDATE_STATUS(:1,:2,:3,:4); end;";
                  if("127".equals(statusType) && "Completed".equals(taskStatus))
                  {
                  System.out.println("## Completed TASK");
                    MessageToken[] tokens = { new MessageToken("TASK_NAME", taskName) };
                    exceptionList.add(new OAException("XXMER","OD_PLM_ALREADY_COMPLETED",tokens,OAException.INFORMATION,null));                    
                  }
                  else if("125".equals(statusType) && !"Completed".equals(taskStatus))
                  {
                                    System.out.println("## In-Completed TASK");
                    MessageToken[] tokens = { new MessageToken("TASK_NAME", taskName) };
                    exceptionList.add(new OAException("XXMER","OD_PLM_ALREADY_UNDOCOMPLETED",tokens,OAException.INFORMATION,null));                    
                  }
                  else{ 
                  try{
                  oraclecallablestatement = (OracleCallableStatement)oadbtransaction.createCallableStatement(stmt, 10);
                  oraclecallablestatement.setNUMBER(1,projecId);
                  oraclecallablestatement.setNUMBER(2,taskId);
                  oraclecallablestatement.setString(3,statusType);
                  oraclecallablestatement.registerOutParameter(4,Types.VARCHAR, 0, 500);
//                  errMsg = oraclecallablestatement.getString(4);
                  oraclecallablestatement.execute();
                  msg = oraclecallablestatement.getString(4);
                  
                  }catch(Exception e)
                  {
                    System.out.println("Exception e="+e);
                  }
                  System.out.println("PLSQL Return MSG:"+oraclecallablestatement.getString(4));
                  }

                  
                  System.out.println("After calling proc msg="+msg);
//                  if("127".equals(statusType))
//                  msg = "Completed";
//                  if("125".equals(statusType))
//                  msg = "Undo Completed";
//                  if(!"S".equals(msg))
//                  throw new OAException("XXMER",msg,null,OAException.ERROR,null);
//                  exceptionList.add(new OAException("XXCRM","OD_TRACKING_NUMBER_NULL",tokens,OAException.ERROR,null));
//                  exceptionList.add(new OAException("XXMER",msg,null,OAException.ERROR,null));
                    
                  if("S".equals(msg)){
                  if("127".equals(statusType)){
                  MessageToken[] tokens = { new MessageToken("TASK_NAME", taskName) };
//                  throw new OAException("XXMER","Selected Project/Task Status has been"+msg,null,OAException.INFORMATION,null);
                  exceptionList.add(new OAException("XXMER","OD_PLM_TASK_COMPLETED",tokens,OAException.INFORMATION,null));                  
                  }
                  else if("125".equals(statusType))
                  {
                  MessageToken[] tokens = { new MessageToken("TASK_NAME", taskName) };
//                  throw new OAException("XXMER","Selected Project/Task Status has been"+msg,null,OAException.INFORMATION,null);
                  exceptionList.add(new OAException("XXMER","OD_PLM_TASK_UNDO_COMPLETED",tokens,OAException.INFORMATION,null));                    
                  }
                  }
                  else if(msg!= null)
                  exceptionList.add(new OAException("XXMER",msg,null,OAException.ERROR,null));
//                  pageContext.putDialogMessage(new OAException("XXMER","Selected Project/Task Status has been"+msg,null,OAException.INFORMATION,null));
//                  System.out.println("After calling proc status="+statusType);
              }catch(SQLException sqlexception)
              {
               System.out.println("#### Exception="+sqlexception);
              }
              
            }
            row.setAttribute("SelectCheckbox",null);// To deselect the task after re-assignmment
           }
          }
          OAException.raiseBundledOAException(exceptionList);
         }
         selIter.closeRowSetIterator();
    
  }


}
