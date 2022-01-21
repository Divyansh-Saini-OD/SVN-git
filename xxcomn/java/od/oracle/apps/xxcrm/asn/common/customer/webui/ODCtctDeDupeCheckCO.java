/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODCtctDeDupeCheckCO.java                                      |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Controller Object for the Contact Duplicate Check Region               |
 |                                                                           |
 |  NOTES                                                                    |
 |         Used for the Customization on the Create Contact Page             |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    No dependencies.                                                       |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    27-Sep-2007 Jasmine Sujithra   Created                                 |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.common.customer.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.asn.common.fwk.webui.ASNControllerObjectImpl;
import com.sun.java.util.collections.HashMap;
import oracle.apps.fnd.framework.OAFwkConstants;
import java.util.Vector;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.ar.hz.components.util.server.HzPuiServerUtil;
import oracle.apps.asn.common.fwk.webui.ASNUIConstants;
import java.io.Serializable;


/**
 * Controller for ...
 */
public class ODCtctDeDupeCheckCO extends ASNControllerObjectImpl
{
  public static final String RCS_ID="$Header: /home/cvs/repository/Office_Depot/SRC/CRM/E1307_SiteLevel_Attributes_ASN/3.\040Source\040Code\040&\040Install\040Files/E1307D_SiteLevel_Attributes_(LeadOpp_CreateUpdate)/ODCtctDeDupeCheckCO.java,v 1.2 2007/10/11 20:59:38 jsujithra Exp $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
   final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODCtctDeDupeCheckCO.processRequest";

    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);

    if (isProcLogEnabled)
    {
        pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }
    super.processRequest(pageContext, webBean);


    OAApplicationModule am = (OAApplicationModule)pageContext.getRootApplicationModule();
    boolean duplicateExist = false;
    String fromLOV = pageContext.getParameter("ASNReqFromLOVPage");
    String relPartyId = null;
	  String relId = null;
	  String objPartyId = pageContext.getParameter("ASNReqFrmCustId");
    String subPartyId = null;

    duplicateExist =  HzPuiServerUtil.checkContactDuplicates(am.getOADBTransaction(), am);

    if (isStatLogEnabled) {
        pageContext.writeDiagnostics(METHOD_NAME, "Duplicate exist: " + (duplicateExist ? "true" : "false"), OAFwkConstants.STATEMENT);
    }

    if (!duplicateExist)
    {
        pageContext.writeDiagnostics(METHOD_NAME, "Inside duplicateExist is false ", OAFwkConstants.PROCEDURE);
        Vector tempData = HzPuiServerUtil.getContactRelRecord((pageContext.getApplicationModule(webBean)).getOADBTransaction());
        if ( tempData != null ) {
            if (isStatLogEnabled) {
                pageContext.writeDiagnostics(METHOD_NAME, "contact Vector Found = " + tempData.toString(), OAFwkConstants.STATEMENT);
            }
            HashMap hTemp = (HashMap)tempData.elementAt(0);
            relPartyId = hTemp.get("RelationshipPartyId").toString();
            relId = hTemp.get("PartyRelationshipId").toString();
            objPartyId = hTemp.get("ObjectId").toString();
            subPartyId = hTemp.get("SubjectId").toString();
            if (isStatLogEnabled)    {
                StringBuffer buf = new StringBuffer();
                buf.append("relPartyId = ");
                buf.append(relPartyId);
                buf.append("relId = ");
                buf.append(relId);
                buf.append("objPartyId = ");
                buf.append(objPartyId);
                buf.append("subPartyId = ");
                buf.append(subPartyId);
                pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
            }

        }

        // Begin Mod Raam on 06.13.2006
        // Get the customer location id from transaction persisted by create
        // contact page.
        String selLocId = (String) pageContext.getTransactionValue("ASNTxnSelLocationId");
         pageContext.writeDiagnostics(METHOD_NAME, "ASNTxnSelLocationId : "+selLocId, OAFwkConstants.PROCEDURE);
        if (isProcLogEnabled)
        {
          StringBuffer logMsg = new StringBuffer(100);
          logMsg.append("User selected location in transaction is = ");
          logMsg.append(selLocId);
          pageContext.writeDiagnostics(METHOD_NAME, logMsg.toString(), OAFwkConstants.PROCEDURE);
        }

          /* Commented out the creation of a Party Site 
        if (selLocId != null && relPartyId != null)
        {
          Serializable[] parameters =  { relPartyId, selLocId };
          am.invokeMethod("createPartySite", parameters);
        }*/
        // End Mod. 

      


        /*Added Custom Code to Check for existing Party Site Contact */
                
        String partySiteId = pageContext.getParameter("ASNReqFrmSiteId"); 
        if (partySiteId == null)
        {
             partySiteId = (String)pageContext.getTransactionValue("ASNReqFrmSiteIdTXN");
        }
        Serializable [] extparameters = { partySiteId,relId};        
        pageContext.writeDiagnostics(METHOD_NAME, "Inside ASNPageSelBtn event ", 2);                     
        pageContext.writeDiagnostics(METHOD_NAME, "Party Site Id", 2);
        pageContext.writeDiagnostics(METHOD_NAME, partySiteId, 2);                      
        am.invokeMethod("insertRecords", extparameters);
        /* End Custom Code */

        //set retainAM = false as we have commited the transaction
        am.invokeMethod("commitTransaction");

        if(pageContext.getParameter("ASNReqFromLOVPage") != null)
        {
            if (isStatLogEnabled) {
                pageContext.writeDiagnostics(METHOD_NAME, "ASNReqFromLOVpage = " + fromLOV, OAFwkConstants.STATEMENT);
            }
           // pageContext.putParameter("ASNReqSelCustId",   objPartyId);
            pageContext.putParameter("ASNReqSelCtctId",   subPartyId);
            pageContext.putParameter("ASNReqSelRelPtyId", relPartyId);
            pageContext.putParameter("ASNReqSelRelId",    relId);
            Serializable[] parameters =  { subPartyId };
	          String ctctPartyName = (String) am.invokeMethod("getPartyNameFromId", parameters);
            pageContext.putParameter("ASNReqSelCtctName",   ctctPartyName);
            pageContext.releaseRootApplicationModule();
       			HashMap conditions = new HashMap();
			      conditions.put(ASNUIConstants.RETAIN_AM, "Y");
			      this.processTargetURL(pageContext,conditions,null);
	       }else{
			      this.processTargetURL(pageContext,null,null);
         }
    }
    if (isProcLogEnabled) {
        pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }
  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODCtctDeDupeCheckCO.processFormRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    if (isProcLogEnabled) {
        pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processFormRequest(pageContext, webBean);

    if (isProcLogEnabled) {
        pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }
  
  }

}
