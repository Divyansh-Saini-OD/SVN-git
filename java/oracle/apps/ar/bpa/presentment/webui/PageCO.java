  /*===========================================================================+
 |      Copyright (c) 2001, 2014 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 |       06-Jun-02  lishao      Created.                                     |
 |       28-Apr-03  lishao      Use OAWebBeanConstants alignment constants   |
 |                              to replace BPA defined constants.            | 
 +===========================================================================*/
package oracle.apps.ar.bpa.presentment.webui;
/*----------------------------------------------------------------------------
 -- Author: Sridevi Kondoju
 -- Component Id: E1293
 -- Script Location: $CUSTOM_JAVA_TOP/oracle/apps/ar/bpa/presentment/webui
 -- Description: Considered R12 code version and added custom code.
 -- History:
 -- Name            Date         Version    Description
 -- -----           -----        -------    -----------
 -- Sridevi Kondoju 10-Sep-2013  1.0        Retrofitted for R12 Upgrade.
 -- Vasu Raparla    17-Aug_2016  1.1        Retrofitted for R12.2.5 Upgrade.
 -- Madhu Bolli     10-Mar-2017  1.2        Defect#41197 - Invoice PDFCopy returns and
 --                                      navigates to ViewRequests if it submits concurrent request 
 --                                      and does not wait for request
 -- Madhu Bolli     21-Apr-2017  1.3       Invoice PDF Copy - Refresh Functionality
---------------------------------------------------------------------------*/

import com.sun.java.util.collections.HashMap;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.Serializable;
import java.util.Hashtable;
import java.util.Vector;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServletResponse;
import oracle.apps.ar.bpa.presentment.util.DataSource;
import oracle.apps.ar.bpa.presentment.util.DataSrcParam;
import oracle.apps.ar.bpa.presentment.util.InvoiceXMLBuilder;
import oracle.apps.ar.bpa.templatemgmt.templates.server.TemplateStylesheetBuilder;
import oracle.apps.ar.bpa.util.Constants;
import oracle.apps.ar.bpa.util.Utilities;
import oracle.apps.ar.bpa.util.AppRoutines;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.common.MessageToken; 
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.OANLSServices;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OACellFormatBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OARowLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OASpacerCellBean;
import oracle.apps.fnd.framework.webui.beans.layout.OASpacerRowBean;
import oracle.apps.fnd.framework.webui.beans.layout.OATableLayoutBean;
import oracle.apps.fnd.framework.webui.beans.nav.OABreadCrumbsBean;
import oracle.apps.xdo.template.FOProcessor;
import oracle.apps.xdo.template.FormProcessor;
import oracle.apps.xdo.template.RTFProcessor;
import oracle.cabo.ui.TextNode;
import oracle.cabo.ui.beans.nav.GlobalButtonBarBean;
import oracle.cabo.ui.data.DataObject;
import oracle.jbo.Row;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.BlobDomain;
import oracle.xml.parser.v2.XMLDocument;
import oracle.apps.fnd.framework.server.OADBTransaction;
import java.util.Properties;
import oracle.jdbc.OraclePreparedStatement;
import oracle.apps.xdo.common.pdf.util.PDFDocMerger;
import java.util.ArrayList;
//import oracle.apps.ar.bpa.presentment.util.InvoiceXMLHelper;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;
/*
 * This controller programmatically creates the layout components and
 * adds the children region items, instead of relying on the declarative
 * approach.
 */
public class PageCO extends BpaControllerImpl implements Constants
{

  public static final String RCS_ID="$Header: PageCO.java 120.11.12020000.6 2014/07/01 20:05:44 rravikir ship $";
  public static final boolean RCS_ID_RECORDED =
       VersionInfo.recordClassVersion(RCS_ID, "oracle.apps.ar.bpa.presentment.webui");

  private void showPdf(OAPageContext pageContext, OAWebBean webBean, int priAppId)
  {
    OAApplicationModule am = pageContext.getApplicationModule(webBean);

    // 1. Extract Parameters from the url
    String templateId = pageContext.getParameter("templateId");
    String templateType = pageContext.getParameter("templateType");        //only used when template id is passed

    // 2. Call Assignment Engine if template id is not passed. 
    //Initialize the primary data source hashmap and primary header data source
    HashMap priAppDataSrcList = new HashMap();   //the primary application data source list.
    Object priAppDataSrcObj = pageContext.getTransactionTransientValue("PRI_DATASOURCE");
    Object cachedPriAppObj = pageContext.getTransactionValue("PRI_APP_ID");
    pageContext.putTransactionValue("PRI_APP_ID", String.valueOf(priAppId));    

    if (priAppDataSrcObj == null) 
    {
      //initPriAppDataSource(pageContext, webBean, priAppDataSrcList, 222);      
      initPriAppDataSource(pageContext, webBean, priAppDataSrcList, priAppId); //remove the hardcoded priAppId
      pageContext.putTransactionTransientValue("PRI_DATASOURCE", priAppDataSrcList);
    }
    else
    {
      int cachedPriAppId = Integer.parseInt((String)cachedPriAppObj);        
      if (priAppId != cachedPriAppId)
      {
        initPriAppDataSource(pageContext, webBean, priAppDataSrcList, priAppId); //remove the hardcoded priAppId
        pageContext.putTransactionTransientValue("PRI_DATASOURCE", priAppDataSrcList);                
      }              
      else  priAppDataSrcList = (HashMap)priAppDataSrcObj;      
    }

    DataSource headerDataSource = (DataSource)priAppDataSrcList.get(FIRST_HEADER);
    OAViewObject vo = getHeaderViewObject(pageContext, webBean, headerDataSource); 

    if (isNullString(templateId))
    {    
       templateId = assignmentEngine(pageContext,webBean, vo.first(), priAppId);
        if (templateId == null)
        {
          if (pageContext.isLoggingEnabled(OAFwkConstants.ERROR))
            pageContext.writeDiagnostics(this, "Error in getting Template for document: " + 
                    Utilities.getRowValue(vo.first(), "TrxNumber"), OAFwkConstants.ERROR);       
          return;
        }       
       OAViewObject templateVo = (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("TemplatesVO");
       templateVo.setWhereClauseParam(0, templateId);
       templateVo.executeQuery();  
       Row row = templateVo.next(); 
       if (row != null) {
         String type  = (String)row.getAttribute("TemplateType");
         templateType = ( type == null )? "XSLFO": type.toUpperCase();       
       }
    }
    
    int intTemplateId = Integer.parseInt(templateId);    
    String cachedTemplateId = (String)pageContext.getTransactionValue("TEMPLATE_ID");
    pageContext.putTransactionValue("TEMPLATE_ID",templateId);     
    if (cachedTemplateId == null || ! cachedTemplateId.equals(templateId) )
      pageContext.putTransactionValue("TMPLT_CHANGED","Y");
    else
      pageContext.putTransactionValue("TMPLT_CHANGED","N");     
    
    // 3. Extract the template file
    ByteArrayInputStream insTemplate = (ByteArrayInputStream)pageContext.getTransactionTransientValue("sTemplate");
    try
    {     
    if ( insTemplate == null || "Y".equals(pageContext.getTransactionValue("TMPLT_CHANGED")))
    {
       OAViewObjectImpl filesVo = (OAViewObjectImpl)am.findViewObject("TemplateFilesVO");
       filesVo.setWhereClauseParam(0,new Number(intTemplateId));
       filesVo.executeQuery();
       if ( filesVo.next() != null )
       {
          Row filesRow = (Row) filesVo.getCurrentRow();
          BlobDomain fileData = (BlobDomain)filesRow.getAttribute("FileData");
          insTemplate= new ByteArrayInputStream(fileData.toByteArray());
            
          if ( "RTF".equals(templateType) )
          {
             RTFProcessor rtfProcessor = new RTFProcessor(insTemplate);
             ByteArrayOutputStream bOutTmplt = new ByteArrayOutputStream();                    
             rtfProcessor.setOutput(bOutTmplt);   
             rtfProcessor.process();
             insTemplate = new ByteArrayInputStream(bOutTmplt.toByteArray());               
          } 
       }
       else
       {
            if ( !"XSLFO".equals(templateType) )
            {
              throw new OAException("AR", "AR_BPA_PREVIEW_NO_TMPLT_FILE");
            }

            OAApplicationModule rootAM = pageContext.getRootApplicationModule();
            TemplateStylesheetBuilder builder = new TemplateStylesheetBuilder(rootAM, templateId);
            XMLDocument xslDoc = builder.getXSL(rootAM);
            ByteArrayOutputStream bOutTmplt = new ByteArrayOutputStream();     
            xslDoc.print(bOutTmplt, "UTF-8");
            insTemplate = new ByteArrayInputStream(bOutTmplt.toByteArray());
        }
        pageContext.putTransactionTransientValue("sTemplate",insTemplate);
     }
     else
        insTemplate.reset();
    }
    catch(Exception e)
    {
        if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
           pageContext.writeDiagnostics(this, "Error Generating Stylesheet", OAFwkConstants.PROCEDURE); 
        Exception[] error = { e };
        throw  new OAException("AR",
          "AR_BPA_TM_PRINT_PREVIEW_ERR" ,null,OAException.SEVERE, error);
    }
        
    // 4. Build the invoice xml  
    ByteArrayInputStream bXml = null;
    try
    {
         InvoiceXMLBuilder xmlBuilder = new InvoiceXMLBuilder(am);
         XMLDocument xmlDoc = xmlBuilder.getXML(pageContext, webBean, templateId);
         ByteArrayOutputStream bOutXml = new ByteArrayOutputStream();
         xmlDoc.print(bOutXml, "UTF-8");
         bXml = new ByteArrayInputStream(bOutXml.toByteArray());
    }
    catch(Exception e)
    {
        if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
           pageContext.writeDiagnostics(this, "Error Generating Invoice XML", OAFwkConstants.PROCEDURE); 
        Exception[] error = { e };
        throw new OAException("AR",
          "AR_BPA_TM_PRINT_PREVIEW_ERR" ,null,OAException.SEVERE, error);
    }
           
    // 5. Call the XML Publisher API to generate the PDF.
    String oaMedia = (String)pageContext.getTransactionTransientValue("OA_MEDIA_VALUE");
    if ( oaMedia == null )
    {
     oaMedia = ((OADBTransaction)am.getTransaction()).getProfile("APPS_FRAMEWORK_AGENT"); 
     if (oaMedia.endsWith("/") == false) 
        oaMedia += "/"; 
     oaMedia += "OA_MEDIA";
    }
    Properties pr = new Properties(); 
    pr.put("user-variable.OA_MEDIA", oaMedia);

    ServletOutputStream os = null;
    try
    {
       // Get a handle to the HttpResponse Object 
       DataObject sessionDictionary = 
              (DataObject)pageContext.getNamedDataObject("_SessionParameters");    
       HttpServletResponse response = 
              (HttpServletResponse)sessionDictionary.selectValue(null,"HttpServletResponse");  
 
       os = response.getOutputStream();
       response.resetBuffer();
       response.setContentType("application/pdf");
       //ByteArrayOutputStream[] apdf = null;
       ArrayList<ByteArrayInputStream> list = null;
       ByteArrayOutputStream bpdf = new ByteArrayOutputStream();
       if (!"PDF".equals(templateType) )
       {
          FOProcessor processor = new FOProcessor();
          processor.setData(bXml);     // set XML input file
          processor.setTemplate(insTemplate); // set XSL input file
          processor.setOutput(bpdf);  //set (PDF) output file
          processor.setOutputFormat(FOProcessor.FORMAT_PDF);
          processor.setConfig(pr);
          processor.generate();
       }
       else 
       {
          FormProcessor fProcessor = new FormProcessor();
          fProcessor.setTemplate(insTemplate);        // Input File (PDF) name
          fProcessor.setData(bXml);
          fProcessor.setOutput(bpdf);
          if ( !fProcessor.process() )
          {
            throw new OAException("AR","AR_BPA_TM_PRINT_PREVIEW_ERR");
          }
       }
       
       list = getAttachPdfs(pageContext,webBean , am, priAppId, templateId);
       if(list != null && list.size() > 0){
    	   ByteArrayInputStream[] inputPdfs = new ByteArrayInputStream[list.size()+1];
    	   inputPdfs[0] = new ByteArrayInputStream(bpdf.toByteArray());
    	   for(int loopVariable = 0; loopVariable < list.size(); loopVariable++){
    		   inputPdfs[loopVariable+1] = list.get(loopVariable);
    	   }
    	   bpdf = new ByteArrayOutputStream();
    	   PDFDocMerger docMerger = new PDFDocMerger(inputPdfs,bpdf);
    	   docMerger.process();
       }
       
      if ( "Y".equals(pageContext.getParameter("UpdatePrintFlag")))
        AppRoutines.stampDocument(pageContext, (OADBTransaction)am.getTransaction(), vo.first(), priAppId);
       
      response.setContentLength(bpdf.size());
      os.write(bpdf.toByteArray(), 0, bpdf.size());
      // restore content type to original....else html rendered by cabo will get downloaded!!
      // response.setContentType("text/html");
      os.flush();
      os.close();
    }
    catch (Exception e)
    {
      if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
         pageContext.writeDiagnostics(this, "Error Generating Pdf", OAFwkConstants.PROCEDURE); 
      Exception[] error = { e };
      throw new OAException("AR",
        "AR_BPA_TM_PRINT_PREVIEW_ERR" ,null,OAException.SEVERE, error);
    }
    finally
    {
      if ( os != null)
      {
        try { os.close(); } catch(Exception e) {}
      }
    }
 } //showPdf
  
  public ArrayList getAttachPdfs(OAPageContext pageContext, OAWebBean webBean, OAApplicationModule am, int priAppId, String templateId){
	  String attachDocCatId = ((OADBTransaction)am.getTransaction()).getProfile("AR_BPA_PRINT_ATTACH_CATEGORY");
      boolean attachPrintFlag = ((null == attachDocCatId) || ("".equals(attachDocCatId.trim()))) ? false : true;
       //boolean attachPrintFlag = true;
      if( !attachPrintFlag ){
    	  return null;
      }
      //ByteArrayOutputStream[] apdf = new ByteArrayOutputStream[10];
      String custTrxid =(String) pageContext.getParameter("CustomerTrxId");
      ArrayList<ByteArrayInputStream> list = new ArrayList<ByteArrayInputStream>();
	  OAViewObject filesVo = null;    
	    if (priAppId == AR) {
	      filesVo = (OAViewObject)am.findViewObject("AttachLobFilesVO");
	      if (filesVo == null) {
	        filesVo = (OAViewObject)am.createViewObject("AttachLobFilesVO", 
	                                         "oracle.apps.ar.bpa.presentment.server.AttachLobFilesVO");        
	      }      
	    }
      try{
	    if ((priAppId == AR) && attachPrintFlag) {
            filesVo.setWhereClauseParams(null);
            filesVo.setWhereClauseParam(0,new Number(custTrxid));        
            filesVo.setWhereClauseParam(1,new Number(attachDocCatId));
            filesVo.executeQuery();   
            for ( Row fileRow = filesVo.first(); fileRow != null; fileRow = filesVo.next())
            {
            	 OAViewObject filesDataVo = (OAViewObject)am.findViewObject("AttachLobFileDataVO");
                if ( filesDataVo == null)
                {
                  filesDataVo = (OAViewObject)am.createViewObject("AttachLobFileDataVO", 
                                                   "oracle.apps.ar.bpa.presentment.server.AttachLobFileDataVO"); 
                }
              //filesDataVo.setWhereClauseParams(null);
              filesDataVo.setWhereClauseParam(0,(Number)fileRow.getAttribute(0));
              //filesDataVo.setWhereClauseParam(0,new Number(1395629));        
              filesDataVo.executeQuery();  
              Row filesDataRow = filesDataVo.first();
              BlobDomain fileData = (BlobDomain)filesDataRow.getAttribute("FileData");
              ByteArrayInputStream bpdf  = new ByteArrayInputStream(fileData.toByteArray());
              list.add(bpdf);      
            }
          } 
      } catch(Exception e)
      {
        
      }
	    return list;
  }

  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
      //Added for R12 upgrade retrofit
  if (showODInvoice(pageContext, webBean)) {
      pageContext.writeDiagnostics(this, "PageCO.PR() - aftershowODInvoice", OAFwkConstants.PROCEDURE);
      return; 
  } // Added for Office Depot to display invoices in custom way 
  else 
  {
    pageContext.writeDiagnostics(this, "PageCO.PR() - aftershowODInvoice returns false", OAFwkConstants.PROCEDURE);
  }

    OAPageLayoutBean pageLayoutBean = pageContext.getPageLayoutBean();  
    String viewType = pageContext.getParameter("ViewType");
    String retainBN = pageContext.getParameter("retainBN");    //if we need to keep the global button.
    int priAppId = AR;
    if (pageContext.getParameter("PriAppId") != null)
      priAppId = Integer.parseInt(pageContext.getParameter("PriAppId"));    //identify the primary id to support BF and future document types.
    //int secAppId = Integer.parseInt(row2.getAttribute(0).toString());      convert to int if necessary
    
    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE)){
    	pageContext.writeDiagnostics(this, "View Type :"+viewType+", retainBN :"+retainBN, OAFwkConstants.PROCEDURE);
    }
    
    //Bug 4003780
    if (!("MULTIPRINT".equals(viewType)))
    {
      if (!("Y".equals(retainBN))) //iRec bug 4226775
      {
        GlobalButtonBarBean barBean = (GlobalButtonBarBean)pageLayoutBean.getGlobalButtons();           
        if ( barBean != null )
        {
          barBean.clearIndexedChildren();
          pageLayoutBean.setCopyright(new TextNode(""));
          pageLayoutBean.setPrivacy(null);    
          pageLayoutBean.setCorporateBranding(null); 
          pageLayoutBean.setProductBranding(null);
        }        
      }
    }

    if ( viewType != null && viewType.equals("PRINT"))
    {
        showPdf(pageContext,webBean, priAppId);
    }
    else if (viewType != null && viewType.equals("MULTIPRINT"))
    {
        String requestId = pageContext.getParameter("requestId");
        showPdfMultiInv(pageContext,webBean,requestId, priAppId);
    }
    else
    {
        prepareData(pageContext, webBean, priAppId);
        String previewFlag = pageContext.getParameter("preview");
        //If you are previewing the transaction for the first page, it will truncate the original breadcrumb.
        //It will not break the breadcrumb when you drilldown to furthur level
        if ("Y".equals(previewFlag))    
        {
           String dispLevel = pageContext.getParameter("dispLevel");
           if ( isNullString(dispLevel))
           {
              // pageContext.getPageLayoutBean().setBreadCrumbEnabled(false);
              OABreadCrumbsBean breadCrumbBean = (OABreadCrumbsBean) pageContext.getPageLayoutBean().getBreadCrumbsLocator();
              if ( breadCrumbBean != null )
              {
                  String firstLink = breadCrumbBean.getFirstLinkDestination();
                  if ( firstLink != null && (firstLink.lastIndexOf("TmInterPreviewPG") != -1 ||
                         firstLink.lastIndexOf("MainPG") != -1 || firstLink.lastIndexOf("ChooseContextPG") != -1) )
                       breadCrumbBean.removeLink(pageContext,0); 
              }
           }      
      }
    }
  }

  private OAWebBean generateWebBean(OAPageContext pageContext, OAWebBean root, OAWebBean webBean, OAViewObject viewObject, int flag)
  {
    OAWebBean bean = null;  
    OAWebBean spacer = createSpacerBean(pageContext, 0, 1);    
    Row row = viewObject.next(); 
    if (row != null) 
    {
      Object layoutStyle = row.getAttribute(PB_CONTENT_ORIENTATION);
      int style = (layoutStyle == null || "".equals(layoutStyle))? NO_STYLE : Integer.parseInt(layoutStyle.toString());       
      int childCount = Integer.parseInt(row.getAttribute(PB_CONTENT_COUNT).toString());            
      int dispSeq = Integer.parseInt(row.getAttribute(PB_CONTENT_DISPLAY_SEQUENCE).toString());                  
      String sWidth = (String)row.getAttribute(PB_CONTENT_AREA_WIDTH);   
      
      switch (style) {
        case ROOT:        
          bean = (OATableLayoutBean)createTableLayoutBean(pageContext);
          for (int k=0; k<childCount; k++) {
            bean.addIndexedChild(spacer);
          }          
          for (int i=0; i<childCount; i++) {
            Row nextRow = viewObject.next(); 
            int newDispSeq = Integer.parseInt(nextRow.getAttribute(PB_CONTENT_DISPLAY_SEQUENCE).toString());
            if (newDispSeq == TEMPLATE_BODY) {
              OARowLayoutBean vRow = (OARowLayoutBean)createWebBean(pageContext, ROW_LAYOUT_BEAN, null, null);
              bean.replaceIndexedChild(newDispSeq-1, vRow);   
//              vRow.addIndexedChild(createWebBean(pageContext, STACK_LAYOUT_BEAN, null, "BodyBean"));              
              vRow.addIndexedChild(generateAreaBean(pageContext, root, viewObject, nextRow, childCount, true));
            }
            else {
              OARowLayoutBean vRow = (OARowLayoutBean)createWebBean(pageContext, ROW_LAYOUT_BEAN, null, null);            
              bean.replaceIndexedChild(newDispSeq-1, vRow);   
              viewObject.previous();              
              generateWebBean(pageContext, root, vRow, viewObject, NEED_CELL_FORMAT_BEAN);
            }            
          }
          break;
        case VER:  
          bean = (OATableLayoutBean)createTableLayoutBean(pageContext);
          for (int k=0; k<childCount; k++) {
            bean.addIndexedChild(spacer);
          }
          for (int i=0; i<childCount; i++) {
            OARowLayoutBean vRow = (OARowLayoutBean)createWebBean(pageContext, ROW_LAYOUT_BEAN, null, null);
            Row nextRow = viewObject.next(); 
            int newDispSeq = Integer.parseInt(nextRow.getAttribute(PB_CONTENT_DISPLAY_SEQUENCE).toString());                              
            bean.replaceIndexedChild(newDispSeq-1, vRow);   
            viewObject.previous();
            generateWebBean(pageContext, root, vRow, viewObject, NEED_CELL_FORMAT_BEAN);
          }
          break;
        case HOR: 
          bean = (OATableLayoutBean)createTableLayoutBean(pageContext);
          OARowLayoutBean hRow = (OARowLayoutBean)createWebBean(pageContext, ROW_LAYOUT_BEAN, null, null);                          
          bean.addIndexedChild(hRow);
          for (int k=0; k<childCount; k++) {
            hRow.addIndexedChild(spacer);
          }          
          for (int j=0; j<childCount; j++) {
            generateWebBean(pageContext, root, hRow, viewObject, NEED_INDEX_CELL_FORMAT_BEAN);
          }
          break;
        case NO_STYLE: 
          //it only make sense to add the label to the leaf node and count > 0, as well as left, right, top, bottom space.
          if (childCount != 0)
            bean = generateAreaBean(pageContext, root, viewObject, row, childCount, false);
          else
            bean = createSpacerBean(pageContext, 0, 1);   //create a spacer bean if count==0 should add the width.
          break;
      }
      if (flag == NEED_INDEX_CELL_FORMAT_BEAN) {
        OACellFormatBean cellBean = createCellBean(pageContext, sWidth, OAWebBeanConstants.H_ALIGN_START, OAWebBeanConstants.V_ALIGN_TOP, null);
        cellBean.addIndexedChild(bean);
        webBean.replaceIndexedChild(dispSeq-1, cellBean);                        
      }
      else if (flag == NEED_CELL_FORMAT_BEAN) {
        OACellFormatBean cellBean = createCellBean(pageContext, sWidth, OAWebBeanConstants.H_ALIGN_START, OAWebBeanConstants.V_ALIGN_TOP, null);
        cellBean.addIndexedChild(bean);
        webBean.addIndexedChild(cellBean);                        
      }      
      else {
        webBean.addIndexedChild(bean);
      }      
    }
    return webBean;     //return the top rootBean
  }

  //generate the Area Bean
  private OAWebBean generateAreaBean(OAPageContext pageContext, OAWebBean root, OAViewObject viewObject, Row row, int childCount, boolean genBodyBeanFlag)
  {
    OAWebBean bean = null;     
    Object top = row.getAttribute(PB_CONTENT_AREA_TOP_SPACE);
    int topHeight = (top == null || "".equals(top))? BPA_ZERO : Integer.parseInt(top.toString());                 
    Object bottom = row.getAttribute(PB_CONTENT_AREA_BOTTOM_SPACE);
    int bottomHeight = (bottom == null || "".equals(bottom))? BPA_ZERO : Integer.parseInt(bottom.toString());                 
    if (topHeight == 0 && bottomHeight == 0)
      bean = generateNodeBean(pageContext, root, viewObject, row, childCount, genBodyBeanFlag);              
    else {
      bean = createTableLayoutBean(pageContext);                                                                      
      if (topHeight != 0) {
        OASpacerRowBean spacerRowBean1 = (OASpacerRowBean)createWebBean(pageContext, SPACER_ROW_BEAN, null, null);
        spacerRowBean1.setCellHeight(String.valueOf(topHeight));
        bean.addIndexedChild(spacerRowBean1);
      }            
      OARowLayoutBean rowBean2 = (OARowLayoutBean)createWebBean(pageContext, ROW_LAYOUT_BEAN, null, null);                                        
      bean.addIndexedChild(rowBean2);
      rowBean2.addIndexedChild(generateNodeBean(pageContext, root, viewObject, row, childCount, genBodyBeanFlag));              
      if (bottomHeight != 0) {
        OASpacerRowBean spacerRowBean3 = (OASpacerRowBean)createWebBean(pageContext, SPACER_ROW_BEAN, null, null);
        spacerRowBean3.setCellHeight(String.valueOf(bottomHeight));
        bean.addIndexedChild(spacerRowBean3);
      }            
    }  
    return bean;
  }
  
  //generate the leaf node bean
  private OAWebBean generateLeafNodeBean(OAPageContext pageContext, OAWebBean root, OAViewObject viewObject, Row row, int childCount, boolean genBodyBeanFlag)
  {
    OAWebBean bean = null;
    Object itemLayoutStyle = row.getAttribute(PB_CONTENT_STYLE_ID);
    int itemStyle = (itemLayoutStyle == null || "".equals(itemLayoutStyle))? NO_STYLE : Integer.parseInt(itemLayoutStyle.toString());       
    String  displayLabel = (String)row.getAttribute(PB_CONTENT_DISPLAY_PROMPT);                    
    String  dispLabelStyle = (String)row.getAttribute(PB_CONTENT_DISP_PROMPT_STYLE);                        

    if (displayLabel != null && !"".equals(displayLabel)) {
      bean = createTableLayoutBean(pageContext);        
      OARowLayoutBean rowBean1 = (OARowLayoutBean)createWebBean(pageContext, ROW_LAYOUT_BEAN, null, null);
      if (isNullString(dispLabelStyle) || REGULAR.equals(dispLabelStyle))
        rowBean1.addIndexedChild(createLblBean(pageContext, displayLabel, ORA_FIELD_TEXT));        
      else 
        rowBean1.addIndexedChild(createLblBean(pageContext, displayLabel, ORA_DATA_TEXT));              
      OARowLayoutBean rowBean2 = (OARowLayoutBean)createWebBean(pageContext, ROW_LAYOUT_BEAN, null, null);
      if (genBodyBeanFlag)
        rowBean2.addIndexedChild(createWebBean(pageContext, STACK_LAYOUT_BEAN, null, "BodyBean"));      
      else
        rowBean2.addIndexedChild(getStyleBean(pageContext, root, viewObject, childCount, itemStyle));                    
      bean.addIndexedChild(rowBean1);
      bean.addIndexedChild(rowBean2);              
    } 
    else 
    {
      if (genBodyBeanFlag)
        bean = (OAWebBean)createWebBean(pageContext, STACK_LAYOUT_BEAN, null, "BodyBean");      
      else
        bean = getStyleBean(pageContext, root, viewObject, childCount, itemStyle);
    }
    return bean;
  }

  //generate the node bean with left width and right width
  private OAWebBean generateNodeBean(OAPageContext pageContext, OAWebBean root, OAViewObject viewObject, Row row, int childCount, boolean genBodyBeanFlag)
  {
    OAWebBean bean = null;
    Object left = row.getAttribute(PB_CONTENT_AREA_LEFT_SPACE);
    int leftWidth = (left == null || "".equals(left))? BPA_ZERO : Integer.parseInt(left.toString());                 
    Object right = row.getAttribute(PB_CONTENT_AREA_RIGHT_SPACE);
    int rightWidth = (right == null || "".equals(right))? BPA_ZERO : Integer.parseInt(right.toString());                 
    if (leftWidth ==0 && rightWidth == 0)
      bean = generateLeafNodeBean(pageContext, root, viewObject, row, childCount, genBodyBeanFlag);
    else {
      bean = (OATableLayoutBean)createTableLayoutBean(pageContext);                                                          
      OARowLayoutBean rowBean = (OARowLayoutBean)createWebBean(pageContext, ROW_LAYOUT_BEAN, null, null);              
      bean.addIndexedChild(rowBean);
      //2.1 check the leftWidth column
      if (leftWidth != 0) {
        OASpacerCellBean spacerCellBean1 = (OASpacerCellBean)createWebBean(pageContext, SPACER_CELL_BEAN, null, null);
        spacerCellBean1.setWidth(String.valueOf(leftWidth));
        rowBean.addIndexedChild(spacerCellBean1);
      }
      //2.2 check the label and add the main node  don't set the width for the leaf node, don't know the width at all.
      OACellFormatBean cellBean2 = (OACellFormatBean)createWebBean(pageContext, CELL_FORMAT_BEAN, null, null);
      cellBean2.setHAlign(OAWebBeanConstants.H_ALIGN_START);
      cellBean2.setVAlign(OAWebBeanConstants.V_ALIGN_TOP);      
      OAWebBean nodeBean = generateLeafNodeBean(pageContext, root, viewObject, row, childCount, genBodyBeanFlag);
      cellBean2.addIndexedChild(nodeBean);
      rowBean.addIndexedChild(cellBean2);
      //2.3 check the rightWidth column     
      if (rightWidth != 0) {
        OASpacerCellBean spacerCellBean3 = (OASpacerCellBean)createWebBean(pageContext, SPACER_CELL_BEAN, null, null);
        spacerCellBean3.setWidth(String.valueOf(rightWidth));
        rowBean.addIndexedChild(spacerCellBean3);
      }              
    }
    return bean;
  }  

  private void prepareData(OAPageContext pageContext, OAWebBean webBean, int priAppId)
  {
    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this, "prepareData()+", OAFwkConstants.PROCEDURE); 

    //0. prepare the basic presentment information.
    OANLSServices nls = pageContext.getOANLSServices();
      
    //the value will be availabel only if it is not the first page.
    String dispLevel = pageContext.getParameter("dispLevel");    
    //the value will be available only if there are lineTypes and it is not the first page.
    String lineType  = pageContext.getParameter("lineType");     
    
    boolean isFirstPage = isNullString(dispLevel); 
    pageContext.putParameter("IsFirstPage", new Boolean(isFirstPage));
    if (isFirstPage) pageContext.putSessionValue("StartUrl", pageContext.getCurrentUrl());        

    String templateId = pageContext.getParameter("templateId"); //The template id will come from the interactive preview and drilldown.    

    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this, "Template Id : "+templateId, OAFwkConstants.PROCEDURE); 
    
    //1. execute the DataSourceVO to get the a list of datasource if it is the first page.(cache in the cache)
    HashMap priAppDataSrcList = new HashMap();   //the primary application data source list.
    Object priAppDataSrcObj = pageContext.getTransactionTransientValue("PRI_DATASOURCE");
    Object cachedPriAppObj = pageContext.getTransactionValue("PRI_APP_ID");
    pageContext.putTransactionValue("PRI_APP_ID", String.valueOf(priAppId));    

    if (priAppDataSrcObj == null) 
    {
      //initPriAppDataSource(pageContext, webBean, priAppDataSrcList, 222);      
                        initPriAppDataSource(pageContext, webBean, priAppDataSrcList, priAppId); //remove the hardcoded priAppId
      pageContext.putTransactionTransientValue("PRI_DATASOURCE", priAppDataSrcList);
    }
    else
    {
      int cachedPriAppId = Integer.parseInt((String)cachedPriAppObj);        
      if (priAppId != cachedPriAppId)
      {
                        initPriAppDataSource(pageContext, webBean, priAppDataSrcList, priAppId); //remove the hardcoded priAppId
        pageContext.putTransactionTransientValue("PRI_DATASOURCE", priAppDataSrcList);                
      }              
      else  priAppDataSrcList = (HashMap)priAppDataSrcObj;      
    }

    //2. initalize the invoice header view object.
    //Use the init sequence to always initialize the first header view
    String invoiceLevel = null;
    boolean hasGroup = false;         //Since custom data source only support Line + Detail, it only works for OKS now.
    boolean hasDetail = false;        //Use fall back for Custom data source for now.
    String currencyCode = "USD";  
    String trxNumber = null;
    String taxPrintingOption = "";  
    String interfaceHeaderContext = null;
    Date creationDate = null;
    
    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this, "Customer Trx id :"+pageContext.getParameter("CustomerTrxId")+", Terms Seq Num :"+ pageContext.getParameter("TermsSequenceNumber"), OAFwkConstants.PROCEDURE); 
    
    DataSource headerDataSource = (DataSource)priAppDataSrcList.get(FIRST_HEADER);
    OAViewObject vo = getHeaderViewObject(pageContext, webBean, headerDataSource); 
    
    invoiceLevel = (String)getViewObjectValue(vo, "BillingLineLevel");
    String hasGrouping = (String)getViewObjectValue(vo, "TrxHasGroups");        
    hasGroup = (hasGrouping != null && "Y".equals(hasGrouping)? true : false);
    String currency = (String)getViewObjectValue(vo, "InvoiceCurrencyCode");        
    currencyCode = (currency != null && !"".equals(currency) ? currency : currencyCode);    
    pageContext.putParameter("CurrencyCode", currencyCode);        
    String currentDate = nls.dateToString((Date)getViewObjectValue(vo, "CurrentDate"));
    pageContext.putParameter("CurrentDate", currentDate);      
    String headerSoNumber = (String)getViewObjectValue(vo, "SalesOrder");        
    if (headerSoNumber != null) 
      pageContext.putParameter("HeaderSoNumber", headerSoNumber);
    String headerCoNumber = (String)getViewObjectValue(vo, "ContractNumber");     
    if (headerCoNumber != null)     
      pageContext.putParameter("HeaderCoNumber", headerCoNumber);    
    trxNumber = (String)getViewObjectValue(vo, "TrxNumber");
    taxPrintingOption = (String)getViewObjectValue(vo, "TaxPrintingOption");
    interfaceHeaderContext = (String)getViewObjectValue(vo, "InterfaceHeaderContext");
    creationDate = (Date)getViewObjectValue(vo, "CreationDate");        
    if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
    {
      pageContext.writeDiagnostics(this, "Transaction Information-----------------------(+)", OAFwkConstants.STATEMENT);                                   
      pageContext.writeDiagnostics(this, "The Billing Line Level: " + invoiceLevel, OAFwkConstants.STATEMENT);        
      pageContext.writeDiagnostics(this, "Has Grouping Info: " + hasGroup, OAFwkConstants.STATEMENT);                          
      pageContext.writeDiagnostics(this, "Currency Code: " + currencyCode, OAFwkConstants.STATEMENT);                                  
      pageContext.writeDiagnostics(this, "Current System Date: " + currentDate, OAFwkConstants.STATEMENT);                                  
      pageContext.writeDiagnostics(this, "Sales Order: " + headerSoNumber, OAFwkConstants.STATEMENT);                                  
      pageContext.writeDiagnostics(this, "Transaction Number: " + trxNumber, OAFwkConstants.STATEMENT);                                  
      pageContext.writeDiagnostics(this, "Transaction Creation Date: " + creationDate, OAFwkConstants.STATEMENT);                                                                        
      pageContext.writeDiagnostics(this, "Tax Printing Option: " + taxPrintingOption, OAFwkConstants.STATEMENT);                        
      pageContext.writeDiagnostics(this, "Header Interface Context: " + interfaceHeaderContext, OAFwkConstants.STATEMENT);                                
      pageContext.writeDiagnostics(this, "InteractivePreview Template Id: " + templateId, OAFwkConstants.STATEMENT);                                                    
      pageContext.writeDiagnostics(this, "System Organization Id: " + pageContext.getOrgId(), OAFwkConstants.STATEMENT);                                                    
      pageContext.writeDiagnostics(this, "Transaction Information-----------------------(-)", OAFwkConstants.STATEMENT);                                             
    }

    //3. go through the assignment engine to decide the template.    
    if (isNullString(templateId))
      templateId = assignmentEngine(pageContext,webBean, vo.first(), priAppId);
    if (templateId == null)
    {
      if (pageContext.isLoggingEnabled(OAFwkConstants.ERROR))
        pageContext.writeDiagnostics(this, "Error in getting Template for document: " + 
                    Utilities.getRowValue(vo.first(), "TrxNumber"), OAFwkConstants.ERROR);       
      return;
    }      

    //4. execute the TemplateVO to get the template info based on the template id.
    int appId = -1;    //the secondary application id. 
    boolean showGroup = false;               
    boolean showDetail = false;     
    boolean useARTaxFormat = false; 
    boolean hasItemizedTax = false; 
    String  taxSummaryGrpby = null;     //tax Grouping criteria
    String  tmpltFormat = null;         //template format for BF bill
    OAViewObject viewObject = null;    
    
    // Access to details is controlled by profile
    String showDetailStr = pageContext.getProfile("AR_BPA_DETAIL_ACCESS_ENABLED");
    showDetail = ("Y".equals(showDetailStr) ? true : false); 
    
    if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
    {
      pageContext.writeDiagnostics(this, "Page Level Information-----------------------(+)", OAFwkConstants.STATEMENT);                                   
      pageContext.writeDiagnostics(this, "Display Level: " + dispLevel, OAFwkConstants.STATEMENT);                                
      pageContext.writeDiagnostics(this, "Line Type: " + lineType, OAFwkConstants.STATEMENT);                                
      pageContext.writeDiagnostics(this, "First Page: " + isFirstPage, OAFwkConstants.STATEMENT);               
      pageContext.writeDiagnostics(this, "Start URL: " + (String)pageContext.getSessionValue("StartUrl"), OAFwkConstants.STATEMENT);                     
      pageContext.writeDiagnostics(this, "Billing Details Access: " + showDetail, OAFwkConstants.STATEMENT);                     
      pageContext.writeDiagnostics(this, "Page Level Information-----------------------(-)", OAFwkConstants.STATEMENT);                                             
    }
        
    viewObject = (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("TemplatesVO");
    viewObject.setWhereClauseParam(0,templateId); 
    viewObject.executeQuery();    
    Row row = viewObject.next(); 
    if (row != null) {
      appId = Integer.parseInt(row.getAttribute("SecondaryAppId").toString());         
      String showGroupFlag = (String)row.getAttribute("ShowLineGroupingFlag");              
      showGroup = (showGroupFlag != null && "Y".equals(showGroupFlag) && hasGroup ? true : false);
      pageContext.putParameter("ShowSeq", (String)row.getAttribute("ShowSequenceFlag"));      
      String useARTaxFormatFlag = (String)row.getAttribute("UseArTaxoptionFlag");          
      useARTaxFormat = (useARTaxFormatFlag != null && "Y".equals(useARTaxFormatFlag) ? true : false);      
      String showItemizedTaxFlag = (String)row.getAttribute("ShowItemizedTaxFlag");    
      hasItemizedTax = (showItemizedTaxFlag != null && "Y".equals(showItemizedTaxFlag) ? true : false);            
      taxSummaryGrpby = (String)row.getAttribute("TaxSummaryGrpby");                
      String showSequenceFlag = (String)row.getAttribute("ShowSequenceFlag");
      tmpltFormat = (String)row.getAttribute("TemplateFormat"); 
      
      if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
      {
        pageContext.writeDiagnostics(this, "Show Sequence Flag : "+ showSequenceFlag, OAFwkConstants.STATEMENT);   
        pageContext.writeDiagnostics(this, "Show Group Flag : "+ showGroupFlag, OAFwkConstants.STATEMENT); 
        
      }
      
      /*Bug2830767 - Tax Lines should not have Sequence Nos */
      if ( (appId == 515) && "Y".equals(showSequenceFlag) )
      {
         if ( !isFirstPage)
             pageContext.putTransactionValue("DETAIL_SEQ_NUM", new Number(0));
      }

      
      if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
      {
        //most of them doesn't apply to BF bill
        pageContext.writeDiagnostics(this, "Template Information-----------------------(+)", OAFwkConstants.STATEMENT);                         
        pageContext.writeDiagnostics(this, "Template Id: " + templateId, OAFwkConstants.STATEMENT);                                        
        pageContext.writeDiagnostics(this, "Secondary Application Id: " + appId, OAFwkConstants.STATEMENT);                   
        pageContext.writeDiagnostics(this, "Show Group: " + showGroup, OAFwkConstants.STATEMENT);                   
        pageContext.writeDiagnostics(this, "Show Sequence: " + (String)row.getAttribute("ShowSequenceFlag"), OAFwkConstants.STATEMENT);                   
        pageContext.writeDiagnostics(this, "Use AR Tax Format: " + useARTaxFormat, OAFwkConstants.STATEMENT);                   
        pageContext.writeDiagnostics(this, "Show Itemized Tax: " + hasItemizedTax, OAFwkConstants.STATEMENT);                   
        pageContext.writeDiagnostics(this, "Tax Summary Group By: " + taxSummaryGrpby, OAFwkConstants.STATEMENT);                   
        pageContext.writeDiagnostics(this, "Show Sequence Flag: " + showSequenceFlag, OAFwkConstants.STATEMENT);                   
        pageContext.writeDiagnostics(this, "Template Format: " + tmpltFormat, OAFwkConstants.STATEMENT);                           
        pageContext.writeDiagnostics(this, "Template Information-----------------------(-)", OAFwkConstants.STATEMENT);                                 
      }
    } 
    
    //5. decide the tax printing option based on the flag.
    boolean showItemizedTax = false;
    boolean showSummaryTax  = false;
    boolean showEuroTax     = false;
    boolean taxGrpByName    = false;

    if (useARTaxFormat) 
    {
      if (!isNullString(taxPrintingOption))
      {
        if ((taxPrintingOption.indexOf("ITEMIZE")) != -1) showItemizedTax = true;
        if ((taxPrintingOption.indexOf("SUM")) != -1) showSummaryTax = true;
        if ((taxPrintingOption.indexOf("RECAP")) != -1) showSummaryTax = true;
        if ((taxPrintingOption.indexOf("EUROPEAN")) != -1) 
        {
          showSummaryTax = true;      
          showEuroTax = true;        
        }
        if (("RECAP_BY_NAME".equals(taxPrintingOption))) taxGrpByName = true;            
      }
    }
    else 
    {
      showEuroTax = true;
      if (hasItemizedTax) showItemizedTax = true;      
      if (!isNullString(taxSummaryGrpby)) 
      {
        showSummaryTax = true;
        if ("N".equals(taxSummaryGrpby)) taxGrpByName = true;
      }
    }

    pageContext.putParameter("ShowEuroTax", new Boolean(showEuroTax));
    pageContext.putParameter("TaxGrpByName", new Boolean(taxGrpByName));
    
    //6. based on the invoiceLevel flag and hasGroup flag to initialize the Application level Datasource if the secondary appid exist.
    HashMap secAppDataSrcList = new HashMap();   //the secondary application data source list.    
    Object secAppDataSrcObj = pageContext.getTransactionTransientValue("SEC_DATASOURCE");
    Object cachedAppObj = pageContext.getTransactionValue("SEC_APP_ID");
    pageContext.putTransactionValue("SEC_APP_ID", String.valueOf(appId));    
    //Comment out the invoiceLevel since it only apply to seeded OKS so far.
    if (appId != 515) invoiceLevel = null;
    if (cachedAppObj == null)
    {
      if (appId != -1)
      {
        //Load the secondary App data source
        initSecAppDataSource(pageContext, webBean, secAppDataSrcList, appId, invoiceLevel, showGroup, hasGroup);
        pageContext.putTransactionTransientValue("SEC_DATASOURCE", secAppDataSrcList);        
      }
    }
    else
    {
      int cachedAppId = Integer.parseInt((String)cachedAppObj);    
      if (appId == 515)
      {
        //always try to reload the OKS data source since it may contains different invoice level        
        initSecAppDataSource(pageContext, webBean, secAppDataSrcList, appId, invoiceLevel, showGroup, hasGroup);
        pageContext.putTransactionTransientValue("SEC_DATASOURCE", secAppDataSrcList);                        
      }
      else if (appId == -1)
      {
        if (secAppDataSrcObj != null) pageContext.removeTransactionTransientValue("SEC_DATASOURCE");      
      }
      else
      {
        if (appId == cachedAppId)
        {
          if (secAppDataSrcObj == null) 
          {
            initSecAppDataSource(pageContext, webBean, secAppDataSrcList, appId, invoiceLevel, showGroup, hasGroup);
            pageContext.putTransactionTransientValue("SEC_DATASOURCE", secAppDataSrcList);
          }
          else  secAppDataSrcList = (HashMap)secAppDataSrcObj;          
        }
        else
        {
          initSecAppDataSource(pageContext, webBean, secAppDataSrcList, appId, invoiceLevel, showGroup, hasGroup);
          pageContext.putTransactionTransientValue("SEC_DATASOURCE", secAppDataSrcList);                
        }              
      }
    }

    //7 initialize the header data source and header webbean if it is the first page.
    OAWebBean bean = webBean;
    OAWebBean bodyBean = null;
    if (isFirstPage) {
      if (pageContext.isLoggingEnabled(OAFwkConstants.EVENT))
            pageContext.writeDiagnostics(this, "Call generateWebBean to generate header section, in: " + this.getClass().getName() +  ": Entering generateWebBean", OAFwkConstants.EVENT);
      //decide which data source has been used in the template and execute the data source.                    
      initHeaderDataSrcList(pageContext, webBean, priAppDataSrcList, secAppDataSrcList, vo, templateId);
      
      viewObject = (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("ContentAreasVO");
      viewObject.setWhereClauseParam(0,templateId);  
      viewObject.setWhereClauseParam(1,HEADER);  
      viewObject.executeQuery();    
      bean = generateWebBean(pageContext, webBean, webBean, viewObject, NO_CELL_FORMAT_BEAN);    
      bodyBean = (OAWebBean)webBean.findIndexedChildRecursive("BodyBean");  
    }

    //8. initialize the body data source and body webbean based on the invoiceLevel and hasGroup flag.
    if (SUMMARY.equals(invoiceLevel)) {
        //B, S, D or //B, S          
        if (isFirstPage) 
        {
          if (pageContext.isLoggingEnabled(OAFwkConstants.EVENT))
                pageContext.writeDiagnostics(this, "Call show Line, in: " + this.getClass().getName() +  ": Entering showLine", OAFwkConstants.EVENT);                                            
          showLine(pageContext, bean, bodyBean, vo, priAppDataSrcList, secAppDataSrcList, templateId, 
                    showDetail, true, lineType, isFirstPage, appId, showItemizedTax, showSummaryTax, tmpltFormat);        
          showPageTitle(pageContext, trxNumber);
        }
        else if ("S".equals(dispLevel))
        {
          if (pageContext.isLoggingEnabled(OAFwkConstants.EVENT))
                pageContext.writeDiagnostics(this, "Call show SubLine, in: " + this.getClass().getName() +  ": Entering showSubline", OAFwkConstants.EVENT);                                      
          showSubline(pageContext, bean, vo, secAppDataSrcList, templateId, showDetail, lineType, appId);          
        }
        else if ("D".equals(dispLevel)) 
        {
          if (pageContext.isLoggingEnabled(OAFwkConstants.EVENT))
                pageContext.writeDiagnostics(this, "Call show Detail, in: " + this.getClass().getName() +  ": Entering showDetail", OAFwkConstants.EVENT);                                                  
          showDetail(pageContext, bean, vo, priAppDataSrcList, secAppDataSrcList, templateId, lineType);
        }
        else 
        {
          if (pageContext.isLoggingEnabled(OAFwkConstants.EVENT))
                pageContext.writeDiagnostics(this, "Call show Line, in: " + this.getClass().getName() +  ": Entering showLine", OAFwkConstants.EVENT);                                                              
          showLine(pageContext, bean, bodyBean, vo, priAppDataSrcList, secAppDataSrcList, templateId, 
                    showDetail, true, lineType, isFirstPage, appId, showItemizedTax, showSummaryTax, tmpltFormat);        
          showPageTitle(pageContext, trxNumber);          
        }
    }
    else 
    {
      if (showGroup) 
      {
        //G, B, D or //G, B
        if (isFirstPage)
        {
          if (pageContext.isLoggingEnabled(OAFwkConstants.EVENT))
                pageContext.writeDiagnostics(this, "Call show Group, in: " + this.getClass().getName() +  ": Entering showGroup", OAFwkConstants.EVENT);                                                                    
          showGroup(pageContext, bean, bodyBean, vo, priAppDataSrcList, secAppDataSrcList, templateId, 
                    showDetail, appId, showItemizedTax, showSummaryTax);
          showPageTitle(pageContext, trxNumber);        
        }
        else if ("B".equals(dispLevel))
        {
          if (pageContext.isLoggingEnabled(OAFwkConstants.EVENT))
                pageContext.writeDiagnostics(this, "Call show Line, in: " + this.getClass().getName() +  ": Entering showLine", OAFwkConstants.EVENT);                                                                                
          showLine(pageContext, bean, bodyBean, vo, priAppDataSrcList, secAppDataSrcList, templateId, 
                    showDetail, false, lineType, isFirstPage, appId, showItemizedTax, showSummaryTax, tmpltFormat);                
        }
        else if ("D".equals(dispLevel)) 
        {
          if (pageContext.isLoggingEnabled(OAFwkConstants.EVENT))
                pageContext.writeDiagnostics(this, "Call show Detail, in: " + this.getClass().getName() +  ": Entering showDetail", OAFwkConstants.EVENT);                                                                            
          showDetail(pageContext, bean, vo, priAppDataSrcList, secAppDataSrcList, templateId, lineType);
        }
        else 
        {
          if (pageContext.isLoggingEnabled(OAFwkConstants.EVENT))
                pageContext.writeDiagnostics(this, "Call show Group, in: " + this.getClass().getName() +  ": Entering showGroup", OAFwkConstants.EVENT);                                                                              
          showGroup(pageContext, bean, bodyBean, vo, priAppDataSrcList, secAppDataSrcList, templateId, 
                    showDetail, appId, showItemizedTax, showSummaryTax);
          showPageTitle(pageContext, trxNumber);                  
        }
      } 
      else 
      {
        //B, D  or  //B          
        if (isFirstPage)
        {
          if (pageContext.isLoggingEnabled(OAFwkConstants.EVENT))
                pageContext.writeDiagnostics(this, "Call show Line, in: " + this.getClass().getName() +  ": Entering showLine", OAFwkConstants.EVENT);                                                                                
          showLine(pageContext, bean, bodyBean, vo, priAppDataSrcList, secAppDataSrcList, templateId, 
                    showDetail, false, lineType, isFirstPage, appId, showItemizedTax, showSummaryTax, tmpltFormat);
          showPageTitle(pageContext, trxNumber);        
        }
        else if ("D".equals(dispLevel))
        {
          if (pageContext.isLoggingEnabled(OAFwkConstants.EVENT))
                pageContext.writeDiagnostics(this, "Call show Detail, in: " + this.getClass().getName() +  ": Entering showDetail", OAFwkConstants.EVENT);                                                                            
          showDetail(pageContext, bean, vo, priAppDataSrcList, secAppDataSrcList, templateId, lineType);
        }
        else 
        {
          if (pageContext.isLoggingEnabled(OAFwkConstants.EVENT))
                pageContext.writeDiagnostics(this, "Call show Line, in: " + this.getClass().getName() +  ": Entering showLine", OAFwkConstants.EVENT);                                                                                
          showLine(pageContext, bean, bodyBean, vo, priAppDataSrcList, secAppDataSrcList, templateId, 
                    showDetail, false, lineType, isFirstPage, appId, showItemizedTax, showSummaryTax, tmpltFormat);
          showPageTitle(pageContext, trxNumber);                  
        }
      }                  
    }

    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this, "prepareData()-", OAFwkConstants.PROCEDURE);             
  }

  private void showPageTitle(OAPageContext pageContext, String trxNumber)
  {
    OAPageLayoutBean pageLayoutBean = pageContext.getPageLayoutBean(); 
    //Make TrxNumber as a mandatory item name for any primary data source.
    MessageToken[] tokens = { new MessageToken("TRX_NUMBER",trxNumber) };    
    pageLayoutBean.setWindowTitle(pageContext.getMessage("AR", "AR_BPA_TRX_TITLE", tokens)); 
//    pageLayoutBean.prepareForRendering(pageContext);                             
  }

  private void initHeaderDataSrcList(OAPageContext pageContext, OAWebBean webBean, HashMap priAppDataSrcList,
                                     HashMap secAppDataSrcList, OAViewObject headerVo, String templateId)
  {
    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this, "initHeaderDataSrcList()+", OAFwkConstants.PROCEDURE);         
        
    OAViewObject viewObject = (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("HeaderDataSrcListVO");
    viewObject.setWhereClauseParam(0,templateId);  
    viewObject.executeQuery(); 

    for (Row row = viewObject.first(); row != null; row = viewObject.next())
    { 
      Number datasourceId = (Number)row.getAttribute(0);
      Object dataSrcObj = priAppDataSrcList.get(datasourceId);
      if (dataSrcObj == null) dataSrcObj = secAppDataSrcList.get(datasourceId);
      DataSource dataSource = (DataSource)dataSrcObj;
      getViewObject(pageContext, webBean, dataSource, templateId, headerVo); 
    }

    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this, "initHeaderDataSrcList()-", OAFwkConstants.PROCEDURE);             
  }  

  private void initPriAppDataSource(OAPageContext pageContext, OAWebBean webBean, HashMap priAppDataSrcList, int appId)
  {
    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this, "initPriAppDataSrcList()+", OAFwkConstants.PROCEDURE);         
        
    OAViewObject viewObject = (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("DataSourcesVO");
    viewObject.setWhereClauseParam(0,new Integer(appId));  
    viewObject.executeQuery();        
    for (Row row = viewObject.first(); row != null; row = viewObject.next())
    { 
      Number datasourceId = (Number)row.getAttribute(0); 
      String voUsageName = (String)row.getAttribute(1);    
      String voClassName = (String)row.getAttribute(2);          
      String displayLevel = (String)row.getAttribute(3);     
      String taxSourceFlag = (String)row.getAttribute(4);           
      String sourceLineType = (String)row.getAttribute(5);                 
      String objectType = (String)row.getAttribute(6);           
      String objectName = (String)row.getAttribute(7);                       
      String viewName = (String)row.getAttribute(8);                             
      Number applicationId = (Number)row.getAttribute(9);             
      Number voInitSeq = (Number)row.getAttribute(10);                   
      String invoiceLevel = (String)row.getAttribute(11);                             
      
      DataSource dataSource = new DataSource(datasourceId, applicationId, objectType, objectName, voUsageName, voClassName, viewName, displayLevel);      
      if (HEADER.equals(displayLevel))
      {
        //always store as the first header if it is the first one
        if (voInitSeq.compareTo(FIRST_HEADER) == 0 )      
          priAppDataSrcList.put(FIRST_HEADER, dataSource);        
        else
          priAppDataSrcList.put(datasourceId, dataSource);                
      }
      else if (BILLINGLINE.equals(displayLevel)) 
      {
        if (isNullString(taxSourceFlag))
        {
          //handle the case when two billing line view registered for BF.
          if (isNullString(sourceLineType))          
            priAppDataSrcList.put(BILLINGLINE, dataSource);                                
          else
            priAppDataSrcList.put(sourceLineType+BILLINGLINE, dataSource);
        }
        else  
          priAppDataSrcList.put(BILLINGLINE+TAX, dataSource);      
      }
      else if (TAX.equals(displayLevel)) 
        priAppDataSrcList.put(TAX + taxSourceFlag, dataSource);
      else if (DETAIL.equals(displayLevel)) 
        priAppDataSrcList.put(DETAIL, dataSource);        
    }
    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this, "initPriAppDataSrcList()-", OAFwkConstants.PROCEDURE);             
  }

  private void initSecAppDataSource(OAPageContext pageContext, OAWebBean webBean, HashMap secAppDataSrcList, 
                               int appId, String invoiceLevel, boolean showGroup, boolean hasGroup)
  {
    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this, "initSecAppDataSource()+", OAFwkConstants.PROCEDURE);                
    OAViewObject viewObject = (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("DataSourcesVO1");
    if (SUMMARY.equals(invoiceLevel)) 
    {
      viewObject.setWhereClauseParam(0,new Integer(appId));        
      viewObject.setWhereClauseParam(1,invoiceLevel);      //'S' -- Summary Level
    }
    else if (DETAIL.equals(invoiceLevel))
    {
      if (hasGroup)
      {
        if (showGroup) 
        {
          viewObject.setWhereClauseParam(0,new Integer(appId));        
          viewObject.setWhereClauseParam(1,invoiceLevel);  //'D' -- Detail Level          
        } 
        else 
        {
          viewObject.setWhereClauseParam(0,new Integer(appId));        
          viewObject.setWhereClauseParam(1,"N");           //'N' -- Don't show the group.
        }        
      }
      else
      {
        //Need fix Bug 2835504
        viewObject.setWhereClauseParam(0,new Integer(appId));        
        viewObject.setWhereClauseParam(1,"O");             //'O' -- Past invoice.
      }
    }
    else 
    {
      viewObject = (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("DataSourcesVO");      
      viewObject.setWhereClauseParam(0,new Integer(appId));              
    }
    viewObject.executeQuery();        
    for (Row row = viewObject.first(); row != null; row = viewObject.next())
    { 
      Number datasourceId = (Number)row.getAttribute(0);
      String voUsageName = (String)row.getAttribute(1);    
      String voClassName = (String)row.getAttribute(2);          
      String displayLevel = (String)row.getAttribute(3);     
      String taxSourceFlag = (String)row.getAttribute(4);           
      String sourceLineType = (String)row.getAttribute(5);                 
      String objectType = (String)row.getAttribute(6);           
      String objectName = (String)row.getAttribute(7);                 
      String viewName = (String)row.getAttribute(8);                                   
      Number applicationId = (Number)row.getAttribute(9);                   

      DataSource dataSource = new DataSource(datasourceId, applicationId, objectType, objectName, voUsageName, voClassName, viewName, displayLevel);
      if (HEADER.equals(displayLevel))  secAppDataSrcList.put(datasourceId, dataSource);
      else if (GROUP.equals(displayLevel)) 
      {
        if (!isNullString(taxSourceFlag) && "Y".equals(taxSourceFlag)) 
          secAppDataSrcList.put(GROUP+TAX, dataSource);
        else
          secAppDataSrcList.put(GROUP, dataSource);
      }
      else if (BILLINGLINE.equals(displayLevel))
      {
        if (isNullString(sourceLineType))
        {
          if (isNullString(taxSourceFlag))
          {
            secAppDataSrcList.put(BILLINGLINE, dataSource);
            secAppDataSrcList.put(BILLINGLINE+TAX, dataSource);
          }
          else  secAppDataSrcList.put(BILLINGLINE+TAX, dataSource);
        }
        else 
        {
          if (!isNullString(taxSourceFlag) && "Y".equals(taxSourceFlag)) 
            secAppDataSrcList.put(sourceLineType+BILLINGLINE+TAX, dataSource);
          else
            secAppDataSrcList.put(sourceLineType+BILLINGLINE, dataSource);
        }
      }
      else if (SUBLINE.equals(displayLevel)) 
      {
        if (isNullString(sourceLineType))
          secAppDataSrcList.put(SUBLINE, dataSource);
        else
          secAppDataSrcList.put(sourceLineType+SUBLINE, dataSource);
      }
      else if (DETAIL.equals(displayLevel)) 
      {
        if (isNullString(sourceLineType))
          secAppDataSrcList.put(DETAIL, dataSource);
        else
          secAppDataSrcList.put(sourceLineType+DETAIL, dataSource);
      }
    }
    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this, "initSecAppDataSource()-", OAFwkConstants.PROCEDURE);                  
  }

  private StringBuffer appendParamList(OAPageContext pageContext, OAWebBean webBean, DataSource dataSource, StringBuffer link)
  {
    if (dataSource != null) 
    {
      Vector paramNameList = dataSource.getParamList(pageContext, webBean);
      for (int i=0; i<paramNameList.size(); i++) {
        DataSrcParam param = (DataSrcParam)paramNameList.elementAt(i);
        if (DRILLDOWN_PARAM.equals(param.getParamType())) {
          link.append("&" + param.getColumnValue() + "={@" + param.getColumnValue() + "}");
        }
      }                            
    }
    return link;
  }

  private Hashtable getLineTypeDetail(OAPageContext pageContext, OAWebBean webBean, String templateId, String[] lineTypes)
  {
    Hashtable detailList = new Hashtable();
    OAViewObject viewObject = null;
    if (lineTypes != null) 
    {
      for (int i=0; i<lineTypes.length; i++)
      {
        viewObject = (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("VContentAreaDetail");
        viewObject.setWhereClauseParam(0,templateId);          
        viewObject.setWhereClauseParam(1,lineTypes[i]);  
        viewObject.executeQuery();          
        if (viewObject.next() != null) detailList.put(lineTypes[i], "Y");          
      }
    }
    else 
    {
      viewObject = (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("VContentAreaDetail1");    
      viewObject.setWhereClauseParam(0,templateId);        
      viewObject.executeQuery();          
      if (viewObject.next() != null)  detailList.put(DETAIL, "Y");          
    }
    return detailList;
  }
  
  private void showGroup(OAPageContext pageContext, OAWebBean webBean, OAWebBean bodyBean, OAViewObject headerVo, HashMap list1, 
                        HashMap list2, String templateId, boolean showDetail, int appId, boolean showItemizedTax, boolean showSummaryTax)
  {  
    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this, "showGroup()+", OAFwkConstants.PROCEDURE);             
    //5.1 execute the corresponding viewobject here.        
    DataSource dataSource = null;
    if (showItemizedTax)  dataSource = (DataSource)list2.get(GROUP+TAX);
    if (dataSource == null) dataSource = (DataSource)list2.get(GROUP);
    
    getViewObject(pageContext, webBean, dataSource, templateId, headerVo); 
    pageContext.putParameter("BodyVoUsageName", dataSource.getVoUsageName());
    pageContext.putParameter("DisplayLevel", dataSource.getDisplayLevel());    
    //5.2 construct the drilldown link based on the lineType.
    String[] lineTypes = AppRoutines.getLineTypes(appId);
    Hashtable detailList = getLineTypeDetail(pageContext, webBean, templateId, lineTypes);
    Hashtable drilldownUrls = new Hashtable();
    String sLink = (String)pageContext.getSessionValue("StartUrl");
    
    if (sLink.lastIndexOf("retainAM=Y") == -1) sLink = sLink + "&retainAM=Y";
    if (sLink.lastIndexOf("templateId=") == -1) sLink = sLink + "&templateId=" + templateId;    
    // Replace addBreadCrumb=RS with addBreadCrumb=Y
    sLink = updateBreadCrumb(sLink);
    
    StringBuffer link = null;

    if (lineTypes != null) 
    {
      //To construct the url link for different lineType. G-B-D
      for (int i=0; i<lineTypes.length; i++) 
      {
        link = new StringBuffer(sLink);
        if (list2.get(lineTypes[i]+BILLINGLINE) != null) 
        {
          link.append("&seqNum={@SequenceNumber}&dispLevel=B"); //the next level is "B"    
          if (showItemizedTax)
            link = appendParamList(pageContext, webBean, (DataSource)list2.get(lineTypes[i]+BILLINGLINE+TAX), link); 
          else
            link = appendParamList(pageContext, webBean, (DataSource)list2.get(lineTypes[i]+BILLINGLINE), link);           
        }
        else if (showDetail && (detailList.get(lineTypes[i]) != null) && (list2.get(lineTypes[i]+DETAIL) != null))
        {
          link.append("&dispLevel=D");      //the next level is "D"                          
          link = appendParamList(pageContext, webBean, (DataSource)list2.get(lineTypes[i]+DETAIL), link);           
        }
        else link = null;
        if (link != null) 
        {
          link.append("&lineType={@LineType}");          
          drilldownUrls.put(lineTypes[i],link.toString());          
        }
      }
      pageContext.putParameter("DrilldownUrls", drilldownUrls);      
    }
    else 
    {
      link = new StringBuffer(sLink);
      link.append("&seqNum={@SequenceNumber}&dispLevel=B");  //the next level is "B"                  
      if (showItemizedTax)      
        link = appendParamList(pageContext, webBean, (DataSource)list2.get(BILLINGLINE+TAX), link); 
      else
        link = appendParamList(pageContext, webBean, (DataSource)list2.get(BILLINGLINE), link);       
      pageContext.putParameter("DrilldownUrls", link.toString());      
    }
    //5.3 call the ViewObject to retrieve all infos.
    OAViewObject viewObject = (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("ContentAreasVO");
    viewObject.setWhereClauseParam(0,templateId);  
    viewObject.setWhereClauseParam(1,LINE);  
    viewObject.executeQuery();    
    
    if (pageContext.isLoggingEnabled(OAFwkConstants.EVENT))
          pageContext.writeDiagnostics(this, "Call generateWebBean to generate billing line(group) section, in: " + this.getClass().getName() +  ": Entering generateWebBean", OAFwkConstants.EVENT);                                 
    OAWebBean bodyBean1 = generateWebBean(pageContext, webBean, bodyBean, viewObject, NO_CELL_FORMAT_BEAN);      
    //6. display the tax summary section after the main body.
    if (showSummaryTax) 
    {
      bodyBean1.addIndexedChild(createSpacerBean(pageContext, 0, 10));      
      //6.1 initialize the tax summary viewobject.
      boolean taxGrpByName = ((Boolean)pageContext.getParameterObject("TaxGrpByName")).booleanValue();                
      if (taxGrpByName) dataSource = (DataSource)list1.get(TAX+"N");
      else dataSource = (DataSource)list1.get(TAX+"C");
      getViewObject(pageContext, webBean, dataSource, templateId, headerVo); 
      pageContext.putParameter("TaxVoUsageName", dataSource.getVoUsageName());      
      //6.2 initialize the tax summary template
      viewObject = (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("ContentAreasVO");
      viewObject.setWhereClauseParam(0,templateId);  
      viewObject.setWhereClauseParam(1,TAX);  
      viewObject.executeQuery();        
      if (pageContext.isLoggingEnabled(OAFwkConstants.EVENT))
            pageContext.writeDiagnostics(this, "Call generateWebBean to generate tax summary section, in: " + this.getClass().getName() +  ": Entering generateWebBean", OAFwkConstants.EVENT);                                             
      generateWebBean(pageContext, webBean, bodyBean1, viewObject, NO_CELL_FORMAT_BEAN);
    }
    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this, "showGroup()-", OAFwkConstants.PROCEDURE);               
  }          

  //Currenlty only modify showLine method to support BF, need to populate the code to showGroup in the future.
  private void showLine(OAPageContext pageContext, OAWebBean webBean, OAWebBean bodyBean, OAViewObject headerVo, HashMap list1, 
                        HashMap list2, String templateId, boolean showDetail, boolean hasSubline, String lineType, boolean isFirstPage, 
                        int appId, boolean showItemizedTax, boolean showSummaryTax, String tmpltFormat)
  {
    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this, "showLine()+", OAFwkConstants.PROCEDURE);              
    //5.1 execute the corresponding viewobject here.     
    DataSource dataSource = null;
    if (appId == -1)    //the supplementary data source is null
    {
      //deal with common case first
      if (showItemizedTax) dataSource = (DataSource)list1.get(BILLINGLINE+TAX);    
      if (dataSource == null) dataSource = (DataSource)list1.get(BILLINGLINE);
      //if no datasource found, check the BF format type.            
      if (dataSource == null) dataSource = (DataSource)list1.get(tmpltFormat+BILLINGLINE);
    } 
    else
    {
      if (isNullString(lineType)) {
        if (showItemizedTax) 
        {
          dataSource = (DataSource)list2.get(BILLINGLINE+TAX);    
          if (dataSource == null) dataSource = (DataSource)list1.get(BILLINGLINE+TAX);    
        }
        else 
        {
          dataSource = (DataSource)list2.get(BILLINGLINE);
          if (dataSource == null) dataSource = (DataSource)list1.get(BILLINGLINE);        
        }
      }
      else {
        if (showItemizedTax) dataSource = (DataSource)list2.get(lineType+BILLINGLINE+TAX);        
        if (dataSource == null) dataSource = (DataSource)list2.get(lineType+BILLINGLINE);    
      }      
    }
    
    getViewObject(pageContext, webBean, dataSource, templateId, headerVo, true); 
    pageContext.putParameter("BodyVoUsageName", dataSource.getVoUsageName());    
    pageContext.putParameter("DisplayLevel", dataSource.getDisplayLevel());        

    String[] lineTypes = AppRoutines.getLineTypes(appId);
    Hashtable detailList = getLineTypeDetail(pageContext, webBean, templateId, lineTypes);    
    Hashtable drilldownUrls = new Hashtable();
    String sLink = (String)pageContext.getSessionValue("StartUrl");
    
    if (sLink.lastIndexOf("retainAM=Y") == -1) sLink = sLink + "&retainAM=Y";
    if (sLink.lastIndexOf("templateId=") == -1) sLink = sLink + "&templateId=" + templateId;        
    sLink = updateBreadCrumb(sLink);

    StringBuffer link = null;       
    if (isFirstPage && (lineTypes != null)) 
    {
      //To construct the url link for different lineType. B-S-D or B-D
      for (int i=0; i<lineTypes.length; i++) 
      {
        link = new StringBuffer(sLink);
        if (hasSubline && (list2.get(lineTypes[i]+SUBLINE) != null)) 
        {
          link.append("&seqNum={@SequenceNumber}&dispLevel=S");      //the next level is "S"                  
          link = appendParamList(pageContext, webBean, (DataSource)list2.get(lineTypes[i]+SUBLINE), link); 
        }
        else if (showDetail && (detailList.get(lineTypes[i]) != null) && (list2.get(lineTypes[i]+DETAIL) != null))
        {
          link.append("&dispLevel=D");      //the next level is "D"                          
          link = appendParamList(pageContext, webBean, (DataSource)list2.get(lineTypes[i]+DETAIL), link);           
        }
        else link = null;
        if (link != null) 
        {
          link.append("&lineType={@LineType}");          
          drilldownUrls.put(lineTypes[i],link.toString());          
        }
      }
      pageContext.putParameter("DrilldownUrls", drilldownUrls);      
    }
    else if (!isFirstPage && (lineType != null)) 
    {
      link = new StringBuffer(sLink);
      if (hasSubline && (list2.get(lineType+SUBLINE) != null)) 
      {
        link.append("&seqNum={@SequenceNumber}&dispLevel=S");      //the next level is "S"                  
        link = appendParamList(pageContext, webBean, (DataSource)list2.get(lineType+SUBLINE), link); 
        pageContext.putParameter("DrilldownUrls", link.toString());              
      }
      else if (showDetail && (detailList.get(lineType) != null) && (list2.get(lineType+DETAIL) != null))
      {
        link.append("&dispLevel=D");      //the next level is "D"                          
        link = appendParamList(pageContext, webBean, (DataSource)list2.get(lineType+DETAIL), link);           
        pageContext.putParameter("DrilldownUrls", link.toString());                      
      }
      else  pageContext.removeParameter("DrilldownUrls");                
    }
    else 
    {
      if (showDetail && (detailList.get(DETAIL) != null) && 
          ((list1.get(DETAIL) != null) || (list2.get(DETAIL) != null)))
      {
        link = new StringBuffer(sLink).append("&dispLevel=D");      //the next level is "D"                  
        if (list2.get(DETAIL) != null) 
          link = appendParamList(pageContext, webBean, (DataSource)list2.get(DETAIL), link);                     
        else
          link = appendParamList(pageContext, webBean, (DataSource)list1.get(DETAIL), link);                             
        pageContext.putParameter("DrilldownUrls", link.toString());              
      }
      else  pageContext.removeParameter("DrilldownUrls");                
    }      
    
    //5.3 call the ViewObject to retrieve all infos.
    OAViewObject viewObject = (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("ContentAreasVO");
    viewObject.setWhereClauseParam(0,templateId);  
    viewObject.setWhereClauseParam(1,LINE);  
    viewObject.executeQuery();    
    
    if (!isFirstPage) {
      OAPageLayoutBean pageLayoutBean = pageContext.getPageLayoutBean(); 

      String pgTitle = pageContext.getParameter("Description");
      if (pgTitle != null)
        pageLayoutBean.setWindowTitle(pgTitle);

//      pageLayoutBean.prepareForRendering(pageContext);        
      if (pageContext.isLoggingEnabled(OAFwkConstants.EVENT))
            pageContext.writeDiagnostics(this, "Call generateWebBean to generate drilldown detail section, in: " + this.getClass().getName() +  ": Entering generateWebBean", OAFwkConstants.EVENT);                                        
      generateWebBean(pageContext, webBean, webBean, viewObject, NO_CELL_FORMAT_BEAN);
    }
    else {
      if (pageContext.isLoggingEnabled(OAFwkConstants.EVENT))
            pageContext.writeDiagnostics(this, "Call generateWebBean to generate billing line(line) section, in: " + this.getClass().getName() +  ": Entering generateWebBean", OAFwkConstants.EVENT);                                              
      OAWebBean bodyBean1 = generateWebBean(pageContext, webBean, bodyBean, viewObject, NO_CELL_FORMAT_BEAN);      
      //6. display the tax summary section after the main body.
      if (showSummaryTax) 
      {
        bodyBean1.addIndexedChild(createSpacerBean(pageContext, 0, 10));            
        //6.1 initialize the tax summary viewobject.
        boolean taxGrpByName = ((Boolean)pageContext.getParameterObject("TaxGrpByName")).booleanValue();                
        if (taxGrpByName) dataSource = (DataSource)list1.get(TAX+"N");
        else dataSource = (DataSource)list1.get(TAX+"C");
        getViewObject(pageContext, webBean, dataSource, templateId, headerVo); 
        pageContext.putParameter("TaxVoUsageName", dataSource.getVoUsageName());      
        //6.2 initialize the tax summary template
        viewObject = (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("ContentAreasVO");
        viewObject.setWhereClauseParam(0,templateId);  
        viewObject.setWhereClauseParam(1,TAX);  
        viewObject.executeQuery();          
        if (pageContext.isLoggingEnabled(OAFwkConstants.EVENT))
              pageContext.writeDiagnostics(this, "Call generateWebBean to generate tax summary section, in: " + this.getClass().getName() +  ": Entering generateWebBean", OAFwkConstants.EVENT);                                                   
        generateWebBean(pageContext, webBean, bodyBean1, viewObject, NO_CELL_FORMAT_BEAN);
      }      
    }
    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this, "showLine()-", OAFwkConstants.PROCEDURE);                
  }

  private void showSubline(OAPageContext pageContext, OAWebBean webBean, OAViewObject headerVo, HashMap list2, 
                           String templateId, boolean showDetail, String lineType, int appId)
  {
    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this, "showSubline()+", OAFwkConstants.PROCEDURE);                   
    //5.1 execute the corresponding viewobject here.        
    DataSource dataSource = null;
    if (isNullString(lineType)) 
      dataSource = (DataSource)list2.get(SUBLINE);
    else
      dataSource = (DataSource)list2.get(lineType+SUBLINE);        
    getViewObject(pageContext, webBean, dataSource, templateId, headerVo); 
    pageContext.putParameter("BodyVoUsageName", dataSource.getVoUsageName());    
    pageContext.putParameter("DisplayLevel", dataSource.getDisplayLevel());        

    String[] lineTypes = AppRoutines.getLineTypes(appId);
    Hashtable detailList = getLineTypeDetail(pageContext, webBean, templateId, lineTypes);        
    Hashtable drilldownUrls = new Hashtable();
    String sLink = (String)pageContext.getSessionValue("StartUrl");
    
    if (sLink.lastIndexOf("retainAM=Y") == -1) sLink = sLink + "&retainAM=Y";
    if (sLink.lastIndexOf("templateId=") == -1) sLink = sLink + "&templateId=" + templateId;        
    // Replace addBreadCrumb=RS with addBreadCrumb=Y
    sLink = updateBreadCrumb(sLink);    
    
    StringBuffer link = null;       
    
    if (lineType != null) 
    {
      if (showDetail && (detailList.get(lineType) != null) && (list2.get(lineType+DETAIL)) != null)
      {
        link = new StringBuffer(sLink).append("&dispLevel=D");      //the next level is "D"                  
        link = appendParamList(pageContext, webBean, (DataSource)list2.get(lineType+DETAIL), link); 
        pageContext.putParameter("DrilldownUrls", link.toString());              
      }
      else  pageContext.removeParameter("DrilldownUrls");                
    }
    else 
    {
      if (showDetail && (detailList.get(DETAIL) != null) && (list2.get(DETAIL) != null))
      {
        link = new StringBuffer(sLink).append("&dispLevel=D");      //the next level is "D"                  
        link = appendParamList(pageContext, webBean, (DataSource)list2.get(DETAIL), link);                     
        pageContext.putParameter("DrilldownUrls", link.toString());              
      }
      else  pageContext.removeParameter("DrilldownUrls");                
    }      
    
    OAViewObject viewObject = (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("ContentAreasVO");
    viewObject.setWhereClauseParam(0,templateId);  
    viewObject.setWhereClauseParam(1,LINE);  
    viewObject.executeQuery();    
    
    OAPageLayoutBean pageLayoutBean = pageContext.getPageLayoutBean(); 

    String pgTitle = pageContext.getParameter("Description");
    if (pgTitle != null)
      pageLayoutBean.setWindowTitle(pgTitle);

//    pageLayoutBean.prepareForRendering(pageContext);             
    if (pageContext.isLoggingEnabled(OAFwkConstants.EVENT))
          pageContext.writeDiagnostics(this, "Call generateWebBean to generate billing line(subline) section, in: " + this.getClass().getName() +  ": Entering generateWebBean", OAFwkConstants.EVENT);                                                 
    generateWebBean(pageContext, webBean, webBean, viewObject, NO_CELL_FORMAT_BEAN);
    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this, "showSubline()-", OAFwkConstants.PROCEDURE);                     
  }

  private void showDetail(OAPageContext pageContext, OAWebBean webBean, OAViewObject headerVo, 
                          HashMap list1, HashMap list2, String templateId, String lineType)
  {
    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this, "showDetail()+", OAFwkConstants.PROCEDURE);                    
    DataSource dataSource = null;
    OAViewObject viewObject = null;
    if (isNullString(lineType)) 
    {
      viewObject = (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("ContentAreasVO");    
      viewObject.setWhereClauseParam(0,templateId);  
      viewObject.setWhereClauseParam(1, DETAIL);  
      dataSource = (DataSource)list2.get(DETAIL);      
      if (dataSource == null) dataSource = (DataSource)list1.get(DETAIL);      
    }
    else
    {
      viewObject = (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("ContentAreasVO1");    
      viewObject.setWhereClauseParam(0,templateId);  
      viewObject.setWhereClauseParam(1, DETAIL);      
      viewObject.setWhereClauseParam(2, lineType);            
      dataSource = (DataSource)list2.get(lineType+DETAIL);      
      if (dataSource == null) dataSource = (DataSource)list1.get(DETAIL);            
    }
      
    getViewObject(pageContext, webBean, dataSource, templateId, headerVo); 
    pageContext.putParameter("BodyVoUsageName", dataSource.getVoUsageName());
    pageContext.putParameter("DisplayLevel", dataSource.getDisplayLevel());        

    viewObject.executeQuery();    
    OAPageLayoutBean pageLayoutBean = pageContext.getPageLayoutBean(); 

    String pgTitle = pageContext.getParameter("Description");
    if (pgTitle != null)
      pageLayoutBean.setWindowTitle(pgTitle);

//    pageLayoutBean.prepareForRendering(pageContext);                 
    
    if (pageContext.isLoggingEnabled(OAFwkConstants.EVENT))
          pageContext.writeDiagnostics(this, "Call generateWebBean to generate drilldown detail section, in: " + this.getClass().getName() +  ": Entering generateWebBean", OAFwkConstants.EVENT);                                              
    generateWebBean(pageContext, webBean, webBean, viewObject, NO_CELL_FORMAT_BEAN);
    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this, "showDetail()-", OAFwkConstants.PROCEDURE);                      
  }

  private String getTemplateId(OAPageContext pageContext, OAWebBean webBean, int secAppId, 
                                Row hdrRow, Date creationDate, String trxClass, int priAppId) 
  {
    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this, "getTemplateId()+", OAFwkConstants.PROCEDURE);                 
    String templateId = null;
    String viewType = pageContext.getParameter("ViewType");
    String printType = ( viewType != null && ("PRINT".equals(viewType) || "MULTIPRINT".equals(viewType)))? "PRINT": "ONLINE";

    OAViewObject vo = (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("RulesVO");
    vo.setWhereClauseParam(0, new Integer(priAppId));    
    vo.setWhereClauseParam(1, new Integer(secAppId));
    vo.setWhereClauseParam(2, trxClass);        
    vo.setWhereClauseParam(3, creationDate);
    vo.setWhereClauseParam(4, printType);    
    vo.setWhereClauseParam(5, printType);        
    vo.executeQuery();        
    for (Row row = vo.first(); row != null; row = vo.next())
    {
      int ruleId = Integer.parseInt(row.getAttribute(0).toString()); 
      String matchAllAttributes = (String)row.getAttribute(1);
      boolean matchAllFlag = (matchAllAttributes != null && "AND".equals(matchAllAttributes)? true : false);      
      String ruleTemplateId = row.getAttribute(2).toString();       

      OAViewObject vo1 = (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("RuleAttributesVO");
      vo1.setWhereClauseParam(0, new Integer(ruleId));
      vo1.executeQuery();   
      boolean ruleMatchFlag = true;
      for (Row row1 = vo1.first(); row1 != null; row1 = vo1.next())
      {
        String itemCode       = (String)row1.getAttribute(0);
        String matchCondition = (String)row1.getAttribute(1);
        String attributeValue = (String)row1.getAttribute(2);
        String dataType       = (String)row1.getAttribute(3);        
        Object value    =  Utilities.getRowValue(hdrRow, itemCode);        
        if ( value != null )
          ruleMatchFlag = Utilities.matchAttributeValue(matchCondition, attributeValue, 
                 value.toString(), dataType, pageContext.getOANLSServices()); 
        else
          ruleMatchFlag = false;        
        if (!ruleMatchFlag && matchAllFlag) break;    //the rule doesn't match
        if (ruleMatchFlag && !matchAllFlag) break;    //the rule match
      }
      if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
      {
        pageContext.writeDiagnostics(this, "Rule Information-----------------------(+)", OAFwkConstants.STATEMENT);                                   
        pageContext.writeDiagnostics(this, "  Rule Id: " + ruleId, OAFwkConstants.STATEMENT);        
        pageContext.writeDiagnostics(this, "  Match All Attributes: " + matchAllFlag, OAFwkConstants.STATEMENT);                          
        pageContext.writeDiagnostics(this, "  Rule Template Id: " + ruleTemplateId, OAFwkConstants.STATEMENT);                                  
        pageContext.writeDiagnostics(this, "  Rule Match Flag: " + ruleMatchFlag, OAFwkConstants.STATEMENT);                                  
        pageContext.writeDiagnostics(this, "Rule Information-----------------------(-)", OAFwkConstants.STATEMENT);                                             
      }
      if (ruleMatchFlag) 
      {
        templateId = ruleTemplateId; 
        break;
      }
    }
    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this, "getTemplateId()-", OAFwkConstants.PROCEDURE);                   

    return templateId;
  }

  private String assignmentEngine(OAPageContext pageContext, OAWebBean webBean, Row hdrRow, int priAppId)
  {
    String templateId = null;
    String interfaceHeaderContext = (String)Utilities.getRowValue(hdrRow, "InterfaceHeaderContext");
    Date creationDate = (Date)Utilities.getRowValue(hdrRow, "CreationDate");        
    String trxClass = (String)Utilities.getRowValue(hdrRow, "TrxType");   
    
    if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
    {
    	pageContext.writeDiagnostics(this, "Transaction Type : "+trxClass, OAFwkConstants.STATEMENT);  
    	pageContext.writeDiagnostics(this, "Interface Header Context : "+interfaceHeaderContext, OAFwkConstants.STATEMENT);
    }
    
    //default other document to "INV" to prevent binding issue. actually even pass null still works.
    if (trxClass == null) trxClass = "INV";   //will be null for BF

    if (!(isNullString(interfaceHeaderContext))) 
    {
      OAViewObject assignVo = (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("ApplicationListVO");
      assignVo.setWhereClauseParam(0,interfaceHeaderContext.trim());  
      assignVo.executeQuery();              
      for (Row row2 = assignVo.first(); row2 != null; row2 = assignVo.next())
      {        
        int secAppId = Integer.parseInt(row2.getAttribute(0).toString());         
        if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
          pageContext.writeDiagnostics(this, "Assigned Secondary Application Id: " + secAppId, OAFwkConstants.STATEMENT);                   
        templateId = getTemplateId(pageContext, webBean, secAppId, hdrRow, creationDate, trxClass, priAppId);
        if (!(isNullString(templateId))) break;   //jump out the loop as soon as we got the template.
      }
    }
    if (isNullString(templateId))
      templateId = getTemplateId (pageContext, webBean, -1, hdrRow, creationDate, trxClass, priAppId);

    if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
    {
      pageContext.writeDiagnostics(this, "Template Assignment Information-----------------------(+)", OAFwkConstants.STATEMENT);                  
      pageContext.writeDiagnostics(this, "Assigned Template Id: " + templateId, OAFwkConstants.STATEMENT);                                        
      pageContext.writeDiagnostics(this, "Template Assignment Information-----------------------(-)", OAFwkConstants.STATEMENT);                                 
    }      
    return templateId;
  }

 private String updateBreadCrumb(String sLink)
 {
    String newLink ;
    if ( sLink.lastIndexOf("addBreadCrumb=") != -1 )
    {
        int ind = sLink.lastIndexOf("addBreadCrumb=") + "addBreadCrumb=".length();        
        String sLink1 = sLink.substring(0,ind);
        if ( sLink.lastIndexOf("addBreadCrumb=RS") != -1 )
            ind = ind + 2;
        else
            ind = ind + 1;
            
        if ( ind < sLink.length() )
        {
           String sLink2 = sLink.substring(ind);    
           newLink = sLink1 + "Y" + sLink2; 
        }
        else
           newLink = sLink1 + "Y";
    }
    else
       newLink = sLink + "&addBreadCrumb=Y"; 
    return newLink;
   
 }

  public void showPdfMultiInv(OAPageContext pageContext, OAWebBean webBean, String requestId, int priAppId)
  {     
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    // First, do the stuff that should be done only once...
    String oaMedia = (String)pageContext.getTransactionTransientValue("OA_MEDIA_VALUE");
    String locale = pageContext.getParameter("locale");
    if ( oaMedia == null )
    {
      oaMedia = ((OADBTransaction)am.getTransaction()).getProfile("APPS_FRAMEWORK_AGENT"); 
      if (oaMedia.endsWith("/") == false) 
        oaMedia += "/"; 
      oaMedia += "OA_MEDIA";
    }
    Properties pr = new Properties(); 
    pr.put("user-variable.OA_MEDIA", oaMedia);

    InvoiceXMLBuilder xmlBuilder = new InvoiceXMLBuilder(am);  
    String workId = "1";      //hardcode to use one workId.
    String orderByColumn = AppRoutines.getOrderByColumn(priAppId, null);
    OADBTransaction transaction = am.getOADBTransaction();  
    String updPrintFlag = pageContext.getParameter("UpdatePrintFlag");

    OAViewObject docVo = null;      //the master vo for printing  
    try 
    {
      OAViewObject dsPrintVo = (OAViewObject)am.findViewObject("DataSourcePrintVO");   //the vo to pick up print header vo
      dsPrintVo.setWhereClauseParam(0,new Number(priAppId));                        
      dsPrintVo.executeQuery();
      Row dsPrintRow = dsPrintVo.first();
      if (dsPrintRow != null)
      {
        docVo = (OAViewObject)am.findViewObject(dsPrintRow.getAttribute(1).toString());
        if (docVo == null)
          docVo = (OAViewObject)am.createViewObject(dsPrintRow.getAttribute(1).toString(), dsPrintRow.getAttribute(2).toString());        
        docVo.setPassivationEnabled(false);    
        Object params[ ] =  { new Number(requestId), new Number(workId) } ;
        docVo.setWhereClauseParams(null);
        docVo.setWhereClauseParams(params);
        docVo.setOrderByClause(orderByColumn);
        docVo.executeQuery();    
        docVo.setForwardOnly(true);
        docVo.setMaxFetchSize(-1);
      }
      else
      {
        //exit the program since no print vo found.
        if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
          pageContext.writeDiagnostics(this, "Error: no print viewobject registered in the system", OAFwkConstants.PROCEDURE);     
        return;      
      }    
    }
    catch( Exception e )
    {
      throw OAException.wrapperException(e);
    }

    String delSql=" DELETE ar_bpa_print_requests WHERE request_id = :1 ";
    OraclePreparedStatement delStmt = (OraclePreparedStatement)(transaction.createPreparedStatement(delSql, 1));
    OraclePreparedStatement appStmt = null;
    String appSql = AppRoutines.getStampSql(priAppId);
    if (( "Y".equals(updPrintFlag ))&& (appSql != null)) appStmt = (OraclePreparedStatement)transaction.createPreparedStatement(appSql, 1);    
  
    //Declare the input stream array that holds as many elements as
    // there are rows in VO. Each element will contain pdf for an invoice.
    HashMap pdfArray = new HashMap();
    int cnt = 0;
    String rowTemplateId = pageContext.getParameter("templateId");  
    String rowTemplateType = null; 
  
    for ( Row row = docVo.first(); row != null; row = docVo.next())
    {
      // Declare the input and output streams here, to make sure they get reset.
      ByteArrayInputStream bXml = null;       //Holds XML data stream
      ByteArrayOutputStream bPdf = new ByteArrayOutputStream();   //For returning pdf
      ByteArrayInputStream insTemplate = null;

      try
      {
        if (rowTemplateId == null || "".equals(rowTemplateId)){
          rowTemplateId = assignmentEngine(pageContext, webBean, row, priAppId);
        }
        if (rowTemplateId == null)
        {
          if (pageContext.isLoggingEnabled(OAFwkConstants.ERROR))
            pageContext.writeDiagnostics(this, "Error in getting Template for document: " + 
                                          Utilities.getRowValue(row, "TrxNumber"), OAFwkConstants.ERROR);       
          continue;
        }
        OAViewObjectImpl filesVo = (OAViewObjectImpl)am.findViewObject("TemplateFilesVO");
        filesVo.setWhereClauseParams(null);
        filesVo.setWhereClauseParam(0,new Number(Integer.parseInt(rowTemplateId)));
        filesVo.executeQuery();
      
        if ( filesVo.next() != null )
        {
          Row filesRow = (Row) filesVo.getCurrentRow();
          OAViewObject templateVo = (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("TemplatesVO");
          templateVo.setWhereClauseParam(0, new Number(Integer.parseInt(rowTemplateId)));
          templateVo.executeQuery();  

          String type  = (String)templateVo.first().getAttribute("TemplateType");
          rowTemplateType = ( type == null )? "XSLFO": type.toUpperCase();       

          BlobDomain fileData = (BlobDomain)filesRow.getAttribute("FileData");
          insTemplate = new ByteArrayInputStream(fileData.toByteArray());
          
          if ( "RTF".equals(rowTemplateType) )
          {
            RTFProcessor rtfProcessor = new RTFProcessor(insTemplate);
            ByteArrayOutputStream bOutTmplt = new ByteArrayOutputStream();                    
            rtfProcessor.setOutput(bOutTmplt);   
            rtfProcessor.process();
            insTemplate = new ByteArrayInputStream(bOutTmplt.toByteArray());               
          } 
        }
        else
        {
            throw new OAException("AR", "AR_BPA_PREVIEW_NO_TMPLT_FILE");
        }
      }
      catch(Exception e)
      {
        if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
            pageContext.writeDiagnostics(this, "Error in getting template ID or Type.", OAFwkConstants.PROCEDURE); 
        Exception[] error = { e };
        throw OAException.wrapperException(e);
      }               
          
      if ( insTemplate != null)
      {
        try
        {
          XMLDocument xmlDoc =  xmlBuilder.getXML(am, row, rowTemplateId);
          ByteArrayOutputStream bOutXml = new ByteArrayOutputStream();
          xmlDoc.print (bOutXml, "UTF-8"); 
          bXml =  new ByteArrayInputStream(bOutXml.toByteArray()); 
        }
        catch(Exception e)
        {
          if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
              pageContext.writeDiagnostics(this, "Error in getting XML data.", OAFwkConstants.PROCEDURE); 
          throw OAException.wrapperException(e);
        }  
      }

      if ( bXml != null)
      {
        try
        {
          if (!"PDF".equals(rowTemplateType) )
          {
            FOProcessor processor = new FOProcessor();
            processor.setData(bXml);     // set XML input file
            processor.setTemplate(insTemplate); // set XSL input file
            if ( locale != null || !"".equals(locale)){
            	processor.setLocale(locale);
            }
            processor.setOutput(bPdf);  //set (PDF) output file
            processor.setOutputFormat(FOProcessor.FORMAT_PDF);
            processor.setConfig(pr);
            processor.generate();
          }
          else
          {
            FormProcessor fProcessor = new FormProcessor();
            fProcessor.setTemplate(insTemplate);        // Input File (PDF) name
            if ( locale != null || !"".equals(locale)){
            	fProcessor.setLocale(locale);
            }
            fProcessor.setData(bXml);
            fProcessor.setOutput(bPdf);
            if ( !fProcessor.process() )
            {
                throw new OAException("AR","AR_BPA_TM_PRINT_PREVIEW_ERR");
            }
          }
        }
        catch(Exception e)
        {
          if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
              pageContext.writeDiagnostics(this, "Error in getting XML data.", OAFwkConstants.PROCEDURE); 
          Exception[] error = { e };
          throw new OAException("AR",
                 "AR_BPA_TM_PRINT_PREVIEW_ERR" ,null,OAException.SEVERE, error);
        }               
      }

      if ( bPdf != null)
      {
        try
        {
          pdfArray.put(new Integer(++cnt), new ByteArrayInputStream(bPdf.toByteArray()));
          AppRoutines.stampDocument(appStmt, null, row, priAppId, null);          
        }
        catch (Exception exc)
        {
          if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
              pageContext.writeDiagnostics(this, "Error in sending pdf stream to merger.", OAFwkConstants.PROCEDURE); 
          Exception[] error = { exc };
          throw new OAException("AR",
                     "AR_BPA_TM_PRINT_PREVIEW_ERR" ,null,OAException.SEVERE, error);
        }               
      }
    }
    
    if (cnt > 0)
    {
      ByteArrayOutputStream bPdf1 = new ByteArrayOutputStream();  
      InputStream[] bPdfIn = (ByteArrayInputStream[]) pdfArray.values().toArray(new ByteArrayInputStream[cnt]) ;
      
      try
      {
        // Initialize PDFDocMerger
        PDFDocMerger docMerger = new PDFDocMerger(bPdfIn, bPdf1);

        // Merge PDF Documents and generates new PDF Document
        docMerger.process();
        docMerger = null;
        if ( appStmt != null)
        {
          appStmt.sendBatch();
          appStmt.close();
        }

        if (delStmt != null)
        {
          delStmt.setInt(1, Integer.parseInt(requestId));
          delStmt.execute();  
          delStmt.close();                  
        }
        transaction.commit();
    ServletOutputStream os = null;
    try
    {
       // Get a handle to the HttpResponse Object 
       DataObject sessionDictionary = 
              (DataObject)pageContext.getNamedDataObject("_SessionParameters");    
       HttpServletResponse response = 
              (HttpServletResponse)sessionDictionary.selectValue(null,"HttpServletResponse");  
 
       os = response.getOutputStream();
       response.resetBuffer();
       response.setContentType("application/pdf");

       // Added for bug 18070318 - begin 
       if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
         pageContext.writeDiagnostics(this, "Setting the response header to open as attachment", OAFwkConstants.STATEMENT);
       response.setHeader("Content-Disposition", "attachment; filename=preview.pdf") ;
       // Added for bug 18070318 - end
      
       response.setContentLength(bPdf1.size());
       os.write(bPdf1.toByteArray(), 0, bPdf1.size());
       // restore content type to original....else html rendered by cabo will get downloaded!!
       // response.setContentType("text/html");
       os.flush();
       os.close();
    }
    catch (Exception e)
    {
      if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
         pageContext.writeDiagnostics(this, "Error Generating Pdf", OAFwkConstants.PROCEDURE); 
      Exception[] error = { e };
      throw new OAException("AR",
        "AR_BPA_TM_PRINT_PREVIEW_ERR" ,null,OAException.SEVERE, error);
    }
    finally
    {
      if ( os != null)
      {
        try { os.close(); } catch(Exception e) {}
      }
    }

        BlobDomain newBlob = new BlobDomain(); 
        newBlob.setBytes(bPdf1.toByteArray());
        AppRoutines.storeBillDocument(pageContext, newBlob, requestId, priAppId);
     
        bPdf1 = null;
        bPdfIn = null;      
        newBlob = null;        
        transaction.commit();        
      }
      catch(Exception exc)
      {
        if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
            pageContext.writeDiagnostics(this, "Error in pdf merger.", OAFwkConstants.PROCEDURE);
        Exception[] error = { exc };
        throw new OAException("AR",
                     "AR_BPA_TM_PRINT_PREVIEW_ERR" ,null,OAException.SEVERE, error);
      }
      finally
      {
        if ( appStmt != null)
        {
          try { appStmt.close(); } catch(Exception e) {}
        }
        if (delStmt != null )
        {
          try { delStmt.close(); } catch(Exception ex) {}
        }
      }      
    }     
  } 
    //Added for R12 upgrade retrofit
    // The only thing added to this class for OD is the showODInvoice method and call to it in processRequest
    public boolean showODInvoice(OAPageContext oapagecontext, OAWebBean oawebbean) 
    {
        String sViewType = oapagecontext.getParameter("ViewType");
        if(sViewType == null || !sViewType.equals("PRINT")) return false;

        String sCustomerTrxId = oapagecontext.getParameter("CustomerTrxId");
        String sConsBill = oapagecontext.getParameter("ConsInvId");
        String sTrxNumber = oapagecontext.getParameter("trxNumber");
        if (sConsBill!=null) {
          sCustomerTrxId = "-" + sConsBill;
          sTrxNumber = sConsBill;
        }
        Serializable[] parameters = { sCustomerTrxId };
        Class[] paramTypes = { String.class };
        OAApplicationModule am = (OAApplicationModule)oapagecontext.getApplicationModule(oawebbean);
    byte[] baPDF = null;
		try {
			baPDF = (byte[])am.invokeMethod("GetInvoiceBytes", parameters, paramTypes);
		} catch (Exception exc) {
          try{
                oapagecontext.writeDiagnostics(this, "Invokng GetInvoiceBytes got exception : "+exc.getMessage(), OAFwkConstants.ERROR);
                oapagecontext.sendRedirect("/XXFIN_HTML/iRecContactUsLinks.htm");
          } 
          catch (Exception ee){} 			
		}
    String pdfCopyReqId = (String)((OADBTransactionImpl)oapagecontext.getRootApplicationModule().getOADBTransaction()).getValue("PDF_REQ_ID");
    String isPdfCopyDuplicateReq = (String)((OADBTransactionImpl)oapagecontext.getRootApplicationModule().getOADBTransaction()).getValue("IS_PDF_REQ_DUPL");
      
    if(pdfCopyReqId != null) 
    {
      String nValue = null;
     // ((OADBTransactionImpl)oapagecontext.getRootApplicationModule().getOADBTransaction()).putValue("PDF_REQ_ID", nValue);
      pdfCopyReqId = pdfCopyReqId.trim();
    }
    if(isPdfCopyDuplicateReq != null) 
    {
      isPdfCopyDuplicateReq = isPdfCopyDuplicateReq.trim();
    }
    oapagecontext.writeDiagnostics(this, "PDF Copy Request Id "+pdfCopyReqId, OAFwkConstants.STATEMENT);
		HashMap hMap = null;

		if (baPDF == null && pdfCopyReqId != null)  {

    hMap = new HashMap();
		hMap.put("IsPDFCopyReq", "Y");
    hMap.put("IsPDFCopyDuplicateReq", isPdfCopyDuplicateReq);
    
    // For Consolidated, we need to display all child requests in 'View Concurrent Requests' page
    // as the output (Consolidated Invoice) can show in Child request. So, send it as parentRequest
    // The subsequent code (handle this) is in "od.oracle.apps.fnd.cp.viewreq.webui.ODViewRequestsPageCO"
     hMap.put("trxNumber",sTrxNumber);
     hMap.put("customerTrxId", sCustomerTrxId);
    if (sConsBill!=null) 
    {
      hMap.put("parentRequestId", pdfCopyReqId); // For Consolidated Invoice
      hMap.put("IsIrecConsolidateInvoice", "Y");
    } else {
      hMap.put("requestId",pdfCopyReqId);
    }


     oapagecontext.setForwardURL("FNDCPVIEWREQUEST",
                                    KEEP_MENU_CONTEXT,
                                    null, // "IMC_NG_MAIN_MENU",
                                    hMap,
                                    false,
                                    ADD_BREAD_CRUMB_NO,
                                    IGNORE_MESSAGES);
 
		  return true;
		}	else if (baPDF == null || baPDF.length == 0)  {
      try{
			oapagecontext.writeDiagnostics(this, "Invokng GetInvoiceBytes() - returned value pdfb blob lenght is 0", OAFwkConstants.ERROR);
            oapagecontext.sendRedirect("/XXFIN_HTML/iRecContactUsLinks.htm");
            
          } 
      catch (Exception ee){}    
      return true;
    }
    else {

        try
        {
          //ServletResponse response = oapagecontext.getRenderingContext().getServletResponse();
          //OutputStream o = response.getOutputStream();
          //o.write(baPDF);
          //o.flush();
          //o.close();
          // if (baPDF.length==0) throw new Exception();

          DataObject dataobject = oapagecontext.getNamedDataObject("_SessionParameters");
          HttpServletResponse httpservletresponse = (HttpServletResponse)dataobject.selectValue(null, "HttpServletResponse");
          ServletOutputStream servletoutputstream = httpservletresponse.getOutputStream();
          httpservletresponse.setContentType("application/pdf");
          httpservletresponse.setContentLength(baPDF.length);
          servletoutputstream.write(baPDF, 0, baPDF.length);
          servletoutputstream.flush();
          servletoutputstream.close();// *important* to ensure no more jsp output
          return true;
        }
        catch(Exception ex)
        {
          try{
                          oapagecontext.sendRedirect("/XXFIN_HTML/iRecContactUsLinks.htm");
                          } 
          catch (Exception ee){} 
        }
        return true;

    }
  }
}
