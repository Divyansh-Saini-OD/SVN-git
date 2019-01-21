<html dir="ltr" lang="en-US-ORACLE9I"><head><title>iSupport Store Portal Form</title><meta name="generator" content="Oracle UIX">
<link rel='stylesheet' href='images/jtfucss_sml.css'>
<link rel="stylesheet" charset="UTF-8" type="text/css" href="images/oracle-desktop-custom-2_2_24_5-en-ie-6-windows.css">
<script type="text/javascript"> 
function checkform(form) { 
	if (form1.calendar1.value == "") {
    alert( "Please Select the Desired Communication Date" );
    form.calendar1.focus();
    return false ;
  }
  	if (form1.Business_opp1.value == "") {
    alert( "Please Enter the Is there an RTV on this Item?" );
    form.Business_opp1.focus();
    return false ;
  }
  if (form1.Business_opp2.value == "") {
    alert( "Please Enter the Should customer returns be handled differently than our normal return policy?" );
    form.Business_opp2.focus();
    return false ;
  }
  
     return true ;
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
function toggleField(val) { 
var o = document.getElementById('Yes'); 
(val == 'Yes')? o.style.display = 'block' : o.style.display = 'none'; 
} 
function toggleField1(val) { 
var o = document.getElementById('Yes1'); 
(val == 'Yes')? o.style.display = 'block' : o.style.display = 'none'; 
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
var calendarScreenX = 100; // either 'auto' or numeric
var calendarScreenY = 100; // either 'auto' or numeric

// }}}
// {{{ getCalendar()

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

    // IE needs less space to make this thing
    if ((document.all) && (navigator.userAgent.indexOf("Konqueror") == -1)) {
        cal_width = 410;
    }

    calendarTarget = in_dateField;
    calendarWindow = window.open('Calendar/calendar.html', 'dateSelectorPopup','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=0,dependent=no,width='+cal_width+',height='+cal_height + (calendarScreenX != 'auto' ? ',screenX=' + calendarScreenX : '') + (calendarScreenY != 'auto' ? ',screenY=' + calendarScreenY : ''));

    return false;
}

// }}}
// {{{ killCalendar()

function killCalendar() 
{
    if (calendarWindow && !calendarWindow.closed) {
        calendarWindow.close();
    }
}

// }}}

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
	 <td width="100%" class="OraTableColumnHeader"><b>Urgent Product Issues:</b>
		</td>
		
		</tr>
  </table>

   <%String srRequestNumber = request.getParameter("srID");%>
<body>
<table>
<tr>
<td class="OraPromptText" ><a target="_blank" href="http://sp.na.odcorp.net/sites/StoreSupport/home/Shared%20Documents/SS_Request_System_Business_Rules/Urgent_Product_Issue_BR.pdf" title="">Click here to review the Urgent Product Issues Business Rules </a></td>
</tr>
</table>
<form name="form1" method="post" action="xxod_Urgent_Product_Issue_Process.jsp?srID=<%=srRequestNumber%>" onsubmit="return checkform(this)" >

<table>
  <tr>
  <td class="OraPromptText"><input type=checkbox name=agree value="ON" onclick = "test6()">I Understand these Business Rules and will Structure my program to fit within these guidelines. <br><U>Note:From cannot be submitted unless the business rules have been acknowladged .Additional info is required</U> <BR>
</td>
</tr>
</table>
<B><font color="#CC0000">Required Fields are in Yellow</B>

<table id="myrow4" style="visibility:hidden" width="100%" border="1"  BORDERCOLOR ="#CC0000"  align="center" cellpadding="0" cellspacing="0">
<tr>
  
  <td class="OraPromptText" bgcolor="#CC0000" border="1"  BORDERCOLOR ="#FFFFFF" ><font color="#FFFFFF"><B>Desired Communication Date:</td><td bgcolor="#B0B0B0"><input type="text" size="50" name="calendar1" style="background-color:yellow;"/><a href="#" onclick="return getCalendar(document.form1.calendar1);"><img src="Calendar/calendar.png" border="0" /></a></B></font>
  </td>
  </tr>
    <tr>


<td class="OraPromptText" bgcolor="#CC0000" width="50%" border="1"  BORDERCOLOR ="#FFFFFF"><font color="#FFFFFF"><B>Is there an RTV on this Item? </B></font></td><td bgcolor="#B0B0B0">
 <select id="Business_opp1" name="Business_opp1" onchange="toggleField(this.value);" style="background-color:yellow;" > 
<option value="">Select </option> 
<option value="Yes">Yes</option> 
<option value="No">No</option> 
</select><BR>
 </td>
 </tr>
 <tr tr id="Yes" style="display: none">
<td class="OraPromptText" bgcolor="#B0B0B0" size="50"><b>Enter RTV #:</b></td>
 <td bgcolor="#B0B0B0">
 <input type="text" name ="Yes" size="70" style="background-color:yellow;">
 </td>
 </tr>

<td class="OraPromptText" bgcolor="#CC0000" size="40" border="1"  BORDERCOLOR ="#FFFFFF" > <font color="#FFFFFF"><B>Should customer returns be handled differently than our normal return policy?</B></font></td><td bgcolor="#B0B0B0">
 <select id="Business_opp2" name="Business_opp2" onchange="toggleField1(this.value);" style="background-color:yellow;" > 
<option value="">Select </option> 
<option value="Yes">Yes</option> 
<option value="No">No</option> 
</select><BR>
 </td>
 </tr>
 <tr id="Yes1" style="display: none">
<td class="OraPromptText" bgcolor="#B0B0B0" size="40" border="1"  BORDERCOLOR ="#FFFFFF"> <b>Explain how returns will be handled:</b></td>
 <td bgcolor="#B0B0B0">
 <TEXTAREA NAME="Yes1" COLS=60 ROWS=4 style="background-color:yellow;"></TEXTAREA>
 </td>
 </tr>
 <tr>
 <td class="OraPromptText" bgcolor="#CC0000">&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp<input type="submit" value="Submit"></td>
<td class="OraPromptText" bgcolor="#CC0000" ><font color="#FFFFFF"><B>Please Verify All Data Prior to Submission</font></b>
</td>

</tr>
</table>
</form>

</body>
<BR>
<BR>


<table cellpadding="0" cellspacing="0" border="0" width="100%" summary=""><tr><td><div class="xv"><span id="N75">Copyright (c) 2006, Oracle. All rights reserved.</span></div></td></tr></table>


