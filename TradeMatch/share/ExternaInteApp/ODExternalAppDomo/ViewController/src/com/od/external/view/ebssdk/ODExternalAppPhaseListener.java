package com.od.external.view.ebssdk;

import com.od.external.model.bean.FndUserBean;

import com.od.external.view.ebs.EBizUtil;

import java.sql.SQLException;

import java.util.Map;

import javax.faces.context.FacesContext;

import oracle.adf.controller.v2.lifecycle.Lifecycle;
import oracle.adf.controller.v2.lifecycle.PagePhaseEvent;
import oracle.adf.controller.v2.lifecycle.PagePhaseListener;
import oracle.adf.share.ADFContext;
import oracle.adf.share.logging.ADFLogger;

import oracle.apps.fnd.ext.common.AppsRequestWrapper;
import oracle.apps.fnd.ext.common.Session;

public class ODExternalAppPhaseListener  implements PagePhaseListener {
    
    
    private static ADFLogger _logger = ADFLogger.createADFLogger(ODExternalAppPhaseListener.class);
    String currentUser = null;
    String currentUserId = null;
    Integer respId = null;
    Integer respApplId = null;
    AppsRequestWrapper wrappedRequest = null;
    FacesContext fctx = null;




    public void afterPhase(PagePhaseEvent pagePhaseEvent) {
        _logger.severe("afterPhase-->" + Lifecycle.getPhaseName(pagePhaseEvent.getPhaseId()));
        
        _logger.warning("afterPhase-->" + Lifecycle.getPhaseName(pagePhaseEvent.getPhaseId()));
        ///////////SET PAGE NAME HERE THIS CHANGES PER PAGE/////////
        String pageName = "TRANSACTION MONITOR";
        String lastPageName = null;

        /////////////////////////////////////////////////////////////

        if (pagePhaseEvent.getPhaseId() == Lifecycle.INIT_CONTEXT_ID) {
            fctx = FacesContext.getCurrentInstance();

            Map sessionScope = ADFContext.getCurrent().getSessionScope();
            FndUserBean fndUser = (FndUserBean) sessionScope.get("fndUserBean");
            
            _logger.severe("afterPhase--fndUser>" +fndUser);
         
            if ((fndUser != null)) {
                
                _logger.severe("afterPhase--getUserName>" +fndUser.getUserName());
                _logger.severe("afterPhase--getUserid>" +fndUser.getUserid());
                _logger.severe("afterPhase--getEbsRoles>" +fndUser.getEbsRoles());
                lastPageName = fndUser.getLastPageName();
            }
            _logger.warning("***Lifecycle.INIT_CONTEXT_ID***");
            if (!(fctx.isPostback())) {
            //if (!(pageName.equals(lastPageName))) {
                _logger.warning("Checking for EBS Session in afterPhase ");


               Session sessionEBS = EBizUtil.checkEBSSession(pageName);

                //setEBSLocale(sessionEBS);
            }

        } else if (pagePhaseEvent.getPhaseId() == Lifecycle.PREPARE_RENDER_ID) {
            if (wrappedRequest != null && wrappedRequest.getConnection() != null) {
                try {
                    if (!wrappedRequest.getConnection().isClosed()) {
                        wrappedRequest.getConnection().close();
                        _logger.warning("Connection is closed");
                    }
                } catch (SQLException e) {
                }
            }
        }
    }


    public void beforePhase(PagePhaseEvent pagePhaseEvent) {
        _logger.info("In before Phase, " + Lifecycle.getPhaseName(pagePhaseEvent.getPhaseId()));
    }
}
