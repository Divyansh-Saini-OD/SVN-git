/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODCtctAddrCreateUpdateCO.java                                 |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Controller Object for the Create Update Contact Address Page.          |
 |                                                                           |
 |  NOTES                                                                    |
 |      Used for the Customization on the Create Update Contact Address Page |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    No dependencies.                                                       |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    27-Sep-2007 Jasmine Sujithra   Created                                 |
 |    27-Dec-2007 Jasmine Sujithra    FetchedRowCount removed #217           |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.common.customer.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.nav.OAPageButtonBarBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import com.sun.java.util.collections.HashMap;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.asn.common.fwk.webui.ASNControllerObjectImpl;

import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.OAException;
import java.io.Serializable;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;



/**
 * Controller for ...
 */
public class ODCtctAddrCreateUpdateCO extends ASNControllerObjectImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODCtctAddrCreateUpdateCO.processRequest";

    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }
    String prmReturnUrl = this.getModifiedCurrentUrlForRedirect(pageContext, true);
           pageContext.putTransactionValue("prmReturnUrl ", prmReturnUrl);

    super.processRequest(pageContext, webBean);

    // Begin Mod Raam on 06.14.2006
    // Remove SUBFLOW related coding.
    //If it is a subflow page, need to retain context parameters here
    //retainContextParameters(pageContext);
    // End Mod.

    //disable the breadcrumbs
    ((OAPageLayoutBean) webBean).setBreadCrumbEnabled(false);

    String objPartyId = (String) pageContext.getParameter("ASNReqFrmCustId");
    String objPartyName = (String) pageContext.getParameter("ASNReqFrmCustName");
    String subPartyId = (String) pageContext.getParameter("ASNReqFrmCtctId");
    String subPartyName = (String) pageContext.getParameter("ASNReqFrmCtctName");
    String relPartyId = (String) pageContext.getParameter("ASNReqFrmRelPtyId");
    String relId = (String) pageContext.getParameter("ASNReqFrmRelId");

    String addressEvent = (String) pageContext.getParameter("HzPuiAddressEvent");

    if(addressEvent !=null && addressEvent.equals("UPDATE"))
    {
      OAPageButtonBarBean pb = (OAPageButtonBarBean)pageContext.getPageLayoutBean().getPageButtons();
      OASubmitButtonBean saveAndAddAnotherButton = (OASubmitButtonBean)pb.findIndexedChildRecursive("ASNPageSvCrteAnotherBtn");
      saveAndAddAnotherButton.setRendered(false);

      MessageToken[] tokens = { new MessageToken("PARTYNAME", subPartyName) };
      String pageTitle = pageContext.getMessage("ASN", "ASN_TCA_UPDT_ADDR_TITLE", tokens);
      // Set the page title (which also appears in the breadcrumbs)
      ((OAPageLayoutBean)webBean).setTitle(pageTitle);
    }
    else if(addressEvent !=null && addressEvent.equals("CREATE"))
    {
      MessageToken[] tokens = { new MessageToken("PARTYNAME", subPartyName) };
      String pageTitle = pageContext.getMessage("ASN", "ASN_TCA_CRTE_ADDR_TITLE", tokens);
      // Set the page title (which also appears in the breadcrumbs)
      ((OAPageLayoutBean)webBean).setTitle(pageTitle);
    }
    if (isStatLogEnabled)
    {
      StringBuffer buf = new StringBuffer();
      buf.append("HzPuiAddressPartyId = ");
      buf.append(pageContext.getParameter("HzPuiAddressPartyId"));
      buf.append("HzPuiPartySiteId = ");
      buf.append(pageContext.getParameter("HzPuiPartySiteId"));
      buf.append("HzPuiAddressEvent = ");
      buf.append(pageContext.getParameter("HzPuiAddressEvent"));
      buf.append("HzPuiAddressExist = ");
      buf.append(pageContext.getParameter("HzPuiAddressExist"));
      pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
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
   final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODCtctAddrCreateUpdateCO.processFormRequest";

    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processFormRequest(pageContext, webBean);
    String objPartyId = (String) pageContext.getParameter("ASNReqFrmCustId");
    String objPartyName = (String) pageContext.getParameter("ASNReqFrmCustName");
    String subPartyId = (String) pageContext.getParameter("ASNReqFrmCtctId");
    String subPartyName = (String) pageContext.getParameter("ASNReqFrmCtctName");
    String relPartyId = (String) pageContext.getParameter("ASNReqFrmRelPtyId");
    String relId = (String) pageContext.getParameter("ASNReqFrmRelId");
    String partySiteId = (String) pageContext.getParameter("ASNReqFrmSiteId");
    if (partySiteId == null)
    {
      partySiteId = (String)pageContext.getTransactionValue("ASNReqFrmSiteIdTXN"); 
    }
    
    HashMap params = new HashMap();
     OAApplicationModule am = pageContext.getApplicationModule(webBean);

    if (pageContext.getParameter("ASNPageApyBtn") != null )
    {
        pageContext.getBreadCrumbValue();
      // Begin Mod Raam on 06.14.2006
      // Warning page should be rendered only when updating a shared party site.
      String addrEvnt = pageContext.getParameter("HzPuiAddressEvent");
      if (isProcLogEnabled)
      {
        StringBuffer logMsg = new StringBuffer(100);
        logMsg.append("uRL Param: HzPuiAddressEvent: ");
        logMsg.append(addrEvnt);
        String breadcrumbval = pageContext.getBreadCrumbValue();
        logMsg.append("On click of Apply Bread Brumb Value is :");
        logMsg.append(breadcrumbval);
        
        pageContext.writeDiagnostics(METHOD_NAME, logMsg.toString(), OAFwkConstants.PROCEDURE);
      }

      // Variable commitFlag is initiated to indicate if the changes are to be
      // commited when apply button is clicked. This flag will be set to true
      // when location is NOT shared by multiple parties and when this page is
      // launched in CREATE mode.
      boolean commitFlag = false;

      if ("UPDATE".equals(addrEvnt)) // When apply is clicked to update an existing address.
      {
        String updLocId = pageContext.getParameter("HzPuiAddressLocationId");
        if (isProcLogEnabled)
        {
          StringBuffer logMsg = new StringBuffer(100);
          logMsg.append("uRL Param: HzPuiAddressLocationId: ");
          logMsg.append(updLocId);
          
          pageContext.writeDiagnostics(METHOD_NAME, logMsg.toString(), OAFwkConstants.PROCEDURE);
        }

        // Call AM Method to find out if the location in context is shared by 
        // multiple parties.
       
        String isLocShared = "N";
        Serializable[] parameters =  { relPartyId, updLocId };
        //isLocShared = (String)am.invokeMethod("isSharedLocation", parameters);
        if (isProcLogEnabled)
        {
          StringBuffer logMsg = new StringBuffer(100);
          logMsg.append("Value returned by AM method isSharedLocation is : ");
          logMsg.append(isLocShared);
          pageContext.writeDiagnostics(METHOD_NAME, logMsg.toString(), OAFwkConstants.PROCEDURE);
        }

        if ("Y".equals(isLocShared)) // When location is shared by multiple parties
        {
          // The user has clicked a "Apply" button so we want to display a "Warning"
          // dialog asking if user really wants to update the Party Site.  Note that we
          // configure the dialog so that pressing the "Yes" button submits to
          // this page so we can handle the action in this processFormRequest( ) method.
          OAException mainMessage = new OAException("ASN", "ASN_US_SHARED_LOC_UPD_WARNING");

          // Note that even though we're going to make our Yes/No buttons submit a
          // form, we still need some non-null value in the constructor's Yes/No
          // URL parameters for the buttons to render, so we just pass empty
          // Strings for this.

          OADialogPage dialogPage = new OADialogPage(OAException.WARNING, // messageType
                                                     mainMessage,         // descriptionMessage
                                                     null,                // instructionMessage
                                                     "",                  // okButtonUrl
                                                     "");                 // noButtonUrl

          // We set this value so the code that handles this button press is
          // descriptive.
          dialogPage.setOkButtonItemName("ASNAddressUpdateYes");
          dialogPage.setNoButtonItemName("ASNAddressUpdateNo");

          // The following configures the Yes/No buttons to be submit buttons,
          // and makes sure that we handle the form submit in the originating
          // page (the "Purchase Orders" summary) so we can handle the "Yes"
          // button selection in this controller.

          dialogPage.setOkButtonToPost(true);
          dialogPage.setNoButtonToPost(true);
          dialogPage.setPostToCallingPage(true);

          // Always use Message Dictionary for any Strings you want to display.
          String yes = pageContext.getMessage("FND", "FND_DIALOG_YES", null);
          String no = pageContext.getMessage("FND", "FND_DIALOG_NO", null);

          // Now set our Yes/No labels instead of the default OK/Cancel.
          dialogPage.setOkButtonLabel(yes);
          dialogPage.setNoButtonLabel(no);

          /*
          Hashtable formParams = new Hashtable(7);
          formParams.put("ASNReqFrmCustId", objPartyId);
          formParams.put("ASNReqFrmCustName", objPartyName);
          formParams.put("ASNReqFrmCtctId", subPartyId);
          formParams.put("ASNReqFrmCtctName", subPartyName);
          formParams.put("ASNReqFrmRelPtyId", relPartyId);
          formParams.put("ASNReqFrmRelId", relId);
          formParams.put("ASNReqFrmResubmit", "N");
          formparams.put("HzPuiAddressPartyId", relPartyId);
          formparams.put("HzPuiAddressEvent" , "UPDATE");
          formparams.put("HzPuiAddressLocationId", pageContext.getParameter("HzPuiAddressViewLocationId"));
          formparams.put("HzPuiAddressPartySiteId", pageContext.getParameter("HzPuiAddressViewPartySiteId"));
          dialogPage.setFormParameters(formParams);
          */

          pageContext.redirectToDialogPage(dialogPage);
        }
        else // When location is NOT shared by multiple location
        {
          commitFlag = true;
        }
      }
      else  // When apply is clicked to create a new address.
      {

         commitFlag = true;
      }

      if (commitFlag)
      {

       if (partySiteId == null)
       {
         String partyId = (String) pageContext.getParameter("ASNReqFrmCustId");
          Serializable aserializable[] = { partyId };
            partySiteId = 
                    (String)am.invokeMethod("getPartySiteId", aserializable);
            pageContext.writeDiagnostics(METHOD_NAME, "Party Site Id from am.getPartySiteId  : "+partySiteId , OAFwkConstants.PROCEDURE); 
            //pageContext.putParameter("ASNReqFrmSiteId","259784");
            pageContext.putParameter("ASNReqFrmSiteId", partySiteId);
             pageContext.putTransactionValue("ASNReqFrmSiteIdTXN", 
                                                 partySiteId);
       }
        // commit
       // doCommit(pageContext);
       OAViewObject partysiterelationshipvo = 
                  (OAViewObject)am.findViewObject("ODPartySiteExtRelationshipVO");

                  if (partysiterelationshipvo == null) {
                      MessageToken[] token = 
                      { new MessageToken("OBJECT_NAME", "ODPartySiteExtRelationshipVO") };
                      throw new OAException("AK", "FWK_TBX_OBJECT_NOT_FOUND", token);
                  }

                  Serializable[] relparams = { partySiteId,relId };
                  partysiterelationshipvo.invokeMethod("initQuery", relparams);

                     int recordcount = partysiterelationshipvo.getRowCount();


                   
                    if ( recordcount > 0)
                    {
 
                        Serializable[] parameters =  { partySiteId };   
                        String partySiteAddr = (String) am.invokeMethod("getPartySiteAddr", parameters);
                        Serializable[] contactparameters =  { subPartyId };  
                        String contactName = (String) am.invokeMethod("getPartyNameFromId", contactparameters);//"Jasmine Test";
    
                        MessageToken[] tokens = { new MessageToken("NAME", contactName), new MessageToken("ADDRESS", partySiteAddr)};
                        throw new OAException("XXCRM", "XX_SFA_055_DUPLICATE_SITE_CTCT", tokens);
                    }
                    else
                    {
                        Serializable [] parameters = { partySiteId,relId};        
                        pageContext.writeDiagnostics(METHOD_NAME, "Inside ASNPageSelBtn event ", 2);                     
                        pageContext.writeDiagnostics(METHOD_NAME, "Party Site Id", 2);
                        pageContext.writeDiagnostics(METHOD_NAME, partySiteId, 2);                      
                        am.invokeMethod("insertRecords", parameters);
                        am.invokeMethod("applyTransaction");
        
                    }

        processTargetURL(pageContext, null, params);
      }
    }
    else if (pageContext.getParameter("ASNAddressUpdateYes") != null )
    {
      // commit
      doCommit(pageContext);

      processTargetURL(pageContext, null, params);
    }
    else if (pageContext.getParameter("ASNAddressUpdateNo") != null )
    {
      processTargetURL(pageContext, null, params);
    }
    // End Mod.
    else if (pageContext.getParameter("ASNPageSvCrteAnotherBtn") != null )
    {
      // commit
      //doCommit(pageContext);

       OAViewObject partysiterelationshipvo = 
                  (OAViewObject)am.findViewObject("ODPartySiteExtRelationshipVO");

                  if (partysiterelationshipvo == null) {
                      MessageToken[] token = 
                      { new MessageToken("OBJECT_NAME", "ODPartySiteExtRelationshipVO") };
                      throw new OAException("AK", "FWK_TBX_OBJECT_NOT_FOUND", token);
                  }

                  Serializable[] relparams = { partySiteId,relId };
                  partysiterelationshipvo.invokeMethod("initQuery", relparams);
                  /* Jasmine Fix for Tracker Row 217 */
                  //int recordcount = partysiterelationshipvo.getFetchedRowCount();
                  int recordcount = partysiterelationshipvo.getRowCount();

                   
                    if ( recordcount > 0)
                    {
 
                        Serializable[] parameters =  { partySiteId };   
                        String partySiteAddr = (String) am.invokeMethod("getPartySiteAddr", parameters);
                        Serializable[] contactparameters =  { subPartyId };  
                        String contactName = (String) am.invokeMethod("getPartyNameFromId", contactparameters);//"Jasmine Test";
    
                        MessageToken[] tokens = { new MessageToken("NAME", contactName), new MessageToken("ADDRESS", partySiteAddr)};
                        throw new OAException("XXCRM", "XX_SFA_055_DUPLICATE_SITE_CTCT", tokens);
                    }
                    else
                    {
                        Serializable [] parameters = { partySiteId,relId};        
                        pageContext.writeDiagnostics(METHOD_NAME, "Inside ASNPageSelBtn event ", 2);                     
                        pageContext.writeDiagnostics(METHOD_NAME, "Party Site Id", 2);
                        pageContext.writeDiagnostics(METHOD_NAME, partySiteId, 2);                      
                        am.invokeMethod("insertRecords", parameters);
                        am.invokeMethod("applyTransaction");
        
                    }

      //The following three paramters are created by TCA when rendering this page.
      //Since their controller will not be executed during save and create another
      //action, these parameters should be removed before forwarding to the same
      //page.
      pageContext.removeParameter("HzPuiAddressExist");
      pageContext.removeParameter("HzPuiOrgCompositeExist"); 
      pageContext.removeParameter("hzCountry");

      params.put("ASNReqFrmCustId",objPartyId);
      params.put("ASNReqFrmCustName", objPartyName);
      params.put("ASNReqFrmCtctId",subPartyId);
      params.put("ASNReqFrmCtctName", subPartyName);
      params.put("ASNReqFrmRelPtyId",relPartyId);
      params.put("ASNReqFrmRelId", relId);
      params.put("HzPuiAddressPartyId", relPartyId);
      params.put("HzPuiAddressEvent", "CREATE");
      params.put("HzPuiPartySiteId", null);
	    params.put("HzPuiLocationId", null);
      params.put("HzPuiPartySiteUseId", null);
      pageContext.forwardImmediatelyToCurrentPage(params,
                    false,
                    ADD_BREAD_CRUMB_SAVE);
    }

    else if (pageContext.getParameter("ASNPageCnclBtn") != null )
    {
         if (isProcLogEnabled)
      {
        StringBuffer logMsg = new StringBuffer(100);
        
        String breadcrumbval = pageContext.getBreadCrumbValue();
        logMsg.append("On click of Apply Bread Brumb Value is :");
        logMsg.append(breadcrumbval);
        
        pageContext.writeDiagnostics(METHOD_NAME, logMsg.toString(), OAFwkConstants.PROCEDURE);
      }
      
      processTargetURL(pageContext,null,null);
    }
	 if (isProcLogEnabled) {
	    pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
	 }

  }

}
