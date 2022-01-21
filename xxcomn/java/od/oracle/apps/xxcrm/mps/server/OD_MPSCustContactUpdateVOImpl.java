/*===========================================================================+
 |      		      Office Depot - TDS Parts                           |
 |                Oracle Consulting Organization, Redwood Shores, CA, USA     |
 +=========================================================================== +
 |  FILENAME                                                                  |
 |             OD_MPSCustomerContactUpdateCO.java                             |
 |                                                                            |
 |  DESCRIPTION                                                               |
 |    Class to update the Party Contact to the database.                      |
 |    Also used for validation upon submission.                               |
 |                                                                            |
 |  NOTES                                                                     |
 |                                                                            |
 |                                                                            |
 |  DEPENDENCIES                                                              |
 |                                                                            |
 |  HISTORY                                                                   |
 | Ver  Date        Name           Revision Description                       |
 | ===  =========   ============== ===========================================|
 | 1.0  17-Dec-2013 Sravanthi surya Defect#26930 fix for Incorrecting Setting |
 |                                  of Where Clause while executing query inVO|
 |                                                                            |
 |                                                                            |
 |                                                                            |
 +===========================================================================*/
package od.oracle.apps.xxcrm.mps.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class OD_MPSCustContactUpdateVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public OD_MPSCustContactUpdateVOImpl()
  {
  }

  public void initCustContUpdate(String partyId, String location)
  { System.out.println("##### initCustContUpdate in VOImpl");
    setWhereClause("PARTY_ID = "+partyId+" AND DEVICE_LOCATION = '"+location+"'");
    executeQuery();
    System.out.println("##### initCustContUpdate rowCount="+getRowCount());
  } 
  
  public void initAddressCustContUpdate(String partyId, String serialno)
  { System.out.println("##### initAddressCustContUpdate in VOImpl");
    //setWhereClause("PARTY_ID = "+partyId+" AND SITE_ADDRESS_1 = '"+address+"'");   Commented By Sravanthi on 12/17/2013
	setWhereClause("PARTY_ID = "+partyId+" AND SERIAL_NO = '"+serialno+"'");         // Added By Sravanthi on 12/17/2013
    executeQuery();
    System.out.println("##### initAddressCustContUpdate rowCount="+getRowCount());
  }  
}