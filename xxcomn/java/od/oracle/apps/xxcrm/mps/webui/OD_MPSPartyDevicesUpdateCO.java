/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.mps.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import java.io.Serializable;
import oracle.apps.fnd.framework.webui.beans.table.OAAdvancedTableBean;
import oracle.apps.fnd.framework.webui.beans.table.OAColumnBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;
import oracle.apps.fnd.framework.webui.OADataBoundValueViewObject;
/**
 * Controller for ...
 */
public class OD_MPSPartyDevicesUpdateCO extends OAControllerImpl
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
    OAApplicationModule mpsPartyDevicesAM = pageContext.getApplicationModule(webBean);
    OAAdvancedTableBean table = (OAAdvancedTableBean)webBean.findIndexedChildRecursive("CurrentCountTL");
    OAColumnBean colorcol = (OAColumnBean)webBean.findIndexedChildRecursive("ColorCol");
    System.out.println("colorcol="+colorcol);
    OAMessageStyledTextBean color = (OAMessageStyledTextBean)colorcol.findIndexedChildRecursive("Color");
    System.out.println("color="+color);
    OADataBoundValueViewObject cssjob = new OADataBoundValueViewObject(color,"Fillcolor");
    System.out.println("cssjob="+cssjob);
    color.setAttributeValue(oracle.cabo.ui.UIConstants.STYLE_CLASS_ATTR, cssjob);

    if(pageContext.getParameter("serialNo") != null){
    String serialNo =  pageContext.getParameter("serialNo");
    Serializable[] params = {serialNo};
    mpsPartyDevicesAM.invokeMethod("initFetchSerialNo",params);
    mpsPartyDevicesAM.invokeMethod("initDevicesColorCount",params);
    mpsPartyDevicesAM.invokeMethod("initColorTonerCount",params); 
    if(pageContext.getParameter("partyId") != null){
    String partyId =  pageContext.getParameter("partyId");
    Serializable[] param = {serialNo,partyId};
    mpsPartyDevicesAM.invokeMethod("initDevicesMargin",param);
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
    OAApplicationModule mpsPartyDevicesAM = pageContext.getApplicationModule(webBean);
    if(pageContext.getParameter("Save") != null)
    {
      mpsPartyDevicesAM.invokeMethod("saveData");
      throw new OAException("XXCRM","OD_CRM_MPS_SAVED",null,OAException.INFORMATION,null);
    }    

    if("Back".equals(pageContext.getParameter(EVENT_PARAM))){
      com.sun.java.util.collections.HashMap params = new com.sun.java.util.collections.HashMap(2);
      params.put("partyName",pageContext.getParameter("partyName"));
      params.put("partyId",pageContext.getParameter("partyId"));
//      params.put("serialNo",pageContext.getParameter("serialNo"));
      System.out.println("##### In BACK partyName="+pageContext.getParameter("partyName"));
      System.out.println("##### In BACK serialNo="+pageContext.getParameter("serialNo"));
      pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxcrm/mps/webui/OD_MPSPartyDevicesPG",
                                null,
                                OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                null,
                                params,
                                false, // Retain AM
                                OAWebBeanConstants.ADD_BREAD_CRUMB_NO, OAWebBeanConstants.IGNORE_MESSAGES);      

    }
    if("colorDetails".equals(pageContext.getParameter(EVENT_PARAM))){
    System.out.println("##### in EVENT colorDetails");
    pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxcrm/mps/webui/OD_MPSPartyDevicesColorCountPG",
                                null,
                                OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                null,
                                null,
                                false, // Retain AM
                                OAWebBeanConstants.ADD_BREAD_CRUMB_NO, OAWebBeanConstants.IGNORE_MESSAGES);     
    }
    
    
  }

}
