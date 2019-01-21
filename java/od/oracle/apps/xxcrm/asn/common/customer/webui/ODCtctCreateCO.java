/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODCtctCreateCO.java                                           |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Controller Object for the Create Contact Page.                         |
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
 |    17-Jan-2008 Jasmine Sujithra   Test for TSI                            |
 |    17-Jan-2008 Jasmine Sujithra   Override DQM                            |
 |    22-Apr-2010 Devi               For eBilling                            |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.common.customer.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAFwkConstants;

import oracle.apps.fnd.framework.webui.beans.OABodyBean;
import oracle.apps.asn.common.fwk.webui.ASNControllerObjectImpl;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.asn.common.fwk.webui.ASNUIConstants;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageCheckBoxBean;
import com.sun.java.util.collections.HashMap;
import java.util.Vector;
import java.io.Serializable;
import oracle.jbo.Transaction;

import od.oracle.apps.xxcrm.cdh.ebl.server.ODUtil;

import oracle.apps.fnd.framework.server.OADBTransactionImpl;
import oracle.jdbc.OracleCallableStatement;
import oracle.jbo.domain.Number;
import java.sql.Types;
import java.sql.SQLException;



/**
 * Controller for ...
 */
public class ODCtctCreateCO extends ASNControllerObjectImpl 
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
    final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODCtctCreateCO.processRequest";

	   boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
	   boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);
        
	   if (isProcLogEnabled) {
       pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
     }
     pageContext.putParameter("HzPuiMatchOptionDisplay","AND");
     super.processRequest(pageContext, webBean);


      // - Multiple clicks - fix
     OAWebBean bodyBean = pageContext.getRootWebBean();
     if (bodyBean != null && bodyBean instanceof OABodyBean)
	{
       ((OABodyBean)bodyBean).setBlockOnEverySubmit(true);
     }

     String fromLOVPage = pageContext.getParameter("ASNReqFromLOVPage");

      //disable the breadcrumbs
     ((OAPageLayoutBean)webBean).setBreadCrumbEnabled(false);
     //If it is a subflow page, need to retain context parameters here
     retainContextParameters(pageContext);

     String orgPartyId = pageContext.getParameter("ASNReqFrmCustId");
     if (orgPartyId == null) {
       OAException e = new OAException("ASN", "ASN_TCA_CUSTPARAM_MISS_ERR");
       pageContext.putDialogMessage(e);
     }else{
       pageContext.putParameter("HzPuiPerProfileObjectId", orgPartyId);
       pageContext.putParameter("ObjectId", orgPartyId);
       String orgPartyName = pageContext.getParameter("ASNReqFrmCustName");
       if (orgPartyName == null)
	     {
         OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);
         Serializable[] parameters = { orgPartyId };
         orgPartyName = (String)am.invokeMethod("getPartyNameFromId", parameters);

       }
       MessageToken[] tokens = { new MessageToken("PARTYNAME", orgPartyName) };
       String pageTitle = pageContext.getMessage("ASN", "ASN_TCA_CRTE_CTCT_TITLE", tokens);
       // Set the page title (which also appears in the breadcrumbs)
       ((OAPageLayoutBean)webBean).setTitle(pageTitle);

     }

     // Begin Mod Raam on 06.13.2006
     // Changes to implement sharing location

     // Get the selected address returned by PtyAddrSelCO
     String selLocId = pageContext.getParameter("ASNReqSelLocationId");
     String selAddress = pageContext.getParameter("ASNReqSelAddress");

     if (selLocId != null && selAddress != null)
     // When user has selected a customer address
     {
       // Copy the selected address info into txn since user may navigate
       // to global pages. These values should be retained even then.
       pageContext.putTransactionValue("ASNTxnSelLocationId", selLocId);
       pageContext.putTransactionValue("ASNTxnSelAddress", selAddress);
       if (isStatLogEnabled)
	     {
        StringBuffer buf = new StringBuffer(250);
         buf.append("  Selected Location ID= ");
         buf.append(selLocId);
         buf.append("  Selected Address = ");
         buf.append(selAddress);
         buf.append("  Before setting selected address in page beans. ");
         pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
               
       }
     } 
	else
     // Get selected a customer address from txn
     {
       selLocId = (String)pageContext.getTransactionValue("ASNTxnSelLocationId");
       selAddress = (String)pageContext.getTransactionValue("ASNTxnSelAddress");
     }

     // Check transaction parameter to see if user is returning from address
     // selection flow. If so, set specific CPUI parameter.
     if ("Y".equals(pageContext.getTransactionValue("ASNTxnAddrSelFlow")))
	{
       if (isProcLogEnabled) 
	  {
         pageContext.writeDiagnostics(METHOD_NAME, "AM already exists. Setting CPUI parameter HzPuiPersonCompositeExist to avoid creating new row.", OAFwkConstants.PROCEDURE);
       }

       // Following CPUI parameter should be placed in context when returning from
       // address selection page to indicate TCA to avoid inserting a new row into the VO.
       // This is to avoid bug 5246947
       pageContext.putParameter("HzPuiPersonCompositeExist", "YES");

       // Remove the parameter from transaction since user returned from the flow.
       pageContext.removeTransactionValue("ASNTxnAddrSelFlow");
     }

     if (selLocId != null && selAddress != null)
     // When user selected customer address is available
     {
       // Copy user selected address into address text item.
       OAHeaderBean selAddrHdr = (OAHeaderBean)webBean.findChildRecursive("ASNCtctSelectRN");
       if (selAddrHdr != null)
	  {
         OAMessageTextInputBean selAddrItem = (OAMessageTextInputBean)selAddrHdr.findChildRecursive("ASNCtctSelAddr");
         selAddrItem.setText(selAddress);
       }

       if (isStatLogEnabled)
	  {
         StringBuffer buf = new StringBuffer(300);
         buf.append("  After setting selected address in page beans. ");
         pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
       }
     }
     // End Mod.

     

     if (isStatLogEnabled) {
        pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.STATEMENT);
      }

  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  
  

   /**
   * Procedure to handle form submissions for form elements in
   * AK region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    ODUtil utl = new ODUtil(pageContext.getApplicationModule(webBean));
    utl.log("Inside PFR ODCtctCreateCO:ASNPageApyBtn "  ); 
  
    final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODCtctCreateCO.processFormRequest";

    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);

    if (isProcLogEnabled) {
        pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }
    super.processFormRequest(pageContext, webBean);


    String fromLOV = pageContext.getParameter("ASNReqFromLOVPage");
        String relPartyId = null;
        String relId = null;
        String objPartyId = null;
        String subPartyId = null;

        HashMap params = new HashMap();

        OAApplicationModule rootAm = 
            (OAApplicationModule)pageContext.getRootApplicationModule();

        if (pageContext.getParameter("ASNPageCnclBtn") != null) {
            if (isStatLogEnabled) {
                pageContext.writeDiagnostics(METHOD_NAME, "Cancel pressed", 
                                             OAFwkConstants.STATEMENT);
            }
            if (pageContext.getParameter("ASNReqFromLOVPage") != null) {
                if (isStatLogEnabled) {
                    pageContext.writeDiagnostics(METHOD_NAME, 
                                                 "ASNReqFromLOVPage = " + 
                                                 fromLOV, 
                                                 OAFwkConstants.STATEMENT);
                }
                pageContext.releaseRootApplicationModule();
                HashMap conditions = new HashMap();
                conditions.put(ASNUIConstants.RETAIN_AM, "Y");
                this.processTargetURL(pageContext, conditions, null);
            } else {
                this.processTargetURL(pageContext, null, null);
            }
        } //end of cancel button pressed
        else if (pageContext.getParameter("ASNPageApyBtn") != null) {

            utl.log("Inside PFR ODCtctCreateCO:ASNPageApyBtn"); 

            
            if (isStatLogEnabled) {
                pageContext.writeDiagnostics(METHOD_NAME, "Apply pressed", 
                                             OAFwkConstants.STATEMENT);
            }

            //Rramchan enhancement for Create Contact (Duplicate Preven Flow)

            //Put the Organisation Party Id in the URL parameters, we need it to make the query

            String ASNOrgPartyId = pageContext.getParameter("ASNReqFrmCustId");

            if (ASNOrgPartyId != null) {
                if (isStatLogEnabled) {
                    pageContext.writeDiagnostics(METHOD_NAME, 
                                                 "ASNOrgPartyId is :" + 
                                                 ASNOrgPartyId, 
                                                 OAFwkConstants.STATEMENT);


                }
                params.put("ASNOrgPartyId", ASNOrgPartyId);
            }


            Transaction tx = 
                (pageContext.getApplicationModule(webBean)).getTransaction();
            tx.validate();
            //Check the ASN profile to see whether the profile for org de-dupe check is turned on.
            String valueDQMProfile = 
                (String)pageContext.getProfile("HZ_DQM_ENABLED_FLAG");
            if ("NO".equals(valueDQMProfile)) { //start of dql not enabled
                utl.log("Inside PFR ODCtctCreateCO:ASNPageApyBtn: DQM No:valueDQMProfile:" + valueDQMProfile);            
                if (isStatLogEnabled) {
                    pageContext.writeDiagnostics(METHOD_NAME, 
                                                 "DQM Disabled, so commit", 
                                                 OAFwkConstants.STATEMENT);
                }
                //Commit the transaction
                rootAm.invokeMethod("commitTransaction");
                Vector tempData = 
                    oracle.apps.ar.hz.components.util.server.HzPuiServerUtil.getContactRelRecord((pageContext.getApplicationModule(webBean)).getOADBTransaction());
                if (tempData != null) {
                    if (isStatLogEnabled) {
                        pageContext.writeDiagnostics(METHOD_NAME, 
                                                     "contact Vector Found = " + 
                                                     tempData.toString(), 
                                                     OAFwkConstants.STATEMENT);
                    }
                    HashMap hTemp = (HashMap)tempData.elementAt(0);
                    relPartyId = hTemp.get("RelationshipPartyId").toString();
                    relId = hTemp.get("PartyRelationshipId").toString();
                    objPartyId = hTemp.get("ObjectId").toString();
                    subPartyId = hTemp.get("SubjectId").toString();
                    if (isStatLogEnabled) {
                        StringBuffer buf = new StringBuffer();
                        buf.append("relPartyId = ");
                        buf.append(relPartyId);
                        buf.append("relId = ");
                        buf.append(relId);
                        buf.append("objPartyId = ");
                        buf.append(objPartyId);
                        buf.append("subPartyId = ");
                        buf.append(subPartyId);
                        pageContext.writeDiagnostics(METHOD_NAME, 
                                                     buf.toString(), 
                                                     OAFwkConstants.STATEMENT);
                    }
                }
                /* Code Added for eBilling page to make contact resposibility type as BILLING */
                setBillingPurpose( pageContext, webBean, relPartyId);
                /* End - Code Added for eBilling page to make contact resposibility type as BILLING */                 
                if (pageContext.getParameter("ASNReqFromLOVPage") != null) {
                    if (isStatLogEnabled) {
                        pageContext.writeDiagnostics(METHOD_NAME, 
                                                     "ASNReqFromLOVPage = " + 
                                                     fromLOV, 
                                                     OAFwkConstants.STATEMENT);
                    } //pageContext.putParameter("ASNReqSelCustId",   objPartyId);
                    pageContext.putParameter("ASNReqSelCtctId", subPartyId);
                    pageContext.putParameter("ASNReqSelRelPtyId", relPartyId);
                    pageContext.putParameter("ASNReqSelRelId", relId);
                    Serializable[] parameters = { subPartyId };
                    String ctctPartyName = 
                        (String)rootAm.invokeMethod("getPartyNameFromId", 
                                                    parameters);
                    pageContext.putParameter("ASNReqSelCtctName", 
                                             ctctPartyName);
                    pageContext.releaseRootApplicationModule();
                    HashMap conditions = new HashMap();
                    conditions.put(ASNUIConstants.RETAIN_AM, "Y");
                    this.processTargetURL(pageContext, conditions, null);
                } else {
                    this.processTargetURL(pageContext, null, null);
                }
                 
            } //end of dqm not enabled
            else { //start of dqm enabled
                utl.log("Inside PFR ODCtctCreateCO:ASNPageApyBtn: DQM Yes:valueDQMProfile:" + valueDQMProfile);                        
if (isStatLogEnabled) {
                    pageContext.writeDiagnostics(METHOD_NAME, 
                                                 "DQM Enabled, but avoiding Contact search, so commit", 
                                                 OAFwkConstants.STATEMENT);
                }


                Vector tempData = 
                    oracle.apps.ar.hz.components.util.server.HzPuiServerUtil.getContactRelRecord((pageContext.getApplicationModule(webBean)).getOADBTransaction());
                if (tempData != null) {
                    if (isStatLogEnabled) {
                        pageContext.writeDiagnostics(METHOD_NAME, 
                                                     "contact Vector Found = " + 
                                                     tempData.toString(), 
                                                     OAFwkConstants.STATEMENT);
                    }
                    HashMap hTemp = (HashMap)tempData.elementAt(0);
                    relPartyId = hTemp.get("RelationshipPartyId").toString();
                    relId = hTemp.get("PartyRelationshipId").toString();
                    objPartyId = hTemp.get("ObjectId").toString();
                    subPartyId = hTemp.get("SubjectId").toString();
                    if (isStatLogEnabled) {
                        StringBuffer buf = new StringBuffer();
                        buf.append("relPartyId = ");
                        buf.append(relPartyId);
                        buf.append("relId = ");
                        buf.append(relId);
                        buf.append("objPartyId = ");
                        buf.append(objPartyId);
                        buf.append("subPartyId = ");
                        buf.append(subPartyId);
                        pageContext.writeDiagnostics(METHOD_NAME, 
                                                     buf.toString(), 
                                                     OAFwkConstants.STATEMENT);
                    }
                }
                  /*Added Custom Code to Insert a party site association in the Extensible attributes */
                
        //String partySiteId = pageContext.getParameter("ASNReqFrmSiteId"); 
        //if (partySiteId == null)
        //{
             //pageContext.writeDiagnostics(METHOD_NAME, "ASNReqFrmSiteId is null hence taking value of ASNReqFrmSiteIdTXN  ", 2);
             String partySiteId = (String)pageContext.getTransactionValue("ASNReqFrmSiteIdTXN");
        //}
        pageContext.writeDiagnostics(METHOD_NAME, "ASNReqFrmSiteIdTXN is :  "+ pageContext.getTransactionValue("ASNReqFrmSiteIdTXN"), 2);
        Serializable [] extparameters = { partySiteId,relId};        
        pageContext.writeDiagnostics(METHOD_NAME, "Inside ASNPageSelBtn event ", 2);                     
        pageContext.writeDiagnostics(METHOD_NAME, "Party Site Id", 2);
        pageContext.writeDiagnostics(METHOD_NAME, partySiteId, 2);                      
        rootAm.invokeMethod("insertRecords", extparameters);
        /* End Custom Code */
                //Commit the transaction
                rootAm.invokeMethod("commitTransaction");
         
                /* Code Added for eBilling page to make contact resposibility type as BILLING */
                setBillingPurpose( pageContext, webBean, relPartyId);
                /* End - Code Added for eBilling page to make contact resposibility type as BILLING */                
                
                if (pageContext.getParameter("ASNReqFromLOVPage") != null) {
                    if (isStatLogEnabled) {
                        pageContext.writeDiagnostics(METHOD_NAME, 
                                                     "ASNReqFromLOVPage = " + 
                                                     fromLOV, 
                                                     OAFwkConstants.STATEMENT);
                    } //pageContext.putParameter("ASNReqSelCustId",   objPartyId);
                    pageContext.putParameter("ASNReqSelCtctId", subPartyId);
                    pageContext.putParameter("ASNReqSelRelPtyId", relPartyId);
                    pageContext.putParameter("ASNReqSelRelId", relId);
                    Serializable[] parameters = { subPartyId };
                    String ctctPartyName = 
                        (String)rootAm.invokeMethod("getPartyNameFromId", 
                                                    parameters);
                    pageContext.putParameter("ASNReqSelCtctName", 
                                             ctctPartyName);
                    pageContext.releaseRootApplicationModule();
                    HashMap conditions = new HashMap();
                    conditions.put(ASNUIConstants.RETAIN_AM, "Y");
                    this.processTargetURL(pageContext, conditions, null);
                } else {
                    this.processTargetURL(pageContext, null, null);
                }




            
                /*if (isStatLogEnabled) {
                    pageContext.writeDiagnostics(METHOD_NAME, "DQM enabled", 
                                                 OAFwkConstants.STATEMENT);
                }


                params.put("ASNReqFrmCustId", 
                           pageContext.getParameter("ASNReqFrmCustId"));
                params.put("ASNReqFrmCustName", 
                           pageContext.getParameter("ASNReqFrmCustName"));

                if (pageContext.getParameter("ASNReqFromLOVPage") != null) {
                    if (isStatLogEnabled) {
                        pageContext.writeDiagnostics(METHOD_NAME, 
                                                     "ASNReqFromLOVPage = " + 
                                                     fromLOV, 
                                                     OAFwkConstants.STATEMENT);
                    }
                    params.put("ASNReqFromLOVPage", fromLOV);
                }
                
                String asnEnableOutOfCtxtDedupe = 
                    (String)pageContext.getProfile("ASN_DEDUPE_SHOW_ALL_CTCT");
                 if (isStatLogEnabled) {
                        pageContext.writeDiagnostics(METHOD_NAME, 
                                                     "Value of ASN_DEDUPE_SHOW_ALL_CTCT is :" + 
                                                     asnEnableOutOfCtxtDedupe, 
                                                     OAFwkConstants.STATEMENT);
                  }
                if (asnEnableOutOfCtxtDedupe != null && 
                    "Y".equalsIgnoreCase(asnEnableOutOfCtxtDedupe))
                {
                  // Get the value of show inactive check box.
                  OAMessageCheckBoxBean showAllBox = (OAMessageCheckBoxBean)webBean.findChildRecursive("ASNCtctShowInactiveChkBox");
                  String inActiveContact = (String)showAllBox.getValue(pageContext);

                  //Check the value of inactive check box and store the same
                  if ("N".equals(inActiveContact))
                  {
                    if (isStatLogEnabled)
                    {
                      pageContext.writeDiagnostics(METHOD_NAME, "Show Inactive False", OAFwkConstants.STATEMENT);
                    }
                    params.put("ASNCtctShowInactiveChkBox", "N");
                  }
                  else
                  {
                    if (isStatLogEnabled)
                    {
                      pageContext.writeDiagnostics(METHOD_NAME, "Show Inactive True", OAFwkConstants.STATEMENT);
                    }
                    params.put("ASNCtctShowInactiveChkBox", "Y");
                  }

                  if (isStatLogEnabled)
                  {
                    pageContext.writeDiagnostics(METHOD_NAME, "Forwarding to AllCtctWarningPage", OAFwkConstants.STATEMENT);
                  }
                  params.put("ASNReqFrmFuncName", "ASN_ALLCTCTWARNINGPG");
                  pageContext.forwardImmediately("ASN_ALLCTCTWARNINGPG"
                                                , KEEP_MENU_CONTEXT
                                                , null
                                                , params
                                                , true
                                                , ADD_BREAD_CRUMB_SAVE);
                } 
                else 
                {
                  //Required only in the case of old dedupe flow 
                  String conDeDupeMatchRuleId = (String)pageContext.getProfile("HZ_CON_DUP_PREV_MATCHRULE");
                  params.put("HzPuiSimpleMatchRuleId", conDeDupeMatchRuleId);
                  params.put("HzPuiComponentUsage", "DEDUPE");
                  params.put("HzPuiContactObjectId", pageContext.getParameter("ASNReqFrmCustId"));
                  params.put("HzPuiAddressEvent", "CREATE");

                  params.put("ASNReqFrmFuncName", "ASN_CTCTWARNINGPG");
                  pageContext.forwardImmediately("ASN_CTCTWARNINGPG"
                                                , KEEP_MENU_CONTEXT
                                                , null
                                                , params
                                                , true
                                                , ADD_BREAD_CRUMB_SAVE);
              }*/
             
            } //end of dqm enabled
            utl.log("End PFR ODCtctCreateCO:ASNPageApyBtn: ");            
            
        } //end of event handling for apply
        // Begin Mod Raam on 06.13.2006
        // address selection
        else if (pageContext.getParameter("ASNCustAddrSelBtn") != null)
        // When address select button is clicked
        {
            if (isProcLogEnabled) {
                pageContext.writeDiagnostics(METHOD_NAME, 
                                             "Select address button is clicked.", 
                                             OAFwkConstants.PROCEDURE);
            }

            // Set a transaction parameter value to indicate that user is navigating
            // out of this page to address selection page. This will be used in pR().

            pageContext.putTransactionValue("ASNTxnAddrSelFlow", "Y");

            params.put("ASNReqFrmCustId", 
                       pageContext.getParameter("ASNReqFrmCustId"));
            params.put("ASNReqFrmFuncName", "ASN_PTYADDRSELPG");
            // Set the following parameter to indicate that address selection page is
            // call from contact create page.
            params.put("ASNReqFrmCtctCreateFlow", "Y");
            // Begin Mod Raam on 06.27.2006
            if (fromLOV != null) {
                if (isStatLogEnabled) {
                    pageContext.writeDiagnostics(METHOD_NAME, 
                                                 "ASNReqFromLOVPage = " + 
                                                 fromLOV, 
                                                 OAFwkConstants.STATEMENT);
                }
                params.put("ASNReqFromLOVPage", fromLOV);
            }
            // End Mod.

            pageContext.forwardImmediately("ASN_PTYADDRSELPG"       // functionName
                                          , KEEP_MENU_CONTEXT       // menuContextAction
                                          , null                    // menuName
                                          , params                  // parameters
                                          , true                    // retainAM
                                          , ADD_BREAD_CRUMB_SAVE);  // addBreadCrumb
        }
        // End Mod.



    
       
	 if (isProcLogEnabled) {
      pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
	 }
  }



    public void processFormData(OAPageContext pageContext, OAWebBean webBean) {
        final String METHOD_NAME = 
            "od.oracle.apps.xxcrm.asn.common.customer.webui.ODCtctCreateCO.processFormData";
        boolean isProcLogEnabled = 
            pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);

        if (isProcLogEnabled) {
            pageContext.writeDiagnostics(METHOD_NAME, "Begin", 
                                         OAFwkConstants.PROCEDURE);
        }
        pageContext.putParameter("HzPuiPerProfileObjectId", 
                                 pageContext.getParameter("ASNReqFrmCustId"));
        pageContext.putParameter("HzPuiAddressEvent", "CREATE");

        if (isProcLogEnabled) {
            pageContext.writeDiagnostics(METHOD_NAME, "End", 
                                         OAFwkConstants.PROCEDURE);
        }
    }

    /* Method to call PLSQL API to set responsibilty as Billing for the newly created contact */
    public void setBillingPurpose(OAPageContext pageContext, OAWebBean webBean, String relPartyId)
    {
        ODUtil utl = new ODUtil(pageContext.getApplicationModule(webBean));    
        utl.log("Inside setBillingPurpose ODEBillParentPage:" + pageContext.getParameter("ODEBillParentPage") );                                                        
        utl.log("Inside setBillingPurpose: ODEBillCustAccId:" +  pageContext.getParameter("ODEBillCustAccId") ); 
        utl.log("Inside setBillingPurpose: relPartyId:" +  relPartyId );                 
        try
        {
          if ("ODEBillMainPG".equals(pageContext.getParameter("ODEBillParentPage")) 
                     &&  pageContext.getParameter("ODEBillCustAccId") != null && relPartyId != null)
          {
              utl.log("Inside setBillingPurpose:ASNPageApyBtn:  Calling Custom API:ODEBillCustAccId:" +  pageContext.getParameter("ODEBillCustAccId") );                                        
              utl.log("Inside setBillingPurpose:ASNPageApyBtn:  Calling Custom API:relPartyId: " + relPartyId );                                                            
              String custAccountId = pageContext.getParameter("ODEBillCustAccId");
             OAApplicationModule rootAm = (OAApplicationModule)pageContext.getRootApplicationModule();              
              OADBTransactionImpl oadbtransactionimpl = (OADBTransactionImpl) rootAm.getOADBTransaction();                    
              String createBilling = "BEGIN"
                              + "  XX_CDH_HZ_CUST_ACCT_ROLE_PKG.CREATE_CUST_ACCOUNT_ROLE( p_rel_party_id             => :1 "
                              + "                                                       , p_cust_account_id          => :2 "
                              + "                                                       , x_return_status            => :3); "
                              + "END;";
                
              OracleCallableStatement ocs = (OracleCallableStatement)oadbtransactionimpl.createCallableStatement(createBilling, -1);
              ocs.setNUMBER(1, new Number(relPartyId) );
              ocs.setNUMBER(2, new Number(custAccountId));
              ocs.registerOutParameter(3, Types.VARCHAR ); 
              ocs.execute();
              String returnStatus = ocs.getString(3); 
              utl.log("Inside setBillingPurpose:ASNPageApyBtn: After execute :returnStatus: " + returnStatus );                       
          }//end if
        }//end try
        catch(SQLException sqlexception)
        {
            throw OAException.wrapperException(sqlexception);
        }
        catch(Exception exception)
        {
            throw OAException.wrapperException(exception);
        }                 
      
    }


}
