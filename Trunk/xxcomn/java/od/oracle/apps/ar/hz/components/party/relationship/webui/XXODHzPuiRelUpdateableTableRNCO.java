/*-- +===================================================================================+
#-- |                           Oracle GSD                                              |
#-- |                         Bangalore, India                                          |
#-- +===================================================================================+
#-- |                                                                                   |
#-- |                                                                                   |
#-- |File Name : XXODHzPuiRelUpdateableTableRNCO.java                                   |
#-- |                                                                                   |
#-- |                                                                                   |
#-- |                                                                                   |
#-- |Change Record:                                                                     |
#-- |===============                                                                    |
#-- |Version   Date         Author            	Remarks                                 |
#-- |=======   ==========   ==============     	==========================              |
#-- |  1.0     17-JAN-2014  Darshini G            Initial Version                       |
#-- +===================================================================================+*/

package od.oracle.apps.ar.hz.components.party.relationship.webui;


import oracle.apps.ar.hz.components.party.relationship.server.HzPuiRelationshipAMImpl;
import oracle.apps.ar.hz.components.party.relationship.webui.HzPuiRelUpdateableTableRNCO;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;


public class XXODHzPuiRelUpdateableTableRNCO extends HzPuiRelUpdateableTableRNCO
{
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
           {
             super.processRequest(pageContext, webBean);
             HzPuiRelationshipAMImpl am = (HzPuiRelationshipAMImpl)pageContext.getApplicationModule(webBean);
             OAViewObject vo = (OAViewObject)am.findViewObject("HzPuiRelationshipTableVO");
             //getting parameters for existing where clause
			 String str1 = getParameter(pageContext, "HzPuiObjectPartyId");
             String str2 = getParameter(pageContext, "HzPuiObjectPartyType");
             String str3 = getParameter(pageContext, "HzPuiSubjectPartyType");
             //getting the existing where clause    
             String exstclause = vo.getWhereClause(); 
             String CustClause = exstclause + "AND relationship_type <> 'OD_FIN_HIER'";
             if (vo!=null)
             {
               //Adding where clause
   			   vo.setWhereClause(null);
               vo.setWhereClauseParams(null);
               vo.setWhereClause(CustClause);
               vo.setWhereClauseParam(0,str2);
               vo.setWhereClauseParam(1,str1);
               vo.setWhereClauseParam(2,str3);
               vo.executeQuery();
             }
             
           }
  
  }
