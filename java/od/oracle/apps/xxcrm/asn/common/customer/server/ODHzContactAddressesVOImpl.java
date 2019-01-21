/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODHzContactAddressesVOImpl.java                               |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    View Object Implementation for ODHzContactAddressesVO View             |
 |                                                                           |
 |                                                                           |
 |                                                                           |
 |  NOTES                                                                    |
 |         Used for the View and Update Contact Pages                        |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |     No dependencies.                                                      |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |   11-Oct-2007 Jasmine Sujithra   Created                                  |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.common.customer.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODHzContactAddressesVOImpl extends OAViewObjectImpl 
{

public void initQuery(String partyId)  
  {
    setWhereClauseParams(null); // Always reset  
    setWhereClauseParam(0, partyId); 
     //setWhereClauseParam(0, "728052"); 

    executeQuery();
  } // end initQuery()

  public void initQuery(String partyId, String countryCode, String purpose)  
  {
   
    setWhereClauseParams(null); // Always reset
    setWhereClause(null);
    setWhereClauseParam(0, partyId);     
    //setWhereClauseParam(0, "728052"); 
    
    int bind = 1;
    if(countryCode != null)
    {
      addWhereClause("COUNTRY_CODE = :2");
      setWhereClauseParam(bind++, countryCode);
    }
    else
    {
      addWhereClause("(1=1)");
    }
    
    if(purpose != null)
    {
      addWhereClause("and (:3 in (select site_use_type "+
                     " from hz_party_site_uses psu "+
                     "where psu.party_site_id = QRSLT.PARTY_SITE_ID))");
      setWhereClauseParam(bind++, purpose);
    }
    
    executeQuery();
  } // end initQuery()  

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public ODHzContactAddressesVOImpl()
  {
  }
}