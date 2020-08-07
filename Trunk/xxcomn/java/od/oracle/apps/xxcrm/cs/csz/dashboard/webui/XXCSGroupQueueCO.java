package od.oracle.apps.xxcrm.cs.csz.dashboard.webui;

import com.sun.java.util.collections.HashMap;
import java.io.Serializable;
import oracle.apps.cs.csz.common.*;
import od.oracle.apps.xxcrm.cs.csz.dashboard.webui.eventhandler.XXCSGroupQueueEventHandler;
import oracle.apps.cs.csz.oa.webui.CszControllerImpl;
import oracle.apps.cs.csz.popup.sr.util.ServiceRequestPopup;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAHideShowHeaderBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPopupBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.jbo.domain.Number;

public class XXCSGroupQueueCO extends CszControllerImpl
    implements ServiceRequestPopup
{

    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processRequest(oapagecontext, oawebbean);
        populateGroupQueueVO(oapagecontext, oawebbean);
        OATableBean oatablebean = (OATableBean)oawebbean.findChildRecursive("GroupTableRN");
        OAMessageChoiceBean oamessagechoicebean = (OAMessageChoiceBean)oawebbean.findChildRecursive("SrStatusEnabled");
        if(oamessagechoicebean != null)
        {
            oamessagechoicebean.setListVOBoundContainerColumn(0, oatablebean, "SrStatusEnabled");
            oamessagechoicebean.setListVOBoundContainerColumn(1, oatablebean, "IncidentTypeId");
            oamessagechoicebean.setListVOBoundContainerColumn(2, oatablebean, "ResponsibilityId");
            oamessagechoicebean.setListVOBoundContainerColumn(3, oatablebean, "IncidentTypeId");
            oamessagechoicebean.setListVOBoundContainerColumn(4, oatablebean, "ResponsibilityId");
            oamessagechoicebean.setListVOBoundContainerColumn(5, oatablebean, "IncidentTypeId");
            oamessagechoicebean.setListVOBoundContainerColumn(6, oatablebean, "ResponsibilityId");
            oamessagechoicebean.setListVOBoundContainerColumn(7, oatablebean, "IncidentTypeId");
            oamessagechoicebean.setListVOBoundContainerColumn(8, oatablebean, "ResponsibilityId");
            oamessagechoicebean.setListVOBoundContainerColumn(9, oatablebean, "IncidentTypeId");
            oamessagechoicebean.setListVOBoundContainerColumn(10, oatablebean, "ResponsibilityId");
            oamessagechoicebean.setListVOBoundContainerColumn(11, oatablebean, "IncidentTypeId");
            oamessagechoicebean.setListVOBoundContainerColumn(12, oatablebean, "ResponsibilityId");
            oamessagechoicebean.setListVOBoundContainerColumn(13, oatablebean, "SrStatusEnabled");
            oamessagechoicebean.setListVOBoundContainerColumn(14, oatablebean, "SrStatusEnabled");
            oamessagechoicebean.setListVOBoundContainerColumn(15, oatablebean, "SrStatusEnabled");
            oamessagechoicebean.setListVOBoundContainerColumn(16, oatablebean, "IncidentTypeId");
            oamessagechoicebean.setListVOBoundContainerColumn(17, oatablebean, "ResponsibilityId");
            oamessagechoicebean.setListVOBoundContainerColumn(18, oatablebean, "IncidentTypeId");
            oamessagechoicebean.setListVOBoundContainerColumn(19, oatablebean, "ResponsibilityId");
            oamessagechoicebean.setListVOBoundContainerColumn(20, oatablebean, "IncidentTypeId");
            oamessagechoicebean.setListVOBoundContainerColumn(21, oatablebean, "ResponsibilityId");
            oamessagechoicebean.setListVOBoundContainerColumn(22, oatablebean, "IncidentTypeId");
            oamessagechoicebean.setListVOBoundContainerColumn(23, oatablebean, "ResponsibilityId");
            oamessagechoicebean.setListVOBoundContainerColumn(24, oatablebean, "IncidentTypeId");
            oamessagechoicebean.setListVOBoundContainerColumn(25, oatablebean, "ResponsibilityId");
            oamessagechoicebean.setListVOBoundContainerColumn(26, oatablebean, "IncidentTypeId");
            oamessagechoicebean.setListVOBoundContainerColumn(27, oatablebean, "ResponsibilityId");
            oamessagechoicebean.setListVOBoundContainerColumn(28, oatablebean, "SrStatusEnabled");
            oamessagechoicebean.setListVOBoundContainerColumn(29, oatablebean, "IncidentTypeId");
            oamessagechoicebean.setListVOBoundContainerColumn(30, oatablebean, "ResponsibilityId");
            oamessagechoicebean.setListVOBoundContainerColumn(31, oatablebean, "IncidentTypeId");
            oamessagechoicebean.setListVOBoundContainerColumn(32, oatablebean, "ResponsibilityId");
        }
        setPopupTitle(oapagecontext, oawebbean);
    }

    public void launchDetailsPage(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        handlPopupEventDetails(oapagecontext, oawebbean);
    }

    private void setPopupTitle(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        String s = CszIndustryTemplateUtil.cszGetMessage(oapagecontext, "CS", "CS_QUICK_UPDATE_SR_TITLE", null);
        OAPopupBean oapopupbean = (OAPopupBean)oawebbean.findChildRecursive("updateGroupServiceReqest");
        if(oapopupbean != null)
            oapopupbean.setTitle(s);
        s = CszIndustryTemplateUtil.cszGetMessage(oapagecontext, "CS", "CSZ_SR_NOTES_POPUP_TITLE", null);
        oapopupbean = (OAPopupBean)oawebbean.findChildRecursive("GroupSRNotesPopup");
        if(oapopupbean != null)
            oapopupbean.setTitle(s);
    }

    public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processFormRequest(oapagecontext, oawebbean);
        OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
        XXCSGroupQueueEventHandler groupqueueeventhandler = new XXCSGroupQueueEventHandler();
        groupqueueeventhandler.processEvent(null, oaapplicationmodule, oapagecontext);
        launchDetailsPage(oapagecontext, oawebbean);
    }

    private void populateGroupQueueVO(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        if(oapagecontext.isLoggingEnabled(1))
            oapagecontext.writeDiagnostics(this, " Inside populateGroupQueueVO method", 1);
        String s = (String)oapagecontext.getSessionValue("cszResourceId");
        OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
        if(s == null)
        {
            String s1 = oapagecontext.getMessage("CS", "CSZ_NO_RESOURCE_FOR_USER", null);
            throw new CszException(s1, (byte)0, oapagecontext, oapagecontext, oaapplicationmodule);
        } else
        {
            Serializable aserializable[] = {
                new String(s)
            };
            oaapplicationmodule.invokeMethod("loadGroupQueueVO", aserializable);
            String s2 = (String)oaapplicationmodule.invokeMethod("getGroupQueueCount");
            OAHideShowHeaderBean oahideshowheaderbean = (OAHideShowHeaderBean)oawebbean;
            oahideshowheaderbean.setText((new StringBuilder()).append(oahideshowheaderbean.getText()).append(" (").append(s2).append(")").toString());
            return;
        }
    }

    private void handlPopupEventDetails(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        HashMap hashmap = new HashMap();
        String s1 = (String)oapagecontext.getSessionValue("ieuIncidentNumber");
        Number number = (Number)oapagecontext.getSessionValue("ieuIncidentId");
        String s2 = (String)oapagecontext.getSessionValue("ieuSRAction");
        String s3 = (String)oapagecontext.getSessionValue("ieuSRWarning");
        Object obj = null;
        if("QuickUpdateSR".equals(s2))
        {
            String s = oapagecontext.getCurrentUrlForRedirect();
            if(number != null && !"".equals(number))
            {
                oapagecontext.removeSessionValue("ieuIncidentId");
                oapagecontext.removeSessionValue("ieuIncidentNumber");
                oapagecontext.removeSessionValue("ieuSRAction");
                hashmap.put("cszIncidentId", number);
                hashmap.put("cszUpdateSRRetURL", s);
                if(s3 != null && !"".equals(s3))
                {
                    hashmap.put("cszMessageText", s3);
                    hashmap.put("cszMessageType", "W");
                }
                oapagecontext.removeSessionValue("ieuSRWarning");
                String s4 = CszIndustryTemplateUtil.getSubstitutionKey(oapagecontext, "F", "CSZ_SR_UP_FN");
                oapagecontext.setForwardURL(s4, (byte)0, null, hashmap, false, CszGlobalConstants.CSZ_DEFAULT_BREADCRUMB_PARAM, (byte)99);
            }
        }
    }

    public static final String RCS_ID = "$Header: GroupQueueCO.java 120.1.12020000.11 2014/04/10 07:40:51 spamujul ship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: GroupQueueCO.java 120.1.12020000.11 2014/04/10 07:40:51 spamujul ship $", "oracle.apps.cs.csz.dashboard.webui");

}