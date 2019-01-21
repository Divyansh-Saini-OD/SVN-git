<%@ page import="java.sql.*" %>
<%@ page import="oracle.jdbc.driver.*" %>
<%@ page import="java.lang.String.*" %>
<%@ page import="oracle.jdbc.OracleTypes" %>
<%@ page import="oracle.apps.jtf.aom.transaction.TransactionScope" %>
<html dir="ltr" lang="en-US-ORACLE9I"><head><title>iSupport Store Fortal Form</title><meta name="generator" content="Oracle UIX">
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

<table border=0 cellspacing=0 cellpadding=0 width='100%' summary=''>
          <tr>
            <td><img ALT=' ' height=21 src='images/ibuutl02.gif' width='7'></td>
            <td nowrap width='100%' class='binHeaderCell'></td>
            <td><img ALT=' ' height=21 src='images/ibuutr02.gif' width='7'></td>
          </tr>
        </table>
<table width='100%' border="1" bordercolor="#000000" cellspacing=1 cellpadding=1 summary='sr'>
    <tr align=center> <th id='c0' class='binColumnHeaderCell'>Program Name</th>
      <th id='c1' class='binColumnHeaderCell'>Module Name</th>
      <th id='c2' class='binColumnHeaderCell'>Error Location</th>
      <th id='c3'  class='binColumnHeaderCell'>Creation Date</th>
      <th id='c4' class='binColumnHeaderCell'>Error Message</th>
	     </tr>
 <%   

 OracleConnection oracleconnection = null;
 oracleconnection = (OracleConnection)TransactionScope.getConnection();
 //String s1="SELECT CB.INCIDENT_NUMBER,CT.NAME,CB.status_flag,CB.CREATED_BY, CB.last_update_date FROM CS_INCIDENTS_ALL_B CB,CS_INCIDENT_TYPES_TL CT WHERE CT.INCIDENT_TYPE_ID = CB.INCIDENT_TYPE_ID  and cb.created_by='1141645' order by cb.last_update_date desc";  
  String s1=" SELECT program_name,module_name,error_location ,to_char(creation_date,'DD_MON_YYYY') as creation_date1, error_message  FROM XX_COM_ERROR_LOG  WHERE module_name IN('CS','CSF') order by creation_date desc ";
   PreparedStatement  preStatement= oracleconnection.prepareStatement(s1);
             ResultSet resultset = preStatement.executeQuery();
              while(resultset.next()) {
   %>
   <tr>
    <td headers='c1' class='tableDataCell'><%=resultset.getString(1)%>&nbsp</a></td>   
	<td headers='c2' class='tableDataCell'><%=resultset.getString(2)%>&nbsp</td>  
	  <td headers='c3' class='tableDataCell'><%=resultset.getString(3)%>&nbsp</td>  
	  <td headers='c4'class='tableDataCell'><%=resultset.getString(4)%>&nbsp</td>  
	  <td headers='c5' class='tableDataCell'><%=resultset.getString(5)%>&nbsp</td>  
	 	 </tr>
 <%
}
%>
 </table>

<BR><BR>
<table cellpadding="0" cellspacing="0" border="0" width="100%" summary=""><tr><td><div class="xv"><span id="N75">Copyright (c) 2006, Oracle. All rights reserved.</span></div></td></tr></table>