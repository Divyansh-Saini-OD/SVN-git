    /*===========================================================================+
 |      Copyright (c) 2000 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 |       14-Aug-00  sjamall       Created.                                   |
 |       10-Apr-01  sjamall       bugfix 1636553 :moved the class/transaction|
 |                                type criteria to the xml file(metadata).   |
 |       29-May-01  sjamall       bugfix 1797441 changed sales order keyword |
 |                                search criteria.                           |
 |        06-Aug-01  sjamall      bugfix 1865307 : using                     |
 |                                BusinessObjectsUtils.getCurrency() to get  |
 |                                Currency object from transaction cache.    |
 |        10-Sep-01  sjamall      bugfix 1788892                             |
 |        27-Nov-01  sjamall      bugfix 2125241: replacing reference to     |
 |                                import oracle.apps.fnd.common.Currency by  |
 |                                oracle.apps.fnd.common.CurrencyHelper      |
 |        06-May-02  yreddy       BugFix 2272203: Search the string for ","  |
 |                                and push null into the stack .             |
 |        18-Jul-02  albowicz     BugFix 2445929 Fixed a bug where trans     |
 |                                not associated with a site were being      |
 |                                inadvertantly masked out.                  |
 |        04-Jun-04  vnb          Bug # 1927069 -  The Amount Formatting task|
 |                                has been moved to AccountDetailsBaseCO     |
 |        26-May-05  rsinthre     Bug # 4392371 - OIR needs to support cross |
 |								  customer payment                           |
 |   28-Feb-08 avepati       Bug 6748005 - ADS12.0.03 :FIN:NEED CONSOLIDATED |
 |                             NUMBER FILTER ON ACCOUNT DETAILS PAGE         |
 |     02-Feb-2010 nkanchan  Bug # 9312037 - trxs shud be filtered in the customer statement as well     |
 |   26-Apr-2010   avepati  Bug 9595986-sql exceptn on Cons Billing No search|
 |   25-Aug-2010   avepati   Bug 10053342 - Cons Billing Number throws error |
 |                            for grouping of accounts                       |
 |   27-Apr-11 nkanchan Bug # 11871930 - fp:10151772:provide multi transaction search in account details page|   
 +===========================================================================*/
/**
 * This class contains contains the basic query logic used by the View Objects
 * that we need to form the various result regions of the Account Details Search
 * page.
 *
 * @author 	Mohammad Shoaib Jamall
 */
package oracle.apps.ar.irec.accountDetails;
/*---------------------------------------------------------------------------------
 -- Author: Sridevi Kondoju
 -- Component Id: E1327
 -- Script Location: $CUSTOM_JAVA_TOP/oracle/apps/ar/irec/accountDetails
 -- Description: Considered R12 code and added custom code.
 -- History:
 -- Name            Date         Version    Description
 -- -----           -----        -------    -----------
 -- Sridevi Kondoju 27-Jul-2013   1.0    Retrofitted for R12 Upgrade.
 -- Sridevi Kondoju 3-Oct-2013    2.0    updated for DEFECT 25639
 -- Sridevi Kondoju 11-Oct-2013   3.0    updated for DEFECT 22908
 -- Sridevi Kondoju 16-Dec-2014   4.0    Modified for iRec Enhancement changes.
 --                                      Commented code for perfomance issue to
 --                                      large customers 
 -- Vasu Raparla                  5.0    Retrofitted for R12.2.5 Upgrade
 -- Sridevi K                     5.1     Updated for Defect39675
 -- Madhu Bolli                   5.2    Added Consolidated Invoice Number as 10th parameter
 --                                       in executeQuery
-----------------------------------------------------------------------------------*/
import java.util.ArrayList;
import java.util.HashMap;
import java.sql.Types;

import java.util.Iterator;

import oracle.apps.fnd.common.VersionInfo;
import java.util.StringTokenizer;
import java.util.Stack;
import java.lang.StringBuffer;

import oracle.apps.ar.irec.accountDetails.server.AccountBalanceVOImpl;

import oracle.apps.ar.irec.accountDetails.server.RequestTableVOImpl;
import oracle.apps.ar.irec.accountDetails.server.TotalCMVOImpl;
import oracle.apps.ar.irec.accountDetails.server.TotalOpenInvoicesVOImpl;
import oracle.apps.ar.irec.accountDetails.server.TotalPaymentsVOImpl;
import oracle.apps.ar.irec.accountDetails.server.TotalRequestsVOImpl;

import oracle.jbo.Row;
import oracle.jbo.ViewObject;
import oracle.jbo.domain.Date;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;
import oracle.apps.ar.irec.util.BusinessObjectsUtils;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.server.OADBTransaction;

import oracle.jdbc.OracleCallableStatement;


public abstract class TableVO extends oracle.apps.ar.irec.framework.IROAViewObjectImpl
{

  public static final String RCS_ID="$Header: TableVO.java 120.16 2011/04/27 12:49:39 nkanchan ship $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "oracle.apps.ar.irec.accountDetails");


  /**
  * this method initiates the query to take care of the HLD requirement to
  * create an initial table of the greater of "rownum < 11" or
  * "sysdate - creation_date < 30"
  */
/*  public void initQueryLimitRowCount( String vCurrCode, String vCustId,
                                      String vCustSiteUseId, String vAcctStatus,
                                      String vAcctType, String vKeyword)
  {
    // get the entity to calculate the transactions within the last X days.
    TableVO countObject = (TableVO)getApplicationModule().findViewObject
      ("CountTrxWithinLastXDaysVO");

    initQueryLimitRowCountHelper( vCurrCode, vCustId,
                                  vCustSiteUseId, vAcctStatus,
                                  vAcctType, vKeyword,
                                  countObject);

  }*/

/*  public void initQueryLimitRowCount( String vCurrCode, String vCustId,
                                      String vCustSiteUseId, String vAcctStatus,
                                      String vAcctType, String vRestrict,
                                      String vQuery, String vParams, String vKeyword,
                                      String vOrderNumber, String vOrderType,
                                      String vLineId, String vAmountFrom,
                                      String vAmountTo, Date vTransDateFrom,
                                      Date vTransDateTo, Date vDueDateFrom,
                                      Date vDueDateTo)
  {
    initQueryLimitRowCount( vCurrCode, vCustId, vCustSiteUseId, vAcctStatus,
                            vAcctType, vKeyword);
  }*/

  /*public void initQueryLimitRowCount( String vCurrCode, String vCustId,
                                      String vCustSiteUseId, String vAcctStatus,
                                      String vAcctType, String vKeyword,
                                      String vOrderNumber, String vOrderType,
                                      String vLineId)
  {
    initQueryLimitRowCount( vCurrCode, vCustId, vCustSiteUseId, vAcctStatus,
                            vAcctType, vKeyword);
  }*/

 /* public void initQueryLimitRowCountHelper( String vCurrCode, String vCustId,
                                      String vCustSiteUseId, String vAcctStatus,
                                      String vAcctType, String vKeyword,
                                      TableVO countObject)
  {
    // get the number of transactions in the last X days
    int vBindInteger = 2;
    {
      StringBuffer addWhereClause = new StringBuffer("");
      setWhereClauseParams(null);
      setWhereClause(null);

      vBindInteger = countObject.initQueryHelper( vCurrCode, vCustId,
                     vCustSiteUseId, vAcctStatus,
                     vAcctType, vKeyword,
                     addWhereClause.append(mWithinXdaysClause).append(" AND "),
                     vBindInteger, null, null);

      countObject.setWhereClauseParam(--vBindInteger,
        new oracle.jbo.domain.Number(getRowDaysLimit(vCustId, vCustSiteUseId)));

      countObject.executeQuery(vCurrCode);
    }
    Number countRows = (Number) BusinessObjectsUtils.getFirstObject
                          (countObject.getRowSetIterator(), "CountRows");

    StringBuffer addWhereClause = new StringBuffer("");
    setWhereClauseParams(null);
    setWhereClause(null);


    // bugfix 1796817
    vBindInteger = 0;
    if (containsBindVariablesForMonthsLimit())
    {
      setWhereClauseParam(vBindInteger++, getSimpleSearchDateLimit(vCustId, vCustSiteUseId));
      setWhereClauseParam(vBindInteger++, getSimpleSearchDateLimit(vCustId, vCustSiteUseId));
    }

    //**
    //* set the row limiting clause according to the result of the query to
    //* get the right transaction.
    //*
    vBindInteger++;
    String rowNumClause = " rownum < :" + vBindInteger++ + " ";
    if ( null != countRows )
    {
      if ( countRows.intValue() > getRowNumberLimit(vCustId, vCustSiteUseId) )
      {
        rowNumClause = mWithinXdaysClause;
      }
    }


    vBindInteger = initQueryHelper( vCurrCode, vCustId,
                     vCustSiteUseId, vAcctStatus,
                     vAcctType, vKeyword,
                     addWhereClause.append(rowNumClause).append(" AND "),
                     vBindInteger, null, null);

    if ( rowNumClause.equals(mWithinXdaysClause))
    {
      setWhereClauseParam(--vBindInteger,
                          new oracle.jbo.domain.Number(getRowDaysLimit(vCustId, vCustSiteUseId)));
    }
    else
    {
      setWhereClauseParam(--vBindInteger,
                          new oracle.jbo.domain.Number(getRowNumberLimit(vCustId, vCustSiteUseId)));
    }

    executeQuery(vCurrCode);
  }*/

  public void advancedInitQuery(
    String vCurrCode, String vCustId, String vCustSiteUseId,
	  String relCustId, String relCustSiteId,
    String vAcctStatus, String vAcctType,
    String vRestrict, String vQuery, String vParams, String vKeyword,
    String vOrderNumber, String vOrderType, String vLineId,
    String vAmountFrom, String vAmountTo, String isInternalUser, String personPartyId,
    String paymentVO, String status,String sXXShipToIDValue,String sXXTransactions, String sXXConsBill,
    String sXXPurchaseOrder, String sXXDept,String sXXDesktop, String sXXRelease, Date vTransDateFrom, Date vTransDateTo, 
    Date vDueDateFrom, Date vDueDateTo)
  {
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() vQuery: "+ vQuery, 1);  
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() vCustId: "+ vCustId, 1);  
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() vCustSiteUseId: "+ vCustSiteUseId, 1);  
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() relCustId: "+ relCustId, 1);  
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() relCustSiteId: "+ relCustSiteId, 1);  
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() vAcctStatus: "+ vAcctStatus, 1);  
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() vAcctType: "+ vAcctType, 1);  
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() vRestrict: "+ vRestrict, 1);  
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() vQuery: "+ vQuery, 1);  
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() status: "+ status, 1);  
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() paymentVO: "+ paymentVO, 1);  
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() isInternalUser: "+ isInternalUser, 1);  
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() vKeyword: "+ vKeyword, 1);  
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() vParams: " + vParams, 1);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() vOrderNumber: " + vOrderNumber, 1);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() vOrderType: " + vOrderType, 1);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() vLineId: " + vLineId, 1);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() vAmountFrom: " + vAmountFrom, 1);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() vAmountTo: " + vAmountTo, 1);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() personPartyId: " + personPartyId, 1);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() sXXShipToIDValue: " + sXXShipToIDValue, 1);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() sXXTransactions: " + sXXTransactions, 1);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() sXXConsBill: " + sXXConsBill, 1);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() sXXPurchaseOrder: " + sXXPurchaseOrder, 1);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() sXXDept: " + sXXDept, 1);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() sXXDesktop: " + sXXDesktop, 1);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() sXXRelease: " + sXXRelease, 1);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() vTransDateFrom: " + vTransDateFrom, 1);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() vTransDateTo: " + vTransDateTo, 1);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() vDueDateFrom: " + vDueDateFrom, 1);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() vDueDateTo: " + vDueDateTo, 1);


    OADBTransactionImpl trx = (OADBTransactionImpl)((OAApplicationModuleImpl)getApplicationModule()).getOADBTransaction();
    String sessionId = trx.getSessionId()+"";
    String strUserId = trx.getUserId()+"";
    String strOrgId  = trx.getOrgId()+"";
    executeQuery(     
       vCurrCode,        vCustId,        vCustSiteUseId,
	   relCustId,        relCustSiteId,
       vAcctStatus,      vAcctType,
       vRestrict,        vQuery,         vParams,          vKeyword,
       vOrderNumber,     vOrderType,     vLineId,
       vAmountFrom,      vAmountTo,      isInternalUser,   personPartyId,
       paymentVO,        status,         sXXShipToIDValue, sXXTransactions, sXXConsBill,
       sXXPurchaseOrder, sXXDept,        sXXDesktop,       sXXRelease,      vTransDateFrom, vTransDateTo, 
       vDueDateFrom,     vDueDateTo,     sessionId,        strUserId,       strOrgId
    );
    /*      
    StringBuffer addWhereClause = new StringBuffer("");
    setWhereClauseParams(null);
    setWhereClause(null);
    int vBindInteger = 1;
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() 1 vBindInteger: "+ vBindInteger, 1);
    OADBTransactionImpl trx = (OADBTransactionImpl)((OAApplicationModuleImpl)getApplicationModule()).getOADBTransaction();
    if("Y".equals(paymentVO))
    {
      vBindInteger++;
      vBindInteger++;
    }
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() 2 vBindInteger: "+ vBindInteger, 1);
    // bugfix 1796817 : sjamall 06/14/2001
    if (containsBindVariablesForMonthsLimit())
    {
      vBindInteger++;
      vBindInteger++;
    }
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() 3 vBindInteger: "+ vBindInteger, 1);
    
    // adding SessionId parameter for group my accounts
    vBindInteger++;
    // adding UserId parameter for the query
    vBindInteger++;
  //Start - R12 upgrade
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() 4 vBindInteger: "+ vBindInteger, 1);
        
    String userId = trx.getUserId()+"";
    setWhereClauseParam (--vBindInteger, userId);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() 12 a vBindInteger: "+ vBindInteger, 1);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() 12 a userId: "+ userId, 1);
         // Added for E1327
         if (containsBindVariablesForShipTo())
             vBindInteger++;
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() 5 vBindInteger: "+ vBindInteger, 1);

         // Added for CR619
         if (containsSoftColumns()) {
             if (sXXDept != null && sXXDept.length() > 0) {
                 addWhereClause.append(" LTRIM(RTRIM(XX_COST_CENTER_DEPT)) = :" +
                                                     vBindInteger++); //Added to fix the advance search issue using Cost Center -- QC Defect # 22908
                 addWhereClause.append(" AND ");
             }
             if (sXXDesktop != null && sXXDesktop.length() > 0) {
                 addWhereClause.append(" XX_DESK_DEL_ADDR = :" + vBindInteger++);
                 addWhereClause.append(" AND ");
             }
             if (sXXRelease != null && sXXRelease.length() > 0) {
                 addWhereClause.append(" XX_RELEASE_NUMBER = :" + vBindInteger++);
                 addWhereClause.append(" AND ");
             }
         }
         this.writeDiagnostics(this, "TableVO.advancedInitQuery() 6 vBindInteger: "+ vBindInteger, 1);

         if (sXXPurchaseOrder != null && sXXPurchaseOrder.length() > 0) {
             addWhereClause.append(" ct_purchase_order = :" + vBindInteger++);
             addWhereClause.append(" AND ");
         }
         this.writeDiagnostics(this, "TableVO.advancedInitQuery() 7 vBindInteger: "+ vBindInteger, 1);

         boolean bAddConsBillFilter = false;
         if (sXXConsBill != null && sXXConsBill.length() > 0 && 
             containsConsolidatedBillColumn() && 
             sXXConsBill.matches("^\\d+$")) {
             bAddConsBillFilter = true;
             addWhereClause.append(" xx_cons_inv_id = :" + vBindInteger++);
             addWhereClause.append(" AND ");
         }

         else {
             if (sXXTransactions != null && sXXTransactions.length() > 0) {
                 if (sXXTransactions.indexOf("\n") < 0 && 
                     sXXTransactions.indexOf("\r") < 
                     0) { // // when single row, use delivered approach for transaction search
                     // vQuery = sXXTransactions; for defect39675 
                    vKeyword = sXXTransactions; 

                 } else {
                     String sBucket;
                     String sPurge = "Y";
                     String sSuccess = "X";
                     String lsXXTransactions = 
                         (sXXTransactions + '\n').replace((char)160, 
                                                          (char)32).replace(",", 
                                                                            " ").replace("  ", 
                                                                                         " ").replace(" ", 
                                                                                                      "\n").replace('\r', 
                                                                                                                    '\n').replace("\n\n", 
                                                                                                                                  "\n");

                     int maxChars = 4000; // SQL limitation
                     int maxBuckets = 
                         18; // Arbitrary limitation, but may help agains DoS attack or trying huge amt of data
                     // Assuming trx_numbers are typically 12 characters plus CRLF,
                     // 18 * 4000 = 72,000; 72,000 / 14 = 5,142 trxs... should be plenty
                     int lastPos = 0;
                     int pos = lsXXTransactions.lastIndexOf('\n', maxChars);

                     while (pos > lastPos && !sSuccess.equals("N") && 
                            (maxBuckets-- > 0)) {
                         sBucket = lsXXTransactions.substring(lastPos, pos + 1);
                         if (sBucket.trim().length() > 0) {

                             OADBTransaction txn = 
                                 ((OAApplicationModuleImpl)getApplicationModule()).getOADBTransaction();
                             OracleCallableStatement oraclecallablestatement = 
                                 null;
                             try {
                                 sSuccess = "N";
                                 oraclecallablestatement = 
                                         (OracleCallableStatement)txn.createCallableStatement("CALL XX_IREC_SEARCH_PKG.INSERT_TRX_SEARCH(?,?,?)", 
                                                                                              1);
                                 oraclecallablestatement.setString(1, sBucket);
                                 oraclecallablestatement.setString(2, sPurge);
                                 oraclecallablestatement.registerOutParameter(3, 
                                                                              Types.VARCHAR);
                                 oraclecallablestatement.execute();
                                 if (oraclecallablestatement != null) {
                                     sSuccess = 
                                             oraclecallablestatement.getString(3);
                                     oraclecallablestatement.close();
                                 }
                             } catch (Exception ex) {
                                 try {
                                     if (oraclecallablestatement != null)
                                         oraclecallablestatement.close();
                                 } catch (Ex) {
                                 }
                             }
                             sPurge = "N";
                         }
                         lastPos = pos + 1;
                         pos = 
         lsXXTransactions.lastIndexOf('\n', pos + maxChars);
                     }

                     if (sSuccess.equals("Y"))
                         addWhereClause.append(" trx_number IN (SELECT * FROM XX_ARI_TRX_SEARCH_GT) AND ");

                     //    to include purchase orders in search, use this instead:
                     // stringbuffer.append(" (trx_number IN (SELECT * FROM XX_ARI_TRX_SEARCH_GT) OR ct_purchase_order IN (SELECT * FROM XX_ARI_TRX_SEARCH_GT)) AND ");
                 }
                 this.writeDiagnostics(this, "TableVO.advancedInitQuery() 8 vBindInteger: "+ vBindInteger, 1);

             }
         }

        //End - R12 upgrade


    //Bug 1927069 - Amount Formatting has been moved to AccountDetailsBaseCO,
    //which uses the APIs from OANLSServices.
    ///*try { vAmountFrom = processAmountEntry(vAmountFrom, vCurrCode); }
    //catch (Exception e) {
    //  throw new OAException("AR", "ARI_INVALID_TRX_AMOUNT_FROM");
    //}
    //try {vAmountTo = processAmountEntry(vAmountTo, vCurrCode); }
    //catch (Exception e) {
    //  throw new OAException("AR", "ARI_INVALID_TRX_AMOUNT_TO");
    //}/

    vBindInteger = addExtraQueryClause(addWhereClause, vQuery, vParams, vBindInteger);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() 9 vBindInteger: "+ vBindInteger, 1);

    vBindInteger = addAdvancedSearchAmountFromAndToClause
      (vAmountFrom, vAmountTo, addWhereClause, vCurrCode, vBindInteger);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() 10 vBindInteger: "+ vBindInteger, 1);
      
    vBindInteger = addAdvancedSearchTransDateFromAndToClause
      ((Date)vTransDateTo, (Date)vTransDateFrom, addWhereClause, vBindInteger);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() 11 vBindInteger: "+ vBindInteger, 1);
      
    vBindInteger = addAdvancedSearchDueDateFromAndToClause
      ((Date)vDueDateFrom, (Date)vDueDateTo, addWhereClause, vBindInteger);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() 12 vBindInteger: "+ vBindInteger, 1);

    // Bug # 3867838 - hikumar
    if("OIR_AGING_DISPUTE_ONLY".equals(vAcctStatus) || "OIR_AGING_PENDADJ_ONLY".equals(vAcctStatus)
                || "OIR_AGING_DISPUTE_PENDADJ".equals(vAcctStatus) )
      {
        if("OIR_AGING_DISPUTE_ONLY".equals(vAcctStatus))
          addWhereClause.append("AMOUNT_IN_DISPUTE <>0 AND");
        else if("OIR_AGING_PENDADJ_ONLY".equals(vAcctStatus))
          addWhereClause.append("AMOUNT_ADJUSTED_PENDING <>0 AND");
        else if("OIR_AGING_DISPUTE_PENDADJ".equals(vAcctStatus))
          addWhereClause.append("( AMOUNT_IN_DISPUTE <>0 OR AMOUNT_ADJUSTED_PENDING <>0 ) AND ");

        vAcctStatus = "OPEN"; // set the status as OPEN to be used in query clause
      }
    
     if(status != null && !"".equals(status))
     {
       if(!"PENDING".equals(status))
               addWhereClause.append("PAYMENT_APPROVAL = '"+status+"' AND ");
       else
         addWhereClause.append("(PAYMENT_APPROVAL = 'PENDING' OR PAYMENT_APPROVAL IS NULL) AND CLASS1 NOT IN ('PMT') AND ");
         //The above clause picks up all the transactions whoose status hasn't
         //been set.But this should not contain payments. Hence the 'NOT IN'
     }
    
    initQueryHelper( vCurrCode, vCustId,
                     vCustSiteUseId, vAcctStatus,
                     vAcctType, vKeyword,
                     addWhereClause, vBindInteger, relCustId, relCustSiteId);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() 13 vBindInteger: "+ vBindInteger, 1);

    //--vBindInteger;
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() 13.1 vBindInteger: "+ vBindInteger, 1);

    vBindInteger = addAdvancedSearchDueDateFromAndToParams
      ((Date)vDueDateFrom, (Date)vDueDateTo, addWhereClause, vBindInteger);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() 15 vBindInteger: "+ vBindInteger, 1);
      
    vBindInteger = addAdvancedSearchTransDateFromAndToParams
      ((Date)vTransDateTo, (Date)vTransDateFrom, addWhereClause, vBindInteger);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() 16 vBindInteger: "+ vBindInteger, 1);
      
    vBindInteger = addAdvancedSearchAmountFromAndToParams
      (vAmountFrom, vAmountTo, addWhereClause, vCurrCode, vBindInteger);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() 17 vBindInteger: "+ vBindInteger, 1);

    vBindInteger = addExtraQueryParams(vQuery, vParams, vBindInteger);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() 18 vBindInteger: "+ vBindInteger, 1);
    
	  //Start -R12 ugrade
        // Added for CR619
        if (bAddConsBillFilter)
            setWhereClauseParam(--vBindInteger, sXXConsBill);
        this.writeDiagnostics(this, "TableVO.advancedInitQuery() 19 vBindInteger: "+ vBindInteger, 1);

        if (sXXPurchaseOrder != null && sXXPurchaseOrder.length() > 0) {
            setWhereClauseParam(--vBindInteger, sXXPurchaseOrder);
        }
        this.writeDiagnostics(this, "TableVO.advancedInitQuery() 20 vBindInteger: "+ vBindInteger, 1);

        if (containsSoftColumns()) {
            if (sXXRelease != null && sXXRelease.length() > 0)
                setWhereClauseParam(--vBindInteger, sXXRelease);
            if (sXXDesktop != null && sXXDesktop.length() > 0)
                setWhereClauseParam(--vBindInteger, sXXDesktop);
            if (sXXDept != null && sXXDept.length() > 0)
                setWhereClauseParam(--vBindInteger, sXXDept);
        }
        this.writeDiagnostics(this, "TableVO.advancedInitQuery() 21 vBindInteger: "+ vBindInteger, 1);

        if (containsBindVariablesForShipTo())
            setWhereClauseParam(--vBindInteger, sXXShipToIDValue);
        this.writeDiagnostics(this, "TableVO.advancedInitQuery() 22 vBindInteger: "+ vBindInteger, 1);

        //End -R12 ugrade

    
    // Set the Session Id parameter
    String sessionId = trx.getSessionId()+"";
    setWhereClauseParam (--vBindInteger, sessionId);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() 23 b vBindInteger: "+ vBindInteger, 1);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() 23 a sessionId: "+ sessionId, 1);
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() 23 vBindInteger: "+ vBindInteger, 1);


    // bugfix 1796817 : sjamall 06/14/2001
    if (containsBindVariablesForMonthsLimit())
    {
      if ( ("false".equals(vRestrict)) ||
           (!isNullString(vAmountFrom)) || (!isNullString(vAmountTo)) ||
           ( null != vTransDateFrom ) || ( null != vTransDateTo ) ||
           ( null != vDueDateFrom ) || ( null != vDueDateTo ) )
      {
        setWhereClauseParam(--vBindInteger, "");
        setWhereClauseParam(--vBindInteger, "");
      }
      else
      {
      // setWhereClauseParam(--vBindInteger, getSimpleSearchDateLimit(vCustId, vCustSiteUseId));
      //  setWhereClauseParam(--vBindInteger, getSimpleSearchDateLimit(vCustId, vCustSiteUseId));
      }
    }
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() 24 vBindInteger: "+ vBindInteger, 1);

    if("Y".equals(paymentVO))
    {
      setWhereClauseParam(--vBindInteger, personPartyId);
      setWhereClauseParam(--vBindInteger, isInternalUser);
    }
    this.writeDiagnostics(this, "TableVO.advancedInitQuery() 25 vBindInteger: "+ vBindInteger, 1);

    executeQuery(vCurrCode);
    */
  }

  //Start - R12 upgrade

 // For E1327 and E2052 (overridden in subclasses):

 protected boolean containsBindVariablesForShipTo() {
     return false;
 }

 protected boolean containsConsolidatedBillColumn() {
     return false;
 }

 protected boolean containsSoftColumns() {
     return false;
 }


//End - R12 upgrade

  protected void executeQuery(String vCurrCode)
  {    
    this.writeDiagnostics(this, "TableVO.executeQuery() sql: "+ this.getQuery(), 1);
    
    Object[] strParams = this.getWhereClauseParams();
    
    this.writeDiagnostics(this, "TableVO.executeQuery() number of Params: " + strParams.length, 1);
    this.writeDiagnostics(this, "TableVO.executeQuery() getWhereClause(): " + this.getWhereClause(), 1);
    this.writeDiagnostics(this, "TableVO.executeQuery() getWhereClause(): " + this.getWhereClauseParams(), 1);
    for (int i=0; i< strParams.length; i++)
      this.writeDiagnostics(this, "TableVO.executeQuery() getWhereClause(" + i + "): " + strParams[i], 1);
    
    executeQuery();
  }

  protected void executeQuery(    String vCurrCode, String vCustId, String vCustSiteUseId,
	  String relCustId, String relCustSiteId,
    String vAcctStatus, String vAcctType,
    String vRestrict, String vQuery, String vParams, String vKeyword,
    String vOrderNumber, String vOrderType, String vLineId,
    String vAmountFrom, String vAmountTo, String isInternalUser, String personPartyId,
    String paymentVO, String status,String sXXShipToIDValue,String sXXTransactions, String sXXConsBill,
    String sXXPurchaseOrder, String sXXDept,String sXXDesktop, String sXXRelease, Date vTransDateFrom, Date vTransDateTo, 
    Date vDueDateFrom, Date vDueDateTo, String sessionId, String strUserId, String strOrgId
  )
  {    
    this.writeDiagnostics(this, "TableVO.executeQuery() extended sql: "+ this.getQuery(), 1);
    String trx_status = statusForWhereClause(vAcctStatus);
    if ("".equals(trx_status.trim()))
        trx_status = null;

    setWhereClause(null);
	
    String trxNoSrchQry = " trx_number IN (SELECT decode(transaction, 'NONE',trx_number, transaction) FROM XX_ARI_TRX_SEARCH_GT) ";
    
    if(sXXTransactions != null && !"".equals(sXXTransactions.trim())) 
    {
	    this.writeDiagnostics(this, "sXXTransactions value is NOT NULL", 1);
		this.setWhereClause(trxNoSrchQry);   
    }
	
	setTrxNumberKeyWord( sXXTransactions);
	// setWhereClause(null);  ver - 5.2 for param 9 as sXXConsBill
    setWhereClauseParam(0,  sessionId);
    setWhereClauseParam(1,  strUserId);
    setWhereClauseParam(2,  vCurrCode);
    setWhereClauseParam(3,  vAcctStatus);
    setWhereClauseParam(4,  vAcctStatus);
    setWhereClauseParam(5, sXXDept);
    setWhereClauseParam(6, sXXDesktop);
    setWhereClauseParam(7, sXXRelease);
    setWhereClauseParam(8, sXXPurchaseOrder);
    setWhereClauseParam(9, sXXConsBill);
    setWhereClauseParam(10, vAmountFrom);
    setWhereClauseParam(11, vAmountTo);
    setWhereClauseParam(12, vTransDateFrom);
    setWhereClauseParam(13, vTransDateTo);
    setWhereClauseParam(14, vDueDateFrom);
    setWhereClauseParam(15, vDueDateTo);

    //setMaxFetchSize(10000);
    Object[] strParams = this.getWhereClauseParams();
    
    this.writeDiagnostics(this, "TableVO.executeQuery() number of Params: " + strParams.length, 1);
    this.writeDiagnostics(this, "TableVO.executeQuery() getWhereClause(): " + this.getWhereClause(), 1);
    this.writeDiagnostics(this, "TableVO.executeQuery() getWhereClause(): " + this.getWhereClauseParams(), 1);
    for (int i=0; i< strParams.length; i++)
      this.writeDiagnostics(this, "TableVO.executeQuery() getWhereClause(" + i + "): " + strParams[i], 1);

    executeQuery();
  }
  
  
  protected int addAdvancedSearchAmountFromAndToClause
      (String vAmountFrom, String vAmountTo, StringBuffer addWhereClause, String vCurrCode, int vBindInteger)
  { throw new OAException("please contact development about this message:oracle.apps.ar.irec.accountDetails.TableVO.java"); }
  protected int addAdvancedSearchAmountFromAndToParams
      (String vAmountFrom, String vAmountTo, StringBuffer addWhereClause, String vCurrCode, int vBindInteger)
  { throw new OAException("please contact development about this message:oracle.apps.ar.irec.accountDetails.TableVO.java"); }

  protected int addAdvancedSearchTransDateFromAndToClause
      (Date vTransDateTo, Date vTransDateFrom, StringBuffer addWhereClause, int vBindInteger)
  { throw new OAException("please contact development about this message:oracle.apps.ar.irec.accountDetails.TableVO.java"); }
  protected int addAdvancedSearchTransDateFromAndToParams
      (Date vTransDateTo, Date vTransDateFrom, StringBuffer addWhereClause, int vBindInteger)
  { throw new OAException("please contact development about this message:oracle.apps.ar.irec.accountDetails.TableVO.java"); }

  protected int addAdvancedSearchDueDateFromAndToClause
      (Date vDueDateFrom, Date vDueDateTo, StringBuffer addWhereClause, int vBindInteger)
  { throw new OAException("please contact development about this message:oracle.apps.ar.irec.accountDetails.TableVO.java"); }
  protected int addAdvancedSearchDueDateFromAndToParams
      (Date vDueDateFrom, Date vDueDateTo, StringBuffer addWhereClause, int vBindInteger)
  { throw new OAException("please contact development about this message:oracle.apps.ar.irec.accountDetails.TableVO.java"); }


  public void initQuery( String vCurrCode, String vCustId,
                         String vCustSiteUseId, String vAcctStatus,
                         String vAcctType, String vKeyword,
                         String vOrderNumber, String vOrderType,
                         String vLineId)
  {
    initQuery( vCurrCode, vCustId, vCustSiteUseId, vAcctStatus,
               vAcctType, vKeyword);
  }

  public void initQuery( String vCurrCode, String vCustId,
                         String vCustSiteUseId, String vAcctStatus,
                         String vAcctType, String vKeyword)
  {
    StringBuffer addWhereClause = new StringBuffer("");
    setWhereClauseParams(null);
    setWhereClause(null);
    initQueryHelper( vCurrCode, vCustId,
                     vCustSiteUseId, vAcctStatus,
                     vAcctType, vKeyword,
                     addWhereClause, 1, null, null);

    executeQuery(vCurrCode);
  }

  protected String getOrderBindVariable(String value)
  { return (""); }

  protected int initQueryHelper( String vCurrCode, String vCustId,
                               String vCustSiteUseId, String vAcctStatus,
                               String vAcctType, String vKeyword,
                               StringBuffer addWhereClause, int vBindInteger, String  relCustId, String relCustSiteId)
  {
  
    
    // ( customer_id = :1 )
     OAApplicationModuleImpl am = (OAApplicationModuleImpl)getApplicationModule();
     OADBTransactionImpl trx = (OADBTransactionImpl)am.getOADBTransaction();
     

       if(vCustId !=null && !"-1".equals(vCustId))  
       {
         if("CONSBILLNUMBERBAL".equals(vAcctType) ) {
           addWhereClause.append ( "( ArPaymentSchedulesV.customer_id = :" + vBindInteger++ + " )");
           // where ArPaymentSchedulesV is used as alias name 
           // for AR_PAYMENT_SCHEDULES in ConsInvTableVO and ConsInvAccountBalanceVO 
           
         } else 
         { 
           addWhereClause.append ( "( customer_id = :" + vBindInteger++ + " )");
           this.writeDiagnostics(this, "TableVO.initQueryHelper() 1 vBindInteger: "+ vBindInteger, 1);           
         }
       }
/*
        //Start - Commented on 16Dec2014
   else
	  {
		  //Bug 5858028 - When Customer Id is not set, then we are in context of Multiple Customer Accounts
		  //So, we need to set the customer id and customer site use id appended dynamically
		  //for the sites that the user(current session) has access to       
		  String queryString = "SELECT CUSTOMER_ID, CUSTOMER_SITE_USE_ID FROM AR_IREC_USER_ACCT_SITES_ALL WHERE SESSION_ID = "+trx.getSessionId();
		  HashMap customerList = new HashMap();
		  String sCustomerId = "";
		  String sCustomerSiteUseId = "";
		  
		  ViewObject currentContextVO = null;
		  Row row = null ;
		  currentContextVO = (ViewObject) am.createViewObjectFromQueryStmt(null , queryString );
		  currentContextVO.executeQuery();
		  currentContextVO.reset();
		  //counter for counting the number of sites
		  int custsitecount = 0;
		  int tempcount = 0;
		  ArrayList custSiteList = new ArrayList();
		  //Customer can be repeated in the above query, so putting them in a Hashmap as the key avoid duplicates
		  while(currentContextVO.hasNext())
		  {
			row = currentContextVO.next();
			customerList.put((String)row.getAttribute(0).toString(), (String)row.getAttribute(0).toString()) ;
			sCustomerSiteUseId += row.getAttribute(1).toString()+", ";
			custsitecount++;
			tempcount++;
			if(tempcount>=990)   
			  {
          custSiteList.add(sCustomerSiteUseId);
          sCustomerSiteUseId = "";
          tempcount = 0;
			  }
		  }
		  if(custsitecount < 990)
		  {
        sCustomerSiteUseId = sCustomerSiteUseId.substring(0, sCustomerSiteUseId.length()-2); 
		  }
      else
      { //to add the last cust site uses which were not added in earlier loop
        custSiteList.add(sCustomerSiteUseId);
      }
		  currentContextVO.remove(); 
		  Iterator custIter = customerList.keySet().iterator();
		  while(custIter.hasNext())
		  {
        sCustomerId += (String)custIter.next()+", ";
		  }
		  sCustomerId = sCustomerId.substring(0, sCustomerId.length()-2);

		  if(sCustomerId !=null && sCustomerSiteUseId!=null && !"".equals(sCustomerId) && !"".equals(sCustomerSiteUseId)) 
        if(custsitecount <990) {
          if("CONSBILLNUMBERBAL".equals(vAcctType) ) {
            addWhereClause.append ( "(ArPaymentSchedulesV.customer_id in (" + sCustomerId + ")) and (ArPaymentSchedulesV.customer_site_use_id in ("+ sCustomerSiteUseId +")) and ");
          } else addWhereClause.append ( "(customer_id in (" + sCustomerId + ")) and (customer_site_use_id in ("+ sCustomerSiteUseId +")) and ");
        }
        else
        {
          if("CONSBILLNUMBERBAL".equals(vAcctType) ) {
            addWhereClause.append ( "(ArPaymentSchedulesV.customer_id in (" + sCustomerId + ")) and  ");
          } else addWhereClause.append ( "(customer_id in (" + sCustomerId + ")) and  ");
          Iterator custSiteIter = custSiteList.iterator();
            if(custSiteIter.hasNext())
              addWhereClause.append ( " ( ");
          while(custSiteIter.hasNext())
           {
          sCustomerSiteUseId = (String)custSiteIter.next();
          sCustomerSiteUseId = sCustomerSiteUseId.substring(0, sCustomerSiteUseId.length()-2); 
          addWhereClause.append ( " customer_site_use_id in ("+ sCustomerSiteUseId +") ");					
            if(custSiteIter.hasNext())
              addWhereClause.append ( " or ");
            else
              addWhereClause.append ( " ) and ");
           }				
			   
        }
	     }
		 //End - Commented on 16Dec2014
        */ 
     
    if(relCustId!=null)
      {
      addWhereClause.append(  " AND ((( :" 
                           + vBindInteger++ 
                           +" IS NULL OR :" 
                           + vBindInteger++ 
                           + " = customer_site_use_id )) OR"
                           + "((paying_customer_id= :"+vBindInteger++ +") and ( :"+vBindInteger++ +" = paying_site_use_id ))) ");
      this.writeDiagnostics(this, "TableVO.initQueryHelper() 2 1+1 vBindInteger: "+ vBindInteger, 1);           
    }
    else 	if(vCustSiteUseId !=null && !"".equals(vCustSiteUseId) && !"-1".equals(vCustSiteUseId))
    {
	 
		  // <bugfix 2445929>
			// AND ( :4 IS NULL OR :5 = customer_site_use_id )
			if(vCustId !=null && !"-1".equals(vCustId))
			addWhereClause.append(  " AND ( :" 
							  + vBindInteger++ 
							  +" IS NULL OR :" 
							  + vBindInteger++ 
							  + " = customer_site_use_id )");
      this.writeDiagnostics(this, "TableVO.initQueryHelper() 3 1+1 vBindInteger: "+ vBindInteger, 1);           
    }
	/*
	  //Start - Commented on 16Dec2014
 	else
  {
    if(vCustId !=null && !"-1".equals(vCustId) && !"".equals(vCustId))
    {
      String queryString = "SELECT CUSTOMER_SITE_USE_ID FROM AR_IREC_USER_ACCT_SITES_ALL WHERE SESSION_ID = "+trx.getSessionId() +" AND CUSTOMER_ID = "+vCustId;
      String sCustomerSiteUseId = "";
      ViewObject currentSiteContextVO = null;
      Row row = null ;
      currentSiteContextVO = (ViewObject) am.createViewObjectFromQueryStmt(null , queryString );
      currentSiteContextVO.executeQuery();
      currentSiteContextVO.reset();
      //counter for counting the number of sites
      int custsitecount = 0;
      int tempcount = 0;
      ArrayList custSiteList = new ArrayList();
      while(currentSiteContextVO.hasNext())
      {
        row = currentSiteContextVO.next();
        sCustomerSiteUseId += row.getAttribute(0).toString()+", ";
        custsitecount++;
        tempcount++;
        if(tempcount>=990)
        {
          custSiteList.add(sCustomerSiteUseId);
          sCustomerSiteUseId = "";
          tempcount = 0;
        }
      }
      if(custsitecount < 990)
      {
        if(sCustomerSiteUseId.length() >=2)
          sCustomerSiteUseId = sCustomerSiteUseId.substring(0, sCustomerSiteUseId.length()-2); 
      }
      else
      { //to add the last cust site uses which were not added in earlier loop
        custSiteList.add(sCustomerSiteUseId);
      }
      currentSiteContextVO.remove(); 

      if(sCustomerSiteUseId!=null && !"".equals(sCustomerSiteUseId))
      {
        addWhereClause.append ( " and ");
        if(custsitecount<990)
          addWhereClause.append ( " (customer_site_use_id in ("+ sCustomerSiteUseId +")) ");
        else
       {
        Iterator custSiteIter = custSiteList.iterator();
        if(custSiteIter.hasNext())
          addWhereClause.append ( " ( ");
        while(custSiteIter.hasNext())
         {
          sCustomerSiteUseId = (String)custSiteIter.next();
          sCustomerSiteUseId = sCustomerSiteUseId.substring(0, sCustomerSiteUseId.length()-2); 
          addWhereClause.append ( " customer_site_use_id in ("+ sCustomerSiteUseId +") ");
          if(custSiteIter.hasNext())
            addWhereClause.append (" or ");
          else
           addWhereClause.append ( " ) ");
         }	
					
       }
      }
    }
  }
  //End - Commented on 16Dec2014
        */
    // </bugfix 2445929>

    // AND ( invoice_currency_code = :3 )
     if((vCustId !=null && !"-1".equals(vCustId)) || (vCustSiteUseId !=null && !"".equals(vCustSiteUseId) && !"-1".equals(vCustSiteUseId)))
       addWhereClause.append(  " AND ");

    // Bug # 9312037
    if("FILTER_ACCT_BALANCE".equals(vAcctType) ) 
        addWhereClause.append ( " ( ArPaymentSchedules.invoice_currency_code = :" + vBindInteger++ + " )");
    else if("CONSBILLNUMBERBAL".equals(vAcctType)) //bug 9595986
        addWhereClause.append ( " ( ArPaymentSchedulesV.invoice_currency_code = :" + vBindInteger++ + " )");
    else
        addWhereClause.append ( " ( invoice_currency_code = :" + vBindInteger++ + " )");
    this.writeDiagnostics(this, "TableVO.initQueryHelper() 3 vBindInteger: "+ vBindInteger, 1);           
    vBindInteger = initQuerySpecialized(vAcctStatus, vAcctType, addWhereClause,
                                        vKeyword, vCurrCode, vBindInteger);

    this.writeDiagnostics(this, "TableVO.initQueryHelper() 4 - after initQuerySpecialized vBindInteger: "+ vBindInteger, 1);           

    setWhereClauseParam (--vBindInteger, vCurrCode);
    this.writeDiagnostics(this, "TableVO.initQueryHelper() 5 - after setWhereClauseParam(x,vCurrCode) vBindInteger: "+ vBindInteger, 1);           
    
	if(relCustId!=null)
    {
      setWhereClauseParam (--vBindInteger, relCustSiteId);
      this.writeDiagnostics(this, "TableVO.initQueryHelper() 6 - after setWhereClauseParam(x,relCustSiteId) vBindInteger: "+ vBindInteger, 1);           
      setWhereClauseParam (--vBindInteger, relCustId);
      this.writeDiagnostics(this, "TableVO.initQueryHelper() 7 - after setWhereClauseParam(x,relCustId) vBindInteger: "+ vBindInteger, 1);           
      setWhereClauseParam (--vBindInteger, vCustSiteUseId);
      this.writeDiagnostics(this, "TableVO.initQueryHelper() 8 - after setWhereClauseParam(x,vCustSiteUseId) vBindInteger: "+ vBindInteger, 1);           
      setWhereClauseParam (--vBindInteger, vCustSiteUseId);
      this.writeDiagnostics(this, "TableVO.initQueryHelper() 9 - after setWhereClauseParam(x,vCustSiteUseId) vBindInteger: "+ vBindInteger, 1);           
    }
    if(vCustSiteUseId !=null && !"".equals(vCustSiteUseId) && !"-1".equals(vCustSiteUseId))
    {
      setWhereClauseParam (--vBindInteger, vCustSiteUseId);
      this.writeDiagnostics(this, "TableVO.initQueryHelper() 10 - after setWhereClauseParam(x,vCustSiteUseId) vBindInteger: "+ vBindInteger, 1);           
      setWhereClauseParam (--vBindInteger, vCustSiteUseId);
      this.writeDiagnostics(this, "TableVO.initQueryHelper() 11 - after setWhereClauseParam(x,vCustSiteUseId) vBindInteger: "+ vBindInteger, 1);           
    }
    
    if(vCustId !=null && !"-1".equals(vCustId))
    setWhereClauseParam (--vBindInteger, vCustId);
    this.writeDiagnostics(this, "TableVO.initQueryHelper() 12 - after setWhereClauseParam(x,vCustId) vBindInteger: "+ vBindInteger, 1);           

    return (vBindInteger);

  }

  protected int initQuerySpecialized(String vAcctStatus, String vAcctType,
                                     StringBuffer addWhereClause, String vKeyword,
                                     String vCurrCode, int vBindInteger)
  {
    String status = null;
    
    status = statusForWhereClause(vAcctStatus);
    
    this.writeDiagnostics(this, "TableVO.initQuerySpecialized status: " + status, 1);    
    
    // AND ( status = nvl ( :6 , status ))
     if("CONSBILLNUMBERBAL".equals(vAcctType) ) {
       addWhereClause.append ( " AND ( ArPaymentSchedulesV.status = nvl ( :" + vBindInteger++
           + " , ArPaymentSchedulesV.status ))");  
       // where ArPaymentSchedulesV is used as alias name  for AR_PAYMENT_SCHEDULES in ConsInvAccountBalanceVO 
       
     }else 
     {
       if (status != null && !"".equals(status.trim()))
         addWhereClause.append ( " AND ( status = :" + vBindInteger++  + ")");
     }
    

    String class1, class2;


    addWhereClause.append(overdueInvoiceClause(vAcctStatus));
    addWhereClause.append(amountRemainingClause(vAcctStatus));

        vBindInteger = handleKeyword (addWhereClause, vKeyword, vCurrCode, vBindInteger);

    if (status != null && !"".equals(status.trim()))
      setWhereClauseParam (--vBindInteger, status);
  
    return (vBindInteger);
  }

  protected static final String mOverdueClause = " AND ( trunc(sysdate) > due_date ) ";

  protected static final String mWithinXdaysClause = "  sysdate < ( trx_date + :1 ) ";

  protected String getWithinXdaysClause()
  {
    return "  sysdate < ( trx_date + :1 ) ";
  }

/*  protected int getRowNumberLimit(String customerId, String customerSiteUseId)
  {
    return ((IROAApplicationModuleImpl)getApplicationModule()).getIntegerFromPackage(ARI_CONFIGURATION_PACKAGE, "Restrict_By_Rows", customerId, customerSiteUseId) + 1;
  }*/

/*  protected int getRowDaysLimit(String customerId, String customerSiteUseId)
  {
    return ((IROAApplicationModuleImpl)getApplicationModule()).getIntegerFromPackage(ARI_CONFIGURATION_PACKAGE, "Restrict_By_Days", customerId, customerSiteUseId) + 1;
  }*/

  protected String overdueInvoiceClause(String vAcctStatus)
  {
    String overdueClause = new String ("");
    if ( null != vAcctStatus )
    {
       if (vAcctStatus.equals("PAST_DUE_INVOICE"))
          {overdueClause = mOverdueClause; }
    }
    return overdueClause;
  }

  protected String amountRemainingClause(String vAcctStatus)
  {
    return ("");
  }

  /**
  * this creates the variable to bind to for the bind variable
  * equated to 'status' in the query statement
  */
  protected String statusForWhereClause(String vAcctStatus)
  {
    String status = new String ("");
    if (null != vAcctStatus)
    {
      if (vAcctStatus.equals("CLOSED"))
          {status = "CL";}
      else if (vAcctStatus.equals("OPEN"))
          {status = "OP";}
      else if (vAcctStatus.equals("PAST_DUE_INVOICE"))
          {status = "OP";}
    }
    return status;
  }


  protected int handleKeyword(StringBuffer addWhereClause, String vKeyword,
                              String vCurrCode, int vBindInteger)
  {
    if ((null != vKeyword) && (!("".equals(vKeyword))))
    {
        
      // bug # 11871930  - nkanchan
      StringTokenizer sTokens  = new StringTokenizer(vKeyword,",");
      if(sTokens.countTokens()<=1) sTokens = new StringTokenizer(vKeyword, "\n");
      if(sTokens.countTokens()>1) {
          Object vo = getViewObject();
          if ((null != vKeyword) && (!("".equals(vKeyword))) 
                && !(vo instanceof AccountBalanceVOImpl) && !(vo instanceof TotalRequestsVOImpl) 
                  && !(vo instanceof TotalPaymentsVOImpl) && !(vo instanceof TotalOpenInvoicesVOImpl) 
                  && !(vo instanceof TotalCMVOImpl) )
          {

              boolean closeKeywordClause = (addWhereClause.length() > 0);
              if (closeKeywordClause)
              {
                addWhereClause.append( " AND " );
              }

              String sTrxList = "";
             
              //counter for counting the number of transactions
              int trxlistcount = 0;
              int tempcount = 0;
              ArrayList keywordList = new ArrayList();

              while (sTokens.hasMoreTokens())
              {
                 sTrxList += "'"+sTokens.nextToken().trim()+"'"+ ",";
                 trxlistcount++;
                 tempcount++;
                 if(tempcount>=990)
                 {
                  keywordList.add(sTrxList);
                  sTrxList = "";
                  tempcount = 0;
                 }
              }
                  
              if(trxlistcount < 990)
              {
                sTrxList = sTrxList.substring(0, sTrxList.length()-1); 
              } 
              else
              { //to add the last trx numbers which were not added in earlier loop
                keywordList.add(sTrxList);
              }

              if(trxlistcount <990)
                  if (vo instanceof RequestTableVOImpl)
                    addWhereClause.append ( "to_char ( request_id ) in ("+ sTrxList +") ");   
                  else
                    addWhereClause.append ( "trx_number in ("+ sTrxList +") ");       
              else
              {

                Iterator keywordListIter = keywordList.iterator();
                  if(keywordListIter.hasNext())
                    addWhereClause.append ( " ( ");
                while(keywordListIter.hasNext())
                {
                  sTrxList = (String)keywordListIter.next();
                  sTrxList = sTrxList.substring(0, sTrxList.length()-1);
                  if (vo instanceof RequestTableVOImpl)
                    addWhereClause.append ( "to_char ( request_id ) in ("+ sTrxList +") ");   
                  else
                    addWhereClause.append ( "trx_number in ("+ sTrxList +") ");       
                  if(keywordListIter.hasNext())
                    addWhereClause.append ( " or ");
                  else
                    addWhereClause.append ( " )");
                 }
              }               
          }
          setWhereClause (addWhereClause.toString());
          return (--vBindInteger);
      } 
     else { // count is one
      vKeyword = vKeyword.replace('*', '%');
      return (handleKeywordUtility(addWhereClause, vKeyword, vCurrCode, vBindInteger));
     }
    }
    else
    {
      setWhereClause (addWhereClause.toString());
      return (--vBindInteger);
    }

  }
  
    

  protected int handleKeywordUtility(StringBuffer addWhereClause, String vKeyword,
                                     String vCurrCode, int vBindInteger)
  {
    int startBindingAt = vBindInteger;

    boolean closeKeywordClause = (addWhereClause.length() > 0);

    if (closeKeywordClause)
    {
      addWhereClause.append( " AND ( " );
    }
    addWhereClause.append(" trx_number LIKE :" + vBindInteger++);
    addWhereClause.append(" OR ct_purchase_order LIKE :" + vBindInteger++);

    oracle.jbo.domain.Date date;
    try
    {
      date = BusinessObjectsUtils.getDateFromString
              (vKeyword, (OAApplicationModule)getApplicationModule());
    }
    catch (Exception e)
    {
      date = null;
    }


    if (null != date)
    {
      addWhereClause.append(" OR trx_date = :" + vBindInteger++);
      addWhereClause.append(" OR due_date = :" + vBindInteger++);
    }

    oracle.jbo.domain.Number amount_due = getAmountFromString(vKeyword, vCurrCode);

    // maybe we should be converting to oracle.jbo.domain.Number before we move on.
    if (null != amount_due)
    {
      addWhereClause.append(" OR amount_due_original = :" + vBindInteger++);
      addWhereClause.append(" OR amount_due_remaining = :" + vBindInteger++);
    }

    // bugfix 1797441 : sjamall 29/05/2001
    addWhereClause.append
      (" OR ( EXISTS ( SELECT * FROM " +
      " (SELECT rctl.customer_trx_id AS customer_trx_id_rctl, rctl.sales_order AS sales_order_rctl FROM ra_customer_trx_lines rctl ) ");
    addWhereClause.append
      (" where customer_trx_id = customer_trx_id_rctl ");
    addWhereClause.append
      (" AND sales_order_rctl like :" + vBindInteger++ + " ) )");

    String toAppendToClause = closeKeywordClause ? " ) " : "";

    handleKeywordForExtraClauses(addWhereClause, vKeyword, toAppendToClause, vBindInteger);

    // start binding..
    vBindInteger = startBindingAt - 1;
    setWhereClauseParam(vBindInteger++, vKeyword); //binding trx_number
    setWhereClauseParam(vBindInteger++, vKeyword); //binding ct_purchase_order

    if (null != date)
    {
      setWhereClauseParam(vBindInteger++, date); //binding trx_date
      setWhereClauseParam(vBindInteger++, date); //binding due_date
    }

    if (null != amount_due)
    {
      setWhereClauseParam(vBindInteger++, amount_due); //binding amount_due_original
      setWhereClauseParam(vBindInteger++, amount_due); //binding amount_due_remaining
    }

    setWhereClauseParam(vBindInteger++, vKeyword); //binding sales_order
    return ( --startBindingAt );
  }

  protected int handleKeywordForExtraClauses(StringBuffer addWhereClause, String vKeyword, String vAppendToClause, int vBindInteger)
  {
    setWhereClause (addWhereClause.append(vAppendToClause).toString());
    return ( --vBindInteger );
  }

  /**
  * this method should be used for setting the where clause of the query.
  * instead of setWhereClause(String).
  */
  protected int setWhereClause(StringBuffer addWhereClause, String vKeyword, int vBindInteger)
  {
    setWhereClause (addWhereClause.toString());
    return (--vBindInteger);
  }

  // bugfix 1796817
/*  protected String getSimpleSearchDateLimit(String customerId, String customerSiteUseId)
  {
    OADBTransactionImpl trx = (OADBTransactionImpl)
      ((OAApplicationModuleImpl)getApplicationModule()).getOADBTransaction();
    Date limit = trx.getCurrentDBDate();
    int monthsLimit = ((IROAApplicationModuleImpl)getApplicationModule()).getIntegerFromPackage(ARI_CONFIGURATION_PACKAGE, "Search_Months_Limit", customerId, customerSiteUseId);
    return Integer.toString(-monthsLimit);
  }*/

  protected abstract boolean containsBindVariablesForMonthsLimit();

  //Bug 1927069 - Amount Formatting has been moved to AccountDetailsBaseCO,
  //which uses the APIs from OANLSServices.
  /*private String processAmountEntry(String amountStr, String currString) throws Exception
  {
    String retVal = null;
    if ((null != amountStr) && (!("".equals(amountStr.trim()))))
    {
      Number amount = null;
      try { amount = new Number(amountStr); }
      catch(Exception e) { amount = null; }
      if (null != amount)
        retVal = amountStr;
      else
      {
        OAApplicationModuleImpl am = (OAApplicationModuleImpl)getApplicationModule();
        OAApplicationModuleImpl amR = (am.isRoot() ? am : (OAApplicationModuleImpl)am.getRootApplicationModule());
        double amt;
        try {
          amt = CurrencyHelper.getNumericValue
            (((oracle.apps.fnd.framework.server.OADBTransactionImpl)amR.getOADBTransaction()).getAppsContext(),
            amountStr, currString);
          retVal = Double.toString(amt);
        }
        catch(Exception e) {throw e;}

      }
    }
    return retVal;
  }*/

  protected int addExtraQueryClause(StringBuffer addWhereClause, String vQuery,
                                    String vParams, int vBindInteger)
  {
    if(!(isNullString(vQuery)))
    {
      StringTokenizer st = new StringTokenizer (vQuery, "~~");
      boolean queryAdded = false;

      while (st.hasMoreTokens())
      {
        addWhereClause.append(" " + st.nextToken());
        queryAdded = true;
        if(st.hasMoreTokens())
          addWhereClause.append(" :" + vBindInteger++ );
      }

      if(queryAdded)
        addWhereClause.append(" AND ");
    }

    return vBindInteger;
  }

  protected int addExtraQueryParams(String vQuery, String vParams, int vBindInteger)
  {
    if (!(isNullString(vParams)))
    {
      Stack stack = new Stack();
      String tmp;
      StringTokenizer st = new StringTokenizer (vParams, "~~");
      // push elements onto stack and then pop stack to reverse order of parameters.
      while (st.hasMoreTokens())
      {
        tmp = st.nextToken();
        // Bugfix 2272203 : Check for "," and push null .
        if (null == tmp || ",".equals(tmp))
          tmp = "";
        stack.push(tmp);
      }

      while (!(stack.empty()))
      {
        tmp = (String)stack.pop();
        setWhereClauseParam(--vBindInteger, tmp);
      }
    }

    return vBindInteger;
  }
  public void setTrxNumberKeyWord( String sXXTransactions)
  {
       String trxNumberKeyWord = null;
       String sBucket;
       String sPurge = "Y";
       String sSuccess = "X";
       if (sXXTransactions == null || (sXXTransactions != null && "".equals(sXXTransactions.trim())))
           sXXTransactions = "NONE";
       String lsXXTransactions = 
           (sXXTransactions + '\n').replace((char)160, 
                                            (char)32).replace(",", 
                                                              " ").replace("  ", 
                                                                           " ").replace(" ", 
                                                                                        "\n").replace('\r', 
                                                                                                      '\n').replace("\n\n", 
                                                                                                                    "\n");
       
       int maxChars = 4000; // SQL limitation
       int maxBuckets = 
           18; // Arbitrary limitation, but may help agains DoS attack or trying huge amt of data
       // Assuming trx_numbers are typically 12 characters plus CRLF,
       // 18 * 4000 = 72,000; 72,000 / 14 = 5,142 trxs... should be plenty
       int lastPos = 0;
       int pos = lsXXTransactions.lastIndexOf('\n', maxChars);
       
       while (pos > lastPos && !sSuccess.equals("N") && 
              (maxBuckets-- > 0)) {
           sBucket = lsXXTransactions.substring(lastPos, pos + 1);
           if (sBucket.trim().length() > 0) {
       
               OADBTransaction txn = 
                   ((OAApplicationModuleImpl)getApplicationModule()).getOADBTransaction();
               OracleCallableStatement oraclecallablestatement = 
                   null;
               try {
                   sSuccess = "N";
                   oraclecallablestatement = 
                           (OracleCallableStatement)txn.createCallableStatement("CALL XX_IREC_SEARCH_PKG.INSERT_TRX_SEARCH(?,?,?)", 
                                                                                1);
                   oraclecallablestatement.setString(1, sBucket);
                   oraclecallablestatement.setString(2, sPurge);
                   oraclecallablestatement.registerOutParameter(3, 
                                                                Types.VARCHAR);
                   oraclecallablestatement.execute();
                   if (oraclecallablestatement != null) {
                       sSuccess = 
                               oraclecallablestatement.getString(3);
                       oraclecallablestatement.close();
                   }
               } catch (Exception ex) {
                   try {
                       if (oraclecallablestatement != null)
                           oraclecallablestatement.close();
                      } catch (Exception e) {
                          e.printStackTrace();
                      }
               }
               sPurge = "N";
           }
           lastPos = pos + 1;
           pos = 
           lsXXTransactions.lastIndexOf('\n', pos + maxChars);
       }       
   }
     
     
}

