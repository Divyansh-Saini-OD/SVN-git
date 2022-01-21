<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<!DOCTYPE HTML>><HTML><HEAD>
<META content="text/html; charset=utf-8" http-equiv="Content-Type"></HEAD>
<BODY><PRE>/*===========================================================================+
 |   Copyright (c) 2001, 2003 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.cdh.extension.webui;

import com.sun.java.util.collections.HashMap;

import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import java.io.Serializable;
import java.util.Vector;
import java.lang.Class;
import oracle.jbo.common.Diagnostic;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.apps.fnd.framework.webui.beans.table.OATableFooterBean;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.ego.extfwk.user.presentation.webui.EgoExtFwkUserRenderer;
import oracle.apps.ego.extfwk.util.Pages;
import com.sun.java.util.collections.ArrayList;
import oracle.apps.fnd.framework.webui.beans.form.OAFormValueBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.common.VersionInfo;
import oracle.jbo.domain.Number;
import oracle.jbo.Row;
import oracle.apps.fnd.framework.webui.OAWebBeanHelper;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.apps.ego.extfwk.util.EgoExtFwkUtil;
import oracle.jbo.AttributeDef;

/**
 * Controller for HzPuiOrgProfileExt
 */
public class ODAttributeExtRnCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header: /home/cvs/repository/Office_Depot/SRC/CRM/E0255_CDHAdditionalAttributes/3.\040Source\040Code\040&amp;\040Install\040Files/FilesForSVN/ODAttributeExtRnCO.java,v 1.1 2007/06/29 08:54:48 vjmohan Exp $";
  public static final boolean RCS_ID_RECORDED =
         VersionInfo.recordClassVersion(RCS_ID, "oracle.apps.ar.hz.components.extension.webui");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
    //get am
    OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);


    //Step 1
    // Set up User-Defined Attributes Framework to render the AG
    EgoExtFwkUserRenderer extFwkRenderer = new EgoExtFwkUserRenderer();

    //Step 2: Set the classification
    String classCode = pageContext.getParameter("HzPuiExtClass");
    if(classCode==null)
    {
      classCode = "ADMIN_DEFINED";
    }
    extFwkRenderer.setClassificationCode(pageContext, classCode);
	String EntGroup =  pageContext.getParameter("EntGroup");
	String EntKey = pageContext.getParameter("EntKey");
	String EOClass = pageContext.getParameter("EOClass");
	String VOClass = pageContext.getParameter("VOClass");
	String EntIntName = pageContext.getParameter("EntIntName");
	if (EntIntName == null || (EntIntName != null &amp;&amp; EntIntName.length()==0 ))
	{
		EntIntName=EntGroup;
	}

    extFwkRenderer.setParentObjectValues(pageContext,
                                         EntIntName,
					 					 new String[] {EntKey},
                                         Boolean.TRUE,
                                         Boolean.TRUE,
                                         Boolean.FALSE);

    pageContext.putTransactionValue("dispType", new String("INLINE"));

    //Step 3: Set data object
    extFwkRenderer.setDataLevelValues(pageContext, null);

    //Step 4: Set VO/EO

    extFwkRenderer.setEOandVONames(pageContext,
                                   new String[][] {{EntGroup,
                                   EOClass,
                                   VOClass}});

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
       pageContext.putTransactionTransientValue("EgoExtAMPath", new String(extAMPath + "."+ "ODExtAttributeGenericAM"));


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

         OAMessageChoiceBean pagePoplist = (OAMessageChoiceBean)webBean.findChildRecursive("HzOrgExtPageList");
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
                  sPageId = ((Pages)(pageList.get(0))).getPageId(); //Get it from pageList
                  pagePoplist.setDefaultValue(sPageId);
                }
                if(sPageId !=null) {
                    pagePoplist.setValue(pageContext,sPageId); 
                }
              }
              //set the pageId in the pageContext for the ego region.
              pageContext.putParameter("pageId", sPageId);
              pageContext.getPageLayoutBean().prepareForRendering(pageContext);
              OAFormValueBean pageIdAsFormValueBean = (OAFormValueBean) webBean.findIndexedChildRecursive("pageIdAsFormValue");
              pageIdAsFormValueBean.setValue(pageContext, sPageId);
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
    OAApplicationModule am = pageContext.getRootApplicationModule();
    OAMessageChoiceBean pagePoplist = (OAMessageChoiceBean)webBean.findChildRecursive("HzOrgExtPageList");
    String pageName = pagePoplist.getSelectionText(pageContext).trim();    
    am.getOADBTransaction().putTransientValue("pageName", pageName);
    pageContext.putParameter("pageName", pageName);
    if("HzExtPagePoplistChange".equals(pageContext.getParameter("event")))
    {
     HashMap params = new HashMap();
     params.put("HzPuiExtPageId",pagePoplist.getValue(pageContext).toString());

     //Defect# 11538 -- Make SPC Attribute read only for selected roles
     if("SPC Card Information".equals(pageName) 
        &amp;&amp; "Y".equals(pageContext.getParameter("SPCView"))
       )
     {
       params.put("HzPuiExtMode","VIEW");
     }else
     {
       params.put("HzPuiExtMode","UPDATE");
     }
     //End of Defect# 11538 modifications
              pageContext.setForwardURLToCurrentPage(params,
                                               true, // retain the AM
                                               pageContext.getBreadCrumbValue(),
                                               IGNORE_MESSAGES);
    }
    if("ACH Sending ID".equals(pageName)) {
      am.getOADBTransaction().putTransientValue("achPageId","Y");
      am.getOADBTransaction().putTransientValue("paccountId",pageContext.getParameter("EntKey"));
    }
    else {
      am.getOADBTransaction().putTransientValue("achPageId","N");
    }
    if("Billing Documents".equals(pageName))
    {
      am.getOADBTransaction().putTransientValue("BillDocsPageId","Y");
      
    if("addRows".equals(pageContext.getParameter("event")))
    {
            OAWebBean rootBean = pageContext.getRootWebBean();
            OATableBean tableRN = (OATableBean)rootBean.findChildRecursive("BILLDOCS");
            OAViewObject vo = (OAViewObject)pageContext.getRootApplicationModule().findViewObject(tableRN.getViewUsageName());
            if(pageContext.getRootApplicationModule().getOADBTransaction().isDirty())
            {
              throw new OAException("Please Save or Revert Changes before you Add Another Row");
            }
    }
    }
    else
    {
      am.getOADBTransaction().putTransientValue("BillDocsPageId","N");
    }
  }


}
</PRE></BODY></HTML>
