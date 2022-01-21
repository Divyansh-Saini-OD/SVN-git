/*===========================================================================+
 |      Copyright (c) 2001 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 |  Aug-03    mkatraga  Created                                              |
 |  12/12/04  rramacha  Bug 3973098 is fixed in this version.                |
 |                      Call to ASN security method checkAccessPriviledge()  |
 |                      is replaced with processAccessPriviledge() and it    |
 |                      fowards to dialogue page on secrity exception.       |
 |  02/14/05  rramacha  Bug 4168549 is fixed in this version.                |
 |                      The first action after a back button navigtion       |
 |                      does an additional processRequest. Because of this   |
 |                      CPUI param HzPuiAddressEvent set in processRequest   |
 |                      takes precedence. Now this parameter is set both in  |
 |                      pageContext and uRL for create/update address events.|
 |  05/11/05  vpalaiya  Removed OALinkBean reference as CPUI changed the item|
 |                      type from link to switcher.                          |
 |  06/15/06  rramacha  Implemented Location Sharing Enhancement.            |
 |  06/27/06  rramacha  Bug 5359131 is fixed. Select button should not be    |
 |                      handled to foward to address selection page. Removed |
 |                      the unwanted code.                                   |
 |  28-AUG-2009 Anirban Chaudhuri   Modified for PRDGB defect#2135 fix.      |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.common.customer.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import java.io.Serializable;
import com.sun.java.util.collections.HashMap;
import od.oracle.apps.xxcrm.asn.common.fwk.webui.ODASNControllerObjectImpl;
import oracle.apps.fnd.framework.webui.beans.layout.OACellFormatBean;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.asn.common.fwk.webui.ASNUIConstants;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.asn.common.webui.ASNUIUtil;
import oracle.apps.fnd.framework.webui.beans.OASwitcherBean;
import oracle.apps.fnd.framework.webui.beans.nav.OAPageButtonBarBean;
import oracle.apps.fnd.framework.webui.beans.layout.OACellFormatBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.nav.OABreadCrumbsBean;
import oracle.apps.fnd.framework.webui.beans.layout.*;
/**
 * Controller for Organization Summary page.
 */
public class ODOrgViewCO extends ODASNControllerObjectImpl
{
  public static final String RCS_ID="$Header: ODOrgViewCO.java 115.27.115200.4 2007/10/08 05:36:02 AshokKumar ship $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "od.oracle.apps.xxcrm.asn.common.customer.webui");

  /**
   * Layout and page setup logic for AK region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    final String METHOD_NAME = "xxcrm.asn.common.customer.webui.ODOrgViewCO.processRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    if (isProcLogEnabled)
    {
    pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processRequest(pageContext, webBean);


    String partyId  = pageContext.getParameter("ASNReqFrmCustId");

    //Anirban: 2135 starts: for skipping view org page and re-directing to the update org page.

    if (true)
    {
     if ( partyId == null )
     {
         OAException e = new OAException("ASN", "ASN_TCA_CUSTPARAM_MISS_ERR");
         pageContext.putDialogMessage(e);
     }

	 HashMap hashmapRedirect = new HashMap();
     hashmapRedirect.put("ASNReqFrmCustId", partyId);
     hashmapRedirect.put("ASNReqFrmFuncName", "ASN_ORGUPDATEPG");
     //pageContext.forwardImmediately("ASN_ORGUPDATEPG", (byte)0, null, hashmapRedirect, false, "S");
	 pageContext.forwardImmediately("ASN_ORGUPDATEPG", (byte)0, null, hashmapRedirect, false, "Y");
	}
	else
	{

	 if ( partyId == null )
     {
         OAException e = new OAException("ASN", "ASN_TCA_CUSTPARAM_MISS_ERR");
         pageContext.putDialogMessage(e);
     }else
     {
      String partyName  = pageContext.getParameter("ASNReqFrmCustName");

 
      //for attachments need to invoke the partyVO.
      OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);
      Serializable[] parameters =  { partyId };
      String queriedPartyName  = (String) am.invokeMethod("getPartyNameFromId", parameters);

      if(partyName == null)
      {
        partyName = queriedPartyName;
      }

      // set up page title
      MessageToken[] tokens = { new MessageToken("PARTYNAME", partyName) };
      String pageTitle = pageContext.getMessage("ASN", "ASN_TCA_VIEW_CUST_TITLE", tokens);
      // Set the page title (which also appears in the breadcrumbs)
      ((OAPageLayoutBean)webBean).setTitle(pageTitle);

      //set up the colspan for the contacts row
      OACellFormatBean contactCell = (OACellFormatBean)webBean.findChildRecursive("ASNOrgCtctsInfoCell");
      if(contactCell != null)
      {
        contactCell.setColumnSpan(2);
      }
      //set up the colspan for the notes row
      OACellFormatBean notesCell = (OACellFormatBean)webBean.findChildRecursive("ASNOrgNotesCell");
      if(notesCell != null)
      {
        notesCell.setColumnSpan(2);
      }
      //set up the colspan for the Business Activities
      OACellFormatBean bussActCell = (OACellFormatBean)webBean.findChildRecursive("ASNOrgBussActCell");
      if(bussActCell != null)
      {
        bussActCell.setColumnSpan(2);
      }
      //set up the colspan for the Products under contract
      OACellFormatBean prodUnderCntrCell = (OACellFormatBean)webBean.findChildRecursive("ASNProdUnderCntrCell");
      if(prodUnderCntrCell != null)
      {
        prodUnderCntrCell.setColumnSpan(2);
      }
      //hide the un-supported items in the tca components that should not be personalized by the user
      //contacts section
      OAHeaderBean asnOrgCtctsInfoRN = (OAHeaderBean) webBean.findChildRecursive("ASNOrgCtctsInfoRN");
      if(asnOrgCtctsInfoRN != null)
      {
        //hide buttons in the contacts view component
        OASubmitButtonBean hzPuiContRelTableMarkDupEventButton=  (OASubmitButtonBean)asnOrgCtctsInfoRN.findChildRecursive("HzPuiContRelTableMarkDupEvent");
        if(hzPuiContRelTableMarkDupEventButton != null)
        {
          hzPuiContRelTableMarkDupEventButton.setRendered(false);
        }

        OASubmitButtonBean hzPuiContRelTableSelPrimaryEventButton=  (OASubmitButtonBean)asnOrgCtctsInfoRN.findChildRecursive("HzPuiContRelTableSelPrimaryEvent");
        if(hzPuiContRelTableSelPrimaryEventButton != null)
        {
          hzPuiContRelTableSelPrimaryEventButton.setRendered(false);
        }

        OASubmitButtonBean hzPuiContRelTableViewHistoryEventButton=  (OASubmitButtonBean)asnOrgCtctsInfoRN.findChildRecursive("HzPuiContRelTableViewHistoryEvent");
        if(hzPuiContRelTableViewHistoryEventButton != null)
        {
          hzPuiContRelTableViewHistoryEventButton.setRendered(false);
        }

        OAMessageChoiceBean HzPuiContTableCreateRelRoleChoice=  (OAMessageChoiceBean)asnOrgCtctsInfoRN.findChildRecursive("HzPuiContTableCreateRelRole");
        if(HzPuiContTableCreateRelRoleChoice != null)
        {
          HzPuiContTableCreateRelRoleChoice.setRendered(false);
        }

        //hide restore icon column in the contacts table.
        // Hide the "restore" bean. Made changes here for backward compatibility as TCA
        // CPUI component changed from Link to Switcher Bean. Original reference to OALinkBean
        // is removed as part of the fix.
        if(asnOrgCtctsInfoRN.findChildRecursive("restore") != null)
        {
          asnOrgCtctsInfoRN.findChildRecursive("restore").setRendered(false);
        }
        // Custom code starts here
        // Code to change the button prompt to Contacts
        OASubmitButtonBean hzPuiContRelTableCreateEventButton =  (OASubmitButtonBean)asnOrgCtctsInfoRN.findChildRecursive("HzPuiContRelTableCreateEvent");
        if(hzPuiContRelTableCreateEventButton != null)
        {
          hzPuiContRelTableCreateEventButton.setText("Create");
        }
        // Custom code ends here
      }
      //end contact section

    //address section
    OAHeaderBean asnOrgAddrRN = (OAHeaderBean) webBean.findChildRecursive("ASNOrgAddrRN");
    if(asnOrgAddrRN != null){
      //hide the buttons in the address view component
      OASubmitButtonBean hzPuiViewInactiveButton=  (OASubmitButtonBean)asnOrgAddrRN.findChildRecursive("HzPuiViewInactiveButton");
      if(hzPuiViewInactiveButton != null){
        hzPuiViewInactiveButton.setRendered(false);
      }
      OASubmitButtonBean hzPuiSelectPrimaryUseButton=  (OASubmitButtonBean)asnOrgAddrRN.findChildRecursive("HzPuiSelectPrimaryUseButton");
      if(hzPuiSelectPrimaryUseButton != null){
        hzPuiSelectPrimaryUseButton.setRendered(false);
      }
    }
    //end address section
    //end of hiding the un-supported items in tca components that should not be personalizable

    //put the parameters required for the header regions
    pageContext.putParameter("HzPuiPartyId", partyId);
    // Diagnostic.println("----------------->ODOrgViewCO->processRequest. partyId = " + partyId);

    //save partyname in the transaction.
    pageContext.putTransactionValue("ASNTxnCustName", partyName);
    // Diagnostic.println("----------------->ODOrgViewCO->processRequest. partyName = " + partyName);

    //put the parameters required for the contact points regions
    pageContext.putParameter("HzPuiContRelTableRelGroupCode", "PARTY_REL_GRP_CONTACTS");
    pageContext.putParameter("HzPuiContRelTableObjectPartyId", partyId);
    pageContext.putParameter("HzPuiContRelTableObjectPartyType", "ORGANIZATION");
    pageContext.putParameter("HzPuiContRelTableMode", "CURRENT");
    //pageContext.putParameter("HzPuiContRelTableRole", "CONTACTORG");

    //put the parameters required for the address region
    pageContext.putParameter("HzPuiAddressEvent", "ViewAddress");
    pageContext.putParameter("HzPuiAddressPartyId", partyId);

    //put the parameters required for the phone region
    pageContext.putParameter("HzPuiCPPhoneTableEvent", "UPDATE");
    pageContext.putParameter("HzPuiOwnerTableName", "HZ_PARTIES");
    pageContext.putParameter("HzPuiOwnerTableId", partyId );

    //put the parameters required for the notes region
    pageContext.putTransactionValue("ASNTxnNoteSourceCode", "PARTY");
    pageContext.putTransactionValue("ASNTxnNoteSourceId", partyId);

    //put the parameters required for the products under contract region
    pageContext.putTransactionValue("ASNTxnCustomerId", partyId);

    //put the code required for the attachments
    //attachment integration here
    ASNUIUtil.attchSetUp(pageContext
                    ,webBean
                    ,true
                    ,"ASNOrgAttchTable"//This is the attachment table item
                    ,"ASNOrgAttchContextHolderRN"//This is the stack region that holds the context information
                    ,"ASNOrgAttchContextRN");//this is the messageComponentLayout region that holds actual context beans

    //set up the colspan for the attachemnts cell
    OACellFormatBean attchCell = (OACellFormatBean)webBean.findChildRecursive("ASNOrgAttchCell");
    if(attchCell != null){
       attchCell.setColumnSpan(2);
    }

    //put the parameters required for the business activities region
    pageContext.putTransactionValue("ASNTxnCustomerId", partyId);
    pageContext.putTransactionValue("ASNTxnBusActLkpTyp", "ASN_BUSINESS_ACTS");
    pageContext.putTransactionValue("ASNTxnAddBrdCrmb", "ADD_BREAD_CRUMB_YES");
    pageContext.putTransactionValue("ASNTxnReturnUrl", getModifiedCurrentUrlForRedirect(pageContext, true));

    //initializes the query for the customer actions poplist
    am.invokeMethod("initCustomerActionsQuery", null);

    // set return to link destination
    ///*comment it out for now*/addReturnLink( pageContext, webBean, "ASNOrgViewRetLnk");



    /*VJ: Added the code for making the page readonly for users with view only access- BEGIN*/
    String custAccMode = this.processAccessPrivilege(pageContext,
                                                     ASNUIConstants.CUSTOMER_ENTITY,
                                                     partyId);
     // AccessCode = 1OllOl11O - UPDATE
      // AccessCode = 101lOl11O - READ
      //custAccMode = "101lOl11O";
      if ("101lOl11O".equals(custAccMode))
      {
        //Disable the page update buttons
        OAPageButtonBarBean PageButtonsRN = (OAPageButtonBarBean) webBean.findChildRecursive("ASNPageButtonRN");       
        if(PageButtonsRN != null)
        {
          OASubmitButtonBean ASNPageFullUpdBtn = (OASubmitButtonBean)PageButtonsRN.findChildRecursive("ASNPageFullUpdBtn");
          if(ASNPageFullUpdBtn != null)
          {
            ASNPageFullUpdBtn.setRendered(true);
          }
          /*
          OASubmitButtonBean ASNPageApyBtn = (OASubmitButtonBean)PageButtonsRN.findChildRecursive("ASNPageApyBtn");
          if(ASNPageApyBtn != null)
          {
            ASNPageApyBtn.setRendered(false);
          }
          */
        }

        //Remove the contact create/update/delete
        OAHeaderBean ASNOrgCtctsInfoRN = (OAHeaderBean) webBean.findChildRecursive("ASNOrgCtctsInfoRN");
        if(ASNOrgCtctsInfoRN != null)
        {
          //hide create button
          OASubmitButtonBean HzPuiContRelTableCreateEvent = (OASubmitButtonBean)ASNOrgCtctsInfoRN.findChildRecursive("HzPuiContRelTableCreateEvent");
          if(HzPuiContRelTableCreateEvent != null)
          {
            HzPuiContRelTableCreateEvent.setRendered(false);
          }

          OASwitcherBean updateSwitcher = (OASwitcherBean)ASNOrgCtctsInfoRN.findChildRecursive("update_switcher");
          if(updateSwitcher != null)
          {
            updateSwitcher.setRendered(false);
          }
          
          OASwitcherBean removeSwitcher = (OASwitcherBean)ASNOrgCtctsInfoRN.findChildRecursive("remove_switcher");
          if(removeSwitcher != null)
          {
            removeSwitcher.setRendered(false);
          }
        }
        //Attachment region read-only
        ASNUIUtil.attchSetUp(pageContext
                    ,webBean
                    ,false
                    ,"ASNOrgAttchTable"//This is the attachment table item
                    ,"ASNOrgAttchContextHolderRN"//This is the stack region that holds the context information
                    ,"ASNOrgAttchContextRN");//this is the messageComponentLayout region that holds actual context beans        
        OAAttachmentTableBean oaattachmenttablebean = (OAAttachmentTableBean)webBean.findIndexedChildRecursive("ASNOrgAttchTable");
        if (oaattachmenttablebean != null)
        {
          oaattachmenttablebean.setDocumentCatalogEnabled(false);
          oaattachmenttablebean.setUpdateable(false);
        }
      
      }

    /*VJ: Added the code for making the page readonly for users with view only access - END*/

        }


	}
	//Anirban: 2135 ends: for skipping view org page and re-directing to the update org page.

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
    final String METHOD_NAME = "xxcrm.asn.common.customer.webui.ODOrgViewCO.processFormRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    if (isProcLogEnabled)
    {
    pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processFormRequest(pageContext, webBean);
    pageContext.putParameter("ASNReqFrmFuncName","ASN_ORGVIEWPG");

    String partyId = pageContext.getParameter("ASNReqFrmCustId");
    String partyName = (String)pageContext.getTransactionValue("ASNTxnCustName");

    HashMap params = new HashMap();
    params.put("ASNReqFrmCustId", partyId);
    params.put("ASNReqFrmCustName", partyName);

    //get the page level event
    String event = pageContext.getParameter(EVENT_PARAM);

    //This is the event handling for the page level buttons
    if (pageContext.getParameter("ASNPageCnclBtn") != null)
    {
        this.processTargetURL(pageContext, null, null);
    }
    else if (pageContext.getParameter("ASNPageApyBtn") != null)
    {
        doCommit(pageContext);
        this.processTargetURL(pageContext, null, null);
    }
    else if (pageContext.getParameter("ASNPageFullUpdBtn") != null)
    {
        doCommit(pageContext);
        params.put("ASNReqFrmFuncName", "ASN_ORGUPDATEPG");
        pageContext.forwardImmediately("ASN_ORGUPDATEPG",
                    KEEP_MENU_CONTEXT ,
                    null,
                    params,
                    false,
                    ADD_BREAD_CRUMB_YES);
    }
    //end of event handling for page else buttons

    //this is event handling for the contacts region
    else if (pageContext.getParameter("HzPuiContRelTableCreateEvent") != null)
    {
        doCommit(pageContext);
        pageContext.putParameter("ASNReqPgAct","SUBFLOW");
                    params.put("ASNReqFrmFuncName", "ASN_CTCTCREATEPG");
                    params.put("ASNReqFrmPgMode", "CREATE");
        this.processTargetURL(pageContext,null,params);
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
       params.put("ASNReqFrmFuncName", "ASN_CTCTVIEWPG");
       pageContext.forwardImmediately("ASN_CTCTVIEWPG",
                    KEEP_MENU_CONTEXT ,
                    null,
                    params,
                    false,
                    ADD_BREAD_CRUMB_YES);
    }

    //end of event handling for the contacts region

    //this is the event handling for the address region
    // Begin Mod Raam on 06.15.2006
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

      pageContext.forwardImmediately("ASN_CUSTADDRCREATEUPDATEPG",  // functionName
                                      KEEP_MENU_CONTEXT ,           // menuContext
                                      null,                         // menuName
                                      params,                       // parameters
                                      false,                        // retainAM
                                      ADD_BREAD_CRUMB_YES);         // addBreadCrumb
    }
    else if ("HzAddressUpdate".equals(pageContext.getParameter("HzPuiAddressViewEvent")))
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

      pageContext.forwardImmediately("ASN_CUSTADDRCREATEUPDATEPG",  // functionName
                                      KEEP_MENU_CONTEXT ,           // menuContext
                                      null,                         // menuName
                                      params,                       // parameters
                                      false,                        // retainAM
                                      ADD_BREAD_CRUMB_YES);         // addBreadCrumb
    }
    //end of event handling for the address region

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
         this.processTargetURL(pageContext,null,params);
    }
    else if (pageContext.getParameter("HzPuiCPPhoneTableActionEvent") != null &&
              "UPDATE".equals( pageContext.getParameter("HzPuiCPPhoneTableActionEvent") ) )
    {
         //params.put("ASNReqCallingPage", "ASN_ORGVIEWPG");
         params.put("HzPuiOwnerTableName", "HZ_PARTIES");
         params.put("HzPuiOwnerTableId", partyId);
         params.put("HzPuiCntctPointEvent", "UPDATE");
         params.put("HzPuiContactPointId", pageContext.getParameter("HzPuiContactPointPhoneId") );
         doCommit(pageContext);
         pageContext.putParameter("ASNReqPgAct","SUBFLOW");
         params.put("ASNReqFrmFuncName", "ASN_CUSTPHNCREATEUPDATEPG");
         this.processTargetURL(pageContext,null,params);
    }
    //end of code for handling events in phone region

    //handle the events raised from the business activities region.
    else if(pageContext.getParameter("ASNReqExitPage") != null &&
          pageContext.getParameter("ASNReqExitPage").equals("Y"))
    {
        doCommit(pageContext);
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
    //handle the PPR events raised by the attachments
    else if("oaAddAttachment".equals(event) ||
             "oaUpdateAttachment".equals(event) ||
             "oaDeleteAttachment".equals(event) ||
             "oaViewAttachment".equals(event) )
    {
                //commit
        doCommit(pageContext);
        //call the common utility method.
                ASNUIUtil.attchEvent(pageContext,webBean);
    }
    else if ("CallNotesDetail".equals(pageContext.getParameter("CacNotesDtlEvent")))
    {
      doCommit(pageContext);
    }

    if (isProcLogEnabled)
    {
    pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }
  }

}

