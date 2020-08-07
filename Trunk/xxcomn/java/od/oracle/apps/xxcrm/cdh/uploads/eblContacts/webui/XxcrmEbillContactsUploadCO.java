/*===========================================================================+
 |   Copyright (c) 2001, 2003 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.cdh.uploads.eblContacts.webui;
/* Subversion Info:
 * $HeadURL: http://svn.na.odcorp.net/svn/od/common/trunk/xxcomn/java/od/oracle/apps/xxcrm/cdh/uploads/eblContacts/webui/XxcrmEbillContactsUploadCO.java $
 * $Rev: 189053 $
 * $Date: 2012-08-14 05:20:43 -0400 (Tue, 14 Aug 2012) $
*/
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import com.sun.java.util.collections.HashMap;
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
public class XxcrmEbillContactsUploadCO extends OAControllerImpl
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
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    ODUtil utl = new ODUtil(am);

    String strFileName = null;
    String strLocalFileName = null;
    utl.log(pageContext.getParameter(EVENT_PARAM));
    Serializable[] param = null;
    String fileName= null;

    String strFileUploadId = "";

    DataObject fileUploadData = pageContext.getNamedDataObject("fileSelector");
    OAMessageFileUploadBean fileUploadBean = (OAMessageFileUploadBean)webBean.findIndexedChildRecursive("fileSelector");
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
    if (pageContext.getParameter("btnSubmit") != null)
    {
      utl.log("Inside Upload click");
      if (str==null)
      {
        throw new OAException("Please select a file to upload", OAException.ERROR);
      }
      if (str !=null)
      {
      //utl.log("Inside s not null");
      if (isCsvFile(pageContext,webBean,strFileName))
      {
        strFileUploadId = doUpload( pageContext, webBean);

        HashMap hMap = new HashMap();
        hMap.put( "rId", strFileUploadId);

        OAException msg1 = new OAException("The file " + strLocalFileName +
              " has been uploaded to the server successfully. Please use the link above to go back to the EBill Main Page.", OAException.CONFIRMATION);
       pageContext.putDialogMessage(msg1);
        //OAViewObject mainVO = (OAViewObject) am.findViewObject("XxcrmEblContactsUploadVO");
        //mainVO.executeQuery();
        // fileUploadBean.setValue(pageContext,null);

       pageContext.forwardImmediatelyToCurrentPage(
                                   hMap
                                 , true
                                 , ADD_BREAD_CRUMB_YES );


      } // End of Is CSV
      else
      {
         throw new OAException ("Only CSV files are supported for uploads!");
      } // end of else
      }
    }// End of Upload Event
    if ("DownloadEblContact".equals(pageContext.getParameter(EVENT_PARAM) ) )
    {
      utl.log("Inside Download");

      /*
      param = new Serializable[5];
      param[0] = "" + pageContext.getUserId();
      param[1] = "" + pageContext.getResponsibilityId();
      param[2] = "" + pageContext.getResponsibilityApplicationId();
      param[3] = "" + custAccountId.intValue();
      param[4] = "" + custDocId.intValue();

      strFileUploadId = pageContext.getApplicationModule(webBean).invokeMethod("doDownloadContacts", param);
      */

      strFileUploadId = "3";
      OAViewObject clobVO = (OAViewObject) am.findViewObject("XxcrmEblContUploadsVO");
      clobVO.setWhereClause(null);
      clobVO.setWhereClause(" file_upload_id = " + strFileUploadId);
      clobVO.executeQuery();
      OARow row = (OARow) clobVO.first();
      utl.log("After First Row: strFileUploadId:" + strFileUploadId);
      ClobDomain b = null;

      while(row != null)
      {
        String fId = row.getAttribute("FileUploadId").toString() ;
       // utl.log("inside while: fId: " + fId);
        if(strFileUploadId.equals(fId))
        {
          utl.log("inside if");
          b = (ClobDomain)row.getAttribute("FileData");
          String fName =(String) row.getAttribute("FileName");
          pageContext.putSessionValue("fNameSessVal", fName);
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
        out.close();
      }

      catch (Exception e)
      {
        e.printStackTrace();
      }
	}


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
  public static String doUpload(OAPageContext pageContext, OAWebBean webBean)
  {
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    OAViewObject VO = (OAViewObject) am.findViewObject("XxcrmEblContUploadsVO");
    OADBTransaction transaction = am.getOADBTransaction();
    ODUtil utl = new ODUtil(am);
    VO.first(); // To create a new record at the first position
    OARow row = (OARow)VO.createRow();
    DataObject fileUploadData = pageContext.getNamedDataObject("fileSelector");
    String uFileName = null;
    uFileName = (String)fileUploadData.selectValue(null, "UPLOAD_FILE_NAME");
    utl.log("uFileName: " + uFileName);
    String contentType = (String)fileUploadData.selectValue(null, "UPLOAD_FILE_MIME_TYPE");
    utl.log("contentType: " + contentType);
    Number fileId = transaction.getSequenceValue("XXCRM.XXCRM_FILE_UPLOAD_ID_S");
    BlobDomain uploadedByteStream = (BlobDomain)fileUploadData.selectValue(null, uFileName) ;

    Number var = new Number(0);

    row.setAttribute("FileUploadId", fileId);
    row.setAttribute("FileName",uFileName);
    row.setAttribute("FileData",uploadedByteStream);
    row.setAttribute("FileStatus","P");
    row.setAttribute("FileContentType","application/vnd.ms-excel");
    row.setAttribute("Program","XXCRM-EBLContacts");
    //row.setAttribute("UserName",pageContext.getUserId());
    VO.insertRow(row);
    utl.log("Before Commit");
    am.getTransaction().commit();
    utl.log("After Commit");


    Serializable[] param = new Serializable[4];
    param[0] = "" + pageContext.getUserId();
    param[1] = "" + pageContext.getResponsibilityId();
    param[2] = "" + pageContext.getResponsibilityApplicationId();
    param[3] = "" + fileId.intValue();

    String strBatchId = "";
    strBatchId = (String)pageContext.getApplicationModule(webBean).invokeMethod("doUploadContacts", param);

    OAViewObject eblContStgVO = (OAViewObject)(pageContext.getApplicationModule(webBean).findViewObject("XxodCdhEblContactsStgVO"));
    eblContStgVO.setWhereClause(null);
    eblContStgVO.setWhereClause(" BATCH_ID = " + strBatchId);
    utl.log("XxodCdhEblContactsStgVO Query: " + eblContStgVO.getQuery());
    eblContStgVO.executeQuery();

    return strBatchId;

  } // End of doUpload

}
