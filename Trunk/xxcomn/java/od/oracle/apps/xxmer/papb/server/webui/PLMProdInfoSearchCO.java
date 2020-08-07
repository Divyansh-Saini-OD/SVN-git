/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxmer.papb.server.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAImageBean;
import oracle.apps.fnd.framework.webui.OADataBoundValueViewObject;
import od.oracle.apps.xxmer.papb.server.PAPBAMImpl;
import od.oracle.apps.xxmer.papb.server.GenPrdDtlVOImpl;



/**
 * Controller for ...
 */
public class PLMProdInfoSearchCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  protected String m_strForwardURLUpdate;

  public PLMProdInfoSearchCO ()
  {
    m_strForwardURLUpdate = 
        "OA.jsp?page=/od/oracle/apps/xxmer/papb/webui/PLMProductInfoHeaderPG";
  }

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);

     OATableBean table = (OATableBean)webBean.findIndexedChildRecursive("ResultsTable");
    /*if (table == null)
    {
      MessageToken[] tokens = { new MessageToken("OBJECT_NAME", "OrdersTable") };
      throw new OAException("AK", "FWK_TBX_OBJECT_NOT_FOUND", tokens);
    }*/
    OAImageBean prodImageBean = (OAImageBean)table.findIndexedChildRecursive("ProductImage");
    /*if (prodImageBean == null)
    {
      MessageToken[] tokens = { new MessageToken("OBJECT_NAME", "StatusImage") };
      throw new OAException("AK", "FWK_TBX_OBJECT_NOT_FOUND", tokens);
    }*/

    // Define a binding between the image bean and the view object attribute that it
    // will reference to get the appropriate .jpg image value name.
    // Note that the corresponding attribute values are obtained using a decode( ) in the
    // ProdSearchVO view object.
    OADataBoundValueViewObject imageBinding = 
       new OADataBoundValueViewObject(prodImageBean, "ProductImage");

    // Finally tell the image bean where to get the image source attribute
    prodImageBean.setAttributeValue(SOURCE_ATTR, imageBinding);

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

    if("update".equals(pageContext.getParameter(EVENT_PARAM)))
    {
      pageContext.putParameter("MODE","MODE_UPDATE");
      pageContext.setForwardURL(m_strForwardURLUpdate
                                    ,null
                                    ,OAWebBeanConstants.KEEP_MENU_CONTEXT
                                    ,null
                                    ,null
                                    ,true
                                    ,OAWebBeanConstants.ADD_BREAD_CRUMB_YES
                                    ,OAWebBeanConstants.IGNORE_MESSAGES);
    }
  }

}
