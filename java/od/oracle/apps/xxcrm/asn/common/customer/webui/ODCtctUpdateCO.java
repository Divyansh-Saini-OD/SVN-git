/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODCtctViewCO.java                                             |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Controller Object for the Update Contact Page                          |
 |                                                                           |
 |                                                                           |
 |  NOTES                                                                    |
 |         Used for the Customization on the Update Contact Page             |
 |         Handling of the Create and Update Buttons                         |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    No dependencies.                                                       |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    11-Oct-2007 Jasmine Sujithra   Created                                 |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.common.customer.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import java.io.Serializable;
import com.sun.java.util.collections.HashMap;
import oracle.apps.asn.common.fwk.webui.ASNControllerObjectImpl;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.asn.common.fwk.webui.ASNUIConstants;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;
import oracle.apps.asn.common.webui.ASNUIUtil;
import java.util.Hashtable;

import oracle.apps.fnd.framework.server.OADBTransaction;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import oracle.jdbc.driver.OracleConnection;
import java.sql.SQLException;


/**
 * Controller for ...
 */
public class ODCtctUpdateCO extends ASNControllerObjectImpl
{
  public static final String RCS_ID="$Header: /home/cvs/repository/Office_Depot/SRC/CRM/E1307_SiteLevel_Attributes_ASN/3.\040Source\040Code\040&\040Install\040Files/E1307D_SiteLevel_Attributes_(LeadOpp_CreateUpdate)/ODCtctUpdateCO.java,v 1.1 2007/10/11 20:59:38 jsujithra Exp $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
   final String METHOD_NAME = "asn.common.customer.webui.CtctUpdateCO.processRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    if (isProcLogEnabled)
    {
    pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processRequest(pageContext, webBean);


    String objPartyId = (String) pageContext.getParameter("ASNReqFrmCustId");    
    String objPartyName = null; //(String) pageContext.getParameter("ASNReqFrmCustName");  
    String subPartyId = (String) pageContext.getParameter("ASNReqFrmCtctId");
    String subPartyName = null; //(String) pageContext.getParameter("ASNReqFrmCtctName");
    String relPartyId = (String) pageContext.getParameter("ASNReqFrmRelPtyId");
    String relId = (String) pageContext.getParameter("ASNReqFrmRelId");


    
  if( objPartyId == null || subPartyId == null || relPartyId == null || relId == null)
  {
     OAException e = new OAException("ASN", "ASN_TCA_CTCTPARAM_MISS_ERR");
     pageContext.putDialogMessage(e);
  }
  else
  {
    OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);
    Serializable[] parameters =  { relPartyId, objPartyId };
    //intialize the VO
    am.invokeMethod("initQuery", parameters);

    /* Begin devi change
     * getting subpartyname and object party name
     * Added for eBilling*/
    objPartyName = (String) pageContext.getParameter("ODReqFrmCustName"); 
    subPartyName = (String) pageContext.getParameter("ODReqFrmCtctName");
    String parentPage = (String) pageContext.getParameter("ODEBillParentPage");
    if((objPartyName == null) || (subPartyName == null))
    {
    //End of eBilling Change
    
      Hashtable ht = (Hashtable) am.invokeMethod("getAttributes");

      if(objPartyName == null) {
          objPartyName = (String)ht.get("RelatedOrganizationName");
      }
      if(subPartyName == null) {
          subPartyName = (String)ht.get("PersonPartyName");
      }

    }//eBilling Change







    MessageToken[] tokens = { new MessageToken("SUBPARTYNAME", subPartyName),
                              new MessageToken("OBJPARTYNAME", objPartyName) };
    String pageTitle = pageContext.getMessage("ASN", "ASN_TCA_UPDT_CTCT_TITLE", tokens);
    // Set the page title (which also appears in the breadcrumbs)
    ((OAPageLayoutBean)webBean).setTitle(pageTitle);

    //hide the un-supported items in the tca components that should not be personalized by the user
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
    //end of hiding the un-supported items in tca components that should not be personalizable

    //save partyname in the transaction.
    pageContext.putTransactionValue("ASNTxnCustName", objPartyName);
    pageContext.putTransactionValue("ASNTxnCtctName", subPartyName);


    //put the parameters required for the header region
    pageContext.putParameter("HzPuiContactRelationshipId", relId);
    pageContext.putParameter("HzPuiContactPartyId", subPartyId);
    pageContext.putParameter("HzPuiContactEvent", "UPDATE");


    //put the parameters required for the notes region
    pageContext.putTransactionValue("ASNTxnNoteSourceCode", "PARTY");
    pageContext.putTransactionValue("ASNTxnNoteSourceId", relPartyId);

    //put the parameters required for the tasks region
    pageContext.putTransactionValue("cacTaskSrcObjCode", "PARTY");
    pageContext.putTransactionValue("cacTaskSrcObjId", relPartyId);
    pageContext.putTransactionValue("cacTaskCustId", objPartyId);
    pageContext.putTransactionValue("cacTaskContDqmRule", (String) pageContext.getProfile("HZ_DQM_CON_SIMPLE_MATCHRULE"));
    pageContext.putTransactionValue("cacTaskNoDelDlg", "Y");
    pageContext.putTransactionValue("cacTaskReturnUrl", getModifiedCurrentUrlForRedirect(pageContext, true));

    //put the parameters required for the address region
    pageContext.putParameter("HzPuiAddressEvent", "ViewAddress");
    pageContext.putParameter("HzPuiAddressPartyId", relPartyId);

    //put the parameters required for the contact points
    pageContext.putParameter("HzPuiCPPhoneTableEvent", "UPDATE");
	  pageContext.putParameter("HzPuiCPEmailTableEvent", "UPDATE");
    pageContext.putParameter("HzPuiOwnerTableName", "HZ_PARTIES");
    pageContext.putParameter("HzPuiOwnerTableId", relPartyId );

    //put the code required for the attachments
    //attachment integration here
    ASNUIUtil.attchSetUp(pageContext
                    ,webBean
                    ,true
                    ,"ASNCtctAttchTable"//This is the attachment table item
                    ,"ASNCtctAttchContextHolderRN"//This is the stack region that holds the context information
                    ,"ASNCtctAttchContextRN");//this is the messageComponentLayout region that holds actual context beans



    /*
     * initialize TCA parameters required for subtab PPR
     */
    Serializable [] pparams = {objPartyId, subPartyId, relPartyId, relId};
    am.invokeMethod("initSubtabPPRParameters", pparams);


  	//put the parameters required for the business activities region
    pageContext.putTransactionValue("ASNTxnCustomerId", objPartyId);
    pageContext.putTransactionValue("ASNTxnRelPtyId", relPartyId);
    pageContext.putTransactionValue("ASNTxnBusActLkpTyp", "ASN_BUSINESS_ACTS");
    pageContext.putTransactionValue("ASNTxnAddBrdCrmb", "ADD_BREAD_CRUMB_YES");
    pageContext.putTransactionValue("ASNTxnReturnUrl", getModifiedCurrentUrlForRedirect(pageContext, true));

    // set return to link destination
    ///*comment it out for now*/addReturnLink( pageContext, webBean, "ASNCtctUpdRetLnk");

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
      final String METHOD_NAME = "asn.common.customer.webui.CtctUpdateCO.processFormRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    if (isProcLogEnabled)
    {
    pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processFormRequest(pageContext, webBean);
    pageContext.putParameter("ASNReqFrmFuncName","ASN_CTCTUPDATEPG");

    String objPartyId = (String) pageContext.getParameter("ASNReqFrmCustId");
    String objPartyName = (String) pageContext.getTransactionValue("ASNTxnCustName");
    String subPartyId = (String) pageContext.getParameter("ASNReqFrmCtctId");
    String subPartyName = (String) pageContext.getTransactionValue("ASNTxnCtctName");
    String relPartyId = (String) pageContext.getParameter("ASNReqFrmRelPtyId");
    String relId = (String) pageContext.getParameter("ASNReqFrmRelId");



    subPartyName = pageContext.getParameter("FirstName") + " " + pageContext.getParameter("LastName");
    MessageToken[] tokens = { new MessageToken("SUBPARTYNAME", subPartyName),
                              new MessageToken("OBJPARTYNAME", objPartyName) };
    String pageTitle = pageContext.getMessage("ASN", "ASN_TCA_UPDT_CTCT_TITLE", tokens);

    HashMap conditions = new HashMap();
    conditions.put(ASNUIConstants.BC_CURRENT_LINK, ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
    conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT,pageTitle);

    HashMap params = new HashMap();
    params.put("ASNReqFrmCustId",objPartyId);
    params.put("ASNReqFrmCustName", objPartyName);
    params.put("ASNReqFrmCtctId",subPartyId);
    params.put("ASNReqFrmCtctName", subPartyName);
    params.put("ASNReqFrmRelPtyId",relPartyId);
    params.put("ASNReqFrmRelId", relId);

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
    //end of event handling for page else buttons


    //this is the event handling for the address region
    // Begin Mod Raam on 06.14.2006
    else if(pageContext.getParameter("HzPuiSelectButton") != null)
    // When address select button is clicked
    {
      doCommit(pageContext);

      pageContext.putParameter("ASNReqPgAct","SUBFLOW");
      params.put("ASNReqFrmFuncName","ASN_PTYADDRSELPG");
      params.put("ASNReqFrmCreateSite", "Y");

      this.processTargetURL(pageContext,conditions, params);
    }
    else if (pageContext.getParameter("HzPuiCreateButton") != null )
    // When address create button is clicked
    {
      // Save the changes.
      doCommit(pageContext);

      params.put("HzPuiAddressPartyId", relPartyId);
      params.put("HzPuiAddressEvent", "CREATE");
      // Begin Mod Raam on 02/14/2005
      // Address event is set in pageContext to override the value set in
      // processRequest during back button scenario.
      pageContext.putParameter("HzPuiAddressEvent" , "CREATE");
      // End Mod.
      params.put("ASNReqFrmFuncName", "ASN_CTCTADDRCREATEUPDATEPG");

      // replace the current link text/title from the bread crumb with the specified value
      // the title will not be replaced if the specified value is null/empty
      this.modifyCurrentBreadcrumbLink(pageContext, // pageContext
                                       true,        // replaceCurrentText
                                       pageTitle,   // newText
                                       false);      // resetRetainAMParam

      pageContext.forwardImmediately("ASN_CTCTADDRCREATEUPDATEPG",  // functionName
                                      KEEP_MENU_CONTEXT ,           // menuContext
                                      null,                         // menuName
                                      params,                       // parameters
                                      false,                        // retainAM
                                      ADD_BREAD_CRUMB_YES);         // addBreadCrumb
    }
    else if ("HzAddressUpdate".equals(pageContext.getParameter("HzPuiAddressViewEvent")))
    // When address update icon is clicked
    {   // Message for checking Invalid site.
					  String partySID = (String) pageContext.getParameter("HzPuiAddressViewPartySiteId");

			pageContext.writeDiagnostics(METHOD_NAME,"HzPuiAddressViewPartySiteId:" +partySID,OAFwkConstants.PROCEDURE);
						String sql1 = "select status from hz_party_sites where party_site_id = :1";
	  		  		 OAApplicationModule am = pageContext.getRootApplicationModule();
	  		  		 oracle.jbo.ViewObject pctvo4 = am.findViewObject("pctVO4");
	  		  		             if (pctvo4 == null )
	  		  		             {
	  		  		               pctvo4 = am.createViewObjectFromQueryStmt("pctVO4", sql1);
	  		  		             }

	  		  		             if (pctvo4 != null)
	  		  		             {
	  		  		                 pctvo4.setWhereClauseParams(null);
	  		  		                 pctvo4.setWhereClauseParam(0,partySID);
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
										// Save the changes
										doCommit(pageContext);
										params.put("ASNReqFrmSiteId" , pageContext.getParameter("HzPuiAddressViewPartySiteId"));
										pageContext.putParameter("ASNReqFrmSiteId" , pageContext.getParameter("HzPuiAddressViewPartySiteId"));
										params.put("HzPuiAddressPartyId", relPartyId);
										params.put("HzPuiAddressEvent" , "UPDATE");
										// Begin Mod Raam on 02/14/2005
										// Address event is set in pageContext to override the value set in
										// processRequest during back button scenario.
										pageContext.putParameter("HzPuiAddressEvent" , "UPDATE");
										// End Mod.
										params.put("HzPuiAddressLocationId", pageContext.getParameter("HzPuiAddressViewLocationId"));
										params.put("HzPuiAddressPartySiteId", pageContext.getParameter("HzPuiAddressViewPartySiteId"));
										params.put("ASNReqFrmFuncName", "ASN_CTCTADDRCREATEUPDATEPG");

										// replace the current link text/title from the bread crumb with the specified value
										// the title will not be replaced if the specified value is null/empty
										this.modifyCurrentBreadcrumbLink(pageContext, // pageContext
										true,        // replaceCurrentText
										pageTitle,   // newText
										false);      // resetRetainAMParam

										pageContext.forwardImmediately("ASN_CTCTADDRCREATEUPDATEPG",  // functionName
																		KEEP_MENU_CONTEXT ,           // menuContext
																		null,                         // menuName
																		params,                       // parameters
																		false,                        // retainAM
                                      									ADD_BREAD_CRUMB_YES);         // addBreadCrumb
									 }

								   }

    }
    //end of event handling for the address region

   //Redirect to phone create page
    else if ( pageContext.getParameter("HzPuiPhoneCreateButton") != null )
    {
         params.put("ASNReqCallingPage", "ASN_CTCTVIEWPG");
         params.put("HzPuiOwnerTableName", "HZ_PARTIES");
         params.put("HzPuiOwnerTableId", relPartyId);
         params.put("HzPuiCntctPointEvent", "CREATE");
         params.put("HzPuiPhoneLineType", pageContext.getParameter("HzPuiSelectedPhoneLineType") );
         doCommit(pageContext);
         pageContext.putParameter("ASNReqPgAct","SUBFLOW");
         params.put("ASNReqFrmFuncName", "ASN_CTCTPHNCREATEUPDATEPG");
         this.processTargetURL(pageContext,conditions,params);
    }
    else if (pageContext.getParameter("HzPuiCPPhoneTableActionEvent") != null &&
              "UPDATE".equals( pageContext.getParameter("HzPuiCPPhoneTableActionEvent") ) )
    {
         params.put("ASNReqCallingPage", "ASN_CTCTVIEWPG");
         params.put("HzPuiOwnerTableName", "HZ_PARTIES");
         params.put("HzPuiOwnerTableId", relPartyId);
         params.put("HzPuiCntctPointEvent", "UPDATE");
         params.put("HzPuiContactPointId", pageContext.getParameter("HzPuiContactPointPhoneId") );
         // Begin Mod Raam on 11.21.2004
         params.put("HzPuiContPrefDoNotCallQMode", "CURRENTFUTURE");
         // End Mod.
         doCommit(pageContext);
         pageContext.putParameter("ASNReqPgAct","SUBFLOW");
         params.put("ASNReqFrmFuncName", "ASN_CTCTPHNCREATEUPDATEPG");
         this.processTargetURL(pageContext,conditions,params);
    }
    //end of code for handling events in phone region

    //event handling for the email region
    else if (pageContext.getParameter("HzPuiEmailCreateButton") != null ) {
        params.put("HzPuiOwnerTableName", "HZ_PARTIES");
        params.put("HzPuiOwnerTableId", relPartyId);
        params.put("HzPuiCntctPointEvent", "CREATE");
        doCommit(pageContext);
        pageContext.putParameter("ASNReqPgAct","SUBFLOW");
        params.put("ASNReqFrmFuncName", "ASN_CTCTEMLCREATEUPDATEPG");
        this.processTargetURL(pageContext,conditions,params);
	  }
    else if (pageContext.getParameter("HzPuiCPEmailTableActionEvent") != null &&
	              "UPDATE".equals( pageContext.getParameter("HzPuiCPEmailTableActionEvent") ) )
    {
        params.put("HzPuiOwnerTableName", "HZ_PARTIES");
        params.put("HzPuiOwnerTableId", relPartyId);
        params.put("HzPuiCntctPointEvent", "UPDATE");
        params.put("HzPuiContactPointId", pageContext.getParameter("HzPuiContactPointEmailId") );
        doCommit(pageContext);
        pageContext.putParameter("ASNReqPgAct","SUBFLOW");
        params.put("ASNReqFrmFuncName", "ASN_CTCTEMLCREATEUPDATEPG");
        this.processTargetURL(pageContext,conditions,params);
    }
    //end of code for handling events in the email region
    else if ("Update".equals(pageContext.getParameter("CacSmrTaskEvent")) ||
             "View".equals(pageContext.getParameter("CacSmrTaskEvent")) ||
             "CallNotesDetail".equals(pageContext.getParameter("CacNotesDtlEvent")))
    {
      doCommit(pageContext);
      this.modifyCurrentBreadcrumbLink(pageContext, true, pageTitle, false);
    }
    //handle the events raised from the business activities region.
    else if(pageContext.getParameter("ASNReqExitPage") != null &&
          pageContext.getParameter("ASNReqExitPage").equals("Y"))
    {
      //commit
      doCommit(pageContext);
      //modify the breadcrumb link.
      this.modifyCurrentBreadcrumbLink(pageContext, true, pageTitle, false);
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
      ASNUIUtil.attchEvent(pageContext, webBean);
    }


    if (isProcLogEnabled)
    {
    pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }

  }

}
