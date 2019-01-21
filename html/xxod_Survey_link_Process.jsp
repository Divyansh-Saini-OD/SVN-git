<%@ page import="java.sql.*" %>
<%@ page import="oracle.jdbc.driver.*" %>
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
    <td>
	 <img src="images/ODLOGO.gif" alt="ODLOGO.gif" border="0"><span class="x4b"></span><img src="images/pbs.gif" alt=""></span>
		 </td>
		 	 </tr>
	 <td>
	 <IMG SRC="images/cghes-3.gif" WIDTH="100%" HEIGHT="8" BORDER="0" ALT="">
	 </td>
	 </tr>
	 <tr>
	 <td width="100%" class="OraTableColumnHeader"><b>Store Portal Forms:</b>
		</td>
		
		</tr>
  </table>

<body>
<BR><BR><BR>
<table width="100%" border="0"  BORDERCOLOR =""  align="center" cellpadding="0" cellspacing="0">
   <%
   
 String srRequestNumber = request.getParameter("srID");
 OracleConnection oracleconnection = null;
 oracleconnection = (OracleConnection)TransactionScope.getConnection();
String s1=" select FORM_NAME from XX_CS_STORE_FORTAL_FORM where srnumber='"+srRequestNumber+"' ORDER BY form_name ASC";
 PreparedStatement  preStatement= oracleconnection.prepareStatement(s1);
             ResultSet resultset = preStatement.executeQuery();
              while(resultset.next()) {
				String SR_type1 = resultset.getString(1); 		
				


if ("Bounce Back Coupon will be required".equals(SR_type1))
	{

	%>
 <tr>
  <td class="OraPromptText">
  <a href="xxod_Bounch_Back_Coupon.jsp?srID=<%=srRequestNumber%>">Bounce Back Coupon will be required</a>
  </td>
  </tr>
	<%
}
if ("Register will be required".equals(SR_type1))  
{

	%>
 <tr>
  <td class="OraPromptText">
  <a href="xxod_Register_Prompt.jsp?srID=<%=srRequestNumber%>">Register Prompt will be required </a>
  </td>
  </tr>
	<%
}

if ("Signage will be required".equals(SR_type1))
{
	
%>

<tr>
<td class="OraPromptText">
  <a href="xxod_Request_Signage_Only.jsp?srID=<%=srRequestNumber%>">Signage will be required</a>
  </td>
  </tr>

<%
}
if ("Training will be required".equals(SR_type1))
{
	%>

 <tr>
  <td class="OraPromptText">
  <a href="xxod_Request_Training_Only.jsp?srID=<%=srRequestNumber%>">Training will be required</a>
  </td>
  </tr>

	<%

}
 


	
 
	
	if ("WebTop Button will be required".equals(SR_type1)) 
	{

	%>
 <tr>
  <td class="OraPromptText">
  <a href="xxod_Web_Top_Button.jsp?srID=<%=srRequestNumber%>">WebTop Button will be required</a>
  </td>
  </tr>
	<%
}
}
%>



 <%
   
String s2=" select count(*) from XX_CS_STORE_FORTAL_FORM where FORM_NAME !='null' and srnumber='"+srRequestNumber+"' ";
 PreparedStatement  preStatement2= oracleconnection.prepareStatement(s2);
             ResultSet resultset2 = preStatement2.executeQuery();
              while(resultset2.next()) {
				String SR_type2 = resultset2.getString(1); 

if ("0".equals(SR_type2))

{
PreparedStatement preStatement99 = oracleconnection.prepareStatement("{ call XX_CS_SOP_WF_PKG.INIT_PROC('"+srRequestNumber+"') }");
 preStatement99.execute();

  String redirectURL ="../OA_HTML/ibuhpage.jsp?jtfax=0&jtfay=0&jtfaz=0&jtfaw=n";
  response.sendRedirect(redirectURL);
	
}
}
%>
</table>
<BR><BR>
<BR>
<table cellpadding="0" cellspacing="0" border="0" width="100%" summary=""><tr><td><div class="xv"><span id="N75">Copyright (c) 2006, Oracle. All rights reserved.</span></div></td></tr></table>


