<%@ page import="java.sql.*" %>
<%@ page import="oracle.jdbc.driver.*" %>
<%@ page import="oracle.jdbc.OracleTypes" %>
<%@ page import="oracle.apps.jtf.aom.transaction.TransactionScope" %>
<html dir="ltr" lang="en-US-ORACLE9I"><head><title>iSupport Store Portal Form </title><meta name="generator" content="Oracle UIX">
<link rel='stylesheet' href='images/jtfucss_sml.css'>
<link rel="stylesheet" charset="UTF-8" type="text/css" href="images/oracle-desktop-custom-2_2_24_5-en-ie-6-windows.css">
<script>
function TimeoutCloseWindow2()
{
	window.setTimeout("window.close()", 1);
}
</script>
 <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0">
  <tr>
    <td>
	 <img src="images/ODLOGO.gif" alt="ODLOGO.gif" border="0"><span class="x4b"></span><img src="images/pbs.gif" alt=""></span>
		 </td>
		 	 </tr>
	 <td>
	 <IMG SRC="images/cghes-3.gif" WIDTH="100%" HEIGHT="8" BORDER="0" ALT="">
	 </td>
	 </tr>
	 <tr>
	 <td width="100%" class="OraTableColumnHeader"><b>SKU or UPC Issue:</b>
		</td>
		
		</tr>
  </table>
   <% 
          String srRequestNumber1 = request.getParameter("srID");
	 	  String test11 = "Select Issue Type:";
          String test1 = request.getParameter("combol");
	 	  String test22 = "Desired Communication Date:";
          String test2 = request.getParameter("calendar2");

     

	 String sr_type = "SKU or UPC Issue";

OracleConnection oracleconnection = null;
oracleconnection = (OracleConnection)TransactionScope.getConnection();
String s2="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test22+"','"+test2+"','"+sr_type+"')";
             PreparedStatement  preStatement1= oracleconnection.prepareStatement(s2);
             preStatement1.execute();

String s1="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test11+"','"+test1+"','"+sr_type+"')";
             PreparedStatement  preStatement= oracleconnection.prepareStatement(s1);
             preStatement.execute();

PreparedStatement preStatement92 = oracleconnection.prepareStatement("{ call XX_CS_SOP_WF_PKG.INIT_PROC('"+srRequestNumber1+"') }");
      preStatement92.execute();


%>
<body>
Successfully inserted 
<BR>
<BR>
<%
    String redirectURL ="../OA_HTML/ibuhpage.jsp?jtfax=0&jtfay=0&jtfaz=0&jtfaw=n";

     response.sendRedirect(redirectURL);

%>


<table cellpadding="0" cellspacing="0" border="0" width="100%" summary=""><tr><td><div class="xv"><span id="N75">Copyright (c) 2006, Oracle. All rights reserved.</span></div></td></tr></table>