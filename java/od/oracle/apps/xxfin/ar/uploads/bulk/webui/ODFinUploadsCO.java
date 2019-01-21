/*===========================================================================+
 |   Copyright (c) 2001, 2003 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxfin.ar.uploads.bulk.webui;
/* Subversion Info:
 * $HeadURL:$
 * $Rev:$
 * $Date:$
*/
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
//import od.oracle.apps.xxcrm.cdh.ebl.server.ODUtil;
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
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageFileUploadBean;
import java.util.StringTokenizer;
import oracle.apps.fnd.common.MessageToken;


/**
 * Controller for ...
 */
public class ODFinUploadsCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion(RCS_ID, "%packagename%");
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
    //Fetching header details
    OAViewObject templVO = (OAViewObject) am.findViewObject("ODFinUploadsTempVO");
    templVO.executeQuery();
    OAViewObject mainVO = (OAViewObject) am.findViewObject("ODFinUploadsVO"); 
    mainVO.executeQuery();
    OAViewObject poplistVO = (OAViewObject) am.findViewObject("ODFinTemplatePVO");
    //Below is the code to implement the security feature in the PVO values listed.
    poplistVO.setWhereClause("responsibility_id = " +  pageContext.getResponsibilityId() );
    poplistVO.executeQuery();
    if(pageContext.isLoggingEnabled(3))
                    pageContext.writeDiagnostics(this, "poplistVO count:" + poplistVO.getRowCount(), 3);
    
    // Code to fetch the Upload Type from xxcrm_template_file_uploads region to be diaplayed in the Files Uploaded region
    OAViewObject clobCodePVO = (OAViewObject) am.findViewObject("ODFinTemplateNameFilesPVO");
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
    super.processFormRequest(pageContext, webBean);
    String strFileName = null;
    String strLocalFileName = null;
     if(pageContext.isLoggingEnabled(3))
                    pageContext.writeDiagnostics(this, "EVENT_PARAM:"+pageContext.getParameter(EVENT_PARAM), 3);
    
    Serializable[] param = null;
    String fileName= null;
       
    DataObject fileUploadData = pageContext.getNamedDataObject("fileUpload");
    OAMessageFileUploadBean fileUploadBean = (OAMessageFileUploadBean)webBean.findIndexedChildRecursive("fileUpload");
    fileUploadBean.getValue(pageContext);
    String str = (String)  fileUploadBean.getValue(pageContext);
    if(pageContext.isLoggingEnabled(3))
    {
      pageContext.writeDiagnostics(this, "File Upload Data value" + fileUploadData, 3);
      pageContext.writeDiagnostics(this, "File Upload Bean value" + str, 3);
    }
    if (pageContext.getParameter("upload") != null && fileUploadData == null)
    {
      throw new OAException("Please select a file to upload", OAException.ERROR);
            
    }
    
  if (fileUploadData != null)
    {
      strLocalFileName = (String)fileUploadData.selectValue(null, "UPLOAD_FILE_NAME");
      strFileName = strLocalFileName;
      if(pageContext.isLoggingEnabled(3))
      pageContext.writeDiagnostics(this, "strFileName: " + strFileName, 3);      
    } 

    // Code for Upload Button click in the File Upload region
    if (pageContext.getParameter("upload") != null)
    {
      if(pageContext.isLoggingEnabled(3))
      pageContext.writeDiagnostics(this, "Inside Upload click", 3);
      if (str==null)
      {
        throw new OAException("Please select a file to upload", OAException.ERROR);
      }
      if (str !=null)
      {
      if(pageContext.isLoggingEnabled(3))
      pageContext.writeDiagnostics(this, "Inside s not null", 3);
      if (isCsvFile(pageContext,webBean,strFileName))
      {
        doUpload( pageContext, webBean);
        OAViewObject mainVO = (OAViewObject) am.findViewObject("ODFinUploadsVO"); 
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
      if(pageContext.isLoggingEnabled(3))
      pageContext.writeDiagnostics(this, "Inside Download", 3);
      String fileId = pageContext.getParameter("p_file_id"); 
      OAViewObject clobVO = (OAViewObject) am.findViewObject("ODFinUploadsVO");
      clobVO.executeQuery(); 
      OARow row = (OARow) clobVO.first();
      if(pageContext.isLoggingEnabled(3))
      pageContext.writeDiagnostics(this, "After First Row: File id:" + fileId, 3);
      ClobDomain b = null;
      
      while(row != null)
      {
        String fId = row.getAttribute("FileUploadId").toString() ;
        if(pageContext.isLoggingEnabled(3))
          pageContext.writeDiagnostics(this, "inside while: fId: " + fId, 3);
        if(fileId.equals(fId))
        {
          if(pageContext.isLoggingEnabled(3))
          pageContext.writeDiagnostics(this, "inside if" + fId, 3);
          b = (ClobDomain)row.getAttribute("FileData");
          String fName =(String) row.getAttribute("FileName");
          pageContext.putSessionValue("fNameSessVal", fName);
          if(pageContext.isLoggingEnabled(3))
          pageContext.writeDiagnostics(this, "inside while: fName: " + fName, 3);
          
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
      if(pageContext.isLoggingEnabled(3))
          pageContext.writeDiagnostics(this, "Inside Error File Data", 3);
      String fileId1 = pageContext.getParameter("p_file"); 
      if(pageContext.isLoggingEnabled(3))
          pageContext.writeDiagnostics(this, "Fild Id is :" + fileId1, 3);
      OAViewObject clobVO = (OAViewObject) am.findViewObject("ODFinUploadsVO");
      clobVO.executeQuery(); 
      OARow row = (OARow) clobVO.first();
      ClobDomain b = null;
      
      while(row != null)
      {
         String fileId2 = row.getAttribute("FileUploadId").toString() ;
         if(pageContext.isLoggingEnabled(3))
          pageContext.writeDiagnostics(this, "inside while: fId: " + fileId2, 3);
        if(fileId1.equals(fileId2))
        {
          if(pageContext.isLoggingEnabled(3))
          pageContext.writeDiagnostics(this, "inside if", 3);
          b = (ClobDomain)row.getAttribute("ErrorFileData");
          String fName =(String) row.getAttribute("FileName");
          pageContext.putSessionValue("fNameSessVal", fName);
          if(pageContext.isLoggingEnabled(3))
          pageContext.writeDiagnostics(this,"inside while: fName: " + fName, 3);
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
      String fileId1 = pageContext.getParameter("p_file"); 
      if(pageContext.isLoggingEnabled(3))
      {
        pageContext.writeDiagnostics(this,"Inside Output File Data", 3);
        pageContext.writeDiagnostics(this,"Fild Id is :" + fileId1, 3);
      }
      OAViewObject clobVO = (OAViewObject) am.findViewObject("ODFinUploadsVO");
      clobVO.executeQuery(); 
      OARow row = (OARow) clobVO.first();
      ClobDomain b = null;
      
      while(row != null)
      {
         String fileId2 = row.getAttribute("FileUploadId").toString() ;
         if(pageContext.isLoggingEnabled(3))
          pageContext.writeDiagnostics(this,"inside while: fId: " + fileId2, 3);
        if(fileId1.equals(fileId2))
        {
          b = (ClobDomain)row.getAttribute("OutputFileData");
          String fName =(String) row.getAttribute("FileName");
          pageContext.putSessionValue("fNameSessVal", fName);
          if(pageContext.isLoggingEnabled(3))
          pageContext.writeDiagnostics(this,"inside if - while: fName: " + fName, 3);
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
     String fileUploadId = pageContext.getParameter("p_fileupload_id");
    if(pageContext.isLoggingEnabled(3))
    {
      pageContext.writeDiagnostics(this,"Inside Upload Action Button click", 3);
      pageContext.writeDiagnostics(this,"Fild Upload Id is :" + fileUploadId, 3);
    }
     OAViewObject mainVO = (OAViewObject) am.findViewObject("ODFinUploadsVO");
     mainVO.executeQuery(); 
     OARow row = (OARow) mainVO.first();
     String rowLimitProfile = pageContext.getProfile("XX_FIN_BULK_UPLOAD_LIMIT");
     if(pageContext.isLoggingEnabled(3))
    {
      pageContext.writeDiagnostics(this,"Inside Upload Action Button click: profile 'OD : Fin Hier and Credit Bulk Upload Limit' value:"+rowLimitProfile, 3);      
    }
    if(rowLimitProfile != null && rowLimitProfile.trim().length() >0)
    {
      
    }else
    {
      rowLimitProfile = "0";
    }
    Number rowLimit = new Number();
    try
    {
      rowLimit = new Number(rowLimitProfile);
    }catch(Exception e)
    {
      rowLimit = new Number();
    }
    Boolean flag = false;
    int count =0;
      while(row != null)
      {
        String fileIdVal = row.getAttribute("FileUploadId").toString() ;
        if(pageContext.isLoggingEnabled(3))
          pageContext.writeDiagnostics(this,"inside while: file Upload Id - Upload Action: " + fileIdVal, 3);
        if(fileUploadId.equals(fileIdVal))
       {
          count = clobRowCount((ClobDomain)row.getAttribute("FileData"))-1;
          flag = count <= rowLimit.intValue();
          if(pageContext.isLoggingEnabled(3))
          pageContext.writeDiagnostics(this,"inside while: file Upload Id - Upload Action: file rows : " + count+" validation:"+flag, 3);
          if(flag)
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
              if(pageContext.isLoggingEnabled(3))
                pageContext.writeDiagnostics(this,"Before invoking Upload Action", 3);
              reqId= am.invokeMethod ("uploadAction", param);
              if(pageContext.isLoggingEnabled(3))
                pageContext.writeDiagnostics(this,"After Upload Action method execution "+"Request Id: " + reqId, 3);
               //Added to disable the Process Button and Cancel after clicking it for processing
               row.setAttribute("UploadAction",Boolean.TRUE);
              OAException msg2 = new OAException ("A Concurrent Request  " + reqId + " is submitted.",OAException.INFORMATION);                                               
              pageContext.putDialogMessage(msg2);
              break;
          }else
          {
            MessageToken [] tokens =  {new MessageToken("LIMIT_VALUE",rowLimitProfile)};
            throw new OAException("XXFIN", "XXFIN_UPLOAD_LIMIT_ERROR", tokens,OAException.ERROR, null );
            //throw new OAException ("File has more than the maximum rows allowed!. Please uplad the file again with the maximum rows allowed:"+rowLimitProfile);
          }
        }
        row = (OARow) mainVO.next();
       }
   } // End of UploadAction

   // Clcik of Refresh button
  if (pageContext.getParameter("Refresh") != null) 
  {
     OAViewObject mainVO = (OAViewObject) am.findViewObject("ODFinUploadsVO");
     mainVO.executeQuery(); 
  } // End of Refresh


//Click of Cancel Button
  if ("cancel".equals(pageContext.getParameter(EVENT_PARAM)))
  {
     String fileUpdId = pageContext.getParameter("p_file_idval");
     if(pageContext.isLoggingEnabled(3))
          pageContext.writeDiagnostics(this,"Inside Cancel Action: File Upload Id :" + fileUpdId, 3);
  
     OAViewObject mainVO = (OAViewObject) am.findViewObject("ODFinUploadsVO");
     mainVO.executeQuery(); 
     OARow row = (OARow) mainVO.first();
      while(row != null)
      {
        String fileId = row.getAttribute("FileUploadId").toString() ;
        if(pageContext.isLoggingEnabled(3))
          pageContext.writeDiagnostics(this,"inside while: file Upload Id - Cancel: " + fileId, 3);
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
      String templateId = pageContext.getParameter("p_template_id"); 
      OAViewObject templateVO = (OAViewObject) am.findViewObject("ODFinUploadsTempVO");
      templateVO.executeQuery(); 
      OARow row = (OARow) templateVO.first();
      if(pageContext.isLoggingEnabled(3))
          pageContext.writeDiagnostics(this,"Inside templateDownload Template id:" + templateId, 3);
      ClobDomain b = null;
      
      while(row != null)
      {
        String tempId = row.getAttribute("TemplateFileUploadId").toString() ;
        if(pageContext.isLoggingEnabled(3))
          pageContext.writeDiagnostics(this,"inside while: tempId: " + tempId, 3);
        if(templateId.equals(tempId))
        {
          b = (ClobDomain)row.getAttribute("TemplateCsv");
          String tempName =(String) row.getAttribute("TemplateName") + ".csv"; // Appending this .csv with the filename so that the file will be opened in csv format.Else it will not be in csv format
          pageContext.putSessionValue("tempNameSessVal", tempName);
          if(pageContext.isLoggingEnabled(3))
          pageContext.writeDiagnostics(this,"inside while if: tempName: " + tempName, 3);
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
        String contentType =  "application/csv";        
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
      
    } // End of templateDownload Action
  
    // Code for getting the Help file when clicking on the "Click Here" option in the Templates region
  if("help".equals(pageContext.getParameter(EVENT_PARAM) ))
    { 
      String templateId = pageContext.getParameter("p_template_id"); 
      if(pageContext.isLoggingEnabled(3))
          pageContext.writeDiagnostics(this,"Inside templateDownload Template id:" + templateId, 3);
      OAViewObject templateVO = (OAViewObject) am.findViewObject("ODFinUploadsTempVO");
      templateVO.executeQuery(); 
      OARow row = (OARow) templateVO.first();
      ClobDomain b = null;
      
      while(row != null)
      {
        String tempId = row.getAttribute("TemplateFileUploadId").toString() ;
        if(pageContext.isLoggingEnabled(3))
          pageContext.writeDiagnostics(this,"inside while: tempId: " + tempId, 3);
        if(templateId.equals(tempId))
        {
          b = (ClobDomain)row.getAttribute("HelpFile");
          String tempName = (String) row.getAttribute("TemplateName") + ".rtf";  // Click Here will appear for all templates for Help File
          pageContext.putSessionValue("tempNameSessVal", tempName);
          if(pageContext.isLoggingEnabled(3))
          pageContext.writeDiagnostics(this,"inside while if: tempName: " + tempName, 3);
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
    if(pageContext.isLoggingEnabled(3))
          pageContext.writeDiagnostics(this,"--In isCsvFile--", 3);
    boolean isCsv = false;

    String strTemp = "";
    strTemp = strFileName.substring(strFileName.lastIndexOf('.')+1, strFileName.length());
    if (strTemp.trim().equalsIgnoreCase("CSV"))
      isCsv = true;
    if(pageContext.isLoggingEnabled(3))
          pageContext.writeDiagnostics(this,"strTemp: " + strTemp+ " :: "+"isCsv: " + isCsv, 3);
    return isCsv;
  }
  public void doUpload(OAPageContext pageContext, OAWebBean webBean)
{
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    OAViewObject VO = (OAViewObject) am.findViewObject("ODFinUploadsVO");
    OADBTransaction transaction = am.getOADBTransaction();
    VO.first(); // To create a new record at the first position 
    OARow row = (OARow)VO.createRow();
    DataObject fileUploadData = pageContext.getNamedDataObject("fileUpload");
    String uFileName = null;
    uFileName = (String)fileUploadData.selectValue(null, "UPLOAD_FILE_NAME");
    String contentType = (String)fileUploadData.selectValue(null, "UPLOAD_FILE_MIME_TYPE");
    if(pageContext.isLoggingEnabled(3))
          pageContext.writeDiagnostics(this,"uFileName: " + uFileName+" :: "+"contentType: " + contentType, 3);
    Number fileId = transaction.getSequenceValue("XXCRM_FILE_UPLOAD_ID_S");
    BlobDomain uploadedByteStream = (BlobDomain)fileUploadData.selectValue(null, uFileName) ;
   // OAMessageChoiceBean clobCode = (OAMessageChoiceBean) webBean.getLabel();
    OAMessageChoiceBean clobCode = (OAMessageChoiceBean)webBean.findIndexedChildRecursive("templateType");
    String clobCodeVal = (String)clobCode.getSelectionText(pageContext); 
    Number var = new Number(0);
    if(pageContext.isLoggingEnabled(3))
          pageContext.writeDiagnostics(this,"Clob Code" +clobCodeVal, 3);
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
    if(pageContext.isLoggingEnabled(3))
          pageContext.writeDiagnostics(this,"Before Commit", 3);
    am.getTransaction().commit();
    if(pageContext.isLoggingEnabled(3))
          pageContext.writeDiagnostics(this,"After Commit", 3);
} // End of doUpload

public int clobRowCount(ClobDomain clobdm)
{
  StringTokenizer st = new StringTokenizer(clobdm.toString(),"\n"); 
  return st.countTokens();
  
}

}
