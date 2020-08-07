// +======================================================================================+
// | Office Depot - Project Simplify                                                      |
// | Providge Consulting                                                                  |
// +======================================================================================+
// |  Class:         XXARConfirmRequestCO.java                                            |
// |  Description:   This class is the controller for the XXARConfirmRequest Page Layout  |
// |                                                                                      |
// |  Change Record:                                                                      |
// |  ==========================                                                          |
// |Version   Date          Author             Remarks                                    |
// |=======   ===========   ================   ========================================== |
// |1.0       26-JUN-2007   BLooman            Initial version                            |
// |                                                                                      |
// +======================================================================================+
package od.oracle.apps.xxfin.ar.irec.invoicecopy.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAStaticStyledTextBean;

/**
 * Controller for ...
 */
public class XXARConfirmRequestCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$ XXARConfirmRequestCO.java 115.10 2007/07/18 03:00:00 bjl noship ";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "od.oracle.apps.xxfin.ar.irec.invoicecopy.webui");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean) {
    super.processRequest(pageContext, webBean);

    // if parameter indicates user has submitted the send invoice copy
    if (pageContext.getParameter("SubmitButton") != null) { 
      // get the Request Id parameter for the submitted send invoice copy
      if (pageContext.getParameter("requestId") != null) {
        String requestId = pageContext.getParameter("requestId");

        MessageToken tokens[] = 
        { new MessageToken("REQUEST_ID", requestId) };
            
        String confirmText = 
          pageContext.getApplicationModule(webBean).getOADBTransaction().getMessage
          ("XXFIN","XX_ARI_0010_CONFIRM_REQUEST",tokens);

        // set the Confirm Text value with the Request Id parameter
        OAStaticStyledTextBean confirmTextBean = 
          (OAStaticStyledTextBean)webBean.findIndexedChildRecursive("ConfirmText");
        if (confirmTextBean != null) { 
          confirmTextBean.setText(pageContext, confirmText);
        }
      }
    } 
  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean) {
    super.processFormRequest(pageContext, webBean);
    
    // if user clicks the OK button, close the window
    if (pageContext.getParameter("OkButton") != null) {
	    pageContext.setForwardURL
      ( "OALogout.jsp?closeWindow=true&menu=Y",
        null,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        null,
        true,
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
        OAWebBeanConstants.IGNORE_MESSAGES );
      
    }
  }

}
