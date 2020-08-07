/*===========================================================================+
 |      Copyright (c) 2001 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 | 1.1  17-FEB-2017   MBolli  Thread Leak 12.2.5 Upgrade - close all statements, resultsets |
 +===========================================================================*/
package od.oracle.apps.xxcrm.cdh.extension.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.cabo.ui.data.DictionaryData;
import oracle.jbo.common.Diagnostic;
import com.sun.java.util.collections.HashMap;
import java.io.Serializable;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.imc.ocong.util.webui.ImcUtilPkg;
import oracle.jdbc.OraclePreparedStatement;
import oracle.jdbc.OracleResultSet;
import java.sql.Connection;
import java.sql.SQLException;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;

/**
 * Controller for ...
 */
public class ODExtAttributeGenericCO extends OAControllerImpl
{

  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
    pageContext.writeDiagnostics(METHOD_NAME, "In ODExtAttributeGenericCO", OAFwkConstants.PROCEDURE);
    // Display confirmation message, if any
    ImcUtilPkg.getMessage(pageContext);

    String EntKey  = pageContext.getParameter("EntKey");
    String EntGroup  = pageContext.getParameter("EntGroup");
    String EntName  = pageContext.getParameter("EntName");
    String AttrGroup  = pageContext.getParameter("HzOrgExtPageList");

    OAMessageChoiceBean pagePoplist = (OAMessageChoiceBean)webBean.findChildRecursive("HzOrgExtPageList");

    String pageName = "";

    if (pagePoplist != null)
      pageName = pagePoplist.getSelectionText(pageContext);

    OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);
    pageContext.writeDiagnostics(METHOD_NAME, "pageName: "+  pageName + ", EntGroup: "  + EntGroup + ", EntKey: "  + EntKey + ", transVal: " + am.getOADBTransaction().getTransientValue("pageName"), OAFwkConstants.PROCEDURE);
 
    //Hide Restore and Save buttons when entity attribute group is Billing Documents
    if("85".equals(AttrGroup)){
      if (webBean.findChildRecursive("IMCAPPLYBUTTON") != null)
        webBean.findChildRecursive("IMCAPPLYBUTTON").setRendered(false);
      if (webBean.findChildRecursive("IMCCANCELBUTTON") != null)
        webBean.findChildRecursive("IMCCANCELBUTTON").setRendered(false);
    } else {
      if (webBean.findChildRecursive("IMCAPPLYBUTTON") != null)
        webBean.findChildRecursive("IMCAPPLYBUTTON").setRendered(true);
      if (webBean.findChildRecursive("IMCCANCELBUTTON") != null)
        webBean.findChildRecursive("IMCCANCELBUTTON").setRendered(true);	
    }

    pageContext.writeDiagnostics(METHOD_NAME, "AttrGroup: " + AttrGroup, OAFwkConstants.PROCEDURE);

	if (EntName == null || EntName.length() == 0)
	{
			String sqlStr = " select meaning from FND_LOOKUP_VALUES where lookup_type = 'HZ_EXT_ENTITIES' and LOOKUP_CODE= :1 and LANGUAGE = userenv('LANG') ";

			 OraclePreparedStatement pStatement = null;
			 Connection conn;
			 OracleResultSet rset = null;

			 OADBTransaction transaction = pageContext.getApplicationModule(webBean).getOADBTransaction();

			 try {
				 conn = transaction.getJdbcConnection();
				 pStatement =
						 (OraclePreparedStatement)conn.prepareStatement(sqlStr);
				 pStatement.setString(1, EntGroup);
				 rset =
		(OracleResultSet)pStatement.executeQuery();
				 if (rset.next()) {
					 EntName = rset.getString(1);
				 }
			 } catch (SQLException e) {
				 EntName = "";
			 } finally {
				 try {
					if (rset != null)
						rset.close();
					 if (pStatement != null)
						 pStatement.close();
				 } catch (SQLException e) {
				 }
			 }

	}

	if (EntName == null)
	{
		EntName=EntGroup;
	}
    // set up page title
    StringBuffer pageHeaderText = new StringBuffer(100);
    pageHeaderText.append(((OAPageLayoutBean)webBean).getWindowTitle());
    pageHeaderText.append(" : ");
    pageHeaderText.append(EntName);
    pageHeaderText.append(" : ");
    pageHeaderText.append(EntKey);

    // Set the po-specific page title (which also appears in the breadcrumbs)
    ((OAPageLayoutBean)webBean).setTitle(pageHeaderText.toString());
    ((OAPageLayoutBean)webBean).setWindowTitle(pageHeaderText.toString());

  }

  /**
   * Procedure to handle form submissions for form elements in
   * AK region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormRequest(pageContext, webBean);
  }

}
