<html dir="ltr" lang="en-US-ORACLE9I"><head><title>iSupport Store Portal Form </title><meta name="generator" content="Oracle UIX">
<link rel='stylesheet' href='images/jtfucss_sml.css'>
<link rel="stylesheet" charset="UTF-8" type="text/css" href="images/oracle-desktop-custom-2_2_24_5-en-ie-6-windows.css">
<script type="text/javascript"> 
function checkform(form) { 
	if (form1.Business_opp1.value == "") {
    alert( "Please Select the Is this training for an existing product or program?" );
    form.Business_opp1.focus();
    return false ;
  }
  	if (form1.Business_opp4.value == "") {
    alert( "Please select the What is the shelf-life of this project or service" );
    form.Business_opp4.focus();
    return false ;
  }
  if (form1.Business_opp6.value == "") {
    alert( "Please Enter the What is the expected outcome of this training?" );
    form.Business_opp6.focus();
    return false ;
  }
  if (form1.calendar1.value == "") {
    alert( "Please select the When does this training need to be available for Associates to complete?" );
    form.calendar1.focus();
    return false ;
  }
    return true ;
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

function test(){
if(document["form1"]["checkbox1"].checked){
document.getElementById("myrow").style.visibility="visible"
}
else{
document.getElementById("myrow").style.visibility="hidden"
}
}
function test1(){
if(document["form1"]["checkbox15"].checked){
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


function test3(){
if(document["form1"]["checkbox4"].checked){
document.getElementById("myrow3").style.visibility="visible"
}
else{
document.getElementById("myrow3").style.visibility="hidden"
}
}


function test4(){
if(document["form1"]["checkbox5"].checked){
document.getElementById("myrow4").style.visibility="visible"
}
else{
document.getElementById("myrow4").style.visibility="hidden"
}
}

function test6(){
if(document["form1"]["agree"].checked){
document.getElementById("myrow5").style.visibility="visible"
}
else{
document.getElementById("myrow5").style.visibility="hidden"
}
}
function toggleField(val) { 
var o = document.getElementById('Yes'); 
(val == 'Yes')? o.style.display = 'block' : o.style.display = 'none'; 
} 

function toggleField1(val) { 
var o = document.getElementById('Yes1'); 
(val == '0 - 6 Months')? o.style.display = 'block' : o.style.display = 'none'; 
var o = document.getElementById('Yes2'); 
(val == '6 Months - 1 Year')? o.style.display = 'block' : o.style.display = 'none'; 
var o = document.getElementById('Yes3'); 
(val == '1 Year or More')? o.style.display = 'block' : o.style.display = 'none'; 
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
	 <td width="100%" class="OraTableColumnHeader"><b>Training:</b>
		</td>
		
		</tr>
  </table>
   <%String srRequestNumber = request.getParameter("srID");%>
<BR>
<body>
<table>
<tr>
<td class="OraPromptText" ><a target="_blank" href="http://sp.na.odcorp.net/sites/StoreSupport/home/Shared%20Documents/SS_Request_System_Business_Rules/Training_BR.pdf" title="">Click here to review the Training Business Rules</a></td>
</tr>
</table>
<form name="form1" method="post" action="xxod_Request_Training_Only_Process.jsp?srID=<%=srRequestNumber%>" onsubmit="return checkform(this)"  >

<table>
  <tr>
  <td class="OraPromptText"><input type=checkbox name=agree value="ON" onclick = "test6()">I understand these Business Rules and will structure my program to fit within these guidelines.<BR><U>Note: Form cannot be submitted unless the Business Rules have been acknowledged.</U> <BR></td>
</tr>
<tr>
</tr>
</table>
<B><font color="#CC0000">Required Fields are in Yellow </B>

<table id="myrow5" style="visibility:hidden" width="100%"  border="1"  BORDERCOLOR ="#CC0000"    align="center" cellpadding="0" cellspacing="0">
 <tr>
 <td>
<table width="100%" >
  <td class="OraPromptText" bgcolor="#CC0000" width="50%" border="1"  BORDERCOLOR ="#FFFFFF"><font color="#FFFFFF"><B>Is this training for an existing product or program? </B></font></td><td bgcolor="#B0B0B0">
 <select id="Business_opp1" name="Business_opp1" onchange="toggleField(this.value);" style="background-color:yellow;" > 
<option value="">Select </option> 
<option value="Yes">Yes</option> 
<option value="No">No</option> 
</select><BR>
</td>
</tr>
</table>
 </td>
 </tr>

<tr id="Yes" style="display: none">
 <td class="OraPromptText" bgcolor="#B0B0B0" ><B>What should the learner be able to do at the conclusion of this training that he or she cannot do now?<BR>
	<TEXTAREA NAME="Business_opp2" COLS=100 ROWS=2 style="background-color:yellow;"></TEXTAREA><BR>
 Can the task or the workflow itself be made easier/simpler? Are there any obstacles preventing Associates from completing this task?</B><BR>
	<TEXTAREA NAME="Business_opp3" COLS=100 ROWS=2 style="background-color:yellow;"></TEXTAREA></font></td>
 </tr>

<tr>
 <td>
<table width="100%" >
  <td class="OraPromptText" bgcolor="#CC0000" width="50%" border="1"  BORDERCOLOR ="#FFFFFF"><font color="#FFFFFF"><B>What is the shelf-life of this product/service? </B></font></td><td bgcolor="#B0B0B0">
 <select id="Business_opp4" name="Business_opp4" onchange="toggleField1(this.value);" style="background-color:yellow;" > 
<option value="">Select </option> 
<option value="0 - 6 Months">0 - 6 Months</option> 
<option value="6 Months - 1 Year">6 Months - 1 Year</option> 
<option value="1 Year or More">1 Year or More</option> 
</select><BR>
</td>
</tr>
</table>
 </td>
 </tr>

<tr id="Yes1" style="display: none">
 <td class="OraPromptText" bgcolor="#B0B0B0"><B>Based on the shelf-life selected, the training format for this product/service will be: Huddle Helper featured in the Weekly Review or Advertising Notes</B></font><BR></td> </tr>
 <tr>
 <td>

 <table id="Yes2" style="display: none" width="100%"  border="1"  BORDERCOLOR ="#CC0000"    align="center" cellpadding="0" cellspacing="0" >
<tr>
 <td class="OraPromptText" bgcolor="#B0B0B0"><B>Based on the shelf-life selected, available training format options appear below, please select all that apply:</B></font><BR></td>
</tr>
<tr>
	<td class="OraPromptText" style="background-color:yellow;" >
	<input type="checkbox" name="checkbox6" value="Huddle Helpe" style="background-color:yellow;" >Huddle Helper<BR>
	<input type="checkbox" name="checkbox7" value="Webex Session" style="background-color:yellow;" >WebEx Session<BR>
	</td>	
 </tr>
 </table>
 </td>
 </tr>
 <tr>
 <td>
 
<table id="Yes3" style="display: none" width="100%"  border="1"  BORDERCOLOR ="#CC0000"    align="center" cellpadding="0" cellspacing="0" >
<tr>
 <td class="OraPromptText" bgcolor="#B0B0B0" border="1"  BORDERCOLOR ="#FFFFFF" ><B>Based on the shelf-life selected, available training format options appear below, please select all that apply:</B></font></td>
 </tr>
 <tr>
   <td class="OraPromptText" style="background-color:yellow;">
    <input type="checkbox" name="checkbox8" value="Huddle Helper" style="background-color:yellow;">Huddle Helper<BR>
	<input type="checkbox" name="checkbox9" value="WebEx Session" style="background-color:yellow;">WebEx Session<BR>
	<input type="checkbox" name="checkbox10" value="eLearning Module" style="background-color:yellow;">eLearning Module<BR>
	<input type="checkbox" name="checkbox11" value="Workbook" style="background-color:yellow;">Workbook<BR>
	<input type="checkbox" name="checkbox12" value="Start Smart Guide" style="background-color:yellow;">Start Smart Guide<BR>
	<input type="checkbox" name="checkbox13" value="Start Smart Cards" style="background-color:yellow;">Start Smart Cards<BR>
	<input type="checkbox" name="checkbox14" value="Item of the Month" style="background-color:yellow;">Item of the Month<BR>
	<input type="checkbox" name="checkbox15" value="Product Knowledge Video" style="background-color:yellow;" onclick = "test1()" >Product Knowledge Video<BR>
</td>
 </tr>
   <tr id="myrow1" style="visibility:hidden">
 <td class="OraPromptText" bgcolor="#B0B0B0"><B>The cost to produce a Product Knowledge Video is approximately $15,000, who will fund the cost? </B></font>
 <select id="Business_opp5" name="Business_opp5" onchange="getCombo1(this)" style="background-color:yellow;"> 
<option value="">Select </option> 
<option value="Office Depot Created">Office Depot Created</option> 
<option value="Vendor Created">Vendor Created </option> 
</select></td>
</tr>
 </table>
 
 </td>
 </tr>

<tr>
 <td class="OraPromptText" bgcolor="#CC0000"><font color="#FFFFFF"><b>What marketing or merchandising plans are in place to support this product or service launch? (check all that apply)</b></font><BR></td>
	</tr>
	<tr>
	<td class="OraPromptText" style="background-color:yellow;">
	<input type="checkbox" name="checkbox16" value="Product/Service will be featured in multiple locations (i.e. EBW)"   style="background-color:yellow;">Product/Service will be featured in multiple locations (i.e. EBW) <BR>
	<input type="checkbox" name="checkbox17" value="roduct/Service will be featured in an upcoming insert or Direct Mail campaign" style="background-color:yellow;">Product/Service will be featured in an upcoming insert or Direct Mail campaign<BR>
	<input type="checkbox" name="checkbox18" value="There will be additional signage used to promote this product/service" style="background-color:yellow;">There will be additional signage used to promote this product/service<BR><input type="checkbox" name="checkbox19" value="N/A" style="background-color:yellow;">N/A</td>	
 </tr>


 <tr>
 <td class="OraPromptText" bgcolor="#CC0000" ><font color="#FFFFFF"><b>What is the expected outcome of this training?<BR>
	<TEXTAREA NAME="Business_opp6" COLS=100 ROWS=3 style="background-color:yellow;"></TEXTAREA></b></font></td>
 </tr>

 <tr>
 <td>
 <table width="100%"  border="1"  BORDERCOLOR ="#FFFFFF"  cellpadding="0" cellspacing="0">
 <tr>
  <td class="OraPromptText" width="50%" bgcolor="#CC0000"><font color="#FFFFFF"><B>When does this training need to be available for Associates to complete?</B></font>
  </td>
  <td class="OraPromptText" width="50%"  bgcolor="#B0B0B0"> 
  <input type="text" size="40" name="calendar1" style="background-color:yellow;" /><a href="#" onclick="return getCalendar(document.form1.calendar1);"><img src="Calendar/calendar.png" border="0" /></a>
  </td>
  </tr>
  </table>
  </td>
  </tr>
     <tr>
 <td class="OraPromptText" bgcolor="#CC0000" ><font color="#FFFFFF"><b>Special Requests or Other Details:<BR>
	<TEXTAREA NAME="Business_opp7" COLS=100 ROWS=3></TEXTAREA></b></font></td>
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