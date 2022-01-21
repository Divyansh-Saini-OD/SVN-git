/*===========================================================================+
 |      Copyright (c) 2000 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 |       14-Aug-00  sjamall       Created.                                   |
 |       03-Apr-01  sjamall       added workaround for bug 1718439           |
 |       05-Jun-01  sjamall       deprecated getTextFromPackage(String pkg,  |
 |                                String proc, String customerId,            |
 |                                String customerSiteUseId); replaced by     |
 |                                getTextFromPackage(String pkg,             |
 |                                String proc, String userId,                |
 |                                String customerId,String customerSiteUseId)|
 |       08-Jun-01  sjamall       added method getActiveCurrencyCode()       |
 |       20-Jul-01  krmenon       changed all CallableStatements to          |
 |                                OracleCallableStatements.                  |
 |                                added lenght specifications in all calls to|
 |                                registerOutParameter                       |
 |       01-Oct-01  sjamall       making changes to                          |
 |                                irec.framework.webui.VisibilityCO &        |
 |                                irec.framework.IROAApplicationModuleImpl   |
 |                                due to changes in framework where we are   |
 |                                required to not change attributes in the   |
 |                                processFormRequest(). We are therefore     |
 |                                redirecting to the current page in the     |
 |                                Visibility logic if we are going through   |
 |                                processFormRequest()                       |
 |       18-Mar-02  sjamall       bugfix 2264429                             |
 |       13-May-02  albowicz      Modified for enhancement request 2006628.  |
 |                                The customer search now supports external  |
 |                                users and trx number searches.  This file  |
 |                                was modified to add isInternal()           |
 |                                and isExternal() functions.                |
 |       12-Jun-02  albowicz      Modified for to fix bug number 2413869.    |
 |                                Specifically modified file to no longer    |
 |                                cache isInternal and isExternal since      |
 |                                there really is no performance gain and    |
 |                                the caching introduced a bug.              |
 |       15-Aug-03  albowicz      Admin Functionality                        |
 |  07/01/2004 hikumar Bug # 3738162 Added encrypted customerId and siteId as|
 |                        parameters in function get_homepage_customization()|
 |    01-Oct-04   vnb          Bug 3933606 - Multi-Print Enhancement         |
 |    03-Jan-05   vnb          Bug 4071551 - Added method to compute service |
 |							   charge                                        |
 |    11-Mar-05   vnb          Bug 4232383 - Moved getDiscountAmount function|
 |                             here for public use                           |
 |    22-Jul-05   rsinthre     Bug 4508705 - ATG: R12: REMOVE DEPRECATED APIS|  
 |    30-Sep-05   rsinthre   Bug 4621415 - Getting an error in navigating    |
 |                           to the Invoice Details page                     |
 |    15-Nov-05  rsinthre    Bug 4735794 - Error on clicking invoice when    |
 |                           Number format is 10.000,00                      |
 |    12-Dec-07   avepati    Bug 6622674 -JAVA CODE CHANGES FOR JDBC 11G ON MT|
 |    26-Nov-08  avepati  Bug 7432149 - PRINT PREVIEW OF EXTERNAL TEMPLATE IN|
 |                                       INVOICE DETAIL                      |
 |    11-May-09  avepati   Bug 8447417 - Switching of customer context is not|
 |                        happening for transactions applied across customers|
 |   19-Mar-2010 nkanchan  Bug # 8293098 - service charges based on credit   |
 |                              card type when making payments               |
 |   12-Aug-2010 avepati   Bug 10015700  - cust stmt errors with xml error   |
 |   06-Jul-2011 rsinthre  Bug 11864017 - Change of currency preference cause|
 |                         exception viewing invoice                         |
 |   01-Jun-2012 melapaku  Bug 14142122 -iReceivables Customer Search Page   |
 |                                       erroring out for certain users
 +===========================================================================*/

package oracle.apps.ar.irec.framework;


import java.sql.Types;

import oracle.apps.ar.irec.accountDetails.server.PrintButtonsPVOImpl;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.ar.irec.util.BusinessObjectsUtils;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jbo.domain.Number;
import oracle.apps.ar.irec.framework.IROAViewObjectImpl;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;
import oracle.apps.fnd.functionSecurity.FunctionSecurity;
import oracle.apps.fnd.common.WebAppsContext;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.ar.irec.framework.server.FndUserPartyIdSetupVOImpl;
import oracle.apps.ar.irec.framework.server.FndUserPartyIdSetupVORowImpl;
import oracle.apps.ar.irec.admin.framework.server.CustIdToPartyIdVOImpl;
import oracle.apps.ar.irec.admin.framework.server.CustIdToPartyIdVORowImpl;

import oracle.jdbc.OracleCallableStatement;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.jtf.base.Logger;

import oracle.jbo.ViewObject;
import oracle.jbo.Row;
import oracle.apps.ar.irec.framework.server.CurrentCustomerContextVOImpl;
import oracle.apps.ar.irec.framework.server.CurrentCustomerContextVORowImpl ;
import oracle.apps.fnd.framework.OARow;


import oracle.apps.ar.irec.common.server.ArwSearchCustomers;
import oracle.apps.ar.irec.common.server.ArwSearchCustomers.CustsiteRec;

import oracle.apps.ar.irec.common.server.ExternalUserSearchResultsVOImpl;
import oracle.apps.ar.irec.common.server.ExternalUserSearchResultsVORowImpl;
import com.sun.java.util.collections.ArrayList;
import oracle.jbo.RowSetIterator;

/**
 * the iReceivables basic Application Module.
 * contains methods that can be used to keep track of whether a page
 * has been visited in the current Transaction.
 *
 * @author 	Mohammad Shoaib Jamall
 */

public abstract class IROAApplicationModuleImpl extends oracle.apps.fnd.framework.server.OAApplicationModuleImpl
{

  public static final String RCS_ID="$Header: IROAApplicationModuleImpl.java 120.16.12020000.2 2012/07/22 02:39:27 rsinthre ship $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "oracle.apps.ar.irec.framework");

  /**
    * This is the default constructor (do not remove)
    */
  public IROAApplicationModuleImpl()
  {
  }

  /**
  * specifies that the page has been visited and puts the
  * vUniqueRegionKey, vRegionID Key/Value pair in
  * the transaction cache. Adds the String getPageAmCode()
  * to the vUniqueRegionKey to form the Key/Value pair that is
  * actually stored.
  * <p>
  * example of intended use {@link webui.VisibilityCO}:
  *
  *
  * @param vRegionID
  * @param vUniqueRegionKey
  *
  */
  public void setPageVisited(String vRegionID, String vUniqueRegionKey)
  {
    getOADBTransaction().putValue(getPageAmCode() + vUniqueRegionKey, vRegionID);
  }

  /**
  * is the page visited before, in this transaction? this simply checks to
  * see if something with our Key is cached.
  *
  * @param vUniqueRegionKey
  *
  * @return has region been visited
  *
  * @see #isPageVisited(String vRegionID, String vUniqueRegionKey)
  */
  public Boolean isPageVisited(String vUniqueRegionKey)
  {
    Object pageVisited = getOADBTransaction().getValue( getPageAmCode() + vUniqueRegionKey);
    return new Boolean ( (pageVisited != null) && (!(pageVisited.equals("~"))));
  }

  /**
  * is the page visited before in this transaction? this checks if the
  * value cached corresponding to our Key is equal to vRegionID
  *
  * @param vRegionID
  * @param vUniqueRegionKey
  *
  * @return has region been visited
  *
  * @see #isPageVisited(String vUniqueRegionKey)
  */
  public Boolean isPageVisited(String vRegionID, String vUniqueRegionKey)
  {

    Object pageVisited = getOADBTransaction().getValue( getPageAmCode() + vUniqueRegionKey);
    Boolean isPageVisited;
    if (null == pageVisited) isPageVisited = new Boolean (false);
    else
    {
      isPageVisited = new Boolean(pageVisited.equals(vRegionID));
    }
    return isPageVisited;
  }

  /**
  * bugfix 1671116 : sjamall 06/04/2001
  * Warning: method deprecated:
  *
  * get text from pl/sql packages. the plsql procedure should be of form
  * <procedure>(x_output_string OUT VARCHAR2, x_customer_id IN VARCHAR2,
  * x_customer_site_use_id IN VARCHAR2, x_language_string IN VARCHAR2)
  *
  * @param pkg: package name
  * @param proc: procedure name
  * @param customerId
  * @param customerSiteUseId
  * @param vUniqueRegionKey
  *
  * @return text from plsql package
  *
  * @deprecated Replace by getTextFromPackage(String pkg, String proc,
  *                        String userId, String customerId,
  *                        String customerSiteUseId)
  *
  * @see oracle.apps.ar.irec.homepage.webui.ColumnTwoCO#processRequest(OAPageContext, OAWebBean) for an example of usage.
  */
  public String getTextFromPackage(String pkg, String proc, String customerId, String customerSiteUseId)
  {
    // the framework returns a '{}' for parameters when they have
    // a null value and they are encrypted out of the database.
    // see bug 1718439
    if (customerId != null)
    {
      try{ Number customerIdNumber = new Number(customerId);  }
      catch (Exception e)  { customerId = null; }
    }
    if (customerSiteUseId != null)
    {
      try{ Number siteUseIdNumber = new Number(customerSiteUseId);  }
      catch (Exception e) { customerSiteUseId = null; }
    }

    OADBTransaction tx = (OADBTransaction) getDBTransaction();
    String returnString = null;
    String sql = "BEGIN" +
    " " + pkg + "." + proc + " (" +
    "	x_output_string		=>	:1 , " +
    "	x_customer_id		=>	" + ((null == customerId) ? "null" : customerId) + " , " +
    "	x_customer_site_use_id		=>	" + ((null == customerSiteUseId) ? "null" : customerSiteUseId ) + " , " +
    "	x_language_string		=>	'" + tx.getCurrentLanguage() + "' " +
    "	);" + " END;";

    // Bug Fix - 1887440
    //CallableStatement cStmt = tx.createCallableStatement(sql, 1);
    OracleCallableStatement cStmt = (OracleCallableStatement)tx.createCallableStatement(sql, 1);

    try
    {
      // Bug Fix - 1887440
      // Need to specify lenght in order to avoid 32K memory usage.
      //cStmt.registerOutParameter(1, Types.VARCHAR);
      cStmt.registerOutParameter(1, Types.VARCHAR, 0, 4000 );
      cStmt.execute();
      returnString = cStmt.getString(1);
    }
    catch(Exception e)
    { 
      try
      {
        if(Logger.isEnabled(Logger.EXCEPTION))
          Logger.out(e, OAFwkConstants.EXCEPTION, Class.forName("oracle.apps.ar.irec.framework.IROAApplicationModuleImpl"));
      }
      catch(ClassNotFoundException cnfE){}
      throw OAException.wrapperException(e); 
    }
    finally
    {
      try {cStmt.close();}
      catch(Exception e) { throw OAException.wrapperException(e); }
    }

    return (null == returnString) ? "" : returnString;

  }

  /**
  * bugfix 1671116 : sjamall 06/04/2001
  * get text from pl/sql packages. the plsql procedure should be of form
  * <procedure>(p_user_id IN NUMBER, p_customer_id IN NUMBER,
  * p_site_use_id IN NUMBER, p_language IN VARCHAR2,  p_output_string OUT VARCHAR2, )
  *
  * @param pkg: package name
  * @param proc: procedure name
  * @param userId
  * @param customerId
  * @param customerSiteUseId
  * @param vUniqueRegionKey
  *
  * @return text from plsql package
  *
  * @see oracle.apps.ar.irec.homepage.webui.ColumnTwoCO#processRequest(OAPageContext, OAWebBean) for an example of usage.
  */
  public String getTextFromPackage(String pkg, String proc, String userId, String customerId, String customerSiteUseId, String encryptedCustomerId , String encryptedCustSiteUseId ,int size)
  {
    // Modifed for Bug# 14142122
    long siteUseIdNumber = -1;
    long customerIdNumber = -1;
    long userIdNumber = -1;

    // the framework returns a '{}' for parameters when they have
    // a null value and they are encrypted out of the database.
    // see bug 1718439
    if (customerId != null)
    { // Modifed for Bug# 14142122
      try{ customerIdNumber = Long.valueOf(customerId).longValue();  }
      catch (Exception e)  { customerIdNumber = -1; }
    }
    if (customerSiteUseId != null)
    {  // Modifed for Bug# 14142122
      try{ siteUseIdNumber = Long.valueOf(customerSiteUseId).longValue();  }
      catch (Exception e) { siteUseIdNumber = -1; }
    }
    if (userId != null)
    { // Modifed for Bug# 14142122
      try{ userIdNumber = Long.valueOf(userId).longValue();  }
      catch (Exception e)  { userIdNumber = -1; }
    }

    OADBTransaction tx = (OADBTransaction) getDBTransaction();
    String returnString = null;
    String sql = "BEGIN" +
    " " + pkg + "." + proc + " (" +
    "	p_output_string		=>	:1 , " +
    "	p_user_id		=>	:2 , " +
    "	p_customer_id		=>	:3 , " +
    "	p_site_use_id		=>	:4 , " +
    "	p_encrypted_customer_id		=>	:5 , " +
    "	p_encrypted_site_use_id		=>	:6 , " +
    "	p_language		=>	'" + tx.getCurrentLanguage() + "' " +
    "	);" + " END;";

    // Bug Fix - 1887440
    // CallableStatement cStmt = tx.createCallableStatement(sql, 1);
    OracleCallableStatement cStmt = (OracleCallableStatement)tx.createCallableStatement(sql, 1);

    try
    {
      // Bug Fix - 1887440
      // Need to specify lenght in order to avoid 32K memory usage.
      //cStmt.registerOutParameter(1, Types.VARCHAR);
      if (-1 == size)
        cStmt.registerOutParameter(1, Types.VARCHAR, 0, 8000);
      else
        cStmt.registerOutParameter(1, Types.VARCHAR,
                                   0 /* this parameter is not used */, size);
      cStmt.setLong(2, userIdNumber);
      cStmt.setLong(3, customerIdNumber);
      cStmt.setLong(4, siteUseIdNumber);
      cStmt.setString(5, encryptedCustomerId);
      cStmt.setString(6, encryptedCustSiteUseId);
      cStmt.execute();
      returnString = cStmt.getString(1);
    }
    catch(Exception e)
    { 
      try
      {
        if(Logger.isEnabled(Logger.EXCEPTION))
          Logger.out(e, OAFwkConstants.EXCEPTION, Class.forName("oracle.apps.ar.irec.framework.IROAApplicationModuleImpl"));
      }
      catch(ClassNotFoundException cnfE){}
      throw OAException.wrapperException(e); 
    }
    finally
    {
      try {cStmt.close();}
      catch(Exception e) { throw OAException.wrapperException(e); }
    }

    return (null == returnString) ? "" : returnString;

  }

/*  public String getTextFromPackage(String pkg, String proc, String userId, String customerId, String customerSiteUseId)
  {
    return getTextFromPackage(pkg, proc, userId, customerId, customerSiteUseId, 4000);
  } */
  public String getLargeTextFromPackage(String pkg, String proc, String userId, String customerId, String customerSiteUseId , String encryptedCustomerId , String encryptedCustSiteUseId)
  {
    return getTextFromPackage(pkg, proc, userId, customerId, customerSiteUseId, encryptedCustomerId,encryptedCustSiteUseId , -1);
  }

  /**
  * get text from pl/sql packages. the plsql procedure should be of form
  * <procedure>(x_output_string OUT NUMBER, x_customer_id IN VARCHAR2,
  * x_customer_site_use_id IN VARCHAR2, x_language_string IN VARCHAR2)
  *
  * @param pkg: package name
  * @param proc: procedure name
  * @param customerId
  * @param customerSiteUseId
  * @param vUniqueRegionKey
  *
  * @return integer from plsql package
  *
  * @see oracle.apps.ar.irec.accountDetails.TableVOO#getRowNumberLimit(String customerId, String customerSiteUseId)
  * for an example of usage.
  */
  public int getIntegerFromPackage(String pkg, String proc, String customerId, String customerSiteUseId)  {
    OADBTransaction tx = (OADBTransaction) getDBTransaction();
    int returnInt;
    String sql = "BEGIN" +
    " " + pkg + "." + proc + " (" +
    "	x_output_number		=>	:1 , " +
    "	x_customer_id		=>	" + ((isNullString(customerId)) ? "null" : customerId) + " , " +
    "	x_customer_site_use_id		=>	" + ((isNullString(customerSiteUseId)) ? "null" : customerSiteUseId ) + " , " +
    "	x_language_string		=>	'" + tx.getCurrentLanguage() + "' " +
    "	);" + " END;";

    // Bug Fix - 1887440
    // CallableStatement cStmt = tx.createCallableStatement(sql, 1);
    OracleCallableStatement cStmt = (OracleCallableStatement)tx.createCallableStatement(sql, 1);

    try
    {
      cStmt.registerOutParameter(1, Types.INTEGER);
      cStmt.execute();
      returnInt = cStmt.getInt(1);
    }
    catch(Exception e)
    { 
      try
      {
        if(Logger.isEnabled(Logger.EXCEPTION))
          Logger.out(e, OAFwkConstants.EXCEPTION, Class.forName("oracle.apps.ar.irec.framework.IROAApplicationModuleImpl"));
      }
      catch(ClassNotFoundException cnfE){}
      throw OAException.wrapperException(e); 
    }
    finally
    {
      try {cStmt.close();}
      catch(Exception e) { throw OAException.wrapperException(e); }
    }

    return returnInt;

  }

  /**
  * get the active currency code of the application. methods getCurrencyCodeVO()
  * and getCurrencyCodeAttribute() have to be defined in the implementing AM
  * to tell the AM where it should be getting the currency code from.
  *
  * @return String the currency code active
  *
  * @see oracle.apps.ar.irec.accountDetails.inv.server.InvoiceDisputeAMImpl
  * for an example of usage.
  */
  public String getActiveCurrencyCode()
  {
    IROAViewObjectImpl currVO =
      (IROAViewObjectImpl)findViewObject(getCurrencyCodeVO());
    String currency = (String)currVO.getFirstObject(getCurrencyCodeAttribute());
    return currency;
  }

  /**
   * tests to see if function is valid for current Fnd User Responsibility.
   * for example usage @see
   * oracle.apps.ar.irec.accountDetails.inv.webui.LinesOrActivitiesButtonsCO
   */
  public Boolean testFunctionValid(String functionName)
  {
    // sjamall 05/16/2001 bugfix 1775020
    boolean function = false;
    {
      OADBTransactionImpl txn = (OADBTransactionImpl)getOADBTransaction();
      //Bug 4508705 - Removing Deprecated Class FunctionManager and replaced with FunctionSecurity
      FunctionSecurity fs = new FunctionSecurity((WebAppsContext)txn.getAppsContext());
      
      function = fs.testFunction(fs.getFunction(functionName), fs.getUser(), fs.getResp(txn.getResponsibilityId(), txn.getResponsibilityApplicationId()), fs.getSecurityGroup());
    }
    return new Boolean(function);
  }

  /**
  * checks if user is iReceivables External Customer
  *
  * @return boolean
  */
  public final Boolean isExternalCustomer ()
  {
    return testFunctionValid("ARI_EXTERNAL_ACCESS");
  }

  /**
  * checks if user is iReceivables Internal Customer
  *
  * @return boolean
  */
  public final Boolean isInternalCustomer ()
  {
    return testFunctionValid("ARI_INTERNAL_ACCESS");
  }

  /**
   * method for getting current fnd user id. For an example use @see:
   * oracle.apps.ar.irec.accountDetails.homepage.webui.ColTwoCO
   */
  public String getUserId ()
  {
    // get user id
    OADBTransaction trans = getOADBTransaction();
    String userId = Integer.toString(trans.getUserId());
    return userId;
  }
  /**
   * need to override this method to return a View Object Name which contains
   * the Active Currency Code.
   *
   * @return String Currency Code View Object
   */
  protected String getCurrencyCodeVO()
  {
    throw new OAException
    ("Unexpected Error in oracle.apps.ar.irec.framework.IROAApplicationModule.java" );
  }

  /**
   * need to override this method to return a View Object Attribute name which
   * contains the Active Currency Code.
   *
   * @return String Currency Code View Object Attribute
   */
  protected String getCurrencyCodeAttribute()
  {
    throw new OAException
    ("Unexpected Error in oracle.apps.ar.irec.framework.IROAApplicationModule.java" );
  }

  // this has to be unique amongst application modules.
  protected final String getPageAmCode()
  {
    return(getClass().getName());
  }

  private boolean isNullString (String value)
  {
    return BusinessObjectsUtils.isNullString(value);
  }

  public String getOrgPartyId(String sCustomerId)
  {
    CustIdToPartyIdVOImpl vo = (CustIdToPartyIdVOImpl)findViewObject("CustIdToPartyIdVO");
    if(vo == null)
      vo = (CustIdToPartyIdVOImpl)createViewObject("CustIdToPartyIdVO", "oracle.apps.ar.irec.admin.framework.server.CustIdToPartyIdVO");
      
    vo.initQuery(sCustomerId);
    CustIdToPartyIdVORowImpl row = (CustIdToPartyIdVORowImpl)vo.first();

    String sOrgPartyId = (row.getPartyId()).toString();
    return sOrgPartyId;      
  }

  public String getPersonPartyId()
  {
    FndUserPartyIdSetupVOImpl vo = (FndUserPartyIdSetupVOImpl)findViewObject("FndUserPartyIdSetupVO");
    if(vo == null)
      vo = (FndUserPartyIdSetupVOImpl)createViewObject("FndUserPartyIdSetupVO", "oracle.apps.ar.irec.framework.server.FndUserPartyIdSetupVO");
      
    vo.initQuery(getUserId());
    FndUserPartyIdSetupVORowImpl row = (FndUserPartyIdSetupVORowImpl)vo.first();

    if(row == null)
      return "DISABLED";

    String sPersonPartyId = (row.getPersonPartyId()).toString();
    return sPersonPartyId;      
  }

  public String getSelectedPartyId()
  {
    FndUserPartyIdSetupVOImpl vo = (FndUserPartyIdSetupVOImpl)findViewObject("FndUserPartyIdSetupVO");
    vo.initQuery(getUserId());
    FndUserPartyIdSetupVORowImpl row = (FndUserPartyIdSetupVORowImpl)vo.first();

    if(row == null)
      return "DISABLED";

    String sSelectedPartyId = (row.getSelectedPartyId()).toString();
    return sSelectedPartyId;      
  }

  public void commitTransaction()
  {
      getTransaction().commit();
  }

  //Bug 4071551 - Performance issues while adding records to transaction list
   /**
   * 
   * Method to compute service charge for records chosen in transaction list
   */
  public void computeServiceCharge(String sCustomerId, String sCustomerSiteUseId, String sPaymentType, String sLookupCode)
  {
    OADBTransaction tx = (OADBTransaction) getDBTransaction();

    String sql = "BEGIN :1 := ar_irec_payments.get_service_charge(:2, :3, :4, :5); END;";

    OracleCallableStatement callStmt = (OracleCallableStatement)tx.createCallableStatement(sql, 1);

    double totalServiceCharge = 0; 

    try
    {
      callStmt.registerOutParameter(1, Types.DOUBLE);
      callStmt.setString(2, sCustomerId);
      callStmt.setString(3, sCustomerSiteUseId);
      callStmt.setString(4, sPaymentType);
      callStmt.setString(5, sLookupCode);
      callStmt.execute();
      totalServiceCharge = callStmt.getDouble(1);
    }
    catch(Exception e)
    {
      try
      {
        if(Logger.isEnabled(Logger.EXCEPTION))
          Logger.out(e, OAFwkConstants.EXCEPTION, Class.forName("oracle.apps.ar.irec.framework.IROAApplicationModuleImpl"));
      }
      catch(ClassNotFoundException cnfE){}
      throw OAException.wrapperException(e);
    }
    finally
    {
      try
      {
        callStmt.close();
      }
      catch(Exception e)
      {
        throw OAException.wrapperException(e);
      }
    }

  }

  //Bug 4232383 - Moved the function here for public use
  public Number getDiscountAmount(String sPmtSchId , String sRemAmt)
   {
    OADBTransactionImpl tx = (OADBTransactionImpl)getOADBTransaction();
    String sql = "BEGIN :1 := ar_irec_payments.get_discount_wrapper( :2 ,:3 ); END;";
    float fDiscAmt = 0 ;
                 
    // Create the callable statement
    OracleCallableStatement callStmt = (OracleCallableStatement)tx.createCallableStatement(sql, 1);
    try
    {
      callStmt.registerOutParameter(1,Types.NUMERIC);
      callStmt.setString(2, sPmtSchId);
      Number nRemAmt=null;
      if(sRemAmt!=null && !"".equals(sRemAmt)) 
      {
          //nRemAmt = new Number(this.getOADBTransaction().getOANLSServices().stringToNumber(sRemAmt));   
          //Bug 11864017 - sRemAmt is coming as 234.4 and not in user preference format. 
          //So, no need to convert the string sRemAmt from user preference format
          nRemAmt = new Number(sRemAmt);
      }
      callStmt.setDouble(3, (nRemAmt==null?0:nRemAmt.doubleValue()));
      callStmt.execute();

      fDiscAmt = (float) callStmt.getFloat(1);
      
    } catch(Exception e) {
      try
      {
        if(Logger.isEnabled(Logger.EXCEPTION))
          Logger.out(e, OAFwkConstants.EXCEPTION, Class.forName("oracle.apps.ar.irec.framework.IROAApplicationModuleImpl"));
      }
      catch(ClassNotFoundException cnfE){}
      throw OAException.wrapperException(e);
    } finally {
      try {
        callStmt.close();
      } catch(Exception e) {
        throw OAException.wrapperException(e);
      }
    } 
           
    return new Number(fDiscAmt);
   }
   
   
  /** Account/Site grouping - Bug # 5862963
    * This method initialize the customer context.
    * 
    * This method executes the query to get coustomer drop down list populated. 
    * It returns the customerId if there is just one row in VO , else returns NULL
    * 
    * @param null
    * @return customerId (String)
    *     
    */
    public String initCustomerContext()
    {
      OADBTransaction trxn = this.getOADBTransaction();
      int sesId = trxn.getSessionId() ;
      Number nCustId = null ;
      String currCustId = null ;
      Number sessionId = null ;

      try{ sessionId = new Number(sesId);  }
      catch (Exception e)  { sessionId = null; }

      CurrentCustomerContextVOImpl custContextVo = (CurrentCustomerContextVOImpl)findViewObject("CurrentCustomerContextVO"); ;
      
      int count = 0 ;
      if(custContextVo!=null)
        { 
          custContextVo.initQuery(sessionId);
          while(custContextVo.hasNext())
          {
            count++;
            custContextVo.next();
            if(count>2) break ;
           }

        if(count>1)
         {
           currCustId = null ;
         }
        else
        {
          CurrentCustomerContextVORowImpl custContextRow = (CurrentCustomerContextVORowImpl) custContextVo.first();
          if(custContextRow!=null)
            {
              nCustId=(Number)custContextRow.getCustAccountId();
              currCustId=nCustId.toString() ;
            }
        }
         
        }
          
      return currCustId ;
      
    }

    
    public String initCustomerSiteContext(String custId)
    {
      ViewObject customerSiteContextVo = null ;
      customerSiteContextVo = (ViewObject) createViewObjectFromQueryStmt(null , "select distinct customer_site_use_id from ar_irec_user_acct_sites_all where user_id = FND_GLOBAL.USER_ID AND session_id = :1 AND customer_id = :2" );

      OADBTransaction trxn = this.getOADBTransaction();
         int sesId = trxn.getSessionId() ;
         Number sessionId = null ;

        try{ sessionId = new Number(sesId);  }
        catch (Exception e)  { sessionId = null; }

      customerSiteContextVo.setWhereClauseParams(null);
      customerSiteContextVo.setWhereClauseParam(0,sessionId);
      customerSiteContextVo.setWhereClauseParam(1,custId);
      customerSiteContextVo.executeQuery();

      int siteCount = 0 ;
      String custSiteId = null ;
      Row row = null ;
      while(customerSiteContextVo.hasNext())
       {
          row = customerSiteContextVo.next();
          custSiteId = row.getAttribute(0).toString() ;
          siteCount++;

          if(siteCount>1) break ;
       }
      customerSiteContextVo.remove(); 

     if(siteCount > 1) custSiteId = null ;

     return custSiteId ;
    }

    
    /** Account/Site grouping - Bug # 5862963
    * 
    * This method returns 'Y' or 'N' depending on the current user's customer context.
    *  'Y' if the user is in context of more than one customer account, 'N' otherwise
    *  
    * @param null
    * @return 'Y' or 'N'
    *     
    */
     public String isMultiCustomerContext()
    {
      String multiCustCont = "N" ;
      int count = 0 ;
      CurrentCustomerContextVOImpl custContextVo = (CurrentCustomerContextVOImpl)findViewObject("CurrentCustomerContextVO"); 
      
      if(!custContextVo.isExecuted())
       {
         OADBTransaction trxn = this.getOADBTransaction();
         int sesId = trxn.getSessionId() ;
         Number sessionId = null ;

        try{ sessionId = new Number(sesId);  }
        catch (Exception e)  { sessionId = null; }
        custContextVo.initQuery(sessionId);
       }

      custContextVo.reset();
      while(custContextVo.hasNext())
          {
            count++;
            custContextVo.next();
            if(count>2) break ;
           }

      if (count>1) multiCustCont = "Y" ;

      return multiCustCont ;     
    }



    /** Account/Site grouping - Bug # 5862963
    * 
    * This returns count of distinct customer account in current user context 
    *  
    * @param null
    * @return Number
    *     
    */
    public Number getCurrentCustomerAccessCount()
    {
      int count = 0 ;
      Number CustCount = null ;
      CurrentCustomerContextVOImpl custContextVo = (CurrentCustomerContextVOImpl)findViewObject("CurrentCustomerContextVO"); 
      
      if(!custContextVo.isExecuted())
       {
         OADBTransaction trxn = this.getOADBTransaction();
         int sesId = trxn.getSessionId() ;
         Number sessionId = null ;

        try{ sessionId = new Number(sesId);  }
        catch (Exception e)  { sessionId = null; }
        custContextVo.initQuery(sessionId);
       }

      custContextVo.reset();
      while(custContextVo.hasNext())
          {
            count++;
            custContextVo.next();
           }

      if(count>2) count-- ;  // subtract one for the 'All Customer Accounts row' if count is > 2
      
      try{ CustCount = new Number(count);  }
        catch (Exception e)  { CustCount = null; }

      return CustCount ;
       
    }
    
  // bug # 7432149   
  // this function will allow you to hide/show the IcxPrintablePageButton,BpaPrintViewButton,PrintViewButton  

   public void setTrxDetailsPrintButtons(String icxPrintablePage,String bpaPrintablePage,String printPreview)
     {

       PrintButtonsPVOImpl printButtonsPVO = (PrintButtonsPVOImpl)findViewObject("PrintButtonsPVO");

       if (printButtonsPVO != null)
        {
          OARow PrntPrvwPVrow = null ;
          if (printButtonsPVO.getFetchedRowCount() == 0)
            {
              printButtonsPVO.setMaxFetchSize(0);
              printButtonsPVO.executeQuery();
              printButtonsPVO.insertRow(printButtonsPVO.createRow());
        
               PrntPrvwPVrow = (OARow)printButtonsPVO.first();
               PrntPrvwPVrow.setAttribute("RowKey", new Number(1));
             }
          else
            {
              PrntPrvwPVrow = (OARow) printButtonsPVO.first() ;
             }
          PrntPrvwPVrow.setAttribute("IcxPrintablePageButton",new Boolean(icxPrintablePage));
          PrntPrvwPVrow.setAttribute("BpaPrintablePageButton", new Boolean(bpaPrintablePage));
          PrntPrvwPVrow.setAttribute("PrintPreview", new Boolean(printPreview));
          
          }
       
     } 
     
  public void initAccountsAndSites(Long partyID,Long orgID,Long userID,Long sessionID,Long custID, Long siteID,String isInternalCustomer,String isAccountGroup )
    {
      ArwSearchCustomers.CustsiteRec[] custsiteRecArray=null;      
      Number partyIDnum = (partyID==null)?null:new Number(partyID.longValue());
      Number orgIDnum = (orgID==null)?null:new Number(orgID.longValue());
      Number userIDnum = (userID==null)?null:new Number(userID.longValue());
      Number sessionIDnum = (sessionID==null)?null:new Number(sessionID.longValue());
      Number custIDnum = (custID==null)?null:new Number(custID.longValue());
      Number siteIDnum = (siteID==null)?null:new Number(siteID.longValue());
      
      String strLargeCust = "";
      if (siteIDnum != null)
        strLargeCust = isLargeCustomer( custID.toString(), siteIDnum.toString());
      else 
        strLargeCust = isLargeCustomer( custID.toString());      
    
      /*if( "N".equals(strLargeCust)) {
        try 
        {
          if(isAccountGroup.equals("Y") || (custIDnum!=null))
          {
            ArwSearchCustomers.CustsiteRec rec= new ArwSearchCustomers.CustsiteRec();
            rec.setCustomerid(custIDnum);
            rec.setSiteuseid(siteIDnum);
            custsiteRecArray = new ArwSearchCustomers.CustsiteRec[] {rec};
          }
          else
          {
            custsiteRecArray=getCustsiteRecArray();
          }
          OADBTransaction tx = (OADBTransaction)this.getDBTransaction();
          ArwSearchCustomers.initializeAccountSites(tx,custsiteRecArray,partyIDnum,sessionIDnum,userIDnum,orgIDnum,isInternalCustomer);
        }
        catch(Exception e)
        {
          throw OAException.wrapperException(e);
        }
      }*/ 
    }    

  /**
   * This method is responsible for creating array of customerid and siteid pair which are selected 
   * on the customer search page.
   * Bug # 5858769 
  */
  public ArwSearchCustomers.CustsiteRec[] getCustsiteRecArray() throws Exception{
    ArwSearchCustomers.CustsiteRec siteRec = null;
    Number customerId = null;
    Number siteUseId = null;

      ExternalUserSearchResultsVOImpl exVO = ((ExternalUserSearchResultsVOImpl)this.findViewObject("ExternalUserSearchResultsVO"));
      if(!exVO.isExecuted()) return null;
      RowSetIterator iter = exVO.createRowSetIterator("iter");
      iter.reset();
      ArrayList recList = new ArrayList();  
      
      while (iter.hasNext()) {

        ExternalUserSearchResultsVORowImpl row = (ExternalUserSearchResultsVORowImpl)iter.next();

        String sSelected = ((row.getSelected() == null) ? "N":row.getSelected());

        if (sSelected.equals("Y")) {
          customerId = row.getCustomerId();
          siteUseId =  (row.getBillToSiteUseId()==null || row.getBillToSiteUseId().equals(""))
          ?null:new Number(row.getBillToSiteUseId());
    ArwSearchCustomers.CustsiteRec rec= new CustsiteRec();
    rec.setCustomerid(customerId);
    rec.setSiteuseid(siteUseId);
    recList.add(rec);

        }
        //Close RowSetIterator
        
      }
      iter.closeRowSetIterator();
      ArwSearchCustomers.CustsiteRec[] arr = new ArwSearchCustomers.CustsiteRec[recList.size()];
       recList.toArray(arr); 


      

     return arr;
  }     

  // added for bug 10015700 
  public String getXMLFormattedString(String sFormateString)
  {
    String xmlFormattedString = null;
    xmlFormattedString = replace(sFormateString, "&", "&amp;");
    xmlFormattedString = replace(xmlFormattedString, "<", "&lt;");
    xmlFormattedString = replace(xmlFormattedString, ">", "&gt;");

    return xmlFormattedString;
  }
  
  // added for bug 10015700 
  public static String replace(String source, String pattern, String replace)
  {
    if (source!=null)
    {
    final int len = pattern.length();
    StringBuffer sb = new StringBuffer();
    int found = -1;
    int start = 0;

    while( (found = source.indexOf(pattern, start) ) != -1) {
        sb.append(source.substring(start, found));
        sb.append(replace);
        start = found + len;
    }

    sb.append(source.substring(start));

    return sb.toString();
    }
    else return "";
  }

  public String isLargeCustomer(String strCustomerId, String strCustomerSiteUseId){
     OADBTransaction txn = (OADBTransaction)this.getDBTransaction();
     OracleCallableStatement oraclecallablestatement =  null;
     String strIsLargeCust = "N";
     String populateSession = "Y";
     String sessionID=txn.getSessionId() + "";
     try {
         String strSqlStmt = "BEGIN :1 := XX_FIN_ARI_UTIL.IS_LARGE_CUSTOMER(p_customer_id => :2, P_CUSTOMER_SITE_USE_ID => :3, p_session_id => :4, p_populate_session => :5); END;";
    
         oraclecallablestatement = 
             (OracleCallableStatement)txn.createCallableStatement(strSqlStmt, 1);
             if (oraclecallablestatement != null) {
               oraclecallablestatement.registerOutParameter(1, Types.VARCHAR, 0, 1);
               oraclecallablestatement.setString(2, strCustomerId);
               oraclecallablestatement.setString(3, strCustomerSiteUseId);
               oraclecallablestatement.setString(4, sessionID);              
               oraclecallablestatement.setString(5, populateSession);
               oraclecallablestatement.execute();
               strIsLargeCust = oraclecallablestatement.getString(1);
             }
    
     } catch (Exception ex) {
         try {
             if (oraclecallablestatement != null)
                 oraclecallablestatement.close();
         } catch (Exception ex2) {
         }
     }
     return strIsLargeCust;
    }

   public String isLargeCustomer(String strCustomerId){
    OADBTransaction txn = (OADBTransaction)this.getDBTransaction();
    OracleCallableStatement oraclecallablestatement =  null;
    String strIsLargeCust = "N";
    String populateSession = "Y";
    String sessionID=txn.getSessionId() + "";
    try {
        String strSqlStmt = "BEGIN :1 := XX_FIN_ARI_UTIL.IS_LARGE_CUSTOMER(p_customer_id => :2, p_session_id => :3, p_populate_session => :4); END;";

        oraclecallablestatement = 
            (OracleCallableStatement)txn.createCallableStatement(strSqlStmt, 1);
            if (oraclecallablestatement != null) {
              oraclecallablestatement.registerOutParameter(1, Types.VARCHAR, 0, 1);
              oraclecallablestatement.setString(2, strCustomerId);
              oraclecallablestatement.setString(3, sessionID);              
              oraclecallablestatement.setString(4, populateSession);
              oraclecallablestatement.execute();
              strIsLargeCust = oraclecallablestatement.getString(1);
            }

    } catch (Exception ex) {
        try {
            if (oraclecallablestatement != null)
                oraclecallablestatement.close();
        } catch (Exception ex2) {
        }
    }
    return strIsLargeCust;
  }
  
}




