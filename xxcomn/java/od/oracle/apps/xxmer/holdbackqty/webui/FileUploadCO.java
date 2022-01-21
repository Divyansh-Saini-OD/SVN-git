/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxmer.holdbackqty.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
// import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

//
//import java.io.Serializable;
//import oracle.jbo.domain.Number;
 
//import oracle.cabo.ui.data.BoundValue;
//import oracle.cabo.ui.data.DictionaryData;
//import oracle.cabo.ui.data.DataObjectList;
//import oracle.cabo.ui.data.bind.ConcatBoundValue;
//import oracle.cabo.ui.data.bind.FixedBoundValue;
 
//import oracle.apps.fnd.common.MessageToken;
//import oracle.apps.fnd.common.VersionInfo;
 
import oracle.apps.fnd.framework.OAApplicationModule;

//
//import oracle.apps.fnd.framework.OAApplicationModule;
import java.io.Serializable;
import oracle.jbo.domain.BlobDomain;
import oracle.cabo.ui.data.DataObject;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.common.MessageToken;

//import oracle.apps.fnd.framework.OAException;
//import oracle.apps.fnd.framework.OAViewObject;
//import oracle.apps.fnd.framework.webui.OAControllerImpl;
//import oracle.apps.fnd.framework.webui.OADataBoundValueViewObject;
//import oracle.apps.fnd.framework.webui.OADialogPage;
//import oracle.apps.fnd.framework.webui.OAPageContext;
//import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
//import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
//import oracle.apps.fnd.framework.webui.beans.OAImageBean;
//import oracle.apps.fnd.framework.webui.beans.OAWebBean;
//import oracle.apps.fnd.framework.webui.beans.table.OATableBean;

//

/**
 * Controller for ...
 */
public class FileUploadCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    System.out.println("FileUploadCO: processRequest called");   
  
    super.processRequest(pageContext, webBean);

    if(!pageContext.isFormSubmission())
    	{
    	  OAApplicationModule am = pageContext.getApplicationModule(webBean);
    	  am.invokeMethod("initalizeUploadForm",null);
    	}
    System.out.println("FileUploadCO: processRequest exited");   

  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    System.out.println("FileUploadCO: processFormRequest called");   

    super.processFormRequest(pageContext, webBean);

    if(pageContext.getParameter("Apply") != null)
    	{          
    	  OAApplicationModule am = pageContext.getApplicationModule(webBean);

    	  //Retrieve object from pageContext to get FileName.
    	  DataObject fileUploadData = (DataObject)pageContext.getNamedDataObject("File");
    	  String fileName = (String)fileUploadData.selectValue(null, "UPLOAD_FILE_NAME");

    	  //reinitialize form
    	  am.invokeMethod("initalizeUploadForm",null); 

    	  //Test to make sure uploaded file has a CSV extension.  
        int index = fileName.indexOf(".");
    	  String fileExt = fileName.substring(index+1);
    	  if(!(fileExt.toUpperCase().equals("CSV")))
    	  {      
        		MessageToken[] tokens = {new MessageToken("TYPE",fileExt)};   
        		throw new OAException("XXMER","XXMER_VC_INVALID_FILETYPE",tokens);       
    	  }
	  
    	  String file = pageContext.getParameter("File");
    	  BlobDomain blobdomain = (BlobDomain)pageContext.getParameterObject(file);    
       
     	  //Serialize blob object for processing by the AM
    	  Serializable[] parameters = {blobdomain,fileName};      
    	  Class[] methodParamTypes = { blobdomain.getClass(),fileName.getClass() };
    	  Serializable countSerialized = 
        am.invokeMethod("processCSVFile",parameters,methodParamTypes);  
    	  String rowCount = (String)countSerialized;
      
     
    	  //Commit all added rows to table
    	  am.invokeMethod("apply");

    	  MessageToken[] tokens = {new MessageToken("ROWS",rowCount),
        new MessageToken("FILE",fileName)};  
    	  OAException confirmMessage = new OAException("XXMER",
                                            "XXMER_VC_FILEUPLOAD_CONFIRM",
                                            tokens,
                                            OAException.CONFIRMATION,		
                                            null);
    
    	  pageContext.putDialogMessage(confirmMessage);                                                
    	}    
    System.out.println("FileUploadCO: processFormRequest exited");   

  }

}
