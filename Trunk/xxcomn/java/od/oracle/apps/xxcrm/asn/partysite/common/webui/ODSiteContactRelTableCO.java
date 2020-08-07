/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODSiteContactRelTableCO.java                                    |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Controller class for site level contact relationship table region.     |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    No dependencies.                                                       |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    04/09/2007 Ashok Kumar   Created                                       |
 |    30/11/2007 Satyasrinivas Passing siteid from pageContext when          |
 |                              ContRelTableObjectPartySiteId is null         |                                                                    |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.partysite.common.webui;

//import com.sun.java.util.collections.HashMap;

import java.io.Serializable;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.OANLSServices;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import oracle.jbo.common.Diagnostic;
/**
 * Controller for ...
 */
public class ODSiteContactRelTableCO extends OAControllerImpl
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
    final String METHOD_NAME = "xxcrm.asn.partysite.common.webui.ODSiteContactRelTableCO.processRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    if (isProcLogEnabled)
    {
    pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processRequest(pageContext, webBean);

    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    String partySiteId = pageContext.getParameter("ContRelTableObjectPartySiteId");
    if (partySiteId == null) partySiteId = pageContext.getParameter("ASNReqFrmSiteId");
    Serializable[] parameters =  { partySiteId };
    am.invokeMethod("initTableQuery", parameters);

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
    Diagnostic.println("ODSiteContactRelTableCO: Inside process form request");

    if (pageContext.getParameter("ContRelTableDeleteEvent") != null)
      Diagnostic.println("Inside Contact process form request ContRelTableDeleteEvent:" + pageContext.getParameter("ContRelTableDeleteEvent"));

    if (pageContext.getParameter("ExtensionId") != null)
      Diagnostic.println("Inside Contact process form request ExtensionId:" + pageContext.getParameter("ExtensionId"));

    super.processFormRequest(pageContext, webBean);
    OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);

    if (pageContext.getParameter("RelationshipDeleteYes") != null )
    {
        String extensionId = pageContext.getParameter("ExtensionId");
        String relationshipValue = pageContext.getParameter("ContRelName");
        String relationshipRoleMeaning = pageContext.getParameter("ContRelRole");

        Diagnostic.println("get RelationshipDeleteYes event , ExtensionId = " + extensionId);

        //All parameters passed using invokeMethod() must be serializable.

        Serializable[] parameters =  { extensionId };
        am.invokeMethod("deleteRelationships", parameters);

        // show confirmation
        MessageToken[] token = {new MessageToken("DISPLAY_VALUE", relationshipValue + ", " + relationshipRoleMeaning)};
        OAException message =  new OAException("AR","HZ_PUI_REMOVE_CONFIRMATION", token,OAException.CONFIRMATION, null);
        pageContext.putDialogMessage(message);
    }
    else if ("RelationshipDelete".equals(pageContext.getParameter("ContRelTableDeleteEvent")))
    {
        Diagnostic.println("delete icon clicked");

      // The user has clicked a "Delete" icon so we want to display a "Warning"
      // dialog asking if she really wants to delete the PO.  Note that we
      // configure the dialog so that pressing the "Yes" button submits to
      // this page so we can handle the action in this processFormRequest( ) method.

      String extensionId = pageContext.getParameter("ExtensionId");
      String relationshipName = pageContext.getParameter("ContRelName");
      String relationshipRoleMeaning = pageContext.getParameter("ContRelRole");
      String objectPartyType = pageContext.getParameter("ContRelType");

      java.util.Date utilDate = new java.util.Date();
      java.sql.Date sqlDate = new java.sql.Date(utilDate.getTime());
      oracle.jbo.domain.Date jboDate = new oracle.jbo.domain.Date(sqlDate);

      OADBTransaction transaction = (OADBTransaction)am.getOADBTransaction();

      OANLSServices nlsServices = transaction.getOANLSServices();

      MessageToken[] tokens = { new MessageToken("PARTY_NAME", relationshipName) ,
                                new MessageToken("ROLE", relationshipRoleMeaning),
                                new MessageToken("SYSDATE", nlsServices.dateToString(jboDate))};

      OAException mainMessage;

      mainMessage = new OAException("AR", "HZ_PUI_REMOVE_REL_PER_WARNING", tokens);

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
  }

}
