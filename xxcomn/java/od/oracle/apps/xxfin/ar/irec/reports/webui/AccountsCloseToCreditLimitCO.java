/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxfin.ar.irec.reports.webui;

import java.io.Serializable;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.beans.OABodyBean;
import od.oracle.apps.xxfin.ar.irec.reports.server.AccountsCloseToCreditLimitAMImpl;
import oracle.apps.fnd.common.MessageToken;

/**
 * Controller for ...
 */
public class AccountsCloseToCreditLimitCO extends OAControllerImpl
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

    OAWebBean body = pageContext.getRootWebBean();
    if (body instanceof OABodyBean)
    {
      ((OABodyBean)body).setBlockOnEverySubmit(true); // this makes sure you can't click a submit button again until first is processed
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

    String sResult;
    if (pageContext.getParameter("SubmitBtn") != null) {

        String sOutstandingAmountLow  = pageContext.getParameter("OutstandingAmountLow");
        String sOutstandingAmountHigh = pageContext.getParameter("OutstandingAmountHigh");
        String sCollectorNumberLow    = pageContext.getParameter("CollectorNumberLow");
        if (sCollectorNumberLow==null || sCollectorNumberLow.equals(""))
            throw new OAException("XXFIN", "ARI_AD_HOC_COLLECTOR_REQUIRED");

        String sCollectorNumberHigh   = pageContext.getParameter("CollectorNumberHigh");
        if (sCollectorNumberHigh==null || sCollectorNumberHigh.equals("")) sCollectorNumberHigh = sCollectorNumberLow;
        
        String sCollectorClass        = pageContext.getParameter("CustomerClassLookupCode");
        String sEmailList             = pageContext.getParameter("EmailList");

        if (sEmailList == null || sEmailList.indexOf("@")<0 || sEmailList.indexOf(".")<0)
            throw new OAException("XXFIN", "ARI_AD_HOC_INVALID_EMAIL");

        try
        {
            Serializable parameters[] = {sOutstandingAmountLow,        sOutstandingAmountHigh,            sCollectorNumberLow, 
                                         sCollectorNumberHigh,         sCollectorClass,                   sEmailList};
            Class paramTypes[] = {  Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.String"),
                                    Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.String") };

            AccountsCloseToCreditLimitAMImpl am = (AccountsCloseToCreditLimitAMImpl)pageContext.getApplicationModule(webBean);
            sResult = (String)am.invokeMethod("SubmitAccountsCloseToCreditLimitReport", parameters, paramTypes);
//              MessageToken[] tokens = null; // { new MessageToken("TOKEN", value) };            
//              throw new OAException("XXFIN", "ARI_AD_HOC_SUBMITTED", tokens, OAException.INFORMATION, null);
        }
        catch(Exception ex)
        {
            throw new OAException("XXFIN", "ARI_AD_HOC_GENERIC_ERROR");
        }
        
        throw new OAException(sResult,OAException.INFORMATION);
    }

  }

}
