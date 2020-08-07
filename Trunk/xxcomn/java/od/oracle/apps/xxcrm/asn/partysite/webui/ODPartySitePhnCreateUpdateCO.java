/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.partysite.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.nav.OAPageButtonBarBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import com.sun.java.util.collections.HashMap;
import oracle.jbo.common.Diagnostic;
import oracle.apps.fnd.framework.server.OADBTransaction;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.asn.common.fwk.webui.ASNControllerObjectImpl;
import oracle.apps.fnd.framework.OAFwkConstants;
import od.oracle.apps.xxcrm.asn.common.fwk.webui.ODASNControllerObjectImpl;
import oracle.apps.fnd.framework.OAApplicationModule;
import od.oracle.apps.xxcrm.asn.partysite.server.ODPartySitePhnCreateUpdateAMImpl;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.OAException;


/**
 * Controller for ...
 */
public class ODPartySitePhnCreateUpdateCO extends ODASNControllerObjectImpl
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
  // Call the parent class process request
    super.processRequest(pageContext, webBean);

  //disable the breadcrumbs
	//((OAPageLayoutBean) webBean).setBreadCrumbEnabled(false);

  // Parameters passed from OD Site Update Page.
    String partyId = (String) pageContext.getParameter("ASNReqFrmCustId");
    String partyName = (String) pageContext.getParameter("ASNReqFrmCustName");
    String siteAddress = (String) pageContext.getParameter("ASNReqFrmSiteAdd");
    String returnFunction = (String) pageContext.getParameter("ASNReqCallingPage");
    String cntctPointEvent = (String) pageContext.getParameter("HzPuiCntctPointEvent");
    String HzPuiPhoneLineType = (String) pageContext.getParameter("HzPuiPhoneLineType");
    String HzPuiCntctPointId = (String) pageContext.getParameter("HzPuiCntctPointId");
    String HzPuiOwnerTableName = "HZ_PARTY_SITES";
   // String HzPuiOwnerTableId  = (String) pageContext.getParameter("ODSiteID");
    String HzPuiOwnerTableId  = (String) pageContext.getParameter("ASNReqFrmSiteId");

  // Checking event values
    if(cntctPointEvent !=null && cntctPointEvent.equals("UPDATE"))  {
       OAPageButtonBarBean pb = (OAPageButtonBarBean)pageContext.getPageLayoutBean().getPageButtons();
       OASubmitButtonBean saveAndAddAnotherButton = (OASubmitButtonBean)pb.findIndexedChildRecursive("ASNSavExit");
       saveAndAddAnotherButton.setRendered(false);

        MessageToken[] tokens = { new MessageToken("PARTYNAME", partyName) };
        String pageTitle =    pageContext.getMessage("ASN", "ASN_TCA_UPDT_PHONE_TITLE", tokens);
       // Set the page title (which also appears in the breadcrumbs)
       ((OAPageLayoutBean)webBean).setTitle(pageTitle);
    }else if(cntctPointEvent !=null && cntctPointEvent.equals("CREATE")) {
    MessageToken[] tokens = { new MessageToken("PARTYNAME", partyName) };
       String pageTitle = pageContext.getMessage("ASN", "ASN_TCA_CRTE_PHONE_TITLE", tokens);
       // Set the page title (which also appears in the breadcrumbs)
       ((OAPageLayoutBean)webBean).setTitle(pageTitle);
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
    super.processFormRequest(pageContext, webBean);
    OAApplicationModule am = (OAApplicationModule) pageContext.getApplicationModule(webBean);

    String partyId = (String) pageContext.getParameter("ASNReqFrmCustId");
    String partyName = (String) pageContext.getParameter("ASNReqFrmCustName");
    String partySiteID = (String) pageContext.getParameter("ASNReqFrmSiteId");

       HashMap params = new HashMap();
     if (pageContext.getParameter("ASNApply") != null )
    {
      // 'Apply' Button clicked :commit
      OAMessageTextInputBean phnBean = (OAMessageTextInputBean)webBean.findIndexedChildRecursive("PhoneNumber");
	        if (phnBean == null) {throw new OAException("XXCRM", "XX_SFA_054_SITEPHN_REQDFIELD");}

 am.invokeMethod("commitAll");
  //passing required params
       params.put("ASNReqFrmCustName", partyName);
       params.put("ASNReqFrmCustId",partyId);
       params.put("HzPuiOwnerTableName", "HZ_PARTY_SITES");
       params.put("HzPuiOwnerTableId", partySiteID);
       params.put("HzPuiCntctPointEvent", "CREATE");
       params.put("HzPuiPhoneLineType", pageContext.getParameter("HzPuiPhoneLineType"));
       params.put("HzPuiContactPointChanged", "NO");
       pageContext.putParameter("ASNReqFrmSiteId", partySiteID);

      processTargetURL(pageContext,params,null);
    }
    // 'Save and Create Another' button clicked
    else if (pageContext.getParameter("ASNSavExit") != null )
    {
		OAMessageTextInputBean phnBean = (OAMessageTextInputBean)webBean.findIndexedChildRecursive("PhoneNumber");
      if (phnBean == null) {throw new OAException("XXCRM", "XX_SFA_054_SITEPHN_REQDFIELD");}

      // commit
am.invokeMethod("commitAll");

      params.put("ASNReqFrmCustName", partyName);
      params.put("ASNReqFrmCustId",partyId);
      params.put("HzPuiOwnerTableName", "HZ_PARTY_SITES");
      params.put("HzPuiOwnerTableId", partySiteID);
      params.put("HzPuiCntctPointEvent", "CREATE");
      params.put("HzPuiPhoneLineType", pageContext.getParameter("HzPuiPhoneLineType"));
      params.put("HzPuiContactPointChanged", "NO");
      params.put("ASNReqFrmSiteId", partySiteID);

      pageContext.forwardImmediatelyToCurrentPage(params,
                    false,
                    ADD_BREAD_CRUMB_SAVE);
    }
    // 'Cancel' button clicked
    else if (pageContext.getParameter("ASNCancelBtn") != null )
    {
		am.getTransaction().rollback();
      processTargetURL(pageContext,null,null);
    }
  }

}
