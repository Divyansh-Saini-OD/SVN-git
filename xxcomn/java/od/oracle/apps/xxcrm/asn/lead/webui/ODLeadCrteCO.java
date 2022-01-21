/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODLeadCrteCO.java                                             |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Page Controller class for Create Lead Page.                            |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    No dependencies.                                                       |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |                                     Created                               |
 |    23-Nov-2007 Jasmine Sujithra     Added logic to default site Address   |
 |    22-May-2009 Anirban Chaudhuri    Fixed defect#15033                    |
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
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.jbo.ViewObject;
import oracle.apps.fnd.common.MessageToken;
import oracle.jbo.Row;
import oracle.apps.asn.lead.server.*;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.jbo.domain.Number;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;


/**
 * Controller for ODLeadCrtePG
 */
public class ODLeadCrteCO extends ASNControllerObjectImpl
{
  public static final String RCS_ID="$Header: ODLeadCrteCO.java 115.26 2005/02/05 03:25:32 pchalaga ship $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "od.oracle.apps.xxcrm.asn.lead.webui");

  /**
   * Layout and page setup logic for AK region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    final String METHOD_NAME = "xxcrm.asn.lead.webui.ODLeadCrteCO.processRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);

    if (isProcLogEnabled)
    {
     pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processRequest(pageContext, webBean);

    /* Office depot lead creation address region customization */
			ViewObject leadVO = pageContext.getApplicationModule(webBean).findViewObject("LeadCreateVO");
			if(leadVO != null)
	    {
	      if (leadVO.getAttributeCount() == oracle.jbo.server.ViewDefImpl.getMaxAttrConst("oracle.apps.asn.lead.server.LeadCreateVO"))
	      {
	        leadVO.addDynamicAttribute("AddressId");
	        leadVO.addDynamicAttribute("AddressDetails");
	      }
    }

    //  Get Page layout and Application module
    OAApplicationModule oam = pageContext.getApplicationModule(webBean);

    //  Get user context information such as getting the Resource Id, Login User's Info,
    //  Resource Group Id, Master Organization Id, Manager Flag
	  this.initUserContext(oam, pageContext);

    //  Load / Create a Row
    // This makes sure the middle tier state (the EO and VO cache) are cleared.
    if(!this.isViewObjectQueried(oam, "LeadCreateVO"))
    {
      this.doRollback(pageContext);
      this.createRow(oam, "LeadCreateVO");
    }

	// Debug Logging
    if (isStatLogEnabled)
    {
      StringBuffer buf = new StringBuffer(200);
      buf.append(" After calling createRow on LeadCreateVO. ");
      buf.append(" Before calling the method getLeadInfo. ");
      pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
    } // End Debug Logging

    HashMap leadInfo = (HashMap)oam.invokeMethod("getLeadInfo");

    // Debug Logging
    if (isStatLogEnabled)
    {
      StringBuffer buf = new StringBuffer(200);
      buf.append(" After calling the method getLeadInfo. ");
      buf.append(" leadInfo : ");
      buf.append(leadInfo.toString());
      pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
    } // End Debug Logging

    String leadId = null;
    if(leadInfo!=null)
    {
      leadId = (String)leadInfo.get("SalesLeadId");
    }

    // Modify the Detail Region properties

    if(leadId!=null)
    {
      // Handle customer selection while returning from the Customer Selection Subflow Page
      String selCustId = pageContext.getParameter("ASNReqSelCustId");
      String selCustName = null;
      if(selCustId!=null && !("".equals(selCustId.trim())))
      {
        selCustName = pageContext.getParameter("ASNReqSelCustName");
      }
      else
      {
        String custId = (String)leadInfo.get("CustomerId");
        if(custId!=null)
        {
          selCustId = custId;
          selCustName = (String)leadInfo.get("PartyName");
        }

      }
      Serializable[] custParams = {selCustId, selCustName};

      // Debug Logging
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(200);
        buf.append("Parameters passed to setCustomerAttributes method. ");
        buf.append(" selCustId : ");
        buf.append(selCustId);
        buf.append(" , selCustName : ");
        buf.append(selCustName);
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      } // End Debug Logging

      oam.invokeMethod("setCustomerAttributes", custParams);

      // Handle Primary Contact while returning from the Primary Contact Selection Subflow Page
      String selCtctId = pageContext.getParameter("ASNReqSelRelPtyId");

      // Debug Logging
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(200);
        buf.append(" Primary Contact Party Id returned by the Context parameter ASNReqSelRelPtyId : ");
        buf.append(selCtctId);
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      } // End Debug Logging

      String selCtctName = null;
      if(selCtctId!=null && !("".equals(selCtctId.trim())))
      {
        // Debug Logging
        if (isStatLogEnabled)
        {
          StringBuffer buf = new StringBuffer(200);
          buf.append(" selCtctId is not NULL ");
          pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
        } // End Debug Logging

        selCtctName = pageContext.getParameter("ASNReqSelCtctName");
        Serializable[] ctctParams = {selCtctId, selCtctName};

        // Debug Logging
        if (isStatLogEnabled)
        {
          StringBuffer buf = new StringBuffer(200);
          buf.append(" Parameters passed to setContactAttributes method. ");
          buf.append(" selCtctId : ");
          buf.append(selCtctId);
          buf.append(" , selCtctName (got from the Context parameter ASNReqSelCtctName) : ");
          buf.append(selCtctName);
          buf.append(" Before call to setContactAttributes method. ");
          pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
        } // End Debug Logging

        oam.invokeMethod("setContactAttributes", ctctParams);

        // Debug Logging
        if (isStatLogEnabled)
        {
          StringBuffer buf = new StringBuffer(200);
          buf.append(" After call to setContactAttributes method. ");
          pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
        } // End Debug Logging

      }
      else
      {
        // Debug Logging
        if (isStatLogEnabled)
        {
          StringBuffer buf = new StringBuffer(200);
          buf.append(" selCtctId is NULL ");
          pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
        } // End Debug Logging

        selCtctName = (String)leadInfo.get("ContactName");
      }

      // Always Disable customer and contact fields
      OAMessageTextInputBean custBean = (OAMessageTextInputBean)webBean.findIndexedChildRecursive("ASNLeadCrteCust");
      OAMessageTextInputBean ctctBean = (OAMessageTextInputBean)webBean.findIndexedChildRecursive("ASNLeadCrteCtct");
      if(custBean!=null)
      {
        custBean.setDisabled(true);
      }
      if(ctctBean!=null)
      {
        ctctBean.setDisabled(true);
      }

      // Changes for Customer Actions -- Changes done for Customer Field
      OAMessageTextInputBean mainCustName = (OAMessageTextInputBean) webBean.findIndexedChildRecursive("ASNLeadCrteCust");
      String selectCustText = pageContext.getMessage("ASN", "ASN_CMMN_NO_CUST_SEL", null);
      Serializable [] selParams = {selCustId, selCustName,selectCustText};

      if (mainCustName !=null)
      {
        String custRenderProp = (String) oam.invokeMethod("setCustomerText",selParams);

        // Debug Logging
        if (isStatLogEnabled)
        {
          StringBuffer buf = new StringBuffer(200);
          buf.append(" Customer Actions - Customer Field ");
          buf.append(" custRenderProp : ");
          buf.append(custRenderProp);
          pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
        } // End Debug Logging

        if ("N".equals(custRenderProp))
        {
          mainCustName.setReadOnly(true);
          mainCustName.setDisabled(true);
        }
        else
        {
          mainCustName.setReadOnly(false);
          mainCustName.setDisabled(true);
        }
      }

      // Changes for Customer Actions -- Changes done for Contact Field
      OAMessageTextInputBean mainCtctName = (OAMessageTextInputBean) webBean.findIndexedChildRecursive("ASNLeadCrteCtct");
      String selectCtctText = pageContext.getMessage("ASN", "ASN_CMMN_NO_CTCT_SEL", null);
      Serializable [] selParams1 = {selCtctId, selCtctName,selectCtctText};

      if (mainCtctName !=null)
      {
        String ctctRenderProp = (String) oam.invokeMethod("setContactText",selParams1);

        // Debug Logging
        if (isStatLogEnabled)
        {
          StringBuffer buf = new StringBuffer(200);
          buf.append(" Customer Actions - Contact Field ");
          buf.append(" ctctRenderProp : ");
          buf.append(ctctRenderProp);
          pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
        } // End Debug Logging

        if ("N".equals(ctctRenderProp))
        {
          mainCtctName.setReadOnly(true);
          mainCtctName.setDisabled(true);
        }
        else
        {
          mainCtctName.setReadOnly(false);
          mainCtctName.setDisabled(true);
        }
      }
    }

    /*
		     * *************************************************************************
		     * Add address to the lead - Office Depot
		     * *************************************************************************
		     */

        String asnSiteId = pageContext.getParameter("ASNReqFrmSiteId");
        String asnSiteName = null;

        if (asnSiteId != null)
        {
            String siteNameSql = "select hz_format_pub.format_address( ps.location_id, null, null, ', ', null, null, null, null) Address from hz_party_sites ps where party_site_id = :1";
            oracle.jbo.ViewObject siteNamevo = oam.findViewObject("SiteNameVO");
            if (siteNamevo == null )
            {
              siteNamevo = oam.createViewObjectFromQueryStmt("SiteNameVO", siteNameSql);
            }

            if (siteNamevo != null)
            {
                siteNamevo.setWhereClauseParam(0,asnSiteId);
                siteNamevo.executeQuery();
                siteNamevo.first();
                asnSiteName = siteNamevo.getCurrentRow().getAttribute(0).toString();
                siteNamevo.remove();
            }



        }
        pageContext.writeDiagnostics(METHOD_NAME, "ASNReqFrmSiteId : "+asnSiteId, OAFwkConstants.PROCEDURE);
        pageContext.writeDiagnostics(METHOD_NAME, "asnSiteName : "+asnSiteName, OAFwkConstants.PROCEDURE);



		    String selPSId = pageContext.getParameter("ASNReqSelPartySiteId");
		    String selAddress = pageContext.getParameter("ASNReqSelAddress");
        if (selPSId == null)
        selPSId = asnSiteId;
        if (selAddress == null)
        selAddress = asnSiteName;


		    if(selPSId != null && selAddress != null)
		    {
				ViewObject vo = pageContext.getApplicationModule(webBean).findViewObject("LeadCreateVO");
	if(vo == null)
				{
				 MessageToken[] tokens = { new MessageToken("NAME", "LeadCreateVO") };
			 		  throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", tokens);
				}

				Row row = vo.first();
                //                   Row row = vo.getCurrentRow();
	pageContext.writeDiagnostics(METHOD_NAME, "row settting : address details"+row.getAttribute("AddressDetails"), OAFwkConstants.PROCEDURE);
pageContext.writeDiagnostics(METHOD_NAME, "row settting : address details"+row.getAttribute("AddressId"), OAFwkConstants.PROCEDURE);
                row.setAttribute("AddressDetails", selAddress);
				row.setAttribute("AddressId",selPSId);
        pageContext.writeDiagnostics(METHOD_NAME, "row settting : address details"+row.getAttribute("AddressDetails"), OAFwkConstants.PROCEDURE);
pageContext.writeDiagnostics(METHOD_NAME, "row setting : address details"+row.getAttribute("AddressId"), OAFwkConstants.PROCEDURE);

	   pageContext.putTransactionValue("OD_LEAD_ADDRESS_ID",selPSId );
	}

    if (isProcLogEnabled)
    {
    pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }
  }

  // Fix for bug 4040174 - This is so that processing continues after
  // a warning message is encountered.
  /**
   * Procedure that is called upon form submit.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */

  public void processFormData(OAPageContext pageContext, OAWebBean webBean)
  {
    final String METHOD_NAME = "asn.lead.webui.ODLeadCrteCO.processFormData";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);

    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    pageContext.setSkipProcessFormRequestForMessageLevel(OAException.ERROR);
    super.processFormData(pageContext, webBean);

    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }
  }

  /**
   * Procedure to handle form submissions for form elements in AK region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    final String METHOD_NAME = "asn.lead.webui.ODLeadCrteCO.processFormRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);

    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processFormRequest(pageContext, webBean);



    //  Set the current page function name
    pageContext.putParameter("ASNReqFrmFuncName", "ASN_LEADCRTEPG");

    //  Get the Application module
    OAApplicationModule oam = pageContext.getApplicationModule(webBean);

    //  Get the page action event that has caused the submit
    String actEvt = pageContext.getParameter("ASNReqPgAct");

	// Debug Logging
    if (isStatLogEnabled)
    {
      StringBuffer buf = new StringBuffer(200);
      buf.append(" value of Context parameter ASNReqPgAct - actEvt : ");
      buf.append(actEvt);
      pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
    } // End Debug Logging

    //  Handle the applciation logic for each event
    if(pageContext.getParameter("ASNPageApyButton")!=null)
    {
      //Anirban: starts fix for the defect#15033.

	  ViewObject voAddressDetails = pageContext.getApplicationModule(webBean).findViewObject("LeadCreateVO");
	  if(voAddressDetails == null)
	  {
	   MessageToken[] tokens = { new MessageToken("NAME", "LeadCreateVO") };
	   throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", tokens);
	  }
      Row rowAddressDetails = voAddressDetails.first();
      String banAddressDetails = (String)rowAddressDetails.getAttribute("AddressDetails");
      pageContext.writeDiagnostics(METHOD_NAME, "Anirban22May: address is: "+banAddressDetails, OAFwkConstants.STATEMENT);

      if (banAddressDetails==null || "".equals(banAddressDetails))
	  {
		  throw new OAException("Please note, you must select an address of the customer before continuing.");
	  }

      //Anirban: ends fix for the defect#15033.

      // Apply button is clicked
      HashMap leadInfo = (HashMap)oam.invokeMethod("getLeadInfo");

      // Debug Logging
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(200);
        buf.append(" Apply Button - value of leadInfo Hashmap : ");
        buf.append(leadInfo.toString());
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      } // End Debug Logging

      String leadId = null;
      String customerId = null;
      if(leadInfo!=null)
      {
        leadId = (String)leadInfo.get("SalesLeadId");
        customerId = (String)leadInfo.get("CustomerId");
        this.doCommit(pageContext, false);

		   //Office depot -save address id
			      String addressID = null;
			       addressID = (String)pageContext.getTransactionValue("OD_LEAD_ADDRESS_ID");


			       OAViewObject oaVO = (OAViewObject)oam.findViewObject("LeadHeaderDetailsVO");
			       if ( oaVO == null )
			       oaVO = (OAViewObject)oam.createViewObject("LeadHeaderDetailsVO",
			                "oracle.apps.asn.lead.server.LeadHeaderDetailsVO");
			       LeadHeaderDetailsVOImpl   LeadHeaderDetailsVO = (LeadHeaderDetailsVOImpl)oaVO;
			       LeadHeaderDetailsVO.initQuery(leadId);
			       LeadHeaderDetailsVORowImpl detailRow = (LeadHeaderDetailsVORowImpl) LeadHeaderDetailsVO.first();

			        if (addressID!=null)
			        {
			          detailRow.setAddressId(new Number(new Long(addressID)));
				    }

			       oam.getTransaction().commit();

			//Office depot -save address id

			      pageContext.putParameter("ASNReqPgAct","LEADDET");
			      pageContext.putParameter("ASNReqNewSelectionFlag", "Y");


			      HashMap conditions = new HashMap(2);
			      conditions.put(ASNUIConstants.BC_CURRENT_LINK,ASNUIConstants.BC_CURRENT_LINK_REMOVE);

			      HashMap urlParams = new HashMap(2);
			      urlParams.put("ASNReqFrmLeadId", leadId);
                  urlParams.put("ASNReqFrmCustId", customerId);

                    // Debug Logging
				  				          if (isStatLogEnabled)
				  				          {
				  				            StringBuffer buf = new StringBuffer(200);
				  				            buf.append(" Apply Button - Parameters being passed to processTargetURL -  ");
				  				            buf.append(" conditions : ");
				  				            buf.append(conditions.toString());
				  				            buf.append(" urlParams : ");
				  				            buf.append(urlParams.toString());
				  				            pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
				          }// End Debug Logging

				  			      if (isStatLogEnabled)
				  			        {
				  			          StringBuffer   buf2 = new StringBuffer(400);
				  			           buf2.append("  Apply button Selected.  ");
				  			           buf2.append(" ,Lead ID = ");
				  			           buf2.append(leadId);
				  			           buf2.append(" :  Value of parameter ASNReqPgAct = LEADDET");
				  			           pageContext.writeDiagnostics(METHOD_NAME, buf2.toString(), OAFwkConstants.STATEMENT);
				  			        }


	      this.processTargetURL(pageContext,conditions, urlParams);

      }
    }
    else if(pageContext.getParameter("ASNPageCnclButton")!=null) //Cancel Button is clicked
    {
       
      this.doRollback(pageContext);
      this.processTargetURL(pageContext, null, null);
     
    }
    else if(pageContext.getParameter("ASNCustSelButton")!=null)
    {
      // Customer Selection Button is clicked
      pageContext.putParameter("ASNReqPgAct", "SUBFLOW");
      HashMap conditions = new HashMap(3);
      conditions.put(ASNUIConstants.RETAIN_AM, "Y");
      conditions.put(ASNUIConstants.BC_CURRENT_LINK, ASNUIConstants.BC_CURRENT_LINK_REMOVE);

      // set the required sub-flow specific parameters
      HashMap urlParams = new HashMap(2);
      urlParams.put("ASNReqFrmFuncName", "ASN_ORGLOVPG");
       // urlParams.put("ASNReqFrmFuncName", "ASN_CUSTSEARCHPG");
      // Debug Logging
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(200);
        buf.append(" Customer Selection Button - Parameters being passed to processTargetURL -  ");
        buf.append(" conditions : ");
        buf.append(conditions.toString());
        buf.append(" urlParams : ");
        buf.append(urlParams.toString());
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      } // End Debug Logging

      this.processTargetURL(pageContext, conditions, urlParams);
    }
    else if(pageContext.getParameter("ASNCtctSelButton")!=null)
    {
      // Contact Selection Button is clicked
      HashMap leadInfo = (HashMap)oam.invokeMethod("getLeadInfo");

      // Debug Logging
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(200);
        buf.append(" Contact Selection Button - value of leadInfo Hashmap : ");
        buf.append(leadInfo.toString());
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      } // End Debug Logging

      String customerId = null;
      if(leadInfo!=null)
      {
        customerId = (String)leadInfo.get("CustomerId");
      }

      if(customerId==null)
        throw new OAException("ASN","ASN_CMMN_CTCT_REQCUST_ERR");

      pageContext.putParameter("ASNReqPgAct", "SUBFLOW");
      HashMap conditions = new HashMap(3);
      conditions.put(ASNUIConstants.RETAIN_AM, "Y");
      conditions.put(ASNUIConstants.BC_CURRENT_LINK, ASNUIConstants.BC_CURRENT_LINK_REMOVE);

      // set the required sub-flow specific parameters
      HashMap urlParams = new HashMap(3);
      urlParams.put("ASNReqFrmFuncName", "ASN_CTCTLOVPG");
      urlParams.put("ASNReqFrmCustId", customerId);

      /* Include Custom code to set the Match Rule Attributes for Party Number and Address */

      /* Get the Match Rule name from the profile option HZ: Match Rule for Contact Simple Search */
      String ctctSimpleMatchRuleId = (String) pageContext.getProfile("HZ_DQM_CON_SIMPLE_MATCHRULE");

      /* Get the address ID */
      String addressid = (String)pageContext.getTransactionValue("OD_LEAD_ADDRESS_ID");

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

      // Debug Logging
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(200);
        buf.append(" Contact Selection Button - Parameters being passed to processTargetURL -  ");
        buf.append(" conditions : ");
        buf.append(conditions.toString());
        buf.append(" urlParams : ");
        buf.append(urlParams.toString());
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      } // End Debug Logging

      this.processTargetURL(pageContext, conditions, urlParams);
    }

  if(pageContext.getParameter("ODASNAddressSelButton") != null)
    {
       // OD -- Checking for customer selection
       HashMap leadInf = (HashMap)oam.invokeMethod("getLeadInfo");
	  	    String custID = (String)leadInf.get("CustomerId");
              if (custID ==null)
              {throw new OAException("XXCRM", "XX_SFA_053_CUST_NOTSELECTED");}

         pageContext.putParameter("ASNReqPgAct","SUBFLOW");

     /* Office Depot lead creation address changes */
	        ViewObject vo = pageContext.getApplicationModule(webBean).findViewObject("LeadCreateVO");
			 		if(vo == null)
			 		{
			 		  MessageToken[] tokens = { new MessageToken("NAME", "LeadCreateVO") };
			 		  throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", tokens);
			 		}

			    Row row = vo.first();
				row.setAttribute("AddressDetails", pageContext.getParameter("ASNReqSelAddress"));
                                row.setAttribute("AddressId",pageContext.getParameter("ASNReqSelPartySiteId"));
	      HashMap conditions = new HashMap();
	      conditions.put(ASNUIConstants.RETAIN_AM,"Y");
	      conditions.put(ASNUIConstants.BC_CURRENT_LINK,ASNUIConstants.BC_CURRENT_LINK_REMOVE);


	      HashMap urlParams = new HashMap();
	    //  urlParams.put("ASNReqFrmFuncName","ASN_ORGLOVPG");
	    urlParams.put("ASNReqFrmFuncName","ASN_PTYADDRSELPG");
		 urlParams.put("ASNReqFrmCustId",custID);



	      if (isStatLogEnabled)
	        {
	          StringBuffer  buf = new StringBuffer(200);
	          buf.append(" Select Customer Page Button Clicked. Retain AM parameter set to  ");
	           buf.append(ASNUIConstants.RETAIN_AM);
	           pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
	        }

	      this.processTargetURL(pageContext,conditions, urlParams);
	    }





    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }
  }
}
