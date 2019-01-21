 <%! public static final String RCS_ID = "$Header: odbisquicklinks.jsp 115.208 2007/04/16 10:02:35 sjustina noship $"; %>
 <%!
 /**
  +===========================================================================+
  |      Copyright (c) 2002 Oracle Corporation, Redwood Shores, CA, USA       |
  |                         All rights reserved.                              |
  +===========================================================================+
  |  FILENAME                                                                 |
  |      odbisquicklinks.jsp                                                  |
  |                                                                           |
  |  DESCRIPTION                                                              |
  |            Main jsp to render OD Shortcuts	                              |
  |                                                                           |
  |  HISTORY                                                                  |
  |   Date          Developer     Description                                 |
  |   8-3-2010     sjustina       Initial Draft Version                       |
  +===========================================================================+
  **/
  %><%@
   page  import="oracle.apps.fnd.common.*"
   import="java.sql.*"
  import="od.oracle.apps.xxcrm.bis.pmv.report.ODAttainmentBean"
   import="oracle.apps.bis.pmv.parameters.*"
   import="oracle.apps.bis.pmv.common.*"
   import="oracle.apps.bis.pmv.session.*"
   import="oracle.apps.bis.pmv.report.*"
   import="oracle.apps.bis.pmv.metadata.*"
   import="oracle.apps.bis.pmv.*"
   import="oracle.apps.bis.pmv.metadata.AKRegion"
   import="java.util.Hashtable"
   import="java.util.Vector"
   import="com.sun.java.util.collections.HashMap"
   import="oracle.apps.bis.msg.MessageLog"
   import="oracle.apps.bis.database.JDBCUtil"
   import="oracle.apps.fnd.functionSecurity.*"
   import="oracle.apps.bis.pmv.lov.LovHelper"
   import="javax.servlet.ServletContext"
   import = "oracle.apps.fnd.framework.webui.OAJSPHelper"
   import = "oracle.apps.fnd.framework.webui.URLMgr"
   import = "oracle.apps.fnd.security.HMAC"
   import = "oracle.apps.bis.pmv.portlet.Portlet"
   import = "oracle.apps.bis.common.ServletWrapper"
   import = "oracle.apps.bis.parameters.DefaultParameters"
   import = "oracle.cabo.share.url.EncoderUtils"
   import = "oracle.apps.fnd.framework.server.OADBTransaction"
   import = "oracle.apps.bis.webadi.metadata.WebADIMetadata"
   import = "oracle.apps.bis.webadi.metadata.WebADIAdapter"
    import = "od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil"
   import = "com.sun.java.util.collections.Map"
   import = "com.sun.java.util.collections.HashMap"
   import = "javax.servlet.http.HttpSession"
   import = "com.sun.java.util.collections.ArrayList"
   import = "od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil"
   import = "od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil"
 %><%
   UserSession userSession = null;
   WebAppsContext webAppsContext = null;
   MessageLog PmvMsgLog = null;
   int logLevel = Integer.MAX_VALUE;
   try
   {
     userSession = new UserSession(pageContext);
     pageContext.setAttribute("oracle.apps.bis.pmv.session.UserSession", userSession);
     AKRegion akRegionObj = userSession.getAKRegion();
     webAppsContext = userSession.getWebAppsContext();
     Connection conn = userSession.getConnection();
     PmvMsgLog = userSession.getPmvMsgLog();
     if (PmvMsgLog != null)
       logLevel = PmvMsgLog.getLevel();
     boolean isEmail = userSession.isEmail();
       //ashgarg Bug Fix : 4185409
     boolean isEmailContent = userSession.isEmailContent();
     boolean isLovReport = userSession.isLovReport();
     String regionCode = userSession.getRegionCode();
     String functionName = userSession.getFunctionName();
     String pSubmit = userSession.getSubmitMode();
     String pMode = userSession.getReportMode();
     boolean refreshParameters = "Y".equals(request.getParameter("refreshParameters"))?true:false;
     //ugodavar - Enh.3946492
     int pMaxResultSetSize = userSession.getMaxResultSetSize();
     String pOutputFormat = request.getParameter("pOutputFormat");
     String fromExport = request.getParameter("fromExport");
     String designer = request.getParameter("designer"); //Enh.3986441
     // udua - Report Preview DBIMU Enhancement - 3823882
     String designerPreview = request.getParameter("designerPreview");
     //ashgarg Bug Fix:  5471847
     String txnid = request.getParameter("transactionid");
     if(StringUtil.emptyString(txnid))
     {
       try{
         int transactionId = webAppsContext.createTransaction(Integer.parseInt(webAppsContext.getSessionId()));
         txnid = String.valueOf(transactionId);
         userSession.setTransactionId(txnid);
       }catch(Exception e)
        {/*e.printStackTrace();*/}
     }

     if("Y".equals(designerPreview))
     {
       designer =  "N";
       // udua - BugFix 4517507 - Moved BscSQL and prototype rows logic to UserSession
       // because we'd like to keep bisviewm as lean as possible (so as to follow MVC Architecture).
       userSession.initReportDesignerPreview();
     }
     if(!StringUtil.emptyString(pOutputFormat))
     {
       fromExport = "EXPORT_TO_" + pOutputFormat.toUpperCase();
     }

     HMAC hmac = null;
     //ashgarg Bug Fix:3823820
     //ksadagop Bug Fix:3862069
     try {
        byte[] mackey= webAppsContext.getMacKey();
        hmac = new HMAC(HMAC.HMAC_MD5);
        hmac.setKey(mackey);
     }
     catch(Exception ee) {
       if (PmvMsgLog != null && logLevel == MessageLog.ERROR) {
         PmvMsgLog.logMessage(PMVConstants.PRG_INIT_PMV_SETUP, ee.getMessage(), logLevel);
       }
     }
     //ksadagop Enh.4240831 - SaveAs Feature
     if("1".equals(ServletWrapper.getParameter(request, "pFirstTime")) && userSession.isShowMode()
     && !("Y".equals(request.getParameter("fromPersonalize")))
     && userSession.isUserCustomization() && !userSession.getAKRegion().isEDW() && userSession.isViewExists())
     {
       String paramBookMarkUrl = userSession.getParamBookMarkUrl();
       if(!StringUtil.emptyString(paramBookMarkUrl)) {
         response.sendRedirect(EncoderUtils.encodeURL(URLMgr.processOutgoingURL(paramBookMarkUrl,hmac),response.getCharacterEncoding(),true));
         }
     }

     if (userSession.isSONAR()) {
       ODAttainmentBean reportPageBean = new ODAttainmentBean(userSession);
       reportPageBean.renderSchedule(conn);
       return;
     }
     else if (userSession.isFromConc()) {
       String fileId = request.getParameter("fileId");
       String scheduleId = request.getParameter("scheduleId");
       String requestType = request.getParameter("requestType");
       ODAttainmentBean reportPageBean = new ODAttainmentBean();
       reportPageBean.initSession(pageContext);
       reportPageBean.RenderPageBean(scheduleId,requestType,functionName,regionCode,fileId,conn);
       return;
     } else if (userSession.isOpenLovMode()) {
       pageContext.getSession().putValue("PMV_USER_SESSION", userSession);

       PMVParameterForm pmvForm = new PMVParameterForm(userSession);
       pageContext.getSession().putValue("PMV_PARAM_FORM", pmvForm);

       String submitField = request.getParameter("pSubmitField");
       pageContext.getSession().putValue("PMV_SUBMIT_FIELD", submitField);

       String submitMode = request.getParameter("pSubmitMode");
       pageContext.getSession().putValue("PMV_SUBMIT_MODE", submitMode);

       String selectedLevel = pmvForm.getParamSelected();
       if (selectedLevel.endsWith("_FROM"))
         selectedLevel = selectedLevel.substring(0, selectedLevel.lastIndexOf("_FROM"));
       else if (selectedLevel.endsWith("_TO"))
         selectedLevel = selectedLevel.substring(0, selectedLevel.lastIndexOf("_TO"));
       //HRI Delegate
       //pageContext.getSession().putValue("PMV_SELECTED_LEVEL", selectedLevel);
       boolean isIndentedLov = false;
       AKRegionItem selectedItem = (AKRegionItem) akRegionObj.getAKRegionItems().get(selectedLevel);
       String lovFunctionName = selectedItem.getLovFunctionName();
       if (StringUtil.emptyString(lovFunctionName)) {
         DimLevelProperties selectedLevelProperties = selectedItem.getDimLevelProperties();
         //String lovFunctionName = "";
         if (selectedLevelProperties != null){
           lovFunctionName = selectedLevelProperties.getLovFormFunction();
           isIndentedLov = selectedLevelProperties.isParent();
         }
       }
       String accessibility = webAppsContext.getProfileStore().getProfile("ICX_ACCESSIBILITY_FEATURES");
       if (!"N".equals(accessibility) && !StringUtil.emptyString(accessibility))
         isIndentedLov = false;
       String lovURL = LovHelper.getLovUrl(lovFunctionName, webAppsContext, request, isIndentedLov);
       if(!StringUtil.emptyString(lovFunctionName))
       {
         PMVParameters pmvParameters = new PMVParameters(pageContext, userSession);
         pmvParameters.setParameters(selectedLevel);
       }else if(isIndentedLov)
         lovURL = URLMgr.processOutgoingURL(lovURL,hmac);
       response.sendRedirect(lovURL);
       return;
     }
 //vkazhipu added for Enh 4240870
     else if (userSession.isSelectNavigation()) {
       String pageFunc = null;
       String selectURL = request.getParameter("pButtonUrl");
       HashMap idValueMap = (HashMap)ODPMVUtil.getParameters(selectURL);

       if (idValueMap != null) {
         pageFunc = (String)idValueMap.get("pFunctionName");
         String isCheckBoxUsed = (String)idValueMap.get("checkBoxSelection");
         String displayMode = (String)idValueMap.get("pDisplayMode");
         HashMap idArray = ODDrillUtil.getSelectNavigationValues(idValueMap,request,isCheckBoxUsed);
         pageContext.getSession().putValue("selectNavIds",idArray);
         String functionURL;
         //Printable Page Enhancement
         if("PRINT".equals(displayMode) || "EXPORT".equals(displayMode))
           functionURL = ODDrillUtil.getPrintablePageURL(selectURL, idArray, request, userSession);
         else
           functionURL = ODDrillUtil.getRunFunctionURL(pageFunc,null,webAppsContext);
         if (functionURL!= null){
           response.sendRedirect(functionURL);
         }
         return;

      }
     }
     else if (userSession.isDownLoadMode()) {
       String scheduleId = request.getParameter("pScheduleId");
       String fileId = request.getParameter("pFileId");
       ODAttainmentBean reportPageBean = new ODAttainmentBean();
       reportPageBean.initSession(pageContext);
       reportPageBean.download(scheduleId, fileId, functionName,
                               regionCode, conn, webAppsContext, userSession);
       return;
     } else if(userSession.isPersonalizeMode()) {
       ODAttainmentBean reportPageBean = new ODAttainmentBean(userSession);
       reportPageBean.invokePersonalizePage();
       return;
     } else if(userSession.isPersonalizeParametersMode()) { // nbarik - 12/13/05 - Enhancement 4240842 - Parameter Personalization
       ODAttainmentBean reportPageBean = new ODAttainmentBean(userSession);
       reportPageBean.invokePersonalizeParametersPage();
       return;
     } else if("PERSONALIZEVIEW".equals(pSubmit)) {
       ODAttainmentBean reportPageBean = new ODAttainmentBean(userSession);
       reportPageBean.invokePersonalizeViewPage();
       return;
     }	else if (userSession.isSavePageParamMode()) {
       RequestInfo requestInfo = new RequestInfo();
       String pageId = ODPMVUtil.getPageId(request.getParameter("_pageid"), webAppsContext);//Bug Fix2953393
       requestInfo.setPageId(pageId);
       requestInfo.setMode(pSubmit);
       requestInfo.setRequestType("P");
       userSession.setRequestInfo(requestInfo);
       String userId = request.getParameter("pUserId");
       if (userId != null && userId.length() >0) {
         userSession.setUserId(userId);
       }
       String respId = request.getParameter("pResponsibilityId");
       if (respId != null && respId.length() >0) {
         userSession.setResponsibilityId(respId);
       }
       String pageUrl = request.getParameter("_page_url");
       if (pageUrl == null || pageUrl.length() ==0) {
         GlobalMenu gm = new GlobalMenu();
         pageUrl = gm.getReturnToPortalLink(webAppsContext);
       }
       StringBuffer params = new StringBuffer(200);//Bug.Fix.4141392
       params.append("pFirstTime=0");//ugodavar - avoid resetting of breadCrumbs.
       //bug 4091522
       boolean doesPageIdHaveComma = (pageId != null && pageId.indexOf(",") >0) ;
       //bug 3855946
       boolean isPortalPage = (pageId != null && !doesPageIdHaveComma && Double.parseDouble(pageId) > 0) ;
       if (isPortalPage)
       {
         String paramStr = ODPMVUtil.getParamString(conn,userId, pageId);
         if(!StringUtil.emptyString(paramStr))
         {
           params.append("&");
           params.append(paramStr);
         }
       }
       params.append("&pMode=").append(PMVConstants.BKMARK_MODE);//bug.fix.5141202
       // bookamrk
 	//Enh.3986441 - save the parameters in case of page designer
       if (ODPMVUtil.isParamBookMarked() && !isPortalPage && !"Y".equals(designer)) {
         String urlParamString = PMVParameterForm.getBookMarkParameters(userSession, true);
         //urlParamString = StringUtil.replaceAll(urlParamString, "pmvI=24/03/2006&pmvV=24-Mar-2006", "pmvI=31/12/2002&pmvV=31-Dec-2002");
         //urlParamString = StringUtil.replaceAll(urlParamString, "pmvN=ITEM%2BPOA_COMMODITIES&pmvI=181&pmvV=Hardware%20Computer", "pmvN=ITEM%2BPOA_COMMODITIES&pmvI=%27181%27,%27182%27&pmvV=Hardware%20Computer^^Software%20Computer");

         if (urlParamString != null) params.append(urlParamString);
       } else {
         //parameter redesign
         PMVParameterForm pmvForm = new PMVParameterForm(userSession);
         pmvForm.saveParameters();
         //saveParamBean.saveParameters(webAppsContext, userSession);
       }
       FunctionSecurity sec = new FunctionSecurity(webAppsContext);//Bug.Fix.4141392
       Function func = null;
       if(!StringUtil.emptyString(ODPMVUtil.getUrlParamValue(pageUrl, "function_id")))
       	  func = sec.getFunction(Integer.parseInt( ODPMVUtil.getUrlParamValue(pageUrl, "function_id")));
       String redirectUrl;
       if(func == null || !sec.testFunction(func, sec.getUser(), sec.getResp(), sec.getSecurityGroup()) )
       {
         StringBuffer url = new StringBuffer(200);
         url.append(pageUrl);
         url.append("&").append(params.toString());
         redirectUrl = ODPMVUtil.getOAMacUrl(url.toString(), webAppsContext);
       }else{
         redirectUrl = sec.getRunFunctionURL(func, sec.getResp(), sec.getSecurityGroup(), params.toString());
       }

       //redirectUrl = StringUtil.replaceAll(redirectUrl, "ap6118rt.us.oracle.com:8001", "ap7004jdv.us.oracle.com:9004");

       if(isPortalPage)
         response.sendRedirect(redirectUrl);
       else
         response.sendRedirect(EncoderUtils.encodeURL(redirectUrl, response.getCharacterEncoding(),true));
       return;
     } else  if (userSession.isRunMode()) {
       if ("Y".equals(request.getParameter("pFromPers"))) {
         ODAttainmentBean reportPageBean = new ODAttainmentBean(userSession);
         reportPageBean.invokePersonalizePortletPage();
         return;
       } else {
         RequestInfo requestInfo = new RequestInfo();
         requestInfo.setMode(pSubmit);
         requestInfo.setRequestType(request.getParameter("requestType"));
         userSession.setRequestInfo(requestInfo);
         // serao - to bkmark with params
         // redirect to page with mode = show  so that the url params are considered
         // do this only for non-EDW reports.
         //ksadagop BugFix#3645793
 	//autogen and live parameters
         if (ODPMVUtil.isParamBookMarked() &&
            !akRegionObj.isEDW() &&
            !isLovReport &&
   	   !"Y".equals(designer))
         {
           //saveParamBean.setSaveParamIntoDB(false); // so that the params are not saved twice
           //saveParamBean.saveParameters(webAppsContext, userSession);
           //ppalpart - Commented as this does not give the XXCRM_HTML in the URL
           //StringBuffer paramRedirectUrl = new HttpUtils().getRequestURL(request);
           //ppalpart - Added to get the URL including the XXCRM_HTML and then add the bisviewm.jsp
           //StringBuffer paramRedirectUrl = ServletWrapper.getRequestURL(request);
           StringBuffer paramRedirectUrl = new StringBuffer(1000);
           paramRedirectUrl.append("/XXCRM_HTML/bisviewm.jsp");
           //String urlParamString = saveParamBean.getParamUrlString();
           String urlParamString = PMVParameterForm.getBookMarkParameters(userSession, true);
           if (urlParamString != null) {
             paramRedirectUrl.append("?dbc=").append(request.getParameter("dbc"));
             paramRedirectUrl.append("&transactionid=").append(request.getParameter("transactionid"));
             paramRedirectUrl.append("&regionCode=").append(regionCode);
             paramRedirectUrl.append("&functionName=").append(functionName);
             if(userSession.getXmlReport() != null ) {
               paramRedirectUrl.append("&reportName=").append(userSession.getXmlReport());
             }
             paramRedirectUrl.append("&pFirstTime=0");
             paramRedirectUrl.append(urlParamString);
             paramRedirectUrl.append("&pMode=").append(PMVConstants.BKMARK_MODE); //dbc, txid
             paramRedirectUrl.append("&respId=").append(webAppsContext.getRespId()); //dbc, txid
             paramRedirectUrl.append("&respApplId=").append(webAppsContext.getRespApplId()) ;
             //bug 3798390
             String parameterDisplayOnly = request.getParameter("pParameterDisplayOnly");
             if (parameterDisplayOnly != null && parameterDisplayOnly.length() >0)
               paramRedirectUrl.append("&pParameterDisplayOnly=").append(parameterDisplayOnly);
             String displayParameters = request.getParameter("pDisplayParameters");
             if (displayParameters != null && displayParameters.length() >0)
               paramRedirectUrl.append("&pDisplayParameters=").append(displayParameters);
             String enableForecast = request.getParameter("pEnableForecastGraph");
             if (enableForecast != null && enableForecast.length() >0)
               paramRedirectUrl.append("&pEnableForecastGraph=").append(enableForecast);
             String dispRun = request.getParameter("pDispRun");
             if (dispRun != null && dispRun.length() >0)
               paramRedirectUrl.append("&pDispRun=").append(dispRun);
             String customView = request.getParameter("pCustomView");
             if (customView != null && customView.length() >0)
               paramRedirectUrl.append("&pCustomView=").append(customView);
             String reportType = request.getParameter("pReportType");
             if (reportType != null && reportType.length() >0)
               paramRedirectUrl.append("&pReportType=").append(reportType);
             String csvFileName = request.getParameter("pCSVFileName");
             if (csvFileName != null && csvFileName.length() >0)
               paramRedirectUrl.append("&pCSVFileName=").append(csvFileName);
             if(pMaxResultSetSize > -1)  //ugodavar - Enh.3946492
               paramRedirectUrl.append("&pMaxResultSetSize=").append(pMaxResultSetSize);
             //Enh.3986441
             if("Y".equals(designer))
               paramRedirectUrl.append("&designer=Y");
             // udua - Report Preview DBIMU Enhancement - 3823882
             if("Y".equals(designerPreview)) {
               paramRedirectUrl.append("&designerPreview=Y");
             }
             if (refreshParameters)
               paramRedirectUrl.append("&refreshParameters=Y");
             // nbarik - 02/08/05 - Enhancement 4120795
             if ("Y".equals(request.getParameter(PMVConstants.HIDENAV)))
               paramRedirectUrl.append("&").append(PMVConstants.HIDENAV).append("=Y");
             if ("Y".equals(request.getParameter(PMVConstants.TAB)))
               paramRedirectUrl.append("&").append(PMVConstants.TAB).append("=Y");
             String displayOnlyParameters = request.getParameter("displayOnlyParameters");
             if(!StringUtil.emptyString(displayOnlyParameters))
               paramRedirectUrl.append("&displayOnlyParameters=").append(displayOnlyParameters);
             String drillResetParams = request.getParameter("drillResetParams");
             if(!StringUtil.emptyString(drillResetParams)){
               ServletWrapper.putSessionValue(pageContext, "drillResetParams"+functionName, drillResetParams);
               //paramRedirectUrl.append("&drillResetParams=").append(drillResetParams);
             }
             if(PMVConstants.IS_TABLE_PERSONALIZATION) {
               String persNoOfRows = request.getParameter(PMVConstants.PERS_NO_OF_ROWS);
               if (persNoOfRows != null && persNoOfRows.length() >0)
                 paramRedirectUrl.append("&").append(PMVConstants.PERS_NO_OF_ROWS).append("=").append(persNoOfRows);
             }
             response.sendRedirect(EncoderUtils.encodeURL(paramRedirectUrl.toString(),response.getCharacterEncoding(),true));
             return;
           }
         } else {
           PMVParameterForm pmvForm = new PMVParameterForm(userSession);
           pmvForm.saveParameters();
           //saveParamBean.saveParameters(webAppsContext, userSession);
 	  // autogen
 	  if ("Y".equals(designer))
 	  {
       	    String rUrl = (String) pageContext.getSession().getValue("BIS_PMV_PAGE_URL");
             if(!StringUtil.emptyString(rUrl))
             	// response.sendRedirect(EncoderUtils.encodeURL(rUrl,response.getCharacterEncoding(),true));
             	response.sendRedirect(EncoderUtils.encodeURL(URLMgr.processOutgoingURL(rUrl,hmac),response.getCharacterEncoding(),true));

 	    return ;
 	  }
         }
       }
     } else if (userSession.isEmail()) {
       ODAttainmentBean reportPageBean = new ODAttainmentBean(userSession);
       reportPageBean.invokeEmailPage();
       return;
     } else if (userSession.isDelegationMode()) {
       ODAttainmentBean reportPageBean = new ODAttainmentBean(userSession);
       reportPageBean.invokeDelegationPage();
       return;
     } else if(userSession.isUserPersonalizeMode()) {
       ODAttainmentBean reportPageBean = new ODAttainmentBean(userSession);
       reportPageBean.invokeUserPersonalizePage();
       return;
 	  } else if (userSession.isScheduleMode()
             || userSession.isSaveDefaultParamMode()
             || "CANCELBUTTON".equals(pSubmit))
     {
       if (!"CANCELBUTTON".equals(pSubmit)) {
         //saveParamBean.saveParameters(webAppsContext, userSession);
         PMVParameterForm pmvForm = new PMVParameterForm(userSession);
         if(!userSession.isScheduleMode())
           pmvForm.setSaveToDefault(true);
         pmvForm.saveParameters();
       }
       String redirectUrl = "";
       if (userSession.isScheduleMode()) {
         ODAttainmentBean reportPageBean = new ODAttainmentBean(userSession);
         redirectUrl = reportPageBean.getScheduleURL();
       } else {
         redirectUrl = request.getParameter("pPersReturnUrl");
         if(StringUtil.emptyString(redirectUrl))
           redirectUrl = ODHTMLUtil.getMessageUrl(webAppsContext, userSession, request.getParameter("dbc"));
       }
       if (userSession.isScheduleMode())
         response.sendRedirect(EncoderUtils.encodeURL(redirectUrl,response.getCharacterEncoding(),true));
       else
         response.sendRedirect(EncoderUtils.encodeURL(URLMgr.processOutgoingURL(redirectUrl,hmac),response.getCharacterEncoding(),true));
       return;
     } else if (userSession.isBookMarkMode()) {
       RequestInfo requestInfo = new RequestInfo();
       requestInfo.setMode(pMode);
       requestInfo.setRequestType(request.getParameter("requestType"));
       userSession.setRequestInfo(requestInfo);
       //parameter redesign
       PMVParameterForm pmvForm = new PMVParameterForm(userSession);
       pmvForm.saveParameters();
     } else if (userSession.isShowMode() || userSession.isLivePortletMode() || userSession.isExportMode()) {
 %><jsp:useBean id="saveParamBean" class="oracle.apps.bis.pmv.parameters.ParameterSaveBean" scope="request"/><%
     saveParamBean.init(userSession);
 %><jsp:setProperty name="saveParamBean" property="*"/><%
   if (userSession.isExportMode()) {
         if(!StringUtil.emptyString(pOutputFormat) && !"RELATED".equals(pMode) && !"DRILL".equals(pMode))
         {
            //Enh.3946492 - ugodavar - save the parameters because running for the first time.
           Hashtable paramHashTable = new Hashtable(11);
           String pParameters = userSession.getParameters();
           if (!StringUtil.emptyString(pParameters)){
             paramHashTable = userSession.getParameterHashTable(pParameters, regionCode);
             String saveByIds = ODPMVUtil.getUrlParamValue(pParameters, "pParamIds");
             saveParamBean.setpSaveByIds(saveByIds);
             saveParamBean.saveParameters(paramHashTable, userSession,0);
           }
         }
   	    if (PMVConstants.EXPORT_TO_EXCEL.equals(fromExport)) {
        		// WebADI integration
       		boolean useWebADI = false ;
 		      WebADIAdapter adiAdapter = new WebADIAdapter(functionName, regionCode, webAppsContext) ;
     		  if (adiAdapter != null && adiAdapter.isWebADIMetadataPresent())
     		  	useWebADI = true ;
           if (!useWebADI) // the usual way of handling Excel download
           {
               ExportReportPageBean exportReportPageBean = new ExportReportPageBean(pageContext, webAppsContext,  userSession);
               exportReportPageBean.setExportHeaders();
               exportReportPageBean.setQueryData();
               exportReportPageBean.export(true, true, true);
           }
           else
           {
             ExportADIReportPageBean exportADIReportPageBean = new ExportADIReportPageBean(pageContext, webAppsContext, userSession, adiAdapter) ;
             exportADIReportPageBean.setQueryDataForFirstTime() ;
             exportADIReportPageBean.export(true,true,true) ;
           }
         }else if(PMVConstants.EXPORT_TO_PDF.equals(fromExport)) {
             String templateCode = request.getParameter("templateCode");
             ExportPdfReportPageBean exportPdfReportPageBean = new ExportPdfReportPageBean(pageContext, webAppsContext,  userSession);
             exportPdfReportPageBean.setExportHeaders();
             exportPdfReportPageBean.setQueryDataForFirstTime();
             if(!StringUtil.emptyString(templateCode)) {
               exportPdfReportPageBean.exportForRTF(true, true, true);
               exportPdfReportPageBean.generatePDFForTemplate(templateCode);
             } else {
               exportPdfReportPageBean.export(true, true, true);
               exportPdfReportPageBean.generatePDF();
             }
         }else {
           ODAttainmentBean reportPageBean = new ODAttainmentBean(userSession);
           reportPageBean.invokeExportPage();
           //BugFix#3050837
           //reportPageBean.initSession(pageContext);
           //reportPageBean.invokeExportPage(webAppsContext,userSession);
         }
         return;
     }else  if (userSession.isShowMode()) {
       Hashtable paramHashTable = new Hashtable(11);
       String pParameters = userSession.getParameters();
       if (!StringUtil.emptyString(pParameters)){
         paramHashTable = userSession.getParameterHashTable(pParameters, regionCode);
         String saveByIds = ODPMVUtil.getUrlParamValue(pParameters, "pParamIds");
         saveParamBean.setpSaveByIds(saveByIds);
         saveParamBean.saveParameters(paramHashTable, userSession,0);
       }
       // nbarik - 06/10/04 - Enhancement 3436868
       //ashgarg Bug Fix: 3690658
       else if ("Y".equals(request.getParameter("forceRun")) &&
                !("Y".equals(request.getParameter("fromPersonalize"))))
       {
         //nbarik - 07/12/04 - Bug Fix 3757434
         DefaultParameters defaultParameters = new DefaultParameters("", conn, akRegionObj, webAppsContext);
         paramHashTable = defaultParameters.getDefaultValuesFromPMF();
         userSession.setParameters("");
         userSession.setParamIds(true);
         saveParamBean.setpSaveByIds("Y"); // This will be always Y for PMF default values
         saveParamBean.saveParameters(paramHashTable, userSession, 0);
       }
       if("Y".equals( designer )){//Enh.3986441 - redirect to report designer page
       String redirectUrl = (String) pageContext.getSession().getValue("BIS_PMV_PAGE_URL");//"/XXCRM_HTML/OA.jsp?page=/oracle/apps/bis/page/webui/PageDefinitionPG&designer=Y&addBreadCrumb=N&retainAM=Y&builderKey=BIS_KEY_1001&transactionid=1399646796";
       if(!StringUtil.emptyString(redirectUrl))
         response.sendRedirect(EncoderUtils.encodeURL(URLMgr.processOutgoingURL(redirectUrl,hmac),response.getCharacterEncoding(),true));
        }
     } else if (userSession.isLivePortletMode()) {

       String plugId = request.getParameter("pPlugId");
       String title = request.getParameter("pReportTitle");
       String graphType = request.getParameter("pGraphNumber");
       graphType = (graphType == null)? "": graphType;
       String requestType = request.getParameter("pTrendType");
       String parameterDisplayOnly = request.getParameter("pParameterDisplayOnly");
       String scheduleId = request.getParameter("pScheduleId");
       String fileId = request.getParameter("pFileId");
       fileId = (fileId  == null)? "": fileId;
       String redirectUrl = request.getParameter("pReturnURL");

       /*
       ppatil: if("Y".equals(editParamLinkEnable) part added for ER#4268591
       */
       String editParamLinkEnable = ServletWrapper.getParameter(request, "pEditParamLinkEnable");
       String pageId =  ODPMVUtil.getUrlParamValue(redirectUrl, "_pageid");
       if ("Y".equals(editParamLinkEnable))
       {
         RequestInfo requestInfo = userSession.getRequestInfo();
         requestInfo.setEditParamLinkEnabled(true);
         requestInfo.setMode(pSubmit);
         requestInfo.setRequestType("P");
         userSession.setRequestInfo(requestInfo);

         String userId = request.getParameter("pUserId");
         if (userId != null && userId.length() >0) {
           userSession.setUserId(userId);
         }

         String respId = request.getParameter("pResponsibilityId");
         if (respId != null && respId.length() >0) {
           userSession.setResponsibilityId(respId);
         }

         requestInfo.setPageId(pageId);

         if (redirectUrl == null || redirectUrl.length() ==0) {
           GlobalMenu gm = new GlobalMenu();
           redirectUrl = gm.getReturnToPortalLink(webAppsContext);
         }
         StringBuffer paramRedirectUrl = new StringBuffer(200);
         paramRedirectUrl.append(redirectUrl);
         paramRedirectUrl.append("&pFirstTime=0");
         String [] pmvN =  request.getParameterValues(PMVConstants.PARAM_NAME);
         String [] pmvI =  request.getParameterValues(PMVConstants.PARAM_ID);
         String [] pmvV =  request.getParameterValues(PMVConstants.PARAM_VALUE);
         String [] pmvON =  request.getParameterValues(PMVConstants.PARAM_OPTR_NAME);
         String [] pmvOI =  request.getParameterValues(PMVConstants.PARAM_OPTR_ID);

         PMVParameterForm pmvForm = new PMVParameterForm(userSession, null, pmvN, pmvI, pmvV, pmvON, pmvOI);
         pmvForm.saveParameters();
       }
       else
       {
         if(plugId!=null && plugId.length()>0)
           ODPMVUtil.stalePortlet(conn, plugId, PmvMsgLog);

         if (parameterDisplayOnly.equals("N"))
           saveParamBean.saveParameters(userSession, plugId, regionCode, requestType, title, graphType, fileId);
         else
           saveParamBean.savePortletSettings(userSession, plugId, requestType, title, graphType, scheduleId);

         // send redirect here itself....
         //serao -02/07/02- added returnURL for return to start page
         //String redirectUrl = request.getParameter("pReturnURL");
         if (redirectUrl == null || redirectUrl.length() == 0) {
           GlobalMenu gm = new GlobalMenu();
           redirectUrl = gm.getReturnToPortalLink(webAppsContext);
         }
   //ashgarg Bug Fix: 3823820
         //response.sendRedirect(EncoderUtils.encodeURL(redirectUrl,response.getCharacterEncoding(),true));
         //response.sendRedirect(EncoderUtils.encodeURL(URLMgr.processOutgoingURL(redirectUrl.substring(redirectUrl.indexOf("RF"),redirectUrl.length()),hmac),response.getCharacterEncoding(),true));
         //ashgarg Bug Fix: 3871873*/
       }
       //ksadagop BugFix#4932173
       boolean isPortal = ODPMVUtil.isPortal(pageId);
       String Url = redirectUrl;
       if(!isPortal)
         Url = URLMgr.processOutgoingURL(redirectUrl,hmac);

       response.sendRedirect(EncoderUtils.encodeURL(Url,response.getCharacterEncoding(),true));
       return;
     }
   }

   String currLang = webAppsContext.getCurrLangCode();
   String styleSheetNms = ODHTMLUtil.getStyleSheetName(webAppsContext);
   String baseHref = webAppsContext.getProfileStore().getProfile("APPS_FRAMEWORK_AGENT");

 %>
 <%@ include file="jtfincl.jsp" %>
 <HTML LANG="<%=currLang%>">
   <META content="MSHTML 5.00.2614.3401" name=GENERATOR>
   <% if ("Y".equals(request.getParameter("autoRefresh"))) { %>
   <%=ODHTMLUtil.getRefreshTag(webAppsContext) %>
   <%}
   if(isEmailContent){ %>
   <base href="<%= baseHref %>" >
   <% } %>

  <link rel="stylesheet" href="/XXCRM_HTML/bismarli.css?1265687626783" type="text/css">

     <%
       //serao 02/04/02 - include the header only if the mode is none of the known modes which
       // will redirect the page.   see details bug #2208962
       boolean displayHeader = !("SCHEDULE".equals(pSubmit) || "SAVEPARAMETERS".equals(pSubmit) || "APPLYLIVEPORTLET".equals(pSubmit))&& !refreshParameters;
       /* Moved this below
       if (displayHeader) {
         //serao - dynamic include if the header is specified
         if ("PRINTABLE".equals(pSubmit))
            webAppsContext.setSessionAttribute("showHeaderLinks","N");
         else{ //nbarik - 03/24/03 - Bug Fix 2809833 - show the global buttons
            webAppsContext.setSessionAttribute("showHeaderLinks", null);
            //jprabhud - 07/12/04 - Bug 3757082 - Need to remove Navigator link from Report
            webAppsContext.setSessionAttribute("showMenu", "N");
            webAppsContext.setSessionAttribute("showHelp", null);
         }
 }*/
         //Enh.4895041 moved up from below
       ODAttainmentBean reportPageBean = new ODAttainmentBean(userSession);
       String reportHTML = reportPageBean.renderPage();
      if(displayHeader){
       //Moved this here from above
       //serao - dynamic include if the header is specified
         if ("PRINTABLE".equals(pSubmit))
            webAppsContext.setSessionAttribute("showHeaderLinks","N");
         else{ //nbarik - 03/24/03 - Bug Fix 2809833 - show the global buttons
            webAppsContext.setSessionAttribute("showHeaderLinks", null);
            //jprabhud - 07/12/04 - Bug 3757082 - Need to remove Navigator link from Report
           //modified by kalyan showMenu = N is original value
            webAppsContext.setSessionAttribute("showMenu", "N");
            webAppsContext.setSessionAttribute("showHelp", null);
         }
         String header = akRegionObj.getHeader();
         if (header != null) { %>
           <jsp:include page="<%= header %>" flush="true"/>
         <% }
         else if (!isLovReport && (!"Y".equals(request.getParameter(PMVConstants.HIDENAV)) || "Y".equals(request.getParameter(PMVConstants.TAB)))){ %>
            <%@ include file="odbisattainhd.jsp" %>
    <%   } else if (!"Y".equals(request.getParameter(PMVConstants.HIDENAV))){  %>
          <%=HeaderBean.getLovHeaderHtml(webAppsContext, userSession)%>
    <%   }
       } %>


       <body bgcolor="#FFFFFF" link="#663300" vlink="#996633" alink="#FF6600" text="#000000">
       <NOSCRIPT>
       <P>This product requires use of a browser that supports JavaScript
           1.2, and that you run with scripting enabled
        </NOSCRIPT>
        <%
        	String selectedTab = request.getParameter("smjSelectedTab");
        	if((selectedTab == null) || ("".equals(selectedTab)))
        			selectedTab = "subTabId0";
        %>
                <form name="smjForm" method="post">
				 <input type='hidden' name=smjSelectedTab value="<%=selectedTab%>" />
         </form>
    <%
      /* ReportPageBean reportPageBean = new ReportPageBean(userSession);
       out.println(reportPageBean.renderPage());*/
       out.println(reportHTML);//Enh.4895041
       if (refreshParameters)//msaran:4269991 && !akRegionObj.isEDW())
       {
         String paramSection = reportPageBean.getParameterSection();
         paramSection = StringUtil.replaceAll(paramSection, "\n", "&#13;");
         paramSection = StringUtil.replaceAll(paramSection, "'", "&apos;");
         paramSection = StringUtil.replaceAll(paramSection, "<", "&lt;");
         paramSection = StringUtil.replaceAll(paramSection, ">", "&gt;");
   %>
   <script>
     window.parent.refreshParamSection('<%=paramSection%>');
   </script>
   <%
       } else {
       String footer = akRegionObj.getFooter();
       if (footer != null) { %>
         	<jsp:include page="<%= footer %>" flush="true"/>
       <% }
       else if (!isLovReport  && !"Y".equals(request.getParameter(PMVConstants.HIDENAV))){ %>
         <%@ include file="bispmvft.jsp" %>
       <% }
       if(userSession.isGoReport()) { //Bug.Fix.4576358%>
         <iframe title='hiddenIframe' name='hiddenIframe' id='hiddenIframe' width='0' height='0'></iframe>
       <% }
     }
   } catch (PMVException e) {
     String msg = e.getMessage();
     if("BAD_CALENDAR".equals(msg))
       msg = ODPMVUtil.getMessage("BIS_BAD_CALENDAR", webAppsContext);
     if (PmvMsgLog != null && (logLevel == MessageLog.ERROR || logLevel == MessageLog.PERFORMANCE)) {
       if (logLevel == MessageLog.ERROR) {
         PmvMsgLog.logMessage(PMVConstants.PRG_INIT_PMV_SETUP, msg, logLevel);
       }
       //nbarik - 09/01/03 - Bug Fix 3122691 - Set SQL Trace Off
       JDBCUtil.setSqlTrace(userSession.getConnection(), 0);
       try {
         PmvMsgLog.closeProgress(PMVConstants.PRG_INIT_PMV_SETUP);
         PmvMsgLog.closeProgress("TOTAL_TIME_REPORT");
         PmvMsgLog.closeLog();
       } catch (Exception ex) {
         System.err.println(PMVConstants.ERROR_PREFIX + " Exception occured while closing BIA progress/log...." + ex.getMessage());
       }
       //put the object in the session before redirecting it to the error page. this object needs to be put in the
       //session so as to be accessible in bispmver.jsp. -ansingh
       pageContext.getSession().putValue("PmvMsgLog", PmvMsgLog);
       String txnId = request.getParameter("transactionid");
       txnId = (txnId == null) ? "" : txnId;
       pageContext.getSession().putValue("txnId", txnId);
     }
     response.sendRedirect(EncoderUtils.encodeURL(ODPMVUtil.getErrorUrl(userSession, msg, request, pageContext),response.getCharacterEncoding(),true));
   } finally {
     if (webAppsContext != null)
       webAppsContext.freeWebAppsContext();
   } %>
 </BODY>
 </HTML>
