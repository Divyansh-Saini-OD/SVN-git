package od.oracle.apps.fnd.cp.viewreq.webui;

/*----------------------------------------------------------------------------
 -- Author: Madhu Bolli
 -- Script Location: $XXCOMN_TOP/java/oracle/apps/fnd/cp/viewreq/webui
 -- History:
 -- Name            Date         Version    Description
 -- -----           -----        -------    -----------
 -- Madhu Bolli   14-Mar-2017    1.0        defect#41197 - iRec PDFCopy Invoice
 --                                     execute other initSummary for Consolidated Invoice.
 -- Madhu Bolli   21-Apr-2017    1.1         PDF Copy - Refresh Functionality and showing View Output
---------------------------------------------------------------------------*/
import java.io.Serializable;

import java.util.Date;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.cp.viewreq.webui.ViewRequestsPageCO;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAStaticStyledTextBean;
import oracle.apps.fnd.framework.webui.beans.OASwitcherBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;
import java.util.Vector;
import oracle.apps.fnd.cp.viewreq.server.RequestSummarySearchVOImpl;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.server.OADBTransaction;

import oracle.apps.fnd.functionSecurity.Function;
import oracle.apps.fnd.functionSecurity.FunctionSecurity;


import java.sql.CallableStatement;
import java.sql.Types;
import java.sql.SQLException;

import oracle.cabo.ui.data.DataObject;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServletResponse;
import oracle.apps.fnd.framework.OAApplicationModule;
import java.sql.Blob;

import java.sql.ResultSet;
import java.sql.PreparedStatement;

import oracle.cabo.style.CSSStyle;


public class ODViewRequestsPageCO extends ViewRequestsPageCO
{
  public ODViewRequestsPageCO()
  {
  }
  

  public void processRequest(OAPageContext pageContext, OAWebBean webBean) {
  

    String isPDFCopyRequest = pageContext.getParameter("IsPDFCopyReq");
    if(isPDFCopyRequest == null || "".equals(isPDFCopyRequest.trim())) 
    {
       isPDFCopyRequest = (String)pageContext.getTransactionValue("IS_PDF_COPY_REQ");
    }
    
    if("Y".equals(isPDFCopyRequest)) {
      Object reqViewOutput = pageContext.getParameter("OUTPUT");
       
       if ((reqViewOutput != null) && (((String)reqViewOutput).equals("Y")))
       {
          viewRequestOutput(pageContext, webBean);
          return;
       }
    }

    super.processRequest(pageContext, webBean);

    if("Y".equals(isPDFCopyRequest)) {
      pageContext.putTransactionValue("IS_PDF_COPY_REQ", isPDFCopyRequest);
      handlePdfCopyViewRequests(pageContext, webBean);
    }
    
    String isBulkExportRequests = (String)pageContext.getTransactionValue("IsBulkExportRequests");
    if ("Y".equals(isBulkExportRequests))
    {
      handleBulkExportViewRequests(pageContext, webBean);
    }                 
  }
  
  public void handlePdfCopyViewRequests(OAPageContext pageContext, OAWebBean webBean)
  {

    String sTrxNumber = pageContext.getParameter("trxNumber");    
    String custTrxId = pageContext.getParameter("customerTrxId");
    pageContext.putTransactionValue("tCustomerTrxId", custTrxId);
    
    OAPageLayoutBean pgLytBn = (OAPageLayoutBean) pageContext.getPageLayoutBean();
    pgLytBn.setTitle("Requests for Transaction "+sTrxNumber);
    
    OATableBean reqSumTblBn = (OATableBean)webBean.findIndexedChildRecursive("RequestSummarySearchVO");
    
    if(reqSumTblBn != null) 
    {
      OAWebBean reqIdCol = (OAWebBean)reqSumTblBn.findIndexedChildRecursive("FndAdvRequestId");
      if(reqIdCol != null) reqIdCol.setRendered(false);
      OAWebBean reqProgNameCol = (OAWebBean)reqSumTblBn.findIndexedChildRecursive("Fndcpadvprogramnamedisplay");
      if(reqProgNameCol != null) reqProgNameCol.setRendered(false);
      OAWebBean reqDetailCol = (OAWebBean)reqSumTblBn.findIndexedChildRecursive("Fndcpadvreqdetails");
      if(reqDetailCol != null) reqDetailCol.setRendered(false);
      OAWebBean reqRepublishCol = (OAWebBean)reqSumTblBn.findIndexedChildRecursive("Fndcpadvreqrepublishswitcher");
      if(reqRepublishCol != null) reqRepublishCol.setRendered(false); 

      webBean.findIndexedChildRecursive("FndCpSubmitReq").setRendered(false);
      webBean.findIndexedChildRecursive("Fndcpreqsimplesearchreg").setRendered(false);
      webBean.findIndexedChildRecursive("Fndcpreqadvsearchreg").setRendered(false);
      webBean.findIndexedChildRecursive("Fndcpseparator").setRendered(false);
    
    }
    
    // Begin - handling of Duplicate PDF Copy Concurrent Request
     String isPdfCopyDupReq = pageContext.getParameter("IsPDFCopyDuplicateReq"); 
     
     pageContext.writeDiagnostics(this, "ODVIewRequestsPageCO.PR() - trxNumber : "+sTrxNumber, OAFwkConstants.STATEMENT);
     
     String isIrecConsInv = pageContext.getParameter("IsIrecConsolidateInvoice");
 
     String requestId = pageContext.getParameter("parentRequestId");
     if(requestId == null || "".equals(requestId.trim())) 
     {
        requestId = pageContext.getParameter("requestId");
     }
     pageContext.putTransactionValue("submittedRequestId", requestId);
    
     OAException message = null;
     String msgTkn2 = "";
     if("Y".equals(isPdfCopyDupReq)) 
     {
       requestId = pageContext.getParameter("parentRequestId");
       if(requestId == null || "".equals(requestId.trim())) 
       {
         requestId = pageContext.getParameter("requestId");
       }
          msgTkn2 = " already ";
          MessageToken[] tokens = { new MessageToken("TRX_NUM", sTrxNumber), 
                   new MessageToken("IS_DUP_REQ", msgTkn2)}; 
          message = new OAException("XXFIN", "XX_ARI_INV_PDF_COPY_MSG", tokens, OAException.WARNING, null);
          pageContext.writeDiagnostics(this, "PDF Copy Duplicate Request Id "+requestId, OAFwkConstants.STATEMENT);
     } else 
     {
       msgTkn2 = "";
       MessageToken[] tokens = { new MessageToken("TRX_NUM", sTrxNumber), 
                   new MessageToken("IS_DUP_REQ", msgTkn2)}; 
       message = new OAException("XXFIN", "XX_ARI_INV_PDF_COPY_MSG", tokens, OAException.CONFIRMATION, null);
     }
    
     pageContext.putDialogMessage(message); 
    
    // End - handling of Duplicate PDF Copy Concurrent Request
    
    
    // Below code to handle for Consolidated Invoice
    
    if ("Y".equals(isIrecConsInv)) 
    {
      Serializable[] paramValues = null;
      Serializable[] paramTypes = null;
     // OATableBean reqSumTblBn = (OATableBean)webBean.findIndexedChildRecursive("RequestSummarySearchVO");
      int i = 10;
      if(reqSumTblBn != null) 
      {
         i = reqSumTblBn.getNumberOfRowsDisplayed();
      }  
    
      OAViewObject reqSumSrchVO = (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("RequestSummarySearchVO");
      if (reqSumSrchVO.getRangeSize() < i) {
        reqSumSrchVO.setRangeSize(i);
      }      
      String parentReqId = pageContext.getParameter("parentRequestId");
      
      if (parentReqId != null)
      {
    //       String reqSumVOPred = ((OAViewObjectImpl)reqSumSrchVO).getPredicate();
        paramValues = new Serializable[] { parentReqId, null, null, null, null, null, null, null, "Y", null, null };
        paramTypes = new Class[] { String.class, String.class, String.class, Date.class, Date.class, String.class, String.class, String.class,String.class, String.class, String.class };
        
        reqSumSrchVO.invokeMethod("initSummary", (Serializable[])paramValues, (Class[])paramTypes); 

        // By disabling below regions, the simple search VO's doesn't execute again.
        webBean.findIndexedChildRecursive("Fndcpreqsimplesearchreg").setRendered(false);
        webBean.findIndexedChildRecursive("Fndcpreqadvsearchreg").setRendered(false);
        webBean.findIndexedChildRecursive("Fndcpseparator").setRendered(false);
        
      }      
    }  // end of if ("Y".equals(isIrecConsInv))   
  }
  

  public void handleBulkExportViewRequests(OAPageContext pageContext, OAWebBean webBean)
  {
      OATableBean reqSumTblBn = (OATableBean)webBean.findIndexedChildRecursive("RequestSummarySearchVO");
    
      int i = 10;
      if(reqSumTblBn != null) 
      {
        OAWebBean reqIdCol = (OAWebBean)reqSumTblBn.findIndexedChildRecursive("FndAdvRequestId");
        if(reqIdCol != null) reqIdCol.setRendered(false);
        OAWebBean reqProgNameCol = (OAWebBean)reqSumTblBn.findIndexedChildRecursive("Fndcpadvprogramnamedisplay");
        if(reqProgNameCol != null) reqProgNameCol.setRendered(false);
     /**   OAWebBean reqDetailCol = (OAWebBean)reqSumTblBn.findIndexedChildRecursive("Fndcpadvreqdetails");
        if(reqDetailCol != null) reqDetailCol.setRendered(false);  **/
        OAWebBean reqRepublishCol = (OAWebBean)reqSumTblBn.findIndexedChildRecursive("Fndcpadvreqrepublishswitcher");
        if(reqRepublishCol != null) reqRepublishCol.setRendered(false); 

        OAWebBean reqCustomerNo = (OAWebBean)reqSumTblBn.findIndexedChildRecursive("XXODBlkExpFndcpadvreqCustomerNo");
        if(reqCustomerNo != null) reqCustomerNo.setRendered(true);          
        
        OAStaticStyledTextBean tipTextBn = (OAStaticStyledTextBean)webBean.findIndexedChildRecursive("TestStaticTip");
        if(tipTextBn != null) 
        {
          MessageToken[] tokens = { new MessageToken("REQ_OUTPUT_TYPE1", "Excel Output"), 
                   new MessageToken("REQ_OUTPUT_TYPE2", "Excel")}; 
          tipTextBn.setText(pageContext.getMessage("XXFIN", "XX_ARI_FND_VIEW_REQ_TIP", tokens));
          CSSStyle cellBGColor = new CSSStyle();
          cellBGColor.setProperty("color","#0000FF"); 
          tipTextBn.setInlineStyle(cellBGColor);
        }
          
        OASwitcherBean reqOutputSwtchCol = (OASwitcherBean)reqSumTblBn.findIndexedChildRecursive("Fndcpadvreqoutputswitcher");
        if(reqOutputSwtchCol != null) 
        {
            reqOutputSwtchCol.setAttributeValue(PROMPT_ATTR, "Excel Output");
        }             
        
        i = reqSumTblBn.getNumberOfRowsDisplayed();
      }
                
      OAViewObject reqSumSrchVO = (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("RequestSummarySearchVO");
      if (reqSumSrchVO.getRangeSize() < i) {
        reqSumSrchVO.setRangeSize(i);
      }      
      
      String requestId = pageContext.getParameter("requestId");
      String sCustomerId = pageContext.getParameter("customerId");
      String customerNum = pageContext.getParameter("customerNum");
      
      if (requestId != null) {
        MessageToken[] tokens = { new MessageToken("CUST_NUMBER", customerNum)}; 
        OAException message = new OAException("XXFIN", "XX_ARI_BLK_EXP_CONF_MSG", tokens, OAException.CONFIRMATION, null);
        pageContext.putDialogMessage(message);
      }
      
      bulkExportViewReqExecute(pageContext, webBean);    
      

      // Hide the 'Simple Search'/'Advanced Search' regions
      webBean.findIndexedChildRecursive("Fndcpreqsimplesearchreg").setRendered(false);
      webBean.findIndexedChildRecursive("Fndcpreqadvsearchreg").setRendered(false);
      webBean.findIndexedChildRecursive("Fndcpseparator").setRendered(false);

      if (reqSumTblBn != null)    {
        ((OATableBean)reqSumTblBn).prepareForRendering(pageContext);
      }      
  }

  public void bulkExportViewReqExecute(OAPageContext pageContext, OAWebBean webBean)
  {
    OAApplicationModuleImpl cpViewReqAM = (OAApplicationModuleImpl)pageContext.getApplicationModule(webBean);
    RequestSummarySearchVOImpl reqSumSrchVO = (RequestSummarySearchVOImpl)cpViewReqAM.findViewObject("RequestSummarySearchVO");

    String str1 = "";
    OADBTransactionImpl localOADBTransactionImpl = (OADBTransactionImpl)cpViewReqAM.getDBTransaction();
    Integer iUserId = new Integer(localOADBTransactionImpl.getUserId());
    String sPredicate = getPredicate(pageContext, webBean);
    Vector localVector = new Vector();
    String requestId = pageContext.getParameter("requestId");
    String viewReqDays = pageContext.getProfile("OD_IREC_EXPORT_VIEW_REQ_DAYS");
    if (viewReqDays == null || "".equals(viewReqDays.trim()))  {
      viewReqDays="7";
    }   
    
    
    reqSumSrchVO.setWhereClause(null);
    reqSumSrchVO.setWhereClauseParams(null);
    str1 = "( requested_by =:1 )";
    
    /** we dont need to check the predicate for the bulk export.
     * We show only the requests of that requested user to him
    if (!"(1=2)".equals(sPredicate)) {
      str1 = "( requested_by =:1  or " + sPredicate + ")";
    } else {
      str1 = "( requested_by =:1 )";
    }
    **/
    localVector.addElement(iUserId);
    str1 = str1 + " and ((program_short_name in ('XXARIINVHDR', 'XXARIINVLI', 'XXARIALTXHDR', 'XXARIALTXLI', 'XXARIALTXHDRLI', 'XXARIADBHDR', 'XXARIADBLI' ) ";
    str1 = str1 + " or (request_id = "+requestId+"  and not exists (select 'CHILD_SUBMITTED'  from fnd_concurrent_requests where parent_request_id = "+requestId+" ))) ";
    str1 = str1 + " and (request_date >= trunc(SYSDATE - "+viewReqDays+")))";
    reqSumSrchVO.setWhereClause(str1);
    reqSumSrchVO.setWhereClauseParam(0, localVector.elementAt(0));
    reqSumSrchVO.setOrderByClause("requested_start_date desc");
    reqSumSrchVO.executeQuery();


    

  }

  private String getPredicate(OAPageContext pageContext, OAWebBean webBean)
  {
    OAApplicationModuleImpl cpViewReqAM = (OAApplicationModuleImpl)pageContext.getApplicationModule(webBean);
    OADBTransactionImpl localOADBTransactionImpl = (OADBTransactionImpl)cpViewReqAM.getDBTransaction();
    FunctionSecurity localFunctionSecurity = localOADBTransactionImpl.getFunctionSecurity();
    Function localFunction = localFunctionSecurity.getFunction("FND_CP_REQ_VIEW");
    String str = localFunctionSecurity.getSecurityPredicate(localFunction, localFunctionSecurity.getDataContext(null, "FND_CONCURRENT_REQUESTS", null, null, null, null, null), null, null, null);
    return str;
  }  
  
  
 
       public void processFormRequest(OAPageContext pageContext, OAWebBean webBean) {
       
         
         super.processFormRequest(pageContext, webBean);
         
         // In iReceivables, for PDF Copy, we fire the CP request and shows the View Requests page. User has to click on 'Refresh' button 
         // to see the updated results. If the CP completes, then we need to save the CP Request output into a table and that trigger point
         // is from the 'Refresh' button.
		 
		 String isPdfCopyReq = (String)pageContext.getTransactionValue("IS_PDF_COPY_REQ");
         if (("Y".equals(isPdfCopyReq)) && (pageContext.getParameter("Refresh") != null))
         {
           String reqPhase = null;
           String reqStatus = null;
           Number reqId = null;
           
           String custTrxId = (String)pageContext.getTransactionValue("tCustomerTrxId");
           if(custTrxId == null || "".equals(custTrxId.trim())) 
           {
             pageContext.writeDiagnostics(this, "ODViewRequestsPageCO.PFR() - PDF Copy Saving - Customer Trx Id Value is Null", 1);
             return;             
           }
           String sReqId = (String)pageContext.getTransactionValue("submittedRequestId");
           if(sReqId == null || "".equals(sReqId.trim())) 
           {
             pageContext.writeDiagnostics(this, "ODViewRequestsPageCO.PFR() - PDF Copy Saving - RequestId Value is Null", 1);
             return;             
           }           
                      
            RequestSummarySearchVOImpl reqSumVO = (RequestSummarySearchVOImpl)pageContext.getApplicationModule(webBean).findViewObject("RequestSummarySearchVO");
            if(reqSumVO != null) {
             OARow reqSumRow = (OARow)  reqSumVO.first();
             if (reqSumRow != null) 
             {
               reqPhase = (String)reqSumRow.getAttribute("PhaseCode");
               reqStatus = (String)reqSumRow.getAttribute("StatusCode");
              // reqId = (Number)reqSumRow.getAttribute("RequestId");
             }
             
            }
            
            int iRequestId;
            if(sReqId != null) 
            {
              try  {
                iRequestId = Integer.parseInt(sReqId);  // reqId.intValue();
              } catch(Exception Nofe) 
              {
                pageContext.writeDiagnostics(this, "ODViewRequestsPageCO.PFR() - PDF Copy Saving - RequestId Conversion Exception "+Nofe.getMessage(), 1);
                return;
              }
            } else 
            {
              pageContext.writeDiagnostics(this, "ODViewRequestsPageCO.PFR() - PDF Copy Saving - RequestId Value is NULL", 1);
              return;
            }
            
            if ("C".equals(reqPhase) && "C".equals(reqStatus)) 
            {
              OADBTransaction txn = ((OAApplicationModuleImpl)pageContext.getApplicationModule(webBean)).getOADBTransaction();
              CallableStatement ocs = null;
              String resultErrorBuf = null;
              String resultRetCode = null;
              
              try
              {
                ocs = txn.createCallableStatement("call XX_ARI_INVOICE_COPY_PKG.save_pdf_invoice_copy(?,?,?,?)",0);
                ocs.registerOutParameter(1,Types.VARCHAR);
                ocs.registerOutParameter(2,Types.INTEGER);  
                ocs.setString(3, custTrxId);
                ocs.setInt(4, iRequestId);
                              
                ocs.execute();

                resultRetCode = ocs.getString(1);
                resultErrorBuf = ocs.getString(2);
                
              }
              catch(Exception ex)
              {
                pageContext.writeDiagnostics(this, "ODViewRequestsPageCO.PFR() - Refresh Button - Saving PDF Invoice Copy throw error - "+ex.getStackTrace(), 1);
                throw new OAException(ex.toString());
              }
              finally {
                try {if (ocs != null) ocs.close();}
                  catch(Exception ex2) {};
              }                 
              if ("0".equals(resultRetCode))  // Success
              {
                pageContext.writeDiagnostics(this, "ODViewRequestsPageCO.PFR() - PDF Copy completed successfully and updated the PDF Copy to the table", 1);
              } else 
              {
                pageContext.writeDiagnostics(this, "ODViewRequestsPageCO.PFR() - PDF Copy completed but not saved into the table. Error Message is "+resultErrorBuf, 1);
              }                          
            }
           return;
         }                  
       }  


    public void viewRequestOutput(OAPageContext pageContext, OAWebBean webBean) 
    {
        String reqId = null;
        byte[] baInvoice = null;
        Blob baPDF = null; 
        int iReqId;
        
        reqId = pageContext.getParameter("REQUESTID");
        
        try {
          iReqId = Integer.parseInt(reqId);
        } catch (Exception exc) 
        {
          pageContext.writeDiagnostics(this, "ODViewRequestsPageCO.PR() - View output - RequestId value is Invalid "+exc.getMessage(), 1);
          sendToErrorPage(pageContext);
          return;
        }
        
        ResultSet rs = null;
        PreparedStatement cs = null;
        
        try {
           String Query=" SELECT document_data FROM XX_XDO_REQUEST_DOCS_WEB WHERE request_id = :1";
          OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);
          cs=(PreparedStatement)am.getOADBTransaction().getJdbcConnection().prepareStatement(Query);
          cs.setInt(1, iReqId);
          rs=cs.executeQuery();
          while(rs.next())
          {
              
              baPDF = rs.getBlob(1); 
              baInvoice = baPDF.getBytes(1, (int) baPDF.length());
          }
        } catch (Exception exc) {
          // The driver could not handle this as a BLOB...
          // Fallback to default (and slower) byte[] handling
          try {
           baInvoice = rs.getBytes(1);
          } catch(SQLException sqle) 
          {
            pageContext.writeDiagnostics(this, "ODViewRequestsPageCO.PR() - View output - failed Blob reading - "+sqle.getMessage(), 1);
            sendToErrorPage(pageContext);
            return;            
          }
        }
        finally 
        {
          try {
           if (rs != null) 
             rs.close();
           
           if(cs != null)
             cs.close();
          } catch (Exception exc) 
          {
            pageContext.writeDiagnostics(this, "ODViewRequestsPageCO.PR() - View Output failed "+exc.getMessage(), 1);
          }
        }
        
        if (baInvoice == null || baInvoice.length == 0) 
        {
          pageContext.writeDiagnostics(this, "ODViewRequestsPageCO.PR() - View Output failed with pdf output length less than 0", 1);
          sendToErrorPage(pageContext);
          return;
        }
        
        pageContext.writeDiagnostics(this, "ODViewRequestsPageCO.PR() - View Output - Retrieving output from Blob", 1);
        try {
          DataObject dataobject = pageContext.getNamedDataObject("_SessionParameters");
          HttpServletResponse httpservletresponse = (HttpServletResponse)dataobject.selectValue(null, "HttpServletResponse");
          ServletOutputStream servletoutputstream = httpservletresponse.getOutputStream();
          httpservletresponse.setContentType("application/pdf");
          httpservletresponse.setContentLength(baInvoice.length);
          servletoutputstream.write(baInvoice, 0, baInvoice.length);
          servletoutputstream.flush();
          servletoutputstream.close();// *important* to ensure no more jsp output
          return;
        }
        catch(Exception ex)
        {
          pageContext.writeDiagnostics(this, "ODViewRequestsPageCO.PR() - View Output failed with pdf while streaming "+ex.getMessage(), 1);
          sendToErrorPage(pageContext);
        }                     
    }
    
    public void sendToErrorPage(OAPageContext pageContext) {
      try{
              pageContext.sendRedirect("/XXFIN_HTML/iRecContactUsLinks.htm");
      } 
      catch (Exception ee){} 
    }
       
}
