/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODCtctWarningCO.java                                           |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Controller Object for the Contact Warning Page.                         |
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
import java.util.Vector;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.ar.hz.components.util.server.HzPuiServerUtil;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.asn.common.fwk.webui.ASNUIConstants;
import java.io.Serializable;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.layout.OATableLayoutBean;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAViewObject;


/**
 * Controller for ...
 */
public class ODCtctWarningCO extends ASNControllerObjectImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODCtctWarningCO.processRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processRequest(pageContext, webBean);
    // Diagnostic.println("----------------->CtctWarningCO: processRequest() begin");
    //disable the breadcrumbs
    ((OAPageLayoutBean) webBean).setBreadCrumbEnabled(false);
    //If it is a subflow page, need to retain context parameters here
	  retainContextParameters(pageContext);
    // Diagnostic.println("----------------->CtctWarningCO: ASNReqFromLOVPage =" + pageContext.getParameter("ASNReqFromLOVPage"));
    // Diagnostic.println("----------------->CtctWarningCO: processRequest() end");

    //hide the un-supported items in the tca components that should not be personalized by the user
    //dqm search results section
    OATableLayoutBean asnCtctDQMSearchResultsRN = (OATableLayoutBean) webBean.findChildRecursive("ASNCtctDQMSearchResultsRN");
    if(asnCtctDQMSearchResultsRN != null){
      //hide the create contact button
      OASubmitButtonBean hzPuiCreateContactButton=  (OASubmitButtonBean)asnCtctDQMSearchResultsRN.findChildRecursive("HzPuiCreateContact");
      if(hzPuiCreateContactButton != null){
        hzPuiCreateContactButton.setRendered(false);
      }
    }
    //dqm search results section
    //end of hiding the un-supported items in tca components that should not be personalizable

    if (isProcLogEnabled)
    {
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
  final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODCtctWarningCO.processFormRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    if (isProcLogEnabled)
    {
    pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processFormRequest(pageContext, webBean);
    // Diagnostic.println("----------------->CtctWarningCO: processFormRequest() begin");

    OAApplicationModule am = (OAApplicationModule)pageContext.getRootApplicationModule();

    String fromLOV = pageContext.getParameter("ASNReqFromLOVPage");
    String orgPartyId = pageContext.getParameter("HzPuiContactObjectId");
    
    String relPartyId = null;
	  String relId = null;
	  String objPartyId = pageContext.getParameter("ASNReqFrmCustId");
    String subPartyId = null;

    HashMap params = new HashMap();


    //If the user clicked on the Use Existing Button
    if (pageContext.getParameter("HzPuiSelectExistingContact") != null)  
    {
        // Diagnostic.println("----------------->CtctWarningCO processFormRequest. HzPuiSelectExistingContact Selected ");
        Vector selectedContacts = HzPuiServerUtil.getSelectedContacts(pageContext.getRootApplicationModule(), 1);
        if ( selectedContacts != null && selectedContacts.size() > 0) 
        {
            HashMap hTemp = (HashMap)selectedContacts.elementAt(0);
            relPartyId = (String)hTemp.get("RelationshipPartyId");
            relId = (String)hTemp.get("RelationshipId");
            subPartyId = (String)hTemp.get("PersonPartyId");
            /*
            Diagnostic.println("relPartyId = " + relPartyId);
            Diagnostic.println("relId = " + relId);
            Diagnostic.println("objPartyId = " + objPartyId);
            Diagnostic.println("subPartyId = " + subPartyId);
            */

            
            /* Custom Code to insert the association between the contact and Party site 
             * into the Extensible Attribute Group */
            am.invokeMethod("cancelTransaction");
            String partySiteId = pageContext.getParameter("ASNReqFrmSiteId"); 
             if (partySiteId == null)
             {
                 partySiteId = (String)pageContext.getTransactionValue("ASNReqFrmSiteIdTXN");
             }
              pageContext.writeDiagnostics(METHOD_NAME, "Use Existing party site id :"+partySiteId , 2);
              pageContext.writeDiagnostics(METHOD_NAME, "Use Existing Relationship id :"+relId , 2);

              OAViewObject partysiterelationshipvo = (OAViewObject)am.findViewObject("ODPartySiteExtRelationshipVO");
              
              if (partysiterelationshipvo == null) 
              {
                      MessageToken[] token = 
                      { new MessageToken("OBJECT_NAME", "ODPartySiteExtRelationshipVO") };
                      throw new OAException("AK", "FWK_TBX_OBJECT_NOT_FOUND", token);
              }

              Serializable[] relparams = { partySiteId,relId };
              partysiterelationshipvo.invokeMethod("initQuery", relparams);

              int recordcount = partysiterelationshipvo.getRowCount();

                   
              if ( recordcount > 0)
              {
                         pageContext.writeDiagnostics(METHOD_NAME, "Relationship exists ..display error " , 2);
                        Serializable[] parameters =  { partySiteId };   
                        String partySiteAddr = (String) am.invokeMethod("getPartySiteAddr", parameters);
                        Serializable[] contactparameters =  { subPartyId };  
                        String contactName = (String) am.invokeMethod("getPartyNameFromId", contactparameters);//"Jasmine Test";
    
                        MessageToken[] tokens = { new MessageToken("NAME", contactName), new MessageToken("ADDRESS", partySiteAddr)};
                        throw new OAException("XXCRM", "XX_SFA_055_DUPLICATE_SITE_CTCT", tokens);
              }
              else
              {
                        pageContext.writeDiagnostics(METHOD_NAME, "Relationship doesn't exist ..create record " , 2);
                        Serializable [] parameters = { partySiteId,relId};        
                        pageContext.writeDiagnostics(METHOD_NAME, "Inside ASNPageSelBtn event ", 2);                     
                        pageContext.writeDiagnostics(METHOD_NAME, "Party Site Id", 2);
                        pageContext.writeDiagnostics(METHOD_NAME, partySiteId, 2);                      
                        am.invokeMethod("insertRecords", parameters);
                        am.invokeMethod("applyTransaction");
        
              }

        }
        else
        {
           OAException e = new OAException("ASN", "ASN_CMMN_RADIO_MISS_ERR");
           pageContext.putDialogMessage(e);
        }
        if(pageContext.getParameter("ASNReqFromLOVPage") != null)
        {
            // Diagnostic.println("----------------->CtctWarningCO: processFormRequest() ASNReqFromLOVpage = " + fromLOV);
            //pageContext.putParameter("ASNReqSelCustId",   objPartyId);
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
		    }else
        {
			      this.processTargetURL(pageContext,null,null);
        }
    }   //If the user clicked on create?
    else if( pageContext.getParameter("HzPuiPersonCreate") != null )
    {
       // Diagnostic.println("----------------->CtctWarningCO processFormRequest. HzPuiCtctCreate Selected ");
       Vector tempData = oracle.apps.ar.hz.components.util.server.HzPuiServerUtil.getContactRelRecord((pageContext.getApplicationModule(webBean)).getOADBTransaction());
       if ( tempData != null ) {
            // Diagnostic.println("contact Vector Found = " + tempData.toString() );
            HashMap hTemp = (HashMap)tempData.elementAt(0);
            relPartyId = hTemp.get("RelationshipPartyId").toString();
            relId = hTemp.get("PartyRelationshipId").toString();
            objPartyId = hTemp.get("ObjectId").toString();
            subPartyId = hTemp.get("SubjectId").toString();
            /*
            Diagnostic.println("relPartyId = " + relPartyId);
            Diagnostic.println("relId = " + relId);
            Diagnostic.println("objPartyId = " + objPartyId);
            Diagnostic.println("subPartyId = " + subPartyId);
            */
        }

        // Begin Mod Raam on 06.13.2006
        // Get the customer location id from transaction persisted by create
        // contact page.
        String selLocId = (String)pageContext.getTransactionValue("ASNTxnSelLocationId");
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

        /* Custom Code to insert the association between the contact and Party site 
         * into the Extensible Attribute Group */
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
            // Diagnostic.println("----------------->CtctWarningCO: processFormRequest() ASNReqFromLOVpage = " + fromLOV);
            //pageContext.putParameter("ASNReqSelCustId",   objPartyId);
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
    else if(pageContext.getParameter("ASNPageCnclBtn") != null)
    {
         // Diagnostic.println("----------------->CtctWarningCO processFormRequest. Cancel Button clicked");
         if(pageContext.getParameter("ASNReqFromLOVPage") != null) {
	          // Diagnostic.println("----------------->CtctWarningCO processFormRequest.ASNReqFromLOVPage = " + fromLOV);
			      HashMap conditions = new HashMap();
            conditions.put(ASNUIConstants.RETAIN_AM, "Y");
            pageContext.releaseRootApplicationModule();
            this.processTargetURL(pageContext,conditions,null);
         }else {
           this.processTargetURL(pageContext,null,null);
         }
    }
    else if ((pageContext.getParameter("HzPuiContactLOVEvent") != null) && (pageContext.getParameter("HzPuiContactLOVEvent").equals("PERSONDETAIL")))
    {
        // Diagnostic.println("----------------->CtctWarningCO processFormRequest. Go to Contact View page");
        params.put("ASNReqFrmCustId", pageContext.getParameter("ASNReqFrmCustId"));
        params.put("ASNReqFrmCustName", pageContext.getParameter("ASNReqFrmCustName"));
        params.put("ASNReqFrmCtctId", pageContext.getParameter("HzPuiPersonPartyId"));
        params.put("ASNReqFrmCtctName", pageContext.getParameter("HzPuiPersonPartyName"));
        params.put("ASNReqFrmRelPtyId", pageContext.getParameter("HzPuiRelParyId"));
        params.put("ASNReqFrmRelId", pageContext.getParameter("HzPuiRelationshipId"));
        pageContext.putParameter("ASNReqPgAct","CTCTDET");
        this.processTargetURL(pageContext,null,params);
    }

    if (isProcLogEnabled)
    {
    pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }


  }

}
