/*===========================================================================+
 |   Copyright (c) 2001, 2003 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.cdh.extension.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.jbo.common.Diagnostic;
import com.sun.java.util.collections.HashMap;
import java.io.Serializable;
import java.util.Enumeration;
import java.util.Vector;
import oracle.apps.imc.ocong.util.webui.ImcUtilPkg;
import oracle.apps.fnd.framework.webui.beans.layout.OAFlowLayoutBean;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAWebBeanHelper;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.jbo.Row;
import oracle.jbo.domain.Number;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import com.sun.java.util.collections.ArrayList;

/**
 * Controller for ImcOrgProfieBttnBar
 */
public class ODExtAttributeButtonBarCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header: /home/cvs/repository/Office_Depot/SRC/CRM/E0255_CDHAdditionalAttributes/3.\040Source\040Code\040&\040Install\040Files/FilesForSVN/ODExtAttributeButtonBarCO.java,v 1.1 2007/06/29 08:54:48 vjmohan Exp $";
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

    HashMap params = new HashMap();
    params.put("EntKey", pageContext.getParameter("EntKey"));
    params.put("EntGroup", pageContext.getParameter("EntGroup"));
    params.put("VOClass", pageContext.getParameter("VOClass"));
    params.put("EOClass", pageContext.getParameter("EOClass"));
    params.put("EntName", pageContext.getParameter("EntName"));
    ////Defect# 11538 -- Make SPC Attribute read only for selected roles
    if("Y".equals(pageContext.getParameter("SPCView")))
    {
      params.put("SPCView", "Y");
    }
    //End of Defect# 11538 modifications
    
    OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);
    if (pageContext.getParameter("IMCAPPLYBUTTON") != null || 
        pageContext.getParameter("IMCCANCELBUTTON") != null )
    {
        if (pageContext.getParameter("IMCAPPLYBUTTON") != null )
        {   
            am.invokeMethod("commitTransaction");
            ImcUtilPkg.putConfirmationMessage(pageContext, "IMC_NG_CF_CP_UPDATE", null);
        }    
        if (pageContext.getParameter("IMCCANCELBUTTON") != null )
        {   
            am.getOADBTransaction().rollback();
        } 
		//In either case, release AM and go back to the same page
        pageContext.setForwardURL("XX_CDH_EXT_ATTRIBUTES", 
                                       KEEP_MENU_CONTEXT,
                                       "IMC_NG_MAIN_MENU", 
                                       params, 
                                       false, 
                                       ADD_BREAD_CRUMB_NO,
                                       IGNORE_MESSAGES);
    }

  }

}
