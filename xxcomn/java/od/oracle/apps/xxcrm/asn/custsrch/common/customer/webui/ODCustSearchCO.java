/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
/*===========================================================================+
 |      		       Office Depot - Project Simplify                       |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODCustSearchCO.java                                           |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |             Controller for the sales customer search page.                |                         
 |                                                                           |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    This class file is called from ODCustSearchPG.xml                      |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |  21/09/2007 Anirban Chaudhuri   Created                                   |
 |  22/10/2007 Sami Begg		   Modified SQL in getSecurityRestrictiveSql()|
 |  30/11/2007 Anirban Chaudhuri   Modified for defaulting search results    |
 |  30/11/2007 Sudeept Maharana    Modified getSecurityRestrictiveSql()      |
 |                                 for FULL ACCESS                           |
 |  18/01/2008 Anirban Chaudhuri   Modified getSecurityRestrictiveSql() api  |
 +===========================================================================*/

package od.oracle.apps.xxcrm.asn.custsrch.common.customer.webui;

import oracle.apps.asn.common.customer.webui.CustSearchCO;
import oracle.apps.fnd.framework.webui.beans.layout.OAStackLayoutBean; 
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;
import java.io.Serializable;
import java.util.Enumeration;
import oracle.apps.asn.common.fwk.webui.ASNControllerObjectImpl;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.layout.OATableLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;
import oracle.cabo.ui.beans.BaseWebBean;
import oracle.apps.fnd.framework.OAException;

/**
 * Controller for ...
 */
public class ODCustSearchCO extends ASNControllerObjectImpl  //CustSearchCO//OAControllerImpl 
{
    
  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
  {
        super.processRequest(oapagecontext, oawebbean);
	    oapagecontext.writeDiagnostics(this,  "ODCustSearchCO: ANIRBAN IN PR" , OAFwkConstants.STATEMENT);
	    String s = "od.oracle.apps.xxcrm.asn.custsrch.common.customer.webui.ODCustSearchCO.processRequest";
        boolean flag = oapagecontext.isLoggingEnabled(2);
        boolean flag1 = oapagecontext.isLoggingEnabled(1);
        if(flag)
            oapagecontext.writeDiagnostics(s, "Begin", 2);
        super.processRequest(oapagecontext, oawebbean);
        oapagecontext.removeParameter("HzPuiSearchComponentMode");
        boolean flag2 = false;
        String s1 = oapagecontext.getParameter("ASNReqPgAct");
        String s2 = (String)oapagecontext.getSessionValue("ASNSsnSrchParamCopied");
        String s3 = oapagecontext.getParameter("ASNCAQ");
        if(s3 == null || s3.trim().length() == 0)
            s3 = "Y";
        OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
        oaapplicationmodule.invokeMethod("init");
        if(flag1)
        {
            StringBuffer stringbuffer = new StringBuffer(200);
            stringbuffer.append("Parameters: ASNReqPgAct: ");
            stringbuffer.append(s1);
            stringbuffer.append(", ASNSSnSrchParamCopied: ");
            stringbuffer.append(s2);
            stringbuffer.append(", ASNCAQ: ");
            stringbuffer.append(s3);
            oapagecontext.writeDiagnostics(s, stringbuffer.toString(), 1);
        }
        if("FRMDSHBD".equals(s1))
        {
            if("Y".equals(s2))
            {
                String as[] = oapagecontext.getSessionValueNames();
                if(as != null)
                {
                    for(int i = 0; i < as.length; i++)
                        if(as[i] != null && as[i].startsWith(ASN_SSN_PARAM_PREFIX))
                            oapagecontext.removeSessionValue(as[i]);

                }
                oapagecontext.removeSessionValue("ASNSsnSrchParamCopied");
            }
        } else
        if("Y".equals(s2))
        {
            flag2 = true;
            if(!"N".equals(s3))
            {
                String as1[] = oapagecontext.getSessionValueNames();
                for(int j = 0; j < as1.length; j++)
                {
                    String s7 = as1[j];
                    if(s7.startsWith(ASN_SSN_PARAM_PREFIX))
                    {
                        String s10 = (String)oapagecontext.getSessionValue(s7);
                        oapagecontext.putParameter(s7.substring(ASN_SSN_PARAM_PREFIX_LEN), s10);
                    }
                }

                oapagecontext.putParameter("HzPuiSearchAutoQuery", "Y");
            }
        }

		OAStackLayoutBean oatablelayoutbean = (OAStackLayoutBean)oawebbean.findChildRecursive("ASNDQMWrapperRN");
        OATableLayoutBean oatablelayoutbean1 = (OATableLayoutBean)oawebbean.findChildRecursive("ASNSrchResultsRN");

		String defaultResourceId = "-999999";
        Serializable aserializabledefault2[] = {
                    defaultResourceId
                };
        oaapplicationmodule.invokeMethod("initQueryForDefault", aserializabledefault2);

        if(("FRMDSHBD".equals(s1)) || ("ASNSrchResultsTb".equals(oapagecontext.getParameter("custRegionCode"))))
        {			
            oapagecontext.writeDiagnostics(s, "Anirban28Nov: inside PR rendering the correct region: NONDQM", 2);
			Serializable aserializable[] = {
                "NONDQM"
            };
            oaapplicationmodule.invokeMethod("setSearchType", aserializable);
			boolean perzFlag = false;
            String s8 = null;
            s8 = oapagecontext.getProfile("ASN_CUST_ACCESS");
            boolean flag3 = isLoginResourceManager(oapagecontext.getApplicationModule(oawebbean), oapagecontext);
            if(!"F".equals(s8) && !flag3)
            {
                String s11 = getLoginResourceId(oapagecontext.getApplicationModule(oawebbean), oapagecontext);
                Serializable aserializable2[] = {
                    s11
                };
                oaapplicationmodule.invokeMethod("initQueryForDefault", aserializable2);
				perzFlag = true;
            }			
        }
		else
	    {
         Serializable aserializable[] = {
                "DQM"
            };
            oaapplicationmodule.invokeMethod("setSearchType", aserializable);
			oapagecontext.writeDiagnostics(s, "Anirban28Nov: inside PR rendering the correct region: DQM", 2);
	    }

		

        String s4 = oapagecontext.getProfile("HZ_DQM_ORG_SIMPLE_MATCHRULE");
        String s6 = oapagecontext.getProfile("HZ_DQM_ORG_ADV_MATCHRULE");
        oapagecontext.putParameter("HzPuiSearchType", "SIMPLEADV");
        oapagecontext.putParameter("HzPuiSearchPartyType", "ORGANIZATION");
        oapagecontext.putParameter("HzPuiSimpleMatchRuleId", s4);
        oapagecontext.putParameter("HzPuiAdvMatchRuleId", s6);
        oapagecontext.putParameter("HzPuiClassificationFilter", "Y");
        oapagecontext.putParameter("HzPuiRelationshipFilter", "Y");
        oapagecontext.putParameter("HzPuiDQMOrgSearchExtraWhereClause", getSecurityRestrictiveSql(oapagecontext, oawebbean));
//		oapagecontext.putParameter("HzPuiDQMOrgSearchExtraWhereClause", "");
        String s9 = oapagecontext.getParameter("HzPuiSearchMode");
        if(s9 == null)
            oapagecontext.putParameter("HzPuiSearchMode", "SIMPLE");
        if(flag)
            oapagecontext.writeDiagnostics(s, "End", 2);
  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
  {
        super.processFormRequest(oapagecontext, oawebbean);
	    oapagecontext.writeDiagnostics(this,  "ODCustSearchCO: ANIRBAN IN PFR" , OAFwkConstants.STATEMENT);
	    String s = "od.oracle.apps.xxcrm.asn.custsrch.common.customer.webui.ODCustSearchCO.processFormRequest";
        boolean flag = oapagecontext.isLoggingEnabled(2);
        if(flag)
            oapagecontext.writeDiagnostics(s, "Begin", 2);
        super.processFormRequest(oapagecontext, oawebbean);
        oapagecontext.putParameter("ASNReqFrmFuncName", "ASN_CUSTSEARCHPG");
        String s1 = oapagecontext.getProfile("HZ_DQM_ORG_SIMPLE_MATCHRULE");
        String s2 = oapagecontext.getProfile("HZ_DQM_ORG_ADV_MATCHRULE");
        oapagecontext.putParameter("HzPuiSearchType", "SIMPLEADV");
        oapagecontext.putParameter("HzPuiSearchPartyType", "ORGANIZATION");
        oapagecontext.putParameter("HzPuiSimpleMatchRuleId", s1);
        oapagecontext.putParameter("HzPuiAdvMatchRuleId", s2);
        oapagecontext.putParameter("HzPuiDQMOrgSearchExtraWhereClause", getSecurityRestrictiveSql(oapagecontext, oawebbean));
//		oapagecontext.putParameter("HzPuiDQMOrgSearchExtraWhereClause", "");
        HashMap hashmap = new HashMap();
        if(oapagecontext.getParameter("HzPuiToggleSearch") != null)
        {
			oapagecontext.writeDiagnostics(s, "Anirban27Nov: HzPuiToggleSearch pressed ", 2);
            oapagecontext.putParameter("ASNCAQ", "N");
            String s3 = oapagecontext.getParameter("HzPuiSearchMode");
            oapagecontext.putParameter("HzPuiSearchMode", "ADV".equals(s3) ? "SIMPLE" : "ADV");
            hashmap.put("HzPuiSearchMode", "ADV".equals(s3) ? "SIMPLE" : "ADV");
            oapagecontext.forwardImmediatelyToCurrentPage(hashmap, true, "Y");
        } else
        if(oapagecontext.getParameter("HzPuiAddSearchField") != null)
            oapagecontext.putParameter("ASNCAQ", "N");
        else
        if(oapagecontext.getParameter("HzPuiCreate") != null)
        {
            oapagecontext.putParameter("ASNReqPgAct", "SUBFLOW");
            hashmap.put("ASNReqFrmFuncName", "ASN_ORGCREATEPG");
            processTargetURL(oapagecontext, null, hashmap);
        } else
        //anirban starts
        if("PARTYDETAIL".equals(oapagecontext.getParameter("HzPuiEvent")))
        {
            hashmap.put("ASNReqFrmCustId", oapagecontext.getParameter("HzPuiPartyId"));
            hashmap.put("ASNReqFrmCustName", oapagecontext.getParameter("HzPuiPartyName"));
			hashmap.put("ASNReqFrmFuncName", "ASN_ORGVIEWPG");
            oapagecontext.putParameter("ASNReqPgAct", "CUSTDET");
			
			if("PERSON".equals(getCustomerType(oapagecontext, oapagecontext.getParameter("HzPuiPartyId"))))
                    throw new OAException("ASN", "ASN_CMMN_PTYPERSON_ACSS_ERR");

            //processTargetURL(oapagecontext, null, hashmap);
			boolean flag50 = false;
			//oapagecontext.forwardImmediately("ASN_ORGSECURVIEWPG", OAWebBeanConstants.KEEP_MENU_CONTEXT, null, hashmap, flag50, "Y");
			oapagecontext.forwardImmediately("ASN_ORGVIEWPG", OAWebBeanConstants.KEEP_MENU_CONTEXT, null, hashmap, flag50, "Y");
        } else
        if("ADDRDETAIL".equals(oapagecontext.getParameter("HzPuiAddrEvent")))
        {
            hashmap.put("ASNReqFrmCustId", oapagecontext.getParameter("HzPuiAddrPartyId"));
            hashmap.put("ASNReqFrmCustName", oapagecontext.getParameter("HzPuiAddrPartyName"));
			hashmap.put("ASNReqFrmSiteId", oapagecontext.getParameter("HzPuiAddrPartySiteId"));
			//hashmap.put("ASNReqFrmFuncName", "OD_ASN_SITE_UPDATE");
			hashmap.put("ASNReqFrmFuncName", "XX_ASN_SITEVIEWPG");
			
            boolean flag50 = false;
			//oapagecontext.forwardImmediately("OD_ASN_SITE_UPDATE", OAWebBeanConstants.KEEP_MENU_CONTEXT, null, hashmap, flag50, "Y");
			oapagecontext.forwardImmediately("XX_ASN_SITEVIEWPG", OAWebBeanConstants.KEEP_MENU_CONTEXT, null, hashmap, flag50, "Y");
        } else
		//anirban ends
        if(oapagecontext.getParameter("HzPuiGoSearch") != null)
        {
            oapagecontext.removeSessionValue("ASNSsnSrchParamCopied");
            String as[] = oapagecontext.getSessionValueNames();
            if(as != null)
            {
                for(int i = 0; i < as.length; i++)
                    if(as[i] != null && as[i].startsWith(ASN_SSN_PARAM_PREFIX))
                        oapagecontext.removeSessionValue(as[i]);

            }
            boolean flag1 = false;
            for(Enumeration enumeration = oapagecontext.getParameterNames(); enumeration.hasMoreElements();)
            {
                String s4 = (String)enumeration.nextElement();
                if(s4.startsWith(ATTR_PARAM_PREFIX))
                {
                    String s5 = oapagecontext.getParameter(s4);
                    if(s5 != null && s5.trim().length() != 0)
                    {
                        oapagecontext.putSessionValue(ASN_SSN_PARAM_PREFIX + s4, s5);
                        flag1 = true;
                    }
                }
            }

            if(flag1)
                oapagecontext.putSessionValue("ASNSsnSrchParamCopied", "Y");
            OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);

            /*OAStackLayoutBean oatablelayoutbean = (OAStackLayoutBean)oawebbean.findChildRecursive("ASNDQMWrapperRN");
            OATableLayoutBean oatablelayoutbean1 = (OATableLayoutBean)oawebbean.findChildRecursive("ASNSrchResultsRN");

			oatablelayoutbean1.setRendered(true);
            oatablelayoutbean.setRendered(true);*/

			Serializable aserializable[] = {
                "DQM"
            };
            oaapplicationmodule.invokeMethod("setSearchType", aserializable);

			oapagecontext.writeDiagnostics(s, "Anirban27Nov: go Button pressed and rendering the correct regions", 2);

            oapagecontext.putParameter("ASNCAQ", "N");
        }
        if(flag)
            oapagecontext.writeDiagnostics(s, "End", 2);
  }

  public String getSecurityRestrictiveSql(OAPageContext oapagecontext, OAWebBean oawebbean)
  {
	    oapagecontext.writeDiagnostics(this,  "ODCustSearchCO: getSecurityRestrictiveSql" , OAFwkConstants.STATEMENT);
        String s = "asn.common.customer.webui.CustSearchCO.getSecurityRestrictiveSql";
        boolean flag = oapagecontext.isLoggingEnabled(2);
        if(flag)
            oapagecontext.writeDiagnostics(s, "Begin", 2);
        StringBuffer stringbuffer = new StringBuffer();
        String s1 = null;
        s1 = oapagecontext.getProfile("ASN_CUST_ACCESS");
        if(s1 == null || "".equals(s1.trim()))
            s1 = "S";
        "F".equals(s1);



        //Anirban SEEDED: sales team 'T': STARTS

		if("T".equals(s1))
        {
            String s4 = getLoginResourceId(oapagecontext.getApplicationModule(oawebbean), oapagecontext);
            boolean flag1 = isLoginResourceManager(oapagecontext.getApplicationModule(oawebbean), oapagecontext);
            ArrayList arraylist = getManagerGroupIds(oapagecontext.getApplicationModule(oawebbean), oapagecontext);
            ArrayList arraylist1 = getAdminGroupIds(oapagecontext.getApplicationModule(oawebbean), oapagecontext);
            boolean flag2 = isStandaloneMember(oapagecontext.getApplicationModule(oawebbean), oapagecontext);
            String s2;
            if(flag1)
                s2 = "Y";
            else
                s2 = "N";
            String s3;
            if(flag2)
                s3 = "Y";
            else
                s3 = "N";
            if("N".equals(s2) || "Y".equals(s2) && (arraylist == null || arraylist != null && arraylist.size() <= 0) && (arraylist1 == null || arraylist1 != null && arraylist1.size() <= 0))
            {
                stringbuffer.append(" ( party_id in ( SELECT secu.customer_id ");
                stringbuffer.append(" FROM    as_accesses_all secu");
                stringbuffer.append(" WHERE   secu.sales_lead_id IS NULL ");
                stringbuffer.append(" AND     secu.lead_id IS NULL ");
                stringbuffer.append(" AND      salesforce_id  = ");
                stringbuffer.append(s4);
                stringbuffer.append(" AND      salesforce_id+0  = ");
                stringbuffer.append(s4);
                stringbuffer.append(") )");
            }
            if("Y".equals(s2) && (arraylist != null && arraylist.size() > 0 || arraylist1 != null && arraylist1.size() > 0))
            {
                stringbuffer.append(" ( party_id in ( SELECT secu.customer_id ");
                stringbuffer.append(" FROM    as_accesses_all secu ");
                stringbuffer.append(" WHERE   secu.sales_group_id in ( ");
                stringbuffer.append(" SELECT  jrgd.group_id ");
                stringbuffer.append(" FROM    jtf_rs_groups_denorm jrgd, ");
                stringbuffer.append(" jtf_rs_group_usages  jrgu ");
                stringbuffer.append(" WHERE   jrgd.parent_group_id  IN ( ");
                if(arraylist != null && arraylist.size() > 0)
                {
                    stringbuffer.append(arraylist.get(0));
                    for(int i = 1; i < arraylist.size(); i++)
                    {
                        stringbuffer.append(", ");
                        stringbuffer.append(arraylist.get(i));
                    }

                    if(arraylist1 != null)
                    {
                        for(int k = 0; k < arraylist1.size(); k++)
                        {
                            stringbuffer.append(", ");
                            stringbuffer.append(arraylist1.get(k));
                        }

                    }
                } else
                if(arraylist1 != null)
                {
                    stringbuffer.append(arraylist1.get(0));
                    for(int j = 1; j < arraylist1.size(); j++)
                    {
                        stringbuffer.append(", ");
                        stringbuffer.append(arraylist1.get(j));
                    }

                }
                stringbuffer.append(" ) ");
                stringbuffer.append(" AND     jrgd.start_date_active <= TRUNC(SYSDATE)");
                stringbuffer.append(" AND     NVL(jrgd.end_date_active, SYSDATE) >= TRUNC(SYSDATE) ");
                stringbuffer.append(" AND     jrgu.group_id = jrgd.group_id ");
                stringbuffer.append(" AND     jrgu.usage  in ('SALES', 'PRM')) ");
                stringbuffer.append(" AND   secu.lead_id IS NULL ");
                stringbuffer.append(" AND   secu.sales_lead_id IS NULL ");
                if("Y".equals(s3))
                {
                    stringbuffer.append(" UNION ALL ");
                    stringbuffer.append(" SELECT secu.customer_id ");
                    stringbuffer.append(" FROM    as_accesses_all secu");
                    stringbuffer.append(" WHERE   secu.sales_lead_id IS NULL ");
                    stringbuffer.append(" AND     secu.lead_id IS NULL ");
                    stringbuffer.append(" AND      salesforce_id  = ");
                    stringbuffer.append(s4);
                    stringbuffer.append(" AND      salesforce_id+0  = ");
                    stringbuffer.append(s4);
                    stringbuffer.append(") )");
                } else
                {
                    stringbuffer.append(" ) )");
                }
            }
        }

        //Anirban SEEDED: sales team 'T': ENDS	

        if("S".equals(s1))
        {
            String s4 = getLoginResourceId(oapagecontext.getApplicationModule(oawebbean), oapagecontext);
            boolean flag1 = isLoginResourceManager(oapagecontext.getApplicationModule(oawebbean), oapagecontext);
            ArrayList arraylist = getManagerGroupIds(oapagecontext.getApplicationModule(oawebbean), oapagecontext);
            ArrayList arraylist1 = getAdminGroupIds(oapagecontext.getApplicationModule(oawebbean), oapagecontext);
            boolean flag2 = isStandaloneMember(oapagecontext.getApplicationModule(oawebbean), oapagecontext);
            String s2;
            if(flag1)
                s2 = "Y";
            else
                s2 = "N";
            String s3;
            if(flag2)
                s3 = "Y";
            else
                s3 = "N";

			//SALES REP STARTS
            if("N".equals(s2) || "Y".equals(s2) && (arraylist == null || arraylist != null && arraylist.size() <= 0) && (arraylist1 == null || arraylist1 != null && arraylist1.size() <= 0))
            {

                stringbuffer.append(" ( party_site_id in ( SELECT hzps.party_site_id  ");
                stringbuffer.append(" FROM XX_TM_NAM_TERR_CURR_ASSIGN_V aaa, HZ_PARTY_SITES hzps ");
                stringbuffer.append(" WHERE aaa.entity_type='PARTY_SITE'   AND hzps.party_site_id = aaa.entity_id   AND nvl(hzps.identifying_address_flag,'N') = 'N' AND hzps.status = 'A'   and aaa.resource_id = ");
                stringbuffer.append(s4);
                stringbuffer.append(" UNION   ");
                stringbuffer.append(" SELECT hzps.party_site_id   ");
                stringbuffer.append(" FROM HZ_PARTY_SITES hzps  ");
                stringbuffer.append(" WHERE hzps.party_id IN ");
                stringbuffer.append("(SELECT party_id FROM XX_TM_NAM_TERR_CURR_ASSIGN_V aaa, HZ_PARTY_SITES hzps ");
				stringbuffer.append(" WHERE aaa.entity_type='PARTY_SITE'   AND hzps.party_site_id = aaa.entity_id   AND nvl(hzps.identifying_address_flag,'N') = 'Y' AND hzps.status = 'A'   and aaa.resource_id = ");
                stringbuffer.append(s4);
                stringbuffer.append(")))");
            }
            //SALES REP ENDS


            //MANAGER/ADMIN: STARTS        
            if("Y".equals(s2) && (arraylist != null && arraylist.size() > 0 || arraylist1 != null && arraylist1.size() > 0))
            {
                //MANAGER/ADMIN AS A REP: STARTS
                stringbuffer.append(" ( party_site_id in ( SELECT hzps.party_site_id  ");
                stringbuffer.append(" FROM XX_TM_NAM_TERR_CURR_ASSIGN_V aaa, HZ_PARTY_SITES hzps ");
                stringbuffer.append(" WHERE aaa.entity_type='PARTY_SITE'   AND hzps.party_site_id = aaa.entity_id   AND nvl(hzps.identifying_address_flag,'N') = 'N' AND hzps.status = 'A'   and aaa.resource_id = ");
                stringbuffer.append(s4);
                stringbuffer.append(" UNION   ");
                stringbuffer.append(" SELECT hzps.party_site_id   ");
                stringbuffer.append(" FROM HZ_PARTY_SITES hzps  ");
                stringbuffer.append(" WHERE hzps.party_id IN ");
                stringbuffer.append("(SELECT party_id FROM XX_TM_NAM_TERR_CURR_ASSIGN_V aaa, HZ_PARTY_SITES hzps ");
				stringbuffer.append(" WHERE aaa.entity_type='PARTY_SITE'   AND hzps.party_site_id = aaa.entity_id   AND nvl(hzps.identifying_address_flag,'N') = 'Y' AND hzps.status = 'A'   and aaa.resource_id = ");
                stringbuffer.append(s4);
                stringbuffer.append(")");
                //MANAGER/ADMIN AS A REP: ENDS


                stringbuffer.append(" UNION   ");
                stringbuffer.append(" SELECT hzps.party_site_id  ");
                stringbuffer.append(" FROM XX_TM_NAM_TERR_CURR_ASSIGN_V aaa, HZ_PARTY_SITES hzps ");
                stringbuffer.append(" WHERE aaa.entity_type='PARTY_SITE'   AND hzps.party_site_id = aaa.entity_id   AND nvl(hzps.identifying_address_flag,'N') = 'N' AND hzps.status = 'A'   and aaa.group_id IN ");
                stringbuffer.append(" ( SELECT b.group_id  ");
                stringbuffer.append(" FROM JTF_RS_GROUP_USAGES jrgu,JTF_RS_GROUPS_DENORM b");
                //stringbuffer.append(" WHERE aaa.group_id = b.group_id AND"); 
                stringbuffer.append(" WHERE ");                
                stringbuffer.append(" jrgu.usage IN ('SALES', 'PRM')   AND jrgu.group_id = b.group_id and"); stringbuffer.append(" b.start_date_active <= TRUNC(sysdate) and ");
				stringbuffer.append(" NVL(b.end_date_Active, sysdate) >= TRUNC(sysdate) "); 
                //stringbuffer.append(" and aaa.group_id = jrgu.group_id and b.parent_group_id  IN ( ");
				stringbuffer.append(" and b.parent_group_id  IN ( ");

               
                if(arraylist != null && arraylist.size() > 0)
                {
                    stringbuffer.append(arraylist.get(0));
                    for(int i = 1; i < arraylist.size(); i++)
                    {
                        stringbuffer.append(", ");
                        stringbuffer.append(arraylist.get(i));
                    }

                    if(arraylist1 != null)
                    {
                        for(int k = 0; k < arraylist1.size(); k++)
                        {
                            stringbuffer.append(", ");
                            stringbuffer.append(arraylist1.get(k));
                        }

                    }
                } else
                if(arraylist1 != null)
                {
                    stringbuffer.append(arraylist1.get(0));
                    for(int j = 1; j < arraylist1.size(); j++)
                    {
                        stringbuffer.append(", ");
                        stringbuffer.append(arraylist1.get(j));
                    }

                }
                stringbuffer.append(" )) ");


                stringbuffer.append(" UNION   ");
                stringbuffer.append(" SELECT hzps.party_site_id   ");
                stringbuffer.append(" FROM HZ_PARTY_SITES hzps  ");
                stringbuffer.append(" WHERE hzps.party_id IN ");
                stringbuffer.append("(SELECT party_id FROM XX_TM_NAM_TERR_CURR_ASSIGN_V aaa, HZ_PARTY_SITES hzps ");
				stringbuffer.append(" WHERE aaa.entity_type='PARTY_SITE'   AND hzps.party_site_id = aaa.entity_id   AND nvl(hzps.identifying_address_flag,'N') = 'Y' AND hzps.status = 'A'   and aaa.group_id IN ");
                stringbuffer.append(" ( SELECT b.group_id  ");
                stringbuffer.append(" FROM JTF_RS_GROUP_USAGES jrgu,JTF_RS_GROUPS_DENORM b");
				//stringbuffer.append(" WHERE aaa.group_id = b.group_id AND"); 
                stringbuffer.append(" WHERE ");               
                stringbuffer.append(" jrgu.usage IN ('SALES', 'PRM')   AND jrgu.group_id = b.group_id");   stringbuffer.append(" and b.start_date_active <= TRUNC(sysdate)   and ");
				stringbuffer.append(" NVL(b.end_date_Active, sysdate) >= TRUNC(sysdate) ");  
                //stringbuffer.append(" and aaa.group_id = jrgu.group_id and b.parent_group_id  IN ( ");
				stringbuffer.append(" and b.parent_group_id  IN ( ");

               
                if(arraylist != null && arraylist.size() > 0)
                {
                    stringbuffer.append(arraylist.get(0));
                    for(int i = 1; i < arraylist.size(); i++)
                    {
                        stringbuffer.append(", ");
                        stringbuffer.append(arraylist.get(i));
                    }

                    if(arraylist1 != null)
                    {
                        for(int k = 0; k < arraylist1.size(); k++)
                        {
                            stringbuffer.append(", ");
                            stringbuffer.append(arraylist1.get(k));
                        }

                    }
                } else
                if(arraylist1 != null)
                {
                    stringbuffer.append(arraylist1.get(0));
                    for(int j = 1; j < arraylist1.size(); j++)
                    {
                        stringbuffer.append(", ");
                        stringbuffer.append(arraylist1.get(j));
                    }

                }
                stringbuffer.append(" ))))) ");

               
               
               


               /* if("Y".equals(s3))
                {
                    stringbuffer.append(" UNION ALL ");
                    stringbuffer.append(" SELECT hzps.party_site_id  ");
                    stringbuffer.append(" FROM XX_TM_NAM_TERR_CURR_ASSIGN_V aaa, HZ_PARTY_SITES hzps ");
                    stringbuffer.append(" WHERE aaa.entity_type='PARTY_SITE'   AND hzps.party_site_id = aaa.entity_id   AND hzps.status = 'A'   and aaa.resource_id = ");
                    stringbuffer.append(s4);
                    stringbuffer.append(" and fnd_profile.value('ASN_CUST_ACCESS')= 'S' ");
                    stringbuffer.append(" UNION   ");
                    stringbuffer.append(" SELECT hzps.party_site_id   ");
                    stringbuffer.append(" FROM XX_TM_NAM_TERR_CURR_ASSIGN_V aaa,HZ_PARTY_SITES hzps  ");
                    stringbuffer.append(" WHERE aaa.entity_type='PARTY_SITE'   AND hzps.party_site_id = aaa.entity_id AND aaa.resource_id = ");
                    stringbuffer.append(s4);
                    stringbuffer.append(" and fnd_profile.value('ASN_CUST_ACCESS')= 'T' ");
                    stringbuffer.append(") )");

                } else
                {
                    stringbuffer.append(" ) )");
                }*/
            }
			//MANAGER/ADMIN ENDS
        }
        if(flag)
            oapagecontext.writeDiagnostics(s, "End", 2);

	    oapagecontext.writeDiagnostics(s,  "getSecurityRestrictiveSql extra where clause: " + stringbuffer.toString() , OAFwkConstants.STATEMENT);                
        return stringbuffer.toString();
  }

  public ODCustSearchCO()
  {
  }

    public static final String RCS_ID = "$Header: ODCustSearchCO.java 115.24.115200.2 2005/10/18 23:30:21 sprabhu ship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: ODCustSearchCO.java 115.24.115200.2 2005/10/18 23:30:21 achaudhu ship $", "od.oracle.apps.xxcrm.asn.custsrch.common.customer.webui");
    private static String ASN_SSN_PARAM_PREFIX;
    private static int ASN_SSN_PARAM_PREFIX_LEN;
    private static String ATTR_PARAM_PREFIX;
    private static int ATTR_PARAM_PREFIX_LEN;

    static 
    {
        ASN_SSN_PARAM_PREFIX = "ASNSsnCustSrch";
        ASN_SSN_PARAM_PREFIX_LEN = ASN_SSN_PARAM_PREFIX.length();
        ATTR_PARAM_PREFIX = "MATCH_RULE_ATTR";
        ATTR_PARAM_PREFIX_LEN = ATTR_PARAM_PREFIX.length();
    }

}
