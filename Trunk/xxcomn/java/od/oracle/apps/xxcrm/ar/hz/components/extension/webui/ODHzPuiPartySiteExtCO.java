/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODHzPuiPartySiteExtCO.java                                    |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Region Controller for Party Site Extensible                            |
 |           Attributes HzPuiPartySiteExtRN                                  |
 |                                                                           |
 |  NOTES                                                                    |
 |         Used for the displaying the Extensible Attributes                 |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    No dependencies.                                                       |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |   14-Nov-2007 Jasmine Sujithra   Created                                  |
 |                                                                           |
 +===========================================================================*/

package od.oracle.apps.xxcrm.ar.hz.components.extension.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import oracle.apps.fnd.framework.OAViewObject;
import oracle.jbo.RowSetIterator;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAFwkConstants;

import com.sun.java.util.collections.ArrayList;
import java.io.Serializable;
import java.lang.Class;
import oracle.apps.ego.extfwk.user.presentation.webui.EgoExtFwkUserRenderer;
import oracle.apps.ego.extfwk.util.Pages;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.beans.form.OAFormValueBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.jbo.common.Diagnostic;
import oracle.apps.ar.hz.components.extension.server.HzExtPageListVORowImpl;



/**
 * Controller for ...
 */
public class ODHzPuiPartySiteExtCO extends OAControllerImpl
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
    final String METHOD_NAME = "od.oracle.apps.xxcrm.ar.hz.components.extension.webui.ODHzPuiPartySiteExtCO.processRequest"; 
    
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);

    
     if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processRequest(pageContext, webBean);
     //get am
    OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);

    //get party_site_id
    String partySiteId = pageContext.getParameter("HzPuiExtEntityId");
    Diagnostic.println("Inside HzPuiPartySiteExtCO. partySiteId =" + partySiteId);
    if(partySiteId==null)
    {
      throw new OAException("HzPuiPartySiteExtCO: partySiteId is not passed", OAException.ERROR);
    }
    pageContext.putTransactionTransientValue("HzPuiExtEntityId", partySiteId);

    //Step 1
    // Set up User-Defined Attributes Framework to render the AG
    EgoExtFwkUserRenderer extFwkRenderer = new EgoExtFwkUserRenderer();

    //Step 2: Set the classification
    String classCode = pageContext.getParameter("HzPuiExtClass");
    if(classCode==null)
    {
      classCode = "ADMIN_DEFINED";
    }
    Diagnostic.println("Inside HzPuiPartySiteExtCO. classCode =" + classCode);
    extFwkRenderer.setClassificationCode(pageContext, classCode);

    extFwkRenderer.setParentObjectValues(pageContext,
                                         "HZ_PARTY_SITES",
                                         new String[] {partySiteId},
                                         Boolean.TRUE,
                                         Boolean.TRUE,
                                         Boolean.FALSE);

    pageContext.putTransactionValue("dispType", new String("INLINE"));

    //Step 3: Set data object
    extFwkRenderer.setDataLevelValues(pageContext, null);

    //Step 4: Set VO/EO
    extFwkRenderer.setEOandVONames(pageContext,
                                   new String[][] {{"HZ_PARTY_SITES_GROUP",
                                   "oracle.apps.ar.hz.components.extension.server.HzPartySiteExtEO",
                                   "oracle.apps.ar.hz.components.extension.server.HzPartySiteExtVO"}});

    String extMode = pageContext.getParameter("HzPuiExtMode");
    if(extMode==null)
    {
      extMode = "UPDATE";
    }
    pageContext.putParameter("mode",extMode);


    /* am path */

       String extAMPath = pageContext.getParameter("HzPuiExtAMPath");
       if(extAMPath==null)
       {
         extAMPath = "ImcRootAM";
       }
       pageContext.putTransactionTransientValue("EgoExtAMPath", new String(extAMPath + ".HzPartySiteExtAM"));


    ArrayList pageList = extFwkRenderer.getPageLinks(pageContext);

    //Run rest of the code(logic) only if the pages are found.
    if ( pageList.size() == 0 )
    {
      webBean.setRendered(false);
    }else
    {
         //Code to intialize the Page List VO used by the Drop Down.
         Serializable[] paramPageList =  { pageList };
         Class[] clsPageList = { pageList.getClass() };
         am.invokeMethod("makePageList",paramPageList, clsPageList);



          /* Custom Code to restrict the values in the Extensible Attributes Group pop list */
      if ("Y".equalsIgnoreCase(pageContext.getParameter("ODSiteAttributeGroup")))
      {
          pageContext.writeDiagnostics(METHOD_NAME, "ODSiteAttributeGroup is Y", OAFwkConstants.PROCEDURE);         
          OAViewObject attributeGroupVO  = (OAViewObject)am.findViewObject("ODSiteAttributeGroupVO");
          if (attributeGroupVO == null)
          {
            attributeGroupVO = (OAViewObject)am.createViewObject("ODSiteAttributeGroupVO","od.oracle.apps.xxcrm.asn.common.customer.server.ODSiteAttributeGroupVO");
          }
          attributeGroupVO.executeQuery();
          
      
          OAViewObject HzExtPageListVO  = (OAViewObject)am.findViewObject("HzExtPageListVO");
          RowSetIterator attributegroupItr =null;
          RowSetIterator pagelistItr = null;
          OAViewRowImpl pagelistrow = null;
          OAViewRowImpl attributegrouprow = null;
          if (HzExtPageListVO != null)
          {  
              int startCount = HzExtPageListVO.getFetchedRowCount();
              String strStartCount =startCount + "";
              pageContext.writeDiagnostics(METHOD_NAME, "Start Row Count : " + strStartCount, OAFwkConstants.STATEMENT);
              
              pagelistItr = HzExtPageListVO.findRowSetIterator("PageListIterator");
              if(pagelistItr==null)
                  pagelistItr = HzExtPageListVO.createRowSetIterator("PageListIterator");
              else
                  pagelistItr.reset();

              if(pagelistItr!=null)
              {      
                  String extpageid = null;
                  String extpagename =null;
                  while(pagelistItr.hasNext())
                  {
                    pagelistrow = (OAViewRowImpl)pagelistItr.next();
                    if(pagelistrow!=null)
                    {
                      extpageid = pagelistrow.getAttribute("ExtPageId").toString();
                      extpagename = pagelistrow.getAttribute("ExtPageName").toString();
                      boolean delstatus =true;
                       
                      if (isStatLogEnabled)
                      {
                            StringBuffer buf = new StringBuffer(100);
                            buf.append("  pagelistrow.ExtPageId : ");
                            buf.append(extpageid);
                            buf.append("  pagelistrow.ExtPageName : ");
                            buf.append(extpagename);
                            pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
                      }

                      if(attributeGroupVO!=null) 
                      {
                          attributegroupItr = attributeGroupVO.findRowSetIterator("AttributeGroupIterator");
                          if(attributegroupItr==null)
                              attributegroupItr = attributeGroupVO.createRowSetIterator("AttributeGroupIterator");
                          else
                              attributegroupItr.reset();
                      }
                      
                      if(attributegroupItr!=null)
                      {
                          String attpageid = null;
                          String attpagename = null;
                          while(attributegroupItr.hasNext())
                          {
                              attributegrouprow = (OAViewRowImpl)attributegroupItr.next();
                              if(attributegrouprow!=null)
                              {
                                  attpageid = attributegrouprow.getAttribute("PageId").toString();
                                  attpagename =  attributegrouprow.getAttribute("Meaning").toString();
                                  if (isStatLogEnabled)
                                  {
                                     
                                      StringBuffer buf = new StringBuffer(100);
                                      buf.append("  attributegrouprow.PageId : ");
                                      buf.append(attpageid);
                                      buf.append("  attributegrouprow.Meaning : ");
                                      buf.append(attpagename);
                                      pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
                                    
                                  }
                                  if(attpageid.equals(extpageid))
                                  {
                                      delstatus = false;                                      
                                      break;
                                  }
                              }
                          }
                          attributegroupItr.closeRowSetIterator();
                      }
                      if (delstatus )
                      {                             
                          pagelistItr.removeCurrentRow();
                      }		
                    }
                  }
                }
                pagelistItr.closeRowSetIterator();
              }
              int endCount = HzExtPageListVO.getFetchedRowCount();
              String strEndCount =endCount + "";
              pageContext.writeDiagnostics(METHOD_NAME, "End Row Count : " + strEndCount, OAFwkConstants.STATEMENT);
              
          }


         

         OAMessageChoiceBean pagePoplist = (OAMessageChoiceBean)webBean.findChildRecursive("HzPartySiteExtPageList");
         if(pagePoplist!=null)
         {
              String sPageId = pageContext.getParameter("HzPuiExtPageId");
              //check to render the poplist or not
              String renderPagePoplist = pageContext.getParameter("HzPuiExtAMPath");
              if("N".equals(renderPagePoplist))
              {
                pagePoplist.setRendered(false);
              }
              else
              {
                pagePoplist.setRequiredIcon("no");
                if(sPageId == null){ // if the page id is not passed
                  //check the value in the drop down.
                  sPageId = pagePoplist.getSelectionValue(pageContext);
                }
                if ( sPageId == null ) //If the value is not selected from the Drop down
                {
                  //Get the first PageId from the pageList and set it as the default
                  //for the droplist
                  //sPageId = ((Pages)(pageList.get(0))).getPageId(); //Get it from pageList              
                  //pagePoplist.setDefaultValue(sPageId);
                  pagePoplist.setSelectedIndex(0);
                  //sPageId = pagePoplist.getSelectedValue();
                  OAViewObject HzExtPageListVO  = (OAViewObject)am.findViewObject("HzExtPageListVO");
                   if ( HzExtPageListVO != null) 
                  { 
                    if ((HzExtPageListVO.getFetchedRowCount()) >0) 
                    {
                      HzExtPageListVORowImpl cRow = (HzExtPageListVORowImpl)HzExtPageListVO.first();
                      Object extPageId = (Object)cRow.getAttribute("ExtPageId");
                      if (extPageId != null)
                      sPageId = (String)extPageId;
                    }
                  }
                  pageContext.writeDiagnostics(METHOD_NAME, "sPageId : " + sPageId , OAFwkConstants.STATEMENT);
                }
              }
              if (sPageId != null)
              {
              //set the pageId in the pageContext for the ego region.
              pageContext.putParameter("pageId", sPageId);

              pageContext.getPageLayoutBean().prepareForRendering(pageContext);
              OAFormValueBean pageIdAsFormValueBean = (OAFormValueBean) webBean.findIndexedChildRecursive("pageIdAsFormValue");
              pageIdAsFormValueBean.setValue(pageContext, sPageId);
              }
              else
              {
                webBean.setRendered(false);
              }
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
    if("HzExtPagePoplistChange".equals(pageContext.getParameter("event")))
    {
              pageContext.setForwardURLToCurrentPage(null,
                                               true, // retain the AM
                                               pageContext.getBreadCrumbValue(),
                                               IGNORE_MESSAGES);
    }

  }

}
