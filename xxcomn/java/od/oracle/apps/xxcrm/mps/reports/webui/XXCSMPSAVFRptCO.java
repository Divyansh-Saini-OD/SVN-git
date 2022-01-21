/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.mps.reports.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.webui.beans.form.OAFormValueBean;
import java.io.Serializable;

import oracle.apps.fnd.framework.OAFwkConstants;

/**
 * Controller for ...
 */
public class XXCSMPSAVFRptCO extends OAControllerImpl
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
   OAApplicationModule mpsAVFAM = pageContext.getApplicationModule(webBean);
    if(pageContext.getParameter("Search") != null)
    {
     String partyId = pageContext.getParameter("PartyIDFV");
     String serialNo = pageContext.getParameter("SerialNo");
     
     String managedStatus = pageContext.getParameter("ManagedStatusInput");
     String activeStatus = pageContext.getParameter("ActiveStatusInput");

     pageContext.writeDiagnostics(this, "managedStatus: " + managedStatus, OAFwkConstants.STATEMENT);
     pageContext.writeDiagnostics(this, "activeStatus: " + activeStatus, OAFwkConstants.STATEMENT);
     
      Serializable[] params = {partyId, serialNo, managedStatus, activeStatus};
      mpsAVFAM.invokeMethod("initMPSAVF",params);
//      System.out.println("##### Search partyId="+partyId);
    }

    if(pageContext.getParameter("Clear") != null)  
    {
      clear( pageContext, webBean, mpsAVFAM);
    }    
          
  }

 public void clear(OAPageContext pageContext,OAWebBean webBean, OAApplicationModule mpsAVFAM)
  {
    OAMessageLovInputBean parttyNameBean = (OAMessageLovInputBean)webBean.findChildRecursive("PartyName");
    OAMessageTextInputBean serialNoBean = (OAMessageTextInputBean)webBean.findChildRecursive("SerialNo");
    OAFormValueBean partyIdBean = (OAFormValueBean)webBean.findChildRecursive("PartyIDFV");
    OAMessageTextInputBean managedStatusBean = (OAMessageTextInputBean)webBean.findChildRecursive("ManagedStatusInput");
    OAMessageTextInputBean activeStatusBean = (OAMessageTextInputBean)webBean.findChildRecursive("ActiveStatusInput");
    if(parttyNameBean != null)
    parttyNameBean.setValue(pageContext,"");
    if(partyIdBean != null)
    partyIdBean.setValue(pageContext,"");    
    if(serialNoBean != null)
    serialNoBean.setValue(pageContext,"");
    if(managedStatusBean!=null)
        managedStatusBean.setValue(pageContext, "");
    if(activeStatusBean!=null)
        activeStatusBean.setValue(pageContext, "");
    Serializable[] params = {"-1", "-1", null, null};
    mpsAVFAM.invokeMethod("initMPSAVF",params);    
  }

  }


