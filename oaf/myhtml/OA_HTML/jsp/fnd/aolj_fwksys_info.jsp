<%@ page
  language    = "java"
  contentType = "text/html"
  import      = "java.lang.*, java.io.*, java.util.*, java.util.zip.*, oracle.apps.fnd.framework.webui.OAWebBeanConstants"
%>

<%! public static final String RCS_ID = "$Header: aolj_fwksys_info.jsp 115.3 2003/04/17 22:26:07 rtse ship $"; %>

<%-- Turn off caching of contents in this page --%>
<%
  response.setHeader("Cache-Control", "no-cache");
  response.setHeader("Pragma", "no-cache");
  response.setDateHeader("Expires", -1);
  response.setStatus(HttpServletResponse.SC_RESET_CONTENT);
%>

<%
  if(!"true".equals(request.getSession(true).getValue("aoljtest")))
  {
    out.println("<font color=red>" +
      "ERROR:  This page can only be accessed through " +
      "<a href=aoljtest.jsp>aoljtest.jsp</a>.</font><br>");

    return;
  }
%>


<HTML>
  <HEAD>
    <TITLE>Oracle Self Service Framework Information</TITLE>
  </HEAD>
  <BODY>
    <H1>Oracle Self Service Framework Information</H1>
    <HR>
    <H2>Version Information</H2>
<%
    final String phase        = OAWebBeanConstants.OA_PHASE,
                 majorVersion = OAWebBeanConstants.OA_MAJOR_VERSION,
                 minorVersion = OAWebBeanConstants.OA_MINOR_VERSION,
                 buildDate    = OAWebBeanConstants.OA_BUILD_DATE;
%>
    <TABLE BORDER>
      <TR>
        <TH ALIGN="LEFT">Phase</TH>
        <TD><%= phase %></TD>
      </TR>
      <TR>
        <TH ALIGN="LEFT">Major Version</TH>
        <TD><%= majorVersion %></TD>
      </TR>
      <TR>
        <TH ALIGN="LEFT">Minor Version</TH>
        <TD><%= minorVersion %></TD>
      </TR>
      <TR>
        <TH ALIGN="LEFT">Build Date</TH>
        <TD><%= buildDate %></TD>
      </TR>
    </TABLE>
    <HR>
    <H2>System Information</H2>
    <TABLE BORDER>
      <TR>
        <TH ALIGN="LEFT">Java Runtime Environment</TH>
        <TD><%= System.getProperty("java.version") %>
          (<A HREF='<%= System.getProperty("java.vendor.url") %>'><%= System.getProperty("java.vendor") %></A>)
        </TD>
      </TR>
      <TR>
        <TH ALIGN="LEFT">Java Virtual Machine specification</TH>
        <TD><%= System.getProperty("java.vm.specification.name") %> -
            <%= System.getProperty("java.vm.specification.version") %>
            (<%= System.getProperty("java.vm.specification.vendor") %>)
        </TD>
      </TR>
      <TR>
        <TH ALIGN="LEFT">Java Virtual Machine implementation</TH>
        <TD><%= System.getProperty("java.vm.name") %> -
            <%= System.getProperty("java.vm.version") %>
            (<%= System.getProperty("java.vm.vendor") %>)
        </TD>
      </TR>
      <TR>
        <TH ALIGN="LEFT">Java Runtime Environment specification</TH>
        <TD><%= System.getProperty("java.specification.name") %> -
            <%= System.getProperty("java.specification.version") %>
            (<%= System.getProperty("java.specification.vendor") %>)
        </TD>
      </TR>
      <TR>
        <TH ALIGN="LEFT">Operating System</TH>
        <TD><%= System.getProperty("os.name") %> -
            <%= System.getProperty("os.version") %>
            (<%= System.getProperty("os.arch") %>)
        </TD>
      </TR>
      <TR>
        <TH ALIGN="LEFT">Java installation directory</TH>
        <TD><%= System.getProperty("java.home") %></TD>
      </TR>
      <TR>
        <TH ALIGN="LEFT">JVM Locale</TH>
        <TD><%= Locale.getDefault() %></TD>
      </TR>
      <TR>
        <TH ALIGN="LEFT">Oracle Java Server Pages</TH> 
        <TD><%= application.getAttribute("oracle.jsp.versionNumber") %></TD>
      </TR>
      <TR>
        <TH ALIGN="LEFT">Browser</TH>
        <TD><%= request.getHeader("User-Agent") %></TD>
      </TR>
    </TABLE>
    <HR>
    <H2>Request Headers</H2>
    <UL>
<%
    Enumeration headerNames = request.getHeaderNames();
    while (headerNames.hasMoreElements())
    {
      String headerName = (String)headerNames.nextElement();
%>
      <LI><%= headerName %>: <%= request.getHeader(headerName) %></LI>
<%
    }
%>
    </UL>
    <HR>
    <H2>System Classpath</H2>
    <UL>
<%
    String classPath = System.getProperty("java.class.path");
    String pathSep = System.getProperty("path.separator");
    StringTokenizer st = new StringTokenizer(classPath, pathSep);
    while (st.hasMoreTokens())
    {
%>
      <LI><%= st.nextToken() %></LI>
<%
    }
%>
    </UL>
    <HR>
    <EM>Generated on <%= new Date() %></EM>
  </BODY>
</HTML>

