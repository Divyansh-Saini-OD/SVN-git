<html dir="ltr" lang="en-US-ORACLE9I"><head><title>iSupport Store Portal Form </title><meta name="generator" content="Oracle UIX">
<link rel='stylesheet' href='images/jtfucss_sml.css'>
<link rel="stylesheet" charset="UTF-8" type="text/css" href="images/oracle-desktop-custom-2_2_24_5-en-ie-6-windows.css">
<script type="text/javascript"> 
function checkform(form) { 
	if (form1.checkbox1.value == "") {
    alert( "Please Select The Do you want to Add or Delete a WebTop Button" );
    form.checkbox1.focus();
    return false ;
  }
  	   
    return true ;
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

function toggleField(val) { 
var o = document.getElementById('Yes1'); 
(val == 'Add New WebTop Button')? o.style.display = 'block' : o.style.display = 'none'; 
var o = document.getElementById('Yes2'); 
(val == 'Delete Existing WebTop Button')? o.style.display = 'block' : o.style.display = 'none'; 
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
	 <td width="100%" class="OraTableColumnHeader"><b>WebTop Button:</b>
		</td>
		
		</tr>
  </table>
   <%String srRequestNumber = request.getParameter("srID");%>
<BR>
<body>
<table>
<tr>
<td class="OraPromptText" ><a target="_blank" href="http://sp.na.odcorp.net/sites/StoreSupport/home/Shared%20Documents/SS_Request_System_Business_Rules/WebTop_Button_BR.pdf " title="">Click here to review the WebTop Button Business Rules</a></td>
</tr>
</table>
<form name="form1" method="post" action="xxod_Web_Top_Button_Process.jsp?srID=<%=srRequestNumber%>" onsubmit="return checkform(this)" >

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
  <td class="OraPromptText" border="1" ><font color="#FFFFFF"><B></b></font></td>
 </tr>
<tr>
<td>
<table>
<tr>
<td class="OraPromptText" bgcolor="#CC0000"><font color="#FFFFFF"><B>Do you want to Add or Delete a WebTop Button?</B></font></td>
<td class="OraPromptText" >
 <select id="checkbox1" name="checkbox1" onchange="toggleField(this.value);" style="background-color:yellow;" > 
<option value="">Select </option> 
<option value="Add New WebTop Button">Add New WebTop Button</option> 
<option value="Delete Existing WebTop Button">Delete Existing WebTop Button</option> 
</select>
</td></tr> 
</table>
</td>
</tr>
<tr>
<td>
<table id="Yes1" style="display: none" width="100%"  border="1"  BORDERCOLOR ="#FFFFFF"    align="center" cellpadding="0" cellspacing="0">
  <tr>
 <td class="OraPromptText"  bgcolor="#CC0000" ><font color="#FFFFFF">
 <B>Start Date:</B></B><BR><I>Specify 'Immediate' if no specific start date is required</I> </td>
  </tr>
 <tr>
 <td bgcolor="#B0B0B0" > <input type = "text" name ="Business_opp1" size="40" style="background-color:yellow;"></td>
 </tr>
 <tr>
 <td class="OraPromptText"  bgcolor="#CC0000"  ><font color="#FFFFFF"><b>
 End Date:</B><BR><I>Specify 'Never' if the link should not expire</I></td>
  </tr>
 <tr>
 <td bgcolor="#B0B0B0" ><input type = "text" name ="Business2" size="40" style="background-color:yellow;"></td>
 </tr>
 <tr>
 <td class="OraPromptText"  bgcolor="#CC0000" ><font color="#FFFFFF"><b>
 Why is this button needed?</B></td> </tr>
 <tr>
 <td><TEXTAREA NAME="Business_just" COLS=100 ROWS=3 style="background-color:yellow;"></TEXTAREA></td>
 </tr>
 
   <tr>
<td class="OraPromptText"  bgcolor="#CC0000" ><font color="#FFFFFF"><b>What is the name of the new WebTop Button?</td>
 </tr>
 <tr>
<td><TEXTAREA NAME="Business_name" COLS=100 ROWS=1 style="background-color:yellow;"></TEXTAREA></td>
 </tr>
<tr>
<td class="OraPromptText"  bgcolor="#CC0000" ><font color="#FFFFFF"><b>What is the  complete URL?</td>
 </tr>
 <tr>
<td ><TEXTAREA NAME="Business_URL" COLS=100 ROWS=3 style="background-color:yellow;"></TEXTAREA></td>
 </tr>
  <tr>
  <td>
  <table width="100%"  border="1"  cellpadding="0" cellspacing="0">
  <tr>
 <td class="OraPromptText" width="50%" bgcolor="#CC0000" ><font color="#FFFFFF"><B>Has the site been tested in a store lab?</B></td>
  <td bgcolor="#B0B0B0" width="50%"><select id="Business_opp9" name="Business_opp9" onchange="getCombo11(this)" style="background-color:yellow;"> 
<option value="">Select </option> 
<option value="Yes">Yes</option> 
<option value="No">No</option> 
</select></td>
 </tr>
 </table>
 </td>
 </tr>
<tr>
<td class="OraPromptText"  bgcolor="#CC0000" ><font color="#FFFFFF"><b> What is the mouse-over text?</B><BR><I>Optional, maximum 250 characters</I></td>
 </tr>
 <tr>
<td> <TEXTAREA NAME="Business_Mouse" COLS=100 ROWS=3></TEXTAREA></td>
 </tr>
 <tr>
 <td>
 <table width="100%"  border="1"  BORDERCOLOR ="#FFFFFF"    align="center" cellpadding="0" cellspacing="0" >
 <tr>
 <td class="OraPromptText"  bgcolor="#CC0000" ><font color="#FFFFFF"><b>
 Where will the WebTop Button reside?</b> </td>
  <td bgcolor="#B0B0B0"><select id="Business_opp4" name="Business_opp4" onchange="getCombo1(this)" style="background-color:yellow;"> 
<option value="">Select </option> 
<option value="Associate Desktop - Customer Services">Associate Desktop - Customer Services</option> 
<option value="Associate Desktop - Associate/Management Functions">Associate Desktop - Associate/Management Functions</option> 
<option value="Associate Desktop - HR/Training Functions">Associate Desktop - HR/Training Functions</option> 

<option value="Associate Desktop - Receiving/Inventory Functions">Associate Desktop - Receiving/Inventory Functions</option> 
<option value="DPS Desktop - Customer/Production Services">CPD Desktop - Customer/Production Services</option>
<option value="DPS Desktop - Associate/Management Functions">CPD Desktop - Associate/Management Functions</option> 
<option value="DPS Desktop - Document/Retrievel Services">CPD Desktop - Document/Retrieval Services</option> 
</select>
</td>
 </tr>
</table>
</td>
</tr>
 <tr>
<td class="OraPromptText"  bgcolor="#CC0000" ><font color="#FFFFFF"><b>
In terms of positioning, what current WebTop Button will this button follow?</td>
 </tr>
 <tr>
<td> <TEXTAREA NAME="Business_posi" COLS=100 ROWS=2></TEXTAREA></td>
 </tr>
 <tr>
<td class="OraPromptText"  bgcolor="#CC0000" ><font color="#FFFFFF"><b>
Special Requests or Other Details:</td>
 </tr>
 <tr>
<td> <TEXTAREA NAME="Business_posi1" COLS=100 ROWS=4></TEXTAREA></td>
 </tr>
 
 

 </table>
 </td>
 </tr>
 <tr>
 <td>
 <table id="Yes2" style="display: none"  width="100%"  border="1"  BORDERCOLOR ="#CC0000"    align="center" cellpadding="0" cellspacing="0" >
 <tr>
 <td class="OraPromptText"  bgcolor="#CC0000" ><font color="#FFFFFF"><b>What is the name of the WebTop Button to be deleted?</td>
 </tr>
 <tr>
 <td> <TEXTAREA NAME="Business_opp10" COLS=100 ROWS=1 style="background-color:yellow;"></TEXTAREA></td>
 </tr>
 <tr>
 <td>
 <table width="100%"  border="1"  BORDERCOLOR ="#FFFFFF"    align="center" cellpadding="0" cellspacing="0">
 <tr>
  <td class="OraPromptText"  bgcolor="#CC0000" ><font color="#FFFFFF"><b>Deletion Date:</td>
  <td bgcolor="#B0B0B0" ><input type="text" size="40" name="calendar2" style="background-color:yellow;" /><a href="#" onclick="return getCalendar(document.form1.calendar2);"><img src="Calendar/calendar.png" border="0" /></a></B></font>
  </td>
  </tr>
  </table>
  </td>
  </tr>
  
</table>
</td>
<tr><td class="OraPromptText" bgcolor="#CC0000" ><font color="#FFFFFF"><B> <CENTER><input type="submit" value="Submit">Please Verify All Data Prior to Submission</CENTER></font></b>
</td>
</td></tr>

</tr>
</table>
</form>

</body>
<BR>
<table cellpadding="0" cellspacing="0" border="0" width="100%" summary=""><tr><td><div class="xv"><span id="N75">Copyright (c) 2006, Oracle. All rights reserved.</span></div></td></tr></table>