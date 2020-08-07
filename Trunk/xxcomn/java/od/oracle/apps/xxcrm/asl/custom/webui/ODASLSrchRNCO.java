/*===========================================================================+
 |   Copyright (c) 2001, 2003 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                             									 |
 |
 |              Sami Begg       Created
 |  30-NOV-07   Satyasrinivas   Added parameter to pageContext for           |
 |                               putting party_id					         |													 |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asl.custom.webui;

import od.oracle.apps.xxcrm.asl.custom.server.ODASLSrchAMImpl;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import com.sun.java.util.collections.HashMap;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageCheckBoxBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;

import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
//import oracle.apps.cs.csz.common.CszGlobalConstants;

import java.io.Serializable;
import oracle.apps.fnd.framework.OAApplicationModule;

/**
 * Controller for ...
 */
public class ODASLSrchRNCO extends OAControllerImpl
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

    int uid = pageContext.getUserId();
    String userid = new Integer(uid).toString();

    Serializable[] parameters = { userid };
    Class[] paramTypes = { String.class};
    OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);
    am.invokeMethod("initSummary", parameters, paramTypes);
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

	if (pageContext.getParameter("srchbut") != null) {

		String orgname = "";
		String contact = "";
		String address = "";
		String reqstat = "";
		String offline = "";
		String reqstd = "";
		String reqend = "";
		String reqid = "";

		 if (!pageContext.getParameter("orgname").equals(null)){
			orgname = pageContext.getParameter("orgname").toString();
		 }

		 if (!pageContext.getParameter("contact").equals(null)){
			contact = pageContext.getParameter("contact").toString();
		 }

		 if (!pageContext.getParameter("reqstat").equals(null)){
			reqstat = pageContext.getParameter("reqstat").toString();
		 }

		 if (!pageContext.getParameter("address").equals(null)){
			address = pageContext.getParameter("address").toString();
		 }

		 if (!pageContext.getParameter("reqstd").equals(null)){
			reqstd = pageContext.getParameter("reqstd").toString();
		 }

		 if (!pageContext.getParameter("reqend").equals(null)){
			reqend = pageContext.getParameter("reqend").toString();
		 }

		 if (!pageContext.getParameter("createdoffline").equals(null)){
			offline = pageContext.getParameter("createdoffline").toString();
		 }

		 if (!pageContext.getParameter("reqid").equals(null)){
			reqid = pageContext.getParameter("reqid").toString();
		 }

    int uid = pageContext.getUserId();
    String userid = new Integer(uid).toString();

		Serializable[] parameters = { orgname,contact,address,reqstat,offline,reqstd,reqend,reqid,userid };
		Class[] paramTypes = { String.class,String.class,String.class,String.class,String.class,String.class,String.class,String.class,String.class };
		OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);
		am.invokeMethod("buildQuery", parameters, paramTypes);
	}

  if ( "custlink".equals(pageContext.getParameter("event")))  {
      HashMap params = new HashMap();

       params.put("ASNReqFrmCustId", pageContext.getParameter("ASNReqFrmCustId"));
      pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxcrm/asn/common/customer/webui/ODOrgUpdatePG&OAFunc=ASN_ORGUPDATEPG&ASNReqFrmFuncName=ASN_ORGUPDATEPG&retainAM=Y&addBreadCrumb=Y",
                                        null,
                                        KEEP_MENU_CONTEXT,
                                        null,
                                        params,
                                        false,
                                        ADD_BREAD_CRUMB_YES,
                                        IGNORE_MESSAGES);
   }

  }

}
