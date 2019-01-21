/*===========================================================================+
 |      Copyright (c) 2001 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                    												 |
 |  10/12/07 Satyasrinivas Created for Office Depot changes.                 |
 +===========================================================================*/
//package oracle.apps.jtf.cac.task.webui;
package od.oracle.apps.xxcrm.asn.common.webui;

import java.io.Serializable;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.*;
import oracle.apps.fnd.framework.webui.*;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.jtf.cac.task.webui.*;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.jbo.ViewObject;
import oracle.jbo.Row;


/*
 * Controller for Appointment/Task References
 * Scope: public
 * Description: Task Reference Region provides tabular display of
 * References for a given Appointment/Task.
 * @rep:displayname Task Reference controller
 * @rep:product CAC
 * @rep:category CAC_CAL_TASK
 * @param cacTaskSrcObjCode source object code for a task
 * @param cacTaskSrcObjId source object id for a task
 * @param cacTaskObjectCode additional source code to be created as reference
 * @param cacTaskObjectId additional source id to be created as reference
 * @param cacTaskCustId the id number for customer
 */
public class ODTaskReferenceCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header: ODTaskReferenceCO.java 115.6 2005/01/19 21:45:48 twan noship $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "xxcrm.oracle.apps.asn.common.webui");

  /**
   * Layout and page setup logic for AK region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);

    // Get mandatory parameters
    String cacReferenceTaskId = (String)pageContext.getTransactionValue("cacReferenceTaskId");
    String cacTaskSrcObjCode = (String)pageContext.getTransactionValue("cacTaskSrcObjCode");
    String cacTaskSrcObjId = (String)pageContext.getTransactionValue("cacTaskSrcObjId");
    String cacTaskObjectCode = (String)pageContext.getParameter("cacTaskObjectCode");
    String cacTaskObjectId = (String)pageContext.getParameter("cacTaskObjectId");
    String cacTaskCustId = (String)pageContext.getParameter("cacTaskCustId");
    if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
      pageContext.writeDiagnostics(this,
        "TaskReferencePG required parameters:"+
        "cacReferenceTaskId="+cacReferenceTaskId+
        "cacTaskSrcObjCode="+cacTaskSrcObjCode+
        ",cacTaskSrcObjId="+cacTaskSrcObjId+
        ",cacTaskObjectCode="+cacTaskObjectCode+
        ",cacTaskObjectId="+cacTaskObjectId+
        ",cacTaskCustId="+cacTaskCustId,
        OAFwkConstants.STATEMENT);

    // Check mandatory parameters
    if (cacTaskSrcObjCode == null || "".equals(cacTaskSrcObjCode))
    {
      MessageToken[] tokens = {new MessageToken("PARAMETER_NAME", "cacTaskSrcObjCode")};
      throw new OAException("JTF", "JTF_TASK_PARAM_NOT_FOUND", tokens);
    }

    if (cacReferenceTaskId == null || "".equals(cacReferenceTaskId))
    {
      MessageToken[] tokens = {new MessageToken("PARAMETER_NAME", "cacReferenceTaskId")};
      throw new OAException("JTF", "JTF_TASK_PARAM_NOT_FOUND", tokens);
    }

    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if (!"".equals(cacTaskSrcObjId))
    {
      if (cacTaskSrcObjId == null && cacTaskObjectId == null)
      {
        //load reference table for update page
        am.invokeMethod("initReference");
      }
      else
      {
        //load reference table for create page
        if (cacTaskSrcObjId != null
            && !"APPOINTMENT".equals(cacTaskSrcObjCode)
            && !"TASK".equals(cacTaskSrcObjCode))
        {
          Serializable[] parameters = {cacTaskSrcObjCode, cacTaskSrcObjId};
          am.invokeMethod("createReference", parameters);
        }
        if (cacTaskObjectId != null)
        {
          Serializable[] parameters = {cacTaskObjectCode, cacTaskObjectId};
          am.invokeMethod("createReference", parameters);
        }
      }
    }

    //create reference for customer
    if (cacTaskCustId != null && !"".equals(cacTaskCustId))
    {
      //load reference table for create page
      if (!cacTaskCustId.equals(cacTaskSrcObjId) && !"PARTY".equals(cacTaskSrcObjCode))
      {
        Serializable[] parameters = {null, cacTaskCustId};
        am.invokeMethod("createReference", parameters);
      }
    }
    /**** OD changes -- Create reference for Party Site ****/
   if ( "LEAD".equals(cacTaskSrcObjCode) || "OPPORTUNITY".equals(cacTaskSrcObjCode))
	            {
	             String task_id = (String)pageContext.getTransactionValue("cacReferenceTaskId") ;
pageContext.writeDiagnostics(this,"OD satya -- TaskReferencePG address id parameter:"+pageContext.getParameter("cacTaskCustAddressId"),OAFwkConstants.STATEMENT);
                   String contactTask = (String)pageContext.getParameter("cacTaskContactId");
                  if (!"".equals(contactTask) && contactTask != null)
                     {pageContext.writeDiagnostics(this,"OD satya -- TaskReferencePG contactTask parameter:"+pageContext.getParameter("cacTaskContact"),OAFwkConstants.STATEMENT);
                     String AddresSID = (String)pageContext.getParameter("cacTaskCustAddressId");
                     Serializable aserializableCt[] = {"OD_PARTY_SITE",AddresSID};
                      am.invokeMethod("createReference", aserializableCt);
                     }
                   else 
                    {
	             String sql1 = "select address_id  from jtf_tasks_b where task_id = :1 and not exists(select 'X' from JTF_TASK_REFERENCES_B B, jtf_tasks_b A where A.TASK_ID = :1 and A.task_id = B.task_id and B.object_type_code = 'OD_PARTY_SITE' and B.object_id = A.address_id)";
	             oracle.jbo.ViewObject pSitevo = am.findViewObject("pSiteVO");
	            if (pSitevo == null )
	            {
	              pSitevo = am.createViewObjectFromQueryStmt("pSiteVO", sql1);
	            }

	            if (pSitevo != null  && cacTaskSrcObjCode !=null)
	            {   pSitevo.setWhereClauseParams(null);
	                pSitevo.setWhereClauseParam(0,task_id);
	                pSitevo.executeQuery();
                        pSitevo.first();
	                oracle.jbo.Row row = pSitevo.first();
                    if (row !=null) {  
                       String taskaddressID = pSitevo.getCurrentRow().getAttribute(0).toString();
	    if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT)){
		 pageContext.writeDiagnostics(this,"OD -- TaskReferencePG address id parameter:"+",cacTaskCustAddressId="+taskaddressID,OAFwkConstants.STATEMENT);}
	                pSitevo.remove();
	               Serializable aserializable55[] = {"OD_PARTY_SITE",taskaddressID};
	              am.invokeMethod("createReference", aserializable55);
                    }
                        else
                     {pSitevo.remove();}
	        }
}}
  }

  /**
   * Procedure to handle form submissions for form elements in
   * AK region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormRequest(pageContext, webBean);
    if (pageContext.getParameter("AddButton") != null &&
        pageContext.getParameter("CacObjId") != null &&
        !"".equals(pageContext.getParameter("CacObjId")))
    {
      Serializable[] parameters = {pageContext.getParameter("CacObjTypeCode"),
                                   pageContext.getParameter("CacObjId")};
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      am.invokeMethod("createReference", parameters);
    }

    if ("Delete".equals(pageContext.getParameter("CacTaskRefEvent")))
    {
      removeRef(pageContext, webBean, pageContext.getParameter("CacTaskRefId"));
    }
  }

  /** Invokes AM remove method then forwards back to the current page. */
  private void removeRef(OAPageContext pageContext, OAWebBean webBean, String refId)
  {
    OAApplicationModule am = pageContext.getApplicationModule(webBean);

    Serializable[] parameters = { refId };
    am.invokeMethod("removeReference", parameters);
    pageContext.putParameter("cacTaskCustId", "");
    pageContext.putTransactionValue("cacTaskSrcObjId", "");
    //Also reset params for Contact Region, bug 3887567
    pageContext.putParameter("cacTaskContactId", "");
    pageContext.putParameter("cacContactId", "");
    pageContext.setForwardURLToCurrentPage(null, true, ADD_BREAD_CRUMB_SAVE,
                                           IGNORE_MESSAGES);
  }

}
