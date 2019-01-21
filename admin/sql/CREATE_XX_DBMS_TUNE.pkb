create or replace
package body XX_DBMS_TUNE_PKG
AS
procedure PROCESS_REQUEST(p_sql_text CLOB
                          ,p_sql_id VARCHAR2
                          ,p_time_limit VARCHAR2
                          ,p_action VARCHAR2)
AS
task_name VARCHAR2(5000);
lc_sql_text CLOB := p_sql_text ;
lc_error VARCHAR2(2000);
lc_report_text CLOB :=NULL;
l_offset NUMBER:=1;
BEGIN

lc_error := 'Printing Header';
          htp.p('<html>'
          ||'<head>'
          ||'<TITLE> EASy Tune - SQL Statements - Report </TITLE>'
          ||'</head>'
          ||'<body>'
          ||'<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0" WIDTH="100%">'
          ||'<tr><td width="75%"  height="" align="left"><img src="/OA_MEDIA/ODLOGO.gif"></td>'
          ||'<td align="right"><form name="para" action="XX_DBMS_TUNE_PKG.XX_DBMS_TUNE" method="post"><br><a onclick="submit()" onmouseover="this.style.cursor=''pointer''"><font size=2 face="arial" Color="blue"><u>Task Submission Page</u></font></a></form></td>'
          ||'<td align="right"><font size=2 face="arial" Color="blue"><a href="/OA_HTML/OA.jsp?OAFunc=OAHOMEPAGE">Home</a></font></td>'
          ||'<td align="right"><font face="arial" size="2"><a href="javascript:parent.window.close()">Close</a></font></td></tr>'
          ||'</TABLE>'
          ||'<hr width=100% size="7" color="red" noshade="noshade">'
          ||'<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0" WIDTH="100%">'
          ||'<tr><td width="25%" height="" align="right"><font face="Arial" color="#4863A0" size="2"><b> Date: '||SYSDATE||'</b></font></td></tr>'
          ||'<tr><td width="75%" height="50" align="center"><font face="Trebuchet MS" color="#4863A0" size="4"><b> EASy Tune - SQL Statements - Report </b></font></td></tr>'
          ||'</TABLE>'
          ||'<br>');
  IF (p_sql_id IS NOT NULL) THEN
  lc_error := 'Getting SQL Text';  
     SELECT SQL_FULLTEXT 
     INTO lc_SQL_text
     FROM gv$SQL
     WHERE sql_id = p_sql_id
     and rownum = 1;
  
  END IF;
     
  lc_error := 'Creating Task';  

  task_name := DBMS_SQLTUNE.CREATE_TUNING_TASK( sql_text => lc_sql_text,
                                   user_name => 'APPS',
                                   scope => 'COMPREHENSIVE',
                                   time_limit => p_time_limit
                                   );
 lc_error := 'executing Task'; 
dbms_sqltune.execute_tuning_task ( task_name);
 lc_error := 'executing report'; 

-- htp.P(dbms_sqltune.report_tuning_task(task_name));

lc_report_text := dbms_sqltune.report_tuning_task(task_name);

--htp.PRN(dbms_lob.getlength(lc_report_text));
htp.PRN('<PRE>');
loop
         exit when l_offset > dbms_lob.getlength(lc_report_text);
         htp.PRN( dbms_lob.substr( lc_report_text,255, l_offset ) );
         l_offset := l_offset + 255;
end loop;
htp.PRN('</PRE>');
EXCEPTION WHEN OTHERS THEN
  htp.PRN('Encountered Error : '|| SQLERRM||chr(13)
         ||lc_error);
  
end;

procedure XX_DBMS_TUNE
as
BEGIN
 IF (icx_sec.ValidateSession ) THEN
 -- Header
          htp.p('<HTML>');
          htp.p('<HEAD>');
          htp.p('<TITLE> EASy Tune - SQL Statements </TITLE>');
          htp.p('</HEAD>');
          htp.p('<BODY MARGINHEIGHT=0 MARGINWIDTH=0 BGCOLOR="">');
          htp.p('<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0" WIDTH="100%">');
          htp.p('<tr><td width="75%"  height="" align="left"><img src="/OA_MEDIA/ODLOGO.gif"></td>');
          htp.p('<td align="right"><font size=2 face="arial" Color="blue"><a href="/OA_HTML/OA.jsp?OAFunc=OAHOMEPAGE">Home</a></font></td><td align="right"><font face="arial" size="2"><a href="javascript:parent.window.close()">Close</a></font></td></tr>');
          htp.p('</TABLE>');
          htp.p('<hr width=100% size="7" color="red" noshade="noshade">');
          htp.p('<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0" WIDTH="100%">');
          htp.p('<tr><td width="20%" height="" align="right"><font face="Arial" color="#4863A0" size="2"><b> Date: '||SYSDATE||'</b></font></td></tr>');
          htp.p('<tr><td width="80%" height="50" align="center"><font face="Trebuchet MS" color="#4863A0" size="4"><b> EASy Tune - Performance Tuning Advisor </b></font></td></tr>');
          htp.p('</TABLE>');
          htp.p('</BODY>');
          htp.p('</HTML>');
-- Main Body          
htp.print('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
	<head>
	<!-- The recommended practice is to load jQuery from Google''s CDN service.  --> 
<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.js"></script> 
 
<!-- Tabs, Tooltip, Scrollable, Overlay, Expose. No jQuery. --> 
<script src="http://cdn.jquerytools.org/1.1.1/tiny/jquery.tools.min.js"></script>

<script type="text/javascript">

function validate_form(thisform)
{
document.body.style.cursor=''wait'';
with (thisform)
  {
    if (p_time_limit.value == "")
  {p_time_limit.focus();
  alert("Time Limit Cannot BE NULL. Please enter a value");
  return false;
  }
    if ((p_sql_text.value != "") && (p_sql_id.value != ""))
  {p_sql_text.focus();
  alert("Please Enter either the SQL Text or SQL ID. Both cannot be entered simultaneously");
  return false;
  }
  if ((p_sql_text.value == "") && (p_sql_id.value == ""))
  {p_sql_text.focus();
  alert("Please Enter either the SQL Text or SQL ID. Any one input is required to proceed");
  return false;
  }  
  }
}
</script>
<!-- standalone page styling -->
<style>
body {
	padding:10px 50px;
	font-family:"Lucida Grande","Lucida Sans Unicode","bitstream vera sans","trebuchet ms",verdana;
}

/* get rid of those system borders being generated for A tags */
a:active {
  outline:none;
}

:focus {
  -moz-outline-style:none;
}
</style>
<!-- javascript coding -->
<script>
$(function() {

// select all desired input fields and attach tooltips to them
$("#myform :input").tooltip({

	// place tooltip on the right edge
	position: "center right",

	// a little tweaking of the position
	offset: [-2, 10],

	// use the built-in fadeIn/fadeOut effect
	effect: "fade",

	// custom opacity setting
	opacity: 0.7,

	// use this single tooltip element
	tip: ''.tooltip''

});
});
</script>
</head>
<body>
<style>
.tooltip {
	background-color:#000;
	border:1px solid #fff;
	padding:10px 15px;
	width:200px;
	display:none;
	color:#fff;
	text-align:left;
	font-size:12px;

	/* outline radius for mozilla/firefox only */
	-moz-box-shadow:0 0 10px #000;
	-webkit-box-shadow:0 0 10px #000;
}



#myform {
	border:2px outset #ccc;
	padding:10px;
	margin:20px 0;
	width:750px;
	-moz-border-radius:4px;
}

#myform h3 {
	text-align:center;
	margin:0 0 10px 0;
}

#inputs label, #inputs input, #inputs textarea, #inputs select {
	display: block;
	width: 550px;
	float: left;
	margin-bottom: 1px;
}

#inputs label {
	text-align: right;
	width: 150px;
	padding-right: 20px;
}

#inputs br {
	clear: left;
}
</style>

<div class="tooltip"></div>
<CENTER>
<FORM NAME="myform" id="myform" ACTION="XX_DBMS_TUNE_PKG.PROCESS_REQUEST" METHOD="GET"  onsubmit="return validate_form(this)">
	<div id="inputs">
		<!-- username -->
		<label for="SQL Text">SQL Text</label>
        <textarea id="p_sql_text" name="p_sql_text" rows="15" cols="1" title="Enter SQL Text without parameters(use bind variables) and semi colon at the end"></textarea><br />
		<!-- password -->
		<label for="p_sql_id">SQL ID</label>
		<input id="p_sql_id" name="p_sql_id" title="Enter a Valid SQL IDentifier" /><br />

		<!-- email -->
		<label for="p_time_limit">Max Time Limit (seconds)</label>
		<input id="p_time_limit" value = 60 name="p_time_limit" title="Please enter the maximum Execution time that can be taken by the task" />
        <br/>
	</div>
        </p>
	    <INPUT TYPE=SUBMIT NAME="p_action" title="Submit tuning Task" VALUE="Submit">
		<INPUT TYPE=RESET NAME="p_clear" VALUE="Clear" title="Reset Form">
	<!--	<button type="button" title="This button won''t do anything">Proceed</button> -->
	

</form>
</CENTER>
');

htp.p('

<div align=center>
Usage : Place the cursor on the respective fields for instructions.
</div>

<p style=''margin-bottom:12.0pt''><o:p>&nbsp;</o:p></p>

</div>');
htp.p('</BODY>
</HTML>');
end if;
end;
END;
/
SHOW ERR;