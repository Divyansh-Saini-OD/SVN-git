package od.oracle.apps.xxcrm.asn.common.customer.server;

import oracle.apps.fnd.framework.OAViewObject;
import od.oracle.apps.xxcrm.hz.account.customer.server.ODSiteUsageVOImpl;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.apps.fnd.framework.OARow;
import oracle.jbo.Row;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

import od.oracle.apps.xxcrm.hz.account.customer.server.ODHzCustAccountsVOImpl;
import od.oracle.apps.xxcrm.hz.account.customer.server.ODRelatedAccountVOImpl;
import od.oracle.apps.xxcrm.hz.account.customer.server.ODCreditDunningVOImpl;
import od.oracle.apps.xxcrm.hz.account.customer.server.ODAccountSitesVOImpl;
import od.oracle.apps.xxcrm.hz.account.customer.server.ODAccountSitesVORowImpl;
import od.oracle.apps.xxcrm.hz.account.customer.server.ODAccountContactsVOImpl;
import od.oracle.apps.xxcrm.hz.account.customer.server.ODHzCustAccountsVORowImpl;
import od.oracle.apps.xxcrm.hz.account.customer.server.ODAccountSitesVORowImpl;
import od.oracle.apps.xxcrm.hz.account.customer.server.ODAccountSiteContactsVOImpl;
import od.oracle.apps.xxcrm.hz.account.customer.server.ODAccountSiteContactsVORowImpl;

//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODViewAccountDetAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public ODViewAccountDetAMImpl()
  {
  }

   /**
   * 
   * Container's getter for ODHzCustAccountsVO
   */
  public ODHzCustAccountsVOImpl getODHzCustAccountsVO()
  {
    return (ODHzCustAccountsVOImpl)findViewObject("ODHzCustAccountsVO");
  }
  
  public void initCustAcc(String partyid,String requestID)
  {
      if (partyid !=null)
      { 
        OAViewObject vo = getODHzCustAccountsVO();
         if (!vo.isPreparedForExecution())
         {
           getODHzCustAccountsVO().initQuery(partyid);
           ODHzCustAccountsVORowImpl x1 = (ODHzCustAccountsVORowImpl) getODHzCustAccountsVO().first();
          if (x1 != null)      { x1.setAttribute("SelectFlag","Y");  }
        ODHzCustAccountsVORowImpl row=null;
         if (requestID != null && requestID.length() > 0)
   {
       row = (ODHzCustAccountsVORowImpl)getODHzCustAccountsVO().first();
       while (row != null)
       {
          if (row.getRequestId().toString().equalsIgnoreCase(requestID)) break;
          row  = (ODHzCustAccountsVORowImpl)getODHzCustAccountsVO().next(); 
          row.setAttribute("SelectFlag","Y");
       }
    OAViewObject vor = getODWRFRefVO();
         if (!vor.isPreparedForExecution())
         {
           getODWRFRefVO().initQuery(partyid);
         }
   }
   else
   {
       row = (ODHzCustAccountsVORowImpl)getODHzCustAccountsVO().first();
       if (row != null) row.setAttribute("SelectFlag","Y");
  } 
        
     }
          }
  }

  
 public void initRelAcc() 
  {
 ODHzCustAccountsVORowImpl rowPick1 = (ODHzCustAccountsVORowImpl) getODHzCustAccountsVO().first();
   if (rowPick1 != null ) 
   {
    ODHzCustAccountsVORowImpl rowPick = (ODHzCustAccountsVORowImpl) getODHzCustAccountsVO().getFirstFilteredRow("SelectFlag","Y");
    OAViewObject vo2 = getODRelatedAccountVO();
     if (!vo2.isPreparedForExecution())
   { 
    vo2.setWhereClauseParams(null);
    vo2.setWhereClauseParam(0, rowPick.getCustAccountId());
    vo2.executeQuery();
    
   }
 }
  }
  

 public void initRelAccCur(String params) 
  {
    OAViewObject vo2 = getODRelatedAccountVO();
    vo2.setWhereClauseParams(null);
    vo2.setWhereClauseParam(0, params);
    vo2.executeQuery();
  }

  public void initCreditDunn()
  {
    ODHzCustAccountsVORowImpl rowPick1 = (ODHzCustAccountsVORowImpl) getODHzCustAccountsVO().first();
  if (rowPick1 != null)
   {
    ODHzCustAccountsVORowImpl rowPick = (ODHzCustAccountsVORowImpl) getODHzCustAccountsVO().getFirstFilteredRow("SelectFlag","Y");
    OAViewObject vo3 = getODCreditDunningVO();
     if (!vo3.isPreparedForExecution())
  {
    vo3.setWhereClauseParams(null);
    vo3.setWhereClauseParam(0, rowPick.getCustAccountId());
    vo3.executeQuery();
    }
   }
  }

  public void initCreditDunnCur(String params) 
  {
    OAViewObject vo3 = getODCreditDunningVO();
    vo3.setWhereClauseParams(null);
    vo3.setWhereClauseParam(0, params);
    vo3.executeQuery();
  }  

  public void initAccContacts()
  {
  ODHzCustAccountsVORowImpl rowPick1 = (ODHzCustAccountsVORowImpl) getODHzCustAccountsVO().first();
  if (rowPick1 != null)
   { 
    ODHzCustAccountsVORowImpl rowPick = (ODHzCustAccountsVORowImpl) getODHzCustAccountsVO().getFirstFilteredRow("SelectFlag","Y");
    OAViewObject vo5 = getODAccountContactsVO2();
  
    if (!vo5.isPreparedForExecution())
    {
      vo5.setWhereClauseParams(null);
      vo5.setWhereClauseParam(0, rowPick.getCustAccountId());
      vo5.executeQuery();
    }
   }
   }

   public void initAccContactsCur(String params) 
  { 
    OAViewObject vo5 = getODAccountContactsVO2();




    
    vo5.setWhereClauseParams(null);
    vo5.setWhereClauseParam(0, params);
    vo5.executeQuery();

}
   public void initAccSites()
  {
   ODHzCustAccountsVORowImpl rowPick1 = (ODHzCustAccountsVORowImpl) getODHzCustAccountsVO().first();
      
  if (rowPick1 != null)
   {
    ODHzCustAccountsVORowImpl rowPick = (ODHzCustAccountsVORowImpl) getODHzCustAccountsVO().getFirstFilteredRow("SelectFlag","Y");
    OAViewObject vo = getODAccountSitesVO();
    if (!vo.isPreparedForExecution())
        {
                  vo.setWhereClauseParams(null);
                  vo.setWhereClauseParam(0, rowPick.getAttribute("CustAccountId"));
                  vo.executeQuery();
      ODAccountSitesVORowImpl x1 = (ODAccountSitesVORowImpl) getODAccountSitesVO().first();
          if (x1 != null)      { x1.setAttribute("SelectFlag2","Y");  }
          }
   }     
   }

  public void initAccSitesCur(String params) 
    {
      OAViewObject vo = getODAccountSitesVO();
      vo.setWhereClauseParams(null);
      vo.setWhereClauseParam(0, params);
      vo.executeQuery();
      ODAccountSitesVORowImpl row = (ODAccountSitesVORowImpl) getODAccountSitesVO().first();
          if (row != null)       row.setAttribute("SelectFlag2","Y");
    }  


 public void initAccSitesContacts()
  {
  ODAccountSitesVORowImpl rowPick1 =null;

 if (getODHzCustAccountsVO().first() != null)
{
  rowPick1 = (ODAccountSitesVORowImpl) getODAccountSitesVO().first();
}

  if (rowPick1 != null)
   {
    ODAccountSitesVORowImpl rowPick = (ODAccountSitesVORowImpl) getODAccountSitesVO().getFirstFilteredRow("SelectFlag2","Y");
     OAViewObject vo5 = getODAccountSiteContactsVO1();
    if (!vo5.isPreparedForExecution())
        {
                  vo5.setWhereClauseParams(null);
                  vo5.setWhereClauseParam(0, rowPick.getAttribute("CustSid"));
                  vo5.executeQuery();
          }
    }
  }

   public void initAccSitesContactsCur(String params) 
    {
      OAViewObject vo = getODAccountSiteContactsVO1();
      vo.setWhereClauseParams(null);
      vo.setWhereClauseParam(0, params);
      vo.executeQuery();
    }  

  

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("od.oracle.apps.xxcrm.asn.common.customer.server", "ODViewAccountDetAMLocal");
  }

  /**
   * 
   * Container's getter for ODRelatedAccountVO
   */
  public ODRelatedAccountVOImpl getODRelatedAccountVO()
  {
    return (ODRelatedAccountVOImpl)findViewObject("ODRelatedAccountVO");
  }

  /**
   * 
   * Container's getter for ODCreditDunningVO
   */
  public ODCreditDunningVOImpl getODCreditDunningVO()
  {
    return (ODCreditDunningVOImpl)findViewObject("ODCreditDunningVO");
  }

  /**
   * 
   * Container's getter for ODAccountSitesVO
   */
  public ODAccountSitesVOImpl getODAccountSitesVO()
  {
    return (ODAccountSitesVOImpl)findViewObject("ODAccountSitesVO");
  }



  /**
   * 
   * Container's getter for ODAccountContactsVO2
   */
  public ODAccountContactsVOImpl getODAccountContactsVO2()
  {
    return (ODAccountContactsVOImpl)findViewObject("ODAccountContactsVO2");
  }

  /**
   * 
   * Container's getter for ODAccountSiteContactsVO1
   */
  public ODAccountSiteContactsVOImpl getODAccountSiteContactsVO1()
  {
    return (ODAccountSiteContactsVOImpl)findViewObject("ODAccountSiteContactsVO1");
  }
public ODWRFRefVOImpl getODWRFRefVO()
  {
    return (ODWRFRefVOImpl)findViewObject("ODWRFRefVO");
  }









}
