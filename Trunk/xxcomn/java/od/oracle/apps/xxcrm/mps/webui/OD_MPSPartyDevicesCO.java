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
//import od.oracle.apps.xxcrm.mps.server.OD_MPSCustContactVORowImpl;
import com.sun.java.util.collections.HashMap;
/**
 * Controller for ...
 */
public class OD_MPSPartyDevicesCO extends OAControllerImpl
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
    System.out.println("##### In OD_MPSPartyDevicesCO PR");
    pageContext.writeDiagnostics(this,"##### In OD_MPSPartyDevicesCO PR",1);
    String partyName = pageContext.getParameter("partyName");
    String partyId = pageContext.getParameter("partyId");
    String customerNumber = pageContext.getParameter("customerNumber");
//    String serialNo = pageContext.getParameter("serialNo");
    System.out.println("##### IN PR OD_MPSPartyDevicesCO  partyName="+partyName);
    System.out.println("##### IN PR OD_MPSPartyDevicesCO  partyId="+partyId);
    System.out.println("##### IN PR OD_MPSPartyDevicesCO  customerNumber="+customerNumber);


    if(partyName != null){
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
    mpsPartyDevicesAM.invokeMethod("initFetchPartyContact",params);
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
        mpsPartyDevicesAM.invokeMethod("initFetchPartyContact",params);
      }
      else
      throw new OAException("XXCRM","OD_PROVIDE_PARTY_NAME",null,OAException.ERROR,null);
    }
    if(pageContext.getParameter("Clear") != null)  
    {
      clear( pageContext, webBean, mpsPartyDevicesAM);
    }
    

    if("GotoSerialNo".equals(pageContext.getParameter(EVENT_PARAM)))
    {
      HashMap param = new HashMap(1);
      param.put("FROM","ADDRESSLINK");
      param.put("address",pageContext.getParameter("address"));
      //Defect: 23597
      param.put("serialNo",pageContext.getParameter("serialNo"));
      System.out.println("##### gotoaddress link address="+pageContext.getParameter("address"));
      pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxcrm/mps/webui/OD_MPSPartyDevicesUpdatePG",
                                null,
                                OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                null,
                                param,
                                false, // Retain AM
                                OAWebBeanConstants.ADD_BREAD_CRUMB_YES, OAWebBeanConstants.IGNORE_MESSAGES);      
    }

    }  

  

  public void clear(OAPageContext pageContext,OAWebBean webBean, OAApplicationModule mpsPartyDevicesAM)
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
    mpsPartyDevicesAM.invokeMethod("initFetchPartyContact",params);
    if(pageContext.getParameter("SerialNo") != null)
    serialNoBean.setValue(pageContext,"");
  }
}

