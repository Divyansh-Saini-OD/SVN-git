package od.oracle.apps.xxcrm.cs.csz.search.webui;

 

import oracle.apps.cs.csz.search.webui.AdvSrchResultsRNCO;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.jbo.Row;
import java.sql.CallableStatement; 
import java.sql.Types;
import java.sql.Connection;

public class AdvSrchResultsRNCOExtn024 extends AdvSrchResultsRNCO { 
public void processRequest(OAPageContext pageContext, OAWebBean webBean)
    {
      super.processRequest(pageContext, webBean);
      String sXXContactMethod = "NA";
	  String sXXDCNumber = "NA";
      if (pageContext.getSessionValueDirect("xxContactMethod")!=null) { sXXContactMethod = pageContext.getSessionValueDirect("xxContactMethod").toString(); }
	  if (pageContext.getSessionValueDirect("xxDCNumber")!=null) { sXXDCNumber = pageContext.getSessionValueDirect("xxDCNumber").toString(); }
      
	  
      if ( !sXXContactMethod.equals("NA") || !sXXDCNumber.equals("NA"))  
      {
      OAApplicationModule localOAApplicationModule = pageContext.getApplicationModule(webBean);
      OAViewObject localOAViewObject = (OAViewObject)localOAApplicationModule.findViewObject("SrchResultsVO");     
      if (localOAViewObject!=null)
          { //vo if
			  pageContext.writeDiagnostics(this,"Vo is available",1);
			  String sQuery=localOAViewObject.getQuery();                
			  pageContext.writeDiagnostics(this,"Custom Query is" + sQuery,1);
			  localOAViewObject.last();
			  Row rw =localOAViewObject.first();
			  while (rw!=null)
			{ //while loop
							  String sIncidentId= rw.getAttribute("Incidentid").toString();
							  pageContext.writeDiagnostics(this,"xxIncidentId is" + sIncidentId,1);
							  							 
							  String sContactMehtod = getContactMethod(sIncidentId,pageContext,webBean);
							  pageContext.writeDiagnostics(this,"sContactMehtod is" + sContactMehtod,1);
                              //String sXXContactMethod = pageContext.getSessionValueDirect("xxContactMethod").toString();
			                  pageContext.writeDiagnostics(this,"xxContactMethod is" + sXXContactMethod,1);
                              
							  String sDCNumber = getDCNumber(sIncidentId,pageContext,webBean);
							  pageContext.writeDiagnostics(this,"sDCNumber is" + sDCNumber,1);
							  pageContext.writeDiagnostics(this,"xxDCNumber is" + sXXDCNumber,1);
                              
							  
                               // if (!sContactMehtod.equals(sXXContactMethod))//"018674"))
								//	{
									//	localOAViewObject.removeCurrentRow();
								//	}
																    
                                    if ((!sContactMehtod.equals(sXXContactMethod) && !sXXContactMethod.equals("NA")) || (!sDCNumber.equals(sXXDCNumber)&&!sXXDCNumber.equals("NA")))//"018674"))
									{
										localOAViewObject.removeCurrentRow();
									}
									
                                
							    rw=localOAViewObject.next();
			} //while end
          } //vo else
      else
         {
           pageContext.writeDiagnostics(this,"Vo is not available",1);


         } //vo end
       }
	}
   

    public void processFormRequest(OAPageContext paramOAPageContext, OAWebBean paramOAWebBean)
    {
      super.processFormRequest(paramOAPageContext, paramOAWebBean);
    }
	
    public String getContactMethod(String pIncidentId,OAPageContext pageContext, OAWebBean webBean)
    {
    String sContactMehtod = "NONE"; 
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    CallableStatement cstmt = null;
    try
       {
       Connection conn = am.getOADBTransaction().getJdbcConnection();
       cstmt = conn.prepareCall("{call ?:=XX_CS_CONTACT_METHOD_PKG.XX_CS_GET_CONTACT_METHOD(?)}");
       cstmt.registerOutParameter(1,Types.VARCHAR);
       cstmt.setString(2,pIncidentId);
       cstmt.execute();
       sContactMehtod = cstmt.getString(1);
	   if (sContactMehtod==null)
		   sContactMehtod = "NONE";
       pageContext.writeDiagnostics(this,"ReturnContactMehtod is" + sContactMehtod,1);
       cstmt.close();
       }

    catch(Exception e)   {
    pageContext.writeDiagnostics(this,"Error  is" + e.getMessage(),1);
	}
	finally {
            try {
			   if (cstmt!=null)
			     cstmt.close();
			   }
            catch(Exception e) {
				pageContext.writeDiagnostics(this,"Error  is" + e.getMessage(),1);
			}
	}
    return sContactMehtod;
    }
	
	 public String getDCNumber(String pIncidentId,OAPageContext pageContext, OAWebBean webBean)
    {
    String sDCNumber = "NONE"; 
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    CallableStatement cstmt = null;
    try
       {
       Connection conn = am.getOADBTransaction().getJdbcConnection();
       cstmt = conn.prepareCall("{call ?:=XX_CS_DC_NUMBER_PKG.XX_CS_GET_DC_NUMBER(?)}");
       cstmt.registerOutParameter(1,Types.VARCHAR);
       cstmt.setString(2,pIncidentId);
       cstmt.execute();
       sDCNumber = cstmt.getString(1);
	   if (sDCNumber==null)
		   sDCNumber = "NONE";
       pageContext.writeDiagnostics(this,"ReturnDCNumber is" + sDCNumber,1);
       cstmt.close();
       }

    catch(Exception e)   {
    pageContext.writeDiagnostics(this,"Error  is" + e.getMessage(),1);
	}
	finally {
            try {
			   if (cstmt!=null)
			     cstmt.close();
			   }
            catch(Exception e) {
				pageContext.writeDiagnostics(this,"Error  is" + e.getMessage(),1);
			}
	}
    return sDCNumber;
    }

}