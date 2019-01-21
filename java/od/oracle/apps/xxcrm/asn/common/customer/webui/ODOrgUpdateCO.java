 /*===========================================================================+
  |                            Office Depot - Project Simplify                |
  |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
  +===========================================================================+
  |  FILENAME                                                                 |
  |             ODOrgUpdateCO.java                                            |
  |                                                                           |
  |  DESCRIPTION                                                              |
  |    od.oracle.apps.xxcrm.asn.common.customer.webui.ODOrgUpdateCO.java is   |
  |    includes the orginal code in OrgViewCO.java file in its entirity along |
  |    with some custom modifications. The Controller will extend the custom  |
  |    ODASNControllerObjectImpl.java security object.                        |
  |                                                                           |
  |                                                                           |
  |  NOTES                                                                    |
  |                                                                           |
  |                                                                           |
  |  DEPENDENCIES                                                             |
  |    None                                                                   |
  |                                                                           |
  |  HISTORY                                                                  |
  |                                                                           |
  |    10/08/2007   Ashok Kumar T J    Created                                |
  |    10/01/2007   Jeevan Babu        Added code to handle Customer Accts Tab|
  |    12/12/2007   Anirban Chaudhuri  Added code to make the page read only  |
  |    24/01/2007   Anirban Chaudhuri  Added code to make the page read only  |
  |    04/03/2008   Jasmine Sujithra   Update Customer breadcrumb issue for RO|
  |    25/07/2008   V Jayamohan        Fix for QC-9233                        |
  |    12/05/2009   Anirban Chaudhuri  Fix for QC-14801                       |
  |    09/10/2009   Anirban Chaudhuri  Added NetPricer Subtab                 |
  |    08/06/2010   Anitha Devarajulu  Added code to inactive Status field for|
  |                                    Defect 6262                            |
  +===========================================================================*/
package od.oracle.apps.xxcrm.asn.common.customer.webui;

/* Subversion Info:

*

* $HeadURL$

*

* $Rev$

*

* $Date$

*/


import com.sun.java.util.collections.HashMap;

import java.io.Serializable;

import od.oracle.apps.xxcrm.asn.common.fwk.webui.ODASNControllerObjectImpl;

import oracle.apps.asn.common.fwk.webui.ASNUIConstants;
import oracle.apps.asn.common.webui.ASNUIUtil;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OADescriptiveFlexBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.layout.OACellFormatBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAStackLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OASubTabLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.nav.OAButtonBean;
import oracle.apps.fnd.framework.webui.beans.nav.OALinkBean;
import oracle.apps.fnd.framework.webui.beans.nav.OASubTabBarBean;
import oracle.apps.fnd.framework.webui.beans.table.OAAdvancedTableBean;
import oracle.apps.fnd.framework.webui.beans.table.OASingleSelectionBean;
import oracle.apps.fnd.framework.webui.beans.layout.*;
import oracle.apps.fnd.framework.webui.beans.message.*;
import oracle.apps.fnd.framework.webui.beans.*;
import oracle.apps.fnd.framework.webui.beans.table.*;

import oracle.jbo.Row;
import oracle.apps.fnd.framework.OAViewObject;
import od.oracle.apps.xxcrm.customer.account.server.ODCustomerAccountsVOImpl;
import od.oracle.apps.xxcrm.customer.account.server.ODCustomerAccountsVORowImpl;
import od.oracle.apps.xxcrm.asn.common.customer.server.ODPartyOrigSysRefVOImpl;
import od.oracle.apps.xxcrm.asn.common.customer.server.ODPartyOrigSysRefVORowImpl;
import od.oracle.apps.xxcrm.asn.common.customer.server.ODWRFRefVORowImpl;
import od.oracle.apps.xxcrm.asn.common.customer.server.ODWRFRefVOImpl;
import oracle.jdbc.driver.OracleCallableStatement;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;
import java.sql.ResultSet;
import oracle.jdbc.OracleResultSet;
import oracle.apps.fnd.framework.webui.beans.nav.OAButtonBean;

/**
 * Controller for Organization Details Page.
 */
public class ODOrgUpdateCO extends ODASNControllerObjectImpl
{
  public static final String RCS_ID="$Header: ODOrgUpdateCO.java 115.44.115200.3 2007/10/08 16:40:48 AshokKumar ship $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "od.oracle.apps.xxcrm.asn.common.customer.webui");

  /**
   * Layout and page setup logic for AK region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {

    final String METHOD_NAME = "xxcrm.asn.common.customer.webui.ODOrgUpdateCO.processRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    if (isProcLogEnabled)
    {
    pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processRequest(pageContext, webBean);

    String partyId  = pageContext.getParameter("ASNReqFrmCustId");
    if ( partyId == null )  {
         OAException e = new OAException("ASN", "ASN_TCA_CUSTPARAM_MISS_ERR");
         pageContext.putDialogMessage(e);
    }else
    {
    OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);
     
//   Serializable[] methodParam = {partyId};
//     am.invokeMethod("initWRFAcc",methodParam);


	OAViewObject View= (OAViewObject)am.findViewObject("ODWRFRefVO");
      if ( View == null )
      View = (OAViewObject)am.createViewObject("ODWRFRefVO","od.oracle.apps.xxcrm.asn.common.customer.server.ODWRFRefVO");


      if ( View != null )
      {
       View.setWhereClause(null);
       View.setWhereClauseParams(null);
       View.setWhereClauseParam(0, partyId);
       View.executeQuery();
      }

     
      ODWRFRefVORowImpl vrowban = (ODWRFRefVORowImpl)View.first();
 	if (vrowban != null)
      {
      OAButtonBean wnbButton=  (OAButtonBean )webBean.findChildRecursive("wrfbtn");
      
      if (vrowban.getDisable().equals("True"))
       {
        if(wnbButton!= null)
          wnbButton.setRendered(false); 
        }   
       }

//  Starting Changes made for Defect 6262 by Anitha

    Boolean flag = isCustomer(partyId,am);
    if (flag == true)
    {
       OADefaultStackLayoutBean ASNOrgUpdateHdrRN1 = (OADefaultStackLayoutBean) webBean.findChildRecursive("ASNOrgUpdateHdrRN");
       OAMessageChoiceBean party_status1 =  (OAMessageChoiceBean)ASNOrgUpdateHdrRN1.findChildRecursive("party_status");
       party_status1.setDisabled(true);
    }

//  Ending Changes made for Defect 6262 by Anitha

    String partyName  = null; //pageContext.getParameter("ASNReqFrmCustName");

    if(partyName == null) {
        Serializable[] parameters =  { partyId };
        partyName = (String) am.invokeMethod("getPartyNameFromId", parameters);
    }

    // set up page title
    MessageToken[] tokens = { new MessageToken("PARTYNAME", partyName) };
    String pageTitle = pageContext.getMessage("ASN", "ASN_TCA_UPDT_CUST_TITLE", tokens);
    // Set the page title (which also appears in the breadcrumbs)
    ((OAPageLayoutBean)webBean).setTitle(pageTitle);

    //set up the colspan for the Business Activities
    OACellFormatBean bussActCell = (OACellFormatBean)webBean.findChildRecursive("ASNBusinessActCell");
    if(bussActCell != null){
       bussActCell.setColumnSpan(2);
    }

    //hide the un-supported items in the tca components that should not be personalized by the user
    //contacts section
    OAStackLayoutBean asnCtctInfoRN = (OAStackLayoutBean) webBean.findChildRecursive("ASNCtctInfoRN");
    if(asnCtctInfoRN != null)
    {
      //hide buttons in the contacts view component
      OASubmitButtonBean hzPuiContRelTableMarkDupEventButton=  (OASubmitButtonBean)asnCtctInfoRN.findChildRecursive("HzPuiContRelTableMarkDupEvent");
      if(hzPuiContRelTableMarkDupEventButton != null)
      {
        hzPuiContRelTableMarkDupEventButton.setRendered(false);
      }

      OASubmitButtonBean hzPuiContRelTableSelPrimaryEventButton=  (OASubmitButtonBean)asnCtctInfoRN.findChildRecursive("HzPuiContRelTableSelPrimaryEvent");
      if(hzPuiContRelTableSelPrimaryEventButton != null)
      {
        hzPuiContRelTableSelPrimaryEventButton.setRendered(false);
      }

      OASubmitButtonBean hzPuiContRelTableViewHistoryEventButton=  (OASubmitButtonBean)asnCtctInfoRN.findChildRecursive("HzPuiContRelTableViewHistoryEvent");
      if(hzPuiContRelTableViewHistoryEventButton != null)
      {
        hzPuiContRelTableViewHistoryEventButton.setRendered(false);
      }

      OAMessageChoiceBean HzPuiContTableCreateRelRoleChoice=  (OAMessageChoiceBean)asnCtctInfoRN.findChildRecursive("HzPuiContTableCreateRelRole");
      if(HzPuiContTableCreateRelRoleChoice != null)
      {
        HzPuiContTableCreateRelRoleChoice.setRendered(false);
      }

      //hide restore icon column in the contacts table.
      // Hide the "restore" bean. Made changes here for backward compatibility as TCA
      // CPUI component changed from Link to Switcher Bean. Original reference to OALinkBean
      // is removed as part of the fix.
      if(asnCtctInfoRN.findChildRecursive("restore") != null)
      {
        asnCtctInfoRN.findChildRecursive("restore").setRendered(false);
      }
      // Custom code starts here
      // Code to change the button prompt to Contacts
      OASubmitButtonBean hzPuiContRelTableCreateEventButton =  (OASubmitButtonBean)asnCtctInfoRN.findChildRecursive("HzPuiContRelTableCreateEvent");
      if(hzPuiContRelTableCreateEventButton != null)
      {
         hzPuiContRelTableCreateEventButton.setText("Create");
      }
      // Custom code ends here
    }
    //end contact section

    //address section
    OAHeaderBean asnAddrViewRN = (OAHeaderBean) webBean.findChildRecursive("ASNAddrViewRN");
    if(asnAddrViewRN != null){
      //hide the buttons in the address view component
      OASubmitButtonBean hzPuiViewInactiveButton=  (OASubmitButtonBean)asnAddrViewRN.findChildRecursive("HzPuiViewInactiveButton");
      if(hzPuiViewInactiveButton != null){
        hzPuiViewInactiveButton.setRendered(false);
      }
      OASubmitButtonBean hzPuiSelectPrimaryUseButton=  (OASubmitButtonBean)asnAddrViewRN.findChildRecursive("HzPuiSelectPrimaryUseButton");
      if(hzPuiSelectPrimaryUseButton != null){
        hzPuiSelectPrimaryUseButton.setRendered(false);
      }
    }
    //end address section

    //relationships section
    OAStackLayoutBean asnRelInfoRN = (OAStackLayoutBean) webBean.findChildRecursive("ASNRelInfoRN");
    if(asnRelInfoRN != null)
    {
      //hide the button in the relationship view component
      OASubmitButtonBean hzPuiPartyRelTableMarkDupEventButton=  (OASubmitButtonBean)asnRelInfoRN.findChildRecursive("HzPuiPartyRelTableMarkDupEvent");
      if(hzPuiPartyRelTableMarkDupEventButton != null)
      {
        hzPuiPartyRelTableMarkDupEventButton.setRendered(false);
      }

      OASubmitButtonBean hzPuiPartyRelTableViewHistoryEventButton=  (OASubmitButtonBean)asnRelInfoRN.findChildRecursive("HzPuiPartyRelTableViewHistoryEvent");
      if(hzPuiPartyRelTableViewHistoryEventButton != null)
      {
        hzPuiPartyRelTableViewHistoryEventButton.setRendered(false);
      }

      //hide restore icon column in the relationships table.
      // Hide the "restore" bean. Made changes here for backward compatibility as TCA
      // CPUI component changed from Link to Switcher Bean. Original reference to OALinkBean
      // is removed as part of the fix.
      if(asnRelInfoRN.findChildRecursive("restore") != null)
      {
        asnRelInfoRN.findChildRecursive("restore").setRendered(false);
      }
    }
    //end relationships section

    //classification section
    //OAStackLayoutBean asnClsInfoRN = (OAStackLayoutBean) webBean.findChildRecursive("ASNClsInfoRN");
    OAHeaderBean asnClsInfoRN = (OAHeaderBean) webBean.findChildRecursive("ASNClsInfoRN");
    if(asnClsInfoRN != null){
      //hide the button in the classification view component
      OASubmitButtonBean hzPuiClassificationViewHistoryButton=  (OASubmitButtonBean)asnClsInfoRN.findChildRecursive("HzPuiClassificationViewHistory");
      if(hzPuiClassificationViewHistoryButton != null){
        hzPuiClassificationViewHistoryButton.setRendered(false);
      }
    }

    OAHeaderBean asnIndClsInfoRN = (OAHeaderBean) webBean.findChildRecursive("ASNIndClsInfoRN");
    if(asnIndClsInfoRN != null){
      //hide the button in the classification view component
      OASubmitButtonBean hzPuiIndClassificationViewHistoryButton=  (OASubmitButtonBean)asnClsInfoRN.findChildRecursive("HzPuiIndClassificationViewHistory");
      if(hzPuiIndClassificationViewHistoryButton != null){
        hzPuiIndClassificationViewHistoryButton.setRendered(false);
      }
    }
    //end of classification section

    //end of hiding the un-supported items in tca components that should not be personalizable



    //save partyname in the transaction.
    pageContext.putTransactionValue("ASNTxnCustName", partyName);
    // Diagnostic.println("----------------->ODOrgUpdateCO->processRequest. partyId = " + partyId);
    // Diagnostic.println("----------------->ODOrgUpdateCO->processRequest. partyName = " + partyName);

    //put the parameters required for the header and profile regions
    pageContext.putParameter("HzPuiOrgProfileEvent", "UPDATE");
    pageContext.putParameter("HzPuiEmployeeInfoEvent", "UPDATE");
    pageContext.putParameter("HzPuiIncomeEvent", "UPDATE");
    pageContext.putParameter("HzPuiOrgProfilePartyId", partyId);
    pageContext.putParameter("HzPuiEmployeePartyId", partyId);
    pageContext.putParameter("HzPuiTaxFinancialPartyId", partyId);

    //put the parameters required for the products under contract region
    pageContext.putTransactionValue("ASNTxnCustomerId", partyId);

    //put the parameters required for the notes region
          pageContext.putTransactionValue("ASNTxnNoteSourceCode", "PARTY");
    pageContext.putTransactionValue("ASNTxnNoteSourceId", partyId);

    //put the parameters required for the tasks region
    pageContext.putTransactionValue("cacTaskSrcObjCode", "PARTY");
    pageContext.putTransactionValue("cacTaskSrcObjId", partyId);
    pageContext.putTransactionValue("cacTaskCustId", partyId);
    pageContext.putTransactionValue("cacTaskContDqmRule", (String) pageContext.getProfile("HZ_DQM_CON_SIMPLE_MATCHRULE"));/*"10002";*/
    pageContext.putTransactionValue("cacTaskNoDelDlg", "Y");
    pageContext.putTransactionValue("cacTaskReturnUrl", getModifiedCurrentUrlForRedirect(pageContext, true));

    //put the parameters required for the address region
    pageContext.putParameter("HzPuiAddressEvent", "ViewAddress");
    pageContext.putParameter("HzPuiAddressPartyId", partyId);

    //put the parameters required for the contact points
    pageContext.putParameter("HzPuiCPPhoneTableEvent", "UPDATE");
    pageContext.putParameter("HzPuiCPEmailTableEvent", "UPDATE");
    pageContext.putParameter("HzPuiCPUrlTableEvent", "UPDATE");
    pageContext.putParameter("HzPuiOwnerTableName", "HZ_PARTIES");
    pageContext.putParameter("HzPuiOwnerTableId", partyId );

    //put the parameters required for the classification region
    pageContext.putParameter("HzPuiPartyId", partyId);


    //put the parameters required for the contact regions
    pageContext.putParameter("HzPuiContRelTableObjectPartyId", partyId);
    pageContext.putParameter("HzPuiContRelTableObjectPartyType", "ORGANIZATION");
    pageContext.putParameter("HzPuiContRelTableMode", "CURRENT");

    //put the parameters required for the relationships region
    pageContext.putParameter("HzPuiPartyRelTableObjectPartyId", partyId);
    pageContext.putParameter("HzPuiPartyRelTableObjectPartyType", "ORGANIZATION");
    pageContext.putParameter("HzPuiPartyRelTableSubjectPartyType", "ORGANIZATION");
    pageContext.putParameter("HzPuiPartyRelTableMode", "CURRENT");



    // sales Team UI
    //get the customerid parameter
    String custId = pageContext.getParameter("ASNReqFrmCustId");
    if (custId != null)
    {
        // resource group binding
        // ***** Replaced the below code as the item style is changed to messageStyleText for the bean
        OAMessageChoiceBean groupBean = (OAMessageChoiceBean)webBean.findIndexedChildRecursive("ASNSTGroup");
        OAAdvancedTableBean STBean = (OAAdvancedTableBean)webBean.findIndexedChildRecursive("ASNSTLstTb");
        if(groupBean != null && STBean != null)
        {
          groupBean.setListVOBoundContainerColumn(0,STBean,"ASNSTRscId");
          groupBean.setListVOBoundContainerColumn(1,STBean,"ASNSTGroupId");
        }

        //init query
        Serializable [] STparam = {custId};
        am.invokeMethod("initSalesTeamQuery", STparam);
    }

    //parameters for the partners sales team region.

    pageContext.putTransactionValue("PvCustomerId", pageContext.getParameter("ASNReqFrmCustId"));
    pageContext.putTransactionValue("prmReturnUrl", getModifiedCurrentUrlForRedirect(pageContext, true));



   //put the code required for the attachments
   //attachment integration here
    ASNUIUtil.attchSetUp(pageContext
                    ,webBean
                    ,true
                    ,"ASNOrgAttchTable"//This is the attachment table item
                    ,"ASNOrgAttchContextHolderRN"//This is the stack region that holds the context information
                    ,"ASNOrgAttchContextRN");//this is the messageComponentLayout region that holds actual context beans

    /*
     * initialize TCA parameters required for subtab PPR
     */
    Serializable [] pparams = {partyId};
    am.invokeMethod("initSubtabPPRParameters", pparams);

    //put the parameters required for the business activities region
    pageContext.putTransactionValue("ASNTxnCustomerId", partyId);
    pageContext.putTransactionValue("ASNTxnBusActLkpTyp", "ASN_BUSINESS_ACTS");
    pageContext.putTransactionValue("ASNTxnAddBrdCrmb", "ADD_BREAD_CRUMB_YES");
    pageContext.putTransactionValue("ASNTxnReturnUrl", getModifiedCurrentUrlForRedirect(pageContext, true));

    //initializes the query for the customer actions poplist
    am.invokeMethod("initCustomerActionsQuery", null);

    /***Flexfields for the customer sales team*/
    // Get a handle to the StackLayout of the Additional Info region
    //OAStackLayoutBean stBean = (OAStackLayoutBean)webBean.findIndexedChildRecursive("ASNCustSalesTeamAddInfoRN");
    // Get a handle to the Header Bean
    OAHeaderBean headerRn=(OAHeaderBean)webBean.findIndexedChildRecursive("ASNCustSalesTeamAddInfoHdrRN");
    // Get a handle to the flexfield
    OADescriptiveFlexBean flexBean = (OADescriptiveFlexBean)webBean.findIndexedChildRecursive("ASNCustSalesTeamAddInfoFF");
    // Get a handle to the select column
    OASingleSelectionBean selector = null;
    OAAdvancedTableBean STBean = (OAAdvancedTableBean)webBean.findIndexedChildRecursive("ASNSTLstTb");
    if(STBean != null)
      selector = (OASingleSelectionBean) STBean.getTableSelection();

   // Check if the Header Layout is Rendered (user may have personalized)
    if(headerRn != null && headerRn.isRendered())
    {
      // check if No Rows exist in the VO of the table.
     if (Boolean.FALSE.equals(am.invokeMethod("rowExistsInSalesteamDetails")))
      {
        // No Rows Exist, Hence we should not render the FlexField, its Header beans.
        headerRn.setRendered(false);
        if(flexBean != null)
        {
          flexBean.setFlexTableRendered(false);
          flexBean.setRendered(false);
        }
        if(selector != null)
          selector.setRendered(false);
      }
     else
      {
        // Render the Flexfield
        headerRn.setRendered(true);
        if(flexBean != null)
        {
          flexBean.setFlexTableRendered(true);
          flexBean.setRendered(true);
        }
        if(selector != null)
          selector.setRendered(true);
      }
      // Refresh the Current Row or set the first row
      am.invokeMethod("refreshSalesteamDetailsRow");
    }
   else
      if(selector != null) {
        selector.setRendered(false);
    }
    /*** end of flexfields for the customer sales team*/

    // set return to link destination
    ///*comment it out for now*/addReturnLink( pageContext, webBean, "ASNOrgUpdRetLnk");

      // ******* Custom code starts here
      // Code to add Customer Accounts Tab in Customer details page.
      pageContext.putParameter("pid",custId );
      OAButtonBean viewHierButton = (OAButtonBean) webBean.findChildRecursive("viewHierBtn");
      OAButtonBean viewRelaButton = (OAButtonBean) webBean.findChildRecursive("viewRelaBtn");
      OADBTransaction oa = pageContext.getApplicationModule(webBean).getOADBTransaction();
      if ("Y".equals(oa.getProfile("XX_ASN_CUSTOMER_HIERARCHY")))
      {
        viewHierButton.setFireActionForSubmit("viewHierBtnClicked", null, null, false);
        String s2 = "OA.jsp?page=/oracle/apps/imc/home/webui/VisualPage&pid="+pageContext.getParameter("pid")+"&VisHidden2=Y";
        viewRelaButton.setOnClick("javascript:window.open('" + s2 + "','self', 'resizable, width=750,height=500,menubar=yes,toolbar=yes,statusbar=yes,location=yes,locationbar=yes,scrollbars=yes')");
      }
      else
      {
        viewRelaButton.setRendered(false);
        viewHierButton.setRendered(false);
      }

      //Added for Account Request
      OASubTabLayoutBean tabBean = (OASubTabLayoutBean)webBean.findChildRecursive("ASNOrgUpdateSubtabLayoutRN");
      OAStackLayoutBean accountSetup = new OAStackLayoutBean();
      accountSetup.setText("Account Setup");
      OASubTabBarBean subTabBean = (OASubTabBarBean)webBean.findChildRecursive("ASNOrgUpdateSubtabBar");

      //Code for Account Setup Tab
      OAStackLayoutBean accountSetupRegion= (OAStackLayoutBean)createWebBean(pageContext,
                   "/od/oracle/apps/xxcrm/asn/common/customer/webui/ODOrgAccountSetupRN",
                   "AccountSetupRN",
                   true);
      OALinkBean accountSetupLink = new OALinkBean();
      accountSetupLink.setText("Account Setup");
      accountSetupLink.setFireActionForSubmit("update", null, null, true, true);
      accountSetupLink.setID("AccountSetupTab");
      tabBean.addIndexedChild(accountSetupRegion);
      subTabBean.addIndexedChild(accountSetupLink);

      //View Account Details tab
      OAStackLayoutBean accountSetup2 = (OAStackLayoutBean)createWebBean(pageContext,"/od/oracle/apps/xxcrm/asn/common/customer/webui/ODViewAccountDetailsRN","ViewAccountDetRN",true);
      OALinkBean oalb = new OALinkBean();
      oalb.setText("View Account Details");
      oalb.setFireActionForSubmit("update", null, null, true, true);
      tabBean.addIndexedChild(accountSetup2);
      subTabBean.addIndexedChild(oalb);


//ANIRBAN ADDED CODE FOR ADDING THE NETPRICER REGION AS A SUBTAB ON 09 OCT'09 : STARTS

      String errMsg = "N";

      String banPartyId = partyId;
      String custNumberDefault = "";
      String addressSeqDefault = "";

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
       ODCustomerAccountsVO.setWhereClauseParam(0, banPartyId);
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
        pageContext.writeDiagnostics(METHOD_NAME, "Anirban: If Account Number exists make the netPricer subtab NOT hidden",  OAFwkConstants.STATEMENT);
        errMsg = "Y";        
       }
       rowban  = (ODCustomerAccountsVORowImpl)ODCustomerAccountsVO.next();
      }

      pageContext.writeDiagnostics(METHOD_NAME, "Anirban value of errMsg is :"+errMsg,  OAFwkConstants.STATEMENT);

      //errMsg = "N";
      if (errMsg.equals("Y"))
      {
       OASubTabLayoutBean tabBeanNP = (OASubTabLayoutBean)webBean.findChildRecursive("ASNOrgUpdateSubtabLayoutRN");
       OAFlowLayoutBean netPricerRN = new OAFlowLayoutBean();
       netPricerRN.setText("Customer Reports");
       OASubTabBarBean subTabBeanNP = (OASubTabBarBean)webBean.findChildRecursive("ASNOrgUpdateSubtabBar");

       //Code for Net Pricer Sub Tab
       OAFlowLayoutBean netpricerRegion= (OAFlowLayoutBean)createWebBean(pageContext,
                   "/od/oracle/apps/xxcrm/netPricer/webui/ODNetPricerRN",
                   "NetPricerRN",
                   true);
       OALinkBean netPricerSubTabLink = new OALinkBean();
       netPricerSubTabLink.setText("Customer Reports");
       netPricerSubTabLink.setID("NetPricerSubTab");
       tabBeanNP.addIndexedChild(netpricerRegion);
       subTabBeanNP.addIndexedChild(netPricerSubTabLink);
       netPricerSubTabLink.setFireActionForSubmit("update", null, null, true, true);
      }

      //Logic for defaulting customer number and address sequence STARTS here.

      OAViewObject ODPartyOrigSysRefVO = (OAViewObject)am.findViewObject("ODPartyOrigSysRefVO");
      if ( ODPartyOrigSysRefVO == null )
      ODPartyOrigSysRefVO = (OAViewObject)am.createViewObject("ODPartyOrigSysRefVO","od.oracle.apps.xxcrm.asn.common.customer.server.ODPartyOrigSysRefVO");

      if(ODPartyOrigSysRefVO == null)
      {
       pageContext.writeDiagnostics(METHOD_NAME, "Anirban: ODPartyOrigSysRefVO is still NULL",  OAFwkConstants.STATEMENT);
       pageContext.writeDiagnostics(METHOD_NAME, "Anirban: party id is : "+banPartyId,  OAFwkConstants.STATEMENT);
      }

      if ( ODPartyOrigSysRefVO != null )
      {
       ODPartyOrigSysRefVO.setWhereClause(null);
       ODPartyOrigSysRefVO.setWhereClauseParams(null);
       ODPartyOrigSysRefVO.setWhereClauseParam(0, banPartyId);
       ODPartyOrigSysRefVO.executeQuery();
       pageContext.writeDiagnostics(METHOD_NAME, "Anirban: party id is : "+banPartyId,  OAFwkConstants.STATEMENT);
      }

      ODPartyOrigSysRefVORowImpl rowban1 = (ODPartyOrigSysRefVORowImpl)ODPartyOrigSysRefVO.first();

      if(rowban1 == null)
      {
       pageContext.writeDiagnostics(METHOD_NAME, "Anirban: rowban1 is NULL",  OAFwkConstants.STATEMENT);
      }

      while (rowban1 != null)
      {
       pageContext.writeDiagnostics(METHOD_NAME, "Anirban: inside rowban1 != null ",  OAFwkConstants.STATEMENT);
       if (rowban1.getCustNumber() != null)
       {
        pageContext.writeDiagnostics(METHOD_NAME, "Anirban: rowban1.getCustNumber() != null",  OAFwkConstants.STATEMENT);
        custNumberDefault = rowban1.getCustNumber();
        addressSeqDefault = rowban1.getAddrSeq();
        break;        
       }
       rowban1  = (ODPartyOrigSysRefVORowImpl)ODPartyOrigSysRefVO.next();
      }



      OAFlowLayoutBean netPricerRNtoSetValue = (OAFlowLayoutBean)tabBean.findChildRecursive("NetPricerRN");
      if(netPricerRNtoSetValue != null)
      {
       OAMessageTextInputBean custNumberNPRN = (OAMessageTextInputBean)netPricerRNtoSetValue.findChildRecursive("CustNumber");
       if(custNumberNPRN != null)
       {
        custNumberNPRN.setValue(pageContext,custNumberDefault);
        pageContext.writeDiagnostics(METHOD_NAME, "anirban8oct: custNumberNPRN value is: "+custNumberNPRN.getValue(pageContext), 1);
       }

       OAMessageTextInputBean addressSequenceNPRN = (OAMessageTextInputBean)netPricerRNtoSetValue.findChildRecursive("AddressSequence");
       if(addressSequenceNPRN != null)
       {
        addressSequenceNPRN.setValue(pageContext,addressSeqDefault);
        pageContext.writeDiagnostics(METHOD_NAME, "anirban8oct: addressSequenceNPRN value is: "+addressSequenceNPRN.getValue(pageContext), 1);
       }
      }

      //Logic for defaulting customer number and address sequence ENDS here.
     
//ANIRBAN ADDED CODE FOR ADDING THE NETPRICER REGION AS A SUBTAB ON 09 OCT'09 : ENDS



//ANIRBAN ADDED CODE FOR MAKING THE PAGE AS READ ONLY: STARTS ON 10 DEC'07

   String custAccMode = this.processAccessPrivilege(pageContext,
                                                     ASNUIConstants.CUSTOMER_ENTITY,
                                                     partyId);

   pageContext.writeDiagnostics(METHOD_NAME, "anirban12dec: printing value of custAccMode: "+custAccMode, 1);

   //custAccMode = "101lOl11O";

   if ("101lOl11O".equals(custAccMode))
   {
/*----------------------------------BASIC INFORMATION-------------------------------------------------*/
    OADefaultStackLayoutBean ASNOrgUpdateHdrRN = (OADefaultStackLayoutBean) webBean.findChildRecursive("ASNOrgUpdateHdrRN");
    if(ASNOrgUpdateHdrRN != null)
    {
     OADescriptiveFlexBean OrgProfileFlex = (OADescriptiveFlexBean)ASNOrgUpdateHdrRN.findChildRecursive("OrgProfileFlex");
     if(OrgProfileFlex != null)
     {
       OrgProfileFlex.setReadOnly(true);
       pageContext.writeDiagnostics(METHOD_NAME, "anirban7dec: inside inside code for making readOnly", 1);
     }

     OAMessageChoiceBean party_status = (OAMessageChoiceBean)ASNOrgUpdateHdrRN.findChildRecursive("party_status");
     if(party_status != null)
     {
       party_status.setReadOnly(true);
     }

     OAMessageTextInputBean organization_name = (OAMessageTextInputBean)ASNOrgUpdateHdrRN.findChildRecursive("organization_name");
     if(organization_name != null)
     {
       organization_name.setReadOnly(true);
     }

     OAMessageTextInputBean pronunciation = (OAMessageTextInputBean)ASNOrgUpdateHdrRN.findChildRecursive("pronunciation");
     if(pronunciation != null)
     {
       pronunciation.setReadOnly(true);
     }

     OAMessageTextInputBean alias = (OAMessageTextInputBean)ASNOrgUpdateHdrRN.findChildRecursive("alias");
     if(alias != null)
     {
       alias.setReadOnly(true);
     }

     OAMessageTextInputBean alias2 = (OAMessageTextInputBean)ASNOrgUpdateHdrRN.findChildRecursive("alias2");
     if(alias2 != null)
     {
       alias2.setReadOnly(true);
     }

     OAMessageTextInputBean alias3 = (OAMessageTextInputBean)ASNOrgUpdateHdrRN.findChildRecursive("alias3");
     if(alias3 != null)
     {
       alias3.setReadOnly(true);
     }

     OAMessageTextInputBean alias4 = (OAMessageTextInputBean)ASNOrgUpdateHdrRN.findChildRecursive("alias4");
     if(alias4 != null)
     {
       alias4.setReadOnly(true);
     }

     OAMessageTextInputBean alias5 = (OAMessageTextInputBean)ASNOrgUpdateHdrRN.findChildRecursive("alias5");
     if(alias5 != null)
     {
       alias5.setReadOnly(true);
     }

     OAMessageTextInputBean registry_id = (OAMessageTextInputBean)ASNOrgUpdateHdrRN.findChildRecursive("registry_id");
     if(registry_id != null)
     {
       registry_id.setReadOnly(true);
     }
    }
/*----------------------------------BASIC INFORMATION-------------------------------------------------*/



/*----------------------------------PROFILE-----------------------------------------------------------*/

    OADefaultDoubleColumnBean ASNOrgPrflInfoRN = (OADefaultDoubleColumnBean)webBean.findChildRecursive("ASNOrgPrflInfoRN");

    OADefaultDoubleColumnBean ASNOrgEmplInfoRN = (OADefaultDoubleColumnBean)webBean.findChildRecursive("ASNOrgEmplInfoRN");

    OADefaultDoubleColumnBean ASNOrgFinlInfoRN = (OADefaultDoubleColumnBean)webBean.findChildRecursive("ASNOrgFinlInfoRN");

    if(ASNOrgPrflInfoRN != null)
    {
      OAMessageTextInputBean duns_number = (OAMessageTextInputBean)ASNOrgPrflInfoRN.findChildRecursive("duns_number");
      if(duns_number != null)
      {
       duns_number.setReadOnly(true);
      }

      OAMessageLovInputBean legal_structure = (OAMessageLovInputBean)ASNOrgPrflInfoRN.findChildRecursive("legal_structure");
      if(legal_structure != null)
      {
       legal_structure.setReadOnly(true);
      }

      OAMessageTextInputBean ceo_name = (OAMessageTextInputBean)ASNOrgPrflInfoRN.findChildRecursive("ceo_name");
      if(ceo_name != null)
      {
       ceo_name.setReadOnly(true);
      }

      OAMessageTextInputBean ceo_title = (OAMessageTextInputBean)ASNOrgPrflInfoRN.findChildRecursive("ceo_title");
      if(ceo_title != null)
      {
       ceo_title.setReadOnly(true);
      }

      OAMessageTextInputBean principal_name = (OAMessageTextInputBean)ASNOrgPrflInfoRN.findChildRecursive("principal_name");
      if(principal_name != null)
      {
       principal_name.setReadOnly(true);
      }

      OAMessageTextInputBean principal_title = (OAMessageTextInputBean)ASNOrgPrflInfoRN.findChildRecursive("principal_title");
      if(principal_title != null)
      {
       principal_title.setReadOnly(true);
      }

      OAMessageTextInputBean control_year = (OAMessageTextInputBean)ASNOrgPrflInfoRN.findChildRecursive("control_year");
      if(control_year != null)
      {
       control_year.setReadOnly(true);
      }

      OAMessageTextInputBean incorporation_year = (OAMessageTextInputBean)ASNOrgPrflInfoRN.findChildRecursive("incorporation_year");
      if(incorporation_year != null)
      {
       incorporation_year.setReadOnly(true);
      }

      OAMessageTextInputBean mission_statement = (OAMessageTextInputBean)ASNOrgPrflInfoRN.findChildRecursive("mission_statement");
      if(mission_statement != null)
      {
       mission_statement.setReadOnly(true);
      }

      OAMessageTextInputBean year_established = (OAMessageTextInputBean)ASNOrgPrflInfoRN.findChildRecursive("year_established");
      if(year_established != null)
      {
       year_established.setReadOnly(true);
      }
    }

    if(ASNOrgEmplInfoRN != null)
    {
      OAMessageChoiceBean totalEmpEstInd=  (OAMessageChoiceBean)ASNOrgEmplInfoRN.findChildRecursive("totalEmpEstInd");
      if(totalEmpEstInd != null)
      {
        totalEmpEstInd.setReadOnly(true);
      }

      OAMessageChoiceBean empAtPrimaryAdrEstInd =  (OAMessageChoiceBean)ASNOrgEmplInfoRN.findChildRecursive("empAtPrimaryAdrEstInd");
      if(empAtPrimaryAdrEstInd != null)
      {
        empAtPrimaryAdrEstInd.setReadOnly(true);
      }

      OAMessageTextInputBean employeesTotal = (OAMessageTextInputBean)ASNOrgEmplInfoRN.findChildRecursive("employeesTotal");
      if(employeesTotal != null)
      {
       employeesTotal.setReadOnly(true);
      }

      OAMessageTextInputBean EmpAtPrimaryAdr = (OAMessageTextInputBean)ASNOrgEmplInfoRN.findChildRecursive("EmpAtPrimaryAdr");
      if(EmpAtPrimaryAdr != null)
      {
       EmpAtPrimaryAdr.setReadOnly(true);
      }
    }

    if(ASNOrgFinlInfoRN != null)
    {
      OAMessageTextInputBean JgzzFiscalCode = (OAMessageTextInputBean)ASNOrgFinlInfoRN.findChildRecursive("JgzzFiscalCode");
      if(JgzzFiscalCode != null)
      {
       JgzzFiscalCode.setReadOnly(true);
      }
      OAMessageTextInputBean AnalysisFy = (OAMessageTextInputBean)ASNOrgFinlInfoRN.findChildRecursive("AnalysisFy");
      if(AnalysisFy != null)
      {
       AnalysisFy.setReadOnly(true);
      }

      OAMessageTextInputBean TaxReference = (OAMessageTextInputBean)ASNOrgFinlInfoRN.findChildRecursive("TaxReference");
      if(TaxReference != null)
      {
       TaxReference.setReadOnly(true);
      }

      OAMessageCheckBoxBean GsaIndicatorFlag = (OAMessageCheckBoxBean)ASNOrgFinlInfoRN.findChildRecursive("GsaIndicatorFlag");
      if(GsaIndicatorFlag != null)
      {
       GsaIndicatorFlag.setReadOnly(true);
      }
      
      OAMessageChoiceBean FiscalYearendMonth =  (OAMessageChoiceBean)ASNOrgFinlInfoRN.findChildRecursive("FiscalYearendMonth");
      if(FiscalYearendMonth != null)
      {
        FiscalYearendMonth.setReadOnly(true);
      }

      OAMessageTextInputBean CurrFyPotentialRevenue = (OAMessageTextInputBean)ASNOrgFinlInfoRN.findChildRecursive("CurrFyPotentialRevenue");
      if(CurrFyPotentialRevenue != null)
      {
       CurrFyPotentialRevenue.setReadOnly(true);
      }

      OAMessageTextInputBean NextFyPotentialRevenue = (OAMessageTextInputBean)ASNOrgFinlInfoRN.findChildRecursive("NextFyPotentialRevenue");
      if(NextFyPotentialRevenue != null)
      {
       NextFyPotentialRevenue.setReadOnly(true);
      }

      OAMessageLovInputBean PrefFunctionalCurrencyDesc = (OAMessageLovInputBean)ASNOrgFinlInfoRN.findChildRecursive("PrefFunctionalCurrencyDesc");
      if(PrefFunctionalCurrencyDesc != null)
      {
       PrefFunctionalCurrencyDesc.setReadOnly(true);
      }
    }


/*----------------------------------PROFILE-----------------------------------------------------------*/



/*----------------------------------NOTES&TASKS-------------------------------------------------------*/

    OAStackLayoutBean ASNTasksRN = (OAStackLayoutBean)webBean.findChildRecursive("ASNTasksRN");
    if(ASNTasksRN != null)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "anirban7dec: inside task code for making readOnly", 1);
      OASwitcherBean CacSmrUpdSwitch = (OASwitcherBean)ASNTasksRN.findChildRecursive("CacSmrUpdSwitch");
      if(CacSmrUpdSwitch != null)
      {
       CacSmrUpdSwitch.setRendered(false);
       pageContext.writeDiagnostics(METHOD_NAME, "anirban7dec: inside inside task code for making readOnly", 1);
      }

      OALinkBean CacSmrTaskDelLink = (OALinkBean)ASNTasksRN.findChildRecursive("CacSmrTaskDelLink");
      if(CacSmrTaskDelLink != null)
      {
       CacSmrTaskDelLink.setRendered(false);
       pageContext.writeDiagnostics(METHOD_NAME, "anirban7dec: inside inside task code for making ReadOnly", 1);
      }

      pageContext.putTransactionValue("cacTaskTableRO", "Y");
    }

    //Attachment region read-only
      ASNUIUtil.attchSetUp(pageContext
                    ,webBean
                    ,false
                    ,"ASNOrgAttchTable"//This is the attachment table item
                    ,"ASNOrgAttchContextHolderRN"//This is the stack region that holds the context information
                    ,"ASNOrgAttchContextRN");//this is the messageComponentLayout region that holds actual context beans
        OAAttachmentTableBean ASNOrgAttchTable = (OAAttachmentTableBean)webBean.findIndexedChildRecursive("ASNOrgAttchTable");
        if (ASNOrgAttchTable != null)
        {
          ASNOrgAttchTable.setDocumentCatalogEnabled(false);
          ASNOrgAttchTable.setUpdateable(false);
        }

/*----------------------------------NOTES&TASKS-------------------------------------------------------*/



/*----------------------------------CONTACTS----------------------------------------------------------*/

    OAStackLayoutBean ASNCtctInfoRN1 = (OAStackLayoutBean)webBean.findChildRecursive("ASNCtctInfoRN");
    if(ASNCtctInfoRN1 != null)
    {
     OARowLayoutBean ContactTableRL = (OARowLayoutBean)ASNCtctInfoRN1.findChildRecursive("ContactTableRL");
     if(ContactTableRL != null)
     {
       //Anirban starts fix for defect#14801
       ContactTableRL.setRendered(true);//changed from false to true for defect#14801 fix.
       //Anirban ends fix for defect#14801
     }

      OASwitcherBean updateSwitcher = (OASwitcherBean)ASNCtctInfoRN1.findChildRecursive("update_switcher");
      if(updateSwitcher != null)
      {
        updateSwitcher.setRendered(false);
      }

      OASwitcherBean removeSwitcher = (OASwitcherBean)ASNCtctInfoRN1.findChildRecursive("remove_switcher");
      if(removeSwitcher != null)
      {
       removeSwitcher.setRendered(false);
      }
    }

/*----------------------------------CONTACTS----------------------------------------------------------*/



/*----------------------------------ADDRESS BOOK------------------------------------------------------*/

    OAHeaderBean ASNPhnViewRN = (OAHeaderBean)webBean.findChildRecursive("ASNPhnViewRN");
    if(ASNPhnViewRN != null)
    {
      OARowLayoutBean tableActionsPhoneRL = (OARowLayoutBean)ASNPhnViewRN.findChildRecursive("tableActionsPhoneRL");
      if(tableActionsPhoneRL != null)
      {
       tableActionsPhoneRL.setRendered(false);
      }

      OASwitcherBean update_switcher_ASNPhnViewRN = (OASwitcherBean)ASNPhnViewRN.findChildRecursive("UpdateSwitcher");
      if(update_switcher_ASNPhnViewRN != null)
      {
        update_switcher_ASNPhnViewRN.setRendered(false);
      }

      OASwitcherBean remove_switcher_ASNPhnViewRN = (OASwitcherBean)ASNPhnViewRN.findChildRecursive("DeleteSwitcher");
      if(remove_switcher_ASNPhnViewRN != null)
      {
       remove_switcher_ASNPhnViewRN.setRendered(false);
       pageContext.writeDiagnostics(METHOD_NAME, "anirban10dec: inside inside phone code for making ReadOnly: delete switcher", 1);
      }
      pageContext.putTransactionValue("ReadOnlyModeDefect", "ReadOnlyMode");
    }




    OAHeaderBean ASNEmlViewRN = (OAHeaderBean)webBean.findChildRecursive("ASNEmlViewRN");
    if(ASNEmlViewRN != null)
    {
      OAFlowLayoutBean tableActionEmailFL = (OAFlowLayoutBean)ASNEmlViewRN.findChildRecursive("tableActionEmailFL");
      if(tableActionEmailFL != null)
      {
       tableActionEmailFL.setRendered(false);
      }

      OASwitcherBean updateSwitcher = (OASwitcherBean)ASNEmlViewRN.findChildRecursive("UpdateSwitcher");
      if(updateSwitcher != null)
      {
        updateSwitcher.setRendered(false);
      }

      OASwitcherBean removeSwitcher = (OASwitcherBean)ASNEmlViewRN.findChildRecursive("DeleteSwitcher");
      if(removeSwitcher != null)
      {
       removeSwitcher.setRendered(false);
      }
    }




    OAHeaderBean ASNWebsiteRN = (OAHeaderBean)webBean.findChildRecursive("ASNWebsiteRN");
    if(ASNWebsiteRN != null)
    {
      OAFlowLayoutBean tableActionUrlFL = (OAFlowLayoutBean)ASNWebsiteRN.findChildRecursive("tableActionUrlFL");
      if(tableActionUrlFL != null)
      {
       tableActionUrlFL.setRendered(false);
      }

      OASwitcherBean updateSwitcher_ASNWebsiteRN = (OASwitcherBean)ASNWebsiteRN.findChildRecursive("UpdateSwitcher");
      if(updateSwitcher_ASNWebsiteRN != null)
      {
        updateSwitcher_ASNWebsiteRN.setRendered(false);
      }

      OASwitcherBean removeSwitcher_ASNWebsiteRN = (OASwitcherBean)ASNWebsiteRN.findChildRecursive("DeleteSwitcher");
      if(removeSwitcher_ASNWebsiteRN != null)
      {
       removeSwitcher_ASNWebsiteRN.setRendered(false);
      }
    }

/*----------------------------------ADDRESS BOOK------------------------------------------------------*/



/*----------------------------------BUSINESS RELATIONSHIP---------------------------------------------*/

    OAButtonBean viewHierBtn = (OAButtonBean)webBean.findChildRecursive("viewHierBtn");
    OAButtonBean viewRelaBtn = (OAButtonBean)webBean.findChildRecursive("viewRelaBtn");
    if(viewHierBtn != null)
    {
     viewHierBtn.setRendered(false);
    }
    if(viewRelaBtn != null)
    {
     viewRelaBtn.setRendered(false);
    }

    OAStackLayoutBean ASNRelInfoRN = (OAStackLayoutBean)webBean.findChildRecursive("ASNRelInfoRN");
    if(ASNRelInfoRN != null)
    {
     OARowLayoutBean ContactTableRL_ASNRelInfoRN = (OARowLayoutBean)ASNRelInfoRN.findChildRecursive("ContactTableRL");
      if(ContactTableRL_ASNRelInfoRN != null)
      {
       ContactTableRL_ASNRelInfoRN.setRendered(false);
      }

      OASwitcherBean updateSwitcher_ASNRelInfoRN = (OASwitcherBean)ASNRelInfoRN.findChildRecursive("update_switcher");
      if(updateSwitcher_ASNRelInfoRN != null)
      {
        updateSwitcher_ASNRelInfoRN.setRendered(false);
      }

      OASwitcherBean removeSwitcher_ASNRelInfoRN = (OASwitcherBean)ASNRelInfoRN.findChildRecursive("remove_switcher");
      if(removeSwitcher_ASNRelInfoRN != null)
      {
       removeSwitcher_ASNRelInfoRN.setRendered(false);
      }
    }

/*----------------------------------BUSINESS RELATIONSHIP---------------------------------------------*/



/*----------------------------------CLASSIFICATIONS---------------------------------------------------*/

    OAHeaderBean ASNClsInfoRN = (OAHeaderBean)webBean.findChildRecursive("ASNClsInfoRN");
    if(ASNClsInfoRN != null)
    {
     OATableLayoutBean region1 = (OATableLayoutBean)ASNClsInfoRN.findChildRecursive("region1");

     if(region1 != null)
     {
       OAFlowLayoutBean tableButtons_ASNClsInfoRN = (OAFlowLayoutBean)region1.findChildRecursive("tableButtons");
       if(tableButtons_ASNClsInfoRN != null)
       {
        tableButtons_ASNClsInfoRN.setRendered(false);
       }

       OASwitcherBean updateSwitcher_ASNClsInfoRN = (OASwitcherBean)region1.findChildRecursive("Update");
       if(updateSwitcher_ASNClsInfoRN != null)
       {
        updateSwitcher_ASNClsInfoRN.setRendered(false);
       }

       OASwitcherBean removeSwitcher_ASNClsInfoRN = (OASwitcherBean)region1.findChildRecursive("Remove");
       if(removeSwitcher_ASNClsInfoRN != null)
       {
        removeSwitcher_ASNClsInfoRN.setRendered(false);
       }
     }
    }


    OAHeaderBean ASNIndClsInfoRN = (OAHeaderBean)webBean.findChildRecursive("ASNIndClsInfoRN");
    if(ASNIndClsInfoRN != null)
    {
     OATableLayoutBean region11 = (OATableLayoutBean)ASNIndClsInfoRN.findChildRecursive("region1");

     if(region11 != null)
     {
       OAFlowLayoutBean tableButtons_ASNIndClsInfoRN = (OAFlowLayoutBean)region11.findChildRecursive("tableButtons");
       if(tableButtons_ASNIndClsInfoRN != null)
       {
        tableButtons_ASNIndClsInfoRN.setRendered(false);
       }

       OASwitcherBean updateSwitcher_ASNIndClsInfoRN = (OASwitcherBean)region11.findChildRecursive("IndUpdate");
       if(updateSwitcher_ASNIndClsInfoRN != null)
       {
        updateSwitcher_ASNIndClsInfoRN.setRendered(false);
       }

       OASwitcherBean removeSwitcher_ASNIndClsInfoRN = (OASwitcherBean)region11.findChildRecursive("IndRemove");
       if(removeSwitcher_ASNIndClsInfoRN != null)
       {
        removeSwitcher_ASNIndClsInfoRN.setRendered(false);
       }
     }
    }

/*----------------------------------CLASSIFICATIONS---------------------------------------------------*/



/*----------------------------------SALES TEAM--------------------------------------------------------*/

//NO CODE CHANGES REQUIRED.

/*----------------------------------SALES TEAM--------------------------------------------------------*/



/*----------------------------------ACCOUNT SETUP----------------------------------------------------*/

    OAStackLayoutBean AccountSetupRN = (OAStackLayoutBean)webBean.findChildRecursive("AccountSetupRN");
    if(AccountSetupRN != null)
    {
     OAFlowLayoutBean ButtonFlow = (OAFlowLayoutBean)AccountSetupRN.findChildRecursive("ButtonFlow");
     OAFlowLayoutBean ContractsButtonFlow = (OAFlowLayoutBean)AccountSetupRN.findChildRecursive("ContractsButtonFlow");
     OAFlowLayoutBean DocumentsButtonFlow = (OAFlowLayoutBean)AccountSetupRN.findChildRecursive("DocumentsButtonFlow");
     if(ButtonFlow != null)
     {
      ButtonFlow.setRendered(false);
     }
     if(ContractsButtonFlow != null)
     {
      ContractsButtonFlow.setRendered(false);
     }
     if(DocumentsButtonFlow != null)
     {
      DocumentsButtonFlow.setRendered(false);
     }
    }

    if(AccountSetupRN != null)
    {
     OAMessageCheckBoxBean DisplayPrices = (OAMessageCheckBoxBean)AccountSetupRN.findChildRecursive("DisplayPrices");
     DisplayPrices.setReadOnly(true);

     OAMessageCheckBoxBean FreightCharge = (OAMessageCheckBoxBean)AccountSetupRN.findChildRecursive("FreightCharge");
     FreightCharge.setReadOnly(true);

     OAMessageCheckBoxBean FaxOrder = (OAMessageCheckBoxBean)AccountSetupRN.findChildRecursive("FaxOrder");
     FaxOrder.setReadOnly(true);

     OAMessageCheckBoxBean AFax = (OAMessageCheckBoxBean)AccountSetupRN.findChildRecursive("AFax");
     AFax.setReadOnly(true);

     OAMessageCheckBoxBean Substitutions = (OAMessageCheckBoxBean)AccountSetupRN.findChildRecursive("Substitutions");
     Substitutions.setReadOnly(true);

     OAMessageCheckBoxBean BackOrders = (OAMessageCheckBoxBean)AccountSetupRN.findChildRecursive("BackOrders");
     BackOrders.setReadOnly(true);

     OAMessageCheckBoxBean DisplayBackOrder = (OAMessageCheckBoxBean)AccountSetupRN.findChildRecursive("DisplayBackOrder");
     DisplayBackOrder.setReadOnly(true);

     OAMessageCheckBoxBean PrintInvoice = (OAMessageCheckBoxBean)AccountSetupRN.findChildRecursive("PrintInvoice");
     PrintInvoice.setReadOnly(true);

     OAMessageCheckBoxBean DisplayPurchaseOrder = (OAMessageCheckBoxBean)AccountSetupRN.findChildRecursive("DisplayPurchaseOrder");
     DisplayPurchaseOrder.setReadOnly(true);

     OAMessageCheckBoxBean DisplayPaymentMethod = (OAMessageCheckBoxBean)AccountSetupRN.findChildRecursive("DisplayPaymentMethod");
     DisplayPaymentMethod.setReadOnly(true);



//QC-9233 - Type cast error
//   OAMessageTextInputBean OffContractCode = (OAMessageTextInputBean)AccountSetupRN.findChildRecursive("OffContractCode");
     OAMessageChoiceBean  OffContractCode = (OAMessageChoiceBean)AccountSetupRN.findChildRecursive("OffContractCode");
     OffContractCode.setReadOnly(true);

     OAMessageTextInputBean OffContract = (OAMessageTextInputBean)AccountSetupRN.findChildRecursive("OffContract");
     OffContract.setReadOnly(true);

//QC-9233 - Type cast error
//   OAMessageTextInputBean OffWholesaleCode = (OAMessageTextInputBean)AccountSetupRN.findChildRecursive("OffWholesaleCode");
     OAMessageChoiceBean OffWholesaleCode = (OAMessageChoiceBean)AccountSetupRN.findChildRecursive("OffWholesaleCode");
     OffWholesaleCode.setReadOnly(true);

     OAMessageTextInputBean WholeSale = (OAMessageTextInputBean)AccountSetupRN.findChildRecursive("WholeSale");
     WholeSale.setReadOnly(true);

     OAMessageTextInputBean XREF = (OAMessageTextInputBean)AccountSetupRN.findChildRecursive("XREF");
     XREF.setReadOnly(true);

     OAMessageTextInputBean GPFloor = (OAMessageTextInputBean)AccountSetupRN.findChildRecursive("GPFloor");
     GPFloor.setReadOnly(true);

     OAMessageTextInputBean ParentID = (OAMessageTextInputBean)AccountSetupRN.findChildRecursive("ParentID");
     ParentID.setReadOnly(true);

     OAMessageTextInputBean Comment1 = (OAMessageTextInputBean)AccountSetupRN.findChildRecursive("Comment");
     Comment1.setReadOnly(true);

     OAMessageTextInputBean ContractNumber = (OAMessageTextInputBean)AccountSetupRN.findChildRecursive("ContractNumber");
     ContractNumber.setReadOnly(true);

     OAMessageTextInputBean POHeader = (OAMessageTextInputBean)AccountSetupRN.findChildRecursive("POHeader");
     POHeader.setReadOnly(true);

     OAMessageTextInputBean ReleaseHeader = (OAMessageTextInputBean)AccountSetupRN.findChildRecursive("ReleaseHeader");
     ReleaseHeader.setReadOnly(true);

     OAMessageTextInputBean DepartmentHeader = (OAMessageTextInputBean)AccountSetupRN.findChildRecursive("DepartmentHeader");
     DepartmentHeader.setReadOnly(true);

     OAMessageTextInputBean DesktopHeader = (OAMessageTextInputBean)AccountSetupRN.findChildRecursive("DesktopHeader");
     DesktopHeader.setReadOnly(true);

     OAMessageTextInputBean ProcurementCard = (OAMessageTextInputBean)AccountSetupRN.findChildRecursive("ProcurementCard");
     ProcurementCard.setReadOnly(true);

     OAMessageTextInputBean ContractDescription = (OAMessageTextInputBean)AccountSetupRN.findChildRecursive("ContractDescription");
     ContractDescription.setReadOnly(true);





     OAMessageChoiceBean BillToSite =  (OAMessageChoiceBean)AccountSetupRN.findChildRecursive("BillToSite");
     BillToSite.setReadOnly(true);

     OAMessageChoiceBean ShipToSite =  (OAMessageChoiceBean)AccountSetupRN.findChildRecursive("ShipToSite");
     ShipToSite.setReadOnly(true);

     OAMessageChoiceBean StdContractTemplate =  (OAMessageChoiceBean)AccountSetupRN.findChildRecursive("StdContractTemplate");
     StdContractTemplate.setReadOnly(true);

     OAMessageChoiceBean PricePlan =  (OAMessageChoiceBean)AccountSetupRN.findChildRecursive("PricePlan");
     PricePlan.setReadOnly(true);

     OAMessageChoiceBean Priority =  (OAMessageChoiceBean)AccountSetupRN.findChildRecursive("Priority");
     Priority.setReadOnly(true);

     OAMessageChoiceBean POValidated =  (OAMessageChoiceBean)AccountSetupRN.findChildRecursive("POValidated");
     POValidated.setReadOnly(true);

     OAMessageChoiceBean ReleaseValidated =  (OAMessageChoiceBean)AccountSetupRN.findChildRecursive("ReleaseValidated");
     ReleaseValidated.setReadOnly(true);

     OAMessageChoiceBean DepartmentValidated =  (OAMessageChoiceBean)AccountSetupRN.findChildRecursive("DepartmentValidated");
     DepartmentValidated.setReadOnly(true);

     OAMessageChoiceBean DesktopValidated =  (OAMessageChoiceBean)AccountSetupRN.findChildRecursive("DesktopValidated");
     DesktopValidated.setReadOnly(true);

     OAMessageChoiceBean PaymentMethod =  (OAMessageChoiceBean)AccountSetupRN.findChildRecursive("PaymentMethod");
     PaymentMethod.setReadOnly(true);

    //Anirban: Added for Release 1.2 - Creation of AP and Sales contact

     pageContext.putSessionValue("makeAccountSetupFormReadOnly", custAccMode);

     //OAMessageChoiceBean APContact =  (OAMessageChoiceBean)AccountSetupRN.findChildRecursive("APContact");
     //APContact.setReadOnly(true);     

    //Anirban: Added for Release 1.2 - Creation of AP and Sales contact

     OAMessageChoiceBean DocumentName1 =  (OAMessageChoiceBean)AccountSetupRN.findChildRecursive("DocumentName");
     DocumentName1.setReadOnly(true);

     OAMessageChoiceBean Frequency =  (OAMessageChoiceBean)AccountSetupRN.findChildRecursive("Frequency");
     Frequency.setReadOnly(true);
    }


    OATableBean AccReqTb =  (OATableBean)AccountSetupRN.findChildRecursive("AccReqTb");
    AccReqTb.setSelectionDisplayed(false);

    OATableBean ContractsTable =  (OATableBean)AccountSetupRN.findChildRecursive("ContractsTable");
    ContractsTable.setSelectionDisplayed(false);

    OATableBean DocumentTable =  (OATableBean)AccountSetupRN.findChildRecursive("DocumentTable");
    DocumentTable.setSelectionDisplayed(false);

/*----------------------------------ACCOUNT SETUP----------------------------------------------------*/



/*----------------------------------VIEW ACCOUNT DETAILS----------------------------------------------*/

//NO CODE CHANGES REQUIRED.

/*----------------------------------VIEW ACCOUNT DETAILS----------------------------------------------*/

//ANIRBAN ADDED CODE FOR MAKING THE PAGE AS READ ONLY: ENDS ON 12 DEC'07
   }

   if(pageContext.getParameter("AccountRequestId") != null)
   {
      tabBean.setAttributeValue(MODE_ATTR, SUBTAB_FORM_SUBMISSION_MODE);
      tabBean.setSelectedIndex(pageContext,7);
      //pageContext.putParameter("ASNReqFrmCustId","pid");
    }

    if (pageContext.getParameter("pagerequestId") !=null)
    {
      tabBean.setAttributeValue(MODE_ATTR, SUBTAB_FORM_SUBMISSION_MODE);
      tabBean.setSelectedIndex(pageContext,8);
    }

      // ******* Custom code ends here

    }

    if (isProcLogEnabled)
    {
    pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }

  }

//  Starting Changes made for Defect 6262 by Anitha
  public boolean isCustomer(String partyid, OAApplicationModule am)
  {
    int actEx = 0;
    String actexist = "SELECT count(1) CNT FROM hz_cust_accounts_all WHERE party_id = " + partyid;
    try
        {
           OracleCallableStatement actCall = (OracleCallableStatement)am.getOADBTransaction().createCallableStatement(actexist, -1);
           ResultSet actRS = (OracleResultSet) actCall.executeQuery();

           while(actRS.next())
           {
              actEx = actRS.getInt("CNT");
           }
           actRS.close();
           actCall.close();
        }
        catch(Exception e)
        {
            return false;
        };
    if (actEx > 0)
    {
       return true;
    }
    else
        return false;
  }
//  Ending Changes made for Defect 6262 by Anitha

  /**
   * Procedure to handle form submissions for form elements in
   * AK region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    final String METHOD_NAME = "xxcrm.asn.common.customer.webui.ODOrgUpdateCO.processFormRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    if (isProcLogEnabled)
    {
    pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processFormRequest(pageContext, webBean);
    pageContext.putParameter("ASNReqFrmFuncName","ASN_ORGUPDATEPG");

    /********  Get the Application module   *********/
    OAApplicationModule am = (OAApplicationModule) pageContext.getApplicationModule(webBean);

    /********  Get the page action event that has caused the submit  *********/
    String pageEvent = pageContext.getParameter("ASNReqPgAct");
    String event = pageContext.getParameter(EVENT_PARAM);

    String partyId = (String)pageContext.getParameter("ASNReqFrmCustId");
    String partyName = (String)pageContext.getTransactionValue("ASNTxnCustName");

    //partyName = pageContext.getParameter("organization_name");
    partyName = pageContext.getParameter("organization_name")==null?partyName:pageContext.getParameter("organization_name");
    MessageToken[] tokens = { new MessageToken("PARTYNAME", partyName) };
    String pageTitle = pageContext.getMessage("ASN", "ASN_TCA_UPDT_CUST_TITLE", tokens);

    HashMap conditions = new HashMap();
    conditions.put(ASNUIConstants.BC_CURRENT_LINK, ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
    conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT,pageTitle);

    HashMap params = new HashMap();
    params.put("ASNReqFrmCustId", partyId);
    params.put("ASNReqFrmCustName", partyName);

    // Custom code Starts here
    OADBTransaction oa = pageContext.getApplicationModule(webBean).getOADBTransaction();
    if ("Y".equals(oa.getProfile("XX_ASN_CUSTOMER_HIERARCHY")))
    {
        String custId = pageContext.getParameter("ASNReqFrmCustId");
        HashMap params1 = new HashMap();
        if("viewHierBtnClicked".equals(pageContext.getParameter("event")))
        {
          String sAsnPartyId = pageContext.getParameter("ASNReqFrmCustId");
          String sAsnPartyName = pageContext.getParameter("ASNReqFrmCustName");
          pageContext.putParameter("HzPuiHierPartyId",sAsnPartyId);
          pageContext.putParameter("HzPuiHierPartyName",sAsnPartyName);
          pageContext.putParameter("HzPuiGoSearch","GO");
          pageContext.forwardImmediately("IMC_NG_HIER_SEARCH",
                                              KEEP_MENU_CONTEXT,
                                             null,
                                             params1,
                                             true,
                                           ADD_BREAD_CRUMB_YES);

        }
    }// Ends


    if (pageContext.getParameter("ASNPageCnclBtn") != null)
    {
        pageContext.putParameter("ASNReqFrmCustId",pageContext.getParameter("ASNReqFrmCustId"));
        this.processTargetURL(pageContext, null, null);         
    }
    else if (pageContext.getParameter("ASNPageApyBtn") != null)
    {
        doCommit(pageContext);
        this.processTargetURL(pageContext, null, null); 
    }
    // ***** Start of Custom code to hande "Go To Site(S)" Button.
    else if (pageContext.getParameter("ODGoToSItesBtn") != null)
    {
      doCommit(pageContext);
      this.modifyCurrentBreadcrumbLink(pageContext, true, pageTitle, false);
      params.put("ASNReqFrmFuncName", "XX_ASN_SITEVIEWPG");
      pageContext.forwardImmediately("XX_ASN_SITEVIEWPG",           // functionName
                                      KEEP_MENU_CONTEXT ,           // menuContext
                                      null,                         // menuName
                                      params,                       // parameters
                                      false,                        // retainAM
                                      ADD_BREAD_CRUMB_YES);         // addBreadCrumb
    }
    // ***** End of custom code.
    //code for handling the address events
    // Begin Mod Raam on 06.15.2006
    else if(pageContext.getParameter("HzPuiSelectButton") != null)
    // When address select button is clicked
    {
      doCommit(pageContext);

      pageContext.putParameter("ASNReqPgAct","SUBFLOW");
      params.put("ASNReqFrmFuncName","ASN_PTYADDRSELPG");
      params.put("ASNReqFrmCreateSite", "Y");

      this.processTargetURL(pageContext, conditions, params);
    }
    else if (pageContext.getParameter("HzPuiCreateButton") != null )
    // When address create button is clicked
    {
      // Save the changes.
      doCommit(pageContext);

      params.put("HzPuiAddressPartyId", partyId);
      params.put("HzPuiAddressEvent", "CREATE");
      // Begin Mod Raam on 02/14/2005
      // Address event is set in pageContext to override the value set in
      // processRequest during back button scenario.
      pageContext.putParameter("HzPuiAddressEvent" , "CREATE");
      // End Mod.
      params.put("ASNReqFrmFuncName", "ASN_CUSTADDRCREATEUPDATEPG");

      // TODO: Conditions are to be handled here.
      // replace the current link text/title from the bread crumb with the specified value
      // the title will not be replaced if the specified value is null/empty
      this.modifyCurrentBreadcrumbLink(pageContext, // pageContext
                                       true,        // replaceCurrentText
                                       pageTitle,   // newText
                                       false);      // resetRetainAMParam

      pageContext.forwardImmediately("ASN_CUSTADDRCREATEUPDATEPG",  // functionName
                                      KEEP_MENU_CONTEXT ,           // menuContext
                                      null,                         // menuName
                                      params,                       // parameters
                                      false,                        // retainAM
                                      ADD_BREAD_CRUMB_YES);         // addBreadCrumb
    }
    else if (pageContext.getParameter("HzPuiAddressViewEvent") != null &&
        "HzAddressUpdate".equals(pageContext.getParameter("HzPuiAddressViewEvent")))
    // When address update icon is clicked
    {
      // Save the changes.
      doCommit(pageContext);

      params.put("HzPuiAddressPartyId", partyId);
      params.put("HzPuiAddressEvent" , "UPDATE");
      // Begin Mod Raam on 02/14/2005
      // Address event is set in pageContext to override the value set in
      // processRequest during back button scenario.
      pageContext.putParameter("HzPuiAddressEvent" , "UPDATE");
      // End Mod.
      params.put("HzPuiAddressLocationId", pageContext.getParameter("HzPuiAddressViewLocationId"));
      params.put("HzPuiAddressPartySiteId", pageContext.getParameter("HzPuiAddressViewPartySiteId"));
      params.put("ASNReqFrmFuncName", "ASN_CUSTADDRCREATEUPDATEPG");

      // replace the current link text/title from the bread crumb with the specified value
      // the title will not be replaced if the specified value is null/empty
      this.modifyCurrentBreadcrumbLink(pageContext, // pageContext
                                       true,        // replaceCurrentText
                                       pageTitle,   // newText
                                       false);      // resetRetainAMParam

      pageContext.forwardImmediately("ASN_CUSTADDRCREATEUPDATEPG",  // functionName
                                      KEEP_MENU_CONTEXT ,           // menuContext
                                      null,                         // menuName
                                      params,                       // parameters
                                      false,                        // retainAM
                                      ADD_BREAD_CRUMB_YES);         // addBreadCrumb
    }
    // End Mod
    //end of code for handling the address events

         //event handling for the phone region
         else if ( pageContext.getParameter("HzPuiPhoneCreateButton") != null )
         {
                 params.put("HzPuiOwnerTableName", "HZ_PARTIES");
                 params.put("HzPuiOwnerTableId", partyId);
                 params.put("HzPuiCntctPointEvent", "CREATE");
                 params.put("HzPuiPhoneLineType", pageContext.getParameter("HzPuiSelectedPhoneLineType") );
           doCommit(pageContext);
           pageContext.putParameter("ASNReqPgAct","SUBFLOW");
           params.put("ASNReqFrmFuncName", "ASN_CUSTPHNCREATEUPDATEPG");
           this.processTargetURL(pageContext,conditions,params);
          }
          else if (pageContext.getParameter("HzPuiCPPhoneTableActionEvent") != null &&
                      "UPDATE".equals( pageContext.getParameter("HzPuiCPPhoneTableActionEvent") ) )
          {
                 params.put("HzPuiOwnerTableName", "HZ_PARTIES");
                 params.put("HzPuiOwnerTableId", partyId);
                 params.put("HzPuiCntctPointEvent", "UPDATE");
                 params.put("HzPuiContactPointId", pageContext.getParameter("HzPuiContactPointPhoneId") );
           doCommit(pageContext);
           pageContext.putParameter("ASNReqPgAct","SUBFLOW");
           params.put("ASNReqFrmFuncName", "ASN_CUSTPHNCREATEUPDATEPG");
           this.processTargetURL(pageContext,conditions,params);
          }
    //end of code for handling events in phone region

    //event handling for the email region
    else if (pageContext.getParameter("HzPuiEmailCreateButton") != null ) {
         params.put("HzPuiOwnerTableName", "HZ_PARTIES");
         params.put("HzPuiOwnerTableId", partyId);
               params.put("HzPuiCntctPointEvent", "CREATE");
         doCommit(pageContext);
         pageContext.putParameter("ASNReqPgAct","SUBFLOW");
         params.put("ASNReqFrmFuncName", "ASN_CUSTEMLCREATEUPDATEPG");
         this.processTargetURL(pageContext,conditions,params);
    }
    else if (pageContext.getParameter("HzPuiCPEmailTableActionEvent") != null &&
                      "UPDATE".equals( pageContext.getParameter("HzPuiCPEmailTableActionEvent") ) ) {
        params.put("HzPuiOwnerTableName", "HZ_PARTIES");
        params.put("HzPuiOwnerTableId", partyId);
        params.put("HzPuiCntctPointEvent", "UPDATE");
        params.put("HzPuiContactPointId", pageContext.getParameter("HzPuiContactPointEmailId") );
        doCommit(pageContext);
        pageContext.putParameter("ASNReqPgAct","SUBFLOW");
        params.put("ASNReqFrmFuncName", "ASN_CUSTEMLCREATEUPDATEPG");
        this.processTargetURL(pageContext,conditions,params);
    }
    //end of code for handling events in the email region


    //event handling for the website region
    else if (pageContext.getParameter("HzPuiUrlCreateButton") != null ) {
        params.put("HzPuiOwnerTableName", "HZ_PARTIES");
        params.put("HzPuiOwnerTableId", partyId);
        params.put("HzPuiCntctPointEvent", "CREATE");
        doCommit(pageContext);
        pageContext.putParameter("ASNReqPgAct","SUBFLOW");
        params.put("ASNReqFrmFuncName", "ASN_WEBSITECREATEUPDATEPG");
        this.processTargetURL(pageContext,conditions,params);
          }
          else if (pageContext.getParameter("HzPuiCPUrlTableActionEvent") != null &&
                      "UPDATE".equals( pageContext.getParameter("HzPuiCPUrlTableActionEvent") ) ) {
        params.put("HzPuiOwnerTableName", "HZ_PARTIES");
        params.put("HzPuiOwnerTableId", partyId);
        params.put("HzPuiCntctPointEvent", "UPDATE");
        params.put("HzPuiContactPointId", pageContext.getParameter("HzPuiContactPointUrlId") );
        doCommit(pageContext);
        pageContext.putParameter("ASNReqPgAct","SUBFLOW");
        params.put("ASNReqFrmFuncName", "ASN_WEBSITECREATEUPDATEPG");
        this.processTargetURL(pageContext,conditions,params);
    }
    //end of code for handling events in the website region

    //start of code for handling events in the classification region
    else if (pageContext.getParameter("HzPuiClassificationGo") != null)
    {
         params.put("HzPuiClassCategory", pageContext.getParameter("HzPuiAddClassification"));
         doCommit(pageContext);
         pageContext.putParameter("ASNReqPgAct","SUBFLOW");
         params.put("ASNReqFrmFuncName", "ASN_SELECTHIERCLSPG");
         this.processTargetURL(pageContext,conditions,params);
    }
    else if (pageContext.getParameter("HzPuiClassificationViewEvent") != null &&
     "UPDATE".equals(pageContext.getParameter("HzPuiClassificationViewEvent")))
    {
      params.put("HzPuiCodeAssignmentId", pageContext.getParameter("HzPuiCodeAssignmentId"));
      doCommit(pageContext);
      pageContext.putParameter("ASNReqPgAct","SUBFLOW");
      params.put("ASNReqFrmFuncName", "ASN_CLSUPDATEPG");
      this.processTargetURL(pageContext,conditions,params);
    }
    else if (pageContext.getParameter("HzPuiIndClassificationGo") != null)
    {
         params.put("HzPuiClassCategory", pageContext.getParameter("HzPuiAddIndClassification"));
         doCommit(pageContext);
         pageContext.putParameter("ASNReqPgAct","SUBFLOW");
         params.put("ASNReqFrmFuncName", "ASN_SELECTHIERCLSPG");
         this.processTargetURL(pageContext,conditions,params);
    }
    else if (pageContext.getParameter("HzPuiIndClassificationViewEvent") != null &&
     "UPDATE".equals(pageContext.getParameter("HzPuiIndClassificationViewEvent")))
    {
      params.put("HzPuiCodeAssignmentId", pageContext.getParameter("HzPuiIndCodeAssignmentId"));
      doCommit(pageContext);
      pageContext.putParameter("ASNReqPgAct","SUBFLOW");
      params.put("ASNReqFrmFuncName", "ASN_CLSUPDATEPG");
      this.processTargetURL(pageContext,conditions,params);
    }
    //end of code for handling events in the classification region

    //start of code for handling events in the contacts table
    else if (pageContext.getParameter("HzPuiContRelTableCreateEvent") != null)
    {
        doCommit(pageContext);
        pageContext.putParameter("ASNReqPgAct","SUBFLOW");
                    params.put("ASNReqFrmFuncName", "ASN_CTCTCREATEPG");
                    params.put("ASNReqFrmPgMode", "CREATE");
        this.processTargetURL(pageContext,conditions,params);
    }
    else if (pageContext.getParameter("HzPuiContRelTableUpdateEvent") != null &&
      pageContext.getParameter("HzPuiContRelTableUpdateEvent").equals("UPDATE"))
    {
       params.put("ASNReqFrmRelId",  pageContext.getParameter("HzPuiRelationshipId"));
       params.put("ASNReqFrmRelPtyId",  pageContext.getParameter("HzPuiContRelTableRelPartyId"));
       params.put("ASNReqFrmCustId",  partyId);
       params.put("ASNReqFrmCustName",  partyName);
       params.put("ASNReqFrmCtctId",  pageContext.getParameter("HzPuiContRelTableSubjectPartyId"));
       params.put("ASNReqFrmCtctName",  pageContext.getParameter("HzPuiContRelTableSubjectName"));
       doCommit(pageContext);
       this.modifyCurrentBreadcrumbLink(pageContext, true, pageTitle, false);
       params.put("ASNReqFrmFuncName", "ASN_CTCTUPDATEPG");
       pageContext.forwardImmediately("ASN_CTCTUPDATEPG",
                    KEEP_MENU_CONTEXT ,
                    null,
                    params,
                    false,
                    ADD_BREAD_CRUMB_YES);
    }
    else if (pageContext.getParameter("HzPuiContRelTableViewEvent") != null &&
      pageContext.getParameter("HzPuiContRelTableViewEvent").equals("VIEW"))
    {
       params.put("ASNReqFrmRelId",  pageContext.getParameter("HzPuiRelationshipId"));
       params.put("ASNReqFrmRelPtyId",  pageContext.getParameter("HzPuiContRelTableRelPartyId"));
       params.put("ASNReqFrmCustId",  partyId);
       params.put("ASNReqFrmCustName",  partyName);
       params.put("ASNReqFrmCtctId",  pageContext.getParameter("HzPuiContRelTableSubjectPartyId"));
       params.put("ASNReqFrmCtctName",  pageContext.getParameter("HzPuiContRelTableSubjectName"));
       doCommit(pageContext);
       this.modifyCurrentBreadcrumbLink(pageContext, true, pageTitle, false);
       params.put("ASNReqFrmFuncName", "ASN_CTCTVIEWPG");
       pageContext.forwardImmediately("ASN_CTCTVIEWPG",
                    KEEP_MENU_CONTEXT ,
                    null,
                    params,
                    false,
                    ADD_BREAD_CRUMB_YES);
    }
    //end of code for handling events in the contacts table

    //start of code for handling events in the relationship table
    else if (pageContext.getParameter("HzPuiPartyRelTableCreateEvent") != null)
    {
      String role = (String) pageContext.getParameter("HzPuiContTableCreateRelRole");
      params.put("ASNReqPartyType", "ORGANIZATION");
      params.put("HzPuiAddRelRole", role);
      doCommit(pageContext);
      pageContext.putParameter("ASNReqPgAct","SUBFLOW");
      params.put("ASNReqFrmFuncName", "ASN_RELCREATEPG");
      this.processTargetURL(pageContext,conditions,params);
    }
    else if(pageContext.getParameter("HzPuiPartyRelTableUpdateEvent") !=null &&
      pageContext.getParameter("HzPuiPartyRelTableUpdateEvent").equals("UPDATE"))
    {
      String relId = pageContext.getParameter("HzPuiRelationshipId");
      params.put("HzPuiRelationshipId", relId);
      doCommit(pageContext);
      pageContext.putParameter("ASNReqPgAct","SUBFLOW");
      params.put("ASNReqFrmFuncName", "ASN_RELUPDATEPG");
      this.processTargetURL(pageContext,conditions,params);
    }

    else if(pageContext.getParameter("HzPuiPartyRelTableViewEvent") !=null &&
      pageContext.getParameter("HzPuiPartyRelTableViewEvent").equals("VIEW"))
    {
       String subPartyName = pageContext.getParameter("HzPuiPartyRelTableSubjectName");
            String subPartyId   = pageContext.getParameter("HzPuiPartyRelTableSubjectPartyId");
      HashMap subOrgParams = new HashMap();
      subOrgParams.put("ASNReqFrmCustId", subPartyId);
      subOrgParams.put("ASNReqFrmCustName", subPartyName);
      doCommit(pageContext);
      pageContext.putParameter("ASNReqPgAct","CUSTDET");
      this.processTargetURL(pageContext,conditions,subOrgParams);
    }
    //end of code for handling events in the relationship table

    //code for handling events for the sales team
    /*
    else if(pageContext.getParameter("ASNSTAddButton") != null)
    {
      //do commit
      doCommit(pageContext);
      String customerId = pageContext.getParameter("ASNReqFrmCustId");
      String customerName = pageContext.getParameter("ASNReqFrmCustName");
      pageContext.putParameter("ASNReqPgAct","SUBFLOW");
      conditions.put(ASNUIConstants.RETAIN_AM,"Y");
      HashMap urlParams = new HashMap(2);
      urlParams.put("ASNReqFrmFuncName","ASN_CUSTRSCSELPG");
      urlParams.put("ASNReqFrmCustId",customerId);
      pageContext.putTransactionValue("ASNTxnSubFlowVUN","ODCustomerAccessesVO");
      pageContext.putTransactionValue("ASNTxnSubFlowGroupFlag","N");
      this.processTargetURL(pageContext, conditions, urlParams);
    }
    */
    else if("ST_DELETE".equals(pageEvent) )
    {
      String apId = pageContext.getParameter("ASNReqEvtRowId");
      if(apId != null)
      {
        Serializable[] parameters = { apId };
        am.invokeMethod("removeSalesTeamMembers", parameters);

        // Get a handle to the StackLayout of the Sales Team Additional Info region
        //OAStackLayoutBean stAddInfoBean=(OAStackLayoutBean)webBean.findChildRecursive("ASNCustSalesTeamAddInfoRN");
        OAHeaderBean headerRn=(OAHeaderBean)webBean.findIndexedChildRecursive("ASNCustSalesTeamAddInfoHdrRN");
        // Check if the Stacked Layout is Rendered (user may have personalized)
        // Execute further code only if the StackLayout Bean is rendered
        if(headerRn != null && headerRn.isRendered())
        {
          // Use the following Line of Code as workaround for Bug # 3274685
          pageContext.putParameter("ASNReqPgAct", "REFRESH");
          this.processTargetURL(pageContext, null, null);
        }

      }
    }
    else if ("Update".equals(pageContext.getParameter("CacSmrTaskEvent")) ||
             "View".equals(pageContext.getParameter("CacSmrTaskEvent")) ||
            "CallNotesDetail".equals(pageContext.getParameter("CacNotesDtlEvent")))
    {
        doCommit(pageContext);
        this.modifyCurrentBreadcrumbLink(pageContext, true, pageTitle, false);
    }
    //handle the events raised from the business activities region
    else if(pageContext.getParameter("ASNReqExitPage") != null &&
          pageContext.getParameter("ASNReqExitPage").equals("Y"))
    {
                //commit
        doCommit(pageContext);
        //modify the breadcrumb link.
        this.modifyCurrentBreadcrumbLink(pageContext, true, pageTitle, false);

    }
    //PRM Integration
    else if("pvNavigationEvent".equals(event))
    {
      doCommit(pageContext);
      this.modifyCurrentBreadcrumbLink(pageContext, true, pageTitle, false);

      //pageContext.putTransactionValue("PvCustomerId", partyId);
      pageContext.putTransactionValue("prmReturnUrl", getModifiedCurrentUrlForRedirect(pageContext, true));
    }
    //handle the events raised from the customer actions poplist.
    //This will take the user to the Lead Create Page or the Opportunity Create page
    //and will populate this customer information in those pages.
    else if(pageContext.getParameter("ASNPageGoBtn") != null)
    {
       String custActionValue = pageContext.getParameter("ASNPageCustAct");
       if(custActionValue != null)
       {
          doCommit(pageContext);
          this.modifyCurrentBreadcrumbLink(pageContext, true, pageTitle, false);

          pageContext.putParameter("ASNReqSelCustId", partyId);
          pageContext.putParameter("ASNReqSelCustName", partyName);
          if(custActionValue.equals("CREATE_LEAD"))
          {
            pageContext.putParameter("ASNReqPgAct", "CRTELEAD");
            this.processTargetURL(pageContext, null, null);
          }
          else if(custActionValue.equals("CREATE_OPPORTUNITY"))
          {
            pageContext.putParameter("ASNReqPgAct", "CRTEOPPTY");
            this.processTargetURL(pageContext, null, null);
          }
       }
    }

    // Additional Info. Flexfield Code for Sales Team
    // Following Event fires when a Row is selected on the SalesTeam table
    // Check for the Event when the Fire Action happens on the single selection
    else if ("ASNCustSTSelFA".equals(event))
    {

      // Get a handle to the StackLayout of the Sales Team Additional Info region
      //OAStackLayoutBean stBean=(OAStackLayoutBean)webBean.findChildRecursive("ASNCustSalesTeamAddInfoRN");
      OAHeaderBean headerRn=(OAHeaderBean)webBean.findIndexedChildRecursive("ASNCustSalesTeamAddInfoHdrRN");
      // Check if the Stacked Layout is Rendered (user may have personalized)
      // Execute further code only if the StackLayout Bean is rendered
      if(headerRn != null && headerRn.isRendered())
      {
        // Invoke the method in the AM that sets the Row selected as a Current Row in the VO
        am.invokeMethod("refreshSalesteamDetailsRow");
        pageContext.putParameter("ASNReqPgAct", "REFRESH");
        this.processTargetURL(pageContext, null, null);
      }
    }
    //handle the PPR events raised by the attachments
    else if("oaAddAttachment".equals(event) ||
             "oaUpdateAttachment".equals(event) ||
             "oaDeleteAttachment".equals(event) ||
             "oaViewAttachment".equals(event) )
    {
                //commit
        doCommit(pageContext);
        //modify the breadcrumb link.
        this.modifyCurrentBreadcrumbLink(pageContext, true, pageTitle, false);
        //call the common utility method.
                ASNUIUtil.attchEvent(pageContext,webBean);
    }


    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }

  }

}

