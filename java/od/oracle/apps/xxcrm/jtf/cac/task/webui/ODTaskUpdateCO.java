package od.oracle.apps.xxcrm.jtf.cac.task.webui;

import java.io.Serializable;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.*;
import oracle.apps.fnd.framework.webui.*;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAHideShowHeaderBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.nav.OALinkBean;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.apps.jtf.cac.util.TaskConstants;
import oracle.apps.jtf.cac.util.webui.CacUtil;
import oracle.apps.jtf.cac.util.webui.TaskUtil;
import oracle.cabo.ui.UIConstants;
import oracle.cabo.ui.beans.layout.HideShowHeaderBean;
import oracle.cabo.ui.beans.layout.PageLayoutBean;
import oracle.cabo.ui.beans.nav.LinkBean;
import oracle.jbo.ApplicationModule;
import oracle.jbo.Transaction;

public class ODTaskUpdateCO extends OAControllerImpl
{

    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processRequest(oapagecontext, oawebbean);
        String s = null;
        String s1 = null;
        int i = -1;
        if(!"Y".equals((String)oapagecontext.getTransactionValue("cacTaskParamsTaken")))
        {
            //Anirban added for task dashboard reports: starts

            String s2 = null;
			byte byte0 = 1;

			if("Y".equals(oapagecontext.getParameter("fromTaskDashboard")))
			{
             s2 = oapagecontext.getParameter("cacTaskId");
			}
			else
			{
             s2 = oapagecontext.decrypt(oapagecontext.getParameter("cacTaskId"));
			}

			if("Y".equals(oapagecontext.getParameter("fromActivitiesDashboard")))
			{
             oapagecontext.putParameter("cacTaskUsrAuth",oapagecontext.encrypt(String.valueOf(byte0)));
			}
			
            //Anirban added for task dashboard reports: ends

            if(s2 == null || "".equals(s2))
            {
                MessageToken amessagetoken[] = {
                    new MessageToken("PARAMETER_NAME", "jtfTaskId")
                };
                throw new OAException("JTF", "JTF_TASK_PARAM_NOT_FOUND", amessagetoken);
            }

            oapagecontext.putTransactionTransientValue("cacTaskId", s2);
            String s3 = oapagecontext.decrypt(oapagecontext.getParameter("cacTaskUsrAuth"));
            oapagecontext.putTransactionTransientValue("cacTaskUsrAuth", s3);
            String s5 = oapagecontext.getParameter("cacTaskReturnUrl");
            oapagecontext.putTransactionTransientValue("cacTaskReturnUrl", s5);
            String s6 = oapagecontext.getParameter("cacTaskReturnMsgPrmNm");
            oapagecontext.putTransactionTransientValue("cacTaskReturnMsgPrmNm", s6);
            String s7 = oapagecontext.getParameter("cacTaskReturnLabel");
            oapagecontext.putTransactionTransientValue("cacTaskReturnLabel", s7);
            String s8 = oapagecontext.getParameter("cacTaskAssigneeSecurityImpl");
            oapagecontext.putTransactionTransientValue("cacTaskAssigneeSecurityImpl", s8);
            String s9 = oapagecontext.getParameter("cacTaskTypeRO");
            oapagecontext.putTransactionTransientValue("cacTaskTypeRO", s9);
            s = oapagecontext.getParameter("cacTaskDueDate");
            if(s == null)
                s = "Y";
            oapagecontext.putTransactionTransientValue("cacTaskDueDate", s);
            String s10 = oapagecontext.getParameter("cacTaskContDqmRule");
            oapagecontext.putTransactionTransientValue("cacTaskContDqmRule", s10);
            s1 = oapagecontext.getParameter("cacTaskContact");
            if(s1 == null)
                s1 = "Y";
            oapagecontext.putTransactionTransientValue("cacTaskContact", s1);
            String s11 = oapagecontext.getParameter("cacTaskCustId");
            String s12 = oapagecontext.getPageExecutionFunction();
            oapagecontext.putTransactionTransientValue("cacTaskPageFunc", s12);
            if(oapagecontext.isLoggingEnabled(1))
                oapagecontext.writeDiagnostics(this, "ODTaskUpdateCO - parameters passed:\n,cacTaskId=" + s2 + ",cacTaskDueDate=" + s + ",cacTaskContact=" + s1 + ",cacTaskCustId=" + s11 + ",cacTaskContDqmRule=" + s10 + ",cacTaskPageFunc=" + s12 + ",cacTaskUsrAuth=" + s3 + ",cacTaskAssigneeSecurityImpl=" + s8 + ",cacTaskReturnMsgPrmNm=" + s6 + ",cacTaskReturnUrl=" + s5 + ",cacTaskReturnLabel=" + s7, 1);
            if(s3 != null && !"".equals(s3))
                try
                {
                    i = Integer.parseInt(s3);
                    if(i == 2 || i == 1)
                    {
                        oapagecontext.putTransactionValue("cacTaskUsrAuth", s3);
                    } else
                    {
                        oapagecontext.putTransactionValue("cacTaskUsrAuth", s3);
                        i = -1;
                    }
                }
                catch(Exception _ex)
                {
                    i = -1;
                }
            oapagecontext.putTransactionValue("cacTaskParamsTaken", "Y");
            OAApplicationModule oaapplicationmodule = (OAApplicationModule)oapagecontext.getRootApplicationModule().findApplicationModule("TaskAM");
            Serializable aserializable[] = {
                s2, s11
            };
            oaapplicationmodule.invokeMethod("initTaskDetail", aserializable);
            String s13 = (String)oaapplicationmodule.invokeMethod("getCustomerId");
            if(s13 == null)
                s13 = s11;
            oapagecontext.putTransactionTransientValue("cacTaskCustId", s13);
            String s14 = (String)oaapplicationmodule.invokeMethod("getTaskName");
            String s15 = oapagecontext.getPageLayoutBean().getWindowTitle();
            s15 = s15 + ":" + " " + s14;
            oapagecontext.getPageLayoutBean().setTitle(s15);
            if(i == -1)
            {
                String s4 = (String)oapagecontext.getTransactionValue("cacTaskUsrAuth");
                i = Integer.parseInt(s4);
            }
            if(i == 1)
            {
                MessageToken amessagetoken1[] = null;
                String s16 = oapagecontext.getMessage("JTF", "JTF_TASK_DETAILS", amessagetoken1);
                oapagecontext.getPageLayoutBean().setWindowTitle(s16);
                s16 = s16 + ":" + " " + s14;
                oapagecontext.getPageLayoutBean().setTitle(s16);
                readOnlyRendering(oapagecontext, oawebbean, s1);
                if(!"Y".equals(oapagecontext.getParameter("cacTaskPerzPage")))
                {
                    String s17 = oapagecontext.getMessage("JTF", "JTF_TASK_RETURN_SUMMARY", amessagetoken1);
                    OALinkBean oalinkbean = (OALinkBean)createWebBean(oapagecontext, "LINK_BEAN");
                    oalinkbean.setDestination(s5);
                    if(s7 != null && !"".equals(s7))
                        oalinkbean.setAttributeValue(UIConstants.TEXT_ATTR, s7);
                    else
                        oalinkbean.setAttributeValue(UIConstants.TEXT_ATTR, s17);
                    ((OAPageLayoutBean)oawebbean).setReturnNavigation(oalinkbean);
                }
            } else
            if(i != 2)
            {
                if(oapagecontext.isLoggingEnabled(4))
                    oapagecontext.writeDiagnostics(this, "TaskUpdatePG - Access denied: access =  " + i, 4);
                MessageToken amessagetoken2[] = {
                    new MessageToken("TASK_ID", s2)
                };
                throw new OAException("JTF", "TASK_ACCESS_DENIED", amessagetoken2);
            }
        }
        s = (String)oapagecontext.getTransactionTransientValue("cacTaskDueDate");
        if("Y".equals(s))
        {
            CacUtil.hideRegionItem(oawebbean, "TaskDateHideShowRN");
            CacUtil.hideRegionItem(oawebbean, "RestrictClosureFlag");
            CacUtil.hideRegionItem(oawebbean, "Blank1");
            if(i == 2)
                CacUtil.setDateFormatTip(oapagecontext, oawebbean, "JTF_TASK_DATE_FORMAT", "DueDate");
        } else
        {
            CacUtil.hideRegionItem(oawebbean, "StartDate");
            CacUtil.hideRegionItem(oawebbean, "DueDate");
            CacUtil.hideRegionItem(oawebbean, "TaskEffortsRN");
        }
        s1 = (String)oapagecontext.getTransactionTransientValue("cacTaskContact");
        if("N".equals(s1))
            CacUtil.hideRegionItem(oawebbean, "TaskContactHideShowRN");
        oapagecontext.getPageLayoutBean().prepareForRendering(oapagecontext);
        oapagecontext.getPageLayoutBean().setStart(null);
    }

    public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processFormRequest(oapagecontext, oawebbean);
        boolean flag = oapagecontext.getRootApplicationModule().getTransaction().isDirty();
        if(oapagecontext.getParameter("Apply") != null)
        {
            String s = null;
            if(flag)
            {
                s = oapagecontext.getMessage("JTF", "JTF_TASK_UPDATE_CONFIRM", null);
                OAApplicationModule oaapplicationmodule = (OAApplicationModule)oapagecontext.getRootApplicationModule().findApplicationModule("TaskAM");
                if(oaapplicationmodule != null)
                    oaapplicationmodule.invokeMethod("taskOwnerSync");
                oapagecontext.getRootApplicationModule().findApplicationModule("TaskAM").getTransaction().commit();
            }
            oapagecontext.releaseRootApplicationModule();
            TaskUtil.taskRedirect(oapagecontext, s);
            return;
        }
        if(oapagecontext.getParameter("Cancel") != null)
        {
            oapagecontext.releaseRootApplicationModule();
            TaskUtil.taskRedirect(oapagecontext, null);
        }
    }

    private void readOnlyRendering(OAPageContext oapagecontext, OAWebBean oawebbean, String s)
    {
        OAWebBean oawebbean1 = oawebbean.findChildRecursive("PageButtonRN");
        if(oawebbean1 != null)
            oawebbean1.setRendered(false);
        oawebbean1 = oawebbean.findChildRecursive("TaskRequiredRN");
        if(oawebbean1 != null)
            oawebbean1.setRendered(false);
        oawebbean1 = oawebbean.findChildRecursive("ObjRefTableLayout");
        if(oawebbean1 != null)
            oawebbean1.setRendered(false);
        oawebbean1 = oawebbean.findIndexedChildRecursive("TskRefDelLink");
        if(oawebbean1 != null)
            oawebbean1.setRendered(false);
        OAHideShowHeaderBean oahideshowheaderbean = (OAHideShowHeaderBean)oawebbean.findIndexedChildRecursive("TaskDetailHideShowRN");
        oahideshowheaderbean.setDisclosed(true);
        OAHideShowHeaderBean oahideshowheaderbean1 = (OAHideShowHeaderBean)oawebbean.findIndexedChildRecursive("TaskAssigneeHideShowRN");
        oahideshowheaderbean1.setDisclosed(true);
        OAHideShowHeaderBean oahideshowheaderbean2 = (OAHideShowHeaderBean)oawebbean.findIndexedChildRecursive("TaskReferenceHideShowRN");
        oahideshowheaderbean2.setDisclosed(true);
        if("Y".equals(s))
        {
            OAHideShowHeaderBean oahideshowheaderbean3 = (OAHideShowHeaderBean)oawebbean.findIndexedChildRecursive("TaskContactHideShowRN");
            oahideshowheaderbean3.setDisclosed(true);
            OAWebBean oawebbean2 = oawebbean.findChildRecursive("CacTskAddBtn");
            if(oawebbean2 != null)
                oawebbean2.setRendered(false);
            oawebbean2 = oawebbean.findChildRecursive("CacTskContRemove");
            if(oawebbean2 != null)
                oawebbean2.setRendered(false);
            OATableBean oatablebean = (OATableBean)oawebbean.findIndexedChildRecursive("CacTskContTbl");
            if(oatablebean != null)
            {
                oatablebean.setControlBarDisplayed(false);
                oatablebean.setSelectionDisplayed(false);
            }
        }
        String as[] = {
            "Subject", "Type", "Status", "StartDate", "DueDate", "Visibility", "Priority", "RestrictClosureFlag", "Description", "PlannedEffort", 
            "PlannedEffortUom", "ScheduledStartDate", "ScheduledEndDate", "PlannedStartDate", "PlannedEndDate", "TaskFlexFields"
        };
        CacUtil.setReadOnlyAttr(oawebbean, as, "OraDataText");
    }

    public ODTaskUpdateCO()
    {
    }

    public static final String RCS_ID = "$Header: ODTaskUpdateCO.java 115.26 2006/06/27 22:36:01 twan noship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: ODTaskUpdateCO.java 115.26 2006/06/27 22:36:01 twan noship $", "oracle.apps.jtf.cac.task.webui");

}
