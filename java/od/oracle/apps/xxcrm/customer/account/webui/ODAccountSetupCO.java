package od.oracle.apps.xxcrm.customer.account.webui;
/* Subversion Info:
*
* $HeadURL$
*
* $Rev$
*
* $Date$
*/

import oracle.apps.asn.common.fwk.webui.ASNUIConstants;
import com.sun.java.util.collections.HashMap;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import java.sql.SQLException;
import java.util.HashSet;
import java.util.Set;
import oracle.jbo.RowSetIterator;
import oracle.jbo.RowSet;
import java.util.ArrayList;
import od.oracle.apps.xxcrm.customer.account.poplist.server.ODAccountSetupUpOffVORowImpl;
import od.oracle.apps.xxcrm.customer.account.poplist.server.ODContractTemplatePoplistVOImpl;
import od.oracle.apps.xxcrm.customer.account.poplist.server.ODContractTemplatePoplistVORowImpl;
import od.oracle.apps.xxcrm.customer.account.poplist.server.ODPartyRevenueBandAttributeVORowImpl;
import od.oracle.apps.xxcrm.customer.account.server.ODContractTemplatesVORowImpl;
import od.oracle.apps.xxcrm.customer.account.server.ODContractsAssignedVORowImpl;
import od.oracle.apps.xxcrm.customer.account.server.ODContractsAssignedVOImpl;
import od.oracle.apps.xxcrm.customer.account.server.ODCdhContractProgCodesVORowImpl;
import od.oracle.apps.xxcrm.customer.account.server.OdCdhAcctTemplateContractsVORowImpl;
import od.oracle.apps.xxcrm.customer.account.server.OdCdhAcctTemplateContractsVOImpl;
import od.oracle.apps.xxcrm.customer.account.server.ODCustAcctSetupContractsVORowImpl;
import od.oracle.apps.xxcrm.customer.account.server.ODCustAcctSetupContractsValidationVORowImpl;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;
import od.oracle.apps.xxcrm.customer.account.server.ODCustAcctSetupDocumentVORowImpl;
import od.oracle.apps.xxcrm.customer.account.server.ODCustomerAccountSetupRequestDetailsVORowImpl;
import od.oracle.apps.xxcrm.customer.account.server.ODCustomerAccountSetupRequestVORowImpl;
import od.oracle.apps.xxcrm.customer.account.server.ODCustomerAssignedRoleVORowImpl;
import od.oracle.apps.xxcrm.customer.account.server.ODContTempCUPVOImpl;
import od.oracle.apps.xxcrm.customer.account.server.ODContTempCUPVORowImpl;
import od.oracle.apps.xxcrm.customer.account.server.ODOrgAccountSetupPVOImpl;
import od.oracle.apps.xxcrm.customer.account.server.ODCdhContractCompPVOImpl;
import od.oracle.apps.xxcrm.customer.account.server.ODCdhContractCompPVORowImpl;
import od.oracle.apps.xxcrm.customer.account.server.ODOrgAccountSetupPVORowImpl;
import od.oracle.apps.xxcrm.customer.account.server.ODAccountSetupButtonsPVOImpl;
import od.oracle.apps.xxcrm.customer.account.server.ODAccountSetupButtonsPVORowImpl;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OAFormValueBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageCheckBoxBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.OAFwkConstants;

import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.jbo.Row;
import oracle.jbo.domain.Number;
import od.oracle.apps.xxcrm.customer.account.server.ODCustomerAccountsVOImpl;
import od.oracle.apps.xxcrm.customer.account.server.ODCustomerAccountsVORowImpl;
import od.oracle.apps.xxcrm.customer.account.server.ODCustAcctSalesRepValVOImpl;
import od.oracle.apps.xxcrm.customer.account.server.ODCustAcctSalesRepValVORowImpl;
import od.oracle.apps.xxcrm.customer.account.server.ODHzPuiAddressTableVORowImpl;
import od.oracle.apps.xxcrm.customer.account.server.ODHzPuiAddressTableVOImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import java.sql.Connection;;
import oracle.jdbc.OracleCallableStatement;
import java.sql.Statement;
import oracle.jdbc.OracleStatement;
import java.sql.ResultSet;
import java.sql.Types;
import oracle.jdbc.OracleTypes;
import oracle.apps.fnd.framework.server.OAExceptionUtils;
import oracle.sql.NUMBER;
import oracle.apps.fnd.framework.webui.beans.layout.OACellFormatBean;
import oracle.apps.fnd.framework.webui.beans.OATipBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;


public class ODAccountSetupCO extends OAControllerImpl //ODASNControllerObjectImpl
{
  protected boolean PRICE_PLAN_MANDATORY = false;
  protected boolean PRICE_PLAN_LOCKED = false;
  protected boolean ASSN_CONTRACTS_LOCKED = false;

  protected Set prioritySet = null;

  public ODAccountSetupCO()
  {
  }

  public void processRequest(OAPageContext pageContext,OAWebBean webBean)
  {

    final String METHOD_NAME = "od.oracle.apps.xxcrm.customer.account.webui.ODAccountSetupCO.processRequest";
    pageContext.writeDiagnostics(METHOD_NAME, "ODAccountSetupCO processRequest begins", OAFwkConstants.PROCEDURE);

    super.processRequest(pageContext, webBean );

    setSkipProcessFormData(pageContext, webBean);

    OAApplicationModule currentAm = pageContext.getApplicationModule(webBean);

    OAViewObject ODContTempCUPVO = (OAViewObject)currentAm.findViewObject("ODContTempCUPVO");
    if (ODContTempCUPVO == null)
    {
            ODContTempCUPVO = (OAViewObject)currentAm.createViewObject("ODContTempCUPVO",
                    "od.oracle.apps.xxcrm.customer.account.server.ODContTempCUPVO");
    };

    ODContTempCUPVO.setMaxFetchSize(0) ;
    ODContTempCUPVO.executeQuery();
    ODContTempCUPVORowImpl pvoRow = (ODContTempCUPVORowImpl)ODContTempCUPVO.createRow();
    ODContTempCUPVO.insertRow(pvoRow);

    pvoRow.setReadOnly(Boolean.FALSE );
    pvoRow.setRendered(Boolean.TRUE );

    OAViewObject ODAccountSetupButtonsPVO = (OAViewObject)currentAm.findViewObject("ODAccountSetupButtonsPVO");
    if ( ODAccountSetupButtonsPVO == null )
            ODAccountSetupButtonsPVO = (OAViewObject)currentAm.createViewObject("ODAccountSetupButtonsPVO",
                    "od.oracle.apps.xxcrm.customer.account.server.ODAccountSetupButtonsPVO");

    ODAccountSetupButtonsPVO.setMaxFetchSize(0) ;
    ODAccountSetupButtonsPVO.executeQuery();
    ODAccountSetupButtonsPVORowImpl buttonRenderedRow = (ODAccountSetupButtonsPVORowImpl)ODAccountSetupButtonsPVO.createRow();
    ODAccountSetupButtonsPVO.insertRow(buttonRenderedRow);

    buttonRenderedRow.setAddCustomContractRendered(Boolean.TRUE);
    buttonRenderedRow.setAddCustomDocumentRendered(Boolean.TRUE);
    buttonRenderedRow.setCopyRequestRowRendered(Boolean.TRUE);
    buttonRenderedRow.setDeleteContractRendered(Boolean.TRUE);
    buttonRenderedRow.setDeleteDocumentRendered(Boolean.TRUE);
    buttonRenderedRow.setDeleteRequestRendered(Boolean.TRUE);
    buttonRenderedRow.setSubmitRequestRendered(Boolean.TRUE);
    buttonRenderedRow.setValidateAndSaveRendered(Boolean.TRUE);

    OAViewObject ODOrgAccountSetupPVO = (OAViewObject)currentAm.findViewObject("ODOrgAccountSetupPVO");
    if ( ODOrgAccountSetupPVO == null )
                ODOrgAccountSetupPVO = (OAViewObject)currentAm.createViewObject("ODOrgAccountSetupPVO",
                        "od.oracle.apps.xxcrm.customer.account.server.ODOrgAccountSetupPVO");

    ODOrgAccountSetupPVO.setMaxFetchSize(0) ;
    ODOrgAccountSetupPVO.executeQuery();
    ODOrgAccountSetupPVORowImpl readOnlyRow = (ODOrgAccountSetupPVORowImpl)ODOrgAccountSetupPVO.createRow();
    ODOrgAccountSetupPVO.insertRow(readOnlyRow);

    readOnlyRow.setReadOnly(Boolean.FALSE );


    if (pageContext.isBackNavigationFired(true))
    {
        HashMap params = new HashMap();

        pageContext.forwardImmediatelyToCurrentPage(
                       params, //pageParams
                       true, // Retain AM
                       OAWebBeanConstants.ADD_BREAD_CRUMB_NO);
    }

    Number  partyID = null;
    String spartyID = pageContext.getParameter("pid");

    pageContext.writeDiagnostics(METHOD_NAME, "Party id passed = "+spartyID , OAFwkConstants.PROCEDURE);

    pageContext.writeDiagnostics(METHOD_NAME, "Party ID = "+spartyID, OAFwkConstants.PROCEDURE);

    if (spartyID == null || spartyID.length() == 0)  spartyID = pageContext.getParameter("ASNReqFrmCustId");
    if (spartyID == null)
    {
        //This case happens only during cancel button press.
        //Don't want to see any null pointer exception
        spartyID="000";
        pageContext.putParameter("pid", "000");
        pageContext.putParameter("ASNReqFrmCustId", "000");
    }
    try
    {
       partyID = new Number(spartyID);
    }
        catch(SQLException e)
    {
    }

    OAFormValueBean partyIdBean = (OAFormValueBean)webBean.findIndexedChildRecursive("PartyID");
    if (partyIdBean != null)
    partyIdBean.setValue(pageContext.getParameter("pid"));

    OAMessageChoiceBean StdContractTemplate = (OAMessageChoiceBean)webBean.findChildRecursive("StdContractTemplate");
    StdContractTemplate.setPickListCacheEnabled(false);

    OAViewObject ODContractTemplatePoplistVO = (OAViewObject)currentAm.findViewObject("ODContractTemplatePoplistVO");
    if ( ODContractTemplatePoplistVO == null )
            ODContractTemplatePoplistVO = (OAViewObject)currentAm.createViewObject("ODContractTemplatePoplistVO",
                    "od.oracle.apps.xxcrm.customer.account.poplist.server.ODContractTemplatePoplistVO");

    ODContractTemplatePoplistVO.setMaxFetchSize(-1);
    ODContractTemplatePoplistVO.setWhereClauseParam(0,pageContext.getParameter("pid"));
    //VJ Added for QC 5997
    ODContractTemplatePoplistVO.setWhereClauseParam(1,new Integer(pageContext.getEmployeeId()));
    ODContractTemplatePoplistVO.executeQuery();
    ODContractTemplatePoplistVO.getRowCount();


    OAViewObject customerAccountSetupRequestVO = (OAViewObject)currentAm.findViewObject("CustomerAccountSetupRequestVO");
    if ( customerAccountSetupRequestVO == null )
            customerAccountSetupRequestVO = (OAViewObject)currentAm.createViewObject("CustomerAccountSetupRequestVO",
        "od.oracle.apps.xxcrm.customer.account.server.CustomerAccountSetupRequestVO");

    customerAccountSetupRequestVO.setWhereClause("DELETE_FLAG = 'N' AND PARTY_ID = :1 ");
    customerAccountSetupRequestVO.setWhereClauseParam(0, partyID);
    customerAccountSetupRequestVO.executeQuery();

    OAMessageChoiceBean ODBillsiteLov = (OAMessageChoiceBean)webBean.findChildRecursive("BillToSite");
    ODBillsiteLov.setPickListCacheEnabled(false);

    OAMessageChoiceBean ODAPContactLov = (OAMessageChoiceBean)webBean.findChildRecursive("APContactDD");
    ODAPContactLov.setPickListCacheEnabled(false);

    OAMessageChoiceBean ODSalesContactLov = (OAMessageChoiceBean)webBean.findChildRecursive("SalesContactDD");
    ODSalesContactLov.setPickListCacheEnabled(false);

    OAMessageChoiceBean ODShipsiteLov = (OAMessageChoiceBean)webBean.findChildRecursive("ShipToSite");
    ODShipsiteLov.setPickListCacheEnabled(false);

    OAMessageChoiceBean ODPpLov = (OAMessageChoiceBean)webBean.findChildRecursive("PricePlan");
    ODPpLov.setPickListCacheEnabled(false);

    OAViewObject HzPuiAddressTableVO = (OAViewObject)currentAm.findViewObject("HzPuiAddressTableVO");
    if ( HzPuiAddressTableVO == null )
        HzPuiAddressTableVO = (OAViewObject)currentAm.createViewObject("HzPuiAddressTableVO",
        "od.oracle.apps.xxcrm.customer.account.server.ODHzPuiAddressTableVO");

     HzPuiAddressTableVO.setWhereClauseParam(0, pageContext.getParameter("pid"));
     HzPuiAddressTableVO.executeQuery();

     OAViewObject OdCdhAcctTemplateContractsVO = (OAViewObject)currentAm.findViewObject("OdCdhAcctTemplateContractsVO");
     if ( OdCdhAcctTemplateContractsVO == null )
     OdCdhAcctTemplateContractsVO = (OAViewObject)currentAm.createViewObject("OdCdhAcctTemplateContractsVO",
            "od.oracle.apps.xxcrm.customer.account.server.OdCdhAcctTemplateContractsVO");

     String AccountRequestId = pageContext.getParameter("AccountRequestId");
     ODCustomerAccountSetupRequestVORowImpl row;

     if (AccountRequestId != null && AccountRequestId.length() > 0)
     {
       pageContext.writeDiagnostics(METHOD_NAME, "if account id is passed", OAFwkConstants.PROCEDURE);

       row = (ODCustomerAccountSetupRequestVORowImpl)customerAccountSetupRequestVO.first();

       while (row != null)
       {
         if (row.getRequestId().toString().equalsIgnoreCase(AccountRequestId))
         {
                 break;
         }
         row  = (ODCustomerAccountSetupRequestVORowImpl)customerAccountSetupRequestVO.next();
       }
     }
     else
     {
       pageContext.writeDiagnostics(METHOD_NAME, "if no account id is passed", OAFwkConstants.PROCEDURE);
       row = (ODCustomerAccountSetupRequestVORowImpl)customerAccountSetupRequestVO.first();
     }
     /* *** To handle PPRs when the users navigate to the tab region to avoid page refresh and stale data *** */
     //if ("update".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM)))
     // return;

     if (row != null)
     {
       pageContext.writeDiagnostics(METHOD_NAME, "if row exists", OAFwkConstants.PROCEDURE);

       row.setAttribute("SelectFlag","Y");
       oracle.jbo.domain.Number reqId = (oracle.jbo.domain.Number)row.getAttribute("RequestId");
	   pageContext.putParameter("accrequestID", reqId);

       pageContext.writeDiagnostics(METHOD_NAME, "RequestId: " + reqId.stringValue(), OAFwkConstants.PROCEDURE);

       showTheSelectedRequestDtls(pageContext, webBean,reqId.stringValue() );

       //populate Acct Tmpl Cntrs VO for this request_id
       populateAcctTmplCntrsVO( pageContext, OdCdhAcctTemplateContractsVO, reqId.stringValue());

     }
     else
     {
        pageContext.writeDiagnostics(METHOD_NAME, "if no row exists", OAFwkConstants.PROCEDURE);
        showTheSelectedRequestDtls(pageContext, webBean,"0" );

        makeTheFormReadOnly(pageContext, webBean);
        disableButton(pageContext, webBean );
     }

     OAViewObject ODCustomerAccountsVO = (OAViewObject)currentAm.findViewObject("ODCustomerAccountsVO");
     if ( ODCustomerAccountsVO == null )
             ODCustomerAccountsVO = (OAViewObject)currentAm.createViewObject("ODCustomerAccountsVO",
     "od.oracle.apps.xxcrm.customer.account.server.ODCustomerAccountsVO");

     ODCustomerAccountsVO.setWhereClause(null);
     ODCustomerAccountsVO.setWhereClauseParam(0, pageContext.getParameter("pid"));
     ODCustomerAccountsVO.executeQuery();

     ODCustomerAccountsVORowImpl row2 = (ODCustomerAccountsVORowImpl)ODCustomerAccountsVO.first();
     while (row2 != null)
     {
       if (row2.getAccountNumber() != null)
       {
         pageContext.writeDiagnostics(METHOD_NAME, "If Account Number exists make the form read only", OAFwkConstants.PROCEDURE);

         makeTheFormReadOnly(pageContext, webBean);
         disableAllButton(pageContext, webBean);

         ODAccountSetupButtonsPVO = (OAViewObject)currentAm.findViewObject("ODAccountSetupButtonsPVO");
         buttonRenderedRow = (ODAccountSetupButtonsPVORowImpl)ODAccountSetupButtonsPVO.getCurrentRow() ;
         buttonRenderedRow.setAddNewRequestRowRendered(Boolean.FALSE);

         String errMsg = pageContext.getMessage("XXCRM", "XX_SFA_084_CUST_ACCT_EX",null);
         pageContext.putDialogMessage(new OAException(errMsg, OAException.CONFIRMATION));

         return;
       }
       row2  = (ODCustomerAccountsVORowImpl)ODCustomerAccountsVO.next();
     }

     //Anirban: Added for Release 1.2 - Creation of AP and Sales contact
     String custAccMode = (String)pageContext.getSessionValue("makeAccountSetupFormReadOnly");
     if ("101lOl11O".equals(custAccMode))
     {
       makeTheFormReadOnly(pageContext, webBean);
       pageContext.writeDiagnostics("CR687", "Making the Form Read-Only as per ASN security.", OAFwkConstants.STATEMENT);
     }
     pageContext.removeSessionValue("makeAccountSetupFormReadOnly");
     //Anirban: Added for Release 1.2 - Creation of AP and Sales contact

    pageContext.writeDiagnostics(METHOD_NAME, "ODAccountSetupCO processRequest ends", OAFwkConstants.PROCEDURE);
     }

  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    final String METHOD_NAME = "od.oracle.apps.xxcrm.customer.account.webui.ODAccountSetupCO.processFormRequest";
    pageContext.writeDiagnostics(METHOD_NAME, "ODAccountSetupCO processFormRequest begins", OAFwkConstants.PROCEDURE);

    super.processFormRequest(pageContext, webBean);

    OAMessageChoiceBean ODAPContactLov = (OAMessageChoiceBean)webBean.findChildRecursive("APContactDD");
    ODAPContactLov.setPickListCacheEnabled(false);

    OAMessageChoiceBean ODSalesContactLov = (OAMessageChoiceBean)webBean.findChildRecursive("SalesContactDD");
    ODSalesContactLov.setPickListCacheEnabled(false);

    Number  partyID = null;
    try
    {
      pageContext.writeDiagnostics("SMJ", "IN PFR: PartyID:"+pageContext.getParameter("PartyID"), OAFwkConstants.STATEMENT);
      pageContext.writeDiagnostics("SMJ", "IN PFR: ASNReqFrmCustId:"+pageContext.getParameter("ASNReqFrmCustId"), OAFwkConstants.STATEMENT);
      String str_partyId = pageContext.getParameter("PartyID");
      if(str_partyId==null || "".equals(str_partyId))
         str_partyId = pageContext.getParameter("ASNReqFrmCustId");
      partyID = new Number(str_partyId);
      pageContext.writeDiagnostics(METHOD_NAME, " partyID in processformrequest = "+partyID,OAFwkConstants.PROCEDURE);
    }
    catch(SQLException e)
    {
       pageContext.writeDiagnostics(METHOD_NAME,"SQL Exception in processFormRequest",OAFwkConstants.PROCEDURE);
    }

    if ("accNumclick".equals(pageContext.getParameter(EVENT_PARAM)))
    {
         pageContext.writeDiagnostics(METHOD_NAME, "Account Number Link is clicked on", OAFwkConstants.PROCEDURE);
         String pagePartyid=null;
         String pagerequestId = null;

         HashMap params = new HashMap();
         params.put("pagerequestId",pageContext.getParameter("accrequestID"));
         params.put("pagePartyid",pageContext.getParameter("accpartyID"));
         params.put("ASNReqFrmCustId",pageContext.getParameter("accpartyID"));
         pageContext.forwardImmediately("ASN_ORGUPDATEPG",
                               OAWebBeanConstants.KEEP_MENU_CONTEXT,
                               null,
                               params, //pageParams
                               false, // Retain AM
                               OAWebBeanConstants.ADD_BREAD_CRUMB_NO); // Do not display breadcrums
    }

    OAApplicationModule currentAm = (OAApplicationModule) pageContext.getApplicationModule(webBean);
    String pageEvent = pageContext.getParameter("AcctReqEvent");

    OAViewObject    ODContractTemplatesVO = (OAViewObject)currentAm.findViewObject("ODContractTemplatesVO");
    if ( ODContractTemplatesVO == null )
      ODContractTemplatesVO = (OAViewObject)currentAm.createViewObject("ODContractTemplatesVO",
      "od.oracle.apps.xxcrm.customer.account.server.ODContractTemplatesVO");
    ODContractTemplatesVO.setMaxFetchSize(0);
    ODContractTemplatesVO.setWhereClause(null);
    ODContractTemplatesVO.executeQuery();

   OAViewObject ODCustomerAssignedRoleVO = (OAViewObject)currentAm.findViewObject("ODCustomerAssignedRoleVO");

   if ( ODCustomerAssignedRoleVO == null )
     ODCustomerAssignedRoleVO = (OAViewObject)currentAm.createViewObject("ODCustomerAssignedRoleVO",
            "od.oracle.apps.xxcrm.customer.account.server.ODCustomerAssignedRoleVO");
   ODCustomerAssignedRoleVO.setWhereClauseParam(0, pageContext.getParameter("pid"));
   ODCustomerAssignedRoleVO.setWhereClauseParam(1, pageContext.getUserName());
   ODCustomerAssignedRoleVO.executeQuery();
   ODCustomerAssignedRoleVORowImpl rowSalesRole=   (ODCustomerAssignedRoleVORowImpl)ODCustomerAssignedRoleVO.first();

   OAViewObject ODCustomerAccountSetupRequestDetailsVO = (OAViewObject)currentAm.findViewObject("ODCustomerAccountSetupRequestDetailsVO");
   if ( ODCustomerAccountSetupRequestDetailsVO == null )
   ODCustomerAccountSetupRequestDetailsVO = (OAViewObject)currentAm.createViewObject("ODCustomerAccountSetupRequestDetailsVO",
            "od.oracle.apps.xxcrm.customer.account.server.ODCustomerAccountSetupRequestDetailsVO");

   OAViewObject customerAccountSetupRequestVO = (OAViewObject)currentAm.findViewObject("CustomerAccountSetupRequestVO");
   if ( customerAccountSetupRequestVO == null )
   customerAccountSetupRequestVO = (OAViewObject)currentAm.createViewObject("CustomerAccountSetupRequestVO",
            "od.oracle.apps.xxcrm.customer.account.server.CustomerAccountSetupRequestVO");

   OAViewObject ODCustAcctSetupContractsVO = (OAViewObject)currentAm.findViewObject("ODCustAcctSetupContractsVO");
   if ( ODCustAcctSetupContractsVO == null )
   ODCustAcctSetupContractsVO = (OAViewObject)currentAm.createViewObject("ODCustAcctSetupContractsVO",
            "od.oracle.apps.xxcrm.customer.account.server.ODCustAcctSetupContractsVO");

   OAViewObject OdCdhAcctTemplateContractsVO = (OAViewObject)currentAm.findViewObject("OdCdhAcctTemplateContractsVO");
   if ( OdCdhAcctTemplateContractsVO == null )
   OdCdhAcctTemplateContractsVO = (OAViewObject)currentAm.createViewObject("OdCdhAcctTemplateContractsVO",
            "od.oracle.apps.xxcrm.customer.account.server.OdCdhAcctTemplateContractsVO");

   String reqId1 = pageContext.getParameter("accrequestID");


   pageContext.writeDiagnostics(METHOD_NAME, "accrequestID: " + pageContext.getParameter("accrequestID"), OAFwkConstants.PROCEDURE);
   pageContext.writeDiagnostics(METHOD_NAME, "newreqID: " + pageContext.getParameter("newreqID"), OAFwkConstants.PROCEDURE);
   pageContext.writeDiagnostics(METHOD_NAME, "AccReqSelectedId: " + pageContext.getParameter("AccReqSelectedId"), OAFwkConstants.PROCEDURE);

   //populate Acct Tmpl Cntrs VO for this request_id
   populateAcctTmplCntrsVO( pageContext, OdCdhAcctTemplateContractsVO, reqId1);

    //Document table initialization
    OAViewObject ODCustAcctSetupDocumentVO = (OAViewObject)currentAm.findViewObject("ODCustAcctSetupDocumentVO");
    if ( ODCustAcctSetupDocumentVO == null )
    ODCustAcctSetupDocumentVO = (OAViewObject)currentAm.createViewObject("ODCustAcctSetupDocumentVO",
             "od.oracle.apps.xxcrm.customer.account.server.ODCustAcctSetupDocumentVO");

    if ("RequestIDSelection".equals(pageEvent))
    {
      pageContext.writeDiagnostics(METHOD_NAME, "RequestIDSelection", OAFwkConstants.PROCEDURE);

      String parID = (String) pageContext.getParameter("ASNReqFrmCustId");
      if (parID == null) parID = pageContext.getParameter("PartyID");

      OAViewObject ODCustomerAccountsVO = (OAViewObject)currentAm.findViewObject("ODCustomerAccountsVO");
      if ( ODCustomerAccountsVO == null )
              ODCustomerAccountsVO = (OAViewObject)currentAm.createViewObject("ODCustomerAccountsVO",
      "od.oracle.apps.xxcrm.customer.account.server.ODCustomerAccountsVO");

      ODCustomerAccountsVO.setWhereClause(null);
      ODCustomerAccountsVO.setWhereClauseParam(0, parID);
      ODCustomerAccountsVO.executeQuery();

      ODCustomerAccountsVORowImpl row2 = (ODCustomerAccountsVORowImpl)ODCustomerAccountsVO.first();

      String newreqID= null;

      if (row2 != null && row2.getAccountNumber() != null)
      {
         pageContext.writeDiagnostics(METHOD_NAME, "SATYA:If Account Number exists make the form read only2", OAFwkConstants.PROCEDURE);

         newreqID= pageContext.getParameter("AccReqSelectedId");
         showTheSelectedRequestDtls(pageContext, webBean,newreqID);
         pageContext.putParameter("newreqID", newreqID);
         makeTheFormReadOnly(pageContext, webBean);
         disableAllButton(pageContext, webBean);
       }
       else
       {
         newreqID= pageContext.getParameter("AccReqSelectedId");
         showTheSelectedRequestDtls(pageContext, webBean,newreqID);
         pageContext.putParameter("newreqID", newreqID);
       }
       try{
       //populate OdCdhAcctTemplateContractsVO
       if( newreqID != null)

        populateAcctTmplCntrsVO( pageContext, OdCdhAcctTemplateContractsVO, newreqID);
       } catch (Exception e){
         pageContext.writeDiagnostics(METHOD_NAME, "Exception: " + e.toString(), OAFwkConstants.PROCEDURE);
       }
    }
    else
    if ("ValidateAndSave".equals(pageEvent))
    {
        pageContext.writeDiagnostics(METHOD_NAME, "ValidateAndSave", OAFwkConstants.PROCEDURE);

        ODCustomerAccountSetupRequestDetailsVORowImpl curRow= (ODCustomerAccountSetupRequestDetailsVORowImpl)ODCustomerAccountSetupRequestDetailsVO.getCurrentRow();
         if (curRow != null)
         {
            //Added for Release 1.02 - Adding Loyalty and Segmentation
            if(!isSgmntnChanged(curRow, pageContext.getParameter("SegmentationLOVCode")))
              populateSegmentation(pageContext, currentAm, curRow, partyID);
            if(!isLyltyChanged(curRow, pageContext.getParameter("LoyaltyLOVCode")))
              populateLoyalty(pageContext, currentAm, curRow, partyID);
            //End of code change for Release 1.02 - Adding Loyalty and Segmentation

            //Contract Compliance Rel10.3 changes start
            String contractTemplateId = pageContext.getParameter("StdContractTemplate");
            if( contractTemplateId != null)
              try{
                  curRow.setContractTemplateId(new Number(contractTemplateId.trim()));
              } catch (Exception eContrTem) {
                //throw new OAException("Unexpected Error has occurred when storing Contract. If it persists. Please communicate with System Administrator");
                String errorMsg = pageContext.getMessage("XXCRM", "XX_CRM_TMPL_REQUIRED", null);
                pageContext.putDialogMessage(new OAException(errorMsg, OAException.ERROR));
                return;
              }
            //Contract Compliance Rel10.3 changes end


            if ( "Submitted".equalsIgnoreCase(curRow.getStatus())) return;

            boolean retStatus = validateAccountRequestRecord(pageContext, webBean, curRow);
            if (retStatus == true)
            {
                pageContext.writeDiagnostics(METHOD_NAME, "Validated", OAFwkConstants.PROCEDURE);

                //Anirban: Added for Release 1.2 - Creation of AP and Sales contact
                String salesContactDD = pageContext.getParameter("SalesContactDD");
                String apContactDD = pageContext.getParameter("APContactDD");
                String paymentMethod = curRow.getPaymentMethod();
                if(paymentMethod.equals("AB"))
                {
                  String partyId = partyID.stringValue();
                  pageContext.writeDiagnostics("CR687", "Calling create/update api's. Inside ValidateAndSave event. PaymentMethod is AB", OAFwkConstants.STATEMENT);
                  createUpdateSalescontact(pageContext, currentAm, curRow, salesContactDD, partyId);
                  createUpdateAPcontact(pageContext, currentAm, curRow, apContactDD, partyId);
                }
                else
                {
                  String partyId = partyID.stringValue();
                  createUpdateSalescontact(pageContext, currentAm, curRow, salesContactDD, partyId);
                  String l_varNull = null;
                  curRow.setAttribute13(l_varNull);
                  pageContext.writeDiagnostics("CR687", "Calling create/update api's. Inside ValidateAndSave event. PaymentMethod is NOT AB!", OAFwkConstants.STATEMENT);
                }

                salesContactDD = curRow.getApContact();
                apContactDD = curRow.getAttribute13();

                //Anirban: Added for Release 1.2 - Creation of AP and Sales contact


                curRow.setStatus("Validated");
                curRow.setStatusTransitionDate(currentAm.getOADBTransaction().getCurrentDBDate());
                currentAm.getTransaction().commit();
                Row[] rows = customerAccountSetupRequestVO.getFilteredRows("SelectFlag", "Y");
                if (rows != null && rows.length >0)
                {
                  ODCustomerAccountSetupRequestVORowImpl row = (ODCustomerAccountSetupRequestVORowImpl)rows[0];
                  row.setStatus("Validated");
                  row.setStatusTransitionDate(currentAm.getOADBTransaction().getCurrentDBDate());
                }

                //Anirban: Added for Release 1.2 - Creation of AP and Sales contact

                pageContext.writeDiagnostics("CR687", "Calling initializeAPandSalesContact api. Inside ValidateAndSave event. Querying up the LOV VO's as well!", OAFwkConstants.STATEMENT);

                initializeAPandSalesContact(pageContext, webBean, apContactDD, salesContactDD, paymentMethod);

                //Populate AP Contact DD details
                OAViewObject ODApContactLovVO = (OAViewObject)currentAm.findViewObject("ODApContactLovVO");
                if ( ODApContactLovVO != null )
                   ODApContactLovVO.remove();

                ODApContactLovVO = (OAViewObject)currentAm.createViewObject("ODApContactLovVO",
                 "od.oracle.apps.xxcrm.customer.account.poplist.server.ODApContactLovVO");

                ODApContactLovVO.setWhereClauseParam(0, partyID);
                ODApContactLovVO.executeQuery();

                //Populate Sales Contact DD details
                OAViewObject ODSalesContactLovVO = (OAViewObject)currentAm.findViewObject("ODSalesContactLovVO");
                if ( ODSalesContactLovVO != null )
                    ODSalesContactLovVO.remove();

                ODSalesContactLovVO = (OAViewObject)currentAm.createViewObject("ODSalesContactLovVO",
                "od.oracle.apps.xxcrm.customer.account.poplist.server.ODApContactLovVO");

                ODSalesContactLovVO.setWhereClauseParam(0, partyID);
                ODSalesContactLovVO.executeQuery();

                //Anirban: Added for Release 1.2 - Creation of AP and Sales contact
            }
         }
    }
    else
    if ("DeleteRequest".equals(pageEvent))
    {
      pageContext.writeDiagnostics(METHOD_NAME, "DeleteRequest", OAFwkConstants.PROCEDURE);
      ODCustomerAccountSetupRequestDetailsVORowImpl curRow= (ODCustomerAccountSetupRequestDetailsVORowImpl)ODCustomerAccountSetupRequestDetailsVO.getCurrentRow();
      if (curRow != null)
      {
          if ( "Submitted".equalsIgnoreCase(curRow.getStatus())) return;
            //curRow.remove();
            curRow.setDeleteFlag("Y");

          ODCustAcctSetupContractsVORowImpl curReqContractRow;
          curReqContractRow = (ODCustAcctSetupContractsVORowImpl)ODCustAcctSetupContractsVO.first();
          while (curReqContractRow != null)
          {
            //curReqContractRow.remove();
            curReqContractRow.setDeleteFlag("Y");
            curReqContractRow = (ODCustAcctSetupContractsVORowImpl)ODCustAcctSetupContractsVO.next();
          }
          ODCustAcctSetupDocumentVORowImpl curReqDocRow;
          curReqDocRow = (ODCustAcctSetupDocumentVORowImpl)ODCustAcctSetupDocumentVO.first();
          while (curReqDocRow != null)
          {
            //curReqDocRow.remove();
            curReqDocRow.setDeleteFlag("Y");
            curReqDocRow = (ODCustAcctSetupDocumentVORowImpl)ODCustAcctSetupDocumentVO.next();
          }
          //remove old rows in this VO for this request_id
          clearTemplateContractsVORows( pageContext, currentAm, curRow.getRequestId(), OdCdhAcctTemplateContractsVO);

          currentAm.getTransaction().commit();
       }
       customerAccountSetupRequestVO.executeQuery();

      ODCustomerAccountSetupRequestVORowImpl row = (ODCustomerAccountSetupRequestVORowImpl)customerAccountSetupRequestVO.first();
      if (row!=null)
      {
         pageContext.writeDiagnostics(METHOD_NAME, "Calling Enable Button", OAFwkConstants.PROCEDURE);
         enableButton(pageContext, webBean);
      }
      else
      {
         pageContext.writeDiagnostics(METHOD_NAME, "Calling Disable Button", OAFwkConstants.PROCEDURE);
         disableButton(pageContext, webBean);
      }
      if (row != null)
      {
         row.setAttribute("SelectFlag","Y");
         oracle.jbo.domain.Number reqId = (oracle.jbo.domain.Number)row.getAttribute("RequestId");
		 pageContext.putParameter("accrequestID", reqId.toString());
         showTheSelectedRequestDtls(pageContext,webBean,reqId.toString() );

      }
      else
      {
         makeTheFormReadOnly(pageContext, webBean);
         disableButton(pageContext,webBean);
      }
      row = (ODCustomerAccountSetupRequestVORowImpl)customerAccountSetupRequestVO.first();
      while (row != null)
      {
          if (row.getAccountNumber() != null)
          {
            makeTheFormReadOnly(pageContext, webBean);
            return;
          }
          row  = (ODCustomerAccountSetupRequestVORowImpl)customerAccountSetupRequestVO.next();
      }

    }
    else
    if ("AddNewRequestRow".equals(pageEvent))
    {
        try
        {
            pageContext.writeDiagnostics(METHOD_NAME, "AddNewRequestRow", OAFwkConstants.PROCEDURE);
            currentAm.getTransaction().rollback();
            Number seqCur = currentAm.getOADBTransaction().getSequenceValue("XX_CDH_ACCOUNT_SETUP_REQ_S");
            ODCustomerAccountSetupRequestDetailsVORowImpl newRow = (ODCustomerAccountSetupRequestDetailsVORowImpl)ODCustomerAccountSetupRequestDetailsVO.createRow();
            newRow.setRequestId(seqCur);
            newRow.setStatus("Draft");
            newRow.setDeleteFlag("N");
            newRow.setPoValidated("H");
            newRow.setReleaseValidated("H");
            newRow.setDepartmentValidated("H");
            newRow.setDesktopValidated("H");
            newRow.setPartyId(partyID);

            //Added for Release 1.02 - Adding Loyalty and Segmentation
            populateSegmentation(pageContext, currentAm, newRow, partyID);
            populateLoyalty(pageContext, currentAm, newRow, partyID);
            //End of code change for Release 1.02 - Adding Loyalty and Segmentation

            //Contract Compliance Rel10.3 changes start
            String contractTemplateId = pageContext.getParameter("StdContractTemplate");
            if( contractTemplateId != null)
              try{
                  newRow.setContractTemplateId(new Number(contractTemplateId.trim()));
              } catch (Exception eContrTem) {
                //throw new OAException("Unexpected Error has occurred when storing Contract. If it persists. Please communicate with System Administrator");
                String errorMsg = pageContext.getMessage("XXCRM", "XX_CRM_TMPL_REQUIRED", null);
                pageContext.putDialogMessage(new OAException(errorMsg, OAException.ERROR));
                return;
              }
            //Contract Compliance Rel10.3 changes end

            setDefaultValues(currentAm, newRow);
            pageContext.writeDiagnostics(METHOD_NAME, "in add new row after calling setDefaultValues", OAFwkConstants.PROCEDURE);

            ODCustomerAccountSetupRequestDetailsVO.insertRow(newRow);
            currentAm.getTransaction().commit();

            customerAccountSetupRequestVO.executeQuery();
            ODCustomerAccountSetupRequestVORowImpl curRow = (ODCustomerAccountSetupRequestVORowImpl)customerAccountSetupRequestVO.last();
            if(curRow != null)
            {
                curRow.setAttribute("SelectFlag","Y");
            }
            ODCustomerAccountSetupRequestDetailsVO.setWhereClause(" DELETE_FLAG = 'N' AND REQUEST_ID = :1 ");
            ODCustomerAccountSetupRequestDetailsVO.setWhereClauseParam(0, seqCur);
            ODCustomerAccountSetupRequestDetailsVO.executeQuery();

            pageContext.writeDiagnostics(METHOD_NAME, "in add rows after ODCustomerAccountSetupRequestDetailsVO", OAFwkConstants.PROCEDURE);

            //ODCustAcctSetupContractsVO.setWhereClause("DELETE_FLAG = 'N' AND account_request_id = :1 ");
            //ODCustAcctSetupContractsVO.setWhereClauseParam(0, seqCur);
            //ODCustAcctSetupContractsVO.executeQuery();

            pageContext.writeDiagnostics(METHOD_NAME, "in add rows after ODCustAcctSetupContractsVO", OAFwkConstants.PROCEDURE);

            ODCustAcctSetupDocumentVO.setWhereClause(" DELETE_FLAG = 'N' AND account_request_id = :1 ");
            ODCustAcctSetupDocumentVO.setWhereClauseParam(0, seqCur);
            ODCustAcctSetupDocumentVO.executeQuery();
            pageContext.writeDiagnostics(METHOD_NAME, "in add rows after ODCustAcctSetupDocumentVO", OAFwkConstants.PROCEDURE);

            OAViewObject ODHzPuiAddressTableVO = (OAViewObject)currentAm.findViewObject("ODHzPuiAddressTableVO");
            if ( ODHzPuiAddressTableVO == null )
              ODHzPuiAddressTableVO = (OAViewObject)currentAm.createViewObject("ODHzPuiAddressTableVO",
                    "od.oracle.apps.xxcrm.customer.account.server.ODHzPuiAddressTableVO");

            ODHzPuiAddressTableVO.setWhereClauseParam(0, partyID);
            ODHzPuiAddressTableVO.executeQuery();
            pageContext.writeDiagnostics(METHOD_NAME, "in add rows after ODHzPuiAddressTableVO", OAFwkConstants.PROCEDURE);

            //Anirban: Added for Release 1.2 - Creation of AP and Sales contact

            String salesContactDD = "";
            String apContactDD = "";
            String paymentMethod = "AB";

            pageContext.writeDiagnostics("CR687", "Calling initializeAPandSalesContact api. Inside AddNewRequestRow event. Querying up the LOV VO's as well!", OAFwkConstants.STATEMENT);

            initializeAPandSalesContact(pageContext, webBean, apContactDD, salesContactDD, paymentMethod);

            //Populate AP Contact DD details
            OAViewObject ODApContactLovVO = (OAViewObject)currentAm.findViewObject("ODApContactLovVO");
            if ( ODApContactLovVO != null )
                ODApContactLovVO.remove();

            ODApContactLovVO = (OAViewObject)currentAm.createViewObject("ODApContactLovVO",
                   "od.oracle.apps.xxcrm.customer.account.poplist.server.ODApContactLovVO");

            ODApContactLovVO.setWhereClauseParam(0, partyID);
            ODApContactLovVO.executeQuery();

            //Populate Sales Contact DD details
            OAViewObject ODSalesContactLovVO = (OAViewObject)currentAm.findViewObject("ODSalesContactLovVO");
            if ( ODSalesContactLovVO != null )
               ODSalesContactLovVO.remove();

            ODSalesContactLovVO = (OAViewObject)currentAm.createViewObject("ODSalesContactLovVO",
                   "od.oracle.apps.xxcrm.customer.account.poplist.server.ODApContactLovVO");

            ODSalesContactLovVO.setWhereClauseParam(0, partyID);
            ODSalesContactLovVO.executeQuery();

                //Anirban: Added for Release 1.2 - Creation of AP and Sales contact

            pageContext.writeDiagnostics(METHOD_NAME, "in add rows after ODApContactLovVO", OAFwkConstants.PROCEDURE);

            makeTheFormEditable(pageContext, webBean);
            enableButton(pageContext, webBean);
            pageContext.writeDiagnostics(METHOD_NAME, "in add rows after makeTheFormEditable", OAFwkConstants.PROCEDURE);

        }
        catch (Exception e)
        {
          throw new OAException("Unexpected Error has occurred.If it persists. Please communicate with System Administrator");
        }

    }
    else
    if ("CopyRequestRow".equals(pageEvent))
    {
       pageContext.writeDiagnostics(METHOD_NAME, "CopyRequestRow", OAFwkConstants.PROCEDURE);

       //System.out.println("sudeept copy request row");

        Number curSeq = currentAm.getOADBTransaction().getSequenceValue("XX_CDH_ACCOUNT_SETUP_REQ_S");
        ODCustomerAccountSetupRequestDetailsVORowImpl selRow = (ODCustomerAccountSetupRequestDetailsVORowImpl)ODCustomerAccountSetupRequestDetailsVO.getCurrentRow();
        ODCustomerAccountSetupRequestDetailsVORowImpl newRow = (ODCustomerAccountSetupRequestDetailsVORowImpl)ODCustomerAccountSetupRequestDetailsVO.createRow();
        newRow.setRequestId(curSeq);
        newRow.setStatus("Draft");
        newRow.setStatusTransitionDate(null);

        newRow.setPartyId(selRow.getPartyId());
        newRow.setAccountCreationSystem(selRow.getAccountCreationSystem());
        newRow.setBillToSiteId(selRow.getBillToSiteId());
        newRow.setShipToSiteId(selRow.getShipToSiteId());
        newRow.setOffContractCode(selRow.getOffContractCode() );
        newRow.setOffWholesaleCode(selRow.getOffWholesaleCode());
        newRow.setOffContractPercentage(selRow.getOffContractPercentage());
        newRow.setWholesalePercentage(selRow.getWholesalePercentage());
        newRow.setGpFloorPercentage(selRow.getGpFloorPercentage());
        newRow.setPricePlan(selRow.getPricePlan());
        newRow.setAttribute2(selRow.getAttribute2());
        newRow.setParentId(selRow.getParentId());
        newRow.setXref(selRow.getXref());
        newRow.setPoValidated(selRow.getPoValidated());
        newRow.setReleaseValidated(selRow.getReleaseValidated());
        newRow.setDepartmentValidated(selRow.getDepartmentValidated());
        newRow.setDesktopValidated(selRow.getDesktopValidated());
        newRow.setPoHeader(selRow.getPoHeader());
        newRow.setReleaseHeader(selRow.getReleaseHeader());
        newRow.setDepartmentHeader(selRow.getDepartmentHeader());
        newRow.setDesktopHeader(selRow.getDesktopHeader());
        newRow.setAfax(selRow.getAfax());
        newRow.setFaxOrder(selRow.getFaxOrder());
        newRow.setSubstitutions(selRow.getSubstitutions());
        newRow.setBackOrders(selRow.getBackOrders());
        newRow.setFreightCharge(selRow.getFreightCharge());
        newRow.setDeliveryDocumentType("INVOICE");
        newRow.setPrintInvoice(selRow.getPrintInvoice());
        newRow.setRenamePackingList(selRow.getRenamePackingList());
        newRow.setDisplayPaymentMethod(selRow.getDisplayPaymentMethod());
        newRow.setDisplayBackOrder(selRow.getDisplayBackOrder());
        newRow.setDisplayPurchaseOrder(selRow.getDisplayPurchaseOrder());
        newRow.setDisplayPrices(selRow.getDisplayPrices());
        newRow.setPaymentMethod(selRow.getPaymentMethod());
        newRow.setProcurementCard(selRow.getProcurementCard());
        newRow.setComments(selRow.getComments());
        newRow.setDeleteFlag(selRow.getDeleteFlag());
        newRow.setAttribute5(selRow.getAttribute5() );
        //Added for Release 1.02 - Adding Loyalty and Segmentation
        newRow.setAttribute14(selRow.getAttribute14() );
        newRow.setAttribute15(selRow.getAttribute15() );
        //End of code change for Release 1.02 - Adding Loyalty and Segmentation

        //Anirban: Added for Release 1.2 - Creation of AP and Sales contact
        String salesContactDD = (String)(selRow.getApContact());
        String apContactDD = (String)(selRow.getAttribute13());
        String paymentMethod = selRow.getPaymentMethod();
        pageContext.writeDiagnostics("CR687", "Inside CopyRequestRow event. Copying the Sales and AP contact's value.", OAFwkConstants.STATEMENT);
        newRow.setApContact(selRow.getApContact());
        newRow.setAttribute13(selRow.getAttribute13());
        //Anirban: Added for Release 1.2 - Creation of AP and Sales contact

        ODCustomerAccountSetupRequestDetailsVO.insertRow(newRow);

        //Copy the contracts
        ODCustAcctSetupContractsVO = (OAViewObject)currentAm.findViewObject("ODCustAcctSetupContractsVO");

        OAViewObject ODCustAcctSetupContractsNewVO = (OAViewObject)currentAm.findViewObject("ODCustAcctSetupContractsNewVO");

        if (ODCustAcctSetupContractsNewVO == null)
        ODCustAcctSetupContractsNewVO = (OAViewObject)currentAm.createViewObject("ODCustAcctSetupContractsNewVO",
              "od.oracle.apps.xxcrm.customer.account.server.ODCustAcctSetupContractsVO");
        ODCustAcctSetupContractsVORowImpl newContractRow;

        ODCustAcctSetupContractsVORowImpl curContractRow;
        curContractRow = (ODCustAcctSetupContractsVORowImpl)ODCustAcctSetupContractsVO.first();
        Number curContSeq;
        while (curContractRow != null)
        {
          newContractRow = (ODCustAcctSetupContractsVORowImpl)ODCustAcctSetupContractsNewVO.createRow();
          curContSeq = currentAm.getOADBTransaction().getSequenceValue("XX_CDH_ACCT_SETUP_CONTRACTS_S");
          newContractRow.setAccountRequestId(curSeq);
          newContractRow.setSetupContractId(curContSeq);
          newContractRow.setContractNumber(curContractRow.getContractNumber());
          newContractRow.setContractDescription(curContractRow.getContractDescription());
          newContractRow.setPriority(curContractRow.getPriority());
          newContractRow.setCustom(curContractRow.getCustom());
          newContractRow.setDeleteFlag("N");
          ODCustAcctSetupContractsNewVO.insertRow(newContractRow);
          curContractRow = (ODCustAcctSetupContractsVORowImpl)ODCustAcctSetupContractsVO.next();
        }

        //Copy the documents and document properties
        ODCustAcctSetupDocumentVO = (OAViewObject)currentAm.findViewObject("ODCustAcctSetupDocumentVO");

        OAViewObject ODCustAcctSetupDocumentNewVO = (OAViewObject)currentAm.findViewObject("ODCustAcctSetupDocumentNewVO");
        if (ODCustAcctSetupDocumentNewVO == null)
        ODCustAcctSetupDocumentNewVO = (OAViewObject)currentAm.createViewObject("ODCustAcctSetupDocumentNewVO",
              "od.oracle.apps.xxcrm.customer.account.server.ODCustAcctSetupDocumentVO");
        ODCustAcctSetupDocumentVORowImpl newDocumentRow;

        ODCustAcctSetupDocumentVORowImpl curDocumentRow;
        curDocumentRow = (ODCustAcctSetupDocumentVORowImpl)ODCustAcctSetupDocumentVO.first();
        Number curDocSeq;


        while (curDocumentRow != null)
        {
          newDocumentRow = (ODCustAcctSetupDocumentVORowImpl)ODCustAcctSetupDocumentNewVO.createRow();
          curDocSeq = currentAm.getOADBTransaction().getSequenceValue("XX_CDH_ACCT_SETUP_DOCUMENTS_S");
          newDocumentRow.setAccountRequestId(curSeq);
          newDocumentRow.setDocumentId(curDocSeq);
          newDocumentRow.setDocumentType(curDocumentRow.getDocumentType());
          newDocumentRow.setDocumentName(curDocumentRow.getDocumentName());
          newDocumentRow.setDocumentType(curDocumentRow.getDocumentType());
          newDocumentRow.setDetail(curDocumentRow.getDetail());
          newDocumentRow.setFrequency(curDocumentRow.getFrequency());
          newDocumentRow.setIndirect(curDocumentRow.getIndirect());
          newDocumentRow.setInclBackupInv(curDocumentRow.getInclBackupInv());
          newDocumentRow.setDeleteFlag("N");
          ODCustAcctSetupDocumentNewVO.insertRow(newDocumentRow);

        }



        //populateAcctTmplCntrsVO( pageContext, OdCdhAcctTemplateContractsVO, curSeq.toString());
        String contractTemplateId = pageContext.getParameter("StdContractTemplate");

	   //populate OdCdhAcctTemplateContractsVO

		if( curSeq != null)
		  populateAcctTmplCntrsVO( pageContext, OdCdhAcctTemplateContractsVO, curSeq.toString());

        //Copy ODContractsAssignedVO into OdCdhAcctTemplateContractsVO from the request
        copyCntrsFromAcctReq(pageContext, currentAm, selRow.getRequestId(), curSeq, contractTemplateId, OdCdhAcctTemplateContractsVO);

        currentAm.getTransaction().commit();

        pageContext.writeDiagnostics(METHOD_NAME, "reset the selection to point to the newly created row", OAFwkConstants.PROCEDURE);

        //reset the selection to point to the newly created row.
        customerAccountSetupRequestVO.executeQuery();
        ODCustomerAccountSetupRequestVORowImpl curRow = (ODCustomerAccountSetupRequestVORowImpl)customerAccountSetupRequestVO.last();
        if(curRow != null)
        {
            curRow.setAttribute("SelectFlag","Y");
        }
        ODCustomerAccountSetupRequestDetailsVO.setWhereClause(" DELETE_FLAG = 'N' AND REQUEST_ID = :1 ");
        ODCustomerAccountSetupRequestDetailsVO.setWhereClauseParam(0, curSeq);
        ODCustomerAccountSetupRequestDetailsVO.executeQuery();

        ODCustAcctSetupContractsVO.setWhereClause("DELETE_FLAG = 'N' AND account_request_id = :1 ");
        ODCustAcctSetupContractsVO.setWhereClauseParam(0, curSeq);
        ODCustAcctSetupContractsVO.executeQuery();

        ODCustAcctSetupDocumentVO.setWhereClause(" DELETE_FLAG = 'N' AND  account_request_id = :1 ");
        ODCustAcctSetupDocumentVO.setWhereClauseParam(0, curSeq);
        ODCustAcctSetupDocumentVO.executeQuery();

        //Anirban: Added for Release 1.2 - Creation of AP and Sales contact

        pageContext.writeDiagnostics("CR687", "Calling initializeAPandSalesContact api. Inside CopyRequestRow event. Querying up the LOV VO's as well!", OAFwkConstants.STATEMENT);

        initializeAPandSalesContact(pageContext, webBean, apContactDD, salesContactDD, paymentMethod);

        //Populate AP Contact DD details
        OAViewObject ODApContactLovVO = (OAViewObject)currentAm.findViewObject("ODApContactLovVO");
        if ( ODApContactLovVO != null )
            ODApContactLovVO.remove();

        ODApContactLovVO = (OAViewObject)currentAm.createViewObject("ODApContactLovVO",
               "od.oracle.apps.xxcrm.customer.account.poplist.server.ODApContactLovVO");

        ODApContactLovVO.setWhereClauseParam(0, partyID);
        ODApContactLovVO.executeQuery();

        //Populate Sales Contact DD details
        OAViewObject ODSalesContactLovVO = (OAViewObject)currentAm.findViewObject("ODSalesContactLovVO");
        if ( ODSalesContactLovVO != null )
                    ODSalesContactLovVO.remove();

        ODSalesContactLovVO = (OAViewObject)currentAm.createViewObject("ODSalesContactLovVO",
               "od.oracle.apps.xxcrm.customer.account.poplist.server.ODApContactLovVO");

        ODSalesContactLovVO.setWhereClauseParam(0, partyID);
        ODSalesContactLovVO.executeQuery();

        //Anirban: Added for Release 1.2 - Creation of AP and Sales contact

        makeTheFormEditable(pageContext, webBean);
        enableButton(pageContext, webBean);
    }
    else
    if ("AddCustomContract".equals(pageEvent))
    {
       pageContext.writeDiagnostics(METHOD_NAME, "AddCustomContract", OAFwkConstants.PROCEDURE);
        ODCustomerAccountSetupRequestDetailsVORowImpl masterRow = (ODCustomerAccountSetupRequestDetailsVORowImpl)ODCustomerAccountSetupRequestDetailsVO.first();
        if ( "Submitted".equalsIgnoreCase(masterRow.getStatus())) return;
        OAViewObject vo  = (OAViewObject)currentAm.findViewObject("ODCustAcctSetupContractsVO");

        ODCustAcctSetupContractsVORowImpl newRow = (ODCustAcctSetupContractsVORowImpl)ODCustAcctSetupContractsVO.createRow();
        newRow.setAccountRequestId(masterRow.getRequestId());
        Number curSeq = currentAm.getOADBTransaction().getSequenceValue("XX_CDH_ACCT_SETUP_CONTRACTS_S");
        newRow.setSetupContractId(curSeq);
        newRow.setDeleteFlag("N");
        newRow.setCustom("Y");
        vo.insertRowAtRangeIndex(vo.getRangeSize(),newRow);
        currentAm.getTransaction().commit();
    }
    else
    if ("DeleteContract".equals(pageEvent))
    {
       pageContext.writeDiagnostics(METHOD_NAME, "DeleteContract", OAFwkConstants.PROCEDURE);

       ODCustomerAccountSetupRequestDetailsVORowImpl masterRow = (ODCustomerAccountSetupRequestDetailsVORowImpl)ODCustomerAccountSetupRequestDetailsVO.first();

       Row[] rows = ODCustAcctSetupContractsVO.getFilteredRows("SelectFlag", "Y");
       ODCustAcctSetupContractsVORowImpl row = null;
       for (int i = 0; i < rows.length; i++)
       {
         row = (ODCustAcctSetupContractsVORowImpl)rows[i];
         //row.remove();
         row.setDeleteFlag("Y");
       }
       currentAm.getTransaction().commit();
       ODCustAcctSetupContractsVO.executeQuery();
    }
    if ("AddAssnContract".equals(pageEvent))
    {
        pageContext.writeDiagnostics(METHOD_NAME, "In AddAssnContract Start--", OAFwkConstants.PROCEDURE);
        String contractTemplateId = pageContext.getParameter("StdContractTemplate");
        pageContext.writeDiagnostics(METHOD_NAME, "contractTemplateId: " + contractTemplateId, OAFwkConstants.PROCEDURE);

        ODCustomerAccountSetupRequestDetailsVORowImpl masterRow1 = (ODCustomerAccountSetupRequestDetailsVORowImpl)ODCustomerAccountSetupRequestDetailsVO.getCurrentRow();

        if ( "Submitted".equalsIgnoreCase(masterRow1.getStatus())) return;
        OAViewObject vo1  = (OAViewObject)currentAm.findViewObject("OdCdhAcctTemplateContractsVO");

        vo1.last();
		vo1.next();
        OdCdhAcctTemplateContractsVORowImpl newRow1 = (OdCdhAcctTemplateContractsVORowImpl)OdCdhAcctTemplateContractsVO.createRow();

        if( contractTemplateId != null) {
          try{

				newRow1.setNewRowState(Row.STATUS_INITIALIZED);
                vo1.insertRow(newRow1);

				newRow1.setContractTemplateId(new Number(contractTemplateId.trim()));
                newRow1.setAccountRequestId(masterRow1.getRequestId());
                Number curSeq1 = currentAm.getOADBTransaction().getSequenceValue("XX_CDH_ACCT_TMPL_CONTRACTS_S");

                newRow1.setSetupContractTemplateId(curSeq1);
                newRow1.setDeleteFlag("N");
                newRow1.setCustom("N");
				vo1.setCurrentRow(newRow1);

              //  currentAm.getTransaction().commit();    /* Commented by Devi */
                if(!vo1.isPreparedForExecution())
                  vo1.executeQuery();
                pageContext.writeDiagnostics(METHOD_NAME, "VO1 fetch size: " + vo1.getRowCount(), OAFwkConstants.PROCEDURE);


             } catch (Exception eContrTem) {
                //throw new OAException("Unexpected Error has occurred when storing Contract. If it persists. Please communicate with System Administrator");
                String errorMsg = pageContext.getMessage("XXCRM", "XX_CRM_TMPL_REQUIRED", null);
                pageContext.putDialogMessage(new OAException(errorMsg, OAException.ERROR));
                pageContext.writeDiagnostics(METHOD_NAME, "Exception Add Assign Contract 1039", OAFwkConstants.PROCEDURE);
                return;
             }
        }
        pageContext.writeDiagnostics(METHOD_NAME, "In AddAssnContract End--", OAFwkConstants.PROCEDURE);

    }
    else
    if ("DeleteAssnContract".equals(pageEvent))
    {
       pageContext.writeDiagnostics(METHOD_NAME, "DeleteContract", OAFwkConstants.PROCEDURE);

       Row[] rows = OdCdhAcctTemplateContractsVO.getFilteredRows("SelectFlag", "Y");
       OdCdhAcctTemplateContractsVORowImpl row = null;
       for (int i = 0; i < rows.length; i++)
       {
         row = (OdCdhAcctTemplateContractsVORowImpl)rows[i];
         row.remove();
       }
       currentAm.getTransaction().commit();
       OdCdhAcctTemplateContractsVO.executeQuery();
    }
    else
    if ("SubmitRequest".equals(pageEvent))
    {
        pageContext.writeDiagnostics(METHOD_NAME, "SubmitRequest", OAFwkConstants.PROCEDURE);
        ODCustomerAccountSetupRequestDetailsVORowImpl curRow= (ODCustomerAccountSetupRequestDetailsVORowImpl)ODCustomerAccountSetupRequestDetailsVO.getCurrentRow();
        if ( "Submitted".equalsIgnoreCase(curRow.getStatus())) return;
         if (curRow != null)
         {

            //Added for Release 1.02 - Adding Loyalty and Segmentation
            if(!isSgmntnChanged(curRow, pageContext.getParameter("SegmentationLOVCode")))
              populateSegmentation(pageContext, currentAm, curRow, partyID);
            if(!isLyltyChanged(curRow, pageContext.getParameter("LoyaltyLOVCode")))
              populateLoyalty(pageContext, currentAm, curRow, partyID);
            //End of code change for Release 1.02 - Adding Loyalty and Segmentation

            //Contract Compliance Rel10.3 changes start
            String contractTemplateId = pageContext.getParameter("StdContractTemplate");
            if( contractTemplateId != null)
              try{
                  curRow.setContractTemplateId(new Number(contractTemplateId.trim()));
              } catch (Exception eContrTem) {
                //throw new OAException("Unexpected Error has occurred when storing Contract. If it persists. Please communicate with System Administrator");
                String errorMsg = pageContext.getMessage("XXCRM", "XX_CRM_TMPL_REQUIRED", null);
                pageContext.putDialogMessage(new OAException(errorMsg, OAException.ERROR));
                return;
              }
            //Contract Compliance Rel10.3 changes end

            //populate Acct Tmpl Cntrs VO for this request_id
            //populateAcctTmplCntrsVO( pageContext, OdCdhAcctTemplateContractsVO, curRow.getRequestId().toString());

            boolean retStatus =   validateAccountRequestRecord(pageContext, webBean, curRow);
            if (retStatus == true)
            {
              //Anirban: Added for Release 1.2 - Creation of AP and Sales contact
              String salesContactDD = pageContext.getParameter("SalesContactDD");
              String apContactDD = pageContext.getParameter("APContactDD");
              String paymentMethod = (String)(curRow.getPaymentMethod());
              if(paymentMethod.equals("AB"))
              {
               String partyId = partyID.stringValue();
               pageContext.writeDiagnostics("CR687", "Calling create/update api's. Inside SubmitRequest event. PaymentMethod is AB", OAFwkConstants.STATEMENT);
               createUpdateSalescontact(pageContext, currentAm, curRow, salesContactDD, partyId);
               createUpdateAPcontact(pageContext, currentAm, curRow, apContactDD, partyId);
              }
              else
              {
               String partyId = partyID.stringValue();
               pageContext.writeDiagnostics("CR687", "Calling create/update api's. Inside SubmitRequest event. PaymentMethod is NOT AB!", OAFwkConstants.STATEMENT);
               createUpdateSalescontact(pageContext, currentAm, curRow, salesContactDD, partyId);
               String l_varNull = null;
               curRow.setAttribute13(l_varNull);
              }

              salesContactDD = curRow.getApContact();
              apContactDD = curRow.getAttribute13();

              //Anirban: Added for Release 1.2 - Creation of AP and Sales contact

              curRow.setStatus("Submitted");
              curRow.setStatusTransitionDate(currentAm.getOADBTransaction().getCurrentDBDate());
              currentAm.getTransaction().commit();

              //Anirban: Added for Release 1.2 - Creation of AP and Sales contact

              pageContext.writeDiagnostics("CR687", "Calling initializeAPandSalesContact api. Inside SubmitRequest event. Querying up the LOV VO's as well!", OAFwkConstants.STATEMENT);

              initializeAPandSalesContact(pageContext, webBean, apContactDD, salesContactDD, paymentMethod);

              //Populate AP Contact DD details
              OAViewObject ODApContactLovVO = (OAViewObject)currentAm.findViewObject("ODApContactLovVO");
              if ( ODApContactLovVO != null )
                  ODApContactLovVO.remove();

              ODApContactLovVO = (OAViewObject)currentAm.createViewObject("ODApContactLovVO",
                   "od.oracle.apps.xxcrm.customer.account.poplist.server.ODApContactLovVO");

              ODApContactLovVO.setWhereClauseParam(0, partyID);
              ODApContactLovVO.executeQuery();

              //Populate Sales Contact DD details
              OAViewObject ODSalesContactLovVO = (OAViewObject)currentAm.findViewObject("ODSalesContactLovVO");
              if ( ODSalesContactLovVO != null )
                  ODSalesContactLovVO.remove();

              ODSalesContactLovVO = (OAViewObject)currentAm.createViewObject("ODSalesContactLovVO",
               "od.oracle.apps.xxcrm.customer.account.poplist.server.ODApContactLovVO");

              ODSalesContactLovVO.setWhereClauseParam(0, partyID);
              ODSalesContactLovVO.executeQuery();

              //Anirban: Added for Release 1.2 - Creation of AP and Sales contact


              //Invoke BPEL process to send this file to AOPS
              makeTheFormReadOnly(pageContext, webBean);
              Row[] rows = customerAccountSetupRequestVO.getFilteredRows("SelectFlag", "Y");
              ODCustomerAccountSetupRequestVORowImpl row = (ODCustomerAccountSetupRequestVORowImpl)rows[0];
              row.setStatus("Submitted");
              makeTheFormReadOnly(pageContext, webBean);
              disablesubButton(pageContext, webBean);


              //--   Mohan code changes start here.....
              //Mohan 03/27/2009
              //Defect# 13687 Sales Enhancements - Account Creation ProcessDefect#

              HashMap params = new HashMap();
              pageContext.forwardImmediatelyToCurrentPage(
                             params, //pageParams
                             false, // Retain AM
                             OAWebBeanConstants.ADD_BREAD_CRUMB_SAVE);
              //Mohan  Code changes end here.  Defect# 13687
            }
         }
    }
    else
    if ("AddCustomDocument".equals(pageEvent))
    {
        pageContext.writeDiagnostics(METHOD_NAME, "AddCustomDocument", OAFwkConstants.PROCEDURE);
        OAViewObject vo  = (OAViewObject)currentAm.findViewObject("ODCustAcctSetupDocumentVO");
        ODCustomerAccountSetupRequestDetailsVORowImpl masterRow = (ODCustomerAccountSetupRequestDetailsVORowImpl)ODCustomerAccountSetupRequestDetailsVO.first();

        if ( "Submitted".equalsIgnoreCase(masterRow.getStatus())) return;

        pageContext.writeDiagnostics(METHOD_NAME, "No of Rows = "+vo.getRowCountInRange(), OAFwkConstants.PROCEDURE);

        if (vo.getRowCountInRange() < 1)
        {
          ODCustAcctSetupDocumentVORowImpl newRow = (ODCustAcctSetupDocumentVORowImpl)ODCustAcctSetupDocumentVO.createRow();
          newRow.setAccountRequestId(masterRow.getRequestId());
          Number curSeq = currentAm.getOADBTransaction().getSequenceValue("XX_CDH_ACCT_SETUP_DOCUMENTS_S");
          newRow.setDocumentId(curSeq);
          newRow.setDocumentType("INFO COPY");
          newRow.setDeleteFlag("N");
          ODCustAcctSetupDocumentVO.insertRow(newRow);
        }
        else
        {
          String errMsg = pageContext.getMessage("XXCRM", "XX_SFA_085_ONE_DOC_ONLY",null);
          pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));

          //pageContext.putDialogMessage(new OAException("Only one Document can be added to a request", OAException.ERROR));
        }
    }
    else
    if ("DeleteDocument".equals(pageEvent))
    {
         Row[] rows = ODCustAcctSetupDocumentVO.getFilteredRows("SelectFlag", "Y");
         ODCustAcctSetupDocumentVORowImpl row = null;
         for (int i = 0; i < rows.length; i++)
         {
           row = (ODCustAcctSetupDocumentVORowImpl)rows[i];
           //row.remove();
           row.setDeleteFlag("Y");
         }
         currentAm.getTransaction().commit();
         ODCustAcctSetupDocumentVO.executeQuery();

    }
    else
      if ("CHANGE_CONT_TEMP".equalsIgnoreCase(pageContext.getParameter(EVENT_PARAM) )   )
      {
          pageContext.writeDiagnostics(METHOD_NAME, "CHANGE_CONT_TEMP", OAFwkConstants.PROCEDURE);
          String contTempId = pageContext.getParameter("StdContractTemplate");

          ODCustomerAccountSetupRequestDetailsVORowImpl curRow= (ODCustomerAccountSetupRequestDetailsVORowImpl)ODCustomerAccountSetupRequestDetailsVO.getCurrentRow();
          pageContext.writeDiagnostics(METHOD_NAME, "curRow.getStatus(): " + curRow.getStatus(), OAFwkConstants.PROCEDURE);

		  if ( "Submitted".equalsIgnoreCase(curRow.getStatus()))
          {
            makeTheFormReadOnly(pageContext, webBean);
            return;
          }
          pageContext.writeDiagnostics(METHOD_NAME, "contTempId: " + contTempId, OAFwkConstants.PROCEDURE);

          if ((contTempId == null) || (contTempId).equals("")  )
          {

            curRow.setOffContractPercentage(null );
            curRow.setWholesalePercentage(null);
            curRow.setGpFloorPercentage(null);
            curRow.setXref(null);

            curRow.setParentId(null );
            curRow.setFreightCharge(null);

            curRow.setOffContractCode(null);
            curRow.setOffWholesaleCode(null);


            OAViewObject ODPricePlanLovVO = (OAViewObject)currentAm.findViewObject("ODPricePlanLovVO");

            ODPricePlanLovVO.setWhereClause(null);
            ODPricePlanLovVO.setWhereClause("contract_template_id = :1");
            ODPricePlanLovVO.setWhereClauseParam(0,"0");
            ODPricePlanLovVO.executeQuery();

            //Deleting Not Custom Contracts if any
            ODCustAcctSetupContractsVO.setMaxFetchSize(-1);
            ODCustAcctSetupContractsVO.setWhereClause(null);
            ODCustAcctSetupContractsVO.setWhereClause("DELETE_FLAG = 'N' AND CUSTOM = 'N' AND ACCOUNT_REQUEST_ID = :1");
            ODCustAcctSetupContractsVO.setWhereClauseParam(0,curRow.getRequestId());
            ODCustAcctSetupContractsVO.executeQuery();

            pageContext.writeDiagnostics(METHOD_NAME, "req id = "+curRow.getRequestId()+" no of rows to be deleted"+ODCustAcctSetupContractsVO.getRowCount(), OAFwkConstants.PROCEDURE);

            ODCustAcctSetupContractsVORowImpl vrow=(ODCustAcctSetupContractsVORowImpl)ODCustAcctSetupContractsVO.first();

            while (vrow != null)
            {
              pageContext.writeDiagnostics(METHOD_NAME, "contract number= "+vrow.getContractNumber(), OAFwkConstants.PROCEDURE);
              vrow.setDeleteFlag("Y");
              vrow.remove();
              vrow = (ODCustAcctSetupContractsVORowImpl)ODCustAcctSetupContractsVO.next();

            };

            //remove old rows in this VO for this request_id
            clearTemplateContractsVORows( pageContext, currentAm, curRow.getRequestId(), OdCdhAcctTemplateContractsVO);


            return;
        }

        pageContext.writeDiagnostics(METHOD_NAME, "contTempId not null: " + contTempId, OAFwkConstants.PROCEDURE);

        ODContractTemplatesVO = (OAViewObject)currentAm.findViewObject("ODContractTemplatesVO");
        if ( ODContractTemplatesVO == null )
             ODContractTemplatesVO = (OAViewObject)currentAm.createViewObject("ODContractTemplatesVO",
                    "od.oracle.apps.xxcrm.customer.account.server.ODContractTemplatesVO");

        ODContractTemplatesVO.setWhereClause(null);
        ODContractTemplatesVO.setWhereClause("CONTRACT_TEMPLATE_ID = :1");
        ODContractTemplatesVO.setWhereClauseParam(0,contTempId);
        ODContractTemplatesVO.setMaxFetchSize(-1);
        ODContractTemplatesVO.executeQuery();

        pageContext.writeDiagnostics(METHOD_NAME, "ODContractTemplatesVO populated", OAFwkConstants.PROCEDURE);


        ODContractTemplatesVORowImpl row=(ODContractTemplatesVORowImpl)ODContractTemplatesVO.first();

        //Contract Compliance Rel 10.3 changes
        //render contract fields as per contract template properties
        renderContractTemplateFields( pageContext, webBean, row);

        pageContext.writeDiagnostics(METHOD_NAME, "ODContractTemplatesVORow values : Off Contract Percent = "+row.getOffContractPercent(), OAFwkConstants.PROCEDURE);
        pageContext.writeDiagnostics(METHOD_NAME, "FreightCharge "+row.getFreightCharge()+" OffWholesalePercent "+row.getOffWholesalePercent()+" GpFloorPercent "+row.getGpFloorPercent()+" CustProdXref "+row.getCustProdXref(), OAFwkConstants.PROCEDURE);
        pageContext.writeDiagnostics(METHOD_NAME, "Parent ID = "+row.getParentId()+" OffContractCode "+row.getOffContractCode()+" OffWholesaleCode "+row.getOffWholesaleCode(), OAFwkConstants.PROCEDURE);
        curRow.setOffContractPercentage(row.getOffContractPercent() );
        curRow.setWholesalePercentage(row.getOffWholesalePercent());
        curRow.setGpFloorPercentage(row.getGpFloorPercent());
        curRow.setXref(row.getCustProdXref());

        pageContext.writeDiagnostics(METHOD_NAME, "making XREF readonly", OAFwkConstants.PROCEDURE);
        if (row.getCustProdXref() != null )
        {
               OAViewObject ODContTempCUPVO = (OAViewObject)currentAm.findViewObject("ODContTempCUPVO");

               if (ODContTempCUPVO == null)
               {
                      ODContTempCUPVO = (OAViewObject)currentAm.createViewObject("ODContTempCUPVO",
                          "od.oracle.apps.xxcrm.customer.account.server.ODContTempCUPVO");
               };
                   ODContTempCUPVO.setMaxFetchSize(0) ;
                   ODContTempCUPVO.executeQuery();
                   ODContTempCUPVORowImpl pvoRow = (ODContTempCUPVORowImpl)ODContTempCUPVO.createRow();
                   ODContTempCUPVO.insertRow(pvoRow);

                  pvoRow.setReadOnly(Boolean.TRUE );
                  pvoRow.setRendered(Boolean.FALSE );
        };


        curRow.setParentId( row.getParentId() );
        curRow.setFreightCharge(row.getFreightCharge());
        pageContext.writeDiagnostics(METHOD_NAME, "--2--" + contTempId, OAFwkConstants.PROCEDURE);

        OAViewObject ODAccountSetupUpOffVO = (OAViewObject)currentAm.findViewObject("ODAccountSetupUpOffVO");
        if ( ODAccountSetupUpOffVO == null )
             ODAccountSetupUpOffVO = (OAViewObject)currentAm.createViewObject("ODAccountSetupUpOffVO",
                    "od.oracle.apps.xxcrm.customer.account.poplist.server.ODAccountSetupUpOffVO");
         ODAccountSetupUpOffVO.setWhereClause(null);
         ODAccountSetupUpOffVO.setWhereClause("LOOKUP_CODE = :1");
         ODAccountSetupUpOffVO.setWhereClauseParam(0, row.getOffContractCode() );
         ODAccountSetupUpOffVO.executeQuery();
         ODAccountSetupUpOffVORowImpl ODAccountSetupUpOffVORow =   (ODAccountSetupUpOffVORowImpl)ODAccountSetupUpOffVO.first();
        if (ODAccountSetupUpOffVORow != null)
        {
            curRow.setOffContractCode(ODAccountSetupUpOffVORow.getMeaning());
        }
        pageContext.writeDiagnostics(METHOD_NAME, "--1--" + contTempId, OAFwkConstants.PROCEDURE);

         ODAccountSetupUpOffVO.setWhereClause(null);
         ODAccountSetupUpOffVO.setWhereClause("LOOKUP_CODE = :1");
         ODAccountSetupUpOffVO.setWhereClauseParam(0, row.getOffWholesaleCode());
         ODAccountSetupUpOffVO.executeQuery();
         ODAccountSetupUpOffVORow =   (ODAccountSetupUpOffVORowImpl)ODAccountSetupUpOffVO.first();
        if (ODAccountSetupUpOffVORow != null)
        {
            curRow.setOffWholesaleCode(ODAccountSetupUpOffVORow.getMeaning());
        }
        pageContext.writeDiagnostics(METHOD_NAME, "--0--" + contTempId, OAFwkConstants.PROCEDURE);

        //Populating Price Plan Poplist

        OAViewObject ODPricePlanLovVO = (OAViewObject)currentAm.findViewObject("ODPricePlanLovVO");

        ODPricePlanLovVO.setWhereClause(null);
        ODPricePlanLovVO.setWhereClause("contract_template_id = :1");
        ODPricePlanLovVO.setWhereClauseParam(0,contTempId);
        ODPricePlanLovVO.executeQuery();

        pageContext.writeDiagnostics(METHOD_NAME, "Before calling clearTemplateContractsVORows--" + contTempId, OAFwkConstants.PROCEDURE);

        //remove old rows in this VO for this request_id
        clearTemplateContractsVORows( pageContext, currentAm, curRow.getRequestId(), OdCdhAcctTemplateContractsVO);

        pageContext.writeDiagnostics(METHOD_NAME, "Before calling copyTmplCntrsToAcctCntrs--" + contTempId, OAFwkConstants.PROCEDURE);
        //Copy ODContractsAssignedVO into OdCdhAcctTemplateContractsVO
        copyTmplCntrsToAcctCntrs(pageContext, currentAm, curRow, contTempId, OdCdhAcctTemplateContractsVO);

        //populate Acct Tmpl Cntrs VO for this request_id
        //populateAcctTmplCntrsVO( pageContext, OdCdhAcctTemplateContractsVO, curRow.getRequestId().toString());

        //Contract Compliance - R10.3
        OAViewObject ODCdhContractProgCodesVO = (OAViewObject)currentAm.findViewObject("ODCdhContractProgCodesVO");
        ODCdhContractProgCodesVO.setWhereClause(null);
        ODCdhContractProgCodesVO.setWhereClause("CONTRACT_TEMPLATE_ID = :1");
        ODCdhContractProgCodesVO.setWhereClauseParam(0,contTempId );
        ODCdhContractProgCodesVO.setMaxFetchSize(-1);
        ODCdhContractProgCodesVO.executeQuery();
        pageContext.writeDiagnostics(METHOD_NAME, "Query: " +  ODCdhContractProgCodesVO.getQuery(), OAFwkConstants.PROCEDURE);
        pageContext.writeDiagnostics(METHOD_NAME, "contTempId: " + contTempId + ", " + ODCdhContractProgCodesVO.getRowCount(), OAFwkConstants.PROCEDURE);
        //Contract Compliance - R10.3

        pageContext.writeDiagnostics(METHOD_NAME, "after populating ODCustAcctSetupContractsVO with ODContractsAssignedVO", OAFwkConstants.PROCEDURE);

        //currentAm.getTransaction().commit();
      }
      else

      //Anirban: Added for Release 1.2 - Creation of AP and Sales contact

      if ("APContactDD".equals(pageContext.getParameter(EVENT_PARAM)))
      {
       String apContactDD = pageContext.getParameter("APContactDD");

           pageContext.writeDiagnostics("CR687", "APContactDD Selection is : "+apContactDD, OAFwkConstants.STATEMENT);

       pprAPContact(pageContext,webBean,apContactDD);

          }
      else

          if ("SalesContactDD".equals(pageContext.getParameter(EVENT_PARAM)))
      {
       String salesContactDD = pageContext.getParameter("SalesContactDD");

           pageContext.writeDiagnostics("CR687", "SalesContactDD Selection is : "+salesContactDD, OAFwkConstants.STATEMENT);

       pprSalesContact(pageContext,webBean,salesContactDD);

          }

          else

          if ("PaymentMethodDD".equals(pageContext.getParameter(EVENT_PARAM)))
      {
       String PaymentMethodDD = pageContext.getParameter("PaymentMethod");
           OACellFormatBean apContactRN = (OACellFormatBean)webBean.findChildRecursive("APContactCell");
           OACellFormatBean contactSpacerCell = (OACellFormatBean)webBean.findChildRecursive("ContactSpacerCell");
           OATipBean tipBean            = (OATipBean)webBean.findChildRecursive("TipAPSalesContact");

           if(PaymentMethodDD.equals("CC"))
           {
            tipBean.setRendered(false);
        apContactRN.setRendered(false);
                //contactSpacerCell.setRendered(false);
           }
           else
           {
        tipBean.setRendered(true);
        apContactRN.setRendered(true);
                //contactSpacerCell.setRendered(true);
           }
           pageContext.writeDiagnostics("CR687", "PaymentMethodDD Selection is : "+PaymentMethodDD, OAFwkConstants.STATEMENT);
          }

      //Anirban: Added for Release 1.2 - Creation of AP and Sales contact

      pageContext.writeDiagnostics(METHOD_NAME, "AccountSetupCO processFormRequest Ends", OAFwkConstants.PROCEDURE);
  }

  private boolean isLoyaltySegmentationPopulated(ODCustomerAccountSetupRequestDetailsVORowImpl curRow) {
    if ( curRow.getAttribute14() == null ||
         (curRow.getAttribute14() != null && curRow.getAttribute14().trim().equals(""))
       )
    {
      return false;
    }
    else
      return true;
  }

  //Check Segmentation Changed
  private boolean isSgmntnChanged(ODCustomerAccountSetupRequestDetailsVORowImpl curRow,
                                  String strSgmntn
                                  ) {
    String strOldSgmntn = curRow.getAttribute14();

    boolean isSgmntnChanged = false;

    if (strOldSgmntn == null && strSgmntn == null)
    {
      isSgmntnChanged = false;
    }
    else if (strOldSgmntn == null && strSgmntn != null)
    {
      isSgmntnChanged = true;
    }
    else if (strOldSgmntn != null && strSgmntn == null)
    {
      isSgmntnChanged = true;
    }
    else if (strOldSgmntn != null && strSgmntn != null)
    {
      if( !strOldSgmntn.trim().equalsIgnoreCase(strSgmntn.trim()))
      {
        isSgmntnChanged = true;
      }
    }
    return isSgmntnChanged;
  }
  //Check Loyalty Changed
  private boolean isLyltyChanged(ODCustomerAccountSetupRequestDetailsVORowImpl curRow,
                                  String strLylty
                                  ) {
    String strOldLylty = curRow.getAttribute15();
    boolean isLyltyChanged = false;

    if (strOldLylty == null && strLylty == null)
    {
      isLyltyChanged = false;
    }
    else if (strOldLylty == null && strLylty != null)
    {
      isLyltyChanged = true;
    }
    else if (strOldLylty != null && strLylty == null)
    {
      isLyltyChanged = true;
    }
    else if (strOldLylty != null && strLylty != null)
    {
      if( !(strOldLylty.trim()).equalsIgnoreCase(strLylty.trim()))
      {
        isLyltyChanged = true;
      }
    }
    return isLyltyChanged;
  }

  private void populateSegmentation(OAPageContext pageContext,
                                    OAApplicationModule currentAm,
                                    ODCustomerAccountSetupRequestDetailsVORowImpl curRow,
                                    Number  partyID)
  {

            String strSegmentationCode;
            strSegmentationCode = (String)pageContext.getParameter("CustSegmentLovItem");
            //pageContext.putDialogMessage(new OAException("Segmentation: " + strSegmentationCode, OAException.CONFIRMATION));
            if (strSegmentationCode != null)
            {
              curRow.setAttribute14(strSegmentationCode);
            }
  }

  private void populateLoyalty(OAPageContext pageContext,
                               OAApplicationModule currentAm,
                               ODCustomerAccountSetupRequestDetailsVORowImpl curRow,
                               Number  partyID)
  {

            String strLoyaltyCode;
            strLoyaltyCode = (String)pageContext.getParameter("CustLoyalLovItem");
            //pageContext.putDialogMessage(new OAException("Loyalty: " + strLoyaltyCode, OAException.CONFIRMATION));
            if (strLoyaltyCode != null)
            {
              curRow.setAttribute15(strLoyaltyCode);
            }
  }

  private void createUpdateAPcontact(OAPageContext pageContext,
                               OAApplicationModule currentAm, ODCustomerAccountSetupRequestDetailsVORowImpl curRow, String apContactDD, String partyId)
  {

     String org_AP_contact_id = apContactDD;
         String x_return_status = null;

         OADBTransaction txn = (OADBTransaction)currentAm.getTransaction();;
     OracleCallableStatement cs = null;
     Connection conn = txn.getJdbcConnection();

     String strPrefix = (String)pageContext.getParameter("PersonPreNameAdjunct1");
         String strFirstName = (String)pageContext.getParameter("PersonFirstName1");
         String strMiddleName = (String)pageContext.getParameter("PersonMiddleName1");
         String strLastName = (String)pageContext.getParameter("PersonLastName1");
         String strEmailAddress = (String)pageContext.getParameter("EmailAddress1");
         String strPhoneCountry = (String)pageContext.getParameter("PerPhoneCountryCode1");
         String strPhoneArea = (String)pageContext.getParameter("PhoneAreaCode11");
         String strPhoneNumber = (String)pageContext.getParameter("PhoneNumber11");
         String strPhoneExtension = (String)pageContext.getParameter("PhoneExtension1");
         String strFaxCountry = (String)pageContext.getParameter("FaxCountryCode1");
         String strFaxArea = (String)pageContext.getParameter("FaxAreaCode1");
         String strFaxNumber = (String)pageContext.getParameter("FaxNumber1");
         String strPartySiteId = (String)((curRow.getBillToSiteId()).stringValue());


     try
     {
      if("".equals(apContactDD.trim()))
          {
       pageContext.writeDiagnostics("Anirban : inside CREATE part of createUpdateAPcontact api.", "Anirban : inside CREATE part of createUpdateAPcontact api.", OAFwkConstants.STATEMENT);

       //create api call
       cs = (OracleCallableStatement)conn.prepareCall("begin XX_SFA_CONTACT_CREATE_PKG.Create_Org_APContact(:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12,:13,:14,:15,:16,:17,:18); end;");

       cs.setString(1,strPrefix);
       cs.setString(2,strFirstName);
           cs.setString(3,strMiddleName);
           cs.setString(4,strLastName);
           cs.setString(5,strEmailAddress);
           cs.setString(6,strPhoneCountry);
           cs.setString(7,strPhoneArea);
           cs.setString(8,strPhoneNumber);
           cs.setString(9,strPhoneExtension);
           cs.setString(10,strFaxCountry);
           cs.setString(11,strFaxArea);
           cs.setString(12,strFaxNumber);
           cs.setNUMBER(13,(new NUMBER(partyId)));
           cs.setNUMBER(14,(new NUMBER(strPartySiteId)));

           cs.registerOutParameter(15,OracleTypes.NUMBER);
           cs.registerOutParameter(16,OracleTypes.VARCHAR);
           cs.registerOutParameter(17,OracleTypes.NUMBER);
           cs.registerOutParameter(18,OracleTypes.VARCHAR);

       cs.execute();

       org_AP_contact_id = ((cs.getNUMBER(15)).stringValue());
           x_return_status = cs.getString(16);

           pageContext.writeDiagnostics("Anirban : createUpdateAPcontact", "Value of newly created org contact id is :"+org_AP_contact_id, OAFwkConstants.STATEMENT);

       cs.close();

       if(!x_return_status.equals("S"))
           {
        OAExceptionUtils.checkErrors(txn);
           }
            curRow.setAttribute13(org_AP_contact_id);
          }
          else
          {
       pageContext.writeDiagnostics("Anirban : inside UPDATE part of createUpdateAPcontact api.", "Anirban : inside UPDATE part of createUpdateAPcontact api.", OAFwkConstants.STATEMENT);

       //update api call
       cs = (OracleCallableStatement)conn.prepareCall("begin XX_SFA_CONTACT_CREATE_PKG.Update_Org_APContact(:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12,:13,:14,:15,:16,:17,:18); end;");

       cs.setString(1,strPrefix);
       cs.setString(2,strFirstName);
           cs.setString(3,strMiddleName);
           cs.setString(4,strLastName);
           cs.setString(5,strEmailAddress);
           cs.setString(6,strPhoneCountry);
           cs.setString(7,strPhoneArea);
           cs.setString(8,strPhoneNumber);
           cs.setString(9,strPhoneExtension);
           cs.setString(10,strFaxCountry);
           cs.setString(11,strFaxArea);
           cs.setString(12,strFaxNumber);
           cs.setNUMBER(13,(new NUMBER(partyId)));
           cs.setNUMBER(14,(new NUMBER(strPartySiteId)));
       cs.setString(15,apContactDD);

           cs.registerOutParameter(16,OracleTypes.VARCHAR);
           cs.registerOutParameter(17,OracleTypes.NUMBER);
           cs.registerOutParameter(18,OracleTypes.VARCHAR);

       cs.execute();

       x_return_status = cs.getString(16);

           pageContext.writeDiagnostics("Anirban : createUpdateAPcontact", "Value of x_return_status for update api is :"+x_return_status, OAFwkConstants.STATEMENT);

       cs.close();

       if(!x_return_status.equals("S"))
           {
        OAExceptionUtils.checkErrors(txn);
           }
            curRow.setAttribute13(org_AP_contact_id);
          }
     } //try
     catch(SQLException sqle)
     {
      //sqle.printStackTrace();
     }
     finally
     {
      try
      {
       cs.close();
      }
      catch (Exception e) {}
     }
  }

  private void createUpdateSalescontact(OAPageContext pageContext,
                               OAApplicationModule currentAm, ODCustomerAccountSetupRequestDetailsVORowImpl curRow, String salesContactDD, String partyId)
  {

     String org_Sales_contact_id = salesContactDD;
         String x_return_status = null;

         OADBTransaction txn = (OADBTransaction)currentAm.getTransaction();;
     OracleCallableStatement cs = null;
     Connection conn = txn.getJdbcConnection();

     String strPrefix = (String)pageContext.getParameter("PersonPreNameAdjunct");
         String strFirstName = (String)pageContext.getParameter("PersonFirstName");
         String strMiddleName = (String)pageContext.getParameter("PersonMiddleName");
         String strLastName = (String)pageContext.getParameter("PersonLastName");
         String strEmailAddress = (String)pageContext.getParameter("EmailAddress");
         String strPhoneCountry = (String)pageContext.getParameter("PerPhoneCountryCode");
         String strPhoneArea = (String)pageContext.getParameter("PhoneAreaCode1");
         String strPhoneNumber = (String)pageContext.getParameter("PhoneNumber1");
         String strPhoneExtension = (String)pageContext.getParameter("PhoneExtension");
         String strFaxCountry = (String)pageContext.getParameter("FaxCountryCode");
         String strFaxArea = (String)pageContext.getParameter("FaxAreaCode");
         String strFaxNumber = (String)pageContext.getParameter("FaxNumber");
     String strPartySiteId = (String)((curRow.getBillToSiteId()).stringValue());

         try
     {
      if("".equals(salesContactDD.trim()))
          {
       //create api call
       cs = (OracleCallableStatement)conn.prepareCall("begin XX_SFA_CONTACT_CREATE_PKG.Create_Org_SalesContact(:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12,:13,:14,:15,:16,:17,:18); end;");

       cs.setString(1,strPrefix);
       cs.setString(2,strFirstName);
           cs.setString(3,strMiddleName);
           cs.setString(4,strLastName);
           cs.setString(5,strEmailAddress);
           cs.setString(6,strPhoneCountry);
           cs.setString(7,strPhoneArea);
           cs.setString(8,strPhoneNumber);
           cs.setString(9,strPhoneExtension);
           cs.setString(10,strFaxCountry);
           cs.setString(11,strFaxArea);
           cs.setString(12,strFaxNumber);
           cs.setNUMBER(13,(new NUMBER(partyId)));
           cs.setNUMBER(14,(new NUMBER(strPartySiteId)));

           cs.registerOutParameter(15,OracleTypes.NUMBER);
           cs.registerOutParameter(16,OracleTypes.VARCHAR);
           cs.registerOutParameter(17,OracleTypes.NUMBER);
           cs.registerOutParameter(18,OracleTypes.VARCHAR);

       cs.execute();

       org_Sales_contact_id = ((cs.getNUMBER(15)).stringValue());
           x_return_status = cs.getString(16);

           pageContext.writeDiagnostics("Anirban : createUpdateSalescontact", "Value of newly created org contact id is :"+org_Sales_contact_id, OAFwkConstants.STATEMENT);

       cs.close();

       if(!x_return_status.equals("S"))
           {
        OAExceptionUtils.checkErrors(txn);
           }

        curRow.setApContact(org_Sales_contact_id);

          }
          else
          {
       //update api call
       cs = (OracleCallableStatement)conn.prepareCall("begin XX_SFA_CONTACT_CREATE_PKG.Update_Org_SalesContact(:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12,:13,:14,:15,:16,:17,:18); end;");

       cs.setString(1,strPrefix);
       cs.setString(2,strFirstName);
           cs.setString(3,strMiddleName);
           cs.setString(4,strLastName);
           cs.setString(5,strEmailAddress);
           cs.setString(6,strPhoneCountry);
           cs.setString(7,strPhoneArea);
           cs.setString(8,strPhoneNumber);
           cs.setString(9,strPhoneExtension);
           cs.setString(10,strFaxCountry);
           cs.setString(11,strFaxArea);
           cs.setString(12,strFaxNumber);
           cs.setNUMBER(13,(new NUMBER(partyId)));
           cs.setNUMBER(14,(new NUMBER(strPartySiteId)));
       cs.setString(15,salesContactDD);

           cs.registerOutParameter(16,OracleTypes.VARCHAR);
           cs.registerOutParameter(17,OracleTypes.NUMBER);
           cs.registerOutParameter(18,OracleTypes.VARCHAR);

       cs.execute();

       x_return_status = cs.getString(16);

           pageContext.writeDiagnostics("Anirban : createUpdateSalescontact", "Value of x_return_status for update api is :"+x_return_status, OAFwkConstants.STATEMENT);

       cs.close();

       if(!x_return_status.equals("S"))
           {
        OAExceptionUtils.checkErrors(txn);
           }
            curRow.setApContact(org_Sales_contact_id);
          }
     } //try
     catch(SQLException sqle)
     {
      //sqle.printStackTrace();
     }
     finally
     {
      try
      {
       cs.close();
      }
      catch (Exception e) {}
     }
  }

  public void makeTheFormReadOnly(OAPageContext pageContext, OAWebBean webBean)
  {
                final String METHOD_NAME = "xxcrm.customer.account.webui.ODAccountSetupCO.makeTheFormReadOnly";

        pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
        OAApplicationModule currentAm = pageContext.getApplicationModule(webBean);

        String partyID = pageContext.getParameter("pid");
        if (partyID == null || partyID.length() == 0)
           partyID = pageContext.getParameter("ASNReqFrmCustId");
                pageContext.writeDiagnostics(METHOD_NAME, " SMJ partyID in makeTheFormReadOnly = "+partyID,OAFwkConstants.PROCEDURE);


       OAViewObject ODContTempCUPVO = (OAViewObject)currentAm.findViewObject("ODContTempCUPVO");

       if (ODContTempCUPVO == null)
       {
              ODContTempCUPVO = (OAViewObject)currentAm.createViewObject("ODContTempCUPVO",
                  "od.oracle.apps.xxcrm.customer.account.server.ODContTempCUPVO");
       };
           ODContTempCUPVO.setMaxFetchSize(0) ;
           ODContTempCUPVO.executeQuery();
           ODContTempCUPVORowImpl pvoRow = (ODContTempCUPVORowImpl)ODContTempCUPVO.createRow();
           ODContTempCUPVO.insertRow(pvoRow);

            pvoRow.setReadOnly(Boolean.TRUE );
            pvoRow.setRendered(Boolean.FALSE );


           OAViewObject ODOrgAccountSetupPVO = (OAViewObject)currentAm.findViewObject("ODOrgAccountSetupPVO");
           if ( ODOrgAccountSetupPVO == null )
           ODOrgAccountSetupPVO = (OAViewObject)currentAm.createViewObject("ODOrgAccountSetupPVO",
                  "od.oracle.apps.xxcrm.customer.account.server.ODOrgAccountSetupPVO");

           ODOrgAccountSetupPVO.setMaxFetchSize(0) ;
           ODOrgAccountSetupPVO.executeQuery();
           ODOrgAccountSetupPVORowImpl readOnlyRow = (ODOrgAccountSetupPVORowImpl)ODOrgAccountSetupPVO.createRow();
           ODOrgAccountSetupPVO.insertRow(readOnlyRow);

           readOnlyRow.setReadOnly(Boolean.TRUE );

           pageContext.writeDiagnostics("SMJ", "Entering the Read Only Method", OAFwkConstants.STATEMENT);

           OAViewObject apContactLov = (OAViewObject)currentAm.findViewObject("ODApContactLovVO");
                   if ( apContactLov != null )
                                   apContactLov.remove();
                   apContactLov = (OAViewObject)currentAm.createViewObject("ODApContactLovVO",
                                                          "od.oracle.apps.xxcrm.customer.account.poplist.server.ODApContactHistLovVO");

                   apContactLov.setWhereClause(null);
                   apContactLov.setWhereClauseParams(null);
                   apContactLov.setWhereClauseParam(0,partyID);
                   apContactLov.executeQuery();

           //Anirban: Added for Release 1.2 - Creation of AP and Sales contact

           pageContext.writeDiagnostics("CR687", "Inside makeTheFormReadOnly api.", OAFwkConstants.STATEMENT);

           OAViewObject ODSalesContactLovVO = (OAViewObject)currentAm.findViewObject("ODSalesContactLovVO");
               if ( ODSalesContactLovVO != null )
                            ODSalesContactLovVO.remove();

               ODSalesContactLovVO = (OAViewObject)currentAm.createViewObject("ODSalesContactLovVO",
                   "od.oracle.apps.xxcrm.customer.account.poplist.server.ODApContactHistLovVO");
           ODSalesContactLovVO.setWhereClause(null);
                   ODSalesContactLovVO.setWhereClauseParams(null);
               ODSalesContactLovVO.setWhereClauseParam(0, partyID);
               ODSalesContactLovVO.executeQuery();


           OAMessageLayoutBean mLSpacerAPfirst = (OAMessageLayoutBean)webBean.findChildRecursive("mLSpacerAPfirst");
                   OAMessageLayoutBean mLSpacerAPsecond = (OAMessageLayoutBean)webBean.findChildRecursive("mLSpacerAPsecond");
                   OAMessageLayoutBean messageLayoutTIP = (OAMessageLayoutBean)webBean.findChildRecursive("messageLayoutTIP");

                   OAMessageStyledTextBean ORAPContact = (OAMessageStyledTextBean)webBean.findChildRecursive("ORAPContact");
                   OAMessageStyledTextBean CreateContactAP = (OAMessageStyledTextBean)webBean.findChildRecursive("CreateContactAP");

           mLSpacerAPfirst.setRendered(false);
                   mLSpacerAPsecond.setRendered(false);
                   messageLayoutTIP.setRendered(false);
                   ORAPContact.setRendered(false);
                   CreateContactAP.setRendered(false);

                   OAMessageLayoutBean mLSpacerSalesfirst = (OAMessageLayoutBean)webBean.findChildRecursive("mLSpacerSalesfirst");
                   OAMessageLayoutBean mLSpacerSalessecond = (OAMessageLayoutBean)webBean.findChildRecursive("mLSpacerSalessecond");
                   OAMessageLayoutBean mLSpacerSalesthird = (OAMessageLayoutBean)webBean.findChildRecursive("mLSpacerSalesthird");

                   OAMessageStyledTextBean ORSalesContact = (OAMessageStyledTextBean)webBean.findChildRecursive("ORSalesContact");
                   OAMessageStyledTextBean CreateContactSales = (OAMessageStyledTextBean)webBean.findChildRecursive("CreateContactSales");

           mLSpacerSalesfirst.setRendered(false);
                   mLSpacerSalessecond.setRendered(false);
                   mLSpacerSalesthird.setRendered(false);
                   ORSalesContact.setRendered(false);
                   CreateContactSales.setRendered(false);

                   OAMessageChoiceBean ODAPContactLov = (OAMessageChoiceBean)webBean.findChildRecursive("APContactDD");
           ODAPContactLov.setPrompt("Selected AP Contact");

                   OAMessageChoiceBean ODSalesContactLov = (OAMessageChoiceBean)webBean.findChildRecursive("SalesContactDD");
           ODSalesContactLov.setPrompt("Selected Sales Contact");

                   //Anirban: Added for Release 1.2 - Creation of AP and Sales contact

                   pageContext.writeDiagnostics("SMJ", "After the Read Only Method", OAFwkConstants.STATEMENT);

       //Contract Compliance Changes 10.3 start
             OAViewObject ODCdhContractCompPVO = (OAViewObject)currentAm.findViewObject("ODCdhContractCompPVO");
             if ( ODCdhContractCompPVO == null )
               ODCdhContractCompPVO = (OAViewObject)currentAm.createViewObject("ODCdhContractCompPVO",
            "od.oracle.apps.xxcrm.customer.account.server.ODCdhContractCompPVO");

       ODCdhContractCompPVO.setMaxFetchSize(0) ;
       ODCdhContractCompPVO.executeQuery();
       ODCdhContractCompPVORowImpl contractCompPVORow = (ODCdhContractCompPVORowImpl)ODCdhContractCompPVO.createRow();
       ODCdhContractCompPVO.insertRow(contractCompPVORow);

       contractCompPVORow.setTemplateLockedFlag(Boolean.TRUE);
       contractCompPVORow.setAssncontrLockedFlag(Boolean.TRUE);
       contractCompPVORow.setPriceplanLockedFlag(Boolean.TRUE);
       //Contract Compliance Changes 10.3 end

              pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);

}


  public void disableButton(OAPageContext pageContext,OAWebBean webBean)
  {
                final String METHOD_NAME = "xxcrm.customer.account.webui.ODAccountSetupCO.disableButton";

                pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);

            //System.out.println("sudeept disable button");

        OAApplicationModule currentAm = pageContext.getApplicationModule(webBean);

           OAViewObject ODAccountSetupButtonsPVO = (OAViewObject)currentAm.findViewObject("ODAccountSetupButtonsPVO");
           if ( ODAccountSetupButtonsPVO == null )
           ODAccountSetupButtonsPVO = (OAViewObject)currentAm.createViewObject("ODAccountSetupButtonsPVO",
            "od.oracle.apps.xxcrm.customer.account.server.ODAccountSetupButtonsPVO");

     ODAccountSetupButtonsPVO.setMaxFetchSize(0) ;
     ODAccountSetupButtonsPVO.executeQuery();
     ODAccountSetupButtonsPVORowImpl buttonRenderedRow = (ODAccountSetupButtonsPVORowImpl)ODAccountSetupButtonsPVO.createRow();
     ODAccountSetupButtonsPVO.insertRow(buttonRenderedRow);

     buttonRenderedRow.setAddCustomContractRendered(Boolean.FALSE);
     buttonRenderedRow.setAddCustomDocumentRendered(Boolean.FALSE);
     buttonRenderedRow.setCopyRequestRowRendered(Boolean.FALSE);
     buttonRenderedRow.setDeleteContractRendered(Boolean.FALSE);
     buttonRenderedRow.setDeleteDocumentRendered(Boolean.FALSE);
     buttonRenderedRow.setDeleteRequestRendered(Boolean.FALSE);
     buttonRenderedRow.setSubmitRequestRendered(Boolean.FALSE);
     buttonRenderedRow.setValidateAndSaveRendered(Boolean.FALSE);

            //System.out.println("sudeept disable button2");
                pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
 }

public void disableAllButton(OAPageContext pageContext,OAWebBean webBean)
  {
                final String METHOD_NAME = "xxcrm.customer.account.webui.ODAccountSetupCO.disableAllButton";

                pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);


        OAApplicationModule currentAm = pageContext.getApplicationModule(webBean);

           OAViewObject ODAccountSetupButtonsPVO = (OAViewObject)currentAm.findViewObject("ODAccountSetupButtonsPVO");
           if ( ODAccountSetupButtonsPVO == null )
           ODAccountSetupButtonsPVO = (OAViewObject)currentAm.createViewObject("ODAccountSetupButtonsPVO",
            "od.oracle.apps.xxcrm.customer.account.server.ODAccountSetupButtonsPVO");

     ODAccountSetupButtonsPVO.setMaxFetchSize(0) ;
     ODAccountSetupButtonsPVO.executeQuery();
     ODAccountSetupButtonsPVORowImpl buttonRenderedRow = (ODAccountSetupButtonsPVORowImpl)ODAccountSetupButtonsPVO.createRow();
     ODAccountSetupButtonsPVO.insertRow(buttonRenderedRow);

     buttonRenderedRow.setAddCustomContractRendered(Boolean.FALSE);
     buttonRenderedRow.setAddCustomDocumentRendered(Boolean.FALSE);
     buttonRenderedRow.setCopyRequestRowRendered(Boolean.FALSE);
     buttonRenderedRow.setDeleteContractRendered(Boolean.FALSE);
     buttonRenderedRow.setDeleteDocumentRendered(Boolean.FALSE);
     buttonRenderedRow.setDeleteRequestRendered(Boolean.FALSE);
     buttonRenderedRow.setSubmitRequestRendered(Boolean.FALSE);
     buttonRenderedRow.setValidateAndSaveRendered(Boolean.FALSE);
     buttonRenderedRow.setAddNewRequestRowRendered(Boolean.FALSE);


                pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
 }

public void disablesubButton(OAPageContext pageContext,OAWebBean webBean)
   {
                 final String METHOD_NAME = "xxcrm.customer.account.webui.ODAccountSetupCO.disablesubButton";

                 pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);


         OAApplicationModule currentAm = pageContext.getApplicationModule(webBean);

            OAViewObject ODAccountSetupButtonsPVO = (OAViewObject)currentAm.findViewObject("ODAccountSetupButtonsPVO");
            if ( ODAccountSetupButtonsPVO == null )
            ODAccountSetupButtonsPVO = (OAViewObject)currentAm.createViewObject("ODAccountSetupButtonsPVO",
             "od.oracle.apps.xxcrm.customer.account.server.ODAccountSetupButtonsPVO");

      ODAccountSetupButtonsPVO.setMaxFetchSize(0) ;
      ODAccountSetupButtonsPVO.executeQuery();
      ODAccountSetupButtonsPVORowImpl buttonRenderedRow = (ODAccountSetupButtonsPVORowImpl)ODAccountSetupButtonsPVO.createRow();
      ODAccountSetupButtonsPVO.insertRow(buttonRenderedRow);

      buttonRenderedRow.setAddCustomContractRendered(Boolean.FALSE);
      buttonRenderedRow.setAddCustomDocumentRendered(Boolean.FALSE);
      buttonRenderedRow.setDeleteContractRendered(Boolean.FALSE);
      buttonRenderedRow.setDeleteDocumentRendered(Boolean.FALSE);
      buttonRenderedRow.setDeleteRequestRendered(Boolean.FALSE);
      buttonRenderedRow.setSubmitRequestRendered(Boolean.FALSE);
      buttonRenderedRow.setValidateAndSaveRendered(Boolean.FALSE);
      buttonRenderedRow.setAddNewRequestRowRendered(Boolean.TRUE);
      buttonRenderedRow.setCopyRequestRowRendered(Boolean.TRUE);

         pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
 }

 public void disableDelButton(OAPageContext pageContext,OAWebBean webBean)
    {
                  final String METHOD_NAME = "xxcrm.customer.account.webui.ODAccountSetupCO.disableDelButton";

                  pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);


          OAApplicationModule currentAm = pageContext.getApplicationModule(webBean);

             OAViewObject ODAccountSetupButtonsPVO = (OAViewObject)currentAm.findViewObject("ODAccountSetupButtonsPVO");
             if ( ODAccountSetupButtonsPVO == null )
             ODAccountSetupButtonsPVO = (OAViewObject)currentAm.createViewObject("ODAccountSetupButtonsPVO",
              "od.oracle.apps.xxcrm.customer.account.server.ODAccountSetupButtonsPVO");

       ODAccountSetupButtonsPVO.setMaxFetchSize(0) ;
       ODAccountSetupButtonsPVO.executeQuery();
       ODAccountSetupButtonsPVORowImpl buttonRenderedRow = (ODAccountSetupButtonsPVORowImpl)ODAccountSetupButtonsPVO.createRow();
       ODAccountSetupButtonsPVO.insertRow(buttonRenderedRow);

       buttonRenderedRow.setAddCustomContractRendered(Boolean.FALSE);
       buttonRenderedRow.setAddCustomDocumentRendered(Boolean.FALSE);
       buttonRenderedRow.setDeleteContractRendered(Boolean.FALSE);
       buttonRenderedRow.setDeleteDocumentRendered(Boolean.FALSE);
       buttonRenderedRow.setDeleteRequestRendered(Boolean.FALSE);
       buttonRenderedRow.setSubmitRequestRendered(Boolean.FALSE);
       buttonRenderedRow.setValidateAndSaveRendered(Boolean.FALSE);
       buttonRenderedRow.setAddNewRequestRowRendered(Boolean.TRUE);
       buttonRenderedRow.setCopyRequestRowRendered(Boolean.TRUE);

          pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
 }
  private void copyTmplCntrsToAcctCntrs(OAPageContext pageContext, OAApplicationModule currentAm, ODCustomerAccountSetupRequestDetailsVORowImpl curRow, String contTempId, OAViewObject OdCdhAcctTemplateContractsVO)
  {
        pageContext.writeDiagnostics(METHOD_NAME, "copyTmplCntrsToAcctCntrs Start--contTempId: " + contTempId , OAFwkConstants.PROCEDURE);
        //remove old rows in this VO for this request_id
        //clearTemplateContractsVORows( pageContext, currentAm, curRow.getRequestId(), OdCdhAcctTemplateContractsVO);

        //OAViewObject OdCdhAcctTemplateContractsVO = (OAViewObject)currentAm.findViewObject("OdCdhAcctTemplateContractsVO");
        if ( OdCdhAcctTemplateContractsVO == null )
          OdCdhAcctTemplateContractsVO = (OAViewObject)currentAm.createViewObject("OdCdhAcctTemplateContractsVO",
            "od.oracle.apps.xxcrm.customer.account.server.OdCdhAcctTemplateContractsVO");

        try{
          Statement stmt = currentAm.getOADBTransaction().getJdbcConnection().createStatement();
          ResultSet rs = stmt.executeQuery("SELECT ODCdhContractsAssignedEO.CONTRACT_TEMPLATE_ID, ODCdhContractsAssignedEO.CONTRACT_NUMBER, ODCdhContractsAssignedEO.CONTRACT_DESCRIPTION, ODCdhContractsAssignedEO.PRIORITY FROM XX_CDH_CONTRACTS_ASSIGNED ODCdhContractsAssignedEO WHERE nvl(CONTRACT_TEMPLATE_ID, -1) = nvl(" + contTempId + ",-1)" );
          int rsIter = 0;
          OdCdhAcctTemplateContractsVORowImpl newRow1 = null;

          String ctrPriority = "";

          while(rs.next()) {
            pageContext.writeDiagnostics(METHOD_NAME, "rsIter: " + rsIter + "Contract Number: " + rs.getString("CONTRACT_NUMBER"), OAFwkConstants.PROCEDURE);

            newRow1 = (OdCdhAcctTemplateContractsVORowImpl)OdCdhAcctTemplateContractsVO.createRow();

            Number curSeq1 = currentAm.getOADBTransaction().getSequenceValue("XX_CDH_ACCT_TMPL_CONTRACTS_S");
            newRow1.setSetupContractTemplateId(curSeq1);

            newRow1.setContractTemplateId(new Number(contTempId.trim()));
            newRow1.setAccountRequestId(curRow.getRequestId());

            newRow1.setContractNumber(rs.getString("CONTRACT_NUMBER"));
            newRow1.setContractDescription(rs.getString("CONTRACT_DESCRIPTION"));
            ctrPriority = rs.getString("PRIORITY");

            newRow1.setPriority(ctrPriority);
            newRow1.setCustom("N");
            newRow1.setDeleteFlag("N");

            OdCdhAcctTemplateContractsVO.insertRow(newRow1);

            rsIter++;
        }
        rs.close();

        currentAm.getTransaction().commit();
        pageContext.writeDiagnostics(METHOD_NAME, "OdCdhAcctTemplateContractsVO fetchedRowCount = " + OdCdhAcctTemplateContractsVO.getFetchedRowCount(), OAFwkConstants.PROCEDURE);
        }catch (Exception e) {
           pageContext.writeDiagnostics(METHOD_NAME, "Exception in copyTmplCntrsToAcctCntrs: " + e.toString(), OAFwkConstants.PROCEDURE);
        }
        pageContext.writeDiagnostics(METHOD_NAME, "copyTmplCntrsToAcctCntrs End--" , OAFwkConstants.PROCEDURE);
  }
  private void copyCntrsFromAcctReq(OAPageContext pageContext, OAApplicationModule currentAm, Number oldRquestID, Number newRquestID, String contTempId, OAViewObject OdCdhAcctTemplateContractsVO)
  {
        pageContext.writeDiagnostics(METHOD_NAME, "copyCntrsFromAcctReq Start--old Request_ID: " + oldRquestID.toString() + "newRquestID: " + newRquestID, OAFwkConstants.PROCEDURE);
        //remove old rows in this VO for this request_id
        //clearTemplateContractsVORows( pageContext, currentAm, curRow.getRequestId(), OdCdhAcctTemplateContractsVO);

        //OAViewObject OdCdhAcctTemplateContractsVO = (OAViewObject)currentAm.findViewObject("OdCdhAcctTemplateContractsVO");
        if ( OdCdhAcctTemplateContractsVO == null )
          OdCdhAcctTemplateContractsVO = (OAViewObject)currentAm.createViewObject("OdCdhAcctTemplateContractsVO",
            "od.oracle.apps.xxcrm.customer.account.server.OdCdhAcctTemplateContractsVO");

        //Added for blank row issue by devi
        OdCdhAcctTemplateContractsVO.setWhereClause(null);
        OdCdhAcctTemplateContractsVO.setWhereClauseParams(null);
        OdCdhAcctTemplateContractsVO.setMaxFetchSize(-1);
        OdCdhAcctTemplateContractsVO.setWhereClauseParam(0,oldRquestID.toString() );
        //End of change

        //clear the VO
        Row r1 = OdCdhAcctTemplateContractsVO.first();
        if (r1 != null)
        {
          r1.remove();
        }

        while ( (r1 = OdCdhAcctTemplateContractsVO.next()) != null)
        {
          r1.remove();
        }

        try{
          pageContext.writeDiagnostics(METHOD_NAME, "select contract_number, contract_description, priority from   XX_CDH_ACCT_TEMPLATE_CONTRACTS where  nvl(account_request_id,-1)= nvl(" + oldRquestID.toString() + ",-1" , OAFwkConstants.PROCEDURE);

          Statement stmt = currentAm.getOADBTransaction().getJdbcConnection().createStatement();
          ResultSet rs = stmt.executeQuery("select contract_number, contract_description, priority from   XX_CDH_ACCT_TEMPLATE_CONTRACTS where  nvl(account_request_id,-1)= nvl(" + oldRquestID.toString() + ",-1" );
          int rsIter = 0;
          OdCdhAcctTemplateContractsVORowImpl newRow1 = null;

          String ctrPriority = "";

          while(rs.next()) {
            pageContext.writeDiagnostics(METHOD_NAME, "rsIter: " + rsIter + "Contract Number: " + rs.getString("CONTRACT_NUMBER"), OAFwkConstants.PROCEDURE);

            newRow1 = (OdCdhAcctTemplateContractsVORowImpl)OdCdhAcctTemplateContractsVO.createRow();

            Number curSeq1 = currentAm.getOADBTransaction().getSequenceValue("XX_CDH_ACCT_TMPL_CONTRACTS_S");
            newRow1.setSetupContractTemplateId(curSeq1);

            newRow1.setContractTemplateId(new Number(contTempId.trim()));
            newRow1.setAccountRequestId(newRquestID);

            newRow1.setContractNumber(rs.getString("CONTRACT_NUMBER"));
            newRow1.setContractDescription(rs.getString("CONTRACT_DESCRIPTION"));
            ctrPriority = rs.getString("PRIORITY");

            newRow1.setPriority(ctrPriority);
            newRow1.setCustom("N");
            newRow1.setDeleteFlag("N");

            OdCdhAcctTemplateContractsVO.insertRow(newRow1);

            rsIter++;
        }
        rs.close();

        currentAm.getTransaction().commit();
        pageContext.writeDiagnostics(METHOD_NAME, "copyCntrsFromAcctReq OdCdhAcctTemplateContractsVO fetchedRowCount = " + OdCdhAcctTemplateContractsVO.getFetchedRowCount(), OAFwkConstants.PROCEDURE);
        }catch (Exception e) {
           pageContext.writeDiagnostics(METHOD_NAME, "Exception in copyCntrsFromAcctReq: " + e.toString(), OAFwkConstants.PROCEDURE);
        }
        pageContext.writeDiagnostics(METHOD_NAME, "copyCntrsFromAcctReq End--" , OAFwkConstants.PROCEDURE);
  }

  private void populateAcctTmplCntrsVO(OAPageContext pageContext, OAViewObject OdCdhAcctTemplateContractsVO, String acctReqId)
  {
        pageContext.writeDiagnostics(METHOD_NAME, "populateAcctTmplCntrsVO Start--" , OAFwkConstants.PROCEDURE);
        pageContext.writeDiagnostics(METHOD_NAME, "acctReqId: " + acctReqId , OAFwkConstants.PROCEDURE);
        pageContext.writeDiagnostics(METHOD_NAME, "OdCdhAcctTemplateContractsVO.isExecuted(): " + OdCdhAcctTemplateContractsVO.isExecuted() , OAFwkConstants.PROCEDURE);

        if ( (acctReqId == null) || (acctReqId != null && "".equals(acctReqId)))
        {
          return;
        }
        /* *** To handle PPRs when the users navigate to the tab region to avoid page refresh and stale data *** */
        if ("update".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM)) &&
            OdCdhAcctTemplateContractsVO.isExecuted()
           )
          return;

        //verify OdCdhAcctTemplateContractsVO
        OdCdhAcctTemplateContractsVO.setWhereClause(null);
        OdCdhAcctTemplateContractsVO.setWhereClauseParams(null);
        OdCdhAcctTemplateContractsVO.setMaxFetchSize(-1);
        //Commented for blank row issue by Devi
        //OdCdhAcctTemplateContractsVO.setWhereClause("ACCOUNT_REQUEST_ID = nvl(:1,-1)");
        OdCdhAcctTemplateContractsVO.setWhereClauseParam(0,acctReqId );
        OdCdhAcctTemplateContractsVO.setPreparedForExecution(true);

        String rowSetName = "NewRowSet";

        RowSet secondaryRowSet = OdCdhAcctTemplateContractsVO.findRowSet(rowSetName);
        if (secondaryRowSet == null)
        {
          secondaryRowSet = OdCdhAcctTemplateContractsVO.createRowSet(rowSetName);
        }

        if ( acctReqId != null)
          secondaryRowSet.setWhereClauseParam(0,acctReqId );
        else
          secondaryRowSet.setWhereClauseParam(0,"-1" );

        // This will populate secondary RowSet
        secondaryRowSet.executeQuery();

        int fetchedRowCount1 = secondaryRowSet.getRowCount();

        pageContext.writeDiagnostics(METHOD_NAME, "In populateAcctTmplCntrsVO fetchedRowCount = " + fetchedRowCount1, OAFwkConstants.PROCEDURE);
        pageContext.writeDiagnostics(METHOD_NAME, "populateAcctTmplCntrsVO End--" , OAFwkConstants.PROCEDURE);

  }
  private void clearTemplateContractsVORows(OAPageContext pageContext, OAApplicationModule currentAm, Number accountRequestId, OAViewObject OdCdhAcctTemplateContractsVO) {
    pageContext.writeDiagnostics(METHOD_NAME, "In clearTemplateContractsVORows start, accountRequestId: " + accountRequestId, OAFwkConstants.PROCEDURE);

    if ( (accountRequestId == null) || (accountRequestId != null && "".equals(accountRequestId)))
    {
      return;
    }
    //Added for blank row issue by devi
    OdCdhAcctTemplateContractsVO.setWhereClause(null);
    OdCdhAcctTemplateContractsVO.setWhereClauseParams(null);
    OdCdhAcctTemplateContractsVO.setMaxFetchSize(-1);
    OdCdhAcctTemplateContractsVO.setWhereClauseParam(0,accountRequestId );
    //End of change

    pageContext.writeDiagnostics(METHOD_NAME, "In clearTemplateContractsVORows- no. of rows before clearing = "+ OdCdhAcctTemplateContractsVO.getRowCount() , OAFwkConstants.PROCEDURE);
    OdCdhAcctTemplateContractsVO.setPreparedForExecution(true);

    Row r1 = OdCdhAcctTemplateContractsVO.first();
    if (r1 != null)
    {
      r1.remove();
    }

    while ( (r1 = OdCdhAcctTemplateContractsVO.next()) != null)
    {
      r1.remove();
    }
    currentAm.getTransaction().commit();

    OdCdhAcctTemplateContractsVO.clearCache();

    //Added for blank row issue by devi
    //Added for blank row issue by devi
    OdCdhAcctTemplateContractsVO.setWhereClause(null);
    OdCdhAcctTemplateContractsVO.setWhereClauseParams(null);
    OdCdhAcctTemplateContractsVO.setMaxFetchSize(-1);
    OdCdhAcctTemplateContractsVO.setWhereClauseParam(0,accountRequestId );
    //End of change

    OdCdhAcctTemplateContractsVO.setPreparedForExecution(true);

    pageContext.writeDiagnostics(METHOD_NAME, "In clearTemplateContractsVORows- after clearing OdCdhAcctTemplateContractsVO no. of rows = "+ OdCdhAcctTemplateContractsVO.getRowCount() , OAFwkConstants.PROCEDURE);

    pageContext.writeDiagnostics(METHOD_NAME, "clearTemplateContractsVORows End--" , OAFwkConstants.PROCEDURE);

  }

  private void renderContractTemplateFields(OAPageContext pageContext, OAWebBean webBean, ODContractTemplatesVORowImpl row)
  {
        pageContext.writeDiagnostics(METHOD_NAME, "renderContractTemplateFields Start--" , OAFwkConstants.PROCEDURE);

           OAApplicationModule currentAm = pageContext.getApplicationModule(webBean);

     //Contract Compliance Project 10.3 changes start
     OAViewObject ODContractTemplatesVO = (OAViewObject)currentAm.findViewObject("ODContractTemplatesVO");
     if ( ODContractTemplatesVO == null )
        ODContractTemplatesVO = (OAViewObject)currentAm.createViewObject("ODContractTemplatesVO",
            "od.oracle.apps.xxcrm.customer.account.server.ODContractTemplatesVO");

           OAViewObject ODCdhContractCompPVO = (OAViewObject)currentAm.findViewObject("ODCdhContractCompPVO");
           if ( ODCdhContractCompPVO == null )
           ODCdhContractCompPVO = (OAViewObject)currentAm.createViewObject("ODCdhContractCompPVO",
            "od.oracle.apps.xxcrm.customer.account.server.ODCdhContractCompPVO");

     ODCdhContractCompPVO.setMaxFetchSize(-1) ;
     ODCdhContractCompPVO.executeQuery();
     ODCdhContractCompPVORowImpl readOnlyRow = (ODCdhContractCompPVORowImpl)ODCdhContractCompPVO.createRow();
     ODCdhContractCompPVO.insertRow(readOnlyRow);


     String strTemplateLockedFlag = "";
     if (row != null) {
       strTemplateLockedFlag = row.getTemplateLockedFlag();
       pageContext.writeDiagnostics(METHOD_NAME, "In renderContractTemplateFields, strTemplateLockedFlag: " + strTemplateLockedFlag, OAFwkConstants.PROCEDURE);
     }
     if (strTemplateLockedFlag != null && strTemplateLockedFlag.trim().equalsIgnoreCase("Y"))
       readOnlyRow.setTemplateLockedFlag(Boolean.TRUE);
     else
       readOnlyRow.setTemplateLockedFlag(Boolean.FALSE);

       pageContext.writeDiagnostics(METHOD_NAME, "In renderContractTemplateFields, readOnlyRow.getTemplateLockedFlag(): " + readOnlyRow.getTemplateLockedFlag(), OAFwkConstants.PROCEDURE);

     String strPriceplanLockedFlag = "";
     if (row != null)
       strPriceplanLockedFlag = row.getPriceplanLockedFlag();
     if (strPriceplanLockedFlag != null && strPriceplanLockedFlag.trim().equalsIgnoreCase("Y")) {
       readOnlyRow.setPriceplanLockedFlag(Boolean.FALSE);
       setPriceplanLocked(Boolean.FALSE);
     } else {
       readOnlyRow.setPriceplanLockedFlag(Boolean.TRUE);
       setPriceplanLocked(Boolean.TRUE);
     }

           OAViewObject ODAccountSetupButtonsPVO = (OAViewObject)currentAm.findViewObject("ODAccountSetupButtonsPVO");
           if ( ODAccountSetupButtonsPVO == null )
           ODAccountSetupButtonsPVO = (OAViewObject)currentAm.createViewObject("ODAccountSetupButtonsPVO",
            "od.oracle.apps.xxcrm.customer.account.server.ODAccountSetupButtonsPVO");

     ODAccountSetupButtonsPVO.setMaxFetchSize(-1) ;
     ODAccountSetupButtonsPVO.executeQuery();
     ODAccountSetupButtonsPVORowImpl asbreadOnlyRow = (ODAccountSetupButtonsPVORowImpl)ODAccountSetupButtonsPVO.createRow();
     ODAccountSetupButtonsPVO.insertRow(asbreadOnlyRow);

     String strAssncontrLockedFlag = "";
     if (row != null)
       strAssncontrLockedFlag = row.getAssncontrLockedFlag();
     if (strAssncontrLockedFlag != null && strAssncontrLockedFlag.trim().equalsIgnoreCase("Y"))
     {
       asbreadOnlyRow.setAddCustomContractRendered(Boolean.FALSE);
       asbreadOnlyRow.setDeleteContractRendered(Boolean.FALSE);
       setAssncontrLocked(Boolean.TRUE);
       readOnlyRow.setAssncontrLockedFlag(Boolean.TRUE);
     }
     else
     {
       asbreadOnlyRow.setAddCustomContractRendered(Boolean.TRUE);
       asbreadOnlyRow.setDeleteContractRendered(Boolean.TRUE);
       setAssncontrLocked(Boolean.FALSE);
       readOnlyRow.setAssncontrLockedFlag(Boolean.FALSE);
     }

     String strPriceplanMandatoryFlag = "";
     if (row != null)
       strPriceplanMandatoryFlag = row.getPriceplanMandatoryFlag();
     if (strPriceplanMandatoryFlag != null && strPriceplanMandatoryFlag.trim().equalsIgnoreCase("Y")) {
       readOnlyRow.setPriceplanMandatoryFlag(Boolean.FALSE);
       setPriceplanMandatory(Boolean.FALSE);
     }
     else {
       readOnlyRow.setPriceplanMandatoryFlag(Boolean.TRUE);
       setPriceplanMandatory(Boolean.TRUE);
     }
     //Contract Compliance Project 10.3 changes end
     pageContext.writeDiagnostics(METHOD_NAME, "renderContractTemplateFields End--" , OAFwkConstants.PROCEDURE);

  }

  private void setPriceplanMandatory( boolean bMandatory)
  {
    this.PRICE_PLAN_MANDATORY = bMandatory;
  }

  private boolean getPriceplanMandatory()
  {
    return this.PRICE_PLAN_MANDATORY;
  }

  private void setPriceplanLocked( boolean bPPLocked)
  {
    this.PRICE_PLAN_LOCKED = bPPLocked;
  }

  private boolean getPriceplanLocked()
  {
    return this.PRICE_PLAN_LOCKED;
  }

  private void setAssncontrLocked( boolean bACLocked)
  {
    this.ASSN_CONTRACTS_LOCKED = bACLocked;
  }

  private boolean getAssncontrLocked()
  {
    return this.ASSN_CONTRACTS_LOCKED;
  }

  public void makeTheFormEditable(OAPageContext pageContext, OAWebBean webBean)
  {
                final String METHOD_NAME = "xxcrm.customer.account.webui.ODAccountSetupCO.makeTheFormEditable";

                pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);

           OAApplicationModule currentAm = pageContext.getApplicationModule(webBean);

           OAViewObject ODContTempCUPVO = (OAViewObject)currentAm.findViewObject("ODContTempCUPVO");

       if (ODContTempCUPVO == null)
       {
              ODContTempCUPVO = (OAViewObject)currentAm.createViewObject("ODContTempCUPVO",
                  "od.oracle.apps.xxcrm.customer.account.server.ODContTempCUPVO");
       };
       ODContTempCUPVO.setMaxFetchSize(0) ;
       ODContTempCUPVO.executeQuery();
       ODContTempCUPVORowImpl pvoRow = (ODContTempCUPVORowImpl)ODContTempCUPVO.createRow();
       ODContTempCUPVO.insertRow(pvoRow);

      pvoRow.setReadOnly(Boolean.FALSE );
      pvoRow.setRendered(Boolean.TRUE );

           OAViewObject ODOrgAccountSetupPVO = (OAViewObject)currentAm.findViewObject("ODOrgAccountSetupPVO");
           if ( ODOrgAccountSetupPVO == null )
           ODOrgAccountSetupPVO = (OAViewObject)currentAm.createViewObject("ODOrgAccountSetupPVO",
            "od.oracle.apps.xxcrm.customer.account.server.ODOrgAccountSetupPVO");

     ODOrgAccountSetupPVO.setMaxFetchSize(0) ;
     ODOrgAccountSetupPVO.executeQuery();
     ODOrgAccountSetupPVORowImpl readOnlyRow = (ODOrgAccountSetupPVORowImpl)ODOrgAccountSetupPVO.createRow();
     ODOrgAccountSetupPVO.insertRow(readOnlyRow);

     readOnlyRow.setReadOnly(Boolean.FALSE );

      pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);

  }

    public void enableButton(OAPageContext pageContext,OAWebBean webBean)
    {
      final String METHOD_NAME = "xxcrm.customer.account.webui.ODAccountSetupCO.enableButton";

      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
        OAApplicationModule currentAm = pageContext.getApplicationModule(webBean);

           OAViewObject ODAccountSetupButtonsPVO = (OAViewObject)currentAm.findViewObject("ODAccountSetupButtonsPVO");
           if ( ODAccountSetupButtonsPVO == null )
           ODAccountSetupButtonsPVO = (OAViewObject)currentAm.createViewObject("ODAccountSetupButtonsPVO",
            "od.oracle.apps.xxcrm.customer.account.server.ODAccountSetupButtonsPVO");

     ODAccountSetupButtonsPVO.setMaxFetchSize(0) ;
     ODAccountSetupButtonsPVO.executeQuery();
     ODAccountSetupButtonsPVORowImpl buttonRenderedRow = (ODAccountSetupButtonsPVORowImpl)ODAccountSetupButtonsPVO.createRow();
     ODAccountSetupButtonsPVO.insertRow(buttonRenderedRow);

     buttonRenderedRow.setAddCustomContractRendered(Boolean.TRUE);
     buttonRenderedRow.setAddCustomDocumentRendered(Boolean.TRUE);
     buttonRenderedRow.setCopyRequestRowRendered(Boolean.TRUE);
     buttonRenderedRow.setDeleteContractRendered(Boolean.TRUE);
     buttonRenderedRow.setDeleteDocumentRendered(Boolean.TRUE);
     buttonRenderedRow.setDeleteRequestRendered(Boolean.TRUE);
     buttonRenderedRow.setSubmitRequestRendered(Boolean.TRUE);
     buttonRenderedRow.setValidateAndSaveRendered(Boolean.TRUE);

      pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
   }

    boolean validateAccountRequestRecord(OAPageContext pageContext,OAWebBean webBean, ODCustomerAccountSetupRequestDetailsVORowImpl curRow)
    {

        final String METHOD_NAME = "xxcrm.customer.account.webui.ODAccountSetupCO.validateAccountRequestRecord";

        pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);

        boolean retStatus = true;

        /* Validation for BSD salesrep passing */
        OAApplicationModule cAm = pageContext.getApplicationModule(webBean);
        String IdParty = curRow.getPartyId().toString();
                pageContext.writeDiagnostics(METHOD_NAME, "Satya IdParty = "+IdParty , OAFwkConstants.PROCEDURE);

                 OAViewObject ODCustAcctSalesRepValVO = (OAViewObject)cAm.findViewObject("ODCustAcctSalesRepValVO");
                                if (ODCustAcctSalesRepValVO == null)
                                  {pageContext.writeDiagnostics(METHOD_NAME, "satya in ODCustAcctSalesRepValVO", OAFwkConstants.PROCEDURE);
                                        ODCustAcctSalesRepValVO = (OAViewObject)cAm.createViewObject("ODCustAcctSalesRepValVO",
                                                "od.oracle.apps.xxcrm.customer.account.server.ODCustAcctSalesRepValVO");}
                                        ODCustAcctSalesRepValVO.setWhereClauseParams(null);
                                        ODCustAcctSalesRepValVO.setWhereClauseParam(0,IdParty);
                                        ODCustAcctSalesRepValVO.executeQuery();
                                        ODCustAcctSalesRepValVORowImpl cRow = (ODCustAcctSalesRepValVORowImpl) ODCustAcctSalesRepValVO.first();
                                        pageContext.writeDiagnostics(METHOD_NAME, "satya in ODCustAcctSalesRepValVO2", OAFwkConstants.PROCEDURE);

                                        //if ("0".equals(cRow.getCount1().toString())) - VJ Changed - QC 8783
                                        if ((cRow.getCount1()).intValue() == 0)
                                        {
                                         pageContext.writeDiagnostics(METHOD_NAME, "satya in ODCustAcctSalesRepValVO messsage ", OAFwkConstants.PROCEDURE);
                                         String errMsg = pageContext.getMessage("XXCRM", "XX_SFA_092_BSD_REP",null);
                                         pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
                                         retStatus = false;
                                        }


        String faxFlag1 = curRow.getAfax();
                String faxFlag2 = curRow.getFaxOrder();
                pageContext.writeDiagnostics(METHOD_NAME, "SATYA faxFlag1:"+faxFlag1, OAFwkConstants.PROCEDURE);
                if (faxFlag1 != null  &&  "Y".equals(faxFlag1) && faxFlag2 != null  &&  "Y".equals(faxFlag2))
                {
                  String errMsg = pageContext.getMessage("XXCRM", "XX_SFA_089_FAX_SELECT",null);
                  pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
                  retStatus = false;
                }

        //Release 1.02 Customer Segmentation validation
        String strSegmentationCode = curRow.getAttribute14();
        if ( strSegmentationCode == null || (strSegmentationCode != null && strSegmentationCode.trim().equals("")))
        {
           //MessageToken[] messageTokens = { new MessageToken("LABEL_TOKEN", "Segmentation")};
           String errorMsg = pageContext.getMessage("XXCRM", "XX_CRM_SEGM_REQD_ERROR", null);
           pageContext.putDialogMessage(new OAException(errorMsg, OAException.ERROR));
           retStatus = false;
        }

                //Anirban: Added for Release 1.2 - Creation of AP and Sales contact

        String paymentMethod = curRow.getPaymentMethod();

                pageContext.writeDiagnostics("CR687", "Inside validateAccountRequestRecord api. Doing the necessary form validations for CR687 and throwing the appropriate errors when required.PaymentMethod is AB", OAFwkConstants.STATEMENT);

                if(paymentMethod.equals("AB"))
        {
         String fname_apcontact = pageContext.getParameter("PersonFirstName1");
         String lname_apcontact = pageContext.getParameter("PersonLastName1");
                 String email_apcontact = pageContext.getParameter("EmailAddress1");
                 String faxareacode_apcontact = pageContext.getParameter("FaxAreaCode1");
                 String faxnumber_apcontact = pageContext.getParameter("FaxNumber1");
                 String phoneareacode_apcontact = pageContext.getParameter("PhoneAreaCode11");
                 String phonenumber_apcontact = pageContext.getParameter("PhoneNumber11");
                 String apfaxNOTpresent = "";

                 pageContext.writeDiagnostics("CR687", "Inside validateAccountRequestRecord api. PaymentMethod is AB", OAFwkConstants.STATEMENT);

                 if ((phoneareacode_apcontact == null  ||  ("".equals(phoneareacode_apcontact))) && (phonenumber_apcontact == null  ||  ("".equals(phonenumber_apcontact))))
                 {
                  String errMsg = pageContext.getMessage("XXCRM", "AP_CONT_TEL_REQ",null);
                  pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
                  retStatus = false;
                 }
                 if ((fname_apcontact == null)  || ("".equals(fname_apcontact)))
                 {
                  String errMsg = pageContext.getMessage("XXCRM", "AP_CONT_FNAME_REQ",null);
                  pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
                  retStatus = false;
                 }
                 if ((lname_apcontact == null)  || ("".equals(lname_apcontact)))
                 {
                  String errMsg = pageContext.getMessage("XXCRM", "AP_CONT_LNAME_REQ",null);
                  pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
                  retStatus = false;
                 }
                 if ((faxareacode_apcontact == null  ||  ("".equals(faxareacode_apcontact))) && (faxnumber_apcontact == null  ||  ("".equals(faxnumber_apcontact))))
                 {
                  apfaxNOTpresent = "yes";
                 }
                 if (((email_apcontact == null)  || ("".equals(email_apcontact))) && "yes".equals(apfaxNOTpresent))
                 {
                  String errMsg = pageContext.getMessage("XXCRM", "AP_CONT_EMAIL_FAX_REQ",null);
                  pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
                  retStatus = false;
                 }
                }


                 String fname_salescontact = pageContext.getParameter("PersonFirstName");
         String lname_salescontact = pageContext.getParameter("PersonLastName");
                 String email_salescontact = pageContext.getParameter("EmailAddress");
                 String faxareacode_salescontact = pageContext.getParameter("FaxAreaCode");
                 String faxnumber_salescontact = pageContext.getParameter("FaxNumber");
                 String phoneareacode_salescontact = pageContext.getParameter("PhoneAreaCode1");
                 String phonenumber_salescontact = pageContext.getParameter("PhoneNumber1");
                 String salesfaxNOTpresent = "";

                 if ((phoneareacode_salescontact == null  ||  ("".equals(phoneareacode_salescontact))) && (phonenumber_salescontact == null  ||  ("".equals(phonenumber_salescontact))))
                 {
                  String errMsg = pageContext.getMessage("XXCRM", "SALES_CONT_TEL_REQ",null);
                  pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
                  retStatus = false;
                 }
                 if ((fname_salescontact == null)  || ("".equals(fname_salescontact)))
                 {
                  String errMsg = pageContext.getMessage("XXCRM", "SALES_CONT_FNAME_REQ",null);
                  pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
                  retStatus = false;
                 }
                 if ((lname_salescontact == null)  || ("".equals(lname_salescontact)))
                 {
                  String errMsg = pageContext.getMessage("XXCRM", "SALES_CONT_LNAME_REQ",null);
                  pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
                  retStatus = false;
                 }
                 /*if ((faxareacode_salescontact == null  ||  ("".equals(faxareacode_salescontact))) && (faxnumber_salescontact == null  ||  ("".equals(faxnumber_salescontact))))
                 {
                  salesfaxNOTpresent = "yes";
                 }
                 if (((email_salescontact == null)  || ("".equals(email_salescontact))) && "yes".equals(salesfaxNOTpresent))
                 {
                  String errMsg = pageContext.getMessage("XXCRM", "EMAIL_FAX_REQ",null);
                  pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
                  retStatus = false;
                 }*/

        //Anirban: Added for Release 1.2 - Creation of AP and Sales contact


        Number offContractPercent = curRow.getOffContractPercentage();

        if ( offContractPercent != null && (offContractPercent).intValue() > 100 )
        {
          MessageToken[] tokens = { new MessageToken("REQ_VAL", "Off Contract Percentage")};
          String errMsg = pageContext.getMessage("XXCRM", "XX_SFA_070_PERCENT",tokens);
          pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
          retStatus = false;
        }
        else if (offContractPercent == null)
                {
                  MessageToken[] tokens = { new MessageToken("REQ_VAL", "Off Contract Percentage")};
                  String errMsg = pageContext.getMessage("XXCRM", "XX_SFA_083_NOT_NULL",tokens);
                  pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
                  retStatus = false;
        }


        Number wholeSalePercent = curRow.getWholesalePercentage();

        if ( wholeSalePercent != null && (wholeSalePercent).intValue() > 100 )
        {
          MessageToken[] tokens = { new MessageToken("REQ_VAL", "Off Wholesale Percentage")};
          String errMsg = pageContext.getMessage("XXCRM", "XX_SFA_070_PERCENT",tokens);
          pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
          retStatus = false;
        }
        else if ( wholeSalePercent == null )
                {
                  MessageToken[] tokens = { new MessageToken("REQ_VAL", "Off Wholesale Percentage")};
                  String errMsg = pageContext.getMessage("XXCRM", "XX_SFA_083_NOT_NULL",tokens);
                  pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
                  retStatus = false;
        }

        String OffContract = curRow.getOffContractCode();
                if ( OffContract  == null )
                {
                  MessageToken[] tokens = { new MessageToken("REQ_VAL", "Off Contract")};
                  String errMsg = pageContext.getMessage("XXCRM", "XX_SFA_083_NOT_NULL",tokens);
                  pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
                  retStatus = false;
                }

                String wholeSale = curRow.getOffWholesaleCode();
                if ( wholeSale == null )
                {
                  MessageToken[] tokens = { new MessageToken("REQ_VAL", "Off Wholesale")};
                  String errMsg = pageContext.getMessage("XXCRM", "XX_SFA_083_NOT_NULL",tokens);
                  pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
                  retStatus = false;
        }

        Number gpFloor = curRow.getGpFloorPercentage();

        if ( gpFloor != null && (gpFloor).intValue() > 100 )
        {
          MessageToken[] tokens = { new MessageToken("REQ_VAL", "GP Floor Percentage")};
          String errMsg = pageContext.getMessage("XXCRM", "XX_SFA_070_PERCENT",tokens);
          pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
          retStatus = false;
        }
        else if ( gpFloor == null )
                {
                  MessageToken[] tokens = { new MessageToken("REQ_VAL", "GP Floor Percentage")};
                  String errMsg = pageContext.getMessage("XXCRM", "XX_SFA_083_NOT_NULL",tokens);
                  pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
                  retStatus = false;
                }

      String textPricePlan = curRow.getAttribute2();
      if (textPricePlan == null || "".equals(textPricePlan.trim()))
      {
        textPricePlan = "";
      }
      String pricePlanVal = "" ;
      pricePlanVal = curRow.getPricePlan();

      pageContext.writeDiagnostics(METHOD_NAME, "pricePlanVal:"+ pricePlanVal + ":", OAFwkConstants.PROCEDURE);
      pageContext.writeDiagnostics(METHOD_NAME, "textPricePlan:"+ textPricePlan + ":", OAFwkConstants.PROCEDURE);

      if( getPriceplanMandatory()) {
        if ( curRow.getPricePlan() == null || (curRow.getPricePlan() != null && "".equals(curRow.getPricePlan().trim()))) {
          if ("".equals(textPricePlan.trim())) {
            MessageToken[] tokens = { new MessageToken("REQ_VAL", "Price Plan")};
            String errMsg = pageContext.getMessage("XXCRM", "XX_SFA_083_NOT_NULL",tokens);
            pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
            retStatus = false;
                  }
        }
      }
        if ( curRow.getPricePlan() != null && !"".equals(curRow.getPricePlan().trim()) && !"".equals(textPricePlan)) {
                          pageContext.writeDiagnostics(METHOD_NAME, "debug5:", OAFwkConstants.PROCEDURE);
              MessageToken[] tokens = { new MessageToken("REQ_VAL", "Free Text Price Plan")};
              String errMsg = pageContext.getMessage("XXCRM", "XX_SFA_107_MUST_BE_NULL",tokens);
              pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
              retStatus = false;
         }
         if ((curRow.getPoValidated() == null) || (curRow.getPoValidated()).equals("")  )
                                {
                                  MessageToken[] tokens = { new MessageToken("REQ_VAL", "Purchase Order(PO)")};
                                  String errMsg = pageContext.getMessage("XXCRM", "XX_SFA_083_NOT_NULL",tokens);
                                   pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
                                  retStatus = false;
                        }


                 if ((curRow.getReleaseValidated() == null) || (curRow.getReleaseValidated()).equals("")  )
                                {
                                  MessageToken[] tokens = { new MessageToken("REQ_VAL", "Release")};
                                  String errMsg = pageContext.getMessage("XXCRM", "XX_SFA_083_NOT_NULL",tokens);
                                   pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
                                  retStatus = false;
                                }


                 if ((curRow.getDepartmentValidated() == null) || (curRow.getDepartmentValidated()).equals("")  )
                                {
                                  MessageToken[] tokens = { new MessageToken("REQ_VAL", "Cost Center")};
                                  String errMsg = pageContext.getMessage("XXCRM", "XX_SFA_083_NOT_NULL",tokens);
                                   pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
                                  retStatus = false;
                                }


                 if ((curRow.getDesktopValidated() == null) || (curRow.getDesktopValidated()).equals("")  )
                                {
                                  MessageToken[] tokens = { new MessageToken("REQ_VAL", "Desktop")};
                                  String errMsg = pageContext.getMessage("XXCRM", "XX_SFA_083_NOT_NULL",tokens);
                                   pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
                                  retStatus = false;
                                }


        /*if ((curRow.getApContact() == null) || (curRow.getApContact()).equals("")  )
        {
          MessageToken[] tokens = { new MessageToken("REQ_VAL", "AP Contact")};
          String errMsg = pageContext.getMessage("XXCRM", "XX_SFA_083_NOT_NULL",tokens);
          pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
          retStatus = false;
        }*/

        if (curRow.getBillToSiteId() == null   )
        {

          MessageToken[] tokens = { new MessageToken("REQ_VAL", "Bill To Site")};
          String errMsg = pageContext.getMessage("XXCRM", "XX_SFA_083_NOT_NULL",tokens);
          pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
          retStatus = false;
        }

/*  BillTo and ShipTo adddress validation */
if (curRow.getBillToSiteId() != null)
{  pageContext.writeDiagnostics(METHOD_NAME, "satya in con ", OAFwkConstants.PROCEDURE);
        OAApplicationModule currAm = pageContext.getApplicationModule(webBean);
        String partId = curRow.getPartyId().toString();
        pageContext.writeDiagnostics(METHOD_NAME, "Partypassed = "+partId , OAFwkConstants.PROCEDURE);
        String billPid = curRow.getBillToSiteId().toString();
        pageContext.writeDiagnostics(METHOD_NAME, "billPid = "+billPid , OAFwkConstants.PROCEDURE);

         OAViewObject ODHzPuiAddressTableVO = (OAViewObject)currAm.findViewObject("ODHzPuiAddressTableVO");
                        if (ODHzPuiAddressTableVO == null)
                        {pageContext.writeDiagnostics(METHOD_NAME, "satya in vo1", OAFwkConstants.PROCEDURE);
                                ODHzPuiAddressTableVO = (OAViewObject)currAm.createViewObject("ODHzPuiAddressTableVO",
                                        "od.oracle.apps.xxcrm.customer.account.server.ODHzPuiAddressTableVO");}

                                ODHzPuiAddressTableVO.setWhereClause(null);
                                ODHzPuiAddressTableVO.setWhereClause("party_site_id = :2");
                                ODHzPuiAddressTableVO.setWhereClauseParams(null);
                                ODHzPuiAddressTableVO.setWhereClauseParam(0,partId);
                                ODHzPuiAddressTableVO.setWhereClauseParam(1,billPid);
                                ODHzPuiAddressTableVO.executeQuery();
                                ODHzPuiAddressTableVORowImpl cuRow = (ODHzPuiAddressTableVORowImpl) ODHzPuiAddressTableVO.first();
                                pageContext.writeDiagnostics(METHOD_NAME, "satya in vo2", OAFwkConstants.PROCEDURE);

                                if (cuRow != null)
                                {
                                 if ("US".equals(cuRow.getCountryCode().toString()))
                                  {
                                         pageContext.writeDiagnostics(METHOD_NAME, "satya in US ccode ", OAFwkConstants.PROCEDURE);
                                         if ( cuRow.getCountry() == null || cuRow.getAddress1() == null || cuRow.getPostalCode() == null
                                           || cuRow.getState() == null || cuRow.getCity() == null )
                                        {
                                         pageContext.writeDiagnostics(METHOD_NAME, "satya in messsage ", OAFwkConstants.PROCEDURE);
                                         MessageToken[] tokens = { new MessageToken("ADDRESS","Bill to Site")};
                                         String errMsg = pageContext.getMessage("XXCRM", "XX_SFA_091_INCOMPLETE_ADDR",tokens);
                                         pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
                                         retStatus = false;
                                        }
                                  }
                                 else if ("CA".equals(cuRow.getCountryCode().toString()))
                                   {
                                   pageContext.writeDiagnostics(METHOD_NAME, "satya in CA ccode ", OAFwkConstants.PROCEDURE);
                                        if ( cuRow.getCountry() == null || cuRow.getAddress1() == null || cuRow.getPostalCode() == null || cuRow.getProvince() == null || cuRow.getCity() == null )
                                        {
                                         pageContext.writeDiagnostics(METHOD_NAME, "satya in messsage ", OAFwkConstants.PROCEDURE);
                                         MessageToken[] tokens = { new MessageToken("ADDRESS","Bill to Site")};
                                         String errMsg = pageContext.getMessage("XXCRM", "XX_SFA_091_INCOMPLETE_ADDR",tokens);
                                         pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
                                         retStatus = false;
                                        }
                                   }
                          }
}

if (curRow.getShipToSiteId() != null)
                        {  pageContext.writeDiagnostics(METHOD_NAME, "satya in con ", OAFwkConstants.PROCEDURE);
                                OAApplicationModule currAm = pageContext.getApplicationModule(webBean);
                                String partId = curRow.getPartyId().toString();
                                pageContext.writeDiagnostics(METHOD_NAME, "Partypassed = "+partId , OAFwkConstants.PROCEDURE);
                                String shipPid = curRow.getShipToSiteId().toString();
                                pageContext.writeDiagnostics(METHOD_NAME, "shipPid = "+shipPid , OAFwkConstants.PROCEDURE);

                                 OAViewObject ODHzPuiAddressTableVO = (OAViewObject)currAm.findViewObject("ODHzPuiAddressTableVO");
                                                if (ODHzPuiAddressTableVO == null)
                                                {pageContext.writeDiagnostics(METHOD_NAME, "satya in vo1", OAFwkConstants.PROCEDURE);
                                                        ODHzPuiAddressTableVO = (OAViewObject)currAm.createViewObject("ODHzPuiAddressTableVO",
                                                                "od.oracle.apps.xxcrm.customer.account.server.ODHzPuiAddressTableVO");}

                                                        ODHzPuiAddressTableVO.setWhereClause(null);
                                                        ODHzPuiAddressTableVO.setWhereClause("party_site_id = :2");
                                                        ODHzPuiAddressTableVO.setWhereClauseParams(null);
                                                        ODHzPuiAddressTableVO.setWhereClauseParam(0,partId);
                                                        ODHzPuiAddressTableVO.setWhereClauseParam(1,shipPid);
                                                        ODHzPuiAddressTableVO.executeQuery();
                                                        ODHzPuiAddressTableVORowImpl cuRow = (ODHzPuiAddressTableVORowImpl) ODHzPuiAddressTableVO.first();
                                                        pageContext.writeDiagnostics(METHOD_NAME, "satya in vo2", OAFwkConstants.PROCEDURE);

                                                        if (cuRow != null)
                                                        {
                                                         if ("US".equals(cuRow.getCountryCode().toString()))
                                                          {
                                                                 pageContext.writeDiagnostics(METHOD_NAME, "satya in US ccode ", OAFwkConstants.PROCEDURE);
                                                                 if ( cuRow.getCountry() == null || cuRow.getAddress1() == null || cuRow.getPostalCode() == null
                                                                   || cuRow.getState() == null || cuRow.getCity() == null )
                                                                {
                                                                 pageContext.writeDiagnostics(METHOD_NAME, "satya in messsage ", OAFwkConstants.PROCEDURE);
                                                                 MessageToken[] tokens = { new MessageToken("ADDRESS","Ship to Site")};
                                                                 String errMsg = pageContext.getMessage("XXCRM", "XX_SFA_091_INCOMPLETE_ADDR",tokens);
                                                                 pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
                                                                 retStatus = false;
                                                                }
                                                          }
                                                         else if ("CA".equals(cuRow.getCountryCode().toString()))
                                                           {
                                                           pageContext.writeDiagnostics(METHOD_NAME, "satya in CA ccode ", OAFwkConstants.PROCEDURE);
                                                                if ( cuRow.getCountry() == null || cuRow.getAddress1() == null || cuRow.getPostalCode() == null || cuRow.getProvince() == null || cuRow.getCity() == null )
                                                                {
                                                                 pageContext.writeDiagnostics(METHOD_NAME, "satya in messsage ", OAFwkConstants.PROCEDURE);
                                                                 MessageToken[] tokens = { new MessageToken("ADDRESS","Ship to Site")};
                                                                 String errMsg = pageContext.getMessage("XXCRM", "XX_SFA_091_INCOMPLETE_ADDR",tokens);
                                                                 pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
                                                                 retStatus = false;
                                                                }
                                                           }
                                                  }
                        }


        if ((curRow.getAttribute5() == null) || (curRow.getAttribute5()).equals("")  )
        {
          MessageToken[] tokens = { new MessageToken("REQ_VAL", "Contract Template")};
          String errMsg = pageContext.getMessage("XXCRM", "XX_SFA_083_NOT_NULL",tokens);
          pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));

//          pageContext.putDialogMessage(new OAException("AP Contact cannot be NULL", OAException.ERROR));

          retStatus = false;
        }


//        if (curRow.getBillToSiteId() == curRow.getShipToSiteId())
//        curRow.setShipToSiteId(null);

        OAApplicationModule currentAm = pageContext.getApplicationModule(webBean);

             OAViewObject ODCustAcctSetupContractsValidationVO = (OAViewObject)currentAm.findViewObject("ODCustAcctSetupContractsValidationVO");
                   if (ODCustAcctSetupContractsValidationVO == null)
                   {
                          ODCustAcctSetupContractsValidationVO = (OAViewObject)currentAm.createViewObject("ODCustAcctSetupContractsValidationVO",
                        "od.oracle.apps.xxcrm.customer.account.server.ODCustAcctSetupContractsValidationVO");
                   };
               ODCustAcctSetupContractsValidationVO.setWhereClause(null);
               ODCustAcctSetupContractsValidationVO.setWhereClause("ACCOUNT_REQUEST_ID = :1 AND DELETE_FLAG = 'N' and CUSTOM = 'N'");
               ODCustAcctSetupContractsValidationVO.setWhereClauseParam(0,curRow.getRequestId() );
               ODCustAcctSetupContractsValidationVO.executeQuery();
               ODCustAcctSetupContractsValidationVORowImpl vrow=(ODCustAcctSetupContractsValidationVORowImpl)ODCustAcctSetupContractsValidationVO.first();


                Set set = new HashSet();

             OAViewObject OdCdhAcctTemplateContractsVO = (OAViewObject)currentAm.findViewObject("OdCdhAcctTemplateContractsVO");
             OdCdhAcctTemplateContractsVORowImpl row=(OdCdhAcctTemplateContractsVORowImpl)OdCdhAcctTemplateContractsVO.first();

            while (row != null)
            {
              if (row.getContractNumber() == null || (row.getContractNumber() != null && "".equals(row.getContractNumber())) )
              {

                  MessageToken[] tokens = { new MessageToken("REQ_VAL","Contract Number" )};
                  String errMsg = pageContext.getMessage("XXCRM", "XX_SFA_083_NOT_NULL",tokens);
                  pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
                  retStatus = false;
              }
              if(!set.add(row.getPriority()))
              {
                  MessageToken[] tokens = { new MessageToken("REQ_VAL", row.getPriority())};
                  String errMsg = pageContext.getMessage("XXCRM", "XX_SFA_069_PRIORITY_DUP",tokens);
                  pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
                  retStatus = false;
              }
              row = (OdCdhAcctTemplateContractsVORowImpl)OdCdhAcctTemplateContractsVO.next();

            }

        OAViewObject ODCustAcctSetupDocumentVO = (OAViewObject)currentAm.findViewObject("ODCustAcctSetupDocumentVO");
        if (ODCustAcctSetupDocumentVO != null)
        {
           ODCustAcctSetupDocumentVORowImpl curDocumentRow;
           curDocumentRow = (ODCustAcctSetupDocumentVORowImpl)ODCustAcctSetupDocumentVO.first();
           String documentName;
           String frequency;
           while (curDocumentRow != null)
           {
             documentName = curDocumentRow.getDocumentName();
             frequency = curDocumentRow.getFrequency();
             if ("INVOICE".equals(documentName))
             {
               if (("WEEK".equals(frequency) || "DAY".equals(frequency))  == false)
               {
                  String errMsg = pageContext.getMessage("XXCRM", "XX_ASN_ACCT_SETUP_STD_INV",null);
                  pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
                  retStatus = false;
               }
             }
             if ("CONSOLIDATED_INVOICE".equals(documentName))
             {
               if (("MONTH".equals(frequency) || "SEMI_MONTH".equals(frequency))  == false)
               {
                  String errMsg = pageContext.getMessage("XXCRM", "XX_ASN_ACCT_SETUP_SUM_BILL",null);
                  pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));
                  retStatus = false;
               }
             }

              curDocumentRow = (ODCustAcctSetupDocumentVORowImpl)ODCustAcctSetupDocumentVO.next();
           }
        }
                pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);

        return retStatus;
      }

    void setDefaultValues(OAApplicationModule currentAm,
    ODCustomerAccountSetupRequestDetailsVORowImpl newRow )
    {
                final String METHOD_NAME = "xxcrm.customer.account.webui.ODAccountSetupCO.setDefaultValues";

       newRow.setAfax("Y");
       newRow.setFaxOrder("N");
       newRow.setSubstitutions("Y");
       newRow.setBackOrders("Y");
       newRow.setDeliveryDocumentType("INV");
       newRow.setPrintInvoice("Y");
       newRow.setFreightCharge("Y");
       newRow.setRenamePackingList("Y");
       newRow.setDisplayBackOrder("Y");
       newRow.setDisplayPurchaseOrder("Y");
       newRow.setDisplayPrices("N");
       newRow.setAccountCreationSystem("AOPS");

    }


  void setSkipProcessFormData(OAPageContext pageContext,OAWebBean webBean)
  {
            final String METHOD_NAME = "xxcrm.customer.account.webui.ODAccountSetupCO.setSkipProcessFormData";

                  pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);

            OATableBean tb = (OATableBean)webBean.findIndexedChildRecursive("AccReqTb");
            tb.setUnvalidated(true);
      tb = (OATableBean)webBean.findIndexedChildRecursive("ContractsTable");
      tb.setUnvalidated(true);
      tb = (OATableBean)webBean.findIndexedChildRecursive("DocumentTable");
      tb.setUnvalidated(true);

                  pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
  }

  void initializeAPandSalesContact(OAPageContext pageContext,OAWebBean webBean, String apContactDD, String salesContactDD, String paymentMethod)
  {
    OAApplicationModule currentAm = (OAApplicationModule) pageContext.getApplicationModule(webBean);

        OACellFormatBean apContactRN = (OACellFormatBean)webBean.findChildRecursive("APContactCell");
        OATipBean tipBean            = (OATipBean)webBean.findChildRecursive("TipAPSalesContact");

        if(paymentMethod.equals("CC"))
        {
         tipBean.setRendered(false);
     apContactRN.setRendered(false);
        }

        if(paymentMethod.equals("AB"))
        {
         tipBean.setRendered(true);
     apContactRN.setRendered(true);
        }

        OAMessageLayoutBean mLSpacerAPfirst = (OAMessageLayoutBean)webBean.findChildRecursive("mLSpacerAPfirst");
        OAMessageLayoutBean mLSpacerAPsecond = (OAMessageLayoutBean)webBean.findChildRecursive("mLSpacerAPsecond");
        OAMessageLayoutBean messageLayoutTIP = (OAMessageLayoutBean)webBean.findChildRecursive("messageLayoutTIP");

        OAMessageStyledTextBean ORAPContact = (OAMessageStyledTextBean)webBean.findChildRecursive("ORAPContact");
        OAMessageStyledTextBean CreateContactAP = (OAMessageStyledTextBean)webBean.findChildRecursive("CreateContactAP");

    mLSpacerAPfirst.setRendered(true);
        mLSpacerAPsecond.setRendered(true);
        messageLayoutTIP.setRendered(true);
        ORAPContact.setRendered(true);
        CreateContactAP.setRendered(true);

        OAMessageLayoutBean mLSpacerSalesfirst = (OAMessageLayoutBean)webBean.findChildRecursive("mLSpacerSalesfirst");
        OAMessageLayoutBean mLSpacerSalessecond = (OAMessageLayoutBean)webBean.findChildRecursive("mLSpacerSalessecond");
        OAMessageLayoutBean mLSpacerSalesthird = (OAMessageLayoutBean)webBean.findChildRecursive("mLSpacerSalesthird");

        OAMessageStyledTextBean ORSalesContact = (OAMessageStyledTextBean)webBean.findChildRecursive("ORSalesContact");
        OAMessageStyledTextBean CreateContactSales = (OAMessageStyledTextBean)webBean.findChildRecursive("CreateContactSales");

    mLSpacerSalesfirst.setRendered(true);
        mLSpacerSalessecond.setRendered(true);
        mLSpacerSalesthird.setRendered(true);
        ORSalesContact.setRendered(true);
        CreateContactSales.setRendered(true);

        OAMessageChoiceBean ODAPContactLov = (OAMessageChoiceBean)webBean.findChildRecursive("APContactDD");
    ODAPContactLov.setPrompt("Select Existing Contact");
    OAMessageChoiceBean ODSalesContactLov = (OAMessageChoiceBean)webBean.findChildRecursive("SalesContactDD");
    ODSalesContactLov.setPrompt("Select Existing Contact");



    currentAm.invokeMethod("initPopLists_APContactTitle");
    currentAm.invokeMethod("initPopLists_SalesContactTitle");

        OAViewObject hzPuiPhoneCountryCodeVO = (OAViewObject)currentAm.findViewObject("HzPuiPhoneCountryCodeVO");
        OAViewObject hzPuiPhoneCountryCodeVO1 = (OAViewObject)currentAm.findViewObject("HzPuiPhoneCountryCodeVO1");
        hzPuiPhoneCountryCodeVO.setOrderByClause("country");
        hzPuiPhoneCountryCodeVO1.setOrderByClause("country");
        hzPuiPhoneCountryCodeVO.executeQuery();
        hzPuiPhoneCountryCodeVO1.executeQuery();

        OAViewObject hzPuiFaxCountryCodeVO1 = (OAViewObject)currentAm.findViewObject("HzPuiFaxCountryCodeVO");
        OAViewObject hzPuiFaxCountryCodeVO = (OAViewObject)currentAm.findViewObject("HzPuiFaxCountryCodeVO1");
        hzPuiFaxCountryCodeVO.setOrderByClause("country");
        hzPuiFaxCountryCodeVO1.setOrderByClause("country");
        hzPuiFaxCountryCodeVO.executeQuery();
        hzPuiFaxCountryCodeVO1.executeQuery();

        // VO querying for the AP Contact.

        OAViewObject apContactsVO = (OAViewObject)currentAm.findViewObject("ODAPContactsVO");
        apContactsVO.setWhereClause(null);
        apContactsVO.setWhereClauseParams(null);
        apContactsVO.setWhereClauseParam(0,apContactDD);
        apContactsVO.executeQuery();

        oracle.apps.fnd.framework.server.OAViewRowImpl curRow_apContactsVO = (oracle.apps.fnd.framework.server.OAViewRowImpl)apContactsVO.first();
        if (curRow_apContactsVO==null)
        {
         pageContext.writeDiagnostics("Anirban687: initializeAPandSalesContact", "Anirban : inside curRow_apContactsVO==null", OAFwkConstants.STATEMENT);
         apContactsVO.insertRow(apContactsVO.createRow());
        }

        OAViewObject apContactPointPhoneVO = (OAViewObject)currentAm.findViewObject("ODAPContactPointPhoneVO");
        apContactPointPhoneVO.setWhereClause(null);
        apContactPointPhoneVO.setWhereClauseParams(null);
        apContactPointPhoneVO.setWhereClauseParam(0,apContactDD);
        apContactPointPhoneVO.executeQuery();

        oracle.apps.fnd.framework.server.OAViewRowImpl curRow_apContactPointPhoneVO = (oracle.apps.fnd.framework.server.OAViewRowImpl)apContactPointPhoneVO.first();
        if (curRow_apContactPointPhoneVO==null)
        {
         pageContext.writeDiagnostics("Anirban687: initializeAPandSalesContact", "Anirban : inside curRow_apContactPointPhoneVO==null", OAFwkConstants.STATEMENT);
         apContactPointPhoneVO.insertRow(apContactPointPhoneVO.createRow());
        }

        OAViewObject apContactPointFaxVO = (OAViewObject)currentAm.findViewObject("ODAPContactPointFaxVO");
        apContactPointFaxVO.setWhereClause(null);
        apContactPointFaxVO.setWhereClauseParams(null);
        apContactPointFaxVO.setWhereClauseParam(0,apContactDD);
        apContactPointFaxVO.executeQuery();

        oracle.apps.fnd.framework.server.OAViewRowImpl curRow_apContactPointFaxVO = (oracle.apps.fnd.framework.server.OAViewRowImpl)apContactPointFaxVO.first();
        if (curRow_apContactPointFaxVO==null)
        {
         pageContext.writeDiagnostics("Anirban687: initializeAPandSalesContact", "Anirban : inside curRow_apContactPointFaxVO==null", OAFwkConstants.STATEMENT);
         apContactPointFaxVO.insertRow(apContactPointFaxVO.createRow());
        }

        OAViewObject apContactPointEmailVO = (OAViewObject)currentAm.findViewObject("ODAPContactPointEmailVO");
        apContactPointEmailVO.setWhereClause(null);
        apContactPointEmailVO.setWhereClauseParams(null);
        apContactPointEmailVO.setWhereClauseParam(0,apContactDD);
        apContactPointEmailVO.executeQuery();

        oracle.apps.fnd.framework.server.OAViewRowImpl curRow_apContactPointEmailVO = (oracle.apps.fnd.framework.server.OAViewRowImpl)apContactPointEmailVO.first();
        if (curRow_apContactPointEmailVO==null)
        {
     pageContext.writeDiagnostics("Anirban687: initializeAPandSalesContact", "Anirban : inside curRow_apContactPointEmailVO==null", OAFwkConstants.STATEMENT);
         apContactPointEmailVO.insertRow(apContactPointEmailVO.createRow());
        }


    // VO querying for the Sales Contact.

        OAViewObject salesContactsVO = (OAViewObject)currentAm.findViewObject("ODSalesContactsVO");
        salesContactsVO.setWhereClause(null);
        salesContactsVO.setWhereClauseParams(null);
        salesContactsVO.setWhereClauseParam(0,salesContactDD);
        salesContactsVO.executeQuery();

        oracle.apps.fnd.framework.server.OAViewRowImpl curRow_salesContactsVO = (oracle.apps.fnd.framework.server.OAViewRowImpl)salesContactsVO.first();
        if (curRow_salesContactsVO==null)
        {
     pageContext.writeDiagnostics("Anirban687: initializeAPandSalesContact", "Anirban : inside curRow_salesContactsVO==null", OAFwkConstants.STATEMENT);
         salesContactsVO.insertRow(salesContactsVO.createRow());
        }

        OAViewObject salesContactPointPhoneVO = (OAViewObject)currentAm.findViewObject("ODSalesContactPointPhoneVO");
        salesContactPointPhoneVO.setWhereClause(null);
        salesContactPointPhoneVO.setWhereClauseParams(null);
        salesContactPointPhoneVO.setWhereClauseParam(0,salesContactDD);
        salesContactPointPhoneVO.executeQuery();

        oracle.apps.fnd.framework.server.OAViewRowImpl curRow_salesContactPointPhoneVO = (oracle.apps.fnd.framework.server.OAViewRowImpl)salesContactPointPhoneVO.first();
        if (curRow_salesContactPointPhoneVO==null)
        {
     pageContext.writeDiagnostics("Anirban687: initializeAPandSalesContact", "Anirban : inside curRow_salesContactPointPhoneVO==null", OAFwkConstants.STATEMENT);
         salesContactPointPhoneVO.insertRow(salesContactPointPhoneVO.createRow());
        }

        OAViewObject salesContactPointFaxVO = (OAViewObject)currentAm.findViewObject("ODSalesContactPointFaxVO");
        salesContactPointFaxVO.setWhereClause(null);
        salesContactPointFaxVO.setWhereClauseParams(null);
        salesContactPointFaxVO.setWhereClauseParam(0,salesContactDD);
        salesContactPointFaxVO.executeQuery();

        oracle.apps.fnd.framework.server.OAViewRowImpl curRow_salesContactPointFaxVO = (oracle.apps.fnd.framework.server.OAViewRowImpl)salesContactPointFaxVO.first();
        if (curRow_salesContactPointFaxVO==null)
        {
     pageContext.writeDiagnostics("Anirban687: initializeAPandSalesContact", "Anirban : inside curRow_salesContactPointFaxVO==null", OAFwkConstants.STATEMENT);
         salesContactPointFaxVO.insertRow(salesContactPointFaxVO.createRow());
        }

        OAViewObject salesContactPointEmailVO = (OAViewObject)currentAm.findViewObject("ODSalesContactPointEmailVO");
        salesContactPointEmailVO.setWhereClause(null);
        salesContactPointEmailVO.setWhereClauseParams(null);
        salesContactPointEmailVO.setWhereClauseParam(0,salesContactDD);
        salesContactPointEmailVO.executeQuery();

        oracle.apps.fnd.framework.server.OAViewRowImpl curRow_salesContactPointEmailVO = (oracle.apps.fnd.framework.server.OAViewRowImpl)salesContactPointEmailVO.first();
        if (curRow_salesContactPointEmailVO==null)
        {
     pageContext.writeDiagnostics("Anirban687: initializeAPandSalesContact", "Anirban : inside curRow_salesContactPointEmailVO==null", OAFwkConstants.STATEMENT);
         salesContactPointEmailVO.insertRow(salesContactPointEmailVO.createRow());
        }

  }

  //Anirban: Added for Release 1.2 - Creation of AP and Sales contact

  void pprAPContact(OAPageContext pageContext,OAWebBean webBean, String apContactDD)
  {
    OAApplicationModule currentAm = (OAApplicationModule) pageContext.getApplicationModule(webBean);

        pageContext.writeDiagnostics("CR687", "inside pprAPContact api.", OAFwkConstants.STATEMENT);

    currentAm.invokeMethod("initPopLists_APContactTitle");

        OAViewObject hzPuiPhoneCountryCodeVO1 = (OAViewObject)currentAm.findViewObject("HzPuiPhoneCountryCodeVO1");
        hzPuiPhoneCountryCodeVO1.setOrderByClause("country");
        hzPuiPhoneCountryCodeVO1.executeQuery();

        OAViewObject hzPuiFaxCountryCodeVO1 = (OAViewObject)currentAm.findViewObject("HzPuiFaxCountryCodeVO1");
        hzPuiFaxCountryCodeVO1.setOrderByClause("country");
        hzPuiFaxCountryCodeVO1.executeQuery();

        // VO querying for the AP Contact.

        OAViewObject apContactsVO = (OAViewObject)currentAm.findViewObject("ODAPContactsVO");
        apContactsVO.setWhereClause(null);
        apContactsVO.setWhereClauseParams(null);
        apContactsVO.setWhereClauseParam(0,apContactDD);
        apContactsVO.executeQuery();

        oracle.apps.fnd.framework.server.OAViewRowImpl curRow_apContactsVO = (oracle.apps.fnd.framework.server.OAViewRowImpl)apContactsVO.first();
        if (curRow_apContactsVO==null)
        {
         pageContext.writeDiagnostics("CR687", "inside curRow_apContactsVO==null", OAFwkConstants.STATEMENT);
         apContactsVO.insertRow(apContactsVO.createRow());
        }

        OAViewObject apContactPointPhoneVO = (OAViewObject)currentAm.findViewObject("ODAPContactPointPhoneVO");
        apContactPointPhoneVO.setWhereClause(null);
        apContactPointPhoneVO.setWhereClauseParams(null);
        apContactPointPhoneVO.setWhereClauseParam(0,apContactDD);
        apContactPointPhoneVO.executeQuery();

        oracle.apps.fnd.framework.server.OAViewRowImpl curRow_apContactPointPhoneVO = (oracle.apps.fnd.framework.server.OAViewRowImpl)apContactPointPhoneVO.first();
        if (curRow_apContactPointPhoneVO==null)
        {
         pageContext.writeDiagnostics("CR687", "inside curRow_apContactPointPhoneVO==null", OAFwkConstants.STATEMENT);
         apContactPointPhoneVO.insertRow(apContactPointPhoneVO.createRow());
        }

        OAViewObject apContactPointFaxVO = (OAViewObject)currentAm.findViewObject("ODAPContactPointFaxVO");
        apContactPointFaxVO.setWhereClause(null);
        apContactPointFaxVO.setWhereClauseParams(null);
        apContactPointFaxVO.setWhereClauseParam(0,apContactDD);
        apContactPointFaxVO.executeQuery();

        oracle.apps.fnd.framework.server.OAViewRowImpl curRow_apContactPointFaxVO = (oracle.apps.fnd.framework.server.OAViewRowImpl)apContactPointFaxVO.first();
        if (curRow_apContactPointFaxVO==null)
        {
         pageContext.writeDiagnostics("CR687", "inside curRow_apContactPointFaxVO==null", OAFwkConstants.STATEMENT);
         apContactPointFaxVO.insertRow(apContactPointFaxVO.createRow());
        }

        OAViewObject apContactPointEmailVO = (OAViewObject)currentAm.findViewObject("ODAPContactPointEmailVO");
        apContactPointEmailVO.setWhereClause(null);
        apContactPointEmailVO.setWhereClauseParams(null);
        apContactPointEmailVO.setWhereClauseParam(0,apContactDD);
        apContactPointEmailVO.executeQuery();

        oracle.apps.fnd.framework.server.OAViewRowImpl curRow_apContactPointEmailVO = (oracle.apps.fnd.framework.server.OAViewRowImpl)apContactPointEmailVO.first();
        if (curRow_apContactPointEmailVO==null)
        {
     pageContext.writeDiagnostics("CR687", "inside curRow_apContactPointEmailVO==null", OAFwkConstants.STATEMENT);
         apContactPointEmailVO.insertRow(apContactPointEmailVO.createRow());
        }
  }

  void pprSalesContact(OAPageContext pageContext,OAWebBean webBean, String salesContactDD)
  {
    OAApplicationModule currentAm = (OAApplicationModule) pageContext.getApplicationModule(webBean);

    pageContext.writeDiagnostics("CR687", "inside pprSalesContact api.", OAFwkConstants.STATEMENT);

        currentAm.invokeMethod("initPopLists_SalesContactTitle");

        OAViewObject hzPuiPhoneCountryCodeVO = (OAViewObject)currentAm.findViewObject("HzPuiPhoneCountryCodeVO");
        hzPuiPhoneCountryCodeVO.setOrderByClause("country");
        hzPuiPhoneCountryCodeVO.executeQuery();

        OAViewObject hzPuiFaxCountryCodeVO = (OAViewObject)currentAm.findViewObject("HzPuiFaxCountryCodeVO");
        hzPuiFaxCountryCodeVO.setOrderByClause("country");
        hzPuiFaxCountryCodeVO.executeQuery();

        // VO querying for the Sales Contact.

        OAViewObject salesContactsVO = (OAViewObject)currentAm.findViewObject("ODSalesContactsVO");
        salesContactsVO.setWhereClause(null);
        salesContactsVO.setWhereClauseParams(null);
        salesContactsVO.setWhereClauseParam(0,salesContactDD);
        salesContactsVO.executeQuery();

        oracle.apps.fnd.framework.server.OAViewRowImpl curRow_salesContactsVO = (oracle.apps.fnd.framework.server.OAViewRowImpl)salesContactsVO.first();
        if (curRow_salesContactsVO==null)
        {
     pageContext.writeDiagnostics("CR687:", "inside curRow_salesContactsVO==null", OAFwkConstants.STATEMENT);
         salesContactsVO.insertRow(salesContactsVO.createRow());
        }

        OAViewObject salesContactPointPhoneVO = (OAViewObject)currentAm.findViewObject("ODSalesContactPointPhoneVO");
        salesContactPointPhoneVO.setWhereClause(null);
        salesContactPointPhoneVO.setWhereClauseParams(null);
        salesContactPointPhoneVO.setWhereClauseParam(0,salesContactDD);
        salesContactPointPhoneVO.executeQuery();

        oracle.apps.fnd.framework.server.OAViewRowImpl curRow_salesContactPointPhoneVO = (oracle.apps.fnd.framework.server.OAViewRowImpl)salesContactPointPhoneVO.first();
        if (curRow_salesContactPointPhoneVO==null)
        {
     pageContext.writeDiagnostics("CR687:", "inside curRow_salesContactPointPhoneVO==null", OAFwkConstants.STATEMENT);
         salesContactPointPhoneVO.insertRow(salesContactPointPhoneVO.createRow());
        }

        OAViewObject salesContactPointFaxVO = (OAViewObject)currentAm.findViewObject("ODSalesContactPointFaxVO");
        salesContactPointFaxVO.setWhereClause(null);
        salesContactPointFaxVO.setWhereClauseParams(null);
        salesContactPointFaxVO.setWhereClauseParam(0,salesContactDD);
        salesContactPointFaxVO.executeQuery();

        oracle.apps.fnd.framework.server.OAViewRowImpl curRow_salesContactPointFaxVO = (oracle.apps.fnd.framework.server.OAViewRowImpl)salesContactPointFaxVO.first();
        if (curRow_salesContactPointFaxVO==null)
        {
     pageContext.writeDiagnostics("CR687:", "inside curRow_salesContactPointFaxVO==null", OAFwkConstants.STATEMENT);
         salesContactPointFaxVO.insertRow(salesContactPointFaxVO.createRow());
        }

        OAViewObject salesContactPointEmailVO = (OAViewObject)currentAm.findViewObject("ODSalesContactPointEmailVO");
        salesContactPointEmailVO.setWhereClause(null);
        salesContactPointEmailVO.setWhereClauseParams(null);
        salesContactPointEmailVO.setWhereClauseParam(0,salesContactDD);
        salesContactPointEmailVO.executeQuery();

        oracle.apps.fnd.framework.server.OAViewRowImpl curRow_salesContactPointEmailVO = (oracle.apps.fnd.framework.server.OAViewRowImpl)salesContactPointEmailVO.first();
        if (curRow_salesContactPointEmailVO==null)
        {
     pageContext.writeDiagnostics("CR687:", "inside curRow_salesContactPointEmailVO==null", OAFwkConstants.STATEMENT);
         salesContactPointEmailVO.insertRow(salesContactPointEmailVO.createRow());
        }

  }

  //Anirban: Added for Release 1.2 - Creation of AP and Sales contact

  void showTheSelectedRequestDtls(OAPageContext pageContext,OAWebBean webBean, String newreqID)
        {
            final String METHOD_NAME = "xxcrm.customer.account.webui.ODAccountSetupCO.showTheSelectedRequestDtls";

                pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);

                OAApplicationModule currentAm = (OAApplicationModule) pageContext.getApplicationModule(webBean);

                //Anirban: Added for Release 1.2 - Creation of AP and Sales contact
            String salesContactDD = "";
            String apContactDD = "";
                String paymentMethod = "AB";
        //Anirban: Added for Release 1.2 - Creation of AP and Sales contact

                OAViewObject ODCustomerAccountSetupRequestDetailsVO = (OAViewObject)currentAm.findViewObject("ODCustomerAccountSetupRequestDetailsVO");
                if ( ODCustomerAccountSetupRequestDetailsVO == null )
                        ODCustomerAccountSetupRequestDetailsVO = (OAViewObject)currentAm.createViewObject("ODCustomerAccountSetupRequestDetailsVO",
                "od.oracle.apps.xxcrm.customer.account.server.ODCustomerAccountSetupRequestDetailsVO");

                OAViewObject customerAccountSetupRequestVO = (OAViewObject)currentAm.findViewObject("CustomerAccountSetupRequestVO");
                if ( customerAccountSetupRequestVO == null )
                        customerAccountSetupRequestVO = (OAViewObject)currentAm.createViewObject("CustomerAccountSetupRequestVO",
                "od.oracle.apps.xxcrm.customer.account.server.CustomerAccountSetupRequestVO");

                OAViewObject ODCustAcctSetupContractsVO = (OAViewObject)currentAm.findViewObject("ODCustAcctSetupContractsVO");
                if ( ODCustAcctSetupContractsVO == null )
                        ODCustAcctSetupContractsVO = (OAViewObject)currentAm.createViewObject("ODCustAcctSetupContractsVO",
                "od.oracle.apps.xxcrm.customer.account.server.ODCustAcctSetupContractsVO");

                OAViewObject ODCustAcctSetupDocumentVO = (OAViewObject)currentAm.findViewObject("ODCustAcctSetupDocumentVO");
                if ( ODCustAcctSetupDocumentVO == null )
                        ODCustAcctSetupDocumentVO = (OAViewObject)currentAm.createViewObject("ODCustAcctSetupDocumentVO",
                "od.oracle.apps.xxcrm.customer.account.server.ODCustAcctSetupDocumentVO");


                OAViewObject ODContractsAssignedVO = (OAViewObject)currentAm.findViewObject("ODContractsAssignedVO");
                if ( ODContractsAssignedVO == null )
                        ODContractsAssignedVO = (OAViewObject)currentAm.createViewObject("ODContractsAssignedVO",
                                "od.oracle.apps.xxcrm.customer.account.poplist.server.ODContractsAssignedVO");
        ODContractsAssignedVO.setMaxFetchSize(0);
        ODContractsAssignedVO.executeQuery();
        ODContractsAssignedVO.setMaxFetchSize(-1);

                ODCustomerAccountSetupRequestDetailsVO.setWhereClause("DELETE_FLAG = 'N' AND  REQUEST_ID = :1 ");
                ODCustomerAccountSetupRequestDetailsVO.setWhereClauseParam(0, newreqID);
                ODCustomerAccountSetupRequestDetailsVO.executeQuery();
                ODCustomerAccountSetupRequestDetailsVORowImpl  currentRow = ((ODCustomerAccountSetupRequestDetailsVORowImpl)ODCustomerAccountSetupRequestDetailsVO.first());
      Number partyId = new Number(0);
      String attribute5 = "0";
      String xref = " ";
    if (currentRow == null)
    {
      //System.out.println("current row null");
    }
    else
    {
      //System.out.println("sudeept current row not null att5 = "+currentRow.getAttribute5());
      partyId = currentRow.getPartyId() ;
      attribute5 =  currentRow.getAttribute5();
      xref = currentRow.getXref();

      ODContractsAssignedVO.setWhereClause("CONTRACT_TEMPLATE_ID = :1");
      ODContractsAssignedVO.setWhereClauseParam(0,attribute5 );
      ODContractsAssignedVO.executeQuery();

      //Anirban: Added for Release 1.2 - Creation of AP and Sales contact

      pageContext.writeDiagnostics("CR687", "Calling initializeAPandSalesContact api. Inside showTheSelectedRequestDtls api. Querying up the LOV VO's as well!", OAFwkConstants.STATEMENT);

          salesContactDD = currentRow.getApContact();
          apContactDD = currentRow.getAttribute13();
          paymentMethod = currentRow.getPaymentMethod();
          if (paymentMethod==null)
          {
           paymentMethod = "AB";
          }
          initializeAPandSalesContact(pageContext, webBean, apContactDD, salesContactDD, paymentMethod);
          //Anirban: Added for Release 1.2 - Creation of AP and Sales contact
    }

    //Anirban: Added for Release 1.2 - Creation of AP and Sales contact: populating the Contact's DD. This piece (as below) is intentionally kept out of the generic initialization api.

    //Populate AP Contact DD details
        OAViewObject ODApContactLovVO = (OAViewObject)currentAm.findViewObject("ODApContactLovVO");
        if ( ODApContactLovVO != null )
                ODApContactLovVO.remove();

        ODApContactLovVO = (OAViewObject)currentAm.createViewObject("ODApContactLovVO",
                   "od.oracle.apps.xxcrm.customer.account.poplist.server.ODApContactLovVO");

        ODApContactLovVO.setWhereClauseParam(0, partyId);
        ODApContactLovVO.executeQuery();

    //Populate Sales Contact DD details
        OAViewObject ODSalesContactLovVO = (OAViewObject)currentAm.findViewObject("ODSalesContactLovVO");
        if ( ODSalesContactLovVO != null )
                        ODSalesContactLovVO.remove();

        ODSalesContactLovVO = (OAViewObject)currentAm.createViewObject("ODSalesContactLovVO",
                   "od.oracle.apps.xxcrm.customer.account.poplist.server.ODApContactLovVO");

        ODSalesContactLovVO.setWhereClauseParam(0, partyId);
        ODSalesContactLovVO.executeQuery();

    //Anirban: Added for Release 1.2 - Creation of AP and Sales contact: populating the Contact's DD. This piece is intentionally kept out of the generic initialization api.


    ODCustAcctSetupContractsVO.setMaxFetchSize(0);
    ODCustAcctSetupContractsVO.executeQuery();
            //System.out.println("sudeept vo no of rows in vo 1 =  "+ODCustAcctSetupContractsVO.getRowCount()  );
    ODCustAcctSetupContractsVO.setMaxFetchSize(-1);
    //System.out.println("sudeept in show vo.setmaxfetchsize -1 ");
        ODCustAcctSetupContractsVO.setWhereClause(null);

                ODCustAcctSetupContractsVO.setWhereClause("NVL(CUSTOM,'Y') = 'Y' AND DELETE_FLAG = 'N' AND account_request_id = :1 ");
//                ODCustAcctSetupContractsVO.setWhereClause("DELETE_FLAG = 'N' AND account_request_id = :1 ");
                ODCustAcctSetupContractsVO.setWhereClauseParam(0, newreqID);
        //System.out.println("sudeept in show vo.excutequery"+ ODCustAcctSetupContractsVO.getQuery() );

                ODCustAcctSetupContractsVO.executeQuery();
        //System.out.println("sudeept vo no of rows in vo 2 =  "+ODCustAcctSetupContractsVO.getRowCount()  );

                ODCustAcctSetupDocumentVO.setWhereClause(" DELETE_FLAG = 'N' AND account_request_id = :1 ");
                ODCustAcctSetupDocumentVO.setWhereClauseParam(0, newreqID);
                ODCustAcctSetupDocumentVO.executeQuery();


                OAViewObject ODHzPuiAddressTableVO = (OAViewObject)currentAm.findViewObject("ODHzPuiAddressTableVO");
                if ( ODHzPuiAddressTableVO == null )
                        ODHzPuiAddressTableVO = (OAViewObject)currentAm.createViewObject("ODHzPuiAddressTableVO",
                    "od.oracle.apps.xxcrm.customer.account.server.ODHzPuiAddressTableVO");

                ODHzPuiAddressTableVO.setWhereClauseParam(0, partyId);
            ODHzPuiAddressTableVO.executeQuery();



                        OAViewObject ODPricePlanLovVO = (OAViewObject)currentAm.findViewObject("ODPricePlanLovVO");
                        if ( ODPricePlanLovVO == null )
                                ODPricePlanLovVO = (OAViewObject)currentAm.createViewObject("ODPricePlanLovVO",
                        "od.oracle.apps.xxcrm.customer.account.server.ODPricePlanLovVO");

                        ODPricePlanLovVO.setWhereClause(null);
                        ODPricePlanLovVO.setWhereClause("CONTRACT_TEMPLATE_ID = :1");

                        ODPricePlanLovVO.setWhereClauseParam(0,attribute5 );
                        ODPricePlanLovVO.setMaxFetchSize(-1);
                        ODPricePlanLovVO.executeQuery();

                OAViewObject ODAccountSetupButtonsPVO = (OAViewObject)currentAm.findViewObject("ODAccountSetupButtonsPVO");
                if ( ODAccountSetupButtonsPVO == null )
                        ODAccountSetupButtonsPVO = (OAViewObject)currentAm.createViewObject("ODAccountSetupButtonsPVO",
                                "od.oracle.apps.xxcrm.customer.account.server.ODAccountSetupButtonsPVO");

                    OAViewObject ODContTempCUPVO = (OAViewObject)currentAm.findViewObject("ODContTempCUPVO");

                    if (ODContTempCUPVO == null)
                    {
                        ODContTempCUPVO = (OAViewObject)currentAm.createViewObject("ODContTempCUPVO",
                    "od.oracle.apps.xxcrm.customer.account.server.ODContTempCUPVO");
                    };

                    pageContext.writeDiagnostics(METHOD_NAME, "Making XREF read only if its not null", OAFwkConstants.PROCEDURE);
                if (xref != null )
                {

              ODContTempCUPVO.setMaxFetchSize(0) ;
                    ODContTempCUPVO.executeQuery();
                    ODContTempCUPVORowImpl pvoRow = (ODContTempCUPVORowImpl)ODContTempCUPVO.createRow();
                    ODContTempCUPVO.insertRow(pvoRow);

                    pvoRow.setReadOnly(Boolean.TRUE );
                    pvoRow.setRendered(Boolean.FALSE );
                        };


                        pageContext.writeDiagnostics(METHOD_NAME, "default cont temp id = "+attribute5, OAFwkConstants.PROCEDURE);

                        ODCustAcctSetupContractsVO.setWhereClause("NVL(CUSTOM,'Y') = 'Y' AND DELETE_FLAG = 'N' AND account_request_id = :1 ");
//                        ODCustAcctSetupContractsVO.setWhereClause("DELETE_FLAG = 'N' AND account_request_id = :1 ");
                        ODCustAcctSetupContractsVO.setWhereClauseParam(0, newreqID);
                        ODCustAcctSetupContractsVO.executeQuery();

                ODAccountSetupButtonsPVO.setMaxFetchSize(0) ;
                ODAccountSetupButtonsPVO.executeQuery();
                ODAccountSetupButtonsPVORowImpl buttonRenderedRow = (ODAccountSetupButtonsPVORowImpl)ODAccountSetupButtonsPVO.createRow();
                ODAccountSetupButtonsPVO.insertRow(buttonRenderedRow);


                buttonRenderedRow.setAddCustomContractRendered(Boolean.TRUE);
                buttonRenderedRow.setAddCustomDocumentRendered(Boolean.TRUE);
                buttonRenderedRow.setCopyRequestRowRendered(Boolean.TRUE);
                buttonRenderedRow.setDeleteContractRendered(Boolean.TRUE);
                buttonRenderedRow.setDeleteDocumentRendered(Boolean.TRUE);
                buttonRenderedRow.setDeleteRequestRendered(Boolean.TRUE);
                buttonRenderedRow.setSubmitRequestRendered(Boolean.TRUE);
                buttonRenderedRow.setValidateAndSaveRendered(Boolean.TRUE);


                        ODCustAcctSetupDocumentVO.setWhereClause(" DELETE_FLAG = 'N' AND account_request_id = :1 ");
                ODCustAcctSetupDocumentVO.setWhereClauseParam(0, newreqID);
                        ODCustAcctSetupDocumentVO.executeQuery();

                //Apply all the rendering logics.
                ODCustomerAccountSetupRequestDetailsVORowImpl curRow2= (ODCustomerAccountSetupRequestDetailsVORowImpl)ODCustomerAccountSetupRequestDetailsVO.first();
                String status="";
        //OAMessageLovInputBean lovSgmntn = (OAMessageLovInputBean)webBean.findChildRecursive("CustSegmentLovItem");
        //lovSgmntn.setReadOnly(false);
        //OAMessageLovInputBean lovLylty = (OAMessageLovInputBean)webBean.findChildRecursive("CustLoyalLovItem");
        //lovLylty.setReadOnly(false);
                if (curRow2 != null)  status = curRow2.getStatus();
             if ("Draft".equalsIgnoreCase(status))
                                           {
                                                   makeTheFormEditable(pageContext, webBean);
                                                   enableButton(pageContext, webBean);
                                                   buttonRenderedRow.setSubmitRequestRendered(Boolean.FALSE);
                        //lovSgmntn.setReadOnly(false);
                        //lovLylty.setReadOnly(false);
                                           }
                                           else if ("Validated".equalsIgnoreCase(status))
                                           {
                                                   makeTheFormEditable(pageContext, webBean);
                                                   enableButton(pageContext, webBean);
                        //lovSgmntn.setReadOnly(false);
                        //lovLylty.setReadOnly(false);

                                           }
                                           else if ("Submitted".equalsIgnoreCase(status))
                                                           {
                                                                   makeTheFormReadOnly(pageContext, webBean);
                                                                   disablesubButton(pageContext, webBean);
                                //lovSgmntn.setReadOnly(true);
                                //lovLylty.setReadOnly(true);

                                           }
                                           else if ("BPEL Transmission Successful".equalsIgnoreCase(status))
                                           {
                                                   makeTheFormReadOnly(pageContext, webBean);
                                                   disableDelButton(pageContext, webBean);
                        //lovSgmntn.setReadOnly(true);
                        //lovLylty.setReadOnly(true);
                                            }
                                           else
                                           {
                                                   makeTheFormReadOnly(pageContext, webBean);
                                                   disableAllButton(pageContext, webBean);
                        //lovSgmntn.setReadOnly(false);
                        //lovLylty.setReadOnly(false);
                                    }

                   pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
        }

}
