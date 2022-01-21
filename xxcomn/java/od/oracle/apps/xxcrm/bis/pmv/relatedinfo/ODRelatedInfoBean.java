// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames 
// Source File Name:   RelatedInfoBean.java

package od.oracle.apps.xxcrm.bis.pmv.relatedinfo;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.util.Vector;
import javax.servlet.ServletContext;
import oracle.apps.bis.common.Util;
import oracle.apps.bis.common.VersionConstants;
import oracle.apps.bis.msg.MessageLog;
import oracle.apps.bis.pmv.common.HTMLUtil;
import oracle.apps.bis.pmv.common.PMVConstants;
import oracle.apps.bis.pmv.common.PMVUtil;
import oracle.apps.bis.pmv.common.StringUtil;
import oracle.apps.bis.pmv.metadata.AKRegion;
import oracle.apps.bis.pmv.session.RequestInfo;
import oracle.apps.bis.pmv.session.UserSession;
import oracle.apps.fnd.common.AppsContext;
import oracle.apps.fnd.common.Context;
import oracle.apps.fnd.common.ProfileStore;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.common.WebAppsContext;
import oracle.cabo.share.url.EncoderUtils;
import oracle.apps.bis.pmv.relatedinfo.*;

// Referenced classes of package od.oracle.apps.xxcrm.bis.pmv.relatedinfo:
//            RelatedInfo, RelatedInfoHelper

public class ODRelatedInfoBean
{

    public ODRelatedInfoBean(oracle.apps.bis.pmv.session.UserSession usersession)
    {
        m_LogLevel = 0x7fffffff;
        m_IsPrintable = false;
        m_WebAppsContext = usersession.getWebAppsContext();
        m_Application = usersession.getApplication();
        m_ImageServer = usersession.getImageServer();
        if(usersession.getRequestInfo() != null)
            m_IsPrintable = usersession.getRequestInfo().isPrintable();
        m_RinfoHelper = new RelatedInfoHelper(usersession);
        m_UserSession = usersession;
        try
        {
            if(m_UserSession.getPmvMsgLog() != null)
            {
                m_PmvMsgLog = m_UserSession.getPmvMsgLog();
                m_LogLevel = m_PmvMsgLog.getLevel();
                if(m_LogLevel == 5)
                {
                    m_PmvMsgLog.newProgress("Related Links Rendering");
                    return;
                }
            }
        }
        catch(java.lang.Exception _ex) { }
    }

    public java.lang.String getRinfoHTML(java.lang.String s)
        throws java.io.IOException
    {
        m_BackUrl = s;
        try
        {
            if(m_PmvMsgLog != null && m_LogLevel == 5)
                m_PmvMsgLog.closeProgress("Related Links Rendering");
        }
        catch(java.lang.Exception _ex) { }
        return getRinfoHTML();
    }

    public java.lang.String getRinfoHTML()
        throws java.io.IOException
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(100);
        stringbuffer = getHeader();
        stringbuffer.append("<TABLE valign=top border=0 cellspacing=0 cellpadding=0 width=96% summary=\"\" >");
        stringbuffer.append("<TR VALIGN=top>");
        stringbuffer.append(getReportURLs().toString());
        stringbuffer.append(getUserURLs().toString());
        stringbuffer.append("</TR></TABLE>");
        try
        {
            if(m_PmvMsgLog != null && m_LogLevel == 5)
                m_PmvMsgLog.closeProgress("Related Links Rendering");
        }
        catch(java.lang.Exception _ex) { }
        return stringbuffer.toString();
    }

    private java.lang.StringBuffer getHeader()
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(300);
        java.lang.StringBuffer stringbuffer1 = new StringBuffer(300);
        java.lang.String s = oracle.apps.bis.pmv.common.PMVUtil.getMessage("BIS_CUSTOMIZE_RINFO", m_WebAppsContext);
        java.lang.String s1 = oracle.apps.bis.pmv.common.PMVUtil.getMessage("BIS_RELATED_INFO", m_WebAppsContext);
        java.lang.String s2 = oracle.apps.bis.pmv.common.PMVUtil.getMessage("BIS_CUSTOMIZE", m_WebAppsContext);
        java.lang.String s3 = "";
        java.lang.String s4 = m_WebAppsContext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
        stringbuffer1.append(oracle.apps.bis.pmv.common.PMVUtil.getJspAgent(m_WebAppsContext));
        stringbuffer1.append("OA.jsp?akRegionCode=BISPMVRLLISTPAGE");
        stringbuffer1.append("&akRegionApplicationId=191");
        try
        {
            stringbuffer1.append("&dbc=").append(m_UserSession.getRequestInfo().getDBC());
            stringbuffer1.append("&sessionid=").append(m_UserSession.getSessionId());
            stringbuffer1.append("&language=").append(m_WebAppsContext.getCurrLangCode());
            stringbuffer1.append("&custRegionCode=").append(oracle.cabo.share.url.EncoderUtils.encodeString(m_RinfoHelper.getRegionCode(), s4));
            stringbuffer1.append("&custFunctionName=").append(oracle.cabo.share.url.EncoderUtils.encodeString(m_RinfoHelper.getFunctionName(), s4));
            stringbuffer1.append("&custRegionApplId=").append(m_UserSession.getAKRegion().getRegionApplicationId());
            stringbuffer1.append("&fromRelated=Y");
            stringbuffer1.append("&backUrl=").append(oracle.cabo.share.url.EncoderUtils.encodeString(m_BackUrl, s4));
            try
            {
                if(m_PmvMsgLog != null && m_LogLevel == 5)
                    m_PmvMsgLog.logMessage("Related Links Rendering", "RelatedInfoBean::getHeader - custLink: " + stringbuffer1.toString(), m_LogLevel);
            }
            catch(java.lang.Exception _ex) { }
        }
        catch(java.io.UnsupportedEncodingException unsupportedencodingexception)
        {
            try
            {
                if(m_PmvMsgLog != null && m_LogLevel == 5)
                    m_PmvMsgLog.logMessage("Related Links Rendering", "RelatedInfoBean::getHeader - Exception while encoding related links header - " + unsupportedencodingexception.toString(), m_LogLevel);
            }
            catch(java.lang.Exception _ex) { }
        }
        try
        {
            s3 = oracle.apps.bis.pmv.common.PMVUtil.getOAMacUrl(stringbuffer1.toString(), m_WebAppsContext);
        }
        catch(java.lang.Exception _ex) { }
        if(oracle.apps.bis.pmv.common.StringUtil.emptyString(s3))
            s3 = stringbuffer1.toString();
        stringbuffer.append(oracle.apps.bis.pmv.common.HTMLUtil.getSectionHeader(s1, "OraHeaderSub", m_ImageServer, null));
        if(!m_IsPrintable)
        {
            stringbuffer.append("<TABLE ALIGN=center border=0 cellpadding=0 cellspacing=0 width=93% summary=\"\" >");
            stringbuffer.append("<TR VALIGN=top><TD align=right>");
            stringbuffer.append(oracle.apps.bis.pmv.common.HTMLUtil.getButtonHTML(s3, s, s, s2, m_WebAppsContext, m_Application, m_UserSession));
            stringbuffer.append("</TD></TR></TABLE>");
        }
        return stringbuffer;
    }

    private java.lang.StringBuffer getRelLinksHeader()
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(300);
        java.lang.String s = oracle.apps.bis.common.Util.escapeGTLTHTML(oracle.apps.bis.pmv.common.PMVUtil.getMessage("BIS_RELATED_LINKS", m_WebAppsContext), "");
        stringbuffer.append(oracle.apps.bis.pmv.common.HTMLUtil.getSectionHeader(s, "OraHeaderSub", m_ImageServer, null));
        return stringbuffer;
    }

    private java.lang.StringBuffer getReportURLs()
    {
        java.util.Vector vector = m_RinfoHelper.getReportURLs();
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        if(!vector.isEmpty())
        {
            java.lang.String s = oracle.apps.bis.pmv.common.PMVUtil.getMessage("USER_REPORTS", m_WebAppsContext);
            stringbuffer.append("<TD width=50%><TABLE valign=top cellspacing=0, cellpadding=1 summary=\"\" >");
            stringbuffer.append("<TR><TD class=OraInstructionText><B>");
            stringbuffer.append(s);
            stringbuffer.append("</B></TD></TR>");
            java.lang.String s3 = "";
            if(oracle.apps.bis.pmv.relatedinfo.RelatedInfoBean.isSWAN())
                s3 = "class=OraLinkText";
            for(int i = 0; i < vector.size(); i++)
            {
                oracle.apps.bis.pmv.relatedinfo.RelatedInfo relatedinfo = (oracle.apps.bis.pmv.relatedinfo.RelatedInfo)vector.elementAt(i);
                java.lang.String s1 = relatedinfo.getLinkURL();
                java.lang.String s2 = relatedinfo.getLinkName();
                stringbuffer.append("<TR class=OraInstructionText><TD nowrap>");
                if(!m_IsPrintable)
                {
                    stringbuffer.append("<A ").append(s3).append(" HREF=\"");
                    stringbuffer.append(s1);
                    stringbuffer.append("\">");
                }
                stringbuffer.append(s2);
                if(!m_IsPrintable)
                    stringbuffer.append("</A>");
                stringbuffer.append("</TD></TR>");
            }

            stringbuffer.append("</TABLE></TD>");
        }
        return stringbuffer;
    }

    private java.lang.StringBuffer getUserURLs()
    {
        java.util.Vector vector = m_RinfoHelper.getUserURLs();
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        if(!vector.isEmpty())
        {
            java.lang.String s = oracle.apps.bis.pmv.common.PMVUtil.getMessage("USER_URLS", m_WebAppsContext);
            stringbuffer.append("<TD><TABLE valign=top cellspacing=0, cellpadding=1 summary=\"\" >");
            stringbuffer.append("<TR><TD class=OraHeaderSubSub><B>");
            stringbuffer.append(s);
            stringbuffer.append("</TD></TR>");
            java.lang.String s3 = "";
            if(oracle.apps.bis.pmv.relatedinfo.RelatedInfoBean.isSWAN())
                s3 = "class=OraLinkText";
            for(int i = 0; i < vector.size(); i++)
            {
                oracle.apps.bis.pmv.relatedinfo.RelatedInfo relatedinfo = (oracle.apps.bis.pmv.relatedinfo.RelatedInfo)vector.elementAt(i);
                java.lang.String s1 = relatedinfo.getLinkURL();
                java.lang.String s2 = relatedinfo.getLinkName();
                stringbuffer.append("<TR class=OraInstructionText><TD nowrap>");
                if(!m_IsPrintable)
                {
                    stringbuffer.append("<A ").append(s3).append(" HREF=\"");
                    stringbuffer.append(s1);
                    stringbuffer.append("\">");
                }
                stringbuffer.append(s2);
                if(!m_IsPrintable)
                    stringbuffer.append("</A>");
                stringbuffer.append("</TD></TR>");
            }

            stringbuffer.append("</TABLE></TD>");
        }
        return stringbuffer;
    }

    public java.lang.String getRelatedLinksHTML()
        throws java.io.IOException
    {
        if(m_RinfoHelper.hasLinks())
        {
            java.lang.StringBuffer stringbuffer = new StringBuffer(1000);
            stringbuffer = getRelLinksHeader();
            stringbuffer.append(getRelatedLinksComponentHTML());
            try
            {
                if(m_PmvMsgLog != null && m_LogLevel == 5)
                    m_PmvMsgLog.closeProgress("Related Links Rendering");
            }
            catch(java.lang.Exception _ex) { }
            return stringbuffer.toString();
        } else
        {
            return "";
        }
    }

    private java.lang.StringBuffer getRelatedLinksHeader()
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(300);
        java.lang.StringBuffer stringbuffer1 = new StringBuffer(300);
        oracle.apps.bis.pmv.common.PMVUtil.getMessage("BIS_CUSTOMIZE_RINFO", m_WebAppsContext);
        java.lang.String s = oracle.apps.bis.common.Util.escapeGTLTHTML(oracle.apps.bis.pmv.common.PMVUtil.getMessage("BIS_RELATED_LINKS", m_WebAppsContext), "");
        oracle.apps.bis.pmv.common.PMVUtil.getMessage("BIS_CUSTOMIZE", m_WebAppsContext);
        stringbuffer1.append(m_RinfoHelper.getPlsqlAgent());
        stringbuffer1.append("BIS_RL_PKG.Customize_related_links?U=").append(m_RinfoHelper.getUserId());
        stringbuffer1.append("&R=").append(m_RinfoHelper.getRespId());
        stringbuffer1.append("&F=").append(m_RinfoHelper.getFunctionId());
        stringbuffer1.append("&pFunctionName=").append(m_RinfoHelper.getFunctionName());
        stringbuffer1.append("&pRegionCode=").append(m_RinfoHelper.getRegionCode());
        stringbuffer1.append("&pSessionId=").append(m_RinfoHelper.getSessionId()).append("&pMode=showReport");
        stringbuffer.append("<TABLE ALIGN=center border=0 cellpadding=0 cellspacing=0 width=100% summary=\"\" >");
        stringbuffer.append("<TR VALIGN=top>");
        stringbuffer.append("<TD class=OraHeaderSubSub>");
        stringbuffer.append(s);
        stringbuffer.append("</TD>");
        stringbuffer.append("</TR></TABLE>");
        return stringbuffer;
    }

    private java.lang.StringBuffer getRelatedLinksReportURLs(java.util.Vector vector)
    {
        java.util.Vector vector1 = m_RinfoHelper.getReportURLs();
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        if(!vector1.isEmpty())
        {
            for(int i = 0; i < vector1.size(); i++)
            {
                oracle.apps.bis.pmv.relatedinfo.RelatedInfo relatedinfo = (oracle.apps.bis.pmv.relatedinfo.RelatedInfo)vector1.elementAt(i);
                java.lang.String s = relatedinfo.getLinkURL();
                java.lang.String s1 = relatedinfo.getLinkName();
                stringbuffer.append("<LI class=PmvDbiListNoBullets>");
                stringbuffer.append("<A HREF=\"");
                stringbuffer.append(s);
                stringbuffer.append("\">");
                stringbuffer.append(s1);
                stringbuffer.append("</A>");
            }

        }
        return stringbuffer;
    }

    private java.lang.StringBuffer getRelatedLinksUserURLs(java.util.Vector vector)
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        if(!vector.isEmpty())
        {
            for(int i = 0; i < vector.size(); i++)
            {
                oracle.apps.bis.pmv.relatedinfo.RelatedInfo relatedinfo = (oracle.apps.bis.pmv.relatedinfo.RelatedInfo)vector.elementAt(i);
                java.lang.String s = relatedinfo.getLinkURL();
                java.lang.String s1 = relatedinfo.getLinkName();
                stringbuffer.append("<LI class=PmvDbiListNoBullets>");
                stringbuffer.append("<A HREF=\"");
                stringbuffer.append(s);
                stringbuffer.append("\">");
                stringbuffer.append(s1);
                stringbuffer.append("</A>");
            }

        }
        return stringbuffer;
    }

    private java.lang.StringBuffer getRelatedLinksURLs()
    {
        java.util.Vector vector = m_RinfoHelper.getLinks();
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        if(!vector.isEmpty())
        {
            java.lang.String s3 = "";
            if(oracle.apps.bis.pmv.relatedinfo.RelatedInfoBean.isSWAN())
                s3 = "class=OraLinkText";
            for(int i = 0; i < vector.size(); i++)
            {
                oracle.apps.bis.pmv.relatedinfo.RelatedInfo relatedinfo = (oracle.apps.bis.pmv.relatedinfo.RelatedInfo)vector.elementAt(i);
                java.lang.String s = relatedinfo.getLinkURL();
                java.lang.String s1 = relatedinfo.getLinkName();
                java.lang.String s2 = relatedinfo.getOutputFormat();
                stringbuffer.append("<TR VALIGN=top  style=\"border: #808080 solid 1;\" class=OraInstructionText>");
                stringbuffer.append("<TD>");
                if(oracle.apps.bis.pmv.relatedinfo.RelatedInfoBean.isSWAN())
                    stringbuffer.append("&nbsp;&nbsp;");
                if(m_UserSession.getRequestInfo().isPrintable())
                {
                    stringbuffer.append(oracle.apps.bis.common.Util.escapeGTLTHTML(s1, ""));
                    if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s2))
                        stringbuffer.append(" (").append(oracle.apps.bis.pmv.common.PMVUtil.getMessage("BISPMVEXPORTTOEXCEL", m_WebAppsContext)).append(")");
                    stringbuffer.append("</TD></TR>");
                } else
                {
                    stringbuffer.append("<A ").append(s3).append(" HREF=\"");
                    stringbuffer.append(s);
                    stringbuffer.append("\" target=\"_blank>\"");
                    stringbuffer.append(oracle.apps.bis.common.Util.escapeGTLTHTML(s1, ""));
                    if(!oracle.apps.bis.pmv.common.StringUtil.emptyString(s2))
                        stringbuffer.append(" (").append(oracle.apps.bis.common.Util.escapeGTLTHTML(oracle.apps.bis.pmv.common.PMVUtil.getMessage("BISPMVEXPORTTOEXCEL", m_WebAppsContext), "")).append(") <img src=\"/OA_MEDIA/bisexcel.gif\" border=\"0\" alt=\"Excel\">");
                    stringbuffer.append("</A>");
                    stringbuffer.append("</TD></TR>");
                }
            }

        } else
        {
            stringbuffer = null;
        }
        return stringbuffer;
    }

    public java.lang.StringBuffer getPdfRelatedLinksNames()
    {
        java.util.Vector vector = m_RinfoHelper.getLinks();
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        if(!vector.isEmpty())
        {
            for(int i = 0; i < vector.size(); i++)
            {
                oracle.apps.bis.pmv.relatedinfo.RelatedInfo relatedinfo = (oracle.apps.bis.pmv.relatedinfo.RelatedInfo)vector.elementAt(i);
                java.lang.String s = relatedinfo.getLinkName();
                stringbuffer.append("<link no=\"");
                stringbuffer.append(i + 1);
                stringbuffer.append("\" >");
                stringbuffer.append("\n");
                stringbuffer.append("<name>");
                stringbuffer.append("<![CDATA[");
                stringbuffer.append(s);
                stringbuffer.append("]]>");
                stringbuffer.append("</name>");
                stringbuffer.append("\n");
                stringbuffer.append("</link>");
                stringbuffer.append("\n");
            }

        } else
        {
            stringbuffer = null;
        }
        try
        {
            if(m_PmvMsgLog != null && m_LogLevel == 5)
                m_PmvMsgLog.closeProgress("Related Links Rendering");
        }
        catch(java.lang.Exception _ex) { }
        return stringbuffer;
    }

    public java.lang.StringBuffer getPdfRelatedLinksNamesForRTF()
    {
        java.util.Vector vector = m_RinfoHelper.getLinks();
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        if(!vector.isEmpty())
        {
            for(int i = 0; i < vector.size(); i++)
            {
                oracle.apps.bis.pmv.relatedinfo.RelatedInfo relatedinfo = (oracle.apps.bis.pmv.relatedinfo.RelatedInfo)vector.elementAt(i);
                java.lang.String s = relatedinfo.getLinkName();
                stringbuffer.append("<LINK>");
                stringbuffer.append("<![CDATA[");
                stringbuffer.append(s);
                stringbuffer.append("]]>");
                stringbuffer.append("</LINK>");
                stringbuffer.append("\n");
            }

        } else
        {
            stringbuffer = null;
        }
        try
        {
            if(m_PmvMsgLog != null && m_LogLevel == 5)
                m_PmvMsgLog.closeProgress("Related Links Rendering");
        }
        catch(java.lang.Exception _ex) { }
        return stringbuffer;
    }

    private java.lang.String getInformationMessage()
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(500);
        stringbuffer.append("<td style=\"border: #808080 solid 1;\" class=OraInstructionText>");
        stringbuffer.append(oracle.apps.bis.common.Util.getMessageWithIcon("BIS_INFORMATION", "BIS_RINFO_TEXT", m_WebAppsContext, m_UserSession.getConnection()));
        stringbuffer.append("</td>");
        return stringbuffer.toString();
    }

    public java.lang.String getRelatedLinksComponentHTML()
        throws java.io.IOException
    {
        java.lang.StringBuffer stringbuffer = new StringBuffer(1000);
        java.lang.String s = "";
        if(oracle.apps.bis.pmv.relatedinfo.RelatedInfoBean.isSWAN())
            s = "bgcolor=\"#eaeff5\"";
        stringbuffer.append("<TABLE valign=top border=0 cellspacing=0 cellpadding=0 width=100% summary=\"\" ").append(s).append(" >");
        if(getRelatedLinksURLs() != null)
            stringbuffer.append(getRelatedLinksURLs().toString());
        stringbuffer.append("</TABLE>");
        try
        {
            if(m_PmvMsgLog != null && m_LogLevel == 5)
                m_PmvMsgLog.closeProgress("Related Links Rendering");
        }
        catch(java.lang.Exception _ex) { }
        return stringbuffer.toString();
    }

    public static boolean isSWAN()
    {
        return "SWAN".equals("409");
    }

    public static final java.lang.String RCS_ID = "$Header: RelatedInfoBean.java 115.44 2007/06/22 08:04:42 asverma noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: RelatedInfoBean.java 115.44 2007/06/22 08:04:42 asverma noship $", "oracle.apps.bis.pmv.relatedinfo");
    private oracle.apps.fnd.common.WebAppsContext m_WebAppsContext;
    private oracle.apps.bis.pmv.relatedinfo.RelatedInfoHelper m_RinfoHelper;
    private javax.servlet.ServletContext m_Application;
    private oracle.apps.bis.pmv.session.UserSession m_UserSession;
    private java.lang.String m_ImageServer;
    private java.lang.String m_BackUrl;
    private oracle.apps.bis.msg.MessageLog m_PmvMsgLog;
    private int m_LogLevel;
    private boolean m_IsPrintable;

}
