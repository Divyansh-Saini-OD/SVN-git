package od.oracle.apps.xxcrm.cs.csz.dashboard.webui.eventhandler;

import com.sun.java.util.collections.HashMap;
import java.io.Serializable;
import oracle.apps.cs.csz.common.*;
import oracle.apps.cs.csz.oa.webui.CszControllerImpl;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OAPageContext;

public class XXCSGroupQueueEventHandler
    implements EventHandler
{

    public void processEvent(String s, OAApplicationModule oaapplicationmodule, OAPageContext oapagecontext)
    {
        if("cszUpdateSREvent".equals(oapagecontext.getParameter("event")))
        {
            handleUpdateEvent(oaapplicationmodule, oapagecontext);
            return;
        }
        if("cszAssignSREvent".equals(oapagecontext.getParameter("event")))
        {
            handleAssignEvent(oaapplicationmodule, oapagecontext);
            return;
        }
        if("cszGroupQueueRefresh".equals(oapagecontext.getParameter("event")))
        {
            handleRefreshEvent(oaapplicationmodule, oapagecontext);
        }
    }

    private void handleUpdateEvent(OAApplicationModule oaapplicationmodule, OAPageContext oapagecontext)
    {
        if(oapagecontext.isLoggingEnabled(1))
            oapagecontext.writeDiagnostics(this, "Inside GroupQueueEventHandler : Summary link clicked ", 1);
        HashMap hashmap = new HashMap();
        hashmap.put("cszIncidentId", oapagecontext.getParameter("srId"));
        String s = CszControllerImpl.cszGetCurrentUrlForRedirect(oapagecontext);
        hashmap.put("cszUpdateSRRetURL", s);
        CszControllerImpl.cleanParamsBeforeForward(hashmap);
        oapagecontext.releaseRootApplicationModule();
        oapagecontext.setForwardURL("OD_CSZ_SR_UP_FN", (byte)0, null, hashmap, false, CszGlobalConstants.CSZ_DEFAULT_BREADCRUMB_PARAM, (byte)0);
    }

    private void handleAssignEvent(OAApplicationModule oaapplicationmodule, OAPageContext oapagecontext)
    {
        if(oapagecontext.isLoggingEnabled(1))
            oapagecontext.writeDiagnostics(this, "Inside GroupQueueEventHandler : AssignIcon or Summary link clicked ", 1);
        HashMap hashmap = new HashMap();
        String s = (String)oapagecontext.getSessionValue("cszResourceId");
        if(s == null)
        {
            String s1 = oapagecontext.getMessage("CS", "CSZ_NO_RESOURCE_FOR_USER", null);
            throw new CszException(s1, (byte)0, oapagecontext, oapagecontext, oaapplicationmodule);
        }
        String s2 = (String)oapagecontext.getSessionValue("cszResourceType");
        if(s2 == null)
        {
            String s3 = oapagecontext.getMessage("CS", "CSZ_NO_RESOURCE_FOR_USER", null);
            throw new CszException(s3, (byte)0, oapagecontext, oapagecontext, oaapplicationmodule);
        }
        String s4 = oapagecontext.getParameter("srId");
        String s5 = oapagecontext.getParameter("srNumber");
        Serializable aserializable[] = {
            s4, s, s5, s2
        };
        String s6 = (String)oaapplicationmodule.invokeMethod("assignToMe", aserializable);
        if("SUCCESS".equals(s6))
        {
            hashmap.put("cszIncidentId", s4);
            String s7 = CszControllerImpl.cszGetCurrentUrlForRedirect(oapagecontext);
            hashmap.put("cszUpdateSRRetURL", s7);
            CszControllerImpl.cleanParamsBeforeForward(hashmap);
            oapagecontext.releaseRootApplicationModule();
            oapagecontext.setForwardURL("OD_CSZ_SR_UP_FN", (byte)0, null, hashmap, false, CszGlobalConstants.CSZ_DEFAULT_BREADCRUMB_PARAM, (byte)0);
            return;
        } else
        {
            hashmap.put("cszRefreshGroupQueue", "refresh");
            oapagecontext.forwardImmediatelyToCurrentPage(hashmap, true, CszGlobalConstants.CSZ_DEFAULT_BREADCRUMB_PARAM);
            return;
        }
    }

    private void handleRefreshEvent(OAApplicationModule oaapplicationmodule, OAPageContext oapagecontext)
    {
        if(oapagecontext.isLoggingEnabled(1))
            oapagecontext.writeDiagnostics(this, "Inside handleRefreshButtonEvent method:GroupQueue ", 1);
        String s = (String)oapagecontext.getSessionValue("cszResourceId");
        if(s == null)
        {
            String s1 = oapagecontext.getMessage("CS", "CSZ_NO_RESOURCE_FOR_USER", null);
            throw new CszException(s1, (byte)0, oapagecontext, oapagecontext, oaapplicationmodule);
        } else
        {
            Serializable aserializable[] = {
                s
            };
            oaapplicationmodule.invokeMethod("reExecuteGroupVO", aserializable);
            return;
        }
    }

    public XXCSGroupQueueEventHandler()
    {
    }

    public static final String RCS_ID = "$Header: GroupQueueEventHandler.java 120.2.12020000.2 2012/07/25 12:23:07 lkullamb ship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: GroupQueueEventHandler.java 120.2.12020000.2 2012/07/25 12:23:07 lkullamb ship $", "oracle.apps.cs.csz.dashboard.webui.eventhandler");

}