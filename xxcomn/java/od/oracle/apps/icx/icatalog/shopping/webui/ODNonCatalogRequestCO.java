/*-- +===================================================================================+
#-- |                           Oracle GSD                                              |
#-- |                         Bangalore, India                                          |
#-- +===================================================================================+
#-- |                                                                                   |
#-- |                                                                                   |
#-- |File Name : ODNonCatalogRequestCO.java                                             |
#-- |                                                                                   |
#-- |                                                                                   |
#-- |                                                                                   |
#-- |Change Record:                                                                     |
#-- |===============                                                                    |
#-- | Version   Date         Author            	Remarks                                 |
#-- |=======   ==========   ==============     	==========================              |
#-- |  1.0     18-FEB-2014  Darshini            Initial Version                         |
#-- +===================================================================================+*/
package od.oracle.apps.icx.icatalog.shopping.webui;

import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;
import oracle.apps.icx.icatalog.shopping.webui.NonCatalogRequestCO;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.jbo.Row;

public class ODNonCatalogRequestCO extends NonCatalogRequestCO 
{
    public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
    {
	if (pageContext.getParameter("AddToCart") != null) //Capturing the 'Add To Cart' Event
        {
        // Getting the AM and VO Details associated  with the Category Field
        OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);
        OAViewObject vo = (OAViewObject)am.findViewObject("NonCatalogRequestVO");
        Row curRow = (Row)vo.getCurrentRow();
	     if(curRow!=null)
            {
			String CategoryName = (String)curRow.getAttribute("CategoryName");
			pageContext.writeDiagnostics(this,"CategoryName: = " + CategoryName ,OAFwkConstants.STATEMENT);
            if("DO NOT USE_SELECT A CATEGORY.NON-TRADE.0.0.0".equals(CategoryName))
            throw new OAException("Please choose another category other than the Default ", 
                                   OAException.ERROR);
           }
		}
		super.processFormRequest(pageContext, webBean);
    }
}
