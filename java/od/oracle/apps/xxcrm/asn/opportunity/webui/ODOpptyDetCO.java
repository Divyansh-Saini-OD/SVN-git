/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODOpptyDetCO.java                                             |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Controller Object for the Opportunity Details Page.                    |
 |                                                                           |
 |  NOTES                                                                    |
 |         Used for the Customization on the Opportunity Details Page        |
 |         Modified to pass the Party and Site Search Criteria               |
 |         to the Add Contact Page and Party Site Id                         |
 |         to the Create Contact page                                        |
 |  DEPENDENCIES                                                             |
 |    No dependencies.                                                       |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    12-Sep-2007 Jasmine Sujithra   Created                                 |
 |    12-Dec-2007 Jasmine Sujithra   Modified to use Profile to get          |
 |                                   match rule name                         |
 |    14-Dec-2007 Satyasrinivas      Changes for passing address id to task. |
 |    01-Feb-2008 Anirban        Modified for contacts and customer security |
 |    Mar 13,2009  Mohan K         Defect# 13687 Enhancements to SFA Account |
 |                          Setup link provided from Opportunity Setup page  |
 |    27-Mar-2009  Prasad Devar      Added new Subtab for Contact Strategy   |
 |    04-May-2009  Anirban           Fixed defect#14491.                     |
 |    08-May-2009  Anirban           Fixed defect#14901.                     |
 |    12-May-2009  Anirban           Fixed defect#14801.                     |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.opportunity.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.asn.opportunity.server.OpportunityDetailsVORowImpl;
import com.sun.java.util.collections.HashMap;
import java.util.Hashtable;
import java.io.Serializable;
import oracle.apps.asn.common.webui.ASNUIUtil;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;
import oracle.apps.fnd.framework.webui.beans.table.OAAdvancedTableBean;
import oracle.jbo.domain.Number;
import oracle.apps.asn.common.fwk.webui.ASNUIConstants;
import oracle.apps.fnd.framework.webui.OADataBoundValueViewObject;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OABodyBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.jbo.Row;
import oracle.apps.fnd.framework.webui.beans.layout.OAStackLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OASubTabLayoutBean;
import oracle.apps.fnd.framework.webui.beans.nav.OALinkBean;
import oracle.apps.fnd.framework.webui.beans.nav.OASubTabBarBean;
import od.oracle.apps.xxcrm.asn.common.fwk.webui.ODASNControllerObjectImpl;
import od.oracle.apps.xxcrm.asn.opportunity.server.*;

import od.oracle.apps.xxcrm.customer.account.server.ODCustomerAccountsVOImpl;
import od.oracle.apps.xxcrm.customer.account.server.ODCustomerAccountsVORowImpl;
import oracle.apps.asn.common.fwk.server.ASNViewObjectImpl;

/**
 * Controller for ...
 */
public class ODOpptyDetCO extends ODASNControllerObjectImpl
{
  public static final String RCS_ID="$Header: /home/cvs/repository/Office_Depot/SRC/CRM/E1307_SiteLevel_Attributes_ASN/3.\040Source\040Code\040&\040Install\040Files/E1307D_SiteLevel_Attributes_(LeadOpp_CreateUpdate)/ODOpptyDetCO.java,v 1.5 2007/10/19 08:11:31 jsujithra Exp $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.opportunity.webui.ODOpptyDetCO.processRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);

    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processRequest(pageContext, webBean);




    /*
     * refer to bug 3145454. code to fix the PPR non-queuing behavior
     */
   OAWebBean body = pageContext.getRootWebBean();
   if (body instanceof OABodyBean)
     body.setAttributeValue(OAWebBeanConstants.FIRST_CLICK_PASSED_ATTR,
                                                               Boolean.TRUE);

    /*
     * *************************************************************************
     * Retrieve the required ID here
     * The ID can be from framework parameters or proposal object ID
     * *************************************************************************
     */

    String keyId = pageContext.getParameter("ASNReqFrmOpptyId");
    if(keyId == null || keyId.equals(""))
    {
      keyId = pageContext.getParameter("PRPObjectId");
    }

    /** Since some of the framework parameters are not returned by PRP page in their return
     *  flow, these parameters have been maintained in transaction/session, which'll have
     *  to be set back explicitly in page context/URL. Fix for bug 3841055 which is
     *  ASNS2R10:UNEXPECTED ERROR SEEN WHEN ADDING A NEW OWNER TO OPP WITH PROPOSAL
     **/

    if (keyId == null)
    {
       keyId = (String) pageContext.getTransactionValue("ASNTxnOppId");
       pageContext.putTransactionValue("ASNReqFrmOpptyId", keyId);
    }

    if(keyId == null)
    {
      throw new OAException("ASN","ASN_CMMN_REQKEY_MISS_ERR");
    }
   if (keyId !=null)
   {
    if (isStatLogEnabled)
    {

      StringBuffer buf = new StringBuffer(300) ;
      buf.append("Opportunity ID= ");
      buf.append(keyId);
      pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
    }
   }

    /*
     * *************************************************************************
     * Run the query here
     * And get information of the queried record
     * *************************************************************************
     */
    OAApplicationModule am = (OAApplicationModule) pageContext.getApplicationModule(webBean);


    boolean queryDetails = "Y".equals(pageContext.getParameter("ASNReqNewSelectionFlag"));
    if (queryDetails)
    {
      am.invokeMethod("resetQuery");
    }

    Class [] classDefs = {String.class, Boolean.class};
    Serializable [] params = {keyId, Boolean.FALSE};
    am.invokeMethod("initQuery", params, classDefs);

    Hashtable ht = (Hashtable) am.invokeMethod("getOpptyAttributes");
    // getting customer ID, oppID, title and contact party ID
    Number customerId = (Number) ht.get("CustomerId");
    Number opptyId = (Number) ht.get("LeadId");
    Number relPtyId = (Number) ht.get("RelationshipPartyId");
    String title = (String) ht.get("Description");
    String srcFlag = (String) ht.get("SourceNameUpdFlag");

    if (isStatLogEnabled)
    {
      StringBuffer buf = new StringBuffer(400) ;
      buf.append("  Customer ID= ");
      buf.append(customerId);
      buf.append("  Opportunity ID= ");
      buf.append(opptyId);
      buf.append("  Rel. Party ID= ");
      buf.append(relPtyId);
      buf.append("  Source Flag= ");
      buf.append(srcFlag);
      pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
    }

    if(customerId == null || title== null || opptyId == null)
    {
      throw new OAException("ASN","ASN_CMMN_REQKEY_MISS_ERR");
    }
    //Check for new customer
    String custId = pageContext.getOANLSServices().NumberToString(customerId);
    String selCustId = pageContext.getParameter("ASNReqSelCustId");
    String selCustName = pageContext.getParameter("ASNReqSelCustName");
    if (selCustId!=null)
    {
      if (!selCustId.equals(custId))
      {
        pageContext.putParameter("ASNReqPgAct","SUBFLOW");
        pageContext.putParameter("ASNReqFrmOpptyId", opptyId);
        pageContext.putParameter("ASNReqFrmCustId", selCustId);
        pageContext.putParameter("ASNReqFrmCustNm", selCustName);

        HashMap conditions = new HashMap();
        conditions.put(ASNUIConstants.RETAIN_AM,"Y");

        HashMap urlParams = new HashMap();
        urlParams.put("ASNReqFrmFuncName","ASN_CUSTCONFPG");
        urlParams.put("ASNReqFrmOpptyId",opptyId.toString());
        this.processTargetURL(pageContext,conditions, urlParams);
      }
    }

    /*
     * *************************************************************************
     * Add contact to the opportunity if the user is coming from contact
     * create page
     * *************************************************************************
     */
    String selCtctId = pageContext.getParameter("ASNReqSelCtctId");
    String selRelPtyId = pageContext.getParameter("ASNReqSelRelPtyId");
    String selRelId = pageContext.getParameter("ASNReqSelRelId");

    if(selCtctId != null && selRelPtyId != null && selRelId != null)
    {
       if (isStatLogEnabled)
       {
         StringBuffer buf = new StringBuffer(300) ;
         buf.append("  Selected Contact ID= ");
         buf.append(selCtctId);
         buf.append("  Selected Rel. Party ID= ");
         buf.append(selRelPtyId);
         buf.append("  Rel. Party ID= ");
         buf.append(relPtyId);
         pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
       }
      Serializable [] aparams = {selRelPtyId};
      am.invokeMethod("addContact",aparams);
    }

    /*
     * *************************************************************************
     * Add address to the opportunity
     * *************************************************PartySiteId************************
     */
    String selPSId = pageContext.getParameter("ASNReqSelPartySiteId");
    String selAddress = pageContext.getParameter("ASNReqSelAddress");

    if(selPSId != null && selAddress != null)
    {
      if (isStatLogEnabled)
       {
        StringBuffer buf = new StringBuffer(200) ;
         buf.append("  Selected Party Site ID= ");
         buf.append(selPSId);
         buf.append("  Selected Address = ");
         buf.append(selAddress);
         buf.append("  Before invoking selectAddress function.. ");
         pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
       }
      Serializable [] aparams = {selPSId, selAddress};
      am.invokeMethod("selectAddress",aparams);
       if (isStatLogEnabled)
       {
        StringBuffer buf = new StringBuffer(300) ;
         buf.append("  After invoking selectAddress function ");
         pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
       }
    }

    /*
     * ************ *************************************************************
     * perform security check on opportunity & customer
     * *************************************************************************
     */
    String secFlag = this.processAccessPrivilege(pageContext,
                       ASNUIConstants.OPPORTUNITY_ENTITY,opptyId.toString());
    pageContext.putTransactionValue("ASNTxnOpptyAcsMd",secFlag);
    String custSecFlag = this.checkAccessPrivilege(pageContext,
                           ASNUIConstants.CUSTOMER_ENTITY,
                           customerId.toString(),false);
    pageContext.putTransactionValue("ASNTxnCustAcsMd",custSecFlag);

     if (isStatLogEnabled)
       {
         StringBuffer buf = new StringBuffer(200) ;
         buf.append("  Security flag = ");
         buf.append(secFlag);
         buf.append("  Customer Security Flag = ");
         buf.append(custSecFlag);
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
       }

   // PRM Integration, populate the Read Only parameter for PRM.
    if(ASNUIConstants.READ_ACCESS.equals(secFlag))

     {
       pageContext.putTransactionValue("PvOpptyReadOnly", "Y");
     }
    else
     {
       pageContext.putTransactionValue("PvOpptyReadOnly", "N");
     }

    /*
     * *****************************************************
     * create sales cycle data
     * *****************************************************
     */
    Serializable [] scParams = {secFlag};
    am.invokeMethod("createSalesCycle", scParams);

     if (isStatLogEnabled)
       {
         StringBuffer buf = new StringBuffer(300) ;
         buf.append("  Before Invoking initPPR function = ");
         pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
       }
    /*
     * initialize PPR parameters
     */
    Serializable [] pparams = {secFlag, custSecFlag, srcFlag};
    am.invokeMethod("initPPR", pparams);

     if (isStatLogEnabled)
       {
         StringBuffer buf = new StringBuffer(300) ;
         buf.append("  After Invoking initPPR function = ");
         pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
       }


      // Flex code

     // Check whether the Sales Team Addition Info. Flexfield Region is Rendered
        OAHeaderBean stBean=(OAHeaderBean)webBean.findChildRecursive("ASNSTAddInfoHdrRN");
        if(stBean.isRendered())
        {
          // Refresh the Current Row or set the first row
          am.invokeMethod("refreshSalesteamDetailsRow");
          /********  Set the SalesTeam related UI attributes  ********/
          am.invokeMethod("setOpptyDetSTProperties", new Serializable[]{
                                                          "Y"
                                                         });

        }
        else
        {
          /********  Set the SalesTeam related UI attributes  ********/
          am.invokeMethod("setOpptyDetSTProperties", new Serializable[]{
                                                          "N"
                                                         });
        }


      // Code for Projects Integration
      OAHeaderBean prjHeaderBean = (OAHeaderBean) webBean.findChildRecursive("ASNPrjLstTable");
      if (prjHeaderBean.isRendered())
      //if (prjHeaderBean != null)
      {
        pageContext.putTransactionValue("ASNTxnOpptyPrjDspInfo", "Y");
      }
      else
      {
         pageContext.putTransactionValue("ASNTxnOpptyPrjDspInfo", "N");
      }





    /*
     * *************************************************************************
     * Change the page UI here.
     * *************************************************************************
     */
    //Control for View History button
    /*String viewHistory = (String) pageContext.getProfile("ASN_OPPTY_HIST_TRACK");
    if ( "Y".equals( viewHistory ) )
    {
      OASubmitButtonBean viewHistoryBean = (OASubmitButtonBean)webBean.findChildRecursive("ASNViewHistButton");
      viewHistoryBean.setRendered(true);
    }
    else
    {
      OASubmitButtonBean viewHistoryBean = (OASubmitButtonBean)webBean.findChildRecursive("ASNViewHistButton");
      viewHistoryBean.setRendered(false);
    }*/


    // ppr related
    OAMessageChoiceBean opptyDetMethBean = (OAMessageChoiceBean) webBean.findIndexedChildRecursive("ASNOpptyDetMeth");
    if (opptyDetMethBean != null)
    {
      opptyDetMethBean.setAttributeValue(STYLE_CLASS_ATTR,
        new OADataBoundValueViewObject(opptyDetMethBean,"METH_CSS","OpptyDetAppPropertiesVO1"));
    }

    OAMessageTextInputBean opptyDetFrcstBean = (OAMessageTextInputBean) webBean.findIndexedChildRecursive("ASNOpptyDetFrcstAmt");
    if (opptyDetFrcstBean != null)
    {
      opptyDetFrcstBean.setAttributeValue(STYLE_CLASS_ATTR,
        new OADataBoundValueViewObject(opptyDetFrcstBean,"FRCST_CSS","OpptyDetAppPropertiesVO1"));
    }

    // Change the page title here
    MessageToken[] tokens = { new MessageToken("NAME", title) };
    String titlePrefix = pageContext.getMessage("ASN","ASN_OPPTY_DETPG_TITLE", tokens);
    ((OAPageLayoutBean)webBean).setTitle(titlePrefix);

     //Setting wrap for the address field in read only mode
      if(ASNUIConstants.READ_ACCESS.equals(secFlag))
      {
       OAMessageTextInputBean addressBean = (OAMessageTextInputBean) webBean.findIndexedChildRecursive("ASNOpptyDetAddr");
        if (addressBean != null)
        {
          addressBean.setWrap(SOFT_WRAP);
        }
      }

    //close reason display
    OAMessageChoiceBean closeReason = (OAMessageChoiceBean) webBean.findIndexedChildRecursive("ASNOpptyDetRsn");
    OAMessageChoiceBean status = (OAMessageChoiceBean) webBean.findIndexedChildRecursive("ASNOpptyDetStatus");
    if(closeReason != null && status != null)
    {
      if(status.isRendered())
      {
        closeReason.setRendered(true);
      }
    }

    // if methodology is defined, set it as readonly, otherwise attach a javascript
    // to the methodology dropdown to refresh the page and hide sales cycle tab
    String salesMethFlag = (String) ht.get("SalesMethFlag");
    if(!"Y".equals(salesMethFlag))
    {
      // hide sales cycle
      this.hideSubtab(pageContext,webBean,"ASNOpptyDetSubtab","ASNSCHdrRN");
      // hide the sales cycle table - if it is not used under sale cycle sub-tab
      OAWebBean scStackBean = webBean.findIndexedChildRecursive("ASNSCStgStack");
      if(scStackBean!=null)
      {
        scStackBean.setRendered(false);
      }
    }

    // format amount text based on opportunity currency
    OAMessageStyledTextBean amtBean = (OAMessageStyledTextBean) webBean.findIndexedChildRecursive("ASNOpptyDetAmt");
    if(amtBean != null)
    {
      amtBean.setAttributeValue(CURRENCY_CODE,
        new OADataBoundValueViewObject(amtBean, "CurrencyCode"));
    }

    // format forecast amount text based on opportunity currency
    OAMessageTextInputBean frcstAmtBean = (OAMessageTextInputBean) webBean.findIndexedChildRecursive("ASNOpptyDetFrcstAmt");
    if(frcstAmtBean != null)
    {
      frcstAmtBean.setAttributeValue(CURRENCY_CODE,
        new OADataBoundValueViewObject(frcstAmtBean, "CurrencyCode"));
    }



     // Make sales group dropdown of sales team tab dynamic based on resource ID of each row
    //  BUG 4085315 - GSICU11510.29: ASN:END_DATED RESOURCES ARE SHOWING UP IN SALES TEAM
   //   As part of this fix the group id is also pased to the poplist vo to

    OAMessageChoiceBean groupBean = (OAMessageChoiceBean)webBean.findIndexedChildRecursive("ASNSTGroup");
    OAAdvancedTableBean STBean = (OAAdvancedTableBean)webBean.findIndexedChildRecursive("ASNSTLstTb");
    if(groupBean != null && STBean != null)
    {
      groupBean.setListVOBoundContainerColumn(0,STBean,"ASNSTRscId");
      groupBean.setListVOBoundContainerColumn(1, STBean,"ASNSTGroupId");
    }

//----------------   Mohan Changes Start ----------------------------------
// Mohan 3/13/2009  Defect# 13687 Enhancements to SFA
// Account Setup link provided from Opportunity Setup page

      //Anirban starts fix for defect#14491

      String errMsg = "N";

	  String banPartyId = custId;

      OAViewObject ODCustomerAccountsVO = (OAViewObject)am.findViewObject("ODCustomerAccountsVO");
      if ( ODCustomerAccountsVO == null )
	  ODCustomerAccountsVO = (OAViewObject)am.createViewObject("ODCustomerAccountsVO","od.oracle.apps.xxcrm.customer.account.server.ODCustomerAccountsVO");

      if(ODCustomerAccountsVO == null)
      {
	   pageContext.writeDiagnostics(METHOD_NAME, "Anirban: ODCustomerAccountsVO is still NULL",  OAFwkConstants.STATEMENT);
	   pageContext.writeDiagnostics(METHOD_NAME, "Anirban: party id is : "+banPartyId,  OAFwkConstants.STATEMENT);
	  }

      if ( ODCustomerAccountsVO != null )
	  {
       ODCustomerAccountsVO.setWhereClause(null);
	   ODCustomerAccountsVO.setWhereClauseParams(null);
       ODCustomerAccountsVO.setWhereClauseParam(0, custId);
       ODCustomerAccountsVO.executeQuery();
	   pageContext.writeDiagnostics(METHOD_NAME, "Anirban: party id is : "+banPartyId,  OAFwkConstants.STATEMENT);
	  }

      ODCustomerAccountsVORowImpl rowban = (ODCustomerAccountsVORowImpl)ODCustomerAccountsVO.first();

      if(rowban == null)
      {
	   pageContext.writeDiagnostics(METHOD_NAME, "Anirban: rowban is NULL",  OAFwkConstants.STATEMENT);
	  }

      while (rowban != null)
      {
       pageContext.writeDiagnostics(METHOD_NAME, "Anirban: inside rowban != null ",  OAFwkConstants.STATEMENT);
       if (rowban.getAccountNumber() != null)
       {
        pageContext.writeDiagnostics(METHOD_NAME, "Anirban: If Account Number exists make the accounts subtab hidden",  OAFwkConstants.STATEMENT);
        errMsg = "Y";
        
       }
       rowban  = (ODCustomerAccountsVORowImpl)ODCustomerAccountsVO.next();
      }

	  pageContext.writeDiagnostics(METHOD_NAME, "Anirban value of errMsg is :"+errMsg,  OAFwkConstants.STATEMENT);

     //Anirban ends fix for defect#14491

      // ******* Custom code starts here
      // Code to add Customer Accounts Tab in Customer details page.
      pageContext.putParameter("pid",custId );


      //Anirban starts fix for defect#14491

      if (errMsg.equals("N"))
      {
       OASubTabLayoutBean tabBean = (OASubTabLayoutBean)webBean.findChildRecursive("ASNOpptyDetSubtab");
       OAStackLayoutBean accountSetup = new OAStackLayoutBean();
       accountSetup.setText("Account Setup");
       OASubTabBarBean subTabBean = (OASubTabBarBean)webBean.findChildRecursive("ASNOpptyDetSubtabBar");

       //Code for Account Setup Tab
       OAStackLayoutBean accountSetupRegion= (OAStackLayoutBean)createWebBean(pageContext,
                   "/od/oracle/apps/xxcrm/asn/common/customer/webui/ODOrgAccountSetupRN",
                   "AccountSetupRN",
                   true);
       OALinkBean accountSetupLink = new OALinkBean();
       accountSetupLink.setText("Account Setup");
       accountSetupLink.setID("AccountSetupTab");
       tabBean.addIndexedChild(accountSetupRegion);
       subTabBean.addIndexedChild(accountSetupLink);
	  }

	  //Anirban ends fix for defect#14491
//----------------   Mohan Changes End ----------------------------------




    // PRM related code

  //   String prmReturnUrl = this.getModifiedCurrentUrlForRedirect(pageContext);

//    pageContext.putTransactionValue("prmReturnUrl",prmReturnUrl);


    /*
     * *************************************************************************
     * Integration
     * *************************************************************************
     */

    // for integration with other region
    pageContext.putTransactionValue("ASNTxnCustomerId",customerId.toString());
    pageContext.putTransactionValue("ASNTxnOppId", opptyId.toString());
    if(ASNUIConstants.READ_ACCESS.equals(secFlag)||"PERSON".equals(getCustomerType(pageContext, customerId.toString())))
    {
      pageContext.putTransactionValue("ASNTxnSugCtctReadOnly", "Y");
    }
    else
    {
      pageContext.putTransactionValue("ASNTxnSugCtctReadOnly", "N");
    }
    pageContext.putTransactionValue("ASNTxnSugCtctDestVUN", "OpportunityContactDetailsVO1");

    // integration with sales cycle region
    Number methId = (Number) ht.get("SalesMethodologyId");
    if(methId != null)
    {
        if (isStatLogEnabled)
       {
        StringBuffer buf = new StringBuffer(300) ;
         buf.append("  Methodology ID = ");
         buf.append(methId);
         pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
       }

      pageContext.putTransactionValue("ASNTxnSCObjectType", "OPPORTUNITY");
      pageContext.putTransactionValue("ASNTxnSCObjectId", opptyId.toString());
      pageContext.putTransactionValue("ASNTxnSCMethId",methId.toString());
      Number stageId = (Number) ht.get("SalesStageId");
      if(stageId!=null)
      {
       if (isStatLogEnabled)
       {
         StringBuffer buf = new StringBuffer(250) ;
         buf.append("  Stage ID = ");
         buf.append(stageId);
         pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
       }
        String stageIdStr = stageId.toString();
        pageContext.putTransactionValue("ASNTxnSCStageId", stageIdStr);
      }

      if(ASNUIConstants.READ_ACCESS.equals(secFlag))
        pageContext.putTransactionValue("ASNTxnSCReadOnlyFlag", "Y");
      else
        pageContext.putTransactionValue("ASNTxnSCReadOnlyFlag", "N");

      String currencyCode = (String) ht.get("CurrencyCode");
      if(currencyCode != null)
         pageContext.putTransactionValue("ASNTxnSCCurrencyCd", currencyCode);
      else
         pageContext.removeTransactionValue("ASNTxnSCCurrencyCd");
    }

    // integration with note
    pageContext.putTransactionValue("ASNTxnNoteSourceCode","OPPORTUNITY");
    pageContext.putTransactionValue("ASNTxnNoteSourceId",opptyId.toString());
    pageContext.putTransactionValue("ASNTxnNoteReturnUrl", getModifiedCurrentUrlForRedirect(pageContext, true));

    String lookupParam = "ASN_OPPTY_VIEW_NOTES;0";
    pageContext.putTransactionValue("ASNTxnNoteLookup",lookupParam);

    String poplistParamList = "CUSTOMER;"+customerId.toString();
    pageContext.putTransactionValue("ASNTxnNoteParamList",poplistParamList);

    String poplistTypeList = "CUSTOMER;PARTY";
    pageContext.putTransactionValue("ASNTxnNoteTypeList",poplistTypeList);

    if(ASNUIConstants.READ_ACCESS.equals(secFlag))
    {
      pageContext.putTransactionValue("ASNTxnNoteReadOnly", "Y");
    }
    else
    {
      pageContext.putTransactionValue("ASNTxnNoteReadOnly", "N");
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

    // PRM Notes integration
      // Passing the values only if the opportunity id is present.
      if(opptyId  !=  null)
      {

        pageContext.putTransactionValue("PVTxnNoteSourceId", opptyId.toString());
        pageContext.putTransactionValue("PVTxnNoteSourceCode", "OPPORTUNITY");

        // Below code sets the access to notes region based on security
        if(ASNUIConstants.READ_ACCESS.equals(secFlag))
        {
          pageContext.putTransactionValue("PVTxnNoteReadOnly", "Y");
        }
        else
        {
          pageContext.putTransactionValue("PVTxnNoteReadOnly", "N");
        }
      }

   // Integration with PRM here
      if(opptyId  !=  null)
      {
        pageContext.putTransactionValue("PvLeadId", opptyId.toString());
      }

      if(customerId != null)
      {
        pageContext.putTransactionValue("PvCustomerId", customerId.toString());
      }

      Number AddressId = (Number) ht.get("AddressId ");
      if(AddressId != null)
      {
        pageContext.putTransactionValue("PvCustomerAddrId", AddressId.toString());
      }

    // Integration with task here
    if(ASNUIConstants.READ_ACCESS.equals(secFlag))
    {
      pageContext.putTransactionValue("cacTaskTableRO", "Y");
      pageContext.putTransactionValue("cacTaskReadOnlyPPR","Y");
    }
    else
    {
      pageContext.putTransactionValue("cacTaskTableRO", "N");
      pageContext.putTransactionValue("cacTaskReadOnlyPPR","N");
    }
    pageContext.putTransactionValue("cacTaskSrcObjCode","OPPORTUNITY");
    pageContext.putTransactionValue("cacTaskSrcObjId",opptyId.toString());
    pageContext.putTransactionValue("cacTaskCustId",customerId.toString());
     /****  OD - Address ID sending changes ****/
	  String sql1 = "select address_id from as_leads_all where lead_id = :1";
	  		  		 OAApplicationModule oamaddr = pageContext.getRootApplicationModule();
	  		  		 oracle.jbo.ViewObject pSitevo4 = oamaddr.findViewObject("pSiteVO4");
	  		  		             if (pSitevo4 == null )
	  		  		             {
	  		  		               pSitevo4 = oamaddr.createViewObjectFromQueryStmt("pSiteVO4", sql1);
	  		  		             }

	  		  		             if (pSitevo4 != null)
	  		  		             {
	  		  		                 pSitevo4.setWhereClauseParams(null);
	  		  		                 pSitevo4.setWhereClauseParam(0,opptyId);
	  		  		                 pSitevo4.executeQuery();
	  		  		                 pSitevo4.first();
	  		  		                 String Addressid = pSitevo4.getCurrentRow().getAttribute(0).toString();
	  		  		                 pSitevo4.remove();
	  	  		                 pageContext.putTransactionValue("cacTaskCustAddressId", Addressid);
							 }

    if(relPtyId == null)
    {
      pageContext.putTransactionValue("cacTaskContactId","");
    }
    else
    {
      pageContext.putTransactionValue("cacTaskContactId",relPtyId.toString());
    }
    pageContext.putTransactionValue("cacTaskContDqmRule",(String) pageContext.getProfile("HZ_DQM_CON_SIMPLE_MATCHRULE"));
    pageContext.putTransactionValue("cacTaskNoDelDlg","Y");
    pageContext.putTransactionValue("cacTaskReturnUrl", getModifiedCurrentUrlForRedirect(pageContext, true));

    //attachment integration here
    OAMessageStyledTextBean attchAmtBean = (OAMessageStyledTextBean) webBean.findIndexedChildRecursive("ASNOpptyAttchAmt");
    if(attchAmtBean != null)
    {
      attchAmtBean.setAttributeValue(CURRENCY_CODE,new OADataBoundValueViewObject(amtBean, "CurrencyCode"));
    }
    OAMessageStyledTextBean attchFrcstAmtBean = (OAMessageStyledTextBean) webBean.findIndexedChildRecursive("ASNOpptyAttchFrcstAmt");
    if(attchFrcstAmtBean != null)
    {
      attchFrcstAmtBean.setAttributeValue(CURRENCY_CODE,new OADataBoundValueViewObject(amtBean, "CurrencyCode"));
    }

    boolean updateable = ASNUIConstants.UPDATE_ACCESS.equals(secFlag);
    ASNUIUtil.attchSetUp(pageContext
                        ,webBean
                        ,updateable
                        ,"ASNSubtabAttchTable"
                        ,"ASNOpptyAttchContextHolderRN"
                        ,"ASNOpptyAttchContextRN");

    ASNUIUtil.attchSetUp(pageContext
                        ,webBean
                        ,updateable
                        ,"ASNDetAttchTable"
                        ,"ASNOpptyAttchContextHolderRN"
                        ,"ASNOpptyAttchContextRN");

 /* Added Custom Code for ASN Party Site Attributes */

    OAApplicationModule oaapplicationmodule = pageContext.getRootApplicationModule();
    OAViewObject oaviewobject = (OAViewObject)oaapplicationmodule.findViewObject("OpportunityDetailsVO1");

    if(oaviewobject == null)
    {
            MessageToken amessagetoken[] = {
                new MessageToken("NAME", "OpportunityDetailsVO1")
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
    }
    OpportunityDetailsVORowImpl opportunitydetailsvorowimpl = (OpportunityDetailsVORowImpl)oaviewobject.first();
    Object addressobj = (Object)opportunitydetailsvorowimpl.getAttribute("AddressId");
/// Added code to get source info
 Object srcCdObj = (Object)opportunitydetailsvorowimpl.getAttribute("SourceCode");


    
    String addressid =addressobj.toString();
    if (isStatLogEnabled)
    {
        pageContext.writeDiagnostics(METHOD_NAME,"Value of AddressId is :"+addressid, 1);
    }

    if(addressid != null)
        pageContext.putTransactionValue("ASNPartySiteId", addressid);
    else
        pageContext.removeTransactionValue("ASNPartySiteId");


//----------------   Prasad Changes Start ---------------------/
      // ******* Custom code starts here
      // Code to add Feedback Tab in Opp details page.


 if (!pageContext.isFormSubmission())
    {
      if(srcCdObj !=null){
      ///Check for source Object IF applicible for Feedback
      oracle.apps.asn.opportunity.server.OpptyDetAMImpl  oppAM =(oracle.apps.asn.opportunity.server.OpptyDetAMImpl )am;
      OAApplicationModule oam = (OAApplicationModule)oppAM;
       oracle.apps.fnd.framework.OAViewObject oaviewobject2 = (oracle.apps.fnd.framework.OAViewObject)oam.findViewObject("ODSCSSourcesVO");
       java.lang.StringBuffer stringbuffer2 = new StringBuffer(1000);
       stringbuffer2.append("  SELECT SOC.source_code  AS  \"Code\" , CAMPT.campaign_name AS \"Value\"  FROM  ");
       stringbuffer2.append("                    AMS_SOURCE_CODES     SOC, ");
       stringbuffer2.append("                    AMS_CAMPAIGNS_ALL_TL CAMPT, ");
       stringbuffer2.append("                    AMS_CAMPAIGNS_ALL_B  CAMPB, ");
       stringbuffer2.append("                    apps.FND_LOOKUP_VALUES    LKP ");
       stringbuffer2.append("                      WHERE ");
       stringbuffer2.append("                      SOC.arc_source_code_for = 'CAMP' ");
       stringbuffer2.append("                      AND SOC.active_flag = 'Y' ");
       stringbuffer2.append("                      AND SOC.source_code_for_id = campb.campaign_id ");
       stringbuffer2.append("                      AND CAMPB.campaign_id = campt.campaign_id ");
       stringbuffer2.append("                      AND CAMPB.status_code IN('ACTIVE',    'COMPLETED') ");
       stringbuffer2.append("                      AND CAMPT.LANGUAGE = userenv('LANG') ");
       stringbuffer2.append("                      AND   LKP.lookup_type = 'XXSCS_POT_TYPE_SOURCE_MAP' ");
       stringbuffer2.append("                      AND ltrim(rtrim(upper(replace(LKP.description,chr(9),''))))  = ltrim(rtrim(upper(replace(CAMPT.campaign_name,chr(9),'')))) ");
       stringbuffer2.append("                      AND SOC.source_code = ");
       stringbuffer2.append("'"+srcCdObj.toString()+"'");
       oracle.apps.fnd.framework.server.OAViewDefImpl oaviewdefimpl = (oracle.apps.fnd.framework.server.OAViewDefImpl)oam.getOADBTransaction().createViewDef();
       oaviewdefimpl.setSql(stringbuffer2.toString());
       oaviewdefimpl.setExpertMode(true);
       oaviewdefimpl.setFullName("oracle.apps.asn.lead.server.ODSCSSourcesVO");
       oaviewdefimpl.addSqlDerivedAttrDef("Code", "FDK_CODE", "java.lang.String", 12, false, false, (byte)0, 200);
       oaviewdefimpl.addSqlDerivedAttrDef("Value", "FDK_VALUE", "java.lang.String", 12, false, false, (byte)0, 200);
      if(oaviewobject2!=null)
        {
          oaviewobject2.remove();
        }
       oaviewobject2 = (oracle.apps.fnd.framework.OAViewObject) oppAM.createViewObject("ODSCSSourcesVO", ((oracle.apps.fnd.framework.server.OAViewDef)oaviewdefimpl));
       oaviewobject2.setPassivationEnabled(false);
      
       ((oracle.apps.fnd.framework.server.OAViewObjectImpl)oaviewobject2).setFetchSize((short)50);
      
        if(!oaviewobject2.isPreparedForExecution())
        {
            oaviewobject2.executeQuery();
        }


      Row oaRow = (Row)oaviewobject2.first();
         if(oaRow!=null )
          {      //SupTab to Page creation
              OASubTabLayoutBean opptabBean = (OASubTabLayoutBean)webBean.findChildRecursive("ASNOpptyDetSubtab");
              OASubTabBarBean oppsubTabBean = (OASubTabBarBean)webBean.findChildRecursive("ASNOpptyDetSubtabBar");
              OAStackLayoutBean feedbackSetup = new OAStackLayoutBean();
              feedbackSetup.setText("Feedback History" );
              OAStackLayoutBean feedbackRegion= (OAStackLayoutBean)createWebBean(pageContext,
                   "/od/oracle/apps/xxcrm/scs/fdk/webui/ODSCSFdkHstryRN",
                   "FeedbackRN",
                   true);
                   feedbackSetup.addIndexedChild(feedbackRegion);
                 OALinkBean feedbackLink = new OALinkBean();
                 feedbackLink.setText("Feedback History");
                 feedbackLink.setFireActionForSubmit("update", null, null, true, true);
                 feedbackLink.setID("FeedbackTab");
                            opptabBean.addIndexedChild(feedbackSetup);
                  oppsubTabBean.addIndexedChild(feedbackLink);
                                String src=pageContext.getParameter("SCSReqFrmSrc") ;

                  // seting the Notes & Task as default for Contact Strategy  
   if (!pageContext.isFormSubmission())
    {
                 if(src!=null &&!src.equals(""))
                    if(src.equals("CS"))
                    {
                      OALinkBean noteTaskHdrLnk = (OALinkBean) webBean.findChildRecursive("ASNNoteTaskHdrLnk");
                    //  noteTaskHdrLnk.setSelected(true);
                      opptabBean.setSelectedIndex(pageContext,"ASNNoteTaskHdrRN");
                      pageContext.putParameter("SCSReqFrmSrc","");
                    }
    }
                        
             }
             
      }
    }
      
     
//----------------   Prasad Changes End ----------------------------------


    /* End Of Custom Code */

    //Anirban: starts defect fix #14801
    OAWebBean asnCtctAddButton = webBean.findChildRecursive("ASNCtctAddButton");
    OAWebBean asnCtctCrteButton = webBean.findChildRecursive("ASNCtctCrteButton");
    if(asnCtctAddButton!=null && asnCtctCrteButton!=null)
    {
     asnCtctAddButton.setRendered(true);
     asnCtctCrteButton.setRendered(true);
	 pageContext.writeDiagnostics(METHOD_NAME, "Anirban 12 May: always render contact create button",  OAFwkConstants.STATEMENT);
    }
	//Anirban: ends defect fix #14801


    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }


    //lkumar: Fix for defect 6440
	OAMessageChoiceBean statusBean = (OAMessageChoiceBean) webBean.findIndexedChildRecursive("ASNOpptyDetStatus");
    statusBean.setFireActionForSubmit("StatusChange",null,null,false,false);


  }

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
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {

    final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.opportunity.webui.ODOpptyDetCO.processFormRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
     boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processFormRequest(pageContext, webBean);
    pageContext.putParameter("ASNReqFrmFuncName","ASN_OPPTYDETPG");

    // get application module and page event
    OAApplicationModule am = (OAApplicationModule) pageContext.getApplicationModule(webBean);
    String pageEvent = pageContext.getParameter("ASNReqPgAct");

    // get parameters
    Hashtable oppAttrs = (Hashtable) am.invokeMethod("getOpptyAttributes");
    Hashtable oppLineAttrs = (Hashtable) am.invokeMethod("getOpptyLineAttributes");

    /*
     * *************************************************************************
     * Retrieve the page title for breadcrumb correction here.
     * *************************************************************************
     */

    String entityName = (String) oppAttrs.get("Description");
    MessageToken[] tokens = { new MessageToken("NAME", entityName) };
    String pageTitle = pageContext.getMessage("ASN","ASN_OPPTY_DETPG_TITLE", tokens);
    pageContext.putParameter("ASNReqBrdCrmbTtl", pageTitle);

    /*
     * *************************************************************************
     * set the security access mode here
     * *************************************************************************
     */
    String secFlag = (String)pageContext.getTransactionValue("ASNTxnOpptyAcsMd");
    pageContext.putParameter("ASNReqFrmOpptyAcsMd",secFlag);
    String custSecFlag = (String) pageContext.getTransactionValue("ASNTxnCustAcsMd");
    pageContext.putParameter("ASNReqFrmCustAcsMd",custSecFlag);

    /* Added for Site Level Attributes */
    OAViewObject oaviewobject = (OAViewObject)am.findViewObject("OpportunityDetailsVO1");


    if(oaviewobject == null)
    {
          MessageToken amessagetoken1[] = {
              new MessageToken("NAME", "OpportunityDetailsVO1")
          };
          throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken1);
    }
    OpportunityDetailsVORowImpl opportunitydetailsvorowimpl = (OpportunityDetailsVORowImpl)oaviewobject.first();
    Object addressidobj = (Object)opportunitydetailsvorowimpl.getAttribute("AddressId");
    String addressid =addressidobj.toString();
    Object addressobj = (Object)opportunitydetailsvorowimpl.getAttribute("Address");
    String address =addressobj.toString();

    /* End of Site Level Attribute*/

	//lkumar: Fix for defect 6440
	if("StatusChange".equalsIgnoreCase(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))){
     OAMessageChoiceBean probBean = (OAMessageChoiceBean) webBean.findIndexedChildRecursive("ASNOpptYDetWinProb");
     OAMessageChoiceBean statusBean = (OAMessageChoiceBean) webBean.findIndexedChildRecursive("ASNOpptyDetStatus");

     if("LOST".equals(statusBean.getSelectionValue(pageContext)))
       probBean.setSelectionValue(pageContext,"0");
     else if("WON".equals(statusBean.getSelectionValue(pageContext)))
       probBean.setSelectionValue(pageContext,"100");
   }


    /*
     * *************************************************************************
     * Handle subflow event here
     * *************************************************************************
     */


    //change customer
    if(pageContext.getParameter("ASNCustSelButton") != null)
    {
      Number oppId = (Number) oppAttrs.get("LeadId");
      doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);
      String opportunityId = pageContext.getOANLSServices().NumberToString(oppId);
      Serializable [] params = {opportunityId};
      Boolean checkProposalsQuotes = (Boolean)am.invokeMethod("checkProposalsQuotes",params);
      if (checkProposalsQuotes.booleanValue() == true)
      {
        throw new OAException("ASN", "ASN_PROPOSALS_QUOTES_ERR");
      }
      pageContext.putParameter("ASNReqPgAct","SUBFLOW");

      HashMap conditions = new HashMap();
      conditions.put(ASNUIConstants.RETAIN_AM,"Y");
      //conditions.put(ASNUIConstants.BC_CURRENT_LINK,ASNUIConstants.BC_CURRENT_LINK_REMOVE);

      HashMap urlParams = new HashMap();
      urlParams.put("ASNReqFrmFuncName","ASN_ORGLOVPG");
      if (isStatLogEnabled)
      {
        StringBuffer  buf = new StringBuffer(200);
        buf.append(" Select Customer Page Button Clicked. Retain AM parameter set to  ");
        buf.append(ASNUIConstants.RETAIN_AM);
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      }

      this.processTargetURL(pageContext,conditions, urlParams);
    }
    // address selection
    if(pageContext.getParameter("ASNAddrSelButton") != null)
    {
      Number customerId = (Number) oppAttrs.get("CustomerId");
      doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);

      pageContext.putParameter("ASNReqPgAct","SUBFLOW");

      HashMap conditions = new HashMap();
      conditions.put(ASNUIConstants.BC_CURRENT_LINK,
                     ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
      conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT,pageTitle);
      conditions.put(ASNUIConstants.RETAIN_AM,"Y");

      HashMap urlParams = new HashMap();
      urlParams.put("ASNReqFrmFuncName","ASN_PTYADDRSELPG");
      urlParams.put("ASNReqFrmCustId",customerId.toString());

      this.processTargetURL(pageContext,conditions, urlParams);
    }

     // Below code for competitor to be removed later, due to addition of the lov
     // pop-up change

     /* Code below has been commented as this is no longer a SUBFLOw type of
      * page. This has been modified to an LOv as part of the UI score card changes.
    // add competitor button
    if(pageContext.getParameter("ASNCmptAddButton") != null)
    {
      Number oppLineId = (Number) oppLineAttrs.get("LeadLineId");
      Number oppId = (Number) oppLineAttrs.get("LeadId");
      Number orgId = (Number) oppLineAttrs.get("OrganizationId");
      Number prodCatId = (Number) oppLineAttrs.get("ProductCategoryId");

      Number prodCatSetId = (Number) oppLineAttrs.get("ProductCatSetId");
      Number invItemId = (Number) oppLineAttrs.get("InventoryItemId");
      String productCategory = (String) oppLineAttrs.get("ProductCategory");

       doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);

      pageContext.putParameter("ASNReqPgAct","SUBFLOW");

      HashMap conditions = new HashMap();
      conditions.put(ASNUIConstants.BC_CURRENT_LINK,
                     ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
      conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT,pageTitle);
      conditions.put(ASNUIConstants.RETAIN_AM,"Y");

      HashMap urlParams = new HashMap();
      urlParams.put("ASNReqFrmFuncName","ASN_OPPTYCMPTSELPG");
      urlParams.put("ASNReqFrmOpptyId",oppId.toString());

      if(orgId != null)
        pageContext.putTransactionValue("ASNTxnOrgId",orgId.toString());
      if(prodCatId != null )
      {
        pageContext.putTransactionValue("ASNTxnProdCatId",prodCatId.toString());
        //pageContext.putTransactionValue("ASNTxnProdCatSetId",prodCatSetId.toString());
      }
      if(invItemId != null)
        pageContext.putTransactionValue("ASNTxnInvItemId",invItemId.toString());
      pageContext.putTransactionValue("ASNTxnOpptyLineId",oppLineId.toString());
      pageContext.putTransactionValue("ASNTxnSubFlowVUN","OpptyLineCmptPrdtDetailsVO1");
      if(productCategory != null)
        pageContext.putTransactionValue("ASNTxnProductCategory", productCategory);

      this.processTargetURL(pageContext,conditions, urlParams);
    } */

    // add sales team member button
  /*  if(pageContext.getParameter("ASNSTAddButton") != null)
    {
      Number customerId = (Number) oppAttrs.get("CustomerId");
      Number oppId = (Number) oppAttrs.get("LeadId");

      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(400) ;
        buf.append("Add Sales Team -> Customer ID= ");
        buf.append(customerId);
        buf.append("  ,Add Sales Team -> Opportunity ID= ");
        buf.append(oppId);

        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
       }

      doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);

      pageContext.putParameter("ASNReqPgAct","SUBFLOW");

      HashMap conditions = new HashMap();
      conditions.put(ASNUIConstants.BC_CURRENT_LINK,
                     ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
      conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT,pageTitle);
      conditions.put(ASNUIConstants.RETAIN_AM,"Y");

      HashMap urlParams = new HashMap();
      urlParams.put("ASNReqFrmFuncName","ASN_OPPTYRSCSELPG");
      urlParams.put("ASNReqFrmOpptyId",oppId.toString());
      urlParams.put("ASNReqFrmCustId",customerId.toString());

      pageContext.putTransactionValue("ASNTxnSubFlowVUN","AccessDetailsVO");
      pageContext.putTransactionValue("ASNTxnSubFlowGroupFlag","N");

      this.processTargetURL(pageContext,conditions, urlParams);
    }*/

    // add contact button
    if(pageContext.getParameter("ASNCtctAddButton") != null)
    { Number ctoppId = (Number) oppAttrs.get("LeadId");

    		String sql1 = "select a.status from   hz_party_sites a,as_leads_all b where  a.party_site_id = b.address_id and a.party_id   =  b.customer_id and b.lead_id = :1";
				  		  		  OAApplicationModule ctam = (OAApplicationModule)pageContext.getApplicationModule(webBean);
	                          oracle.jbo.ViewObject pctvo4 = ctam.findViewObject("pctVO4");
				  		  		             if (pctvo4 == null )
				  		  		             {
				  		  		               pctvo4 = ctam.createViewObjectFromQueryStmt("pctVO4", sql1);
				  		  		             }

				  		  		             if (pctvo4 != null)
				  		  		             {
				  		  		                 pctvo4.setWhereClauseParams(null);
				  		  		                 pctvo4.setWhereClauseParam(0,ctoppId);
				  		  		                 pctvo4.executeQuery();
				  		  		                 pctvo4.first();
				  		  		                 String status = pctvo4.getCurrentRow().getAttribute(0).toString();
				  		  		                 pageContext.writeDiagnostics(METHOD_NAME,"ctstatus:" +status,OAFwkConstants.PROCEDURE);
				  		  		                 if ("I".equals(status))
				  		  		                 {
													 pctvo4.remove();
													 throw new OAException("XXCRM","XX_SFA_071_CTCT_INVALIDADDR");
												 }
											  else
				  		  		                 {
												   pctvo4.remove();
      Number customerId = (Number) oppAttrs.get("CustomerId");
      Number oppId = (Number) oppAttrs.get("LeadId");
       if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(300) ;
        buf.append("Add Contact -> Customer ID= ");
        buf.append(customerId);
        buf.append("  ,Add Contact -> Opportunity ID= ");
        buf.append(oppId);

        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
       }
      doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);

      pageContext.putParameter("ASNReqPgAct","SUBFLOW");

      HashMap conditions = new HashMap();
      conditions.put(ASNUIConstants.BC_CURRENT_LINK,
                     ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
      conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT,pageTitle);
      conditions.put(ASNUIConstants.RETAIN_AM,"Y");

      HashMap urlParams = new HashMap();
      urlParams.put("ASNReqFrmFuncName","ASN_OPPTYCTCTSELPG");
      urlParams.put("ASNReqFrmOpptyId",oppId.toString());
      urlParams.put("ASNReqFrmCustId",customerId.toString());

      /* Include Custom code to set the Match Rule Attributes for Party Number and Address */

      /* Get the Match Rule name from the profile option HZ: Match Rule for Contact Simple Search */
      String ctctSimpleMatchRuleId = (String) pageContext.getProfile("HZ_DQM_CON_SIMPLE_MATCHRULE");


      /* Get the Party Number */
      String partyNumber = null;
      String partyNumberSql = "SELECT PARTY_NUMBER FROM HZ_PARTIES WHERE PARTY_ID = :1";
      oracle.jbo.ViewObject partyNumbervo = am.findViewObject("PartyNumberVO");
      if (partyNumbervo == null )
      {
          partyNumbervo = am.createViewObjectFromQueryStmt("PartyNumberVO", partyNumberSql);
      }

      if (partyNumbervo != null)
      {
          partyNumbervo.setWhereClauseParam(0,customerId);
          partyNumbervo.executeQuery();
          partyNumbervo.first();
          Row partyNumbervoRow=partyNumbervo.getCurrentRow();

          if (partyNumbervoRow != null)
          {
              if (partyNumbervoRow.getAttribute(0) != null)
              {
                partyNumber = partyNumbervoRow.getAttribute(0).toString();
              }
          }

          partyNumbervo.remove();
      }

      /* Get the Address Attribute Id from the Match Rule Setup*/
      String addressAttId = null;
      String addressIdSql = " SELECT TAT.ATTRIBUTE_ID FROM HZ_MATCH_RULE_SECONDARY MRP,  HZ_TRANS_ATTRIBUTES_TL TAT WHERE MRP.ATTRIBUTE_ID  = TAT.ATTRIBUTE_ID AND MRP.MATCH_RULE_ID = :1 AND TAT.USER_DEFINED_ATTRIBUTE_NAME ='Address'";
      oracle.jbo.ViewObject addrIdvo = am.findViewObject("AddrIdVO");
      if (addrIdvo == null )
      {
          addrIdvo = am.createViewObjectFromQueryStmt("AddrIdVO", addressIdSql);
      }

      if (addrIdvo != null)
      {
          addrIdvo.setWhereClauseParam(0,ctctSimpleMatchRuleId);
          addrIdvo.executeQuery();
          addrIdvo.first();
          Row addrIdvoRow=addrIdvo.getCurrentRow();

          if (addrIdvoRow != null)
          {
              if (addrIdvoRow.getAttribute(0) != null)
              {
                addressAttId = addrIdvoRow.getAttribute(0).toString();
              }
          }

          addrIdvo.remove();
      }

      /* Get the Related Organization Number Attribute Id from the Match Rule Setup*/
      String relOrgAttId = null;
      String relOrgNumberSql = "SELECT TAT.ATTRIBUTE_ID FROM HZ_MATCH_RULE_SECONDARY MRP,  HZ_TRANS_ATTRIBUTES_TL TAT WHERE MRP.ATTRIBUTE_ID  = TAT.ATTRIBUTE_ID AND MRP.MATCH_RULE_ID = :1 AND TAT.USER_DEFINED_ATTRIBUTE_NAME ='Related Organization Number'";
      oracle.jbo.ViewObject relOrgNumbervo = am.findViewObject("RelOrgNumberVO");
      if (relOrgNumbervo == null )
      {
          relOrgNumbervo = am.createViewObjectFromQueryStmt("RelOrgNumberVO", relOrgNumberSql);
      }

      if (relOrgNumbervo != null)
      {
          relOrgNumbervo.setWhereClauseParam(0,ctctSimpleMatchRuleId);
          relOrgNumbervo.executeQuery();
          relOrgNumbervo.first();
          Row relOrgNumbervoRow=relOrgNumbervo.getCurrentRow();

          if (relOrgNumbervoRow != null)
          {
              if (relOrgNumbervoRow.getAttribute(0) != null)
              {
                relOrgAttId = relOrgNumbervoRow.getAttribute(0).toString();
              }
          }
          relOrgNumbervo.remove();
      }


      /* Append the Attribute Id to the string MATCH_RULE_ATTR to get the Match Rule Attribute Name */
      String AddrParamName = "MATCH_RULE_ATTR" + addressAttId;
      String RelatedOrgNumberParamName = "MATCH_RULE_ATTR" + relOrgAttId;


      /* Pass the address and Party Number to the Address and Related Organization Number fields accordingly */
      pageContext.putParameter(AddrParamName,address);
      pageContext.putParameter(RelatedOrgNumberParamName,partyNumber);


      /* End Of Custom Code */

      pageContext.putTransactionValue("ASNTxnSubFlowVUN","OpportunityContactDetailsVO1");

      this.processTargetURL(pageContext,conditions, urlParams);
    }}
    }

    //Create Contact Flow

    if (pageContext.getParameter("ASNCtctCrteButton") != null)
    {Number ctoppId = (Number) oppAttrs.get("LeadId");

    		String sql1 = "select a.status from   hz_party_sites a,as_leads_all b where  a.party_site_id = b.address_id and a.party_id   =  b.customer_id and b.lead_id = :1";
				  		  		  OAApplicationModule ctam = (OAApplicationModule)pageContext.getApplicationModule(webBean);
	                          oracle.jbo.ViewObject pctvo4 = ctam.findViewObject("pctVO4");
				  		  		             if (pctvo4 == null )
				  		  		             {
				  		  		               pctvo4 = ctam.createViewObjectFromQueryStmt("pctVO4", sql1);
				  		  		             }

				  		  		             if (pctvo4 != null)
				  		  		             {
				  		  		                 pctvo4.setWhereClauseParams(null);
				  		  		                 pctvo4.setWhereClauseParam(0,ctoppId);
				  		  		                 pctvo4.executeQuery();
				  		  		                 pctvo4.first();
				  		  		                 String status = pctvo4.getCurrentRow().getAttribute(0).toString();
				  		  		                 pageContext.writeDiagnostics(METHOD_NAME,"ctstatus:" +status,OAFwkConstants.PROCEDURE);
				  		  		                 if ("I".equals(status))
				  		  		                 {
													 pctvo4.remove();
													 throw new OAException("XXCRM","XX_SFA_071_CTCT_INVALIDADDR");
												 }
											  else
				  		  		                 {
												   pctvo4.remove();
      Number customerId = (Number) oppAttrs.get("CustomerId");
      Number oppId = (Number) oppAttrs.get("LeadId");
       if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(400) ;
        buf.append("Create Contact -> Customer ID= ");
        buf.append(customerId);
        buf.append("  ,Create Contact -> Opportunity ID= ");
        buf.append(oppId);

        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
       }


       //commit your changes
       doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);

       // url parameters
       HashMap urlParams = new HashMap();
      urlParams.put("ASNReqFrmFuncName","ASN_CTCTCREATEPG");
      urlParams.put("ASNReqFrmCustId",customerId);
      urlParams.put("ASNReqFromLOVPage", "TRUE");

      /* Custom Code to include Party Site Id as parameter */
      urlParams.put("ASNReqSelPartySiteId", addressid);
      urlParams.put("ASNReqFrmSiteId",addressid);
      urlParams.put("ASNReqSelAddress", address);

      /* End Custom ASN Party Site Attributes */

      //this is a subflow, so we need this parameter
      pageContext.putParameter("ASNReqPgAct","SUBFLOW");

     //conditions
      HashMap conditions = new HashMap();
      conditions.put(ASNUIConstants.BC_CURRENT_LINK,ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
      conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT,pageTitle);
      conditions.put(ASNUIConstants.RETAIN_AM,"Y");

      this.processTargetURL(pageContext,conditions,urlParams);
  }}
    }

    // add product button or select product icon click
    if(pageContext.getParameter("ASNPrdtAddButton") != null
       || "CHGLINE".equals(pageEvent))
    {
      Number oppId = (Number) oppAttrs.get("LeadId");
        if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(300) ;
        buf.append("  ,Add Product -> Opportunity ID= ");
        buf.append(oppId);

        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
       }
      doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);

      pageContext.putParameter("ASNReqPgAct","SUBFLOW");

      HashMap conditions = new HashMap(5);
      conditions.put(ASNUIConstants.BC_CURRENT_LINK,ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
      conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT,pageTitle);
      conditions.put(ASNUIConstants.RETAIN_AM,"Y");

      HashMap urlParams = new HashMap(3);
      urlParams.put("ASNReqFrmFuncName","ASN_OPPTYPRDTSELPG");
      urlParams.put("ASNReqFrmOpptyId", oppId.toString());

      pageContext.putTransactionValue("ASNTxnSubFlowVUN","OpportunityLineDetailsVO1");
      pageContext.removeTransactionValue("ASNTxnPrdtLnId");
      pageContext.removeTransactionValue("ASNTxnLOVMode");
        // check for select product event
      if("CHGLINE".equals(pageEvent))
      {
        pageContext.putTransactionValue("ASNTxnLOVMode", "SINGLE");
        String opptyLineId = pageContext.getParameter("ASNReqEvtRowId");
        if(opptyLineId!=null && !"".equals(opptyLineId.trim()))
        {
          pageContext.putTransactionValue("ASNTxnPrdtLnId", opptyLineId);
        }
      }

      this.processTargetURL(pageContext,conditions, urlParams);
    }

    /*
     * *************************************************************************
     * Handle PPR events
     * *************************************************************************
     */
    String event = pageContext.getParameter(EVENT_PARAM);

    if ("oaAddAttachment".equals(event))
    {
      doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);
      ASNUIUtil.attchEvent(pageContext,webBean);
    }

    if ("oaUpdateAttachment".equals(event))
    {
      doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);
      ASNUIUtil.attchEvent(pageContext,webBean);

    }
    if ("oaDeleteAttachment".equals(event))
    {
      doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);
      ASNUIUtil.attchEvent(pageContext,webBean);

    }
    if ("oaViewAttachment".equals(event))
    {
      doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);
      ASNUIUtil.attchEvent(pageContext,webBean);
    }

    if (isStatLogEnabled)
    {
      StringBuffer buf = new StringBuffer(200) ;
      buf.append("  PPR Event ->  ");
      buf.append(event);
      pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
    }

    if ("detailMethUpdate".equals(event))
    {
      am.invokeMethod("handleDetailMethUpdateEvent");
    }

    if("detailStatusUpdate".equals(event))
    {
      am.invokeMethod("handleDetailStatusUpdateEvent");
    }

    if("headerFrcstUpdate".equals(event))
    {
      am.invokeMethod("handleHeaderFrcstUpdateEvent");
    }

    if("lineFrcstUpdate".equals(event))
    {
      am.invokeMethod("handleLineFrcstUpdateEvent");
    }

    // Code for flex field

    if ("ASNOpptyStSelFA".equals(event))
    {
      // Get a handle to the StackLayout of the Sales Team Additional Info region
      OAHeaderBean stBean=(OAHeaderBean)webBean.findChildRecursive("ASNSTAddInfoHdrRN");
      // Check if the Stacked Layout is Rendered (user may have personalized)
      // Execute further code only if the header Bean is rendered
      if(stBean.isRendered())
      {

         // Invoke the method in the AM that sets the Row selected as a Current Row in the VO
         am.invokeMethod("refreshSalesteamDetailsRow");
         // Use the following Line of Code as workaround for Bug # 3274685
         // pageContext.forwardImmediately(PageFunctionName,MenuContext, MenuName, urlParams, RetainAM,BreadCrumb);
     //    HashMap stUrlParams = new HashMap();
   //      String stOppId =  (String) pageContext.getTransactionValue("ASNTxnOppId");
 //        stUrlParams.put("ASNReqFrmOpptyId",stOppId.toString());
         pageContext.putParameter("ASNReqPgAct", "REFRESH");
         this.processTargetURL(pageContext, null, null);
        /* pageContext.forwardImmediately("ASN_OPPTYDETPG",
                                        OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                        null,
                                        stUrlParams,
                                        true,
                                        OAWebBeanConstants.ADD_BREAD_CRUMB_YES);*/
         //  pageContext.setForwardURLToCurrentPage(null,true,null,(byte)0);
      }
    }


   // sort action
    if (SORT_EVENT.equals(event))
    {
      if (isStatLogEnabled)
      {
         StringBuffer buf = new StringBuffer(200);
        buf.append(" Event -> ");
        buf.append(" SORT_EVENT - Sales Team");
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      }
      String salesTeamSource = pageContext.getParameter(this.SOURCE_PARAM);
      OAAdvancedTableBean salesTeamTable = (OAAdvancedTableBean)webBean.findIndexedChildRecursive("ASNSTLstTb");
      String salesTeamName = salesTeamTable.getName(pageContext);
      if (isStatLogEnabled)
      {
          StringBuffer buf = new StringBuffer(200);
        buf.append(" Sales Team Table Bean Name -> ");
        buf.append(salesTeamTable);
        buf.append(" Name ");
        buf.append(salesTeamName);
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      }
      if(salesTeamName.equals(salesTeamSource))
      {
        pageContext.putParameter("ASNReqPgAct","REFRESH");
        pageContext.setForwardURLToCurrentPage(null, true, ADD_BREAD_CRUMB_SAVE, OAException.WARNING);
        //this.processTargetURL(pageContext,null,null);
      }
    }


    if (isStatLogEnabled)
    {
      StringBuffer buf = new StringBuffer(250) ;
      buf.append("  ,Page Event ->  ");
      buf.append(pageEvent);
      pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
    }

    // delete sales team member
    if("ST_DELETE".equals(pageEvent) )
    {
      String apId = pageContext.getParameter("ASNReqEvtRowId");
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(300) ;
        buf.append("  Delete Sales Team -> Row ID =  ");
        buf.append(apId);
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
       }

      if(apId != null)
      {
        Serializable[] parameters = { apId };
        am.invokeMethod("removeSalesTeamMembers", parameters);

        // Code for flex added Sept 13, 2004

           // We check if the Flexfield Region is rendered, based on which we do a workaround
          // Get a handle to the StackLayout of the Sales Team Additional Info region

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
    }

    // delete product
    if("LINE_DELETE".equals(pageEvent))
    {
      String lpId = pageContext.getParameter("ASNReqEvtRowId");
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(300) ;
        buf.append("  Delete Product -> Row ID =  ");
        buf.append(lpId);
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
       }
      if (lpId != null )
      {
        Serializable[] parameters = { lpId };
        am.invokeMethod("removeLines", parameters);
         // We check if the Flexfield Region is rendered, based on which we do a workaround
        // Get a handle to the StackLayout of the Sales Team Additional Info region
       /* OAStackLayoutBean AddInfoBean=(OAStackLayoutBean)webBean.findChildRecursive("ASNPrdtAddInfoRN");
       // Check if the Stacked Layout is Rendered (user may have personalized)
       // Execute further code only if the StackLayout Bean is rendered

       if(AddInfoBean.isRendered())
       {
        // Use the following Line of Code as workaround for Bug # 3274685
        // pageContext.forwardImmediately(PageFunctionName,MenuContext, MenuName, urlParams, RetainAM,BreadCrumb);
        // This has been handled in the processTargetURL
        pageContext.putParameter("ASNReqPgAct", "REFRESH");
        this.processTargetURL(pageContext, null, null);
       }*/

      }

      pageContext.putParameter("ASNReqPgAct","REFRESH");
      this.processTargetURL(pageContext,null,null);
    }

    // delete competitor
    if("CMPT_DELETE".equals(pageEvent))
    {
      String lpId = pageContext.getParameter("ASNReqEvtRowId");
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(400) ;
        buf.append("  Delete Competitor -> Row ID =  ");
        buf.append(lpId);
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
       }
      if (lpId != null )
      {
        Serializable[] parameters = { lpId };
        am.invokeMethod("removeCompetitors", parameters);
      }
    }


    // Code to delete a non-revenue forecast owner
   if("NONREV_FRCST_OWNER_DELETE".equals(pageEvent))
    {
      String lpId = pageContext.getParameter("ASNReqEvtRowId");
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(400) ;
        buf.append("  Delete Non-Revenue Forecast Owner -> Row ID =  ");
        buf.append(lpId);
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
       }
      if (lpId != null )
      {
        Serializable[] parameters = { lpId };
        am.invokeMethod("removeNonRevFrcstOwner", parameters);
      }
    }
   // Set the default flag when the group is changed -- Line Level Forecasting functionality
   if("CHANGE_GROUP".equals(event))
   {
     String slsCrdId = pageContext.getParameter("ASNReqEvtRowId");
     Serializable[] amParams = {slsCrdId, "N"};
     am.invokeMethod("setRevFrcstDefaultFlag", amParams);
   }



    /*
     * *************************************************************************
     * Handle save event
     * *************************************************************************
     */
    if(pageContext.getParameter("ASNPageSvButton") != null)
    {
      doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);

      pageContext.putParameter("ASNReqPgAct","REFRESH");

      HashMap conditions = new HashMap();
      conditions.put(ASNUIConstants.BC_CURRENT_LINK,ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
      conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT,pageTitle);

      //anirban: defect#14901 starts.

      OAApplicationModule oamban = pageContext.getRootApplicationModule();
 	  ASNViewObjectImpl opptyDetAppPropertiesVO1 = (ASNViewObjectImpl)oamban.findViewObject("OpptyDetAppPropertiesVO1");
 	  if (opptyDetAppPropertiesVO1 != null)
 	  {
 	   opptyDetAppPropertiesVO1.setPreparedForExecution(false); 	   
	  }

      processTargetURL(pageContext,conditions,null);

	  //anirban: defect#14901 ends.
    }

    /*
     * *************************************************************************
     * Handle main event here.
     * *************************************************************************
     */
    // go to view history page
    if(pageContext.getParameter("ASNViewHistButton")!=null)
    {
      Number oppId = (Number) oppAttrs.get("LeadId");

      //this.doCommit(pageContext);
      doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);
      //pageContext.putParameter("ASNReqPgAct", "SUBFLOW");
      pageContext.putParameter("ASNReqPgAct", "OPPTYHIST");

      HashMap conditions = new HashMap(4);
      conditions.put(ASNUIConstants.RETAIN_AM, "Y");
      conditions.put(ASNUIConstants.BC_CURRENT_LINK, ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
      conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT, pageTitle);

      HashMap urlParams = new HashMap(3);
      urlParams.put("ASNReqFrmFuncName", "ASN_OPPTYHISTTRACKINGPG");
      urlParams.put("ASNReqFrmOpptyId", oppId);
      this.processTargetURL(pageContext, conditions, urlParams);
    }

    // go to customer detail page
    if("CUSTDET".equals(pageEvent))
    {
      doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);

      HashMap conditions = new HashMap();
      conditions.put(ASNUIConstants.BC_CURRENT_LINK,
                     ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
      conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT,pageTitle);

      HashMap urlParams = this.getFrmParamsFromEvtParams(pageContext);

      //anirban starts on 1st Feb '08 

      //processTargetURL(pageContext,conditions, urlParams);

	  HashMap hashmap = new HashMap();
	  hashmap.put("ASNReqFrmCustId", pageContext.getParameter("ASNReqEvtCustId"));
      hashmap.put("ASNReqFrmFuncName", "ASN_ORGVIEWPG");
      pageContext.putParameter("ASNReqPgAct", "CUSTDET");
	  boolean flag50 = false;
	  pageContext.forwardImmediately("ASN_ORGVIEWPG", OAWebBeanConstants.KEEP_MENU_CONTEXT, null, hashmap, flag50, "Y");

	  //anirban ends on 1st Feb '08 
    }

    if("CTCTDET".equals(pageEvent))
    {
      doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);

      HashMap conditions = new HashMap();
      conditions.put(ASNUIConstants.BC_CURRENT_LINK,
                     ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
      conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT,pageTitle);

      HashMap urlParams = this.getFrmParamsFromEvtParams(pageContext);

      processTargetURL(pageContext,conditions, urlParams);
    }

    if("PRPDET".equals(pageEvent))
    {
      String proposalId = pageContext.getParameter("ASNReqEvtPrpId");
      if(proposalId!=null && !("".equals(proposalId.trim())))
      {
        doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);

        Number oppId = (Number) oppAttrs.get("LeadId");

        HashMap prpParams = new HashMap(3);
        prpParams.put("proposalId",proposalId);
        prpParams.put("PRPObjectType","OPPORTUNITY");
        prpParams.put("PRPObjectId", oppId.toString());

        HashMap conditions = new HashMap(3);
        conditions.put(ASNUIConstants.BC_CURRENT_LINK, ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
        conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT, pageTitle);
        this.processTargetURL(pageContext, conditions, prpParams);
      }
    }

    if("QOTDET".equals(pageEvent))
    {
      String quoteHdrId = pageContext.getParameter("ASNReqEvtQotHdrId");
      if(quoteHdrId!=null && !("".equals(quoteHdrId.trim())))
      {
        doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);

        HashMap qotParams = new HashMap(2);
        qotParams.put("qotHdrId",quoteHdrId);
        HashMap conditions = new HashMap(3);
        conditions.put(ASNUIConstants.BC_CURRENT_LINK, ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
        conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT, pageTitle);
        this.processTargetURL(pageContext, conditions, qotParams);
      }
    }

    if("CSCHDET".equals(pageEvent))
    {
      String cschId = pageContext.getParameter("ASNReqEvtCschId");
      if(cschId!=null && !("".equals(cschId.trim())))
      {
        doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);

        HashMap cschParams = new HashMap(3);
        cschParams.put("objId",cschId);

        HashMap conditions = new HashMap(3);
        conditions.put(ASNUIConstants.BC_CURRENT_LINK, ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
        conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT, pageTitle);
        this.processTargetURL(pageContext, conditions, cschParams);
      }
    }

    // for integrated components
    if("OPPTYDET".equals(pageEvent))
    {
      doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);
    }

    if("SLSCCH".equals(pageEvent))
    {
      pageContext.putTransactionValue("ASNTxnSalesCycleReset", "N");
      doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);
      pageContext.removeTransactionValue("ASNTxnSalesCycleReset");
    }

    if(pageContext.getParameter("ASNSCStgVwWkShtButton")!=null)
    {
      pageContext.putTransactionValue("ASNTxnSalesCycleReset", "N");
      doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);
      pageContext.removeTransactionValue("ASNTxnSalesCycleReset");
    }
     if("REFDET".equals(pageEvent))
    {
      String prmRefCode = pageContext.getParameter("ASNReqEvtPrmRefCode");
      if(prmRefCode!=null && !("".equals(prmRefCode.trim())))
      {
              doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);

        HashMap prmRefParams = new HashMap(3);
        prmRefParams.put("pvReferralCode",prmRefCode);
        String retUrl = this.getModifiedCurrentUrlForRedirect(pageContext);
        prmRefParams.put("prmReturnUrl",retUrl);
        //prmRefParams.put("prmReturnUrl",retUrl);
        //String retUrl = this.getCurrentUrlForRedirect(pageContext);
       // pageContext.putTransactionValue("prmReturnUrl",retUrl);


        HashMap conditions = new HashMap(3);
        conditions.put(ASNUIConstants.BC_CURRENT_LINK, ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
        conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT, pageTitle);
        this.processTargetURL(pageContext, conditions, prmRefParams);
      }
    }
      // when update or view task
    if("Update".equals(pageContext.getParameter("CacSmrTaskEvent")) ||
       "View".equals(pageContext.getParameter("CacSmrTaskEvent")) ||
       "CallNotesDetail".equals(pageContext.getParameter("CacNotesDtlEvent")))
    {
      doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);
      modifyCurrentBreadcrumbLink(pageContext, true, pageTitle, true);
    }
      // when sales cycle view option is changed
    if("STGVWCHG".equals(pageContext.getParameter(EVENT_PARAM)))
    {
      if(oppAttrs!=null)
      {
        Number stageId = (Number)oppAttrs.get("SalesStageId");
        if(stageId!=null)
          pageContext.putTransactionValue("ASNTxnSCStageId", stageId.stringValue());
        else
          pageContext.removeTransactionValue("ASNTxnSCStageId");
      }
    }

    // when creating contact task or view contact detail
    if(pageContext.getParameter("ASNCtctGoButton") != null)
    {
      String action = pageContext.getParameter("ASNCtctAct");
      if("CREATE_TASK".equals(action))
      {
        HashMap data = (HashMap) am.invokeMethod("getTaskParameters");
        if(data != null && data.size() > 0)
        {
          doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);

          String srcObjId = (String) data.get("cacTaskSrcObjId");
          if(srcObjId != null)
          {
            data.put("cacTaskSrcObjId",pageContext.encrypt(srcObjId));
          }
 String sql1 = "select address_id from as_leads_all where lead_id = :1";
 		  	OAApplicationModule oamadd = pageContext.getRootApplicationModule();
 		  	oracle.jbo.ViewObject ctAddressvo = oamadd.findViewObject("ctAddrVO");
 		  	if (ctAddressvo == null )
 		  	{
 		  	ctAddressvo = oamadd.createViewObjectFromQueryStmt("ctAddrVO", sql1);
 		  	}
 		  	if (ctAddressvo != null)
 		  	{
 		  	  ctAddressvo.setWhereClauseParams(null);
 		  	  ctAddressvo.setWhereClauseParam(0,srcObjId);
 		  	  ctAddressvo.executeQuery();
 		  	  ctAddressvo.first();
 		  	  String Addressid = ctAddressvo.getCurrentRow().getAttribute(0).toString();
 		  	  ctAddressvo.remove();
 		  	  data.put("cacTaskCustAddressId",Addressid);
		 }

          HashMap conditions = new HashMap();
          conditions.put(ASNUIConstants.BC_CURRENT_LINK,
                         ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
          conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT,pageTitle);

          pageContext.putParameter("ASNReqPgAct","CRTETASK");
          // Debug Logging
		            if (isStatLogEnabled)
		            {
		              StringBuffer buf = new StringBuffer(200);
		              buf.append(" Create Task - Parameters being passed to processTargetURL -  ");
		              buf.append(" conditions : ");
		              buf.append(conditions.toString());
		              buf.append(" data : ");
		              buf.append(data.toString());
		              pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
          } // End Debug Logging

          this.processTargetURL(pageContext,conditions,data);
        }
        else
        {
          throw new OAException("ASN","ASN_CMMN_RADIO_MISS_ERR");
        }
      }
      if("VIEW_DETAILS".equals(action))
      {
        HashMap data = (HashMap) am.invokeMethod("getContactParameters");
        if(data != null && data.size() > 0)
        {
          doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);

          pageContext.putParameter("ASNReqPgAct","CTCTDET");

          HashMap conditions = new HashMap();
          conditions.put(ASNUIConstants.BC_CURRENT_LINK,
                         ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
          conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT,pageTitle);

          processTargetURL(pageContext,conditions, data);
        }
        else
        {
          throw new OAException("ASN","ASN_CMMN_RADIO_MISS_ERR");
        }
      }
      if("SEND_PROPOSAL".equals(action))
      {
        HashMap ctctParams = (HashMap) am.invokeMethod("getContactParameters");
        if(ctctParams != null && ctctParams.size() > 0)
        {
          HashMap prpParams = (HashMap)am.invokeMethod("getProposalParameters");
          if(prpParams!=null && prpParams.size()>0)
          {
            prpParams.put("PRPContactRelPartyId", (String)ctctParams.get("ASNReqFrmRelPtyId"));

            doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);

            HashMap conditions = new HashMap(3);
            conditions.put(ASNUIConstants.BC_CURRENT_LINK, ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
            conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT, pageTitle);
            pageContext.putParameter("ASNReqPgAct", "CRTEPRP");
            this.processTargetURL(pageContext, conditions, prpParams);
          }
        }
        else
        {
          throw new OAException("ASN","ASN_CMMN_RADIO_MISS_ERR");
        }
      }
    }

    //PRM Integration

    if("pvNavigationEvent".equals(event))
    {
      doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);

      Number oppId = (Number) oppAttrs.get("OppId");
      if(oppId!=null)
      {
           String prmReturnUrl = this.getModifiedCurrentUrlForRedirect(pageContext, true);
           pageContext.putTransactionValue("prmReturnUrl ", prmReturnUrl);
      }
      this.modifyCurrentBreadcrumbLink(pageContext, true, pageTitle, true);
    }

    if("pvActionEvent".equals(event))
    {
      Number oppId = (Number) oppAttrs.get("LeadId");

      if(oppId!=null)
      {
//        OAApplicationModule prmAM = (OAApplicationModule) am.findApplicationModule("PvOpptyExtSalesteamAM"); /** Replace with Actual Method Name ***/
        OAWebBean tableBean = webBean.findChildRecursive("ExtSalesTeamContainer");
        OAApplicationModule prmAM = pageContext.getApplicationModule(tableBean);

        oracle.apps.fnd.framework.server.OADBTransaction transaction
            = prmAM.getOADBTransaction();

        String method = pageContext.getParameter("PV_METHOD_NAME");

        /**
         * This section looks for all parameters which starts with the
         * charactes 'pvAP' and puts them to the AM transientValues list.
         * These values will be accessed by the methods in the AM.
         */
        for (java.util.Enumeration e = pageContext.getParameterNames();e.hasMoreElements();)
        {
            String paramName = (String)e.nextElement();
            String paramValue = pageContext.getParameter(paramName);

            if (paramName != null
                && paramName.startsWith("pvAP")
                && paramValue != null)
            {

                transaction.putTransientValue(paramName,paramValue);
            }
        }
        if (method != null)
        {
          doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);
          prmAM.invokeMethod(method);
        }
       doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);
       pageContext.putParameter("ASNReqPgAct","REFRESH");

       HashMap conditions = new HashMap();
       conditions.put(ASNUIConstants.BC_CURRENT_LINK,
                      ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
       conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT,pageTitle);
       processTargetURL(pageContext,conditions,null);
       }
     }


    // create proposal
    if(pageContext.getParameter("ASNPrpAddButton") != null)
    {
      doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);

      HashMap conditions = new HashMap();
      conditions.put(ASNUIConstants.BC_CURRENT_LINK,
                     ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
      conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT,pageTitle);

      HashMap data = (HashMap) am.invokeMethod("getProposalParameters");

      pageContext.putParameter("ASNReqPgAct","CRTEPRP");

      processTargetURL(pageContext,conditions, data);
    }

    // create quote
    if(pageContext.getParameter("ASNQotAddButton") != null)
    {
      doCommit(pageContext, webBean, am, oppAttrs, oppLineAttrs);

      Number oppId = (Number) oppAttrs.get("LeadId");
      if(oppId!=null)
      {
        HashMap conditions = new HashMap(3);
        conditions.put(ASNUIConstants.BC_CURRENT_LINK,
                       ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
        conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT,pageTitle);

        HashMap data = new HashMap(2);
        data.put("qotHdrOptyId", oppId.stringValue());
        pageContext.putParameter("ASNReqPgAct","CRTEQOT");
        processTargetURL(pageContext,conditions, data);
      }
    }
   if (pageContext.isLovEvent() && "ASNRevFrcstOwner".equals(pageContext.getLovInputSourceId()))
   {
      Serializable[] amParams = {null, "N"};
      am.invokeMethod("setRevFrcstDefaultFlag", amParams);
   }

 //
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }
  }

 private void doCommit(OAPageContext oapagecontext, OAWebBean oawebbean, OAApplicationModule oaapplicationmodule, Hashtable hashtable, Hashtable hashtable1)
 {
        String s = "asn.opportunity.webui.OpptyDetCO.doCommit";
        boolean flag = oapagecontext.isLoggingEnabled(2);
        boolean flag1 = oapagecontext.isLoggingEnabled(1);
        if(flag)
            oapagecontext.writeDiagnostics(s, "Begin", 2);
        super.doCommit(oapagecontext);
        String s1 = oapagecontext.getParameter("ASNReqPgAct");
        if(!"OPPTYDET".equals(s1) && !"CTCTDET".equals(s1) && !"CUSTDET".equals(s1) && !"ASNSCStgVwWkShtButton".equals(s1) && !"VIEW_DETAILS".equals(s1))
            oaapplicationmodule.invokeMethod("resetQuery");
        Number number = (Number)hashtable.get("LeadId");
        Serializable aserializable[] = {
            number.toString(), Boolean.TRUE
        };
        Class aclass[] = {
            java.lang.String.class, java.lang.Boolean.class
        };
        oaapplicationmodule.invokeMethod("initQuery", aserializable, aclass);
        oaapplicationmodule.invokeMethod("getOpptyAttributes");
        Number number1 = (Number)hashtable1.get("LeadLineId");
        if(flag1)
        {
            StringBuffer stringbuffer = new StringBuffer(400);
            stringbuffer.append("  Commit -> Lead ID =  ");
            stringbuffer.append(number);
            stringbuffer.append("  Commit -> Lead Line ID =  ");
            stringbuffer.append(number1);
            oapagecontext.writeDiagnostics(s, stringbuffer.toString(), 1);
        }
        if(number1 != null)
        {
            number1.toString();
            oaapplicationmodule.invokeMethod("setRowAsSelected");
            oaapplicationmodule.invokeMethod("getOpptyLineAttributes");
        }
        if(flag)
            oapagecontext.writeDiagnostics(s, "End", 2);
    }



}
