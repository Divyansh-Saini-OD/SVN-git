/*===========================================================================+
 |      Copyright (c) 2001 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 |  Oct-21-2007    Sami Begg  Created                                        |
 |  Feb-20-2008    Anirban    Modified for security of contact search        |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.common.customer.webui;

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
import oracle.cabo.ui.beans.BaseWebBean;

public class ODAllCtctSearchCO extends ASNControllerObjectImpl
{

    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        String s = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODAllCtctSearchCO.processRequest";
        boolean flag = oapagecontext.isLoggingEnabled(2);
        boolean flag1 = oapagecontext.isLoggingEnabled(1);
        if(flag)
            oapagecontext.writeDiagnostics(s, "Begin", 2);
        super.processRequest(oapagecontext, oawebbean);
        String s1 = oapagecontext.getParameter("ASNReqPgAct");
        String s2 = (String)oapagecontext.getSessionValue("ASNSsnSrchParamCopied");
        String s3 = oapagecontext.getParameter("ASNCAQ");
        if(flag1)
        {
            oapagecontext.writeDiagnostics(s, "ASNReqPgAct: " + s1, 1);
            oapagecontext.writeDiagnostics(s, "ASNSsnSrchParamCopied: " + s2, 1);
            oapagecontext.writeDiagnostics(s, "ASNCAQ: " + s3, 1);
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
                oapagecontext.removeSessionValue(ASN_SSN_PARAM_PREFIX + "HzPuiRelatedOrg");
                oapagecontext.removeSessionValue("ASNSsnSrchParamCopied");
            }
        } else
        if("Y".equals(s2) && !"N".equals(s3))
        {
            String as1[] = oapagecontext.getSessionValueNames();
            for(int j = 0; j < as1.length; j++)
            {
                String s5 = as1[j];
                if(s5.startsWith(ASN_SSN_PARAM_PREFIX))
                {
                    String s7 = (String)oapagecontext.getSessionValue(s5);
                    oapagecontext.putParameter(s5.substring(ASN_SSN_PARAM_PREFIX_LEN), s7);
                }
            }

            oapagecontext.putParameter("HzPuiSearchAutoQuery", "Y");
        }
        OATableLayoutBean oatablelayoutbean = (OATableLayoutBean)oawebbean.findChildRecursive("ASNDqmCtctSearchResultsRN");
        if(oatablelayoutbean != null)
        {
            OASubmitButtonBean oasubmitbuttonbean = (OASubmitButtonBean)oatablelayoutbean.findChildRecursive("HzPuiCreate");
            if(oasubmitbuttonbean != null)
                oasubmitbuttonbean.setRendered(false);
            OASubmitButtonBean oasubmitbuttonbean1 = (OASubmitButtonBean)oatablelayoutbean.findChildRecursive("HzPuiMarkDup");
            if(oasubmitbuttonbean1 != null)
                oasubmitbuttonbean1.setRendered(false);
            if(oatablelayoutbean.findChildRecursive("Update") != null)
                oatablelayoutbean.findChildRecursive("Update").setRendered(false);
        }
        String s4 = oapagecontext.getProfile("HZ_DQM_PER_SIMPLE_MATCHRULE");
        String s6 = oapagecontext.getProfile("HZ_DQM_PER_ADV_MATCHRULE");
        oapagecontext.putParameter("HzPuiSearchType", "SIMPLEADV");
        oapagecontext.putParameter("HzPuiSearchPartyType", "PERSON");
        oapagecontext.putParameter("HzPuiSimpleMatchRuleId", s4);
        oapagecontext.putParameter("HzPuiAdvMatchRuleId", s6);
        oapagecontext.putParameter("HzPuiShowPersonLink", "N");
        oapagecontext.putParameter("HzPuiDQMPerSearchExtraWhereClause", getRestrictiveSql(oapagecontext, oawebbean));
        //Anirban added on 28-Mar-2008
        oapagecontext.putParameter("HzPuiDQMCustomVORestrictiveClause", getCustomVORestrictiveClause(oapagecontext, oawebbean));
        //Anirban added on 28-Mar-2008
        String s8 = oapagecontext.getParameter("HzPuiSearchMode");
        if(s8 == null)
            oapagecontext.putParameter("HzPuiSearchMode", "SIMPLE");
        if(flag)
            oapagecontext.writeDiagnostics(s, "End", 2);
    }

    public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        String s = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODAllCtctSearchCO.processFormRequest";
        boolean flag = oapagecontext.isLoggingEnabled(2);
        if(flag)
            oapagecontext.writeDiagnostics(s, "Begin", 2);
        super.processFormRequest(oapagecontext, oawebbean);
        String s1 = oapagecontext.getProfile("HZ_DQM_PER_SIMPLE_MATCHRULE");
        String s2 = oapagecontext.getProfile("HZ_DQM_PER_ADV_MATCHRULE");
        oapagecontext.putParameter("HzPuiSearchType", "SIMPLEADV");
        oapagecontext.putParameter("HzPuiSearchPartyType", "PERSON");
        oapagecontext.putParameter("HzPuiSimpleMatchRuleId", s1);
        oapagecontext.putParameter("HzPuiAdvMatchRuleId", s2);
        oapagecontext.putParameter("HzPuiDQMPerSearchExtraWhereClause", getRestrictiveSql(oapagecontext, oawebbean));
		//Anirban added on 28-Mar-2008
        oapagecontext.putParameter("HzPuiDQMCustomVORestrictiveClause", getCustomVORestrictiveClause(oapagecontext, oawebbean));
        //Anirban added on 28-Mar-2008
        HashMap hashmap = new HashMap();
        if(oapagecontext.getParameter("HzPuiToggleSearch") != null)
        {
            oapagecontext.putParameter("ASNCAQ", "N");
            String s3 = oapagecontext.getParameter("HzPuiSearchMode");
            oapagecontext.putParameter("HzPuiSearchMode", "ADV".equals(s3) ? "SIMPLE" : "ADV");
            hashmap.put("HzPuiSearchMode", "ADV".equals(s3) ? "SIMPLE" : "ADV");
            oapagecontext.forwardImmediatelyToCurrentPage(hashmap, true, "Y");
        } else
        if(oapagecontext.getParameter("HzPuiAddSearchField") != null)
            oapagecontext.putParameter("ASNCAQ", "N");
        else
        if("PARTYDETAIL".equals(oapagecontext.getParameter("HzPuiEvent")))
        {
            HashMap hashmap1 = new HashMap();
            String s4 = oapagecontext.getParameter("HzPuiPartyId");
            String s5 = oapagecontext.getParameter("HzPuiPersonPartyId");
            OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
            Serializable aserializable[] = {
                s4, s5
            };
            hashmap1 = (HashMap)oaapplicationmodule.invokeMethod("getValidatedRelDetails", aserializable);
            hashmap.put("ASNReqFrmCustId", hashmap1.get("ObjectId"));
            hashmap.put("ASNReqFrmCtctId", s5);
            hashmap.put("ASNReqFrmRelPtyId", s4);
            hashmap.put("ASNReqFrmRelId", hashmap1.get("RelationshipId"));
			hashmap.put("ASNReqFrmFuncName", "ASN_CTCTVIEWPG");
            oapagecontext.putParameter("ASNReqPgAct", "CTCTDET");
            //Anirban starts securing contact name link on the contact search page.
            //processTargetURL(oapagecontext, null, hashmap);
            boolean flag50 = false;
			oapagecontext.forwardImmediately("ASN_CTCTVIEWPG", OAWebBeanConstants.KEEP_MENU_CONTEXT, null, hashmap, flag50, "Y");
            //Anirban ends securing contact name link on the contact search page.
        } else
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
            oapagecontext.removeSessionValue(ASN_SSN_PARAM_PREFIX + "HzPuiRelatedOrg");
            boolean flag1 = false;
            for(Enumeration enumeration = oapagecontext.getParameterNames(); enumeration.hasMoreElements();)
            {
                String s6 = (String)enumeration.nextElement();
                if(s6.startsWith(ATTR_PARAM_PREFIX))
                {
                    String s7 = oapagecontext.getParameter(s6);
                    if(s7 != null && s7.trim().length() != 0)
                    {
                        oapagecontext.putSessionValue(ASN_SSN_PARAM_PREFIX + s6, s7);
                        flag1 = true;
                    }
                }
            }

            if(flag1)
            {
                oapagecontext.putSessionValue(ASN_SSN_PARAM_PREFIX + "HzPuiRelatedOrg", oapagecontext.getParameter("HzPuiRelatedOrg"));
                oapagecontext.putSessionValue("ASNSsnSrchParamCopied", "Y");
            }
            oapagecontext.putParameter("ASNCAQ", "N");
        }
        if(flag)
            oapagecontext.writeDiagnostics(s, "End", 2);
    }

    //Anirban added on 28-Mar-2008: starts
	private String getCustomVORestrictiveClause(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        String s = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODAllCtctSearchCO.getCustomVORestrictiveClause";
        boolean flag = oapagecontext.isLoggingEnabled(2);
        if(flag)
            oapagecontext.writeDiagnostics(s, "Begin", 2);
        
        String s1 = null;
        s1 = oapagecontext.getProfile("ASN_CUST_ACCESS");

        String customVORestrictiveClause = "";

        if(s1 == null || "".equals(s1.trim()))
        //Anirban starts securing the contact search.
            s1 = "S";
        "F".equals(s1);
        if("T".equals(s1))
        {
          customVORestrictiveClause = getSecurityRestrictiveSql(oapagecontext, oawebbean);
        }
		if("S".equals(s1))
        {
          customVORestrictiveClause = getCustomSecurityRestrictiveSql(oapagecontext, oawebbean);
        }
		//Anirban ends securing the contact search.
        if(flag)
            oapagecontext.writeDiagnostics(s, "End", 2);
        return customVORestrictiveClause;
    }
    //Anirban added on 28-Mar-2008: ends

    private String getRestrictiveSql(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        String s = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODAllCtctSearchCO.getRestrictiveSql";
        boolean flag = oapagecontext.isLoggingEnabled(2);
        if(flag)
            oapagecontext.writeDiagnostics(s, "Begin", 2);
        StringBuffer stringbuffer = new StringBuffer();
        stringbuffer.append("( ");
        stringbuffer.append("EXISTS (SELECT 1 ");
        stringbuffer.append("FROM Hz_relationships hzr, Hz_code_assignments code, hz_relationship_types reltype ");
        stringbuffer.append("WHERE hzr.subject_id = stage.party_id ");
        stringbuffer.append("AND   hzr.subject_type = 'PERSON' ");
        stringbuffer.append("AND   hzr.object_type = 'ORGANIZATION' ");
        stringbuffer.append("AND   hzr.status = 'A' ");
        stringbuffer.append("AND   hzr.subject_type = reltype.subject_type ");
        stringbuffer.append("AND   hzr.object_type = reltype.object_type ");
        stringbuffer.append("AND   TRUNC(hzr.start_date) <= TRUNC(SYSDATE) ");
        stringbuffer.append("AND   TRUNC(NVL(hzr.end_date, SYSDATE)) >= TRUNC(SYSDATE) ");
        stringbuffer.append("AND   reltype.relationship_type = hzr.relationship_type ");
        stringbuffer.append("AND   code.owner_table_name = 'HZ_RELATIONSHIP_TYPES' ");
        stringbuffer.append("AND   code.owner_table_id = reltype.relationship_type_id ");
        stringbuffer.append("AND   code.class_category = 'RELATIONSHIP_TYPE_GROUP' ");
        stringbuffer.append("AND   code.class_code = 'PARTY_REL_GRP_CONTACTS' ");
        stringbuffer.append("AND   code.content_source_type = 'USER_ENTERED' ");

        /*String s1 = null;
        s1 = oapagecontext.getProfile("ASN_CUST_ACCESS");
        if(s1 == null || "".equals(s1.trim()))
        //Anirban starts securing the contact search.
            s1 = "S";
        "F".equals(s1);
        if("T".equals(s1))
        {
            stringbuffer.append(" AND ");
            stringbuffer.append(getSecurityRestrictiveSql(oapagecontext, oawebbean));
        }
		if("S".equals(s1))
        {
            stringbuffer.append(" AND ");
            stringbuffer.append(getCustomSecurityRestrictiveSql(oapagecontext, oawebbean));
        }
		//Anirban ends securing the contact search.*/

        stringbuffer.append(") )");
        if(flag)
            oapagecontext.writeDiagnostics(s, "End", 2);
        return stringbuffer.toString();
    }

    public String getSecurityRestrictiveSql(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        String s = "asn.common.customer.webui.AllCtctSearchCO.getSecurityRestrictiveSql";
        boolean flag = oapagecontext.isLoggingEnabled(2);
        if(flag)
            oapagecontext.writeDiagnostics(s, "Begin", 2);
        StringBuffer stringbuffer = new StringBuffer();
        String s3 = getLoginResourceId(oapagecontext.getApplicationModule(oawebbean), oapagecontext);
        boolean flag1 = isLoginResourceManager(oapagecontext.getApplicationModule(oawebbean), oapagecontext);
        ArrayList arraylist = getManagerGroupIds(oapagecontext.getApplicationModule(oawebbean), oapagecontext);
        ArrayList arraylist1 = getAdminGroupIds(oapagecontext.getApplicationModule(oawebbean), oapagecontext);
        boolean flag2 = isStandaloneMember(oapagecontext.getApplicationModule(oawebbean), oapagecontext);
        String s1;
        if(flag1)
            s1 = "Y";
        else
            s1 = "N";
        String s2;
        if(flag2)
            s2 = "Y";
        else
            s2 = "N";
        if("N".equals(s1) || "Y".equals(s1) && (arraylist == null || arraylist != null && arraylist.size() <= 0) && (arraylist1 == null || arraylist1 != null && arraylist1.size() <= 0))
        {
            stringbuffer.append(" ( EXISTS ( SELECT secu.customer_id ");
            stringbuffer.append(" FROM    as_accesses_all secu");
            stringbuffer.append(" WHERE   secu.sales_lead_id IS NULL ");
            stringbuffer.append(" AND     secu.lead_id IS NULL ");
            stringbuffer.append(" AND      salesforce_id  = ");
            stringbuffer.append(s3);
            stringbuffer.append(" AND      salesforce_id+0  = ");
            stringbuffer.append(s3);
            stringbuffer.append(") )");
        }
        if("Y".equals(s1) && (arraylist != null && arraylist.size() > 0 || arraylist1 != null && arraylist1.size() > 0))
        {
            stringbuffer.append(" ( hzr.object_id in ( SELECT secu.customer_id ");
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
            if("Y".equals(s2))
            {
                stringbuffer.append(" UNION ALL ");
                stringbuffer.append(" SELECT secu.customer_id ");
                stringbuffer.append(" FROM    as_accesses_all secu");
                stringbuffer.append(" WHERE   secu.sales_lead_id IS NULL ");
                stringbuffer.append(" AND     secu.lead_id IS NULL ");
                stringbuffer.append(" AND      salesforce_id  = ");
                stringbuffer.append(s3);
                stringbuffer.append(" AND      salesforce_id+0  = ");
                stringbuffer.append(s3);
                stringbuffer.append(") )");
            } else
            {
                stringbuffer.append(" ) )");
            }
        }
        if(flag)
            oapagecontext.writeDiagnostics(s, "End", 2);
        return stringbuffer.toString();
    }

	public String getCustomSecurityRestrictiveSql(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        String s = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODAllCtctSearchCO.getSecurityRestrictiveSql";
        boolean flag = oapagecontext.isLoggingEnabled(2);
        if(flag)
            oapagecontext.writeDiagnostics(s, "Begin", 2);
        StringBuffer stringbuffer = new StringBuffer();
        String s3 = getLoginResourceId(oapagecontext.getApplicationModule(oawebbean), oapagecontext);
        boolean flag1 = isLoginResourceManager(oapagecontext.getApplicationModule(oawebbean), oapagecontext);
        ArrayList arraylist = getManagerGroupIds(oapagecontext.getApplicationModule(oawebbean), oapagecontext);
        ArrayList arraylist1 = getAdminGroupIds(oapagecontext.getApplicationModule(oawebbean), oapagecontext);
        boolean flag2 = isStandaloneMember(oapagecontext.getApplicationModule(oawebbean), oapagecontext);
        String s1;
        if(flag1)
            s1 = "Y";
        else
            s1 = "N";
        String s2;
        if(flag2)
            s2 = "Y";
        else
            s2 = "N";

		//SALES REP STARTS
        if("N".equals(s1) || "Y".equals(s1) && (arraylist == null || arraylist != null && arraylist.size() <= 0) && (arraylist1 == null || arraylist1 != null && arraylist1.size() <= 0))
        {
			    //stringbuffer.append(" ( hzr.object_id in ( SELECT hzps.party_id  ");
                stringbuffer.append(" ( subject_id in ( SELECT hzps.party_id  ");
                stringbuffer.append(" FROM XX_TM_NAM_TERR_CURR_ASSIGN_V aaa, HZ_PARTY_SITES hzps ");
                stringbuffer.append(" WHERE aaa.entity_type='PARTY_SITE'   AND hzps.party_site_id = aaa.entity_id   AND hzps.status = 'A'   and aaa.resource_id = ");
                stringbuffer.append(s3);
                stringbuffer.append(") )");
        }
		//SALES REP ENDS

        //MANAGER/ADMIN: STARTS
        if("Y".equals(s1) && (arraylist != null && arraylist.size() > 0 || arraylist1 != null && arraylist1.size() > 0))
        {

            //MANAGER/ADMIN AS A REP: STARTS

            //stringbuffer.append(" ( hzr.object_id in ( SELECT hzps.party_id  ");
            stringbuffer.append(" ( subject_id in ( SELECT hzps.party_id  ");
            stringbuffer.append(" FROM XX_TM_NAM_TERR_CURR_ASSIGN_V aaa, HZ_PARTY_SITES hzps ");
            stringbuffer.append(" WHERE aaa.entity_type='PARTY_SITE'   AND hzps.party_site_id = aaa.entity_id   AND hzps.status = 'A'   and aaa.resource_id = ");
            stringbuffer.append(s3);
            //stringbuffer.append(") ");

			//MANAGER/ADMIN AS A REP: ENDS



            stringbuffer.append(" UNION ");
            stringbuffer.append(" SELECT hzps.party_id  ");
            stringbuffer.append(" FROM JTF_RS_GROUP_USAGES jrgu,JTF_RS_GROUPS_DENORM b,XX_TM_NAM_TERR_CURR_ASSIGN_V aaa,HZ_PARTY_SITES hzps ");
            stringbuffer.append(" WHERE aaa.group_id = b.group_id   AND aaa.entity_type='PARTY_SITE'   AND hzps.party_site_id = aaa.entity_id ");
            stringbuffer.append(" AND jrgu.usage IN ('SALES', 'PRM')   AND jrgu.group_id = b.group_id   and b.start_date_active <= TRUNC(sysdate)   and NVL(b.end_date_Active, sysdate) >= TRUNC(sysdate)");
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
            stringbuffer.append(" ) ))");


            /*if("Y".equals(s2))
            {

                    stringbuffer.append(" UNION ALL ");
                    stringbuffer.append(" SELECT hzps.party_id  ");
                    stringbuffer.append(" FROM XX_TM_NAM_TERR_CURR_ASSIGN_V aaa, HZ_PARTY_SITES hzps ");
                    stringbuffer.append(" WHERE aaa.entity_type='PARTY_SITE'   AND hzps.party_site_id = aaa.entity_id   AND hzps.status = 'A'   and aaa.resource_id = ");
                    stringbuffer.append(s3);
                    stringbuffer.append(" and fnd_profile.value('ASN_CUST_ACCESS')= 'S' ");
                    stringbuffer.append(" UNION   ");
                    stringbuffer.append(" SELECT hzps.party_id   ");
                    stringbuffer.append(" FROM XX_TM_NAM_TERR_CURR_ASSIGN_V aaa,HZ_PARTY_SITES hzps  ");
                    stringbuffer.append(" WHERE aaa.entity_type='PARTY_SITE'   AND hzps.party_site_id = aaa.entity_id AND aaa.resource_id = ");
                    stringbuffer.append(s3);
                    stringbuffer.append(" and fnd_profile.value('ASN_CUST_ACCESS')= 'T' ");
                    stringbuffer.append(") )");

            } else
            {
                stringbuffer.append(" ) )");
            }*/
        }
		//MANAGER/ADMIN: ENDS
        if(flag)
            oapagecontext.writeDiagnostics(s, "End", 2);

	    oapagecontext.writeDiagnostics(s,  "getSecurityRestrictiveSql extra where clause: " + stringbuffer.toString() , OAFwkConstants.STATEMENT);                
        return stringbuffer.toString();
    }

    public ODAllCtctSearchCO()
    {
    }

    public static final String RCS_ID = "$Header: ODAllCtctSearchCO.java 115.7 2005/05/11 23:58:20 vpalaiya noship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: AllCtctSearchCO.java 115.7 2005/05/11 23:58:20 vpalaiya noship $", "oracle.apps.asn.common.customer.webui");
    private static String ASN_SSN_PARAM_PREFIX;
    private static int ASN_SSN_PARAM_PREFIX_LEN;
    private static String ATTR_PARAM_PREFIX;
    private static int ATTR_PARAM_PREFIX_LEN;

    static
    {
        ASN_SSN_PARAM_PREFIX = "ASNSsnCtctSrch";
        ASN_SSN_PARAM_PREFIX_LEN = ASN_SSN_PARAM_PREFIX.length();
        ATTR_PARAM_PREFIX = "MATCH_RULE_ATTR";
        ATTR_PARAM_PREFIX_LEN = ATTR_PARAM_PREFIX.length();
    }
}
