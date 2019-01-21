/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.tds.webui;

import java.io.Serializable;

import java.util.HashMap;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;

import java.io.Serializable;

import oracle.apps.fnd.common.MessageToken;

import java.lang.Integer;

import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import java.util.ArrayList;
import java.util.Vector;

import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.cp.request.ConcurrentRequest;
import oracle.apps.fnd.cp.request.RequestSubmissionException;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageFileUploadBean;

import oracle.jbo.domain.BlobDomain;
import oracle.jbo.domain.Number;

/**
 * Controller for ...
 */
public class xxTDSAutoReprocessMainCO extends OAControllerImpl {
    public static final String RCS_ID = "$Header$";
    public static final boolean RCS_ID_RECORDED = 
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

    /**
     * Layout and page setup logic for a region.
     * @param pageContext the current OA page context
     * @param webBean the web bean corresponding to the region
     */
    public void processRequest(OAPageContext pageContext, OAWebBean webBean) {
        super.processRequest(pageContext, webBean);
        String chooseActionValue = "";
        OAApplicationModule am = pageContext.getApplicationModule(webBean);
        OATableBean tblNC = 
            (OATableBean)webBean.findIndexedChildRecursive("resultsTbl1");
        OATableBean tblNT = 
            (OATableBean)webBean.findIndexedChildRecursive("resultsTbl2");
        OASubmitButtonBean reprocessButton = 
            (OASubmitButtonBean)webBean.findIndexedChildRecursive("reprocessOrderBtn"); // Reprocess Button for NC
        OASubmitButtonBean reprocessOrderBtn2 = 
            (OASubmitButtonBean)webBean.findIndexedChildRecursive("reprocessOrderBtn2"); // Reprocess Button for NT
        OASubmitButtonBean reprocessAllButton = 
            (OASubmitButtonBean)webBean.findIndexedChildRecursive("reprocessAllBtn");

        //am.invokeMethod("executeVO");
        if (pageContext.getTransactionValue("ACVAL") != 
            null) { // Code for Action Type 
            if (pageContext.getTransactionValue("ACVAL").equals("NC")) { // No connect Button 
                tblNC.setRendered(true);
                tblNT.setRendered(false);
            }
            if (pageContext.getTransactionValue("ACVAL").equals("NT")) { // No connect Button 
                tblNC.setRendered(false);
                tblNT.setRendered(true);
            }
        }
        if (pageContext.getTransactionValue("RPVAL") != 
            null) { // Code for Reprocess Type
            if (pageContext.getTransactionValue("RPVAL").equals("RPONE")) { // Reprocess individually - Rendering logic
                System.out.println("reprocessButton PR =" + reprocessButton);
                //   pageContext.putTransactionValue("RPONE","RPONE");
                reprocessButton.setRendered(true);
                reprocessOrderBtn2.setRendered(true);
                reprocessAllButton.setRendered(false);
            }
            if (pageContext.getTransactionValue("RPVAL").equals("RPALL")) { // Reprocess All - Rendering logic
                System.out.println("reprocessButton PR=" + reprocessButton);
                //pageContext.putTransactionValue("RPONE","RPONE");
                reprocessButton.setRendered(false);
                reprocessOrderBtn2.setRendered(false);
                reprocessAllButton.setRendered(true);
            }
        }
    }

    /**
     * Procedure to handle form submissions for form elements in
     * a region.
     * @param pageContext the current OA page context
     * @param webBean the web bean corresponding to the region
     */
    public void processFormRequest(OAPageContext pageContext, 
                                   OAWebBean webBean) {
        super.processFormRequest(pageContext, webBean);
        String chooseActionValue = 
            ""; // Store the dropdown value for Action Type
        String chooseReprocessValue = 
            ""; // Store the dropdown value for Reprocess Type
        String chooseDateFrom = ""; // // Store the From Date

        OAApplicationModule am = pageContext.getApplicationModule(webBean);
        OADBTransaction oadbtransaction = am.getOADBTransaction();
        Connection conn = oadbtransaction.getJdbcConnection();
        ResultSet rsProg = null;
        Statement stmt = null;
        String progShortName = "";
        String programName = "";
        String applName = "";
        String strTableName = "";

        OAMessageChoiceBean chooseActionBean = 
            (OAMessageChoiceBean)webBean.findIndexedChildRecursive("chooseAction");
        OAMessageChoiceBean chooseReprocessBean = 
            (OAMessageChoiceBean)webBean.findIndexedChildRecursive("chooseReprocess");

        OAMessageTextInputBean chooseDateBean = 
            (OAMessageTextInputBean)webBean.findIndexedChildRecursive("chooseDateFrom");
        if (pageContext.getTransactionValue("RPVAL") != null) {
            pageContext.putTransactionValue("RPVAL", "");
        } // Clear the Transaction Values from pageContext
        if (pageContext.getTransactionValue("ACVAL") != null) {
            pageContext.putTransactionValue("ACVAL", "");
        } // Clear the Transaction Values from pageContext
        if (chooseActionBean != null) {
            chooseActionValue = (String)chooseActionBean.getValue(pageContext);
            System.out.println("chooseActionValue=" + chooseActionValue);
        }
        //Select value of Reprocess Action 
        if (chooseReprocessBean != null) {
            chooseReprocessValue = 
                    (String)chooseReprocessBean.getValue(pageContext);
            System.out.println("choosReprocessValue=" + chooseReprocessValue);
        }
        //Select  Value of the Date Entered
        if (chooseDateBean != null) {
            chooseDateFrom = (String)chooseDateBean.getValue(pageContext);
            System.out.println("chooseDateFrom=" + chooseDateFrom);
        }

        if (pageContext.getParameter("go") != null) {
            // Select Value of Action Type
            if (chooseReprocessValue.equals("RPALL")) {
                pageContext.putTransactionValue("RPVAL", "RPALL");
            }
            if (chooseReprocessValue.equals("RPONE")) {
                pageContext.putTransactionValue("RPVAL", "RPONE");
            }
            if (chooseActionValue.equals("NC")) {
                pageContext.putTransactionValue("ACVAL", "NC");
            }
            if (chooseActionValue.equals("NT")) {
                pageContext.putTransactionValue("ACVAL", "NT");
            }
            Serializable[] params = { chooseActionValue, chooseDateFrom };
            am.invokeMethod("invokeResults", params);
            pageContext.forwardImmediatelyToCurrentPage(null, true, null);
        } // End of Go Button Action

        if (pageContext.getParameter(EVENT_PARAM).equals("reprocessOrderNT")) {
            String incNum = (String)pageContext.getParameter("incNum");
            Serializable[] srParams = { chooseDateFrom, incNum };
            String status = 
                (String)am.invokeMethod("reprocessOneNT", srParams);
            System.out.println("status=" + status);
            //pageContext.forwardImmediatelyToCurrentPage(null, true, null);
        } //end reprocess ONE NC logic
        if (pageContext.getParameter(EVENT_PARAM).equals("reprocessOrderNC")) {
            String incNum = (String)pageContext.getParameter("incNum");
            String taskId = (String)pageContext.getParameter("taskId");
            String taskDesc = (String)pageContext.getParameter("taskDesc");
            String taskObjNum = (String)pageContext.getParameter("taskObjNum");
            Serializable[] taskParams = 
            { chooseDateFrom, incNum, taskId, taskDesc, taskObjNum };
            String status = 
                (String)am.invokeMethod("reprocessOneNC", taskParams);
            System.out.println("status=" + status);
            //pageContext.forwardImmediatelyToCurrentPage(null, true, null);
        } //end reprocess ONE NT logic
        //Start Action of Reprocess All
        if (pageContext.getParameter("reprocessAllBtn") != null) {
            try {
                applName = "xxcrm";
                progShortName = "XXTDSAUTOREPROCESS";
                programName = "OD:TDS Auto Reprocess Orders in EBS";
                ConcurrentRequest cr = new ConcurrentRequest(conn);
                // call submit request
                Vector param = new Vector();
                param.addElement(chooseActionValue);
                param.addElement(chooseDateFrom);
                int reqId = 
                    cr.submitRequest(applName, progShortName, null, null, 
                                     false, param);
                conn.commit();
                System.out.println("reqId=" + reqId);

                MessageToken[] tokens = 
                { new MessageToken("PROGRAMNAME", programName), 
                  new MessageToken("REQID", 
                                   reqId + "") }; //, new MessageToken("FILENAME",(String)pageContext.getTransactionValue("strExcelUploadFileName"))};
                throw new OAException("XXFIN", "XXOD_EXCEL_UPLD_PRG_DET", 
                                      tokens, OAException.INFORMATION, null);
            } catch (RequestSubmissionException exp) {
                System.out.println("Request Submission Exception:" + exp);
            } catch (SQLException sexp) {
                System.out.println("SQL Exception:" + sexp);
            }
        } //end reprocess ALL logic

    } //End PFR
}
