// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames
// Source File Name:   ODBISReportCO.java

package od.oracle.apps.xxcrm.bis.report.webui;
import oracle.apps.fnd.framework.OAFwkConstants;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.Vector;
import java.util.Enumeration;
import od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil;
import oracle.apps.bis.pmv.common.StringUtil;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAUrl;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import java.sql.*;

public class ODBISReportCO extends oracle.apps.fnd.framework.webui.OAControllerImpl
{

    public void processRequest(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, oracle.apps.fnd.framework.webui.beans.OAWebBean oawebbean)
    {
        super.processRequest(oapagecontext, oawebbean);
        OAApplicationModule am = oapagecontext.getApplicationModule(oawebbean);
         OAApplicationModuleImpl am1 =(OAApplicationModuleImpl )oapagecontext.getApplicationModule(oawebbean);

        java.lang.String s = oapagecontext.getParameter("pScheduleId");
        java.lang.String s1 = oapagecontext.getParameter("pResponsibilityId");
        java.lang.String s2 = null;
        Object obj = null;
        Object obj1 = null;
        String dbcName = null;
        dbcName = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getDbc(oapagecontext);
        if("".equals(dbcName))
        	dbcName = am.getDbc();

        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
        {
            s2 = oapagecontext.getSessionId();
            java.lang.String s3 = java.lang.String.valueOf(oapagecontext.getUserId());
            java.lang.String s5;
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
                s5 = s1;
            else
                s5 = java.lang.String.valueOf(oapagecontext.getResponsibilityId());
        } else
        {
            s2 = oapagecontext.getParameter("pSessionId");
            java.lang.String s4 = oapagecontext.getParameter("pUserId");
            java.lang.String s6 = s1;
        }
        oapagecontext.getResponsibilityApplicationId();
        java.lang.StringBuffer stringbuffer = new StringBuffer(300);

        oapagecontext.writeDiagnostics("Anirban ODBISReportCO: ", "Anirban: printing smjSelectedTab value: "+oapagecontext.getParameter("smjSelectedTab"),  OAFwkConstants.STATEMENT);

		String pFunctionName = oapagecontext.getParameter("pFunctionName");
             String pRespId =    oapagecontext.getResponsibilityId()+"";
		String smjSelectedTab = "";
		String crmapp = "N";
		

 oracle.apps.fnd.framework.OAViewObject oaviewobject2 = 
            (oracle.apps.fnd.framework.OAViewObject)am.findViewObject("DBMenuVO");
        java.lang.StringBuffer stringbuffer2 = new StringBuffer(1000);
        stringbuffer2.append("  select m.dashboard_menu ");
       stringbuffer2.append("  Code");
        stringbuffer2.append(" FROM fnd_compiled_menu_functions mf,fnd_form_functions_vl f  ");
	stringbuffer2.append(" ,fnd_menu_entries_vl me ,XXBI_REP_MGR_RESP_MAPPINGS m,fnd_responsibility_vl r ");
	stringbuffer2.append(" WHERE me.menu_id = (SELECT menu_id FROM fnd_menus_vl WHERE menu_name=m.reports_menu)  ");
	stringbuffer2.append(" AND mf.function_id = f.function_id AND me.menu_id = mf.menu_id  ");
        stringbuffer2.append(" AND me.function_id = mf.function_id  ");
        stringbuffer2.append(" AND me.function_id = f.function_id  ");
        stringbuffer2.append(" AND f.function_name = :1 ");
        stringbuffer2.append(" AND r.responsibility_id = :2 "  );
        stringbuffer2.append(" AND m.resp_key =r.responsibility_key "); 
        //            System.out.println(stringbuffer2);
        oracle.apps.fnd.framework.server.OAViewDefImpl oaviewdefimpl = 
            (oracle.apps.fnd.framework.server.OAViewDefImpl)am.getOADBTransaction().createViewDef();
        oaviewdefimpl.setSql(stringbuffer2.toString());
        oaviewdefimpl.setExpertMode(true);
        oaviewdefimpl.setFullName("od.oracle.apps.xxcrm.scs.fdk.server.DBMenuVO" );
        oaviewdefimpl.addSqlDerivedAttrDef("Code", "Code", 
                                            "java.lang.String", 12, false, 
                                           false, (byte)0, 200);
                                          
        if (oaviewobject2 != null) {
            oaviewobject2.remove();
        }
        oaviewobject2 = 
                (oracle.apps.fnd.framework.OAViewObject)am1.createViewObject("DBMenuVO", 
                                                                              (oracle.apps.fnd.framework.server.OAViewDef)oaviewdefimpl);
        oaviewobject2.setPassivationEnabled(false);

        ((oracle.apps.fnd.framework.server.OAViewObjectImpl)oaviewobject2).setFetchSize((short)50);

        if (!oaviewobject2.isPreparedForExecution()) {
            oaviewobject2.setWhereClauseParams(null); // Always reset
            oaviewobject2.setWhereClauseParam(0, pFunctionName);
            oaviewobject2.setWhereClauseParam(1, pRespId);
            oaviewobject2.executeQuery();
        }
	    
            smjSelectedTab =oaviewobject2.getAllRowsInRange().length +"";
          if(oaviewobject2.getFetchedRowCount()>0)
          {
           String cd=oaviewobject2.getRowAtRangeIndex(0).getAttribute("Code")+"";
            String tab=  oapagecontext.getParameter(cd);
		smjSelectedTab = "subTabId"+tab;  
           crmapp = "Y";
          }

	/*	if (("XXBI_MGR_TASKS_DTL_RPT".equals(pFunctionName))||("XXBI_MGR_TASKS_SUM_RPT".equals(pFunctionName))||("XXBI_REP_TASKS_DTL_RPT".equals(pFunctionName))||("XXBI_REP_TASKS_SUM_RPT".equals(pFunctionName)))
		{
         smjSelectedTab = "subTabId2";
	crmapp = "Y";
		}

		if (("XXBI_MGR_ACTIVITIES_DTL_RPT".equals(pFunctionName))||("XXBI_MGR_ACTIVITIES_SUM_RPT".equals(pFunctionName))||("XXBI_REP_ACTIVITIES_DTL_RPT".equals(pFunctionName))||("XXBI_REP_ACTIVITIES_SUM_RPT".equals(pFunctionName)))
		{
         smjSelectedTab = "subTabId3";
	crmapp = "Y";
		}

		if (("XXBI_MGR_PS_DTL_RPT".equals(pFunctionName))||("XXBI_MGR_PS_DTL_RPT".equals(pFunctionName))||("XXBI_MGR_PS_SUM_RPT".equals(pFunctionName))||("XXBI_REP_PS_DTL_RPT".equals(pFunctionName)))
		{
         smjSelectedTab = "subTabId0";
crmapp = "Y";
		}

		if (("XXBI_LEAD_RPRT_DTL_MGR".equals(pFunctionName))||("XXBI_LEAD_RPRT_DTL_REP".equals(pFunctionName))||("XXBI_LEAD_RPRT_SMRY_MGR".equals(pFunctionName))||("XXBI_LEAD_RPRT_SMRY_REP".equals(pFunctionName)))
		{
         smjSelectedTab = "subTabId4";
crmapp = "Y";
		}

		if (("XXBI_OPPTY_RPRT_DTL_MGR".equals(pFunctionName))||("XXBI_OPPTY_RPRT_DTL_REP".equals(pFunctionName))||("XXBI_OPPTY_RPRT_SMRY_MGR".equals(pFunctionName))||("XXBI_OPPTY_RPRT_SMRY_REP".equals(pFunctionName)))
		{
         smjSelectedTab = "subTabId5";
crmapp = "Y";
		}

		if ("XXBI_SHORTCUTS_PAGE".equals(pFunctionName))
		{
         smjSelectedTab = "subTabId8";
crmapp = "Y";
		}

		if ("XXBI_ATTAIN_PAGE".equals(pFunctionName))
		{
         smjSelectedTab = "subTabId9";
crmapp = "Y";
		}
*/
if (crmapp.equals("Y"))
{
        stringbuffer.append("../XXCRM_HTML/bisviewm.jsp?");
        stringbuffer.append("dbc=").append(dbcName);


		stringbuffer.append("&").append("smjSelectedTab").append("=").append(smjSelectedTab);
}
else
{
   stringbuffer.append("../OA_HTML/bisviewm.jsp?");
        stringbuffer.append("dbc=").append(dbcName);

}

        stringbuffer.append("&transactionid=").append(oapagecontext.getTransactionId());
        stringbuffer.append("&regionCode=").append(oracle.apps.fnd.framework.webui.OAUrl.encode(oapagecontext, oapagecontext.getParameter("pRegionCode")));
        stringbuffer.append("&functionName=").append(oracle.apps.fnd.framework.webui.OAUrl.encode(oapagecontext, oapagecontext.getParameter("pFunctionName")));
        stringbuffer.append("&forceRun=");
        if(oapagecontext.getParameter("pForceRun") != null)
            stringbuffer.append(oapagecontext.getParameter("pForceRun"));
        else
            stringbuffer.append("N");
        stringbuffer.append("&parameterDisplayOnly=");
        if(oapagecontext.getParameter("pParameterDisplayOnly") != null)
            stringbuffer.append(oapagecontext.getParameter("pParameterDisplayOnly"));
        else
            stringbuffer.append("N");
        stringbuffer.append("&displayParameters=");
        if(oapagecontext.getParameter("pDisplayParameters") != null)
            stringbuffer.append(oapagecontext.getParameter("pDisplayParameters"));
        else
            stringbuffer.append("Y");
        stringbuffer.append("&showSchedule=");
        if(oapagecontext.getParameter("pReportSchedule") != null)
            stringbuffer.append(oapagecontext.getParameter("pReportSchedule"));
        else
            stringbuffer.append("Y");
        stringbuffer.append("&pFirstTime=");
        if(oapagecontext.getParameter("pFirstTime") != null)
            stringbuffer.append(oapagecontext.getParameter("pFirstTime"));
        else
            stringbuffer.append("1");
        stringbuffer.append("&pMode=");
        if(oapagecontext.getParameter("pMode") != null)
            stringbuffer.append(oapagecontext.getParameter("pMode"));
        else
            stringbuffer.append("SHOW");
        if(oapagecontext.getParameter("pScheduleId") != null)
            stringbuffer.append("&scheduleId=").append(oapagecontext.getParameter("pScheduleId"));
        stringbuffer.append("&requestType=");
        if(oapagecontext.getParameter("pRequestType") != null)
            stringbuffer.append(oapagecontext.getParameter("pRequestType"));
        else
            stringbuffer.append("R");
        if(oapagecontext.getParameter("pFileId") != null)
            stringbuffer.append("&fileId=").append(oapagecontext.getParameter("pFileId"));
        if(oapagecontext.getParameter("pResponsibilityId") != null)
            stringbuffer.append("&pResponsibilityId=").append(oapagecontext.getParameter("pResponsibilityId"));
        if(oapagecontext.getParameter("pUserId") != null)
            stringbuffer.append("&pUserId=").append(oapagecontext.getParameter("pUserId"));
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s2))
            stringbuffer.append("&pSessionId=").append(s2);
        if(oapagecontext.getParameter("pApplicationId") != null)
            stringbuffer.append("&pApplicationId=").append(oapagecontext.getParameter("pApplicationId"));
        if(oapagecontext.getParameter("pPreFunctionName") != null)
            stringbuffer.append("&pPreFunctionName=").append(oracle.apps.fnd.framework.webui.OAUrl.encode(oapagecontext, oapagecontext.getParameter("pPreFunctionName")));
        if(oapagecontext.getParameter("pCSVFileName") != null)
            stringbuffer.append("&pCSVFileName=").append(oracle.apps.fnd.framework.webui.OAUrl.encode(oapagecontext, oapagecontext.getParameter("pCSVFileName")));
        if(oapagecontext.getParameter("pPageId") != null)
            stringbuffer.append("&_pageid=").append(oapagecontext.getParameter("pPageId"));
        if(oapagecontext.getParameter("pObjectType") != null)
            stringbuffer.append("&pObjectType=").append(oapagecontext.getParameter("pObjectType"));
        if(oapagecontext.getParameter("displayOnlyParameters") != null)
            stringbuffer.append("&displayOnlyParameters=").append(oracle.apps.fnd.framework.webui.OAUrl.encode(oapagecontext, oapagecontext.getParameter("displayOnlyParameters")));
        if(oapagecontext.getParameter("displayOnlyNoViewByParams") != null)
            stringbuffer.append("&displayOnlyNoViewByParams=").append(oracle.apps.fnd.framework.webui.OAUrl.encode(oapagecontext, oapagecontext.getParameter("displayOnlyNoViewByParams")));
        if(oapagecontext.getParameter("pParameters") != null)
            stringbuffer.append("&pParameters=").append(oracle.apps.fnd.framework.webui.OAUrl.encode(oapagecontext, oapagecontext.getParameter("pParameters")));
        if(oapagecontext.getParameter("pEnableForecastGraph") != null)
            stringbuffer.append("&pEnableForecastGraph=").append(oapagecontext.getParameter("pEnableForecastGraph"));
        if(oapagecontext.getParameter("pCustomView") != null)
            stringbuffer.append("&pCustomView=").append(oracle.apps.fnd.framework.webui.OAUrl.encode(oapagecontext, oapagecontext.getParameter("pCustomView")));
        if(oapagecontext.getParameter("pAutoRefresh") != null)
            stringbuffer.append("&autoRefresh=").append(oracle.apps.fnd.framework.webui.OAUrl.encode(oapagecontext, oapagecontext.getParameter("pAutoRefresh")));
        if(oapagecontext.getParameter("pDispRun") != null)
            stringbuffer.append("&pDispRun=").append(oapagecontext.getParameter("pDispRun"));
        if(oapagecontext.getParameter("pDispRun") != null)
            stringbuffer.append("&pDispRun=").append(oapagecontext.getParameter("pDispRun"));
        if(oapagecontext.getParameter("pMaxResultSetSize") != null)
            stringbuffer.append("&pMaxResultSetSize=").append(oapagecontext.getParameter("pMaxResultSetSize"));
        if(oapagecontext.getParameter("pOutputFormat") != null)
            stringbuffer.append("&pOutputFormat=").append(oapagecontext.getParameter("pOutputFormat"));
        if(oapagecontext.getParameter("hideNav") != null)
            stringbuffer.append("&hideNav=").append(oapagecontext.getParameter("hideNav"));
        if(oapagecontext.getParameter("tab") != null)
            stringbuffer.append("&tab=").append(oapagecontext.getParameter("tab"));
        if(oapagecontext.getParameter("pBCFromFunctionName") != null)
            stringbuffer.append("&pBCFromFunctionName=").append(oracle.apps.fnd.framework.webui.OAUrl.encode(oapagecontext, oapagecontext.getParameter("pBCFromFunctionName")));
        if(oapagecontext.getParameter("pPrevBCInfo") != null)
            stringbuffer.append("&pPrevBCInfo=").append(oracle.apps.fnd.framework.webui.OAUrl.encode(oapagecontext, oapagecontext.getParameter("pPrevBCInfo")));
        if("Y".equals(oapagecontext.getParameter("pResetView")))
            stringbuffer.append("&pResetView=Y");
        if(oapagecontext.getParameter("pDrillDefaultParameters") != null)
            stringbuffer.append(oapagecontext.getParameter("pDrillDefaultParameters"));
        try
        {
            oapagecontext.sendRedirect(stringbuffer.toString());
            return;
        }
        catch(java.lang.Exception _ex)
        {
            return;
        }
    }

    public void processFormRequest(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, oracle.apps.fnd.framework.webui.beans.OAWebBean oawebbean)
    {
        super.processFormRequest(oapagecontext, oawebbean);
    }

    public java.lang.String[] validateParameters(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, com.sun.java.util.collections.Vector vector)
    {
        java.util.Enumeration enumeration = oapagecontext.getParameterNames();
        com.sun.java.util.collections.ArrayList arraylist = new ArrayList(5);
        if(enumeration != null)
            for(; enumeration.hasMoreElements(); arraylist.add(enumeration.nextElement()));
        java.lang.String as[] = new java.lang.String[arraylist.size()];
        as = (java.lang.String[])arraylist.toArray(as);
        return as;
    }

    public ODBISReportCO()
    {
    }

    public static final java.lang.String RCS_ID = "$Header: ODBISReportCO.java 115.9 2007/04/20 12:43:46 sjustina noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: ODBISReportCO.java 115.9 2007/04/20 12:43:46 sjustina noship $", "od.oracle.apps.xxcrm.bis.report.webui");

}
