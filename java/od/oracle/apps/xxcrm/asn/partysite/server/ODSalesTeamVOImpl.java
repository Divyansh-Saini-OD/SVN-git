/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODSalesTeamVOImpl.java                                        |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |     Sales Team VO                                                         | 
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    No dependencies.                                                       |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    01/OCT/2007 Sudeept Maharana   Created  / Generated                    |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.partysite.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Number;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.OAFwkConstants;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODSalesTeamVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public ODSalesTeamVOImpl()
  {
  }

  /**
       *  method to initialize and execute the query
       * @param partySiteId - Party Site ID
       * @return none	   
       */  

  public void initQuery(String partySiteId)
  {
	if (((OADBTransaction)getDBTransaction()).isLoggingEnabled(OAFwkConstants.PROCEDURE))
		this.writeDiagnostics(this , "initQuery.begin", OAFwkConstants.PROCEDURE);

	setWhereClauseParam(0,partySiteId);    
    executeQuery();

	if (((OADBTransaction)getDBTransaction()).isLoggingEnabled(OAFwkConstants.PROCEDURE))
		this.writeDiagnostics(this , "initQuery.end", OAFwkConstants.PROCEDURE);

  }   
}