<%@ page
  isThreadSafe = "false"
  language    = "java"
  contentType = "text/html"
  errorPage   = "OAErrorPage.jsp"
%>

<%@ page import="oracle.apps.fnd.common.VersionInfo"%>
<%@ page import="java.util.Enumeration"%>

<%! public static final String RCS_ID = "$Header: aolj_fwkclass_info.jsp 115.3 2003/04/17 22:26:08 rtse ship $"; %>


<%
  if(!"true".equals(request.getSession(true).getValue("aoljtest")))
  {
    out.println("<font color=red>" +
      "ERROR:  This page can only be accessed through " +
      "<a href=aoljtest.jsp>aoljtest.jsp</a>.</font><br>");

    return;
  }
%>

<h1> Version Information for Oracle Self-Service Framework Classes </h1>
<p>
<hr width=100%>

<%! 

   void displayPkgIndex(HttpServletRequest request, HttpServletResponse response, JspWriter out)
			throws java.io.IOException
   {
      Enumeration sl = VersionInfo.getVersionInfo();

      String pkgname = "";
      
      out.println("<h2> Class Index </h2>");
      out.println("<p><a href=aolj_fwkclass_info.jsp?displayType=all> All classes (oracle.apps.*) </a> <br>");
      while (sl.hasMoreElements())
      {
	 String entry = (String)sl.nextElement();

	 String pkg = entry.substring(0,entry.indexOf("#"));

	 if (pkg.compareTo(pkgname) != 0) {
	   pkgname = pkg;
           out.println("<p><a href=aolj_fwkclass_info.jsp?displayType=" + pkgname + ">" + pkgname + "</a> <br>");
	 }
      }
   }


   void displayPkgDetails(HttpServletRequest request, HttpServletResponse response, JspWriter out, String displayType)
			throws java.io.IOException
   {

      Enumeration sl = VersionInfo.getVersionInfo();

      String pkgname = "";

      while (sl.hasMoreElements())
      {
	 String entry = (String)sl.nextElement();

	 String pkg = entry.substring(0,entry.indexOf("#"));
	 String rcs = entry.substring(entry.indexOf("#")+1);

	 if (pkg.compareTo(pkgname) != 0) {
	   pkgname = pkg;
           out.println("<p><a href=aolj_fwkclass_info.jsp?displayType=" + pkgname + ">" + pkgname + "</a> <br>");
	 }
         
         if (pkgname.equals(displayType))
         {
	   out.println(rcs + "<br>");
         }
      }
   }


   void displayAllPkgDetails(HttpServletRequest request, HttpServletResponse response, JspWriter out, String displayType)
			throws java.io.IOException
   {

      Enumeration sl = VersionInfo.getVersionInfo();

      String pkgname = "";

      while (sl.hasMoreElements())
      {
	 String entry = (String)sl.nextElement();

	 String pkg = entry.substring(0,entry.indexOf("#"));
	 String rcs = entry.substring(entry.indexOf("#")+1);

	 if (pkg.compareTo(pkgname) != 0) {
	   pkgname = pkg;
           out.println("<h2>" + pkgname + "</h2><br>");
	 }
         
	 out.println(rcs + "<br>");
      }
   }

%>

<%

   String displayType = request.getParameter("displayType");

   if (displayType == null)
   {
     //System.err.println("display type is null");
   }
   else if ("index".equals(displayType))
   {
     displayPkgIndex(request, response, out);
   }
   else if ("all".equals(displayType))
   {
    displayAllPkgDetails(request, response, out, displayType);
   }
   else
   {
     displayPkgDetails(request, response, out, displayType);
   }
            
%>
</form>


