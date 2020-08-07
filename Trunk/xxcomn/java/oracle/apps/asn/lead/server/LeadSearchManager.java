/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             LeadSearchManager.java                                        |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Performance tuning done to the base product SQL                        |
 |                                                                           |
 |  NOTES                                                                    |
 |    Hint added to the standard query executed from the Lead Search Page    |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    No dependencies.                                                       |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    23-Jan-2008 Jasmine Sujithra   Created                                 |
 |    01-Feb-2008 Jasmine Sujithra   Restricted rows returned to 200         |
 |    12-Feb-2008 Jasmine Sujithra   Get Max Row count from Profile          |
 |    15-Oct-2008 Mohan Kalyanasundaram Modified forDefect 11919 Lead        |
 |      Search showing Opportunities                                         |
 +===========================================================================*/


package oracle.apps.asn.lead.server;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import java.lang.String;

import java.util.Dictionary;
import java.util.StringTokenizer;

import oracle.apps.asn.common.schema.server.ASNUtil;
import oracle.apps.asn.common.server.SearchCriteria;
import oracle.apps.asn.common.server.SearchManager;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.AttributeDef;
import oracle.jbo.domain.Number;
import oracle.jbo.server.ViewAttributeDefImpl;
import oracle.jbo.server.ViewDefImpl;

import oracle.jbo.domain.Date;

public class LeadSearchManager extends SearchManager
{

 /**
  * Oracle Applications internal source control identifier.
  */
  public static final String RCS_ID="$Header: LeadSearchManager.java 115.72.115200.5 2005/10/20 07:39:18 pchalaga ship $";

 /**
  * Oracle Applications internal source control identifier.
  */
  public static final boolean RCS_ID_RECORDED =
    VersionInfo.recordClassVersion(RCS_ID, "oracle.apps.asn.lead.server");

    // Start of Member Variables:
    /**  Represents SELECT clause **/
    private String selectClause;
   
      /**  Represents JOIN part of the WHERE clause **/
    private String joinClause;
   
      /**  Represents JOIN part of the SECURITY WHERE clause **/
    private String securityJoinClause;

      /**  Represents FILTER part of the WHERE clause **/
    private String filterClause;

      /**  Represents FILTER part of the SECURITY WHERE clause **/
    private String securityFilterClause;
   
      /**  Represents WHERE (JOIN + FILTER) clause **/
   private String whereClause;
   
      /**  Represents WHERE (JOIN + FILTER) of SECURITY clause **/
   private String securityWhereClause;

      /**  Represents FROM clause **/
    private String fromClause;
   
      /**  Represents ORDER BY clause **/
    private String orderByClause;
   
      /**  Represents ArrayList of rendered view attributes/display columns **/
    private ArrayList renderedVwAttrs  = new ArrayList(30);
   
      /**  Represents HashMap of SearchCriteria objects (in ArrayList) **/
    private HashMap searchCriteria = new HashMap(15);
   
      /**  Represents Sort columns of the query **/
    private ArrayList sortColumns = new ArrayList(10);
   
      /**  Represents Sort sequence of the query **/
    private ArrayList sortSequence = new ArrayList(10);
   
      /**  Represents list of bind variables of the query **/
    private ArrayList bindVariables = new ArrayList(10);
   
      /**  Represents the bind sequence of the query **/
    private int bindSequence;
   
      /** Value of the Time Zone Id **/
    private Number serverTimeZoneId;

      /** Value of the Default Lead Status **/
    private String defaultLeadStatus;

      /** Value of the Lead Access used for Full Access  **/
    private  String accessType;

    /**  Represents list of groups for manager **/
    private ArrayList ASNMgrGrpIds = new ArrayList(15);

    /**  Represents list of groups for Admin **/
    private ArrayList ASNAdmnGrpIds = new ArrayList(15);

    /**  Represents list of groups where logged in user is Only a Salesrep**/
    private ArrayList ASNStdAlnMmbrGrpIds = new ArrayList(15);

    /**  Represents list of Created Dates that use a From Range (>=) **/
    private ArrayList LeadCreationDateFromRange = new ArrayList(15);

    /**  Represents list of Created Dates that use a To Range (<=) **/
    private ArrayList LeadCreationDateToRange = new ArrayList(15);

    /**  Represents list of Created Dates that use an Equal Range (=) **/
    private ArrayList LeadCreationDateEqualsRange = new ArrayList(15);

    // Manager Related Variables
    // Indicates whether the resource is a manager/admin. Y/N
    // This wil be used only while building the Select Clause and nowhere else
    private String selectASNMgrFlag;

    /**  Represents IF the flow is for REFRESH Row **/
    // private static String Refresh;
     private boolean Refresh = false;

  /* bind  variables for the sql */
  private int  i = 1;

 /**
  *  default constructor
  */

  public LeadSearchManager()
  {
  }

  //    Method Name: setViewQuery ( )
  //     Description: Builds the SQL query based on various criteria and 
  //    sets it to the LeadSearchVO Method Logic:
   public void setViewQuery( OAApplicationModule oam,
                             Dictionary[] crtiteriaDicts, 
                             ArrayList mRenderedVwAttrs,
                             HashMap dshBdSrchParams, 
                             HashMap miscSrchParams,
                             boolean defaultSort
                           )
   {  
    // get the LeadSearchVO
    OAViewObjectImpl leadsVo = (OAViewObjectImpl)oam.findViewObject("LeadSearchVO");
    OADBTransaction trxn = oam.getOADBTransaction();
    
    /* Modified to get the Maximum number of rows to be displayed from a profile */
    String maxLeadRows = (String)trxn.getProfile("XX_ASN_MAX_LEAD_ROWS");
    if(maxLeadRows == null || "".equals(maxLeadRows))
    {
       maxLeadRows = "200";
    }
     
    
    renderedVwAttrs = mRenderedVwAttrs;

     // set the sort settings
    setSortSettings(leadsVo, defaultSort);
   
     // get the server time zone id
    String  sTimeZoneId = trxn.getProfile("SERVER_TIMEZONE_ID");

    MessageToken[] messageToken5 = { new MessageToken("IDNAME",sTimeZoneId)};
    serverTimeZoneId = ASNUtil.stringToJboNumber(sTimeZoneId, "ASN_CMMN_STR_TO_JBONUM_ERR", messageToken5);
      
     // get the Default Lead Status from the Profile ASN_DEFAULT_LEAD_STATUS
    defaultLeadStatus = trxn.getProfile("ASN_DEFAULT_LEAD_STATUS");

      // Manager Related Variables
      // Indicates whether the resource is a manager/admin. Y/N
      selectASNMgrFlag = (String)miscSrchParams.get("ASNMgrFlag");
    
     // set the search criteria into arraylist
    setSearchCriteria(crtiteriaDicts);

     // build the SELECT clause
    constructSelectClause(leadsVo);
      
    Refresh = false;

     // build the FROM and WHERE clause
    constructFromWhereClause(   oam,
                                dshBdSrchParams, 
                                 miscSrchParams
                                );

    final String METHOD_NAME = "asn.lead.server.LeadSearchManager.setViewQuery";
    boolean isProcLogEnabled = trxn.isLoggingEnabled(OAFwkConstants.PROCEDURE);
   
    String finalSql = null;

    // Check if Hint has to be added
    // selectHint comes from SearchManager depending on security logic
    if(selectHint != null )
    {
      finalSql = " SELECT " + selectHint +" " + selectClause;
    }
    else
    {
      //finalSql = "SELECT " + "/*+ Index(secu XX_TM_NAM_TERR_RSC_N1) USE_NL(hpobj,cont,hcp,hpscust,hps,LeadEO,ast,aslrt,hr,hcplt,ht,hlcust,hl,fttcust) */  " +" " +selectClause;
     finalSql = "SELECT " + selectClause;
    }
    
    // String finalSql = "SELECT " + selectClause;
    finalSql = finalSql + " FROM " + fromClause;
    finalSql = finalSql + " WHERE " + whereClause +" AND ROWNUM <= "+maxLeadRows + " AND 1=1 " ;
    //finalSql = finalSql + " " + orderByClause;

    // Logging Start
    if (isProcLogEnabled)
    {
     StringBuffer  logBuf = new StringBuffer(500)
                           .append(" ==== Final SQL Query ====")
                           .append("Query is " ).append(finalSql);
                           
     trxn.writeDiagnostics(METHOD_NAME,  logBuf.toString(), OAFwkConstants.PROCEDURE);
    }
    // Logging End

    //leadsVo.setOrderByClause(null);

     // set the query to the view object
   leadsVo.setQuery(finalSql);
    leadsVo.setFullSqlMode(OAViewObjectImpl.FULLSQL_MODE_AUGMENTATION);

      // bind the varaibles

    leadsVo.setWhereClauseParams(null);

    if(bindVariables!= null && bindVariables.size() > 0)
    {
      for  (int i = 0; i < bindVariables.size(); i++)
      {
        leadsVo.setWhereClauseParam(i, bindVariables.get(i));
      }
    }

  }

  // Method Name: setSortSettings ( )
  // Description: Determines the sort columns and 
  // sequence based on ORDER BY clause associated with 
  // the LeadSearchVO object Method Logic:
   public void setSortSettings(OAViewObjectImpl leadsVo, boolean defaultSort)
   {
    String ordByClause = null;
    StringBuffer orderByBfr = new StringBuffer(50);

    // determine the sort setting from view object
    if (!defaultSort)
    {
      // get the oder by clause from view object LeadSearchVO
      ordByClause = leadsVo.getOrderByClause();

      //Check if the View Order by clause is Null, If so, append default order by
      if (ordByClause==null || "".equals(ordByClause.trim()))
      {
        sortColumns.add("Age"); 
        sortSequence.add("ASC"); 
        orderByBfr.append(" ORDER BY Age ASC ");
      }
      else
      {
        // tokenize the string to get the attribute names and their sequence
        // e.g. "DESCRIPTION ASC, AGE DESC"
        StringTokenizer stk = new StringTokenizer(ordByClause, ",");

        while(stk.hasMoreTokens())
        {
          String token = stk.nextToken();

          // tokenize the attribute name and order sequence 
          // e.g. "DESCRIPTION ASC"
          StringTokenizer stk1 = new StringTokenizer(token, " ");
          String vwSortAttrName = stk1.nextToken(); // e.g. "DESCRIPTION"
          String vwSortSeq = null;

          if (stk1.hasMoreTokens())
          {
            vwSortSeq = stk1.nextToken();  // e.g. "ASC"
          }
          else
          {
            vwSortSeq = "";
          }
          
          // get the corresponding view attribute name for the sort attribute
          String  vwAttrName = getViewAttributeName(leadsVo, vwSortAttrName);
          // add to the sort column list
          sortColumns.add(vwAttrName); 
          sortSequence.add(vwSortSeq);
        } // end-while
      } //end-else
    } // else-default sort
    else
    {
      sortColumns.add("Age"); 
      sortSequence.add("ASC"); 
      orderByBfr.append(" ORDER BY Age ASC ");
    } 
  
    if(orderByBfr !=null)
    {
      orderByClause = orderByBfr.toString();
    }
   }


  //  Method Name: getViewAttributeName ( )
  //  Description: Gets the view attribute name of the LeadSearchVO for the 
  //  given query column name Method Logic:

  private String getViewAttributeName(OAViewObjectImpl leadsVo, String attrName)
   {  
     // get the view definition of LeadSearchVO
    ViewDefImpl leadsVoDef = (ViewDefImpl)leadsVo.getViewDefinition();
    ViewAttributeDefImpl voAttrDef = null;
   
    // get the attribute definitions of LeadSearchVO
    AttributeDef[] voAttrDefs = leadsVoDef.getAttributeDefs();
   
     // get the view attribute count
    int voAttrDefCount = leadsVoDef.getAttributeCount();
   
    // loop thru the view attributes
    if(voAttrDefs!=null)
    {
      String voAttrName = null;
      int size = voAttrDefs.length;
      for(int i=0; i<size; i++)
      {
        // get the view attribute definition
         voAttrDef = (ViewAttributeDefImpl)voAttrDefs[i];
                
         if(attrName.equals(voAttrDef.getColumnNameForQuery()))
         {
          // get the view attribute name
           voAttrName = voAttrDef.getName();
           return voAttrName;
         }
      }
    }
    return null;
  }

  // Method Name: constructSelectClause ( )
  // Description: Constructs the SELECT clause part of the SQL query based on the rendered attributes. 
  // For ease of implementation, lead entity based column are always selected in SELECT clause no matter
  // whether they are displayed or not.
  // Method Logic:

   public void constructSelectClause(OAViewObjectImpl leadsVo)
   {     
    StringBuffer selectBfr = new StringBuffer(50);
   
    // Add default columns to the renderedVwAttrs;
    if(renderedVwAttrs==null)
    {
      renderedVwAttrs = new ArrayList(20);
    }
   
    // Add SalesLeadId, CustomerId, PrimaryContactPartyId 
    renderedVwAttrs.add("SalesLeadId");
    renderedVwAttrs.add("CustomerId");
    renderedVwAttrs.add("CurrencyCode");
   
    // Add conditional identifier columns 
    if( renderedVwAttrs.contains("ContactName")||
        renderedVwAttrs.contains("PersonFirstName")||
        renderedVwAttrs.contains("JobTitle")||
        renderedVwAttrs.contains("PersonLastName")||
        renderedVwAttrs.contains("PersonMiddleName")||
        renderedVwAttrs.contains("Salutation")||
        searchCriteria.containsKey("ASNLeadLstCtctFstNm")||
        searchCriteria.containsKey("ASNLeadLstCtctLstNm")
      )
    {
      renderedVwAttrs.add("PersonId");
      renderedVwAttrs.add("PrimaryContactPartyId");
      renderedVwAttrs.add("RelationshipId");
    }
   
     // Add SortColumns to the rendered attributes 
     // Add SortColumns to the rendered attributes 
    for (int i = 0; i < sortColumns.size(); i++)
   {
      renderedVwAttrs.add(sortColumns.get(i));
    }

     // get the view definition of LeadSearchVO
    // LeadSearchVOImpl leadsVoDef = (LeadSearchVOImpl)leadsVo.getViewDefinition();
   ViewDefImpl leadsVoDef = leadsVo.getViewDefinition();
      
    ViewAttributeDefImpl voAttrDef = null;
   
     // get the attribute definitions of LeadSearchVO
    AttributeDef[] voAttrDefs = leadsVoDef.getAttributeDefs();
   
     // get the view attribute count
    int voAttrDefCount = leadsVoDef.getAttributeCount();
   
     // loop thru the view attributes, as the same sequence needs to be maintained in 
     // SELECT clause
    if(voAttrDefs!=null)
    {
      String voAttrName = null;
      int size = voAttrDefs.length;
      for(int i=0; i<size; i++)
      {
        // get the view attribute definition
         voAttrDef = (ViewAttributeDefImpl)voAttrDefs[i];

         // get the view attribute name
         voAttrName = voAttrDef.getName();
      
         // do not include "SelectFlag" in SELECT clause      
         if("SelectFlag".equals(voAttrName)) 

         {
          continue;
         }
   
        // query EO attributes always 
         if("SalesLeadId".equals(voAttrName))
         {
          selectBfr.append("LeadEO.sales_lead_id ,  ");
           continue;
         }
         else if("Description".equals(voAttrName))
         {
           selectBfr.append("SUBSTRB(LeadEO.description, 1,240) as Description,  ");
           continue;
         }
         else if("CustomerId".equals(voAttrName))
         {
           selectBfr.append("LeadEO.customer_id ,  ");
           continue;
         }
         else if("PrimaryContactPartyId".equals(voAttrName))
         {
           selectBfr.append("LeadEO.primary_contact_party_id ,  ");
           continue;
         }
         else if("LeadNumber".equals(voAttrName))
         {
           selectBfr.append("LeadEO.lead_number , ");
           continue;
         }
         else if("LastUpdateDate".equals(voAttrName))
         {
           selectBfr.append("LeadEO.last_update_date , ");
           continue;
         }
         else if("CreationDate".equals(voAttrName))
         {
           selectBfr.append("LeadEO.creation_date , ");
           continue;
         }
         else if("BudgetAmount".equals(voAttrName))
         {
           selectBfr.append("LeadEO.budget_amount , ");
           continue;
         }
         else if("CurrencyCode".equals(voAttrName))
         {
           selectBfr.append("LeadEO.currency_code , ");
           continue;
         }

         else if("Age".equals(voAttrName))
         {
              // query always 
           selectBfr.append("CEIL(SYSDATE - LeadEO.creation_date) as Age,  ");
           continue;
         }

        // Non EO based Columns
         else if("LeadStatus".equals(voAttrName))
         {
          // check whether the attribute is displayable 
          if(renderedVwAttrs.contains(voAttrName))
           { 
             selectBfr.append("ast.meaning as LeadStatus, ");
           }
           else // not displayable
           {
             selectBfr.append("null as LeadStatus,  ");           
           }   
           continue;
        }
         else if("RankName".equals(voAttrName))
         {
          // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
            if("Y".equals(selectASNMgrFlag))
            {
              // In case of manager, we always have the search criteria as mandatory
              if(searchCriteria.containsKey("ASNLeadLstRank"))
              {
                ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstRank");
                int ranksize =  searchValues.size();
                for ( int j = 0; j < ranksize; j++)
                {
                  SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(j);
                  // Get the Value in the Search Criteria Object
                  String rankRangeScore = (String)srchCtaObj.getValue();

                  if (rankRangeScore != null &&  "-999".equals(rankRangeScore))
                  {
                    selectBfr.append("null as RankName,  ");
                  }
                  else
                  {
                    selectBfr.append("aslrt.meaning as RankName, ");
                  }
                } //end loop
              }
              else
              {
                selectBfr.append("aslrt.meaning as RankName, ");
              }
            }
            else
            {
            selectBfr.append("aslrt.meaning as RankName, ");
            }
           }
           else // not displayable
           {
             selectBfr.append("null as RankName,  ");           
           }   
           continue;
        }
         else if("CurrencyName".equals(voAttrName))
         {
          // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
            selectBfr.append("fnt.name as CurrencyName, ");
           }
           else // not displayable
           {
             selectBfr.append("null as CurrencyName,  ");           
           }   
           continue;
         }
         else if("CustomerName".equals(voAttrName))
         {
           // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
             selectBfr.append("hpobj.party_name as CustomerName, ");
           }
           else // not displayable
           {
            selectBfr.append("null as CustomerName,  ");           
           }   
           continue;
        }
         else if("SourceSystem".equals(voAttrName))
         {
          // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
            selectBfr.append("srcsys.meaning as SourceSystem, ");
           }
           else // not displayable
           {
             selectBfr.append("null as SourceSystem,  ");           
           }   
           continue;
         }
         else if("PersonId".equals(voAttrName))
         {
           // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
            selectBfr.append("cont.party_id as PersonId, ");
           }
           else // not displayable
           {
            selectBfr.append("null as PersonId,  ");           
           }   
           continue;
         }
         else if("ContactName".equals(voAttrName))
         {
          // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
            selectBfr.append("cont.party_name as ContactName, ");
           }
           else // not displayable
           {
            selectBfr.append("null as ContactName,  ");           
           }  
           continue;
        }
         else if("ContactLocalTime".equals(voAttrName))
         {
          // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
            selectBfr.append("DECODE (hcplt.timezone_id, NULL, NULL,  ");

            selectBfr.append("to_char(hz_timezone_pub.convert_datetime(:");
            selectBfr.append(bindSequence++);
            selectBfr.append(", hcplt.timezone_id, SYSDATE), 'HH:MI AM') ");
            selectBfr.append(" || ' '||ht.standard_time_short_code ) as ContactLocalTime, ");
            bindVariables.add(serverTimeZoneId);
           }
           else // not displayable
           {
             selectBfr.append("null as ContactLocalTime,  ");           
           }   
           continue;
         }
         else if("EmailAddress".equals(voAttrName))
         {
           // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
            selectBfr.append("hcp.email_address as EmailAddress, ");
           }
           else // not displayable
           {
             selectBfr.append("null as EmailAddress,  ");           
           }   
           continue;
         }
         else if("RelationshipId".equals(voAttrName))
         {
          // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
            selectBfr.append("hr.relationship_id as RelationshipId, ");
           }
           else // not displayable
           {
             selectBfr.append("null as RelationshipId,  ");           
           }   
           continue;
         }

         else if("ResourceName".equals(voAttrName))
         {
           // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
             selectBfr.append("jrt.resource_name as ResourceName, ");
           }
           else // not displayable
           {
             selectBfr.append("null as ResourceName,  ");           
           }   
           continue;
         }

         else if("Methodology".equals(voAttrName))
         {
           // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
             selectBfr.append("asmt.sales_methodology_name as Methodology, ");
           }
           else // not displayable
           {
             selectBfr.append("null as Methodology,  ");           
           }   
           continue;
         }

         else if("Stage".equals(voAttrName))
         {
           // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
             selectBfr.append("assat.name as Stage, ");
           }
           else // not displayable
           {
             selectBfr.append("null as Stage,  ");           
           }   
           continue;
         }

         else if("SalesChannel".equals(voAttrName))
         {
          // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
            if("Y".equals(selectASNMgrFlag))
            {
              // In case of manager, we always have the search criteria as mandatory
              if(searchCriteria.containsKey("ASNLeadLstChnl"))
              {
                ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstChnl");
                int channelsize =  searchValues.size();
                for ( int j = 0; j < channelsize; j++)
                {
                  SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(j);
                  // Get the Value in the Search Criteria Object
                  String channelValue = (String)srchCtaObj.getValue();

                  if (channelValue != null &&  "-999".equals(channelValue))
                  {
                   selectBfr.append("null as SalesChannel,  ");           
                  }
                  else
                  {
                   selectBfr.append("chnl.meaning as SalesChannel, ");
                  }
                } //end loop
              }
              else
              {
                selectBfr.append("chnl.meaning as SalesChannel, ");                
              }
            }
            else
            {
             selectBfr.append("chnl.meaning as SalesChannel, ");
            }
           }
           else // not displayable
           {
            selectBfr.append("null as SalesChannel,  ");           
           }   
           continue;
        }

         else if("ResponseChannel".equals(voAttrName))
         {
           // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
             selectBfr.append("rspchnl.meaning as ResponseChannel, ");
           }
           else // not displayable
           {
             selectBfr.append("null as ResponseChannel,  ");
           }   
           continue;
         }

         else if("CloseReason".equals(voAttrName))
         {
           // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
             selectBfr.append("clsrsn.meaning as CloseReason, ");
           }
           else // not displayable
           {
             selectBfr.append("null as CloseReason,  ");
           }   
           continue;
         }

         else if("LeadCreatedBy".equals(voAttrName))
         {
           // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
             selectBfr.append("fucr.user_name as LeadCreatedBy, ");
           }
           else // not displayable
           {
             selectBfr.append("null as LeadCreatedBy,  ");
           }   
           continue;
         }

         else if("LeadUpdatedBy".equals(voAttrName))
         {
           // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
             selectBfr.append("fuup.user_name as LeadUpdatedBy, ");
           }
           else // not displayable
           {
             selectBfr.append("null as LeadUpdatedBy,  ");
           }   
           continue;
         }

         else if("ContactRole".equals(voAttrName))
         {
           // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
             selectBfr.append("ctrole.meaning as ContactRole, ");
           }
           else // not displayable
           {
             selectBfr.append("null as ContactRole,  ");
           }   
           continue;
         }

         else if("JobTitle".equals(voAttrName))
         {
           // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
             selectBfr.append("hoc.job_title as JobTitle, ");
           }
           else // not displayable
           {
             selectBfr.append("null as JobTitle,  ");
           }   
           continue;
         }

         else if("ContactLocalTimeZone".equals(voAttrName))
         {
           // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
             selectBfr.append("ht.standard_time_short_code as ContactLocalTimeZone, ");
           }
           else // not displayable
           {
             selectBfr.append("null as ContactLocalTimeZone,  ");
           }   
           continue;
         }

         else if("City".equals(voAttrName))
         {
           // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
             selectBfr.append("hcp.city as City, ");
           }
           else // not displayable
           {
             selectBfr.append("null as City,  ");
           }   
           continue;
         }

         else if("State".equals(voAttrName))
         {
           // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
             selectBfr.append("hcp.state as State, ");
           }
           else // not displayable
           {
             selectBfr.append("null as State,  ");           
           }   
           continue;
         }

         else if("Province".equals(voAttrName))
         {
           // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
             selectBfr.append("hcp.province as Province, ");
           }
           else // not displayable
           {
             selectBfr.append("null as Province,  ");
           }   
           continue;
         }

         else if("Country".equals(voAttrName))
         {
           // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
             selectBfr.append("ftt.territory_short_name as Country, ");
           }
           else // not displayable
           {
             selectBfr.append("null as Country,  ");
           }   
           continue;
         }

         else if("PostalCode".equals(voAttrName))
         {
           // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
             selectBfr.append("hcp.postal_code as PostalCode, ");
           }
           else // not displayable
           {
             selectBfr.append("null as PostalCode,  ");
           }   
           continue;
         }

         else if("Address".equals(voAttrName))
         {
           // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
            selectBfr.append("hz_format_pub.format_address( hl.location_id, null, null, ', ', null, null, null, null)  as Address, ");
           }
           else // not displayable
           {
             selectBfr.append("null as Address,  ");           
           }   
           continue;
         }

        // customer details
         else if("CustomerCity".equals(voAttrName))
         {
           // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
             selectBfr.append("hlcust.city as CustomerCity, ");
           }
           else // not displayable
           {
             selectBfr.append("null as CustomerCity,  ");
           }   
           continue;
         }

         else if("CustomerProvince".equals(voAttrName))
         {
           // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
          { 
             selectBfr.append("hlcust.province as CustomerProvince, ");
           }
           else // not displayable
           {
             selectBfr.append("null as CustomerProvince,  ");
           }   
           continue;
         }

         else if("CustomerCountry".equals(voAttrName))
         {
           // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
             selectBfr.append("fttcust.territory_short_name as CustomerCountry, ");
           }
           else // not displayable
           {
             selectBfr.append("null as CustomerCountry,  ");
           }   
           continue;
         }
        
         else if("CustomerPostalCode".equals(voAttrName))
         {
           // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
             selectBfr.append("hlcust.postal_code as CustomerPostalCode, ");
           }
           else // not displayable
           {
             selectBfr.append("null as CustomerPostalCode,  ");
           }   
           continue;
         }

         else if("CustomerState".equals(voAttrName))
         {
           // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
             selectBfr.append("hlcust.state as CustomerState, ");
           }
           else // not displayable
           {
             selectBfr.append("null as CustomerState,  ");           
           }   
           continue;
         }

         else if("CustomerAddress".equals(voAttrName))
         {
           // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
            selectBfr.append("hz_format_pub.format_address( hlcust.location_id, null, null, ', ', null, null, null, null) as CustomerAddress, ");
           }
           else // not displayable
           {
             selectBfr.append("null as CustomerAddress,  ");
           }   
           continue;
         }

        // end customer details

         else if("ASNLeadLstCnvToOppty".equals(voAttrName))
         {
           // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
            selectBfr.append("DECODE (LeadEO.status_code, 'CONVERTED_TO_OPPORTUNITY' , 'ASNCnvToOpptyDsbld', 'ASNCnvToOpptyEnbld') as ASNLeadLstCnvToOppty, ");
           }
           else // not displayable
           {
             selectBfr.append("null as ASNLeadLstCnvToOppty,  ");
           }   
           continue;
         }

         else if("SourceName".equals(voAttrName))
         {
              // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
                  { 
                  selectBfr.append("  DECODE(amsc.arc_source_code_for ,    ");
                  selectBfr.append("'CAMP', (SELECT campaign_name");
                  selectBfr.append(" FROM AMS_CAMPAIGNS_ALL_TL ");
                  selectBfr.append(" WHERE campaign_id = amsc.source_code_for_id ");
                  selectBfr.append(" AND language = USERENV('LANG')), ");
                  selectBfr.append(" 'CSCH', (SELECT schedule_name ");
                  selectBfr.append(" FROM ams_campaign_schedules_tl ");
                  selectBfr.append(" WHERE  schedule_id = amsc.source_code_for_id                 ");
                  selectBfr.append(" AND language = USERENV('LANG')),     ");
                  selectBfr.append(" 'EVEH', (SELECT event_header_name                  ");
                  selectBfr.append(" FROM   AMS_EVENT_HEADERS_ALL_TL               ");
                  selectBfr.append(" WHERE  event_header_id = amsc.source_code_for_id                ");
                  selectBfr.append(" AND  language = USERENV('LANG')),        ");
                  selectBfr.append(" 'EONE',  (SELECT event_offer_name                  ");
                  selectBfr.append(" FROM    AMS_EVENT_OFFERS_ALL_TL                  ");
                  selectBfr.append(" WHERE  event_offer_id = amsc.source_code_for_id ");
                  selectBfr.append(" AND language = USERENV('LANG')),         ");
                  selectBfr.append(" 'EVEO',  (SELECT event_offer_name                  ");
                  selectBfr.append(" FROM   AMS_EVENT_OFFERS_ALL_TL                  ");
                  selectBfr.append(" WHERE event_offer_id = amsc.source_code_for_id ");
                  selectBfr.append(" AND language = USERENV('LANG')), ");
                  selectBfr.append(" 'OFFR',  (SELECT description                 ");
                  selectBfr.append(" FROM qp_list_headers_tl                 ");
                  selectBfr.append(" WHERE  list_header_id = amsc.source_code_for_id              ");
                  selectBfr.append(" AND language = USERENV('LANG')), ");
                  selectBfr.append(" null)  as SourceName , ");
           }
           else // not displayable
           {
             selectBfr.append("null as SourceName,  ");           
           }   
           continue;
         }

         else if("FormattedPhone".equals(voAttrName))
         {
              // check whether the attribute is displayable 
           if(renderedVwAttrs.contains(voAttrName))
           { 
          selectBfr.append(" DECODE(hcp.primary_phone_country_code,NULL,'', hcp.primary_phone_country_code || '-')  || ");
          selectBfr.append(" DECODE(hcp.primary_phone_area_code,NULL,'', hcp.primary_phone_area_code|| '-')  || ");
          selectBfr.append(" DECODE(hcp.primary_phone_number,NULL,'',hcp.primary_phone_number)   || ");
          selectBfr.append(" DECODE(hcp.primary_phone_extension,NULL,'','x' ||hcp.primary_phone_extension) as FormattedPhone, ");
           }
           else // not displayable
           {
             selectBfr.append("null as FormattedPhone,  ");
           }   
           continue;
        }
      }
    }
   
       // set the SELECT clause
       selectClause = selectBfr.toString();  
      selectClause = selectClause.trim();
      
       // check  whether the SELECT clause ends-with ","
       //remove "," from the end of selectClause
      if(selectClause.endsWith(","))
      { 
      selectClause = selectClause.substring(0, (selectClause.length()-1));
      }

   
   }
  
  //  Method Name: setSearchCriteria ( )
  //  Description: Retrieves the search criteria from dictionary object and loads into searchCriteria object 

   public void setSearchCriteria (Dictionary[] criteriaDicts)
   {  
    if (criteriaDicts!=null)
    {
      // loop thru (criteriaDicts)
      int size2 = criteriaDicts.length;
      for(int i=0; i<size2; i++)

      {
        // get the criteria dictionary object
         Dictionary criteriaDict = criteriaDicts[i];
         SearchCriteria criteriaObj = new SearchCriteria();
         ArrayList criteriaObjs = null;

          // populate the criteria as SearchCriteria object
          // item name respresents the corresponding table region column/item name for search item
         String criteriaItemName = (String)criteriaDict.get(OAViewObject.CRITERIA_ITEM_NAME);

         criteriaObj.setName(criteriaItemName);
         criteriaObj.setViewAttributeName((String)criteriaDict.get(
         OAViewObject.CRITERIA_VIEW_ATTRIBUTE_NAME));
         criteriaObj.setConditionOperator((String)criteriaDict.get(OAViewObject.CRITERIA_CONDITION));
         criteriaObj.setJoinCondition((String)criteriaDict.get(OAViewObject.CRITERIA_JOIN_CONDITION));
         criteriaObj.setValue(criteriaDict.get(OAViewObject.CRITERIA_VALUE));
   
        // see if the criteria item already exists in the search criteria or not
         if(searchCriteria.containsKey(criteriaItemName))
         {
          // get the existing search criteria for the same item if any
          criteriaObjs = (ArrayList)searchCriteria.get(criteriaItemName);
         }
         if(criteriaObjs==null)
          criteriaObjs = new ArrayList(10);
          
         // add the current search criteria to the list
         criteriaObjs.add(criteriaObj);
         // add the search criteria list to the searchCriteria hashmap object
         searchCriteria.put(criteriaItemName , criteriaObjs);
      } //end of loop
    }
  }

  //  Method Name: constructFromWhereClause ( )
  //  Description: Constructs the FROM and WHERE clause part of the SQL query based on the rendered 
  //  attributes (including sort), search criteria and access check 

  public void constructFromWhereClause (  OAApplicationModule oam,
                                          HashMap dshBdSrchParams,
                                           HashMap miscSrchParams)
  {
    final String METHOD_NAME = "asn.lead.server.LeadSearchManager.constructFromWhereClause";
    OADBTransaction  trxn = oam.getOADBTransaction();

    StringBuffer joinBfr   = new StringBuffer(1000);
    StringBuffer filterBfr = new StringBuffer(500);
    StringBuffer fromBfr   = new StringBuffer(1000);

    StringBuffer securityJoinBfr   = new StringBuffer(500);
    StringBuffer securityFilterBfr = new StringBuffer(500);
    StringBuffer securityFromBfr   = new StringBuffer(500);

   // fromBfr.append(" as_sales_leads  LeadEO, ");
   /* GSD - Changed FROM clause to order the records in the as_sales_leads table by creation date*/
    //fromBfr.append("( SELECT * FROM (SELECT * FROM apps.as_sales_leads ORDER BY creation_date desc )) LeadEO, ");
   
   fromBfr.append("apps.as_sales_leads LeadEO, "); 
    
  
    // Variable for Storing the indicator whether it is for owner or sales team that comes from the Dashboard
    // This variable will be used to pass the value to security logic
    String DashLeadLnkQryFor = null;

    // Variable for Storing the Age Days that comes from the Dashboard
    // This variable will be used to pass the value to security logic
    String DashLeadAgeDays = null;

    // Variable for Storing the From-Days that comes from the Dashboard
    String DashLeadFromDays = null;

    // Variable for Storing the To-Days that comes from the Dashboard
    String DashLeadToDays = null;

    // Variable for Storing the Seeded View's User Type
    String SeededLeadUserType = null;

    // Variable for Storing the Status Category Flag , in case, the Status Category is Open
    String StatusOpenFlag = null;

    // Variable for Storing the Status Open Flag resulted from Status Field, in case, the Status Category is Open
    String OpenFlagFromStatusField = null;

    // Variable for Storing the Owner Resource Id, in case, the Owner name is a selected Criteria 
    Number OwnerSrchResId= null ;

    // Variable for Storing the sales Rep Id, in case, the Sales Person is a selected Criteria 
    Number SalesRepId = null;

    // Variable for Storing the sales Group Id, in case, the Sales Group is a selected Criteria 
    Number GroupSrchId = null;

    MessageToken[] messageToken0 = { new MessageToken("IDNAME","ASNLoginResourceId" )};

    // Parameters that come from miscSrchParams
    Number resourceId =null;
    String ASNStdAlnMmbrFlag= null;
    String ASNMgrFlag= null;

    // In case of Refresh Row Logic, the miscSrchParams are null
    if(miscSrchParams!=null)
    {
      // added for login resource id
      // Store the Value of Logged In User's Resource Id 
      resourceId = ASNUtil.stringToJboNumber((String)miscSrchParams.get("ASNLoginResourceId"),
                                "ASN_CMMN_STR_TO_JBONUM_ERR", messageToken0);

      // Manager Related Variables
      // Indicates whether the resource is a manager/admin. Y/N
      ASNMgrFlag = (String)miscSrchParams.get("ASNMgrFlag");

      // Indicates whether the managerial resource is a stand alone member in any group. Y/N
      ASNStdAlnMmbrFlag = (String)miscSrchParams.get("ASNStdAlnMmbrFlag");

      // Indicates the list of groups that belong to the managerial resource. ArrayList 
      ASNMgrGrpIds = (ArrayList)miscSrchParams.get("ASNMgrGrpIds");

      // Indicates the list of groups that belong to the administrative resource. ArrayList 
      ASNAdmnGrpIds = (ArrayList)miscSrchParams.get("ASNAdmnGrpIds");   

      // Indicates the list of groups that the salesrep belongs to. ArrayList 
      ASNStdAlnMmbrGrpIds = (ArrayList)miscSrchParams.get("ASNStdAlnMmbrGrpIds");

      accessType = (String)miscSrchParams.get("ASNAccessOverride");     
    }

      /* Security Logic to support Full Access */
      // 'T' indicates Sales Team and 'F' indicates Full Access
      if(accessType == null)
      {
        // get the value from profile when the parameter returns a null
        accessType = trxn.getProfile("ASN_LEAD_ACCESS");
        if(accessType==null || "".equals(accessType.trim()))
        {
          accessType = "T";
        }
      }

    // First, Handle all the Security Logic related Criteria

    // Sales Person
    if(searchCriteria.containsKey("ASNLeadLstSlsRscId"))
    {
      ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstSlsRscId");
      int size =  searchValues.size();
      for ( int i = 0; i < size; i++)
      {
        SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(i);

        MessageToken[] messageToken3 = { new MessageToken("IDNAME","SalesRepId" )};
        SalesRepId =ASNUtil.stringToJboNumber((String)srchCtaObj.getValue(),
                                "ASN_CMMN_STR_TO_JBONUM_ERR", messageToken3);
      }
    }

    // Sales Group 
    if(searchCriteria.containsKey("ASNLeadLstSlsGrpId"))
    {
      ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstSlsGrpId");
      int size =  searchValues.size();
      for ( int i = 0; i < size; i++)
      { 
        SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(i);
        MessageToken[] messageToken13 = { new MessageToken("IDNAME","GroupSrchId" )};

        GroupSrchId =ASNUtil.stringToJboNumber((String)srchCtaObj.getValue(),
                                "ASN_CMMN_STR_TO_JBONUM_ERR", messageToken13);
      }
    }

    // Resource Name / Owner Name

    if(searchCriteria.containsKey("ASNLeadLstOwId"))
    {
      ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstOwId");
      int size =  searchValues.size();
       for ( int i = 0; i < size; i++)
      { 
        SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(i);

        // Store the Value of Owner Resource Id
        MessageToken[] messageTokenOwId =
         { new MessageToken("IDNAME","OwnerSrchResId" )};
        OwnerSrchResId = ASNUtil.stringToJboNumber((String)srchCtaObj.getValue(),
                                "ASN_CMMN_STR_TO_JBONUM_ERR", messageTokenOwId);

      } //end loop
    }

    // Lead Status for passing to SECURITY clause
    //Mohan ASNLeadSmpSrchStsCtg Lead Category checking
    if(searchCriteria.containsKey("ASNLeadSmpSrchStsCtg"))
    {
      ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadSmpSrchStsCtg");
      int size =  searchValues.size();
      for ( int i = 0; i < size; i++)
      { 
        SearchCriteria srchCtaObj = (SearchCriteria)searchValues.get(i);
        String status = (String)srchCtaObj.getValue();

        // Check if the value exists
        if(status != null && (!("".equals(status.trim()))))
        {
          OpenFlagFromStatusField = (String)(status.substring(status.length() -1));

        } 
      }
    }

    // Status Category
    // This field is part of Mandatory Search Criteria but not Displayed

    // In case of Manager, we always consider only those that are Open

//Mohan 10/14/2008

//    if("Y".equals(ASNMgrFlag))
//    {
// Mohan additional filter condition for status open flag introduced for reps
// managers (10/15/2008)
      if(searchCriteria.containsKey("ASNLeadLstStsCtg"))
      {
        ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstStsCtg");
        int size =  searchValues.size();
        SearchCriteria srchCtaObj = null;
        if (size > 0)
        {
          srchCtaObj =(SearchCriteria)searchValues.get(0);
          if ((((String)srchCtaObj.getConditionOperator()).trim()).equals("<>"))
          {
            if (((String)srchCtaObj.getValue()).equals("Y"))
            {
              filterBfr.append(" AND ");
              filterBfr.append(" LeadEO.status_open_flag = 'N' ");
              StatusOpenFlag = "N";
            }
            else if (((String)srchCtaObj.getValue()).equals("N"))
            {
              filterBfr.append(" AND ");
              filterBfr.append(" LeadEO.status_open_flag = 'Y' ");
              StatusOpenFlag = "Y";
            }
          }
          else
          {
            StatusOpenFlag = (String)srchCtaObj.getValue();
            filterBfr.append(" AND ");
            filterBfr.append(" LeadEO.status_open_flag = '");
            filterBfr.append(StatusOpenFlag);
            filterBfr.append("' ");
          }
        }
      }
     trxn.writeDiagnostics(METHOD_NAME,  "==>Mohan "+filterBfr.toString(), OAFwkConstants.PROCEDURE);
     
     
     //Vasan , 01/06/2011
     //Added Store Number Search
      if(searchCriteria.containsKey("ASNLeadStoreNo"))
      {
        ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadStoreNo");
        int size =  searchValues.size();
        SearchCriteria srchCtaObj = null;
        String StoreNum;
        if (size > 0)
        {
          srchCtaObj =(SearchCriteria)searchValues.get(0);
          if ((((String)srchCtaObj.getConditionOperator()).trim()).equals("<>"))
          {
            StoreNum = (String)srchCtaObj.getValue();
            filterBfr.append(" AND ");
            filterBfr.append(" LeadEO.Attribute4 <> '");
            filterBfr.append(StoreNum);
            filterBfr.append("' ");
          }
          else
          {
            StoreNum = (String)srchCtaObj.getValue();
            filterBfr.append(" AND ");
            filterBfr.append(" LeadEO.Attribute4 = '");
            filterBfr.append(StoreNum);
            filterBfr.append("' ");
          }
        }
      }
     trxn.writeDiagnostics(METHOD_NAME,  "==>Vasan "+filterBfr.toString(), OAFwkConstants.PROCEDURE);     
     
     
     //End of Change by Vasan
//    }

/*--- Manager commented out Mohan 10/14/2008

    if("Y".equals(ASNMgrFlag))
    {
        if ("Y".equals(OpenFlagFromStatusField))
        {
          filterBfr.append(" AND ");
          filterBfr.append(" LeadEO.status_open_flag = 'Y' ");
          StatusOpenFlag = "Y";
        }
        else
        if ("N".equals(OpenFlagFromStatusField))
        {
          filterBfr.append(" AND ");
          filterBfr.append(" LeadEO.status_open_flag = 'N' ");
          StatusOpenFlag = "N";
        }
    }
Comment ends....*/

    // Case of Rep
/*
    if(searchCriteria.containsKey("ASNLeadLstStsCtg"))
    {
      ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstStsCtg");
      int size =  searchValues.size();
      SearchCriteria srchCtaObj = null;
      if (size > 0)
      {
        srchCtaObj =(SearchCriteria)searchValues.get(0);
        if ((((String)srchCtaObj.getConditionOperator()).trim()).equals("<>"))
        {
          if (((String)srchCtaObj.getValue()).equals("Y"))
          {
             StatusOpenFlag = "N";
          }
          else if (((String)srchCtaObj.getValue()).equals("N"))
          {
             StatusOpenFlag = "Y";
          }
        }
        else
        {
          StatusOpenFlag = (String)srchCtaObj.getValue();
        }
      }
    }
*/
    // Dashboard Changes for Security
    if(dshBdSrchParams != null)
    {

      // Check if the Parameter passed from Leads Bin of Dashboard
      // requires the display of Leads for owner or sales team
      if(dshBdSrchParams.containsKey("ASNSrchLnkQryFor"))
      {
        DashLeadLnkQryFor = (String)dshBdSrchParams.get("ASNSrchLnkQryFor");
        if ("T".equals(DashLeadLnkQryFor))
        {
          // This is in case of Sales Team
          accessType = "T";
        }
        else
        {
          // This is in case of Owner
          OwnerSrchResId = resourceId;
        }
      }

      // Check if the Parameter passed from Leads Bin of Dashboard
      // requires the display of Leads within specific Age
      if(dshBdSrchParams.containsKey("ASNSrchLnkAgeDays"))
      {
        DashLeadAgeDays = (String)dshBdSrchParams.get("ASNSrchLnkAgeDays");
      }

      // Check if the Parameter passed from Leads Bin of Dashboard
      // requires the display of Leads in Open Status and created within last 2 days
      if(dshBdSrchParams.containsKey("ASNSrchLnkOp2"))
      {
        StatusOpenFlag = "Y";
        DashLeadToDays = "2";
      }

      // Check if the Parameter passed from Leads Bin of Dashboard
      // requires the display of Leads in Open Status and created between last 3 and 7 days
      if(dshBdSrchParams.containsKey("ASNSrchLnkOp3to7"))
      {
        StatusOpenFlag = "Y";
        DashLeadFromDays = "3";
        DashLeadToDays = "7";
      }

      // Check if the Parameter passed from Leads Bin of Dashboard
      // requires the display of Leads in Open Status and created between last 8 and 30 days
      if(dshBdSrchParams.containsKey("ASNSrchLnkOp8to30"))
      {
        StatusOpenFlag = "Y";
        DashLeadFromDays = "8";
        DashLeadToDays = "30";
      }

      // Check if the Parameter passed from Leads Bin of Dashboard
      // requires the display of Leads in Open Status and created more than 30 days ago
      if(dshBdSrchParams.containsKey("ASNSrchLnkOp31"))
      {
        StatusOpenFlag = "Y";
        DashLeadFromDays = "31";
      }

      // Check if the Parameter passed from Leads Bin of Dashboard
      // requires the display of Leads that are in Close Status
      if(dshBdSrchParams.containsKey("ASNSrchLnkClosed"))
      {
        StatusOpenFlag = "N";
      }

      // Check if the Parameter passed from Leads Bin of Dashboard
      // requires the display of Leads that are in Progress
      if(dshBdSrchParams.containsKey("ASNSrchLnkInPgs"))
      {
        StatusOpenFlag = "Y";
      }

      // Check if the Parameter passed from Leads Bin of Dashboard
      // requires the display of Leads that are DEAD
      if(dshBdSrchParams.containsKey("ASNSrchLnkDead"))
      {
        StatusOpenFlag = "N";
      }
    }

    // Handle Seeded Views
    // ASNLeadUserType is an additional Search Criteria parameter that gets passed
    // as 'owner' or 'salesteam' depending on whether user selects 
    // 'My Open Leads (Owner)' or 'My Open Leads (Sales Team)' respectively
    // The sales Team logic is handled by the security clause at the end which uses as_access_all

    if(searchCriteria.containsKey("ASNLeadQryIndicator"))    
    {
      ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadQryIndicator");
      int size =  searchValues.size();
       for ( int i = 0; i < size; i++)
      { 
        SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(i);

        SeededLeadUserType = (String)srchCtaObj.getValue();

        if (srchCtaObj.getValue().equals("owner"))
        {
          OwnerSrchResId = resourceId;
        }
        else
        {
          // This is in case of Sales Team
          accessType = "T";
        }
      }
    }

    // Created Date / Creation Date
    
    if(searchCriteria.containsKey("ASNLeadLstCrteDate"))
    {
      // Get all the Criteria Values for Age into an Array List
      ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstCrteDate");

      // Loop thru all the values in the Array List
      int size =  searchValues.size();
      for ( int i = 0; i < size; i++)
      { 
        // Get Search Criteria Object
        SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(i);

        // Get the Value in the Search Criteria Object
        String dateRangeScore = (String)srchCtaObj.getConditionOperator();

        // Check if the value exists
        if(dateRangeScore != null && (!("".equals(dateRangeScore.trim()))))
        {
          int dateind = dateRangeScore.indexOf("<");
          if( dateind != -1 )
          {
            LeadCreationDateToRange.add(srchCtaObj.getValue());
          }
          else
          {
            dateind = dateRangeScore.indexOf(">");
            if( dateind != -1 )
            {
              LeadCreationDateFromRange.add(srchCtaObj.getValue());
            }
            else
            {
              dateind = dateRangeScore.indexOf("=");
              if( dateind != -1 )
              {
                LeadCreationDateEqualsRange.add(srchCtaObj.getValue());
              }
            }
          }
        }
      } // end loop
    }
    
    /// START SECURITY LOGIC
    /// This shouldnt get executed during Refresh
    if(Refresh == false)
    // if (!("Y".equals(Refresh)))
    {
      HashMap secuParams = new HashMap(15);

      secuParams.put("AccessType", accessType);
      secuParams.put("OwnerId", OwnerSrchResId);
      secuParams.put("SalesPersonId",SalesRepId );
      secuParams.put("ResourceId",resourceId );
      secuParams.put("GroupId",GroupSrchId );
      secuParams.put("StatusOpenFlag",StatusOpenFlag);
      secuParams.put("ObjectType","LEAD" );
      secuParams.put("ASNStdAlnMmbrFlag",ASNStdAlnMmbrFlag );
      secuParams.put("ASNMgrFlag",ASNMgrFlag );
      secuParams.put("ASNMgrGrpIds",ASNMgrGrpIds );
      secuParams.put("ASNAdminGrpIds",ASNAdmnGrpIds );
      secuParams.put("ASNStdAlnMmbrGrpIds",ASNStdAlnMmbrGrpIds );
      secuParams.put("LeadCreationDateTo",LeadCreationDateToRange );
      secuParams.put("LeadCreationDateFrom",LeadCreationDateFromRange );
      secuParams.put("LeadCreationDateEquals",LeadCreationDateEqualsRange );
      secuParams.put("bindSequence",new Number(bindSequence) );
      secuParams.put("trans",trxn );
      secuParams.put("DashLeadAgeDays",DashLeadAgeDays );
      secuParams.put("DashLeadFromDays",DashLeadFromDays );
      secuParams.put("DashLeadToDays",DashLeadToDays );

      HashMap secuClause = new HashMap(4);

      secuClause  = getSecurityClause(secuParams);

      securityFromBfr.append((StringBuffer)secuClause.get("FromClause"));
      securityFilterBfr.append((StringBuffer)secuClause.get("filterClause"));
      securityJoinBfr.append((StringBuffer)secuClause.get("whereClause"));

      // check  whether the securityFilterBfr clause begins-with "WHERE "
      // WHERE keyword is appended later
      securityFilterClause = securityFilterBfr.toString();
      securityFilterClause = securityFilterClause.trim();
      if(securityFilterClause.startsWith("WHERE "))
      {
        // remove "WHERE " from the beginning of the whereClause
        securityFilterClause = securityFilterClause.substring(5);
      }

      // check  whether the securityJoinBfr clause begins-with "WHERE "
      // WHERE keyword is appended later
      securityJoinClause = securityJoinBfr.toString();
      securityJoinClause = securityJoinClause.trim();
      if(securityJoinClause.startsWith("WHERE "))
      {
        // remove "WHERE " from the beginning of the whereClause
        securityJoinClause = " AND "+securityJoinClause.substring(5);
      }

      ArrayList bindVars = (ArrayList)secuClause.get("bindVars");
      if(bindVars!= null && bindVars.size() > 0)
      { 
        for (int i = 0; i < bindVars.size(); i++)
        {
          bindVariables.add(bindVars.get(i));
        }
      }  
      bindSequence = bindSeq;
      securityWhereClause = securityJoinClause +" "+securityFilterClause;
    }

    /// END SECURITY LOGIC
    
    // Check all EO Based Attributes

    // Description
    if(searchCriteria.containsKey("ASNLeadLstNm"))
    {
      ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstNm");
      int size =  searchValues.size();
       for ( int i = 0; i < size; i++)
      { 
        SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(i);
        filterBfr.append(" AND ");
        filterBfr.append(" UPPER(LeadEO.Description) ");
        filterBfr.append(srchCtaObj.getConditionOperator());
        filterBfr.append(":" + bindSequence ++);
        bindVariables.add(((String)srchCtaObj.getValue()).toUpperCase());
      } //end loop
    }

    // Lead Number
    if(searchCriteria.containsKey("ASNLeadLstNbr"))
    {
      ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstNbr");
      int size =  searchValues.size();
       for ( int i = 0; i < size; i++)
       { 
          SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(i);
          filterBfr.append(" AND ");
          filterBfr.append(" LeadEO.Lead_Number ");
          filterBfr.append(srchCtaObj.getConditionOperator());
          filterBfr.append(":" + bindSequence ++);
          bindVariables.add(srchCtaObj.getValue());
       } //end loop
    }

    // Creation Date / Created Date
    
    if(searchCriteria.containsKey("ASNLeadLstCrteDate"))
    {
       ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstCrteDate");
      int size =  searchValues.size();
       for ( int i = 0; i < size; i++)
       {
          SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(i);
          filterBfr.append(" AND ");
          filterBfr.append(" trunc(LeadEO.Creation_Date) ");
          filterBfr.append(srchCtaObj.getConditionOperator());
          filterBfr.append(" trunc(:" + bindSequence ++);
          bindVariables.add(srchCtaObj.getValue());
         filterBfr.append(" ) ");
       } //end loop
    }

    // Budget Amount
    if(searchCriteria.containsKey("ASNLeadLstBdgtAmt"))
    {
       ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstBdgtAmt");
      int size =  searchValues.size();
       for ( int i = 0; i < size; i++)
       { 
          SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(i);
          filterBfr.append(" AND ");
          filterBfr.append(" LeadEO.Budget_Amount ");
          filterBfr.append(srchCtaObj.getConditionOperator());
          filterBfr.append(":" + bindSequence ++);
          bindVariables.add(srchCtaObj.getValue());
       } //end loop
    }

    // Non EO Based Attributes

    // Resource Name/ Owner Name
    // This corresponds to VO Attribute Name : ResourceName ; Prompt : Owner Name

    if(renderedVwAttrs.contains("ResourceName"))
    {
      fromBfr.append(" jtf_rs_resource_extns_tl jrt, ");
      joinBfr.append(" AND LeadEO.assign_to_salesforce_id = jrt.resource_id ");
      joinBfr.append(" AND jrt.language (+)= USERENV('LANG') ");
    }

    // Handle the Owner Logic
    if(OwnerSrchResId !=null)
    {
      filterBfr.append(" AND  ");
      filterBfr.append(" LeadEO.assign_to_salesforce_id = ");
      filterBfr.append(":" + bindSequence ++);
      bindVariables.add(OwnerSrchResId);
    }
    
    // Lead Status
    // LeadStatus is a column in VO that is based on EO and is always a mandatory one
    // so need not have to check for Else Clause
    if(renderedVwAttrs.contains("LeadStatus"))
    {
      fromBfr.append( " as_statuses_tl ast ," );
      joinBfr.append( " AND LeadEO.status_code = ast.status_code " );
      joinBfr.append( " AND ast.language = USERENV('LANG')");
    }

    // Lead Status for Binding
    if(searchCriteria.containsKey("ASNLeadLstStatus"))
    {
      ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstStatus");
      int size =  searchValues.size();
      for ( int i = 0; i < size; i++)
      { 
        SearchCriteria srchCtaObj = (SearchCriteria)searchValues.get(i);
        String status = (String)srchCtaObj.getValue();

        // Check if the value exists
        if(status != null && (!("".equals(status.trim()))))
        {
          // OpenFlagFromStatusField = (String)(status.substring(status.length() -1));

          // filterBfr.append(" " + srchCtaObj.getJoinCondition() + " ");
          filterBfr.append(" AND ");
          filterBfr.append(" LeadEO.status_code ");
          filterBfr.append(srchCtaObj.getConditionOperator());
          filterBfr.append(":" + bindSequence ++);
          bindVariables.add((String)(status.substring(0,status.length() -2)));
        } 
      }
    }


    // Customer Name

    if( searchCriteria.containsKey("ASNLeadLstCustNm") || 
        renderedVwAttrs.contains("CustomerName"))
    {
      fromBfr.append( "  hz_parties hpobj ," );
      joinBfr.append( " AND LeadEO.customer_id = hpobj.party_id " );
    }    

    if(searchCriteria.containsKey("ASNLeadLstCustNm"))
    {
      ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstCustNm");
      int size =  searchValues.size();
       for ( int i = 0; i < size; i++)
      { 
        SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(i);
        filterBfr.append(" AND ");
        filterBfr.append(" UPPER(hpobj.party_name) ");
        filterBfr.append(srchCtaObj.getConditionOperator());
        filterBfr.append(":" + bindSequence ++);
         bindVariables.add(((String)srchCtaObj.getValue()).toUpperCase());
      } //end loop
    }

    // Customer Category

    if(searchCriteria.containsKey("ASNLeadLstCustCtg") )
    // Check if the hz_parties hpobj is already used by Customer Name attribute
    {
      if( searchCriteria.containsKey("ASNLeadLstCustNm") || 
          renderedVwAttrs.contains("CustomerName"))
      {
        fromBfr = fromBfr;
      }
      else
      {
        fromBfr.append( " hz_parties hpobj ," );
      }
      fromBfr.append( " fnd_lookup_values ctgry ," );

        joinBfr.append( " AND hpobj.category_code = ctgry.lookup_code (+) " );
        joinBfr.append( " AND ctgry.lookup_type (+) = 'CUSTOMER_CATEGORY' " );
       joinBfr.append( " AND ctgry.view_application_id = 222 " );
         joinBfr.append( " AND ctgry.language = USERENV('LANG')");
     
       if(searchCriteria.containsKey("ASNLeadLstCustCtg"))
       {
        ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstCustCtg");
        int size =  searchValues.size();
         for ( int i = 0; i < size; i++)
          { 
          SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(i);
            filterBfr.append(" AND ");
            filterBfr.append(" ctgry.meaning ");
            filterBfr.append(srchCtaObj.getConditionOperator());
            filterBfr.append(":" + bindSequence ++);
           bindVariables.add(((String)srchCtaObj.getValue()).toUpperCase());
          } //end loop
       }
    }

    // Sales Stage
    if(renderedVwAttrs.contains("Stage"))
   {
      fromBfr.append( " as_sales_stages_all_tl assat, " );
       if(searchCriteria.containsKey("ASNLeadLstStg"))
       {
        joinBfr.append(" AND LeadEO.sales_stage_id = assat.sales_stage_id " );
         joinBfr.append(" AND  assat.language = USERENV ('LANG') " );
      }
      else
       {
        joinBfr.append(" AND LeadEO.sales_stage_id = assat.sales_stage_id(+)  " );
         joinBfr.append(" AND assat.language (+) = USERENV ('LANG') " );
       } 
    }

    if(searchCriteria.containsKey("ASNLeadLstStg"))
    {
      ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstStg");
      int size =  searchValues.size();
       for ( int i = 0; i < size; i++)
      { 
        SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(i);
         filterBfr.append(" AND ");
         filterBfr.append(" LeadEO.sales_stage_id ");
         filterBfr.append(srchCtaObj.getConditionOperator());
         filterBfr.append(":" + bindSequence ++);
         bindVariables.add(srchCtaObj.getValue());
      } //end loop
    }

    // CurrencyName
    if(renderedVwAttrs.contains("CurrencyName"))
    { 
      fromBfr.append( " fnd_currencies_tl fnt," );
       if(searchCriteria.containsKey("ASNLeadLstCurrNm"))
       {
        joinBfr.append(" AND  LeadEO.currency_code = fnt.currency_code " );
         joinBfr.append(" AND fnt.language = USERENV('LANG')");
       }
      else
       {
        joinBfr.append(" AND LeadEO.currency_code = fnt.currency_code " );
         joinBfr.append(" AND fnt.language = USERENV('LANG')");
       } 
    }

    if(searchCriteria.containsKey("ASNLeadLstCurrNm"))
    {
      ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstCurrNm");
      int size =  searchValues.size();
       for ( int i = 0; i < size; i++)
      { 
        SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(i);
         filterBfr.append(" AND "); 
         filterBfr.append(" LeadEO.currency_code ");
         filterBfr.append(srchCtaObj.getConditionOperator());
         filterBfr.append(":" + bindSequence ++);
         bindVariables.add(srchCtaObj.getValue());
      } //end loop
    } 

    // sales Channel

    // Manager Case : Sales Channel Name
    // Handle the Manager case here
    if("Y".equals(ASNMgrFlag))
    {
      // In case of manager, we always have the search criteria as mandatory
      if(searchCriteria.containsKey("ASNLeadLstChnl"))
      {
        ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstChnl");
        int size =  searchValues.size();
        // channelJoin is a variable that indicates whether the sales channel lookup table is required to be joined
        String channelJoin = null;
        for ( int i = 0; i < size; i++)
        {
          SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(i);
          // Get the Value in the Search Criteria Object
          String salesChannelValue = (String)srchCtaObj.getValue();

          // Check if the value is Unspecified 
          if (salesChannelValue != null && "-999".equals(salesChannelValue))
          {
            filterBfr.append(" AND ");
            filterBfr.append(" LeadEO.channel_code is NULL ");
          }
          else
          {
            if(renderedVwAttrs.contains("SalesChannel"))
            {
              channelJoin = "Y";
            }
            filterBfr.append(" AND ");
            filterBfr.append(" LeadEO.channel_code ");
            filterBfr.append(srchCtaObj.getConditionOperator());
            filterBfr.append(":" + bindSequence ++);
            bindVariables.add(srchCtaObj.getValue());          
          }
        } //end loop
        if("Y".equals(channelJoin))
        {
          fromBfr.append( " fnd_lookup_values chnl, " );
          //  If the Sales Channel is part of Search Criteria as well as Display Columns
          joinBfr.append( " AND LeadEO.channel_code = chnl.lookup_code " );
          joinBfr.append( " AND chnl.lookup_type = 'SALES_CHANNEL' " );
          joinBfr.append( " AND chnl.view_application_id = 660 " );
          joinBfr.append( " AND chnl.language = USERENV('LANG')");
        }
      }
      else
      {
        if(renderedVwAttrs.contains("SalesChannel"))
        {
          fromBfr.append( " fnd_lookup_values chnl, " );
          joinBfr.append( " AND LeadEO.channel_code = chnl.lookup_code (+) " );
          joinBfr.append( " AND chnl.lookup_type (+) = 'SALES_CHANNEL' " );
          joinBfr.append( " AND chnl.view_application_id (+) = 660 " );
          joinBfr.append( " AND chnl.language (+) = USERENV('LANG')");
        }
      }
    }

    // Rep Case : Sales Channel
    // Handle the Rep Case here
    if(!("Y".equals(ASNMgrFlag)))
    {
      if(renderedVwAttrs.contains("SalesChannel"))
      {
        fromBfr.append( " fnd_lookup_values chnl, " );
        if(searchCriteria.containsKey("ASNLeadLstChnl"))
        {
          joinBfr.append( " AND LeadEO.channel_code = chnl.lookup_code " );
          joinBfr.append( " AND chnl.lookup_type = 'SALES_CHANNEL' " );
          joinBfr.append( " AND chnl.view_application_id = 660 " );
          joinBfr.append( " AND chnl.language = USERENV('LANG')");
        }
        else
        {
          joinBfr.append( " AND LeadEO.channel_code = chnl.lookup_code (+) " );
          joinBfr.append( " AND chnl.lookup_type (+) = 'SALES_CHANNEL' " );
          joinBfr.append( " AND chnl.view_application_id (+) = 660 " );
          joinBfr.append( " AND chnl.language (+) = USERENV('LANG')");
        }
      }

      if(searchCriteria.containsKey("ASNLeadLstChnl"))
      {
        ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstChnl");
        int size =  searchValues.size();
        for ( int i = 0; i < size; i++)
        { 
          SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(i);
          String salesChannelValue = (String)srchCtaObj.getValue();
          // Check if the value is Unspecified 
          if (salesChannelValue != null && "-999".equals(salesChannelValue))
          {
            filterBfr.append(" AND ");
            filterBfr.append(" LeadEO.channel_code is NULL ");
          }
          else
          {
            filterBfr.append(" AND ");
            filterBfr.append(" LeadEO.channel_code ");
            filterBfr.append(srchCtaObj.getConditionOperator());
            filterBfr.append(":" + bindSequence ++);
            bindVariables.add(srchCtaObj.getValue());          
          }
        } //end loop
      }
    }

    // Response Channel

    if(renderedVwAttrs.contains("ResponseChannel"))
    {
      fromBfr.append( " fnd_lookup_values rspchnl, " );
      if(searchCriteria.containsKey("ASNLeadLstRspChnl"))
      {
         joinBfr.append( " AND LeadEO.vehicle_response_code = rspchnl.lookup_code " );
         joinBfr.append( " AND rspchnl.lookup_type = 'ASN_VEHICLE_RESPONSE_CODE' " );
         joinBfr.append( " AND rspchnl.view_application_id = 0 " );
         joinBfr.append( " AND rspchnl.language = USERENV('LANG')");
      }
      else
      {
         joinBfr.append( " AND LeadEO.vehicle_response_code = rspchnl.lookup_code (+) " );
         joinBfr.append( " AND rspchnl.lookup_type (+) = 'ASN_VEHICLE_RESPONSE_CODE' " );
         joinBfr.append( " AND rspchnl.view_application_id (+) = 0 " );
         joinBfr.append( " AND rspchnl.language (+) = USERENV('LANG')");
      }
    }

    if(searchCriteria.containsKey("ASNLeadLstRspChnl"))
    {
      ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstRspChnl");
      int size =  searchValues.size();
       for ( int i = 0; i < size; i++)
      { 
        SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(i);
        filterBfr.append(" AND ");
        filterBfr.append(" LeadEO.vehicle_response_code ");
        filterBfr.append(srchCtaObj.getConditionOperator());
        filterBfr.append(":" + bindSequence ++);
        bindVariables.add(srchCtaObj.getValue());
      } //end loop
    }

    // Source System

    if(renderedVwAttrs.contains("SourceSystem"))
    {
      fromBfr.append( " fnd_lookup_values srcsys, " );
      if(searchCriteria.containsKey("ASNLeadLstSrcSystem"))
      {
         joinBfr.append( " AND LeadEO.source_system = srcsys.lookup_code " );
         joinBfr.append( " AND srcsys.lookup_type = 'SOURCE_SYSTEM' " );
         joinBfr.append( " AND srcsys.view_application_id = 279 " );
         joinBfr.append( " AND srcsys.language = USERENV('LANG')");
      }
      else
      {
         joinBfr.append( " AND LeadEO.source_system = srcsys.lookup_code (+) " );
         joinBfr.append( " AND srcsys.lookup_type (+) = 'SOURCE_SYSTEM' " );
         joinBfr.append( " AND srcsys.view_application_id (+) = 279 " );
         joinBfr.append( " AND srcsys.language (+) = USERENV('LANG')");
      }
    }

    if(searchCriteria.containsKey("ASNLeadLstSrcSystem"))
    {
      ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstSrcSystem");
      int size =  searchValues.size();
       for ( int i = 0; i < size; i++)
      { 
        SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(i);
        filterBfr.append(" AND "); 
        filterBfr.append(" LeadEO.source_system  ");
        filterBfr.append(srchCtaObj.getConditionOperator());
        filterBfr.append(":" + bindSequence ++);
        bindVariables.add(srchCtaObj.getValue());
      } //end loop
    }

    // Close Reason

    if(renderedVwAttrs.contains("CloseReason"))
    {
      fromBfr.append( " fnd_lookup_values clsrsn, " );
      if(searchCriteria.containsKey("ASNLeadLstClsRsn"))
      {
         joinBfr.append( " AND LeadEO.close_reason = clsrsn.lookup_code " );
         joinBfr.append( " AND clsrsn.lookup_type = 'ASN_LEAD_CLOSE_REASON' " );
         joinBfr.append( " AND clsrsn.view_application_id = 0 " );
         joinBfr.append( " AND clsrsn.language = USERENV('LANG')");
      }
      else
      {
         joinBfr.append( " AND LeadEO.close_reason = clsrsn.lookup_code (+) " );
         joinBfr.append( " AND clsrsn.lookup_type (+) = 'ASN_LEAD_CLOSE_REASON' " );
         joinBfr.append( " AND clsrsn.view_application_id (+) = 0 " );
         joinBfr.append( " AND clsrsn.language (+) = USERENV('LANG')");
      }
    }

    if(searchCriteria.containsKey("ASNLeadLstClsRsn"))
    {
      ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstClsRsn");
      int size =  searchValues.size();
       for ( int i = 0; i < size; i++)
      { 
        SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(i);
        filterBfr.append(" AND "); 
        filterBfr.append(" LeadEO.close_reason  ");
        filterBfr.append(srchCtaObj.getConditionOperator());
        filterBfr.append(":" + bindSequence ++);
        bindVariables.add(srchCtaObj.getValue());
      } //end loop
    }

    // Lead Rank Name

    if(renderedVwAttrs.contains("RankName"))
    {
      fromBfr.append( " as_sales_lead_ranks_tl aslrt ," );
      if(searchCriteria.containsKey("ASNLeadLstRank"))
      {
        //  If the Lead Rank is part of Search Criteria as well as Display Columns,
        //  We may have to use the Base Table as well depending upon the criteria value
        // Suppose, if the Value entered has a > symbol, we need to join both tables.
        fromBfr.append( " as_sales_lead_ranks_b aslrb ," );
        joinBfr.append( " AND LeadEO.lead_rank_id = aslrb.rank_id " );
        joinBfr.append( " AND aslrb.rank_id = aslrt.rank_id " );
        joinBfr.append( " AND aslrt.language = USERENV('LANG')");
      }
      else
      {
        // If the Lead Rank is part of Display Columns but not the Search Criteria,
        //  We can go directly against the TL table
        joinBfr.append( " AND LeadEO.lead_rank_id = aslrt.rank_id (+) " );
        joinBfr.append( " AND aslrt.language (+) = USERENV('LANG')");
      }
    }

    if(searchCriteria.containsKey("ASNLeadLstRank"))
    {
      // Get all the Criteria Values for Rank into an Array List
      ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstRank");
      // Loop thru all the values in the Array List
      int size =  searchValues.size();

      for ( int i = 0; i < size; i++)
      { 
        // Get Search Criteria Object
        SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(i);

        // Get the Value in the Search Criteria Object
        String rankRangeScore = (String)srchCtaObj.getValue();

        // Check if the value exists
        if(rankRangeScore != null && (!("".equals(rankRangeScore.trim()))))
        {
          int ind = rankRangeScore.indexOf("=");
          if( ind == -1 )
          {
            MessageToken[] messageToken = { new MessageToken("IDNAME",rankRangeScore )};
            Number rankId = ASNUtil.stringToJboNumber
                            (rankRangeScore,"ASN_CMMN_STR_TO_JBONUM_ERR", messageToken);

            filterBfr.append(" AND "); 
            filterBfr.append(" LeadEO.lead_rank_id ");
            filterBfr.append(" = ");
            filterBfr.append(":" + bindSequence ++);
            bindVariables.add(rankId);
          }
          else
          {
            MessageToken[] messageToken1 = { new MessageToken("IDNAME",rankRangeScore.substring(ind+1) )};
            Number minScore =   ASNUtil.stringToJboNumber
                                (rankRangeScore.substring(ind+1),"ASN_CMMN_STR_TO_JBONUM_ERR", messageToken1);

            filterBfr.append(" AND "); 
            filterBfr.append(" aslrb.min_score ");
            filterBfr.append(" >= ");
            filterBfr.append(":" + bindSequence ++);
            bindVariables.add(minScore);
          }
        }
      } //end loop
    }


    // Methodology

    if(renderedVwAttrs.contains("Methodology"))
    {
      fromBfr.append( " as_sales_methodology_tl asmt ," );
      if(searchCriteria.containsKey("ASNLeadLstMeth"))
      {
         joinBfr.append( " AND LeadEO.sales_methodology_id = asmt.sales_methodology_id " );
         joinBfr.append( " AND asmt.language = USERENV('LANG')");
      }
      else
      {
         joinBfr.append( " AND LeadEO.sales_methodology_id = asmt.sales_methodology_id (+) " );
         joinBfr.append( " AND asmt.language (+) = USERENV('LANG')");
      }
    }

    if(searchCriteria.containsKey("ASNLeadLstMeth"))
    {
      ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstMeth");
      int size =  searchValues.size();
       for ( int i = 0; i < size; i++)
      { 
        SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(i);
        filterBfr.append(" AND ");
        filterBfr.append(" LeadEO.sales_methodology_id ");
        filterBfr.append(srchCtaObj.getConditionOperator());
        filterBfr.append(":" + bindSequence ++);
        bindVariables.add(srchCtaObj.getValue());
      } //end loop
    }

    // Source Name 
    // ASNLeadLstSrcNm is the Search Display Field for Source Meaning
    // ASNLeadLstSrcId is the Search Field that has the Source Id stored

    if(renderedVwAttrs.contains("SourceName"))
    {
      fromBfr.append( " ams_source_codes amsc ," );
      if(searchCriteria.containsKey("ASNLeadLstSrcId"))
      {
         joinBfr.append( " AND LeadEO.source_promotion_id = amsc.source_code_id " );
      }
      else
      {
         joinBfr.append( " AND LeadEO.source_promotion_id = amsc.source_code_id (+)" );
      }
    }

    if(searchCriteria.containsKey("ASNLeadLstSrcId"))
    {
      ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstSrcId");
      int size =  searchValues.size();
       for ( int i = 0; i < size; i++)
      {
        SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(i);
        filterBfr.append(" AND ");
        filterBfr.append(" LeadEO.source_promotion_id ");
        filterBfr.append(srchCtaObj.getConditionOperator());
        filterBfr.append(":" + bindSequence ++);
        bindVariables.add(srchCtaObj.getValue());
      } //end loop
    }


    // Age
    
    if(searchCriteria.containsKey("ASNLeadLstAge"))
    {
      // Get all the Criteria Values for Age into an Array List
      ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstAge");

      // Date variables to be used to convert the Age into date
      Date  date = new Date();
      Date beginDate = (Date) date.getCurrentDate();
      Date endDate = (Date) date.getCurrentDate();

      // Loop thru all the values in the Array List
      int size =  searchValues.size();
      SearchCriteria srchCtaObj = null;
      String ageRangeScore = null;
      
      for ( int i = 0; i < size; i++)
      { 
        // Get Search Criteria Object
        srchCtaObj =(SearchCriteria)searchValues.get(i);

        // Get the Value in the Search Criteria Object
        ageRangeScore = (String)srchCtaObj.getValue();

        // Check if the value exists
        if(ageRangeScore != null && (!("".equals(ageRangeScore.trim()))))
        {
          int ind = ageRangeScore.indexOf("-");
          if( ind != -1 )
          {
            MessageToken[] messageToken3 = { new MessageToken("IDNAME",ageRangeScore.substring(0,ind) )};
            Number  beginAge =
              ASNUtil.stringToJboNumber(ageRangeScore.substring(0,ind), "ASN_CMMN_STR_TO_JBONUM_ERR", messageToken3);
            MessageToken[] messageToken4 = { new MessageToken("IDNAME",ageRangeScore.substring(ind+1) )};
            Number  endAge =
              ASNUtil.stringToJboNumber(ageRangeScore.substring(ind+1), "ASN_CMMN_STR_TO_JBONUM_ERR", messageToken4);

            Number tempBeginAge = beginAge.subtract(1);
            Number tempEndAge = endAge.add(1);
            
            // converting the age into the past date relative to the system date
            beginDate = (Date) beginDate.addJulianDays(-tempBeginAge.intValue(),0);     
            endDate = (Date) endDate.addJulianDays(-tempEndAge.intValue(),0);

            filterBfr.append(" AND TRUNC(LeadEO.creation_date) <= :"+ bindSequence++ );
            filterBfr.append(" AND TRUNC(LeadEO.creation_date) >= :"+ bindSequence++ );
            filterBfr.append(" AND CEIL(SYSDATE - LeadEO.creation_date) BETWEEN :"+ bindSequence++ +" AND :"+bindSequence++ );
            bindVariables.add(beginDate);
            bindVariables.add(endDate);
            bindVariables.add(beginAge);
            bindVariables.add(endAge);
          }
          else
          {
            ind = ageRangeScore.indexOf(">=");
            if( ind != -1 )
            {
              MessageToken[] messageToken1 = { new MessageToken("IDNAME",ageRangeScore.substring(ind+2) )};
              Number minScore =   
              ASNUtil.stringToJboNumber(ageRangeScore.substring(ind+2),"ASN_CMMN_STR_TO_JBONUM_ERR", messageToken1);

              Number tempMinScore = minScore.subtract(1);

              endDate = (Date) endDate.addJulianDays(-tempMinScore.intValue(),0);
              filterBfr.append(" AND TRUNC(LeadEO.creation_date) <= :"+ bindSequence++ );
              filterBfr.append(" AND CEIL(SYSDATE - LeadEO.creation_date) ");
              filterBfr.append(" >= ");
              filterBfr.append(":" + bindSequence ++);
              bindVariables.add(endDate);                
              bindVariables.add(minScore);
            }
            else
            {
              ind = ageRangeScore.indexOf("<=");
              if( ind != -1 )
              {
                MessageToken[] messageToken1 = { new MessageToken("IDNAME",ageRangeScore.substring(ind+2) )};
                Number minScore =   
                ASNUtil.stringToJboNumber(ageRangeScore.substring(ind+2),"ASN_CMMN_STR_TO_JBONUM_ERR", messageToken1);

                Number tempMinScore = minScore.add(1);

                beginDate = (Date) beginDate.addJulianDays(-tempMinScore.intValue(),0);
                filterBfr.append(" AND TRUNC(LeadEO.creation_date) >= :"+ bindSequence++ );
                filterBfr.append(" AND CEIL(SYSDATE - LeadEO.creation_date) ");
                filterBfr.append(" <= ");
                filterBfr.append(":" + bindSequence ++);
                bindVariables.add(beginDate);
                bindVariables.add(minScore);
              }
              else
              {
                ind = ageRangeScore.indexOf("<");
                if( ind != -1 )
                {
                  MessageToken[] messageToken1 = { new MessageToken("IDNAME",ageRangeScore.substring(ind+1) )};
                  Number minScore =   
                  ASNUtil.stringToJboNumber(ageRangeScore.substring(ind+1),"ASN_CMMN_STR_TO_JBONUM_ERR", messageToken1);

                  Number tempMinScore = minScore.add(1);

                  beginDate = (Date) beginDate.addJulianDays(-tempMinScore.intValue(),0);
                  filterBfr.append(" AND TRUNC(LeadEO.creation_date) > :"+ bindSequence++ );
                  filterBfr.append(" AND CEIL(SYSDATE - LeadEO.creation_date) ");
                  filterBfr.append(" < ");
                  filterBfr.append(":" + bindSequence ++);
                  bindVariables.add(beginDate);
                  bindVariables.add(minScore);
                }
                else
                {
                  ind = ageRangeScore.indexOf(">");
                  if( ind != -1 )
                  {
                    MessageToken[] messageToken1 = { new MessageToken("IDNAME",ageRangeScore.substring(ind+1) )};
                    Number minScore =   
                    ASNUtil.stringToJboNumber(ageRangeScore.substring(ind+1),"ASN_CMMN_STR_TO_JBONUM_ERR", messageToken1);

                    Number tempMinScore = minScore.subtract(1);

                    endDate = (Date) endDate.addJulianDays(-tempMinScore.intValue(),0);
                    filterBfr.append(" AND TRUNC(LeadEO.creation_date) < :"+ bindSequence++ );
                    filterBfr.append(" AND CEIL(SYSDATE - LeadEO.creation_date) ");
                    filterBfr.append(" > ");
                    filterBfr.append(":" + bindSequence ++);
                    bindVariables.add(endDate);
                    bindVariables.add(minScore);
                  }
                  else
                  {
                    ind = ageRangeScore.indexOf("=");
                    if( ind != -1 )
                    {
                      MessageToken[] messageToken1 = { new MessageToken("IDNAME",ageRangeScore.substring(ind+1) )};
                      Number minScore =   
                      ASNUtil.stringToJboNumber(ageRangeScore.substring(ind+1),"ASN_CMMN_STR_TO_JBONUM_ERR", messageToken1);

                      endDate = (Date) endDate.addJulianDays(-minScore.intValue(),0);
                      filterBfr.append(" AND TRUNC(LeadEO.creation_date) = :"+ bindSequence++ );
                      filterBfr.append(" AND CEIL(SYSDATE - LeadEO.creation_date) ");
                      filterBfr.append(" = ");
                      filterBfr.append(":" + bindSequence ++);
                      bindVariables.add(endDate);
                      bindVariables.add(minScore);
                    }
                  }
                }
              }
            }
          }
        }
      } //end loop
    }    


    // Lead Created By

    if(renderedVwAttrs.contains("LeadCreatedBy"))
    {
      fromBfr.append( " fnd_user fucr, " );
      joinBfr.append( " AND LeadEO.created_by = fucr.user_id " );
    }

    // Lead Updated By

    if(renderedVwAttrs.contains("LeadUpdatedBy"))
    {
      fromBfr.append( " fnd_user fuup, " );
      joinBfr.append( " AND LeadEO.last_updated_by = fuup.user_id " );
    }

    // Contact Details
    // The Search Criteria can have Contact First Name and Contact Last Name
    // But, We are displaying only the Contact Name

    if(renderedVwAttrs.contains("PersonId"))
    {
      fromBfr.append( " hz_parties cont, hz_relationships hr, " );
       if( searchCriteria.containsKey("ASNLeadLstCtctFstNm")||
          searchCriteria.containsKey("ASNLeadLstCtctLstNm")
        )
       {
        joinBfr.append(" AND LeadEO.primary_contact_party_id = hr.party_id  ");
        joinBfr.append(" AND hr.subject_id = cont.party_id ");
        joinBfr.append(" AND hr.subject_table_name = 'HZ_PARTIES' ");
        joinBfr.append(" AND hr.object_id = LeadEO.customer_id ");
        joinBfr.append(" AND hr.object_table_name = 'HZ_PARTIES' " );
       }
       else
       {
        joinBfr.append(" AND LeadEO.primary_contact_party_id = hr.party_id(+)  ");
         joinBfr.append(" AND hr.subject_id = cont.party_id (+) ");
         joinBfr.append(" AND hr.subject_table_name (+) = 'HZ_PARTIES' ");
         joinBfr.append(" AND hr.object_id(+) = LeadEO.customer_id ");
         joinBfr.append(" AND hr.object_table_name (+) = 'HZ_PARTIES' " );
       } 
    }

    // Binding the Search Criteria in case of Contact First Name
    if(searchCriteria.containsKey("ASNLeadLstCtctFstNm"))
    {
      ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstCtctFstNm");
      int size =  searchValues.size();
       for ( int i = 0; i < size; i++)
      { 
        SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(i);
         filterBfr.append(" AND ");
         filterBfr.append(" UPPER(cont.person_first_name) ");
         filterBfr.append(srchCtaObj.getConditionOperator());
         filterBfr.append(":" + bindSequence ++);
         bindVariables.add(((String)srchCtaObj.getValue()).toUpperCase());
      } //end loop
    }

    // Binding the Search Criteria in case of Contact Last Name
    if(searchCriteria.containsKey("ASNLeadLstCtctLstNm"))
    {
      ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstCtctLstNm");
      int size =  searchValues.size();
       for ( int i = 0; i < size; i++)
      { 
        SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(i);
         filterBfr.append(" AND ");
         filterBfr.append(" UPPER(cont.person_last_name) ");
         filterBfr.append(srchCtaObj.getConditionOperator());
         filterBfr.append(":" + bindSequence ++);
         bindVariables.add(((String)srchCtaObj.getValue()).toUpperCase());
      } //end loop
    }

    // Job Title
    
    if(renderedVwAttrs.contains("JobTitle"))
    {
      fromBfr.append(" hz_org_contacts hoc,  ");
      joinBfr.append(" AND hr.relationship_id = hoc.party_relationship_id (+) ");      
    }

    // Contact Role 
    // ASNLeadLstCtctRole is the Search Field that has the Source Id stored

    if(renderedVwAttrs.contains("ContactRole"))
    {
      fromBfr.append( " as_sales_lead_contacts role, fnd_lookup_values ctrole ," );
      if(searchCriteria.containsKey("ASNLeadLstCtctRole"))
      {
        joinBfr.append( " AND LeadEO.sales_lead_id = role.sales_lead_id " );
        joinBfr.append( " AND LeadEO.customer_id = role.customer_id " );
        joinBfr.append( " AND LeadEO.primary_contact_party_id = role.contact_party_id " );
        joinBfr.append( " AND role.contact_role_code = ctrole.lookup_code " );
        joinBfr.append( " AND ctrole.lookup_type = 'ASN_CONTACT_ROLE' " );
        joinBfr.append( " AND ctrole.view_application_id = 0 " );
        joinBfr.append( " AND ctrole.language = USERENV('LANG')");
      }
      else
      {
        joinBfr.append( " AND LeadEO.sales_lead_id = role.sales_lead_id (+) " );
        joinBfr.append( " AND LeadEO.customer_id = role.customer_id (+) " );
        joinBfr.append( " AND LeadEO.primary_contact_party_id = role.contact_party_id (+) " );
        joinBfr.append( " AND role.contact_role_code = ctrole.lookup_code (+) " );
        joinBfr.append( " AND ctrole.lookup_type (+) = 'ASN_CONTACT_ROLE' " );
        joinBfr.append( " AND ctrole.view_application_id (+) = 0 " );
        joinBfr.append( " AND ctrole.language (+) = USERENV('LANG')");
      }
    }

    if(searchCriteria.containsKey("ASNLeadLstCtctRole"))
    {
      if(!(renderedVwAttrs.contains("ContactRole")))
      {
        fromBfr.append( " as_sales_lead_contacts role, " );
        joinBfr.append( " AND LeadEO.sales_lead_id = role.sales_lead_id " );
        joinBfr.append( " AND LeadEO.customer_id = role.customer_id " );
        joinBfr.append( " AND LeadEO.primary_contact_party_id = role.contact_party_id " );
      }
      
      ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstCtctRole");
      int size =  searchValues.size();
       for ( int i = 0; i < size; i++)
      {
        SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(i);
        filterBfr.append(" AND ");
        filterBfr.append(" role.contact_role_code ");
        filterBfr.append(srchCtaObj.getConditionOperator());
        filterBfr.append(":" + bindSequence ++);
        bindVariables.add(srchCtaObj.getValue());
      } //end loop
    }


    // Local Time zones
    if( (renderedVwAttrs.contains("ContactLocalTime")) ||
        (renderedVwAttrs.contains("ContactLocalTimeZone")) ||
        (searchCriteria.containsKey("ASNLeadLstCtctLclTm")) ||
        (searchCriteria.containsKey("ASNLeadLstCtctLclTmZn")))
        {
          fromBfr.append( " hz_contact_points hcplt," );

         if(searchCriteria.containsKey("ASNLeadLstCtctLclTmZn"))
          {
            joinBfr.append(" AND LeadEO.primary_contact_party_id = hcplt.owner_table_id");
               joinBfr.append(" AND hcplt.owner_table_name = 'HZ_PARTIES' ");
            joinBfr.append(" AND hcplt.primary_flag = 'Y' ");
            joinBfr.append(" AND hcplt.contact_point_type = 'PHONE' ");
          }
          else
          {
            joinBfr.append(" AND LeadEO.primary_contact_party_id = hcplt.owner_table_id(+)");
            joinBfr.append(" AND hcplt.owner_table_name (+) = 'HZ_PARTIES' ");
            joinBfr.append(" AND hcplt.primary_flag (+) = 'Y' ");
            joinBfr.append(" AND hcplt.contact_point_type (+) = 'PHONE' ");
          }

        // Local Time Zone
        if(searchCriteria.containsKey("ASNLeadLstCtctLclTmZn"))
        {
          ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstCtctLclTmZn");
          int size =  searchValues.size();
         for ( int i = 0; i < size; i++)
          { 
            SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(i);
            filterBfr.append(" AND ");
            filterBfr.append(" hcplt.timezone_id ");
            filterBfr.append(srchCtaObj.getConditionOperator());
            filterBfr.append(":" + bindSequence ++);
            bindVariables.add(srchCtaObj.getValue());
          } //end loop
        }

        // Local Time 
        if((renderedVwAttrs.contains("ContactLocalTime")) ||
          (renderedVwAttrs.contains("ContactLocalTimeZone")))
         {
          fromBfr.append( " hz_timezones ht, " );
          if(searchCriteria.containsKey("ASNLeadLstCtctLclTm"))
          {
            joinBfr.append( " AND hcplt.timezone_id = ht.timezone_id  " );
          }
          else
          {
            joinBfr.append( " AND hcplt.timezone_id = ht.timezone_id (+) " );
          }
        }
        
        if(searchCriteria.containsKey("ASNLeadLstCtctLclTm"))
        {
          // code the binding logic
          // Get all the Criteria Values for Local Time into an Array List
          ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstCtctLclTm");
          // Loop thru all the values in the Array List
          int size =  searchValues.size();
          for ( int i = 0; i < size; i++)
          { 
            // Get Search Criteria Object
            SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(i);

            // Get the Value in the Search Criteria Object
            String contactLocalTime = (String)srchCtaObj.getValue();

            // Check if the value exists
            if(contactLocalTime != null && (!("".equals(contactLocalTime.trim()))))
            {
              int ind = contactLocalTime.indexOf("-");
              if (ind != -1)
              {
                MessageToken[] messageToken3 = { new MessageToken("IDNAME",contactLocalTime.substring(0,ind) )};
                Number  beginTime =
                ASNUtil.stringToJboNumber(contactLocalTime.substring(0,ind), "ASN_CMMN_STR_TO_JBONUM_ERR", messageToken3);
                MessageToken[] messageToken4 = { new MessageToken("IDNAME",contactLocalTime.substring(ind+1) )};
                Number  endTime =
                        ASNUtil.stringToJboNumber(contactLocalTime.substring(ind+1), "ASN_CMMN_STR_TO_JBONUM_ERR", messageToken4);

                filterBfr.append(" AND hcplt.timezone_id  in (SELECT  timezone_id FROM hz_timezones_vl where hz_timezone_pub.convert_datetime (:"+ bindSequence++ +", timezone_id, SYSDATE) BETWEEN  TRUNC(SYSDATE)+ :"+ bindSequence++ +"/24 AND TRUNC(SYSDATE) + :"+bindSequence++ +"/24) ");
                bindVariables.add(serverTimeZoneId);
                bindVariables.add(beginTime);
                bindVariables.add(endTime);
              }
              else
              {
                ind = contactLocalTime.indexOf("<=");
                if (ind != -1)
                {
                  MessageToken[] messageToken3 = { new MessageToken("IDNAME",contactLocalTime.substring(0,ind) )};
                  Number  currLocalTime =
                  ASNUtil.stringToJboNumber(contactLocalTime.substring(0,ind+2), "ASN_CMMN_STR_TO_JBONUM_ERR", messageToken3);

                  filterBfr.append(" AND hcplt.timezone_id  in (SELECT  timezone_id FROM hz_timezones_vl where hz_timezone_pub.convert_datetime (:"+ bindSequence++ +", timezone_id, SYSDATE) <= TRUNC(SYSDATE)+ :"+ bindSequence++ +"/24");
                  bindVariables.add(serverTimeZoneId);
                  bindVariables.add(currLocalTime);
                }
                else
                {
                  ind = contactLocalTime.indexOf(">=");
                  if (ind != -1)
                  {
                    MessageToken[] messageToken3 = { new MessageToken("IDNAME",contactLocalTime.substring(0,ind) )};
                    Number  currLocalTime =
                    ASNUtil.stringToJboNumber(contactLocalTime.substring(0,ind+2), "ASN_CMMN_STR_TO_JBONUM_ERR", messageToken3);

                    filterBfr.append(" AND hcplt.timezone_id  in (SELECT  timezone_id FROM hz_timezones_vl where hz_timezone_pub.convert_datetime (:"+ bindSequence++ +", timezone_id, SYSDATE) >= TRUNC(SYSDATE)+ :"+ bindSequence++ +"/24");
                    bindVariables.add(serverTimeZoneId);
                    bindVariables.add(currLocalTime);
                  }
                  else
                  {
                    ind = contactLocalTime.indexOf("<");
                    if (ind != -1)
                    {
                      MessageToken[] messageToken3 = { new MessageToken("IDNAME",contactLocalTime.substring(0,ind) )};
                      Number  currLocalTime =
                      ASNUtil.stringToJboNumber(contactLocalTime.substring(0,ind+1), "ASN_CMMN_STR_TO_JBONUM_ERR", messageToken3);

                      filterBfr.append(" AND hcplt.timezone_id  in (SELECT  timezone_id FROM hz_timezones_vl where hz_timezone_pub.convert_datetime (:"+ bindSequence++ +", timezone_id, SYSDATE) < TRUNC(SYSDATE)+ :"+ bindSequence++ +"/24");
                      bindVariables.add(serverTimeZoneId);
                      bindVariables.add(currLocalTime);
                    }
                    else
                    {
                      ind = contactLocalTime.indexOf(">");
                      if (ind != -1)
                      {
                        MessageToken[] messageToken3 = { new MessageToken("IDNAME",contactLocalTime.substring(0,ind) )};
                        Number  currLocalTime =
                        ASNUtil.stringToJboNumber(contactLocalTime.substring(0,ind+1), "ASN_CMMN_STR_TO_JBONUM_ERR", messageToken3);

                        filterBfr.append(" AND hcplt.timezone_id  in (SELECT  timezone_id FROM hz_timezones_vl where hz_timezone_pub.convert_datetime (:"+ bindSequence++ +", timezone_id, SYSDATE) > TRUNC(SYSDATE)+ :"+ bindSequence++ +"/24");
                        bindVariables.add(serverTimeZoneId);
                        bindVariables.add(currLocalTime);
                      }
                      else
                      {
                        ind = contactLocalTime.indexOf("=");
                        if (ind != -1)
                        {
                          MessageToken[] messageToken3 = { new MessageToken("IDNAME",contactLocalTime.substring(0,ind) )};
                          Number  currLocalTime =
                          ASNUtil.stringToJboNumber(contactLocalTime.substring(0,ind+1), "ASN_CMMN_STR_TO_JBONUM_ERR", messageToken3);

                          filterBfr.append(" AND hcplt.timezone_id  in (SELECT  timezone_id FROM hz_timezones_vl where hz_timezone_pub.convert_datetime (:"+ bindSequence++ +", timezone_id, SYSDATE) = TRUNC(SYSDATE)+ :"+ bindSequence++ +"/24");
                          bindVariables.add(serverTimeZoneId);
                          bindVariables.add(currLocalTime);
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

    // Contact Address/Email Addr / Phone related info 
  
    if( renderedVwAttrs.contains("State") ||
       renderedVwAttrs.contains("City")||
        renderedVwAttrs.contains("Country")||
       renderedVwAttrs.contains("Province")||
       renderedVwAttrs.contains("PostalCode")||
      renderedVwAttrs.contains("EmailAddress")||
      renderedVwAttrs.contains("FormattedPhone") )
      {
        // ACCESS RELATIONSHIP RECORD IN HZ_PARTIES FOR CONTACTS ADDR/PHONE/EMAIL
        fromBfr.append(" hz_parties hcp,  ");
        joinBfr.append(" AND LeadEO.primary_contact_party_id = hcp.party_id(+) ");

        // In case of country, join with the fnd_territories_tl
        if(renderedVwAttrs.contains("Country"))        
        {
          fromBfr.append(" fnd_territories_tl ftt, ");
          joinBfr.append(" AND hcp.country = ftt.territory_code (+) ");
          joinBfr.append(" AND ftt.language (+) = USERENV('LANG') ");
        }
      }

      // For concatenated addr, need to call TCA api so join with hz_locations etc 
      if(renderedVwAttrs.contains("Address") )
      {
        if( renderedVwAttrs.contains("PersonId")|| 
          renderedVwAttrs.contains("FormattedPhone")|| 
          renderedVwAttrs.contains("EmailAddress")||
          renderedVwAttrs.contains("State") ||
            renderedVwAttrs.contains("City")||
          renderedVwAttrs.contains("Country")||
            renderedVwAttrs.contains("Province")||
            renderedVwAttrs.contains("PostalCode") )
          {
            fromBfr.append(" hz_locations hl, hz_party_sites hps, ");
          }
          else
          {
            fromBfr.append(" hz_locations hl, hz_party_sites hps,  ");    
          }
          joinBfr.append(" AND LeadEO.primary_contact_party_id = hps.party_id (+) ");
          joinBfr.append(" AND hps.identifying_address_flag(+) = 'Y' ");
          joinBfr.append(" AND hps.location_id = hl.location_id (+) ");
      }

      // Customer Details
      if( renderedVwAttrs.contains("CustomerState") ||
        renderedVwAttrs.contains("CustomerCity")||
        renderedVwAttrs.contains("CustomerCountry")||
        renderedVwAttrs.contains("CustomerProvince")||
        renderedVwAttrs.contains("CustomerPostalCode")||
        renderedVwAttrs.contains("CustomerAddress"))
      {
        if(searchCriteria.containsKey("ASNLeadLstCustCntry"))
        {
          fromBfr.append(" hz_locations hlcust, hz_party_sites hpscust, ");
          joinBfr.append(" AND LeadEO.address_id = hpscust.party_site_id ");
          joinBfr.append(" AND hpscust.location_id = hlcust.location_id  ");

          // In case of country, join with the fnd_territories_tl
          if(renderedVwAttrs.contains("CustomerCountry"))        
          {
            fromBfr.append(" fnd_territories_tl fttcust, ");
            joinBfr.append(" AND hlcust.country = fttcust.territory_code  ");
            joinBfr.append(" AND fttcust.language  = USERENV('LANG') ");          
          }
        }
        else
        {
          fromBfr.append(" hz_locations hlcust, hz_party_sites hpscust, ");
          joinBfr.append(" AND LeadEO.address_id = hpscust.party_site_id(+) ");
          joinBfr.append(" AND hpscust.location_id = hlcust.location_id(+) ");

          // In case of country, join with the fnd_territories_tl
          if(renderedVwAttrs.contains("CustomerCountry"))        
          {
            fromBfr.append(" fnd_territories_tl fttcust, ");
            joinBfr.append(" AND hlcust.country = fttcust.territory_code(+) ");
            joinBfr.append(" AND fttcust.language(+) = USERENV('LANG') ");
          }
        }
      }

      if(searchCriteria.containsKey("ASNLeadLstCustCntry"))
      {
        ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstCustCntry");
        int size =  searchValues.size();
        for ( int i = 0; i < size; i++)
        { 
          SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(i);
          filterBfr.append(" AND  ");         
          filterBfr.append(" LeadEO.country ");
          filterBfr.append(srchCtaObj.getConditionOperator());
          filterBfr.append(":" + bindSequence ++);
          bindVariables.add(((String)srchCtaObj.getValue()));
        }
      }

    // Start of Product Category & Inventory Item Search Logic
    // Note :Add Organization Id also
    // As, User might select either a Product Category or an Inventory Item,
    // We check for the following 3 form value fields :
    // 1. ASNLeadLstPrdtCtgId
    // 2. ASNLeadPrdtInvItmId
    // 3. ASNLeadLstPrdtInvOrgId
  
    if(searchCriteria.containsKey("ASNLeadLstPrdtCtgId"))
    {
       ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstPrdtCtgId");
      if(searchCriteria.containsKey("ASNLeadLstPrdtInvItmId"))
      {
        String InvItem =null;
       ArrayList searchValuesInv = (ArrayList)searchCriteria.get("ASNLeadLstPrdtInvItmId");
         for ( int i = 0; i < searchValuesInv.size(); i++)
        { 
          SearchCriteria srchCtaObjInv =(SearchCriteria)searchValuesInv.get(i);
          InvItem = (String)srchCtaObjInv.getValue();
        }

        if( ("-1").equals(InvItem)||
            !(searchCriteria.containsKey("ASNLeadLstPrdtInvItmId")))
        {
          //ArrayList searchValues = (ArrayList)searchCriteria.get("ASNLeadLstPrdtCtgId");
          filterBfr.append(" AND LeadEO.sales_lead_id in ");
          filterBfr.append(" (Select al.sales_lead_id from "); 
          filterBfr.append("  AS_SALES_LEAD_LINES AL,ENI_PROD_DENORM_HRCHY_V Prd ");
          filterBfr.append(" Where LeadEO.Sales_Lead_Id = AL.Sales_Lead_Id  ");
          filterBfr.append(" AND AL.CATEGORY_ID = Prd.CHILD_ID ");
          filterBfr.append(" AND AL.CATEGORY_SET_ID = Prd.CATEGORY_SET_ID ");

          int size =  searchValuesInv.size();
          for ( int i = 0; i < size; i++)
          { 
            SearchCriteria srchCtaObj =(SearchCriteria)searchValues.get(i);
            // filterBfr.append(" AND ");
            filterBfr.append(" AND  ");
            filterBfr.append(" prd.PARENT_ID  ");
            filterBfr.append(srchCtaObj.getConditionOperator());
            filterBfr.append(":" + bindSequence ++);
            bindVariables.add(srchCtaObj.getValue());
            filterBfr.append(" ) ");         
          } //end loop
        }
      }
    }

    if(searchCriteria.containsKey("ASNLeadLstPrdtInvItmId"))
    {
      ArrayList searchValues1 = (ArrayList)searchCriteria.get("ASNLeadLstPrdtInvItmId");
      // ArrayList searchValues2 = (ArrayList)searchCriteria.get("ASNLeadLstPrdtInvOrgId");

      int size =  searchValues1.size();
      for ( int i = 0; i < size; i++)
      {
        // get the value of the Inventory Item Id
        SearchCriteria srchCtaObj1 =(SearchCriteria)searchValues1.get(i);
        // get the value of the corresponding Organization Id
        // SearchCriteria srchCtaObj2 =(SearchCriteria)searchValues2.get(i);

        String invItem = (String)srchCtaObj1.getValue();
          // filterBfr.append(" " + srchCtaObj.getJoinCondition() + " ");
        if(!(("-1").equals(invItem)))
         {
           filterBfr.append(" AND LeadEO.sales_lead_id in ");
           filterBfr.append(" (Select al.sales_lead_id from "); 
           filterBfr.append("  AS_SALES_LEAD_LINES AL ");
           filterBfr.append(" where LeadEO.Sales_Lead_Id = al.sales_lead_id  ");
           // filterBfr.append(" AND AL.inventory_item_id = :"+ bindSequence++ +" AND AL.organization_id = :"+ bindSequence++);
           filterBfr.append(" AND AL.inventory_item_id = :"+ bindSequence++ );
           // Bind the value of Inventory Item Id
           bindVariables.add(srchCtaObj1.getValue());
           // Bind the value of Organization Id
           // bindVariables.add(srchCtaObj2.getValue());
          filterBfr.append(" ) ");
         }
      } //end loop
    }

    // Dashboard Changes
    if(dshBdSrchParams != null)
    {
      // Date variables to be used to convert the Age into date
      Date  date = new Date();
      Date dashAgeDate = (Date) date.getCurrentDate();
      Date dashBeginDate = (Date) date.getCurrentDate();
      Date dashEndDate = (Date) date.getCurrentDate();

      // Check if the Parameter passed from Leads Bin of Dashboard
      // requires the display of Leads within specific Age
      if(dshBdSrchParams.containsKey("ASNSrchLnkAgeDays"))
      {
        String ageDays = (String)dshBdSrchParams.get("ASNSrchLnkAgeDays");

        Integer intAgeDays = new Integer(ageDays);
        dashAgeDate = (Date) dashAgeDate.addJulianDays(-intAgeDays.intValue(),0);
        filterBfr.append(" AND TRUNC(LeadEO.creation_date) >= :"+ bindSequence++ );
        bindVariables.add(dashAgeDate);
      }

      // Check if the Parameter passed from Leads Bin of Dashboard
      // requires the display of Leads for a specific Rank Id passed
      if(dshBdSrchParams.containsKey("ASNSrchLnkRank"))
      {
        String rankId = (String)dshBdSrchParams.get("ASNSrchLnkRank");
        filterBfr.append(" AND "); 
        filterBfr.append(" LeadEO.lead_rank_id ");
        filterBfr.append(" = ");
        filterBfr.append(":" + bindSequence ++);
        bindVariables.add(rankId);
      }

      // Check if the Parameter passed from Leads Bin of Dashboard
      // requires the display of Leads in Open Status and created within last 2 days
      if(dshBdSrchParams.containsKey("ASNSrchLnkOp2"))
      {
        dashEndDate = (Date) dashEndDate.addJulianDays(-2,0);
        filterBfr.append(" AND TRUNC(LeadEO.creation_date) >= :"+ bindSequence++ );
        bindVariables.add(dashEndDate);
        StatusOpenFlag = "Y";
      }

      // Check if the Parameter passed from Leads Bin of Dashboard
      // requires the display of Leads in Open Status and created between last 3 and 7 days
      if(dshBdSrchParams.containsKey("ASNSrchLnkOp3to7"))
      {
        // converting the age into the past date relative to the system date
        dashBeginDate = (Date) dashBeginDate.addJulianDays(-3,0);     
        dashEndDate = (Date) dashEndDate.addJulianDays(-7,0);
        filterBfr.append(" AND TRUNC(LeadEO.creation_date) <= :"+ bindSequence++ );
        filterBfr.append(" AND TRUNC(LeadEO.creation_date) >= :"+ bindSequence++ );
        bindVariables.add(dashBeginDate);
        bindVariables.add(dashEndDate);
        StatusOpenFlag = "Y";
      }

      // Check if the Parameter passed from Leads Bin of Dashboard
      // requires the display of Leads in Open Status and created between last 8 and 30 days
      if(dshBdSrchParams.containsKey("ASNSrchLnkOp8to30"))
      {
        // converting the age into the past date relative to the system date
        dashBeginDate = (Date) dashBeginDate.addJulianDays(-8,0);     
        dashEndDate = (Date) dashEndDate.addJulianDays(-30,0);
        filterBfr.append(" AND TRUNC(LeadEO.creation_date) <= :"+ bindSequence++ );
        filterBfr.append(" AND TRUNC(LeadEO.creation_date) >= :"+ bindSequence++ );
        bindVariables.add(dashBeginDate);
        bindVariables.add(dashEndDate);
        StatusOpenFlag = "Y";
      }

      // Check if the Parameter passed from Leads Bin of Dashboard
      // requires the display of Leads in Open Status and created more than 30 days ago
      if(dshBdSrchParams.containsKey("ASNSrchLnkOp31"))
      {
        dashEndDate = (Date) dashEndDate.addJulianDays(-31,0);
        filterBfr.append(" AND TRUNC(LeadEO.creation_date) <= :"+ bindSequence++ );
        bindVariables.add(dashEndDate);
        StatusOpenFlag = "Y";
      }

      // Check if the Parameter passed from Leads Bin of Dashboard
      // requires the display of Leads that are in Close Status
      if(dshBdSrchParams.containsKey("ASNSrchLnkClosed"))
      {
        joinBfr.append( "  AND LeadEO.status_code <> 'CONVERTED_TO_OPPORTUNITY'  " );
        // joinBfr.append( "  AND NVL(LeadEO.status_open_flag, 'N') = 'N'  " );
        StatusOpenFlag = "N";
      }

      // Check if the Parameter passed from Leads Bin of Dashboard
      // requires the display of Leads that are Converted to Opportunity
      if(dshBdSrchParams.containsKey("ASNSrchLnkCnvtd"))
      {
        joinBfr.append( "  AND LeadEO.status_code = 'CONVERTED_TO_OPPORTUNITY'  " );
      }

      // Parameters Passed from Sales campaign Bin of Dashboard

      // Check if the Parameter passed from Leads Bin of Dashboard
      // requires the display of Leads that come under a Campaign Schedule
      // Parameter we get is a Campaign Schedule Id associated with the Lead

      if(dshBdSrchParams.containsKey("ASNSrchLnkSrcPrmId"))
      {
        String tSourcePromotionId = (String)dshBdSrchParams.get("ASNSrchLnkSrcPrmId");
        filterBfr.append(" AND LeadEO.source_promotion_id = :");
        filterBfr.append(bindSequence++);
        bindVariables.add(tSourcePromotionId);
      }

      // Check if the Parameter passed from Leads Bin of Dashboard
      // requires the display of Leads with No Action
      if(dshBdSrchParams.containsKey("ASNSrchLnkNoAct"))
      {
        filterBfr.append( "  AND LeadEO.status_code = " );
        filterBfr.append(":" + bindSequence++);
        bindVariables.add(defaultLeadStatus);
      }

      // Check if the Parameter passed from Leads Bin of Dashboard
      // requires the display of Leads that are in Progress
      if(dshBdSrchParams.containsKey("ASNSrchLnkInPgs"))
      {
        filterBfr.append( "  AND LeadEO.status_code != " );
        filterBfr.append(":" + bindSequence++);
        bindVariables.add(defaultLeadStatus);

        // joinBfr.append( "  AND LeadEO.status_code != 'CONVERTED_TO_OPPORTUNITY' " );
        // joinBfr.append( "  AND LeadEO.status_open_flag = 'Y'  " );
        StatusOpenFlag = "Y";
      }

      // Check if the Parameter passed from Leads Bin of Dashboard
      // requires the display of Leads that are DEAD
      if(dshBdSrchParams.containsKey("ASNSrchLnkDead"))
      {
        joinBfr.append( "  AND LeadEO.status_code != 'CONVERTED_TO_OPPORTUNITY' " );
        // joinBfr.append( "  AND NVL(LeadEO.status_open_flag, 'N') = 'N'  " );
        StatusOpenFlag = "N";
      }
    }

    // Building the Final From & Where Clauses
    fromClause    = fromBfr.toString();
    joinClause    = joinBfr.toString();
    filterClause  = filterBfr.toString();

    whereClause = joinClause + filterClause;
    fromClause  = fromClause.trim();

    // check  whether the FROM clause ends-with ", ", If so, remove it
    if(fromClause.endsWith(",")) 
    {
      //remove ", " from the end of the from Clause
      fromClause = fromClause.substring(0, (fromClause.length()-1));
    }
    
    if(Refresh == false)
    // if (!("Y".equals(Refresh)))
    {
      fromClause = fromClause + securityFromBfr.toString();
      whereClause = securityWhereClause + " " +whereClause;
    }

    // check  whether the WHERE clause begins-with "AND "
    whereClause = whereClause.trim();
    if(whereClause.startsWith("AND "))
    {
      // remove "AND " from the beginning of the whereClause
      whereClause = whereClause.substring(3);
      // whereClause = whereClause.replaceFirst("AND ", " ");
    }

  }

  // Refresh Row Logic
  // Updating the Fields on Details Region should update the corresponding attributes
  // on the Results Table.
  // Lead Name, Lead Number and Budget Amount being EO based attributes

  public void getLeadUwqRefreshVO( OAApplicationModuleImpl oam,
                                    ArrayList mRenderedVwAttrs,
                                    Number salesLeadId)  
  
   {  
     // get the LeadSearchVO
    OAViewObjectImpl LeadVO = (OAViewObjectImpl)oam.findViewObject("LeadSearchVO2");
   
    renderedVwAttrs = mRenderedVwAttrs;
   

    Refresh = true;
    // Refresh = "Y";
  
    // build the SELECT clause
    constructSelectClause(LeadVO);

    final String METHOD_NAME = "asn.lead.server.LeadSearchManager.getLeadUwqRefreshVO";

    OADBTransaction trxn = oam.getOADBTransaction();
    boolean isProcLogEnabled = trxn.isLoggingEnabled(OAFwkConstants.PROCEDURE);

    HashMap miscSrchParams =null;  
    HashMap dshBdSrchParams = null;  
    String accessType = null;

     // build the FROM and WHERE clause
    constructFromWhereClause(   oam,
                                dshBdSrchParams, 
                                 miscSrchParams);

    String finalSql = "SELECT " + selectClause;
    finalSql = finalSql + " FROM " + fromClause;
    finalSql = finalSql + " WHERE " + whereClause;
    // finalSql = finalSql + " " + orderByClause;

    // Logging Start
    if (isProcLogEnabled)
    {
     StringBuffer  logBuf = new StringBuffer(500)
                           .append(" ==== Final SQL Query ====")
                           .append("Query is " ).append(finalSql)
                           .append("Bind variables = ").append(bindVariables);
                           
     trxn.writeDiagnostics(METHOD_NAME,  logBuf.toString(), OAFwkConstants.PROCEDURE);
    }
    
    finalSql = finalSql + " AND LeadEO.sales_lead_id = "+":" + bindSequence ++;
    bindVariables.add(salesLeadId);

    //    Serializable [] sql_uwq_Params = {finalSql.toString()};
    LeadVO.setOrderByClause(null);   
    LeadVO.setQuery(finalSql);

     // bind the varaibles
    LeadVO.setWhereClauseParams(null);

    if(bindVariables!= null && bindVariables.size() > 0)
    {
      for  (int i = 0; i < bindVariables.size(); i++)
      {
        LeadVO.setWhereClauseParam(i, bindVariables.get(i));
      }
    }

    //OpptyVO.setFullSqlMode(OAViewObjectImpl.FULLSQL_MODE_AUGMENTATION);
  }
}
