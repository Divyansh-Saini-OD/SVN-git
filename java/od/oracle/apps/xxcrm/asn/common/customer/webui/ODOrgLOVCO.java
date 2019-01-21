/*===========================================================================+
 |      Copyright (c) 2001 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 |  Aug-03      mkatraga  Created                                            |
 |  12/10/2004  rramacha  AM is retained when toggling between search modes. |
 |                        Breadcrumb is saved instead of adding during toggle|
 |                        to avoid adding breadcrumb of customer lov page    |
 |                        when drilling down to customer details after a     |
 |                        toggle. AutoQuery parameter is not set anymore.    |
 |                        TCA parameters are verified and removed the ones   |
 |                        that are not necessary to be set.                  |
 |                        Bugs 4000423 is fixed.                             |
 |  05/11/05  vpalaiya  Removed OALinkBean reference as CPUI changed the item|
 |                      type from link to switcher.                          |
 +===========================================================================*/
 /*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODOrgLOVCO.java                                               |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Customer LOV controller file                                           |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |                                                                           |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |   24-Dec-2007 Anirban Chaudhuri   Fixed code for defect#187 in ASN Tracker|
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.common.customer.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.OABodyBean;
import oracle.apps.asn.common.fwk.webui.ASNControllerObjectImpl;
import com.sun.java.util.collections.HashMap;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.ar.hz.components.util.webui.HzPuiWebuiUtil;
import oracle.apps.fnd.framework.OAApplicationModule;
import java.io.Serializable;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.asn.common.fwk.webui.ASNUIConstants;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.layout.OATableLayoutBean;
import com.sun.java.util.collections.ArrayList;
import oracle.jbo.Row;
import java.util.Hashtable;
import oracle.jbo.domain.Number;
import java.util.Enumeration;
import com.sun.java.util.collections.HashMap;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.jbo.common.Diagnostic;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.beans.table.OAHGridBean;
import oracle.apps.fnd.framework.webui.OAHGridQueriedRowEnumerator;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.OAApplicationModule;
/**
 * Controller for ...
 */
public class ODOrgLOVCO extends ASNControllerObjectImpl
{
  public static final String RCS_ID="$Header: OrgLOVCO.java 115.21.115200.2 2005/10/14 17:29:57 vpalaiya ship $";
  public static final boolean RCS_ID_RECORDED =
         VersionInfo.recordClassVersion(RCS_ID, "od.oracle.apps.xxcrm.asn.common.customer.webui");

  /**
   * Layout and page setup logic for AK region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    final String METHOD_NAME = "xxcrm.asn.common.customer.webui.ODOrgLOVCO.processRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processRequest(pageContext, webBean);

    // - Multiple clicks - fix
    OAWebBean bodyBean = pageContext.getRootWebBean();
    if (bodyBean!=null && bodyBean instanceof OABodyBean)
    {
      ((OABodyBean)bodyBean).setBlockOnEverySubmit(true);
    }

    //disable the breadcrumbs
    ((OAPageLayoutBean) webBean).setBreadCrumbEnabled(false);

    //If it is a subflow page, need to retain context parameters here
    retainContextParameters(pageContext);

    //hide the un-supported items in the tca components that should not be personalized by the user
    //dqm search results section
    OATableLayoutBean asnDQMSearchResultsRN = (OATableLayoutBean) webBean.findChildRecursive("ASNDQMSearchResultsRN");
    if(asnDQMSearchResultsRN != null)
    {
      //hide the un-used buttons
      OASubmitButtonBean hzPuiMarkDupButton=  (OASubmitButtonBean)asnDQMSearchResultsRN.findChildRecursive("HzPuiMarkDup");
      if(hzPuiMarkDupButton != null)
      {
        hzPuiMarkDupButton.setRendered(false);
      }

      OASubmitButtonBean hzPuiPurchaseButton=  (OASubmitButtonBean)asnDQMSearchResultsRN.findChildRecursive("HzPuiPurchase");
      if(hzPuiPurchaseButton != null)
      {
        hzPuiPurchaseButton.setRendered(false);
      }

      OASubmitButtonBean hzPuiSelectOrgButton=  (OASubmitButtonBean)asnDQMSearchResultsRN.findChildRecursive("HzPuiSelectOrgButton");
      if(hzPuiSelectOrgButton != null)
      {
        hzPuiSelectOrgButton.setRendered(false);
      }

      //hide update icon column in the dqm search results table
      // Hide the "Update" bean. Made changes here for backward compatibility as TCA
      // CPUI component changed from Link to Switcher Bean. Original reference to OALinkBean
      // is removed as part of the fix.
      if(asnDQMSearchResultsRN.findChildRecursive("Update") != null)
      {
        asnDQMSearchResultsRN.findChildRecursive("Update").setRendered(false);
      }
    }
    //dqm search results section
    //end of hiding the un-supported items in tca components that should not be personalizable

    String custSimpleMatchRuleId = (String) pageContext.getProfile("HZ_DQM_ORG_SIMPLE_MATCHRULE");
    String custAdvMatchRuleId    = (String) pageContext.getProfile("HZ_DQM_ORG_ADV_MATCHRULE");

    pageContext.putParameter("HzPuiSearchType", "SIMPLEADV");
    pageContext.putParameter("HzPuiSearchPartyType", "ORGANIZATION");
    pageContext.putParameter("HzPuiSearchComponentMode", "LOV");
    pageContext.putParameter("HzPuiSimpleMatchRuleId", custSimpleMatchRuleId);
    pageContext.putParameter("HzPuiAdvMatchRuleId", custAdvMatchRuleId);
    pageContext.putParameter("HzPuiClassificationFilter", "Y");
    pageContext.putParameter("HzPuiRelationshipFilter", "Y");
    //This parameter is set for TCA to further filter DQM search results with
    //ASN security SQL.
    //pageContext.putParameter("HzPuiDQMOrgSearchExtraWhereClause", getSecurityRestrictiveSql(pageContext, webBean));

	pageContext.putParameter("HzPuiDQMOrgSearchExtraWhereClause", "");


  	String searchMode = pageContext.getParameter("HzPuiSearchMode");
  	if(searchMode == null)
  	{
      pageContext.putParameter("HzPuiSearchMode", "SIMPLE");
    }

    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }
  }

  /**
   * Procedure to handle form submissions for form elements in
   * AK region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    final String METHOD_NAME = "xxcrm.asn.common.customer.webui.ODOrgLOVCO.processFormRequest";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    super.processFormRequest(pageContext, webBean);

    String custSimpleMatchRuleId = (String) pageContext.getProfile("HZ_DQM_ORG_SIMPLE_MATCHRULE");
    String custAdvMatchRuleId    = (String) pageContext.getProfile("HZ_DQM_ORG_ADV_MATCHRULE");

    pageContext.putParameter("HzPuiSearchType", "SIMPLEADV");
    pageContext.putParameter("HzPuiSearchPartyType", "ORGANIZATION");
    pageContext.putParameter("HzPuiSearchComponentMode", "LOV");
    pageContext.putParameter("HzPuiSimpleMatchRuleId", custSimpleMatchRuleId);
    pageContext.putParameter("HzPuiAdvMatchRuleId", custAdvMatchRuleId);
    //This parameter is set for TCA to further filter DQM search results with
    //ASN security SQL.
    //pageContext.putParameter("HzPuiDQMOrgSearchExtraWhereClause", getSecurityRestrictiveSql(pageContext, webBean));

	pageContext.putParameter("HzPuiDQMOrgSearchExtraWhereClause", "");

    HashMap params = new HashMap();
    //Handle toggle search event of TCA component to switch the search mode.
    if (pageContext.getParameter("HzPuiToggleSearch") != null)
    {
      String searchMode = pageContext.getParameter("HzPuiSearchMode");
      // Search mode is set in pageContext to support back button as uRL param
      // may not be available in certain scenarios.
      pageContext.putParameter("HzPuiSearchMode", ("ADV".equals(searchMode) ? "SIMPLE" : "ADV"));
      params.put("HzPuiSearchMode", ("ADV".equals(searchMode) ? "SIMPLE" : "ADV"));
      pageContext.forwardImmediatelyToCurrentPage(params, true, ADD_BREAD_CRUMB_SAVE);
    }
     //If the user clicked on the select Button
    else if (pageContext.getParameter("ASNPageSelBtn") != null)
    {
      String sPartyId = null;
      String sPartyName = null;
      sPartyId = getSelectedOrgId( pageContext, webBean);
      if ( sPartyId == null )
      {
        OAException e = new OAException("ASN", "ASN_CMMN_RADIO_MISS_ERR");
        throw e;
      }
      OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);
      Serializable[] parameters =  { sPartyId };
      sPartyName = (String) am.invokeMethod("getPartyNameFromId", parameters);

      pageContext.putParameter("ASNReqSelCustId", sPartyId);
      pageContext.putParameter("ASNReqSelCustName", sPartyName);

      pageContext.putParameter("ASNReqSelPartySiteId", getSelectedAddressId(pageContext, webBean));
	  pageContext.putParameter("ASNReqSelLocationId", getSelectedLocationId(pageContext, webBean));
	  pageContext.putParameter("ASNReqSelAddress", getSelectedAddress(pageContext, webBean));
	  pageContext.putParameter("ASNReqSelSiteId", getSelectedAddressId(pageContext, webBean));
	  pageContext.putParameter("ASNReqSelSiteName", getSelectedAddress(pageContext, webBean));

      HashMap conditions = new HashMap();
      conditions.put(ASNUIConstants.RETAIN_AM, "Y");
      pageContext.releaseRootApplicationModule();
      this.processTargetURL(pageContext, conditions, null);
    }
    //If the user clicked on the cancel Button
    else if(pageContext.getParameter("ASNPageCnclBtn") != null)
    {
      HashMap conditions = new HashMap();
      conditions.put(ASNUIConstants.RETAIN_AM, "Y");
      pageContext.releaseRootApplicationModule();
      this.processTargetURL(pageContext, conditions, null);
    }
    else if (pageContext.getParameter("HzPuiCreate") != null)
    {
      pageContext.releaseRootApplicationModule();
		  params.put("ASNReqFrmFuncName", "ASN_ORGCREATEPG");
		  params.put("ASNReqFromLOVPage", "TRUE");
      pageContext.forwardImmediately("ASN_ORGCREATEPG",
                    KEEP_MENU_CONTEXT ,
                    null,
                    params,
                    true,
                    ADD_BREAD_CRUMB_SAVE);
    }
    else if ("PARTYDETAIL".equals(pageContext.getParameter("HzPuiEvent")))
    {
      params.put("ASNReqFrmCustId", pageContext.getParameter("HzPuiPartyId"));
      params.put("ASNReqFrmCustName", pageContext.getParameter("HzPuiPartyName"));
      pageContext.putParameter("ASNReqPgAct","CUSTDET");
      this.processTargetURL(pageContext, null, params);
    }
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }
  }

  /**
   * Method to create and fetch the extra security
   * where clause to be passed as a parameter to TCA
   * components for restricting the search
   *
   * @param pageContext the current OA page context
   *
   */
 public String getSecurityRestrictiveSql(OAPageContext pageContext, OAWebBean webBean)
  {
    final String METHOD_NAME = "xxcrm.asn.common.customer.webui.ODOrgLOVCO.getSecurityRestrictiveSql";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    StringBuffer extraClause = new StringBuffer();

    // jezhou 12/02/2004 support full access
    String accessProfileValue = null;
    accessProfileValue = (String) pageContext.getProfile("ASN_CUST_ACCESS");
    if(accessProfileValue==null || "".equals(accessProfileValue.trim()))
      accessProfileValue = "T";

    if("F".equals(accessProfileValue))
    {
      // no ops
    }
    if("T".equals(accessProfileValue) || "S".equals(accessProfileValue))
    {
      String managerFlag;
      String standaloneMemberFlag;
      String resourceId = this.getLoginResourceId(pageContext.getApplicationModule(webBean),pageContext);

      boolean mf = this.isLoginResourceManager(pageContext.getApplicationModule(webBean), pageContext);

      ArrayList managerGroupIds = this.getManagerGroupIds(pageContext.getApplicationModule(webBean),pageContext);

      ArrayList adminGroupIds = this.getAdminGroupIds(pageContext.getApplicationModule(webBean),pageContext);

      boolean isStandaloneMember = this.isStandaloneMember(pageContext.getApplicationModule(webBean),pageContext);

      if(mf)
      {
        managerFlag = "Y";
      }else
      {
        managerFlag = "N";
      }

      if(isStandaloneMember)
      {
        standaloneMemberFlag = "Y";
      }else
      {
        standaloneMemberFlag = "N";
      }

      if("N".equals(managerFlag) ||
         ("Y".equals(managerFlag) &&
          ((managerGroupIds == null || (managerGroupIds != null && managerGroupIds.size()<=0)) &&
           (adminGroupIds == null || (adminGroupIds != null && adminGroupIds.size()<=0)))))
      {
/* old query
        extraClause.append(" ( party_id in ( SELECT secu.customer_id ");
        extraClause.append(" FROM    as_accesses_all secu");
        extraClause.append(" WHERE   secu.sales_lead_id IS NULL ");
        extraClause.append(" AND     secu.lead_id IS NULL ");
        extraClause.append(" AND      salesforce_id  = ");
        extraClause.append(resourceId);
        extraClause.append(" AND      salesforce_id+0  = ");
        extraClause.append(resourceId);
        extraClause.append(") )");
new query */
		extraClause.append(" ( party_site_id in ( SELECT hzps.party_site_id  ");
		extraClause.append(" FROM XX_TM_NAM_TERR_CURR_ASSIGN_V aaa, HZ_PARTY_SITES hzps ");
		extraClause.append(" WHERE aaa.entity_type='PARTY_SITE'   AND hzps.party_site_id = aaa.entity_id   AND hzps.status = 'A'   and aaa.resource_id = ");
		extraClause.append(resourceId);
		extraClause.append(" and fnd_profile.value('ASN_CUST_ACCESS')= 'S' ");
		extraClause.append(" UNION   ");
		extraClause.append(" SELECT hzps.party_site_id   ");
		extraClause.append(" FROM XX_TM_NAM_TERR_CURR_ASSIGN_V aaa,HZ_PARTY_SITES hzps  ");
		extraClause.append(" WHERE aaa.entity_type='PARTY_SITE'   AND hzps.party_site_id = aaa.entity_id AND aaa.resource_id = ");
		extraClause.append(resourceId);
		extraClause.append(" and fnd_profile.value('ASN_CUST_ACCESS')= 'T' ");
		extraClause.append(") )");
      }

      if("Y".equals(managerFlag) &&
         ((managerGroupIds != null && managerGroupIds.size()>0) ||
          (adminGroupIds != null && adminGroupIds.size()>0)))
      {
/* old query
        extraClause.append(" ( party_id in ( SELECT secu.customer_id ");
        extraClause.append(" FROM    as_accesses_all secu ");
        extraClause.append(" WHERE   secu.sales_group_id in ( ");
        extraClause.append(" SELECT  jrgd.group_id ");
        extraClause.append(" FROM    jtf_rs_groups_denorm jrgd, ");
        extraClause.append(" jtf_rs_group_usages  jrgu ");
        extraClause.append(" WHERE   jrgd.parent_group_id  IN ( ");
new query */
		extraClause.append(" ( party_site_id in ( SELECT hzps.party_site_id  ");
		extraClause.append(" FROM JTF_RS_GROUP_USAGES jrgu,JTF_RS_GROUPS_DENORM b,XX_TM_NAM_TERR_CURR_ASSIGN_V aaa,HZ_PARTY_SITES hzps,HZ_PARTY_SITE_USES hzpsu,FND_LOOKUP_VALUES  fndl ");
		extraClause.append(" WHERE aaa.group_id = b.group_id   AND aaa.entity_type='PARTY_SITE'   AND hzps.party_site_id = aaa.entity_id   AND hzpsu.party_site_id = hzps.party_site_id   AND fndl.lookup_type = 'XXOD_ASN_PARTY_SEC_SITE_TYPES'   AND hzpsu.site_use_type = fndl.lookup_code   AND hzps.status = 'A'   AND nvl(hzps.identifying_address_flag,'N') = 'Y'   AND hzpsu.status = 'A'   and aaa.resource_id <> ");
		extraClause.append(resourceId);
		extraClause.append(" AND jrgu.usage IN ('SALES', 'PRM')   AND jrgu.group_id = b.group_id   and b.start_date_active <= TRUNC(sysdate)   and NVL(b.end_date_Active, sysdate) >= TRUNC(sysdate)   and fnd_profile.value('ASN_CUST_ACCESS')= 'S' ");
		extraClause.append(" and b.parent_group_id  IN ( ");

        if(managerGroupIds != null && managerGroupIds.size()>0)
        {
          extraClause.append(managerGroupIds.get(0));
          for(int i=1; i<managerGroupIds.size(); i++)
          {
            extraClause.append(", ");
            extraClause.append(managerGroupIds.get(i));
          }
          if(adminGroupIds != null)
          {
            for(int i=0; i<adminGroupIds.size(); i++)
            {
              extraClause.append(", ");
              extraClause.append(adminGroupIds.get(i));
            }
          }
        }
        else
        {
          if(adminGroupIds != null)
          {
            extraClause.append(adminGroupIds.get(0));
            for(int i=1; i<adminGroupIds.size(); i++)
            {
              extraClause.append(", ");
              extraClause.append(adminGroupIds.get(i));
            }
          }
        }
        extraClause.append(" ) ");

		extraClause.append(" UNION   ");
		extraClause.append(" SELECT hzps.party_site_id   ");
		extraClause.append(" FROM JTF_RS_GROUP_USAGES jrgu,JTF_RS_GROUPS_DENORM b,XX_TM_NAM_TERR_CURR_ASSIGN_V aaa,HZ_PARTY_SITES hzps  ");
		extraClause.append(" WHERE aaa.group_id = b.group_id    AND aaa.entity_type='PARTY_SITE'    AND hzps.party_site_id = aaa.entity_id AND aaa.resource_id <> ");
		extraClause.append(resourceId);
		extraClause.append(" AND jrgu.usage IN ('SALES', 'PRM')    AND jrgu.group_id = b.group_id    and b.start_date_active <= TRUNC(sysdate)    and NVL(b.end_date_Active, sysdate) >= TRUNC(sysdate)    and fnd_profile.value('ASN_CUST_ACCESS')= 'T' ");
		extraClause.append(" and b.parent_group_id  IN ( ");

        if(managerGroupIds != null && managerGroupIds.size()>0)
        {
          extraClause.append(managerGroupIds.get(0));
          for(int i=1; i<managerGroupIds.size(); i++)
          {
            extraClause.append(", ");
            extraClause.append(managerGroupIds.get(i));
          }
          if(adminGroupIds != null)
          {
            for(int i=0; i<adminGroupIds.size(); i++)
            {
              extraClause.append(", ");
              extraClause.append(adminGroupIds.get(i));
            }
          }
        }
        else
        {
          if(adminGroupIds != null)
          {
            extraClause.append(adminGroupIds.get(0));
            for(int i=1; i<adminGroupIds.size(); i++)
            {
              extraClause.append(", ");
              extraClause.append(adminGroupIds.get(i));
            }
          }
        }
		extraClause.append(" ) ");

/* old query
        extraClause.append(" AND     jrgd.start_date_active <= TRUNC(SYSDATE)");
        extraClause.append(" AND     NVL(jrgd.end_date_active, SYSDATE) >= TRUNC(SYSDATE) ");
        extraClause.append(" AND     jrgu.group_id = jrgd.group_id ");
        extraClause.append(" AND     jrgu.usage  in ('SALES', 'PRM')) ");
        extraClause.append(" AND   secu.lead_id IS NULL ");
        extraClause.append(" AND   secu.sales_lead_id IS NULL ");
*/
        if("Y".equals(standaloneMemberFlag))
        {
/* old query
          extraClause.append(" UNION ALL ");
          extraClause.append(" SELECT secu.customer_id ");
          extraClause.append(" FROM    as_accesses_all secu");
          extraClause.append(" WHERE   secu.sales_lead_id IS NULL ");
          extraClause.append(" AND     secu.lead_id IS NULL ");
          extraClause.append(" AND      salesforce_id  = ");
          extraClause.append(resourceId);
          extraClause.append(" AND      salesforce_id+0  = ");
          extraClause.append(resourceId);
          extraClause.append(") )");
new query */
		extraClause.append(" UNION ALL ");
		extraClause.append(" SELECT hzps.party_site_id  ");
		extraClause.append(" FROM XX_TM_NAM_TERR_CURR_ASSIGN_V aaa, HZ_PARTY_SITES hzps ");
		extraClause.append(" WHERE aaa.entity_type='PARTY_SITE'   AND hzps.party_site_id = aaa.entity_id   AND hzps.status = 'A'   and aaa.resource_id = ");
		extraClause.append(resourceId);
		extraClause.append(" and fnd_profile.value('ASN_CUST_ACCESS')= 'S' ");
		extraClause.append(" UNION   ");
		extraClause.append(" SELECT hzps.party_site_id   ");
		extraClause.append(" FROM XX_TM_NAM_TERR_CURR_ASSIGN_V aaa,HZ_PARTY_SITES hzps  ");
		extraClause.append(" WHERE aaa.entity_type='PARTY_SITE'   AND hzps.party_site_id = aaa.entity_id AND aaa.resource_id = ");
		extraClause.append(resourceId);
		extraClause.append(" and fnd_profile.value('ASN_CUST_ACCESS')= 'T' ");
		extraClause.append(") )");

        }
        else
        {
          extraClause.append(" ) )");
        }
      }
    }
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);
    }
    return extraClause.toString();
  }

public static String getSelectedOrgId(OAPageContext oapagecontext, OAWebBean oawebbean)
   {
       Diagnostic.println("Entering  HzPuiWebuiUtil.getSelectedOrgId()");
       OAApplicationModuleImpl oaapplicationmoduleimpl = (OAApplicationModuleImpl)oapagecontext.getRootApplicationModule();
       OAApplicationModule oaapplicationmodule = (OAApplicationModule)oaapplicationmoduleimpl.findApplicationModule("ODHzPuiDQMSrchResultsAM");
       OAViewObject oaviewobject = null;
     //  if(oaapplicationmodule == null)
         //  oaviewobject = (OAViewObject)oaapplicationmoduleimpl.findViewObject("HzPuiOrgDupPreventionAM.HzPuiDQMSrchResultsAM.HzPuiDQMSrchResultsVO");
      // else
           oaviewobject = (OAViewObject)oaapplicationmodule.findViewObject("ODHzPuiDQMSrchResultsVO1");
       oaviewobject.reset();
       String s = null;
       if(oaviewobject != null && oaviewobject.isExecuted())
       {
           Diagnostic.println("Entering  getSelectedOrgId()");
           while(oaviewobject.hasNext())
           {
               Row row = oaviewobject.next();
               String s1 = (String)row.getAttribute("SelectFlag");
               if("Y".equals(s1))
               {
                   s = row.getAttribute("PartyId").toString();
                   break;
               }
           }
       }
       if(s == null)
           throw new OAException("AR", "HZ_RM_HIER_ACTION_REQ_BUT", null, (byte)0, null);
       else
           return s;
   }

   public static String getSelectedAddressId(OAPageContext oapagecontext, OAWebBean oawebbean)
   {
       Diagnostic.println("Entering  HzPuiWebuiUtil.getSelectedAddressId()");
       OAApplicationModuleImpl oaapplicationmoduleimpl = (OAApplicationModuleImpl)oapagecontext.getRootApplicationModule();
       OAApplicationModule oaapplicationmodule = (OAApplicationModule)oaapplicationmoduleimpl.findApplicationModule("ODHzPuiDQMSrchResultsAM");
       OAViewObject oaviewobject = null;
     //  if(oaapplicationmodule == null)
         //  oaviewobject = (OAViewObject)oaapplicationmoduleimpl.findViewObject("HzPuiOrgDupPreventionAM.HzPuiDQMSrchResultsAM.HzPuiDQMSrchResultsVO");
      // else
           oaviewobject = (OAViewObject)oaapplicationmodule.findViewObject("ODHzPuiDQMSrchResultsVO1");
       oaviewobject.reset();
       String s = null;
       if(oaviewobject != null && oaviewobject.isExecuted())
       {
           Diagnostic.println("Entering  getSelectedOrgId()");
           while(oaviewobject.hasNext())
           {
               Row row = oaviewobject.next();
               String s1 = (String)row.getAttribute("SelectFlag");
               if("Y".equals(s1))
               {
                  //Anirban added for fixing defect#187 in ASN Tracker: Start
                  if(row.getAttribute("PartySiteId") == null)
				   {
                    OAException e = new OAException("XXCRM", "XX_SFA_082_PARTY_WOUT_SITE");
				    throw (e);
				   }
				  //Anirban added for fixing defect#187 in ASN Tracker: End

                   s = row.getAttribute("PartySiteId").toString();
                   break;
               }
           }
       }
       if(s == null)
           throw new OAException("AR", "HZ_RM_HIER_ACTION_REQ_BUT", null, (byte)0, null);
       else
           return s;
   }

   public static String getSelectedAddress(OAPageContext oapagecontext, OAWebBean oawebbean)
   {
       Diagnostic.println("Entering  HzPuiWebuiUtil.getSelectedAddress()");
       OAApplicationModuleImpl oaapplicationmoduleimpl = (OAApplicationModuleImpl)oapagecontext.getRootApplicationModule();
       OAApplicationModule oaapplicationmodule = (OAApplicationModule)oaapplicationmoduleimpl.findApplicationModule("ODHzPuiDQMSrchResultsAM");
       OAViewObject oaviewobject = null;
     //  if(oaapplicationmodule == null)
         //  oaviewobject = (OAViewObject)oaapplicationmoduleimpl.findViewObject("HzPuiOrgDupPreventionAM.HzPuiDQMSrchResultsAM.HzPuiDQMSrchResultsVO");
      // else
           oaviewobject = (OAViewObject)oaapplicationmodule.findViewObject("ODHzPuiDQMSrchResultsVO1");
       oaviewobject.reset();
       String s = null;
       if(oaviewobject != null && oaviewobject.isExecuted())
       {
           Diagnostic.println("Entering  getSelectedOrgId()");
           while(oaviewobject.hasNext())
           {
               Row row = oaviewobject.next();
               String s1 = (String)row.getAttribute("SelectFlag");
               if("Y".equals(s1))
               {
                  //Anirban added for fixing defect#187 in ASN Tracker: Start
                  if(row.getAttribute("Address") == null)
				   {
                    OAException e = new OAException("XXCRM", "XX_SFA_082_PARTY_WOUT_SITE");
				    throw (e);
				   }
				   //Anirban added for fixing defect#187 in ASN Tracker: End

                   s = row.getAttribute("Address").toString();
                   break;
               }
           }
       }
       if(s == null)
           throw new OAException("AR", "HZ_RM_HIER_ACTION_REQ_BUT", null, (byte)0, null);
       else
           return s;
   }

   public static String getSelectedLocationId(OAPageContext oapagecontext, OAWebBean oawebbean)
   {
       Diagnostic.println("Entering  HzPuiWebuiUtil.getSelectedLocationId()");
       OAApplicationModuleImpl oaapplicationmoduleimpl = (OAApplicationModuleImpl)oapagecontext.getRootApplicationModule();
       OAApplicationModule oaapplicationmodule = (OAApplicationModule)oaapplicationmoduleimpl.findApplicationModule("ODHzPuiDQMSrchResultsAM");
       OAViewObject oaviewobject = null;
     //  if(oaapplicationmodule == null)
         //  oaviewobject = (OAViewObject)oaapplicationmoduleimpl.findViewObject("HzPuiOrgDupPreventionAM.HzPuiDQMSrchResultsAM.HzPuiDQMSrchResultsVO");
      // else
           oaviewobject = (OAViewObject)oaapplicationmodule.findViewObject("ODHzPuiDQMSrchResultsVO1");
       oaviewobject.reset();
       String s = null;
       if(oaviewobject != null && oaviewobject.isExecuted())
       {
           Diagnostic.println("Entering  getSelectedOrgId()");
           while(oaviewobject.hasNext())
           {
               Row row = oaviewobject.next();
               String s1 = (String)row.getAttribute("SelectFlag");
               if("Y".equals(s1))
               {
                  //Anirban added for fixing defect#187 in ASN Tracker: Start
                  if(row.getAttribute("LocationId") == null)
				   {
                    OAException e = new OAException("XXCRM", "XX_SFA_082_PARTY_WOUT_SITE");
				    throw (e);
				   }
				   //Anirban added for fixing defect#187 in ASN Tracker: End
                   s = row.getAttribute("LocationId").toString();
                   break;
               }
           }
       }
       if(s == null)
           throw new OAException("AR", "HZ_RM_HIER_ACTION_REQ_BUT", null, (byte)0, null);
       else
           return s;
   }

}
