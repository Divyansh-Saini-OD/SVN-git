/*===========================================================================+
 |   Copyright (c) 2001, 2003 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 |  06-Feb-2008     Anirban Chaudhuri      Modified for securing Party link  |
 |                                         on the UWQ details page.          | 
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.opportunity.webui;
//package oracle.apps.asn.opportunity.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.asn.common.fwk.webui.ASNControllerObjectImpl;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import java.io.Serializable;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;
import oracle.apps.fnd.framework.webui.OADataBoundValueViewObject;
import oracle.apps.fnd.framework.OAException;
import java.util.Hashtable;
import oracle.jbo.domain.Number;
import com.sun.java.util.collections.HashMap;
import oracle.apps.asn.common.fwk.webui.ASNUIConstants;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.asn.opportunity.webui.*;

/**
 * Controller for ...
 */
public class ODASNOpptyUwqDetCO extends ASNControllerObjectImpl
{
  public static final String RCS_ID="$Header: ODASNOpptyUwqDetCO.java 115.22 2005/02/17 20:50:51 pdelaney noship $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "xxcrm.oracle.apps.asn.opportunity.webui");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    final String METHOD_NAME = "asn.opportunity.webui.ASNOpptyDtlCO.processRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processRequest(pageContext, webBean);

    OAApplicationModule am = (OAApplicationModule) pageContext.getRootApplicationModule();
    OAApplicationModule queryAM = (OAApplicationModule)am.findApplicationModule("ASNOpptyQryAM");

    ////////////////////////////////////////////////////////////////////////////
    // ppr related UI programmatic change
    ///////////////////////////////////////////////////////////////
    // amount
    OAMessageStyledTextBean damtBean = (OAMessageStyledTextBean) webBean.findIndexedChildRecursive("ASNOpptyDetAmt");
    if(damtBean != null)
    {
      damtBean.setAttributeValue(CURRENCY_CODE,
       new OADataBoundValueViewObject(damtBean, "CurrencyCode"));
    }

    OAMessageTextInputBean famtBean = (OAMessageTextInputBean) webBean.findIndexedChildRecursive("ASNOpptyDetFrcstAmt");
    if(famtBean != null)
    {
      famtBean.setAttributeValue(CURRENCY_CODE,
        new OADataBoundValueViewObject(famtBean, "CurrencyCode"));
    }

    OAMessageChoiceBean opptyDetMethBean = (OAMessageChoiceBean) webBean.findIndexedChildRecursive("ASNOpptyDetMeth");
    if (opptyDetMethBean != null)
    {
      opptyDetMethBean.setAttributeValue(STYLE_CLASS_ATTR,
        new OADataBoundValueViewObject(opptyDetMethBean,"METH_CSS","OpptyUwqAppPropertiesVO1"));
    }

    OAMessageTextInputBean opptyDetFrcstBean = (OAMessageTextInputBean) webBean.findIndexedChildRecursive("ASNOpptyDetFrcstAmt");
    if (opptyDetFrcstBean != null)
    {
      opptyDetFrcstBean.setAttributeValue(STYLE_CLASS_ATTR,
        new OADataBoundValueViewObject(opptyDetFrcstBean,"FRCST_CSS","OpptyUwqAppPropertiesVO1"));
    }

    OAHeaderBean headerBean = (OAHeaderBean) webBean.findIndexedChildRecursive("ASNOpptyUwqDetRN");
    if(headerBean != null)
    {
      headerBean.setAttributeValue(this.TEXT_ATTR,
        new OADataBoundValueViewObject(headerBean,"OPP_TITLE","OpptyUwqAppPropertiesVO1"));
    }
    String opptyId = (String)pageContext.getSessionValue("ASNSsnUWQOpptyId");
    if(opptyId == null)
    {
      String ssnOpptyId = (String)pageContext.getParameter("ASNReqOpptyId");
      if (ssnOpptyId == null)
      {
        ssnOpptyId = (String) queryAM.invokeMethod("getSelectedOpptyId");
      }
      Serializable[] params = {ssnOpptyId};
      opptyId = (String) queryAM.invokeMethod("getCurrentRow", params);
    }

    /********  Perform the oppty access check *********/
    boolean isNoAccess = true;
    boolean isReadAccess = false;

    String opptyAcsMode = ASNUIConstants.NO_ACCESS;
    if(opptyId!=null)
    {
      opptyAcsMode = this.checkAccessPrivilege(pageContext,
                                              ASNUIConstants.OPPORTUNITY_ENTITY,
                                              opptyId,
                                              false);
    }
    if(opptyAcsMode!=null)
      pageContext.putTransactionValue("ASNTxnOpptyAcsMd", opptyAcsMode);
    else
      pageContext.removeTransactionValue("ASNTxnOpptyAcsMd");

    isReadAccess = ASNUIConstants.READ_ACCESS.equals(opptyAcsMode);
    if(opptyAcsMode!=null && ( isReadAccess ||ASNUIConstants.UPDATE_ACCESS.equals(opptyAcsMode)))
    {
      isNoAccess = false;
    }


    String resourceId = (String) getLoginResourceId(queryAM, pageContext);
    String isManagerFlag = isLoginResourceManager(queryAM, pageContext)?"Y":"N";
    Serializable aparams[] = { resourceId, isManagerFlag, opptyId, (isReadAccess?"Y":"N") };
    if (isStatLogEnabled)
    {
      StringBuffer buf = new StringBuffer(100);
      buf.append("call to setRow");
      buf.append("resourceId = ");
      buf.append(resourceId);
      buf.append("isManagerFlag = ");
      buf.append(isManagerFlag);
      buf.append("isReadAccess = ");
      buf.append(isReadAccess);
      pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
    }
    am.invokeMethod("setRow", aparams);
    if(opptyId != null)
    {

    // Change the page UI here.
    /////////////////////////////////////////////////////////////////////////////
    //close reason display

      OAMessageChoiceBean closeReason = (OAMessageChoiceBean) webBean.findIndexedChildRecursive("ASNOpptyDetRsn");
      OAMessageChoiceBean statusBn = (OAMessageChoiceBean) webBean.findIndexedChildRecursive("ASNOpptyDetStatus");
      if(closeReason != null && statusBn != null)
      {
        if(statusBn.isRendered())
        {
          closeReason.setRendered(true);
        }
      }



    /////////////////////////////////////////////////////////////////////////////
    // Run init query
    /////////////////////////////////////////////////////////////////////////////
    // common parameters

    String pageEvent = pageContext.getParameter("ASNReqPgAct");

    if (isStatLogEnabled)
    {
      StringBuffer buf = new StringBuffer(100);
      buf.append("Page Event = ");
      buf.append(pageEvent);
      pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
    }

    Serializable [] ssparams = {""};
    if (isStatLogEnabled)
    {
      StringBuffer buf = new StringBuffer(100);
      buf.append("Call to handleSrchMethUpdateEvent ");
      buf.append("paramaters = ");
      buf.append(ssparams);
      pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
    }

      // set required parameters for Notes region
      /////////////////////////////////////////////////////////////
      Hashtable ht = (Hashtable) am.invokeMethod("getOpptyAttributes");
      Number leadId = (Number) ht.get("LeadId");
      if(leadId == null)
      {
        throw new OAException("ASN","ASN_CMMN_REQKEY_MISS_ERR");
      }
      Number customerId = (Number) ht.get("CustomerId");
      Number relPtyId = (Number) ht.get("RelationshipPartyId");

      if(customerId == null)
      {
        throw new OAException("ASN","ASN_CMMN_REQKEY_MISS_ERR");
      }

      String secFlag = checkAccessPrivilege(pageContext,
                        ASNUIConstants.OPPORTUNITY_ENTITY,leadId.toString(),false);
      String custSecFlag = checkAccessPrivilege(pageContext,
                            ASNUIConstants.CUSTOMER_ENTITY,
                            customerId.toString(),false);

      // note
      pageContext.putTransactionValue("ASNTxnNoteSourceCode","OPPORTUNITY");
      pageContext.putTransactionValue("ASNTxnNoteSourceId",leadId.toString());

      String lookupParam = "ASN_OPPTY_VIEW_NOTES;0";
      pageContext.putTransactionValue("ASNTxnNoteLookup",lookupParam);

      String poplistParamList = "CUSTOMER;"+customerId.toString();
      pageContext.putTransactionValue("ASNTxnNoteParamList",poplistParamList);

      String poplistTypeList = "CUSTOMER;PARTY";
      pageContext.putTransactionValue("ASNTxnNoteTypeList",poplistTypeList);

      if(!ASNUIConstants.UPDATE_ACCESS.equals(secFlag))
      {
        pageContext.putTransactionValue("ASNTxnNoteReadOnly","Y");
      }
      else
      {
        pageContext.putTransactionValue("ASNTxnNoteReadOnly","N");
      }
      if(ASNUIConstants.UPDATE_ACCESS.equals(custSecFlag))
      {
        pageContext.putTransactionValue("ASNTxnCustNoteReadOnly", "N");
        String poplistROList = "CUSTOMER;N";
        pageContext.putTransactionValue("ASNTxnNoteReadOnlyList",poplistROList);
      }
      else if(ASNUIConstants.READ_ACCESS.equals(custSecFlag))
      {
        pageContext.putTransactionValue("ASNTxnCustNoteReadOnly", "Y");
        String poplistROList = "CUSTOMER;Y";
        pageContext.putTransactionValue("ASNTxnNoteReadOnlyList",poplistROList);
      }
      else
      {
        pageContext.putTransactionValue("ASNTxnCustNoteReadOnly", "X");
        String poplistROList = "CUSTOMER;X";
        pageContext.putTransactionValue("ASNTxnNoteReadOnlyList",poplistROList);
      }

      /******* Task Integration ******/
      pageContext.putTransactionValue("cacTaskSrcObjCode","OPPORTUNITY");
      pageContext.putTransactionValue("cacTaskSrcObjId",leadId.toString());
      pageContext.putTransactionValue("cacTaskCustId",customerId.toString());
      /** Sending task addressid
	  		 String sql1 = "select address_id from as_leads_all where lead_id = :1";
	  		 OAApplicationModule oamaddr = pageContext.getRootApplicationModule();
	  		 oracle.jbo.ViewObject pSitevo2 = oamaddr.findViewObject("pSiteVO2");
	  		             if (pSitevo2 == null )
	  		             {
	  		               pSitevo2 = oamaddr.createViewObjectFromQueryStmt("pSiteVO2", sql1);
	  		             }

	  		             if (pSitevo2 != null)
	  		             {
	  		                 pSitevo2.setWhereClauseParams(null);
	  		                 pSitevo2.setWhereClauseParam(0,leadId);
	  		                 pSitevo2.executeQuery();
	  		                 pSitevo2.first();
	  		                 String Addressid = pSitevo2.getCurrentRow().getAttribute(0).toString();
	  		                 pSitevo2.remove();
	  		                 pageContext.putTransactionValue("cacTaskCustAddressId", Addressid);
                    }**/
      if(ASNUIConstants.READ_ACCESS.equals(secFlag))
      {
        pageContext.putTransactionValue("cacTaskTableRO","Y");
        pageContext.putTransactionValue("cacTaskReadOnlyPPR","Y");
      }
      else
      {
        pageContext.putTransactionValue("cacTaskTableRO","N");
        pageContext.putTransactionValue("cacTaskReadOnlyPPR","N");
      }
      if(relPtyId != null)
      {
        pageContext.putTransactionValue("cacTaskContactId",relPtyId.toString());
      }
      else
      {
        pageContext.putTransactionValue("cacTaskContactId","");
      }
      pageContext.putTransactionValue("cacTaskContDqmRule",(String) pageContext.getProfile("HZ_DQM_CON_SIMPLE_MATCHRULE"));
      pageContext.putTransactionValue("cacTaskNoDelDlg","Y");

      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(100);
        buf.append("Opportunity Id = ");
        buf.append(opptyId);
        buf.append("Login Resource Id = ");
        buf.append(resourceId);
        buf.append("Is Resource a Manager = ");
        buf.append(isManagerFlag);
        buf.append("Lead Id = ");
        buf.append(leadId);
        buf.append("Customer Id = ");
        buf.append(customerId);
        buf.append("Relationship Id = ");
        buf.append(relPtyId);
        buf.append("Access to Opportunity = ");
        buf.append(secFlag);
        buf.append("Access to Customer = ");
        buf.append(custSecFlag);
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      }

    }
    else
    {
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(100);
        buf.append("Opportunity Id is null ");
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      }


    }

    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }

  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    final String METHOD_NAME = "asn.opportunity.webui.OpptyUwqDetCO.processRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);

    super.processFormRequest(pageContext, webBean);
    OAApplicationModule am = (OAApplicationModule) pageContext.getRootApplicationModule();
    OAApplicationModule queryAM = (OAApplicationModule)am.findApplicationModule("ASNOpptyQryAM");
    String pageEvent = pageContext.getParameter("ASNReqPgAct");
    //change radio button
    if("OPPTYRDOBTNCHG".equals(pageEvent))
	  {
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(100);
        buf.append("event = ");
        buf.append(pageEvent);
        buf.append("call to  handleHeaderFrcstUpdateEvent ");
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      }
    }

    String ssnOpptyId = (String)pageContext.getParameter("ASNReqOpptyId");
    if(ssnOpptyId == null)
    {
      String opptyId = (String)pageContext.getParameter("ASNReqOpptyId");
      if (opptyId == null)
      {
        opptyId = (String) queryAM.invokeMethod("getSelectedOpptyId");
      }
      Serializable[] params = {opptyId};
      ssnOpptyId = (String) queryAM.invokeMethod("getCurrentRow", params);
    }

    if("Y".equals(pageContext.getParameter("ASNReqNewSelectionFlag")))
    {
      String opptyId = (String) ssnOpptyId;
      //set access
      boolean isNoAccess = true;
      boolean isReadAccess = false;
      String opptyAcsMode = ASNUIConstants.NO_ACCESS;

    	opptyAcsMode = checkAccessPrivilege(pageContext,
                                          ASNUIConstants.OPPORTUNITY_ENTITY,
                                          opptyId,
                                          false);
      isReadAccess = ASNUIConstants.READ_ACCESS.equals(opptyAcsMode);
      if(opptyAcsMode!=null && ( isReadAccess || ASNUIConstants.UPDATE_ACCESS.equals(opptyAcsMode)))
      {
        isNoAccess = false;
      }

      String resourceId = (String) getLoginResourceId(queryAM, pageContext);
      String isManagerFlag = isLoginResourceManager(queryAM, pageContext)?"Y":"N";
      Serializable aparams[] = { resourceId, isManagerFlag, opptyId,  (isReadAccess?"Y":"N")  };

      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(100);
        buf.append("call to setRow");
        buf.append("resourceId = ");
        buf.append(resourceId);
        buf.append("isManagerFlag = ");
        buf.append(isManagerFlag);
        buf.append("isReadAccess = ");
        buf.append(isReadAccess);
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      }
      am.invokeMethod("setRow", aparams);

      Hashtable ht = (Hashtable) am.invokeMethod("getOpptyAttributes");
      Number leadId = (Number) ht.get("LeadId");

      String leadIdStr = pageContext.getOANLSServices().NumberToString(leadId);

      if(leadId == null)
      {
        throw new OAException("ASN","ASN_CMMN_REQKEY_MISS_ERR");
      }

      Number customerId = (Number) ht.get("CustomerId");
      Number relPtyId = (Number) ht.get("RelationshipPartyId");

      String secFlag = checkAccessPrivilege(pageContext,
                        ASNUIConstants.OPPORTUNITY_ENTITY,leadId.toString(),false);
      String custSecFlag = checkAccessPrivilege(pageContext,
                            ASNUIConstants.CUSTOMER_ENTITY,
                            customerId.toString(),false);

      if(customerId == null)
      {
        throw new OAException("ASN","ASN_CMMN_REQKEY_MISS_ERR");
      }

      // note integration
      //////////////////////////////////
      pageContext.putTransactionValue("ASNTxnNoteSourceCode","OPPORTUNITY");
      pageContext.putTransactionValue("ASNTxnNoteSourceId",leadId.toString());

      String poplistParamList = "CUSTOMER;"+customerId.toString();
      pageContext.putTransactionValue("ASNTxnNoteParamList",poplistParamList);

      String poplistTypeList = "CUSTOMER;PARTY";
      pageContext.putTransactionValue("ASNTxnNoteTypeList",poplistTypeList);


      if(!ASNUIConstants.UPDATE_ACCESS.equals(secFlag))
      {
        if (isStatLogEnabled)
        {
          StringBuffer buf = new StringBuffer(100);
          buf.append("ASNTxnNoteReadOnly = Y");
          pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
        }
        pageContext.putTransactionValue("ASNTxnNoteReadOnly","Y");
      }
      else
      {
        if (isStatLogEnabled)
        {
          StringBuffer buf = new StringBuffer(100);
          buf.append("ASNTxnNoteReadOnly = N");
          pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
        }
        pageContext.putTransactionValue("ASNTxnNoteReadOnly","N");
      }
      if(ASNUIConstants.UPDATE_ACCESS.equals(custSecFlag))
      {
        pageContext.putTransactionValue("ASNTxnCustNoteReadOnly", "N");
        String poplistROList = "CUSTOMER;N";
        pageContext.putTransactionValue("ASNTxnNoteReadOnlyList",poplistROList);
      }
      else if(ASNUIConstants.READ_ACCESS.equals(custSecFlag))
      {
        pageContext.putTransactionValue("ASNTxnCustNoteReadOnly", "Y");
        String poplistROList = "CUSTOMER;Y";
        pageContext.putTransactionValue("ASNTxnNoteReadOnlyList",poplistROList);
      }
      else
      {
        pageContext.putTransactionValue("ASNTxnCustNoteReadOnly", "X");
        String poplistROList = "CUSTOMER;X";
        pageContext.putTransactionValue("ASNTxnNoteReadOnlyList",poplistROList);
      }
      pageContext.putParameter("ASNReqNotePPREventFlag","Y");
      String lookupParam = "ASN_OPPTY_VIEW_NOTES;0";
      pageContext.putTransactionValue("ASNTxnNoteLookup",lookupParam);

      //task integration
      /////////////////////////////////
      pageContext.putTransactionValue("cacTaskSrcObjCode","OPPORTUNITY");
      pageContext.putTransactionValue("cacTaskSrcObjId",leadId.toString());

      pageContext.putTransactionValue("cacTaskCustId",customerId.toString());
      /** Sending task addressid **/
	  	  		 String sql1 = "select address_id from as_leads_all where lead_id = :1";
	  	  		 OAApplicationModule oamaddr = pageContext.getRootApplicationModule();
	  	  		 oracle.jbo.ViewObject pSitevo2 = oamaddr.findViewObject("pSiteVO2");
	  	  		             if (pSitevo2 == null )
	  	  		             {
	  	  		               pSitevo2 = oamaddr.createViewObjectFromQueryStmt("pSiteVO2", sql1);
	  	  		             }

	  	  		             if (pSitevo2 != null)
	  	  		             {
	  	  		                 pSitevo2.setWhereClauseParams(null);
	  	  		                 pSitevo2.setWhereClauseParam(0,leadId);
	  	  		                 pSitevo2.executeQuery();
	  	  		                 pSitevo2.first();
	  	  		                 String Addressid = pSitevo2.getCurrentRow().getAttribute(0).toString();
	  	  		                 pSitevo2.remove();
	  	  		                 pageContext.putTransactionValue("cacTaskCustAddressId", Addressid);
	                      }

      if(relPtyId != null)
      {
        pageContext.putTransactionValue("cacTaskContactId",relPtyId.toString());
      }
      else
      {
        pageContext.putTransactionValue("cacTaskContactId","");
      }

      OAApplicationModule tam = (OAApplicationModule)am.findApplicationModule("CacTaskSummAM");
      if(tam != null)
      {
        if (isStatLogEnabled)
        {
          StringBuffer buf = new StringBuffer(100);
          buf.append("taskAM call to  resetQuery");
          pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
        }
        tam.invokeMethod("resetQuery");
        Serializable [] tparams = {"OPPORTUNITY",leadId.toString()};
        if (isStatLogEnabled)
        {
          StringBuffer buf = new StringBuffer(100);
          buf.append("taskAM call to initTaskSummQuery");
          pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
        }
        tam.invokeMethod("initTaskSummQuery",tparams);
        if(!ASNUIConstants.UPDATE_ACCESS.equals(secFlag))
        {
          pageContext.putTransactionValue("cacTaskTableRO","Y");
          pageContext.putTransactionValue("cacTaskReadOnlyPPR","Y");
        }
        else
        {
          pageContext.putTransactionValue("cacTaskTableRO","N");
          pageContext.putTransactionValue("cacTaskReadOnlyPPR","N");
        }
      }
    }
    else
    {
      Serializable[] params = {ssnOpptyId};

      String opptyId = (String) queryAM.invokeMethod("getCurrentRow", params);
      //don't render detials region if no rows selected.
      if(opptyId==null)
      {
        //set access
        boolean isReadAccess = false;

        String resourceId = (String) getLoginResourceId(queryAM, pageContext);
        String isManagerFlag = isLoginResourceManager(queryAM, pageContext)?"Y":"N";
        Serializable aparams[] = { resourceId, isManagerFlag, opptyId,  (isReadAccess?"Y":"N")  };

        if (isStatLogEnabled)
        {
          StringBuffer buf = new StringBuffer(100);
          buf.append("call to setRow");
          buf.append("resourceId = ");
          buf.append(resourceId);
          buf.append("isManagerFlag = ");
          buf.append(isManagerFlag);
          buf.append("isReadAccess = ");
          buf.append(isReadAccess);
          pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
        }
        am.invokeMethod("setRow", aparams);
      }
    }

    String event = pageContext.getParameter(EVENT_PARAM);

    if ("detailMethUpdate".equals(event))
    {
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(100);
        buf.append("event = ");
        buf.append(event);
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      }
      am.invokeMethod("handleDetailMethUpdateEvent");
    }

    if("detailStatusUpdate".equals(event))
    {
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(100);
        buf.append("event = ");
        buf.append(event);
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      }
      am.invokeMethod("handleDetailStatusUpdateEvent");
    }



    /*
     * Handle main event here.
     * i.e. Event that forwards to other detail page
     */


    if("CSCHDET".equals(pageEvent))
    {
      String cschId = pageContext.getParameter("ASNReqEvtCschId");
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(100);
        buf.append("event = ");
        buf.append(event);
        buf.append("cschId = ");
        buf.append(cschId);
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      }
      if(cschId!=null && !("".equals(cschId.trim())))
      {
        pageContext.putSessionValue("ASNSsnUWQOpptyId", ssnOpptyId);

        HashMap prpParams = new HashMap(1);
        prpParams.put("objId",cschId);
        processTargetURL(pageContext, null, prpParams);
      }
    }

   // customer detail link clicked
   // Anirban starts securing party name link
    if("CUSTDET".equals(pageEvent))
    {
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(100);
        buf.append("event = ");
        buf.append(event);
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      }
      pageContext.putSessionValue("ASNSsnUWQOpptyId", ssnOpptyId);

      HashMap urlParams = this.getFrmParamsFromEvtParams(pageContext);
      //processTargetURL(pageContext,null, urlParams);

      HashMap hashmap = new HashMap();
	  hashmap.put("ASNReqFrmCustId", pageContext.getParameter("ASNReqEvtCustId"));
      hashmap.put("ASNReqFrmFuncName", "ASN_ORGVIEWPG");
      pageContext.putParameter("ASNReqPgAct", "CUSTDET");
	  boolean flag50 = false;
	  pageContext.forwardImmediately("ASN_ORGVIEWPG", OAWebBeanConstants.KEEP_MENU_CONTEXT, null, hashmap, flag50, "Y");

    }
    // Anirban ends securing party name link

    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }

  }

}
