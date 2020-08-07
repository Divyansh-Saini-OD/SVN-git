package od.oracle.apps.xxcrm.cs.csz.search.webui;

import oracle.apps.cs.csz.search.webui.AdvSrchCO;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

public class AdvSrchCOExtn08 extends AdvSrchCO {

    public void processRequest(OAPageContext pageContext, OAWebBean webBean)
    {
      super.processRequest(pageContext, webBean);
    }
    public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
    {
	if (pageContext.getParameter("CszSrchSearchBtn")!=null)
	{	
            if (pageContext.getParameter("xxMCContactMethod")!=null && !pageContext.getParameter("xxMCContactMethod").toString().trim().equals("") )
               {
                String s1= pageContext.getParameter("xxMCContactMethod").toString(); 
                pageContext.putSessionValueDirect("xxContactMethod", s1);
               }
            else
              {
              pageContext.putSessionValueDirect("xxContactMethod", "NA");	
              } 
			  
            if (pageContext.getParameter("xxMTDCNumber")!=null && !pageContext.getParameter("xxMTDCNumber").toString().trim().equals("") )
               {
                String s2= pageContext.getParameter("xxMTDCNumber").toString(); 
                pageContext.putSessionValueDirect("xxDCNumber", s2);
               }
            else
              {
              pageContext.putSessionValueDirect("xxDCNumber", "NA");	
              } 			  
       }
        super.processFormRequest(pageContext, webBean);
    }
}
