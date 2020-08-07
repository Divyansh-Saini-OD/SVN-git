/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODSiteUpdateCO.java                                           |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Page Controller class for ODSiteUpdatePG.                              |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    No dependencies.                                                       |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    01/OCT/2007 Sudeept Maharana   Created                                 |
 |    14/NOV/2007 Jasmine Sujithra   Included parameter ODSiteAttributeGroup |
 |    27/NOV/2007 Jasmine Sujithra   Added Parameters for the Task Region    |
 |    27/NOV/2007 Sathya Prabha      Commented the breadcrumb in the update  |
 |                                   Contact region. Added a variable in the |
 |                                   Remove Task message.                    |
 |    28/NOV/2007  Jasmine Sujithra   Disabled the Add Site Contact and Add  |
 |                                    New Row Button in the Tasks Region on  |
 |                                    Read Only Access                       |
 |    03/DEC/2007 Sathya Prabha      Set the Retain AM parameter to "true"in |
 |                                   process form request method for         |
 |                                   refreshing a page when a party site is  |
 |                                   selected.                               |
 |    17/DEC/2007 Jasmine Sujithra  Undo the Retain AM Change                |             
 |    14/FEB/2008 Jasmine Sujithra  Call Party Security to determine         |
 |                                  contact access and modified the title    |
 |    04/MAR/2008 Jasmine Sujithra  Updated for Breadcrumb for NI site       | 
 |    22/APR/2008 Jasmine Sujithra  Updated ASNReqFrmFuncName parameter      |
 |    12-MAY-2009 Anirban Chaudhuri Modified for defect#14801 fix.           |
 |    28-AUG-2009 Anirban Chaudhuri Modified for PRDGB defect#2135 fix.      |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.partysite.webui;

/* Subversion Info:

*

* $HeadURL: http://svn.na.odcorp.net/svn/od/common/trunk/xxcomn/java/od/oracle/apps/xxcrm/asn/partysite/webui/ODSiteUpdateCO.java $

*

* $Rev: 95339 $

*

* $Date: 2010-03-05 04:42:23 -0500 (Fri, 05 Mar 2010) $

*/

import com.sun.java.util.collections.HashMap;
import java.io.Serializable;

import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.asn.common.webui.ASNUIUtil;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.table.OAAdvancedTableBean;
import od.oracle.apps.xxcrm.asn.common.fwk.webui.ODASNControllerObjectImpl;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.nav.OABreadCrumbsBean;
import oracle.apps.fnd.framework.webui.beans.OASwitcherBean;
import oracle.apps.asn.common.fwk.webui.ASNUIConstants;
import oracle.apps.fnd.framework.webui.beans.table.OAColumnBean;
import oracle.apps.fnd.framework.webui.beans.layout.OASubTabLayoutBean;
/**
 * Controller for ...
 */
public class ODSiteUpdateCO extends ODASNControllerObjectImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
  VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

/**
 * processRequest is called before the page is loaded
 *
 * @param  pageContext - the page context
 * @param  webBean     - web Bean
 * @return void
 */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    final String METHOD_NAME = "xxcrm.asn.partysite.webui.ODSiteUpdateCO.processRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);

    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

  	super.processRequest(pageContext, webBean);

    /* Added for the Extensible Attributes Customization*/
    pageContext.putParameter("ODSiteAttributeGroup", "Y");

    OAApplicationModule am = pageContext.getApplicationModule(webBean);

        //Anirban: 2135 starts: for read-only partysite access

        /*pageContext.putTransactionValue("ASNReqFrmCustId",pageContext.getParameter("ASNReqFrmCustId"));
        pageContext.putTransactionValue("ASNReqFrmCustName",pageContext.getParameter("ASNReqFrmCustName"));
        pageContext.putTransactionValue("ASNReqFrmSiteId",pageContext.getParameter("ASNReqFrmSiteId"));
        pageContext.putTransactionValue("ASNReqFrmSiteName",pageContext.getParameter("ASNReqFrmSiteName"));
        pageContext.putTransactionValue("ASNReqFrmCallingSiteId",pageContext.getParameter("ASNReqFrmCallingSiteId"));*/
        


        String partyId = pageContext.getParameter("ASNReqFrmCustId");
        String partyName = pageContext.getParameter("ASNReqFrmCustName");
        String partySiteId = pageContext.getParameter("ASNReqFrmSiteId");
        String partySiteName = pageContext.getParameter("ASNReqFrmSiteName");


        if(partyId==null)
		   partyId = (String)pageContext.getTransactionValue("ASNReqFrmCustId");
		else
		   pageContext.putTransactionValue("ASNReqFrmCustId",pageContext.getParameter("ASNReqFrmCustId"));

        if(partyName==null)
		   partyName = (String)pageContext.getTransactionValue("ASNReqFrmCustName");
		else
		   pageContext.putTransactionValue("ASNReqFrmCustName",pageContext.getParameter("ASNReqFrmCustName"));

		if(partySiteId==null)
		   partySiteId = (String)pageContext.getTransactionValue("ASNReqFrmSiteId");
		else
		   pageContext.putTransactionValue("ASNReqFrmSiteId",pageContext.getParameter("ASNReqFrmSiteId"));

		if(partySiteName==null)
		   partySiteName = (String)pageContext.getTransactionValue("ASNReqFrmSiteName");
		else
		   pageContext.putTransactionValue("ASNReqFrmSiteName",pageContext.getParameter("ASNReqFrmSiteName"));
        pageContext.putTransactionValue("ASNReqFrmCallingSiteId",pageContext.getParameter("ASNReqFrmCallingSiteId"));

        //Anirban: 2135 ends: for read-only partysite access

		// set Page and Window Title
		//MessageToken[] tokens = { new MessageToken("REQ_VAL1", partyName), new MessageToken("REQ_VAL2", partySiteName) };
        MessageToken[] tokens = { };

		String pageTitle = pageContext.getMessage("XXCRM", "XX_SFA_050_UPDATE_SITE_TITLE", tokens);
    

		((OAPageLayoutBean)webBean).setTitle(pageTitle);
		((OAPageLayoutBean)webBean).setWindowTitle(pageTitle);

		//    Serializable[] parameters =  { "82702" };
		Serializable[] parameters =  { partyId, partySiteId };
		Class[] paramTypes = { String.class, String.class };
		am.invokeMethod("initQuery", parameters, paramTypes);

	    //initializing the Actions Poplist
	    am.invokeMethod("initCustomerActionsQuery");
	    am.invokeMethod("initAddrBkTypes");

	    // parameters for Party Site Extension Attributes
	    pageContext.putParameter("HzPuiExtEntityId",partySiteId);
	    pageContext.putParameter("HzPuiExtAMPath","ODSiteUpdateAM");

        String access = processAccessPrivilege(pageContext,"SITE",partySiteId);
		//Anirban: added only the below 1 line of code for testing purpose, will remove it eventually.
		//access = "101lOl11O";

         /* Added For calling Party security to determine contact access */
       String custAccMode = this.processAccessPrivilege(pageContext,
                                                     ASNUIConstants.CUSTOMER_ENTITY,
                                                     partyId);
       pageContext.putTransactionValue("ASNTxnCustAccMode",custAccMode);

        if ("1OllOl11O".equals(access) )
        {
        		pageContext.putParameter("HzPuiExtMode", "UPDATE");
      	    //Code required for the attachments
      	    //Attachment integration here
			// update mode
            ASNUIUtil.attchSetUp(pageContext
	                    ,webBean
	                    ,true
	                    ,"SiteAttchTable"//This is the attachment table item
	                    ,"SiteAttchContextHolderRN"//This is the stack region that holds the context information
	                    ,"SiteAttchContextRN");//this is the messageComponentLayout region that holds actual context beans

           /* Display the Add Site Contact Button */
            OAHeaderBean SiteCtctsRelTableRN = (OAHeaderBean) webBean.findChildRecursive("ContactsExtRN");
            if(SiteCtctsRelTableRN != null)
            {
              //display buttons in the contacts view component
              OASubmitButtonBean contRelTableAddSiteContEvent = (OASubmitButtonBean)SiteCtctsRelTableRN.findChildRecursive("ContRelTableAddSiteContEvent");
              if(contRelTableAddSiteContEvent != null)
              {
                contRelTableAddSiteContEvent.setRendered(true);
              }
              OASubmitButtonBean createContactButton = (OASubmitButtonBean)SiteCtctsRelTableRN.findChildRecursive("ASNCreateCtctBtn");
              if(createContactButton != null)
              {
                createContactButton.setRendered(true);
              }

              /* Display the Update and Remove columns from the contact table */
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
            
            /* Make the Task Region Updateable */
            pageContext.putTransactionValue("cacTaskTableRO","N");            
            pageContext.putTransactionValue("cacTaskReadOnlyPPR", "N");
            
            am.invokeMethod("setUpdate");
        }
		//Anirban: 2135 starts: for read-only partysite access
        //else
        else if ("101lOl11O".equals(access))
        {
            pageContext.putParameter("HzPuiExtMode", "VIEW");


            OAColumnBean region4 = (OAColumnBean)webBean.findChildRecursive("UpdateColumn");
            if(region4 != null)
            {
              region4.setRendered(false);
            }
          
            OAColumnBean region41 = (OAColumnBean)webBean.findChildRecursive("RemoveColumn");
            if(region41 != null)
            {
              region41.setRendered(false);
            }

			OASubmitButtonBean createAddressButton = (OASubmitButtonBean)webBean.findChildRecursive("CreateAddress");
            if(createAddressButton != null)
            {
              createAddressButton.setRendered(false);
            }


      	    //Code required for the attachments
      	    //Attachment integration here
      	    // read only mode
            ASNUIUtil.attchSetUp(pageContext
	                    ,webBean
	                    ,false
	                    ,"SiteAttchTable"//This is the attachment table item
	                    ,"SiteAttchContextHolderRN"//This is the stack region that holds the context information
	                    ,"SiteAttchContextRN");//this is the messageComponentLayout region that holds actual context beans

             /* Hide the Add Site Contact Button */
            OAHeaderBean SiteCtctsRelTableRN = (OAHeaderBean) webBean.findChildRecursive("ContactsExtRN");

           
			if(SiteCtctsRelTableRN != null)
            {
              //hide buttons in the contacts view component
              /*OASubmitButtonBean contRelTableAddSiteContEvent = (OASubmitButtonBean)SiteCtctsRelTableRN.findChildRecursive("ContRelTableAddSiteContEvent");
              if(contRelTableAddSiteContEvent != null)
              {
                contRelTableAddSiteContEvent.setRendered(false);
              }
              OASubmitButtonBean createContactButton = (OASubmitButtonBean)SiteCtctsRelTableRN.findChildRecursive("ASNCreateCtctBtn");
              if(createContactButton != null)
              {
                createContactButton.setRendered(false);
              }*/

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

            /* Make the Task Region Read Only */
            pageContext.putTransactionValue("cacTaskTableRO","Y");            
            pageContext.putTransactionValue("cacTaskReadOnlyPPR", "Y");
            
            am.invokeMethod("setReadOnly");

        }
         //Anirban: 2135 ends: for read-only partysite access


          /* Check for Party Access */
          // custAccMode = 1OllOl11O - UPDATE
          // custAccMode = 101lOl11O - READ     
	  
      if ("101lOl11O".equals(custAccMode))
      {
        /* Read Only access to the party hence disable the update icon on the contacts region*/
        OAHeaderBean SiteCtctsRelTableRN = (OAHeaderBean) webBean.findChildRecursive("ContactsExtRN");
        if(SiteCtctsRelTableRN != null)
        {
              /* Hide the Update column from the contact table */
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
              /* DO NOT Hide the Add and Create Contact button EVER as per the defect#14801*/
              OASubmitButtonBean contRelTableAddSiteContEvent = (OASubmitButtonBean)SiteCtctsRelTableRN.findChildRecursive("ContRelTableAddSiteContEvent");
              if(contRelTableAddSiteContEvent != null)
              {
                //Anirban starts fix for defect#14801
                contRelTableAddSiteContEvent.setRendered(true);
				//Anirban starts fix for defect#14801
              }

              OASubmitButtonBean createContactButton = (OASubmitButtonBean)SiteCtctsRelTableRN.findChildRecursive("ASNCreateCtctBtn");
              if(createContactButton != null)
              {
                //Anirban starts fix for defect#14801
                createContactButton.setRendered(true);//changed from false to true for defect#14801 fix.
                //Anirban ends fix for defect#14801
              }          
        }
      }

	    // parameters for Business Activities Region
	    pageContext.putTransactionValue("ASNTxnAddressId",(partySiteId).toString() );
	    pageContext.putTransactionValue("ASNTxnSiteBusActLkpTyp", "XX_ASN_SITE_BUS_ACTS");

	    // parameters for Contacts Region
	    pageContext.putParameter("ContRelTableObjectPartySiteId",partySiteId);

	    // parameters for Notes Region
	    pageContext.putTransactionValue("ASNTxnNoteSourceCode", "PARTY_SITE");
	    pageContext.putTransactionValue("ASNTxnNoteSourceId", (partySiteId).toString());

      //Parameters for Tasks Region
      pageContext.putTransactionValue("cacTaskSrcObjCode", "OD_PARTY_SITE");
      pageContext.putTransactionValue("cacTaskSrcObjId", partySiteId);
      pageContext.putTransactionValue("cacTaskCustId", partyId);
      pageContext.putTransactionValue("cacTaskContDqmRule", (String) pageContext.getProfile("HZ_DQM_CON_SIMPLE_MATCHRULE"));/*"10002";*/
      pageContext.putTransactionValue("cacTaskNoDelDlg", "Y");
      pageContext.putTransactionValue("cacTaskReturnUrl", getModifiedCurrentUrlForRedirect(pageContext, true));

      OASubTabLayoutBean tabBean = (OASubTabLayoutBean)webBean.findChildRecursive("SubTabLayoutRN");
	  if(pageContext.getParameter("AddnInfoTaskDetails") != null)
      {
       tabBean.setAttributeValue(MODE_ATTR, SUBTAB_FORM_SUBMISSION_MODE);
       tabBean.setSelectedIndex(pageContext,1);      
      }	

    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }

  }

/**
 * Procedure to handle form submissions for form elements in a region
 *
 * @param  pageContext - the page context
 * @param  webBean     - web Bean
 * @return void
 */


  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    final String METHOD_NAME = "xxcrm.asn.partysite.webui.ODSiteUpdateCO.processFormRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStmtLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);

    if (isProcLogEnabled)
    {
    pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }


		super.processFormRequest(pageContext, webBean);

	    OAApplicationModule am = pageContext.getApplicationModule(webBean);

		String partyId = (String)pageContext.getTransactionValue("ASNReqFrmCustId");
		String partyName = (String)pageContext.getTransactionValue("ASNReqFrmCustName");
		String partySiteId = (String)pageContext.getTransactionValue("ASNReqFrmSiteId");
		String partySiteName = (String)pageContext.getTransactionValue("ASNReqFrmSiteName");
    String custAccMode = (String)pageContext.getTransactionValue("ASNTxnCustAccMode");
    String callingSiteId = (String)pageContext.getTransactionValue("ASNReqFrmCallingSiteId");

      
		
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

      pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
    }

		MessageToken[] tokens = { new MessageToken("REQ_VAL1", partyName), new MessageToken("REQ_VAL2", partySiteName) };

		String pageTitle = pageContext.getMessage("XXCRM", "XX_SFA_050_UPDATE_SITE_TITLE", tokens);

		  HashMap params = new HashMap();
	    params.put("ASNReqFrmFuncName", "XX_ASN_SITE_UPDATE");
	    params.put("ASNReqFrmCustId", partyId);
	    params.put("ASNReqFrmCustName", partyName);
	    params.put("ASNReqFrmSiteId", partySiteId);
	    params.put("ASNReqFrmSiteName", partySiteName);
      params.put("ASNReqFrmCustAccMode",custAccMode);
      params.put("ASNReqFrmCallingSiteId", callingSiteId);
      

	    // When Party Site is changed
	    if (("SELECT_EVENT").equals(pageContext.getParameter(EVENT_PARAM)) )
	    {
        params.put("ASNReqFrmSiteId", pageContext.getParameter("pSiteId"));
    		params.put("ASNReqFrmFuncName", "XX_ASN_SITEVIEWPG");

        Serializable[] parameters =  { pageContext.getParameter("pSiteId") };
        Class[] paramTypes = { String.class};
        Serializable partySiteName2 = am.invokeMethod("getSelectedPartySiteName", parameters, paramTypes);
        params.put("ASNReqFrmSiteName", partySiteName2);
        
		//Anirban: 2135 starts: for read-only partysite access

        pageContext.forwardImmediately("XX_ASN_SITE_UPDATE"
                                      , (byte)0 //OAWebBeanConstants.KEEP_MENU_CONTEXT
                                      , null
                                      , params
                                      , false
                                      , "Y"); //OAWebBeanConstants.ADD_BREAD_CRUMB_YES

        //Anirban: 2135 ends: for read-only partysite access

		}

		else if (("REMOVE_SITE").equals(pageContext.getParameter(EVENT_PARAM)) )
		{
			// setting up the Remove Confirmation dialog page
			String siteID = pageContext.getParameter("siteID");
			String siteAdr = pageContext.getParameter("siteAddress");

			MessageToken[] mtokens = { new MessageToken("REQ_VAL", "the Site"),
										new MessageToken("REQ_VAL2",siteAdr ) };
			OAException message = new OAException("XXCRM", "XX_SFA_046_CONFIRM_REMOVAL", mtokens, OAException.CONFIRMATION, null);

			OADialogPage dialogPage = new OADialogPage(OAException.WARNING, message, null, "", "");

			String yes = pageContext.getMessage("XXCRM", "XX_SFA_048_YES", null);
			String no = pageContext.getMessage("XXCRM", "XX_SFA_049_NO", null);

			dialogPage.setOkButtonItemName("DeleteSiteYesButton");

			dialogPage.setOkButtonToPost(true);
			dialogPage.setNoButtonToPost(true);
			dialogPage.setPostToCallingPage(true);

			// seting  Yes/No labels instead of the default OK/Cancel.
			dialogPage.setOkButtonLabel(yes);
			dialogPage.setNoButtonLabel(no);

			java.util.Hashtable formParams = new java.util.Hashtable(1);
			formParams.put("siteID", siteID);
			formParams.put("siteAddress",siteAdr);
			dialogPage.setFormParameters(formParams);

			pageContext.redirectToDialogPage(dialogPage);
		}
		// if Remove Site is Confirmed
	    else if (pageContext.getParameter("DeleteSiteYesButton") != null)
		{
			Serializable[] parameters =  { pageContext.getParameter("siteID") };
			Class[] paramTypes = { String.class };

			am.invokeMethod("makeInactive", parameters, paramTypes);
			am.invokeMethod("commitAll");

			MessageToken[] mtokens = { new MessageToken("REQ_VAL", "Site "+pageContext.getParameter("siteAddress")) };
			throw new OAException("XXCRM","XX_SFA_047_DEL_CONFIRM", mtokens, OAException.CONFIRMATION, null);
		}

		// if task is to be removed, setting up the task removal confirmation dialog page
		else if (("REMOVE_TASK").equals(pageContext.getParameter(EVENT_PARAM)) )
		{
			String taskID = pageContext.getParameter("taskID");

			MessageToken[] mtokens = { new MessageToken("REQ_VAL", "the Task"),
										new MessageToken("REQ_VAL2", pageContext.getParameter("taskNAME")) };
			OAException message = new OAException("XXCRM","XX_SFA_046_CONFIRM_REMOVAL", mtokens, OAException.CONFIRMATION, null);

			OADialogPage dialogPage = new OADialogPage(OAException.WARNING, message, null, "", "");

			String yes = pageContext.getMessage("XXCRM", "XX_SFA_048_YES", null);
			String no = pageContext.getMessage("XXCRM", "XX_SFA_049_NO", null);

			dialogPage.setOkButtonItemName("DeleteTaskYesButton");

			dialogPage.setOkButtonToPost(true);
			dialogPage.setNoButtonToPost(true);
			dialogPage.setPostToCallingPage(true);

			//setting  Yes/No labels instead of the default OK/Cancel.
			dialogPage.setOkButtonLabel(yes);
			dialogPage.setNoButtonLabel(no);

			java.util.Hashtable formParams = new java.util.Hashtable(1);
			formParams.put("taskID", taskID);
			dialogPage.setFormParameters(formParams);

			pageContext.redirectToDialogPage(dialogPage);
		}
		// on confirmation to remove task, removing task
		// variable strTaskName added to appear in message - by Prabha
		else if (pageContext.getParameter("DeleteTaskYesButton") != null)
		{
			String strTaskName = pageContext.getParameter("taskNAME");
			Serializable[] parameters =  { pageContext.getParameter("taskID") };
			Class[] paramTypes = { String.class };
			am.invokeMethod("deleteTask", parameters, paramTypes);
			am.invokeMethod("commitAll");

			MessageToken[] mtokens = { new MessageToken("REQ_VAL", "Task "+strTaskName) };
			throw new OAException("XXCRM","XX_SFA_047_DEL_CONFIRM", mtokens, OAException.CONFIRMATION, null);
		}
		// setting up dialog page to confirm remove address
		else if (("REMOVE_ADDR").equals(pageContext.getParameter(EVENT_PARAM)) )
		{
			String contactID = pageContext.getParameter("contactID");
			String phnNum = pageContext.getParameter("phoneNUMBER");

			MessageToken[] mtokens = { new MessageToken("REQ_VAL", "the Address Book entry"),
										new MessageToken("REQ_VAL2", pageContext.getParameter("phoneNUMBER")) };
			OAException message = new OAException("XXCRM","XX_SFA_046_CONFIRM_REMOVAL", mtokens, OAException.CONFIRMATION, null);

			OADialogPage dialogPage = new OADialogPage(OAException.WARNING, message, null, "", "");

			String yes = pageContext.getMessage("XXCRM", "XX_SFA_048_YES", null);
			String no = pageContext.getMessage("XXCRM", "XX_SFA_049_NO", null);

			dialogPage.setOkButtonItemName("DeleteAddrYesButton");

			dialogPage.setOkButtonToPost(true);
			dialogPage.setNoButtonToPost(true);
			dialogPage.setPostToCallingPage(true);

			// setting our Yes/No labels instead of the default OK/Cancel.
			dialogPage.setOkButtonLabel(yes);
			dialogPage.setNoButtonLabel(no);

			java.util.Hashtable formParams = new java.util.Hashtable(1);
			formParams.put("contactID", contactID);
			formParams.put("phoneNumber", phnNum);
			dialogPage.setFormParameters(formParams);

			pageContext.redirectToDialogPage(dialogPage);
		}
		// if address is confirmed to be removed, removing address
		else if (pageContext.getParameter("DeleteAddrYesButton") != null)
		{
			Serializable[] parameters =  { pageContext.getParameter("contactID") };
			Class[] paramTypes = { String.class };
			am.invokeMethod("deletePhone",parameters,paramTypes);
			am.invokeMethod("commitAll");

			MessageToken[] mtokens = { new MessageToken("REQ_VAL", "The Address Book Entry "+pageContext.getParameter("phoneNumber")) };
			throw new OAException("XXCRM","XX_SFA_047_DEL_CONFIRM", mtokens, OAException.CONFIRMATION, null);
		}


		// Add Another Row button for Tasks
		else if (ADD_ROWS_EVENT.equals(pageContext.getParameter(EVENT_PARAM)))
		{
			//get the maximum number or rows that can be displayed in this table

			String nTableRows = null;
			OAAdvancedTableBean table = (OAAdvancedTableBean)webBean.findChildRecursive("TasksRN");
			if (table != null)
				nTableRows = Integer.toString(table.getNumberOfRowsDisplayed(pageContext));

			String ouId =  String.valueOf(pageContext.getOrgId());

			am.invokeMethod("addMoreRows", new String[]{nTableRows , partyId , partySiteId, ouId});
		}
		// If Cancel is clicked
		else if (pageContext.getParameter("Cancel") != null)
		{
			am.invokeMethod("rollbackAll");
			// Redirecting to View Site Page

			/*pageContext.forwardImmediately("XX_ASN_SITEVIEWPG"
	                                      , OAWebBeanConstants.KEEP_MENU_CONTEXT
	                                      , null
	                                      , params
	                                      , false
	                                      , OAWebBeanConstants.ADD_BREAD_CRUMB_YES);*/
        pageContext.putParameter("ASNReqFrmSiteId",callingSiteId);
        processTargetURL(pageContext, null, null);


		}
		// If Apply is clicked
		else if (pageContext.getParameter("Apply") != null)
		{
			Serializable[] parameters =  { partySiteName };
			Class[] paramTypes = { String.class };

			am.invokeMethod("commitAll",parameters,paramTypes);

			//Coming back to Site Update Page


            //Anirban: 2135 starts: for read-only partysite access

            pageContext.forwardImmediately("XX_ASN_SITE_UPDATE"
                                      , (byte)0 //OAWebBeanConstants.KEEP_MENU_CONTEXT
                                      , null
                                      , params
                                      , false
                                      , "Y"); //OAWebBeanConstants.ADD_BREAD_CRUMB_YES

            //Anirban: 2135 ends: for read-only partysite access
	       

		}

		else if (pageContext.getParameter("CancelYesButton") != null)
		{
			am.invokeMethod("rollbackAll");

	       /*pageContext.forwardImmediately("XX_ASN_SITEVIEWPG"
								      , OAWebBeanConstants.KEEP_MENU_CONTEXT
								      , null
								      , params
								      , false
								      , OAWebBeanConstants.ADD_BREAD_CRUMB_YES);*/
       pageContext.putParameter("ASNReqFrmSiteId",callingSiteId);
        processTargetURL(pageContext, null, null);
		}
		// Events in Attachments Region
		else if("oaAddAttachment".equals(pageContext.getParameter(EVENT_PARAM)) ||
			"oaUpdateAttachment".equals(pageContext.getParameter(EVENT_PARAM)) ||
			"oaDeleteAttachment".equals(pageContext.getParameter(EVENT_PARAM)) ||
			"oaViewAttachment".equals(pageContext.getParameter(EVENT_PARAM)) )
		{
			doCommit(pageContext,true);
			//call the common utility method.
			ASNUIUtil.attchEvent(pageContext,webBean);
		}
		else if(pageContext.getParameter("Go") != null)
		{
			String ActionValue = pageContext.getParameter("Actions");
			if(ActionValue != null)
			{
				doCommit(pageContext);
				pageContext.putParameter("ASNReqSelCustId", partyId);
				pageContext.putParameter("ASNReqSelCustName", partyName);
				pageContext.putParameter("ASNReqSelSiteId", partySiteId);
				pageContext.putParameter("ASNReqSelSiteName", partySiteName);

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
		//event handling for the contacts region
		else if (pageContext.getParameter("ContRelTableAddSiteContEvent") != null)
		{

      
      pageContext.putParameter("ASNReqFrmFuncName","XX_ASN_SITE_UPDATE");
      retainContextParameters(pageContext);

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
			// Commented as this gets added to the page level breadcrumb - by Prabha.
			/*this.modifyCurrentBreadcrumbLink(pageContext, // pageContext
	                                        true,        // replaceCurrentText
	                                        pageTitle,   // newText
	                                        false);      // resetRetainAMParam
            */

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
                // Create an contact in the context of an Site
                pageContext.writeDiagnostics(METHOD_NAME, "Before doCommit ASNReqCtxtFuncName :  "+ pageContext.getParameter("ASNReqCtxtFuncName"), 2);
                pageContext.writeDiagnostics(METHOD_NAME, "Before doCommit ASNReqFrmFuncName :  "+ pageContext.getParameter("ASNReqFrmFuncName"), 2);
                pageContext.putParameter("ASNReqFrmFuncName",pageContext.getParameter("ASNReqCtxtFuncName"));
                doCommit(pageContext);
                pageContext.writeDiagnostics(METHOD_NAME, "After doCommit ASNReqCtxtFuncName :  "+ pageContext.getParameter("ASNReqCtxtFuncName"), 2);
                pageContext.writeDiagnostics(METHOD_NAME, "After doCommit ASNReqFrmFuncName :  "+ pageContext.getParameter("ASNReqFrmFuncName"), 2);
                //doCommit(pageContext);
                //OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);
                //am.invokeMethod("clearContactsVOCache");
                pageContext.putParameter("ASNReqFrmFuncName","XX_ASN_SITE_UPDATE");
      
                retainContextParameters(pageContext);
                params.put("ASNReqFrmCustId", pageContext.getParameter("ASNReqFrmCustId"));
                params.put("ASNReqPgAct",pageContext.getParameter("ASNReqPgAct"));
                params.put("ASNReqFrmRelId",  pageContext.getParameter("ASNReqFrmRelId"));
                params.put("ASNReqFrmRelPtyId",  pageContext.getParameter("ASNReqFrmRelPtyId"));
                params.put("ASNReqFrmCustName",  pageContext.getParameter("ASNReqFrmCustName"));
                params.put("ASNReqFrmCtctId", pageContext.getParameter("ASNReqFrmCtctId"));
                params.put("ASNReqFrmCtctName",  pageContext.getParameter("ASNReqFrmCtctName"));
                params.put("ASNReqFrmSiteId",  partySiteId);
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
      	else if ("CallNotesDetail".equals(pageContext.getParameter("CacNotesDtlEvent")))
      	{
    		doCommit(pageContext);
        }

        else if(pageContext.getParameter("CreateAddress") != null)
        {

      		MessageToken amessagetoken[] = {new MessageToken("PARTYNAME", partyName)};
		String s5 = pageContext.getMessage("ASN", "ASN_TCA_UPDT_CUST_TITLE", amessagetoken);

      		HashMap hashmap = new HashMap();
      		hashmap.put("BCL", "BCLRT");
      		hashmap.put("BCLT", s5);

		params.put("HzPuiAddressPartyId", partyId);
		params.put("HzPuiAddressEvent", "CREATE");
		pageContext.putParameter("HzPuiAddressEvent", "CREATE");
		pageContext.putParameter("ASNReqPgAct", "SUBFLOW");
		params.put("ASNReqFrmFuncName", "ASN_CUSTADDRCREATEUPDATEPG");
		params.put("ASNReqFrmCustId",partyId);
		params.put("ASNReqFrmCustName",partyName);
		params.put("HzPuiAddressEvent", "CREATE");
		params.put("ASNReqFrmFuncName", "XX_ASN_SITE_UPDATE");

		pageContext.forwardImmediately("ASN_CUSTADDRCREATEUPDATEPG"
                                      , OAWebBeanConstants.KEEP_MENU_CONTEXT
                                      , null
                                      , params
                                      , false
                                      , OAWebBeanConstants.ADD_BREAD_CRUMB_YES);


        }
        else if(("UPDATE_EVENT").equals(pageContext.getParameter(EVENT_PARAM)))
        {

	    MessageToken amessagetoken[] = { new MessageToken("PARTYNAME", partyName) };

            String s5 = pageContext.getMessage("ASN", "ASN_TCA_UPDT_CUST_TITLE", amessagetoken);
            HashMap hashmap = new HashMap();
      			hashmap.put("BCL", "BCLRT");
      			hashmap.put("BCLT", s5);

        		String siteId = pageContext.getParameter("siteID");
            params.put("HzPuiAddressPartyId", partyId);
            params.put("HzPuiAddressEvent", "UPDATE");
            pageContext.putParameter("HzPuiAddressEvent", "UPDATE");
            params.put("HzPuiAddressPartySiteId", siteId);
            pageContext.putParameter("ASNReqPgAct", "SUBFLOW");

            params.put("ASNReqFrmCustId",partyId);
            params.put("ASNReqFrmCustName",partyName);
            params.put("HzPuiAddressEvent", "UPDATE");
            params.put("ASNReqFrmFuncName", "XX_ASN_SITE_UPDATE");

            pageContext.forwardImmediately("ASN_CUSTADDRCREATEUPDATEPG"
                                      , OAWebBeanConstants.KEEP_MENU_CONTEXT
                                      , null
                                      , params
                                      , false
                                      , OAWebBeanConstants.ADD_BREAD_CRUMB_YES);
        }

        else if(("TASK_VIEW").equals(pageContext.getParameter(EVENT_PARAM)))
        {
            params.put("cacTaskId",pageContext.encrypt(pageContext.getParameter("taskID")));

            params.put("cacTaskCustId",partyId);
            params.put("ASNTxnCustomerId", partyId);
            params.put("ASNTxnNoteSourceCode", "PARTY");
            params.put("ASNTxnNoteSourceId", partyId);
            params.put("cacTaskSrcObjCode", "PARTY");
            params.put("cacTaskSrcObjId", partyId);
            params.put("cacTaskCustId", partyId);
            params.put("cacTaskContDqmRule", pageContext.getProfile("HZ_DQM_CON_SIMPLE_MATCHRULE"));
            params.put("cacTaskNoDelDlg", "Y");
            params.put("cacTaskReturnUrl", getModifiedCurrentUrlForRedirect(pageContext, true));


            pageContext.putTransactionValue("ASNTxnCustomerId", partyId);
            pageContext.putTransactionValue("ASNTxnNoteSourceCode", "PARTY");
            pageContext.putTransactionValue("ASNTxnNoteSourceId", partyId);
            pageContext.putTransactionValue("cacTaskSrcObjCode", "PARTY");
            pageContext.putTransactionValue("cacTaskSrcObjId", partyId);
            pageContext.putTransactionValue("cacTaskCustId", partyId);
            pageContext.putTransactionValue("cacTaskContDqmRule", pageContext.getProfile("HZ_DQM_CON_SIMPLE_MATCHRULE"));
            pageContext.putTransactionValue("cacTaskNoDelDlg", "Y");
            pageContext.putTransactionValue("cacTaskReturnUrl", getModifiedCurrentUrlForRedirect(pageContext, true));

			// 1 = View Mode
            byte byte0 = 1;
            boolean flag = false;

			params.put("cacTaskUsrAuth", pageContext.encrypt(String.valueOf(byte0)));
            params.put("CacBasePageRegionCode", "/od/oracle/apps/xxcrm/asn/partysite/webui/SiteUpdatePG");
            pageContext.setForwardURL("CAC_TASK_UPDATE", byte0, null, params, flag, "Y", (byte)99);
        }
        else if(("TASK_UPDATE").equals(pageContext.getParameter(EVENT_PARAM)))
        {

            params.put("cacTaskId",pageContext.encrypt(pageContext.getParameter("taskID")));

            params.put("cacTaskCustId",partyId);
            params.put("ASNTxnCustomerId", partyId);
            params.put("ASNTxnNoteSourceCode", "PARTY");
            params.put("ASNTxnNoteSourceId", partyId);
            params.put("cacTaskSrcObjCode", "PARTY");
            params.put("cacTaskSrcObjId", partyId);
            params.put("cacTaskCustId", partyId);
            params.put("cacTaskContDqmRule", pageContext.getProfile("HZ_DQM_CON_SIMPLE_MATCHRULE"));
            params.put("cacTaskNoDelDlg", "Y");
            params.put("cacTaskReturnUrl", getModifiedCurrentUrlForRedirect(pageContext, true));


            pageContext.putTransactionValue("ASNTxnCustomerId", partyId);
            pageContext.putTransactionValue("ASNTxnNoteSourceCode", "PARTY");
            pageContext.putTransactionValue("ASNTxnNoteSourceId", partyId);
            pageContext.putTransactionValue("cacTaskSrcObjCode", "PARTY");
            pageContext.putTransactionValue("cacTaskSrcObjId", partyId);
            pageContext.putTransactionValue("cacTaskCustId", partyId);
            pageContext.putTransactionValue("cacTaskContDqmRule", pageContext.getProfile("HZ_DQM_CON_SIMPLE_MATCHRULE"));
            pageContext.putTransactionValue("cacTaskNoDelDlg", "Y");
            pageContext.putTransactionValue("cacTaskReturnUrl", getModifiedCurrentUrlForRedirect(pageContext, true));

			// 2= Update Mode
            byte byte0 = 2;
            boolean flag = false;

            params.put("cacTaskUsrAuth", pageContext.encrypt(String.valueOf(byte0)));
            params.put("CacBasePageRegionCode", "/od/oracle/apps/xxcrm/asn/partysite/webui/SiteUpdatePG");
            pageContext.setForwardURL("CAC_TASK_UPDATE", byte0, null, params, flag, "Y", (byte)99);

        }
		else if (pageContext.getParameter("GoToParty")!=null)
		{

            pageContext.forwardImmediately("ASN_ORGVIEWPG"
                                      , OAWebBeanConstants.KEEP_MENU_CONTEXT
                                      , null
                                      , params
                                      , false
                                      , OAWebBeanConstants.ADD_BREAD_CRUMB_YES);

		}

		else if (pageContext.getParameter("GoBtn")!=null)
		{
            params.put("HzPuiOwnerTableName", "HZ_PARTY_SITES");
            params.put("HzPuiOwnerTableId", partySiteId);
            params.put("HzPuiCntctPointEvent", "CREATE");
            params.put("HzPuiPhoneLineType", pageContext.getParameter("Create"));
            params.put("ASNReqFrmCustId",partyId);
            params.put("ASNReqFrmCustName",partyName);
            params.put("ASNReqFrmSiteId", partySiteId);
            params.put("ASNReqFrmSiteName", partySiteName);

            pageContext.putParameter("ASNReqPgAct", "SUBFLOW");
            params.put("ASNReqFrmFuncName", "XX_ASN_SITE_UPDATE");

            pageContext.forwardImmediately("XX_ASN_SITE_PHN_CREATEUPDATEPG"
                                      , OAWebBeanConstants.KEEP_MENU_CONTEXT
                                      , null
                                      , params
                                      , false
                                      , OAWebBeanConstants.ADD_BREAD_CRUMB_YES);


		}
		else if (("UPDATE_PHONE").equals(pageContext.getParameter(EVENT_PARAM)) )
		{
			String  contactID = pageContext.getParameter("contactID");

            params.put("ASNReqFrmCustId",partyId);
            params.put("ASNReqFrmCustName",partyName);
            params.put("ASNReqFrmSiteId", partySiteId);
            params.put("ASNReqFrmSiteName", partySiteName);

            params.put("HzPuiOwnerTableName", "HZ_PARTY_SITES");
            params.put("HzPuiOwnerTableId", partySiteId);
            params.put("HzPuiCntctPointEvent", "UPDATE");
            params.put("HzPuiContactPointId", contactID);
            pageContext.putParameter("ASNReqPgAct", "SUBFLOW");
            params.put("ASNReqFrmFuncName", "XX_ASN_SITE_UPDATE");

            pageContext.forwardImmediately("XX_ASN_SITE_PHN_CREATEUPDATEPG"
                                      , OAWebBeanConstants.KEEP_MENU_CONTEXT
                                      , null
                                      , params
                                      , false
                                      , OAWebBeanConstants.ADD_BREAD_CRUMB_YES);


		}
    if (isProcLogEnabled)
    {
    pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }

  }

}
