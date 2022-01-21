package od.oracle.apps.xxcrm.addattr.account.stmts.webui;

import java.io.Serializable;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import java.sql.Connection;


import java.sql.SQLException;
import java.sql.Types;
import java.sql.CallableStatement;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageCheckBoxBean;

 /*
  --  Copyright (c) 2015, by Office Depot., All Rights Reserved
  --
  -- Author: Sridevi Kondoju
  -- Component Id: E0255 Mod4B
  -- Script Location:
             $CUSTOM_JAVA_TOP/od/oracle/apps/xxcrm/addattr/account/stmts/webui
  -- Description: Controller java file which used on 'Account Profile tab'
  --              For attribute group - STATEMENTS_AT_SHIP_TO
  -- Package Usage       : 
  -- Name                  Type         Purpose
  -- --------------------  -----------  ------------------------------------------
  --  processRequest       public void   Called up when page initally loads
   -- processFormRequest    public void  Called when page submitted
   -- Notes:
   -- History:
   -- Name            Date         Version    Description
   -- -----           -----        -------    -----------
   -- Sridevi Kondoju 27-MAR-2015  1.0        Initial version
   --
  */
  
/**
 * Controller for ...
 */
public class ODStatementsShiptoCO extends OAControllerImpl {
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
        pageContext.writeDiagnostics(this, 
                                     "XXOD: Start Process Request Controller", 
                                     1);

        initialize(pageContext, webBean);
        
        

       pageContext.writeDiagnostics(this, 
                                     "XXOD: End Process Request Controller", 
                                     1);
    }

    /**
     * Procedure to handle form submissions for form elements in
     * a region.
     * @param pageContext the current OA page context
     * @param webBean the web bean corresponding to the region
     */
    public void processFormRequest(OAPageContext pageContext, 
                                   OAWebBean webBean) {
        pageContext.writeDiagnostics(this, 
                                     "XXOD: Start Process Form Request Controller", 
                                     1);
        super.processFormRequest(pageContext, webBean);

        pageContext.writeDiagnostics(this, 
                                     "XXOD: End Process Form Request Controller", 
                                     1);
    }

    /**
      * Procedure called up for initializing 
      * a region.
      * @param pageContext the current OA page context
      * @param webBean the web bean corresponding to the region
      */
    public static void initialize(OAPageContext pageContext, 
                                  OAWebBean webBean) {
        pageContext.writeDiagnostics("ODStatementsShiptoCO", "XXOD: Start initialize", 
                                     1);

        OAApplicationModule nam = 
            (OAApplicationModule)pageContext.getApplicationModule(webBean);

        String custAcctId = pageContext.getParameter("AcctId");

        pageContext.writeDiagnostics("ODStatementsShiptoCO.initParams", 
                                     "XXOD: custAcctId:" + custAcctId, 1);
        if ("".equals(custAcctId))
            custAcctId = null;

        if (custAcctId == null) {
            pageContext.writeDiagnostics("ODStatementsShiptoCO.initParams", 
                                         "XXOD: Unable to initialize page.", 
                                         1);
          
        } else {
            pageContext.writeDiagnostics("ODStatementsShiptoCO.initParams", 
                                         "XXOD: before calling initCAVO " + 
                                         custAcctId, 1);
            Serializable[] params = { custAcctId };
            if (nam != null) {
                nam.invokeMethod("initVO", params);
            }
        }


        pageContext.writeDiagnostics("ODStatementsShiptoCO", "XXOD: End initialize", 
                                     1);
    }

   

}
