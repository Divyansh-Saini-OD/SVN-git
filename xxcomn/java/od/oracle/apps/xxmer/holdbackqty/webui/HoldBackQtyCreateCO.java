/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxmer.holdbackqty.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
// new imports
//import java.io.Serializable;
//import oracle.jbo.domain.Number;
 
//import oracle.cabo.ui.data.BoundValue;
//import oracle.cabo.ui.data.DictionaryData;
//import oracle.cabo.ui.data.DataObjectList;
//import oracle.cabo.ui.data.bind.ConcatBoundValue;
//import oracle.cabo.ui.data.bind.FixedBoundValue;
 
import oracle.apps.fnd.common.MessageToken;
//import oracle.apps.fnd.common.VersionInfo;
 
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
//import oracle.apps.fnd.framework.webui.OAControllerImpl;
//import oracle.apps.fnd.framework.webui.OADataBoundValueViewObject;
import oracle.apps.fnd.framework.webui.OADialogPage;
//import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
//import oracle.apps.fnd.framework.webui.beans.OAImageBean;
//import oracle.apps.fnd.framework.webui.beans.OAWebBean;
//import oracle.apps.fnd.framework.webui.beans.table.OATableBean;


// end new imports
/**
 * Controller for ...
 */
public class HoldBackQtyCreateCO extends OAControllerImpl
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
    System.out.println("HoldBackQtyCreateCO: processRequest called");   
  
    super.processRequest(pageContext, webBean);
    // add apply logic
    if(!pageContext.isBackNavigationFired(false))
	  {
        System.out.println("HoldBackQtyCreateCO: processRequest IF Nav");   
    
        // change vndCreateTxn to holdBackQtyCreateTxn
		   TransactionUnitHelper.startTransactionUnit(pageContext,"holdBackQtyCreateTxn");

		   if (!pageContext.isFormSubmission())
		   {
            System.out.println("HoldBackQtyCreateCO: processRequest IF page context");   
       
			   OAApplicationModule am = pageContext.getApplicationModule(webBean);
         am.invokeMethod("createHoldBackQty", null);
		   }
	  }
	  else
	  {
        System.out.println("HoldBackQtyCreateCO: processRequest else Nav");   

		  if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, "holdBackQtyCreateTxn", true))
		  {
          System.out.println("HoldBackQtyCreateCO: processRequest Else page context");   

			  OADialogPage dialogPage = new OADialogPage(NAVIGATION_ERROR);
			  pageContext.redirectToDialogPage(dialogPage);
		  }
	  }
    System.out.println("HoldBackQtyCreateCO: processRequest exited");   

  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    System.out.println("HoldBackQtyCreateCO: processFormRequest called");   
  
    super.processFormRequest(pageContext, webBean);
    // add apply logic
    OAApplicationModule am = pageContext.getApplicationModule(webBean);      
    
    if (pageContext.getParameter("Apply") != null)
    {
      System.out.println("HoldBackQtyCreateCO: processFormRequest APPLY 1");   

      OAViewObject vo = (OAViewObject)am.findViewObject("HoldBackQtyVO1");

	    String Item = (String)vo.getCurrentRow().getAttribute("Item");
//	    String WarehouseLocation = (String)vo.getCurrentRow().getAttribute("Warehouse_Location");
	    String WarehouseLocation = (String)vo.getCurrentRow().getAttribute("WarehouseLocation");

      System.out.println("HoldBackQtyCreateCO: processFormRequest: item: " + Item + " loc " + WarehouseLocation);   

      // String vendorNum = String.valueOf(vendorId.intValue());
      am.invokeMethod("apply");

      // Indicate that the Create transaction is complete.
      //  TransactionUnitHelper.endTransactionUnit(pageContext, "vndCreateTxn");

      // Assuming the "commit" succeeds, navigate back to the "Search" page with
      // the user's search criteria intact and display a "Confirmation" message
      // at the top of the page.
      MessageToken[] tokens = { new MessageToken("ITEM", Item),
                                new MessageToken("WAREHOUSE_LOCATION", WarehouseLocation) };

      OAException confirmMessage = new OAException("XXMER", "XXMER_T_VC_CREATE_COMFIRM", tokens,
                                       OAException.CONFIRMATION, null);

       // Per the UI guidelines, we want to add the confirmation message at the
       // top of the search/results page and we want the old search criteria and
       // results to display.

       pageContext.putDialogMessage(confirmMessage);

       pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxmer/holdbackqty/webui/HoldBackQtyPG",
                                      null,
                                      OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                      null,
                                      null,
                                      true, // retain AM
                                      OAWebBeanConstants.ADD_BREAD_CRUMB_NO);

    }
    else if(pageContext.getParameter("Cancel") != null)
    {
      am.invokeMethod("rollbackHoldBackQty");
      TransactionUnitHelper.endTransactionUnit(pageContext,"vndCreateTxn");
      pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxmer/holdbackqty/webui/HoldBackQtyPG",
                                      null,
                                      OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                      null,
                                      null,
                                      true, // retain AM
                                      OAWebBeanConstants.ADD_BREAD_CRUMB_NO);

    }
    System.out.println("HoldBackQtyCreateCO: processFormRequest exited");   

  }   
}
