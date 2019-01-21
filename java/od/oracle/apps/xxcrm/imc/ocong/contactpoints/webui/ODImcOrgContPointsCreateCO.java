/*==============================================================================+
 |      Copyright (c) 2001 Oracle Corporation, Redwood Shores, CA, USA          |
 |                         All rights reserved.                                 |
 +==============================================================================+
 |  HISTORY                                                                     |
 |  Date           Authors            Remarks                                   |
 |  12-Aug-2013    Darshini           I2186 - Modified for R12 Upgrade Retrofit |
 +==============================================================================*/
package od.oracle.apps.xxcrm.imc.ocong.contactpoints.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.cabo.ui.data.DictionaryData;
import oracle.jbo.common.Diagnostic;
import com.sun.java.util.collections.HashMap;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.imc.ocong.util.webui.ImcUtilPkg;
import oracle.apps.imc.ocong.contactpoints.webui.ImcOrgContPointsCreateCO;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.layout.OADefaultSingleColumnBean;
/*Commented and added by Darshini for R12 Upgrade Retrofit
import oracle.jdbc.driver.OracleCallableStatement;*/
import oracle.jdbc.OracleCallableStatement;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;
import java.sql.ResultSet;
import oracle.jdbc.OracleResultSet;

/**
 * Controller for ...
 */
public class ODImcOrgContPointsCreateCO extends ImcOrgContPointsCreateCO
{
  public static final String RCS_ID="$Header: ODImcOrgContPointsCreateCO.java 115.6 2011/12/15 23:29:28 ssilveri noship $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "od.oracle.apps.xxcrm.imc.ocong.contactpoints.webui");

  /**
   * Layout and page setup logic for AK region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
	  pageContext.writeDiagnostics(METHOD_NAME, "ODImcOrgContPointsCreateCO->processRequest. start ", OAFwkConstants.PROCEDURE);
    super.processRequest(pageContext, webBean);    
    //oracle.apps.imc.ocong.util.webui.ImcUtilPkg.debugPageContext(pageContext, "ODImcOrgContPointsCreateCO -> ProcessRequest");
	OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);
	int cCount = 0;
	String sImcGenPartyId    = pageContext.getParameter("ImcGenPartyId");
	String contactPointID    = pageContext.getParameter("ImcContactPointId");
	pageContext.writeDiagnostics(METHOD_NAME, "ODImcOrgContPointsCreateCO->processRequest. contactPointID= "+contactPointID, OAFwkConstants.PROCEDURE);
	String query = 
			"select count(1) CNT from hz_contact_points "
			+"where owner_table_name='HZ_PARTIES' "
			+"and status='A' "
			+"and contact_point_type='EMAIL' "
			+"and contact_point_purpose = 'BILLING' "
			+"and owner_table_id= "+ sImcGenPartyId;
	
    try
        {
		
           OracleCallableStatement actCall = (OracleCallableStatement)am.getOADBTransaction().createCallableStatement(query, -1);
           ResultSet actRS = (OracleResultSet) actCall.executeQuery();

           while(actRS.next())
           {
              cCount = actRS.getInt("CNT");
           }
           actRS.close();
           actCall.close();
        }
        catch(Exception e)
        {
            pageContext.writeDiagnostics(METHOD_NAME, "ODImcOrgContPointsCreateCO->processRequest. Exception: "+e.getMessage(), OAFwkConstants.PROCEDURE);
        }
	String query2 = 
			"select * from hz_contact_points "
			+"where contact_point_id= "+ contactPointID;
			String cnt_purpose = null;
			String cnt_status = null;
    try
        {
		
           OracleCallableStatement actCall = (OracleCallableStatement)am.getOADBTransaction().createCallableStatement(query2, -1);
           ResultSet actRS = (OracleResultSet) actCall.executeQuery();

           if(actRS.next())
           {
              cnt_purpose = actRS.getString("CONTACT_POINT_PURPOSE");
			  cnt_status = actRS.getString("STATUS");
           }
           actRS.close();
           actCall.close();
        }
        catch(Exception e)
        {
            pageContext.writeDiagnostics(METHOD_NAME, "ODImcOrgContPointsCreateCO->processRequest. Exception: "+e.getMessage(), OAFwkConstants.PROCEDURE);
        }
	OADefaultSingleColumnBean  hzPuiContactPointEmailRN = (OADefaultSingleColumnBean) webBean.findChildRecursive("region2");
	if(hzPuiContactPointEmailRN != null && cCount == 1){
	OAMessageChoiceBean contactPointPurpose = (OAMessageChoiceBean)hzPuiContactPointEmailRN.findChildRecursive("EmContactPointPurpose");
	if(contactPointPurpose != null){
		if("BILLING".equals(cnt_purpose) && "A".equals(cnt_status))
		contactPointPurpose.setReadOnly(true);
	}
    OAMessageChoiceBean emStatus = (OAMessageChoiceBean)hzPuiContactPointEmailRN.findChildRecursive("EmStatus");
	if(emStatus != null){
		if("BILLING".equals(cnt_purpose) && "A".equals(cnt_status))
			emStatus.setReadOnly(true);
		//pageContext.writeDiagnostics(METHOD_NAME, "ODImcOrgContPointsCreateCO->processRequest. emStatus = " + emStatus.getText(pageContext), OAFwkConstants.PROCEDURE);
		
	}
    pageContext.writeDiagnostics(METHOD_NAME, "ODImcOrgContPointsCreateCO->processRequest. hzPuiContactPointEmailRN = " + hzPuiContactPointEmailRN, OAFwkConstants.PROCEDURE);
	}
	pageContext.writeDiagnostics(METHOD_NAME, "ODImcOrgContPointsCreateCO->processRequest. end ", OAFwkConstants.PROCEDURE);
  }

  /**
   * Procedure to handle form submissions for form elements in
   * AK region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
	final String METHOD_NAME = "od.oracle.apps.xxcrm.ar.hz.components.contactpoints.webui.ODImcOrgContPointsCreateCO.processFormRequest";   

    oracle.apps.imc.ocong.util.webui.ImcUtilPkg.debugPageContext(pageContext, "ODImcOrgContPointsCreateCO -> ProcessFormRequest");    
	super.processFormRequest(pageContext, webBean);
    pageContext.writeDiagnostics(METHOD_NAME, "ODImcOrgContPointsCreateCO->processFormRequest. end", OAFwkConstants.PROCEDURE);
  }

}

