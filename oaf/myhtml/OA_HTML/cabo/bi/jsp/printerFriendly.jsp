<%@ taglib uri="http://xmlns.oracle.com/bibeans/jsp" prefix="orabi" %>
<%@ taglib uri="http://java.sun.com/jstl/core" prefix="c" %>
<%@ page contentType="text/html;charset=windows-1252"%>

<%-- Start synchronization of the BI tags --%>
<% synchronized(session){ %>
<orabi:BIThinSession id="bisession1_xxx"  configuration="/designerOLAPConfig1.xml" >
  <%--  Business Intelligence definition tags here --%>
  <orabi:PrinterFriendlyView id="prnFriendly1" />
</orabi:BIThinSession>

<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
    <title>
      BI Beans JSP Page
    </title>
  </head>

  <body>
    <form name="BIForm" method="POST"  action="printerFriendly.jsp" >
      <%-- Insert your Business Intelligence tags here --%>
      <orabi:Render targetId="prnFriendly1" parentForm="BIForm" />
      <%-- The InsertHiddenFields tag adds state fields to the parent form tag --%>
      <orabi:InsertHiddenFields parentForm="BIForm"  biThinSessionId="bisession1" />
    </form>

  </body>
</html>
<% } %>
<%-- End synchronization of the BI tags --%>
