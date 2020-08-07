/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                            
 |   01-Jun-2013  Rma Goyal    V1.0   Defect 21945 RICE ID=  E3058             |
 |   17-Feb-2017  Madhu Bolli  V1.1   Thread Leak 12.2.5 Upgrade - close all statements, resultsets|
 +===========================================================================*/
package od.oracle.apps.xxcomn.common.fileUpload.webui;

import java.io.Serializable;
import oracle.apps.fnd.common.MessageToken;
import java.lang.Integer;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import java.sql.Connection;
import java.sql.PreparedStatement; 
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import java.util.ArrayList;
import java.util.Vector;
import oracle.apps.fnd.framework.OAException;
import jxl.read.biff.BiffException;

import od.oracle.apps.xxcomn.common.fileUpload.webui.ExcelParser;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.cp.request.ConcurrentRequest;
import oracle.apps.fnd.cp.request.RequestSubmissionException;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageFileUploadBean;

import oracle.jbo.domain.BlobDomain;
import oracle.jbo.domain.Number;

/**
 * Controller for ...
 */
public class FileUploadCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");
  boolean UploadClicked =false;
  boolean submitProgClicked =false;
  boolean  fileBrowsed = false;
  
  static class ExcelDef
  {
    private String strColumnName;
    private String strExcelColumnName;
    private String strDataType;
    private int nSheetNum;
    private String strUseInImgTag;
    private String strValidationSQL;
    private String strColumnHeading;
    
    ExcelDef(String strColumnName, String strExcelColumnName, 
      String strDataType, int nSheetNum, String strUseInImgTag,
      String strValidationSQL, String strColumnHeading )  {      
      this.strColumnName = strColumnName;
      this.strExcelColumnName = strExcelColumnName;
      this.strDataType = strDataType;
      this.nSheetNum = nSheetNum;
      this.strUseInImgTag = strUseInImgTag;
      this.strValidationSQL = strValidationSQL;
      this.strColumnHeading = strColumnHeading;
    }
    public void setStrColumnName(String strColumnName) {
        this.strColumnName = strColumnName;
    }

    public String getStrColumnName() {
        return strColumnName;
    }

    public void setStrExcelColumnName(String strExcelColumnName) {
        this.strExcelColumnName = strExcelColumnName;
    }

    public String getStrExcelColumnName() {
        return strExcelColumnName;
    }

    public void setStrDataType(String strDataType) {
        this.strDataType = strDataType;
    }

    public String getStrDataType() {
        return strDataType;
    }

    public void setNSheetNum(int nSheetNum) {
        this.nSheetNum = nSheetNum;
    }

    public int getNSheetNum() {
        return nSheetNum;
    }
    
    public void setstrUseInImgTag(String strUseInImgTag) {
        this.strUseInImgTag = strUseInImgTag;
    }

    public String getstrUseInImgTag() {
        return strUseInImgTag;
    }

    public void setstrValidationSQL(String strValidationSQL) {
        this.strValidationSQL = strValidationSQL;
    }

    public String getstrValidationSQL() {
        return strValidationSQL;
    }

    public void setstrColumnHeading(String strColumnHeading) {
        this.strColumnHeading = strColumnHeading;
    }

    public String getstrColumnHeading() {
        return strColumnHeading;
    }
  }
  
  public FileUploadCO()
  {
  }

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
OAApplicationModule am = pageContext.getApplicationModule(webBean);
    OADBTransaction oadbtransaction = am.getOADBTransaction();
  ResultSet rsProg = null;
    Statement stmt = null;
    String progShortName="";
    String programName ="";
    String applName="";
    String strTableName="";
    Connection conn = oadbtransaction.getJdbcConnection();

    if (pageContext.isBackNavigationFired(true))
    {
      System.out.println("Back button fired");
      pageContext.redirectToDialogPage(new OADialogPage(NAVIGATION_ERROR));
    }
    else
    {
      System.out.println("Back button Not fired");
    }

    super.processRequest(pageContext, webBean);
    OAPageLayoutBean pageLayoutBean = (OAPageLayoutBean)webBean;
    OAMessageFileUploadBean fileUploadBean = 
      (OAMessageFileUploadBean) pageLayoutBean.findChildRecursive("FileUpload");
    fileUploadBean.setFileContentType("application/vnd.ms-excel");
    System.out.println("application="+pageContext.getApplicationShortName());
    String appShortName="";
    OAViewObject voAppsName = (OAViewObject)am.findViewObject("xxGetAppsNameVO1");
    voAppsName.executeQuery();
    voAppsName.first(); 
    if(voAppsName.getCurrentRow()!=null) {
    appShortName = voAppsName.getCurrentRow().getAttribute("Appsshortname").toString();
    }
    // code starts for choose Template
   OAViewObject vo = (OAViewObject)am.findViewObject("FndFlexValuesVO");
    try{
      if (!vo.isPreparedForExecution())
      {
      vo.setWhereClauseParams(null);
      vo.setWhereClauseParam(0,appShortName);
    //  System.out.println("vo query="+vo.getQuery());
      if(pageContext.isLoggingEnabled(3)){
        pageContext.writeDiagnostics("VO Query",vo.getQuery(),3);
      }
      
      vo.executeQuery();
    }
  }
    catch(Exception e) {    
          throw new OAException(e.getMessage());
          }
    vo.first(); 
    // code ends for choose Template
 /*   String strTemplateID = pageContext.getParameter("ExcelTemplateChoice");
    System.out.println("Template Id in Process Request="+strTemplateID);

     try{      
      
      String sqlGetProg =" select distinct staging_table_name strTableName, appl_short_name appl_name, prog_short_name short_name,  program_name prog_name from  xx_od_upload_excel_config where template_id = " + strTemplateID;
      stmt = conn.createStatement();
      rsProg = stmt.executeQuery(sqlGetProg);
      while(rsProg.next()){
      
	    progShortName =(String) rsProg.getObject("short_name");
      programName = rsProg.getString("prog_name");
      applName= rsProg.getString("appl_name");
      strTableName = rsProg.getString("strTableName");
      
      System.out.println("progShortName="+progShortName);
      System.out.println("programName="+programName);
      if(pageContext.isLoggingEnabled(3)){
      pageContext.writeDiagnostics("progShortName",progShortName,3);
      pageContext.writeDiagnostics("programName",programName,3);
      pageContext.writeDiagnostics("strTableName",strTableName,3);
      }
      }
        }catch (Exception e) { //e.printStackTrace();
        if(pageContext.isLoggingEnabled(3)){
        
        pageContext.writeDiagnostics("Error in loading Program=","In Catch block",3);
        }
      }
    OAMessageTextInputBean textBean = (OAMessageTextInputBean)webBean.findChildRecursive("item1");

 textBean.setValue(pageContext, programName);  */
  }

  public String loadExcelDatatoDB(OAPageContext pageContext, OAWebBean webBean)
  { 
    Connection conn = null;
    Statement stmt = null;
		ResultSet rs = null;
    Statement stmt1 = null;
		ResultSet rs1 = null;
    String strImgPath;
    int nFirstRow = -1;       

    String strTemplateID = pageContext.getParameter("ExcelTemplateChoice");
    System.out.println("Template Id ="+strTemplateID);
    try {

      String strExcelUploadFileName = pageContext.getParameter("FileUpload");
      if(strExcelUploadFileName == null)
        throw new OAException("XXFIN","XXOD_EXCEL_UPLD_FILE_MISSING");
      System.out.println("strExcelUploadFileName ="+strExcelUploadFileName);

      if(pageContext.isLoggingEnabled(3)){

      pageContext.writeDiagnostics("strExcelUploadFileName=",strExcelUploadFileName,3);
      }
      
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      OADBTransaction oadbtransaction = am.getOADBTransaction();
      conn = oadbtransaction.getJdbcConnection();

      String sqlGet1 = 
        " select ffvv.attribute1 first_row, ffvv.attribute2 image_path "
        + " from  FND_FLEX_VALUES_VL ffvv, FND_FLEX_VALUE_SETS ffvs "
        + " where ffvv.flex_value_set_id = ffvs.flex_value_set_id"
        + " and ffvs.flex_value_set_name = 'XX_OD_UPLOAD_TEMPLATE_CONFIG' "
        + " and ffvv.flex_value = '" + strTemplateID+"'";
//      System.out.println("SQL to get Qualifier ="+sqlGet1);
      if(pageContext.isLoggingEnabled(3)){
      
      pageContext.writeDiagnostics("SQL to get Qualifier =",sqlGet1,3);
      }
      stmt1 = conn.createStatement();
			rs1 = stmt1.executeQuery(sqlGet1);
      if (rs1.next())
      {
        nFirstRow = rs1.getInt("first_row");
        strImgPath = rs1.getString("image_path");
      }
      else
        return "Could not get configuration values from the database!";

      String sqlGet = "select staging_table_name, staging_column_name, data_type, "
      + " sheet_no, excel_column, use_in_img_tag, validation_sql, stg_column_heading"
      + " from  xx_od_upload_excel_config where template_id = " + strTemplateID;
      
      System.out.println("SQL to get staging table details ="+sqlGet);
      if(pageContext.isLoggingEnabled(3)){
      
      pageContext.writeDiagnostics("SQL to get staging table details =",sqlGet,3);
      }
      ArrayList list = new ArrayList();
      
      stmt = conn.createStatement();
			rs = stmt.executeQuery(sqlGet);
      // Right now we support only on table name and one sheet per upload
      String strTableName ="";
      int nSheetNum = -1;
			while (rs.next()) 
			{				System.out.println("Inside result set");
        strTableName = rs.getString("staging_table_name");
        String strColumn = rs.getString("staging_column_name");
        String strDataType = rs.getString("data_type");
        nSheetNum = rs.getInt("sheet_no");
        String strExcelCol = rs.getString("excel_column");
        String strUseInImgTag = rs.getString("use_in_img_tag");
        String strValidationSQL = rs.getString("validation_sql");
        String strColumnHeading = rs.getString("stg_column_heading");
        ExcelDef exceldef = new ExcelDef(strColumn, strExcelCol, 
            strDataType, nSheetNum, strUseInImgTag, strValidationSQL, strColumnHeading);
            
        list.add(exceldef);
			}
      ExcelParser excelParser = null;
      try
      {
        BlobDomain blobdomain = (BlobDomain)pageContext.getParameterObject(strExcelUploadFileName);
        excelParser = new ExcelParser
              (blobdomain.getBinaryStream());
        excelParser.setCurrentSheet(nSheetNum);        
      }
      catch(BiffException e)
      {
        OAException successMessage = new OAException(e.getMessage(),OAException.ERROR);
        pageContext.putDialogMessage(successMessage);
        return e.getMessage();
      }

     int nMaxRows = excelParser.getNumRowsInCurrentSheet();
     System.out.println("nMaxRows="+nMaxRows);
      if(pageContext.isLoggingEnabled(3)){
     pageContext.writeDiagnostics("Rows in excel File=",nMaxRows+"",3);   
      }
     boolean bNullDataRowFound = false;
      for (int i = nFirstRow; i <= nMaxRows; i++)
      {
        if (bNullDataRowFound)
          break;

        String strInsertSql = "insert into " + strTableName + " (creation_date,last_update_date, created_by ,last_updated_by,status";
        String strInsertSqlValues = " values(sysdate, sysdate, " + pageContext.getUserId()+","+pageContext.getUserId()+",'I'"; 
        String strImageTag = strImgPath+"img_";

        for (int j=0; j < list.size(); j++)
        {
          ExcelDef exceldef = (ExcelDef) list.get(j);
          String strCellNum = exceldef.getStrExcelColumnName()+ Integer.toString(i);
          String strValue;
          if(exceldef.getStrDataType().equalsIgnoreCase("I")) //image
          {
            int nIndex = i - nFirstRow;
            strValue = strImageTag + ".jpg";
            if(!excelParser.retrieveAndSaveImage(strValue, nIndex))
              return "Could not retrieve and save image " + strValue;
          }
          else
            strValue = excelParser.getCellValue(strCellNum, exceldef.getStrDataType().charAt(0));
          
          if ( (strValue != null) && !strValue.equalsIgnoreCase("") ) 
          {
            if ( (exceldef.getstrUseInImgTag() != null) &&
              exceldef.getstrUseInImgTag().equalsIgnoreCase("Y") )
                strImageTag = strImageTag + strValue + "_";            
              
            strValue = strValue.replaceAll("'","''");
            switch (exceldef.getStrDataType().charAt(0))
            {
              case 'C': //currency
                if (strValue.length() >  3)
                  strValue = strValue.substring(3); // omit "$"
                break;
              case 'D':
                strValue = "to_date('"+strValue+"', 'mm/dd/yyyy')"; //TO DO date is expected in mm/dd/yyyy format
                break;
              case 'I':
                strValue = "'"+strValue+"'";
                break;
              case 'V':
                strValue = "'"+strValue+"'";
                break;
              default:
                break;
            }

            // Now do the field level validation
            if(exceldef.getStrDataType().charAt(0) == 'N' ) //Numeric
            {
              try
              {
                double dtmp = Double.parseDouble(strValue);
              }
              catch(Exception e)
              {
                return "Numerical value expected for " + exceldef.getstrColumnHeading()
                  + ". Found " + strValue + " at Excel row " + Integer.toString(i);
              }
            }
            if (exceldef.getstrValidationSQL() != null)
            {
              String sqlValidation = exceldef.getstrValidationSQL();
              String strParam = ":" + exceldef.getStrColumnName();
              sqlValidation = sqlValidation.replaceAll(strParam, strValue);
              Statement stmtValidation = conn.createStatement();
              ResultSet rsValidation = stmtValidation.executeQuery(sqlValidation);
              if (!rsValidation.next())
              {
                rsValidation.close();
                stmtValidation.close();
                return "validation failed for " + exceldef.getstrColumnHeading()
                  + " " + strValue + " at Excel row " + Integer.toString(i);
              }
              else
              {
                rsValidation.close();
                stmtValidation.close();
              }
            }

            strInsertSql += ", ";
            strInsertSql += exceldef.getStrColumnName();
            
            strInsertSqlValues += ", ";
            strInsertSqlValues += strValue;
          }
          else if ( (exceldef.getstrUseInImgTag() != null) &&
              exceldef.getstrUseInImgTag().equalsIgnoreCase("Y") )
          {
            bNullDataRowFound = true;
            break;
          }
        }
        if (!bNullDataRowFound)
        {
          strInsertSql += ") ";
          strInsertSqlValues += ")";
       
          String strInsert = strInsertSql + strInsertSqlValues;
      //    pageContext.writeDiagnostics("strInsertSql=",strInsertSql,3);   
      //    pageContext.writeDiagnostics("strInsertSqlValues=",strInsertSqlValues,3);   
          Statement stmtInsert = conn.createStatement();
          stmtInsert.executeUpdate(strInsert);
          if (stmtInsert != null)
            stmtInsert.close();
        }
      }
      conn.commit();

      //Now call the concurrent program in next release of the program
          

      return null;
    } catch (SQLException e) {
      e.printStackTrace();
      return e.getMessage();
    } catch (Exception ee) {	
      ee.printStackTrace();
      if (ee.getMessage() != null)
        return ee.getMessage();
      else
        return ee.getClass().getName();
    } finally{
      try {
        if (rs != null)
          rs.close();
        if (rs1 != null)
          rs1.close();	  
        if (stmt != null)
          stmt.close();        
        if (stmt1 != null)
          stmt1.close();        
        //if (conn != null)
          //conn.close();					
      } catch (Exception e){
        e.printStackTrace();
        return e.getMessage();
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
    OADBTransaction oadbtransaction = am.getOADBTransaction();
    Connection conn = oadbtransaction.getJdbcConnection();
    ResultSet rsProg = null;
    Statement stmt = null;
    String progShortName="";
    String programName ="";
    String applName="";
    String strTableName="";
    
		String strTemplateID = pageContext.getParameter("ExcelTemplateChoice");
    String strExcelUploadFileName = pageContext.getParameter("FileUpload");
    System.out.println("strExcelUploadFileName="+strExcelUploadFileName);
    pageContext.putTransactionValue("strExcelUploadFileName",strExcelUploadFileName);
         
   try{      
      
      String sqlGetProg =" select distinct staging_table_name strTableName, appl_short_name appl_name, prog_short_name short_name,  program_name prog_name from  xx_od_upload_excel_config where template_id = " + strTemplateID;
      stmt = conn.createStatement();
      rsProg = stmt.executeQuery(sqlGetProg);
      while(rsProg.next()){
      
	    progShortName =(String) rsProg.getObject("short_name");
      programName = rsProg.getString("prog_name");
      applName= rsProg.getString("appl_name");
      strTableName = rsProg.getString("strTableName");
      
      System.out.println("progShortName="+progShortName);
      System.out.println("programName="+programName);
      if(pageContext.isLoggingEnabled(3)){
      pageContext.writeDiagnostics("progShortName",progShortName,3);
      pageContext.writeDiagnostics("programName",programName,3);
      pageContext.writeDiagnostics("strTableName",strTableName,3);
      }
      }
        }catch (Exception e) { //e.printStackTrace();
        if(pageContext.isLoggingEnabled(3)){
        
        pageContext.writeDiagnostics("Error in loading Program=","In Catch block",3);
        }
      }
	  finally {
		try {
		 if (rsProg != null)
			rsProg.close();
		} catch(Exception exc) {  }
      }	  
          
    if (pageContext.getParameter("Apply") != null)
    {
      UploadClicked = true; //to capture the event of file upload
      
      String strError = loadExcelDatatoDB (pageContext, webBean);
      System.out.println("strError="+strError);
       if(strExcelUploadFileName == null) {
        throw new OAException("XXFIN","XXOD_EXCEL_UPLD_FILE_MISSING");
        }
        else { // only if file is selected, any upload can happen
          fileBrowsed = true;
          if (strError == null)
          {
            String successMsg="Excel File Uploaded Successfully. Please submit the program:"+programName;
            OAException successMessage = new OAException(successMsg,OAException.INFORMATION);
            pageContext.putDialogMessage(successMessage);
          }
          else
          {
            String errorMesg="Error Uploading the excel file.Please try again!";
            OAException errMessage = new OAException(errorMesg, OAException.ERROR);
            pageContext.putDialogMessage(errMessage);
          }
        }
    }
    else if((pageContext.getParameter("ViewOutputButton")!=null)) 
    {
    // If view output is clicked without uploading the file
      if(!UploadClicked || !fileBrowsed) {

      MessageToken[] tokens = { };
      throw new OAException("XXFIN", "XXOD_EXCEL_UPLD_FILE_MISSING", tokens);
      } 
      // If view output is clicked without submitting the program
      if(!submitProgClicked || !fileBrowsed) { 

      MessageToken[] tokens = { };
      throw new OAException("XXFIN", "XXOD_EXCEL_UPLD_PRG_SUBMIT", tokens);
      } 
    
    System.out.println("Output link clicked");
    String requestId = "";
    String parentRequestId = "";
    String requestName="";
    if(pageContext.getTransactionValue("parentRequestId")!=null) 
    {
       parentRequestId =(String) pageContext.getTransactionValue("parentRequestId");
    }
  //  System.out.println("requestId in CO="+parentRequestId);    
    OAViewObject vo = (OAViewObject)am.findViewObject("xxConcProgDetailVO");
    try{
      if (!vo.isPreparedForExecution())
      {
      vo.setWhereClauseParams(null);
      vo.setWhereClauseParam(0, new Number(parentRequestId));
     // System.out.println("vo query="+vo.getQuery());
      vo.executeQuery();
    }
  }
    catch(Exception e) {    
          throw new OAException(e.getMessage());
          }

      vo.first(); // Pointing to the first row of the VO to fetch the request details
      if(vo.getCurrentRow()!=null) {
        requestId = vo.getCurrentRow().getAttribute("Reqid").toString();
        requestName = vo.getCurrentRow().getAttribute("ProgramName").toString();
      }
      else requestId=parentRequestId;
   //  System.out.println("requestId="+requestId+"requestName="+requestName);
    if(pageContext.isLoggingEnabled(3)){
    
     pageContext.writeDiagnostics("Request Id Submitted",requestId,3);
    }
    
      Serializable[] reqParam =  { requestId };
      am.invokeMethod("getOutputURL", reqParam);
      String outputURL = (String)pageContext.getTransactionValue("OutputURL");
      try
      {
          pageContext.sendRedirect(outputURL);
          return;
      }
      catch(Exception exception)
      {
      String errMsg="The program has not generated output yet. Please wait and re-click the button!";
      OAException errorMsg = new OAException(errMsg,OAException.ERROR);
      pageContext.putDialogMessage(errorMsg);
      return;
      }
    }
    else if(pageContext.getParameter("ProgramSubmitButton")!=null && UploadClicked && fileBrowsed)
    {  
      System.out.println("Program automatic submission");
      submitProgClicked = true;
      //Now call the concurrent program
   try
      {
      // get the JDBC connection      
      ConcurrentRequest cr = new ConcurrentRequest(conn);
      // call submit request

      Vector param = new Vector();
      pageContext.putTransactionValue("parentRequestId",""); // clear the transaction value buffer
      int reqId = cr.submitRequest(applName, progShortName, null,null, false, param);
//    int reqId=24361517;
      conn.commit();
//      System.out.println("reqId="+reqId);
      pageContext.putTransactionValue("parentRequestId",reqId+"");
      MessageToken[] tokens={new MessageToken("PROGRAMNAME",programName),new MessageToken("REQID",reqId+"")};//, new MessageToken("FILENAME",(String)pageContext.getTransactionValue("strExcelUploadFileName"))};
      throw new OAException("XXFIN", "XXOD_EXCEL_UPLD_PRG_DET", tokens,OAException.INFORMATION,null);
      }
      catch(RequestSubmissionException  exp)
      {
      System.out.println("Request Submission Exception:"+exp);
      }
      catch(SQLException  sexp)
      {
      System.out.println("SQL Exception:"+sexp);
      }           
    } 
     else if(pageContext.getParameter("Cancel") != null && UploadClicked && fileBrowsed)
    {
      System.out.println("In Cancel");
	 PreparedStatement stmtUpdate=null;
     try{
      String sqlCancel =" update "+ strTableName+" set status = 'E'";
      System.out.println("sql for cancel =" + sqlCancel);
      stmtUpdate = conn.prepareStatement(sqlCancel); 
      stmtUpdate.executeUpdate();
      conn.commit();
      String errMsg="The file was successfully cancelled.";
      OAException errorMsg = new OAException(errMsg,OAException.CONFIRMATION);
      pageContext.putDialogMessage(errorMsg);
      return;
      
     }
     catch (Exception e) { 
     throw new OAException("Could not successfully cancel all the records.Please contact the administrator.");

     //e.printStackTrace(); 
     } 
	 finally {
		try {
		 if (stmtUpdate != null)
			stmtUpdate.close();
	 }
	 catch(Exception exc) {  }
    }
	}
     else if(("download").equals(pageContext.getParameter(EVENT_PARAM))) 
    {
      System.out.println("In download sub tab");
    }
     else if(("upload").equals(pageContext.getParameter(EVENT_PARAM))) 
    {
      System.out.println("In upload sub tab");
    }
    
    else 
    {
      MessageToken[] tokens = { };
      throw new OAException("XXFIN", "XXOD_EXCEL_UPLD_FILE_MISSING", tokens);
    }
  }
}
