// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames
// Source File Name:   ODDrillPageCO.java

package od.oracle.apps.xxcrm.bis.pmv.drill.webui;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;
import java.io.IOException;
import java.util.Enumeration;
import java.util.Vector;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.jsp.PageContext;
import oracle.apps.bis.pmv.breadcrumb.BreadCrumb;
import oracle.apps.bis.pmv.breadcrumb.BreadCrumbHelper;
import oracle.apps.bis.pmv.common.PMVConstants;
import od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil;
import od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillFactory;
import od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillImpl;
import oracle.apps.fnd.common.Context;
import oracle.apps.fnd.common.ProfileStore;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.common.WebAppsContext;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.nav.OABreadCrumbsBean;
import oracle.apps.fnd.functionSecurity.Function;
import oracle.apps.fnd.functionSecurity.FunctionSecurity;
import oracle.cabo.ui.ServletRenderingContext;
import oracle.apps.fnd.framework.OAFwkConstants;

public class ODDrillPageCO extends oracle.apps.fnd.framework.webui.OAControllerImpl
{

    public void processRequest(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, oracle.apps.fnd.framework.webui.beans.OAWebBean oawebbean)
    {
        super.processRequest(oapagecontext, oawebbean);
        try
        {
            javax.servlet.http.HttpServletRequest httpservletrequest = (javax.servlet.http.HttpServletRequest)oapagecontext.getRenderingContext().getJspPageContext().getRequest();
            javax.servlet.http.HttpServletResponse httpservletresponse = (javax.servlet.http.HttpServletResponse)oapagecontext.getRenderingContext().getJspPageContext().getResponse();
            oracle.apps.fnd.framework.server.OADBTransaction oadbtransaction = oapagecontext.getApplicationModule(oawebbean).getOADBTransaction();
            oracle.apps.fnd.common.WebAppsContext webappscontext = (oracle.apps.fnd.common.WebAppsContext)((oracle.apps.fnd.framework.server.OADBTransactionImpl)oadbtransaction).getAppsContext();
            java.lang.String s = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getDbc(oapagecontext);
            oapagecontext.getRenderingContext().getJspPageContext().setAttribute("dbc", s);
            if(webappscontext == null)
            {
                java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getDbc(oapagecontext);
                java.lang.String s2 = httpservletrequest.getServerName();
                java.lang.String s3 = (new Integer(httpservletrequest.getServerPort())).toString();
                webappscontext = new WebAppsContext(s2, s3, s1);
            }
            initBreadCrumbs((oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean)oawebbean, oapagecontext, webappscontext);
            invokeDrillPage(oapagecontext, webappscontext, httpservletrequest, httpservletresponse);
            return;
        }
        catch(java.io.IOException _ex)
        {
            return;
        }
    }

    private void initBreadCrumbs(oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean oapagelayoutbean, oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        oracle.apps.fnd.framework.webui.beans.nav.OABreadCrumbsBean oabreadcrumbsbean = (oracle.apps.fnd.framework.webui.beans.nav.OABreadCrumbsBean)oapagelayoutbean.getBreadCrumbsLocator();
        if(oabreadcrumbsbean != null)
            oabreadcrumbsbean.removeAllLinks(oapagecontext);
        javax.servlet.jsp.PageContext pagecontext = oapagecontext.getRenderingContext().getJspPageContext();
        int i = oracle.apps.bis.pmv.breadcrumb.BreadCrumbHelper.getBreadCrumbsSize(pagecontext, webappscontext);
        int ai[] = oracle.apps.bis.pmv.breadcrumb.BreadCrumbHelper.getIndexArray(i);
        com.sun.java.util.collections.HashMap hashmap = oracle.apps.bis.pmv.breadcrumb.BreadCrumbHelper.getBreadCrumbsAtIndeces(pagecontext, webappscontext, ai);
        oracle.apps.fnd.functionSecurity.FunctionSecurity functionsecurity = new FunctionSecurity(webappscontext);
        Object obj = null;
        Object obj1 = null;
        oracle.apps.bis.pmv.breadcrumb.BreadCrumb breadcrumb = null;
        Object obj3 = null;
        Object obj4 = null;
        for(int j = 0; hashmap != null && oabreadcrumbsbean != null && j < ai.length; j++)
        {
            java.lang.Object obj2 = hashmap.get(java.lang.Integer.toString(j));
            if(obj2 != null && (obj2 instanceof oracle.apps.bis.pmv.breadcrumb.BreadCrumb) && functionsecurity != null)
            {
                breadcrumb = (oracle.apps.bis.pmv.breadcrumb.BreadCrumb)obj2;
                oracle.apps.fnd.functionSecurity.Function function = functionsecurity.getFunction(breadcrumb.getFunctionName());
                java.lang.String s;
                java.lang.String s1;
                if(function != null)
                {
                    s = function.getUserFunctionName();
                    s1 = functionsecurity.getRunFunctionURL(function, functionsecurity.getResp(breadcrumb.getRespId(), breadcrumb.getRespAppId()), functionsecurity.getSecurityGroup(breadcrumb.getSecGrpId()), "pMode=BCRUMB");
                } else
                {
                    s = breadcrumb.getUserFunctionName();
                    s1 = breadcrumb.getDestinationUrl();
                }
                if(s != null && s1 != null)
                    oabreadcrumbsbean.addLink(oapagecontext, s, s1);
            }
        }

        _prevBreadCrumb = breadcrumb;
    }

    private void invokeDrillPage(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, oracle.apps.fnd.common.WebAppsContext webappscontext, javax.servlet.http.HttpServletRequest httpservletrequest, javax.servlet.http.HttpServletResponse httpservletresponse)
        throws java.io.IOException
    {
        if(webappscontext == null)
        {
            java.lang.String s = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getDbc(oapagecontext);
            java.lang.String s2 = httpservletrequest.getServerName();
            java.lang.String s3 = (new Integer(httpservletrequest.getServerPort())).toString();
            webappscontext = new WebAppsContext(s2, s3, s);
        }
        java.lang.String s1 = webappscontext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
        httpservletresponse.setContentType("text/html;charset=" + s1);


        try
        {
            java.sql.Connection connection = webappscontext.getJDBCConnection();
            od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillImpl drillimpl = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillFactory.getDrillImplObject(httpservletrequest, oapagecontext.getRenderingContext().getJspPageContext(), webappscontext, connection);
            drillimpl.setPrevBreadCrumb(_prevBreadCrumb);
            if(drillimpl != null)
            {
                drillimpl.process();
                drillimpl.redirect();
                java.lang.String s4 = drillimpl.getRedirectURL();
				oapagecontext.writeDiagnostics("Anirban ODDrillPageCO: ", "Anirban: printing drillimpl.getRedirectURL() value: "+s4,  OAFwkConstants.STATEMENT);
                try
                {
                 /*java.lang.String s21 = null;
                 java.lang.String s91 = webappscontext.getProfileStore().getProfile("APPS_FRAMEWORK_AGENT");
                 java.lang.StringBuffer stringbuffer = new StringBuffer(300);
	             stringbuffer.append(s91);
                 stringbuffer.append("/XXCRM_HTML/bisviewm.jsp?");
                 stringbuffer.append("dbc=").append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getDbc(oapagecontext));      stringbuffer.append("&regionCode=").append("XXBI_REP_POTENTIAL_DTL_RPT&functionName=XXBI_REP_POTENTIAL_DTL_RPT&forceRun=Y&parameterDisplayOnly=N&displayParameters=Y&showSchedule=Y&pFirstTime=0&pMode=DRILL&requestType=R");
                 stringbuffer.append("&pSessionId=").append(oapagecontext.getSessionId()) ;
                 stringbuffer.append(s4);
                 stringbuffer.append("&forceRun=");
                 oapagecontext.sendRedirect(stringbuffer.toString());*/
				 oapagecontext.sendRedirect(s4);
                }
                catch(java.io.IOException _ex) { }
            }
        }
        finally
        {
            webappscontext.releaseJDBCConnection();
        }
    }

    public void processFormRequest(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, oracle.apps.fnd.framework.webui.beans.OAWebBean oawebbean)
    {
        super.processFormRequest(oapagecontext, oawebbean);
    }

    public java.lang.String[] validateParameters(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, java.util.Vector vector)
    {
        java.util.Enumeration enumeration = oapagecontext.getParameterNames();
        com.sun.java.util.collections.ArrayList arraylist = new ArrayList(5);
        if(enumeration != null)
            for(; enumeration.hasMoreElements(); arraylist.add(enumeration.nextElement()));
        java.lang.String as[] = new java.lang.String[arraylist.size()];
        as = (java.lang.String[])arraylist.toArray(as);
        return as;
    }

    public ODDrillPageCO()
    {
    }

    public static final java.lang.String RCS_ID = "$Header: ODDrillPageCO.java 115.8 2006/03/29 03:03 ugodavar noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: ODDrillPageCO.java 115.8 2006/03/29 03:03 ugodavar noship $", "%packagename%");
    private oracle.apps.bis.pmv.breadcrumb.BreadCrumb _prevBreadCrumb;

}
