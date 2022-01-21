/*===========================================================================+
 |   Copyright (c) 2001, 2003 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.lead.webui;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import java.io.Serializable;

import oracle.apps.asn.common.fwk.webui.ASNControllerObjectImpl;
import oracle.apps.asn.common.fwk.webui.ASNUIConstants;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.OADataBoundValueViewObject;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAFormattedTextBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.apps.asn.lead.webui.*;

/**
 * Controller for ...
 */
public class ODASNLeadUwqDetCO extends ASNControllerObjectImpl
{
  public static final String RCS_ID="$Header: ODASNLeadUwqDetCO.java 115.16 2005/02/18 17:50:11 asahoo noship $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "od.oracle.apps.xxcrm.asn.lead.webui");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    final String METHOD_NAME = "xxcrm.asn.lead.webui.ODASNLeadUwqDetCO.processRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processRequest(pageContext, webBean);

    /********  Get Page layout and Application module   *********/
    OAApplicationModule oam = pageContext.getApplicationModule(webBean);
    OAPageLayoutBean pgLayout = pageContext.getPageLayoutBean();

    /********  Get page context information   *********/
    boolean queryDetails = "Y".equals(pageContext.getParameter("ASNReqNewSelectionFlag"));
    boolean isNoAccess = true;
    boolean isReadAccess = false;

    /*****  Dummy initialization for Notes    *******/
     if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(100);
        buf.append("Dummy initialization for Notes Begin");
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      }

    pageContext.putTransactionValue("ASNTxnNoteSourceCode","LEAD");
    pageContext.putTransactionValue("ASNTxnNoteSourceId","-1");

    String lookupParam = "ASN_LEAD_VIEW_NOTES;0";
    pageContext.putTransactionValue("ASNTxnNoteLookup",lookupParam);

    String poplistParamList = "CUSTOMER;-1";
    pageContext.putTransactionValue("ASNTxnNoteParamList",poplistParamList);

    String poplistTypeList = "CUSTOMER;PARTY";
    pageContext.putTransactionValue("ASNTxnNoteTypeList",poplistTypeList);

    String poplistROList = "CUSTOMER;N";
    pageContext.putTransactionValue("ASNTxnNoteReadOnlyList",poplistROList);

     if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(100);
        buf.append("Dummy initialization for Notes End");
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      }

    /*****  Dummy initialization for tasks    *******/
     if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(100);
        buf.append("Dummy initialization for Tasks Begin");
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      }
    pageContext.putTransactionValue("cacTaskSrcObjCode","LEAD");
    pageContext.putTransactionValue("cacTaskSrcObjId","-1");
    pageContext.putTransactionValue("cacTaskCustId","-1");
    pageContext.putTransactionValue("cacTaskContactId","-1");
    pageContext.putTransactionValue("cacTaskCustAddressId","-1");
    pageContext.putTransactionValue("cacTaskContDqmRule",(String)pageContext.getProfile("HZ_DQM_CON_SIMPLE_MATCHRULE"));
    pageContext.putTransactionValue("cacTaskNoDelDlg","Y");

     if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(100);
        buf.append("Dummy initialization for Tasks End");
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      }

    /********  Identify the selected row *********/
    String leadId = (String)pageContext.getSessionValue("ASNSsnUwqLeadId");
    if(leadId == null)
    {
      leadId = pageContext.getParameter("ASNReqLeadId");
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(100);
        buf.append(" leadId = ");
        buf.append(leadId);
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      }
    }


    /********  Perform the lead access check *********/
    String leadAcsMode = ASNUIConstants.NO_ACCESS;
    if(leadId!=null)
    {
      leadAcsMode = this.checkAccessPrivilege(pageContext,
                                              ASNUIConstants.LEAD_ENTITY,
                                              leadId,
                                              false);
    }
    if(leadAcsMode!=null)
      pageContext.putTransactionValue("ASNTxnLeadAcsMd", leadAcsMode);
    else
      pageContext.removeTransactionValue("ASNTxnLeadAcsMd");

    isReadAccess = ASNUIConstants.READ_ACCESS.equals(leadAcsMode);
    if(leadAcsMode!=null && ( isReadAccess ||
                              ASNUIConstants.UPDATE_ACCESS.equals(leadAcsMode)))
    {
      isNoAccess = false;
    }

     if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(200);
        buf.append(" leadAcsMode = ");
        buf.append(leadAcsMode);
        buf.append(" isReadAccess = ");
        buf.append(isReadAccess);
        buf.append(" isNoAccess = ");
        buf.append(isNoAccess);
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      }

     /********  Modify the Detail Region properties   *********/
      OAHeaderBean detailRn = (OAHeaderBean)pgLayout.findIndexedChildRecursive("ASNLeadDetHdrRN");
      if(detailRn!=null)
      {
        /*** bind the region title to properties view attribute ***/
        detailRn.setAttributeValue(OAWebBeanConstants.TEXT_ATTR,
              new OADataBoundValueViewObject(detailRn,"UWQ_DET_TITLE","LeadUwqAppPropertiesVO"));

        /**** Setting the Formatted Text for Currency Code ****/
        OAFormattedTextBean fmtdCurrNmBean = (OAFormattedTextBean)pgLayout.findIndexedChildRecursive("ASNLeadDetCurrNm");
        if(fmtdCurrNmBean!=null)
        {
          fmtdCurrNmBean.setAttributeValue(OAWebBeanConstants.TEXT_ATTR,
              new OADataBoundValueViewObject(fmtdCurrNmBean,"UWQ_DET_CURRENCY","LeadUwqAppPropertiesVO"));
          fmtdCurrNmBean.setCSSClass("OraPageStampText");
         }

        /*** bind the input fields CSS class to properties view attribute ***/
        String[] inputFldNms = new String[]
                                     { "ASNLeadDetStatus", "ASNLeadDetRank",
                                       "ASNLeadDetLeadName", "ASNLeadDetRespChan",
                                       "ASNLeadDetSrcNm"};
        OAWebBean inputFldBn = null;
        for(int i=0; i<inputFldNms.length; i++)
        {
          inputFldBn = detailRn.findIndexedChildRecursive(inputFldNms[i]);
          if(inputFldBn!=null)
          {
            inputFldBn.setAttributeValue(STYLE_CLASS_ATTR,
                      new OADataBoundValueViewObject(inputFldBn,"FIELD_CSS","LeadUwqAppPropertiesVO"));
          }
        }

        inputFldNms = new String[]
                            {
                              "ASNLeadDetCtctFirstNm", "ASNLeadDetCtctLastNm",
                              "ASNLeadDetJob", "ASNLeadDetPhonCntryCd",
                              "ASNLeadDetPhonAreaCd", "ASNLeadDetPhonNbr",
                              "ASNLeadDetPhonExt"
                            };
        for(int i=0; i<inputFldNms.length; i++)
        {
          inputFldBn = detailRn.findIndexedChildRecursive(inputFldNms[i]);
          if(inputFldBn!=null)
          {
            inputFldBn.setAttributeValue(STYLE_CLASS_ATTR,
                      new OADataBoundValueViewObject(inputFldBn,"CTCT_FLDS_CSS","LeadUwqAppPropertiesVO"));
          }
        }

        inputFldBn = pgLayout.findIndexedChildRecursive("ASNLeadDetRsn");
        if(inputFldBn!=null)
        {
          inputFldBn.setAttributeValue(STYLE_CLASS_ATTR,
                        new OADataBoundValueViewObject(inputFldBn,"CLSRSN_CSS","LeadUwqAppPropertiesVO"));
        }

        /*** Product Amount Formatting  ***/
        OATableBean prdtLstBean = (OATableBean)webBean.findIndexedChildRecursive("ASNLeadDetPrdtLstRN");
        if(prdtLstBean!=null)
        {
          OAWebBean prdtAmtBean = prdtLstBean.findIndexedChildRecursive("ASNLeadDetPrdtAmt");
          if(prdtAmtBean!=null)
          {
            prdtAmtBean.setAttributeValue(OAWebBeanConstants.CURRENCY_CODE,
                                          new OADataBoundValueViewObject(prdtAmtBean,
                                                "CurrencyCode","LeadDetailsVO"));
          }
        }


        /**** Format the Budget Amount based on the Currency Code ****/
        OAWebBean budgetAmtBean = pgLayout.findIndexedChildRecursive("ASNLeadDetBudgetAmt");
        if(budgetAmtBean!=null)
        {
          budgetAmtBean.setAttributeValue(OAWebBeanConstants.CURRENCY_CODE, new OADataBoundValueViewObject(budgetAmtBean, "CurrencyCode","LeadDetailsVO"));
        }

          /**** Always display close reason if status is displayed  ****/
        OAWebBean clsReasonBean = detailRn.findIndexedChildRecursive("ASNLeadDetRsn");
        OAWebBean stsBean = detailRn.findIndexedChildRecursive("ASNLeadDetStatus");
        if(clsReasonBean!=null && stsBean!=null)
        {
          if(stsBean.isRendered())
          {
            clsReasonBean.setRendered(true);
          }
        }
    } // end of detailRN


    if(queryDetails)
     {
       oam.invokeMethod("resetQuery", new Serializable[]{"LeadDetailsVO"});
     }

    HashMap leadInfo = null;
    if(leadId!=null)
    {
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(200);
        buf.append(" leadId = ");
        buf.append(leadId);
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      }

      Serializable params[] = {"LeadDetailsVO", leadId};
      leadInfo = (HashMap)oam.invokeMethod("getLeadInfo", params);
    }

    /********  Set the UI attributes  ********/
    oam.invokeMethod("setLeadUwqProperties", new Serializable[]{leadAcsMode});

     /********  Load the lead details *********/
    if(leadId!=null)
    {
      if(isNoAccess)
      {
        String errToken = pageContext.getMessage("ASN", "ASN_CMMN_LEAD", null);
        MessageToken[] tokens = { new MessageToken("OBJECTNAME", errToken) };
        throw new OAException("ASN", "ASN_CMMN_NO_ACSS_ERR", tokens);
      }

      /******** Get the Lead Details *********/
      String leadName   = (String)leadInfo.get("Description");
      String leadStsCd  = (String)leadInfo.get("StatusCode");
      String customerId = (String)leadInfo.get("CustomerId");
      String contactId  = (String)leadInfo.get("PrimaryContactPartyId");

      /********  Perform the customer access check *********/
      String custAcsMode = this.checkAccessPrivilege(pageContext,
                                                     ASNUIConstants.CUSTOMER_ENTITY,
                                                     customerId,
                                                     false,
                                                     false
                                                    );
      String custType = this.getCustomerType(pageContext, customerId);

      if(custAcsMode!=null)
        pageContext.putTransactionValue("ASNTxnCustAcsMd", custAcsMode);
      else
        pageContext.removeTransactionValue("ASNTxnCustAcsMd");

      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(300);
        buf.append(" leadStsCd = ");
        buf.append(leadStsCd);
        buf.append(" customerId = ");
        buf.append(customerId);
        buf.append(" contactId = ");
        buf.append(contactId);
        buf.append(" custAcsMode = ");
        buf.append(custAcsMode);
        buf.append(" custType = ");
        buf.append(custType);
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      }

      /** Handle primary contact selection **/
      String selRelPtyId = pageContext.getParameter("ASNReqSelRelPtyId");
      if(selRelPtyId!=null && !("".equals(selRelPtyId.trim())))
      {
          if (isStatLogEnabled)
          {
           StringBuffer buf = new StringBuffer(300);
           buf.append(" selRelPtyId = ");
           buf.append(selRelPtyId);
           pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
          }

          Serializable[] ctctParams = {selRelPtyId};
          oam.invokeMethod("setPrimaryLeadContact", ctctParams);
          oam.invokeMethod("getPrimaryLeadContact");
      }

      /********  Set the Customer related UI attributes  ********/
      oam.invokeMethod("setLeadUwqCustProperties", new Serializable[]{custAcsMode, custType});

      /*** lead will be read-only if the user does not have update access or the
           lead status is converted to opportunity  ***/
      if("CONVERTED_TO_OPPORTUNITY".equals(leadStsCd))
      {
          isReadAccess = true;
      }

      setLeadRegionParameters (pageContext,leadInfo,isReadAccess, custAcsMode, false, webBean);
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
    final String METHOD_NAME = "xxcrm.asn.lead.webui.ODASNLeadUwqDetCO.processFormRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

      super.processFormRequest(pageContext, webBean);

      /********  Get the Application module   *********/
      OAApplicationModule oam = pageContext.getRootApplicationModule();
      OAApplicationModule queryAM = (OAApplicationModule)oam.findApplicationModule("ASNLeadQryAM");
      OAPageLayoutBean pgLayout = pageContext.getPageLayoutBean();

    	/* set the access privileges of the current lead & customer in the page context */
	    String leadAcsMode = (String)pageContext.getTransactionValue("ASNTxnLeadAcsMd");
	    String custAcsMode = (String)pageContext.getTransactionValue("ASNTxnCustAcsMd");

	    if(leadAcsMode!=null)
	       pageContext.putParameter("ASNReqFrmLeadAcsMd", leadAcsMode);

	    if(custAcsMode!=null)
	       pageContext.putParameter("ASNReqFrmCustAcsMd", custAcsMode);

      boolean isUpdateAccess = ASNUIConstants.UPDATE_ACCESS.equals(leadAcsMode);

	    String asnEvt = pageContext.getParameter("ASNReqPgAct");

      String leadId = (String)oam.invokeMethod("getLeadId", new Serializable[]{"LeadDetailsVO"});

      if (isStatLogEnabled)
          {
           StringBuffer buf = new StringBuffer(300);
           buf.append(" leadAcsMode = ");
           buf.append(leadAcsMode);
           buf.append(" custAcsMode = ");
           buf.append(custAcsMode);
           buf.append(" asnEvt = ");
           buf.append(asnEvt);
           buf.append(" leadId = ");
           buf.append(leadId);
           pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
          }

      if("LEADRDOBTNCHG".equals(asnEvt))
	    {
	      if(isUpdateAccess)
	      {
	        // refresh the corresponding row on the master list table
          ArrayList leadrenderedVwAttrs = (ArrayList) pageContext.getTransactionTransientValue("ASNTxnLeadrenderedVwAttrs");
          Serializable params[] = {leadId, leadrenderedVwAttrs};
          Class[] classDef = { String.class, ArrayList.class};
          if (isStatLogEnabled)
          {
           StringBuffer buf = new StringBuffer(300);
           buf.append(" asnEvt = LEADRDOBTNCHG ");
           buf.append(" refreshLeadUwqRow method is called");
           pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
          }
	        queryAM.invokeMethod("refreshLeadUwqRow", params, classDef);
	      }
	    }

      if("Y".equals(pageContext.getParameter("ASNReqNewSelectionFlag")))
	    {
         boolean isNoAccess = true;
         boolean isReadAccess = false;
		     // get the lead id
	       leadId = (String)pageContext.getParameter("ASNReqLeadId");
		     // get the user access privilege on the lead
	       leadAcsMode = checkAccessPrivilege(pageContext,
                                            ASNUIConstants.LEAD_ENTITY,
                                            leadId,
                                            false,
                                            false);
         isReadAccess = ASNUIConstants.READ_ACCESS.equals(leadAcsMode);
         if(leadAcsMode!=null && ( isReadAccess || ASNUIConstants.UPDATE_ACCESS.equals(leadAcsMode)))
         {
          isNoAccess = false;
         }

         if (isStatLogEnabled)
         {
           StringBuffer buf = new StringBuffer(100);
           buf.append("ASNReqNewSelectionFlag = Y ");
           buf.append(" leadId = ");
           buf.append(leadId);
           buf.append(" leadAcsMode = ");
           buf.append(leadAcsMode);
           pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
         }

         HashMap leadInfo = new HashMap(10);
         if (leadId!=null)
          {
            Serializable params[] = {"LeadDetailsVO", leadId};
	          leadInfo  = (HashMap)oam.invokeMethod("getLeadInfo", params);
          }

		     // set the UI SPEL attributes
	       oam.invokeMethod("setLeadUwqProperties", new Serializable[]{leadAcsMode});
		     // load the lead details
	       if(leadId!=null)
	        {
	         if(isNoAccess)
	          {
	            String errToken = pageContext.getMessage("ASN", "ASN_CMMN_LEAD", null);
              MessageToken[] tokens = { new MessageToken("OBJECTNAME", errToken) };
              throw new OAException("ASN", "ASN_CMMN_NO_ACSS_ERR", tokens);
	          }
	          // get the lead details


            String leadName   = (String)leadInfo.get("Description");
            String leadStsCd  = (String)leadInfo.get("StatusCode");
            String customerId = (String)leadInfo.get("CustomerId");
            String contactId  = (String)leadInfo.get("PrimaryContactPartyId");

		        // get the user access privilege on the lead
	          custAcsMode = checkAccessPrivilege(pageContext,
	                                             ASNUIConstants.CUSTOMER_ENTITY,
                                               customerId,
                                               false,
                                               false);
		        // get the type of the customer
	          String custType = getCustomerType(pageContext, customerId);

            if (isStatLogEnabled)
            {
             StringBuffer buf = new StringBuffer(300);
              buf.append(" leadStsCd = ");
              buf.append(leadStsCd);
              buf.append(" customerId = ");
              buf.append(customerId);
              buf.append(" contactId = ");
              buf.append(contactId);
              buf.append(" custAcsMode = ");
              buf.append(custAcsMode);
              buf.append(" custType = ");
              buf.append(custType);
              pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
            }

		        // set the UI SPEL attributes for customer related fields
	          oam.invokeMethod("setLeadUwqCustProperties",new Serializable[]{custAcsMode,custType});

		        // set the access privileges in page context
	          if(leadAcsMode!=null)
	          {
	           pageContext.putParameter("ASNReqFrmLeadAcsMd", leadAcsMode);
	          }
	          if(custAcsMode!=null)
	          {
	           pageContext.putParameter("ASNReqFrmCustAcsMd", custAcsMode);
	          }

	          // Lead will be read-only if it is already converted to opportunity
            if("CONVERTED_TO_OPPORTUNITY".equals(leadStsCd))
            {
             isReadAccess = true;
            }

	          // Set embedded region integration parameters
	          setLeadRegionParameters (pageContext,leadInfo,isReadAccess, custAcsMode, true, webBean);
	      }
      }
      else
        {
          leadId = (String)pageContext.getParameter("ASNReqLeadId");
          if(leadId ==null)
           leadId = (String)queryAM.invokeMethod("getSelectedLeadId");

          //don't render detials region if no rows selected.
          if(leadId ==null)
           oam.invokeMethod("setLeadUwqProperties", new Serializable[]{leadAcsMode});
	      }

      if (isProcLogEnabled)
      {
        pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
      }
   }

  void setLeadRegionParameters (OAPageContext pageContext,
                                HashMap leadInfo,
                                boolean isReadAccess,
                                String custAcsMode,
                                boolean isPPR,
                                OAWebBean webBean)
	{
    final String METHOD_NAME = "xxcrm.asn.lead.webui.ODASNLeadUwqDetCO.setLeadRegionParameters";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }
        OAApplicationModule oam = pageContext.getRootApplicationModule();
	      /*** set Notes region parameters ***/
        String leadId = (String)leadInfo.get("SalesLeadId");
        String customerId = (String)leadInfo.get("CustomerId");
        String contactId  = (String)leadInfo.get("PrimaryContactPartyId");
        String addressID  = (String)leadInfo.get("AddressId");

        if (isStatLogEnabled)
            {
             StringBuffer buf = new StringBuffer(100);
              buf.append(" leadId = ");
              buf.append(leadId);
              buf.append(" customerId = ");
              buf.append(customerId);
              buf.append(" contactId = ");
              buf.append(contactId);
              pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
            }

        pageContext.putTransactionValue("ASNTxnNoteSourceCode","LEAD");
        pageContext.putTransactionValue("ASNTxnNoteSourceId",leadId);
        String lookupParam = "ASN_LEAD_VIEW_NOTES;0";
        pageContext.putTransactionValue("ASNTxnNoteLookup",lookupParam);
        String poplistParamList = "CUSTOMER;" + customerId;
        pageContext.putTransactionValue("ASNTxnNoteParamList", poplistParamList);
        String poplistTypeList = "CUSTOMER;PARTY";
        pageContext.putTransactionValue("ASNTxnNoteTypeList", poplistTypeList);
        pageContext.putTransactionValue("ASNTxnNoteReadOnly",(isReadAccess?"Y":"N"));
        if(ASNUIConstants.UPDATE_ACCESS.equals(custAcsMode))
        {
          pageContext.putTransactionValue("ASNTxnCustNoteReadOnly", "N");
          String poplistROList = "CUSTOMER;N";
          pageContext.putTransactionValue("ASNTxnNoteReadOnlyList",poplistROList);
        }
        else if(ASNUIConstants.READ_ACCESS.equals(custAcsMode))
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

         if (isPPR)
         pageContext.putParameter("ASNReqNotePPREventFlag", "Y");

	      /*** set Tasks region parameters ***/
        pageContext.putTransactionValue("cacTaskSrcObjCode", "LEAD");
        pageContext.putTransactionValue("cacTaskSrcObjId", leadId);
        pageContext.putTransactionValue("cacTaskCustId", customerId);
    /** Sending task addressid **/
		 String sql1 = "select address_id from as_sales_leads where sales_lead_id = :1";
		 OAApplicationModule oamaddr = pageContext.getRootApplicationModule();
		 oracle.jbo.ViewObject pSitevo1 = oamaddr.findViewObject("pSiteVO1");
		             if (pSitevo1 == null )
		             {
		               pSitevo1 = oamaddr.createViewObjectFromQueryStmt("pSiteVO1", sql1);
		             }

		             if (pSitevo1 != null)
		             {
		                 pSitevo1.setWhereClauseParams(null);
		                 pSitevo1.setWhereClauseParam(0,leadId);
		                 pSitevo1.executeQuery();
		                 pSitevo1.first();
		                 String Addressid = pSitevo1.getCurrentRow().getAttribute(0).toString();
		                 pSitevo1.remove();
		                 pageContext.putTransactionValue("cacTaskCustAddressId", Addressid);
                    }

        pageContext.putTransactionValue("cacTaskContDqmRule",(String)pageContext.getProfile("HZ_DQM_CON_SIMPLE_MATCHRULE"));
        pageContext.putTransactionValue("cacTaskNoDelDlg", "Y");
        pageContext.putTransactionValue("cacTaskReadOnlyPPR", (isReadAccess?"Y":"N"));
        if(contactId!=null)
        {
          pageContext.putTransactionValue("cacTaskContactId", contactId);
        }
        pageContext.putTransactionValue("cacTaskReturnUrl", getModifiedCurrentUrlForRedirect(pageContext,true));

         if (isPPR)
         {
          OAApplicationModule taskAM = (OAApplicationModule)oam.findApplicationModule("CacTaskSummAM");
          if(taskAM!=null)
          {
            taskAM.invokeMethod("resetQuery");
            taskAM.invokeMethod("initTaskSummQuery", new Serializable[]{"LEAD", leadId});
          }
        }

        if (isProcLogEnabled)
        {
         pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
        }
	}


}
