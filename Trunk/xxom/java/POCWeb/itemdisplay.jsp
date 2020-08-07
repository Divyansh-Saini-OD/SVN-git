<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
"http://www.w3.org/TR/html4/loose.dtd">
<%@ page contentType="text/html;charset=windows-1252"%>

<%@ page import="java.util.*,java.text.*"%>
<%
    Vector oItemID = (Vector)request.getAttribute("itemid");
    Vector oItemName = (Vector)request.getAttribute("itemname");
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy hh:mm:ssss a");
%>

<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=windows-1252"/>
    <title>OTC POC - Item Display</title>
    <style type="text/css">
      body {
      background-color: #ffde73; 
}
    </style>
  </head>
  <body><table cellspacing="0" cellpadding="0" border="1" align="center"
               width="100%"
               style="border-color:rgb(0,0,0); border-style:solid;">
      <tr>
        <td>
          <div align="center">
            <strong>Item Name Display</strong>
          </div></td>
      </tr>
      <tr>
        <td>
          <div align="center">
            <strong>Request received at : <%=request.getAttribute("starttime")%></strong>
          </div></td>
      </tr>
      <tr>
        <td>
          <table cellspacing="0" cellpadding="0" border="1" align="center"
                 width="90%"
                 style="border-color:rgb(0,0,0); border-style:solid;">
            <tr>
              <td width="23%">
                <div align="center">
                  <strong>Item ID</strong>
                </div>
              </td>
              <td width="77%">
                <div align="center">
                  <strong>Item Name</strong>
                </div>
              </td>
            </tr>
            <%for(int i=0;i<oItemName.size();i++) {%>
            <tr>
              <td width="23%"><%= (String)oItemID.elementAt(i)%></td>
              <td width="77%"><%= (String)oItemName.elementAt(i)%></td>
            </tr>
            <%}%>
          </table>
        </td>
      </tr>
      <tr>
        <td>
          <div align="center">
            <strong>Request serviced at : <%=sdf.format(new java.util.Date())%></strong>
          </div></td>
      </tr>
      <tr>
        <td>
          <div align="center">
            <input type="button" value="Item ID Selection"
                   onclick="javascript:history.back()"/>
          </div>
        </td>
      </tr>
    </table></body>
</html>