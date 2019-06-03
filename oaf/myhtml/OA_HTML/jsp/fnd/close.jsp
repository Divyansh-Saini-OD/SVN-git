<%@ page language="java" %>
<%@ page import="oracle.apps.fnd.common.VersionInfo" %>
<%!
  public static final String RCS_ID =
    "$Header: close.jsp 115.1 2002/10/25 00:07:48 rou noship $";
  public static final boolean RCS_ID_RECORDED =
    VersionInfo.recordClassVersion(RCS_ID,"oa_html.jsp.fnd");
%>
<html>
<body onLoad="closeAndReload()">
<script>
function closeAndReload ()
{
<%
  String domain = request.getParameter("domain");
  if ( domain != null ) out.println("document.domain='" +domain+ "'");

  String reload = request.getParameter("reload");
  if ( reload != null && reload.equalsIgnoreCase("yes") )
  {
     out.println("  if (opener){");
     out.println("    if (opener != null) {");
     out.println("      parent.opener.location.reload();");
     out.println("    }");
     out.println("  }");
    }
%>
  window.close();
}
</script>
</body>
</html>
