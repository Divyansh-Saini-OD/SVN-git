// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames
// Source File Name:   ODDrillFactory.java

package od.oracle.apps.xxcrm.bis.pmv.drill;


import java.sql.Connection;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.jsp.PageContext;
import oracle.apps.bis.common.ServletWrapper;
import oracle.apps.bis.pmv.common.PMVConstants;
import od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.common.WebAppsContext;
import oracle.apps.fnd.functionSecurity.Function;

// Referenced classes of package od.oracle.apps.xxcrm.bis.pmv.drill:
//            DrillAcrossImpl, DrillDownImpl, DrillFromExtImpl, DrillFromPortletTitleImpl,
//            DrillRelatedImpl, DrillToExtImpl, DrillUtil, ParamMapHandler,
//            DrillImpl

public class ODDrillFactory
{

    public ODDrillFactory()
    {
    }

    private static boolean isPMVFunction(java.lang.String s, oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        oracle.apps.fnd.functionSecurity.Function function = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getFunction(s, webappscontext);
        if(function != null)
        {
            java.lang.String s1 = function.getWebHTMLCall();
            return od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.isPMVReportFunction(s1) || od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.isPMVPageFunction(s1);
        } else
        {
            return false;
        }
    }

    public static od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillImpl getDrillImplObject(javax.servlet.http.HttpServletRequest httpservletrequest, javax.servlet.jsp.PageContext pagecontext, oracle.apps.fnd.common.WebAppsContext webappscontext, java.sql.Connection connection)
    {
        int i = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.getMode(oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pMode"));
        java.lang.String s = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pPreFunction");
        java.lang.Object obj = null;
        switch(i)
        {
        default:
            break;

        case 0: // '\0'
            boolean flag = od.oracle.apps.xxcrm.bis.pmv.drill.ODParamMapHandler.isFuncMapped(s, webappscontext, connection);
            if(flag)
            {
                obj = new ODDrillFromExtImpl(httpservletrequest, pagecontext, webappscontext, connection);
                ((od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillFromExtImpl)obj).setParamMap(((od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillFromExtImpl)obj).getParameters(httpservletrequest));
                break;
            }
            java.lang.String s1 = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pFunction");
            boolean flag1 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillFactory.isPMVFunction(s1, webappscontext);
            boolean flag2 = od.oracle.apps.xxcrm.bis.pmv.drill.ODParamMapHandler.isFuncMapped(s1, webappscontext, connection);
            if(flag2 && !flag1)
                obj = new ODDrillToExtImpl(httpservletrequest, pagecontext, webappscontext, connection, s1);
            else
                obj = new ODDrillRelatedImpl(httpservletrequest, pagecontext, webappscontext, connection);
            break;

        case 1: // '\001'
            java.lang.String s2 = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pUrlString");
            if(s2 != null && s2.startsWith("{!!"))
                s2 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillUtil.OADecrypt(webappscontext, s2);
            java.lang.String s3 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getParameterValue(s2, "pFunctionName");
            boolean flag3 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillFactory.isPMVFunction(s3, webappscontext);
            boolean flag4 = od.oracle.apps.xxcrm.bis.pmv.drill.ODParamMapHandler.isFuncMapped(s3, webappscontext, connection);
            if(flag4 && !flag3)
                obj = new ODDrillToExtImpl(httpservletrequest, pagecontext, webappscontext, connection, s3);
            else
                obj = new ODDrillAcrossImpl(httpservletrequest, pagecontext, webappscontext, connection);
            break;

        case 2: // '\002'
            obj = new ODDrillDownImpl(httpservletrequest, pagecontext, webappscontext, connection);
            break;

        case 3: // '\003'
            boolean flag5 = od.oracle.apps.xxcrm.bis.pmv.drill.ODParamMapHandler.isFuncMapped(s, webappscontext, connection);
            if(flag5)
            {
                obj = new ODDrillFromExtImpl(httpservletrequest, pagecontext, webappscontext, connection);
                ((od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillFromExtImpl)obj).setParamMap(((od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillFromExtImpl)obj).getParameters(httpservletrequest));
            } else
            {
                obj = new ODDrillAcrossImpl(httpservletrequest, pagecontext, webappscontext, connection);
            }
            break;

        case 4: // '\004'
            java.lang.String s4 = oracle.apps.bis.common.ServletWrapper.getParameter(httpservletrequest, "pFunction");
            boolean flag6 = od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillFactory.isPMVFunction(s4, webappscontext);
            boolean flag7 = od.oracle.apps.xxcrm.bis.pmv.drill.ODParamMapHandler.isFuncMapped(s4, webappscontext, connection);
            if(flag7 && !flag6)
                obj = new ODDrillToExtImpl(httpservletrequest, pagecontext, webappscontext, connection, s4);
            else
                obj = new ODDrillRelatedImpl(httpservletrequest, pagecontext, webappscontext, connection);
            break;

        case 5: // '\005'
        case 6: // '\006'
            obj = new ODDrillRelatedImpl(httpservletrequest, pagecontext, webappscontext, connection);
            break;

        case 7: // '\007'
        case 8: // '\b'
            obj = new ODDrillFromPortletTitleImpl(httpservletrequest, pagecontext, webappscontext, connection);
            break;
        }
        return ((od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillImpl) (obj));
    }

    public static boolean isValidMode(int i)
    {
        return i < 9 && i > -1;
    }

    public static final java.lang.String RCS_ID = "$Header: ODDrillFactory.java 115.5 2005/04/07 07:25:43 nbarik noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: ODDrillFactory.java 115.5 2005/04/07 07:25:43 nbarik noship $", "od.oracle.apps.xxcrm.bis.pmv.drill");
    public static final int NO_MODE = 0;
    public static final int DRILL_MODE = 1;
    public static final int DRILLDOWN_MODE = 2;
    public static final int PUBLIC_MODE = 3;
    public static final int RELATED_MODE = 4;
    public static final int RELATED_REPORT_TO_PAGE_MODE = 5;
    public static final int RELATED_PAGE_TO_PAGE_MODE = 6;
    public static final int DRILL_FROM_PORTLET_TITLE_MODE = 7;
    public static final int BC_MODE = 8;
    public static final java.lang.String drillModes[] = {
        "NO", "DRILL", "DRILLDOWN", "PUBLIC", "RELATED", "RELATED_REPORT_TO_PAGE", "RELATED_PAGE_TO_PAGE", "DRILL_FROM_PORTLET_TITLE", "BCRUMB"
    };

}
