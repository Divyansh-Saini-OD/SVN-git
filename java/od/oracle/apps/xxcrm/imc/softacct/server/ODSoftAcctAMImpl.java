/*===========================================================================+
 |      		       Office Depot - Project Simplify                           |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODSoftAcctAMImpl.java                                         |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Class is invoked from the controller class ODSoftAcctCO.java and       |
 |     helps in rendering the data from the database.                        |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |       This class invokes the following files:                             |
 |          ODGeneralInfoVOImpl.java                                         |
 |          ODAcctSiteVOImpl.java                                            |
 |          ODFlexfieldInfoVOImpl.java                                       |                         
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    04/04/2007     Sathya Prabha Rani       Created                        |
 |                                                                           |
 +===========================================================================*/

package od.oracle.apps.xxcrm.imc.softacct.server;

import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.common.MessageToken;
import oracle.jbo.Key;
import oracle.jbo.Row;

//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODSoftAcctAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public ODSoftAcctAMImpl()
  {
  }

  /**
   * 
   * Container's getter for ODGeneralInfoVO1
   */
  public ODGeneralInfoVOImpl getODGeneralInfoVO1()
  {
    return (ODGeneralInfoVOImpl)findViewObject("ODGeneralInfoVO1");
  }

  /**
   * 
   * Container's getter for ODAcctSiteVO1
   */
  public ODAcctSiteVOImpl getODAcctSiteVO1()
  {
    return (ODAcctSiteVOImpl)findViewObject("ODAcctSiteVO1");
  }

  /**
   * 
   * Container's getter for ODFlexfieldInfoVO1
   */
  public ODFlexfieldInfoVOImpl getODFlexfieldInfoVO1()
  {
    return (ODFlexfieldInfoVOImpl)findViewObject("ODFlexfieldInfoVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("od.oracle.apps.xxcrm.imc.softacct.server", "ODSoftAcctAMLocal");
  }

  /**
  *
  * Custom method to Commit the transaction during Create/Update.
  *
  */
  public void saveTheFF()
  {
    getTransaction().commit();
  }

  /**
   * 
   * The method "initQueryGeneralInfo" of the class "ODGeneralInfoVOImpl" is   
   * invoked to execute a query and determine the General details of a Customer.
   * <p>
   * @Param acctSiteId      - The account "site use id" used to find the 
   *                          site use details
   */
  public void initDetailsGenInfo(String acctSiteId)
  {
    ODGeneralInfoVOImpl vo = getODGeneralInfoVO1();
    if (vo == null)
    {
      MessageToken [] tokens =  {new MessageToken("OBJECT_NAME",
                   "getODGeneralInfoVO1")};
      throw new OAException("IMC", "XXOD_IMC_SACT_OBJECT_NOT_FOUND", tokens,
                    OAException.ERROR, null );
    }
    vo.initQueryGeneralInfo(acctSiteId);
  }

  /**
   * 
   * The method "initQueryAcctSite" of the class "ODAcctSiteVOImpl" is invoked  
   * to execute a query and determine the Account Site details of a Customer.
   * <p>
   * @Param acctSiteId      - The account "site use id" used to find the 
   *                          site use details.
   * @Param acctSiteUseCode - The account "site use code" used to find 
   *                          the site use details.
   */
  public void initDetailsCustAcctSite(String acctSiteId, String acctSiteUseCode)
  {
    ODAcctSiteVOImpl vo = getODAcctSiteVO1();
    if (vo == null)
    {
      MessageToken [] tokens =  {new MessageToken("OBJECT_NAME",
                   "getODAcctSiteVO1")};
      throw new OAException("IMC", "XXOD_IMC_SACT_OBJECT_NOT_FOUND", tokens,
                    OAException.ERROR, null );
    }
    vo.initQueryAcctSite(acctSiteId,acctSiteUseCode);
  }

  /**
   * 
   * The method is used to invoke the class "ODFlexfieldInfoVOImpl" and display
   * the DFFs based on the input parameters. The class "ODFlexfieldInfoVORowImpl"
   * is invoked to programmatically set the DFFs, instead of doing it
   * declaratively because the Context fields need to be hidden.
   * <p>
   * @Param siteUseId      - The account "site use id" used to find the 
   *                          site use details.
   * @Param siteUseCode    - The account "site use code" used to find 
   *                          the site use details.
   */
  public void initDetailsFlexfield(String siteUseId, String siteUseCode)
  {
    ODFlexfieldInfoVOImpl vo = getODFlexfieldInfoVO1();
    if (vo == null)
    {
      MessageToken[] errTokens = { new MessageToken("OBJECT_NAME", "getODFlexfieldInfoVO1")};
      throw new OAException("AK", "FWK_TBX_OBJECT_NOT_FOUND", errTokens);
    } 
   
    String[] keys = { siteUseId };
    Row[] rows = vo.findByKey(new Key(keys), 1);
   
    if (rows.length != 0)
    {
    if (rows != null)
    {
      vo.setCurrentRow(rows[0]);
    }
    
    ODFlexfieldInfoVORowImpl a = (ODFlexfieldInfoVORowImpl)vo.getCurrentRow();
    a.setAttribute("AttributeCategory", siteUseCode);
    }
  } 
  
}