// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames
// Source File Name:   ODHTMLUtil.java

package od.oracle.apps.xxcrm.bis.pmv.common;
import oracle.apps.bis.pmv.common.*;
import com.sun.java.util.collections.AbstractCollection;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;
import java.io.Serializable;
import java.io.UnsupportedEncodingException;
import java.util.Vector;
import java.sql.Connection;
import javax.servlet.ServletContext;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.jsp.PageContext;
import oracle.apps.bis.common.UserPersonalizationUtil;
import oracle.apps.bis.common.Util;
import od.oracle.apps.xxcrm.bis.common.ODViewPopUpMenu;
import od.oracle.apps.xxcrm.bis.components.ODComponentPageHeaderFooter;
import oracle.apps.bis.pmv.lov.LovUtil;
import oracle.apps.bis.pmv.metadata.AKRegion;
import oracle.apps.bis.pmv.metadata.AKRegionItem;
import oracle.apps.bis.pmv.parameters.Hierarchy;
import oracle.apps.bis.pmv.parameters.ParameterHelper;
import oracle.apps.bis.pmv.parameters.PopDateValues;
import oracle.apps.bis.pmv.session.RequestInfo;
import oracle.apps.bis.pmv.session.UserSession;
import oracle.apps.fnd.common.AppsContext;
import oracle.apps.fnd.common.Context;
import oracle.apps.fnd.common.ProfileStore;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.common.WebAppsContext;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.security.AolSecurity;
import oracle.cabo.share.config.Configuration;
import oracle.cabo.share.url.EncoderUtils;

// Referenced classes of package oracle.apps.bis.pmv.common:
//            LookUp, LookUpHelper, PMVConstants, PMVUtil,
//            StringUtil

public class ODHTMLUtil
    implements oracle.apps.bis.pmv.common.PMVConstants
{

    public ODHTMLUtil()
    {
    }

    public static java.lang.String getSpaceHTML(oracle.apps.bis.pmv.session.UserSession usersession, java.lang.String s)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append("<tr><td><img src=");
        stringbuffer.append(usersession.getImageServer());
        stringbuffer.append("bisspace.gif alt=\"\" height=").append(s).append("></td></tr>");
        return stringbuffer.toString();
    }

    public static java.lang.String getRerunlink(oracle.apps.bis.pmv.session.UserSession usersession)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(200);
        stringbuffer.append("<TD> <a href=\"");
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getJspAgent(usersession.getWebAppsContext()));
        stringbuffer.append("../XXCRM_HTML/bisviewm.jsp?dbc=").append(usersession.getRequestInfo().getDBC());
        stringbuffer.append("&sessionid=").append(usersession.getSessionId());
        stringbuffer.append("&transactionid=").append(usersession.getTransactionId());
        stringbuffer.append("&regionCode=").append(usersession.getRegionCode());
        stringbuffer.append("&functionName=").append(usersession.getFunctionName());
        stringbuffer.append("&parameterDisplayOnly=").append(usersession.getRequestInfo().getParameterDisplayOnly());
        stringbuffer.append("&displayParameters=").append(usersession.getRequestInfo().getDisplayParameters());
        stringbuffer.append("&pFirstTime=0&pSubmit=RERUN");
        if(!usersession.getRequestInfo().getScheduleId().equals(""))
            stringbuffer.append("&scheduleId=").append(usersession.getRequestInfo().getScheduleId());
        stringbuffer.append("\" target=_top>").append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("RERUN", usersession.getWebAppsContext()));
        stringbuffer.append("</a></TD>");
        return stringbuffer.toString();
    }

    public static java.lang.String getButtonHTML(java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, oracle.apps.fnd.common.WebAppsContext webappscontext, javax.servlet.ServletContext servletcontext, oracle.apps.bis.pmv.session.UserSession usersession)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(200);
        stringbuffer.append(" <A HREF=" + s);
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getOnMouseOverHtml(s1));
        stringbuffer.append(" return true\"\" target=_top>");
        stringbuffer.append("<img src=");
        if(usersession.getRequestInfo() != null && "BSC".equals(usersession.getRequestInfo().getMode()))
            stringbuffer.append("/OA_HTML/");
        stringbuffer.append(oracle.apps.bis.common.Util.generateButtonGif(s3, webappscontext, servletcontext, usersession.getRequest(), usersession.getPageContext(), usersession.getConnection()));
        stringbuffer.append(" ALT=\"");
        stringbuffer.append(s2 + " ");
        stringbuffer.append("\" TITLE=\"");
        stringbuffer.append(s2 + " ");
        stringbuffer.append("\" border=0></a>");
        return stringbuffer.toString();
    }

    public static java.lang.String getStyleSheetName(oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        java.lang.String s = "";
        java.lang.StringBuffer stringbuffer = new StringBuffer(200);
        long l = java.lang.System.currentTimeMillis();
        try
        {
            if(webappscontext.getCurrLangCode() != null)
                s = webappscontext.getCurrLangCode();
            if(s.equals("AR") || s.equals("IW"))
                stringbuffer.append("<link rel=\"stylesheet\" href=\"/OA_HTML/bismarlibidi.css?").append(l).append("\" type=\"text/css\">");
            else
                stringbuffer.append("<link rel=\"stylesheet\" href=\"/OA_HTML/bismarli.css?").append(l).append("\" type=\"text/css\">");
        }
        catch(java.lang.Exception _ex) { }
        return stringbuffer.toString();
    }

    public static java.lang.String getDashboardActionsHtml(od.oracle.apps.xxcrm.bis.components.ODComponentPageHeaderFooter componentpageheaderfooter, oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, boolean flag)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(200);
        java.lang.String s = "";
        java.lang.String s1 = oapagecontext.getMessage("BIS", "BIS_ACTIONS", null);
        java.lang.String s2 = oapagecontext.getMessage("BIS", "BIS_VIEWS", null);
        if(oapagecontext.getCurrentLanguage() != null)
            s = oapagecontext.getCurrentLanguage();
        java.lang.String s3 = "right";
        if("AR".equals(s) || "IW".equals(s))
            s3 = "left";
        if(!flag)
            stringbuffer.append("<tr><td noWrap align=").append(s3).append(">");
        else
            stringbuffer.append("</td><td noWrap align=").append(s3).append(">");
        stringbuffer.append("<a id='ViewsDHeader' name='ViewsDHeader' class=\"PmvCrumbsEnabled\"");
        stringbuffer.append(" style=\"cursor:hand;text-decoration:none;\"");
        stringbuffer.append(" href=\"javascript:menuControlClick(event, 'VMenu0', 'ViewsDHeader', '');\"");
        stringbuffer.append(" onClick=\"menuControlClick(event, 'VMenu0', 'ViewsDHeader', '');return false;\"");
        stringbuffer.append(" onKeyDown=\"clkDown(event)\" onMouseDown=\"clkDown(event)\">");
        stringbuffer.append(s2);
        stringbuffer.append(" <img align=bottom src=/OA_MEDIA/bisdarr.gif ALT=\"").append(s2);
        stringbuffer.append(" \" TITLE=\"").append(s2).append(" \" border=0>");
        stringbuffer.append(" </a>&nbsp;&nbsp;");
        stringbuffer.append("<a id='createImage1' name='createImage1' class=\"PmvCrumbsEnabled\"");
        stringbuffer.append(" style=\"cursor:hand;text-decoration:none;\"");
        stringbuffer.append(" href=\"javascript:menuControlClick(event, 'VMenu1', 'createImage1', '');\"");
        stringbuffer.append(" onClick=\"menuControlClick(event, 'VMenu1', 'createImage1', '');return false;\"");
        stringbuffer.append(" onKeyDown=\"clkDown(event)\" onMouseDown=\"clkDown(event)\">");
        stringbuffer.append(s1);
        stringbuffer.append(" <img align=bottom src=/OA_MEDIA/bisdarr.gif ALT=\"").append(s1);
        stringbuffer.append(" \" TITLE=\"").append(s1).append(" \" border=0>");
        stringbuffer.append(" </a></td>");
        stringbuffer.append("<td>");
        stringbuffer.append(od.oracle.apps.xxcrm.bis.common.ODViewPopUpMenu.getDashboardActionsHtml(componentpageheaderfooter, oapagecontext));
        stringbuffer.append("</td>");
        stringbuffer.append("<td>");
        stringbuffer.append(od.oracle.apps.xxcrm.bis.common.ODViewPopUpMenu.getDashboardViewsHtml(componentpageheaderfooter, oapagecontext));
        stringbuffer.append("</td>");
        stringbuffer.append("</tr>");
        return stringbuffer.toString();
    }

    public static java.lang.String getActionButtonHtml(oracle.apps.fnd.common.WebAppsContext webappscontext, oracle.apps.bis.pmv.session.UserSession usersession)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(200);
        java.lang.String s = "";
        java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_ACTIONS", webappscontext);
        if(webappscontext.getCurrLangCode() != null)
            s = webappscontext.getCurrLangCode();
        if(s.equals("AR") || s.equals("IW"))
        {
            stringbuffer.append("<td align=\"left\" valign=\"top\"  width=\"10%\">");
            stringbuffer.append("<table cellpadding=\"0\" cellspacing=\"0\" align=\"left\" border=\"0\" summary=\"\">");
        } else
        {
            stringbuffer.append("<td align=\"right\" valign=\"top\" width=\"10%\">");
            stringbuffer.append("<table cellpadding=\"0\" cellspacing=\"0\" align=\"right\" border=\"0\" summary=\"\">");
        }
        stringbuffer.append("<TR><TD noWrap valign=\"top\">");
        if(usersession.getAKRegion() != null && !usersession.getAKRegion().isEDW())
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getListOfViewHtml(usersession, false));
        stringbuffer.append("</TD><TD noWrap valign=\"top\">");
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getListOfQCHtml(usersession, false));
        stringbuffer.append("</TD><TD noWrap vAlign=\"top\">&nbsp;&nbsp;<A class=\"OraCrumbsEnabled\" id=\"createImage1\" name=\"createImage1\"");
        stringbuffer.append(" onmousedown=clkDown(event) onkeydown=clkDown(event)");
        stringbuffer.append(" style=\"CURSOR: hand; TEXT-DECORATION: none\"");
        stringbuffer.append(" onClick=\"menuControlClick(event, 'VMenu1', 'createImage1', '');return false;\"");
        stringbuffer.append(" href=\"javascript:menuControlClick(event, 'VMenu1', 'createImage1', '');\">");
        stringbuffer.append(s1);
        stringbuffer.append("&nbsp;<IMG title=\"").append(s1).append(" \" alt=\"").append(s1).append(" \"");
        stringbuffer.append(" src=\"/OA_MEDIA/bisdarr.gif\" border=0> </A>&nbsp;</TD>");
        stringbuffer.append("<TD>");
        stringbuffer.append(" <link type=\"text/css\" rel=\"stylesheet\" href=\"/OA_HTML/bisviewpopup.css?").append(java.lang.System.currentTimeMillis()).append("\"> ");
  stringbuffer.append(od.oracle.apps.xxcrm.bis.common.ODViewPopUpMenu.getActionButtonHtml(usersession));
        stringbuffer.append("</td>");
        stringbuffer.append("</tr></table></td>");
        return stringbuffer.toString();
    }

    public static java.lang.String getQCButtonHtml(oracle.apps.fnd.common.WebAppsContext webappscontext, oracle.apps.bis.pmv.session.UserSession usersession)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(200);
        java.lang.String s = "";
        java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_ACTIONS", webappscontext);
        if(webappscontext.getCurrLangCode() != null)
            s = webappscontext.getCurrLangCode();
        if(s.equals("AR") || s.equals("IW"))
        {
            stringbuffer.append("<td align=\"left\" valign=\"top\"  width=\"10%\">");
            stringbuffer.append("<table cellpadding=\"0\" cellspacing=\"0\" align=\"left\" border=\"0\" summary=\"\">");
        } else
        {
            stringbuffer.append("<td align=\"right\" valign=\"top\" width=\"10%\">");
            stringbuffer.append("<table cellpadding=\"0\" cellspacing=\"0\" align=\"right\" border=\"0\" summary=\"\">");
        }
        stringbuffer.append("<TR><TD noWrap valign=\"top\">");
        /*if(usersession.getAKRegion() != null && !usersession.getAKRegion().isEDW())

            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getListOfViewHtml(usersession, false));
        stringbuffer.append("</TD><TD noWrap valign=\"top\">");
        */
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getListOfQCHtml(usersession, false));
        /*
        stringbuffer.append("</TD><TD noWrap vAlign=\"top\">&nbsp;&nbsp;<A class=\"OraCrumbsEnabled\" id=\"createImage1\" name=\"createImage1\"");
        stringbuffer.append(" onmousedown=clkDown(event) onkeydown=clkDown(event)");
        stringbuffer.append(" style=\"CURSOR: hand; TEXT-DECORATION: none\"");
        stringbuffer.append(" onClick=\"menuControlClick(event, 'VMenu1', 'createImage1', '');return false;\"");
        stringbuffer.append(" href=\"javascript:menuControlClick(event, 'VMenu1', 'createImage1', '');\">");
        stringbuffer.append(s1);
        stringbuffer.append("&nbsp;<IMG title=\"").append(s1).append(" \" alt=\"").append(s1).append(" \"");
        stringbuffer.append(" src=\"/OA_MEDIA/bisdarr.gif\" border=0> </A>&nbsp;</TD>");
        stringbuffer.append("<TD>");
        stringbuffer.append(" <link type=\"text/css\" rel=\"stylesheet\" href=\"/OA_HTML/bisviewpopup.css?").append(java.lang.System.currentTimeMillis()).append("\"> ");
        stringbuffer.append(od.oracle.apps.xxcrm.bis.common.ODViewPopUpMenu.getActionButtonHtml(usersession));
        */
        stringbuffer.append("</td>");
        stringbuffer.append("</tr></table></td>");
        return stringbuffer.toString();
    }

   public static java.lang.String getListOfQCHtml(oracle.apps.bis.pmv.session.UserSession usersession, boolean flag)
    {
        com.sun.java.util.collections.HashMap hashmap = oracle.apps.bis.common.UserPersonalizationUtil.getUserLevelCustomizationData(usersession.getUserId(), usersession.getFunctionName(), usersession.getConnection());
        java.lang.String s = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_REPORT_QC", usersession.getWebAppsContext());
        //java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_REPORT_QC", usersession.getWebAppsContext());
        java.lang.String s1 = "Shortcuts";
        java.lang.String s2 = usersession.getCustomCode();
        usersession.getParamBookMarkUrl();
        java.lang.StringBuffer stringbuffer = new StringBuffer(1000);
        java.lang.String s3 = "createImage1";
        if(flag)
            s3 = s3 + "2";
        Vector objVect = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getListofShortcuts(usersession.getConnection(),usersession);
        if(objVect!=null && objVect.size()>0){
			 stringbuffer.append("&nbsp;&nbsp;<A class=\"OraCrumbsEnabled\" id=\"").append(s3).append("\" name=\"").append(s3).append("\"");
			 stringbuffer.append(" onmousedown=clkDown(event) onkeydown=clkDown(event)");
			 stringbuffer.append(" style=\"CURSOR: hand; TEXT-DECORATION: none\"");
			 stringbuffer.append(" onclick=\"menuControlClick(event, 'ShortcutsMenu', '").append(s3).append("', '").append(s2).append("');return false;\"");
			 stringbuffer.append(" href=\"javascript:menuControlClick(event, 'ShortcutsMenu', '").append(s3).append("', '").append(s2).append("');\">");
			 stringbuffer.append(s1);
			 stringbuffer.append("&nbsp;<IMG title=\"").append(s1).append(" \" alt=\"").append(s1).append(" \"");
			 stringbuffer.append("src=\"/OA_MEDIA/bisdarr.gif\" border=0></A></TD>");
             stringbuffer.append("<TD>");
             stringbuffer.append("<div id=\"ShortcutsMenu\" class=\"viewPopUpMenu\">");
			 for(int i=0;i<objVect.size();i++){
				 HashMap objHash = (HashMap)objVect.get(i);
				 String label = null;
				 if(objHash.get("label")!=null)
				   label = objHash.get("label").toString();
				 String path = null;
				 if(objHash.get("path")!=null)
				   path = objHash.get("path").toString();
				 stringbuffer.append("<a class=\"viewPopUpMenuItem\" title="+label+" href=\"../OA_HTML/"+path+"\" target=\"crm_detail_wnd\" onClick=dtl_window(\"\")><span>"+label+"</span></a>");
			 }
		}
		stringbuffer.append("</div>");
        return stringbuffer.toString();
    }

    public static java.lang.String getListOfViewHtml(oracle.apps.bis.pmv.session.UserSession usersession, boolean flag)
    {
        com.sun.java.util.collections.HashMap hashmap = oracle.apps.bis.common.UserPersonalizationUtil.getUserLevelCustomizationData(usersession.getUserId(), usersession.getFunctionName(), usersession.getConnection());
        java.lang.String s = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_REPORT_VIEWS", usersession.getWebAppsContext());
        java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_VIEWS", usersession.getWebAppsContext());
        java.lang.String s2 = usersession.getCustomCode();
        usersession.getParamBookMarkUrl();
        java.lang.StringBuffer stringbuffer = new StringBuffer(1000);
        java.lang.String s3 = "createImage";
        if(flag)
            s3 = s3 + "2";
        stringbuffer.append("&nbsp;&nbsp;<A class=\"OraCrumbsEnabled\" id=\"").append(s3).append("\" name=\"").append(s3).append("\"");
        stringbuffer.append(" onmousedown=clkDown(event) onkeydown=clkDown(event)");
        stringbuffer.append(" style=\"CURSOR: hand; TEXT-DECORATION: none\"");
        stringbuffer.append(" onclick=\"menuControlClick(event, 'VMenu0', '").append(s3).append("', '").append(s2).append("');return false;\"");
        stringbuffer.append(" href=\"javascript:menuControlClick(event, 'VMenu0', '").append(s3).append("', '").append(s2).append("');\">");
        stringbuffer.append(s1);
        stringbuffer.append("&nbsp;<IMG title=\"").append(s).append(" \" alt=\"").append(s).append(" \"");
        stringbuffer.append("src=\"/OA_MEDIA/bisdarr.gif\" border=0></A></TD>");
        stringbuffer.append("<TD>");
        if(!flag)
            stringbuffer.append(od.oracle.apps.xxcrm.bis.common.ODViewPopUpMenu.getListOfViewHtml(hashmap, s2, usersession));
        return stringbuffer.toString();
    }

    public static java.lang.String getStyleSheetNameWithFullPath(oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        java.lang.String s = "";
        java.lang.StringBuffer stringbuffer = new StringBuffer(200);
        long l = java.lang.System.currentTimeMillis();
        try
        {
            if(webappscontext.getCurrLangCode() != null)
                s = webappscontext.getCurrLangCode();
            if(s.equals("AR") || s.equals("IW"))
                stringbuffer.append("<LINK REL=\"stylesheet\" HREF=\"").append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getJspAgent(webappscontext)).append("bismarlibidi.css?").append(l).append("\" type=\"text/css\">");
            else
                stringbuffer.append("<LINK REL=\"stylesheet\" HREF=\"").append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getJspAgent(webappscontext)).append("bismarli.css?").append(l).append("\" type=\"text/css\">");
        }
        catch(java.lang.Exception _ex) { }
        return stringbuffer.toString();
    }

    public static java.lang.String getPopList(java.lang.String s, java.lang.String s1, java.lang.String s2, com.sun.java.util.collections.ArrayList arraylist, boolean flag, java.lang.String s3, java.lang.String s4)
    {
        oracle.apps.bis.pmv.common.LookUp alookup[] = (oracle.apps.bis.pmv.common.LookUp[])arraylist.toArray(new oracle.apps.bis.pmv.common.LookUp[arraylist.size()]);
        return od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getPopListFromLookUp(s, s2, s1, alookup, flag, s3, s4);
    }

    public static java.lang.String getPopList(java.lang.String s, java.lang.String s1, java.lang.String s2, com.sun.java.util.collections.ArrayList arraylist, boolean flag, boolean flag1, java.lang.String s3, java.lang.String s4)
    {
        com.sun.java.util.collections.ArrayList arraylist1 = null;
        if(flag1 && !"All".equals(oracle.apps.bis.pmv.common.LookUpHelper.decodeIdValue(s1)[1]))
            arraylist1 = oracle.apps.bis.pmv.lov.LovUtil.indentLookUpValues(arraylist, s1, "-");
        else
            arraylist1 = arraylist;
        oracle.apps.bis.pmv.common.LookUp alookup[] = (oracle.apps.bis.pmv.common.LookUp[])arraylist1.toArray(new oracle.apps.bis.pmv.common.LookUp[arraylist1.size()]);
        return od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getPopListFromLookUp(s, s2, s1, alookup, flag, s3, s4);
    }

    public static java.lang.String getPopListFromLookUp(java.lang.String s, java.lang.String s1, java.lang.String s2, oracle.apps.bis.pmv.common.LookUp alookup[], boolean flag, java.lang.String s3, java.lang.String s4)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(200);
        boolean flag1 = false;
        stringbuffer.append("<LABEL>");
        stringbuffer.append("<SELECT class=OraInstructionText NAME=" + s);
        if(s1 != null && s1.length() > 0)
            stringbuffer.append(" onChange=").append(s1);
        stringbuffer.append(" >");
        if(alookup != null)
        {
            oracle.apps.fnd.security.AolSecurity aolsecurity = new AolSecurity();
            java.lang.String s5 = "";
            java.lang.String s9 = oracle.apps.bis.pmv.common.LookUpHelper.decodeIdValue(s2)[0];
            boolean flag2 = false;
            if(s1 != null)
            {
                if(s1.indexOf("ORGANIZATION+JTF_ORG_SALES_GROUP") > 0 && s9.equals("-1111"))
                    flag2 = true;
                if(s1.indexOf("ORGANIZATION+JTF_ORG_INTERACTION_CENTER_GRP") > 0 && s9.equals("-1111"))
                    flag2 = true;
            }
            int i = alookup.length;
            for(int j = 0; j < i; j++)
            {
                if(j < 30)
                {
                    stringbuffer.append("<OPTION ");
                    if(!flag1 && oracle.apps.bis.pmv.common.LookUpHelper.decodeIdValue(alookup[j].getCode())[0].equals(s9))
                    {
                        stringbuffer.append(" SELECTED ");
                        flag1 = true;
                    }
                    stringbuffer.append("value=\"");
                    java.lang.String s6;
                    if(flag)
                        s6 = od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getEncryptedCode(alookup[j].getCode(), aolsecurity);
                    else
                        s6 = alookup[j].getCode();
                    stringbuffer.append(s6);
                    stringbuffer.append("\">");
                    stringbuffer.append(alookup[j].getMeaning());
                    continue;
                }
                if(flag1 || !oracle.apps.bis.pmv.common.LookUpHelper.decodeIdValue(alookup[j].getCode())[0].equals(s9))
                    continue;
                stringbuffer.append("<OPTION ");
                stringbuffer.append(" SELECTED ");
                flag1 = true;
                stringbuffer.append("value=\"");
                java.lang.String s7;
                if(flag)
                    s7 = od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getEncryptedCode(alookup[j].getCode(), aolsecurity);
                else
                    s7 = alookup[j].getCode();
                stringbuffer.append(s7);
                stringbuffer.append("\">");
                stringbuffer.append(alookup[j].getMeaning());
                break;
            }

            if(s9 != null && !"".equals(s9) && !s9.equals(s2) && !flag1 && !flag2)
            {
                java.lang.String s8;
                if(flag)
                    s8 = od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getEncryptedCode(s2, aolsecurity);
                else
                    s8 = s2;
                stringbuffer.append("<OPTION SELECTED value=\"").append(s8).append("\">");
                stringbuffer.append(oracle.apps.bis.pmv.common.LookUpHelper.decodeIdValue(s2)[1]);
            }
            if(alookup.length > 30 || oracle.apps.bis.pmv.common.StringUtil.in(s4, oracle.apps.bis.pmv.common.PMVConstants.VALID_SEARCH_REQ_LOV_DIMS))
                stringbuffer.append("<OPTION value=\"^*^MORE^*^\">").append(s3);
        }
        stringbuffer.append("</SELECT>");
        stringbuffer.append("</LABEL>");
        return stringbuffer.toString();
    }

    public static java.lang.String getSimplePopListFromLookUp(java.lang.String s, java.lang.String s1, java.lang.String s2, com.sun.java.util.collections.ArrayList arraylist, boolean flag)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(200);
        java.lang.String as[] = null;
        if(s2 != null)
            as = oracle.apps.bis.pmv.common.StringUtil.tokenize(s2, ",");
        stringbuffer.append("<LABEL>");
        stringbuffer.append("<SELECT class=OraInstructionText NAME=" + s);
        if(flag)
            stringbuffer.append(" MULTIPLE");
        stringbuffer.append(" >");
        if(s2 == null)
        {
            stringbuffer.append("<OPTION SELECTED value=\"").append(s1).append("\">");
            stringbuffer.append(s1);
        } else
        {
            stringbuffer.append("<OPTION value=\"").append(s1).append("\">");
            stringbuffer.append(s1);
        }
        if(arraylist != null)
        {
            java.lang.String s3 = "";
            int i = arraylist.size();
            for(int j = 0; j < i; j++)
            {
                oracle.apps.bis.pmv.common.LookUp lookup = (oracle.apps.bis.pmv.common.LookUp)arraylist.get(j);
                stringbuffer.append("<OPTION ");
                java.lang.String s4 = lookup.getCode();
                if(!flag)
                {
                    if(s2 != null && s2.equals(s4))
                        stringbuffer.append(" SELECTED ");
                } else
                if(as != null && oracle.apps.bis.pmv.common.StringUtil.in(s4, as))
                    stringbuffer.append(" SELECTED ");
                stringbuffer.append("value=\"");
                stringbuffer.append(s4);
                stringbuffer.append("\">");
                stringbuffer.append(lookup.getMeaning());
            }

        }
        stringbuffer.append("</SELECT>");
        stringbuffer.append("</LABEL>");
        return stringbuffer.toString();
    }

    public static java.lang.String getPortletPopList(java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, com.sun.java.util.collections.ArrayList arraylist, boolean flag, java.lang.String s4, java.lang.String s5)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        stringbuffer.append(" <TABLE class=DbiParameterTable style=\"DISPLAY: inline\" cellSpacing=0 cellPadding=1 border=0 summary=\"\">");
        stringbuffer.append("<TBODY>");
        stringbuffer.append("<TR>");
        stringbuffer.append("<TD class=OraInstructionText noWrap>").append(s).append("</TD>");
        stringbuffer.append("<TD class=OraInstructionText noWrap>");
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getPopList(s1, s2, s3, arraylist, true, flag, s4, s5));
        stringbuffer.append("<TD align=middle width=10>&nbsp;</TD>");
        stringbuffer.append("</TR>");
        stringbuffer.append("</TBODY>");
        stringbuffer.append("</TABLE>");
        return stringbuffer.toString();
    }

    public static java.lang.String getPortletPopList(java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, com.sun.java.util.collections.ArrayList arraylist, com.sun.java.util.collections.ArrayList arraylist1, java.lang.String s4)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        stringbuffer.append(" <TABLE class=DbiParameterTable style=\"DISPLAY: inline\" cellSpacing=0 cellPadding=1 border=0 summary=\"\">");
        stringbuffer.append("<TBODY>");
        stringbuffer.append("<TR>");
        stringbuffer.append("<TD class=OraInstructionText noWrap>").append(s).append("</TD>");
        stringbuffer.append("<TD class=OraInstructionText noWrap>");
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getPopList(s1, s2, s3, arraylist, arraylist1, s4));
        stringbuffer.append("<TD align=middle width=10>&nbsp;</TD>");
        stringbuffer.append("</TR>");
        stringbuffer.append("</TBODY>");
        stringbuffer.append("</TABLE>");
        return stringbuffer.toString();
    }

    public static java.lang.String getPopList(java.lang.String s, java.lang.String s1, com.sun.java.util.collections.ArrayList arraylist, com.sun.java.util.collections.ArrayList arraylist1, java.lang.String s2)
    {
        return od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getPopList(s, s1, null, arraylist, arraylist1, s2);
    }

    public static java.lang.String getPopList(java.lang.String s, java.lang.String s1, java.lang.String s2, com.sun.java.util.collections.ArrayList arraylist, com.sun.java.util.collections.ArrayList arraylist1, java.lang.String s3)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        java.lang.String s4 = "";
        stringbuffer.append("<LABEL>");
        stringbuffer.append("<SELECT class=OraInstructionText NAME=" + s);
        if(s2 != null && s2.length() > 0)
            stringbuffer.append(" onChange=").append(s2);
        stringbuffer.append(" >");
        int i = arraylist1.size();
        if(i > 30)
            i = 30;
        for(int j = 0; j < i; j++)
            if(!"".equals((java.lang.String)arraylist.get(j)) || !"pParameterViewBy".equals(s))
            {
                stringbuffer.append("  <OPTION ");
                if(((java.lang.String)arraylist.get(j)).equals(s1))
                    stringbuffer.append(" SELECTED ");
                stringbuffer.append("value=\"");
                stringbuffer.append((java.lang.String)arraylist.get(j));
                stringbuffer.append("\">");
                if("pParameterViewBy".equals(s))
                {
                    java.lang.String s5 = (java.lang.String)arraylist1.get(j);
                    if(s5.indexOf("-") >= 0)
                        stringbuffer.append(s5.substring(s5.indexOf("-") + 1));
                    else
                        stringbuffer.append(s5);
                } else
                {
                    stringbuffer.append(arraylist1.get(j));
                }
            }

        if(arraylist1.size() > 30)
            stringbuffer.append("<OPTION value=\"^*^MORE^*^\">").append(s3);
        stringbuffer.append("</SELECT>");
        stringbuffer.append("</LABEL>");
        return stringbuffer.toString();
    }

    public static java.lang.String getLovString(int i, java.lang.String s, int j, oracle.apps.bis.pmv.session.UserSession usersession, java.lang.String s1, java.lang.String s2)
    {
        return od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getLovString(i, s, j, usersession, s1, s2, null);
    }

    public static java.lang.String getLovString(int i, java.lang.String s, int j, oracle.apps.bis.pmv.session.UserSession usersession, java.lang.String s1, java.lang.String s2, java.lang.String s3)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        stringbuffer.append("<a href=javascript:openLovWindow(window.parameterForm.pParameter");
        stringbuffer.append(i);
        if(j > 1)
        {
            stringbuffer.append(".options[window.parameterForm.pParameter");
            stringbuffer.append(i);
            stringbuffer.append(".options.selectedIndex]");
        }
        stringbuffer.append(".value,'pParameterValue");
        stringbuffer.append(i).append("','");
        stringbuffer.append(s1).append("','");
        stringbuffer.append(s2).append("');");
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getOnMouseOverHtml(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_RG_LOV", "PARAM_NAME", s, usersession.getWebAppsContext())));
        stringbuffer.append(" return true\"\"");
        if(s3 != null && s3.length() > 0)
            stringbuffer.append(" onClick=\"" + s3 + "; return true\"");
        stringbuffer.append(">");
        stringbuffer.append("<img src=" + usersession.getImageServer() + "BISILOV.gif border=0");
        stringbuffer.append(" align=absmiddle ");
        stringbuffer.append(" alt=\"");
        oracle.apps.fnd.common.WebAppsContext webappscontext = usersession.getWebAppsContext();
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_LOV", webappscontext));
        stringbuffer.append("\" title=\"");
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_LOV", webappscontext));
        stringbuffer.append("\">");
        stringbuffer.append("</a>");
        return stringbuffer.toString();
    }

    public static java.lang.String getTimeLovString(int i, java.lang.String s, int j, oracle.apps.bis.pmv.session.UserSession usersession, int k, int l, java.lang.String s1, boolean flag)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        oracle.apps.fnd.common.WebAppsContext webappscontext = usersession.getWebAppsContext();
        java.lang.String s2 = usersession.getAKRegion().getParameterLayoutType();
        java.lang.String s3 = "";
        if(!flag && ("1".equals(s2) || "3".equals(s2)))
            s3 = "RUN";
        stringbuffer.append("");
        stringbuffer.append("<a href=javascript:openLovWindow(window.parameterForm.pTimeParameter");
        if(j > 1)
            stringbuffer.append(".options[window.parameterForm.pTimeParameter.options.selectedIndex]");
        stringbuffer.append(".value,'").append(s1).append("','" + s3 + "','TIME')");
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getOnMouseOverHtml(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_RG_LOV", "PARAM_NAME", s, webappscontext)));
        stringbuffer.append(" return true\">");
        stringbuffer.append("<img src=");
        stringbuffer.append(usersession.getImageServer() + "BISILOV.gif border=0");
        stringbuffer.append(" align=absmiddle ");
        stringbuffer.append(" alt=\"");
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_LOV", webappscontext));
        stringbuffer.append("\" title=\"");
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_LOV", webappscontext));
        stringbuffer.append("\">");
        stringbuffer.append("</a>");
        return stringbuffer.toString();
    }

    public static java.lang.String getDynamicPageParamLovString(int i, java.lang.String s)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(200);
        stringbuffer.append("+\"&pAttrCode=\" + escape(escape(window.parameterForm.pParameter").append(i);
        stringbuffer.append(".value)).replace(\"+\",\"%2B\")+\"&pAttrValue=\" + ");
        stringbuffer.append("escape(escape(\"").append(s).append("\")).replace(\"+\",\"%2B\")");
        return stringbuffer.toString();
    }

    public static java.lang.String getDynamicLovString(int i, int j)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(200);
        stringbuffer.append("+\"&pAttrCode=\" + escape(escape(window.parameterForm.pParameter").append(i);
        if(j > 1)
            stringbuffer.append(".options[window.parameterForm.pParameter").append(i).append(".options.selectedIndex]");
        stringbuffer.append(".value)).replace(\"+\",\"%2B\")+\"&pAttrValue=\" + escape(escape(window.parameterForm.pParameterValue").append(i).append(".value)).replace(\"+\",\"%2B\")");
        return stringbuffer.toString();
    }

    public static java.lang.String getDynamicTimeLovString(int i)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(300);
        stringbuffer.append("+\"&pAttrCode=\"+escape(window.parameterForm.pTimeParameter");
        if(i > 1)
            stringbuffer.append(".options[window.parameterForm.pTimeParameter.options.selectedIndex]");
        stringbuffer.append(".value).replace(\"+\",\"%2B\")+\"&pAttrValue=\"+escape(window.parameterForm.pTimeFromParameter.value).replace(\"+\",\"%2B\")");
        return stringbuffer.toString();
    }

    public static java.lang.String getTimeInpString(java.lang.String s, java.lang.String s1, java.lang.String s2)
    {
        return od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getTextInpString(s, s1, "10", s2);
    }

    public static java.lang.String getTextInpString(java.lang.String s, java.lang.String s1, java.lang.String s2)
    {
        java.lang.String s3 = oracle.apps.bis.common.Util.escapeHTML(s1, "<br>");
        int i = s3.length() + 4;
        return od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getTextInpString(s, s1, java.lang.String.valueOf(i), s2);
    }

    public static java.lang.String getTextInpString(java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append("<LABEL style=\"display:none\" for=\"").append(s).append("\">.</LABEL>");
        stringbuffer.append("<INPUT TYPE=text id=\"").append(s).append("\" NAME=\"").append(s).append("\" SIZE=").append(s2);
        if(s3 != null)
        {
            stringbuffer.append(" onKeyDown=\"").append(s3).append("\"");
            stringbuffer.append(" onMouseDown=\"").append(s3).append("\"");
        }
        java.lang.String s4 = oracle.apps.bis.common.Util.escapeHTML(s1, "<br>");
        stringbuffer.append(" title=\"").append(s4).append("\"");
        stringbuffer.append(" VALUE=\"").append(s4).append("\">");
        return stringbuffer.toString();
    }

    public static java.lang.String getTextInpString(java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, java.lang.String s4, java.lang.String s5, boolean flag)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append("<LABEL style=\"display:none\" for=\"").append(s).append("\">.</LABEL>");
        stringbuffer.append("<INPUT TYPE=text id=\"").append(s).append("\" NAME=\"").append(s).append("\"");
        if(flag)
        {
            stringbuffer.append(" readonly=\"true\" ");
            stringbuffer.append(" onmouseover=\"itmMovr('").append(s).append("')\" ");
        }
        if(s5 != null)
            stringbuffer.append(" SIZE=").append(s5);
        if(s2 != null)
            stringbuffer.append(" style=\"width:").append(s2).append("cm;\"");
        if(s4 != null)
            stringbuffer.append(" onClick=\"").append(s4).append("\"");
        if(s3 != null)
        {
            stringbuffer.append(" onKeyDown=\"").append(s3).append("\"");
            stringbuffer.append(" onMouseDown=\"").append(s3).append("\"");
        }
        java.lang.String s6 = oracle.apps.bis.common.Util.escapeHTML(s1, "<br>");
        stringbuffer.append(" title=\"").append(s6).append("\"");
        stringbuffer.append(" VALUE=\"").append(s6).append("\">");
        return stringbuffer.toString();
    }

    public static java.lang.String getText(java.lang.String s, java.lang.String s1, java.lang.String s2)
    {
        return od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getText(s, s1, s2, null);
    }

    public static java.lang.String getText(java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(150);
        stringbuffer.append("<INPUT type=hidden name=");
        stringbuffer.append(s);
        stringbuffer.append(" value=\"");
        stringbuffer.append(s1);
        stringbuffer.append("\">");
        if(s3 != null)
            stringbuffer.append(s3);
        else
            stringbuffer.append("<font face=Arial size=2><LABEL>");
        stringbuffer.append(s2);
        stringbuffer.append("</b></font>");
        return stringbuffer.toString();
    }

    public static java.lang.String getFontText(java.lang.String s, java.lang.String s1)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        if(s1 != null)
            stringbuffer.append(s1);
        else
            stringbuffer.append("<font face=Arial size=2><LABEL>");
        stringbuffer.append(s);
        stringbuffer.append("</b></font>");
        return stringbuffer.toString();
    }

    public static java.lang.String getHiddenField(java.lang.String s, java.lang.String s1)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(150);
        stringbuffer.append("<INPUT type=hidden name=");
        stringbuffer.append(s);
        stringbuffer.append(" value=\"");
        stringbuffer.append(s1);
        stringbuffer.append("\">");
        return stringbuffer.toString();
    }

    public static java.lang.String getHiddenIdField(java.lang.String s, java.lang.String s1)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(150);
        stringbuffer.append("<INPUT type=hidden id=\"");
        stringbuffer.append(s);
        stringbuffer.append("\" name=\"").append(s).append("\" value=\"");
        stringbuffer.append(s1);
        stringbuffer.append("\">");
        return stringbuffer.toString();
    }

    public static java.lang.String getSectionHeader(java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append("<TABLE border=0 cellpadding=0 cellspacing=0 width=98% summary=\"\">");
        stringbuffer.append("<TR >");
        stringbuffer.append("<TD class=\"").append(s1).append("\">");
        stringbuffer.append(s).append("</TD></TR>");
        stringbuffer.append("<TR >");
        stringbuffer.append("<TD colspan=2 class=\"OraBGAccentDark\">");
        stringbuffer.append("<img src=\"").append(s2);
        stringbuffer.append("bisspace.gif\" alt=\"\" width=400 height=1></TD>");
        stringbuffer.append("</TR>");
        if(s3 != null)
            stringbuffer.append("<TR><TD class=\"OraInstructionText\">").append(s3).append("</TD></TR>");
        stringbuffer.append("</TABLE>");
        return stringbuffer.toString();
    }

    public static java.lang.String getDottedLine(oracle.apps.bis.pmv.session.UserSession usersession)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append("<table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\"  summary=\"\">");
        stringbuffer.append("<TR>");
        stringbuffer.append("<td height=\"3\"");
        stringbuffer.append(" background=\"");
        stringbuffer.append(usersession.getImageServer());
        stringbuffer.append("bisdots.gif\"");
        stringbuffer.append(" alt=\"\" width=\"100%\" colspan=\"6\">");
        stringbuffer.append("<img src=");
        stringbuffer.append(usersession.getImageServer());
        stringbuffer.append("bisspace.gif alt=\"\" height=\"3\"></td>");
        stringbuffer.append("</TR>");
        stringbuffer.append("</table>");
        return stringbuffer.toString();
    }

    public static java.lang.String getPdfDottedLine(oracle.apps.bis.pmv.session.UserSession usersession)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append("<dottedline icon=\"");
        stringbuffer.append(usersession.getImageServer());
        stringbuffer.append("bisdots.gif\" alt=\"\" >");
        stringbuffer.append("</dottedline>");
        return stringbuffer.toString();
    }

    public static java.lang.String getScheduleUrl(oracle.apps.fnd.common.WebAppsContext webappscontext, oracle.apps.bis.pmv.session.UserSession usersession, java.lang.String s)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getJspAgent(webappscontext));
        stringbuffer.append("bissched.jsp?pRegionCode=");
        stringbuffer.append(usersession.getRegionCode());
        stringbuffer.append("&functionName=");
        stringbuffer.append(usersession.getFunctionName());
        stringbuffer.append("&requestType=R&plugId=&reportTitle=&graphType=");
        stringbuffer.append("&dbc=").append(s);
        stringbuffer.append("sessionid=").append(webappscontext.getCurrentSessionId());
        return stringbuffer.toString();
    }

    public static java.lang.String getMessageUrl(oracle.apps.fnd.common.WebAppsContext webappscontext, oracle.apps.bis.pmv.session.UserSession usersession, java.lang.String s)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getJspAgent(webappscontext));
        stringbuffer.append("bismessg.jsp?dbc=").append(s);
        stringbuffer.append("&sessionid=").append(webappscontext.getCurrentSessionId());
        stringbuffer.append("&message=BIS_DEFAULTS_SAVED&header=CONFIRMATION_PAGE&pageTitle=CONFIRMATION&regionCode=");
        stringbuffer.append(usersession.getRegionCode());
        return stringbuffer.toString();
    }

    public static java.lang.String getPrintParam(java.lang.String s, java.lang.String s1, boolean flag, java.lang.String s2)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(2000);
        stringbuffer.append("<td valign=middle align=right class=OraPromptText nowrap>");
        stringbuffer.append(s);
        stringbuffer.append("&nbsp;</td><td valign=middle  class=OraDataText>");
        stringbuffer.append(s1);
        if(flag)
            stringbuffer.append("-").append(s2);
        stringbuffer.append("&nbsp;&nbsp;&nbsp;</td>");
        return stringbuffer.toString();
    }

    public static java.lang.String getPrintParamSchedule(java.lang.String s, java.lang.String s1, boolean flag, java.lang.String s2)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(2000);
        stringbuffer.append("<td valign=middle align=right class=OraPromptText nowrap>");
        stringbuffer.append(s);
        stringbuffer.append(" </td><td>&nbsp;&nbsp;</td> <td valign=middle class=OraDataText>");
        stringbuffer.append(s1);
        if(flag)
            stringbuffer.append("-").append(s2);
        stringbuffer.append("</td>");
        return stringbuffer.toString();
    }

    public static java.lang.String getReportFooter(oracle.apps.fnd.common.WebAppsContext webappscontext, javax.servlet.ServletContext servletcontext, oracle.apps.bis.pmv.session.UserSession usersession)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append("<INPUT TYPE=hidden name=printable value=>");
        stringbuffer.append("<TABLE border=0 cellspacing=0,cellpadding=4 WIDTH=\"99%\" summary=\"\">");
        java.lang.String s = "";
        if(webappscontext.getCurrLangCode() != null)
            s = webappscontext.getCurrLangCode();
        if(s.equals("AR") || s.equals("IW"))
        {
            stringbuffer.append("<TR>");
            stringbuffer.append("<TD align=left width=\"90%\">&nbsp;</td>");
            stringbuffer.append("<TD align=left valign=\"top\" width=\"10%\">");
            stringbuffer.append("<table cellpadding=\"0\" cellspacing=\"0\" align=\"left\" border=\"0\" summary=\"\" >");
        } else
        {
            stringbuffer.append("<TR>");
            stringbuffer.append("<TD align=right width=\"90%\">&nbsp;</td>");
            stringbuffer.append("<TD align=right valign=\"top\" width=\"10%\">");
            stringbuffer.append("<table cellpadding=\"0\" cellspacing=\"0\" align=\"right\" border=\"0\" summary=\"\">");
        }
        stringbuffer.append("<tr><td noWrap valign=\"top\">");
        if(usersession.getAKRegion() != null && !usersession.getAKRegion().isEDW())
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getListOfViewHtml(usersession, true));
        stringbuffer.append("</TD><TD noWrap valign=\"top\">");
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getListOfQCHtml(usersession, true));
        stringbuffer.append("</TD>");
        java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_ACTIONS", webappscontext);
        stringbuffer.append("<TD noWrap vAlign=\"top\">&nbsp;&nbsp;");
        stringbuffer.append("<A class=\"OraCrumbsEnabled\" id=\"ActionImage\" name=\"ActionImage\"");
        stringbuffer.append(" onmousedown=clkDown(event) onkeydown=clkDown(event)");
        stringbuffer.append(" style=\"CURSOR: hand; TEXT-DECORATION: none\"");
        stringbuffer.append(" onclick=\"menuControlClick(event, 'VMenu1', 'ActionImage', '');return false;\"");
        stringbuffer.append(" href=\"javascript:menuControlClick(event, 'VMenu1', 'ActionImage', '');\">").append(s1);
        stringbuffer.append("&nbsp;<IMG title=\"").append(s1).append(" \" alt=\"").append(s1).append(" \"");
        stringbuffer.append(" src=\"/OA_MEDIA/bisdarr.gif\" border=0></A>");
        stringbuffer.append("</TD></TR></TABLE>");
        stringbuffer.append("</TD></TR></TABLE>");
        return stringbuffer.toString();
    }

    public static java.lang.String getQCFooter(oracle.apps.fnd.common.WebAppsContext webappscontext, javax.servlet.ServletContext servletcontext, oracle.apps.bis.pmv.session.UserSession usersession)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append("<INPUT TYPE=hidden name=printable value=>");
        stringbuffer.append("<TABLE border=0 cellspacing=0,cellpadding=4 WIDTH=\"99%\" summary=\"\">");
        java.lang.String s = "";
        if(webappscontext.getCurrLangCode() != null)
            s = webappscontext.getCurrLangCode();
        if(s.equals("AR") || s.equals("IW"))
        {
            stringbuffer.append("<TR>");
            stringbuffer.append("<TD align=left width=\"90%\">&nbsp;</td>");
            stringbuffer.append("<TD align=left valign=\"top\" width=\"10%\">");
            stringbuffer.append("<table cellpadding=\"0\" cellspacing=\"0\" align=\"left\" border=\"0\" summary=\"\" >");
        } else
        {
            stringbuffer.append("<TR>");
            stringbuffer.append("<TD align=right width=\"90%\">&nbsp;</td>");
            stringbuffer.append("<TD align=right valign=\"top\" width=\"10%\">");
            stringbuffer.append("<table cellpadding=\"0\" cellspacing=\"0\" align=\"right\" border=\"0\" summary=\"\">");
        }
        stringbuffer.append("<tr><td noWrap valign=\"top\">");
        /*if(usersession.getAKRegion() != null && !usersession.getAKRegion().isEDW())
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getListOfViewHtml(usersession, true));
        stringbuffer.append("</TD><TD noWrap valign=\"top\">");
        */
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getListOfQCHtml(usersession, true));
        stringbuffer.append("</TD>");
        /*
        java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_ACTIONS", webappscontext);
        stringbuffer.append("<TD noWrap vAlign=\"top\">&nbsp;&nbsp;");
        stringbuffer.append("<A class=\"OraCrumbsEnabled\" id=\"ActionImage\" name=\"ActionImage\"");
        stringbuffer.append(" onmousedown=clkDown(event) onkeydown=clkDown(event)");
        stringbuffer.append(" style=\"CURSOR: hand; TEXT-DECORATION: none\"");
        stringbuffer.append(" onclick=\"menuControlClick(event, 'VMenu1', 'ActionImage', '');return false;\"");
        stringbuffer.append(" href=\"javascript:menuControlClick(event, 'VMenu1', 'ActionImage', '');\">").append(s1);
        stringbuffer.append("&nbsp;<IMG title=\"").append(s1).append(" \" alt=\"").append(s1).append(" \"");
        stringbuffer.append(" src=\"/OA_MEDIA/bisdarr.gif\" border=0></A>");
        stringbuffer.append("</TD></TR></TABLE>");
        */
        stringbuffer.append("</TD></TR></TABLE>");
        return stringbuffer.toString();
    }

    public static java.lang.String getLovReportFooter(oracle.apps.fnd.common.WebAppsContext webappscontext, javax.servlet.ServletContext servletcontext, oracle.apps.bis.pmv.session.UserSession usersession)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append("<TABLE border=0 cellspacing=0 cellpadding=4 WIDTH=\"99%\"  summary=\"\">");
        java.lang.String s = "";
        if(webappscontext.getCurrLangCode() != null)
            s = webappscontext.getCurrLangCode();
        if(s.equals("AR") || s.equals("IW"))
            stringbuffer.append("<TR><TD align=left>");
        else
            stringbuffer.append("<TR><TD align=right>");
        java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_CANCEL", webappscontext);
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getButtonHTML("javascript:self.close()", s1, s1, s1, webappscontext, usersession.getApplication(), usersession));
        stringbuffer.append(" &nbsp;");
        stringbuffer.append("<A HREF=javascript:closeLovWindow();");
        s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_SELECT", webappscontext);
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getOnMouseOverHtml(s1));
        stringbuffer.append(" return true\"\">");
        stringbuffer.append("<img src=\"");
        stringbuffer.append(oracle.apps.bis.common.Util.generateButtonGif(s1, webappscontext, servletcontext, usersession.getRequest(), usersession.getPageContext(), usersession.getConnection()));
        stringbuffer.append("\" ALT=\"").append(s1);
        stringbuffer.append("\" TITLE=\"").append(s1);
        stringbuffer.append("\" border=0>");
        stringbuffer.append("</a>&nbsp;</TD></TR></TABLE>");
        return stringbuffer.toString();
    }

    public static java.lang.String getPrintableTable(oracle.apps.fnd.common.WebAppsContext webappscontext, javax.servlet.ServletContext servletcontext, oracle.apps.bis.pmv.session.UserSession usersession)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append("<INPUT TYPE=hidden name=printable value=>");
        stringbuffer.append("<TABLE border=0 cellspacing=0,cellpadding=4 WIDTH=\"99%\"  summary=\"\">");
        java.lang.String s = "";
        if(webappscontext.getCurrLangCode() != null)
            s = webappscontext.getCurrLangCode();
        if(s.equals("AR") || s.equals("IW"))
            stringbuffer.append("<TR><TD align=left>");
        else
            stringbuffer.append("<TR><TD align=right>");
        stringbuffer.append("<A HREF=javascript:doSubmit(\"PRINTABLE\");");
        java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_PRINTER_FRIENDLY", webappscontext);
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getOnMouseOverHtml(s1));
        stringbuffer.append(" return true\"\">");
        java.lang.String s2 = "";
        s2 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_PRINTABLE_PAGE", webappscontext);
        stringbuffer.append("<img src=\"");
        stringbuffer.append(oracle.apps.bis.common.Util.generateButtonGif(s2, webappscontext, servletcontext, usersession.getRequest(), usersession.getPageContext(), usersession.getConnection()));
        stringbuffer.append("\" ALT=\"").append(s1);
        stringbuffer.append("\" TITLE=\"").append(s1);
        stringbuffer.append("\" border=0>");
        stringbuffer.append("</a>&nbsp;</TD></TR></TABLE>");
        return stringbuffer.toString();
    }

    public static java.lang.String getSkiImage(oracle.apps.bis.pmv.session.UserSession usersession, oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        java.lang.String s = usersession.getImageServer();
        java.lang.String s1 = "";
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append("<TABLE width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\"  summary=\"\">");
        stringbuffer.append("<TR>");
        stringbuffer.append("<TD  width=\"604\">&nbsp</TD>");
        stringbuffer.append("<TD ROWSPAN=\"2\"  valign=\"bottom\" width=\"12\">");
        try
        {
            if(webappscontext.getCurrLangCode() != null)
                s1 = webappscontext.getCurrLangCode();
        }
        catch(java.lang.Exception _ex) { }
        if(s1.equals("AR") || s1.equals("IW"))
            stringbuffer.append("<IMG SRC=\"").append(s).append("bislghrm.gif\" alt=\"\" width=\"12\" height=\"14\"></TD>");
        else
            stringbuffer.append("<IMG SRC=\"").append(s).append("bisslghr.gif\" alt=\"\" width=\"12\" height=\"14\"></TD>");
        stringbuffer.append("</TR>").append(" <TR>");
        stringbuffer.append("<TD bgcolor=\"#CCCC99\" height=\"1\"><IMG SRC=\"");
        stringbuffer.append(s).append("bisspace.gif\" alt=\"\" height=1 width=1></TD>");
        stringbuffer.append("</TR> </TABLE>");
        return stringbuffer.toString();
    }

    public static java.lang.String getCopyRight(oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append("<TABLE><TR><TD class=\"OraCopyright\" width=\"99%\"  summary=\"\">");
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BISCPYRT", webappscontext)).append(" </TD></TR></TABLE>");
        return stringbuffer.toString();
    }

    public static java.lang.String getTableNavigation(oracle.apps.bis.pmv.session.UserSession usersession, int i, java.lang.String s, int j, int k, int l, boolean flag)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        oracle.apps.fnd.common.WebAppsContext webappscontext = usersession.getWebAppsContext();
        od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getJspAgent(webappscontext);
        java.lang.String s1 = "";
        if(webappscontext.getCurrLangCode() != null)
            s1 = webappscontext.getCurrLangCode();
        java.lang.String s2 = usersession.getImageServer();
        java.lang.String s3 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_SHOW_SET", webappscontext);
        java.lang.String s4 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_SHOW_ALL", webappscontext);
        java.lang.String s5 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_PREVIOUS", webappscontext);
        java.lang.String s6 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_TABLE_NEXT", webappscontext);
        stringbuffer.append("<TR><td><table border=0 cellpadding=3 cellspacing=0 width=100%  summary=\"\"><tbody>");
        stringbuffer.append("<tr valign=middle>");
        if("ALL".equals(s))
        {
            stringbuffer.append("<td ><div >");
            stringbuffer.append("<a href=\"javascript:searchTable('SET')\" return true\"\">");
            stringbuffer.append("<span class=OraGlobalButtonText>").append(s3).append("</span></a></div></td>");
        } else
        {
            if(i > j)
            {
                stringbuffer.append("<td ><div >");
                stringbuffer.append("<a href=\"javascript:searchTable('ALL')\"  return true\"\">");
                stringbuffer.append("<span class=OraGlobalButtonText>").append(s4).append("</span></a></div></td>");
            } else
            {
                stringbuffer.append("<td >&nbsp;</td>");
            }
            if(k <= 1)
            {
                if(s1.equals("AR") || s1.equals("IW"))
                    stringbuffer.append("<td align=right width=1%><font size=1><img align=textTop src=").append(s2).append("bisnextd.gif></font></td>");
                else
                    stringbuffer.append("<td align=right width=1%><font size=1><img align=textTop src=").append(s2).append("bisprevd.gif></font></td>");
                stringbuffer.append("<td align=right width=3%><div ><span class=OraGlobalButtonTextDisabled>").append(s5).append("</span></div></td>");
            } else
            {
                stringbuffer.append("<td align=right width=1%><a href=\"javascript:searchTable('PREVIOUS')\" return true\"\">");
                stringbuffer.append("<font size=1><img align=textTop src=").append(s2).append("bispreva.gif ALT=\"").append(s5).append("\" TITLE=\"").append(s5).append("\" border=0></font></a></td>");
                stringbuffer.append("<td align=right width=3%><div >");
                stringbuffer.append("<a href=\"javascript:searchTable('PREVIOUS')\"  return true\"\">");
                stringbuffer.append("<span class=OraGlobalButtonText>").append(s5).append("</span></a></div></td>");
            }
            stringbuffer.append("<td nowrap align=right width=3%><div align=center>");
            if(!flag)
                stringbuffer.append("<span class=OraGlobalButtonTextSelected><font size=2>").append(k + 1).append("-").append(l).append(" of ").append(i).append("</font></span></div></td>");
            boolean flag1 = flag && j < i || !flag && l < i;
            if(!flag1)
            {
                stringbuffer.append("<td align=right width=3%><div align=right>");
                stringbuffer.append("<span class=OraGlobalButtonTextDisabled>").append(s6).append("</span></div></td>");
                stringbuffer.append("<td align=right width=1%><font size=1>");
                if(s1.equals("AR") || s1.equals("IW"))
                    stringbuffer.append("<img align=textTop src=").append(s2).append("bisprevd.gif></font></td>");
                else
                    stringbuffer.append("<img align=textTop src=").append(s2).append("bisnextd.gif></font></td>");
            } else
            {
                stringbuffer.append("<td align=right width=3%><div align=right>");
                stringbuffer.append("<a href=\"javascript:searchTable('NEXT')\"  return true\"\">");
                stringbuffer.append("<span class=OraGlobalButtonText>").append(s6).append("</span></a></div></td>");
                stringbuffer.append("<td align=right width=1%>");
                stringbuffer.append("<a href=\"javascript:searchTable('NEXT')\"  return true\"\">");
                stringbuffer.append("<font size=1><img align=textTop src=").append(s2).append("bisnexta.gif ALT=\"").append(s6).append("\" TITLE=\"").append(s6).append("\" border=0></font></a></td>");
            }
        }
        stringbuffer.append("</tr></tbody></table></td></TR>");
        return stringbuffer.toString();
    }

    public static java.lang.String getCustomizeLink(oracle.apps.bis.pmv.session.UserSession usersession, java.lang.String s, java.lang.String s1, java.lang.String s2, oracle.apps.fnd.common.WebAppsContext webappscontext, javax.servlet.ServletContext servletcontext)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(300);
        stringbuffer.append(" <a href=\"");
        java.lang.String s3 = webappscontext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getJspAgent(webappscontext));
        stringbuffer.append("OA.jsp?akRegionCode=BISPMVDUMMYPAGE");
        stringbuffer.append("&akRegionApplicationId=191");
        try
        {
            stringbuffer.append("&custRegionCode=").append(oracle.cabo.share.url.EncoderUtils.encodeString(usersession.getRegionCode(), s3));
            stringbuffer.append("&custRegionApplId=").append(usersession.getAKRegion().getRegionApplicationId());
            stringbuffer.append("&levelId=60");
            stringbuffer.append("&_backurl=..\\XXCRM_HTML\\bisviewm.jsp");
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("?dbc=", s3)).append(oracle.cabo.share.url.EncoderUtils.encodeString(usersession.getRequestInfo().getDBC(), s3));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&transactionid=", s3)).append(oracle.cabo.share.url.EncoderUtils.encodeString(usersession.getTransactionId(), s3));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&sessionid=", s3)).append(oracle.cabo.share.url.EncoderUtils.encodeString(usersession.getSessionId(), s3));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&regionCode=", s3)).append(oracle.cabo.share.url.EncoderUtils.encodeString(usersession.getRegionCode(), s3));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&functionName=", s3)).append(oracle.cabo.share.url.EncoderUtils.encodeString(usersession.getFunctionName(), s3));
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&pFirstTime=", s3)).append("0");
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&language_code=", s3)).append(webappscontext.getCurrLangCode());
            stringbuffer.append(oracle.cabo.share.url.EncoderUtils.encodeString("&pMode=", s3)).append(usersession.getRequestInfo().getMode());
            stringbuffer.append("&dbc=").append(usersession.getRequestInfo().getDBC());
            stringbuffer.append("&language=").append(webappscontext.getCurrLangCode());
            stringbuffer.append("&transactionid=").append(usersession.getTransactionId());
            stringbuffer.append("&menu=Y");
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getOnMouseOverHtml(s));
            stringbuffer.append(" return true\"\">");
            stringbuffer.append("<img src=");
            stringbuffer.append(oracle.apps.bis.common.Util.generateButtonGif(s2, webappscontext, servletcontext, usersession.getRequest(), usersession.getPageContext(), usersession.getConnection()));
            stringbuffer.append(" ALT=\"");
            stringbuffer.append(s1 + " ");
            stringbuffer.append("\" TITLE=\"");
            stringbuffer.append(s1 + " ");
            stringbuffer.append("\" border=0></a>");
        }
        catch(java.io.UnsupportedEncodingException _ex) { }
        return stringbuffer.toString();
    }

    public static java.lang.String getStretchLine(oracle.apps.bis.pmv.session.UserSession usersession)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append("<TD valign=center><b><font size=4 face=Arial color=#336699>|</font></b></TD>");
        return stringbuffer.toString();
    }

    public static java.lang.String getSolidLine(oracle.apps.bis.pmv.session.UserSession usersession, int i, int j)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append("<TABLE cellSpacing=0 cellPadding=").append(j).append(" border=0 width=100%  summary=\"\">");
        stringbuffer.append("<TR><TD><IMG height=").append(i).append(" src=");
        stringbuffer.append(usersession.getImageServer()).append("bisbline.gif alt=\"\" width=100%></TD></TR></TABLE>");
        return stringbuffer.toString();
    }

    public static java.lang.String getCustomStyles()
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer("");
        stringbuffer.append("<STYLE TYPE=\"text/css\">");
        stringbuffer.append(".OraPmvTableColumnHeader {\tBACKGROUND-COLOR: #cccc99; COLOR: #336699; FONT-FAMILY: Arial, Helvetica, Geneva, sans-serif; FONT-SIZE: 10pt; FONT-WEIGHT: bold; TEXT-ALIGN: left; TEXT-INDENT: 1px; BORDER-BOTTOM: #f7f7e7 1px solid; BORDER-RIGHT: #f7f7e7 1px solid;}");
        stringbuffer.append(".OraPmvTableColumnHeaderNumber {\tBACKGROUND-COLOR: #cccc99; COLOR: #336699; FONT-FAMILY: Arial, Helvetica, Geneva, sans-serif; FONT-SIZE: 10pt; FONT-WEIGHT: bold; TEXT-ALIGN: right; TEXT-INDENT: 1px; BORDER-BOTTOM: #f7f7e7 1px solid; BORDER-RIGHT: #f7f7e7 1px solid;}");
        stringbuffer.append(".OraTableSortableColumnName {BACKGROUND-COLOR: #cccc99; COLOR: #336699; CURSOR: hand; FONT-FAMILY: Arial, Helvetica, Geneva, sans-serif; FONT-SIZE: 10pt; FONT-WEIGHT: bold; TEXT-ALIGN: left; TEXT-DECORATION: none; TEXT-INDENT: 1px;}");
        stringbuffer.append(".OraTableSortableColumnNameNumber {BACKGROUND-COLOR: #cccc99; COLOR: #336699; CURSOR: hand; FONT-FAMILY: Arial, Helvetica, Geneva, sans-serif; FONT-SIZE: 10pt; FONT-WEIGHT: bold; TEXT-ALIGN: right; TEXT-DECORATION: none; TEXT-INDENT: 1px;}");
        stringbuffer.append("A.OraPmvTableSortableColumnHeader:link {BACKGROUND-COLOR: #cccc99; COLOR: #336699; CURSOR: hand; FONT-FAMILY: Arial, Helvetica, Geneva, sans-serif; FONT-SIZE: 10pt; FONT-WEIGHT: bold; TEXT-ALIGN: left; TEXT-DECORATION: none; TEXT-INDENT: 1px;}");
        stringbuffer.append("A.OraPmvTableSortableColumnHeader:active {BACKGROUND-COLOR: #cccc99; COLOR: #336699; CURSOR: hand; FONT-FAMILY: Arial, Helvetica, Geneva, sans-serif; FONT-SIZE: 10pt; FONT-WEIGHT: bold; TEXT-ALIGN: left; TEXT-DECORATION: none; TEXT-INDENT: 1px}");
        stringbuffer.append("A.OraPmvTableSortableColumnHeader:visited {BACKGROUND-COLOR: #cccc99; COLOR: #336699; CURSOR: hand; FONT-FAMILY: Arial, Helvetica, Geneva, sans-serif; FONT-SIZE: 10pt; FONT-WEIGHT: bold; TEXT-ALIGN: left; TEXT-DECORATION: none; TEXT-INDENT: 1px}");
        stringbuffer.append("A.OraPmvTableSortableColumnHeaderNumber:link {BACKGROUND-COLOR: #cccc99; COLOR: #336699; CURSOR: hand; FONT-FAMILY: Arial, Helvetica, Geneva, sans-serif;FONT-SIZE: 10pt; FONT-WEIGHT: bold; TEXT-ALIGN: right; TEXT-DECORATION: none; TEXT-INDENT: 1px; }");
        stringbuffer.append("A.OraPmvTableSortableColumnHeaderNumber:active {BACKGROUND-COLOR: #cccc99; COLOR: #336699; CURSOR: hand; FONT-FAMILY: Arial, Helvetica, Geneva, sans-serif;FONT-SIZE: 10pt; FONT-WEIGHT: bold; TEXT-ALIGN: right; TEXT-DECORATION: none; TEXT-INDENT: 1px}");
        stringbuffer.append("A.OraPmvTableSortableColumnHeaderNumber:visited {BACKGROUND-COLOR: #cccc99; COLOR: #336699; CURSOR: hand; FONT-FAMILY: Arial, Helvetica, Geneva, sans-serif;FONT-SIZE: 10pt; FONT-WEIGHT: bold; TEXT-ALIGN: right; TEXT-DECORATION: none; TEXT-INDENT: 1px}");
        stringbuffer.append(".OraPmvLinkHidden {text-decoration:none;COLOR: #663300; FONT-FAMILY: Arial, Helvetica, Geneva, sans-serif; FONT-SIZE: 10pt}");
        stringbuffer.append("</STYLE>");
        return stringbuffer.toString();
    }

    public static java.lang.String getTableNavigation(boolean flag, boolean flag1, java.lang.String s, int i, int j, boolean flag2, int k, int l,
            oracle.apps.fnd.common.WebAppsContext webappscontext, java.lang.String s1, java.lang.String s2, int i1, java.lang.String s3, java.lang.String s4, int j1,
            java.lang.String s5, boolean flag3, boolean flag4, boolean flag5, boolean flag6, int k1, boolean flag7,
            com.sun.java.util.collections.ArrayList arraylist, javax.servlet.jsp.PageContext pagecontext, java.sql.Connection connection, boolean flag8)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        java.lang.String s6 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_SHOW_SET", webappscontext);
        java.lang.String s7 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_SHOW_ALL", webappscontext);
        java.lang.String s8 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_PREVIOUS", webappscontext);
        java.lang.String s9 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_TABLE_NEXT", webappscontext);
        java.lang.String s10 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getJspAgent(webappscontext);
        java.lang.String s11 = "";
        boolean flag9 = false;
        if(webappscontext.getCurrLangCode() != null)
        {
            java.lang.String s12 = webappscontext.getCurrLangCode();
            if(s12.equals("AR") || s12.equals("IW"))
                flag9 = true;
        }
        stringbuffer.append("<TR><td><table border=0 cellpadding=1 cellspacing=0 width=100% summary=\"\" ");
        if(j1 == 1)
            stringbuffer.append("class=OraPmvTableBottom");
        else
            stringbuffer.append("class=OraPmvTableTop");
        stringbuffer.append(" ><tbody>");
        stringbuffer.append("<tr valign=middle>");
        if(flag5)
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getSelectAllHtml(webappscontext));
        if(j1 != 1 && arraylist != null)
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getTableNavButtons(webappscontext, arraylist, pagecontext, connection));
        if(flag2)
        {
            if("ALL".equals(s))
            {
                stringbuffer.append("<td ><div >");
                stringbuffer.append("<a href=\"javascript:searchTable").append(s4).append("('false')\" return true\"\">");
                stringbuffer.append("<span class=OraGlobalButtonText>").append(s6).append("</span></a></div></td>");
            } else
            {
                stringbuffer.append("<td ><div >");
                stringbuffer.append("<a href=\"javascript:searchTable").append(s4).append("('true')\"  return true\"\">");
                stringbuffer.append("<span class=OraGlobalButtonText>").append(s7).append("</span></a></div></td>");
            }
        } else
        {
            stringbuffer.append("<td >&nbsp;</td>");
        }
        if(flag6 && k1 <= 2 && !flag7)
        {
            java.lang.String s13 = oracle.apps.bis.common.Util.escapeGTLTHTML(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_PERSONALIZE", webappscontext), "");
            stringbuffer.append("<td align=right width=11% nowrap><div align=right>");
            java.lang.String s15 = "Pers";
            if(j1 == 1)
                s15 = s15 + "Low";
            else
                s15 = s15 + "Up";
            stringbuffer.append("<a id=\"").append(s15).append("\"");
            if(flag8)
            {
                stringbuffer.append(" onClick=\"\" style=\"cursor=none\"");
            } else
            {
                stringbuffer.append(" href=\"javascript:drlObjClk(event, 'TMenu0', 1, '").append(s15).append("');\"");
                stringbuffer.append(" onClick=\"drlObjClk(event, 'TMenu0', 1, '").append(s15).append("');return false;\"");
                stringbuffer.append(" style=\"cursor:hand;text-decoration:none;\"");
                stringbuffer.append(" onKeyDown=\"clkDown(event, 'TMenu0')\" onMouseDown=\"clkDown(event, 'TMenu0')\"");
            }
            stringbuffer.append(" ALT=\"").append(s13).append("\" TITLE=\"").append(s13).append("\">");
            if(flag8)
                stringbuffer.append("<span class=OraNavBarInactiveLink>");
            else
                stringbuffer.append("<span class=OraNavBarActiveLink>");
            stringbuffer.append(s13).append("</span>&nbsp;");
            stringbuffer.append("<img align=bottom src=\"/OA_MEDIA/");
            if(flag8)
                stringbuffer.append("bisdarr5.gif\"");
            else
                stringbuffer.append("bisdarr.gif\"");
            stringbuffer.append(" ALT=\"").append(s13).append("\" TITLE=\"").append(s13).append("\" border=0>");
            stringbuffer.append("</a>&nbsp;&nbsp;</div></td>");
            stringbuffer.append("<td align=right width=1%><img alt=\"\" src=\"/OA_MEDIA/bisdivdr.gif\"></td>");
            stringbuffer.append("<td align=right width=1%>&nbsp;</td>");
        }
        java.lang.String s14 = "false";
        java.lang.String s16 = "false";
        java.lang.String s17 = "true";
        int l1 = i - k;
        java.lang.String s18 = s2;
        if(l1 < java.lang.Integer.parseInt(s2) && flag4)
        {
            s14 = "true";
            s17 = "false";
            int i2 = java.lang.Integer.parseInt(s2);
            i2 -= java.lang.Integer.parseInt(s3);
            s18 = java.lang.String.valueOf(i2);
            if(l1 < 0)
                l1 = 0;
        } else
        if(flag4)
        {
            s14 = "true";
            s17 = "false";
            l1 = 0;
            s18 = "0";
            s3 = java.lang.String.valueOf(j);
        }
        if(flag)
        {
            stringbuffer.append("<td align=right nowrap width=1%>");
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getNavigateTable(s17, l1, s16, s14, s18, s3, s4)).append(" >");
            if(flag9)
            {
                stringbuffer.append("<img align=textTop src=").append(s10).append("cabo/").append(oracle.cabo.share.config.Configuration.IMAGES_DIRECTORY).append("/tnavn.gif ALT=\"").append(s8);
                stringbuffer.append("\" TITLE=\"").append(s8);
                stringbuffer.append("\" border=0>");
            } else
            {
                stringbuffer.append("<img align=textTop src=").append(s10).append("cabo/").append(oracle.cabo.share.config.Configuration.IMAGES_DIRECTORY).append("/tnavp.gif ALT=\"").append(s8);
                stringbuffer.append("\" TITLE=\"").append(s8);
                stringbuffer.append("\" border=0>");
            }
            stringbuffer.append("</font></a></td>");
            stringbuffer.append("<td align=right nowrap width=3%><div >");
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getNavigateTable(s17, l1, s16, s14, s18, s3, s4)).append(" >");
            stringbuffer.append("<span class=OraNavBarActiveLink>").append(s8);
            stringbuffer.append("&nbsp;").append(k);
            stringbuffer.append("</a>&nbsp;</span></div></td>");
        } else
        {
            if(flag9)
                stringbuffer.append("<td align=right nowrap width=1%><img align=textTop src=").append(s10).append("cabo/").append(oracle.cabo.share.config.Configuration.IMAGES_DIRECTORY).append("/tnavnd.gif alt=\"\" ></td>");
            else
                stringbuffer.append("<td align=right nowrap width=1%><img align=textTop src=").append(s10).append("cabo/").append(oracle.cabo.share.config.Configuration.IMAGES_DIRECTORY).append("/tnavpd.gif alt=\"\" ></td>");
            stringbuffer.append("<td align=right nowrap width=2%><div ><span class=OraNavBarInactiveLink>").append(s8).append("&nbsp;</span></div></td>");
        }
        if(flag1 || flag)
        {
            java.lang.String s19 = "tablePopList";
            if(j1 == 1)
                s19 = s19 + "Lower";
            else
                s19 = s19 + "Upper";
            s19 = s19 + s4;
            stringbuffer.append("<td valign=middle width=4% nowrap><LABEL id=\"").append(s19).append("Label\" style=\"display:none\" for=\"").append(s19).append("\">.</LABEL><select id=\"").append(s19).append("\" name=").append(s19);
            stringbuffer.append(" onchange=\"");
            if(!flag4)
                l1 = i + k;
            else
                s3 = java.lang.String.valueOf(j);
            if(l1 < java.lang.Integer.parseInt(s2) && flag4)
            {
                int l2 = java.lang.Integer.parseInt(s18);
                l2 += java.lang.Integer.parseInt(s3);
                s18 = java.lang.String.valueOf(l2);
            } else
            if(flag4 && s18.startsWith("-"))
                s18 = java.lang.String.valueOf(java.lang.Integer.parseInt(s18) + java.lang.Integer.parseInt(s3));
            if(j1 == 1)
                stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getNavigateLower(s17, l1, s16, s14, s18, s3, s4)).append("\">");
            else
                stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getNavigateUpper(s17, l1, s16, s14, s18, s3, s4)).append("\">");
            int i3;
            try
            {
                i3 = java.lang.Integer.parseInt(s5);
            }
            catch(java.lang.Exception _ex)
            {
                i3 = i1;
            }
            for(int k3 = 0; k3 < i3; k3 += k)
            {
                stringbuffer.append("<option ");
                if(!flag3 && java.lang.String.valueOf(k3).equals(s2) || flag3 && k3 == i - 1)
                    stringbuffer.append("selected ");
                stringbuffer.append("value=\"").append(java.lang.String.valueOf(k3)).append("\" >");
                java.lang.String s20 = "";
                if(k3 + k > i3)
                    s20 = java.lang.String.valueOf(i3);
                else
                    s20 = java.lang.String.valueOf(k3 + k);
                if(flag9)
                {
                    stringbuffer.append(s20);
                    stringbuffer.append("-");
                    stringbuffer.append(java.lang.String.valueOf(k3 + 1));
                } else
                {
                    stringbuffer.append(java.lang.String.valueOf(k3 + 1));
                    stringbuffer.append("-");
                    stringbuffer.append(s20);
                }
                if(s5 != null)
                    stringbuffer.append(" ").append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_PMV_OF", webappscontext)).append(" ").append(java.lang.String.valueOf(i3));
                stringbuffer.append("</option>");
                if(!flag4 && s5 == null && (!flag3 && java.lang.String.valueOf(k3).equals(s2) || flag3 && k3 == i - 1))
                    break;
            }

            if(s5 == null)
                stringbuffer.append("<option value=\"MORE\" >").append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_LOV_MORE", webappscontext)).append(" </option>");
            stringbuffer.append("</select>&nbsp;</td>");
        }
        s14 = "false";
        s16 = "false";
        s17 = "true";
        l1 = i + k;
        s18 = s2;
        if(l1 > j && flag4)
        {
            s16 = "true";
            s17 = "false";
            l1 = 0;
            int j2 = java.lang.Integer.parseInt(s2);
            j2 += j;
            s18 = java.lang.String.valueOf(j2);
            s3 = java.lang.String.valueOf(j);
        } else
        if(flag4)
        {
            s16 = "true";
            s17 = "false";
            l1 = 0;
            s18 = java.lang.String.valueOf(j);
            s3 = java.lang.String.valueOf(j);
        }
        if(flag1)
        {
            stringbuffer.append("<td align=right nowrap width=2%><div align=right>");
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getNavigateTable(s17, l1, s16, s14, s18, s3, s4)).append(" >");
            stringbuffer.append("<span class=OraNavBarActiveLink>").append(s9);
            int k2 = i1 - ((i + k) - 1);
            if(s5 != null && flag4)
            {
                int j3 = 0;
                try
                {
                    j3 = java.lang.Integer.parseInt(s5);
                }
                catch(java.lang.Exception _ex)
                {
                    j3 = 0;
                }
                if(j3 > 0)
                {
                    k2 = j3 - i1;
                    if(k2 > k || k2 < 1)
                        k2 = k;
                }
            }
            if(s5 != null && flag4)
                stringbuffer.append("&nbsp;").append(java.lang.String.valueOf(k2));
            else
            if(k2 < k && k2 > 0 && !flag4)
                stringbuffer.append("&nbsp;").append(java.lang.String.valueOf(k2));
            else
                stringbuffer.append("&nbsp;").append(k);
            stringbuffer.append("</span></a></div></td>");
            stringbuffer.append("<td align=right nowrap width=1%>");
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getNavigateTable(s17, l1, s16, s14, s18, s3, s4)).append(" >");
            if(flag9)
                stringbuffer.append("<img align=textTop src=").append(s10).append("cabo/").append(oracle.cabo.share.config.Configuration.IMAGES_DIRECTORY).append("/tnavp.gif ALT=\"").append(s9).append("\" TITLE=\"").append(s9).append("\" border=0>");
            else
                stringbuffer.append("<img align=textTop src=").append(s10).append("cabo/").append(oracle.cabo.share.config.Configuration.IMAGES_DIRECTORY).append("/tnavn.gif ALT=\"").append(s9).append("\" TITLE=\"").append(s9).append("\" border=0>");
            stringbuffer.append("</a></td>");
        } else
        {
            stringbuffer.append("<td align=right nowrap width=1%><div align=right>");
            stringbuffer.append("<span class=OraNavBarInactiveLink>").append(s9).append("</span></div></td>");
            stringbuffer.append("<td align=right nowrap width=1%>");
            if(flag9)
                stringbuffer.append("<img align=textTop src=").append(s10).append("cabo/").append(oracle.cabo.share.config.Configuration.IMAGES_DIRECTORY).append("/tnavpd.gif alt=\"\" ></td>");
            else
                stringbuffer.append("<img align=textTop src=").append(s10).append("cabo/").append(oracle.cabo.share.config.Configuration.IMAGES_DIRECTORY).append("/tnavnd.gif alt=\"\" ></td>");
        }
        stringbuffer.append("</tr></tbody></table></td></TR>");
        return stringbuffer.toString();
    }

    public static java.lang.String getTableViewLink(oracle.apps.fnd.common.WebAppsContext webappscontext, java.lang.String s, int i, com.sun.java.util.collections.ArrayList arraylist, boolean flag, javax.servlet.jsp.PageContext pagecontext, java.sql.Connection connection, boolean flag1)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        java.lang.String s1 = oracle.apps.bis.common.Util.escapeGTLTHTML(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_PERSONALIZE", webappscontext), "");
        od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getJspAgent(webappscontext);
        java.lang.String s2 = "";
        boolean flag2 = false;
        if(webappscontext.getCurrLangCode() != null)
        {
            java.lang.String s3 = webappscontext.getCurrLangCode();
            boolean flag3;
            if(s3.equals("AR") || s3.equals("IW"))
                flag3 = true;
        }
        stringbuffer.append("<TR><td><table border=0 cellpadding=1 cellspacing=0 width=100% summary=\"\" ");
        if(i == 1)
            stringbuffer.append("class=OraPmvTableBottom");
        else
            stringbuffer.append("class=OraPmvTableTop");
        stringbuffer.append(" ><tbody>");
        stringbuffer.append("<tr valign=middle>");
        if(arraylist != null && i != 1)
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getTableNavButtons(webappscontext, arraylist, pagecontext, connection));
        stringbuffer.append("<td >&nbsp;</td>");
        stringbuffer.append("<td >&nbsp;</td>");
        stringbuffer.append("<td >&nbsp;</td>");
        java.lang.String s4 = "Pers";
        if(i == 1)
            s4 = s4 + "Low";
        else
            s4 = s4 + "Up";
        if(flag)
        {
            stringbuffer.append("<td align=right width=11% nowrap><div align=right>");
            stringbuffer.append("<a id=\"").append(s4).append("\"");
            if(flag1)
            {
                stringbuffer.append(" onClick=\"\" style=\"cursor=none\"");
            } else
            {
                stringbuffer.append(" href=\"javascript:drlObjClk(event, 'TMenu0', 1, '").append(s4).append("');\"");
                stringbuffer.append(" onClick=\"drlObjClk(event, 'TMenu0', 1, '").append(s4).append("');return false;\"");
                stringbuffer.append(" style=\"cursor=hand;text-decoration:none;\"");
                stringbuffer.append(" onKeyDown=\"clkDown(event, 'TMenu0')\" onMouseDown=\"clkDown(event, 'TMenu0')\"");
            }
            stringbuffer.append(" ALT=\"").append(s1).append("\" TITLE=\"").append(s1).append("\">");
            if(flag1)
                stringbuffer.append("<span class=OraNavBarInactiveLink>");
            else
                stringbuffer.append("<span class=OraNavBarActiveLink>");
            stringbuffer.append(s1).append("</span>&nbsp;");
            stringbuffer.append("<img align=bottom src=\"/OA_MEDIA/");
            if(flag1)
                stringbuffer.append("bisdarr5.gif\"");
            else
                stringbuffer.append("bisdarr.gif\"");
            stringbuffer.append(" ALT=\"").append(s1).append("\" TITLE=\"").append(s1).append("\" border=0>");
            stringbuffer.append("</a>&nbsp;&nbsp;</div></td>");
        }
        stringbuffer.append("</tr></tbody></table></td></TR>");
        return stringbuffer.toString();
    }

    private static java.lang.StringBuffer getSelectAllHtml(oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append("<td noWrap align=\"left\"><div><span class=\"OraGlobalButtonText\">");
        stringbuffer.append("<a href=\"javascript:selectAll()\" return true;\"> ");
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_SELECT_ALL", webappscontext));
        stringbuffer.append("</a>");
        stringbuffer.append("&nbsp;&nbsp|&nbsp;&nbsp");
        stringbuffer.append("<a href=\"javascript:selectNone()\" return true;\">");
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_SELECT_NONE", webappscontext));
        stringbuffer.append("</a>");
        stringbuffer.append("</span></div></td>");
        return stringbuffer;
    }

    private static java.lang.String getNavigateTable(java.lang.String s, int i, java.lang.String s1, java.lang.String s2, java.lang.String s3, java.lang.String s4, java.lang.String s5)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append("<a href=\"javascript:navigateTable").append(s5).append("(");
        stringbuffer.append("'").append(s).append("',");
        stringbuffer.append("'").append(i).append("',");
        stringbuffer.append("'").append(s1).append("',");
        stringbuffer.append("'").append(s2).append("',");
        stringbuffer.append("'").append(s3).append("',");
        stringbuffer.append("'").append(s4).append("',");
        stringbuffer.append("'").append(s5).append("')\"");
        return stringbuffer.toString();
    }

    private static java.lang.String getNavigateUpper(java.lang.String s, int i, java.lang.String s1, java.lang.String s2, java.lang.String s3, java.lang.String s4, java.lang.String s5)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append("javascript:navigateUpperList").append(s5).append("(");
        stringbuffer.append("'").append(s).append("',");
        stringbuffer.append("'").append(i).append("',");
        stringbuffer.append("'").append(s1).append("',");
        stringbuffer.append("'").append(s2).append("',");
        stringbuffer.append("'").append(s3).append("',");
        stringbuffer.append("'").append(s4).append("')");
        return stringbuffer.toString();
    }

    private static java.lang.String getNavigateLower(java.lang.String s, int i, java.lang.String s1, java.lang.String s2, java.lang.String s3, java.lang.String s4, java.lang.String s5)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append("javascript:navigateLowerlist").append(s5).append("(");
        stringbuffer.append("'").append(s).append("',");
        stringbuffer.append("'").append(i).append("',");
        stringbuffer.append("'").append(s1).append("',");
        stringbuffer.append("'").append(s2).append("',");
        stringbuffer.append("'").append(s3).append("',");
        stringbuffer.append("'").append(s4).append("')");
        return stringbuffer.toString();
    }

    public static java.lang.String getLastUpdateString(java.lang.String s, oracle.apps.bis.pmv.session.UserSession usersession)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        if(s != null && !"".equals(s))
        {
            stringbuffer.append("<span class=\"OraTipText\">");
            stringbuffer.append(s);
            stringbuffer.append("</span> <br>");
        }
        return stringbuffer.toString();
    }

    public static java.lang.String getAutoFactorHTMLString(java.lang.String s)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append("<span class=\"OraTipText\">");
        stringbuffer.append(s);
        stringbuffer.append("</span> <br>");
        return stringbuffer.toString();
    }

    public static java.lang.String getExcelLastUpdateString(java.lang.String s, oracle.apps.bis.pmv.session.UserSession usersession)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getLastUpdateStringWithoutSpan(s);
        if(s1 != null && !"".equals(s1))
            stringbuffer.append(s1);
        return stringbuffer.toString();
    }

    public static java.lang.String getPdfLastUpdateString(java.lang.String s, oracle.apps.bis.pmv.session.UserSession usersession)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getLastUpdateStringWithoutSpan(s);
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
        {
            stringbuffer.append("<lastupdate icon=\" \">");
            stringbuffer.append("\n");
            stringbuffer.append("<![CDATA[");
            stringbuffer.append(s1);
            stringbuffer.append("]]>");
            stringbuffer.append("\n");
            stringbuffer.append("</lastupdate>");
            stringbuffer.append("\n");
        }
        return stringbuffer.toString();
    }

    public static java.lang.String getOnMouseOverHtml(java.lang.String s)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append(" &nbsp;&nbsp ");
        return stringbuffer.toString();
    }

    public static java.lang.String getMouseOverText(java.lang.String s)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(50);
        java.lang.String s1 = "";
        if(s != null)
            s1 = oracle.apps.bis.pmv.common.StringUtil.replaceAll(s, "\"", "&quot;");
        stringbuffer.append(oracle.apps.bis.pmv.common.StringUtil.replaceAll(s1, "'", "\\'"));
        return stringbuffer.toString();
    }

    public static java.lang.String getPortletTitle(java.lang.String s)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append("<TABLE cellSpacing=0 cellPadding=0 width=\"100%\"  summary=\"\">");
        stringbuffer.append("<TR><TD class=OraHeaderSubSub>");
        stringbuffer.append(s);
        stringbuffer.append("</TD></TR>");
        stringbuffer.append("</TABLE>");
        return stringbuffer.toString();
    }

    public static java.lang.String getPortletBorder()
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append("<TABLE cellSpacing=0 cellPadding=0  summary=\"\" width=\"100%\" style='border:#999999 1px solid'>");
        stringbuffer.append("<TR><TD class=OraInstructionText>");
        return stringbuffer.toString();
    }

    public static java.lang.String getRLPortletBorder()
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append("<TABLE cellSpacing=0 cellPadding=0  summary=\"\" bgcolor=\"#eaeff5\" width=\"100%\" ");
        stringbuffer.append("style='border:#999999 1px solid'>");
        stringbuffer.append("<TR><TD class=OraInstructionText>");
        return stringbuffer.toString();
    }

    public static java.lang.String closePortletBorder()
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(20);
        stringbuffer.append("</TD></TR></TABLE>");
        return stringbuffer.toString();
    }

    public static java.lang.String getStyleSheetLink(java.lang.String s)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append("<LINK REL=Stylesheet TYPE=\"text/css\" HREF=\"");
        stringbuffer.append(s);
        stringbuffer.append("PORTAL30.wwpob_app_style.render_css?p_style_id=6\">\n");
        return stringbuffer.toString();
    }

    public static java.lang.String getStyleSheet(java.lang.String s, java.lang.String s1)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        long l = java.lang.System.currentTimeMillis();
        stringbuffer.append("<link rel=\"stylesheet\" href=\"").append(s).append("biscusto.css?").append(l).append("\" type=\"text/css\">");
        if(s1 != null && (s1.equals("AR") || s1.equals("IW")))
            stringbuffer.append("<link rel=\"stylesheet\" href=\"").append(s).append("bismarlibidi.css?").append(l).append("\" type=\"text/css\">");
        else
            stringbuffer.append("<link rel=\"stylesheet\" href=\"").append(s).append("bismarli.css?").append(l).append("\" type=\"text/css\">");
        return stringbuffer.toString();
    }

    public static java.lang.String getComponentPageHtmlHeader(boolean flag, java.lang.String s, java.lang.String s1)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(200);
        if(flag)
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getStyleSheet(s1, s));
        stringbuffer.append("<SCRIPT LANGUAGE=\"JavaScript\">function show_context_help(h) {");
        stringbuffer.append("newWindow = window.open(h,\"ContextHelp\", \"menubar=1,scrollbars=1,resizable=1,width=600, height=400\");}</SCRIPT>\n");
        return stringbuffer.toString();
    }

    public static java.lang.String getPortalPageHeader(java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, java.lang.String s4, java.lang.String s5, java.lang.String s6, java.lang.String s7,
            java.lang.String s8, java.lang.String s9, java.lang.String s10, java.lang.String s11, java.lang.String s12, java.lang.String s13, java.lang.String s14,
            java.lang.String s15, boolean flag)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(1000);
        stringbuffer.append("<tr><td>");
        stringbuffer.append("<table cellspacing=\"0\" cellpadding=\"0\"  summary=\"\" width=\"100%\" border=\"0\"> ");
        if("AR".equals(s13) || "IW".equals(s13))
            stringbuffer.append("<tr>      <td align=\"RIGHT\">  ");
        else
            stringbuffer.append("<tr>      <td align=\"LEFT\">  ");
        stringbuffer.append("<table cellspacing=\"0\" cellpadding=\"0\"  summary=\"\" border=\"0\">  ");
        stringbuffer.append("<tr> <td><img src=\"").append(s15).append("/OA_MEDIA/oplogopb.gif\" alt=\"Oracle\" width=\"141\" height=\"23\">  ");
        stringbuffer.append("</td>");
        stringbuffer.append("<td class=\"OraHeader\">");
        stringbuffer.append(s).append("</td></tr></table></td>");
        if(!flag)
        {
            if("AR".equals(s13) || "IW".equals(s13))
                stringbuffer.append("<td align=\"LEFT\" valign=\"bottom\"> ");
            else
                stringbuffer.append("<td align=\"RIGHT\" valign=\"bottom\"> ");
            stringbuffer.append("<table border=\"0\" cellpadding=\"4\"  summary=\"\"  cellspacing=\"0\"> ");
            stringbuffer.append(" <tr nowrap>");
            if(s7 != null)
            {
                stringbuffer.append("<td> <a href=\"");
                stringbuffer.append(s8).append("\" class=\"OraGlobalButtonText\" target=_top>").append(s7).append("</a>");
                stringbuffer.append("</td>");
            }
            if(s9 != null && !"".equals(s9) || s10 != null && !"".equals(s10))
            {
                stringbuffer.append("<td class=\"OraInstructionText\"> ");
                if(s9 != null && !"".equals(s9))
                {
                    stringbuffer.append("<a href=\"").append(s9).append("\" class=\"OraGlobalButtonText\" target=_top>");
                    stringbuffer.append("<img src=\"/OA_MEDIA/bisaprev.gif\" border=0></a>&nbsp;");
                    stringbuffer.append("<a href=\"").append(s9).append("\" class=\"OraGlobalButtonText\" target=_top>");
                    stringbuffer.append(s11).append("</a>");
                } else
                {
                    stringbuffer.append("<img src=\"/OA_MEDIA/bisdprev.gif\">&nbsp;").append(s11);
                }
                stringbuffer.append("</td>");
                stringbuffer.append("<td>|</td><td class=\"OraInstructionText\"> ");
                if(s10 != null && !"".equals(s10))
                {
                    stringbuffer.append("<a href=\"").append(s10).append("\" class=\"OraGlobalButtonText\" target=_top>");
                    stringbuffer.append(s12).append("</a>&nbsp;");
                    stringbuffer.append("<a href=\"").append(s10).append("\" class=\"OraGlobalButtonText\" target=_top>");
                    stringbuffer.append("<img src=\"/OA_MEDIA/bisanext.gif\" border=0>").append("</a>");
                } else
                {
                    stringbuffer.append(s12).append("&nbsp;<img src=\"/OA_MEDIA/bisdnext.gif\">");
                }
                stringbuffer.append("</td><td>&nbsp;</td>");
            }
            stringbuffer.append("<td> <a href=\"").append(s4).append("\" class=\"OraGlobalButtonText\" target=_top>").append(s1).append("</a>");
            stringbuffer.append("</td>");
            stringbuffer.append("<td> <a href=\"");
            stringbuffer.append(s5).append("\" class=\"OraGlobalButtonText\" target=_top>").append(s2).append("</a>");
            stringbuffer.append("</td>");
            stringbuffer.append("<td> <a href=\"");
            stringbuffer.append(s6).append("\" class=\"OraGlobalButtonText\" target=_top>").append(s3).append("</a>");
            stringbuffer.append("</td>");
            stringbuffer.append("</tr>  </table>   </td>  </tr>");
        }
        stringbuffer.append("<tr>  </tr>  </table>");
        stringbuffer.append("<table width=\"100%\" border=\"0\"  summary=\"\"  cellspacing=\"0\" cellpadding=\"1\">");
        stringbuffer.append("<tr> <td colspan=\"5\"><img border=0 width=100% height=3 id=\"_x0000_i1060\" src=\"/OA_MEDIA/bispixdb.gif\" alt=\"\" align=middle></td>");
        stringbuffer.append("</tr></table>");
        stringbuffer.append("</td></tr>");
        if(flag)
            stringbuffer.append(" <base href=\"").append(s15).append("\"> ");
        return stringbuffer.toString();
    }

    public static java.lang.String getPortalPageFooter(java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, java.lang.String s4, java.lang.String s5, java.lang.String s6, java.lang.String s7,
            java.lang.String s8, java.lang.String s9, java.lang.String s10, java.lang.String s11, java.lang.String s12)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(1000);
        stringbuffer.append("<table cellspacing=\"0\" cellpadding=\"0\" width=\"100%\"  summary=\"\"  border=\"0\">\n");
        stringbuffer.append("<tbody> <tr> <td>&nbsp;</td>  </tr>\n");
        stringbuffer.append("<tr> <td class=\"OraBGAccentDark\"><img border=\"0\" width=\"100%\" height=\"1\" src=\"/OA_MEDIA/FNDINVDT.gif\" alt=\"\" title=\"\"></td> </tr>\n");
        stringbuffer.append("<tr><td align=\"middle\"><table summary=\"\"><tr><td>");
        if(s6 != null)
        {
            stringbuffer.append("<a href=\"").append(s7).append("\" class=\"OraLinkText\" target=_top>").append(s6).append("</a>");
            stringbuffer.append("&nbsp;|</td><td>&nbsp;");
            if(s9 != null && !"".equals(s9) || s10 != null && !"".equals(s10))
            {
                if(s9 != null && !"".equals(s9))
                    stringbuffer.append("<a href=\"").append(s9).append("\" class=\"OraLinkText\" target=_top>").append(s11).append("</a>");
                else
                    stringbuffer.append(s11);
                stringbuffer.append("&nbsp;|</td><td>&nbsp;");
                if(s10 != null && !"".equals(s10))
                    stringbuffer.append("<a href=\"").append(s10).append("\" class=\"OraLinkText\" target=_top>").append(s12).append("</a>");
                else
                    stringbuffer.append(s12);
                stringbuffer.append("&nbsp;|</td><td>&nbsp;");
            }
            stringbuffer.append("<a href=\"").append(s3).append("\" class=\"OraLinkText\" target=_top>").append(s).append("</a>");
            stringbuffer.append("&nbsp;|</td><td>&nbsp;");
            stringbuffer.append("<a href=\"").append(s4).append("\" class=\"OraLinkText\" target=_top> ").append(s1).append("</a>");
            stringbuffer.append("&nbsp;|</td><td>&nbsp;");
            stringbuffer.append("<a href=\"").append(s5).append("\" class=\"OraLinkText\" target=_top>").append(s2).append("</a>");
            stringbuffer.append("</td></tr></table></td></tr>");
            stringbuffer.append(" <tr> <td class=\"OraInstructionText\" align=\"middle\" colspan=\"2\">");
            stringbuffer.append("<div align=\"RIGHT\"></div>");
            stringbuffer.append("</td>   </tr>");
        }
        stringbuffer.append("<tr> <td class=\"OraCopyright\">").append(s8).append("</td>");
        stringbuffer.append("</tr>");
        stringbuffer.append(" </tbody></table>");
        return stringbuffer.toString();
    }

    public static java.lang.String getReportUrl(java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, java.lang.String s4)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(200);
        stringbuffer.append(s);
        stringbuffer.append("bis_trend_plug.view_report_from_portlet");
        stringbuffer.append("?pRegionCode=").append(s1);
        stringbuffer.append("&pFunctionName=").append(s2);
        stringbuffer.append("&pScheduleId=").append(s3);
        stringbuffer.append("&pPageId=").append(s4);
        return stringbuffer.toString();
    }

    public static java.lang.String getCustomizeUrl(java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, java.lang.String s4, java.lang.String s5, java.lang.String s6, java.lang.String s7,
            java.lang.String s8, oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(200);
        try
        {
            java.lang.String s9 = webappscontext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
            stringbuffer.append(s);
            stringbuffer.append("OA.jsp?akRegionCode=").append(s1);
            stringbuffer.append("&akRegionApplicationId=").append(s2);
            stringbuffer.append("&dbc=").append(s6);
            stringbuffer.append("&transactionid=").append(s7);
            stringbuffer.append("&_portletid=").append(s3);
            stringbuffer.append("&_referencepath=").append(oracle.cabo.share.url.EncoderUtils.encodeString(s4, s9));
            stringbuffer.append("&_title=").append(oracle.cabo.share.url.EncoderUtils.encodeString(s5, s9));
            stringbuffer.append("&_backurl=").append(s8);
        }
        catch(java.io.UnsupportedEncodingException _ex) { }
        return stringbuffer.toString();
    }

    public static java.lang.String getPreviewLovString(oracle.apps.bis.pmv.session.UserSession usersession)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append("<img src=" + usersession.getImageServer() + "BISILOV.gif border=0");
        stringbuffer.append(" align=absmiddle ");
        stringbuffer.append(" alt=\"");
        oracle.apps.fnd.common.WebAppsContext webappscontext = usersession.getWebAppsContext();
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getMouseOverText(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_LOV", webappscontext)));
        stringbuffer.append("\" title=\"");
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getMouseOverText(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_LOV", webappscontext)));
        stringbuffer.append("\">");
        return stringbuffer.toString();
    }

    public static java.lang.String getEncryptedCode(java.lang.String s, oracle.apps.fnd.security.AolSecurity aolsecurity)
    {
        java.lang.String s1 = null;
        try
        {
            java.lang.String s2 = aolsecurity.encrypt("IDVALUE", s);
            if(s2.equals("ZG_ENCRYPT_FAILED_CHARSET_CLIP"))
                s2 = aolsecurity.encrypt("IDVALUE", 1000, s);
            s1 = s2 + "*^*^*";
        }
        catch(java.lang.Exception _ex)
        {
            s1 = s + "*^*^*";
        }
        return s1;
    }

    public static java.lang.String getCommentsHtml(java.lang.String s, java.lang.String s1)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        stringbuffer.append("<table cellpadding=0 cellspacing=0 border=0 summary=\"\">");
        for(int i = 0; i < 20; i++)
            stringbuffer.append("<tr></tr>");

        stringbuffer.append("<tr><td class=OraFieldText>");
        for(int j = 0; j < s1.length(); j++)
            if(s1.charAt(j) == '\n')
                stringbuffer.append("</tr><tr><td class=OraFieldText>");
            else
            if(s1.charAt(j) == ' ')
                stringbuffer.append("&nbsp;");
            else
                stringbuffer.append(s1.charAt(j));

        stringbuffer.append("</td></tr>");
        for(int k = 0; k < 25; k++)
            stringbuffer.append("<tr></tr>");

        stringbuffer.append("</table>");
        stringbuffer.append("<table width=\"100%\" border=\"0\" summary=\"\" cellspacing=\"0\" cellpadding=\"0\">");
        stringbuffer.append("<tr><td height=\"3\" background=\"");
        stringbuffer.append(s).append("/OA_MEDIA/bisdots.gif");
        stringbuffer.append("\" alt=\"\" width=\"100%\" colspan=\"6\"></td></tr></table>");
        return stringbuffer.toString();
    }

    public static java.lang.String getRefreshTag(oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        java.lang.String s = "<meta http-equiv=\"refresh\" content=\"" + oracle.apps.bis.common.Util.getRefreshTime(webappscontext) + "\">";
        return s;
    }

    public static java.lang.String getLastUpdateStringWithoutSpan(java.lang.String s)
    {
        java.lang.String s1 = s;
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s))
        {
            int i = s.indexOf(">");
            if(i > 0)
            {
                java.lang.String s2 = s.substring(i);
                s1 = s2.substring(1, s2.indexOf("</"));
            }
            int j = s1.indexOf("<A");
            int k = s1.indexOf(">");
            if(j > 0)
            {
                java.lang.String s3 = s1.substring(0, j);
                java.lang.String s4 = s1.substring(k + 1);
                s1 = s3 + s4;
            }
        }
        return s1;
    }

    public static java.lang.String getPortletComboList(java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, java.lang.String s4, com.sun.java.util.collections.ArrayList arraylist, boolean flag, boolean flag1,
            oracle.apps.fnd.common.WebAppsContext webappscontext, java.lang.String s5, com.sun.java.util.collections.ArrayList arraylist1, java.lang.String s6, boolean flag2, boolean flag3, com.sun.java.util.collections.ArrayList arraylist2,
            javax.servlet.jsp.PageContext pagecontext, boolean flag4)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        stringbuffer.append(" <TABLE class=DbiParameterTable style=\"DISPLAY: inline\" cellSpacing=0 cellPadding=1 border=0 summary=\"\">");
        stringbuffer.append("<TBODY>");
        stringbuffer.append("<TR>");
        stringbuffer.append("<TD class=OraInstructionText noWrap>").append(s).append("</TD>");
        stringbuffer.append("<TD class=OraInstructionText noWrap>");
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getComboList(s1, s2, s3, s4, arraylist, flag, flag1, webappscontext, s5, arraylist1, s6, flag2, flag3, arraylist2, pagecontext, true, flag4));
        stringbuffer.append("<TD align=middle width=10>&nbsp;</TD>");
        stringbuffer.append("</TR>");
        stringbuffer.append("</TBODY>");
        stringbuffer.append("</TABLE>");
        return stringbuffer.toString();
    }

    public static java.lang.String getComboList(java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, com.sun.java.util.collections.ArrayList arraylist, boolean flag, boolean flag1, oracle.apps.fnd.common.WebAppsContext webappscontext,
            java.lang.String s4, com.sun.java.util.collections.ArrayList arraylist1, java.lang.String s5, boolean flag2, boolean flag3, com.sun.java.util.collections.ArrayList arraylist2, javax.servlet.jsp.PageContext pagecontext,
            boolean flag4, boolean flag5)
    {
        java.lang.String s6 = s3;
        java.lang.String s7 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_LOV_MORE", webappscontext);
        java.lang.String s8 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_APPLY", webappscontext);
        java.lang.String s9 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_ALL", webappscontext);
        java.lang.String s10 = null;
        java.lang.String s11 = null;
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        java.lang.StringBuffer stringbuffer1 = new StringBuffer(500);
        java.lang.String s12 = (java.lang.String)arraylist1.get(0);
        java.lang.String s13 = "btnClk('" + s12 + "', '" + s + "', event)";
        java.lang.String s14 = null;
        int i = 2;
        int j = 0;
        boolean flag6 = false;
        boolean flag8 = true;
        if("pTimeFromParameter".equals(s))
            flag8 = false;
        stringbuffer1.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getTriIconHtml(s12, s, "", flag8));
        java.lang.String s15 = "";
        java.lang.String s16 = s1;
        oracle.apps.fnd.security.AolSecurity aolsecurity = new AolSecurity();
        boolean flag9 = oracle.apps.bis.pmv.common.StringUtil.in(s4, oracle.apps.bis.pmv.common.PMVConstants.VALID_SEARCH_REQ_LOV_DIMS) || !flag5;
        if(s4.indexOf("+") != s4.lastIndexOf("+"))
            s15 = s4.substring(s4.lastIndexOf("+") + 1, s4.length());
        for(int k = 0; k < arraylist.size(); k++)
        {
            com.sun.java.util.collections.ArrayList arraylist3 = (com.sun.java.util.collections.ArrayList)arraylist.get(k);
            com.sun.java.util.collections.ArrayList arraylist4 = null;
            java.lang.String as[] = oracle.apps.bis.pmv.common.LookUpHelper.decodeIdValue(s1);
            com.sun.java.util.collections.ArrayList arraylist5 = new ArrayList(11);
            com.sun.java.util.collections.ArrayList arraylist6 = new ArrayList(11);
            try
            {
                od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.evaluateIdMeanings(as, arraylist6, arraylist5);
                boolean flag11 = false;
                for(int i1 = 0; i1 < arraylist3.size(); i1++)
                {
                    if(((oracle.apps.bis.pmv.common.LookUp)arraylist3.get(i1)).getId().equals(as[0]))
                    {
                        flag11 = true;
                        break;
                    }
                    if(arraylist6.contains(((oracle.apps.bis.pmv.common.LookUp)arraylist3.get(i1)).getId()))
                    {
                        arraylist6.remove(((oracle.apps.bis.pmv.common.LookUp)arraylist3.get(i1)).getId());
                        arraylist5.remove(((oracle.apps.bis.pmv.common.LookUp)arraylist3.get(i1)).getMeaning());
                        flag11 = true;
                    }
                }

                if(!flag9 && !flag11)
                {
                    od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.addLookUp(s1, as[0], as[1], arraylist3);
                    s2 = as[1];
                } else
                if(arraylist6.size() > 0)
                {
                    for(int j1 = 0; j1 < arraylist6.size(); j1++)
                        od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.addLookUp((java.lang.String)arraylist6.get(j1), (java.lang.String)arraylist6.get(j1), (java.lang.String)arraylist5.get(j1), arraylist3);

                }
            }
            catch(java.lang.Exception _ex) { }
            if(arraylist2 != null)
                s14 = (java.lang.String)arraylist2.get(k);
            if(flag1 && !s9.equals(s2))
                arraylist4 = oracle.apps.bis.pmv.lov.LovUtil.indentLookUpValues(arraylist3, s1, "&nbsp;&nbsp;&nbsp;");
            else
                arraylist4 = arraylist3;
            oracle.apps.bis.pmv.common.LookUp alookup[] = (oracle.apps.bis.pmv.common.LookUp[])arraylist4.toArray(new oracle.apps.bis.pmv.common.LookUp[arraylist4.size()]);
            s10 = null;
            if(alookup.length > 0)
                s10 = alookup[0].getMeaning();
            java.lang.String s18 = "";
            java.lang.String s19 = (java.lang.String)arraylist1.get(k);
            java.lang.String s20 = "";
            boolean flag12 = true;
            java.lang.String s22 = oracle.apps.bis.pmv.common.LookUpHelper.decodeIdValue(s1)[0];
            if(s3 != null)
            {
                boolean flag7;
                if(s3.indexOf("ORGANIZATION+JTF_ORG_SALES_GROUP") > 0 && s22.equals("-1111"))
                    flag7 = true;
                if(s3.indexOf("ORGANIZATION+JTF_ORG_INTERACTION_CENTER_GRP") > 0 && s22.equals("-1111"))
                    flag7 = true;
            }
            com.sun.java.util.collections.ArrayList arraylist7 = new ArrayList(11);
            com.sun.java.util.collections.ArrayList arraylist8 = new ArrayList(11);
            com.sun.java.util.collections.ArrayList arraylist9 = new ArrayList(11);
            com.sun.java.util.collections.ArrayList arraylist10 = new ArrayList(11);
            com.sun.java.util.collections.ArrayList arraylist11 = new ArrayList(11);
            com.sun.java.util.collections.ArrayList arraylist12 = new ArrayList(11);
            boolean flag13 = false;
            int k1 = 0;
            boolean flag14 = false;
            com.sun.java.util.collections.HashMap hashmap = null;
            if(!flag2)
            {
                hashmap = oracle.apps.bis.pmv.common.LookUpHelper.getDelegationsForMore();
                if(hashmap != null)
                    k1 = hashmap.size() / 3;
                if(k1 > 10)
                {
                    int l1 = k1 - 10;
                    k1 -= l1;
                }
            }
            int i2 = 15;
            if(k1 > 0)
                i2 -= k1;
            for(int j2 = 0; j2 < alookup.length; j2++)
            {
                if(j2 < i2)
                {
                    boolean flag15 = false;
                    if("All".equals(alookup[j2].getCode()) || "All".equals(alookup[j2].getMeaning()) || s9.equals(alookup[j2].getMeaning()))
                        flag15 = true;
                    java.lang.String s23;
                    if(flag && !flag15)
                        s23 = od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getEncryptedCode(alookup[j2].getCode(), aolsecurity);
                    else
                        s23 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getEscapedHTML(alookup[j2].getCode());
                    if(j2 <= 0 || !flag15)
                    {
                        if(alookup[j2].getCode().equals(s1))
                        {
                            flag12 = false;
                            s16 = s23;
                        } else
                        if(s9.equals(s2))
                            flag12 = false;
                        java.lang.String s21 = alookup[j2].getMeaning();
                        if("pTimeFromParameter".equals(s))
                            s23 = "Tf" + k + s23;
                        else
                        if("pTimeToParameter".equals(s))
                            s23 = "Tt" + k + s23;
                        if("ALL".equalsIgnoreCase(alookup[j2].getCode()) && flag3)
                            s23 = s4 + s23;
                        else
                        if("ALL".equalsIgnoreCase(alookup[j2].getCode()))
                            s23 = s19 + s23;
                        if(flag1 && s21.indexOf("&nbsp;") == 0)
                        {
                            java.lang.String s27;
                            for(s27 = s21; s27.indexOf("&nbsp;") == 0; s27 = s27.substring(6, s27.length()));
                            if(s27.length() + 3 > i)
                                i = s27.length() + 3;
                        } else
                        if(s21.length() > i)
                            i = s21.length();
                        od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.addComboLookUp(arraylist7, arraylist9, arraylist10, arraylist11, arraylist8, arraylist12, s4, s19, s23, s, s21, s2, flag3, flag1, pagecontext, s15);
                    }
                    continue;
                }
                java.lang.String s24 = "";
                if(flag12 && !"^~]*All".equals(s1))
                    s16 = od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.addSelectedLookUp(arraylist7, arraylist9, arraylist10, arraylist11, arraylist8, arraylist12, s4, s19, s14, s, s1, s2, flag1, flag, flag3, aolsecurity, pagecontext, null, s9, arraylist.size(), alookup);
                flag13 = true;
                s24 = s19 + "MORE";
                od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.addComboLookUp(arraylist7, arraylist9, arraylist10, arraylist11, arraylist8, arraylist12, s4, s19, s24, s, s7, s2, flag3, flag1, pagecontext, null);
                break;
            }

            if(!flag9 && !flag2 && k1 > 0)
            {
                if(!flag13)
                    od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.addComboLookUp(arraylist7, arraylist9, arraylist10, arraylist11, arraylist8, null, "", "", "", "", "", "", true, false, null, null);
                for(int l2 = 0; l2 < k1; l2++)
                {
                    java.lang.String s25;
                    if(flag)
                        s25 = od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getEncryptedCode((java.lang.String)hashmap.get("code" + l2), aolsecurity);
                    else
                        s25 = (java.lang.String)hashmap.get("code" + l2);
                    od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.addComboLookUp(arraylist7, arraylist9, arraylist10, arraylist11, arraylist8, arraylist12, s4, s19, s25, s, (java.lang.String)hashmap.get("description" + l2), s2, flag3, flag1, pagecontext, null);
                }

            } else
            if(flag9)
            {
                java.lang.String s26 = null;
                s16 = od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.addSelectedLookUp(arraylist7, arraylist9, arraylist10, arraylist11, arraylist8, arraylist12, s4, s19, s14, s, s1, s2, flag1, flag, flag3, aolsecurity, pagecontext, null, s9, arraylist.size(), alookup);
                s26 = s19 + "MORE";
                od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.addComboLookUp(arraylist7, arraylist9, arraylist10, arraylist11, arraylist8, arraylist12, s4, s19, s26, s, s7, s2, flag3, flag1, pagecontext, null);
                if(!"All".equals(s26))
                {
                    i = (((java.lang.String)arraylist11.get(arraylist11.size() - 1)).length() - s7.length()) + s2.length();
                    j = i;
                }
            }
            if(arraylist12.size() > 0)
            {
                for(int k2 = 0; k2 < arraylist12.size(); k2++)
                    stringbuffer1.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getHiddenIdField(s19 + k2, (java.lang.String)arraylist12.get(k2)));

            }
            if(j == 0 || j > 0 && j > i)
                j = i;
            if(s.startsWith("pTime") && j < 15)
                j = 15;
            stringbuffer1.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getMultiDimComboIconHtml(arraylist7, arraylist8, arraylist9, arraylist10, arraylist11, s, s19, s18, s5, j, flag3, s14, s8, k1, s11));
        }

        i = j;
        if(flag9 && s9.equals(s2) && !s9.equals(s10))
            s2 = s7;
        i = s2.length();
        java.lang.String s17 = "1.0";
        double d = 0.0D;
        boolean flag10 = true;
        for(int l = 0; l < i; l++)
            if(java.lang.Character.isUpperCase(s2.charAt(l)) || java.lang.Character.isWhitespace(s2.charAt(l)))
            {
                d += 0.25D;
            } else
            {
                d += 0.20000000000000001D;
                flag10 = false;
            }

        if(i < 10)
            d += 0.10000000000000001D;
        if(flag10)
            d += 0.38D;
        if(d > 3.7000000000000002D)
        {
            s17 = "3.7";
        } else
        {
            s17 = java.lang.String.valueOf(d);
            try
            {
                s17 = s17.substring(0, s17.indexOf(".") + 3);
            }
            catch(java.lang.Exception _ex)
            {
                s17 = java.lang.String.valueOf(d);
            }
        }
        if(!flag4)
            s13 = null;
        if(flag && s16.equals(s1))
            s16 = od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getEncryptedCode(s1, aolsecurity);
        if(s12.startsWith("mnuVal"))
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getHiddenIdField(s, s16));
        else
        if(flag4)
        {
            if("^~]*All".equals(s1) || s9.equals(s2))
                stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getHiddenIdField(s, "All"));
            else
                stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getHiddenIdField(s, s16));
        } else
        if("^~]*All".equals(s1) || s9.equals(s2))
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getHiddenIdField("div" + s, "All"));
        else
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getHiddenIdField("div" + s, s16));
        if(s12.startsWith("mnuVal"))
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getTextInpString("divs" + s, s2, s17, s6, s13, null, flag4));
        else
        if(flag4)
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getTextInpString("div" + s, s2, s17, s6, s13, null, flag4));
        else
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getTextInpString(s, s2, s17, s6, s13, null, flag4));
        stringbuffer.append(stringbuffer1.toString());
        return stringbuffer.toString();
    }

    public static java.lang.String getDimComboList(java.lang.String s, java.lang.String s1, java.lang.String s2, com.sun.java.util.collections.ArrayList arraylist, com.sun.java.util.collections.ArrayList arraylist1, java.lang.String s3, java.lang.String s4, java.lang.String s5,
            com.sun.java.util.collections.ArrayList arraylist2, javax.servlet.jsp.PageContext pagecontext)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        java.lang.StringBuffer stringbuffer1 = new StringBuffer(500);
        com.sun.java.util.collections.ArrayList arraylist3 = new ArrayList(3);
        com.sun.java.util.collections.ArrayList arraylist4 = new ArrayList(3);
        com.sun.java.util.collections.ArrayList arraylist5 = new ArrayList(3);
        com.sun.java.util.collections.ArrayList arraylist6 = new ArrayList(3);
        com.sun.java.util.collections.ArrayList arraylist7 = new ArrayList(3);
        int i = 2;
        java.lang.String s6 = "btnClk('" + s4 + "', '" + s + "', event)";
        if(arraylist2 != null && arraylist2.size() > 1)
        {
            stringbuffer1.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getTriIconHtml(s4 + "M0", s, "", false));
            com.sun.java.util.collections.ArrayList arraylist8 = new ArrayList(4);
            com.sun.java.util.collections.ArrayList arraylist10 = new ArrayList(4);
            for(int k = 0; k < arraylist2.size(); k++)
            {
                oracle.apps.bis.pmv.parameters.Hierarchy hierarchy = (oracle.apps.bis.pmv.parameters.Hierarchy)arraylist2.get(k);
                java.lang.String s10 = hierarchy.getHierarchyId();
                com.sun.java.util.collections.ArrayList arraylist9 = hierarchy.getLevels();
                com.sun.java.util.collections.ArrayList arraylist11 = hierarchy.getLevelLabels();
                java.lang.String s11 = s4 + "M" + k;
                s6 = "btnClk('" + s4 + "', '" + s + "', event)";
                arraylist3 = new ArrayList(4);
                arraylist4 = new ArrayList(4);
                arraylist5 = new ArrayList(4);
                arraylist6 = new ArrayList(4);
                arraylist7 = new ArrayList(4);
                for(int i1 = 0; i1 < arraylist9.size(); i1++)
                {
                    java.lang.String s12 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getEscapedHTML((java.lang.String)arraylist9.get(i1));
                    java.lang.String s13 = (java.lang.String)arraylist11.get(i1);
                    od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.addDimComboLkUp(arraylist3, arraylist5, arraylist6, arraylist7, arraylist4, s11, s12, s13, s, pagecontext);
                    if(((java.lang.String)arraylist1.get(i1)).length() > i)
                        i = ((java.lang.String)arraylist1.get(i1)).length();
                }

                stringbuffer1.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getMultiDimComboIconHtml(arraylist3, arraylist4, arraylist5, arraylist6, arraylist7, s, s11, "", s5, i, true, s10, null, 0, null));
            }

        } else
        {
            stringbuffer1.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getTriIconHtml(s4, s, "", false));
            for(int j = 0; j < arraylist.size(); j++)
            {
                java.lang.String s8 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getEscapedHTML((java.lang.String)arraylist.get(j));
                java.lang.String s9 = (java.lang.String)arraylist1.get(j);
                od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.addDimComboLkUp(arraylist3, arraylist5, arraylist6, arraylist7, arraylist4, s4, s8, s9, s, pagecontext);
                if(((java.lang.String)arraylist1.get(j)).length() > i)
                    i = ((java.lang.String)arraylist1.get(j)).length();
            }

            stringbuffer1.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getMultiDimComboIconHtml(arraylist3, arraylist4, arraylist5, arraylist6, arraylist7, s, s4, "", s5, i, true, null, null, 0, null));
        }
        java.lang.String s7 = "1.0";
        double d = 0.0D;
        i = s2.length();
        for(int l = 0; l < i; l++)
            if(java.lang.Character.isUpperCase(s2.charAt(l)) || java.lang.Character.isWhitespace(s2.charAt(l)))
                d += 0.23999999999999999D;
            else
                d += 0.19D;

        if(i < 10)
            d += 0.10000000000000001D;
        s7 = java.lang.String.valueOf(d);
        try
        {
            s7 = s7.substring(0, s7.indexOf(".") + 3);
        }
        catch(java.lang.Exception _ex)
        {
            s7 = java.lang.String.valueOf(d);
        }
        s6 = null;
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getHiddenIdField(s, s1));
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getTextInpString("div" + s, s2, s7, null, null, null, true));
        stringbuffer.append(stringbuffer1.toString());
        return stringbuffer.toString();
    }

    public static java.lang.String getComboItemHtml(java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, com.sun.java.util.collections.ArrayList arraylist, com.sun.java.util.collections.ArrayList arraylist1, com.sun.java.util.collections.ArrayList arraylist2, com.sun.java.util.collections.ArrayList arraylist3,
            com.sun.java.util.collections.ArrayList arraylist4, boolean flag, java.lang.String s4, java.lang.String s5, java.lang.String s6, java.lang.String s7, java.lang.String s8,
            java.lang.String s9, boolean flag1, int i, boolean flag2)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        java.lang.String s10 = "1.0";
        double d;
        if(i <= 6)
            d = (double)i * 0.20999999999999999D;
        else
        if(i <= 10)
            d = (double)i * 0.19D;
        else
            d = (double)i * 0.16D;
        if(d > 3.7000000000000002D)
            s10 = "3.7";
        else
        if(d < 1.5D)
        {
            s10 = "1.5";
        } else
        {
            s10 = java.lang.String.valueOf(d);
            try
            {
                s10 = s10.substring(0, s10.indexOf(".") + 3);
            }
            catch(java.lang.Exception _ex)
            {
                s10 = java.lang.String.valueOf(d);
            }
        }
        java.lang.String s11 = "btnClk('" + s6 + "', '" + s + "', event)";
        if(!flag2)
            s11 = null;
        if(s6.startsWith("mnuVal"))
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getHiddenIdField(s, s2));
        else
        if("^~]*All".equals(s2))
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getHiddenIdField("div" + s, "All"));
        else
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getHiddenIdField("div" + s, s2));
        if(s6.startsWith("mnuVal"))
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getTextInpString("divs" + s, s3, s10, s9, s11, null, true));
        else
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getTextInpString(s, s3, s10, s9, s11, null, false));
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getComboIconHtml(arraylist, arraylist1, arraylist2, arraylist3, arraylist4, s, s6, s7, s8, i, flag2));
        return stringbuffer.toString();
    }

    public static java.lang.String getMultiDimComboIconHtml(com.sun.java.util.collections.ArrayList arraylist, com.sun.java.util.collections.ArrayList arraylist1, com.sun.java.util.collections.ArrayList arraylist2, com.sun.java.util.collections.ArrayList arraylist3, com.sun.java.util.collections.ArrayList arraylist4, java.lang.String s, java.lang.String s1, java.lang.String s2,
            java.lang.String s3, int i, boolean flag, java.lang.String s4, java.lang.String s5, int j, java.lang.String s6)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        stringbuffer.append("<table id=\"").append(s1).append("\"");
        if(s1.indexOf("M") > 0 && s4 != null)
            stringbuffer.append(" name=\"").append(s1.substring(0, s1.indexOf("M") + 1)).append(s4).append("\"");
        stringbuffer.append(" class=\"menu\">");
        boolean flag1 = false;
        boolean flag2 = false;
        if(!flag)
        {
            stringbuffer.append("<tr><td id=\"").append(s1).append("cls\" class=\"mMenuItem\" onclick=\"clickApply(event)\"");
            stringbuffer.append(" onmouseover=\"miMovr('").append(s1).append("cls')\" onmouseout=\"miMcout('").append(s1).append("cls')\")");
            stringbuffer.append("  align=\"right\" valign=\"center\" style=\"size:8pt;font-family:Arial, Helvetica, Geneva, sans-serif;color:#336699\"> ");
            stringbuffer.append(s5);
            stringbuffer.append(" </td></tr>");
        }
        for(int k = 0; k < arraylist.size(); k++)
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString((java.lang.String)arraylist.get(k)))
            {
                if((s1 + "MORE").equals((java.lang.String)arraylist.get(k)))
                {
                    stringbuffer.append("<tr><td ><hr noshade color=\"lightgrey\" size=\"1\"></hr></td></tr>");
                    flag2 = true;
                }
                stringbuffer.append("<tr><td id=\"").append(arraylist.get(k));
                if(flag)
                    stringbuffer.append("\" class=\"menuItem\"");
                else
                    stringbuffer.append("\" class=\"mMenuItem\"");
                if(!arraylist1.isEmpty())
                    stringbuffer.append(" onclick=\"").append(arraylist1.get(k));
                stringbuffer.append("\" onmouseover=\"").append(arraylist2.get(k)).append("\" onmouseout=\"").append(arraylist3.get(k));
                stringbuffer.append("\">");
                if("pParameterViewBy".equals(s))
                {
                    java.lang.String s7 = (java.lang.String)arraylist4.get(k);
                    if(s7.indexOf("-") >= 0)
                        stringbuffer.append(s7.substring(s7.indexOf("-") + 1));
                    else
                        stringbuffer.append(s7);
                } else
                {
                    stringbuffer.append(arraylist4.get(k));
                }
                if(i <= ((java.lang.String)arraylist4.get(k)).length())
                {
                    flag1 = true;
                    if(i < 25)
                        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.addSpace(6));
                    else
                    if(i < 35)
                        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.addSpace(5));
                    else
                    if(i < 45)
                        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.addSpace(10));
                    else
                        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.addSpace(2));
                }
                if(!flag1 && k == arraylist.size() - 1)
                    stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.addSpace(((i - ((java.lang.String)arraylist4.get(k)).length()) * 3) / 2 + 3));
                stringbuffer.append(" </td></tr>");
                if(flag2 && j > 0)
                {
                    stringbuffer.append("<tr><td ><hr noshade color=\"lightgrey\" size=\"1\"></hr></td></tr>");
                    flag2 = false;
                }
            } else
            {
                stringbuffer.append("<tr><td ><hr noshade color=\"lightgrey\" size=\"1\"></hr></td></tr>");
            }

        stringbuffer.append("  </table>");
        return stringbuffer.toString();
    }

    public static java.lang.String getComboIconHtml(com.sun.java.util.collections.ArrayList arraylist, com.sun.java.util.collections.ArrayList arraylist1, com.sun.java.util.collections.ArrayList arraylist2, com.sun.java.util.collections.ArrayList arraylist3, com.sun.java.util.collections.ArrayList arraylist4, java.lang.String s, java.lang.String s1, java.lang.String s2,
            java.lang.String s3, int i, boolean flag)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        boolean flag1 = false;
        stringbuffer.append("<a href=\"javascript:btnClk('").append(s1).append("', '").append(s).append("', event)\"");
        stringbuffer.append(" onclick=\"btnClk('").append(s1).append("', '").append(s).append("', event);return false;\">");
        stringbuffer.append("<img src=\"");
        stringbuffer.append("/OA_MEDIA/bistrian.gif\" alt='' title=\"").append(s2).append("\" border=\"0\" align=\"absmiddle\"></a> &nbsp;&nbsp; ");
        stringbuffer.append("<table id=\"").append(s1).append("\" class=\"menu\">");
        for(int j = 0; j < arraylist.size(); j++)
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString((java.lang.String)arraylist.get(j)))
            {
                if("CALENDAR".equals((java.lang.String)arraylist.get(j)))
                    stringbuffer.append("<tr><td ><hr noshade color=\"lightgrey\" size=\"1\"></hr></td></tr>");
                stringbuffer.append("<tr><td id=\"");
                if(!"pParameterViewBy".equals(s))
                    stringbuffer.append(arraylist.get(j));
                else
                    stringbuffer.append("vb" + arraylist.get(j));
                if(flag)
                    stringbuffer.append("\" class=\"menuItem\"");
                else
                    stringbuffer.append("\" class=\"mMenuItem\"");
                if(!arraylist1.isEmpty())
                    stringbuffer.append(" onclick=\"").append(arraylist1.get(j));
                stringbuffer.append("\" onmouseover=\"").append(arraylist2.get(j)).append("\" onmouseout=\"").append(arraylist3.get(j));
                stringbuffer.append("\">");
                if("pParameterViewBy".equals(s))
                {
                    java.lang.String s4 = (java.lang.String)arraylist4.get(j);
                    if(s4.indexOf("-") >= 0)
                        stringbuffer.append(s4.substring(s4.indexOf("-") + 1));
                    else
                        stringbuffer.append(s4);
                } else
                {
                    stringbuffer.append(arraylist4.get(j));
                }
                if(i <= ((java.lang.String)arraylist4.get(j)).length())
                {
                    flag1 = true;
                    if(i < 5)
                        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.addSpace(4));
                    else
                    if(i < 9)
                        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.addSpace(3));
                    else
                        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.addSpace(2));
                }
                if(!flag1 && j == arraylist.size() - 1)
                    stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.addSpace(((i - ((java.lang.String)arraylist4.get(j)).length()) * 3) / 2 + 2));
                stringbuffer.append(" </td></tr>");
            }

        stringbuffer.append("  </table>");
        return stringbuffer.toString();
    }

    public static java.lang.String getPortletComboTimeViewByCompareHtml(com.sun.java.util.collections.ArrayList arraylist, com.sun.java.util.collections.ArrayList arraylist1, java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, java.lang.String s4, java.lang.String s5,
            java.lang.String s6, boolean flag, javax.servlet.jsp.PageContext pagecontext)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        stringbuffer.append(" <TABLE class=DbiParameterTable style=\"DISPLAY: inline\" cellSpacing=0 cellPadding=1 border=0>");
        stringbuffer.append("<TBODY>");
        stringbuffer.append("<TR>");
        stringbuffer.append("<TD class=OraInstructionText noWrap>").append(s6).append("</TD>");
        stringbuffer.append("<TD class=OraInstructionText noWrap>");
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getComboTimeViewByCompareHtml(arraylist, arraylist1, s, s1, s2, s3, s4, s5, flag, pagecontext));
        stringbuffer.append("<TD align=middle width=10>&nbsp;</TD>");
        stringbuffer.append("</TR>");
        stringbuffer.append("</TBODY>");
        stringbuffer.append("</TABLE>");
        return stringbuffer.toString();
    }

    public static java.lang.String getComboTimeViewByCompareHtml(com.sun.java.util.collections.ArrayList arraylist, com.sun.java.util.collections.ArrayList arraylist1, java.lang.String s, java.lang.String s1, java.lang.String s2, java.lang.String s3, java.lang.String s4, java.lang.String s5,
            boolean flag, javax.servlet.jsp.PageContext pagecontext)
    {
        java.lang.String s6 = "";
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        com.sun.java.util.collections.ArrayList arraylist2 = new ArrayList(4);
        com.sun.java.util.collections.ArrayList arraylist3 = new ArrayList(4);
        com.sun.java.util.collections.ArrayList arraylist4 = new ArrayList(4);
        int i = 2;
        for(int j = 0; j < arraylist.size(); j++)
        {
            java.lang.String s7 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getEscapedHTML((java.lang.String)arraylist.get(j));
            if(!"pParameterViewBy".equals(s))
            {
                arraylist2.add("miMovr('" + s7 + "')");
                arraylist3.add("miMout('" + s7 + "')");
            } else
            {
                arraylist2.add("miMovr('vb" + s7 + "')");
                arraylist3.add("miMout('vb" + s7 + "')");
            }
            arraylist4.add("miSel('" + s1 + "', '" + s7 + "', '" + od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getEscapedHTML((java.lang.String)arraylist1.get(j)) + "', '" + s + "', '" + s7 + "')");
            if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s7) && ((java.lang.String)arraylist1.get(j)).length() > i)
                i = ((java.lang.String)arraylist1.get(j)).length();
        }

        double d = 0.0D;
        i = s4.length();
        for(int k = 0; k < i; k++)
            if(java.lang.Character.isUpperCase(s4.charAt(k)) || java.lang.Character.isWhitespace(s4.charAt(k)))
                d += 0.25D;
            else
                d += 0.20000000000000001D;

        if(i < 6)
            d += 0.25D;
        else
        if(i < 10)
            d += 0.10000000000000001D;
        if(d > 3.7000000000000002D)
            d = 3.7000000000000002D;
        java.lang.String s8 = java.lang.String.valueOf(d);
        try
        {
            s8 = s8.substring(0, s8.indexOf(".") + 3);
        }
        catch(java.lang.Exception _ex)
        {
            s8 = java.lang.String.valueOf(d);
        }
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getHiddenIdField(s, s3));
        java.lang.String s9 = "btnClk('" + s1 + "', '" + s + "', event)";
        if(!flag)
            s9 = null;
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getTextInpString("divs" + s, s4, s8, s5, s9, null, true));
        stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getComboIconHtml(arraylist, arraylist4, arraylist2, arraylist3, arraylist1, s, s1, s6, s2, i, flag));
        return stringbuffer.toString();
    }

    public static com.sun.java.util.collections.ArrayList getCalendarIdValues(boolean flag)
    {
        com.sun.java.util.collections.ArrayList arraylist = new ArrayList(11);
        arraylist.add("TODAY");
        if(!flag)
            arraylist.add("YESTERDAY");
        arraylist.add("LWEEK");
        arraylist.add("LPERIOD");
        arraylist.add("LQTR");
        arraylist.add("LYEAR");
        if(!flag)
        {
            arraylist.add("WEND");
            arraylist.add("PEND");
            arraylist.add("QEND");
            arraylist.add("YEND");
        }
        arraylist.add("CALENDAR");
        return arraylist;
    }

    public static com.sun.java.util.collections.ArrayList getCalendarMouseOverValues(boolean flag)
    {
        com.sun.java.util.collections.ArrayList arraylist = new ArrayList(11);
        arraylist.add("miMovr('TODAY')");
        if(!flag)
            arraylist.add("miMovr('YESTERDAY')");
        arraylist.add("miMovr('LWEEK')");
        arraylist.add("miMovr('LPERIOD')");
        arraylist.add("miMovr('LQTR')");
        arraylist.add("miMovr('LYEAR')");
        if(!flag)
        {
            arraylist.add("miMovr('WEND')");
            arraylist.add("miMovr('PEND')");
            arraylist.add("miMovr('QEND')");
            arraylist.add("miMovr('YEND')");
        }
        arraylist.add("miMovr('CALENDAR')");
        return arraylist;
    }

    public static com.sun.java.util.collections.ArrayList getCalendarMouseOutValues(boolean flag)
    {
        com.sun.java.util.collections.ArrayList arraylist = new ArrayList(11);
        arraylist.add("miMout('TODAY')");
        if(!flag)
            arraylist.add("miMout('YESTERDAY')");
        arraylist.add("miMout('LWEEK')");
        arraylist.add("miMout('LPERIOD')");
        arraylist.add("miMout('LQTR')");
        arraylist.add("miMout('LYEAR')");
        if(!flag)
        {
            arraylist.add("miMout('WEND')");
            arraylist.add("miMout('PEND')");
            arraylist.add("miMout('QEND')");
            arraylist.add("miMout('YEND')");
        }
        arraylist.add("miMout('CALENDAR')");
        return arraylist;
    }

    public static com.sun.java.util.collections.ArrayList getCalendarShownValues(oracle.apps.fnd.common.WebAppsContext webappscontext, java.lang.String s, oracle.apps.bis.pmv.parameters.PopDateValues popdatevalues, boolean flag)
    {
        com.sun.java.util.collections.ArrayList arraylist = new ArrayList(11);
        arraylist.add(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_TODAY", webappscontext));
        if(!flag)
        {
            arraylist.add(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_YESTERDAY", webappscontext) + " (" + popdatevalues.getYesterDateStr() + ") ");
            arraylist.add(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_LWEEK", webappscontext) + " (" + popdatevalues.getLastWeekEndStr() + ") ");
            arraylist.add(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_LPERIOD", webappscontext) + " (" + popdatevalues.getLastPeriodEndStr() + ") ");
            arraylist.add(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_LQTR", webappscontext) + " (" + popdatevalues.getLastQtrEndStr() + ") ");
            arraylist.add(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_LYEAR", webappscontext) + " (" + popdatevalues.getLastYearEndStr() + ") ");
            arraylist.add(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_WEND", webappscontext) + " (" + popdatevalues.getWeekEndStr() + ") ");
            arraylist.add(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_PEND", webappscontext) + " (" + popdatevalues.getPeriodEndStr() + ") ");
            arraylist.add(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_QEND", webappscontext) + " (" + popdatevalues.getQtrEndStr() + ") ");
            arraylist.add(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_YEND", webappscontext) + " (" + popdatevalues.getYearEndStr() + ") ");
        } else
        {
            arraylist.add(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_RWEEK", webappscontext));
            arraylist.add(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_RPERIOD", webappscontext));
            arraylist.add(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_RQTR", webappscontext));
            arraylist.add(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_RYEAR", webappscontext));
        }
        arraylist.add(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_CALENDAR", webappscontext));
        return arraylist;
    }

    public static com.sun.java.util.collections.ArrayList getCalendarClickValues(java.lang.String s, java.lang.String s1, oracle.apps.bis.pmv.parameters.PopDateValues popdatevalues, boolean flag)
    {
        com.sun.java.util.collections.ArrayList arraylist = new ArrayList(11);
        arraylist.add("dtMiSel('" + s + "','" + popdatevalues.getSysDateStr() + "','" + s1 + "')");
        if(!flag)
            arraylist.add("dtMiSel('" + s + "','" + popdatevalues.getYesterDateStr() + "','" + s1 + "')");
        arraylist.add("dtMiSel('" + s + "','" + popdatevalues.getLastWeekEndStr() + "','" + s1 + "')");
        arraylist.add("dtMiSel('" + s + "','" + popdatevalues.getLastPeriodEndStr() + "','" + s1 + "')");
        arraylist.add("dtMiSel('" + s + "','" + popdatevalues.getLastQtrEndStr() + "','" + s1 + "')");
        arraylist.add("dtMiSel('" + s + "','" + popdatevalues.getLastYearEndStr() + "','" + s1 + "')");
        if(!flag)
        {
            arraylist.add("dtMiSel('" + s + "','" + popdatevalues.getWeekEndStr() + "','" + s1 + "')");
            arraylist.add("dtMiSel('" + s + "','" + popdatevalues.getPeriodEndStr() + "','" + s1 + "')");
            arraylist.add("dtMiSel('" + s + "','" + popdatevalues.getQtrEndStr() + "','" + s1 + "')");
            arraylist.add("dtMiSel('" + s + "','" + popdatevalues.getYearEndStr() + "','" + s1 + "')");
        }
        arraylist.add("dtMiSel('" + s + "','CALENDAR','" + s1 + "')");
        return arraylist;
    }

    public static java.lang.String addSpace(int i)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append(" ");
        for(int j = 0; j < i; j++)
            stringbuffer.append("&nbsp;");

        return stringbuffer.toString();
    }

    public static java.lang.String getTriIconHtml(java.lang.String s, java.lang.String s1, java.lang.String s2, boolean flag)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        stringbuffer.append("<a href=\"javascript:btnClk('").append(s).append("', '").append(s1).append("', event)\"");
        stringbuffer.append(" onclick=\"btnClk('").append(s).append("', '").append(s1).append("', event);return false;\">");
        stringbuffer.append("<img src=\"");
        stringbuffer.append("/OA_MEDIA/bistrian.gif\" title=\"").append(s2).append("\" border=\"0\" align=\"absmiddle\" alt=\"\" ></a> ");
        if(flag)
            stringbuffer.append("&nbsp;&nbsp; ");
        return stringbuffer.toString();
    }

    public static void addDimComboLkUp(com.sun.java.util.collections.ArrayList arraylist, com.sun.java.util.collections.ArrayList arraylist1, com.sun.java.util.collections.ArrayList arraylist2, com.sun.java.util.collections.ArrayList arraylist3, com.sun.java.util.collections.ArrayList arraylist4, java.lang.String s, java.lang.String s1, java.lang.String s2,
            java.lang.String s3, javax.servlet.jsp.PageContext pagecontext)
    {
        if(s.startsWith("mnuDim") && s.indexOf("M") > 0)
        {
            java.lang.String s4 = s.substring(s.length() - 1) + s1;
            arraylist.add(s4);
            arraylist1.add("miMovr('" + s4 + "')");
            arraylist2.add("miMout('" + s4 + "')");
        } else
        {
            arraylist.add(s1);
            arraylist1.add("miMovr('" + s1 + "')");
            arraylist2.add("miMout('" + s1 + "')");
        }
        arraylist3.add(s2);
        arraylist4.add("dimMiSel('" + s + "', '" + s1 + "', '" + od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getEscapedHTML(s2) + "','" + s3 + "')");
    }

    public static void addComboLookUp(com.sun.java.util.collections.ArrayList arraylist, com.sun.java.util.collections.ArrayList arraylist1, com.sun.java.util.collections.ArrayList arraylist2, com.sun.java.util.collections.ArrayList arraylist3, com.sun.java.util.collections.ArrayList arraylist4, com.sun.java.util.collections.ArrayList arraylist5, java.lang.String s, java.lang.String s1,
            java.lang.String s2, java.lang.String s3, java.lang.String s4, java.lang.String s5, boolean flag, boolean flag1, javax.servlet.jsp.PageContext pagecontext,
            java.lang.String s6)
    {
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s6))
            s2 = s6 + s2;
        arraylist.add(s2);
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s2))
        {
            arraylist1.add("");
            arraylist2.add("");
        } else
        {
            arraylist1.add("miMovr('" + s2 + "')");
            arraylist2.add("miMout('" + s2 + "')");
        }
        if(flag)
        {
            arraylist3.add(s4);
        } else
        {
            java.lang.StringBuffer stringbuffer = new StringBuffer(200);
            stringbuffer.append("<LABEL style=\"display:none\" for=\"").append(s1).append(s2).append("\" >.</LABEL>");
            stringbuffer.append("<input id=\"").append(s1).append(s2).append("\" type=\"checkbox\" value=\"on\"");
            if((s1 + "All").equals(s2) || (s1 + "MORE").equals(s2))
                stringbuffer.append(" style=\"visibility:hidden\"");
            stringbuffer.append(">&nbsp;").append(s4);
            arraylist3.add(stringbuffer.toString());
            if(!s2.equalsIgnoreCase(s1 + "ALL"))
                if(s5.indexOf(s4) == 0 && s5.trim().length() == s4.length())
                    arraylist5.add(s1 + s2);
                else
                if(s5.indexOf(s4) >= 0)
                {
                    int i = s5.indexOf(s4) + s4.length();
                    int j = s5.length();
                    if(j == i)
                        arraylist5.add(s1 + s2);
                    else
                    if(j > i && s5.substring(i, i + 1).equals("^"))
                        arraylist5.add(s1 + s2);
                }
        }
        if(flag1 && s4.indexOf("&nbsp;") == 0)
            for(; s4.indexOf("&nbsp;") == 0; s4 = s4.substring(6, s4.length()));
        if((s1 + "MORE").equals(s2))
        {
            arraylist4.add("miSel('" + s1 + "', '^*^MORE^*^', '" + od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getEscapedHTML(s4) + "', '" + s3 + "', '" + s + "')");
            return;
        }
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s6))
            s2 = s2.substring(s6.length());
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s2))
        {
            arraylist4.add("");
            return;
        } else
        {
            arraylist4.add("miSel('" + s1 + "', '" + s2 + "', '" + od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getEscapedHTML(s4) + "', '" + s3 + "', '" + s + "')");
            return;
        }
    }

    public static java.lang.String getRtfLastUpdateString(java.lang.String s, oracle.apps.bis.pmv.session.UserSession usersession)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getLastUpdateStringWithoutSpan(s);
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
        {
            stringbuffer.append("<LASTUPDATE>");
            stringbuffer.append("\n");
            stringbuffer.append("<![CDATA[");
            stringbuffer.append(s1);
            stringbuffer.append("]]>");
            stringbuffer.append("\n");
            stringbuffer.append("</LASTUPDATE>");
            stringbuffer.append("\n");
        }
        return stringbuffer.toString();
    }

    public static java.lang.String getPdfCopyRight(oracle.apps.fnd.common.WebAppsContext webappscontext)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        java.lang.String s = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BISCPYRT", webappscontext);
        java.lang.String s1 = oracle.apps.bis.pmv.common.StringUtil.replaceAll(s, "&COPY;", "&#169;");
        stringbuffer.append("<COPYRIGHT>");
        stringbuffer.append("\n");
        stringbuffer.append(s1);
        stringbuffer.append("\n");
        stringbuffer.append("</COPYRIGHT>");
        stringbuffer.append("\n");
        return stringbuffer.toString();
    }

    public static java.lang.String addSelectedLookUp(com.sun.java.util.collections.ArrayList arraylist, com.sun.java.util.collections.ArrayList arraylist1, com.sun.java.util.collections.ArrayList arraylist2, com.sun.java.util.collections.ArrayList arraylist3, com.sun.java.util.collections.ArrayList arraylist4, com.sun.java.util.collections.ArrayList arraylist5, java.lang.String s, java.lang.String s1,
            java.lang.String s2, java.lang.String s3, java.lang.String s4, java.lang.String s5, boolean flag, boolean flag1, boolean flag2,
            oracle.apps.fnd.security.AolSecurity aolsecurity, javax.servlet.jsp.PageContext pagecontext, java.lang.String s6, java.lang.String s7, int i, oracle.apps.bis.pmv.common.LookUp alookup[])
    {
        if(i < 2 || s.equals(s2))
        {
            java.lang.String s10 = s5;
            if(!s7.equals(s5))
            {
                if(flag2 || s10.indexOf("^^") < 0)
                {
                    java.lang.String s8;
                    if(flag1)
                        s8 = od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getEncryptedCode(s4, aolsecurity);
                    else
                        s8 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getEscapedHTML(s4);
                    s10 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getEscapedHTML(s5);
                    if(arraylist.size() >= 15)
                    {
                        arraylist.remove(14);
                        arraylist1.remove(14);
                        arraylist2.remove(14);
                        arraylist3.remove(14);
                        arraylist4.remove(14);
                    }
                    od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.addComboLookUp(arraylist, arraylist1, arraylist2, arraylist3, arraylist4, arraylist5, s, s1, s8, s3, s10, s5, flag2, flag, pagecontext, null);
                    return s8;
                }
                java.lang.String s9 = s4;
                boolean aflag[] = new boolean[15];
                while(s10.indexOf("^^") >= 0)
                {
                    java.lang.String s11 = s10.substring(0, s10.indexOf("^^"));
                    s10 = s10.substring(s10.indexOf("^^") + 2);
                    java.lang.String s12 = s9.substring(0, s9.indexOf("^^"));
                    if(flag1)
                        s12 = od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getEncryptedCode(s12, aolsecurity);
                    s9 = s9.substring(s9.indexOf("^^") + 2);
                    int i2 = od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.checkMultiAdd(alookup, s11);
                    int j = -1;
                    if(i2 > -1)
                        aflag[i2] = true;
                    if(i2 == -1)
                    {
                        for(int l = arraylist.size() - 1; l >= 0;)
                            try
                            {
                                if(aflag[l] || "All".equals(alookup[l].getMeaning()))
                                    continue;
                                j = l;
                                break;
                            }
                            catch(java.lang.Exception _ex)
                            {
                                l--;
                            }

                        if(j >= 0)
                        {
                            for(int j1 = j; j1 < arraylist.size() - 1; j1++)
                            {
                                arraylist.set(j1, arraylist.get(j1 + 1));
                                arraylist1.set(j1, arraylist1.get(j1 + 1));
                                arraylist2.set(j1, arraylist2.get(j1 + 1));
                                arraylist3.set(j1, arraylist3.get(j1 + 1));
                                arraylist4.set(j1, arraylist4.get(j1 + 1));
                                aflag[j1] = aflag[j1 + 1];
                            }

                            arraylist1.remove(arraylist.size() - 1);
                            arraylist2.remove(arraylist.size() - 1);
                            arraylist3.remove(arraylist.size() - 1);
                            arraylist4.remove(arraylist.size() - 1);
                            aflag[arraylist.size() - 1] = true;
                            arraylist.remove(arraylist.size() - 1);
                        }
                        od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.addComboLookUp(arraylist, arraylist1, arraylist2, arraylist3, arraylist4, arraylist5, s, s1, s12, s3, s11, s5, flag2, flag, pagecontext, null);
                    }
                }
                int k = -1;
                int l1 = od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.checkMultiAdd(alookup, s10);
                if(l1 > -1)
                    aflag[l1] = true;
                if(l1 == -1)
                {
                    for(int i1 = arraylist.size() - 1; i1 >= 0;)
                        try
                        {
                            if(aflag[i1] || "All".equals(alookup[i1].getMeaning()))
                                continue;
                            k = i1;
                            break;
                        }
                        catch(java.lang.Exception _ex)
                        {
                            i1--;
                        }

                    if(k >= 0)
                    {
                        for(int k1 = k; k1 < arraylist.size() - 1; k1++)
                        {
                            arraylist.set(k1, arraylist.get(k1 + 1));
                            arraylist1.set(k1, arraylist1.get(k1 + 1));
                            arraylist2.set(k1, arraylist2.get(k1 + 1));
                            arraylist3.set(k1, arraylist3.get(k1 + 1));
                            arraylist4.set(k1, arraylist4.get(k1 + 1));
                            aflag[k1] = aflag[k1 + 1];
                        }

                        arraylist1.remove(arraylist.size() - 1);
                        arraylist2.remove(arraylist.size() - 1);
                        arraylist3.remove(arraylist.size() - 1);
                        arraylist4.remove(arraylist.size() - 1);
                        aflag[arraylist.size() - 1] = true;
                        arraylist.remove(arraylist.size() - 1);
                    }
                    od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.addComboLookUp(arraylist, arraylist1, arraylist2, arraylist3, arraylist4, arraylist5, s, s1, s9, s3, s10, s5, flag2, flag, pagecontext, null);
                }
            }
        }
        if(flag1)
            return od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getEncryptedCode(s4, aolsecurity);
        else
            return od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getEscapedHTML(s4);
    }

    public static int checkMultiAdd(oracle.apps.bis.pmv.common.LookUp alookup[], java.lang.String s)
    {
        for(int i = 0; i < alookup.length; i++)
            if(i < 15)
            {
                if(alookup[i].getMeaning().equals(s))
                    return i;
            } else
            {
                return -1;
            }

        return -1;
    }

    public static java.lang.String getEncryptedUrl(java.lang.String s, oracle.apps.fnd.framework.OAApplicationModule oaapplicationmodule)
    {
        java.io.Serializable aserializable[] = {
            s
        };
        java.lang.Class aclass[] = {
            java.lang.String.class
        };
        java.lang.String s1 = (java.lang.String)oaapplicationmodule.invokeMethod("getEncryptedUrl", aserializable, aclass);
        return s1;
    }

    public static java.lang.String getDisplayPDFHtml(java.lang.String s, oracle.apps.fnd.framework.webui.OAPageContext oapagecontext, oracle.apps.fnd.framework.OAApplicationModule oaapplicationmodule)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(512);
        java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODHTMLUtil.getEncryptedUrl(s, oaapplicationmodule);
        java.lang.StringBuffer stringbuffer1 = new StringBuffer(256);
        stringbuffer1.append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getJspUrl(oapagecontext.getProfile("APPS_SERVLET_AGENT")));
        stringbuffer1.append("bissched.jsp?pStream=Y&fileid=").append(s1);
        stringbuffer.append("<table><tr></tr><tr></tr><tr></tr><tr></tr><tr><td class=OraDataText> ");
        stringbuffer.append(oapagecontext.getMessage("BIS", "BIS_CLICK", null));
        stringbuffer.append(" <a href=\"").append(stringbuffer1.toString()).append(" \">");
        stringbuffer.append(oapagecontext.getMessage("BIS", "BIS_CLICKONE", null)).append("  </a> ");
        stringbuffer.append(oapagecontext.getMessage("BIS", "BIS_CLICKTWO", null)).append("  </td></tr></table>");
        return stringbuffer.toString();
    }

    public static void addLookUp(java.lang.String s, java.lang.String s1, java.lang.String s2, com.sun.java.util.collections.ArrayList arraylist)
    {
        oracle.apps.bis.pmv.common.LookUp lookup = new LookUp();
        lookup.setCode(s);
        lookup.setId(s1);
        lookup.setMeaning(s2);
        arraylist.add(lookup);
    }

    public static void evaluateIdMeanings(java.lang.String as[], com.sun.java.util.collections.ArrayList arraylist, com.sun.java.util.collections.ArrayList arraylist1)
    {
        if(as[1] != null && as[1].indexOf("^^") >= 0)
        {
            java.lang.String s = as[1];
            java.lang.String s1 = oracle.apps.bis.pmv.common.StringUtil.replaceAll(as[0], "'", "");
            while(s.indexOf("^^") > 0)
            {
                arraylist1.add(s.substring(0, s.indexOf("^^")));
                s = s.substring(s.indexOf("^^") + 2, s.length());
                if(s1.indexOf(",") > 0)
                {
                    arraylist.add(s1.substring(0, s1.indexOf(",")));
                    s1 = s1.substring(s1.indexOf(",") + 1, s1.length());
                }
            }
            arraylist1.add(s.substring(0, s.length()));
            arraylist.add(s1.substring(0, s1.length()));
        }
    }

    public static java.lang.String getSaveModelJS(oracle.apps.bis.pmv.session.UserSession usersession)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        try
        {
            stringbuffer.append("<script> function doWarnForDsg(inpUrl){if (confirm(\"");
            stringbuffer.append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_PMV_RPD_SAVEMODEL", usersession.getWebAppsContext()));
            stringbuffer.append("\")) ");
            stringbuffer.append("{window.location.replace(inpUrl) ; } } </script>");
        }
        catch(java.lang.Exception _ex) { }
        return stringbuffer.toString();
    }

    public static java.lang.String getTableNavButtons(oracle.apps.fnd.common.WebAppsContext webappscontext, com.sun.java.util.collections.ArrayList arraylist, javax.servlet.jsp.PageContext pagecontext, java.sql.Connection connection)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(1000);
        oracle.apps.bis.pmv.metadata.AKRegionItem aakregionitem[] = new oracle.apps.bis.pmv.metadata.AKRegionItem[arraylist.size()];
        for(int i = 0; i < arraylist.size(); i++)
            aakregionitem[i] = (oracle.apps.bis.pmv.metadata.AKRegionItem)arraylist.get(i);

        stringbuffer.append("<td>");
        for(int j = 0; j < arraylist.size(); j++)
        {
            stringbuffer.append(oracle.apps.bis.common.Util.getButtonHTML("javascript:self.actionButtonNav('" + aakregionitem[j].getUrl() + "')", aakregionitem[j].getAttributeNameLong(), aakregionitem[j].getAttributeNameLong(), aakregionitem[j].getAttributeNameLong(), webappscontext, pagecontext, pagecontext.getServletContext(), (javax.servlet.http.HttpServletRequest)pagecontext.getRequest(), connection));
            stringbuffer.append("&nbsp;");
        }

        stringbuffer.append("</td>");
        return stringbuffer.toString();
    }

    public static java.lang.String getCheckBoxSelectLinks(oracle.apps.fnd.common.WebAppsContext webappscontext, java.lang.String s)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer.append("<TR><td><table border=0 cellpadding=1 cellspacing=0 width=100% summary=\"\" ");
        stringbuffer.append("class=OraPmvTableTop");
        stringbuffer.append(" ><tbody>");
        stringbuffer.append("<tr valign=middle>");
        stringbuffer.append("<td >&nbsp;</td>");
        stringbuffer.append("<td >&nbsp;</td>");
        stringbuffer.append("<td >&nbsp;</td>");
        stringbuffer.append("<tr valign=middle>");
        stringbuffer.append("<td ><a class=\"OraGlobalButtonText\" href=\"javascript:selectAllCheckBox").append(s).append("()\" return true;\"  > ").append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_SELECT_ALL", webappscontext)).append("</a>&nbsp;|&nbsp;");
        stringbuffer.append("<a class=\"OraGlobalButtonText\" href=\"javascript:selectNoneCheckBox()\" return true;\" > ").append(od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_SELECT_NONE", webappscontext)).append("</a> </td>");
        stringbuffer.append("<td >&nbsp;</td>");
        stringbuffer.append("<td >&nbsp;</td>");
        stringbuffer.append("<td >&nbsp;</td>");
        stringbuffer.append("<td >&nbsp;</td>");
        stringbuffer.append("<td >&nbsp;</td>");
        stringbuffer.append("<td >&nbsp;</td>");
        stringbuffer.append("<td >&nbsp;</td>");
        stringbuffer.append("</tr></tbody></table></td></TR>");
        return stringbuffer.toString();
    }

    public static java.lang.String renderCheckBoxHeader(int i, int j)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer();
        stringbuffer.append("<td headers=\"SELECT\" rowspan=").append(java.lang.String.valueOf(j)).append(" class=\"OraPmvTableCellSelect OraPmvLovBrdr\" width=\"2%\">");
        stringbuffer.append("<LABEL id=\"").append("SelectCheckboxLabel").append("LABEL\" style=\"display:none\" for=\"");
        stringbuffer.append("SelectCheckbox").append("\">").append("SelectCheckbox").append("</LABEL>");
        stringbuffer.append("<input type=\"").append("checkbox");
        stringbuffer.append("\" id=\"").append("SelectCheckbox").append("\" name=\"").append("SelectCheckbox").append("\"");
        stringbuffer.append(" value=\"").append(i).append("\"></td>");
        return stringbuffer.toString();
    }

    public static java.lang.String renderSelectNavigationJS(java.lang.String s)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer();
        stringbuffer.append(" function selectAllCheckBox").append(s).append("() {");
        stringbuffer.append(" var cbCount = document.bisTableForm").append(s).append(".SelectCheckbox.length;");
        stringbuffer.append(" if (cbCount) ");
        stringbuffer.append(" { ");
        stringbuffer.append(" for(i=0; i < cbCount; i++){ ");
        stringbuffer.append(" document.bisTableForm").append(s).append(".SelectCheckbox[i].checked = true; ");
        stringbuffer.append("  } } else ");
        stringbuffer.append("  document.bisTableForm").append(s).append(".SelectCheckbox.checked = true; ");
        stringbuffer.append("  } ");
        stringbuffer.append(" function selectNoneCheckBox").append(s).append("() {");
        stringbuffer.append(" var cbCount = document.bisTableForm").append(s).append(".SelectCheckbox.length;");
        stringbuffer.append(" if (cbCount) ");
        stringbuffer.append(" { ");
        stringbuffer.append(" for(i=0; i < cbCount; i++){ ");
        stringbuffer.append(" document.bisTableForm").append(s).append(".SelectCheckbox[i].checked = false; ");
        stringbuffer.append("  } } else ");
        stringbuffer.append("  document.bisTableForm").append(s).append(".SelectCheckbox.checked = false; ");
        stringbuffer.append("  } ");
        stringbuffer.append(" function actionButtonNav").append(s).append("(url) {");
        stringbuffer.append("  var submitValue = \"selectNavigation\";");
        stringbuffer.append("  var url = url;");
        stringbuffer.append("  document.bisTableForm").append(s).append(".pSelectSubmit").append(s).append(".value = ").append("submitValue").append(";");
        stringbuffer.append("  document.bisTableForm").append(s).append(".pButtonUrl").append(s).append(".value = ").append("url").append(";");
        stringbuffer.append(" document.bisTableForm.submit(); ");
        stringbuffer.append(" } ");
        return stringbuffer.toString();
    }

    public static java.lang.String getPdfInfoTip(oracle.apps.bis.pmv.session.UserSession usersession, oracle.apps.bis.pmv.parameters.ParameterHelper parameterhelper)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        java.lang.String s = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getInfoTip(usersession, parameterhelper);
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s) && !"null".equals(s))
        {
            stringbuffer.append("<INFOTIP>");
            stringbuffer.append("\n");
            stringbuffer.append(s);
            stringbuffer.append("\n");
            stringbuffer.append("</INFOTIP>");
            stringbuffer.append("\n");
            return stringbuffer.toString();
        } else
        {
            return null;
        }
    }

    public static java.lang.String getBscPrototypeIcon(oracle.apps.fnd.common.WebAppsContext webappscontext, oracle.apps.fnd.framework.webui.OAPageContext oapagecontext)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        java.lang.String s = "";
        if(webappscontext != null)
            s = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getMessage("BIS_BSC_PROTOTYPE_DATA", webappscontext);
        else
        if(oapagecontext != null)
            s = oapagecontext.getMessage("BIS", "BIS_BSC_PROTOTYPE_DATA", null);
        java.lang.String s1 = od.oracle.apps.xxcrm.bis.pmv.common.ODPMVUtil.getFrameworkAgent(webappscontext);
        stringbuffer.append(" <img height=16 src=\"");
        if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s1))
            stringbuffer.append(s1);
        stringbuffer.append("/OA_MEDIA/tree_testobject.gif\" width=16 border=0 ");
        stringbuffer.append(" alt=\"").append(s).append("\"");
        stringbuffer.append(" title=\"").append(s).append("\"");
        stringbuffer.append(" onmouseover=\"javascript:window.status='").append(s).append("'\">");
        return stringbuffer.toString();
    }

    public static java.lang.String getFooterSpaceHTML(oracle.apps.bis.pmv.session.UserSession usersession, java.lang.String s, java.lang.String s1)
    {
        return "";
    }

    public static java.lang.String getDashboardFooter(oracle.apps.fnd.framework.webui.OAPageContext oapagecontext)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        java.lang.String s = "";
        if(oapagecontext.getCurrentLanguage() != null)
            s = oapagecontext.getCurrentLanguage();
        if("AR".equals(s) || "IW".equals(s))
            stringbuffer.append(" <TR><TD align=left noWrap>");
        else
            stringbuffer.append(" <TR><TD align=right noWrap>");
        java.lang.String s1 = oapagecontext.getMessage("BIS", "BIS_ACTIONS", null);
        java.lang.String s2 = oapagecontext.getMessage("BIS", "BIS_VIEWS", null);
        stringbuffer.append("<a id='ViewsDFooter' name='ViewsDFooter' class=\"PmvCrumbsEnabled\"");
        stringbuffer.append(" style=\"cursor:hand;text-decoration:none;\"");
        stringbuffer.append(" href=\"javascript:menuControlClick(event, 'VMenu0', 'ViewsDFooter', '');\"");
        stringbuffer.append(" onClick=\"menuControlClick(event, 'VMenu0', 'ViewsDFooter', '');return false;\"");
        stringbuffer.append(" onKeyDown=\"clkDown(event)\" onMouseDown=\"clkDown(event)\">");
        stringbuffer.append(s2);
        stringbuffer.append(" <img align=bottom src=/OA_MEDIA/bisdarr.gif ALT=\"").append(s2);
        stringbuffer.append(" \" TITLE=\"").append(s2).append(" \" border=0>");
        stringbuffer.append(" </a>&nbsp;&nbsp;");
        stringbuffer.append("<a id='ActionDFooter' name='ActionDFooter' class=\"PmvCrumbsEnabled\"");
        stringbuffer.append(" style=\"cursor:hand;text-decoration:none;\"");
        stringbuffer.append(" href=\"javascript:menuControlClick(event, 'VMenu1', 'ActionDFooter', '');\"");
        stringbuffer.append(" onClick=\"return menuControlClick(event, 'VMenu1', 'ActionDFooter', '');\"");
        stringbuffer.append(" onKeyDown=\"clkDown(event)\" onMouseDown=\"clkDown(event)\">");
        stringbuffer.append(s1);
        stringbuffer.append(" <img align=bottom src=/OA_MEDIA/bisdarr.gif ALT=\"").append(s1);
        stringbuffer.append("\" TITLE=\"").append(s1).append("\" border=0>");
        stringbuffer.append(" </a>&nbsp;");
        stringbuffer.append("</TD></TR> ");
        return stringbuffer.toString();
    }

    public static final java.lang.String RCS_ID = "$Header: HTMLUtil.java 115.268 2006/10/09 09:13:38 nkishore noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: HTMLUtil.java 115.268 2006/10/09 09:13:38 nkishore noship $", "oracle.apps.bis.pmv.common");

}
