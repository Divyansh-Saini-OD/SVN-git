<!-- $Header: bisviewp.jsp 115.4 2006/02/27 12:33:35 amkulkar noship $ -->
<%@
  page language="java" import="oracle.apps.bis.pmv.common.GenericUtil"
 import="od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillAcrossImpl"
  import="oracle.apps.fnd.common.WebAppsContext"
  import="oracle.apps.bis.pmv.drill.ParamMapHandler"
  import="od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillFactory"
  import="od.oracle.apps.xxcrm.bis.pmv.drill.ODDrillImpl"
  import="java.sql.Connection"
%>
<script type="text/javascript" language="JavaScript">

 function dtl_window(myURL)
 {
   w = window.open(myURL,"crm_detail_wnd","scrollbars,resizable,toolbar,status");
   w.focus();
 }

</script>
<jsp:useBean id="genericUtil" class="oracle.apps.bis.pmv.common.GenericUtil" scope="request"/>
<%


  WebAppsContext webAppsContext = genericUtil.validateContext(request, response);
  if (webAppsContext == null) {
      String dbcFile =  request.getParameter("dbc");
      String host = request.getServerName();
      String port =  new Integer(request.getServerPort()).toString();
      webAppsContext = new WebAppsContext(host,port, dbcFile);
  }

  String  enc = webAppsContext.getProfileStore().getProfile("ICX_CLIENT_IANA_ENCODING");
  response.setContentType("text/html;charset=" + enc);

try {
  Connection conn = webAppsContext.getJDBCConnection();
  //nbarik - 05/15/04 - Enhancement 3576963 - Drill Java Conversion
  //DrillAcrossImpl drillImpl = DrillAcrossImpl.getDrillimplObject( request, webAppsContext, conn, DrillAcrossImpl.PUBLIC_MODE);
  ODDrillImpl drillImpl = ODDrillFactory.getDrillImplObject(request, pageContext, webAppsContext, conn);
  if (drillImpl != null) {
    drillImpl.process();
    drillImpl.redirect();
    response.sendRedirect( drillImpl.getRedirectURL());
  }

 } finally {
    webAppsContext.releaseJDBCConnection();
 }
   //return;
%>

