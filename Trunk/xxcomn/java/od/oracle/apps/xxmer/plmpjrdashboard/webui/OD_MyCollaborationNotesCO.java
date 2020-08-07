/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxmer.plmpjrdashboard.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.beans.form.OAFormBean;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.apps.fnd.framework.webui.beans.message.MessageRichTextEditorBean;
import oracle.jbo.domain.Number;
import com.sun.java.util.collections.HashMap;
import oracle.cabo.ui.action.FireAction;
import oracle.apps.fnd.framework.webui.OAWebBeanUtils;
import java.io.Serializable;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
/**
 * Controller for ...
 */
public class OD_MyCollaborationNotesCO extends OAControllerImpl
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
    OAApplicationModule plmProjDBAM = (OAApplicationModule)pageContext.getApplicationModule(webBean);
    MessageRichTextEditorBean noteEntryBean = (MessageRichTextEditorBean)webBean.findChildRecursive("NotesEntry");
    
//    plmProjDBAM.invokeMethod("executeNotes");
    if(pageContext.getParameter("whereD") != null){
      whereD = pageContext.getParameter("whereD");
      System.out.println("#### In Collabaotan PAge whereD="+whereD);
    }
    if("Clear".equals(pageContext.getParameter("Notes")))
    {
      noteEntryBean.setText(null);
    }
    System.out.println("From PAGE="+pageContext.getParameter("fromPage"));
    if(!"clear".equals(pageContext.getParameter("ClearScreen"))){
    if("MyAssignments".equals(pageContext.getParameter("fromPage")))
    {
      System.out.println("From My Assignments PG");
      Serializable[] param = {pageContext.getParameter("projectId").toString(),pageContext.getParameter("taskId").toString()};
//      plmProjDBAM.invokeMethod("setWhereNotes",param);
      plmProjDBAM.invokeMethod("setWherePANotes",param);
      System.out.println("### FROM MyAssignments whereD="+whereD);
    }
    if("writeNotesMyAssignments".equals(pageContext.getParameter("fromPage")))
    {
      System.out.println("From writeNotesMyAssignments");
      pageContext.putParameter("fromPage","writeNotesMyAssignments");
      System.out.println("### Project ID="+pageContext.getParameter("projectId"));
      System.out.println("### Task ID="+pageContext.getParameter("taskId"));
//      plmProjDBAM.invokeMethod("executeNotes");
//      plmProjDBAM.invokeMethod("create");
//      plmProjDBAM.invokeMethod("executeNotes");
//      plmProjDBAM.invokeMethod("create");
    }
    }
//    OAFormBean projId = (OAFormBean)webBean.findChildRecursive("FromProjectId");
//    OAFormBean taskId = (OAFormBean)webBean.findChildRecursive("FromTaskId");
//    projId.setText("1000");
//    taskId.setText(("1"));
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
    OAApplicationModule plmProjDBAM = (OAApplicationModule)pageContext.getApplicationModule(webBean);
    OATableBean notesTableBean = (OATableBean)webBean.findChildRecursive("NotesnRN");

    if(pageContext.getParameter("CreateNotes") != null)
    {
      plmProjDBAM.invokeMethod("create");
    }
    System.out.println("IN PFR EVENT="+pageContext.getParameter(EVENT_PARAM));
    System.out.println("## AddNotes="+pageContext.getParameter("AddNotes"));
    if("executeNotes".equals(pageContext.getParameter(EVENT_PARAM))){
    String notes = pageContext.getParameter("NotesEntry");
    System.out.println("#### Notes ="+notes);
    String projectId = pageContext.getParameter("projectId");
    String taskId = pageContext.getParameter("taskId");
    String userid = Integer.toString(pageContext.getUserId());
    if("".equals(pageContext.getParameter("NotesEntry")) ){
    System.out.println("Notes is null");
    throw new OAException("XXMER","OD_PLM_NOTES_NULL",null,OAException.ERROR,null);
    }
//    String 
    Serializable[] params = {notes,projectId,taskId};
    Serializable[] paramsExeUser = {userid};
    Serializable[] paramsExeprojtask = {projectId,taskId};
    System.out.println("AddNotes event ... notes="+notes);
    if("writeNotesMyAssignments".equals(pageContext.getParameter("fromPage")))
    {
      System.out.println("### When Add Notes from writeNotesMyAssignments");
      System.out.println("### Project ID="+pageContext.getParameter("projectId"));
      System.out.println("### Task ID="+pageContext.getParameter("taskId"));
      plmProjDBAM.invokeMethod("create");
      plmProjDBAM.invokeMethod("setNotes",params);
      plmProjDBAM.invokeMethod("apply");
//      plmProjDBAM.invokeMethod("executeNotesByUser",paramsExeUser);
//      plmProjDBAM.invokeMethod("executePANotesByUser",params);
      plmProjDBAM.invokeMethod("setWherePANotes",paramsExeprojtask);
    }
    else
    {
//    pageContext.putParameter("fromPage","writeNotesMyAssignments")
      plmProjDBAM.invokeMethod("create");
      plmProjDBAM.invokeMethod("setNotes",params);
      plmProjDBAM.invokeMethod("apply");
      plmProjDBAM.invokeMethod("executeNotes");
      plmProjDBAM.invokeMethod("executePANotes");
    }
    //    executeNotes
//    public static oracle.cabo.ui.action.FireAction getFirePartialActionForSubmit(OAWebBean webBean,
//      String formName,
//      String eventName,
//      Hashtable params,
//      Boolean clientUnvalidated)
//    mcb.setFireActionForSubmit ("empPositionChange", params, paramsWithBinds,false, false);
    FireAction fireAction = OAWebBeanUtils.getFireActionForSubmit(
    notesTableBean, "execute", null, null,false, false);
    HashMap param = new HashMap(1);
    param.put("Notes","Clear");
    pageContext.forwardImmediatelyToCurrentPage(param,true,null);


    }

if(pageContext.getParameter("Search") != null)
    {
      System.out.println("#### Search Button is Clicked");
      System.out.println("#### Show Task Days:"+pageContext.getParameter("ShowTaskDays"));
      System.out.println("#### Resource:"+pageContext.getParameter("ResourcePersonIDFV"));
      System.out.println("#### Task Name:"+pageContext.getParameter("TaskName"));
      System.out.println("#### Task Id:"+pageContext.getParameter("TaskIDFV"));
      System.out.println("#### Division:"+pageContext.getParameter("DivisionName"));
      System.out.println("#### DepartmentName:"+pageContext.getParameter("DepartmentName"));
      System.out.println("#### ProjectId_NameFV:"+pageContext.getParameter("ProjectId_NameFV"));
      System.out.println("#### StartDate:"+pageContext.getParameter("StartDate"));
      System.out.println("#### DueDate:"+pageContext.getParameter("DueDate"));
      System.out.println("#### ProjectId_NumberFV:"+pageContext.getParameter("ProjectId_NumberFV"));
      System.out.println("#### ClassName:"+pageContext.getParameter("ClassName"));
      System.out.println("#### Status:"+pageContext.getParameter("Status"));
      StringBuffer where = new StringBuffer();
      int whereCount = 0;
      System.out.println("## whereCount="+whereCount);

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
//      int whereLen = where.length();
      if(where.length()!=0){
      String whereClause = where.toString();
      Serializable[] params = {whereClause};
//      System.out.println("#### Where Clause="+whereClause);
      plmProjDBAM.invokeMethod("invokenoteswhereClause",params);
      }
    }

    if(pageContext.getParameter("Clear") != null){
     com.sun.java.util.collections.HashMap  addParams = new com.sun.java.util.collections.HashMap(1);
     addParams.put("ClearScreen","clear");
     pageContext.forwardImmediatelyToCurrentPage(addParams,false,null);      
    }  
    if(pageContext.getParameter("BackAssignPG")!= null){
    com.sun.java.util.collections.HashMap  wherearams = new com.sun.java.util.collections.HashMap(1);
    System.out.println("### BackAssignPG whereD="+whereD);
    wherearams.put("whereD",whereD);
    wherearams.put("fromPage","MyCollaborationPage");
    pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxmer/plmpjrdashboard/webui/OD_MyAssignmentsPG"
      , null
      , OAWebBeanConstants.KEEP_MENU_CONTEXT
      , null
      , wherearams //param
      , true
      , OAWebBeanConstants.ADD_BREAD_CRUMB_NO);
    }
  }

}
