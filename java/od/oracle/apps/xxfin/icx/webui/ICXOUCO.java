package od.oracle.apps.xxfin.icx.webui;

import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;


public class ICXOUCO extends OAControllerImpl
{
  // Required for Applications source control
  public static final String RCS_ID="$Header: ICXOUCO.java 115.9 2004/08/04 03:47:07 atgops1 noship $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "od.oracle.apps.xxfin.icx.webui");

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
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean){   
    super.processFormRequest(pageContext, webBean);  
    if (pageContext.getParameter("Save") != null)
    {      
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      am.invokeMethod("apply");

      OAException confirmMessage = new OAException("Saved", OAException.CONFIRMATION);
      pageContext.putDialogMessage(confirmMessage);  // or:  throw new OAException(message, OAException.INFORMATION);
    }
  }

}

