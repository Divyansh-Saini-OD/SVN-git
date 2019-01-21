<!--=========================================================================+
 |      Copyright (c) 2001 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  FILENAME                                                                 |
 |     JtfTerrLookupOrgRend.jsp                                              |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |     Territory Lookup Basic Form Page                                      |
 |  NOTES                                                                    |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |     16-OCT-2000 arpatel  Amit R. Patel        Created.                    |
 |     23-OCT-2001 eihsu    Edward Hsu		 Display and flow changes    |
 |     01-NOV-2001 eihsu    Edward Hsu		 field validation fix        |
 |     20-NOV-2001 arpatel  Amit R. Patel        Added standard JTTY include |
 |     05-FEB-2002 imachin  Igor Machin          Corrected Country select    |
 |                                               (bug 2212779)               |
 |                                                                           |
 |     15-MAY-2002 arpatel  Amit R. Patel        Added org_details variable  |
 |     05-JUN-2002 sgkumar  Sandeep Kumar        Corrected First, Previous   |
 |                                               Links (2168340)             |
 |     03-MAR-2004 shli     Shuang Li            Added 'Certification Level' |
 +=========================================================================-->
<!-- $Header: JtfTerrLookupOrgRend.jsp 115.17 2004/03/23 00:32:35 shli ship $ -->

<%
///////////////////////////////////////////////
// HTML RENDERING BEGINS
///////////////////////////////////////////////
%>

<HTML>
<HEAD><TITLE><%=_prompts[0]%>: <%=_prompts[1]%></TITLE>
<!-- CRM Foundation: Territory Lookup -->
<%@ include file="jtfscss.jsp" %> <!-- Style Sheet -->

<SCRIPT>
	function goFirst(n) {
			document.forms['JtfTerrLookupOrg'].FIRST_REC.value=n;
			document.forms['JtfTerrLookupOrg'].submit(); 
			return false;
	}
	
	function chkorg() {
	
	  if (document.forms['JtfTerrLookupOrg'].squal_char01.value.length < 3) {
		
		          document.forms['JtfTerrLookupOrg'].SearchOrg.disabled=true;
	                  //alert('<%= AOLMessageManager.getMessageSt("JTF_TERR_LOOKUP_3CHARS")%>');
				return false;
			} else {
			        document.forms['JtfTerrLookupOrg'].SearchOrg.disabled=false;
	  if (document.forms['JtfTerrLookupOrg'].squal_char01.value.length > 99)           {
               
            alert('<%= AOLMessageManager.getMessageSt("JTF_TERR_LOOKUP_MAXCHARS")%>');
            return false; 

           } 
				return false;
			}
	}
		

</SCRIPT>

</HEAD>
<%@ page  import="java.sql.*,java.util.*,java.io.*,javax.servlet.*,javax.servlet.http.*" %>
<%@ page import="oracle.jdbc.driver.OracleConnection" %>

<BODY class='applicationBody'>
<%@ include file="jtfdnbartop.jsp" %>

<br>
<table align=center summary= ""><!-- main body table -->
	<tr><td width=5>&nbsp;</td> <!-- left padding -->
	<td>
	<table align=center summary= ""><!-- all content table -->
<%
  if (action.equals("RESULT")) {

			//////////////////////////////////////////////////////////
			// RESULT GENERATOR BEGINS
	  	        //////////////////////////////////////////////////////////

%>	  <tr><!-- this row for page title -->
		    <td class=pageTitle colspan=2 nowrap><%=_prompts[1]%><!--Territory Lookup--></td>
	  </tr>
  	  <tr><td colspan=2><hr></td></tr>
  	  <tr><td width=20>&nbsp;</td><!-- indentation -->
		<td>
		<table width=100%>	   
          <tr>
	     <td class=sectionHeader1 nowrap><%=_prompts[34]%><!--Lookup by Organization --></td>
	  </tr>
	  <tr>
<%    String org_details = lk_org + ", "+lk_address + " " + lk_city +", " + lk_State +", " + lk_PostalCode + " " + lk_Country;	  
%>	  
	  	     <td> <span class=sectionHeader2 nowrap><%=_prompts[5]%></span>:&nbsp;<%=org_details%>
	             <!--Organization: party name address etc -->
	             </td>
	  </tr>
	  <tr><td class=prompt>&nbsp;</td></tr>
          <tr><td>
<%
          //We want org_results postal code to be passed in here
          PostalCode = lk_PostalCode;
%>                    
          <%@ include file="JtfTerrAssgnRsltRend.jsp" %>
	  </td></tr>
<%    } else {
%>           
	  <tr><!-- this row for page title -->
	    <td class=pageTitle colspan=2 nowrap><%=_prompts[1]%><!--Territory Lookup --></td>
	  </tr>
	  <tr><td colspan=2><hr></td></tr>
	  <tr><td width=20>&nbsp;</td><!-- indentation -->
		<td>
		<table width=100%>	
	  <tr>
	    <td class=sectionHeader1 nowrap><%=_prompts[34]%><!--Lookup by Organization --></td>
	  </tr>
	  <tr>
	    <td colspan=5 class="footnote"><li><%= AOLMessageManager.getMessageSt("JTF_TERR_LKU_FIND_ORG")%>
		<!--To find a salesperson, enter your criteria in the fields below. -->
		</td>
	  </tr>
	  <tr>
			<td>
     <form Method = post action="<%=link%>" name="JtfTerrLookupOrg">
     
	<input type=hidden name="ACTION" value="LISTORGS">
<%
		//////////////////////////////////////////////////////////
			// FORM GENERATOR BEGINS
	  	//////////////////////////////////////////////////////////	
%>
		<table width=100%><!-- form content table -->

		<tr>
		<td class=prompt align=right><img src="/OA_MEDIA/requiredicon_status.gif"><%=_prompts[5]%><!--Organization--></td>
							
              	<td><input type="text" name="squal_char01" MAXLENGTH="<%=jttyMaxFieldLen%>" size="40" onChange="chkorg()" onKeyUp="chkorg()" onMouseUp="chkorg()"
              	
<%              if (action.equals("LISTORGS")) {
%>              value="<%=org%>"
<%              } else {
%>               value="" &nbsp;
<%              }
%>                             
		>
            	</td>
            	</tr>

                <input type="hidden" name="FIRST_REC" value="1">
		<tr><td class=prompt align=right><%=_prompts[40]%><!--Country--></td>
            	<td>
            	<select name="squal_char07" width=null>
		<option value=""> </option>
<%	for (int i = 0; i < results_tbl_country_vals.length; i++ ) {
%>		<option 
<%			if (results_tbl_country_vals[i].column2.equals(Country)){
%>	     	selected
<%      }
%>             value="<%=results_tbl_country_vals[i].column2 %>">
		<%=results_tbl_country_vals[i].column1%></option>
<%	}
%>		</select>
		</td>
		</tr>

<%

OracleConnection conn1 = null;
ResultSet getCountRs = null;
PreparedStatement getCountStmt = null;
//out.println("State: "+State);
try {

conn1        = (OracleConnection)TransactionScope.getConnection() ;
String query = "select state_code,state_description from apps.xx_tm_terr_lookup_state_v";
getCountStmt = conn1.prepareStatement(query);
getCountRs   = getCountStmt.executeQuery();

%>
		<tr><td class=prompt align=right><%=_prompts[42]%><!--State/Province--></td>
		<td>
		<select name="squal_char04"  value="">
		     <option value=""> </option>                    
<%
while(getCountRs.next())
{  
%>
                     <option
<%     
 if (getCountRs.getString(1).equals(State)){
%>           
                     selected
<%           
}
%>                     
                     value="<%=getCountRs.getString(1)%>">
		            <%=getCountRs.getString(2)%>
		     </option>       
<%
}
%>
                     </select>
<%
}
catch(Exception e)	
{
 out.println(e);
}
%>
		</td></tr>

		<tr><td class=prompt align=right><%=_prompts[41]%><!--Postal Code--></td>
		<td>
              	<input type="text" name="squal_char06" MAXLENGTH="<%=jttyMaxFieldLen%>" size="25"
<%              if (action.equals("LISTORGS")) {
%>              value="<%=PostalCode%>"
<%              }
%>              
<%             
%>                
                </td></tr>

                <tr><td class=prompt align=right><%=_prompts[54]%><!--Certification Level--></td>
                <td>
                <select name="squal_char08" width=null>
                <option value=""> </option>
<%      for (int i = 0; i < results_tbl_cert_level_vals.length; i++ ) {
%>              <option
<%                      if (results_tbl_cert_level_vals[i].column2.equals(Cert_level)){
%>              selected
<%      }
%>             value="<%=results_tbl_cert_level_vals[i].column2 %>">
                <%=results_tbl_cert_level_vals[i].column1%></option>
<%      }
%>              </select>
                </td>
                </tr>
 

 
		<tr><td class=prompt>&nbsp;</td></tr>
		<tr><div align=right>
		<td colspan=2 align=right>
<%	if (org.equals("")) {
%>  	<input disabled type=submit name="SearchOrg"
<%	} else {
%>  	<input type=submit name="SearchOrg"
<%	}
%>			 value="<%=_prompts[2]%>"
				 action="<%=link%>"
				 ><!--Go-->

			        <input type="button" name="Clear"
				 value="<%=_prompts[4]%>"
				 onClick="document.forms['JtfTerrLookupOrg'].action='<%=link%>';
				 document.forms['JtfTerrLookupOrg'].ACTION.value='FORM';
			         document.forms['JtfTerrLookupOrg'].squal_char01.value='';
			         document.forms['JtfTerrLookupOrg'].squal_char04.value='';
                                 document.forms['JtfTerrLookupOrg'].squal_char06.value='';
                                 document.forms['JtfTerrLookupOrg'].squal_char07.value=' ';
                                 document.forms['JtfTerrLookupOrg'].squal_char08.value=' ';
				 document.forms['JtfTerrLookupOrg'].submit();
				 return false;"
				><!--Clear-->
		</td>
		</div>      
		</tr>
		<tr>
		  <td colspan=2 align=left class="footnote" nowrap><img src="/OA_MEDIA/requiredicon_status.gif"> <%=_prompts[37]%>&nbsp;<%= AOLMessageManager.getMessageSt("JTF_TERR_ENTER_3_CHARS")%><!--Indicates required field. Please enter at least 3 characters. --></td>
		</tr>
		</table><!-- query form table -->
		</form>				
		</td></tr>
                <tr><td><hr></td></tr>

<%  	//////////////////////////////////////////////////////////	
			// FORM GENERATOR ENDS
  		//////////////////////////////////////////////////////////

//      if (action.equals("LISTORGS")) {
%>			<tr><td>
          <%@include file="JtfTerrOrgListRend.jsp" %>
					</td></tr>
<%         if (orglist_results.size() > 0) {
%>			<tr>
				<TD colspan=2 ALIGN="CENTER">
				
<% 				if (set < total_rows) {
%>				<!-- First -->
<% if (first_rec == 1) { %>
<%=_prompts[17]%> |
<% } else { %>
<a href="<%=link%>" onClick="goFirst('1'); return false;"><%=_prompts[17]%></a> |
<% } %>
					<!-- Previous -->
<% if (first_rec == 1) { %>
<%=_prompts[18]%> |
<% } else { %>
					<a href="<%=link%>" onClick="goFirst('<%=(first_rec - set)%>'); return false;"><%=_prompts[18]%></a> 
<% } %>
<%				}
%>

<%				if (total_rows > first_rec + set -1 ) {
%>					<%=first_rec%> - <%=first_rec + set -1 %> <%=_prompts[21]%> <%=total_rows%>
<%				} else {
%>					<%=first_rec%> - <%=total_rows%> <%=_prompts[21]%> <%=total_rows%>
<%				}
%>
<%				if (last_rec < total_rows) {
%>			  <!-- Next -->
					<a href="<%=link%>" onClick="goFirst('<%=(first_rec + set)%>'); return false;"><%=_prompts[19]%></a> 
					<!-- Last -->
					| <a href="<%=link%>" onClick="goFirst('<%=laststart%>'); return false;"><%=_prompts[20]%></a>
<%				}
%>
				</td>
			</tr>
<%	    }
%>						
					
<%//    } // doing this all the time per JT except RESULTS!
     } //else !RESULT
%>                              </table>
	                        </td></tr><!-- close indentation -->
				</table><!-- all content table -->
			<td width=5>&nbsp;</td>
		</td></tr>	
		</table><!--- MAIN BODY TABLE -->
<%@include file = "jtfdnbarbtm.jsp"%> <!--Bottom of side navigation bar -->
</BODY>
</HTML>
<%@include file = "jtfernlp.jsp"%> <!--Send an End Request -->
<%
///////////////////////////////////////////////
// HTML RENDERING ENDS
///////////////////////////////////////////////
%>
