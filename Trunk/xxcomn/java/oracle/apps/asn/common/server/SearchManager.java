/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            			   Oracle NAC Consulting Organization         	     |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             SearchManager.java                                            |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    API will override base product in order to implement changes in SQL    |
 |     					                                                     |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    This class file is called from                                         |
 |oracle\apps\asn\lead\server\LeadSearchManager.constructFromWhereClause()   |
 |oracle\apps\asn\opportunity\server\OpptySearchManager.constructFromWhereClause()|
 |                                                                           |
 | all modifications take place in the getSecurityClause() method. in general|
 | all references to as_accesses_all have been replaced with refs to the     |
 | OD custom assignment tables.  relevant column names have been changed as  |
 | well.  common changes are:                                                |
 |                                                                           |
 |  as_accesses_all --> XX_TM_NAM_TERR_CURR_ASSIGN_V                         |
 |  salesforce_id --> resource_id                                            |
 |  lead_id --> entity_id AND entity_type ='OPPORTUNITY'                     |
 |  sales_lead_id --> entity_id AND entity_type='LEAD'                       |
 |  sales_group_id --> group_id                                              |
 |  removal of refs to open_flag, contributor_flag, object_creation_date     |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    24/10/2007   Sami Begg          Created                                |
 |    24-Jan-2008  Jasmine Sujithra   Changed Hint for performance           |
 |    12-Feb-2008  Jasmine Sujithra   Included Hint for Opportunity query    |
 |    09-May-2008  Anirban Chaudhuri  Fixed QC defect#6793                   |
 |    01-Jun-2009  Nabarun Ghosh      QC#15453, Included Enliu's comments    |
 |                                    on Lead Search Query with Mgr login.   |
 |    03-Aug-2009  Anirban Chaudhuri  Fixed QC defect#1636 in PRDGB          |
 |    04-Aug-2009  Anirban Chaudhuri  Fixed QC defect#1636 in PRDGB          |
 +===========================================================================*/
package oracle.apps.asn.common.server;

import com.sun.java.util.collections.*;
import java.sql.Types;
import java.util.StringTokenizer;
import oracle.apps.asn.common.schema.server.ASNUtil;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.OANLSServices;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAViewDef;
import oracle.jbo.AttributeDef;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.apps.asn.common.server.*;

public class SearchManager
{

    public SearchManager()
    {
        selectClause = new StringBuffer(300);
        whereClause = new StringBuffer(300);
        FromClause = new StringBuffer(200);
        filterClause = new StringBuffer(200);
        searchableColumns = new HashMap(20);
        bindVariables = new ArrayList(100);
        selectColumns = new ArrayList(20);
        filterColumns = new ArrayList(8);
        filterValues = new ArrayList(8);
        cDefSelectColumns = new ArrayList(20);
        mappedColumns = new HashMap(50);
    }

    protected void addSelectClause(String s)
    {
        if(selectClause.length() <= 0)
        {
            selectClause = selectClause.append(" SELECT ").append(s);
            return;
        } else
        {
            selectClause = selectClause.append(" , ").append(s);
            return;
        }
    }

    protected void setFromClause(String s)
    {
        fromClause = s;
    }

    protected void addWhereClause(String s)
    {
        if(whereClause.length() <= 0)
        {
            whereClause.append(" WHERE ").append(s);
            return;
        } else
        {
            whereClause.append("  AND ").append(s);
            return;
        }
    }

    protected void addWhereClause(String s, int i)
    {
        if(whereClause.length() <= 0)
        {
            whereClause.append(" WHERE ").append(s).append(i);
            return;
        } else
        {
            whereClause.append("  AND ").append(s).append(i);
            return;
        }
    }

    protected void addWhereClause(String s, int i, String s1)
    {
        if(whereClause.length() <= 0)
        {
            whereClause.append(" WHERE ").append(s).append(i).append(s1);
            return;
        } else
        {
            whereClause.append("  AND ").append(s).append(i).append(s1);
            return;
        }
    }

    protected void addSelectColumn(String s)
    {
        selectColumns.add(s);
    }

    protected void setSelectColumns()
    {
        cDefSelectColumns.clear();
        if(selectColumns != null && selectColumns.size() > 0)
        {
            int i = 1;
            for(Iterator iterator = selectColumns.iterator(); iterator.hasNext();)
            {
                String s = (String)iterator.next();
                ColumnDefinition columndefinition = (ColumnDefinition)mappedColumns.get(s);
                if(columndefinition != null)
                {
                    addSelectClause(columndefinition.dbColumnName);
                    columndefinition.index = i;
                    cDefSelectColumns.add(columndefinition);
                    i++;
                }
            }

        }
    }

    protected void addSearchParam(OADBTransaction oadbtransaction)
    {
        if(searchableColumns != null && searchableColumns.size() > 0)
        {
            Object obj;
            for(Iterator iterator = searchableColumns.keySet().iterator(); iterator.hasNext(); filterValues.add(obj))
            {
                String s = (String)iterator.next();
                String s1 = (String)searchableColumns.get(s);
                ColumnDefinition columndefinition = (ColumnDefinition)mappedColumns.get(s);
                obj = null;
                if(s1 != null && columndefinition != null)
                {
                    Object obj1 = null;
                    switch(columndefinition.dbDataType)
                    {
                    case 2: // '\002'
                        MessageToken amessagetoken[] = {
                            new MessageToken("IDNAME", s1)
                        };
                        obj1 = ASNUtil.stringToJboNumber(s1, "ASN_CMMN_STR_TO_JBONUM_ERR", amessagetoken);
                        break;

                    case 1: // '\001'
                        obj1 = s1;
                        break;

                    case 3: // '\003'
                        Date date = new Date(oadbtransaction.getOANLSServices().stringToDate(s1));
                        obj1 = date;
                        break;
                    }
                    obj = obj1;
                }
                filterColumns.add(s);
            }

        }
    }

    protected Object getMiscFilterValue(String s)
    {
        Object obj = null;
        int i = filterColumns.indexOf(s);
        if(i >= 0)
            obj = filterValues.get(i);
        return obj;
    }

    protected void setViewDef(OAViewDef oaviewdef)
    {
        if(cDefSelectColumns != null && cDefSelectColumns.size() > 0)
        {
            for(int i = 0; i < cDefSelectColumns.size(); i++)
            {
                ColumnDefinition columndefinition = (ColumnDefinition)cDefSelectColumns.get(i);
                if(columndefinition.AttrType == 1)
                    oaviewdef.addPersistentAttrDef(columndefinition.AttrName, columndefinition.entityUsageName, columndefinition.AttrName, true, (byte)0);
                else
                if(columndefinition.dbDataType == 1)
                    oaviewdef.addSqlDerivedAttrDef(columndefinition.AttrName, columndefinition.AttrName, "java.lang.String", 12, false, false, (byte)0, columndefinition.dbDataPrecision);
                else
                if(columndefinition.dbDataType == 2)
                    oaviewdef.addSqlDerivedAttrDef(columndefinition.AttrName, columndefinition.dbQueryColumn, "oracle.jbo.domain.Number", 2, false, false, (byte)0);
                else
                if(columndefinition.dbDataType == 3)
                    oaviewdef.addSqlDerivedAttrDef(columndefinition.AttrName, columndefinition.dbQueryColumn, "oracle.jbo.domain.Date", 91, false, false, (byte)0);
            }

        }
    }

    public String getSelectClause()
    {
        return selectClause.toString();
    }

    public String getWhereClause()
    {
        return whereClause.toString();
    }

    public String getFromClause()
    {
        return fromClause;
    }

    public static HashMap getSearchParams(String s)
    {
        HashMap hashmap = null;
        if(s != null && s.length() > 0)
        {
            s.substring(1, s.indexOf("}"));
            hashmap = new HashMap(15);
            String s1;
            for(StringTokenizer stringtokenizer = new StringTokenizer(s); stringtokenizer.hasMoreTokens(); hashmap.put(s1.substring(0, s1.indexOf("=")), s1.substring(s1.indexOf("=") + 1, s1.indexOf(","))))
                s1 = stringtokenizer.nextToken();

        }
        return hashmap;
    }

    public static ArrayList getDisplayColumns(String s)
    {
        ArrayList arraylist = null;
        if(s != null && s.length() > 0)
        {
            String s1 = s.substring(1, s.indexOf("]")) + ",";
            arraylist = new ArrayList(20);
            String s2;
            for(StringTokenizer stringtokenizer = new StringTokenizer(s1); stringtokenizer.hasMoreTokens(); arraylist.add(s2.substring(0, s2.indexOf(","))))
                s2 = stringtokenizer.nextToken();

        }
        return arraylist;
    }

    public HashMap getSecurityClause(HashMap hashmap)
    {
        boolean flag = false;
        boolean flag1 = false;
        boolean flag2 = false;
        boolean flag3 = false;
        boolean flag4 = false;
        Number number = null;
        Number number1 = null;
        Number number2 = null;
        Number number3 = null;
        Number number4 = null;
        Number number5 = null;
        Object obj = null;
        String s = null;
        String s1 = null;
        String s2 = null;
        String s3 = null;
        String s4 = null;
        ArrayList arraylist = new ArrayList(10);
        ArrayList arraylist1 = new ArrayList(10);
        ArrayList arraylist2 = new ArrayList(10);
        ArrayList arraylist3 = new ArrayList(10);
        ArrayList arraylist4 = new ArrayList(10);
        ArrayList arraylist5 = new ArrayList(10);
        String s5 = null;
        String s6 = null;
        String s7 = null;
        OADBTransaction oadbtransaction = (OADBTransaction)hashmap.get("trans");
        boolean flag5 = oadbtransaction.isLoggingEnabled(1);
        String s8 = "asn.opportunity.server.SearchManager.getSecurityClause";
        selectHint = null;
        HashMap hashmap1 = new HashMap(3);
        number = (Number)hashmap.get("ResourceId");
        if(((String)hashmap.get("AccessType")).equals("F"))
            flag = false;
        else
            flag = true;
        if((Number)hashmap.get("OwnerId") != null)
        {
            flag1 = true;
            number1 = (Number)hashmap.get("OwnerId");
            if(flag && number1.equals(number))
                flag = false;
        }
        if((Number)hashmap.get("SalesPersonId") != null)
        {
            flag2 = true;
            number2 = (Number)hashmap.get("SalesPersonId");
            if(number2.equals(number1))
                flag2 = false;
            if(flag && number2.equals(number))
                flag = false;
        }
        if((Number)hashmap.get("ContributorId") != null)
        {
            flag3 = true;
            new MessageToken("IDNAME", "ContributorId");
            number3 = (Number)hashmap.get("ContributorId");
            if(flag && number3.equals(number))
                flag = false;
            if(flag2 && number3.equals(number2))
                flag2 = false;
        }
        arraylist = (ArrayList)hashmap.get("ASNMgrGrpIds");
        arraylist1 = (ArrayList)hashmap.get("ASNAdminGrpIds");
        arraylist2 = (ArrayList)hashmap.get("ASNStdAlnMmbrGrpIds");
        if(((String)hashmap.get("ASNMgrFlag")).equals("Y") && (arraylist != null && arraylist.size() > 0 || arraylist1 != null && arraylist1.size() > 0))
            flag4 = true;
        if((Number)hashmap.get("GroupId") != null && number2 != null)
            flag2 = true;
        if((Number)hashmap.get("GroupId") != null && flag4 && arraylist2 != null && arraylist2.contains((Number)hashmap.get("GroupId")))
        {
            if(flag5)
            {
                StringBuffer stringbuffer = (new StringBuffer(50)).append(" == Security method== ").append(" Manager Search on STANDALONE Group,NO HIERARCHY ").append(number1);
                oadbtransaction.writeDiagnostics(s8, stringbuffer.toString(), 1);
            }
            flag4 = false;
        }
        if((Number)hashmap.get("GroupId") != null && ((String)hashmap.get("AccessType")).equals("T") && flag4)
            flag = false;
        number4 = (Number)hashmap.get("DashCustomer");
        number5 = (Number)hashmap.get("GroupId");
        s = (String)hashmap.get("StatusOpenFlag");
        s3 = (String)hashmap.get("Forecastable");
        s1 = (String)hashmap.get("ObjectType");
        s4 = (String)hashmap.get("DashSalescampaignSrch");
        s2 = (String)hashmap.get("ASNStdAlnMmbrFlag");
        arraylist3 = (ArrayList)hashmap.get("LeadCreationDateFrom");
        arraylist4 = (ArrayList)hashmap.get("LeadCreationDateTo");
        arraylist5 = (ArrayList)hashmap.get("LeadCreationDateEquals");
        s7 = (String)hashmap.get("DashLeadAgeDays");
        s6 = (String)hashmap.get("DashLeadToDays");
        s5 = (String)hashmap.get("DashLeadFromDays");
        if(s1.equals("LEAD"))
        {
            Number number6 = (Number)hashmap.get("bindSequence");
            bindSeq = number6.intValue();
        }
        if(flag5)
        {
            StringBuffer stringbuffer1 = (new StringBuffer(500)).append(" ==== OD Input Parameters to Security method====").append(" OwnerId = ").append(number1).append(" SalesPersonId = ").append(number2).append(" ResourceId = ").append(number).append(" GroupId = ").append(number5).append(" CustId = ").append(number4).append(" Dashboard Sales campaign Search  = ").append(s4).append(" StatusOpenFlag = ").append(s).append(" Forecastable = ").append(s3).append(" ObjectType = ").append(s1).append(" ASNStdAlnMmbrFlag = ").append(s2).append(" bManager = ").append(flag4).append(" bResource = ").append(flag).append(" bOwner = ").append(flag1).append(" bSalesPerson = ").append(flag2).append(" DashLeadAgeDays = ").append(s7).append(" DashLeadToDays = ").append(s6).append(" DashLeadFromDays = ").append(s5).append(" bContributor = ").append(flag3);
            oadbtransaction.writeDiagnostics(s8, stringbuffer1.toString(), 1);
        }
        int i = 0;
        if(flag && !flag4)
        {
            i++;
            if(s1.equals("OPPTY"))
                FromClause.append(sql_Resource_Oppty);
            else
                FromClause.append(sql_Resource_Lead);

/*ODR
 * Removing this block because XX_TM_NAM_TERR_CURR_ASSIGN_V does not have equivalent columns
 * for 'open_flag','customer_id','object_creation_date'
 *
            if(s != null)
                if(s.equals("Y"))
                    FromClause.append(" AND   aaa.open_flag = 'Y'  ");
               else
                    FromClause.append(" AND   NVL(aaa.open_flag,'N') = 'N'  ");
            if(number4 != null)
            {
                FromClause.append(" AND   aaa.customer_id = ");
                FromClause.append(":" + bindSeq++);
                bindVariables.add(number4);
            }
            if(arraylist3 != null || arraylist4 != null || arraylist5 != null)
                FromClause.append(getLeadCreateDateClause(arraylist3, arraylist4, arraylist5, "aaa").toString());
            Date date = new Date();
            Date date1 = (Date)Date.getCurrentDate();
            Date date2 = (Date)Date.getCurrentDate();
            Date date3 = (Date)Date.getCurrentDate();
            if(s7 != null)
            {
                Integer integer = new Integer(s7);
                date1 = (Date)date1.addJulianDays(-integer.intValue(), 0);
                FromClause.append(" AND  TRUNC(aaa.object_creation_date) >=  ");
                FromClause.append(":" + bindSeq++);
                bindVariables.add(date1);
            }
            if(s5 != null)
            {
                Integer integer1 = new Integer(s5);
                if(s6 != null)
                {
                    Integer integer3 = new Integer(s6);
                    date2 = (Date)date2.addJulianDays(-integer1.intValue(), 0);
                    date3 = (Date)date3.addJulianDays(-integer3.intValue(), 0);
                    FromClause.append(" AND TRUNC(aaa.object_creation_date)  <=  ");
                    FromClause.append(":" + bindSeq++);
                    bindVariables.add(date2);
                    FromClause.append(" AND TRUNC(aaa.object_creation_date)  >=  ");
                    FromClause.append(":" + bindSeq++);
                    bindVariables.add(date3);
                } else
                {
                    date2 = (Date)date2.addJulianDays(-integer1.intValue(), 0);
                    FromClause.append(" AND TRUNC(aaa.object_creation_date)  <=  ");
                    FromClause.append(":" + bindSeq++);
                    bindVariables.add(date2);
                }
            }
            if(s6 != null && s5 == null)
            {
                Integer integer2 = new Integer(s6);
                date3 = (Date)date3.addJulianDays(-integer2.intValue(), 0);
                FromClause.append(" AND TRUNC(aaa.object_creation_date)  >=  ");
                FromClause.append(":" + bindSeq++);
                bindVariables.add(date3);
            }
* */

//ODR            FromClause.append(" AND   aaa.salesforce_id  = ");
            FromClause.append(" AND   aaa.resource_id  = ");

            FromClause.append(":" + bindSeq++);
            FromClause.append(") secu ");
            bindVariables.add(number);

            if(s1.equals("OPPTY"))
                addWhereClause(" OpportunityEO.lead_id = secu.entity_id AND secu.entity_type ='OPPORTUNITY' ");
//ODR                addWhereClause(" OpportunityEO.lead_id = secu.lead_id ");
            else
                addWhereClause(" leadEO.sales_lead_id = secu.entity_id AND secu.entity_type='LEAD' ");
//ODR                addWhereClause(" leadEO.sales_lead_id = secu.sales_lead_id ");

        }
        if(flag2)
            if(i > 0)
            {
                if(s1.equals("OPPTY"))
                {
                    filterClause.append(" AND EXISTS ");

//ODR                    filterClause.append(" (SELECT slrp.Lead_Id from as_accesses_all slrp ");
                    filterClause.append(" (SELECT slrp.entity_Id from XX_TM_NAM_TERR_CURR_ASSIGN_V slrp ");

                    if(number5 != null && flag4)
                    {
                        filterClause.append(" ,jtf_rs_groups_denorm    jrgd ");
                        filterClause.append(" ,jtf_rs_group_usages    jrgu ");
                    }

//ODR                    filterClause.append("  where slrp.sales_lead_id IS  NULL ");
//                    filterClause.append(" AND    slrp.lead_id IS NOT NULL ");
                    filterClause.append(" where   slrp.entity_type='OPPORTUNITY' ");

//ODR                    filterClause.append(" AND    slrp.lead_id = opportunityEO.lead_id ");
                    filterClause.append(" AND    slrp.entity_id = opportunityEO.lead_id ");

                } else
                {
                    filterClause.append(" AND EXISTS ");

//ODR                    filterClause.append(" (SELECT slrp.sales_Lead_Id from as_accesses_all slrp ");
                    filterClause.append(" (SELECT slrp.entity_Id from XX_TM_NAM_TERR_CURR_ASSIGN_V slrp ");

                    if(number5 != null && flag4)
                    {
                        filterClause.append(" ,jtf_rs_groups_denorm    jrgd ");
                        filterClause.append(" ,jtf_rs_group_usages    jrgu ");
                    }

//ODR                    filterClause.append(" where slrp.sales_lead_id IS  NOT NULL ");
//                    filterClause.append(" AND    slrp.lead_id IS NULL ");
                    filterClause.append(" where   slrp.entity_type='LEAD' ");

//ODR                    filterClause.append(" AND    slrp.sales_lead_id = leadEO.sales_lead_id ");
                    filterClause.append(" AND    slrp.entity_id = leadEO.sales_lead_id ");

//ODR                    if(arraylist3 != null || arraylist4 != null || arraylist5 != null)
//                        filterClause.append(getLeadCreateDateClause(arraylist3, arraylist4, arraylist5, "slrp").toString());

                }

//ODR                filterClause.append(" AND    slrp.salesForce_id = ");
                filterClause.append(" AND    slrp.resource_id = ");

                filterClause.append(":" + bindSeq++);
                bindVariables.add(number2);

/* ODR                filterClause.append(" AND    slrp.salesForce_id + 0 = ");
                filterClause.append(":" + bindSeq++);
                bindVariables.add(number2);
                if(s != null)
                    if(s.equals("Y"))
                        filterClause.append(" AND   slrp.open_flag = 'Y'  ");
                    else
                        filterClause.append(" AND   NVL(slrp.open_flag,'N') = 'N'  ");
*/
                if(number5 != null)
                    if(flag4)
                    {
                        filterClause.append(sql_group);

//ODR                        filterClause.append(" AND jrgd.group_id = slrp.sales_group_id ");
                        filterClause.append(" AND jrgd.group_id = slrp.group_id ");

                        filterClause.append(" AND jrgd.parent_group_id = ");
                        filterClause.append(":" + bindSeq++);
                        bindVariables.add(number5);
                    } else
                    {

//ODR                        filterClause.append(" AND   slrp.sales_group_id= ");
                        filterClause.append(" AND   slrp.group_id= ");

                        filterClause.append(":" + bindSeq++);
                        bindVariables.add(number5);
                    }
                filterClause.append(" ) ");
                i++;
            } else
            {
                i++;
                if(s1.equals("OPPTY"))
                {
                    if(number5 != null && flag4)
                    {

//ODR                        FromClause.append(" ,( SELECT /*+ no_merge */ distinct aaa.lead_id ");
//Removed no_merge           FromClause.append(" ,( SELECT /*+ no_merge */ distinct aaa.entity_id , aaa.entity_type ");
                             FromClause.append(" ,( SELECT distinct aaa.entity_id , aaa.entity_type ");

                        FromClause.append(sql_group_secu);

//ODR                        FromClause.append(" AND  aaa.sales_lead_id IS NULL ");
//                        FromClause.append(" AND  aaa.lead_id IS NOT NULL ");
                        FromClause.append(" AND aaa.entity_type='OPPORTUNITY' ");

                    } else
                    {
                        FromClause.append(sql_Resource_Oppty);
                    }

//ODR                    addWhereClause(" OpportunityEO.lead_id = secu.lead_id ");
                    addWhereClause(" OpportunityEO.lead_id = secu.entity_id AND secu.entity_type='OPPORTUNITY' ");

                } else
                {
                    if(number5 != null && flag4)
                    {

//ODR                        FromClause.append(" ,( SELECT /*+ no_merge */ distinct aaa.sales_lead_id ");
                        FromClause.append(" ,( SELECT distinct aaa.entity_id , aaa.entity_type ");

                        FromClause.append(sql_group_secu);

//ODR                        FromClause.append(" AND  aaa.sales_lead_id IS NOT NULL ");
//                        FromClause.append(" AND  aaa.lead_id IS NULL ");
                        FromClause.append(" AND aaa.entity_type='LEAD' ");

                    } else
                    {
                        FromClause.append(sql_Resource_Lead);
                    }

//ODR                    addWhereClause(" leadEO.sales_lead_id = secu.sales_lead_id ");
                    addWhereClause(" leadEO.sales_lead_id = secu.entity_id AND secu.entity_type='LEAD' ");

                }

/*ODR                if(s != null)
                    if(s.equals("Y"))
                        FromClause.append(" AND   aaa.open_flag = 'Y'  ");
                    else
                        FromClause.append(" AND   NVL(aaa.open_flag,'N') = 'N'  ");
*/
//ODR                FromClause.append(" AND   aaa.salesforce_id  = ");
                FromClause.append(" AND   aaa.resource_id  = ");

                FromClause.append(":" + bindSeq++);
                bindVariables.add(number2);
                if(number5 != null)
                    if(flag4)
                    {
                        FromClause.append(" AND jrgd.parent_group_id = ");
                        FromClause.append(":" + bindSeq++);
                        bindVariables.add(number5);
                    } else
                    {

//ODR                        FromClause.append(" AND   aaa.sales_group_id= ");
                        FromClause.append(" AND   aaa.group_id= ");

                        FromClause.append(":" + bindSeq++);
                        bindVariables.add(number5);
                    }

//ODR                if(arraylist3 != null || arraylist4 != null || arraylist5 != null)
//                    FromClause.append(getLeadCreateDateClause(arraylist3, arraylist4, arraylist5, "aaa").toString());

                FromClause.append(") secu ");
            }
        if(flag3)
            if(i > 0)
            {
                filterClause.append(" AND OpportunityEO.lead_id in ");

/*ODR                filterClause.append(" (SELECT cntrb.Lead_Id from as_accesses_all cntrb ");
                filterClause.append("  where cntrb.sales_lead_id IS  NULL ");
                filterClause.append(" AND    cntrb.lead_id IS NOT NULL ");
                filterClause.append(" AND    cntrb.lead_id = opportunityEO.lead_id ");
                filterClause.append(" AND    cntrb.salesForce_id = ");
*/
                filterClause.append(" (SELECT cntrb.entity_Id from XX_TM_NAM_TERR_CURR_ASSIGN_V cntrb ");
                filterClause.append("  where cntrb.entity_type='OPPORTUNITY' ");
                filterClause.append(" AND    cntrb.entity_id = opportunityEO.lead_id ");
                filterClause.append(" AND    cntrb.resource_id = ");

                filterClause.append(":" + bindSeq++);
                bindVariables.add(number3);

/*ODR                filterClause.append(" AND    cntrb.salesForce_id + 0 = ");
                filterClause.append(":" + bindSeq++);
                bindVariables.add(number3);
                filterClause.append(" AND    cntrb.contributor_flag = 'Y' ");
                if(s != null)
                    if(s.equals("Y"))
                        filterClause.append(" AND   cntrb.open_flag = 'Y'  ");
                    else
                        filterClause.append(" AND   NVL(cntrb.open_flag,'N') = 'N'  ");
*/
                filterClause.append(" ) ");
                i++;
            } else
            {
                i++;
                if(s1.equals("OPPTY"))
                    FromClause.append(sql_Resource_Oppty);
                else
                    FromClause.append(sql_Resource_Lead);

/*ODR                if(s != null)
                    if(s.equals("Y"))
                        FromClause.append(" AND   aaa.open_flag = 'Y'  ");
                    else
                        FromClause.append(" AND   NVL(aaa.open_flag,'N') = 'N'  ");
*/
//ODR                FromClause.append(" AND   aaa.salesforce_id  = ");
                FromClause.append(" AND   aaa.resource_id  = ");

                FromClause.append(":" + bindSeq++);

//ODR                FromClause.append(" AND    aaa.contributor_flag = 'Y' ");

                FromClause.append(") secu ");
                bindVariables.add(number3);

//ODR                addWhereClause("OpportunityEO.lead_id = secu.lead_id ");
                addWhereClause("OpportunityEO.lead_id = secu.entity_id AND secu.entity_type='OPPORTUNITY' ");

            }
        if(number5 != null && !flag2)
            if(i > 0)
            {
                if(s1.equals("OPPTY"))
                {
                    filterClause.append(" AND EXISTS ");

//ODR                    filterClause.append(" (SELECT slgrp.Lead_Id from as_accesses_all slgrp ");
                    filterClause.append(" (SELECT slgrp.entity_Id from XX_TM_NAM_TERR_CURR_ASSIGN_V slgrp ");

                    if(flag4)
                    {
                        filterClause.append(" ,jtf_rs_groups_denorm    jrgd ");
                        filterClause.append(" ,jtf_rs_group_usages    jrgu ");
                    }

//ODR                    filterClause.append("  where slgrp.sales_lead_id IS  NULL ");
//                    filterClause.append(" AND    slgrp.lead_id IS NOT NULL ");
                    filterClause.append(" where   slgrp.entity_type='OPPORTUNITY' ");

//ODR                    filterClause.append(" AND    slgrp.lead_id = opportunityEO.lead_id ");
                    filterClause.append(" AND    slgrp.entity_id = opportunityEO.lead_id ");

                } else
                {

                    filterClause.append(" AND EXISTS ");

//ODR                    filterClause.append(" (SELECT slgrp.sales_Lead_Id from as_accesses_all slgrp ");
                    filterClause.append(" (SELECT slgrp.entity_Id from XX_TM_NAM_TERR_CURR_ASSIGN_V slgrp ");

                    if(flag4)
                    {
                        filterClause.append(" ,jtf_rs_groups_denorm    jrgd ");
                        filterClause.append(" ,jtf_rs_group_usages    jrgu ");
                    }

//ODR                    filterClause.append("  where slgrp.sales_lead_id IS NOT NULL ");
//                    filterClause.append(" AND    slgrp.lead_id IS NULL ");
                    filterClause.append(" where   slgrp.entity_type='LEAD' ");

//ODR                    filterClause.append(" AND    slgrp.sales_lead_id = leadEO.sales_lead_id ");
                    filterClause.append(" AND    slgrp.entity_id = leadEO.sales_lead_id ");

//ODR                    if(arraylist3 != null || arraylist4 != null || arraylist5 != null)
//                        filterClause.append(getLeadCreateDateClause(arraylist3, arraylist4, arraylist5, "slgrp").toString());

                }
                if(flag4)
                {
                    filterClause.append(" AND   jrgd.parent_group_id = ");
                    filterClause.append(":" + bindSeq++);
                    bindVariables.add(number5);
                } else
                {

//ODR                    filterClause.append(" AND  slgrp.sales_group_id = ");
                    filterClause.append(" AND  slgrp.group_id = ");

                    filterClause.append(":" + bindSeq++);
                    bindVariables.add(number5);
                }

/*ODR                if(s != null)
                    if(s.equals("Y"))
                        filterClause.append(" AND   slgrp.open_flag = 'Y'  ");
                    else
                        filterClause.append(" AND   NVL(slgrp.open_flag,'N') = 'N'  ");
*/
                filterClause.append(" ) ");
                i++;
            } else
            {
                i++;
                if(s1.equals("OPPTY"))
                {
                    if(flag4)
                    {

//ODR                  FromClause.append(" ,( SELECT /*+ no_merge */ distinct aaa.lead_id ");
//Removed no_merge     FromClause.append(" ,( SELECT /*+ no_merge */ distinct aaa.entity_id , aaa.entity_type ");
                       FromClause.append(" ,( SELECT distinct aaa.entity_id , aaa.entity_type ");

                        FromClause.append(sql_group_secu);

//ODR                        FromClause.append(" AND  aaa.sales_lead_id IS NULL ");
//                        FromClause.append(" AND  aaa.lead_id IS NOT NULL ");
                        FromClause.append(" AND aaa.entity_type='OPPORTUNITY' ");

                    } else
                    {
                        FromClause.append(sql_Resource_Oppty);
                    }
                } else
                {
                    if(flag4)
                    {

//ODR                        FromClause.append(" ,( SELECT /*+ no_merge */ distinct aaa.sales_lead_id ");
                        FromClause.append(" ,( SELECT distinct aaa.entity_id , aaa.entity_type ");

                        FromClause.append(sql_group_secu);

//ODR                        FromClause.append(" AND  aaa.sales_lead_id IS NOT NULL ");
//                        FromClause.append(" AND  aaa.lead_id IS NULL ");
                        FromClause.append(" AND aaa.entity_type='LEAD' ");

                    } else
                    {
                        FromClause.append(sql_Resource_Lead);
                    }
//ODR                    if(arraylist3 != null || arraylist4 != null || arraylist5 != null)
//                        FromClause.append(getLeadCreateDateClause(arraylist3, arraylist4, arraylist5, "aaa").toString());
                }

/*ODR                if(s != null)
                    if(s.equals("Y"))
                        FromClause.append(" AND   aaa.open_flag = 'Y'  ");
                    else
                        FromClause.append(" AND   NVL(aaa.open_flag,'N') = 'N'  ");
*/
                if(flag4)
                {
                    FromClause.append(" AND   jrgd.parent_group_id  = ");
                    FromClause.append(":" + bindSeq++);
                    bindVariables.add(number5);
                } else
                {

//ODR                    FromClause.append(" AND   aaa.sales_group_id  = ");
                    FromClause.append(" AND   aaa.group_id  = ");

                    FromClause.append(":" + bindSeq++);
                    bindVariables.add(number5);
                }
                FromClause.append(") secu ");
                if(s1.equals("OPPTY"))

//ODR                    addWhereClause(" OpportunityEO.lead_id = secu.lead_id ");
                    addWhereClause(" OpportunityEO.lead_id = secu.entity_id AND secu.entity_type='OPPORTUNITY' ");

                else

//ODR                    addWhereClause(" leadEO.sales_lead_id = secu.sales_lead_id ");
                    addWhereClause(" leadEO.sales_lead_id = secu.entity_id AND secu.entity_type='LEAD' ");

            }
        if(flag4 && flag)
        {
            if(s1.equals("OPPTY"))
                filterClause.append(sql_Mgr_Oppty);
            else
                filterClause.append(sql_Mgr_Lead);
            filterClause.append(" AND   jrgd.parent_group_id in ( ");
            if(arraylist != null && arraylist.size() > 0)
            {
                if(flag5)
                {
                    StringBuffer stringbuffer2 = (new StringBuffer(50)).append(" ==== ASNMgrGrpIds not null====");
                    oadbtransaction.writeDiagnostics(s8, stringbuffer2.toString(), 1);
                }
                for(int j = 0; j < arraylist.size(); j++)
                {
                    filterClause.append(":" + bindSeq++);
                    filterClause.append(",");
                    bindVariables.add(arraylist.get(j));
                }

            }
            if(arraylist1 != null && arraylist1.size() > 0)
            {
                if(flag5)
                {
                    StringBuffer stringbuffer3 = (new StringBuffer(50)).append(" ==== ASNAdminGrpIds not null====");
                    oadbtransaction.writeDiagnostics(s8, stringbuffer3.toString(), 1);
                }
                for(int k = 0; k < arraylist1.size(); k++)
                {
                    filterClause.append(":" + bindSeq++);
                    filterClause.append(",");
                    bindVariables.add(arraylist1.get(k));
                }

            }
            if(filterClause.toString().endsWith(","))
            {
                filterClause.setLength(filterClause.length() - 1);
                filterClause.append(") ");
            }
            filterClause.append(" AND   jrgu.usage  in ('SALES', 'PRM') ");

//ODR            filterClause.append(" AND   jrgd.group_id = secu.sales_group_id ");

            //04-Aug-2009  Anirban Chaudhuri  Fixed QC defect#1636 in PRDGB: starts
			if(s1.equals("OPPTY"))
            {
             filterClause.append(" AND   jrgd.group_id = secu.group_id ");
			}
			else
			{
             filterClause.append(" AND   jrgd.group_id = TERR_RSC.group_id ");
			}
            //04-Aug-2009  Anirban Chaudhuri  Fixed QC defect#1636 in PRDGB: ends
			

            if(s1.equals("OPPTY"))
            {

//ODR                filterClause.append(" AND   secu.sales_lead_id IS NULL ");
//                filterClause.append(" AND   secu.lead_id IS NOT NULL ");
                filterClause.append(" AND   secu.entity_type = 'OPPORTUNITY' ");

//ODR                filterClause.append(" AND   secu.lead_id = OpportunityEO.Lead_Id ");
                filterClause.append(" AND   secu.entity_id = OpportunityEO.Lead_Id ");

            } 


			//04-Aug-2009  Anirban Chaudhuri  Fixed QC defect#1636 in PRDGB: starts
			/*else
            {

//ODR                filterClause.append(" AND   secu.lead_id IS NULL ");
//                filterClause.append(" AND   secu.sales_lead_id IS NOT NULL ");
                filterClause.append(" AND   secu.entity_type = 'LEAD' ");

//ODR                filterClause.append(" AND   secu.sales_lead_id = LeadEO.Sales_lead_Id ");
                
				//03-Aug-2009  Anirban Chaudhuri  Fixed QC defect#1636 in PRDGB: starts
				//filterClause.append(" AND   secu.entity_id = LeadEO.Sales_lead_Id ");
				//03-Aug-2009  Anirban Chaudhuri  Fixed QC defect#1636 in PRDGB: ends

            }*/
            //04-Aug-2009  Anirban Chaudhuri  Fixed QC defect#1636 in PRDGB: ends



/*ODR            if(s != null && s.equals("Y"))
                filterClause.append(" AND   secu.open_flag = 'Y' ");
            else
            if(s != null && s.equals("N"))
                filterClause.append(" AND   NVL(secu.open_flag,'N') ='N'  ");
            if(arraylist3 != null || arraylist4 != null || arraylist5 != null)
                filterClause.append(getLeadCreateDateClause(arraylist3, arraylist4, arraylist5, "secu").toString());
*/
            if(s2 != null && s2.equals("Y"))
            {
                filterClause.append(" UNION ALL ");

/*ODR                filterClause.append(" SELECT aaa.lead_id ");
                filterClause.append(" FROM as_accesses_all aaa ");
                filterClause.append(" WHERE aaa.sales_lead_id is  null ");
                filterClause.append(" AND aaa.lead_id is NOT null ");
                filterClause.append(" AND aaa.salesforce_id = ");
*/
                filterClause.append(" (SELECT aaa.entity_Id from XX_TM_NAM_TERR_CURR_ASSIGN_V aaa ");
                //filterClause.append("  where aaa.entity_type='OPPORTUNITY' ");

                if(s1.equals("OPPTY"))
                    filterClause.append("  where aaa.entity_type='OPPORTUNITY' ");
                else
                    filterClause.append("  where aaa.entity_type='LEAD' ");

                filterClause.append(" AND    aaa.resource_id = ");

                filterClause.append(":" + bindSeq++);
                bindVariables.add(number);

/*ODR                filterClause.append(" AND   aaa.salesforce_id + 0 = ");
                filterClause.append(":" + bindSeq++);
                bindVariables.add(number);
                if(s != null && s.equals("Y"))
                    filterClause.append(" AND   aaa.open_flag = 'Y' ");
                else
                if(s != null && s.equals("N"))
                    filterClause.append(" AND  NVL(aaa.open_flag,'N') = 'N' ");
*/
                if(s1.equals("OPPTY"))
                    filterClause.append(" AND   aaa.entity_id = OpportunityEO.Lead_Id AND aaa.entity_type = 'OPPORTUNITY' ");
//ODR                    filterClause.append(" AND   aaa.lead_id = OpportunityEO.Lead_Id ");
                else
					//03-Aug-2009  Anirban Chaudhuri  Fixed QC defect#1636 in PRDGB: starts
                    //filterClause.append(" AND   aaa.entity_id = LeadEO.Sales_lead_Id AND aaa.entity_type = 'LEAD' ");
                    filterClause.append(" AND   aaa.entity_type = 'LEAD' ");
					//03-Aug-2009  Anirban Chaudhuri  Fixed QC defect#1636 in PRDGB: ends

				filterClause.append(" ) ");
//ODR                    filterClause.append(" AND   aaa.sales_lead_id = LeadEO.Sales_lead_Id ");

//ODR                if(arraylist3 != null || arraylist4 != null || arraylist5 != null)
//                    filterClause.append(getLeadCreateDateClause(arraylist3, arraylist4, arraylist5, "aaa").toString());

            }
            filterClause.append(" ) ");
            if(s1.equals("OPPTY"))
                //selectHint = " /*+ leading (OpportunityEO) */ ";
                selectHint = " /*+ index(OpportunityEO as_leads_n19) */ ";

            else
                 //selectHint = " /*+ leading (LeadEO) */ ";
                //Modified by Nabarun as on 01/06/09 based on Enliu's recomendation to improve performance, QC#:15453
                //selectHint = " /*+ Index(secu XX_TM_NAM_TERR_RSC_N1) USE_NL(hpobj,cont,hcp,hpscust,hps,LeadEO,ast,aslrt,hr,hcplt,ht,hlcust,hl,fttcust) */  ";
                selectHint = " /*+ USE_NL(hpobj,cont,hpscust,LeadEO,ast,aslrt,hr,hlcust,fttcust) */  ";
        }
        if(i <= 0)
        {
            if(!flag4)
            {
                if(flag5)
                {
                    StringBuffer stringbuffer4 = (new StringBuffer(50)).append(" ==== bcount ==0 -- No secu clause)====");
                    oadbtransaction.writeDiagnostics(s8, stringbuffer4.toString(), 1);
                }
                if(s1.equals("LEAD"))
                {
                    if(s != null)
                    {
                        filterClause.append(" AND leadEO.status_open_flag = ");
                        filterClause.append(":" + bindSeq++);
                        bindVariables.add(s);
                    }
                } else
                {
                    if(s != null)
                    {
                        FromClause.append(" , as_statuses_b asb ");
                        addWhereClause(" OpportunityEO.status = asb.status_code ");
                        filterClause.append(" and asb.opp_open_status_flag =  ");
                        filterClause.append(":" + bindSeq++);
                        bindVariables.add(s);
                    } else
                    if(s4 != null && number1 != null)
                    {
                        FromClause.append(" , as_statuses_b asb ");
                        addWhereClause(" OpportunityEO.status = asb.status_code ");
                    }
                    if(s3 != null)
                    {
                        filterClause.append(" AND  ");
                        filterClause.append(" asb.forecast_rollup_flag =  ");
                        filterClause.append(":" + bindSeq++);
                        bindVariables.add(s3);
                    }
                }
            }
        } else
        {
            if(s3 != null || s4 != null)
            {
                FromClause.append(" , as_statuses_b asb ");
                addWhereClause(" OpportunityEO.status = asb.status_code ");
            }
            if(s3 != null)
            {
                filterClause.append(" and asb.forecast_rollup_flag =  ");
                filterClause.append(":" + bindSeq++);
                bindVariables.add(s3);
            }
        }
        hashmap1.put("FromClause", FromClause);
        hashmap1.put("filterClause", filterClause);
        hashmap1.put("whereClause", whereClause);
        hashmap1.put("bindVars", bindVariables);
        return hashmap1;
    }

    private StringBuffer getLeadCreateDateClause(ArrayList arraylist, ArrayList arraylist1, ArrayList arraylist2, String s)
    {
        StringBuffer stringbuffer = new StringBuffer(100);
        if(arraylist != null)
        {
            for(Iterator iterator = arraylist.iterator(); iterator.hasNext(); bindVariables.add(iterator.next()))
            {
                stringbuffer.append(" and trunc(" + s + ".OBJECT_CREATION_DATE) > trunc(:" + bindSeq++);
                stringbuffer.append(")");
            }

        }
        if(arraylist1 != null)
        {
            for(Iterator iterator1 = arraylist1.iterator(); iterator1.hasNext(); bindVariables.add(iterator1.next()))
            {
                stringbuffer.append(" and trunc(" + s + ".OBJECT_CREATION_DATE) < trunc(:" + bindSeq++);
                stringbuffer.append(")");
            }

        }
        if(arraylist2 != null)
        {
            for(Iterator iterator2 = arraylist2.iterator(); iterator2.hasNext(); bindVariables.add(iterator2.next()))
            {
                stringbuffer.append(" and trunc(" + s + ".OBJECT_CREATION_DATE) = trunc(:" + bindSeq++);
                stringbuffer.append(")");
            }

        }
        return stringbuffer;
    }

    public static final String RCS_ID = "$Header: SearchManager.java 115.25.115200.3 2005/10/13 17:27:11 lgupta ship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: SearchManager.java 115.25.115200.3 2005/10/13 17:27:11 lgupta ship $", "oracle.apps.asn.common.server");
    protected StringBuffer selectClause;
    protected StringBuffer whereClause;
    protected String fromClause;
    protected StringBuffer FromClause;
    protected StringBuffer filterClause;
    protected HashMap searchableColumns;

//ODR    private static final String sql_Resource_Oppty = (new StringBuffer(300)).append(" ,( SELECT /*+ no_merge */ distinct aaa.lead_id  ").append("  FROM  as_accesses_all aaa ").append(" WHERE  aaa.sales_lead_id IS  NULL ").append(" AND    aaa.lead_id IS NOT NULL ").toString();
//Removed no_merge    private static final String sql_Resource_Oppty = (new StringBuffer(300)).append(",( SELECT /*+ no_merge */ distinct aaa.entity_id  , aaa.entity_type FROM  XX_TM_NAM_TERR_CURR_ASSIGN_V aaa WHERE  aaa.entity_type='OPPORTUNITY' ").toString();
    private static final String sql_Resource_Oppty = (new StringBuffer(300)).append(",( SELECT  distinct aaa.entity_id  , aaa.entity_type FROM  XX_TM_NAM_TERR_CURR_ASSIGN_V aaa WHERE  aaa.entity_type='OPPORTUNITY' ").toString();

//ODR    private static final String sql_Resource_Lead = (new StringBuffer(300)).append(" ,( SELECT /*+ no_merge */ distinct aaa.sales_lead_id ").append("  FROM  as_accesses_all aaa ").append(" WHERE  aaa.sales_lead_id IS  NOT NULL ").append(" AND    aaa.lead_id IS NULL ").toString();
    private static final String sql_Resource_Lead = (new StringBuffer(300)).append(",( SELECT  distinct aaa.entity_id , aaa.entity_type FROM  XX_TM_NAM_TERR_CURR_ASSIGN_V aaa WHERE  aaa.entity_type='LEAD' ").toString();

//ODR    private static final String sql_Mgr_Oppty = (new StringBuffer(300)).append(" AND exists ").append(" (SELECT  secu.lead_id ").append("  FROM  jtf_rs_groups_denorm  jrgd, ").append(" jtf_rs_group_usages  jrgu, ").append(" as_accesses_all secu  ").append("  WHERE  trunc(jrgd.start_date_active) <= TRUNC(SYSDATE) ").append(" AND  trunc(NVL(jrgd.end_date_active, SYSDATE)) >= TRUNC(SYSDATE) ").append(" AND     jrgu.group_id = jrgd.group_id ").toString();
    private static final String sql_Mgr_Oppty = (new StringBuffer(300)).append(" AND exists (SELECT secu.entity_id FROM jtf_rs_groups_denorm jrgd, jtf_rs_group_usages jrgu, XX_TM_NAM_TERR_CURR_ASSIGN_V secu WHERE secu.entity_type='OPPORTUNITY' AND trunc(jrgd.start_date_active) <= TRUNC(SYSDATE) AND trunc(NVL(jrgd.end_date_active, SYSDATE)) >= TRUNC(SYSDATE) AND jrgu.group_id = jrgd.group_id ").toString();

//ODR    private static final String sql_Mgr_Lead = (new StringBuffer(300)).append(" AND exists ").append(" (SELECT  secu.sales_lead_id ").append("  FROM  jtf_rs_groups_denorm  jrgd, ").append(" jtf_rs_group_usages  jrgu, ").append(" as_accesses_all secu  ").append("  WHERE  trunc(jrgd.start_date_active) <= TRUNC(SYSDATE) ").append(" AND  trunc(NVL(jrgd.end_date_active, SYSDATE)) >= TRUNC(SYSDATE) ").append(" AND     jrgu.group_id = jrgd.group_id ").toString();

    //03-Aug-2009 and 04-Aug-2009 Anirban Chaudhuri  Fixed QC defect#1636 in PRDGB: starts
    private static final String sql_Mgr_Lead = (new StringBuffer(300)).append(" AND LeadEO.Sales_lead_Id in (SELECT /*+ leading(jrgu, jrgd) INDEX(TERR_ENT XX_TM_NAM_TERR_ENTITY_DTLS_N2) */ TERR_ENT.entity_id FROM jtf_rs_groups_denorm jrgd, jtf_rs_group_usages jrgu, XX_TM_NAM_TERR_RSC_DTLS TERR_RSC, XX_TM_NAM_TERR_DEFN  TERR, XX_TM_NAM_TERR_ENTITY_DTLS  TERR_ENT WHERE TERR_ENT.entity_type='LEAD' AND trunc(jrgd.start_date_active) <= TRUNC(SYSDATE) AND trunc(NVL(jrgd.end_date_active, SYSDATE)) >= TRUNC(SYSDATE) AND jrgu.group_id = jrgd.group_id AND TERR.NAMED_ACCT_TERR_ID = TERR_RSC.NAMED_ACCT_TERR_ID AND TERR_ENT.NAMED_ACCT_TERR_ID = TERR.NAMED_ACCT_TERR_ID AND SYSDATE BETWEEN NVL(TERR.START_DATE_ACTIVE,SYSDATE-1) AND NVL(TERR.END_DATE_ACTIVE,SYSDATE+1) AND SYSDATE BETWEEN NVL(TERR_ENT.START_DATE_ACTIVE,SYSDATE-1) AND NVL(TERR_ENT.END_DATE_ACTIVE,SYSDATE+1) AND SYSDATE BETWEEN NVL(TERR_RSC.START_DATE_ACTIVE,SYSDATE-1) AND NVL(TERR_RSC.END_DATE_ACTIVE,SYSDATE+1) AND NVL(TERR.status,'A') = 'A' AND NVL(TERR_ENT.status,'A') = 'A' AND NVL(TERR_RSC.status,'A') = 'A' ").toString();
	//03-Aug-2009 and 04-Aug-2009 Anirban Chaudhuri  Fixed QC defect#1636 in PRDGB: ends

    private static final String sql_group = (new StringBuffer(100)).append(" AND     trunc(jrgd.start_date_active) <=     TRUNC(SYSDATE) ").append(" AND     trunc(NVL(jrgd.end_date_active, SYSDATE)) >= TRUNC(SYSDATE) ").append(" AND     jrgu.group_id = jrgd.group_id ").append(" AND     jrgu.usage  in ('SALES','PRM') ").toString();

//ODR    private static final String sql_group_secu = (new StringBuffer(200)).append("  FROM  as_accesses_all aaa, ").append(" jtf_rs_groups_denorm jrgd, jtf_rs_group_usages  jrgu ").append(" WHERE  trunc(jrgd.start_date_active) <= TRUNC(SYSDATE) ").append(" AND    trunc(NVL(jrgd.end_date_active, SYSDATE)) >= TRUNC(SYSDATE) ").append(" AND    jrgu.group_id = jrgd.group_id ").append(" AND    jrgu.usage  in ('SALES','PRM') ").append(" AND    jrgd.group_id = aaa.sales_group_id ").toString();
    private static final String sql_group_secu = (new StringBuffer(200)).append(" FROM XX_TM_NAM_TERR_CURR_ASSIGN_V aaa, jtf_rs_groups_denorm jrgd, jtf_rs_group_usages jrgu WHERE trunc(jrgd.start_date_active) <= TRUNC(SYSDATE) AND trunc(NVL(jrgd.end_date_active, SYSDATE)) >= TRUNC(SYSDATE) AND jrgu.group_id = jrgd.group_id AND jrgu.usage in ('SALES','PRM') AND jrgd.group_id = aaa.group_id ").toString();

    protected String selectHint;
    protected int bindSeq;
    private ArrayList bindVariables;
    protected ArrayList selectColumns;
    protected ArrayList filterColumns;
    protected ArrayList filterValues;
    protected ArrayList cDefSelectColumns;
    protected HashMap mappedColumns;
    protected static final String sql_phone = (new StringBuffer(100)).append("  DECODE(hcp.primary_phone_country_code,NULL,'', hcp.primary_phone_country_code || '-') ").append(" || DECODE(hcp.primary_phone_area_code,NULL,'', hcp.primary_phone_area_code|| '-') ").append(" || DECODE(hcp.primary_phone_number,NULL,'',hcp.primary_phone_number)  ").append(" || DECODE(hcp.primary_phone_extension,NULL,'','x' ||hcp.primary_phone_extension) ").append("  AS  FormattedPhone ").toString();
    protected static final String sql_SourceName = (new StringBuffer(500)).append(" DECODE(amsc.arc_source_code_for ,  ").append("  'CAMP', (SELECT campaign_name  ").append("           FROM AMS_CAMPAIGNS_ALL_TL ").append("           WHERE campaign_id = amsc.source_code_for_id ").append("           AND language = USERENV('LANG')), ").append("   'CSCH', (SELECT schedule_name ").append("            FROM   ams_campaign_schedules_tl ").append("            WHERE  schedule_id = amsc.source_code_for_id ").append("\t           AND language = USERENV('LANG')), ").append("   'EVEH', (SELECT event_header_name  ").append("\t           FROM AMS_EVENT_HEADERS_ALL_TL  ").append("            WHERE event_header_id = amsc.source_code_for_id ").append(" \t         AND language = USERENV('LANG')), ").append(" \t 'EONE', (SELECT event_offer_name  ").append(" \t          FROM AMS_EVENT_OFFERS_ALL_TL  ").append(" \t          WHERE event_offer_id = amsc.source_code_for_id ").append(" \t          AND language = USERENV('LANG')),  ").append(" \t 'EVEO', (SELECT event_offer_name  ").append(" \t          FROM AMS_EVENT_OFFERS_ALL_TL  ").append(" \t          WHERE event_offer_id = amsc.source_code_for_id ").append(" \t          AND language = USERENV('LANG')),  ").append(" \t 'OFFR', (SELECT  description ").append(" \t          FROM    qp_list_headers_tl ").append(" \t          WHERE  list_header_id = amsc.source_code_for_id ").append("            AND language = USERENV('LANG')),null) as SourceName ").toString();

}
