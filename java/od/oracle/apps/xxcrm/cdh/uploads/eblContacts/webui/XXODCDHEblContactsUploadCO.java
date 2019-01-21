/*===========================================================================+
 |  Office Depot                                                             |
 +===========================================================================+
 |  HISTORY                                                                  |
 |  20-JUL-2012  Sreedhar Mohan     Initial Draft                            |
 +===========================================================================*/
package od.oracle.apps.xxcrm.cdh.uploads.eblContacts.webui;

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
import od.oracle.apps.xxcrm.cdh.ebl.server.ODUtil;
import oracle.apps.fnd.framework.OAViewObject;
/**
 * Controller for Ebl Contacts Upload
 */
public class XXODCDHEblContactsUploadCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header: MistcaUploadCO.java 115.3 2006/06/13 12:54:12 ssmohan noship $";
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

    ODUtil utl = new ODUtil(pageContext.getApplicationModule(webBean));
    utl.log("Inside processRequest of eBlUploadCO");

    Serializable[] param = null;
    param =  new Serializable[1];
    String strBatchId = (String)pageContext.getParameter("rId");

    param[0] = "" + (String)pageContext.getParameter("rId");
    if (strBatchId!= null ) {
      webBean.findIndexedChildRecursive("UploadRegion").setRendered( false);
      //pageContext.getApplicationModule(webBean).invokeMethod("executeQuery", param);

       OAViewObject eblContStgVO = (OAViewObject)(pageContext.getApplicationModule(webBean).findViewObject("XxodCdhEblContactsStgVO"));
       eblContStgVO.setWhereClause(null);
       eblContStgVO.setWhereClause(" BATCH_ID = " + strBatchId);
       utl.log("XxodCdhEblContactsStgVO Query: " + eblContStgVO.getQuery());
       eblContStgVO.executeQuery();

      webBean.findIndexedChildRecursive("UploadEblContResults").setRendered( true);
    } else {
      webBean.findIndexedChildRecursive("UploadEblContResults").setRendered( false);
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
    ODUtil utl = new ODUtil(pageContext.getApplicationModule(webBean));
    utl.log("Inside processFormRequest of eBlUploadCO");

    String strFileName = null;
    String strLocalFileName = null;
    Serializable[] param = null;
    Serializable[] param1 = null;
    HashMap hMap = null;

    DataObject fileUploadData = pageContext.getNamedDataObject("fileSelector");
    if (fileUploadData != null)
      strLocalFileName = (String)fileUploadData.selectValue(null, "UPLOAD_FILE_NAME");
    strFileName = strLocalFileName;

    if (pageContext.getParameter("btnSubmit") != null)
    {
      if (isCsvFile(strFileName)) {
        strFileName = doUpload( pageContext, webBean);
        param = new Serializable[4];
        param[0] = "" + pageContext.getUserId();
        param[1] = "" + pageContext.getResponsibilityId();
        param[2] = "" + pageContext.getResponsibilityApplicationId();
        param[3] = strFileName;

        strReturn = "";
        strReturn = pageContext.getApplicationModule(webBean).invokeMethod("runConcReqSet", param);

        hMap = new HashMap();
        hMap.put( "rId", strReturn);

        OAException msg1 = new OAException("The file " + strLocalFileName +
              " has been uploaded to the server successfully. Please use the link above to go back to the EBill Main Page.", OAException.CONFIRMATION);
       pageContext.putDialogMessage(msg1);

       /*
       param1 = new Serializable[1];
       param1[0] = strReturn;
       if (strReturn!= null )
         pageContext.getApplicationModule(webBean).invokeMethod("executeQuery", param1);
       */
       OAViewObject eblContStgVO = (OAViewObject)(pageContext.getApplicationModule(webBean).findViewObject("XxodCdhEblContactsStgVO"));
       eblContStgVO.setWhereClause(null);
       eblContStgVO.setWhereClause(" BATCH_ID = " + strReturn);
       utl.log("XxodCdhEblContactsStgVO Query: " + eblContStgVO.getQuery());
       eblContStgVO.executeQuery();

       pageContext.forwardImmediatelyToCurrentPage(
                                   hMap
                                 , true
                                 , ADD_BREAD_CRUMB_YES );

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
                                       ADD_BREAD_CRUMB_YES,
                                       IGNORE_MESSAGES);
    }
  }

  public static String doUpload(OAPageContext pageContext, OAWebBean webBean)
  {
    String LOG_DIR = "";

    //Get the temp directory path
    //framework.Logging.system.filename retrieves the TEMP path

    //String logDir = System.getProperty("framework.Logging.system.filename");
    String logDir = pageContext.getProfile("XX_UTL_FILE_OUT_DIR");

    DataObject fileUploadData = pageContext.getNamedDataObject("fileSelector");
    String uFileName = null;
    uFileName = (String)fileUploadData.selectValue(null, "UPLOAD_FILE_NAME");
    String contentType = (String)fileUploadData.selectValue(null, "UPLOAD_FILE_MIME_TYPE");

    BlobDomain uploadedByteStream = (BlobDomain)fileUploadData.selectValue(null, uFileName);
    Reader reader = uploadedByteStream.getCharacterStream();

    String file_name = logDir + "/upldEblCntFile" + pageContext.getUserId() + pageContext.getSessionId() + pageContext.getCurrentDBDate().getTime() + ".csv";

    //String file_name = LOG_DIR + "upldEblCntFile" + pageContext.getUserId() + pageContext.getSessionId() + ".csv";
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


