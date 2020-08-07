/*===========================================================================+
 |   Copyright (c) 2001, 2003 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.cdh.uploads.remitto.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAException;
import oracle.cabo.ui.data.DataObject;
import oracle.jbo.domain.BlobDomain;
import java.io.FileWriter;
import java.io.File;
import java.io.Reader;
import java.io.IOException;
import java.io.Serializable;
import com.sun.java.util.collections.HashMap;
import oracle.apps.fnd.framework.OAFwkConstants;
/**
 * Controller for ...
 */
public class XXODCDHUploadRemitToCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header: XXODCDHUploadRemitToCO.java 115.3 2006/06/13 12:54:12 ssmohan noship $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  Serializable strReturn = null;        

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
    Serializable strReturn = (Serializable)pageContext.getParameter("rId");
    if (strReturn != null ) {
      webBean.findIndexedChildRecursive("UploadRegion").setRendered( false);
      webBean.findIndexedChildRecursive("ViewRequestsRegion").setRendered( true);
    } else {
      webBean.findIndexedChildRecursive("ViewRequestsRegion").setRendered( false);
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
    String strFileName = null;
    String strLocalFileName = null;
    Serializable[] param = null;
    HashMap hMap = null;

    DataObject fileUploadData = pageContext.getNamedDataObject("fileSelector");
    if (fileUploadData != null)
      strLocalFileName = (String)fileUploadData.selectValue(null, "UPLOAD_FILE_NAME");
    strFileName = strLocalFileName;
    System.out.println("strFileName: " + strFileName);
    pageContext.writeDiagnostics(METHOD_NAME, "1 strFileName: " + strFileName, OAFwkConstants.PROCEDURE);        
    if (pageContext.getParameter("btnSubmit") != null) 
    {
      if (isCsvFile(strFileName)) {
        strFileName = doUpload( pageContext, webBean);
        pageContext.writeDiagnostics(METHOD_NAME, "2 strFileName: " + strFileName, OAFwkConstants.PROCEDURE);        
        param = new Serializable[4];
        param[0] = "" + pageContext.getUserId();
        param[1] = "" + pageContext.getResponsibilityId();
        param[2] = "" + pageContext.getResponsibilityApplicationId();
        param[3] = strFileName;

        strReturn = "";
        strReturn = pageContext.getApplicationModule(webBean).invokeMethod("runConcReqSet", param);
        System.out.println("strReturn: " + strReturn);
        pageContext.writeDiagnostics(METHOD_NAME, "strReturn: " + strReturn, OAFwkConstants.PROCEDURE);        

        hMap = new HashMap();
        hMap.put( "rId", strReturn);
      
      OAException msg1 = new OAException("The file " + strLocalFileName +
              " has been uploaded to the server successfully.", OAException.CONFIRMATION);
      pageContext.putDialogMessage(msg1);

      OAException msg2 = new OAException ("A Concurrent Request Set " +
      "is submitted to load the " +
      "Remit to Sales Channels. \nThe Request Set Id is: " + strReturn + ".", OAException.INFORMATION);
      pageContext.putDialogMessage(msg2);


        pageContext.forwardImmediatelyToCurrentPage(
                                   hMap
                                 , true
                                 , ADD_BREAD_CRUMB_NO );
                           
        }
        else {
          OAException message = new OAException("Please upload only a CSV file!",
                                                OAException.ERROR
                                                );
          pageContext.putDialogMessage(message);                                               
        }
    }
    if (pageContext.getParameter("btnViewRequests") != null) 
    {
        pageContext.setForwardURL("FNDCPVIEWREQUEST", 
                                       KEEP_MENU_CONTEXT,
                                       "IMC_NG_MAIN_MENU", 
                                       hMap, 
                                       false, 
                                       ADD_BREAD_CRUMB_NO,
                                       IGNORE_MESSAGES);
    }
  }

  public static String doUpload(OAPageContext pageContext, OAWebBean webBean)
  {
    // String LOG_DIR = "";

    //Get the temp directory path
    //framework.Logging.system.filename retrieves the TEMP path
	
	 //Added for Defect 40505
	 
	String LOG_DIR = pageContext.getProfile("XX_CDH_FILE_UPLOAD_PATH"); 
	
	
      //Added for Defect 40505
   // String logDir = System.getProperty("framework.Logging.system.filename");
   // try
   //  {
   //    if (logDir != null && logDir.trim().length() >= 0)
   //    {
   //      int slash = Math.max(logDir.lastIndexOf('/'), logDir.lastIndexOf('\\'));
   //     LOG_DIR = logDir.substring(0, slash + 1);
   //   }
   // }catch (Exception ex)
   // {
    //  System.out.println(ex.getMessage());
    //  ex.printStackTrace();
    //  throw new OAException(ex.getMessage(),OAException.ERROR);
   // }

    DataObject fileUploadData = pageContext.getNamedDataObject("fileSelector");
    String uFileName = null;
    uFileName = (String)fileUploadData.selectValue(null, "UPLOAD_FILE_NAME");
    String contentType = (String)fileUploadData.selectValue(null, "UPLOAD_FILE_MIME_TYPE");

    BlobDomain uploadedByteStream = (BlobDomain)fileUploadData.selectValue(null, uFileName);
    Reader reader = uploadedByteStream.getCharacterStream();

    String file_name = LOG_DIR + "uploadeFile" + pageContext.getUserId() + pageContext.getSessionId() + ".csv";
    int line_counter = 0;
    String currLine = null;
    try{
      FileWriter fwriter = new FileWriter(file_name);
      int c, c_name;
      while((c=reader.read())!=-1)
      {
        fwriter.write(c);
      }
      fwriter.flush();
      fwriter.close();

    }catch(IOException ioe)
    {
      ioe.printStackTrace();
      throw new OAException(ioe.getMessage(), OAException.ERROR);
    }catch(Exception e)
    {
      e.printStackTrace();
      throw new OAException(e.getMessage(), OAException.ERROR);
    }

    return file_name;
  }
  private boolean isCsvFile( String strFileName) 
  {
    boolean isCsv = false;

    String strTemp = "";
    strTemp = strFileName.substring(strFileName.lastIndexOf('.')+1, strFileName.length());
    if (strTemp.trim().equalsIgnoreCase("CSV"))
      isCsv = true;
    return isCsv;
  }
}
