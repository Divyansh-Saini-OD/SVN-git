<html dir="ltr" lang="en-US-ORACLE9I"><head><title>iSupport Store Portal Form </title><meta name="generator" content="Oracle UIX">
<link rel='stylesheet' href='images/jtfucss_sml.css'>
<link rel="stylesheet" charset="UTF-8" type="text/css" href="images/oracle-desktop-custom-2_2_24_5-en-ie-6-windows.css">
<script type="text/javascript"> 
function checkform(form) { 
	if (form1.calendar1.value == "") {
    alert( "Please Select the Program Start Date" );
    form.calendar1.focus();
    return false ;
  }
  	  if (form1.Business_opp25.value == "") {
    alert( "Please select the Program type" );
    form.Business_opp25.focus();
    return false ;
	}
  if (form1.Business_opp11.value == "") {
    alert( "Please select the How will the signage be funded?" );
    form.Business_opp11.focus();
    return false ;
  }
   if (form1.Business_opp13.value == "") {
    alert( "Please enter the Vendor Company Name?" );
    form.Business_opp13.focus();
    return false ;
  }
   if (form1.Business_opp14.value == "") {
    alert( "Please Enter the Vendor Contact Name?" );
    form.Business_opp14.focus();
    return false ;
  }
   if (form1.Business_opp15.value == "") {
    alert( "Please Enter the Vendor Phone Number?" );
    form.Business_opp15.focus();
    return false ;
  }

    if (form1.Business_opp17.value == "") {
    alert( "Please select the Creative Development" );
    form.Business_opp17.focus();
    return false ;
  }
   if (form1.Business_opp18.value == "") {
    alert( "Please select the Production/Shipping" );
    form.Business_opp18.focus();
    return false ;
  }
  if (form1.Business_opp19.value == "") {
    alert( "Please enter the Reason for Request" );
    form.Business_opp19.focus();
    return false ;
  }
  if (form1.Business_opp20.value == "") {
    alert( "Please enter the Message to be Communicated" );
    form.Business_opp20.focus();
    return false ;
  }

    return true ;
}

function toggleField(val) { 
var o = document.getElementById('other'); 
(val == 'Other')? o.style.display = 'block' : o.style.display = 'none'; 
} 

 function toggleField1(val) { 
var o = document.getElementById('other1'); 
(val == 'Vendor Funded')? o.style.display = 'block' : o.style.display = 'none'; 
} 

function getCombo1(sel) { 
  var value = sel.options[sel.selectedIndex].value;   

} 
function getCombo11(sel) { 
  var value = sel.options[sel.selectedIndex].value;   
}
function getCombo111(sel) { 
  var value = sel.options[sel.selectedIndex].value;   
}
function getCombo1111(sel) { 
  var value = sel.options[sel.selectedIndex].value;   
}

function getCombo11111(sel) { 
  var value = sel.options[sel.selectedIndex].value;   
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
if(document["form1"]["Business_opp8"].checked){
document.getElementById("myrow2").style.visibility="visible"
}
else{
document.getElementById("myrow2").style.visibility="hidden"
}
}

function test3(){
if(document["form1"]["Business_opp12"].checked){
document.getElementById("myrow3").style.visibility="visible"
}
else{
document.getElementById("myrow3").style.visibility="hidden"
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
	 <td width="100%" class="OraTableColumnHeader"><b>Signage:</b>
		</td>
		
		</tr>
  </table>
   <%String srRequestNumber = request.getParameter("srID");%>
<BR>
<body>
<table>
<tr>
<td class="OraPromptText" ><a target="_blank" href="http://sp.na.odcorp.net/sites/StoreSupport/home/Shared%20Documents/SS_Request_System_Business_Rules/Signage_BR.pdf" title="">Click here to review the Signage Business Rules </a></td>
</tr>
</table>
<form name="form1" method="post" action="xxod_Request_Signage_Only_Process.jsp?srID=<%=srRequestNumber%>" onsubmit="return checkform(this)">

<table>
  <tr>
  <td class="OraPromptText"><input type=checkbox name=agree value="ON" onclick = "test6()">I understand these Business Rules and will structure my program to fit within these guidelines.<BR><U>Note: Form cannot be submitted unless the Business Rules have been acknowledged.</U> <BR></td>
</tr>
<tr>
</tr>
</table>
<B><font color="#CC0000">Required Fields are in Yellow</B>
<table id="myrow4" style="visibility:hidden" width="100%"  border="1"  BORDERCOLOR ="#CC0000"    align="center" cellpadding="0" cellspacing="0">
  <tr>
  <td>
  <table  width="100%"  border="1"  BORDERCOLOR ="#FFFFFF"    align="center" cellpadding="0" cellspacing="0">
  <tr>
    <td class="OraPromptText" bgcolor="#CC0000" border="1"  BORDERCOLOR ="#FFFFFF" ><font color="#FFFFFF"><B>Program Start Date:</td>
  
  <td bgcolor="#B0B0B0" >
  <input type="text" size="40" name="calendar1" style="background-color:yellow;"/><a href="#" onclick="return getCalendar(document.form1.calendar1);"><img src="Calendar/calendar.png" border="0" /></a></B></font>
  </td>
  </tr>
  <tr>
  <td class="OraPromptText" bgcolor="#CC0000" border="1"  BORDERCOLOR ="#FFFFFF"><font color="#FFFFFF"><B>Program End Date:</td>
    <td bgcolor="#B0B0B0"><input type="text"  size="40" name="calendar2" /><a href="#" onclick="return getCalendar(document.form1.calendar2);"><img src="Calendar/calendar.png" border="0" /></a></B></font>
  </td>
  </tr>
 
<tr>
 <td class="OraPromptText" bgcolor="#CC0000" border="1"  BORDERCOLOR ="#FFFFFF" ><font color="#FFFFFF"><B>Program Type:</B></font></td>
  <td class="OraPromptText" bgcolor="#B0B0B0">
 <select id="Business_opp25" name="Business_opp25" onchange="toggleField(this.value);" style="background-color:yellow;"> 
<option value="">Select</option> 
<option value="Corrugate">Corrugate</option> 
<option value="EBW">EBW</option> 
<option value="Marketing Program">Marketing Program</option> 
<option value="New Fixture">New Fixture</option> 
<option value="POG Change/Line Review">POG Change/Line Review</option> 
<option value="Promotional(2-3 Months)">Promotional (2-3 Months)</option> 
<option value="Test">Test</option> 
<option value="Other">Other</option> 
</select><BR>
 </td>
</tr>
</table>
</td>
</tr>
<tr id="other" style="display: none">
 <td class="OraPromptText" bgcolor="#B0B0B0" ><B>If Other:</B><TEXTAREA NAME="other" id="other" COLS=75 ROWS=2 style="background-color:yellow;"></TEXTAREA></td>
 </tr>


<tr>
 <td class="OraPromptText" bgcolor="#CC0000" border="1"  BORDERCOLOR ="#FFFFFF" ><font color="#FFFFFF"><B>Signage Display Location: (check all that apply) </B></font></td>
 </tr>
 <tr>
   <td class="OraPromptText" style="background-color:yellow;">
    <input type="checkbox" name="Business_opp2" value="EndCap" style="background-color:yellow;">Endcap*<BR>
	<input type="checkbox" name="Business_opp3" value="Bulk" style="background-color:yellow;">Bulk*<BR>
	<input type="checkbox" name="Business_opp4" value="Wing" style="background-color:yellow;">Wing*<BR>
	<input type="checkbox" name="Business_opp5" value="Corrugate" style="background-color:yellow;">Corrugate*<BR>
	<input type="checkbox" name="Business_opp6" value="Strikezone" style="background-color:yellow;">Strikezone<BR>
	<input type="checkbox" name="Business_opp7" value="In-Line" style="background-color:yellow;">In-Line<BR>
	<input type="checkbox" name="Business_opp8" value="Other" onclick= "test2()" style="background-color:yellow;">Other
		</td>
 </tr>
<tr id="myrow2" style="visibility:hidden">
<td  class="OraPromptText" bgcolor="#B0B0B0" ><B>If Other:</B><TEXTAREA NAME="Business_opp9" COLS=75 ROWS=2 style="background-color:yellow;"></TEXTAREA>
</td>
</tr>
<tr>

<td class="OraPromptText" bgcolor="#CC0000"><font color="#FFFFFF"><B> Enter POG #:</B><BR>*<I>Required if you select Endcap, Bulk, Wing, or Corrugate display location</I> </font></td>
</tr>
<tr>
<td>
<TEXTAREA NAME="Business_opp10" COLS=100 ROWS=2></TEXTAREA>
 </td>
 </tr>
 <tr> 
 <td>
 <table width="100%"  border="1"  BORDERCOLOR ="#FFFFFF"   align="center" cellpadding="0" cellspacing="0">
 <tr>
 <td class="OraPromptText" bgcolor="#CC0000"><font color="#FFFFFF"><B>How will the signage be funded?  </B></font></td>
  <td bgcolor="#B0B0B0"><select id="Business_opp11" name="Business_opp11" onchange="getCombo11111(this)" style="background-color:yellow;"> 
<option value="">Select </option> 
<option value="Office Depot Created">Office Depot Funded</option> 
<option value="Vendor Created">Vendor Funded </option> 
</select></td>
</tr>
</table>
</td>
</tr>

 <tr>
 <td class="OraPromptText" bgcolor="#CC0000" border="1"><font color="#FFFFFF"><B>Vendor Contact Information:<BR></B>
 <I>If Office Depot Funded, enter 'NA' for the following questions</I></font></td>
 </tr>
 <tr>
 <td>
 <table width="100%"  border="1"  BORDERCOLOR ="#FFFFFF"   align="center" cellpadding="0" cellspacing="0">
 <tr>
  <td class="OraPromptText" bgcolor="#CC0000"><font color="#FFFFFF"><B>Vendor Company Name:</td>
  <td bgcolor="#B0B0B0" ><input type = "text" name ="Business_opp13" size="100" style="background-color:yellow;"></td>
  </tr>
  <tr>
   <td class="OraPromptText" bgcolor="#CC0000"><font color="#FFFFFF"><B>Vendor Contact Name:</td>
   <td bgcolor="#B0B0B0"><input type = "text" name ="Business_opp14" size="100" style="background-color:yellow;"></td>
   </tr>
   <tr>
   <td class="OraPromptText" bgcolor="#CC0000"><font color="#FFFFFF"><B>Vendor Phone Number:</td>
   <td bgcolor="#B0B0B0"><input type = "text" name ="Business_opp15" size="100" style="background-color:yellow;"></td>
   </tr>
   </table>
   </td>
     <tr>
   <td class="OraPromptText" bgcolor="#CC0000"><font color="#FFFFFF"><B>As needed, enter the Company Name, Contact Name, and Contact Phone for each additional Vendor:</td>
   </tr>
   <tr>
   <td bgcolor="#B0B0B0"><TEXTAREA NAME="Business_opp16" COLS=85 ROWS=4></TEXTAREA></td>
</tr>

   <tr>
   <td>
   <table width="100%"  border="1"  BORDERCOLOR ="#FFFFFF"    align="center" cellpadding="0" cellspacing="0" >
   <tr>
 <td class="OraPromptText" bgcolor="#CC0000"><font color="#FFFFFF"><B>Creative Development: </B></font></td>
 <td bgcolor="#B0B0B0"> <select id="Business_opp1" name="Business_opp17" onchange="getCombo1(this)" style="background-color:yellow;"> 
<option value="">Select </option> 
<option value="Office Depot Created">Office Depot Created </option> 
<option value="Vendor Created (attach vendor creative)">Vendor Created (attach vendor creative) </option> 
</select></td>
</tr>
<tr>
 <td class="OraPromptText" bgcolor="#CC0000"><font color="#FFFFFF"><B>Production/Shipping: </B></font></td>
 <td bgcolor="#B0B0B0"><select id="Business_opp2" name="Business_opp18" onchange="getCombo11(this)" style="background-color:yellow;"> 
<option value="">Select </option> 
<option value="Office Depot Produced/Shipped to Stores">Office Depot Produced/Shipped to Stores</option> 
<option value="Vendor Produced/Shipped to Stores">Vendor Produced/Shipped to Stores</option> 
</select></td>
</tr>
</table>
</td>
</tr>

<tr>
 <td class="OraPromptText" bgcolor="#CC0000"><font color="#FFFFFF"><B>Reason for Request:</td>
	</tr>
	<tr>
	<td><TEXTAREA NAME="Business_opp19" COLS=100 ROWS=3 style="background-color:yellow;"></TEXTAREA></td>
 </tr>


<tr>
 <td class="OraPromptText" bgcolor="#CC0000"><font color="#FFFFFF"><B>Message to be Communicated:</td>
	</tr>
	<tr>
	<td><TEXTAREA NAME="Business_opp20" COLS=100 ROWS=3 style="background-color:yellow;"></TEXTAREA></td>
 </tr>

<tr>
 <td class="OraPromptText" bgcolor="#CC0000"><font color="#FFFFFF"><B>Legal Disclaimers: </td>
	</tr>
	<tr>
	<td><TEXTAREA NAME="Business_opp21" COLS=100 ROWS=3></TEXTAREA></td>
 </tr>

<tr>
 <td class="OraPromptText" bgcolor="#CC0000"><font color="#FFFFFF"><B>Other Requirements (i.e. Logos):</td>
	</tr>
	<tr>
	<td><TEXTAREA NAME="Business_opp22" COLS=100 ROWS=3></TEXTAREA></td>
 </tr>
<tr>
 <td class="OraPromptText" bgcolor="#CC0000"><font color="#FFFFFF"><B>Product/Sign Attributes (i.e. Product Name, SKU, Features, Benefits):   </td>
	</tr>
	<tr>
	<td><TEXTAREA NAME="Business_opp23" COLS=100 ROWS=3></TEXTAREA></td>
 </tr>
 <tr>
 <td class="OraPromptText" ><a target="_blank" href="http://uschwssweb01/sites/StoreSupport/home/Shared%20Documents/SS_Request_System_Business_Rules/FTP_Vendor_Instructions.pdf"><B>Click here for Final Artwork Submission Guidelines</B></a>
 </td>
 </tr>


<tr>
<td class="OraPromptText" bgcolor="#CC0000" ><font color="#FFFFFF"><B> <CENTER><input type="submit" value="Submit">Please Verify All Data Prior to Submission</CENTER></font></b>
</td></tr>
</table>
</form>

</body>
<BR>
<BR>


<table cellpadding="0" cellspacing="0" border="0" width="100%" summary=""><tr><td><div class="xv"><span id="N75">Copyright (c) 2006, Oracle. All rights reserved.</span></div></td></tr></table>