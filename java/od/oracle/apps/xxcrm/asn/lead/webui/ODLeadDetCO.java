  /*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODLeadDetCO.java                                              |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Controller Object for the Lead Details Page.                           |
 |                                                                           |
 |  NOTES                                                                    |
 |         Used for the Customization on the Lead Details Page               |
 |         Stores the Party Site Id to be passed to View Site Page           |
 |  DEPENDENCIES                                                             |
 |    No dependencies.                                                       |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    12-Sep-2007 Jasmine Sujithra   Created                                 |
 |    14-Dec-2007 Satyasrinivas      Parameter added for task address id.    |
 |    11-Feb-2008 Anirban Chaudhuri  Modified for security of the page.      |
 |    05-APRL-09  Prasad Devar       Modified Page to support ContactStrategy|
 |    12-May-2008 Anirban Chaudhuri  Modified for defect#14801 fix.          |
 +===========================================================================*/

package od.oracle.apps.xxcrm.asn.lead.webui;
//package oracle.apps.asn.lead.webui;

import com.sun.java.util.collections.HashMap;

import java.io.Serializable;

import oracle.apps.asn.common.fwk.webui.ASNControllerObjectImpl;
import oracle.apps.asn.common.fwk.webui.ASNUIConstants;
import oracle.apps.asn.common.webui.ASNUIUtil;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAViewObject;
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
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.webui.beans.nav.OANavigationBarBean;
import oracle.apps.fnd.framework.webui.beans.nav.OAPageButtonBarBean;
import oracle.apps.fnd.framework.webui.beans.table.OAAdvancedTableBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAStackLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OASubTabLayoutBean;
import oracle.apps.fnd.framework.webui.beans.nav.OALinkBean;
import oracle.apps.fnd.framework.webui.beans.nav.OASubTabBarBean;
import od.oracle.apps.xxcrm.asn.common.fwk.webui.ODASNControllerObjectImpl;
import oracle.apps.fnd.framework.server.*;
import oracle.apps.asn.lead.server.*;
import oracle.jbo.Row;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

/**
 * Controller for LeadDetPG
 */
public class ODLeadDetCO extends ODASNControllerObjectImpl
{
  public static final String RCS_ID="$Header: ODLeadDetCO.java 115.95 2005/02/15 20:44:37 pchalaga ship $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "od.oracle.apps.xxcrm.asn.lead.webui");

  /**
   * Layout and page setup logic for AK region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    final String METHOD_NAME = "xxcrm.asn.lead.webui.LeadDetCO.processRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processRequest(pageContext, webBean);

      /********  Get Page layout and Application module   *********/
    OAPageLayoutBean pgLayout = (OAPageLayoutBean)webBean;
    OAApplicationModule oam = pageContext.getRootApplicationModule();
    OAApplicationModule queryAM = (OAApplicationModule)oam.findApplicationModule("ASNLeadQryAM");

      /********  Get user context information   *********/
    String loginResId = this.getLoginResourceId(oam, pageContext);
    boolean isLoginResMgr = this.isLoginResourceManager(oam, pageContext);

    // Debug Logging
    if (isStatLogEnabled)
    {
      StringBuffer buf = new StringBuffer(200);
      buf.append(" loginResId ");
      buf.append(loginResId);
      pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
    } // End Debug Logging

    /********  Get page context information   *********/
    boolean isNavBarEnbld = "Y".equals(pageContext.getParameter("ASNReqFrmEnblNavBar"));

    // Debug Logging
    if (isStatLogEnabled)
    {
      StringBuffer buf = new StringBuffer(200);
      buf.append(" isNavBarEnbld ");
      buf.append(isNavBarEnbld);
      pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
    } // End Debug Logging

    String leadId = pageContext.getParameter("ASNReqFrmLeadId");
    if(leadId==null || "".equals(leadId.trim()))
    {
        // returned from PRP page - PRP returns only one parameter
      leadId = pageContext.getParameter("PRPObjectId");
    }

    // Debug Logging
    if (isStatLogEnabled)
    {
      StringBuffer buf = new StringBuffer(200);
      buf.append(" leadId ");
      buf.append(leadId);
      pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
    } // End Debug Logging

    boolean queryDetails = "Y".equals(pageContext.getParameter("ASNReqNewSelectionFlag"));

      /********  Perform the lead access check *********/
    boolean isNoAccess = true;
    boolean isReadAccess = false;
    String leadAcsMode = this.processAccessPrivilege(pageContext,
                                                   ASNUIConstants.LEAD_ENTITY,
                                                   leadId);
    // Debug Logging
    if (isStatLogEnabled)
    {
      StringBuffer buf = new StringBuffer(200);
      buf.append(" leadAcsMode ");
      buf.append(leadAcsMode);
      pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
    } // End Debug Logging

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

      /********  Modify the page breadcrumb   *********/
    this.modifyCurrentBreadcrumbLink(pageContext, false, null, true);

      // check whether the underlying summary view object exists before generating the navigation bar
    if(!this.isViewObjectQueried(queryAM, "LeadSearchVO"))
    {
      isNavBarEnbld = false;
    }

      // initialize the navigation bar
    if(isNavBarEnbld)
    {
      OAPageButtonBarBean pgBar = (OAPageButtonBarBean)pgLayout.getPageButtons();
      OANavigationBarBean navBar = null;
      if(pgBar!=null)
      {
        navBar = (OANavigationBarBean)pgBar.findIndexedChildRecursive("ASNPageNavBar");
      }
      if(navBar!=null)
      {
        int curNavValue = 1;
          /** Determine the current value for the navigation bar **/
        String navVal = pageContext.getParameter("ASNReqNavBarCurrValue");
        if(navVal!=null && navVal.trim().length()>0)
        {
          curNavValue = Integer.parseInt(navVal);
        }
        else
        {
            /** Determine the navigation index for the requested lead **/
          Serializable params[] = {"LeadSearchVO", leadId};
          curNavValue = Integer.parseInt((String)oam.invokeMethod("getLeadRowIndex", params));
          curNavValue = curNavValue + 1;
        }
        navBar.setValue(curNavValue);
        navBar.setMinValue(1);
        String rowCount = (String)pageContext.getTransactionValue("ASNTxnLeadRowCount");
        if(rowCount!=null)
        {
          long maxValue = Long.parseLong(rowCount);
          if(maxValue>=1)
            navBar.setMaxValue(maxValue);
        }
        navBar.setTypeText(pageContext.getMessage("ASN", "ASN_LEAD_TITLE", null));
      }
    }

      /********  Load the lead details *********/
    if(queryDetails)
    {
      oam.invokeMethod("resetQuery", new Serializable[]{"LeadHeaderDetailsVO"});
    }
    Serializable params[] = {"LeadHeaderDetailsVO", leadId};
    HashMap leadInfo = (HashMap)oam.invokeMethod("getLeadInfo", params);

    // Debug Logging
    if (isStatLogEnabled)
    {
      StringBuffer buf = new StringBuffer(200);
      buf.append(" After calling the method getLeadInfo. ");
      buf.append(" leadInfo : ");
      buf.append(leadInfo.toString());
      pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
    } // End Debug Logging

    if(leadInfo!=null && leadInfo.size()>0)
    {
      leadId = (String)leadInfo.get("SalesLeadId");
    }
    else
    {
      leadId = null;
    }

      /** Initialize and set the UI properties view object **/
    oam.invokeMethod("setLeadDetProperties", new Serializable[]{leadId, leadAcsMode,
                                                                (isNavBarEnbld?"Y":"N")});

    if(leadId!=null)
    {
      if(isNoAccess)
      {
        String errToken = pageContext.getMessage("ASN", "ASN_CMMN_LEAD", null);
        MessageToken[] tokens = { new MessageToken("OBJECTNAME", errToken) };
        throw new OAException("ASN", "ASN_CMMN_NO_ACSS_ERR", tokens);
      }

      String leadName = (String)leadInfo.get("Description");
      String leadStsCd = (String)leadInfo.get("StatusCode");
      String customerId = (String)leadInfo.get("CustomerId");
      String contactId = (String)leadInfo.get("PrimaryContactPartyId");
      String methodologyId = (String)leadInfo.get("SalesMethodologyId");
      String methodologyFlag = (String)leadInfo.get("SalesMethFlag");
      String currencyCd = (String)leadInfo.get("CurrencyCode");
      String currencyName1 = (String)leadInfo.get("CurrencyName");

        /*** Lead should become read-only if it is converted to opportunity  **/
      if("CONVERTED_TO_OPPORTUNITY".equals(leadStsCd))
      {
        isReadAccess = true;
      }

        /********  Perform the customer access check *********/
      String custAcsMode = this.checkAccessPrivilege(pageContext,
                                                     ASNUIConstants.CUSTOMER_ENTITY,
                                                     customerId, false
                                                    );
     pageContext.writeDiagnostics(METHOD_NAME,"custAcsMode = "+custAcsMode, OAFwkConstants.STATEMENT);
 String custType = this.getCustomerType(pageContext, customerId);

      if(custAcsMode!=null)
        pageContext.putTransactionValue("ASNTxnCustAcsMd", custAcsMode);
      else
        pageContext.removeTransactionValue("ASNTxnCustAcsMd");

        /** bind the input fields CSS class to properties view attribute **/
      String[] inputFldNms = new String[]
                                  {
                                    "ASNLeadDetNm", "ASNLeadDetRank",
                                    "ASNLeadDetStatus", "ASNLeadDetChnl",
                                    "ASNLeadDetRespChan", "ASNLeadDetSrcNm"
                                  };
      OAWebBean inputFldBn = null;
      for(int i=0; i<inputFldNms.length; i++)
      {
        inputFldBn = pgLayout.findIndexedChildRecursive(inputFldNms[i]);
        if(inputFldBn!=null)
        {
          inputFldBn.setAttributeValue(STYLE_CLASS_ATTR,
                    new OADataBoundValueViewObject(inputFldBn,"FIELD_CSS","LeadDetAppPropertiesVO"));
        }
      }
      inputFldBn = pgLayout.findIndexedChildRecursive("ASNLeadDetRsn");
      if(inputFldBn!=null)
      {
        inputFldBn.setAttributeValue(STYLE_CLASS_ATTR,
                      new OADataBoundValueViewObject(inputFldBn,"CLSRSN_CSS","LeadDetAppPropertiesVO"));
      }
      inputFldBn = pgLayout.findIndexedChildRecursive("ASNLeadDetMeth");
      if(inputFldBn!=null)
      {
        inputFldBn.setAttributeValue(STYLE_CLASS_ATTR,
                      new OADataBoundValueViewObject(inputFldBn,"METH_CSS","LeadDetAppPropertiesVO"));
      }
      inputFldBn = pgLayout.findIndexedChildRecursive("ASNLeadDetStage");
      if(inputFldBn!=null)
      {
        inputFldBn.setAttributeValue(STYLE_CLASS_ATTR,
                      new OADataBoundValueViewObject(inputFldBn,"STAGE_CSS","LeadDetAppPropertiesVO"));
      }

      // Handling FlexField Additional Info Region on Sales Team Table
      // Check whether the Sales Team Addition Info. Flexfield Region is Rendered
      // OAStackLayoutBean stBean=(OAStackLayoutBean)webBean.findChildRecursive("ASNSTAddInfoRN");
      OAHeaderBean stBean=(OAHeaderBean)webBean.findChildRecursive("ASNSTAddInfoHdrRN");
      if(stBean.isRendered())
      {
        // Refresh the Current Row or set the first row
        oam.invokeMethod("refreshSalesteamDetailsRow");

        /********  Set the SalesTeam related UI attributes  ********/
        oam.invokeMethod("setLeadDetSTProperties", new Serializable[]{
                                                          "Y"
                                                         });
      }
      else
      {
        /********  Set the SalesTeam related UI attributes  ********/
        oam.invokeMethod("setLeadDetSTProperties", new Serializable[]{
                                                          "N"
                                                         });
      }

      // setting the contact table properties
      oam.invokeMethod("setLeadDetCustProperties", new Serializable[]{
                                                          custAcsMode,
                                                          custType,
                                                          (isReadAccess?"Y":"N")
                                                         });

      // Modify the detail region attributes

      // Set page title
      pgLayout.setTitle(pageContext.getMessage("ASN", "ASN_LEAD_DETPG_TITLE",
                          new MessageToken[]{new MessageToken("NAME", (leadName!=null?leadName:""))}));

      /** Setting wrap for the address field in read only mode **/
      if(isReadAccess)
      {
        OAMessageTextInputBean addressBean = (OAMessageTextInputBean) webBean.findIndexedChildRecursive("ASNLeadDetAddr");
        if(addressBean != null)
        {
         addressBean.setWrap(SOFT_WRAP);
        }
      }

        /**** Always display close reason if status is displayed  ****/
      OAWebBean clsReasonBean = webBean.findIndexedChildRecursive("ASNLeadDetRsn");
      OAWebBean stsBean = webBean.findIndexedChildRecursive("ASNLeadDetStatus");
      if(clsReasonBean!=null && stsBean!=null)
      {
        if(stsBean.isRendered())
        {
          clsReasonBean.setRendered(true);
        }
      }

        /**** Always disable the customer address field  ****/
      OAMessageTextInputBean addrBean = (OAMessageTextInputBean)webBean.findIndexedChildRecursive("ASNLeadDetAddr");
      if(addrBean != null)
      {
        addrBean.setDisabled(true);
      }

        /** Handle address selection **/
      String selPtySiteId = pageContext.getParameter("ASNReqSelPartySiteId");
      String selAddress = null;
      if(selPtySiteId!=null && !("".equals(selPtySiteId.trim())))
      {
        // String selLocationId = pageContext.getParameter("ASNReqSelLocationId");
        selAddress = pageContext.getParameter("ASNReqSelAddress");
        if(!isReadAccess && !("PERSON".equals(custType)))
        {
          Serializable[] addrParams = {selPtySiteId, selAddress};
          oam.invokeMethod("setCustAddressAttributes", addrParams);
        }
      }

        /**  Read Only flag for Suggested Contacts **/
      pageContext.putTransactionValue("ASNTxnSugCtctReadOnly",
                                ((isReadAccess || "PERSON".equals(custType))?"Y":"N"));

        /**  Read Only flag for Included components **/
      if(isReadAccess)
      {
        pageContext.putTransactionValue("ASNTxnLeadReadOnly", "Y");
      }
      else
      {
        pageContext.putTransactionValue("ASNTxnLeadReadOnly", "N");
      }

        /**  Sales methodology validation **/
      if("Y".equals(methodologyFlag))
      {
          /**  Sales Cycle integration - set required parameters  **/
        pageContext.putTransactionValue("ASNTxnSCObjectType", "LEAD");
        pageContext.putTransactionValue("ASNTxnSCObjectId", leadId);
        pageContext.putTransactionValue("ASNTxnSCMethId", methodologyId);
        String stageId = (String)leadInfo.get("SalesStageId");
        if(stageId!=null)
          pageContext.putTransactionValue("ASNTxnSCStageId", stageId);
        else
          pageContext.removeTransactionValue("ASNTxnSCStageId");
        if(isReadAccess)
          pageContext.putTransactionValue("ASNTxnSCReadOnlyFlag", "Y");
        else
          pageContext.putTransactionValue("ASNTxnSCReadOnlyFlag", "N");
        if(currencyCd!=null)
          pageContext.putTransactionValue("ASNTxnSCCurrencyCd", currencyCd);
        else
          pageContext.removeTransactionValue("ASNTxnSCCurrencyCd");
      }
      else
      {
          /** Hide the sales cycle sub-tab **/
           // This option always ensures that the only sales cycle sub-tab index is used for hiding/removing
        this.hideSubtab(pageContext, webBean, "ASNLeadDetSubtab", "ASNSCHdrRN");

          // hide the sales cycle table - if it is used somewhere other than the sales cycle sub-tab
        OAWebBean scStackBean = webBean.findIndexedChildRecursive("ASNSCStgStack");
        if(scStackBean!=null)
        {
          scStackBean.setRendered(false);
        }
      }

        /** Notes Integration -- set required parameters **/
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

         /** Tasks Integration  - set required parameters **/
      pageContext.putTransactionValue("cacTaskSrcObjCode", "LEAD");
      pageContext.putTransactionValue("cacTaskSrcObjId", leadId);
      pageContext.putTransactionValue("cacTaskCustId", customerId);
      pageContext.putTransactionValue("cacTaskContDqmRule", (String)pageContext.getProfile("HZ_DQM_CON_SIMPLE_MATCHRULE"));
      pageContext.putTransactionValue("cacTaskNoDelDlg", "Y");
      if(contactId!=null)
      {
        pageContext.putTransactionValue("cacTaskContactId", contactId);
      }
      pageContext.putTransactionValue("cacTaskReturnUrl", getModifiedCurrentUrlForRedirect(pageContext, true));
      //--pageContext.putTransactionValue("cacTaskTableRO", (isReadAccess?"Y":"N"));
      pageContext.putTransactionValue("cacTaskReadOnlyPPR", (isReadAccess?"Y":"N"));

         /** Analysis - Suggested Contacts integration -- set required parameters **/
      pageContext.putTransactionValue("ASNTxnLeadId", leadId);
      pageContext.putTransactionValue("ASNTxnCustomerId", customerId);
      pageContext.putTransactionValue("ASNTxnSugCtctDestVUN", "LeadHeaderContactDetailsVO");

      /** Partners - External sales Team Integration -- set required parameters **/
      pageContext.putTransactionValue("PvSalesLeadId", leadId);
      pageContext.putTransactionValue("PvCustomerId", customerId);
      pageContext.putTransactionValue("PvLeadReadOnly", (isReadAccess?"Y":"N"));
      pageContext.putTransactionValue("prmReturnUrl", getModifiedCurrentUrlForRedirect(pageContext, true));


         /** Resource-Group poplist validation **/
        // Bug Fix: 3373511 -- Sales Group in Sales team table is displayed as read-only
      OAAdvancedTableBean slsTeamBean = (OAAdvancedTableBean)webBean.findIndexedChildRecursive("ASNSTLstTb");
      if(slsTeamBean!=null)
      {
        OAMessageChoiceBean groupBean = (OAMessageChoiceBean)slsTeamBean.findIndexedChildRecursive("ASNSTGroup");
        if(groupBean!=null)
        {
          groupBean.setListVOBoundContainerColumn(0, slsTeamBean,"ASNSTRscId");
		      groupBean.setListVOBoundContainerColumn(1, slsTeamBean,"ASNSTGroupId");
        }
      }
    }
    else
    {
      throw new OAException("ASN","ASN_CMMN_REQKEY_MISS_ERR");
    }

    //attachment integration here

    ASNUIUtil.attchSetUp(pageContext
                    ,webBean
                    ,(!isReadAccess)
                    ,"ASNSubtabLeadAttachTable"//This is the attachment table item
                    ,"ASNLeadAttachContextHolderRN"//This is the stack region that holds the context information
                    ,"ASNLeadAttachContextRN");//this is the messageComponentLayout region that holds actual context beans


    ASNUIUtil.attchSetUp(pageContext
                    ,webBean
                    ,(!isReadAccess)
                    ,"ASNDetAttachHdrTable"//This is the attachment table item
                    ,"ASNLeadAttachContextHolderRN"//This is the stack region that holds the context information
                    ,"ASNLeadAttachContextRN");//this is the messageComponentLayout region that holds actual context beans

    // Setting the Formatted Text for Currency Code
    // Begin of Setting the currency information
    OAFormattedTextBean fmtdCurrNmBean = (OAFormattedTextBean)pgLayout.findIndexedChildRecursive("ASNLeadDetCurrNm");

      String currencyName = (String)leadInfo.get("CurrencyName");
    // String currencyNm = (String)oam.invokeMethod("getLeadCurrencyName", new Serializable[]{"LeadHeaderDetailsVO"});

    if(fmtdCurrNmBean!=null)
    {
      String fmtdCurrNmTxt = pageContext.getMessage("ASN", "ASN_CMMN_CURR_DETS",
                                new MessageToken[]{new MessageToken("CURRCODE", currencyName)});

      fmtdCurrNmBean.setText(fmtdCurrNmTxt);
      fmtdCurrNmBean.setValue(pageContext, fmtdCurrNmTxt);
      fmtdCurrNmBean.setCSSClass("OraPageStampText");
    }
    // End of Setting the currency information

    // Format the Budget Amount based on the Currency Code
    // Begin of Budget Amount Formatting

      OAWebBean budgetAmtBean = pgLayout.findIndexedChildRecursive("ASNLeadDetBudgetAmt");
      if(budgetAmtBean!=null)
      {
        budgetAmtBean.setAttributeValue(OAWebBeanConstants.CURRENCY_CODE, new OADataBoundValueViewObject(budgetAmtBean, "CurrencyCode","LeadHeaderDetailsVO"));
      }
    // End of Budget Amount Formatting

    /****  New Code Additions -- START ****/

      boolean flag = pageContext.isLoggingEnabled(2);
      boolean flag1 = pageContext.isLoggingEnabled(1);
      if(flag)
        pageContext.writeDiagnostics(METHOD_NAME,"Begin", 2);
      super.processRequest(pageContext, webBean);
      OAApplicationModule oaapplicationmodule = pageContext.getRootApplicationModule();
      String leadid = pageContext.getParameter("ASNReqFrmLeadId");
      Serializable aserializable[] = {"LeadHeaderDetailsVO", leadid};

      HashMap hashmap = (HashMap)oaapplicationmodule.invokeMethod("getLeadInfo", aserializable);
      String addressid = (String)hashmap.get("AddressId");
      String address = (String)hashmap.get("Address");
      String leadID = (String)hashmap.get("SalesLeadId");
	  String customerId = (String)hashmap.get("CustomerId");
	  String contactId = (String)hashmap.get("PrimaryContactPartyId");
       Object srcCdObj = (Object)hashmap.get("SourceCode");

 
      if(flag1)
      {
        pageContext.writeDiagnostics(METHOD_NAME,"Value of AddressId is :" + addressid, 1);
        pageContext.writeDiagnostics(METHOD_NAME,"Value of Address is :" + address, 1);
      }

     pageContext.putTransactionValue("ASNPartySiteId", addressid);
/////

      /** OD -- Task Reference parameters **/
	 		   		   	 pageContext.putTransactionValue("cacTaskSrcObjCode", "LEAD");
	 		   		   	 pageContext.putTransactionValue("cacTaskSrcObjId", leadID);
	 		   		     pageContext.putTransactionValue("cacTaskCustId", customerId);
	 		   		     pageContext.putTransactionValue("cacTaskCustAcctId","");
	 		   		     pageContext.putTransactionValue("cacTaskCustAddressId", addressid);
	 		   		     pageContext.putTransactionValue("cacTaskContDqmRule", (String)pageContext.getProfile("HZ_DQM_CON_SIMPLE_MATCHRULE"));
	 		   		   	 pageContext.putTransactionValue("cacTaskNoDelDlg", "Y");
	 		   		   	 if(contactId!=null)
	 		   		   	 {
	 		   		   	   pageContext.putTransactionValue("cacTaskContactId", contactId);
	 		             }
	 		          if(flag1)
	 		   	         {
	 		   			   pageContext.writeDiagnostics(METHOD_NAME,"Value of cacTaskSrcObjId is :" + leadID, 1);
	 		   			   pageContext.writeDiagnostics(METHOD_NAME,"Value of cacTaskCustId is :" + customerId, 1);
	 		   			   pageContext.writeDiagnostics(METHOD_NAME,"Value of AddressId is :" + addressid, 1);
	 		   	           pageContext.writeDiagnostics(METHOD_NAME,"Value of cacTaskContDqmRule is :" + pageContext.getProfile("HZ_DQM_CON_SIMPLE_MATCHRULE"), 1);
		   	         }
  /****  New Code Additions -- END ****/

    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }




      

//----------------   Prasad Changes Start ---------------------/
      // ******* Custom code starts here
      // Code to add Feedback Tab in Lead details page.
   

  if (!pageContext.isFormSubmission())
    {
    if(srcCdObj !=null){
        ///Check for source Object IF applicible for Feedback
          //LeadUwqAMImpl leadAM =(LeadUwqAMImpl)oam;//Anirban commented out for compilation issues.
		  OAApplicationModuleImpl leadAM =(OAApplicationModuleImpl)oam;//Anirban introduced this line of code for compilation issues.
		  OAApplicationModule leadAM1 = (OAApplicationModule)leadAM;
          oracle.apps.fnd.framework.OAViewObject oaviewobject2 = (oracle.apps.fnd.framework.OAViewObject)leadAM1.findViewObject("ODSCSSourcesVO");
          java.lang.StringBuffer stringbuffer = new StringBuffer(1000);
            stringbuffer.append("  SELECT SOC.source_code  AS  \"Code\" , CAMPT.campaign_name AS \"Value\"  FROM  ");
            stringbuffer.append("                    AMS_SOURCE_CODES     SOC, ");
            stringbuffer.append("                    AMS_CAMPAIGNS_ALL_TL CAMPT, ");
            stringbuffer.append("                    AMS_CAMPAIGNS_ALL_B  CAMPB, ");
            stringbuffer.append("                    apps.FND_LOOKUP_VALUES    LKP ");
            stringbuffer.append("                  WHERE ");
            stringbuffer.append("                      SOC.arc_source_code_for = 'CAMP' ");
            stringbuffer.append("                  AND SOC.active_flag = 'Y' ");
             stringbuffer.append("                 AND SOC.source_code_for_id = campb.campaign_id ");
            stringbuffer.append("                  AND CAMPB.campaign_id = campt.campaign_id ");
            stringbuffer.append("                  AND CAMPB.status_code IN('ACTIVE',    'COMPLETED') ");
            stringbuffer.append("                  AND CAMPT.LANGUAGE = userenv('LANG') ");
            stringbuffer.append("                  AND   LKP.lookup_type = 'XXSCS_POT_TYPE_SOURCE_MAP' ");
            stringbuffer.append("                   AND ltrim(rtrim(upper(replace(LKP.description,chr(9),''))))  = ltrim(rtrim(upper(replace(CAMPT.campaign_name,chr(9),'')))) ");
            stringbuffer.append("                   AND SOC.source_code = ");
            stringbuffer.append("'"+srcCdObj.toString()+"'");
            oracle.apps.fnd.framework.server.OAViewDefImpl oaviewdefimpl = (oracle.apps.fnd.framework.server.OAViewDefImpl)oam.getOADBTransaction().createViewDef();
            oaviewdefimpl.setSql(stringbuffer.toString());
            oaviewdefimpl.setExpertMode(true);
            oaviewdefimpl.setFullName("oracle.apps.asn.lead.server.ODSCSSourcesVO");
            oaviewdefimpl.addSqlDerivedAttrDef("Code", "FDK_CODE", "java.lang.String", 12, false, false, (byte)0, 200);
            oaviewdefimpl.addSqlDerivedAttrDef("Value", "FDK_VALUE", "java.lang.String", 12, false, false, (byte)0, 200);
            if(oaviewobject2!=null)
              {
                oaviewobject2.remove();
               }
            oaviewobject2 = (oracle.apps.fnd.framework.OAViewObject) leadAM.createViewObject("ODSCSSourcesVO", ((oracle.apps.fnd.framework.server.OAViewDef)oaviewdefimpl));
            oaviewobject2.setPassivationEnabled(false);
            
            ((oracle.apps.fnd.framework.server.OAViewObjectImpl)oaviewobject2).setFetchSize((short)50);
              if(!oaviewobject2.isPreparedForExecution())
                {
                  oaviewobject2.executeQuery();
                }

            Row oaRow = (Row)oaviewobject2.first();
           if(oaRow!=null )
            {    
              // Subtab To Page
                OASubTabLayoutBean tabBean = (OASubTabLayoutBean)webBean.findChildRecursive("ASNLeadDetSubtab");
                OASubTabBarBean oppsubTabBean = (OASubTabBarBean)webBean.findChildRecursive("ASNLeadDetSubtabBar");
                OAStackLayoutBean feedbackSetup = new OAStackLayoutBean();
                feedbackSetup.setText("Feedback History");
                               OAStackLayoutBean feedbackRegion= (OAStackLayoutBean)createWebBean(pageContext,
                   "/od/oracle/apps/xxcrm/scs/fdk/webui/ODSCSFdkHstryRN",
                   "FeedbackRN",
                   true);
                 feedbackSetup.addIndexedChild(feedbackRegion);
                  OALinkBean feedbackLink = new OALinkBean();
                 feedbackLink.setText("Feedback History");
                 feedbackLink.setFireActionForSubmit("update", null, null, true, true);
                 feedbackLink.setID("FeedbackTab");
                 tabBean.addIndexedChild(feedbackSetup);
                 oppsubTabBean.addIndexedChild(feedbackLink);
                 String src=pageContext.getParameter("SCSReqFrmSrc") ;

                  // seting the Notes & Task as default for Contact Strategy  
   if (!pageContext.isFormSubmission())
    {
                 if(src!=null &&!src.equals(""))
                    if(src.equals("CS"))
                    {
                      OALinkBean noteTaskHdrLnk = (OALinkBean) webBean.findChildRecursive("ASNNoteTaskHdrLnk");
                     // noteTaskHdrLnk.setSelected(true);
                      tabBean.setSelectedIndex(pageContext,"ASNNoteTaskHdrRN");
                      pageContext.putParameter("SCSReqFrmSrc","");
                    }
    }
                 
              }
           }
       }
//----------------   Prasad Changes End ----------------------------------

    //Anirban: starts defect fix #14801
    OAWebBean asnCtctAddButton = webBean.findChildRecursive("ASNCtctAddButton");
    OAWebBean asnCtctCrteButton = webBean.findChildRecursive("ASNCtctCrteButton");
    if(asnCtctAddButton!=null && asnCtctCrteButton!=null)
    {
     asnCtctAddButton.setRendered(true);
     asnCtctCrteButton.setRendered(true);
	 pageContext.writeDiagnostics(METHOD_NAME, "Anirban 12 May: always render contact create button", OAFwkConstants.STATEMENT);
    }
    //Anirban: ends defect fix #14801


  }

  // Fix for bug 4040174 - This is so that processing continues after
  // a warning message is encountered.





   /**
   * Procedure that is called upon form submit.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */

  public void processFormData(OAPageContext pageContext, OAWebBean webBean)
  {
     pageContext.setSkipProcessFormRequestForMessageLevel(OAException.ERROR);
     super.processFormData(pageContext, webBean);
   }

  /**
   * Procedure to handle form submissions for form elements in
   * AK region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    final String METHOD_NAME = "xxcrm.asn.lead.webui.LeadDetCO.processFormRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processFormRequest(pageContext, webBean);

      /********  Set the current page function name  *********/
    pageContext.putParameter("ASNReqFrmFuncName", "ASN_LEADDETPG");

      /********  Get the Application module   *********/
    OAApplicationModule oam = pageContext.getRootApplicationModule();

      /********  Get the page action event that has caused the submit  *********/
    String actEvt = pageContext.getParameter("ASNReqPgAct");
    String oaActEvt = pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM);

      /** Since some of the framework parameters are not returned by PRP page in their return
       *  flow, these parameters have been maintained in transaction/session, which'll have
       *  to be set back explicitly in page context/URL
       *  **/
    String leadIdVal = (String)oam.invokeMethod("getLeadId", new Serializable[]{"LeadHeaderDetailsVO"});
    if(leadIdVal!=null)
      pageContext.putParameter("ASNReqFrmLeadId", leadIdVal);

      /********  Set the access privileges in the page context  *********/
    String leadAcsMode = (String)pageContext.getTransactionValue("ASNTxnLeadAcsMd");
    String custAcsMode = (String)pageContext.getTransactionValue("ASNTxnCustAcsMd");
    if(leadAcsMode!=null)
      pageContext.putParameter("ASNReqFrmLeadAcsMd", leadAcsMode);
    if(custAcsMode!=null)
      pageContext.putParameter("ASNReqFrmCustAcsMd", custAcsMode);

      /********  Get the Page title   *********/
    String leadName = (String)oam.invokeMethod("getLeadName", new Serializable[]{"LeadHeaderDetailsVO"});
    String pageTitle = pageContext.getMessage("ASN", "ASN_LEAD_DETPG_TITLE",
                          new MessageToken[]{new MessageToken("NAME", (leadName!=null?leadName:""))});
    pageContext.putParameter("ASNReqBrdCrmbTtl", pageTitle);

      /********  Handle the applciation logic for each event  *********/
    if(OAWebBeanConstants.GOTO_EVENT.equals(oaActEvt) &&
       "ASNPageNavBar".equals(pageContext.getParameter(OAWebBeanConstants.SOURCE_PARAM)))
    {
        // determine whether to save the changes, do not save for the read-only access mode
        // for read-only case, roll back the changes for phase-1
      this.doCommit(pageContext);
      oam.invokeMethod("resetQuery", new Serializable[]{"LeadHeaderDetailsVO"});

      pageContext.putParameter("ASNReqNewSelectionFlag", "Y");
      pageContext.putParameter("ASNReqSCStgVw", "CURRENT_STAGE");

        // determine the summary view usage based on view privileges
        // determine whether to go to previous or next lead - find the lead id
      int targetIndex = Integer.parseInt(pageContext.getParameter("value"));
      String rowIndex = String.valueOf((targetIndex>=1?(targetIndex-1):0));
      Serializable params[] = {"LeadSearchVO", rowIndex};
      HashMap urlParams = (HashMap)oam.invokeMethod("findLeadInfoByRowIndex", params);
      if(urlParams!=null)
      {
        pageContext.putParameter("ASNReqNavBarCurrValue", String.valueOf(targetIndex));
        pageContext.putParameter("ASNReqPgAct", "LEADDET");
        pageContext.putParameter("ASNReqFrmLeadId", (String)urlParams.get("ASNReqFrmLeadId"));
        pageContext.removeParameter("ASNReqFrmLeadAcsMd");
        pageContext.removeParameter("ASNReqFrmCustAcsMd");
        HashMap conditions = new HashMap(4);
        conditions.put(ASNUIConstants.RETAIN_AM, "Y");
        conditions.put(ASNUIConstants.BC_CURRENT_LINK, ASNUIConstants.BC_CURRENT_LINK_REMOVE);
        conditions.put(ASNUIConstants.BLOCK_ENTRY, "N");
        urlParams.put("ASNReqFrmEnblNavBar", "Y");

        // Debug Logging
        if (isStatLogEnabled)
        {
          StringBuffer buf = new StringBuffer(200);
          buf.append(" ASNPageNavBar is teh context parameter - Parameters being passed to processTargetURL -  ");
          buf.append(" conditions : ");
          buf.append(conditions.toString());
          buf.append(" urlParams : ");
          buf.append(urlParams.toString());
          pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
        } // End Debug Logging

        this.processTargetURL(pageContext, conditions, urlParams);
      }
    }
    else if("METHCHG".equals(oaActEvt))
    {
        // handle methodology update event - refresh and deafult the stage
      oam.invokeMethod("handleMethChg", new Serializable[]{"LeadHeaderDetailsVO", "LeadDetAppPropertiesVO"});
    }
    else if("detailStatusUpdate".equals(oaActEvt))
    {
        // handle status update event - refresh the close reasons
      oam.invokeMethod("handleDetailStatusUpdateEvent");
    }
    else if("CSCHDET".equals(actEvt))
    {
      String cschId = pageContext.getParameter("ASNReqEvtCschId");
      if(cschId!=null && !("".equals(cschId.trim())))
      {
        this.doCommit(pageContext);
        oam.invokeMethod("resetQuery", new Serializable[]{"LeadHeaderDetailsVO"});
        HashMap cschParams = new HashMap(2);
        cschParams.put("objId",cschId);
        HashMap conditions = new HashMap(3);
        conditions.put(ASNUIConstants.BC_CURRENT_LINK, ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
        conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT, pageTitle);

        // Debug Logging
        if (isStatLogEnabled)
        {
          StringBuffer buf = new StringBuffer(200);
          buf.append(" actEvt is CSCHDET - Parameters being passed to processTargetURL -  ");
          buf.append(" conditions : ");
          buf.append(conditions.toString());
          buf.append(" cschParams : ");
          buf.append(cschParams.toString());
          pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
        } // End Debug Logging

        this.processTargetURL(pageContext, conditions, cschParams);
      }
    }
    else if("CTCTDET".equals(actEvt))
    {
      this.doCommit(pageContext);
      // oam.invokeMethod("resetQuery", new Serializable[]{"LeadHeaderDetailsVO"});
      HashMap conditions = new HashMap(3);
      conditions.put(ASNUIConstants.BC_CURRENT_LINK, ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
      conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT, pageTitle);
      HashMap urlParams = this.getFrmParamsFromEvtParams(pageContext);

      // Debug Logging
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(200);
        buf.append(" Customer and Contact Details Buttons- Parameters being passed to processTargetURL -  ");
        buf.append(" conditions : ");
        buf.append(conditions.toString());
        buf.append(" urlParams : ");
        buf.append(urlParams.toString());
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      } // End Debug Logging

      this.processTargetURL(pageContext, conditions, urlParams);
    }
    //anirban starts securing the party link
    else if("CUSTDET".equals(actEvt))
    {
      this.doCommit(pageContext);
      // oam.invokeMethod("resetQuery", new Serializable[]{"LeadHeaderDetailsVO"});
      HashMap conditions = new HashMap(3);
      conditions.put(ASNUIConstants.BC_CURRENT_LINK, ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
      conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT, pageTitle);
      HashMap urlParams = this.getFrmParamsFromEvtParams(pageContext);

      // Debug Logging
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(200);
        buf.append(" Customer and Contact Details Buttons- Parameters being passed to processTargetURL -  ");
        buf.append(" conditions : ");
        buf.append(conditions.toString());
        buf.append(" urlParams : ");
        buf.append(urlParams.toString());
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      }  // End Debug Logging

      //this.processTargetURL(pageContext, conditions, urlParams);

	  HashMap hashmap = new HashMap();
	  hashmap.put("ASNReqFrmCustId", pageContext.getParameter("ASNReqEvtCustId"));
      hashmap.put("ASNReqFrmFuncName", "ASN_ORGVIEWPG");
      pageContext.putParameter("ASNReqPgAct", "CUSTDET");
	  boolean flag50 = false;
	  pageContext.forwardImmediately("ASN_ORGVIEWPG", OAWebBeanConstants.KEEP_MENU_CONTEXT, null, hashmap, flag50, "Y");
    }
	//anirban ends securing the party link
    else if(pageContext.getParameter("ASNAddrSelButton")!=null)
    {
      this.doCommit(pageContext);
      String customerId = (String)oam.invokeMethod("getLeadCustomerId",
                                          new Serializable[]{"LeadHeaderDetailsVO"});
      oam.invokeMethod("resetQuery", new Serializable[]{"LeadHeaderDetailsVO"});
      pageContext.putParameter("ASNReqPgAct", "SUBFLOW");
      HashMap conditions = new HashMap(4);
      conditions.put(ASNUIConstants.RETAIN_AM, "Y");
      conditions.put(ASNUIConstants.BC_CURRENT_LINK, ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
      conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT, pageTitle);
        // set the required sub-flow specific parameters
      HashMap urlParams = new HashMap(3);
      urlParams.put("ASNReqFrmFuncName", "ASN_PTYADDRSELPG");
      urlParams.put("ASNReqFrmCustId", customerId);

      // Debug Logging
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(200);
        buf.append(" Address Selection Button - Parameters being passed to processTargetURL -  ");
        buf.append(" conditions : ");
        buf.append(conditions.toString());
        buf.append(" urlParams : ");
        buf.append(urlParams.toString());
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      } // End Debug Logging

      this.processTargetURL(pageContext, conditions, urlParams);
    }
    else if(pageContext.getParameter("ASNPageFshButton")!=null)
    {
      this.doCommit(pageContext);
      oam.invokeMethod("resetQuery", new Serializable[]{"LeadHeaderDetailsVO"});
        // forward the request to the lead uwq page
      HashMap urlParams = new HashMap(2);

      if (isLoginResourceManager(oam, pageContext))
      // if ("Y".equals((String)pageContext.getSessionValue(ASNUIConstants.MANAGER_UI_FLAG)))
      {
       urlParams.put("ASNReqFrmFuncName", "ASN_LEADUWQPG_MGR");
       pageContext.forwardImmediately("ASN_LEADUWQPG_MGR",
                                     OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                     null,
                                     urlParams,
                                     false,
                                     OAWebBeanConstants.ADD_BREAD_CRUMB_YES
                                    );
      }
      else
      {
       urlParams.put("ASNReqFrmFuncName", "ASN_LEADUWQPG");
       pageContext.forwardImmediately("ASN_LEADUWQPG",
                                     OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                     null,
                                     urlParams,
                                     false,
                                     OAWebBeanConstants.ADD_BREAD_CRUMB_YES
                                    );
      }
    }
    else if(pageContext.getParameter("ASNPageSvButton")!=null)
    {
      this.doCommit(pageContext);
      oam.invokeMethod("resetQuery", new Serializable[]{"LeadHeaderDetailsVO"});
      pageContext.putParameter("ASNReqNewSelectionFlag", "Y");
      pageContext.putParameter("ASNReqPgAct", "REFRESH");
      HashMap conditions = new HashMap(3);
      conditions.put(ASNUIConstants.BC_CURRENT_LINK, ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
      conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT, pageTitle);
      this.processTargetURL(pageContext, null, null);
    }
    else if(pageContext.getParameter("ASNPageRankButton")!=null)
    {
      oam.invokeMethod("runLeadEngines", new Serializable[] {"LeadHeaderDetailsVO"});
      this.doCommit(pageContext);
      oam.invokeMethod("resetQuery", new Serializable[]{"LeadHeaderDetailsVO"});
      pageContext.putParameter("ASNReqNewSelectionFlag", "Y");
      pageContext.putParameter("ASNReqPgAct", "REFRESH");
      HashMap conditions = new HashMap(3);
      conditions.put(ASNUIConstants.BC_CURRENT_LINK, ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
      conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT, pageTitle);

      // Debug Logging
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(200);
        buf.append(" Rank Button - Parameters being passed to processTargetURL -  ");
        buf.append(" conditions : ");
        buf.append(conditions.toString());
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      } // End Debug Logging

      this.processTargetURL(pageContext, conditions, null);
    }
    else if(pageContext.getParameter("ASNPageCnvToOpptyButton")!=null)
    {
      // convert the lead to opportunity
      Serializable params[] = {"LeadHeaderDetailsVO", null};
      String opptyId = (String)oam.invokeMethod("convertToOpportunity", params);
      if(opptyId!=null)
      {
        // commit the transaction
        this.doCommit(pageContext);

        String customerId = pageContext.getParameter("ASNReqFrmCustId");
        pageContext.putParameter("ASNReqPgAct", "OPPTYDET");
        pageContext.putParameter("ASNReqNewSelectionFlag", "Y");
        HashMap conditions = new HashMap(3);
        conditions.put(ASNUIConstants.BC_CURRENT_LINK, ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
        conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT, pageTitle);
        HashMap urlParams = new HashMap(3);
        urlParams.put("ASNReqFrmOpptyId", opptyId);
        if(customerId!=null && !("".equals(customerId.trim())))
        {
          urlParams.put("ASNReqFrmCustId", customerId);
        }

        // Debug Logging
        if (isStatLogEnabled)
        {
          StringBuffer buf = new StringBuffer(200);
          buf.append(" Convert Lead to Opportunity Button - Parameters being passed to processTargetURL -  ");
          buf.append(" conditions : ");
          buf.append(conditions.toString());
          buf.append(" urlParams : ");
          buf.append(urlParams.toString());
          pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
        } // End Debug Logging

        this.processTargetURL(pageContext, conditions, urlParams);
      }
    }
    else if("RSCDEL".equals(actEvt))
    {
      String leadAccessId = pageContext.getParameter("ASNReqEvtRowId");
      this.deleteRow(oam, "LeadHeaderAccessDetailsVO", "AccessId", leadAccessId, false);

      // We check if the Flexfield Region is rendered, based on which we do a workaround
      // Get a handle to the StackLayout of the Sales Team Additional Info region
      // OAStackLayoutBean AddInfoBean=(OAStackLayoutBean)webBean.findChildRecursive("ASNSTAddInfoRN");
      OAHeaderBean AddInfoBean=(OAHeaderBean)webBean.findChildRecursive("ASNSTAddInfoHdrRN");
      // Check if the Stacked Layout is Rendered (user may have personalized)
      // Execute further code only if the StackLayout Bean is rendered

      if(AddInfoBean.isRendered())
      {
        // Use the following Line of Code as workaround for Bug # 3274685
        // pageContext.forwardImmediately(PageFunctionName,MenuContext, MenuName, urlParams, RetainAM,BreadCrumb);
        // This has been handled in the processTargetURL
        pageContext.putParameter("ASNReqPgAct", "REFRESH");
        this.processTargetURL(pageContext, null, null);
      }

    }
      /** Intregated Component specific logic **/
    else if("Update".equals(pageContext.getParameter("CacSmrTaskEvent")) ||
            "View".equals(pageContext.getParameter("CacSmrTaskEvent")))
    {
      this.doCommit(pageContext);
      oam.invokeMethod("resetQuery", new Serializable[]{"LeadHeaderDetailsVO"});
      this.modifyCurrentBreadcrumbLink(pageContext, true, pageTitle, true);
    }
    else if("OPPTYDET".equals(actEvt))
    {
      this.doCommit(pageContext);
    }
    else if(pageContext.getParameter("ASNSCStgVwWkShtButton")!=null
            || "SLSCCH".equals(actEvt))
    {
      this.doCommit(pageContext);
      pageContext.putTransactionValue("ASNTxnSalesCycleReset", "N");
	 if ("SLSCCH".equals(actEvt))
	 {
       oam.invokeMethod("resetQuery", new Serializable[]{"LeadHeaderDetailsVO"});
	  }
      pageContext.removeTransactionValue("ASNTxnSalesCycleReset");
    }
    else if("STGVWCHG".equals(oaActEvt))
    {
      String stageId = (String)oam.invokeMethod("getLeadSalesStageId", new Serializable[]{"LeadHeaderDetailsVO"});
      if(stageId!=null)
      {
        pageContext.putTransactionValue("ASNTxnSCStageId", stageId);
      }
      else
      {
        pageContext.removeTransactionValue("ASNTxnSCStageId");
      }
    }
    /** Partners - External sales Team Integration -- set required parameters **/
    else if("pvNavigationEvent".equals(oaActEvt))
    {
      // Commit the Data
      this.doCommit(pageContext);
      pageContext.putTransactionValue("prmReturnUrl", getModifiedCurrentUrlForRedirect(pageContext, true));

      this.modifyCurrentBreadcrumbLink(pageContext, true, pageTitle, true);
    }

    // Additional Info. Flexfield Code for Sales Team
    // Following Event fires when a Row is selected on the SalesTeam table
    // Check for the Event when the Fire Action happens on the single selection
    else if ("ASNLeadSTSelFA".equals(oaActEvt))
    {
      // Get a handle to the Header Bean of the Sales Team Additional Info region
      OAHeaderBean stBean=(OAHeaderBean)webBean.findChildRecursive("ASNSTAddInfoHdrRN");
      // Check if the Stacked Layout is Rendered (user may have personalized)
      // Execute further code only if the StackLayout Bean is rendered

      if(stBean.isRendered())
      {
        // Invoke the method in the AM that sets the Row selected as a Current Row in the VO
        oam.invokeMethod("refreshSalesteamDetailsRow");
        HashMap stUrlParams = new HashMap();
        String stLeadId = (String)pageContext.getTransactionValue("ASNTxnLeadId");
        stUrlParams.put("ASNReqFrmLeadId",stLeadId.toString());

        // Use the following Line of Code as workaround for Bug # 3274685
        // pageContext.forwardImmediately(PageFunctionName,MenuContext, MenuName, urlParams, RetainAM,BreadCrumb);
        // This has been handled in the processTargetURL
        pageContext.putParameter("ASNReqPgAct", "REFRESH");
        this.processTargetURL(pageContext, null, null);
      }
    }

    // Handle the sort event on the sales team table
    else if(SORT_EVENT.equals(pageContext.getParameter(EVENT_PARAM)))
    {
      String source = pageContext.getParameter(this.SOURCE_PARAM);
      OAAdvancedTableBean stTable = (OAAdvancedTableBean)webBean.findIndexedChildRecursive("ASNSTLstTb");
      if(stTable!=null)
      {
        String name = stTable.getName(pageContext);
        if(name.equals(source))
        {
          // Get a handle to the Header Bean of the Sales Team Additional Info region
          OAHeaderBean stBean1=(OAHeaderBean)webBean.findChildRecursive("ASNSTAddInfoHdrRN");
          // Refresh only if the additional info. is rendered
          if(stBean1.isRendered())
          {
            pageContext.putParameter("ASNReqPgAct","REFRESH");
            pageContext.setForwardURLToCurrentPage(null, true, ADD_BREAD_CRUMB_SAVE,OAException.WARNING);
          }
         }
      }
    }

    // Handling the View History Button
    else if(pageContext.getParameter("ASNPageHistButton")!=null)
    {
      String leadId = pageContext.getParameter("ASNReqFrmLeadId");

      this.doCommit(pageContext);
      oam.invokeMethod("resetQuery", new Serializable[]{"LeadHeaderDetailsVO"});
      // pageContext.putParameter("ASNReqPgAct", "SUBFLOW");
      pageContext.putParameter("ASNReqPgAct", "LEADHIST");

      HashMap conditions = new HashMap(4);
      conditions.put(ASNUIConstants.RETAIN_AM, "Y");
      conditions.put(ASNUIConstants.BC_CURRENT_LINK, ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
      conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT, pageTitle);
        // set the required sub-flow specific parameters
      HashMap urlParams = new HashMap(3);
      urlParams.put("ASNReqFrmFuncName", "ASN_LEADHISTTRACKINGPG");
      urlParams.put("ASNReqFrmLeadId", leadId);

      // Debug Logging
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(200);
        buf.append(" View History Button - Parameters being passed to processTargetURL -  ");
        buf.append(" conditions : ");
        buf.append(conditions.toString());
        buf.append(" urlParams : ");
        buf.append(urlParams.toString());
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      } // End Debug Logging

      this.processTargetURL(pageContext, conditions, urlParams);
    }

    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }

  }

}
