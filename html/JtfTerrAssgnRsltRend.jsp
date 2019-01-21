<!--===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
/*===========================================================================+
 |      		       Office Depot - Project Simplify                       |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             JtfTerrAssgnDtl.jsp                                           |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |             Territory lookup jsp page.                                    |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |                                                                           |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    20/11/2007 Anirban Chaudhuri   Modified the Oracle seeded jsp file     |
 |                                                                           |
 +===========================================================================-->

<!--=========================================================================+
 |      Copyright (c) 2000 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  FILENAME                                                                 |
 |     JtfTerrAsgnRsltRend.jsp                                               |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |     Territory Lookup Form Page                                            |
 |  NOTES                                                                    |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |     15-OCT-2001 eihsu            Created.                                 |
 |     16-OCT-2001 eihsu Edward Hsu Reverted to older output rec names       |
 |     23-JAN-2002 eihsu Edward Hsu Does not display email link if email N/A |
 |     07-MAY-2002 arpatel          Added hyperlink for territory name to    |
 |                                  JtfTerrAssgnDtl.jsp page                 |
 |                                                                           |
 +=========================================================================-->

 

<!-- $Header: JtfTerrAssgnRsltRend.jsp 115.13 2003/10/21 00:14:25 jdochert ship $ -->
<%	///////////////////////////////////////////////
		// RESULT RENDERING BEGINS - GIVEN DATA EXISTS
		///////////////////////////////////////////////

		// Generates output of Territory Lookup results

		////////////////////////////////////////////////////////////////////////////////////////////
		// Requires:	String action must be instantiation with "RESULT" or something else.
		//						Array assign_results - Array must be instantiated with 
		//				    assign_results.column1 is <!-- salesperson -->
		//						assign_results.column2 is <!-- Job Title -->
		//						assign_results.column3 is <!-- Phone Number -->
		//						assign_results.column4 is <!-- E-Mail -->
		//						assign_results.column5 is <!-- Manager Name-->
		//						assign_results.column6 is <!-- Manager Phone Number -->
		//
		// Modifies:	Sets array record elements to "&nbsp;" if they are null;
		//
		// Effects:		IF String action == "RESULT"
		//								Outputs HTML Table and assignment results if records exist, message otherwise
		//					  ELSE 
		//							  Outputs HTML Table with message "No Lookup Conducted" --> JTF_TERR_NO_SEARCH_CONDUCTED						
		
		
%>		
	<table width=100%><!-- TERRR ASSIGN RESULTS RENDERER JtfTerrAsgnRsltRend.jsp-->
				<tr><td colspan="7" class="sectionHeader1" nowrap><%=_prompts[38]%><!--Results--></td>
					<!-- this row for section Title-->
					</tr>
	  		<tr><td height=30 class=tableSmallHeaderCell align=center><%=_prompts[10]%></td> <!-- salesperson -->
						<td height=30 class=tableSmallHeaderCell align=center><%=_prompts[45]%></td> <!-- Role -->
						<td height=30 class=tableSmallHeaderCell align=center><%=_prompts[12]%></td> <!-- Job Title -->
						<td height=30 class=tableSmallHeaderCell align=center><%=_prompts[11]%></td> <!-- Phone Number -->
						<td height=30 class=tableSmallHeaderCell align=center><%=_prompts[13]%></td> <!-- E-Mail -->
						<td height=30 class=tableSmallHeaderCell align=center><%=_prompts[14]%></td> <!-- Manager Name-->
						<td height=30 class=tableSmallHeaderCell align=center><%=_prompts[16]%></td> <!-- Manager Phone Number -->
						<td height=30 class=tableSmallHeaderCell align=center><%=_prompts[44]%></td> <!-- Territory -->
						<td height=30 class=tableSmallHeaderCell align=center><%=_prompts[46]%></td> <!-- Top Level Territory -->
				</tr>
<%	
		if (!action.equals("RESULT")) { 
%>			<tr><td colspan="9" height=30 class=tableDataCell align=center><%=AOLMessageManager.getMessageSt("JTF_TERR_NO_SEARCH_CONDUCTED")%></td></tr>
<%	} else {
                if (assign_results.length > 0) {
                
  		  for (int i = 0; i < assign_results.length; i++) {
  			if (assign_results[i].resource_name == null )  assign_results[i].resource_name				= "&nbsp;";
  			if (assign_results[i].resource_phone == null )  assign_results[i].resource_phone 			= "&nbsp;";
  			if (assign_results[i].resource_job_title == null )  assign_results[i].resource_job_title 	= "&nbsp;";
  			if (assign_results[i].resource_email == null )  assign_results[i].resource_email 			= "&nbsp;";
  			if (assign_results[i].resource_mgr_name == null )  assign_results[i].resource_mgr_name 		= "&nbsp;";
  			if (assign_results[i].resource_mgr_phone == null )  assign_results[i].resource_mgr_phone 	= "&nbsp;";
  			if (assign_results[i].resource_mgr_email == null )  assign_results[i].resource_mgr_email  = "&nbsp;";
  			if (assign_results[i].property1 == null )  assign_results[i].property1  	= "&nbsp;";
  			if (assign_results[i].property2 == null )  assign_results[i].property2 	= "&nbsp;";
  			if (assign_results[i].property3 == null )  assign_results[i].property3 	= "&nbsp;";
//  			if (assign_results[i].property4 == null ) assign_results[i].property4 	= "&nbsp;";
			}
%>
<%		
				for (int i = 0; i < assign_results.length; i ++) { %>
			 	<tr>
			 		<td class=tableDataCell height=30 align=center>
			 			<%=assign_results[i].resource_name%></td>
					<td class=tableDataCell height=30 align=center>
						<%=assign_results[i].property2%></td>
					<td class=tableDataCell height=30 align=center>
						<%=assign_results[i].resource_job_title%></td>
					<td class=tableDataCell height=30 align=center>
						<%=assign_results[i].resource_phone%></td>
					<td class=tableDataCell height=30 align=center>
<%        if (assign_results[i].resource_email.equals("") || assign_results[i].resource_email.equals("&nbsp;")) {
%>					&nbsp;
<%				} else {
%>					<a href="mailto:<%=assign_results[i].resource_email%>"><%=assign_results[i].resource_email%></a>
<%				}
%>					</td>
					<td class=tableDataCell height=30 align=center>
						<%=assign_results[i].resource_mgr_name%></td>
					<td class=tableDataCell height=30 align=center>
						<%=assign_results[i].resource_mgr_phone%></td>
					<td class=tableDataCell height=30 align=center>
<%        if (assign_results[i].property1.equals("") || assign_results[i].property1.equals("&nbsp;")) {
%>					&nbsp;
<%				} else {	                             
                                       String sales_person = java.net.URLEncoder.encode(assign_results[i].resource_name+", "+assign_results[i].resource_job_title);
                                       String enc_org_details = java.net.URLEncoder.encode(org_details);
                                       String org_name = java.net.URLEncoder.encode(lk_org);
                                       String postal_code = java.net.URLEncoder.encode(PostalCode);
%>                                       
              				
            				<%=assign_results[i].property1%>
				     
<%				}
%>					
					     
						</td>
					<td class=tableDataCell height=30 align=center>
						<%=assign_results[i].property3%></td>
						</tr>
<% 			}
			} else {
%>			<tr><td class=tableDataCell height=30 colspan=9><center>
					<%=AOLMessageManager.getMessageSt("JTF_TERR_LOOKUP_NO_TERRS")%></center> 
					</td></tr>
<%		}
		}  // this this result or just pre-populated table?
%>	</table>
