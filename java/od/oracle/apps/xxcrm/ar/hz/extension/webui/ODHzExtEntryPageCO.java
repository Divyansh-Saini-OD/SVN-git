
package od.oracle.apps.xxcrm.ar.hz.extension.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import java.io.Serializable;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.jbo.common.Diagnostic;
/**
 * Controller for ...
 */
public class ODHzExtEntryPageCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header: /home/cvs/repository/Office_Depot/SRC/CRM/E0255_CDHAdditionalAttributes/3.\040Source\040Code\040&\040Install\040Files/FilesForSVN/ODHzExtEntryPageCO.java,v 1.1 2007/06/29 08:54:48 vjmohan Exp $";
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

    // hide side nav menu
    pageContext.getPageLayoutBean().prepareForRendering(pageContext);
    pageContext.getPageLayoutBean().setStart(null);     
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

    OAApplicationModule am = (OAApplicationModule)pageContext.getRootApplicationModule();

    if (pageContext.getParameter("EntityGo") != null)
    {
      String entity = pageContext.getParameter("EntityChoice");

      Serializable[] parameters =  { entity };
   	  String objId = (String) am.invokeMethod("getObjectId", parameters);

      String objGroupType = null;
      if (entity.equals("HZ_ORGANIZATION_PROFILES"))
        objGroupType = "HZ_ORG_PROFILES_GROUP";
      else if (entity.equals("HZ_PERSON_PROFILES"))
        objGroupType = "HZ_PERSON_PROFILES_GROUP";        
      else if (entity.equals("HZ_PARTY_SITES"))
        objGroupType = "HZ_PARTY_SITES_GROUP";        
      else if (entity.equals("HZ_LOCATIONS"))
        objGroupType = "HZ_LOCATIONS_GROUP";        
      else if (entity.equals("HZ_CREDIT_RATINGS"))
        objGroupType = "HZ_CREDIT_RATINGS_GROUP";  
      else if (entity.equals("HZ_FINANCIAL_NUMBERS"))
        objGroupType = "HZ_FIN_NUMBERS_GROUP";  
      else if (entity.equals("HZ_FINANCIAL_REPORTS"))
        objGroupType = "HZ_FIN_REPORTS_GROUP";  
       
      else 
      {
	objGroupType = entity;
      }

      pageContext.putSessionValue("HzExtObjId", objId);
      pageContext.putSessionValue("HzExtObjGroupType", objGroupType);

      Diagnostic.println("Home page:" + pageContext.getHomePageMenuName());
      pageContext.forwardImmediately("HZ_EXT_SETUP_GROUP", 
                                   RESET_MENU_CONTEXT,
                                   pageContext.getHomePageMenuName(), 
                                   null, 
                                   true, 
                                   ADD_BREAD_CRUMB_YES); 
    }                                   
  }

}
