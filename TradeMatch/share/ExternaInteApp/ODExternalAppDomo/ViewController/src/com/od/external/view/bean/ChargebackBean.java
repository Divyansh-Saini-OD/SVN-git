package com.od.external.view.bean;

import com.od.external.model.bean.FndUserBean;

import com.od.external.view.filter.EBSWrapperFilter;

import java.util.Map;

import java.util.logging.Logger;

import oracle.adf.share.ADFContext;
import oracle.adf.view.rich.component.rich.layout.RichPanelHeader;
import oracle.adf.view.rich.component.rich.output.RichOutputFormatted;

public class ChargebackBean {
    private static final Logger logger = Logger.getLogger(ChargebackBean.class.getName());
    private RichPanelHeader hederTitileBind;
    private RichOutputFormatted bindUserValue;

    public ChargebackBean() {
        logger.warning("Calling ChargebackBean-------- ");
        
        Map sessionScope = ADFContext.getCurrent().getSessionScope();
        FndUserBean fndUser = (FndUserBean)sessionScope.get("fndUserBean");
        
        logger.warning("Calling ChargebackBean for getEbsRoles: " + fndUser.getEbsRoles());
        logger.warning("Calling ChargebackBean getUserName: " + fndUser.getUserName());
        
    }

    public void setHederTitileBind(RichPanelHeader hederTitileBind) {
        this.hederTitileBind = hederTitileBind;
    }

    public RichPanelHeader getHederTitileBind() {
        return hederTitileBind;
    }

    public void setBindUserValue(RichOutputFormatted bindUserValue) {
        
   
        this.bindUserValue = bindUserValue;
        
    }

    public RichOutputFormatted getBindUserValue() {

       
    return bindUserValue;
    }
}
