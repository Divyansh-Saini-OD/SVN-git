<%@ page import="java.sql.*" %>
<%@ page import="oracle.jdbc.driver.*" %>
<%@ page import="oracle.jdbc.OracleTypes" %>
<%@ page import="oracle.apps.jtf.aom.transaction.TransactionScope" %>
<html dir="ltr" lang="en-US-ORACLE9I"><head><title>iSupport Store Portal Form</title><meta name="generator" content="Oracle UIX">
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
	 <td width="100%" class="OraTableColumnHeader"><b>Request Incentive/Contest:</b>
		</td>
		
		</tr>
  </table>
   <% 
     String srRequestNumber1 = request.getParameter("srID");
	 	  String test11 = "Incentive Start Date:";
		  String test22 = "Incentive End Date:";
		  String test33 = "Why is the Incentive needed?";
		  String test44 = "What is the proposed Incentive?";
		  String test55 = "What are the benefits of implementing the Incentive?";
		  String test66 = "How will the success of the Incentive be measured?";
          String test77 = "Type of Incentive:";
	      String test88 = "Type of Award:";
	      String test99 = "Type of Award if Other:";





		String sr_type = "Request Incentive or Contest";

     String test1 = request.getParameter("calendar1");
     String test2 = request.getParameter("calendar2");
	 String test3 = request.getParameter("Business_opp1");
     String test4 = request.getParameter("Business_opp2");
	 String test5 = request.getParameter("Business_opp3");
	  String test6 = request.getParameter("Business_opp4");
	   String test7 = request.getParameter("Business_opp5");
	    String test8 = request.getParameter("Business_opp6");
		 String test9 = request.getParameter("other");


		  String test10 = request.getParameter("Addcomp1");
	        String test011 = request.getParameter("Addcomp2");

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

String s6="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test66+"','"+test6+"','"+sr_type+"')";
             PreparedStatement  preStatement6= oracleconnection.prepareStatement(s6);
             preStatement6.execute();
String s7="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test77+"','"+test7+"','"+sr_type+"')";
             PreparedStatement  preStatement7= oracleconnection.prepareStatement(s7);
             preStatement7.execute();
String s8="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test88+"','"+test8+"','"+sr_type+"')";
             PreparedStatement  preStatement8= oracleconnection.prepareStatement(s8);
             preStatement8.execute();
String s9="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test99+"','"+test9+"','"+sr_type+"')";
             PreparedStatement  preStatement9= oracleconnection.prepareStatement(s9);
             preStatement9.execute();
	



String s10="insert into XX_CS_STORE_FORTAL_FORM(SRNUMBER,FORM_NAME,LAST_UPDATE_BY,UPDATE_BY)values('"+srRequestNumber1+"','"+test10+"','','')";
             PreparedStatement  preStatement10= oracleconnection.prepareStatement(s10);
             preStatement10.execute();

String s011="insert into XX_CS_STORE_FORTAL_FORM(SRNUMBER,FORM_NAME,LAST_UPDATE_BY,UPDATE_BY)values('"+srRequestNumber1+"','"+test011+"','','')";
             PreparedStatement  preStatement011= oracleconnection.prepareStatement(s011);
             preStatement011.execute();



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