/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.ar.hz.components.account.site.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageRadioButtonBean;

/**
 * Controller for ...
 */
public class XXODChooseSiteSeqCriteraCO extends OAControllerImpl
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
      OAMessageRadioButtonBean siteSeqCriteria = 
        (OAMessageRadioButtonBean)webBean.findChildRecursive("SiteSequence");
      siteSeqCriteria.setName("SiteSeqGroup");
      siteSeqCriteria.setValue("SINGLE");
      siteSeqCriteria.setSelected((boolean)true);

      OAMessageRadioButtonBean siteSeqRangeCriteria = 
        (OAMessageRadioButtonBean)webBean.findChildRecursive("SiteSequenceRange");
      siteSeqRangeCriteria.setName("SiteSeqGroup");
      siteSeqRangeCriteria.setValue("RANGE");
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
