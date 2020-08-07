// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames 
// Source File Name:   ODParamMapHandler.java

package od.oracle.apps.xxcrm.bis.pmv.drill;

import java.sql.Connection;
import oracle.apps.bis.common.Constants;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.common.WebAppsContext;
import oracle.apps.jtf.cache.CacheManager;
import oracle.apps.jtf.cache.appsimpl.AppsCacheContext;
import oracle.apps.jtf.cache.generic.CacheContext;

// Referenced classes of package od.oracle.apps.xxcrm.bis.pmv.drill:
//            BisExternalParamMap

public class ODParamMapHandler
{

    public static java.lang.String getCacheKeyForFunction(java.lang.String s)
    {
        return "BIS_PMV_EXT_" + s;
    }

    private static od.oracle.apps.xxcrm.bis.pmv.drill.ODBisExternalParamMap getBisExtFromCache(java.lang.String s, oracle.apps.fnd.common.WebAppsContext webappscontext, java.sql.Connection connection)
    {
        if(s == null)
            return null;
        od.oracle.apps.xxcrm.bis.pmv.drill.ODBisExternalParamMap bisexternalparammap = null;
        try
        {
            java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.drill.ODParamMapHandler.getCacheKeyForFunction(s);
            oracle.apps.jtf.cache.appsimpl.AppsCacheContext appscachecontext = new AppsCacheContext(webappscontext);
            appscachecontext.setCacheLoaderContext("CONNECTION", connection);
            appscachecontext.setCacheLoaderContext("FUNCTION_NAME", s);
            bisexternalparammap = (od.oracle.apps.xxcrm.bis.pmv.drill.ODBisExternalParamMap)oracle.apps.jtf.cache.CacheManager.get("BIS_PMV_PARAM_MAP_CACHE", "BIS", s1, appscachecontext);
        }
        catch(java.lang.Exception _ex) { }
        return bisexternalparammap;
    }

    public static od.oracle.apps.xxcrm.bis.pmv.drill.ODBisExternalParamMap getBisExtParamMap(java.lang.String s, oracle.apps.fnd.common.WebAppsContext webappscontext, java.sql.Connection connection)
    {
        return od.oracle.apps.xxcrm.bis.pmv.drill.ODParamMapHandler.getBisExtFromCache(s, webappscontext, connection);
    }

    public static boolean isFuncMapped(java.lang.String s, oracle.apps.fnd.common.WebAppsContext webappscontext, java.sql.Connection connection)
    {
        if(s == null)
            return false;
        return od.oracle.apps.xxcrm.bis.pmv.drill.ODParamMapHandler.getBisExtFromCache(s, webappscontext, connection) != null;
    }

    public ODParamMapHandler()
    {
    }

    public static final java.lang.String RCS_ID = "$Header: ODParamMapHandler.java 115.3 2005/10/16 23:59:09 jprabhud noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: ODParamMapHandler.java 115.3 2005/10/16 23:59:09 jprabhud noship $", "od.oracle.apps.xxcrm.bis.pmv.drill.ODParamMapHandler");
    private static final java.lang.String FUNC_MAP_KEY = "BIS_PMV_EXT_";

}
