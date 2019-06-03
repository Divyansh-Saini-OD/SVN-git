  <!-- BPM Worklist Application; Human Workflow Application -->
  <!-- JSP for displaying Details page -->

<%@ page import="java.util.*"%>
<%@ page import="java.text.*" %>
<%@ page import="java.io.IOException"%>
<%@ page import="javax.servlet.http.HttpServletRequest,
                 oracle.bpel.services.workflow.task.model.Task"%>
<%@ page import="oracle.bpel.services.workflow.worklist.servlet.Constants"%>
<%@ page import="oracle.bpel.services.workflow.worklist.api.payload.FormUtil,
                 oracle.bpel.services.workflow.worklist.api.payload.Field"%>
<%@ page import="oracle.bpel.services.workflow.worklist.api.payload.PayloadFormGenerator,
                  oracle.bpel.services.workflow.worklist.api.payload.Form,
                  oracle.bpel.services.workflow.worklist.api.payload.PayloadConstant,
                  oracle.bpel.services.workflow.client.IWorkflowServiceClient,
                  oracle.bpel.services.workflow.client.WorkflowServiceClientFactory,
                  oracle.bpel.services.workflow.query.ITaskQueryService,
                  oracle.bpel.services.workflow.verification.IWorkflowContext,
                  oracle.bpel.services.workflow.worklist.display.*"%>
<%@ page import="org.w3c.dom.*" %>


<%@ page contentType="text/html;charset=UTF-8"%>
<%@ page pageEncoding="UTF-8" %>

<%
  try {
%>
  
  <% 
    /**
    * this block gets the payload object from the task object
    * Note: contextKey, taskId annd task have been null checked 
    *       before calling this jsp, no null checking needs to be done here
    * USER SHOULD NOT MODIFY THIS BLOCK
    */
    String taskId = request.getParameter(Constants.WORKLIST_TASKID_PARAMETER_NAME);
    String strTaskVersion = request.getParameter(Constants.WORKLIST_TASK_VERSION_PARAMETER_NAME);
    String contextId = request.getParameter(Constants.WORKLIST_CONTEXT_PARAMETER_NAME);
    
    int taskVersion = 0;
    // incase strTaskVersion is null means user wants latest version
    // from WFTask table
    // else it wants from the WFTaskHistory table
    if(strTaskVersion != null && !strTaskVersion.trim().equals(""))
    {
      try
      {
        taskVersion = Integer.parseInt(strTaskVersion);
      }
      catch(NumberFormatException exc)
      {
        //TO DO throw the exception
        taskVersion = 1;
      }
    }
   
    IWorkflowServiceClient  wfSvcClient =
                        WorkflowServiceClientFactory.getWorkflowServiceClient(
                                 WorkflowServiceClientFactory.JAVA_CLIENT);
    ITaskQueryService queryService =  wfSvcClient.getTaskQueryService();
    IWorkflowContext context = queryService.getWorkflowContext(contextId);
 
    Task task = null;
    
    if(taskVersion == 0)
    {
       task =  queryService.getTaskDetailsById(context, taskId);
    } 
    else
    {
      task = queryService.getTaskVersionDetails(context,taskId,taskVersion);
    }
    
    //get the locale from the context
    Locale locale = context.getLocale();
    String contextPath = request.getContextPath();
    
    String xmlURL = getXMLMappingFileURL(request);
    Form form = PayloadFormGenerator.getMappingForm(task,xmlURL);
    Element payload = (Element) task.getPayloadAsElement();

    //TO DO add login page
    
    String nextPage 
         = request.getParameter(Constants.WORKLIST_NEXT_PAGE_PARAMETER_NAME);
    String loginPage 
       = request.getParameter(Constants.WORKLIST_LOGIN_PAGE_PARAMETER_NAME);
    String errorPage 
       = request.getParameter(Constants.WORKLIST_ERROR_PAGE_PARAMETER_NAME);
  
    Map requiredParams 
       = PayloadFormGenerator.getRequiredFormParameters(form.getNamespaceMap(), 
                                                        task, 
                                                        context, 
                                                        nextPage, 
                                                        loginPage, 
                                                        errorPage);
    Set requiredParamNames = requiredParams.keySet();
  
    boolean canUpdate = PayloadFormGenerator.canUpdate(task,taskVersion);
    boolean showXmlView = form.showXmlView();
    boolean xmlEditable = form.isXmlEditable();
    String xmlDisabledStr = xmlEditable ? "" : "DISABLED";
  %>
  
  <!-- USER CAN MODIFY THE FOLLOWING CODE -->

  <div id="htmlView" style="padding:10px;padding-top:0px;padding-bottom:0px;display:block">
    <br/><br/>
    <form id="PayloadJSPHTML" name="PayloadJSPHTML"
        action="<%=Constants.UPDATE_SERVLET_NAME%>" 
        method="post" onSubmit="return validateData(this)">        
        <!-- print required params -->
        <input type="hidden" name="tableOperationAdd" value="" />
        <input type="hidden" name="tableOperationRemove" value="" />
        <input type="hidden" name="<%=Constants.WFTASKPAYLOAD_UPDATE_BUTTON_KEY_NAME%>" value="" />
        <%
          Iterator iter = requiredParamNames.iterator();
          while (iter.hasNext()) {
            String paramName = (String) iter.next();
            String paramValue = (String) requiredParams.get(paramName);
        %>
            <input type="hidden" name="<%=paramName%>" value="<%=paramValue%>"/>
        <%
          }     
        %>
        <!-- print form -->
        <table border="0" cellpadding="0" cellspacing="3">
        <%
          Field thisField = null;
          String thisValue = "";
          String thisDisabled = "";
          
          
					%>
						</table>
				<hr align="left" width="80%"/>
				<table cellpadding="0" cellspacing="3">
				<tr><td colspan="3" class="payloadSectionTitle" id="ns1_cl_ProcessInfo">Process Info</td></tr>

					<%
					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessName");
					if (thisField == null || thisField.isEditable()) {
						thisDisabled = "";
					}
					else {
						thisDisabled = "disabled";
					}
					%>
						<tr><th align="left">Business Process Name<font class="payloadAsterick">&nbsp;*</font></th>
						<td align="left"><input name="<%=PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessName")%>" type="text" value="<%=PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessName", form.getNamespaceMap(),"string", locale)%>" <%=thisDisabled%> dataType="string"></input></td>
						<input name="<%=PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessName")%>" type="hidden" value="<%=FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessName",form,locale,task,context)%>"></input>
						<td align="left" class="payloadDataType"><%=FormUtil.getDatatypeLocale("string",locale)%></td><input name="<%=PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessName")%>" type="hidden" value="string"></input> 
						</tr>
					<%
					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessId");
					if (thisField == null || thisField.isEditable()) {
						thisDisabled = "";
					}
					else {
						thisDisabled = "disabled";
					}
					%>
						<tr><th align="left">Business Process Id<font class="payloadAsterick">&nbsp;*</font></th>
						<td align="left"><input name="<%=PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessId")%>" type="text" value="<%=PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessId", form.getNamespaceMap(),"string", locale)%>" <%=thisDisabled%> dataType="string"></input></td>
						<input name="<%=PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessId")%>" type="hidden" value="<%=FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessId",form,locale,task,context)%>"></input>
						<td align="left" class="payloadDataType"><%=FormUtil.getDatatypeLocale("string",locale)%></td><input name="<%=PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessId")%>" type="hidden" value="string"></input>
						</tr>
					<%
					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessStep");
					if (thisField == null || thisField.isEditable()) {
						thisDisabled = "";
					}
					else {
						thisDisabled = "disabled";
					}
					%>
						<tr><th align="left">Business Process Step</th>
						<td align="left"><input name="<%=PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessStep")%>" type="text" value="<%=PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessStep", form.getNamespaceMap(),"string", locale)%>" <%=thisDisabled%> dataType="string"></input></td>
						<input name="<%=PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessStep")%>" type="hidden" value="<%=FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessStep",form,locale,task,context)%>"></input>
						<td align="left" class="payloadDataType"><%=FormUtil.getDatatypeLocale("string",locale)%></td><input name="<%=PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessStep")%>" type="hidden" value="string"></input>
						</tr>
					<%
					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessDomain");
					if (thisField == null || thisField.isEditable()) {
						thisDisabled = "";
					}
					else {
						thisDisabled = "disabled";
					}
					%>
						<tr><th align="left">Business Process Domain</th>
						<td align="left"><input name="<%=PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessDomain")%>" type="text" value="<%=PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessDomain", form.getNamespaceMap(),"string", locale)%>" <%=thisDisabled%> dataType="string"></input></td>
						<input name="<%=PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessDomain")%>" type="hidden" value="<%=FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessDomain",form,locale,task,context)%>"></input>
						<td align="left" class="payloadDataType"><%=FormUtil.getDatatypeLocale("string",locale)%></td><input name="<%=PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessDomain")%>" type="hidden" value="string"></input>
						</tr>
					<%
					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:SystemName");
					if (thisField == null || thisField.isEditable()) {
						thisDisabled = "";
					}
					else {
						thisDisabled = "disabled";
					}
					%>
						<tr><th align="left">System Name</th>
						<td align="left"><input name="<%=PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:SystemName")%>" type="text" value="<%=PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:SystemName", form.getNamespaceMap(),"string", locale)%>" <%=thisDisabled%> dataType="string"></input></td>
						<input name="<%=PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:SystemName")%>" type="hidden" value="<%=FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:SystemName",form,locale,task,context)%>"></input>
						<td align="left" class="payloadDataType"><%=FormUtil.getDatatypeLocale("string",locale)%></td><input name="<%=PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:SystemName")%>" type="hidden" value="string"></input>
						</tr>
					<%
					%>
						</table>
				<hr align="left" width="80%"/>
				<table cellpadding="0" cellspacing="3">
				<tr><td colspan="3" class="payloadSectionTitle" id="ns1_cl_TradingPartnerDetails">Trading Partner Details</td></tr>

					<%
					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPFrom");
					if (thisField == null || thisField.isEditable()) {
						thisDisabled = "";
					}
					else {
						thisDisabled = "disabled";
					}
					%>
						<tr><th align="left">TP From<font class="payloadAsterick">&nbsp;*</font></th>
						<td align="left"><input name="<%=PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPFrom")%>" type="text" value="<%=PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPFrom", form.getNamespaceMap(),"string", locale)%>" <%=thisDisabled%> dataType="string"></input></td>
						<input name="<%=PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPFrom")%>" type="hidden" value="<%=FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPFrom",form,locale,task,context)%>"></input>
						<td align="left" class="payloadDataType"><%=FormUtil.getDatatypeLocale("string",locale)%></td><input name="<%=PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPFrom")%>" type="hidden" value="string"></input>
						</tr>
					<%
					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPTo");
					if (thisField == null || thisField.isEditable()) {
						thisDisabled = "";
					}
					else {
						thisDisabled = "disabled";
					}
					%>
						<tr><th align="left">TP To<font class="payloadAsterick">&nbsp;*</font></th>
						<td align="left"><input name="<%=PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPTo")%>" type="text" value="<%=PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPTo", form.getNamespaceMap(),"string", locale)%>" <%=thisDisabled%> dataType="string"></input></td>
						<input name="<%=PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPTo")%>" type="hidden" value="<%=FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPTo",form,locale,task,context)%>"></input>
						<td align="left" class="payloadDataType"><%=FormUtil.getDatatypeLocale("string",locale)%></td><input name="<%=PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPTo")%>" type="hidden" value="string"></input>
						</tr>
					<%
					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPDocTypeName");
					if (thisField == null || thisField.isEditable()) {
						thisDisabled = "";
					}
					else {
						thisDisabled = "disabled";
					}
					%>
						<tr><th align="left">TP Doc Type Name<font class="payloadAsterick">&nbsp;*</font></th>
						<td align="left"><input name="<%=PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPDocTypeName")%>" type="text" value="<%=PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPDocTypeName", form.getNamespaceMap(),"string", locale)%>" <%=thisDisabled%> dataType="string"></input></td>
						<input name="<%=PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPDocTypeName")%>" type="hidden" value="<%=FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPDocTypeName",form,locale,task,context)%>"></input>
						<td align="left" class="payloadDataType"><%=FormUtil.getDatatypeLocale("string",locale)%></td><input name="<%=PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPDocTypeName")%>" type="hidden" value="string"></input>
						</tr>
					<%
					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPDocTypeRevision");
					if (thisField == null || thisField.isEditable()) {
						thisDisabled = "";
					}
					else {
						thisDisabled = "disabled";
					}
					%>
						<tr><th align="left">TP Doc Type Revision<font class="payloadAsterick">&nbsp;*</font></th>
						<td align="left"><input name="<%=PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPDocTypeRevision")%>" type="text" value="<%=PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPDocTypeRevision", form.getNamespaceMap(),"string", locale)%>" <%=thisDisabled%> dataType="string"></input></td>
						<input name="<%=PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPDocTypeRevision")%>" type="hidden" value="<%=FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPDocTypeRevision",form,locale,task,context)%>"></input>
						<td align="left" class="payloadDataType"><%=FormUtil.getDatatypeLocale("string",locale)%></td><input name="<%=PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPDocTypeRevision")%>" type="hidden" value="string"></input>
						</tr>
					<%
					%>
						</table>
				<hr align="left" width="80%"/>
				<table cellpadding="0" cellspacing="3">
				<tr><td colspan="3" class="payloadSectionTitle" id="ns1_cl_ErrorDetails">Error Details</td></tr>

					<%
					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorCode");
					if (thisField == null || thisField.isEditable()) {
						thisDisabled = "";
					}
					else {
						thisDisabled = "disabled";
					}
					%>
						<tr><th align="left">Error Code<font class="payloadAsterick">&nbsp;*</font></th>
						<td align="left"><input name="<%=PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorCode")%>" type="text" value="<%=PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorCode", form.getNamespaceMap(),"string", locale)%>" <%=thisDisabled%> dataType="string"></input></td>
						<input name="<%=PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorCode")%>" type="hidden" value="<%=FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorCode",form,locale,task,context)%>"></input>
						<td align="left" class="payloadDataType"><%=FormUtil.getDatatypeLocale("string",locale)%></td><input name="<%=PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorCode")%>" type="hidden" value="string"></input>
						</tr>
					<%
					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorDescription");
					if (thisField == null || thisField.isEditable()) {
						thisDisabled = "";
					}
					else {
						thisDisabled = "disabled";
					}
					%>
						<tr><th align="left">Error Description</th>
						<td align="left"><textarea rows="5" cols="150" name="<%=PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorDescription")%>"><%=PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorDescription", form.getNamespaceMap(),"string", locale)%></textarea></td>
						<input name="<%=PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorDescription")%>" type="hidden" value="<%=FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorDescription",form,locale,task,context)%>"></input>
						<td align="left" class="payloadDataType"><%=FormUtil.getDatatypeLocale("string",locale)%></td><input name="<%=PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorDescription")%>" type="hidden" value="string"></input>
						</tr>
					<%
					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorText");
					if (thisField == null || thisField.isEditable()) {
						thisDisabled = "";
					}
					else {
						thisDisabled = "disabled";
					}
					%>
						<tr><th align="left">Error Text</th>
						<td align="left"><input name="<%=PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorText")%>" type="text" value="<%=PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorText", form.getNamespaceMap(),"string", locale)%>" <%=thisDisabled%> dataType="string"></input></td>
						<input name="<%=PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorText")%>" type="hidden" value="<%=FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorText",form,locale,task,context)%>"></input>
						<td align="left" class="payloadDataType"><%=FormUtil.getDatatypeLocale("string",locale)%></td><input name="<%=PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorText")%>" type="hidden" value="string"></input>
						</tr>
					<%
					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorType");
					if (thisField == null || thisField.isEditable()) {
						thisDisabled = "";
					}
					else {
						thisDisabled = "disabled";
					}
					%>
						<tr><th align="left">Error Type</th>
						<td align="left"><input name="<%=PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorType")%>" type="text" value="<%=PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorType", form.getNamespaceMap(),"string", locale)%>" <%=thisDisabled%> dataType="string"></input></td>
						<input name="<%=PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorType")%>" type="hidden" value="<%=FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorType",form,locale,task,context)%>"></input>
						<td align="left" class="payloadDataType"><%=FormUtil.getDatatypeLocale("string",locale)%></td><input name="<%=PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorType")%>" type="hidden" value="string"></input>
						</tr>
					<%
					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorSeverity");
					if (thisField == null || thisField.isEditable()) {
						thisDisabled = "";
					}
					else {
						thisDisabled = "disabled";
					}
					%>
						<tr><th align="left">Error Severity<font class="payloadAsterick">&nbsp;*</font></th>
						<td align="left"><input name="<%=PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorSeverity")%>" type="text" value="<%=PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorSeverity", form.getNamespaceMap(),"string", locale)%>" <%=thisDisabled%> dataType="string"></input></td>
						<input name="<%=PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorSeverity")%>" type="hidden" value="<%=FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorSeverity",form,locale,task,context)%>"></input>
						<td align="left" class="payloadDataType"><%=FormUtil.getDatatypeLocale("string",locale)%></td><input name="<%=PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorSeverity")%>" type="hidden" value="string"></input>
						</tr>
					<%
					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorDateTime");
					if (thisField == null || thisField.isEditable()) {
						thisDisabled = "";
					}
					else {
						thisDisabled = "disabled";
					}
					%>
						<tr><th align="left">Error Date Time<font class="payloadAsterick">&nbsp;*</font></th>
						<td align="left"><input name="<%=PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorDateTime")%>" type="text" value="<%=PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorDateTime", form.getNamespaceMap(),"string", locale)%>" <%=thisDisabled%> dataType="string"></input></td>
						<input name="<%=PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorDateTime")%>" type="hidden" value="<%=FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorDateTime",form,locale,task,context)%>"></input>
						<td align="left" class="payloadDataType"><%=FormUtil.getDatatypeLocale("string",locale)%></td><input name="<%=PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorDateTime")%>" type="hidden" value="string"></input>
						</tr>
					<%
					%>
						</table>
				<hr align="left" width="80%"/>
				<table cellpadding="0" cellspacing="3">
				<tr><td colspan="3" class="payloadSectionTitle" id="ns1_cl_MessageDetails">Message Details</td></tr>

					<%
					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageId");
					if (thisField == null || thisField.isEditable()) {
						thisDisabled = "";
					}
					else {
						thisDisabled = "disabled";
					}
					%>
						<tr><th align="left">Message Id<font class="payloadAsterick">&nbsp;*</font></th>
						<td align="left"><input name="<%=PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageId")%>" type="text" value="<%=PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageId", form.getNamespaceMap(),"string", locale)%>" <%=thisDisabled%> dataType="string"></input></td>
						<input name="<%=PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageId")%>" type="hidden" value="<%=FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageId",form,locale,task,context)%>"></input>
						<td align="left" class="payloadDataType"><%=FormUtil.getDatatypeLocale("string",locale)%></td><input name="<%=PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageId")%>" type="hidden" value="string"></input>
						</tr>
					<%
					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageDateTime");
					if (thisField == null || thisField.isEditable()) {
						thisDisabled = "";
					}
					else {
						thisDisabled = "disabled";
					}
					%>
						<tr><th align="left">Message Date Time</th>
						<td align="left"><input name="<%=PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageDateTime")%>" type="text" value="<%=PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageDateTime", form.getNamespaceMap(),"string", locale)%>" <%=thisDisabled%> dataType="string"></input></td>
						<input name="<%=PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageDateTime")%>" type="hidden" value="<%=FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageDateTime",form,locale,task,context)%>"></input>
						<td align="left" class="payloadDataType"><%=FormUtil.getDatatypeLocale("string",locale)%></td><input name="<%=PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageDateTime")%>" type="hidden" value="string"></input>
						</tr>
					<%
					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageType");
					if (thisField == null || thisField.isEditable()) {
						thisDisabled = "";
					}
					else {
						thisDisabled = "disabled";
					}
					%>
						<tr><th align="left">Message Type</th>
						<td align="left"><input name="<%=PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageType")%>" type="text" value="<%=PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageType", form.getNamespaceMap(),"string", locale)%>" <%=thisDisabled%> dataType="string"></input></td>
						<input name="<%=PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageType")%>" type="hidden" value="<%=FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageType",form,locale,task,context)%>"></input>
						<td align="left" class="payloadDataType"><%=FormUtil.getDatatypeLocale("string",locale)%></td><input name="<%=PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageType")%>" type="hidden" value="string"></input>
						</tr>
					<%
					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageVersion");
					if (thisField == null || thisField.isEditable()) {
						thisDisabled = "";
					}
					else {
						thisDisabled = "disabled";
					}
					%>
						<tr><th align="left">Message Version</th>
						<td align="left"><input name="<%=PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageVersion")%>" type="text" value="<%=PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageVersion", form.getNamespaceMap(),"string", locale)%>" <%=thisDisabled%> dataType="string"></input></td>
						<input name="<%=PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageVersion")%>" type="hidden" value="<%=FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageVersion",form,locale,task,context)%>"></input>
						<td align="left" class="payloadDataType"><%=FormUtil.getDatatypeLocale("string",locale)%></td><input name="<%=PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageVersion")%>" type="hidden" value="string"></input>
						</tr>
					<%
					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageOperation");
					if (thisField == null || thisField.isEditable()) {
						thisDisabled = "";
					}
					else {
						thisDisabled = "disabled";
					}
					%>
						<tr><th align="left">Message Operation</th>
						<td align="left"><input name="<%=PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageOperation")%>" type="text" value="<%=PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageOperation", form.getNamespaceMap(),"string", locale)%>" <%=thisDisabled%> dataType="string"></input></td>
						<input name="<%=PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageOperation")%>" type="hidden" value="<%=FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageOperation",form,locale,task,context)%>"></input>
						<td align="left" class="payloadDataType"><%=FormUtil.getDatatypeLocale("string",locale)%></td><input name="<%=PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageOperation")%>" type="hidden" value="string"></input>
						</tr>
					<%
					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageSourceSystem");
					if (thisField == null || thisField.isEditable()) {
						thisDisabled = "";
					}
					else {
						thisDisabled = "disabled";
					}
					%>
						<tr><th align="left">Message Source System</th>
						<td align="left"><input name="<%=PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageSourceSystem")%>" type="text" value="<%=PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageSourceSystem", form.getNamespaceMap(),"string", locale)%>" <%=thisDisabled%> dataType="string"></input></td>
						<input name="<%=PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageSourceSystem")%>" type="hidden" value="<%=FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageSourceSystem",form,locale,task,context)%>"></input>
						<td align="left" class="payloadDataType"><%=FormUtil.getDatatypeLocale("string",locale)%></td><input name="<%=PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageSourceSystem")%>" type="hidden" value="string"></input>
						</tr>
					<%
					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageSourceSystemComponent");
					if (thisField == null || thisField.isEditable()) {
						thisDisabled = "";
					}
					else {
						thisDisabled = "disabled";
					}
					%>
						<tr><th align="left">Message Source System Component</th>
						<td align="left"><input name="<%=PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageSourceSystemComponent")%>" type="text" value="<%=PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageSourceSystemComponent", form.getNamespaceMap(),"string", locale)%>" <%=thisDisabled%> dataType="string"></input></td>
						<input name="<%=PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageSourceSystemComponent")%>" type="hidden" value="<%=FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageSourceSystemComponent",form,locale,task,context)%>"></input>
						<td align="left" class="payloadDataType"><%=FormUtil.getDatatypeLocale("string",locale)%></td><input name="<%=PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageSourceSystemComponent")%>" type="hidden" value="string"></input>
						</tr>
					<%
					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageData");
					if (thisField == null || thisField.isEditable()) {
						thisDisabled = "";
					}
					else {
						thisDisabled = "disabled";
					}
					%>
						<tr><th align="left">Message Data</th>
						<td align="left"><textarea rows="15" cols="150" name="<%=PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageData")%>"><%=PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageData", form.getNamespaceMap(),"string", locale)%></textarea></td>
						<input name="<%=PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageData")%>" type="hidden" value="<%=FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageData",form,locale,task,context)%>"></input>
						<td align="left" class="payloadDataType"><%=FormUtil.getDatatypeLocale("string",locale)%></td><input name="<%=PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageData")%>" type="hidden" value="string"></input>
						</tr>
					<%
					%>
						</table>
				<hr align="left" width="80%"/>
				<table cellpadding="0" cellspacing="3">
				<tr><td colspan="3" class="payloadSectionTitle" id="ns1_cl_ErrorHandlingOptions">Error Handling Options</td></tr>

					<%
					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorHandlingOptions/ns1:Retire");
					if (thisField == null || thisField.isEditable()) {
						thisDisabled = "";
					}
					else {
						thisDisabled = "disabled";
					}
					%>
						<tr><th align="left">Retire</th>
						<td align="left"><input name="<%=PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorHandlingOptions/ns1:Retire")%>" type="text" value="<%=PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorHandlingOptions/ns1:Retire", form.getNamespaceMap(),"boolean", locale)%>" <%=thisDisabled%> dataType="boolean"></input></td>
						<input name="<%=PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorHandlingOptions/ns1:Retire")%>" type="hidden" value="<%=FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorHandlingOptions/ns1:Retire",form,locale,task,context)%>"></input>
						<td align="left" class="payloadDataType"><%=FormUtil.getDatatypeLocale("boolean",locale)%></td><input name="<%=PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorHandlingOptions/ns1:Retire")%>" type="hidden" value="boolean"></input>
						</tr>
					<%
					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorHandlingOptions/ns1:Task");
					if (thisField == null || thisField.isEditable()) {
						thisDisabled = "";
					}
					else {
						thisDisabled = "disabled";
					}
					%>
						<tr><th align="left">Task</th>
						<td align="left"><input name="<%=PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorHandlingOptions/ns1:Task")%>" type="text" value="<%=PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorHandlingOptions/ns1:Task", form.getNamespaceMap(),"boolean", locale)%>" <%=thisDisabled%> dataType="boolean"></input></td>
						<input name="<%=PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorHandlingOptions/ns1:Task")%>" type="hidden" value="<%=FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorHandlingOptions/ns1:Task",form,locale,task,context)%>"></input>
						<td align="left" class="payloadDataType"><%=FormUtil.getDatatypeLocale("boolean",locale)%></td><input name="<%=PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorHandlingOptions/ns1:Task")%>" type="hidden" value="boolean"></input>
						</tr>
					<%


        %>
        </table>
    </form>
  </div>
  
  <% 
  }
  catch (Exception e) {
    out.flush();
    response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, 
                      e.toString());
  } 
%>

<%!
     private String getXMLMappingFileURL( HttpServletRequest request) 
     {
       String url = "http://" + request.getServerName() + ":" + request.getServerPort()
                    + request.getContextPath() +"/";
       
       url = url + "payload-body.xml"; 
       return url;
     }
%>
