/*=================================================================================+

 |                       Office Depot - Project Simplify                             |

 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                 |

 +===================================================================================+

 |  FILENAME                                                                         |

 |             ODCustomerQueryCO.java                                                |

 |                                                                                   |

 |  DESCRIPTION                                                                      |

 |    Query Region Controller class for the customer Search Page                     |

 |                                                                                   |

 | Subversion Info:

 | $HeadURL$

 | $Rev$

 | $Date$

 |  NOTES                                                                            |

 |         Used for the Customer Search Page                                         |

 |                                                                                   |

 |  DEPENDENCIES                                                                     |

 |    No dependencies.                                                               |

 |                                                                                   |

 |  HISTORY                                                                          |

 |                                                                                   |

 |   17-Mar-2008 Jasmine Sujithra   Created                                          |

 |   02-Apr-2008 Jasmine Sujithra   Added Sales Rep                                  |

 |   03-Apr-2008 Jasmine Sujithra   Updated for Classification and Ship to           |

 |   09-Apr-2008 Jasmine Sujithra   Updated for performance-order of clause          |

 |   14-Apr-2008 Jasmine Sujithra   Updated for duplicate criteria message           |

 |   16-Apr-2008 Anirban Chaudhuri  Mandating criteria check for unsecured user      |

 |   16-Apr-2008 Anirban Chaudhuri  Changed Union all to Union for PERF reasons      |

 |   28-Apr-2008 Anirban Chaudhuri  Removed Hint from ShipToSequenceNum extra clause |

 |   29-Apr-2008 Jasmine Sujithra   Changed view XX_TM_NAM_TERR_CURR_ASSIGN_V        |

 |   30-Apr-2008 Jasmine Sujithra   Updated for UPPER(Contact Name)                  |

 |   30-May-2008 Jasmine Sujithra   Updated for Phone Number                         |

 |   04-Jun-2008 Jasmine Sujithra   Changed Phone No clause to use the index         |

 |   12-Jun-2008 Jasmine Sujithra   Changed Contact clause to use a hint             |

 |   10-Jul-2008 Anirban Chaudhuri  PERF modification to remove hint for ContactName |

 |   18-Sep-2008 Anirban Chaudhuri  Modified 'LegacyNumber' extra where clause       |

 |   10-Oct-2008 Anirban Chaudhuri  PERF suggestion for adding hint implemented      |

 |   29-Apr-2009 Anirban Chaudhuri  Fixed PERF defect#14427                          |

 |   05-Jan-2010 Annapoorani Rajaguru Fixed defect#2264                              |
 |   12-Apr-2010 Indra Varada         Fix for Defect#4338                            |	

 +===================================================================================*/

package od.oracle.apps.xxcrm.asn.custsrch.common.customer.webui;



import oracle.apps.fnd.common.VersionInfo;



import oracle.apps.fnd.framework.webui.OAPageContext;

import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import oracle.apps.fnd.framework.webui.beans.layout.OAQueryBean;

import java.util.Dictionary;

import oracle.apps.fnd.framework.OAViewObject;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.apps.fnd.framework.OAApplicationModule;

import oracle.apps.fnd.framework.OAFwkConstants;

import od.oracle.apps.xxcrm.asn.common.fwk.webui.ODASNControllerObjectImpl;

import com.sun.java.util.collections.ArrayList;

import oracle.apps.fnd.framework.OAException;

import com.sun.java.util.collections.HashMap;





/**

 * Controller for ...

 */

public class ODCustomerQueryCO extends ODASNControllerObjectImpl

{

  public static final String RCS_ID="$Header$";

  public static final boolean RCS_ID_RECORDED =

        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");





    //oracle.jbo.domain.Number

    String SalesRepId = null;

    String ClassCode = null;

    String ClassCategory = null;
    
    



  /**

   * Layout and page setup logic for a region.

   * @param pageContext the current OA page context

   * @param webBean the web bean corresponding to the region

   */

  public void processRequest(OAPageContext pageContext, OAWebBean webBean)

  {

      final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.custsrch.common.customer.webui.ODCustomerQueryCO.processRequest";

      boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);

      if (isProcLogEnabled)

      {

        pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);

      }

      super.processRequest(pageContext, webBean);

      OAQueryBean queryBean = (OAQueryBean) webBean;



      String currentPanel = queryBean.getCurrentSearchPanel();

      String switchPanel =(String)pageContext.getSessionValue("ASNTxnSwitchPanel");

      if(switchPanel== null || "".equals(switchPanel))

      {

        switchPanel = "DONE";

      }



      // If you are on the views panel, handle the criteria

      // for the default personalization



      pageContext.writeDiagnostics(METHOD_NAME, "Current Panel Before switch is : "+currentPanel, OAFwkConstants.PROCEDURE);

      if(CUSTOMIZE.equals(currentPanel) && switchPanel.equals("YES"))

      {

        queryBean.setCurrentSearchPanel(SEARCH);

        pageContext.removeSessionValue("ASNTxnSwitchPanel");

        pageContext.putSessionValue("ASNTxnSwitchPanel","DONE");

        currentPanel = queryBean.getCurrentSearchPanel();

        pageContext.writeDiagnostics(METHOD_NAME, "Current Panel After switch is : "+currentPanel, OAFwkConstants.PROCEDURE);

      }



      String viewId = (String)queryBean.getAttributeValue(CUST_ANVR_VIEWID);



      if (((CUSTOMIZE.equals(currentPanel) ) && queryBean.getDefaultCustomization() != null) ||viewId != null )

      {

            pageContext.writeDiagnostics(METHOD_NAME, "Before Calling handleCriteria for default View", OAFwkConstants.PROCEDURE);



            /* Include pre validation criteria*/

            String custAccess = null;

            custAccess = pageContext.getProfile("ASN_CUST_ACCESS");

			if(custAccess == null || "".equals(custAccess.trim()))

               custAccess = "S";

            pageContext.writeDiagnostics(METHOD_NAME, "ASN_CUST_ACCESS : "+custAccess, OAFwkConstants.STATEMENT);

            boolean flag3 = isLoginResourceManager(pageContext.getApplicationModule(webBean), pageContext);





            boolean mainValidationCheck = false;

           // if(!"F".equals(custAccess) && !flag3)

           mainValidationCheck = preValidationCheck (pageContext, webBean,custAccess);

           if(!mainValidationCheck)

           {

                pageContext.writeDiagnostics(METHOD_NAME, "mainValidationCheck returned false : ", OAFwkConstants.STATEMENT);

                OAException e = new OAException("XXCRM", "XX_SFA_090_WILD_CARD_SEARCH");

                throw(e);

           }

           String securityClause = getSecurityRestrictiveSql(pageContext, webBean);

           //handleCriteria (pageContext, webBean,securityClause);

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

    final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.custsrch.common.customer.webui.ODCustomerQueryCO.processFormRequest";

    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);

    if (isProcLogEnabled)

    {

      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);

    }

    super.processFormRequest(pageContext, webBean);





    OAQueryBean queryBean = (OAQueryBean) webBean;





    String currentPanel = queryBean.getCurrentSearchPanel();

    // if you are on the search or the advanced search panels,

    // handle the criteria on the Go button press.

    pageContext.writeDiagnostics(METHOD_NAME, "Current Panel is : "+currentPanel, OAFwkConstants.PROCEDURE);

    String custAccess = null;

    custAccess = pageContext.getProfile("ASN_CUST_ACCESS");

	if(custAccess == null || "".equals(custAccess.trim()))

       custAccess = "S";

    pageContext.writeDiagnostics(METHOD_NAME, "ASN_CUST_ACCESS : "+custAccess, OAFwkConstants.STATEMENT);

    boolean flag3 = isLoginResourceManager(pageContext.getApplicationModule(webBean), pageContext);



    if ((SEARCH.equals(currentPanel) || ADVANCED_SEARCH.equals(currentPanel) )&&pageContext.getParameter(queryBean.getGoButtonName())   != null)

    {

        pageContext.writeDiagnostics(METHOD_NAME, "Inside Search Panel  ", OAFwkConstants.STATEMENT);

        pageContext.writeDiagnostics(METHOD_NAME, "Go Button name is :  "+ pageContext.getParameter(queryBean.getGoButtonName()) , OAFwkConstants.STATEMENT);

        if(pageContext.getParameter(queryBean.getGoButtonName())   != null)

        {

            pageContext.writeDiagnostics(METHOD_NAME, "Go Button is pressed ", OAFwkConstants.STATEMENT);

        }



        /* Include pre validation criteria*/



        boolean mainValidationCheck =false;

        mainValidationCheck = preValidationCheck (pageContext, webBean,custAccess);

        if(!mainValidationCheck)

        {

            pageContext.writeDiagnostics(METHOD_NAME, "mainValidationCheck returned false : ", OAFwkConstants.STATEMENT);

            OAException e = new OAException("XXCRM", "XX_SFA_090_WILD_CARD_SEARCH");

            throw(e);

        }

        String securityClause = getSecurityRestrictiveSql(pageContext, webBean);

        handleCriteria (pageContext, webBean,securityClause);

    }



      // button press.

    if (CUSTOMIZE.equals(currentPanel) &&   pageContext.getParameter(queryBean.getPersonalizeGoButtonName()) != null)

    {

        pageContext.writeDiagnostics(METHOD_NAME, "Inside the Views Panel : ", OAFwkConstants.STATEMENT);

        /* Include pre validation criteria*/



        boolean mainValidationCheck =false;

        mainValidationCheck = preValidationCheck (pageContext, webBean,custAccess);

        if(!mainValidationCheck)

        {

            pageContext.writeDiagnostics(METHOD_NAME, "mainValidationCheck returned false : ", OAFwkConstants.STATEMENT);

            OAException e = new OAException("XXCRM", "XX_SFA_090_WILD_CARD_SEARCH");

            throw(e);

        }

        String securityClause = getSecurityRestrictiveSql(pageContext, webBean);

        handleCriteria (pageContext, webBean,securityClause);

    }



    if (isProcLogEnabled)

    {

      pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);

    }



  }



  public void handleCriteria (OAPageContext pageContext, OAWebBean webBean, String securityClause)

  {

    final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.custsrch.common.customer.webui.ODCustomerQueryCO.handleCriteria";

    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);

    if (isProcLogEnabled)

    {

      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);

    }

    OAQueryBean queryBean = (OAQueryBean) webBean;



    //String whereClause = "1=1 ";

    String whereClause = "";

    int clauseCount =0;



    pageContext.writeDiagnostics(METHOD_NAME, "securityClause = "+securityClause, OAFwkConstants.STATEMENT);

    if(securityClause!=null && !"".equals(securityClause.trim()))

    {

      //whereClause = whereClause + " AND " + securityClause;

      whereClause = securityClause ;

      clauseCount = clauseCount +1;

    }

    else

    {

      pageContext.writeDiagnostics(METHOD_NAME, "securityClause is null ", OAFwkConstants.STATEMENT);

    }

    //Annapoorani 05-Jan-10 starts. Defect#2264
    String CustTypeProfile = pageContext.getProfile("XX_SFA_EXCLUDE_INT_CUST");
    if (CustTypeProfile.equalsIgnoreCase("Y"))
    	{
       if (clauseCount >0)
              {
			whereClause = whereClause + " AND ";
              }
      whereClause = whereClause + " NVL(QRSLT.CUSTOMER_TYPE,'R') <> 'I' ";
      clauseCount = clauseCount +1;
      }
    //Annapoorani 05-Jan-10 ends. Defect#2264

    // This gives you the current non-view attribute criteria

    Dictionary[] dic = queryBean.getNonViewAttrCriteria(pageContext);



    // If the dictionary is empty, then it means that no non-view criteria

    // is available, so return.

    if (dic == null )//|| dic.isEmpty())

    {

       pageContext.writeDiagnostics(METHOD_NAME, "getNonViewAttrCriteria Dictionary is null", OAFwkConstants.PROCEDURE);

       return;

    }



    pageContext.writeDiagnostics(METHOD_NAME, "Dictionary is not null", OAFwkConstants.PROCEDURE);

    // Otherwise process the dictionary to build your where clause.

    int dictSize = dic.length;



    // Iterate through the dictionary to set your where clauses

    for (int i=0; i < dictSize; i++)

    {

        // Item for which the criteria is defined.

        String itemName = (String) dic[i].get(OAViewObject.CRITERIA_ITEM_NAME);

        pageContext.writeDiagnostics(METHOD_NAME, "itemName = "+itemName, OAFwkConstants.STATEMENT);

        // Condition is the SQL condition - examples: like , = etc



        String condition = (String) dic[i].get(OAViewObject.CRITERIA_CONDITION);

        pageContext.writeDiagnostics(METHOD_NAME, "condition = "+condition, OAFwkConstants.STATEMENT);



        // Value is the value entered with the appropriate % based on condition

        Object value = dic[i].get(OAViewObject.CRITERIA_VALUE);

        pageContext.writeDiagnostics(METHOD_NAME, "value = "+value, OAFwkConstants.STATEMENT);



        // Join condition is either AND or OR depending on what user chooses

        String joinCondition = (String) dic[i].get(OAViewObject.CRITERIA_JOIN_CONDITION);

        pageContext.writeDiagnostics(METHOD_NAME, "joinCondition 1 = "+joinCondition, OAFwkConstants.STATEMENT);



        if(joinCondition == null || "".equals(joinCondition))

            joinCondition = "AND";

        else

            joinCondition = joinCondition.toUpperCase();



        pageContext.writeDiagnostics(METHOD_NAME, "joinCondition 2 = "+joinCondition, OAFwkConstants.STATEMENT);





       // Now use the above information to build your where clause.



         if (itemName.equals("ResultsFlag"))

        {

            if (value.equals("PARTY%")||value.equals("PARTY"))

            {

              if (clauseCount >0)

              {

                //if(joinCondition.equals("AND") )

                  whereClause = whereClause + " AND ";

                //else

                  //whereClause = whereClause + " OR ";

              }

              whereClause = whereClause + " QRSLT.identifying_address_flag = 'Y' ";

              clauseCount = clauseCount +1;

            }

        }



        if (itemName.equals("ActiveFlag"))

        {

          if (clauseCount >0)

          {

              //if(joinCondition.equals("AND") )

                whereClause = whereClause + " AND ";

              //else

                //whereClause = whereClause + " OR ";

          }

          if(value.equals("ACTIVE"))

          {

            whereClause = whereClause + " QRSLT.PARTY_STATUS = 'A' AND QRSLT.SITE_STATUS ='A' ";

            clauseCount = clauseCount +1;

          }

          else if (value.equals("INACTIVE"))

          {

            whereClause = whereClause + " QRSLT.PARTY_STATUS = 'I' AND QRSLT.SITE_STATUS ='I' ";

            clauseCount = clauseCount +1;

          }

          else

          {

            whereClause = whereClause + " QRSLT.PARTY_STATUS IN( 'A','I') AND QRSLT.SITE_STATUS IN ('A','I') ";

            clauseCount = clauseCount +1;

          }



        }

        if (itemName.equals("NoOfRows"))

        {

          if (clauseCount >0)

          {

            //if(joinCondition.equals("AND"))

                whereClause = whereClause + " AND ";

            //else

                //whereClause = whereClause + " OR ";

          }

          whereClause = whereClause + "ROWNUM <= "+value + " AND  1=1 ";

          clauseCount = clauseCount +1;

        }



        if (itemName.equals("PartyNumber"))

        {

          if (clauseCount >0)

          {

            if(joinCondition.equals("AND") )

                whereClause = whereClause + " AND ";

            else

                whereClause = whereClause + " OR ";

          }

          whereClause = whereClause + " QRSLT.party_number "+condition+ " '"+ value +"'";

          clauseCount = clauseCount +1;

        }



        if (itemName.equals("ContactName"))

        {

            if (clauseCount >0)

            {

              if(joinCondition.equals("AND") )

                whereClause = whereClause + " AND ";

              else

                whereClause = whereClause + " OR ";

            }

          //whereClause = whereClause + " EXISTS(select 1 from hz_parties person, hz_relationships hzr where hzr.subject_type = 'ORGANIZATION' AND   hzr.subject_id = QRSLT.party_id AND   person.party_id = hzr.object_id AND  hzr.RELATIONSHIP_CODE = 'CONTACT' AND hzr.object_type = 'PERSON' AND UPPER(person.party_name) " + condition + " UPPER('"+value+"')) ";

          whereClause = whereClause + " EXISTS(select 1 from hz_parties person, hz_relationships hzr where hzr.subject_type = 'ORGANIZATION' AND hzr.subject_id = QRSLT.party_id AND person.party_id = hzr.object_id AND hzr.RELATIONSHIP_CODE = 'CONTACT' AND hzr.object_type = 'PERSON' AND UPPER(person.party_name) " + condition + " UPPER('"+value+"')) ";



          clauseCount = clauseCount +1;

        }

        if (itemName.equals("Classification"))

        {

          if (clauseCount >0)

          {

            if(joinCondition.equals("AND") )

                whereClause = whereClause + " AND ";

            else

                whereClause = whereClause + " OR ";

          }

          //whereClause = whereClause + " EXISTS (select 1 from hz_code_assignments a, ar_lookups b where a.owner_table_name = 'HZ_PARTIES' AND   a.owner_table_id = QRSLT.party_id AND   a.class_code = b.lookup_code AND   a.class_category = b.lookup_type AND   a.status = 'A'  AND   (a.class_category || ', ' || b.meaning) = '"+value+"') ";

          whereClause = whereClause + " EXISTS (select 1 from hz_code_assignments a where a.owner_table_name = 'HZ_PARTIES' AND   a.owner_table_id = QRSLT.party_id AND   a.status = 'A'    AND  a.class_category = '"+ClassCategory+"' AND a.class_code = '"+ClassCode+"')";

          clauseCount = clauseCount +1;

        }

         if (itemName.equals("BillingNumber"))

        {

            if (clauseCount >0)

            {

              if(joinCondition.equals("AND") )

                whereClause = whereClause + " AND ";

            else

                whereClause = whereClause + " OR ";

            }

          whereClause = whereClause + "EXISTS (select 1 from hz_cust_accounts hca  where  hca.party_id = QRSLT.party_id  AND status = 'A'  AND hca.account_number "+ condition + " '"+ value +"') ";

          clauseCount = clauseCount +1;

        }

         if (itemName.equals("RelationshipRole"))

        {

          if (clauseCount >0)

          {

            if(joinCondition.equals("AND") )

                whereClause = whereClause + " AND ";

            else

                whereClause = whereClause + " OR ";

          }

          //whereClause = whereClause + "EXISTS (select 1 from hz_relationships a where a.OBJECT_TYPE = 'ORGANIZATION'AND   a.object_id = QRSLT.party_id AND   a.RELATIONSHIP_CODE =  '"+ value +"') ";

          whereClause = whereClause + "exists (select   1 from hz_relationships a where a.object_id = qrslt.party_id and 1=1 and a.OBJECT_TYPE = 'ORGANIZATION' and substr(a.RELATIONSHIP_CODE,1,length('"+value+"')) = '"+ value +"')";



          clauseCount = clauseCount +1;

        }

        if (itemName.equals("CustomerCategory"))

        {

          if (clauseCount >0)

          {

            if(joinCondition.equals("AND") )

                whereClause = whereClause + " AND ";

            else

                whereClause = whereClause + " OR ";

          }

          whereClause = whereClause + "EXISTS (SELECT 1 FROM fnd_lookup_values FNDL WHERE FNDL.lookup_code = QRSLT.category_code AND FNDL.lookup_type='CUSTOMER_CATEGORY' AND FNDL.meaning " +condition+ " '"+ value +"'  ) ";

          clauseCount = clauseCount +1;

        }

        if (itemName.equals("OdCustomerType"))

        {

          if (clauseCount >0)

          {

            if(joinCondition.equals("AND") )

                whereClause = whereClause + " AND ";

            else

                whereClause = whereClause + " OR ";

          }

          whereClause = whereClause + "EXISTS (SELECT   1 FROM  hz_cust_accounts HZCA WHERE HZCA.party_id = QRSLT.party_id AND HZCA.attribute18 "+condition+ " '"+ value +"') ";

          clauseCount = clauseCount +1;

        }

        if (itemName.equals("ShipToSequenceNum"))

        {

          if (clauseCount >0)

          {

            if(joinCondition.equals("AND") )

                whereClause = whereClause + " AND ";

            else

                whereClause = whereClause + " OR ";

          }

          //whereClause = whereClause + "EXISTS (SELECT /*+ index(HZCSU hz_cust_site_uses_u1) */ 1 FROM  hz_cust_acct_sites_all  HZCS, hz_cust_site_uses_all  HZCSU WHERE HZCS.party_site_id = QRSLT.party_site_id AND HZCS.cust_acct_site_id = HZCSU.cust_acct_site_id AND HZCSU.site_use_id = (SELECT site_use_id FROM hz_cust_site_uses_all WHERE site_use_id = HZCSU.site_use_id AND 1 = 1) AND HZCS.cust_acct_site_id = (SELECT cust_acct_site_id FROM  hz_cust_acct_sites_all";

          //whereClause = whereClause + " WHERE cust_acct_site_id = HZCS.cust_acct_site_id AND 1 = 1)nvl(substr(HZCSU.orig_system_reference,instr(HZCSU.orig_system_reference,'-',1,1)+1,instr(HZCSU.orig_system_reference,'-',1,2)-instr(HZCSU.orig_system_reference,'-',1)-1),'') like '"+ value +"%') ";

          whereClause = whereClause + "exists (select 1  from hz_cust_acct_sites  HZCS      ,hz_cust_site_uses  HZCSU  where  HZCS.cust_acct_site_id = (SELECT cust_acct_site_id FROM  hz_cust_acct_sites WHERE cust_acct_site_id = HZCS.cust_acct_site_id AND 1 = 1) AND  HZCS.party_site_id     = QRSLT.party_site_id AND  HZCS.cust_acct_site_id  = HZCSU.cust_acct_site_id AND";

          whereClause = whereClause + " nvl(substr(HZCSU.orig_system_reference,instr(HZCSU.orig_system_reference,'-',1,1)+1,instr(HZCSU.orig_system_reference,'-',1,2)-instr(HZCSU.orig_system_reference,'-',1)-1),'') "+condition + " '"+ value +"' AND 1=1 )";

          clauseCount = clauseCount +1;

        }

        if (itemName.equals("LegacyNumber"))

        {

          if (clauseCount >0)

          {

            if(joinCondition.equals("AND") )

                whereClause = whereClause + " AND ";

            else

                whereClause = whereClause + " OR ";

          }

          whereClause = whereClause + "EXISTS (select 1 from hz_cust_accounts where party_id  = QRSLT.party_id AND status = 'A' AND orig_system_reference "+condition+ " '"+ value +"') ";

          clauseCount = clauseCount +1;

        }



        if (itemName.equals("PostalCode"))

        {

          if (clauseCount >0)

          {

            if(joinCondition.equals("AND") )

                whereClause = whereClause + " AND ";

            else

                whereClause = whereClause + " OR ";

          }

          whereClause = whereClause + "POSTAL_CODE  "+condition+ " '"+ value +"' ";

          clauseCount = clauseCount +1;

        }



        if (itemName.equals("PrimaryPhone"))

        {

          if (clauseCount >0)

          {

            if(joinCondition.equals("AND") )

                whereClause = whereClause + " AND ";

            else

                whereClause = whereClause + " OR ";

          }

          //whereClause = whereClause + "UPPER(PHONE_COUNTRY_CODE||PHONE_AREA_CODE||PHONE_NUMBER||PHONE_EXTENSION)  "+condition+ " '"+ value +"' ";

          whereClause = whereClause + "EXISTS (select 1 from  hz_contact_points HZCP where upper(PHONE_COUNTRY_CODE||PHONE_AREA_CODE||PHONE_NUMBER||PHONE_EXTENSION) "+condition+ " '"+ value +"' AND  HZCP.OWNER_TABLE_ID||'' = QRSLT.party_site_id and  HZCP.PRIMARY_FLAG = 'Y' and  HZCP.OWNER_TABLE_NAME = 'HZ_PARTY_SITES' and  PHONE_LINE_TYPE = 'GEN' and  ((PHONE_NUMBER is not null) or (PHONE_NUMBER <> ''))  and  rownum > 0) ";

          clauseCount = clauseCount +1;

        }





         if (itemName.equals("SalesPerson"))

        {

          if (clauseCount >0)

          {

            if(joinCondition.equals("AND") )

                whereClause = whereClause + " AND ";

            else

                whereClause = whereClause + " OR ";

          }

          // Sales Person



          whereClause =whereClause +"EXISTS( SELECT 1 FROM xx_tm_nam_terr_entity_dtls   xtnted  ,xx_tm_nam_terr_rsc_dtls      xtntrd  ,xx_tm_nam_terr_defn  xtntd WHERE xtnted.entity_id  = QRSLT.party_site_id  AND   xtntrd.named_acct_terr_id = xtnted.named_acct_terr_id AND   xtntd.named_acct_terr_id  = xtntrd.named_acct_terr_id  AND   xtnted.named_acct_terr_id = xtntd.named_acct_terr_id  AND   xtntrd.resource_id        = '"+ SalesRepId +"' AND   xtnted.entity_type        = 'PARTY_SITE' ";

          whereClause = whereClause + "AND sysdate between nvl(xtntrd.start_date_active,sysdate-1) and nvl(xtntrd.end_date_active,sysdate +1) AND   sysdate between nvl(xtnted.start_date_active,sysdate-1) and nvl(xtnted.end_date_active, sysdate+1)  AND   sysdate between nvl(xtntd.start_date_active,sysdate-1) and nvl(xtntd.end_date_active,sysdate+1) AND   xtnted.status  = 'A' AND   xtntrd.status = 'A' AND   xtntd.status = 'A' )";

          //whereClause =whereClause + " 1=1 ";

          clauseCount = clauseCount +1;

        }

        pageContext.writeDiagnostics(METHOD_NAME, "clauseCount = "+clauseCount, OAFwkConstants.PROCEDURE);

        pageContext.writeDiagnostics(METHOD_NAME, "Complete whereClause = "+whereClause, OAFwkConstants.PROCEDURE);







    }

        // Finally invoke a custom method on your view object to set the where clause

        // you should not execute the query if you call getNonViewAttrCriteria.

        // where clause

        // get the CustomerSearchVO

        OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);

        OAViewObjectImpl customerSearchVo = (OAViewObjectImpl)am.findViewObject("ODCustomerSearchResultsVO");

        customerSearchVo.setWhereClause(null);

        customerSearchVo.setWhereClauseParams(null);

        

        //anirban: 28 apr'09 starts : defect#14427



        String profileValue = pageContext.getProfile("ASN_CUST_ACCESS");

        if(profileValue == null || "".equals(profileValue.trim()) || "F".equals(profileValue))

	    {

         customerSearchVo.setWhereClause(whereClause);

        }

        else

	    {

		 String bind_resourceId = getLoginResourceId(am, pageContext);

		 customerSearchVo.setWhereClause(whereClause);

		 customerSearchVo.setWhereClauseParam(0, bind_resourceId);

		 customerSearchVo.setWhereClauseParam(1, bind_resourceId);

		}

         

        //now here, put the logic of supplying bind varaibles's values starting from 3rd varaiable onwards ONLY //when the logged in user is a manager.



		//anirban: 28 apr'09 ends : defect#14427

        String voQuery = customerSearchVo.getQuery();

        pageContext.writeDiagnostics(METHOD_NAME, "Complete VO Query = "+voQuery, OAFwkConstants.PROCEDURE);





     if (isProcLogEnabled)

        {

          pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);

        }

  }



  public boolean preValidationCheck (OAPageContext pageContext, OAWebBean webBean,String custAccess)

  {

    final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.custsrch.common.customer.webui.ODCustomerQueryCO.preValidationCheck";

    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);

    if (isProcLogEnabled)

    {

      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);

    }

    pageContext.writeDiagnostics(METHOD_NAME, "Access is : "+ custAccess, OAFwkConstants.STATEMENT);

    OAQueryBean queryBean = (OAQueryBean) webBean;

    boolean validationCheck = true;

    boolean mandatoryCheck = false;



    // This gives you the current criteria

    Dictionary[] dic = queryBean.getCriteria(pageContext);



    // If the dictionary is empty, then it means that no criteria

    // is available, so return.

    if (dic == null )//|| dic.isEmpty())

    {

      pageContext.writeDiagnostics(METHOD_NAME, "getCriteria Dictionary is null", OAFwkConstants.PROCEDURE);

      validationCheck = false;

      //return false;

    }

    else

    {



        pageContext.writeDiagnostics(METHOD_NAME, "getCriteria Dictionary is not null", OAFwkConstants.PROCEDURE);

        // Otherwise process the dictionary to ensure that atleast one field has 3 non wild card characters.

        int dictSize = dic.length;

        pageContext.writeDiagnostics(METHOD_NAME, "Length of dictionary - dictSize : "+dictSize, OAFwkConstants.PROCEDURE);



        //Iterate through the dictionary to check for duplicate rows



        HashMap criteria = new HashMap(100);

        boolean duplicateFound = false;

        String criteriaItemName = null;

        Object criteriaItemvalue = null;

        Dictionary criteriaDict = null;







        for (int i=0; i < dictSize; i++)

        {

            criteriaDict = dic[i];

            criteriaItemName = (String)criteriaDict.get(OAViewObject.CRITERIA_ITEM_NAME);

            criteriaItemvalue = criteriaDict.get(OAViewObject.CRITERIA_VALUE);

             pageContext.writeDiagnostics(METHOD_NAME, "criteriaItemName :   "+ criteriaItemName, OAFwkConstants.STATEMENT);

             pageContext.writeDiagnostics(METHOD_NAME, "criteriaItemvalue :   "+ criteriaItemvalue, OAFwkConstants.STATEMENT);

            //only string items are checked for duplicate values

            if (!duplicateFound && criteriaItemvalue instanceof String)

            {

              //item already in the hashmap generate error

              if (criteria.containsKey(criteriaItemName))

              {

                duplicateFound = true;

                //pageContext.putDialogMessage(new OAException("ASN","ASN_DUP_SRCH_CRITERIA"));

                pageContext.writeDiagnostics(METHOD_NAME, "Duplicate Search Criteria entered  ", OAFwkConstants.STATEMENT);

                OAException e = new OAException("ASN", "ASN_DUP_SRCH_CRITERIA");

                throw(e);

              }

              else

              {

                  //populate the hashmap

                  criteria.put(criteriaItemName,criteriaItemvalue);

              }

            }



        }





        // Iterate through the dictionary to perform pre validation

        for (int i=0; i < dictSize; i++)

        {

            pageContext.writeDiagnostics(METHOD_NAME, "Value of i : "+i, OAFwkConstants.PROCEDURE);

            // Item for which the criteria is defined.

            String itemName = (String) dic[i].get(OAViewObject.CRITERIA_ITEM_NAME);

            pageContext.writeDiagnostics(METHOD_NAME, "itemName = "+itemName, OAFwkConstants.PROCEDURE);

            // Condition is the SQL condition - examples: like , = etc



            String condition = (String) dic[i].get(OAViewObject.CRITERIA_CONDITION);

            pageContext.writeDiagnostics(METHOD_NAME, "condition = "+condition, OAFwkConstants.PROCEDURE);



            // Value is the value entered with the appropriate % based on condition

            Object value = dic[i].get(OAViewObject.CRITERIA_VALUE);

            pageContext.writeDiagnostics(METHOD_NAME, "value = "+value, OAFwkConstants.PROCEDURE);



            // Join condition is either AND or OR depending on what user chooses

            String joinCondition = (String) dic[i].get(OAViewObject.CRITERIA_JOIN_CONDITION);



            //if(("F".equals(custAccess) )&&((itemName.equals("PartyNumber"))||(itemName.equals("PartyName"))||(itemName.equals("LegacyNumber"))))

            if((itemName.equals("PartyNumber"))||(itemName.equals("PartyName"))||(itemName.equals("LegacyNumber")))

            {

                pageContext.writeDiagnostics(METHOD_NAME, "Mandatory Check : "+itemName, OAFwkConstants.PROCEDURE);

                mandatoryCheck = true;

            }



            if((itemName.equals("NoOfRows"))||(itemName.equals("ResultsFlag"))||(itemName.equals("ActiveFlag"))||(itemName.equals("State")))

            {

                pageContext.writeDiagnostics(METHOD_NAME, "Not considered for pre validation : "+itemName, OAFwkConstants.PROCEDURE);

            }

            else

            {

                pageContext.writeDiagnostics(METHOD_NAME, "Considered for Prevalidation : "+itemName, OAFwkConstants.PROCEDURE);

                if(itemName.equals("SalesPersonResourceId"))

                {

                  //SalesRepId = (oracle.jbo.domain.Number)value;

                  SalesRepId = value.toString();

                }

                if(itemName.equals("ClassCodeValue"))

                {

                  ClassCode = value.toString();

                }

                if(itemName.equals("ClassCategoryValue"))

                {

                  ClassCategory = value.toString();

                }

                String valueStr = value.toString();

                String newStr ="";



                pageContext.writeDiagnostics(METHOD_NAME, "Check for Percent % ", OAFwkConstants.PROCEDURE);

                int wildcardPosition = valueStr.indexOf("%");

                pageContext.writeDiagnostics(METHOD_NAME, "wildcardPosition = "+wildcardPosition, OAFwkConstants.PROCEDURE);

                if (wildcardPosition== -1)

                {

                    pageContext.writeDiagnostics(METHOD_NAME, "Percent inside wildcardPosition ==-1 ", OAFwkConstants.PROCEDURE);

                    newStr = valueStr;

                }

                else

                {

                  if (wildcardPosition !=0)

                  {

                    pageContext.writeDiagnostics(METHOD_NAME, "Percent inside ELSE wildcardPosition ==-1 ", OAFwkConstants.PROCEDURE);

                    newStr = valueStr.substring(0,wildcardPosition);

                  }

                  else

                  {

                    newStr = "";

                  }

                }



                pageContext.writeDiagnostics(METHOD_NAME, "valueStr = "+valueStr, OAFwkConstants.PROCEDURE);

                pageContext.writeDiagnostics(METHOD_NAME, "newStr = "+newStr, OAFwkConstants.PROCEDURE);

                pageContext.writeDiagnostics(METHOD_NAME, "newStr.length() = "+newStr.length(), OAFwkConstants.PROCEDURE);



                pageContext.writeDiagnostics(METHOD_NAME, "Check for Underscore _ ", OAFwkConstants.PROCEDURE);

                wildcardPosition = newStr.indexOf("_");

                pageContext.writeDiagnostics(METHOD_NAME, "wildcardPosition = "+wildcardPosition, OAFwkConstants.PROCEDURE);

                if (wildcardPosition== -1)

                {

                    pageContext.writeDiagnostics(METHOD_NAME, "Underscore inside wildcardPosition ==-1 ", OAFwkConstants.PROCEDURE);

                    //newStr = valueStr;

                }

                else

                {

                  if (wildcardPosition !=0)

                  {

                    pageContext.writeDiagnostics(METHOD_NAME, "Underscore inside ELSE wildcardPosition ==-1 ", OAFwkConstants.PROCEDURE);

                    newStr = newStr.substring(0,wildcardPosition);

                  }

                   else

                  {

                    newStr = "";

                  }

                }



                pageContext.writeDiagnostics(METHOD_NAME, "newStr = "+newStr, OAFwkConstants.PROCEDURE);

                pageContext.writeDiagnostics(METHOD_NAME, "newStr.length() = "+newStr.length(), OAFwkConstants.PROCEDURE);



                if (newStr.length()<3)

                {

                    // return false;

                    validationCheck = false;

                    pageContext.writeDiagnostics(METHOD_NAME, "3 Char Validation Failed : "+newStr.length(), OAFwkConstants.PROCEDURE);

                }

                /* Check for the IS NOT condition */

                 condition = condition.trim();

                if ("<>".equalsIgnoreCase(condition))

                {

                  pageContext.writeDiagnostics(METHOD_NAME, "Condition not supported  ", OAFwkConstants.STATEMENT);

                  validationCheck = false;

                }



            }

        }

    }

    if (("F".equals(custAccess) )&& !mandatoryCheck)

    //if ( !mandatoryCheck)

    {

       pageContext.writeDiagnostics(METHOD_NAME, "Mandatory Parameters not entered  ", OAFwkConstants.STATEMENT);

       OAException e = new OAException("XXCRM", "XX_SFA_095_ENTER_REQD_PARAMS");

       throw(e);

    }



     if (isProcLogEnabled)

     {

          pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);

     }

        return validationCheck;

  }





  public String getSecurityRestrictiveSql(OAPageContext oapagecontext, OAWebBean oawebbean)

  {



        String s = "od.oracle.apps.xxcrm.asn.custsrch.common.customer.webui.ODCustomerQueryCO.getSecurityRestrictiveSql";

        boolean flag = oapagecontext.isLoggingEnabled(2);

        if(flag)

            oapagecontext.writeDiagnostics(s, "Begin", 2);

        StringBuffer stringbuffer = new StringBuffer();

        String s1 = null;

        s1 = oapagecontext.getProfile("ASN_CUST_ACCESS");

        if(s1 == null || "".equals(s1.trim()))

            s1 = "S";

        "F".equals(s1);







        // SEEDED: sales team 'T': STARTS



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



        // SEEDED: sales team 'T': ENDS



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

                //stringbuffer.append(" ( party_site_id in ( SELECT hzps.party_site_id  ");

				//Anirban added for PERF:starts

                stringbuffer.append("  QRSLT.party_site_id in ( SELECT party_site_id ");

                stringbuffer.append("   from ( SELECT hzps.party_site_id  ");

				//Anirban added for PERF:ends

                stringbuffer.append(" FROM (SELECT terr.named_acct_terr_id, terr_ent.entity_type, terr_ent.entity_id, terr_rsc.resource_id, terr_rsc.resource_role_id, terr_rsc.GROUP_ID, terr_ent.full_access_flag FROM xx_tm_nam_terr_rsc_dtls terr_rsc, xx_tm_nam_terr_defn terr, xx_tm_nam_terr_entity_dtls terr_ent WHERE terr.named_acct_terr_id = terr_rsc.named_acct_terr_id AND terr_ent.named_acct_terr_id = terr_rsc.named_acct_terr_id ");

                stringbuffer.append(" AND terr_ent.named_acct_terr_id = terr.named_acct_terr_id AND SYSDATE BETWEEN NVL (terr.start_date_active, SYSDATE - 1) AND NVL (terr.end_date_active, SYSDATE + 1) AND SYSDATE BETWEEN NVL (terr_ent.start_date_active, SYSDATE - 1) AND NVL (terr_ent.end_date_active, SYSDATE + 1) AND SYSDATE BETWEEN NVL (terr_rsc.start_date_active, SYSDATE - 1) AND NVL (terr_rsc.end_date_active, SYSDATE + 1) AND NVL (terr.status, 'A') = 'A' ");

                stringbuffer.append(" AND NVL (terr_ent.status, 'A') = 'A' AND NVL (terr_rsc.status, 'A') = 'A') aaa, HZ_PARTY_SITES hzps ");

                stringbuffer.append(" WHERE aaa.entity_type='PARTY_SITE'   AND hzps.party_site_id = aaa.entity_id   AND nvl(hzps.identifying_address_flag,'N') = 'N' AND hzps.status = 'A'   and aaa.resource_id = :1");

				//anirban: 28 Apr'09 starts : defect#14427

                //stringbuffer.append(s4);

				//anirban: 28 Apr'09 ends : defect#14427

                stringbuffer.append(" UNION ALL   ");

		        stringbuffer.append(" SELECT hzps.party_site_id   ");

                stringbuffer.append(" FROM HZ_PARTY_SITES hzps  ");

                //stringbuffer.append(" WHERE hzps.party_id IN ");

                stringbuffer.append(" WHERE exists ");

                stringbuffer.append("(SELECT party_id FROM (SELECT terr.named_acct_terr_id, terr_ent.entity_type, terr_ent.entity_id, terr_rsc.resource_id, terr_rsc.resource_role_id, terr_rsc.GROUP_ID, terr_ent.full_access_flag FROM xx_tm_nam_terr_rsc_dtls terr_rsc, xx_tm_nam_terr_defn terr, xx_tm_nam_terr_entity_dtls terr_ent WHERE terr.named_acct_terr_id = terr_rsc.named_acct_terr_id AND terr_ent.named_acct_terr_id = terr_rsc.named_acct_terr_id ");

                stringbuffer.append(" AND terr_ent.named_acct_terr_id = terr.named_acct_terr_id AND SYSDATE BETWEEN NVL (terr.start_date_active, SYSDATE - 1) AND NVL (terr.end_date_active, SYSDATE + 1) AND SYSDATE BETWEEN NVL (terr_ent.start_date_active, SYSDATE - 1) AND NVL (terr_ent.end_date_active, SYSDATE + 1) AND SYSDATE BETWEEN NVL (terr_rsc.start_date_active, SYSDATE - 1) AND NVL (terr_rsc.end_date_active, SYSDATE + 1) AND NVL (terr.status, 'A') = 'A' ");

                stringbuffer.append(" AND NVL (terr_ent.status, 'A') = 'A' AND NVL (terr_rsc.status, 'A') = 'A') aaa, HZ_PARTY_SITES hzpps ");

				stringbuffer.append(" WHERE hzpps.party_id = hzps.party_id and aaa.entity_type='PARTY_SITE'   AND hzpps.party_site_id = aaa.entity_id   AND nvl(hzpps.identifying_address_flag,'N') = 'Y' AND hzpps.status = 'A'   and aaa.resource_id = :2");

                //anirban: 28 Apr'09 starts : defect#14427

                //stringbuffer.append(s4);

				//anirban: 28 Apr'09 ends : defect#14427

                stringbuffer.append(" )))");

            }

            //SALES REP ENDS





            //MANAGER/ADMIN: STARTS

            if("Y".equals(s2) && (arraylist != null && arraylist.size() > 0 || arraylist1 != null && arraylist1.size() > 0))

            {

                //MANAGER/ADMIN AS A REP: STARTS



                //stringbuffer.append(" ( party_site_id in ( SELECT hzps.party_site_id  ");

				//Anirban added for PERF:starts

                stringbuffer.append("  QRSLT.party_site_id in ( SELECT party_site_id ");

                stringbuffer.append("   from ( SELECT hzps.party_site_id  ");

				//Anirban added for PERF:ends

                stringbuffer.append(" FROM (SELECT /*+ INDEX (terr_ent XX_TM_NAM_TERR_ENTITY_DTLS_N2) */ terr.named_acct_terr_id, terr_ent.entity_type, terr_ent.entity_id, terr_rsc.resource_id, terr_rsc.resource_role_id, terr_rsc.GROUP_ID, terr_ent.full_access_flag FROM xx_tm_nam_terr_rsc_dtls terr_rsc, xx_tm_nam_terr_defn terr, xx_tm_nam_terr_entity_dtls terr_ent WHERE terr.named_acct_terr_id = terr_rsc.named_acct_terr_id AND terr_ent.named_acct_terr_id = terr_rsc.named_acct_terr_id ");

                stringbuffer.append(" AND terr_ent.named_acct_terr_id = terr.named_acct_terr_id AND SYSDATE BETWEEN NVL (terr.start_date_active, SYSDATE - 1) AND NVL (terr.end_date_active, SYSDATE + 1) AND SYSDATE BETWEEN NVL (terr_ent.start_date_active, SYSDATE - 1) AND NVL (terr_ent.end_date_active, SYSDATE + 1) AND SYSDATE BETWEEN NVL (terr_rsc.start_date_active, SYSDATE - 1) AND NVL (terr_rsc.end_date_active, SYSDATE + 1) AND NVL (terr.status, 'A') = 'A' ");

                stringbuffer.append(" AND NVL (terr_ent.status, 'A') = 'A' AND NVL (terr_rsc.status, 'A') = 'A') aaa, HZ_PARTY_SITES hzps ");

                stringbuffer.append(" WHERE aaa.entity_type='PARTY_SITE'   AND hzps.party_site_id = aaa.entity_id   AND nvl(hzps.identifying_address_flag,'N') = 'N' AND hzps.status = 'A'   and aaa.resource_id = :1");

				//anirban: 28 Apr'09 starts : defect#14427

                //stringbuffer.append(s4);

				//anirban: 28 Apr'09 ends : defect#14427

                stringbuffer.append(" UNION ALL   ");//uncommenting on 8 july for perf reasons.

				//stringbuffer.append(" UNION  ");

                stringbuffer.append(" SELECT hzps.party_site_id   ");

                stringbuffer.append(" FROM HZ_PARTY_SITES hzps  ");

                //stringbuffer.append(" WHERE hzps.party_id IN ");

                stringbuffer.append(" WHERE exists ");

                stringbuffer.append("(SELECT party_id FROM (SELECT terr.named_acct_terr_id, terr_ent.entity_type, terr_ent.entity_id, terr_rsc.resource_id, terr_rsc.resource_role_id, terr_rsc.GROUP_ID, terr_ent.full_access_flag FROM xx_tm_nam_terr_rsc_dtls terr_rsc, xx_tm_nam_terr_defn terr, xx_tm_nam_terr_entity_dtls terr_ent WHERE terr.named_acct_terr_id = terr_rsc.named_acct_terr_id AND terr_ent.named_acct_terr_id = terr_rsc.named_acct_terr_id ");

                stringbuffer.append(" AND terr_ent.named_acct_terr_id = terr.named_acct_terr_id AND SYSDATE BETWEEN NVL (terr.start_date_active, SYSDATE - 1) AND NVL (terr.end_date_active, SYSDATE + 1) AND SYSDATE BETWEEN NVL (terr_ent.start_date_active, SYSDATE - 1) AND NVL (terr_ent.end_date_active, SYSDATE + 1) AND SYSDATE BETWEEN NVL (terr_rsc.start_date_active, SYSDATE - 1) AND NVL (terr_rsc.end_date_active, SYSDATE + 1) AND NVL (terr.status, 'A') = 'A' ");

                stringbuffer.append(" AND NVL (terr_ent.status, 'A') = 'A' AND NVL (terr_rsc.status, 'A') = 'A') aaa, HZ_PARTY_SITES hzpps ");

                stringbuffer.append(" WHERE hzpps.party_id = hzps.party_id and aaa.entity_type='PARTY_SITE'   AND hzpps.party_site_id = aaa.entity_id   AND nvl(hzpps.identifying_address_flag,'N') = 'Y' AND hzpps.status = 'A'   and aaa.resource_id = :2");

                //anirban: 28 Apr'09 starts : defect#14427

                //stringbuffer.append(s4);

				//anirban: 28 Apr'09 ends : defect#14427

                stringbuffer.append(")");

                //MANAGER/ADMIN AS A REP: ENDS





                stringbuffer.append(" UNION ALL  ");//uncommenting on 8 july for perf reasons.

				//stringbuffer.append(" UNION  ");

                stringbuffer.append(" SELECT hzps.party_site_id  ");

                stringbuffer.append(" FROM (SELECT /*+ INDEX (terr_ent XX_TM_NAM_TERR_ENTITY_DTLS_N2) */ terr.named_acct_terr_id, terr_ent.entity_type, terr_ent.entity_id, terr_rsc.resource_id, terr_rsc.resource_role_id, terr_rsc.GROUP_ID, terr_ent.full_access_flag FROM xx_tm_nam_terr_rsc_dtls terr_rsc, xx_tm_nam_terr_defn terr, xx_tm_nam_terr_entity_dtls terr_ent WHERE terr.named_acct_terr_id = terr_rsc.named_acct_terr_id AND terr_ent.named_acct_terr_id = terr_rsc.named_acct_terr_id ");

                stringbuffer.append(" AND terr_ent.named_acct_terr_id = terr.named_acct_terr_id AND SYSDATE BETWEEN NVL (terr.start_date_active, SYSDATE - 1) AND NVL (terr.end_date_active, SYSDATE + 1) AND SYSDATE BETWEEN NVL (terr_ent.start_date_active, SYSDATE - 1) AND NVL (terr_ent.end_date_active, SYSDATE + 1) AND SYSDATE BETWEEN NVL (terr_rsc.start_date_active, SYSDATE - 1) AND NVL (terr_rsc.end_date_active, SYSDATE + 1) AND NVL (terr.status, 'A') = 'A' ");

                stringbuffer.append(" AND NVL (terr_ent.status, 'A') = 'A' AND NVL (terr_rsc.status, 'A') = 'A') aaa, HZ_PARTY_SITES hzps ");

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





                stringbuffer.append(" UNION ALL   ");//uncommenting on 8 july for perf reasons.

				//stringbuffer.append(" UNION  ");

                stringbuffer.append(" SELECT hzps.party_site_id   ");

                stringbuffer.append(" FROM HZ_PARTY_SITES hzps  ");

                stringbuffer.append(" WHERE hzps.party_id IN ");

                stringbuffer.append("(SELECT party_id FROM (SELECT /*+ INDEX (terr_ent XX_TM_NAM_TERR_ENTITY_DTLS_N2) */ terr.named_acct_terr_id, terr_ent.entity_type, terr_ent.entity_id, terr_rsc.resource_id, terr_rsc.resource_role_id, terr_rsc.GROUP_ID, terr_ent.full_access_flag FROM xx_tm_nam_terr_rsc_dtls terr_rsc, xx_tm_nam_terr_defn terr, xx_tm_nam_terr_entity_dtls terr_ent WHERE terr.named_acct_terr_id = terr_rsc.named_acct_terr_id AND terr_ent.named_acct_terr_id = terr_rsc.named_acct_terr_id ");

                stringbuffer.append(" AND terr_ent.named_acct_terr_id = terr.named_acct_terr_id AND SYSDATE BETWEEN NVL (terr.start_date_active, SYSDATE - 1) AND NVL (terr.end_date_active, SYSDATE + 1) AND SYSDATE BETWEEN NVL (terr_ent.start_date_active, SYSDATE - 1) AND NVL (terr_ent.end_date_active, SYSDATE + 1) AND SYSDATE BETWEEN NVL (terr_rsc.start_date_active, SYSDATE - 1) AND NVL (terr_rsc.end_date_active, SYSDATE + 1) AND NVL (terr.status, 'A') = 'A' ");

                stringbuffer.append(" AND NVL (terr_ent.status, 'A') = 'A' AND NVL (terr_rsc.status, 'A') = 'A') aaa, HZ_PARTY_SITES hzps ");

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









}

