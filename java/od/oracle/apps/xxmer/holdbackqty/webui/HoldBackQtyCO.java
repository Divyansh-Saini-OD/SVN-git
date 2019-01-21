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
//import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
//import oracle.apps.fnd.framework.OARowSetProperties;
//import oracle.apps.fnd.framework.OARowSetUtils;
//import oracle.apps.fnd.framework.OARowValException;
//import oracle.apps.fnd.framework.OAViewCriteriaRow;
//import oracle.jbo.domain.Number;
//import java.lang.Number;
//import oracle.*;
//import java.lang.*;
//import java.util.*;
//import java.sql.*;

// begin new imports
import java.io.Serializable;
 
//import oracle.jbo.domain.Number;
//import oracle.jbo.ViewObject;
//import oracle.jbo.client.Configuration;

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

//import oracle.jbo.Transaction;

import com.sun.java.util.collections.HashMap;

//import oracle.jbo.RowSetIterator;
//import oracle.jbo.Row;

// 1/30/08
//import oracle.jbo.Transaction;
//import oracle.jbo.domain.Number;   // added to support ss upload functionality
//import oracle.jbo.RowSetIterator;

//import oracle.apps.fnd.framework.OAAttrValException;
//import java.io.IOException;
//import java.io.BufferedReader;
//import oracle.jbo.domain.BlobDomain;
//import java.util.StringTokenizer;
//import java.io.Serializable;
import java.lang.String;
//import oracle.jbo.domain.Date;   // added to support date class (ss upload functionality)
//import oracle.apps.fnd.framework.OAViewCriteriaRow;
//import oracle.apps.fnd.framework.server.OAViewObjectImpl;
// end new imports

/**
 * Controller for ...
 */
public class HoldBackQtyCO extends OAControllerImpl
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
    System.out.println("HoldBackQtyCO: processRequest called");   
  
    super.processRequest(pageContext, webBean);
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    am.invokeMethod("initHoldBackQtyList");

    if(!pageContext.isBackNavigationFired(false))
    {
      TransactionUnitHelper.startTransactionUnit(pageContext,"holdBackQtyTxn");

      if (!pageContext.isFormSubmission())
      {
            //OAApplicationModule am = pageContext.getApplicationModule(webBean);
            am.invokeMethod("createHoldBackQty", null);
      }
    }
    else
    {
        if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, "holdBackQtyTxn", true))
        {
          OADialogPage dialogPage = new OADialogPage(NAVIGATION_ERROR);
          pageContext.redirectToDialogPage(dialogPage);
          am.invokeMethod("rollbackHoldBackQty");
        }
    }
    System.out.println("HoldBackQtyCO: processRequest exited");   
   
  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    System.out.println("HoldBackQtyCO: processFormRequest called");   

    super.processFormRequest(pageContext, webBean);

    if(pageContext.getParameter("Create") != null)
      {
          pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxmer/holdbackqty/webui/HoldBackQtyAddPG"
                                ,null
                                ,OAWebBeanConstants.KEEP_MENU_CONTEXT
                                ,null
                                ,null
                                ,true
                                ,OAWebBeanConstants.ADD_BREAD_CRUMB_YES
                                ,OAWebBeanConstants.IGNORE_MESSAGES);
      }
    else if(pageContext.getParameter("Upload") != null)
      {
          pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxmer/holdbackqty/webui/FileUploadPG"
                                ,null
                                ,OAWebBeanConstants.KEEP_MENU_CONTEXT
                                ,null
                                ,null
                                ,true
                                ,OAWebBeanConstants.ADD_BREAD_CRUMB_YES
                                ,OAWebBeanConstants.IGNORE_MESSAGES);
      }
    else if("update".equals(pageContext.getParameter(EVENT_PARAM)))
    {   
      // 1/20/08  Get correct row: Get the identifier of the PPR event source row
      String rowReference = pageContext.getParameter(OAWebBeanConstants.EVENT_SOURCE_ROW_REFERENCE);

      String rowIndex = pageContext.getParameter(OAWebBeanConstants.EVENT_SOURCE_ROW_INDEX_PARAM);
      //Serializable[] parameters = { rowReference };
      int numRowIndex = Integer.parseInt(rowIndex);   
      
      String[] parameters = { rowIndex };

   		System.out.println("**** row reference: " + rowReference);                           
   		System.out.println("**** row index: " + rowIndex);  
  		System.out.println("**** rr parameters: " + parameters);                           

      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      am.invokeMethod("prepEditItemVO4",parameters);

      pageContext.putParameter("rowIndex", rowIndex);

  		System.out.println("HoldBackQtyCO: Process Form Request: Done");                           
     
      //String Item_rr = (String) rowReference.split("{",",");
//  		System.out.println("**** rr item: " + Item_rr);                           
      
      // 1/20/08 String WarehouseLocation = pageContext.getParameter("WarehouseLocation");

      // 1/28/08 OAApplicationModule am = pageContext.getApplicationModule(webBean);     
//1/30/08@4      OAViewObject vo = (OAViewObject)am.findViewObject("HoldBackQtyListVO1");
      //OAViewObject vo = (OAViewObject) getHoldBackQtyVO1();    
  
  		// 1/28/08 System.out.println(" current row set to " + rowIndex);                           
      
      //String Item = (String)vo.rowIndex.getAttribute("Item");
      //String WarehouseLocation = (String)vo.rowIndex.getAttribute("WarehouseLocation");

      //@@String Item = rowIndex.stringToInteger.getAttribute("Item");
      //@@String WarehouseLocation = rowIndex.to_number.getAttribute("WarehouseLocation");

//1/30/08@4 	    String Item = (String)vo.getCurrentRow().getAttribute("Item");
//1/30/08@4 	    String WarehouseLocation = (String)vo.getCurrentRow().getAttribute("WarehouseLocation");

//      String Item = (String)vo.rowReference.getAttribute("Item");  // 1/20/08
//      String WarehouseLocation = (String)vo.rowReference.getAttribute("WarehouseLocation");  // 1/20/08

      //1/28/08 String Item = pageContext.getParameter("Item");
      //1/28/08 String WarehouseLocation = pageContext.getParameter("WarehouseLocation");

//1/30/08@4   		System.out.println("**a** Item: " + Item + " WarehouseLocation: " + WarehouseLocation);                           

      //1/28/08 MessageToken[] tokens = {new MessageToken("ITEM",Item),new MessageToken("WAREHOUSE_LOCATION",WarehouseLocation)};

         // pageContext.putParameter("plannerId", planner.plannerId);

     // redirect page to Request Scheduling page
//1/30/08@4      HashMap parms = new HashMap();
//1/30/08@4      String url = "OA.jsp";
//1/30/08@4      parms.put("WarehouseLocation", WarehouseLocation);
//1/30/08@4      parms.put("Item", Item);

//     pageContext.putParameter("WarehouseLocation", pageContext.getParameter("WarehouseLocation"));
//     pageContext.putParameter("Item",pageContext.getParameter("Item"));
     //1/28/08 pageContext.putParameter("Item",Item);
     //1/28/08 pageContext.putParameter("WarehouseLocation",WarehouseLocation);
     
      pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxmer/holdbackqty/webui/HoldBackQtyEditPG"
                                ,null
                                ,OAWebBeanConstants.KEEP_MENU_CONTEXT
                                ,null
                                ,null                          // parms or null
                                ,true
                                ,OAWebBeanConstants.ADD_BREAD_CRUMB_YES
                                ,OAWebBeanConstants.IGNORE_MESSAGES);
      
    }

    else if("delete".equals(pageContext.getParameter(EVENT_PARAM)))
    {
      System.out.println("HoldBackQtyCO: processFormRequest - delete item");   

    // @@@@@   Planner planner = getSelectedPlanner(pageContext, webBean);
    
      String Item = pageContext.getParameter("Item");
      String WarehouseLocation = pageContext.getParameter("WarehouseLocation");

  		System.out.println("!!!!!!!!!!!!!!!!  Item " +Item+" Loc "+WarehouseLocation);                           

      System.out.println("HoldBackQtyCO: processFormRequest - 2 delete item");

      MessageToken[] tokens = {new MessageToken("ITEM",Item),new MessageToken("WAREHOUSE_LOCATION",WarehouseLocation)};

      OAException mainMessage = new OAException("XXMER","XX_HBQ_QUESTION_DELETE", tokens);

      System.out.println("HoldBackQtyCO: processFormRequest - 3 delete item");

      OADialogPage dialogPage = new OADialogPage(OAException.WARNING, mainMessage, null,"","");
      String yes = pageContext.getMessage("XXMER","XXMER_T_YES",null);
      String no = pageContext.getMessage("XXMER","XXMER_T_NO",null);

      System.out.println("HoldBackQtyCO: processFormRequest - 4 delete item");
   
      dialogPage.setOkButtonItemName("DeleteYesButton");
      dialogPage.setOkButtonToPost(true);
      dialogPage.setNoButtonToPost(true);
      dialogPage.setPostToCallingPage(true);
      dialogPage.setOkButtonLabel(yes);
      dialogPage.setNoButtonLabel(no);

      System.out.println("HoldBackQtyCO: processFormRequest - 5 delete item");         

         java.util.Hashtable formParams = new java.util.Hashtable(1); 
         formParams.put("Item", Item); 
         formParams.put("WarehouseLocation", WarehouseLocation);
         dialogPage.setFormParameters(formParams); 

      System.out.println("HoldBackQtyCO: processFormRequest - 6 delete item");     

      pageContext.redirectToDialogPage(dialogPage);

      System.out.println("HoldBackQtyCO: processFormRequest - end delete item");         
    }
    else if(pageContext.getParameter("DeleteYesButton")!=null)
    {
      String Item = pageContext.getParameter("Item");
      String WarehouseLocation = pageContext.getParameter("WarehouseLocation");
  		System.out.println("**********  Item " +Item+" Loc "+WarehouseLocation);                           
      
      Serializable[] parameters = {Item, WarehouseLocation};
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      am.invokeMethod("deleteHoldBackQty",parameters);
      am.invokeMethod("initHoldBackQtyList");
      MessageToken[] tokens = {new MessageToken("ITEM",Item),new MessageToken("WAREHOUSE_LOCATION",WarehouseLocation)};

      OAException message = new OAException("XXMER","XXMER_T_VENDOR_DELETE_CONFIRM", tokens,OAException.CONFIRMATION,null);     
     
      pageContext.putDialogMessage(message);
       
    }
    System.out.println("HoldBackQtyCO: processFormRequest exited");   
      
  }

}
