package od.oracle.apps.xxcrm.addattr.achcccontrol.creditauth.webui;

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
  -- Component Id: E1356 CR1120
  -- Script Location:
             $CUSTOM_JAVA_TOP/od/oracle/apps/xxcrm/addattr/achcccontrol/creditauth/webui
  -- Description: Controller java file which used on 'Account Profile tab'
  --              For attribute group - CREDIT_AUTH_GROUP
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
public class ODCreditAuthCO extends OAControllerImpl {
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
        
        

        applyFinHierView(pageContext, webBean);

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
        pageContext.writeDiagnostics("ODCreditAuthCO", "XXOD: Start initialize", 
                                     1);

        OAApplicationModule nam = 
            (OAApplicationModule)pageContext.getApplicationModule(webBean);

        String custAcctId = pageContext.getParameter("AcctId");

        pageContext.writeDiagnostics("ODCreditAuthCO.initParams", 
                                     "XXOD: custAcctId:" + custAcctId, 1);
        if ("".equals(custAcctId))
            custAcctId = null;

        if (custAcctId == null) {
            pageContext.writeDiagnostics("ODCreditAuthCO.initParams", 
                                         "XXOD: Unable to initialize page.", 
                                         1);
          
        } else {
            pageContext.writeDiagnostics("ODCreditAuthCO.initParams", 
                                         "XXOD: before calling initCAVO " + 
                                         custAcctId, 1);
            Serializable[] params = { custAcctId };
            if (nam != null) {
                nam.invokeMethod("initCAVO", params);
            }
        }


        pageContext.writeDiagnostics("ODCreditAuthCO", "XXOD: End initialize", 
                                     1);
    }

    /**
      * Procedure 
      * 
      * @param pageContext the current OA page context
      * @param webBean the web bean corresponding to the region
      */
   public void applyFinHierView(OAPageContext pageContext, OAWebBean webBean) {
       String isFinParent = "N";

       pageContext.writeDiagnostics(this, "Begin applyFinHierView", 1);

       String custAcctId = pageContext.getParameter("AcctId");

       pageContext.writeDiagnostics(this, "custAcctId:" + custAcctId, 1);


       CallableStatement cs = null;
       OADBTransaction oadbtransaction =  pageContext.getApplicationModule(webBean).getOADBTransaction();

     try {
           if (custAcctId != null)   {
            

              pageContext.writeDiagnostics(this, "custAcctId:" + custAcctId, 1);
        
              cs = oadbtransaction.getJdbcConnection().prepareCall("{? = call XX_CDH_EXTN_ACHCCCONTROL_PKG.chk_creditauth(:2)}");



               cs.registerOutParameter(1, Types.VARCHAR);
               cs.setString(2, custAcctId);

               cs.execute();

               isFinParent = cs.getString(1);


               pageContext.writeDiagnostics(this, 
                                            "isFinParent:" + isFinParent, 1);


               

           }
       }catch (Exception e) {
          pageContext.writeDiagnostics(this, 
                                            "Exception:" + e.toString(), 1);
        }
	finally {
            if (cs!=null) try {cs.close();} catch (Exception ex) {};
	}

       OAMessageCheckBoxBean cb = 
                   (OAMessageCheckBoxBean)webBean.findChildRecursive("chkODCreditAuthCheck");
               if ("Y".equals(isFinParent)) {

                   if (cb != null) {
                       cb.setAttributeValue(OAWebBeanConstants.READ_ONLY_ATTR, 
                                            Boolean.FALSE);
                   }
               } else {
                   if (cb != null) {
                       cb.setAttributeValue(OAWebBeanConstants.READ_ONLY_ATTR, 
                                            Boolean.TRUE);
                   }

               }

   }


}
