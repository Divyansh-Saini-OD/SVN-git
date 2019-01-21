package od.oracle.apps.xxmer.wfh.webui;
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
public class PlannerAddCO extends OAControllerImpl
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
     // (the user selected the Add Planner button) and we should proceed 
     // normally and initialize a new planner.
     if (!pageContext.isBackNavigationFired(false))
     {
        // We indicate that we are starting the create transaction (this 
        // is used to ensure correct Back button behavior).
        TransactionUnitHelper.startTransactionUnit(pageContext, "plannerAddTxn");
      
        // This test ensures that we don't try to create a new planner if
        // we had a JVM failover, or if a recyled application module
        // is activated after passivation.  If this things happen, BC4J will
        // be able to find the row that you created so the user can resume
        // work.
        if (!pageContext.isFormSubmission())
        {
          OAApplicationModule am = pageContext.getApplicationModule(webBean);
          am.invokeMethod("createPlanner", null);
        } 
      }
      else 
      { 
        if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, "plannerAddTxn", true))
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
      OAViewObject vo = (OAViewObject)am.findViewObject("NewPlannerVO1");
        
      // Note that we have to get this value from the VO because the EO will
      // assemble it during its validation cycle.

	    Number plannerId = (Number)vo.getCurrentRow().getAttribute("PlannerId");
      String planner = String.valueOf(plannerId.intValue());

	    // Simply telling the transaction to commit will cause all the Entity Object validation
	    // to fire.
	    //
	    // Note: there's no reason for a developer to perform a rollback.  This is handled by
	    // the framework if errors are encountered.
      am.invokeMethod("apply");

      // Indicate that the Create transaction is complete.
      TransactionUnitHelper.endTransactionUnit(pageContext, "plannerAddTxn");
    
      // Assuming the "commit" succeeds, navigate back to the "PlannerHierarchy" page
      // and display a "Confirmation" message at the top of the page.
                                 
      MessageToken[] msgTokens = {new MessageToken("PLANNER", planner)};
      OAException confirmMessage = new OAException("XXMER", "XX_WFH_CONFIRM_ADD", msgTokens, OAException.CONFIRMATION, null);
       // Per the UI guidelines, we want to add the confirmation message at the 
       // top of the search/results page and we want the old search criteria and
       // results to display.
       pageContext.putDialogMessage(confirmMessage);

       pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxmer/wfh/webui/PlannerHierarchyPG",
                                      null,
                                      OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                      null,
                                      null,
                                      true, // retain AM
                                      OAWebBeanConstants.ADD_BREAD_CRUMB_NO); 

 
    }
    else if (pageContext.getParameter("Cancel") != null)
    {
       am.invokeMethod("rollback");   
       TransactionUnitHelper.endTransactionUnit(pageContext, "plannerAddTxn");
       
       pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxmer/wfh/webui/PlannerHierarchyPG",
                                      null,
                                      OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                      null,
                                      null,
                                      true, // retain AM
                                      OAWebBeanConstants.ADD_BREAD_CRUMB_NO);    
    }
  }
}
