create or replace 
PACKAGE BODY XX_AR_CUST_STMTXL_WRAP_PKG
AS
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                          Wipro-Office Depot                                       |
-- +===================================================================================+
-- | Name             :  XX_AR_CUST_STMTXL_WRAP  E2048(Defect 3261)                    |
-- | Description      :  This Package is used to fetch all the Customer                |
-- |                     Statements and mail the Customer statements                   |
-- |                     in  the Excel format                                          |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date         Author           Remarks                                    |
-- |=======   ==========   =============    ======================                     |
-- |DRAFT 1.0 05-NOV-2009  Vinaykumar S   Initial draft version(CR 622)                |
-- |  1.1     14-DEC-2009  Vinaykumar S   Made changes to the code as                  |
-- |                                      Per Subbu's Comments                         |
-- |                                      Defect 3261(CR 622)                          |
-- |  1.2     09-FEB-2010  Vinaykumar S   Modified the code as                         |
-- |                                      Per comments from UATGB                      |
-- |                                      Testing Team                                 |
-- |  1.3     18-FEB-2010  Vinaykumar S   Made changes to the code to                  |
-- |                                      be org Specific                              |
-- |  1.4     19-FEB-2010  Vinaykumar S   Modified for Defect # 4497                   |
-- |  1.5     31-MAR-2010  Vinaykumar S   Modified for R1.3 Defect 3261                |
-- |                                       (CR 622)                                    |
-- |  1.6     07-JUN-2010  Bhuvaneswary S Modified for R1.4 Defect 5117                |
-- |  1.7     22-JUL-2010  Saravanan PL   R1.4 - Defect# 6705 - File Size Issue        |
-- |  1.8     29-NOV-2010  RamyaPriya M   Modified the receipt number derivation in    |
-- |                                       GET_UNAPP_CASH_DETAILS proc for Defect# 9179|
-- | 1.9      21-JAN-2011  Rohit Ranjan   Modified the code as per Defect# 15297       |
-- | 1.10     11-FEB-2015  John Willson   Modified the code as per the Defect #33481   |
-- | 1.11     18-MAY-2015  Manikant Kasu  Made code changes to send statements to      |
-- |                                      customers ship_to site also as per           |
-- |                                      Defect#                                      |
-- | 1.12     26-OCT-2015  Vasu Raparla   Removed schema areferences for R12.2         |
-- +===================================================================================+
        gc_html_file          VARCHAR2(200);
        gc_html_file_user_p1  VARCHAR2(200);
        gc_html_file_user_p2  VARCHAR2(200);
        gc_directory_path     VARCHAR2(200);
        gc_debug_msg          VARCHAR2(4000);
        gn_org_id             NUMBER := FND_PROFILE.VALUE('org_id');
PROCEDURE GET_CUST_DETAILS(x_errbuf            OUT  VARCHAR2
                          ,x_retcode           OUT  VARCHAR2
                          ,p_stmt_date         IN   VARCHAR2
                          ,p_stmt_cycle        IN   NUMBER
                          ,p_no_of_customers   IN   NUMBER
                          ,p_customer_id       IN   NUMBER
                          ,p_debug_flag        IN   VARCHAR2
                         )
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  GET_CUST_DETAILS                              |
-- | Description      :  This Procedure is used to Extract all the     |
-- |                   Customer Details and insert into customer master|
-- |                  and call the Batching and Submit Child Procedures|
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |DRAFT 1.0 05-NOV-2009  Vinaykumar S    Initial draft version       |
-- |  1.1     14-DEC-2009  Vinaykumar S   Made changes to the code as  |
-- |                                      Per Subbu's Comments         |
-- |                                      Defect 3261(CR 622)          |
-- |  1.2     09-FEB-2010  Vinaykumar S   Modified the code as         |
-- |                                      Per comments from UATGB      |
-- |                                      Testing Team                 |
-- |  1.3     18-FEB-2010  Vinaykumar S   Made changes to the code to  |
-- |                                      be org Specific              |
-- |  1.4     18-MAY-2015  Manikant Kasu  Made code changes to active  |
-- |                                      customer details cursor for  |
-- |                                      ship_to site also as per     |
-- |                                      Defect#                      |
-- +===================================================================+
-----------------------------------------------------------
-- The Cursor Selects the active customer details        --
-----------------------------------------------------------
   CURSOR lcu_get_cust_details
   IS
   SELECT  /*+ LEADING(ARSC,HCP)*/ 
           HCA.cust_account_id                     customer_id
          ,HCSU.site_use_id                        customer_site_id
          ,DECODE(HCP.cons_inv_flag,'Y','C','I')   customer_type
          ,1                                       batch_id
          ,HCSU.location                           location
          ,HCA.account_number                      customer_number
          ,ARSC.name                               statement_cycle
   FROM    hz_cust_site_uses       HCSU
          ,hz_cust_accounts        HCA
          ,hz_customer_profiles    HCP
          ,hz_cust_acct_sites      HCAS
          ,ar_statement_cycles     ARSC
   WHERE  HCP.send_statements = 'Y'
   AND    HCSU.status = 'A'
   AND    HCA.status  = 'A'
   AND    HCP.status  = 'A'
   AND    HCA.cust_account_id     = HCP.cust_account_id
   AND    HCAS.cust_account_id    = HCA.cust_account_id
   AND    HCP.site_use_id         = HCSU.site_use_id
   AND    HCAS.cust_acct_site_id  = HCSU.cust_acct_site_id
   AND    HCSU.site_use_code      = 'BILL_TO'
   AND    HCP.statement_cycle_id  = ARSC.statement_cycle_id
   AND    ARSC.statement_cycle_id = p_stmt_cycle
   AND    HCA.cust_account_id     = NVL(p_customer_id,HCA.cust_account_id)
   AND    EXISTS (SELECT  1
                  FROM  XX_AR_PS_TMP_STG APS
                  WHERE APS.customer_site_use_id = HCSU.site_use_id
                  AND   APS.status = 'OP'
                  AND   APS.amount_due_remaining != 0
                  )
   AND    NOT EXISTS (select 1
                   from   xx_cdh_cust_acct_ext_b  ext,
                          EGO_ATTR_GROUPS_V       grp
                   where  ext.attr_group_id=grp.attr_group_id                      
                   and    grp.application_id=222 
                   and    ext.cust_account_id = hca.cust_account_id
                   AND    ext.c_ext_attr1         = 'Y'
                   and    grp.attr_group_name = 'STATEMENTS_AT_SHIP_TO'
                   and    grp.attr_group_type='XX_CDH_CUST_ACCOUNT' )
   UNION
   SELECT  /*+ no_expand LEADING(ARSC,HCP,HCA,EXT,GRP) index(HCSU HZ_CUST_SITE_USES_N1) */
           HCA.cust_account_id                     customer_id
          ,HCSU.site_use_id                        customer_site_id
          ,DECODE(HCP.cons_inv_flag,'Y','C','I')   customer_type
          ,1                                       batch_id
          ,HCSU.location                           location
          ,HCA.account_number                      customer_number
          ,ARSC.name                               statement_cycle
   FROM    hz_cust_site_uses       HCSU
          ,hz_cust_accounts        HCA
          ,hz_customer_profiles    HCP
          ,hz_cust_acct_sites      HCAS
          ,ar_statement_cycles     ARSC
          ,xx_cdh_cust_acct_ext_b  ext
          ,ego_attr_groups_v       grp
   WHERE  1 = 1
   and    HCP.send_statements = 'Y'
   AND    HCSU.status = 'A'
   AND    HCA.status  = 'A'
   AND    HCP.status  = 'A'
   AND    HCA.cust_account_id     = HCP.cust_account_id
   AND    HCAS.cust_account_id    = HCA.cust_account_id
   AND    HCAS.cust_acct_site_id  = HCSU.cust_acct_site_id
   AND    HCSU.site_use_code      = 'SHIP_TO'
   AND    HCP.statement_cycle_id  = ARSC.statement_cycle_id
   AND    ARSC.statement_cycle_id = p_stmt_cycle
   AND    HCA.cust_account_id     = NVL(p_customer_id,HCA.cust_account_id)
   AND    ext.attr_group_id       = grp.attr_group_id                      
   AND    grp.application_id      = 222 
   AND    ext.cust_account_id     = hca.cust_account_id 
   AND    grp.attr_group_name     = 'STATEMENTS_AT_SHIP_TO'
   AND    grp.attr_group_type     = 'XX_CDH_CUST_ACCOUNT'
   AND    ext.c_ext_attr1         = 'Y'
   AND    EXISTS (SELECT  /*+ no_unnest no_push_subq */
                          1
                  FROM    XX_AR_PS_TMP_STG  APS,
                          ra_Customer_Trx       rct                          
                  WHERE   1 = 1 
                  --APS.customer_site_use_id = HCSU.site_use_id
                  AND     RCT.customer_trx_id = APS.customer_trx_id             
                  AND     RCT.bill_to_site_use_id = APS.customer_site_use_id 
                  AND     RCT.ship_to_site_use_id = HCSU.site_use_id
                  AND     RCT.bill_to_Customer_id = HCA.cust_account_id
                  AND     APS.status = 'OP'
                  AND     APS.amount_due_remaining != 0
                  )               
  ;
  
  CURSOR lcu_upd_arps_full(p_customer_id IN ar_payment_schedules_all.customer_id%TYPE ) 
  IS
  SELECT /*+ full(aps) parallel(aps,8) */
         * 
  FROM   ar_payment_schedules aps 
  WHERE  1 = 1 
  AND    APS.status = 'OP' 
  AND    APS.amount_due_remaining <> 0
  and    APS.customer_id = nvl(p_customer_id,aps.customer_id)
  ;
  
---------------------------------
--   VARIABLE DECLARATION      --
---------------------------------
   ln_bucket_cnt        NUMBER;
   EX_SETUP_EXCEPTION   EXCEPTION;
   ln_count             NUMBER;
   lc_stmt_cycle_name   ar_statement_cycles.name%TYPE;
   lc_submit_flag       VARCHAR2(2);
   lc_stmt_date         VARCHAR2(20);
   ln_bulk_coll_limit   NUMBER := 10000;
   lc_request_data      VARCHAR2(50);
   ln_request_id        NUMBER;
   ld_stmt_date         DATE;
   lc_submit_req_count  NUMBER := 0;
   ln_parent_request_id NUMBER;
   ln_cnt_err_request   NUMBER;
   ln_cnt_war_request   NUMBER;
   lc_status            NUMBER;
   
   ln_insert_cnt        NUMBER :=0;
   ln_insert_tot        NUMBER :=0;

   
   -- pl/sql table to hold customer details.
   TYPE rec_cust_details IS RECORD (
                                     customer_id        hz_cust_accounts.cust_account_id%TYPE
                                    ,customer_site_id   hz_cust_site_uses.site_use_id%TYPE
                                    ,customer_type      hz_customer_profiles.cons_inv_flag%TYPE
                                    ,batch_id           NUMBER
                                    ,location           hz_cust_site_uses.location%TYPE
                                    ,customer_number    hz_cust_accounts.account_number%TYPE
                                    ,statement_cycle    ar_statement_cycles.name%TYPE
                                   );
   lr_cust_details          rec_cust_details;
   
   --Variable declaration of Table type
   TYPE tab_cust_details IS TABLE OF lr_cust_details%TYPE
   INDEX BY BINARY_INTEGER;
   lt_cust_details           tab_cust_details;
      
   TYPE upd_arps_tbl_type IS TABLE OF AR_PAYMENT_SCHEDULES_ALL%ROWTYPE;
   lt_upd_arps               upd_arps_tbl_type;

--------------------------------------------------------------------
 --    This Procedure is used for Inserting the Customer Details  --
 --    Into Customer Master table                                 --
--------------------------------------------------------------------
PROCEDURE INSERT_CUST_DETAILS
AS
BEGIN
   ln_count := 0;
   OPEN lcu_get_cust_details;
      LOOP
         FETCH lcu_get_cust_details BULK COLLECT INTO lt_cust_details LIMIT NVL(ln_bulk_coll_limit,10000);
            IF lt_cust_details.COUNT > 0 THEN
               FORALL i IN 1..lt_cust_details.LAST
                     INSERT INTO xx_ar_cs_customer_master
                     VALUES lt_cust_details(i);
                     ln_count := ln_count + lt_cust_details.COUNT;
                   COMMIT;
            ELSE
               EXIT;
            END IF;
      END LOOP;
   CLOSE lcu_get_cust_details;
EXCEPTION
   WHEN OTHERS THEN
     FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception raised in Inserting Customer Details '|| SQLERRM);
     RAISE EX_SETUP_EXCEPTION;
END INSERT_CUST_DETAILS;
PROCEDURE GET_BATCH_SIZE--(p_no_of_customers IN NUMBER) Commented as its moved as the private procedure R1.4 changes
AS
   ln_batch_size        NUMBER;
   ln_tot_customers     NUMBER;
   ln_batch_id          NUMBER;
   ln_batch_indx        NUMBER := 1;
   ln_batch_count       NUMBER := 0;
    -- pl/sql table to hold all batch Id's created.
   TYPE batch_id_rec_type  IS RECORD
   (customer_id            NUMBER
   ,batch_id               NUMBER
   );
   lr_batch_id         batch_id_rec_type;
   TYPE batch_id_tbl_type
   IS TABLE OF lr_batch_id%TYPE
   INDEX BY BINARY_INTEGER;
   lt_batch_id         batch_id_tbl_type;
   CURSOR lcu_cust_id
   IS
   SELECT COUNT(*) cnt,customer_id
   FROM xx_ar_cs_customer_master
   GROUP BY customer_id;
BEGIN
   FOR lcu_rec_cust_id IN lcu_cust_id
      LOOP
        IF ln_batch_count = 0
        OR ln_batch_count + lcu_rec_cust_id.cnt > p_no_of_customers
        THEN
          SELECT xx_ar_cs_customer_master_s.NEXTVAL
          INTO ln_batch_id
          FROM dual;
          lt_batch_id (ln_batch_indx).customer_id := lcu_rec_cust_id.customer_id;
          lt_batch_id (ln_batch_indx).batch_id := ln_batch_id;
          ln_batch_count := lcu_rec_cust_id.cnt;
        ELSE
          ln_batch_count := ln_batch_count + lcu_rec_cust_id.cnt;
          lt_batch_id (ln_batch_indx).customer_id := lcu_rec_cust_id.customer_id;
          lt_batch_id (ln_batch_indx).batch_id := ln_batch_id;
        END IF;
               ln_batch_indx := ln_batch_indx + 1;
      END LOOP;
      IF lt_batch_id.COUNT > 0
      THEN
        FOR i IN lt_batch_id.FIRST .. lt_batch_id.LAST
           LOOP
              UPDATE xx_ar_cs_customer_master
              SET  batch_id = lt_batch_id(i).batch_id
              WHERE customer_id = lt_batch_id(i).customer_id;
           END LOOP;
              lt_batch_id.DELETE;
      END IF;
      COMMIT;
EXCEPTION
   WHEN OTHERS
   THEN
     FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception raised in Batch Size Procedure '|| SQLERRM);
END  GET_BATCH_SIZE;
--------------------------------------------------------------------
 --    This Procedure is used to print the customer details and   --
 --    its email IDs at site level and customer level             --
--------------------------------------------------------------------
PROCEDURE PRINT_CUST_DETAILS
AS
CURSOR lcu_print_cust_details
IS
SELECT customer_id
      ,customer_site_id
      ,customer_email_id
      ,customer_site_email_id
      ,customer_number
FROM  xx_ar_cs_docid_store_master
WHERE statement_cycle = lc_stmt_cycle_name
AND   statement_date  = TO_DATE(p_stmt_date,'YYYY/MM/DD HH24:MI:SS');
BEGIN
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'************************************************** ');
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Details of Customer Statements Delivered');
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'************************************************** ');
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
   FOR lcu_rec_print_details IN lcu_print_cust_details
      LOOP
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Customer Number        : '||lcu_rec_print_details.customer_number);
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Customer Email ID      : '||lcu_rec_print_details.customer_email_id);
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Customer Site Email ID : '||lcu_rec_print_details.customer_site_email_id);
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
      END LOOP;
EXCEPTION
   WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception raised in PRINT_CUST_DETAILS procedure '|| SQLERRM);
      x_retcode := 2;
END PRINT_CUST_DETAILS;
BEGIN
   ln_parent_request_id := FND_GLOBAL.conc_request_id;
   lc_request_data :=FND_CONC_GLOBAL.request_data;
   ld_stmt_date := TO_DATE(p_stmt_date,'YYYY/MM/DD HH24:MI:SS');
   IF ( lc_request_data IS NULL) THEN
      SELECT name
      INTO lc_stmt_cycle_name
      FROM ar_statement_cycles
      WHERE statement_cycle_id = p_stmt_cycle;
      SELECT COUNT(*)
      INTO ln_bucket_cnt
      FROM ar_aging_buckets AAB
          ,ar_aging_bucket_lines AABL
      WHERE AAB.aging_bucket_id = AABL.aging_bucket_id
      AND UPPER(AAB.bucket_name) = (
                                     SELECT XFTV.target_value6
                                     FROM   xx_fin_translatedefinition   XFTD
                                           ,xx_fin_translatevalues       XFTV
                                     WHERE  XFTD.translate_id     = XFTV.translate_id
                                     AND    XFTD.translation_name = 'XX_AR_STMT_TYPES'
                                     AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                                     AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                                     AND    XFTV.enabled_flag = 'Y'
                                     AND    XFTD.enabled_flag = 'Y'
                                     AND    XFTV.target_value6 IS NOT NULL
                                    );
      IF (ln_bucket_cnt > 5) THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception raised where No of Aging Buckets > 5 Please Check the aging buckets set up'|| SQLERRM);
         RAISE EX_SETUP_EXCEPTION;
      ELSE
         FND_FILE.PUT_LINE(FND_FILE.LOG,'');
         FND_FILE.PUT_LINE(FND_FILE.LOG,' Parameters:');
         FND_FILE.PUT_LINE(FND_FILE.LOG,' Statement Cycle     :' ||lc_stmt_cycle_name);
         FND_FILE.PUT_LINE(FND_FILE.LOG,' No_of_customers     :' ||p_no_of_customers);
         FND_FILE.PUT_LINE(FND_FILE.LOG,' Customer No         :' ||p_customer_id);
         FND_FILE.PUT_LINE(FND_FILE.LOG,' Debug Flag          :' ||p_debug_flag);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'');
         gc_debug_msg := 'Organisation ID : '     ||gn_org_id     || CHR(13) ||
                         'No of Aging Buckets : ' ||ln_bucket_cnt || CHR(13) ||
                         'Deleting the records from Store Master and History tables if the statement data already exists';
         DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
         DELETE FROM xx_ar_cs_customer_master;
         DELETE FROM xx_ar_cs_docid_store_child;
         DELETE FROM xx_ar_cs_docid_str_chd_history
         WHERE statement_date  = TO_DATE(p_stmt_date,'YYYY/MM/DD HH24:MI:SS')
         AND   statement_cycle = lc_stmt_cycle_name
         AND   org_id          = gn_org_id;
         DELETE FROM xx_ar_cs_docid_store_master
         WHERE statement_date   = TO_DATE(p_stmt_date,'YYYY/MM/DD HH24:MI:SS')
         AND   statement_cycle  = lc_stmt_cycle_name
         AND   org_id           = gn_org_id;
         COMMIT;

         --------------------------------------------------------------------
         --   Calling the BULK INSERT into XX_AR_C_PS_TMP_STG temp table   --
         --------------------------------------------------------------------
         
         gc_debug_msg := 'Truncating TABLE XX_AR_PS_TMP_STG before insert:'||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS');
         DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
         EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_PS_TMP_STG';
         
         open lcu_upd_arps_full(p_customer_id);
          LOOP
             FETCH lcu_upd_arps_full
             BULK COLLECT INTO lt_upd_arps LIMIT 10000;

             FORALL i IN 1 .. lt_upd_arps.COUNT
             INSERT INTO XX_AR_PS_TMP_STG
             VALUES lt_upd_arps (i);

                IF lt_upd_arps.COUNT > 0 THEN
                   ln_insert_cnt := SQL%ROWCOUNT;
                   ln_insert_tot := ln_insert_tot + ln_insert_cnt;
                END IF;
             COMMIT;

             EXIT WHEN lcu_upd_arps_full%NOTFOUND;

          END LOOP;

         CLOSE lcu_upd_arps_full;
         gc_debug_msg := 'Total Records Inserted into XX_AR_PS_TMP_STG: '||ln_insert_tot||'; at timestamp'||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS');
         DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
         
         --------------------------------------------------
         --   Calling the INSERT_CUST_DETAILS Procedure  --
         --------------------------------------------------
         gc_debug_msg := 'Calling INSERT_CUST_DETAILS Procedure';
         DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
         INSERT_CUST_DETAILS;
         gc_debug_msg := 'INSERT_CUST_DETAILS Procedure Complete..';
         DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'');
         BEGIN
            IF ln_count = 0 THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception : No Data found for the statement cycle'|| lc_stmt_cycle_name);
               RAISE EX_SETUP_EXCEPTION;
            ELSE
               FND_FILE.PUT_LINE(FND_FILE.LOG,' Total Number of Customers    :' ||ln_count);
            END IF;
         EXCEPTION
         WHEN EX_SETUP_EXCEPTION THEN
            x_retcode := 1;
            RETURN;
         END;
           --------------------------------------------------
           --   Calling the GET_BATCH_SIZE Procedure       --
           --------------------------------------------------
         FND_FILE.PUT_LINE(FND_FILE.LOG,'');
         gc_debug_msg := 'Calling GET_BATCH_SIZE Procedure';
         DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
         GET_BATCH_SIZE;--(p_no_of_customers)Commented as its moved as the private procedure R1.4 changes;
         gc_debug_msg := 'Batching process Complete..';
         DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
        -----------------------------------------------------
        --   Calling the STORE_CHILD_DETAILS Procedure         --
        -----------------------------------------------------
         gc_debug_msg := 'Started submitting the Child Concurrent Program';
         DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
         FOR i IN (SELECT DISTINCT batch_id
                   FROM xx_ar_cs_customer_master)
            LOOP
               ln_request_id := FND_REQUEST.SUBMIT_REQUEST( 'XXFIN'
                                                           ,'XXARCSCHILD'
                                                           ,NULL
                                                           ,NULL
                                                           ,TRUE
                                                           ,ld_stmt_date
                                                           ,i.batch_id
                                                           ,p_debug_flag
                                                          );
               lc_submit_req_count := lc_submit_req_count + 1;
               COMMIT;
            END LOOP;
      END IF;
      IF lc_submit_req_count > 0 THEN
         FND_CONC_GLOBAL.set_req_globals( conc_status => 'PAUSED',request_data => 'CHILD_COMPLETE');
         lc_submit_req_count := 0;
      ELSE
         gc_debug_msg := lc_submit_req_count || ' Child Concurrent Program submitted';
         DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
         x_retcode := 1;
      END IF;
   ELSIF ( lc_request_data = 'CHILD_COMPLETE') THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'');
      FND_FILE.PUT_LINE(FND_FILE.LOG,' inside wrapper ');
      IF Get_Chid_Status(ln_parent_request_id) != 2 THEN
        gc_debug_msg := 'Inserting the customer details into Store Master Table';
        DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
        INSERT INTO xx_ar_cs_docid_store_master(customer_id
                                              ,customer_site_id
                                              ,statement_date
                                              ,location
                                              ,customer_number
                                              ,statement_cycle
                                              ,creation_date
                                              ,org_id
                                              )
        SELECT DISTINCT customer_id,customer_site_id,statement_date,location,customer_number,statement_cycle,creation_date,org_id
          FROM xx_ar_cs_docid_store_child;
         COMMIT;
        FOR i IN (SELECT DISTINCT batch_id
                FROM xx_ar_cs_customer_master)
          LOOP
             ln_request_id := FND_REQUEST.SUBMIT_REQUEST( 'XXFIN'
                                                     ,'XXARCSWRAP'
                                                     ,NULL
                                                     ,NULL
                                                     ,TRUE
                                                     ,p_stmt_date
                                                     ,'A'
                                                     ,p_debug_flag
                                                     ,i.batch_id
						    );
              lc_submit_req_count := lc_submit_req_count + 1;
          END LOOP;
          IF lc_submit_req_count > 0 THEN
             FND_CONC_GLOBAL.set_req_globals( conc_status => 'PAUSED',request_data => 'WRAPPER_COMPLETE');
             lc_submit_req_count := 0;
          ELSE
             gc_debug_msg := lc_submit_req_count || ' Child Concurrent Program submitted';
             DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
             lc_request_data := 'COMPLETE';
             x_retcode := 1;
          END IF;
      ELSE
           lc_request_data := 'COMPLETE';
      END IF;
   ELSIF ( lc_request_data = 'WRAPPER_COMPLETE') THEN
     IF Get_Chid_Status(ln_parent_request_id) != 2 THEN
         lc_stmt_date  := TO_CHAR(TO_DATE(p_stmt_date,'YYYY/MM/DD HH24:MI:SS'),'MM/DD/YYYY');
         gc_debug_msg := 'Calling the Generate Mail Body Procedure';
         DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
         GENERATE_MAIL_BODY(lc_stmt_date
                           ,p_debug_flag
                           );
         gc_debug_msg := 'Generate Mail Body Procedure Complete..';
         DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
         INSERT INTO xx_ar_cs_docid_str_chd_history
         SELECT *
          FROM xx_ar_cs_docid_store_child;
          ---------------------------------------------------------
           --   Calling the Email Delivery Shell Script Program   --
          ---------------------------------------------------------
          SUBMIT_SEND_MAIL( p_stmt_date
                          ,'A'
                          ,'Customer'
                          , null
                          , p_debug_flag
                          , lc_status
                          );
           IF ( lc_status IS NOT NULL) THEN
               x_retcode := 1;
               lc_request_data := 'COMPLETE';
           ELSE
               gc_debug_msg := 'Shell Script program completed ';
               DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
           END IF;
     ELSE
          lc_request_data := 'COMPLETE';
     END IF;
      ---------------------------------------------------------
      --   Calling the Print Customer details PROCEDURE      --
      ---------------------------------------------------------
   ELSIF ( lc_request_data = 'SENT_MAIL') THEN
      gc_debug_msg := 'Calling PRINT_CUST_DETAILS Procedure';
      DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
      SELECT name
      INTO lc_stmt_cycle_name
      FROM ar_statement_cycles
      WHERE statement_cycle_id = p_stmt_cycle;
      PRINT_CUST_DETAILS;
      gc_debug_msg := 'PRINT_CUST_DETAILS Procedure Complete..';
      DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
      gc_debug_msg := 'OD: AR Generate Customer statements Excel - Main Program Complete..';
      DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
      lc_request_data := 'COMPLETE';
   END IF;
   IF ( lc_request_data = 'COMPLETE' ) THEN
        x_retcode := Get_Chid_Status(ln_parent_request_id);
   END IF;
EXCEPTION
   WHEN EX_SETUP_EXCEPTION THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception raised in EX_SETUP_EXCEPTION in  XX_AR_GET_CUST_DETAILS procedure '|| SQLERRM);
      FND_FILE.PUT_LINE(FND_FILE.LOG,gc_debug_msg);
      x_retcode := 1;
   WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception raised in XX_AR_GET_CUST_DETAILS procedure '|| SQLERRM);
      x_retcode := 2;
END GET_CUST_DETAILS;
PROCEDURE  STORE_CHILD_DETAILS(x_errbuf            OUT  VARCHAR2
                              ,x_retcode           OUT  VARCHAR2
                              ,p_stmt_date         IN   DATE
                              ,p_batch_id          IN   NUMBER
                              ,p_debug_flag        IN   VARCHAR2
                              )
AS
-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                          Wipro-Office Depot                            |
-- +========================================================================+
-- | Name             :  STORE_CHILD_DETAILS                                |
-- | Description      :  This Procedure is find the individual and          |
-- |                     Consolidated Customer Details,Unapplied cash       |
-- |                     Receipts,calculate aging buckets and insert        |
-- |                     into the Store Child table                         |
-- |Change Record:                                                          |
-- |===============                                                         |
-- |Version   Date         Author           Remarks                         |
-- |=======   ==========   =============    ======================          |
-- |DRAFT 1.0 05-Nov-2009  Vinaykumar S    Initial draft version            |
-- |  1.1     14-DEC-2009  Vinaykumar S   Made changes to the code as       |
-- |                                      Per Subbu's Comments              |
-- |                                      Defect 3261(CR 622)               |
-- |  1.2     09-FEB-2010  Vinaykumar S   Modified the code as              |
-- |                                      Per comments from UATGB           |
-- |                                      Testing Team                      |
-- |  1.3     18-FEB-2010  Vinaykumar S   Made changes to the code to       |
-- |                                      be org Specific                   |
-- |  1.4     19-FEB-2010  Vinaykumar S   Modified for Defect # 4497        |
-- |  1.5     31-MAR-2010  Vinaykumar S   Modified for R1.3 CR 622          |
-- |                                       (CR 622)                         |
-- |  1.6     07-JUN-2010  Bhuvaneswary S Modified for R1.4 Defect 5117     |
-- |  1.7     18-MAY-2015  Manikant Kasu  Made code changes to cursor -     |
-- |                                      AOPS Individual and Consolidated  |
-- |                                      customer details,cutomers eligible|
-- |                                      for Conversion, per Defect#       |
-- |                                                                        |
-- +======================================================================+
---------------------------------
--   VARIABLE DECLARATION      --
---------------------------------
   ln_cons_bill_number  ar_cons_inv.cons_billing_number%TYPE;
   ln_aging_days        NUMBER;
   ln_current_amt       ar_payment_schedules.amount_due_remaining%TYPE;
   ln_past_due_1        ar_payment_schedules.amount_due_remaining%TYPE;
   ln_past_due_2        ar_payment_schedules.amount_due_remaining%TYPE;
   ln_past_due_3        ar_payment_schedules.amount_due_remaining%TYPE;
   ln_past_due_4        ar_payment_schedules.amount_due_remaining%TYPE;
   ln_customer_id       hz_cust_accounts.cust_account_id%TYPE;
   ln_soft_attr1        xx_om_header_attributes_all.release_number%TYPE;
   ln_soft_attr2        xx_om_header_attributes_all.cost_center_dept%TYPE;
   ln_soft_attr3        xx_om_header_attributes_all.desk_del_addr%TYPE;
   ln_soft_attr4        ra_customer_trx.purchase_order%TYPE;
   ln_customer_site_id  hz_cust_site_uses.site_use_id%TYPE;
   lc_location          hz_cust_site_uses.location%TYPE;
   ln_cust_no           hz_cust_accounts.account_number%TYPE;
   lc_stmt_cycle        ar_statement_cycles.name%TYPE;
   lc_who               fnd_user.user_id%TYPE := fnd_profile.VALUE ('USER_ID');
   ld_when              DATE   := SYSDATE;
--------------------------------------------------------------------------
-- The Cursor Selects the customer ID and Customer Site ID details      --
--------------------------------------------------------------------------
   CURSOR lcu_cust_site_id(p_batch_id  NUMBER)
   IS
      SELECT customer_id
            ,customer_site_id
            ,customer_type
            ,location
            ,customer_number
           ,statement_cycle
      FROM  xx_ar_cs_customer_master
      WHERE  batch_id = p_batch_id;
--------------------------------------------------------------
-- The Cursor Selects the distinct customer ID details      --
--------------------------------------------------------------
   CURSOR lcu_customer_id(p_batch_id  NUMBER)
   IS
      SELECT DISTINCT customer_id,customer_number,statement_cycle
      FROM  xx_ar_cs_customer_master
      WHERE  batch_id = p_batch_id;
--------------------------------------------------------------------------
-- The Cursor Selects the eligible AOPS Individual customer details     --
--------------------------------------------------------------------------
   CURSOR lcu_get_indiv_cust_details(p_customer_site_id  NUMBER, p_customer_id NUMBER)
   IS
-- Start Changes for R1.3 CR 622 Defect 3261
   SELECT /*+ ordered use_nl(APS) */
          RCT.trx_number                                                trx_number
         ,RCT.trx_date                                                  trx_date
         ,DECODE(APS.class,'INV','Invoice','CM','CreditMemo',APS.class) trx_class
         ,XOHA.cost_center_dept                                         soft_attr1  --DEPARTMENT_REPORT
         ,RCT.purchase_order                                            soft_attr2  --PO_REPORT
         ,XOHA.release_number                                           soft_attr3  --RELEASE_REPORT
         ,XOHA.desk_del_addr                                            soft_attr4  --DESKTOP_REPORT
         ,APS.amount_due_original                                       original_amt
         ,APS.amount_due_remaining                                      balance_due
         ,APS.due_date                                                  due_date
   FROM   ra_customer_trx               RCT
         ,XX_AR_PS_TMP_STG       APS
         ,xx_om_header_attributes_all   XOHA
    WHERE 1 = 1
     and (RCT.bill_to_site_use_id = p_customer_site_id 
     OR RCT.ship_to_site_use_id = p_customer_site_id)
     and rct.bill_to_customer_id = p_customer_id
     AND RCT.customer_trx_id = APS.customer_trx_id
     AND APS.status = 'OP'
     AND APS.amount_due_remaining != 0
     AND RCT.attribute14 = XOHA.header_id
     AND EXISTS ( SELECT /*+ no_unnest */ 
                        1
                  FROM xx_ar_invoice_freq_history XAIFH
                  WHERE XAIFH.paydoc_flag = 'Y'
                    AND XAIFH.invoice_id    = RCT.customer_trx_id
                )
     AND EXISTS ( SELECT 1
                  FROM   fnd_lookup_values_vl  FLV
                        ,ra_batch_sources      RBS
                  WHERE  RBS.batch_source_id = RCT.batch_source_id
                  AND    FLV.lookup_type     = 'XX_AR_CUST_STMT_SOURCE'
                  AND    FLV.meaning         =  RBS.name
                  AND    FLV.enabled_flag    = 'Y'
                  AND    FLV.tag             = 'NONCONV'
                  AND    TRUNC(SYSDATE) BETWEEN TRUNC(FLV.start_date_active)
                                         AND    TRUNC(NVL(FLV.end_date_active,SYSDATE+1))
                )
      ;
-- End Changes for R1.3 CR 622 Defect 3261
--------------------------------------------------------------------------
-- The Cursor Selects the eligible AOPS Consolidated customer details   --
--------------------------------------------------------------------------
   CURSOR lcu_get_cons_cust_details(p_customer_site_id  NUMBER, p_customer_id NUMBER)
   IS
-- Start Changes for R1.3 CR 622 Defect 3261
   select /*+ ordered use_nl(APS) */
          RCT.trx_number                                                trx_number
         ,RCT.trx_date                                                  trx_date
         ,DECODE(APS.class,'INV','Invoice','CM','CreditMemo',APS.class) trx_class
         ,XOHA.cost_center_dept                                         soft_attr1  --DEPARTMENT_REPORT
         ,RCT.purchase_order                                            soft_attr2  --PO_REPORT
         ,XOHA.release_number                                           soft_attr3  --RELEASE_REPORT
         ,XOHA.desk_del_addr                                            soft_attr4  --DESKTOP_REPORT
         ,APS.amount_due_original                                       original_amt
         ,APS.amount_due_remaining                                      balance_due
         ,APS.due_date                                                  due_date
         ,APS.cons_inv_id                                               cons_inv_id
   FROM  ra_customer_trx               RCT
        ,XX_AR_PS_TMP_STG       APS
        ,xx_om_header_attributes_all   XOHA
  WHERE 1 = 1
    and (RCT.bill_to_site_use_id = p_customer_site_id 
     OR RCT.ship_to_site_use_id = p_customer_site_id)
     and rct.bill_to_customer_id = p_customer_id
   AND APS.customer_trx_id = RCT.customer_trx_id
   AND APS.status = 'OP'
   AND APS.amount_due_remaining != 0
   AND RCT.attribute14 = XOHA.header_id
   AND EXISTS ( SELECT  1
                FROM ar_cons_inv      ACI
                    ,ar_cons_inv_trx  ACIT
                WHERE ACIT.cons_inv_id    = ACI.cons_inv_id
                AND  ACIT.customer_trx_id = RCT.customer_trx_id
                AND  ACI.site_use_id      = rct.bill_to_site_use_id
                AND (ACI.attribute2  IS NOT NULL
                OR   ACI.attribute4  IS NOT NULL
                OR   ACI.attribute10 IS NOT NULL
                OR   ACI.attribute12 IS NOT NULL)-- Added for Defect 5117 R1.4 To ensure picking up transactions sent via e-Bill.
                )
   AND EXISTS ( SELECT 1
                FROM   fnd_lookup_values_vl  FLV
                      ,ra_batch_sources      RBS
                WHERE  RBS.batch_source_id = RCT.batch_source_id
                AND    FLV.lookup_type     = 'XX_AR_CUST_STMT_SOURCE'
                AND    FLV.meaning         =  RBS.name
                AND    FLV.enabled_flag    = 'Y'
                AND    FLV.tag             = 'NONCONV'
                AND    TRUNC(SYSDATE) BETWEEN TRUNC(FLV.start_date_active)
                                       AND    TRUNC(NVL(FLV.end_date_active,SYSDATE+1))
              )
   ; 
              
-- End Changes for R1.3 CR 622 Defect 3261
-- Added Below Cursor for R1.3 CR 622 Defect 3261
-- Start Changes for R1.3 CR 622 Defect 3261
------------------------------------------------------------
-- The Cursor Selects the eligible Conversion details     --
------------------------------------------------------------
   CURSOR lcu_get_conv_details(p_customer_site_id  NUMBER, p_customer_id NUMBER)
   IS
   select /*+ ordered use_nl(APS) */
          RCT.trx_number                                                trx_number
         ,RCT.trx_date                                                  trx_date
         ,DECODE(APS.class,'INV','Invoice','CM','CreditMemo',APS.class) trx_class
         ,XOHA.cost_center_dept                                         soft_attr1  --DEPARTMENT_REPORT
         ,RCT.purchase_order                                            soft_attr2  --PO_REPORT
         ,XOHA.release_number                                           soft_attr3  --RELEASE_REPORT
         ,XOHA.desk_del_addr                                            soft_attr4  --DESKTOP_REPORT
         ,APS.amount_due_original                                       original_amt
         ,APS.amount_due_remaining                                      balance_due
         ,APS.due_date                                                  due_date
         ,APS.cons_inv_id                                               cons_inv_id
   FROM   ra_customer_trx               RCT
         ,XX_AR_PS_TMP_STG       APS
         ,xx_om_header_attributes_all   XOHA
   WHERE 1 = 1
     and (RCT.bill_to_site_use_id = p_customer_site_id 
     or RCT.SHIP_TO_SITE_USE_ID = P_CUSTOMER_SITE_ID)
     and rct.bill_to_customer_id = p_customer_id
     AND RCT.customer_trx_id = APS.customer_trx_id
     AND APS.status = 'OP'
     AND APS.amount_due_remaining != 0
     AND RCT.attribute14 = XOHA.header_id(+)
     AND EXISTS ( SELECT 1
                  FROM   fnd_lookup_values_vl     FLV
                        ,ra_batch_sources         RBS
                  WHERE  RBS.batch_source_id = RCT.batch_source_id
                  AND    FLV.lookup_type     = 'XX_AR_CUST_STMT_SOURCE'
                  AND    FLV.meaning         =  RBS.name
                  AND    FLV.enabled_flag    = 'Y'
                  AND    FLV.tag             = 'CONV'
                  AND    TRUNC(SYSDATE) BETWEEN TRUNC(FLV.start_date_active)
                                         AND    TRUNC(NVL(FLV.end_date_active,SYSDATE+1))
                )
       ;
-- End Changes for R1.3 CR 622 Defect 3261
--------------------------------------------------------------
-- The Procedure is used to find the Aging Bucket Details   --
--------------------------------------------------------------
PROCEDURE CALC_AGING_BUCKETS(p_aging_days IN NUMBER
                            ,p_balance_due IN NUMBER)
AS
   ln_bucket_seq_num  ar_aging_bucket_lines.bucket_sequence_num%TYPE;
BEGIN
   SELECT AABL.bucket_sequence_num
   INTO ln_bucket_seq_num
   FROM ar_aging_buckets       AAB
       ,ar_aging_bucket_lines  AABL
   WHERE AAB.aging_bucket_id = AABL.aging_bucket_id
   AND p_aging_days BETWEEN AABL.days_start
   AND AABL.days_to
   AND UPPER(AAB.bucket_name) = (
                                  SELECT XFTV.target_value6
                                  FROM   xx_fin_translatedefinition   XFTD
                                        ,xx_fin_translatevalues       XFTV
                                  WHERE  XFTD.translate_id     = XFTV.translate_id
                                  AND    XFTD.translation_name = 'XX_AR_STMT_TYPES'
                                  AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                                  AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                                  AND    XFTV.enabled_flag = 'Y'
                                  AND    XFTD.enabled_flag = 'Y'
                                  AND    XFTV.target_value6 IS NOT NULL
                                );
      IF (ln_bucket_seq_num = 1)
      THEN
          ln_current_amt := p_balance_due;
          ln_past_due_1 := 0;
          ln_past_due_2 := 0;
          ln_past_due_3 := 0;
          ln_past_due_4 := 0;
       ELSIF (ln_bucket_seq_num = 2)
       THEN
          ln_current_amt := 0;
          ln_past_due_1 := p_balance_due;
          ln_past_due_2 := 0;
          ln_past_due_3 := 0;
          ln_past_due_4 := 0;
       ELSIF (ln_bucket_seq_num = 3)
       THEN
          ln_current_amt := 0;
          ln_past_due_1 := 0;
          ln_past_due_2 := p_balance_due;
          ln_past_due_3 := 0;
          ln_past_due_4 := 0;
       ELSIF (ln_bucket_seq_num = 4)
       THEN
          ln_current_amt := 0;
          ln_past_due_1 := 0;
          ln_past_due_2 := 0;
          ln_past_due_3 := p_balance_due;
          ln_past_due_4 := 0;
       ELSE
          ln_current_amt := 0;
          ln_past_due_1 := 0;
          ln_past_due_2 := 0;
          ln_past_due_3 := 0;
          ln_past_due_4 := p_balance_due;
       END IF;
EXCEPTION
 WHEN OTHERS THEN
   FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception raised in validating the Aging Buckets'|| SQLERRM );
    x_retcode := 2;
END CALC_AGING_BUCKETS;
------------------------------------------------------------------------
-- The Procedure is used to find the Unapplied Cash Receipt Details   --
------------------------------------------------------------------------
PROCEDURE GET_UNAPP_CASH_DETAILS
AS
---------------------------------
--   VARIABLE DECLARATION      --
---------------------------------
   ln_trx_class       ar_payment_schedules.class%TYPE;
--------------------------------------------------------------------------
-- The Cursor Selects the Cash Receipt ID for the Customer Site ID      --
--------------------------------------------------------------------------
   CURSOR lcu_get_cash_receipt_id
   IS
   SELECT DISTINCT ARCA.cash_receipt_id  cash_receipt_id
   FROM ar_cash_receipts ARCA
   WHERE ARCA.pay_from_customer = ln_customer_id;
--------------------------------------------------------------------------
-- The Cursor Selects the Cash Receipt Details for the Cash Receipt ID  --
--------------------------------------------------------------------------
   CURSOR lcu_get_cash_receipt_details(p_cash_receipt_id  NUMBER)
   IS
   SELECT   ARCA.receipt_number                          receipt_no
           ,ARCA.receipt_date                            receipt_date
           ,MAX(ARCA.amount)                             original_amt
           ,SUM(ARAA.amount_applied)                     applied_amt
           ,MAX(ARCA.amount) - SUM(ARAA.amount_applied)  balance_due
   FROM     ar_cash_receipts                         ARCA
           ,ar_receivable_applications               ARAA
   WHERE    ARCA.cash_receipt_id = p_cash_receipt_id
   AND      ARCA.cash_receipt_id = ARAA.cash_receipt_id
  AND      ARAA.apply_date <= p_stmt_date
  -- AND      ARAA.status = 'APP'
/*Defect# 15297 Customer Statement issue in Invoices, added the status as ACTIVITY*/
 AND      ARAA.status IN ('APP','ACTIVITY')
 /* Below condition has added for the defect - 33481 */
 AND   ARCA.STATUS not in ( 'REV','STOP')
   GROUP BY ARCA.receipt_number
           ,ARCA.receipt_date
   HAVING  MAX(ARCA.amount) != SUM(ARAA.amount_applied)
/*Defect# 15297 Customer Statement issue in Invoices commented the UNION ALL for Miscellaneous Receipts*/
  UNION ALL
   SELECT   ARCA.receipt_number                          receipt_no
           ,ARCA.receipt_date                            receipt_date
           ,ARCA.amount                                  original_amt
           ,0                                            applied_amt
           ,ARCA.amount                                  balance_due
   FROM     ar_cash_receipts                         ARCA
   WHERE    ARCA.cash_receipt_id = p_cash_receipt_id
   AND      ARCA.receipt_date <= p_stmt_date
/*Defect# 15297 Customer Statement issue in Invoices, added the status as UNAPP*/
   AND      ARCA.status ='UNAPP'
  /* Below condition has added for the defect - 33481 */
   --AND   ARCA.STATUS! ='REV'
   AND NOT EXISTS (
                   SELECT 1
                   FROM  ar_receivable_applications ARAA
                   WHERE  ARAA.cash_receipt_id = ARCA.cash_receipt_id
                   AND    ARAA.status = 'APP'
                   );
   BEGIN
      ln_trx_class := 'CASH RECEIPT';
      gc_debug_msg := 'Begin GET_UNAPP_CASH_DETAILS Procedure ..:'||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS');
      DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
         FOR  lcu_rec_cash_receipt_id IN lcu_get_cash_receipt_id
          LOOP
            FOR  lcu_rec_cash_receipt_details IN lcu_get_cash_receipt_details(lcu_rec_cash_receipt_id.cash_receipt_id)
              LOOP
                --lcu_rec_cash_receipt_details.receipt_no := 'CASH '||lcu_rec_cash_receipt_details.receipt_no;  --Commented for Defect #9179
                INSERT
                INTO xx_ar_cs_docid_store_child(statement_date
                                               ,customer_id
                                               ,customer_site_id
                                               ,cons_bill_number
                                               ,trx_number
                                               ,trx_date
                                               ,trx_class
                                               ,soft_attribute1
                                               ,soft_attribute2
                                               ,soft_attribute3
                                               ,soft_attribute4
                                               ,original_amount
                                               ,balance_due
                                               ,due_date
                                               ,current_amt
                                               ,past_due_1
                                               ,past_due_2
                                               ,past_due_3
                                               ,past_due_4
                                               ,creation_date
                                               ,created_by
                                               ,last_update_date
                                               ,last_updated_by
                                               ,batch_id
                                               ,location
                                               ,customer_number
                                               ,statement_cycle
                                               ,org_id
                                               )
                VALUES                         ( p_stmt_date
                                                ,ln_customer_id
                                                ,ln_customer_site_id
                                                ,'N/A'
                                                --,lcu_rec_cash_receipt_details.receipt_no  --Commented for Defect #9179
                                                ,'CASH '||lcu_rec_cash_receipt_details.receipt_no --Added for Defect #9179
                                                ,lcu_rec_cash_receipt_details.receipt_date
                                                ,ln_trx_class
                                                ,NULL
                                                ,NULL
                                                ,NULL
                                                ,NULL
                                                ,lcu_rec_cash_receipt_details.original_amt*(-1)
                                                ,lcu_rec_cash_receipt_details.balance_due*(-1)
                                                ,NULL
                                                ,lcu_rec_cash_receipt_details.balance_due*(-1)
                                                ,0
                                                ,0
                                                ,0
                                                ,0
                                                ,ld_when
                                                ,lc_who
                                                ,ld_when
                                                ,lc_who
                                                ,p_batch_id
                                                ,NULL
                                                ,ln_cust_no
                                                ,lc_stmt_cycle
                                                ,gn_org_id
                                                );
              END LOOP;
              COMMIT;
          END LOOP;
          COMMIT;
          gc_debug_msg := 'END GET_UNAPP_CASH_DETAILS Procedure ..:'||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS');
      DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
   EXCEPTION
     WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception raised in GET_UNAPP_CASH_DETAILS procedure '|| SQLERRM);
            x_retcode := 2;
   END GET_UNAPP_CASH_DETAILS;
   BEGIN
      gc_debug_msg := 'In STORE_CHILD_DETAILS Procedure ..:'||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS');
      DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'');
      gc_debug_msg := 'Inserting the Consolidated and Individual Customer Details into Child Table..:'||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS');
      DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
      FOR lcu_rec_cust_site_id IN lcu_cust_site_id(p_batch_id)
         LOOP
            ln_cons_bill_number := 'N/A';
            ln_customer_id      := lcu_rec_cust_site_id.customer_id;
            ln_customer_site_id := lcu_rec_cust_site_id.customer_site_id;
            lc_location         := lcu_rec_cust_site_id.location;
            ln_cust_no          := lcu_rec_cust_site_id.customer_number;
            lc_stmt_cycle       := lcu_rec_cust_site_id.statement_cycle;
       --     IF lcu_rec_cust_site_id.customer_type = 'I' THEN       Commented for R1.3 CR 622 Defect 3261
               FND_FILE.PUT_LINE(FND_FILE.LOG,'');
               FOR  lcu_rec_indiv_cust_details IN lcu_get_indiv_cust_details(lcu_rec_cust_site_id.customer_site_id,lcu_rec_cust_site_id.customer_id)
                  LOOP
                   IF lcu_rec_indiv_cust_details.trx_date <= p_stmt_date THEN
                  -------------------------------------------------------------------------
                  --     Reinitializing the Aging Bucket Values for every customer site  --
                  -------------------------------------------------------------------------
                     ln_current_amt   := 0;
                     ln_past_due_1    := 0;
                     ln_past_due_2    := 0;
                     ln_past_due_3    := 0;
                     ln_past_due_4    := 0;
                 -------------------------------------------------------------------------
                 --     Initializing the Soft Header Values for every customer site     --
                 -------------------------------------------------------------------------
                      ln_soft_attr1   := lcu_rec_indiv_cust_details.soft_attr1;
                      ln_soft_attr2   := lcu_rec_indiv_cust_details.soft_attr2;
                      ln_soft_attr3   := lcu_rec_indiv_cust_details.soft_attr3;
                      ln_soft_attr4   := lcu_rec_indiv_cust_details.soft_attr4;
                      ln_aging_days :=  TRUNC(p_stmt_date) - TRUNC(lcu_rec_indiv_cust_details.due_date);
                 -------------------------------------------------------
                 --   Calling the CALC_AGING_BUCKETS Procedure  --
                  -------------------------------------------------------
                 CALC_AGING_BUCKETS(ln_aging_days
                                   ,lcu_rec_indiv_cust_details.balance_due
                                   );
                 INSERT INTO xx_ar_cs_docid_store_child( statement_date
                                                        ,customer_id
                                                        ,customer_site_id
                                                        ,cons_bill_number
                                                        ,trx_number
                                                        ,trx_date
                                                        ,trx_class
                                                        ,soft_attribute1
                                                        ,soft_attribute2
                                                        ,soft_attribute3
                                                        ,soft_attribute4
                                                        ,original_amount
                                                        ,balance_due
                                                        ,due_date
                                                        ,current_amt
                                                        ,past_due_1
                                                        ,past_due_2
                                                        ,past_due_3
                                                        ,past_due_4
                                                        ,creation_date
                                                        ,created_by
                                                        ,last_update_date
                                                        ,last_updated_by
                                                        ,batch_id
                                                        ,location
                                                        ,customer_number
                                                        ,statement_cycle
                                                        ,org_id
                                                        )
                  VALUES                               ( p_stmt_date
                                                        ,lcu_rec_cust_site_id.customer_id
                                                        ,lcu_rec_cust_site_id.customer_site_id
                                                        ,'N/A'
                                                        ,lcu_rec_indiv_cust_details.trx_number
                                                        ,lcu_rec_indiv_cust_details.trx_date
                                                        ,lcu_rec_indiv_cust_details.trx_class
                                                        ,lcu_rec_indiv_cust_details.soft_attr1
                                                        ,lcu_rec_indiv_cust_details.soft_attr2
                                                        ,lcu_rec_indiv_cust_details.soft_attr3
                                                        ,lcu_rec_indiv_cust_details.soft_attr4
                                                        ,lcu_rec_indiv_cust_details.original_amt
                                                        ,lcu_rec_indiv_cust_details.balance_due
                                                        ,lcu_rec_indiv_cust_details.due_date
                                                        ,ln_current_amt
                                                        ,ln_past_due_1
                                                        ,ln_past_due_2
                                                        ,ln_past_due_3
                                                        ,ln_past_due_4
                                                        ,ld_when
                                                        ,lc_who
                                                        ,ld_when
                                                        ,lc_who
                                                        ,p_batch_id
                                                        ,lcu_rec_cust_site_id.location
                                                        ,lcu_rec_cust_site_id.customer_number
                                                        ,lcu_rec_cust_site_id.statement_cycle
                                                        ,gn_org_id
                                                       );
                     END IF;
                   END LOOP;
                   COMMIT;
          --  ELSE          Commented for R1.3 CR 622 Defect 3261
                FOR  lcu_rec_cons_cust_details IN lcu_get_cons_cust_details(lcu_rec_cust_site_id.customer_site_id,lcu_rec_cust_site_id.customer_id)
                   LOOP
                     IF lcu_rec_cons_cust_details.trx_date <= p_stmt_date THEN
                      SELECT ACI.cons_billing_number
                      INTO   ln_cons_bill_number
                      FROM  ar_cons_inv ACI
                      WHERE ACI.cons_inv_id = lcu_rec_cons_cust_details.cons_inv_id;
                      -------------------------------------------------------------------------
                      --     Reinitializing the Aging Bucket Values for every customer site  --
                       -------------------------------------------------------------------------
                     ln_current_amt   := 0;
                     ln_past_due_1    := 0;
                     ln_past_due_2    := 0;
                     ln_past_due_3    := 0;
                     ln_past_due_4    := 0;
                     -------------------------------------------------------------------------
                     --     Initializing the Soft Header Values for every customer site     --
                      -------------------------------------------------------------------------
                     ln_soft_attr1   := lcu_rec_cons_cust_details.soft_attr1;
                     ln_soft_attr2   := lcu_rec_cons_cust_details.soft_attr2;
                     ln_soft_attr3   := lcu_rec_cons_cust_details.soft_attr3;
                     ln_soft_attr4   := lcu_rec_cons_cust_details.soft_attr4;
                     ln_aging_days :=  TRUNC(p_stmt_date) - TRUNC(lcu_rec_cons_cust_details.due_date);
                     --------------------------------------------------
                     --   Calling the CALC_AGING_BUCKETS Procedure   --
                     --------------------------------------------------
                     CALC_AGING_BUCKETS(ln_aging_days
                                       ,lcu_rec_cons_cust_details.balance_due
                                       );
                     INSERT INTO xx_ar_cs_docid_store_child(statement_date
                                                           ,customer_id
                                                           ,customer_site_id
                                                           ,cons_bill_number
                                                           ,trx_number
                                                           ,trx_date
                                                           ,trx_class
                                                           ,soft_attribute1
                                                           ,soft_attribute2
                                                           ,soft_attribute3
                                                           ,soft_attribute4
                                                           ,original_amount
                                                           ,balance_due
                                                           ,due_date
                                                           ,current_amt
                                                           ,past_due_1
                                                           ,past_due_2
                                                           ,past_due_3
                                                           ,past_due_4
                                                           ,creation_date
                                                           ,created_by
                                                           ,last_update_date
                                                           ,last_updated_by
                                                           ,batch_id
                                                           ,location
                                                           ,customer_number
                                                           ,statement_cycle
                                                           ,org_id
                                                           )
                       VALUES                             ( p_stmt_date
                                                           ,lcu_rec_cust_site_id.customer_id
                                                           ,lcu_rec_cust_site_id.customer_site_id
                                                           ,ln_cons_bill_number
                                                           ,lcu_rec_cons_cust_details.trx_number
                                                           ,lcu_rec_cons_cust_details.trx_date
                                                           ,lcu_rec_cons_cust_details.trx_class
                                                           ,lcu_rec_cons_cust_details.soft_attr1
                                                           ,lcu_rec_cons_cust_details.soft_attr2
                                                           ,lcu_rec_cons_cust_details.soft_attr3
                                                           ,lcu_rec_cons_cust_details.soft_attr4
                                                           ,lcu_rec_cons_cust_details.original_amt
                                                           ,lcu_rec_cons_cust_details.balance_due
                                                           ,lcu_rec_cons_cust_details.due_date
                                                           ,ln_current_amt
                                                           ,ln_past_due_1
                                                           ,ln_past_due_2
                                                           ,ln_past_due_3
                                                           ,ln_past_due_4
                                                           ,ld_when
                                                           ,lc_who
                                                           ,ld_when
                                                           ,lc_who
                                                           ,p_batch_id
                                                           ,lcu_rec_cust_site_id.location
                                                           ,lcu_rec_cust_site_id.customer_number
                                                           ,lcu_rec_cust_site_id.statement_cycle
                                                           ,gn_org_id
                                                           );
                    END IF;
                   END LOOP;
                   COMMIT;
      --      END IF;      Commented for R1.3 CR 622 Defect 3261
    -- Added Below comments for R1.3 CR 622 Defect 3261
    -- Start Changes for R1.3 CR 622 Defect 3261
            gc_debug_msg := 'Inserting the Conversion Details into Child Table..:'||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS');
            DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
            FND_FILE.PUT_LINE(FND_FILE.log,'');
            FOR  lcu_rec_get_conv_details IN lcu_get_conv_details(lcu_rec_cust_site_id.customer_site_id,lcu_rec_cust_site_id.customer_id)
               LOOP
                  IF lcu_rec_get_conv_details.trx_date <= p_stmt_date THEN
                    IF lcu_rec_get_conv_details.cons_inv_id IS NOT NULL THEN
                       SELECT NVL(ACI.cons_billing_number,'N/A')
                       INTO   ln_cons_bill_number
                       FROM  ar_cons_inv ACI
                       WHERE ACI.cons_inv_id = lcu_rec_get_conv_details.cons_inv_id;
                    ELSE
                       ln_cons_bill_number := NULL;
                    END IF;
                     -------------------------------------------------------------------------
                     --     Reinitializing the Aging Bucket Values for every customer site  --
                     -------------------------------------------------------------------------
                        ln_current_amt   := 0;
                        ln_past_due_1    := 0;
                        ln_past_due_2    := 0;
                        ln_past_due_3    := 0;
                        ln_past_due_4    := 0;
                    -------------------------------------------------------------------------
                    --     Initializing the Soft Header Values for every customer site     --
                    -------------------------------------------------------------------------
                         ln_soft_attr1   := lcu_rec_get_conv_details.soft_attr1;
                         ln_soft_attr2   := lcu_rec_get_conv_details.soft_attr2;
                         ln_soft_attr3   := lcu_rec_get_conv_details.soft_attr3;
                         ln_soft_attr4   := lcu_rec_get_conv_details.soft_attr4;
                         ln_aging_days :=  TRUNC(p_stmt_date) - TRUNC(lcu_rec_get_conv_details.due_date);
                    -------------------------------------------------------
                    --   Calling the CALC_AGING_BUCKETS Procedure  --
                     -------------------------------------------------------
                         CALC_AGING_BUCKETS(ln_aging_days
                                           ,lcu_rec_get_conv_details.balance_due
                                           );
                      INSERT INTO xx_ar_cs_docid_store_child( statement_date
                                                             ,customer_id
                                                             ,customer_site_id
                                                             ,cons_bill_number
                                                             ,trx_number
                                                             ,trx_date
                                                             ,trx_class
                                                             ,soft_attribute1
                                                             ,soft_attribute2
                                                             ,soft_attribute3
                                                             ,soft_attribute4
                                                             ,original_amount
                                                             ,balance_due
                                                             ,due_date
                                                             ,current_amt
                                                             ,past_due_1
                                                             ,past_due_2
                                                             ,past_due_3
                                                             ,past_due_4
                                                             ,creation_date
                                                             ,created_by
                                                             ,last_update_date
                                                             ,last_updated_by
                                                             ,batch_id
                                                             ,location
                                                             ,customer_number
                                                             ,statement_cycle
                                                             ,org_id
                                                             )
                       VALUES                               ( p_stmt_date
                                                             ,lcu_rec_cust_site_id.customer_id
                                                             ,lcu_rec_cust_site_id.customer_site_id
                                                             ,ln_cons_bill_number
                                                             ,lcu_rec_get_conv_details.trx_number
                                                             ,lcu_rec_get_conv_details.trx_date
                                                             ,lcu_rec_get_conv_details.trx_class
                                                             ,lcu_rec_get_conv_details.soft_attr1
                                                             ,lcu_rec_get_conv_details.soft_attr2
                                                             ,lcu_rec_get_conv_details.soft_attr3
                                                             ,lcu_rec_get_conv_details.soft_attr4
                                                             ,lcu_rec_get_conv_details.original_amt
                                                             ,lcu_rec_get_conv_details.balance_due
                                                             ,lcu_rec_get_conv_details.due_date
                                                             ,ln_current_amt
                                                             ,ln_past_due_1
                                                             ,ln_past_due_2
                                                             ,ln_past_due_3
                                                             ,ln_past_due_4
                                                             ,ld_when
                                                             ,lc_who
                                                             ,ld_when
                                                             ,lc_who
                                                             ,p_batch_id
                                                             ,lc_location
                                                             ,ln_cust_no
                                                             ,lc_stmt_cycle
                                                             ,gn_org_id
                                                            );
               END IF;
            END LOOP;
            COMMIT;
   -- End Changes for R1.3 CR 622 Defect 3261
            gc_debug_msg := 'Customer ID          : '||lcu_rec_cust_site_id.customer_id;
            DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
            gc_debug_msg := 'Customer Site ID     : '||lcu_rec_cust_site_id.customer_site_id;
            DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
         END LOOP;
         COMMIT;
         -------------------------------------------------------
         --  Calling the GET_UNAPP_CASH_DETAILS Procedure  --
         -------------------------------------------------------
         gc_debug_msg := 'Calling the GET_UNAPP_CASH_DETAILS Procedure:'||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS');
         DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'');
         FOR  lcu_rec_customer_id IN lcu_customer_id(p_batch_id)
            LOOP
               ln_customer_site_id := 0;
               ln_customer_id      := lcu_rec_customer_id.customer_id;
               ln_cust_no          := lcu_rec_customer_id.customer_number;
               lc_stmt_cycle       := lcu_rec_customer_id.statement_cycle;
               GET_UNAPP_CASH_DETAILS;
            END LOOP;
            COMMIT;
         gc_debug_msg := 'GET_UNAPP_CASH_DETAILS Procedure Complete..:'||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS');
         DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'');
         gc_debug_msg := 'STORE_CHILD_DETAILS Procedure Complete..:'||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS');
         DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'');
   EXCEPTION
      WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception raised in STORE_CHILD_DETAILS procedure '|| SQLERRM);
            x_retcode := 2;
   END STORE_CHILD_DETAILS;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  SUBMIT_REP_BURST                              |
-- | Description      :  This Procedure is used to submit the report   |
-- |                     for the batch id passed and to submit the     |
-- |                     respective bursting program                   |
-- |                     Statements                                    |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |DRAFT 1.0 08-Jun-2010  Bhuvaneswary S    Initial draft version     |
-- +===================================================================+
PROCEDURE SUBMIT_REP_BURST(x_errbuf        OUT   VARCHAR2
                          ,x_retcode       OUT   VARCHAR2
                          ,p_stmt_date     IN VARCHAR2
                          ,p_burst_flag    IN VARCHAR2
                          ,p_debug_flag    IN VARCHAR2
                          ,p_batch_id      IN NUMBER
                          )
AS
   ln_request_id_site   NUMBER;
   ln_request_id_cust   NUMBER;
   EX_SETUP_EXCEPTION   EXCEPTION;
   ld_stmt_date         DATE;
   lc_stmt_date         VARCHAR2(20);
   lc_request_data      VARCHAR2(500);
   ln_request_id        NUMBER;
   lc_submit_req_count  NUMBER := 0;
   ln_cnt_err_request   NUMBER;
   ln_cnt_war_request   NUMBER;
   ln_parent_request_id NUMBER;
BEGIN
   ld_stmt_date := TO_DATE(p_stmt_date,'YYYY/MM/DD HH24:MI:SS');
   lc_stmt_date := TO_CHAR(ld_stmt_date,'DD-MON-YYYY');
   lc_request_data      :=FND_CONC_GLOBAL.request_data;
   ln_parent_request_id := FND_GLOBAL.conc_request_id;
   ln_request_id        := 0;
   IF ( lc_request_data IS NULL ) THEN
      IF (p_burst_flag = 'A' OR p_burst_flag = 'S') THEN
         gc_debug_msg  := 'Started submitting the report for site level';
         DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
         ln_request_id_site := FND_REQUEST.SUBMIT_REQUEST( 'XXFIN'
                                                          ,'XXARCSEXT'
                                                          ,NULL
                                                          ,NULL
                                                          ,TRUE
                                                          ,ld_stmt_date
                                                          ,p_batch_id
                                                          ,'N'
                                                         );
         lc_submit_req_count := lc_submit_req_count + 1;
         COMMIT;
      END IF;
      IF (p_burst_flag = 'A' OR p_burst_flag = 'C') THEN
         gc_debug_msg  := 'Started submitting the report for Customer level';
         DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
         ln_request_id_cust := FND_REQUEST.SUBMIT_REQUEST( 'XXFIN'
                                                          ,'XXARCSEXT'
                                                          ,NULL
                                                          ,NULL
                                                          ,TRUE
                                                          ,ld_stmt_date
                                                          ,p_batch_id
                                                          ,'Y'
                                                         );
         lc_submit_req_count := lc_submit_req_count + 1;
         COMMIT;
      END IF;
      IF lc_submit_req_count > 0 THEN
         FND_CONC_GLOBAL.set_req_globals( conc_status => 'PAUSED',request_data => ln_request_id_site || '-' || ln_request_id_cust);
         lc_submit_req_count := 0;
      ELSE
         gc_debug_msg := lc_submit_req_count || ' Reports submitted';
         DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
         lc_request_data := 'COMPLETE';
          x_retcode := 1;
      END IF;
   ELSIF (INSTR(lc_request_data,'-') != 0) THEN
     IF Get_Chid_Status(ln_parent_request_id) != 2 THEN
        IF (p_burst_flag = 'A' OR p_burst_flag = 'S') THEN
           ln_request_id := FND_REQUEST.SUBMIT_REQUEST( 'XXFIN'
                                                  ,'XXARCSEBP'
                                                  ,NULL
                                                  ,NULL
                                                  ,TRUE
                                                  ,SUBSTR(lc_request_data,1,INSTR(lc_request_data,'-')-1)
                                                  ,'N'
                                                 );
           lc_submit_req_count := lc_submit_req_count + 1;
           COMMIT;
        END IF;
        IF (p_burst_flag = 'A' OR p_burst_flag = 'C') THEN
           ln_request_id := FND_REQUEST.SUBMIT_REQUEST( 'XXFIN'
                                                  ,'XXARCSEBP'
                                                  ,NULL
                                                  ,NULL
                                                  ,TRUE
                                                  ,SUBSTR(lc_request_data,INSTR(lc_request_data,'-')+1)
                                                  ,'Y'
                                                 );
           lc_submit_req_count := lc_submit_req_count + 1;
           COMMIT;
        END IF;
        IF lc_submit_req_count > 0 THEN
           FND_CONC_GLOBAL.set_req_globals( conc_status => 'PAUSED',request_data => 'COMPLETE');
           lc_submit_req_count := 0;
        ELSE
           gc_debug_msg := lc_submit_req_count || ' Bursting programs submitted';
           DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
           lc_request_data := 'COMPLETE';
           x_retcode := 1;
        END IF;
     ELSE
        lc_request_data := 'COMPLETE';
     END IF;
   END IF;
   IF ( lc_request_data = 'COMPLETE' AND ln_request_id = 0) THEN
        x_retcode := Get_Chid_Status(ln_parent_request_id);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception raised in SUBMIT_REP_BURST Procedure'|| SQLERRM);
      x_retcode := 2;
END SUBMIT_REP_BURST;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  SUBMIT_SEND_MAIL                              |
-- | Description      :  This Procedure is used for calling the shell  |
-- |                     script program which in turn mails the        |
-- |                     statements   to the respective e mail ids     |
-- |                     for the batch id passed and to submit the     |
-- |                     respective bursting program                   |
-- |                     Statements                                    |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |DRAFT 1.0 08-Jun-2010  Bhuvaneswary S    Initial draft version     |
-- +===================================================================+
PROCEDURE SUBMIT_SEND_MAIL(p_stmt_date     IN  VARCHAR2
                          ,p_burst_flag    IN  VARCHAR2
                          ,p_send_email    IN  VARCHAR2
                          ,p_user_emailid  IN  VARCHAR2
                          ,p_debug_flag    IN  VARCHAR2
                          ,p_status        OUT NUMBER
                          )
AS
   ln_request_id          NUMBER;
   EX_SETUP_EXCEPTION     EXCEPTION;
   ld_stmt_date           DATE;
   lc_stmt_date           VARCHAR2(20);
   lc_source_file_path    VARCHAR2(2000);
   lc_archive_file_path   VARCHAR2(2000);
   lc_src_site_file_path  VARCHAR2(2000);
   lc_arch_site_file_path VARCHAR2(2000);
   lc_resend_flag         VARCHAR2(2);
   lc_from_email_add      VARCHAR2(240);
   lc_request_data        VARCHAR2(50);
   lc_submit_req_count    NUMBER := 0;
   lc_max_file_size       VARCHAR2(50);
   lc_filesize_user_id    VARCHAR2(4000);
   lc_ftp_cust_path       VARCHAR2(2000);
   lc_ftp_custsite_path   VARCHAR2(2000);
   lc_mail_print_ftp      VARCHAR2(2000);
BEGIN
   gc_debug_msg := 'Finding the source and Archive path for Customer/Site Level from translations';
   DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
   lc_request_data :=FND_CONC_GLOBAL.request_data;
   ld_stmt_date := TO_DATE(p_stmt_date,'YYYY/MM/DD HH24:MI:SS');
   lc_stmt_date := TO_CHAR(ld_stmt_date,'DD-MON-YYYY');
    ------------------------------
    --    Get Resend Flag       --
    ------------------------------
   IF (p_burst_flag = 'C' OR p_burst_flag = 'S')  THEN
      lc_resend_flag := 'Y';
   ELSIF  (p_burst_flag = 'A') THEN
      lc_resend_flag := 'N';
   END IF;
   IF ( lc_request_data = 'WRAPPER_COMPLETE' ) THEN
      BEGIN
      ------------------------------------------------------------------------------
      --   Getting the Source File Path and Archive File Path using Translations  --
      ------------------------------------------------------------------------------
         SELECT XFTV.target_value2
               ,XFTV.target_value3
               ,XFTV.target_value4
               ,XFTV.target_value5
               ,XFTV.target_value9
               ,XFTV.target_value10
               ,XFTV.target_value11
               ,XFTV.target_value12
	       ,XFTV.target_value13
         INTO   lc_source_file_path
               ,lc_archive_file_path
               ,lc_src_site_file_path
               ,lc_arch_site_file_path
               ,lc_max_file_size
               ,lc_filesize_user_id
               ,lc_ftp_cust_path
               ,lc_ftp_custsite_path
	       ,lc_mail_print_ftp
         FROM   xx_fin_translatedefinition XFTD
               ,xx_fin_translatevalues     XFTV
         WHERE  XFTD.translate_id     = XFTV.translate_id
         AND    XFTD.translation_name = 'XX_AR_STMT_TYPES'
         AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
         AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
         AND    XFTV.enabled_flag     = 'Y'
         AND    XFTD.enabled_flag     = 'Y'
         AND    XFTV.target_value2 IS NOT NULL
         AND    XFTV.target_value3 IS NOT NULL
         AND    XFTV.target_value4 IS NOT NULL
         AND    XFTV.target_value5 IS NOT NULL;
      EXCEPTION
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception raised while getting Source and Archive File paths for Customer/Site Level '|| SQLERRM);
            RAISE EX_SETUP_EXCEPTION;
      END;
      BEGIN
         SELECT text
         INTO   lc_from_email_add
         FROM   ar_standard_text_vl
         WHERE  name = 'OD_CUST_STMT_FROM_EMAIL';
      EXCEPTION
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception raised while getting From Email Address '|| SQLERRM);
            RAISE EX_SETUP_EXCEPTION;
      END;
      IF (p_burst_flag = 'A' OR p_burst_flag = 'S') THEN
         gc_debug_msg  := 'Started submitting the Shell Script for site level, for email address: '||p_user_emailid ;
         DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
         
         ln_request_id := FND_REQUEST.SUBMIT_REQUEST( 'XXFIN'
                                                     ,'XXARCSEMAILDOC'
                                                     ,NULL
                                                     ,NULL
                                                     ,TRUE
                                                     ,lc_stmt_date
                                                     ,lc_src_site_file_path
                                                     ,lc_arch_site_file_path
                                                     ,gc_directory_path||'/'||gc_html_file
                                                     ,'N'
                                                     ,p_send_email
                                                     ,p_user_emailid
                                                     ,lc_resend_flag
                                                     ,lc_from_email_add
                                                     ,gn_org_id
                                                     ,gc_directory_path||'/'||gc_html_file_user_p1
                                                     ,gc_directory_path||'/'||gc_html_file_user_p2
                                                     ,lc_ftp_custsite_path
                                                     ,lc_mail_print_ftp
                                                     ,lc_max_file_size
                                                     ,lc_filesize_user_id
                                                     );
         lc_submit_req_count := lc_submit_req_count + 1;
         COMMIT;
      END IF;
      IF (p_burst_flag = 'A' OR p_burst_flag = 'C') THEN
         gc_debug_msg := 'Started submitting the Shell Script for Customer Header level, for email address: '||p_user_emailid ;
         DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
         
         ln_request_id := FND_REQUEST.SUBMIT_REQUEST( 'XXFIN'
                                                     ,'XXARCSEMAILDOC'
                                                     ,NULL
                                                     ,NULL
                                                     ,TRUE
                                                     ,lc_stmt_date
                                                     ,lc_source_file_path
                                                     ,lc_archive_file_path
                                                     ,gc_directory_path||'/'||gc_html_file
                                                     ,'Y'
                                                     ,p_send_email
                                                     ,p_user_emailid
                                                     ,lc_resend_flag
                                                     ,lc_from_email_add
                                                     ,gn_org_id
                                                     ,gc_directory_path||'/'||gc_html_file_user_p1
                                                     ,gc_directory_path||'/'||gc_html_file_user_p2
                                                     ,lc_ftp_cust_path
                                                     ,lc_mail_print_ftp
                                                     ,lc_max_file_size
                                                     ,lc_filesize_user_id
                                                    );
         lc_submit_req_count := lc_submit_req_count + 1;
         COMMIT;
      END IF;
      IF lc_submit_req_count > 0 THEN
         FND_CONC_GLOBAL.set_req_globals( conc_status => 'PAUSED',request_data => 'SENT_MAIL');
         lc_submit_req_count := 0;
      ELSE
         gc_debug_msg := lc_submit_req_count || ' SHELL_SCRIPT programs submitted';
         DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
         p_status := 1;
      END IF;
   END IF;
EXCEPTION
   WHEN EX_SETUP_EXCEPTION THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception raised in SUBMIT_SEND_MAIL Procedure in EX_SETUP_EXCEPTION'|| SQLERRM);
   WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception raised in SUBMIT_SEND_MAIL Procedure'|| SQLERRM);
END SUBMIT_SEND_MAIL;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  CUST_STMT_RESEND_MAIN                         |
-- | Description      :  This Procedure is used to resend the Customer |
-- |                     Statements                                    |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |DRAFT 1.0 12-Nov-2009  Vinaykumar S    Initial draft version       |
-- |  1.1     14-DEC-2009  Vinaykumar S   Made changes to the code as  |
-- |                                      Per Subbu's Comments         |
-- |                                      Defect 3261(CR 622)          |
-- |  1.2     18-FEB-2010  Vinaykumar S   Made changes to the code to  |
-- |                                      be org Specific              |
-- +===================================================================+
PROCEDURE  CUST_STMT_RESEND_MAIN( x_errbuf          OUT   VARCHAR2
                                 ,x_retcode         OUT   VARCHAR2
                                 ,p_stmt_date        IN   VARCHAR2
                                 ,p_customer_id      IN   NUMBER
                                 ,p_customer_site_id IN   NUMBER
                                 ,p_email_id         IN   VARCHAR2
                                 ,p_send_email       IN   VARCHAR2
                                 ,p_debug_flag       IN   VARCHAR2
                                )
AS
---------------------------------
--   VARIABLE DECLARATION      --
---------------------------------
   lc_location           hz_cust_site_uses.location%TYPE;
   lc_cons_flag          VARCHAR2(2);
   ln_batch_id           NUMBER;
   lc_submit_req_count   NUMBER := 0;
   lc_stmt_date          VARCHAR2(20);
   ld_stmt_date          DATE;
   ln_cust_cnt           NUMBER;
   ln_cust_site_cnt      NUMBER;
   lc_burst_flag         VARCHAR2(2);
   lc_request_data       VARCHAR2(50);
   ln_request_id         NUMBER;
   ln_parent_request_id  NUMBER;
   ln_cnt_err_request    NUMBER;
   ln_cnt_war_request    NUMBER;
   lc_status             NUMBER;
   CURSOR lcu_site_id(p_customer_id  NUMBER)
   IS
   SELECT customer_site_id
   FROM xx_ar_cs_docid_store_master
   WHERE customer_id = p_customer_id
   AND   statement_date = ld_stmt_date;
BEGIN
   lc_request_data      := FND_CONC_GLOBAL.request_data;
   ln_parent_request_id := FND_GLOBAL.conc_request_id;
   IF ( lc_request_data IS NULL ) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'');
      FND_FILE.PUT_LINE(FND_FILE.LOG,' Parameters:');
      FND_FILE.PUT_LINE(FND_FILE.LOG,' Statement Date    :' ||p_stmt_date);
      FND_FILE.PUT_LINE(FND_FILE.LOG,' Customer ID       :' ||p_customer_id);
      FND_FILE.PUT_LINE(FND_FILE.LOG,' Customer Site ID  :' ||p_customer_site_id);
      FND_FILE.PUT_LINE(FND_FILE.LOG,' Email ID          :' ||p_email_id);
      FND_FILE.PUT_LINE(FND_FILE.LOG,' Send Email To     :' ||p_send_email);
      FND_FILE.PUT_LINE(FND_FILE.LOG,' Debug Flag        :' ||p_debug_flag);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'');
      DELETE FROM xx_ar_cs_customer_master;
      DELETE FROM xx_ar_cs_docid_store_child;
      COMMIT;
      SELECT xx_ar_cs_customer_master_s.NEXTVAL
      INTO ln_batch_id
      FROM dual;
      ld_stmt_date := TO_DATE(p_stmt_date,'YYYY/MM/DD HH24:MI:SS');
      IF (p_customer_id IS NOT NULL AND p_customer_site_id IS NULL) THEN
         FOR lcu_rec_site_id IN lcu_site_id(p_customer_id)
            LOOP
               INSERT INTO xx_ar_cs_customer_master(customer_id
                                                   ,customer_site_id
                                                   ,batch_id
                                                   )
               VALUES                             (p_customer_id
                                                  ,lcu_rec_site_id.customer_site_id
                                                  ,ln_batch_id
                                                   );
             END LOOP;
         lc_burst_flag := 'C';
         gc_debug_msg := 'Burst Flag : ' ||lc_burst_flag;
         DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
      ELSIF (p_customer_site_id IS NOT NULL) THEN
         INSERT INTO xx_ar_cs_customer_master(customer_id
                                             ,customer_site_id
                                             ,batch_id
                                             )
         VALUES                              (p_customer_id
                                             ,p_customer_site_id
                                             ,ln_batch_id
                                             );
         lc_burst_flag := 'S';
         gc_debug_msg := 'Burst Flag : ' ||lc_burst_flag;
         DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
      END IF ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'');
      gc_debug_msg := 'Fetching the statement details from History table and Inserting into Child table';
      DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
      INSERT INTO xx_ar_cs_docid_store_child
      SELECT * FROM xx_ar_cs_docid_str_chd_history XACSH
      WHERE XACSH.customer_id     = p_customer_id
      AND  XACSH.customer_site_id = NVL(p_customer_site_id,XACSH.customer_site_id)
      AND  XACSH.statement_date   = ld_stmt_date
      AND  XACSH.org_id           = gn_org_id;
      UPDATE xx_ar_cs_docid_store_child
      SET batch_id = ln_batch_id;
      -----------------------------------------------------------------------------
      --  Calling the SUBMIT_REP_BURST Procedure to submit a report and Bursting --
      -----------------------------------------------------------------------------
      gc_debug_msg := 'Calling Wrapper to submit a report and Bursting ';
      DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'');
      FOR i IN (SELECT DISTINCT batch_id
                FROM xx_ar_cs_customer_master)
      LOOP
         ln_request_id := FND_REQUEST.SUBMIT_REQUEST( 'XXFIN'
                                                     ,'XXARCSWRAP'
                                                     ,NULL
                                                     ,NULL
                                                     ,TRUE
                                                     ,p_stmt_date
                                                     ,lc_burst_flag
                                                     ,p_debug_flag
                                                     ,i.batch_id
                                                    );
         lc_submit_req_count := lc_submit_req_count + 1;
      END LOOP;
      IF lc_submit_req_count > 0 THEN
         FND_CONC_GLOBAL.set_req_globals( conc_status => 'PAUSED',request_data => 'WRAPPER_COMPLETE');
         lc_submit_req_count := 0;
      ELSE
         gc_debug_msg := lc_submit_req_count || ' Wrapper programs submitted';
         DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
         lc_request_data := 'COMPLETE';
         x_retcode := 1;
      END IF;
   ELSIF (lc_request_data = 'WRAPPER_COMPLETE' ) THEN
      IF Get_Chid_Status(ln_parent_request_id) != 2 THEN
         lc_stmt_date  := TO_CHAR(TO_DATE(p_stmt_date,'YYYY/MM/DD HH24:MI:SS'),'MM/DD/YYYY');
         ------------------------------------------------------------
          --       Calling the GENERATE_MAIL_BODY Procedure         --
         ------------------------------------------------------------
         FND_FILE.PUT_LINE(FND_FILE.LOG,'');
         gc_debug_msg := 'Calling the Generate Mail Body Procedure';
         DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
         GENERATE_MAIL_BODY(lc_stmt_date
                           ,p_debug_flag
                           );
         gc_debug_msg := 'Generate Mail Body Procedure Complete..';
         DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'');
         ------------------------------------------------------------------------------
          --       Calling the SUBMIT_SEND_MAIL Procedure  to submit a Shell Script       --
         ------------------------------------------------------------------------------
         gc_debug_msg := 'Calling SUBMIT_SEND_MAIL Procedure';
         DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
         IF (p_customer_id IS NOT NULL AND p_customer_site_id IS NULL) THEN
            lc_burst_flag := 'C';
         ELSIF (p_customer_site_id IS NOT NULL) THEN
            lc_burst_flag := 'S';
         END IF ;
         SUBMIT_SEND_MAIL(p_stmt_date
                        ,lc_burst_flag
                        ,p_send_email
                        ,p_email_id
                        ,p_debug_flag
                        ,lc_status
                        );
         IF (lc_status IS NOT NULL) THEN
            x_retcode := 1;
            lc_request_data := 'COMPLETE';
         END IF;
     ELSE
         lc_request_data := 'COMPLETE';
     END IF;
   END IF;
   IF lc_request_data = 'COMPLETE' OR lc_request_data = 'SENT_MAIL' THEN
       x_retcode := Get_Chid_Status(ln_parent_request_id);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception raised in CUST_STMT_RESEND_MAIN procedure '|| SQLERRM);
      x_retcode := 2;
END CUST_STMT_RESEND_MAIN;

PROCEDURE GENERATE_MAIL_BODY(p_stmt_date  IN VARCHAR2
                            ,p_debug_flag IN VARCHAR2
                            )
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  GENERATE_MAIL_BODY                            |
-- | Description      : This Procedure is used to generate the mailbody|
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |DRAFT 1.0 05-NOV-2009  Vinaykumar S    Initial draft version       |
-- |  1.1     14-DEC-2009  Vinaykumar S   Made changes to the code as  |
-- |                                      Per Subbu's Comments         |
-- |                                      Defect 3261(CR 622)          |
-- |  1.2     09-FEB-2010  Vinaykumar S   Modified the code as         |
-- |                                      Per comments from UATGB      |
-- |                                      Testing Team                 |
-- +===================================================================+
   ---------------------------------
   --   VARIABLE DECLARATION      --
   ---------------------------------
   lc_text_html    VARCHAR2(2000);
   lc_text         VARCHAR2(2000);
   lt_file_html     UTL_FILE.FILE_TYPE;
   lc_directory     VARCHAR2(100) := 'XXFIN_OUTBOUND';
   lc_email_body1  VARCHAR2(2000);
   lc_email_body2  VARCHAR2(2000);
   lc_email_body3  VARCHAR2(2000);
BEGIN
   SELECT text
   INTO lc_text_html
   FROM ar_standard_text_vl
   WHERE name = 'OD_CUST_STATEMENTS_HTML';
   SELECT text
   INTO lc_text
   FROM ar_standard_text_vl
   WHERE name = 'OD_CUST_STATEMENTS';
   SELECT text
   INTO lc_email_body1
   FROM ar_standard_text_vl
   WHERE name = 'OD_CUST_STMT_EMAIL_BODY1';
   SELECT text
   INTO lc_email_body2
   FROM ar_standard_text_vl
   WHERE name = 'OD_CUST_STMT_EMAIL_BODY2';
   SELECT text
   INTO lc_email_body3
   FROM ar_standard_text_vl
   WHERE name = 'OD_CUST_STMT_EMAIL_BODY3';
   gc_html_file       := 'XXARCSHTML';
   gc_html_file_user_p1  := 'XXARCSHTML_USER_P1';
   gc_html_file_user_p2  := 'XXARCSHTML_USER_P2';
   BEGIN
      UTL_FILE.FREMOVE(lc_directory,gc_html_file);
      gc_debug_msg :='Removed file: ' || gc_html_file;
      DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
      UTL_FILE.FREMOVE(lc_directory,gc_html_file_user_p1);
      gc_debug_msg :='Removed file: ' || gc_html_file_user_p1;
      DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
      UTL_FILE.FREMOVE(lc_directory,gc_html_file_user_p2);
      gc_debug_msg :='Removed file: ' || gc_html_file_user_p2;
      DEBUG_MESSAGE(p_debug_flag,gc_debug_msg);
   EXCEPTION
      WHEN OTHERS THEN
      NULL;
   END;
   lt_file_html := UTL_FILE.fopen(lc_directory, gc_html_file,'w');
   UTL_FILE.PUT_LINE(lt_file_html,'<HTML><BODY>'
                        || '<FONT FACE="Arial" SIZE="2" color="#000000">'
                        || lc_email_body1 ||' '||p_stmt_date
                        || lc_email_body2
                        || '</FONT>'
                        || '<h1><b><FONT FACE="Verdana" SIZE="3" color="#228B22">'
                        || lc_text_html
                        || '</b></h1>'
                        || lc_text
                        || '</BODY></HTML>'
                     );
   UTL_FILE.fclose(lt_file_html);
   lt_file_html := UTL_FILE.fopen(lc_directory, gc_html_file_user_p1,'w');
   UTL_FILE.PUT_LINE(lt_file_html,'<HTML><BODY>'
                        || '<PRE><FONT FACE="Arial" SIZE="2" color="#000000">'
                        || lc_email_body3
                        || '</PRE></BODY></HTML>'
                     );
   UTL_FILE.fclose(lt_file_html);
  lt_file_html := UTL_FILE.fopen(lc_directory, gc_html_file_user_p2,'w');
   UTL_FILE.PUT_LINE(lt_file_html,'<HTML><BODY>'
                        || '<FONT FACE="Arial" SIZE="2" color="#000000">'
                        || lc_email_body2
                        || '</FONT>'
                        || '<h1><b><FONT FACE="Verdana" SIZE="3" color="#228B22">'
                        || lc_text_html
                        || '</b></h1>'
                        || lc_text
                        || '</BODY></HTML>'
                     );
   UTL_FILE.fclose(lt_file_html);
   SELECT directory_path
   INTO gc_directory_path
   FROM dba_directories
   WHERE directory_name = 'XXFIN_OUTBOUND';
EXCEPTION
   WHEN OTHERS THEN
     FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception raised while writing into Text file. '|| SQLERRM);
END GENERATE_MAIL_BODY;

PROCEDURE GET_DELIVERY_EMAILID(p_site_use_id       IN       VARCHAR2
                              ,p_customer_flag     IN       VARCHAR2
                              ,p_resend_flag       IN       VARCHAR2
                              ,p_stmt_date         IN       VARCHAR2
                              ,p_org_id            IN       NUMBER
                              ,x_mail_add          OUT      VARCHAR2
                              ,x_cust_acct_no      OUT      VARCHAR2
                              ,x_aops_cust_no      OUT      VARCHAR2
                              ,x_location          OUT      VARCHAR2
                              ,x_bill_sequence     OUT      VARCHAR2
                              ,x_stmt_date         OUT      VARCHAR2
                              )
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  GET_DELIVERY_EMAILID                          |
-- | Description      : This Procedure is used to fetch the Email Ids  |
-- |                    at Customer Header Level and Site Level        |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |DRAFT 1.0 05-NOV-2009  Vinaykumar S    Initial draft version       |
-- |  1.1     14-DEC-2009  Vinaykumar S   Made changes to the code as  |
-- |                                      Per Subbu's Comments         |
-- |                                      Defect 3261(CR 622)          |
-- |  1.2     18-FEB-2010  Vinaykumar S   Made changes to the code to  |
-- |                                      be org Specific              |
-- +===================================================================+
   lc_concat      VARCHAR2(9000);
   CURSOR lcu_email
   IS
     SELECT HCP.email_address  email_address
     FROM   hz_cust_site_uses_all HCSU
           ,hz_cust_acct_sites_all HCAS
           ,hz_cust_account_roles  HCAR
           ,hz_contact_points HCP
     WHERE  HCSU.site_use_id =p_site_use_id
     AND    HCAS.cust_acct_site_id=HCSU.cust_acct_site_id
     AND    HCSU.cust_acct_site_id = HCAR.cust_acct_site_id
     AND    HCP.owner_table_id = HCAR.party_id
     AND    HCP.owner_table_name     = 'HZ_PARTIES'
     AND    HCSU.site_use_code       IN ( 'BILL_TO' ,'SHIP_TO')
     AND    HCAS.status              = 'A'
     AND    HCP.status               = 'A'
     AND    HCP.contact_point_type   = 'EMAIL'
     AND    HCP.contact_point_purpose= 'STATEMENTS'
     AND    HCSU.org_id              = p_org_id
     ORDER BY HCP.email_address;
     email_rec lcu_email%ROWTYPE;
   CURSOR lcu_cust_email
   IS
      SELECT HCP.email_address
      FROM   hz_cust_account_roles  HCAR
            ,hz_contact_points HCP
      WHERE  HCAR.cust_account_id = p_site_use_id
      AND    HCP.owner_table_id = HCAR.party_id
      AND    HCP.owner_table_name = 'HZ_PARTIES'
      AND    HCP.status = 'A'
      AND    HCP.contact_point_type='EMAIL'
      AND    HCP.contact_point_purpose='STATEMENTS'
      AND    HCAR.cust_acct_site_id IS NULL
      ORDER BY HCP.email_address;
   cust_email_rec lcu_cust_email%ROWTYPE;
   BEGIN
      BEGIN
         x_stmt_date := TO_CHAR( TO_DATE(p_stmt_date,'DD-MON-YYYY'),'YYYYMMDD');
         IF p_customer_flag = 'N'  THEN
            SELECT DISTINCT customer_number,location
            INTO   x_cust_acct_no
                  ,x_location
            FROM   xx_ar_cs_docid_store_child
            where  CUSTOMER_SITE_ID = P_SITE_USE_ID;
            select SUBSTR(HCA.ORIG_SYSTEM_REFERENCE,1,8),SUBSTR(HCAS.ORIG_SYSTEM_REFERENCE,10,5)
            INTO   x_aops_cust_no,x_bill_sequence
            FROM hz_cust_accounts   HCA
                ,hz_cust_acct_sites_all HCAS
                ,hz_cust_site_uses_all  HCSU
            WHERE HCSU.site_use_id       =  p_site_use_id
            AND   HCAS.cust_acct_site_id =  HCSU.cust_acct_site_id
            AND   HCAS.cust_account_id   =  HCA.cust_account_id
            AND   HCSU.org_id            = p_org_id;
--            SELECT SUBSTR(HCAS.orig_system_reference,10,5)
--            INTO   x_bill_sequence
--            FROM hz_cust_accounts   HCA
--                ,hz_cust_acct_sites_all HCAS
--                ,hz_cust_site_uses_all  HCSU
--            WHERE HCSU.site_use_id       =  p_site_use_id
--            AND   HCAS.cust_acct_site_id =  HCSU.cust_acct_site_id
--            AND   HCAS.cust_account_id   =  HCA.cust_account_id
--            AND   HCSU.org_id            = p_org_id;
            x_location      := 'Location : '||x_location;
            x_bill_sequence := '_'||x_bill_sequence;
         ELSE
            SELECT DISTINCT customer_number
            INTO x_cust_acct_no
            FROM xx_ar_cs_docid_store_child
            WHERE customer_id = p_site_use_id;
            SELECT SUBSTR(HCA.orig_system_reference,1,8)
            INTO   x_aops_cust_no
            FROM hz_cust_accounts  HCA
            WHERE HCA.cust_account_id = p_site_use_id;
            x_location      := NULL;
            x_bill_sequence := NULL;
         END IF;
      EXCEPTION
         WHEN OTHERS THEN
            x_cust_acct_no  := 'NOT FOUND';
            x_location      := 'NOT FOUND';
            x_aops_cust_no  := 'NOT FOUND';
            x_bill_sequence := 'NOT FOUND';
            FND_FILE.PUT_LINE(FND_FILE.LOG,' Error location :'||x_cust_acct_no );
            FND_FILE.PUT_LINE(FND_FILE.LOG,' Error location :'||x_location);
            FND_FILE.PUT_LINE(FND_FILE.LOG,' Error location :'||x_aops_cust_no);
            FND_FILE.PUT_LINE(FND_FILE.LOG,' Error location :'||x_bill_sequence);
            FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception raised in fetching the customer details in email ID procedure' ||SQLERRM);
      END;
      BEGIN
         IF p_customer_flag = 'N' THEN
            OPEN lcu_email;
               FETCH lcu_email INTO email_rec;
                  IF email_rec.email_address IS NULL
                  THEN
                     x_mail_add := 'No_Email_Addr';
                  ELSE
                     WHILE (lcu_email%FOUND)
                        LOOP
                            x_mail_add := x_mail_add||','||email_rec.email_address;
                            FETCH lcu_email INTO email_rec;
                        END LOOP;
                        x_mail_add := SUBSTR(x_mail_add,2,LENGTH(x_mail_add));
                        UPDATE  xx_ar_cs_docid_store_master
                        SET     cust_site_sent_date = SYSDATE
                               ,customer_site_email_id = x_mail_add
                               ,last_update_date = SYSDATE
                        WHERE   customer_site_id = p_site_use_id;
                        COMMIT;
                        IF p_resend_flag = 'Y' THEN
                           UPDATE xx_ar_cs_docid_store_master
                           SET    resend_stmt_number = NVL(resend_stmt_number,0) + 1
                                 ,last_update_date = SYSDATE
                           WHERE  customer_site_id = p_site_use_id;
                           COMMIT;
                        END IF;
                    END IF;
             CLOSE lcu_email;
         ELSE
            OPEN lcu_cust_email;
               FETCH lcu_cust_email INTO cust_email_rec;
                  IF cust_email_rec.email_address IS NULL
                  THEN
                     x_mail_add := 'No_Email_Addr';
                  ELSE
                     WHILE (lcu_cust_email%FOUND)
                        LOOP
                           x_mail_add := x_mail_add||','||cust_email_rec.email_address;
                           FETCH lcu_cust_email INTO cust_email_rec;
                        END LOOP;
                      x_mail_add := SUBSTR(x_mail_add,2,LENGTH(x_mail_add));
                      UPDATE xx_ar_cs_docid_store_master
                      SET  customer_sent_date = SYSDATE
                          ,customer_email_id = x_mail_add
                          ,last_update_date = SYSDATE
                      WHERE customer_id = p_site_use_id;
                      COMMIT;
                      IF p_resend_flag = 'Y' THEN
                          UPDATE xx_ar_cs_docid_store_master
                          SET  resend_stmt_number = NVL(resend_stmt_number,0) + 1
                               ,last_update_date = SYSDATE
                          WHERE customer_id = p_site_use_id;
                          COMMIT;
                      END IF;
                   END IF;
             CLOSE lcu_cust_email;
                END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
            x_mail_add := 'No_Email_Addr';
         WHEN OTHERS THEN
            x_mail_add := 'Email_Addr_Err';
            DBMS_OUTPUT.PUT_LINE(SQLERRM);
         END;
         lc_concat := '~'||x_mail_add||'~'||x_cust_acct_no||'~'||x_aops_cust_no||'~'||x_location||'~'||x_bill_sequence||'~'||x_stmt_date||'~';
           CUSTOM_OUTPUT(REPLACE(lc_concat,' ','^'));
END GET_DELIVERY_EMAILID;

PROCEDURE DEBUG_MESSAGE(p_debug_flag       IN       VARCHAR2
                       ,p_debug_msg        IN       VARCHAR2
                       )
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  DEBUG_MESSAGE                                 |
-- | Description      : This Procedure is used to print the debug      |
-- |                    messages wherever required                     |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- | 1.1     14-Dec-2009  Vinaykumar S     Added for Defect 3261 as    |
-- |                                       per subbu's comments        |
-- |                                      Defect 3261(CR 622)          |
-- +===================================================================+
BEGIN
   IF (NVL(p_debug_flag,'N') = 'Y') THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,' '||p_debug_msg);
   END IF;
END DEBUG_MESSAGE;

PROCEDURE CUSTOM_OUTPUT(p_string IN VARCHAR2 )
IS
 -- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  DEBUG_MESSAGE                                 |
-- | Description      : This Procedure is used to print dbms outputs   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- | 1.1     19-FEB-2010  Ranjith Thangasamy Added for Defect 4519     |
-- +===================================================================+
   lc_string_in LONG DEFAULT p_string;
   ln_len number;
   ln_count number DEFAULT 0;
   ln_string_length NUMBER DEFAULT 255;
BEGIN
 ln_len := LENGTH(lc_string_in);
    WHILE ln_count < ln_len
   LOOP
      dbms_output.put_line( substr( lc_string_in, ln_count +1, ln_string_length  ) );
      ln_count := ln_count +ln_string_length ;
   END LOOP;
END;

FUNCTION Get_Chid_Status (p_par_req_id NUMBER)
        RETURN NUMBER
  IS
   -- +===================================================================+
-- |                  Office Depot - Project Simplify                     |
-- |                          Wipro-Office Depot                          |
-- +=======================================================================+
-- | Name             :  Get_Chid_Status                                  |
-- | Description      : This function is get the Status Of the            |
-- |                    Child Requests                                    |
-- |Change Record:                                                        |
-- |===============                                                       |
-- |Version   Date         Author           Remarks                       |
-- |=======   ==========   =============    ======================        |
-- | 1.0     11-Jun-2010  Bhuvi             Performance Changes           |
-- +======================================================================+
   ln_cnt_err_request  NUMBER;
   ln_cnt_war_request  NUMBER;
   ln_ret_code         NUMBER;
 BEGIN
      ln_ret_code := 0;
      SELECT count(*)
      INTO ln_cnt_err_request
      FROM fnd_concurrent_requests
      WHERE parent_request_id = p_par_req_id
      AND phase_code = 'C'
      AND status_code = 'E';
      SELECT count(*)
      INTO ln_cnt_war_request
      FROM fnd_concurrent_requests
      WHERE parent_request_id = p_par_req_id
      AND phase_code = 'C'
      AND status_code = 'G';
      IF ln_cnt_war_request <> 0 THEN
         gc_debug_msg := ln_cnt_err_request ||' Child Requests has ended in Warning.Please, Check the Child Requests LOG for Details';
         DEBUG_MESSAGE('Y',gc_debug_msg);
         ln_ret_code := 1;
      END IF;
      IF ln_cnt_err_request <> 0 THEN
         gc_debug_msg := ln_cnt_err_request ||' Child Requests Errored Out.Please, Check the Child Requests LOG for Details';
         DEBUG_MESSAGE('Y',gc_debug_msg);
         ln_ret_code := 2;
      END IF;
     RETURN ln_ret_code;
  END Get_Chid_Status;
END XX_AR_CUST_STMTXL_WRAP_PKG;
/