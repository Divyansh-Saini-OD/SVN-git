/*
--  Copyright (c) 2005, by Dell Inc., All Rights Reserved
--
-- RICE Id: E1207 - QMR Extension
-- Script Location:
-- $CUSTOM_JAVA_TOP/od/oracle/apps/xxmer/papb/server/webui
-- Description: Custom upload page
-- Package Usage       : Unrestricted.
-- Name                  Type         Purpose
-- --------------------  -----------  ------------------------------------------
--
-- Notes:
-- History:
-- Name            Date         Version    Description
-- -----           -----        -------    -----------
-- Sridevi K       7-Jun-2013    1.0        Retrofitted for R12 upgrade
--
*/
package od.oracle.apps.xxmer.papb.server.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageFileUploadBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.jbo.domain.BlobDomain;
import od.oracle.apps.xxmer.papb.server.PAPBExcelParser;
import java.util.ArrayList;
import oracle.apps.fnd.framework.server.OADBTransaction;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.lang.Integer;
import oracle.apps.fnd.common.MessageToken;
//Retrofit for R12 upgrade - Start
import jxl.read.biff.BiffException;
//import oracle.jdbc.driver.OracleCallableStatement;
//Retrofit for R12 upgrade - End
import java.sql.Types;




/**
 * Controller for ...
 */
public class ExcelUploadCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  protected String m_strForwardURLList;
  protected String m_strForwardURLErrors;
  protected String m_strSuccessMsgToken;
  protected String m_strErrorMsgToken;

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
  
  public ExcelUploadCO()
  {
      m_strForwardURLList = "OA.jsp?page=/od/oracle/apps/xxmer/ss/webui/SSCapsMultiSearchPG";
      m_strForwardURLErrors = "OA.jsp?page=/od/oracle/apps/xxmer/ss/webui/SSFileDownloadPG";
      m_strSuccessMsgToken = "XXMER_PA_PB_EXCEL_UPLOAD_SUC";
      m_strErrorMsgToken = "XXMER_PA_PB_EXCEL_UPLOAD_ERR";
  }


  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
    OAPageLayoutBean pageLayoutBean = (OAPageLayoutBean)webBean;
    OAMessageFileUploadBean fileUploadBean = 
      (OAMessageFileUploadBean) pageLayoutBean.findChildRecursive("FileUpload");
    fileUploadBean.setFileContentType("application/vnd.ms-excel");
  }

  public String loadExcelDatatoDB(OAPageContext pageContext, OAWebBean webBean)
  {
    Connection conn = null;
    Statement stmt = null;
		ResultSet rs = null;
    Statement stmt1 = null;
		ResultSet rs1 = null;

    String strTemplateID = pageContext.getParameter("ExcelTemplateChoice");
    pageContext.writeDiagnostics(this, "OD:loadExcelDatatoDB", 1);

    try {

      String strExcelUploadFileName = pageContext.getParameter("UPLOAD_FILE_NAME");
      if(strExcelUploadFileName == null)
	  throw new Exception(" Please select a file to upload!");

      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      OADBTransaction oadbtransaction = am.getOADBTransaction();
      conn = oadbtransaction.getJdbcConnection();
      
      String sqlGet1 = 
        " select ffvv.attribute1 first_row, ffvv.attribute2 image_path "
        + " from  apps.FND_FLEX_VALUES_VL ffvv, apps.FND_FLEX_VALUE_SETS ffvs "
        + " where ffvv.flex_value_set_id = ffvs.flex_value_set_id"
        + " and ffvs.flex_value_set_name = 'XX_PA_PB_EXCEL_TEMPLATE_CONFIG' "
        + " and ffvv.flex_value = " + strTemplateID;
      
      pageContext.writeDiagnostics(this, "OD:sqlGet1"+sqlGet1, 1);

	  String strImgPath;
      int nFirstRow = -1;       
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
      + " from  xxmer.xx_pa_pb_excel_config where template_id = " + strTemplateID;
      

      pageContext.writeDiagnostics(this, "OD:sqlGet"+sqlGet, 1);

	  //ArrayList list = new ArrayList();// Changed for R12 Upgrade retrofit
      ArrayList<ExcelDef> list = new ArrayList<ExcelDef>();
      
      stmt = conn.createStatement();
			rs = stmt.executeQuery(sqlGet);
                 
      // Right now we support only on etable name and one sheet per upload
      String strTableName ="";
      int nSheetNum = -1;
			while (rs.next()) 
			{				
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

            pageContext.writeDiagnostics(this, "OD:Before executing logic of PAPBExcelParser", 1); 
      PAPBExcelParser excelParser = null;
      try
      {
        BlobDomain blobdomain = (BlobDomain)pageContext.getParameterObject(strExcelUploadFileName);
        excelParser = new PAPBExcelParser
              (blobdomain.getBinaryStream());
        excelParser.setCurrentSheet(nSheetNum);        
        pageContext.writeDiagnostics(this,"OD:set current sheet", 1); 
      }
      catch(BiffException e) //Commented for R12 upgrade - Retrofit
      {
        return e.getMessage();
      }

      int nMaxRows = excelParser.getNumRowsInCurrentSheet();
      
        pageContext.writeDiagnostics(this, "OD:no of rows in current sheet"+nMaxRows, 1); 
      boolean bNullDataRowFound = false;
      for (int i = nFirstRow; i <= nMaxRows; i++)
      {
        if (bNullDataRowFound)
          break;
        String strInsertSql = "insert into " + strTableName + " (creation_date, process_flag, created_by ";
        String strInsertSqlValues = " values(sysdate, 1, " + pageContext.getUserId(); 

        String strImageTag = strImgPath+"img_";
        //strImageTag = "C:\\img_"; //TO DO remove this
        for (int j=0; j < list.size(); j++)
        {
          //ExcelDef exceldef = (ExcelDef) list.get(j); // Changed for R12 Upgrade retrofit
		  ExcelDef exceldef = list.get(j);

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
          Statement stmtInsert = conn.createStatement();
          stmtInsert.executeUpdate(strInsert);
          if (stmtInsert != null)
            stmtInsert.close();
        }
      }
      conn.commit();
        pageContext.writeDiagnostics(this, "OD:before Now call the concurrent program", 1); 
      //Now call the concurrent program
      /* Commented for R12 retrofit */
	  /*
	  OracleCallableStatement oraclecallablestatement;
      String sql = "BEGIN XX_PA_PB_PRDUPLD_PKG.xx_submit_conc_pgm"
        + " (o_request_id => :1 ); END;";
      oraclecallablestatement = (OracleCallableStatement)
          oadbtransaction.createCallableStatement(sql, -1);
      oraclecallablestatement.registerOutParameter(1, Types.NUMERIC);
      oraclecallablestatement.execute();
      int nRequestID = oraclecallablestatement.getInt(1);
      oraclecallablestatement.close();      
	  */
        pageContext.writeDiagnostics(this, "OD:completed loadExcelDatatoDB", 1); 
      return null;
    } catch (SQLException e) {
      //e.printStackTrace();
      return e.getMessage();
    } catch (Exception ee) {	
      //ee.printStackTrace();
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
    if (pageContext.getParameter("Apply") != null)
    {
      String strError = loadExcelDatatoDB (pageContext, webBean);
      if (strError == null)
      {
        OAException successMessage = new OAException("XXMER", m_strSuccessMsgToken, 
                                  null, OAException.INFORMATION, null); 
        pageContext.putDialogMessage(successMessage);
      }
      else
      {
        MessageToken[] tokens = { new MessageToken("P_ERROR_MSG", strError)};
        OAException errMessage = new OAException("XXMER", m_strErrorMsgToken, 
                                  tokens, OAException.ERROR, null);
        pageContext.putDialogMessage(errMessage);
      }
      
/*      
        String s = pageContext.getParameter("UPLOAD_FILE_NAME");
        BlobDomain blobdomain = (BlobDomain)pageContext.getParameterObject(s);
        PAPBExcelParser excelParser = new PAPBExcelParser
              (blobdomain.getBinaryStream());

        String str = excelParser.getCellValue(10,2); //Cell K3
        str = excelParser.getCellValue(9,4); //Cell J5
        str = excelParser.getCellValue(1,8); //Cell B9
        str = excelParser.getCellValue(16,8); //Cell Q9
        
     /*
        List array_data = excelParser.parse();
        StringBuffer sbError = new StringBuffer("");
        ArrayList array_Errors = new ArrayList();
        int nErrorCount = callExcelUploadStoredProc(pageContext, webBean, 
              array_data, sbError, array_Errors);

        if (nErrorCount == 0)
        {
          String strNum = Integer.toString(array_data.size());
          MessageToken[] tokens = { new MessageToken("NUMBER", strNum) };
          OAException confirmMessage = new OAException("XXMER", 
              m_strConfirmMsgToken, tokens,OAException.CONFIRMATION, null);

          // Per the UI guidelines, we want to add the confirmation message at the
          // top of the search/results page and we want the old search criteria and
          // results to display.

          OADialogPage dialogPage = new OADialogPage(OAException.CONFIRMATION, 
              confirmMessage,
              null,
              m_strForwardURLList,
              null);
          pageContext.releaseRootApplicationModule(); 
          pageContext.redirectToDialogPage(dialogPage);
        }
        else
        {
          try
          {
            byte[] outBytes = excelParser.createMergedWorkBook(array_Errors);
/*            FileOutputStream fs = new FileOutputStream("SubbuExcelTest.xls");
            fs.write(outBytes);
            fs.close();
*
            StringBuffer sbError1 = new StringBuffer("");
            int nRet = callWriteExcelErrorsStoredProc(pageContext, webBean, 
                outBytes, sbError1);
            String strNum1 = Integer.toString(nErrorCount);
            String strNum2 = Integer.toString(array_data.size());
            MessageToken[] tokens = { new MessageToken("NUMBER1", strNum1),
                    new MessageToken("NUMBER2", strNum2)};
            OAException errMessage = new OAException("XXMER", m_strErrorMsgToken, 
                                      tokens, OAException.ERROR, null);
            pageContext.putDialogMessage(errMessage);
            if (nRet == 0)
            {
              OADialogPage dialogPage = new OADialogPage(OAException.ERROR, 
                  errMessage,
                  null,
                  m_strForwardURLErrors,
                  null);
              pageContext.releaseRootApplicationModule(); 
              pageContext.redirectToDialogPage(dialogPage);
            }
          }
          catch (Exception ex) 
          {
            ex.printStackTrace();
          }
        }*/
    }    
  }

}
