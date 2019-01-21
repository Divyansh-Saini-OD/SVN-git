<%@ page import="java.sql.*" %>
<%@ page import="oracle.jdbc.driver.*" %>
<%@ page import="java.lang.String.*" %>
<%@ page import="oracle.jdbc.OracleTypes" %>
<%@ page import="oracle.apps.jtf.aom.transaction.TransactionScope" %>
<html dir="ltr" lang="en-US-ORACLE9I"><head><title>Office Depot - Work Order Service Receipt</title><meta name="generator" content="Oracle UIX">
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
	 <td width="100%" class="OraTableColumnHeader"><b></b>
		</td></tr>
  </table>
  <% String incident_number = request.getParameter("WkOrder"); %>

<table border=0 cellspacing=0 cellpadding=0 width='100%' summary=''>
          <tr>
            <td><img ALT=' ' height=21 src='images/ibuutl02.gif' width='7'></td>
            <td nowrap width='100%' class='binHeaderCell'>Work Order#: <%out.println(incident_number);%></td>
            <td><img ALT=' ' height=21 src='images/ibuutr02.gif' width='7'></td>
          </tr>
        </table>
		<BR>

	<table border="0" cellpadding="5" cellspacing="0" width="800">
<tr>
	<td align="left" valign="top" width="200" class="x3w"><B>Customer</B>
	<%   

 OracleConnection oracleconnection = null;
 oracleconnection = (OracleConnection)TransactionScope.getConnection();
 String s1="select incident_id request_id,UPPER(tier) transaction_id,incident_attribute_8 email,      incident_attribute_5 name, incident_attribute_2 address, incident_attribute_14 phone,       incident_attribute_15 work_phone from apps.cs_incidents_all_b where incident_number = '"+incident_number+"'";  
 PreparedStatement  preStatement= oracleconnection.prepareStatement(s1);
             ResultSet resultset = preStatement.executeQuery();
			 String s11="0";
			 String s12="0";
              while(resultset.next()) {
				 s11 =resultset.getString(1);
				 s12=resultset.getString(2);
				  %>
<table cellpadding="0" cellspacing="0">
   <tr>
    <tr>
   <td width="50%" class="OraPromptText"><%=resultset.getString(3)%></td>
   </tr>
   <tr>
   <td width="50%"  class="OraPromptText"><%=resultset.getString(4)%></td>
   </tr>
   <tr>
   <td width="40%" class="OraPromptText"><%=resultset.getString(5)%></td>
   </tr>
   <tr>
   <td width="50%" class="OraPromptText">Phone :<%=resultset.getString(6)%></td>
   </tr>
   <tr>
   <td width="50%" class="OraPromptText">Work phone:<%=resultset.getString(7)%></td>
   </tr>
   <tr>
    </tr>
  </table>	
  </div>
     
  <%
}
  %>

  </td>
	<td  class="x3w" align="left" valign="top" width="300" ><B>Computer</B>
	<table cellpadding="0" cellspacing="0">
	<tr>
   <td>
<%
if (s12 == null|| "".equals(s12) || "YES".equals(s12) || "NO".equals(s12)) 
{
	//out.println(s12);
}
else
{
	String s2="select qp.node_name,qd.freeform_string from   apps.ies_question_data qd,       apps.ies_questions qp,       apps.ies_panels ip where  ip.panel_id = qp.panel_id and    qp.question_id = qd.question_id and    ip.panel_name = 'Device' and    qd.transaction_id = '"+s12+"' order by qp.question_order "; 
 PreparedStatement  preStatement1= oracleconnection.prepareStatement(s2);
             ResultSet resultset1 = preStatement1.executeQuery();
			   while(resultset1.next()) {
	%>
	<TABLE>
	<TR>
		<TD width="120" class="OraPromptText"><%=resultset1.getString(1)%>:</TD>
		<TD width="150" class="OraPromptText"><%=resultset1.getString(2)%></TD>
	</TR>
	</TABLE>
	

  <%
}
}
  %>
  </td>
 </tr>
   </table>
  
   </td>
<td align="left" valign="top" width="250" >

<table  cellpadding="0" cellspacing="0">
</tr>
<td width="50%" class="OraPromptText">
</td>
</tr>
</table>

</td>
</tr>
</table>

<%
String s4="select jtt.name, jtl.task_id from apps.jtf_tasks_vl jtl,      apps.jtf_task_types_tl jtt,       apps.jtf_task_statuses_tl jll where jll.task_status_id = jtl.task_status_id and   jtt.task_type_id = jtl.task_type_id and   jtl.source_object_id = '"+s11+"' and   jtl.source_object_type_code = 'SR' group by jtt.name, jtl.task_id "; 
 PreparedStatement  preStatement4= oracleconnection.prepareStatement(s4);
             ResultSet resultset4 = preStatement4.executeQuery();
			  String s13="";
			  String s14="0";
			   while(resultset4.next()) {
				 s13 =resultset4.getString(1);
				 s14 =resultset4.getString(2);
			   }
			   %>


<table border=0 cellspacing=0 cellpadding=0 width='100%'>
<tr>
<td class="x3w"><%out.println(s13);%>Details</td>
</tr>
</table>
<%
String s3="select jtl.task_name ,jll.name status from apps.jtf_tasks_vl jtl,     apps.jtf_task_types_tl jtt, apps.jtf_task_statuses_tl jll where jll.task_status_id = jtl.task_status_id and   jtt.task_type_id = jtl.task_type_id and   jtl.source_object_id = '"+s11+"' and   jtl.source_object_type_code = 'SR' order by jtt.name "; 
 PreparedStatement  preStatement3= oracleconnection.prepareStatement(s3);
             ResultSet resultset3 = preStatement3.executeQuery();
			   while(resultset3.next()) {

%>
 <table border=1 cellspacing=0 cellpadding=0 width='100%' bordercolor="#000000" >
          <tr>
            <td  class="OraPromptText" bordercolor="#FFFFFF"><%=resultset3.getString(1)%></td>
            <td  class="OraPromptText" bordercolor="#FFFFFF"><%=resultset3.getString(2)%></td>

 <%
	}
 %>
</tr>
<tr>
 <%
String s5="select notes from apps.jtf_notes_vl where source_object_code = 'TASK' and   source_object_id = '"+s14+"' and   entered_by_name <> 'CS_ADMIN' "; 
 PreparedStatement  preStatement5= oracleconnection.prepareStatement(s5);
             ResultSet resultset5 = preStatement5.executeQuery();
			 			   while(resultset5.next()) {
							   %>

<td  class="OraPromptText" bordercolor="#FFFFFF"><%=resultset5.getString(1)%></td>

<%
}
%>
 </tr>
 </table>
 

<BR><BR>
<table cellpadding="0" cellspacing="0" border="0" width="100%" summary=""><tr><td><div class="xv"><span id="N75">Copyright (c) 2006, Oracle. All rights reserved.</span></div></td></tr></table>