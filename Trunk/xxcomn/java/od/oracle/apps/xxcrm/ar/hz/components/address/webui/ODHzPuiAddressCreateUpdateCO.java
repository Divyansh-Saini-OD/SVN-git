/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODHzPuiAddressCreateUpdateCO.java                             |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    New CO for HzPuiAddressCreateUpdate region                             |
 |                                                                           |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    No dependencies.                                                       |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |   03-Jul-2009 Anirban Chaudhuri  Created for defect#16097.                |
 +===========================================================================*/

package od.oracle.apps.xxcrm.ar.hz.components.address.webui;

import com.sun.java.util.collections.HashMap;
import java.io.Serializable;
import java.util.Hashtable;
import java.util.Vector;
import oracle.apps.ar.hz.components.util.webui.HzPuiWebuiUtil;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.*;
import oracle.apps.fnd.framework.webui.beans.OADescriptiveFlexBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OAFormValueBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageCheckBoxBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.cabo.ui.UIConstants;
import oracle.cabo.ui.beans.form.CheckBoxBean;
import oracle.cabo.ui.beans.form.FormElementBean;
import oracle.jbo.common.Diagnostic;
import oracle.jbo.domain.Number;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.OAPageContext;

import od.oracle.apps.xxcrm.asn.common.customer.server.ODPartySiteAccountCheckVOImpl;
import od.oracle.apps.xxcrm.asn.common.customer.server.ODPartySiteAccountCheckVORowImpl;

import oracle.apps.fnd.framework.OAViewObject;
import oracle.jbo.Row;

public class ODHzPuiAddressCreateUpdateCO extends oracle.apps.ar.hz.components.address.webui.HzPuiAddressCreateUpdateCO
{

    public void processRequest(OAPageContext pageContext, OAWebBean oawebbean)
    {
       super.processRequest(pageContext, oawebbean); 
	   /*
	   String s = "od.oracle.apps.xxcrm.ar.hz.components.address.webui.ODHzPuiAddressCreateUpdateCO.processRequest";
	
	   String checkPartySiteId = pageContext.getParameter("HzPuiAddressPartySiteId");

	   pageContext.writeDiagnostics(s, "Anirban 3rd July'09 : XX_ASN_ALLOW_VPD_ADDR_UPDATE profile value is :: "+pageContext.getProfile("XX_ASN_ALLOW_VPD_ADDR_UPDATE"), 1);

       if ("Y".equals(pageContext.getProfile("XX_ASN_ALLOW_VPD_ADDR_UPDATE")))
       {
         OAApplicationModule am = pageContext.getApplicationModule(oawebbean);

		 OAViewObject ODPartySiteAccountCheckVO = (OAViewObject)am.findViewObject("ODPartySiteAccountCheckVO");
         if ( ODPartySiteAccountCheckVO == null )
	        ODPartySiteAccountCheckVO = (OAViewObject)am.createViewObject("ODPartySiteAccountCheckVO","od.oracle.apps.xxcrm.asn.common.customer.server.ODPartySiteAccountCheckVO");

         if(ODPartySiteAccountCheckVO == null)
         {
	      pageContext.writeDiagnostics(s, "Anirban: ODHzPuiAddressCreateUpdateCO: ODPartySiteAccountCheckVO is still NULL",  OAFwkConstants.STATEMENT);
	      pageContext.writeDiagnostics(s, "Anirban: ODHzPuiAddressCreateUpdateCO: checkPartySiteId is : "+checkPartySiteId,  OAFwkConstants.STATEMENT);
	     }

         if ( ODPartySiteAccountCheckVO != null )
	     {
          ODPartySiteAccountCheckVO.setWhereClause(null);
	      ODPartySiteAccountCheckVO.setWhereClauseParams(null);
          ODPartySiteAccountCheckVO.setWhereClauseParam(0, checkPartySiteId);
          ODPartySiteAccountCheckVO.executeQuery();
	      pageContext.writeDiagnostics(s, "Anirban: ODHzPuiAddressCreateUpdateCO: checkPartySiteId is : "+checkPartySiteId,  OAFwkConstants.STATEMENT);
	     }

		ODPartySiteAccountCheckVORowImpl rowban = (ODPartySiteAccountCheckVORowImpl)ODPartySiteAccountCheckVO.first();

        if(rowban == null)
        {
	     pageContext.writeDiagnostics(s, "Anirban: ODHzPuiAddressCreateUpdateCO: rowban is NULL",  OAFwkConstants.STATEMENT);
	    }
 
        if (rowban != null)
        {
         pageContext.writeDiagnostics(METHOD_NAME, "Anirban: ODHzPuiAddressCreateUpdateCO: inside rowban != null ",  OAFwkConstants.STATEMENT);
         if (rowban.getCustAcctSiteId() != null)
         {
          pageContext.writeDiagnostics(METHOD_NAME, "Anirban: ODHzPuiAddressCreateUpdateCO: rowban.getCustAcctSiteId() IS NOT NULL !!!",  OAFwkConstants.STATEMENT);
        
		  if("UPDATE".equals(pageContext.getParameter("HzPuiAddressEvent")))
          {

           OATableBean oatablebean = (OATableBean)oawebbean.findIndexedChildRecursive("hzPartySiteUseTable");
           if(oatablebean != null)
           {
            oatablebean.setInsertable(false);
            oatablebean.setAutoInsertion(false);
            oatablebean.prepareForRendering(pageContext);
           }
		  }//if("UPDATE".equals(oapagecontext.getParameter("HzPuiAddressEvent")))  
		 }//if (rowban.getCustAcctSiteId() != null)
		}//if (rowban != null)
	   }//if ("Y".equals(pageContext.getProfile("XX_ASN_ALLOW_VPD_ADDR_UPDATE")))
	   */
    }

    public void processFormRequest(OAPageContext pageContext, OAWebBean oawebbean)
    {
        super.processFormRequest(pageContext, oawebbean);
        
    }

    public void processFormData(OAPageContext pageContext, OAWebBean oawebbean)
    {
    }

    public ODHzPuiAddressCreateUpdateCO()
    {
    }

    public static final String RCS_ID = "$Header: ODHzPuiAddressCreateUpdateCO.java 115.31 2005/03/29 23:01:42 achaudhu noship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: ODHzPuiAddressCreateUpdateCO.java 115.31 2005/03/29 23:01:42 achaudhu noship $", "od.oracle.apps.xxcrm.ar.hz.components.address.webui");

}
