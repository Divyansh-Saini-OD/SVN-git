/*===========================================================================+
  |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
  |                         All rights reserved.                              |
  +===========================================================================+
  |  HISTORY 
  |  Prasad-Devar 
  +===========================================================================*/
package od.oracle.apps.xxcrm.scs.fdk.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import com.sun.java.util.collections.HashMap;

import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;

import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.OAFwkConstants;

/**
 * Controller for ...
 */
public class ODSCSRouteCO extends OAControllerImpl {
    public static final String RCS_ID = "$Header$";
    public static final boolean RCS_ID_RECORDED = 
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

    /**
     * Layout and page setup logic for a region.
     * @param pageContext the current OA page context
     * @param webBean the web bean corresponding to the region
     */
    public void processRequest(OAPageContext pageContext, OAWebBean webBean) {
        final String METHOD_NAME = 
            "od.oracle.apps.xxcrm.scs.fdk.webui.ODSCSRouteCO.processRequest";
        boolean isProcLogEnabled = 
            pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
        boolean isStatLogEnabled = 
            pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);
        if (isProcLogEnabled) {
            pageContext.writeDiagnostics(METHOD_NAME, "Begin", 
                                         OAFwkConstants.PROCEDURE);
        }

        super.processRequest(pageContext, webBean);

        HashMap parameters = new HashMap();

        CallableStatement stmt = null;

        OAException confirmMessage1 = null;
        new OAException(" Error_message", OAException.ERROR);
        String entityType = "";
        int entityId = 0;
        String usage_exists = "";
        String Error_message = "";

        try {
            OADBTransaction trx = 
                pageContext.getRootApplicationModule().getOADBTransaction();
            stmt = 
trx.createCallableStatement("Begin " + "XXSCS_CONT_STRATEGY_PKG.P_Route_Lead_Opp( " + 
                            "                           :1, " + 
                            "                           :2, " + 
                            "                           :3, " + 
                            "                           :4, " + 
                            "                           :5, " + 
                            "                           :6, " + 
                            "                           :7 " + 
                            "                            ); " + " commit; " + 
                            " end;", 1);
            // parameters.put("ASNReqFrmLeadId", pageContext.getParameter("FrmLeadId").toString());  
            System.out.println(pageContext.getParameter("FrmPtnId") + 
                               "  FrmPtnId " + 
                               pageContext.getParameter("FrmStId") + "   " + 
                               pageContext.getParameter("FrmPtnTyp"));
            stmt.setInt(1, 
                        Integer.parseInt(pageContext.getParameter("FrmPtnId") + 
                                         ""));
            stmt.setInt(2, 
                        Integer.parseInt(pageContext.getParameter("FrmStId") + 
                                         ""));
            stmt.setString(3, pageContext.getParameter("FrmPtnTyp"));
            stmt.registerOutParameter(4, Types.VARCHAR);
            stmt.registerOutParameter(5, Types.INTEGER);
            stmt.registerOutParameter(6, Types.VARCHAR);
            stmt.registerOutParameter(7, Types.VARCHAR);
            stmt.execute();

            entityType = stmt.getString(4);
            entityId = stmt.getInt(5);
            usage_exists = stmt.getString(6);
            Error_message = stmt.getString(7);
            confirmMessage1 = null;
            new OAException(Error_message, OAException.CONFIRMATION);


        } catch (SQLException sqlexception) {
            sqlexception.printStackTrace();
            OAException confirmMessage = 
                new OAException(sqlexception.toString(), OAException.ERROR);
            pageContext.putDialogMessage(confirmMessage);
        }
        if (!"S".equals(usage_exists))

        {
            OAException confirmMessage = 
                new OAException(Error_message, OAException.ERROR);
            pageContext.putDialogMessage(confirmMessage);

        } else {
            //parameters.put("akRegionCode", "FNDCPREQUESTVIEWREGION");
            //String id = """2167951""";
            //parameters.put("requestID",id);
            //http://chileba06d.na.odcorp.net:8020/OA_HTML/OA.jsp?page=/od/oracle/apps/xxcrm/cs/custom/webui/ODCsCrteOptntyCrtPG&ASNReqFrmOpptyId=8283

            String reDirctPg = pageContext.getParameter("FrmPtnVw");

            if (reDirctPg == null) {
                reDirctPg = "";
            }
            String URL = "";

            if (reDirctPg.equals("FEEDBACK")) {
                URL = 
"OA.jsp?page=/od/oracle/apps/xxcrm/scs/fdk/webui/ODSCSFdkFmPG";
                parameters.put("SCSReqFrmEntityId", entityId + "");
                parameters.put("SCSReqFrmEntitytype", entityType);

            } else if (reDirctPg.equals("LEAD")) {
                if (entityType.equals("OPPORTUNITY")) {

                    URL = 
"OA.jsp?page=/oracle/apps/asn/opportunity/webui/OpptyDetPG";
                    //    URL="OA.jsp?page=/oracle/apps/asn/opportunity/webui/OpptyDetPG";
                    parameters.put("ASNReqFrmOpptyId", entityId + "");
                    parameters.put("SCSReqFrmSrc", "CS_R");


                } else {
                    URL = "OA.jsp?page=/oracle/apps/asn/lead/webui/LeadDetPG";
                    //     URL="OA.jsp?page=/od/oracle/apps/xxcrm/asn/lead/webui/ODLeadDetPG";
                    parameters.put("ASNReqFrmLeadId", entityId + "");
                    parameters.put("SCSReqFrmSrc", "CS_R");
                }
            }
            System.out.println(URL); // retain AM
                pageContext.forwardImmediately(URL, null, 
                                               OAWebBeanConstants.KEEP_MENU_CONTEXT, 
                                               null, parameters, true, 
                                               OAWebBeanConstants.ADD_BREAD_CRUMB_YES);
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
    }

}
