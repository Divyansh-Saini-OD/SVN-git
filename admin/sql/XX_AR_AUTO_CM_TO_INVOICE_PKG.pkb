CREATE OR REPLACE PACKAGE BODY XX_AR_AUTO_CM_TO_INVOICE_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : XX_AR_AUTO_CM_TO_INVOICE_PKG                                 |
-- | RICE ID : E2057                                                     |
-- | Description : This packages helps to autoapplication                |
-- |               of credit memo to open invoices based                 |
-- |               on the age calculated using profile value             |
-- |                                                                     |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author                 Remarks           |
-- |======   ==========     =============        ======================= |
-- |Draft 1A 26-MAR-2010    Cindhu Nagarajan      Initial version        |
-- |                                              CR 733 Defect 4019     |
-- |1.1      21-APR-2010    Cindhu Nagarajan      Added Parameter for    |
-- |                                              testing purposes for   |
-- |                                              CR 733 Defect 4019     |
-- |1.2      26-APR-2010    Cindhu Nagarajan      Added the Procedure    |
-- |                                              check child requests   |
-- |                                              status and removed     |
-- |                                              submit child procedure |
-- |                                              to improve performance |
-- |                                              for CR 733 Defect 4019 |
-- |1.3      17-MAY-2010    Cindhu Nagarajan      Added for Defect #5183 |
-- |                                              to improve performance |
-- | 1.4     18-May-2010    Subbu Pillai          Addded gather stats    |
-- |                                              command Defect #5183   |
-- | 1.5     28-May-2010    Cindhu Nagarajan      Added gather stats     |
-- |                                              command at partition   |
-- |                                              level by org_id        |
-- |                                              for Defect # 6098      |
-- | 1.6     12-Dec-2011    Maheswararao N        Modified Dispute status|
-- |                                              function logic due to  |
-- |                                              DFF setup for same     |
-- | 1.7     16-Jul-2013    Veronica M            Modified for R12       |
-- |                                              Retrofit Upgrade       |
-- |1.8     30-Oct-2015     Vasu R                Removed schema         |
-- |                                              references for R12.2   |
-- +=====================================================================+

-- +=====================================================================+
-- | Name :  IDENTIFY_CM_MAIN                                            |
-- | RICE ID : E2057                                                     |
-- | Description : This main procedure will call the procedures namely   |
-- |               insert header table, get batch size ,Check Child      |
-- |               requests Status ,generate report procedure            |
-- |               which inturn helps in auto application of cm to inv   |
-- |               based on the age calc using profile value. It helps to|
-- |               get all possible eligible credit memo and insert in   |
-- |               the header and update with batch id for each customer |
-- |               site id.                                              |
-- |                                                                     |
-- | Parameters :  p_batch_size,p_debug_flag,p_bulk_limit,p_cycle_date,  |
-- |               p_cm_number,p_cust_acct_id,p_gather_stats             |
-- | Returns    :  x_err_buff,x_ret_code                                 |
-- +=====================================================================+

   gn_org_id                     NUMBER :=FND_PROFILE.VALUE ('ORG_ID');

PROCEDURE IDENTIFY_CM_MAIN  (x_err_buff        OUT NOCOPY VARCHAR2
                            ,x_ret_code        OUT NOCOPY NUMBER
                            ,p_batch_size      IN  NUMBER
                            ,p_debug_flag      IN  VARCHAR2
                            ,p_bulk_limit      IN  NUMBER
                            ,p_cycle_date      IN  VARCHAR2
                            ,p_cm_number       IN  VARCHAR2
                            ,p_cust_acct_id    IN  NUMBER   -- Added on 21-APR-2010
                            ,p_gather_stats    IN  VARCHAR2 -- Added for Defect# 6098
                            )
IS
 
-- Local Variables Declaration in Main procedure

   ln_count                      NUMBER :=0;
   ln_profile_value              NUMBER := FND_PROFILE.VALUE('XX_AR_AGE_BEYOND_DUE_DATE_FOR_CM_AUTO_APPLICATION');
   ln_cnt_err_request            NUMBER;
   ln_parent_request_id          NUMBER;
   lc_debug_msg                  VARCHAR2(4000);
-- lc_match_type                 VARCHAR2(1000);  ----- Commented on 26/04/2010
   ln_cust_acct_id               NUMBER;

    -- Added on 26-APR-2010 **Start**

-- +=====================================================================+
-- | Name :  Check Child Requests Status                                 |
-- | RICE ID : E2057                                                     |
-- | Description : The procedure is used to print the output in a report |
-- |               The report fields have been updated in the header and |
-- |               detail table. This procedure will fetch those records |
-- |               and give as report output in concurrent program       |
-- |                                                                     |
-- | Parameters :   p_request_id                                         |
-- | Returns    :   x_err_cnt                                            |
-- +=====================================================================+

PROCEDURE CHECK_CHILD_REQUESTS_STATUS( p_request_id  IN  NUMBER
                                      ,x_err_cnt     OUT NUMBER
                                     )
IS

-- Local Variables Declaration

        ln_error_cnt                NUMBER:=0;
        ln_request_id               NUMBER;
        ln_conc_prog_id             NUMBER;
        lb_wait                     BOOLEAN;
        lc_phase                    VARCHAR2(50);
        lc_status                   VARCHAR2(50);
        lc_dev_phase                VARCHAR2(15);
        lc_dev_status               VARCHAR2(15);
        lc_status_code              VARCHAR2(10);
        lc_user_id                  VARCHAR2(100);
        lc_message                  VARCHAR2(2000);

-------------------------------------------------------------------------
-- Cursor to fetch the child requests submitted for matching process-----
-------------------------------------------------------------------------

CURSOR lc_get_child_req
IS
          SELECT request_id
          FROM  FND_AMP_REQUESTS_V
          where parent_request_id=p_request_id;

BEGIN
  DEBUG_MESSAGE('Y','Checking the Child Request for the Request ID   : '||p_request_id);
-------------------------------------------------------------------------
-- Parent Request have to wait until the child requests complete    -----
-- Checking if any child requests have errored out ----------------------
-------------------------------------------------------------------------
  FOR lr_get_child_req IN lc_get_child_req
   LOOP
      lb_wait := FND_CONCURRENT.WAIT_FOR_REQUEST   (lr_get_child_req.request_id
                                                   ,10
                                                   ,NULL
                                                   ,lc_phase
                                                   ,lc_status
                                                   ,lc_dev_phase
                                                   ,lc_dev_status
                                                   ,lc_message
                                                    );

      IF lc_dev_status = 'ERROR' THEN
         ln_error_cnt := ln_error_cnt + 1;
      END IF;

   END LOOP;
      x_err_cnt := ln_error_cnt;

      IF(x_err_cnt<>0)
      THEN
      DEBUG_MESSAGE('Y',x_err_cnt||' Child Requests ended in Error');
      END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'No Data has been found while Checking Child Request Status. No Child has been submitted in the Matching process.');

    WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception raised while Checking Child Requests Status '|| SQLERRM);

END;

 -- Added on 26-APR-2010 **End**

-- +=====================================================================+
-- | Name :  INSERT_HEADER_TABLE                                         |
-- | RICE ID : E2057                                                     |
-- | Description : The procedure will insert all eligible CM into Header |
-- |               table. The eligible CM records will be                |
-- |               fetched and Inserted into Header table to apply on    |
-- |               Invoice. This is a private procedure                  |
-- +=====================================================================+

PROCEDURE INSERT_HEADER_TABLE
IS
-----------------------------------------------------------------------------
------------------ Cursor to fetch all eligible Credit memos ----------------
-----------------------------------------------------------------------------
   CURSOR lcu_eligible_cm_details
   IS
   SELECT     /*+
             LEADING(APS RCT HCP RT)
             USE_NL(APS RCT HCP RT)
             INDEX(RCT RA_CUSTOMER_TRX_U1)
             INDEX(HCP HZ_CUSTOMER_PROFILES_N1)
             INDEX(RT RA_TERMS_B_U1)
                                          */
             RCT.customer_trx_id           cm_customer_trx_id
           , RCT.trx_number                cm_trx_number
           , RCT.purchase_order            cm_po_number
           , APS.amount_due_remaining      cm_amount
           , RCT.trx_date                  cm_trx_date
           , RCT.bill_to_site_use_id       cust_site_id
           , ABS(APS.amount_due_remaining) balance_amount
           , RCT.bill_to_customer_id
           ,'' batch_id
           ,'' request_id
           ,SYSDATE creation_date
           ,'N' error_flg
           ,'' error_msg
           , gn_org_id                     org_id
   FROM    xx_ar_open_trans_itm    APS
          ,ra_customer_trx          RCT
          ,hz_customer_profiles     HCP
          ,ra_terms_b               RT
   WHERE   APS.org_id=gn_org_id
   AND     APS.STATUS='OP'
   AND     APS.class ='CM'
   AND     APS.amount_due_remaining < 0
   AND     APS.customer_trx_id=RCT.customer_trx_id
   AND     RCT.bill_to_customer_id=HCP.cust_account_id
   AND     HCP.site_use_id IS NULL
   AND     NVL(HCP.attribute5,'N') <>'Y'   --- Attribute 5 is Excluded customers from CM Auto Application
   AND     HCP.standard_terms=RT.term_id
   AND     RT.attribute6='Y'               --- Attribute 6 is AB customers Term Flag
   AND     (RCT.trx_date + rt.attribute3 + ln_profile_value) < FND_DATE.CANONICAL_TO_DATE(p_cycle_date); -- Attribute3 signifies Due Days

-----------------------------------------------------------------------------
---------Cursor to get CM detail by passing Credit Memo number---------------
-----------------------------------------------------------------------------

  CURSOR lcu_get_cm_details(p_cm_number IN VARCHAR2)
     IS
     SELECT    RCT.customer_trx_id           cm_customer_trx_id
             , RCT.trx_number                cm_trx_number
             , RCT.purchase_order            cm_po_number
             , APS.amount_due_remaining      cm_amount
             , RCT.trx_date                  cm_trx_date
             , RCT.bill_to_site_use_id       cust_site_id
             , ABS(APS.amount_due_remaining) balance_amount
             , RCT.bill_to_customer_id
             ,'' batch_id
             ,'' request_id
             ,SYSDATE creation_date
             ,'N' error_flg
             ,'' error_msg
             , gn_org_id                     org_id
     FROM    ar_payment_schedules     APS
            ,ra_customer_trx         rct
            ,hz_customer_profiles    HCP
            ,RA_TERMS_B              RT
     where   RCT.TRX_NUMBER =p_cm_number
     AND     APS.status='OP'
     AND     APS.class='CM'
     AND     APS.amount_due_remaining < 0
     AND     APS.customer_trx_id=RCT.customer_trx_id
     AND     RCT.bill_to_customer_id=HCP.cust_account_id
     AND     HCP.site_use_id IS NULL
     AND     NVL(HCP.attribute5,'N') <>'Y'   --- Attribute 5 is Excluded customers from CM Auto Application
     AND     HCP.standard_terms=RT.term_id
     AND     RT.attribute6='Y'               --- Attribute 6 is AB customers Term Flag
     AND     (RCT.trx_date + rt.attribute3 + ln_profile_value) < FND_DATE.CANONICAL_TO_DATE(p_cycle_date); -- Attribute3 signifies Due Days

-----------------------------------------------------------------------------
---------Cursor to get CM detail by passing Customer number------------------
-----------------------------------------------------------------------------
 -- Added on 21-APR-2010 **Start**

    CURSOR lcu_cm_details(p_cust_acct_id IN NUMBER)
     IS
     SELECT    RCT.customer_trx_id           cm_customer_trx_id
             , RCT.trx_number                cm_trx_number
             , RCT.purchase_order            cm_po_number
             , APS.amount_due_remaining      cm_amount
             , RCT.trx_date                  cm_trx_date
             , RCT.bill_to_site_use_id       cust_site_id
             , ABS(APS.amount_due_remaining) balance_amount
             , RCT.bill_to_customer_id
             ,'' batch_id
             ,'' request_id
             ,SYSDATE creation_date
             ,'N' error_flg
             ,'' error_msg
             , gn_org_id                     org_id
     FROM    ar_payment_schedules     APS
            ,ra_customer_trx         RCT
            ,hz_customer_profiles    HCP
            ,ra_terms_b              RT
     WHERE   HCP.cust_account_id=p_cust_acct_id
     AND     APS.status='OP'
     AND     APS.class='CM'
     AND     APS.amount_due_remaining < 0
     AND     APS.customer_trx_id=RCT.customer_trx_id
     AND     RCT.bill_to_customer_id=HCP.cust_account_id
     AND     HCP.site_use_id IS NULL
     AND     NVL(HCP.attribute5,'N') <>'Y'   --- Attribute 5 is Excluded customers from CM Auto Application
     AND     HCP.standard_terms=RT.term_id
     AND     RT.attribute6='Y'               --- Attribute 6 is AB customers Term Flag
     AND     (RCT.trx_date + rt.attribute3 + ln_profile_value) < FND_DATE.CANONICAL_TO_DATE(p_cycle_date); -- Attribute3 signifies Due Days

-- Added on 21-APR-2010 **End**

-----------------------------------------------------------------------------
--Insert the eligible Credit Memo and customer details into Header table ---
-----------------------------------------------------------------------------

--- pl/sql table to hold customer details ---

   TYPE rec_eligible_cm_details IS RECORD(cm_customer_trx_id             xx_ar_auto_app_cminv_hdr.cm_customer_trx_id%TYPE
                                         ,cm_trx_number                  xx_ar_auto_app_cminv_hdr.cm_trx_number%TYPE
                                         ,cm_po_number                   xx_ar_auto_app_cminv_hdr.cm_po_number%TYPE
                                         ,cm_amount                      xx_ar_auto_app_cminv_hdr.cm_amount%TYPE
                                         ,cm_trx_date                    xx_ar_auto_app_cminv_hdr.cm_trx_date%TYPE
                                         ,cust_site_id                   xx_ar_auto_app_cminv_hdr.cust_site_id%TYPE
                                         ,balance_amount                 xx_ar_auto_app_cminv_hdr.balance_amount%TYPE
                                         ,bill_to_customer_id            xx_ar_auto_app_cminv_hdr.bill_to_customer_id%TYPE
                                         ,batch_id                       xx_ar_auto_app_cminv_hdr.batch_id%TYPE
                                         ,request_id                     xx_ar_auto_app_cminv_hdr.request_id%TYPE
                                         ,creation_date                  xx_ar_auto_app_cminv_hdr.creation_date%TYPE
                                         ,error_flg                      xx_ar_auto_app_cminv_hdr.error_flg%TYPE
                                         ,error_msg                      xx_ar_auto_app_cminv_hdr.error_msg%TYPE
                                         ,org_id                         xx_ar_auto_app_cminv_hdr.org_id%TYPE
                                         );
   lr_eligible_cm_details          rec_eligible_cm_details;

   TYPE tab_eligible_cm_details IS TABLE OF lr_eligible_cm_details%TYPE
   INDEX BY BINARY_INTEGER;

   lt_eligible_cm_details           tab_eligible_cm_details;

BEGIN

   --DELETE FROM XXFIN.xx_ar_auto_app_cminv_hdr WHERE org_id=gn_org_id;              -- Commented for Defect#5183
   --DELETE FROM XXFIN.xx_ar_auto_app_cminv_dtl WHERE org_id=gn_org_id;              -- Commented for Defect#5183

  -- Added for Defect # 5183  ** START**
   EXECUTE IMMEDIATE ('ALTER TABLE XXFIN.XX_AR_AUTO_APP_CMINV_HDR TRUNCATE PARTITION XX_AR_AUTO_APP_CMINV_HDR_'||gn_org_id);
   EXECUTE IMMEDIATE ('ALTER TABLE XXFIN.XX_AR_AUTO_APP_CMINV_DTL TRUNCATE PARTITION XX_AR_AUTO_APP_CMINV_DTL_'||gn_org_id);

  -- Added for Defect # 5183  ** End**

---------------------------------------------------------------------------------------
----- Open the cursor to fetch eligible cm records based on the parameters passed------
---------------------------------------------------------------------------------------

----- Both the Values of Credit Memo Number and Customer Number is NULL

   IF (p_cm_number IS NULL AND p_cust_acct_id IS NULL)
   THEN
     OPEN lcu_eligible_cm_details;
     LOOP
     FETCH lcu_eligible_cm_details BULK COLLECT INTO lt_eligible_cm_details LIMIT p_bulk_limit;
       IF lt_eligible_cm_details.COUNT > 0 THEN
         FORALL i IN 1..lt_eligible_cm_details.LAST
         INSERT INTO xx_ar_auto_app_cminv_hdr
         VALUES lt_eligible_cm_details(i);
         ln_count:=ln_count+SQL%ROWCOUNT;
       ELSE
         EXIT;
       END IF;
     END LOOP;
     CLOSE lcu_eligible_cm_details; --- Close cursor

----- Customer number is NULL and Credit memo is not NULL

   ELSIF (p_cm_number IS NOT NULL AND p_cust_acct_id IS NULL)
   THEN
     OPEN lcu_get_cm_details(p_cm_number);
     LOOP
     FETCH lcu_get_cm_details BULK COLLECT INTO lt_eligible_cm_details LIMIT p_bulk_limit;
       IF lt_eligible_cm_details.COUNT > 0 THEN
         FORALL i IN 1..lt_eligible_cm_details.LAST
         INSERT INTO xx_ar_auto_app_cminv_hdr
         VALUES lt_eligible_cm_details(i);
         ln_count:=ln_count+SQL%ROWCOUNT;
       ELSE
         EXIT;
       END IF;
     END LOOP;
     CLOSE lcu_get_cm_details; --- Close cursor

------ Credit memo is NULL and Customer Number is not NULL

   ELSIF (p_cm_number IS NULL AND p_cust_acct_id IS NOT NULL)
   THEN
     OPEN lcu_cm_details(p_cust_acct_id);
     LOOP
     FETCH lcu_cm_details BULK COLLECT INTO lt_eligible_cm_details LIMIT p_bulk_limit;
       IF lt_eligible_cm_details.COUNT > 0 THEN
         FORALL i IN 1..lt_eligible_cm_details.LAST
         INSERT INTO xx_ar_auto_app_cminv_hdr
         VALUES lt_eligible_cm_details(i);
         ln_count:=ln_count+SQL%ROWCOUNT;
       ELSE
         EXIT;
       END IF;
     END LOOP;
     CLOSE lcu_cm_details;   --- Close cursor

------ Both Credit memo and Customer Number is Not NULL

 ---- Added on 21-APR-2010 **START**
   ELSIF (p_cm_number IS NOT NULL AND p_cust_acct_id IS NOT NULL)
   THEN
-------------------------------------------------------------------------------------------------
--- Check the passed Customer number is matching with Credit memo number passed. If not exit-----
-------------------------------------------------------------------------------------------------
      SELECT HCA.cust_account_id
      INTO   ln_cust_acct_id
      FROM  hz_cust_accounts    HCA
           ,ra_customer_trx_all RCT
      WHERE RCT.bill_to_customer_id=HCA.cust_account_id
      AND   RCT.trx_number=p_cm_number;

    IF(p_cust_acct_id = ln_cust_acct_id)
    THEN
     OPEN lcu_get_cm_details(p_cm_number);
     LOOP
     FETCH lcu_get_cm_details BULK COLLECT INTO lt_eligible_cm_details LIMIT p_bulk_limit;
       IF lt_eligible_cm_details.COUNT > 0 THEN
         FORALL i IN 1..lt_eligible_cm_details.LAST
         INSERT INTO xx_ar_auto_app_cminv_hdr
         VALUES lt_eligible_cm_details(i);
         ln_count:=ln_count+SQL%ROWCOUNT;
       ELSE
         EXIT;
       END IF;
     END LOOP;
     CLOSE lcu_get_cm_details; --- Close cursor
    ELSE
       FND_FILE.PUT_LINE(FND_FILE.LOG,' Credit Memo ' || p_cm_number || ' does not match with the Cust Account ID ' || p_cust_acct_id ||
                                      '..Exiting from Insert Header table..');
       RETURN;
    END IF;
    ---- Added on 21-APR-2010 **END**

   END IF;

   FND_FILE.PUT_LINE(FND_FILE.LOG,'+---------------------------------------------------------------------------+');
   FND_FILE.PUT_LINE(FND_FILE.LOG,' Total number of records Inserted in the Header Interim Table is ' || ln_count);
   COMMIT;

EXCEPTION
    WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception raised while Inserting in Header table '|| SQLERRM);

END INSERT_HEADER_TABLE;


PROCEDURE GET_BATCH_SIZE
IS

-- +=====================================================================+
-- | Name :  GET_BATCH_SIZE                                              |
-- | RICE ID : E2057                                                     |
-- | Description : The procedure is used to get the batch size in terms  |
-- |               with customer site id. The batch id will be created   |
-- |               for customer site id using batching logic and will get|
-- |               updated into the header table. This is a private      |
-- |               procedure                                             |
-- +=====================================================================+

------------------------------------------------------------
-- Local Variables Declaration in get batch size procedure--
------------------------------------------------------------

    ln_batch_size           NUMBER;
    ln_tot_customers        NUMBER;
    ln_batch_id             NUMBER;
    ln_batch_indx           NUMBER := 1;
    ln_batch_count          NUMBER := 0;
    ln_request_id           NUMBER ;
    ln_ref_child_req_id     NUMBER ; -- -- Added on 26-APR-2010
    lb_print_option         BOOLEAN;

-----------------------------------------------------------------------------
--------------- pl/sql table to hold all batch Id's created------------------
-----------------------------------------------------------------------------

      CURSOR lcu_cust_site_id
      IS
        SELECT    COUNT(*) cnt
                 ,cust_site_id
        FROM     xx_ar_auto_app_cminv_hdr
        WHERE    org_id=gn_org_id
        GROUP BY cust_site_id;

BEGIN
        ln_request_id := FND_GLOBAL.CONC_REQUEST_ID;

-------------------------------------------------------------------
--------------- Updating Batch id in Header Table------------------
-------------------------------------------------------------------
   FOR lr_cust_site_id IN lcu_cust_site_id
   LOOP

      IF ln_batch_count = 0 OR ln_batch_count + lr_cust_site_id.cnt > p_batch_size
      THEN

-------------------------------------------------------------------
---------- Submitting Child Program to do Matching Process---------
-------------------------------------------------------------------

-- Added on 26-APR-2010 **Start**
        IF ln_batch_count = 0 THEN
          DEBUG_MESSAGE('Y','Entered into First Record in Batching');
        ELSE
          DEBUG_MESSAGE(p_debug_flag,'The Count of Batched Records is  '||to_char(ln_batch_count + lr_cust_site_id.cnt));

                                -----Call the Set print option for the Child program to have # of copies to be 0.
            -----Otherwise the child program will complete in Warning.

          lb_print_option := fnd_request.set_print_options(
                                                        copies            => 0
                                                       );
          ln_ref_child_req_id := FND_REQUEST.SUBMIT_REQUEST(
                                                           'XXFIN'
                                                           ,'XXARCMMATCHP'
                                                           ,NULL
                                                           ,NULL
                                                           ,FALSE
                                                           ,ln_batch_id
                                                           ,p_debug_flag
                                                           ,p_cycle_date
                                                           );
           COMMIT;
                          IF ln_ref_child_req_id > 0
                          THEN
                                DEBUG_MESSAGE('Y','The Child Request '||ln_ref_child_req_id||' has been submitted');
                          END IF;
        END IF;
-- Added on 26-APR-2010 **End**

-------------------------------------------------------------------
-------------- Getting Batch Value from Sequence-------------------
-------------------------------------------------------------------
         SELECT xx_ar_auto_app_cminv_s.NEXTVAL
         INTO ln_batch_id
         FROM dual;
         DEBUG_MESSAGE('Y','Batch ID is '||ln_batch_id); --- Added on 26-APR-2010
         ln_batch_count := lr_cust_site_id.cnt;
      ELSE
           ln_batch_count := ln_batch_count + lr_cust_site_id.cnt;
      END IF;
-------------------------------------------------------------------
------ Updating Batch Id in Header Table for each Cust site id-----
-------------------------------------------------------------------

         UPDATE xx_ar_auto_app_cminv_hdr
         SET batch_id = ln_batch_id
            ,request_id = ln_request_id
         WHERE cust_site_id = lr_cust_site_id.cust_site_id;
         COMMIT;
   END LOOP;

-- Added on 26-APR-2010 **Start**
--------------------------------------------------------------------------------
----The final child needs to be submitted after the final updates of batch id---
--------------------------------------------------------------------------------

-----Call the Set print option for the Child program to have # of copies to be 0.
-----Otherwise the child program will complete in Warning.

        lb_print_option := fnd_request.set_print_options(
                                                        COPIES            => 0
                                                       );

        ln_ref_child_req_id := FND_REQUEST.SUBMIT_REQUEST(
                                                          'XXFIN'
                                                         ,'XXARCMMATCHP'
                                                         ,NULL
                                                         ,NULL
                                                         ,FALSE
                                                         ,ln_batch_id
                                                         ,p_debug_flag
                                                         ,p_cycle_date
                                                          );
           COMMIT;
-- Added on 26-APR-2010 **End**
                          IF ln_ref_child_req_id > 0
                          THEN
                                DEBUG_MESSAGE('Y','The Child Request '||ln_ref_child_req_id||' has been submitted');
                          END IF;

           FND_FILE.PUT_LINE(FND_FILE.LOG,' Updated Batch Id in Header Table');

EXCEPTION
   WHEN OTHERS THEN
   FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception raised in Batch Size Procedure '|| SQLERRM);

END GET_BATCH_SIZE;

-------------------------------------------------------------------
----------- Main Procedure Starts ---------------------------------
-------------------------------------------------------------------

BEGIN
mo_global.set_policy_context('S',gn_org_id);        -- Added for R12 Retrofit Upgrade by Veronica on 16-Jul-2013

     FND_FILE.PUT_LINE(FND_FILE.LOG,'+---------------------------------------------------------------------------+');
     FND_FILE.PUT_LINE(FND_FILE.LOG,' Parameters');
     FND_FILE.PUT_LINE(FND_FILE.LOG,'-----------');
     FND_FILE.PUT_LINE(FND_FILE.LOG,' Batch Size          :' ||p_batch_size);
     FND_FILE.PUT_LINE(FND_FILE.LOG,' Bulk Limit          :' ||p_bulk_limit);
     FND_FILE.PUT_LINE(FND_FILE.LOG,' Debug Flag          :' ||p_debug_flag);
     FND_FILE.PUT_LINE(FND_FILE.LOG,' Cycle Date          :' ||p_cycle_date);
     FND_FILE.PUT_LINE(FND_FILE.LOG,' CM Number           :' ||p_cm_number);
     FND_FILE.PUT_LINE(FND_FILE.LOG,' Cust Account ID     :' ||p_cust_acct_id);
     FND_FILE.PUT_LINE(FND_FILE.LOG,' Gather Stats Flag   :' ||p_gather_stats);   -- Added for Defect # 6098
     FND_FILE.PUT_LINE(FND_FILE.LOG,'+---------------------------------------------------------------------------+');
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Profile Value        :' ||ln_profile_value);
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Org ID               :' ||gn_org_id);
     FND_FILE.PUT_LINE(FND_FILE.LOG,'');

     lc_debug_msg:= 'Calling Insert Header Table Procedure';
     DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);

-------------------------------------------------------------------
----------- Calling Insert Header Table Procedure------------------
-------------------------------------------------------------------
     insert_header_table;

     lc_debug_msg := 'Insert Header Table Procedure Complete..';
     DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);

 -- Added for Defect #5183  - Addition of Gather stats on Header table  ** Start**
     IF(ln_count>0 AND p_gather_stats = 'Y')
     THEN
                  lc_debug_msg := 'Eligible CM details Updated in Header Table';
                  debug_message(p_debug_flag,lc_debug_msg);
                                                debug_message('Y','--------------------------------------------------');
                  debug_message('Y','Gather Stats for Header Table Start - '||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
              --  fnd_stats.gather_table_stats('XXFIN','XX_AR_AUTO_APP_CMINV_HDR');  -- Commenting for Defect # 6098

                  fnd_stats.gather_table_stats('XXFIN','XX_AR_AUTO_APP_CMINV_HDR',NULL,NULL,'XX_AR_AUTO_APP_CMINV_HDR_'||gn_org_id);  -- Added for Defect# 6098
                  debug_message('Y','Gather Stats for Header Table End - '||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
                                                debug_message('Y','--------------------------------------------------');
     END IF;
 -- Added for Defect #5183  - Addition of Gather stats on Header table  ** End**


-------------------------------------------------------------------------
------ To check the count of records inserted into header table----------
------If count is more than zero then call batching procedure -----------
------If count is equal to zero then no eligible cm records available ---
-------------------------------------------------------------------------
   IF(ln_count>0)
   THEN
     lc_debug_msg:= 'Calling Get Batch Size Procedure..';
     debug_message(p_debug_flag,lc_debug_msg);



------------------------------------------------------------------------------------
------- Calling get batch size procedure for batching of records in header table------
--------------------------------------------------------------------------------------
     get_batch_size;

     lc_debug_msg := 'Get Batch Size Procedure Complete..';
     DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);

     lc_debug_msg := 'Batch size Updated in Header table ';
     DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);

---- Commented on 26/04/2010 to improve Performance ** START**

/*   lc_debug_msg:= 'Calling Submit child Procedure for Reference Match..';
     DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);

-----------------------------------------------------
------- Calling Submit Child procedure -------------
-----------------------------------------------------
     lc_match_type := 'R';
    -- submit_child(p_debug_flag,p_cycle_date,lc_match_type,ln_cnt_err_request);

   IF ln_cnt_err_request <> 0
   THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,ln_cnt_err_request ||' Child Requests are Errored Out.Please, Check the Child Requests LOG for Details');
       x_ret_code := 2; -- Assign retcode value as 2 to error out the parent request
       RETURN;
   END IF;

     lc_debug_msg:= 'Calling Submit Child Procedure for Exact Amount Match..';
     DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);

     LC_MATCH_TYPE :='E';
     --submit_child(p_debug_flag,p_cycle_date,lc_match_type,ln_cnt_err_request);

     lc_debug_msg := 'Submit Child procedure Completed..';
     DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);     */

---- Commented on 26/04/2010 to improve Performance ** END**

-----------------------------------------------------
--Calling Check Child Requests status  procedure ----
-----------------------------------------------------
     lc_debug_msg:= 'Check Child Requests Status Procedure Starts..';
     DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);

     check_child_requests_status(fnd_global.conc_request_id, ln_cnt_err_request);
-------------------------------------------------------
------- Calling Generate report procedure -------------
-------------------------------------------------------
     generate_report(p_debug_flag,p_gather_stats);   -- p_gather_stats is Added for Defect # 6098

     lc_debug_msg := 'Generate Report Procedure Completed..';
     DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);

-----------------------------------------------------------
------- Check whether any child programs have errored out--
------- If any then parent should also error out-----------
-----------------------------------------------------------
     IF ln_cnt_err_request <> 0
     THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,ln_cnt_err_request ||' Child Request Errored Out.Please, Check the Child Request LOG for Details');
       x_ret_code := 2; -- Assign retcode value as 2 to error out the parent request
     END IF;
   FND_FILE.PUT_LINE(FND_FILE.LOG,'All Eligible CM applied Successfully with Matched Invoice.. Identify CM Main Procedure Complete..');

   ELSE
       FND_FILE.PUT_LINE(FND_FILE.LOG,' NO eligible CM records has been found. No records Inserted in Header table. ');
   END IF;

EXCEPTION
WHEN OTHERS THEN
FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception raised in main procedure'|| SQLERRM);

END IDENTIFY_CM_MAIN;   -- End of Main procedure

---- Commented on 26/04/2010 to improve Performance ** START**

/*-- +=====================================================================+
-- | Name :  SUBMIT_CHILD                                                |
-- | Description : The procedure is used to submit the cm match program. |
-- |               All eligible credit memo match with open invoices by  |
-- |               reference match and exact amount match. Submit child  |
-- |               helps to submit the cm match procedure which inturn   |
-- |               call the reference match and exact amount match       |
-- |               procedures.                                           |
-- |                                                                     |
-- | Parameters :  p_debug_flag,p_cycle_date                             |
-- +=====================================================================+
PROCEDURE SUBMIT_CHILD(p_debug_flag   IN VARCHAR2
                      ,p_cycle_date   IN VARCHAR2
                      ,p_match_type   IN VARCHAR2
                      ,x_error        OUT NUMBER
                      )
IS

-------------------------------------------------------------------
------ Local variables declaration in submit child procedure-------
-------------------------------------------------------------------
   ln_request_id          NUMBER(15);
   lc_request_data        VARCHAR2(15);
   lc_debug_msg           VARCHAR2(4000);

   lc_message             VARCHAR2 (2000);
   lc_phase               VARCHAR2 (50);
   lc_status              VARCHAR2 (50);
   lc_dev_phase           VARCHAR2 (15);
   lc_dev_status          VARCHAR2 (15);
   lb_wait                BOOLEAN;
   ln_indx                NUMBER := 1;
   ln_error_cnt           NUMBER;

-------------------------------------------------------------------
----------------- Get batch id from header table-------------------
-------------------------------------------------------------------

   CURSOR lcu_batch_id
   IS
   SELECT DISTINCT batch_id
   FROM xx_ar_auto_app_cminv_hdr
   WHERE org_id=gn_org_id;

    -- pl/sql table to hold all batch Id's created.
   TYPE batch_id_rec_type IS RECORD
        (request_id   NUMBER
        ,status       VARCHAR2 (50)
        );

   lr_batch_id        batch_id_rec_type;

   TYPE batch_id_tbl_type IS TABLE OF lr_batch_id%TYPE
   INDEX BY BINARY_INTEGER;

   lt_batch_id        batch_id_tbl_type;

BEGIN
        ln_error_cnt := 0;

        lc_debug_msg := 'Submitting CM Match Process Procedure.';
        DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);

      FOR lr_batch_id IN lcu_batch_id
      LOOP
              ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                                                           'XXFIN'
                                                           ,'XXARCMMATCHP'
                                                           ,null
                                                           ,null
                                                           ,FALSE
                                                           ,p_match_type
                                                           ,lr_batch_id.batch_id
                                                           ,p_debug_flag
                                                           ,p_cycle_date
                                                           );
           COMMIT;

       IF ln_request_id = 0  THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,' **** Request id - Reference match type ****  ' || ln_request_id);
          x_error:= 1;
       ELSE
          lc_debug_msg :=  'Request ID               :  '||ln_request_id;
          DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);
          lt_batch_id(ln_indx).request_id := ln_request_id;
          ln_indx := ln_indx +1;
          x_error:= 0;
       END IF;
      END LOOP;

         IF(p_match_type='E') THEN
            lb_wait := fnd_concurrent.wait_for_request (ln_request_id
                                                       ,10
                                                       ,NULL
                                                       ,lc_phase
                                                       ,lc_status
                                                       ,lc_dev_phase
                                                       ,lc_dev_status
                                                       ,lc_message
                                                        );
          IF lc_dev_status = 'ERROR' THEN
             ln_error_cnt := ln_error_cnt + 1;
          END IF;
       END IF;

   IF ln_error_cnt > 0 THEN
   FND_FILE.PUT_LINE(FND_FILE.LOG,' Child Requests are Errored in CM Match Process Procedure.Please, Check it for details');
   x_error:= 2;
   END IF;

        lc_debug_msg := 'CM Match Process Procedure Completed..';
        DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);

EXCEPTION
   WHEN OTHERS THEN
   FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception raised while submitting CM match process program from submit child'|| SQLERRM);

END SUBMIT_CHILD;*/

---- Commented on 26/04/2010 to improve Performance ** END**

-- +=====================================================================+
-- | Name :  APPLY_CM_INV_PROCESS                                        |
-- | Description : The procedure is used to call standard api to auto    |
-- |               apply open cm to invoice                              |
-- | Parameters :  p_batch_id, p_inv_customer_trx_id                     |
-- |               p_payment_schedule_id,p_amount_applied                |
-- |               ,p_msg_comments,p_user_id,p_resp_id                   |
-- |               ,p_resp_appl_id,p_debug_flag,p_cycle_date             |
-- | Returns    :  x_msg_count,x_msg_data                                |
-- +=====================================================================+
PROCEDURE APPLY_CM_INV_PROCESS (p_cm_customer_trx_id    IN  NUMBER
                               ,p_cm_trx_number         IN VARCHAR2
                               ,p_inv_customer_trx_id   IN  NUMBER
                               ,p_inv_trx_number        IN VARCHAR2
                               ,p_payment_schedule_id   IN  NUMBER
                               ,p_amount_applied        IN  NUMBER
                               ,p_msg_comments          IN  VARCHAR2
                               ,p_user_id               IN  NUMBER
                               ,p_resp_id               IN  NUMBER
                               ,p_resp_appl_id          IN  NUMBER
                               ,p_debug_flag            IN  VARCHAR2
                               ,p_cycle_date            IN  VARCHAR2
                               ,x_msg_count             OUT NUMBER
                               ,x_msg_data              OUT VARCHAR2
                               ,p_return_status         OUT VARCHAR2
                               )
IS

--Local Variables Declaration

        ln_msg_count                    NUMBER  := 0;
        lc_msg_data                     VARCHAR2(255);
        ln_out_rec_application_id       NUMBER;
        lc_error_msg                    VARCHAR2(4000);
        lc_debug_msg                    VARCHAR2(4000);
        ln_api_version                  CONSTANT NUMBER := 1;
        lc_init_msg_list                CONSTANT VARCHAR2(1) := FND_API.g_true;
        lc_comments                     CONSTANT ar_receivable_applications.comments%TYPE := p_msg_comments;
        lc_commit                       CONSTANT VARCHAR2(1) := FND_API.g_false;
        ln_acctd_amount_applied_from    ar_receivable_applications.acctd_amount_applied_from%TYPE;
        ln_acctd_amount_applied_to      ar_receivable_applications.acctd_amount_applied_to%TYPE;
        lr_cm_app_rec                   AR_CM_API_PUB.cm_app_rec_type;
        lc_return_status                VARCHAR2(1000);

BEGIN
-----------------------------------------------------------------------------------------------------------------
-- Calling standard API to apply CM to invoice-------------------------------------------------------------------
-- First set the environment of the user submitting the request by submitting fnd_global.apps_initialize()-------
--The procedure requires three parameters ... Fnd_Global.apps_initialize(userId,responsibilityId,applicationId)--
-----------------------------------------------------------------------------------------------------------------

        Fnd_Global.apps_initialize(p_user_id,p_resp_id,p_resp_appl_id);


        lc_debug_msg :='User ID           : ' || p_user_id;
        DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);
        lc_debug_msg :='Responsiblity ID  : ' || p_resp_id;
        DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);
        lc_debug_msg :='Application ID    : ' || p_resp_appl_id;
        DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);
        lc_debug_msg :='Passing values in Apply CM Inv Process Procedure to call Standard API';
        DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);


        lr_cm_app_rec.cm_customer_trx_id        := p_cm_customer_trx_id;
        lr_cm_app_rec.cm_trx_number             := null; -- Credit Memo Number
        lr_cm_app_rec.inv_customer_trx_id       := p_inv_customer_trx_id;
        lr_cm_app_rec.inv_trx_number            := null ; -- Invoice Number
        lr_cm_app_rec.installment               := null;
        lr_cm_app_rec.amount_applied            := p_amount_applied;
        lr_cm_app_rec.applied_payment_schedule_id := p_payment_schedule_id;
        lr_cm_app_rec.apply_date                := p_cycle_date;
        lr_cm_app_rec.gl_date                   := p_cycle_date;
        lr_cm_app_rec.inv_customer_trx_line_id  := null;
        lr_cm_app_rec.inv_line_number           := null;
        lr_cm_app_rec.show_closed_invoices      := null;
        lr_cm_app_rec.ussgl_transaction_code    := null;
        lr_cm_app_rec.attribute_category        := null;
        lr_cm_app_rec.attribute1                := null;
        lr_cm_app_rec.attribute2                := null;
        lr_cm_app_rec.attribute3                := null;
        lr_cm_app_rec.attribute4                := null;
        lr_cm_app_rec.attribute5                := null;
        lr_cm_app_rec.attribute6                := null;
        lr_cm_app_rec.attribute7                := null;
        lr_cm_app_rec.attribute8                := null;
        lr_cm_app_rec.attribute9                := null;
        lr_cm_app_rec.attribute10               := null;
        lr_cm_app_rec.attribute11               := null;
        lr_cm_app_rec.attribute12               := null;
        lr_cm_app_rec.attribute13               := null;
        lr_cm_app_rec.attribute14               := null;
        lr_cm_app_rec.attribute15               := null;
        lr_cm_app_rec.global_attribute_category := null;
        lr_cm_app_rec.global_attribute1         := null;
        lr_cm_app_rec.global_attribute2         := null;
        lr_cm_app_rec.global_attribute3         := null;
        lr_cm_app_rec.global_attribute4         := null;
        lr_cm_app_rec.global_attribute5         := null;
        lr_cm_app_rec.global_attribute6         := null;
        lr_cm_app_rec.global_attribute7         := null;
        lr_cm_app_rec.global_attribute8         := null;
        lr_cm_app_rec.global_attribute9         := null;
        lr_cm_app_rec.global_attribute10        := null;
        lr_cm_app_rec.global_attribute11        := null;
        lr_cm_app_rec.global_attribute12        := null;
        lr_cm_app_rec.global_attribute12        := null;
        lr_cm_app_rec.global_attribute14        := null;
        lr_cm_app_rec.global_attribute15        := null;
        lr_cm_app_rec.global_attribute16        := null;
        lr_cm_app_rec.global_attribute17        := null;
        lr_cm_app_rec.global_attribute18        := null;
        lr_cm_app_rec.global_attribute19        := null;
        lr_cm_app_rec.global_attribute20        := null;
        lr_cm_app_rec.comments                  := lc_comments;
        lr_cm_app_rec.called_from               := null;

        ln_msg_count := 0;
        DEBUG_MESSAGE(p_debug_flag,'ln_msg_count has been reset. The value is '||ln_msg_count);

--/*
             AR_CM_API_PUB.APPLY_ON_ACCOUNT( p_api_version               => ln_api_version
                                           , p_init_msg_list             => lc_init_msg_list
                                           , p_commit                    => lc_commit
                                           , p_cm_app_rec                => lr_cm_app_rec
                                           , x_return_status             => lc_return_status
                                           , x_msg_count                 => ln_msg_count
                                           , x_msg_data                  => lc_msg_data
                                           , x_out_rec_application_id    => ln_out_rec_application_id
                                           , x_acctd_amount_applied_from => ln_acctd_amount_applied_from
                                           , x_acctd_amount_applied_to   => ln_acctd_amount_applied_to
                                           );
--*/

        x_msg_count   := ln_msg_count;
        p_return_status := lc_return_status;
        DEBUG_MESSAGE(p_debug_flag,'Message Count     : '||x_msg_count);
        DEBUG_MESSAGE(p_debug_flag,'Return Status is ' ||lc_return_status);
        lc_debug_msg := 'Standard API Process Completed';
        DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);


   IF ln_msg_count = 1
   THEN
        x_msg_data  := 'Error while Applying Invoice ' || p_inv_trx_number || ' to CM  '||p_cm_trx_number ||' ' || lc_msg_data;
        FND_FILE.PUT_LINE(FND_FILE.LOG,(x_msg_data));
        FND_FILE.PUT_LINE(FND_FILE.LOG,('Return Status is ' ||lc_return_status));

   ELSIF ln_msg_count > 1
   THEN
        lc_error_msg :='Error occured while Applying Invoice  ' || p_inv_trx_number || ' to CM  '||p_cm_trx_number;
        FND_FILE.PUT_LINE(FND_FILE.LOG,('Return Status is ' ||lc_return_status));
     FOR I IN 1..ln_msg_count
     LOOP
        lc_error_msg:= lc_error_msg || (I||'. '||SUBSTR(FND_MSG_PUB.GET(p_encoded => FND_API.G_FALSE ), 1,255));

     END LOOP;
        x_msg_data:=lc_error_msg;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Message from Standard API  ' || lc_error_msg);
   END IF;
        ln_msg_count := 0;
        DEBUG_MESSAGE(p_debug_flag,'Successfully submitted Standard API');

EXCEPTION
WHEN OTHERS THEN
FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while submitting Standard API'  || SQLERRM);

END APPLY_CM_INV_PROCESS;

-- +=====================================================================+
-- | Name :  EXACT_AMOUNT_MATCH_PROCESS                                  |
-- | RICE ID : E2057                                                     |
-- | Description : The procedure is used to do matching of cm to inv     |
-- |               using Exact amount matching process                   |
-- | Parameters :  p_batch_id,p_debug_flag,p_cycle_date                  |
-- +=====================================================================+

PROCEDURE EXACT_AMOUNT_MATCH_PROCESS(p_batch_id        IN NUMBER
                                    ,p_debug_flag      IN VARCHAR2
                                    ,p_cycle_date      IN VARCHAR2
                                    )
IS

-- Local variable Declarations

        ln_count                NUMBER := 0;
        ln_amount_applied       NUMBER;
        ln_error_count          NUMBER := 0;
        ln_balance_amount       NUMBER;
        ln_inv_amt_after        NUMBER;
        ln_user_id              NUMBER := FND_PROFILE.VALUE('USER_ID');
        ln_resp_id              NUMBER := FND_PROFILE.VALUE('RESP_ID') ;
        ln_resp_appl_id         NUMBER := FND_PROFILE.VALUE('RESP_APPL_ID');
        ln_profile_value        NUMBER := FND_PROFILE.VALUE('XX_AR_AGE_BEYOND_DUE_DATE_FOR_CM_AUTO_APPLICATION');
        ln_org_id               NUMBER := FND_PROFILE.VALUE ('ORG_ID');
        lc_debug_msg            VARCHAR2(4000);
        lc_exact_comments       VARCHAR2(1000);
        lc_msg_data             VARCHAR2(1000);
        lc_return_status        VARCHAR2(25);
        lc_match_type           VARCHAR2(2) := 'E';
        lc_debug_flag           VARCHAR2(2) := p_debug_flag;
        ld_cycle_date           DATE;

--------------------------------------------------------
-- Cursor query to get cm details from header table-----
--------------------------------------------------------

   CURSOR lcu_eligible_cm_header_exact
   IS
   SELECT   cm_customer_trx_id
           ,cm_trx_number
           ,cm_po_number
           ,cm_amount
           ,cm_trx_date
           ,cust_site_id
           ,balance_amount
   FROM    xx_ar_auto_app_cminv_hdr
   WHERE   batch_id=p_batch_id
   AND     org_id= ln_org_id
   AND     balance_amount<>0;

-------------------------------------------------------------------------------------------
-- Parameterized Cursor to get open invoices to match with eligible open credit memos----
-------------------------------------------------------------------------------------------

   CURSOR lcu_open_invoices_exact(p_balance  IN NUMBER,p_cust_site_id     IN NUMBER)
   IS
   SELECT INV.customer_trx_id             inv_customer_trx_id
         ,INV.trx_number                  inv_trx_number
         ,APS_INV.amount_due_remaining     inv_amount
         ,INV.purchase_order              inv_po_number
         ,APS_INV.amount_due_remaining    inv_balance_amount
         ,APS_INV.due_date                due_date
         ,APS_INV.payment_schedule_id
   FROM   ar_payment_schedules       APS_INV
        , ra_customer_trx            INV
   WHERE  APS_INV.status                   ='OP'
   AND    APS_INV.class                    ='INV'
   AND    APS_INV.customer_site_use_id     = p_cust_site_id
   AND    APS_INV.amount_due_remaining     = p_balance
   AND    APS_INV.customer_trx_id          = INV.customer_trx_id
   AND   (APS_INV.due_date + ln_profile_value) < FND_DATE.CANONICAL_TO_DATE(p_cycle_date)
   ORDER BY APS_INV.due_date;

      lr_open_invoices_exact lcu_open_invoices_exact%ROWTYPE;

BEGIN

      lc_debug_msg := '**********Exact Amount Match process Starts**********';
      DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);

   FOR lr_eligible_cm_header_exact IN lcu_eligible_cm_header_exact
   LOOP
     OPEN lcu_open_invoices_exact(lr_eligible_cm_header_exact.balance_amount,lr_eligible_cm_header_exact.cust_site_id);
     LOOP
     FETCH lcu_open_invoices_exact INTO lr_open_invoices_exact;
     IF lcu_open_invoices_exact%NOTFOUND THEN
      DEBUG_MESSAGE(p_debug_flag,'CM  '||lr_eligible_cm_header_exact.cm_trx_number ||' has no Invoice to Match in Exact Amount Match process');
      EXIT;
     END IF;
     IF GET_INV_DISPUTE_STATUS(lr_open_invoices_exact.inv_customer_trx_id)='N' THEN
       DEBUG_MESSAGE(p_debug_flag,'The Invoice '||lr_open_invoices_exact.inv_trx_number||' has a dispute. So this invoice is not eligible for Exact Amount Matching');
     ELSE
       DEBUG_MESSAGE(p_debug_flag,'Eligible CM  :'||lr_eligible_cm_header_exact.cm_trx_number);
       DEBUG_MESSAGE(p_debug_flag,'Matching Inv :'||lr_open_invoices_exact.inv_trx_number);
       lc_exact_comments := 'System match of aged CM to INV at ' || ln_profile_value || ', Exact Dollar Match only ';
--------------------------------------------------------------------
------------ Balance amount = cm amount - inv amount .. ------------
 ----------- It will be zero in exact dollar match process  --------
--------------------------------------------------------------------
      lc_debug_msg := '**Calling Apply CmInv Process Procedure from Exact Amount Process**';
      DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);

                ld_cycle_date     := FND_DATE.CANONICAL_TO_DATE(p_cycle_date); -- To convert cycle date into oracle standard form
                DEBUG_MESSAGE(p_debug_flag,'The Cycle Date '||ld_cycle_date);


      apply_cm_inv_process(lr_eligible_cm_header_exact.cm_customer_trx_id
                         ,lr_eligible_cm_header_exact.cm_trx_number
                         ,lr_open_invoices_exact.inv_customer_trx_id
                         ,lr_open_invoices_exact.inv_trx_number
                         ,lr_open_invoices_exact.payment_schedule_id
                         ,lr_open_invoices_exact.inv_balance_amount
                         ,lc_exact_comments
                         ,ln_user_id
                         ,ln_resp_id
                         ,ln_resp_appl_id
                         ,lc_debug_flag
                         ,ld_cycle_date
                         ,ln_error_count
                         ,lc_msg_data
                         ,lc_return_status
                          );


       lc_debug_msg := 'Apply CMInv process Procedure completed after Exact Amount Matching';
       DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);

        IF (ln_error_count =0)
        THEN

        ln_balance_amount := lr_eligible_cm_header_exact.balance_amount-lr_open_invoices_exact.inv_balance_amount;
  -----------------------------------------------------------------------------
  ------------ Inv amount after  = Total inv amount - inv amount applied ..----
  ------------ It will be zero in exact dollar match process  -----------------
  -----------------------------------------------------------------------------
         ln_inv_amt_after  := lr_open_invoices_exact.inv_amount-lr_open_invoices_exact.inv_balance_amount;


         FND_FILE.PUT_LINE(FND_FILE.LOG,' Balance Invoice amount   on Invoice  :'||lr_open_invoices_exact.inv_trx_number||' is '|| ln_inv_amt_after || '         Amount applied  to CM '||lr_eligible_cm_header_exact.cm_trx_number||'  :' || lr_open_invoices_exact.inv_balance_amount);

         DEBUG_MESSAGE(p_debug_flag,'Balance Amounts Got Successfully after Exact Dollar Match Process ');
  --------------------------------------------------------------------
  -- All applied invoices details get Inserted into child table-------
  --------------------------------------------------------------------
          INSERT INTO xx_ar_auto_app_cminv_dtl (cm_customer_trx_id
                                                     ,org_id
                                                     ,cm_amount_before
                                                     ,cm_amount_after
                                                     ,inv_amount_after
                                                     ,inv_customer_trx_id
                                                     ,inv_trx_number
                                                     ,inv_po_number
                                                     ,inv_amount
                                                     ,inv_amount_applied
                                                     ,due_date
                                                     ,match_type
                                                       )
           VALUES                                    ( lr_eligible_cm_header_exact.cm_customer_trx_id
                                                      ,ln_org_id
                                                      ,lr_open_invoices_exact.inv_balance_amount*-1
                                                      ,ln_balance_amount
                                                      ,ln_inv_amt_after
                                                      ,lr_open_invoices_exact.inv_customer_trx_id
                                                      ,lr_open_invoices_exact.inv_trx_number
                                                      ,lr_open_invoices_exact.inv_po_number
                                                      ,lr_open_invoices_exact.inv_balance_amount
                                                      ,lr_open_invoices_exact.inv_balance_amount
                                                      ,lr_open_invoices_exact.due_date
                                                      ,lc_match_type
                                                     );
         DEBUG_MESSAGE(p_debug_flag,'Record inserted  for CM  '||lr_eligible_cm_header_exact.cm_trx_number ||' for the Invoice '||lr_open_invoices_exact.inv_trx_number);
  ------------------------------------------------------------------
  -- All applied cm details amount get updated into header table----
  ------------------------------------------------------------------

          UPDATE xx_ar_auto_app_cminv_hdr
          SET balance_amount=ln_balance_amount,
                             error_msg=null, error_flg='N'
          WHERE cm_customer_trx_id=lr_eligible_cm_header_exact.cm_customer_trx_id;

       ELSE
  ------------------------------------------------------------------------------------------
  -- If error mesg count is not zero then update the header table with the error mesg-------
  ------------------------------------------------------------------------------------------
         DEBUG_MESSAGE(p_debug_flag,'Exact Amount Matching failed when CM '||lr_eligible_cm_header_exact.cm_trx_number ||' was applied to Invoice '||lr_open_invoices_exact.inv_trx_number);
          UPDATE xx_ar_auto_app_cminv_hdr
          SET error_msg = lc_msg_data
             ,error_flg = 'Y'
          WHERE cm_customer_trx_id=lr_eligible_cm_header_exact.cm_customer_trx_id;

       END IF;
-----------------------------------------------------------------------------------------------------------
--- If more than one invoice matching for the same CM amount-----------------------------------------------
----oldest invoice will get match first with cm and if any other matching records found it should get exit.
----without processing.So, put exit condition as below-----------------------------------------------------
-----------------------------------------------------------------------------------------------------------
      COMMIT;
      EXIT;
     END IF; --Dispute Check.

     END LOOP; -- Invoice cursor
     CLOSE lcu_open_invoices_exact; -- Invoice cursor
   END LOOP;-- CM cursor
   COMMIT;
   FND_FILE.PUT_LINE(FND_FILE.LOG,' Both Header and Detail table Inserted/Updated Successfully after Exact Amount Match process  ');

EXCEPTION
   WHEN OTHERS THEN
   FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception raised in exact amount matching process'|| SQLERRM);

END EXACT_AMOUNT_MATCH_PROCESS;

-- +=====================================================================+
-- | Name :  REFERENCE_MATCH_PROCESS                                     |
-- | RICE ID : E2057                                                     |
-- | Description : The procedure is used to do matching of CM to Inv     |
-- |               using Reference number                                |
-- | Parameters :  p_batch_id ,p_debug_flag,p_cycle_date                 |
-- +=====================================================================+

PROCEDURE REFERENCE_MATCH_PROCESS(p_batch_id        IN NUMBER
                                 ,p_debug_flag      IN VARCHAR2
                                 ,p_cycle_date      IN VARCHAR2
                                 )
IS
-- Local variable Declarations
        ln_count                        NUMBER :=0;
        ln_amount                       NUMBER :=0;
        ln_balance_amount               NUMBER :=0;
        ln_inv_amt_after                NUMBER;
        ln_user_id                      NUMBER := FND_PROFILE.VALUE('USER_ID');
        ln_resp_id                      NUMBER := FND_PROFILE.VALUE('RESP_ID') ;
        ln_resp_appl_id                 NUMBER := FND_PROFILE.VALUE('RESP_APPL_ID');
        ln_profile_value                NUMBER := FND_PROFILE.VALUE('XX_AR_AGE_BEYOND_DUE_DATE_FOR_CM_AUTO_APPLICATION');
        ln_org_id                       NUMBER := FND_PROFILE.VALUE ('ORG_ID');
        ld_cycle_date                   DATE;
        lc_error_flag_ref               VARCHAR2(10);
        lc_ref_comments                 VARCHAR2(1000);
        lc_msg_data                     VARCHAR2(1000);
        lc_return_status                VARCHAR2(25);
        lc_debug_msg                    VARCHAR2(4000);
        lc_debug_flag                   VARCHAR2(2) := p_debug_flag;
        lc_match_type                   VARCHAR2(2) := 'R';
        lc_error                        VARCHAR2(1000);

-------------------------------------------------------------------------------------------
-- Cursor query to get eligible cm details from header temp table for the batch id passed--
-------------------------------------------------------------------------------------------

   CURSOR lcu_eligible_cm_header_ref
   IS
   SELECT   cm_customer_trx_id
           ,cm_trx_number
           ,cm_po_number
           ,cm_amount
           ,cm_trx_date
           ,cust_site_id
           ,balance_amount
   FROM    xx_ar_auto_app_cminv_hdr
   WHERE   batch_id = p_batch_id
   AND     org_id   = ln_org_id;

-------------------------------------------------------------------------------------------
-- Parameterized Cursor to get open invoices to match with eligible open credit memos----
-------------------------------------------------------------------------------------------

   CURSOR lcu_open_invoices_ref(p_customer_trx_id  IN NUMBER
                               ,p_cust_site_id     IN NUMBER)
   IS
   SELECT
   DISTINCT INV.customer_trx_id             inv_customer_trx_id
           ,INV.trx_number                  inv_trx_number
           ,APS.amount_due_remaining        inv_amount
           ,INV.purchase_order              inv_po_number
           ,APS.due_date                    due_date
           ,APS.payment_schedule_id
   FROM     ra_customer_trx            CM
           ,oe_order_headers           OHA
           ,oe_order_lines             OLA
           ,xx_om_line_attributes_all  XOLA
           ,ra_customer_trx            INV
           ,ar_payment_schedules       APS
   WHERE   CM.customer_trx_id       = p_customer_trx_id
   AND     TO_NUMBER(CM.attribute14)= OHA.header_id
   AND     OHA.header_id            = OLA.header_id
   AND     OLA.line_id              = XOLA.line_id
   AND     XOLA.ret_orig_order_num  = INV.trx_number
   AND     INV.bill_to_site_use_id  = p_cust_site_id
   AND     INV.customer_trx_id      = APS.customer_trx_id
   AND     APS.status               ='OP'
   AND     APS.class                ='INV'
   AND     APS.amount_due_remaining > 0
   AND    (APS.DUE_DATE + ln_profile_value) < FND_DATE.CANONICAL_TO_DATE(p_cycle_date)
   AND    GET_INV_DISPUTE_STATUS(INV.customer_trx_id)='Y';

        lr_open_invoices_ref  lcu_open_invoices_ref%ROWTYPE;

BEGIN
        lc_debug_msg := '**********Reference Match Process Starts**********';
        DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);

   FOR lr_eligible_cm_header_ref IN lcu_eligible_cm_header_ref
   LOOP

       lc_error_flag_ref := 'N'; -- Assigning error flag for reference match as No. If error is Yes it should not process matching logic
       DEBUG_MESSAGE(p_debug_flag,'Checking if any Invoice Reference exists for CM  :  '||lr_eligible_cm_header_ref.cm_trx_number);

    OPEN lcu_open_invoices_ref(lr_eligible_cm_header_ref.cm_customer_trx_id,lr_eligible_cm_header_ref.cust_site_id);
    LOOP
       lc_debug_msg := 'Cursor Opened to get the Referenced Invoice from OM';
       DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);
    FETCH lcu_open_invoices_ref INTO lr_open_invoices_ref;

       IF lcu_open_invoices_ref%NOTFOUND THEN
         DEBUG_MESSAGE(p_debug_flag,'No Referenced Matching Invoice found, Coming out of the Reference Invoice Cursor');
         EXIT;
       END IF;
 ---------------------------------------------------------------------------------------------
 ------------------- For the passed customer trx id and cust site id the matched  ------------
 --------------------invoice should be one by matching with reference number.-- --------------
 ------------------ IF it is more than one don't perform reference matching logic------------
 --------------------------------------------------------------------------------------------
         DEBUG_MESSAGE(p_debug_flag,'Number of Records fetched  :  '||lcu_open_invoices_ref%ROWCOUNT);

       IF (lcu_open_invoices_ref%ROWCOUNT > 1)
       THEN
         lc_error_flag_ref :='Y';
         DEBUG_MESSAGE(FND_FILE.LOG,'The CM Trx # '||lr_eligible_cm_header_ref.cm_trx_number ||' had more than one References. So Reference Match cannot be performed.');
         EXIT;
       END IF;

     IF(lc_error_flag_ref='N')
     THEN
         lc_debug_msg := 'The CM Trx Number '||lr_eligible_cm_header_ref.cm_trx_number||' can be applied to Invoice Number '||lr_open_invoices_ref.inv_trx_number;
         DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);
  -----------------------------------------------------------------
  --- If cm amount is high than matching invoice -----------------
  --- then apply cm amount which is equal to invoice amount,------
  --- cm will have open balance ----------------------------------
  -----------------------------------------------------------------
        IF(ABS(lr_eligible_cm_header_ref.cm_amount) > lr_open_invoices_ref.inv_amount)
        THEN
         ln_amount := lr_open_invoices_ref.inv_amount;
------------------------------------------------------------------------
--------- If the matched invoice amount is high than cm ----------------
--------- then apply full cm amount, invoice will have open balance-----
------------------------------------------------------------------------
        ELSIF (ABS(lr_eligible_cm_header_ref.cm_amount) <= lr_open_invoices_ref.inv_amount)
        THEN
         ln_amount := ABS(lr_eligible_cm_header_ref.cm_amount); --- Should Pass only positive amount value to standard API.
                                                                --- So for CM give Absoleute to make positive
        END IF;
 -----------------------------------------------------------------------------------------------------
 ----- Balance cm amount = Applied cm amount =>Balance amount - amount passed to standard api--------
 -----------------------------------------------------------------------------------------------------
         ln_balance_amount := lr_eligible_cm_header_ref.balance_amount-ln_amount;
         ld_cycle_date     := FND_DATE.CANONICAL_TO_DATE(p_cycle_date); -- To convert cycle date into oracle standard form

 ------------------------------------------------------------------------------------------------------------------------
 ------------ Inv amount after  = Subtract Total inv amount with inv amount applied -------------------------------------
 ------------------------------------------------------------------------------------------------------------------------
         ln_inv_amt_after  := lr_open_invoices_ref.inv_amount-ln_amount;

         lc_debug_msg := '**Calling Apply CMInv Process from Reference Match Process**';
         DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);

         lc_ref_comments := 'System match of aged CM to INV at ' || ln_profile_value || ', Reference Match';

         lc_debug_msg:='Comments passed to apply CM Inv procedure from Reference Match is  ' || lc_ref_comments;
         DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);

         apply_cm_inv_process(lr_eligible_cm_header_ref.cm_customer_trx_id
                             ,lr_eligible_cm_header_ref.cm_trx_number
                             ,lr_open_invoices_ref.inv_customer_trx_id
                             ,lr_open_invoices_ref.inv_trx_number
                             ,lr_open_invoices_ref.payment_schedule_id
                             ,ln_amount
                             ,lc_ref_comments
                             ,ln_user_id
                             ,ln_resp_id
                             ,ln_resp_appl_id
                             ,lc_debug_flag
                             ,ld_cycle_date
                             ,ln_count
                             ,lc_msg_data
                             ,lc_return_status
                             );

 ----------------------------------------------------------
 -- All applied invoices gets Inserted into child table----
 ----------------------------------------------------------
        IF (ln_count =0 or lc_return_status <> 'E')
        THEN
           DEBUG_MESSAGE(P_DEBUG_FLAG,'Invoice Applied to CM, Inserting the data to the Detail Table');
           FND_FILE.PUT_LINE(FND_FILE.LOG,' Balance CM amount  for CM ' ||lr_eligible_cm_header_ref.cm_trx_number ||' :  ' || ln_balance_amount || '         Amount applied  to Invoice '||lr_open_invoices_ref.inv_trx_number||'  :  ' || ln_amount);

           INSERT INTO xx_ar_auto_app_cminv_dtl (cm_customer_trx_id
                                                      ,org_id
                                                      ,cm_amount_before
                                                      ,cm_amount_after
                                                      ,inv_amount_after
                                                      ,inv_customer_trx_id
                                                      ,inv_trx_number
                                                      ,inv_po_number
                                                      ,inv_amount
                                                      ,inv_amount_applied
                                                      ,due_date
                                                      ,match_type
                                                      )
           VALUES                                    (lr_eligible_cm_header_ref.cm_customer_trx_id
                                                     ,ln_org_id
                                                     ,lr_eligible_cm_header_ref.cm_amount
                                                     ,ln_balance_amount
                                                     ,ln_inv_amt_after
                                                     ,lr_open_invoices_ref.inv_customer_trx_id
                                                     ,lr_open_invoices_ref.inv_trx_number
                                                     ,lr_open_invoices_ref.inv_po_number
                                                     ,lr_open_invoices_ref.inv_amount
                                                     ,ln_amount
                                                     ,lr_open_invoices_ref.due_date
                                                     ,lc_match_type
                                                     );
 ---------------------------------------------------------------------
 --- All applied cm balance amount gets updated into header table-----
 ---------------------------------------------------------------------
           UPDATE xx_ar_auto_app_cminv_hdr
           SET balance_amount=ln_balance_amount,
                          error_msg=null, error_flg='N'
           WHERE cm_customer_trx_id=lr_eligible_cm_header_ref.cm_customer_trx_id;
             DEBUG_MESSAGE(p_debug_flag,'Invoice Applied to CM, Updated the balance CM amount to the Header Table');
        ELSE
 ----------------------------------------------------------------------------------------
 -- If error mesg count is not zero then update the header table with the error mesg-----
 ----------------------------------------------------------------------------------------
             DEBUG_MESSAGE(p_debug_flag,'Error While Applying the CM. Updating the error message to the Header table');
           UPDATE xx_ar_auto_app_cminv_hdr
           SET error_msg = lc_msg_data
              ,error_flg = 'Y'
           WHERE cm_customer_trx_id=lr_eligible_cm_header_ref.cm_customer_trx_id;

        END IF;

     ELSIF (lc_error_flag_ref='Y')
     THEN
         lc_error := 'More than one matched invoice found for Unapply CM and Autoapplication cannot be done in Reference Match process';
         DEBUG_MESSAGE(p_debug_flag,lc_error);
       UPDATE xx_ar_auto_app_cminv_hdr
       SET error_msg = lc_error
          ,error_flg = 'Y'
       WHERE cm_customer_trx_id=lr_eligible_cm_header_ref.cm_customer_trx_id;

     END IF;
     commit;
    END LOOP;
      lc_debug_msg := 'Apply CmInv Process Procedure completed after Reference Match of CM to Inv';
      DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);
    CLOSE lcu_open_invoices_ref; -- Invoice cursor
   END LOOP;-- CM cursor

   COMMIT;
   FND_FILE.PUT_LINE(FND_FILE.LOG,' Both Header and Detail table Inserted/Updated Successfully after Reference Match process  ');
   FND_FILE.PUT_LINE(FND_FILE.LOG, '');

-- Added on 26-APR-2010 **End**

 EXCEPTION
   WHEN OTHERS THEN
   FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception raised in Reference Matching process'|| SQLERRM);

END REFERENCE_MATCH_PROCESS;


-- +=====================================================================+
-- | Name :  CM_MATCH_PROCESS                                            |
-- | RICE ID : E2057                                                     |
-- | Description : The procedure is used to submit the matching process  |
-- |               procedures. Autoapply of CM to invoice can be done    |
-- |               by two matching process. Reference match and exact    |
-- |               amount match. The cm match process procedure helps to |
-- |               call the reference match procedure and exact amount   |
-- |               procedure to find possible invoices to apply cm       |
-- |                                                                     |
-- | Parameters :  p_match_type,p_batch_id,p_debug_flag,p_cycle_date     |
-- | Returns    :  x_err_buff,x_ret_code                                 |
-- +=====================================================================+

PROCEDURE CM_MATCH_PROCESS  (x_err_buff        OUT NOCOPY VARCHAR2
                            ,x_ret_code        OUT NOCOPY NUMBER
--                          ,p_match_type      IN VARCHAR2  ----- Commented on 26/04/2010
                            ,p_batch_id        IN NUMBER
                            ,p_debug_flag      IN VARCHAR2
                            ,p_cycle_date      IN VARCHAR2
                            )
IS
-- Local Variables Declaration

      lc_debug_msg                  VARCHAR2(4000);

BEGIN
      lc_debug_msg := 'Calling Matching process from CM Match process';
      DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);

                                        -------------------------------------------------
                                        -- Calling Reference Match Process ---
                                        ------------------------------------------------
--    IF (p_match_type = 'R')  --  ----- Commented on 26/04/2010
--    THEN                     --  ----- Commented on 26/04/2010
      DEBUG_MESSAGE('Y','--------------------------------');
      DEBUG_MESSAGE('Y','STEP 1 : Reference Match Process');
                DEBUG_MESSAGE('Y','--------------------------------');
      REFERENCE_MATCH_PROCESS(P_BATCH_ID,P_DEBUG_FLAG,P_CYCLE_DATE);

       -- Added on 26-APR-2010 **Start**
                                        ------------------------------------------------------------------
                                        -------------- Calling Exact Amount match process ----
                                        ------------------------------------------------------------------

                DEBUG_MESSAGE('Y','-----------------------------------');
      DEBUG_MESSAGE('Y','STEP 2 : Exact Amount Match Process');
                DEBUG_MESSAGE('Y','-----------------------------------');
                EXACT_AMOUNT_MATCH_PROCESS(P_BATCH_ID,P_DEBUG_FLAG,P_CYCLE_DATE);

 ----- Commented on 26/04/2010 ** START**
/*-----------------------------------------
-- Calling Exact Amount Match Process ---
-----------------------------------------
    ELSIF (p_match_type = 'E')
    THEN
      exact_amount_match_process(p_batch_id,p_debug_flag,p_cycle_date);

    END IF;*/
 ----- Commented on 26/04/2010** END**

      lc_debug_msg := 'Matching of CM to Inv completed after CM Match Process';
      DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);

EXCEPTION
   WHEN OTHERS THEN
   FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception raised while calling matching programs '|| SQLERRM);

END CM_MATCH_PROCESS;


-- +=====================================================================+
-- | Name :  GENERATE_REPORT                                             |
-- | RICE ID : E2057                                                     |
-- | Description : The procedure is used to print the output in a report |
-- |               The report fields have been updated in the header and |
-- |               detail table. This procedure will fetch those records |
-- |               and give as report output in concurrent program       |
-- |                                                                     |
-- | Parameters :   p_debug_flag,p_gather_stats                          |
-- +=====================================================================+

PROCEDURE GENERATE_REPORT(p_debug_flag    IN VARCHAR2
                         ,p_gather_stats  IN VARCHAR2  -- Added for Defect # 6098
                         )
IS
        lc_debug_msg                  VARCHAR2(4000);
--      lc_match_type                 VARCHAR2(2):= 'R'; ----- Commented on 26/04/2010
        ln_error_count                NUMBER:=0;

-------------------------------------------------------------------------
-- Cursor to get applied cm and invoice details from header/detail table--
-------------------------------------------------------------------------

   CURSOR lcu_cminv_details
   IS
   SELECT   XXAC.cm_customer_trx_id
           ,XXAC.cm_trx_number
           ,HZC.account_name          customer_name
           ,HZC.account_number        customer_account_number
           ,XXAC.cm_po_number
           ,XXAD.cm_amount_before
           ,XXAC.cm_trx_date
           ,XXAC.cust_site_id
           ,XXAC.balance_amount
           ,XXAC.bill_to_customer_id
           ,XXAD.inv_customer_trx_id
           ,XXAD.inv_trx_number
           ,XXAD.inv_po_number
           ,XXAD.inv_amount
           ,XXAD.inv_amount_applied
           ,XXAD.cm_amount_after *-1 cm_amount_after
           ,XXAD.inv_amount_after
           ,XXAD.due_date
           ,XXAD.match_type
           ,XXAC.error_msg
           ,TRIM(HZS.location) bill_to_location
   FROM     xx_ar_auto_app_cminv_hdr         XXAC
           ,hz_cust_accounts                  HZC
           ,xx_ar_auto_app_cminv_dtl         XXAD
           ,hz_cust_site_uses                 HZS
           ,hz_cust_acct_sites                HCS
   WHERE    XXAC.cm_customer_trx_id = XXAD.cm_customer_trx_id
   AND      HZC.cust_account_id     = XXAC.bill_to_customer_id
   AND      HZC.cust_account_id     = HCS.cust_account_id
   AND      HCS.cust_acct_site_id   = HZS.cust_acct_site_id
   AND      HZS.site_use_id         = XXAC.cust_site_id
   AND      XXAC.org_id             = gn_org_id
   AND      XXAC.error_flg          ='N'
   ORDER BY XXAD.match_type DESC, XXAC.cm_trx_number;

-------------------------------------------------------------------------
-- Cursor to get error message for the non matching processes -----------
-------------------------------------------------------------------------

   CURSOR lcu_error_msg
   IS
   SELECT XXAC.cm_trx_number
         ,HZC.account_name          customer_name
         ,HZC.account_number        customer_account_number
         ,XXAC.cm_amount
         ,XXAC.error_msg
   FROM   xx_ar_auto_app_cminv_hdr        XXAC
         ,hz_cust_accounts                 HZC
   WHERE  HZC.cust_account_id     = XXAC.bill_to_customer_id
   AND    XXAC.error_msg IS NOT NULL
   AND    XXAC.error_flg = 'Y'
   AND    XXAC.org_id    = gn_org_id;

BEGIN
      -- Added for Defect #5183  - Addition of Gather stats on Detail table  ** Start**

    IF (p_gather_stats = 'Y')
    THEN
        lc_debug_msg := 'Generation of Report Starts..';
        debug_message(p_debug_flag,lc_debug_msg);
                  debug_message('Y','--------------------------------------------------');
        debug_message('Y','Gather Stats for Detail Table Start - '||to_char(sysdate,'DD-MON-YYYY HH24:MI:SS'));
     -- fnd_stats.gather_table_stats('XXFIN','XX_AR_AUTO_APP_CMINV_DTL');   -- Commented for Defect # 6098

        fnd_stats.gather_table_stats('XXFIN','XX_AR_AUTO_APP_CMINV_DTL',NULL,NULL,'XX_AR_AUTO_APP_CMINV_DTL_'||gn_org_id);  -- Added for Defect# 6098
        debug_message('Y','Gather Stats for Detail Table End - '||to_char(sysdate,'DD-MON-YYYY HH24:MI:SS'));
                  debug_message('Y','--------------------------------------------------');
    END IF;
 -- Added for Defect #5183  - Addition of Gather stats on Detail table  ** End**

-------------------------------------------------------------------------
------Writing labels in program output for reference match --------------
-------------------------------------------------------------------------
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Match Type'
                                        || '|' ||'Account Number '
                                        || '|' || 'Bill-to-Location'
                                        || '|' || 'Customer Name'
                                        || '|' || 'CM #'
                                        || '|' || 'CM PO #'
                                        || '|' || 'CM Open Amount Before'
                                        || '|' || 'CM Open Amount After'
                                        || '|' || 'Invoice #'
                                        || '|' || 'Invoice PO #'
                                        || '|' || 'Invoice Amount Before'
                                        || '|' || 'Invoice Amount After'
                                        || '|' || 'Dollar Amount Applied to Invoice');
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '');

-------------------------------------------------------------------------
------Writing values in program output for match in looping----
-------------------------------------------------------------------------

  FOR lr_cminv_details IN lcu_cminv_details
  LOOP

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_cminv_details.match_type
                                        || '|' || lr_cminv_details.customer_account_number
                                        || '|' || lr_cminv_details.bill_to_location
                                        || '|' || lr_cminv_details.customer_name
                                        || '|' || lr_cminv_details.cm_trx_number
                                        || '|' || lr_cminv_details.cm_po_number
                                        || '|' || lr_cminv_details.cm_amount_before
                                        || '|' || lr_cminv_details.cm_amount_after
                                        || '|' || lr_cminv_details.inv_trx_number
                                        || '|' || lr_cminv_details.inv_po_number
                                        || '|' || lr_cminv_details.inv_amount
                                        || '|' || lr_cminv_details.inv_amount_after
                                        || '|' || lr_cminv_details.inv_amount_applied);
  END LOOP;


-------------------------------------------------------------------------
------Writing error messeges in program output --------------------------
-------------------------------------------------------------------------

   SELECT COUNT(*)
   INTO ln_error_count
   FROM xx_ar_auto_app_cminv_hdr
   WHERE error_msg IS NOT NULL
   AND error_flg='Y'            -- If error count is greater than one then it prints the headings once in the log
   AND org_id   =gn_org_id;

   IF(ln_error_count>0)
   THEN
     FND_FILE.PUT_LINE(FND_FILE.LOG,'--------------------------------------------------------------------------------------------------------------------------------------------------------------------');
     FND_FILE.PUT_LINE(FND_FILE.LOG, '***************************** Error Report*****************************');
     FND_FILE.PUT_LINE(FND_FILE.LOG, '');
     FND_FILE.PUT_LINE(FND_FILE.LOG, LPAD('Customer Account Number',30,' ')
                                  || LPAD('Customer Name',30,' ')
                                  || LPAD('Credit Memo Amount',30,' ')
                                  || LPAD('CM Number ',40,' ')
                                  || LPAD('Error Message ', 30,' '));
     FND_FILE.PUT_LINE(FND_FILE.LOG,'--------------------------------------------------------------------------------------------------------------------------------------------------------------------');

     -----------------------------------------------------------------------------------
--- IF error mesg in the header table is not null => that records ended with error . ---
--- So print the message in log---------------------------------------------------------
----------------------------------------------------------------------------------------

    FOR lr_error_msg IN lcu_error_msg
    LOOP
     FND_FILE.PUT_LINE(FND_FILE.LOG,LPAD(lr_error_msg.customer_account_number,30,' ')
                                 || LPAD(lr_error_msg.customer_name,30,' ')
                                 || LPAD(lr_error_msg.cm_amount,30,' ')
                                 || LPAD(LR_ERROR_MSG.CM_TRX_NUMBER,40,' ')
                                 || ' '||LPAD(lr_error_msg.error_msg,100,' '));
    END LOOP;

   END IF;

         lc_debug_msg := '**Report Output Got Generated Successfully**';
         DEBUG_MESSAGE(p_debug_flag,lc_debug_msg);

EXCEPTION
WHEN OTHERS THEN
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised while Writing in Report Output' || SQLERRM);


END GENERATE_REPORT;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  DEBUG_MESSAGE                                 |
-- | RICE ID : E2057                                                   |
-- | Description      : This Procedure is used to print the debug      |
-- |                    messages wherever required                     |
-- | Parameters :       p_debug_flag,p_debug_msg                       |
-- +===================================================================+

PROCEDURE DEBUG_MESSAGE(p_debug_flag       IN       VARCHAR2
                       ,p_debug_msg        IN       VARCHAR2
                       )
AS
BEGIN

   IF (NVL(p_debug_flag,'N') = 'Y') THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,' '||p_debug_msg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'');
   END IF;

END DEBUG_MESSAGE;

 -- +====================================================================+
-- | Name : GET_INV_DISPUTE_STATUS                                      |
---| Rice Id : E2057                                                    |
-- | Description : It accepts the inv trx id and it will check          |
-- |               whether the passed invoice is in complete or approved|
-- |               status and it implies the invoice is ready for       |
-- |               auto application process                             |
-- | Parameters :  p_set_of_books_id, p_currency_code, p_period_name    |
-- +====================================================================+
FUNCTION GET_INV_DISPUTE_STATUS(p_inv_trx_id    IN NUMBER)

RETURN VARCHAR2
IS
    ln_inv_disp_status       VARCHAR2(2);
BEGIN
  -- Modified on 12-DEC-2011 for new DFF filed configuration for Webcollect project
    SELECT (SELECT 'x'
    FROM ra_cm_requests_all RCM,
         fnd_lookup_values flv
    WHERE customer_trx_id=p_inv_trx_id
    AND RCM.status = flv.lookup_code
    AND flv.lookup_type='XX_OD_AR_INV_DISPUTES_STATUSES'
    UNION
    SELECT 'x'
    FROM RA_CUSTOMER_TRX_ALL
    WHERE customer_trx_id=p_inv_trx_id
    AND nvl(attribute11,'N') = 'Y')
    INTO ln_inv_disp_status
    FROM DUAL;

    IF ln_inv_disp_status is NULL
    THEN
    RETURN 'Y';
    ELSE
    RETURN 'N';
    END IF;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 'Y';
  WHEN TOO_MANY_ROWS THEN
    RETURN 'N';
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception Raised in Get invoice dispute status ' || SQLERRM);
    RETURN 'N';

END GET_INV_DISPUTE_STATUS;

END XX_AR_AUTO_CM_TO_INVOICE_PKG;
/
