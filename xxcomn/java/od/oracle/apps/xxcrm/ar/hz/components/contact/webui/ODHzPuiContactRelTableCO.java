/*===========================================================================+
 |      Copyright (c) 2001 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY
 |            Created Satyasrinivas
 +===========================================================================*/
//package oracle.apps.ar.hz.components.contact.webui;
package od.oracle.apps.xxcrm.ar.hz.components.contact.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import java.io.Serializable;
import oracle.jbo.common.Diagnostic;
import oracle.apps.fnd.framework.OAApplicationModule;

import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.webui.beans.form.OAFormValueBean;
import java.util.Hashtable;
import java.util.Enumeration;
import com.sun.java.util.collections.HashMap;

import oracle.apps.fnd.framework.webui.beans.layout.OARowLayoutBean;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.OANLSServices;
import oracle.apps.fnd.framework.server.OADBTransaction;

import oracle.apps.fnd.framework.OAViewObject;

/**
 * Controller for ...
 */
public class ODHzPuiContactRelTableCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header: ODHzPuiContactRelTableCO.java 115.23 2004/06/16 18:15:09 tsli noship $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /**
   * Layout and page setup logic for AK region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    OAApplicationModule am = pageContext.getApplicationModule(webBean);

       OAViewObject HzPuiContactRelTableVO = (OAViewObject)am.findViewObject("HzPuiContactRelTableVO");
       HzPuiContactRelTableVO.remove();
	   HzPuiContactRelTableVO = (OAViewObject)am.createViewObject("HzPuiContactRelTableVO",
            "od.oracle.apps.xxcrm.ar.hz.components.contact.server.ODHzPuiContRelTableVO");

            /* OAViewObject HzPuiContactRelTableVO = (OAViewObject)am.findViewObject("HzPuiContRelTableVO");
			       if (HzPuiContactRelTableVO !=null){HzPuiContactRelTableVO.remove();}
			           HzPuiContactRelTableVO = (OAViewObject)am.createViewObject("HzPuiContRelTableVO",
			            "od.oracle.apps.xxcrm.ar.hz.components.contact.server.ODHzPuiContRelTableVO");*/


    Diagnostic.println("ODHzPuiContactRelTableCO: Inside proces request");
    Diagnostic.println("Testing provider pickup - ODHzPuiContactRelTableCO: Inside proces request");

    super.processRequest(pageContext, webBean);

    //OAApplicationModule am = pageContext.getApplicationModule(webBean);

    String relationshipGroup = pageContext.getParameter("HzPuiContRelTableRelGroupCode");
    String partyType = pageContext.getParameter("HzPuiContRelTableObjectPartyType");
    String subjectId = pageContext.getParameter("HzPuiContRelTableObjectPartyId");
    String subjectPartyType = pageContext.getParameter("HzPuiContRelTableSubjectPartyType");

    if ((partyType == null) || partyType.equals(""))
    {
      Serializable[] partyParameters =  { subjectId };
      partyType = (String) am.invokeMethod("initPartyTypeQuery", partyParameters);
    }

    //All parameters passed using invokeMethod() must be serializable.
    Serializable[] parameters1 =  { relationshipGroup, partyType, subjectPartyType};

    am.invokeMethod("initQuery", parameters1);

    if ("HISTORY".equals(pageContext.getParameter("HzPuiContRelTableMode")))
    {

	    String role = pageContext.getParameter("HzPuiContRelTableRole");
      String code = pageContext.getParameter("HzPuiContRelTableRelGroupCode");
      String searchOption = pageContext.getParameter("search_dropdown");
      String searchInput = pageContext.getParameter("searchinput");

      Diagnostic.println("ODHzPuiContactRelTableCO: Inside process request - Go Button clicked");
      Diagnostic.println("ODHzPuiContactRelTableCO: Inside process request - AM Name: " + am.getName());

      // Hide Row Layout

      Diagnostic.println("ODHzPuiContactRelTableCO: Inside process request - Hiding layout bean ");

      OARowLayoutBean layoutBean =
        (OARowLayoutBean) webBean.findChildRecursive("ContactTableRL");

      if( layoutBean != null && layoutBean.isRendered())
        layoutBean.setRendered(false);

      // Hide Update and Remove

      OATableBean  contactTable =
        (OATableBean) webBean.findIndexedChildRecursive("HzPuiContactRelTable");

      if( contactTable != null && contactTable.isRendered())
        {
           OAWebBean updateSwitcher =
              contactTable.findIndexedChildRecursive("update_switcher");
              //column to be hide

           if( updateSwitcher != null && updateSwitcher.isRendered() )
              updateSwitcher.setRendered(false);

           OAWebBean removeSwitcher =
              contactTable.findIndexedChildRecursive("remove_switcher");
              //column to be hide

           if( removeSwitcher != null && removeSwitcher.isRendered() )
              removeSwitcher.setRendered(false);

           OAWebBean restoreBtn =
              contactTable.findIndexedChildRecursive("restore");
              //column to be shown

           if( restoreBtn != null && (!restoreBtn.isRendered()) )
              restoreBtn.setRendered(true);
        }

      // All parameters passed using invokeMethod() must be serializable.

	    Serializable[] parameters =  { "HISTORY", partyType, subjectPartyType, code, role, subjectId , searchOption, searchInput};
      am.invokeMethod("initTableQuery", parameters);

    } else if ("CURRENT".equals(pageContext.getParameter("HzPuiContRelTableMode")))
    {

      Diagnostic.println("ODHzPuiContactRelTableCO: Inside process request - Go Button clicked");

      OAMessageChoiceBean choiceBean =
        (OAMessageChoiceBean) webBean.findChildRecursive("HzPuiContTableCreateRelRole");

      if( choiceBean != null)
        {
          choiceBean.setPickListCacheEnabled(false);
          choiceBean.setRequiredIcon("no");
          choiceBean.setDefaultValue(null);
        }

	    String role = pageContext.getParameter("HzPuiContRelTableRole");
      String code = pageContext.getParameter("HzPuiContRelTableRelGroupCode");
      String searchOption = pageContext.getParameter("search_dropdown");
      String searchInput = pageContext.getParameter("searchinput");

      // Perform query only on first pass

      if (pageContext.getParameter("hzPuiRelTableExist") == null)
      {
         Diagnostic.println("ODHzPuiContactRelTableCO: Inside process request - before doing query");

         searchOption = pageContext.getParameter("HzPuiContSearchOption");
         searchInput = pageContext.getParameter("HzPuiContSearchInput");

         // All parameters passed using invokeMethod() must be serializable.
	       Serializable[] parameters =  { "CURRENT", partyType, subjectPartyType, code, role, subjectId , searchOption, searchInput};
         am.invokeMethod("initTableQuery", parameters);
      }
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
    Diagnostic.println("ODHzPuiContactRelTableCO: Inside process form request");

    if (pageContext.getParameter("HzPuiContRelTableDeleteEvent") != null)
      Diagnostic.println("Inside Contact process form request HzPuiContRelTableDeleteEvent:" + pageContext.getParameter("HzPuiContRelTableDeleteEvent"));

    if (pageContext.getParameter("HzPuiRelationshipId") != null)
      Diagnostic.println("Inside Contact process form request HzPuiRelationshipId:" + pageContext.getParameter("HzPuiRelationshipId"));

    super.processFormRequest(pageContext, webBean);

    OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);

    if ((pageContext.getParameter("HzPuiRelationshipDeleteYes") != null) ||
        ("HzPuiRelationshipRestore".equals(pageContext.getParameter("HzPuiContRelTableRestoreEvent"))))
    {
        String relationshipId = pageContext.getParameter("HzPuiRelationshipId");
        String relationshipValue = pageContext.getParameter("hzPuiRelName");
        String relationshipRoleMeaning = pageContext.getParameter("hzPuiRelRole");

        Diagnostic.println("get HzPuiRelationshipDeleteYes event , RelationshipId = " + relationshipId);

        //All parameters passed using invokeMethod() must be serializable.

        Serializable[] parameters =  { relationshipId };
        am.invokeMethod("deleteRelationships", parameters);

        // show confirmation

        if ("HzPuiRelationshipRestore".equals(pageContext.getParameter("HzPuiContRelTableRestoreEvent")))
          {
            MessageToken[] token = {new MessageToken("DISPLAY_VALUE", relationshipValue + ", " + relationshipRoleMeaning)};
            OAException message =  new OAException("AR","HZ_PUI_RESTORE_CONFIRMATION", token,OAException.CONFIRMATION, null);
            pageContext.putDialogMessage(message);
          }
        else
          {
            MessageToken[] token = {new MessageToken("DISPLAY_VALUE", relationshipValue + ", " + relationshipRoleMeaning)};
            OAException message =  new OAException("AR","HZ_PUI_REMOVE_CONFIRMATION", token,OAException.CONFIRMATION, null);
            pageContext.putDialogMessage(message);
          }

    }
    else if ("HzPuiRelationshipDelete".equals(pageContext.getParameter("HzPuiContRelTableDeleteEvent")))
    {
        Diagnostic.println("delete icon clicked");

      // The user has clicked a "Delete" icon so we want to display a "Warning"
      // dialog asking if she really wants to delete the PO.  Note that we
      // configure the dialog so that pressing the "Yes" button submits to
      // this page so we can handle the action in this processFormRequest( ) method.

      String HzPuiRelationshipId = pageContext.getParameter("HzPuiRelationshipId");
      String relationshipName = pageContext.getParameter("hzPuiRelName");
      String relationshipRoleMeaning = pageContext.getParameter("hzPuiRelRole");
      String objectPartyType = pageContext.getParameter("hzPuiRelType");

      java.util.Date utilDate = new java.util.Date();
      java.sql.Date sqlDate = new java.sql.Date(utilDate.getTime());
      oracle.jbo.domain.Date jboDate = new oracle.jbo.domain.Date(sqlDate);

      OADBTransaction transaction = (OADBTransaction)am.getOADBTransaction();

      OANLSServices nlsServices = transaction.getOANLSServices();

      MessageToken[] tokens = { new MessageToken("PARTY_NAME", relationshipName) ,
                                new MessageToken("ROLE", relationshipRoleMeaning),
                                new MessageToken("SYSDATE", nlsServices.dateToString(jboDate))};

      OAException mainMessage;

      if (objectPartyType.equals("ORGANIZATION"))
      {
         mainMessage = new OAException("AR", "HZ_PUI_REMOVE_REL_ORG_WARNING", tokens);
      } else
      {
         mainMessage = new OAException("AR", "HZ_PUI_REMOVE_REL_PER_WARNING", tokens);
      }
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

     dialogPage.setOkButtonItemName("HzPuiRelationshipDeleteYes");

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

     java.util.Hashtable formParams = new java.util.Hashtable(1);

     formParams.put("HzPuiRelationshipId", HzPuiRelationshipId);
     formParams.put("hzPuiRelName", relationshipName);
     formParams.put("hzPuiRelRole", relationshipRoleMeaning);
     formParams.put("HzPuiResubmitFlag", "YES");

     dialogPage.setFormParameters(formParams);

     //Following code is added to fix the problem of loosing context
     //when rendering a Dialog page
     String sRegionRefName = (String) pageContext.getParameter("HzPuiContactRelRegionRef");
     if ( sRegionRefName != null && sRegionRefName.length() > 0 )
          dialogPage.setHeaderNestedRegionRefName(sRegionRefName);

     pageContext.redirectToDialogPage(dialogPage);

    } else if (pageContext.getParameter("HzPuiContRelTableSearchButton") != null)
    {
	    String role = pageContext.getParameter("role");
      String code = pageContext.getParameter("HzPuiContRelTableRelGroupCode");
      String subjectId = pageContext.getParameter("HzPuiContRelTableObjectPartyId");
      String searchOption = pageContext.getParameter("search_dropdown");
      String searchInput = pageContext.getParameter("searchinput");
      String subjectPartyType = pageContext.getParameter("HzPuiContRelTableSubjectPartyType");
      String partyType = pageContext.getParameter("HzPuiContRelTableObjectPartyType");

      Diagnostic.println("ODHzPuiContactRelTableCO: Inside process form request - Go Button clicked");

//      OAApplicationModule am = pageContext.getApplicationModule(webBean);

      Diagnostic.println("ODHzPuiContactRelTableCO: Inside process form request - AM Name: " + am.getName());

      HashMap h = new HashMap(1);
      h.put("hzPuiRelTableExist", "YES");

      // All parameters passed using invokeMethod() must be serializable.

	    Serializable[] parameters =  { "CURRENT", partyType, subjectPartyType, code, role, subjectId , searchOption, searchInput};
      am.invokeMethod("initTableQuery", parameters);


      // Now redirect back to this page so we can implement UI changes as a
      // consequence of the query in processRequest().  NEVER make UI changes in
      // processFormRequest().

      pageContext.setForwardURLToCurrentPage(h,
                                             true, // retain the AM
                                             ADD_BREAD_CRUMB_NO,
                                             IGNORE_MESSAGES);


    }

  }

}
