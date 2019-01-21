/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODLeadCtctTableCO.java                                        |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Controller Object for the Contact Region on the Lead Details Page.     |
 |                                                                           |
 |  NOTES                                                                    |
 |         Used for the Customization on the Lead Details Page               |
 |         Modified to pass the Party and Site Search Criteria               |
 |         to the Add Contact Page and Party Site Id                         |
 |         to the Create Contact page                                        |
 |  DEPENDENCIES                                                             |
 |    No dependencies.                                                       |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    12-Sep-2007 Jasmine Sujithra   Created                                 |
 |    05-Dec-2007 Sathya Prabha      Added custom code to render data in the |
 |                                   Address and Related Org ID fields of UI |
 |                                   on click of Add Contact button.         |
 |    12-Dec-2007 Jasmine Sujithra   Modified to use Profile to get          |
 |                                   match rule name                         |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.lead.webui;

import com.sun.java.util.collections.HashMap;
import java.io.Serializable;
import oracle.apps.asn.common.fwk.webui.ASNControllerObjectImpl;
import oracle.apps.asn.common.fwk.webui.ASNUIConstants;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.table.OAAdvancedTableBean;
import oracle.jbo.Row;


/**
 * Controller for ...
 */
public class ODLeadCtctTableCO extends ASNControllerObjectImpl
{
  public static final String RCS_ID="$Header: /home/cvs/repository/Office_Depot/SRC/CRM/E1307_SiteLevel_Attributes_ASN/3.\040Source\040Code\040&\040Install\040Files/E1307D_SiteLevel_Attributes_(LeadOpp_CreateUpdate)/ODLeadCtctTableCO.java,v 1.4 2007/10/19 08:11:31 jsujithra Exp $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
     final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.lead.webui.ODLeadCtctTableCO.processRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processRequest(pageContext, webBean);

      /********  Get Page layout and Application module   *********/
    OAApplicationModule oam = pageContext.getRootApplicationModule();

    // Get a handle to the Header of the Contacts Additional Info region
    OAHeaderBean ctctBean=(OAHeaderBean)webBean.findChildRecursive("ASNCtctAddInfoHdrRN");

      /********  Set Table Selection Bar UI properties   *********/
    OAAdvancedTableBean ctctLstBean = (OAAdvancedTableBean)webBean.findIndexedChildRecursive("ASNCtctLstTb");
    if(ctctLstBean!=null)
    {
      // Debug Logging
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(200);
        buf.append(" ctctLstBean is not null ");
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      } // End Debug Logging

      String leadReadOnly = (String)pageContext.getTransactionValue("ASNTxnLeadReadOnly");
      // Debug Logging
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(200);
        buf.append(" leadReadOnly : ");
        buf.append(leadReadOnly);
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      } // End Debug Logging

      if("N".equals(leadReadOnly))
      {
        OAWebBean tableSelectionBean = (OAWebBean)ctctLstBean.getTableSelection();
        if(tableSelectionBean!=null)
        {
          OAMessageChoiceBean actionChcBean = (OAMessageChoiceBean)tableSelectionBean.findIndexedChildRecursive("ASNCtctAction");
          if(actionChcBean!=null)
          {
            actionChcBean.setRequired(OAWebBeanConstants.REQUIRED_YES);
            actionChcBean.setRequiredIcon("");
          }
        }
      }

      // Set the Contact table actions based on the Lead Read Only mode
      if(ctctBean.isRendered())
      {
        //  Set the Customer related UI attributes
        oam.invokeMethod("setLeadDetCustFlexProperties", new Serializable[]{
                                                          leadReadOnly,
                                                          "Y"
                                                         });
      }
      else
      {
        //  Set the Customer related UI attributes
        oam.invokeMethod("setLeadDetCustFlexProperties", new Serializable[]{
                                                          leadReadOnly,
                                                          "N"
                                                         });
      }

      // We check if the Flexfield Region is rendered, based on which we do a workaround
      if(ctctBean.isRendered())
      {
        // Refresh the Current Row or set the first row
        oam.invokeMethod("refreshContactDetailsRow");
      }
    }

    /** Handle contact selection **/
    String selRelPtyId = pageContext.getParameter("ASNReqSelRelPtyId");
    if(selRelPtyId!=null && !("".equals(selRelPtyId.trim())))
    {
      String selCtctId = pageContext.getParameter("ASNReqSelCtctId");
      String selRelId = pageContext.getParameter("ASNReqSelRelId");
      Serializable[] ctctParams = {selRelPtyId, selCtctId, selRelId};
      // Debug Logging
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(200);
        buf.append(" Handle Contact Selection - Parameters being passed to addLeadContact -  ");
        buf.append(" ctctParams : ");
        buf.append(ctctParams.toString());
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      } // End Debug Logging

      oam.invokeMethod("addLeadContact", ctctParams);
    }

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
    final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.lead.webui.ODLeadCtctTableCO.processFormRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processFormRequest(pageContext, webBean);

      /********  Get the Application module   *********/
    OAApplicationModule oam = pageContext.getRootApplicationModule();

      /********  Get the page action event that has caused the submit  *********/
    String actEvt = pageContext.getParameter("ASNReqPgAct");

    // Debug Logging
    if (isStatLogEnabled)
    {
      StringBuffer buf = new StringBuffer(200);
      buf.append(" actEvt : ");
      buf.append(actEvt);
      pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
    } // End Debug Logging

    // Get a handle to the Header of the Contacts Additional Info region
    OAHeaderBean ctctBean=(OAHeaderBean)webBean.findChildRecursive("ASNCtctAddInfoHdrRN");

      /********  Get the Page title   *********/
    String pageTitle = pageContext.getParameter("ASNReqBrdCrmbTtl");

      /********  Handle the applciation logic for each event  *********/
    if(pageContext.getParameter("ASNCtctGoButton")!=null)
    {
      String viewAction = pageContext.getParameter("ASNCtctAction");

      // Debug Logging
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(200);
        buf.append(" Contact Go Button  ");
        buf.append(" Value of viewAction : ");
        buf.append(viewAction);
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      } // End Debug Logging

      if("VIEW_DETAILS".equals(viewAction))
      {
          // get the selected contact info from LeadContactDetailsVO
        HashMap urlParams = (HashMap)oam.invokeMethod("getSelectedContactDetails",
                                                      new Serializable[] {"LeadHeaderContactDetailsVO"});
        if(urlParams!=null && urlParams.size()>0)
        {
          this.doCommit(pageContext);
          // oam.invokeMethod("resetQuery", new Serializable[]{"LeadHeaderDetailsVO"});
          HashMap conditions = new HashMap(3);
          conditions.put(ASNUIConstants.BC_CURRENT_LINK, ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
          conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT, pageTitle);
          pageContext.putParameter("ASNReqPgAct", "CTCTDET");

          // Debug Logging
          if (isStatLogEnabled)
          {
            StringBuffer buf = new StringBuffer(200);
            buf.append(" View Details - Parameters being passed to processTargetURL -  ");
            buf.append(" conditions : ");
            buf.append(conditions.toString());
            buf.append(" urlParams : ");
            buf.append(urlParams.toString());
            pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
          } // End Debug Logging

          this.processTargetURL(pageContext, conditions, urlParams);
        }
        else
        {
          throw new OAException("ASN","ASN_CMMN_RADIO_MISS_ERR");
        }
      }
      else if("REMOVE".equals(viewAction))
      {
        boolean isSuccess = this.deleteSelectedRow(oam, "LeadHeaderContactDetailsVO");
        if(!isSuccess)
          throw new OAException("ASN","ASN_CMMN_RADIO_MISS_ERR");
      }
      else if("CREATE_TASK".equals(viewAction))
      {
        HashMap ctctParams = (HashMap)oam.invokeMethod("getSelectedContactDetails",
                                                      new Serializable[] {"LeadHeaderContactDetailsVO"});

         // Debug Logging
        if (isStatLogEnabled)
        {
          StringBuffer buf = new StringBuffer(200);
          buf.append(" Create Task - values returned by call to getSelectedContactDetails method - HashMap ctctParams : ");
          buf.append(ctctParams.toString());
          pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
        } // End Debug Logging

        if(ctctParams!=null && ctctParams.size() > 0)
        {
          this.doCommit(pageContext);
          oam.invokeMethod("resetQuery", new Serializable[]{"LeadHeaderDetailsVO"});
          String leadId = pageContext.getParameter("ASNReqFrmLeadId");
          HashMap taskParams = new HashMap(8);

          Serializable aserializable[] = {"LeadHeaderDetailsVO", leadId};
          HashMap hashmp = (HashMap)oam.invokeMethod("getLeadInfo", aserializable);
		  String addressid = (String)hashmp.get("AddressId");

          taskParams.put("cacTaskSrcObjCode", "LEAD");
          taskParams.put("cacTaskSrcObjId", pageContext.encrypt(leadId));
          taskParams.put("cacTaskCustId", (String)ctctParams.get("ASNReqFrmCustId"));
          taskParams.put("cacTaskContactId", (String)ctctParams.get("ASNReqFrmRelPtyId"));
          taskParams.put("cacTaskCustAddressId", addressid);

          HashMap conditions = new HashMap(3);
          conditions.put(ASNUIConstants.BC_CURRENT_LINK, ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
          conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT, pageTitle);
          pageContext.putParameter("ASNReqPgAct", "CRTETASK");
         // Debug Logging
          if (isStatLogEnabled)
          {
            StringBuffer buf = new StringBuffer(200);
            buf.append(" Create Task - Parameters being passed to processTargetURL -  ");
            buf.append(" conditions : ");
            buf.append(conditions.toString());
            buf.append(" taskParams : ");
            buf.append(taskParams.toString());
            pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
          } // End Debug Logging

          this.processTargetURL(pageContext, conditions, taskParams);
        }
        else
        {
          throw new OAException("ASN","ASN_CMMN_RADIO_MISS_ERR");
        }
      }
      else if("SEND_PROPOSAL".equals(viewAction))
      {
        String leadId = pageContext.getParameter("ASNReqFrmLeadId");
          // get the selected contact info from LeadContactDetailsVO
        HashMap ctctParams = (HashMap)oam.invokeMethod("getSelectedContactDetails",
                                                      new Serializable[] {"LeadHeaderContactDetailsVO"});
        // Debug Logging
        if (isStatLogEnabled)
        {
          StringBuffer buf = new StringBuffer(200);
          buf.append(" Send Proposal - HashMap ctctParams returned by method getSelectedContactDetails -  ");
          buf.append(" ctctParams : ");
          buf.append(ctctParams.toString());
          pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
        } // End Debug Logging

        if(ctctParams!=null && ctctParams.size()>0)
        {
          this.doCommit(pageContext);
          HashMap prpParams = new HashMap(7);
          prpParams.put("PRPObjectType", "SALES_LEAD");
          prpParams.put("PRPObjectId", leadId);
          prpParams.put("PRPReturnFunctionName", "ASN_LEADDETPG");
          prpParams.put("PRPContactRelPartyId", (String)ctctParams.get("ASNReqFrmRelPtyId"));
            // get the lead source code
          String sourceCode = (String)oam.invokeMethod("getLeadSourceCode",
                                                      new Serializable[] {"LeadHeaderDetailsVO"});
          prpParams.put("PRPSourceCode", sourceCode);
          oam.invokeMethod("resetQuery", new Serializable[]{"LeadHeaderDetailsVO"});

          HashMap conditions = new HashMap(3);
          conditions.put(ASNUIConstants.BC_CURRENT_LINK, ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
          conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT, pageTitle);
          pageContext.putParameter("ASNReqPgAct", "CRTEPRP");

          // Debug Logging
          if (isStatLogEnabled)
          {
            StringBuffer buf = new StringBuffer(200);
            buf.append(" Send Proposal - Parameters being passed to processTargetURL -  ");
            buf.append(" conditions : ");
            buf.append(conditions.toString());
            buf.append(" prpParams : ");
            buf.append(prpParams.toString());
            pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
          } // End Debug Logging

            // forard URL to create proposal page
          this.processTargetURL(pageContext, conditions, prpParams);
        }
        else
        {
          throw new OAException("ASN","ASN_CMMN_RADIO_MISS_ERR");
        }
      }
    }
    else if(pageContext.getParameter("ASNCtctAddButton")!=null)
    {  String leadId11 = pageContext.getParameter("ASNReqFrmLeadId");
		Serializable aserial11[] = {"LeadHeaderDetailsVO", leadId11};
		HashMap hasmap = (HashMap)oam.invokeMethod("getLeadInfo", aserial11);
      String partySID = (String)hasmap.get("AddressId");
		//String partySID = (String) pageContext.getParameter("ASNReqFrmSiteId");

					pageContext.writeDiagnostics(METHOD_NAME,"HzPuiAddressViewPartySiteId:" +partySID,OAFwkConstants.PROCEDURE);
								String sql1 = "select status from hz_party_sites where party_site_id = :1";
			  		  		  OAApplicationModule ctam = (OAApplicationModule)pageContext.getApplicationModule(webBean);
                          oracle.jbo.ViewObject pctvo4 = ctam.findViewObject("pctVO4");
			  		  		             if (pctvo4 == null )
			  		  		             {
			  		  		               pctvo4 = ctam.createViewObjectFromQueryStmt("pctVO4", sql1);
			  		  		             }

			  		  		             if (pctvo4 != null)
			  		  		             {
			  		  		                 pctvo4.setWhereClauseParams(null);
			  		  		                 pctvo4.setWhereClauseParam(0,partySID);
			  		  		                 pctvo4.executeQuery();
			  		  		                 pctvo4.first();
			  		  		                 String status = pctvo4.getCurrentRow().getAttribute(0).toString();
			  		  		                 pageContext.writeDiagnostics(METHOD_NAME,"ctstatus:" +status,OAFwkConstants.PROCEDURE);
			  		  		                 if ("I".equals(status))
			  		  		                 {
												 pctvo4.remove();
												 throw new OAException("XXCRM","XX_SFA_071_CTCT_INVALIDADDR");
											 }
										  else
			  		  		                 {
												   pctvo4.remove();
      String leadId = pageContext.getParameter("ASNReqFrmLeadId");
      String customerId = (String)oam.invokeMethod("getLeadCustomerId", new Serializable[]{"LeadHeaderDetailsVO"});

      this.doCommit(pageContext);
      oam.invokeMethod("resetQuery", new Serializable[]{"LeadHeaderDetailsVO"});
      Serializable params[] = {"LeadHeaderDetailsVO", leadId};
      oam.invokeMethod("getLeadInfo", params);

      pageContext.putParameter("ASNReqPgAct", "SUBFLOW");
      HashMap conditions = new HashMap(4);
      conditions.put(ASNUIConstants.RETAIN_AM, "Y");
      conditions.put(ASNUIConstants.BC_CURRENT_LINK, ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
      conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT, pageTitle);

        // set the required sub-flow specific parameters
      HashMap urlParams = new HashMap(4);
      urlParams.put("ASNReqFrmFuncName", "ASN_LEADCTCTSELPG");
      urlParams.put("ASNReqFrmLeadId", leadId);
      urlParams.put("ASNReqFrmCustId", customerId);

      /* Include Custom code to set the Match Rule Attributes for Party Number and Address */

      /* Get the Match Rule name from the profile option HZ: Match Rule for Contact Simple Search */
      String ctctSimpleMatchRuleId = (String) pageContext.getProfile("HZ_DQM_CON_SIMPLE_MATCHRULE");

      /* Get the address ID */
      Serializable aserializable[] = {
            "LeadHeaderDetailsVO", leadId
              };
      HashMap addhashmap = (HashMap)oam.invokeMethod("getLeadInfo", aserializable);
      String addressid = (String)addhashmap.get("AddressId");

      /* Get the Formatted Address String */
      String address = null;
      String addressSql = "SELECT DECODE(HZPS.LOCATION_ID,NULL,NULL,HZ_FORMAT_PUB.FORMAT_ADDRESS(HZPS.LOCATION_ID,NULL,NULL,',')) FROM HZ_PARTY_SITES HZPS WHERE HZPS.PARTY_SITE_ID = :1";
      oracle.jbo.ViewObject addressvo = oam.findViewObject("AddressVO");
      if (addressvo == null )
      {
          addressvo = oam.createViewObjectFromQueryStmt("AddressVO", addressSql);
      }

      if (addressvo != null)
      {
          addressvo.setWhereClauseParam(0,addressid);
          addressvo.executeQuery();
          addressvo.first();
          Row addressvoRow=addressvo.getCurrentRow();

          if (addressvoRow != null)
          {
              if (addressvoRow.getAttribute(0) != null)
              {
                address = addressvoRow.getAttribute(0).toString();
              }
          }

          addressvo.remove();
      }


      /* Get the Party Number */
      String partyNumber = null;
      String partyNumberSql = "SELECT PARTY_NUMBER FROM HZ_PARTIES WHERE PARTY_ID = :1";
      oracle.jbo.ViewObject partyNumbervo = oam.findViewObject("PartyNumberVO");
      if (partyNumbervo == null )
      {
          partyNumbervo = oam.createViewObjectFromQueryStmt("PartyNumberVO", partyNumberSql);
      }

      if (partyNumbervo != null)
      {
          partyNumbervo.setWhereClauseParam(0,customerId);
          partyNumbervo.executeQuery();
          partyNumbervo.first();
          Row partyNumbervoRow=partyNumbervo.getCurrentRow();

          if (partyNumbervoRow != null)
          {
              if (partyNumbervoRow.getAttribute(0) != null)
              {
                partyNumber = partyNumbervoRow.getAttribute(0).toString();
              }
          }

          partyNumbervo.remove();
      }


       /* Get the Address Attribute Id from the Match Rule Setup*/
       String addressAttId = null;

      String addressIdSql = " SELECT TAT.ATTRIBUTE_ID FROM HZ_MATCH_RULE_SECONDARY MRP,  HZ_TRANS_ATTRIBUTES_TL TAT WHERE MRP.ATTRIBUTE_ID  = TAT.ATTRIBUTE_ID AND MRP.MATCH_RULE_ID = :1 AND TAT.USER_DEFINED_ATTRIBUTE_NAME ='Address'";
      oracle.jbo.ViewObject addrIdvo = oam.findViewObject("AddrIdVO");
      if (addrIdvo == null )
      {
          addrIdvo = oam.createViewObjectFromQueryStmt("AddrIdVO", addressIdSql);
      }

      if (addrIdvo != null)
      {
          addrIdvo.setWhereClauseParam(0,ctctSimpleMatchRuleId);
          addrIdvo.executeQuery();
          addrIdvo.first();
          Row addrIdvoRow=addrIdvo.getCurrentRow();

          if (addrIdvoRow != null)
          {
              if (addrIdvoRow.getAttribute(0) != null)
              {
                addressAttId = addrIdvoRow.getAttribute(0).toString();
              }
          }

          addrIdvo.remove();
      }

       /* Get the Related Organization Number Attribute Id from the Match Rule Setup*/
       String relOrgAttId = null;
      //String relOrgIdSql = "SELECT TAT.ATTRIBUTE_ID FROM HZ_MATCH_RULE_SECONDARY MRP,  HZ_TRANS_ATTRIBUTES_TL TAT,  HZ_MATCH_RULES_VL HMR WHERE MRP.ATTRIBUTE_ID  = TAT.ATTRIBUTE_ID AND MRP.MATCH_RULE_ID = HMR.MATCH_RULE_ID AND HMR.RULE_NAME ='XXOD_PERSON_ADVANCED_SEARCH_MATCH_RULE' AND TAT.USER_DEFINED_ATTRIBUTE_NAME ='Related Organization ID'";
      String relOrgNumberSql = "SELECT TAT.ATTRIBUTE_ID FROM HZ_MATCH_RULE_SECONDARY MRP,  HZ_TRANS_ATTRIBUTES_TL TAT WHERE MRP.ATTRIBUTE_ID  = TAT.ATTRIBUTE_ID AND MRP.MATCH_RULE_ID = :1 AND TAT.USER_DEFINED_ATTRIBUTE_NAME ='Related Organization Number'";
      oracle.jbo.ViewObject relOrgNumbervo = oam.findViewObject("RelOrgNumberVO");
      if (relOrgNumbervo == null )
      {
          relOrgNumbervo = oam.createViewObjectFromQueryStmt("RelOrgNumberVO", relOrgNumberSql);
      }

      if (relOrgNumbervo != null)
      {
          relOrgNumbervo.setWhereClauseParam(0,ctctSimpleMatchRuleId);
          relOrgNumbervo.executeQuery();
          relOrgNumbervo.first();
          //VJ Added as part of fix for Issue 174 - BEGIN
          Row relOrgNumbervoRow=relOrgNumbervo.getCurrentRow();

          if (relOrgNumbervoRow != null)
          {
              if (relOrgNumbervoRow.getAttribute(0) != null)
              {
                relOrgAttId = relOrgNumbervoRow.getAttribute(0).toString();
              }
          }
          //VJ Added as part of fix for Issue 174 - END
          //String relOrgAttId = relOrgIdvo.getCurrentRow().getAttribute(0).toString();

          relOrgNumbervo.remove();
      }


      /* Append the Attribute Id to the string MATCH_RULE_ATTR to get the Match Rule Attribute Name */
      //  String RegistryIdParamName = "MATCH_RULE_ATTR" + registryAttId;
      String AddrParamName = "MATCH_RULE_ATTR" + addressAttId;
      String RelatedOrgNumberParamName = "MATCH_RULE_ATTR" + relOrgAttId;

      /* Pass the address and Party Number to the Address and Related Organization Number fields accordingly */
      // pageContext.putParameter(RegistryIdParamName,addressValue);
      // pageContext.putParameter(AddrParamName,addressValue);
      pageContext.putParameter(AddrParamName,address);
      pageContext.putParameter(RelatedOrgNumberParamName,partyNumber);


      /* End of Custom Code */


      pageContext.putTransactionValue("ASNTxnSubFlowVUN", "LeadHeaderContactDetailsVO");

      // Debug Logging
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(200);
        buf.append(" Contact Add Button - Parameters being passed to processTargetURL -  ");
        buf.append(" conditions : ");
        buf.append(conditions.toString());
        buf.append(" urlParams : ");
        buf.append(urlParams.toString());
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      } // End Debug Logging

      this.processTargetURL(pageContext, conditions, urlParams);
  }}
    }

    // Following event occurs when the Create Contact Button is clicked
    else if (pageContext.getParameter("ASNCtctCrteButton") != null)
    {   String leadId9 = pageContext.getParameter("ASNReqFrmLeadId");
		Serializable aserial9[] = {"LeadHeaderDetailsVO", leadId9};
		HashMap hasmap = (HashMap)oam.invokeMethod("getLeadInfo", aserial9);
      String partySID = (String)hasmap.get("AddressId");
		//String partySID = (String) pageContext.getParameter("ASNReqFrmSiteId");

					pageContext.writeDiagnostics(METHOD_NAME,"HzPuiAddressViewPartySiteId:" +partySID,OAFwkConstants.PROCEDURE);
								String sql1 = "select status from hz_party_sites where party_site_id = :1";
			  		  		  OAApplicationModule ctam = (OAApplicationModule)pageContext.getApplicationModule(webBean);
                          oracle.jbo.ViewObject pctvo4 = ctam.findViewObject("pctVO4");
			  		  		             if (pctvo4 == null )
			  		  		             {
			  		  		               pctvo4 = ctam.createViewObjectFromQueryStmt("pctVO4", sql1);
			  		  		             }

			  		  		             if (pctvo4 != null)
			  		  		             {
			  		  		                 pctvo4.setWhereClauseParams(null);
			  		  		                 pctvo4.setWhereClauseParam(0,partySID);
			  		  		                 pctvo4.executeQuery();
			  		  		                 pctvo4.first();
			  		  		                 String status = pctvo4.getCurrentRow().getAttribute(0).toString();
			  		  		                 pageContext.writeDiagnostics(METHOD_NAME,"ctstatus:" +status,OAFwkConstants.PROCEDURE);
			  		  		                 if ("I".equals(status))
			  		  		                 {
												 pctvo4.remove();
												 throw new OAException("XXCRM","XX_SFA_071_CTCT_INVALIDADDR");
											 }
										  else
			  		  		                 {
												   pctvo4.remove();
      String customerId = (String)oam.invokeMethod("getLeadCustomerId", new Serializable[]{"LeadHeaderDetailsVO"});
      String leadId = pageContext.getParameter("ASNReqFrmLeadId");
      /* Get the Address Id - to be passed as Party Site Id*/
       // Debug Logging
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(200);
        buf.append(" customerId : ");
        buf.append(customerId);
        buf.append(" leadId : ");
        buf.append(leadId);
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      } // End Debug Logging

      Serializable aserializable[] = {
            "LeadHeaderDetailsVO", leadId
              };
      HashMap addhashmap = (HashMap)oam.invokeMethod("getLeadInfo", aserializable);
      String addressid = (String)addhashmap.get("AddressId");
      String address =(String)addhashmap.get("Address");

      //commit the changes
      this.doCommit(pageContext);
      oam.invokeMethod("resetQuery", new Serializable[]{"LeadHeaderDetailsVO"});
      Serializable params[] = {"LeadHeaderDetailsVO", leadId};
      oam.invokeMethod("getLeadInfo", params);

      //this is a subflow, so we need this parameter
      pageContext.putParameter("ASNReqPgAct", "SUBFLOW");
      HashMap conditions = new HashMap(4);
      conditions.put(ASNUIConstants.RETAIN_AM, "Y");
      conditions.put(ASNUIConstants.BC_CURRENT_LINK, ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
      conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT, pageTitle);

        // set the required sub-flow specific parameters
      HashMap urlParams = new HashMap(4);
      urlParams.put("ASNReqFrmFuncName", "ASN_CTCTCREATEPG");
      urlParams.put("ASNReqFrmCustId", customerId);
      urlParams.put("ASNReqFromLOVPage", "TRUE");
      urlParams.put("ASNReqSelPartySiteId", addressid);
      urlParams.put("ASNReqSelAddress", address);
      urlParams.put("ASNReqFrmSiteId",addressid);
      pageContext.putTransactionValue("ASNTxnSubFlowVUN", "LeadHeaderContactDetailsVO");

      // Debug Logging
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(200);
        buf.append(" Contact Create Button - Parameters being passed to processTargetURL -  ");
        buf.append(" conditions : ");
        buf.append(conditions.toString());
        buf.append(" urlParams : ");
        buf.append(urlParams.toString());
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      } // End Debug Logging

      this.processTargetURL(pageContext, conditions, urlParams);
  }}
    }

    else if("CTCTDEL".equals(actEvt))
    {
      String leadCtctId = pageContext.getParameter("ASNReqEvtRowId");
      this.deleteRow(oam, "LeadHeaderContactDetailsVO", "LeadContactId", leadCtctId, false);

      // We check if the Flexfield Region is rendered, based on which we do a workaround
      if(ctctBean.isRendered())
      {
        // Use the following Line of Code as workaround for Bug # 3274685
        // pageContext.forwardImmediately(PageFunctionName,MenuContext, MenuName, urlParams, RetainAM,BreadCrumb);
        // This has been handled in the processTargetURL
        pageContext.putParameter("ASNReqPgAct", "REFRESH");
        this.processTargetURL(pageContext, null, null);
      }
    }

    // Additional Info. Flexfield Code
    // Following Event fires when a Row is selected on the Contacts table
    String oaActEvt = pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM);

    // Debug Logging
    if (isStatLogEnabled)
    {
      StringBuffer buf = new StringBuffer(200);
      buf.append(" value of oaActEvt : ");
      buf.append(oaActEvt);
      pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
    } // End Debug Logging

    // Check for the Event when the Fire Action happens on the single selection
    if ("ASNLeadCtctSelFA".equals(oaActEvt))
    {
      if(ctctBean.isRendered())
      {
        // Invoke the method in the AM that sets the Row selected as a Current Row in the VO
        oam.invokeMethod("refreshContactDetailsRow");
        HashMap ctctUrlParams = new HashMap();
        String ctctLeadId = (String)pageContext.getTransactionValue("ASNTxnLeadId");
        ctctUrlParams.put("ASNReqFrmLeadId",ctctLeadId.toString());

        // Use the following Line of Code as workaround for Bug # 3274685
        // pageContext.forwardImmediately(PageFunctionName,MenuContext, MenuName, urlParams, RetainAM,BreadCrumb);
        // This has been handled in the processTargetURL
        pageContext.putParameter("ASNReqPgAct", "REFRESH");
        this.processTargetURL(pageContext, null, null);
      }
    }

    if (isProcLogEnabled)
    {
    pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }

  }

}
