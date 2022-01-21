/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.cdh.ebl.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import od.oracle.apps.xxcrm.cdh.ebl.server.EbillingParamAMImpl;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import java.io.Serializable;

/**
 * Controller for ...
 */
public class ParamCO extends OAControllerImpl
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
    EbillingParamAMImpl am = (EbillingParamAMImpl)pageContext.getRootApplicationModule();

    //initializing the query
    am.invokeMethod("initQuery");
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

    EbillingParamAMImpl am = (EbillingParamAMImpl)pageContext.getRootApplicationModule();

    if (pageContext.getParameter("DeleteButton")!=null){

      am.invokeMethod("deleteRows"); 
      
    }

    if (pageContext.getParameter("SaveButton")!=null){

      try{    
      pageContext.getRootApplicationModule().getOADBTransaction().commit();          
      }
      catch(Exception ex)
      {
        throw new OAException("XXCRM","XXOD_EBL_PARAM_MULTIVAL");
      }



      throw new OAException("All changes have been saved",OAException.INFORMATION);
  }

    if (pageContext.isLovEvent())
   {
     String rowRef = pageContext.getParameter(OAWebBeanConstants.EVENT_SOURCE_ROW_REFERENCE);
     String lovInputSourceId = pageContext.getLovInputSourceId();

     Serializable params[] = {rowRef,lovInputSourceId};

     am.invokeMethod("handleRendering",params);

    // System.out.println("Source LOV: "+ lovInputSourceId);  

     


   
   }
  
  }

}
