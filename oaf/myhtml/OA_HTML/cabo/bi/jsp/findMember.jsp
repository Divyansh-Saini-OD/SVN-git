<%@ taglib uri="http://xmlns.oracle.com/bibeans/jsp" prefix="orabi" %>
<%@ taglib uri="http://java.sun.com/jstl/core" prefix="c" %>
<%@ page contentType="text/html;charset=windows-1252"%>

<%-- Start synchronization of the BI tags --%>
<% synchronized(session){ %>
<orabi:BIThinSession id="bisession1"  configuration="/designerOLAPConfig1.xml" >
  <%--  Business Intelligence definition tags here --%>
  <orabi:FindMember id="findMember1" />
</orabi:BIThinSession>

<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
    <title>
      BI Beans JSP Page
    </title>
  </head>

  <body>
    <form name="BIForm" method="POST"  action="findMember.jsp" >
      <%-- Insert your Business Intelligence tags here --%>
      <p/>
      <p/>

      <orabi:Render parentForm="BIForm" targetId="findMember1"/>
      <orabi:InsertHiddenFields parentForm="BIForm"  biThinSessionId="bisession1" />
    </form>

  </body>
</html>
<% } %>
<%-- End synchronization of the BI tags --%>
