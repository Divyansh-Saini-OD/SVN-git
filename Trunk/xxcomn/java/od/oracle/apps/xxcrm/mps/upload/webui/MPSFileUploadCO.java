/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.mps.upload.webui;

import java.io.Serializable;
import oracle.apps.fnd.common.MessageToken;
import java.lang.Integer;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import com.sun.java.util.collections.HashMap;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants; 

import java.util.ArrayList;
import java.util.Vector;
import oracle.apps.fnd.framework.OAException;
import jxl.read.biff.BiffException;

import od.oracle.apps.xxcrm.mps.upload.webui.ExcelParser;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.cp.request.ConcurrentRequest;
import oracle.apps.fnd.cp.request.RequestSubmissionException;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageFileUploadBean;

import oracle.jbo.domain.BlobDomain;

/**
 * Controller for ...
 */
public class MPSFileUploadCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  boolean UploadClicked =false;
  boolean submitProgClicked =false;
  boolean  fileBrowsed = false;

  private String strConcProgName = "";
  private String strConcProgShortName="";
  private String strNextSteps = null;
  private String strBatchID1 = null;
  
  private void setConcProgName( String progName) {
    this.strConcProgName = progName;
  }

  private String getConcProgName() {
    return this.strConcProgName;
  }
  
  private void setNextStepsName( String sNextSteps) {
    this.strNextSteps = sNextSteps;
  }

  private String getNextStepsName() {
    return this.strNextSteps;
  } 

  private void setBatchID( String sBatchID) {
    this.strBatchID1 = sBatchID;
  }

  private String getBatchID() {
    return this.strBatchID1;
  }   

  private void setConcProgShortName( String progShortName) {
    this.strConcProgShortName = progShortName;
  }

  private String getConcProgShortName() {
    return this.strConcProgShortName;
  }
  
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
  
  public MPSFileUploadCO()
  {
  }

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);

    pageContext.writeDiagnostics("MPSFileUploadCO processRequest", "START--", 3);
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    OADBTransaction oadbtransaction = am.getOADBTransaction();
    ResultSet rsProg = null;
    Statement stmt = null;
    String progShortName="";
    String programName ="";
    String applName="";
    String strTableName="";
    Connection conn = oadbtransaction.getJdbcConnection();
	
    Serializable strReturn = (Serializable)pageContext.getParameter("rId");
    pageContext.writeDiagnostics("MPSFileUploadCO processRequest","strReturn: " + strReturn,3);
    if (strReturn != null ) {
      webBean.findIndexedChildRecursive("UploadRegion").setRendered( false);
      //webBean.findIndexedChildRecursive("ViewRequestsRegion").setRendered( true);
      webBean.findIndexedChildRecursive("btnView").setRendered( true);
    } else {
      //webBean.findIndexedChildRecursive("ViewRequestsRegion").setRendered( false);
      webBean.findIndexedChildRecursive("btnView").setRendered( false);
    }	
	  String strNSteps = (String)pageContext.getParameter("next_steps");
    System.out.println("strNSteps: " + strNSteps);
    if (strNSteps != null ) {
      webBean.findIndexedChildRecursive("btnNextSteps").setRendered( true);
	    setNextStepsName(strNSteps);
    } else {
      webBean.findIndexedChildRecursive("btnNextSteps").setRendered( false);
    }

	  String strUploadFileName = pageContext.getParameter("FileUpload");
    String strTemp = "";
    if (strUploadFileName != null) {
      strTemp = strUploadFileName.substring(strUploadFileName.lastIndexOf('.')+1, strUploadFileName.length());
      System.out.println("strTemp: " + strTemp);
    
      OAPageLayoutBean pageLayoutBean = (OAPageLayoutBean)webBean;
      OAMessageFileUploadBean fileUploadBean = 
        (OAMessageFileUploadBean) pageLayoutBean.findChildRecursive("FileUpload");
      if (strTemp.trim().equalsIgnoreCase("XLS")) {
        fileUploadBean.setFileContentType("application/vnd.ms-excel");
      }
      else if ( (strTemp.trim().equalsIgnoreCase("XLSX"))) {
        fileUploadBean.setFileContentType("application/application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
      }
      else {
        OAException errorMessage = new OAException("Unsupported File for upload!",OAException.ERROR);
        pageContext.putDialogMessage(errorMessage);
        throw errorMessage;
      }
    }
      
	  pageContext.writeDiagnostics("application: ", pageContext.getApplicationShortName(),3);
  
    pageContext.writeDiagnostics("MPSFileUploadCO processRequest ",  "END--",3);
  }
  
  public String loadExcelDatatoDB(OAPageContext pageContext, OAWebBean webBean)
  { 
    pageContext.writeDiagnostics("MPSFileUploadCO loadExcelDatatoDB ", "START--", 3);
  
    Connection conn = null;
    Statement stmt = null;
	  ResultSet rs = null;
    Statement stmt1 = null;
	  ResultSet rs1 = null;
    String strImgPath = "";
    int nFirstRow = 2;  //to make it simple, hard coded, so that in every 
                        //upload excel file, the data  starts from 2nd row      

    String strTemplateID = pageContext.getParameter("ExcelTemplateChoice");
	  pageContext.writeDiagnostics("Template Id: ", strTemplateID, 3);

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

      String sqlGet = " select   val.source_value1 as staging_table_name " +
                      " , val.source_value2 as staging_column_name       " +
                      " , val.source_value3 as data_type                 " +
                      " , val.source_value5 as sheet_no                  " +
                      " , val.source_value4 as stg_column_heading        " +
                      " , val.source_value6 as excel_column              " +
                      " , val.source_value7 as template_id               " +
                      " , val.source_value8 as app_short_name            " +
                      " , val.source_value9 as prog_short_name           " +
                      " , val.source_value10 as validation_sql           " +
                      " , val.target_value1 as program_name              " +
                      " , val.target_value2 as next_steps                " +
                      " , NULL AS use_in_img_tag                         " +
                      " FROM     XX_FIN_TRANSLATEVALUES     val          " +
                      " , XX_FIN_TRANSLATEDEFINITION def                 " +
                      " WHERE  def.TRANSLATE_ID = val.TRANSLATE_ID       " +
                      " and    def.TRANSLATION_NAME = '" + strTemplateID + "'" +
                      " and    val.ENABLED_FLAG = 'Y'";
      
      if(pageContext.isLoggingEnabled(3)){      
        pageContext.writeDiagnostics("SQL to get staging table details =",sqlGet,3);
      }
      ArrayList list = new ArrayList();
      
      stmt = conn.createStatement();
      rs = stmt.executeQuery(sqlGet);
      
	  // Right now we support only on table name and one sheet per upload
      String strTableName ="";
	  String strProgName = "";
	  String strProgShortName = "";
	  String strNxtSteps = "";
	  String strBatchID = "";
	  strBatchID = am.getOADBTransaction().getSequenceValue("XXOM.XX_CS_MPS_UPLOAD_BATCH_ID_S").stringValue();
	  setBatchID(strBatchID);
	  
      int nSheetNum = -1;
      while (rs.next()) 
      {				
		//System.out.println("Inside result set");
        strTableName = rs.getString("staging_table_name");
        String strColumn = rs.getString("staging_column_name");
        String strDataType = rs.getString("data_type");
        nSheetNum = rs.getInt("sheet_no");
        String strExcelCol = rs.getString("excel_column");
        String strUseInImgTag = rs.getString("use_in_img_tag");
        String strValidationSQL = rs.getString("validation_sql");
        String strColumnHeading = rs.getString("stg_column_heading");
		strProgName = rs.getString("program_name");
		strNxtSteps = rs.getString("next_steps");
    System.out.println("strNxtSteps: " + strNxtSteps);
		strProgShortName = rs.getString("prog_short_name");		
        ExcelDef exceldef = new ExcelDef(strColumn, strExcelCol, 
            strDataType, nSheetNum, strUseInImgTag, strValidationSQL, strColumnHeading);
            
        list.add(exceldef);
      }
      //set Next Steps Name
	  setNextStepsName(strNxtSteps);

      //set Concurrent Program Name
	  setConcProgName(strProgName);
	  
	  //set Conc Progam Short Name
	  setConcProgShortName(strProgShortName);
	  
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
        OAException successMessage = new OAException(e.getMessage(),OAException.INFORMATION);
        pageContext.putDialogMessage(successMessage);
        return e.getMessage();
      }

     int nMaxRows = excelParser.getNumRowsInCurrentSheet();
     //System.out.println("nMaxRows="+nMaxRows);
     if(pageContext.isLoggingEnabled(3)){
       pageContext.writeDiagnostics("Rows in excel File=",nMaxRows+"",3);   
     }
     boolean bNullDataRowFound = false;
     for (int i = nFirstRow; i <= nMaxRows; i++)
     {
        if (bNullDataRowFound)
          break;

        String strInsertSql = "insert into " + strTableName + " (batch_id, creation_date,last_update_date, created_by ,last_updated_by";
        String strInsertSqlValues = " values(" + getBatchID() + ", sysdate, sysdate, " + pageContext.getUserId()+","+pageContext.getUserId(); 
        String strImageTag = "";
        strImageTag = strImgPath+"img_";

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
          pageContext.writeDiagnostics("strInsertSql=",strInsertSql,3);   
          pageContext.writeDiagnostics("strInsertSqlValues=",strInsertSqlValues,3);   
          Statement stmtInsert = conn.createStatement();
          stmtInsert.executeUpdate(strInsert);
          if (stmtInsert != null)
            stmtInsert.close();
        }
      }
      conn.commit();

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
    pageContext.writeDiagnostics("MPSFileUploadCO loadExcelDatatoDB", "END--", 3);
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
    pageContext.writeDiagnostics("MPSFileUploadCO processFormRequest ",  "START--", 3);
    Serializable strReturn = (Serializable)pageContext.getParameter("rId");
    pageContext.writeDiagnostics("MPSFileUploadCO processFormRequest","strReturn: " + strReturn,3);
	
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
         
	HashMap hMap = new HashMap();
	HashMap hMap1 = new HashMap();
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
            String successMsg="Excel File " + strExcelUploadFileName + " Uploaded Successfully.";
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
      
      System.out.println("getNextStepsName: " + getNextStepsName());
      if (getNextStepsName() != null) {
        pageContext.putParameter("next_steps", getNextStepsName());
        hMap.put("next_steps", getNextStepsName());
      } 
      
		try
      {
      // get the JDBC connection      
      ConcurrentRequest cr = new ConcurrentRequest(conn);
      // call submit request

      Vector param = new Vector();
      param.add(0,getBatchID());
	  hMap1.put("BatchID", getBatchID());
	  hMap.put("BatchID", getBatchID());
      pageContext.putTransactionValue("parentRequestId",""); // clear the transaction value buffer
      int reqId = cr.submitRequest("CS", getConcProgShortName(), null,null, false, param);

      hMap.put( "rId", (new Integer(reqId)).toString());
      pageContext.putParameter("rId", (new Integer(reqId)).toString());
	  
      conn.commit();

      pageContext.putTransactionValue("parentRequestId",reqId+"");
      MessageToken[] tokens={new MessageToken("PROGRAMNAME", getConcProgName() ),new MessageToken("REQID",reqId+"")};//, new MessageToken("FILENAME",(String)pageContext.getTransactionValue("strExcelUploadFileName"))};

      OAException msg2 = new OAException("CS", "XX_CS_MPS_EXCEL_UPLD_PRG_DET", tokens,OAException.INFORMATION,null);

      pageContext.putDialogMessage(msg2);

      pageContext.forwardImmediatelyToCurrentPage(
                                   hMap
                                 , true
                                 , OAWebBeanConstants.ADD_BREAD_CRUMB_YES );
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

    String s2 = pageContext.getParameter("event");
    if("viewRequest".equals(s2)) {
        pageContext.setForwardURL("FNDCPVIEWREQUEST", 
                                   KEEP_MENU_CONTEXT,
                                   "IMC_NG_MAIN_MENU", 
                                   hMap, 
                                   false, 
                                   ADD_BREAD_CRUMB_YES,
                                   IGNORE_MESSAGES);
        return;
    }
       
    if("NextSteps".equals(s2)) {
	    
      Serializable[] reqParam =  { (String)pageContext.getParameter("rId") };
      am.invokeMethod("getOutputURL", reqParam);
      String outputURL = (String)pageContext.getTransactionValue("OutputURL");
      try
      {
        pageContext.setForwardURL( getNextStepsName(), 
                                   KEEP_MENU_CONTEXT,
                                   "IMC_NG_MAIN_MENU", 
                                   hMap1, 
                                   false, 
                                   ADD_BREAD_CRUMB_YES,
                                   IGNORE_MESSAGES);
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

    pageContext.writeDiagnostics("MPSFileUploadCO processFormRequest ", "END--", 3);
  }
}
