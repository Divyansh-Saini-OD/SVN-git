/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 | 1.0 12-Apr-17  Madhu Bolli     Defect#41464 - Bulk Export                 |
 +===========================================================================*/
package od.oracle.apps.xxfin.ar.irec.accountDetails.blkexp.webui;


import com.sun.java.util.collections.HashMap;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import java.io.Serializable;

import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import java.sql.SQLException;
import java.text.SimpleDateFormat;
import java.text.DateFormat;


import oracle.apps.ar.irec.framework.webui.IROAControllerImpl;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;

/**
 * Controller for ...
 */
public class ODIrecBlkExpSrchCO extends IROAControllerImpl
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

    String customerId = pageContext.getParameter("Ircustomerid");
    String customerNum = pageContext.getParameter("IrcustomerNumber");
    pageContext.writeDiagnostics(this, "ODIrecBlkExpSrchCO.PR() - Customer Number as parameter is "+customerNum, 1);
    if(customerId == null || "".equals(customerId.trim())) {
      customerId = (String)pageContext.getTransactionValue("customerId");
      customerNum = (String)pageContext.getTransactionValue("txnCustomerNum");
    } 
    pageContext.writeDiagnostics(this, "ODIrecBlkExpSrchCO.PR() - Customer Number from Transaction is "+customerNum, 1);

    OAApplicationModuleImpl blkExpAM = (OAApplicationModuleImpl)pageContext.getApplicationModule(webBean);
    String tryType = null;
    OAMessageChoiceBean trxTypeMsgChBn = (OAMessageChoiceBean)webBean.findChildRecursive("ODIrBlExpSrchTrxTypeMsgCh");
    if (trxTypeMsgChBn != null) 
    {
      tryType = (String)trxTypeMsgChBn.getValue(pageContext);  // At first, this value comes from Default Value set declaratively
    }
    if (tryType == null || "".equals(tryType.trim())) 
    {
      tryType = "INVOICES";
    }

    blkExpAM.invokeMethod("handleTrxTypeChangeEvent",new Serializable[]{tryType});

    if(customerId != null && !"".equals(customerId.trim())) {
      pageContext.putTransactionValue("customerId", customerId);
      pageContext.putTransactionValue("txnCustomerNum", customerNum);
    } else 
    {
      pageContext.writeDiagnostics(this, "ODIrecBlkExpSrchCO.PR() - Customer Number context not set for Bulk Export", OAFwkConstants.STATEMENT);
      OAException message = new OAException("XXFIN", "XX_ARI_BLK_EXP_CUST_NULL", null, OAException.ERROR, null);
      //pageContext.putDialogMessage(message); 
      throw message;
    }
    
    OAHeaderBean hdrBn = (OAHeaderBean)webBean.findIndexedChildRecursive("ODIrBlExpSrchHdr");
    if(hdrBn != null) 
    {
      String hdrValue = hdrBn.getText();
      hdrBn.setText(hdrValue+" for Customer Number "+customerNum);
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
    OAApplicationModuleImpl blkExpAM = (OAApplicationModuleImpl)pageContext.getApplicationModule(webBean);

    
    String customerId = (String) pageContext.getTransactionValue("customerId");    
    String customerNumber = (String)pageContext.getTransactionValue("txnCustomerNum");
    if(customerId == null || "".equals(customerId.trim())) 
    {
      OAException message = new OAException("XXFIN", "XX_ARI_BLK_EXP_CUST_NULL", null, OAException.ERROR, null);
      throw message;
    }
    
    String trxType = pageContext.getParameter("ODIrBlExpSrchTrxTypeMsgCh");
    String event = pageContext.getParameter("event");
    if("trxTypeChange".equals(event)) 
    {      
      blkExpAM.invokeMethod("handleTrxTypeChangeEvent",new Serializable[]{trxType});
    }  else if (pageContext.getParameter("ODIrBlExpSrchSubmitBtn") != null) 
    {
    
      // Get All values from UI Fields and invoke AM method submitBulkExport()
      
      String trxStatus = pageContext.getParameter("ODIrBlExpSrchTrxStatusMsgCh");
      String trxTemplate = pageContext.getParameter("ODIrBlExpSrchTmpltMsgCh");

      String toEmail = pageContext.getParameter("ODIrBlExpSrchEmailMsgTInp");
      String sAmtFrom = pageContext.getParameter("ODIrBlExpSrchAmtFromMsgTInp");

      
      // Convert the given 'Amount From' value to Number
      if ("".equals(sAmtFrom.trim()))
      {
        sAmtFrom = null;
      }
      
      // Convert the given 'Amount To' value to Number
      String sAmtTo = pageContext.getParameter("ODIrBlExpSrchAmtToMsgTInp");
      if ("".equals(sAmtTo.trim()))
      {
        sAmtTo = null;
      }      

      // Get all dates
      String sTrxDateFrom = pageContext.getParameter("ODIrBlExpSrchTransDateFromMsgTInp"); 
      String sTrxDateTo = pageContext.getParameter("ODIrBlExpSrchTransDateToMsgTInp");
      String sDueDateFrom = pageContext.getParameter("ODIrBlExpSrchDueDateFromMsgTInp");
      String sDueDateTo = pageContext.getParameter("ODIrBlExpSrchDueDateToMsgTInp");  
      
      
      // Invoke the method to invoke the plsql procedure which submits the CP

       Serializable[]paramValues = new Serializable[] { customerNumber, customerId, trxStatus, trxType, trxTemplate, toEmail, sAmtFrom, sAmtTo, sTrxDateFrom, sTrxDateTo, sDueDateFrom, sDueDateTo };
       Serializable[] paramTypes = new Class[] { String.class, String.class, String.class, String.class, String.class,  String.class, String.class, String.class, String.class, String.class, String.class, String.class};
       
       String result = (String)blkExpAM.invokeMethod("submitBulkExport", (Serializable[])paramValues, (Class[])paramTypes);
       
      
       if("0".equals(result)) 
       {
         pageContext.writeDiagnostics(this, "Bulk Export Submission Successfully", OAFwkConstants.STATEMENT);
         Number requestId = (Number)pageContext.getTransactionValue("BULK_EXP_REQUEST_ID");
         String sCustomerId = (String)pageContext.getTransactionValue("customerId");
         String customerNum = (String) pageContext.getTransactionValue("txnCustomerNum"); 
  
         HashMap hMap = new HashMap();
         hMap.put("IsBulkExportRequests", "Y");
         hMap.put("requestId", requestId);
         hMap.put("customerId", sCustomerId);
         hMap.put("customerNum", customerNum);                              
         hMap.put("OA_SubTabIdx",1);
         pageContext.forwardImmediately("OA.jsp?region=/od/oracle/apps/xxfin/ar/irec/accountDetails/blkexp/webui/ODIrecBlkExpMainRN&OA_SubTabIdx=1",
         null,
         OAWebBeanConstants.KEEP_MENU_CONTEXT,
         null,
         hMap,
         true, // retain AM
         OAWebBeanConstants.ADD_BREAD_CRUMB_NO);  
         
                                
         
       } else 
       {
         pageContext.writeDiagnostics(this, "Bulk Export Submission resulted in Error "+result, OAFwkConstants.STATEMENT);
         throw new OAException("ulk Export Submission failed "+result);
       }
    }
    
  }

}
