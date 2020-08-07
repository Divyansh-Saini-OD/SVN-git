/*===========================================================================+
 |      		      Office Depot - TDS Parts                                   |
 |                Oracle Consulting Organization, Redwood Shores, CA, USA    |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             OD_MPSCustomerLocationUpdateCO.java                                      |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Class to get the Party Contact Details from the database.              |
 |                                                                           |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |                                                                           |
 |  HISTORY                                                                  |
 | Ver  Date       Name           Revision Description                       |
 | ===  =========  ============== ===========================================|
 | 1.0  03-OCT-12  Suraj Charan   Initial.                                   |
 |                                                                           |
 |                                                                           |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxcrm.mps.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;

import java.io.Serializable;
/**
 * Controller for ...
 */
public class OD_MPSCustomerLocationUpdateCO extends OAControllerImpl
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
    OAApplicationModule mpsCustContAM = pageContext.getApplicationModule(webBean);
      System.out.println("##### In OD_MPSCustomerLocationUpdateCO PR location="+ pageContext.getParameter("location"));
      System.out.println("##### In OD_MPSCustomerLocationUpdateCO PR device id="+ pageContext.getParameter("deviceId"));
      System.out.println("##### In OD_MPSCustomerLocationUpdateCO PR partyId="+ pageContext.getParameter("partyId"));    
      System.out.println("##### In OD_MPSCustomerLocationUpdateCO PR address="+ pageContext.getParameter("address"));    
    if(pageContext.getParameter("location") != null)
    {
      OAHeaderBean hdrBean = (OAHeaderBean)webBean.findChildRecursive("CustLocationUpdateHDR");
      if(hdrBean != null)
      {
        hdrBean.setText(hdrBean.getText(pageContext)+": "+pageContext.getParameter("location"));
      }
    }    
    OAViewObject mpsCustLocUpdateVO = (OAViewObject)mpsCustContAM.findViewObject("OD_MPSCustLocationUpdateVO");
//    OAViewObject mpsCustLocUpdateVO = (OAViewObject)mpsCustContAM.findViewObject("TestVO");
//    OAViewObject mpsCustLocUpdateVO = (OAViewObject)mpsCustContAM.findViewObject("OD_MPSLocUpdateVO");
    
//    mpsCustContVO.setWhereClause("PARTY_NAME = '" + partyName+"'");
//    mpsCustLocUpdateVO.setWhereClause("DEVICE_LOCATION = '" + pageContext.getParameter("location")+"' AND 
    mpsCustLocUpdateVO.setWhereClause("DEVICE_ID = '"+pageContext.getParameter("deviceId")+"' AND PARTY_ID ="+pageContext.getParameter("partyId"));
//    mpsCustLocUpdateVO.setWhereClauseParam(0,pageContext.getParameter("location"));
    System.out.println("##### In OD_MPSCustomerLocationUpdateCO PR Location Update Query="+mpsCustLocUpdateVO.getQuery());
    pageContext.writeDiagnostics(this,"##### In OD_MPSCustomerLocationUpdateCO PR Location Update Query="+mpsCustLocUpdateVO.getQuery(),1);
    mpsCustLocUpdateVO.executeQuery();    
    System.out.println("##### In OD_MPSCustomerLocationUpdateCO PR Row Count Location update="+ mpsCustLocUpdateVO.getRowCount());
    pageContext.writeDiagnostics(this,"##### In OD_MPSCustomerLocationUpdateCO PR Row Count Location update="+ mpsCustLocUpdateVO.getRowCount(),1);
//    OAViewObject mpsCurrLevelsVO = (OAViewObject)mpsCustContAM.findViewObject("OD_MPSCurrentLevelsVO");    
//    mpsCurrLevelsVO.executeQuery();
    
    Serializable[] params = {pageContext.getParameter("serialNo").toString()};
//    Serializable[] params = {"JPCCB5R00G"}; //remove hard-code
    mpsCustContAM.invokeMethod("initCurrentLevel",params);
    mpsCustContAM.invokeMethod("initCurrentCount",params);
//    OAViewObject mpsCurrCountVO = (OAViewObject)mpsCustContAM.findViewObject("OD_MPSCurrentCountVO");    
//    mpsCurrCountVO.executeQuery();
//    pageContext.putParameter("serialNo",pageContext.getParameter("serialNo").toString()); 
    System.out.println("##### LocationUpdateCO from="+pageContext.getParameter("FROM"));
    if(pageContext.getParameter("FROM") != null && "SERIALN0".equals(pageContext.getParameter("FROM")))
    pageContext.putSessionValue("FROM",pageContext.getParameter("FROM").toString());
    if(pageContext.getParameter("FROM") != null && "SERIALN0LINK".equals(pageContext.getParameter("FROM")))
    pageContext.putSessionValue("FROM",pageContext.getParameter("FROM").toString());
    if(pageContext.getParameter("FROM") != null && "ADDRESSLINK".equals(pageContext.getParameter("FROM"))){
    pageContext.putSessionValue("FROM",pageContext.getParameter("FROM").toString());    
    pageContext.putSessionValue("address", pageContext.getParameter("address"));
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
    OAApplicationModule mpsCustContAM = pageContext.getApplicationModule(webBean);
    if(pageContext.getParameter("Save") != null)
    {
      mpsCustContAM.invokeMethod("saveData");
      throw new OAException("XXCRM","OD_CRM_MPS_SAVED",null,OAException.INFORMATION,null);
    }
//    if(pageContext.getParameter("Back") != null){
    if("Back".equals(pageContext.getParameter(EVENT_PARAM))){
      com.sun.java.util.collections.HashMap params = new com.sun.java.util.collections.HashMap(2);
      params.put("partyId",pageContext.getParameter("partyId"));
      params.put("location",pageContext.getParameter("location"));
      
      
      String page = null;
      System.out.println("##### PFR locationupdateco FROM="+pageContext.getSessionValue("FROM"));
      if(pageContext.getSessionValue("FROM")!=null ){
      if("SERIALN0".equals(pageContext.getSessionValue("FROM"))){
      page = "OD_MPSCustContactPG";
      params.put("FROM","SERIALN0");
      }
      if("SERIALN0LINK".equals(pageContext.getSessionValue("FROM"))){
      page = "OD_MPSCustContactPG";
      params.put("FROM","SERIALN0LINK");
      params.put("address",pageContext.getParameter("address"));
      }
      if("ADDRESSLINK".equals(pageContext.getSessionValue("FROM"))){
      page = "OD_MPSCustomerContactUpdatePG";
      params.put("FROM","ADDRESSLINK");
      params.put("address", pageContext.getSessionValue("address"));
      }      
      }
      else{
      page = "OD_MPSCustomerContactUpdatePG";
      params.put("FROM","ADDRESSLINK");
      params.put("address", pageContext.getSessionValue("address"));
      }
      System.out.println("##### In Back of LocationUpdateCO page="+page);
      pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxcrm/mps/webui/"+page, //OD_MPSCustContactPG",
                                null,
                                OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                null,
                                params,
                                false, // Retain AM
                                OAWebBeanConstants.ADD_BREAD_CRUMB_NO, OAWebBeanConstants.IGNORE_MESSAGES);      
    }

    if("orderDetails".equals(pageContext.getParameter(EVENT_PARAM))){
      com.sun.java.util.collections.HashMap params = new com.sun.java.util.collections.HashMap(2);
      params.put("partyId",pageContext.getParameter("partyId"));
      params.put("serialNo",pageContext.getParameter("serialNo"));
      if(pageContext.getParameter("FROM")!=null && "SERIALN0".equals(pageContext.getParameter("FROM")))
      params.put("FROM","SERIALN0");
      pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxcrm/mps/webui/OD_MPSOrderDetailsPG",
                                null,
                                OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                null,
                                params,
                                false, // Retain AM
                                OAWebBeanConstants.ADD_BREAD_CRUMB_NO, OAWebBeanConstants.IGNORE_MESSAGES);      
    }    
    
  }

}
