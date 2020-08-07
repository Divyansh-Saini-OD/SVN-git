/*===========================================================================+
 |      		      Office Depot - TDS Parts                                   |
 |                Oracle Consulting Organization, Redwood Shores, CA, USA    |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             OD_MPSCusContactCO.java                                      |
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
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;

import java.io.Serializable;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.webui.beans.form.OAFormValueBean;
import od.oracle.apps.xxcrm.mps.server.OD_MPSSerialNoVORowImpl;
import od.oracle.apps.xxcrm.mps.server.OD_MPSCustLocationUpdateVORowImpl;
import od.oracle.apps.xxcrm.mps.server.OD_MPSCustContactVORowImpl;
import com.sun.java.util.collections.HashMap;

/**
 * Controller for ...
 */
public class OD_MPSCustContactCO extends OAControllerImpl
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
    System.out.println("##### In OD_MPSCustContactCO PR");
    pageContext.writeDiagnostics(this,"##### In OD_MPSCustContactCO PR",1);
//    String partyName = "21ST CENTURY ONCOLOGY";
//    String partyId = "21323388";
    String partyName = pageContext.getParameter("partyName");
    String partyId = pageContext.getParameter("partyId");
    String customerNumber = pageContext.getParameter("customerNumber");
    String serialNo = pageContext.getParameter("serialNo");
//    OAViewObject mpsCustContVO = (OAViewObject)mpsCustContAM.findViewObject("OD_MPSCustContactVO");
////    tVO.setWhereClause("PARTY_NAME = '" + partyName+"'");
//    mpsCustContVO.setWhereClause("PARTY_ID = " + partyId);
//    mpsCustContVO.executeQuery();
//    System.out.println("Test row="+mpsCustContVO.getRowCount()); 
    System.out.println("##### IN PR custcontactco  FROM="+pageContext.getParameter("FROM"));
    if("SERIALN0".equals(pageContext.getParameter("FROM")))
    {
      OAMessageTextInputBean serialNoBean = (OAMessageTextInputBean)webBean.findChildRecursive("SerialNo");
      if(serialNo != null)
      serialNoBean.setValue(pageContext, serialNo); 
    }
    else if(partyName != null){
    OAMessageLovInputBean partyNameBean = (OAMessageLovInputBean)webBean.findChildRecursive("PartyName");
    OAMessageStyledTextBean partyIdBean = (OAMessageStyledTextBean)webBean.findChildRecursive("PartyId");
    OAFormValueBean partyIdFormBean = (OAFormValueBean)webBean.findChildRecursive("PartyIDFV");
    OAMessageStyledTextBean customerNumberBean = (OAMessageStyledTextBean)webBean.findChildRecursive("CustomerNumber");
    OAFormValueBean customerNumberFormBean = (OAFormValueBean)webBean.findChildRecursive("CustomernumberFV");
    if(partyNameBean != null)
    partyNameBean.setValue(pageContext,partyName);
    if(partyIdBean != null)
    partyIdBean.setValue(pageContext,partyId);
    if(partyIdFormBean != null)
    partyIdFormBean.setValue(pageContext,partyId);
    if(customerNumberBean != null)
    customerNumberBean.setValue(pageContext,customerNumber);
    if(customerNumberFormBean != null)
    customerNumberFormBean.setValue(pageContext,customerNumber);
    
    
    Serializable[] params = {partyName, partyId};
    mpsCustContAM.invokeMethod("initFetchPartyContact",params);
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
      String partyName = pageContext.getParameter("PartyName");
      String partyId = pageContext.getParameter("PartyIDFV");//PartyId");    
      String customerNumber = pageContext.getParameter("CustomernumberFV");
      System.out.println("##### EVENT="+pageContext.getParameter(EVENT_PARAM));
      System.out.println("##### PFR partyName="+partyName);
      System.out.println("##### PFR partyId="+partyId);
      /*
      if("lovUpdate".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        partyId = pageContext.getParameter("PartyIDFV");
        if("".equals(partyId) || partyId == null)
        {
          throw new OAException("XXCRM","OD_PROVIDE_PARTY_NAME",null,OAException.ERROR,null);
        }
      }
      */
      if(pageContext.getParameter("PartyIDFV") != null){
      OAMessageStyledTextBean partyIdBean = (OAMessageStyledTextBean)webBean.findChildRecursive("PartyId");
      if(partyIdBean!= null)
      partyIdBean.setValue(pageContext,partyId);
      }

      if(pageContext.getParameter("CustomernumberFV") != null){
      OAMessageStyledTextBean customerNumberBean = (OAMessageStyledTextBean)webBean.findChildRecursive("CustomerNumber");
      if(customerNumberBean!= null)
      customerNumberBean.setValue(pageContext,customerNumber);
      }      

      pageContext.writeDiagnostics(this,"##### PFR partyName="+partyName,1);
      pageContext.writeDiagnostics(this,"##### PFR partyId="+partyId,1);
    if(pageContext.getParameter("Search") != null)
    {

      System.out.println("##### Search partyName="+partyName);
      System.out.println("##### Search partyId="+partyId);
      
      if((pageContext.getParameter("PartyName")!=null && !"".equals(pageContext.getParameter("PartyName"))) && (pageContext.getParameter("PartyIDFV")!=null) && !"".equals(pageContext.getParameter("PartyIDFV")) && (pageContext.getParameter("SerialNo")==null || "".equals(pageContext.getParameter("SerialNo"))))
      {
        Serializable[] params = {partyName, partyId};
        mpsCustContAM.invokeMethod("initFetchPartyContact",params);
      }
      else if((pageContext.getParameter("SerialNo")!=null && !"".equals(pageContext.getParameter("SerialNo"))))
      {
        System.out.println("##### Inside Serial No is not null.");
        String serialNo = pageContext.getParameter("SerialNo");
        Serializable[] params = {serialNo};
        mpsCustContAM.invokeMethod("initFetchLocationDetails",params);
        mpsCustContAM.invokeMethod("initFetchLocationSerialNo",params);
        OAViewObject srlVO = (OAViewObject)mpsCustContAM.findViewObject("OD_MPSCustLocationUpdateVO");
        OD_MPSCustLocationUpdateVORowImpl srlVORow = (OD_MPSCustLocationUpdateVORowImpl)srlVO.first();
        if(srlVO.getRowCount() != 0){
        srlVORow.getDeviceId();
        srlVORow.getDeviceLocation();
        srlVORow.getPartyId();
        HashMap param = new HashMap(3);
//        --location, deviceid, partyid
        param.put("location",srlVORow.getDeviceLocation());
        param.put("deviceId",srlVORow.getDeviceId());
        param.put("partyId",srlVORow.getPartyId());
        param.put("serialNo",srlVORow.getSerialNo());
        param.put("FROM","SERIALN0");
        
        pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxcrm/mps/webui/OD_MPSCustomerLocationUpdatePG",
                                null,
                                OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                null,
                                param,
                                false, // Retain AM
                                OAWebBeanConstants.ADD_BREAD_CRUMB_YES, OAWebBeanConstants.IGNORE_MESSAGES);
        }else{
        throw new OAException("XXCRM","NO_DATA_FOUND",null,OAException.ERROR,null);
        }
      }
      else
      throw new OAException("XXCRM","OD_PROVIDE_PARTY_NAME",null,OAException.ERROR,null);
    }
    if(pageContext.getParameter("Clear") != null)  
    {
      clear( pageContext, webBean, mpsCustContAM);
    }
    

    if("gotolocation".equals(pageContext.getParameter(EVENT_PARAM)))
    {
      pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxcrm/mps/webui/OD_MPSCustomerContactUpdatePG",
                                null,
                                OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                null,
                                null,
                                false, // Retain AM
                                OAWebBeanConstants.ADD_BREAD_CRUMB_YES, OAWebBeanConstants.IGNORE_MESSAGES);

    }
    if("gotoaddress".equals(pageContext.getParameter(EVENT_PARAM)))
    {
      HashMap param = new HashMap(1);
      param.put("FROM","ADDRESSLINK");
      param.put("address",pageContext.getParameter("address"));
      //Defect: 23597
      param.put("serialNo",pageContext.getParameter("serialNo"));
      System.out.println("##### gotoaddress link address="+pageContext.getParameter("address"));
      pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxcrm/mps/webui/OD_MPSCustomerContactUpdatePG",
                                null,
                                OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                null,
                                param,
                                false, // Retain AM
                                OAWebBeanConstants.ADD_BREAD_CRUMB_YES, OAWebBeanConstants.IGNORE_MESSAGES);      
    }
    if("gotoserialno".equals(pageContext.getParameter(EVENT_PARAM)))
    {
        String serialNo = pageContext.getParameter("serialNo");
        
        System.out.println("##### EVENT gotoserialno serialNo="+serialNo);
        Serializable[] params = {serialNo};
        mpsCustContAM.invokeMethod("initFetchLocationDetails",params);
        mpsCustContAM.invokeMethod("initFetchLocationSerialNo",params);
        OAViewObject srlVO = (OAViewObject)mpsCustContAM.findViewObject("OD_MPSCustLocationUpdateVO");
        OD_MPSCustLocationUpdateVORowImpl srlVORow = (OD_MPSCustLocationUpdateVORowImpl)srlVO.first();
        if(srlVO.getRowCount() != 0){
        srlVORow.getDeviceId();
        srlVORow.getDeviceLocation();
        srlVORow.getPartyId();
        HashMap param = new HashMap(3);
//        --location, deviceid, partyid
        param.put("location",srlVORow.getDeviceLocation());
        param.put("deviceId",srlVORow.getDeviceId());
        param.put("partyId",srlVORow.getPartyId());
        param.put("serialNo",srlVORow.getSerialNo());
        param.put("FROM","SERIALN0LINK");
        
        pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxcrm/mps/webui/OD_MPSCustomerLocationUpdatePG",
                                null,
                                OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                null,
                                param,
                                false, // Retain AM
                                OAWebBeanConstants.ADD_BREAD_CRUMB_YES, OAWebBeanConstants.IGNORE_MESSAGES);
        }else{
        throw new OAException("XXCRM","NO_DATA_FOUND",null,OAException.ERROR,null);
        }
    }    
    
  }

  public void clear(OAPageContext pageContext,OAWebBean webBean, OAApplicationModule mpsCustContAM)
  {
    OAMessageLovInputBean partyNameBean = (OAMessageLovInputBean)webBean.findChildRecursive("PartyName");
    OAMessageStyledTextBean partyIdBean = (OAMessageStyledTextBean)webBean.findChildRecursive("PartyId");
    OAFormValueBean partyIdFormBean = (OAFormValueBean)webBean.findChildRecursive("PartyIDFV");
    OAMessageTextInputBean serialNoBean = (OAMessageTextInputBean)webBean.findChildRecursive("SerialNo");
    OAMessageStyledTextBean customerNumberBean = (OAMessageStyledTextBean)webBean.findChildRecursive("CustomerNumber");
    OAFormValueBean customerNumberFormBean = (OAFormValueBean)webBean.findChildRecursive("CustomernumberFV");    
    if(partyNameBean != null)
    partyNameBean.setValue(pageContext,"");
    if(partyIdBean != null)
    partyIdBean.setValue(pageContext,"");
    if(partyIdFormBean != null)
    partyIdFormBean.setValue(pageContext,"");  
    if(customerNumberBean != null)
    customerNumberBean.setValue(pageContext,"");
    if(customerNumberFormBean != null)
    customerNumberFormBean.setValue(pageContext,"");
    
    Serializable[] params = {"-1", "-1"};
    mpsCustContAM.invokeMethod("initFetchPartyContact",params);
    if(pageContext.getParameter("SerialNo") != null)
    serialNoBean.setValue(pageContext,"");
  }
}
