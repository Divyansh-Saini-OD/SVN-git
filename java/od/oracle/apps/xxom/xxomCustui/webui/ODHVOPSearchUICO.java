/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxom.xxomCustui.webui;

import java.io.Serializable;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;

/**
 * Controller for ...
 */
public class ODHVOPSearchUICO extends OAControllerImpl
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
	 if(pageContext.getResponsibilityName() == null) { pageContext.changeResponsibility("OD (US) OM Read Only Archive", "ONT"); }  
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
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      if(pageContext.getParameter("Go") != null)
      {
      
          String sOrderNumber = pageContext.getParameter("OrderNumber");
          String sOSRDocRef = pageContext.getParameter("OrigSysDocumentRef");    
          System.out.println("sOrderNumber: " + sOrderNumber + ", sOSRDocRef: " + sOSRDocRef);
          
          Serializable[] params = {sOSRDocRef, sOrderNumber
                                  };       
          am.invokeMethod("initXxOmOrderSearchVO",params);
      }    
      if(pageContext.getParameter("Clear") != null)  
      {
        clear( pageContext, webBean, am);
      }       
  }
    public void clear(OAPageContext pageContext,OAWebBean webBean, OAApplicationModule am)
     {
    OAMessageTextInputBean OrderNumberBean = (OAMessageTextInputBean)webBean.findChildRecursive("OrderNumber");
    OAMessageTextInputBean OrigSysDocumentRefBean = (OAMessageTextInputBean)webBean.findChildRecursive("OrigSysDocumentRef");

    if(OrderNumberBean != null)
    OrderNumberBean.setValue(pageContext,"");
    if(OrigSysDocumentRefBean != null)
    OrigSysDocumentRefBean.setValue(pageContext,"");
    
    Serializable[] params = { "-1","-1"
                            };
    am.invokeMethod("initXxOmOrderSearchVO",params);
    }

}
