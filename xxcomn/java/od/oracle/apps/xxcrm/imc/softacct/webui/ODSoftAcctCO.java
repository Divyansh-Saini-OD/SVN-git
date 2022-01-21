/*===========================================================================+
 |      		       Office Depot - Project Simplify                           |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODSoftAcctCO.java                                             |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Controller Class that helps in displaying the DFFs and the actions     |
 |    associated with the DFFs like Restore and Save                         |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |      This class is invoked from ODSoftAcctAMImpl.java                     |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    04/04/2007     Sathya Prabha Rani       Created                        |
 |                                                                           |
 +===========================================================================*/

package od.oracle.apps.xxcrm.imc.softacct.webui;

import java.io.Serializable;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.OAApplicationModule;

/**
 * Controller for ...
 */
public class ODSoftAcctCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header: /home/cvs/repository/Office_Depot/SRC/CRM/E0102_SoftAccountingFields/3.\040Source\040Code\040&\040Install\040Files/ODSoftAcctCO.java,v 1.2 2007/07/24 09:36:16 srani Exp $";
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

    //Retrieve the parameters from the URL
   
    String custAcctSiteID = pageContext.getParameter("custAcctSiteID");
    String siteUseID      = pageContext.getParameter("siteUseID");
    String siteUseCode    = pageContext.getParameter("siteUseCode");

    //Invoking General Information
    
    Serializable [] parameters = {custAcctSiteID};
    am.invokeMethod("initDetailsGenInfo", parameters);

    //Invoking Account Site Information
       
    Serializable [] parameters2 = { custAcctSiteID,siteUseCode };
    am.invokeMethod("initDetailsCustAcctSite", parameters2); 

    //Invoking Addtional Information
    
    Serializable [] parameters3 = { siteUseID, siteUseCode };
    am.invokeMethod("initDetailsFlexfield", parameters3); 
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
     
    if (pageContext.getParameter("restore") != null)
    {
      pageContext.forwardImmediatelyToCurrentPage(null, false,ADD_BREAD_CRUMB_YES);
    }

    if (pageContext.getParameter("save") != null) 
    {
      OAViewObject vo = (OAViewObject)am.findViewObject("ODFlexfieldInfoVO1");

      // Invoke custom method for updation of DFFs.
      
      am.invokeMethod("saveTheFF");
      
      OAException confirmMessage = new OAException("IMC", "XXOD_IMC_SOFTACCT_UPD_CONFIRM",null,
      OAException.CONFIRMATION, null);
     
      pageContext.putDialogMessage(confirmMessage);
     
      pageContext.forwardImmediately("OA.jsp?page=/oracle/apps/xxcrm/imc/softacct/webui/ODSoftAcctPG",
                                 null,
                                 OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                 null,
                                 null,
                                 true, // retain AM
                                 OAWebBeanConstants.ADD_BREAD_CRUMB_YES); 
    }

  
  }

}
