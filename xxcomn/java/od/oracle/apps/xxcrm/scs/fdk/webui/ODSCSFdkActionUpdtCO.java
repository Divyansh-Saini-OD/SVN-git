/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.scs.fdk.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;

import java.io.Serializable;

/**
 * Controller for ...
 */
public class ODSCSFdkActionUpdtCO extends OAControllerImpl {
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
        String id = pageContext.getParameter("SCSFrmAId");
        System.out.println(id);

        OAApplicationModule am = 
            (OAApplicationModule)pageContext.getApplicationModule(webBean);
        Serializable[] params = { id };
        am.invokeMethod("initQueryActionsDtls", params);

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


        OAApplicationModule am = pageContext.getApplicationModule(webBean);
        if (pageContext.getParameter("Cancel") != null) {
            am.invokeMethod("cancel", null);
            String URL = 
                "OA.jsp?page=/od/oracle/apps/xxcrm/scs/fdk/webui/ODSCSFdkActnsDtlsPG";
            System.out.println(URL); // retain AM
                pageContext.forwardImmediately(URL, null, KEEP_MENU_CONTEXT, 
                                               null, null, true, 
                                               ADD_BREAD_CRUMB_NO);

        }
        if (pageContext.getParameter("Apply") != null) {
            am.invokeMethod("apply", null);
            String URL = 
                "OA.jsp?page=/od/oracle/apps/xxcrm/scs/fdk/webui/ODSCSFdkActnsDtlsPG";
            System.out.println(URL); // retain AM
                pageContext.forwardImmediately(URL, null, KEEP_MENU_CONTEXT, 
                                               null, null, true, 
                                               ADD_BREAD_CRUMB_NO);
        }
    }

}
