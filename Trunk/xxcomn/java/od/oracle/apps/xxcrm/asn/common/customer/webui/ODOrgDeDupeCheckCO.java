/*===========================================================================+
 |      Copyright (c) 2001 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 | 23-Sep-2008 Sarah Justina      Created to Fix the Party Duplication       |
 |                                QC #11358                                  |
 | 12-Jan-2010 Sarah Justina      Added File Comments                        |
 +===========================================================================*/
package  od.oracle.apps.xxcrm.asn.common.customer.webui;

/* Subversion Info:
 *
 * $HeadURL: http://svn.na.odcorp.net/svn/od/common/trunk/xxcomn/java/od/oracle/apps/xxcrm/asn/common/customer/webui/ODOrgDeDupeCheckCO.java $
 *
 * $Rev: 90446 $
 *
 * $Date: 2010-01-12 04:47:14 -0500 (Tue, 12 Jan 2010) $
 */


import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.asn.common.fwk.webui.ASNControllerObjectImpl;
import com.sun.java.util.collections.HashMap;
import oracle.jbo.common.Diagnostic;
import java.util.Vector;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.ar.hz.components.util.server.HzPuiServerUtil;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.asn.common.fwk.webui.ASNUIConstants;
import java.io.Serializable;

import java.sql.CallableStatement;

import oracle.apps.fnd.framework.webui.beans.nav.OABreadCrumbsBean;
import oracle.apps.fnd.framework.OAFwkConstants;
import java.sql.SQLException;
import oracle.jdbc.OracleCallableStatement;
import java.sql.Connection;

import java.sql.Types;

import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OADBTransaction;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.apps.fnd.framework.webui.OAWebBeanConstants;

import oracle.jbo.Row;
import oracle.jbo.domain.Number;

/**
 * Controller for ...
 */
public class ODOrgDeDupeCheckCO extends ASNControllerObjectImpl
{
  public static final String RCS_ID="$Header: ODOrgDeDupeCheckCO.java 115.7.115200.2 2005/05/25 00:03:13 vpalaiya ship $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "oracle.apps.asn.common.customer.webui");

  /**
   * Layout and page setup logic for AK region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODOrgDeDupeCheckCO.processRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
      boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);
    if (isProcLogEnabled)
    {
    pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processRequest(pageContext, webBean);
    // Diagnostic.println("----------------->ODOrgDeDupeCheckCO processRequest. " );

    OAApplicationModule am = (OAApplicationModule)pageContext.getRootApplicationModule();
    HashMap params = new HashMap();
    boolean duplicateExist = false;
    String buttonClicked = null;
    boolean bRetainAM = false;
    String sPartyId = null;
    String sPartyName = null;
    String fromLOV = pageContext.getParameter("ASNReqFromLOVPage");
    String relPartyId = null;
    String relId = null;
    String objPartyId = null;
    String subPartyId = null;
    String sicCode = pageContext.getParameter("SicCode");
    String wcw = pageContext.getParameter("Wcw");
    String noSiteAssoc = pageContext.getParameter("NoSiteAssoc");
    pageContext.writeDiagnostics(METHOD_NAME, "SMJ ODWcw:"+wcw, OAFwkConstants.STATEMENT);
    pageContext.writeDiagnostics(METHOD_NAME, "SMJ SicCodeHidden:"+sicCode, OAFwkConstants.STATEMENT);
    pageContext.writeDiagnostics(METHOD_NAME, "SMJ noSiteAssoc:"+noSiteAssoc, OAFwkConstants.STATEMENT);

    /************************************************
     * SJUSTINA:23-SEP-08 **Start of DupProfileCode
     * Code to check duplicates will be triggered
     * based on the profile HZ_DUP_PREVENTION_STATE
     ************************************************/
    String sDupPreventProfile = (String) pageContext.getProfile("HZ_DUP_PREVENTION_STATE");

    if ((sDupPreventProfile == null) || (sDupPreventProfile.equals("")))
          sDupPreventProfile = "DISABLED";

    if ( "ORG_ONLY".equals( sDupPreventProfile ) || "PERSON_AND_ORG".equals( sDupPreventProfile ))
    {
       duplicateExist =  HzPuiServerUtil.checkOrgDuplicates(am.getOADBTransaction(), am);
    }
    /**********************************************
     * SJUSTINA:23-SEP-08 **End of DupProfileCode**
     **********************************************/

    // Diagnostic.println("Duplicate exist: " + (duplicateExist ? "true" : "false"));

    if (!duplicateExist)
    {
        //am.invokeMethod("commitTransaction");
        buttonClicked = pageContext.getParameter("ASNReqFrmButtonClicked");
        Vector tempData = HzPuiServerUtil.getOrgProfileQuickEx((pageContext.getApplicationModule(webBean)).getOADBTransaction());
        if ( tempData != null )
        {
                 // Diagnostic.println("Org Vector Found = " + tempData.toString() );
                 HashMap hTemp = (HashMap)tempData.elementAt(0);
                 StringBuffer sbOrgId = new StringBuffer();
                 sbOrgId.append( hTemp.get("PartyId") );
                 StringBuffer sbOrgName = new StringBuffer();
                 sbOrgName.append( hTemp.get("OrganizationName") );
                 sPartyId = sbOrgId.toString();
                 sPartyName = sbOrgName.toString();
        }
        Vector tempData1 = HzPuiServerUtil.getContactRelRecord((pageContext.getApplicationModule(webBean)).getOADBTransaction());
                        if (tempData1 != null) {
                            if (isStatLogEnabled) {
                                pageContext.writeDiagnostics(METHOD_NAME,
                                                             "SMJ contact Vector Found = " +
                                                             tempData1.toString(),
                                                             OAFwkConstants.STATEMENT);
                            }
                            HashMap hTemp = (HashMap)tempData1.elementAt(0);
                            if(hTemp!=null){
                            relPartyId = hTemp.get("RelationshipPartyId").toString();
                            relId = hTemp.get("PartyRelationshipId").toString();
                            objPartyId = hTemp.get("ObjectId").toString();
                            subPartyId = hTemp.get("SubjectId").toString();
                            if (isStatLogEnabled) {
                                StringBuffer buf = new StringBuffer();
                                buf.append("SMJ relPartyId = ");
                                buf.append(relPartyId);
                                buf.append("SMJ relId = ");
                                buf.append(relId);
                                buf.append("SMJ objPartyId = ");
                                buf.append(objPartyId);
                                buf.append("SMJ subPartyId = ");
                                buf.append(subPartyId);
                                pageContext.writeDiagnostics(METHOD_NAME,
                                                             buf.toString(),
                                                             OAFwkConstants.STATEMENT);
                            }
                            }
                        }
        String partySiteId = null;
        OAApplicationModule nestedAM = (OAApplicationModule)am.findApplicationModule("HzPuiAddressAM");
        OAViewObjectImpl nestedVO = (OAViewObjectImpl)nestedAM.findViewObject("HzPuiPartySiteVO");
          if(nestedVO!=null){
           if(nestedVO.getCurrentRow()!=null){
            partySiteId = nestedVO.getCurrentRow().getAttribute("PartySiteId").toString();
           }
          }
        Serializable[] parameters = { sPartyId };
        am.invokeMethod("commitTransaction", parameters);
        Serializable[] params1 = {partySiteId,relId,wcw,sicCode,noSiteAssoc};
        am.invokeMethod("insertRecords",params1);

        /************************************************
         * SJUSTINA:23-SEP-08 **Start of Autonamed Call**
         ************************************************/
        String hardAssign = pageContext.getParameter("HardAssign");
        pageContext.writeDiagnostics("SMJ","HardAssign:"+hardAssign,OAFwkConstants.STATEMENT);
        if("HardAssign".equals(hardAssign))
          callHardAssignApi(pageContext,webBean);
        else
          callAutoNamedApi(pageContext,webBean);

        /************************************************
         * SJUSTINA:23-SEP-08 **End of Autonamed Call  **
         ************************************************/

        if(buttonClicked.equals("SaveAddMoreDetails")){
			          // Diagnostic.println("----------------->ODOrgDeDupeCheckCO processFormRequest. SaveAddMoreDetails event handling");
                params.put("ASNReqFrmFuncName", "ASN_ORGUPDATEPG");
                params.put("ASNReqFrmCustId", sPartyId);
                params.put("ASNReqFrmCustName", sPartyName);
                if(!this.isSubFlow(pageContext)){
                  // remove the current link from the bread crumb
                  OAPageLayoutBean pgLayout = pageContext.getPageLayoutBean();
                  OABreadCrumbsBean brdCrumb = (OABreadCrumbsBean)pgLayout.getBreadCrumbsLocator();
                  if(brdCrumb!=null)
                  {
                    int ct = brdCrumb.getLinkCount();
                    brdCrumb.removeLink(pageContext, (ct-1));
                  }
                }
                pageContext.forwardImmediately("ASN_ORGUPDATEPG",
                    KEEP_MENU_CONTEXT ,
                    null,
                    params,
                    false,
                    ADD_BREAD_CRUMB_YES);
        }else if(buttonClicked.equals("ApplyCreateAnother")) {
			          // Diagnostic.println("----------------->ODOrgDeDupeCheckCO processFormRequest. ApplyCreateAnother event handling");
                //this.processTargetURL(pageContext,null,null);
                params.put("ShowAll","Y");
                params.put("HideAll","N");
                pageContext.forwardImmediately("ASN_ORGCREATEPG",
                    KEEP_MENU_CONTEXT ,
                    null,
                    params,
                    false,
                    ADD_BREAD_CRUMB_SAVE);
        }else if(buttonClicked.equals("Apply")){
				        // Diagnostic.println("----------------->ODOrgDeDupeCheckCO processFormRequest. Apply event andling");
                if(pageContext.getParameter("ASNReqFromLOVPage") != null){
			            // Diagnostic.println("----------------->ODOrgDeDupeCheckCO processFormRequest.ASNReqFromLOVPage = " + fromLOV);
                  pageContext.putParameter("ASNReqSelCustId", sPartyId);
                  pageContext.putParameter("ASNReqSelCustName", sPartyName);
                  HashMap conditions = new HashMap();
                  conditions.put(ASNUIConstants.RETAIN_AM, "Y");
                  conditions.put("ASNReqFrmFuncName", "OD_ASN_CUSTOMER_SEARCHPG");
                  pageContext.releaseRootApplicationModule();
                  //this.processTargetURL(pageContext,conditions,null);
                   pageContext.forwardImmediately("OD_ASN_CUSTOMER_SEARCHPG",
                        OAWebBeanConstants.KEEP_MENU_CONTEXT ,
                        null,
                        conditions,
                        false,
                        OAWebBeanConstants.ADD_BREAD_CRUMB_SAVE);
                }else{
                    HashMap conditions = new HashMap();
                    conditions.put("ASNReqFrmFuncName", "OD_ASN_CUSTOMER_SEARCHPG");
                   //this.processTargetURL(pageContext,conditions,null);
                    pageContext.forwardImmediately("OD_ASN_CUSTOMER_SEARCHPG",
                         OAWebBeanConstants.KEEP_MENU_CONTEXT ,
                         null,
                         conditions,
                         false,
                         OAWebBeanConstants.ADD_BREAD_CRUMB_SAVE);
                }
        }

    }
    if (isProcLogEnabled)
    {
    pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }

  }

  /**
   * Procedure to handle form submissions for form elements in
   * AK region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODOrgDeDupeCheckCO.processFormRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    if (isProcLogEnabled)
    {
    pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processFormRequest(pageContext, webBean);

    if (isProcLogEnabled)
    {
    pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }

  }

    private void callAutoNamedApi(OAPageContext pageContext, OAWebBean webBean)
         {
     String s = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODOrgCreateCO.callAutoNamedApi";
         boolean flag = pageContext.isLoggingEnabled(2);
         if(flag)
             pageContext.writeDiagnostics(s, "Begin", 2);
        String HzPuiCreatedPartySiteId = (String)pageContext.getTransactionTransientValue("HzPuiCreatedPartySiteId");
        pageContext.writeDiagnostics(s, "HzPuiCreatedPartySiteId : " +HzPuiCreatedPartySiteId , 2);
        String resourceId = pageContext.getParameter("WinnerResId");
        String roleId = pageContext.getParameter("WinnerRoleId");
        String groupId = pageContext.getParameter("WinnerGroupId");
        String fullAccFlag = pageContext.getParameter("WinnerAccFlag");
        pageContext.writeDiagnostics(s, "WinnerResId : " +resourceId , 2);
        pageContext.writeDiagnostics(s, "WinnerRoleId : " +roleId , 2);
        pageContext.writeDiagnostics(s, "WinnerGroupId : " +groupId , 2);
        pageContext.writeDiagnostics(s, "WinnerAccFlag : " +fullAccFlag , 2);
        StringBuffer hardQry = new StringBuffer();

         hardQry.append("BEGIN XX_JTF_RS_NAMED_ACC_TERR_PUB.Create_Territory(p_api_version_number => :1");
         hardQry.append(",p_status => :2, p_full_access_flag => :3");
         hardQry.append(",p_source_terr_id => :4,p_resource_id => :5,p_role_id => :6");
         hardQry.append(",p_group_id  => :7 ,p_entity_type => :8,p_entity_id => :9");
         hardQry.append(",p_source_entity_id => :10,p_terr_asgnmnt_source     => :11");
         hardQry.append(",x_error_code => :12,x_error_message => :13); end;");
        String appDtsQry = hardQry.toString();
        pageContext.writeDiagnostics(s, "appDtsQry : " +appDtsQry , 2);
        OADBTransaction transaction =  pageContext.getApplicationModule(webBean).getOADBTransaction();
        Connection objConn = transaction.getJdbcConnection();
        //OracleCallableStatement objStmt = null;
        CallableStatement objStmt = null;
        String errCode = null;
        String errMsg = null;
         try{
             pageContext.writeDiagnostics(s, "B4 Call" , 2);
             objStmt = objConn.prepareCall(appDtsQry);
             objStmt.setDouble(1,1.0);
             objStmt.setString(2,"A");
             objStmt.setString(3,fullAccFlag);
             objStmt.setInt(4,-1);
             objStmt.setInt(5,Integer.parseInt(resourceId));
             objStmt.setInt(6,Integer.parseInt(roleId));
             objStmt.setInt(7,Integer.parseInt(groupId));
             objStmt.setString(8,"PARTY_SITE");
             objStmt.setInt(9,Integer.parseInt(HzPuiCreatedPartySiteId));
             objStmt.setInt(10,-1);
             objStmt.setString(11,"Rule Based Assignment - Online");
             objStmt.registerOutParameter(12,Types.VARCHAR);
             objStmt.registerOutParameter(13,Types.VARCHAR);

             objStmt.execute();
             pageContext.writeDiagnostics(s, "After Execute" , 2);

             errCode = objStmt.getString(12);
             errMsg = objStmt.getString(13);
             pageContext.writeDiagnostics(s, "errCode:"+errCode , 2);
             pageContext.writeDiagnostics(s, "errMsg:"+errMsg , 2);
             doCommit(pageContext);
             if(!"S".equals(errCode)){
                 throw new OAException("The system has encountered an unexpected error during Autonamed Assignment:"+errMsg);
             }
         }
         catch(SQLException e){
             pageContext.writeDiagnostics(s, "Error during Execute:"+e.getMessage()+e.getStackTrace() , 2);
             e.printStackTrace(System.err);
             throw new OAException("The system has encountered an unexpected error during Autonamed Assignment. The signature could have changed.");
         }
         finally{
           try {
               if(objStmt!=null)
                   objStmt.close();
               }
           catch(SQLException e){
               e.printStackTrace(System.err);
           }
         }
        if(flag)
             pageContext.writeDiagnostics(s, "End", 2);

         }

    private void callHardAssignApi(OAPageContext pageContext, OAWebBean webBean)
         {
     String s = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODOrgDeDupeCheckCO.callHardAssignApi";
         boolean flag = pageContext.isLoggingEnabled(2);
         if(flag)
             pageContext.writeDiagnostics(s, "Begin", 2);
        String HzPuiCreatedPartySiteId = (String)pageContext.getTransactionTransientValue("HzPuiCreatedPartySiteId");
        pageContext.writeDiagnostics(s, "HzPuiCreatedPartySiteId : " +HzPuiCreatedPartySiteId , 2);
        String resourceId = pageContext.getParameter("GeneralRepId");
        String roleId = pageContext.getParameter("GenRoleId");
        String groupId = pageContext.getParameter("GenGroupId");
        pageContext.writeDiagnostics(s, "GeneralRepId : " +resourceId , 2);
        pageContext.writeDiagnostics(s, "GenRoleId : " +roleId , 2);
        pageContext.writeDiagnostics(s, "GenGroupId : " +groupId , 2);
        StringBuffer hardQry = new StringBuffer();

         hardQry.append("BEGIN XX_JTF_RS_NAMED_ACC_TERR_PUB.Create_Territory(p_api_version_number => :1");
         hardQry.append(",p_status => :2");
         hardQry.append(",p_source_terr_id => :3,p_resource_id => :4,p_role_id => :5");
         hardQry.append(",p_group_id  => :6 ,p_entity_type => :7,p_entity_id => :8");
         hardQry.append(",p_source_entity_id => :9,p_terr_asgnmnt_source     => :10");
         hardQry.append(",x_error_code => :11,x_error_message => :12); end;");
        String appDtsQry = hardQry.toString();
        pageContext.writeDiagnostics(s, "appDtsQry : " +appDtsQry , 2);
        OADBTransaction transaction =  pageContext.getApplicationModule(webBean).getOADBTransaction();
        Connection objConn = transaction.getJdbcConnection();
        //OracleCallableStatement objStmt = null;
        CallableStatement objStmt = null;
        String errCode = null;
        String errMsg = null;
         try{
             pageContext.writeDiagnostics(s, "B4 Call" , 2);
             objStmt = objConn.prepareCall(appDtsQry);
             objStmt.setDouble(1,1.0);
             objStmt.setString(2,"A");
             objStmt.setInt(3,-1);
             objStmt.setInt(4,Integer.parseInt(resourceId));
             objStmt.setInt(5,Integer.parseInt(roleId));
             objStmt.setInt(6,Integer.parseInt(groupId));
             objStmt.setString(7,"PARTY_SITE");
             objStmt.setInt(8,Integer.parseInt(HzPuiCreatedPartySiteId));
             objStmt.setInt(9,-1);
             objStmt.setString(10,"Territory Override");
             objStmt.registerOutParameter(11,Types.VARCHAR);
             objStmt.registerOutParameter(12,Types.VARCHAR);

             objStmt.execute();
             pageContext.writeDiagnostics(s, "After Execute" , 2);

             errCode = objStmt.getString(11);
             errMsg = objStmt.getString(12);
             pageContext.writeDiagnostics(s, "errCode:"+errCode , 2);
             pageContext.writeDiagnostics(s, "errMsg:"+errMsg , 2);
             doCommit(pageContext);
             if(!"S".equals(errCode)){
                 throw new OAException("The system has encountered an unexpected error during Hard Assignment:"+errMsg);
             }
         }
         catch(SQLException e){
             pageContext.writeDiagnostics(s, "Error during Execute:"+e.getMessage()+e.getStackTrace() , 2);
             e.printStackTrace(System.err);
             throw new OAException("The system has encountered an unexpected error during Hard Assignment. The signature could have changed.");
         }
         finally{
           try {
               if(objStmt!=null)
                   objStmt.close();
               }
           catch(SQLException e){
               e.printStackTrace(System.err);
           }
         }
        if(flag)
             pageContext.writeDiagnostics(s, "End", 2);

         }

}

