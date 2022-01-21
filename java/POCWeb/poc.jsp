<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
"http://www.w3.org/TR/html4/loose.dtd">
<%@ page contentType="text/html;charset=windows-1252"%>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=windows-1252"/>
    <title>OTC POC</title>
    <style type="text/css">
      body {
      background-color: #ffde73; 
    }
    </style>
  </head>
  <body bgcolor="Gray"><table cellspacing="0" cellpadding="0" border="1" width="100%"
               align="center"
               style="border-color:rgb(0,0,0); border-collapse:collapse; border-style:solid;">
      <tr>
        <td>
          <div align="center">
            <strong>OTC POC Page</strong>
          </div></td>
      </tr>
      <tr>
        <td>
          <form name="frmInput" action="POCControllerServlet" method="post">
            <table cellspacing="0" cellpadding="0" border="1" width="56%"
                   align="center"
                   style="border-color:rgb(0,0,0); border-collapse:collapse; border-style:solid;">
              <tr>
                <td width="24%">Item ID</td>
                <td width="76%">
                  <select size="5" name="lstItemID" multiple="multiple"
                          style="text-align:center;">
                    <option value="11001">11001&nbsp;&nbsp;&nbsp;</option>
                    <option value="22001">22001&nbsp;&nbsp;&nbsp;</option>
                    <option value="24001">24001&nbsp;&nbsp;&nbsp;</option>
                    <option value="23001">23001&nbsp;&nbsp;&nbsp;</option>
                    <option value="25001">25001&nbsp;&nbsp;&nbsp;</option>
                    <option value="24002">24002&nbsp;&nbsp;&nbsp;</option>
                    <option value="25002">25002&nbsp;&nbsp;&nbsp;</option>
                    <option value="25004">25004&nbsp;&nbsp;&nbsp;</option>
                    <option value="25005">25005&nbsp;&nbsp;&nbsp;</option>
                    <option value="25011">25011&nbsp;&nbsp;&nbsp;</option>
                  </select>
                </td>
              </tr>
              <tr>
                <td width="24%">Execute</td>
                <td width="76%">
                  <input type="radio" name="rbExecute" value="S"/>
                  Serially &nbsp;&nbsp;
                  <input type="radio" name="rbExecute" value="P"
                         checked="checked"/>
                  Parallely
                </td>
              </tr>
              <tr>
                <td width="24%" colspan="2">
                  <div align="center">
                    <input type="submit" name="btnSubmit" value="Show Results"/>
                  </div>
                </td>
              </tr>
            </table>
            <input type="hidden" name="hdnAction" value="ItemInput"/>
          </form>
        </td>
      </tr>
    </table></body>
</html>