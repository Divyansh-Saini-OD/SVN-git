/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxmer.scdashboard.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import java.io.Serializable;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;

import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;
import oracle.apps.fnd.framework.webui.OADataBoundValueViewObject;
//import oracle.apps.fnd.framework.OAException;


/**
 * Controller for ...
 */
public class ODSCDashboardCO extends OAControllerImpl
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
    super.processRequest(pageContext, webBean);
    System.out.println("#### processRequest");
    String inspectionNo = null;
    // Code for making the grade color code filling in UI.
    OATableBean auditTableBean = (OATableBean)webBean.findIndexedChildRecursive("AuditResults");
    OAMessageStyledTextBean grade = (OAMessageStyledTextBean)auditTableBean.findIndexedChildRecursive("InspectionGrade");
    OADataBoundValueViewObject cssGrade = new OADataBoundValueViewObject(grade,"Color");
    grade.setAttributeValue(oracle.cabo.ui.UIConstants.STYLE_CLASS_ATTR, cssGrade); 
    
    OAApplicationModule odscAM = (OAApplicationModule)pageContext.getApplicationModule(webBean);
    OATableBean inspectionTblBean = (OATableBean)webBean.findChildRecursive("InspectionDetails");
    OAHeaderBean indpectionHDR = (OAHeaderBean)webBean.findChildRecursive("InspectionHDR");
    indpectionHDR.setRendered(false);
    if(pageContext.getParameter("inpectionNo")!=null){
     inspectionNo = pageContext.getParameter("inpectionNo");
     Serializable[] params = {inspectionNo};
    System.out.println("#### processRequest inspectionNo="+inspectionNo);
    indpectionHDR.setRendered(true);
    String hdrText = "Inspection Details ("+inspectionNo+")";
    indpectionHDR.setText(pageContext,hdrText);
    odscAM.invokeMethod("initInspectionDetails",params);
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
    System.out.println("#### processFormRequest");
    com.sun.java.util.collections.HashMap  addParams = new com.sun.java.util.collections.HashMap(1);
    String venName = null;
    String venNumber = null;
    String facName =  null;
    String facNumber = null;
    int searchParams = 0;
    OAApplicationModule odscAM = (OAApplicationModule)pageContext.getApplicationModule(webBean);
    if(pageContext.getParameter("Go")!=null)
    {
     if(pageContext.getParameter("VendorNameLOV")!=null && !"".equals(pageContext.getParameter("VendorNameLOV"))){
       venName = pageContext.getParameter("VendorNameLOV");
       searchParams++;
     }
     if(pageContext.getParameter("VendorNumberLOV")!=null && !"".equals(pageContext.getParameter("VendorNumberLOV")))   {    
       venNumber = pageContext.getParameter("VendorNumberLOV");
       searchParams++;
     }
     if(pageContext.getParameter("ODSCFactoryNameLOV")!=null && !"".equals(pageContext.getParameter("ODSCFactoryNameLOV")))       {
       facName = pageContext.getParameter("ODSCFactoryNameLOV");
       searchParams++;
     }
     if(pageContext.getParameter("ODSCFactoryNumberLOV")!=null && !"".equals(pageContext.getParameter("ODSCFactoryNumberLOV")))     {  
       facNumber = pageContext.getParameter("ODSCFactoryNumberLOV");
       searchParams++;
     }
     if(searchParams > 0){
      Serializable[] params = {venName,venNumber,facName,facNumber};
      odscAM.invokeMethod("initVendorFactoryDetails",params);
      odscAM.invokeMethod("initAuditHistory",params);

//      com.sun.java.util.collections.HashMap  addParams = new com.sun.java.util.collections.HashMap(1);
      addParams.put("inpectionNo",null);
//      System.out.println("#### PFR--");
      pageContext.forwardImmediatelyToCurrentPage(addParams,true,null);
     }
     
    }

    if (pageContext.getParameter("Clear") != null)
    { 
     addParams.put("inpectionNo",null);
     pageContext.forwardImmediatelyToCurrentPage(addParams,false,null); 
    }

    if("getInspectionNo".equals(pageContext.getParameter(EVENT_PARAM)))
    {
      String inpectionNo = pageContext.getParameter("OdScInspectionNo");
      addParams.put("inpectionNo",inpectionNo);
      System.out.println("Date passed to PR:"+inpectionNo);
      pageContext.forwardImmediatelyToCurrentPage(addParams,true,null);
    }
  }

}
