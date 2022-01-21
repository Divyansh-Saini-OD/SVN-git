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
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageDateFieldBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;
import java.io.Serializable;
/**
 * Controller for ...
 */
public class XXCSMPSIncidentsOpenRptCO extends OAControllerImpl
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
    OAApplicationModule mpsIncidentsOpenAM = pageContext.getApplicationModule(webBean);
    if(pageContext.getParameter("Search") != null)
    {
      System.out.println("##### Search CustomerNameParam="+pageContext.getParameter("CustomerNameParam"));
      String customerName = pageContext.getParameter("CustomerNameParam");
      String fromDeliveryDate = pageContext.getParameter("FromDeliveryDateParam");
      String toDeliveryDate = pageContext.getParameter("ToDeliveryDateParam");
      String incidentNumber = pageContext.getParameter("IncidentNumberParam");
      String incidentType = pageContext.getParameter("IncidentTypeParam");
      String incidentStatus = pageContext.getParameter("IncidentStatusParam");

      String CustomerNumber = pageContext.getParameter("CustomerNumberParam");
      String ExpectedRespDate = pageContext.getParameter("ExpectedRespDateParam");
      String ExpectedResolDate = pageContext.getParameter("ExpectedResolDateParam");
      String ProgramType = pageContext.getParameter("ProgramTypeParam");
      String SerialNumber = pageContext.getParameter("SerialNumberParam");
      String Summary = pageContext.getParameter("SummaryParam");
      
      Serializable[] params = {customerName, toDeliveryDate, fromDeliveryDate, incidentNumber, incidentType, incidentStatus,
                               CustomerNumber, ExpectedRespDate, ExpectedResolDate, ProgramType, SerialNumber, Summary
                              };
      mpsIncidentsOpenAM.invokeMethod("initMPSIncidentOpen",params);
//      System.out.println("##### Search partyId="+partyId);
    }

    if(pageContext.getParameter("Clear") != null)  
    {
      clear( pageContext, webBean, mpsIncidentsOpenAM);
    }    
          
  }

 public void clear(OAPageContext pageContext,OAWebBean webBean, OAApplicationModule mpsTonerOrderAM)
  {
    OAMessageLovInputBean customerNameBean = (OAMessageLovInputBean)webBean.findChildRecursive("CustomerNameParam");
    OAMessageDateFieldBean fromDeliveryDateBean = (OAMessageDateFieldBean)webBean.findChildRecursive("FromDeliveryDateParam");
    OAMessageDateFieldBean toDeliveryDateBean = (OAMessageDateFieldBean)webBean.findChildRecursive("ToDeliveryDateParam");
    OAMessageTextInputBean incidentNumberBean = (OAMessageTextInputBean)webBean.findChildRecursive("IncidentNumberParam");
    OAMessageChoiceBean incidentTypeBean = (OAMessageChoiceBean)webBean.findChildRecursive("IncidentTypeParam");
    OAMessageChoiceBean incidentStatusBean = (OAMessageChoiceBean)webBean.findChildRecursive("IncidentStatusParam");
    OAMessageTextInputBean customerNumberBean = (OAMessageTextInputBean)webBean.findChildRecursive("CustomerNumberParam");
    OAMessageDateFieldBean expectedRespDateBean = (OAMessageDateFieldBean)webBean.findChildRecursive("ExpectedRespDateParam");
    OAMessageDateFieldBean expectedResolDateBean = (OAMessageDateFieldBean)webBean.findChildRecursive("ExpectedResolDateParam");
    OAMessageTextInputBean programTypeBean = (OAMessageTextInputBean)webBean.findChildRecursive("ProgramTypeParam");
    OAMessageTextInputBean serialNumberBean = (OAMessageTextInputBean)webBean.findChildRecursive("SerialNumberParam");
    OAMessageTextInputBean summaryBean = (OAMessageTextInputBean)webBean.findChildRecursive("SummaryParam");

    if(customerNameBean != null)
    customerNameBean.setValue(pageContext,"");
    if(fromDeliveryDateBean != null)
    fromDeliveryDateBean.setValue(pageContext,"");
    if(toDeliveryDateBean != null)
    toDeliveryDateBean.setValue(pageContext,"");
    if(incidentNumberBean != null)
    incidentNumberBean.setValue(pageContext,"");    
    if(incidentTypeBean != null)
    incidentTypeBean.setValue(pageContext,""); 
    if(incidentStatusBean != null)
    incidentStatusBean.setValue(pageContext,""); 

    if(customerNumberBean != null)
    customerNumberBean.setValue(pageContext,"");
    if(expectedRespDateBean != null)
    expectedRespDateBean.setValue(pageContext,"");
    if(expectedResolDateBean != null)
    expectedResolDateBean.setValue(pageContext,"");
    if(programTypeBean != null)
    programTypeBean.setValue(pageContext,"");    
    if(serialNumberBean != null)
    serialNumberBean.setValue(pageContext,""); 
    if(summaryBean != null)
    summaryBean.setValue(pageContext,""); 

    
    Serializable[] params = {"-1", "01-JAN-0001","01-JAN-9999", "-1","-1","-1"
                            ,"-1","01-JAN-0001","01-JAN-9999","-1","-1","-1"
                            };
    mpsTonerOrderAM.invokeMethod("initMPSIncidentOpen",params);    
  }

}
