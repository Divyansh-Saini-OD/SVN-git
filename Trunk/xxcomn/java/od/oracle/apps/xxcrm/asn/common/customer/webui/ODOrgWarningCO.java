/*===========================================================================+
 |      Copyright (c) 2001 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 | 23-Sep-2008 Sarah Justina      Created to Fix the Party Duplication       |
 |                                QC #11358                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.common.customer.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.asn.common.fwk.webui.ASNControllerObjectImpl;
import com.sun.java.util.collections.HashMap;
import java.util.Vector;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.ar.hz.components.util.server.HzPuiServerUtil;
import oracle.apps.ar.hz.components.util.webui.HzPuiWebuiUtil;
import oracle.apps.fnd.framework.OAException;
import java.io.Serializable;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.asn.common.fwk.webui.ASNUIConstants;
import oracle.apps.fnd.framework.webui.beans.nav.OABreadCrumbsBean;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.layout.OATableLayoutBean;
import java.sql.SQLException;
import oracle.jdbc.OracleCallableStatement;
import java.sql.Connection;
import oracle.apps.fnd.framework.server.OADBTransaction;

/**
 * Controller for ...
 */
public class ODOrgWarningCO extends ASNControllerObjectImpl
{
  public static final String RCS_ID="$Header: ODOrgWarningCO.java 115.14 2005/05/11 23:58:19 vpalaiya ship $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "oracle.apps.asn.common.customer.webui");

  /**
   * Layout and page setup logic for AK region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODOrgWarningCO.processRequest";
	boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
	if (isProcLogEnabled) {
	  pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
	}

    super.processRequest(pageContext, webBean);

    //Diagnostic.println("----------------->ODOrgWarningCO: processRequest() begin");

    if(this.isSubFlow(pageContext))
    {
      //Diagnostic.println("----------------->ODOrgWarningCO: This is a subflow");
      //disable the breadcrumbs
      ((OAPageLayoutBean) webBean).setBreadCrumbEnabled(false);
      //If it is a subflow page, need to retain context parameters here
	    retainContextParameters(pageContext);
    }

    //hide the un-supported items in the tca components that should not be personalized by the user
    //dqm search results section
    OATableLayoutBean asnOrgDeDupeRN = (OATableLayoutBean) webBean.findChildRecursive("ASNOrgDeDupeRN");
    if(asnOrgDeDupeRN != null)
    {
      //hide the un-used buttons
      OASubmitButtonBean hzPuiMarkDupButton=  (OASubmitButtonBean)asnOrgDeDupeRN.findChildRecursive("HzPuiMarkDup");
      if(hzPuiMarkDupButton != null)
      {
        hzPuiMarkDupButton.setRendered(false);
      }

      OASubmitButtonBean hzPuiPurchaseButton=  (OASubmitButtonBean)asnOrgDeDupeRN.findChildRecursive("HzPuiPurchase");
      if(hzPuiPurchaseButton != null)
      {
        hzPuiPurchaseButton.setRendered(false);
      }

      OASubmitButtonBean hzPuiCreateButton=  (OASubmitButtonBean)asnOrgDeDupeRN.findChildRecursive("HzPuiCreate");
      if(hzPuiCreateButton != null)
      {
        hzPuiCreateButton.setRendered(false);
      }

      //hide update icon column in the dqm search results table
      // Hide the "Update" bean. Made changes here for backward compatibility as TCA
      // CPUI component changed from Link to Switcher Bean. Original reference to OALinkBean
      // is removed as part of the fix.
      if(asnOrgDeDupeRN.findChildRecursive("Update") != null)
      {
        asnOrgDeDupeRN.findChildRecursive("Update").setRendered(false);
      }
    }
    //dqm search results section
    //end of hiding the un-supported items in tca components that should not be personalizable

    //Diagnostic.println("----------------->ODOrgWarningCO: ASNReqFromLOVPage =" + pageContext.getParameter("ASNReqFromLOVPage"));
    //Diagnostic.println("----------------->ODOrgWarningCO: processRequest() end");

	if (isProcLogEnabled) {
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
    final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODOrgWarningCO.processFormRequest";
	boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
	if (isProcLogEnabled) {
	  pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
	}

    super.processFormRequest(pageContext, webBean);
    pageContext.putParameter("ASNReqFrmFuncName","ASN_ORGWARNINGPG");
    //Diagnostic.println("----------------->ODOrgWarningCO: processFormRequest() begin");

    OAApplicationModule am = (OAApplicationModule)pageContext.getRootApplicationModule();
    String sPartyId = null;
    String sPartyName = null;
    HashMap params = new HashMap();
    String buttonClicked = pageContext.getParameter("ASNReqFrmButtonClicked");
    String fromLOV = pageContext.getParameter("ASNReqFromLOVPage");

    //If the user clicked on the Use Existing Button
    if (pageContext.getParameter("HzPuiSelectOrgButton") != null)
    {
        //Diagnostic.println("----------------->ODOrgWarningCO processFormRequest. HzPuiSelectOrgButton Selected ");
        sPartyId = HzPuiWebuiUtil.getSelectedOrgId( pageContext, webBean);
        if ( sPartyId == null )  {
           OAException e = new OAException("ASN", "ASN_CMMN_CUST_MISS_ERR");
           pageContext.putDialogMessage(e);
        } else{
           //Diagnostic.println("----------------->ODOrgWarningCO processFormRequest. sPartyId: "+ sPartyId);
           Serializable[] parameters =  { sPartyId };
           sPartyName = (String) am.invokeMethod("getPartyNameFromId", parameters);
           //Diagnostic.println("----------------->ODOrgWarningCO processFormRequest. sPartyName: "+ sPartyName);
        }
        if(buttonClicked.equals("SaveAddMoreDetails")){
			          //Diagnostic.println("----------------->ODOrgWarningCO processFormRequest. SaveAddMoreDetails event handling");
                String custAccMode = this.checkAccessPrivilege(pageContext,
                                                     ASNUIConstants.CUSTOMER_ENTITY,
                                                     sPartyId,
                                                     true);
                if(custAccMode.equals(ASNUIConstants.UPDATE_ACCESS)) {
                    params.put("ASNReqFrmCustId", sPartyId);
                    params.put("ASNReqFrmCustName", sPartyName);
                    params.put("ASNReqFrmFuncName", "ASN_ORGUPDATEPG");
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
                } else if(custAccMode.equals(ASNUIConstants.READ_ACCESS)){
                    params.put("ASNReqFrmCustId", sPartyId);
                    params.put("ASNReqFrmCustName", sPartyName);
                    params.put("ASNReqFrmFuncName", "ASN_ORVIEWROPG");
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
                    pageContext.forwardImmediately("ASN_ORGVIEWROPG",
                            KEEP_MENU_CONTEXT ,
                            null,
                            params,
                            false,
                            ADD_BREAD_CRUMB_YES);
                }
        }else if(buttonClicked.equals("ApplyCreateAnother")) {
			          //Diagnostic.println("----------------->ODOrgWarningCO processFormRequest. ApplyCreateAnother event handling");
                //this.processTargetURL(pageContext,null,null);
                pageContext.forwardImmediately("ASN_ORGCREATEPG",
                    KEEP_MENU_CONTEXT ,
                    null,
                    params,
                    true,
                    ADD_BREAD_CRUMB_SAVE);
        }else if(buttonClicked.equals("Apply")){
				        //Diagnostic.println("----------------->ODOrgWarningCO processFormRequest. Apply event andling");
                if(pageContext.getParameter("ASNReqFromLOVPage") != null){
			            //Diagnostic.println("----------------->ODOrgWarningCO processFormRequest.ASNReqFromLOVPage = " + fromLOV);
                  pageContext.putParameter("ASNReqSelCustId", sPartyId);
                  pageContext.putParameter("ASNReqSelCustName", sPartyName);
                  HashMap conditions = new HashMap();
                  conditions.put(ASNUIConstants.RETAIN_AM, "Y");
                  pageContext.releaseRootApplicationModule();
                  this.processTargetURL(pageContext,conditions,null);
                }else{
                   this.processTargetURL(pageContext,null,null);
                }
        }
    }
    //If the user clicked on create?
    else if( pageContext.getParameter("HzPuiOrgCreate") != null )
    {
       //Diagnostic.println("----------------->ODOrgWarningCO processFormRequest. HzPuiOrgCreate Selected ");
       Vector tempData = null;
       tempData = HzPuiServerUtil.getOrgProfileQuickEx((pageContext.getApplicationModule(webBean)).getOADBTransaction());
       if ( tempData != null )
        {
                 //Diagnostic.println("Org Vector Found = " + tempData.toString() );
                 HashMap hTemp = (HashMap)tempData.elementAt(0);
                 StringBuffer sbOrgId = new StringBuffer();
                 sbOrgId.append( hTemp.get("PartyId") );
                 StringBuffer sbOrgName = new StringBuffer();
                 sbOrgName.append( hTemp.get("OrganizationName") );
                 sPartyId = sbOrgId.toString();
                 sPartyName = sbOrgName.toString();
        }
        //Diagnostic.println("----------------->ODOrgWarningCO processFormRequest. Commit Transaction");
        //am.invokeMethod("commitTransaction");
        Serializable[] parameters = { sPartyId };
        am.invokeMethod("commitTransaction", parameters);
        /************************************************
         * SJUSTINA:23-SEP-08 **Start of Autonamed Call**
         ************************************************/

		callAutoNamedApi(pageContext,webBean);

        /************************************************
         * SJUSTINA:23-SEP-08 **End of Autonamed Call  **
         ************************************************/
        if(buttonClicked.equals("SaveAddMoreDetails")){
			          //Diagnostic.println("----------------->ODOrgWarningCO processFormRequest. SaveAddMoreDetails event handling");
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
			          //Diagnostic.println("----------------->ODOrgWarningCO processFormRequest. ApplyCreateAnother event handling");
                //this.processTargetURL(pageContext,null,null);
                pageContext.forwardImmediately("ASN_ORGCREATEPG",
                    KEEP_MENU_CONTEXT ,
                    null,
                    params,
                    true,
                    ADD_BREAD_CRUMB_SAVE);
        }else if(buttonClicked.equals("Apply")){
				        //Diagnostic.println("----------------->ODOrgWarningCO processFormRequest. Apply event andling");
                if(pageContext.getParameter("ASNReqFromLOVPage") != null){
			            //Diagnostic.println("----------------->ODOrgWarningCO processFormRequest.ASNReqFromLOVPage = " + fromLOV);
			            pageContext.putParameter("ASNReqSelCustId", sPartyId);
                  pageContext.putParameter("ASNReqSelCustName", sPartyName);
                  HashMap conditions = new HashMap();
                  conditions.put(ASNUIConstants.RETAIN_AM, "Y");
                  pageContext.releaseRootApplicationModule();
                  this.processTargetURL(pageContext,conditions,null);
                }else{
                   this.processTargetURL(pageContext,null,null);
                }
        }
    }
    else if ((pageContext.getParameter("HzPuiEvent") != null) && (pageContext.getParameter("HzPuiEvent").equals("PARTYDETAIL")))
    {
        //Diagnostic.println("----------------->ODOrgWarningCO processFormRequest. Go to Org View page");
        //block the navigation if the user does not have even any access to the customer
        String custAccMode = this.checkAccessPrivilege(pageContext,
                                                     ASNUIConstants.CUSTOMER_ENTITY,
                                                     pageContext.getParameter("HzPuiPartyId"),
                                                     true);
        params.put("ASNReqFrmCustId", pageContext.getParameter("HzPuiPartyId"));
        params.put("ASNReqFrmCustName", pageContext.getParameter("HzPuiPartyName"));
        pageContext.putParameter("ASNReqPgAct","CUSTDET");
        HashMap conditions = new HashMap();
        if(!this.isSubFlow(pageContext)){
          conditions.put(ASNUIConstants.BC_CURRENT_LINK,ASNUIConstants.BC_CURRENT_LINK_REMOVE);
        }
        this.processTargetURL(pageContext,conditions,params);
    }
    else if(pageContext.getParameter("ASNPageCnclBtn") != null)
    {
        //Diagnostic.println("----------------->ODOrgWarningCO processFormRequest. Cancel Button clicked");
        if(pageContext.getParameter("ASNReqFromLOVPage") != null) {
	          //Diagnostic.println("----------------->ODOrgWarningCO processFormRequest.ASNReqFromLOVPage = " + fromLOV);
			      HashMap conditions = new HashMap();
            conditions.put(ASNUIConstants.RETAIN_AM, "Y");
            pageContext.releaseRootApplicationModule();
            this.processTargetURL(pageContext,conditions,null);
        }else {
           this.processTargetURL(pageContext,null,null);
        }
    }

	if (isProcLogEnabled) {
	  pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
	}


  }

   private void callAutoNamedApi(OAPageContext pageContext, OAWebBean webBean)
   {
        String s = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODOrgDeDupeCheckCO.callAutoNamedApi";
        boolean flag = pageContext.isLoggingEnabled(2);
        if(flag)
            pageContext.writeDiagnostics(s, "Begin", 2);
		String HzPuiCreatedPartySiteId = (String)pageContext.getTransactionTransientValue("HzPuiCreatedPartySiteId");
        pageContext.writeDiagnostics(s, "HzPuiCreatedPartySiteId : " +HzPuiCreatedPartySiteId , 2);

        String appDtsQry = "begin  XX_JTF_SALES_REP_PTY_SITE_CRTN.create_party_site(" + HzPuiCreatedPartySiteId +"); end; ";
		  OracleCallableStatement callableStatement = null;
		  Connection conn ;
		  OADBTransaction transaction =  pageContext.getApplicationModule(webBean).getOADBTransaction();

			try
			{
			  callableStatement = (OracleCallableStatement)transaction.createCallableStatement(appDtsQry,0);
			  callableStatement .execute();
			  doCommit(pageContext);
		  }
		  catch(SQLException e)
		  {
			  e.printStackTrace(System.err);
		  }
		  finally
		  {
			try {
			if(callableStatement!=null) callableStatement.close();
			}
			catch(SQLException e)
			{
			  e.printStackTrace(System.err);
			}
		  }
       if(flag)
            pageContext.writeDiagnostics(s, "End", 2);

	}

}

