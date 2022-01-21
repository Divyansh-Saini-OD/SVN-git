package oracle.apps.ar.irec.accountDetails.webui;

import com.sun.java.util.collections.HashMap;

import java.io.Serializable;

import java.lang.reflect.Field;

import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;

import oracle.apps.ar.irec.accountDetails.webui.AccountDetailsPageCO;
import oracle.apps.ar.irec.framework.webui.IROAControllerImpl;
import oracle.apps.fnd.common.CurrencyHelper;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAUrl;
import oracle.apps.fnd.framework.webui.beans.OASwitcherBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OASelectionButtonBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OARowLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageCheckBoxBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageDateFieldBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.table.OAAdvancedTableBean;
import oracle.apps.fnd.framework.webui.beans.table.OAColumnBean;
import oracle.apps.fnd.framework.webui.beans.table.OASortableHeaderBean;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.ar.irec.accountDetails.server.CustomTrxSearchTableVORowImpl;
import oracle.apps.ar.irec.homepage.server.DiscountAlertsVORowImpl;
import oracle.apps.xdo.oa.common.DocumentHelper;
import oracle.jbo.RowSetIterator;

import oracle.jbo.Row;
import oracle.jbo.ViewObject;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;

import oracle.jdbc.OracleCallableStatement;


/*----------------------------------------------------------------------------
 -- Author: Sridevi Kondoju
 -- Component Id: E1327 and E2052
 -- Script Location: $CUSTOM_JAVA_TOP/oracle/apps/ar/irec/accountDetails/webui
 -- Description: Considered R12 code version and added custom code.
 -- History:
 -- Name            Date         Version    Description
 -- -----           -----        -------    -----------
 -- Sridevi Kondoju 27-Jul-2013  1.0        Retrofitted for R12 Upgrade.
 -- Sridevi Kondoju 6-sep-2013   2.0        Removed extraspace
 -- Sridevi Kondoju 15-DEC-2013  3.0        Modified for Defect26258
 -- Sridevi Kondoju 6-Jun-2014   4.0        Modified for Defect30336
 -- Sridevi Kondoju 12-Jan-2015  4.0    Re-retrofitted considering
 --									  latest version from patch p19052386

---------------------------------------------------------------------------*/
/*===========================================================================+
 |      Copyright (c) 2001, 2014 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 |    08-May-03   albowicz     Created for Export Feature                    |
 |    20-May-03   albowicz     Added isBrowserBackButton function.           |
 |    11-June-03  hikumar      Bug # 1766614 - modified to logic of function |
 |                             isBrowserBackButton                           |
 |    17-June-03 hikumar      Bug fix 1927616 - In advance search if from    |
 |                            date exceeds to date , it should give error    |
 |    21-Oct-03  hikumar      Bug # 3186472 - Modified for URL security      |
 |    10-Feb-04    vnb       Bug # 3367661 - Check isLoggingEnabled before   |
 |                           calling writeDiagnostics                        |
 |    26-May-04   vnb        Bug # 3467287 - Method added to insert records  |
 |							 Transaction list                                |
 |    04-Jun-04   vnb        Bug # 1927069 - Amounts to be formatted based on|
 |							 the current preferences of the user             |
 |    01-Oct-04   vnb          Bug 3933606 - Multi-Print Enhancement         |
 |    23-Nov-04   vnb         Bug 4000209 - Multi Pay Error page no more used|
 |    02-Dec-04   vnb          Bug 4000064 - Different messages based on     |
 |                             submitted print requests                      |
 |    03-Jan-05   vnb        Bug 4071551 - Added a call to compute service   |
 |                           charge after inserting all selected records into|
 |                           transaction list                                |
 |    03-Feb-05   vnb        Bug 4103494 - Float values should not be used for|
 |                           comparisons                                      |
 |    15-Mar-05   rsinthre   Bug 4237309 - Apply Credits tab appears in       |
 |                           AccountDetails page when profile option is NO    |
 |    31-Mar-05  rsinthre    Bug # 4267180 - Multi printing errors out in     |
 |                           pseudo environment                               |
 |    24-May-05  vnb         Bug 4197060 - MOAC Uptake                       |
 |    26-May-05  rsinthre    Bug # 4392371 - OIR needs to support cross       |
 |                           customer payment                                 |
 |    01-Aug-05  rsinthre    Bug 4275821 - Multi Print Errors out: Increase   |
 |                           length of PROGRAM_NAME attribute                 |
 |  02-Aug-05  rsinthre   Bug # 4528713 - Obsolete 'OIR: Bill presentment     |
 |                        architecture enabled' profile option                |
 |  20-Sep-05  rsinthre   Bug # 4604121 - Unable to add payments to           |
 |                        transaction list in r12 sep drop                    |
 |  10-Nov-05  rsinthre   Bug 4495150 - Hide table buttons, when records are  |
 |                        added to Transaction List                           |
 |  28-May-07  mbolli     Bug#6074405 - Replacing where clause param 'class2' |
 |                          and 'CLASS2' to 'class'                           |
 |   12-Dec-07 avepati    Bug 6622674 - Java Code Changes For JDBC 11G On MT  |
 |   28-Feb-08 avepati    Bug 6748005 - ADS12.0.03 :FIN:NEED CONSOLIDATED     |
 |                             NUMBER FILTER ON ACCOUNT DETAILS PAGE          |
 |   10-Mar-08 avepati    Bug 6863009-GRAND TOTALS ARE NOT DISPLAYED ON FILTER|
 |                              BY CONS BILL NUM IN ACCT DTLS	                |
 |   14-Mar-08 avepati    Bug 6889365 - GETTING UNEXPECTED ERROR ON PAYING ACCOUNT PAGE |
 |   08-Jan-09 avepati    Bug 7681101 - TRANSACTION DETAILS ARE NOT COMING IN PAYING ACCOUNT PAGE |
 |   19-Jan-09 avepati    Bug 7721379 - NEED TO SHOW ONLY GROUPED CUSTOMERS IN|
 |                                            ACCT DETAILS CUSTOMER DROP DOWN |
 |   07-May-09 nkanchan Bug # 7678038 - IRECEIVABLES DOES NOT SHOW RECEIPTS WITH NO LOCATION
 |   11-Aug-09 avepati  Bug #8674041 - Unable to print invoices using AR print|
 |                                     program from iReceivables              |
 |   13-Aug-09 avepati   Bug 8790495-Add to Transaction List takes Control    |
 |                             back to page1                                  |
 |   25-Oct-09 avepati   Bug 9040332,	9068491-Consolidated Bill number search |
 |                             throws sqlexception in AccountDetails Page     |
 |   11-Dec-09 nkanchan  bug # 9174649 - when selecting from lov, able to     |
 |                          switch to account that does not belong to customer|
 |   22-Mar-2010 nkanchan  Bug # 8293098 - service charges based on credit    |
 |                              card type when making payments                |
 |   10-May-2010 avepati Bug 9694718 - Sql exception when navigating from     |
 |                                payment details page to account detail page |
 |   09-Jul-2010 avepati  Bug # 9882826 - Error when searching invoices with  |
 |                          status over 90 days  in account details page      |
 |   31-Aug-2010 avepati  Bug # 10061489 - Apply Credits button is always     |
 |                          with status closed                                |
 |   24-Nov-2010 avepati  Bug # 10302989 - Printing Invoice using AR printprog|
 |                          under 'All customer Accoounts' is erroring out    |
 |   31-Jan-11  avepati   Bug 7154650-Support Multiple Dispute feature        |
 |    18-Mar-11   nkanchan  Bug 11871875 - fp:9193514 :transaction            |
 |                           list disappears in ireceivables                  |
 |   06-Apr-11  avepati   Bug 11900858 - Unable to search transactions in Acct|
 |                            Details page using international character dates|
 |   09-May-11  avepati   Bug 12403921 - Dispute button not available if "PMT |
 |                             Approver" role is given                        |
 |   13-May-11  avepati   Bug 12353886 -Print Button should print the invoices|
 |                            using custom BPA templates                      |
 |   17-Jun-11  rsinthre  Bug 12650704 - BANK ACCOUNT DETAILS REMAIN IN NEW   |
 |                        TRANSACTION THOUGH PYMT CANCELL                     |
 |   01-Nov-11  melapaku  Bug 12687632 - ACCOUNT DETAILS SHOWS RELATED CUST   |
 |                         TRX IF YOU COME FROM PAYING ACC                    |
 |   21-Nov-11 parln      Bug 12677298 - CREDIT MEMO AND RECEIPTS NOT LIMITED |
 |                         BY 'FND: VIEW OBJECT MAX FETCH                     |
 |   25-Jan-12 parln      Bug# 13622850 Credit Memo Links through Null Pointer|
 |   13-Feb-12 parln      Bug#13602291 Able to dispute negative Debit Memos   |
 |                                     and ChargeBack
 |   27-Sep-12 shvimal    Bug 14530418 - OIR ACCOUNT SUMMARY PAGE: CREDIT MEMOS
 |                                       NOT INCLUDED IN THE AGING            |
 |   16-Nov-12 shvimal    BUG 14823754 - ER: ABILITY TO DOWNLOAD XML AND      |
 |                                       CUSTOMIZE EXPORT TEMPLATES           |
 |   08-Jul-13  shvimal   Bug 16355174 - IRECEIVABLES ISSUE: PAY BUTTON SPORADICALLY MISSING |
 |   11-Apr-14  rsurimen  Bug 18531298 - MISSING PRINT BUTTON WHEN VIEWING CREDIT MEMO SEARCH IN THE ACCOUNT DETAILS Sev 1 SR |
 |   18-Apr-14  shvimal   Bug 18610451 - FULL LIST OF ALL DISCOUNTS IS MISSING SELECT ALL BOX AND TOTALS OF DISCOUNT INV |
 |   18-Apr-14  rsurimen  Bug 18601726 - ER: ABILITY TO HIDE DISPUTE BUTTON BY PAGE ON ACCT DET AND TRX LIST |
 |   11-Mar-2015 ssiddams   Bug 20524609 - STALE DATA ERROR AFTER PRINTING/VIEWING INVOICE |
 +===========================================================================*/

/**
 * Controller for ...
 */
public class AccountDetailsBaseCO extends IROAControllerImpl {
    public static final String RCS_ID = "$Header: AccountDetailsBaseCO.java 120.79.12020000.8 2015/03/12 13:04:49 ssiddams ship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: AccountDetailsBaseCO.java 120.79.12020000.8 2015/03/12 13:04:49 ssiddams ship $", "oracle.apps.ar.irec.accountDetails.webui");
    /* Added for R12 upgrade retrofit */
    // locals added for CR619
    String msSoftHeaderDepartment;
    String msSoftHeaderPurchaseOrder;
    String msSoftHeaderRelease;
    String msSoftHeaderDesktop;


    /* Added for R12 upgrade retrofit */

    public void getSoftHeaders(OAPageContext oapagecontext,
                               OAWebBean oawebbean) {

        String sSoftHeadersCached = null;

        oapagecontext.writeDiagnostics(this,
                                       "XXOD: AccountDetailsBaseCO.getSoftHeaders - Begin",
                                       1);

        sSoftHeadersCached =
                (String)oapagecontext.getSessionValue("XX_SOFT_HEADERS_CACHED");
        if (sSoftHeadersCached != null &&
            sSoftHeadersCached.equals(getActiveCustomerId(oapagecontext))) {
            msSoftHeaderDepartment =
                    (String)oapagecontext.getSessionValue("XX_SOFT_HEADER_DEPT");
            msSoftHeaderPurchaseOrder =
                    (String)oapagecontext.getSessionValue("XX_SOFT_HEADER_PO");
            msSoftHeaderRelease =
                    (String)oapagecontext.getSessionValue("XX_SOFT_HEADER_RELEASE");
            msSoftHeaderDesktop =
                    (String)oapagecontext.getSessionValue("XX_SOFT_HEADER_DESKTOP");
        } else {
            OADBTransaction txn =
                ((OAApplicationModule)oapagecontext.getApplicationModule(oawebbean)).getOADBTransaction();
            OracleCallableStatement oraclecallablestatement = null;
            try {
                oraclecallablestatement =
                        (OracleCallableStatement)txn.createCallableStatement("CALL XX_IREC_SEARCH_PKG.GET_SOFT_HEADERS(?,?,?,?,?,?)",
                                                                             1);
                oraclecallablestatement.setString(1,
                                                  getActiveCustomerId(oapagecontext));
                oraclecallablestatement.registerOutParameter(2, Types.VARCHAR);
                oraclecallablestatement.registerOutParameter(3, Types.VARCHAR);
                oraclecallablestatement.registerOutParameter(4, Types.VARCHAR);
                oraclecallablestatement.registerOutParameter(5, Types.VARCHAR);
                oraclecallablestatement.registerOutParameter(6,
                                                             Types.VARCHAR); // when <>"Y", sSoftHeaderXXX will be blank so items will still be hidden
                oraclecallablestatement.execute();
                if (oraclecallablestatement != null) {
                    msSoftHeaderDepartment =
                            oraclecallablestatement.getString(2);
                    msSoftHeaderPurchaseOrder =
                            oraclecallablestatement.getString(3);
                    msSoftHeaderRelease = oraclecallablestatement.getString(4);
                    msSoftHeaderDesktop = oraclecallablestatement.getString(5);

                    oraclecallablestatement.close();
                }
            } catch (Exception ex) {
                try {
                    if (oraclecallablestatement != null)
                        oraclecallablestatement.close();
                } catch (Exception ex2) {
                }
                ;
            }
            oapagecontext.putSessionValue("XX_SOFT_HEADER_DEPT",
                                          (msSoftHeaderDepartment == null ?
                                           "" : msSoftHeaderDepartment));
            oapagecontext.putSessionValue("XX_SOFT_HEADER_PO",
                                          (msSoftHeaderPurchaseOrder == null ?
                                           "" : msSoftHeaderPurchaseOrder));
            oapagecontext.putSessionValue("XX_SOFT_HEADER_RELEASE",
                                          (msSoftHeaderRelease == null ? "" :
                                           msSoftHeaderRelease));
            oapagecontext.putSessionValue("XX_SOFT_HEADER_DESKTOP",
                                          (msSoftHeaderDesktop == null ? "" :
                                           msSoftHeaderDesktop));
            oapagecontext.putSessionValue("XX_SOFT_HEADERS_CACHED",
                                          getActiveCustomerId(oapagecontext));
        }
        oapagecontext.writeDiagnostics(this,
                                       "XXOD: AccountDetailsBaseCO.getSoftHeaders - End",
                                       1);
    }


    /* Added for R12 upgrade retrofit */
    // Bushrod added for CR619 to set (and possibly hide) Soft Header labels for table result columns:

    public void setColumnSoftHeaders(OAPageContext oapagecontext,
                                     OAWebBean oawebbean, String sPOHeaderName,
                                     String sPOColumn,
                                     String sSoftHeaderBeanPrefix) {
        oapagecontext.writeDiagnostics(this,
                                       "XXOD: AccountDetailsBaseCO.setColumnSoftHeaders - Begin",
                                       1);
        getSoftHeaders(oapagecontext, oawebbean);

        setColumnSoftHeader(oapagecontext, oawebbean, sPOHeaderName, sPOColumn,
                            msSoftHeaderPurchaseOrder);
        setColumnSoftHeader(oapagecontext, oawebbean,
                            sSoftHeaderBeanPrefix + "TrxReleaseColumnHeader",
                            sSoftHeaderBeanPrefix + "TrxReleaseColumn",
                            msSoftHeaderRelease);
        setColumnSoftHeader(oapagecontext, oawebbean,
                            sSoftHeaderBeanPrefix + "TrxDepartmentColumnHeader",
                            sSoftHeaderBeanPrefix + "TrxDepartmentColumn",
                            msSoftHeaderDepartment);
        setColumnSoftHeader(oapagecontext, oawebbean,
                            sSoftHeaderBeanPrefix + "TrxDesktopColumnHeader",
                            sSoftHeaderBeanPrefix + "TrxDesktopColumn",
                            msSoftHeaderDesktop);
        oapagecontext.writeDiagnostics(this,
                                       "XXOD: AccountDetailsBaseCO.setColumnSoftHeaders - End",
                                       1);
    }

    /* Added for R12 upgrade retrofit */

    public void setColumnSoftHeader(OAPageContext oapagecontext,
                                    OAWebBean oawebbean, String sHeaderName,
                                    String sColumnName, String sSoftLabel) {
        oapagecontext.writeDiagnostics(this,
                                       "XXOD: AccountDetailsBaseCO.setColumnSoftHeader - Begin",
                                       1);
        if (sSoftLabel != null && !sSoftLabel.equals("")) {
            OASortableHeaderBean header =
                (OASortableHeaderBean)oawebbean.findChildRecursive(sHeaderName);
            if (header != null)
                header.setText(sSoftLabel);
        } else {
            OAWebBean bean =
                oapagecontext.getPageLayoutBean().findChildRecursive(sColumnName);
            if (bean != null)
                bean.setRendered(false);
        }

        oapagecontext.writeDiagnostics(this,
                                       "XXOD: AccountDetailsBaseCO.setColumnSoftHeader - End",
                                       1);
    }


    /* Added for R12 upgrade retrofit */
    // Bushrod added for CR619 to set (and possibly hide) search region LOV labels:

    public void setLOVSoftHeaders(OAPageContext oapagecontext,
                                  OAWebBean oawebbean) {
        oapagecontext.writeDiagnostics(this,
                                       "XXOD: AccountDetailsBaseCO.setLOVSoftHeaders - Begin",
                                       1);
        getSoftHeaders(oapagecontext, oawebbean);

        setLOVSoftHeader(oawebbean, "XXPurchaseOrder",
                         msSoftHeaderPurchaseOrder);
        setLOVSoftHeader(oawebbean, "XXRelease", msSoftHeaderRelease);
        setLOVSoftHeader(oawebbean, "XXDept", msSoftHeaderDepartment);
        setLOVSoftHeader(oawebbean, "XXDesktop", msSoftHeaderDesktop);
        oapagecontext.writeDiagnostics(this,
                                       "XXOD: AccountDetailsBaseCO.setLOVSoftHeaders - End",
                                       1);
    }


    /* Added for R12 upgrade retrofit */

    public void setLOVSoftHeader(OAWebBean oawebbean, String sLOVname,
                                 String sPrompt) {

        OAMessageLovInputBean xxLovBean =
            (OAMessageLovInputBean)oawebbean.findChildRecursive(sLOVname);
        if (xxLovBean != null) {
            if (sPrompt != null && !sPrompt.equals(""))
                xxLovBean.setPrompt(sPrompt);
            else
                xxLovBean.setRendered(false);
        }
    }
    // End of addition for CR619 (see others below)
    /* End - R12 ugrade retrofit*/


    /**
     * Layout and page setup logic for AK region.
     * @param pageContext the current OA page context
     * @param webBean the web bean corresponding to the AK region
     */
    public void processRequest(OAPageContext pageContext, OAWebBean webBean) {

        if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
            pageContext.writeDiagnostics(this, "processRequest+",
                                         OAFwkConstants.PROCEDURE);

        /* Added for R12 ugrade retrofit */
        // This "if" added for CR619 to set (and possibly hide) LOV labels:
        pageContext.writeDiagnostics(this, "XXOD: processRequest - before if ",
                                     1);
        if (this.getClass().getName().endsWith("SearchRegionCO")) {

            pageContext.writeDiagnostics(this,
                                         "XXOD: processRequest - inside if ",
                                         1);
            setLOVSoftHeaders(pageContext, webBean);
        }
        /* End - Added for R12 ugrade retrofit */


        super.processRequest(pageContext, webBean);

        //Bug 3871284 - Transaction List GT to be cleared, if not already in this session
        if (pageContext.getSessionValue("TransactionListCleared") == null) {
            clearTransactionList(pageContext);
            pageContext.putSessionValue("TransactionListCleared", "Yes");
        }

        if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
            pageContext.writeDiagnostics(this, "processRequest-",
                                         OAFwkConstants.PROCEDURE);
    }

    /**
     * Procedure to handle form submissions for form elements in
     * AK region.
     * @param pageContext the current OA page context
     * @param webBean the web bean corresponding to the AK region
     */
    public void processFormRequest(OAPageContext pageContext,
                                   OAWebBean webBean) {
        super.processFormRequest(pageContext, webBean);
    }

    public String getSearchType(OAPageContext pageContext, OAWebBean webBean) {
        String trx_type =
            AccountDetailsPageCO.getParameter(pageContext, SearchHeaderCO.TRANSACTION_TYPE);
        if (trx_type == null || "".equals(trx_type))
            trx_type = "ALL_TRX";

        return trx_type;
    }

    public String getSearchStatus(OAPageContext pageContext,
                                  OAWebBean webBean) {
        String trx_status =
            AccountDetailsPageCO.getParameter(pageContext, SearchHeaderCO.TRANSACTION_STATUS);
        if (trx_status == null || "".equals(trx_status))
            trx_status = "OPEN";

        return trx_status;
    }

    protected void runAcctDetailsQuery(OAPageContext pageContext,
                                       OAWebBean webBean,
                                       String sViewObjectName) {
        if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
            pageContext.writeDiagnostics(this, "start runAcctDetailsQuery",
                                         OAFwkConstants.PROCEDURE);

        OAApplicationModule am = pageContext.getApplicationModule(webBean);

        String activeCurrencyCode;
        String activeCustomerId;
        String activeCustomerSiteUseId;
        String keyword =
            AccountDetailsPageCO.getParameter(pageContext, "Iracctdtlskeyword");
        String status =
            AccountDetailsPageCO.getParameter(pageContext, "IrApprovalStatus");

        if (null != keyword)
            keyword = keyword.trim();

        // Bug # 1927616  - hikumar
        String sAmountFrom =
            AccountDetailsPageCO.getParameter(pageContext, "Ariamountfrom");
        String sAmountTo =
            AccountDetailsPageCO.getParameter(pageContext, "Ariamountto");

        if (sAmountFrom != null && sAmountTo != null &&
            !sAmountFrom.equals("") && !sAmountTo.equals("")) {
            //Bug 1927069 - Convert amount into float based on current preferences for amt format
            //Bug 4103494 - Float values should not be used for comparisons
            try {
                Number nAmountFrom =
                    new Number(pageContext.getOANLSServices().stringToNumber(sAmountFrom));
                Number nAmountTo =
                    new Number(pageContext.getOANLSServices().stringToNumber(sAmountTo));
                if ((nAmountTo.subtract(nAmountFrom)).compareTo(0) < 0)
                    throw new OAException("AR", "ARI_ACCT_ADV_SEARCH_AMOUNT");

                //Convert the amounts back to strings to be able to pass as parameters to the query.
                sAmountFrom =
                        pageContext.getOANLSServices().NumberToString(nAmountFrom);
                sAmountTo =
                        pageContext.getOANLSServices().NumberToString(nAmountTo);
            } catch (SQLException e) {
                throw OAException.wrapperException(e);
            }

        }

        // Bug # 1927616  - hikumar

        activeCurrencyCode =
                getActiveCurrencyCode(pageContext, AccountDetailsPageCO.getParameter(pageContext,
                                                                                     CURRENCY_CODE_KEY));
        // Bug # 3186472 - hikumar
        // Modified to replace AccountDetailsPageCO.getParameter with AccountDetailsPageCO.getDecryptedParameter
        activeCustomerId = getActiveCustomerId(pageContext);
        activeCustomerSiteUseId = getActiveCustomerUseId(pageContext);

        int bucketStart = 0;
        int bucketEnd = 0;
        String trx_status =
            AccountDetailsPageCO.getParameter(pageContext, SearchHeaderCO.TRANSACTION_STATUS);
        String trx_type =
            AccountDetailsPageCO.getParameter(pageContext, SearchHeaderCO.TRANSACTION_TYPE);

        Date[] advancedDateSearchCriteria =
            getDateFromAccountSearchVO(pageContext, webBean);

        // Now if an Aging Status type is used, then modify the search paramters
        // to perform an Open Invoice Advanced Search with Due Dates search criteria set.
        if (trx_status != null && trx_status.startsWith("OIR_AGING_")) {
            int bucket_delim_location = trx_status.lastIndexOf("_");
            // Bug # 3867838 - hikumar
            if (!"OIR_AGING_DISPUTE_ONLY".equals(trx_status) &&
                !"OIR_AGING_PENDADJ_ONLY".equals(trx_status) &&
                !"OIR_AGING_DISPUTE_PENDADJ".equals(trx_status)) {
                bucketStart =
                        -Integer.parseInt(trx_status.substring(10, bucket_delim_location));
                bucketEnd =
                        -Integer.parseInt(trx_status.substring(bucket_delim_location +
                                                               1));
                // These functions will make sure that the advanced search criteria
                // still work with the bucket ranges.
                advancedDateSearchCriteria[2] =
                        adjustDueDateForAging(pageContext,
                                              advancedDateSearchCriteria[2],
                                              bucketEnd, true);
                advancedDateSearchCriteria[3] =
                        adjustDueDateForAging(pageContext,
                                              advancedDateSearchCriteria[3],
                                              bucketStart, false);
            }

            String[] sDates = { "null", "null", "null", "null" };
            if (advancedDateSearchCriteria[2] != null)
                sDates[2] = advancedDateSearchCriteria[2].stringValue();
            if (advancedDateSearchCriteria[3] != null)
                sDates[3] = advancedDateSearchCriteria[3].stringValue();

            if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
                pageContext.writeDiagnostics(this,
                                             "setupQuery:  Using Advanced Search to bring back all open invoices in the following bucket: " +
                                             "trx_status  = " + trx_status +
                                             ",  " + "bucketStart = " +
                                             String.valueOf(bucketStart) +
                                             ",  " + "bucketEnd   = " +
                                             String.valueOf(bucketEnd) +
                                             ",  " + "DueDateFrom = " +
                                             sDates[2] + ",  " +
                                             "DueDateTo   = " + sDates[3] +
                                             "  ", OAFwkConstants.STATEMENT);

            // Bug # 3867838 - hikumar
            if (!"OIR_AGING_DISPUTE_ONLY".equals(trx_status) &&
                !"OIR_AGING_PENDADJ_ONLY".equals(trx_status) &&
                !"OIR_AGING_DISPUTE_PENDADJ".equals(trx_status))
                trx_status = "OPEN";
            trx_type = "INVOICES";
        }

        String paymentVO = isPaymentVO() ? "Y" : "N";
        String isInternal =
            isInternalCustomer(pageContext, webBean) ? "Y" : "N";
        String personPartyId =
            (String)pageContext.getSessionValue("CUSTOMER_SEARCH_PERSON_ID");
        Long orgID =
            new Long(getActiveOrgId(pageContext)); //bug 	10058215 -avepati
        Long sessionID = new Long(pageContext.getSessionId());
        Long userID = new Long(pageContext.getUserId());

        String relCustomerValue =
            pageContext.getParameter("SearchRelCustomerValue");
        String relCustId = null;
        String relCustSiteId = null;
        if (relCustomerValue != null && !"".equals(relCustomerValue)) {
            //Bug # 4604121 - Set relatedCustomer Id as activeCustomerId and
            //set relatedCustSiteId only if activeCustomerSiteId is not null
            relCustId = activeCustomerId;
            if (activeCustomerSiteUseId != null) {
                relCustSiteId = activeCustomerSiteUseId;
            }
            activeCustomerId = relCustomerValue;
            activeCustomerSiteUseId = null;
            Long customerId = new Long(relCustomerValue);

            initialiseRelatedCustomerAcct(am, customerId, sessionID, userID,
                                          orgID, isInternal);
            //Bug#12687632 - Added the below line to requery whenever MyAccount Link is being clicked from PayingAccount Page
            pageContext.putSessionValue("Requery", "Y");
        } else {
            deleteRelCustPayAcctSites(pageContext, webBean);
        } // added for bug 7721379

        /*Added for R12 ugrade retrofit */
        // Bushrod added:
        String sXXShiptoIDValue = pageContext.getParameter("XXShipToIDValue");
        String sXXConsBill = pageContext.getParameter("XXConsBill");
        String sXXTransactions = pageContext.getParameter("XXTransactions");
        String sXXPurchaseOrder = pageContext.getParameter("XXPurchaseOrder");
        String sXXDept = pageContext.getParameter("XXDept");
        String sXXDesktop = pageContext.getParameter("XXDesktop");
        String sXXRelease = pageContext.getParameter("XXRelease");
        if (sXXConsBill != null)
            sXXConsBill = sXXConsBill.trim();
        if (sXXTransactions != null)
            sXXTransactions = sXXTransactions.trim();
        if (sXXPurchaseOrder != null)
            sXXPurchaseOrder = sXXPurchaseOrder.trim();
        if (sXXDept != null)
            sXXDept = sXXDept.trim();
        if (sXXDesktop != null)
            sXXDesktop = sXXDesktop.trim();
        if (sXXRelease != null)
            sXXRelease = sXXRelease.trim();


        pageContext.writeDiagnostics(this,
                              "XXOD: sXXShiptoIDValue " + sXXShiptoIDValue, 1);
        pageContext.writeDiagnostics(this, "XXOD: sXXConsBill " + sXXConsBill, 1);
        pageContext.writeDiagnostics(this, "XXOD: sXXTransactions " + sXXTransactions,
                              1);
        pageContext.writeDiagnostics(this,
                              "XXOD: sXXPurchaseOrder " + sXXPurchaseOrder, 1);
        pageContext.writeDiagnostics(this, "XXOD: sXXDept " + sXXDept, 1);
        pageContext.writeDiagnostics(this, "XXOD: sXXDesktop " + sXXDesktop, 1);
        pageContext.writeDiagnostics(this, "XXOD: sXXReleas " + sXXRelease, 1);
        /*End - Added for R12 ugrade retrofit */

        Serializable[] params =
        //Added for R12 upgrade retrofit// Inserted 1 line:
        //Bug 1927069 - The amounts are formatted before passing as parameters.
        { activeCurrencyCode, activeCustomerId, activeCustomerSiteUseId,
          relCustId, relCustSiteId, trx_status,
          AccountDetailsPageCO.getParameter(pageContext,
                                            SearchHeaderCO.TRANSACTION_TYPE),
          (String)getValueInSession(pageContext,
                                    SearchHeaderCO.RESTRICT_ACCT_DETAILS),
          pageContext.getParameter(SearchHeaderCO.ACCT_DETAILS_QUERY),
          pageContext.getParameter(SearchHeaderCO.ACCT_DETAILS_QUERY_PARAMS),
          keyword,
          AccountDetailsPageCO.getParameter(pageContext, "Irordernumber"),
          AccountDetailsPageCO.getParameter(pageContext, "Irordertype"),
          AccountDetailsPageCO.getParameter(pageContext, "Irlineid"),
          sAmountFrom, sAmountTo, isInternal, personPartyId, paymentVO, status,
          sXXShiptoIDValue, sXXTransactions, sXXConsBill, sXXPurchaseOrder,
          sXXDept, sXXDesktop, sXXRelease, advancedDateSearchCriteria[0],
          advancedDateSearchCriteria[1], advancedDateSearchCriteria[2],
          advancedDateSearchCriteria[3]};

        if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
            pageContext.writeDiagnostics(this,
                                         "calling invokeQueries() for advancedQueriesToInvoke() with " +
                                         "<activeCurrencyCode>=" +
                                         activeCurrencyCode +
                                         ", <activeCustomerId>=" +
                                         activeCustomerId +
                                         ", <activeCustomerSiteUseId>=" +
                                         activeCustomerSiteUseId +
                                         ", <Iraccountstatus>=" + params[5] +
                                         ", <trxType>=" + params[6] +
                                         ", <IrAcctDetailsRestrict>=" +
                                         params[7] + ", <keyword>=" + keyword +
                                         ", <Irordernumber>=" + params[9] +
                                         ", <Irordertype>=" + params[10] +
                                         ", <Irlineid>=" + params[11] +
                                         ", <Ariamountfrom>=" + params[12] +
                                         ", <Ariamountto>=" + params[13],
                                         OAFwkConstants.STATEMENT);

        Class[] paramsTypes = new Class[params.length];
        int i;
        for (i = 0; i < (paramsTypes.length - 4); i++)
            paramsTypes[i] = String.class;

        try {
            for (; i < paramsTypes.length; i++) {
                paramsTypes[i] = Class.forName("oracle.jbo.domain.Date");
            }
        } catch (java.lang.ClassNotFoundException e) {
            throw new OAException(e.toString());
        }


        OAViewObject vo =
            (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject(sViewObjectName);
        vo.invokeMethod("advancedInitQuery", params, paramsTypes);

        //Get the Count of Records retreived, to be displayed on Account Details Page
        
        String actualTrxType =
            AccountDetailsPageCO.getParameter(pageContext, SearchHeaderCO.TRANSACTION_TYPE);

        am.invokeMethod("resetSelectAllTrxFlag"); // reset the select all fetch trx flag every time query is executed
        Serializable[] fetCntParams = { sViewObjectName };
        Number nTotalFetCnt =
            (Number)am.invokeMethod("setFetchedTrxTotalAndReturnCount",
                                    fetCntParams);
        int fetchTotalCnt = 0;
        //if (nTotalFetCnt != null)
            //fetchTotalCnt = nTotalFetCnt.intValue();
            fetchTotalCnt = vo.getMaxFetchSize();
        int grandTotalCnt =
                setGrandTotals(pageContext, webBean, trx_type, trx_status,
                               activeCurrencyCode, vo, Long.toString(sessionID), Long.toString(userID), activeCustomerId, activeCustomerSiteUseId, Long.toString(orgID));
        if (grandTotalCnt != 0) {


            OAMessageCheckBoxBean selAllFetBean =
                (OAMessageCheckBoxBean)(pageContext.getPageLayoutBean().findIndexedChildRecursive("SelectAllFetchedTrx"));
            String promptTxt = (String)selAllFetBean.getText(pageContext);
            
            if (grandTotalCnt > fetchTotalCnt) {
                promptTxt = promptTxt + " " + fetchTotalCnt;
                am.invokeMethod("displayMoreRowsErrorMessage");
            } else {
                promptTxt = promptTxt + " " + grandTotalCnt;    
            }                
            
            selAllFetBean.setText(pageContext, promptTxt);
        } else { // if fetched transactions are zero , hide the grand totals regions and selectedTrx totals regions
            OAWebBean srchDtlsReg =
                (OAWebBean)pageContext.getPageLayoutBean().findChildRecursive("SearchDtlRN");
            OAWebBean selTrxTotReg =
                (OAWebBean)pageContext.getPageLayoutBean().findChildRecursive("SelectedTrxTotalsReg");
            srchDtlsReg.setRendered(false);
            selTrxTotReg.setRendered(false);
        }
      
        
        //Set the VO to first to display first set of records in results region
        if (vo != null)
            vo.first();

        if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
            pageContext.writeDiagnostics(this, "end runAcctDetailsQuery",
                                         OAFwkConstants.PROCEDURE);
    }

    /*
  private int setGrandTotals(OAPageContext pageContext, OAWebBean webBean, String trxType, String currencyCode, OAViewObject vo)
  {
    int     cnt             = 0;
    Number  totalCount      = null;
    Number  amtDueOriginal  = null;
    Number  amtDueRemaining = null;
    String  classType = null;
   // OAMessageLayoutBean grandTotalRegion = (OAMessageLayoutBean)pageContext.getPageLayoutBean().findChildRecursive("GrandTotalsRegionLayout");

    if(trxType == null || "ALL_TRX".equals(trxType) || "CONSBILLNUMBER".equals(trxType)  || "CREDIT_MEMOS".equals(trxType) || "DEBIT_MEMOS".equals(trxType) || "DEPOSITS".equals(trxType) || "INVOICES".equals(trxType) || "PAYMENTS".equals(trxType) || "CHARGEBACKS".equals(trxType) || "GUARANTEES".equals(trxType) || "ALL_DEBIT_TRX".equals(trxType))
    {
      if(trxType==null || "ALL_TRX".equals(trxType)  )
        classType = "AND ";
      else if("CREDIT_MEMOS".equals(trxType))
        classType = "AND CLASS = 'CM' AND ";
      else if("DEBIT_MEMOS".equals(trxType))
        classType = "AND CLASS = 'DM' AND ";
      else if("DEPOSITS".equals(trxType))
        classType = "AND CLASS = 'DEP' AND ";
      else if("INVOICES".equals(trxType) )
        classType = "AND CLASS = 'INV' AND ";
      else if("PAYMENTS".equals(trxType))
        classType = "AND CLASS = 'PMT' AND ";
      else if("CHARGEBACKS".equals(trxType))
        classType = "AND CLASS = 'CB' AND ";
      else if("GUARANTEES".equals(trxType))
        classType = "AND CLASS = 'GUAR' AND ";
      else if("ALL_DEBIT_TRX".equals(trxType))
        classType = "AND CLASS IN ('CB','INV', 'DM', 'DEP') AND ";
      else if("CONSBILLNUMBER".equals(trxType))
        classType = "AND ";
      {
        ViewObject totalsVO = null ;
        Row row = null ;
        String whereClause = vo.getWhereClause();
        String modifiedWhereClause = getModifiedWhereClause(whereClause,trxType);
        Object[] whereCluaseParams = vo.getWhereClauseParams();


         * bug 5003425 - vgundlap
         * The following 'if' block has been added as PaymentVO contains 2 initial parameters
         * that are not present in following query string which will result in error when
         * totalsVO.setWhereClauseParams(whereCluaseParams) is called.
         * Hence the initial 2 parameters are being skipped in the loop.

          // added CreditMemo to this if block for bug # 9174649

        if ("PAYMENTS".equals(trxType) || "CREDIT_MEMOS".equals(trxType))
        {
          int paramSize=whereCluaseParams.length;
          Object temp[]=new Object[paramSize-2];
          for(int count=2;count<paramSize;count++){
            temp[count-2]=whereCluaseParams[count];
          }
          whereCluaseParams=temp;
        }


        String queryString = "SELECT *+ leading(auasa) * count(*) COUNT, nvl( SUM ( amount_due_original ), 0) SUM_AMOUNT_DUE_ORIGINAL, nvl(SUM(amount_due_remaining ), 0) SUM_AMOUNT_DUE_REMAINING FROM AR_PAYMENT_SCHEDULES ArPaymentSchedulesV, ra_customer_trx ct, ar_irec_user_acct_sites_all auasa WHERE ( trunc( ArPaymentSchedulesV.TRX_DATE ) >= nvl2(  :1 , trunc ( add_months(SYSDATE, :2 ) ) , trunc ( ArPaymentSchedulesV.TRX_DATE ))) AND ArPaymentSchedulesV.customer_trx_id = ct.customer_trx_id AND ArPaymentSchedulesV.customer_id = auasa.customer_id AND ArPaymentSchedulesV.CUSTOMER_SITE_USE_ID = auasa.CUSTOMER_SITE_USE_ID AND auasa.USER_ID = FND_GLOBAL.USER_ID AND(TRUNC(arpaymentschedulesv.trx_date)) >= trunc(decode( nvl(FND_PROFILE.VALUE('ARI_FILTER_TRXDATE_OLDER'), 0), 0, arpaymentschedulesv.trx_date, (sysdate-FND_PROFILE.VALUE('ARI_FILTER_TRXDATE_OLDER'))))\n" +
        "AND (ct.printing_option =  decode(nvl(FND_PROFILE.VALUE('ARI_FILTER_DONOTPRINT_TRX'), 'NOT'), 'Y', 'PRI', ct.printing_option) OR ArPaymentSchedulesV.CLASS='PMT') AND auasa.session_id = :3 "+classType+modifiedWhereClause;

        if(trxType==null || "ALL_TRX".equals(trxType) || "PAYMENTS".equals(trxType))
          // added condition OR (auasa.CUSTOMER_SITE_USE_ID = -1 AND pmt.CUSTOMER_SITE_USE_ID IS NULL)) in queryString for bug # 7678038
          queryString = "SELECT *+ leading(auasa) * count(*) COUNT, nvl( SUM ( amount_due_original ), 0) SUM_AMOUNT_DUE_ORIGINAL, " +
          "nvl(SUM (decode(class,'PMT', ar_irec_payments.get_pymt_amnt_due_remaining(cash_receipt_id),amount_due_remaining )), 0)  SUM_AMOUNT_DUE_REMAINING " +
          "FROM AR_PAYMENT_SCHEDULES ArPaymentSchedulesV, ra_customer_trx ct,ar_irec_user_acct_sites_all auasa " +
          "WHERE ( trunc( ArPaymentSchedulesV.TRX_DATE ) >= nvl2(  :1 , trunc ( add_months(SYSDATE, :2 ) ) , trunc ( ArPaymentSchedulesV.TRX_DATE ))) " +
          "AND ArPaymentSchedulesV.customer_trx_id = ct.customer_trx_id(+) AND ArPaymentSchedulesV.customer_id = auasa.customer_id " +
          " AND (ArPaymentSchedulesV.CUSTOMER_SITE_USE_ID = auasa.CUSTOMER_SITE_USE_ID OR (auasa.CUSTOMER_SITE_USE_ID = -1 AND ArPaymentSchedulesV.CUSTOMER_SITE_USE_ID IS NULL)) AND auasa.USER_ID = FND_GLOBAL.USER_ID AND(TRUNC(arpaymentschedulesv.trx_date)) >= trunc(decode( nvl(FND_PROFILE.VALUE('ARI_FILTER_TRXDATE_OLDER'), 0), 0, arpaymentschedulesv.trx_date, (sysdate-FND_PROFILE.VALUE('ARI_FILTER_TRXDATE_OLDER'))))\n" +
          "AND (ct.printing_option =  decode(nvl(FND_PROFILE.VALUE('ARI_FILTER_DONOTPRINT_TRX'), 'NOT'), 'Y', 'PRI', ct.printing_option) OR ArPaymentSchedulesV.CLASS='PMT') AND auasa.session_id = :3 " + classType+modifiedWhereClause;
       if("CONSBILLNUMBER".equals(trxType))
         // added condition OR (auasa.CUSTOMER_SITE_USE_ID = -1 AND pmt.CUSTOMER_SITE_USE_ID IS NULL)) in queryString for bug # 7678038
         queryString = "SELECT *+ leading(auasa) * count(*) COUNT, nvl( SUM ( amount_due_original ), 0) SUM_AMOUNT_DUE_ORIGINAL, " +
         "nvl(SUM (decode(class,'PMT', ar_irec_payments.get_pymt_amnt_due_remaining(cash_receipt_id),amount_due_remaining )), 0)  SUM_AMOUNT_DUE_REMAINING " +
         "FROM AR_PAYMENT_SCHEDULES ArPaymentSchedulesV, ra_customer_trx ct , AR_CONS_INV_ALL ArCnsinv,ar_irec_user_acct_sites_all auasa " + // bug 9040332
         "WHERE ( trunc( ArPaymentSchedulesV.TRX_DATE ) >= nvl2(  :1 , trunc ( add_months(SYSDATE, :2 ) ) , trunc ( ArPaymentSchedulesV.TRX_DATE ))) " +
         "AND ArPaymentSchedulesV.customer_trx_id = ct.customer_trx_id(+) AND ArPaymentSchedulesV.cons_inv_id = ArCnsinv.cons_inv_id AND ArPaymentSchedulesV.customer_id = auasa.customer_id "+
         " AND (ArPaymentSchedulesV.CUSTOMER_SITE_USE_ID = auasa.CUSTOMER_SITE_USE_ID OR (auasa.CUSTOMER_SITE_USE_ID = -1 AND ArPaymentSchedulesV.CUSTOMER_SITE_USE_ID IS NULL)) AND auasa.USER_ID = FND_GLOBAL.USER_ID AND(TRUNC(arpaymentschedulesv.trx_date)) >= trunc(decode( nvl(FND_PROFILE.VALUE('ARI_FILTER_TRXDATE_OLDER'), 0), 0, arpaymentschedulesv.trx_date, (sysdate-FND_PROFILE.VALUE('ARI_FILTER_TRXDATE_OLDER'))))\n" +
         " AND (ct.printing_option =  decode(nvl(FND_PROFILE.VALUE('ARI_FILTER_DONOTPRINT_TRX'), 'NOT'), 'Y', 'PRI', ct.printing_option) OR ArPaymentSchedulesV.CLASS='PMT') AND auasa.session_id = :3 " + classType+modifiedWhereClause;


        totalsVO = (ViewObject) pageContext.getApplicationModule(webBean).createViewObjectFromQueryStmt(null , queryString );
        totalsVO.setWhereClauseParams(whereCluaseParams);
        totalsVO.executeQuery();
        if(totalsVO.hasNext())
        {
          row = totalsVO.next();
          totalCount = (Number)row.getAttribute(0);
          amtDueOriginal = (Number)row.getAttribute(1);
          amtDueRemaining = (Number)row.getAttribute(2);
          cnt = totalCount.intValue();
        }
        totalsVO.remove();
      }
      if(cnt>0 && currencyCode != null)
      {
        OAMessageStyledTextBean GrndTotalTrxNum = (OAMessageStyledTextBean)pageContext.getPageLayoutBean().findChildRecursive("NoOfTrx");
        OAMessageStyledTextBean gtOriginalAmtBean = (OAMessageStyledTextBean)pageContext.getPageLayoutBean().findChildRecursive("GTOriginalAmt");
        OAMessageStyledTextBean gtRemainingAmtBean = (OAMessageStyledTextBean)pageContext.getPageLayoutBean().findChildRecursive("GTRemainingAmt");

        String amtDueOriginalFormatted  = getFormattedAmount(pageContext, webBean, amtDueOriginal, currencyCode);
        String amtDueRemainingFormatted = getFormattedAmount(pageContext, webBean, amtDueRemaining, currencyCode);


        if(gtOriginalAmtBean!=null)
          gtOriginalAmtBean.setValue(pageContext, amtDueOriginalFormatted);
        if(gtRemainingAmtBean!=null)
          gtRemainingAmtBean.setValue(pageContext, amtDueRemainingFormatted);
        if(GrndTotalTrxNum!=null)
          GrndTotalTrxNum.setValue(pageContext, String.valueOf(cnt));
      }

    } // if(trxType == null || "ALL_TRX".equals(trxType) ||  "CREDIT_MEMOS".equals(trxType) || "DEBIT_MEMOS".equals(trxType) || "DEPOSITS".equals(trxType) || "INVOICES".equals(trxType) || "PAYMENTS".equals(trxType))
    return cnt;
  }
  */

    //Added for R12 upgrade retrofit

    private int setGrandTotals(OAPageContext oapagecontext,
                               OAWebBean oawebbean, String s, String trx_status, String s1,
                               OAViewObject oaviewobject, String strSessionId, 
                               String strUserId, String activeCustomerId, 
                               String activeCustomerSiteUseId, String strOrgId) {
        int i = 0;
        Object obj = null;
        Number number1 = null;
        Number number2 = null;
        String s2 = null;
        String strIrecUserAcctSiteUseId = null;
        oapagecontext.writeDiagnostics(this, "--AccountDetailsBaseCO setGrandTotals trx_type: " + s, 1);
        oapagecontext.writeDiagnostics(this, "--AccountDetailsBaseCO setGrandTotals trx_status: " + trx_status, 1);
        oapagecontext.writeDiagnostics(this, "--AccountDetailsBaseCO setGrandTotals ActiveCurrencyCode: " + s1, 1);
        oapagecontext.writeDiagnostics(this, "--AccountDetailsBaseCO setGrandTotals strSessionId: " + strSessionId, 1);
        oapagecontext.writeDiagnostics(this, "--AccountDetailsBaseCO setGrandTotals strUserId: " + strUserId, 1);
        oapagecontext.writeDiagnostics(this, "--AccountDetailsBaseCO setGrandTotals activeCustomerId: " + activeCustomerId, 1);
        oapagecontext.writeDiagnostics(this, "--AccountDetailsBaseCO setGrandTotals activeCustomerSiteUseId: " + activeCustomerSiteUseId, 1);
        
        if (activeCustomerSiteUseId == null || "".equals(activeCustomerSiteUseId))
            strIrecUserAcctSiteUseId = "-1";
        else
            strIrecUserAcctSiteUseId = activeCustomerSiteUseId;
        
        oapagecontext.writeDiagnostics(this, "--AccountDetailsBaseCO setGrandTotals strIrecUserAcctSiteUseId: " + strIrecUserAcctSiteUseId, 1);
        oapagecontext.writeDiagnostics(this, "--AccountDetailsBaseCO setGrandTotals strOrgId: " + strOrgId, 1);
        
        /*
        if (s == null || "ALL_TRX".equals(s) || "CONSBILLNUMBER".equals(s) ||
            "CREDIT_MEMOS".equals(s) || "DEBIT_MEMOS".equals(s) ||
            "DEPOSITS".equals(s) || "INVOICES".equals(s) ||
            "PAYMENTS".equals(s) || "CHARGEBACKS".equals(s) ||
            "GUARANTEES".equals(s) || "ALL_DEBIT_TRX".equals(s)) {
            if (s == null || "ALL_TRX".equals(s))
                //Bushrod replaced:                s2 = "AND ";
                //with:
                s2 =
 //"AND NVL(ct.ship_to_site_use_id,'-1') = NVL( :7 , NVL(ct.ship_to_site_use_id,'-1')) AND ";
 "AND NVL(ct.ship_to_site_use_id,'-1') = NVL( :7 , NVL(ct.ship_to_site_use_id,'-1'))";
            else if ("CREDIT_MEMOS".equals(s))
                //Bushrod replaced:                s2 = "AND CLASS = 'CM' AND ";
                //with:
                s2 =
 //"AND CLASS = 'CM' AND NVL(ct.ship_to_site_use_id,'-1') = NVL( :7 , NVL(ct.ship_to_site_use_id,'-1')) AND ";
 "AND CLASS = 'CM' AND NVL(ct.ship_to_site_use_id,'-1') = NVL( :7 , NVL(ct.ship_to_site_use_id,'-1')) ";
            else if ("DEBIT_MEMOS".equals(s))
                //Bushrod replaced:                s2 = "AND CLASS = 'DM' AND ";
                //with:
                s2 =
 //"AND CLASS = 'DM' AND NVL(ct.ship_to_site_use_id,'-1') = NVL( :7 , NVL(ct.ship_to_site_use_id,'-1')) AND ";
 "AND CLASS = 'DM' AND NVL(ct.ship_to_site_use_id,'-1') = NVL( :7 , NVL(ct.ship_to_site_use_id,'-1')) ";
            else if ("DEPOSITS".equals(s))
                //Bushrod replaced:                s2 = "AND CLASS = 'DEP' AND ";
                //with:
                s2 =
 //"AND CLASS = 'DEP' AND NVL(ct.ship_to_site_use_id,'-1') = NVL( :7 , NVL(ct.ship_to_site_use_id,'-1')) AND ";
 "AND CLASS = 'DEP' AND NVL(ct.ship_to_site_use_id,'-1') = NVL( :7 , NVL(ct.ship_to_site_use_id,'-1')) ";
            else if ("INVOICES".equals(s))
                //Bushrod replaced:                s2 = "AND CLASS = 'INV' AND ";
                //with:
                s2 =
 //"AND CLASS = 'INV' AND NVL(ct.ship_to_site_use_id,'-1') = NVL( :7 , NVL(ct.ship_to_site_use_id,'-1')) AND ";
  "AND CLASS = 'INV' AND NVL(ct.ship_to_site_use_id,'-1') = NVL( :7 , NVL(ct.ship_to_site_use_id,'-1')) ";
            else if ("PAYMENTS".equals(s))
                //s2 = "AND CLASS = 'PMT' AND ";
                s2 = "AND CLASS = 'PMT' ";
            //              s2 = "AND CLASS = 'PMT' AND NVL(ct.ship_to_site_use_id,'-1') = NVL( :7 , NVL(ct.ship_to_site_use_id,'-1')) AND "; --removed for defect 8915
            else if ("CHARGEBACKS".equals(s))
                //s2 = "AND CLASS = 'CB' AND ";
                s2 = "AND CLASS = 'CB' ";
            else if ("GUARANTEES".equals(s))
                //s2 = "AND CLASS = 'GUAR' AND ";
                s2 = "AND CLASS = 'GUAR' ";
            else if ("ALL_DEBIT_TRX".equals(s))
                //Bushrod replaced:                s2 = "AND CLASS IN ('CB', 'INV', 'DM', 'DEP') AND ";
                //with:
                s2 =
 //"AND CLASS IN ('CB', 'INV', 'DM', 'DEP')  AND NVL(ct.ship_to_site_use_id,'-1') = NVL( :7 , NVL(ct.ship_to_site_use_id,'-1')) AND ";
 "AND CLASS IN ('CB', 'INV', 'DM', 'DEP')  AND NVL(ct.ship_to_site_use_id,'-1') = NVL( :7 , NVL(ct.ship_to_site_use_id,'-1')) ";
            else if ("CONSBILLNUMBER".equals(s)) {
                //s2 = "AND ";
                s2 = " AND NVL(ct.ship_to_site_use_id,'-1') = NVL( :7 , NVL(ct.ship_to_site_use_id,'-1')) ";
            }
        } else {
            //s2 =  "AND ";
            s2 =  " ";
        }
        ViewObject viewobject = null;
        Object obj1 = null;
        String s3 = " " + oaviewobject.getWhereClause();
        String s4 = getModifiedWhereClause(s3, s);
        Object aobj[] = oaviewobject.getWhereClauseParams();
            
        oapagecontext.writeDiagnostics(this, "--AccountDetailsBaseCO setGrandTotals getWhereClause: " + s2, 1);
        oapagecontext.writeDiagnostics(this, "--AccountDetailsBaseCO setGrandTotals getWhereClause: " + s3, 1);
        oapagecontext.writeDiagnostics(this, "--AccountDetailsBaseCO setGrandTotals getModifiedWhereClause: " + s4, 1);
        if ("PAYMENTS".equals(s) || "CREDIT_MEMOS".equals(s)) {
            int j = aobj.length;
            Object aobj1[] = new Object[j - 2];
            for (int k = 2; k < j; k++)
                aobj1[k - 2] = aobj[k];

            aobj = aobj1;
        }
        for (int z=0; z<aobj.length; z++)
          oapagecontext.writeDiagnostics(this, "--AccountDetailsBaseCO setGrandTotals getWhereClauseParams: [" + z + "]" + aobj[z], 1);
        //          String s5 = "SELECT count(*) COUNT, nvl( SUM ( amount_due_original ), 0) SUM_AMOUNT_DUE_ORIGINAL, nvl(SUM(amount_due_remaining ), 0) SUM_AMOUNT_DUE_REMAINING FROM AR_PAYMENT_SCHEDULES ArPaymentSchedulesV, ra_customer_trx ct, ar_irec_user_acct_sites_all auasa WHERE ( trunc( ArPaymentSchedulesV.TRX_DATE ) >= nvl2(  :1 , trunc ( add_months(SYSDATE, :2 ) ) , trunc ( ArPaymentSchedulesV.TRX_DATE ))) AND ArPaymentSchedulesV.customer_trx_id = ct.customer_trx_id AND ArPaymentSchedulesV.customer_id = auasa.customer_id AND ArPaymentSchedulesV.CUSTOMER_SITE_USE_ID = auasa.CUSTOMER_SITE_USE_ID AND auasa.USER_ID = FND_GLOBAL.USER_ID AND auasa.session_id = :3 " + s2 + s4;
        //          String s5 = "SELECT count(*) COUNT, nvl( SUM ( amount_due_original ), 0) SUM_AMOUNT_DUE_ORIGINAL, nvl(SUM(amount_due_remaining ), 0) SUM_AMOUNT_DUE_REMAINING FROM AR_PAYMENT_SCHEDULES ArPaymentSchedulesV, ra_customer_trx ct, ar_irec_user_acct_sites_all auasa WHERE ( trunc( ArPaymentSchedulesV.TRX_DATE ) >= nvl2(  :1 , trunc ( add_months(SYSDATE, :2 ) ) , trunc ( ArPaymentSchedulesV.TRX_DATE ))) AND ArPaymentSchedulesV.customer_trx_id = ct.customer_trx_id AND ArPaymentSchedulesV.customer_id = auasa.customer_id AND ArPaymentSchedulesV.CUSTOMER_SITE_USE_ID = auasa.CUSTOMER_SITE_USE_ID AND auasa.USER_ID = FND_GLOBAL.USER_ID AND auasa.session_id = :3 " + s2; // commented for R12 upgrade
        
        //String s5 =
        //    "SELECT /*+ leading(auasa) use_hash(ArPaymentSchedulesV auasa)*/ //count(1) COUNT, nvl( SUM ( amount_due_original ), 0) SUM_AMOUNT_DUE_ORIGINAL, nvl(SUM(amount_due_remaining ), 0) SUM_AMOUNT_DUE_REMAINING FROM AR_PAYMENT_SCHEDULES ArPaymentSchedulesV, ra_customer_trx ct, ar_irec_user_acct_sites_all auasa WHERE ( trunc( ArPaymentSchedulesV.TRX_DATE ) >= nvl2(  :1 , trunc ( add_months(SYSDATE, :2 ) ) , trunc ( ArPaymentSchedulesV.TRX_DATE ))) AND ArPaymentSchedulesV.customer_trx_id = ct.customer_trx_id AND ArPaymentSchedulesV.customer_id = auasa.customer_id AND(TRUNC(arpaymentschedulesv.trx_date)) >= trunc(decode( nvl(FND_PROFILE.VALUE(\'ARI_FILTER_TRXDATE_OLDER\'), 0), 0, arpaymentschedulesv.trx_date, (sysdate-FND_PROFILE.VALUE(\'ARI_FILTER_TRXDATE_OLDER\'))))\nAND (ct.printing_option =  decode(nvl(FND_PROFILE.VALUE(\'ARI_FILTER_DONOTPRINT_TRX\'), \'NOT\'), \'Y\', \'PRI\', ct.printing_option) OR ArPaymentSchedulesV.CLASS=\'PMT\') AND auasa.session_id = :3 AND auasa.USER_ID = :4 AND auasa.ORG_ID = :5 AND auasa.CUSTOMER_SITE_USE_ID = :6 " +
        //    s2;

        //if (s == null || "ALL_TRX".equals(s) || "PAYMENTS".equals(s))
        //    //              s5 = "SELECT count(*) COUNT, nvl( SUM ( amount_due_original ), 0) SUM_AMOUNT_DUE_ORIGINAL, nvl(SUM (decode(class,'PMT', ar_irec_payments.get_pymt_amnt_due_remaining(cash_receipt_id),amount_due_remaining )), 0)  SUM_AMOUNT_DUE_REMAINING FROM AR_PAYMENT_SCHEDULES ArPaymentSchedulesV, ra_customer_trx ct, ar_irec_user_acct_sites_all auasa WHERE ( trunc( ArPaymentSchedulesV.TRX_DATE ) >= nvl2(  :1 , trunc ( add_months(SYSDATE, :2 ) ) , trunc ( ArPaymentSchedulesV.TRX_DATE ))) AND ArPaymentSchedulesV.customer_trx_id = ct.customer_trx_id(+) AND ArPaymentSchedulesV.customer_id = auasa.customer_id AND ( ArPaymentSchedulesV.CUSTOMER_SITE_USE_ID = auasa.CUSTOMER_SITE_USE_ID  OR (auasa.CUSTOMER_SITE_USE_ID = -1 AND ArPaymentSchedulesV.CUSTOMER_SITE_USE_ID IS NULL))  AND auasa.USER_ID = FND_GLOBAL.USER_ID AND auasa.session_id = :3 " + s2 + s4;
        //    // s5 =  "SELECT count(*) COUNT, nvl( SUM ( amount_due_original ), 0) SUM_AMOUNT_DUE_ORIGINAL, nvl(SUM (decode(class,'PMT', ar_irec_payments.get_pymt_amnt_due_remaining(cash_receipt_id),amount_due_remaining )), 0)  SUM_AMOUNT_DUE_REMAINING FROM AR_PAYMENT_SCHEDULES ArPaymentSchedulesV, ra_customer_trx ct, ar_irec_user_acct_sites_all auasa WHERE ( trunc( ArPaymentSchedulesV.TRX_DATE ) >= nvl2(  :1 , trunc ( add_months(SYSDATE, :2 ) ) , trunc ( ArPaymentSchedulesV.TRX_DATE ))) AND ArPaymentSchedulesV.customer_trx_id = ct.customer_trx_id(+) AND ArPaymentSchedulesV.customer_id = auasa.customer_id AND ( ArPaymentSchedulesV.CUSTOMER_SITE_USE_ID = auasa.CUSTOMER_SITE_USE_ID  OR (auasa.CUSTOMER_SITE_USE_ID = -1 AND ArPaymentSchedulesV.CUSTOMER_SITE_USE_ID IS NULL))  AND auasa.USER_ID = FND_GLOBAL.USER_ID AND auasa.session_id = :3 " +  s2; //commented for R12 upgrade
        //    s5 =
        //    "SELECT /*+ leading(auasa) use_hash(ArPaymentSchedulesV auasa)*/ count(1) COUNT, nvl( SUM ( amount_due_original ), 0) SUM_AMOUNT_DUE_ORIGINAL, nvl(SUM (decode(class,\'PMT\', ar_irec_payments.get_pymt_amnt_due_remaining(cash_receipt_id),amount_due_remaining )), 0)  SUM_AMOUNT_DUE_REMAINING FROM AR_PAYMENT_SCHEDULES ArPaymentSchedulesV, ra_customer_trx ct,ar_irec_user_acct_sites_all auasa WHERE ( trunc( ArPaymentSchedulesV.TRX_DATE ) >= nvl2(  :1 , trunc ( add_months(SYSDATE, :2 ) ) , trunc ( ArPaymentSchedulesV.TRX_DATE ))) AND ArPaymentSchedulesV.customer_trx_id = ct.customer_trx_id(+) AND ArPaymentSchedulesV.customer_id = auasa.customer_id  AND(TRUNC(arpaymentschedulesv.trx_date)) >= trunc(decode( nvl(FND_PROFILE.VALUE(\'ARI_FILTER_TRXDATE_OLDER\'), 0), 0, arpaymentschedulesv.trx_date, (sysdate-FND_PROFILE.VALUE(\'ARI_FILTER_TRXDATE_OLDER\'))))\nAND (ct.printing_option =  decode(nvl(FND_PROFILE.VALUE(\'ARI_FILTER_DONOTPRINT_TRX\'), \'NOT\'), \'Y\', \'PRI\', ct.printing_option) OR ArPaymentSchedulesV.CLASS=\'PMT\') AND auasa.session_id = :3 AND auasa.USER_ID = :4  AND auasa.ORG_ID = :5 AND auasa.CUSTOMER_SITE_USE_ID = :6 " +
        //       s2;
        //    
        //if ("CONSBILLNUMBER".equals(s)) {
        //               s5 =
        //    "SELECT /*+ leading(auasa) use_hash(ArPaymentSchedulesV auasa)*/ count(1) COUNT, nvl( SUM ( amount_due_original ), 0) SUM_AMOUNT_DUE_ORIGINAL, nvl(SUM (decode(class,\'PMT\', ar_irec_payments.get_pymt_amnt_due_remaining(cash_receipt_id),amount_due_remaining )), 0)  SUM_AMOUNT_DUE_REMAINING FROM AR_PAYMENT_SCHEDULES ArPaymentSchedulesV, ra_customer_trx ct , AR_CONS_INV_ALL ArCnsinv,ar_irec_user_acct_sites_all auasa WHERE ( trunc( ArPaymentSchedulesV.TRX_DATE ) >= nvl2(  :1 , trunc ( add_months(SYSDATE, :2 ) ) , trunc ( ArPaymentSchedulesV.TRX_DATE ))) AND ArPaymentSchedulesV.customer_trx_id = ct.customer_trx_id(+) AND ArPaymentSchedulesV.cons_inv_id = ArCnsinv.cons_inv_id AND ArPaymentSchedulesV.customer_id = auasa.customer_id  AND(TRUNC(arpaymentschedulesv.trx_date)) >= trunc(decode( nvl(FND_PROFILE.VALUE(\'ARI_FILTER_TRXDATE_OLDER\'), 0), 0, arpaymentschedulesv.trx_date, (sysdate-FND_PROFILE.VALUE(\'ARI_FILTER_TRXDATE_OLDER\'))))\n AND (ct.printing_option =  decode(nvl(FND_PROFILE.VALUE(\'ARI_FILTER_DONOTPRINT_TRX\'), \'NOT\'), \'Y\', \'PRI\', ct.printing_option) OR ArPaymentSchedulesV.CLASS=\'PMT\') AND auasa.session_id = :3 AND auasa.USER_ID = :4  AND auasa.ORG_ID = :5 AND auasa.CUSTOMER_SITE_USE_ID = :6 " +
        //       s2;
        //    }
        //    
        //           // For CR619:
        //if (s4.indexOf("XX_RELEASE_NUMBER") >= 0 ||
        //               s4.indexOf("XX_COST_CENTER_DEPT") >= 0 ||
        //               s4.indexOf("XX_DESK_DEL_ADDR") >= 0) {
        //               s5 =
        //    s5.replace("FROM AR_PAYMENT_SCHEDULES", "FROM XX_OM_HEADER_ATTRIBUTES_ALL oha, AR_PAYMENT_SCHEDULES");
        //               s5 =
        //    s5.replace(" WHERE ", " WHERE ct.attribute14 = oha.header_id(+) AND ");
        //    s4 = s4.replace("XX_RELEASE_NUMBER", "oha.RELEASE_NUMBER");
        //    s4 = s4.replace("XX_COST_CENTER_DEPT", "oha.COST_CENTER_DEPT");
        //    s4 = s4.replace("XX_DESK_DEL_ADDR", "oha.DESK_DEL_ADDR");
        //}
        //s5 = s5 + " AND ArPaymentSchedulesV.customer_Id = :8 AND ArPaymentSchedulesV.status  = nvl(:9,ArPaymentSchedulesV.status)";
        ////s5 = s5 + s4;
        //oapagecontext.writeDiagnostics(this, "--AccountDetailsBaseCO setGrandTotals SQL Stmt for VO: " + s5, 1);
        //viewobject =
        //        oapagecontext.getApplicationModule(oawebbean).createViewObjectFromQueryStmt(null,
        //                                                                                    s5);
        //
        ////viewobject.setWhereClauseParams(aobj);
        //
        //String StrTrxStatus = "";
        //if ("".equals(trx_status.trim()))
        //  StrTrxStatus = null;
        //else {
        //  StrTrxStatus = statusForWhereClause(trx_status);
        //}
        //
        //if ("".equals(trx_status.trim()))
        //    trx_status = null;
        //Object[] whereClauseParamObjs = {null, null, strSessionId, strUserId, strOrgId, strIrecUserAcctSiteUseId, activeCustomerSiteUseId, activeCustomerId, StrTrxStatus};
        //viewobject.setWhereClauseParams(whereClauseParamObjs);
        //viewobject.setWhereClauseParams(null);
        //viewobject.setWhereClauseParam(0,null);
        //viewobject.setWhereClauseParam(1,null);
        //viewobject.setWhereClauseParam(2,strSessionId);
        //viewobject.setWhereClauseParam(3,strUserId);
        //viewobject.setWhereClauseParam(4,activeCustomerSiteUseId);
        //viewobject.setWhereClauseParam(5,activeCustomerId);
        //viewobject.setMaxFetchSize(-1);
        
        ViewObject viewobject = null;
        String aggregateStmt = "select  count(1) COUNT, nvl( SUM ( amount_due_original ), 0) SUM_AMOUNT_DUE_ORIGINAL , nvl(SUM(amount_due_remaining ), 0) SUM_AMOUNT_DUE_REMAINING from ( " + oaviewobject.getQuery() + " ) qrlst";
        viewobject =
                oapagecontext.getApplicationModule(oawebbean).createViewObjectFromQueryStmt(null,
                                                                                            aggregateStmt);
        oapagecontext.writeDiagnostics(this, "--AccountDetailsBaseCO setGrandTotals SQL Stmt for VO: " + aggregateStmt, 1); 
        Object aobj[] = oaviewobject.getWhereClauseParams(); 
        viewobject.setWhereClauseParams(aobj);        
        viewobject.executeQuery();
        if (viewobject.hasNext()) {
            oapagecontext.writeDiagnostics(this, "--AccountDetailsBaseCO viewobject.hasNext true", 1);
            oracle.jbo.Row row = viewobject.next();
            Number number = (Number)row.getAttribute(0);
            number1 = (Number)row.getAttribute(1);
            number2 = (Number)row.getAttribute(2);
            i = number.intValue();
            oapagecontext.writeDiagnostics(this, "--AccountDetailsBaseCO TotalNumberOFTrxs: " + i, 1);
            if (number1 != null)
              oapagecontext.writeDiagnostics(this, "--AccountDetailsBaseCO number1: " + number1.intValue(), 1);
            if (number2 != null)
              oapagecontext.writeDiagnostics(this, "--AccountDetailsBaseCO number2: " + number2.intValue(), 1);
        }
        viewobject.remove();
        if (i > 0 && s1 != null) {
            OAMessageStyledTextBean oamessagestyledtextbean =
                (OAMessageStyledTextBean)oapagecontext.getPageLayoutBean().findChildRecursive("NoOfTrx");
            OAMessageStyledTextBean oamessagestyledtextbean1 =
                (OAMessageStyledTextBean)oapagecontext.getPageLayoutBean().findChildRecursive("GTOriginalAmt");
            OAMessageStyledTextBean oamessagestyledtextbean2 =
                (OAMessageStyledTextBean)oapagecontext.getPageLayoutBean().findChildRecursive("GTRemainingAmt");
            String s6 =
                getFormattedAmount(oapagecontext, oawebbean, number1, s1);
            String s7 =
                getFormattedAmount(oapagecontext, oawebbean, number2, s1);
            if (oamessagestyledtextbean1 != null)
                oamessagestyledtextbean1.setValue(oapagecontext, s6);
            if (oamessagestyledtextbean2 != null)
                oamessagestyledtextbean2.setValue(oapagecontext, s7);
            if (oamessagestyledtextbean != null)
                oamessagestyledtextbean.setValue(oapagecontext,
                                                 String.valueOf(i));
        }

        return i;
    }


    private void initialiseRelatedCustomerAcct(OAApplicationModule am,
                                               Long customerId, Long sessionId,
                                               Long userId, Long orgId,
                                               String isInternal) {


        String sql =
            "BEGIN ARW_SEARCH_CUSTOMERS.update_account_sites(" + "p_customer_id => :1," +
            "p_session_id => :2," + "p_user_id => :3," + "p_org_id => :4," +
            "p_is_internal_user => :5);" + "END;";

        OADBTransaction trx = (OADBTransaction)am.getOADBTransaction();
        OracleCallableStatement cStmt =
            (OracleCallableStatement)trx.createCallableStatement(sql, 1);

        try {
            cStmt.setLong(1, customerId);
            cStmt.setLong(2, sessionId);
            cStmt.setLong(3, userId);
            cStmt.setLong(4, orgId);
            cStmt.setString(5, isInternal);

            cStmt.execute();

        } catch (Exception e) {
            throw OAException.wrapperException(e);
        } finally {
            try {
                cStmt.close();
            } catch (Exception e) {
                throw OAException.wrapperException(e);
            }
        } //finally


    }

    private String getModifiedWhereClause(String whereClause, String trxType) {
        String newWhereClause = whereClause;
        // added for bug 6889365
        if ("CONSBILLNUMBER".equals(trxType)) {

            if (newWhereClause.indexOf("customer_id") != -1)
                newWhereClause =
                        replace(newWhereClause, "customer_id", "ArPaymentSchedulesV.customer_id");
            if (newWhereClause.indexOf("status") != -1)
                newWhereClause =
                        replace(newWhereClause, "status", "ArPaymentSchedulesV.status");
            // In the first if condition string 'paying_customer_id' will be replaced to 'paying_ArPaymentSchedulesV.customer_id'
            // which is incorrect , and so replacing back to the  original string 'paying_customer_id' in the following condition
            if (newWhereClause.indexOf("paying_ArPaymentSchedulesV.customer_id") !=
                -1)
                newWhereClause =
                        replace(newWhereClause, "paying_ArPaymentSchedulesV.customer_id",
                                "paying_customer_id");
            if (newWhereClause.indexOf("due_date") !=
                -1) // bug 	9068491
                newWhereClause =
                        replace(newWhereClause, "due_date", "ArPaymentSchedulesV.due_date");
            if (newWhereClause.indexOf("DUE_DATE") != -1) // bug   9068491
                newWhereClause =
                        replace(newWhereClause, "DUE_DATE", "ArPaymentSchedulesV.DUE_DATE");
        } else { // added for bug 9040332
            if (newWhereClause.indexOf("customer_id") != -1)
                newWhereClause =
                        replace(newWhereClause, "customer_id", "ArPaymentSchedulesV.customer_id");

        }
        if (newWhereClause.indexOf("invoice_currency_code") != -1)
            newWhereClause =
                    replace(newWhereClause, "invoice_currency_code", "ArPaymentSchedulesV.invoice_currency_code");
        if (newWhereClause.indexOf("trx_number") != -1)
            newWhereClause =
                    replace(newWhereClause, "trx_number", "ArPaymentSchedulesV.trx_number");
        if (newWhereClause.indexOf("ct_purchase_order") != -1)
            newWhereClause =
                    replace(newWhereClause, "ct_purchase_order", "purchase_order");
        if (newWhereClause.indexOf(" customer_trx_id ") != -1)
            newWhereClause =
                    replace(newWhereClause, " customer_trx_id ", " ArPaymentSchedulesV.customer_trx_id ");
        if (newWhereClause.indexOf("TRX_DATE") != -1) // bug 	9694718
            newWhereClause =
                    replace(newWhereClause, "TRX_DATE", " ArPaymentSchedulesV.TRX_DATE");
        //Bug 5649716 - Append alias name to remove SQL Query error
        if (newWhereClause.indexOf("customer_site_use_id") != -1)
            newWhereClause =
                    replace(newWhereClause, "customer_site_use_id", "ArPaymentSchedulesV.customer_site_use_id");
        if (newWhereClause.indexOf("paying_ArPaymentSchedulesV.customer_id") !=
            -1)
            newWhereClause =
                    replace(newWhereClause, "paying_ArPaymentSchedulesV.customer_id",
                            "paying_customer_id");
        if (newWhereClause.indexOf(" CLASS1") != -1)
            newWhereClause = replace(newWhereClause, " CLASS1", " CLASS");
        // Bug#6074405
        if (newWhereClause.indexOf(" CLASS2") != -1)
            newWhereClause = replace(newWhereClause, " CLASS2", " CLASS");
        if (newWhereClause.indexOf(" class2") != -1)
            newWhereClause = replace(newWhereClause, " class2", " CLASS");
        // Bug # 7678038 - NEed to Show Receips created with out location
        if ((newWhereClause.indexOf("ArPaymentSchedulesV.customer_site_use_id") !=
             -1) && ("ALL_TRX".equals(trxType) || "PAYMENTS".equals(trxType)))
            newWhereClause =
                    replace(newWhereClause, "ArPaymentSchedulesV.customer_site_use_id",
                            "auasa.customer_site_use_id");

        // Added For R1.2 CR 619 (consolidated bill filter)
        if (newWhereClause.indexOf("xx_cons_inv_id") != -1)
            newWhereClause =
                    replace(newWhereClause, "xx_cons_inv_id", "ct.batch_source_id in (SELECT batch_source_id FROM XX_AR_CONSBILL_BATCH_SOURCES_V) and cons_inv_id");


        return newWhereClause;
    }

    public static String replace(String source, String pattern,
                                 String replace) {
        if (source != null) {
            final int len = pattern.length();
            StringBuffer sb = new StringBuffer();
            int found = -1;
            int start = 0;

            while ((found = source.indexOf(pattern, start)) != -1) {
                sb.append(source.substring(start, found));
                sb.append(replace);
                start = found + len;
            }

            sb.append(source.substring(start));

            return sb.toString();
        } else
            return "";
    }

    private String getFormattedAmount(OAPageContext pageContext,
                                      OAWebBean webBean, Number sumAmount,
                                      String currCode) {
        try {
            if (null == sumAmount)
                return "";
            double amt = sumAmount.bigDecimalValue().doubleValue();
            OAApplicationModuleImpl am =
                (OAApplicationModuleImpl)pageContext.getApplicationModule(webBean);
            OAApplicationModuleImpl amR =
                (am.isRoot() ? am : (OAApplicationModuleImpl)am.getRootApplicationModule());
            return CurrencyHelper.getFormattedNumericValue(((oracle.apps.fnd.framework.server.OADBTransactionImpl)amR.getOADBTransaction()).getOANLSServices(),
                                                           ((oracle.apps.fnd.framework.server.OADBTransactionImpl)amR.getOADBTransaction()).getAppsContext(),
                                                           currCode, amt);
        } catch (java.sql.SQLException e) {
            throw new OAException("AccountDetailsBaseCO.getFormattedAmount() failed");
        }
    }

    private Date[] getDateFromAccountSearchVO(OAPageContext pageContext,
                                              OAWebBean webBean) {
        Date[] retValues = new Date[4];
        String[] items =
        { "Aritransdatefrom", "Aritransdateto", "Ariduedatefrom",
          "Ariduedateto" };
        String[] sDates = { "null", "null", "null", "null" };

        for (int i = 0; i < items.length; i++) {
            OAMessageDateFieldBean dateBean = null;
            OAPageLayoutBean layoutBean =
                (OAPageLayoutBean)pageContext.getPageLayoutBean();
            if (layoutBean != null)
                dateBean =
                        (OAMessageDateFieldBean)layoutBean.findIndexedChildRecursive(items[i]);

            retValues[i] = null;
            if (dateBean != null && dateBean.getValue(pageContext) != null)
                retValues[i] =
                        new Date((Timestamp)dateBean.getValue(pageContext));

            if (retValues[i] != null)
                sDates[i] = retValues[i].stringValue();
        }

        // Bug # 1927616  - hikumar
        if (retValues[1] != null && retValues[0] != null) {
            if (retValues[1].compareTo(retValues[0]) < 0) {
                throw new OAException("AR", "ARI_ACCT_ADV_SEARCH_DATE");
            }
        }

        if (retValues[3] != null && retValues[2] != null) {
            if (retValues[3].compareTo(retValues[2]) < 0) {
                throw new OAException("AR", "ARI_ACCT_ADV_SEARCH_DATE");
            }
        }
        // Bug # 1927616  - hikumar

        if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
            pageContext.writeDiagnostics(this,
                                         "getDateFromAccountSearchVO is returning the following dates: " +
                                         "DateFrom    = " + sDates[0] + ",  " +
                                         "DateTo      = " + sDates[1] + ",  " +
                                         "DueDateFrom = " + sDates[2] + ",  " +
                                         "DueDateTo   = " + sDates[3] + " ) ",
                                         OAFwkConstants.STATEMENT);


        return retValues;
    }

    // NumDays is "Days past due" if aging is being used, null o.w.
    // This function will return the more constricting search criteria between
    // dueDate and numDays.
    /*
  private Date adjustDueDateForAging(OAPageContext pageContext, oracle.jbo.domain.Date dueDate,
                                     long numDays, boolean isStart)
  {
    java.util.Date today = pageContext.getCurrentDBDate();
    if (numDays == -9999999) numDays= -99999;  //added for bug 9882826 by avepati
    long bucketDateInMilliseconds = today.getTime() + numDays * 24 * 60 * 60 * 1000;
    java.sql.Date sqlBucketDate = new java.sql.Date(bucketDateInMilliseconds);
    oracle.jbo.domain.Date bucketDate = new oracle.jbo.domain.Date(sqlBucketDate);

    // Return bucket Date if no advanced search due Date is specified
    if(dueDate == null)
      return bucketDate;

    // Return the starting advanced search date if it is later than the bucket start date
    if(isStart && dueDate.compareTo(bucketDate) == 1 )
      return dueDate;

    // Return the ending advanced search date if it is earlier than the bucket end date
    if(!isStart && dueDate.compareTo(bucketDate) == -1 )
      return dueDate;

    // Return the bucket date if the advanced search date is outside the bucket.
    return bucketDate;
  }
  */

    // NumDays is "Days past due" if aging is being used, null o.w.
    // This function will return the more constricting search criteria between
    // dueDate and numDays.

    private Date adjustDueDateForAging(OAPageContext pageContext,
                                       oracle.jbo.domain.Date dueDate,
                                       long numDays, boolean isStart) {
        OADBTransaction txn =
            pageContext.getRootApplicationModule().getOADBTransaction();

        txn.writeDiagnostics("XXOD:adjustDueDateForAging",
                             "**start adjustDueDateForAging", 1);
        txn.writeDiagnostics("XXOD:adjustDueDateForAging", "dueDate" + dueDate,
                             1);
        txn.writeDiagnostics("XXOD:adjustDueDateForAging", "numDays" + numDays,
                             1);
        if (isStart) {
            txn.writeDiagnostics("XXOD:adjustDueDateForAging", "isstart true",
                                 1);
        } else {
            txn.writeDiagnostics("XXOD:adjustDueDateForAging", "isstart false",
                                 1);
        }
        java.util.Date today = pageContext.getCurrentDBDate();

        txn.writeDiagnostics("XXOD:adjustDueDateForAging", "today" + today, 1);

        //if (numDays == -9999999) numDays= -99999;  //added for bug 9882826 by avepati

        if (numDays == -9999999)
            numDays = -999999; //added for Defect30336

        //if (Math.abs(numDays) == 9999999) numDays=999999;  //added for defect 26258
        if (numDays == 9999999)
            numDays = 999999; //added for defect 26258

        txn.writeDiagnostics("XXOD:adjustDueDateForAging",
                             "numDays ==::" + numDays, 1);

        long bucketDateInMilliseconds =
            today.getTime() + numDays * 24 * 60 * 60 * 1000;

        txn.writeDiagnostics("XXOD:adjustDueDateForAging",
                             "bucketDateInMilliseconds::" +
                             bucketDateInMilliseconds, 1);
        java.sql.Date sqlBucketDate =
            new java.sql.Date(bucketDateInMilliseconds);

        txn.writeDiagnostics("XXOD:adjustDueDateForAging",
                             "sqlBucketDate::" + sqlBucketDate, 1);

        oracle.jbo.domain.Date bucketDate =
            new oracle.jbo.domain.Date(sqlBucketDate);

        txn.writeDiagnostics("XXOD:adjustDueDateForAging",
                             " bucketDate ::" + bucketDate, 1);

        // Return bucket Date if no advanced search due Date is specified
        if (dueDate == null)
            return bucketDate;

        // Return the starting advanced search date if it is later than the bucket start date
        if (isStart && dueDate.compareTo(bucketDate) == 1)
            return dueDate;

        // Return the ending advanced search date if it is earlier than the bucket end date
        if (!isStart && dueDate.compareTo(bucketDate) == -1)
            return dueDate;

        // Return the bucket date if the advanced search date is outside the bucket.
        return bucketDate;
    }

    protected void SaveSearchCriteria(OAPageContext pageContext,
                                      OAWebBean webBean) {
        String type = getSearchType(pageContext, webBean);
        String status = getSearchStatus(pageContext, webBean);
        String currency =
            pageContext.getParameter(SearchHeaderCO.CURRENCY_CODE_KEY);
        String keyword = pageContext.getParameter("Iracctdtlskeyword");
        String amountFrom = pageContext.getParameter("Ariamountfrom");
        String amountTo = pageContext.getParameter("Ariamountto");
        String trxDateFrom = pageContext.getParameter("Aritransdatefrom");
        String trxDateTo = pageContext.getParameter("Aritransdateto");
        String dueDateFrom = pageContext.getParameter("Ariduedatefrom");
        String dueDateTo = pageContext.getParameter("Ariduedateto");

        //Added for R12 upgrade retrofit
        // Bushrod added for E1327
        String sXXShipToIDValue = pageContext.getParameter("XXShipToIDValue");
        // Bushrod added for CR619
        String sXXConsBill = pageContext.getParameter("XXConsBill");
        String sXXTransactions = pageContext.getParameter("XXTransactions");
        String sXXPurchaseOrder = pageContext.getParameter("XXPurchaseOrder");
        String sXXDept = pageContext.getParameter("XXDept");
        String sXXDesktop = pageContext.getParameter("XXDesktop");
        String sXXRelease = pageContext.getParameter("XXRelease");

        //End - Added for R12 upgrade retrofit

        if (status == null || "".equals(status))
            status = "OPEN";

        if (type == null || "".equals(type))
            type = "ALL_TRX";

        pageContext.putSessionValue("RETURN_ACCT_DETAILS_LINK_STATUS", status);
        pageContext.putSessionValue("RETURN_ACCT_DETAILS_LINK_TYPE", type);
        pageContext.putSessionValue("RETURN_ACCT_DETAILS_LINK_CURRENCY",
                                    currency == null ? "" : currency);
        pageContext.putSessionValue("RETURN_ACCT_DETAILS_LINK_KEYWORD",
                                    keyword == null ? "" : keyword);
        pageContext.putSessionValue("RETURN_ACCT_DETAILS_LINK_AMTFROM",
                                    amountFrom == null ? "" : amountFrom);
        pageContext.putSessionValue("RETURN_ACCT_DETAILS_LINK_AMTTO",
                                    amountTo == null ? "" : amountTo);
        pageContext.putSessionValue("RETURN_ACCT_DETAILS_LINK_TRXDATEFROM",
                                    trxDateFrom == null ? "" : trxDateFrom);
        pageContext.putSessionValue("RETURN_ACCT_DETAILS_LINK_TRXDATETO",
                                    trxDateTo == null ? "" : trxDateTo);
        pageContext.putSessionValue("RETURN_ACCT_DETAILS_LINK_DUEDATEFROM",
                                    dueDateFrom == null ? "" : dueDateFrom);
        pageContext.putSessionValue("RETURN_ACCT_DETAILS_LINK_DUEDATETO",
                                    dueDateTo == null ? "" : dueDateTo);

        // Added for R12 ugrade retrofit
        // Bushrod added for E1327
        pageContext.putSessionValue("RETURN_ACCT_DETAILS_LINK_XXSHIPTOIDVALUE",
                                    sXXShipToIDValue != null ?
                                    sXXShipToIDValue : "");
        // Bushrod added for E2052
        pageContext.putSessionValue("RETURN_ACCT_DETAILS_LINK_XXCONSBILL",
                                    sXXConsBill != null ? sXXConsBill : "");
        pageContext.putSessionValue("RETURN_ACCT_DETAILS_LINK_XXTRANSACTIONS",
                                    sXXTransactions != null ? sXXTransactions :
                                    "");
        pageContext.putSessionValue("RETURN_ACCT_DETAILS_LINK_XXPURCHASEORDER",
                                    sXXPurchaseOrder != null ?
                                    sXXPurchaseOrder : "");
        pageContext.putSessionValue("RETURN_ACCT_DETAILS_LINK_XXDEPT",
                                    sXXDept != null ? sXXDept : "");
        pageContext.putSessionValue("RETURN_ACCT_DETAILS_LINK_XXDESKTOP",
                                    sXXDesktop != null ? sXXDesktop : "");
        pageContext.putSessionValue("RETURN_ACCT_DETAILS_LINK_XXRELEASE",
                                    sXXRelease != null ? sXXRelease : "");

        // End - Added for R12 ugrade retrofit

    }


    /**Pre-Condition:  This procedure checks whether or not the form submit event is
   caused after Browser Back Button by comparing the current URL and the URL of the
   page on which last form sumit , which is saved in session variable THEREFORE
   THE SESSION VARIABLE SHOULD BE SET ONLY AFTER THE LAST CALL TO THIS FUNCTION

   Currently the function is called from AccountDetailsPageCO first and then from
   SearchHeaderCO , so the session variable ACCOUNT_DETAILS_PAGE_LAST_URL is set
   at the end of processRequest() in SearchHeaderCO
     */
    public static boolean isBrowserBackButton(OAPageContext pageContext) {

        //  Bug # 1766614  - hikumar
        // Detect back event for form submit requests.
        if (pageContext.isFormSubmission()) {
            String currentUrl =
                OAUrl.decode(pageContext, pageContext.getCurrentUrl());
            // get teh last formsubmit URL from the session variable
            String lastUrl =
                (String)pageContext.getSessionValue("ACCOUNT_DETAILS_PAGE_LAST_URL");
            // If the form submit occurs on a URL that is different from the
            // last one, back event occurred.
            if (!pageContext.isDialogPage(lastUrl) &&
                !currentUrl.equals(lastUrl))
                return true;
        }

        return (false);
    }

    //Bug 3467287 - This method inserts records into the Transaction List;
    //and is called by the Controllers of the results for the transactions searched for.

    protected void insertIntoTransactionList(OAPageContext pageContext,
                                             String region,
                                             Boolean insertAll) {
        if (pageContext.getSessionValue("TransactionListCleared") == null) {
            clearTransactionList(pageContext);
            pageContext.putSessionValue("TransactionListCleared", "Yes");
        }

        Class[] paramType =
        { java.lang.String.class, java.lang.String.class, java.lang.String.class,
          Boolean.class };

        //Bug 4071551 - Calculate service charge after inserting all records in transaction list

        String sCustomerId = getActiveCustomerId(pageContext);
        String sCustomerSiteUseId = getActiveCustomerUseId(pageContext);


        Serializable[] params =
        { region, sCustomerId, sCustomerSiteUseId, insertAll };
        (pageContext.getRootApplicationModule()).invokeMethod("addToTransactionList",
                                                              params,
                                                              paramType);

        /*  Commented for bug # 8293098
	Serializable [] prms = { sCustomerId, sCustomerSiteUseId};
    (pageContext.getRootApplicationModule()).invokeMethod("computeServiceCharge", prms);
*/

        //pageContext.putSessionValue("RecordsInTransactionList","YES");
        putSessionValueForTrxList(pageContext, "Y");
    }

    //Bug 3933606 - Multi-Print Enhancement

    protected String printSelectedTransactions(OAPageContext pageContext,
                                               String region,
                                               Boolean printAll) {
        String bpaMultiPrintLimitSql =
            "BEGIN :1 := ARI_UTILITIES.multi_print_limit(p_customer_id => :2, p_customer_site_use_id => :3); END;";
        String bpaMultiPrintLimit = "0";

        String sCustomerId = getActiveCustomerId(pageContext);
        String sCustomerSiteUseId = getActiveCustomerUseId(pageContext);
        String sOrgId = getActiveOrgId(pageContext);

        // If customer is null then inserting in ar_irec_print_requests table is errorring out as customer_id is a not null column
        if (sCustomerId == null || "".equals(sCustomerId))
            sCustomerId = "-1"; //bug 10302989

        OADBTransaction tx =
            (OADBTransaction)pageContext.getRootApplicationModule().getOADBTransaction();
        OracleCallableStatement cStmt =
            (OracleCallableStatement)tx.createCallableStatement(bpaMultiPrintLimitSql,
                                                                1);
        try {
            cStmt.registerOutParameter(1, Types.VARCHAR, 0, 4000);
            cStmt.setString(2, sCustomerId);
            cStmt.setString(3, sCustomerSiteUseId);

            cStmt.execute();
            bpaMultiPrintLimit = cStmt.getString(1);
        } catch (Exception e) {
            throw OAException.wrapperException(e);
        } finally {
            try {
                cStmt.close();
            } catch (Exception e) {
                throw OAException.wrapperException(e);
            }
        } //finally

        //Bug # 4528713 - Obsolete 'OIR: Bill presentment architecture enabled' profile option
        String bpaPrintEnabled =
            pageContext.getProfile("OIR_INVOICE_BPA_ENABLED");
        Class[] paramType =
        { java.lang.String.class, java.lang.String.class, java.lang.String.class,
          java.lang.String.class, java.lang.String.class,
          java.lang.String.class, Boolean.class };
        Serializable[] prm =
        { region, bpaPrintEnabled, bpaMultiPrintLimit, sCustomerId,
          sCustomerSiteUseId, sOrgId, printAll };
        String sRequestIds =
            (String)pageContext.getRootApplicationModule().invokeMethod("printSelectedInvoices",
                                                                        prm,
                                                                        paramType);

        pageContext.putSessionValue("Requery", "Y"); //bug 11871875

        //Bug 4000064 - Pass the param values to the Requests page to display
        //different confirmation messages based on requests submitted
        String sBpaPrintImmediateRequestId =
            (String)tx.getValue("BpaPrintImmediate");

        String sPrintReqExceedMaxInvLimit =
            (String)tx.getValue("PrintReqExceedMaxInvLimit");
        String sPrintReqExceedMaxTrxLimit =
            (String)tx.getValue("PrintReqExceedMaxTrxLimit");
        String sPrintReqMultiTrxTypes =
            (String)tx.getValue("PrintReqMultiTrxTypes");

        HashMap params = new HashMap(5);
        params.put("requestIds", sRequestIds);
        params.put("CurrentPrintRequest", "Y");
        params.put("PrintReqExceedMaxInvLimit", sPrintReqExceedMaxInvLimit);
        params.put("PrintReqExceedMaxTrxLimit", sPrintReqExceedMaxTrxLimit);
        params.put("PrintReqMultiTrxTypes", sPrintReqMultiTrxTypes);

        //If BPA Immediate has been used, add the following params, which are reqd by BPA
        if (sBpaPrintImmediateRequestId != null) {
            String sTemplateId = tx.getProfile("OIR_BPA_TEMPLATE_SELECTION");
            params.put("templateId", sTemplateId); // bug 12353886
            params.put("templateType",
                       pageContext.getParameter("templateType"));
            params.put("preview", "Y");
            params.put("ViewType", "MULTIPRINT");
            params.put("requestId", sBpaPrintImmediateRequestId);
            params.put("UpdatePrintFlag", "Y");

            //4275821 - customer id and customer site id are to be passed for bpa.
            params.put("customer_Id", sCustomerId);
            params.put("customer_Site_Use_Id",
                       (sCustomerSiteUseId == null || !("".equals(sCustomerSiteUseId))) ?
                       sCustomerSiteUseId : "-1");


            String sProgramName =
                pageContext.getMessage("AR", "ARI_IMMEDIATE_PRINT_PROG_NAME",
                                       null);
            params.put("ProgramName", sProgramName);
        }

        pageContext.setForwardURL("OA.jsp?page=/oracle/apps/ar/irec/requests/webui/ARI_VIEW_PRINT_REQUESTS_PAGE",
                                  null, OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                  null, params, true,
                                  OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
                                  OAWebBeanConstants.IGNORE_MESSAGES);

        return sRequestIds;
    }

    /**
     * Procedure to redirect to Payment page
     * @param pageContext the current OA page context
     * @param region the name of the region submitting the request
     */
    protected
    //Bug 4000209 - Remove use of Multi Pay Error Page
    void paySelectedTransactions(OAPageContext pageContext, String region,
                                 Boolean selectAll) {
        insertIntoTransactionList(pageContext, region, selectAll);
        String payURL =
            "OA.jsp?akRegionCode=ARI_INVOICE_PAYMENT_PAGE&akRegionApplicationId=222&Irselected=Y&retainAM=Y&PayButtonClick=Y"; // Bug 16355174 - Added paramter Pay Button click
        //12650704 - When navigated to Adv Payment page, enter the New BA/CC details and then cancel the
        //transaction and come back for Payment still shows the previously entered information. Since Adv payment page has AccountDetailsAM
        //as the rootAM and AccountDetailsAM is being retained the data is being shown.
        OAApplicationModule am = pageContext.getRootApplicationModule();
        OAApplicationModule pmtAM =
            (OAApplicationModule)am.findApplicationModule("ARI_INVOICE_PAYMENT_FORM222_PaymentFormRegion_oracle_apps_ar_irec_accountDetails_pay_server_PaymentAM");
        if (pmtAM != null) {
            OAViewObject newBAVO =
                (OAViewObject)pmtAM.findViewObject("NewBankAccountVO");
            if (newBAVO != null)
                newBAVO.clearCache();
            OAViewObject newCCVO =
                (OAViewObject)pmtAM.findViewObject("NewCreditCardVO");
            if (newCCVO != null)
                newCCVO.clearCache();
            OADBTransaction trx = (OADBTransaction)pmtAM.getOADBTransaction();
            String sReceiptDate = (String)trx.getValue("ReceiptDate");
            if (sReceiptDate != null)
                trx.removeValue("ReceiptDate");
        }

        pageContext.setForwardURL(payURL.toString(), null,
                                  OAWebBeanConstants.KEEP_MENU_CONTEXT, null,
                                  null, true,
                                  OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
                                  OAWebBeanConstants.IGNORE_MESSAGES);
        // Bug # 3938122 - Credit Memo Appplications
        // pageContext.setForwardURL("ARI_MULTIPAY_ERROR_PAGE",KEEP_MENU_CONTEXT , null , null , true , ADD_BREAD_CRUMB_NO,(byte)ERROR);
    }

    // bug 8790495 - Add to Transction List will take back control to page 1

    protected void hideSelectionButtons(OAPageContext pageContext,
                                        OAWebBean webBean, HashMap prms) {

        String payLabel = (String)prms.get("Pay");
        String printLabel = (String)prms.get("Print");
        String applyCreditsLabel = (String)prms.get("ApplyCredits");
        String disputeLabel = (String)prms.get("Dispute");


        OASelectionButtonBean payButton =
            (OASelectionButtonBean)webBean.findChildRecursive(payLabel);
        OASelectionButtonBean printButton =
            (OASelectionButtonBean)webBean.findChildRecursive(printLabel);
        OASelectionButtonBean applyCreditsButton =
            (OASelectionButtonBean)webBean.findChildRecursive(applyCreditsLabel);
        OASelectionButtonBean disputeButton =
            (OASelectionButtonBean)webBean.findChildRecursive(disputeLabel);

        if (isRecordInTransactionList(pageContext)) {
            if (payButton != null)
                payButton.setRendered(false);
            if (printButton != null)
                printButton.setRendered(false);
            if (applyCreditsButton != null)
                applyCreditsButton.setRendered(false);
            if (disputeButton != null)
                disputeButton.setRendered(false);

            { //confirmation message after adding records to transaction list
                OAException confirmMessage = null;
                String msg =
                    pageContext.getMessage("AR", "ARI_TRX_LIST_CONTINUE",
                                           null);
                confirmMessage = new OAException(msg, OAException.INFORMATION);
                pageContext.putDialogMessage(confirmMessage);
            }

        }
    }

    //Bug 4237309 - Apply Credits tab appears in AccountDetails page when profile option is NO

    protected void displaySelectionButtons(OAPageContext pageContext,
                                           OAWebBean webBean, String region,
                                           HashMap prms) {

        // 23-Dec-03  vnb  Bugfix # 3329641 - Remove PAY functionality when the function
        //                                 'Pay Invoices' is excluded from the responsibility
        // Validate the payment setup
        String trxListLabel = (String)prms.get("TransactionList");
        String payLabel = (String)prms.get("Pay");
        String printLabel = (String)prms.get("Print");
        String applyCreditsLabel = (String)prms.get("ApplyCredits");
        String disputeLabel = (String)prms.get("Dispute");
        String errorColumnLabel = (String)prms.get("errorColumn");
        String errorExistsLabel = (String)prms.get("ErrorExists");


        //Hide the "Pay" and "Apply Credits" when the org context is "All Organizations"
        String sOrgContext = getActiveOrgId(pageContext);
        boolean bAllOrg = "-1".equals(sOrgContext);
        String paymentRegionLabel = (String)prms.get("PaymentApprovalRn");
        String approvalStatusColumn = (String)prms.get("ApprovalStatusColumn");
        String approveLabel = (String)prms.get("ApproveLabel");

        String sCustomerId = getActiveCustomerId(pageContext);
        String sCustomerSiteUseId = getActiveCustomerUseId(pageContext);
        String sCurrencyCode = (String)getActiveCurrencyCode(pageContext);

        boolean bAllCustomers =
            (null == sCustomerId) || "-1".equals(sCustomerId) ||
            "".equals(sCustomerId);

        // Bug # 3587177 - Added parameters to check payment method at customer level or site level
        Serializable[] param =
        { sCustomerId, sCustomerSiteUseId, sCurrencyCode };
        Class[] paramTypes =
        { java.lang.String.class, java.lang.String.class, java.lang.String.class };
        Boolean bValidPaymentSetup = Boolean.FALSE;

        //Check for Valid Payment Setup for Internal Users. Also for external users in context of single customer context
        if (isInternalCustomer(pageContext, webBean) ||
            (sCustomerId != null && !"-1".equals(sCustomerId)))
            bValidPaymentSetup =
                    (Boolean)pageContext.getRootApplicationModule().invokeMethod("isValidPaymentSetup",
                                                                                 param,
                                                                                 paramTypes);

        boolean bPayButtonDisplay =
            bValidPaymentSetup.booleanValue() && !bAllOrg && !bAllCustomers;

        OASelectionButtonBean payButton =
            (OASelectionButtonBean)webBean.findChildRecursive(payLabel);
        OASelectionButtonBean printButton =
            (OASelectionButtonBean)webBean.findChildRecursive(printLabel);
        OASelectionButtonBean applyCreditsButton =
            (OASelectionButtonBean)webBean.findChildRecursive(applyCreditsLabel);
        OASelectionButtonBean disputeButton =
            (OASelectionButtonBean)webBean.findChildRecursive(disputeLabel);

        if (payButton != null)
            payButton.setRendered(bPayButtonDisplay);

        //Bug 18601726
        boolean bDisputeButtonDisplay = false;
        if ("Y".equals(pageContext.getProfile("ARI_MULTIPLE_DISPUTE"))) {
            if (disputeButton != null) {
                if ((!bAllOrg && !bAllCustomers)) {
                    bDisputeButtonDisplay = true;
                    disputeButton.setRendered(bDisputeButtonDisplay);
                }

                else
                    disputeButton.setRendered(bDisputeButtonDisplay);
            }

        } else if (disputeButton != null)
            disputeButton.setRendered(bDisputeButtonDisplay);
        String pmtApproverStatus =
            pageContext.getProfile("OIR_PMT_APPROVER_STATUS");
        if (!(("PMT_APPROVER".equals(pmtApproverStatus)) ||
              "PMT_APPROVER_PAYER".equals(pmtApproverStatus)) ||
            getSearchStatus(pageContext, webBean).equals("CLOSED")) {
            OARowLayoutBean paymentApprovalRn =
                (OARowLayoutBean)webBean.findChildRecursive(paymentRegionLabel);
            if (paymentApprovalRn != null)
                paymentApprovalRn.setRendered(false);

        }

        if ("PMT_APPROVER".equals(pmtApproverStatus)) {
            if (payButton != null)
                payButton.setRendered(false);
            if (applyCreditsButton != null)
                applyCreditsButton.setRendered(false);
            //        if(disputeButton != null)              //commented for bug 12403921
            //          disputeButton.setRendered(false);
        }

        //For values NULL & DISABLED, the column should be hidden
        if (isNullString(pmtApproverStatus) ||
            "DISABLED".equals(pmtApproverStatus)) {
            OAColumnBean columnBean =
                (OAColumnBean)webBean.findChildRecursive(approvalStatusColumn);
            if (columnBean != null)
                columnBean.setRendered(false);
        } else {
            OAColumnBean columnBean =
                (OAColumnBean)webBean.findChildRecursive(approvalStatusColumn);
            if (columnBean != null)
                columnBean.setRendered(true);
        }

        // Set the 'Print' button rendering based on profile "OIR: Bill Presentment Architecture Enabled"
        String bpaPrintEnabled =
            pageContext.getProfile("OIR_INVOICE_BPA_ENABLED");
        if (bpaPrintEnabled == null || "".equals(bpaPrintEnabled))
            bpaPrintEnabled = "Y";
        if (!("Y".equals(bpaPrintEnabled)) && bAllOrg) {
            if (printButton != null)
                printButton.setRendered(false);
        }

        // Set the 'Apply Credits' button rendering based on profile "OIR: Apply Credits"
        if (!("Y".equals(pageContext.getProfile("OIR_APPLY_CREDITS"))) ||
            bAllOrg || bAllCustomers) {
            if (applyCreditsButton != null)
                applyCreditsButton.setRendered(false);
        }
        if (isRecordInTransactionList(pageContext)) {
            //Bug 4495150 - Hide table buttons, when records are added to Transaction List
            if (payButton != null)
                payButton.setRendered(false);
            if (printButton != null)
                printButton.setRendered(false);
            if (applyCreditsButton != null)
                applyCreditsButton.setRendered(false);

            if (disputeButton != null)
                disputeButton.setRendered(false);
        }
        if (getSearchStatus(pageContext, webBean).equals("CLOSED") &&
            (!"PMT".equals(region)) && (!"DISC_INV".equals(region))) {
            if (payButton != null)
                payButton.setRendered(false);
            if (applyCreditsButton != null)
                applyCreditsButton.setRendered(false); // Bug 10061489
        }


        //Pay button is always disabled when transaction type is Credit Memo OR Guarantee
        if ("CM".equals(region) || "GUAR".equals(region) ||
            "PMT".equals(region)) {
            if (payButton != null)
                payButton.setRendered(false);
            //Bug 18531298
            //if(printButton!=null)  printButton.setRendered(false);
        }
        if (pageContext.getSessionValue("ErrorExists") == "YES") {
            Class[] paramType =
            { java.lang.String.class, java.lang.String.class, Boolean.class,
              Boolean.class };
            OAApplicationModule am = pageContext.getApplicationModule(webBean);
            pageContext.putSessionValue("ErrorExists", "NO");
            OAColumnBean errorColumn =
                (OAColumnBean)webBean.findIndexedChildRecursive(errorColumnLabel);
            errorColumn.setRendered(true);
            OASwitcherBean icon =
                (OASwitcherBean)webBean.findIndexedChildRecursive(errorExistsLabel);
            icon.setRendered(true);
            // Validate again to show errors
            if (pageContext.getParameter(trxListLabel) != null) {
                Serializable[] params =
                { region, "ADD", Boolean.TRUE, Boolean.FALSE };
                Boolean valid =
                    (Boolean)am.invokeMethod("validateSelectedRecords", params,
                                             paramType);
            } else if (pageContext.getParameter(payLabel) != null) {
                Serializable[] params =
                { region, "PAY", Boolean.TRUE, Boolean.FALSE };
                Boolean valid =
                    (Boolean)am.invokeMethod("validateSelectedRecords", params,
                                             paramType);
            } else if (pageContext.getParameter(printLabel) != null) {
                Serializable[] params =
                { region, "PRINT", Boolean.TRUE, Boolean.FALSE };
                Boolean valid =
                    (Boolean)am.invokeMethod("validateSelectedRecords", params,
                                             paramType);
            } else if (pageContext.getParameter(applyCreditsLabel) != null) {
                Serializable[] params =
                { region, "APPLYCREDITS", Boolean.TRUE, Boolean.FALSE };
                Boolean valid =
                    (Boolean)am.invokeMethod("validateSelectedRecords", params,
                                             paramType);
            } else if (pageContext.getParameter(approveLabel) != null) {
                Serializable[] params =
                { region, "APPROVE", Boolean.TRUE, Boolean.FALSE };
                Boolean valid =
                    (Boolean)am.invokeMethod("validateSelectedRecords", params,
                                             paramType);
            } else if (pageContext.getParameter(disputeLabel) != null) {
                Serializable[] params =
                { region, "DISPUTE", Boolean.TRUE, Boolean.FALSE };
                Boolean valid =
                    (Boolean)am.invokeMethod("validateSelectedRecords", params,
                                             paramType);
            }
        }

        // runVOForResults(pageContext, webBean, region, param);

    }

    //Bug 4237309 - Apply Credits tab appears in AccountDetails page when profile option is NO

    protected void runVOForResults(OAPageContext pageContext,
                                   OAWebBean webBean, String region,
                                   Serializable[] params) {

        String requery = pageContext.getParameter("Requery");
        if (requery == null || "".equals(requery))
            requery = (String)pageContext.getSessionValue("Requery");

        /*String hideTrxTotalsRegion = (String)pageContext.getTransactionValue("HideTrxTotalsRegion");
    if("Y".equals(hideTrxTotalsRegion) && "N".equals(requery)) {
      OAWebBean srchDtlsReg = (OAWebBean)pageContext.getPageLayoutBean().findChildRecursive("SearchDtlRN");
      OAWebBean selTrxTotReg = (OAWebBean)pageContext.getPageLayoutBean().findChildRecursive("SelectedTrxTotalRN");
      srchDtlsReg.setRendered(false);
      selTrxTotReg.setRendered(false);
     }*/

        if ("N".equals(requery)) { // Bug  11871875
            pageContext.removeParameter("Requery");
            return;
        } else
            pageContext.putSessionValue("Requery", "N");

        if ("ALL_TRX".equals(region)) {
            runAcctDetailsQuery(pageContext, webBean, "TransactionTableVO");
            // Added 1 Line for CR619 (E2052):
            setColumnSoftHeaders(pageContext, webBean, "combTrxsortableHeader7",
                                 "combTrxcolumn7", "XXcomb");
        } else if ("CONS_INV".equals(region)) {
            runAcctDetailsQuery(pageContext, webBean, "ConsInvTableVO");
        } else if ("CM".equals(region)) {
            //Bug 14530418 - Removed Aging Bucket condition as aging is now supported for Credit Memos
            /*OAViewObject vo = (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("CMTableVO");
        if((getSearchStatus(pageContext, webBean)).startsWith("OIR_AGING_") == true)
        {
           vo.setMaxFetchSize(0);
           vo.setPreparedForExecution(false);
           OAMessageLayoutBean grandTotalRegion = (OAMessageLayoutBean)pageContext.getPageLayoutBean().findChildRecursive("GrandTotalsRegionLayout");
           OARowLayoutBean allBtnsRN = (OARowLayoutBean)pageContext.getPageLayoutBean().findChildRecursive("AllBtnsRN");
           if(grandTotalRegion!=null)
            grandTotalRegion.setRendered(false);
           if(allBtnsRN != null)
            allBtnsRN.setRendered(false);
        }
        else
         //Bug- 12677298- CREDIT MEMO AND RECEIPTS NOT LIMITED BY 'FND: VIEW OBJECT MAX FETCH'.
          String maxSize = pageContext.getProfile("VO_MAX_FETCH_SIZE");
          int voSize = -1;
          if(maxSize!=null)
            voSize = (Integer.valueOf(maxSize)).intValue();
          if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
            pageContext.writeDiagnostics(this, "fetch size: "+voSize, OAFwkConstants.STATEMENT);
          vo.setMaxFetchSize(voSize);*/
            runAcctDetailsQuery(pageContext, webBean, "CMTableVO");
            // Added 1 Line for CR619 (E2052):
            setColumnSoftHeaders(pageContext, webBean, "cmsortableHeader4", "cmcolumn4",
                                 "XXcm"); // Bushrod added for CR619
        } else if ("CUST_TRX".equals(region)) {
            OAViewObject vo =
                (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("CustomTrxSearchTableVO");
            vo.invokeMethod("executeQuery");
            setTotalsForDiscOrCustomSearch(pageContext, webBean, region,
                                           "CustomTrxSearchTableVO");
        } else if ("DM".equals(region)) {
            runAcctDetailsQuery(pageContext, webBean, "DMTableVO");
        } else if ("DEP".equals(region)) {
            runAcctDetailsQuery(pageContext, webBean, "DEPTableVO");
        } else if ("DISC_INV".equals(region)) {
            OAViewObject vo =
                (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("DiscountAlertsVO");
            vo.invokeMethod("initQuery", params);
            setTotalsForDiscOrCustomSearch(pageContext, webBean, region,
                                           "DiscountAlertsVO");
        } else if ("INV".equals(region)) {
            runAcctDetailsQuery(pageContext, webBean, "InvoiceTableVO");
            // Added 1 Line for CR619 (E2052):
            setColumnSoftHeaders(pageContext, webBean, "invsortableHeader6",
                                 "invcolumn6",
                                 "XXinv"); // Bushrod added for CR619
        } else if ("CB".equals(region)) {
            runAcctDetailsQuery(pageContext, webBean, "CBTableVO");
        } else if ("GUAR".equals(region)) {
            runAcctDetailsQuery(pageContext, webBean, "GuarTableVO");
        } else if ("ALL_DEBIT_TRX".equals(region)) {
            runAcctDetailsQuery(pageContext, webBean, "AllDebTrxTableVO");
            // Added 1 Line for CR619 (E2052):
            setColumnSoftHeaders(pageContext, webBean, "debTrxsortableHeader6",
                                 "debTrxcolumn6",
                                 "XXdeb"); // Bushrod added for CR619
        }
        // bug # 11871875
        else if ("CREDIT_REQUESTS".equals(region)) {
            runAcctDetailsQuery(pageContext, webBean, "RequestTableVO");
        } else if ("PAYMENTS".equals(region)) {
            runAcctDetailsQuery(pageContext, webBean, "PaymentVO");
        }

    }

    protected String getVONameForRegion(String region) {
        if ("ALL_TRX".equals(region)) {
            return ("TransactionTableVO");
        }
        if ("CONS_INV".equals(region)) {
            return ("ConsInvTableVO");
        } else if ("CM".equals(region)) {
            return ("CMTableVO");
        } else if ("CUST_TRX".equals(region)) {
            return ("CustomTrxSearchTableVO");
        } else if ("DM".equals(region)) {
            return ("DMTableVO");
        } else if ("DEP".equals(region)) {
            return ("DEPTableVO");
        } else if ("DISC_INV".equals(region)) {
            return ("DiscountAlertsVO");
        } else if ("INV".equals(region)) {
            return ("InvoiceTableVO");
        } else if ("CB".equals(region)) {
            return ("CBTableVO");
        } else if ("GUAR".equals(region)) {
            return ("GuarTableVO");
        } else if ("ALL_DEBIT_TRX".equals(region)) {
            return ("AllDebTrxTableVO");
        } else if ("PMT".equals(region)) {
            return ("PaymentVO");
        }

        else
            return null;
    }

    private void setTotalsForDiscOrCustomSearch(OAPageContext pageContext,
                                                OAWebBean webBean,
                                                String trxType,
                                                String viewName) {
        OAApplicationModule am = pageContext.getApplicationModule(webBean);
        am.invokeMethod("resetSelectAllTrxFlag");

        /** Commented  for Bug 18610451
    Serializable[] fetCntParams = {viewName} ;
    Number nTotalFetCnt = (Number) am.invokeMethod("setFetchedTrxTotalAndReturnCount",fetCntParams);
    int fetchTotalCnt = 0 ;
    if(nTotalFetCnt!=null)  fetchTotalCnt = nTotalFetCnt.intValue() ;

    if(fetchTotalCnt ==0)  // hide the fetched transactions summary region is fetch count is zero
    {
      OAWebBean srchDtlsReg = (OAWebBean)pageContext.getPageLayoutBean().findChildRecursive("SelectedTrxTotalsReg");
      srchDtlsReg.setRendered(false);

    }
      // hide the grand totals region for custom trx and discounts searches
      // this needs to be be changed to show grand totals for custom transactions search later
      OAWebBean srchDtlsReg = (OAWebBean)pageContext.getPageLayoutBean().findChildRecursive("SearchDtlRN");
      srchDtlsReg.setRendered(false);
      **/

        // Start - Added for Bug 18610451
        int cnt = 0;
        DiscountAlertsVORowImpl discRow = null;
        CustomTrxSearchTableVORowImpl custRow = null;
        Number amtDueOriginal = new Number(0);
        Number amtDueRemaining = new Number(0);
        //OAWebBean srchDtlsReg = (OAWebBean)pageContext.getPageLayoutBean().findChildRecursive("SearchDtlRN");
        OAMessageLayoutBean grandTotalRegion =
            (OAMessageLayoutBean)pageContext.getPageLayoutBean().findChildRecursive("GrandTotalsLayoutReg");
        OAMessageStyledTextBean gtOriginalAmtBean =
            (OAMessageStyledTextBean)pageContext.getPageLayoutBean().findChildRecursive("GTOriginalAmt");
        OAMessageStyledTextBean gtRemainingAmtBean =
            (OAMessageStyledTextBean)pageContext.getPageLayoutBean().findChildRecursive("GTRemainingAmt");
        String currencyCode = null;
        RowSetIterator iter =
            ((OAViewObject)pageContext.getApplicationModule(webBean).findViewObject(viewName)).createRowSetIterator("iter");
        iter.reset();
        try {
            Number currOriginalAmt = new Number(0);
            Number currRemainingAmt = new Number(0);
            if ("DISC_INV".equals(trxType)) {
                while (iter.hasNext()) {
                    discRow = (DiscountAlertsVORowImpl)iter.next();
                    currOriginalAmt = discRow.getAmountDueOriginal();
                    currRemainingAmt = discRow.getAmountDueRemaining();
                    amtDueOriginal = amtDueOriginal.add(currOriginalAmt);
                    amtDueRemaining = amtDueRemaining.add(currRemainingAmt);
                    cnt++;
                }
                if (discRow != null)
                    currencyCode = discRow.getInvoiceCurrencyCode();
            } else if ("CUST_TRX".equals(trxType)) {
                while (iter.hasNext()) {
                    custRow = (CustomTrxSearchTableVORowImpl)iter.next();
                    currOriginalAmt = custRow.getAmountDueOriginal();
                    currRemainingAmt = custRow.getAmountDueRemaining();
                    amtDueOriginal = amtDueOriginal.add(currOriginalAmt);
                    amtDueRemaining = amtDueRemaining.add(currRemainingAmt);
                    cnt++;
                }
                if (custRow != null)
                    currencyCode = custRow.getInvoiceCurrencyCode();
            }

            if (cnt > 0 && currencyCode != null) {
                String amtDueOriginalFormatted =
                    getFormattedAmount(pageContext, webBean, amtDueOriginal,
                                       currencyCode);
                String amtDueRemainingFormatted =
                    getFormattedAmount(pageContext, webBean, amtDueRemaining,
                                       currencyCode);

                if (gtOriginalAmtBean != null)
                    gtOriginalAmtBean.setValue(pageContext,
                                               amtDueOriginalFormatted);
                if (gtRemainingAmtBean != null)
                    gtRemainingAmtBean.setValue(pageContext,
                                                amtDueRemainingFormatted);
            } else {
                if (gtOriginalAmtBean != null)
                    gtOriginalAmtBean.setValue(pageContext, "");
                if (gtRemainingAmtBean != null)
                    gtRemainingAmtBean.setValue(pageContext, "");
            }
            iter.closeRowSetIterator();
        } catch (Exception e) {
            iter.closeRowSetIterator();
        }
        OAMessageStyledTextBean noOfTrx =
            (OAMessageStyledTextBean)pageContext.getPageLayoutBean().findChildRecursive("NoOfTrx");
        OAWebBean srchDtlsReg =
            (OAWebBean)pageContext.getPageLayoutBean().findChildRecursive("SearchDtlRN");
        OAMessageCheckBoxBean selAllFetBean =
            (OAMessageCheckBoxBean)(pageContext.getPageLayoutBean().findIndexedChildRecursive("SelectAllFetchedTrx"));
        String promptTxt = (String)selAllFetBean.getText(pageContext);
        promptTxt = promptTxt.substring(0, 10);
        if (cnt > 0) {
            promptTxt = promptTxt + " " + cnt;
            selAllFetBean.setText(pageContext, promptTxt);
            noOfTrx.setValue(pageContext, String.valueOf(cnt));
        } else {
            selAllFetBean.setText(pageContext, promptTxt);
            noOfTrx.setValue(pageContext, "");
        }

        // End - Added for Bug 18610451
    }

    /**
     * Procedure to set the input parameter for XDO REGION
     * @param pageContext the current OA page context
     * @param webBean the OAWebBean
     * @param trxType for specifying the Transaction Type
     * Bug # 5236417
     * Created By : ABHISJAI
     */
    public void setXDOParameters(OAPageContext pageContext, OAWebBean webBean,
                                 String trxType) {
        try {
            Class docHelper =
                (Class)Class.forName("oracle.apps.xdo.oa.common.DocumentHelper");
            Field sourceType = docHelper.getField("DATA_SOURCE_TYPE_BLOB");
            pageContext.putParameter("p_DataSource",
                                     DocumentHelper.DATA_SOURCE_TYPE_BLOB);
            if (null == trxType || "ALL_TRX".equals(trxType))
                pageContext.putParameter("p_DataSourceCode",
                                         "ARI_ALLTRX_SEARCH");
            else if ("CREDIT_MEMOS".equals(trxType))
                pageContext.putParameter("p_DataSourceCode", "ARI_CM_SEARCH");
            else if ("CREDIT_REQUESTS".equals(trxType))
                pageContext.putParameter("p_DataSourceCode",
                                         "ARI_CMREQ_SEARCH");
            else if ("DEBIT_MEMOS".equals(trxType))
                pageContext.putParameter("p_DataSourceCode", "ARI_DM_SEARCH");
            else if ("DEPOSITS".equals(trxType))
                pageContext.putParameter("p_DataSourceCode", "ARI_DEP_SEARCH");
            else if ("INVOICES".equals(trxType))
                pageContext.putParameter("p_DataSourceCode", "ARI_INV_SEARCH");
            else if ("PAYMENTS".equals(trxType))
                pageContext.putParameter("p_DataSourceCode", "ARI_PMT_SEARCH");
            else if ("DISC_INV".equals(trxType))
                pageContext.putParameter("p_DataSourceCode",
                                         "ARI_DISCINV_SEARCH");
            else if ("GUARANTEES".equals(trxType))
                pageContext.putParameter("p_DataSourceCode",
                                         "ARI_GUAR_SEARCH");
            else if ("CHARGEBACKS".equals(trxType))
                pageContext.putParameter("p_DataSourceCode", "ARI_CB_SEARCH");
            else if ("ALL_DEBIT_TRX".equals(trxType))
                pageContext.putParameter("p_DataSourceCode", "ARI_ADB_SEARCH");
            else
                pageContext.putParameter("p_DataSourceCode",
                                         "ARI_CUSTTRX_SEARCH");

            pageContext.putParameter("p_DataSourceAppsShortName", "AR");
            pageContext.putParameter("p_XDORegionHeight", "25%");
            //Bug # 8371146: Removed XDO related code
            String dataSourceCode =
                pageContext.getParameter("p_DataSourceCode");
            initalizeTemplateVOs(pageContext, webBean, dataSourceCode);

        } catch (Exception e) {
            throw OAException.wrapperException(e);
        }
    }

    /**
     * Procedure to get the XML as blob and setting the info in session
     * @param pageContext the current OA page context
     * @param webBean the OAWebBean
     * @param trxType for specifying the Transaction Type
     * Bug # 5236417
     * Created By : ABHISJAI
     * Updated Bug # 8371146
     */
    public

    void setXMLData(OAPageContext pageContext, OAWebBean webBean,
                    String trxType) {
        OAApplicationModule am =
            pageContext.getRootApplicationModule(); //getApplicationModule(webBean);
        OADBTransaction trx = am.getOADBTransaction();
        trx.putValue("trxType", trxType);
        String exportButton = pageContext.getParameter("XDOExportResults");
        String templateCode = pageContext.getParameter("TemplateCode");
        String customerId = getActiveCustomerId(pageContext);

        // Bug 14823754 - Added for Download XML button event
        String pageEvent = pageContext.getParameter("event");
        if ("downloadXML".equals(pageEvent)) {
            if (customerId != null && !"-1".equals(customerId) &&
                !"".equals(customerId))
                downloadXMLFile(pageContext, webBean, "AR", templateCode);
            else
                throw new OAException("AR", "ARI_SELECT_CUST_FOR_STMT");
        }

        if (exportButton != null) {
            //Bug #12400817- Commented the below line and added steps below it for displaying error msg when All customer
            // Accounts is being chosen and export button is being clicked
            //exportXDOData(pageContext, webBean, "AR", templateCode);
            if (customerId != null && !"-1".equals(customerId) &&
                !"".equals(customerId))
                exportXDOData(pageContext, webBean, "AR", templateCode);
            else
                throw new OAException("AR", "ARI_SELECT_CUST_FOR_STMT");
        }
    }


    public boolean isPaymentVO() {
        return false;
    }

    protected void recalculateSelectedTrxTotals(OAPageContext pageContext,
                                                OAWebBean webBean,
                                                String region) {
        String sViewObjectName = getVONameForRegion(region);
        Serializable[] fetCntParams = { sViewObjectName };

        OAApplicationModule am = pageContext.getRootApplicationModule();
        Number nTotalFetCnt =
            (Number)am.invokeMethod("setFetchedTrxTotalAndReturnCount",
                                    fetCntParams);
    }


    protected void SelectAllFetchedTrxChanged(OAPageContext pageContext,
                                              OAWebBean webBean,
                                              String region) {
        String sViewObjectName = getVONameForRegion(region);
        Serializable[] fetCntParams = { sViewObjectName };

        OAApplicationModule am = pageContext.getRootApplicationModule();
        Number nTotalFetCnt =
            (Number)am.invokeMethod("handleSelectAllFetchedTrxChanged",
                                    fetCntParams);
    }


    /**
     * Procedure to render different buttons depending on the Transaction Type
     * @param pageContext the current OA page context
     * @param webBean the OAWebBean
     * @param trxType for specifying the Transaction Type
     * Bug # 5236417
     * Created By : ABHISJAI
     */
    public

    void displayButtonAndSetVOResults(OAPageContext pageContext,
                                      OAWebBean webBean, String trxType) {

        HashMap prms = new HashMap(10);
        setXDOParameters(pageContext, webBean, trxType);

        if ("INVOICES".equals(trxType)) {
            prms.put("TransactionList", "invTransactionList");
            prms.put("Pay", "invPay");
            prms.put("Dispute", "invDispute");
            prms.put("Print", "invPrint");
            prms.put("ApplyCredits", "invApplyCredits");
            prms.put("errorColumn", "invcolumn1");
            prms.put("ErrorExists", "InvErrorExists");
            prms.put("PaymentApprovalRn", "invPaymentApproval");
            prms.put("ApprovalStatusColumn", "invApprovalStatusCol");
            prms.put("ApproveLabel", "approveButton");

            prms.put("CustomerNumber", "invcustnumcolumn");
            prms.put("CustomerName", "invcustnamecolumn");

            displaySelectionButtons(pageContext, webBean, "INV", prms);

            runVOForResults(pageContext, webBean, "INV", null);
        } else if ("CONSOLIDATEDINVOICES".equals(trxType)) {
            prms.put("TransactionList", "consInvTransactionList");
            prms.put("Pay", "consInvPay");
            prms.put("Dispute", "consInvDispute");
            prms.put("Print", "consInvPrint");
            prms.put("ApplyCredits", "consInvApplyCredits");
            prms.put("errorColumn", "consInvcolumn1");
            prms.put("ErrorExists", "consInvErrorExists");
            prms.put("PaymentApprovalRn", "consInvPaymentApproval");
            prms.put("ApprovalStatusColumn", "IrConsInvApprovalStatusCol");
            prms.put("ApproveLabel", "approveButton");

            prms.put("CustomerNumber", "consInvcustnumcolumn");
            prms.put("CustomerName", "consInvcustnamecolumn");

            displaySelectionButtons(pageContext, webBean, "CONS_INV", prms);
            runVOForResults(pageContext, webBean, "CONS_INV", null);
        } else if ("GUARANTEES".equals(trxType)) {
            prms.put("TransactionList", "guarTransactionList");
            prms.put("Pay", "guarPay");
            prms.put("Dispute", "guarDispute");
            prms.put("Print", "guarPrint");
            prms.put("ApplyCredits", "guarApplyCredits");
            prms.put("errorColumn", "guarcolumn1");
            prms.put("ErrorExists", "guarErrorExists");
            prms.put("PaymentApprovalRn", "guarPaymentApproval");
            prms.put("ApprovalStatusColumn", "guarApprovalStatusCol");

            prms.put("CustomerNumber", "guarcustnumcolumn");
            prms.put("CustomerName", "guarcustnamecolumn");

            displaySelectionButtons(pageContext, webBean, "GUAR", prms);
            runVOForResults(pageContext, webBean, "GUAR", null);

        } else if ("CHARGEBACKS".equals(trxType)) {
            prms.put("TransactionList", "cbTransactionList");
            prms.put("Pay", "cbPay");
            prms.put("Print", "cbPrint");
            prms.put("ApplyCredits", "cbApplyCredits");
            prms.put("Dispute", "cbDispute");
            prms.put("errorColumn", "cbcolumn1");
            prms.put("ErrorExists", "cbErrorExists");
            prms.put("PaymentApprovalRn", "cbPaymentApproval");
            prms.put("ApprovalStatusColumn", "cbApprovalStatusCol");
            // Bug 13602291 - During mulitple transaction disputes, negative transactions are not properly handled.

            prms.put("ApproveLabel", "approveButton");
            prms.put("CustomerNumber", "cbcustnumcolumn");
            prms.put("CustomerName", "cbcustnamecolumn");

            displaySelectionButtons(pageContext, webBean, "CB", prms);
            runVOForResults(pageContext, webBean, "CB", null);

        } else if ("PAYMENTS".equals(trxType)) {
            prms.put("TransactionList", "pmtTransactionList");
            prms.put("Pay", "pmtPay");
            prms.put("Print", "pmtPrint");
            prms.put("ApplyCredits", "pmtApplyCredits");
            prms.put("errorColumn", "pmtErrorCol");
            prms.put("ErrorExists", "pmtErrorExists");

            prms.put("CustomerNumber", "pmtcustnumcolumn");
            prms.put("CustomerName", "pmtcustnamecolumn");

            displaySelectionButtons(pageContext, webBean, "PMT", prms);

        } else if ("DEPOSITS".equals(trxType)) {
            prms.put("TransactionList", "depTransactionList");
            prms.put("Pay", "depPay");
            prms.put("Dispute", "depDispute");
            prms.put("Print", "depPrint");
            prms.put("ApplyCredits", "depApplyCredits");
            prms.put("errorColumn", "depcolumn1");
            prms.put("ErrorExists", "DepErrorExists");
            prms.put("PaymentApprovalRn", "depPaymentApproval");
            prms.put("ApprovalStatusColumn", "IrDepApprovalStatusCol");

            prms.put("CustomerNumber", "depcustnumcolumn");
            prms.put("CustomerName", "depcustnamecolumn");

            displaySelectionButtons(pageContext, webBean, "DEP", prms);
            runVOForResults(pageContext, webBean, "DEP", null);
        } else if ("ALL_DEBIT_TRX".equals(trxType)) {
            prms.put("TransactionList", "debTrxTransactionList");
            prms.put("Pay", "debTrxPay");
            prms.put("Dispute", "debTrxDispute");
            prms.put("Print", "debTrxPrint");
            prms.put("ApplyCredits", "debTrxApplyCredits");
            prms.put("errorColumn", "debTrxcolumn1");
            prms.put("ErrorExists", "debTrxErrorExists");
            prms.put("PaymentApprovalRn", "debTrxPaymentApproval");
            prms.put("ApprovalStatusColumn", "debApprovalStatusCol");
            prms.put("ApproveLabel", "approveButton");

            prms.put("CustomerNumber", "debcustnumcolumn");
            prms.put("CustomerName", "debcustnamecolumn");

            displaySelectionButtons(pageContext, webBean, "ALL_DEBIT_TRX",
                                    prms);
            runVOForResults(pageContext, webBean, "ALL_DEBIT_TRX", null);
        } else if ("CREDIT_MEMOS".equals(trxType)) {
            prms.put("TransactionList", "cmTransactionList");
            prms.put("Pay", "cmPay");
            prms.put("Print", "cmPrint");
            prms.put("ApplyCredits", "cmApplyCredits");
            prms.put("errorColumn", "cmcolumn1");
            prms.put("ErrorExists", "CmErrorExists");
            prms.put("PaymentApprovalRn", "cmPaymentApproval");
            prms.put("ApprovalStatusColumn", "cmApprovalStatusCol");

            prms.put("CustomerNumber", "cmcustnumcolumn");
            prms.put("CustomerName", "cmcustnamecolumn");

            displaySelectionButtons(pageContext, webBean, "CM", prms);
            runVOForResults(pageContext, webBean, "CM", null);
        } else if (null == trxType || "ALL_TRX".equals(trxType)) {
            prms.put("TransactionList", "TransactionList");
            prms.put("Pay", "Pay");
            prms.put("Dispute", "Dispute");
            prms.put("Print", "Print");
            prms.put("ApplyCredits", "ApplyCredits");
            prms.put("errorColumn", "combTrxcolumn1");
            prms.put("ErrorExists", "ErrorExists");
            prms.put("PaymentApprovalRn", "combPaymentApproval");
            prms.put("ApprovalStatusColumn", "IrCombApprovalStatusCol");
            prms.put("ApproveLabel", "approveButton");

            prms.put("CustomerNumber", "combcustnumcolumn");
            prms.put("CustomerName", "combcustnamecolumn");

            displaySelectionButtons(pageContext, webBean, "ALL_TRX", prms);
            runVOForResults(pageContext, webBean, "ALL_TRX", null);
        } else if ("DEBIT_MEMOS".equals(trxType)) {
            prms.put("TransactionList", "dmTransactionList");
            prms.put("Pay", "dmPay");
            prms.put("Print", "dmPrint");
            prms.put("ApplyCredits", "dmApplyCredits");
            prms.put("Dispute", "dmDispute");
            prms.put("errorColumn", "dmcolumn1");
            prms.put("ErrorExists", "DmErrorExists");
            prms.put("PaymentApprovalRn", "dmPaymentApproval");
            prms.put("ApprovalStatusColumn", "dmApprovalStatusCol");
            // Bug 13602291 - During mulitple transaction disputes, negative transactions are not properly handled.
            prms.put("ApproveLabel", "approveButton");
            prms.put("CustomerNumber", "dmcustnumcolumn");
            prms.put("CustomerName", "dmcustnamecolumn");

            displaySelectionButtons(pageContext, webBean, "DM", prms);
            runVOForResults(pageContext, webBean, "DM", null);
        } else if ("DISC_INV".equals(trxType)) {
            prms.put("TransactionList", "discInvTransactionList");
            prms.put("Pay", "discInvPay");
            prms.put("Dispute", "discInvDispute");
            prms.put("Print", "discInvPrint");
            prms.put("ApplyCredits", "discApplyCredits");
            prms.put("errorColumn", "discinv_ErrorCol");
            prms.put("ErrorExists", "DiscInvErrorExists");
            prms.put("PaymentApprovalRn", "discInvPaymentApproval");
            prms.put("ApprovalStatusColumn", "discinvApprovalStatusCol");

            prms.put("CustomerNumber", "discinvcustnumcolumn");
            prms.put("CustomerName", "discinvcustnamecolumn");

            displaySelectionButtons(pageContext, webBean, "DISC_INV", prms);

            String sCustomerId = getActiveCustomerId(pageContext);
            String sCustomerSiteUseId = getActiveCustomerUseId(pageContext);
            String sCurrencyCode = (String)getActiveCurrencyCode(pageContext);
            String discFilterValue =
                (String)pageContext.getParameter("IrDiscountFilter");
            Serializable[] param =
            { sCurrencyCode, sCustomerId, sCustomerSiteUseId,
              discFilterValue };
            runVOForResults(pageContext, webBean, "DISC_INV", param);
        } else if ("CUST_TRX".equals(trxType)) {
            prms.put("TransactionList", "CustTrxTransactionList");
            prms.put("Pay", "CustTrxPay");
            prms.put("Dispute", "CustTrxDispute");
            prms.put("Print", "CustTrxPrint");
            prms.put("ApplyCredits", "CustApplyCredits");
            prms.put("errorColumn", "CustTrxErrorCol");
            prms.put("ErrorExists", "CustTrxErrorExists");
            prms.put("PaymentApprovalRn", "custPaymentApproval");
            prms.put("ApprovalStatusColumn", "CustomApprovalStatusCol");
            prms.put("ApproveLabel", "approveButton");

            prms.put("CustomerNumber", "custtrxcustnumcolumn");
            prms.put("CustomerName", "custtrxcustnamecolumn");

            displaySelectionButtons(pageContext, webBean, "CUST_TRX", prms);
            runVOForResults(pageContext, webBean, "CUST_TRX", null);

        } else {
            prms.put("TransactionList", "CustTrxTransactionList");
            prms.put("Pay", "CustTrxPay");
            prms.put("Dispute", "CustTrxDispute");
            prms.put("Print", "CustTrxPrint");
            prms.put("ApplyCredits", "CustApplyCredits");
            prms.put("errorColumn", "CustTrxErrorCol");
            prms.put("ErrorExists", "CustTrxErrorExists");
            prms.put("PaymentApprovalRn", "custPaymentApproval");
            prms.put("ApprovalStatusColumn", "CustomApprovalStatusCol");
            prms.put("ApproveLabel", "approveButton");

            prms.put("CustomerNumber", "TrxListCustNumColumn");
            prms.put("CustomerName", "TrxListCustNameColumn");

            displaySelectionButtons(pageContext, webBean, "CUST_TRX", prms);
            runVOForResults(pageContext, webBean, "CUST_TRX", null);
        }
    }
    
    //Bug-20524609:Added below method for bug#20524609
      public void setSkipFormDataForTable(OAPageContext pageContext,OAWebBean webBean,String printParam,String tableId)
      {
        //Bug-20524609:start -Added below code
          if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
            pageContext.writeDiagnostics(this, "setSkipFormDataForTable+", OAFwkConstants.PROCEDURE);
        
          String printBPA=(String)pageContext.getTransactionValue(printParam);
          if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
          pageContext.writeDiagnostics(this, "printBPA-----"+printBPA, OAFwkConstants.PROCEDURE);
          OAAdvancedTableBean  tableBean=(OAAdvancedTableBean)webBean.findIndexedChildRecursive(tableId);
          if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
          pageContext.writeDiagnostics(this, "tableBean-----"+tableBean, OAFwkConstants.PROCEDURE);
          if(tableBean!=null)
          {
          if("Y".equals(printBPA))
          { 
            if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
            pageContext.writeDiagnostics(this, "Setting the Table skipProcessFormData property to true+", OAFwkConstants.PROCEDURE);
            tableBean.setSkipProcessFormData(pageContext, true);
          }
          else
          {
            if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
            pageContext.writeDiagnostics(this, "Setting the Table skipProcessFormData property to fasle+", OAFwkConstants.PROCEDURE);
            tableBean.setSkipProcessFormData(pageContext, false);
          }
          }   
          pageContext.removeTransactionValue(printParam);
          //Bug-20524609:End
      }

  /**
  * this creates the variable to bind to for the bind variable
  * equated to 'status' in the query statement
  */
  protected String statusForWhereClause(String StrTrxStatus)
  {
    String status = new String ("");
    if (null != StrTrxStatus)
    {
      if (StrTrxStatus.equals("CLOSED"))
          {status = "CL";}
      else if (StrTrxStatus.equals("OPEN"))
          {status = "OP";}
      else if (StrTrxStatus.equals("PAST_DUE_INVOICE"))
          {status = "OP";}
    }
    return status;
  }
}
