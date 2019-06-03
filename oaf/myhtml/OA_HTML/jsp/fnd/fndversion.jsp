<%--
 /*===========================================================================+
 |      Copyright (c) 2000 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  FILENAME                                                                 |
 |      fndversion.jsp                                                       | 
 |                                                                           |
 |  DESCRIPTION                                                              |
 |      JSP to get the version info of Java classes that have been loaded.   |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |  HISTORY                                                                  |
 |       16-JUN-00  R Tse Created.                                           |
 +===========================================================================+
 +================= COMMENTS ARE AUTOMATICALLY ADDED BY ARCS ================+
 +=============== DESCRIBE YOUR CURRENT CHANGES DURING CHECK IN =============+
 +===========================================================================+
    The following comments are automatically added by ARCS using your check
    in comment so please describe your current changes during the ARCS 'in'

	$Log: fndversion.jsp,v $
	Revision 115.7  2002/06/14 22:17:04  mskees
	bug 2213954 - modified HTML title and added RUP version info.
	New Dependency on VersionInfo.java 115.7 (and really RUP H)


 +===========================================================================*/
--%>

<%@ page import="oracle.apps.fnd.common.VersionInfo, java.util.*"%>

<%! public static final String RCS_ID =
  "$Header: fndversion.jsp 115.7 2002/06/14 22:17:04 mskees ship $"; %>
<%! public static final boolean RCS_ID_RECORDED =
  VersionInfo.recordClassVersion(RCS_ID,"oa_html.jsp.fnd"); %>

<%
  String versionInfo = "";
  String header, rcsID;
  StringTokenizer tokenizer;
  Enumeration enum = VersionInfo.getPrettyVersionInfo();

	// MSkees - changed the title String to be a bit more informative and added
	// the new RUP version info as a header to this page.
  String html = "<html>\n<title>Applications Class Versions</title>\n<body>\n"
  	+ "<b>Currently Running : " + oracle.apps.fnd.common.VersionInfo.AOLJ_VERSION + "</b>\n";

  while(enum.hasMoreElements())
  {
    header = (String) enum.nextElement();

    if(header.startsWith("$Header:"))
    {
      try
      {
        tokenizer = new StringTokenizer(header);
        tokenizer.nextToken(); // Discard "$Header" string.

        versionInfo += "&nbsp " + tokenizer.nextToken() + " " +
          tokenizer.nextToken() + "<br>" + "\n";
      }
      catch(Exception e)
      {
        versionInfo += "&nbsp " + header + " ?" + "<br>" + "\n";
      }
    }
    else if(header.startsWith("$" + "Header" + "$"))
    {
      versionInfo += "&nbsp " + header + " ?" + "<br>" + "\n";
    }
    else
    {
      versionInfo += "\n" + "<p><b>" + header + "</b><br>" + "\n";
    }
  }

  html += versionInfo + "\n" + "</body></html>";

  out.println(html);
%>
