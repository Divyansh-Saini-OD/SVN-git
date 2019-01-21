<%@ page import="java.sql.*" %>
<%@ page import="oracle.jdbc.driver.*" %>
<%@ page import="java.lang.String.*" %>
<%@ page import="oracle.jdbc.OracleTypes" %>
<%@ page import="oracle.apps.jtf.aom.transaction.TransactionScope" %>
<html dir="ltr" lang="en-US-ORACLE9I"><head><title>iSupport Store Portal Form</title><meta name="generator" content="Oracle UIX">
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
    <td><img src="images/ODLOGO.gif" alt="ODLOGO.gif" border="0"><img src="images/pbs.gif"></td>
	 </td>
		 		 <td><SCRIPT LANGUAGE="JavaScript">
if (window.print) {
document.write('<form> '
+ '<input type=button name=print value="Print this page" '
+ 'onClick="javascript:window.print()"></form>');
}
</script>
		</td>
	 </tr>
	 <td><IMG SRC="images/cghes-3.gif" WIDTH="100%" HEIGHT="8" BORDER="0" ALT=""></td>
	 <td><IMG SRC="images/cghes-3.gif" WIDTH="100%" HEIGHT="8" BORDER="0" ALT=""></td>
	 </tr>
	 <tr>
	 <td width="100%" class="OraTableColumnHeader"><b>Submission Request Details</b></td>
	 <td width="100%" class="OraTableColumnHeader"></td>
	 </tr>
  </table>
  <BR>
<% String srRequestNumber = request.getParameter("srID"); %>
<% 
OracleConnection oracleconnection = null;
oracleconnection = (OracleConnection)TransactionScope.getConnection();
String s222="select summary,EXTERNAL_ATTRIBUTE_5,EXTERNAL_ATTRIBUTE_6 from apps.cs_incidents where incident_number = '"+srRequestNumber+"' ";
PreparedStatement  preStatement222= oracleconnection.prepareStatement(s222);
             ResultSet resultset222 = preStatement222.executeQuery();
              while(resultset222.next()) {

				  %>

	<table  width="100%" align="center" border="1" cellpadding="0" cellspacing="0">
   <tr>
   <td width="40%" class="x18">Service Request </td> <td width="40%" class="x18"><% out.println(srRequestNumber); %></td
   </tr>
   <tr>
   <td width="40%" class="x18">Title </td> <td width="40%" class="x18"><%=resultset222.getString(1)%></td
   </tr>
   <tr>
   <td width="40%" class="x18">Role </td> <td width="40%" class="x18"><%=resultset222.getString(2)%></td
   </tr>
   <tr>
   <td width="40%" class="x18">Target Audience </td> <td width="40%" class="x18"><%=resultset222.getString(3)%></td
  </tr>
  </table>		 
<%
}
                  
%>
<br>
 <%   

 
 String s11=" select srtype from  XX_CS_ISUPPORT_SURVEY where srnumber='"+srRequestNumber+"'and srtype='Initiate New Concept or Pilot' group by srtype ";
PreparedStatement  preStatement11= oracleconnection.prepareStatement(s11);
             ResultSet resultset11 = preStatement11.executeQuery();
              while(resultset11.next()) {
				String SR_type11 = resultset11.getString(1); 

if ("Initiate New Concept or Pilot".equals(SR_type11))

{

%>
<table>
<tr>
<td  class="x18" ><B>Initiate New Concept or Pilot</B>
</td>
</tr>
</table>

<%
	
String s1="select question,answers  FROM XX_CS_ISUPPORT_SURVEY where srnumber='"+srRequestNumber+"' and srtype='Initiate New Concept or Pilot' " ;
 PreparedStatement  preStatement= oracleconnection.prepareStatement(s1);
             ResultSet resultset = preStatement.executeQuery();
              while(resultset.next()) {
                  
%>


  <table  width="100%" border="1"  align="center" cellpadding="0" cellspacing="0">
   <tr>
	  <td width="40%" border="1" BORDERCOLOR ="#CC0000" class="OraPromptText"><%=resultset.getString(1)%></td>  
      <td  width="60%"  class="OraPromptText">
      <textarea wrap name="cause_texta" rows="3" cols="70"><%= resultset.getString(2) %></textarea>  </td>
     </tr>
  </table>

<%
}
}
}
 
  String s22=" select srtype from  XX_CS_ISUPPORT_SURVEY where srnumber='"+srRequestNumber+"'and srtype='Urgent Product Issues' group by srtype ";
PreparedStatement  preStatement22= oracleconnection.prepareStatement(s22);
             ResultSet resultset22 = preStatement22.executeQuery();
              while(resultset22.next()) {
				String SR_type22 = resultset22.getString(1); 

if ("Urgent Product Issues".equals(SR_type22))

{

%>
<table>
<tr>
<td  class="x18" ><B>Urgent Product Issues</B>
</td>
</tr>
</table>
<%
String s2=" select question,answers  FROM XX_CS_ISUPPORT_SURVEY where srnumber='"+srRequestNumber+"' and srtype='Urgent Product Issues' " ;
 PreparedStatement  preStatement2= oracleconnection.prepareStatement(s2);
             ResultSet resultset2 = preStatement2.executeQuery();
              while(resultset2.next()) {
                  
%>

  <table  width="100%" border="1"  align="center" cellpadding="0" cellspacing="0">
   <tr>
	  <td width="40%" border="1" BORDERCOLOR ="#CC0000" class="OraPromptText"><%=resultset2.getString(1)%></td>  
      <td  width="60%"  colspan="2"class="OraPromptText">
      <textarea wrap name="cause_texta" rows="3" cols="70"><%= resultset2.getString(2) %></textarea>  </td>
     </tr>
  </table>


<%
}
}
}



  String s33=" select srtype from  XX_CS_ISUPPORT_SURVEY where srnumber='"+srRequestNumber+"'and srtype='Insert, ROP, or Direct Mail' group by srtype ";
PreparedStatement  preStatement33= oracleconnection.prepareStatement(s33);
             ResultSet resultset33 = preStatement33.executeQuery();
              while(resultset33.next()) {
				String SR_type33 = resultset33.getString(1); 

if ("Insert, ROP, or Direct Mail".equals(SR_type33))

{

%>
<table>
<tr>
<td  class="x18" ><B>Insert, ROP, or Direct Mail</B>
</td>
</tr>
</table>
<%
String s3=" select question,answers  FROM XX_CS_ISUPPORT_SURVEY where srnumber='"+srRequestNumber+"' and srtype='Insert, ROP, or Direct Mail' " ;
 PreparedStatement  preStatement3= oracleconnection.prepareStatement(s3);
             ResultSet resultset3 = preStatement3.executeQuery();
              while(resultset3.next()) {
                  
%>

  <table  width="100%" border="1"  align="center" cellpadding="0" cellspacing="0">
   <tr>
	  <td width="40%" border="1" BORDERCOLOR ="#CC0000" class="OraPromptText"><%=resultset3.getString(1)%></td>  
      <td  width="60%"  colspan="2"class="OraPromptText">
      <textarea wrap name="cause_texta" rows="3" cols="70"><%= resultset3.getString(2) %></textarea>  </td>
     </tr>
  </table>


<%
}
}
}

String s44=" select srtype from  XX_CS_ISUPPORT_SURVEY where srnumber='"+srRequestNumber+"'and srtype='SKU or UPC Issue' group by srtype ";
PreparedStatement  preStatement44= oracleconnection.prepareStatement(s44);
             ResultSet resultset44 = preStatement44.executeQuery();
              while(resultset44.next()) {
				String SR_type44 = resultset44.getString(1); 

if ("SKU or UPC Issue".equals(SR_type44))

{

%>
<table>
<tr>
<td  class="x18" ><B>SKU or UPC Issue</B>
</td>
</tr>
</table>
<%
String s4=" select question,answers  FROM XX_CS_ISUPPORT_SURVEY where srnumber='"+srRequestNumber+"' and srtype='SKU or UPC Issue' " ;
 PreparedStatement  preStatement4= oracleconnection.prepareStatement(s4);
             ResultSet resultset4 = preStatement4.executeQuery();
              while(resultset4.next()) {
                  
%>

  <table  width="100%" border="1"  align="center" cellpadding="0" cellspacing="0">
   <tr>
	  <td width="40%" border="1" BORDERCOLOR ="#CC0000" class="OraPromptText"><%=resultset4.getString(1)%></td>  
      <td  width="60%"  colspan="2"class="OraPromptText">
      <textarea wrap name="cause_texta" rows="3" cols="70"><%= resultset4.getString(2) %></textarea>  </td>
     </tr>
  </table>


<%
}
}
}




String s55=" select srtype from  XX_CS_ISUPPORT_SURVEY where srnumber='"+srRequestNumber+"'and srtype='Other Store Communication' group by srtype ";
PreparedStatement  preStatement55= oracleconnection.prepareStatement(s55);
             ResultSet resultset55 = preStatement55.executeQuery();
              while(resultset55.next()) {
				String SR_type55 = resultset55.getString(1); 

if ("Other Store Communication".equals(SR_type55))

{

%>
<table>
<tr>
<td  class="x18" ><B>Other Store Communication</B>
</td>
</tr>
</table>
<%
String s5=" select question,answers  FROM XX_CS_ISUPPORT_SURVEY where srnumber='"+srRequestNumber+"' and srtype='Other Store Communication' " ;
 PreparedStatement  preStatement5= oracleconnection.prepareStatement(s5);
             ResultSet resultset5 = preStatement5.executeQuery();
              while(resultset5.next()) {
                  
%>

  <table  width="100%" border="1"  align="center" cellpadding="0" cellspacing="0">
   <tr>
	  <td width="40%" border="1" BORDERCOLOR ="#CC0000" class="OraPromptText"><%=resultset5.getString(1)%></td>  
      <td  width="60%"  colspan="2"class="OraPromptText">
      <textarea wrap name="cause_texta" rows="3" cols="70"><%= resultset5.getString(2) %></textarea>  </td>
     </tr>
  </table>


<%
}
}
}


String s66=" select srtype from  XX_CS_ISUPPORT_SURVEY where srnumber='"+srRequestNumber+"'and srtype='Signage Only' group by srtype ";
PreparedStatement  preStatement66= oracleconnection.prepareStatement(s66);
             ResultSet resultset66 = preStatement66.executeQuery();
              while(resultset66.next()) {
				String SR_type66 = resultset66.getString(1); 

if ("Signage Only".equals(SR_type66))

{

%>
<table>
<tr>
<td  class="x18" ><B>Signage Only</B>
</td>
</tr>
</table>
<%
String s6=" select question,answers  FROM XX_CS_ISUPPORT_SURVEY where srnumber='"+srRequestNumber+"' and srtype='Signage Only' " ;

 PreparedStatement  preStatement6= oracleconnection.prepareStatement(s6);
             ResultSet resultset6 = preStatement6.executeQuery();
              while(resultset6.next()) {
                  
%>

  <table  width="100%" border="1"  align="center" cellpadding="0" cellspacing="0">
   <tr>
	  <td width="40%" border="1" BORDERCOLOR ="#CC0000" class="OraPromptText"><%=resultset6.getString(1)%></td>  
      <td  width="60%"  colspan="2"class="OraPromptText">
      <textarea wrap name="cause_texta" rows="3" cols="70"><%= resultset6.getString(2) %></textarea>  </td>
     </tr>
  </table>

<%
}
}
}


String s77=" select srtype from  XX_CS_ISUPPORT_SURVEY where srnumber='"+srRequestNumber+"'and srtype='Training Only' group by srtype ";
PreparedStatement  preStatement77= oracleconnection.prepareStatement(s77);
             ResultSet resultset77 = preStatement77.executeQuery();
              while(resultset77.next()) {
				String SR_type77 = resultset77.getString(1); 

if ("Training Only".equals(SR_type77))

{

%>
<table>
<tr>
<td  class="x18" ><B>Training Only</B>
</td>
</tr>
</table>
<%
String s7=" select question,answers  FROM XX_CS_ISUPPORT_SURVEY where srnumber='"+srRequestNumber+"' and srtype='Training Only' " ;

 PreparedStatement  preStatement7= oracleconnection.prepareStatement(s7);
             ResultSet resultset7 = preStatement7.executeQuery();
              while(resultset7.next()) {
                  
%>

  <table  width="100%" border="1"  align="center" cellpadding="0" cellspacing="0">
   <tr>
	  <td width="40%" border="1" BORDERCOLOR ="#CC0000" class="OraPromptText"><%=resultset7.getString(1)%></td>  
      <td  width="60%"  colspan="2"class="OraPromptText">
      <textarea wrap name="cause_texta" rows="3" cols="70"><%= resultset7.getString(2) %></textarea>  </td>
     </tr>
  </table>

<%
}
}
}


String s88=" select srtype from  XX_CS_ISUPPORT_SURVEY where srnumber='"+srRequestNumber+"'and srtype='Request Incentive or Contest' group by srtype ";
PreparedStatement  preStatement88= oracleconnection.prepareStatement(s88);
             ResultSet resultset88 = preStatement88.executeQuery();
              while(resultset88.next()) {
				String SR_type88 = resultset88.getString(1); 

if ("Request Incentive or Contest".equals(SR_type88))
{

%>
<table>
<tr>
<td  class="x18" ><B>Request Incentive/Contest</B>
</td>
</tr>
</table>
<%
String s8=" select question,answers  FROM XX_CS_ISUPPORT_SURVEY where srnumber='"+srRequestNumber+"' and srtype='Request Incentive or Contest'" ;

 PreparedStatement  preStatement8= oracleconnection.prepareStatement(s8);
             ResultSet resultset8 = preStatement8.executeQuery();
              while(resultset8.next()) {
                  
%>

  <table  width="100%" border="1"  align="center" cellpadding="0" cellspacing="0">
   <tr>
	  <td width="40%" border="1" BORDERCOLOR ="#CC0000" class="OraPromptText"><%=resultset8.getString(1)%></td>  
      <td  width="60%"  colspan="2"class="OraPromptText">
      <textarea wrap name="cause_texta" rows="3" cols="70"><%= resultset8.getString(2) %></textarea>  </td>
     </tr>
  </table>

<%
}
}
}


String s99=" select srtype from  XX_CS_ISUPPORT_SURVEY where srnumber='"+srRequestNumber+"'and srtype='Bounce Back Coupon' group by srtype ";
PreparedStatement  preStatement99= oracleconnection.prepareStatement(s99);
             ResultSet resultset99 = preStatement99.executeQuery();
              while(resultset99.next()) {
				String SR_type99 = resultset99.getString(1); 

if ("Bounce Back Coupon".equals(SR_type99))

{

%>
<table>
<tr>
<td  class="x18" ><B>Bounce Back Coupon</B>
</td>
</tr>
</table>
<%
String s9=" select question,answers  FROM XX_CS_ISUPPORT_SURVEY where srnumber='"+srRequestNumber+"' and srtype='Bounce Back Coupon' " ;

 PreparedStatement  preStatement9= oracleconnection.prepareStatement(s9);
             ResultSet resultset9 = preStatement9.executeQuery();
              while(resultset9.next()) {
                  
%>

  <table  width="100%" border="1"  align="center" cellpadding="0" cellspacing="0">
   <tr>
	  <td width="40%" border="1" BORDERCOLOR ="#CC0000" class="OraPromptText"><%=resultset9.getString(1)%></td>  
      <td  width="60%"  colspan="2"class="OraPromptText">
      <textarea wrap name="cause_texta" rows="3" cols="70"><%= resultset9.getString(2) %></textarea>  </td>
     </tr>
  </table>

<%
}
}
}



String s010=" select srtype from  XX_CS_ISUPPORT_SURVEY where srnumber='"+srRequestNumber+"'and srtype='Web Top Button' group by srtype ";
PreparedStatement  preStatement010= oracleconnection.prepareStatement(s010);
             ResultSet resultset010 = preStatement010.executeQuery();
              while(resultset010.next()) {
				String SR_type010 = resultset010.getString(1); 

if ("Web Top Button".equals(SR_type010))

{

%>
<table>
<tr>
<td  class="x18" ><B>Web Top Button</B>
</td>
</tr>
</table>
<%
String s10=" select question,answers  FROM XX_CS_ISUPPORT_SURVEY where srnumber='"+srRequestNumber+"' and srtype='Web Top Button' " ;

 PreparedStatement  preStatement10= oracleconnection.prepareStatement(s10);
             ResultSet resultset10 = preStatement10.executeQuery();
              while(resultset10.next()) {
                  
%>

  <table  width="100%" border="1"  align="center" cellpadding="0" cellspacing="0">
   <tr>
	  <td width="40%" border="1" BORDERCOLOR ="#CC0000" class="OraPromptText"><%=resultset10.getString(1)%></td>  
      <td  width="60%"  colspan="2"class="OraPromptText">
      <textarea wrap name="cause_texta" rows="3" cols="70"><%= resultset10.getString(2) %></textarea>  </td>
     </tr>
  </table>

<%
}
}
}


String s011=" select srtype from  XX_CS_ISUPPORT_SURVEY where srnumber='"+srRequestNumber+"'and srtype='Register Prompt' group by srtype ";
PreparedStatement  preStatement011= oracleconnection.prepareStatement(s011);
             ResultSet resultset011 = preStatement011.executeQuery();
              while(resultset011.next()) {
				String SR_type011 = resultset011.getString(1); 

if ("Register Prompt".equals(SR_type011))

{

%>
<table>
<tr>
<td  class="x18" ><B>Register Prompt</B>
</td>
</tr>
</table>
<%
String s111=" select question,answers  FROM XX_CS_ISUPPORT_SURVEY where srnumber='"+srRequestNumber+"' and srtype='Register Prompt' " ;

 PreparedStatement  preStatement111= oracleconnection.prepareStatement(s111);
             ResultSet resultset111 = preStatement111.executeQuery();
              while(resultset111.next()) {
                  
%>

  <table  width="100%" border="1"  align="center" cellpadding="0" cellspacing="0">
   <tr>
	  <td width="40%" border="1" BORDERCOLOR ="#CC0000" class="OraPromptText"><%=resultset111.getString(1)%></td>  
      <td  width="60%"  colspan="2"class="OraPromptText">
      <textarea wrap name="cause_texta" rows="3" cols="70"><%= resultset111.getString(2) %></textarea>  </td>
     </tr>
  </table>

<%
}
}
}





String s012=" select srtype from  XX_CS_ISUPPORT_SURVEY where srnumber='"+srRequestNumber+"'and srtype='SOP Update' group by srtype ";
PreparedStatement  preStatement012= oracleconnection.prepareStatement(s012);
             ResultSet resultset012 = preStatement012.executeQuery();
              while(resultset012.next()) {
				String SR_type012 = resultset012.getString(1); 

if ("SOP Update".equals(SR_type012))

{

%>
<table>
<tr>
<td  class="x18" ><B>SOP Update</B>
</td>
</tr>
</table>
<%
String s12=" select question,answers  FROM XX_CS_ISUPPORT_SURVEY where srnumber='"+srRequestNumber+"' and srtype='SOP Update' " ;

 PreparedStatement  preStatement12= oracleconnection.prepareStatement(s12);
             ResultSet resultset12 = preStatement12.executeQuery();
              while(resultset12.next()) {
                  
%>

  <table  width="100%" border="1"  align="center" cellpadding="0" cellspacing="0">
   <tr>
	  <td width="40%" border="1" BORDERCOLOR ="#CC0000" class="OraPromptText"><%=resultset12.getString(1)%></td>  
      <td  width="60%"  colspan="2"class="OraPromptText">
      <textarea wrap name="cause_texta" rows="3" cols="70"><%= resultset12.getString(2) %></textarea>  </td>
     </tr>
  </table>

<%
}
}
}
%>

<BR>
<BR>
<BR>
<table cellpadding="0" cellspacing="0" border="0" width="100%" summary=""><tr><td><div class="xv"><span id="N75">Copyright (c) 2006, Oracle. All rights reserved.</span></div></td></tr></table>