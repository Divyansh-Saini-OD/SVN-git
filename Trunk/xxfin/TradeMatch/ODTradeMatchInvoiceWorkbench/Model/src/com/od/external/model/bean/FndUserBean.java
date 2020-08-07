package com.od.external.model.bean;

import java.io.Serializable;

import java.math.BigDecimal;

import java.util.ArrayList;

public class FndUserBean implements Serializable {
    @SuppressWarnings("compatibility:8177758295452990002")
    private static final long serialVersionUID = 1L;

    public FndUserBean() {
    }
    public FndUserBean(String username, Integer userid, Integer respid, Integer respapplid, boolean resubmitaccess, String ebsrole, BigDecimal orgid, ArrayList ebsRoles) {
        this.username = username;
        this.userid = userid;
        this.respid = respid;
        this.respapplid = respapplid;  
        this.resubmitaccess = resubmitaccess;
        this.ebsrole = ebsrole;
        this.orgid = orgid;
        this.ebsRoles=ebsRoles;
    
    }
    public void setUserName(String username) {
        this.username = username;
    }

    public String getUserName() {
        return username;
    }

    public void setUserid(Integer userid) {
        this.userid = userid;
    }

    public Integer getUserid() {
        return userid;
    }
    public void setRespId(Integer respid) {
        this.respid = respid;
    }

    public Integer getRespId() {
        return respid;
    }

    public void setRespapplId(Integer respapplid) {
        this.respapplid = respapplid;
    }

    public Integer getRespapplId() {
        return respapplid;
    }

    public void setResubmitaccess(boolean resubmitaccess) {
        this.resubmitaccess = resubmitaccess;
    }

    public boolean isResubmitaccess() {
        return resubmitaccess;
    }

    public void setLastPageName(String lastPageName) {
        this.lastPageName = lastPageName;
    }

    public String getLastPageName() {
        return lastPageName;
    }
    
    public String getEbsRole() {
        return ebsrole;
    }    
    
    public void setEbsRole(String ebsrole) {
        this.ebsrole = ebsrole;
    } 
    
    public BigDecimal getOrgid() {
        return orgid;
    }
    
    public void setOrgid(BigDecimal orgid) {
        this.orgid = orgid;
    }
    
    private String username;
    private Integer userid;

    public void setTaskFlowParam(double taskFlowParam) {
        this.taskFlowParam = taskFlowParam;
    }

    public double getTaskFlowParam() {
        return  Math.random();
    }
    private Integer respid;
    private Integer respapplid;
    private boolean resubmitaccess;
    private String lastPageName;
    private String ebsrole;
    private BigDecimal orgid;
    private double taskFlowParam;
    private ArrayList ebsRoles;

    public void setEbsRoles(ArrayList ebsRoles) {
        this.ebsRoles = ebsRoles;
    }

    public ArrayList getEbsRoles() {
        return ebsRoles;
    }
}

