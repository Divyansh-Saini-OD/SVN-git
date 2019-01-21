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
	 <td width="100%" class="OraTableColumnHeader"><b>Request Training Only:</b>
		</td>
		
		</tr>
  </table>
   <% 
          
String srRequestNumber1 = request.getParameter("srID");
String test01 = "Is this training for an existing product or program?";
String test02 = "What should the learder be able to do at the conclusion of this training that he or she cannot do now?";
String test03 = "Can the task or the workflow itself bemade easier / simpler? Are there any obstacles preventing Associates from completing this task?";

String test04 = "What is the shelf-life of this product/service? ";

String test05 = "Based on the shelf-life, select training format from available options:";

String test06 = "Who will fund the cost to produce the Product Knowledge Video?";
String test07 = "What marketing or merchandising plans are in place to support this product or service launch?";
String test08 = "What is the expected outcome of this training?";
String test09 = "When does this training need to be available for Associates to complete?";
String test010 = "Special Requests or Other Details:";
		  	 
		 
		  
     String test1 = request.getParameter("Business_opp1");
     String test2 = request.getParameter("Business_opp2");
	 String test3 = request.getParameter("Business_opp3");
	 String test4 = request.getParameter("Business_opp4");
	 String test5 = request.getParameter("checkbox6");
	 String test6 = request.getParameter("checkbox7");

	 String test7 = request.getParameter("checkbox8");
	 String test8 = request.getParameter("checkbox9");
	 String test9 = request.getParameter("checkbox10");
	 String test10 = request.getParameter("checkbox11");
	 String test11 = request.getParameter("checkbox12");
	 String test12 = request.getParameter("checkbox13");
	 String test13 = request.getParameter("checkbox14");
     String test14 = request.getParameter("checkbox15");

	 String test15 = request.getParameter("Business_opp5");
	 String test16 = request.getParameter("checkbox16");
 	 String test17 = request.getParameter("checkbox17");
  	 String test18 = request.getParameter("checkbox18");
   	 String test19 = request.getParameter("checkbox19");
   	 String test20 = request.getParameter("Business_opp6");
  	 String test21 = request.getParameter("calendar1");
	 String test22 = request.getParameter("Business_opp7");

	
  	 

	 String sr_type = "Training Only";

OracleConnection oracleconnection = null;
oracleconnection = (OracleConnection)TransactionScope.getConnection();
String s1="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test01+"','"+test1+"','"+sr_type+"')";
             PreparedStatement  preStatement= oracleconnection.prepareStatement(s1);
             preStatement.execute();

String s2="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test02+"','"+test2+"','"+sr_type+"')";
             PreparedStatement  preStatement2= oracleconnection.prepareStatement(s2);
             preStatement2.execute();

String s3="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test03+"','"+test3+"','"+sr_type+"')";
             PreparedStatement  preStatement3= oracleconnection.prepareStatement(s3);
             preStatement3.execute();

String s4="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test04+"','"+test4+"','"+sr_type+"')";
             PreparedStatement  preStatement4= oracleconnection.prepareStatement(s4);
             preStatement4.execute();
String s5="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test05+"','"+test5+"','"+sr_type+"')";
             PreparedStatement  preStatement5= oracleconnection.prepareStatement(s5);
             preStatement5.execute();

String s6="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test05+"','"+test6+"','"+sr_type+"')";
             PreparedStatement  preStatement6= oracleconnection.prepareStatement(s6);
             preStatement6.execute();




String s7="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test05+"','"+test7+"','"+sr_type+"')";
             PreparedStatement  preStatement7= oracleconnection.prepareStatement(s7);
             preStatement7.execute();
String s8="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test05+"','"+test8+"','"+sr_type+"')";
             PreparedStatement  preStatement8= oracleconnection.prepareStatement(s8);
             preStatement8.execute();

String s9="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test05+"','"+test9+"','"+sr_type+"')";
             PreparedStatement  preStatement9= oracleconnection.prepareStatement(s9);
             preStatement9.execute();

String s10="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test05+"','"+test10+"','"+sr_type+"')";
             PreparedStatement  preStatement10= oracleconnection.prepareStatement(s10);
             preStatement10.execute();



String s11="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test05+"','"+test11+"','"+sr_type+"')";
             PreparedStatement  preStatement11= oracleconnection.prepareStatement(s11);
             preStatement11.execute();
String s12="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test05+"','"+test12+"','"+sr_type+"')";
             PreparedStatement  preStatement12= oracleconnection.prepareStatement(s12);
             preStatement12.execute();
String s13="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test05+"','"+test13+"','"+sr_type+"')";
             PreparedStatement  preStatement13= oracleconnection.prepareStatement(s13);
             preStatement13.execute();

	
String s14="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test05+"','"+test14+"','"+sr_type+"')";
             PreparedStatement  preStatement14= oracleconnection.prepareStatement(s14);
             preStatement14.execute();
String s15="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test06+"','"+test15+"','"+sr_type+"')";
             PreparedStatement  preStatement15= oracleconnection.prepareStatement(s15);
             preStatement15.execute();
String s16="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test07+"','"+test16+"','"+sr_type+"')";
             PreparedStatement  preStatement16= oracleconnection.prepareStatement(s16);
             preStatement16.execute();
String s17="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test07+"','"+test17+"','"+sr_type+"')";
             PreparedStatement  preStatement17= oracleconnection.prepareStatement(s17);            preStatement17.execute();

String s18="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test07+"','"+test18+"','"+sr_type+"')";
             PreparedStatement  preStatement18= oracleconnection.prepareStatement(s18);
             preStatement18.execute();


String s19="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test07+"','"+test19+"','"+sr_type+"')";
             PreparedStatement  preStatement19= oracleconnection.prepareStatement(s19);
             preStatement19.execute();

String s20="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test08+"','"+test20+"','"+sr_type+"')";
             PreparedStatement  preStatement20= oracleconnection.prepareStatement(s20);
             preStatement20.execute();
String s21="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test09+"','"+test21+"','"+sr_type+"')";
             PreparedStatement  preStatement21= oracleconnection.prepareStatement(s21);
             preStatement21.execute();
String s22="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test010+"','"+test22+"','"+sr_type+"')";
             PreparedStatement  preStatement22= oracleconnection.prepareStatement(s22);
             preStatement22.execute();




 String s99="UPDATE XX_CS_STORE_FORTAL_FORM SET FORM_NAME='null' where FORM_NAME='Training will be required' and SRNUMBER='"+srRequestNumber1+"' " ;
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