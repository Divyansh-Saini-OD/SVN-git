<html dir="ltr" lang="en-US-ORACLE9I"><head><title>iSupport Store Portal Form </title><meta name="generator" content="Oracle UIX">
<link rel='stylesheet' href='images/jtfucss_sml.css'>
<link rel="stylesheet" charset="UTF-8" type="text/css" href="images/oracle-desktop-custom-2_2_24_5-en-ie-6-windows.css">
<script type="text/javascript"> 
function checkform(form) { 
	if (form1.calendar1.value == "") {
    alert( "Please Select the Incentive Start Date" );
    form.calendar1.focus();
    return false ;
  }
  else if (form1.calendar2.value == "") {
    alert( "Please Select the Incentive End Date" );
    form.calendar2.focus();
    return false ;
  }
  else if (form1.Business_opp1.value == "") {
    alert( "Please Enter the Why is the Incentive needed" );
    form.Business_opp1.focus();
    return false ;
  }
  else if (form1.Business_opp2.value == "") {
    alert( "Please Enter the What is the proposed Incentive" );
    form.Business_opp2.focus();
    return false ;
  }
   else if (form1.Business_opp3.value == "") {
    alert( "Please Enter the What are the benefit obtained from implementing the Incentive?" );
    form.Business_opp3.focus();
    return false ;
  }
   else if (form1.Business_opp4.value == "") {
    alert( "Please Enter theHow will the success of the Incentive be measured?" );
    form.Business_opp4.focus();
    return false ;
  }

 else if (form1.Business_opp5.value == "") {
    alert( "Please Select the Type of Incentive" );
    form.Business_opp5.focus();
    return false ;
  }
   else if (form1.Business_opp6.value == "") {
    alert( "Please Select the Type of Award" );
    form.Business_opp6.focus();
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

function toggleField(val) { 
var o = document.getElementById('other'); 
(val == 'Other')? o.style.display = 'block' : o.style.display = 'none'; 
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
	 <td width="100%" class="OraTableColumnHeader"><b>Incentive or Contest:</b>
		</td>
		
		</tr>
  </table>
   <%String srRequestNumber = request.getParameter("srID");%>
<BR>
<body>
<table>
<tr>
<td class="OraPromptText" ><a target="_blank" href="http://sp.na.odcorp.net/sites/StoreSupport/home/Shared%20Documents/SS_Request_System_Business_Rules/Incentive_Contest_BR.pdf" title="">Click here to review the Incentive or Contest Business Rules</a></td>
</tr>
</table>
<form name="form1" method="post" action="xxod_Request_Incentive_Contest_Process.jsp?srID=<%=srRequestNumber%>" onsubmit="return checkform(this)"  >

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
  <table width="100%">
  <tr>
  
  <td class="OraPromptText" bgcolor="#CC0000"><font color="#FFFFFF"><B>Incentive Start Date:</td><td bgcolor="#B0B0B0"><input type="text" size="40" name="calendar1" style="background-color:yellow;"/><a href="#" onclick="return getCalendar(document.form1.calendar1);"><img src="Calendar/calendar.png" border="0" /></a></B></font>
  </td>
  </tr>
  <tr>
  <td class="OraPromptText" bgcolor="#CC0000"><font color="#FFFFFF"><B>Incentive End Date:</td><td bgcolor="#B0B0B0"><input type="text"  size="40" name="calendar2" style="background-color:yellow;" /><a href="#" onclick="return getCalendar(document.form1.calendar2);"><img src="Calendar/calendar.png" border="0" /></a></B></font>
  </td>
  </tr>
  </table>
  </td>
  </tr>
 <tr>
 <td class="OraPromptText" bgcolor=""><font color="#FFFFFF"><B><BR></B></font>
  </td>
 </tr>
  <tr>
 <td class="OraPromptText" bgcolor="#CC0000"><font color="#FFFFFF"><B>Why is the Incentive needed?</td>
	</tr>
	<tr>
	<td><TEXTAREA NAME="Business_opp1" COLS=120 ROWS=3 style="background-color:yellow;" ></TEXTAREA></td>
 </tr>

<tr>
 <td class="OraPromptText" bgcolor="#CC0000"><font color="#FFFFFF"><B>What is the proposed Incentive?</td>
	</tr>
	<tr>
	<td><TEXTAREA NAME="Business_opp2" COLS=120 ROWS=3 style="background-color:yellow;" ></TEXTAREA></td>
 </tr>


<tr>
 <td class="OraPromptText" bgcolor="#CC0000"><font color="#FFFFFF"><B>What are the benefits obtained from implementing the Incentive?</td>
	</tr>
	<tr>
	<td><TEXTAREA NAME="Business_opp3" COLS=120 ROWS=3 style="background-color:yellow;" ></TEXTAREA></td>
 </tr>

<tr>
 <td class="OraPromptText" bgcolor="#CC0000"><font color="#FFFFFF"><B>How will the success of the Incentive be measured?</td>
	</tr>
	<tr>
	<td><TEXTAREA NAME="Business_opp4" COLS=120 ROWS=3 style="background-color:yellow;"></TEXTAREA></td>
 </tr>


	<tr>
	<td>

	<table width="100%" >
	<tr>
	 <td class="OraPromptText" bgcolor="#CC0000"><font color="#FFFFFF"><B>Type of Incentive: </B></font></td><td bgcolor="#B0B0B0">
 <select id="Business_opp5" name="Business_opp5" onchange="getCombo1(this)" style="background-color:yellow;"> 
<option value="">Select </option> 
<option value="Achieve Highest Total Sales .VS. Total Sales">Achieve Highest Total Sales vs. Total Sales</option> 
<option value="Achieve Highest Total Units .VS. Total Units">Achieve Highest Total Units vs. Total Units </option> 
<option value="Achieve Highest Increasein Sales to a set baseline or therehold">Achieve Highest Increase in Sales to a Set Baseline or Threshold</option> 
<option value="Achieve Highest Increasein Units to a set baseline or therehold">Achieve Highest Increase in Units to a Set Baseline or Threshold </option> 

</select></td>
</tr>
<tr>
 <td class="OraPromptText" bgcolor="#CC0000"><font color="#FFFFFF"><B>Type of Award: </B></font></td><td bgcolor="#B0B0B0">
 <select id="Business_opp6" name="Business_opp6" onchange="toggleField(this.value);" style="background-color:yellow;" > 
<option value="">Select </option> 
<option value="Flat rate per Associate (involves OT recalculation for hourly Associates">Flat Rate per Associate  (involves OT Recalculation for Hourly Associates)</option> 
<option value="Associate Activity Fund Credit">Associate Activity Fund Credit</option> 
<option value="OD Gift Card for each Associate(under$ 25)">OD Gift Card for each Associate (under $25)</option> 
<option value="Percentage of Associate's Salary">Percentage of Associate's Salary</option> 
<option value="Other">Other</option> 
</select>
 </td>
 </tr>
 <tr id="other" style="display: none">
 <td class="OraPromptText" bgcolor="#B0B0B0"><B>If Other:</B></td><td bgcolor="#B0B0B0"><TEXTAREA NAME="other" id="other"  COLS=65 ROWS=2 style="background-color:yellow;" ></TEXTAREA>
 </td>
 </tr>
</table>

</td>
</tr>

<tr>
 <td class="OraPromptText" bgcolor="#CC0000"><font color="#FFFFFF"><B>Additional Components: (check all that apply)</B></font> </td>
	</tr>
	<tr>
	<td>
	<table width="100%" border="1"  bgcolor="#FFFFFF" BORDERCOLOR ="#CC0000" >
 <tr>
	<td class="OraPromptText" ><input type="checkbox" name="Addcomp1" value="Register will be required">Register Prompt</td>
	</tr>
	<tr>
	<td class="OraPromptText"><input type="checkbox" name="Addcomp2" value="Signage will be required">Signage</td>
	</tr>
	<td></td>
	 </tr>


<tr>
<td class="OraPromptText" bgcolor="#CC0000" ><CENTER><font color="#FFFFFF"><B> <input type="submit" value="Submit">Please Verify All Data Prior to Submission</font></CENTER></b>
</td></tr>
</table>
</form>

</body>
<BR>
<BR>


<table cellpadding="0" cellspacing="0" border="0" width="100%" summary=""><tr><td><div class="xv"><span id="N75">Copyright (c) 2006, Oracle. All rights reserved.</span></div></td></tr></table>