/*===========================================================================+
 |                             Office Depot - Project Simplify               |
 |                 Oracle NAIO                                               |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODWacFileUploadCO.java                                        |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Class to download template and upload the .csv file, to make a call to |
 |    data validation and insertion program. To give error messages if any   |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    None                                                                   |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    31-JUL-07 Mithun D S   Created                                         |
 |    08-OCT-07 Archie       Updated the pack to fetch                       |
 |                           only one template                               |
 +===========================================================================*/

package od.oracle.apps.xxptp.wac.fileupload.webui;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageDownloadBean;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.OADataBoundValueViewObject;
import oracle.jbo.domain.BlobDomain;
import oracle.apps.fnd.server.FndLobsVORowImpl;
import od.oracle.apps.xxptp.wac.fileupload.server.ODInvAverageCostStgVORowImpl;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import com.sun.java.util.collections.HashMap;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import java.sql.SQLException;
import oracle.jdbc.OracleCallableStatement;
import java.sql.Connection;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jdbc.OracleTypes;
import oracle.jbo.RowSetIterator;

public class ODWacFileUploadCO extends OAControllerImpl
{

/**
 * Constructor method 
 */

  public ODWacFileUploadCO()
  {

  }
  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext,OAWebBean webBean)
  {  
   super.processRequest(pageContext, webBean );
   // Get current page AM
   OAApplicationModule currentAm = pageContext.getApplicationModule(webBean);

   OAViewObject fndLobs = (OAViewObject)currentAm.findViewObject("FndLobsVODown");
   if ( fndLobs == null )
   {
     fndLobs = (OAViewObject)currentAm.createViewObject("FndLobsVODown", "oracle.apps.fnd.server.FndLobsVO");
   }

   //Setting the where clause to get Template1.xls
   fndLobs.setWhereClause("PROGRAM_NAME = :1");
   fndLobs.setWhereClause(fndLobs.getWhereClause()+" AND FILE_NAME = :2");
   fndLobs.setWhereClauseParam(0, "OD_GI_WCA_EXT_TEMPLATE");
   fndLobs.setWhereClauseParam(1, "Template.xls");
   fndLobs.executeQuery();

   //Assigning the derived value to the message download bean
   OAMessageDownloadBean downloadBean1 = (OAMessageDownloadBean)webBean.findIndexedChildRecursive("TemplateDownload1");
   downloadBean1.setViewUsageName(fndLobs.getFullName()); // always gives full name of view instance
   downloadBean1.setViewAttributeName("FileName"); // for display text of the link
   downloadBean1.setContentViewAttributeName("FileData"); 
   OADataBoundValueViewObject contentBoundValue1 = new OADataBoundValueViewObject(downloadBean1, "FileContentType");
   downloadBean1.setAttributeValue(OAWebBeanConstants.FILE_CONTENT_TYPE, contentBoundValue1); 

   OAViewObject fndLobs1 = (OAViewObject)currentAm.findViewObject("FndLobsVODown1");
   if (fndLobs1 == null )
   {
     fndLobs1 = (OAViewObject)currentAm.createViewObject("FndLobsVODown1", "oracle.apps.fnd.server.FndLobsVO");
   }
   
   //Setting the where clause to get Template1.xls
   /*fndLobs1.setWhereClause("PROGRAM_NAME = :1");
   fndLobs1.setWhereClause(fndLobs1.getWhereClause()+" AND FILE_NAME = :2");
   fndLobs1.setWhereClauseParam(0, "OD_GI_WCA_EXT_TEMPLATE");
   fndLobs1.setWhereClauseParam(1, "Template2.xls");
   fndLobs1.executeQuery();

   //Assigning the derived value to the message download bean
   OAMessageDownloadBean downloadBean2 = (OAMessageDownloadBean)webBean.findIndexedChildRecursive("TemplateDownload2");
   downloadBean2.setViewUsageName(fndLobs1.getFullName()); // always gives full name of view instance
   downloadBean2.setViewAttributeName("FileName"); // for display text of the link
   downloadBean2.setContentViewAttributeName("FileData"); 
   OADataBoundValueViewObject contentBoundValue2 = new OADataBoundValueViewObject(downloadBean2, "FileContentType");
   downloadBean2.setAttributeValue(OAWebBeanConstants.FILE_CONTENT_TYPE, contentBoundValue2); 
   */

   OAMessageTextInputBean oaBean = (OAMessageTextInputBean)webBean.findChildRecursive("WFItemKeyNumber");
   oaBean.setText(pageContext.getParameter("fileID"));

   String errDetails = "";
   String errstatus  = "";
   String errstat    = "";
   String errBuff    = "";
   
   //Check if 'Apply' button was pressed
   if (pageContext.getParameter("Okay") != null)
   {
     if ("E".equals(pageContext.getParameter("uploadStatus"))) 
     {
       OAViewObject errVO = (OAViewObject)currentAm.findViewObject("ODInvAverageCostStg");
       if (errVO == null)
       {
          errVO = (OAViewObject)currentAm.createViewObject("ODInvAverageCostStg", "od.oracle.apps.xxptp.wac.fileupload.server.ODInvAverageCostStgVO");
       }
       
       //Getting error message from staging table
       errVO.setWhereClause("FILE_ID = :1");
       errVO.setWhereClauseParam(0,pageContext.getParameter("fileID"));
       errVO.executeQuery();

       int rowCount = errVO.getRowCount(); 
       RowSetIterator loopIter = errVO.createRowSetIterator("loopIter");

       if (rowCount > 0)
       {
         loopIter.setRangeStart(0);
         loopIter.setRangeSize(rowCount);

         for (int i = 0; i < rowCount; i++)
         {
           ODInvAverageCostStgVORowImpl errVORow = (ODInvAverageCostStgVORowImpl)loopIter.getRowAtRangeIndex(i);
           errBuff = "Record Number "+errVORow.getRecordNumber()+" - "+errVORow.getStatusFlag()+": "+errVORow.getErrorMessage();
           errDetails = errDetails + "\n" + errBuff;
         }
       }
      
      loopIter.closeRowSetIterator();    

      oaBean = (OAMessageTextInputBean)webBean.findChildRecursive("ValidationStatus");
      oaBean.setText(pageContext.getParameter("errorDetails") + " rows failed. See Errors below.");

      oaBean = (OAMessageTextInputBean)webBean.findChildRecursive("ErrorDetails");
      oaBean.setText(errDetails);
     }            
     
     else if ("F".equals(pageContext.getParameter("uploadStatus"))) 
     {
      
       oaBean = (OAMessageTextInputBean)webBean.findChildRecursive("ValidationStatus");
       oaBean.setText("Not Validated. See errors below.");

       oaBean = (OAMessageTextInputBean)webBean.findChildRecursive("ErrorDetails");
       oaBean.setText(pageContext.getParameter("errorDetails"));
     }
     
     else 
     {
       oaBean = (OAMessageTextInputBean)webBean.findChildRecursive("ValidationStatus");
       oaBean.setText("Validated");

       oaBean = (OAMessageTextInputBean)webBean.findChildRecursive("ErrorDetails");
       oaBean.setText("No Errors");
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
    if (pageContext.getParameter("Okay") != null)
    {
      OAApplicationModule currentAm = pageContext.getApplicationModule(webBean);
      // Insert csv file into FND_LOBS
      String fileName = pageContext.getParameter("FileInput");
      BlobDomain myblob = (BlobDomain)pageContext.getParameterObject(fileName);
      String contentType = "application/vnd.ms-excel; charset=UTF-8";
      String fileFormat  = "BINARY";

      OAViewObject tempFndLobsVO = (OAViewObject)currentAm.findViewObject("FndLobsVO");
      if ( tempFndLobsVO == null )
      {
        tempFndLobsVO = (OAViewObject)currentAm.createViewObject("FndLobsVO", "oracle.apps.fnd.server.FndLobsVO");
        tempFndLobsVO.setMaxFetchSize(0);
      }
      
      OAViewObject fVo = (OAViewObject)currentAm.findViewObject("FndLobsVO");
      if (!fVo.isPreparedForExecution())
      fVo.setMaxFetchSize(0); 
      FndLobsVORowImpl fRow = (FndLobsVORowImpl)fVo.createRow();
      fRow.setFileName(fileName);
      fRow.setFileContentType(contentType);
      fRow.setFileFormat(fileFormat);
      fRow.setFileData(myblob);
      //Set date to sysdate
      fRow.setUploadDate(new Date());
      //change program name
      fRow.setProgramName("OD_GI_WCA_EXT");
      tempFndLobsVO.insertRow(fRow); //For View purpose

      fVo.insertRow(fRow);
      currentAm.getTransaction().commit();
      Number fileId = fRow.getFileId();
      
      HashMap params = new HashMap();        
      params.put("fileID", "");
      params.put("fileName", "" );
      params.put("uploadStatus","");
      params.put("errorDetails", "");
      
      String errDetails = "";
      String errstatus  = "";
      String errstat    = "";
      String errBuff    = "";
      //Call to the procedure to validate data
      String validateQry = " BEGIN XX_GI_AVERAGE_COST_PKG.GET_AVERAGE_COST_DETAILS(:1, :2, :3); END;";
      OracleCallableStatement callableStatement = null;
      Connection conn;
      OADBTransaction transaction =  pageContext.getApplicationModule(webBean).getOADBTransaction();

      try
      {
        conn = transaction.getJdbcConnection ();
        callableStatement = (OracleCallableStatement) conn.prepareCall(validateQry);
        callableStatement.setInt(1, fileId.intValue());
        callableStatement.registerOutParameter(2, OracleTypes.VARCHAR, 0, 3000);
        callableStatement.registerOutParameter(3, OracleTypes.VARCHAR, 0, 3000);
        callableStatement.execute();
        errstatus = callableStatement.getString(2);
        errstat   = callableStatement.getString(3);
          
      }
      catch(SQLException e)
      {
        errDetails = "Error during SQL Operation";
      }
      finally
      {
        try 
        {
          if(callableStatement!=null) callableStatement.close();
        }
          catch(SQLException e)
        { 
          e.printStackTrace(); 
        }
      }
               
      params.put("fileID", fileId);
      params.put("fileName", fileName );
      params.put("uploadStatus", errstatus);
      params.put("errorDetails", errstat);

      pageContext.forwardImmediatelyToCurrentPage(params, false,ADD_BREAD_CRUMB_NO);

    }
  }
}
