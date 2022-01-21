/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODSiteBusinessActivitiesAMImpl.java                           |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Application Module for business activities at the party site level.    |
 |                                                                           |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    This class file is called from ODSiteBusinessActivitiesCOImpl.java     |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    04/09/2007 Ashok Kumar   Created                                       |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.partysite.common.server;
import com.sun.java.util.collections.ArrayList;

import od.oracle.apps.xxcrm.asn.common.fwk.server.ODASNApplicationModuleImpl;
import oracle.apps.asn.common.poplist.server.LookupsOrderByTagVOImpl;
import oracle.apps.asn.common.poplist.server.LookupsOrderByTagVORowImpl;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;


//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODSiteBusinessActivitiesAMImpl extends ODASNApplicationModuleImpl 
{
  /**
  * Oracle Applications internal source control identifier.
  */
  public static final String RCS_ID="$Header: ODSiteBusinessActivitiesAMImpl.java,v 1.2 2007/10/01 11:53:58 Ashokuma Exp $";

  /**
  * Oracle Applications internal source control identifier.
  */
  public static final boolean RCS_ID_RECORDED =
    VersionInfo.recordClassVersion(RCS_ID, "od.oracle.apps.xxcrm.asn.partysite.common.server");

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public ODSiteBusinessActivitiesAMImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("od.oracle.apps.xxcrm.asn.partysite.common.server", "ODSiteBusinessActivitiesAMLocal");
  }

  /**
   * 
   * Container's getter for LookupsOrderByTagVO
   */
  public LookupsOrderByTagVOImpl getLookupsOrderByTagVO()
  {
    return (LookupsOrderByTagVOImpl)findViewObject("LookupsOrderByTagVO");
  }

  /**
   *
   * Method to initialize the business activity poplist Query
   */
  public void initBusActPoplistQuery(String lookupType, String viewApplicationId)
  {
    final String METHOD_NAME = "xxcrm.asn.partysite.common.server.ODSiteBusinessActivitiesAMImpl.initBusActPoplistQuery";
    OADBTransaction dbTrx = (OADBTransaction)getOADBTransaction();
    boolean isProcLogEnabled = dbTrx.isLoggingEnabled(OAFwkConstants.PROCEDURE);

    if (isProcLogEnabled)
    {
      dbTrx.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    LookupsOrderByTagVOImpl vo = getLookupsOrderByTagVO();
    if (vo == null)
    {
      MessageToken[] tokens = { new MessageToken("NAME", "LookupsOrderByTagVO") };
      throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", tokens);
    }
    vo.initQuery(lookupType, viewApplicationId);

    if (isProcLogEnabled)
    {
      dbTrx.writeDiagnostics(METHOD_NAME,"End", OAFwkConstants.PROCEDURE);
    }

  }

  /**
   *
   * Method to find out the initial value selected for business activity poplist
   */
  public String busActSelectedValue()
  {
    final String METHOD_NAME = "xxcrm.asn.partysite.common.server.ODSiteBusinessActivitiesAMImpl.busActSelectedValue";
    OADBTransaction dbTrx = (OADBTransaction)getOADBTransaction();
    boolean isProcLogEnabled = dbTrx.isLoggingEnabled(OAFwkConstants.PROCEDURE);

    if (isProcLogEnabled)
    {
      dbTrx.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    LookupsOrderByTagVOImpl vo1 = getLookupsOrderByTagVO();
    LookupsOrderByTagVORowImpl row = (LookupsOrderByTagVORowImpl) vo1.first();
    String selectedValue = (String)row.getAttribute("LookupCode");
   
    if (isProcLogEnabled)
    {
      dbTrx.writeDiagnostics(METHOD_NAME,selectedValue, OAFwkConstants.PROCEDURE);
      dbTrx.writeDiagnostics(METHOD_NAME,"End", OAFwkConstants.PROCEDURE);
    }

    return selectedValue;
  }

  /**
   *
   * Method to find out the region path for a given region, which is declared as a function
   */
  public String getRegionPath(String functionName)
  {
    final String METHOD_NAME = "xxcrm.asn.partysite.common.server.ODSiteBusinessActivitiesAMImpl.getRegionPath";
    OADBTransaction dbTrx = (OADBTransaction)getOADBTransaction();
    boolean isProcLogEnabled = dbTrx.isLoggingEnabled(OAFwkConstants.PROCEDURE);

    if (isProcLogEnabled)
    {
      dbTrx.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    if (isProcLogEnabled)
    {
      dbTrx.writeDiagnostics(METHOD_NAME,"End", OAFwkConstants.PROCEDURE);
    }
    return (getOADBTransaction().getFunctionSecurity().getFunction(functionName).getWebHTMLCall());
  }

  /**
   *
   * Method to store all the business activity lookup codes in a arraylist
   */
  public ArrayList busActLookupCodes()
  {
    final String METHOD_NAME = "xxcrm.asn.partysite.common.server.ODSiteBusinessActivitiesAMImpl.busActLookupCodes";
    OADBTransaction dbTrx = (OADBTransaction)getOADBTransaction();
    boolean isProcLogEnabled = dbTrx.isLoggingEnabled(OAFwkConstants.PROCEDURE);

    if (isProcLogEnabled)
    {
      dbTrx.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    LookupsOrderByTagVOImpl vo1 = getLookupsOrderByTagVO();
    LookupsOrderByTagVORowImpl row = null;

    ArrayList busActLookupCodesList = new ArrayList(15);

    int i = 0;
    vo1.reset();
    while (vo1.hasNext())
    {
       row = (LookupsOrderByTagVORowImpl)vo1.next();
       if(row!=null)
       {
         busActLookupCodesList.add(i, row.getLookupCode());
       }
       i++;
    }

    vo1.reset();

    if (isProcLogEnabled)
    {
      dbTrx.writeDiagnostics(METHOD_NAME,"End", OAFwkConstants.PROCEDURE);
    }

    return busActLookupCodesList;
  }

  /**
   *
   * Method to reset query for all the business activity vos
   */
  public void resetQuery()
  {
    final String METHOD_NAME = "xxcrm.asn.partysite.common.server.ODSiteBusinessActivitiesAMImpl.resetBusinessActsQuery";
    OADBTransaction dbTrx = (OADBTransaction)getOADBTransaction();
    boolean isProcLogEnabled = dbTrx.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStmtLogEnabled = dbTrx.isLoggingEnabled(OAFwkConstants.STATEMENT);

    if (isProcLogEnabled)
    {
      dbTrx.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }

    String[] nestedAMNames = getApplicationModuleNames();
    String nestedAMName = null;
    OAApplicationModule nestedAM = null;

    for (int i = 0; i < nestedAMNames.length; i++)
    {
       nestedAMName = nestedAMNames[i];
       nestedAM = (OAApplicationModuleImpl) findApplicationModule(nestedAMName);
       try
       {
         nestedAM.invokeMethod("resetQuery");
       }
        catch(Exception e)
          {
            StringBuffer buf = new StringBuffer();
            buf.append("The resetQuery method is missing for the AM = ");
            buf.append(nestedAMName);
               if (isStmtLogEnabled)
               {
                 dbTrx.writeDiagnostics(METHOD_NAME,buf.toString(), OAFwkConstants.PROCEDURE);
              }
          }
    }

    if (isProcLogEnabled)
    {
      dbTrx.writeDiagnostics(METHOD_NAME,"End", OAFwkConstants.PROCEDURE);
    }

  }
  
}