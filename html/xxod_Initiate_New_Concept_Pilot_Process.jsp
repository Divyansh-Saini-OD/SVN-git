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
	 <td width="100%" class="OraTableColumnHeader"><b>Initiate New Concept or Pilot:</b>
		</td>
		
		</tr>
  </table>
   <% 
     String srRequestNumber1 = request.getParameter("srID");
	 	  String test11 = "Business Opportunity:";
		  String test22 = "Concept/Pilot Requirements:";
		  String test222 = "High Level Scope:";
		  String test33 = "What are the benefits obtained from implementing this Concept/Pilot?";
		  String test44 = "How will the success of the Concept/Pilot be measured?";
		  String test55 = "Constraints:";
		  String sr_type = "Initiate New Concept or Pilot";
		  String test66 = "Desired Program Start Date:";
		  String test77 = "Desired Program End Date:";


     String test1 = request.getParameter("Business_opp1");
     String test2 = request.getParameter("Business_opp2");
	 String test21 = request.getParameter("Business_opp22");
	 String test3 = request.getParameter("Business_opp3");
     String test4 = request.getParameter("Business_opp4");
	 String test5 = request.getParameter("Business_opp5");
	  String test6 = request.getParameter("Addcomp1");
	   String test7 = request.getParameter("Addcomp2");
	    String test8 = request.getParameter("Addcomp3");
		 String test9 = request.getParameter("Addcomp4");
		  String test10 = request.getParameter("Addcomp5");
		  String test111 = request.getParameter("calendar1");
		  String test2222 = request.getParameter("calendar2");


OracleConnection oracleconnection = null;
oracleconnection = (OracleConnection)TransactionScope.getConnection();
String s11="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test66+"','"+test111+"','"+sr_type+"')";
             PreparedStatement  preStatement11= oracleconnection.prepareStatement(s11);
             preStatement11.execute();
String s12="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test77+"','"+test2222+"','"+sr_type+"')";
             PreparedStatement  preStatement12= oracleconnection.prepareStatement(s12);
             preStatement12.execute();

String s1="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test11+"','"+test1+"','"+sr_type+"')";
             PreparedStatement  preStatement= oracleconnection.prepareStatement(s1);
             preStatement.execute();

String s2="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test22+"','"+test2+"','"+sr_type+"')";
             PreparedStatement  preStatement2= oracleconnection.prepareStatement(s2);
             preStatement2.execute();

String s21="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test222+"','"+test21+"','"+sr_type+"')";
             PreparedStatement  preStatement21= oracleconnection.prepareStatement(s21);
             preStatement21.execute();

String s3="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test33+"','"+test3+"','"+sr_type+"')";
             PreparedStatement  preStatement3= oracleconnection.prepareStatement(s3);
             preStatement3.execute();

String s4="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test44+"','"+test4+"','"+sr_type+"')";
             PreparedStatement  preStatement4= oracleconnection.prepareStatement(s4);
             preStatement4.execute();

String s5="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test55+"','"+test5+"','"+sr_type+"')";
             PreparedStatement  preStatement5= oracleconnection.prepareStatement(s5);
             preStatement5.execute();



String s6="insert into XX_CS_STORE_FORTAL_FORM(SRNUMBER,FORM_NAME,LAST_UPDATE_BY,UPDATE_BY)values('"+srRequestNumber1+"','"+test6+"','','')";
             PreparedStatement  preStatement6= oracleconnection.prepareStatement(s6);
             preStatement6.execute();

String s7="insert into XX_CS_STORE_FORTAL_FORM(SRNUMBER,FORM_NAME,LAST_UPDATE_BY,UPDATE_BY)values('"+srRequestNumber1+"','"+test7+"','','')";
             PreparedStatement  preStatement7= oracleconnection.prepareStatement(s7);
             preStatement7.execute();

String s8="insert into XX_CS_STORE_FORTAL_FORM(SRNUMBER,FORM_NAME,LAST_UPDATE_BY,UPDATE_BY)values('"+srRequestNumber1+"','"+test8+"','','')";
             PreparedStatement  preStatement8= oracleconnection.prepareStatement(s8);
             preStatement8.execute();
String s9="insert into XX_CS_STORE_FORTAL_FORM(SRNUMBER,FORM_NAME,LAST_UPDATE_BY,UPDATE_BY)values('"+srRequestNumber1+"','"+test9+"','','')";
             PreparedStatement  preStatement9= oracleconnection.prepareStatement(s9);
             preStatement9.execute();
String s10="insert into XX_CS_STORE_FORTAL_FORM(SRNUMBER,FORM_NAME,LAST_UPDATE_BY,UPDATE_BY)values('"+srRequestNumber1+"','"+test10+"','','')";
             PreparedStatement  preStatement10= oracleconnection.prepareStatement(s10);
             preStatement10.execute();


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