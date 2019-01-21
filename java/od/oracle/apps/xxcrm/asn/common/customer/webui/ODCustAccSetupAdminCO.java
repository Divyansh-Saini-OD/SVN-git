/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.common.customer.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.util.provider.OAFrameworkProviderUtil;
import oracle.apps.fnd.framework.webui.*;
import oracle.apps.fnd.framework.OAException;
import od.oracle.apps.xxcrm.asn.common.customer.server.ODContractTemplatesVORowImpl;

import oracle.apps.fnd.common.*;

import oracle.apps.fnd.framework.webui.beans.nav.OAButtonBean;
import oracle.apps.fnd.security.HMAC;
import oracle.apps.fnd.framework.OAViewObject;
/**
 * Controller for ...
 */
public class ODCustAccSetupAdminCO extends OAControllerImpl
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
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
    am.invokeMethod("lookupquery");
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

    OAApplicationModule currentAm = (OAApplicationModule) pageContext.getApplicationModule(webBean);
    String pageEvent = pageContext.getParameter("AcctSetupAdminEvent");

    if ("AddContractTemplate".equals(pageEvent))
    {
       currentAm.invokeMethod("addContractTemplate");
       OAException confirmMessage = new OAException("XXCRM", "XX_ASN_ACCT_SETUP_ADMIN_CONF",    null,
       OAException.CONFIRMATION, null);  
       pageContext.putDialogMessage(confirmMessage);
       
    }    
    else
    if ("RemoveContractTemplate".equals(pageEvent))
    {
       currentAm.invokeMethod("removeContractTemplate");
    }
    else
    if ("AddDocumentTemplate".equals(pageEvent))
    {
       currentAm.invokeMethod("addDocumentTemplate");
    }
    else
    if ("RemoveDocumentTemplate".equals(pageEvent))
    {
       currentAm.invokeMethod("removeDocumentTemplate");
    }
    else
    if ("AddDefaultValues".equals(pageEvent))
    {
       currentAm.invokeMethod("addDefaultValues");
    }
    else
    if ("RemoveDefaultValues".equals(pageEvent))
    {
       currentAm.invokeMethod("removeDefaultValues");
    }


if (pageContext.getParameter("Update") != null) 
   {
/*Do all the validations*/
   OAViewObject ODContractTemplatesVO = (OAViewObject)currentAm.findViewObject("ODContractTemplatesVO");
   ODContractTemplatesVORowImpl curRow;        
   curRow = (ODContractTemplatesVORowImpl)ODContractTemplatesVO.first();
   boolean valStatus = true;
   /*
   while (curRow != null)
   {
    if ((curRow.getSalesRole() != null || curRow.getRevenueBandCode() != null ||
        curRow.getContarctNumber() != null || curRow.getContractDescription() !=null ||
        curRow.getPriority() != null || curRow.getCustom() != null) && curRow.getTemplateName() == null)
        {
          valStatus = false;
          String errMsg = pageContext.getMessage("XXCRM", "XX_ASN_ACCT_TEMPLATE_MANDATORY",null);
          pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));          
        }        
        curRow = (ODContractTemplatesVORowImpl)ODContractTemplatesVO.next();
   }
   */


   if (valStatus == true)
   {
       OAApplicationModule am = pageContext.getApplicationModule(webBean);
       am.invokeMethod("apply");
       OAException confirmMessage = new OAException("XXCRM", "XX_ASN_ACCT_SETUP_ADMIN_CONF",    null,
       OAException.CONFIRMATION, null);  
       pageContext.putDialogMessage(confirmMessage);
   }
   
   pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxcrm/asn/common/customer/webui/ODCustAccSetupAdminPG",
                                 null,
                                 OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                 null,
                                 null,
                                 true, // retain AM
                                 OAWebBeanConstants.ADD_BREAD_CRUMB_NO); 

   }


  }

}
