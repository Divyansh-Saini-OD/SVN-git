/*===========================================================================+
 |   Copyright (c) 2001, 2003 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.cdh.uploads.bulk.webui;
/* Subversion Info:
 * $HeadURL$
 * $Rev$
 * $Date$
*/
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
//Added by Mangala
import oracle.apps.fnd.framework.OAApplicationModule;
import od.oracle.apps.xxcrm.cdh.ebl.server.ODUtil;
import oracle.apps.fnd.framework.OAException;
import oracle.cabo.ui.data.DataObject;
import oracle.jbo.domain.BlobDomain;
import oracle.jbo.domain.ClobDomain;
import oracle.cabo.ui.data.DictionaryData;
import java.io.PrintWriter;
import java.io.Serializable;


import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jbo.domain.Number;
import oracle.cabo.ui.RenderingContext;
import javax.servlet.http.HttpServletResponse;
//import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageFileUploadBean;


/**
 * Controller for ...
 */
public class ODImportToolCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");
  Object reqId = null;
  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    ODUtil utl = new ODUtil(am);
    //Fetching header details
    OAViewObject templVO = (OAViewObject) am.findViewObject("ODImportToolTempVO");
    templVO.executeQuery();
    OAViewObject mainVO = (OAViewObject) am.findViewObject("ODImportToolsVO"); 
    mainVO.executeQuery();
    OAViewObject poplistVO = (OAViewObject) am.findViewObject("ODImportToolTemplatePVO");
    //Below is the code to implement the security feature in the PVO values listed.
    poplistVO.setWhereClause("responsibility_id = " +  pageContext.getResponsibilityId() );
    poplistVO.executeQuery();
    utl.log(pageContext.getParameter("poplistVO count:" + poplistVO.getRowCount()));
    // Code to fetch the Upload Type from xxtps_template_file_uploads region to be diaplayed in the Files Uploaded region
    OAViewObject clobCodePVO = (OAViewObject) am.findViewObject("ODImportTempNameFilesPVO");
    clobCodePVO.setWhereClause("responsibility_id = " +  pageContext.getResponsibilityId() );
    clobCodePVO.executeQuery();
   /* // To display the created By column
    OAViewObject createdByPVO = (OAViewObject) am.findViewObject("ODImportToolFileUpdByPVO");
    createdByPVO.setWhereClause("user_id = " +  pageContext.getParameter("CreatedBy") );
    createdByPVO.executeQuery();*/
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
    ODUtil utl = new ODUtil(am);
    super.processFormRequest(pageContext, webBean);
    String strFileName = null;
    String strLocalFileName = null;
    utl.log(pageContext.getParameter(EVENT_PARAM));
    Serializable[] param = null;
    String fileName= null;
    
    pageContext.writeDiagnostics(this, "in PFR " + pageContext.getParameter(EVENT_PARAM), 1);
       
    DataObject fileUploadData = pageContext.getNamedDataObject("fileUpload");
    OAMessageFileUploadBean fileUploadBean = (OAMessageFileUploadBean)webBean.findIndexedChildRecursive("fileUpload");
    fileUploadBean.getValue(pageContext);
    String str = (String)  fileUploadBean.getValue(pageContext); 
    //utl.log("File Upload Data value" + fileUploadData);
    //utl.log("File Upload Bean value" + str);
    if (pageContext.getParameter("upload") != null && fileUploadData == null)
    {
      throw new OAException("Please select a file to upload", OAException.ERROR);
            
    }
    
  if (fileUploadData != null)
    {
      strLocalFileName = (String)fileUploadData.selectValue(null, "UPLOAD_FILE_NAME");
      strFileName = strLocalFileName;
      utl.log("strFileName: " + strFileName);
    } 

    // Code for Upload Button click in the File Upload region
    if (pageContext.getParameter("upload") != null)
    {
      //utl.log("Inside Upload click");
      if (str==null)
      {
        throw new OAException("Please select a file to upload", OAException.ERROR);
      }
      if (str !=null)
      {
      //utl.log("Inside s not null");
      if (isCsvFile(pageContext,webBean,strFileName))
      {
        doUpload( pageContext, webBean);
        OAViewObject mainVO = (OAViewObject) am.findViewObject("ODImportToolsVO"); 
        mainVO.executeQuery();
         fileUploadBean.setValue(pageContext,null); 
        throw new OAException("The file " + strLocalFileName +
              " has been uploaded successfully.", OAException.CONFIRMATION);                           
      } // End of Is CSV
      else 
      {
         throw new OAException ("Only CSV files are supported for uploads!");                                            
      } // end of else
      }
    }// End of Upload Event

    // Code for getting the Excel file when clicking on the File name in the Files Uploaded region
    if("Download".equals(pageContext.getParameter(EVENT_PARAM) ))
    {      
      utl.log("Inside Download");   
      String fileId = pageContext.getParameter("p_file_id"); 
      OAViewObject clobVO = (OAViewObject) am.findViewObject("ODImportToolsVO");
      clobVO.executeQuery(); 
      OARow row = (OARow) clobVO.first();
      utl.log("After First Row: File id:" + fileId); 
      ClobDomain b = null;
      
      while(row != null)
      {
        String fId = row.getAttribute("FileUploadId").toString() ;
       // utl.log("inside while: fId: " + fId);  
        if(fileId.equals(fId))
        {
          utl.log("inside if");
          b = (ClobDomain)row.getAttribute("FileData");
          String fName =(String) row.getAttribute("FileName");
          pageContext.putSessionValue("fNameSessVal", fName);
          //utl.log("inside while: fName: " + fName); 
          break;
        }    
        row = (OARow) clobVO.next();
      }
  
      DictionaryData sessionDictionary =(DictionaryData) pageContext.getNamedDataObject("_SessionParameters"); 
      try  
      {
        String ufileName = (String) pageContext.getSessionValue("fNameSessVal"); 
        RenderingContext con = (RenderingContext) pageContext.getRenderingContext(); 
        HttpServletResponse response = (HttpServletResponse)sessionDictionary.selectValue(con,"HttpServletResponse"); 
        String contentType =  "application/csv";        
        response.setHeader("Content-disposition", "attachment; filename=\"" + ufileName +"\"");
        response.setContentType(contentType);
        PrintWriter out = response.getWriter();
        out.print(b.toString()); 
        pageContext.setDocumentRendered(false);
        out.close();
      } 
 
      catch (Exception e)
      { 
        e.printStackTrace(); 
      }
      
    } // End of Download Action
  // Code for getting the Excel file when clicking on the Error Icon in the Files Uploaded region
  if("error".equals(pageContext.getParameter(EVENT_PARAM) )) 
     {
      utl.log("Inside Error File Data"); 
      String fileId1 = pageContext.getParameter("p_file"); 
      //utl.log("Fild Id is :" + fileId1);
      OAViewObject clobVO = (OAViewObject) am.findViewObject("ODImportToolsVO");
      clobVO.executeQuery(); 
      OARow row = (OARow) clobVO.first();
      ClobDomain b = null;
      
      while(row != null)
      {
         String fileId2 = row.getAttribute("FileUploadId").toString() ;
       // utl.log("inside while: fId: " + fileId2);  
        if(fileId1.equals(fileId2))
        {
          utl.log("inside if");
          b = (ClobDomain)row.getAttribute("ErrorFileData");
          String fName =(String) row.getAttribute("FileName");
          pageContext.putSessionValue("fNameSessVal", fName);
         // utl.log("inside while: fName: " + fName); 
          break;
        }
        row = (OARow) clobVO.next();
      }
  
      DictionaryData sessionDictionary =(DictionaryData) pageContext.getNamedDataObject("_SessionParameters"); 
      try  
      {
        String ufileName = (String) pageContext.getSessionValue("fNameSessVal"); 
        RenderingContext con = (RenderingContext) pageContext.getRenderingContext(); 
        HttpServletResponse response = (HttpServletResponse)sessionDictionary.selectValue(con,"HttpServletResponse"); 
        String contentType =  "application/csv";        
        response.setHeader("Content-disposition", "attachment; filename=\"" + "Error_" + ufileName + "\"");
        response.setContentType(contentType);
        PrintWriter out = response.getWriter();
        out.print(b.toString()); 
        pageContext.setDocumentRendered(false);
        out.close();
      } 
 
      catch (Exception e)
      { 
        e.printStackTrace(); 
      }

     
     } // End of Error File Data

      // Code for getting the Excel file when clicking on the Out File Icon in the Files Uploaded region
 if("output".equals(pageContext.getParameter(EVENT_PARAM) )) 
     {
      utl.log("Inside Output File Data"); 
      String fileId1 = pageContext.getParameter("p_file"); 
     // utl.log("Fild Id is :" + fileId1);
      OAViewObject clobVO = (OAViewObject) am.findViewObject("ODImportToolsVO");
      clobVO.executeQuery(); 
      OARow row = (OARow) clobVO.first();
      ClobDomain b = null;
      
      while(row != null)
      {
         String fileId2 = row.getAttribute("FileUploadId").toString() ;
        //utl.log("inside while: fId: " + fileId2);  
        if(fileId1.equals(fileId2))
        {
          utl.log("inside if");
          b = (ClobDomain)row.getAttribute("OutputFileData");
          String fName =(String) row.getAttribute("FileName");
          pageContext.putSessionValue("fNameSessVal", fName);
          utl.log("inside while: fName: " + fName); 
          break;
        }
        row = (OARow) clobVO.next();
      }
  
      DictionaryData sessionDictionary =(DictionaryData) pageContext.getNamedDataObject("_SessionParameters"); 
      try  
      {
        String ufileName = (String) pageContext.getSessionValue("fNameSessVal"); 
        RenderingContext con = (RenderingContext) pageContext.getRenderingContext(); 
        HttpServletResponse response = (HttpServletResponse)sessionDictionary.selectValue(con,"HttpServletResponse"); 
        String contentType =  "application/csv";        
        response.setHeader("Content-disposition", "attachment; filename=\"" + "Output_" + ufileName + "\"");
        response.setContentType(contentType);
        PrintWriter out = response.getWriter();
        out.print(b.toString()); 
        pageContext.setDocumentRendered(false);
        out.close();
      } 
 
      catch (Exception e)
      { 
        e.printStackTrace(); 
      }

     
     } // End of Output File Data

// Code for Process Button Click in the Files Uploaded region
   if ("uploadAction".equals(pageContext.getParameter(EVENT_PARAM)))
   {
     
     utl.log ("Inside Upload Action Button click");
     String fileUploadId = pageContext.getParameter("p_fileupload_id");
     utl.log("Fild Upload Id is :" + fileUploadId);
     OAViewObject mainVO = (OAViewObject) am.findViewObject("ODImportToolsVO");
     mainVO.executeQuery(); 
     OARow row = (OARow) mainVO.first();
      while(row != null)
      {
        String fileIdVal = row.getAttribute("FileUploadId").toString() ;
        utl.log("inside while: file Upload Id - Upload Action: " + fileIdVal);  
        if(fileUploadId.equals(fileIdVal))
       {
        param = new Serializable[4];
        param[0] = "" + pageContext.getUserId();
        param[1] = "" + pageContext.getResponsibilityId();
        param[2] = "" + pageContext.getResponsibilityApplicationId();
        param[3] = fileIdVal;
        reqId = "" ;
        //Included the following set attribute code, commit to change the status to Running after Process is clicked on.
        row.setAttribute ("FileStatus","R");
      	am.getTransaction().commit();
        utl.log("Before invoking Upload Action");
        reqId= am.invokeMethod ("uploadAction", param);
        utl.log("After Upload Action method execution");
        utl.log("Request Id: " + reqId);
         //Added to disable the Process Button and Cancel after clicking it for processing
         row.setAttribute("UploadAction",Boolean.TRUE);
   
       /* OAException msg2 = new OAException ("A Concurrent Request  " +
                                                   "is submitted to create the Leads." +
                                                   "  \nThe Request Id is: " + reqId + ".", OAException.INFORMATION);*/
        OAException msg2 = new OAException ("A Concurrent Request  " + reqId + " is submitted.",OAException.INFORMATION);                                               
        pageContext.putDialogMessage(msg2);
        utl.log("Message" + msg2);
        break;
        }
        row = (OARow) mainVO.next();
       }
      
      
   } // End of UploadAction

   // Clcik of Refresh button
  if (pageContext.getParameter("Refresh") != null) 
  {
     OAViewObject mainVO = (OAViewObject) am.findViewObject("ODImportToolsVO");
     mainVO.executeQuery(); 
  } // End of Refresh


//Click of Cancel Button
  if ("cancel".equals(pageContext.getParameter(EVENT_PARAM)))
  {
     utl.log ("Inside Cancel Action");
     String fileUpdId = pageContext.getParameter("p_file_idval");
     utl.log ("Inside Cancel Action: File Upload Id :" + fileUpdId);
   /*  OASubmitButtonBean submitButton = (OASubmitButtonBean)webBean.findIndexedChildRecursive("Action");
     submitButton.setDisabled(true);
     OASubmitButtonBean submitButton1 = (OASubmitButtonBean)webBean.findIndexedChildRecursive("cancel");
     submitButton1.setDisabled(true);*/
  
     OAViewObject mainVO = (OAViewObject) am.findViewObject("ODImportToolsVO");
     mainVO.executeQuery(); 
     OARow row = (OARow) mainVO.first();
      while(row != null)
      {
        String fileId = row.getAttribute("FileUploadId").toString() ;
        utl.log("inside while: file Upload Id - Cancel: " + fileId);  
        if(fileUpdId.equals(fileId))
       {
        row.setAttribute("FileStatus","X");
        am.getTransaction().commit();
         //Added to disable the Process Button and Cancel after clicking the Cancel Button
       row.setAttribute("UploadAction",Boolean.TRUE);
        break;
       }
       row = (OARow) mainVO.next();
      }
  } // End of Cancel

  // Code for getting the Excel file when clicking on the Template name in the Templates region
  if("templateDownload".equals(pageContext.getParameter(EVENT_PARAM) ))
    {      
      utl.log("Inside templateDownload");   
      String templateId = pageContext.getParameter("p_template_id"); 
      OAViewObject templateVO = (OAViewObject) am.findViewObject("ODImportToolTempVO");
      templateVO.executeQuery(); 
      OARow row = (OARow) templateVO.first();
      utl.log("Template id:" + templateId); 
      ClobDomain b = null;
      
      while(row != null)
      {
        String tempId = row.getAttribute("TemplateFileUploadId").toString() ;
        utl.log("inside while: tempId: " + tempId);  
        if(templateId.equals(tempId))
        {
          utl.log("inside if");
          b = (ClobDomain)row.getAttribute("TemplateCsv");
          String tempName =(String) row.getAttribute("TemplateName") + ".csv"; // Appending this .csv with the filename so that the file will be opened in csv format.Else it will not be in csv format
          pageContext.putSessionValue("tempNameSessVal", tempName);
          utl.log("inside while: tempName: " + tempName); 
          break;
        }    
        row = (OARow) templateVO.next();
      }
        pageContext.writeDiagnostics(this, "File Contents: "+b.toString(), 1);
  
      DictionaryData sessionDictionary =(DictionaryData) pageContext.getNamedDataObject("_SessionParameters"); 
      try  
      {
        String templateName = (String) pageContext.getSessionValue("tempNameSessVal"); 
        RenderingContext con = (RenderingContext) pageContext.getRenderingContext(); 
        HttpServletResponse response = (HttpServletResponse)sessionDictionary.selectValue(con,"HttpServletResponse"); 
        String contentType =  "application/csv";        
        response.setHeader("Content-disposition", "attachment; filename=\"" + templateName +"\"");
        response.setContentType(contentType);
        pageContext.writeDiagnostics(this, "before calling getWriter", 1);
        
        PrintWriter out = response.getWriter();
        pageContext.writeDiagnostics(this, "after calling getWriter", 1);
        out.print(b.toString()); 
        pageContext.writeDiagnostics(this, "after calling print", 1);
        pageContext.setDocumentRendered(false);
        out.close();
        
      } 
 
      catch (Exception e)
      { 
          e.printStackTrace(); 
          pageContext.writeDiagnostics(this, "Error: " + e.getMessage(), 1);
          throw new OAException(e.getMessage(), OAException.ERROR);
      }
      
    } // End of templateDownload Action
  
    // Code for getting the Help file when clicking on the "Click Here" option in the Templates region
  if("help".equals(pageContext.getParameter(EVENT_PARAM) ))
    {      
      utl.log("Inside templateDownload");   
      String templateId = pageContext.getParameter("p_template_id"); 
      OAViewObject templateVO = (OAViewObject) am.findViewObject("ODImportToolTempVO");
      templateVO.executeQuery(); 
      OARow row = (OARow) templateVO.first();
      utl.log("Template id:" + templateId); 
      ClobDomain b = null;
      
      while(row != null)
      {
        String tempId = row.getAttribute("TemplateFileUploadId").toString() ;
        utl.log("inside while: tempId: " + tempId);  
        if(templateId.equals(tempId))
        {
          utl.log("inside if");
          b = (ClobDomain)row.getAttribute("HelpFile");
          String tempName = (String) row.getAttribute("TemplateName") + ".rtf";  // Click Here will appear for all templates for Help File
          pageContext.putSessionValue("tempNameSessVal", tempName);
          utl.log("inside while: tempName: " + tempName); 
          break;
        }    
        row = (OARow) templateVO.next();
      }
  
      DictionaryData sessionDictionary =(DictionaryData) pageContext.getNamedDataObject("_SessionParameters"); 
      try  
      {
        String templateName = (String) pageContext.getSessionValue("tempNameSessVal"); 
        RenderingContext con = (RenderingContext) pageContext.getRenderingContext(); 
        HttpServletResponse response = (HttpServletResponse)sessionDictionary.selectValue(con,"HttpServletResponse"); 
        String contentType =  "application/rtf";        
        response.setHeader("Content-disposition", "attachment; filename=\"" + templateName +"\"");
        response.setContentType(contentType);
        PrintWriter out = response.getWriter();
        out.print(b.toString()); 
        pageContext.setDocumentRendered(false);
        out.close();
      } 
 
      catch (Exception e)
      { 
        e.printStackTrace(); 
      }
      
    } // End of HelpFile Action
    
 } // End of ProcessFormRequest
 private boolean isCsvFile( OAPageContext pageContext, OAWebBean webBean,String strFileName) 
  {
    
    OAApplicationModule am =pageContext.getApplicationModule(webBean);
    ODUtil utl = new ODUtil(am);
    utl.log("--In isCsvFile--");
    boolean isCsv = false;

    String strTemp = "";
    strTemp = strFileName.substring(strFileName.lastIndexOf('.')+1, strFileName.length());
    utl.log("strTemp: " + strTemp);
    if (strTemp.trim().equalsIgnoreCase("CSV"))
      isCsv = true;
    utl.log("isCsv: " + isCsv);
    return isCsv;
  }
  public static void doUpload(OAPageContext pageContext, OAWebBean webBean)
{
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    OAViewObject VO = (OAViewObject) am.findViewObject("ODImportToolsVO");
    OADBTransaction transaction = am.getOADBTransaction();
    ODUtil utl = new ODUtil(am);
    VO.first(); // To create a new record at the first position 
    OARow row = (OARow)VO.createRow();
    DataObject fileUploadData = pageContext.getNamedDataObject("fileUpload");
    String uFileName = null;
    uFileName = (String)fileUploadData.selectValue(null, "UPLOAD_FILE_NAME");
    utl.log("uFileName: " + uFileName);
    String contentType = (String)fileUploadData.selectValue(null, "UPLOAD_FILE_MIME_TYPE");
    utl.log("contentType: " + contentType);
    Number fileId = transaction.getSequenceValue("XXTPS_FILE_UPLOAD_ID_S");
    BlobDomain uploadedByteStream = (BlobDomain)fileUploadData.selectValue(null, uFileName) ;
   // OAMessageChoiceBean clobCode = (OAMessageChoiceBean) webBean.getLabel();
    OAMessageChoiceBean clobCode = (OAMessageChoiceBean)webBean.findIndexedChildRecursive("templateType");
    String clobCodeVal = (String)clobCode.getSelectionText(pageContext); 
    Number var = new Number(0);
    utl.log("Clob Code" +clobCodeVal);
    row.setAttribute("FileUploadId", fileId);
    row.setAttribute("FileName",uFileName);
    row.setAttribute("FileData",uploadedByteStream); 
    row.setAttribute("FileStatus","P");
    row.setAttribute("ClobType","csv");
    row.setAttribute("ClobCode",clobCodeVal);//"CUSTOMER_LEADS");
    row.setAttribute("FileContentType","application/vnd.ms-excel");
    row.setAttribute("Program","XXCRM-APP");
    row.setAttribute("TotalProcessedRecords",var);
    row.setAttribute("NoOfSuccessRecords",var);
    row.setAttribute("NoOfErrorRecords",var);
    //row.setAttribute("UserName",pageContext.getUserId());
    VO.insertRow(row);
    utl.log("Before Commit");
    am.getTransaction().commit();
    utl.log("After Commit");
} // End of doUpload

}
