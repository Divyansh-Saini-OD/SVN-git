<%@ page import="java.sql.*" %>
<%@ page import="oracle.jdbc.driver.*" %>
<%@ page import="oracle.jdbc.OracleTypes" %>
<%@ page import="oracle.apps.jtf.aom.transaction.TransactionScope" %>
<html dir="ltr" lang="en-US-ORACLE9I"><head><title>iSupport Store Portal Form </title><meta name="generator" content="Oracle UIX">
<link rel='stylesheet' href='images/jtfucss_sml.css'>
<link rel="stylesheet" charset="UTF-8" type="text/css" href="images/oracle-desktop-custom-2_2_24_5-en-ie-6-windows.css">
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
	 <td width="100%" class="OraTableColumnHeader"><b>System Request - Register Prompt:</b>
		</td>
		
		</tr>
  </table>
   <% 
          String srRequestNumber1 = request.getParameter("srID");
	 	  String test11 = "Prompt Start Date:";
		  String test22 = "Prompt End Date:";
		  String test33 = "Why is Register Prompt needed?";
		  String test44 = "Prompt Messaging:";
		  String test55 = "SKU(s) to Trigger Prompt at POS:";
          


     String test1 = request.getParameter("calendar2");
     String test2 = request.getParameter("calendar3");
	 String test3 = request.getParameter("Business_opp1");
     String test4 = request.getParameter("Business_opp3");
	 String test5 = request.getParameter("Business_opp4");
		 String sr_type = "Register Prompt";

OracleConnection oracleconnection = null;
oracleconnection = (OracleConnection)TransactionScope.getConnection();
String s1="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test11+"','"+test1+"','"+sr_type+"')";
             PreparedStatement  preStatement= oracleconnection.prepareStatement(s1);
             preStatement.execute();

String s2="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test22+"','"+test2+"','"+sr_type+"')";
             PreparedStatement  preStatement2= oracleconnection.prepareStatement(s2);
             preStatement2.execute();

String s3="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test33+"','"+test3+"','"+sr_type+"')";
             PreparedStatement  preStatement3= oracleconnection.prepareStatement(s3);
             preStatement3.execute();

String s4="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test44+"','"+test4+"','"+sr_type+"')";
             PreparedStatement  preStatement4= oracleconnection.prepareStatement(s4);
             preStatement4.execute();

String s5="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test55+"','"+test5+"','"+sr_type+"')";
             PreparedStatement  preStatement5= oracleconnection.prepareStatement(s5);
             preStatement5.execute();

 String s99="UPDATE XX_CS_STORE_FORTAL_FORM SET FORM_NAME='null' where FORM_NAME='Register will be required' and SRNUMBER='"+srRequestNumber1+"' " ;
             PreparedStatement  preStatement99= oracleconnection.prepareStatement(s99);
             preStatement99.execute();



%>
<body>
Successfully inserted 
<BR>
<BR>
<%
     String redirectURL = "xxod_Survey_link_Process.jsp?srID="+srRequestNumber1;
     response.sendRedirect(redirectURL);

%>

<table cellpadding="0" cellspacing="0" border="0" width="100%" summary=""><tr><td><div class="xv"><span id="N75">Copyright (c) 2006, Oracle. All rights reserved.</span></div></td></tr></table>