/*=============================================================================+
 |                       Office Depot - Project Simplify                       |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization           |
 +=============================================================================+
 |  FILENAME                                                                   |
 |             ODSiteViewCO.java                                               |
 |                                                                             |
 |  DESCRIPTION                                                                |
 |    Page Controller class for SiteViewPG.                                    |
 |                                                                             |
 |  NOTES                                                                      |
 |                                                                             |
 |                                                                             |
 |  DEPENDENCIES                                                               |
 |    No dependencies.                                                         |
 |                                                                             |
 |  HISTORY                                                                    |
 |                                                                             |
 |    04/09/2007  Ashok Kumar         Created                                  |
 |    21-Nov-2007 Jasmine Sujithra    Modified Access Code Condition           |        
 |    23-Nov-2007 Jasmine Sujithra    Added Parameter ASNReqFrmSiteId on  Go'  |
 |    24-Dec-2007 Anirban Chaudhuri   Fixed code for defect#187 in ASN Tracker | 
 |    14-Feb-2008 Jasmine Sujithra    Call Party Security to determine         |
 |                                    contact access                           |
 |    4-Mar-2008  Jasmine Sujithra    Updated for Breadcrumb for NI site       |
 |    12-May-2008 Anirban Chaudhuri   Modified for defect#14801 fix.           |
 |    28-AUG-2009 Anirban Chaudhuri   Modified for PRDGB defect#2135 fix.      |
 +============================================================================*/
package od.oracle.apps.xxcrm.asn.partysite.webui;

import com.sun.java.util.collections.HashMap;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import java.io.Serializable;

import od.oracle.apps.xxcrm.asn.common.fwk.webui.ODASNControllerObjectImpl;

//import oracle.apps.asn.common.fwk.webui.ASNUIConstants;
import oracle.apps.asn.common.webui.ASNUIUtil;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.OASwitcherBean;
import oracle.apps.fnd.framework.webui.beans.nav.OAPageButtonBarBean;
import oracle.apps.fnd.framework.webui.beans.layout.OACellFormatBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.nav.OABreadCrumbsBean;
import oracle.apps.asn.common.fwk.webui.ASNUIConstants;

import oracle.jbo.common.Diagnostic;


/**
 * Controller for ...
 */
public class ODSiteViewCO extends ODASNControllerObjectImpl
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
    final String METHOD_NAME = "xxcrm.asn.partysite.webui.ODSiteViewCO.processRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    if (isProcLogEnabled)
    {
    pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processRequest(pageContext, webBean);

    String partyId      = pageContext.getParameter("ASNReqFrmCustId");
    String partySiteId  = pageContext.getParameter("ASNReqFrmSiteId");
    String salesLeadId  = pageContext.getParameter("ASNReqFrmSalesLeadId");
    String leadId       = pageContext.getParameter("ASNReqFrmLeadId");

        pageContext.writeDiagnostics(METHOD_NAME, "partySiteId = "+partySiteId , OAFwkConstants.PROCEDURE);
   
    if ( partyId == null )
    {
         OAException e = new OAException("ASN", "ASN_TCA_CUSTPARAM_MISS_ERR");
         pageContext.putDialogMessage(e);
    }
    else
    {
      String partyName  = pageContext.getParameter("ASNReqFrmCustName");
      String partySiteName = pageContext.getParameter("ASNReqFrmSiteName");

      //for attachments need to invoke the ODPartySiteVO.
      OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);
      Serializable[] parameter1 =  { partyId };
      String queriedPartyName  = (String) am.invokeMethod("getPartyNameFromId", parameter1);

      if(partyName == null)
      {
        partyName = queriedPartyName;
      }
      //Anirban added for fixing defect#187 in ASN Tracker: Moved the piece of code to the top: Start
	  //initializes the query for the customer actions poplist


	  //Anirban: 2135 starts: for skipping view site page and re-directing to the update site page.
      //am.invokeMethod("initCustomerActionsQuery", null); //commented this line of code
	  //Anirban: 2135 ends: for skipping view site page and re-directing to the update site page.

      //initializes the query for the customer actions poplist

      //Anirban: 2135 starts: for skipping view site page and re-directing to the update site page.
      //am.invokeMethod("getPartyInfo", parameter1);//commented this line of code
	  //Anirban: 2135 ends: for skipping view site page and re-directing to the update site page.


	  //Anirban added for fixing defect#187 in ASN Tracker: Moved the piece of code to the top: End
                                                 
      // Fetch the party site identifier if null using the lead identifier 
      // or the sales lead identifier (if not null) else fetch the primary 
      // party site identifier.
      if(partySiteId == null) 
      {

      pageContext.writeDiagnostics(METHOD_NAME, "Begin partySiteId"+partySiteId, OAFwkConstants.PROCEDURE);
      
         if (salesLeadId != null)
         {
             Serializable[] LeadParams =  { salesLeadId, partyId };
             partySiteId = (String) am.invokeMethod("getPartySiteIdForLeadId", LeadParams);
         }
         else if(leadId != null)
         {
             Serializable[] OpprParams =  { leadId, partyId };
             partySiteId = (String) am.invokeMethod("getPartySiteIdForOpprId", OpprParams);           
         }

      pageContext.writeDiagnostics(METHOD_NAME, "End partySiteId"+partySiteId, OAFwkConstants.PROCEDURE);         
      }

      Serializable[] parameter2 =  { partyId, partySiteId };
      String queriedPartySiteName  = (String) am.invokeMethod("getSiteNameFromId", parameter2);     
      
     // if(partySiteName == null)
      //{
        partySiteName = queriedPartySiteName;
     // }
      
	  //Anirban added for fixing defect#187 in ASN Tracker: Start
      // check if partySiteId is null and if yes then get the primary site id.
      if((partySiteId == null) || ("".equals(partySiteId)))
      { 
        partySiteId = (String) am.invokeMethod("getPrmySiteId", parameter2);
        if((partySiteId == null) || ("".equals(partySiteId)))
        {
          //OAException e = new OAException("XXCRM", "XX_SFA_052_SITEPARAM_MISS_ERR");
		  //pageContext.putDialogMessage(e);
		 OAException e = new OAException("XXCRM", "XX_SFA_081_PARTY_WOUT_SITE"); 		
		 throw(e);
        }
      }


      //Anirban: 2135 starts: for skipping view site page and re-directing to the update site page.

      if(true)
     {

      HashMap hashmapRedirect = new HashMap();
      hashmapRedirect.put("ASNReqFrmCustId", partyId);
      hashmapRedirect.put("ASNReqFrmCustName", partyName);
	  hashmapRedirect.put("ASNReqFrmSiteId", partySiteId);
      hashmapRedirect.put("ASNReqFrmSiteName", partySiteName);
	  hashmapRedirect.put("ASNReqFrmFuncName", "XX_ASN_SITE_UPDATE");
      hashmapRedirect.put("ASNReqFrmCallingSiteId",partySiteId);
      //pageContext.forwardImmediately("XX_ASN_SITE_UPDATE", (byte)0, null, hashmapRedirect, false, "S");
	  pageContext.forwardImmediately("XX_ASN_SITE_UPDATE", (byte)0, null, hashmapRedirect, false, "Y");
	 }
	 else
	 {

      //Anirban added for fixing defect#187 in ASN Tracker: End
      String AccessCode = this.processAccessPrivilege(pageContext,
                                                      "SITE",
                                                      partySiteId);

      /* Added For calling Party security to determine contact access */
      String custAccMode = this.processAccessPrivilege(pageContext,
                                                     ASNUIConstants.CUSTOMER_ENTITY,
                                                     partyId);
    
                   
      // set up page title
      MessageToken[] tokens = { new MessageToken("PARTYNAME", queriedPartyName), new MessageToken("SITENAME", queriedPartySiteName) };
      String pageTitle = pageContext.getMessage("XXCRM", "XX_SFA_045_TCA_VIEW_SITE_TITLE", tokens);
      
      // Set the page title (which also appears in the breadcrumbs)
      ((OAPageLayoutBean)webBean).setTitle(pageTitle);

      //save partyname, partySiteName and id in the transaction.
      pageContext.putTransactionValue("ASNTxnCustName", partyName);
      pageContext.putTransactionValue("ASNTxnSiteName", partySiteName);    
      pageContext.putTransactionValue("ASNTxnSiteId",partySiteId); 
      pageContext.putTransactionValue("ASNTxnCustAccMode",custAccMode);
    
      Diagnostic.println("----------------->OrgViewCO->processRequest. partyName = " + partyName + " partySiteName = " + partySiteName);

      //put the parameters required for the contact points regions
      pageContext.putParameter("ContRelTableObjectPartySiteId", partySiteId);

      //put the parameters required for the notes region
      pageContext.putTransactionValue("ASNTxnNoteSourceCode", "PARTY_SITE");
      pageContext.putTransactionValue("ASNTxnNoteSourceId", partySiteId);

      // AccessCode = 1OllOl11O - UPDATE
      // AccessCode = 101lOl11O - READ
      if ("1OllOl11O".equals(AccessCode))
      {

        // Set the rendered property to true for the following buttons
        // 1. ContRelTableAddSiteContEvent - contact region
        // 2. Apply - Page Button bar
        // 3. UpdateSiteDetails - Page Button bar

        OAHeaderBean SiteCtctsRelTableRN = (OAHeaderBean) webBean.findChildRecursive("ODSiteCtctsRelTableRN");
        if(SiteCtctsRelTableRN != null)
        {
          //hide buttons in the contacts view component
          OASubmitButtonBean contRelTableAddSiteContEvent = (OASubmitButtonBean)SiteCtctsRelTableRN.findChildRecursive("ContRelTableAddSiteContEvent");
          if(contRelTableAddSiteContEvent != null)
          {
            contRelTableAddSiteContEvent.setRendered(true);
          }

          OASwitcherBean updateSwitcher = (OASwitcherBean)SiteCtctsRelTableRN.findChildRecursive("update_switcher");
          if(updateSwitcher != null)
          {
            updateSwitcher.setRendered(true);
          }
          
          OASwitcherBean removeSwitcher = (OASwitcherBean)SiteCtctsRelTableRN.findChildRecursive("remove_switcher");
          if(removeSwitcher != null)
          {
            removeSwitcher.setRendered(true);
          }
        }

        OAPageButtonBarBean PageButtonsRN = (OAPageButtonBarBean) webBean.findChildRecursive("ODPageButtonsRN");
        if(PageButtonsRN != null)
        {
          OASubmitButtonBean applyButton = (OASubmitButtonBean)PageButtonsRN.findChildRecursive("Apply");
          if(applyButton != null)
          {
            applyButton.setRendered(true);
          }
          OASubmitButtonBean updateSiteDetails = (OASubmitButtonBean)PageButtonsRN.findChildRecursive("UpdateSiteDetails");
          if(updateSiteDetails != null)
          {
            updateSiteDetails.setRendered(true);
          }
        }

        //put the code required for the attachments
        //attachment integration here for update      
        ASNUIUtil.attchSetUp(pageContext
                            ,webBean
                            ,true
                            ,"ODSiteAttchTable"//This is the attachment table item
                            ,"ODSiteAttchContextHolderRN"//This is the stack region that holds the context information
                            ,"ODSiteAttchContextRN");//this is the messageComponentLayout region that holds actual context beans
      }
     else if ("101lOl11O".equals(AccessCode))
      {

        // Set the rendered property to false for the following buttons
        // 1. ContRelTableAddSiteContEvent - contact region
        // 2. Apply - Page Button bar
        // 3. UpdateSiteDetails - Page Button bar

        OAHeaderBean SiteCtctsRelTableRN = (OAHeaderBean) webBean.findChildRecursive("ODSiteCtctsRelTableRN");
        if(SiteCtctsRelTableRN != null)
        {
          //hide buttons in the contacts view component
          OASubmitButtonBean contRelTableAddSiteContEvent = (OASubmitButtonBean)SiteCtctsRelTableRN.findChildRecursive("ContRelTableAddSiteContEvent");
          if(contRelTableAddSiteContEvent != null)
          {
            contRelTableAddSiteContEvent.setRendered(false);
          }
           OASubmitButtonBean createContactButton = (OASubmitButtonBean)SiteCtctsRelTableRN.findChildRecursive("ASNCreateCtctBtn");
          if(createContactButton != null)
          {
            createContactButton.setRendered(false);
          }

          /* Hide the Update and Remove columns from the contact table */
          OASwitcherBean updateSwitcher = (OASwitcherBean)SiteCtctsRelTableRN.findChildRecursive("update_switcher");
          if(updateSwitcher != null)
          {
            updateSwitcher.setRendered(false);
          }
          
          OASwitcherBean removeSwitcher = (OASwitcherBean)SiteCtctsRelTableRN.findChildRecursive("remove_switcher");
          if(removeSwitcher != null)
          {
            removeSwitcher.setRendered(false);
          }

        }

        OAPageButtonBarBean PageButtonsRN = (OAPageButtonBarBean) webBean.findChildRecursive("ODPageButtonsRN");       
        if(PageButtonsRN != null)
        {
          OASubmitButtonBean applyButton = (OASubmitButtonBean)PageButtonsRN.findChildRecursive("Apply");
          if(applyButton != null)
          {
            applyButton.setRendered(true);
          }
          OASubmitButtonBean updateSiteDetails = (OASubmitButtonBean)PageButtonsRN.findChildRecursive("UpdateSiteDetails");
          if(updateSiteDetails != null)
          {
            updateSiteDetails.setRendered(true);
          }
        }

        //put the code required for the attachments
        //attachment integration here for Read only
        ASNUIUtil.attchSetUp(pageContext
                            ,webBean
                            ,false
                            ,"ODSiteAttchTable"//This is the attachment table item
                            ,"ODSiteAttchContextHolderRN"//This is the stack region that holds the context information
                            ,"ODSiteAttchContextRN");//this is the messageComponentLayout region that holds actual context beans        
      }

      /* Check for Party Access */
       // custAccMode = 1OllOl11O - UPDATE
      // custAccMode = 101lOl11O - READ
     
      if ("101lOl11O".equals(custAccMode))
      {
      /* Read Only access to the party hence disable the update icon on the contacts region*/
      OAHeaderBean SiteCtctsRelTableRN = (OAHeaderBean) webBean.findChildRecursive("ODSiteCtctsRelTableRN");
        if(SiteCtctsRelTableRN != null)
        {       

          /* Hide the Update column from the contact table */         
         OASwitcherBean updateSwitcher = (OASwitcherBean)SiteCtctsRelTableRN.findChildRecursive("update_switcher");
          if(updateSwitcher != null)
          {
            updateSwitcher.setRendered(false);
          }
           /* Hide the Create Contact button*/
          OASubmitButtonBean createContactButton = (OASubmitButtonBean)SiteCtctsRelTableRN.findChildRecursive("ASNCreateCtctBtn");
          if(createContactButton != null)
          {
            //Anirban starts fix for defect#14801
            createContactButton.setRendered(true);//changed from false to true for defect#14801 fix.
            //Anirban ends fix for defect#14801
          }

        }
      }

      
      //set up the colspan for the attachemnts cell
      OACellFormatBean attchCell = (OACellFormatBean)webBean.findChildRecursive("ODSiteAttchCell");
      if(attchCell != null){
         attchCell.setColumnSpan(2);
      }

      //put the parameters required for the business activities region
      pageContext.putTransactionValue("ASNTxnAddressId", partySiteId);
      pageContext.putTransactionValue("ASNTxnSiteBusActLkpTyp", "XX_ASN_SITE_BUS_ACTS");    
      pageContext.putTransactionValue("ASNTxnAddBrdCrmb", "ADD_BREAD_CRUMB_YES");
      pageContext.putTransactionValue("ASNTxnReturnUrl", getModifiedCurrentUrlForRedirect(pageContext, true));
      //addReturnLink(pageContext, webBean, "ReturnLink"); 
      

      //initializes the query for the customer actions poplist
      Serializable[] parameter3 =  { partySiteId };
      am.invokeMethod("getSiteInfo", parameter3);    

     }
     //Anirban: 2135 ends: for skipping view site page and re-directing to the update site page.

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
    final String METHOD_NAME = "xxcrm.asn.partysite.webui.ODSiteViewCO.processFormRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStmtLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);

    if (isProcLogEnabled)
    {
    pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    } 
    
    super.processFormRequest(pageContext, webBean);
    pageContext.putParameter("ASNReqFrmFuncName","XX_ASN_SITEVIEWPG");
    
    String partyId = pageContext.getParameter("ASNReqFrmCustId");
    String partyName = (String)pageContext.getTransactionValue("ASNTxnCustName");
    String partySiteId = (String)pageContext.getTransactionValue("ASNTxnSiteId");
    String partySiteName = (String)pageContext.getTransactionValue("ASNTxnSiteName");
    String custAccMode = (String)pageContext.getTransactionValue("ASNTxnCustAccMode");

    MessageToken[] tokens = { new MessageToken("PARTYNAME", partyName), new MessageToken("SITENAME", partySiteName) };
    String pageTitle = pageContext.getMessage("XXCRM", "XX_SFA_045_TCA_VIEW_SITE_TITLE", tokens);       

    OAPageLayoutBean pgLayout = pageContext.getPageLayoutBean();
    OABreadCrumbsBean brdCrumb = (OABreadCrumbsBean)pgLayout.getBreadCrumbsLocator();
    pgLayout.setBreadCrumbEnabled(true);

    if (isStmtLogEnabled)
    {
      StringBuffer buf = new StringBuffer();
      buf.append("partyId = ");
      buf.append(partyId);
      buf.append(" ,partyName = ");
      buf.append(partyName);
      buf.append(" ,partySiteId = ");
      buf.append(partySiteId);
      buf.append(" ,partySiteName = ");
      buf.append(partySiteName);
      buf.append(" ,brdCrumb = ");
      buf.append(brdCrumb);
      pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
    }
   
    HashMap params = new HashMap();
    params.put("ASNReqFrmFuncName", "XX_ASN_SITEVIEWPG");
    params.put("ASNReqFrmCustId", partyId);
    params.put("ASNReqFrmCustName", partyName);
    params.put("ASNReqFrmSiteId", partySiteId);
    params.put("ASNReqFrmSiteName", partySiteName);
    params.put("ASNReqFrmCustAccMode",custAccMode);
    //params.put("ASNReqFrmOriginalSiteId", partySiteId);

    //get the page level event
    String event = pageContext.getParameter(EVENT_PARAM);

    //This is the event handling for the page level buttons
    if (pageContext.getParameter("Cancel") != null)
    {
        this.processTargetURL(pageContext, null, null);
    }
    else if (pageContext.getParameter("Apply") != null)
    {
        doCommit(pageContext);
        this.processTargetURL(pageContext, null, null);
    }
    else if (pageContext.getParameter("UpdateSiteDetails") != null)
    {
        doCommit(pageContext);
        this.modifyCurrentBreadcrumbLink(pageContext, true, pageTitle, false);
        params.put("ASNReqFrmFuncName", "XX_ASN_SITE_UPDATE");
        params.put("ASNReqFrmCallingSiteId",partySiteId);
        pageContext.forwardImmediately("XX_ASN_SITE_UPDATE",
                    KEEP_MENU_CONTEXT ,
                    null,
                    params,
                    false,
                    ADD_BREAD_CRUMB_YES);
    }
    //end of event handling for page else buttons   
    //handle the events raised from the Site actions poplist.
    //This will take the user to the Lead Create Page or the Opportunity Create page
    //and will populate this customer and site information in those pages.
    else if(pageContext.getParameter("Go") != null)
    {
       String ActionValue = pageContext.getParameter("Action");
       if(ActionValue != null)
       {
          doCommit(pageContext);
          this.modifyCurrentBreadcrumbLink(pageContext, true, pageTitle, false);
          pageContext.putParameter("ASNReqSelCustId", partyId);
          pageContext.putParameter("ASNReqSelCustName", partyName);
          pageContext.putParameter("ASNReqSelSiteId", partySiteId);
          pageContext.putParameter("ASNReqSelSiteName", partySiteName);
          pageContext.putParameter("ASNReqFrmSiteId", partySiteId);
          
          if(ActionValue.equals("CREATE_LEAD"))
          {
            pageContext.putParameter("ASNReqPgAct", "CRTELEAD");
            this.processTargetURL(pageContext, null, null);
          }
          else if(ActionValue.equals("CREATE_OPPORTUNITY"))
          {
            pageContext.putParameter("ASNReqPgAct", "CRTEOPPTY");
            this.processTargetURL(pageContext, null, null);
          }
       } 
    }
    else if ("ViewOrgEvt".equals(event))
    {
       doCommit(pageContext);
       pageContext.putParameter("ASNReqPgAct","CUSTDET");
       params.put("ASNReqFrmFuncName", "ASN_ORGVIEWPG");      
       //this.processTargetURL(pageContext,null,params); 
	   
       pageContext.forwardImmediately("ASN_ORGVIEWPG", OAWebBeanConstants.KEEP_MENU_CONTEXT, null, params, false, OAWebBeanConstants.ADD_BREAD_CRUMB_YES);	   
    }
    //this is event handling for the contacts region
    else if (pageContext.getParameter("ContRelTableAddSiteContEvent") != null)
    {
       doCommit(pageContext);
       pageContext.putParameter("ASNReqPgAct","SUBFLOW");
       params.put("ASNReqFrmFuncName", "OD_ASN_ADDSITECTCTPG");
       this.processTargetURL(pageContext,null,params);       
    }
    else if (pageContext.getParameter("ContRelTableUpdateEvent") != null &&
      pageContext.getParameter("ContRelTableUpdateEvent").equals("UPDATE"))
    {
       params.put("ASNReqFrmRelId",  pageContext.getParameter("RelationshipId"));
       params.put("ASNReqFrmRelPtyId",  pageContext.getParameter("ContRelTableRelPartyId"));
       params.put("ASNReqFrmCustId",  partyId);
       params.put("ASNReqFrmCustName",  partyName);
       params.put("ASNReqFrmCtctId",  pageContext.getParameter("ContRelTableSubjectPartyId"));
       params.put("ASNReqFrmCtctName",  pageContext.getParameter("ContRelTableSubjectName"));
       doCommit(pageContext);
       // replace the current link text/title from the bread crumb with the specified value
       // the title will not be replaced if the specified value is null/empty
       this.modifyCurrentBreadcrumbLink(pageContext, // pageContext
                                        true,        // replaceCurrentText
                                        pageTitle,   // newText
                                        false);      // resetRetainAMParam       
       params.put("ASNReqFrmFuncName", "ASN_CTCTUPDATEPG");
       pageContext.forwardImmediately("ASN_CTCTUPDATEPG",
                    KEEP_MENU_CONTEXT ,
                    null,
                    params,
                    false,
                    ADD_BREAD_CRUMB_YES);
    }
    else if (pageContext.getParameter("ContRelTableViewEvent") != null &&
      pageContext.getParameter("ContRelTableViewEvent").equals("VIEW"))
    {
       params.put("ASNReqFrmRelId",  pageContext.getParameter("RelationshipId"));
       params.put("ASNReqFrmRelPtyId",  pageContext.getParameter("ContRelTableRelPartyId"));
       params.put("ASNReqFrmCustId",  partyId);
       params.put("ASNReqFrmCustName",  partyName);
       params.put("ASNReqFrmCtctId",  pageContext.getParameter("ContRelTableSubjectPartyId"));
       params.put("ASNReqFrmCtctName",  pageContext.getParameter("ContRelTableSubjectName"));
       doCommit(pageContext);
       //modify the breadcrumb link.
       this.modifyCurrentBreadcrumbLink(pageContext, true, pageTitle, false);
       params.put("ASNReqFrmFuncName", "ASN_CTCTVIEWPG");     
       pageContext.forwardImmediately("ASN_CTCTVIEWPG",
                    KEEP_MENU_CONTEXT ,
                    null,
                    params,
                    false,
                    ADD_BREAD_CRUMB_YES);
    }
    else if (pageContext.getParameter("ASNCreateCtctBtn") != null)
    {
       	 String partySID = partySiteId;//(String) pageContext.getParameter("ASNReqFrmSiteId");
  			
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
                // Create an contact in the context of a Site
                pageContext.writeDiagnostics(METHOD_NAME, "Before doCommit ASNReqCtxtFuncName :  "+ pageContext.getParameter("ASNReqCtxtFuncName"), 2);
                pageContext.writeDiagnostics(METHOD_NAME, "Before doCommit ASNReqFrmFuncName :  "+ pageContext.getParameter("ASNReqFrmFuncName"), 2);
                //pageContext.putParameter("ASNReqFrmFuncName",pageContext.getParameter("ASNReqCtxtFuncName"));
                //doCommit(pageContext);
                //pageContext.putParameter("ASNReqCtxtFuncName",pageContext.getParameter("ASNReqFrmFuncName"));
                pageContext.writeDiagnostics(METHOD_NAME, "After doCommit ASNReqCtxtFuncName :  "+ pageContext.getParameter("ASNReqCtxtFuncName"), 2);
                pageContext.writeDiagnostics(METHOD_NAME, "After doCommit ASNReqFrmFuncName :  "+ pageContext.getParameter("ASNReqFrmFuncName"), 2);
                //doCommit(pageContext);
                //OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);
                //am.invokeMethod("clearContactsVOCache");

                //retainContextParameters(pageContext);
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

                pageContext.writeDiagnostics(METHOD_NAME, "Before Create Contact ASNReqFrmSiteId :  ", 2);
                pageContext.writeDiagnostics(METHOD_NAME, pageContext.getParameter("ASNReqFrmSiteId"), 2);


                pageContext.putParameter("ASNReqPgAct","SUBFLOW");
                HashMap conditions = new HashMap();
                conditions.put(ASNUIConstants.RETAIN_AM, "Y");

                this.processTargetURL(pageContext,conditions,params);
             }
         }

    }
    //end of event handling for the contacts region    
    //handle the events raised from the business activities region.
    else if(pageContext.getParameter("ASNReqExitPage") != null &&
          pageContext.getParameter("ASNReqExitPage").equals("Y"))
    {
        doCommit(pageContext);
       //modify the breadcrumb link.
       this.modifyCurrentBreadcrumbLink(pageContext, true, pageTitle, false);        
    }    
    //handle the PPR events raised by the attachments
    else if("oaAddAttachment".equals(event) ||
             "oaUpdateAttachment".equals(event) ||
             "oaDeleteAttachment".equals(event) ||
             "oaViewAttachment".equals(event) )
    {
        //commit
        doCommit(pageContext);
        //modify the breadcrumb link.
        this.modifyCurrentBreadcrumbLink(pageContext, true, pageTitle, false);        
        //call the common utility method.
        ASNUIUtil.attchEvent(pageContext,webBean);
    }
    else if ("CallNotesDetail".equals(pageContext.getParameter("CacNotesDtlEvent")))
    {
      doCommit(pageContext);
    }

    if (isProcLogEnabled)
    {
    pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }
    
  }

}
