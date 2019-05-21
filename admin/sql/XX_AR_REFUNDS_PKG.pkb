
	SET SHOW OFF		
	SET VERIFY OFF		
	SET ECHO OFF		
	SET TAB OFF		
	SET FEEDBACK OFF		
	SET TERM ON		
			
	prompt creating package body xx_ar_refunds_pkg	
	
	PROMPT Program exits if the creation is not successful		
	REM Added for ARU db drv auto generation		
	REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \		
	REM dbdrv: checkfile:~PROD:~PATH:~FILE		
			
	WHENEVER OSERROR EXIT FAILURE ROLLBACK;		
	WHENEVER SQLERROR EXIT FAILURE ROLLBACK;		
			
CREATE OR REPLACE PACKAGE BODY xx_ar_refunds_pkg
AS
-- =========================================================================================================================
--   NAME:       XX_AR_REFUNDS_PKG .
--   PURPOSE:    This package contains procedures and functions for the
--                AR Automated Refund process.
--   REVISIONS:
--   Ver        Date        Author           Description
--   ---------  ----------  ---------------  -------------------------------------------------------------------------------
--   1.0        04/04/2007  Deepak Gowda      1. Created this package.
--   1.1        10/11/2007  Arul Justin Raj   Fix for Defect 2313
--                                            Overload the function derive_company_from
--                                            _location with the parameter ORG_ID
--   1.2        10/12/2007  Deepak Gowda      Fix for Defect 2418
--                                            Use Pay Group US_OD_EXP_NON_DISC for
--                                            all operating units.
--                                            Fix for Defect 2441
--                                            Use Invoice Source 'US_OD_AR_REFUND' for
--                                            all operating units
--   1.3       11/14/2007  Deepak Gowda       Added P_ORG_ID parameter to Identify proc.
--   1.4       12/18/2007  Deepak Gowda       Performance tuning update in Identify Process
--                                            Added Get primary bill to address in procedure.
--   1.5       01/09/2008  Deepak Gowda       Defect 2671: Use country when creating suppluer site.
--                                            Updated to use AP_VENDORS_V and AP_VENDOR_SITES_V
--                                            instead of PO_VENDORS_ALL and PO_VENDOR_SITES_ALL
--                                            when looking up Vendors and Sites
--   1.6       01/16/2008  Deepak Gowda       Use Invoice Source 'US_OD_RETAIL_REFUND' for
--                                            Store Mail Check refunds.
--   1.7       03/19/2008  Deepak Gowda       Defect 4381 Run Payables Open Interface Import for
--                                            Invoice Source 'US_OD_RETAIL_REFUND'
--   1.8       06/23/2008  Brian J Looman     Performance changes (defects 8298, 8301)
--   1.9       07/09/2008  Brian J Looman     More Performance changes (defects 7743 and 8298)
--   2.0       07/17/2008  Sandeep Pandhare   Defect 9063
--   2.1       08/20/2008  Brian J Looman     Defect 10112, when p_only_pre_selected = "N", then
--                                            conditions should not be used.
--   2.2       09/12/2008  Brian J Looman     Defect 11109 - use store_customer_name for payee
--   2.3       09/22/2008  Brian J Looman     Defect 11452 (redo changes for defect 10112)
--   2.4       09/25/2008  Brian J Looman     Defects 11485 and 11486
--   2.5       05/20/2009  Anitha Devarajulu  Defect 15220
--   2.6       12/16/2009  Mohammed Appas     Defect 3516
--   2.9       12/21/2009  Ganga Devi R       Modified AP check description format for R1.2 CR 714(Defect# 2532)
--   2.7       12/25/2009  RamyaPriya         Modified for the Defect 3340
--   2.8       12/28/2009  RamyaPriya         Modified for the Defect #3340
--                                            (Changed Translation to Lookup)
--   3.0       01/04/2010  Bhuvaneswary S     Updated for CR 697/698 R1.2 and merged code for defect 3516,3340 with 2532
--   3.1       03/19/2010  Usha R             Modified the code for defect 4901
--   3.2       04/05/2010  Usha R             Modified the code for defect 4901
--   3.3       04/07/2010  Ganga Devi R       Modified for R1.3 CR# 544 Defect#1253
--                                            and merged code fix for defect#4348 done by Usha
--   3.4       13/05/2010  Rama Krishna K     Modified the code for defect 5755 to take UNAPP and UNIDENTIFIED trxn's
--   3.5       17/05/2010  Rama Krishna K     Modified the code for defect 5755 to have both Refunds and Escheats
--                                            identify same set of data with the same Inactive Date
--   3.6       17/06/2010  Ganga Devi R       Modified INSERT_SUPPLIER_SITE_INT procedure for defect# 6311
--   3.7       07/10/2010  RamyaPriya M       Modified for the defect #8300
--                                            To restrict DFF update when the receipt is in processed status
--   3.8       11/09/2010  Venkatesh B        Modified the procedure "create_refund" to fetch the data according to the user Id for the defect #8304
--   4.0       04/07/2011  Jay Gupta          (Oracle) Modified for SDR Project
--   5.0       04/18/2011  Gaurav Agarwal     (Oracle) Modified for SDR Project - Accounting entreis for AP line
--   5.1       05/31/2011  Gaurav Agarwal     (Oracle) Modified for SDR Project - Added substr for city and AP invoice number.
--   5.2       06/10/2011  Jay Gupta          (Oracle) Modified for SDR Project - Added condition for supplier site
--   5.3       06/21/2011  Gaurav Agarwal     (Oracle) Modified for SDR Project - ln_vendor_site_id := NULL ; -- variable initialize added
--                                            Defect 12210  Mailchecks are failing on invalid supplier site
--                                            Defect 12225  SALES ACCOUNTING - INTERNAL MAILCHECK SUPPLIER PAYGROUP shd be US_OD_CLEARING_TREASURY
--   5.4       06/29/2011  Gaurav Agarwal     (Oracle) Modified for SDR Project -
--                                            For Internal Supplier Mailcheck vendor site code is changed as defined in PROD.
--   5.5       09/09/2011  Sachin R Patil     Updating the last_update_date and last_updated_by columns of tables ar_cash_receipts_all
--                                            and ra_customer_trx_all whenever attribute9 and attribute10 are getting updated Defect #13458
--   5.6       07/24/2012  Rohit Ranjan       Defect#17965 (Previously declined escheatment requests preventing new escheat request on transactions)
--   5.7       09/27/2012  Abdul Khan         Code fix done to fix performnace issue report while executing OD: Refunds - Identify AR Refunds program
--                                            when PreSelected Trx = N is passed as parameter. QC Defect 17501
--   5.8       08/13/2013  Deepak V           E0055 - Changes made for R12 retrofit. The payables open interface and supplier open interface has a additional
--                                            parameter for operating unit in R12, that have now been added.
--   5.9       18/07/2013  Ankit Arora        Code changes for QC Defect 22806 , Added as part of R12 retrofit.
--   5.10      11/11/2013  Deepak V           E0055 - Supplier open Interface and supllier site open interface call has been changed. Qc Defect - 26375 and 26024.
--   6.0       23/05/2014  Veronica Mairembam Code changes for QC Defect #28951, to include the changes for 11i defect #27439
--   6.1       05/28/2014  Paddy Sanjeevi     Defect 30123
--   6.2       15/12/2015  Ravi Palikala	  Modified for the defect#34346 to include the column vendor_site_interface_id in the insert statement
--   6.3       27/10/2015  Vasu Raparla	      Removed Schema References for R12.2 
--	 6.4	   01/09/2016  Rakesh Polepalli   Modified for the Defect# 36803
--	 6.5	   03/10/2016  Rakesh Polepalli   Modified for the Defect# 37226
--   6.6       01/08/2019  Shanti Sethuraj    Changing supplier site category code from EX to EX-REF for the jira # NAIT-65243 
--   6.7       20/05/2019  Satheesh Suthari   Adding org_id condition at attribute10 & attribute9 for ra_customer_trx_all table, defect# 89061
-- =========================================================================================================================
-------------------------------------------------
   --Start of changes for Defect #3340
-------------------------------------------------
    TYPE receipt_writeoff_record IS RECORD(
        receipt_number        VARCHAR2(30),
        receipt_date          VARCHAR2(240),
        store_number          VARCHAR2(100),
        refund_amount         NUMBER,
        currency              VARCHAR2(15),
        account_dr            VARCHAR2(240),
        account_cr            VARCHAR2(240),
        description           VARCHAR2(240)                                                     --Added for defect 4348
                                           ,
        account_seg_dr        VARCHAR2(25)                --Added for defect 4348     -- Modified for 4348 on 4/29/2010
                                          ,
        account_seg_cr        VARCHAR2(25)                                         --Added for defect 4348 on 4/29/2010
                                          ,
        location_dr           VARCHAR2(25)                                         --Added for defect 4348 on 4/29/2010
                                          ,
        location_cr           VARCHAR2(25)                                         --Added for defect 4348 on 4/29/2010
                                          ,
        meaning_debit         VARCHAR2(240)                                                     --Added for defect 4348
                                           ,
        meaning_credit        VARCHAR2(240)                                                     --Added for defect 4348
                                           ,
        location_description  VARCHAR2(240)                                                     --Added for defect 4348
    );

    TYPE receipt_writeoff_type IS TABLE OF receipt_writeoff_record
        INDEX BY BINARY_INTEGER;

    gt_receipt_writeoff      receipt_writeoff_type;
    gn_count                 NUMBER                := 1;
    gn_tot_receipt_writeoff  NUMBER                := 0;
    gn_cust_id               NUMBER;
    gn_check                 NUMBER;

-------------------------------------------------
   --End of changes for Defect #3340
-------------------------------------------------
    PROCEDURE od_message(
        p_msg_type        IN  VARCHAR2,
        p_msg             IN  VARCHAR2,
        p_msg_loc         IN  VARCHAR2 DEFAULT NULL,
        p_addnl_line_len  IN  NUMBER DEFAULT 110);

    PROCEDURE identify_refund_trx(
        errbuf               OUT NOCOPY     VARCHAR2,
        retcode              OUT NOCOPY     VARCHAR2,
        p_trx_date_from      IN             VARCHAR2,
        p_trx_date_to        IN             VARCHAR2,
        p_amount_from        IN             NUMBER DEFAULT 0.000001,
        p_amount_to          IN             NUMBER DEFAULT 9999999999999,
        p_no_activity_in     IN             NUMBER                                                          --# OF DAYS.
                                                  ,
        p_only_pre_selected  IN             VARCHAR2                                                              --Y/N.
                                                    ,
        p_process_type       IN             VARCHAR2                                                --ESCHEAT/OM/OTHERS.
                                                    ,
        p_only_for_user_id   IN             NUMBER DEFAULT NULL,
        p_org_id             IN             VARCHAR2,
        p_limit_size         IN             NUMBER)                                 --Added for defect 4901 on 05=APR-10
    IS
-- Commented for QC Defect 17501 - Start
--      CURSOR id_refund_trx_ar (
--         i_trx_date_from IN DATE
--       , i_trx_date_to IN DATE
--       , p_escheat_inact_days IN NUMBER
--       , p_refund_inact_days IN NUMBER
--      )                                                                                                                                                -- Added for CR 697/698 R1.2
--      IS
--         SELECT   SOURCE
--                , customer_id
--                , NULL customer_number
--                , NULL party_name
--                , NULL aops_customer_number
--                , cash_receipt_id
--                , customer_trx_id
--                , trx_id
--                , CLASS
--                , trx_number
--                , trx_date
--                , invoice_currency_code
--                , amount_due_remaining
--                , aps_last_update_date
--                , pre_selected_flag
--                , refund_request
--                , refund_status
--                , org_id
--                , location_id
--                , address1
--                , address2
--                , address3
--                , city
--                , state
--                , province
--                , postal_code
--                , country
--                , om_hold_status
--                , om_delete_status
--                , om_store_number
--                , store_customer_name
--                , 0 ref_mailcheck_id                                                                                                                     -- added by gaurav for v5.0
--             --FROM xx_ar_refund_trx_id_v xatv            --Commented for defect 4901
--         FROM     xx_ar_open_credits_itm xatv                                                                                                          --Added for defect 4901
--            WHERE org_id = p_org_id
--              AND (   refund_status IS NULL
--                   OR refund_status = 'Declined')
--              AND amount_due_remaining BETWEEN NVL (-1 * p_amount_to, -9999999999999) AND NVL (-1 * p_amount_from, -0.000001)
--              AND trx_date BETWEEN NVL (i_trx_date_from, trx_date) AND NVL (i_trx_date_to, trx_date)
--              AND (   (    NVL (p_only_pre_selected, 'N') = 'Y'
--                       AND refund_request IN ('Send Refund', 'Send Refund Alt'))
--                   OR (NVL (p_only_pre_selected, 'N') = 'N'))
--               -- defect 10112, BLooman 08/21/08, should not have conditions if p_only_pre_selected is not Y
--               --       AND refund_request IS NULL ) )
--              -- AND cash_receipt_status = 'UNAPP'   -- which excludes UNID ---Commented out for Defect 5755
--              AND cash_receipt_status IN ('UNAPP', 'UNID')                                                                                      -- Added by Rama Krishna K for V 3.4
--              AND (   refund_request IN ('Send Refund', 'Send Refund Alt')
--                   OR (    refund_request IS NULL
--                            -- Modified the below check_cust to include cash_receipt_id as IN parameter by Rama Krishna K
--                       -- on 5/16 to handle UNIDENTIFIED Transaction scenario
--                       AND check_cust (p_no_activity_in, p_refund_inact_days, xatv.customer_id, xatv.cash_receipt_id) = 0                                    --Added for defect 4901
--                                                                                                                                  /*AND (aps_last_update_date <=
--                                                                                                                                         (SELECT MAX (aps2.last_update_date)
--                                                                                                                                            FROM ar_payment_schedules_all aps2
--                                                                                                                                           WHERE org_id = xatv.org_id
--                                                                                                                                             AND customer_id = xatv.customer_id
--                                                                                                                                             AND aps2.last_update_date <
--                                                                                                                                                 (SYSDATE-NVL(p_no_activity_in,120) ) ) ) ) )*/  -- Commented for CR 697/698 R1.2
--                                                                                                                         --          ) )  commented by ranjith--AND aps_last_update_date >= (SYSDATE - 730);     -- Commented for CR 697/698 R1.2
--                                                                                                                                     /*AND NOT EXISTS (  SELECT amount_due_remaining
--                                                                                                                                                         FROM ar_payment_schedules_all APS
--                                                                                                                                                          WHERE xaoti.customer_id = xatv.customer_id
--                                                                                                                                                          AND xaoti.amount_due_remaining > 0
--                                                                                                                                                        )
--                                                                                                                                      AND NOT EXISTS   (
--                                                                                                                                                         SELECT 1
--                                                                                                                                                         FROM ra_customer_trx_all RCT
--                                                                                                                                                         WHERE RCT.bill_to_customer_id = xatv.customer_id
--                                                                                                                                                                           AND RCT.trx_date >= (SYSDATE-NVL(p_no_activity_in,p_refund_inact_days) )
--                                                                                                                                                       )
--                                                                                                                                      AND NOT EXISTS   (
--                                                                                                                                                       SELECT 1
--                                                                                                                                                        FROM ar_payment_schedules_all aps,
--                                                                                                                                                             ar_receivable_applications_all ara
--                                                                                                                                                        WHERE ara.cash_receipt_id = aps.cash_receipt_id
--                                                                                                                                                        AND   aps.customer_id =  xatv.customer_id
--                                                                                                                                                        AND   ara.applied_customer_trx_id IS NOT NULL
--                                                                                                                                                                                AND   ara.status = 'APP'
--                                                                                                                                                        AND   (ara.apply_date >= (SYSDATE-NVL(p_no_activity_in,p_refund_inact_days) ))
--                                                                                                                                                        )
--                                                                                                                                       AND NOT EXISTS (
--                                                                                                                                                       SELECT 1
--                                                                                                                                                       FROM ar_receivable_applications_all ara
--                                                                                                                                                           ,ra_customer_trx_all rct
--                                                                                                                                                       WHERE rct.customer_trx_id = ara.applied_customer_trx_id
--                                                                                                                                                       AND   rct.bill_to_customer_id = XATV.customer_id
--                                                                                                                                                       AND   (ara.apply_date >= (SYSDATE-NVL(p_no_activity_in,p_refund_inact_days) ))
--                                                                                                                                                       AND   ara.status <> 'ACTIVITY'
--                                                                                                                                                       )
--                                                                                                                                       AND NOT EXISTS  (
--                                                                                                                                                        SELECT 1 FROM ar_cash_receipts_all acra
--                                                                                                                                                        WHERE acra.receipt_date  >= (SYSDATE-NVL(p_no_activity_in,p_refund_inact_days) )
--                                                                                                                                                        AND   acra.pay_from_customer = XATV.customer_id
--                                                                                                                                                        )*/
--                      )
--                  )
--            -- Commented out the below condition due to 2 reasons by Rama Krishna K on 5/17 for V 3.5
--         -- 1. We are already taking of verifying this check with transaction number in check_cust function and is redundant
--         -- 2. This is causing inconsistency in results for both Refunds and Escheats for the same inactive date
--              -- AND aps_last_update_date > (SYSDATE - p_escheat_inact_days)-- Added for CR 697/698 R1.2
--         ORDER BY customer_id                                                                                                                               -- Added for defect 4901
--                             ;
-- Commented for QC Defect 17501 - End

        -- Added for QC Defect 17501 - Start
        CURSOR id_refund_trx_ar                                                            -- Added for CR 697/698 R1.2
        IS
            SELECT   SOURCE,
                     customer_id,
                     customer_number,
                     party_name,
                     aops_customer_number,
                     cash_receipt_id,
                     customer_trx_id,
                     trx_id,
                     CLASS,
                     trx_number,
                     trx_date,
                     invoice_currency_code,
                     amount_due_remaining,
                     aps_last_update_date,
                     pre_selected_flag,
                     refund_request,
                     refund_status,
                     org_id,
                     location_id,
                     address1,
                     address2,
                     address3,
                     city,
                     state,
                     province,
                     postal_code,
                     country,
                     om_hold_status,
                     om_delete_status,
                     om_store_number,
                     store_customer_name,
                     ref_mailcheck_id
            FROM     xx_ar_refund_itm
            WHERE    (refund_request IN('Send Refund', 'Send Refund Alt') OR(refund_request IS NULL AND check_cust = 0))
            ORDER BY customer_id;

        -- Added for QC Defect 17501 - End
        CURSOR id_refund_trx_escheat(
            i_trx_date_from       IN  DATE,
            i_trx_date_to         IN  DATE,
            p_escheat_inact_days  IN  NUMBER)                                               -- Added for CR 697/698 R1.2
        IS
/*Cursor code is changed as part of the Defect# 17965 (Previously declined escheatment requests preventing new escheat request on transactions) starts here*/
            SELECT   SOURCE,
                     customer_id,
                     NULL customer_number,
                     NULL party_name,
                     NULL aops_customer_number,
                     cash_receipt_id,
                     customer_trx_id,
                     trx_id,
                     CLASS,
                     trx_number,
                     trx_date,
                     invoice_currency_code,
                     amount_due_remaining,
                     aps_last_update_date,
                     pre_selected_flag,
                     refund_request,
                     refund_status,
                     org_id,
                     location_id,
                     address1,
                     address2,
                     address3,
                     city,
                     state,
                     province,
                     postal_code,
                     country,
                     om_hold_status,
                     om_delete_status,
                     om_store_number,
                     store_customer_name,
                     0 ref_mailcheck_id                                                      -- added by gaurav for v5.0
            --FROM xx_ar_refund_trx_id_v xatv            --Commented for defect 4901
            FROM     xx_ar_open_credits_itm xatv                                           --Added for defect 4901
            WHERE    org_id = p_org_id
            AND      (refund_status IS NULL OR refund_status = 'Declined')
            AND      (   (NVL(p_only_pre_selected,
                              'N') = 'Y' AND refund_request IN('Declined', 'Escheat'))
                      OR (NVL(p_only_pre_selected,
                              'N') = 'N'))
            AND      amount_due_remaining BETWEEN NVL(  -1
                                                      * p_amount_to,
                                                      -9999999999999) AND NVL(  -1
                                                                              * p_amount_from,
                                                                              -0.000001)
            AND      trx_date BETWEEN NVL(i_trx_date_from,
                                          trx_date) AND NVL(i_trx_date_to,
                                                            trx_date)
            AND      cash_receipt_status IN('UNAPP', 'UNID')                        -- Added by Rama Krishna K for V 3.4
            --    AND (refund_request IN ('Decline', 'Escheat')  OR (refund_request IS NULL
            AND      (   refund_request = 'Escheat'
                      OR refund_request = 'Decline'
                      OR     refund_request IS NULL
                         AND check_cust(p_no_activity_in,
                                        p_escheat_inact_days,
                                        xatv.customer_id,
                                        xatv.cash_receipt_id) = 0)
            ORDER BY customer_id;

/*Cursor code change ends here as part of the Defect# 17965 (Previously declined escheatment requests preventing new escheat request on transactions) starts here    */

        /*Cursor code is commented as part of the Defect# 17965 (Previously declined escheatment requests preventing new escheat request on transactions) starts here
SELECT   SOURCE
                , customer_id
                , NULL customer_number
                , NULL party_name
                , NULL aops_customer_number
                ,                                                                                                                              --Added for R1.2 CR#714(Defect# 2532)
                  cash_receipt_id
                , customer_trx_id
                , trx_id
                , CLASS
                , trx_number
                , trx_date
                , invoice_currency_code
                , amount_due_remaining
                , aps_last_update_date
                , pre_selected_flag
                , refund_request
                , refund_status
                , org_id
                , location_id
                , address1
                , address2
                , address3
                , city
                , state
                , province
                , postal_code
                , country
                , om_hold_status
                , om_delete_status
                , om_store_number
                , store_customer_name
                , 0 ref_mailcheck_id                                                                                                                     -- added by gaurav for v5.0
             --FROM xx_ar_refund_trx_id_v xatv            --Commented for defect 4901
         FROM     xx_ar_open_credits_itm xatv                                                                                                          --Added for defect 4901
            WHERE org_id = p_org_id
              AND (   refund_status IS NULL
                   OR refund_status = 'Declined')
              AND amount_due_remaining BETWEEN NVL (-1 * p_amount_to, -9999999999999) AND NVL (-1 * p_amount_from, -0.000001)
              AND trx_date BETWEEN NVL (i_trx_date_from, trx_date) AND NVL (i_trx_date_to, trx_date)
              AND cash_receipt_status IN ('UNAPP', 'UNID')                                                                                      -- Added by Rama Krishna K for V 3.4
               -- as part of having the refunds jobs to pick UNAPP as also UNIDENTIFIED transactions on 5/16
                  -- AND customer_id IS NOT NULL--  added for the Defect 5755 -- Commented this as for UNIDENTIFIED transactions
              -- scenario, the customer_id will be NULL for V 3.4
              AND (   refund_request = 'Escheat'
                   OR (    refund_request IS NULL
                            -- Modified the below check_cust to include cash_receipt_id as IN parameter by Rama Krishna K
                       -- on 5/16 to handle UNIDENTIFIED Transaction scenario
                       AND check_cust (p_no_activity_in, p_escheat_inact_days, xatv.customer_id, xatv.cash_receipt_id) = 0                                   --Added for defect 4901
                                                                                                                          -- AND (aps_last_update_date <= (SYSDATE-NVL(p_no_activity_in,730)) ) ) )  Commented for CR 697/698 R1.2
                                                                                                                               /*AND NOT EXISTS (
                                                                                                                                                  SELECT amount_due_remaining
                                                                                                                                                  FROM   ar_payment_schedules_all APS
                                                                                                                                                  WHERE  APS.customer_id = xatv.customer_id
                                                                                                                                                  AND    APS.amount_due_remaining > 0
                                                                                                                                                 )
                                                                                                                               AND NOT EXISTS   (
                                                                                                                                                  SELECT 1
                                                                                                                                                  FROM ra_customer_trx_all RCT
                                                                                                                                                  WHERE RCT.bill_to_customer_id = xatv.customer_id
                                                                                                                                                                    AND RCT.trx_date > (SYSDATE-NVL(p_no_activity_in,p_escheat_inact_days) )
                                                                                                                                                )
                                                                                                                               AND NOT EXISTS   (
                                                                                                                                                SELECT 1
                                                                                                                                                 FROM ar_payment_schedules_all aps,
                                                                                                                                                      ar_receivable_applications_all ara
                                                                                                                                                 WHERE ara.cash_receipt_id = aps.cash_receipt_id
                                                                                                                                                 AND   aps.customer_id =  xatv.customer_id
                                                                                                                                                 AND   ara.applied_customer_trx_id IS NOT NULL
                                                                                                                                                 AND   ara.status = 'APP'
                                                                                                                                                 AND   (ara.apply_date > (SYSDATE-NVL(p_no_activity_in,p_escheat_inact_days) ))
                                                                                                                                                 )
                                                                                                                                AND NOT EXISTS (
                                                                                                                                                SELECT 1
                                                                                                                                                FROM ar_receivable_applications_all ara
                                                                                                                                                    ,ra_customer_trx_all rct
                                                                                                                                                WHERE rct.customer_trx_id = ara.applied_customer_trx_id
                                                                                                                                                AND   rct.bill_to_customer_id = XATV.customer_id
                                                                                                                                                AND   (ara.apply_date > (SYSDATE-NVL(p_no_activity_in,p_escheat_inact_days) ))
                                                                                                                                                AND   ara.status <> 'ACTIVITY'
                                                                                                                                                )
                                                                                                                               AND NOT EXISTS  (
                                                                                                                                                 SELECT 1 FROM ar_cash_receipts_all acra
                                                                                                                                                 WHERE acra.receipt_date  > (SYSDATE-NVL(p_no_activity_in,p_escheat_inact_days) )
                                                                                                                                                 AND   acra.pay_from_customer = XATV.customer_id
                                                                                                                                                 )*/
                 --     )
               --   )
         -- AND aps_last_update_date <= (SYSDATE - NVL(p_no_activity_in,p_escheat_inact_days))-- Added for the CR 697/698 R1.2
        -- ORDER BY customer_id;                                                                                                                               --Added for defect 4901
/*Cursor code is commented as part of the Defect# 17965 (Previously declined escheatment requests preventing new escheat request on transactions) ends here*/
        CURSOR id_refund_trx_sel(
            i_trx_date_from  IN  DATE,
            i_trx_date_to    IN  DATE)
        IS
            SELECT /*+ LEADING(@"SEL$D9D7977F_2" "RCT"@"SEL$D9D7977F_2") LEADING(@"SEL$53D7279B_1" "ACR"@"SEL$2") */
                   --Added this Hint for Defect# 3516 on 16-Dec-09 by Mohammed Appas A
                   SOURCE,
                   customer_id,
                   NULL customer_number,
                   NULL party_name,
                   NULL aops_customer_number,                                      --Added for R1.2 CR#714(Defect# 2532)
                   cash_receipt_id,
                   customer_trx_id,
                   trx_id,
                   CLASS,
                   trx_number,
                   trx_date,
                   invoice_currency_code,
                   amount_due_remaining,
                   aps_last_update_date,
                   pre_selected_flag,
                   refund_request,
                   refund_status,
                   org_id,
                   location_id,
                   address1,
                   address2,
                   address3,
                   city,
                   state,
                   province,
                   postal_code,
                   country,
                   om_hold_status,
                   om_delete_status,
                   om_store_number,
                   store_customer_name,
                   0 ref_mailcheck_id                                                        -- added by gaurav for v5.0
            FROM   xx_ar_refund_trx_id_v xatv
            WHERE  org_id = p_org_id
            AND    refund_request IN('Send Refund', 'Send Refund Alt')
            AND    (   (p_only_for_user_id IS NOT NULL AND last_updated_by = p_only_for_user_id)
                    OR (p_only_for_user_id IS NULL))
            --   AND ( refund_status IS NULL OR refund_status = 'Declined' )  Commented for CR 697 / 698
            AND    amount_due_remaining BETWEEN NVL(  -1
                                                    * p_amount_to,
                                                    -9999999999999) AND NVL(  -1
                                                                            * p_amount_from,
                                                                            -0.000001)
            AND    trx_date BETWEEN NVL(i_trx_date_from,
                                        trx_date) AND NVL(i_trx_date_to,
                                                          trx_date);

        CURSOR id_refund_trx_om(
            i_trx_date_from  IN  DATE,
            i_trx_date_to    IN  DATE)
        IS
            SELECT SOURCE,
                   customer_id,
                   NULL customer_number,
                   NULL party_name,
                   NULL aops_customer_number,                                     --Added for R 1.2 CR#714(Defect# 2532)
                   cash_receipt_id,
                   customer_trx_id,
                   trx_id,
                   CLASS,
                   trx_number,
                   trx_date,
                   invoice_currency_code,
                   amount_due_remaining,
                   aps_last_update_date,
                   pre_selected_flag,
                   refund_request,
                   refund_status,
                   org_id,
                   location_id,
                   address1,
                   address2,
                   address3,
                   city,
                   state,
                   province,
                   postal_code,
                   country,
                   om_hold_status,
                   om_delete_status,
                   om_store_number,
                   store_customer_name,
                   ref_mailcheck_id                                                          -- added by gaurav for v5.0
            FROM   xx_ar_refund_trx_om_id_v xatv
            /* V4.0, View definition is changed,
               Added condition that ar_cash_receipt_id should be NULL in Hold Table */
            WHERE  org_id = p_org_id
            AND    amount_due_remaining BETWEEN NVL(  -1
                                                    * p_amount_to,
                                                    -9999999999999) AND NVL(  -1
                                                                            * p_amount_from,
                                                                            -0.000001)
            AND    trx_date BETWEEN NVL(i_trx_date_from,
                                        trx_date) AND NVL(i_trx_date_to,
                                                          trx_date)
            AND    om_store_number IS NOT NULL;

        TYPE idtrxtab IS TABLE OF idtrxrec
            INDEX BY BINARY_INTEGER;

        vidtrxtab               idtrxtab;
        lc_trx_type             VARCHAR2(20);
        ln_refund_header_id     NUMBER;
        ln_id_count             NUMBER;
        ln_ins_count            NUMBER;
        lc_selected_flag        VARCHAR2(1)                        := 'N';
        lc_refund_alt_flag      VARCHAR2(1);
        lc_escheat_flag         VARCHAR2(1);
        lc_approved_flag        VARCHAR2(1);
        lc_write_off_only       VARCHAR2(1);
        lc_activity_type        VARCHAR2(60);
        lc_dff1                 VARCHAR2(30);
        lc_dff2                 VARCHAR2(30);
        ln_primary_bill_loc_id  NUMBER;
        lc_address1             VARCHAR2(240);
        lc_address2             VARCHAR2(240);
        lc_address3             VARCHAR2(240);
        lc_city                 VARCHAR2(60);
        lc_state                VARCHAR2(60);
        lc_province             VARCHAR2(60);
        lc_postal_code          VARCHAR2(60);
        lc_country              VARCHAR2(60);
        ld_date_from            DATE;
        ld_date_to              DATE;
        lc_sob_name             gl_sets_of_books.short_name%TYPE;
        exp_invalid_sob         EXCEPTION;
        ln_refund_tot           NUMBER;
        lc_user_name            fnd_user.user_name%TYPE;
        lc_ident_type           VARCHAR2(30);                                                            -- defect 10906
        ln_custcheck_db         NUMBER;                                                     -- Added for CR 697/698 R1.2
        ln_escheat_inact_days   NUMBER;                                                     -- Added for CR 697/698 R1.2
        ln_refund_inact_days    NUMBER;                                                     -- Added for CR 697/698 R1.2
        lc_payment_method_name  VARCHAR2(30);

        -- Added for QC Defect 17501 - Start
        -- This procedure will populate data in XX_AR_REFUND_ITM. This table will be repopulated for each execution
        PROCEDURE insert_refund_itm(
            lp_date_from          IN  DATE,
            lp_date_to            IN  DATE,
            lp_refund_inact_days  IN  NUMBER)
        IS
            ln_check_cust  NUMBER := 1;
        BEGIN
            EXECUTE IMMEDIATE 'TRUNCATE TABLE xxfin.xx_ar_refund_itm';

            INSERT INTO xx_ar_refund_itm
                (SELECT SOURCE,
                        customer_id,
                        NULL                                                                           --customer_number
                            ,
                        NULL                                                                                --party_name
                            ,
                        NULL                                                                      --aops_customer_number
                            ,
                        cash_receipt_id,
                        customer_trx_id,
                        trx_id,
                        CLASS,
                        trx_number,
                        trx_date,
                        invoice_currency_code,
                        amount_due_remaining,
                        aps_last_update_date,
                        pre_selected_flag,
                        refund_request,
                        refund_status,
                        org_id,
                        location_id,
                        address1,
                        address2,
                        address3,
                        city,
                        state,
                        province,
                        postal_code,
                        country,
                        om_hold_status,
                        om_delete_status,
                        om_store_number,
                        store_customer_name,
                        0 ref_mailcheck_id,
                        1                                                                                   --check_cust
                 FROM   xx_ar_open_credits_itm
                 WHERE  org_id = p_org_id
                 AND    (refund_status IS NULL OR refund_status = 'Declined')
                 AND    amount_due_remaining BETWEEN NVL(  -1
                                                         * p_amount_to,
                                                         -9999999999999)
                                                 AND NVL(  -1
                                                         * p_amount_from,
                                                         -0.000001)
                 AND    trx_date BETWEEN NVL(lp_date_from,
                                             trx_date) AND NVL(lp_date_to,
                                                               trx_date)
                 AND    (   (NVL(p_only_pre_selected,
                                 'N') = 'Y' AND refund_request IN('Send Refund', 'Send Refund Alt'))
                         OR (NVL(p_only_pre_selected,
                                 'N') = 'N'))
                 AND    cash_receipt_status IN('UNAPP', 'UNID'));

            BEGIN
                FOR i IN (SELECT DISTINCT customer_id,
                                          cash_receipt_id
                          FROM            xx_ar_refund_itm
                          ORDER BY        customer_id)
                LOOP
                    ln_check_cust := 1;
                    ln_check_cust :=
                                   check_cust(p_no_activity_in,
                                              ln_refund_inact_days,
                                              i.customer_id,
                                              i.cash_receipt_id);

                    IF ln_check_cust = 0
                    THEN
                        UPDATE xx_ar_refund_itm
                        SET check_cust = ln_check_cust
                        WHERE  customer_id = i.customer_id;
                    END IF;
                END LOOP;
            EXCEPTION
                WHEN OTHERS
                THEN
                    ln_check_cust := 2;
            END;

            COMMIT;
        EXCEPTION
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'Exception in PROCEDURE insert_refund_itm : '
                                  || SQLERRM);
        END insert_refund_itm;

        -- Added for QC Defect 17501 - End
                                                                                              -- V4.0, Added to store payment method name
        PROCEDURE open_cursor(
            lp_date_from  IN  DATE,
            lp_date_to    IN  DATE)
        IS
        BEGIN
            fnd_file.put_line(fnd_file.LOG,
                              'fetching lookups');

            SELECT meaning
            INTO   ln_escheat_inact_days
            FROM   fnd_lookup_values flv
            WHERE  lookup_type = 'XX_OD_AR_REFUND_INACTIVITY'
            AND    SYSDATE BETWEEN flv.start_date_active AND NVL(flv.end_date_active,
                                                                   SYSDATE
                                                                 + 1)
            AND    flv.enabled_flag = 'Y'
            AND    flv.lookup_code = 'ESCHEAT';                                             -- Added for CR 697/698 R1.2

            SELECT meaning
            INTO   ln_refund_inact_days
            FROM   fnd_lookup_values flv
            WHERE  lookup_type = 'XX_OD_AR_REFUND_INACTIVITY'
            AND    SYSDATE BETWEEN flv.start_date_active AND NVL(flv.end_date_active,
                                                                   SYSDATE
                                                                 + 1)
            AND    flv.enabled_flag = 'Y'
            AND    flv.lookup_code = 'REFUND';                                              -- Added for CR 697/698 R1.2

            IF (p_process_type = 'OM')
            THEN
                OPEN id_refund_trx_om(lp_date_from,
                                      lp_date_to);
            ELSIF(p_process_type = 'E')
            THEN
                --OPEN id_refund_trx_escheat(lp_date_from, lp_date_to); Commented for CR 697/698 R1.2
                OPEN id_refund_trx_escheat(lp_date_from,
                                           lp_date_to,
                                           ln_escheat_inact_days);                          -- Added for CR 697/698 R1.2
            ELSE                                                                      -- IF (lp_process_type = 'R') THEN
                IF (p_only_pre_selected = 'Y')
                THEN
                    OPEN id_refund_trx_sel(lp_date_from,
                                           lp_date_to);
                ELSE
                    --OPEN id_refund_trx_ar(lp_date_from, lp_date_to); Commented for CR 697/698 R1.2
                    --OPEN id_refund_trx_ar (lp_date_from, lp_date_to, ln_escheat_inact_days, ln_refund_inact_days);  -- Added for CR 697/698 R1.2 -- Commented for QC Defect 17501

                    -- Added for QC Defect 17501 - Start
                    insert_refund_itm(lp_date_from,
                                      lp_date_to,
                                      ln_refund_inact_days);

                    OPEN id_refund_trx_ar;
                -- Added for QC Defect 17501 - End                                        -- Added for CR 697/698 R1.2
                END IF;
            END IF;
        END;

        PROCEDURE FETCH_RECORDS
        IS
        BEGIN
            IF (p_process_type = 'OM')
            THEN
                FETCH id_refund_trx_om
                BULK COLLECT INTO vidtrxtab LIMIT p_limit_size;
                                     --Changed the limit size hardcoded value to parameter  for defect 4901 on 05-APR-10
            ELSIF(p_process_type = 'E')
            THEN
                FETCH id_refund_trx_escheat
                BULK COLLECT INTO vidtrxtab LIMIT p_limit_size;
                                     --Changed the limit size hardcoded value to parameter  for defect 4901 on 05-APR-10
            ELSE                                                                       -- IF (p_process_type = 'R') THEN
                IF (p_only_pre_selected = 'Y')
                THEN
                    FETCH id_refund_trx_sel
                    BULK COLLECT INTO vidtrxtab LIMIT p_limit_size;
                                     --Changed the limit size hardcoded value to parameter  for defect 4901 on 05-APR-10
                ELSE
                    FETCH id_refund_trx_ar
                    BULK COLLECT INTO vidtrxtab LIMIT p_limit_size;
                                     --Changed the limit size hardcoded value to parameter  for defect 4901 on 05-APR-10
                END IF;
            END IF;
        END;

        PROCEDURE close_cursors
        IS
        BEGIN
            IF (id_refund_trx_om%ISOPEN)
            THEN
                CLOSE id_refund_trx_om;
            END IF;

            IF (id_refund_trx_escheat%ISOPEN)
            THEN
                CLOSE id_refund_trx_escheat;
            END IF;

            IF (id_refund_trx_sel%ISOPEN)
            THEN
                CLOSE id_refund_trx_sel;
            END IF;

            IF (id_refund_trx_ar%ISOPEN)
            THEN
                CLOSE id_refund_trx_ar;
            END IF;
        END;
    BEGIN
        -- defect 10906, use variable for identification type (since it can change)
        lc_ident_type := p_process_type;
        ln_id_count := 0;
        ln_ins_count := 0;
        mo_global.set_policy_context('S',
                                     p_org_id);                                         --Added For R12 Upgrade Retrofit

        BEGIN
            SELECT gsb.short_name
            INTO   lc_sob_name
            FROM   ar_system_parameters asp,
                   gl_sets_of_books gsb
            WHERE  gsb.set_of_books_id = asp.set_of_books_id AND gsb.short_name IN('US_USD_P', 'CA_CAD_P');
        EXCEPTION
            WHEN OTHERS
            THEN
                od_message('O',
                           'Set of Books not found!');
                od_message('M',
                           'Set of Books not found!');
                RAISE;
        END;

        od_message('O',
                   ' ');
        od_message('O',
                   'Parameters: ');
        od_message('O',
                   '----------- ');
        od_message('O',
                   ' ');
        od_message('O',
                      'Identify:'
                   || p_process_type
                   || ' with no activity in:'
                   || NVL(p_no_activity_in,
                          0)
                   || ' days');

        IF p_amount_from IS NOT NULL OR p_amount_to IS NOT NULL
        THEN
            od_message('O',
                          '   Transaction Amounts between :'
                       || p_amount_from
                       || ' and '
                       || p_amount_to);
        END IF;

        IF p_trx_date_from IS NOT NULL
        THEN
            ld_date_from := fnd_conc_date.string_to_date(p_trx_date_from);
        END IF;

        IF p_trx_date_to IS NOT NULL
        THEN
            ld_date_to := fnd_conc_date.string_to_date(p_trx_date_to);
            od_message('O',
                          '   Transactions between :'
                       || ld_date_from
                       || ' and '
                       || ld_date_to);
        END IF;

        IF NVL(p_only_pre_selected,
               'N') = 'Y'
        THEN
            od_message('O',
                          '   Identify Only Pre-Selected Transactions:'
                       || p_only_pre_selected);

            IF p_only_for_user_id IS NOT NULL
            THEN
                BEGIN
                    SELECT user_name
                    INTO   lc_user_name
                    FROM   fnd_user
                    WHERE  user_id = p_only_for_user_id;

                    od_message('O',
                                  '   Identify Pre-Selected Transactions for only User: '
                               || lc_user_name);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        od_message('M',
                                   ' Identify Pre-Selected Transactions for only User: User Not Found');
                END;
            END IF;
        END IF;

        od_message('O',
                   ' ');
        od_message('O',
                   g_print_line);
        od_message('O',
                   ' ');
        od_message('O',
                   ' ');
        -- based on the parameters, open the corresponding cursor
        open_cursor(lp_date_from      => ld_date_from,
                    lp_date_to        => ld_date_to);

        LOOP
            -- fetch next set of records for the related cursor
            fnd_file.put_line(fnd_file.LOG,
                                 'Fetch start'
                              || TO_CHAR(SYSDATE,
                                         'HH24:MI:SS'));
            FETCH_RECORDS();
            fnd_file.put_line(fnd_file.LOG,
                                 'Fetch end'
                              || TO_CHAR(SYSDATE,
                                         'HH24:MI:SS'));
            EXIT WHEN vidtrxtab.COUNT = 0;
            ln_id_count :=   ln_id_count
                           + vidtrxtab.COUNT;
            od_message('M',
                          'Processing...'
                       || vidtrxtab.COUNT
                       || ' transactions identified...');
            fnd_file.put_line(fnd_file.LOG,
                                 p_process_type
                              || ' '
                              || p_no_activity_in
                              || ' '
                              || ln_refund_inact_days
                              || ' '
                              || ln_escheat_inact_days);

            IF vidtrxtab.COUNT > 0
            THEN
                FOR i IN vidtrxtab.FIRST .. vidtrxtab.LAST
                LOOP
                    --EXIT WHEN vidtrxtab.COUNT = 0;
                    SELECT xx_refund_header_id_s.NEXTVAL
                    INTO   ln_refund_header_id
                    FROM   DUAL;

                    IF (vidtrxtab(i).customer_id IS NOT NULL)
                    THEN
                        BEGIN
                            SELECT account_number,
                                   party_name,
                                   SUBSTR(hca.orig_system_reference,
                                          1,
                                          8) aops_customer_number                  -- Added for R1.2 CR714(Defect# 2532)
                            INTO   vidtrxtab(i).customer_number,
                                   vidtrxtab(i).party_name,
                                   vidtrxtab(i).aops_customer_number               -- Added for R1.2 CR714(Defect# 2532)
                            FROM   hz_cust_accounts hca,
                                   hz_parties hp
                            WHERE  hca.party_id = hp.party_id AND hca.cust_account_id = vidtrxtab(i).customer_id;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                od_message('M',
                                              'Errors while fetching customer information. '
                                           || SQLERRM);
                        END;
                    ELSE
                        -- if customer is not defined (unidentified), and refunding the customer,
                        --   then through an error message
                        IF (lc_ident_type = 'R')
                        THEN
                            od_message('M',
                                       'Processing a refund for a transaction without a customer.');
                        END IF;
                    END IF;

                    -- defect 11109 - set party_name to store_customer_name if OM/SAS mailcheck
                    IF (vidtrxtab(i).store_customer_name IS NOT NULL)
                    THEN
                        vidtrxtab(i).party_name := vidtrxtab(i).store_customer_name;
                    END IF;

                    IF p_process_type IN('E') AND vidtrxtab(i).SOURCE != 'OM'
                    THEN
                        -- Escheats/OM Mail-Check Refunds.
                        lc_escheat_flag := 'Y';
                        --lc_selected_flag := 'Y';        --Commented for R1.3 CR#544 Defect#1253
                        lc_selected_flag := 'N';                                    --Added for R1.3 CR#544 Defect#1253
                        lc_refund_alt_flag := 'N';
                        lc_write_off_only := 'N';
                        lc_dff1 := 'Escheat';

                        IF lc_sob_name = 'US_USD_P'
                        THEN
                            IF vidtrxtab(i).CLASS = 'PMT'
                            THEN
                                lc_activity_type := 'US_ESCHEAT_REC_WRITEOFF_OD';
                            ELSE
                                lc_activity_type := 'US_ESCHEAT_CM_WRITEOFF_OD';
                            END IF;
                        ELSIF lc_sob_name = 'CA_CAD_P'
                        THEN
                            IF vidtrxtab(i).CLASS = 'PMT'
                            THEN
                                lc_activity_type := 'CA_ESCHEAT_REC_WRITEOFF_OD';
                            ELSE
                                lc_activity_type := 'CA_ESCHEAT_CM_WRITEOFF_OD';
                            END IF;
                        ELSE
                            RAISE exp_invalid_sob;
                        END IF;
                    ELSIF p_process_type IN('OM') AND vidtrxtab(i).SOURCE = 'OM' AND vidtrxtab(i).CLASS = 'PMT'
                    THEN
                        -- OM Mail-Check Refunds.
                        -- Check the Hold/Delete status to determine if this is
                        -- an escheat trx
                        IF (vidtrxtab(i).om_hold_status = 'P' AND vidtrxtab(i).om_delete_status = 'N')
                        THEN
                            -- Pay Customer;
                            lc_write_off_only := 'N';
                            lc_escheat_flag := 'N';

                            IF lc_sob_name = 'US_USD_P'
                            THEN
                                lc_activity_type := 'US_MAILCK_CLR_OD';
                            ELSIF lc_sob_name = 'CA_CAD_P'
                            THEN
                                lc_activity_type := 'CA_MAILCK_CLR_OD';
                            ELSE
                                RAISE exp_invalid_sob;
                            END IF;
                        -- BLooman - ignore hold_status values for escheat
                        ELSIF(vidtrxtab(i).om_delete_status IN('A', 'E'))
                        THEN
                            --Writeoff_As_escheat;
                            lc_escheat_flag := 'Y';
                            lc_write_off_only := 'N';

                            IF lc_sob_name = 'US_USD_P'
                            THEN
                                lc_activity_type := 'US_ESCHEAT_REC_WRITEOFF_OD';
                            ELSIF lc_sob_name = 'CA_CAD_P'
                            THEN
                                lc_activity_type := 'CA_ESCHEAT_REC_WRITEOFF_OD';
                            ELSE
                                RAISE exp_invalid_sob;
                            END IF;                                                                    -- sob_name check
                        -- BLooman - process any other mail check records as write-offs
                        ELSE
                            --writeoff_receipt
                            lc_write_off_only := 'Y';
                            lc_escheat_flag := 'N';

                            IF lc_sob_name = 'US_USD_P'
                            THEN
                                IF (vidtrxtab(i).om_delete_status = 'S')
                                THEN
                                    lc_activity_type :=    'US_MAILCK_REV_'
                                                        || vidtrxtab(i).om_store_number
                                                        || '_OD';
                                ELSIF((vidtrxtab(i).om_delete_status = 'O')
                                                                           -- V4.0, Added OR Condition for delete_status 'M'
                                      OR(vidtrxtab(i).om_delete_status = 'M'))
                                THEN
                                    lc_activity_type :=    'US_MAILCK_O/S_'
                                                        || vidtrxtab(i).om_store_number
                                                        || '_OD';
                                ELSE
                                    -- V4.0, For any other combinations, display error message
                                    GOTO NEXT_RECORD;
                                -- V4.0 lc_activity_type := 'US_MAILCK_CLR_OD';
                                END IF;
                            -- V4.0, Added ELSIF for CANADA SOB
                            ELSIF lc_sob_name = 'CA_CAD_P'
                            THEN
                                IF (vidtrxtab(i).om_delete_status = 'S')
                                THEN
                                    lc_activity_type :=    'CA_MAILCK_REV_'
                                                        || vidtrxtab(i).om_store_number
                                                        || '_OD';
                                ELSIF((vidtrxtab(i).om_delete_status = 'O')
                                                                           -- V4.0, Added OR Condition for delete_status 'M'
                                      OR(vidtrxtab(i).om_delete_status = 'M'))
                                THEN
                                    lc_activity_type :=    'CA_MAILCK_O/S_'
                                                        || vidtrxtab(i).om_store_number
                                                        || '_OD';
                                ELSE
                                    -- V4.0, For any other combinations, display error message
                                    GOTO NEXT_RECORD;
                                -- V4.0 lc_activity_type := 'CA_MAILCK_CLR_OD';
                                END IF;
                            ELSE
                                RAISE exp_invalid_sob;
                            END IF;
                        END IF;

                        IF NVL(lc_escheat_flag,
                               'N') = 'Y'
                        THEN
                            lc_dff1 := 'Escheat';
                        ELSE
                            lc_dff1 := 'Send Refund Alt';
                        END IF;

                        lc_selected_flag := 'Y';
                        lc_refund_alt_flag := 'Y';
                        lc_approved_flag := 'Y';
                    ELSE
                        /*  -- Non-Escheat / Non-OM Refunds. --------    */
                        IF lc_sob_name = 'US_USD_P'
                        THEN
                            IF vidtrxtab(i).CLASS = 'PMT'
                            THEN
                                lc_activity_type := 'US_REC_AUTO MAIL CHK_OD';
                            ELSE
                                lc_activity_type := 'US_CM_AUTO MAIL CHK_OD';
                            END IF;
                        ELSIF lc_sob_name = 'CA_CAD_P'
                        THEN
                            IF vidtrxtab(i).CLASS = 'PMT'
                            THEN
                                lc_activity_type := 'CA_REC_AUTO MAIL CHK_OD';
                            ELSE
                                lc_activity_type := 'CA_CM_AUTO MAIL CHK_OD';
                            END IF;
                        ELSE
                            RAISE exp_invalid_sob;
                        END IF;

                        IF (vidtrxtab(i).refund_request = 'Send Refund Alt')
                        THEN
                            lc_escheat_flag := 'N';
                            lc_selected_flag := 'N';
                            lc_refund_alt_flag := 'Y';
                            lc_dff1 := 'Send Refund Alt';
                        ELSIF(vidtrxtab(i).refund_request = 'Send Refund')
                        THEN
                            lc_escheat_flag := 'N';
                            lc_selected_flag := 'N';
                            lc_refund_alt_flag := 'N';
                            lc_dff1 := 'Send Refund';
                        ELSIF(vidtrxtab(i).refund_request = 'Escheat')
                        THEN
                            -- defect 10906, these should be ident type of "E" (Escheat)
                            lc_ident_type := 'E';
                            lc_escheat_flag := 'Y';
                            --lc_selected_flag := 'Y';        --Commented for R1.3 CR#544 Defect#1253
                            lc_selected_flag := 'N';                                --Added for R1.3 CR#544 Defect#1253
                            lc_refund_alt_flag := 'N';
                            lc_dff1 := 'Escheat';
                        ELSE
                            lc_escheat_flag := 'N';
                            lc_selected_flag := 'N';
                            lc_refund_alt_flag := 'N';
                            lc_dff1 := 'Send Refund';
                        END IF;
                    END IF;

                    IF vidtrxtab(i).SOURCE = 'OM'
                    THEN
                        ln_primary_bill_loc_id := vidtrxtab(i).location_id;
                        lc_address1 := vidtrxtab(i).address1;
                        lc_address2 := vidtrxtab(i).address2;
                        lc_address3 := vidtrxtab(i).address3;
                        lc_city := vidtrxtab(i).city;
                        lc_state := vidtrxtab(i).state;
                        lc_province := vidtrxtab(i).province;
                        lc_postal_code := vidtrxtab(i).postal_code;
                        lc_country := vidtrxtab(i).country;
                    ELSE                                                                             -- 'NON-OM' Source.
                        IF NVL(lc_refund_alt_flag,
                               'N') = 'Y'
                        THEN
                            ln_primary_bill_loc_id := vidtrxtab(i).location_id;
                            lc_address1 := NULL;
                            lc_address2 := NULL;
                            lc_address3 := NULL;
                            lc_city := NULL;
                            lc_state := NULL;
                            lc_province := NULL;
                            lc_postal_code := NULL;
                            lc_country := NULL;
                        ELSE
                            -- Get the primary Bill Site for the customer.
                            od_message('M',
                                          'Get primary bill Site for Customer# '
                                       || vidtrxtab(i).customer_number
                                       || ' - '
                                       || vidtrxtab(i).party_name);

                            IF (vidtrxtab(i).customer_id IS NOT NULL)
                            THEN
                                BEGIN
                                    SELECT hl.location_id,
                                           hl.address1,
                                           hl.address2,
                                           hl.address3,
                                           hl.city,
                                           hl.state,
                                           hl.province,
                                           hl.postal_code,
                                           hl.country
                                    INTO   ln_primary_bill_loc_id,
                                           lc_address1,
                                           lc_address2,
                                           lc_address3,
                                           lc_city,
                                           lc_state,
                                           lc_province,
                                           lc_postal_code,
                                           lc_country
                                    FROM   hz_cust_accounts_all hca,
                                           hz_cust_acct_sites_all hcas,
                                           hz_cust_site_uses_all hcsu,
                                           hz_party_sites hps,
                                           hz_locations hl,
                                           hz_parties party
                                    WHERE  party.party_id = hca.party_id
                                    AND    hca.cust_account_id = hcas.cust_account_id
                                    AND    hcas.cust_acct_site_id = hcsu.cust_acct_site_id
                                    AND    hcas.party_site_id = hps.party_site_id
                                    AND    hl.location_id = hps.location_id
                                    AND    hcas.org_id = vidtrxtab(i).org_id
                                    AND    hcsu.primary_flag = 'Y'
                                    AND    hcsu.site_use_code = 'BILL_TO'
                                    AND    hca.cust_account_id = vidtrxtab(i).customer_id;
                                EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                        NULL;
                                END;
                            END IF;
                        END IF;
                    END IF;

                    -- V4.0, Added to derive payment method name, to insert into refund temp table
                    BEGIN
                        SELECT arm.NAME
                        INTO   lc_payment_method_name
                        FROM   ar_receipt_methods arm,
                               ar_cash_receipts_all acr
                        WHERE  arm.receipt_method_id = acr.receipt_method_id
                        AND    acr.cash_receipt_id = vidtrxtab(i).trx_id;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            lc_payment_method_name := NULL;
                    END;

                    -- V4.0, end of Payment method derivation
                    BEGIN
                        INSERT INTO xx_ar_refund_trx_tmp
                                    (refund_header_id,
                                     customer_id,
                                     customer_number,
                                     payee_name,
                                     aops_customer_number                          -- Added for R1.2 CR714(Defect# 2532)
                                                         ,
                                     trx_id,
                                     trx_type,
                                     trx_number,
                                     trx_currency_code,
                                     refund_amount,
                                     adj_created_flag,
                                     selected_flag,
                                     identification_type,
                                     identification_date,
                                     org_id,
                                     primary_bill_loc_id,
                                     alt_address1,
                                     alt_address2,
                                     alt_address3,
                                     alt_city,
                                     alt_state,
                                     alt_province,
                                     alt_postal_code,
                                     alt_country,
                                     last_update_date,
                                     last_updated_by,
                                     creation_date,
                                     created_by,
                                     last_update_login,
                                     refund_alt_flag,
                                     escheat_flag,
                                     paid_flag,
                                     status,
                                     om_delete_status,
                                     om_hold_status,
                                     om_write_off_only,
                                     om_store_number,
                                     activity_type,
                                     original_activity_type                                     --Added for Defect #3340
                                                           ,
                                     account_orig_dr                                            --Added for Defect #3340
                                                    ,
                                     account_generic_cr                                         --Added for Defect #3340
                                                       ,
                                     payment_method_name                               -- V4.0, to insert payment method
                                                        ,
                                     ref_mailcheck_id                                                            -- V5.0
                                                     )
                             VALUES (ln_refund_header_id,
                                     vidtrxtab(i).customer_id,
                                     vidtrxtab(i).customer_number,
                                     vidtrxtab(i).party_name,
                                     vidtrxtab(i).aops_customer_number             -- Added for R1.2 CR714(Defect# 2532)
                                                                      ,
                                     vidtrxtab(i).trx_id
--                 , DECODE (vidtrxtab(i).class, 'PMT', 'R', 'C')                  -- commented for CR 697/698 R1.2
                        ,
                                     DECODE(vidtrxtab(i).CLASS,
                                            'PMT', 'R',
                                            'CM', 'C',
                                            'INV', 'I')                                     -- Added for CR 697/698 R1.2
                                                       ,
                                     vidtrxtab(i).trx_number,
                                     vidtrxtab(i).trx_currency_code,
                                       -1
                                     * vidtrxtab(i).refund_amount,
                                     'N',
                                     lc_selected_flag
                                                     -- defect 10906, using local identification type variable
                        ,
                                     lc_ident_type
                                                  --, p_process_type
                        ,
                                     SYSDATE,
                                     vidtrxtab(i).org_id,
                                     ln_primary_bill_loc_id,
                                     lc_address1,
                                     lc_address2,
                                     lc_address3,
                                     lc_city,
                                     lc_state,
                                     lc_province,
                                     lc_postal_code,
                                     lc_country,
                                     SYSDATE,
                                     fnd_global.user_id,
                                     SYSDATE,
                                     fnd_global.user_id,
                                     fnd_global.login_id,
                                     lc_refund_alt_flag,
                                     lc_escheat_flag,
                                     'N'
                   -- defect 10906, using local identification type variable
/*                   , DECODE (lc_ident_type
                   --, DECODE (p_process_type
                      , 'OM', DECODE (NVL (lc_approved_flag, 'N' )
                         , 'Y', 'W', 'I' ), 'E', 'W', 'I' )*/                                                     --Commented for R1.3 CR#544 Defect#1253
                        ,
                                     DECODE(lc_ident_type                            --Added for R1.3 CR#544 Defect#1253
                                                         ,
                                            'OM', DECODE(NVL(lc_approved_flag,
                                                             'N'),
                                                         'Y', 'W',
                                                         'I'),
                                            'I'),
                                     vidtrxtab(i).om_delete_status,
                                     vidtrxtab(i).om_hold_status,
                                     NVL(lc_write_off_only,
                                         'N'),
                                     vidtrxtab(i).om_store_number,
                                     lc_activity_type,
                                     NULL                                                       --Added for Defect #3340
                                         ,
                                     NULL                                                       --Added for Defect #3340
                                         ,
                                     NULL                                                       --Added for Defect #3340
                                         --, lc_payment_method_name  -- V4.0, passed payment method name
                        ,
                                     DECODE(lc_ident_type,
                                            'OM', 'US_MAILCHECK_OD',
                                            lc_payment_method_name)                                              -- v5.0
                                                                   ,
                                     vidtrxtab(i).ref_mailcheck_id                                               -- V5.0
                                                                  );

                        IF vidtrxtab(i).CLASS = 'PMT'
                        THEN
                            UPDATE ar_cash_receipts_all acr
                            SET attribute_category = 'SALES_ACCT',
                                attribute9 = lc_dff1,
                                last_update_date = SYSDATE                                              -- Defect #13458
                                                          ,
                                last_updated_by = fnd_profile.VALUE('USER_ID')                         -- Defect # 13458
                            WHERE  cash_receipt_id = vidtrxtab(i).cash_receipt_id;
                        ELSE
                            UPDATE ra_customer_trx_all
                            SET attribute_category = 'SALES_ACCT',
                                attribute9 = lc_dff1,
                                last_update_date = SYSDATE                                              -- Defect #13458
                                                          ,
                                last_updated_by = fnd_profile.VALUE('USER_ID')                         -- Defect # 13458
                            WHERE  customer_trx_id = vidtrxtab(i).customer_trx_id;
                        END IF;

                        ln_ins_count :=   NVL(ln_ins_count,
                                              0)
                                        + 1;
                        ln_refund_tot :=   NVL(ln_refund_tot,
                                               0)
                                         +   vidtrxtab(i).refund_amount
                                           * -1;

                        IF NVL(ln_ins_count,
                               0) = 1
                        THEN
                            od_message('O',
                                       g_print_line);
                            -- Customer # (10)  Customer Name (30) Type (12)
                            -- Transaction Number (15)  Refund Amount (15)
                            -- Status (7)  Escheat(8) Refund Alt (10)
                            od_message('O',
                                          'Customer# '
                                       || 'Payee                         '
                                       || 'Trx Type    '
                                       || 'Trx Number     '
                                       || ' Refund Amount '
                                       -- || 'Status '
                                       || 'Escheat '
                                       || 'Refund Alt');
                            od_message('O',
                                       g_print_line);
                            od_message('O',
                                       '');
                        END IF;

                        IF vidtrxtab(i).CLASS = 'PMT'
                        THEN
                            lc_trx_type := 'Receipt';
                        ELSIF vidtrxtab(i).CLASS = 'CM'
                        THEN                                                                           -- 697/698 Change
                            lc_trx_type := 'Credit Memo';
                        ELSE
                            lc_trx_type := 'Invoice';
                        END IF;

                        od_message('O',
                                      RPAD(SUBSTR(vidtrxtab(i).customer_number,
                                                  1,
                                                  10),
                                           10,
                                           ' ')
                                   || RPAD(SUBSTR(vidtrxtab(i).party_name,
                                                  1,
                                                  30),
                                           30,
                                           ' ')
                                   || RPAD(lc_trx_type,
                                           12,
                                           ' ')
                                   || RPAD(SUBSTR(vidtrxtab(i).trx_number,
                                                  1,
                                                  15),
                                           15,
                                           ' ')
                                   || LPAD(TO_CHAR(  vidtrxtab(i).refund_amount
                                                   * -1,
                                                   '99G999G990D00PR'),
                                           15,
                                           ' ')
                                   || '   '
                                   || lc_escheat_flag
                                   || '    '
                                   || '    '
                                   || lc_refund_alt_flag
                                   || '    ');
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            od_message('M',
                                          SQLCODE
                                       || ': '
                                       || SQLERRM
                                       || ' When saving Trx '
                                       || vidtrxtab(i).CLASS
                                       || ':'
                                       || vidtrxtab(i).trx_number);
                    END;

                    -- V4.0, Ignore the record, in case of wrong Combination of Delete_Status and Hold_Status
                    <<NEXT_RECORD>>                                                                               -- V4.
                    od_message('E',
                               'Invalid Combination of Delete_Status and Hold_Status');
                END LOOP;
            END IF;
        END LOOP;

        IF ln_id_count > 0
        THEN
            od_message('O',
                       ' ');
            od_message('O',
                       g_print_line);

            IF p_process_type = 'R'
            THEN
                od_message('M',
                              'Identified '
                           || ln_id_count
                           || ' transactions to Review Form');
                od_message('M',
                              'Inserted '
                           || ln_ins_count
                           || ' transactions to Review Form');
                od_message('O',
                              RPAD(' ',
                                   10,
                                   ' ')
                           || RPAD(' ',
                                   30,
                                   ' ')
                           || LPAD('Total Refunds Identified:',
                                   27,
                                   ' ')
                           || LPAD(TO_CHAR(ln_refund_tot,
                                           '99G999G990D00PR'),
                                   15,
                                   ' '));
            ELSIF p_process_type = 'E'
            THEN
                od_message('O',
                              RPAD(' ',
                                   10,
                                   ' ')
                           || RPAD(' ',
                                   30,
                                   ' ')
                           || LPAD('Escheats Identified:',
                                   27,
                                   ' ')
                           || LPAD(TO_CHAR(ln_refund_tot,
                                           '99G999G990D00PR'),
                                   15,
                                   ' '));
            ELSIF p_process_type = 'OM'
            THEN
                od_message('O',
                              RPAD(' ',
                                   10,
                                   ' ')
                           || LPAD('Total Store Refunds/Escheats Identified:',
                                   57,
                                   ' ')
                           || LPAD(TO_CHAR(ln_refund_tot,
                                           '99G999G990D00PR'),
                                   15,
                                   ' '));
            ELSE
                od_message('O',
                              RPAD(' ',
                                   10,
                                   ' ')
                           || RPAD(' ',
                                   30,
                                   ' ')
                           || LPAD('Total :',
                                   27,
                                   ' ')
                           || LPAD(TO_CHAR(ln_refund_tot,
                                           '99G999G990D00PR'),
                                   15,
                                   ' '));
                od_message('M',
                              'Identified '
                           || ln_id_count
                           || ' transactions.');
                od_message('M',
                              'Inserted '
                           || ln_ins_count
                           || ' transactions.');
            END IF;

            od_message('O',
                       g_print_line);
            od_message('O',
                       ' ');
        ELSE                                                                                   -- No records Identified.
            od_message('M',
                       'No Transactions Identified for Review');
        END IF;

        close_cursors();
        COMMIT;
    EXCEPTION
        WHEN exp_invalid_sob
        THEN
            close_cursors();
            od_message('E',
                       'Error Identifying Refund Transactions.',
                       'Invalid Set of Books');
        WHEN OTHERS
        THEN
            close_cursors();
            od_message('M',
                          'Error Identifying Refund Transactions.'
                       || SQLCODE
                       || ':'
                       || SQLERRM);
            od_message('E',
                       'Error Identifying Refund Transactions.');
    END identify_refund_trx;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
    PROCEDURE create_refund(
        errbuf         OUT NOCOPY     VARCHAR2,
        retcode        OUT NOCOPY     VARCHAR2,
        p_om_escheats  IN             VARCHAR2,
        p_user_id      IN             NUMBER                                                 --Added for the defect 8304
                                            )
    IS
        CURSOR c_refund_hdr(
            p_org_id  IN  NUMBER)
        IS
            SELECT   refund_header_id,
                     trx_type,
                     customer_id,
                     customer_number,
                     trx_currency_code,
                     SUM(refund_amount) refund_amount
            FROM     xx_ar_refund_trx_tmp
            WHERE    adj_created_flag = 'N'
            AND      status = 'W'
            AND      selected_flag = 'Y'
            AND      (   (NVL(p_om_escheats,
                              'N') = 'Y' AND(identification_type = 'OM' AND escheat_flag = 'Y'))
                      OR (NVL(p_om_escheats,
                              'N') = 'N' AND NOT(identification_type = 'OM' AND escheat_flag = 'Y')))
            AND      org_id = p_org_id
            AND      last_updated_by = NVL(p_user_id,
                                           last_updated_by)                                  --Added for the defect 8304
            GROUP BY refund_header_id,
                     trx_type,
                     customer_id,
                     customer_number,
                     trx_currency_code
            ORDER BY customer_number,
                     trx_type;

        CURSOR c_trx(
            p_customer_id       IN  NUMBER,
            p_org_id            IN  NUMBER,
            p_refund_header_id  IN  NUMBER)
        IS
            -- defect 8298 - B.Looman - added hint for performance enhancements
            SELECT        /*+ INDEX (XX_AR_REFUND_TRX_TMP XX_AR_REFUND_TRX_TMP_U1) */
                          *
            FROM          xx_ar_refund_trx_tmp
            WHERE         customer_id = p_customer_id
            AND           adj_created_flag = 'N'
            AND           status = 'W'                                                         --Approved for Write off.
            AND           selected_flag = 'Y'
            AND           org_id = p_org_id
            AND           refund_header_id = p_refund_header_id
            FOR UPDATE OF adjustment_number, adj_created_flag, adj_creation_date
            ORDER BY      customer_number,
                          trx_number;

        CURSOR c_trx_to_unapply(
            p_cash_receipt_id  IN  NUMBER)
        IS
            SELECT ara.applied_payment_schedule_id,
                   ara.receivable_application_id,
                   ara.amount_applied,
                   aps.trx_number
            FROM   ar_receivable_applications ara,
                   ar_payment_schedules aps
            WHERE  ara.applied_payment_schedule_id = aps.payment_schedule_id
            -- defect 8298 - B.Looman - remove trim so index is used
            AND    aps.trx_number IN('On Account', 'Prepayment')
            --AND TRIM (aps.trx_number) IN ('On Account', 'Prepayment')
            AND    NVL(display,
                       'N') = 'Y'
            AND    application_type = 'CASH'
            AND    ara.cash_receipt_id = p_cash_receipt_id;

        CURSOR get_addr(
            p_org_id  IN  NUMBER)
        IS
            SELECT   COUNT(*),
                     customer_id,
                     org_id,
                     customer_number
            FROM     xx_ar_refund_trx_tmp
            WHERE    escheat_flag = 'N'
            AND      refund_alt_flag = 'N'
            AND      identification_type != 'OM'
            AND      status = 'W'
            AND      org_id = p_org_id
            AND      adj_created_flag = 'N'
            AND      (   primary_bill_loc_id IS NULL
                      OR alt_address1 IS NULL
                      OR alt_city IS NULL
                      OR NVL(alt_state,
                             alt_province) IS NULL)
            AND      identification_type = 'R'
            GROUP BY customer_id,
                     org_id,
                     customer_number;

        ln_customer_id         hz_cust_accounts.cust_account_id%TYPE;
        ln_ps_id               ar_payment_schedules_all.payment_schedule_id%TYPE;
        ln_cash_receipt_id     ar_cash_receipts_all.cash_receipt_id%TYPE;
        ln_cust_trx_id         ra_customer_trx_all.customer_trx_id%TYPE;
        ln_cust_trx_line_id    ra_customer_trx_lines_all.customer_trx_line_id%TYPE;
        ln_amt_rem             ar_payment_schedules_all.amount_due_remaining%TYPE;
        ln_adj_amt_from        ar_approval_user_limits.amount_from%TYPE;
        ln_adj_amt_to          ar_approval_user_limits.amount_to%TYPE;
        ln_wrtoff_amt_from     ar_approval_user_limits.amount_from%TYPE;
        ln_wrtoff_amt_to       ar_approval_user_limits.amount_to%TYPE;
        lc_trx_type            VARCHAR2(20);
        x_return_status        VARCHAR2(2000);
        x_msg_count            NUMBER;
        x_msg_data             VARCHAR2(2000);
        lc_api_err_msg         VARCHAR2(2000);
        lc_err_loc             VARCHAR2(100);
        lc_err_msg             VARCHAR2(100);
        lc_err                 VARCHAR2(1);
        lc_adj_warning         VARCHAR2(1);
        lc_adj_num             VARCHAR2(100);
        ln_org_id              NUMBER;
        ln_onacct_amt          ar_receivable_applications_all.amount_applied%TYPE;
        ln_refund_total        NUMBER;
        lc_sob_name            gl_sets_of_books.short_name%TYPE;
        --lc_cm_adj_name        ar_receivables_trx.NAME%TYPE;
        --lc_rcpt_wo_name       ar_receivables_trx.NAME%TYPE;
        ln_conc_request_id     NUMBER;
        lc_reason_code         VARCHAR2(100);
        lc_comments            VARCHAR2(2000);
        lc_address1            VARCHAR2(240);
        lc_address2            VARCHAR2(240);
        lc_address3            VARCHAR2(240);
        lc_city                VARCHAR2(60);
        lc_state               VARCHAR2(60);
        lc_province            VARCHAR2(60);
        lc_postal_code         VARCHAR2(60);
        lc_country             VARCHAR2(60);
        lc_status              VARCHAR2(20);
        ln_refunds_count       NUMBER                                                := 0;
        ln_refund_amounts_tot  NUMBER                                                := 0;
        ln_errors_count        NUMBER                                                := 0;
        -- V4.0, to store payment method flag for store trx
        ln_mail_check          NUMBER                                                := 0;
    BEGIN
        ln_org_id := fnd_profile.VALUE('ORG_ID');
        ln_conc_request_id := fnd_profile.VALUE('CONC_REQUEST_ID');

        BEGIN
            SELECT gsb.short_name
            INTO   lc_sob_name
            FROM   ar_system_parameters asp,
                   gl_sets_of_books gsb
            WHERE  gsb.set_of_books_id = asp.set_of_books_id;
        EXCEPTION
            WHEN OTHERS
            THEN
                od_message('M',
                           'Set of Books not found!');
                RAISE;
        END;

        od_message('M',
                      'Set of Books: '
                   || lc_sob_name);
        od_message('O',
                   '');
        od_message('O',
                      'Set of Books:'
                   || fnd_profile.VALUE('GL_SET_OF_BKS_NAME')
                   || '                 OD: Refunds - Create Refunds                        Date:'
                   || TRUNC(SYSDATE));
        od_message('O',
                   '');
        od_message('O',
                   '');

        -- Verify Primary Bill-To address has been setup
        -- for all non-escheat transactions.
        BEGIN
            FOR v_get_addr IN get_addr(ln_org_id)
            LOOP
                BEGIN
                    UPDATE xx_ar_refund_trx_tmp
                    SET (primary_bill_loc_id, alt_address1, alt_address2, alt_address3, alt_city, alt_state,
                         alt_province, alt_postal_code, alt_country) =
                            (SELECT hl.location_id,
                                    hl.address1,
                                    hl.address2,
                                    hl.address3,
                                    hl.city,
                                    hl.state,
                                    hl.province,
                                    hl.postal_code,
                                    hl.country
                             FROM   hz_cust_accounts hca,
                                    hz_cust_acct_sites hcas,
                                    hz_cust_site_uses hcsu,
                                    hz_party_sites hps,
                                    hz_locations hl
                             WHERE  hca.cust_account_id = hcas.cust_account_id(+)
                             AND    hcas.cust_acct_site_id = hcsu.cust_acct_site_id(+)
                             AND    hcas.party_site_id = hps.party_site_id
                             AND    hl.location_id = hps.location_id
                             AND    hcas.org_id = v_get_addr.org_id
                             AND    NVL(hcsu.primary_flag,
                                        'N') = 'Y'
                             AND    hcsu.site_use_code = 'BILL_TO'
                             AND    hca.cust_account_id = v_get_addr.customer_id
                             AND    ROWNUM = 1),
                        last_update_date = SYSDATE,
                        last_updated_by = fnd_profile.VALUE('USER_ID'),
                        last_update_login = fnd_profile.VALUE('LOGIN_ID')
                    WHERE  customer_id = v_get_addr.customer_id
                    AND    escheat_flag = 'N'
                    AND    refund_alt_flag = 'N'
                    AND    status = 'W'
                    AND    adj_created_flag = 'N'
                    AND    (   primary_bill_loc_id IS NULL
                            OR alt_address1 IS NULL
                            OR alt_city IS NULL
                            OR NVL(alt_state,
                                   alt_province) IS NULL)
                    AND    identification_type = 'R';

                    od_message('M',
                                  'Updated '
                               || SQL%ROWCOUNT
                               || ' rows.');
                    od_message('M',
                                  'Found Primary Bill_To for Customer#:'
                               || v_get_addr.customer_number
                               || ' in org:'
                               || v_get_addr.org_id);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        od_message('M',
                                      '*** Error getting Primary Bill_To for Customer#:'
                                   || v_get_addr.customer_number
                                   || ' in org:'
                                   || v_get_addr.org_id
                                   || '  Error:'
                                   || SQLCODE
                                   || ':'
                                   || SQLERRM);
                END;
            END LOOP;
        EXCEPTION
            WHEN OTHERS
            THEN
                NULL;
        END;

        -- For each refund header ID in xx_ar_refund_trx_tmp table
        -- with atleast one row in xx_ar_refund_trx_tmp with adj_created_flag = 'N'
        FOR v_refund_hdr IN c_refund_hdr(ln_org_id)
        LOOP
            -- Get all records in xx_ar_refund_trx_tmp for refund header ID and adj_created_flag = 'N'
            ln_adj_amt_from := 0;
            ln_adj_amt_to := 0;

            -- IF lc_trx_type = 'C' THEN   Commented for CR 697/698 R1.2
            IF lc_trx_type = 'C' OR lc_trx_type = 'I'
            THEN                                                                           -- Added for CR 697/698 R1.2
                lc_trx_type := 'Credit Memo';
            ELSE
                lc_trx_type := 'Receipt';
            END IF;

            od_message('M',
                       '----------------------------------------------------------------------');

            FOR v_trx IN c_trx(v_refund_hdr.customer_id,
                               ln_org_id,
                               v_refund_hdr.refund_header_id)
            LOOP
                lc_err := 'N';
                lc_adj_warning := 'N';
                lc_adj_num := NULL;
                ln_ps_id := NULL;
                x_return_status := NULL;
                x_msg_data := NULL;
                x_msg_count := NULL;
                -- V4.0, defaulting with 0, only for Store trx and Mailcheck payment method it would be 1
                ln_mail_check := 0;
                od_message('M',
                              'Customer#:'
                           || v_refund_hdr.customer_number
                           || ' Type:'
                           || v_trx.trx_type
                           || '  Trx#:'
                           || v_trx.trx_number
                           || ' Refund Amount:'
                           || v_refund_hdr.trx_currency_code
                           || ' '
                           || v_refund_hdr.refund_amount);

            -- set error flag if customer is not defined (Unidentified Receipts)
--            IF (v_trx.identification_type = 'R' AND v_trx.customer_id IS NULL) THEN
--              UPDATE xx_ar_refund_trx_tmp
--                 SET error_flag = 'Y'
--                   , last_update_date = SYSDATE
--                   , last_updated_by = fnd_profile.VALUE ('USER_ID')
--                   , last_update_login = fnd_profile.VALUE ('LOGIN_ID')
--               WHERE refund_header_id = v_trx.refund_header_id;

                --              INSERT INTO xx_ar_refund_error_log
--                      (conc_request_id, err_code , customer_number, trx_type
--                     , trx_number , attribute1 , attribute2, attribute3 )
--               VALUES (ln_conc_request_id, 'R0018', v_refund_hdr.customer_number
--                     , lc_trx_type, v_trx.trx_number, NULL ,NULL, NULL );
--            END IF;

                -- Get payment schedule ID and amount due remaining for the transaction
                BEGIN
                    SELECT payment_schedule_id,
                           DECODE(ps.CLASS,
                                  'PMT', 'Receipt',
                                  'Credit Memo'),
                             -1
                           * amount_due_remaining
                    INTO   ln_ps_id,
                           lc_trx_type,
                           ln_amt_rem
                    FROM   ar_payment_schedules ps
                    WHERE  ps.customer_id = v_refund_hdr.customer_id
                    AND    (   (v_trx.trx_type = 'R' AND ps.cash_receipt_id = v_trx.trx_id)
                            -- OR ( v_trx.trx_type = 'C'   Commented for CR 697/698 R1.2
                            OR (    v_trx.trx_type IN('C', 'I')                             -- Added for CR 697/698 R1.2
                                AND ps.customer_trx_id = v_trx.trx_id));

                    IF v_trx.trx_type = 'R'
                    THEN
                        BEGIN
                            ln_onacct_amt := 0;

                            -- removed "-1 * " since the on-account amount should be positive
                            --   defect 11485 - B.Looman - 9/24/08
                            SELECT NVL(SUM(NVL(amount_applied,
                                               0)),
                                       0)
                            --NVL (SUM (NVL (-1 * amount_applied, 0)), 0)
                            INTO   ln_onacct_amt
                            FROM   ar_receivable_applications
                            WHERE  cash_receipt_id = v_trx.trx_id
                            AND    display = 'Y'                                    -- only show the active applications
                            AND    applied_payment_schedule_id = (SELECT payment_schedule_id
                                                                  FROM   ar_payment_schedules_all
                                                                  -- defect 8298 - B.Looman - remove trim so index is used
                                                                  WHERE  trx_number = 'On Account');
                        --WHERE TRIM (trx_number) = 'On Account');
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                ln_onacct_amt := 0;
                        END;

                        od_message('M',
                                      'Amt_Remaining:'
                                   || ln_amt_rem
                                   || ' On Acct Amt:'
                                   || ln_onacct_amt);
                        ln_amt_rem :=   NVL(ln_amt_rem,
                                            0)
                                      - NVL(ln_onacct_amt,
                                            0);
                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        lc_err := 'Y';

                        UPDATE xx_ar_refund_trx_tmp
                        SET error_flag = 'Y',
                            last_update_date = SYSDATE,
                            last_updated_by = fnd_profile.VALUE('USER_ID'),
                            last_update_login = fnd_profile.VALUE('LOGIN_ID')
                        WHERE  refund_header_id = v_trx.refund_header_id;

                        INSERT INTO xx_ar_refund_error_log
                                    (conc_request_id,
                                     err_code,
                                     customer_number,
                                     trx_type,
                                     trx_number)
                             VALUES (ln_conc_request_id,
                                     'R0008',
                                     v_refund_hdr.customer_number,
                                     lc_trx_type,
                                     v_trx.trx_number);
                END;

            -- if the amount due remaining <> refund amount.
            -- This is possible if applications/adjustments/unapplications
            -- occur after creation of refund record
--V 5.0  -- AND v_trx.identification_type != 'OM'  added
--            IF ln_amt_rem <> v_trx.refund_amount THEN
--            IF ln_amt_rem <> v_trx.refund_amount AND v_trx.identification_type != 'OM' THEN
-- V 5.2 v_trx.identification_type removed and nvl(v_trx.ref_mailcheck_id,0) added for all old records and new NON 'OM' by Gaurav Agarwal
                IF ln_amt_rem <> v_trx.refund_amount AND NVL(v_trx.ref_mailcheck_id,
                                                             0) = 0
                THEN
                    lc_err := 'Y';
                    od_message('M',
                                  '*** Remaining Amount:'
                               || ln_amt_rem
                               || ' does not match Refund Amount:'
                               || v_trx.refund_amount);

                    IF v_trx.trx_type = 'R' AND ln_onacct_amt <> 0
                    THEN
                        UPDATE xx_ar_refund_trx_tmp
                        SET error_flag = 'Y',
                            last_update_date = SYSDATE,
                            last_updated_by = fnd_profile.VALUE('USER_ID'),
                            last_update_login = fnd_profile.VALUE('LOGIN_ID')
                        WHERE  refund_header_id = v_trx.refund_header_id;

                        INSERT INTO xx_ar_refund_error_log
                                    (conc_request_id,
                                     err_code,
                                     customer_number,
                                     trx_type,
                                     trx_number,
                                     attribute1,
                                     attribute2,
                                     attribute3)
                             VALUES (ln_conc_request_id,
                                     'R0009',
                                     v_refund_hdr.customer_number,
                                     lc_trx_type,
                                     v_trx.trx_number,
                                     TO_CHAR(ABS(ln_onacct_amt)),
                                     v_trx.refund_amount,
                                     ln_amt_rem);
                    ELSE
                        UPDATE xx_ar_refund_trx_tmp
                        SET error_flag = 'Y',
                            last_update_date = SYSDATE,
                            last_updated_by = fnd_profile.VALUE('USER_ID'),
                            last_update_login = fnd_profile.VALUE('LOGIN_ID')
                        WHERE  refund_header_id = v_trx.refund_header_id;

                        INSERT INTO xx_ar_refund_error_log
                                    (conc_request_id,
                                     err_code,
                                     customer_number,
                                     trx_type,
                                     trx_number,
                                     attribute1,
                                     attribute2)
                             VALUES (ln_conc_request_id,
                                     'R0001',
                                     v_refund_hdr.customer_number,
                                     lc_trx_type,
                                     v_trx.trx_number,
                                     TO_CHAR(v_trx.refund_amount),
                                     TO_CHAR(ABS(ln_amt_rem)));
                    END IF;
                END IF;

                -- If alternate address is indicated, check if it has been entered.
                -- Or check if a primary bill-to is specified.
                IF     NVL(v_trx.escheat_flag,
                           'N') = 'N'
                   AND TRIM(v_trx.alt_address1) IS NULL
                   AND TRIM(v_trx.alt_city) IS NULL
                   AND (TRIM(v_trx.alt_state) IS NULL OR TRIM(v_trx.alt_province) IS NULL)
                THEN
                    IF NVL(v_trx.refund_alt_flag,
                           'N') = 'Y' OR v_trx.primary_bill_loc_id IS NULL
                    THEN
                        -- don't check address on OM mailchecks when they're
                        --   flagged for over/short or other adjustments
                        -- defect 11486 - B.Looman - 09/24/08
                        IF NOT(    v_trx.identification_type = 'OM'
                               AND v_trx.om_hold_status != 'P'
                               AND v_trx.om_delete_status != 'N')
                        THEN
                            lc_err := 'Y';

                            UPDATE xx_ar_refund_trx_tmp
                            SET error_flag = 'Y',
                                last_update_date = SYSDATE,
                                last_updated_by = fnd_profile.VALUE('USER_ID'),
                                last_update_login = fnd_profile.VALUE('LOGIN_ID')
                            WHERE  refund_header_id = v_trx.refund_header_id;

                            INSERT INTO xx_ar_refund_error_log
                                        (conc_request_id,
                                         err_code,
                                         customer_number,
                                         trx_type,
                                         trx_number,
                                         attribute1)
                                 VALUES (ln_conc_request_id,
                                         'R0011',
                                         v_trx.customer_number,
                                         lc_trx_type,
                                         v_trx.trx_number,
                                         DECODE(v_trx.refund_alt_flag,
                                                'Y', 'Alternate',
                                                'Primary Bill-To'));
                        END IF;
                    END IF;
                END IF;

                IF v_trx.activity_type IS NULL
                THEN
                    lc_err := 'Y';

                    UPDATE xx_ar_refund_trx_tmp
                    SET error_flag = 'Y',
                        last_update_date = SYSDATE,
                        last_updated_by = fnd_profile.VALUE('USER_ID'),
                        last_update_login = fnd_profile.VALUE('LOGIN_ID')
                    WHERE  refund_header_id = v_trx.refund_header_id;

                    INSERT INTO xx_ar_refund_error_log
                                (conc_request_id,
                                 err_code,
                                 customer_number,
                                 trx_type,
                                 trx_number)
                         VALUES (ln_conc_request_id,
                                 'R0014',
                                 v_trx.customer_number,
                                 lc_trx_type,
                                 v_trx.trx_number);
                END IF;

                IF lc_err = 'N'
                THEN
                    -- If credit memo
                    lc_reason_code := NULL;
                    lc_comments := NULL;

                    --  IF v_trx.trx_type = 'C' THEN    Commented for CR 697/698 R1.2
                    IF v_trx.trx_type = 'C' OR v_trx.trx_type = 'I'
                    THEN                                                                   -- Added for CR 697/698 R1.2
                        IF NVL(v_trx.escheat_flag,
                               'N') = 'N'
                        THEN
                            IF NVL(v_trx.refund_alt_flag,
                                   'N') = 'Y'
                            THEN
                                lc_reason_code := 'REFUND ALT';
                                lc_comments :=
                                       ';'
                                    || v_trx.alt_address1
                                    || ' '
                                    || v_trx.alt_address2
                                    || ' '
                                    || v_trx.alt_address3
                                    || ' '
                                    || v_trx.alt_city
                                    || ' '
                                    || NVL(v_trx.alt_state,
                                           v_trx.alt_province)
                                    || ' '
                                    || v_trx.alt_postal_code
                                    || ' '
                                    || v_trx.alt_country;
                            ELSE
                                lc_reason_code := 'REFUND';
                                lc_comments := NULL;
                            END IF;
                        END IF;

                        x_return_status := NULL;
                        x_msg_data := NULL;
                        x_msg_count := NULL;
                        create_cm_adjustment(ln_ps_id,
                                             v_trx.trx_id,
                                             v_refund_hdr.customer_number,
                                             v_trx.refund_amount,
                                             ln_org_id,
                                             v_trx.activity_type                                        --lc_cm_adj_name
                                                                ,
                                             lc_reason_code,
                                             lc_comments,
                                             lc_adj_num,
                                             x_return_status,
                                             x_msg_count,
                                             x_msg_data);
                        od_message('M',
                                      'After Create CM Adjustment for:'
                                   || v_trx.trx_number
                                   || ' for :'
                                   || v_trx.trx_currency_code
                                   || ' '
                                   || v_trx.refund_amount
                                   || ' Status:'
                                   || x_return_status
                                   || ' Message:'
                                   || x_msg_count
                                   || ':'
                                   || x_msg_data);

                        -- If return message from API is not null
                        -- IF x_msg_data IS NOT NULL
                        -- THEN
                        --   lc_err    := 'Y';
                        IF NVL(x_return_status,
                               fnd_api.g_ret_sts_success) = fnd_api.g_ret_sts_success
                        THEN
                            -- Adjustment Created, but could be with warnings.
                            -- For Example when submitted for approval.
                            od_message('M',
                                          'Adj Api returned Success. Msg Count:'
                                       || x_msg_count);

                            IF NVL(x_msg_count,
                                   0) > 0
                            THEN
                                lc_err := 'N';
                                lc_adj_warning := 'Y';

                                UPDATE xx_ar_refund_trx_tmp
                                SET error_flag = 'Y',
                                    remarks = x_msg_data,
                                    last_update_date = SYSDATE,
                                    last_updated_by = fnd_profile.VALUE('USER_ID'),
                                    last_update_login = fnd_profile.VALUE('LOGIN_ID')
                                WHERE  refund_header_id = v_trx.refund_header_id;

                                INSERT INTO xx_ar_refund_error_log
                                            (conc_request_id,
                                             err_code,
                                             customer_number,
                                             trx_type,
                                             trx_number,
                                             attribute1)
                                     VALUES (ln_conc_request_id,
                                             'R0004',
                                             v_refund_hdr.customer_number,
                                             lc_trx_type,
                                             v_trx.trx_number,
                                             SUBSTR(x_msg_data,
                                                    1,
                                                    1000));
                            END IF;
                        ELSIF NVL(x_return_status,
                                  fnd_api.g_ret_sts_success) <> fnd_api.g_ret_sts_success
                        THEN
                            lc_err := 'Y';

                            IF NVL(x_msg_data,
                                   'x') IN('R0007')
                            THEN
                                UPDATE xx_ar_refund_trx_tmp
                                SET error_flag = 'Y',
                                    last_update_date = SYSDATE,
                                    last_updated_by = fnd_profile.VALUE('USER_ID'),
                                    last_update_login = fnd_profile.VALUE('LOGIN_ID')
                                WHERE  refund_header_id = v_trx.refund_header_id;

                                INSERT INTO xx_ar_refund_error_log
                                            (conc_request_id,
                                             err_code,
                                             customer_number,
                                             trx_type,
                                             trx_number,
                                             attribute1)
                                     VALUES (ln_conc_request_id,
                                             x_msg_data,
                                             v_refund_hdr.customer_number,
                                             lc_trx_type,
                                             v_trx.trx_number,
                                             v_trx.activity_type);
                            ELSE
                                UPDATE xx_ar_refund_trx_tmp
                                SET error_flag = 'Y',
                                    last_update_date = SYSDATE,
                                    last_updated_by = fnd_profile.VALUE('USER_ID'),
                                    last_update_login = fnd_profile.VALUE('LOGIN_ID')
                                WHERE  refund_header_id = v_trx.refund_header_id;

                                INSERT INTO xx_ar_refund_error_log
                                            (conc_request_id,
                                             err_code,
                                             customer_number,
                                             trx_type,
                                             trx_number,
                                             attribute1)
                                     VALUES (ln_conc_request_id,
                                             'R0003',
                                             v_refund_hdr.customer_number,
                                             lc_trx_type,
                                             v_trx.trx_number,
                                             SUBSTR(x_msg_data,
                                                    1,
                                                    1000));
                            END IF;
                        END IF;

                        IF NVL(lc_err,
                               'N') = 'N'
                        THEN
                            od_message('M',
                                          'Success creating CM Adjustment '
                                       || lc_adj_num);

                            UPDATE xx_ar_refund_trx_tmp
                            SET adjustment_number = lc_adj_num,
                                adj_created_flag = 'Y',
                                adj_creation_date = SYSDATE,
                                error_flag = NVL(lc_adj_warning,
                                                 'N'),
                                last_update_date = SYSDATE,
                                last_updated_by = fnd_profile.VALUE('USER_ID'),
                                last_update_login = fnd_profile.VALUE('LOGIN_ID')
                            WHERE CURRENT OF c_trx;

                            -- Update DFF2 to show status.
                            UPDATE ra_customer_trx_all
                            SET attribute10 = 'Refund Adjustment',
                                last_update_date = SYSDATE                                              -- Defect #13458
                                                          ,
                                last_updated_by = fnd_profile.VALUE('USER_ID')                         -- Defect # 13458
                            WHERE  customer_trx_id = v_trx.trx_id;
                        ELSE                                                                             -- Lc_error='Y'
                            -- ln_errors_count    := NVL(ln_errors_count, 0) + 1;
                            od_message('M',
                                          '*** Error - Refund could not be created for TRX:'
                                       || v_trx.trx_type
                                       || '/'
                                       || v_trx.trx_number);
                        END IF;
                    ELSE                                                                                     -- Receipt.
                        IF NVL(v_trx.escheat_flag,
                               'N') = 'Y'
                        THEN
                            FOR v_unapp_trx IN c_trx_to_unapply(v_trx.trx_id)
                            LOOP
                                IF v_unapp_trx.trx_number = 'On Account'
                                THEN
                                    od_message('M',
                                                  'Unapply On Account of '
                                               || v_unapp_trx.amount_applied
                                               || ' for receipt:'
                                               || v_trx.trx_number);
                                    x_return_status := NULL;
                                    x_msg_data := NULL;
                                    x_msg_count := NULL;
                                    unapply_on_account(v_unapp_trx.receivable_application_id,
                                                       x_return_status,
                                                       x_msg_count,
                                                       x_msg_data);
                                ELSIF v_unapp_trx.trx_number = 'Prepayment'
                                THEN
                                    od_message('M',
                                                  'Unapply Prepayment of '
                                               || v_unapp_trx.amount_applied
                                               || ' for receipt:'
                                               || v_trx.trx_number
                                               || ' - recv_appl_id = '
                                               || v_unapp_trx.receivable_application_id);
                                    x_return_status := NULL;
                                    x_msg_data := NULL;
                                    x_msg_count := NULL;
                                    unapply_prepayment(v_unapp_trx.receivable_application_id,
                                                       x_return_status,
                                                       x_msg_count,
                                                       x_msg_data);
                                ELSE
                                    od_message('M',
                                                  '*** Warning: Non Prepayment/On-Account application'
                                               || ' found for trx:'
                                               || v_trx.trx_number);
                                END IF;
                            END LOOP;
                        ELSE                                                                            -- Non-Escheats.
                            IF NVL(v_trx.refund_alt_flag,
                                   'N') = 'Y'
                            THEN
                                lc_reason_code := 'REFUND ALT';
                                lc_comments :=
                                       ';'
                                    || v_trx.alt_address1
                                    || ' '
                                    || v_trx.alt_address2
                                    || ' '
                                    || v_trx.alt_address3
                                    || ' '
                                    || v_trx.alt_city
                                    || ' '
                                    || NVL(v_trx.alt_state,
                                           v_trx.alt_province)
                                    || ' '
                                    || v_trx.alt_postal_code
                                    || ' '
                                    || v_trx.alt_country;
                            ELSE
                                lc_reason_code := 'REFUND';
                                lc_comments := NULL;
                            END IF;
                        END IF;

                        -- V4.0, Added to check payment method for Store Refund
                        IF     NVL(v_trx.identification_type,
                                   'x') = 'OM'
                           AND INSTR(NVL(v_trx.payment_method_name,
                                         'XXX'),
                                     'MAILCHECK') > 0
                        THEN
                            ln_mail_check := 1;
                        END IF;

                        -- If On-Account/Pre-Pay unapp is successful create Rcpt W/off
                        IF     NVL(x_return_status,
                                   fnd_api.g_ret_sts_success) = fnd_api.g_ret_sts_success
                           -- V4.0, Added condition to not perform Write-Off for Store Refund where payment method is 'MMAILCHECK'
                           AND ln_mail_check = 0
                        --On-Account/Prepayment
                        THEN
                            x_return_status := NULL;
                            x_msg_data := NULL;
                            x_msg_count := NULL;
                            -- No errors if Unapplying for Escheat.
                            create_receipt_writeoff(v_refund_hdr.refund_header_id           --Added for the Defect #3340
                                                                                 ,
                                                    v_trx.trx_id,
                                                    v_refund_hdr.customer_number,
                                                    v_trx.refund_amount,
                                                    ln_org_id,
                                                    v_trx.activity_type,
                                                    lc_reason_code,
                                                    lc_comments,
                                                    NVL(v_trx.escheat_flag,
                                                        'N'),
                                                    lc_adj_num,
                                                    x_return_status,
                                                    x_msg_count,
                                                    x_msg_data);

                            IF NVL(x_return_status,
                                   fnd_api.g_ret_sts_success) <> fnd_api.g_ret_sts_success
                            --Receipt Write-off  was not successful
                            THEN
                                lc_err := 'Y';

                                IF NVL(x_msg_data,
                                       'x') IN('R0012')
                                THEN
                                    UPDATE xx_ar_refund_trx_tmp
                                    SET error_flag = 'Y',
                                        last_update_date = SYSDATE,
                                        last_updated_by = fnd_profile.VALUE('USER_ID'),
                                        last_update_login = fnd_profile.VALUE('LOGIN_ID')
                                    WHERE  refund_header_id = v_trx.refund_header_id;

                                    INSERT INTO xx_ar_refund_error_log
                                                (conc_request_id,
                                                 err_code,
                                                 customer_number,
                                                 trx_type,
                                                 trx_number,
                                                 attribute1)
                                         VALUES (ln_conc_request_id,
                                                 SUBSTR(x_msg_data,
                                                        1,
                                                        5),
                                                 v_refund_hdr.customer_number,
                                                 lc_trx_type,
                                                 v_trx.trx_number,
                                                 v_trx.activity_type);
                                ELSIF x_msg_data IN('R0013')
                                THEN
                                    UPDATE xx_ar_refund_trx_tmp
                                    SET error_flag = 'Y',
                                        last_update_date = SYSDATE,
                                        last_updated_by = fnd_profile.VALUE('USER_ID'),
                                        last_update_login = fnd_profile.VALUE('LOGIN_ID')
                                    WHERE  refund_header_id = v_trx.refund_header_id;

                                    INSERT INTO xx_ar_refund_error_log
                                                (conc_request_id,
                                                 err_code,
                                                 customer_number,
                                                 trx_type,
                                                 trx_number,
                                                 attribute1)
                                         VALUES (ln_conc_request_id,
                                                 SUBSTR(x_msg_data,
                                                        1,
                                                        100),
                                                 v_refund_hdr.customer_number,
                                                 lc_trx_type,
                                                 v_trx.trx_number,
                                                 'Receipt Write-off');
                                ELSE
                                    UPDATE xx_ar_refund_trx_tmp
                                    SET error_flag = 'Y',
                                        last_update_date = SYSDATE,
                                        last_updated_by = fnd_profile.VALUE('USER_ID'),
                                        last_update_login = fnd_profile.VALUE('LOGIN_ID')
                                    WHERE  refund_header_id = v_trx.refund_header_id;

                                    INSERT INTO xx_ar_refund_error_log
                                                (conc_request_id,
                                                 err_code,
                                                 customer_number,
                                                 trx_type,
                                                 trx_number,
                                                 attribute1,
                                                 attribute2)
                                         VALUES (ln_conc_request_id,
                                                 'R0005',
                                                 v_refund_hdr.customer_number,
                                                 lc_trx_type,
                                                 v_trx.trx_number,
                                                    v_trx.trx_currency_code
                                                 || ' '
                                                 || v_trx.refund_amount,
                                                 SUBSTR(x_msg_data,
                                                        1,
                                                        1000));
                                END IF;

                                od_message('M',
                                              '**Error Creating Receipt Write-Off: '
                                           || x_msg_data);
                            ELSE
                                od_message('M',
                                              'After Create Receipt Write-off for:'
                                           || v_trx.trx_number
                                           || ' for :'
                                           || v_trx.trx_currency_code
                                           || ' '
                                           || v_trx.refund_amount
                                           || ' Status:'
                                           || x_return_status
                                           || ' Message:'
                                           || x_msg_count
                                           || ':'
                                           || x_msg_data);
                                od_message('M',
                                              'Receivable_Application_ID for Receipt write-off:'
                                           || lc_adj_num);
                            END IF;
                        ELSIF ln_mail_check = 0
                        THEN                                      -- V4.0, Added as it doesn't go thru Write Off Process
                            --On-Account/Prepayment application error
                            lc_err := 'Y';

                            IF NVL(x_msg_data,
                                   'x') IN('R0010')
                            THEN
                                UPDATE xx_ar_refund_trx_tmp
                                SET error_flag = 'Y',
                                    last_update_date = SYSDATE,
                                    last_updated_by = fnd_profile.VALUE('USER_ID'),
                                    last_update_login = fnd_profile.VALUE('LOGIN_ID')
                                WHERE  refund_header_id = v_trx.refund_header_id;

                                INSERT INTO xx_ar_refund_error_log
                                            (conc_request_id,
                                             err_code,
                                             customer_number,
                                             trx_type,
                                             trx_number,
                                             attribute1)
                                     VALUES (ln_conc_request_id,
                                             SUBSTR(x_msg_data,
                                                    1,
                                                    5),
                                             v_refund_hdr.customer_number,
                                             lc_trx_type,
                                             v_trx.trx_number,
                                             SUBSTR(x_msg_data,
                                                    7,
                                                    1000));
                            ELSE
                                UPDATE xx_ar_refund_trx_tmp
                                SET error_flag = 'Y',
                                    last_update_date = SYSDATE,
                                    last_updated_by = fnd_profile.VALUE('USER_ID'),
                                    last_update_login = fnd_profile.VALUE('LOGIN_ID')
                                WHERE  refund_header_id = v_trx.refund_header_id;

                                INSERT INTO xx_ar_refund_error_log
                                            (conc_request_id,
                                             err_code,
                                             customer_number,
                                             trx_type,
                                             trx_number,
                                             attribute1,
                                             attribute2)
                                     VALUES (ln_conc_request_id,
                                             'R0005',
                                             v_refund_hdr.customer_number,
                                             lc_trx_type,
                                             v_trx.trx_number,
                                                v_trx.trx_currency_code
                                             || ' '
                                             || v_trx.refund_amount,
                                             SUBSTR(x_msg_data,
                                                    1,
                                                    1000));
                            END IF;
                        END IF;
                    END IF;

                    IF lc_err = 'N'
                    THEN
                        IF ln_mail_check = 0
                        THEN                   -- V4.0, Added to not count the adjustment/wrote off for store mailcheck
                            ln_refunds_count :=   NVL(ln_refunds_count,
                                                      0)
                                                + 1;
                            ln_refund_amounts_tot :=   NVL(ln_refund_amounts_tot,
                                                           0)
                                                     + v_trx.refund_amount;
                        END IF;                                                                                  -- v4.0

                        -- Customer # (10)  Customer Name (25) Type (10)
                        -- Transaction Number (20)  Refund Amount (15)
                        -- Adjustment# (12)   Status (10)   Escheat(7)
                        BEGIN
                            UPDATE xx_ar_refund_trx_tmp
                            SET adjustment_number = lc_adj_num,
                                adj_created_flag = 'Y',
                                status = 'A',
                                adj_creation_date = SYSDATE,
                                error_flag = NVL(lc_adj_warning,
                                                 'N'),
                                last_update_date = SYSDATE,
                                last_updated_by = fnd_profile.VALUE('USER_ID'),
                                last_update_login = fnd_profile.VALUE('LOGIN_ID')
                            WHERE CURRENT OF c_trx;

                            IF ln_refunds_count = 1
                            THEN
                                od_message('O',
                                           'Adjustments/Write-off Created for the following Transactions');
                                od_message('O',
                                           ' ');
                                od_message('O',
                                           g_print_line);
                                -- Customer # (10)  Customer Name (25) Type (12)
                                -- Transaction Number (15)  Refund Amount (15)
                                -- Adjustment# (20)   Status (15)  E(1)
                                od_message('O',
                                              'Customer# '
                                           || 'Payee                    '
                                           || 'Trx Type    '
                                           || 'Trx Number     '
                                           || ' Refund Amount '
                                           || 'Adjustment#         '
                                           || 'Status       '
                                           || 'Escheat');
                                od_message('O',
                                           g_print_line);
                            END IF;

                            od_message('O',
                                          RPAD(SUBSTR(v_refund_hdr.customer_number,
                                                      1,
                                                      10),
                                               10,
                                               ' ')
                                       || RPAD(SUBSTR(v_trx.payee_name,
                                                      1,
                                                      25),
                                               25,
                                               ' ')
                                       || RPAD(lc_trx_type,
                                               12,
                                               ' ')
                                       || RPAD(SUBSTR(v_trx.trx_number,
                                                      1,
                                                      15),
                                               15,
                                               ' ')
                                       || LPAD(TO_CHAR(v_trx.refund_amount,
                                                       '99G999G990D00PR'),
                                               15,
                                               ' ')
                                       || RPAD(SUBSTR(lc_adj_num,
                                                      1,
                                                      20),
                                               20,
                                               ' ')
                                       || '   '
                                       || RPAD(v_trx.status,
                                               11,
                                               ' ')
                                       || '  '
                                       || v_trx.escheat_flag);

                            BEGIN
                                lc_err_loc := 'Update DFF2 value on Receipt';

                                -- Update DFF2 to show status.
                                UPDATE ar_cash_receipts_all acr
                                SET attribute10 = 'Refund Adjustment',
                                    last_update_date = SYSDATE                                          -- Defect #13458
                                                              ,
                                    last_updated_by = fnd_profile.VALUE('USER_ID')                     -- Defect # 13458
                                WHERE  cash_receipt_id = v_trx.trx_id;

                                lc_err_loc := 'Update process code and OM DFF for Receipt';

                                -- Update OM DFF Status to show status.
                                IF v_trx.identification_type = 'OM' AND v_trx.trx_type = 'R'
                                THEN
                                    UPDATE ar_cash_receipts_all acr
                                    SET attribute13 =    'WRITTEN OFF|'
                                                      || TO_CHAR(SYSDATE,
                                                                 'RRRR/MM/DD HH24:MI:SS')
                                    WHERE  cash_receipt_id = v_trx.trx_id;

                                    UPDATE xx_ar_mail_check_holds
                                    SET ar_cash_receipt_id = v_trx.trx_id,
                                        process_code = 'APPLIED'
                                    WHERE  ar_cash_receipt_id IS NULL
                                    AND    process_code = 'PENDING'
                                    AND    NVL(aops_order_number,
                                               pos_transaction_number) = (SELECT attribute7
                                                                          FROM   ar_cash_receipts_all
                                                                          WHERE  cash_receipt_id = v_trx.trx_id);
                                END IF;
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    od_message('M',
                                                  'Warning: Could not update DFF on Cash Receipt.'
                                               || SQLCODE
                                               || ':'
                                               || SQLERRM);
                            END;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                od_message('M',
                                              '*** Error updating adjustment created flag and'
                                           || ' status after creating adjustment. Error:'
                                           || SQLCODE
                                           || ':'
                                           || SQLERRM);
                        END;
                    END IF;
                ELSE                                                              -- if pre adjust/write-off error = 'N'
                    od_message('M',
                                  '*** Error (Pre-Loop)- Refund could not be created for TRX:'
                               || v_trx.trx_type
                               || '/'
                               || v_trx.trx_number);
                END IF;                                                                                  -- if err = 'N'

                IF lc_err = 'Y'
                THEN
                    ln_errors_count :=   NVL(ln_errors_count,
                                             0)
                                       + 1;
                END IF;
            END LOOP;
        END LOOP;
		
		IF(p_user_id is null) -- Defect#37226 - Added IF condition to restrict procedure call for manually submitted requests
		THEN
			update_dffs;
		END IF;
			
        IF ln_refunds_count > 0
        THEN
            od_message('O',
                       ' ');
            od_message('O',
                       g_print_line);
            od_message('O',
                          RPAD(' ',
                               10,
                               ' ')
                       || RPAD(' ',
                               25,
                               ' ')
                       || RPAD(' ',
                               10,
                               ' ')
                       || LPAD('    Total:  ',
                               15,
                               ' ')
                       || ' '
                       || LPAD(TO_CHAR(ln_refund_amounts_tot,
                                       '9G999G990D00PR'),
                               16,
                               ' '));
            od_message('O',
                       ' ');
        END IF;

----------------------------------------------
--Start of Changes for the Defect #3340
----------------------------------------------
        IF (gn_tot_receipt_writeoff > 0)
        THEN
            od_message('O',
                       '');
            od_message('O',
                       '');
            od_message('O',
                       '');
            od_message('O',
                       g_print_line);
            od_message('O',
                       '                                                 Refunds to be Reclassified ');
            /*od_message('O', g_print_line);            --Commented for defect 4348
            od_message('O'
                      ,'Receipt Number|'
                       ||'Receipt Date|'
                       ||'Store Number|'
                       ||'Refund Amount|'
                       ||'Currency|'
                       ||'Account Dr|'
                       ||'Account Cr'
                      );*/
            od_message('O',
                       g_print_line);                                       --Modified on 28-DEC-09 -- Moved out of LOOP

            FOR cntr IN 1 ..   gn_count
                             - 1
            LOOP
                           --od_message('O'                                     --Commented for Defect #3340 on 19-JAN-09
                --Commented for defect #4348
                    /*FND_FILE.PUT_LINE (FND_FILE.OUTPUT,gt_receipt_writeoff(cntr).receipt_number
                                      ||'|'
                                      ||gt_receipt_writeoff(cntr).receipt_date
                                      ||'|'
                                      ||gt_receipt_writeoff(cntr).store_number
                                      ||'|'
                                      ||gt_receipt_writeoff(cntr).refund_amount
                                      ||'|'
                                      ||gt_receipt_writeoff(cntr).currency
                                      ||'|'
                                      ||gt_receipt_writeoff(cntr).account_cr    -- Swaped CR and DR as generic account needs to show as account Dr in the output
                                      ||'|'
                                      ||gt_receipt_writeoff(cntr).account_dr    -- Swaped CR and DR as generic account needs to show as account Dr in the output
                                     );*/

                --Added for defect #4348
                fnd_file.put_line(fnd_file.output,
                                     gt_receipt_writeoff(cntr).account_dr     -- Modified for defect # 4348 on 4/29/2010
                                  || '|'
                                  || gt_receipt_writeoff(cntr).refund_amount
                                  || '||'                                     -- Modified for defect # 4348 on 4/29/2010
                                  || gt_receipt_writeoff(cntr).receipt_date
                                  || '|'
                                  || gt_receipt_writeoff(cntr).description
                                  || '|'
                                  || gt_receipt_writeoff(cntr).location_description
                                  || '|'
                                  || gt_receipt_writeoff(cntr).location_dr             -- Modified for 4348 on 4/29/2010
                                  || '|'
                                  || gt_receipt_writeoff(cntr).meaning_debit
                                  || '|'
                                  || gt_receipt_writeoff(cntr).account_seg_dr);
--Added for defect #4348
                fnd_file.put_line(fnd_file.output,
                                     gt_receipt_writeoff(cntr).account_cr     -- Modified for defect # 4348 on 4/29/2010
                                  || '||'                                     -- Modified for defect # 4348 on 4/29/2010
                                  || gt_receipt_writeoff(cntr).refund_amount
                                  || '|'
                                  || gt_receipt_writeoff(cntr).receipt_date
                                  || '|'
                                  || gt_receipt_writeoff(cntr).description
                                  || '|'
                                  || gt_receipt_writeoff(cntr).location_description
                                  || '|'
                                  || gt_receipt_writeoff(cntr).location_cr             -- Modified for 4348 on 4/29/2010
                                  || '|'
                                  || gt_receipt_writeoff(cntr).meaning_credit
                                  || '|'
                                  || gt_receipt_writeoff(cntr).account_seg_cr);
            END LOOP;
        ELSE
            od_message('O',
                       '');
            od_message('O',
                       '');
            od_message('O',
                       '');
            od_message('O',
                       g_print_line);
            od_message('O',
                       '                                                 Refunds to be Reclassified ');
            od_message('O',
                       g_print_line);
            od_message('O',
                       '*** No Receipt Write OFF done using Generic Receivable Activity ***');
        END IF;

----------------------------------------------
--End of Changes for the Defect #3340
----------------------------------------------
        IF ln_errors_count > 0
        THEN
            print_errors(ln_conc_request_id);
        END IF;

        od_message('O',
                   '');
        od_message('O',
                   '');
        od_message('O',
                   '');
        od_message('O',
                   g_print_line);
        od_message('O',
                   '                                                 Process Summary ');
        od_message('O',
                   g_print_line);
        od_message('O',
                      'Number of refunds successfully Created          :'
                   || ln_refunds_count);
        od_message('O',
                      'Total Amount of refunds successfully Created    :'
                   || ln_refund_amounts_tot);
        od_message('O',
                      'Number of errors when creating refunds          :'
                   || ln_errors_count);
    EXCEPTION
        WHEN OTHERS
        THEN
            raise_application_error(-20000,
                                       '**** Error:'
                                    || SQLCODE
                                    || ':'
                                    || SQLERRM);
    END;

    PROCEDURE create_cm_adjustment(
        p_payment_schedule_id  IN             NUMBER,
        p_customer_trx_id      IN             NUMBER,
        p_customer_number      IN             VARCHAR2,
        p_amount               IN             NUMBER,
        p_org_id               IN             NUMBER,
        p_adj_name             IN             VARCHAR2,
        p_reason_code          IN             VARCHAR2,
        p_comments             IN             VARCHAR2,
        o_adj_num              OUT NOCOPY     VARCHAR2,
        x_return_status        OUT NOCOPY     VARCHAR2,
        x_msg_count            OUT NOCOPY     NUMBER,
        x_msg_data             OUT NOCOPY     VARCHAR2)
    IS
        lr_adj_rec      ar_adjustments%ROWTYPE;
        lc_adj_num      ar_adjustments.adjustment_number%TYPE;
        ln_adj_id       ar_adjustments.adjustment_id%TYPE;
        ln_activity_id  ar_receivables_trx_all.receivables_trx_id%TYPE;
        ln_line_amt     ra_customer_trx_lines_all.extended_amount%TYPE;
        ln_amt          ra_customer_trx_lines_all.extended_amount%TYPE;
        lc_api_err_msg  VARCHAR2(2000);
        lc_adj_status   ar_adjustments_all.status%TYPE;
    BEGIN
        SELECT receivables_trx_id
        INTO   ln_activity_id
        FROM   ar_receivables_trx r
        WHERE  TRIM(r.NAME) = p_adj_name AND org_id = p_org_id AND status = 'A';

        od_message('M',
                      'CM Adjustment Name: '
                   || p_adj_name);
        o_adj_num := NULL;
        lr_adj_rec.TYPE := 'INVOICE';
        lr_adj_rec.payment_schedule_id := p_payment_schedule_id;
        lr_adj_rec.amount := p_amount;
        lr_adj_rec.customer_trx_id := p_customer_trx_id;
        lr_adj_rec.receivables_trx_id := ln_activity_id;
        lr_adj_rec.apply_date := TRUNC(SYSDATE);
        lr_adj_rec.gl_date := TRUNC(SYSDATE);
        lr_adj_rec.reason_code := p_reason_code;                                                             --'REFUND';
        lr_adj_rec.created_from := 'ADJ-API';
        lr_adj_rec.comments :=    p_reason_code
                               || p_comments;
        fnd_file.put_line(fnd_file.LOG,
                             'p_payment_schedule_id: '
                          || p_payment_schedule_id);
        fnd_file.put_line(fnd_file.LOG,
                             'p_amount: '
                          || p_amount);
        fnd_file.put_line(fnd_file.LOG,
                             'p_customer_trx_id: '
                          || p_customer_trx_id);
        fnd_file.put_line(fnd_file.LOG,
                             'ln_activity_id: '
                          || ln_activity_id);
        fnd_file.put_line(fnd_file.LOG,
                             'p_reason_code: '
                          || p_reason_code);
        fnd_file.put_line(fnd_file.LOG,
                             'p_reason_code || p_comments: '
                          || p_reason_code
                          || p_comments);
        ar_adjust_pub.create_adjustment(p_api_name               => 'AR_ADJUST_PUB',
                                        p_api_version            => 1.0,
                                        p_init_msg_list          => fnd_api.g_true,
                                        p_msg_count              => x_msg_count,
                                        p_msg_data               => x_msg_data,
                                        p_return_status          => x_return_status,
                                        p_adj_rec                => lr_adj_rec,
                                        p_new_adjust_number      => lc_adj_num,
                                        p_new_adjust_id          => ln_adj_id
                                                                             -- ,p_chk_approval_limits      => fnd_api.g_false
                                       );
        o_adj_num := lc_adj_num;
-------------------
        fnd_file.put_line(fnd_file.LOG,
                             'x_msg_count: '
                          || x_msg_count);
        fnd_file.put_line(fnd_file.LOG,
                             'x_msg_data: '
                          || x_msg_data);
        fnd_file.put_line(fnd_file.LOG,
                             'x_return_status: '
                          || x_return_status);

-------------------
        IF NVL(x_return_status,
               'x') = fnd_api.g_ret_sts_success
        THEN
            od_message('M',
                          'Before Approve:'
                       || x_msg_data);
            od_message('M',
                          'Status: '
                       || x_return_status
                       || ' Count:'
                       || x_msg_count
                       || 'Data:'
                       || x_msg_data);
            x_return_status := NULL;
            x_msg_count := NULL;
            x_msg_data := NULL;

            IF lc_adj_num IS NOT NULL
            THEN
                BEGIN
                    SELECT NVL(status,
                               'X')
                    INTO   lc_adj_status
                    FROM   ar_adjustments_all
                    WHERE  adjustment_number = lc_adj_num;

                    IF lc_adj_status != 'A'
                    THEN
                        ar_adjust_pub.approve_adjustment(p_api_name                 => 'AR_ADJUST_PUB',
                                                         p_api_version              => 1.0,
                                                         p_msg_count                => x_msg_count,
                                                         p_msg_data                 => x_msg_data,
                                                         p_return_status            => x_return_status,
                                                         p_adj_rec                  => NULL,
                                                         p_chk_approval_limits      => fnd_api.g_false,
                                                         p_old_adjust_id            => ln_adj_id);
                    END IF;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        od_message('M',
                                      'Error Getting Status for Adjustment:'
                                   || lc_adj_num);
                END;
            END IF;

            od_message('M',
                          'After Approve:'
                       || x_msg_data);
            od_message('M',
                          'Status: '
                       || x_return_status
                       || ' Count:'
                       || x_msg_count
                       || 'Data:'
                       || x_msg_data);
        END IF;

        IF NVL(x_msg_count,
               0) > 0
        THEN
            FOR i IN 1 .. x_msg_count
            LOOP
                lc_api_err_msg := fnd_msg_pub.get(p_encoded      => fnd_api.g_false);
                od_message('M',
                              '*** '
                           || i
                           || ' of '
                           || x_msg_count
                           || ': '
                           || NVL(lc_api_err_msg,
                                  x_msg_data));
            END LOOP;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            od_message('M',
                          '*** CM Adjustment: '
                       || p_adj_name
                       || ' not Defined for org_id:'
                       || p_org_id);
            x_return_status := 'E';
            x_msg_data := 'R0007';
        WHEN OTHERS
        THEN
            od_message('M',
                          '*** CM Adjustment: '
                       || p_adj_name
                       || ' for org_id:'
                       || p_org_id
                       || ' Other error-'
                       || SQLERRM);
            x_return_status := 'E';
            x_msg_data := 'R0007';
    END;

    PROCEDURE create_receipt_writeoff(
        p_refund_header_id           IN             NUMBER                                      --Added for Defect #3340
                                                          ,
        p_cash_receipt_id            IN             NUMBER,
        p_customer_number            IN             VARCHAR2,
        p_amount                     IN             NUMBER,
        p_org_id                     IN             NUMBER,
        p_wo_name                    IN             VARCHAR2,
        p_reason_code                IN             VARCHAR2,
        p_comments                   IN             VARCHAR2,
        p_escheat_flag               IN             VARCHAR2,
        o_receivable_application_id  OUT NOCOPY     VARCHAR2,
        x_return_status              OUT NOCOPY     VARCHAR2,
        x_msg_count                  OUT NOCOPY     NUMBER,
        x_msg_data                   OUT NOCOPY     VARCHAR2)
    IS
        ln_activity_id                  ar_receivables_trx_all.receivables_trx_id%TYPE;
        ln_applied_payment_schedule_id  ar_payment_schedules_all.payment_schedule_id%TYPE;
        lc_application_ref_type         ar_receivable_applications.application_ref_type%TYPE;
        ln_application_ref_id           ar_receivable_applications.application_ref_id%TYPE;
        lc_application_ref_num          ar_receivable_applications.application_ref_num%TYPE;
        ln_secondary_appln_ref_id       ar_receivable_applications.secondary_application_ref_id%TYPE;
        ln_receivable_application_id    ar_receivable_applications.receivable_application_id%TYPE;
        lc_api_err_msg                  VARCHAR2(2000);
        ln_account_cr                   VARCHAR2(240)                                                  := NULL;
                                                   --Added for Defect #3340  -- Modified for defect # 4348 on 4/29/2010
        lc_meaning_credit               VARCHAR2(240);                                         --Added for defect #4348
        lc_meaning_debit                VARCHAR2(240);                                         --Added for defect #4348
        lc_description                  VARCHAR2(240);                                         --Added for defect #4348
        lc_generic_activity_type        VARCHAR2(240);                                         --Added for Defect #3340
    BEGIN
        BEGIN
            SELECT payment_schedule_id
            INTO   ln_applied_payment_schedule_id
            FROM   ar_payment_schedules
            WHERE  trx_number = 'Receipt Write-off';

--start of changes for defect #4348
            SELECT flv.meaning,
                   flv.description
            INTO   gt_receipt_writeoff(gn_count).meaning_credit,
                   gt_receipt_writeoff(gn_count).location_description
            FROM   fnd_lookup_values_vl flv
            WHERE  flv.lookup_type = 'XX_AR_REFUNDS_RECLASSIFICATION'
            AND    flv.enabled_flag = 'Y'
            AND    TRUNC(SYSDATE) BETWEEN TRUNC(flv.start_date_active) AND TRUNC(NVL(flv.end_date_active,
                                                                                       SYSDATE
                                                                                     + 1))
            AND    flv.lookup_code = 'CREDIT';

            SELECT flv.meaning,
                   flv.description
            INTO   gt_receipt_writeoff(gn_count).meaning_debit,
                   gt_receipt_writeoff(gn_count).location_description
            FROM   fnd_lookup_values_vl flv
            WHERE  flv.lookup_type = 'XX_AR_REFUNDS_RECLASSIFICATION'
            AND    flv.enabled_flag = 'Y'
            AND    TRUNC(SYSDATE) BETWEEN TRUNC(flv.start_date_active) AND TRUNC(NVL(flv.end_date_active,
                                                                                       SYSDATE
                                                                                     + 1))
            AND    flv.lookup_code = 'DEBIT';

--End of changes for defect #4348
            BEGIN
                SELECT r.receivables_trx_id,
                       r.description                                                             --Added for defect 4348
                                    ,
                       glc.segment3                                                              --Added for defect 4348
                                   ,
                       glc.segment4                                                              --Added for defect 4348
                                   ,
                          glc.segment1
                       || '|'                                      --Changed to '|'symbol instead of '.' for defect 4348
                       || glc.segment2
                       || '|'
                       || glc.segment3
                       || '|'
                       || glc.segment4
                       || '|'
                       || glc.segment5
                       || '|'
                       || glc.segment6
                       || '|'
                       || glc.segment7 "CODE_COMBINATION"                                       --Added for Defect #3340
                INTO   ln_activity_id,
                       gt_receipt_writeoff(gn_count).description                                 --Added for defect 4348
                                                                ,
                       gt_receipt_writeoff(gn_count).account_seg_cr
                                                             --Added for defect 4348   -- Modified for 4348 on 4/29/2010
                                                                   ,
                       gt_receipt_writeoff(gn_count).location_cr
                                                         --Added for defect 4348 --    -- Modified for 4348 on 4/29/2010
                                                                ,
                       gt_receipt_writeoff(gn_count).account_cr
                                                          --Added for Defect #3340     -- Modified for 4348 on 4/29/2010
                FROM   ar_receivables_trx r,
                       gl_code_combinations glc
                WHERE  TYPE = 'WRITEOFF'
                AND    TRIM(r.NAME) = p_wo_name
                AND    org_id = p_org_id
                AND    status = 'A'
                AND    glc.code_combination_id = r.code_combination_id;                         --Added for Defect #3340

                od_message('M',
                              'Receipt Write-Off Name: '
                           || p_wo_name);
                ar_receipt_api_pub.activity_application
                                                       (p_api_version                       => 1.0,
                                                        p_init_msg_list                     => fnd_api.g_true,
                                                        p_commit                            => fnd_api.g_false,
                                                        p_validation_level                  => fnd_api.g_valid_level_full,
                                                        x_return_status                     => x_return_status,
                                                        x_msg_count                         => x_msg_count,
                                                        x_msg_data                          => x_msg_data,
                                                        p_cash_receipt_id                   => p_cash_receipt_id,
                                                        p_amount_applied                    => p_amount,
                                                        p_applied_payment_schedule_id       => ln_applied_payment_schedule_id,
                                                        p_receivables_trx_id                => ln_activity_id,
                                                        p_comments                          =>    p_reason_code
                                                                                               || p_comments,
                                                        p_apply_date                        => TRUNC(SYSDATE),
                                                        p_application_ref_type              => lc_application_ref_type,
                                                        p_application_ref_id                => ln_application_ref_id,
                                                        p_application_ref_num               => lc_application_ref_num,
                                                        p_secondary_application_ref_id      => ln_secondary_appln_ref_id,
                                                        p_receivable_application_id         => ln_receivable_application_id,
                                                        p_called_from                       => 'OD Refunds Process');
                o_receivable_application_id :=    'Rcv Appl ID:'
                                               || TO_CHAR(ln_receivable_application_id);

                IF NVL(x_msg_count,
                       0) > 0
                THEN
                    FOR i IN 1 .. x_msg_count
                    LOOP
                        lc_api_err_msg := fnd_msg_pub.get(p_encoded      => fnd_api.g_false);  --Added for Defect #3340
                        --fnd_msg_pub.get (p_encoded      => fnd_api.g_true);     --Commented for Defect #3340
                        od_message('M',
                                      '*** '
                                   || i
                                   || ' of '
                                   || x_msg_count
                                   || ': '
                                   || NVL(lc_api_err_msg,
                                          x_msg_data));
                    END LOOP;

----------------------------------------------------------------------------------------
--Start of Changes for the Defect #3340
-----------------------------------------------------------------------------------------
-- OD_AR_REF_GENERIC_ACTIVTY Translation values list the generic activity name.Based on
-- the generic activity name generic activity id derived and passed to
-- the ar_receipt_api_pub.activity_application to do writeoff for those receipts
-- which is failed during Balancing Segments between two companies
------------------------------------------------------------------------------------------
                    BEGIN
                        SELECT receivables_trx_id,
                               r.description                                                     --Added for defect 4348
                                            ,
                               glc.segment3                                                      --Added for defect 4348
                                           ,
                               glc.segment4                                                      --Added for defect 4348
                                           ,
                                  glc.segment1
                               || '|'                              --Changed to '|'symbol instead of '.' for defect 4348
                               || glc.segment2
                               || '|'
                               || glc.segment3
                               || '|'
                               || glc.segment4
                               || '|'
                               || glc.segment5
                               || '|'
                               || glc.segment6
                               || '|'
                               || glc.segment7 "CODE_COMBINATION",
                               r.NAME "ACTIVITY_TYPE"
                        INTO   ln_activity_id,
                               gt_receipt_writeoff(gn_count).description                         --Added for defect 4348
                                                                        ,
                               gt_receipt_writeoff(gn_count).account_seg_dr
                                                            --Added for defect 4348    -- Modified for 4348 on 4/29/2010
                                                                           ,
                               gt_receipt_writeoff(gn_count).location_dr
                                                           --Added for defect 4348     -- Modified for 4348 on 4/29/2010
                                                                        ,
                               gt_receipt_writeoff(gn_count).account_dr                -- Modified for 4348 on 4/29/2010
                                                                       ,
                               lc_generic_activity_type
                        FROM   ar_receivables_trx r,
                               gl_code_combinations glc
                        WHERE  TYPE = 'WRITEOFF'
                        AND    org_id = p_org_id
                        AND    status = 'A'
                        AND    glc.code_combination_id = r.code_combination_id
                        AND    TRIM(r.NAME) IN(
                                   SELECT flv.description
                                   FROM   fnd_lookup_values_vl flv
                                   WHERE  flv.lookup_type = 'OD_AR_REF_GENERIC_ACTIVITY'
                                   AND    flv.enabled_flag = 'Y'
                                   AND    TRUNC(SYSDATE) BETWEEN TRUNC(flv.start_date_active)
                                                             AND TRUNC(NVL(flv.end_date_active,
                                                                             SYSDATE
                                                                           + 1))
                                   AND    p_wo_name LIKE    flv.meaning
                                                         || '%');                      --Modified to Lookup on 28-DEC-09
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            ln_activity_id := NULL;
                            od_message
                                   ('M',
                                       '*** Receipt Write-off error @OD_AR_REF_GENERIC_ACTIVTY translation derivation:'
                                    || p_wo_name
                                    || ' -Other Err - '
                                    || SQLERRM);
                    END;

                    IF (ln_activity_id IS NOT NULL)
                    THEN
                        od_message('M',
                                      'Generic Receivable Activity ID: '
                                   || ln_activity_id);
                        ar_receipt_api_pub.activity_application
                                                       (p_api_version                       => 1.0,
                                                        p_init_msg_list                     => fnd_api.g_true,
                                                        p_commit                            => fnd_api.g_false,
                                                        p_validation_level                  => fnd_api.g_valid_level_full,
                                                        x_return_status                     => x_return_status,
                                                        x_msg_count                         => x_msg_count,
                                                        x_msg_data                          => x_msg_data,
                                                        p_cash_receipt_id                   => p_cash_receipt_id,
                                                        p_amount_applied                    => p_amount,
                                                        p_applied_payment_schedule_id       => ln_applied_payment_schedule_id,
                                                        p_receivables_trx_id                => ln_activity_id,
                                                        p_comments                          =>    p_reason_code
                                                                                               || p_comments,
                                                        p_apply_date                        => TRUNC(SYSDATE),
                                                        p_application_ref_type              => lc_application_ref_type,
                                                        p_application_ref_id                => ln_application_ref_id,
                                                        p_application_ref_num               => lc_application_ref_num,
                                                        p_secondary_application_ref_id      => ln_secondary_appln_ref_id,
                                                        p_receivable_application_id         => ln_receivable_application_id,
                                                        p_called_from                       => 'OD Refunds Process');
                        o_receivable_application_id :=    'Rcv Appl ID:'
                                                       || TO_CHAR(ln_receivable_application_id);

----------------------------------------------------------------
--To track the receipts to be Reclassified in the output section
----------------------------------------------------------------
                        BEGIN
                            SELECT receipt_number
                                                 --,receipt_date                       --Commented for defect 4348
                            ,
                                   TO_CHAR(receipt_date,
                                           'RRRR-MM-DD')                                         --Added for defect 4348
                                                        ,
                                   NVL(attribute1,
                                       attribute2),
                                   currency_code
                            INTO   gt_receipt_writeoff(gn_count).receipt_number,
                                   gt_receipt_writeoff(gn_count).receipt_date,
                                   gt_receipt_writeoff(gn_count).store_number,
                                   gt_receipt_writeoff(gn_count).currency
                            FROM   ar_cash_receipts
                            WHERE  cash_receipt_id = p_cash_receipt_id;

                            --     gt_receipt_writeoff(gn_count).account_dr    := ln_account_cr;   -- Commented for Defect # 4348 on 4/29/2010
                            gt_receipt_writeoff(gn_count).refund_amount := p_amount;
                            gn_tot_receipt_writeoff :=   gn_tot_receipt_writeoff
                                                       + 1;

----------------------------------------------------------
--Update Orig_activity_type,account_dr,account_cr
----------------------------------------------------------
                            UPDATE xx_ar_refund_trx_tmp
                            SET original_activity_type = p_wo_name,
                                activity_type = lc_generic_activity_type,
                                account_orig_dr =
                                               gt_receipt_writeoff(gn_count).account_dr
                                                                                       -- Modified for 4348 on 4/29/2010
                                                                                       ,
                                account_generic_cr =
                                              gt_receipt_writeoff(gn_count).account_cr
                                                                                      --  Modified for 4348 on 4/29/2010
                                                                                      ,
                                last_update_date = SYSDATE,
                                last_updated_by = fnd_profile.VALUE('USER_ID'),
                                last_update_login = fnd_profile.VALUE('LOGIN_ID')
                            WHERE  refund_header_id = p_refund_header_id;

                            gn_count :=   gn_count
                                        + 1;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                od_message
                                         ('M',
                                             '*** Receipt Write-off error @Reclassification output derivation section:'
                                          || SQLCODE
                                          || ' -Other Err - '
                                          || SQLERRM);
                        END;                                                              --Added Exception on 28-DEC-09
                    ELSE
                        od_message
                                ('M',
                                    'Generic Receivable Activity does not exist for the Original receivable Activity: '
                                 || p_wo_name);
                    END IF;
----------------------------------------------------------
--End of Changes for the Defect #3340
----------------------------------------------------------
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    od_message('M',
                                  '*** Receipt Write-Off: '
                               || p_wo_name
                               || 'not Defined for org_id:'
                               || p_org_id);
                    x_return_status := 'E';
                    x_msg_data := 'R0012';
                WHEN OTHERS
                THEN
                    od_message('M',
                                  '*** Receipt Write-off:'
                               || p_wo_name
                               || ' -Other Err1 - '
                               || SQLERRM);
                    x_return_status := 'E';
                    x_msg_data := 'R0012';
            END;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                od_message('M',
                           '*** CRW: Receipt Write-Off: Payment Schedule not Defined');
                x_return_status := 'E';
                x_msg_data := 'R0013';
            WHEN OTHERS
            THEN
                od_message('M',
                              '*** CRW: Receipt Write-Off: Payment Schedule - Other Err2 - '
                           || SQLERRM);
                x_return_status := 'E';
                x_msg_data := 'R0013';
        END;
    END;

--------------------------------------------------------------------------------
    PROCEDURE unapply_prepayment(
        p_receivable_application_id  IN             NUMBER,
        x_return_status              OUT NOCOPY     VARCHAR2,
        x_msg_count                  OUT NOCOPY     NUMBER,
        x_msg_data                   OUT NOCOPY     VARCHAR2)
    IS
        lc_err_msg  VARCHAR2(2000);
    BEGIN
        ar_receipt_api_pub.unapply_other_account(p_api_version                    => 1.0,
                                                 p_init_msg_list                  => fnd_api.g_true,
                                                 p_commit                         => fnd_api.g_false,
                                                 p_validation_level               => fnd_api.g_valid_level_full,
                                                 x_return_status                  => x_return_status,
                                                 x_msg_count                      => x_msg_count,
                                                 x_msg_data                       => x_msg_data,
                                                 p_receivable_application_id      => p_receivable_application_id);

        IF NVL(x_msg_count,
               0) > 0
        THEN
            FOR i IN 1 .. x_msg_count
            LOOP
                lc_err_msg := fnd_msg_pub.get(p_encoded      => fnd_api.g_false);
                od_message('M',
                              '*** '
                           || i
                           || '.'
                           || SUBSTR(lc_err_msg,
                                     1,
                                     255));

                IF x_msg_data IS NOT NULL
                THEN
                    x_msg_data := SUBSTR(   x_msg_data
                                         || '/'
                                         || i
                                         || '.'
                                         || lc_err_msg,
                                         1,
                                         2000);
                ELSE
                    x_msg_data := SUBSTR(   i
                                         || '.'
                                         || lc_err_msg,
                                         1,
                                         2000);
                END IF;
            END LOOP;
        END IF;

        IF x_return_status <> 'S'
        THEN
            od_message('M',
                       '*** Error Un-Applying Pre-Payment');
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            od_message('M',
                          '*** Error Un-Applying Pre-Payment: '
                       || SQLERRM);
            x_return_status := 'E';
            x_msg_data :=    'R0010'
                          || ':'
                          || SQLCODE
                          || ':'
                          || SQLERRM;
    END;

--------------------------------------------------------------------------------
    PROCEDURE unapply_on_account(
        p_receivable_application_id  IN             NUMBER,
        x_return_status              OUT NOCOPY     VARCHAR2,
        x_msg_count                  OUT NOCOPY     NUMBER,
        x_msg_data                   OUT NOCOPY     VARCHAR2)
    IS
        lc_err_msg  VARCHAR2(2000);
    BEGIN
        od_message('M',
                   'Before Calling API for Unapplying On Account.');
        ar_receipt_api_pub.unapply_on_account(p_api_version                    => 1.0,
                                              p_init_msg_list                  => fnd_api.g_true,
                                              p_commit                         => fnd_api.g_false,
                                              p_validation_level               => fnd_api.g_valid_level_full,
                                              x_return_status                  => x_return_status,
                                              x_msg_count                      => x_msg_count,
                                              x_msg_data                       => x_msg_data,
                                              p_receivable_application_id      => p_receivable_application_id);
        od_message('M',
                      'After Calling API for Unapplying On Account-Error Count:'
                   || x_msg_count
                   || ' Error Status:'
                   || x_return_status
                   || '  Msg Data:'
                   || x_msg_data);

        IF NVL(x_msg_count,
               0) > 0
        THEN
            FOR i IN 1 .. x_msg_count
            LOOP
                lc_err_msg := fnd_msg_pub.get(p_encoded      => fnd_api.g_false);
                od_message('M',
                              '*** '
                           || i
                           || '.'
                           || SUBSTR(lc_err_msg,
                                     1,
                                     255));

                IF x_msg_data IS NOT NULL
                THEN
                    x_msg_data := SUBSTR(   x_msg_data
                                         || '/'
                                         || i
                                         || '.'
                                         || lc_err_msg,
                                         1,
                                         2000);
                ELSE
                    x_msg_data := SUBSTR(   i
                                         || '.'
                                         || lc_err_msg,
                                         1,
                                         2000);
                END IF;
            END LOOP;
        END IF;

        IF x_return_status <> 'S'
        THEN
            od_message('M',
                       'Error Un-Applying On Account');
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            od_message('M',
                          '*** Error Un-Applying On Account: '
                       || SQLERRM);
            x_return_status := 'E';
            x_msg_data :=    'R0010'
                          || ':'
                          || SQLCODE
                          || ':'
                          || SQLERRM;
    END;

--------------------------------------------------------------------------------

    -- Procedure to insert record into ap_suppliers_int table
    PROCEDURE insert_supplier_interface(
        p_refund_hdr_rec       IN             xx_ar_refund_trx_tmp%ROWTYPE,
        p_sob_name             IN             VARCHAR2,
        x_vendor_interface_id  OUT NOCOPY     NUMBER,
        x_err_mesg             OUT NOCOPY     VARCHAR2)
    IS
    BEGIN
-- Generate sequence for vendor_interface_id
        SELECT ap_suppliers_int_s.NEXTVAL
        INTO   x_vendor_interface_id
        FROM   DUAL;

-- Insert a record into ap_suppliers_int table
        INSERT INTO ap_suppliers_int
                    (vendor_interface_id,
                     vendor_name,
                     customer_num,
                     vendor_type_lookup_code,
                     one_time_flag,
                     terms_name,
                     pay_date_basis_lookup_code,
                     pay_group_lookup_code,
                     start_date_active,
                     end_date_active,
                     status,
                     terms_date_basis,
                     last_update_date,
                     last_updated_by,
                     creation_date,
                     created_by,
                     last_update_login)
             VALUES (x_vendor_interface_id,
                     p_refund_hdr_rec.payee_name,
                     p_refund_hdr_rec.customer_number,
                     'CUSTOMER',
                     'Y',
                     '00',
                     'DISCOUNT'
                               --Defect 2418 - Use US_ID_EXP_NON_DISC for Canada also.
                               --, DECODE (p_sob_name
                               --        , 'US_USD_P', 'US_OD_EXP_NON_DISC'
                               --        , 'CA_CAD_P', 'CA_OD_EXP_NON_DISC'
                               --        , NULL
                               --         )
        ,
                     'US_OD_EXP_NON_DISC'                                                                   -- Pay Group
                                         ,
                     SYSDATE,
                     NULL,
                     'NEW',
                     'Invoice',
                     SYSDATE,
                     fnd_global.user_id,
                     SYSDATE,
                     fnd_global.user_id,
                     fnd_global.conc_login_id);
    EXCEPTION
        WHEN OTHERS
        THEN
            x_err_mesg :=    'E:'
                          || SQLCODE
                          || SQLERRM;
    END;

    -- Procedure to insert a record into ap_supplier_sites_int table
    -- Either vendor_interface_id or vendor_id will be populated deoending on whether vendor already exists or not
    -- If vendor exists in PO_VENDORS table, vendor_id will be passed else vendor_interface_id will be passed
    PROCEDURE insert_supplier_site_int(
        p_refund_hdr_rec       IN             xx_ar_refund_trx_tmp%ROWTYPE,
        p_vendor_interface_id  IN             NUMBER,
        p_vendor_id            IN             NUMBER,
        p_sob_name             IN             VARCHAR2,
        x_sitecode             OUT NOCOPY     VARCHAR2,
        x_err_mesg             OUT NOCOPY     VARCHAR2)
    IS
    BEGIN
        -- Generate site code as 'RF' || sequence number
        --SELECT 'RF' || LPAD (xx_ar_refund_sitecode_s.NEXTVAL, 5, '0')    -- Commented for defect# 6311
        SELECT    'RF'
               || LPAD(xx_ar_refund_sitecode_s.NEXTVAL,
                       13,
                       '0')                                                                    -- Added for defect# 6311
        INTO   x_sitecode
        FROM   DUAL;

        -- Insert a record into ap_supplier_sites_int table
        INSERT INTO ap_supplier_sites_int
                    (vendor_interface_id,
                     vendor_id,
                     vendor_site_code,
                     address_line1,
                     address_line2,
                     address_line3,
                     city,
                     state,
                     province,
                     country,
                     zip,
                     terms_name,
                     purchasing_site_flag,
                     pay_site_flag,
                     org_id,
                     status,
                     terms_date_basis,
                     pay_date_basis_lookup_code,
                     pay_group_lookup_code,
                     payment_method_lookup_code,
                     attribute8                                                                        -- Site Category.
                               ,
                     last_update_date,
                     last_updated_by,
                     creation_date,
                     created_by,
                     last_update_login,
					 vendor_site_interface_id -- Added for the defect 34346
					 )
             VALUES (p_vendor_interface_id,
                     p_vendor_id,
                     x_sitecode,
                     UPPER(p_refund_hdr_rec.alt_address1),
                     UPPER(p_refund_hdr_rec.alt_address2),
                     UPPER(p_refund_hdr_rec.alt_address3),
                     SUBSTR(UPPER(p_refund_hdr_rec.alt_city),
                            1,
                            25)                                                                 -- substr added for v5.1
                               ,
                     UPPER(p_refund_hdr_rec.alt_state),
                     UPPER(p_refund_hdr_rec.alt_province),
                     NVL(UPPER(p_refund_hdr_rec.alt_country),
                         (SELECT default_country
                          FROM   ar_system_parameters)),
                     UPPER(p_refund_hdr_rec.alt_postal_code),
                     '00',
                     'N',
                     'Y',
                     fnd_global.org_id,
                     'NEW',
                     'Invoice',
                     'DISCOUNT'
                               -- Defect 2418 Use 'US_OD_EXP_NON_DISC' for Canada also
                               --, DECODE (p_sob_name
                               --        , 'US_USD_P', 'US_OD_EXP_NON_DISC'
                               --        , 'CA_CAD_P', 'CA_OD_EXP_NON_DISC'
                               --        , NULL
                               --         )
        ,
                     'US_OD_EXP_NON_DISC',
                     'CHECK',
                     'EX-REF'  --changed for the jira NAIT-65243             --'EXPENSE'
                         ,
                     SYSDATE,
                     fnd_global.user_id,
                     SYSDATE,
                     fnd_global.user_id,
                     fnd_global.user_id,
					 AP_SUPPLIER_SITES_INT_S.NextVal -- Added for the defect 34346
					 );
    EXCEPTION
        WHEN OTHERS
        THEN
            x_err_mesg :=    'E:'
                          || SQLCODE
                          || SQLERRM;
    END;

    -- Procedure to insert a record into ap_invoices_interface table
    PROCEDURE insert_invoice_interface(
        p_inv_amt         IN             NUMBER,
        p_vendor_name     IN             VARCHAR2
                                                 -- V4.0, Commented below parameter as this is not required because passing the description directly
                                                 --, p_aops_customer_number IN             VARCHAR2                 --Added for R1.2 CR714(Defect# 2532)
    ,
        p_sitecode        IN             VARCHAR2,
        p_curr            IN             VARCHAR2,
        p_sob_name        IN             VARCHAR2
                                                 -- V4.0, Commented below parameter as this is not required because passing the description directly
                                                 --, p_cust_num             IN             VARCHAR2
    ,
        p_trx_num         IN             VARCHAR2,
        p_invoice_source  IN             VARCHAR2
                                                 -- V4.0, Added parameter to get the description
    ,
        p_description     IN             VARCHAR2,
        o_invoice_id      OUT NOCOPY     NUMBER,
        o_invoice_num     OUT NOCOPY     VARCHAR2,
        x_err_mesg        OUT NOCOPY     VARCHAR2)
    IS
        ln_invoice_id   NUMBER;
        lc_invoice_num  ap_invoices_all.invoice_num%TYPE;
    BEGIN
        -- Generate invoice_id from sequence
        SELECT ap_invoices_interface_s.NEXTVAL
        INTO   ln_invoice_id
        FROM   DUAL;

        lc_invoice_num :=    'AR'
                          || (p_trx_num);

        -- Insert a record into ap_invoices_interface table
        INSERT INTO ap_invoices_interface
                    (invoice_id,
                     invoice_num,
                     invoice_date,
                     description,
                     vendor_name,
                     vendor_site_code,
                     invoice_amount,
                     invoice_currency_code,
                     terms_name,
                     org_id,
                     last_update_date,
                     last_updated_by,
                     creation_date,
                     created_by,
                     status,
                     SOURCE,
                     attribute7                                                                           -- defect 9063
                               ,
                     pay_group_lookup_code)
             VALUES (ln_invoice_id,
                     SUBSTR(lc_invoice_num,
                            1,
                            50),
                     SYSDATE                                                                    -- substr added for v5.1
                            /* ,'Refund for customer number '
                            || p_cust_num
                            || ' for TRX# '
                            || p_trx_num*/                          --Commented for R1.2 CR714(Defect# 2532)
                            -- V4.0, Commented and passing the description as a parameter, which is derived from calling procedure
                            /*,'REF CUST#'
                             ||p_cust_num
                             ||'/'
                             ||p_aops_customer_number */                  --Modified check description format for R1.2 CR714(Defect# 2532)
        ,
                     p_description                                       -- V4.0, Added desciprion passed as a parameter
                                  ,
                     p_vendor_name,
                     p_sitecode,
                     ABS(p_inv_amt),
                     p_curr,
                     '00',
                     fnd_global.org_id,
                     SYSDATE,
                     fnd_global.user_id,
                     SYSDATE,
                     fnd_global.user_id,
                     NULL
                         -- Defect 2441 use 'US_OD_AR_REFUND' for Canada Also.
                         --, DECODE (p_sob_name
                         --        , 'US_USD_P', 'US_OD_AR_REFUND'
                         --        , 'CA_CAD_P', 'CA_OD_AR_REFUND'
                         --        , NULL
                         --         )
                         --,            'US_OD_AR_REFUND'
                         -- Defect 2478 use 'US_OD_RETAIL_REFUND' for Store Refunds
        ,
                     p_invoice_source,
                     p_invoice_source
                 -- Defect 2418 use '
                 -- , DECODE (p_sob_name
                 --         , 'US_USD_P', 'US_OD_EXP_NON_DISC'
                 --        , 'CA_CAD_P', -- 'CA_OD_EXP_NON_DISC'
                 --        , NULL
                 --          )
--      ,            'US_OD_EXP_NON_DISC'    -- COMMENTED FOR defect 12225 v5.3 Gaurav
        ,
                     DECODE(p_inv_amt,
                            0, 'US_OD_CLEARING_TREASURY',
                            'US_OD_EXP_NON_DISC')                            --decode added FOR defect 12225 v5.3 Gaurav
                                                 );

        o_invoice_id := ln_invoice_id;
        o_invoice_num := lc_invoice_num;
    EXCEPTION
        WHEN OTHERS
        THEN
            o_invoice_id := 0;
            o_invoice_num := NULL;
            x_err_mesg :=    SQLCODE
                          || SQLERRM;
    END;

    PROCEDURE insert_invoice_lines_int(
        p_invoice_id       IN             NUMBER,
        p_line_num         IN             NUMBER,
        p_company_num      IN             VARCHAR2,
        p_refund_trx_rec   IN             xx_ar_refund_trx_tmp%ROWTYPE,
        o_invoice_line_id  OUT NOCOPY     NUMBER,
        x_err_mesg         OUT NOCOPY     VARCHAR2,
        p_line             IN             NUMBER)
    IS
        ln_invoice_line_id  NUMBER;
        ln_dist_ccid        gl_code_combinations_kfv.code_combination_id%TYPE;
        lc_dist_cc          gl_code_combinations_kfv.padded_concatenated_segments%TYPE;
        ln_coa_id           gl_sets_of_books.chart_of_accounts_id%TYPE;
        lc_company          gl_code_combinations_kfv.segment1%TYPE;
        lc_cost_center      gl_code_combinations_kfv.segment2%TYPE                       := '00000';
        --'09000';
        lc_account          gl_code_combinations_kfv.segment3%TYPE;
        lc_location         gl_code_combinations_kfv.segment4%TYPE                       := '000000';
        lc_intercompany     gl_code_combinations_kfv.segment5%TYPE                       := '0000';
        lc_lob              gl_code_combinations_kfv.segment6%TYPE                       := '00';
        lc_future           gl_code_combinations_kfv.segment7%TYPE                       := '000000';
        exep_location       EXCEPTION;
        exep_company        EXCEPTION;
        ln_org_id           NUMBER;
        lc_act_type         ar_receivables_trx_all.NAME%TYPE                             := NULL;
    BEGIN
        ln_org_id := fnd_profile.VALUE('ORG_ID');

        SELECT ap_invoice_lines_interface_s.NEXTVAL
        INTO   ln_invoice_line_id
        FROM   DUAL;

        BEGIN
            SELECT chart_of_accounts_id
            INTO   ln_coa_id
            FROM   gl_sets_of_books sob,
                   ap_system_parameters a
            WHERE  sob.set_of_books_id = a.set_of_books_id;
        EXCEPTION
            WHEN OTHERS
            THEN
                ln_dist_ccid := NULL;
        END;

        IF p_refund_trx_rec.identification_type = 'OM'
        THEN
            lc_account := '20202000';                                              --'21030050'--(Mailcheck New System)
        ELSE                                                                      -- Non 'OM(Store Mail Check') refunds.
            lc_account := '10504000';                                               --'11250090' (A/R-Clearing Mail Ck)
        END IF;

        lc_lob := '90';                                                                                          --'04';
        lc_location := '010000';
        od_message('M',
                      'COA ID:'
                   || ln_coa_id
                   || '  Identification Type:'
                   || p_refund_trx_rec.identification_type
                   || ' Location:'
                   || lc_location);

        IF lc_location IS NOT NULL
        THEN
            -- AP INVOICE DISTRIBUTION.
            BEGIN
                -- Fix for Defect 2313
                -- Call to the overloaded version of function derive_company_from_location
                -- with the parameter ORG_ID
                lc_company :=
                    xx_gl_translate_utl_pkg.derive_company_from_location(p_location      => lc_location,
                                                                         p_org_id        => ln_org_id);
            EXCEPTION
                WHEN OTHERS
                THEN
                    od_message('M',
                                  'Company/Lob could not be determined for Location/Cost-Center'
                               || lc_location);
                    RAISE exep_company;
            END;
        ELSE
            od_message('M',
                       'Location / Store Number not found!');
            RAISE exep_location;
        END IF;

        IF lc_company IS NOT NULL
        THEN
            lc_dist_cc :=
                   lc_company
                || '.'
                || lc_cost_center
                || '.'
                || lc_account
                || '.'
                || lc_location
                || '.'
                || lc_intercompany
                || '.'
                || lc_lob
                || '.'
                || lc_future;
        ELSE
            od_message('M',
                          'Company could not be determined for location:'
                       || lc_location);
            RAISE exep_company;
        END IF;

        od_message('M',
                      'Concatenated Segments:'
                   || lc_dist_cc);
        ln_dist_ccid := fnd_flex_ext.get_ccid('SQLGL',
                                              'GL#',
                                              ln_coa_id,
                                              NULL,
                                              lc_dist_cc);

-- v 5.0 Starts
        IF p_refund_trx_rec.identification_type = 'OM' AND p_line = 2
        THEN
            IF (p_refund_trx_rec.om_delete_status = 'M' OR p_refund_trx_rec.om_delete_status = 'O')
            THEN
                lc_act_type :=
                       xx_ar_prepayments_pkg.get_country_prefix(ln_org_id)
                    || '_MAILCK_O/S'
                    || '_'
                    || p_refund_trx_rec.om_store_number;
            ELSIF(p_refund_trx_rec.om_delete_status = 'A' OR p_refund_trx_rec.om_delete_status = 'E')
            THEN
                lc_act_type :=    xx_ar_prepayments_pkg.get_country_prefix(ln_org_id)
                               || '_ESCHEAT_REC_WRITEOFF_OD';
            ELSIF(p_refund_trx_rec.om_delete_status = 'S')
            THEN
                lc_act_type :=
                       xx_ar_prepayments_pkg.get_country_prefix(ln_org_id)
                    || '_MAILCK_REV'
                    || '_'
                    || p_refund_trx_rec.om_store_number;
            END IF;
        END IF;

        IF lc_act_type IS NOT NULL
        THEN
            BEGIN
                SELECT code_combination_id
                INTO   ln_dist_ccid
                FROM   ar_receivables_trx_all
                WHERE  INSTR(NAME,
                             lc_act_type) > 0;
            EXCEPTION
                WHEN OTHERS
                THEN
                    ln_dist_ccid := NULL;
            END;
        END IF;

-- v 5.0 ENDS
        IF ln_dist_ccid = 0 OR ln_dist_ccid = -1
        THEN
            ln_dist_ccid := NULL;
            x_err_mesg :=
                   'Error creating Code Combination ('
                || lc_dist_cc
                || ') for Trx: '
                || p_refund_trx_rec.trx_number
                || '. Error:'
                || fnd_flex_ext.GET_MESSAGE;
        ELSE
            INSERT INTO ap_invoice_lines_interface
                        (invoice_id,
                         invoice_line_id,
                         line_number,
                         line_type_lookup_code,
                         amount,
                         dist_code_combination_id,
                         description,
                         created_by,
                         creation_date,
                         last_updated_by,
                         last_update_date,
                         last_update_login,
                         org_id)
                 VALUES (p_invoice_id,
                         ln_invoice_line_id,
                         p_line_num,
                         'ITEM',
                         p_refund_trx_rec.refund_amount                     -- v 4.0 ABS(p_refund_trx_rec.refund_amount)
                                                       ,
                         ln_dist_ccid,
                            'Refund for '
                         /*|| DECODE (p_refund_trx_rec.trx_type
                                  , 'C', 'Credit Memo '
                                  , 'Receipt'
                                   )*/ -- Commented for CR 697/698 R1.2
                         || DECODE(p_refund_trx_rec.trx_type,
                                   'R', 'Receipt',
                                   'Credit Memo ')                                          -- Added for CR 697/698 R1.2
                         || ': '
                         || (p_refund_trx_rec.trx_number),
                         fnd_global.user_id,
                         SYSDATE,
                         fnd_global.user_id,
                         SYSDATE,
                         fnd_global.conc_login_id,
                         fnd_global.org_id);

            o_invoice_line_id := ln_invoice_line_id;
        END IF;
    EXCEPTION
        WHEN exep_location
        THEN
            x_err_mesg := 'Location / Store Number not found.';
            o_invoice_line_id := 0;
        WHEN exep_company
        THEN
            x_err_mesg :=    'Company segment could not be determined for location:'
                          || lc_location;
            o_invoice_line_id := 0;
        WHEN OTHERS
        THEN
            o_invoice_line_id := 0;
            x_err_mesg :=    SQLCODE
                          || SQLERRM;
    END;

    PROCEDURE get_vendor_id(
        p_name       IN      VARCHAR2,
        o_vendor_id  OUT     NUMBER)
    IS
    BEGIN
        SELECT vendor_id
        INTO   o_vendor_id
        FROM   ap_vendors_v                                                                                 --po_vendors
        WHERE  TRIM(UPPER(vendor_name)) = TRIM(UPPER(p_name)) AND ROWNUM = 1;
    EXCEPTION
        WHEN OTHERS
        THEN
            o_vendor_id := NULL;
    END;

    PROCEDURE get_vendor_site_id(
        p_vendor_id  IN             NUMBER,
        p_address1   IN             VARCHAR2,
        p_address2   IN             VARCHAR2,
        p_address3   IN             VARCHAR2,
        p_city       IN             VARCHAR2,
        p_state      IN             VARCHAR2,
        p_province   IN             VARCHAR2,
        p_country    IN             VARCHAR2,
        o_site_id    OUT NOCOPY     NUMBER,
        o_sitecode   OUT NOCOPY     VARCHAR2)
    IS
    BEGIN
        SELECT vendor_site_id,
               vendor_site_code
        INTO   o_site_id,
               o_sitecode
        FROM   ap_vendor_sites_v                                                                   --po_vendor_sites_all
        WHERE  TRIM(UPPER(address_line1)) = TRIM(UPPER(p_address1))
        AND    TRIM(UPPER(NVL(address_line2,
                              'X'))) = TRIM(UPPER(NVL(p_address2,
                                                      'X')))
        AND    TRIM(UPPER(NVL(address_line3,
                              'X'))) = TRIM(UPPER(NVL(p_address3,
                                                      'X')))
        AND    TRIM(UPPER(city)) = TRIM(UPPER(p_city))
        AND    TRIM(UPPER(NVL(state,
                              'X'))) = TRIM(UPPER(NVL(p_state,
                                                      'X')))
        AND    TRIM(UPPER(NVL(province,
                              'X'))) = TRIM(UPPER(NVL(p_province,
                                                      'X')))
        AND    TRIM(UPPER(NVL(country,
                              'X'))) = TRIM(UPPER(NVL(p_country,
                                                      'X')))
        AND    vendor_id = p_vendor_id
        AND    ROWNUM = 1;
    EXCEPTION
        WHEN OTHERS
        THEN
            o_site_id := NULL;
            o_sitecode := NULL;
    END;

    PROCEDURE get_vendor_site_int_id(
        p_vendor_id     IN             NUMBER,
        p_interface_id  IN             NUMBER,
        p_address1      IN             VARCHAR2,
        p_address2      IN             VARCHAR2,
        p_address3      IN             VARCHAR2,
        p_city          IN             VARCHAR2,
        p_state         IN             VARCHAR2,
        p_province      IN             VARCHAR2,
        p_country       IN             VARCHAR2,
        o_sitecode      OUT NOCOPY     VARCHAR2)
    IS
    BEGIN
        SELECT vendor_site_code
        INTO   o_sitecode
        FROM   ap_supplier_sites_int
        WHERE  DECODE(p_vendor_id,
                      NULL, vendor_interface_id,
                      vendor_id) = DECODE(p_vendor_id,
                                          NULL, p_interface_id,
                                          p_vendor_id)
        AND    TRIM(UPPER(address_line1)) = TRIM(UPPER(p_address1))
        AND    TRIM(UPPER(NVL(address_line2,
                              'X'))) = TRIM(UPPER(NVL(p_address2,
                                                      'X')))
        AND    TRIM(UPPER(NVL(address_line3,
                              'X'))) = TRIM(UPPER(NVL(p_address3,
                                                      'X')))
        AND    TRIM(UPPER(city)) = TRIM(UPPER(p_city))
        AND    TRIM(UPPER(NVL(state,
                              'X'))) = TRIM(UPPER(NVL(p_state,
                                                      'X')))
        AND    TRIM(UPPER(NVL(province,
                              'X'))) = TRIM(UPPER(NVL(p_province,
                                                      'X')))
        AND    TRIM(UPPER(NVL(country,
                              'X'))) = TRIM(UPPER(NVL(p_country,
                                                      'X')))
        AND    ROWNUM = 1
        AND    status = 'NEW';
    EXCEPTION
        WHEN OTHERS
        THEN
            o_sitecode := NULL;
    END;

    PROCEDURE get_vendor_int_id(
        p_name           IN             VARCHAR2,
        o_vendor_int_id  OUT NOCOPY     NUMBER)
    IS
    BEGIN
        SELECT vendor_interface_id
        INTO   o_vendor_int_id
        FROM   ap_suppliers_int
        WHERE  TRIM(UPPER(vendor_name)) = TRIM(UPPER(p_name)) AND ROWNUM = 1;
    EXCEPTION
        WHEN OTHERS
        THEN
            o_vendor_int_id := NULL;
    END;

--
-- Main Procedure
--       Parameter: Currency
--       This procedure will be executed once for each operating unit
--      pick up records from xx_ar_refund_trx_tmp where adj_created_flag='Y' and inv_created_flag='N'
--      Check if vendor exists, Else insert into ap_suppliers_int table
--        Check if vendor site exists else insert into ap_supplier_sites_int table
--        Insert record into ap_invoices_interface table
--        Insert record into ap_invoice_lines_interface table
--        Submit concurrent request for "Suppliers Open Interface Import" if need be
--        Submit concurrent request for "Supplier Sites Open Interface Import" if need be
--        Submit concurrent request for "Payables Open Interface Import"
    PROCEDURE create_ap_invoice(
        errbuf   IN OUT NOCOPY  VARCHAR2,
        errcode  IN OUT NOCOPY  INTEGER)
    IS
        CURSOR c_refund_hdr(
            p_org_id  IN  NUMBER)
        IS
            SELECT *
            FROM   xx_ar_refund_trx_tmp xartt
            WHERE  xartt.inv_created_flag = 'N'
            AND    xartt.adj_created_flag = 'Y'
            AND    xartt.selected_flag = 'Y'
            AND    xartt.status = 'A'
            -- V4.0, Commented below 2 condition and added 2 new to select all Store Records
            -- AND om_write_off_only = 'N'  -- V4.0
            -- AND escheat_flag = 'N'       -- V4.0
            AND    xartt.om_write_off_only =
                       DECODE(xartt.identification_type,
                              'OM', DECODE(INSTR(NVL(payment_method_name,
                                                     'XXX'),
                                                 'MAILCHECK'),
                                           0, 'N',
                                           om_write_off_only),
                              'N')
            AND    xartt.escheat_flag =
                       DECODE(xartt.identification_type,
                              'OM', DECODE(INSTR(NVL(payment_method_name,
                                                     'XXX'),
                                                 'MAILCHECK'),
                                           0, 'N',
                                           xartt.escheat_flag),
                              'N')
            AND    org_id = p_org_id;

        CURSOR c_trx(
            p_refund_header_id  IN  NUMBER)
        IS
            SELECT        *
            FROM          xx_ar_refund_trx_tmp
            WHERE         refund_header_id = p_refund_header_id
            -- V4.0, commented below 5 conditions, which are not required, as using refund_header_id
            --AND inv_created_flag = 'N'
            --AND adj_created_flag = 'Y'
            --AND status = 'A'
            --AND om_write_off_only = 'N'
            --AND escheat_flag = 'N'
            FOR UPDATE OF ap_invoice_number, inv_created_flag, ap_inv_creation_date;

        ln_vendor_id            po_vendors.vendor_id%TYPE;
        ln_vendor_site_id       po_vendor_sites.vendor_site_id%TYPE;
        ln_vendor_interface_id  NUMBER;
        lc_create_vendor        VARCHAR2(1);
        lc_create_site          VARCHAR2(1);
        ln_vendor_cnt           NUMBER;
        ln_site_cnt             NUMBER;
        ln_org_id               NUMBER;
        ln_sob_id               gl_sets_of_books.set_of_books_id%TYPE;
        lc_sitecode             po_vendor_sites.vendor_site_code%TYPE;
        ln_tot_amt              NUMBER;
        ln_invoice_id           NUMBER;
        ln_invoice_line_id      NUMBER;
        lc_invoice_num          ap_invoices_all.invoice_num%TYPE;
        lc_invoice_source       VARCHAR2(30);
        ln_inv_count            NUMBER                                          := 0;
        ln_inv_err_count        NUMBER                                          := 0;
        ln_line_num             NUMBER;
        ln_req_id               NUMBER;
        ln_req_id2              NUMBER;
        lc_phase                VARCHAR2(200);
        lc_status               VARCHAR2(200);
        lc_dev_phase            VARCHAR2(200);
        lc_dev_status           VARCHAR2(200);
        lc_message              VARCHAR2(200);
        lb_wait                 BOOLEAN;
        ln_user_id              NUMBER;
        lc_sob_name             gl_sets_of_books.short_name%TYPE;
        ln_trx_id               NUMBER;
        lc_trx_type             VARCHAR2(15);
        lc_err_mesg             VARCHAR2(1000);
        lc_savepoint            VARCHAR2(100);
        intf_insert_error       EXCEPTION;
        lc_comn_err_loc         VARCHAR2(100);
        ln_proc_count           NUMBER                                          := 0;
        ln_conc_request_id      NUMBER;
        lc_cust_number          hz_cust_accounts.account_number%TYPE;
        -- V4.0, variable declaration to hold aops_order_number, description, invoice amount and payee name
        lc_aops_order_number    xx_ar_mail_check_holds.aops_order_number%TYPE;
        lc_description          ap_invoices_interface.description%TYPE;
        ln_invoice_amount       NUMBER;
        lc_payee_name           xx_ar_refund_trx_tmp.payee_name%TYPE;
        lc_sale_return_date     VARCHAR2(30);
        lc_in_invoice_number    VARCHAR2(30);
        xx_lc_description       xx_ar_refund_trx_tmp.description%TYPE;                                   -- Defect 22806
	lc_insert_error_sup_site VARCHAR2(2);			-- Defect 30123

    BEGIN
        ln_vendor_cnt := 0;
        ln_site_cnt := 0;
        ln_inv_count := 0;
        ln_proc_count := 0;
        ln_user_id := fnd_global.user_id;
        ln_org_id := fnd_profile.VALUE('ORG_ID');
        ln_conc_request_id := fnd_profile.VALUE('CONC_REQUEST_ID');
        od_message('M',
                   g_print_line);
        od_message('O',
                   ln_conc_request_id);
        od_message('O',
                      fnd_profile.VALUE('GL_SET_OF_BKS_NAME')
                   || '                 OD: Refunds - Create Invoices for Refunds                    Date:'
                   || TRUNC(SYSDATE));
        od_message('O',
                   '');

        SELECT gsb.short_name
        INTO   lc_sob_name
        FROM   hr_operating_units hru,
               gl_sets_of_books gsb
        WHERE  gsb.set_of_books_id = hru.set_of_books_id AND hru.organization_id = ln_org_id;

        lc_comn_err_loc := 'After SOB name';

        -- Get all records in xx_ar_refund_trx_tmp table with
        -- ADJ_CREATED_FLAG = 'Y' and INV_CREATED_FLAG = 'N'
        -- and org_id = Org based on current responsibiity.
        FOR v_refund_hdr IN c_refund_hdr(ln_org_id)
        LOOP
            BEGIN
                ln_vendor_site_id := NULL;                                   -- added for defect # 12210 by Gaurav V5.3
                lc_err_mesg := NULL;
                lc_create_vendor := 'N';
                lc_create_site := 'N';
	        lc_insert_error_sup_site:=NULL;
                lc_savepoint :=    'SAVEPOINT-XXARRFNDC'
                                || v_refund_hdr.refund_header_id;
                od_message('M',
                           ' ');
                od_message('M',
                           g_print_line);
                SAVEPOINT lc_savepoint;
                od_message('M',
                              'Set Savepoint:'
                           || lc_savepoint);

                IF v_refund_hdr.trx_type = 'R'
                THEN
                    lc_trx_type := 'Receipt';
                ELSE
                    lc_trx_type := 'Credit Memo';
                END IF;

                /* V4.0, Added below code, as for Store refund where payment method is 'MAILCHECK' and
                   transaction is  reclassing/escheat, need to create $0 invoice with supplier 'INTERNAL SUPPLIER MAILCHECK' */
                ln_invoice_amount := v_refund_hdr.refund_amount;
                lc_payee_name := v_refund_hdr.payee_name;

                IF     NVL(v_refund_hdr.identification_type,
                           'x') = 'OM'
                   AND INSTR(NVL(v_refund_hdr.payment_method_name,
                                 'XXX'),
                             'MAILCHECK') > 0
                THEN
                    IF lc_sob_name = 'US_USD_P' AND NVL(v_refund_hdr.activity_type,
                                                        'XXX') <> 'US_MAILCK_CLR_OD'
                    THEN
                        ln_invoice_amount := 0;
                        lc_payee_name := 'INTERNAL SUPPLIER MAILCHECK';
                    END IF;

                    IF lc_sob_name = 'CA_USD_P' AND NVL(v_refund_hdr.activity_type,
                                                        'XXX') <> 'CA_MAILCK_CLR_OD'
                    THEN
                        ln_invoice_amount := 0;
                        lc_payee_name := 'INTERNAL SUPPLIER MAILCHECK';
                    END IF;
                END IF;

                -- V4.0 End

                -- Check if record exists in PO_VENDORS table with
                -- vendor name = xx_ar_refund_customer.payee_name
                -- V4.0, Commented below statement and added new to pass different payee name in case of $0 invoice
                --get_vendor_id (v_refund_hdr.payee_name, ln_vendor_id);
                get_vendor_id(lc_payee_name,
                              ln_vendor_id);
                lc_comn_err_loc := 'After get_vendor_id';

                -- If record exists ....
                IF ln_vendor_id IS NOT NULL
                THEN
                    lc_create_vendor := 'N';

                    -- Check if record exists in PO_VENDOR_SITES for the vendor_id
                    -- and address = address from xx_ar_refund_trx_tmp table
                    -- V5.2, Fetching the vendor site in case of mailcheck and 0 invoice amount
                    IF lc_payee_name = 'INTERNAL SUPPLIER MAILCHECK' AND ln_invoice_amount = 0
                    THEN
                        BEGIN
                            IF lc_sob_name = 'US_USD_P'
                            THEN
                                SELECT vendor_site_id,
                                       vendor_site_code
                                INTO   ln_vendor_site_id,
                                       lc_sitecode
                                FROM   ap_vendor_sites_v
                                WHERE  vendor_id = ln_vendor_id
                                AND    vendor_site_code = 'RF803533'        -- 'RF792910'   Commented By Gaurav for V5.4
                                AND    ROWNUM = 1;
                            ELSIF lc_sob_name = 'CA_USD_P'
                            THEN
                                SELECT vendor_site_id,
                                       vendor_site_code
                                INTO   ln_vendor_site_id,
                                       lc_sitecode
                                FROM   ap_vendor_sites_v
                                WHERE  vendor_id = ln_vendor_id
                                AND    vendor_site_code = 'RF803534'         --  'RF792911' Commented By Gaurav for V5.4
                                AND    ROWNUM = 1;
                            END IF;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                ln_vendor_site_id := NULL;
                                lc_sitecode := NULL;
                        END;
                    END IF;

                    -- V5.2, get vendor site details if vendor_site_id is null
                    IF ln_vendor_site_id IS NULL
                    THEN
                        get_vendor_site_id(ln_vendor_id,
                                           v_refund_hdr.alt_address1,
                                           v_refund_hdr.alt_address2,
                                           v_refund_hdr.alt_address3,
                                           v_refund_hdr.alt_city,
                                           v_refund_hdr.alt_state,
                                           v_refund_hdr.alt_province,
                                           v_refund_hdr.alt_country,
                                           ln_vendor_site_id,
                                           lc_sitecode);
                        lc_comn_err_loc := 'After Vend Site ID 1';
                    END IF;

                    -- If vendor site exists ...
                    IF ln_vendor_site_id IS NOT NULL
                    THEN
                        lc_create_site := 'N';
                    ELSE
                        -- Check if record exists in ap_supplier_sites_int
                        -- table for the vendor_id and address
                        get_vendor_site_int_id(ln_vendor_id,
                                               NULL,
                                               v_refund_hdr.alt_address1,
                                               v_refund_hdr.alt_address2,
                                               v_refund_hdr.alt_address3,
                                               v_refund_hdr.alt_city,
                                               v_refund_hdr.alt_state,
                                               v_refund_hdr.alt_province,
                                               v_refund_hdr.alt_country,
                                               lc_sitecode);
                        lc_comn_err_loc := 'After Vend Site ID 2';

                        -- If record does not exist
                        IF lc_sitecode IS NULL
                        THEN
                            lc_create_site := 'Y';
                        ELSE
                            lc_create_site := 'N';
                        END IF;
                    END IF;
                -- If record does not exist in PO_VENDORS table for payee_name
                ELSE
                    -- Check if record exists in ap_suppliers_int table for the payee name
                    get_vendor_int_id(lc_payee_name     -- V4.0, passed the derived payee name --v_refund_hdr.payee_name
                                                   ,
                                      ln_vendor_interface_id);
                    lc_comn_err_loc := 'After Vend Int ID';

                    -- If record exists in ap_suppliers_int table
                    IF ln_vendor_interface_id IS NOT NULL
                    THEN
                        lc_create_vendor := 'N';
                    ELSE
                        lc_create_vendor := 'Y';
                    END IF;

                    -- Check if record exists in ap_supplier_sites_int table for the vendor_interface_id and address
                    get_vendor_site_int_id(NULL,
                                           ln_vendor_interface_id,
                                           v_refund_hdr.alt_address1,
                                           v_refund_hdr.alt_address2,
                                           v_refund_hdr.alt_address3,
                                           v_refund_hdr.alt_city,
                                           v_refund_hdr.alt_state,
                                           v_refund_hdr.alt_province,
                                           v_refund_hdr.alt_country,
                                           lc_sitecode);

                    -- If record does not exist
                    IF lc_sitecode IS NULL
                    THEN
                        lc_create_site := 'Y';
                    ELSE
                        lc_create_site := 'N';
                    END IF;
                END IF;

                lc_comn_err_loc := 'Vendor Create Check';

                -- If vendor is to be created
                IF lc_create_vendor = 'Y'
                THEN
                    -- Insert a record into ap_suppliers_int table
                    insert_supplier_interface(v_refund_hdr,
                                              lc_sob_name,
                                              ln_vendor_interface_id,
                                              lc_err_mesg);

                    IF lc_err_mesg IS NOT NULL
                    THEN
                        lc_err_mesg :=    'Vendor Interface Insert Error: '
                                       || lc_err_mesg;
                        lc_comn_err_loc := 'XX_AR_REFUNDS_PKG.Create_AP_Invoice -INS Vendor Intf';

		        lc_insert_error_sup_site:='S';    -- Defect 30123

                        RAISE intf_insert_error;
                    ELSE
                        ln_vendor_cnt :=   NVL(ln_vendor_cnt,
                                               0)
                                         + 1;
                    END IF;
                END IF;

                -- If vendor site is to be created
                IF lc_create_site = 'Y'
                THEN
                    -- If vendor is to be created
                    IF lc_create_vendor = 'Y'
                    THEN
                        -- Insert a record into ap_supplier_sites_int table with
                        -- the vendor_interface_id as opposed to with the vendor_id
                        insert_supplier_site_int(v_refund_hdr,
                                                 ln_vendor_interface_id,
                                                 NULL,
                                                 lc_sob_name,
                                                 lc_sitecode,
                                                 lc_err_mesg);
                    ELSE
                        IF ln_vendor_id IS NULL
                        THEN
                            -- Insert a record into ap_supplier_sites_int table with
                            -- the vendor_interface_id as opposed to with the vendor_id
                            insert_supplier_site_int(v_refund_hdr,
                                                     ln_vendor_interface_id,
                                                     NULL,
                                                     lc_sob_name,
                                                     lc_sitecode,
                                                     lc_err_mesg);
                        ELSE
                            -- Insert a record into ap_supplier_sites_int table with the vendor_id.
                            insert_supplier_site_int(v_refund_hdr,
                                                     NULL,
                                                     ln_vendor_id,
                                                     lc_sob_name,
                                                     lc_sitecode,
                                                     lc_err_mesg);
                        END IF;
                    END IF;

                    IF lc_err_mesg IS NOT NULL
                    THEN
                        lc_err_mesg :=    'Vendor Site Interface Insert Error:'
                                       || lc_err_mesg;
                        lc_comn_err_loc := 'XX_AR_REFUNDS_PKG.Create_AP_Invoice-Vendor Site Intf';

	   	        lc_insert_error_sup_site:='SS';    -- Defect 30123

                        RAISE intf_insert_error;
                    ELSE
                        ln_site_cnt :=   NVL(ln_site_cnt,
                                             0)
                                       + 1;
                    END IF;
                END IF;                                                                       -- if lc_create_site = 'Y'

                lc_comn_err_loc := 'Vendor matched';

                BEGIN
                    -- Update Vendor Created/matched Status on Transaction
                    IF v_refund_hdr.trx_type = 'R'
                    THEN
                        UPDATE ar_cash_receipts_all acr
                        SET attribute10 = 'Vendor Created/Matched',
                            last_update_date = SYSDATE                                                  -- Defect #13458
                                                      ,
                            last_updated_by = fnd_profile.VALUE('USER_ID')                             -- Defect # 13458
                        WHERE  cash_receipt_id = v_refund_hdr.trx_id;
                    ELSE
                        UPDATE ra_customer_trx_all
                        SET attribute10 = 'Vendor Created/Matched',
                            last_update_date = SYSDATE                                                  -- Defect #13458
                                                      ,
                            last_updated_by = fnd_profile.VALUE('USER_ID')                             -- Defect # 13458
                        WHERE  customer_trx_id = v_refund_hdr.trx_id;
                    END IF;

                    UPDATE xx_ar_refund_trx_tmp
                    SET ap_vendor_site_code = lc_sitecode,
                        error_flag = 'N',
                        last_update_date = SYSDATE,
                        last_updated_by = fnd_profile.VALUE('USER_ID'),
                        last_update_login = fnd_profile.VALUE('LOGIN_ID')
                    WHERE  refund_header_id = v_refund_hdr.refund_header_id;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        od_message
                             ('M',
                                 '*** Error Updating Refunds Staging Table after creating vendor for Refund_Header_ID:'
                              || v_refund_hdr.refund_header_id
                              || ' Trx:'
                              || v_refund_hdr.trx_number);
                END;

                /* Disabled Code
                -- to accomodate if multiple refunds will be processed as single.
                -- AP Invoice.

                -- Get total refund amount for the record in xx_ar_refund_customer. There could be
                -- multiple lines for one record Sum(refund_amount) from xx_ar_refund_trx_tmp table
                -- will give refund amount which will be the invoice amount

                 BEGIN
                    SELECT SUM(NVL(refund_amount, 0))
                      INTO ln_tot_amt
                      FROM xx_ar_refund_trx_tmp
                     WHERE refund_header_id = v_refund_hdr.refund_header_id;
                 EXCEPTION
                    WHEN OTHERS THEN
                       ln_tot_amt := 0;
                 END;
                  */
                lc_comn_err_loc := 'Before Insert invoice intf call';

                IF NVL(v_refund_hdr.identification_type,
                       'x') = 'OM'
                THEN
                    lc_invoice_source := 'US_OD_RETAIL_REFUND';
                ELSE
                    lc_invoice_source := 'US_OD_AR_REFUND';
                END IF;

                -- V4.0, Added to derive description
                IF NVL(v_refund_hdr.identification_type,
                       'x') = 'OM'
                THEN
                    BEGIN
                        SELECT    SUBSTR(xamch.pos_transaction_number,
                                         9,
                                         2)
                               || '/'
                               || SUBSTR(xamch.pos_transaction_number,
                                         11,
                                         2)
                               || '/'
                               || SUBSTR(xamch.pos_transaction_number,
                                         5,
                                         4),
                               xamch.aops_order_number,
                               NVL(xamch.aops_order_number,
                                   xamch.pos_transaction_number)
                        INTO   lc_sale_return_date,
                               lc_aops_order_number,
                               lc_in_invoice_number
                        FROM   xx_ar_mail_check_holds xamch
                        WHERE  ref_mailcheck_id = v_refund_hdr.ref_mailcheck_id AND ROWNUM = 1;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            lc_sale_return_date := NULL;
                            lc_aops_order_number := NULL;
                            lc_in_invoice_number := NULL;
                    END;

                    IF lc_aops_order_number IS NOT NULL
                    THEN
                        lc_description :=    'Order '
                                          || lc_aops_order_number;
                    ELSE
                        lc_description :=    'Store Refund '
                                          || lc_sale_return_date;
                    END IF;
                ELSE
                    SELECT DISTINCT description
                    INTO            xx_lc_description
                    FROM            xx_ar_refund_trx_tmp
                    WHERE           -- trx_number = v_refund_hdr.trx_number    --Commented for Defect 28951 on 05/23/14
                                    trx_id = v_refund_hdr.trx_id               --Added for Defect 28951 on 05/23/14
					  AND			trx_type = v_refund_hdr.trx_type		   --Added for the Defect# 36803
                      AND             adj_created_flag = 'Y';
                                                                                          --Code Change for defect 22806

                    IF xx_lc_description IS NULL
                    THEN                                                                  --Code Change for defect 22806
                        lc_description :=
                                   'REF CUST#'
                                || v_refund_hdr.customer_number
                                || '/'
                                || v_refund_hdr.aops_customer_number;
                    ELSE                                                                  --Code Change for defect 22806
                        lc_description := xx_lc_description;                             --Code Change for defect 22806
                    END IF;                                                               --Code Change for defect 22806

                    -- V4.0, Added to store trx_number
                    lc_in_invoice_number := v_refund_hdr.trx_number;

                END IF;

                -- V4.0, End

                -- Insert a record into ap_invoices_interface
                insert_invoice_interface(ln_invoice_amount
                                                          /* V4.0, commented below and added above, as for Store refund, payment type 'MAILCHECK' and
                                                            reclassing/escheat transactions, need to create $0 invoice */
                                                          --v_refund_hdr.refund_amount
                ,
                                         lc_payee_name  -- V4.0, passed the derived payee name --v_refund_hdr.payee_name
                                                      -- V4.0, Not required, as passed description directly as a parameter
                                                      --, v_refund_hdr.aops_customer_number   --Added for R1.2 CR714(Defect# 2532)
                ,
                                         lc_sitecode,
                                         v_refund_hdr.trx_currency_code,
                                         lc_sob_name
                                                    -- V4.0, Not required, as passed description directly as a parameter
                                                    --, v_refund_hdr.customer_number
                ,
                                         lc_in_invoice_number                           -- V4.0, v_refund_hdr.trx_number
                                                             ,
                                         lc_invoice_source
                                                          -- V4.0, Passed description as a parameter
                ,
                                         lc_description,
                                         ln_invoice_id,
                                         lc_invoice_num,
                                         lc_err_mesg);
                lc_comn_err_loc := 'After Insert invoice intf call';

                IF lc_err_mesg IS NOT NULL OR ln_invoice_id = 0
                THEN
                    lc_err_mesg :=    'Invoice Interface Insert Error: '
                                   || lc_err_mesg;
                    lc_comn_err_loc := 'XX_AR_REFUNDS_PKG.Create_AP_Invoice - AP INV INTF';
                    RAISE intf_insert_error;
                END IF;

                ln_line_num := 1;

                -- Get all records from xx_ar_refund_trx_tmp for the refund_header_id
                -- This will return only one record since we are creating an AP Invoice
                -- for every refund transaction.
                FOR v_trx IN c_trx(v_refund_hdr.refund_header_id)
                LOOP
                    -- Insert a record into ap_invoice_lines_interface
                    insert_invoice_lines_int(ln_invoice_id,
                                             ln_line_num,
                                             v_refund_hdr.customer_number,
                                             v_trx,
                                             ln_invoice_line_id,
                                             lc_err_mesg,
                                             1);

                    -- V4.0, for $0 invoice, need to insert 2 dist lines one with +ve and another with -ve amt
                    IF ln_invoice_amount = 0
                    THEN
                        v_trx.refund_amount :=   -1
                                               * v_trx.refund_amount;
                        ln_line_num := 2;
                        insert_invoice_lines_int(ln_invoice_id,
                                                 ln_line_num,
                                                 v_refund_hdr.customer_number,
                                                 v_trx,
                                                 ln_invoice_line_id,
                                                 lc_err_mesg,
                                                 2);
                    END IF;

                    -- V4.0
                    IF lc_err_mesg IS NOT NULL OR NVL(ln_invoice_line_id,
                                                      0) = 0
                    THEN
                        od_message('M',
                                   'Error after call to Insert Invoice lines Int');
                        lc_err_mesg :=    'Invoice Line Interface Insert Error: '
                                       || lc_err_mesg;
                        lc_comn_err_loc := 'XX_AR_REFUNDS_PKG.Create_AP_Invoice-AP INV LINE INTF';
                        RAISE intf_insert_error;
                    END IF;

                    BEGIN
                        -- Update xx_ar_refund_trx_tmp table with the invoice number generated
                        -- and set INV_CREATED_FLAG to 'Y'
                        UPDATE xx_ar_refund_trx_tmp
                        SET status = 'X',
                            ap_invoice_number = lc_invoice_num,
                            error_flag = 'N',
                            last_update_date = SYSDATE,
                            last_updated_by = fnd_profile.VALUE('USER_ID'),
                            last_update_login = fnd_profile.VALUE('LOGIN_ID')
                        WHERE CURRENT OF c_trx;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            od_message('M',
                                          '*** Error updating AP invoice creation status for trx:'
                                       || v_trx.trx_number
                                       || ' for Customer'
                                       || v_trx.customer_number);
                    END;

                    ln_line_num :=   NVL(ln_line_num,
                                         0)
                                   + 1;
                END LOOP;

                lc_comn_err_loc := 'Before invoice stat update';

                -- Update Invoice Created Status on Transaction
                IF v_refund_hdr.trx_type = 'R'
                THEN
                    UPDATE ar_cash_receipts_all acr
                    SET attribute10 = 'Sent to AP',
                        last_update_date = SYSDATE                                                      -- Defect #13458
                                                  ,
                        last_updated_by = fnd_profile.VALUE('USER_ID')                                 -- Defect # 13458
                    WHERE  cash_receipt_id = v_refund_hdr.trx_id;
                ELSE
                    UPDATE ra_customer_trx_all
                    SET attribute10 = 'Sent to AP',
                        last_update_date = SYSDATE                                                      -- Defect #13458
                                                  ,
                        last_updated_by = fnd_profile.VALUE('USER_ID')                                 -- Defect # 13458
                    WHERE  customer_trx_id = v_refund_hdr.trx_id;
                END IF;

                ln_inv_count :=   NVL(ln_inv_count,
                                      0)
                                + 1;
            EXCEPTION
                WHEN intf_insert_error
                THEN
                    /*od_message('E'
                             ,    'Error Creating AP invoice for Refund - Trx#:'
                               || v_refund_hdr.trx_number
                               || ' for Customer'
                               || v_refund_hdr.customer_number
                               || '. Error:'
                               || lc_err_mesg
                             , lc_comn_err_loc
                              );    */
                    od_message('M',
                                  '***Error at:'
                               || lc_comn_err_loc
                               || '. Rolling back to savepoint:'
                               || lc_savepoint);
                    od_message('M',
                               lc_err_mesg);

/*   commented for defect 30123

                    IF lc_create_vendor = 'Y' AND NVL(ln_vendor_cnt,
                                                      0) > 0
                    THEN
                        ln_vendor_cnt :=   ln_vendor_cnt
                                         - 1;
                    END IF;

                    IF lc_create_site = 'Y' AND NVL(ln_site_cnt,
                                                    0) > 0
                    THEN
                        ln_site_cnt :=   ln_site_cnt
                                       - 1;
                    END IF;

*/

		    -- Added for Defect 30123

	   	    IF lc_insert_error_sup_site='SS' THEN

	 	       IF lc_create_vendor='Y' THEN

		          ln_vendor_cnt :=   ln_vendor_cnt- 1;

	  	       END IF;

		    END IF;

		    -- End for Defect 30123

                    ln_inv_err_count :=   NVL(ln_inv_err_count,
                                              0)
                                        + 1;
                    ROLLBACK TO lc_savepoint;

                    UPDATE xx_ar_refund_trx_tmp
                    SET error_flag = 'Y',
                        last_update_date = SYSDATE,
                        last_updated_by = fnd_profile.VALUE('USER_ID'),
                        last_update_login = fnd_profile.VALUE('LOGIN_ID')
                    WHERE  refund_header_id = v_refund_hdr.refund_header_id;

                    INSERT INTO xx_ar_refund_error_log
                                (conc_request_id,
                                 err_code,
                                 customer_number,
                                 trx_type,
                                 trx_number,
                                 attribute1)
                         VALUES (ln_conc_request_id,
                                 'R0015',
                                 v_refund_hdr.customer_number,
                                 lc_trx_type,
                                 v_refund_hdr.trx_number,
                                 lc_err_mesg);
                WHEN OTHERS
                THEN
                    od_message('E',
                                  'Error creating AP invoice for refund - Trx:'
                               || v_refund_hdr.trx_number
                               || ' for Customer'
                               || v_refund_hdr.customer_number
                               || 'Error:'
                               || SQLCODE
                               || ':'
                               || SQLERRM,
                               lc_comn_err_loc);
                    od_message('M',
                                  '***Error at:'
                               || lc_comn_err_loc
                               || '. Rolling back to savepoint:'
                               || lc_savepoint);
                    ROLLBACK TO lc_savepoint;
                    ln_inv_err_count :=   NVL(ln_inv_err_count,
                                              0)
                                        + 1;

                    INSERT INTO xx_ar_refund_error_log
                                (conc_request_id,
                                 err_code,
                                 customer_number,
                                 trx_type,
                                 trx_number,
                                 attribute1)
                         VALUES (ln_conc_request_id,
                                 'R0015',
                                 v_refund_hdr.customer_number,
                                 lc_trx_type,
                                 v_refund_hdr.trx_number,
                                 lc_err_mesg);
            END;

            ln_proc_count :=   NVL(ln_proc_count,
                                   0)
                             + 1;
        END LOOP;

        COMMIT;

        BEGIN
            lc_comn_err_loc := NULL;

            -- If records inserted in ap_suppliers_int table, submit "Supplier Open Interface Import" program
            IF NVL(ln_vendor_cnt,
                   0) > 0
            THEN
                lc_comn_err_loc := 'Submit "Supplier Open Interface Import"';
                ln_req_id :=
                    fnd_request.submit_request('SQLAP'                                                     --application
                                                      ,
                                               'APXSUIMP'                                                      --program
                                                         ,
                                               'Supplier Open Interface Import'                                --chr(0),
                                                                               ,
                                               SYSDATE                                                      --start_time
                                                      ,
                                               FALSE                                                       --sub_request
                                                    ,
                                               --NULL                  --argument1 Added for r12 retrofit. Operating unit. Commented for 5.9 (QC Defect 26375 and 26024)
                                               --    ,
                                               'ALL'                                                        -- argument2
                                                    ,
                                               1000                                                          --argument3
                                                   ,
                                               'N'                                                           --argument4
                                                  ,
                                               'N'                                                           --argument5
                                                  ,
                                               'N'                                                           --argument6
                                                  ,
                                               CHR(0)                                                        --argument7
                                                     ,
                                               CHR(0)                                                        --argument8
                                                     ,
                                               CHR(0)                                                        --argument9
                                                     );

                -- Commit so user can view the request in the application.
                IF (ln_req_id = 0)
                THEN
                    od_message('M',
                               'Error Submitting "Supplier Open Interface Import"');
                    --fnd_message.retrieve;
                    fnd_message.raise_error;
                ELSE
                    COMMIT;
                    -- Wait for request to complete
                    lb_wait :=
                        fnd_concurrent.wait_for_request(ln_req_id,
                                                        20,
                                                        0,
                                                        lc_phase,
                                                        lc_status,
                                                        lc_dev_phase,
                                                        lc_dev_status,
                                                        lc_message);

                    BEGIN
                        FOR vend_err_rec IN (SELECT asi.reject_code,
                                                    xart.refund_header_id,
                                                    xart.customer_number,
                                                    xart.trx_id,
                                                    xart.trx_type,
                                                    xart.trx_number,
                                                    asi.status
                                             FROM   xx_ar_refund_trx_tmp xart,
                                                    ap_suppliers_int asi
                                             WHERE  xart.status = 'X'
                                             AND    xart.customer_number = asi.customer_num
                                             AND    asi.import_request_id = ln_req_id
											 AND    xart.org_id = fnd_global.org_id)--defect#89061
                        LOOP
                            IF vend_err_rec.status = 'PROCESSED'
                            THEN
                                UPDATE xx_ar_refund_trx_tmp
                                SET error_flag = 'N',
                                    status = 'S',
                                    remarks = 'Vendor Created/Matched',
                                    last_update_date = SYSDATE,
                                    last_updated_by = fnd_profile.VALUE('USER_ID'),
                                    last_update_login = fnd_profile.VALUE('LOGIN_ID')
                                WHERE  refund_header_id = vend_err_rec.refund_header_id;
                            ELSIF vend_err_rec.status = 'REJECTED'
                            THEN
                                UPDATE xx_ar_refund_trx_tmp
                                SET error_flag = 'Y',
                                    status = 'X',
                                    remarks = 'Error Creating Supplier',
                                    last_update_date = SYSDATE,
                                    last_updated_by = fnd_profile.VALUE('USER_ID'),
                                    last_update_login = fnd_profile.VALUE('LOGIN_ID')
                                WHERE  refund_header_id = vend_err_rec.refund_header_id;

                                -- Update Invoice Created Status on Transaction
                                IF vend_err_rec.trx_type = 'R'
                                THEN
                                    UPDATE ar_cash_receipts_all acr
                                    SET attribute10 = 'Sent to AP',
                                        last_update_date = SYSDATE                                      -- Defect #13458
                                                                  ,
                                        last_updated_by = fnd_profile.VALUE('USER_ID')                 -- Defect # 13458
                                    WHERE  cash_receipt_id = vend_err_rec.trx_id;
                                ELSE
                                    UPDATE ra_customer_trx_all
                                    SET attribute10 = 'Send to AP',
                                        last_update_date = SYSDATE                                      -- Defect #13458
                                                                  ,
                                        last_updated_by = fnd_profile.VALUE('USER_ID')                 -- Defect # 13458
                                    WHERE  customer_trx_id = vend_err_rec.trx_id;
                                END IF;

                                INSERT INTO xx_ar_refund_error_log
                                            (conc_request_id,
                                             err_code,
                                             customer_number,
                                             trx_type,
                                             trx_number,
                                             attribute1)
                                     VALUES (ln_conc_request_id,
                                             'R0016',
                                             vend_err_rec.customer_number,
                                             DECODE(vend_err_rec.trx_type,
                                                    'R', 'Receipt',
                                                    'Credit Memo'),
                                             vend_err_rec.trx_number,
                                                'Supplier Interface Error:'
                                             || vend_err_rec.reject_code);
                            ELSE
                                NULL;
                            END IF;
                        END LOOP;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            NULL;
                    END;

                    -- Delete from ap_suppliers_int for the request ID and status = 'PROCESSED'
                    -- This needs to be done because, if records sit in Interface table with the vendor name
                    -- and another record is inserted with same vendor name, interface program results in
                    -- error: Vendor Name Already Exists!!!!!!!!!
                    DELETE FROM ap_suppliers_int
                    WHERE       import_request_id = ln_req_id AND status = 'PROCESSED';
                END IF;
            END IF;

            -- If records inserted in ap_supplier_sites_int table
            IF NVL(ln_site_cnt,
                   0) > 0
            THEN
                lc_comn_err_loc := 'Submit "Supplier Sites Open Intf Import" program';
                ln_req_id :=
                    fnd_request.submit_request('SQLAP'                                                     --application
                                                      ,
                                               'APXSSIMP'                                                      --program
                                                         ,
                                               'Supplier Sites Open Interface Import'                      --description
                                                                                     ,
                                               SYSDATE                                                      --start_time
                                                      ,
                                               FALSE                                                       --sub_request
                                                    ,
                                               fnd_profile.value('ORG_ID')  --NULL                  --argument1 Added for r12 retrofit. Operating unit. Passing the operating unit value for 5,9 (Qc Defect 26375 and 26024)
                                                   ,
                                               'ALL'                                                        -- argument2
                                                    ,
                                               1000                                                          --argument3
                                                   ,
                                               'N'                                                           --argument4
                                                  ,
                                               'N'                                                           --argument5
                                                  ,
                                               'N'                                                           --argument6
                                                  ,
                                               CHR(0)                                                        --argument7
                                                     ,
                                               CHR(0)                                                        --argument8
                                                     ,
                                               CHR(0)                                                        --argument9
                                                     );

                IF (ln_req_id = 0)
                THEN
                    od_message('M',
                               '*** Error Submitting "Supplier Sites Open Interface Import"');
                    --fnd_message.retrieve;
                    fnd_message.raise_error;
                ELSE
                    COMMIT;
                    -- Wait for request to complete
                    lb_wait :=
                        fnd_concurrent.wait_for_request(ln_req_id,
                                                        20,
                                                        0,
                                                        lc_phase,
                                                        lc_status,
                                                        lc_dev_phase,
                                                        lc_dev_status,
                                                        lc_message);

                    BEGIN
                        FOR vend_sites_err_rec IN (SELECT xart.refund_header_id,
                                                          xart.customer_number,
                                                          xart.trx_id,
                                                          xart.trx_type,
                                                          xart.trx_number,
                                                          assi.address_line1,
                                                          assi.address_line2,
                                                          assi.city,
                                                          assi.state,
                                                          assi.province,
                                                          assi.zip,
                                                          assi.country,
                                                          assi.reject_code,
                                                          assi.status
                                                   FROM   xx_ar_refund_trx_tmp xart,
                                                          ap_supplier_sites_int assi
                                                   WHERE  xart.status = 'X'
                                                   AND    xart.ap_vendor_site_code = assi.vendor_site_code
                                                   AND    assi.import_request_id = ln_req_id
												   AND    xart.org_id = fnd_global.org_id)--defect#89061
                        LOOP
                            IF vend_sites_err_rec.status = 'PROCESSED'
                            THEN
                                -- Update Invoice Created Status on Transaction
                                IF vend_sites_err_rec.trx_type = 'R'
                                THEN
                                    UPDATE ar_cash_receipts_all acr
                                    SET attribute10 = 'Vendor Created/Matched',
                                        last_update_date = SYSDATE                                      -- Defect #13458
                                                                  ,
                                        last_updated_by = fnd_profile.VALUE('USER_ID')                 -- Defect # 13458
                                    WHERE  cash_receipt_id = vend_sites_err_rec.trx_id;
                                ELSE
                                    UPDATE ra_customer_trx_all
                                    SET attribute10 = 'Vendor Created/Matched',
                                        last_update_date = SYSDATE                                      -- Defect #13458
                                                                  ,
                                        last_updated_by = fnd_profile.VALUE('USER_ID')                 -- Defect # 13458
                                    WHERE  customer_trx_id = vend_sites_err_rec.trx_id;
                                END IF;

                                UPDATE xx_ar_refund_trx_tmp
                                SET error_flag = 'N',
                                    status = 'S',
                                    remarks = 'Vendor Created/Matched',
                                    last_update_date = SYSDATE,
                                    last_updated_by = fnd_profile.VALUE('USER_ID'),
                                    last_update_login = fnd_profile.VALUE('LOGIN_ID')
                                WHERE  refund_header_id = vend_sites_err_rec.refund_header_id;
                            ELSIF vend_sites_err_rec.status = 'REJECTED'
                            THEN
                                -- Update Invoice Created Status on Transaction
                                IF vend_sites_err_rec.trx_type = 'R'
                                THEN
                                    UPDATE ar_cash_receipts_all acr
                                    SET attribute10 = 'Sent to AP',
                                        last_update_date = SYSDATE                                      -- Defect #13458
                                                                  ,
                                        last_updated_by = fnd_profile.VALUE('USER_ID')                 -- Defect # 13458
                                    WHERE  cash_receipt_id = vend_sites_err_rec.trx_id;
                                ELSE
                                    UPDATE ra_customer_trx_all
                                    SET attribute10 = 'Send to AP',
                                        last_update_date = SYSDATE                                      -- Defect #13458
                                                                  ,
                                        last_updated_by = fnd_profile.VALUE('USER_ID')                 -- Defect # 13458
                                    WHERE  customer_trx_id = vend_sites_err_rec.trx_id;
                                END IF;

                                UPDATE xx_ar_refund_trx_tmp
                                SET error_flag = 'Y',
                                    status = 'X',
                                    remarks = 'Error Creating AP Supplier Site',
                                    last_update_date = SYSDATE,
                                    last_updated_by = fnd_profile.VALUE('USER_ID'),
                                    last_update_login = fnd_profile.VALUE('LOGIN_ID')
                                WHERE  refund_header_id = vend_sites_err_rec.refund_header_id;

                                INSERT INTO xx_ar_refund_error_log
                                            (conc_request_id,
                                             err_code,
                                             customer_number,
                                             trx_type,
                                             trx_number,
                                             attribute1,
                                             attribute2)
                                     VALUES (ln_conc_request_id,
                                             'R0017',
                                             vend_sites_err_rec.customer_number,
                                             DECODE(vend_sites_err_rec.trx_type,
                                                    'R', 'Receipt',
                                                    'Credit Memo'),
                                             vend_sites_err_rec.trx_number,
                                                'Supplier Site Interface Error:'
                                             || vend_sites_err_rec.reject_code,
                                                vend_sites_err_rec.address_line1
                                             || ' '
                                             || vend_sites_err_rec.address_line2
                                             || vend_sites_err_rec.city
                                             || ' '
                                             || NVL(vend_sites_err_rec.state,
                                                    vend_sites_err_rec.province)
                                             || ' '
                                             || vend_sites_err_rec.zip
                                             || ' '
                                             || vend_sites_err_rec.country);
                            ELSE
                                NULL;
                            END IF;
                        END LOOP;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            od_message('M',
                                       '*** Error updating Staus on Supplier Site Creation failure');
                    END;

                    -- Delete from ap_supplier_sites_int for the request ID and status = 'PROCESSED'
                    -- This needs to be done because, if records sit in Interface table with the vendor site details
                    -- and another record is inserted with same vendor site details, interface program results in
                    -- error: Vendor Site Already Exists!!!!!!!!!
                    DELETE FROM ap_supplier_sites_int s
                    WHERE       import_request_id = ln_req_id AND s.status = 'PROCESSED';
                END IF;
            END IF;

            IF NVL(ln_inv_count,
                   0) > 0
            THEN
                lc_comn_err_loc := 'Submit "Payables Open Interface Import" program Source:US_OD_AR_REFUND';
                ln_req_id :=
                    fnd_request.submit_request('SQLAP'                                                     --application
                                                      ,
                                               'APXIIMPT'                                                      --program
                                                         ,
                                               'Payables Open Interface Import'                            --description
                                                                               ,
                                               SYSDATE                                                      --start_time
                                                      ,
                                               FALSE                                                       --sub_request
                                                    ,
                                               fnd_profile.value('ORG_ID') --NULL                  --argument1 Added for r12 retrofit. Operating unit. Passing the operating unit value for 5,9 (Qc Defect 26375 and 26024)
                                                   ,
                                               'US_OD_AR_REFUND'                                             --argument2
                                                                ,
                                               CHR(0)                                                        --argument3
                                                     ,
                                                  'REFUND'
                                               || TO_CHAR(SYSDATE,
                                                          'DD-MON-YY')                                       --argument4
                                                                      ,
                                               CHR(0)                                                        --argument5
                                                     ,
                                               CHR(0)                                                        --argument6
                                                     ,
                                               CHR(0)                                                        --argument7
                                                     ,
                                               'N'                                                           --argument8
                                                  ,
                                               'N'                                                           --argument9
                                                  );

                IF (ln_req_id = 0)
                THEN
                    od_message('M',
                               '*** Error Submitting "Payables Open Interface Import" Source:US_OD_AR_REFUND');
                    --fnd_message.retrieve;
                    fnd_message.raise_error;
                ELSE
                    COMMIT;
                    -- Wait for request to complete
                    lb_wait :=
                        fnd_concurrent.wait_for_request(ln_req_id,
                                                        20,
                                                        0,
                                                        lc_phase,
                                                        lc_status,
                                                        lc_dev_phase,
                                                        lc_dev_status,
                                                        lc_message);
                END IF;                                                                    -- Conc Program submission 1.

                lc_comn_err_loc := 'Submit "Payables Open Interface Import" program Source:US_OD_RETAIL_REFUND';
                ln_req_id2 :=
                    fnd_request.submit_request('SQLAP'                                                     --application
                                                      ,
                                               'APXIIMPT'                                                      --program
                                                         ,
                                               'Payables Open Interface Import'                            --description
                                                                               ,
                                               SYSDATE                                                      --start_time
                                                      ,
                                               FALSE                                                       --sub_request
                                                    ,
                                               fnd_profile.value('ORG_ID') --NULL                  --argument1 Added for r12 retrofit. Operating unit. Passing the operating unit value for 5,9 (Qc Defect 26375 and 26024)
                                                   ,
                                               'US_OD_RETAIL_REFUND'                                         --argument2
                                                                    ,
                                               CHR(0)                                                        --argument3
                                                     ,
                                                  'REFUND'
                                               || TO_CHAR(SYSDATE,
                                                          'DD-MON-YY')                                       --argument4
                                                                      ,
                                               CHR(0)                                                        --argument5
                                                     ,
                                               CHR(0)                                                        --argument6
                                                     ,
                                               CHR(0)                                                        --argument7
                                                     ,
                                               'N'                                                           --argument8
                                                  ,
                                               'N'                                                           --argument9
                                                  );

                IF (ln_req_id2 = 0)
                THEN
                    od_message('M',
                               '*** Error Submitting "Payables Open Interface Import" Source:US_OD_AR_REFUND');
                    --fnd_message.retrieve;
                    fnd_message.raise_error;
                ELSE
                    COMMIT;
                    -- Wait for request to complete
                    lb_wait :=
                        fnd_concurrent.wait_for_request(ln_req_id2,
                                                        20,
                                                        0,
                                                        lc_phase,
                                                        lc_status,
                                                        lc_dev_phase,
                                                        lc_dev_status,
                                                        lc_message);
                END IF;                                                                    -- Conc Program submission 2.

                lc_cust_number := NULL;

                FOR inv_recs IN (SELECT *
                                 FROM   ap_invoices_interface
                                 WHERE  request_id IN(ln_req_id, ln_req_id2))
                LOOP
                    IF inv_recs.status = 'PROCESSED'
                    THEN
                        UPDATE xx_ar_refund_trx_tmp
                        SET status = 'V',
                            inv_created_flag = 'Y',
                            ap_inv_creation_date = SYSDATE,
                            remarks = 'AP Invoice Created',
                            error_flag = 'N',
                            last_update_date = SYSDATE,
                            last_updated_by = fnd_profile.VALUE('USER_ID'),
                            last_update_login = fnd_profile.VALUE('LOGIN_ID')
                        WHERE  ap_invoice_number = inv_recs.invoice_num
                        AND    ap_vendor_site_code = inv_recs.vendor_site_code
                        AND    org_id = inv_recs.org_id;

                        BEGIN
                            SELECT trx_id,
                                   trx_type
                            INTO   ln_trx_id,
                                   lc_trx_type
                            FROM   xx_ar_refund_trx_tmp
                            WHERE  ap_invoice_number = inv_recs.invoice_num
                            AND    ap_vendor_site_code = inv_recs.vendor_site_code
                            AND    inv_created_flag = 'Y'
							AND    org_id = fnd_global.org_id;--defect#89061

                            -- Update Invoice Created Status on Transaction
                            IF lc_trx_type = 'R'
                            THEN
                                UPDATE ar_cash_receipts_all acr
                                SET attribute10 = 'Invoice Created',
                                    last_update_date = SYSDATE                                          -- Defect #13458
                                                              ,
                                    last_updated_by = fnd_profile.VALUE('USER_ID')                     -- Defect # 13458
                                WHERE  cash_receipt_id = ln_trx_id;
                            ELSE
                                UPDATE ra_customer_trx_all
                                SET attribute10 = 'Invoice Created',
                                    last_update_date = SYSDATE                                          -- Defect #13458
                                                              ,
                                    last_updated_by = fnd_profile.VALUE('USER_ID')                     -- Defect # 13458
                                WHERE  customer_trx_id = ln_trx_id;
                            END IF;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                od_message('M',
                                              '*** Error Updating Status after successfully creating'
                                           || ' AP Invoice Number:'
                                           || inv_recs.invoice_num);
                        END;
                    ELSIF inv_recs.status = 'REJECTED'
                    THEN
                        UPDATE xx_ar_refund_trx_tmp
                        SET inv_created_flag = 'N',
                            error_flag = 'Y',
                            status = 'X',
                            remarks =    ' Error creating AP Invoice.'
                                      || ' Review Payables Open Invoice Interface Log.',
                            last_update_date = SYSDATE,
                            last_updated_by = fnd_profile.VALUE('USER_ID'),
                            last_update_login = fnd_profile.VALUE('LOGIN_ID')
                        WHERE  ap_invoice_number = inv_recs.invoice_num
                        AND    ap_vendor_site_code = inv_recs.vendor_site_code
                        AND    status IN('X', 'S')
                        AND    org_id = inv_recs.org_id;

                        BEGIN
                            SELECT trx_id,
                                   DECODE(trx_type,
                                          'R', 'Receipt',
                                          'Credit Memo'),
                                   customer_number
                            INTO   ln_trx_id,
                                   lc_trx_type,
                                   lc_cust_number
                            FROM   xx_ar_refund_trx_tmp
                            WHERE  ap_invoice_number = inv_recs.invoice_num
                            AND    ap_vendor_site_code = inv_recs.vendor_site_code
                            AND    inv_created_flag = 'N'
                            AND    error_flag = 'Y'
							AND    org_id = fnd_global.org_id;--defect#89061

                            -- Update Invoice Created Status on Transaction
                            IF lc_trx_type = 'R'
                            THEN
                                UPDATE ar_cash_receipts_all acr
                                SET attribute10 = 'Sent to AP',
                                    last_update_date = SYSDATE                                          -- Defect #13458
                                                              ,
                                    last_updated_by = fnd_profile.VALUE('USER_ID')                     -- Defect # 13458
                                WHERE  cash_receipt_id = ln_trx_id;
                            ELSE
                                UPDATE ra_customer_trx_all
                                SET attribute10 = 'Sent to AP',
                                    last_update_date = SYSDATE                                          -- Defect #13458
                                                              ,
                                    last_updated_by = fnd_profile.VALUE('USER_ID')                     -- Defect # 13458
                                WHERE  customer_trx_id = ln_trx_id;
                            END IF;

                            od_message('M',
                                          'Checking Intf errs for Inv_id:'
                                       || inv_recs.invoice_id
                                       || ' for conc req id:'
                                       || ln_conc_request_id);

                            FOR err_invs IN (SELECT *
                                             FROM   ap_interface_rejections_v
                                             WHERE  invoice_id = inv_recs.invoice_id)
                            LOOP
                                od_message('M',
                                              '*** Error AP INV INTF ERR: Vendor:'
                                           || lc_cust_number
                                           || ' Inv#'
                                           || err_invs.invoice_num
                                           || ' Msg:'
                                           || err_invs.description);

                                INSERT INTO xx_ar_refund_error_log
                                            (conc_request_id,
                                             err_code,
                                             customer_number,
                                             trx_type,
                                             trx_number,
                                             attribute1)
                                     VALUES (ln_conc_request_id,
                                             'R0015',
                                             lc_cust_number,
                                             lc_trx_type,
                                             SUBSTR(inv_recs.invoice_num,
                                                    3),
                                                'Invoice Interface Error:'
                                             || err_invs.description);
                            END LOOP;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                od_message('M',
                                              '*** Error Updating Status for invoices rejected '
                                           || 'in Payables Open Interface'
                                           || ' AP Invoice Number:'
                                           || inv_recs.invoice_num);
                        END;
                    ELSE
                        NULL;
                    END IF;
                END LOOP;                                                                                    --Inv Recs.
            --END IF;                                -- Conc Program submission.
            END IF;                                                                                      --Inv_Count > 0

            od_message('O',
                       '');
            od_message('O',
                       '');
            od_message('O',
                       ' ');
            od_message('O',
                       g_print_line);
            od_message('O',
                       '                                               Process Summary ');
            od_message('O',
                       g_print_line);
            od_message('O',
                       '');
            od_message('O',
                          'Number of Transactions Processed             :'
                       || ln_proc_count);
            od_message('O',
                          'Number of New Vendors created                :'
                       || ln_vendor_cnt);
            od_message('O',
                          'Number of New Vendors Sites created          :'
                       || ln_site_cnt);
            od_message('O',
                          'Number of Refund Invoices Created            :'
                       || ln_inv_count);
            od_message('O',
                          'Number of Invoices not created due to errors :'
                       || ln_inv_err_count);
            od_message('O',
                       '');

            IF ln_inv_err_count > 0
            THEN
                print_errors(ln_conc_request_id);
            END IF;

            update_dffs;
        EXCEPTION
            WHEN OTHERS
            THEN
                DECLARE
                    l_return_code  VARCHAR2(1) := 'E';
                    l_msg_count    NUMBER      := 1;
                BEGIN
                    xx_com_error_log_pub.log_error(p_program_type                => 'CONCURRENT PROGRAM',
                                                   p_program_name                => 'XXARRFNDI',
                                                   p_program_id                  => fnd_profile.VALUE('CONC_REQUEST_ID'),
                                                   p_module_name                 => 'xxfin',
                                                   p_error_location              => lc_comn_err_loc,
                                                   p_error_message_count         => 1,
                                                   p_error_message_code          => 'E',
                                                   p_error_message               =>    SQLCODE
                                                                                    || ':'
                                                                                    || SQLERRM,
                                                   p_error_message_severity      => 'FATAL',
                                                   p_notify_flag                 => 'N',
                                                   p_object_type                 => 'OD Refunds: AP Supplier/Invoice Interface',
                                                   p_object_id                   => NULL,
                                                   p_return_code                 => l_return_code,
                                                   p_msg_count                   => l_msg_count);
                    COMMIT;
                END;
        END;

        update_dffs;
    END;

    -- This procedure is used to synchronize statuses of the DFFs
    --  on the Transactions and receipts screens.
    PROCEDURE update_dffs
    IS
        CURSOR xfer_escheats_cur
        IS
            SELECT        *
            FROM          xx_ar_refund_trx_tmp xart
            WHERE         escheat_flag = 'Y'
            AND           status = 'X'
            AND           xart.last_update_date =
                              (SELECT MAX(last_update_date)
                               FROM   xx_ar_refund_trx_tmp xart2
                               WHERE  customer_id = xart.customer_id
                               AND    trx_type = xart.trx_type
                               AND    trx_number = xart.trx_number)
            FOR UPDATE OF status;

        CURSOR proc_escheats_cur
        IS
            SELECT        *
            FROM          xx_ar_refund_trx_tmp xart
            WHERE         escheat_flag = 'Y'
            AND           status = 'P'
            AND           last_update_date <   SYSDATE
                                             - 14
            AND           last_update_date =
                              (SELECT MAX(last_update_date)
                               FROM   xx_ar_refund_trx_tmp xart2
                               WHERE  customer_id = xart.customer_id
                               AND    trx_type = xart.trx_type
                               AND    trx_number = xart.trx_number)
            FOR UPDATE OF status;

/*
      CURSOR declined_cur IS
        SELECT  *
          FROM xx_ar_refund_trx_tmp xart
         WHERE trx_type != 'E'
           AND status = 'D'
           AND last_update_date < SYSDATE - 14
           AND last_update_date =
                  (SELECT MAX (last_update_date)
                     FROM xx_ar_refund_trx_tmp xart2
                    WHERE customer_id = xart.customer_id
                      AND trx_type = xart.trx_type
                      AND trx_number = xart.trx_number)
         FOR UPDATE OF status;
*/ --Commented for Defect #8300
-- Added for Defect #8300
        CURSOR declined_cur
        IS
            SELECT        *
            FROM          xx_ar_refund_trx_tmp xart
            WHERE         1 = 1
            AND           identification_type != 'E'
            AND           status = 'D'
            AND           last_update_date <   SYSDATE
                                             - 14
			AND           org_id = fnd_global.org_id--defect#89061
            AND           refund_header_id =
                              (SELECT MAX(refund_header_id)
                               FROM   xx_ar_refund_trx_tmp xart2
                               WHERE  1 = 1
                               AND    xart2.trx_id = xart.trx_id
                               AND    xart2.trx_type = xart.trx_type
                               AND    xart2.trx_number = xart.trx_number)
            FOR UPDATE OF status;

-- End of changes for defect #8300

        -- Check for following transactions for purge
        -- Non-Escheats that are paid
        -- Declined Records.
        -- Refunds transferred to AP more than 14 days ago
        -- will be marked in other process
        CURSOR processed_cur
        IS
            SELECT        *
            FROM          xx_ar_refund_trx_tmp xart
            WHERE         identification_type != 'E'
            AND           status IN('P')
            AND           last_update_date <   SYSDATE
                                             - 14
            AND           xart.last_update_date =
                              (SELECT MAX(last_update_date)
                               FROM   xx_ar_refund_trx_tmp xart2
                               WHERE  customer_id = xart.customer_id
                               AND    trx_type = xart.trx_type
                               AND    trx_number = xart.trx_number)
            FOR UPDATE OF status;

        -- Check if invoice was created for
        -- invoices that were transferred to AP
        -- and failed in interface originally
        -- and were re-imported after original submission.
        CURSOR inv_created_cur
        IS
            SELECT        *
            FROM          xx_ar_refund_trx_tmp xart
            WHERE         escheat_flag = 'N'
            AND           inv_created_flag = 'N'
            AND           status IN('X', 'S')
			AND           org_id = fnd_global.org_id--defect#89061
            AND           xart.last_update_date =
                              (SELECT MAX(last_update_date)
                               FROM   xx_ar_refund_trx_tmp xart2
                               WHERE  customer_id = xart.customer_id
                               AND    trx_type = xart.trx_type
                               AND    trx_number = xart.trx_number)
            AND           EXISTS(
                              SELECT 1
                              FROM   ap_invoices api,
                                     ap_vendor_sites_v avs
                              WHERE  avs.vendor_site_id = api.vendor_site_id
                              AND    invoice_num = xart.ap_invoice_number
                              AND    avs.vendor_site_code = xart.ap_vendor_site_code)
            FOR UPDATE OF status, paid_flag;

        -- Check if Invoice has been paid.
        CURSOR paid_cur
        IS
            SELECT        *
            FROM          xx_ar_refund_trx_tmp xart
            WHERE         escheat_flag = 'N'
            AND           inv_created_flag = 'Y'
            AND           status = 'V'
			AND           org_id = fnd_global.org_id--defect#89061
            AND           xart.last_update_date =
                              (SELECT MAX(last_update_date)
                               FROM   xx_ar_refund_trx_tmp xart2
                               WHERE  customer_id = xart.customer_id
                               AND    trx_type = xart.trx_type
                               AND    trx_number = xart.trx_number)
            AND           EXISTS(
                              SELECT 1
                              FROM   ap_invoices api,
                                     ap_vendor_sites_v avs
                              WHERE  (  NVL(amount_paid,
                                            0)
                                      + NVL(discount_amount_taken,
                                            0)) = invoice_amount
                              AND    avs.vendor_site_id = api.vendor_site_id
                              AND    api.invoice_num = xart.ap_invoice_number
                              AND    avs.vendor_site_code = xart.ap_vendor_site_code)
            FOR UPDATE OF status, paid_flag;
    BEGIN
        -- Update processed escheats after 14 days.
        FOR xfer_escheat_rec IN xfer_escheats_cur
        LOOP
            UPDATE xx_ar_refund_trx_tmp
            SET status = 'P',
                error_flag = 'N',
                last_update_date = SYSDATE,
                last_updated_by = fnd_profile.VALUE('USER_ID'),
                last_update_login = fnd_profile.VALUE('LOGIN_ID')
            WHERE CURRENT OF xfer_escheats_cur;
        END LOOP;                                                                                   --Xfer_Escheats_Cur.

        -- Update processed escheats after 14 days.
        FOR proc_escheat_rec IN proc_escheats_cur
        LOOP
            UPDATE xx_ar_refund_trx_tmp
            SET status = 'Z',
                error_flag = 'N',
                last_update_date = SYSDATE,
                last_updated_by = fnd_profile.VALUE('USER_ID'),
                last_update_login = fnd_profile.VALUE('LOGIN_ID')
            WHERE CURRENT OF proc_escheats_cur;
        END LOOP;                                                                                   --Proc_Escheats_Cur.

        -- Mark paid records as processed.
        FOR processed_recs IN processed_cur
        LOOP
            UPDATE xx_ar_refund_trx_tmp
            SET status = 'Z',
                error_flag = 'N'
            WHERE CURRENT OF processed_cur;
        END LOOP;

        -- Mark DFFs of declined records.
        FOR declined_recs IN declined_cur
        LOOP
            -- Update Paid Status on Transaction.
            IF declined_recs.trx_type = 'R'
            THEN
                UPDATE ar_cash_receipts_all acr
                SET attribute9 = 'Decline',
                    attribute10 = 'Declined',
                    last_update_date = SYSDATE                                                          -- Defect #13458
                                              ,
                    last_updated_by = fnd_profile.VALUE('USER_ID')                                     -- Defect # 13458
                WHERE  cash_receipt_id = declined_recs.trx_id;
            ELSE
                UPDATE ra_customer_trx_all
                SET attribute9 = 'Decline',
                    attribute10 = 'Declined',
                    last_update_date = SYSDATE                                                          -- Defect #13458
                                              ,
                    last_updated_by = fnd_profile.VALUE('USER_ID')                                     -- Defect # 13458
                WHERE  customer_trx_id = declined_recs.trx_id;
            END IF;
        END LOOP;

        -- Check for Invoice creation Records.
        FOR inv_created_rec IN inv_created_cur
        LOOP
            UPDATE xx_ar_refund_trx_tmp
            SET status = 'V',
                inv_created_flag = 'Y',
                error_flag = 'N',
                last_update_date = SYSDATE,
                last_updated_by = fnd_profile.VALUE('USER_ID'),
                last_update_login = fnd_profile.VALUE('LOGIN_ID')
            WHERE CURRENT OF inv_created_cur;

            -- Update Paid Status on Transaction.
            IF inv_created_rec.trx_type = 'R'
            THEN
                UPDATE ar_cash_receipts_all acr
                SET attribute10 = 'Invoice Created',
                    last_update_date = SYSDATE                                                          -- Defect #13458
                                              ,
                    last_updated_by = fnd_profile.VALUE('USER_ID')                                     -- Defect # 13458
                WHERE  cash_receipt_id = inv_created_rec.trx_id;

                BEGIN
                    -- Update OM DFF Status to show status.
                    IF inv_created_rec.identification_type = 'OM'
                    THEN
                        UPDATE ar_cash_receipts_all acr
                        SET attribute13 =    'AP INVOICE CREATED|'
                                          || TO_CHAR(SYSDATE,
                                                     'RRRR/MM/DD HH24:MI:SS')
                        WHERE  cash_receipt_id = inv_created_rec.trx_id AND attribute13 LIKE 'ON HOLD|%';

                        UPDATE xx_ar_mail_check_holds
                        SET ap_invoice_id =
                                (SELECT api.invoice_id
                                 FROM   ap_invoices api,
                                        ap_vendor_sites_v avs
                                 WHERE  invoice_num = inv_created_rec.ap_invoice_number
                                 AND    api.vendor_site_id = avs.vendor_site_id
                                 AND    avs.vendor_site_code = inv_created_rec.ap_vendor_site_code),
                            process_code = 'INVOICED'
                        WHERE  process_code IN('PENDING', 'APPLIED')
                        AND    NVL(aops_order_number,
                                   pos_transaction_number) = (SELECT attribute7
                                                              FROM   ar_cash_receipts_all
                                                              WHERE  cash_receipt_id = inv_created_rec.trx_id);
                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        od_message('M',
                                   'Warning: Problem updating INVOICED status on OM Receipt DFF');
                END;
            ELSE
                UPDATE ra_customer_trx_all
                SET attribute10 = 'Invoice Created',
                    last_update_date = SYSDATE                                                          -- Defect #13458
                                              ,
                    last_updated_by = fnd_profile.VALUE('USER_ID')                                     -- Defect # 13458
                WHERE  customer_trx_id = inv_created_rec.trx_id;
            END IF;
        END LOOP;

        -- Check for Paid Records.
        FOR paid_rec IN paid_cur
        LOOP
            UPDATE xx_ar_refund_trx_tmp
            SET status = 'P',
                paid_flag = 'Y',
                error_flag = 'N',
                last_update_date = SYSDATE,
                last_updated_by = fnd_profile.VALUE('USER_ID'),
                last_update_login = fnd_profile.VALUE('LOGIN_ID')
            WHERE CURRENT OF paid_cur;

            -- Update Paid Status on Transaction.
            IF paid_rec.trx_type = 'R'
            THEN
                UPDATE ar_cash_receipts_all acr
                SET attribute10 = 'Paid',
                    last_update_date = SYSDATE,
                    last_updated_by = fnd_profile.VALUE('USER_ID')                                     -- Defect # 13458
                WHERE  cash_receipt_id = paid_rec.trx_id;

                BEGIN
                    -- Update OM DFF Status to show status.
                    IF paid_rec.identification_type = 'OM'
                    THEN
                        UPDATE ar_cash_receipts_all acr
                        SET attribute13 =    'AP INVOICE PAID|'
                                          || TO_CHAR(SYSDATE,
                                                     'RRRR/MM/DD HH24:MI:SS')
                        WHERE  cash_receipt_id = paid_rec.trx_id AND attribute13 IS NOT NULL;

                        UPDATE xx_ar_mail_check_holds
                        SET ap_invoice_id =
                                (SELECT api.invoice_id
                                 FROM   ap_invoices api,
                                        ap_vendor_sites_v avs
                                 WHERE  invoice_num = paid_rec.ap_invoice_number
                                 AND    api.vendor_site_id = avs.vendor_site_id
                                 AND    avs.vendor_site_code = paid_rec.ap_vendor_site_code),
                            process_code = 'PAID'
                        WHERE  process_code IN('PENDING', 'APPLIED')
                        AND    NVL(aops_order_number,
                                   pos_transaction_number) = (SELECT attribute7
                                                              FROM   ar_cash_receipts_all
                                                              WHERE  cash_receipt_id = paid_rec.trx_id);
                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        od_message('M',
                                   'Warning: Problem updating PAID status on OM Receipt DFF');
                END;
            ELSE
                UPDATE ra_customer_trx_all
                SET attribute10 = 'Paid',
                    last_update_date = SYSDATE                                                          -- Defect #13458
                                              ,
                    last_updated_by = fnd_profile.VALUE('USER_ID')                                     -- Defect # 13458
                WHERE  customer_trx_id = paid_rec.trx_id;
            END IF;
        END LOOP;
    EXCEPTION
        WHEN OTHERS
        THEN
            od_message('M',
                          'Error Updating DFFs. '
                       || SQLCODE
                       || ':'
                       || SQLERRM);
    END;

    PROCEDURE get_om_refund_status(
        p_cash_receipt_id  IN             NUMBER,
        x_escheat_flag     OUT NOCOPY     VARCHAR2,
        x_write_off_only   OUT NOCOPY     VARCHAR2,
        x_activity_code    OUT NOCOPY     VARCHAR2,
        x_approved_flag    OUT NOCOPY     VARCHAR2)
    IS
    -- This procedure will check in the OM / Legacy tables to determine
    -- the approval and hold/escheat status of a transaction.
    BEGIN
        x_escheat_flag := 'N';
        x_approved_flag := 'N';
        x_activity_code := NULL;
    END;

    PROCEDURE print_errors(
        p_request_id  IN  NUMBER)
    IS
    BEGIN
        od_message('O',
                   ' ');
        od_message('O',
                   ' ');
        od_message('O',
                   ' ');
        od_message('O',
                   g_print_line);
        od_message('O',
                   '                                               Error Summary');
        od_message('O',
                   g_print_line);
        od_message('O',
                   ' ');
        -- Customer # (10) Type (12) Transaction Number (18)
        od_message('O',
                      'Customer# '
                   || 'Trx Type    '
                   || 'Trx Number        '
                   || 'Error');
        od_message('O',
                   g_print_line);

        FOR v_err_recs IN (SELECT DISTINCT ec.err_code err_code,
                                           el.customer_number,
                                           el.trx_type,
                                           el.trx_number,
                                           REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ec.err_msg,
                                                                                   '<A1>',
                                                                                   el.attribute1),
                                                                           '<A2>',
                                                                           el.attribute2),
                                                                   '<A3>',
                                                                   el.attribute3),
                                                           '<A4>',
                                                           el.attribute4),
                                                   '<A5>',
                                                   el.attribute5) err_msg
                           FROM            xx_ar_refund_error_log el,
                                           xx_ar_refund_err_codes ec
                           WHERE           ec.err_code = el.err_code
                           AND             el.conc_request_id = NVL(p_request_id,
                                                                    fnd_profile.VALUE('CONC_REQUEST_ID'))
                           ORDER BY        1)
        LOOP
            od_message('O',
                          RPAD(SUBSTR(v_err_recs.customer_number,
                                      1,
                                      10),
                               10,
                               ' ')
                       || RPAD(SUBSTR(v_err_recs.trx_type,
                                      1,
                                      12),
                               12,
                               ' ')
                       || RPAD(SUBSTR(v_err_recs.trx_number,
                                      1,
                                      18),
                               18,
                               ' ')
                       || v_err_recs.err_code
                       || ':'
                       || v_err_recs.err_msg,
                       NULL,
                       80);
        END LOOP;
    END;

    PROCEDURE od_message(
        p_msg_type        IN  VARCHAR2,
        p_msg             IN  VARCHAR2,
        p_msg_loc         IN  VARCHAR2 DEFAULT NULL,
        p_addnl_line_len  IN  NUMBER DEFAULT 110)
    IS
        ln_char_count  NUMBER := 0;
        ln_line_count  NUMBER := 0;
    BEGIN
        IF p_msg_type = 'M'
        THEN
            fnd_file.put_line(fnd_file.LOG,
                              p_msg);
        ELSIF p_msg_type = 'O'
        THEN
            /* If message cannot fit on one line,
            -- break into multiple lines */-- fnd_file.put_line(fnd_file.output, p_msg);
            IF NVL(LENGTH(p_msg),
                   0) > 120
            THEN
                FOR x IN 1 ..(  TRUNC(  (  LENGTH(p_msg)
                                         - 120)
                                      / p_addnl_line_len)
                              + 2)
                LOOP
                    ln_line_count :=   NVL(ln_line_count,
                                           0)
                                     + 1;

                    IF ln_line_count = 1
                    THEN
                        fnd_file.put_line(fnd_file.output,
                                          SUBSTR(p_msg,
                                                 1,
                                                 120));
                        ln_char_count :=   NVL(ln_char_count,
                                               0)
                                         + 120;
                    ELSE
                        fnd_file.put_line(fnd_file.output,
                                             LPAD(' ',
                                                    120
                                                  - p_addnl_line_len,
                                                  ' ')
                                          || SUBSTR(LTRIM(p_msg),
                                                      ln_char_count
                                                    + 1,
                                                    p_addnl_line_len));
                        ln_char_count :=   NVL(ln_char_count,
                                               0)
                                         + p_addnl_line_len;
                    END IF;
                END LOOP;
            ELSE
                fnd_file.put_line(fnd_file.output,
                                  p_msg);
            END IF;
        ELSIF p_msg_type = 'E'
        THEN
            fnd_file.put_line(fnd_file.LOG,
                              p_msg);
        /*    DECLARE
               l_return_code         VARCHAR2(1)  := 'E';
               l_msg_count           NUMBER   := 1;
               ln_request_id         NUMBER  := fnd_profile.VALUE ('CONC_REQUEST_ID');
               lc_conc_prog_short_name  fnd_concurrent_programs.concurrent_program_name%TYPE;
            BEGIN
               SELECT concurrent_program_name
                 INTO lc_conc_prog_short_name
                 FROM fnd_concurrent_requests fcr
                    , fnd_concurrent_programs_vl fcp
                WHERE fcr.concurrent_program_id = fcp.concurrent_program_id
                  AND fcr.request_id = ln_request_id;

               XX_COM_ERROR_LOG_PUB.log_error
               ( p_program_type                => 'CONCURRENT PROGRAM'
               , p_program_name                => lc_conc_prog_short_name
               , p_program_id                  => ln_request_id
               , p_module_name                 => 'xxfin'
               , p_error_location              => p_msg_loc
               , p_error_message_count         => 1
               , p_error_message_code          => 'E'
               , p_error_message               => p_msg || ' / ' || SQLCODE || ':' || SQLERRM
               , p_error_message_severity      => 'MAJOR'
               , p_notify_flag                 => 'N'
               , p_object_type                 => 'OD Refunds'
               , p_object_id                   => NULL
               , p_return_code                 => l_return_code
               , p_msg_count                   => l_msg_count );
            END;*/
        END IF;
    END od_message;

    FUNCTION get_status_descr(
        p_status_code   IN  VARCHAR2,
        p_escheat_flag  IN  VARCHAR2)
        RETURN VARCHAR2
    IS
    BEGIN
        IF p_status_code = 'I'
        THEN
            RETURN('01. Identified for Refund');
        ELSIF p_status_code = 'D'
        THEN
            RETURN('02. Declined');
        ELSIF p_status_code = 'W'
        THEN
            RETURN('03. Approved for Adjustment/Write-off');
        ELSIF p_status_code = 'A'
        THEN
            RETURN('04. Adjustment/Write-off Created');
        ELSIF p_status_code = 'S'
        THEN
            RETURN('05. Vendor Created/Matched');
        ELSIF p_status_code = 'X'
        THEN
            IF p_escheat_flag = 'Y'
            THEN
                RETURN('08. Transferred to Abandoned Property database');
            ELSE
                RETURN('06. Transferred to AP');
            END IF;
        ELSIF p_status_code = 'V'
        THEN
            RETURN('07. Invoice Created');
        ELSIF p_status_code = 'P'
        THEN
            IF p_escheat_flag = 'Y'
            THEN
                RETURN('10. Processed - Ready to Purge');
            ELSE
                RETURN('09. Paid - Ready to Purge');
            END IF;
        --Added for defect 15220
        ELSIF p_status_code = 'Z'
        THEN
            RETURN('11. Processed Escheat/Non-Escheat that crossed 14 days');
        ELSE
            RETURN p_status_code;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN p_status_code;
    END;

-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                       WIPRO Technologies                                |
-- +=========================================================================+
-- | Name : Insert_into_int_tables                                           |
-- | Description : Procedure to insert the values in interim tables          |
-- |                                                                  .      |
-- |                                                                         |
-- | Parameters :    Errbuf and retcode                                      |
-- |===============                                                          |
-- |Version   Date          Author              Remarks                      |
-- |=======   ==========   =============   ==================================|
-- |   1      26-MAR-10   Usha R       Initial version--Added for defect 4901|
-- |   2.     05-APR-10   Usha R       Modified the code for defect 4901     |
-- +==========================================================================+
    PROCEDURE insert_into_int_tables(
        errbuf   OUT  VARCHAR2,
        retcode  OUT  NUMBER)
    IS
        ln_open_credits_count  NUMBER := 0;
        ln_open_trans_count    NUMBER := 0;
        ln_total_records       NUMBER := 0;
    BEGIN
        BEGIN
            EXECUTE IMMEDIATE 'TRUNCATE TABLE  xxfin.xx_ar_open_trans_itm';

            fnd_file.put_line(fnd_file.LOG,
                                 'Truncate Ends for xx_ar_open_trans_itm table at '
                              || TO_CHAR(SYSDATE,
                                         'DD/MON/YYYY HH24:MI:SS'));                --Added for defect 4901 on 05-APR-10
--        FND_FILE.PUT_LINE (fnd_file.LOG,'');                                                                                               --Added for defect 4901 on 05-APR-10
        END;

        BEGIN
            EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.xx_ar_open_credits_itm';

            fnd_file.put_line(fnd_file.LOG,
                                 'Truncate Ends for xx_ar_open_credits_itm table at '
                              || TO_CHAR(SYSDATE,
                                         'DD/MON/YYYY HH24:MI:SS'));
            --Added for defect 4901 on 05-APR-10
            fnd_file.put_line(fnd_file.LOG,
                              '');                                                  --Added for defect 4901 on 05-APR-10
        END;

        BEGIN
            --SAVEPOINT sp3;                                                                 --Commented for defect 4901 on 05-APR-10
            INSERT INTO xx_ar_open_trans_itm
                (SELECT /*+PARALLEL(APS,8) FULL(APS)*/
                        *
                 FROM   ar_payment_schedules_all aps
                 WHERE  aps.status = 'OP');

            ln_open_trans_count := SQL%ROWCOUNT;
            fnd_file.put_line(fnd_file.LOG,
                                 'Inserted in xx_ar_open_trans_itm table at '
                              || TO_CHAR(SYSDATE,
                                         'DD/MON/YYYY HH24:MI:SS'));                --Added for defect 4901 on 05-APR-10
--        FND_FILE.PUT_LINE (fnd_file.LOG,'');                                                                                                --Added for defect 4901 on 05-APR-10
            fnd_file.put_line(fnd_file.LOG,
                                 'Total number of records inserted in xx_ar_open_trans_itm '
                              || ln_open_trans_count
                              || ' rows');                                          --Added for defect 4901 on 05-APR-10
            fnd_file.put_line(fnd_file.LOG,
                              '');                                                  --Added for defect 4901 on 05-APR-10
        EXCEPTION
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  'Insertion failed in xx_ar_open_trans_itm');      --Added for defect 4901 on 05-APR-10
                fnd_file.put_line(fnd_file.LOG,
                                  '');                                              --Added for defect 4901 on 05-APR-10
        -- ROLLBACK to SAVEPOINT sp3;                                                --Commented for defect 4901 on 05-APR-10
        END;

        COMMIT;

        BEGIN
            --SAVEPOINT sp4;                                                            --Commented for defect 4901 on 05-APR-10

            --Added hint for defect 4901 on 05-APR-10
            INSERT      /*+ PARALLEL(XAOTI2,8) */INTO xx_ar_open_credits_itm xaoti2
                (SELECT /*+ FULL(XAOTI) PARALLEL(XAOTI,8) */
                        'NON-OM' SOURCE,
                        xaoti.customer_id,
                        xaoti.cash_receipt_id,
                        xaoti.customer_trx_id,
                        xaoti.CLASS,
                        acr.cash_receipt_id trx_id,
                        xaoti.trx_number,
                        xaoti.trx_date,
                        xaoti.invoice_currency_code,
                        xaoti.amount_due_remaining,
                        xaoti.last_update_date aps_last_update_date
/*Escheat is added in the CASE Statement as part of the Defect# 17965 (Previously declined escheatment requests preventing new escheat request on transactions) */
                 ,
                        CASE
                            WHEN acr.attribute9 IN('Send Refund', 'Send Refund Alt', 'Escheat')
                                THEN 'Y'
                            ELSE 'N'
                        END pre_selected_flag,
                        acr.attribute9 refund_request,
                        acr.attribute10 refund_status,
                        xaoti.org_id,
                        NULL bill_to_site_use_id,
                        acr.customer_site_use_id,
                        NULL location_id,
                        NULL address1,
                        NULL address2,
                        NULL address3,
                        NULL city,
                        NULL state,
                        NULL province,
                        NULL postal_code,
                        NULL country,
                        acr.status cash_receipt_status,
                        NULL om_hold_status,
                        NULL om_delete_status,
                        NULL om_store_number,
                        NULL store_customer_name,
                        acr.last_updated_by
                 FROM   xx_ar_open_trans_itm xaoti,
                        ar_cash_receipts_all acr
                 WHERE  acr.cash_receipt_id = xaoti.cash_receipt_id
                 AND    xaoti.CLASS = 'PMT'
                 AND    acr.receipt_method_id NOT IN(
                            SELECT receipt_method_id
                            FROM   ar_receipt_methods arm
                            WHERE  EXISTS(
                                       SELECT 1
                                       FROM   fnd_lookup_values flv
                                       WHERE  lookup_type = 'XX_OD_AR_REFUND_RECEIPT_METHOD'
                                       AND    SYSDATE BETWEEN flv.start_date_active
                                                          AND NVL(flv.end_date_active,
                                                                    SYSDATE
                                                                  + 1)
                                       AND    flv.enabled_flag = 'Y'
                                       AND    flv.meaning = arm.NAME))
                 AND    NOT EXISTS(
                                SELECT 1
                                FROM   xx_ar_refund_trx_tmp
                                WHERE  trx_id = xaoti.cash_receipt_id AND trx_type = 'R' AND status != 'D'
                                       AND ROWNUM = 1)
                 AND    NOT EXISTS(SELECT /*+INDEX(HCA HZ_CUST_ACCOUNTS_U1)*/
                                          1
                                   FROM   hz_cust_accounts hca
                                   WHERE  hca.cust_account_id = xaoti.customer_id AND customer_type = 'I' AND ROWNUM = 1)
                 --  AND XX_AR_GET_CUSTOMER_ID_TYPE(xaoti.customer_id) != 1--Commented for defect 4901 on 05-APR-10
                 AND    xaoti.amount_due_remaining < 0
                 UNION ALL
                 SELECT /*+ FULL(XAOTI) PARALLEL(XAOTI,8) */
                        'NON-OM' SOURCE,
                        xaoti.customer_id,
                        xaoti.cash_receipt_id,
                        xaoti.customer_trx_id,
                        xaoti.CLASS,
                        rct.customer_trx_id trx_id,
                        xaoti.trx_number,
                        xaoti.trx_date,
                        xaoti.invoice_currency_code,
                        xaoti.amount_due_remaining,
                        xaoti.last_update_date aps_last_update_date
/*Escheat is added in the CASE Statement as part of the Defect# 17965 (Previously declined escheatment requests preventing new escheat request on transactions) */
                 ,
                        CASE
                            WHEN rct.attribute9 IN('Send Refund', 'Send Refund Alt', 'Escheat')
                                THEN 'Y'
                            ELSE 'N'
                        END pre_selected_flag,
                        rct.attribute9 refund_request,
                        rct.attribute10 refund_status,
                        xaoti.org_id,
                        rct.bill_to_site_use_id,
                        NULL customer_site_use_id,
                        NULL location_id,
                        NULL address1,
                        NULL address2,
                        NULL address3,
                        NULL city,
                        NULL state,
                        NULL province,
                        NULL postal_code,
                        NULL country,
                        'UNAPP' cash_receipt_status,
                        NULL om_hold_status,
                        NULL om_delete_status,
                        NULL om_store_number,
                        NULL store_customer_name,
                        rct.last_updated_by
                 FROM   xx_ar_open_trans_itm xaoti,
                        ra_customer_trx_all rct
                 WHERE  xaoti.customer_trx_id = rct.customer_trx_id
                 AND    xaoti.CLASS IN('CM', 'INV')
                 AND    NOT EXISTS(
                            SELECT 1
                            FROM   xx_ar_refund_trx_tmp
                            WHERE  trx_id = rct.customer_trx_id AND trx_type IN('C', 'I') AND status != 'D'
                                   AND ROWNUM = 1)
                 AND    NOT EXISTS(SELECT /*+INDEX(HCA HZ_CUST_ACCOUNTS_U1)*/
                                          1
                                   FROM   hz_cust_accounts hca
                                   WHERE  hca.cust_account_id = xaoti.customer_id AND customer_type = 'I' AND ROWNUM = 1)
                 -- AND XX_AR_GET_CUSTOMER_ID_TYPE(xaoti.customer_id) != 1    --Commented for defect 4901 on 05-APR-10
                 AND    xaoti.amount_due_remaining < 0);

            ln_open_credits_count := SQL%ROWCOUNT;
            fnd_file.put_line(fnd_file.LOG,
                                 'Inserted in xx_ar_open_credits_itm table at '
                              || TO_CHAR(SYSDATE,
                                         'DD/MON/YYYY HH24:MI:SS'));                --Added for defect 4901 on 05-APR-10
--      FND_FILE.PUT_LINE (fnd_file.LOG,'');                                                                                                 --Added for defect 4901 on 05-APR-10
            fnd_file.put_line(fnd_file.LOG,
                                 'Total number of records inserted in xx_ar_open_credits_itm '
                              || ln_open_credits_count
                              || ' rows');                                          --Added for defect 4901 on 05-APR-10
            fnd_file.put_line(fnd_file.LOG,
                              '');                                                  --Added for defect 4901 on 05-APR-10
        EXCEPTION
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  'Insertion failed in xx_ar_open_credits_itm');    --Added for defect 4901 on 05-APR-10
                fnd_file.put_line(fnd_file.LOG,
                                  '');                                              --Added for defect 4901 on 05-APR-10
        --ROLLBACK to SAVEPOINT sp4;     --Commented for defect 4901 on 05-APR-10
        END;

        COMMIT;
        ln_total_records :=   ln_open_trans_count
                            + ln_open_credits_count;
        fnd_file.put_line(fnd_file.LOG,
                             'Total number of records for both the tables '
                          || ln_total_records
                          || ' rows');                                              --Added for defect 4901 on 05-APR-10
        fnd_file.put_line(fnd_file.LOG,
                          '');                                                      --Added for defect 4901 on 05-APR-10
    END insert_into_int_tables;

--Commented the function for defect 4901 on 05-APR-2010
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                       WIPRO Technologies                                |
-- +=========================================================================+
-- | Name : xx_ar_get_customer_id_type                                       |
-- | Description : Function is added due to performance issue                |
-- |                                                                  .      |
-- |                                                                         |
-- | Parameters :    x_CUSTOMER_ID                                           |
-- |===============                                                          |
-- |Version   Date          Author              Remarks                      |
-- |=======   ==========   =============   ==================================|
-- |   1      24-MAR-10   Usha R       Initial version--Added for defect 4901|
-- +==========================================================================+
/*FUNCTION xx_ar_get_customer_id_type(x_CUSTOMER_ID IN NUMBER)
        RETURN NUMBER
IS
        l_customer_id_type_exists NUMBER(1);
BEGIN
  BEGIN
      SELECT 1
        INTO l_Customer_ID_Type_Exists
        FROM HZ_CUST_ACCOUNTS HZA
       WHERE CUST_ACCOUNT_ID = x_CUSTOMER_ID
         AND CUSTOMER_TYPE = 'I'
         AND ROWNUM = 1;
  EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_Customer_ID_Type_Exists:=0;
        RETURN l_Customer_ID_Type_Exists;
  END;

  RETURN l_customer_id_type_exists;
END XX_AR_GET_CUSTOMER_ID_TYPE;*/

    -- +=============================================================================+
-- |                  Office Depot - Project Simplify                            |
-- |                       WIPRO Technologies                                    |
-- +=============================================================================+
-- | Name : check_cust                                                           |
-- | Description : Function is added due to performance issue                    |
-- |                                                                  .          |
-- |                                                                             |
-- | Parameters :     p_no_activity_in,p_inact_days,p_customer_id                |
-- |===============                                                              |
-- |Version   Date          Author                  Remarks                      |
-- |=======   ==========   =============   ======================================|
-- |   1      24-MAR-10   Usha R           Initial version--Added for defect 4901|
-- |   3.4    16-MAY-10   Rama Krishna K   Added Cash Receipt Id as IN parameter |
-- |                                       to handle performance issue for UNID  |
-- |                                       for QC #5755                          |
-- |   3.5    20-Jun-10   Abdul Khan       Commented  check_cust procedure for   |
-- |                                       QC Defect 17501. The same procedure   |
-- |                                       is copied with change in sequence of  |
-- |                                       queries to improve performance.       |
-- +=============================================================================+

    -- Commented for QC Defect 17501 - Start
    /*
    FUNCTION check_cust (
       p_no_activity_in IN NUMBER                                                                                                                                        -- parameter
     , p_inact_days IN NUMBER                                                                                                                                         -- from look up
     , p_customer_id IN NUMBER
     , p_cash_receipt_id IN NUMBER
    )
       RETURN NUMBER
    IS
       ln_check                      NUMBER := 0;
    BEGIN
       -- FND_FILE.PUT_LINE (fnd_file.LOG,'Same Customer Check');
       IF (gn_cust_id = p_customer_id)
       THEN
          --FND_FILE.PUT_LINE (fnd_file.LOG,'Same Customer Check - Passed');
          RETURN gn_check;
       ELSE
          gn_cust_id    := p_customer_id;

          --FND_FILE.PUT_LINE (fnd_file.LOG,'Same Customer Check - Failed for Customer '||p_customer_id);
          SELECT COUNT (1)
            INTO ln_check
            FROM DUAL
           WHERE EXISTS (SELECT amount_due_remaining
                           --FROM ar_payment_schedules_all APS         --Commented for defect 4901
                         FROM   xx_ar_open_trans_itm xaoti                                                                                              --Added for defect 4901
                          WHERE xaoti.customer_id = p_customer_id
                            AND xaoti.amount_due_remaining > 0);

          IF (ln_check <> 1)
          THEN
             SELECT COUNT (1)
               INTO ln_check
               FROM DUAL
              WHERE EXISTS (SELECT 1
                              FROM ra_customer_trx_all rct
                             WHERE rct.bill_to_customer_id = p_customer_id
                               AND rct.trx_date >= (SYSDATE - NVL (p_no_activity_in, p_inact_days)));
          END IF;

          IF ln_check <> 1
          THEN
             SELECT COUNT (1)
               INTO ln_check
               FROM DUAL
              WHERE EXISTS (SELECT 1
                              FROM ar_payment_schedules_all aps
                                 , ar_receivable_applications_all ara
                             WHERE ara.cash_receipt_id = aps.cash_receipt_id
                               AND aps.customer_id = p_customer_id
                               AND ara.applied_customer_trx_id IS NOT NULL
                               AND ara.status = 'APP'
                               AND (ara.apply_date >= (SYSDATE - NVL (p_no_activity_in, p_inact_days))));
          END IF;

          IF ln_check <> 1
          THEN
             SELECT COUNT (1)
               INTO ln_check
               FROM DUAL
              WHERE EXISTS (SELECT 1
                              FROM ar_receivable_applications_all ara
                                 , ra_customer_trx_all rct
                             WHERE rct.customer_trx_id = ara.applied_customer_trx_id
                               AND rct.bill_to_customer_id = p_customer_id
                               AND (ara.apply_date >= (SYSDATE - NVL (p_no_activity_in, p_inact_days)))
                               AND ara.status <> 'ACTIVITY');
          END IF;

          -- FND_FILE.PUT_LINE (fnd_file.LOG,'Receipt Date Check for Receipt ID '||p_cash_receipt_id);
          IF ln_check <> 1
          THEN
             SELECT COUNT (1)
               INTO ln_check
               FROM DUAL
              WHERE EXISTS (SELECT 1
                              FROM ar_cash_receipts_all acra
                             WHERE acra.receipt_date >= (SYSDATE - NVL (p_no_activity_in, p_inact_days))
                               -- Modified the below statement to verify for NULL to include the UNIDENTIFIED transactions
                               -- on 5/15 by Rama Krishna K for version 3.4 on 5/16 for QC #5755
                               AND (   acra.pay_from_customer = p_customer_id
                                    OR (    acra.pay_from_customer IS NULL
                                        AND acra.cash_receipt_id = p_cash_receipt_id)));
          END IF;

          -- FND_FILE.PUT_LINE (fnd_file.LOG,'Receipt Date Check for Receipt ID : Result='||ln_check);
          gn_check      := ln_check;
          RETURN ln_check;
       END IF;
    END check_cust;
    */-- Commented for QC Defect 17501 - End

    -- Added for QC Defect 17501 - Start
    FUNCTION check_cust(
        p_no_activity_in   IN  NUMBER,
        p_inact_days       IN  NUMBER,
        p_customer_id      IN  NUMBER,
        p_cash_receipt_id  IN  NUMBER)
        RETURN NUMBER
    IS
        ln_check  NUMBER := 0;
    BEGIN
        IF (gn_cust_id = p_customer_id)
        THEN
            RETURN gn_check;
        ELSE
            gn_cust_id := p_customer_id;

            SELECT COUNT(1)
            INTO   ln_check
            FROM   DUAL
            WHERE  EXISTS(SELECT amount_due_remaining
                          FROM   xx_ar_open_trans_itm xaoti
                          WHERE  xaoti.customer_id = p_customer_id AND xaoti.amount_due_remaining > 0);

            IF ln_check <> 1
            THEN
                SELECT COUNT(1)
                INTO   ln_check
                FROM   DUAL
                WHERE  EXISTS(
                           SELECT 1
                           FROM   ar_cash_receipts_all acra
                           WHERE  acra.receipt_date >=(  SYSDATE
                                                       - NVL(p_no_activity_in,
                                                             p_inact_days))
                           AND    (   acra.pay_from_customer = p_customer_id
                                   OR (acra.pay_from_customer IS NULL AND acra.cash_receipt_id = p_cash_receipt_id)));
            END IF;

            IF (ln_check <> 1)
            THEN
                SELECT COUNT(1)
                INTO   ln_check
                FROM   DUAL
                WHERE  EXISTS(
                           SELECT 1
                           FROM   ra_customer_trx_all rct
                           WHERE  rct.bill_to_customer_id = p_customer_id
                           AND    rct.trx_date >=(  SYSDATE
                                                  - NVL(p_no_activity_in,
                                                        p_inact_days)));
            END IF;

            IF ln_check <> 1
            THEN
                SELECT COUNT(1)
                INTO   ln_check
                FROM   DUAL
                WHERE  EXISTS(
                           SELECT 1
                           FROM   ra_customer_trx_all rct
                           WHERE  rct.bill_to_customer_id = p_customer_id
                           AND    EXISTS(
                                      SELECT 1
                                      FROM   ar_receivable_applications_all ara
                                      WHERE  ara.applied_customer_trx_id = rct.customer_trx_id
                                      AND    (ara.apply_date >=(  SYSDATE
                                                                - NVL(p_no_activity_in,
                                                                      p_inact_days)))
                                      AND    ara.status <> 'ACTIVITY'));
            END IF;

            IF ln_check <> 1
            THEN
                SELECT COUNT(1)
                INTO   ln_check
                FROM   DUAL
                WHERE  EXISTS(
                           SELECT /*+ INDEX (APS AR_PAYMENT_SCHEDULES_N6) */
                                  1
                           FROM   ar_payment_schedules_all aps
                           WHERE  aps.customer_id = p_customer_id
                           AND    EXISTS(
                                      SELECT 1
                                      FROM   ar_receivable_applications_all ara
                                      WHERE  ara.cash_receipt_id = aps.cash_receipt_id
                                      AND    ara.applied_customer_trx_id IS NOT NULL
                                      AND    ara.status = 'APP'
                                      AND    (ara.apply_date >=(  SYSDATE
                                                                - NVL(p_no_activity_in,
                                                                      p_inact_days)))));
            END IF;

            gn_check := ln_check;
            RETURN ln_check;
        END IF;
    END check_cust;
-- Added for QC Defect 17501 - End
END xx_ar_refunds_pkg;

/

SHOW ERRORS;