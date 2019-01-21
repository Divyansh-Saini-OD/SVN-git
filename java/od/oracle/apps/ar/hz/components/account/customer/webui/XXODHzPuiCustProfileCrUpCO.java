/*-- +===================================================================================+
#-- |                           Oracle GSD                                              |
#-- +===================================================================================+
#-- |                                                                                   |
#-- |                                                                                   |
#-- |File Name : XXODHzPuiCustProfileCrUpCO.java                                        |
#-- |                                                                                   |
#-- |                                                                                   |
#-- |                                                                                   |
#-- |Change Record:                                                                     |
#-- |===============                                                                    |
#-- |Version   Date         Author            	Remarks                                 |
#-- |=======   ==========   ==============     	==========================              |
#-- |  1.0     30-SEP-2013  Darshini            Initial Version                         |
#-- |  2.0     1-SEP-2015   Sridevi K           For MOD5 Changes                        |
#-- +===================================================================================+*/
package od.oracle.apps.ar.hz.components.account.customer.webui;


import oracle.apps.ar.hz.components.account.customer.server.HzPuiCustActAMImpl;
import oracle.apps.ar.hz.components.account.customer.webui.HzPuiCustProfileCrUpCO;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.beans.layout.OARowLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageCheckBoxBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.OAApplicationModule;

import oracle.jbo.Row;


public class XXODHzPuiCustProfileCrUpCO extends HzPuiCustProfileCrUpCO {
    public void processRequest(OAPageContext pageContext, OAWebBean webBean) {
        super.processRequest(pageContext, webBean);
       

        String custAcctId = pageContext.getParameter("AcctId");
        pageContext.writeDiagnostics(this, "XXOD: **custAcctId:" + custAcctId, 
                                     1);

        String custAcctSiteId = pageContext.getParameter("AcctSiteId");
        pageContext.writeDiagnostics(this, 
                                     "XXOD: **custAcctSiteId:" + custAcctSiteId, 
                                     1);

        OAApplicationModule am = pageContext.getRootApplicationModule();

        OAApplicationModule hzPuiCustActAM = 
            (OAApplicationModule)am.findApplicationModule("HzPuiCustActAM");


        //For getting handle to HzPuiCustProfileDisplayPVO
        OAViewObject custProfilePVO = 
            (OAViewObject)hzPuiCustActAM.findViewObject("HzPuiCustProfileDisplayPVO");

        if (custProfilePVO != null) {


            Row row = custProfilePVO.getCurrentRow();
            if (custAcctSiteId == null) {

                row.setAttribute("StmtsAccount", Boolean.TRUE);
            } else {
                row.setAttribute("StmtsAccount", Boolean.FALSE);

            }

            pageContext.writeDiagnostics(this, 
                                         "XXOD: after setting stmtsAccount" + 
                                         row.getAttribute("StmtsAccount").toString(), 
                                         1);

        }


    }
}
