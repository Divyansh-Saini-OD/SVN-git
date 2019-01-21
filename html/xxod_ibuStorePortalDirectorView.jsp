<%@ include file="ibucincl.jsp" %>
<%@ page import="oracle.apps.ibu.common.RendererUtil" %>
<%@ page import="oracle.apps.ibu.config.ConfigContextValuesInfo" %>
<%@ page import="oracle.apps.ibu.config.ConfigDataLoader" %>
<%@ page import="oracle.apps.ibu.config.ConfigFlowPageInfo" %>
<%@ page import="oracle.apps.ibu.config.ConfigItemInfo" %>
<%@ page import="oracle.apps.ibu.config.ConfigPageFlow" %>
<%@ page import="oracle.apps.ibu.config.ConfigRegionItems" %>
<%@ page import="oracle.apps.ibu.config.ConfigRegionKey" %>
<%@ page import="oracle.apps.ibu.requests.ServiceRequestEmailHandler" %>
<%@ page import="oracle.apps.jtf.util.GeneralPreference" %>
<%@ page import="oracle.apps.jtf.base.interfaces.MessageManagerInter" %>
<%@ page import="oracle.apps.jtf.base.resources.AOLMessageManager" %>
<%@ page import="java.sql.*" %>
<%@ page import="oracle.jdbc.driver.*" %>
<%@ page import="oracle.jdbc.OracleTypes" %>
<%@ page import="oracle.apps.jtf.aom.transaction.TransactionScope" %>
<% ibuPermissionName  = "IBU_Request_Create";%>
<%@ include file="ibucinit.jsp" %>
<%

  pageContext.setAttribute("ibuCHeaderFunc", "IBU_SR_CNFG_CREATE_CNFM_TOP");
  pageContext.setAttribute("ibuCLeftFunc", "IBU_SR_CNFG_CREATE_CNFM_LEFT");
  pageContext.setAttribute("ibuCRightFunc", "IBU_SR_CNFG_CREATE_CNFM_RIGHT");
  pageContext.setAttribute("ibuCBottomFunc", "IBU_SR_CNFG_CREATE_CNFM_BOTTOM");
  pageContext.setAttribute("ibuConfigOn", "y");

 // String formName="confirmation";
   long userID = _context.getUserID();
  //out.println(userID);
 %> 
 <%@ include file="ibuchst2.jsp" %>
<%@ include file="ibuchend.jsp" %>
<%@ include file="ibucbst.jsp" %>

<table border=0 cellspacing=0 cellpadding=0 width='100%' summary=''>
          <tr>
            <td><img ALT=' ' height=21 src='../XXCRM_HTML/images/ibuutl02.gif' width='7'></td>
            <td nowrap width='100%' class='binHeaderCell'>Service Requests</td>
            <td><img ALT=' ' height=21 src='../XXCRM_HTML/images/ibuutr02.gif' width='7'></td>
          </tr>
        </table>
<table width='100%' border=0 cellspacing=1 cellpadding=1 summary='sr'>
    <tr align=center> <th id='c0' class='binColumnHeaderCell'>Request Number</th>
      <th id='c1' class='binColumnHeaderCell'>Problem Summary</th>
      <th id='c2' class='binColumnHeaderCell'>Request Type</th>
      <th id='c3' class='binColumnHeaderCell'>Status</th>
      <th id='c4' class='binColumnHeaderCell'>Reported On</th>
	  <th id='c5' class='binColumnHeaderCell'>Last Updated On</th>
	   <th id='c6' class='binColumnHeaderCell'>Created By</th>
    </tr>
	
 <%   

 OracleConnection oracleconnection = null;
 oracleconnection = (OracleConnection)TransactionScope.getConnection();
 //String s1="SELECT CB.INCIDENT_NUMBER,CT.NAME,CB.status_flag,CB.CREATED_BY, CB.last_update_date FROM CS_INCIDENTS_ALL_B CB,CS_INCIDENT_TYPES_TL CT WHERE CT.INCIDENT_TYPE_ID = CB.INCIDENT_TYPE_ID  and cb.created_by='1141645' order by cb.last_update_date desc";  
 // String s1="SELECT CB.INCIDENT_NUMBER, CB.summary Problem_Summary,CT.NAME Request_Type , ST.NAME Status,  TO_CHAR(CB.creation_date, 'DD-Mon-YYYY') AS creation_date , TO_CHAR(CB.last_update_date, 'DD-Mon-YYYY') AS last_update_date  FROM apps.CS_INCIDENTS CB, CS_INCIDENT_TYPES_TL CT , CS_INCIDENT_STATUSES ST  WHERE CT.INCIDENT_TYPE_ID = CB.INCIDENT_TYPE_ID AND ST.INCIDENT_STATUS_ID   = CB.INCIDENT_STATUS_ID AND CB.incident_status_id != 2  AND EXISTS( select b.user_id from per_all_assignments_f a ,  fnd_user b where b.employee_id = a.person_id and  trunc(sysdate) between a.effective_start_date and a.effective_end_date connect by prior a.person_id =a.supervisor_id start with a.supervisor_id = (select employee_id from fnd_user                            where user_id = '"+USERID+"')) order by CB.creation_date desc ";  

  String s1="SELECT CB.INCIDENT_NUMBER,CB.summary Problem_Summary,CT.NAME Request_Type, ST.NAME Status ,  TO_CHAR(CB.creation_date, 'DD-Mon-YYYY')   creation_date ,TO_CHAR(CB.last_update_date, 'DD-Mon-YYYY')  last_update_date ,(select nvl(description, user_name)from fnd_user WHERE user_id=CB.created_by) created_by  FROM apps.CS_INCIDENTS CB,  CS_INCIDENT_TYPES_TL CT   ,  CS_INCIDENT_STATUSES ST   WHERE CT.INCIDENT_TYPE_ID = CB.INCIDENT_TYPE_ID AND ST.INCIDENT_STATUS_ID   = CB.INCIDENT_STATUS_ID AND CB.incident_status_id  != 2 AND EXISTS   (SELECT b.user_id      FROM per_all_assignments_f a ,   fnd_user b  WHERE b.employee_id = a.person_id    AND b.user_id= CB.created_by AND a.created_by= b.user_id CONNECT BY prior a.person_id =a.supervisor_id START   WITH a.supervisor_id = (SELECT employee_id FROM fnd_user WHERE user_id = '"+userID+"') ) ORDER BY  CB.creation_date DESC ";

 PreparedStatement  preStatement= oracleconnection.prepareStatement(s1);
             ResultSet resultset = preStatement.executeQuery();
              while(resultset.next()) {
   %>
   <tr>
    <td headers='c1' class='tableDataCell'><a class="OraLinkText" href="../OA_HTML/xx_ibuSRDetails.jsp?srID=<%=resultset.getString(1)%>"><%=resultset.getString(1)%>&nbsp</a></td>   
	<td headers='c2' class='tableDataCell'><%=resultset.getString(2)%>&nbsp</td>  
	  <td headers='c3' class='tableDataCell'><%=resultset.getString(3)%>&nbsp</td>  
	  <td headers='c4'class='tableDataCell'><%=resultset.getString(4)%>&nbsp</td>  
	  <td headers='c5' class='tableDataCell'><%=resultset.getString(5)%>&nbsp</td>  
	  <td headers='c6' class='tableDataCell'><%=resultset.getString(6)%>&nbsp</td>  
	  <td headers='c7' class='tableDataCell'><%=resultset.getString(7)%>&nbsp</td>  
	 </tr>
 <%
}
%>


<%@ include file="ibucbend.jsp" %>
