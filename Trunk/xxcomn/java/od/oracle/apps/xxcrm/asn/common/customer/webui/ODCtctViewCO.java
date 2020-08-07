/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODCtctViewCO.java                                             |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Controller Object for the View Contact Page                            |
 |                                                                           |
 |                                                                           |
 |  NOTES                                                                    |
 |         Used for the Customization on the View Contact Page               |
 |         Handling of the Create and Update Buttons                         |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    No dependencies.                                                       |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    11-Oct-2007 Jasmine Sujithra   Created                                 |
 |    19-Feb-2008 Anirban Chaudhuri  Modified for Contact's Security.        |
 |    30-Apr-2008 Anirban Chaudhuri 'Apply' button visible for read only mode|
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.common.customer.webui;


import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.nav.OALinkBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import java.io.Serializable;
import com.sun.java.util.collections.HashMap;
import oracle.apps.asn.common.fwk.webui.ASNControllerObjectImpl;
import oracle.apps.fnd.framework.webui.beans.layout.OACellFormatBean;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.asn.common.fwk.webui.ASNUIConstants;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;
import oracle.apps.asn.common.webui.ASNUIUtil;
import java.util.Hashtable;
import od.oracle.apps.xxcrm.asn.common.fwk.webui.ODASNControllerObjectImpl;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.OASwitcherBean;
import oracle.apps.fnd.framework.webui.beans.layout.*;
import oracle.cabo.ui.UIConstants;
import oracle.cabo.ui.beans.layout.CellFormatBean;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;



/**
 * Controller for ...
 */
public class ODCtctViewCO extends ODASNControllerObjectImpl
{
  public static final String RCS_ID="$Header: /home/cvs/repository/Office_Depot/SRC/CRM/E1307_SiteLevel_Attributes_ASN/3.\040Source\040Code\040&\040Install\040Files/E1307D_SiteLevel_Attributes_(LeadOpp_CreateUpdate)/ODCtctViewCO.java,v 1.1 2007/10/11 20:59:38 jsujithra Exp $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
   final String METHOD_NAME = "asn.common.customer.webui.CtctViewCO.processRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    if (isProcLogEnabled)
    {
    pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processRequest(pageContext, webBean);

    String objPartyId = (String) pageContext.getParameter("ASNReqFrmCustId");
    String objPartyName = (String) pageContext.getParameter("ASNReqFrmCustName");
    String subPartyId = (String) pageContext.getParameter("ASNReqFrmCtctId");
    String subPartyName = (String) pageContext.getParameter("ASNReqFrmCtctName");
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

    Hashtable ht = (Hashtable) am.invokeMethod("getAttributes");
    // getting subpartyname and object party name
    if(objPartyName == null) {
        objPartyName = (String)ht.get("RelatedOrganizationName");
    }
    if(subPartyName == null) {
        subPartyName = (String)ht.get("PersonPartyName");
    }

    MessageToken[] tokens = { new MessageToken("SUBPARTYNAME", subPartyName),
                              new MessageToken("OBJPARTYNAME", objPartyName) };
    String pageTitle = pageContext.getMessage("ASN", "ASN_TCA_VIEW_CTCT_TITLE", tokens);
    // Set the page title (which also appears in the breadcrumbs)
    ((OAPageLayoutBean)webBean).setTitle(pageTitle);

    //save partyname in the transaction.
    pageContext.putTransactionValue("ASNTxnCustName", objPartyName);
    pageContext.putTransactionValue("ASNTxnCtctName", subPartyName);


    //set up the colspan for the notes row
    OACellFormatBean notesCell = (OACellFormatBean)webBean.findChildRecursive("ASNCtctNotesCell");
    if(notesCell != null){
       notesCell.setColumnSpan(2);
    }
    //set up the colspan for the tasks row
    OACellFormatBean tasksCell = (OACellFormatBean)webBean.findChildRecursive("ASNCtctTasksCell");
    if(tasksCell != null){
       tasksCell.setColumnSpan(2);
    }
    //set up the colspan for the Business Activities
    OACellFormatBean bussActCell = (OACellFormatBean)webBean.findChildRecursive("ASNCtctBussActCell");
    if(bussActCell != null){
       bussActCell.setColumnSpan(2);
    }

    //hide the un-supported items in the tca components that should not be personalized by the user
    //address section
    OAHeaderBean asnCtctAddrRN = (OAHeaderBean) webBean.findChildRecursive("ASNCtctAddrRN");
    if(asnCtctAddrRN != null){
      //hide the buttons in the address view component
      OASubmitButtonBean hzPuiViewInactiveButton=  (OASubmitButtonBean)asnCtctAddrRN.findChildRecursive("HzPuiViewInactiveButton");
      if(hzPuiViewInactiveButton != null){
        hzPuiViewInactiveButton.setRendered(false);
      }
      OASubmitButtonBean hzPuiSelectPrimaryUseButton=  (OASubmitButtonBean)asnCtctAddrRN.findChildRecursive("HzPuiSelectPrimaryUseButton");
      if(hzPuiSelectPrimaryUseButton != null){
        hzPuiSelectPrimaryUseButton.setRendered(false);
      }
    }
    //end address section
    //end of hiding the un-supported items in tca components that should not be personalizable

    //put the parameters required for the first part of header
    pageContext.putParameter("HzPuiContRelPartyId", relPartyId);
    pageContext.putParameter("HzPuiContObjectPartyId", objPartyId);
    pageContext.putParameter("HzPuiContactDetailsEvent", "UPDATE");

    //put the parameters required for the header regions
    pageContext.putParameter("HzPuiPartyId", relPartyId);

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

    //put the parameters required for the phone region
    pageContext.putParameter("HzPuiCPPhoneTableEvent", "UPDATE");
    pageContext.putParameter("HzPuiOwnerTableName", "HZ_PARTIES");
    pageContext.putParameter("HzPuiOwnerTableId", relPartyId );

    //put the parameters required for the business activities region


    //put the code required for the attachments
    //attachment integration here
    ASNUIUtil.attchSetUp(pageContext
                    ,webBean
                    ,true
                    ,"ASNCtctAttchTable"//This is the attachment table item
                    ,"ASNCtctAttchContextHolderRN"//This is the stack region that holds the context information
                    ,"ASNCtctAttchContextRN");//this is the messageComponentLayout region that holds actual context beans

    //set up the colspan for the attachemnts cell
    OACellFormatBean attchCell = (OACellFormatBean)webBean.findChildRecursive("ASNCtctAttchCell");
    if(attchCell != null){
       attchCell.setColumnSpan(2);
    }

    //put the parameters required for the business activities region
    pageContext.putTransactionValue("ASNTxnCustomerId", objPartyId);
    pageContext.putTransactionValue("ASNTxnRelPtyId", relPartyId);
    pageContext.putTransactionValue("ASNTxnBusActLkpTyp", "ASN_BUSINESS_ACTS");
    pageContext.putTransactionValue("ASNTxnAddBrdCrmb", "ADD_BREAD_CRUMB_YES");
    pageContext.putTransactionValue("ASNTxnReturnUrl", getModifiedCurrentUrlForRedirect(pageContext, true));

    // set return to link destination
    ///*comment it out for now*/addReturnLink( pageContext, webBean, "ASNCtctViewRetLnk");

  }

  //Anirban starts making view contact page as read only based on security access.
    String custAccMode = this.processAccessPrivilege(pageContext,
                                                     ASNUIConstants.CUSTOMER_ENTITY,
                                                     objPartyId);

	if ("101lOl11O".equals(custAccMode))
    {
     
     pageContext.putTransactionValue("ReadOnlyModeDefect","ReadOnlyMode");
	 pageContext.putTransactionValue("ROModeAddress","ReadOnlyMode");

     OASubmitButtonBean updateCtctDetails = (OASubmitButtonBean)webBean.findChildRecursive("ASNPageFullUpdBtn");
     if(updateCtctDetails != null)
     {
      updateCtctDetails.setRendered(false);
	 }
	 OASubmitButtonBean pageApyBtn = (OASubmitButtonBean)webBean.findChildRecursive("ASNPageApyBtn");
     if(pageApyBtn != null)
     {
      pageApyBtn.setRendered(true);
	 }

	 OAHeaderBean oaheaderbean = (OAHeaderBean)webBean.findChildRecursive("ASNCtctAddrRN");
     if(oaheaderbean != null)
     {
      OAFlowLayoutBean oaflowlayoutbean = (OAFlowLayoutBean)oaheaderbean.findChildRecursive("addressButtons");
      if(oaflowlayoutbean != null)
         oaflowlayoutbean.setRendered(false);

      OASwitcherBean oaswitcherbean = (OASwitcherBean)oaheaderbean.findChildRecursive("updateSwitcher");
      if(oaswitcherbean != null)
         oaswitcherbean.setRendered(false);

      OASwitcherBean oaswitcherbean1 = (OASwitcherBean)oaheaderbean.findChildRecursive("removeSwitcher");
      if(oaswitcherbean1 != null)
         oaswitcherbean1.setRendered(false);

	  OASubmitButtonBean hzPuiCreateButton=  (OASubmitButtonBean)oaheaderbean.findChildRecursive("HzPuiCreateButton");
      if(hzPuiCreateButton != null){
         hzPuiCreateButton.setRendered(false);}
     }

     OAHeaderBean oaheaderbean1 = (OAHeaderBean)webBean.findChildRecursive("ASNCtctPhnRN");
     if(oaheaderbean1 != null)
     {
      OARowLayoutBean oarowlayoutbean = (OARowLayoutBean)oaheaderbean1.findChildRecursive("tableActionsPhoneRL");
      if(oarowlayoutbean != null)
         oarowlayoutbean.setRendered(false);

      OASwitcherBean oaswitcherbean2 = (OASwitcherBean)oaheaderbean1.findChildRecursive("UpdateSwitcher");
      if(oaswitcherbean2 != null)
         oaswitcherbean2.setRendered(false);

      OASwitcherBean oaswitcherbean3 = (OASwitcherBean)oaheaderbean1.findChildRecursive("DeleteSwitcher");
      if(oaswitcherbean3 != null)
         oaswitcherbean3.setRendered(false);
     }
	  
     ASNUIUtil.attchSetUp(pageContext
                    ,webBean
                    ,false
                    ,"ASNCtctAttchTable"//This is the attachment table item
                    ,"ASNCtctAttchContextHolderRN"//This is the stack region that holds the context   information
                    ,"ASNCtctAttchContextRN");//this is the messageComponentLayout region that holds actual context beans
     OAAttachmentTableBean oaattachmenttablebean = (OAAttachmentTableBean)webBean.findIndexedChildRecursive("ASNCtctAttchTable");
     if (oaattachmenttablebean != null)
     {
      oaattachmenttablebean.setDocumentCatalogEnabled(false);
      oaattachmenttablebean.setUpdateable(false);
     }
	 

	 OAStackLayoutBean ASNTasksRN = (OAStackLayoutBean)webBean.findChildRecursive("ASNCtctTasksRN");
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
	  pageContext.putTransactionValue("cacTaskNoDelDlg", "Y");
	  pageContext.putTransactionValue("cacTaskReadOnlyPPR", "Y");
	 }
   
	 }
  //Anirban ends making view contact page as read only based on security access.

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
    final String METHOD_NAME = "asn.common.customer.webui.CtctViewCO.processFormRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    if (isProcLogEnabled)
    {
    pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processFormRequest(pageContext, webBean);
    pageContext.putParameter("ASNReqFrmFuncName","ASN_CTCTVIEWPG");

    String objPartyId = (String) pageContext.getParameter("ASNReqFrmCustId");
    String objPartyName = (String) pageContext.getTransactionValue("ASNTxnCustName");
    String subPartyId = (String) pageContext.getParameter("ASNReqFrmCtctId");
    String subPartyName = (String) pageContext.getTransactionValue("ASNTxnCtctName");
    String relPartyId = (String) pageContext.getParameter("ASNReqFrmRelPtyId");
    String relId = (String) pageContext.getParameter("ASNReqFrmRelId");



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
    else if (pageContext.getParameter("ASNPageFullUpdBtn") != null)
    {
        doCommit(pageContext);
        params.put("ASNReqFrmFuncName", "ASN_CTCTUPDATEPG");
        pageContext.forwardImmediately("ASN_CTCTUPDATEPG",
                    KEEP_MENU_CONTEXT ,
                    null,
                    params,
                    false,
                    ADD_BREAD_CRUMB_YES);
    }
    //end of event handling for page level buttons

    //this is the event handling for the address region
    else if(pageContext.getParameter("HzPuiSelectButton") != null)
    // When address select button is clicked
    {
      doCommit(pageContext);

      pageContext.putParameter("ASNReqPgAct","SUBFLOW");
      params.put("ASNReqFrmFuncName","ASN_PTYADDRSELPG");
      params.put("ASNReqFrmCreateSite", "Y");

      this.processTargetURL(pageContext, null, params);
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

      pageContext.forwardImmediately("ASN_CTCTADDRCREATEUPDATEPG",  // functionName
                                      KEEP_MENU_CONTEXT ,           // menuContext
                                      null,                         // menuName
                                      params,                       // parameters
                                      false,                        // retainAM
                                      ADD_BREAD_CRUMB_YES);         // addBreadCrumb
    }
    else if ("HzAddressUpdate".equals(pageContext.getParameter("HzPuiAddressViewEvent")))
    // When address update icon is clicked
    {
      // Save the changes.
      doCommit(pageContext);

      params.put("HzPuiAddressPartyId", relPartyId);
      params.put("HzPuiAddressEvent" , "UPDATE");
      params.put("ASNReqFrmSiteId" , pageContext.getParameter("HzPuiAddressViewPartySiteId"));
      pageContext.putParameter("ASNReqFrmSiteId" , pageContext.getParameter("HzPuiAddressViewPartySiteId"));
      // Begin Mod Raam on 02/14/2005
      // Address event is set in pageContext to override the value set in
      // processRequest during back button scenario.
      pageContext.putParameter("HzPuiAddressEvent" , "UPDATE");
      // End Mod.
      params.put("HzPuiAddressLocationId", pageContext.getParameter("HzPuiAddressViewLocationId"));
      params.put("HzPuiAddressPartySiteId", pageContext.getParameter("HzPuiAddressViewPartySiteId"));
      params.put("ASNReqFrmFuncName", "ASN_CTCTADDRCREATEUPDATEPG");

      pageContext.forwardImmediately("ASN_CTCTADDRCREATEUPDATEPG",  // functionName
                                      KEEP_MENU_CONTEXT ,           // menuContext
                                      null,                         // menuName
                                      params,                       // parameters
                                      false,                        // retainAM
                                      ADD_BREAD_CRUMB_YES);         // addBreadCrumb
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
         this.processTargetURL(pageContext,null,params);
    }
    else if (pageContext.getParameter("HzPuiCPPhoneTableActionEvent") != null &&
              "UPDATE".equals( pageContext.getParameter("HzPuiCPPhoneTableActionEvent") ) )
    {
         params.put("ASNReqCallingPage", "ASN_CTCTVIEWPG");
         params.put("HzPuiOwnerTableName", "HZ_PARTIES");
         params.put("HzPuiOwnerTableId", relPartyId);
         params.put("HzPuiCntctPointEvent", "UPDATE");
         params.put("HzPuiContactPointId", pageContext.getParameter("HzPuiContactPointPhoneId") );
         // Begin Mod Raam 11.22.2004
         // Part of fix for bug 4023544
         params.put("HzPuiContPrefDoNotCallQMode", "CURRENTFUTURE");
         // End Mod.
         doCommit(pageContext);
         pageContext.putParameter("ASNReqPgAct","SUBFLOW");
         params.put("ASNReqFrmFuncName", "ASN_CTCTPHNCREATEUPDATEPG");
         this.processTargetURL(pageContext,null,params);
    }
    //end of code for handling events in phone region

    //event handling for the header region customer hyperlink
    else if (pageContext.getParameter("HzPuiContactDetailEvent") != null &&
              "ORGANIZATION".equals( pageContext.getParameter("HzPuiContactDetailEvent") ) )

    {
         HashMap orgParams = new HashMap();
         orgParams.put("ASNReqFrmCustId", objPartyId);
         orgParams.put("ASNReqFrmCustName", objPartyName);
         orgParams.put("ASNReqFrmFuncName", "ASN_ORGVIEWPG");

         doCommit(pageContext);
         pageContext.putParameter("ASNReqPgAct","CUSTDET");

		 //Anirban starts securing party name link on the contact's view page
         //this.processTargetURL(pageContext,null,orgParams);
		 boolean flag50 = false;
		 pageContext.forwardImmediately("ASN_ORGVIEWPG", OAWebBeanConstants.KEEP_MENU_CONTEXT, null, orgParams, flag50, "Y");
         //Anirban ends securing party name link on the contact's view page
    }
    // Begin Mod Raam 11.20.2004
    // The following HzPuiContPrefExistEvent is handled to forward to phone
    // create update page. Fixes bug 4023544
   else if ("HzPuiContPrefExistEvent".equals(pageContext.getParameter(EVENT_PARAM)))
    {
      doCommit(pageContext);
      params.put("HzPuiCntctPointEvent", "UPDATE");
      params.put("HzPuiContPrefDoNotCallQMode", "CURRENTFUTURE");
      pageContext.putParameter("ASNReqPgAct","SUBFLOW");
      params.put("ASNReqFrmFuncName", "ASN_CTCTPHNCREATEUPDATEPG");
      this.processTargetURL(pageContext,null,params);
    }
    // End Mod.
    else if ("Update".equals(pageContext.getParameter("CacSmrTaskEvent")) ||
             "View".equals(pageContext.getParameter("CacSmrTaskEvent")) ||
             "CallNotesDetail".equals(pageContext.getParameter("CacNotesDtlEvent")))
    {
        doCommit(pageContext);
    }
    //handle the events raised from the business activities region.
    else if(pageContext.getParameter("ASNReqExitPage") != null &&
          pageContext.getParameter("ASNReqExitPage").equals("Y"))
    {
        doCommit(pageContext);
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


    if (isProcLogEnabled)
    {
    pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }

  }

}
