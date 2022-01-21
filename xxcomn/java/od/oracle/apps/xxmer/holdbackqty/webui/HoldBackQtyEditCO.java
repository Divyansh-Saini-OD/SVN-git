/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxmer.holdbackqty.webui;
import od.oracle.apps.xxmer.holdbackqty.server.HoldBackQtyAMImpl;    // 1/24/08
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
public class HoldBackQtyEditCO extends OAControllerImpl
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
    System.out.println("HoldBackQtyEditCO: processRequest called");

    super.processRequest(pageContext, webBean);
    // add apply logic
    if(!pageContext.isBackNavigationFired(false))
	  {
        System.out.println("HoldBackQtyEditCO: processRequest IF Nav");

        // change vndEditTxn to holdBackQtyEditTxn
		   TransactionUnitHelper.startTransactionUnit(pageContext,"holdBackQtyEditTxn");

		   if (!pageContext.isFormSubmission())
		   {
            System.out.println("HoldBackQtyEditCO: processRequest IF page context");
 
         // String Item = pageContext.getParameter("Item");

         String Item = pageContext.getParameter("Item");
         String WarehouseLocation = pageContext.getParameter("WarehouseLocation");
         String[] parameters = { Item, WarehouseLocation };
         //String[] parameters = { Item, WarehouseLocation };

     		System.out.println("HoldBackQtyEditCO: pr: item is " + Item);                           
     		System.out.println("HoldBackQtyEditCO: pr: WarehouseLocation is " + WarehouseLocation);  

			   OAApplicationModule am = pageContext.getApplicationModule(webBean);

         //am.invokeMethod("prepEditItemVO", Item, WarehouseLocation);
         //am.invokeMethod("prepEditItemVO2", parameters);
         ((HoldBackQtyAMImpl)am).prepEditItemVO2(parameters);
        
         //am.invokeMethod("editHoldBackQty", parameters);
         //am.invokeMethod("editHoldBackQty", null);
		   }
	  }
	  else
	  {
        System.out.println("HoldBackQtyEditCO: processRequest else Nav");

		  if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, "holdBackQtyEditTxn", true))
		  {
          System.out.println("HoldBackQtyEditCO: processRequest Else page context");

			  OADialogPage dialogPage = new OADialogPage(NAVIGATION_ERROR);
			  pageContext.redirectToDialogPage(dialogPage);
		  }
	  }
    System.out.println("HoldBackQtyEditCO: processRequest exited");

  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    System.out.println("HoldBackQtyEditCO: processFormRequest called");

    super.processFormRequest(pageContext, webBean);
    // add apply logic
    OAApplicationModule am = pageContext.getApplicationModule(webBean);

    if (pageContext.getParameter("Apply") != null)
    {
      System.out.println("HoldBackQtyEditCO: processFormRequest APPLY 1");

      //String rowIndex = pageContext.getParameter("rowIndex");
      //System.out.println("HoldBackQtyEditCO: processFormRequest: rowIndex: " + rowIndex);


      // String vendorNum = String.valueOf(vendorId.intValue());
      // am.invokeMethod("apply");
      am.invokeMethod("editHoldBackQty");
      System.out.println("HoldBackQtyEditCO: processFormRequest APPLY");

      // Indicate that the Edit transaction is complete.
      //  TransactionUnitHelper.endTransactionUnit(pageContext, "vndEditTxn");

      // Assuming the "commit" succeeds, navigate back to the "Search" page with
      // the user's search criteria intact and display a "Confirmation" message
      // at the top of the page.
      //MessageToken[] tokens = { new MessageToken("ITEM", Item),
      //                          new MessageToken("WAREHOUSE_LOCATION", WarehouseLocation) };

      //OAException confirmMessage = new OAException("XXMER", "XXMER_T_VC_Edit_COMFIRM", tokens,
      //                                 OAException.CONFIRMATION, null);

      //System.out.println("HoldBackQtyEditCO: processFormRequest APPLY 6");

       // Per the UI guidelines, we want to add the confirmation message at the
       // top of the search/results page and we want the old search criteria and
       // results to display.

       // pageContext.putDialogMessage(confirmMessage);

      System.out.println("HoldBackQtyEditCO: processFormRequest APPLY 7");

       pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxmer/holdbackqty/webui/HoldBackQtyPG",
                                      null,
                                      OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                      null,
                                      null,
                                      true, // retain AM
                                      OAWebBeanConstants.ADD_BREAD_CRUMB_NO);

      System.out.println("HoldBackQtyEditCO: processFormRequest APPLY 8");

    }
    else if(pageContext.getParameter("Cancel") != null)
    {
      am.invokeMethod("rollbackHoldBackQty");
      TransactionUnitHelper.endTransactionUnit(pageContext,"vndEditTxn");
      pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxmer/holdbackqty/webui/HoldBackQtyPG",
                                      null,
                                      OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                      null,
                                      null,
                                      true, // retain AM
                                      OAWebBeanConstants.ADD_BREAD_CRUMB_NO);

    }
    System.out.println("HoldBackQtyEditCO: processFormRequest exited");

  }
}
