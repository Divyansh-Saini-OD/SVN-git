/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.customer.account.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import java.sql.SQLException;
import oracle.jbo.domain.Number;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import com.sun.java.util.collections.HashMap;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import java.io.Serializable;
import oracle.apps.asn.common.fwk.webui.ASNControllerObjectImpl;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.asn.common.webui.ASNUIUtil;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.table.OAAdvancedTableBean;
import od.oracle.apps.xxcrm.asn.common.fwk.webui.ODASNControllerObjectImpl;

/**
 * Controller for ...
 */
public class ODContractTemplateCreateUpdateCO extends OAControllerImpl
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

    final String METHOD_NAME = "od.oracle.apps.xxcrm.customer.account.webui.ODContractCreateUpdateCO.processRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);

    super.processRequest(pageContext, webBean);

    OAApplicationModule am = pageContext.getApplicationModule(webBean);

    String mode = pageContext.getParameter("mode");

    if (mode.equalsIgnoreCase("UPDATE"))
    {

      pageContext.writeDiagnostics(METHOD_NAME, "UPDATE", OAFwkConstants.PROCEDURE);

      Serializable[] parameters =  { pageContext.getParameter("templateId") };
      Class[] paramTypes = { String.class };

      System.out.println("sudeept update mode "+pageContext.getParameter("templateId"));
    
      am.invokeMethod("initQuery",parameters, paramTypes)   ;
      am.invokeMethod("setUpdate");
 	   ((OAMessageTextInputBean)webBean.findIndexedChildRecursive("TemplateName")).setReadOnly(true);

    }
    else if ( mode.equalsIgnoreCase("CREATE"))
    {

      pageContext.writeDiagnostics(METHOD_NAME, "CREATE", OAFwkConstants.PROCEDURE);

      am.invokeMethod("createTemplate");
      am.invokeMethod("setUpdate");      
    }
    else if (mode.equalsIgnoreCase("DETAILS"))
    {

      pageContext.writeDiagnostics(METHOD_NAME, "DETAILS", OAFwkConstants.PROCEDURE);

      Serializable[] parameters =  { pageContext.getParameter("templateId") };
      Class[] paramTypes = { String.class };
    
      am.invokeMethod("initQuery",parameters, paramTypes)   ;
      am.invokeMethod("setReadOnly");
      ((OAMessageTextInputBean)webBean.findIndexedChildRecursive("TemplateName")).setReadOnly(true);
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

    final String METHOD_NAME = "od.oracle.apps.xxcrm.customer.account.webui.ODContractCreateUpdateCO.processFormRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);


      super.processFormRequest(pageContext, webBean);
      OAApplicationModule am= pageContext.getRootApplicationModule();

    if (pageContext.getParameter("Apply") !=null)
    {

      pageContext.writeDiagnostics(METHOD_NAME, "Apply", OAFwkConstants.PROCEDURE);

      System.out.println("sudeept before apply");

      am.invokeMethod("commitAll");

      System.out.println("sudeept after apply");

      pageContext.putDialogMessage(new OAException("XXCRM","XX_ASN_ACCT_SETUP_ADMIN_CONF", null, OAException.CONFIRMATION, null));


   		HashMap params = new HashMap();
	    params.put("mode", "UPDATE"); 
      params.put("templateId", pageContext.getParameter("TemplateId") );

      pageContext.forwardImmediately("XX_ASN_CONT_TEMP_CU"
                                      , OAWebBeanConstants.KEEP_MENU_CONTEXT
                                      , null
                                      , params
                                      , true
                                      , OAWebBeanConstants.ADD_BREAD_CRUMB_YES);
      
    }
    if (pageContext.getParameter("AddRow") != null)
    {

      pageContext.writeDiagnostics(METHOD_NAME, "Add Row", OAFwkConstants.PROCEDURE);
    
      am.invokeMethod("addRows");
    }

    if (pageContext.getParameter("AddPricePlanRow") != null)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Add Price Plan Row", OAFwkConstants.PROCEDURE);

      am.invokeMethod("addPricePlanRows");
    }
    if (pageContext.getParameter("AddProgramCode") != null)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Add Program Code Row", OAFwkConstants.PROCEDURE);

      am.invokeMethod("addProgCodesRows");
    }

    if ("DELETE_CONTRACT".equalsIgnoreCase(pageContext.getParameter(EVENT_PARAM)))
    {
      pageContext.writeDiagnostics(METHOD_NAME, "DELETE_CONTRACT", OAFwkConstants.PROCEDURE);

			MessageToken[] mtokens = { new MessageToken("REQ_VAL", "the Assigned Contract"),
										new MessageToken("REQ_VAL2",pageContext.getParameter("contAssNumber") ) };
			OAException message = new OAException("XXCRM", "XX_SFA_046_CONFIRM_REMOVAL", mtokens, OAException.CONFIRMATION, null);

			OADialogPage dialogPage = new OADialogPage(OAException.WARNING, message, null, "", "");

			String yes = pageContext.getMessage("XXCRM", "XX_SFA_048_YES", null);
			String no = pageContext.getMessage("XXCRM", "XX_SFA_049_NO", null);

			dialogPage.setOkButtonItemName("DeleteContractYesButton");

			dialogPage.setOkButtonToPost(true);
			dialogPage.setNoButtonToPost(true);
			dialogPage.setPostToCallingPage(true);

			// seting  Yes/No labels instead of the default OK/Cancel.
			dialogPage.setOkButtonLabel(yes); 
			dialogPage.setNoButtonLabel(no);

			java.util.Hashtable formParams = new java.util.Hashtable(1); 
			formParams.put("contAssId", pageContext.getParameter("contAssId")); 
      formParams.put("contAssNumber", pageContext.getParameter("contAssNumber"));
			dialogPage.setFormParameters(formParams); 
	   
			pageContext.redirectToDialogPage(dialogPage);
    }
    if (pageContext.getParameter("DeleteContractYesButton") != null)
    {
  		Serializable[] parameters =  { pageContext.getParameter("contAssId") };
    	Class[] paramTypes = { String.class };

      am.invokeMethod("deleteContract",parameters, paramTypes);

			MessageToken[] mtokens = { new MessageToken("REQ_VAL", "Assigned Contract  "+pageContext.getParameter("contAssNumber")) };
			throw new OAException("XXCRM","XX_SFA_047_DEL_CONFIRM", mtokens, OAException.CONFIRMATION, null);
    }

    if ("DELETE_PP".equalsIgnoreCase(pageContext.getParameter(EVENT_PARAM)))
    {

      pageContext.writeDiagnostics(METHOD_NAME, "DELETE_PRICE_PLAN", OAFwkConstants.PROCEDURE);

			MessageToken[] mtokens = { new MessageToken("REQ_VAL", "the Price Plan"),
										new MessageToken("REQ_VAL2",pageContext.getParameter("ppName") ) };
			OAException message = new OAException("XXCRM", "XX_SFA_046_CONFIRM_REMOVAL", mtokens, OAException.CONFIRMATION, null);

			OADialogPage dialogPage = new OADialogPage(OAException.WARNING, message, null, "", "");

			String yes = pageContext.getMessage("XXCRM", "XX_SFA_048_YES", null);
			String no = pageContext.getMessage("XXCRM", "XX_SFA_049_NO", null);

			dialogPage.setOkButtonItemName("DeletePPYesButton");

			dialogPage.setOkButtonToPost(true);
			dialogPage.setNoButtonToPost(true);
			dialogPage.setPostToCallingPage(true);

			// seting  Yes/No labels instead of the default OK/Cancel.
			dialogPage.setOkButtonLabel(yes); 
			dialogPage.setNoButtonLabel(no);

			java.util.Hashtable formParams = new java.util.Hashtable(1); 
			formParams.put("ppId", pageContext.getParameter("ppId")); 
      formParams.put("ppName", pageContext.getParameter("ppName"));
			dialogPage.setFormParameters(formParams); 
	   
			pageContext.redirectToDialogPage(dialogPage);
    }
    if (pageContext.getParameter("DeletePPYesButton") != null)
    {
  		Serializable[] parameters =  { pageContext.getParameter("ppId") };
    	Class[] paramTypes = { String.class };

      am.invokeMethod("deletePricePlan",parameters, paramTypes);

			MessageToken[] mtokens = { new MessageToken("REQ_VAL", "Price Plan  "+pageContext.getParameter("ppName")) };
			throw new OAException("XXCRM","XX_SFA_047_DEL_CONFIRM", mtokens, OAException.CONFIRMATION, null);
    }

    if ("DELETE_PC".equalsIgnoreCase(pageContext.getParameter(EVENT_PARAM)))
    {

      pageContext.writeDiagnostics(METHOD_NAME, "DELETE_PROG_CODES", OAFwkConstants.PROCEDURE);

			MessageToken[] mtokens = { new MessageToken("REQ_VAL", "the Program Code"),
										new MessageToken("REQ_VAL2",pageContext.getParameter("pcName") ) };
			OAException message = new OAException("XXCRM", "XX_SFA_046_CONFIRM_REMOVAL", mtokens, OAException.CONFIRMATION, null);

			OADialogPage dialogPage = new OADialogPage(OAException.WARNING, message, null, "", "");

			String yes = pageContext.getMessage("XXCRM", "XX_SFA_048_YES", null);
			String no = pageContext.getMessage("XXCRM", "XX_SFA_049_NO", null);

			dialogPage.setOkButtonItemName("DeletePCYesButton");

			dialogPage.setOkButtonToPost(true);
			dialogPage.setNoButtonToPost(true);
			dialogPage.setPostToCallingPage(true);

			// seting  Yes/No labels instead of the default OK/Cancel.
			dialogPage.setOkButtonLabel(yes); 
			dialogPage.setNoButtonLabel(no);

			java.util.Hashtable formParams = new java.util.Hashtable(1); 
			formParams.put("pcId", pageContext.getParameter("pcId")); 
      formParams.put("pcName", pageContext.getParameter("pcName"));
			dialogPage.setFormParameters(formParams); 
	   
			pageContext.redirectToDialogPage(dialogPage);
    }
    if (pageContext.getParameter("DeletePCYesButton") != null)
    {
  		Serializable[] parameters =  { pageContext.getParameter("pcId") };
    	Class[] paramTypes = { String.class };

      am.invokeMethod("deleteProgCode",parameters, paramTypes);

			MessageToken[] mtokens = { new MessageToken("REQ_VAL", "Program Code  "+pageContext.getParameter("pcName")) };
			throw new OAException("XXCRM","XX_SFA_047_DEL_CONFIRM", mtokens, OAException.CONFIRMATION, null);
    }

  }

}
