/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            			   Oracle NAC Consulting Organization         			     |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             OpptySearchManager.java                               |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    API will override base product in order to implement changes in SQL    |
 |     					                                                             |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    This class file is called from                                         |
 |        oracle\apps\asn\opportunity\server\OpptyUwqViewRowImpl             |
 |        oracle\apps\asn\opportunity\server\OpptySearchVORowImpl            |
 |        oracle\apps\asn\opportunity\server\ASNOpptyQryAMImpl               |
 |                                                                           |
 | all modifications take place in the constructFromWhereClause() method.    |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    24/10/2007  Sami Begg           Created                                |
 |    29-Jan-2008 Jasmine Sujithra   Updated query for performance           |
 |    12-Feb-2008 Jasmine Sujithra   Get Max Row count from Profile          |
 |    20-Oct-2008 Mohan Kalyanasundaram Defect# 12029 Opportunity search     |
 |     based on status category and status bringing incorrect results.       |
 |    05-Apr-2010 Indra Varada Fix for Defect#4992                           |
 +===========================================================================*/
package oracle.apps.asn.opportunity.server;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;
import java.io.Serializable;
import java.util.Dictionary;
import java.util.StringTokenizer;
import oracle.apps.asn.common.fwk.server.ASNViewObjectImpl;
import oracle.apps.asn.common.fwk.server.ASNViewRowImpl;
import oracle.apps.asn.common.schema.server.ASNUtil;
import oracle.apps.asn.common.server.SearchCriteria;
import oracle.apps.asn.common.server.SearchManager;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.*;
import oracle.apps.fnd.framework.server.*;
import oracle.jbo.ApplicationModule;
import oracle.jbo.common.NamedObjectImpl;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jbo.server.*;

// Referenced classes of package oracle.apps.asn.opportunity.server:
//            OpportunityCurrPeriodRangeVOImpl

public class OpptySearchManager extends SearchManager
{

    public OpptySearchManager()
    {
        Refresh = false;
        whereClause = new StringBuffer(500);
        renderedVwAttrs = new ArrayList(50);
        searchCriteria = new HashMap(15);
        sortColumns = new ArrayList(10);
        sortSequence = new ArrayList(10);
        bindVariables = new ArrayList(50);
        ASNMgrGrpIds = new ArrayList(15);
        ASNAdminGrpIds = new ArrayList(15);
        ASNStdAlnMmbrGrpIds = new ArrayList(15);
    }

    public void setViewQuery(OAApplicationModule oaapplicationmodule, Dictionary adictionary[], ArrayList arraylist, HashMap hashmap, HashMap hashmap1, boolean flag)
    {
        OADBTransaction oadbtransaction = oaapplicationmodule.getOADBTransaction();
        OAViewObjectImpl oaviewobjectimpl = (OAViewObjectImpl)oaapplicationmodule.findViewObject("OpptySearchVO1");

        /* Modified to get the Maximum number of rows to be displayed from a profile */
        String maxOpptyRows = (String)oadbtransaction.getProfile("XX_ASN_MAX_OPPTY_ROWS");
        if(maxOpptyRows == null || "".equals(maxOpptyRows))
        {
            maxOpptyRows = "200";
        }
    
        renderedVwAttrs = arraylist;
        setSortSettings(oaviewobjectimpl, flag);
        setSearchCriteria(adictionary, oadbtransaction);
        ASNMgrFlag = (String)hashmap1.get("ASNManagerFlag");
        adddefSelectColumns();
        constructSelectClause(oaviewobjectimpl);
        String s = "asn.opportunity.server.OpptySearchManager.setViewQuery";
        boolean flag1 = oadbtransaction.isLoggingEnabled(1);
        constructFromWhereClause(oaapplicationmodule, hashmap, hashmap1);
        if(flag1)
        {
            StringBuffer stringbuffer = (new StringBuffer(500)).append(" ==== Input Parameters ====").append("Display Param = ").append(renderedVwAttrs).append("SelectClause = ").append(selectClause).append("From Clause = ").append(fromClause).append("Where Clause = ").append(FinalwhereClause).append("Order By Clause = ").append(orderByClause).append("Bind variables = ").append(bindVariables);
            oadbtransaction.writeDiagnostics(s, stringbuffer.toString(), 1);
        }
        StringBuffer stringbuffer1 = new StringBuffer(200);
        if(super.selectHint != null)
        {
            stringbuffer1.append(" SELECT " + super.selectHint);
            stringbuffer1.append(" ");
            stringbuffer1.append(selectClause);
        } else
        {
            /* Added Select Hint */
            stringbuffer1.append("SELECT "+ "/*+ index(OpportunityEO as_leads_n19) */");
            stringbuffer1.append(" ");
            stringbuffer1.append(selectClause);
        }
        stringbuffer1.append(" ");
        stringbuffer1.append(fromClause);
        stringbuffer1.append(" ");
        stringbuffer1.append(FinalwhereClause);       
        stringbuffer1.append(" AND ROWNUM <= ");
        stringbuffer1.append(maxOpptyRows);
        stringbuffer1.append(" AND 1=1 ");
       // stringbuffer1.append(" ");
        //stringbuffer1.append(orderByClause);
        Serializable aserializable[] = {
            stringbuffer1.toString()
        };
        oadbtransaction.writeDiagnostics(s, "Final SQL is : " + stringbuffer1.toString(), 1);
        oaviewobjectimpl.invokeMethod("setQuery", aserializable);
        oaviewobjectimpl.setWhereClauseParams(null);
        if(bindVariables != null && bindVariables.size() > 0)
        {
            for(int i = 0; i < bindVariables.size(); i++)
                oaviewobjectimpl.setWhereClauseParam(i, bindVariables.get(i));

        }
    }

    public void setSortSettings(OAViewObjectImpl oaviewobjectimpl, boolean flag)
    {
        Object obj = null;
        StringBuffer stringbuffer = new StringBuffer(50);
        Object obj1 = null;
        Object obj2 = null;
        Object obj3 = null;
        Object obj4 = null;
        Object obj5 = null;
        if(!flag)
        {
            String s = oaviewobjectimpl.getOrderByClause();
            if(s != null)
            {
                String s3;
                for(StringTokenizer stringtokenizer1 = new StringTokenizer(s, ","); stringtokenizer1.hasMoreTokens(); sortSequence.add(s3))
                {
                    String s1 = stringtokenizer1.nextToken();
                    StringTokenizer stringtokenizer = new StringTokenizer(s1, " ");
                    String s2 = stringtokenizer.nextToken();
                    if(stringtokenizer.hasMoreTokens())
                        s3 = stringtokenizer.nextToken();
                    else
                        s3 = "";
                    String s4 = getViewAttributeName(oaviewobjectimpl, s2);
                    sortColumns.add(s4);
                }

            }
            if(s == null)
            {
                sortColumns.add("OpportunityEO.last_update_date");
                sortSequence.add("DESC");
                for(int i = 0; i < sortColumns.size(); i++)
                    if(stringbuffer.length() <= 0)
                    {
                        stringbuffer.append(" Order by " + sortColumns.get(i));
                        stringbuffer.append(" " + sortSequence.get(i));
                    } else
                    {
                        stringbuffer.append(" , " + sortColumns.get(i));
                        stringbuffer.append(" " + sortSequence.get(i));
                    }

            }
        } else
        {
            sortColumns.add("OpportunityEO.last_update_date");
            sortSequence.add("DESC");
            for(int j = 0; j < sortColumns.size(); j++)
                if(stringbuffer.length() <= 0)
                {
                    stringbuffer.append(" Order by " + sortColumns.get(j));
                    stringbuffer.append(" " + sortSequence.get(j));
                } else
                {
                    stringbuffer.append(" , " + sortColumns.get(j));
                    stringbuffer.append(" " + sortSequence.get(j));
                }

        }
        if(stringbuffer != null)
            orderByClause = stringbuffer.toString();
    }

    private String getViewAttributeName(OAViewObjectImpl oaviewobjectimpl, String s)
    {
        ViewDefImpl viewdefimpl = oaviewobjectimpl.getViewDefinition();
        Object obj = null;
        oracle.jbo.AttributeDef aattributedef[] = viewdefimpl.getAttributeDefs();
        viewdefimpl.getAttributeCount();
        if(aattributedef != null)
        {
            Object obj1 = null;
            int i = aattributedef.length;
            for(int j = 0; j < i; j++)
            {
                ViewAttributeDefImpl viewattributedefimpl = (ViewAttributeDefImpl)aattributedef[j];
                if(s.equals(viewattributedefimpl.getColumnNameForQuery()))
                {
                    String s1 = viewattributedefimpl.getName();
                    return s1;
                }
            }

        }
        return null;
    }

    public void constructSelectClause(OAViewObjectImpl oaviewobjectimpl)
    {
        StringBuffer stringbuffer = new StringBuffer(50);
        if(renderedVwAttrs == null)
            renderedVwAttrs = new ArrayList(6);
        renderedVwAttrs.add("leadId");
        renderedVwAttrs.add("CustomerId");
        renderedVwAttrs.add("CurrencyCode");
        for(int i = 0; i < sortColumns.size(); i++)
            renderedVwAttrs.add(sortColumns.get(i));

        ViewDefImpl viewdefimpl = oaviewobjectimpl.getViewDefinition();
        Object obj = null;
        oracle.jbo.AttributeDef aattributedef[] = viewdefimpl.getAttributeDefs();
        viewdefimpl.getAttributeCount();
        if(aattributedef != null)
        {
            Object obj1 = null;
            int j = aattributedef.length;
            for(int k = 0; k < j; k++)
            {
                ViewAttributeDefImpl viewattributedefimpl = (ViewAttributeDefImpl)aattributedef[k];
                String s = viewattributedefimpl.getName();
                if(!"SelectFlag".equals(s))
                    if("Description".equals(s))
                        stringbuffer.append("SUBSTRB(OpportunityEO.description, 1,240) as Description,  ");
                    else
                    if("LeadId".equals(s))
                        stringbuffer.append("OpportunityEO.lead_id ,  ");
                    else
                    if("CustomerId".equals(s))
                        stringbuffer.append("OpportunityEO.customer_id,  ");
                    else
                    if("OwnerSalesforceId".equals(s))
                        stringbuffer.append("OpportunityEO.OWNER_SALESFORCE_ID,  ");
                    else
                    if("LeadNumber".equals(s))
                        stringbuffer.append("OpportunityEO.lead_number, ");
                    else
                    if("CurrencyCode".equals(s))
                        stringbuffer.append("OpportunityEO.Currency_Code, ");
                    else
                    if("SourcePromotionId".equals(s))
                        stringbuffer.append("OpportunityEO.Source_Promotion_Id , ");
                    else
                    if("CreationDate".equals(s))
                        stringbuffer.append("OpportunityEO.creation_date , ");
                    else
                    if("LastUpdateDate".equals(s))
                        stringbuffer.append("OpportunityEO.last_update_date , ");
                    else
                    if("TotalAmount".equals(s))
                        stringbuffer.append("OpportunityEO.TOTAL_AMOUNT, ");
                    else
                    if("TotalForecastAmount".equals(s))
                        stringbuffer.append("OpportunityEO.TOTAL_REVENUE_OPP_FORECAST_AMT , ");
                    else
                    if("ReferralCode".equals(s))
                        stringbuffer.append("OpportunityEO.PRM_Referral_Code as ReferralCode");
                    else
                    if("DecisionDate".equals(s))
                        stringbuffer.append("OpportunityEO.Decision_Date, ");
                    else
                    if("WinProbability".equals(s))
                        stringbuffer.append("OpportunityEO.win_probability , ");
                    else
                    if("OpptyStatusName".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("ast.meaning as OpptyStatusName, ");
                        else
                            stringbuffer.append("null as OpptyStatusName,  ");
                    } else
                    if("SalesStageName".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("asst.name as SalesStageName, ");
                        else
                            stringbuffer.append("null as SalesStageName,  ");
                    } else
                    if("MethodologyNm".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("asmt.sales_methodology_name as MethodologyNm, ");
                        else
                            stringbuffer.append("null as MethodologyNm,  ");
                    } else
                    if("AssignmentStatusNm".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("pvlkp.meaning as AssignmentStatusNm, ");
                        else
                            stringbuffer.append("null as AssignmentStatusNm,  ");
                    } else
                    if("CurrencyName".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("fnt.name as CurrencyName, ");
                        else
                            stringbuffer.append("null as CurrencyName,  ");
                    } else
                    if("PartyName".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("hp.party_name as PartyName, ");
                        else
                            stringbuffer.append("null as PartyName,  ");
                    } else
                    if("ResourceName".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("jrt.resource_name as ResourceName, ");
                        else
                            stringbuffer.append("null as ResourceName,  ");
                    } else
                    if("CustomerCategory".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("flv.meaning as CustomerCategory, ");
                        else
                            stringbuffer.append("null as CustomerCategory,  ");
                    } else
                    if("PersonId".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append(" cont.party_id as PersonId, ");
                        else
                            stringbuffer.append("null as PersonId,  ");
                    } else
                    if("RelationShipId".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("hr.relationship_id as RelationShipId, ");
                        else
                            stringbuffer.append("null as RelationShipId,  ");
                    } else
                    if("ContactName".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("cont.party_name as ContactName, ");
                        else
                            stringbuffer.append("null as ContactName,  ");
                    } else
                    if("PersonFirstName".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("cont.person_first_name as PersonFirstName, ");
                        else
                            stringbuffer.append("null as PersonFirstName,  ");
                    } else
                    if("PersonLastName".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("cont.person_last_name as PersonLastName, ");
                        else
                            stringbuffer.append("null as PersonLastName,  ");
                    } else
                    if("PersonMiddleName".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("cont.person_middle_name as PersonMiddleName, ");
                        else
                            stringbuffer.append("null as PersonMiddleName,  ");
                    } else
                    if("Salutation".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("cont.Salutation as Salutation, ");
                        else
                            stringbuffer.append("null as Salutation,  ");
                    } else
                    if("JobTitle".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("hoc.job_title as JobTitle, ");
                        else
                            stringbuffer.append("null as JobTitle,  ");
                    } else
                    if("FormattedPhone".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append(SearchManager.sql_phone + " ,");
                        else
                            stringbuffer.append("null as FormattedPhone,  ");
                    } else
                    if("State".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("hcp.state as State , ");
                        else
                            stringbuffer.append("null as State,  ");
                    } else
                    if("City".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("hcp.City as City, ");
                        else
                            stringbuffer.append("null as City,  ");
                    } else
                    if("Country".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("ftt.territory_short_name as Country, ");
                        else
                            stringbuffer.append("null as Country,  ");
                    } else
                    if("Province".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("hcp.Province as Province, ");
                        else
                            stringbuffer.append("null as Province,  ");
                    } else
                    if("PostalCode".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("hcp.Postal_Code as PostalCode, ");
                        else
                            stringbuffer.append("null as PostalCode,  ");
                    } else
                    if("Address".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("hz_format_pub.format_address( hl.location_id, null, null, ', ', null, null, null, null)  as Address, ");
                        else
                            stringbuffer.append("null as Address,  ");
                    } else
                    if("CustState".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("hlcust.state as CustState , ");
                        else
                            stringbuffer.append("null as CustState,  ");
                    } else
                    if("CustCity".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("hlcust.City as CustCity, ");
                        else
                            stringbuffer.append("null as CustCity,  ");
                    } else
                    if("CustCountry".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("fttcust.territory_short_name as CustCountry, ");
                        else
                            stringbuffer.append("null as CustCountry,  ");
                    } else
                    if("CustProvince".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("hlcust.Province as CustProvince, ");
                        else
                            stringbuffer.append("null as CustProvince,  ");
                    } else
                    if("CustPostalCode".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("hlcust.Postal_Code as CustPostalCode, ");
                        else
                            stringbuffer.append("null as CustPostalCode,  ");
                    } else
                    if("CustAddress".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("hz_format_pub.format_address( hlcust.location_id, null, null, ', ', null, null, null, null) as CustAddress, ");
                        else
                            stringbuffer.append("null as CustAddress,  ");
                    } else
                    if("OpptyCreatedBy".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("fucr.user_name as OpptyCreatedBy, ");
                        else
                            stringbuffer.append("null as OpptyCreatedBy,  ");
                    } else
                    if("OpptyUpdatedBy".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("fuup.user_name as OpptyUpdatedBy, ");
                        else
                            stringbuffer.append("null as OpptyUpdatedBy,  ");
                    } else
                    if("CloseReason".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("rsn.meaning as CloseReason, ");
                        else
                            stringbuffer.append("null as CloseReason,  ");
                    } else
                    if("SourceName".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append(SearchManager.sql_SourceName + " ,");
                        else
                            stringbuffer.append("null as SourceName,  ");
                    } else
                    if("PostalCode".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("hl.Postal_Code as PostalCode, ");
                        else
                            stringbuffer.append("null as PostalCode,  ");
                    } else
                    if("EmailAddress".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("hcp.email_address as EmailAddress, ");
                        else
                            stringbuffer.append("null as EmailAddress,  ");
                    } else
                    if("RelationshipId".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("hr.relationship_id, ");
                        else
                            stringbuffer.append("null,  ");
                    } else
                    if("SalesChannel".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append(" chnl.meaning as SalesChannel, ");
                        else
                            stringbuffer.append("null as SalesChannel, ");
                    } else
                    if("VehicleResponseCode".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("rspchnl.meaning as VehicleResponseCode, ");
                        else
                            stringbuffer.append("null as VehicleResponseCode,  ");
                    } else
                    if("RelationshipId".equals(s))
                    {
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("hr.Relationship_Id as RelationshipId, ");
                        else
                            stringbuffer.append("null as RelationshipId,  ");
                    } else
                    if("PrimaryContactPartyId".equals(s))
                        if(renderedVwAttrs.contains(s))
                            stringbuffer.append("hr.party_id as PrimaryContactPartyId, ");
                        else
                            stringbuffer.append("null as PrimaryContactPartyId,  ");
            }

        }
        selectClause = stringbuffer.toString();
        selectClause = selectClause.trim();
        if(selectClause.endsWith(","))
            selectClause = selectClause.substring(0, selectClause.length() - 1);
    }

    public void setSearchCriteria(Dictionary adictionary[], OADBTransaction oadbtransaction)
    {
        String s = "asn.opportunity.server.OpptySearchManager.setSearchCriteria";
        boolean flag = oadbtransaction.isLoggingEnabled(1);
        if(adictionary != null)
        {
            Object obj = null;
            for(int i = 0; i < adictionary.length; i++)
            {
                Dictionary dictionary = adictionary[i];
                SearchCriteria searchcriteria = new SearchCriteria();
                ArrayList arraylist = null;
                String s1 = (String)dictionary.get("criteriaItemName");
                searchcriteria.setName(s1);
                searchcriteria.setViewAttributeName((String)dictionary.get("criteriaViewAttributeName"));
                searchcriteria.setConditionOperator((String)dictionary.get("criteriaCondition"));
                searchcriteria.setJoinCondition((String)dictionary.get("criteriaJoinCondition"));
                searchcriteria.setValue(dictionary.get("criteriaValue"));
                if(flag)
                {
                    StringBuffer stringbuffer = new StringBuffer(50);
                    stringbuffer.append("  Search Criteria : ");
                    stringbuffer.append(" Criteria Name  : ");
                    stringbuffer.append(s1);
                    stringbuffer.append(" Criteria Value  : ");
                    stringbuffer.append(dictionary.get("criteriaValue"));
                    oadbtransaction.writeDiagnostics(s, stringbuffer.toString(), 1);
                }
                if(searchCriteria.containsKey(s1))
                    arraylist = (ArrayList)searchCriteria.get(s1);
                if(arraylist == null)
                    arraylist = new ArrayList(10);
                arraylist.add(searchcriteria);
                searchCriteria.put(s1, arraylist);
            }

        }
    }

    public void constructFromWhereClause(OAApplicationModule oaapplicationmodule, HashMap hashmap, HashMap hashmap1)
    {
        StringBuffer stringbuffer = new StringBuffer(500);
        StringBuffer stringbuffer1 = new StringBuffer(800);
        Object obj = null;
        fromClause = stringbuffer1.toString();
        filterClause = stringbuffer.toString();
        MessageToken amessagetoken[] = {
            new MessageToken("IDNAME", "ASNLoginResourceId")
        };
        Number number = null;
        String s1 = null;
        if(hashmap1 != null)
        {
            number = ASNUtil.stringToJboNumber((String)hashmap1.get("ASNLoginResourceId"), "ASN_CMMN_STR_TO_JBONUM_ERR", amessagetoken);
            s1 = (String)hashmap1.get("ASNStdAlnMmbrFlag");
            ASNMgrGrpIds = (ArrayList)hashmap1.get("ASNMgrGrpIds");
            ASNAdminGrpIds = (ArrayList)hashmap1.get("ASNAdmnGrpIds");
            ASNStdAlnMmbrGrpIds = (ArrayList)hashmap1.get("ASNStdAlnMmbrGrpIds");
            accessType = (String)hashmap1.get("ASNAccessOverride");
        }
        String s2 = null;
        Object obj1 = null;
        Number number2 = null;
        Number number3 = null;
        Number number4 = null;
        Number number5 = null;
        Number number6 = null;
        String s3 = null;
        Object obj2 = null;
        String s5 = null;
        
        //stringbuffer1.append(" FROM  as_leads_all  OpportunityEO ");
        /* GSD - Changed FROM clause to order the records in the as_leads_all table by creation date*/
        stringbuffer1.append(" FROM  (SELECT * FROM apps.as_leads_all ORDER BY creation_date desc )OpportunityEO "); 
        
        OADBTransaction oadbtransaction = oaapplicationmodule.getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(1);
        String s6 = "asn.opportunity.server.OpptySearchManager.constructFromWhereClause";
        if(accessType == null)
        {
            accessType = oadbtransaction.getProfile("ASN_OPP_ACCESS");
            if(accessType == null || "".equals(accessType.trim()))
                accessType = "T";
        }
        String s7 = oadbtransaction.getProfile("JTF_PROFILE_DEFAULT_CURRENCY");
        String s8 = oadbtransaction.getProfile("ASN_CURRCONV_PERIOD_TYPE");
        String s9 = oadbtransaction.getProfile("ASN_FRCST_FORECAST_CALENDAR");
        MessageToken amessagetoken1[] = {
            new MessageToken("IDNAME", "Credit Type")
        };
        Number number7 = ASNUtil.stringToJboNumber(oadbtransaction.getProfile("ASN_FRCST_CREDIT_TYPE_ID"), "ASN_CMMN_STR_TO_JBONUM_ERR", amessagetoken1);
        if(flag)
        {
            StringBuffer stringbuffer2 = new StringBuffer(100);
            stringbuffer2.append("  Input Params : ");
            stringbuffer2.append(" AccessType : ");
            stringbuffer2.append(accessType);
            stringbuffer2.append(" resourceId :");
            stringbuffer2.append(number);
            stringbuffer2.append(" Standalone Member :");
            stringbuffer2.append(s1);
            stringbuffer2.append(" MgrFlag :");
            stringbuffer2.append(ASNMgrFlag);
            stringbuffer2.append(" REFRESH :");
            stringbuffer2.append(Refresh);
            stringbuffer2.append(" currencyCode :");
            stringbuffer2.append(s7);
            stringbuffer2.append(" periodType :");
            stringbuffer2.append(s8);
            stringbuffer2.append(" periodSetName :");
            stringbuffer2.append(s9);
            stringbuffer2.append(" frcstCreditType :");
            stringbuffer2.append(number7);
            oadbtransaction.writeDiagnostics(s6, stringbuffer2.toString(), 1);
        }
//Mohan
        if(searchCriteria.containsKey("ASNOpptyLstStCatgCode"))
        {
            ArrayList arraylist = (ArrayList)searchCriteria.get("ASNOpptyLstStCatgCode");
            int i = arraylist.size();
            for(int l8 = 0; l8 < i; l8++)
            {
                SearchCriteria searchcriteria7 = (SearchCriteria)arraylist.get(l8);
                if(searchcriteria7.getConditionOperator().trim().equals("<>"))
                {
                    if(((String)searchcriteria7.getValue()).equals("Y")) {
                        s2 = "N";
//Mohan Added the following block 10/20/2008
                      stringbuffer1.append("  , as_statuses_b asbs  ");
                      String oppStsCtgWhereClause = "  OpportunityEO.status = asbs.status_code and asbs.opp_open_status_flag = '" + s2 +"' ";
                      addWhereClause(oppStsCtgWhereClause);
//Mohan Added block ends.

                    } else if(((String)searchcriteria7.getValue()).equals("N")) {
                        s2 = "Y";                     
//Mohan Added the following block 10/20/2008
                      stringbuffer1.append("  , as_statuses_b asbs  ");
                      String oppStsCtgWhereClause = "  OpportunityEO.status = asbs.status_code and asbs.opp_open_status_flag = '" + s2 +"' ";
                      addWhereClause(oppStsCtgWhereClause);
//Mohan Added block ends.
                    } else 
                    {
                      
                    }
                } else
                {
                    s2 = (String)searchcriteria7.getValue();
//Mohan Added the following block 10/20/2008
                      stringbuffer1.append("  , as_statuses_b asbs  ");
                      String oppStsCtgWhereClause = "  OpportunityEO.status = asbs.status_code and asbs.opp_open_status_flag = '" + s2 +"' ";
                      addWhereClause(oppStsCtgWhereClause);
//Mohan Added block ends.
                }
            }

        }
        if(searchCriteria.containsKey("ASNOpptyLstStatMgr"))
        {
            ArrayList arraylist1 = (ArrayList)searchCriteria.get("ASNOpptyLstStatMgr");
            int j = arraylist1.size();
            for(int i9 = 0; i9 < j; i9++)
            {
                SearchCriteria searchcriteria8 = (SearchCriteria)arraylist1.get(i9);
                String s12 = (String)searchcriteria8.getValue();
                if(s12 != null && !"".equals(s12.trim()))
                    if(searchcriteria8.getConditionOperator().trim().equals("<>"))
                    {
                        if("Y".equals(s12.substring(s12.length() - 1)))
                            s2 = "N";
                        else
                        if("N".equals(s12.substring(s12.length() - 1)))
                            s2 = "Y";
                    } else
                    {
                        s2 = s12.substring(s12.length() - 1);
                    }
            }

        }
        if(hashmap != null)
        {
            if(hashmap.containsKey("ASNSrchLnkQryFor"))
            {
                String s = (String)hashmap.get("ASNSrchLnkQryFor");
                if("T".equals(s))
                    accessType = "T";
                else
                    number2 = number;
            }
            if(hashmap.containsKey("ASNSrchLnkOpen"))
                s2 = "Y";
            if(hashmap.containsKey("ASNSrchLnkCustId"))
            {
                Object obj3 = hashmap.get("ASNSrchLnkCustId");
                MessageToken amessagetoken2[] = {
                    new MessageToken("IDNAME", "CustomerId")
                };
                number5 = ASNUtil.stringToJboNumber((String)obj3, "ASN_CMMN_STR_TO_JBONUM_ERR", amessagetoken2);
            }
            if(hashmap.containsKey("ASNSrchLnkWon") || hashmap.containsKey("ASNSrchLnkLost") || hashmap.containsKey("ASNSrchLnkInPgs"))
                s5 = "Y";
            if(flag)
            {
                StringBuffer stringbuffer3 = new StringBuffer(50);
                stringbuffer3.append(" Dashboard Search -- Sales campaign  ");
                stringbuffer3.append(s5);
                stringbuffer3.append(" Dashboard Search -- Customer :");
                stringbuffer3.append(" custId = ");
                stringbuffer3.append(number5);
                stringbuffer3.append(" StatusOpenFlag ");
                stringbuffer3.append(s2);
                oadbtransaction.writeDiagnostics(s6, stringbuffer3.toString(), 1);
            }
        }
        if(searchCriteria.containsKey("ASNOpptyLstSlsRepId"))
        {
            ArrayList arraylist2 = (ArrayList)searchCriteria.get("ASNOpptyLstSlsRepId");
            int k = arraylist2.size();
            for(int j9 = 0; j9 < k; j9++)
            {
                SearchCriteria searchcriteria9 = (SearchCriteria)arraylist2.get(j9);
                MessageToken amessagetoken5[] = {
                    new MessageToken("IDNAME", "SalesRepId")
                };
                number3 = ASNUtil.stringToJboNumber((String)searchcriteria9.getValue(), "ASN_CMMN_STR_TO_JBONUM_ERR", amessagetoken5);
            }

        }
        if(searchCriteria.containsKey("ASNOpptyQryIndicator"))
        {
            ArrayList arraylist3 = (ArrayList)searchCriteria.get("ASNOpptyQryIndicator");
            int l = arraylist3.size();
            for(int k9 = 0; k9 < l; k9++)
            {
                SearchCriteria searchcriteria10 = (SearchCriteria)arraylist3.get(k9);
                String s4 = (String)searchcriteria10.getValue();
                if(s4.equals("SALESTEAM"))
                    accessType = "T";
                if(searchcriteria10.getValue().equals("OWNER"))
                {
                    number2 = number;
                    if(flag)
                    {
                        StringBuffer stringbuffer10 = new StringBuffer(100);
                        stringbuffer10.append("Oppty Query Indicator for seeded View : Y");
                        oadbtransaction.writeDiagnostics(s6, stringbuffer10.toString(), 1);
                    }
                }
            }

        }
        if(searchCriteria.containsKey("ASNOpptyLstRscId"))
        {
            ArrayList arraylist4 = (ArrayList)searchCriteria.get("ASNOpptyLstRscId");
            int i1 = arraylist4.size();
            for(int l9 = 0; l9 < i1; l9++)
            {
                SearchCriteria searchcriteria11 = (SearchCriteria)arraylist4.get(l9);
                MessageToken amessagetoken6[] = {
                    new MessageToken("IDNAME", "OwnerId")
                };
                number2 = ASNUtil.stringToJboNumber((String)searchcriteria11.getValue(), "ASN_CMMN_STR_TO_JBONUM_ERR", amessagetoken6);
                if(flag)
                {
                    StringBuffer stringbuffer11 = new StringBuffer(100);
                    stringbuffer11.append("Owner Search == resourceId :");
                    stringbuffer11.append("resourceId = ");
                    stringbuffer11.append(number);
                    oadbtransaction.writeDiagnostics(s6, stringbuffer11.toString(), 1);
                }
            }

        }
        if(searchCriteria.containsKey("ASNOpptyLstSlsGrpId"))
        {
            ArrayList arraylist5 = (ArrayList)searchCriteria.get("ASNOpptyLstSlsGrpId");
            int j1 = arraylist5.size();
            for(int i10 = 0; i10 < j1; i10++)
            {
                SearchCriteria searchcriteria12 = (SearchCriteria)arraylist5.get(i10);
                MessageToken amessagetoken7[] = {
                    new MessageToken("IDNAME", "GroupId")
                };
                number4 = ASNUtil.stringToJboNumber((String)searchcriteria12.getValue(), "ASN_CMMN_STR_TO_JBONUM_ERR", amessagetoken7);
            }

        }
        if(searchCriteria.containsKey("ASNOpptyLstContribId"))
        {
            ArrayList arraylist6 = (ArrayList)searchCriteria.get("ASNOpptyLstContribId");
            int k1 = arraylist6.size();
            for(int j10 = 0; j10 < k1; j10++)
            {
                SearchCriteria searchcriteria13 = (SearchCriteria)arraylist6.get(j10);
                MessageToken amessagetoken8[] = {
                    new MessageToken("IDNAME", "ContributorId")
                };
                number6 = ASNUtil.stringToJboNumber((String)searchcriteria13.getValue(), "ASN_CMMN_STR_TO_JBONUM_ERR", amessagetoken8);
            }

        }
        if(searchCriteria.containsKey("ASNOpptyLstFrcst"))
        {
            ArrayList arraylist7 = (ArrayList)searchCriteria.get("ASNOpptyLstFrcst");
            int l1 = arraylist7.size();
            for(int k10 = 0; k10 < l1; k10++)
            {
                SearchCriteria searchcriteria14 = (SearchCriteria)arraylist7.get(k10);
                if(searchcriteria14.getConditionOperator().trim().equals("<>"))
                {
                    if(((String)searchcriteria14.getValue()).equals("Y"))
                        s3 = "N";
                    else
                    if(((String)searchcriteria14.getValue()).equals("N"))
                        s3 = "Y";
                } else
                {
                    s3 = (String)searchcriteria14.getValue();
                }
            }

        }
        if(!Refresh)
        {
            //Mohan 
            oadbtransaction.writeDiagnostics("===>> Mohan before put Hashmap", " Value of s2: "+s2, 1);
            HashMap hashmap2 = new HashMap(9);
            hashmap2.put("AccessType", accessType);
            hashmap2.put("OwnerId", number2);
            hashmap2.put("SalesPersonId", number3);
            hashmap2.put("ResourceId", number);
            hashmap2.put("ContributorId", number6);
            hashmap2.put("GroupId", number4);
            hashmap2.put("DashCustomer", number5);
            hashmap2.put("StatusOpenFlag", s2);
            hashmap2.put("Forecastable", s3);
            hashmap2.put("ObjectType", "OPPTY");
            hashmap2.put("ASNStdAlnMmbrFlag", s1);
            hashmap2.put("ASNMgrFlag", ASNMgrFlag);
            hashmap2.put("ASNMgrGrpIds", ASNMgrGrpIds);
            hashmap2.put("ASNStdAlnMmbrGrpIds", ASNStdAlnMmbrGrpIds);
            hashmap2.put("ASNAdminGrpIds", ASNAdminGrpIds);
            hashmap2.put("trans", oadbtransaction);
            hashmap2.put("DashSalescampaignSrch", s5);
            HashMap hashmap3 = new HashMap(4);
            hashmap3 = getSecurityClause(hashmap2);
            stringbuffer1.append((StringBuffer)hashmap3.get("FromClause"));
            stringbuffer.append((StringBuffer)hashmap3.get("filterClause"));
            whereClause.append((StringBuffer)hashmap3.get("whereClause"));
            bindSequence = super.bindSeq;
            ArrayList arraylist37 = (ArrayList)hashmap3.get("bindVars");
            if(arraylist37 != null && arraylist37.size() > 0)
            {
                for(int l15 = 0; l15 < arraylist37.size(); l15++)
                    bindVariables.add(arraylist37.get(l15));

            }
        }
        if(searchCriteria.containsKey("ASNOpptyLstNm"))
        {
            ArrayList arraylist8 = (ArrayList)searchCriteria.get("ASNOpptyLstNm");
            for(int i2 = 0; i2 < arraylist8.size(); i2++)
            {
                SearchCriteria searchcriteria = (SearchCriteria)arraylist8.get(i2);
                stringbuffer.append(" AND ");
                stringbuffer.append(" UPPER(OpportunityEO.Description) ");
                stringbuffer.append(searchcriteria.getConditionOperator());
                stringbuffer.append(":" + bindSequence++);
                bindVariables.add(((String)searchcriteria.getValue()).toUpperCase());
            }

        }
        if(number2 != null)
        {
            stringbuffer.append(" AND  ");
            stringbuffer.append("  OpportunityEO.owner_salesforce_id  = ");
            stringbuffer.append(":" + bindSequence++);
            bindVariables.add(number2);
            if(flag)
            {
                StringBuffer stringbuffer4 = new StringBuffer(100);
                stringbuffer4.append("Owner Search  :");
                stringbuffer4.append("ownerId = ");
                stringbuffer4.append(number2);
                oadbtransaction.writeDiagnostics(s6, stringbuffer4.toString(), 1);
            }
        }
        if(hashmap != null)
        {
            if(hashmap.containsKey("ASNSrchLnkSrcPrmId"))
            {
                Object obj4 = hashmap.get("ASNSrchLnkSrcPrmId");
                stringbuffer.append(" AND OpportunityEO.source_promotion_id = ");
                stringbuffer.append(":" + bindSequence++);
                MessageToken amessagetoken3[] = {
                    new MessageToken("IDNAME", "dashboard CampaignId")
                };
                Number number8 = ASNUtil.stringToJboNumber((String)obj4, "ASN_CMMN_STR_TO_JBONUM_ERR", amessagetoken3);
                bindVariables.add(number8);
                if(flag)
                {
                    StringBuffer stringbuffer8 = new StringBuffer(100);
                    stringbuffer8.append("Dashboard Search -- Source Code :");
                    stringbuffer8.append("SrcCdForId = ");
                    stringbuffer8.append(number8);
                    oadbtransaction.writeDiagnostics(s6, stringbuffer8.toString(), 1);
                }
            }
            if(hashmap.containsKey("ASNSrchLnkStg"))
            {
                Object obj5 = hashmap.get("ASNSrchLnkStg");
                ArrayList arraylist36 = new ArrayList(5);
                Number number10;
                for(StringTokenizer stringtokenizer = new StringTokenizer((String)obj5, ","); stringtokenizer.hasMoreTokens(); arraylist36.add(number10))
                {
                    String s11 = stringtokenizer.nextToken();
                    MessageToken amessagetoken9[] = {
                        new MessageToken("IDNAME", "StageId")
                    };
                    number10 = ASNUtil.stringToJboNumber(s11, "ASN_CMMN_STR_TO_JBONUM_ERR", amessagetoken9);
                }

                stringbuffer.append(" AND OpportunityEO.sales_stage_id  in( ");
                if(arraylist36 != null && arraylist36.size() > 0)
                {
                    for(int i16 = 0; i16 < arraylist36.size(); i16++)
                    {
                        stringbuffer.append(":" + bindSequence++);
                        stringbuffer.append(",");
                        bindVariables.add(arraylist36.get(i16));
                    }

                }
                if(stringbuffer.toString().endsWith(","))
                {
                    stringbuffer.setLength(stringbuffer.length() - 1);
                    stringbuffer.append(") ");
                }
            }
            if(hashmap.containsKey("ASNSrchLnkAgeDays"))
            {
                Object obj6 = hashmap.get("ASNSrchLnkAgeDays");
                MessageToken amessagetoken4[] = {
                    new MessageToken("IDNAME", "AgeDays")
                };
                Number number9 = ASNUtil.stringToJboNumber((String)obj6, "ASN_CMMN_STR_TO_JBONUM_ERR", amessagetoken4);
                stringbuffer.append(" AND CEIL(SYSDATE - OpportunityEO.Creation_Date) <= ");
                stringbuffer.append(":" + bindSequence++);
                bindVariables.add(number9);
                if(flag)
                {
                    StringBuffer stringbuffer9 = new StringBuffer(100);
                    stringbuffer9.append("Dashboard Search -- Age Days :");
                    stringbuffer9.append(" age Days = ");
                    stringbuffer9.append(number9);
                    oadbtransaction.writeDiagnostics(s6, stringbuffer9.toString(), 1);
                }
            }
            if(hashmap.containsKey("ASNSrchLnkInPgs"))
            {
                addWhereClause(" asb.opp_open_status_flag = 'Y' AND asb.win_loss_indicator <> 'W' ");
                if(flag)
                {
                    StringBuffer stringbuffer5 = new StringBuffer(100);
                    stringbuffer5.append("Dashboard Search -- ASNSrchLnkInPgs:");
                    oadbtransaction.writeDiagnostics(s6, stringbuffer5.toString(), 1);
                }
            } else
            if(hashmap.containsKey("ASNSrchLnkLost"))
            {
                addWhereClause(" NVL(asb.opp_open_status_flag, 'N') = 'N' and  asb.win_loss_indicator <> 'W' ");
                if(flag)
                {
                    StringBuffer stringbuffer6 = new StringBuffer(100);
                    stringbuffer6.append("Dashboard Search -- ASNSrchLnkLost:");
                    oadbtransaction.writeDiagnostics(s6, stringbuffer6.toString(), 1);
                }
            } else
            if(hashmap.containsKey("ASNSrchLnkWon"))
            {
                addWhereClause(" asb.win_loss_indicator = 'W' ");
                if(flag)
                {
                    StringBuffer stringbuffer7 = new StringBuffer(100);
                    stringbuffer7.append("Dashboard Search -- ASNSrchLnkWon:");
                    oadbtransaction.writeDiagnostics(s6, stringbuffer7.toString(), 1);
                }
            }
        }
        if(searchCriteria.containsKey("ASNOpptyLstWinProRange"))
        {
            ArrayList arraylist9 = (ArrayList)searchCriteria.get("ASNOpptyLstWinProRange");
            int j2 = arraylist9.size();
            for(int l10 = 0; l10 < j2; l10++)
            {
                SearchCriteria searchcriteria15 = (SearchCriteria)arraylist9.get(l10);
                String s13 = (String)searchcriteria15.getValue();
                if(s13 != null && !"".equals(s13.trim()))
                {
                    int l16 = s13.indexOf("-");
                    if(l16 != -1)
                    {
                        MessageToken amessagetoken11[] = {
                            new MessageToken("IDNAME", s13.substring(0, l16))
                        };
                        Number number11 = ASNUtil.stringToJboNumber(s13.substring(0, l16), "ASN_CMMN_STR_TO_JBONUM_ERR", amessagetoken11);
                        MessageToken amessagetoken17[] = {
                            new MessageToken("IDNAME", s13.substring(l16 + 1))
                        };
                        Number number17 = ASNUtil.stringToJboNumber(s13.substring(l16 + 1), "ASN_CMMN_STR_TO_JBONUM_ERR", amessagetoken17);
                        stringbuffer.append(" AND OpportunityEO.win_probability >= :" + bindSequence++);
                        bindVariables.add(number11);
                        stringbuffer.append(" AND OpportunityEO.win_probability <= :" + bindSequence++);
                        bindVariables.add(number17);
                    } else
                    {
                        int i17 = s13.indexOf("<=");
                        if(i17 != -1)
                        {
                            MessageToken amessagetoken12[] = {
                                new MessageToken("IDNAME", s13.substring(0, i17))
                            };
                            Number number12 = ASNUtil.stringToJboNumber(s13.substring(i17 + 2), "ASN_CMMN_STR_TO_JBONUM_ERR", amessagetoken12);
                            stringbuffer.append(" AND OpportunityEO.win_probability <= :" + bindSequence++);
                            bindVariables.add(number12);
                        } else
                        {
                            int j17 = s13.indexOf(">=");
                            if(j17 != -1)
                            {
                                MessageToken amessagetoken13[] = {
                                    new MessageToken("IDNAME", s13.substring(0, j17))
                                };
                                Number number13 = ASNUtil.stringToJboNumber(s13.substring(j17 + 2), "ASN_CMMN_STR_TO_JBONUM_ERR", amessagetoken13);
                                stringbuffer.append(" AND OpportunityEO.win_probability >= :" + bindSequence++);
                                bindVariables.add(number13);
                            } else
                            {
                                int k17 = s13.indexOf(">");
                                if(k17 != -1)
                                {
                                    MessageToken amessagetoken14[] = {
                                        new MessageToken("IDNAME", s13.substring(0, k17))
                                    };
                                    Number number14 = ASNUtil.stringToJboNumber(s13.substring(k17 + 1), "ASN_CMMN_STR_TO_JBONUM_ERR", amessagetoken14);
                                    stringbuffer.append(" AND OpportunityEO.win_probability > :" + bindSequence++);
                                    bindVariables.add(number14);
                                } else
                                {
                                    int l17 = s13.indexOf("<");
                                    if(l17 != -1)
                                    {
                                        MessageToken amessagetoken15[] = {
                                            new MessageToken("IDNAME", s13.substring(0, l17))
                                        };
                                        Number number15 = ASNUtil.stringToJboNumber(s13.substring(l17 + 1), "ASN_CMMN_STR_TO_JBONUM_ERR", amessagetoken15);
                                        stringbuffer.append(" AND OpportunityEO.win_probability < :" + bindSequence++);
                                        bindVariables.add(number15);
                                    } else
                                    {
                                        MessageToken amessagetoken16[] = {
                                            new MessageToken("IDNAME", s13.substring(0, l17))
                                        };
                                        Number number16 = ASNUtil.stringToJboNumber(s13, "ASN_CMMN_STR_TO_JBONUM_ERR", amessagetoken16);
                                        stringbuffer.append(" AND OpportunityEO.win_probability = :" + bindSequence++);
                                        bindVariables.add(number16);
                                    }
                                }
                            }
                        }
                    }
                }
            }

        }
        if(searchCriteria.containsKey("ASNOpptyLstDateRange"))
        {
            ArrayList arraylist10 = (ArrayList)searchCriteria.get("ASNOpptyLstDateRange");
            int k2 = arraylist10.size();
            for(int i11 = 0; i11 < k2; i11++)
            {
                SearchCriteria searchcriteria16 = (SearchCriteria)arraylist10.get(i11);
                String s14 = (String)searchcriteria16.getValue();
                if(s14 != null && !"".equals(s14.trim()))
                    if(s14.equals("-999"))
                    {
                        String s17 = oadbtransaction.getProfile("ASN_FRCST_FORECAST_CALENDAR");
                        HashMap hashmap4 = checkPerioddate(oaapplicationmodule, s17);
                        if(hashmap4 != null)
                        {
                            stringbuffer.append(" AND OpportunityEO.Decision_date >= (:" + bindSequence++);
                            bindVariables.add(hashmap4.get("StartDate"));
                            stringbuffer.append(" ) ");
                            stringbuffer.append(" AND OpportunityEO.Decision_date <= (:" + bindSequence++);
                            bindVariables.add(hashmap4.get("EndDate"));
                            stringbuffer.append(" ) ");
                        }
                    } else
                    {
                        int i18 = s14.indexOf(",");
                        if(i18 != -1)
                        {
                            String s18 = s14.substring(0, i18);
                            String s22 = s14.substring(i18 + 1);
                            Date date2 = new Date(oadbtransaction.getOANLSServices().stringToDate(s18));
                            Date date4 = new Date(oadbtransaction.getOANLSServices().stringToDate(s22));
                            stringbuffer.append(" AND OpportunityEO.Decision_date >= (:" + bindSequence++);
                            bindVariables.add(date2);
                            stringbuffer.append(" ) ");
                            stringbuffer.append(" AND OpportunityEO.Decision_date <= (:" + bindSequence++);
                            bindVariables.add(date4);
                            stringbuffer.append(" ) ");
                        } else
                        {
                            int j18 = s14.indexOf("-");
                            if(j18 != -1)
                            {
                                String s19 = s14.substring(0, j18);
                                String s23 = s14.substring(j18 + 1);
                                Date date3 = new Date(oadbtransaction.getOANLSServices().stringToDate(s19));
                                Date date5 = new Date(oadbtransaction.getOANLSServices().stringToDate(s23));
                                stringbuffer.append(" AND OpportunityEO.Decision_date >= (:" + bindSequence++);
                                bindVariables.add(date3);
                                stringbuffer.append(" ) ");
                                stringbuffer.append(" AND OpportunityEO.Decision_date <= (:" + bindSequence++);
                                bindVariables.add(date5);
                                stringbuffer.append(" ) ");
                            } else
                            {
                                int k18 = s14.indexOf("<=");
                                if(k18 != -1)
                                {
                                    String s20;
                                    if(s14.startsWith("<="))
                                        s20 = s14.substring(k18 + 2);
                                    else
                                        s20 = s14.substring(0, k18);
                                    Date date = new Date(oadbtransaction.getOANLSServices().stringToDate(s20));
                                    stringbuffer.append(" AND OpportunityEO.Decision_date <= (:" + bindSequence++);
                                    bindVariables.add(date);
                                    stringbuffer.append(" ) ");
                                } else
                                {
                                    int l18 = s14.indexOf(">=");
                                    if(l18 != -1)
                                    {
                                        String s21;
                                        if(s14.startsWith(">="))
                                            s21 = s14.substring(l18 + 2);
                                        else
                                            s21 = s14.substring(0, l18);
                                        stringbuffer.append(" AND OpportunityEO.Decision_date >= (:" + bindSequence++);
                                        bindVariables.add(s21);
                                        stringbuffer.append(" ) ");
                                    } else
                                    {
                                        Date date1 = new Date(oadbtransaction.getOANLSServices().stringToDate(s14));
                                        stringbuffer.append(" AND OpportunityEO.Decision_date <= (:" + bindSequence++);
                                        bindVariables.add(date1);
                                        stringbuffer.append(" ) ");
                                    }
                                }
                            }
                        }
                    }
            }

        }
        if(searchCriteria.containsKey("ASNOpptyLstPartnerId"))
        {
            ArrayList arraylist11 = (ArrayList)searchCriteria.get("ASNOpptyLstPartnerId");
            int l2 = arraylist11.size();
            for(int j11 = 0; j11 < l2; j11++)
            {
                SearchCriteria searchcriteria17 = (SearchCriteria)arraylist11.get(j11);
                MessageToken amessagetoken10[] = {
                    new MessageToken("IDNAME", "PartnerId")
                };
                Number number1 = ASNUtil.stringToJboNumber((String)searchcriteria17.getValue(), "ASN_CMMN_STR_TO_JBONUM_ERR", amessagetoken10);
                stringbuffer.append(" AND OpportunityEO.lead_id in ");
/*ODR
                stringbuffer.append(" (SELECT prm.Lead_Id from as_accesses_all prm ");
                stringbuffer.append("  where prm.sales_lead_id IS  NULL ");
                stringbuffer.append(" AND    prm.lead_id IS NOT NULL ");
                stringbuffer.append(" AND    prm.lead_id = opportunityEO.lead_id ");
                stringbuffer.append(" AND  prm.partner_customer_id = ");
*/
                stringbuffer.append(" (SELECT prm.entity_Id from XX_TM_NAM_TERR_CURR_ASSIGN_V prm ");
                stringbuffer.append("  where prm.entity_type='OPPORTUNITY' ");
                stringbuffer.append(" AND    prm.entity_id = opportunityEO.lead_id ");

//                stringbuffer.append(":" + bindSequence++);
//                bindVariables.add(searchcriteria17.getValue());
                stringbuffer.append(" )");
            }

        }
        if(searchCriteria.containsKey("ASNOpptyLstCustNm"))
        {
            ArrayList arraylist12 = (ArrayList)searchCriteria.get("ASNOpptyLstCustNm");
            int i3 = arraylist12.size();
            for(int k11 = 0; k11 < i3; k11++)
            {
                SearchCriteria searchcriteria18 = (SearchCriteria)arraylist12.get(k11);
                stringbuffer.append(" AND  ");
                stringbuffer.append(" UPPER(hp.party_name) ");
                stringbuffer.append(searchcriteria18.getConditionOperator());
                stringbuffer.append(":" + bindSequence++);
                bindVariables.add(((String)searchcriteria18.getValue()).toUpperCase());
            }

        }
        if(renderedVwAttrs.contains("OpptyStatusName"))
        {
            stringbuffer1.append(" ,  as_statuses_tl ast ");
            addWhereClause(" OpportunityEO.status = ast.status_code  ");
            addWhereClause(" ast.language = USERENV('LANG')");
        }
        if(searchCriteria.containsKey("ASNOpptyLstStatus"))
        {
            ArrayList arraylist13 = (ArrayList)searchCriteria.get("ASNOpptyLstStatus");
            int j3 = arraylist13.size();
            for(int l11 = 0; l11 < j3; l11++)
            {
                SearchCriteria searchcriteria19 = (SearchCriteria)arraylist13.get(l11);
                stringbuffer.append(" AND  ");
                stringbuffer.append(" OpportunityEO.status ");
                stringbuffer.append(searchcriteria19.getConditionOperator());
                stringbuffer.append(":" + bindSequence++);
                bindVariables.add(searchcriteria19.getValue());
            }

        }
        if(searchCriteria.containsKey("ASNOpptyLstStatMgr"))
        {
            ArrayList arraylist14 = (ArrayList)searchCriteria.get("ASNOpptyLstStatMgr");
            int k3 = arraylist14.size();
            for(int i12 = 0; i12 < k3; i12++)
            {
                SearchCriteria searchcriteria20 = (SearchCriteria)arraylist14.get(i12);
                String s15 = (String)searchcriteria20.getValue();
                if(s15 != null && !"".equals(s15.trim()))
                {
                    stringbuffer.append(" AND  ");
                    stringbuffer.append(" OpportunityEO.status ");
                    stringbuffer.append(searchcriteria20.getConditionOperator());
                    stringbuffer.append(":" + bindSequence++);
                    bindVariables.add(s15.substring(0, s15.length() - 2));
                }
            }

        }
        if(renderedVwAttrs.contains("SalesStageName"))
        {
            stringbuffer1.append(" ,  as_sales_stages_all_tl asst ");
            if(searchCriteria.containsKey("ASNOpptyLstStageId"))
            {
                addWhereClause(" OpportunityEO.sales_stage_id = asst.sales_stage_id ");
                addWhereClause("  asst.language = USERENV ('LANG') ");
            } else
            {
                addWhereClause(" OpportunityEO.sales_stage_id = asst.sales_stage_id(+)  ");
                addWhereClause(" asst.language (+) = USERENV ('LANG') ");
            }
        }
        if(searchCriteria.containsKey("ASNOpptyLstStageId"))
        {
            ArrayList arraylist15 = (ArrayList)searchCriteria.get("ASNOpptyLstStageId");
            int l3 = arraylist15.size();
            for(int j12 = 0; j12 < l3; j12++)
            {
                SearchCriteria searchcriteria21 = (SearchCriteria)arraylist15.get(j12);
                stringbuffer.append(" AND  ");
                stringbuffer.append(" OpportunityEO.sales_stage_id ");
                stringbuffer.append(searchcriteria21.getConditionOperator());
                stringbuffer.append(":" + bindSequence++);
                bindVariables.add(searchcriteria21.getValue());
            }

        }
        if(renderedVwAttrs.contains("CurrencyName"))
        {
            stringbuffer1.append(" ,  fnd_currencies_tl fnt ");
            addWhereClause("  OpportunityEO.currency_code = fnt.currency_code ");
            addWhereClause(" fnt.language = USERENV('LANG')");
        }
        if(searchCriteria.containsKey("ASNOpptyLstCurr"))
        {
            ArrayList arraylist16 = (ArrayList)searchCriteria.get("ASNOpptyLstCurr");
            int i4 = arraylist16.size();
            for(int k12 = 0; k12 < i4; k12++)
            {
                SearchCriteria searchcriteria22 = (SearchCriteria)arraylist16.get(k12);
                stringbuffer.append(" AND  ");
                stringbuffer.append(" OpportunityEO.currency_code ");
                stringbuffer.append(searchcriteria22.getConditionOperator());
                stringbuffer.append(":" + bindSequence++);
                bindVariables.add(searchcriteria22.getValue());
            }

        }
        if(searchCriteria.containsKey("ASNOpptyLstDate"))
        {
            ArrayList arraylist17 = (ArrayList)searchCriteria.get("ASNOpptyLstDate");
            for(int j4 = 0; j4 < arraylist17.size(); j4++)
            {
                SearchCriteria searchcriteria1 = (SearchCriteria)arraylist17.get(j4);
                stringbuffer.append(" AND ");
                stringbuffer.append(" OpportunityEO.Decision_Date ");
                stringbuffer.append(searchcriteria1.getConditionOperator());
                stringbuffer.append(":" + bindSequence++);
                bindVariables.add(searchcriteria1.getValue());
            }

        }
        if(searchCriteria.containsKey("ASNOpptyLstCrtedDate"))
        {
            ArrayList arraylist18 = (ArrayList)searchCriteria.get("ASNOpptyLstCrtedDate");
            for(int k4 = 0; k4 < arraylist18.size(); k4++)
            {
                SearchCriteria searchcriteria2 = (SearchCriteria)arraylist18.get(k4);
                stringbuffer.append(" AND ");
                stringbuffer.append(" trunc(OpportunityEO.Creation_Date) ");
                stringbuffer.append(searchcriteria2.getConditionOperator());
                stringbuffer.append(" trunc(:" + bindSequence++);
                bindVariables.add(searchcriteria2.getValue());
                stringbuffer.append(" ) ");
            }

        }
        if(searchCriteria.containsKey("ASNOpptyLstWinProb"))
        {
            ArrayList arraylist19 = (ArrayList)searchCriteria.get("ASNOpptyLstWinProb");
            for(int l4 = 0; l4 < arraylist19.size(); l4++)
            {
                SearchCriteria searchcriteria3 = (SearchCriteria)arraylist19.get(l4);
                stringbuffer.append(" AND  ");
                stringbuffer.append(" OpportunityEO.Win_Probability ");
                stringbuffer.append(searchcriteria3.getConditionOperator());
                stringbuffer.append(":" + bindSequence++);
                bindVariables.add(searchcriteria3.getValue());
            }

        }
        if(searchCriteria.containsKey("ASNOpptyLstNbr"))
        {
            ArrayList arraylist20 = (ArrayList)searchCriteria.get("ASNOpptyLstNbr");
            for(int i5 = 0; i5 < arraylist20.size(); i5++)
            {
                SearchCriteria searchcriteria4 = (SearchCriteria)arraylist20.get(i5);
                stringbuffer.append(" AND  ");
                stringbuffer.append(" OpportunityEO.Lead_Number ");
                stringbuffer.append(searchcriteria4.getConditionOperator());
                stringbuffer.append(":" + bindSequence++);
                bindVariables.add(searchcriteria4.getValue());
            }

        }
        if(renderedVwAttrs.contains("SalesChannel"))
        {
            stringbuffer1.append(",  fnd_lookup_values chnl ");
            if(searchCriteria.containsKey("ASNOpptyLstChnl"))
            {
                addWhereClause(" OpportunityEO.channel_code = chnl.lookup_code ");
                addWhereClause(" chnl.lookup_type = 'SALES_CHANNEL' ");
                addWhereClause(" chnl.view_application_id  = 660 ");
                addWhereClause(" chnl.language  = USERENV( 'LANG') ");
            } else
            {
                addWhereClause(" OpportunityEO.channel_code = chnl.lookup_code (+)");
                addWhereClause(" chnl.lookup_type(+) = 'SALES_CHANNEL' ");
                addWhereClause(" chnl.view_application_id (+) = 660 ");
                addWhereClause(" chnl.language (+) = USERENV( 'LANG') ");
            }
        }
        if(searchCriteria.containsKey("ASNOpptyLstChnl"))
        {
            ArrayList arraylist21 = (ArrayList)searchCriteria.get("ASNOpptyLstChnl");
            int j5 = arraylist21.size();
            for(int l12 = 0; l12 < j5; l12++)
            {
                SearchCriteria searchcriteria23 = (SearchCriteria)arraylist21.get(l12);
                stringbuffer.append(" AND  ");
                stringbuffer.append(" OpportunityEO.channel_code ");
                stringbuffer.append(searchcriteria23.getConditionOperator());
                stringbuffer.append(":" + bindSequence++);
                bindVariables.add(searchcriteria23.getValue());
            }

        }
        if(renderedVwAttrs.contains("SourceName"))
        {
            stringbuffer1.append(" ,   ams_source_codes amsc ");
            if(searchCriteria.containsKey("ASNOpptyLstSrc"))
                addWhereClause(" OpportunityEO.source_promotion_id = amsc.source_code_id ");
            else
                addWhereClause(" OpportunityEO.source_promotion_id = amsc.source_code_id (+) ");
        }
        if(searchCriteria.containsKey("ASNOpptyLstSrc"))
        {
            ArrayList arraylist22 = (ArrayList)searchCriteria.get("ASNOpptyLstSrc");
            int k5 = arraylist22.size();
            for(int i13 = 0; i13 < k5; i13++)
            {
                SearchCriteria searchcriteria24 = (SearchCriteria)arraylist22.get(i13);
                stringbuffer.append(" AND  ");
                stringbuffer.append("  OpportunityEO.source_promotion_id ");
                stringbuffer.append(searchcriteria24.getConditionOperator());
                stringbuffer.append(":" + bindSequence++);
                bindVariables.add(searchcriteria24.getValue());
            }

        }
        if(renderedVwAttrs.contains("MethodologyNm"))
            if(searchCriteria.containsKey("ASNOpptyLstMeth"))
            {
                stringbuffer1.append(" , as_sales_methodology_tl asmt ");
                addWhereClause("  OpportunityEO.Sales_Methodology_Id = asmt.Sales_Methodology_Id ");
                addWhereClause(" asmt.language = USERENV ('LANG') ");
            } else
            {
                stringbuffer1.append(" , as_sales_methodology_tl asmt ");
                addWhereClause("  OpportunityEO.Sales_Methodology_Id = asmt.Sales_Methodology_Id(+) ");
                addWhereClause(" asmt.language(+) = USERENV ('LANG') ");
            }
        if(searchCriteria.containsKey("ASNOpptyLstMeth"))
        {
            ArrayList arraylist23 = (ArrayList)searchCriteria.get("ASNOpptyLstMeth");
            int l5 = arraylist23.size();
            for(int j13 = 0; j13 < l5; j13++)
            {
                SearchCriteria searchcriteria25 = (SearchCriteria)arraylist23.get(j13);
                stringbuffer.append(" AND  ");
                stringbuffer.append(" OpportunityEO.Sales_Methodology_Id  ");
                stringbuffer.append(searchcriteria25.getConditionOperator());
                stringbuffer.append(":" + bindSequence++);
                bindVariables.add(searchcriteria25.getValue());
            }

        }
        if(renderedVwAttrs.contains("VehicleResponseCode"))
        {
            stringbuffer1.append(" , fnd_lookup_values rspchnl ");
            addWhereClause(" OpportunityEO.vehicle_response_code = rspchnl.lookup_code (+) ");
            addWhereClause(" rspchnl.lookup_type (+) = 'ASN_VEHICLE_RESPONSE_CODE' ");
            addWhereClause(" rspchnl.view_application_id (+) = 0 ");
            addWhereClause(" rspchnl.language (+) = USERENV('LANG')");
        }
        if(searchCriteria.containsKey("ASNOpptyLstLastUpdDate"))
        {
            ArrayList arraylist24 = (ArrayList)searchCriteria.get("ASNOpptyLstLastUpdDate");
            for(int i6 = 0; i6 < arraylist24.size(); i6++)
            {
                SearchCriteria searchcriteria5 = (SearchCriteria)arraylist24.get(i6);
                stringbuffer.append(" AND  ");
                stringbuffer.append(" trunc(OpportunityEO.Last_Update_Date) ");
                stringbuffer.append(searchcriteria5.getConditionOperator());
                stringbuffer.append(" trunc(:" + bindSequence++);
                bindVariables.add(searchcriteria5.getValue());
                stringbuffer.append(" ) ");
            }

        }
        if(searchCriteria.containsKey("ASNOpptyLstPrdCatgId"))
        {
            ArrayList arraylist25 = (ArrayList)searchCriteria.get("ASNOpptyLstPrdCatgId");
            if(searchCriteria.containsKey("ASNOpptyLstInvItem"))
            {
                String s10 = null;
                ArrayList arraylist38 = (ArrayList)searchCriteria.get("ASNOpptyLstInvItem");
                for(int j16 = 0; j16 < arraylist38.size(); j16++)
                {
                    SearchCriteria searchcriteria35 = (SearchCriteria)arraylist38.get(j16);
                    s10 = (String)searchcriteria35.getValue();
                }

                if("-1".equals(s10) || !searchCriteria.containsKey("ASNOpptyLstInvItem"))
                {
                    stringbuffer.append(" AND OpportunityEO.lead_id in ");
                    stringbuffer.append(" (Select al.lead_id from ");
                    stringbuffer.append("  AS_LEAD_LINES_ALL AL,ENI_PROD_DENORM_HRCHY_V Prd ");
                    stringbuffer.append(" where OpportunityEO.Lead_Id = al.Lead_Id  ");
                    stringbuffer.append(" AND AL.PRODUCT_CATEGORY_ID = Prd.CHILD_ID ");
                    stringbuffer.append(" AND AL.PRODUCT_CAT_SET_ID = Prd.CATEGORY_SET_ID ");
                    int k16 = arraylist25.size();
                    for(int i19 = 0; i19 < k16; i19++)
                    {
                        SearchCriteria searchcriteria36 = (SearchCriteria)arraylist25.get(i19);
                        stringbuffer.append(" AND  ");
                        stringbuffer.append(" prd.PARENT_id  ");
                        stringbuffer.append(searchcriteria36.getConditionOperator());
                        stringbuffer.append(":" + bindSequence++);
                        bindVariables.add(searchcriteria36.getValue());
                        stringbuffer.append(" ) ");
                    }

                }
            }
        }
        if(searchCriteria.containsKey("ASNOpptyLstInvItem"))
        {
            ArrayList arraylist26 = (ArrayList)searchCriteria.get("ASNOpptyLstInvItem");
            int j6 = arraylist26.size();
            for(int k13 = 0; k13 < j6; k13++)
            {
                SearchCriteria searchcriteria26 = (SearchCriteria)arraylist26.get(k13);
                String s16 = (String)searchcriteria26.getValue();
                if(!"-1".equals(s16))
                {
                    stringbuffer.append(" AND OpportunityEO.lead_id in ");
                    stringbuffer.append(" (Select al.lead_id from ");
                    stringbuffer.append("  AS_LEAD_LINES_ALL AL ");
                    stringbuffer.append(" where OpportunityEO.Lead_Id = al.Lead_Id  ");
                    stringbuffer.append(" AND  ");
                    stringbuffer.append(" al.inventory_item_id ");
                    stringbuffer.append(searchcriteria26.getConditionOperator());
                    stringbuffer.append(":" + bindSequence++);
                    bindVariables.add(searchcriteria26.getValue());
                    stringbuffer.append(" ) ");
                }
            }

        }
        if(searchCriteria.containsKey("ASNOpptyLstAmt"))
        {
            ArrayList arraylist27 = (ArrayList)searchCriteria.get("ASNOpptyLstAmt");
            for(int k6 = 0; k6 < arraylist27.size(); k6++)
            {
                SearchCriteria searchcriteria6 = (SearchCriteria)arraylist27.get(k6);
                stringbuffer.append(" AND ");
                stringbuffer.append(" OpportunityEO.Total_Amount ");
                stringbuffer.append(searchcriteria6.getConditionOperator());
                stringbuffer.append(":" + bindSequence++);
                bindVariables.add(searchcriteria6.getValue());
            }

        }
        if(renderedVwAttrs.contains("PersonId"))
        {
            stringbuffer1.append(" , as_lead_contacts_all alca, hz_parties cont, hz_relationships hr ");
            if(searchCriteria.containsKey("ASNOpptyLstCtctFirstNm") || searchCriteria.containsKey("ASNOpptyLstCtctLastNm"))
            {
                addWhereClause(" OpportunityEO.lead_id = alca.lead_id ");
                addWhereClause(" OpportunityEO.customer_id = alca.customer_id  ");
                addWhereClause(" alca.primary_contact_flag  = 'Y' ");
                addWhereClause(" alca.contact_party_id = hr.party_id  ");
                addWhereClause(" hr.subject_id = cont.party_id  ");
                addWhereClause(" hr.subject_table_name  = 'HZ_PARTIES' ");
                addWhereClause(" alca.customer_id = hr.object_id ");
                addWhereClause(" hr.object_table_name  = 'HZ_PARTIES' ");
            } else
            {
                addWhereClause(" OpportunityEO.lead_id = alca.lead_id (+)");
                addWhereClause(" OpportunityEO.customer_id = alca.customer_id(+)  ");
                addWhereClause(" alca.primary_contact_flag (+) = 'Y' ");
                addWhereClause(" alca.contact_party_id = hr.party_id(+)  ");
                addWhereClause(" hr.subject_id = cont.party_id (+) ");
                addWhereClause(" hr.subject_table_name (+) = 'HZ_PARTIES' ");
                addWhereClause(" alca.customer_id = hr.object_id(+) ");
                addWhereClause(" hr.object_table_name (+) = 'HZ_PARTIES' ");
            }
        }
        if(searchCriteria.containsKey("ASNOpptyLstCtctFirstNm"))
        {
            ArrayList arraylist28 = (ArrayList)searchCriteria.get("ASNOpptyLstCtctFirstNm");
            int l6 = arraylist28.size();
            for(int l13 = 0; l13 < l6; l13++)
            {
                SearchCriteria searchcriteria27 = (SearchCriteria)arraylist28.get(l13);
                stringbuffer.append(" AND  ");
                stringbuffer.append(" UPPER(cont.person_first_name) ");
                stringbuffer.append(searchcriteria27.getConditionOperator());
                stringbuffer.append(":" + bindSequence++);
                bindVariables.add(((String)searchcriteria27.getValue()).toUpperCase());
            }

        }
        if(searchCriteria.containsKey("ASNOpptyLstCtctLastNm"))
        {
            ArrayList arraylist29 = (ArrayList)searchCriteria.get("ASNOpptyLstCtctLastNm");
            int i7 = arraylist29.size();
            for(int i14 = 0; i14 < i7; i14++)
            {
                SearchCriteria searchcriteria28 = (SearchCriteria)arraylist29.get(i14);
                stringbuffer.append(" AND  ");
                stringbuffer.append(" UPPER(cont.person_last_name) ");
                stringbuffer.append(searchcriteria28.getConditionOperator());
                stringbuffer.append(":" + bindSequence++);
                bindVariables.add(((String)searchcriteria28.getValue()).toUpperCase());
            }

        }
        if(renderedVwAttrs.contains("JobTitle"))
        {
            stringbuffer1.append(" ,  hz_org_contacts hoc  ");
            addWhereClause(" hr.relationship_id = hoc.party_relationship_id (+) ");
        }
        if(renderedVwAttrs.contains("State") || renderedVwAttrs.contains("City") || renderedVwAttrs.contains("Country") || renderedVwAttrs.contains("Province") || renderedVwAttrs.contains("PostalCode") || renderedVwAttrs.contains("EmailAddress") || renderedVwAttrs.contains("FormattedPhone"))
        {
            if(renderedVwAttrs.contains("PersonId"))
            {
                stringbuffer1.append(" ,  hz_parties hcp  ");
            } else
            {
                stringbuffer1.append(" ,  as_lead_contacts_all alca, hz_parties hcp  ");
                addWhereClause("  OpportunityEO.lead_id = alca.lead_id (+) ");
                addWhereClause("  OpportunityEO.customer_id = alca.customer_id (+) ");
                addWhereClause("  alca.primary_contact_flag (+) = 'Y' ");
            }
            addWhereClause("  alca.contact_party_id = hcp.party_id(+) ");
            if(renderedVwAttrs.contains("Country"))
            {
                stringbuffer1.append(" ,fnd_territories_tl ftt ");
                addWhereClause(" hcp.country = ftt.territory_code (+) ");
                addWhereClause(" ftt.language (+) = USERENV('LANG') ");
            }
        }
        if(renderedVwAttrs.contains("Address"))
        {
            if(renderedVwAttrs.contains("PersonId") || renderedVwAttrs.contains("FormattedPhone") || renderedVwAttrs.contains("EmailAddress") || renderedVwAttrs.contains("State") || renderedVwAttrs.contains("City") || renderedVwAttrs.contains("Province") || renderedVwAttrs.contains("PostalCode"))
            {
                stringbuffer1.append(" ,  hz_locations hl, hz_party_sites hps ");
            } else
            {
                stringbuffer1.append(" , as_lead_contacts_all alca, hz_locations hl, hz_party_sites hps ");
                addWhereClause("  OpportunityEO.lead_id = alca.lead_id (+) ");
                addWhereClause("  OpportunityEO.customer_id = alca.customer_id (+) ");
                addWhereClause("  alca.primary_contact_flag (+) = 'Y' ");
            }
            addWhereClause(" alca.contact_party_id = hps.party_id (+) ");
            addWhereClause(" hps.identifying_address_flag(+) = 'Y' ");
            addWhereClause(" hps.location_id = hl.location_id (+) ");
        }
        if(renderedVwAttrs.contains("PartyName") || searchCriteria.containsKey("ASNOpptyLstCustNm"))
        {
            stringbuffer1.append(" ,hz_parties hp ");
            addWhereClause("  OpportunityEO.customer_id = hp.party_id  ");
        }
        if(renderedVwAttrs.contains("CustState") || renderedVwAttrs.contains("CustCity") || renderedVwAttrs.contains("CustCountry") || renderedVwAttrs.contains("CustProvince") || renderedVwAttrs.contains("CustPostalCode") || renderedVwAttrs.contains("CustAddress"))
            if(searchCriteria.containsKey("ASNOpptyLstCustCnty"))
            {
                stringbuffer1.append(" ,hz_locations  hlcust, hz_party_sites hpscust ");
                addWhereClause("  OpportunityEO.address_id = hpscust.party_site_id  ");
                addWhereClause("  hpscust.location_id = hlcust.location_id  ");
                if(renderedVwAttrs.contains("CustCountry"))
                {
                    stringbuffer1.append(" ,fnd_territories_tl fttcust ");
                    addWhereClause(" hlcust.country = fttcust.territory_code  ");
                    addWhereClause(" fttcust.language  = USERENV('LANG') ");
                }
            } else
            {
                stringbuffer1.append(" ,hz_locations  hlcust, hz_party_sites hpscust ");
                addWhereClause("  OpportunityEO.address_id = hpscust.party_site_id(+)  ");
                addWhereClause("  hpscust.location_id = hlcust.location_id(+)  ");
                if(renderedVwAttrs.contains("CustCountry"))
                {
                    stringbuffer1.append(" ,fnd_territories_tl fttcust ");
                    addWhereClause(" hlcust.country = fttcust.territory_code(+)  ");
                    addWhereClause(" fttcust.language(+)  = USERENV('LANG') ");
                }
            }
        if(searchCriteria.containsKey("ASNOpptyLstCustCnty"))
        {
            if(!renderedVwAttrs.contains("CustState") && !renderedVwAttrs.contains("CustCity") && !renderedVwAttrs.contains("CustCountry") && !renderedVwAttrs.contains("CustProvince") && !renderedVwAttrs.contains("CustPostalCode") && !renderedVwAttrs.contains("CustAddress"))
            {
                stringbuffer1.append(" ,hz_locations  hlcust, hz_party_sites hpscust  ");
                addWhereClause("  OpportunityEO.address_id = hpscust.party_site_id  ");
                addWhereClause("  hpscust.location_id = hlcust.location_id  ");
            }
            ArrayList arraylist30 = (ArrayList)searchCriteria.get("ASNOpptyLstCustCnty");
            int j7 = arraylist30.size();
            for(int j14 = 0; j14 < j7; j14++)
            {
                SearchCriteria searchcriteria29 = (SearchCriteria)arraylist30.get(j14);
                stringbuffer.append(" AND  ");
                stringbuffer.append(" hlcust.country ");
                stringbuffer.append(searchcriteria29.getConditionOperator());
                stringbuffer.append(":" + bindSequence++);
                bindVariables.add((String)searchcriteria29.getValue());
            }

        }
        if(renderedVwAttrs.contains("ResourceName"))
        {
            stringbuffer1.append(" ,  jtf_rs_resource_extns_tl jrt ");
            addWhereClause(" OpportunityEO.owner_salesforce_id = jrt.resource_id ");
            addWhereClause(" jrt.language = USERENV('LANG') ");
        }
        if(renderedVwAttrs.contains("CustomerCategory"))
            if(renderedVwAttrs.contains("PartyName"))
            {
                stringbuffer1.append(", fnd_lookup_values  flv ");
                addWhereClause(" hp.category_code = flv.lookup_code (+)");
                addWhereClause(" flv.lookup_type(+) = 'CUSTOMER_CATEGORY' ");
                addWhereClause(" flv.view_application_id (+) = 222 ");
                addWhereClause(" flv.language (+) = USERENV( 'LANG') ");
            } else
            {
                stringbuffer1.append(", hz_parties hp, fnd_lookup_values  flv ");
                addWhereClause(" OpportunityEO.customer_id = hp.party_id ");
                addWhereClause(" hp.category_code = flv.lookup_code (+)");
                addWhereClause(" flv.lookup_type(+) = 'CUSTOMER_CATEGORY' ");
                addWhereClause(" flv.view_application_id (+) = 222 ");
                addWhereClause(" flv.language (+) = USERENV( 'LANG') ");
            }
        if(renderedVwAttrs.contains("AssignmentStatusNm"))
            if(searchCriteria.containsKey("ASNOpptyLstAssgnStatCode"))
            {
                stringbuffer1.append(" ,  pv_lead_workflows pvwk, pv_lookups pvlkp ");
                addWhereClause(" OpportunityEO.Lead_Id = pvwk.Lead_Id  ");
                addWhereClause(" pvwk.LATEST_ROUTING_FLAG = 'Y' ");
                addWhereClause(" pvwk.routing_status = pvlkp.lookup_code ");
                addWhereClause(" pvlkp. lookup_type = 'PV_ROUTING_STAGE'  ");
            } else
            {
                stringbuffer1.append(" ,  pv_lead_workflows pvwk, pv_lookups pvlkp ");
                addWhereClause(" OpportunityEO.Lead_Id = pvwk.Lead_Id(+)  ");
                addWhereClause(" pvwk.LATEST_ROUTING_FLAG(+) = 'Y' ");
                addWhereClause(" pvwk.routing_status = pvlkp.lookup_code(+) ");
                addWhereClause(" pvlkp. lookup_type(+) = 'PV_ROUTING_STAGE' ");
            }
        if(searchCriteria.containsKey("ASNOpptyLstAssgnStatCode"))
        {
            ArrayList arraylist31 = (ArrayList)searchCriteria.get("ASNOpptyLstAssgnStatCode");
            if(!renderedVwAttrs.contains("AssignmentStatusNm"))
            {
                stringbuffer1.append(" ,  pv_lead_workflows pvwk, pv_lookups pvlkp ");
                addWhereClause(" OpportunityEO.Lead_Id = pvwk.Lead_Id  ");
                addWhereClause(" pvwk.LATEST_ROUTING_FLAG = 'Y' ");
                addWhereClause(" pvwk.routing_status = pvlkp.lookup_code ");
                addWhereClause(" pvlkp. lookup_type = 'PV_ROUTING_STAGE'  ");
            }
            int k7 = arraylist31.size();
            for(int k14 = 0; k14 < k7; k14++)
            {
                SearchCriteria searchcriteria30 = (SearchCriteria)arraylist31.get(k14);
                stringbuffer.append(" AND  ");
                stringbuffer.append("  pvwk.routing_status  ");
                stringbuffer.append(searchcriteria30.getConditionOperator());
                stringbuffer.append(":" + bindSequence++);
                bindVariables.add(searchcriteria30.getValue());
            }

        }
        if(searchCriteria.containsKey("ASNOpptyLstFrcstAmt"))
        {
            ArrayList arraylist32 = (ArrayList)searchCriteria.get("ASNOpptyLstFrcstAmt");
            int l7 = arraylist32.size();
            for(int l14 = 0; l14 < l7; l14++)
            {
                SearchCriteria searchcriteria31 = (SearchCriteria)arraylist32.get(l14);
                stringbuffer.append(" AND  ");
                stringbuffer.append(" OpportunityEO.Total_revenue_opp_forecast_Amt ");
                stringbuffer.append(searchcriteria31.getConditionOperator());
                stringbuffer.append(":" + bindSequence++);
                bindVariables.add(searchcriteria31.getValue());
            }

        }
        if(searchCriteria.containsKey("ASNOpptyLstRefCode"))
        {
            ArrayList arraylist33 = (ArrayList)searchCriteria.get("ASNOpptyLstRefCode");
            int i8 = arraylist33.size();
            for(int i15 = 0; i15 < i8; i15++)
            {
                SearchCriteria searchcriteria32 = (SearchCriteria)arraylist33.get(i15);
                stringbuffer.append(" AND  ");
                stringbuffer.append(" UPPER(OpportunityEO.prm_referral_code)  ");
                stringbuffer.append(searchcriteria32.getConditionOperator());
                stringbuffer.append(":" + bindSequence++);
                bindVariables.add(((String)searchcriteria32.getValue()).toUpperCase());
            }

        }
        if(searchCriteria.containsKey("ASNOpptyLstFrcstOwnId"))
        {
            ArrayList arraylist34 = (ArrayList)searchCriteria.get("ASNOpptyLstFrcstOwnId");
            int j8 = arraylist34.size();
            for(int j15 = 0; j15 < j8; j15++)
            {
                SearchCriteria searchcriteria33 = (SearchCriteria)arraylist34.get(j15);
                stringbuffer.append(" and OpportunityEO.Lead_Id IN ");
                stringbuffer.append(" (SELECT LEAD_ID FROM as_sales_credits slscrd ");
                stringbuffer.append("  WHERE OpportunityEO.Lead_Id = slscrd.Lead_Id ");
                stringbuffer.append("  and slscrd.credit_type_id = ");
                stringbuffer.append(":" + bindSequence++);
                bindVariables.add(number7);
                stringbuffer.append(" and slscrd.salesforce_id = ");
                stringbuffer.append(":" + bindSequence++);
                bindVariables.add(searchcriteria33.getValue());
                stringbuffer.append(" ) ");
            }

        }

		 //Vasan , 01/06/2011
     //Added Store Number Search
      if(searchCriteria.containsKey("ASNOpptyStoreNo"))
      {
        ArrayList searchValues = (ArrayList)searchCriteria.get("ASNOpptyStoreNo");
        int size =  searchValues.size();
        SearchCriteria srchCtaObj = null;
        String StoreNum;
        if (size > 0)
        {
          srchCtaObj =(SearchCriteria)searchValues.get(0);
          if ((((String)srchCtaObj.getConditionOperator()).trim()).equals("<>"))
          {
            StoreNum = (String)srchCtaObj.getValue();
            stringbuffer.append(" AND ");
            stringbuffer.append(" OpportunityEO.Attribute4 <> '");
            stringbuffer.append(StoreNum);
            stringbuffer.append("' ");
          }
          else
          {
            StoreNum = (String)srchCtaObj.getValue();
            stringbuffer.append(" AND ");
            stringbuffer.append(" OpportunityEO.Attribute4 = '");
            stringbuffer.append(StoreNum);
            stringbuffer.append("' ");
          }
        }
      }
     oadbtransaction.writeDiagnostics( "==>Vasan ", stringbuffer.toString(), 1);     
     
     
     //End of Change by Vasan


        if(renderedVwAttrs.contains("CloseReason"))
            if(searchCriteria.containsKey("ASNOpptyLstClsRsnCode"))
            {
                stringbuffer1.append(" ,  fnd_lookup_values rsn ");
                addWhereClause(" OpportunityEO.CLOSE_REASON = rsn.lookup_code ");
                addWhereClause(" rsn.language = USERENV('LANG') ");
                addWhereClause(" rsn.lookup_type = 'ASN_OPPTY_CLOSE_REASON' ");
                addWhereClause(" rsn.view_application_id = 0 ");
            } else
            {
                stringbuffer1.append(" ,  fnd_lookup_values rsn ");
                addWhereClause(" OpportunityEO.CLOSE_REASON = rsn.lookup_code(+) ");
                addWhereClause(" rsn.language(+) = USERENV('LANG') ");
                addWhereClause(" rsn.lookup_type(+) = 'ASN_OPPTY_CLOSE_REASON' ");
                addWhereClause(" rsn.view_application_id(+) = 0 ");
            }
        if(searchCriteria.containsKey("ASNOpptyLstClsRsnCode"))
        {
            ArrayList arraylist35 = (ArrayList)searchCriteria.get("ASNOpptyLstClsRsnCode");
            int k8 = arraylist35.size();
            for(int k15 = 0; k15 < k8; k15++)
            {
                SearchCriteria searchcriteria34 = (SearchCriteria)arraylist35.get(k15);
                stringbuffer.append(" AND  ");
                stringbuffer.append(" OpportunityEO.CLOSE_REASON ");
                stringbuffer.append(searchcriteria34.getConditionOperator());
                stringbuffer.append(":" + bindSequence++);
                bindVariables.add(searchcriteria34.getValue());
            }

        }
        if(renderedVwAttrs.contains("OpptyUpdatedBy"))
        {
            stringbuffer1.append(" ,  fnd_user fuup ");
            addWhereClause(" OpportunityEO.last_updated_by = fuup.user_id ");
        }
        if(renderedVwAttrs.contains("OpptyCreatedBy"))
        {
            stringbuffer1.append(" ,  fnd_user fucr ");
            addWhereClause(" OpportunityEO.created_by = fucr.user_id ");
        }
        fromClause = stringbuffer1.toString();
        filterClause = stringbuffer.toString();
        fromClause = fromClause.trim();
        if(fromClause.endsWith(","))
            fromClause = fromClause.substring(0, fromClause.length() - 1);
        whereClause.append(" ");
        whereClause.append(filterClause);
        if(whereClause.toString().trim().startsWith("AND "))
        {
            FinalwhereClause = whereClause.toString().trim().substring(3);
            return;
        } else
        {
            FinalwhereClause = whereClause.toString().trim();
            return;
        }
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

    public void getOpptyUwqRefreshVO(OAApplicationModuleImpl oaapplicationmoduleimpl, ArrayList arraylist, Number number)
    {
        OAViewObjectImpl _tmp = (OAViewObjectImpl)oaapplicationmoduleimpl.findViewObject("OpptySearchVO2");
        OAViewObjectImpl oaviewobjectimpl = (OAViewObjectImpl)oaapplicationmoduleimpl.findViewObject("OpptySearchVO2");
        renderedVwAttrs = arraylist;
        adddefSelectColumns();
        Refresh = true;
        constructSelectClause(oaviewobjectimpl);
        String s = "asn.opportunity.server.OpptySearchManager.getOpptyUwqRefreshVO";
        OADBTransaction oadbtransaction = oaapplicationmoduleimpl.getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(1);
        HashMap hashmap = null;
        HashMap hashmap1 = null;
        constructFromWhereClause(oaapplicationmoduleimpl, hashmap1, hashmap);
        if(flag)
        {
            StringBuffer stringbuffer = (new StringBuffer(500)).append(" ==== Input Parameters ====").append("Display Param = ").append(renderedVwAttrs).append("SelectClause = ").append(selectClause).append("From Clause = ").append(fromClause).append("Where Clause = ").append(FinalwhereClause).append("Bind variables = ").append(bindVariables);
            oadbtransaction.writeDiagnostics(s, stringbuffer.toString(), 1);
        }
        StringBuffer stringbuffer1 = new StringBuffer(200);
        stringbuffer1.append("SELECT ");
        stringbuffer1.append(selectClause);
        stringbuffer1.append(" ");
        stringbuffer1.append(fromClause);
        stringbuffer1.append(" ");
        stringbuffer1.append(FinalwhereClause);
        stringbuffer1.append(" AND OpportunityEO.lead_id = ");
        stringbuffer1.append(":" + bindSequence++);
        bindVariables.add(number);
        stringbuffer1.append(" ");
        Serializable aserializable[] = {
            stringbuffer1.toString()
        };
//Mohan
            oadbtransaction.writeDiagnostics("===>> Mohan Final Select: ", stringbuffer1.toString(), 1);

        oaviewobjectimpl.setOrderByClause(null);
        oaviewobjectimpl.invokeMethod("setQuery", aserializable);
        oaviewobjectimpl.getQuery();
        oaviewobjectimpl.setWhereClauseParams(null);
        if(bindVariables != null && bindVariables.size() > 0)
        {
            for(int i = 0; i < bindVariables.size(); i++)
                oaviewobjectimpl.setWhereClauseParam(i, bindVariables.get(i));

        }
    }

    private void adddefSelectColumns()
    {
        if(renderedVwAttrs.contains("ContactName") || renderedVwAttrs.contains("PersonFirstName") || renderedVwAttrs.contains("JobTitle") || renderedVwAttrs.contains("PersonLastName") || renderedVwAttrs.contains("PersonMiddleName") || renderedVwAttrs.contains("Salutation") || searchCriteria.containsKey("ASNOpptyLstCtctFirstNm") || searchCriteria.containsKey("ASNOpptyLstCtctLastNm"))
        {
            renderedVwAttrs.add("PersonId");
            renderedVwAttrs.add("PrimaryContactPartyId");
            renderedVwAttrs.add("RelationShipId");
        }
    }

    public HashMap checkPerioddate(OAApplicationModule oaapplicationmodule, String s)
    {
        OpportunityCurrPeriodRangeVOImpl opportunitycurrperiodrangevoimpl = null;
        Object obj = null;
        HashMap hashmap = new HashMap();
        if(s != null)
        {
            String s1 = "OpportunityCurrPeriodRangeVO";
            opportunitycurrperiodrangevoimpl = (OpportunityCurrPeriodRangeVOImpl)oaapplicationmodule.findViewObject("OpportunityCurrPeriodRangeVO");
            if(opportunitycurrperiodrangevoimpl == null)
            {
                MessageToken amessagetoken[] = {
                    new MessageToken("NAME", s1)
                };
                throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
            }
            opportunitycurrperiodrangevoimpl.initQuery(s);
        }
        if(opportunitycurrperiodrangevoimpl.hasNext())
        {
            ASNViewRowImpl asnviewrowimpl = (ASNViewRowImpl)opportunitycurrperiodrangevoimpl.first();
            if(asnviewrowimpl != null)
            {
                Date date = (Date)asnviewrowimpl.getAttribute("StartDate");
                Date date1 = (Date)asnviewrowimpl.getAttribute("EndDate");
                hashmap.put("StartDate", date);
                hashmap.put("EndDate", date1);
            }
        }
        return hashmap;
    }

    public static final String RCS_ID = "$Header: OpptySearchManager.java 115.80.115200.5 2005/10/20 21:34:22 lgupta ship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: OpptySearchManager.java 115.80.115200.5 2005/10/20 21:34:22 lgupta ship $", "oracle.apps.asn.opportunity.server");
    private String selectClause;
    private String filterClause;
    private boolean Refresh;
    protected StringBuffer whereClause;
    private String FinalwhereClause;
    private String fromClause;
    private String orderByClause;
    private ArrayList renderedVwAttrs;
    private HashMap searchCriteria;
    private ArrayList sortColumns;
    private ArrayList sortSequence;
    private ArrayList bindVariables;
    private ArrayList ASNMgrGrpIds;
    private ArrayList ASNAdminGrpIds;
    private ArrayList ASNStdAlnMmbrGrpIds;
    private String ASNMgrFlag;
    private String accessType;
    private int bindSequence;

}
