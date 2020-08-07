package oracle.apps.ar.irec.accountDetails.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.ar.irec.framework.webui.IROAControllerImpl;
import oracle.apps.fnd.framework.webui.beans.OAFormattedTextBean;
/*----------------------------------------------------------------------------
 -- Author: Sridevi Kondoju
 -- Component Id: E1327 and E2052
 -- Script Location: $XXCOMN_TOP/oracle/apps/ar/irec/accountDetails/webui
 -- Description: Considered R12 code version and added custom code.
 -- History:
 -- Name            Date         Version    Description
 -- -----           -----        -------    -----------
 -- Sridevi Kondoju 4-Aug-2016  1.0        Retrofitted for R12.2.5 Upgrade.
---------------------------------------------------------------------------*/

/*===========================================================================+
 |      Copyright (c) 2001 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 |    21-Oct-03  hikumar      Bug # 3186472 - Modified for URL security      | 
 +===========================================================================*/
 
/**
 * Controller for ...
 */
public class AcctDetailsPageLabelCO extends IROAControllerImpl
{
  public static final String RCS_ID="$Header: AcctDetailsPageLabelCO.java 120.2 2008/11/07 12:57:48 avepati noship $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "oracle.apps.ar.irec.accountDetails.webui");

  /**
   * Layout and page setup logic for AK region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
  // Bug # 3186472 - hikumar
  // Modified to replace AccountDetailsPageCO.getParameter with AccountDetailsPageCO.getDecryptedParameter
    String companyLocation = getCompanyLocation(pageContext, webBean,
                     getActiveCustomerId(pageContext,
                         pageContext.getDecryptedParameter(CUSTOMER_ID_KEY )),
                     getActiveCustomerUseId(pageContext,
                         pageContext.getDecryptedParameter( CUSTOMER_SITE_ID_KEY )));


    String customerId = getActiveCustomerId(pageContext);
    if(isNullString(customerId)) 
    {
         OAWebBean rootWebBean = pageContext.getRootWebBean();
         OAWebBean header = rootWebBean.findIndexedChildRecursive("AcctDetailsPageLabel");
         header.setRendered(false);     
    }
	else /*Added for R12 ugrade retrofit */
       {
           pageContext.putSessionValue("XXXcustomerid",getActiveCustomerId(pageContext));
           pageContext.putSessionValue("XXXsiteuseid",getActiveCustomerUseId(pageContext));
       }/*End - Added for R12 ugrade retrofit */
                         
  // if company location is null set the colon before company location to setRendered false
    if("".equals(companyLocation)|| companyLocation==null)
     {
       OAFormattedTextBean colonText = (OAFormattedTextBean) webBean.findIndexedChildRecursive("colon_1");
       colonText.setRendered(false);
     }
     
  }

  /**
   * Procedure to handle form submissions for form elements in
   * AK region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormRequest(pageContext, webBean);
  }

}

