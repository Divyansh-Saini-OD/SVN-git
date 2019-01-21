{\rtf1\ansi\ansicpg1252\deff0{\fonttbl{\f0\fnil\fcharset0 Courier New;}}
{\*\generator Msftedit 5.41.15.1515;}\viewkind4\uc1\pard\lang1033\f0\fs20 <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">\par
<%@ page import="java.sql.*" %>\par
<%@ page import="oracle.jdbc.driver.*" %>\par
<%@ page import="java.lang.String.*" %>\par
<%@ page import="oracle.jdbc.OracleTypes" %>\par
<%@ page import="java.util.*, java.lang.*" %>\par
<%@ page import="java.lang.*" %>\par
<%@ page import="oracle.apps.jtf.aom.transaction.TransactionScope" %>\par
<html lang="en-US"><head><META http-equiv="Content-Type" content="text/html; charset=utf-8">\par
<meta http-equiv="X-UA-Compatible" content="IE=EmulateIE7">\par
<link rel="shortcut icon" href="/Worder/OD.ico" type="image/x-icon">\par
<title>Office Depot \endash  Work Order Service Receipt</title>\par
<base>\par
<LINK rel="shortcut icon" type=Worder/x-icon href="Worder/OD.ico">\par
<LINK rel="stylesheet" type="text/css" href="Worder/header.css">\par
<LINK rel="stylesheet" type="text/css" href="Worder/master.css">\par
<LINK rel="stylesheet" type="text/css"  href="Worder/work_order_receipt.css">\par
<style type="text/css">\par
      .margin,.generaldetails,.header div.bannerSeparator,ul.dash, .footer \{\par
        width: 660px;\par
      \}\par
      .custcolumn table, dl.datacolumn, .datacolumn dt.head \{\par
        width: 240px;\par
      \}\par
\par
      .compcolumn dl.datacolumn \{\par
        width: 255px;\par
      \}\par
\par
      .custcolumn .datacolumn dd \{\par
        width: 92px;\par
      \}\par
      .compcolumn dl.datacolumn dt \{\par
        width: 70px;\par
      \}\par
      .servicescolumn dl.datacolumn dd \{\par
        width: 48px;\par
      \}\par
    </style>\par
<style>\par
                  body\par
                  \{\par
                    background-color:#FFF;\par
                  \}\par
                \par
                  .bannerSeparator\par
                  \{\par
                    background-color:#c00;\par
                  \}\par
</style></head><body><div class="contentContainer">\par
\tab\tab\tab\tab <div class="header">\par
\tab\tab\tab\tab <div class="margin">\par
\tab\tab\tab\tab <div class="content">\par
\tab\tab\tab\tab <div class="logo">\par
\tab\tab\tab\tab <img src="Worder/logo.gif" alt="Office Depot"></div>\par
\tab\tab\tab\tab <div id="banner_secondary" class="bannerSecondary">\par
\tab\tab\tab\tab <div></div>\par
\tab\tab\tab\tab <span class="phonenumber">For help:<span>1-866-483-9162</span></span></div>\par
\tab\tab\tab\tab <div class="bannerSeparator"><span></span></div></div></div></div>\par
\tab\tab\tab\tab <div style="clear: both;"></div><div class="main">\par
\tab\tab\tab\tab   <% String incident_number = request.getParameter("WkOrder"); %>\par
\tab\tab\tab\tab\tab <div class="margin"><div class="content"><ul class="dash"><li><span class="propertyKey">WO#:</span> <span class="error"><%out.println(incident_number);%></span></li></ul>\par
\tab\tab\tab\tab\tab\par
\tab\tab\tab\tab\tab <div style="clear:both"></div>\par
\tab\tab\tab\tab\tab <div class="generaldetails">\par
\tab\tab\tab\tab\tab <table class="generalInfo"><tr>\par
\tab\tab\tab\tab\tab <td class="custcolumn">\par
\tab\tab\tab\tab\tab <dl class="datacolumn">\par
\tab\tab\tab\tab\tab <dt class="head">Customer</dt>\par
\tab\tab\tab\tab <%   \par
\par
\tab\tab\tab\tab OracleConnection oracleconnection = null;\par
\tab\tab\tab\tab oracleconnection = (OracleConnection)TransactionScope.getConnection();\par
\tab\tab\tab\tab\tab String s1="select incident_id request_id,UPPER(tier) transaction_id,incident_attribute_8 email,      incident_attribute_5 name, incident_attribute_2 address, incident_attribute_14 phone,       incident_attribute_15 work_phone from cs_incidents_all_b where incident_number = '"+incident_number+"'";  \par
\tab\tab\tab\tab PreparedStatement  preStatement= oracleconnection.prepareStatement(s1);\par
\tab\tab\tab\tab ResultSet resultset = preStatement.executeQuery();\par
\tab\tab\tab\tab  String s11="";\par
\tab\tab\tab\tab String s12="";\par
\tab\tab\tab\tab  while(resultset.next()) \{\par
\tab\tab\tab\tab\tab  s11 =resultset.getString(1);\par
\tab\tab\tab\tab\tab  s12=resultset.getString(2);\par
\tab\tab\tab\tab   %>\par
\tab\tab\tab\tab <dd><%=resultset.getString(3)%></dd>\par
\tab\tab\tab\tab <dd><%=resultset.getString(4)%></dd>\par
\tab\tab\tab\tab <dd><%=resultset.getString(5)%></dd>\par
\tab\tab\tab\tab <dd>Phone:<%=resultset.getString(6)%></dd>\par
\tab\tab\tab\tab <dd>Work:<%=resultset.getString(7)%></dd>\par
\par
\tab\tab\tab\tab <%\par
\tab\tab\tab\tab\}\par
\tab\tab\tab\tab %>\par
\tab\tab\tab\tab <dd></dd></dl></td>\par
\tab\tab\tab\tab <td class="compcolumn">\par
\tab\tab\tab\tab <dl class="datacolumn" >\par
\tab\tab\tab\tab <dt class="head">Computer</dt>\par
\tab\tab\tab\tab <%\par
\tab\tab\tab\tab if (s12 == null|| "".equals(s12) || "YES".equals(s12) || "NO".equals(s12)) \par
\tab\tab\tab\tab\{\par
\tab        //out.println(s12);\par
               \}\par
\tab\tab\tab    else\par
\tab\tab\tab\{\par
\tab\tab String s2="select qp.node_name,qd.freeform_string from   ies_question_data qd,       ies_questions qp,       ies_panels ip where  ip.panel_id = qp.panel_id and    qp.question_id = qd.question_id and    ip.panel_name = 'Device' and    qd.transaction_id = '"+s12+"' order by qp.question_order "; \par
 PreparedStatement  preStatement1= oracleconnection.prepareStatement(s2);\par
             ResultSet resultset1 = preStatement1.executeQuery();\par
\tab\tab\tab    while(resultset1.next()) \{\par
\tab %>\par
<dt><%=resultset1.getString(1)%>:</dt>\par
<dd><%=resultset1.getString(2)%></dd>\par
\par
\tab\tab\tab\tab <%\par
\}\par
\}\par
\tab\tab\tab\tab %>\par
</dl></td>\par
</tr></table></div>\par
\par
\par
<%\par
String s3="select jtt.name, jtl.task_name ,jll.name status,  jtl.task_id from jtf_tasks_vl jtl,       jtf_task_types_tl jtt,   jtf_task_statuses_tl jll where jll.task_status_id = jtl.task_status_id and   jtt.task_type_id = jtl.task_type_id and   jtl.source_object_id = '"+s11+"' and   jtl.source_object_type_code = 'SR'  order by jtt.name  "; \par
 PreparedStatement  preStatement3= oracleconnection.prepareStatement(s3);\par
             ResultSet resultset3 = preStatement3.executeQuery();\par
\tab\tab\tab  Set vectorName = new Set();\par
\tab\tab\tab  String s17="";\par
\tab\tab\tab    while(resultset3.next()) \par
\tab\tab\tab\tab    \{\par
\tab\tab\tab\tab s17=resultset3.getString(1);\par
\tab\tab\tab\tab String s16 =resultset3.getString(4);\par
\tab\tab\tab\tab\tab if (!vectorName.contains(s16))\par
\tab\tab\tab\tab\tab    \{\par
\par
\tab\tab\tab\tab\tab\tab vectorName.add(s16);\par
\par
%>\par
\tab\tab\tab\tab\tab\tab\tab\tab\par
<div class="detailSectionHed"><span><%=resultset3.getString(1)%></span> Service Details</div>\par
<div class="detailSectionHed detailSectionSubHed">\par
<p id="service_title" class="serviceTitle"><%=resultset3.getString(2)%></p>\par
<p class="serviceStatus"><span class="propertyName"></span>\par
<span id="service_stat"><%=resultset3.getString(3)%></span></p></div>\par
<div class="detailBlock bgwhite">\par
<span class="propertyName"><B>Service Description:</B></span>\par
 <%\par
String s5="select notes from jtf_notes_vl where source_object_code = 'TASK' and   source_object_id = '"+s16+"' and  entered_by_name <> 'CS_ADMIN' "; \par
 PreparedStatement  preStatement5= oracleconnection.prepareStatement(s5);\par
             ResultSet resultset5 = preStatement5.executeQuery();\par
\tab\tab\tab  \tab\tab\tab    while(resultset5.next()) \par
\tab\tab\tab\tab\tab\tab\tab    \{\par
%>\par
<servicedescription><%=resultset5.getString(1)%></servicedescription><br>\par
<%\par
\}\par
%>\par
<br>\par
\par
<% \par
\}\par
else\par
\{\par
%>\par
<div class="detailSectionHed detailSectionSubHed">\par
<p id="service_title" class="serviceTitle"><%=resultset3.getString(2)%></p>\par
<p class="serviceStatus"><span class="propertyName"></span>\par
<span id="service_stat"><%=resultset3.getString(3)%></span></p></div>\par
<div class="detailBlock bgwhite"><p>\par
<span class="propertyName"><B>Service Description:</B></span>\par
 <%\par
String s6="select notes from jtf_notes_vl where source_object_code = 'TASK' and   source_object_id = '"+s16+"' and  entered_by_name <> 'CS_ADMIN' "; \par
 PreparedStatement  preStatement6= oracleconnection.prepareStatement(s6);\par
             ResultSet resultset6 = preStatement6.executeQuery();\par
\tab\tab\tab  \tab\tab\tab    while(resultset6.next()) \par
\tab\tab\tab\tab\tab\tab\tab    \{\par
%>\par
<servicedescription><%=resultset6.getString(1)%></servicedescription><br>\par
<%\par
\}\par
\}\par
%>\par
</div>\par
 \par
\par
\par
<%\par
\}\tab\par
%>\par
</div>\par
 </div>\par
<div style="clear: both;"></div>\par
<div class="tracking"></div>\par
</body></html>\par
}
 