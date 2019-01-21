<html dir="ltr" lang="en-US-ORACLE9I"><head><title>iSupport Store Portal Form</title><meta name="generator" content="Oracle UIX">
<link rel='stylesheet' href='images/jtfucss_sml.css'>
<link rel="stylesheet" charset="UTF-8" type="text/css" href="images/oracle-desktop-custom-2_2_24_5-en-ie-6-windows.css">
<script type="text/javascript"> 
function checkform(form) { 
	if (form1.calendar1.value == "") {
    alert( "Please Select the Desired Program Start Date" );
    form.calendar1.focus();
    return false ;
  }
  else if (form1.calendar2.value == "") {
    alert( "Please Select the Desired Program End Date" );
    form.calendar2.focus();
    return false ;
  }
  else if (form1.Business_opp1.value == "") {
    alert( "Please Enter the Business Opportunity?" );
    form.Business_opp1.focus();
    return false ;
  }
  else if (form1.Business_opp2.value == "") {
    alert( "Please Enter the Concept/Pilot Requirements" );
    form.Business_opp2.focus();
    return false ;
  }
   else if (form1.Business_opp22.value == "") {
    alert( "Please Enter the High Level Scope" );
    form.Business_opp22.focus();
    return false ;
  }
   else if (form1.Business_opp3.value == "") {
    alert( "Please Enter the What are the benifits obtained from implementing this Concept/Pilot?" );
    form.Business_opp3.focus();
    return false ;
  }

 else if (form1.Business_opp4.value == "") {
    alert( "Please Enter the How will the success of the Concept/Pilot be measured?" );
    form.Business_opp4.focus();
    return false ;
  }
   else if (form1.Business_opp5.value == "") {
    alert( "Please Enter the Constraints?" );
    form.Business_opp5.focus();
    return false ;
  }
   return true ;
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
	 <td width="100%" class="OraTableColumnHeader"><b>Initiate New Concept or Pilot:</b>
		</td>
		
		</tr>
  </table>
   <%String srRequestNumber = request.getParameter("srID");%>
<BR>
<body>
<table>
<tr>
<td class="OraPromptText" ><a target="_blank" href="http://sp.na.odcorp.net/sites/StoreSupport/home/Shared%20Documents/SS_Request_System_Business_Rules/Initiate_New_Concept_Pilot_BR.pdf" title="">Click here to review the Initiate New Concept or Pilot Business Rules</a></td>
</tr>
</table>
<form name="form1" method="post" action="xxod_Initiate_New_Concept_Pilot_Process.jsp?srID=<%=srRequestNumber%>" onsubmit="return checkform(this)" >

<table>
  <tr>
  <td class="OraPromptText"><input type=checkbox name=agree value="ON" onclick = "test6()">I understand these Business Rules and will structure my program to fit within these guidelines.<br><U>Note: Form cannot be submitted unless the Business Rules have been acknowledged.</U><br></td>
</tr>
<tr>
</tr>
</table>
<B><font color="#CC0000">Required Fields are in Yellow</B>
  <table id="myrow4" style="visibility:hidden" width="100%" border="0"  BORDERCOLOR =""  align="center" cellpadding="0" cellspacing="0">
   <tr>
   <td>
   <table width="100%">
   <tr>
    <td class="OraPromptText" bgcolor="#CC0000"><font color="#FFFFFF"><B>Desired Program Start Date:</td><td bgcolor="#B0B0B0"><input type="text" size="40" name="calendar1" style="background-color:yellow;"/><a href="#" onclick="return getCalendar(document.form1.calendar1);"><img src="Calendar/calendar.png" border="0" /></a></B></font>
  </td>
  </tr>
  <tr>
  <td class="OraPromptText" bgcolor="#CC0000"><font color="#FFFFFF"><B>Desired Program End Date:</td><td bgcolor="#B0B0B0"><input type="text"  size="40" name="calendar2" style="background-color:yellow;" /><a href="#" onclick="return getCalendar(document.form1.calendar2);"><img src="Calendar/calendar.png" border="0" /></a></B></font>
  </td>
  </tr>
</table>
</td>
	<tr>
	<td class="OraPromptText" bgcolor="#CC0000"><B><font color="#FFFFFF">Business Opportunity:</B><BR><I>Why is this Concept/Pilot needed?</I><BR></td>
	</tr>
	<tr>
	<td><TEXTAREA NAME="Business_opp1" COLS=120 ROWS=3 style="background-color:yellow;" ></TEXTAREA></td>
 </tr>
 <tr>
 <td class="OraPromptText"  bgcolor="#CC0000"><B><font color="#FFFFFF">Concept/Pilot Requirements:</B><BR><I>What is the proposal?</I></td>
	</tr>
	<tr>
	<td><TEXTAREA NAME="Business_opp2" COLS=120 ROWS=3 style="background-color:yellow;" ></TEXTAREA></td>
 </tr>
 <tr>
 <td class="OraPromptText"  bgcolor="#CC0000"><B><font color="#FFFFFF">High Level Scope:<BR></B><I>How will the Concept/Pilot be implemented?</I></td>
	</tr>
	<tr>
	<td><TEXTAREA NAME="Business_opp22" COLS=120 ROWS=3 style="background-color:yellow;" ></TEXTAREA></td>
 </tr>

  <tr>
 <td class="OraPromptText" bgcolor="#CC0000"><B><font color="#FFFFFF">What are the benefits obtained from implementing this Concept/Pilot?</B></td>
	</tr>
	<tr>
	<td><TEXTAREA NAME="Business_opp3" COLS=120 ROWS=3 style="background-color:yellow;" ></TEXTAREA></td>
 </tr>
  <tr>
 <td class="OraPromptText" bgcolor="#CC0000" ><B><font color="#FFFFFF">How will the success of the Concept/Pilot be measured?</B> </td>
	</tr>
	<tr>
	<td><TEXTAREA NAME="Business_opp4" COLS=120 ROWS=3 style="background-color:yellow;" ></TEXTAREA></td>
 </tr>
 <tr>
 <td class="OraPromptText" bgcolor="#CC0000" ><B><font color="#FFFFFF">Constraints:</B><BR><I>What could prevent this Concept/Pilot from being implemented?</I></td>
	</tr>
	<tr>
	<td><TEXTAREA NAME="Business_opp5" COLS=120 ROWS=3 style="background-color:yellow;" ></TEXTAREA></td>
 </tr>
 <tr bgcolor="#CC0000">
 <td class="OraPromptText"><font color="#FFFFFF"><B>Additional Components (check all that apply):</B></font> </td>
	</tr>
	<tr>
	<td>
	<table width="100%" border="1"  bgcolor="#FFFFFF" BORDERCOLOR ="#CC0000" >
 <tr>
	<td class="OraPromptText" width="50%"><input type="checkbox" name="Addcomp1" value="Bounce Back Coupon will be required">Bounce Back Coupon</td>
	<td class="OraPromptText" width="50%"><input type="checkbox" name="Addcomp2" value="Signage will be required">Signage</td>
	</tr>
	<tr>
	<td class="OraPromptText"><input type="checkbox" name="Addcomp3" value="Register will be required">Register Prompt</td>
	<td class="OraPromptText"><input type="checkbox" name="Addcomp4" value="Training will be required">Training</td>
	</tr>
	<tr>
 	<td class="OraPromptText"><input type="checkbox" name="Addcomp5" value="WebTop Button will be required">WebTop Button  </td>
	<td></td>
	 </tr>
	 </table>
	 <td>
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