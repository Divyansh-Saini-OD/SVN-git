// Decompiled by Jad v1.5.8g. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: packimports(3) 
// Source File Name:   CommentsDetailsCO.java

package oracle.apps.ar.irec.accountDetails.cmreq.webui;

import oracle.apps.ar.irec.framework.webui.IROAControllerImpl;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.*;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.*;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;
import oracle.cabo.ui.beans.BaseWebBean;
import oracle.cabo.ui.beans.StyledTextBean;
import oracle.cabo.ui.beans.layout.SpacerBean;
import oracle.cabo.ui.beans.layout.TableLayoutBean;
import oracle.jbo.*;

public class CommentsDetailsCO extends IROAControllerImpl
{

    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processRequest(oapagecontext, oawebbean);
        String s = oapagecontext.getParameter("cmRequestId");
        String s1 = getApproverComments(oapagecontext, oawebbean, s);
        OATableLayoutBean oatablelayoutbean = (OATableLayoutBean)createWebBean(oapagecontext, "TABLE_LAYOUT", null, null);
        oawebbean.addIndexedChild(oatablelayoutbean);
        OASpacerBean oaspacerbean = (OASpacerBean)createWebBean(oapagecontext, "SPACER", null, null);
        oaspacerbean.setWidth(1);
        oaspacerbean.setHeight(5);
        for(int i = 0; i < 4; i++)
        {
            OARowLayoutBean oarowlayoutbean = (OARowLayoutBean)createWebBean(oapagecontext, "ROW_LAYOUT", null, null);
            oatablelayoutbean.addRowLayout(oarowlayoutbean);
            OACellFormatBean oacellformatbean = (OACellFormatBean)createWebBean(oapagecontext, "CELL_FORMAT", null, null);
            oarowlayoutbean.addIndexedChild(oacellformatbean);
            oacellformatbean.addIndexedChild(oaspacerbean);
            OAMessageStyledTextBean oamessagestyledtextbean = (OAMessageStyledTextBean)createWebBean(oapagecontext, oawebbean, "Item" + i);
            if(i == 0)
            {
                oamessagestyledtextbean.setStyleClass("OraFieldText");
                oamessagestyledtextbean.setText("Requestor Comments");
            } else
            if(i == 2)
            {
                oamessagestyledtextbean.setStyleClass("OraFieldText");
                oamessagestyledtextbean.setText("Approver Comments");
            } else
            {
                oamessagestyledtextbean.setStyleClass("OraDataText");
            }
            if(i == 3)
                oamessagestyledtextbean.setText(s1);
            addOAMessageStyledTextBean(oatablelayoutbean, oamessagestyledtextbean);
        }

    }

    private String getApproverComments(OAPageContext oapagecontext, OAWebBean oawebbean, String s)
    {
        if(oapagecontext.isLoggingEnabled(2))
            oapagecontext.writeDiagnostics(this, "start getApproverComments", 2);
        oracle.apps.fnd.framework.OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
        String s1 = "";
        String s2 = null;
        Object obj = null;
        Object obj1 = null;
        if(oapagecontext.isLoggingEnabled(1))
            oapagecontext.writeDiagnostics(this, "In getApproverComments Request Id :: " + s, 1);
        if(!"".equalsIgnoreCase(s) || s != null)
            s2 = " SELECT  TEXT_VALUE FROM WF_NOTIFICATION_ATTRIBUTES" + " WHERE NAME  = 'APPROVER_NOTES' and NOTIFICATION_ID IN" + " (select notification_id from wf_item_activity_statuses" + (" where (item_type = 'ARCMREQ' OR item_type = 'ARAMECM') and item_key = '" + s + "'") + " and ( ACTIVITY_RESULT_CODE='REJECTED' OR ACTIVITY_RESULT_CODE ='APPROVED' OR ACTIVITY_RESULT_CODE ='RESOLVED')" + " union" + " select notification_id from wf_item_activity_statuses_h" + (" where (item_type = 'ARCMREQ' OR item_type = 'ARAMECM') and item_key = '" + s + "'") + " and  ( ACTIVITY_RESULT_CODE='REJECTED' OR ACTIVITY_RESULT_CODE ='APPROVED' OR ACTIVITY_RESULT_CODE ='RESOLVED')" + " ) order by notification_id desc";
        if(oapagecontext.isLoggingEnabled(1))
            oapagecontext.writeDiagnostics(this, "Query Statement :: " + s2, 1);
        if(s2 != null)
        {
            oracle.jbo.ViewObject viewobject = oaapplicationmodule.createViewObjectFromQueryStmt(null, s2);
            viewobject.executeQuery();
            if(viewobject.hasNext())
            {
                oracle.jbo.Row row = viewobject.next();
                if(row.getAttribute(0) != null)
                    s1 = row.getAttribute(0).toString();
            }
            viewobject.remove();
        }
        if(oapagecontext.isLoggingEnabled(1))
            oapagecontext.writeDiagnostics(this, "Approver Comment :: " + s1, 1);
        if(oapagecontext.isLoggingEnabled(2))
            oapagecontext.writeDiagnostics(this, "end getApproverComments", 2);
        return s1;
    }

    public CommentsDetailsCO()
    {
    }

    public static final String RCS_ID = "$Header: CommentsDetailsCO.java 115.0 2008/07/09 09:11:38 avepati noship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: CommentsDetailsCO.java 115.0 2008/07/09 09:11:38 avepati noship $", "oracle.apps.ar.irec.accountDetails.cmreq.webui");

}
