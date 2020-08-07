/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.ar.hz.uploads.custxref.webui;

import com.sun.java.util.collections.HashMap;

import java.io.FileWriter;
import java.io.IOException;
import java.io.Reader;
import java.io.Serializable;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import oracle.cabo.ui.data.DataObject;

import oracle.jbo.domain.BlobDomain;

/**
 * Controller for ...
 */
public class XXODCustomerXrefUploadCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
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
      pageContext.writeDiagnostics(this, "XXODCustomerXrefUploadCO: processRequest Begin", 1);
      Serializable strReturn = (Serializable)pageContext.getParameter("rId");
      System.out.println("strReturn: " + strReturn);
      if (strReturn != null ) {
        webBean.findIndexedChildRecursive("UploadRegion").setRendered( false);
        webBean.findIndexedChildRecursive("ViewRequestsRegion").setRendered( true);
      } else {
        webBean.findIndexedChildRecursive("ViewRequestsRegion").setRendered( false);
      }
      pageContext.writeDiagnostics(this, "XXODCustomerXrefUploadCO: processRequest End", 1);
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
      pageContext.writeDiagnostics(this, "--In XXODCDHCustProfilesUploadCO, processFormRequest--", 1);
      String strFileName = null;
      String strLocalFileName = null;
      pageContext.writeDiagnostics(this, "PageContext.getParameter" + pageContext.getParameter("btnSubmit"), 1);
      Serializable[] param = null;
      HashMap hMap = null;

      DataObject fileUploadData = pageContext.getNamedDataObject("fileSelector");
      if (fileUploadData != null)
        strLocalFileName = (String)fileUploadData.selectValue(null, "UPLOAD_FILE_NAME");
      strFileName = strLocalFileName;
      pageContext.writeDiagnostics(this, "strFileName: " + strFileName, 1);
          
      if (pageContext.getParameter("btnSubmit") != null) 
      {
        pageContext.writeDiagnostics(this, "--On Button Submit--", 1);
        if (isCsvFile(strFileName)) {
          strFileName = doUpload( pageContext, webBean);
          param = new Serializable[4];
          param[0] = "" + pageContext.getUserId();
          param[1] = "" + pageContext.getResponsibilityId();
          param[2] = "" + pageContext.getResponsibilityApplicationId();
          param[3] = strFileName;

          strReturn = "";
          strReturn = pageContext.getApplicationModule(webBean).invokeMethod("runConcReqSet", param);
          pageContext.writeDiagnostics(this, "strReturn: " + strReturn, 1);

          hMap = new HashMap();
          hMap.put( "rId", strReturn);
        
        OAException msg1 = new OAException("The file " + strLocalFileName +
                " has been uploaded to the server successfully.", OAException.CONFIRMATION);
        pageContext.putDialogMessage(msg1);

        OAException msg2 = new OAException ("A Concurrent Request Set " +
        "is submitted to load the " +
        "Customer Profiles. \nThe Request Set Id is: " + strReturn + ".", OAException.INFORMATION);
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
      System.out.println("--In doUpload--");
      String LOG_DIR = "";

      //Get the temp directory path
      //framework.Logging.system.filename retrieves the TEMP path

      String logDir = System.getProperty("framework.Logging.system.filename");
      try
      {
        if (logDir != null && logDir.trim().length() >= 0)
        {
          int slash = Math.max(logDir.lastIndexOf('/'), logDir.lastIndexOf('\\'));
          LOG_DIR = logDir.substring(0, slash + 1);
        }
      }catch (Exception ex)
      {
        System.out.println(ex.getMessage());
        ex.printStackTrace();
        throw new OAException(ex.getMessage(),OAException.ERROR);
      }

      DataObject fileUploadData = pageContext.getNamedDataObject("fileSelector");
      String uFileName = null;
      uFileName = (String)fileUploadData.selectValue(null, "UPLOAD_FILE_NAME");
      System.out.println("uFileName: " + uFileName);
      String contentType = (String)fileUploadData.selectValue(null, "UPLOAD_FILE_MIME_TYPE");
      System.out.println("contentType: " + contentType);

      BlobDomain uploadedByteStream = (BlobDomain)fileUploadData.selectValue(null, uFileName);
      Reader reader = uploadedByteStream.getCharacterStream();

      String file_name = LOG_DIR + "uploadeFile" + pageContext.getUserId() + pageContext.getSessionId() + ".csv";
      System.out.println("file_name: " + file_name);
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
        System.out.println(ioe.getMessage());
        ioe.printStackTrace();
        throw new OAException(ioe.getMessage(), OAException.ERROR);
      }catch(Exception e)
      {
        System.out.println(e.getMessage());
        e.printStackTrace();
        throw new OAException(e.getMessage(), OAException.ERROR);
      }

      return file_name;
    }
    private boolean isCsvFile( String strFileName) 
    {
      System.out.println("--In isCsvFile--");
      boolean isCsv = false;

      String strTemp = "";
      strTemp = strFileName.substring(strFileName.lastIndexOf('.')+1, strFileName.length());
      System.out.println("strTemp: " + strTemp);
      if (strTemp.trim().equalsIgnoreCase("CSV"))
        isCsv = true;
      System.out.println("isCsv: " + isCsv);
      return isCsv;
    }  

}
