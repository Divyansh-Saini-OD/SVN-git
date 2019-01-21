<%@ page import="java.sql.*" %>
<%@ page import="oracle.jdbc.driver.*" %>
<%@ page import="oracle.jdbc.OracleTypes" %>
<%@ page import="oracle.apps.jtf.aom.transaction.TransactionScope" %>
<html dir="ltr" lang="en-US-ORACLE9I"><head><title>iSupport Store Fortal Form  </title><meta name="generator" content="Oracle UIX">
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
	 <td width="100%" class="OraTableColumnHeader"><b>System Request - WebTop Button:</b>
		</td>
		
		</tr>
  </table>
   <% 
          String srRequestNumber1 = request.getParameter("srID");
		  String test11 = "Do you want to Add or Delete a WebTop Button?";
	 	  String test22 = "Start Date:";
		  String test33 = "End Date: ";
		  String test44 = "Why is this button needed?";
		  String test55 = "What is the name of the new WebTop Button?";
		  String test66 = "What is the complete URL?";
		  String test77 = "Has the site been tested in a store lab?";
		  String test88 = "What is the mouse-over text?";
		  String test99 = "Where will the WebTop Button reside?";
		  String test111 = "In terms of positioning, what current WebTop Button will this button follow? ";
		  String test222 = "Special Requests or Other Details:";
		  String test333 = "What is the name of the WebTop Button to be deleted?";
		  String test444 = "Deletion Date:";
		 


		


     String test1 = request.getParameter("checkbox1");
     String test2 = request.getParameter("Business_opp1");
	 String test3 = request.getParameter("Business2");
     String test4 = request.getParameter("Business_just");
	 String test5 = request.getParameter("Business_name");
	 String test6 = request.getParameter("Business_URL");
	 String test7 = request.getParameter("Business_opp9");
	 String test8 = request.getParameter("Business_Mouse");
	 String test9 = request.getParameter("Business_opp4");
	 String test10 = request.getParameter("Business_posi");
	 String test12 = request.getParameter("Business_posi1");
	 String test13 = request.getParameter("Business_opp10");
	 String test14 = request.getParameter("calendar2");
	 


	 String sr_type = "Web Top Button";

OracleConnection oracleconnection = null;
oracleconnection = (OracleConnection)TransactionScope.getConnection();
String s13="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test11+"','"+test1+"','"+sr_type+"')";
             PreparedStatement  preStatement13= oracleconnection.prepareStatement(s13);
             preStatement13.execute();

String s1="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test22+"','"+test2+"','"+sr_type+"')";
             PreparedStatement  preStatement= oracleconnection.prepareStatement(s1);
             preStatement.execute();

String s2="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test33+"','"+test3+"','"+sr_type+"')";
             PreparedStatement  preStatement2= oracleconnection.prepareStatement(s2);
             preStatement2.execute();

String s3="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test44+"','"+test4+"','"+sr_type+"')";
             PreparedStatement  preStatement3= oracleconnection.prepareStatement(s3);
             preStatement3.execute();

String s4="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test55+"','"+test5+"','"+sr_type+"')";
             PreparedStatement  preStatement4= oracleconnection.prepareStatement(s4);
             preStatement4.execute();

String s5="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test66+"','"+test6+"','"+sr_type+"')";
             PreparedStatement  preStatement5= oracleconnection.prepareStatement(s5);
             preStatement5.execute();

String s6="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test77+"','"+test7+"','"+sr_type+"')";
             PreparedStatement  preStatement6= oracleconnection.prepareStatement(s6);
             preStatement6.execute();

String s7="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test88+"','"+test8+"','"+sr_type+"')";
             PreparedStatement  preStatement7= oracleconnection.prepareStatement(s7);
             preStatement7.execute();
String s8="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test99+"','"+test9+"','"+sr_type+"')";
             PreparedStatement  preStatement8= oracleconnection.prepareStatement(s8);
             preStatement8.execute();





String s9="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test111+"','"+test10+"','"+sr_type+"')";
             PreparedStatement  preStatement9= oracleconnection.prepareStatement(s9);
             preStatement9.execute();
String s10="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test222+"','"+test12+"','"+sr_type+"')";
             PreparedStatement  preStatement10= oracleconnection.prepareStatement(s10);
             preStatement10.execute();
 String s11="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test333+"','"+test13+"','"+sr_type+"')";
             PreparedStatement  preStatement11= oracleconnection.prepareStatement(s11);
             preStatement11.execute();

 String s12="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test444+"','"+test14+"','"+sr_type+"')";
             PreparedStatement  preStatement12= oracleconnection.prepareStatement(s12);
             preStatement12.execute();




 String s99="UPDATE XX_CS_STORE_FORTAL_FORM SET FORM_NAME='null' where FORM_NAME='WebTop Button will be required' and SRNUMBER='"+srRequestNumber1+"' " ;
             PreparedStatement  preStatement99= oracleconnection.prepareStatement(s99);
             preStatement99.execute();



%>
Successfully inserted 
<BR>
<BR>
<%
     String redirectURL = "xxod_Survey_link_Process.jsp?srID="+srRequestNumber1;
     response.sendRedirect(redirectURL);

%>

<table cellpadding="0" cellspacing="0" border="0" width="100%" summary=""><tr><td><div class="xv"><span id="N75">Copyright (c) 2006, Oracle. All rights reserved.</span></div></td></tr></table>