/*===========================================================================+
  |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
  |                         All rights reserved.                              |
  +===========================================================================+
  |  HISTORY                                                                  |
  +===========================================================================*/
package od.oracle.apps.xxcrm.scs.fdk.webui;

import com.sun.java.util.collections.HashMap;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import java.io.Serializable;

import oracle.jbo.Row;


/**
 * Controller for ...
 */
public class ODSCSFdkQACO extends OAControllerImpl {
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
        OAApplicationModule am = 
            (OAApplicationModule)pageContext.getApplicationModule(webBean);
        //     String event = pageContext.getParameter("event");
        OAViewObject mstrVO = 
            (OAViewObject)am.findViewObject("ODSCSFdbkQstnMstrVO");
        OAViewObject dtlVO = 
            (OAViewObject)am.findViewObject("ODSCSFdbkRespDtlVO");
        // mstrVO.setWhereClause(null);
        mstrVO.executeQuery();
        //  dtlVO.setWhereClause(null);
        dtlVO.executeQuery();


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
        OAApplicationModule am = 
            (OAApplicationModule)pageContext.getApplicationModule(webBean);

        String event = pageContext.getParameter("event");


        OAViewObject vo = 
            (OAViewObject)am.findViewObject("ODSCSFdbkQstnMstrVO");


        if (pageContext.getParameter("Create") != null) {

            String URL = 
                "OA.jsp?page=/od/oracle/apps/xxcrm/scs/fdk/webui/ODSCSFdkQstnsPG";
            System.out.println(URL); // retain AM
                pageContext.forwardImmediately(URL, null, 
                                               OAWebBeanConstants.KEEP_MENU_CONTEXT, 
                                               null, null, true, 
                                               OAWebBeanConstants.ADD_BREAD_CRUMB_YES);
        }
        if (("update").equals(event)) {
            // Get the identifier of the PPR event source row

            String rowReference = 
                pageContext.getParameter(EVENT_SOURCE_ROW_REFERENCE);
            System.out.println(rowReference);
            Row[] rows = 
                vo.getFilteredRows("SelectFlag", "Y"); // This check assumes getFilteredRows returns a zero-length array if
            // it finds no matches. This will also work if this method is changed
            // to return null if there are no matches.
            if ((rows != null) && (rows.length > 0)) {
                // Set the master row and get the unique identifier.
                Row masterRow = rows[0];
                vo.setCurrentRow(masterRow);
                //  String supplierName = (String)masterRow.getAttribute("Name");  
            }


            // Serializable[] parameters = { rowReference };

            // Pass the rowReference to a "handler" method in the application module.

            //  am.invokeMethod("<handleSomeEvent>", parameters);
        }

    }

}
