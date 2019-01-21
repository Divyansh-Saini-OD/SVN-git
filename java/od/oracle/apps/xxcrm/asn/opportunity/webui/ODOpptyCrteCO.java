/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODOpptyCrteCO.java                                            |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Page Controller class for Create Opportunity Page.                     |
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
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.opportunity.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.OAStaticStyledTextBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.asn.common.fwk.webui.ASNControllerObjectImpl;
import com.sun.java.util.collections.HashMap;
import oracle.apps.asn.common.fwk.webui.ASNUIConstants;
import java.io.Serializable;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAException;
import oracle.jbo.ViewObject;
import oracle.jbo.Row;
import oracle.apps.asn.opportunity.server.*;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.jbo.domain.Number;

/**
 * Controller for ...
 */
public class ODOpptyCrteCO extends ASNControllerObjectImpl
{
  public static final String RCS_ID="$Header: /home/cvs/repository/Office_Depot/SRC/CRM/E1307_SiteLevel_Attributes_ASN/3.\040Source\040Code\040&\040Install\040Files/E1307D_SiteLevel_Attributes_(LeadOpp_CreateUpdate)/ODOpptyCrteCO.java,v 1.2 2007/10/18 17:39:43 ssatya Exp $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "od.oracle.apps.xxcrm.asn.opportunity.webui");

  /**
   * Layout and page setup logic for AK region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    final String METHOD_NAME = "xxcrm.asn.opportunity.webui.OpptyCrteCO.processRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);


    if (isProcLogEnabled)
    {
     pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processRequest(pageContext, webBean);


    //OD customization
		ViewObject oppVO = pageContext.getApplicationModule(webBean).findViewObject("OpportunityCreateVO1");
		if(oppVO != null)
    {
      if (oppVO.getAttributeCount() == oracle.jbo.server.ViewDefImpl.getMaxAttrConst("oracle.apps.asn.opportunity.server.OpportunityCreateVO"))
      {
        oppVO.addDynamicAttribute("AddressId");
        oppVO.addDynamicAttribute("AddressDetails");
      }
    }


    /*
     * Run the query or create object here
     */
    OAApplicationModule am = (OAApplicationModule) pageContext.getApplicationModule(webBean);
    if(!this.isViewObjectQueried(am, "OpportunityCreateVO1"))
      {
        this.doRollback(pageContext);

         if(am != null)
         {
            am.invokeMethod("createOpportunity");
         }
      }

      HashMap opptyInfo = (HashMap)am.invokeMethod("getOpptyInfo");
      String LeadId = null;
      if(opptyInfo!=null)
      {
        LeadId = (String)opptyInfo.get("leadId");
      }


     //  String LeadId = (String) am.invokeMethod("getId");
       if (LeadId !=null)
       {


    // select customer
  //  String selCustId = pageContext.getParameter("ASNReqSelCustId");
//    String selCustName = pageContext.getParameter("ASNReqSelCustName");
 //   String selCustId = "1000";
   // String selCustName = "World of Business";
      // getting customer ID
/////////////////////
        String selCustId = pageContext.getParameter("ASNReqSelCustId");
        String selCustName = null;
        if(selCustId!=null && !("".equals(selCustId.trim())))
        {
          selCustName = pageContext.getParameter("ASNReqSelCustName");
        }
        else
        {
          String custId = (String)opptyInfo.get("CustomerId");
          if(custId!=null)
          {
            selCustId = custId;
            selCustName = (String)opptyInfo.get("PartyName");
          }

        }



///////////

    if(selCustId != null && selCustName != null)
    {
      Serializable [] params = {selCustId, selCustName};
      if (isStatLogEnabled)
       {
           StringBuffer buf = new StringBuffer(200);
          buf.append("Customer ID= ");
          buf.append(selCustId);
          buf.append("  ,Customer Name= ");
          buf.append(selCustName);
          pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
        }



      am.invokeMethod("selectCustomer", params);
    }

    /*
     * Change the page UI here.
     */
    //close reason display
    OAMessageChoiceBean closeReason = (OAMessageChoiceBean) webBean.findIndexedChildRecursive("ASNOpptyCrteRsn");
    OAMessageChoiceBean status = (OAMessageChoiceBean) webBean.findIndexedChildRecursive("ASNOpptyCrteStatus");
    if(closeReason != null && status != null)
    {
      if(status.isRendered())
      {
        closeReason.setRendered(true);
      }
    }


    // Change for customer name.

   OAMessageTextInputBean mainCustName = (OAMessageTextInputBean) webBean.findIndexedChildRecursive("ASNOpptyCrteCust");
   String selectCustText = pageContext.getMessage("ASN", "ASN_CMMN_NO_CUST_SEL", null);

   Serializable [] selParams = {selCustId, selCustName,selectCustText};
   if (mainCustName !=null)
   {
     String custRenderProp = (String) am.invokeMethod("setCustomerText",selParams);
      if (isStatLogEnabled)
       {   StringBuffer  buf = new StringBuffer(200);
           buf.append(" ,Customer Render = ");
           buf.append(custRenderProp);

           pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
        }
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

    /*
     * *************************************************************************
     * Add address to the opportunity - OD
     * *************************************************************************
     */

        String asnSiteId = pageContext.getParameter("ASNReqFrmSiteId");
        String asnSiteName = null;

        if (asnSiteId != null)
        {
            String siteNameSql = "select hz_format_pub.format_address( ps.location_id, null, null, ', ', null, null, null, null) Address from hz_party_sites ps where party_site_id = :1";
            oracle.jbo.ViewObject siteNamevo = am.findViewObject("SiteNameVO");
            if (siteNamevo == null )
            {
              siteNamevo = am.createViewObjectFromQueryStmt("SiteNameVO", siteNameSql);
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
		ViewObject vo = pageContext.getApplicationModule(webBean).findViewObject("OpportunityCreateVO1");
		if(vo == null)
		{
		  MessageToken[] tokens = { new MessageToken("NAME", "OpportunityCreateVO1") };
		  throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", tokens);
		}

		Row row = vo.first();
		row.setAttribute("AddressDetails", selAddress);
		row.setAttribute("AddressId",selPSId);

    pageContext.putTransactionValue("OD_OPPORTUNITY_ADDRESS_ID",selPSId );
	}
/* Commeting out since this requirement was taken out from the FDD
 * // UI scorecard Changes.

     //remove required icon from currency
    OAMessageChoiceBean currencyBean = (OAMessageChoiceBean)webBean.findIndexedChildRecursive("ASNOpptyCrteCurr");
    if(currencyBean != null)
    {
      currencyBean.setRequiredIcon("");
    }


     //remove required icon from status
    OAMessageChoiceBean statusBean = (OAMessageChoiceBean)webBean.findIndexedChildRecursive("ASNOpptyCrteStatus");
    if(statusBean != null)
    {
      statusBean.setRequiredIcon("");
    }

 //remove required icon from win probability
    OAMessageChoiceBean winProbBean = (OAMessageChoiceBean)webBean.findIndexedChildRecursive("ASNOpptyCrteWinProb");
    if(winProbBean != null)
    {
      winProbBean.setRequiredIcon("");
    }

    //End of UI scorecard changes.
 */

    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }
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
    pageContext.setSkipProcessFormRequestForMessageLevel(OAException.ERROR);
    super.processFormData(pageContext, webBean);
  }


  /**
   * Procedure to handle form submissions for form elements in
   * AK region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    final String METHOD_NAME = "asn.opportunity.webui.OpptyCrteCO.processRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);


    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processFormRequest(pageContext, webBean);
    pageContext.putParameter("ASNReqFrmFuncName","ASN_OPPTYCRTEPG");

    /*
     * Retrieve common variables here.
     * E.g. Application Module and Event Action
     */
    OAApplicationModule am = (OAApplicationModule) pageContext.getApplicationModule(webBean);
    String pageEvent = pageContext.getParameter("ASNReqPgAct");

    // address selection --OD
    HashMap opptyInfo = (HashMap)am.invokeMethod("getOpptyInfo");
    if(pageContext.getParameter("ASNAddrSelButton") != null)
    {
      String customerId  = (String)opptyInfo.get("CustomerId");
      pageContext.putParameter("ASNReqPgAct","SUBFLOW");
       if (customerId== null)
	  	                 {
 				 throw new OAException("XXCRM", "XX_SFA_053_CUST_NOTSELECTED");
					 }


      HashMap conditions = new HashMap();
      conditions.put(ASNUIConstants.BC_CURRENT_LINK,
                     ASNUIConstants.BC_CURRENT_LINK_RP_TEXT);
      conditions.put(ASNUIConstants.BC_CURRENT_LINK_TEXT,"Create Opportunity");
      conditions.put(ASNUIConstants.RETAIN_AM,"Y");

      HashMap urlParams = new HashMap();
      urlParams.put("ASNReqFrmFuncName","ASN_PTYADDRSELPG");
      urlParams.put("ASNReqFrmCustId",customerId);

      this.processTargetURL(pageContext,conditions, urlParams);
    }


    if(pageContext.getParameter("ASNCustSelButton") != null)
    {
      pageContext.putParameter("ASNReqPgAct","SUBFLOW");

         /* OD changes */
         ViewObject vo = pageContext.getApplicationModule(webBean).findViewObject("OpportunityCreateVO1");
		 		if(vo == null)
		 		{
		 		  MessageToken[] tokens = { new MessageToken("NAME", "OpportunityCreateVO1") };
		 		  throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", tokens);
		 		}

		    Row row = vo.first();
	  	  	row.setAttribute("AddressDetails","");
	  		row.setAttribute("AddressId","");

      HashMap conditions = new HashMap();
      conditions.put(ASNUIConstants.RETAIN_AM,"Y");
      conditions.put(ASNUIConstants.BC_CURRENT_LINK,ASNUIConstants.BC_CURRENT_LINK_REMOVE);

      HashMap urlParams = new HashMap();
      urlParams.put("ASNReqFrmFuncName","ASN_ORGLOVPG");
      //urlParams.put("ASNReqFrmFuncName","ASN_CUSTSEARCH_GLOBAL");

      if (isStatLogEnabled)
        {
          StringBuffer  buf = new StringBuffer(200);
          buf.append(" Select Customer Page Button Clicked. Retain AM parameter set to  ");
           buf.append(ASNUIConstants.RETAIN_AM);
           pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
        }

      this.processTargetURL(pageContext,conditions, urlParams);
    }

     if (pageContext.getParameter("ASNAddrSelButton") != null)
		    {
				OAMessageTextInputBean custName = (OAMessageTextInputBean) webBean.findIndexedChildRecursive("ASNOpptyCrteCust");
	               if (custName == null)
	                 {

				 		  throw new OAException("ASN", "XX_ASN_CUSTOMER_NOTSELECTED");
					 }
	    }

    if(pageContext.getParameter("ASNPageCnclButton") != null)
    {
       if (isStatLogEnabled)
        {
          StringBuffer   buf = new StringBuffer(200);
           buf.append(" Select Customer Page -> Cancel button Selected.  ");
           pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
        }

      am.getTransaction().rollback();
      processTargetURL(pageContext,null,null);
    }

    if(pageContext.getParameter("ASNPageApyButton") != null)
    {
      //doCommit(pageContext);
      doCommit(pageContext, false);
      String idStr = (String) am.invokeMethod("getId");


      //OD -save address id
      String addressID = null;
      addressID = (String)pageContext.getTransactionValue("OD_OPPORTUNITY_ADDRESS_ID");

       OAViewObject oaVO = (OAViewObject)am.findViewObject("OpportunityDetailsVO");
if (oaVO == null) pageContext.writeDiagnostics(METHOD_NAME,"sudeept oaVO is null",OAFwkConstants.PROCEDURE);
       if ( oaVO == null )
       oaVO = (OAViewObject)am.createViewObject("OpportunityDetailsVO",
                "oracle.apps.asn.opportunity.server.OpportunityDetailsVO");
       OpportunityDetailsVOImpl   OpportunityDetailsVO = (OpportunityDetailsVOImpl)oaVO;
 pageContext.writeDiagnostics(METHOD_NAME,"sudeept before initQuery",OAFwkConstants.PROCEDURE);
OpportunityDetailsVO.initQuery(idStr);
 pageContext.writeDiagnostics(METHOD_NAME,"sudeept after  initQuery",OAFwkConstants.PROCEDURE);

       OpportunityDetailsVORowImpl detailRow = (OpportunityDetailsVORowImpl) OpportunityDetailsVO.first();

       if (addressID !=null)
       {
         detailRow.setAddressId(new Number(new Long(addressID)));
       }

         StringBuffer   buf1 = new StringBuffer(200);
           buf1.append(" OD >>> AddressID >>> " + addressID + " " + idStr);
           pageContext.writeDiagnostics(METHOD_NAME, buf1.toString(), OAFwkConstants.STATEMENT);

       am.getTransaction().commit();

       //OD -save address id

      pageContext.putParameter("ASNReqPgAct","OPPTYDET");

      if (isStatLogEnabled)
        {
          StringBuffer   buf = new StringBuffer(400);
           buf.append("  Apply button Selected.  ");
           buf.append(" ,Opportunity ID = ");
           buf.append(idStr);
           buf.append(" :  Value of parameter ASNReqPgAct = OPPTYDET");
           pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
        }


      HashMap conditions = new HashMap();
      conditions.put(ASNUIConstants.BC_CURRENT_LINK,ASNUIConstants.BC_CURRENT_LINK_REMOVE);

      HashMap urlParams = new HashMap();
      urlParams.put("ASNReqFrmOpptyId",idStr);

      this.processTargetURL(pageContext,conditions, urlParams);
    }

    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }
  }

}
