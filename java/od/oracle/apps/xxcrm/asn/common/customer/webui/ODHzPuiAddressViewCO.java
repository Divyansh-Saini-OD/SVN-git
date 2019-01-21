/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODHzPuiAddressViewCO.java                                     |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Controller Object for the Address Region in the                        |
 |    View/Update Contact PageCreate Update Region.                          |
 |                                                                           |
 |  NOTES                                                                    |
 |         Used for the Customization on the View/Update Contact Page        |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    No dependencies.                                                       |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    11-Oct-2007 Jasmine Sujithra   Created                                 |
 |    19-Feb-2008 Anirban Chaudhuri  Modified for Contact's Security.        |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.common.customer.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import java.io.Serializable;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.beans.form.OAFormValueBean;
import oracle.jbo.common.Diagnostic;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.OANLSServices;



/**
 * Controller for ...
 */
public class ODHzPuiAddressViewCO extends OAControllerImpl
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

    final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODHzPuiAddressViewCO.processRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }
    super.processRequest(pageContext, webBean);

    if (isStatLogEnabled)
      {
        StringBuffer logMsg = new StringBuffer(100);
        String addrEvnt = pageContext.getParameter("HzPuiAddressEvent");
        String addrComponentMode = pageContext.getParameter("HzPuiAddressComponentMode");
        logMsg.append("uRL Param: HzPuiAddressEvent: ");
        logMsg.append(addrEvnt);
        logMsg.append("uRL Param: HzPuiAddressComponentMode: ");
        logMsg.append(addrComponentMode);
        pageContext.writeDiagnostics(METHOD_NAME, logMsg.toString(), OAFwkConstants.PROCEDURE);
      }
    Diagnostic.println("Calling HzPuiAddressViewCO");

    if ("ViewAddress".equals(pageContext.getParameter("HzPuiAddressEvent")))
    {
      OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);

      String partyId = pageContext.getParameter("HzPuiAddressPartyId");

      Serializable[] parameters =  { partyId };

      am.invokeMethod("initAddressViewQuery", parameters);
  
      // set the partyId to formValue
      OAFormValueBean formValueBean = (OAFormValueBean) webBean.findIndexedChildRecursive("HzPuiAddressViewPartyId");
      formValueBean.setText(pageContext, partyId);
      
      //Added as per bug #5870953
      if((pageContext.getParameter("HzPuiDisplayPartySiteNumber") != null) && "Show".equals(pageContext.getParameter("HzPuiDisplayPartySiteNumber"))) {
          OAWebBean psn = webBean.findChildRecursive("PartySiteNumber");
          if (psn != null)
          {
            psn.setRendered(true);
          }
      }
    }
    if("LOV".equals(pageContext.getParameter("HzPuiAddressComponentMode")))
    {
      //single selection is on
      //hide view removed button
      OAWebBean vrmBtn = webBean.findChildRecursive("HzPuiViewInactiveButton");
      if(vrmBtn != null)
      {
        vrmBtn.setRendered(false);
      }
      //hide view by purpose button
      OAWebBean vbpBtn = webBean.findChildRecursive("HzPuiSelectPrimaryUseButton");
      if(vbpBtn != null)
      {
        vbpBtn.setRendered(false);
      }
    }
    else if("VIEW".equals(pageContext.getParameter("HzPuiAddressComponentMode")))
    {
      //RO version
      //hide create button
      OAWebBean crBtn = webBean.findChildRecursive("HzPuiCreateButton");
      if(crBtn != null)
      {
        crBtn.setRendered(false);
      }
      //hide view removed button
      OAWebBean vrmBtn = webBean.findChildRecursive("HzPuiViewInactiveButton");
      if(vrmBtn != null)
      {
        vrmBtn.setRendered(false);
      }
      //hide view by purpose button
      OAWebBean vbpBtn = webBean.findChildRecursive("HzPuiSelectPrimaryUseButton");
      if(vbpBtn != null)
      {
        vbpBtn.setRendered(false);
      }
      //hide selection column
      OAWebBean ssb = webBean.findChildRecursive("singleAddressSelection");
      if (ssb != null)
      {
        ssb.setRendered(false);
      }
      //hide update column
      OAWebBean upd = webBean.findChildRecursive("updateSwitcher");
      if (upd != null)
      {
        upd.setRendered(false);
      }
      //hide remove column
      OAWebBean rmv = webBean.findChildRecursive("removeSwitcher");
      if (rmv != null)
      {
        rmv.setRendered(false);
      }
    }
    else
    {
       //hide selection column
       OAWebBean ssb = webBean.findChildRecursive("singleAddressSelection");
       if (ssb != null)
       {
         ssb.setRendered(false);
       }
    }
      pageContext.writeDiagnostics(METHOD_NAME, "Show the Update and Remove Icons", OAFwkConstants.PROCEDURE);
     //show update column
      OAWebBean upd = webBean.findChildRecursive("updateSwitcher");
      if (upd != null)
      {
        pageContext.writeDiagnostics(METHOD_NAME, "updateSwitcher found", OAFwkConstants.PROCEDURE);
        upd.setRendered(true);
      }
      //show remove column
      OAWebBean rmv = webBean.findChildRecursive("removeSwitcher");
      if (rmv != null)
      {
        pageContext.writeDiagnostics(METHOD_NAME, "removeSwitcher found", OAFwkConstants.PROCEDURE);
        rmv.setRendered(true);
      }

    //Anirban added for contact's security: Starts
    if("ReadOnlyMode".equals((String)pageContext.getTransactionValue("ROModeAddress")))
    {
     OAWebBean updReadOnlyMode = webBean.findChildRecursive("updateSwitcher");
     if (updReadOnlyMode != null)
     {
       pageContext.writeDiagnostics(METHOD_NAME, "AnirbanupdateSwitcher found", OAFwkConstants.PROCEDURE);
       updReadOnlyMode.setRendered(false);
     }
     OAWebBean rmvReadOnlyMode = webBean.findChildRecursive("removeSwitcher");
     if (rmvReadOnlyMode != null)
     {
      pageContext.writeDiagnostics(METHOD_NAME, "AnirbanremoveSwitcher found", OAFwkConstants.PROCEDURE);
      rmvReadOnlyMode.setRendered(false);
     }
     pageContext.removeTransactionValue("ROModeAddress");
	}
    //Anirban added for contact's security: Ends

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
    final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODHzPuiAddressViewCO.processFormRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }
    super.processFormRequest(pageContext, webBean);
    OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);

    if (pageContext.getParameter("HzPuiSelectPrimaryUseButton") != null )
      pageContext.putParameter("HzPuiAddressEvent", "ViewSiteUseTable");
    else if (pageContext.getParameter("HzPuiViewInactiveButton") != null )
      pageContext.putParameter("HzPuiAddressEvent", "ViewInactiveAddressTable");
    else if (pageContext.getParameter("HzPuiCreateButton") != null )
      pageContext.putParameter("HzPuiAddressEvent", "CREATE");
    if ("HzAddressRemove".equals(pageContext.getParameter("HzPuiAddressViewEvent")))
    {
      // The user has clicked a "Delete" icon so we want to display a "Warning"
      // dialog asking if she really wants to delete the PO.  Note that we 
      // configure the dialog so that pressing the "Yes" button submits to 
      // this page so we can handle the action in this processFormRequest( ) method.
      /*String hzPuiAddressViewPartySiteId = pageContext.getParameter("HzPuiAddressViewPartySiteId");            
      String formattedAddress = pageContext.getParameter("HzPuiFormattedAddress");      
      MessageToken[] tokens = { new MessageToken("FORMATTED_ADDRESS", formattedAddress) };
      OAException mainMessage = new OAException("AR", "HZ_PUI_REMOVE_ADDRESS_WARNING", tokens);

      // Note that even though we're going to make our Yes/No buttons submit a
      // form, we still need some non-null value in the constructor's Yes/No  
      // URL parameters for the buttons to render, so we just pass empty 
      // Strings for this.
      
      OADialogPage dialogPage = new OADialogPage(OAException.WARNING, 
                                                 mainMessage,
                                                 null, 
                                                 "", 
                                                 "");

     // Always use Message Dictionary for any Strings you want to display.
     
     String yes = pageContext.getMessage("FND", "FND_DIALOG_YES", null);
     String no = pageContext.getMessage("FND", "FND_DIALOG_NO", null);

     // We set this value so the code that handles this button press is 
     // descriptive.
     
     dialogPage.setOkButtonItemName("HzPuiPartySiteDeleteYes");

     // The following configures the Yes/No buttons to be submit buttons,
     // and makes sure that we handle the form submit in the originating
     // page (the "Purchase Orders" summary) so we can handle the "Yes"
     // button selection in this controller.
     
     dialogPage.setOkButtonToPost(true);
     dialogPage.setNoButtonToPost(true);
     dialogPage.setPostToCallingPage(true);

     // Now set our Yes/No labels instead of the default OK/Cancel.
     
     dialogPage.setOkButtonLabel(yes); 
     dialogPage.setNoButtonLabel(no); 

     // We need to keep hold of the poHeaderId, and the OADialogPage gives us a
     // convenient means of doing this.  Note that the use of the Hashtable is
     // really more appropriate for passing multiple parameters, but we've used
     // it here for illustration purposes.  See the OADialogPage javadoc for an
     // alternative when dealing with a single parameter.
     
     java.util.Hashtable formParams = new java.util.Hashtable(6); 
//     Hashtable formParams = getPageContextParameter(pageContext);     
     formParams.put("HzPuiAddressViewPartySiteId", hzPuiAddressViewPartySiteId); 
     formParams.put("HzPuiFormattedAddress", formattedAddress); 
     formParams.put("HzPuiResubmitFlag", "YES");

     dialogPage.setFormParameters(formParams); 

     //Following code is added to fix the problem of loosing context 
     //when rendering a Dialog page
     String sRegionRefName = (String) pageContext.getParameter("HzPuiAddressViewRegionRef");
     if ( sRegionRefName != null && sRegionRefName.length() > 0 )
          dialogPage.setHeaderNestedRegionRefName(sRegionRefName); 

     pageContext.redirectToDialogPage(dialogPage);*/
      
      
      String extensionId = pageContext.getParameter("ExtensionId");
      String relationshipName = pageContext.getParameter("ContRelName");
      String relationshipRoleMeaning = pageContext.getParameter("ContRelRole");
      String objectPartyType = pageContext.getParameter("ContRelType");
      String address = pageContext.getParameter("HzPuiFormattedAddress");

       if (isStatLogEnabled)
      {
        StringBuffer logMsg = new StringBuffer(100);
        logMsg.append("Inside HzAddressRemove - Remove icon clicked ");
        logMsg.append("ExtensionId : ");
        logMsg.append(extensionId);
        logMsg.append("ContRelName: ");
        logMsg.append(relationshipName);
        pageContext.writeDiagnostics(METHOD_NAME, logMsg.toString(), OAFwkConstants.PROCEDURE);
      }
      
      java.util.Date utilDate = new java.util.Date();
      java.sql.Date sqlDate = new java.sql.Date(utilDate.getTime());
      oracle.jbo.domain.Date jboDate = new oracle.jbo.domain.Date(sqlDate);

      OADBTransaction transaction = (OADBTransaction)am.getOADBTransaction();

      OANLSServices nlsServices = transaction.getOANLSServices();

      /*MessageToken[] tokens = { new MessageToken("PARTY_NAME", relationshipName) ,
                                new MessageToken("ROLE", relationshipRoleMeaning),
                                new MessageToken("SYSDATE", nlsServices.dateToString(jboDate))};*/
      MessageToken[] tokens = { new MessageToken("ADDRESS", address) };

      OAException mainMessage;

      mainMessage = new OAException("XXCRM", "XX_SFA_057_REMOVE_CTCT_ADDR", tokens);

      // Note that even though we're going to make our Yes/No buttons submit a
      // form, we still need some non-null value in the constructor's Yes/No
      // URL parameters for the buttons to render, so we just pass empty
      // Strings for this.

      OADialogPage dialogPage = new OADialogPage(OAException.WARNING,
                                                 mainMessage,
                                                 null,
                                                 "",
                                                 "");

     // Always use Message Dictionary for any Strings you want to display.

     String yes = pageContext.getMessage("FND", "FND_DIALOG_YES", null);
     String no = pageContext.getMessage("FND", "FND_DIALOG_NO", null);

     // We set this value so the code that handles this button press is
     // descriptive.

     dialogPage.setOkButtonItemName("RelationshipDeleteYes");
     // Bug # 4716012
     dialogPage.setNoButtonItemName("RelationshipDeleteNo");

     // The following configures the Yes/No buttons to be submit buttons,
     // and makes sure that we handle the form submit in the originating
     // page (the "Purchase Orders" summary) so we can handle the "Yes"
     // button selection in this controller.

     dialogPage.setOkButtonToPost(true);
     dialogPage.setNoButtonToPost(true);
     dialogPage.setPostToCallingPage(true);

     // Now set our Yes/No labels instead of the default OK/Cancel.

     dialogPage.setOkButtonLabel(yes);
     dialogPage.setNoButtonLabel(no);

     java.util.Hashtable formParams = new java.util.Hashtable(1);

     formParams.put("ExtensionId", extensionId);
     formParams.put("ContRelName", relationshipName);
     formParams.put("ContRelRole", relationshipRoleMeaning);
     formParams.put("ContResubmitFlag", "YES");

     dialogPage.setFormParameters(formParams);

     //Following code is added to retain the context
     //when rendering a Dialog page
     String sRegionRefName = (String) pageContext.getParameter("HzPuiContactRelRegionRef");
     if ( sRegionRefName != null && sRegionRefName.length() > 0 )
          dialogPage.setHeaderNestedRegionRefName(sRegionRefName);

     pageContext.redirectToDialogPage(dialogPage);


    }      
    else if (pageContext.getParameter("HzPuiPartySiteDeleteYes") != null)
    {
//        Diagnostic.println("!!!!!!!!!!!!!!!!!!!!!!!!inside evernt " );
      String partySiteId = pageContext.getParameter("HzPuiAddressViewPartySiteId");
      String formattedAddress = pageContext.getParameter("HzPuiFormattedAddress");      

      Diagnostic.println("get HzPuiPartySiteDeleteYes event , partySiteId = " + partySiteId);

      if ( partySiteId != null && partySiteId.trim()!= null )
      {

        Serializable[] parameters =  { partySiteId };
        am.invokeMethod("deletePartySite", parameters);

        MessageToken[] tokens = { new MessageToken("DISPLAY_VALUE", formattedAddress) };
        OAException message = new OAException("AR", "HZ_PUI_REMOVE_CONFIRMATION", tokens,
                                            OAException.CONFIRMATION, null);
        pageContext.putDialogMessage(message);
        
      }
    }
    else if("HzPuiAddressSelected".equals(pageContext.getParameter(EVENT_PARAM)))
    {
       Diagnostic.println("get HzPuiAddressSelected event");
       //following is the sample to get the the address and ids
       com.sun.java.util.collections.HashMap values = oracle.apps.ar.hz.components.util.server.HzPuiServerUtil.getSelectedAddress(am);
       if (values.size()!=0)
       {
          if(values.get("Address")!=null)
          {
            String address = values.get("Address").toString();
            Diagnostic.println("selected addrss is " + address);
          }
          if(values.get("PartySiteId")!=null)
          {
            String psId = values.get("PartySiteId").toString();
            Diagnostic.println("selected addrss PartySiteId is " + psId);
          }
          if(values.get("LocationId")!=null)
          {
            String locId = values.get("LocationId").toString();
            Diagnostic.println("selected addrss LocationId is " + locId);
          }
          if(values.get("LocationId")!=null)
          {
            String pId = values.get("PartyId").toString();
            Diagnostic.println("selected addrss PartyId is " + pId);
          }
       }
    }
    else  if (pageContext.getParameter("RelationshipDeleteYes") != null )
    {
        String partyId = pageContext.getParameter("HzPuiAddressPartyId");
        String extensionId = pageContext.getParameter("ExtensionId");
        String relationshipValue = pageContext.getParameter("ContRelName");
        String relationshipRoleMeaning = pageContext.getParameter("ContRelRole");        

         if (isStatLogEnabled)
      {
        StringBuffer logMsg = new StringBuffer(100);
        logMsg.append("Inside RelationshipDeleteYes - Delete Confirmed ");
        logMsg.append("Party Id : ");
        logMsg.append(partyId);
        logMsg.append("ExtensionId : ");
        logMsg.append(extensionId);
        logMsg.append("ContRelName: ");
        logMsg.append(relationshipValue);
        pageContext.writeDiagnostics(METHOD_NAME, logMsg.toString(), OAFwkConstants.PROCEDURE);
      }
        Diagnostic.println("get RelationshipDeleteYes event , ExtensionId = " + extensionId);

        //All parameters passed using invokeMethod() must be serializable.

        Serializable[] parameters =  { partyId,extensionId };
        am.invokeMethod("deleteRelationships", parameters);

        // show confirmation
        //MessageToken[] token = {new MessageToken("DISPLAY_VALUE", relationshipValue + ", " + relationshipRoleMeaning)};
        //OAException message =  new OAException("AR","HZ_PUI_REMOVE_CONFIRMATION", token,OAException.CONFIRMATION, null);
        //pageContext.putDialogMessage(message);
    }
    if (isProcLogEnabled)
    {
    pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }

  }

}
