<html dir="ltr" lang="en-US-ORACLE9I"><head><title>iSupport Store Portal Form </title><meta name="generator" content="Oracle UIX">
<link rel='stylesheet' href='images/jtfucss_sml.css'>
<link rel="stylesheet" charset="UTF-8" type="text/css" href="images/oracle-desktop-custom-2_2_24_5-en-ie-6-windows.css">
<script type="text/javascript"> 
function checkform(form) { 
if (form1.calendar2.value == "") {
    alert( "Please Select the Desired Communication Date" );
    form.calendar2.focus();
    return false ;
  }
  	if (form1.combol.value == "") {
    alert( "Please Select the Select Issue Type" );
    form.combol.focus();
    return false ;
  }
  
return true;
}

function test(){
if(document["form1"]["checkbox1"].checked){
document.getElementById("myrow").style.visibility="visible"
}
else{
document.getElementById("myrow").style.visibility="hidden"
}
}
function test1(){
if(document["form1"]["checkbox2"].checked){
document.getElementById("myrow1").style.visibility="visible"
}
else{
document.getElementById("myrow1").style.visibility="hidden"
}
}
function test2(){
if(document["form1"]["checkbox3"].checked){
document.getElementById("myrow2").style.visibility="visible"
}
else{
document.getElementById("myrow2").style.visibility="hidden"
}
}
function test6(){
if(document["form1"]["agree"].checked){
document.getElementById("myrow4").style.visibility="visible"
}
else{
document.getElementById("myrow4").style.visibility="hidden"
}
}

function getCombo1(sel) { 
  var value = sel.options[sel.selectedIndex].value;   
} 
function getCombo11(sel) { 
  var value = sel.options[sel.selectedIndex].value;   
}

</script>

  <script language="Javascript">
var calendarWindow = null;
var calendarColors = new Array();
calendarColors['bgColor'] = '#BDC5D0';
calendarColors['borderColor'] = '#333366';
calendarColors['headerBgColor'] = '#143464';
calendarColors['headerColor'] = '#FFFFFF';
calendarColors['dateBgColor'] = '#8493A8';
calendarColors['dateColor'] = '#004080';
calendarColors['dateHoverBgColor'] = '#FFFFFF';
calendarColors['dateHoverColor'] = '#8493A8';
var calendarMonths = new Array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December');
var calendarWeekdays = new Array('S', 'M', 'T', 'W', 'T', 'F', 'S', 'S');
var calendarUseToday = true;
var calendarFormat = 'y/m/d';
var calendarStartMonday = true;
var calendarScreenX = 100; 
var calendarScreenY = 100; 


function getCalendar(in_dateField) 
{
    if (calendarWindow && !calendarWindow.closed) {
        alert('Calendar window already open.  Attempting focus...');
        try {
            calendarWindow.focus();
        }
        catch(e) {}
        
        return false;
    }

    var cal_width = 415;
    var cal_height = 310;

    if ((document.all) && (navigator.userAgent.indexOf("Konqueror") == -1)) {
        cal_width = 410;
    }

    calendarTarget = in_dateField;
    calendarWindow = window.open('Calendar/calendar.html', 'dateSelectorPopup','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=0,dependent=no,width='+cal_width+',height='+cal_height + (calendarScreenX != 'auto' ? ',screenX=' + calendarScreenX : '') + (calendarScreenY != 'auto' ? ',screenY=' + calendarScreenY : ''));

    return false;
}

function killCalendar() 
{
    if (calendarWindow && !calendarWindow.closed) {
        calendarWindow.close();
    }
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
	 <td width="100%" class="OraTableColumnHeader"><b>SKU or UPC Issue:</b>
		</td>
		
		</tr>
  </table>
   <%String srRequestNumber = request.getParameter("srID");%>
<BR>
<body>
<table>
<tr>
<td class="OraPromptText" ><a target="_blank" href="http://sp.na.odcorp.net/sites/StoreSupport/home/Shared%20Documents/SS_Request_System_Business_Rules/SKU_or_UPC_Issue_BR.pdf" title="">Click here to review the SKU or UPC Issue Business Rules</a></td>
</tr>
</table>
<form name="form1" method="post" action="xxod_Sku_Upc_Issue_Process.jsp?srID=<%=srRequestNumber%>" onsubmit="return checkform(this)" >

<table>
  <tr>
  <td class="OraPromptText"><input type=checkbox name=agree value="ON" onclick = "test6()">I understand these Business Rules and will structure my program to fit within these guidelines.<BR><U>Note: Form cannot be submitted unless the Business Rules have been acknowledged.</U> <BR></td>
</tr>
<tr>
</tr>
</table>
<B><font color="#CC0000">Required Fields are in Yellow </B>
<table id="myrow4" style="visibility:hidden" width="100%"  border="1"  BORDERCOLOR ="#CC0000"    align="center" cellpadding="0" cellspacing="0">
  <tr>
  <td class="OraPromptText"  bgcolor="#CC0000" ><font color="#FFFFFF"><b>Desired Communication Date:</td>
    <td bgcolor="#B0B0B0"><input type="text" name="calendar2" size="40" style="background-color:yellow;"/><a href="#" onclick="return getCalendar(document.form1.calendar2);"><img src="Calendar/calendar.png" border="0" /></a><td>
  </tr>
  <tr>
<td class="OraPromptText"  bgcolor="#CC0000" border="1"  BORDERCOLOR ="#FFFFFF" ><font color="#FFFFFF"><B>Select Issue Type:</td>
<td bgcolor="#B0B0B0">
<select id="combo1" name="combol" onchange="getCombo1(this)" style="background-color:yellow;"> 
<option value="">Select </option> 
<option value="Break Pack/SKU Conversion">Break Pack/SKU Conversion</option> 
<option value="Incorrect UPC">Incorrect UPC</option> 
</td>
</tr>

<tr>
<td class="OraPromptText" bgcolor="#CC0000" ><font color="#FFFFFF"><B> </td><td bgcolor="#CC0000" ><font color="#FFFFFF"><B><input type="submit" value="Submit">Please Verify All Data Prior to Submission</font></b>
</td></tr>
</table>
</form>

</body>
<BR>
<BR>


<table cellpadding="0" cellspacing="0" border="0" width="100%" summary=""><tr><td><div class="xv"><span id="N75">Copyright (c) 2006, Oracle. All rights reserved.</span></div></td></tr></table>