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
	 <td width="100%" class="OraTableColumnHeader"><b>Store Portal Form</b>
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
String s01="  select count(srnumber) from XX_CS_ISUPPORT_SURVEY where srnumber='"+srRequestNumber+"' ";
 PreparedStatement  preStatement01= oracleconnection.prepareStatement(s01);
             ResultSet resultset01 = preStatement01.executeQuery();
              while(resultset01.next()) {
				String SR_type1111 = resultset01.getString(1); 

if ("0".equals(SR_type1111))
{
				



String s1=" select ct.name FROM cs_incidents_all_b cb,cs_incident_types_tl ct WHERE  ct.incident_type_id = cb.incident_type_id AND cb.incident_number='"+srRequestNumber+"' ";

 PreparedStatement  preStatement= oracleconnection.prepareStatement(s1);
             ResultSet resultset = preStatement.executeQuery();
              while(resultset.next()) {
				      String SR_type = resultset.getString(1); 

if ("Initiate New Concept or Pilot".equals(SR_type))
{
	
	  String redirectURL = "xxod_Initiate_New_Concept_Pilot.jsp?srID="+srRequestNumber;
	  response.sendRedirect(redirectURL);

}
else if ("Urgent Product Issues".equals(SR_type))
{
	  String redirectURL1 = "xxod_Urgent_Product_Issue.jsp?srID="+srRequestNumber;
	  response.sendRedirect(redirectURL1);

}
else if ("Insert, ROP, or Direct Mail".equals(SR_type))
	{
	String redirectURL2 = "xxod_Insert_ROP_Direct_Mail.jsp?srID="+srRequestNumber;
	 response.sendRedirect(redirectURL2);
	}

	else if ("SKU or UPC Issue".equals(SR_type))
	{
	 String redirectURL3 = "xxod_Sku_Upc_Issue.jsp?srID="+srRequestNumber;
	 response.sendRedirect(redirectURL3);

	}

else if ("Other Store Communication".equals(SR_type))
	{
	String redirectURL4 = "xxod_Other_Store_Portal.jsp?srID="+srRequestNumber;
	 response.sendRedirect(redirectURL4);

	}

else if ("Signage Only".equals(SR_type))
	{
String redirectURL5 = "xxod_Request_Signage_Only.jsp?srID="+srRequestNumber;
	 response.sendRedirect(redirectURL5);
	}

else if ("Training Only".equals(SR_type))
	{
	String redirectURL6 = "xxod_Request_Training_Only.jsp?srID="+srRequestNumber;
	 response.sendRedirect(redirectURL6);

	}

	else if ("Incentive or Contest".equals(SR_type))
	{
String redirectURL7 = "xxod_Request_Incentive_Contest.jsp?srID="+srRequestNumber;
	 response.sendRedirect(redirectURL7);
}

else if ("Bounce Back Coupon".equals(SR_type))
	{
	String redirectURL8 = "xxod_Bounch_Back_Coupon.jsp?srID="+srRequestNumber;
	 response.sendRedirect(redirectURL8);
}

else if ("WebTop Button".equals(SR_type))
	{
	String redirectURL9 = "xxod_Web_Top_Button.jsp?srID="+srRequestNumber;
	 response.sendRedirect(redirectURL9);

	 }
	
else if ("Register Prompt".equals(SR_type))
	{
	String redirectURL10 = "xxod_Register_Prompt.jsp?srID="+srRequestNumber;
	 response.sendRedirect(redirectURL10);

	}

else if ("SOP Update".equals(SR_type))
	{
	String redirectURL11 = "xxod_SOP_Update.jsp?srID="+srRequestNumber;
	 response.sendRedirect(redirectURL11);

  }
  }

}
else
%>

<table>
<tr>
  <td class="OraPromptText"><font color="#CC0000"><B><% out.println("This SR Already Submited the Store Portal Form"); %></b></font>
   </td>
  </tr>
  </table>

  <%
String redirectURL = "xxod_ibuStoreSupportDashboard.jsp?srID="+srRequestNumber;
  response.sendRedirect(redirectURL);

  %>


<table>
<tr>
  <td class="OraPromptText">
  <a href="../OA_HTML/ibuSRDetails.jsp?srID=<%=srRequestNumber%>">Click for SR Update Page</a>
  </td>
  </tr>

  </table>
<%
			
 }
%>

</table>
<BR><BR>

<table cellpadding="0" cellspacing="0" border="0" width="100%" summary=""><tr><td><div class="xv"><span id="N75">Copyright (c) 2006, Oracle. All rights reserved.</span></div></td></tr></table>


