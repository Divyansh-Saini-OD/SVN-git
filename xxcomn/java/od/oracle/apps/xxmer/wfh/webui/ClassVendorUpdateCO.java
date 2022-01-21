/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxmer.wfh.webui;

import java.io.Serializable;

import oracle.jbo.domain.Number;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;

import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

/**
 * Controller for ...
 */
public class ClassVendorUpdateCO extends OAControllerImpl
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
    super.processRequest(pageContext, webBean);
     // If isBackNavigationFired = false, we're here after a valid navigation
     // (the user selected the Update icon) and we should proceed
     // normally and initialize a new planner.
     if (!pageContext.isBackNavigationFired(false))
     {
        // We indicate that we are starting the create transaction (this
        // is used to ensure correct Back button behavior).
        TransactionUnitHelper.startTransactionUnit(pageContext, "merchClassVendorUpdateTxn");

        // This test ensures that we don't try to create a new planner if
        // we had a JVM failover, or if a recyled application module
        // is activated after passivation.  If this things happen, BC4J will
        // be able to find the row that you created so the user can resume
        // work.
        if (!pageContext.isFormSubmission())
        {
          String merchClassId = pageContext.getParameter("merchClassId");
          String vendorSiteId = pageContext.getParameter("vendorSiteId");
          Serializable[] parameters = { merchClassId, vendorSiteId };

          OAApplicationModule am = pageContext.getApplicationModule(webBean);
          am.invokeMethod("prepUpdateClassVendorVO", parameters);
        }
      }
      else
      {
        if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, "merchClassVendorUpdateTxn", true))
        {
          // We got here through some use of the browser "Back" button, so we
          // want to display a stale data error and disallow access to the page.

          // If this were a real application, we would probably display a more
          // context-specific message telling the user she can't use the browser
          // "Back" button and the "Create" page.  Instead, we wanted to illustrate
          // how to display the Applications standard STATE LOSS ERROR message.
          OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
          pageContext.redirectToDialogPage(dialogPage);
        }
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
    super.processFormRequest(pageContext, webBean);

    OAApplicationModule am = pageContext.getApplicationModule(webBean);

    // Pressing the "Apply" button means the transaction should be validated
    // and committed.
    if (pageContext.getParameter("Apply") != null)
    {
      OAViewObject vo = (OAViewObject)am.findViewObject("UpdateClassVendorVO1");

      // Note that we have to get this value from the VO because the EO will
      // assemble it during its validation cycle.

      Number merchClassId = (Number)vo.getCurrentRow().getAttribute("MerchClassId");
      String merchClass = String.valueOf(merchClassId.intValue());
      Number vendorSiteId = (Number)vo.getCurrentRow().getAttribute("VendorSiteId");
      String vendorSite = String.valueOf(vendorSiteId.intValue());

	    // Simply telling the transaction to commit will cause all the Entity Object validation
	    // to fire.
	    //
	    // Note: there's no reason for a developer to perform a rollback.  This is handled by
	    // the framework if errors are encountered.
      am.invokeMethod("apply");

      // Indicate that the Update transaction is complete.
      TransactionUnitHelper.endTransactionUnit(pageContext, "merchClassVendorUpdateTxn");

      // Assuming the "commit" succeeds, navigate back to the "PlannerHierarchy" page
      // and display a "Confirmation" message at the top of the page.

      MessageToken[] msgTokens = {new MessageToken("MERCH_CLASS", merchClass), new MessageToken("VENDOR", vendorSite)};
      OAException confirmMessage = new OAException("XXMER", "XX_WFH_CONFIRM_UPDATE_MCV", msgTokens, OAException.CONFIRMATION, null);
       // Per the UI guidelines, we want to add the confirmation message at the
       // top of the search/results page and we want the old search criteria and
       // results to display.
       pageContext.putDialogMessage(confirmMessage);

       //Refresh the view
       if (vo != null)
       {
         vo.executeQuery();
       }
    }
    else if (pageContext.getParameter("Cancel") != null)
    {
       am.invokeMethod("rollback");
       TransactionUnitHelper.endTransactionUnit(pageContext, "merchClassVendorUpdateTxn");

       pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxmer/wfh/webui/ClassVendorSearchPG",
                                      null,
                                      OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                      null,
                                      null,
                                      true, // retain AM
                                      OAWebBeanConstants.ADD_BREAD_CRUMB_NO);
    }
  }

}
