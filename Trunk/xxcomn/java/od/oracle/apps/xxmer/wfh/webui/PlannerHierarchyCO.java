package od.oracle.apps.xxmer.wfh.webui;
import java.io.Serializable;
//import java.util.Enumeration;

//import oracle.jbo.domain.Number;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;

import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
//import oracle.apps.fnd.framework.OAViewObject;
//import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import oracle.jbo.Row;
//import oracle.jbo.ViewLink;
//import oracle.jbo.JboException;
//import oracle.jbo.server.OAViewLinkAccessorDomain;

import oracle.apps.fnd.framework.webui.OAHGridQueriedRowEnumerator;
import oracle.apps.fnd.framework.webui.beans.table.OAHGridBean;
//import oracle.apps.fnd.framework.webui.beans.table.OASingleSelectionBean;
//import oracle.apps.fnd.framework.webui.beans.table.OAAdvancedTableBean;

/**
 * Controller for ...
 */
public class PlannerHierarchyCO extends OAControllerImpl
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

    OAApplicationModule am = pageContext.getApplicationModule(webBean);

    // The following checks to see if the user navigated back to this page
    // without taking an action that cleared an "in transaction" indicator.
    // If so, we want to rollback any changes that she abandoned to ensure they
    // aren't left lingering in the BC4J cache to cause problems with 
    // subsequent transactions.  For example, if the user navigates to the 
    // Create Employee page where you start a "create" transaction unit, 
    // then navigates back to this page using the browser Back button and
    // selects the Create Employee button again, the OA Framework detects this
    // Back button navigation and steps through processRequest() to this code
    // is executed before you try to create another new employee.
    if (TransactionUnitHelper.isTransactionUnitInProgress(pageContext, "plannerAddTxn", false))
    { 
      am.invokeMethod("rollback");
      TransactionUnitHelper.endTransactionUnit(pageContext, "plannerAddTxn");
    }
    else if (TransactionUnitHelper.isTransactionUnitInProgress(pageContext, "plannerUpdateTxn", false))
    { 
      am.invokeMethod("rollback");
      TransactionUnitHelper.endTransactionUnit(pageContext, "plannerUpdateTxn");
    }
    
    am.invokeMethod("initPlannerHierarchy");
    
    OAHGridBean hGridBean = (OAHGridBean)webBean;
    hGridBean.setRootNodeText("Planners");
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
    
    //displayHGridRows(pageContext, webBean);
   
    if (pageContext.getParameter("Add") != null) 
    {
       OAHGridBean hGridBean = (OAHGridBean)webBean;
       hGridBean.clearCache(pageContext);

       pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxmer/wfh/webui/PlannerAddPG",
                                      null,
                                      OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                      null,
                                      null,
                                      true, // retain AM
                                      OAWebBeanConstants.ADD_BREAD_CRUMB_YES,
                                      OAWebBeanConstants.IGNORE_MESSAGES); 
    }
    else if (pageContext.getParameter("Update") != null)
    {
       Planner planner = getSelectedPlanner(pageContext, webBean);
       if (planner == null) 
       {
         OAException errorMessage = new OAException("XXMER", "XX_WFH_NO_SEL_UPDATE", null, OAException.ERROR, null);
         pageContext.putDialogMessage(errorMessage);
         pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxmer/wfh/webui/PlannerHierarchyPG",
                                      null,
                                      OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                      null,
                                      null,
                                      true, // retain AM
                                      OAWebBeanConstants.ADD_BREAD_CRUMB_NO); 
       }
       else 
       {
         pageContext.putParameter("plannerId", planner.plannerId);
         
         OAHGridBean hGridBean = (OAHGridBean)webBean;
         hGridBean.clearCache(pageContext);
         /*
         MessageToken[] msgTokens = {new MessageToken("PLANNER", planner.plannerId)};
         OAException confirmMessage = new OAException("XXMER", "XX_WFH_CONFIRM_UPDATE", msgTokens, OAException.CONFIRMATION, null);
         pageContext.putDialogMessage(confirmMessage);
         */
         pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxmer/wfh/webui/PlannerUpdatePG",
                                      null,
                                      OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                      null,
                                      null,
                                      true, // retain AM
                                      OAWebBeanConstants.ADD_BREAD_CRUMB_YES,
                                      OAWebBeanConstants.IGNORE_MESSAGES); 
       }
    }
    else if (pageContext.getParameter("Delete") != null)
    {
       Planner planner = getSelectedPlanner(pageContext, webBean);
       if (planner == null) 
       {
         OAException errorMessage = new OAException("XXMER", "XX_WFH_NO_SEL_DELETE", null, OAException.ERROR, null);
         pageContext.putDialogMessage(errorMessage);
         pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxmer/wfh/webui/PlannerHierarchyPG",
                                      null,
                                      OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                      null,
                                      null,
                                      true, // retain AM
                                      OAWebBeanConstants.ADD_BREAD_CRUMB_NO); 
       }
       else 
       {
         MessageToken[] msgTokens = {new MessageToken("PLANNER", planner.plannerName)};
         OAException mainMessage = new OAException("XXMER", "XX_WFH_QUESTION_DELETE", msgTokens);

         OADialogPage dialogPage = new OADialogPage(OAException.WARNING, 
                                                 mainMessage,
                                                 null, 
                                                 "", 
                                                 "");

         dialogPage.setOkButtonItemName("DeleteYesButton");

         dialogPage.setOkButtonToPost(true);
         dialogPage.setNoButtonToPost(true);
         dialogPage.setPostToCallingPage(true);

         dialogPage.setOkButtonLabel(pageContext.getMessage("XXMER", "XX_XXMER_LIT_YES", null)); 
         dialogPage.setNoButtonLabel(pageContext.getMessage("XXMER", "XX_XXMER_LIT_NO", null)); 

         java.util.Hashtable formParams = new java.util.Hashtable(1); 
         formParams.put("plannerId", planner.plannerId); 
         formParams.put("plannerName", planner.plannerName);
         dialogPage.setFormParameters(formParams); 
  
         pageContext.redirectToDialogPage(dialogPage);
       }
    }
    else if (pageContext.getParameter("DeleteYesButton") != null)
    {
       String plannerId = pageContext.getParameter("plannerId");
       String plannerName = pageContext.getParameter("plannerName");
       Serializable[] parameters = { plannerId };

       OAApplicationModule am = pageContext.getApplicationModule(webBean);
       am.invokeMethod("deletePlanner", parameters);

       OAHGridBean hGridBean = (OAHGridBean)webBean;
       hGridBean.clearCache(pageContext);

       MessageToken[] msgTokens = {new MessageToken("PLANNER", plannerName)};
       OAException confirmMessage = new OAException("XXMER", "XX_WFH_CONFIRM_DELETE", msgTokens, OAException.CONFIRMATION, null);
       pageContext.putDialogMessage(confirmMessage);

       pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxmer/wfh/webui/PlannerHierarchyPG",
                                      null,
                                      OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                      null,
                                      null,
                                      true, // retain AM
                                      OAWebBeanConstants.ADD_BREAD_CRUMB_NO); 
    }
  }

  private Planner getSelectedPlanner(OAPageContext pageContext,
                             OAWebBean webBean)
  {
     OAHGridBean hGridBean = (OAHGridBean)webBean;
     OAHGridQueriedRowEnumerator enum = 
       new OAHGridQueriedRowEnumerator(pageContext, hGridBean);
     while (enum.hasMoreElements())
     {
       Row row = (Row)enum.nextElement();
       if (row != null)
       {
         Object o = row.getAttribute("Selected");
         System.out.println("Selected[" + o + "]");
         if ("Y".equals(o.toString())) 
         {
           Planner p = new Planner();
           p.plannerId = row.getAttribute("EmployeeId").toString();
           p.plannerName = row.getAttribute("FullName").toString();
           return p;
         }
       }
     }
     return null;
  }

  private void displayHGridRows(OAPageContext pageContext,
                             OAWebBean webBean)
  {
     OAHGridBean hGridBean = (OAHGridBean)webBean;
     OAHGridQueriedRowEnumerator enum = 
       new OAHGridQueriedRowEnumerator(pageContext, hGridBean);
     int rc = 0;
     while (enum.hasMoreElements())
     {
       Row row = (Row)enum.nextElement();
       System.out.println("Processing Row[" + ++rc + "]");
       if (row != null)
       {
         Object o = row.getAttribute("EmployeeId");
         System.out.println("EmployeeId[" + o + "]");
         o = row.getAttribute("Selected");
         System.out.println("Selected[" + o + "]");
       }
     }
  }

  static class Planner 
  {
    String plannerId = null;
    String plannerName = null;
  }
}
