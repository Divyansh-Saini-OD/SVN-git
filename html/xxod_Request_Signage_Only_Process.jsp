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
	 <td width="100%" class="OraTableColumnHeader"><b>Request Signage Only:</b>
		</td>
		
		</tr>
  </table>
   <% 
          String srRequestNumber1 = request.getParameter("srID");
	 	  String test01 = "Program Start Date:";
		  String test02 = "Program End Date:";
		  String test03 = "Program Type:";
		  String test04 = "Program Type If Other";
		  String test05 = "Signage Display Location:";
		  String test06 = "Signage Display Location:";
		  String test07 = "Signage Display Location:";
		  String test08 = "Signage Display Location:";
		  String test09 = "Signage Display Location:";
		  String test00 = "Signage Display Location:";
		  String test011 = "Signage Display Location:";
		  String test012 = "Signage Display Location If Other:";
		  String test013 = "Enter POG#";
		  String test014 = "How will the signage be funded?:";
		  String test016 = "Vendor Company Name";
		  String test017 = "Vendor Contact Name";
		  String test018 = "Vendor Phone Number";
		  String test019= "Company, Contact, and Phone for each additional Vendor:";
		  String test020= "Creative Development:";
		  String test021= "Production/Shipping:";
		  String test022= "Reason for Request:";
		  String test023= "Message to be Communicated:";
		  String test024= "Legal Disclaimers: ";
		  String test025= "Other Requirements:";
		  String test026= "Product/Sign Attributes:";
		  

		 
		 
		  
     String test1 = request.getParameter("calendar1");
     String test2 = request.getParameter("calendar2");
	 String test3 = request.getParameter("Business_opp25");
	 String test4 = request.getParameter("other");
	 String test5 = request.getParameter("Business_opp2");
	 String test6 = request.getParameter("Business_opp3");
	 String test7 = request.getParameter("Business_opp4");
	 String test8 = request.getParameter("Business_opp5");
	 String test9 = request.getParameter("Business_opp6");
	 String test10 = request.getParameter("Business_opp7");
	 String test11 = request.getParameter("Business_opp8");
	 String test12 = request.getParameter("Business_opp9");
	 String test13 = request.getParameter("Business_opp10");
	 String test14 = request.getParameter("Business_opp11");
	 String test16 = request.getParameter("Business_opp13");
	 String test17 = request.getParameter("Business_opp14");
	 String test18 = request.getParameter("Business_opp15");
	 String test19 = request.getParameter("Business_opp16");
	 String test20 = request.getParameter("Business_opp17");
	 String test21 = request.getParameter("Business_opp18");
	 String test22 = request.getParameter("Business_opp19");
	 String test23 = request.getParameter("Business_opp20");
	 String test24 = request.getParameter("Business_opp21");
	 String test25 = request.getParameter("Business_opp22");
	 String test26 = request.getParameter("Business_opp23");
	 



	 String sr_type = "Signage Only";

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
String s6="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test06+"','"+test6+"','"+sr_type+"')";
             PreparedStatement  preStatement6= oracleconnection.prepareStatement(s6);
             preStatement6.execute();
String s7="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test07+"','"+test7+"','"+sr_type+"')";
             PreparedStatement  preStatement7= oracleconnection.prepareStatement(s7);
             preStatement7.execute();
String s8="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test08+"','"+test8+"','"+sr_type+"')";
             PreparedStatement  preStatement8= oracleconnection.prepareStatement(s8);
             preStatement8.execute();
String s9="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test09+"','"+test9+"','"+sr_type+"')";
             PreparedStatement  preStatement9= oracleconnection.prepareStatement(s9);
             preStatement9.execute();

String s10="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test00+"','"+test10+"','"+sr_type+"')";
             PreparedStatement  preStatement10= oracleconnection.prepareStatement(s10);
             preStatement10.execute();



String s11="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test011+"','"+test11+"','"+sr_type+"')";
             PreparedStatement  preStatement11= oracleconnection.prepareStatement(s11);
             preStatement11.execute();
String s12="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test012+"','"+test12+"','"+sr_type+"')";
             PreparedStatement  preStatement12= oracleconnection.prepareStatement(s12);
             preStatement12.execute();
String s13="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test013+"','"+test13+"','"+sr_type+"')";
             PreparedStatement  preStatement13= oracleconnection.prepareStatement(s13);
             preStatement13.execute();
	
String s14="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test014+"','"+test14+"','"+sr_type+"')";
             PreparedStatement  preStatement14= oracleconnection.prepareStatement(s14);
             preStatement14.execute();
String s16="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test016+"','"+test16+"','"+sr_type+"')";
             PreparedStatement  preStatement16= oracleconnection.prepareStatement(s16);
             preStatement16.execute();
String s17="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test017+"','"+test17+"','"+sr_type+"')";
             PreparedStatement  preStatement17= oracleconnection.prepareStatement(s17);
             preStatement17.execute();
String s18="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test018+"','"+test18+"','"+sr_type+"')";
             PreparedStatement  preStatement18= oracleconnection.prepareStatement(s18);
             preStatement18.execute();
String s19="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test019+"','"+test19+"','"+sr_type+"')";
             PreparedStatement  preStatement19= oracleconnection.prepareStatement(s19);
             preStatement19.execute();
String s20="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test020+"','"+test20+"','"+sr_type+"')";
             PreparedStatement  preStatement20= oracleconnection.prepareStatement(s20);
             preStatement20.execute();




String s21="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test021+"','"+test21+"','"+sr_type+"')";
             PreparedStatement  preStatement21= oracleconnection.prepareStatement(s21);
             preStatement21.execute();

String s22="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test022+"','"+test22+"','"+sr_type+"')";
             PreparedStatement  preStatement22= oracleconnection.prepareStatement(s22);
             preStatement22.execute();

String s23="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test023+"','"+test23+"','"+sr_type+"')";
             PreparedStatement  preStatement23= oracleconnection.prepareStatement(s23);
             preStatement23.execute();

String s24="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test024+"','"+test24+"','"+sr_type+"')";
             PreparedStatement  preStatement24= oracleconnection.prepareStatement(s24);
             preStatement24.execute();

String s25="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test025+"','"+test25+"','"+sr_type+"')";
             PreparedStatement  preStatement25= oracleconnection.prepareStatement(s25);
             preStatement25.execute();

String s26="insert into XX_CS_ISUPPORT_SURVEY(SRNUMBER,Question,Answers,SRTYPE)values('"+srRequestNumber1+"','"+test026+"','"+test26+"','"+sr_type+"')";
             PreparedStatement  preStatement26= oracleconnection.prepareStatement(s26);
             preStatement26.execute();



 String s99="UPDATE XX_CS_STORE_FORTAL_FORM SET FORM_NAME='null' where FORM_NAME='Signage will be required' and SRNUMBER='"+srRequestNumber1+"' " ;
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