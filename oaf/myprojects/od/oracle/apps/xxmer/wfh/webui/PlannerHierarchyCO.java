package od.oracle.apps.xxmer.wfh.webui;
import java.io.Serializable;
//import java.util.Enumeration;

//import oracle.jbo.domain.Number;

//import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;

import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
//import oracle.apps.fnd.framework.OAViewObject;
//import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
//import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
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
    
    displayHGridRows(pageContext, webBean);
   
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
    else if (pageContext.getParameter("Edit") != null)
    {
       Planner planner = getSelectedPlanner(pageContext, webBean);
       if (planner == null) 
       {
         OAException errorMessage = new OAException("Please select a Planner before clicking Update", OAException.ERROR);
         pageContext.putDialogMessage(errorMessage);
       }
       else 
       {
         OAHGridBean hGridBean = (OAHGridBean)webBean;
         hGridBean.clearCache(pageContext);

         OAException confirmMessage = new OAException("Planner (" + planner.plannerId + ") has been updated.", OAException.CONFIRMATION);
         pageContext.putDialogMessage(confirmMessage);
       }
       pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxmer/wfh/webui/PlannerHierarchyPG",
                                      null,
                                      OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                      null,
                                      null,
                                      true, // retain AM
                                      OAWebBeanConstants.ADD_BREAD_CRUMB_NO); 
    }
    else if (pageContext.getParameter("Delete") != null)
    {
       Planner planner = getSelectedPlanner(pageContext, webBean);
       if (planner == null) 
       {
         OAException errorMessage = new OAException("Please select a Planner before clicking Delete", OAException.ERROR);
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
         OAException mainMessage = new OAException("Are you sure you want to delete planner (" + planner.plannerName + ") from the Planner Hierarchy?");

         OADialogPage dialogPage = new OADialogPage(OAException.WARNING, 
                                                 mainMessage,
                                                 null, 
                                                 "", 
                                                 "");

         dialogPage.setOkButtonItemName("DeleteYesButton");

         dialogPage.setOkButtonToPost(true);
         dialogPage.setNoButtonToPost(true);
         dialogPage.setPostToCallingPage(true);

         dialogPage.setOkButtonLabel("Yes"); 
         dialogPage.setNoButtonLabel("No"); 

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

       OAException confirmMessage = new OAException("Planner (" + plannerName + ") has been deleted.", OAException.CONFIRMATION);
       pageContext.putDialogMessage(confirmMessage);

       pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxmer/wfh/webui/PlannerHierarchyPG",
                                      null,
                                      OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                      null,
                                      null,
                                      true, // retain AM
                                      OAWebBeanConstants.ADD_BREAD_CRUMB_NO); 
    }
    //temp code block
    else if (pageContext.getParameter("Delete") != null)
    {
       Planner planner = getSelectedPlanner(pageContext, webBean);
       if (planner == null) 
       {
         OAException errorMessage = new OAException("Please select a Planner before clicking Delete", OAException.ERROR);
         pageContext.putDialogMessage(errorMessage);
       }
       else 
       {
         OAHGridBean hGridBean = (OAHGridBean)webBean;
         hGridBean.clearCache(pageContext);

         OAException confirmMessage = new OAException("Planner (" + planner.plannerName + ") has been deleted.", OAException.CONFIRMATION);
         pageContext.putDialogMessage(confirmMessage);
       }
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
