/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODCustomerAdvSrchCO.java                                      |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Advanced Search Region Controller class for the customer Search Page   |
 |                                                                           |
 |  NOTES                                                                    |
 |         Used for the Customer Search Page                                 |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    No dependencies.                                                       |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |   14-Apr-2008 Jasmine Sujithra   Created                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.custsrch.common.customer.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.layout.OAAdvancedSearchBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageRadioGroupBean;

/**
 * Controller for ...
 */
public class ODCustomerAdvSrchCO extends OAControllerImpl
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
    final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.custsrch.common.customer.webui.ODCustomerAdvSrchCO.processRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

     super.processRequest(pageContext, webBean);
     	// get the advanced search bean
	   OAAdvancedSearchBean advSrchBn = (OAAdvancedSearchBean)webBean;

     if(advSrchBn != null)
     {
	     // get the radio group bean for  for  AND / OR search option
	     OAMessageRadioGroupBean andOrRdoGrpBn = (OAMessageRadioGroupBean)
                                              advSrchBn.findIndexedChildRecursive(OAWebBeanConstants.ADVANCED_SEARCH_RADIO_GROUP);
	     if(andOrRdoGrpBn != null)
        {
	       // hide the radio group for  AND / OR search option
	       andOrRdoGrpBn.setRendered(false);
        }
      }

      if (isProcLogEnabled)
      {
        pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
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
  }

}
