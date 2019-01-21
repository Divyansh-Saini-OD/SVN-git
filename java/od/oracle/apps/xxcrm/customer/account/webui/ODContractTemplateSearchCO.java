/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.customer.account.webui;

import java.io.Serializable;
import com.sun.java.util.collections.HashMap;
import oracle.apps.fnd.framework.OAFwkConstants;

import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

/**
 * Controller for ...
 */
public class ODContractTemplateSearchCO extends OAControllerImpl
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

    final String METHOD_NAME = "od.oracle.apps.xxcrm.customer.account.webui.ODContractTemplateSearchCO.processFormRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);

    super.processFormRequest(pageContext, webBean);

    OAApplicationModule am = pageContext.getRootApplicationModule();

    if ( pageContext.getParameter("Create") != null)
    {

      pageContext.writeDiagnostics(METHOD_NAME, "Create Button Pressed", OAFwkConstants.PROCEDURE);

   		HashMap params = new HashMap();
	    params.put("mode", "CREATE"); 
      pageContext.forwardImmediately("XX_ASN_CONT_TEMP_CU"
                                      , OAWebBeanConstants.KEEP_MENU_CONTEXT
                                      , null
                                      , params
                                      , true
                                      , OAWebBeanConstants.ADD_BREAD_CRUMB_YES);

    }

    if ("DELETE_TEMPLATE".equalsIgnoreCase(pageContext.getParameter(EVENT_PARAM)))
    {
      pageContext.writeDiagnostics(METHOD_NAME, "on DELETE_TEMPLATE", OAFwkConstants.PROCEDURE);

			MessageToken[] mtokens = { new MessageToken("REQ_VAL", "the Contract Template"),
										new MessageToken("REQ_VAL2",pageContext.getParameter("templateName") ) };
			OAException message = new OAException("XXCRM", "XX_SFA_046_CONFIRM_REMOVAL", mtokens, OAException.CONFIRMATION, null);

			OADialogPage dialogPage = new OADialogPage(OAException.WARNING, message, null, "", "");

			String yes = pageContext.getMessage("XXCRM", "XX_SFA_048_YES", null);
			String no = pageContext.getMessage("XXCRM", "XX_SFA_049_NO", null);

			dialogPage.setOkButtonItemName("DeleteTemplateYesButton");

			dialogPage.setOkButtonToPost(true);
			dialogPage.setNoButtonToPost(true);
			dialogPage.setPostToCallingPage(true);

			// seting  Yes/No labels instead of the default OK/Cancel.
			dialogPage.setOkButtonLabel(yes); 
			dialogPage.setNoButtonLabel(no);

			java.util.Hashtable formParams = new java.util.Hashtable(1); 
			formParams.put("templateId", pageContext.getParameter("templateId")); 
      formParams.put("templateName", pageContext.getParameter("templateName"));
			dialogPage.setFormParameters(formParams); 
	   
			pageContext.redirectToDialogPage(dialogPage);
    }
    if (pageContext.getParameter("DeleteTemplateYesButton") != null)
    {
  		Serializable[] parameters =  { pageContext.getParameter("templateId") };
    	Class[] paramTypes = { String.class };

      am.invokeMethod("deleteTemplate",parameters, paramTypes);

			MessageToken[] mtokens = { new MessageToken("REQ_VAL", "Contract Template "+pageContext.getParameter("templateName")) };
			throw new OAException("XXCRM","XX_SFA_047_DEL_CONFIRM", mtokens, OAException.CONFIRMATION, null);
    }

  }

}
