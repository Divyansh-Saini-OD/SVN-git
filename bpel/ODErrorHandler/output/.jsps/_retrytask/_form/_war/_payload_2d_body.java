package _retrytask._form._war;

import oracle.jsp.runtime.*;
import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.jsp.*;
import java.util.*;
import java.text.*;
import java.io.IOException;
import javax.servlet.http.HttpServletRequest;
import oracle.bpel.services.workflow.task.model.Task;
import oracle.bpel.services.workflow.worklist.servlet.Constants;
import oracle.bpel.services.workflow.worklist.api.payload.FormUtil;
import oracle.bpel.services.workflow.worklist.api.payload.Field;
import oracle.bpel.services.workflow.worklist.api.payload.PayloadFormGenerator;
import oracle.bpel.services.workflow.worklist.api.payload.Form;
import oracle.bpel.services.workflow.worklist.api.payload.PayloadConstant;
import oracle.bpel.services.workflow.client.IWorkflowServiceClient;
import oracle.bpel.services.workflow.client.WorkflowServiceClientFactory;
import oracle.bpel.services.workflow.query.ITaskQueryService;
import oracle.bpel.services.workflow.verification.IWorkflowContext;
import oracle.bpel.services.workflow.worklist.display.*;
import org.w3c.dom.*;


public class _payload_2d_body extends com.orionserver.http.OrionHttpJspPage {


  // ** Begin Declarations


     private String getXMLMappingFileURL( HttpServletRequest request) 
     {
       String url = "http://" + request.getServerName() + ":" + request.getServerPort()
                    + request.getContextPath() +"/";
       
       url = url + "payload-body.xml"; 
       return url;
     }

  // ** End Declarations

  public void _jspService(HttpServletRequest request, HttpServletResponse response) throws java.io.IOException, ServletException {

    response.setContentType( "text/html;charset=UTF-8");
    /* set up the intrinsic variables using the pageContext goober:
    ** session = HttpSession
    ** application = ServletContext
    ** out = JspWriter
    ** page = this
    ** config = ServletConfig
    ** all session/app beans declared in globals.jsa
    */
    PageContext pageContext = JspFactory.getDefaultFactory().getPageContext( this, request, response, null, true, JspWriter.DEFAULT_BUFFER, true);
    // Note: this is not emitted if the session directive == false
    HttpSession session = pageContext.getSession();
    int __jsp_tag_starteval;
    ServletContext application = pageContext.getServletContext();
    JspWriter out = pageContext.getOut();
    _payload_2d_body page = this;
    ServletConfig config = pageContext.getServletConfig();

    try {


      out.write(__oracle_jsp_text[0]);
      out.write(__oracle_jsp_text[1]);
      out.write(__oracle_jsp_text[2]);
      out.write(__oracle_jsp_text[3]);
      out.write(__oracle_jsp_text[4]);
      out.write(__oracle_jsp_text[5]);
      out.write(__oracle_jsp_text[6]);
      out.write(__oracle_jsp_text[7]);
      out.write(__oracle_jsp_text[8]);
      out.write(__oracle_jsp_text[9]);
      out.write(__oracle_jsp_text[10]);
      
        try {
      
      out.write(__oracle_jsp_text[11]);
       
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
        
      out.write(__oracle_jsp_text[12]);
      out.print(Constants.UPDATE_SERVLET_NAME);
      out.write(__oracle_jsp_text[13]);
      out.print(Constants.WFTASKPAYLOAD_UPDATE_BUTTON_KEY_NAME);
      out.write(__oracle_jsp_text[14]);
      
                Iterator iter = requiredParamNames.iterator();
                while (iter.hasNext()) {
                  String paramName = (String) iter.next();
                  String paramValue = (String) requiredParams.get(paramName);
              
      out.write(__oracle_jsp_text[15]);
      out.print(paramName);
      out.write(__oracle_jsp_text[16]);
      out.print(paramValue);
      out.write(__oracle_jsp_text[17]);
      
                }     
              
      out.write(__oracle_jsp_text[18]);
      
                Field thisField = null;
                String thisValue = "";
                String thisDisabled = "";
                
                
      					
      out.write(__oracle_jsp_text[19]);
      
      					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessName");
      					if (thisField == null || thisField.isEditable()) {
      						thisDisabled = "";
      					}
      					else {
      						thisDisabled = "disabled";
      					}
      					
      out.write(__oracle_jsp_text[20]);
      out.print(PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessName"));
      out.write(__oracle_jsp_text[21]);
      out.print(PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessName", form.getNamespaceMap(),"string", locale));
      out.write(__oracle_jsp_text[22]);
      out.print(thisDisabled);
      out.write(__oracle_jsp_text[23]);
      out.print(PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessName"));
      out.write(__oracle_jsp_text[24]);
      out.print(FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessName",form,locale,task,context));
      out.write(__oracle_jsp_text[25]);
      out.print(FormUtil.getDatatypeLocale("string",locale));
      out.write(__oracle_jsp_text[26]);
      out.print(PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessName"));
      out.write(__oracle_jsp_text[27]);
      
      					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessId");
      					if (thisField == null || thisField.isEditable()) {
      						thisDisabled = "";
      					}
      					else {
      						thisDisabled = "disabled";
      					}
      					
      out.write(__oracle_jsp_text[28]);
      out.print(PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessId"));
      out.write(__oracle_jsp_text[29]);
      out.print(PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessId", form.getNamespaceMap(),"string", locale));
      out.write(__oracle_jsp_text[30]);
      out.print(thisDisabled);
      out.write(__oracle_jsp_text[31]);
      out.print(PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessId"));
      out.write(__oracle_jsp_text[32]);
      out.print(FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessId",form,locale,task,context));
      out.write(__oracle_jsp_text[33]);
      out.print(FormUtil.getDatatypeLocale("string",locale));
      out.write(__oracle_jsp_text[34]);
      out.print(PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessId"));
      out.write(__oracle_jsp_text[35]);
      
      					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessStep");
      					if (thisField == null || thisField.isEditable()) {
      						thisDisabled = "";
      					}
      					else {
      						thisDisabled = "disabled";
      					}
      					
      out.write(__oracle_jsp_text[36]);
      out.print(PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessStep"));
      out.write(__oracle_jsp_text[37]);
      out.print(PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessStep", form.getNamespaceMap(),"string", locale));
      out.write(__oracle_jsp_text[38]);
      out.print(thisDisabled);
      out.write(__oracle_jsp_text[39]);
      out.print(PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessStep"));
      out.write(__oracle_jsp_text[40]);
      out.print(FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessStep",form,locale,task,context));
      out.write(__oracle_jsp_text[41]);
      out.print(FormUtil.getDatatypeLocale("string",locale));
      out.write(__oracle_jsp_text[42]);
      out.print(PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessStep"));
      out.write(__oracle_jsp_text[43]);
      
      					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessDomain");
      					if (thisField == null || thisField.isEditable()) {
      						thisDisabled = "";
      					}
      					else {
      						thisDisabled = "disabled";
      					}
      					
      out.write(__oracle_jsp_text[44]);
      out.print(PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessDomain"));
      out.write(__oracle_jsp_text[45]);
      out.print(PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessDomain", form.getNamespaceMap(),"string", locale));
      out.write(__oracle_jsp_text[46]);
      out.print(thisDisabled);
      out.write(__oracle_jsp_text[47]);
      out.print(PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessDomain"));
      out.write(__oracle_jsp_text[48]);
      out.print(FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessDomain",form,locale,task,context));
      out.write(__oracle_jsp_text[49]);
      out.print(FormUtil.getDatatypeLocale("string",locale));
      out.write(__oracle_jsp_text[50]);
      out.print(PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:BusinessProcessDomain"));
      out.write(__oracle_jsp_text[51]);
      
      					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:SystemName");
      					if (thisField == null || thisField.isEditable()) {
      						thisDisabled = "";
      					}
      					else {
      						thisDisabled = "disabled";
      					}
      					
      out.write(__oracle_jsp_text[52]);
      out.print(PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:SystemName"));
      out.write(__oracle_jsp_text[53]);
      out.print(PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:SystemName", form.getNamespaceMap(),"string", locale));
      out.write(__oracle_jsp_text[54]);
      out.print(thisDisabled);
      out.write(__oracle_jsp_text[55]);
      out.print(PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:SystemName"));
      out.write(__oracle_jsp_text[56]);
      out.print(FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:SystemName",form,locale,task,context));
      out.write(__oracle_jsp_text[57]);
      out.print(FormUtil.getDatatypeLocale("string",locale));
      out.write(__oracle_jsp_text[58]);
      out.print(PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:SystemName"));
      out.write(__oracle_jsp_text[59]);
      
      					
      out.write(__oracle_jsp_text[60]);
      
      					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPFrom");
      					if (thisField == null || thisField.isEditable()) {
      						thisDisabled = "";
      					}
      					else {
      						thisDisabled = "disabled";
      					}
      					
      out.write(__oracle_jsp_text[61]);
      out.print(PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPFrom"));
      out.write(__oracle_jsp_text[62]);
      out.print(PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPFrom", form.getNamespaceMap(),"string", locale));
      out.write(__oracle_jsp_text[63]);
      out.print(thisDisabled);
      out.write(__oracle_jsp_text[64]);
      out.print(PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPFrom"));
      out.write(__oracle_jsp_text[65]);
      out.print(FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPFrom",form,locale,task,context));
      out.write(__oracle_jsp_text[66]);
      out.print(FormUtil.getDatatypeLocale("string",locale));
      out.write(__oracle_jsp_text[67]);
      out.print(PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPFrom"));
      out.write(__oracle_jsp_text[68]);
      
      					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPTo");
      					if (thisField == null || thisField.isEditable()) {
      						thisDisabled = "";
      					}
      					else {
      						thisDisabled = "disabled";
      					}
      					
      out.write(__oracle_jsp_text[69]);
      out.print(PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPTo"));
      out.write(__oracle_jsp_text[70]);
      out.print(PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPTo", form.getNamespaceMap(),"string", locale));
      out.write(__oracle_jsp_text[71]);
      out.print(thisDisabled);
      out.write(__oracle_jsp_text[72]);
      out.print(PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPTo"));
      out.write(__oracle_jsp_text[73]);
      out.print(FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPTo",form,locale,task,context));
      out.write(__oracle_jsp_text[74]);
      out.print(FormUtil.getDatatypeLocale("string",locale));
      out.write(__oracle_jsp_text[75]);
      out.print(PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPTo"));
      out.write(__oracle_jsp_text[76]);
      
      					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPDocTypeName");
      					if (thisField == null || thisField.isEditable()) {
      						thisDisabled = "";
      					}
      					else {
      						thisDisabled = "disabled";
      					}
      					
      out.write(__oracle_jsp_text[77]);
      out.print(PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPDocTypeName"));
      out.write(__oracle_jsp_text[78]);
      out.print(PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPDocTypeName", form.getNamespaceMap(),"string", locale));
      out.write(__oracle_jsp_text[79]);
      out.print(thisDisabled);
      out.write(__oracle_jsp_text[80]);
      out.print(PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPDocTypeName"));
      out.write(__oracle_jsp_text[81]);
      out.print(FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPDocTypeName",form,locale,task,context));
      out.write(__oracle_jsp_text[82]);
      out.print(FormUtil.getDatatypeLocale("string",locale));
      out.write(__oracle_jsp_text[83]);
      out.print(PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPDocTypeName"));
      out.write(__oracle_jsp_text[84]);
      
      					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPDocTypeRevision");
      					if (thisField == null || thisField.isEditable()) {
      						thisDisabled = "";
      					}
      					else {
      						thisDisabled = "disabled";
      					}
      					
      out.write(__oracle_jsp_text[85]);
      out.print(PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPDocTypeRevision"));
      out.write(__oracle_jsp_text[86]);
      out.print(PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPDocTypeRevision", form.getNamespaceMap(),"string", locale));
      out.write(__oracle_jsp_text[87]);
      out.print(thisDisabled);
      out.write(__oracle_jsp_text[88]);
      out.print(PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPDocTypeRevision"));
      out.write(__oracle_jsp_text[89]);
      out.print(FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPDocTypeRevision",form,locale,task,context));
      out.write(__oracle_jsp_text[90]);
      out.print(FormUtil.getDatatypeLocale("string",locale));
      out.write(__oracle_jsp_text[91]);
      out.print(PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ProcessInfo/ns1:TradingPartnerDetails/ns1:TPDocTypeRevision"));
      out.write(__oracle_jsp_text[92]);
      
      					
      out.write(__oracle_jsp_text[93]);
      
      					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorCode");
      					if (thisField == null || thisField.isEditable()) {
      						thisDisabled = "";
      					}
      					else {
      						thisDisabled = "disabled";
      					}
      					
      out.write(__oracle_jsp_text[94]);
      out.print(PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorCode"));
      out.write(__oracle_jsp_text[95]);
      out.print(PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorCode", form.getNamespaceMap(),"string", locale));
      out.write(__oracle_jsp_text[96]);
      out.print(thisDisabled);
      out.write(__oracle_jsp_text[97]);
      out.print(PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorCode"));
      out.write(__oracle_jsp_text[98]);
      out.print(FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorCode",form,locale,task,context));
      out.write(__oracle_jsp_text[99]);
      out.print(FormUtil.getDatatypeLocale("string",locale));
      out.write(__oracle_jsp_text[100]);
      out.print(PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorCode"));
      out.write(__oracle_jsp_text[101]);
      
      					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorDescription");
      					if (thisField == null || thisField.isEditable()) {
      						thisDisabled = "";
      					}
      					else {
      						thisDisabled = "disabled";
      					}
      					
      out.write(__oracle_jsp_text[102]);
      out.print(PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorDescription"));
      out.write(__oracle_jsp_text[103]);
      out.print(PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorDescription", form.getNamespaceMap(),"string", locale));
      out.write(__oracle_jsp_text[104]);
      out.print(PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorDescription"));
      out.write(__oracle_jsp_text[105]);
      out.print(FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorDescription",form,locale,task,context));
      out.write(__oracle_jsp_text[106]);
      out.print(FormUtil.getDatatypeLocale("string",locale));
      out.write(__oracle_jsp_text[107]);
      out.print(PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorDescription"));
      out.write(__oracle_jsp_text[108]);
      
      					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorText");
      					if (thisField == null || thisField.isEditable()) {
      						thisDisabled = "";
      					}
      					else {
      						thisDisabled = "disabled";
      					}
      					
      out.write(__oracle_jsp_text[109]);
      out.print(PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorText"));
      out.write(__oracle_jsp_text[110]);
      out.print(PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorText", form.getNamespaceMap(),"string", locale));
      out.write(__oracle_jsp_text[111]);
      out.print(thisDisabled);
      out.write(__oracle_jsp_text[112]);
      out.print(PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorText"));
      out.write(__oracle_jsp_text[113]);
      out.print(FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorText",form,locale,task,context));
      out.write(__oracle_jsp_text[114]);
      out.print(FormUtil.getDatatypeLocale("string",locale));
      out.write(__oracle_jsp_text[115]);
      out.print(PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorText"));
      out.write(__oracle_jsp_text[116]);
      
      					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorType");
      					if (thisField == null || thisField.isEditable()) {
      						thisDisabled = "";
      					}
      					else {
      						thisDisabled = "disabled";
      					}
      					
      out.write(__oracle_jsp_text[117]);
      out.print(PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorType"));
      out.write(__oracle_jsp_text[118]);
      out.print(PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorType", form.getNamespaceMap(),"string", locale));
      out.write(__oracle_jsp_text[119]);
      out.print(thisDisabled);
      out.write(__oracle_jsp_text[120]);
      out.print(PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorType"));
      out.write(__oracle_jsp_text[121]);
      out.print(FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorType",form,locale,task,context));
      out.write(__oracle_jsp_text[122]);
      out.print(FormUtil.getDatatypeLocale("string",locale));
      out.write(__oracle_jsp_text[123]);
      out.print(PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorType"));
      out.write(__oracle_jsp_text[124]);
      
      					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorSeverity");
      					if (thisField == null || thisField.isEditable()) {
      						thisDisabled = "";
      					}
      					else {
      						thisDisabled = "disabled";
      					}
      					
      out.write(__oracle_jsp_text[125]);
      out.print(PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorSeverity"));
      out.write(__oracle_jsp_text[126]);
      out.print(PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorSeverity", form.getNamespaceMap(),"string", locale));
      out.write(__oracle_jsp_text[127]);
      out.print(thisDisabled);
      out.write(__oracle_jsp_text[128]);
      out.print(PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorSeverity"));
      out.write(__oracle_jsp_text[129]);
      out.print(FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorSeverity",form,locale,task,context));
      out.write(__oracle_jsp_text[130]);
      out.print(FormUtil.getDatatypeLocale("string",locale));
      out.write(__oracle_jsp_text[131]);
      out.print(PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorSeverity"));
      out.write(__oracle_jsp_text[132]);
      
      					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorDateTime");
      					if (thisField == null || thisField.isEditable()) {
      						thisDisabled = "";
      					}
      					else {
      						thisDisabled = "disabled";
      					}
      					
      out.write(__oracle_jsp_text[133]);
      out.print(PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorDateTime"));
      out.write(__oracle_jsp_text[134]);
      out.print(PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorDateTime", form.getNamespaceMap(),"string", locale));
      out.write(__oracle_jsp_text[135]);
      out.print(thisDisabled);
      out.write(__oracle_jsp_text[136]);
      out.print(PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorDateTime"));
      out.write(__oracle_jsp_text[137]);
      out.print(FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorDateTime",form,locale,task,context));
      out.write(__oracle_jsp_text[138]);
      out.print(FormUtil.getDatatypeLocale("string",locale));
      out.write(__oracle_jsp_text[139]);
      out.print(PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorDetails/ns1:ErrorDateTime"));
      out.write(__oracle_jsp_text[140]);
      
      					
      out.write(__oracle_jsp_text[141]);
      
      					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageId");
      					if (thisField == null || thisField.isEditable()) {
      						thisDisabled = "";
      					}
      					else {
      						thisDisabled = "disabled";
      					}
      					
      out.write(__oracle_jsp_text[142]);
      out.print(PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageId"));
      out.write(__oracle_jsp_text[143]);
      out.print(PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageId", form.getNamespaceMap(),"string", locale));
      out.write(__oracle_jsp_text[144]);
      out.print(thisDisabled);
      out.write(__oracle_jsp_text[145]);
      out.print(PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageId"));
      out.write(__oracle_jsp_text[146]);
      out.print(FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageId",form,locale,task,context));
      out.write(__oracle_jsp_text[147]);
      out.print(FormUtil.getDatatypeLocale("string",locale));
      out.write(__oracle_jsp_text[148]);
      out.print(PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageId"));
      out.write(__oracle_jsp_text[149]);
      
      					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageDateTime");
      					if (thisField == null || thisField.isEditable()) {
      						thisDisabled = "";
      					}
      					else {
      						thisDisabled = "disabled";
      					}
      					
      out.write(__oracle_jsp_text[150]);
      out.print(PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageDateTime"));
      out.write(__oracle_jsp_text[151]);
      out.print(PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageDateTime", form.getNamespaceMap(),"string", locale));
      out.write(__oracle_jsp_text[152]);
      out.print(thisDisabled);
      out.write(__oracle_jsp_text[153]);
      out.print(PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageDateTime"));
      out.write(__oracle_jsp_text[154]);
      out.print(FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageDateTime",form,locale,task,context));
      out.write(__oracle_jsp_text[155]);
      out.print(FormUtil.getDatatypeLocale("string",locale));
      out.write(__oracle_jsp_text[156]);
      out.print(PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageDateTime"));
      out.write(__oracle_jsp_text[157]);
      
      					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageType");
      					if (thisField == null || thisField.isEditable()) {
      						thisDisabled = "";
      					}
      					else {
      						thisDisabled = "disabled";
      					}
      					
      out.write(__oracle_jsp_text[158]);
      out.print(PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageType"));
      out.write(__oracle_jsp_text[159]);
      out.print(PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageType", form.getNamespaceMap(),"string", locale));
      out.write(__oracle_jsp_text[160]);
      out.print(thisDisabled);
      out.write(__oracle_jsp_text[161]);
      out.print(PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageType"));
      out.write(__oracle_jsp_text[162]);
      out.print(FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageType",form,locale,task,context));
      out.write(__oracle_jsp_text[163]);
      out.print(FormUtil.getDatatypeLocale("string",locale));
      out.write(__oracle_jsp_text[164]);
      out.print(PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageType"));
      out.write(__oracle_jsp_text[165]);
      
      					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageVersion");
      					if (thisField == null || thisField.isEditable()) {
      						thisDisabled = "";
      					}
      					else {
      						thisDisabled = "disabled";
      					}
      					
      out.write(__oracle_jsp_text[166]);
      out.print(PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageVersion"));
      out.write(__oracle_jsp_text[167]);
      out.print(PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageVersion", form.getNamespaceMap(),"string", locale));
      out.write(__oracle_jsp_text[168]);
      out.print(thisDisabled);
      out.write(__oracle_jsp_text[169]);
      out.print(PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageVersion"));
      out.write(__oracle_jsp_text[170]);
      out.print(FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageVersion",form,locale,task,context));
      out.write(__oracle_jsp_text[171]);
      out.print(FormUtil.getDatatypeLocale("string",locale));
      out.write(__oracle_jsp_text[172]);
      out.print(PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageVersion"));
      out.write(__oracle_jsp_text[173]);
      
      					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageOperation");
      					if (thisField == null || thisField.isEditable()) {
      						thisDisabled = "";
      					}
      					else {
      						thisDisabled = "disabled";
      					}
      					
      out.write(__oracle_jsp_text[174]);
      out.print(PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageOperation"));
      out.write(__oracle_jsp_text[175]);
      out.print(PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageOperation", form.getNamespaceMap(),"string", locale));
      out.write(__oracle_jsp_text[176]);
      out.print(thisDisabled);
      out.write(__oracle_jsp_text[177]);
      out.print(PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageOperation"));
      out.write(__oracle_jsp_text[178]);
      out.print(FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageOperation",form,locale,task,context));
      out.write(__oracle_jsp_text[179]);
      out.print(FormUtil.getDatatypeLocale("string",locale));
      out.write(__oracle_jsp_text[180]);
      out.print(PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageOperation"));
      out.write(__oracle_jsp_text[181]);
      
      					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageSourceSystem");
      					if (thisField == null || thisField.isEditable()) {
      						thisDisabled = "";
      					}
      					else {
      						thisDisabled = "disabled";
      					}
      					
      out.write(__oracle_jsp_text[182]);
      out.print(PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageSourceSystem"));
      out.write(__oracle_jsp_text[183]);
      out.print(PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageSourceSystem", form.getNamespaceMap(),"string", locale));
      out.write(__oracle_jsp_text[184]);
      out.print(thisDisabled);
      out.write(__oracle_jsp_text[185]);
      out.print(PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageSourceSystem"));
      out.write(__oracle_jsp_text[186]);
      out.print(FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageSourceSystem",form,locale,task,context));
      out.write(__oracle_jsp_text[187]);
      out.print(FormUtil.getDatatypeLocale("string",locale));
      out.write(__oracle_jsp_text[188]);
      out.print(PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageSourceSystem"));
      out.write(__oracle_jsp_text[189]);
      
      					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageSourceSystemComponent");
      					if (thisField == null || thisField.isEditable()) {
      						thisDisabled = "";
      					}
      					else {
      						thisDisabled = "disabled";
      					}
      					
      out.write(__oracle_jsp_text[190]);
      out.print(PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageSourceSystemComponent"));
      out.write(__oracle_jsp_text[191]);
      out.print(PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageSourceSystemComponent", form.getNamespaceMap(),"string", locale));
      out.write(__oracle_jsp_text[192]);
      out.print(thisDisabled);
      out.write(__oracle_jsp_text[193]);
      out.print(PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageSourceSystemComponent"));
      out.write(__oracle_jsp_text[194]);
      out.print(FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageSourceSystemComponent",form,locale,task,context));
      out.write(__oracle_jsp_text[195]);
      out.print(FormUtil.getDatatypeLocale("string",locale));
      out.write(__oracle_jsp_text[196]);
      out.print(PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageSourceSystemComponent"));
      out.write(__oracle_jsp_text[197]);
      
      					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageData");
      					if (thisField == null || thisField.isEditable()) {
      						thisDisabled = "";
      					}
      					else {
      						thisDisabled = "disabled";
      					}
      					
      out.write(__oracle_jsp_text[198]);
      out.print(PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageData"));
      out.write(__oracle_jsp_text[199]);
      out.print(PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageData", form.getNamespaceMap(),"string", locale));
      out.write(__oracle_jsp_text[200]);
      out.print(PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageData"));
      out.write(__oracle_jsp_text[201]);
      out.print(FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageData",form,locale,task,context));
      out.write(__oracle_jsp_text[202]);
      out.print(FormUtil.getDatatypeLocale("string",locale));
      out.write(__oracle_jsp_text[203]);
      out.print(PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:MessageDetails/ns1:MessageData"));
      out.write(__oracle_jsp_text[204]);
      
      					
      out.write(__oracle_jsp_text[205]);
      
      					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorHandlingOptions/ns1:Retire");
      					if (thisField == null || thisField.isEditable()) {
      						thisDisabled = "";
      					}
      					else {
      						thisDisabled = "disabled";
      					}
      					
      out.write(__oracle_jsp_text[206]);
      out.print(PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorHandlingOptions/ns1:Retire"));
      out.write(__oracle_jsp_text[207]);
      out.print(PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorHandlingOptions/ns1:Retire", form.getNamespaceMap(),"boolean", locale));
      out.write(__oracle_jsp_text[208]);
      out.print(thisDisabled);
      out.write(__oracle_jsp_text[209]);
      out.print(PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorHandlingOptions/ns1:Retire"));
      out.write(__oracle_jsp_text[210]);
      out.print(FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorHandlingOptions/ns1:Retire",form,locale,task,context));
      out.write(__oracle_jsp_text[211]);
      out.print(FormUtil.getDatatypeLocale("boolean",locale));
      out.write(__oracle_jsp_text[212]);
      out.print(PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorHandlingOptions/ns1:Retire"));
      out.write(__oracle_jsp_text[213]);
      
      					thisField = form.getField("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorHandlingOptions/ns1:Task");
      					if (thisField == null || thisField.isEditable()) {
      						thisDisabled = "";
      					}
      					else {
      						thisDisabled = "disabled";
      					}
      					
      out.write(__oracle_jsp_text[214]);
      out.print(PayloadFormGenerator.constructName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorHandlingOptions/ns1:Task"));
      out.write(__oracle_jsp_text[215]);
      out.print(PayloadFormGenerator.selectNodeValue(payload, "/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorHandlingOptions/ns1:Task", form.getNamespaceMap(),"boolean", locale));
      out.write(__oracle_jsp_text[216]);
      out.print(thisDisabled);
      out.write(__oracle_jsp_text[217]);
      out.print(PayloadFormGenerator.constructDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorHandlingOptions/ns1:Task"));
      out.write(__oracle_jsp_text[218]);
      out.print(FormUtil.getElementDisplayName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorHandlingOptions/ns1:Task",form,locale,task,context));
      out.write(__oracle_jsp_text[219]);
      out.print(FormUtil.getDatatypeLocale("boolean",locale));
      out.write(__oracle_jsp_text[220]);
      out.print(PayloadFormGenerator.constructDataTypeName("/ns0:task/ns0:payload/ns1:ODErrorHandlerProcessRequest/ns1:ErrorHandlingOptions/ns1:Task"));
      out.write(__oracle_jsp_text[221]);
      
      
      
              
      out.write(__oracle_jsp_text[222]);
       
        }
        catch (Exception e) {
          out.flush();
          response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, 
                            e.toString());
        } 
      
      out.write(__oracle_jsp_text[223]);
      out.write(__oracle_jsp_text[224]);

    }
    catch (Throwable e) {
      if (!(e instanceof javax.servlet.jsp.SkipPageException)){
        try {
          if (out != null) out.clear();
        }
        catch (Exception clearException) {
        }
        pageContext.handlePageException(e);
      }
    }
    finally {
      OracleJspRuntime.extraHandlePCFinally(pageContext, true);
      JspFactory.getDefaultFactory().releasePageContext(pageContext);
    }

  }
  private static final char __oracle_jsp_text[][]=new char[225][];
  static {
    try {
    __oracle_jsp_text[0] = 
    "  <!-- BPM Worklist Application; Human Workflow Application -->\n  <!-- JSP for displaying Details page -->\n\n".toCharArray();
    __oracle_jsp_text[1] = 
    "\n".toCharArray();
    __oracle_jsp_text[2] = 
    "\n".toCharArray();
    __oracle_jsp_text[3] = 
    "\n".toCharArray();
    __oracle_jsp_text[4] = 
    "\n".toCharArray();
    __oracle_jsp_text[5] = 
    "\n".toCharArray();
    __oracle_jsp_text[6] = 
    "\n".toCharArray();
    __oracle_jsp_text[7] = 
    "\n".toCharArray();
    __oracle_jsp_text[8] = 
    "\n\n\n".toCharArray();
    __oracle_jsp_text[9] = 
    "\n".toCharArray();
    __oracle_jsp_text[10] = 
    "\n\n".toCharArray();
    __oracle_jsp_text[11] = 
    "\n  \n  ".toCharArray();
    __oracle_jsp_text[12] = 
    "\n  \n  <!-- USER CAN MODIFY THE FOLLOWING CODE -->\n\n  <div id=\"htmlView\" style=\"padding:10px;padding-top:0px;padding-bottom:0px;display:block\">\n    <br/><br/>\n    <form id=\"PayloadJSPHTML\" name=\"PayloadJSPHTML\"\n        action=\"".toCharArray();
    __oracle_jsp_text[13] = 
    "\" \n        method=\"post\" onSubmit=\"return validateData(this)\">        \n        <!-- print required params -->\n        <input type=\"hidden\" name=\"tableOperationAdd\" value=\"\" />\n        <input type=\"hidden\" name=\"tableOperationRemove\" value=\"\" />\n        <input type=\"hidden\" name=\"".toCharArray();
    __oracle_jsp_text[14] = 
    "\" value=\"\" />\n        ".toCharArray();
    __oracle_jsp_text[15] = 
    "\n            <input type=\"hidden\" name=\"".toCharArray();
    __oracle_jsp_text[16] = 
    "\" value=\"".toCharArray();
    __oracle_jsp_text[17] = 
    "\"/>\n        ".toCharArray();
    __oracle_jsp_text[18] = 
    "\n        <!-- print form -->\n        <table border=\"0\" cellpadding=\"0\" cellspacing=\"3\">\n        ".toCharArray();
    __oracle_jsp_text[19] = 
    "\n\t\t\t\t\t\t</table>\n\t\t\t\t<hr align=\"left\" width=\"80%\"/>\n\t\t\t\t<table cellpadding=\"0\" cellspacing=\"3\">\n\t\t\t\t<tr><td colspan=\"3\" class=\"payloadSectionTitle\" id=\"ns1_cl_ProcessInfo\">Process Info</td></tr>\n\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[20] = 
    "\n\t\t\t\t\t\t<tr><th align=\"left\">Business Process Name<font class=\"payloadAsterick\">&nbsp;*</font></th>\n\t\t\t\t\t\t<td align=\"left\"><input name=\"".toCharArray();
    __oracle_jsp_text[21] = 
    "\" type=\"text\" value=\"".toCharArray();
    __oracle_jsp_text[22] = 
    "\" ".toCharArray();
    __oracle_jsp_text[23] = 
    " dataType=\"string\"></input></td>\n\t\t\t\t\t\t<input name=\"".toCharArray();
    __oracle_jsp_text[24] = 
    "\" type=\"hidden\" value=\"".toCharArray();
    __oracle_jsp_text[25] = 
    "\"></input>\n\t\t\t\t\t\t<td align=\"left\" class=\"payloadDataType\">".toCharArray();
    __oracle_jsp_text[26] = 
    "</td><input name=\"".toCharArray();
    __oracle_jsp_text[27] = 
    "\" type=\"hidden\" value=\"string\"></input> \n\t\t\t\t\t\t</tr>\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[28] = 
    "\n\t\t\t\t\t\t<tr><th align=\"left\">Business Process Id<font class=\"payloadAsterick\">&nbsp;*</font></th>\n\t\t\t\t\t\t<td align=\"left\"><input name=\"".toCharArray();
    __oracle_jsp_text[29] = 
    "\" type=\"text\" value=\"".toCharArray();
    __oracle_jsp_text[30] = 
    "\" ".toCharArray();
    __oracle_jsp_text[31] = 
    " dataType=\"string\"></input></td>\n\t\t\t\t\t\t<input name=\"".toCharArray();
    __oracle_jsp_text[32] = 
    "\" type=\"hidden\" value=\"".toCharArray();
    __oracle_jsp_text[33] = 
    "\"></input>\n\t\t\t\t\t\t<td align=\"left\" class=\"payloadDataType\">".toCharArray();
    __oracle_jsp_text[34] = 
    "</td><input name=\"".toCharArray();
    __oracle_jsp_text[35] = 
    "\" type=\"hidden\" value=\"string\"></input>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[36] = 
    "\n\t\t\t\t\t\t<tr><th align=\"left\">Business Process Step</th>\n\t\t\t\t\t\t<td align=\"left\"><input name=\"".toCharArray();
    __oracle_jsp_text[37] = 
    "\" type=\"text\" value=\"".toCharArray();
    __oracle_jsp_text[38] = 
    "\" ".toCharArray();
    __oracle_jsp_text[39] = 
    " dataType=\"string\"></input></td>\n\t\t\t\t\t\t<input name=\"".toCharArray();
    __oracle_jsp_text[40] = 
    "\" type=\"hidden\" value=\"".toCharArray();
    __oracle_jsp_text[41] = 
    "\"></input>\n\t\t\t\t\t\t<td align=\"left\" class=\"payloadDataType\">".toCharArray();
    __oracle_jsp_text[42] = 
    "</td><input name=\"".toCharArray();
    __oracle_jsp_text[43] = 
    "\" type=\"hidden\" value=\"string\"></input>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[44] = 
    "\n\t\t\t\t\t\t<tr><th align=\"left\">Business Process Domain</th>\n\t\t\t\t\t\t<td align=\"left\"><input name=\"".toCharArray();
    __oracle_jsp_text[45] = 
    "\" type=\"text\" value=\"".toCharArray();
    __oracle_jsp_text[46] = 
    "\" ".toCharArray();
    __oracle_jsp_text[47] = 
    " dataType=\"string\"></input></td>\n\t\t\t\t\t\t<input name=\"".toCharArray();
    __oracle_jsp_text[48] = 
    "\" type=\"hidden\" value=\"".toCharArray();
    __oracle_jsp_text[49] = 
    "\"></input>\n\t\t\t\t\t\t<td align=\"left\" class=\"payloadDataType\">".toCharArray();
    __oracle_jsp_text[50] = 
    "</td><input name=\"".toCharArray();
    __oracle_jsp_text[51] = 
    "\" type=\"hidden\" value=\"string\"></input>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[52] = 
    "\n\t\t\t\t\t\t<tr><th align=\"left\">System Name</th>\n\t\t\t\t\t\t<td align=\"left\"><input name=\"".toCharArray();
    __oracle_jsp_text[53] = 
    "\" type=\"text\" value=\"".toCharArray();
    __oracle_jsp_text[54] = 
    "\" ".toCharArray();
    __oracle_jsp_text[55] = 
    " dataType=\"string\"></input></td>\n\t\t\t\t\t\t<input name=\"".toCharArray();
    __oracle_jsp_text[56] = 
    "\" type=\"hidden\" value=\"".toCharArray();
    __oracle_jsp_text[57] = 
    "\"></input>\n\t\t\t\t\t\t<td align=\"left\" class=\"payloadDataType\">".toCharArray();
    __oracle_jsp_text[58] = 
    "</td><input name=\"".toCharArray();
    __oracle_jsp_text[59] = 
    "\" type=\"hidden\" value=\"string\"></input>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[60] = 
    "\n\t\t\t\t\t\t</table>\n\t\t\t\t<hr align=\"left\" width=\"80%\"/>\n\t\t\t\t<table cellpadding=\"0\" cellspacing=\"3\">\n\t\t\t\t<tr><td colspan=\"3\" class=\"payloadSectionTitle\" id=\"ns1_cl_TradingPartnerDetails\">Trading Partner Details</td></tr>\n\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[61] = 
    "\n\t\t\t\t\t\t<tr><th align=\"left\">TP From<font class=\"payloadAsterick\">&nbsp;*</font></th>\n\t\t\t\t\t\t<td align=\"left\"><input name=\"".toCharArray();
    __oracle_jsp_text[62] = 
    "\" type=\"text\" value=\"".toCharArray();
    __oracle_jsp_text[63] = 
    "\" ".toCharArray();
    __oracle_jsp_text[64] = 
    " dataType=\"string\"></input></td>\n\t\t\t\t\t\t<input name=\"".toCharArray();
    __oracle_jsp_text[65] = 
    "\" type=\"hidden\" value=\"".toCharArray();
    __oracle_jsp_text[66] = 
    "\"></input>\n\t\t\t\t\t\t<td align=\"left\" class=\"payloadDataType\">".toCharArray();
    __oracle_jsp_text[67] = 
    "</td><input name=\"".toCharArray();
    __oracle_jsp_text[68] = 
    "\" type=\"hidden\" value=\"string\"></input>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[69] = 
    "\n\t\t\t\t\t\t<tr><th align=\"left\">TP To<font class=\"payloadAsterick\">&nbsp;*</font></th>\n\t\t\t\t\t\t<td align=\"left\"><input name=\"".toCharArray();
    __oracle_jsp_text[70] = 
    "\" type=\"text\" value=\"".toCharArray();
    __oracle_jsp_text[71] = 
    "\" ".toCharArray();
    __oracle_jsp_text[72] = 
    " dataType=\"string\"></input></td>\n\t\t\t\t\t\t<input name=\"".toCharArray();
    __oracle_jsp_text[73] = 
    "\" type=\"hidden\" value=\"".toCharArray();
    __oracle_jsp_text[74] = 
    "\"></input>\n\t\t\t\t\t\t<td align=\"left\" class=\"payloadDataType\">".toCharArray();
    __oracle_jsp_text[75] = 
    "</td><input name=\"".toCharArray();
    __oracle_jsp_text[76] = 
    "\" type=\"hidden\" value=\"string\"></input>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[77] = 
    "\n\t\t\t\t\t\t<tr><th align=\"left\">TP Doc Type Name<font class=\"payloadAsterick\">&nbsp;*</font></th>\n\t\t\t\t\t\t<td align=\"left\"><input name=\"".toCharArray();
    __oracle_jsp_text[78] = 
    "\" type=\"text\" value=\"".toCharArray();
    __oracle_jsp_text[79] = 
    "\" ".toCharArray();
    __oracle_jsp_text[80] = 
    " dataType=\"string\"></input></td>\n\t\t\t\t\t\t<input name=\"".toCharArray();
    __oracle_jsp_text[81] = 
    "\" type=\"hidden\" value=\"".toCharArray();
    __oracle_jsp_text[82] = 
    "\"></input>\n\t\t\t\t\t\t<td align=\"left\" class=\"payloadDataType\">".toCharArray();
    __oracle_jsp_text[83] = 
    "</td><input name=\"".toCharArray();
    __oracle_jsp_text[84] = 
    "\" type=\"hidden\" value=\"string\"></input>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[85] = 
    "\n\t\t\t\t\t\t<tr><th align=\"left\">TP Doc Type Revision<font class=\"payloadAsterick\">&nbsp;*</font></th>\n\t\t\t\t\t\t<td align=\"left\"><input name=\"".toCharArray();
    __oracle_jsp_text[86] = 
    "\" type=\"text\" value=\"".toCharArray();
    __oracle_jsp_text[87] = 
    "\" ".toCharArray();
    __oracle_jsp_text[88] = 
    " dataType=\"string\"></input></td>\n\t\t\t\t\t\t<input name=\"".toCharArray();
    __oracle_jsp_text[89] = 
    "\" type=\"hidden\" value=\"".toCharArray();
    __oracle_jsp_text[90] = 
    "\"></input>\n\t\t\t\t\t\t<td align=\"left\" class=\"payloadDataType\">".toCharArray();
    __oracle_jsp_text[91] = 
    "</td><input name=\"".toCharArray();
    __oracle_jsp_text[92] = 
    "\" type=\"hidden\" value=\"string\"></input>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[93] = 
    "\n\t\t\t\t\t\t</table>\n\t\t\t\t<hr align=\"left\" width=\"80%\"/>\n\t\t\t\t<table cellpadding=\"0\" cellspacing=\"3\">\n\t\t\t\t<tr><td colspan=\"3\" class=\"payloadSectionTitle\" id=\"ns1_cl_ErrorDetails\">Error Details</td></tr>\n\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[94] = 
    "\n\t\t\t\t\t\t<tr><th align=\"left\">Error Code<font class=\"payloadAsterick\">&nbsp;*</font></th>\n\t\t\t\t\t\t<td align=\"left\"><input name=\"".toCharArray();
    __oracle_jsp_text[95] = 
    "\" type=\"text\" value=\"".toCharArray();
    __oracle_jsp_text[96] = 
    "\" ".toCharArray();
    __oracle_jsp_text[97] = 
    " dataType=\"string\"></input></td>\n\t\t\t\t\t\t<input name=\"".toCharArray();
    __oracle_jsp_text[98] = 
    "\" type=\"hidden\" value=\"".toCharArray();
    __oracle_jsp_text[99] = 
    "\"></input>\n\t\t\t\t\t\t<td align=\"left\" class=\"payloadDataType\">".toCharArray();
    __oracle_jsp_text[100] = 
    "</td><input name=\"".toCharArray();
    __oracle_jsp_text[101] = 
    "\" type=\"hidden\" value=\"string\"></input>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[102] = 
    "\n\t\t\t\t\t\t<tr><th align=\"left\">Error Description</th>\n\t\t\t\t\t\t<td align=\"left\"><textarea rows=\"5\" cols=\"150\" name=\"".toCharArray();
    __oracle_jsp_text[103] = 
    "\">".toCharArray();
    __oracle_jsp_text[104] = 
    "</textarea></td>\n\t\t\t\t\t\t<input name=\"".toCharArray();
    __oracle_jsp_text[105] = 
    "\" type=\"hidden\" value=\"".toCharArray();
    __oracle_jsp_text[106] = 
    "\"></input>\n\t\t\t\t\t\t<td align=\"left\" class=\"payloadDataType\">".toCharArray();
    __oracle_jsp_text[107] = 
    "</td><input name=\"".toCharArray();
    __oracle_jsp_text[108] = 
    "\" type=\"hidden\" value=\"string\"></input>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[109] = 
    "\n\t\t\t\t\t\t<tr><th align=\"left\">Error Text</th>\n\t\t\t\t\t\t<td align=\"left\"><input name=\"".toCharArray();
    __oracle_jsp_text[110] = 
    "\" type=\"text\" value=\"".toCharArray();
    __oracle_jsp_text[111] = 
    "\" ".toCharArray();
    __oracle_jsp_text[112] = 
    " dataType=\"string\"></input></td>\n\t\t\t\t\t\t<input name=\"".toCharArray();
    __oracle_jsp_text[113] = 
    "\" type=\"hidden\" value=\"".toCharArray();
    __oracle_jsp_text[114] = 
    "\"></input>\n\t\t\t\t\t\t<td align=\"left\" class=\"payloadDataType\">".toCharArray();
    __oracle_jsp_text[115] = 
    "</td><input name=\"".toCharArray();
    __oracle_jsp_text[116] = 
    "\" type=\"hidden\" value=\"string\"></input>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[117] = 
    "\n\t\t\t\t\t\t<tr><th align=\"left\">Error Type</th>\n\t\t\t\t\t\t<td align=\"left\"><input name=\"".toCharArray();
    __oracle_jsp_text[118] = 
    "\" type=\"text\" value=\"".toCharArray();
    __oracle_jsp_text[119] = 
    "\" ".toCharArray();
    __oracle_jsp_text[120] = 
    " dataType=\"string\"></input></td>\n\t\t\t\t\t\t<input name=\"".toCharArray();
    __oracle_jsp_text[121] = 
    "\" type=\"hidden\" value=\"".toCharArray();
    __oracle_jsp_text[122] = 
    "\"></input>\n\t\t\t\t\t\t<td align=\"left\" class=\"payloadDataType\">".toCharArray();
    __oracle_jsp_text[123] = 
    "</td><input name=\"".toCharArray();
    __oracle_jsp_text[124] = 
    "\" type=\"hidden\" value=\"string\"></input>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[125] = 
    "\n\t\t\t\t\t\t<tr><th align=\"left\">Error Severity<font class=\"payloadAsterick\">&nbsp;*</font></th>\n\t\t\t\t\t\t<td align=\"left\"><input name=\"".toCharArray();
    __oracle_jsp_text[126] = 
    "\" type=\"text\" value=\"".toCharArray();
    __oracle_jsp_text[127] = 
    "\" ".toCharArray();
    __oracle_jsp_text[128] = 
    " dataType=\"string\"></input></td>\n\t\t\t\t\t\t<input name=\"".toCharArray();
    __oracle_jsp_text[129] = 
    "\" type=\"hidden\" value=\"".toCharArray();
    __oracle_jsp_text[130] = 
    "\"></input>\n\t\t\t\t\t\t<td align=\"left\" class=\"payloadDataType\">".toCharArray();
    __oracle_jsp_text[131] = 
    "</td><input name=\"".toCharArray();
    __oracle_jsp_text[132] = 
    "\" type=\"hidden\" value=\"string\"></input>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[133] = 
    "\n\t\t\t\t\t\t<tr><th align=\"left\">Error Date Time<font class=\"payloadAsterick\">&nbsp;*</font></th>\n\t\t\t\t\t\t<td align=\"left\"><input name=\"".toCharArray();
    __oracle_jsp_text[134] = 
    "\" type=\"text\" value=\"".toCharArray();
    __oracle_jsp_text[135] = 
    "\" ".toCharArray();
    __oracle_jsp_text[136] = 
    " dataType=\"string\"></input></td>\n\t\t\t\t\t\t<input name=\"".toCharArray();
    __oracle_jsp_text[137] = 
    "\" type=\"hidden\" value=\"".toCharArray();
    __oracle_jsp_text[138] = 
    "\"></input>\n\t\t\t\t\t\t<td align=\"left\" class=\"payloadDataType\">".toCharArray();
    __oracle_jsp_text[139] = 
    "</td><input name=\"".toCharArray();
    __oracle_jsp_text[140] = 
    "\" type=\"hidden\" value=\"string\"></input>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[141] = 
    "\n\t\t\t\t\t\t</table>\n\t\t\t\t<hr align=\"left\" width=\"80%\"/>\n\t\t\t\t<table cellpadding=\"0\" cellspacing=\"3\">\n\t\t\t\t<tr><td colspan=\"3\" class=\"payloadSectionTitle\" id=\"ns1_cl_MessageDetails\">Message Details</td></tr>\n\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[142] = 
    "\n\t\t\t\t\t\t<tr><th align=\"left\">Message Id<font class=\"payloadAsterick\">&nbsp;*</font></th>\n\t\t\t\t\t\t<td align=\"left\"><input name=\"".toCharArray();
    __oracle_jsp_text[143] = 
    "\" type=\"text\" value=\"".toCharArray();
    __oracle_jsp_text[144] = 
    "\" ".toCharArray();
    __oracle_jsp_text[145] = 
    " dataType=\"string\"></input></td>\n\t\t\t\t\t\t<input name=\"".toCharArray();
    __oracle_jsp_text[146] = 
    "\" type=\"hidden\" value=\"".toCharArray();
    __oracle_jsp_text[147] = 
    "\"></input>\n\t\t\t\t\t\t<td align=\"left\" class=\"payloadDataType\">".toCharArray();
    __oracle_jsp_text[148] = 
    "</td><input name=\"".toCharArray();
    __oracle_jsp_text[149] = 
    "\" type=\"hidden\" value=\"string\"></input>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[150] = 
    "\n\t\t\t\t\t\t<tr><th align=\"left\">Message Date Time</th>\n\t\t\t\t\t\t<td align=\"left\"><input name=\"".toCharArray();
    __oracle_jsp_text[151] = 
    "\" type=\"text\" value=\"".toCharArray();
    __oracle_jsp_text[152] = 
    "\" ".toCharArray();
    __oracle_jsp_text[153] = 
    " dataType=\"string\"></input></td>\n\t\t\t\t\t\t<input name=\"".toCharArray();
    __oracle_jsp_text[154] = 
    "\" type=\"hidden\" value=\"".toCharArray();
    __oracle_jsp_text[155] = 
    "\"></input>\n\t\t\t\t\t\t<td align=\"left\" class=\"payloadDataType\">".toCharArray();
    __oracle_jsp_text[156] = 
    "</td><input name=\"".toCharArray();
    __oracle_jsp_text[157] = 
    "\" type=\"hidden\" value=\"string\"></input>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[158] = 
    "\n\t\t\t\t\t\t<tr><th align=\"left\">Message Type</th>\n\t\t\t\t\t\t<td align=\"left\"><input name=\"".toCharArray();
    __oracle_jsp_text[159] = 
    "\" type=\"text\" value=\"".toCharArray();
    __oracle_jsp_text[160] = 
    "\" ".toCharArray();
    __oracle_jsp_text[161] = 
    " dataType=\"string\"></input></td>\n\t\t\t\t\t\t<input name=\"".toCharArray();
    __oracle_jsp_text[162] = 
    "\" type=\"hidden\" value=\"".toCharArray();
    __oracle_jsp_text[163] = 
    "\"></input>\n\t\t\t\t\t\t<td align=\"left\" class=\"payloadDataType\">".toCharArray();
    __oracle_jsp_text[164] = 
    "</td><input name=\"".toCharArray();
    __oracle_jsp_text[165] = 
    "\" type=\"hidden\" value=\"string\"></input>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[166] = 
    "\n\t\t\t\t\t\t<tr><th align=\"left\">Message Version</th>\n\t\t\t\t\t\t<td align=\"left\"><input name=\"".toCharArray();
    __oracle_jsp_text[167] = 
    "\" type=\"text\" value=\"".toCharArray();
    __oracle_jsp_text[168] = 
    "\" ".toCharArray();
    __oracle_jsp_text[169] = 
    " dataType=\"string\"></input></td>\n\t\t\t\t\t\t<input name=\"".toCharArray();
    __oracle_jsp_text[170] = 
    "\" type=\"hidden\" value=\"".toCharArray();
    __oracle_jsp_text[171] = 
    "\"></input>\n\t\t\t\t\t\t<td align=\"left\" class=\"payloadDataType\">".toCharArray();
    __oracle_jsp_text[172] = 
    "</td><input name=\"".toCharArray();
    __oracle_jsp_text[173] = 
    "\" type=\"hidden\" value=\"string\"></input>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[174] = 
    "\n\t\t\t\t\t\t<tr><th align=\"left\">Message Operation</th>\n\t\t\t\t\t\t<td align=\"left\"><input name=\"".toCharArray();
    __oracle_jsp_text[175] = 
    "\" type=\"text\" value=\"".toCharArray();
    __oracle_jsp_text[176] = 
    "\" ".toCharArray();
    __oracle_jsp_text[177] = 
    " dataType=\"string\"></input></td>\n\t\t\t\t\t\t<input name=\"".toCharArray();
    __oracle_jsp_text[178] = 
    "\" type=\"hidden\" value=\"".toCharArray();
    __oracle_jsp_text[179] = 
    "\"></input>\n\t\t\t\t\t\t<td align=\"left\" class=\"payloadDataType\">".toCharArray();
    __oracle_jsp_text[180] = 
    "</td><input name=\"".toCharArray();
    __oracle_jsp_text[181] = 
    "\" type=\"hidden\" value=\"string\"></input>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[182] = 
    "\n\t\t\t\t\t\t<tr><th align=\"left\">Message Source System</th>\n\t\t\t\t\t\t<td align=\"left\"><input name=\"".toCharArray();
    __oracle_jsp_text[183] = 
    "\" type=\"text\" value=\"".toCharArray();
    __oracle_jsp_text[184] = 
    "\" ".toCharArray();
    __oracle_jsp_text[185] = 
    " dataType=\"string\"></input></td>\n\t\t\t\t\t\t<input name=\"".toCharArray();
    __oracle_jsp_text[186] = 
    "\" type=\"hidden\" value=\"".toCharArray();
    __oracle_jsp_text[187] = 
    "\"></input>\n\t\t\t\t\t\t<td align=\"left\" class=\"payloadDataType\">".toCharArray();
    __oracle_jsp_text[188] = 
    "</td><input name=\"".toCharArray();
    __oracle_jsp_text[189] = 
    "\" type=\"hidden\" value=\"string\"></input>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[190] = 
    "\n\t\t\t\t\t\t<tr><th align=\"left\">Message Source System Component</th>\n\t\t\t\t\t\t<td align=\"left\"><input name=\"".toCharArray();
    __oracle_jsp_text[191] = 
    "\" type=\"text\" value=\"".toCharArray();
    __oracle_jsp_text[192] = 
    "\" ".toCharArray();
    __oracle_jsp_text[193] = 
    " dataType=\"string\"></input></td>\n\t\t\t\t\t\t<input name=\"".toCharArray();
    __oracle_jsp_text[194] = 
    "\" type=\"hidden\" value=\"".toCharArray();
    __oracle_jsp_text[195] = 
    "\"></input>\n\t\t\t\t\t\t<td align=\"left\" class=\"payloadDataType\">".toCharArray();
    __oracle_jsp_text[196] = 
    "</td><input name=\"".toCharArray();
    __oracle_jsp_text[197] = 
    "\" type=\"hidden\" value=\"string\"></input>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[198] = 
    "\n\t\t\t\t\t\t<tr><th align=\"left\">Message Data</th>\n\t\t\t\t\t\t<td align=\"left\"><textarea rows=\"15\" cols=\"150\" name=\"".toCharArray();
    __oracle_jsp_text[199] = 
    "\">".toCharArray();
    __oracle_jsp_text[200] = 
    "</textarea></td>\n\t\t\t\t\t\t<input name=\"".toCharArray();
    __oracle_jsp_text[201] = 
    "\" type=\"hidden\" value=\"".toCharArray();
    __oracle_jsp_text[202] = 
    "\"></input>\n\t\t\t\t\t\t<td align=\"left\" class=\"payloadDataType\">".toCharArray();
    __oracle_jsp_text[203] = 
    "</td><input name=\"".toCharArray();
    __oracle_jsp_text[204] = 
    "\" type=\"hidden\" value=\"string\"></input>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[205] = 
    "\n\t\t\t\t\t\t</table>\n\t\t\t\t<hr align=\"left\" width=\"80%\"/>\n\t\t\t\t<table cellpadding=\"0\" cellspacing=\"3\">\n\t\t\t\t<tr><td colspan=\"3\" class=\"payloadSectionTitle\" id=\"ns1_cl_ErrorHandlingOptions\">Error Handling Options</td></tr>\n\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[206] = 
    "\n\t\t\t\t\t\t<tr><th align=\"left\">Retire</th>\n\t\t\t\t\t\t<td align=\"left\"><input name=\"".toCharArray();
    __oracle_jsp_text[207] = 
    "\" type=\"text\" value=\"".toCharArray();
    __oracle_jsp_text[208] = 
    "\" ".toCharArray();
    __oracle_jsp_text[209] = 
    " dataType=\"boolean\"></input></td>\n\t\t\t\t\t\t<input name=\"".toCharArray();
    __oracle_jsp_text[210] = 
    "\" type=\"hidden\" value=\"".toCharArray();
    __oracle_jsp_text[211] = 
    "\"></input>\n\t\t\t\t\t\t<td align=\"left\" class=\"payloadDataType\">".toCharArray();
    __oracle_jsp_text[212] = 
    "</td><input name=\"".toCharArray();
    __oracle_jsp_text[213] = 
    "\" type=\"hidden\" value=\"boolean\"></input>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[214] = 
    "\n\t\t\t\t\t\t<tr><th align=\"left\">Task</th>\n\t\t\t\t\t\t<td align=\"left\"><input name=\"".toCharArray();
    __oracle_jsp_text[215] = 
    "\" type=\"text\" value=\"".toCharArray();
    __oracle_jsp_text[216] = 
    "\" ".toCharArray();
    __oracle_jsp_text[217] = 
    " dataType=\"boolean\"></input></td>\n\t\t\t\t\t\t<input name=\"".toCharArray();
    __oracle_jsp_text[218] = 
    "\" type=\"hidden\" value=\"".toCharArray();
    __oracle_jsp_text[219] = 
    "\"></input>\n\t\t\t\t\t\t<td align=\"left\" class=\"payloadDataType\">".toCharArray();
    __oracle_jsp_text[220] = 
    "</td><input name=\"".toCharArray();
    __oracle_jsp_text[221] = 
    "\" type=\"hidden\" value=\"boolean\"></input>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t".toCharArray();
    __oracle_jsp_text[222] = 
    "\n        </table>\n    </form>\n  </div>\n  \n  ".toCharArray();
    __oracle_jsp_text[223] = 
    "\n\n".toCharArray();
    __oracle_jsp_text[224] = 
    "\n".toCharArray();
    }
    catch (Throwable th) {
      System.err.println(th);
    }
}
}
