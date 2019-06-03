<%@ page
  language    = "java"
  contentType = "text/html"
  import      = "java.lang.*, 
                 java.io.*, 
                 java.util.*, 
                 java.util.zip.*, 
                 java.lang.reflect.Field, 
                 oracle.apps.fnd.framework.webui.OAWebBeanConstants,
                 oracle.jrad.version.Version"
  session     = "false"
%>

<%! public static final String RCS_ID = "$Header: OAInfo.jsp 115.81 2005/05/13 04:59:29 nigoel noship $"; %>

<%
  response.setHeader("Cache-Control", "no-cache,no-store,max-age=0"); // HTTP 1.1
  response.setHeader("Pragma", "no-cache");                           // HTTP 1.0
  response.setDateHeader("Expires", -1);                              // Prevent caching at the proxy server
  if (request.getHeader("User-Agent").indexOf("MSIE") >= 0) 
  { 
    // HTTP 1.1.  Only way to force refresh in IE.
    response.setStatus(HttpServletResponse.SC_RESET_CONTENT); 
  } 
%>
<?xml version="1.0" encoding="iso-8859-1"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
  <head>
    <title>OA Framework Version Information</title>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
    <style type="text/css">
    <!--
    body{margin:10px 10px 10px 10px;font-family:arial,helvetica}
    h1{font-size:20px;font-weight:bold;font-family:arial,helvetica;text-decoration:underline;width:100%;text-align:center}
    table{border-style:none;width:90%;margin-left:auto;margin-right:auto}
    th{font-size:16px;font-weight:bold;font-family:arial,helvetica;text-align:left}
    td{font-size:16px;font-family:arial,helvetica;text-align:left}
    tr:hover{background-color:lightyellow} 
    .gen{text-align:right;margin-bottom:10px;margin-left:0px;color:gray;font-size:10px}
    .cen{postition:absolute;top:0;left:0;right:0;bottom:0;height:50%;width:50%}
    -->
    </style>
  </head>
  <body>
    <div class="cen">
    <h1>OA Framework Version Information</h1>
<%
    final String unknown = "Unknown";

    Class oawbc = Class.forName("oracle.apps.fnd.framework.webui.OAWebBeanConstants");
    String phase, majorVersion, aruVersion, minorVersion;
    try
    {
      phase = (String)oawbc.getDeclaredField("OA_PHASE").get(null);
    }
    catch (Exception e)
    {
      phase = unknown;
    }
    try
    {
      majorVersion = (String)oawbc.getDeclaredField("OA_MAJOR_VERSION").get(null);
    }
    catch (Exception e)
    {
      majorVersion = unknown;
    }
    try
    {
      aruVersion = (String)oawbc.getDeclaredField("OA_ARU_VERSION").get(null);
    }
    catch (Exception e)
    {
      aruVersion = unknown;
    }
    try
    {
      minorVersion = (String)oawbc.getDeclaredField("OA_MINOR_VERSION").get(null);
    }
    catch (Exception e)
    {
      minorVersion = unknown;
    }

    String caboVersion, bc4jVersion;
    try
    {
      caboVersion = (String)oawbc.getDeclaredField("OA_CABO_VERSION").get(null);
    }
    catch (Exception e)
    {
      caboVersion = unknown;
    }
    try
    {
      bc4jVersion = (String)oawbc.getDeclaredField("OA_BC4J_VERSION").get(null);
    }
    catch (Exception e)
    {
      bc4jVersion = unknown;
    }

    Class jver = Class.forName("oracle.adf.mds.version.Version");
    String mdsVersion;
    try
    {
      mdsVersion = (String)jver.getDeclaredField("VER_FULL").get(null)
        + " (build " 
        + jver.getDeclaredField("BUILD_NUM").get(null)
        + ")";
    }
    catch (Exception e)
    {
      mdsVersion = unknown;
    }
%>
    <table>
      <tr>
        <th>OA Framework Version</th>
        <td>11.<%= phase %>.<%= majorVersion %>.<%= aruVersion %>.<%= minorVersion %></td>
      </tr>
      <tr>
        <th>MDS Version</th>
        <td><%= mdsVersion %></td>
      </tr>      
      <tr>
        <th>UIX Version</th>
        <td><%= caboVersion %></td>
      </tr>      
      <tr>
        <th>BC4J Version</th>
        <td><%= bc4jVersion %></td>
      </tr>      
    </table>
    <p class="gen">Generated on <%= new Date() %></p>
    </div>
  </body>
</html>

