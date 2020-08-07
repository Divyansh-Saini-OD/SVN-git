package com.od.external.view.ebs;

import com.od.external.model.am.TestExternalInteAMImpl;
import com.od.external.model.bean.FndUserBean;
import com.od.external.view.conn.ConnectionProvider;

import java.math.BigDecimal;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;

import java.util.ArrayList;
import java.util.Map;
import java.util.logging.Level;

import javax.faces.context.FacesContext;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import oracle.adf.share.ADFContext;
import oracle.adf.share.logging.ADFLogger;

import oracle.apps.fnd.ext.common.AppsRequestWrapper;
import oracle.apps.fnd.ext.common.CookieStatus;
import oracle.apps.fnd.ext.common.EBiz;
import oracle.apps.fnd.ext.common.Session;

import oracle.jbo.JboException;
import oracle.jbo.Row;
import oracle.jbo.RowSetIterator;
import oracle.jbo.ViewObject;
import oracle.jbo.client.Configuration;

public class EBizUtil {

    private static EBiz INSTANCE = null;
    private static ADFLogger _logger = ADFLogger.createADFLogger(EBizUtil.class);

    private static String currentUser = null;
    private static Integer currentUserId = null;
    private static Integer respId = null;
    private static Integer respApplId = null;
    private static BigDecimal orgid = null;
    private static AppsRequestWrapper wrappedRequest = null;
    private static FacesContext fctx = null;
    private static HttpServletRequest request = null;
    private static HttpServletResponse response = null;
    private static String pageName = null;
    private static String ebsURLVal =null;
    static {
        Connection connection = null;
        try {
            connection = ConnectionProvider.getConnection();
            // DO NOT hard code applServerID for a real application
            // Get applServerID as CONTEXT-PARAM from web.xml or elsewhere
            INSTANCE = new EBiz(connection, "59B79F4B8B124A06E0540010E01F6DCC28438940202994788949231276189441");
        } catch (SQLException e) {
            _logger.log(Level.SEVERE, "SQLException while creating EBiz instance -->", e);
            throw new RuntimeException(e);
        } catch (Exception e) {
            _logger.log(Level.SEVERE, "Exception while creating EBiz instance -->", e);
            throw new RuntimeException(e);
        } finally {
            if (connection != null) {
                try {
                    connection.close();
                } catch (SQLException e) {
                }
            }
        }
    }

    public static EBiz getEBizInstance() {
        return INSTANCE;
    }

    public static Session checkEBSSession(String pageNameParam) {
        pageName = pageNameParam;
        fctx = FacesContext.getCurrentInstance();
        Session sessionEBS = null;
        Connection conn = null;
        request = (HttpServletRequest) fctx.getExternalContext().getRequest();
        response = (HttpServletResponse) fctx.getExternalContext().getResponse();

        try {
            //conn = EBizUtil.getConnFromAM();
            //conn = AppModuleImpl.getConnFromDS();
            conn = ConnectionProvider.getConnection();

            wrappedRequest = new AppsRequestWrapper(request, response, conn, getEBizInstance());

            sessionEBS = wrappedRequest.getAppsSession(true);
            Map<String, String> sessionInfo = sessionEBS.getInfo();

            _logger.severe("severe>>>>>>sessionInfo" + sessionInfo);
            _logger.info("info>>>>>sessionInfo" + sessionInfo);
            String ebsUrlValue = wrappedRequest.getEbizInstance().getAppsServletAgent();
             ebsURLVal=ebsUrlValue+ "AppsLogin";
            _logger.info("info>>>>>ebsUrlValue" + ebsUrlValue);
            _logger.severe("info>>>>>ebsUrlValue" + ebsUrlValue);
            currentUser = sessionEBS.getUserName();
            _logger.info("info>>>>>currentUser" + currentUser);

            currentUser = sessionEBS.getUserName();
            _logger.severe("info>>>>>currentUser" + currentUser);

            if (!isAuthenticated(sessionEBS)) {
                _logger.info("No valid FND user ICX session exists" + " currently. Redirecting to EBS AppsLogin page");
                String ebsUrl = wrappedRequest.getEbizInstance().getAppsServletAgent();
                ebsUrl = ebsUrl + "AppsLogin"; // This url will redirect to SSO Url.
                _logger.info("ebsUrl = " + ebsUrl);
                response.sendRedirect(ebsUrl);
                fctx.responseComplete();
                return null;
            } else {
                _logger.info("We got a valid ICX session. Proceeding.");
                respId = Integer.parseInt(sessionInfo.get("RESPONSIBILITY_ID"));
                _logger.info(" sessionEBS.getUserName()>>>>>>>>>" + sessionEBS.getUserName());
                /*** POPUP MESSAGE ***
                FacesMessage message =
                    new FacesMessage("We got a valid ICX session. Proceeding " + sessionEBS.getUserName());
                fctx.addMessage(null, message);
                **********************/
                //
                //manageAttributes(wrappedRequest,response);
                //
            }
            updateUserBean(sessionEBS);
            return sessionEBS;

        } catch (Exception ex) {
            _logger.severe("Error , ", ex);
            throw (new JboException(ex));
        } finally {
            if (conn != null) {
                try {
                    conn.close();
                } catch (SQLException e) {
                }
            }
        }
    }


    private static boolean isAuthenticated(Session session) throws Exception {
        // It is always good to check for nullability
        // A null value means something went wrong in the JDBC operation
        if (session == null)
            throw new Exception("Could not initailize ICX session object");
        CookieStatus icxCookieStatus = session.getCurrentState().getIcxCookieStatus();
        if (!icxCookieStatus.equals(CookieStatus.VALID)) {
            _logger.info("Icx session either has expired or is invalid");
            return false;
        }
        return true;
    }


    public static void updateUserBean(Session sessionEBS) {
        Map sessionScope = ADFContext.getCurrent().getSessionScope();

        currentUser = sessionEBS.getUserName();
        //_logger.warning("currentUser:"+currentUser);
        currentUserId = new Integer(Integer.parseInt(sessionEBS.getUserId()));
        Map<String, String> sessionInfo = sessionEBS.getInfo();


        _logger.warning("sessionEBS.getUserId() :" + sessionEBS.getUserId());
        _logger.warning("currentUserId:" + currentUserId);

        respId = Integer.parseInt(sessionInfo.get("RESPONSIBILITY_ID"));
        _logger.warning("respId:" + respId);
        respApplId = Integer.parseInt(sessionInfo.get("RESPONSIBILITY_APPLICATION_ID"));
        //_logger.warning("respApplId:"+respApplId);
        if(sessionInfo.get("ORG_ID")!=null)
        orgid = new BigDecimal(sessionInfo.get("ORG_ID").toString());
        _logger.warning("orgid:" + orgid);
        FndUserBean fndUser = (FndUserBean) sessionScope.get("fndUserBean");


        /*** POPUP MESSAGE ***
        // FacesContext fctx = FacesContext.getCurrentInstance();
        FacesMessage message = new FacesMessage("Hello user " + currentUser);
        fctx.addMessage(null, message);
        message = new FacesMessage("RespID: " + respId);
        fctx.addMessage(null, message);
        *** END POPUP MESSAGE ***/

        if (fndUser == null) {
            fndUser = new FndUserBean();
            fndUser.setUserName(currentUser);
            fndUser.setUserid(currentUserId);
            fndUser.setRespId(respId);
            //fndUser.setOrgid(orgid);
            //fndUser.setRespApplId(respApplId);
            _logger.warning("fndUserBean is put into session bean");
            sessionScope.put("userId", currentUserId);
            sessionScope.put("userName", currentUser);
            sessionScope.put("respId", respId);
            sessionScope.put("respAppId", respApplId);
            sessionScope.put("orgid", orgid);
            sessionScope.put("ebsURL", ebsURLVal);
            _logger.severe(" session userid"+sessionScope.get("userId"));
            
        } else {
            if (fndUser.getRespId().intValue() != respId.intValue()) {
                /*
                message = new FacesMessage("Responsibility from: " + fndUser.getRespId() + " To: " + respId);
                fctx.addMessage(null, message);
                */
                fndUser.setRespId(respId);
                fndUser.setUserid(currentUserId);
                //fndUser.setOrgid(orgid);
                //fndUser.setRespApplId(respApplId);
                sessionScope.put("userId", currentUserId);
                sessionScope.put("userName", currentUser);
                sessionScope.put("respId", respId);
                sessionScope.put("respAppId", respApplId);
                sessionScope.put("orgid", orgid);
                sessionScope.put("ebsURL", ebsURLVal);
          //      sessionScope.put("respKey", respKey);
                _logger.warning("Responsibility is changed in fndUserBean");
                _logger.severe(" session userid"+sessionScope.get("userId"));

            }

        }
        /*
        message = new FacesMessage("Calling checkAuthorization");
        fctx.addMessage(null, message);
        */
        fndUser.setLastPageName(pageName);
        //        fndUser = checkAuthorization(fndUser);
        fndUser = checkEbsRole(fndUser);

        // KGOUGH 15-March-2017
      //  orgid = fndUser.getOrgid();

        _logger.warning("Calling set EBS Context for orgid: " + orgid);
        //callAMSetEBSContext(orgid);

        sessionScope.put("fndUserBean", fndUser);
        sessionScope.put("NewEntry", "true");
        //refreshServiceView();

    }


    public static FndUserBean checkEbsRole(FndUserBean fndUser) {
        _logger.warning("inside checkEbsRole------");

        ArrayList ebsRolesList = null;
        TestExternalInteAMImpl applicationModule =null;
    //        ApplicationModule am = ADFUtils.getApplicationModuleForDataControl("TestExternalInteAMDataControl");
    //        ViewObject vo = am.findViewObject("EbsRoleValues1");
        
                String amDef = "com.od.external.model.am.TestExternalInteAM";
        String config = "TestExternalInteAMLocal";
        try{
    applicationModule = (TestExternalInteAMImpl)Configuration.createRootApplicationModule(amDef, config);
    ViewObject vo = applicationModule.findViewObject("EbsRoleValues1");
    //Business logic goes here.......

        
    
    

        _logger.warning("inside checkEbsRole--getUserid----"+fndUser.getUserid());
        vo.setNamedWhereClauseParam("bindUserId",  fndUser.getUserid());
       
        vo.executeQuery();
        _logger.warning("inside checkEbsRole--getEstimatedRowCount----"+vo.getEstimatedRowCount());
        
            ViewObject respvo = applicationModule.findViewObject("EbsResponsibilitiesVO1");
            //Business logic goes here.......

                
            
            

                _logger.warning("inside checkEbsResp--getRespid----"+fndUser.getRespId());
                respvo.setNamedWhereClauseParam("bind_respId",  fndUser.getRespId());
               
                respvo.executeQuery();
                _logger.warning("inside checkEbsResp--getEstimatedRowCount----"+respvo.getEstimatedRowCount());
            Map sessionScope = ADFContext.getCurrent().getSessionScope();
                if(respvo.first()!=null)
                sessionScope.put("respKey", respvo.first().getAttribute("ResponsibilityKey").toString());
       
        RowSetIterator rsIter = vo.createRowSetIterator(null);
        ebsRolesList = new ArrayList();

        while (rsIter.hasNext()) {


            _logger.warning("inside while  ------");
            Row currRow = rsIter.next();
            _logger.warning("inside while  -RoleName-----" + currRow.getAttribute("RoleName"));
            ebsRolesList.add(currRow.getAttribute("RoleName"));

        }

        fndUser.setEbsRoles(ebsRolesList);
            
                  //  _logger.warning("Setting the context orgid::" + orgid);
                    CallableStatement cs = null;
                    String returnStatus = "NOT COMPLETED";
                    Object[] DRFND_EBI_REPROCESS_OBJ = new Object[7];
                    try {
                        cs =
                            applicationModule.getDBTransaction().createCallableStatement("begin mo_global.init('SQLAP'); mo_global.set_policy_context ('S',:P_orgid);FND_GLOBAL.APPS_INITIALIZE(:p_user_id,:p_resp_id,:p_resp_appid); end;",
                                                                            0);
                        cs.setObject("p_orgid", orgid);
                        cs.setObject("p_user_id", currentUserId);
                        cs.setObject("p_resp_id", respId);
                        cs.setObject("p_resp_appid", respApplId);
                        cs.execute();
                        _logger.warning(" context set currentUserId " + currentUserId.toString() +"respId "+respId+"respApplId "+respApplId );
                    } catch (SQLException sqlerr) {
                        _logger.warning(" error in context");
                        throw new JboException(sqlerr);
                    } finally {
                        try {
                            if (cs != null) {
                                cs.close();
                            }
                        } catch (SQLException closeerr) {
                            throw new JboException(closeerr);
                        }
                    }
                
             

        }catch(Exception ex){
           //Handle Error
        }finally{
           Configuration.releaseRootApplicationModule(applicationModule, false);
        }
         return fndUser;
    }

}
