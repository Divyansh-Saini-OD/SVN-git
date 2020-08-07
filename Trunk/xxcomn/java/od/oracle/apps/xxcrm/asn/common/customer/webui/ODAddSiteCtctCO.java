/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODAddSiteCtctCO.java                                          |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Page Controller class for ODAddSiteCtctPG.                             |
 |                                                                           |
 |  NOTES                                                                    |
 |         Used for the Add Site Contact Page                                |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    No dependencies.                                                       |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |   21-Sep-2007 Jasmine Sujithra   Created                                  |
 |   17-Dec-2007 Jasmine Sujithra   Updated For Cancel Button                |
 |   26-Dec-2007 Jasmine Sujithra   Updated for returning to View/Update     |
 |                                  Site Pages after Creating a Contact      | 
 |   14-Feb-2008 Jasmine Sujithra   Hide create Contact button when access to|
 |                                  Party is read only                       |     
 |   04-Mar-2008 Jasmine Sujithra   Updated for breadcrumbs                  |
 +===========================================================================*/

package od.oracle.apps.xxcrm.asn.common.customer.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.asn.common.fwk.webui.ASNControllerObjectImpl;
import oracle.apps.fnd.framework.webui.beans.OABodyBean;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAApplicationModule;
import java.io.Serializable;
import oracle.apps.fnd.common.MessageToken;
import com.sun.java.util.collections.HashMap;
import oracle.apps.asn.common.fwk.webui.ASNUIConstants;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.nav.OABreadCrumbsBean;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.beans.nav.OAPageButtonBarBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;

/**
 * Controller for ...
 */
public class ODAddSiteCtctCO extends ASNControllerObjectImpl
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
      String s = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODAddSiteCtctCO.processRequest";
      pageContext.writeDiagnostics(s, "Begin", 2);
      super.processRequest(pageContext, webBean);
      ((OAPageLayoutBean)webBean).setBreadCrumbEnabled(false);

      /* First call in this transaction -- hence store all URL Parameters as Transaction Variables*/
      if (pageContext.getTransactionValue("ASNCallingPageTxn")== null)
      {

       pageContext.putTransactionValue("ASNCallingPageTxn", pageContext.getParameter("ASNReqCtxtFuncName"));
        pageContext.putTransactionValue("ASNReqFrmCustIdTxn", pageContext.getParameter("ASNReqFrmCustId"));
        pageContext.putTransactionValue("ASNReqFrmSiteIdTxn", pageContext.getParameter("ASNReqFrmSiteId"));
        pageContext.putTransactionValue("ASNReqFrmRelIdTxn", pageContext.getParameter("ASNReqFrmRelId"));
        pageContext.putTransactionValue("ASNReqFrmRelPtyIdTxn", pageContext.getParameter("ASNReqFrmRelPtyId"));
        pageContext.putTransactionValue("ASNReqFrmCustNameTxn", pageContext.getParameter("ASNReqFrmCustName"));
        pageContext.putTransactionValue("ASNReqFrmCtctNameTxn", pageContext.getParameter("ASNReqFrmCtctName"));
        pageContext.putTransactionValue("ASNReqFrmCtctIdTxn", pageContext.getParameter("ASNReqFrmCtctId"));

      }

      OAWebBean bodyBean = pageContext.getRootWebBean();
      if (bodyBean!=null && bodyBean instanceof OABodyBean)
      {
        ((OABodyBean)bodyBean).setBlockOnEverySubmit(true);
      }

      /* To Be removed after Testing is complete */
      String partyId = "479543";
      String partySiteId = "259783";
      if (pageContext.getTransactionValue("ASNReqFrmCustIdTxn") == null)
      {
       pageContext.putTransactionValue("ASNReqFrmCustIdTxn", partyId);
      }

      if (pageContext.getTransactionValue("ASNReqFrmSiteIdTxn") == null)
      {
       pageContext.putTransactionValue("ASNReqFrmSiteIdTxn", partySiteId);
      }



      String custId =pageContext.getParameter("ASNReqFrmCustId");
      if (custId == null)
      {

        pageContext.writeDiagnostics(s, "In processRequest ASNReqFrmCustId is null", 2);
        pageContext.putParameter("ASNReqFrmCustId",pageContext.getTransactionValue("ASNReqFrmCustIdTxn"));
        pageContext.writeDiagnostics(s, "PartyId :", 2);
        pageContext.writeDiagnostics(s, partyId, 2);
      }

      //If it is a subflow page, need to retain context parameters here
      retainContextParameters(pageContext);
      String ctctSimpleMatchRuleId = /*"10002";*/  (String) pageContext.getProfile("HZ_DQM_CON_SIMPLE_MATCHRULE");
      String orgPartyId = pageContext.getParameter("ASNReqFrmCustId");

      if ( orgPartyId == null )  {
          OAException e = new OAException("ASN", "ASN_TCA_CUSTPARAM_MISS_ERR");
          pageContext.putDialogMessage(e);
      }else{
          pageContext.putParameter("HzPuiContactObjectId", orgPartyId);
      }

      String orgPartyName = pageContext.getParameter("ASNReqFrmCustName");
      if(orgPartyName == null) {
	       OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);
	       Serializable[] parameters =  { orgPartyId };
	       orgPartyName = (String) am.invokeMethod("getPartyNameFromId", parameters);
      }

      String orgPartySiteId = pageContext.getParameter("ASNReqFrmSiteId");
      if (orgPartySiteId == null )
      {
         pageContext.writeDiagnostics(s, "In processRequest ASNReqFrmSiteId is null", 2);
         pageContext.putParameter("ASNReqFrmSiteId",pageContext.getTransactionValue("ASNReqFrmSiteIdTxn"));
      }

      orgPartySiteId =  pageContext.getParameter("ASNReqFrmSiteId");

      OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);
	    Serializable[] parameters =  { orgPartySiteId };
      pageContext.writeDiagnostics(s, "Before call to getPartySiteDetFromId orgPartySiteId :", 2);
      pageContext.writeDiagnostics(s, orgPartySiteId, 2);
	    String orgPartySiteDet = (String) am.invokeMethod("getPartySiteDetFromId", parameters);
      String titleData = orgPartyName+ " - " +orgPartySiteDet;
      titleData = titleData.trim();
      MessageToken[] tokens = { new MessageToken("PARTYSITENAME", titleData)};
      String pageTitle = pageContext.getMessage("XXCRM", "XX_SFA_056_ADD_SITE_CTCT_TITLE", tokens);

      // Set the page title (which also appears in the breadcrumbs)
      pageContext.getPageLayoutBean().setTitle(pageTitle);
      

      /* Contact Security - Start */
      /* Display the Create Contact Button only if the user has Update access to the Party */
      String custAccMode =pageContext.getParameter("ASNReqFrmCustAccMode");
       if ("101lOl11O".equals(custAccMode))
      {
        /* Read Only access to the party hence do not display the Create Contact Button */
      
        OAPageButtonBarBean PageButtonsRN = (OAPageButtonBarBean) webBean.findChildRecursive("ASNPageButtonRN");       
        if(PageButtonsRN != null)
        {
          OASubmitButtonBean createContactButton = (OASubmitButtonBean)PageButtonsRN.findChildRecursive("ASNCreateCtctBtn");
          if(createContactButton != null)
          {
            createContactButton.setRendered(false);
          }
        }
      
      }
      /* Contact Security - End */

      
      pageContext.putParameter("HzPuiSimpleMatchRuleId", ctctSimpleMatchRuleId);
      pageContext.putParameter("HzPuiSearchType", "SINGLE");

      pageContext.writeDiagnostics(s, "After call to getPartySiteDetFromId orgPartySiteId :", 2);
      pageContext.writeDiagnostics(s, orgPartySiteId, 2);
      //OAViewObject vo = (OAViewObject)am.findViewObject("ODContactListVO");
      OAViewObject vo = (OAViewObject)am.findViewObject("ODHzPartySiteContactsVO");

      if (vo == null)
      {
          MessageToken[] token = { new MessageToken("OBJECT_NAME", "ODHzPartySiteContactsVO") };
          throw new OAException("AK", "FWK_TBX_OBJECT_NOT_FOUND", token);
      }

      Serializable[] params  = { orgPartyId,orgPartySiteId };
      pageContext.writeDiagnostics(s, "Before initQuery orgPartyId and orgPartySiteId : ", 2);
      pageContext.writeDiagnostics(s, orgPartyId, 2);
      pageContext.writeDiagnostics(s, orgPartySiteId, 2);
      vo.invokeMethod("initQuery", params);

      pageContext.putTransactionValue("ASNTxnReturnUrl", getModifiedCurrentUrlForRedirect(pageContext, false));

  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormRequest(pageContext, webBean);
    pageContext.putParameter("ASNReqFrmFuncName","OD_ASN_ADDSITECTCTPG");

    String s = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODAddSiteCtctCO.processFormRequest";
    pageContext.writeDiagnostics(s, "Begin", 2);
    String ctctSimpleMatchRuleId = /*"10002";*/  (String) pageContext.getProfile("HZ_DQM_CON_SIMPLE_MATCHRULE");

    String orgPartyId = pageContext.getParameter("ASNReqFrmCustId");
    if (orgPartyId == null)
    {
      pageContext.writeDiagnostics(s, "In processFormRequest ASNReqFrmCustId is null", 2);
      orgPartyId= (String)pageContext.getTransactionValue("ASNReqFrmCustIdTxn");
      pageContext.putParameter("ASNReqFrmCustId",orgPartyId);
    }

    String partySiteId = pageContext.getParameter("ASNReqFrmSiteId");
    if (partySiteId == null )
    {
      pageContext.writeDiagnostics(s, "In processFormRequest ASNReqFrmSiteId is null", 2);
      partySiteId = (String)pageContext.getTransactionValue("ASNReqFrmSiteIdTxn");
      pageContext.putParameter("ASNReqFrmSiteId",partySiteId);
      pageContext.putParameter("ASNReqFrmRelId",pageContext.getTransactionValue("ASNReqFrmRelIdTxn"));
      pageContext.putParameter("ASNReqFrmRelPtyId",pageContext.getTransactionValue("ASNReqFrmRelPtyIdTxn"));
      pageContext.putParameter("ASNReqFrmCustName",pageContext.getTransactionValue("ASNReqFrmCustNameTxn"));
      pageContext.putParameter("ASNReqFrmCtctName",pageContext.getTransactionValue("ASNReqFrmCtctNameTxn"));
      pageContext.putParameter("ASNReqFrmCtctId",pageContext.getTransactionValue("ASNReqFrmCtctIdTxn"));
    }


    HashMap params = new HashMap();

    if(orgPartyId != null){
      pageContext.putParameter("HzPuiContactObjectId", orgPartyId);
    }
    pageContext.putParameter("HzPuiSimpleMatchRuleId", ctctSimpleMatchRuleId);
    pageContext.putParameter("HzPuiSearchType", "SINGLE");


    if (pageContext.getParameter("ASNPageSelBtn") != null)
    {
       /* Select Button is clicked */
        doCommit(pageContext);

        Serializable [] parameters = {orgPartyId, partySiteId};
        pageContext.writeDiagnostics(s, "Inside ASNPageSelBtn event ", 2);
        pageContext.writeDiagnostics(s, "Party Id :", 2);
        pageContext.writeDiagnostics(s, orgPartyId, 2);
        pageContext.writeDiagnostics(s, "Party Site Id", 2);
        pageContext.writeDiagnostics(s, partySiteId, 2);
        OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);
        am.invokeMethod("insertRecords", parameters);
        am.invokeMethod("applyTransaction");
        am.invokeMethod("clearContactsVOCache");
        HashMap conditions = new HashMap();
        conditions.put(ASNUIConstants.RETAIN_AM, "Y");

        /* Remove The Transaction Variables */
        pageContext.removeTransactionValue("ASNCallingPageTxn");
        pageContext.removeTransactionValue("ASNReqFrmCustIdTxn");
        pageContext.removeTransactionValue("ASNReqFrmSiteIdTxn");

        this.processTargetURL(pageContext,conditions,null);
    }
    else if(pageContext.getParameter("ASNPageCnclBtn") != null)
    {
       /* Cancel Button is clicked */
        OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);
        am.invokeMethod("clearContactsVOCache");
        //pageContext.putParameter("ASNReqPgAct","SUBFLOW");
        String callingpage = (String)pageContext.getTransactionValue("ASNCallingPageTxn");
        pageContext.writeDiagnostics(s, "Before Cancel ASNCallingPageTXN :  ", 2);
        pageContext.writeDiagnostics(s, callingpage, 2);
        //pageContext.putParameter("ASNReqFrmFuncName",callingpage);
        //retainContextParameters(pageContext);

        /* Remove The Transaction Variables */
        pageContext.removeTransactionValue("ASNCallingPageTxn");
        pageContext.removeTransactionValue("ASNReqFrmCustIdTxn");
        pageContext.removeTransactionValue("ASNReqFrmSiteIdTxn");


		    params.put("ASNReqPgAct",pageContext.getParameter("ASNReqPgAct"));
        params.put("ASNReqFrmCustId", pageContext.getParameter("ASNReqFrmCustId"));
        params.put("ASNReqFrmSiteId",  pageContext.getParameter("ASNReqFrmSiteId"));
        params.put("ASNReqFrmRelId",  pageContext.getParameter("ASNReqFrmRelId"));
        params.put("ASNReqFrmRelPtyId",  pageContext.getParameter("ASNReqFrmRelPtyId"));
        params.put("ASNReqFrmCustName",  pageContext.getParameter("ASNReqFrmCustName"));
        params.put("ASNReqFrmCtctName",  pageContext.getParameter("ASNReqFrmCtctName"));
        params.put("ASNReqFrmCtctId", pageContext.getParameter("ASNReqFrmCtctId"));
 //       params.put("ASNReqFrmFuncName", pageContext.getParameter("ASNReqFrmFuncName"));
 //VJ -Made the change for tracker issue 162
         params.put("ASNReqFrmFuncName",callingpage);



        this.processTargetURL(pageContext,null,null);
    }
    else if (pageContext.getParameter("ASNCreateCtctBtn") != null)
    {
       	 String partySID = (String) pageContext.getParameter("ASNReqFrmSiteId");
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
                // Create an contact in the context of an Site
                pageContext.writeDiagnostics(s, "Before doCommit ASNReqCtxtFuncName :  "+ pageContext.getParameter("ASNReqCtxtFuncName"), 2);
                pageContext.writeDiagnostics(s, "Before doCommit ASNReqFrmFuncName :  "+ pageContext.getParameter("ASNReqFrmFuncName"), 2);
                pageContext.putParameter("ASNReqFrmFuncName",pageContext.getParameter("ASNReqCtxtFuncName"));
                doCommit(pageContext);
                pageContext.writeDiagnostics(s, "After doCommit ASNReqCtxtFuncName :  "+ pageContext.getParameter("ASNReqCtxtFuncName"), 2);
                pageContext.writeDiagnostics(s, "After doCommit ASNReqFrmFuncName :  "+ pageContext.getParameter("ASNReqFrmFuncName"), 2);
                //doCommit(pageContext);
                OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);
                am.invokeMethod("clearContactsVOCache");

                retainContextParameters(pageContext);
                params.put("ASNReqFrmCustId", pageContext.getParameter("ASNReqFrmCustId"));
                params.put("ASNReqPgAct",pageContext.getParameter("ASNReqPgAct"));
                params.put("ASNReqFrmRelId",  pageContext.getParameter("ASNReqFrmRelId"));
                params.put("ASNReqFrmRelPtyId",  pageContext.getParameter("ASNReqFrmRelPtyId"));
                params.put("ASNReqFrmCustName",  pageContext.getParameter("ASNReqFrmCustName"));
                params.put("ASNReqFrmCtctId", pageContext.getParameter("ASNReqFrmCtctId"));
                params.put("ASNReqFrmCtctName",  pageContext.getParameter("ASNReqFrmCtctName"));
                params.put("ASNReqFrmSiteId",  pageContext.getParameter("ASNReqFrmSiteId"));
                /*
                params.put("HzPuiAddressEvent","UPDATE");
                params.put("HzPuiAddressPartySiteId",pageContext.getParameter("ASNReqFrmSiteId"));
                params.put("HzPuiAddressPartyId", pageContext.getParameter("ASNReqFrmCustId"));*/

                params.put("ASNReqFromLOVPage", "TRUE");
                params.put("ASNReqFrmFuncName", "ASN_CTCTCREATEPG");

                pageContext.writeDiagnostics(s, "Before Create Contact ASNReqFrmSiteId :  ", 2);
                pageContext.writeDiagnostics(s, pageContext.getParameter("ASNReqFrmSiteId"), 2);


                pageContext.putParameter("ASNReqPgAct","SUBFLOW");
                HashMap conditions = new HashMap();
                conditions.put(ASNUIConstants.RETAIN_AM, "Y");

                this.processTargetURL(pageContext,conditions,params);
             }
         }

    }
    else if ("ContactNameLinkEvt".equals(pageContext.getParameter(EVENT_PARAM)))
    {
        pageContext.writeDiagnostics(s, "Inside Contact Name Click Event ", 2);
        doCommit(pageContext);
        retainContextParameters(pageContext);

       /* params.put("ASNReqFrmCustId", pageContext.getParameter("ASNReqFrmCustId"));
		    params.put("ASNReqPgAct",pageContext.getParameter("ASNReqPgAct"));
        params.put("ASNReqFrmRelId",  pageContext.getParameter("ASNReqFrmRelId"));
        params.put("ASNReqFrmRelPtyId",  pageContext.getParameter("ASNReqFrmRelPtyId"));
        params.put("ASNReqFrmCustName",  pageContext.getParameter("ASNReqFrmCustName"));
        params.put("ASNReqFrmCtctId", pageContext.getParameter("ASNReqFrmCtctId"));
        params.put("ASNReqFrmCtctName",  pageContext.getParameter("ASNReqFrmCtctName"));
        params.put("ASNReqFrmSiteId",  pageContext.getParameter("ASNReqFrmSiteId"));
        params.put("ASNReqFrmFuncName", "ASN_CTCTSECURVIEWPG");*/

        params.put("ASNReqFrmCustId", pageContext.getParameter("ASNReqFrmCustId"));
		   // params.put("ASNReqPgAct",pageContext.getParameter("ASNReqPgAct"));
        params.put("ASNReqFrmRelId", pageContext.getParameter("RelationshipId"));// "725288");//
        params.put("ASNReqFrmRelPtyId", pageContext.getParameter("RelPartyId"));// "1778127");//
        params.put("ASNReqFrmCustName",  pageContext.getParameter("ASNReqFrmCustName"));
        params.put("ASNReqFrmCtctId", pageContext.getParameter("PartyId"));//"479543");//
        params.put("ASNReqFrmCtctName",  pageContext.getParameter("ASNReqFrmCtctName"));
        params.put("ASNReqFrmSiteId",  pageContext.getParameter("ASNReqFrmSiteId"));
        //params.put("ASNReqFrmFuncName", "ASN_CTCTSECURVIEWPG");
       // pageContext.putParameter("ASNReqPgAct","SUBFLOW");
        //doCommit(pageContext);
        //retainContextParameters(pageContext);


        StringBuffer logMsg = new StringBuffer(100);
        String ASNReqFrmCustId = pageContext.getParameter("ASNReqFrmCustId");
        String ASNReqPgAct = pageContext.getParameter("ASNReqPgAct");
        String ASNReqFrmRelId = pageContext.getParameter("RelationshipId");
        String ASNReqFrmRelPtyId = pageContext.getParameter("RelPartyId");
        String ASNReqFrmCustName = pageContext.getParameter("ASNReqFrmCustName");
        String ASNReqFrmCtctId = pageContext.getParameter("PartyId");
        String ASNReqFrmCtctName = pageContext.getParameter("ASNReqFrmCtctName");
        String ASNReqFrmSiteId = pageContext.getParameter("ASNReqFrmSiteId");
        String ASNReqFrmFuncName = pageContext.getParameter("ASNReqFrmFuncName");


        /*String ASNReqFrmCustId = (String)params.get("ASNReqFrmCustId");
        String ASNReqPgAct = pageContext.getParameter("ASNReqPgAct");
        String ASNReqFrmRelId = (String)params.get("ASNReqFrmRelId");
        String ASNReqFrmRelPtyId = (String)params.get("ASNReqFrmRelPtyId");
        String ASNReqFrmCustName = (String)params.get("ASNReqFrmCustName");
        String ASNReqFrmCtctId = (String)params.get("ASNReqFrmCtctId");
        String ASNReqFrmCtctName = (String)params.get("ASNReqFrmCtctName");
        String ASNReqFrmSiteId = (String)params.get("ASNReqFrmSiteId");
        String ASNReqFrmFuncName = (String)params.get("ASNReqFrmFuncName");*/

        logMsg.append("New uRL Param: ASNReqFrmCustId: ");
        logMsg.append(ASNReqFrmCustId);
        logMsg.append(" uRL Param: ASNReqPgAct: ");
        logMsg.append(ASNReqPgAct);
        logMsg.append(" uRL Param: ASNReqFrmRelId: ");
        logMsg.append(ASNReqFrmRelId);
        logMsg.append(" uRL Param: ASNReqFrmRelPtyId: ");
        logMsg.append(ASNReqFrmRelPtyId);
        logMsg.append(" uRL Param: ASNReqFrmCustName: ");
        logMsg.append(ASNReqFrmCustName);
        logMsg.append(" uRL Param: ASNReqFrmCtctId: ");
        logMsg.append(ASNReqFrmCtctId);
        logMsg.append(" uRL Param: ASNReqFrmCtctName: ");
        logMsg.append(ASNReqFrmCtctName);
        logMsg.append("uRL Param: ASNReqFrmSiteId: ");
        logMsg.append(ASNReqFrmSiteId);
        logMsg.append(" uRL Param: ASNReqFrmFuncName: ");
        logMsg.append(ASNReqFrmFuncName);
        //logMsg.append(" Bread Crumb : ");
        //logMsg.append(brdCrumb);
        pageContext.writeDiagnostics(METHOD_NAME, logMsg.toString(), OAFwkConstants.PROCEDURE);


        pageContext.writeDiagnostics(s, "Before Contact Name Click Event ASNReqFrmSiteId :  ", 2);
        pageContext.writeDiagnostics(s, pageContext.getParameter("ASNReqFrmSiteId"), 2);
        //modifyCurrentBreadcrumbLink(pageContext, false, null, true);


       HashMap conditions = new HashMap();
        conditions.put(ASNUIConstants.RETAIN_AM, "Y");
        //this.processTargetURL(pageContext,conditions,params);

       params.put("ASNReqFrmFuncName", "ASN_CTCTVIEWPG");
       //this.modifyCurrentBreadcrumbLink(pageContext, true, pageTitle, false);

       pageContext.forwardImmediately("ASN_CTCTVIEWPG",
                    KEEP_MENU_CONTEXT ,
                    null,
                    params,
                    false,
                    ADD_BREAD_CRUMB_YES);


      /*doCommit(pageContext);
      pageContext.putParameter("ASNReqPgAct","SUBFLOW");
      params.put("ASNReqFrmRelId",  pageContext.getParameter("RelationshipId"));
      params.put("ASNReqFrmRelPtyId",  pageContext.getParameter("RelPartyId"));
      params.put("ASNReqFrmCustId",  pageContext.getParameter("PartyId"));
      params.put("ASNReqFrmCustName",  pageContext.getParameter("PartyName"));
      params.put("ASNReqFrmCtctId", pageContext.getParameter("PartyId"));
      params.put("ASNReqFrmCtctName",  pageContext.getParameter("PartyName"));
      pageContext.forwardImmediately("ASN_CTCTSECURVIEWPG",
                                   KEEP_MENU_CONTEXT,
                                   null,
                                   params,
                                   true,
                                   ADD_BREAD_CRUMB_YES
                                  );*/
      pageContext.writeDiagnostics(s, "Inside click of contact name ", 2);

    }
  }
}
