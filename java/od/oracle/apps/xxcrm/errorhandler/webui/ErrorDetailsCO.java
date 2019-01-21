/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.errorhandler.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import java.io.Serializable;
import oracle.apps.fnd.framework.OAApplicationModule;

/**
 * Controller for ...
 */
public class ErrorDetailsCO extends OAControllerImpl
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
    if (pageContext.getParameter("Go") != null) 
    {
		  String moduleName = "";
  		String programType = "";
		  String fromDate = "";
		  String toDate = "";

		  if (!pageContext.getParameter("SearchModuleName").equals(null))
      {
        moduleName = pageContext.getParameter("SearchModuleName").toString();
 		  }
		  if (!pageContext.getParameter("SearchProgramType").equals(null))
      {
			  programType = pageContext.getParameter("SearchProgramType").toString();
		  }
 		  if (!pageContext.getParameter("SearchFromDate").equals(null))
      {
			  fromDate = pageContext.getParameter("SearchFromDate").toString();
		  }
 		  if (!pageContext.getParameter("SearchToDate").equals(null))
      {
			  toDate = pageContext.getParameter("SearchToDate").toString();
		  }

      Serializable[] parameters = { moduleName, programType, fromDate, toDate  };
   	  Class[] paramTypes = { String.class,String.class,String.class,String.class };
		  OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);
		  am.invokeMethod("buildQuery", parameters, paramTypes);
    }   
  }

}
