/*===========================================================================+
 |      		      Office Depot - TDS Parts                                |
 |                Oracle Consulting Organization, Redwood Shores, CA, USA     |
 +=========================================================================== +
 |  FILENAME                                                                  |
 |             OD_MPSCustomerContactUpdateCO.java                             |
 |                                                                            |
 |  DESCRIPTION                                                               |
 |    Class to update the Party Contact to the database.                      |
 |    Also used for validation upon submission.                               |
 |                                                                            |
 |  NOTES                                                                     |
 |                                                                            |
 |                                                                            |
 |  DEPENDENCIES                                                              |
 |                                                                            |
 |  HISTORY                                                                   |
 | Ver  Date        Name           Revision Description                       |
 | ===  =========   ============== ===========================================|
 | 1.0  08-OCT-12   Suraj Charan    Initial.                                   |
 | 1.1  14-Dec-2013 Sravanthi surya Defect#26930 fix for Incorrect parameters |
 |                                  getting binded during run time            |
 | 1.2  30-May-2014 Shubhashree R   Defect#27293 changes for Device Asset     |
 |                                  Details                                   |
 |                                                                            |
 +===========================================================================*/
package od.oracle.apps.xxcrm.mps.webui;

import java.io.Serializable;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;

import oracle.jbo.domain.Number;
/**
 * Controller for ...
 */
public class OD_MPSCustomerContactUpdateCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");
  String partyId = null;
  String location = null;
  String serialNo = null;
  String address = null;

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
    OAApplicationModule mpsCustContAM = pageContext.getApplicationModule(webBean);
    if(pageContext.getParameter("partyName") != null)
    {
      OAHeaderBean hdrBean = (OAHeaderBean)webBean.findChildRecursive("CustContactUpdateHDR");
      if(hdrBean != null)
      {
        hdrBean.setText(hdrBean.getText(pageContext)+": "+pageContext.getParameter("partyName"));
      }
    }
    if(pageContext.getParameter("partyId") != null)
    {
      partyId  =  pageContext.getParameter("partyId");
      location =  pageContext.getParameter("location");
      serialNo =  pageContext.getParameter("serialNo");
	  address =  pageContext.getParameter("address");


//      String partyName = "21ST CENTURY ONCOLOGY";
      System.out.println("##### in OD_MPSCustomerContactUpdateCO PR partyId ="+partyId);
      pageContext.writeDiagnostics(this,"##### in OD_MPSCustomerContactUpdateCO PR partyId ="+partyId ,1);
      //Defect: 23597
    //  Serializable[] params  = {partyId,serialNo};                         //location};  Commeneted by Sravanthi on 14-Dec-2013
	   pageContext.writeDiagnostics(this,"##### Location" +location ,1);
	   Serializable[] params  = {partyId,location}                          ;//location};   Added By Sravanthi on 14-Dec-2013
//      mpsCustContAM.invokeMethod("initCustContUpdate",params);

//    OAViewObject mpsCustContVO = (OAViewObject)mpsCustContAM.findViewObject("OD_MPSCustContactUpdateVO");
////    mpsCustContVO.setWhereClause("PARTY_NAME = '" + partyName+"'");
//    mpsCustContVO.setWhereClause("PARTY_ID =" + partyId);
//    mpsCustContVO.executeQuery();

    }
      System.out.println("##### From Address Link.. partyId="+pageContext.getParameter("partyId"));
      System.out.println("##### From Address Link..address="+pageContext.getParameter("address"));
      if("ADDRESSLINK".equals(pageContext.getParameter("FROM"))){
      System.out.println("##### in OD_MPSCustomerContactUpdateCO PR ADDRESSLINK ="+pageContext.getParameter("FROM"));
      address = pageContext.getParameter("address");
      //Defect: 23597
      serialNo = pageContext.getParameter("serialNo");
      System.out.println("##### in OD_MPSCustomerContactUpdateCO PR address ="+address);
       Serializable[] params  = {partyId,serialNo};                       // Added by sravanthi on 17-Dec-2013
       //Serializable[] params  = {partyId,address};                       Commented by Sravanthi on 17-Dec-2013
      mpsCustContAM.invokeMethod("initAddressCustContUpdate",params);
      }
/*
    if(pageContext.getParameter("location") !=null &&!"".equals(pageContext.getParameter("location")) ){
      if(pageContext.getSessionValue("locationfromSession") == null)
      {
        location = pageContext.getParameter("location");
      }
      location = pageContext.getParameter("location");
      pageContext.putSessionValue("locationfromSession",location);
      System.out.println("##### in OD_MPSCustomerContactUpdateCO PR location ="+location);
      pageContext.writeDiagnostics(this,"##### in OD_MPSCustomerContactUpdateCO PR location ="+location ,1);
      System.out.println("##### in OD_MPSCustomerContactUpdateCO PR locationfromSession ="+pageContext.getSessionValue("locationfromSession"));
      pageContext.writeDiagnostics(this,"##### in OD_MPSCustomerContactUpdateCO PR locationfromSession ="+pageContext.getSessionValue("locationfromSession") ,1);
      Serializable[] params = {location};
      mpsCustContAM.invokeMethod("initFetchLocations",params);
    }
*/
    if(pageContext.getParameter("address") !=null ){
//      if(pageContext.getSessionValue("locationfromSession") == null)
//      {
//        location = pageContext.getParameter("location");
//      }
      address = pageContext.getParameter("address");
//      pageContext.putSessionValue("locationfromSession",address);
      System.out.println("##### in OD_MPSCustomerContactUpdateCO PR address ="+address);
      pageContext.writeDiagnostics(this,"##### in OD_MPSCustomerContactUpdateCO PR address ="+address ,1);
//      System.out.println("##### in OD_MPSCustomerContactUpdateCO PR locationfromSession ="+pageContext.getSessionValue("locationfromSession"));
//      pageContext.writeDiagnostics(this,"##### in OD_MPSCustomerContactUpdateCO PR locationfromSession ="+pageContext.getSessionValue("locationfromSession") ,1);
      Serializable[] params = {address};
      mpsCustContAM.invokeMethod("initFetchAddress",params);
    }
    if(pageContext.getParameter("serialNo") !=null && !"".equals(pageContext.getParameter("serialNo"))){
      if(pageContext.getSessionValue("serialNofromSession") == null)
      {
        serialNo = pageContext.getParameter("serialNo");
      }
      serialNo = pageContext.getParameter("serialNo");
      pageContext.putSessionValue("serialNofromSession",serialNo);
      System.out.println("##### in OD_MPSCustomerContactUpdateCO PR serialNo ="+serialNo);
      pageContext.writeDiagnostics(this,"##### in OD_MPSCustomerContactUpdateCO PR serialNo ="+serialNo ,1);
      System.out.println("##### in OD_MPSCustomerContactUpdateCO PR serialNofromSession ="+pageContext.getSessionValue("serialNofromSession"));
      pageContext.writeDiagnostics(this,"##### in OD_MPSCustomerContactUpdateCO PR serialNofromSession ="+pageContext.getSessionValue("serialNofromSession") ,1);
      Serializable[] params = {serialNo};
      mpsCustContAM.invokeMethod("initFetchSerialNoLink",params);
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
    if("update".equals(pageContext.getParameter(EVENT_PARAM)))
    {
      System.out.println("##### In OD_MPSCustomerContactUpdateCO PFR location="+ pageContext.getParameter("location"));
      System.out.println("##### In OD_MPSCustomerContactUpdateCO PFR device id="+ pageContext.getParameter("deviceId"));
      System.out.println("##### In OD_MPSCustomerContactUpdateCO PFR partyId="+ pageContext.getParameter("partyId"));
      System.out.println("##### In OD_MPSCustomerContactUpdateCO PFR address="+ pageContext.getParameter("address"));
      pageContext.writeDiagnostics(this,"##### In OD_MPSCustomerContactUpdateCO PFR location="+ pageContext.getParameter("location") ,1);
      pageContext.writeDiagnostics(this,"##### In OD_MPSCustomerContactUpdateCO PFR device id="+ pageContext.getParameter("deviceId") ,1);
      pageContext.writeDiagnostics(this,"##### In OD_MPSCustomerContactUpdateCO PFR partyId="+ pageContext.getParameter("partyId") ,1);
      com.sun.java.util.collections.HashMap params = new com.sun.java.util.collections.HashMap(2);
      params.put("location",pageContext.getParameter("location"));
      params.put("deviceId",pageContext.getParameter("deviceId"));
      params.put("partyId",pageContext.getParameter("partyId"));
      params.put("address",pageContext.getParameter("address"));
      //Defect: 23597
      params.put("serialNo",pageContext.getParameter("serialNo"));
      params.put("FROM",pageContext.getParameter("FROM"));
      pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxcrm/mps/webui/OD_MPSCustomerLocationUpdatePG",
                                null,
                                OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                null,
                                params,
                                false, // Retain AM
                                OAWebBeanConstants.ADD_BREAD_CRUMB_NO, OAWebBeanConstants.IGNORE_MESSAGES);
    }

    if(pageContext.getParameter("Save") != null){
    Serializable[] params = {partyId
                            ,serialNo//location  //Defect: 23597
                            ,pageContext.getParameter("Contact")
                            ,pageContext.getParameter("Phone")
                            ,pageContext.getParameter("Address")
                            ,pageContext.getParameter("Address1")
                            ,pageContext.getParameter("City")
                            ,pageContext.getParameter("State")
                            ,pageContext.getParameter("Zip")
                            ,pageContext.getParameter("CostCenter")
                            ,pageContext.getParameter("Location")
                            ,pageContext.getParameter("PONumber")
                            };
    System.out.println("##### When Contact save partyId="+partyId+" location="+location);
    mpsCustContAM.invokeMethod("saveCustContact",params);
    }
//    if(pageContext.getParameter("Back") != null){
    if("Back".equals(pageContext.getParameter(EVENT_PARAM))){
      com.sun.java.util.collections.HashMap params = new com.sun.java.util.collections.HashMap(2);
      params.put("partyName",pageContext.getParameter("partyName"));
      params.put("partyId",pageContext.getParameter("partyId"));
//      params.put("serialNo",pageContext.getParameter("serialNo"));
      System.out.println("##### In BACK partyName="+pageContext.getParameter("partyName"));
      System.out.println("##### In BACK serialNo="+pageContext.getParameter("serialNo"));
      pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxcrm/mps/webui/OD_MPSCustContactPG",
                                null,
                                OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                null,
                                params,
                                false, // Retain AM
                                OAWebBeanConstants.ADD_BREAD_CRUMB_NO, OAWebBeanConstants.IGNORE_MESSAGES);

    }
  }

}
