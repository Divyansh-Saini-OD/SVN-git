package com.od.external.view.filter;


import com.od.external.model.bean.FndUserBean;
import com.od.external.view.conn.ConnectionProvider;
import com.od.external.view.ebs.EBizUtil;

import java.io.IOException;

import java.math.BigDecimal;

import java.sql.SQLException;

import java.util.ArrayList;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.faces.context.FacesContext;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import oracle.adf.share.ADFContext;

import oracle.apps.fnd.ext.common.AppsRequestWrapper;
import oracle.apps.fnd.ext.common.AppsRequestWrapper.WrapperException;
import oracle.apps.fnd.ext.common.CookieStatus;
import oracle.apps.fnd.ext.common.Session;

import oracle.jbo.ApplicationModule;
import oracle.jbo.Row;
import oracle.jbo.RowSetIterator;
import oracle.jbo.ViewObject;
import oracle.jbo.client.Configuration;


public class EBSWrapperFilter implements Filter {
    private FilterConfig _filterConfig = null;
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

    private static final Logger logger = Logger.getLogger(EBSWrapperFilter.class.getName());

    public void destroy() {
        logger.info("Filter destroyed ");
    }

    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException,
                                                                                                     ServletException {
        logger.info("-current URI =" + ((HttpServletRequest) request).getRequestURI());
        AppsRequestWrapper wrapper = null;
        try {
            Session sessionEBS = null;
            wrapper =
                new AppsRequestWrapper((HttpServletRequest) request, (HttpServletResponse) response,
                                       ConnectionProvider.getConnection(), EBizUtil.getEBizInstance());


            System.out.println(wrapper.getCurrentUserId());
            logger.severe("wrapper testing .. >>>>>>user id " + wrapper.getCurrentUserId());
            logger.severe("wrapper>>>>>>getUserPrincipal" + wrapper.getUserPrincipal());


            logger.severe("wrapper>>>>>>sessionInfo" + wrapper);
          


            sessionEBS = wrapper.getAppsSession(true);
            Map<String, String> sessionInfo = sessionEBS.getInfo();
            String ebsUrlValue = wrappedRequest.getEbizInstance().getAppsServletAgent();
            logger.info("We got ebsUrlValue"+ebsUrlValue);
            logger.severe("We got ebsUrlValue"+ebsUrlValue);
            System.err.println("We got ebsUrlValue"+ebsUrlValue);

            if (!isAuthenticated(sessionEBS)) {
                logger.info("No valid FND user ICX session exists" + " currently. Redirecting to EBS AppsLogin page");
                String ebsUrl = wrappedRequest.getEbizInstance().getAppsServletAgent();
                ebsUrl = ebsUrl + "AppsLogin"; // This url will redirect to SSO Url.
                logger.info("ebsUrl = " + ebsUrl);
                // response.sendRedirect(ebsUrl);
                fctx.responseComplete();

            } else {
                logger.info("We got a valid ICX session. Proceeding.");
                respId = Integer.parseInt(sessionInfo.get("RESPONSIBILITY_ID"));
                /*** POPUP MESSAGE ***
                FacesMessage message =
                    new FacesMessage("We got a valid ICX session. Proceeding " + sessionEBS.getUserName());
                fctx.addMessage(null, message);
                **********************/
                //
                //manageAttributes(wrappedRequest,response);
                //

              //  updateUserBean(sessionEBS);
            }
        } catch (WrapperException e2) {
            logger.log(Level.SEVERE, "WrapperException error encountered ", e2);
            throw new ServletException(e2);
        } catch (SQLException e2) {
            logger.log(Level.SEVERE, "SQLException error encountered ", e2);
            throw new ServletException(e2);
        } catch (Exception e) {
        }
        try {
            logger.info("Created AppsRequestWrapper object." + " Continuing the filter chain.");
            chain.doFilter(wrapper, response);
            logger.info("- the filter chain ends");
        } finally {

            if (wrapper != null) {
                logger.info("- releasing the connection attached to the" + " current AppsRequestWrapper instance ");
                try {
                    wrapper.getConnection().close();
                } catch (SQLException e3) {
                    logger.log(Level.WARNING, "SQLException error while closing connection-- ", e3);
                }
            }
            wrapper = null;
        }
    }

    public void init(FilterConfig filterConfig) throws ServletException {
        logger.info("Filter initialized ");
    }

    private static boolean isAuthenticated(Session session) throws Exception {
        // It is always good to check for nullability
        // A null value means something went wrong in the JDBC operation
        if (session == null)
            throw new Exception("Could not initailize ICX session object");
        CookieStatus icxCookieStatus = session.getCurrentState().getIcxCookieStatus();
        if (!icxCookieStatus.equals(CookieStatus.VALID)) {
            logger.info("Icx session either has expired or is invalid");
            return false;
        }
        return true;
    }

    public static void updateUserBean(Session sessionEBS) {
        Map sessionScope = ADFContext.getCurrent().getSessionScope();

        currentUser = sessionEBS.getUserName();
        logger.warning("currentUser:" + currentUser);
        currentUserId = new Integer(Integer.parseInt(sessionEBS.getUserId()));
        Map<String, String> sessionInfo = sessionEBS.getInfo();


        logger.warning("sessionEBS.getUserId() :" + sessionEBS.getUserId());
        logger.warning("currentUserId:" + currentUserId);

        logger.warning("sessionEBS.getInfo()" + sessionEBS.getInfo());

        logger.warning("sessionEBS.getAttributes()" + sessionEBS.getAttributes());

        respId = Integer.parseInt(sessionInfo.get("RESPONSIBILITY_ID"));
        logger.warning("respId:" + respId);
        respApplId = Integer.parseInt(sessionInfo.get("RESPONSIBILITY_APPLICATION_ID"));
        logger.warning("respApplId:" + respApplId);

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
            logger.warning("fndUserBean is put into session bean");
            
            fndUser = checkEbsRole(fndUser);
            sessionScope.put("userId", currentUserId);
            sessionScope.put("userName", currentUser);
            logger.severe(" session userid"+sessionScope.get("userId"));
            
        } else {
            if (fndUser.getRespId().intValue() != respId.intValue()) {
                /*
                message = new FacesMessage("Responsibility from: " + fndUser.getRespId() + " To: " + respId);
                fctx.addMessage(null, message);
                */
                fndUser.setRespId(respId);
                fndUser.setUserName(currentUser);
                fndUser.setUserid(currentUserId);
                //fndUser.setOrgid(orgid);
                //fndUser.setRespApplId(respApplId);
                sessionScope.put("userId", currentUserId);
                sessionScope.put("userName", currentUser);
                logger.warning("Responsibility is changed in fndUserBean");
                logger.severe(" session userid"+sessionScope.get("userId"));
                
            }

        }
        /*
        message = new FacesMessage("Calling checkAuthorization");
        fctx.addMessage(null, message);
        */
        fndUser.setLastPageName(pageName);
        //        fndUser = checkAuthorization(fndUser);
      

        // KGOUGH 15-March-2017
        orgid = fndUser.getOrgid();

        logger.warning("Calling set EBS Context for orgid: " + orgid);
        //callAMSetEBSContext(orgid);

        sessionScope.put("fndUserBean", fndUser);
        sessionScope.put("NewEntry", "true");
        
        
        FndUserBean fndUser1 = (FndUserBean)sessionScope.get("fndUserBean");
        
        logger.warning("Calling set EBS Context for getEbsRoles: " + fndUser1.getEbsRoles());
        logger.warning("Calling set EBS Context for getUserName: " + fndUser1.getUserName());
        //refreshServiceView();

    }


    public static FndUserBean checkEbsRole(FndUserBean fndUser) {
        logger.warning("inside checkEbsRole------");

        ArrayList ebsRolesList = null;
        ApplicationModule applicationModule =null;
//        ApplicationModule am = ADFUtils.getApplicationModuleForDataControl("TestExternalInteAMDataControl");
//        ViewObject vo = am.findViewObject("EbsRoleValues1");
        
                String amDef = "com.od.external.model.am.TestExternalInteAM";
        String config = "TestExternalInteAMLocal";
        try{
    applicationModule = Configuration.createRootApplicationModule(amDef, config);
    ViewObject vo = applicationModule.findViewObject("EbsRoleValues1");
   //Business logic goes here.......

        
   
   

        logger.warning("inside checkEbsRole--getUserid----"+fndUser.getUserid());
        vo.setNamedWhereClauseParam("bindUserId",  fndUser.getUserid());
       
        vo.executeQuery();
        logger.warning("inside checkEbsRole--getEstimatedRowCount----"+vo.getEstimatedRowCount());
        
       
        RowSetIterator rsIter = vo.createRowSetIterator(null);
        ebsRolesList = new ArrayList();

        while (rsIter.hasNext()) {


            logger.warning("inside while  ------");
            Row currRow = rsIter.next();
            logger.warning("inside while  -RoleName-----" + currRow.getAttribute("RoleName"));
            ebsRolesList.add(currRow.getAttribute("RoleName"));

        }

        fndUser.setEbsRoles(ebsRolesList);
        }catch(Exception ex){
           //Handle Error
        }finally{
           Configuration.releaseRootApplicationModule(applicationModule, false);
        }
         return fndUser;
    }
}
