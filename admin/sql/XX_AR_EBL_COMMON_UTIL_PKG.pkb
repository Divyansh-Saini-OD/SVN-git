create or replace PACKAGE BODY      XX_AR_EBL_COMMON_UTIL_PKG
 AS
   gc_put_log               VARCHAR2(4000);
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : XX_AR_EBL_COMMON_UTIL                                               |
-- | Description : This Package will contain all the common functions and utilities    |
-- |               used by the eBilling application                                    |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 10-MAR-2010  Ranjith Prabu           Initial draft version               |
-- |1.1       12-MAR-2013  Rajeshkumar M R         Moved department description        |
-- |                                               to header Defect# 15118             |
-- |1.2       04-NOV-2013  Arun Gannarapu          Made changes to fix the bill_From_date|
-- |                                                with R12 changes                   |
-- |1.3       20-NOV-2013  Arun Gannarapu          Made changes to fix the CA tax issue|
-- |                                               Defect # 26548                      |
-- |1.4       19-DEC-2013  Arun Gannarapu          Made changes to fix the bill from date|
-- |                                                issue defect # 27239               |
-- |1.5       17-FEB-2014  Arun Gannarapu          Made changes to fix the CA tax issue|
-- |                                              for migrated transactions  # 26781   |
-- |1.6       17-Aug-2015  Suresh Naragam          Added bill to location column       |
-- |                                              (Module 4B Release 2)                |
-- |1.7       15-Oct-2015  Suresh Naragam          Removed Schema References           |
-- |                                               (R12.2 Global standards)            |
-- |1.8       04-DEC-2015  Havish Kasina          Added new Function GET_HEADER_DISCOUNT|
-- |                                              (Module 4B Release 3)                |
-- |1.2       08-DEC-2015  Havish Kasina          Added new column dept_code in        |
-- |                                              xx_ar_ebl_cons_dtl_hist,             |
-- |                                              xx_ar_ebl_cons_hdr_hist,             |
-- |                                              xx_ar_ebl_ind_dtl_hist and           |
-- |                                              xx_ar_ebl_ind_hdr_hist tables        |
-- |                                              -- Defect 36437                      |
-- |                                              (MOD 4B Release 3)                   |
-- |2.0		  24-MAY-2016  Rohit Gupta			  Changed the logic for 			   |
-- |											  GET_HEADER_DISCOUNT for defect #37807|
-- |2.1       23-JUN-2016  Havish Kasina          Added a new procedure                 |
-- |                                              GET_KIT_EXTENDED_AMOUNT to get the    |
-- |                                              KIT extended amount and KIT Unit Price|
-- |                                              (Defect 37670 for Kitting)            |
-- |2.2       23-JUN-2016  Havish Kasina          Added new column kit_sku in           |
-- |                                              xx_ar_ebl_cons_dtl_hist,              |
-- |                                              xx_ar_ebl_ind_dtl_hist                |
-- |                                              Defect 37675 (Kitting Changes)        |
-- |2.3       22-FEB-2018  Yashwanth SC           Added order by in get_email_details   |
-- |                                                   (Defect#44275 )                  |
-- |2.4       23-MAR-2018   Aniket J CG           Defect 22772  (Combo Type Changes)    |
-- |2.5       12-SEP-2018   Aarthi                NAIT - 58403  Added SKU level columns |
-- |                                              to the history tables                 |
-- |2.6       23-OCT-2018   SravanKumar           NAIT- 65564: Added new function to    |
-- |                                              display custom message for bill       |
-- |                                              complete customer for delivery        |
-- |                                              method ePDF and ePRINT.               |
-- |2.7       14-NOV-2018   P Jadhav              NAIT- 65564: updated GET_CONS_MSG_BCC |
-- |                                              display  message for bill complete    |
-- |                                              customer and Paydoc method only  	    |
-- |2.8       06-DEC-2018	P Jadhav 			  NAIT-74893: updated GET_CONS_MSG_BCC  |
-- |											  changed custom message		        |
-- |2.9       11-MAR-2019	Aarthi                NAIT- 80452: Adding POD related blurb |
-- |                                              messages to individual reprint reports|
-- |3.0       27-MAY-2020   Divyansh              Added new functions for Tariff Changes|
-- |                                              JIRA NAIT-129167                      |
-- +===================================================================================+
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : PUT_LOG_LINE                                                        |
-- | Description : This Procedure is used to print the log lines based on the debug    |
-- |               and the p_force flag                                                |
-- |Parameters   :  p_debug                                                            |
-- |               ,p_force                                                            |
-- |               ,p_buffer                                                           |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 10-MAR-2010  Ranjith Prabu           Initial draft version               |
-- +===================================================================================+
    PROCEDURE PUT_LOG_LINE( p_debug  IN BOOLEAN
                           ,p_force  IN BOOLEAN
                           ,p_buffer IN VARCHAR2 DEFAULT ' '
                           )
    IS
    BEGIN
      -- if debug is TRUE
      IF ( p_debug OR p_force ) THEN
         -- if in concurrent program, print to log file
         IF (FND_GLOBAL.CONC_REQUEST_ID > 0) THEN
            FND_FILE.put_line(FND_FILE.LOG,NVL(p_buffer,' '));
         -- else print to DBMS_OUTPUT
         ELSE
            DBMS_OUTPUT.put_line(SUBSTR(NVL(p_buffer,' '),1,255));
         END IF;
      END IF;
    END put_log_line;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : MULTI_THREAD                                                        |
-- | Description : This Procedure is used to divide the total population of eXLS       |
-- |               or eTXT or eXLS (Individual) customers to be processed              |
-- |               by the associated child process.                                    |
-- |Parameters   : p_debug_flag                                                        |
-- |              ,p_batch_size                                                        |
-- |              ,p_del_mthd                                                          |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                  Remarks                            |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 10-Jun-2010  Parameswaran SN         Initial draft version for CR 586 -  |
-- |                                               Defect 2811                         |
-- +===================================================================================+
   PROCEDURE MULTI_THREAD( p_batch_size    IN NUMBER
                          ,p_thread_count  IN NUMBER
                          ,p_debug_flag    IN VARCHAR2
                          ,p_del_mthd      IN VARCHAR2
                          ,p_request_id    IN NUMBER
                          ,p_doc_type      IN VARCHAR2
                          ,p_status        IN VARCHAR2
                          ,p_cycle_date    IN VARCHAR2
                          )
    AS

       ln_batch_count            NUMBER := 0;
       ln_batch_id               NUMBER := 0;
       lb_debug                  BOOLEAN;
       ln_custdoc_count          NUMBER := 0;
       ln_org_id                 NUMBER := fnd_profile.value('ORG_ID');
       ln_count                  NUMBER;
       ln_batch_size             NUMBER;
       ld_cycle_date             DATE;

       CURSOR lcu_batch_ind_bills(p_cycle_date IN DATE)
       IS
       SELECT DISTINCT XAEIHM.parent_cust_doc_id parent_cust_doc_id
                      ,XAEIHM.extract_batch_id   extract_batch_id
       FROM   xx_ar_ebl_ind_hdr_main XAEIHM
             ,xx_ar_ebl_file         XAEF
       WHERE  XAEIHM.billdocs_delivery_method = p_del_mthd
       AND    XAEIHM.org_id                   = ln_org_id
       AND    XAEF.file_id                    = XAEIHM.file_id
       AND    XAEF.status                     = p_status
       AND    XAEIHM.bill_to_date             <= p_cycle_date;

       CURSOR lcu_batch_cons_bills(p_cycle_date IN DATE)
       IS
       SELECT DISTINCT XAECHM.parent_cust_doc_id parent_cust_doc_id
                      ,XAECHM.extract_batch_id   extract_batch_id
       FROM   xx_ar_ebl_cons_hdr_main XAECHM
             ,xx_ar_ebl_file          XAEF
       WHERE  XAECHM.billdocs_delivery_method = p_del_mthd
       AND    XAECHM.org_id                   = ln_org_id
       AND    XAEF.file_id                    = XAECHM.file_id
       AND    XAEF.status                     = p_status
       AND    XAECHM.bill_to_date             <= p_cycle_date;

       TYPE ltab_ind_ref_type IS TABLE OF lcu_batch_ind_bills%ROWTYPE INDEX BY BINARY_INTEGER;
       ltab_ind_ref                     ltab_ind_ref_type;
       TYPE ltab_cons_ref_type IS TABLE OF lcu_batch_cons_bills%ROWTYPE INDEX BY BINARY_INTEGER;
       ltab_cons_ref                     ltab_cons_ref_type;

    BEGIN

       IF p_debug_flag = 'Y' THEN
          lb_debug := TRUE;
       ELSE
          lb_debug := FALSE;
       END IF;

       ld_cycle_date          := FND_CONC_DATE.STRING_TO_DATE(p_cycle_date);
       XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug
                                              ,TRUE
                                              ,'Cycle Date : '||TO_CHAR(ld_cycle_date,'DD_MON_YYYY HH24:MI:SS')
                                              );

       IF( p_doc_type = 'IND') THEN

          IF (p_thread_count IS NOT NULL) THEN

             gc_put_log   := 'Get the Distinct count of valid parent cust doc id';
             SELECT COUNT(1)
             INTO   ln_count
             FROM   (SELECT DISTINCT XAEIHM.parent_cust_doc_id
                                    ,XAEIHM.extract_batch_id
                     FROM   xx_ar_ebl_ind_hdr_main XAEIHM
                           ,xx_ar_ebl_file         XAEF
                     WHERE  XAEIHM.billdocs_delivery_method = p_del_mthd
                     AND    XAEIHM.org_id                   = ln_org_id
                     AND    XAEF.file_id                    = XAEIHM.file_id
                     AND    XAEF.status                     = p_status
                     AND    XAEIHM.bill_to_date             <= ld_cycle_date
                     );

             gc_put_log   := 'Calculate the batch size based on the thread count.';
             IF (ln_count <> 0) THEN
                ln_batch_size := CEIL(ln_count/p_thread_count);
             ELSE
                ln_batch_size := -1;
                PUT_LOG_LINE( lb_debug
                             ,TRUE
                             ,'No records to process '||p_del_mthd||' delivery method.'
                             );
             END IF;
          ELSE
             ln_batch_size := NVL(p_batch_size,1000);
          END IF;

          IF (ln_batch_size <> -1) THEN
             PUT_LOG_LINE( lb_debug
                          ,TRUE
                          ,'Delivery Method '||p_del_mthd||' has records to process.'
                          );
             OPEN lcu_batch_ind_bills(ld_cycle_date);
                LOOP
                   gc_put_log   := 'Bulk collect data based on the batch size.';
                   FETCH lcu_batch_ind_bills BULK COLLECT INTO ltab_ind_ref LIMIT NVL(ln_batch_size,1000);
                      EXIT WHEN ltab_ind_ref.COUNT = 0;
                         ln_batch_count   := ln_batch_count + 1;
                         ln_batch_id      := p_request_id || '.' || LPAD (ln_batch_count, 5, '0');

                         FOR i IN ltab_ind_ref.FIRST..ltab_ind_ref.LAST
                         LOOP

                             gc_put_log   := 'Validate Parent cust doc id for further processing.';
                             SELECT COUNT(1)
                             INTO   ln_custdoc_count
                             FROM   xx_ar_ebl_ind_hdr_main XAEIHM
                                   ,xx_ar_ebl_file         XAEF
                             WHERE  XAEIHM.billdocs_delivery_method   = p_del_mthd
                             AND    XAEIHM.org_id                     = ln_org_id
                             AND    XAEIHM.file_id                    = XAEF.file_id(+)
                             AND    UPPER( NVL(XAEF.status,'XXX'))   != p_status
                             AND    XAEIHM.parent_cust_doc_id         = ltab_ind_ref(i).parent_cust_doc_id
                             AND    XAEIHM.extract_batch_id           = ltab_ind_ref(i).extract_batch_id;

                             gc_put_log   := 'Updated batch id depending on the above validation.';
                             IF(ln_custdoc_count = 0) THEN
                                UPDATE xx_ar_ebl_ind_hdr_main
                                SET    batch_id                   = ln_batch_id
                                      ,status                     = 'MARKED_FOR_RENDER'
                                WHERE  parent_cust_doc_id         = ltab_ind_ref(i).parent_cust_doc_id
                                AND    extract_batch_id           = ltab_ind_ref(i).extract_batch_id
                                AND    billdocs_delivery_method   = p_del_mthd
                                AND    org_id                     = ln_org_id;
                             END IF;

                         END LOOP;
                END LOOP;
             CLOSE lcu_batch_ind_bills;
          END IF;
       END IF;

       IF( p_doc_type = 'CONS') THEN
          IF (p_thread_count IS NOT NULL) THEN

             gc_put_log   := 'Get the Distinct count of valid parent cust doc id';
             SELECT COUNT(1)
             INTO   ln_count
             FROM   (SELECT DISTINCT XAECHM.parent_cust_doc_id
                                    ,XAECHM.extract_batch_id
                     FROM   xx_ar_ebl_cons_hdr_main XAECHM
                           ,xx_ar_ebl_file          XAEF
                     WHERE  XAECHM.billdocs_delivery_method = p_del_mthd
                     AND    XAECHM.org_id                   = ln_org_id
                     AND    XAEF.file_id                    = XAECHM.file_id
                     AND    XAEF.status                     = p_status
                     AND    XAECHM.bill_to_date             <= ld_cycle_date
                     );

             gc_put_log   := 'Calculate the batch size based on the thread count.';
             IF (ln_count <> 0) THEN
                ln_batch_size := CEIL(ln_count/p_thread_count);
             ELSE
                ln_batch_size := -1;
                PUT_LOG_LINE( lb_debug
                             ,TRUE
                             ,'No records to process '||p_del_mthd||' delivery method.'
                             );
             END IF;
          ELSE
             ln_batch_size := NVL(p_batch_size,1000);
          END IF;

          IF (ln_batch_size <> -1) THEN
             PUT_LOG_LINE( lb_debug
                          ,TRUE
                          ,'Delivery Method '||p_del_mthd||' has records to process.'
                          );
             OPEN lcu_batch_cons_bills(ld_cycle_date);
                LOOP
                   gc_put_log   := 'Bulk collect data based on the batch size.';
                   FETCH lcu_batch_cons_bills BULK COLLECT INTO ltab_cons_ref LIMIT NVL(ln_batch_size,1000);
                      EXIT WHEN ltab_cons_ref.COUNT = 0;

                         ln_batch_count   := ln_batch_count + 1;
                         ln_batch_id      := p_request_id || '.' || LPAD (ln_batch_count, 5, '0');

                         FOR i IN ltab_cons_ref.FIRST..ltab_cons_ref.LAST
                         LOOP

                             gc_put_log   := 'Validate Parent cust doc id for further processing.';
                             SELECT COUNT(*)
                             INTO ln_custdoc_count
                             FROM   xx_ar_ebl_ind_hdr_main XAEIHM
                                   ,xx_ar_ebl_file XAEF
                             WHERE  XAEIHM.billdocs_delivery_method   = p_del_mthd
                             AND    XAEIHM.org_id                     = ln_org_id
                             AND    XAEIHM.file_id                    = XAEF.file_id(+)
                             AND    UPPER( NVL(XAEF.status,'XXX'))   != p_status
                             AND    XAEIHM.parent_cust_doc_id         = ltab_cons_ref(i).parent_cust_doc_id
                             AND    XAEIHM.extract_batch_id           = ltab_cons_ref(i).extract_batch_id;

                             gc_put_log   := 'Updated batch id depending on the above validation.';
                             IF(ln_custdoc_count = 0) THEN
                                UPDATE xx_ar_ebl_cons_hdr_main
                                SET    batch_id                   = ln_batch_id
                                      ,status                     = 'MARKED_FOR_RENDER'
                                WHERE  parent_cust_doc_id         = ltab_cons_ref(i).parent_cust_doc_id
                                AND    extract_batch_id           = ltab_cons_ref(i).extract_batch_id
                                AND    billdocs_delivery_method   = p_del_mthd
                                AND    org_id                     = ln_org_id;
                             END IF;

                         END LOOP;
                END LOOP;

             CLOSE lcu_batch_cons_bills;

          END IF;
       END IF;

       COMMIT;
       gc_put_log := 'Multi Thread Parameters ==>' || CHR(13)                   ||
                     'Batch_ID : '                 || ln_batch_size  || CHR(13) ||
                     'Delivery method : '          || p_del_mthd     || CHR(13) ||
                     'Request ID : '               || p_request_id   || CHR(13) ||
                     'Total No of Batches : '      || ln_batch_count || CHR(13) ||
                     'Multi Thread Batching process Complete. ';
       PUT_LOG_LINE( lb_debug
                    ,FALSE
                    ,gc_put_log
                    );

    EXCEPTION
    WHEN OTHERS THEN
       gc_put_log := ' Exception raised in MULTI_THREAD Procedure '|| SQLERRM;

       PUT_LOG_LINE( lb_debug
                    ,TRUE
                    ,gc_put_log
                    );
    END MULTI_THREAD;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : GET_AMOUNT                                                          |
-- | Description : This procedure is used to get the following amounts of the          |
-- |               transation.                                                         |
-- |               1. Total Amount                                                     |
-- |               2. SKU lines Amount                                                 |
-- |               3. Delivery/Miscellaneous Amount                                    |
-- |               4. Disocunt Amount(Association, Bulk, Coupon, Tiered)               |
-- |               5. Gift Card Amount                                                 |
-- |                                                                                   |
-- |Parameters   : p_inv_source                                                        |
-- |              ,p_trx_id                                                            |
-- |              ,p_trx_type                                                          |
-- |              ,p_header_id                                                         |
-- |              ,x_sku_line_amt                                                      |
-- |              ,x_delivery_amt                                                      |
-- |              ,x_misc_amt                                                          |
-- |              ,x_assoc_disc_amt                                                    |
-- |              ,x_bulk_disc_amt                                                     |
-- |              ,x_coupon_disc_amt                                                   |
-- |              ,x_tiered_disc_amt                                                   |
-- |              ,x_gift_card_amt                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 11-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE GET_AMOUNT ( p_inv_source       IN   VARCHAR2
                          ,p_trx_id           IN   NUMBER
                          ,p_trx_type         IN   VARCHAR2
                          ,p_header_id        IN   NUMBER
                          ,x_trx_amt          OUT  NUMBER
                          ,x_sku_line_amt     OUT  NUMBER
                          ,x_delivery_amt     OUT  NUMBER
                          ,x_misc_amt         OUT  NUMBER
                          ,x_assoc_disc_amt   OUT  NUMBER
                          ,x_bulk_disc_amt    OUT  NUMBER
                          ,x_coupon_disc_amt  OUT  NUMBER
                          ,x_tiered_disc_amt  OUT  NUMBER
                          ,x_gift_card_amt    OUT  NUMBER
                          ,x_line_count       OUT NUMBER
                          )
    AS
       ln_trx_amt           NUMBER := 0;
       ln_sku_line_amt      NUMBER := 0;
       ln_delivery_amt      NUMBER := 0;
       ln_misc_amt          NUMBER := 0;
       ln_assoc_disc_amt    NUMBER := 0;
       ln_bulk_disc_amt     NUMBER := 0;
       ln_coupon_disc_amt   NUMBER := 0;
       ln_tiered_disc_amt   NUMBER := 0;
       ln_gift_card_amt     NUMBER := 0;
       lc_put_log           VARCHAR2(1000);
       ln_line_count        NUMBER  :=0;
       ln_line_amt          NUMBER  :=0;
       ln_tax_amount        NUMBER  :=0;
    BEGIN

       BEGIN
          SELECT NVL(SUM(DECODE(line_type,'LINE',RCTL.extended_amount,0)),0)
                ,NVL(SUM(DECODE(line_type,'TAX',RCTL.extended_amount,0)),0)
          INTO   ln_line_amt
                ,ln_tax_amount
          FROM   ra_customer_trx_lines_all  RCTL
          WHERE  RCTL.customer_trx_id = p_trx_id;
          ln_trx_amt := ln_line_amt+ln_tax_amount;
       EXCEPTION
          WHEN OTHERS THEN
             lc_put_log     := 'Get the total amount of the transaction ID : ' ||p_trx_id
                               || CHR(10) || 'SQL Error Message : '|| SQLERRM
                               || CHR(10);
             ln_trx_amt     := 0;
       END;

       BEGIN
          SELECT NVL(SUM(RCTL.extended_amount),0),count(1)
          INTO   ln_sku_line_amt
                 ,ln_line_count
          FROM   ra_customer_trx_lines_all RCTL
                ,(
                  SELECT DISTINCT TO_NUMBER (attribute6) item_id
                  FROM   fnd_lookup_values
                  WHERE  lookup_type   = 'OD_FEES_ITEMS'
                  AND    attribute7    ='DELIVERY'
                  AND    LANGUAGE      = USERENV ('LANG')
                  )                         OD_FEES_ITEM
          WHERE  RCTL.customer_trx_id            = p_trx_id
          AND    RCTL.line_type                  = 'LINE'
          AND    RCTL.interface_line_attribute11 = 0
          AND    RCTL.inventory_item_id          <> item_id ;
       EXCEPTION
          WHEN OTHERS THEN
             lc_put_log           := 'Get the SKU Lines amount of the transaction ID : ' ||p_trx_id
                                     || CHR(10) || 'SQL Error Message : '|| SQLERRM
                                     || CHR(10);
             ln_sku_line_amt     := 0;
       END;

       BEGIN
          SELECT NVL(SUM(RCTL.extended_amount),0)
          INTO   ln_delivery_amt
          FROM   ra_customer_trx_lines_all     RCTL
                ,(
                  SELECT DISTINCT TO_NUMBER (attribute6) item_id
                                 ,attribute7             charge_type
                  FROM   fnd_lookup_values
                  WHERE  lookup_type   = 'OD_FEES_ITEMS'
                  AND    attribute7   ='DELIVERY'
                  AND    LANGUAGE      = USERENV ('LANG')
                  )                         OD_FEES_ITEM
          WHERE RCTL.customer_trx_id        = p_trx_id
          AND   RCTL.line_type              != 'TAX'
          AND   RCTL.inventory_item_id      = OD_FEES_ITEM.item_id;
       EXCEPTION
          WHEN OTHERS THEN
             lc_put_log           := 'Get the Delivery and Miscellaneous amount of the transaction ID : ' ||p_trx_id
                                     || CHR(10) || 'SQL Error Message : '|| SQLERRM
                                     || CHR(10);
             ln_delivery_amt     := 0;
             ln_misc_amt         := 0;
       END;

       BEGIN
          SELECT NVL(SUM (RCTL.extended_amount),0)
          INTO   ln_assoc_disc_amt
          FROM   ra_customer_trx_lines_all RCTL
                ,oe_price_adjustments  OPA
          WHERE  p_inv_source                                IN ('SALES_ACCT_US', 'SALES_ACCT_CA')
          AND    RCTL.customer_trx_id                         = p_trx_id
          AND    RCTL.line_type                               != 'TAX'
          AND    TO_NUMBER (RCTL.interface_line_attribute11)  =  OPA.price_adjustment_id
          AND    OPA.attribute8                               = 'AD';
       EXCEPTION
          WHEN OTHERS THEN
             lc_put_log           := 'Get the Association Disount amount of the transaction ID : ' ||p_trx_id
                                     || CHR(10) || 'SQL Error Message : '|| SQLERRM
                                     || CHR(10);
             ln_assoc_disc_amt    := 0;
       END;

       BEGIN
          SELECT NVL(SUM (RCTL.extended_amount),0)
          INTO   ln_bulk_disc_amt
          FROM   ra_customer_trx_lines_all RCTL
                ,oe_price_adjustments  OPA
          WHERE   p_inv_source                                IN ('SALES_ACCT_US', 'SALES_ACCT_CA')
          AND    RCTL.customer_trx_id                         = p_trx_id
          AND    RCTL.line_type                               != 'TAX'
          AND    TO_NUMBER (RCTL.interface_line_attribute11)  =  OPA.price_adjustment_id
          AND    OPA.attribute8                               = '21';
       EXCEPTION
          WHEN OTHERS THEN
             lc_put_log           := 'Get the Bulk Disount amount of the transaction ID : ' ||p_trx_id
                                     || CHR(10) || 'SQL Error Message : '|| SQLERRM
                                     || CHR(10);
             ln_bulk_disc_amt     := 0;
       END;

       BEGIN
          SELECT NVL(SUM(RCTL.extended_amount),0)
          INTO   ln_coupon_disc_amt
          FROM   ra_customer_trx_lines_all RCTL
                ,oe_price_adjustments  OPA
          WHERE    p_inv_source                                IN ('SALES_ACCT_US', 'SALES_ACCT_CA')
          AND    RCTL.customer_trx_id                         = p_trx_id
          AND    RCTL.line_type                               != 'TAX'
          AND    TO_NUMBER (RCTL.interface_line_attribute11)  =  OPA.price_adjustment_id
          AND    OPA.attribute8                               = '10';
       EXCEPTION
          WHEN OTHERS THEN
             lc_put_log           := 'Get the Coupon Disount amount of the transaction ID : ' ||p_trx_id
                                     || CHR(10) || 'SQL Error Message : '|| SQLERRM
                                     || CHR(10);
             ln_coupon_disc_amt   := 0;
       END;

       BEGIN
         SELECT  NVL(SUM(RCTL.extended_amount),0) amount
          INTO    ln_tiered_disc_amt
          FROM    ra_customer_trx_lines_all RCTL
                 ,oe_price_adjustments  OPA
          WHERE     p_inv_source                                IN ('SALES_ACCT_US', 'SALES_ACCT_CA')
          AND    RCTL.customer_trx_id                         = p_trx_id
          AND    RCTL.line_type                               != 'TAX'
          AND    TO_NUMBER (RCTL.interface_line_attribute11)  =  OPA.price_adjustment_id
          AND    OPA.attribute8                               = 'TD';
       EXCEPTION
          WHEN OTHERS THEN
             lc_put_log           := 'Get the Tiered Disount amount of the transaction ID : ' ||p_trx_id
                                     || CHR(10) || 'SQL Error Message : '|| SQLERRM
                                     || CHR(10);
             ln_tiered_disc_amt   := 0;
       END;

       BEGIN
          IF (p_trx_type = 'INV') THEN
             SELECT NVL(SUM(OP.payment_amount),0)
             INTO   ln_gift_card_amt
             FROM   oe_payments    OP
             WHERE  OP.header_id        = p_header_id;
          ELSIF (p_trx_type = 'CM') THEN
             SELECT NVL(SUM(ORT.credit_amount)*-1,0)
             INTO   ln_gift_card_amt
             FROM   xx_om_return_tenders_all ORT
             WHERE  ORT.header_id       = p_header_id;
         END IF;
       EXCEPTION
          WHEN OTHERS THEN
             lc_put_log           := 'Get the Gift Card amount of the transaction ID : ' ||p_trx_id
                                     || CHR(10) || 'SQL Error Message : '|| SQLERRM
                                     || CHR(10);
             ln_gift_card_amt     := 0;
       END;

       ln_misc_amt      := ln_line_amt - ( ln_assoc_disc_amt
                                          +ln_bulk_disc_amt
                                          +ln_coupon_disc_amt
                                          +ln_tiered_disc_amt
                                          +ln_delivery_amt
                                          +ln_sku_line_amt
                                          );

       x_trx_amt         := ln_trx_amt;
       x_sku_line_amt    := ln_sku_line_amt;
       x_delivery_amt    := ln_delivery_amt;
       x_misc_amt        := ln_misc_amt;
       x_assoc_disc_amt  := ln_assoc_disc_amt;
       x_bulk_disc_amt   := ln_bulk_disc_amt;
       x_coupon_disc_amt := ln_coupon_disc_amt;
       x_tiered_disc_amt := ln_tiered_disc_amt;
       x_gift_card_amt   := ln_gift_card_amt;
       x_line_count      := ln_line_count;

    END GET_AMOUNT;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : GET_TAX_AMOUNT                                                      |
-- | Description : This procedure is used to get the tax amount and tax rate for the   |
-- |               transaction.                                                        |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 11-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- |1.1       20-NOV-2013  Arun Gannarapu          Made changes to fix CA Issue for R12|
-- |                                               defect # 26548
-- |1.2       17-FEB-2014  Arun Gannarapu          Made changes to fix the CA tax issu |
-- |                                              for migrated transactions  # 26781    |
-- +===================================================================================+
    PROCEDURE GET_TAX_AMOUNT ( p_trx_id          IN     NUMBER
                              ,p_country         IN     VARCHAR2
                              ,p_province        IN     VARCHAR2
                              ,x_us_tax_amount   OUT    NUMBER
                              ,x_us_tax_rate     OUT    NUMBER
                              ,x_gst_tax_amount  OUT    NUMBER
                              ,x_gst_tax_rate    OUT    NUMBER
                              ,x_pst_tax_amount  OUT    NUMBER
                              ,x_pst_tax_rate    OUT    NUMBER
                              )
    AS
       ln_us_tax_amt           NUMBER := 0;
       ln_us_tax_rate          NUMBER := 0;
       ln_gst_tax_amt          NUMBER := 0;
       ln_pst_qst_tax_amt      NUMBER := 0;
       ln_gst_tax_rate         NUMBER := 0;
       ln_pst_qst_tax_rate     NUMBER := 0;

    BEGIN

       IF p_country = 'US' THEN
          SELECT NVL(SUM(RCTL.extended_amount),0)
                ,NVL(SUM (SUBSTR(RCTL.tax_rate,1,8)), 0) / 100
          INTO   ln_us_tax_amt
                ,ln_us_tax_rate
          FROM  ra_customer_trx_lines_all RCTL
          WHERE RCTL.customer_trx_id = p_trx_id
          AND   RCTL.line_type       = 'TAX';
       ELSE
         SELECT  NVL(SUM(DECODE(vat.tax_rate_code,'COUNTY',NVL(SUM (aitsv.extended_amount),0),0)),0) ln_pst_qst_tax_amt
                ,NVL(SUM(DECODE(vat.tax_rate_code,'COUNTY',NVL((SUM(vat.percentage_rate) ),0),0)),0) ln_pst_qst_tax_rate
                ,NVL(SUM(DECODE(vat.tax_rate_code,'STATE',NVL(SUM (aitsv.extended_amount),0),0)),0) ln_gst_tax_amt
                ,NVL(SUM(DECODE(vat.tax_rate_code,'STATE',NVL((SUM (vat.percentage_rate) ),0),0)),0) ln_gst_tax_rate
         INTO ln_pst_qst_tax_amt,ln_pst_qst_tax_rate
              ,ln_gst_tax_amt,ln_gst_tax_rate
           FROM ra_customer_trx_lines_all aitsv, zx_rates_b vat --ar_vat_tax_vl vat
          WHERE 1 = 1
            AND aitsv.customer_trx_id = p_trx_id
            AND aitsv.line_type = 'TAX'
            AND vat.tax_rate_id(+) = aitsv.vat_tax_id
            AND aitsv.extended_amount <> 0
            group by tax_rate_code;

      END IF;
      x_us_tax_amount  := ln_us_tax_amt;
      x_us_tax_rate    := ln_us_tax_rate;
      x_gst_tax_amount := ln_gst_tax_amt;
      x_gst_tax_rate   := ln_gst_tax_rate;
      x_pst_tax_amount := ln_pst_qst_tax_amt;
      x_pst_tax_rate   := ln_pst_qst_tax_rate;
    EXCEPTION
    WHEN OTHERS THEN
       x_us_tax_amount   := 0;
       x_us_tax_rate     := 0;
       x_gst_tax_amount  := 0;
       x_gst_tax_rate    := 0;
       x_pst_tax_amount   := 0;
       x_pst_tax_rate     := 0;
    END GET_TAX_AMOUNT;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : GET_REMIT_ADDRESS                                                   |
-- | Description : This procedure is used to get the remit to address.                 |
-- |               transaction.                                                        |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 11-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE GET_REMIT_ADDRESS ( p_remit_control_id    IN   NUMBER
                                 ,x_remit_addr1    OUT  VARCHAR2
                                 ,x_remit_addr2    OUT  VARCHAR2
                                 ,x_remit_addr3    OUT  VARCHAR2
                                 ,x_remit_addr4    OUT  VARCHAR2
                                 ,x_remit_city     OUT  VARCHAR2
                                 ,x_remit_state    OUT  VARCHAR2
                                 ,x_remit_zip      OUT  VARCHAR2
                                 ,x_remit_desc     OUT  VARCHAR2
                                 ,x_remit_country  OUT VARCHAR2
                                 )
    AS
       lc_address1       VARCHAR2(40)   := NULL;
       lc_address2       VARCHAR2(40)   := NULL;
       lc_address3       VARCHAR2(40)   := NULL;
       lc_address4       VARCHAR2(40)   := NULL;
       lc_city           VARCHAR2(40)   := NULL;
       lc_state          VARCHAR2(40)   := NULL;
       lc_postal_code    VARCHAR2(40)   := NULL;
       lc_province       VARCHAR2(40)   := NULL;
       lc_country        VARCHAR2(10)   := NULL;
       lc_description    fnd_territories_vl.territory_short_name%TYPE;
       lc_postal         VARCHAR2(25)   := NULL;
       lc_state_pr       VARCHAR2(25)   := NULL;
       lc_address        VARCHAR2(1000) := NULL;
    BEGIN
    SELECT   loc.ADDRESS1                   REMIT_ADDRESS1
       , loc.ADDRESS2                           REMIT_ADDRESS2
       , loc.ADDRESS3                           REMIT_ADDRESS3
       , loc.ADDRESS4                           REMIT_ADDRESS4
       , loc.CITY                                      REMIT_CITY
       , loc.STATE                                   REMIT_STATE
       , loc.PROVINCE                            REMIT_PROVINCE
       , loc.POSTAL_CODE                    REMIT_POSTAL_CODE
       ,DECODE(loc.COUNTRY
                        ,'CA','CANADA'
                        ,loc.country
                        )                                   REMIT_COUNTRY
       INTO   lc_address1
             ,lc_address2
             ,lc_address3
             ,lc_address4
             ,lc_city
             ,lc_state
             ,lc_province
             ,lc_postal_code
             ,lc_country
      FROM     hz_cust_acct_sites acct_site,
               hz_party_sites party_site,
                hz_locations loc
      WHERE    acct_site.cust_acct_site_ID               = p_remit_control_id
      and acct_site.party_site_id = party_site.party_site_id
      and   loc.location_id = party_site.location_id;
       IF (lc_country = 'CANADA') THEN
           SELECT UPPER(territory_short_name)
           INTO   lc_description
           FROM   fnd_territories_vl
           WHERE  territory_code = 'CA';
           IF lc_description IS NULL THEN
                    lc_description := lc_country;
           END IF;
           lc_state_pr := lc_province;
       ELSIF lc_country = 'US' THEN
          lc_description := '';
          lc_state_pr := lc_state;
       END IF;
       IF ((LENGTH(lc_postal_code) <= 5) OR (lc_country <> 'US')) THEN
          lc_postal := lc_postal_code;
       ELSE
          lc_postal := SUBSTR(lc_postal_code,1,5)||'-'||SUBSTR(REPLACE(lc_postal_code ,'-'),6);
       END IF;
       x_remit_addr1   := lc_address1;
       x_remit_addr2   := lc_address2;
       x_remit_addr3   := lc_address3;
       x_remit_addr4   := lc_address4;
       x_remit_city    := lc_city;
       x_remit_state   := lc_state_pr;
       x_remit_zip     := lc_postal;
       x_remit_desc    := lc_description;
       x_remit_country := lc_country;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
       x_remit_addr1   := lc_address1;
       x_remit_addr2   := lc_address2;
       x_remit_addr3   := lc_address3;
       x_remit_addr4   := lc_address4;
       x_remit_city    := lc_city;
       x_remit_state   := lc_state_pr;
       x_remit_zip     := lc_postal;
       x_remit_desc    := lc_description;
    END GET_REMIT_ADDRESS;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : GET_ADDRESS                                                         |
-- | Description : This procedure is used to get the BILL TO address details  for the  |
-- |               given site_use_id.                                                  |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 17-MAR-2010  Ranjith Thangasamy            Initial draft version               |
-- +===================================================================================+
      PROCEDURE GET_ADDRESS (p_site_use_id IN  NUMBER
                         ,x_address1    OUT VARCHAR2
                         ,x_address2    OUT VARCHAR2
                         ,x_address3    OUT VARCHAR2
                         ,x_address4    OUT VARCHAR2
                         ,x_city        OUT VARCHAR2
                         ,x_country     OUT VARCHAR2
                         ,X_STATE       OUT VARCHAR2
                         ,X_POSTAL_CODE OUT VARCHAR2
                         ,X_LOCATION    OUT VARCHAR2
                         ,X_SHIP_TO_NAME OUT VARCHAR2
                         ,x_ship_to_sequence OUT VARCHAR2
                         ,x_province       OUT  VARCHAR2
                         ,x_site_id     OUT  NUMBER
                         ,x_site_sequence OUT VARCHAR2
                         ,x_customer_name OUT VARCHAR2
                         )
   IS
       lc_billto_address1       hz_locations.address1%TYPE    := NULL;
       lc_billto_address2       hz_locations.address2%TYPE    := NULL;
       lc_billto_address3       hz_locations.address3%TYPE    := NULL;
       lc_billto_address4       hz_locations.address4%TYPE    := NULL;
       lc_billto_city           hz_locations.city%TYPE        := NULL;
       lc_billto_country        hz_locations.country%TYPE     := NULL;
       lc_bill_to_state         hz_locations.state%TYPE       := NULL;
       LC_BILLTO_POSTAL_CODE    HZ_LOCATIONS.POSTAL_CODE%TYPE := NULL;
       LC_LOCATION              HZ_CUST_SITE_USES.LOCATION%TYPE    :=NULL;
       LC_SHIP_TO_NAME          VARCHAR2(500);
       lc_ship_to_sequence      hz_cust_site_uses_all.orig_system_reference%TYPE :=NULL;
       lc_province       VARCHAR2(1000) := NULL;
       ln_cust_acct_site_id hz_cust_acct_sites.cust_acct_site_id%TYPE := NULL;
       lc_site_sequence   hz_cust_acct_sites.orig_system_reference%TYPE := NULL;
       lc_customer_name hz_parties.party_name%TYPE := NULL;
   BEGIN
      SELECT HL.address1               bill_to_address1
            ,HL.address2               bill_to_address2
            ,HL.address3               bill_to_address3
            ,HL.address4               bill_to_address4
            ,HL.city                   bill_to_city
            ,HL.country                bill_to_country
            ,nvl(hl.state , hl.province)          bill_state
            ,(CASE WHEN ((LENGTH(HL.POSTAL_CODE) > 5) AND (HL.country = 'US'))
                        THEN (SUBSTR(HL.POSTAL_CODE,1,5)||'-'||SUBSTR(HL.POSTAL_CODE,6))
                        ELSE (HL.POSTAL_CODE)
                        END)BILL_TO_ZIP
            ,HCSU.LOCATION               LOCATION
            ,nvl(hl.address_lines_phonetic,hp.party_name) ship_to_name
            ,regexp_replace(SUBSTR
                        (NVL (SUBSTR (hcsu.orig_system_reference,
                                        INSTR (hcsu.orig_system_reference,
                                               '-'
                                              )
                                      + 1,
                                        (  INSTR (hcsu.orig_system_reference,
                                                  '-',
                                                  2,
                                                  2
                                                 )
                                         - INSTR (hcsu.orig_system_reference,
                                                  '-',
                                                  2
                                                 )
                                        )
                                      - 1
                                     ),
                              hcsu.orig_system_reference
                             ),
                         1,
                         9
                        ),
                    '^0*',
                    ''
                   ) SHIP_TO_SEQUENCE
            ,HL.province
            ,HCAS.cust_acct_site_id
            ,HCAS.orig_system_reference
            ,hp.party_name
      INTO   lc_billto_address1
            ,lc_billto_address2
            ,lc_billto_address3
            ,lc_billto_address4
            ,lc_billto_city
            ,LC_BILLTO_COUNTRY
            ,lc_bill_to_state
            ,LC_BILLTO_POSTAL_CODE
            ,LC_LOCATION
            ,LC_SHIP_TO_NAME
            ,lc_ship_to_sequence
            ,lc_province
            ,ln_cust_acct_site_id
            ,lc_site_sequence
            ,lc_customer_name
      FROM   hz_locations           HL
            ,hz_parties             HP
            ,hz_party_sites         HPS
            ,hz_cust_acct_sites     HCAS
            ,hz_cust_site_uses      HCSU
      WHERE  HCSU.site_use_id        = p_site_use_id
      AND    HCSU.cust_acct_site_id  = HCAS.cust_acct_site_id
      AND    HP.party_id             = HPS.party_id
      AND    HCAS.party_site_id      = HPS.party_site_id
      AND    HL.location_id          = HPS.location_id;
      x_address1    := lc_billto_address1;
      x_address2    := lc_billto_address2;
      x_address3    := lc_billto_address3;
      x_address4    := lc_billto_address4;
      x_city        := lc_billto_city;
      x_country     := lc_billto_country;
      x_state       := lc_bill_to_state;
      X_POSTAL_CODE := LC_BILLTO_POSTAL_CODE;
      X_LOCATION    := LC_LOCATION;
      X_SHIP_TO_NAME := LC_SHIP_TO_NAME;
      X_SHIP_TO_SEQUENCE :=lc_ship_to_sequence;
      x_province         := lc_province;
      x_site_id          := ln_cust_acct_site_id;
      x_site_sequence    := lc_site_sequence;
      x_customer_name    := lc_customer_name;
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
      x_address1    := NULL;
      x_address2    := NULL;
      x_address3    := NULL;
      x_address4    := NULL;
      x_city        := NULL;
      X_COUNTRY     := NULL;
      x_state       :=NULL;
      X_POSTAL_CODE := NULL;
      X_LOCATION    := NULL;
      X_SHIP_TO_NAME := NULL;
      x_ship_to_sequence :=NULL;
      x_customer_name  := NULL;
      gc_put_log := 'NO_DATA_FOUND Exception Raised in GET_ADDRESS Procedure for Site_Use_ID : ' ||p_site_use_id;
      PUT_LOG_LINE( FALSE
                   ,TRUE
                   ,gc_put_log
                   );
      WHEN OTHERS THEN
      gc_put_log := 'Exception Raised in GET_ADDRESS Procedure for Site_Use_ID : ' ||p_site_use_id ||' '||SQLERRM;
      PUT_LOG_LINE( FALSE
                   ,TRUE
                   ,gc_put_log
                   );
   END GET_ADDRESS;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : GET_TERM_DETAILS                                                    |
-- | Description : This procedure is used to fetch the required columns from the       |
-- |               ra_terms table.                                                     |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 17-MAR-2010  Vinaykumar S            Initial draft version               |
-- +===================================================================================+
   PROCEDURE GET_TERM_DETAILS (p_billing_term           IN  VARCHAR2
                              ,x_term                   OUT VARCHAR2
                              ,x_term_description       OUT VARCHAR2
                              ,x_term_discount          OUT VARCHAR2
                              ,x_term_frequency         OUT VARCHAR2
                              ,x_term_report_day        OUT VARCHAR2
                              )
   IS
       lc_term_term              ra_terms_b.attribute5%TYPE := NULL;
       lc_term_description       ra_terms.description%TYPE  := NULL;
       lc_term_discount          ra_terms_b.attribute4%TYPE := NULL;
       lc_term_frequency         ra_terms_b.attribute1%TYPE := NULL;
       lc_term_report_day        ra_terms_b.attribute2%TYPE := NULL;
   BEGIN
      SELECT rt.attribute5
        , rt.description
        , rt.attribute4
        , rt.attribute1
        , rt.attribute2
        INTO
          lc_term_term
        , lc_term_description
        , lc_term_discount
        , lc_term_frequency
        , lc_term_report_day
        FROM ra_terms rt
        WHERE rt.name = p_billing_term;
       x_term             :=  lc_term_term;
      x_term_description :=  lc_term_description;
      x_term_discount    :=  lc_term_discount;
      x_term_frequency   :=  lc_term_frequency;
      x_term_report_day  :=  lc_term_report_day;
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
       x_term             :=  NULL;
       x_term_description :=  NULL;
       x_term_discount    :=  NULL;
       x_term_frequency   :=  NULL;
       x_term_report_day  :=  NULL;
      gc_put_log := 'NO_DATA_FOUND Exception Raised in GET_TERM_DETAILS Procedure for Term_ID : ' ||p_billing_term;
      PUT_LOG_LINE( FALSE
                   ,TRUE
                   ,gc_put_log
                   );
   WHEN OTHERS THEN
       x_term             :=  NULL;
       x_term_description :=  NULL;
       x_term_discount    :=  NULL;
       x_term_frequency   :=  NULL;
       x_term_report_day  :=  NULL;
      gc_put_log := 'OTHERS Exception Raised in GET_TERM_DETAILS Procedure for Term_ID : ' ||p_billing_term;
      PUT_LOG_LINE( FALSE
                   ,TRUE
                   ,gc_put_log||' '||'SQLERRM : '||SQLERRM
                   );
   END GET_TERM_DETAILS;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        :  GET_HDR_ATTR_DETAILS                                               |
-- | Description : This procedure is used to fetch the required columns from the       |
-- |               xx_om_header_attributes_all table.                                  |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 17-MAR-2010  Vinaykumar S            Initial draft version               |
-- +===================================================================================+
   PROCEDURE GET_HDR_ATTR_DETAILS (p_header_id             IN  NUMBER
                                  ,p_spc_source_id         IN NUMBER
                                  ,x_contact_email         OUT VARCHAR2
                                  ,x_contact_name          OUT VARCHAR2
                                  ,x_contact_phone         OUT VARCHAR2
                                  ,x_contact_phone_ext     OUT VARCHAR2
                                  ,x_order_level_comment   OUT VARCHAR2
                                  ,x_order_type_code       OUT VARCHAR2
                                  ,x_order_source_code     OUT VARCHAR2
                                  ,x_ordered_by            OUT VARCHAR2
                                  ,X_Order_Date            OUT DATE
                                  ,X_Spc_Info              OUT VARCHAR2
                                  ,x_cost_center_sft_data  OUT VARCHAR2
                                  ,x_release_data          OUT VARCHAR2
                                  ,x_desk_data             OUT VARCHAR2
                                  ,x_ship_to_addr1         OUT VARCHAR2
                                  ,X_ship_to_addr2         OUT VARCHAR2
                                  ,X_ship_to_city          OUT VARCHAR2
                                  ,x_ship_to_state         OUT VARCHAR2
                                  ,x_ship_to_country       OUT VARCHAR2
                                  ,x_ship_to_zip           OUT VARCHAR2
                                  ,x_tax_rate              OUT NUMBER
                                 )
   IS
       lc_contact_email         xx_om_header_attributes_all.cust_pref_email%TYPE   := NULL;
       lc_contact_name          xx_om_header_attributes_all.cust_contact_name%TYPE := NULL;
       lc_contact_phone         xx_om_header_attributes_all.cust_pref_phone%TYPE   := NULL;
       lc_contact_phone_ext     xx_om_header_attributes_all.cust_pref_phextn%TYPE  := NULL;
       lc_order_level_comment   xx_om_header_attributes_all.comments%TYPE          := NULL;
       lc_ordered_by            xx_om_header_attributes_all.cust_contact_name%TYPE := NULL;
       lc_order_date            oe_order_headers.ordered_date%TYPE     := NULL;
       lc_order_header_id       oe_order_headers.header_id%TYPE     := NULL;
       lc_spc_comments              VARCHAR2(2000)  :=NULL;
       Lc_Spc_Info              oe_order_headers.Orig_Sys_Document_Ref%TYPE   :=NULL;
       lc_cost_center_sft_data  xx_om_header_attributes_all.cost_center_dept%TYPE := Null;
       lc_release_sft_data      xx_om_header_attributes_all.release_number%TYPE   := Null;
       lc_desk_del_addr         xx_om_header_attributes_all.desk_del_addr%TYPE   := Null;
       lc_purchase_order_revision oe_order_headers_all.Orig_Sys_Document_Ref%TYPE :=NULL;
       lc_trx_comments    Xx_Om_Header_Attributes_All.comments %TYPE  :=NULL;
       LC_SPC_ORDER_SOURCE_ID NUMBER;
       lc_order_source_code fnd_lookup_values.lookup_code%TYPE := NULL;
       lc_order_source_id Oe_Order_Headers_All.order_source_id%TYPE :=NULL;
       lc_ship_to_addr1 xx_om_header_attributes_All.ship_to_address1%TYPE:=NULL;
       lc_ship_to_addr2 xx_om_header_attributes_All.ship_to_address2%TYPE:=NULL;
       lc_ship_to_city xx_om_header_attributes_All.ship_to_city%TYPE:=NULL;
       lc_ship_to_state xx_om_header_attributes_All.ship_to_state%TYPE:=NULL;
       lc_ship_to_country xx_om_header_attributes_All.ship_to_country%TYPE:=NULL;
       lc_ship_to_zip xx_om_header_attributes_All.ship_to_zip%TYPE:=NULL;
       lc_order_type_code xx_om_header_attributes_All.od_order_type%TYPE:=NULL;
       lc_tax_rate xx_om_header_attributes_All.tax_rate%TYPE := 0;
   BEGIN
      SELECT  XOHA.cust_pref_email                bill_to_contact_email
             ,XOHA.cust_contact_name              bill_to_contact_name
             ,XOHA.cust_pref_phone                bill_to_contact_phone
             ,XOHA.cust_pref_phextn               bill_to_contact_phone_ext
             ,XOHA.comments                       order_level_comment
             ,XOHA.spc_card_number                spc_card_number
             ,XOHA.cust_contact_name              ordered_by
             ,Oeha.Ordered_Date
             ,Oeha.Orig_Sys_Document_Ref
             ,XOHA.cost_center_dept
             ,XOHA.release_number
             ,XOHA.desk_del_addr
            ,OEHA.order_source_id
            ,XOHA.od_order_type
            ,XOHA.ship_to_address1
             ,XOHA.ship_to_address2
             ,XOHA.ship_to_city
             ,XOHA.ship_to_state
             ,DECODE(XOHA.ship_to_country,'USA','US','CAN','CA','CHN','CN','IND','IN','BAH','BS',XOHA.ship_to_country)
             ,(CASE WHEN ((LENGTH(XOHA.ship_to_zip) > 5) and XOHA.ship_to_country IN('US','USA'))
                        THEN (SUBSTR(XOHA.ship_to_zip,1,5)||'-'||SUBSTR(XOHA.ship_to_zip,6))
                        ELSE (XOHA.ship_to_zip)
                        END)
             ,XOHA.tax_rate*100
      INTO   lc_contact_email
            ,lc_contact_name
            ,lc_contact_phone
            ,lc_contact_phone_ext
            ,lc_order_level_comment
            ,lc_trx_comments
            ,lc_ordered_by
            ,Lc_Order_Date
            ,lc_purchase_order_revision
            ,lc_cost_center_sft_data
            ,lc_release_sft_data
            ,lc_desk_del_addr
            ,lc_order_source_id
            ,lc_order_type_code
            ,lc_ship_to_addr1
            ,lc_ship_to_addr2
            ,lc_ship_to_city
            ,lc_ship_to_state
            ,lc_ship_to_country
            ,lc_ship_to_zip
            ,lc_tax_rate
      From   Xx_Om_Header_Attributes_All  Xoha
            ,Oe_Order_Headers_All Oeha
      Where  Xoha.Header_Id = P_Header_Id
      AND    xoha.header_id = oeha.header_id;
      BEGIN
      IF (lc_order_source_id = p_spc_source_id) THEN
            lc_spc_comments := 'Note: '||'SPC '||lc_trx_comments ||' Date: '||TO_DATE(substr(lc_purchase_order_revision,5,8),'YYYYMMDD')||' Location: '|| substr(lc_purchase_order_revision,1,4) ||
                   ' Register: '|| substr(lc_purchase_order_revision,13,3) ||' Trans #: '|| substr(lc_purchase_order_revision,16,5);
      END IF;
      EXCEPTION
      WHEN OTHERS THEN
      gc_put_log := 'OTHERS Exception Raised in GET_HDR_ATTR_DETAILS - spc details Procedure for Header_ID : ' ||p_header_id||' '||SQLERRM;
      PUT_LOG_LINE( FALSE
                   ,TRUE
                   ,gc_put_log
                   );
      END;
      BEGIN
            SELECT lookup_code
            INTO  lc_order_source_code
            FROM fnd_lookup_values lkup
            WHERE lkup.lookup_type = 'OD_ORDER_SOURCE'
            AND lkup.attribute6 = TO_CHAR (lc_order_source_id)
            AND lkup.enabled_flag = 'Y'
            AND lkup.start_date_active <= TRUNC (SYSDATE)
            AND NVL (lkup.end_date_active, TRUNC (SYSDATE)) >= TRUNC (SYSDATE)
            AND ROWNUM < 2;
      EXCEPTION
         WHEN OTHERS THEN
         gc_put_log := 'OTHERS Exception Raised When deriving Order source code for Header_ID : ' ||p_header_id||' '||SQLERRM;
         PUT_LOG_LINE( FALSE
                      ,TRUE
                      ,gc_put_log
                      );
      END;
       x_contact_email        :=   lc_contact_email;
       x_contact_name         :=   lc_contact_name;
       x_contact_phone        :=   lc_contact_phone;
       x_contact_phone_ext    :=   lc_contact_phone_ext;
       x_order_level_comment  :=   lc_order_level_comment;
       x_order_source_code      :=   lc_order_source_code;
       x_order_type_code      := lc_order_type_code;
       x_ordered_by           :=   lc_ordered_by;
       x_order_date       := trunc(lc_order_date);
       X_Spc_Info         := lc_spc_comments;
       x_cost_center_sft_data :=lc_cost_center_sft_data;
       x_release_data := lc_release_sft_data;
       x_desk_data := lc_desk_del_addr;
       x_ship_to_addr1   :=    lc_ship_to_addr1;
       X_ship_to_addr2   :=    lc_ship_to_addr2;
       X_ship_to_city    :=    lc_ship_to_city;
       x_ship_to_state   :=    lc_ship_to_state;
       x_ship_to_country :=    lc_ship_to_country;
       x_ship_to_zip       :=  lc_ship_to_zip;
       x_tax_Rate         :=   lc_tax_rate;
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
      gc_put_log := 'NO_DATA_FOUND Exception Raised in GET_HDR_ATTR_DETAILS Procedure for Header_ID : ' ||p_header_id;
      PUT_LOG_LINE( FALSE
                   ,TRUE
                   ,gc_put_log
                   );
   WHEN OTHERS THEN
      gc_put_log := 'OTHERS Exception Raised in GET_HDR_ATTR_DETAILS Procedure for Header_ID : ' ||p_header_id||' '||SQLERRM;
      PUT_LOG_LINE( FALSE
                   ,TRUE
                   ,gc_put_log
                   );
   END  GET_HDR_ATTR_DETAILS;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        :  GET_CUST_TRX_LINE_DETAILS                                          |
-- | Description : This procedure is used to fetch the required columns from the       |
-- |               ra_customer_trx_lines table.                                        |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 17-MAR-2010  Vinaykumar S            Initial draft version               |
-- +===================================================================================+
   PROCEDURE GET_CUST_TRX_LINE_DETAILS ( p_cust_trx_line_id            IN  NUMBER
                                        ,p_trx_type                    IN  VARCHAR2
                                        ,x_cont_plan_id                OUT VARCHAR2
                                        ,x_cont_seq_number             OUT VARCHAR2
                                        ,x_ext_price                   OUT VARCHAR2
                                        ,x_item_desc                   OUT VARCHAR2
                                        ,x_qty_ordered                 OUT VARCHAR2
                                        ,x_qty_shipped                 OUT VARCHAR2
                                        ,x_amt_tax_flag                OUT VARCHAR2
                                        ,x_cust_trx_id                 OUT VARCHAR2
                                        ,x_cust_trx_line_id            OUT VARCHAR2
                                        ,x_line_number                 OUT VARCHAR2
                                        ,x_link_to_cust_trx_line_id    OUT VARCHAR2
                                        ,x_sales_order                 OUT VARCHAR2
                                        ,x_sales_order_date            OUT VARCHAR2
                                        ,x_sales_tax_id                OUT VARCHAR2
                                        ,x_tax_exempt_id               OUT VARCHAR2
                                        ,x_tax_precedence              OUT VARCHAR2
                                        ,x_unit_selling_price          OUT VARCHAR2
                                 )
   IS
      lc_cont_plan_id                 ra_customer_trx_lines.attribute9 %TYPE               :=  NULL;
      lc_cont_seq_number              ra_customer_trx_lines.attribute10%TYPE               :=  NULL;
      lc_ext_price                    ra_customer_trx_lines.extended_amount%TYPE           :=  NULL;
      lc_item_desc                    ra_customer_trx_lines.description%TYPE               :=  NULL;
      ln_qty_ordered                  ra_customer_trx_lines.quantity_ordered%TYPE          :=  NULL;
      ln_qty_shipped                  ra_customer_trx_lines.quantity_invoiced%TYPE         :=  NULL;
      lc_amt_tax_flag                 ra_customer_trx_lines.amount_includes_tax_flag%TYPE  :=  NULL;
      ln_cust_trx_id                  ra_customer_trx_lines.customer_trx_id%TYPE           :=  NULL;
      ln_cust_trx_line_id             ra_customer_trx_lines.customer_trx_line_id%TYPE      :=  NULL;
      ln_line_number                  ra_customer_trx_lines.line_number%TYPE               :=  NULL;
      ln_link_to_cust_trx_line_id     ra_customer_trx_lines.link_to_cust_trx_line_id%TYPE  :=  NULL;
      lc_sales_order                  ra_customer_trx_lines.sales_order%TYPE               :=  NULL;
      ld_sales_order_date             ra_customer_trx_lines.sales_order_date%TYPE          :=  NULL;
      ln_sales_tax_id                 ra_customer_trx_lines.sales_tax_id%TYPE              :=  NULL;
      ln_tax_exempt_id                ra_customer_trx_lines.tax_exemption_id%TYPE          :=  NULL;
      ln_tax_precedence               ra_customer_trx_lines.tax_precedence%TYPE            :=  NULL;
      ln_unit_selling_price           ra_customer_trx_lines.unit_selling_price%TYPE        :=  NULL;
   BEGIN
      SELECT RCTL.attribute9                                            Contract_plan_id
            ,RCTL.attribute10                                           Contract_seq_number
            ,NVL (RCTL.extended_amount, RCTL.gross_extended_amount)     ext_price
            ,NVL(RCTL.translated_description,RCTL.description)          item_Description
            ,DECODE(p_trx_type,'CM',RCTL.quantity_credited ,
                     NVL(RCTL.quantity_ordered,RCTL.quantity_invoiced)) quantity_ordered
            ,NVL(RCTL.quantity_invoiced,RCTL.quantity_credited)         quantity_shipped
            ,RCTL.amount_includes_tax_flag                              amount_includes_tax_flag
            ,RCTL.customer_trx_id                                       customer_trx_id
            ,RCTL.customer_trx_line_id                                  customer_trx_line_id
            ,RCTL.line_number                                           line_number
            ,RCTL.link_to_cust_trx_line_id                              link_to_cust_trx_line_id
            ,RCTL.sales_order                                           sales_order
            ,RCTL.sales_order_date                                      sales_order_date
            ,RCTL.sales_tax_id                                          sales_tax_id
            ,RCTL.tax_exemption_id                                      tax_exemption_id
            ,RCTL.tax_precedence                                        tax_precedence
            ,RCTL.unit_selling_price                                    unit_selling_price
      INTO  lc_cont_plan_id
           ,lc_cont_seq_number
           ,lc_ext_price
           ,lc_item_desc
           ,ln_qty_ordered
           ,ln_qty_shipped
           ,lc_amt_tax_flag
           ,ln_cust_trx_id
           ,ln_cust_trx_line_id
           ,ln_line_number
           ,ln_link_to_cust_trx_line_id
           ,lc_sales_order
           ,ld_sales_order_date
           ,ln_sales_tax_id
           ,ln_tax_exempt_id
           ,ln_tax_precedence
           ,ln_unit_selling_price
      FROM  RA_CUSTOMER_TRX_LINES   RCTL
      WHERE RCTL.CUSTOMER_TRX_LINE_ID       =  P_CUST_TRX_LINE_ID;
      x_cont_plan_id              :=  lc_cont_plan_id;
      x_cont_seq_number           :=  lc_cont_seq_number;
      x_ext_price                 :=  lc_ext_price;
      x_item_desc                 :=  lc_item_desc;
      x_qty_ordered               :=  ln_qty_ordered;
      x_qty_shipped               :=  ln_qty_shipped;
      x_amt_tax_flag              :=  lc_amt_tax_flag;
      x_cust_trx_id               :=  ln_cust_trx_id;
      x_cust_trx_line_id          :=  ln_cust_trx_line_id;
      x_line_number               :=  ln_line_number;
      x_link_to_cust_trx_line_id  :=  ln_link_to_cust_trx_line_id;
      x_sales_order               :=  lc_sales_order;
      x_sales_order_date          :=  ld_sales_order_date;
      x_sales_tax_id              :=  ln_sales_tax_id;
      x_tax_exempt_id             :=  ln_tax_exempt_id;
      x_tax_precedence            :=  ln_tax_precedence;
      x_unit_selling_price        :=  ln_unit_selling_price;
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
      x_cont_plan_id              :=  NULL;
      x_cont_seq_number           :=  NULL;
      x_ext_price                 :=  NULL;
      x_item_desc                 :=  NULL;
      x_qty_ordered               :=  NULL;
      x_qty_shipped               :=  NULL;
      x_amt_tax_flag              :=  NULL;
      x_cust_trx_id               :=  NULL;
      x_cust_trx_line_id          :=  NULL;
      x_line_number               :=  NULL;
      x_link_to_cust_trx_line_id  :=  NULL;
      x_sales_order               :=  NULL;
      x_sales_order_date          :=  NULL;
      x_sales_tax_id              :=  NULL;
      x_tax_exempt_id             :=  NULL;
      x_tax_precedence            :=  NULL;
      x_unit_selling_price        :=  NULL;
      gc_put_log := 'NO_DATA_FOUND Exception Raised in GET_CUST_TRX_LINE_DETAILS Procedure for Cust_trx_line_id : ' ||p_cust_trx_line_id;
      PUT_LOG_LINE( FALSE
                   ,TRUE
                   ,gc_put_log
                   );
   END  GET_CUST_TRX_LINE_DETAILS;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : ADDR_EXCP_HANDLING (Address Exception Handling)                     |
-- | Description : To Handle address exceptions                                        |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |DRAFT 1.0 18-MAR-2010  Vinaykumar S            Initial draft version               |
-- +===================================================================================+
   FUNCTION ADDR_EXCP_HANDLING ( p_cust_account_id      NUMBER
                                ,p_cust_doc_id          NUMBER
                                ,p_ship_to_site_use_id  NUMBER
                                ,p_direct_flag          VARCHAR2
                                ,p_site_attr_id         NUMBER
                               )
   RETURN NUMBER
   AS
      ln_site_attr_id         xx_cdh_cust_acct_ext_b.attr_group_id%TYPE;
      ln_cust_acct_site_id    hz_cust_acct_sites_all.cust_acct_site_id%TYPE;
      ln_site_use_id          hz_cust_site_uses_all.site_use_id%TYPE;
      BEGIN
               BEGIN
                  SELECT cust_acct_site_id
                  INTO   ln_cust_acct_site_id
                  FROM   hz_cust_site_uses_all
                  WHERE  site_use_id = p_ship_to_site_use_id;
                  SELECT HCSU.site_use_id
                  INTO   ln_site_use_id
                  FROM   xx_cdh_acct_site_ext_b XCASE
                        ,hz_cust_acct_sites_all HCAS
                        ,hz_cust_site_uses_all  HCSU
                  WHERE  XCASE.cust_acct_site_id = ln_cust_acct_site_id
                  AND    XCASE.n_ext_attr1       = p_cust_doc_id
                  AND    HCSU.cust_acct_site_id  = HCAS.cust_acct_site_id
                  AND    XCASE.c_ext_attr5       = HCAS.orig_system_reference
                  AND    XCASE.attr_group_id     = p_site_attr_id
                  AND    HCSU.site_use_code      = 'SHIP_TO'
                  AND    XCASE.c_ext_attr20      = 'Y';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     IF (p_direct_flag = 'Y') THEN
                        SELECT  HCSU.site_use_id
                        INTO    ln_site_use_id
                        FROM    hz_cust_acct_sites HCAS
                               ,hz_cust_site_uses  HCSU
                        WHERE   HCAS.cust_account_id   = p_cust_account_id
                        AND     HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
                        AND     HCSU.site_use_code     = 'BILL_TO'
                        AND     HCSU.primary_flag      = 'Y';
                        gc_put_log := 'CUST_DOC_ID is NOT NULL and DIRECT_FLAG is Y and site_use_id: '||ln_site_use_id ||' for cust_acct_id :'||p_cust_account_id;
                        PUT_LOG_LINE( FALSE
                                     ,TRUE
                                     ,gc_put_log
                                     );
                     ELSE
                        ln_site_use_id := p_ship_to_site_use_id;
                        gc_put_log := 'CUST_DOC_ID is NOT NULL and DIRECT_FLAG is N and site_use_id: '||p_ship_to_site_use_id ||' for cust_acct_id :'||p_cust_account_id;
                        PUT_LOG_LINE( FALSE
                                     ,TRUE
                                     ,gc_put_log
                                     );
                     END IF;
               END;
 RETURN (ln_site_use_id);
   EXCEPTION
      WHEN OTHERS
      THEN
         gc_put_log := 'Exception raised in ADDR_EXCP_HANDLING Function. Please, check the LOG for details :' ||SQLERRM;
         PUT_LOG_LINE( FALSE
                      ,TRUE
                      ,gc_put_log
                      );
          RETURN(0);
   END ADDR_EXCP_HANDLING;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : GET_SOFT_HEADER (Soft Headers)                                      |
-- | Description : To get soft header values                                           |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |DRAFT 1.0 18-MAR-2010  Ranjith Thangasamy      Initial draft version               |
-- +===================================================================================+
 PROCEDURE GET_SOFT_HEADER ( p_cust_acct_id      IN NUMBER
                              ,p_report_soft_header_id IN NUMBER
                              ,x_cost_center_dept  OUT VARCHAR2
                              ,x_desk_del_addr     OUT VARCHAR2
                              ,x_Om_Release_Number OUT VARCHAR2
                              ,x_purchase_order    OUT VARCHAR2
                              )
   IS
   lc_cost_center_dept      VARCHAR2(250) := NULL;
   lc_desk_del_addr         VARCHAR2(250)    := NULL;
   Lc_Om_Release_Number     VARCHAR2(250)    := Null;
   lc_purchase_order        VARCHAR2(250)    := Null;
   BEGIN
      SELECT XCCAE.c_ext_attr2 po_header
            ,XCCAE.c_ext_attr3 release_header
            ,XCCAE.c_ext_attr1 department_header
            ,XCCAE.c_ext_attr4 delivered_to_header
      INTO lc_purchase_order
          ,Lc_Om_Release_Number
          ,lc_cost_center_dept
          ,lc_desk_del_addr
      FROM xx_cdh_cust_acct_ext_b XCCAE
      WHERE cust_account_id = p_cust_acct_id
      AND   attr_group_id = p_report_soft_header_id;
    x_cost_center_dept := lc_cost_center_dept;
    x_desk_del_addr     :=lc_desk_del_addr;
    x_Om_Release_Number :=Lc_Om_Release_Number;
    x_purchase_order    := lc_purchase_order;
   EXCEPTION WHEN
       NO_DATA_FOUND THEN
    x_cost_center_dept  :=NULL;
    x_desk_del_addr     :=NULL;
    x_Om_Release_Number :=NULL;
    x_purchase_order    :=NULL;
   END GET_SOFT_HEADER;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : xx_fin_check_digit                                                  |
-- | Description : This function is used to get the FLO code for remittance stub.      |
-- |                                                                                   |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |DRAFT 1.0 05-APR-2010  Bhuvaneswary S            Initial draft version             |
-- +===================================================================================+
   FUNCTION xx_fin_check_digit (p_account_number VARCHAR2
                               ,p_invoice_number VARCHAR2
                               ,p_amount         VARCHAR2
                               )
   RETURN VARCHAR2
   IS
   v_account_number       VARCHAR2(8)  := LPAD(REPLACE(p_account_number,' ','0'),8,'0');
   v_account_number_cd    NUMBER;
   v_invoice_number       VARCHAR2(12) := LPAD(REPLACE(p_invoice_number,' ','0'),12,'0');
   v_invoice_number_cd    NUMBER;
   v_amount               VARCHAR2(11) := LPAD(REPLACE(REPLACE(p_amount,' ','0'),'-','0'),11,'0');
   v_amount_cd            NUMBER;
   v_value_out            VARCHAR2(50);
   v_final_cd             NUMBER;
      FUNCTION f_check_digit (v_string VARCHAR2)
      RETURN NUMBER
      IS
      v_sum     NUMBER := 0;
      v_weight  NUMBER;
      v_product NUMBER;
      BEGIN
         FOR i in 1..length(v_string)
            LOOP
               /* Set the weight based on the character space */
               If mod(i,2) = 0 Then
                  v_weight := 2;
               Else
                  v_weight := 1;
               End If;
               /* Calculate the weighted procduct */
               v_product := SUBSTR(v_string, i, 1) * v_weight;
               /* Add the digit or digits to the sum */
               IF LENGTH(v_product) = 1 THEN
                  v_sum := v_sum + v_product;
               ELSE
                  v_sum := v_sum + SUBSTR(v_product,1,1) + SUBSTR(v_product,2);
               END IF;
            END LOOP;
            /* Check digit is 10-the mod10 of the sum */
            IF (MOD(v_sum,10) = 0) THEN   -- defect 7629
               v_sum := 0;
            ELSE
               v_sum := 10-MOD(v_sum,10);
            END IF;
      RETURN v_sum;
      END;
   BEGIN
      /* Calculate the account check digit */
      v_account_number_cd := f_check_digit(v_account_number);
      /* Calculate the invoice check digit */
      v_invoice_number_cd := f_check_digit(v_invoice_number);
      /* Set the amount check digit */
      IF p_amount > 0 THEN
         v_amount_cd := 1;
      ELSE
         v_amount_cd := 0;
      END IF;
      /* Calculate the final check digit */
      v_final_cd := f_check_digit(v_account_number||v_account_number_cd||v_invoice_number||v_invoice_number_cd||v_amount||v_amount_cd);
      /* Build and return the out value */
      v_value_out := v_account_number||v_account_number_cd||' '||v_invoice_number||v_invoice_number_cd||' '||v_amount||' '||v_amount_cd||' '||v_final_cd;
   RETURN v_value_out;
   EXCEPTION
     WHEN OTHERS THEN
        RETURN '000000000000000';
   END xx_fin_check_digit;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : GET_CONCAT_ADDR                                                     |
-- | Description : This function is used to get concated address.               .      |
-- |                                                                                   |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |DRAFT 1.0 05-APR-2010  Bhuvaneswary S            Initial draft version             |
-- +===================================================================================+
   FUNCTION GET_CONCAT_ADDR (p_addr1   VARCHAR2
                            ,p_addr2   VARCHAR2
                            ,p_addr3   VARCHAR2
                            ,p_addr4   VARCHAR2
                            ,p_city    VARCHAR2
                            ,p_state   VARCHAR2
                            ,p_postal  VARCHAR2
                            ,p_country VARCHAR2
                             )
   RETURN VARCHAR2
   IS
      lc_address VARCHAR2(1000);
   BEGIN
      IF (p_addr1 IS NOT NULL)
      THEN
         lc_address :=p_addr1;
      END IF;
      IF (p_addr2 IS NOT NULL)
      THEN
         lc_address := lc_address||chr(10)||p_addr2;
      END IF;
      IF (p_addr3 IS NOT NULL)
      THEN
         lc_address := lc_address||chr(10)||p_addr3;
      END IF;
      IF (p_addr4 IS NOT NULL)
      THEN
         lc_address := lc_address||chr(10)||p_addr4;
      END IF;
   RETURN (lc_address || chr(10) || p_city || ' ' || p_state || ' ' || p_postal || chr(10) || p_country);
   END GET_CONCAT_ADDR;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : gsa_comments                                                        |
-- | Description : This function is used to get the gsa comments                .      |
-- |                                                                                   |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |DRAFT 1.0 05-APR-2010  Ranjith Thangasamy        Initial draft version             |
-- +===================================================================================+
  FUNCTION gsa_comments (p_gsa_flag IN NUMBER)
   RETURN VARCHAR2
   IS
   BEGIN
  -- need to change to a look up
   IF (p_gsa_flag = 1) THEN
     RETURN 'On Federal Supply Schedule';
   ELSIF (p_gsa_flag = 2) THEN
     RETURN 'Not On Federal Supply Schedule';
   ELSE
     RETURN NULL;
  END IF;
   end gsa_comments;

   -- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : get_site_mail_attention                                                        |
-- | Description : This function is used to get the mail to attention           .      |
-- |                                                                                   |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |DRAFT 1.0 05-APR-2010  Ranjith Thangasamy        Initial draft version             |
-- +===================================================================================+
 function get_site_mail_attention ( p_cust_doc_id NUMBER
                                   ,p_cust_site_id number
                                   ,p_attr_id      NUMBER
                                   )
  return varchar2
  is
  lc_mail_to_attention VARCHAR2(1000);
  begin
  select c_ext_attr3
  INTO  lc_mail_to_attention
  from   xx_cdh_acct_site_ext_b xcase
  where xcase.cust_acct_site_id = p_cust_site_id
  and    xcase.n_ext_attr1 = p_cust_doc_id
  and    xcase.attr_group_id     = p_attr_id
  and    xcase.c_ext_attr20      = 'Y';
  RETURN lc_mail_to_attention;
  exception when others then
  return null;
  END get_site_mail_attention;

   -- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : get_extract_status                                                  |
-- | Description : This function is used to get theectract status               .      |
-- |                                                                                   |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |DRAFT 1.0 05-APR-2010  Ranjith Thangasamy        Initial draft version             |
-- +===================================================================================+
  FUNCTION get_extract_status (p_as_of_date DATE
                               ,p_cust_doc_id IN NUMBER)
  RETURN VARCHAR2
  IS
  ln_count NUMBER;
  BEGIN
   SELECT count(1)
   INTO ln_count
   FROM XX_AR_EBL_ERROR_BILLS
   WHERE cust_doc_id = p_cust_doc_id
   AND   as_of_date = p_as_of_date;
   IF (ln_count = 0) THEN
   RETURN 'COMPLETE DOCUMENT EXTRACTED';
   ELSE
   RETURN 'PARTIAL DOCUMENT EXTRACTED';
   END IF;
   END get_extract_status;

   PROCEDURE get_misc_values(p_order_header_id IN NUMBER
                         ,p_reason_code     IN VARCHAR2
                         ,p_sold_to_customer_id IN NUMBER
                         ,p_invoice_type     IN VARCHAR2
                         ,x_orgordnbr       OUT VARCHAR2
                         ,x_reason_code     OUT VARCHAR2
                         ,x_sold_to_customer OUT VARCHAR2
                         ,x_reconcile_date   OUT DATE
                         )
IS
 lc_orgordnbr     xx_om_line_attributes_all.ret_orig_order_num%TYPE   :=NULL;
 lc_reason_code   ar_lookups.meaning%TYPE   :=NULL;
 lc_sold_to_customer hz_cust_accounts_all.account_number%TYPE :=NULL;
 lc_reconcile_date oe_order_lines_all.actual_shipment_date%TYPE :=NULL;
BEGIN
      IF (p_invoice_type = 'CM') THEN
        BEGIN
          SELECT ooh.order_number
          INTO lc_orgordnbr
          FROM xx_om_line_attributes_all xola,
               oe_order_lines ool,
               oe_order_headers ooh
          WHERE xola.line_id = ool.line_id
          AND ool.header_id = p_order_header_id
          AND ooh.orig_sys_document_ref = XOLA.ret_orig_order_num
          AND ROWNUM = 1;
          x_orgordnbr :=lc_orgordnbr;
        EXCEPTION
          WHEN no_data_found THEN
          x_orgordnbr := NULL;
        END;
        BEGIN
          SELECT meaning
          INTO lc_reason_code
          FROM ar_lookups al
          WHERE al.lookup_type = 'CREDIT_MEMO_REASON'
          AND lookup_code = p_reason_code;
          x_reason_code := lc_reason_code;
        EXCEPTION
          WHEN no_data_found THEN
          x_reason_code := NULL;
        END;
     END IF;
       BEGIN
        SELECT account_number
        INTO lc_sold_to_customer
        FROM hz_cust_accounts_all
        WHERE cust_account_id = p_sold_to_customer_id;
        x_sold_to_customer := lc_sold_to_customer;
      EXCEPTION
        WHEN no_data_found THEN
        x_sold_to_customer := NULL;
      END;
     BEGIN
      SELECT  ACTUAL_SHIPMENT_DATE
      INTO lc_reconcile_date
      FROM oe_order_lines_all
      where header_id = p_order_header_id
      and rownum < 2;
      x_reconcile_date := lc_reconcile_date;
     EXCEPTION
        WHEN no_data_found THEN
        x_reconcile_date := NULL;
    END;
  END get_misc_values;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : UPDATE_BILL_STATUS                                                  |
-- | Description : This function is used to updated standard table and delete and      |
-- |               and insert data into frequency and frequency history table          |
-- |               respectively.                                                       |
-- |                                                                                   |
-- |===============                                                                    |
-- |Version   Date            Author                  Remarks                          |
-- |=======   ===========     =============           =================================|
-- |DRAFT 1.0 29-APR-2010     Gokila Tamilselvam      Initial draft version            |
-- |1.1       12-MAR-2013     Rajeshkumar M R         Moved department description     |
-- |                                                  to header Defect# 15118          |
-- |1.2       08-DEC-2015     Havish Kasina           Added new column dept_code in    |
-- |                                                  xx_ar_ebl_cons_dtl_hist,         |
-- |                                                  xx_ar_ebl_cons_hdr_hist,         |
-- |                                                  xx_ar_ebl_ind_dtl_hist and       |
-- |                                                  xx_ar_ebl_ind_hdr_hist tables    |
-- |                                                  -- Defect 36437                  |
-- |                                                  (MOD 4B Release 3)               |
-- |1.3       16-JUN-2016     Suresh Naragam          Mod 4B Release 4 changes         |
-- |1.4       23-JUN-2016     Havish Kasina           Added new column kit_sku in      |
-- |                                                  xx_ar_ebl_cons_dtl_hist,         |
-- |                                                  xx_ar_ebl_ind_dtl_hist           |
-- |                                                  -- Defect 37675                  |
-- |                                                  (Kitting Changes)                |
-- |1.5       12-SEP-2018     Aarthi                  NAIT - 58403 Added SKU level     |
-- |                                                  columns to the history tables    |
-- +===================================================================================+
    PROCEDURE UPDATE_BILL_STATUS ( p_batch_id            NUMBER
                                  ,p_doc_type            VARCHAR2
                                  ,p_delivery_meth       VARCHAR2
                                  ,p_request_id          NUMBER
                                  ,p_debug_flag          VARCHAR2
                                  )
    IS
      lb_debug       BOOLEAN;
      lc_status      VARCHAR2(10)     := 'RENDERED';
      ln_org_id      NUMBER;
      lc_error_loc   VARCHAR2(4000);
    BEGIN
       IF p_debug_flag = 'Y' THEN
          lb_debug := TRUE;
       ELSE
          lb_debug := FALSE;
       END IF;
       ln_org_id    := FND_PROFILE.VALUE('ORG_ID');

       IF p_doc_type = 'CONS' THEN

          lc_error_loc := 'Updating the AR CONS INV Table ';
          UPDATE ar_cons_inv   ACI
          SET    ACI.attribute12                     = p_request_id
                ,ACI.attribute14                     = p_delivery_meth
                ,ACI.attribute15                     = 'Y'
                ,ACI.attribute11                     = 'COMPLETE'
                ,ACI.last_updated_by                 = FND_GLOBAL.USER_ID
                ,ACI.last_update_date                = SYSDATE
                ,ACI.last_update_login               = FND_GLOBAL.USER_ID
          WHERE  EXISTS (SELECT /*+ leading(XAEF) */1
                         FROM   xx_ar_ebl_cons_hdr_main  XAECHM
                               ,xx_ar_ebl_file           XAEF
                         WHERE  XAECHM.cons_inv_id              = ACI.cons_inv_id
                         AND    XAECHM.document_type            = 'Paydoc'
                         AND    XAECHM.batch_id                 = p_batch_id
                         AND    XAECHM.org_id                   = ln_org_id
                         AND    XAECHM.billdocs_delivery_method = p_delivery_meth
                         AND    XAECHM.file_id                  = XAEF.file_id
                         AND    XAECHM.transmission_id          = XAEF.transmission_id
                         AND    XAEF.status                     = lc_status
                         );
          PUT_LOG_LINE ( lb_debug
                        ,TRUE
                        ,'Number of consolidated Bill Updated for the Batch ID : '||p_batch_id||' are : '||SQL%ROWCOUNT
                        );

          lc_error_loc := 'Inserting into Consolidated Detail History Table ';
          INSERT INTO xx_ar_ebl_cons_dtl_hist ( cons_inv_id,customer_trx_id,cust_doc_id,customer_trx_line_id,trx_line_number
                                               ,trx_line_type,item_description,inventory_item_id,inventory_item_number
                                               ,translated_description,order_line_id,po_line_number,quantity_back_ordered
                                               ,quantity_credited,quantity_invoiced,quantity_ordered,quantity_shipped
                                               ,unit_of_measure,unit_price,ext_price,contract_plan_id,contract_seq_number
                                               ,entered_product_code,vendor_product_code,customer_product_code,discount_code
                                               ,elec_detail_seq_number,elec_record_type,wholesaler_item,detail_rec_taxable_flag
                                               ,gsa_comments,interface_line_context,price_adjustment_id,last_updated_by
                                               ,last_updated_date,created_by,creation_date,last_updated_login,c_ext_attr1,c_ext_attr2
                                               ,c_ext_attr3,c_ext_attr4,c_ext_attr5,c_ext_attr6,c_ext_attr7,c_ext_attr8
                                               ,c_ext_attr9,c_ext_attr10,c_ext_attr11,c_ext_attr12,c_ext_attr13,c_ext_attr14
                                               ,c_ext_attr15,c_ext_attr16,c_ext_attr17,c_ext_attr18,c_ext_attr19,c_ext_attr20
                                               ,c_ext_attr21,c_ext_attr22,c_ext_attr23,c_ext_attr24,c_ext_attr25,c_ext_attr26
                                               ,c_ext_attr27,c_ext_attr28,c_ext_attr29,c_ext_attr30,c_ext_attr31,c_ext_attr32
                                               ,c_ext_attr33,c_ext_attr34,c_ext_attr35,c_ext_attr36,c_ext_attr37,c_ext_attr38
                                               ,c_ext_attr39,c_ext_attr40,c_ext_attr41,c_ext_attr42,c_ext_attr43,c_ext_attr44
                                               ,c_ext_attr45,c_ext_attr46,c_ext_attr47,c_ext_attr48,c_ext_attr49,c_ext_attr50
                                               ,batch_id,org_id,request_id,line_level_comment,dept_desc
                                               ,dept_sft_hdr,dept_code, parent_cust_doc_id,extract_batch_id,line_tax_amt
											   ,kit_sku  -- Added for Kitting, Defect# 37675
											   ,kit_sku_desc  -- Added for Kitting, Defect# 37675
											   ,sku_level_tax   -- Added for SKU level Tax changes NAIT 58403
			                                   ,sku_level_total -- Added for SKU level Tax changes NAIT 58403
                                               )
          SELECT XAECDM.cons_inv_id,XAECDM.customer_trx_id,XAECDM.cust_doc_id,XAECDM.customer_trx_line_id,XAECDM.trx_line_number
                ,XAECDM.trx_line_type,XAECDM.item_description,XAECDM.inventory_item_id,XAECDM.inventory_item_number
                ,XAECDM.translated_description,XAECDM.order_line_id,XAECDM.po_line_number,XAECDM.quantity_back_ordered
                ,XAECDM.quantity_credited,XAECDM.quantity_invoiced,XAECDM.quantity_ordered,XAECDM.quantity_shipped
                ,XAECDM.unit_of_measure,XAECDM.unit_price,XAECDM.ext_price,XAECDM.contract_plan_id,XAECDM.contract_seq_number
                ,XAECDM.entered_product_code,XAECDM.vendor_product_code,XAECDM.customer_product_code,XAECDM.discount_code
                ,XAECDM.elec_detail_seq_number,XAECDM.elec_record_type,XAECDM.wholesaler_item,XAECDM.detail_rec_taxable_flag
                ,XAECDM.gsa_comments,XAECDM.interface_line_context,XAECDM.price_adjustment_id,fnd_profile.value('user_id')
                ,sysdate,fnd_profile.value('user_id'),sysdate,fnd_profile.value('login_id'),XAECDM.c_ext_attr1,XAECDM.c_ext_attr2
                ,XAECDM.c_ext_attr3,XAECDM.c_ext_attr4,XAECDM.c_ext_attr5,XAECDM.c_ext_attr6,XAECDM.c_ext_attr7,XAECDM.c_ext_attr8
                ,XAECDM.c_ext_attr9,XAECDM.c_ext_attr10,XAECDM.c_ext_attr11,XAECDM.c_ext_attr12,XAECDM.c_ext_attr13,XAECDM.c_ext_attr14
                ,XAECDM.c_ext_attr15,XAECDM.c_ext_attr16,XAECDM.c_ext_attr17,XAECDM.c_ext_attr18,XAECDM.c_ext_attr19,XAECDM.c_ext_attr20
                ,XAECDM.c_ext_attr21,XAECDM.c_ext_attr22,XAECDM.c_ext_attr23,XAECDM.c_ext_attr24,XAECDM.c_ext_attr25,XAECDM.c_ext_attr26
                ,XAECDM.c_ext_attr27,XAECDM.c_ext_attr28,XAECDM.c_ext_attr29,XAECDM.c_ext_attr30,XAECDM.c_ext_attr31,XAECDM.c_ext_attr32
                ,XAECDM.c_ext_attr33,XAECDM.c_ext_attr34,XAECDM.c_ext_attr35,XAECDM.c_ext_attr36,XAECDM.c_ext_attr37,XAECDM.c_ext_attr38
                ,XAECDM.c_ext_attr39,XAECDM.c_ext_attr40,XAECDM.c_ext_attr41,XAECDM.c_ext_attr42,XAECDM.c_ext_attr43,XAECDM.c_ext_attr44
                ,XAECDM.c_ext_attr45,XAECDM.c_ext_attr46,XAECDM.c_ext_attr47,XAECDM.c_ext_attr48,XAECDM.c_ext_attr49,XAECDM.c_ext_attr50
                ,XAECDM.batch_id,XAECDM.org_id,p_request_id,XAECDM.line_level_comment,XAECDM.dept_desc
                ,XAECDM.dept_sft_hdr,XAECDM.dept_code,XAECDM.parent_cust_doc_id,XAECDM.extract_batch_id,XAECDM.line_tax_amt
				,XAECDM.kit_sku  -- Added for Kitting, Defect# 37675
				,XAECDM.kit_sku_desc  -- Added for Kitting, Defect# 37675
				,XAECDM.sku_level_tax   -- Added for SKU level Tax changes NAIT 58403
			    ,XAECDM.sku_level_total -- Added for SKU level Tax changes NAIT 58403
          FROM   xx_ar_ebl_cons_hdr_main   XAECHM
                ,xx_ar_ebl_cons_dtl_main   XAECDM
                ,xx_ar_ebl_file            XAEF
          WHERE  XAECHM.batch_id                 = p_batch_id
          AND    XAECHM.org_id                   = ln_org_id
          AND    XAECHM.customer_trx_id          = XAECDM.customer_trx_id
          AND    XAECHM.cust_doc_id              = XAECDM.cust_doc_id
          AND    XAECHM.cons_inv_id              = XAECDM.cons_inv_id
          AND    XAECHM.billdocs_delivery_method = p_delivery_meth
          AND    XAECHM.file_id                  = XAEF.file_id
          AND    XAECHM.transmission_id          = XAEF.transmission_id
          AND    XAEF.status                     = lc_status;
          PUT_LOG_LINE ( lb_debug
                        ,TRUE
                        ,'Number of trx lines inserted into dtl hist table for the Batch ID : '||p_batch_id||' are : '||SQL%ROWCOUNT
                        );

          lc_error_loc := 'Inserting into Consolidated Header History Table ';
          INSERT INTO xx_ar_ebl_cons_hdr_hist ( cons_inv_id,customer_trx_id,mbs_doc_id,consolidated_bill_number
                                               ,billdocs_delivery_method,document_type,direct_flag,cust_doc_id
                                               ,bill_from_date,bill_to_date,mail_to_attention,invoice_number
                                               ,original_order_number,original_invoice_amount,amount_due_remaining
                                               ,gross_sale_amount,tax_rate,credit_memo_reason,amount_applied
                                               ,invoice_bill_date,bill_due_date,invoice_currency_code,order_date
                                               ,reconcile_date,order_header_id,order_level_comment,order_level_spc_comment
                                               ,order_type,order_type_code,ordered_by,payment_term,payment_term_description
                                               ,payment_term_discount,payment_term_discount_date,payment_term_frequency,payment_term_report_day
                                               ,payment_term_string,total_bulk_amount,total_coupon_amount,total_discount_amount
                                               ,total_freight_amount,total_gift_card_amount,total_gst_amount,total_hst_amount
                                               ,total_miscellaneous_amount,total_pst_amount,total_qst_amount,total_tiered_discount_amount
                                               ,total_us_tax_amount,sku_lines_subtotal,sales_person,cust_account_id
                                               ,oracle_account_number,customer_name,aops_account_number,cust_acct_site_id
                                               ,cust_site_sequence,customer_ref_date,customer_ref_number,sold_to_customer_number
                                               ,transaction_source,transaction_type,transaction_class,transaction_date
                                               ,bill_to_name,bill_to_address1,bill_to_address2,bill_to_address3,bill_to_address4
                                               ,bill_to_city,bill_to_state,bill_to_country,bill_to_zip,bill_to_contact_name
                                               ,bill_to_contact_phone,bill_to_contact_phone_ext,bill_to_contact_email,bill_to_abbreviation
                                               ,carrier,ship_to_name,ship_to_abbreviation,ship_to_address1,ship_to_address2,ship_to_address3
                                               ,ship_to_address4,ship_to_city,ship_to_state,ship_to_country,ship_to_zip
                                               ,ship_to_sequence,shipment_ref_number,remit_address1,remit_address2,remit_address3
                                               ,remit_address4,remit_city,remit_state,remit_zip,remit_country,us_federal_id
                                               ,canadian_tax_number,cost_center_sft_hdr,po_number_sft_hdr,release_number_sft_hdr,desktop_sft_hdr
                                               ,number_of_lines,last_updated_by,last_updated_date,created_by,creation_date,last_updated_login
                                               ,c_ext_attr1,c_ext_attr2,c_ext_attr3,c_ext_attr4,c_ext_attr5,c_ext_attr6,c_ext_attr7
                                               ,c_ext_attr8,c_ext_attr9,c_ext_attr10,c_ext_attr11,c_ext_attr12,c_ext_attr13,c_ext_attr14
                                               ,c_ext_attr15,c_ext_attr16,c_ext_attr17,c_ext_attr18,c_ext_attr19,c_ext_attr20
                                               ,c_ext_attr21,c_ext_attr22,c_ext_attr23,c_ext_attr24,c_ext_attr25,c_ext_attr26
                                               ,c_ext_attr27,c_ext_attr28,c_ext_attr29,c_ext_attr30,c_ext_attr31,c_ext_attr32
                                               ,c_ext_attr33,c_ext_attr34,c_ext_attr35,c_ext_attr36,c_ext_attr37,c_ext_attr38
                                               ,c_ext_attr39,c_ext_attr40,c_ext_attr41,c_ext_attr42,c_ext_attr43,c_ext_attr44
                                               ,c_ext_attr45,c_ext_attr46,c_ext_attr47,c_ext_attr48,c_ext_attr49,c_ext_attr50
                                               ,batch_id,file_id,transmission_id,file_name,org_id,bill_to_site_use_id,parent_cust_doc_id
                                               ,epdf_doc_level,request_id,trx_number,desktop_sft_data,po_number_sft_data,cost_center_sft_data
                                               ,RELEASE_NUMBER_SFT_DATA,ACCOUNT_CONTACT,ORDER_CONTACT,INFOCOPY_TAG,SPLIT_IDENTIFIER,EMAIL_ADDRESS
                                               ,total_association_discount,batch_source_id,status,extract_batch_id,order_source_code,dept_desc  -- dept_desc added as per Defect # 15118
											   ,dept_code -- Added for Defect 36437
                                               )
          SELECT XAECHM.cons_inv_id,XAECHM.customer_trx_id,XAECHM.mbs_doc_id,XAECHM.consolidated_bill_number
                ,XAECHM.billdocs_delivery_method,XAECHM.document_type,XAECHM.direct_flag,XAECHM.cust_doc_id
                ,XAECHM.bill_from_date,XAECHM.bill_to_date,XAECHM.mail_to_attention,XAECHM.invoice_number
                ,XAECHM.original_order_number,XAECHM.original_invoice_amount,XAECHM.amount_due_remaining
                ,XAECHM.gross_sale_amount,XAECHM.tax_rate,XAECHM.credit_memo_reason,XAECHM.amount_applied
                ,XAECHM.invoice_bill_date,XAECHM.bill_due_date,XAECHM.invoice_currency_code,XAECHM.order_date
                ,XAECHM.reconcile_date,XAECHM.order_header_id,XAECHM.order_level_comment,XAECHM.order_level_spc_comment
                ,XAECHM.order_type,XAECHM.order_type_code,XAECHM.ordered_by,XAECHM.payment_term,XAECHM.payment_term_description
                ,XAECHM.payment_term_discount,XAECHM.payment_term_discount_date,XAECHM.payment_term_frequency,XAECHM.payment_term_report_day
                ,XAECHM.payment_term_string,XAECHM.total_bulk_amount,XAECHM.total_coupon_amount,XAECHM.total_discount_amount
                ,XAECHM.total_freight_amount,XAECHM.total_gift_card_amount,XAECHM.total_gst_amount,XAECHM.total_hst_amount
                ,XAECHM.total_miscellaneous_amount,XAECHM.total_pst_amount,XAECHM.total_qst_amount,XAECHM.total_tiered_discount_amount
                ,XAECHM.total_us_tax_amount,XAECHM.sku_lines_subtotal,XAECHM.sales_person,XAECHM.cust_account_id
                ,XAECHM.oracle_account_number,XAECHM.customer_name,XAECHM.aops_account_number,XAECHM.cust_acct_site_id
                ,XAECHM.cust_site_sequence,XAECHM.customer_ref_date,XAECHM.customer_ref_number,XAECHM.sold_to_customer_number
                ,XAECHM.transaction_source,XAECHM.transaction_type,XAECHM.transaction_class,XAECHM.transaction_date
                ,XAECHM.bill_to_name,XAECHM.bill_to_address1,XAECHM.bill_to_address2,XAECHM.bill_to_address3,XAECHM.bill_to_address4
                ,XAECHM.bill_to_city,XAECHM.bill_to_state,XAECHM.bill_to_country,XAECHM.bill_to_zip,XAECHM.bill_to_contact_name
                ,XAECHM.bill_to_contact_phone,XAECHM.bill_to_contact_phone_ext,XAECHM.bill_to_contact_email,XAECHM.bill_to_abbreviation
                ,XAECHM.carrier,XAECHM.ship_to_name,XAECHM.ship_to_abbreviation,XAECHM.ship_to_address1,XAECHM.ship_to_address2,XAECHM.ship_to_address3
                ,XAECHM.ship_to_address4,XAECHM.ship_to_city,XAECHM.ship_to_state,XAECHM.ship_to_country,XAECHM.ship_to_zip
                ,XAECHM.ship_to_sequence,XAECHM.shipment_ref_number,XAECHM.remit_address1,XAECHM.remit_address2,XAECHM.remit_address3
                ,XAECHM.remit_address4,XAECHM.remit_city,XAECHM.remit_state,XAECHM.remit_zip,XAECHM.remit_country,XAECHM.us_federal_id
                ,XAECHM.canadian_tax_number,XAECHM.cost_center_sft_hdr,XAECHM.po_number_sft_hdr,XAECHM.release_number_sft_hdr,XAECHM.desktop_sft_hdr
                ,XAECHM.number_of_lines,fnd_profile.value('user_id'),sysdate,fnd_profile.value('user_id'),sysdate,fnd_profile.value('login_id')
                ,XAECHM.c_ext_attr1,XAECHM.c_ext_attr2,XAECHM.c_ext_attr3,XAECHM.c_ext_attr4,XAECHM.c_ext_attr5,XAECHM.c_ext_attr6,XAECHM.c_ext_attr7
                ,XAECHM.c_ext_attr8,XAECHM.c_ext_attr9,XAECHM.c_ext_attr10,XAECHM.c_ext_attr11,XAECHM.c_ext_attr12,XAECHM.c_ext_attr13,XAECHM.c_ext_attr14
                ,XAECHM.c_ext_attr15,XAECHM.c_ext_attr16,XAECHM.c_ext_attr17,XAECHM.c_ext_attr18,XAECHM.c_ext_attr19,XAECHM.c_ext_attr20
                ,XAECHM.c_ext_attr21,XAECHM.c_ext_attr22,XAECHM.c_ext_attr23,XAECHM.c_ext_attr24,XAECHM.c_ext_attr25,XAECHM.c_ext_attr26
                ,XAECHM.c_ext_attr27,XAECHM.c_ext_attr28,XAECHM.c_ext_attr29,XAECHM.c_ext_attr30,XAECHM.c_ext_attr31,XAECHM.c_ext_attr32
                ,XAECHM.c_ext_attr33,XAECHM.c_ext_attr34,XAECHM.c_ext_attr35,XAECHM.c_ext_attr36,XAECHM.c_ext_attr37,XAECHM.c_ext_attr38
                ,XAECHM.c_ext_attr39,XAECHM.c_ext_attr40,XAECHM.c_ext_attr41,XAECHM.c_ext_attr42,XAECHM.c_ext_attr43,XAECHM.c_ext_attr44
                ,XAECHM.c_ext_attr45,XAECHM.c_ext_attr46,XAECHM.c_ext_attr47,XAECHM.c_ext_attr48,XAECHM.c_ext_attr49,XAECHM.c_ext_attr50
                ,XAECHM.batch_id,XAECHM.file_id,XAECHM.transmission_id,XAECHM.file_name,XAECHM.org_id,XAECHM.bill_to_site_use_id,XAECHM.parent_cust_doc_id
                ,XAECHM.epdf_doc_level,p_request_id,XAECHM.trx_number,XAECHM.desktop_sft_data,XAECHM.po_number_sft_data,XAECHM.cost_center_sft_data
                ,XAECHM.RELEASE_NUMBER_SFT_DATA,XAECHM.ACCOUNT_CONTACT,XAECHM.ORDER_CONTACT,XAECHM.INFOCOPY_TAG,XAECHM.SPLIT_IDENTIFIER,XAECHM.EMAIL_ADDRESS
                ,XAECHM.total_association_discount,XAECHM.batch_source_id,'RENDERED',XAECHM.extract_batch_id,XAECHM.order_source_code,XAECHM.dept_desc
				,XAECHM.dept_code -- Added for Defect 36437
          FROM   xx_ar_ebl_cons_hdr_main   XAECHM
                ,xx_ar_ebl_file            XAEF
          WHERE  XAECHM.batch_id                 = p_batch_id
          AND    XAECHM.org_id                   = ln_org_id
          AND    XAECHM.billdocs_delivery_method = p_delivery_meth
          AND    XAEF.file_id                    = XAECHM.file_id
          AND    XAEF.transmission_id            = XAECHM.transmission_id
          AND    XAEF.status                     = lc_status;
          PUT_LOG_LINE ( lb_debug
                        ,TRUE
                        ,'Number of trxs inserted into hdr hist table for the Batch ID : '||p_batch_id||' are : '||SQL%ROWCOUNT
                        );

          lc_error_loc := 'Deleting from Consolidated Detail Main Table ';
          DELETE xx_ar_ebl_cons_dtl_main   XAECDM
          WHERE  EXISTS      (SELECT /*+ leading(XAEF) */ 1
                              FROM   xx_ar_ebl_cons_hdr_main XAECHM
                                    ,xx_ar_ebl_file          XAEF
                              WHERE  XAECHM.customer_trx_id              = XAECDM.customer_trx_id
                              AND    XAECHM.CONS_INV_ID                  = XAECDM.CONS_INV_ID
                              AND    XAECHM.cust_doc_id                  = XAECDM.cust_doc_id
                              AND    XAECHM.batch_id                     = p_batch_id
                              AND    XAECHM.org_id                       = ln_org_id
                              AND    XAECHM.billdocs_delivery_method     = p_delivery_meth
                              AND    XAECHM.file_id                      = XAEF.file_id
                              AND    XAECHM.transmission_id              = XAEF.transmission_id
                              AND    XAEF.status                         = lc_status
                              );
          PUT_LOG_LINE ( lb_debug
                        ,TRUE
                        ,'Number of trx lines deleted from dtl table for the Batch ID : '||p_batch_id||' are : '||SQL%ROWCOUNT
                        );

          lc_error_loc := 'Deleting from Consolidated Header Main Table ';
          DELETE xx_ar_ebl_cons_hdr_main    XAECHM
          WHERE  XAECHM.batch_id                 = p_batch_id
          AND    XAECHM.org_id                   = ln_org_id
          AND    XAECHM.billdocs_delivery_method = p_delivery_meth
          AND    EXISTS (SELECT 1
                         FROM   xx_ar_ebl_file  XAEF
                         WHERE  XAEF.file_id           = XAECHM.file_id
                         AND    XAEF.transmission_id   = XAECHM.transmission_id
                         AND    XAEF.status            = lc_status
                         );
          PUT_LOG_LINE ( lb_debug
                        ,TRUE
                        ,'Number of trxs deleted from dtl table for the Batch ID : '||p_batch_id||' are : '||SQL%ROWCOUNT
                        );

       ELSIF p_doc_type = 'IND' THEN

          lc_error_loc := 'Updating RA Customer TRX Table ';
          UPDATE ra_customer_trx RCT
          SET    RCT.printing_pending                  = 'N'
                ,RCT.printing_count                    = NVL(RCT.printing_count, 0) + 1
                ,RCT.printing_last_printed             = SYSDATE
                ,RCT.printing_original_date            = DECODE( RCT.printing_count
                                                                ,0,SYSDATE
                                                                ,NULL,SYSDATE
                                                                ,RCT.printing_original_date
                                                                )
                ,RCT.last_printed_sequence_num         = '1'
                ,RCT.last_updated_by                   = FND_GLOBAL.USER_ID
                ,RCT.last_update_date                  = SYSDATE
                ,RCT.last_update_login                 = FND_GLOBAL.USER_ID
                ,RCT.program_id                        = FND_GLOBAL.CONC_PROGRAM_ID
                ,RCT.request_id                        = p_request_id
          WHERE  EXISTS (SELECT 1
                         FROM   xx_ar_ebl_ind_hdr_main XAEIHM
                               ,xx_ar_ebl_file         XAEF
                         WHERE  XAEIHM.customer_trx_id          = RCT.customer_trx_id
                         AND    XAEIHM.document_type            = 'Paydoc'
                         AND    XAEIHM.batch_id                 = p_batch_id
                         AND    XAEIHM.org_id                   = ln_org_id
                         AND    XAEIHM.billdocs_delivery_method = p_delivery_meth
                         AND    XAEIHM.file_id                  = XAEF.file_id
                         AND    XAEIHM.transmission_id          = XAEF.transmission_id
                         AND    XAEF.status                     = lc_status
                         );
          PUT_LOG_LINE ( lb_debug
                        ,TRUE
                        ,'Number of trx updated for the Batch ID : '||p_batch_id||' are : '||SQL%ROWCOUNT
                        );

          lc_error_loc := 'Inserting into AR Invoice Frequency History Table ';
          INSERT INTO xx_ar_invoice_freq_history (document_id,customer_document_id,paydoc_flag,doc_delivery_method,doc_combo_type,invoice_id
                                                       ,org_id,estimated_print_date,actual_print_date,printed_flag,billdocs_special_handling
                                                       ,bill_to_customer_id,bill_to_customer_number,extension_id,billdocs_payment_term,attribute1
                                                       ,attribute2,attribute3,attribute4,attribute5,attribute6,request_id,request_date,last_update_date
                                                       ,last_updated_by,creation_date,created_by,last_update_login,site_use_id,parent_cust_acct_id,parent_cust_doc_id
                                                       ,mail_to_attention,direct_flag,amount_due_original,amount_due_remaining,due_date,batch_id,status
                                                       )
          SELECT        xaif.document_id,xaif.customer_document_id,xaif.paydoc_flag,xaif.doc_delivery_method,xaif.doc_combo_type,xaif.invoice_id
                       ,xaif.org_id,xaif.estimated_print_date,sysdate,'Y',xaif.billdocs_special_handling
                       ,xaif.bill_to_customer_id,xaif.bill_to_customer_number,xaif.extension_id,xaif.billdocs_payment_term,p_request_id
                       ,xaif.attribute2,xaif.attribute3,xaif.attribute4,xaif.attribute5,xaif.attribute6,substr(p_batch_id,1,instr(p_batch_id,'.')-1),sysdate,sysdate
                       ,fnd_profile.value('user_id'),sysdate,fnd_profile.value('user_id'),fnd_profile.value('login_id'),xaif.site_use_id,xaif.parent_cust_acct_id,xaif.parent_cust_doc_id
                       ,xaif.mail_to_attention,xaif.direct_flag,xaif.amount_due_original,xaif.amount_due_remaining,xaif.due_date,xaif.batch_id,'COMPLETE'
          FROM          xx_ar_invoice_frequency   XAIF
                       ,xx_ar_ebl_ind_hdr_main    XAEIHM
                       ,xx_ar_ebl_file            XAEF
          WHERE         XAIF.status                     = 'IN PROCESS'
          AND           XAIF.invoice_id                 = XAEIHM.customer_trx_id
          AND           XAIF.customer_document_id       = XAEIHM.cust_doc_id
          AND           XAEIHM.batch_id                 = p_batch_id
          AND           XAEIHM.billdocs_delivery_method = p_delivery_meth
          AND           XAEIHM.file_id                  = XAEF.file_id
          AND           XAEIHM.transmission_id          = XAEF.transmission_id
          AND           XAEF.status                     = lc_status;
          PUT_LOG_LINE ( lb_debug
                        ,TRUE
                        ,'Number of trx inserted into freq hist table for the Batch ID : '||p_batch_id||' are : '||SQL%ROWCOUNT
                        );

          lc_error_loc := 'Deleting from AR Invoice Frequency Table ';
          DELETE xx_ar_invoice_frequency     XAIF
          WHERE  status      = 'IN PROCESS'
          AND    EXISTS      (SELECT 1
                              FROM   xx_ar_ebl_ind_hdr_main XAEIHM
                                    ,xx_ar_ebl_file         XAEF
                              WHERE  XAEIHM.customer_trx_id              = XAIF.invoice_id
                              AND    XAEIHM.cust_doc_id                  = XAIF.customer_document_id
                              AND    XAEIHM.batch_id                     = p_batch_id
                              AND    XAEIHM.org_id                       = ln_org_id
                              AND    XAEIHM.billdocs_delivery_method     = p_delivery_meth
                              AND    XAEIHM.file_id                      = XAEF.file_id
                              AND    XAEIHM.transmission_id              = XAEF.transmission_id
                              AND    XAEF.status                         = lc_status
                              );
          PUT_LOG_LINE ( lb_debug
                        ,TRUE
                        ,'Number of trx deleted from freq table for the Batch ID : '||p_batch_id||' are : '||SQL%ROWCOUNT
                        );

          lc_error_loc := 'Inserting into Individual Detail History Table ';
          INSERT INTO xx_ar_ebl_ind_dtl_hist ( customer_trx_id,cust_doc_id,customer_trx_line_id,trx_line_number,trx_line_type
                                              ,item_description,inventory_item_id,inventory_item_number,translated_description,order_line_id
                                              ,po_line_number,quantity_back_ordered,quantity_credited,quantity_invoiced,quantity_ordered
                                              ,quantity_shipped,unit_of_measure,unit_price,ext_price,contract_plan_id,contract_seq_number
                                              ,entered_product_code,vendor_product_code,customer_product_code,discount_code,elec_detail_seq_number
                                              ,elec_record_type,wholesaler_item,detail_rec_taxable_flag,gsa_comments,interface_line_context
                                              ,price_adjustment_id,dept_sft_hdr,last_updated_by,last_updated_date,created_by,creation_date
                                              ,last_updated_login,c_ext_attr1,c_ext_attr2,c_ext_attr3,c_ext_attr4,c_ext_attr5,c_ext_attr6
                                              ,c_ext_attr7,c_ext_attr8,c_ext_attr9,c_ext_attr10,c_ext_attr11,c_ext_attr12,c_ext_attr13,c_ext_attr14
                                              ,c_ext_attr15,c_ext_attr16,c_ext_attr17,c_ext_attr18,c_ext_attr19,c_ext_attr20,c_ext_attr21,c_ext_attr22
                                              ,c_ext_attr23,c_ext_attr24,c_ext_attr25,c_ext_attr26,c_ext_attr27,c_ext_attr28,c_ext_attr29,c_ext_attr30
                                              ,c_ext_attr31,c_ext_attr32,c_ext_attr33,c_ext_attr34,c_ext_attr35,c_ext_attr36,c_ext_attr37,c_ext_attr38
                                              ,c_ext_attr39,c_ext_attr40,c_ext_attr41,c_ext_attr42,c_ext_attr43,c_ext_attr44,c_ext_attr45,c_ext_attr46
                                              ,c_ext_attr47,c_ext_attr48,c_ext_attr49,c_ext_attr50,batch_id,org_id,line_level_comment
                                              ,dept_desc,parent_cust_doc_id,extract_batch_id, dept_code -- Added for Defect 36437
                                              ,line_tax_amt
											  ,kit_sku -- Added for Kitting, Defect# 37675
											  ,kit_sku_desc -- Added for Kitting, Defect# 37675
											  ,sku_level_tax   -- Added for SKU level Tax changes NAIT 58403
			                                  ,sku_level_total -- Added for SKU level Tax changes NAIT 58403
                                              )
          SELECT XAEIDM.customer_trx_id,XAEIDM.cust_doc_id,XAEIDM.customer_trx_line_id,XAEIDM.trx_line_number,XAEIDM.trx_line_type
                ,XAEIDM.item_description,XAEIDM.inventory_item_id,XAEIDM.inventory_item_number,XAEIDM.translated_description,XAEIDM.order_line_id
                ,XAEIDM.po_line_number,XAEIDM.quantity_back_ordered,XAEIDM.quantity_credited,XAEIDM.quantity_invoiced,XAEIDM.quantity_ordered
                ,XAEIDM.quantity_shipped,XAEIDM.unit_of_measure,XAEIDM.unit_price,XAEIDM.ext_price,XAEIDM.contract_plan_id,XAEIDM.contract_seq_number
                ,XAEIDM.entered_product_code,XAEIDM.vendor_product_code,XAEIDM.customer_product_code,XAEIDM.discount_code,XAEIDM.elec_detail_seq_number
                ,XAEIDM.elec_record_type,XAEIDM.wholesaler_item,XAEIDM.detail_rec_taxable_flag,XAEIDM.gsa_comments,XAEIDM.interface_line_context
                ,XAEIDM.price_adjustment_id,XAEIDM.dept_sft_hdr,fnd_profile.value('user_id'),sysdate,fnd_profile.value('user_id'),sysdate
                ,fnd_profile.value('login_id'),XAEIDM.c_ext_attr1,XAEIDM.c_ext_attr2,XAEIDM.c_ext_attr3,XAEIDM.c_ext_attr4,XAEIDM.c_ext_attr5,XAEIDM.c_ext_attr6
                ,XAEIDM.c_ext_attr7,XAEIDM.c_ext_attr8,XAEIDM.c_ext_attr9,XAEIDM.c_ext_attr10,XAEIDM.c_ext_attr11,XAEIDM.c_ext_attr12,XAEIDM.c_ext_attr13,XAEIDM.c_ext_attr14
                ,XAEIDM.c_ext_attr15,XAEIDM.c_ext_attr16,XAEIDM.c_ext_attr17,XAEIDM.c_ext_attr18,XAEIDM.c_ext_attr19,XAEIDM.c_ext_attr20,XAEIDM.c_ext_attr21,XAEIDM.c_ext_attr22
                ,XAEIDM.c_ext_attr23,XAEIDM.c_ext_attr24,XAEIDM.c_ext_attr25,XAEIDM.c_ext_attr26,XAEIDM.c_ext_attr27,XAEIDM.c_ext_attr28,XAEIDM.c_ext_attr29,XAEIDM.c_ext_attr30
                ,XAEIDM.c_ext_attr31,XAEIDM.c_ext_attr32,XAEIDM.c_ext_attr33,XAEIDM.c_ext_attr34,XAEIDM.c_ext_attr35,XAEIDM.c_ext_attr36,XAEIDM.c_ext_attr37,XAEIDM.c_ext_attr38
                ,XAEIDM.c_ext_attr39,XAEIDM.c_ext_attr40,XAEIDM.c_ext_attr41,XAEIDM.c_ext_attr42,XAEIDM.c_ext_attr43,XAEIDM.c_ext_attr44,XAEIDM.c_ext_attr45,XAEIDM.c_ext_attr46
                ,XAEIDM.c_ext_attr47,XAEIDM.c_ext_attr48,XAEIDM.c_ext_attr49,XAEIDM.c_ext_attr50,XAEIDM.batch_id,XAEIDM.org_id,XAEIDM.line_level_comment
                ,XAEIDM.dept_desc,XAEIDM.parent_cust_doc_id,XAEIDM.extract_batch_id, XAEIDM.dept_code -- Added for Defect 36437
                ,XAEIDM.line_tax_amt
				,XAEIDM.kit_sku -- Added for Kitting, Defect# 37675
				,XAEIDM.kit_sku_desc -- Added for Kitting, Defect# 37675
				,XAEIDM.sku_level_tax   -- Added for SKU level Tax changes NAIT 58403
			    ,XAEIDM.sku_level_total -- Added for SKU level Tax changes NAIT 58403
          FROM   xx_ar_ebl_ind_hdr_main   XAEIHM
                ,xx_ar_ebl_ind_dtl_main   XAEIDM
                ,xx_ar_ebl_file           XAEF
          WHERE  XAEIHM.batch_id                 = p_batch_id
          AND    XAEIHM.org_id                   = ln_org_id
          AND    XAEIHM.customer_trx_id          = XAEIDM.customer_trx_id
          AND    XAEIHM.cust_doc_id              = XAEIDM.cust_doc_id
          AND    XAEIHM.billdocs_delivery_method = p_delivery_meth
          AND    XAEIHM.file_id                  = XAEF.file_id
          AND    XAEIHM.transmission_id          = XAEF.transmission_id
          AND    XAEF.status                     = lc_status;
          PUT_LOG_LINE ( lb_debug
                        ,TRUE
                        ,'Number of trx lines inserted into dtl hist table for the Batch ID : '||p_batch_id||' are : '||SQL%ROWCOUNT
                        );

          lc_error_loc := 'Inserting into Individual Header History Table ';
          INSERT INTO xx_ar_ebl_ind_hdr_hist (customer_trx_id,cust_doc_id,mbs_doc_id,billdocs_delivery_method,document_type
                                             ,direct_flag,bill_from_date,bill_to_date,mail_to_attention,invoice_number
                                             ,original_order_number,original_invoice_amount,amount_due_remaining,gross_sale_amount
                                             ,tax_rate,credit_memo_reason,invoice_bill_date,bill_due_date,invoice_currency_code
                                             ,order_date,reconcile_date,order_header_id,order_level_comment,order_level_spc_comment
                                             ,order_type,order_type_code,ordered_by,payment_term,payment_term_description
                                             ,payment_term_discount,payment_term_discount_date,payment_term_frequency,payment_term_report_day
                                             ,payment_term_string,total_bulk_amount,total_coupon_amount,total_discount_amount,total_freight_amount
                                             ,total_gift_card_amount,total_gst_amount,total_hst_amount,total_miscellaneous_amount,total_pst_amount
                                             ,total_qst_amount,total_tiered_discount_amount,total_us_tax_amount,sku_lines_subtotal,sales_person
                                             ,cust_account_id,oracle_account_number,customer_name,aops_account_number,cust_acct_site_id,cust_site_sequence
                                             ,customer_ref_date,customer_ref_number,sold_to_customer_number,transaction_source,transaction_type
                                             ,transaction_class,transaction_date,bill_to_name,bill_to_address1,bill_to_address2,bill_to_address3
                                             ,bill_to_address4,bill_to_city,bill_to_state,bill_to_country,bill_to_zip,bill_to_contact_name
                                             ,bill_to_contact_phone,bill_to_contact_phone_ext,bill_to_contact_email,bill_to_abbreviation
                                             ,carrier,ship_to_name,ship_to_abbreviation
                                             ,ship_to_address1,ship_to_address2,ship_to_address3,ship_to_address4,ship_to_city,ship_to_state,ship_to_country
                                             ,ship_to_zip,ship_to_sequence,shipment_ref_number,remit_address1,remit_address2,remit_address3,remit_address4
                                             ,remit_city,remit_state,remit_zip,us_federal_id,canadian_tax_number,cost_center_sft_hdr,po_number_sft_hdr
                                             ,release_number_sft_hdr,desktop_sft_hdr,number_of_lines,last_updated_by,last_updated_date,created_by,creation_date
                                             ,last_updated_login,c_ext_attr1,c_ext_attr2,c_ext_attr3,c_ext_attr4,c_ext_attr5,c_ext_attr6,c_ext_attr7,c_ext_attr8
                                             ,c_ext_attr9,c_ext_attr10,c_ext_attr11,c_ext_attr12,c_ext_attr13,c_ext_attr14,c_ext_attr15,c_ext_attr16,c_ext_attr17
                                             ,c_ext_attr18,c_ext_attr19,c_ext_attr20,c_ext_attr21,c_ext_attr22,c_ext_attr23,c_ext_attr24,c_ext_attr25,c_ext_attr26
                                             ,c_ext_attr27,c_ext_attr28,c_ext_attr29,c_ext_attr30,c_ext_attr31,c_ext_attr32,c_ext_attr33,c_ext_attr34,c_ext_attr35
                                             ,c_ext_attr36,c_ext_attr37,c_ext_attr38,c_ext_attr39,c_ext_attr40,c_ext_attr41,c_ext_attr42,c_ext_attr43,c_ext_attr44
                                             ,c_ext_attr45,c_ext_attr46,c_ext_attr47,c_ext_attr48,c_ext_attr49,c_ext_attr50,batch_id,file_id,transmission_id
                                             ,file_name,org_id,bill_to_site_use_id,parent_cust_doc_id,epdf_doc_level,request_id,trx_number,desktop_sft_data
                                             ,po_number_sft_data,cost_center_sft_data,release_number_sft_data,account_contact,order_contact,total_delivery_amount
                                             ,BATCH_SOURCE_ID,EMAIL_ADDRESS,SPLIT_IDENTIFIER,TOTAL_ASSOCIATION_DISCOUNT,REMIT_COUNTRY,SALES_ORDER_NUMBER,STATUS,EXTRACT_BATCH_ID
                                             ,trx_term_description,order_source_code,dept_desc -- dept_desc added as per Defect # 15118
											 ,dept_code -- Added for Defect 36437
                                             )
          SELECT  XAEIHM.customer_trx_id,XAEIHM.cust_doc_id,XAEIHM.mbs_doc_id,XAEIHM.billdocs_delivery_method,XAEIHM.document_type
                 ,XAEIHM.direct_flag,XAEIHM.bill_from_date,XAEIHM.bill_to_date,XAEIHM.mail_to_attention,XAEIHM.invoice_number
                 ,XAEIHM.original_order_number,XAEIHM.original_invoice_amount,XAEIHM.amount_due_remaining,XAEIHM.gross_sale_amount
                 ,XAEIHM.tax_rate,XAEIHM.credit_memo_reason,XAEIHM.invoice_bill_date,XAEIHM.bill_due_date,XAEIHM.invoice_currency_code
                 ,XAEIHM.order_date,XAEIHM.reconcile_date,XAEIHM.order_header_id,XAEIHM.order_level_comment,XAEIHM.order_level_spc_comment
                 ,XAEIHM.order_type,XAEIHM.order_type_code,XAEIHM.ordered_by,XAEIHM.payment_term,XAEIHM.payment_term_description
                 ,XAEIHM.payment_term_discount,XAEIHM.payment_term_discount_date,XAEIHM.payment_term_frequency,XAEIHM.payment_term_report_day
                 ,XAEIHM.payment_term_string,XAEIHM.total_bulk_amount,XAEIHM.total_coupon_amount,XAEIHM.total_discount_amount,XAEIHM.total_freight_amount
                 ,XAEIHM.total_gift_card_amount,XAEIHM.total_gst_amount,XAEIHM.total_hst_amount,XAEIHM.total_miscellaneous_amount,XAEIHM.total_pst_amount
                 ,XAEIHM.total_qst_amount,XAEIHM.total_tiered_discount_amount,XAEIHM.total_us_tax_amount,XAEIHM.sku_lines_subtotal,XAEIHM.sales_person
                 ,XAEIHM.cust_account_id,XAEIHM.oracle_account_number,XAEIHM.customer_name,XAEIHM.aops_account_number,XAEIHM.cust_acct_site_id,XAEIHM.cust_site_sequence
                 ,XAEIHM.customer_ref_date,XAEIHM.customer_ref_number,XAEIHM.sold_to_customer_number,XAEIHM.transaction_source,XAEIHM.transaction_type
                 ,XAEIHM.transaction_class,XAEIHM.transaction_date,XAEIHM.bill_to_name,XAEIHM.bill_to_address1,XAEIHM.bill_to_address2,XAEIHM.bill_to_address3
                 ,XAEIHM.bill_to_address4,XAEIHM.bill_to_city,XAEIHM.bill_to_state,XAEIHM.bill_to_country,XAEIHM.bill_to_zip,XAEIHM.bill_to_contact_name,XAEIHM.bill_to_contact_phone
                 ,XAEIHM.bill_to_contact_phone_ext,XAEIHM.bill_to_contact_email,XAEIHM.bill_to_abbreviation
                 ,XAEIHM.carrier,XAEIHM.ship_to_name,XAEIHM.ship_to_abbreviation
                 ,XAEIHM.ship_to_address1,XAEIHM.ship_to_address2,XAEIHM.ship_to_address3,XAEIHM.ship_to_address4,XAEIHM.ship_to_city,XAEIHM.ship_to_state,XAEIHM.ship_to_country
                 ,XAEIHM.ship_to_zip,XAEIHM.ship_to_sequence,XAEIHM.shipment_ref_number,XAEIHM.remit_address1,XAEIHM.remit_address2,XAEIHM.remit_address3,XAEIHM.remit_address4
                 ,XAEIHM.remit_city,XAEIHM.remit_state,XAEIHM.remit_zip,XAEIHM.us_federal_id,XAEIHM.canadian_tax_number,XAEIHM.cost_center_sft_hdr,XAEIHM.po_number_sft_hdr
                 ,XAEIHM.release_number_sft_hdr,XAEIHM.desktop_sft_hdr,XAEIHM.number_of_lines,FND_PROFILE.VALUE('USER_ID'),SYSDATE,FND_PROFILE.VALUE('USER_ID'),SYSDATE
                 ,FND_PROFILE.VALUE('LOGIN_ID'),XAEIHM.c_ext_attr1,XAEIHM.c_ext_attr2,XAEIHM.c_ext_attr3,XAEIHM.c_ext_attr4,XAEIHM.c_ext_attr5,XAEIHM.c_ext_attr6,XAEIHM.c_ext_attr7,XAEIHM.c_ext_attr8
                 ,XAEIHM.c_ext_attr9,XAEIHM.c_ext_attr10,XAEIHM.c_ext_attr11,XAEIHM.c_ext_attr12,XAEIHM.c_ext_attr13,XAEIHM.c_ext_attr14,XAEIHM.c_ext_attr15,XAEIHM.c_ext_attr16,XAEIHM.c_ext_attr17
                 ,XAEIHM.c_ext_attr18,XAEIHM.c_ext_attr19,XAEIHM.c_ext_attr20,XAEIHM.c_ext_attr21,XAEIHM.c_ext_attr22,XAEIHM.c_ext_attr23,XAEIHM.c_ext_attr24,XAEIHM.c_ext_attr25,XAEIHM.c_ext_attr26
                 ,XAEIHM.c_ext_attr27,XAEIHM.c_ext_attr28,XAEIHM.c_ext_attr29,XAEIHM.c_ext_attr30,XAEIHM.c_ext_attr31,XAEIHM.c_ext_attr32,XAEIHM.c_ext_attr33,XAEIHM.c_ext_attr34,XAEIHM.c_ext_attr35
                 ,XAEIHM.c_ext_attr36,XAEIHM.c_ext_attr37,XAEIHM.c_ext_attr38,XAEIHM.c_ext_attr39,XAEIHM.c_ext_attr40,XAEIHM.c_ext_attr41,XAEIHM.c_ext_attr42,XAEIHM.c_ext_attr43,XAEIHM.c_ext_attr44
                 ,XAEIHM.c_ext_attr45,XAEIHM.c_ext_attr46,XAEIHM.c_ext_attr47,XAEIHM.c_ext_attr48,XAEIHM.c_ext_attr49,XAEIHM.c_ext_attr50,XAEIHM.batch_id,XAEIHM.file_id,XAEIHM.transmission_id
                 ,XAEIHM.file_name,XAEIHM.org_id,XAEIHM.bill_to_site_use_id,XAEIHM.parent_cust_doc_id,XAEIHM.epdf_doc_level,p_request_id,XAEIHM.trx_number,XAEIHM.desktop_sft_data
                 ,XAEIHM.po_number_sft_data,XAEIHM.cost_center_sft_data,XAEIHM.release_number_sft_data,XAEIHM.account_contact,XAEIHM.order_contact,XAEIHM.total_delivery_amount
                 ,XAEIHM.BATCH_SOURCE_ID,XAEIHM.EMAIL_ADDRESS,XAEIHM.SPLIT_IDENTIFIER,XAEIHM.TOTAL_ASSOCIATION_DISCOUNT
                 ,XAEIHM.remit_country,XAEIHM.sales_order_number,'RENDERED',XAEIHM.extract_batch_id,XAEIHM.trx_term_description,XAEIHM.order_source_code,XAEIHM.dept_desc
				 ,XAEIHM.dept_code -- Added for Defect 36437
          FROM   xx_ar_ebl_ind_hdr_main   XAEIHM
                ,xx_ar_ebl_file           XAEF
          WHERE  XAEIHM.batch_id                 = p_batch_id
          AND    XAEIHM.org_id                   = ln_org_id
          AND    XAEIHM.billdocs_delivery_method = p_delivery_meth
          AND    XAEIHM.file_id                  = XAEF.file_id
          AND    XAEIHM.transmission_id          = XAEF.transmission_id
          AND    XAEF.status                     = lc_status;
          PUT_LOG_LINE ( lb_debug
                        ,TRUE
                        ,'Number of trxs inserted into hdr hist table for the Batch ID : '||p_batch_id||' are : '||SQL%ROWCOUNT
                        );

          lc_error_loc := 'Deleting from Individual Detail Main Table ';
          DELETE xx_ar_ebl_ind_dtl_main   XAEIDM
          WHERE  EXISTS      (SELECT 1
                              FROM   xx_ar_ebl_ind_hdr_main XAEIHM
                                    ,xx_ar_ebl_file         XAEF
                              WHERE  XAEIHM.customer_trx_id              = XAEIDM.customer_trx_id
                              AND    XAEIHM.cust_doc_id                  = XAEIDM.cust_doc_id
                              AND    XAEIHM.batch_id                     = p_batch_id
                              AND    XAEIHM.org_id                       = ln_org_id
                              AND    XAEIHM.billdocs_delivery_method     = p_delivery_meth
                              AND    XAEIHM.file_id                      = XAEF.file_id
                              AND    XAEIHM.transmission_id              = XAEF.transmission_id
                              AND    XAEF.status                         = lc_status
                              );
          PUT_LOG_LINE ( lb_debug
                        ,TRUE
                        ,'Number of trx lines deleted from dtl table for the Batch ID : '||p_batch_id||' are : '||SQL%ROWCOUNT
                        );

          lc_error_loc := 'Deleting from Individual Header Main Table ';
          DELETE xx_ar_ebl_ind_hdr_main   XAEIHM
          WHERE  XAEIHM.batch_id                      = p_batch_id
          AND    XAEIHM.org_id                        = ln_org_id
          AND    XAEIHM.billdocs_delivery_method      = p_delivery_meth
          AND    EXISTS    (SELECT 1
                            FROM   xx_ar_ebl_file   XAEF
                            WHERE  XAEIHM.file_id                      = XAEF.file_id
                            AND    XAEIHM.transmission_id              = XAEF.transmission_id
                            AND    XAEF.status                         = lc_status
                            );
          PUT_LOG_LINE ( lb_debug
                        ,TRUE
                        ,'Number of trxs deleted from hdr table for the Batch ID : '||p_batch_id||' are : '||SQL%ROWCOUNT
                        );

       END IF;

    EXCEPTION
    WHEN OTHERS THEN
       PUT_LOG_LINE ( lb_debug
                     ,TRUE
                     ,'Error in UPDATE_BILL_STATUS function : ' ||SQLERRM
                     );
       PUT_LOG_LINE ( lb_debug
                     ,TRUE
                     ,'Error in ' || lc_error_loc
                     );
    RAISE;

    END UPDATE_BILL_STATUS;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : UPDATE_BILL_STATUS_eXLS                                             |
-- | Description : This procedure is used to updated standard table and delete and     |
-- |               and insert data into frequency and frequency history table          |
-- |               respectively for the delivery method eXLS                           |
-- | Parameters  :  p_file_id                                                          |
-- |               ,p_doc_type                                                         |
-- |               ,p_delivery_meth                                                    |
-- |               ,p_request_id                                                       |
-- |               ,p_debug_flag                                                       |
-- |                                                                                   |
-- |===============                                                                    |
-- |Version   Date            Author                  Remarks                          |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 10-Jun-2010  Parameswaran SN         Initial draft version for CR 586 -  |
-- |                                               Defect 2811                         |
-- |1.1       08-DEC-2015  Havish Kasina           Added new column dept_code in       |
-- |                                               xx_ar_ebl_cons_dtl_hist,            |
-- |                                               xx_ar_ebl_cons_hdr_hist             |
-- |                                               xx_ar_ebl_ind_dtl_hist and          |
-- |                                               xx_ar_ebl_ind_hdr_hist tables       |
-- |                                               -- Defect 36437                     |
-- |                                               (MOD 4B Release 3)                  |
-- |1.2       16-JUN-2016     Suresh Naragam          Mod 4B Release 4 changes         |
-- |1.3       23-JUN-2016  Havish Kasina           Added new column kit_sku in         |
-- |                                               xx_ar_ebl_cons_dtl_hist,            |
-- |                                               xx_ar_ebl_ind_dtl_hist              |
-- |                                               Defect 37675  (Kitting Changes)     |
-- |1.4      23-MAR-2018   Aniket J CG             Defect 22772  (Combo Type Changes)  |
-- |2.5      12-SEP-2018   Aarthi                  NAIT - 58403 Added SKU level columns|
-- |                                               to the history tables               |
-- +===================================================================================+
    PROCEDURE UPDATE_BILL_STATUS_eXLS ( p_file_id             NUMBER
                                       ,p_doc_type            VARCHAR2
                                       ,p_delivery_meth       VARCHAR2
                                       ,p_request_id          NUMBER
                                       ,p_debug_flag          VARCHAR2
                                       )
    IS
      lb_debug       BOOLEAN;
      lc_status      VARCHAR2(10)   := 'RENDERED';
      ln_org_id      NUMBER;
      lc_error_loc   VARCHAR2(4000);
    BEGIN
       IF p_debug_flag = 'Y' THEN
          lb_debug := TRUE;
       ELSE
          lb_debug := FALSE;
       END IF;

       ln_org_id     := FND_PROFILE.VALUE('ORG_ID');

       IF p_doc_type = 'CONS' THEN
          lc_error_loc := 'Updating AR Cons INV Table ';
          UPDATE ar_cons_inv   ACI
          SET    ACI.attribute12                     = p_request_id
                ,ACI.attribute14                     = p_delivery_meth
                ,ACI.attribute15                     = 'Y'
                ,ACI.attribute11                     = 'COMPLETE'
                ,ACI.last_updated_by                 = FND_GLOBAL.USER_ID
                ,ACI.last_update_date                = SYSDATE
                ,ACI.last_update_login               = FND_GLOBAL.USER_ID
          WHERE  EXISTS (SELECT 1
                         FROM   xx_ar_ebl_cons_hdr_main  XAECHM
                               ,xx_ar_ebl_file           XAEF
                         WHERE  XAECHM.cons_inv_id              = ACI.cons_inv_id
                         AND    XAECHM.document_type            = 'Paydoc'
                         AND    XAECHM.org_id                   = ln_org_id
                         AND    XAECHM.billdocs_delivery_method = p_delivery_meth
                         AND    XAEF.file_id                    = p_file_id
                         AND    XAECHM.file_id                  = XAEF.file_id
                         AND    XAECHM.transmission_id          = XAEF.transmission_id
                         AND    XAEF.status                     = lc_status
                         );
          PUT_LOG_LINE ( lb_debug
                        ,TRUE
                        ,'Number of consolidated Bill Updated for the file ID : '||p_file_id||' are : '||SQL%ROWCOUNT
                        );

          lc_error_loc := 'Inserting into Consolidated Detail History Table ';
          INSERT INTO xx_ar_ebl_cons_dtl_hist ( cons_inv_id,customer_trx_id,cust_doc_id,customer_trx_line_id,trx_line_number
                                               ,trx_line_type,item_description,inventory_item_id,inventory_item_number
                                               ,translated_description,order_line_id,po_line_number,quantity_back_ordered
                                               ,quantity_credited,quantity_invoiced,quantity_ordered,quantity_shipped
                                               ,unit_of_measure,unit_price,ext_price,contract_plan_id,contract_seq_number
                                               ,entered_product_code,vendor_product_code,customer_product_code,discount_code
                                               ,elec_detail_seq_number,elec_record_type,wholesaler_item,detail_rec_taxable_flag
                                               ,gsa_comments,interface_line_context,price_adjustment_id,last_updated_by
                                               ,last_updated_date,created_by,creation_date,last_updated_login,c_ext_attr1,c_ext_attr2
                                               ,c_ext_attr3,c_ext_attr4,c_ext_attr5,c_ext_attr6,c_ext_attr7,c_ext_attr8
                                               ,c_ext_attr9,c_ext_attr10,c_ext_attr11,c_ext_attr12,c_ext_attr13,c_ext_attr14
                                               ,c_ext_attr15,c_ext_attr16,c_ext_attr17,c_ext_attr18,c_ext_attr19,c_ext_attr20
                                               ,c_ext_attr21,c_ext_attr22,c_ext_attr23,c_ext_attr24,c_ext_attr25,c_ext_attr26
                                               ,c_ext_attr27,c_ext_attr28,c_ext_attr29,c_ext_attr30,c_ext_attr31,c_ext_attr32
                                               ,c_ext_attr33,c_ext_attr34,c_ext_attr35,c_ext_attr36,c_ext_attr37,c_ext_attr38
                                               ,c_ext_attr39,c_ext_attr40,c_ext_attr41,c_ext_attr42,c_ext_attr43,c_ext_attr44
                                               ,c_ext_attr45,c_ext_attr46,c_ext_attr47,c_ext_attr48,c_ext_attr49,c_ext_attr50
                                               ,batch_id,org_id,request_id,line_level_comment,dept_desc
                                               ,dept_sft_hdr,dept_code,parent_cust_doc_id,extract_batch_id,line_tax_amt
											   ,kit_sku  -- Added for Kitting, Defect# 37675
											   ,kit_sku_desc  -- Added for Kitting, Defect# 37675
											   ,sku_level_tax   -- Added for SKU level Tax changes NAIT 58403
			                                   ,sku_level_total -- Added for SKU level Tax changes NAIT 58403
                                               )
          SELECT XAECDM.cons_inv_id,XAECDM.customer_trx_id,XAECDM.cust_doc_id,XAECDM.customer_trx_line_id,XAECDM.trx_line_number
                ,XAECDM.trx_line_type,XAECDM.item_description,XAECDM.inventory_item_id,XAECDM.inventory_item_number
                ,XAECDM.translated_description,XAECDM.order_line_id,XAECDM.po_line_number,XAECDM.quantity_back_ordered
                ,XAECDM.quantity_credited,XAECDM.quantity_invoiced,XAECDM.quantity_ordered,XAECDM.quantity_shipped
                ,XAECDM.unit_of_measure,XAECDM.unit_price,XAECDM.ext_price,XAECDM.contract_plan_id,XAECDM.contract_seq_number
                ,XAECDM.entered_product_code,XAECDM.vendor_product_code,XAECDM.customer_product_code,XAECDM.discount_code
                ,XAECDM.elec_detail_seq_number,XAECDM.elec_record_type,XAECDM.wholesaler_item,XAECDM.detail_rec_taxable_flag
                ,XAECDM.gsa_comments,XAECDM.interface_line_context,XAECDM.price_adjustment_id,fnd_profile.value('user_id')
                ,sysdate,fnd_profile.value('user_id'),sysdate,fnd_profile.value('login_id'),XAECDM.c_ext_attr1,XAECDM.c_ext_attr2
                ,XAECDM.c_ext_attr3,XAECDM.c_ext_attr4,XAECDM.c_ext_attr5,XAECDM.c_ext_attr6,XAECDM.c_ext_attr7,XAECDM.c_ext_attr8
                ,XAECDM.c_ext_attr9,XAECDM.c_ext_attr10,XAECDM.c_ext_attr11,XAECDM.c_ext_attr12,XAECDM.c_ext_attr13,XAECDM.c_ext_attr14
                ,XAECDM.c_ext_attr15,XAECDM.c_ext_attr16,XAECDM.c_ext_attr17,XAECDM.c_ext_attr18,XAECDM.c_ext_attr19,XAECDM.c_ext_attr20
                ,XAECDM.c_ext_attr21,XAECDM.c_ext_attr22,XAECDM.c_ext_attr23,XAECDM.c_ext_attr24,XAECDM.c_ext_attr25,XAECDM.c_ext_attr26
                ,XAECDM.c_ext_attr27,XAECDM.c_ext_attr28,XAECDM.c_ext_attr29,XAECDM.c_ext_attr30,XAECDM.c_ext_attr31,XAECDM.c_ext_attr32
                ,XAECDM.c_ext_attr33,XAECDM.c_ext_attr34,XAECDM.c_ext_attr35,XAECDM.c_ext_attr36,XAECDM.c_ext_attr37,XAECDM.c_ext_attr38
                ,XAECDM.c_ext_attr39,XAECDM.c_ext_attr40,XAECDM.c_ext_attr41,XAECDM.c_ext_attr42,XAECDM.c_ext_attr43,XAECDM.c_ext_attr44
                ,XAECDM.c_ext_attr45,XAECDM.c_ext_attr46,XAECDM.c_ext_attr47,XAECDM.c_ext_attr48,XAECDM.c_ext_attr49,XAECDM.c_ext_attr50
                ,XAECDM.batch_id,XAECDM.org_id,p_request_id,XAECDM.line_level_comment,XAECDM.dept_desc
                ,XAECDM.dept_sft_hdr,XAECDM.dept_code,XAECDM.parent_cust_doc_id,XAECDM.extract_batch_id,XAECDM.line_tax_amt
				,XAECDM.kit_sku  -- Added for Kitting, Defect# 37675
				,XAECDM.kit_sku_desc  -- Added for Kitting, Defect# 37675
				,XAECDM.sku_level_tax   -- Added for SKU level Tax changes NAIT 58403
			    ,XAECDM.sku_level_total -- Added for SKU level Tax changes NAIT 58403
          FROM   xx_ar_ebl_cons_hdr_main   XAECHM
                ,xx_ar_ebl_cons_dtl_main   XAECDM
                ,xx_ar_ebl_file            XAEF
				--Start Aniket CG 22772
				,(SELECT n_ext_attr2,c_ext_attr3,
                NVL(DECODE(l.c_ext_attr13,'CR','Credit Memo','DB','Invoice'),NULL) cmb1 ,
                NVL(DECODE(l.c_ext_attr13,'DB','Debit Memo'),NULL)cmb2
                FROM XX_CDH_CUST_ACCT_EXT_B l
                ) XXCMB
                --end
          WHERE  XAECHM.org_id                   = ln_org_id
          AND    XAECHM.customer_trx_id          = XAECDM.customer_trx_id
          AND    XAECHM.cust_doc_id              = XAECDM.cust_doc_id
          AND    XAECHM.cons_inv_id              = XAECDM.cons_inv_id
          AND    XAECHM.billdocs_delivery_method = p_delivery_meth
          AND    XAEF.file_id                    = p_file_id
          AND    XAECHM.file_id                  = XAEF.file_id
          AND    XAECHM.transmission_id          = XAEF.transmission_id
          AND    XAEF.status                     = lc_status
		   --Start Aniket CG 22772
          AND    XAECHM.cust_doc_id  = XXCMB.n_ext_attr2
          AND    XAECHM.billdocs_delivery_method =   XXCMB.c_ext_attr3
          AND    (XAECHM.TRANSACTION_CLASS = NVL(XXCMB.cmb1,XAECHM.TRANSACTION_CLASS)
          OR XAECHM.TRANSACTION_CLASS   = XXCMB.cmb2);
          -- end
          PUT_LOG_LINE ( lb_debug
                        ,TRUE
                        ,'Number of trx lines inserted into dtl hist table for the file ID : '||p_file_id||' are : '||SQL%ROWCOUNT
                        );

          lc_error_loc := 'Inserting into Consolidated Header History Table ';
          INSERT INTO xx_ar_ebl_cons_hdr_hist ( cons_inv_id,customer_trx_id,mbs_doc_id,consolidated_bill_number
                                               ,billdocs_delivery_method,document_type,direct_flag,cust_doc_id
                                               ,bill_from_date,bill_to_date,mail_to_attention,invoice_number
                                               ,original_order_number,original_invoice_amount,amount_due_remaining
                                               ,gross_sale_amount,tax_rate,credit_memo_reason,amount_applied
                                               ,invoice_bill_date,bill_due_date,invoice_currency_code,order_date
                                               ,reconcile_date,order_header_id,order_level_comment,order_level_spc_comment
                                               ,order_type,order_type_code,ordered_by,payment_term,payment_term_description
                                               ,payment_term_discount,payment_term_discount_date,payment_term_frequency,payment_term_report_day
                                               ,payment_term_string,total_bulk_amount,total_coupon_amount,total_discount_amount
                                               ,total_freight_amount,total_gift_card_amount,total_gst_amount,total_hst_amount
                                               ,total_miscellaneous_amount,total_pst_amount,total_qst_amount,total_tiered_discount_amount
                                               ,total_us_tax_amount,sku_lines_subtotal,sales_person,cust_account_id
                                               ,oracle_account_number,customer_name,aops_account_number,cust_acct_site_id
                                               ,cust_site_sequence,customer_ref_date,customer_ref_number,sold_to_customer_number
                                               ,transaction_source,transaction_type,transaction_class,transaction_date
                                               ,bill_to_name,bill_to_address1,bill_to_address2,bill_to_address3,bill_to_address4
                                               ,bill_to_city,bill_to_state,bill_to_country,bill_to_zip,bill_to_contact_name
                                               ,bill_to_contact_phone,bill_to_contact_phone_ext,bill_to_contact_email,carrier, bill_to_abbreviation
                                               ,ship_to_name,ship_to_abbreviation,ship_to_address1,ship_to_address2,ship_to_address3
                                               ,ship_to_address4,ship_to_city,ship_to_state,ship_to_country,ship_to_zip
                                               ,ship_to_sequence,shipment_ref_number,remit_address1,remit_address2,remit_address3
                                               ,remit_address4,remit_city,remit_state,remit_zip,remit_country,us_federal_id
                                               ,canadian_tax_number,cost_center_sft_hdr,po_number_sft_hdr,release_number_sft_hdr,desktop_sft_hdr
                                               ,number_of_lines,last_updated_by,last_updated_date,created_by,creation_date,last_updated_login
                                               ,c_ext_attr1,c_ext_attr2,c_ext_attr3,c_ext_attr4,c_ext_attr5,c_ext_attr6,c_ext_attr7
                                               ,c_ext_attr8,c_ext_attr9,c_ext_attr10,c_ext_attr11,c_ext_attr12,c_ext_attr13,c_ext_attr14
                                               ,c_ext_attr15,c_ext_attr16,c_ext_attr17,c_ext_attr18,c_ext_attr19,c_ext_attr20
                                               ,c_ext_attr21,c_ext_attr22,c_ext_attr23,c_ext_attr24,c_ext_attr25,c_ext_attr26
                                               ,c_ext_attr27,c_ext_attr28,c_ext_attr29,c_ext_attr30,c_ext_attr31,c_ext_attr32
                                               ,c_ext_attr33,c_ext_attr34,c_ext_attr35,c_ext_attr36,c_ext_attr37,c_ext_attr38
                                               ,c_ext_attr39,c_ext_attr40,c_ext_attr41,c_ext_attr42,c_ext_attr43,c_ext_attr44
                                               ,c_ext_attr45,c_ext_attr46,c_ext_attr47,c_ext_attr48,c_ext_attr49,c_ext_attr50
                                               ,batch_id,file_id,transmission_id,file_name,org_id,bill_to_site_use_id,parent_cust_doc_id
                                               ,epdf_doc_level,request_id,trx_number,desktop_sft_data,po_number_sft_data,cost_center_sft_data
                                               ,release_number_sft_data,account_contact,order_contact,infocopy_tag,split_identifier,email_address
                                               ,total_association_discount,batch_source_id,status,extract_batch_id,order_source_code,dept_desc   -- dept_desc added as per Defect # 15118
											   ,dept_code -- Added for Defect 36437
                                               )
          SELECT XAECHM.cons_inv_id,XAECHM.customer_trx_id,XAECHM.mbs_doc_id,XAECHM.consolidated_bill_number
                ,XAECHM.billdocs_delivery_method,XAECHM.document_type,XAECHM.direct_flag,XAECHM.cust_doc_id
                ,XAECHM.bill_from_date,XAECHM.bill_to_date,XAECHM.mail_to_attention,XAECHM.invoice_number
                ,XAECHM.original_order_number,XAECHM.original_invoice_amount,XAECHM.amount_due_remaining
                ,XAECHM.gross_sale_amount,XAECHM.tax_rate,XAECHM.credit_memo_reason,XAECHM.amount_applied
                ,XAECHM.invoice_bill_date,XAECHM.bill_due_date,XAECHM.invoice_currency_code,XAECHM.order_date
                ,XAECHM.reconcile_date,XAECHM.order_header_id,XAECHM.order_level_comment,XAECHM.order_level_spc_comment
                ,XAECHM.order_type,XAECHM.order_type_code,XAECHM.ordered_by,XAECHM.payment_term,XAECHM.payment_term_description
                ,XAECHM.payment_term_discount,XAECHM.payment_term_discount_date,XAECHM.payment_term_frequency,XAECHM.payment_term_report_day
                ,XAECHM.payment_term_string,XAECHM.total_bulk_amount,XAECHM.total_coupon_amount,XAECHM.total_discount_amount
                ,XAECHM.total_freight_amount,XAECHM.total_gift_card_amount,XAECHM.total_gst_amount,XAECHM.total_hst_amount
                ,XAECHM.total_miscellaneous_amount,XAECHM.total_pst_amount,XAECHM.total_qst_amount,XAECHM.total_tiered_discount_amount
                ,XAECHM.total_us_tax_amount,XAECHM.sku_lines_subtotal,XAECHM.sales_person,XAECHM.cust_account_id
                ,XAECHM.oracle_account_number,XAECHM.customer_name,XAECHM.aops_account_number,XAECHM.cust_acct_site_id
                ,XAECHM.cust_site_sequence,XAECHM.customer_ref_date,XAECHM.customer_ref_number,XAECHM.sold_to_customer_number
                ,XAECHM.transaction_source,XAECHM.transaction_type,XAECHM.transaction_class,XAECHM.transaction_date
                ,XAECHM.bill_to_name,XAECHM.bill_to_address1,XAECHM.bill_to_address2,XAECHM.bill_to_address3,XAECHM.bill_to_address4
                ,XAECHM.bill_to_city,XAECHM.bill_to_state,XAECHM.bill_to_country,XAECHM.bill_to_zip,XAECHM.bill_to_contact_name
                ,XAECHM.bill_to_contact_phone,XAECHM.bill_to_contact_phone_ext,XAECHM.bill_to_contact_email,XAECHM.carrier, XAECHM.bill_to_abbreviation
                ,XAECHM.ship_to_name,XAECHM.ship_to_abbreviation,XAECHM.ship_to_address1,XAECHM.ship_to_address2,XAECHM.ship_to_address3
                ,XAECHM.ship_to_address4,XAECHM.ship_to_city,XAECHM.ship_to_state,XAECHM.ship_to_country,XAECHM.ship_to_zip
                ,XAECHM.ship_to_sequence,XAECHM.shipment_ref_number,XAECHM.remit_address1,XAECHM.remit_address2,XAECHM.remit_address3
                ,XAECHM.remit_address4,XAECHM.remit_city,XAECHM.remit_state,XAECHM.remit_zip,XAECHM.remit_country,XAECHM.us_federal_id
                ,XAECHM.canadian_tax_number,XAECHM.cost_center_sft_hdr,XAECHM.po_number_sft_hdr,XAECHM.release_number_sft_hdr,XAECHM.desktop_sft_hdr
                ,XAECHM.number_of_lines,fnd_profile.value('user_id'),sysdate,fnd_profile.value('user_id'),sysdate,fnd_profile.value('login_id')
                ,XAECHM.c_ext_attr1,XAECHM.c_ext_attr2,XAECHM.c_ext_attr3,XAECHM.c_ext_attr4,XAECHM.c_ext_attr5,XAECHM.c_ext_attr6,XAECHM.c_ext_attr7
                ,XAECHM.c_ext_attr8,XAECHM.c_ext_attr9,XAECHM.c_ext_attr10,XAECHM.c_ext_attr11,XAECHM.c_ext_attr12,XAECHM.c_ext_attr13,XAECHM.c_ext_attr14
                ,XAECHM.c_ext_attr15,XAECHM.c_ext_attr16,XAECHM.c_ext_attr17,XAECHM.c_ext_attr18,XAECHM.c_ext_attr19,XAECHM.c_ext_attr20
                ,XAECHM.c_ext_attr21,XAECHM.c_ext_attr22,XAECHM.c_ext_attr23,XAECHM.c_ext_attr24,XAECHM.c_ext_attr25,XAECHM.c_ext_attr26
                ,XAECHM.c_ext_attr27,XAECHM.c_ext_attr28,XAECHM.c_ext_attr29,XAECHM.c_ext_attr30,XAECHM.c_ext_attr31,XAECHM.c_ext_attr32
                ,XAECHM.c_ext_attr33,XAECHM.c_ext_attr34,XAECHM.c_ext_attr35,XAECHM.c_ext_attr36,XAECHM.c_ext_attr37,XAECHM.c_ext_attr38
                ,XAECHM.c_ext_attr39,XAECHM.c_ext_attr40,XAECHM.c_ext_attr41,XAECHM.c_ext_attr42,XAECHM.c_ext_attr43,XAECHM.c_ext_attr44
                ,XAECHM.c_ext_attr45,XAECHM.c_ext_attr46,XAECHM.c_ext_attr47,XAECHM.c_ext_attr48,XAECHM.c_ext_attr49,XAECHM.c_ext_attr50
                ,XAECHM.batch_id,XAECHM.file_id,XAECHM.transmission_id,XAECHM.file_name,XAECHM.org_id,XAECHM.bill_to_site_use_id,XAECHM.parent_cust_doc_id
                ,XAECHM.epdf_doc_level,p_request_id,XAECHM.trx_number,XAECHM.desktop_sft_data,XAECHM.po_number_sft_data,XAECHM.cost_center_sft_data
                ,XAECHM.release_number_sft_data,XAECHM.account_contact,XAECHM.order_contact,XAECHM.infocopy_tag,XAECHM.split_identifier,XAECHM.email_address
                ,XAECHM.total_association_discount,XAECHM.batch_source_id,'RENDERED',XAECHM.extract_batch_id,XAECHM.order_source_code,XAECHM.dept_desc
				,XAECHM.dept_code -- Added for Defect 36437
          FROM   xx_ar_ebl_cons_hdr_main   XAECHM
                ,xx_ar_ebl_file            XAEF
				--Start Aniket CG 22772
				,(SELECT n_ext_attr2,c_ext_attr3,
                NVL(DECODE(l.c_ext_attr13,'CR','Credit Memo','DB','Invoice'),NULL) cmb1 ,
                NVL(DECODE(l.c_ext_attr13,'DB','Debit Memo'),NULL)cmb2
                FROM XX_CDH_CUST_ACCT_EXT_B l
                ) XXCMB
                --end
          WHERE  XAECHM.org_id                   = ln_org_id
          AND    XAECHM.billdocs_delivery_method = p_delivery_meth
          AND    XAEF.file_id                    = XAECHM.file_id
          AND    XAEF.file_id                    = p_file_id
          AND    XAEF.transmission_id            = XAECHM.transmission_id
          AND    XAEF.status                     = lc_status
		  --Start Aniket CG 22772
          AND    XAECHM.cust_doc_id  = XXCMB.n_ext_attr2
          AND    XAECHM.billdocs_delivery_method =   XXCMB.c_ext_attr3
          AND    (XAECHM.TRANSACTION_CLASS = NVL(XXCMB.cmb1,XAECHM.TRANSACTION_CLASS)
          OR XAECHM.TRANSACTION_CLASS   = XXCMB.cmb2);
          -- end
          PUT_LOG_LINE ( lb_debug
                        ,TRUE
                        ,'Number of trxs inserted into hdr hist table for the file ID : '||p_file_id||' are : '||SQL%ROWCOUNT
                        );

          lc_error_loc := 'Deleting from Consolidated Detail Main Table ';
          DELETE xx_ar_ebl_cons_dtl_main   XAECDM
          WHERE  EXISTS      (SELECT /*+ leading(XAEF) */ 1
                              FROM   xx_ar_ebl_cons_hdr_main XAECHM
                                    ,xx_ar_ebl_file          XAEF
                              WHERE  XAECHM.CUSTOMER_TRX_ID              = XAECDM.CUSTOMER_TRX_ID
                              AND    XAECHM.CONS_INV_ID                  = XAECDM.CONS_INV_ID
                              AND    XAECHM.cust_doc_id                  = XAECDM.cust_doc_id
                              AND    XAECHM.org_id                       = ln_org_id
                              AND    XAECHM.billdocs_delivery_method     = p_delivery_meth
                              AND    XAEF.file_id                        = p_file_id
                              AND    XAECHM.file_id                      = XAEF.file_id
                              AND    XAECHM.transmission_id              = XAEF.transmission_id
                              AND    XAEF.status                         = lc_status
                              );
          PUT_LOG_LINE ( lb_debug
                        ,TRUE
                        ,'Number of trx lines deleted from dtl table for the file ID : '||p_file_id||' are : '||SQL%ROWCOUNT
                        );

          lc_error_loc := 'Deleting from Consolidated Header Main Table ';
          DELETE xx_ar_ebl_cons_hdr_main    XAECHM
          WHERE  XAECHM.org_id                   = ln_org_id
          AND    XAECHM.billdocs_delivery_method = p_delivery_meth
          AND    XAECHM.file_id                  = p_file_id
          AND    EXISTS (SELECT 1
                         FROM   xx_ar_ebl_file  XAEF
                         WHERE  XAEF.file_id           = XAECHM.file_id
                         AND    XAEF.file_id           = p_file_id
                         AND    XAEF.transmission_id   = XAECHM.transmission_id
                         AND    XAEF.status            = lc_status
                         );
          PUT_LOG_LINE ( lb_debug
                        ,TRUE
                        ,'Number of trxs deleted from dtl table for the file ID : '||p_file_id||' are : '||SQL%ROWCOUNT
                        );

       ELSIF p_doc_type = 'IND' THEN

          lc_error_loc := 'Updating RA Customer TRX Table ';
          UPDATE ra_customer_trx RCT
          SET    RCT.printing_pending                  = 'N'
                ,RCT.printing_count                    = NVL(RCT.printing_count, 0) + 1
                ,RCT.printing_last_printed             = SYSDATE
                ,RCT.printing_original_date            = DECODE( RCT.printing_count
                                                                ,0,SYSDATE
                                                                ,NULL,SYSDATE
                                                                ,RCT.printing_original_date
                                                                )
                ,RCT.last_printed_sequence_num         = '1'
                ,RCT.last_updated_by                   = FND_GLOBAL.USER_ID
                ,RCT.last_update_date                  = SYSDATE
                ,RCT.last_update_login                 = FND_GLOBAL.USER_ID
                ,RCT.program_id                        = FND_GLOBAL.CONC_PROGRAM_ID
                ,RCT.request_id                        = p_request_id
          WHERE  EXISTS (SELECT 1
                         FROM   xx_ar_ebl_ind_hdr_main XAEIHM
                               ,xx_ar_ebl_file         XAEF
                         WHERE  XAEIHM.customer_trx_id          = RCT.customer_trx_id
                         AND    XAEIHM.document_type            = 'Paydoc'
                         AND    XAEIHM.file_id                  = p_file_id
                         AND    XAEIHM.org_id                   = ln_org_id
                         AND    XAEIHM.billdocs_delivery_method = p_delivery_meth
                         AND    XAEIHM.file_id                  = XAEF.file_id
                         AND    XAEIHM.transmission_id          = XAEF.transmission_id
                         AND    XAEF.status                     = lc_status
                         );
          PUT_LOG_LINE ( lb_debug
                        ,TRUE
                        ,'Number of trx updated for the file ID : '||p_file_id||' are : '||SQL%ROWCOUNT
                        );

          lc_error_loc := 'Inserting intp AR Invoice Frequency History Table ';
          INSERT INTO xx_ar_invoice_freq_history (document_id,customer_document_id,paydoc_flag,doc_delivery_method,doc_combo_type,invoice_id
                                                       ,org_id,estimated_print_date,actual_print_date,printed_flag,billdocs_special_handling
                                                       ,bill_to_customer_id,bill_to_customer_number,extension_id,billdocs_payment_term,attribute1
                                                       ,attribute2,attribute3,attribute4,attribute5,attribute6,request_id,request_date,last_update_date
                                                       ,last_updated_by,creation_date,created_by,last_update_login,site_use_id,parent_cust_acct_id,parent_cust_doc_id
                                                       ,mail_to_attention,direct_flag,amount_due_original,amount_due_remaining,due_date,batch_id,status
                                                       )
          SELECT        xaif.document_id,xaif.customer_document_id,xaif.paydoc_flag,xaif.doc_delivery_method,xaif.doc_combo_type,xaif.invoice_id
                       ,xaif.org_id,xaif.estimated_print_date,sysdate,'Y',xaif.billdocs_special_handling
                       ,xaif.bill_to_customer_id,xaif.bill_to_customer_number,xaif.extension_id,xaif.billdocs_payment_term,p_request_id
                       ,xaif.attribute2,xaif.attribute3,xaif.attribute4,xaif.attribute5,xaif.attribute6,NULL,sysdate,sysdate
                       ,fnd_profile.value('user_id'),sysdate,fnd_profile.value('user_id'),fnd_profile.value('login_id'),xaif.site_use_id,xaif.parent_cust_acct_id,xaif.parent_cust_doc_id
                       ,xaif.mail_to_attention,xaif.direct_flag,xaif.amount_due_original,xaif.amount_due_remaining,xaif.due_date,xaif.batch_id,'COMPLETE'
          FROM          xx_ar_invoice_frequency   XAIF
                       ,xx_ar_ebl_ind_hdr_main    XAEIHM
                       ,xx_ar_ebl_file            XAEF
          WHERE         XAIF.status                     = 'IN PROCESS'
          AND           XAIF.invoice_id                 = XAEIHM.customer_trx_id
          AND           XAIF.customer_document_id       = XAEIHM.cust_doc_id
          AND           XAEF.file_id                    = p_file_id
          AND           XAEIHM.billdocs_delivery_method = p_delivery_meth
          AND           XAEIHM.file_id                  = XAEF.file_id
          AND           XAEIHM.transmission_id          = XAEF.transmission_id
          AND           XAEF.status                     = lc_status;
          PUT_LOG_LINE ( lb_debug
                        ,TRUE
                        ,'Number of trx inserted into freq hist table for the file ID : '||p_file_id||' are : '||SQL%ROWCOUNT
                        );

          lc_error_loc := 'Deleting from AR Invoice Frequency Table ';
          DELETE xx_ar_invoice_frequency     XAIF
          WHERE  status      = 'IN PROCESS'
          AND    EXISTS      (SELECT 1
                              FROM   xx_ar_ebl_ind_hdr_main XAEIHM
                                    ,xx_ar_ebl_file         XAEF
                              WHERE  XAEIHM.customer_trx_id              = XAIF.invoice_id
                              AND    XAEIHM.cust_doc_id                  = XAIF.customer_document_id
                              AND    XAEIHM.org_id                       = ln_org_id
                              AND    XAEIHM.billdocs_delivery_method     = p_delivery_meth
                              AND    XAEF.file_id                        = p_file_id
                              AND    XAEIHM.file_id                      = XAEF.file_id
                              AND    XAEIHM.transmission_id              = XAEF.transmission_id
                              AND    XAEF.status                         = lc_status
                              );
          PUT_LOG_LINE ( lb_debug
                        ,TRUE
                        ,'Number of trx deleted from freq table for the file ID : '||p_file_id||' are : '||SQL%ROWCOUNT
                        );

          lc_error_loc := 'Inserting into Individual Detail History Table ';
          INSERT INTO xx_ar_ebl_ind_dtl_hist ( customer_trx_id,cust_doc_id,customer_trx_line_id,trx_line_number,trx_line_type
                                              ,item_description,inventory_item_id,inventory_item_number,translated_description,order_line_id
                                              ,po_line_number,quantity_back_ordered,quantity_credited,quantity_invoiced,quantity_ordered
                                              ,quantity_shipped,unit_of_measure,unit_price,ext_price,contract_plan_id,contract_seq_number
                                              ,entered_product_code,vendor_product_code,customer_product_code,discount_code,elec_detail_seq_number
                                              ,elec_record_type,wholesaler_item,detail_rec_taxable_flag,gsa_comments,interface_line_context
                                              ,price_adjustment_id,dept_sft_hdr,last_updated_by,last_updated_date,created_by,creation_date
                                              ,last_updated_login,c_ext_attr1,c_ext_attr2,c_ext_attr3,c_ext_attr4,c_ext_attr5,c_ext_attr6
                                              ,c_ext_attr7,c_ext_attr8,c_ext_attr9,c_ext_attr10,c_ext_attr11,c_ext_attr12,c_ext_attr13,c_ext_attr14
                                              ,c_ext_attr15,c_ext_attr16,c_ext_attr17,c_ext_attr18,c_ext_attr19,c_ext_attr20,c_ext_attr21,c_ext_attr22
                                              ,c_ext_attr23,c_ext_attr24,c_ext_attr25,c_ext_attr26,c_ext_attr27,c_ext_attr28,c_ext_attr29,c_ext_attr30
                                              ,c_ext_attr31,c_ext_attr32,c_ext_attr33,c_ext_attr34,c_ext_attr35,c_ext_attr36,c_ext_attr37,c_ext_attr38
                                              ,c_ext_attr39,c_ext_attr40,c_ext_attr41,c_ext_attr42,c_ext_attr43,c_ext_attr44,c_ext_attr45,c_ext_attr46
                                              ,c_ext_attr47,c_ext_attr48,c_ext_attr49,c_ext_attr50,batch_id,org_id,line_level_comment
                                              ,dept_desc,parent_cust_doc_id,extract_batch_id
                                              ,dept_code -- Added for Defect 36437
                                              ,line_tax_amt
											  ,kit_sku   -- Added for Kitting, Defect# 37675
											  ,kit_sku_desc   -- Added for Kitting, Defect# 37675
											  ,sku_level_tax   -- Added for SKU level Tax changes NAIT 58403
			                                  ,sku_level_total -- Added for SKU level Tax changes NAIT 58403
                                              )
          SELECT XAEIDM.customer_trx_id,XAEIDM.cust_doc_id,XAEIDM.customer_trx_line_id,XAEIDM.trx_line_number,XAEIDM.trx_line_type
                ,XAEIDM.item_description,XAEIDM.inventory_item_id,XAEIDM.inventory_item_number,XAEIDM.translated_description,XAEIDM.order_line_id
                ,XAEIDM.po_line_number,XAEIDM.quantity_back_ordered,XAEIDM.quantity_credited,XAEIDM.quantity_invoiced,XAEIDM.quantity_ordered
                ,XAEIDM.quantity_shipped,XAEIDM.unit_of_measure,XAEIDM.unit_price,XAEIDM.ext_price,XAEIDM.contract_plan_id,XAEIDM.contract_seq_number
                ,XAEIDM.entered_product_code,XAEIDM.vendor_product_code,XAEIDM.customer_product_code,XAEIDM.discount_code,XAEIDM.elec_detail_seq_number
                ,XAEIDM.elec_record_type,XAEIDM.wholesaler_item,XAEIDM.detail_rec_taxable_flag,XAEIDM.gsa_comments,XAEIDM.interface_line_context
                ,XAEIDM.price_adjustment_id,XAEIDM.dept_sft_hdr,fnd_profile.value('user_id'),sysdate,fnd_profile.value('user_id'),sysdate
                ,fnd_profile.value('login_id'),XAEIDM.c_ext_attr1,XAEIDM.c_ext_attr2,XAEIDM.c_ext_attr3,XAEIDM.c_ext_attr4,XAEIDM.c_ext_attr5,XAEIDM.c_ext_attr6
                ,XAEIDM.c_ext_attr7,XAEIDM.c_ext_attr8,XAEIDM.c_ext_attr9,XAEIDM.c_ext_attr10,XAEIDM.c_ext_attr11,XAEIDM.c_ext_attr12,XAEIDM.c_ext_attr13,XAEIDM.c_ext_attr14
                ,XAEIDM.c_ext_attr15,XAEIDM.c_ext_attr16,XAEIDM.c_ext_attr17,XAEIDM.c_ext_attr18,XAEIDM.c_ext_attr19,XAEIDM.c_ext_attr20,XAEIDM.c_ext_attr21,XAEIDM.c_ext_attr22
                ,XAEIDM.c_ext_attr23,XAEIDM.c_ext_attr24,XAEIDM.c_ext_attr25,XAEIDM.c_ext_attr26,XAEIDM.c_ext_attr27,XAEIDM.c_ext_attr28,XAEIDM.c_ext_attr29,XAEIDM.c_ext_attr30
                ,XAEIDM.c_ext_attr31,XAEIDM.c_ext_attr32,XAEIDM.c_ext_attr33,XAEIDM.c_ext_attr34,XAEIDM.c_ext_attr35,XAEIDM.c_ext_attr36,XAEIDM.c_ext_attr37,XAEIDM.c_ext_attr38
                ,XAEIDM.c_ext_attr39,XAEIDM.c_ext_attr40,XAEIDM.c_ext_attr41,XAEIDM.c_ext_attr42,XAEIDM.c_ext_attr43,XAEIDM.c_ext_attr44,XAEIDM.c_ext_attr45,XAEIDM.c_ext_attr46
                ,XAEIDM.c_ext_attr47,XAEIDM.c_ext_attr48,XAEIDM.c_ext_attr49,XAEIDM.c_ext_attr50,XAEIDM.batch_id,XAEIDM.org_id,XAEIDM.line_level_comment
                ,XAEIDM.dept_desc,XAEIDM.parent_cust_doc_id,XAEIDM.extract_batch_id
                ,XAEIDM.dept_code -- Added for Defect 36437
                ,XAEIDM.line_tax_amt
				,XAEIDM.kit_sku   -- Added for Kitting, Defect# 37675
				,XAEIDM.kit_sku_desc   -- Added for Kitting, Defect# 37675
				,XAEIDM.sku_level_tax   -- Added for SKU level Tax changes NAIT 58403
			    ,XAEIDM.sku_level_total -- Added for SKU level Tax changes NAIT 58403
          FROM   xx_ar_ebl_ind_hdr_main   XAEIHM
                ,xx_ar_ebl_ind_dtl_main   XAEIDM
                ,xx_ar_ebl_file           XAEF
          WHERE  XAEF.file_id                    = p_file_id
          AND    XAEIHM.org_id                   = ln_org_id
          AND    XAEIHM.customer_trx_id          = XAEIDM.customer_trx_id
          AND    XAEIHM.cust_doc_id              = XAEIDM.cust_doc_id
          AND    XAEIHM.billdocs_delivery_method = p_delivery_meth
          AND    XAEIHM.file_id                  = XAEF.file_id
          AND    XAEIHM.transmission_id          = XAEF.transmission_id
          AND    XAEF.status                     = lc_status;
          PUT_LOG_LINE ( lb_debug
                        ,TRUE
                        ,'Number of trx lines inserted into dtl hist table for the file ID : '||p_file_id||' are : '||SQL%ROWCOUNT
                        );

          lc_error_loc := 'Inserting into Individual Header History Table ';
          INSERT INTO xx_ar_ebl_ind_hdr_hist (customer_trx_id,cust_doc_id,mbs_doc_id,billdocs_delivery_method,document_type
                                             ,direct_flag,bill_from_date,bill_to_date,mail_to_attention,invoice_number
                                             ,original_order_number,original_invoice_amount,amount_due_remaining,gross_sale_amount
                                             ,tax_rate,credit_memo_reason,invoice_bill_date,bill_due_date,invoice_currency_code
                                             ,order_date,reconcile_date,order_header_id,order_level_comment,order_level_spc_comment
                                             ,order_type,order_type_code,ordered_by,payment_term,payment_term_description
                                             ,payment_term_discount,payment_term_discount_date,payment_term_frequency,payment_term_report_day
                                             ,payment_term_string,total_bulk_amount,total_coupon_amount,total_discount_amount,total_freight_amount
                                             ,total_gift_card_amount,total_gst_amount,total_hst_amount,total_miscellaneous_amount,total_pst_amount
                                             ,total_qst_amount,total_tiered_discount_amount,total_us_tax_amount,sku_lines_subtotal,sales_person
                                             ,cust_account_id,oracle_account_number,customer_name,aops_account_number,cust_acct_site_id,cust_site_sequence
                                             ,customer_ref_date,customer_ref_number,sold_to_customer_number,transaction_source,transaction_type
                                             ,transaction_class,transaction_date,bill_to_name,bill_to_address1,bill_to_address2,bill_to_address3
                                             ,bill_to_address4,bill_to_city,bill_to_state,bill_to_country,bill_to_zip,bill_to_contact_name
                                             ,bill_to_contact_phone,bill_to_contact_phone_ext,bill_to_contact_email,bill_to_abbreviation
                                             ,carrier,ship_to_name,ship_to_abbreviation
                                             ,ship_to_address1,ship_to_address2,ship_to_address3,ship_to_address4,ship_to_city,ship_to_state,ship_to_country
                                             ,ship_to_zip,ship_to_sequence,shipment_ref_number,remit_address1,remit_address2,remit_address3,remit_address4
                                             ,remit_city,remit_state,remit_zip,us_federal_id,canadian_tax_number,cost_center_sft_hdr,po_number_sft_hdr
                                             ,release_number_sft_hdr,desktop_sft_hdr,number_of_lines,last_updated_by,last_updated_date,created_by,creation_date
                                             ,last_updated_login,c_ext_attr1,c_ext_attr2,c_ext_attr3,c_ext_attr4,c_ext_attr5,c_ext_attr6,c_ext_attr7,c_ext_attr8
                                             ,c_ext_attr9,c_ext_attr10,c_ext_attr11,c_ext_attr12,c_ext_attr13,c_ext_attr14,c_ext_attr15,c_ext_attr16,c_ext_attr17
                                             ,c_ext_attr18,c_ext_attr19,c_ext_attr20,c_ext_attr21,c_ext_attr22,c_ext_attr23,c_ext_attr24,c_ext_attr25,c_ext_attr26
                                             ,c_ext_attr27,c_ext_attr28,c_ext_attr29,c_ext_attr30,c_ext_attr31,c_ext_attr32,c_ext_attr33,c_ext_attr34,c_ext_attr35
                                             ,c_ext_attr36,c_ext_attr37,c_ext_attr38,c_ext_attr39,c_ext_attr40,c_ext_attr41,c_ext_attr42,c_ext_attr43,c_ext_attr44
                                             ,c_ext_attr45,c_ext_attr46,c_ext_attr47,c_ext_attr48,c_ext_attr49,c_ext_attr50,batch_id,file_id,transmission_id
                                             ,file_name,org_id,bill_to_site_use_id,parent_cust_doc_id,epdf_doc_level,request_id,trx_number,desktop_sft_data
                                             ,po_number_sft_data,cost_center_sft_data,release_number_sft_data,account_contact,order_contact,total_delivery_amount
                                             ,batch_source_id,email_address,split_identifier,total_association_discount,remit_country,sales_order_number,status,extract_batch_id
                                             ,trx_term_description,order_source_code,dept_desc    -- dept_desc added as per Defect # 15118
											 ,dept_code -- Added for Defect 36437
                                             )
          SELECT  XAEIHM.customer_trx_id,XAEIHM.cust_doc_id,XAEIHM.mbs_doc_id,XAEIHM.billdocs_delivery_method,XAEIHM.document_type
                 ,XAEIHM.direct_flag,XAEIHM.bill_from_date,XAEIHM.bill_to_date,XAEIHM.mail_to_attention,XAEIHM.invoice_number
                 ,XAEIHM.original_order_number,XAEIHM.original_invoice_amount,XAEIHM.amount_due_remaining,XAEIHM.gross_sale_amount
                 ,XAEIHM.tax_rate,XAEIHM.credit_memo_reason,XAEIHM.invoice_bill_date,XAEIHM.bill_due_date,XAEIHM.invoice_currency_code
                 ,XAEIHM.order_date,XAEIHM.reconcile_date,XAEIHM.order_header_id,XAEIHM.order_level_comment,XAEIHM.order_level_spc_comment
                 ,XAEIHM.order_type,XAEIHM.order_type_code,XAEIHM.ordered_by,XAEIHM.payment_term,XAEIHM.payment_term_description
                 ,XAEIHM.payment_term_discount,XAEIHM.payment_term_discount_date,XAEIHM.payment_term_frequency,XAEIHM.payment_term_report_day
                 ,XAEIHM.payment_term_string,XAEIHM.total_bulk_amount,XAEIHM.total_coupon_amount,XAEIHM.total_discount_amount,XAEIHM.total_freight_amount
                 ,XAEIHM.total_gift_card_amount,XAEIHM.total_gst_amount,XAEIHM.total_hst_amount,XAEIHM.total_miscellaneous_amount,XAEIHM.total_pst_amount
                 ,XAEIHM.total_qst_amount,XAEIHM.total_tiered_discount_amount,XAEIHM.total_us_tax_amount,XAEIHM.sku_lines_subtotal,XAEIHM.sales_person
                 ,XAEIHM.cust_account_id,XAEIHM.oracle_account_number,XAEIHM.customer_name,XAEIHM.aops_account_number,XAEIHM.cust_acct_site_id,XAEIHM.cust_site_sequence
                 ,XAEIHM.customer_ref_date,XAEIHM.customer_ref_number,XAEIHM.sold_to_customer_number,XAEIHM.transaction_source,XAEIHM.transaction_type
                 ,XAEIHM.transaction_class,XAEIHM.transaction_date,XAEIHM.bill_to_name,XAEIHM.bill_to_address1,XAEIHM.bill_to_address2,XAEIHM.bill_to_address3
                 ,XAEIHM.bill_to_address4,XAEIHM.bill_to_city,XAEIHM.bill_to_state,XAEIHM.bill_to_country,XAEIHM.bill_to_zip,XAEIHM.bill_to_contact_name,XAEIHM.bill_to_contact_phone
                 ,XAEIHM.bill_to_contact_phone_ext,XAEIHM.bill_to_contact_email,XAEIHM.bill_to_abbreviation
                 ,XAEIHM.carrier,XAEIHM.ship_to_name,XAEIHM.ship_to_abbreviation
                 ,XAEIHM.ship_to_address1,XAEIHM.ship_to_address2,XAEIHM.ship_to_address3,XAEIHM.ship_to_address4,XAEIHM.ship_to_city,XAEIHM.ship_to_state,XAEIHM.ship_to_country
                 ,XAEIHM.ship_to_zip,XAEIHM.ship_to_sequence,XAEIHM.shipment_ref_number,XAEIHM.remit_address1,XAEIHM.remit_address2,XAEIHM.remit_address3,XAEIHM.remit_address4
                 ,XAEIHM.remit_city,XAEIHM.remit_state,XAEIHM.remit_zip,XAEIHM.us_federal_id,XAEIHM.canadian_tax_number,XAEIHM.cost_center_sft_hdr,XAEIHM.po_number_sft_hdr
                 ,XAEIHM.release_number_sft_hdr,XAEIHM.desktop_sft_hdr,XAEIHM.number_of_lines,FND_PROFILE.VALUE('USER_ID'),SYSDATE,FND_PROFILE.VALUE('USER_ID'),SYSDATE
                 ,FND_PROFILE.VALUE('LOGIN_ID'),XAEIHM.c_ext_attr1,XAEIHM.c_ext_attr2,XAEIHM.c_ext_attr3,XAEIHM.c_ext_attr4,XAEIHM.c_ext_attr5,XAEIHM.c_ext_attr6,XAEIHM.c_ext_attr7,XAEIHM.c_ext_attr8
                 ,XAEIHM.c_ext_attr9,XAEIHM.c_ext_attr10,XAEIHM.c_ext_attr11,XAEIHM.c_ext_attr12,XAEIHM.c_ext_attr13,XAEIHM.c_ext_attr14,XAEIHM.c_ext_attr15,XAEIHM.c_ext_attr16,XAEIHM.c_ext_attr17
                 ,XAEIHM.c_ext_attr18,XAEIHM.c_ext_attr19,XAEIHM.c_ext_attr20,XAEIHM.c_ext_attr21,XAEIHM.c_ext_attr22,XAEIHM.c_ext_attr23,XAEIHM.c_ext_attr24,XAEIHM.c_ext_attr25,XAEIHM.c_ext_attr26
                 ,XAEIHM.c_ext_attr27,XAEIHM.c_ext_attr28,XAEIHM.c_ext_attr29,XAEIHM.c_ext_attr30,XAEIHM.c_ext_attr31,XAEIHM.c_ext_attr32,XAEIHM.c_ext_attr33,XAEIHM.c_ext_attr34,XAEIHM.c_ext_attr35
                 ,XAEIHM.c_ext_attr36,XAEIHM.c_ext_attr37,XAEIHM.c_ext_attr38,XAEIHM.c_ext_attr39,XAEIHM.c_ext_attr40,XAEIHM.c_ext_attr41,XAEIHM.c_ext_attr42,XAEIHM.c_ext_attr43,XAEIHM.c_ext_attr44
                 ,XAEIHM.c_ext_attr45,XAEIHM.c_ext_attr46,XAEIHM.c_ext_attr47,XAEIHM.c_ext_attr48,XAEIHM.c_ext_attr49,XAEIHM.c_ext_attr50,XAEIHM.batch_id,XAEIHM.file_id,XAEIHM.transmission_id
                 ,XAEIHM.file_name,XAEIHM.org_id,XAEIHM.bill_to_site_use_id,XAEIHM.parent_cust_doc_id,XAEIHM.epdf_doc_level,p_request_id,XAEIHM.trx_number,XAEIHM.desktop_sft_data
                 ,XAEIHM.po_number_sft_data,XAEIHM.cost_center_sft_data,XAEIHM.release_number_sft_data,XAEIHM.account_contact,XAEIHM.order_contact,XAEIHM.total_delivery_amount
                 ,XAEIHM.batch_source_id,XAEIHM.email_address,XAEIHM.split_identifier,XAEIHM.total_association_discount,XAEIHM.remit_country
                 ,XAEIHM.sales_order_number,'RENDERED',XAEIHM.extract_batch_id,XAEIHM.trx_term_description,XAEIHM.order_source_code,XAEIHM.dept_desc
				 ,XAEIHM.dept_code -- Added for Defect 36437
          FROM   xx_ar_ebl_ind_hdr_main   XAEIHM
                ,xx_ar_ebl_file           XAEF
          WHERE  XAEIHM.file_id                  = p_file_id
          AND    XAEIHM.org_id                   = ln_org_id
          AND    XAEIHM.billdocs_delivery_method = p_delivery_meth
          AND    XAEIHM.file_id                  = XAEF.file_id
          AND    XAEF.file_id                    = p_file_id
          AND    XAEIHM.transmission_id          = XAEF.transmission_id
          AND    XAEF.status                     = lc_status;
          PUT_LOG_LINE ( lb_debug
                        ,TRUE
                        ,'Number of trxs inserted into hdr hist table for the file ID : '||p_file_id||' are : '||SQL%ROWCOUNT
                        );

          lc_error_loc := 'Deleting from Individual Detail Main Table ';
          DELETE xx_ar_ebl_ind_dtl_main   XAEIDM
          WHERE  EXISTS      (SELECT 1
                              FROM   xx_ar_ebl_ind_hdr_main XAEIHM
                                    ,xx_ar_ebl_file         XAEF
                              WHERE  XAEIHM.customer_trx_id              = XAEIDM.customer_trx_id
                              AND    XAEIHM.cust_doc_id                  = XAEIDM.cust_doc_id
                              AND    XAEF.file_id                        = p_file_id
                              AND    XAEIHM.org_id                       = ln_org_id
                              AND    XAEIHM.billdocs_delivery_method     = p_delivery_meth
                              AND    XAEIHM.file_id                      = XAEF.file_id
                              AND    XAEIHM.transmission_id              = XAEF.transmission_id
                              AND    XAEF.status                         = lc_status
                              );
          PUT_LOG_LINE ( lb_debug
                        ,TRUE
                        ,'Number of trx lines deleted from dtl table for the file ID : '||p_file_id||' are : '||SQL%ROWCOUNT
                        );

          lc_error_loc := 'Deleting from Individual Header Main Table ';
          DELETE xx_ar_ebl_ind_hdr_main   XAEIHM
          WHERE  XAEIHM.file_id                  = p_file_id
          AND    XAEIHM.org_id                   = ln_org_id
          AND    XAEIHM.billdocs_delivery_method = p_delivery_meth
          AND    EXISTS    (SELECT 1
                            FROM   xx_ar_ebl_file   XAEF
                            WHERE  XAEIHM.file_id                      = XAEF.file_id
                            AND    XAEIHM.transmission_id              = XAEF.transmission_id
                            AND    XAEF.status                         = lc_status
                            );
          PUT_LOG_LINE ( lb_debug
                        ,TRUE
                        ,'Number of trxs deleted from hdr table for the file ID : '||p_file_id||' are : '||SQL%ROWCOUNT
                        );
       END IF;

    END UPDATE_BILL_STATUS_eXLS;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : GET_REMIT_ADDRESSID                                                 |
-- | Description : This Function  is used to get the remit to address id               |
-- | Parameters  :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 03-MAY-2010  Vinaykumar S            Initial draft version               |
-- |      1.1 12-JUN-2012  Gayathri K              As part of Defect#18203             |
-- |                                               get_remitaddressid function modified|
-- |          14-AUG-2012 Rohit Ranjan             Incase Remit to logic is changed    |
-- |                                               in furture then apart from this     |
-- |                                               package, the package                |
-- |                                               XX_AR_PRINT_SUMMBILL_PKB.pkb and    |
-- |                                               XX_AR_REMIT_ADDRESS_CHILD_PKG.pkb   |
-- |                                              function name get_remitaddressid     |
-- |                                              should be modified. Comment is       |
-- |                                              given because in Defect# 14144       |
-- |                                              remit to logic is modified in        |
-- |                                          package XX_AR_REMIT_ADDRESS_CHILD_PKG.pkb|
-- |                                              but not in billing package           |
-- +===================================================================================+

/***** IMPORTANT NOTE *****
*****  Remit to logic is cloned at 3 locations XX_AR_PRINT_SUMMBILL_PKB.pkb,XX_AR_REMIT_ADDRESS_CHILD_PKG.pkb and XX_AR_EBL_COMMON_UTIL_PKG.pkb. Any changes done at one place
has to be synched in the other 2 places.*****/

   FUNCTION GET_REMIT_ADDRESSID (
                                 p_bill_to_site_use_id NUMBER
                                ,p_debug_flag          VARCHAR2
                                )
      RETURN NUMBER
   IS
      CURSOR lcu_remit_derive (
                                p_inv_country       IN   VARCHAR2
                               ,p_inv_state         IN   VARCHAR2
                               ,p_inv_postal_code   IN   VARCHAR2
                              )
      IS
         SELECT   RRT.address_id
             FROM hz_cust_acct_sites HCAS
                  ,hz_party_sites HPS
                  ,hz_locations HL
                  ,ra_remit_tos RRT
            WHERE HCAS.cust_acct_site_id = RRT.address_id
              AND HCAS.party_site_id = HPS.party_site_id
              AND HL.location_id = HPS.location_id
              AND NVL (RRT.status, 'A') = 'A'
              AND NVL (HCAS.status, 'A') = 'A'
              AND (   NVL (RRT.state, p_inv_state) = p_inv_state
                   OR (p_inv_state IS NULL AND RRT.state IS NULL)
                  )
              AND (   (p_inv_postal_code BETWEEN RRT.postal_code_low
                                           AND RRT.postal_code_high
                      )
                   OR (    RRT.postal_code_high IS NULL
                       AND RRT.postal_code_low IS NULL
                      )
                  )
              AND RRT.country = p_inv_country
         ORDER BY RRT.postal_code_low
                 ,RRT.postal_code_high
                 ,RRT.state
                 ,HL.address1
                 ,HL.address2;
      CURSOR lcu_address (p_bill_site_use_id IN NUMBER)
      IS
         SELECT HL.state
               ,HL.country
               ,HL.postal_code
           FROM hz_cust_acct_sites HCAS
               ,hz_party_sites HPS
               ,hz_locations HL
               ,hz_cust_site_uses HCSU
          WHERE HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
            AND HCAS.party_site_id = HPS.party_site_id
            AND HL.location_id = HPS.location_id
            AND HCSU.site_use_id = p_bill_site_use_id;

      ln_remit_to_add            NUMBER :=0;  --added Defect 18203

      lc_inv_state          hz_locations.state%TYPE;
      lc_inv_country        hz_locations.country%TYPE;
      ln_inv_postal_code    hz_locations.postal_code%TYPE;
      ln_remit_address_id   hz_cust_acct_sites.cust_acct_site_id%TYPE;
      lb_debug              BOOLEAN;
   BEGIN
      IF p_debug_flag = 'Y' THEN
         lb_debug := TRUE;
      ELSE
         lb_debug := FALSE;
      END IF;


 fnd_file.put_line (fnd_file.LOG, '*****p_bill_to_site_use_id:  '||p_bill_to_site_use_id);

/***** IMPORTANT NOTE *****
*****  Remit to logic is cloned at 3 locations XX_AR_PRINT_SUMMBILL_PKB.pkb,XX_AR_REMIT_ADDRESS_CHILD_PKG.pkb and XX_AR_EBL_COMMON_UTIL_PKG.pkb. Any changes done at one place
has to be synched in the other 2 places.*****/
           BEGIN      -- --added Defect 18203
           SELECT artav.address_id
                INTO   ln_remit_to_add
                FROM   hz_cust_site_uses_all HCSUA
                      ,ar_remit_to_addresses_v ARTAV
                   -- ,ra_addresses_all RAA
                WHERE  HCSUA.site_use_code = 'BILL_TO'
                AND    HCSUA.attribute_category = 'BILL_TO'
                AND    HCSUA.status = 'A'
                AND    HCSUA.org_id = fnd_global.org_id --ln_org_id
                AND    HCSUA.site_use_id =p_bill_to_site_use_id --lc_cust_txn_rec.bill_to_site_use_id
                AND    HCSUA.attribute25 = ARTAV.attribute1;
             EXCEPTION
             WHEN OTHERS THEN
               ln_remit_to_add:=0;
            end;

   IF ln_remit_to_add =0 THEN  -- --added IF clause, only for above query as part of Defect 18203

      OPEN lcu_address (p_bill_to_site_use_id);
      FETCH lcu_address
       INTO lc_inv_state, lc_inv_country, ln_inv_postal_code;
      gc_put_log := 'Inside get_remitaddressid cursor';
      PUT_LOG_LINE ( lb_debug
                    ,TRUE
                    ,gc_put_log
                   );
      IF lcu_address%NOTFOUND
      THEN
         /* No Default Remit to Address can be found, use the default */
         lc_inv_state        := 'DEFAULT';
         lc_inv_country      := 'DEFAULT';
         ln_inv_postal_code  := NULL;
      END IF;
      CLOSE lcu_address;
      OPEN lcu_remit_derive (lc_inv_country, lc_inv_state, ln_inv_postal_code);
      FETCH lcu_remit_derive
       INTO ln_remit_address_id;
      gc_put_log := 'Fetching remit derive';
      PUT_LOG_LINE ( lb_debug
                    ,TRUE
                    ,gc_put_log
                   );
      IF lcu_remit_derive%NOTFOUND
      THEN
         CLOSE lcu_remit_derive;
         OPEN lcu_remit_derive ('DEFAULT', lc_inv_state, ln_inv_postal_code);
         FETCH lcu_remit_derive
          INTO ln_remit_address_id;
         IF lcu_remit_derive%NOTFOUND
         THEN
            CLOSE lcu_remit_derive;
            OPEN lcu_remit_derive ('DEFAULT', lc_inv_state, '');
            FETCH lcu_remit_derive
             INTO ln_remit_address_id;
            IF lcu_remit_derive%NOTFOUND
            THEN
               CLOSE lcu_remit_derive;
               OPEN lcu_remit_derive ('DEFAULT', 'DEFAULT', '');
               FETCH lcu_remit_derive
                INTO ln_remit_address_id;
            END IF;
         END IF;
      END IF;
      gc_put_log := 'Closing Remit_derive';
      PUT_LOG_LINE ( lb_debug
                    ,TRUE
                    ,gc_put_log
                   );
      CLOSE lcu_remit_derive;
      RETURN (ln_remit_address_id);

       ELSE
        RETURN (ln_remit_to_add); --added Defect 18203
        END IF;

   EXCEPTION
         WHEN OTHERS
         THEN
            gc_put_log := 'Error in get_remitaddressid' ||SQLERRM;
            PUT_LOG_LINE ( lb_debug
                          ,TRUE
                          ,gc_put_log
                         );
          RETURN NULL;
   END GET_REMIT_ADDRESSID;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  get_email_details                             |
-- | Description      :  This function return the email addresses for a|
-- |                     given cust_doc_id and site combination        |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |  1.0     15-MAR-2010  Ranjith Thangasamy  Initial Draft           |
-- +===================================================================+
FUNCTION get_email_details(p_cust_doc_id IN NUMBER
                              , p_site_id IN VARCHAR2
                              )
   RETURN VARCHAR
   IS
   CURSOR lcu_get_email_adrress
   IS
   SELECT hcp.email_address
   FROM hz_relationships hr
   , hz_contact_points hcp
   , hz_org_contacts hoc
   WHERE hr.relationship_code = 'CONTACT_OF'
   AND hcp.owner_table_name = 'HZ_PARTIES'
   AND hcp.owner_table_id = hr.party_id
   AND hcp.contact_point_type = 'EMAIL'
   AND hcp.contact_point_purpose = 'BILLING'
   AND hoc.party_relationship_id = hr.relationship_id
   AND hcp.primary_flag = 'Y'
   AND hoc.org_contact_id IN (SELECT DISTINCT org_contact_id
                              FROM xx_cdh_ebl_contacts xcec
                              WHERE nvl(xcec.cust_acct_site_id, 0) = nvl(p_site_id, 0)
                              AND xcec.cust_doc_id = p_cust_doc_id
                              )order by hcp.email_address; --defect#44275
   lc_email_address VARCHAR2(2000);
   lc_contact VARCHAR2(2000);
   BEGIN
      FOR email_rec IN lcu_get_email_adrress
         LOOP
         lc_email_address := lc_email_address || ';' || email_rec.email_address;
      END LOOP;
      lc_email_address := substr(lc_email_address, 2);
      RETURN lc_email_address;
   END get_email_details;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : INSERT_BLOB_FILE                                                    |
-- | Description : This procedure is used to insert BLOB file into the table.          |
-- | Parameters  :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 16-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE insert_blob_file ( p_dir             IN    VARCHAR2
                                ,p_file            IN    VARCHAR2
                                ,p_file_type       IN    VARCHAR2
                                ,p_trans_id        IN    NUMBER
                                ,p_file_id         IN    NUMBER
                                ,p_debug_flag      IN    VARCHAR2
                                ,x_err_count       OUT   NUMBER
                                )
    IS
       src_file                      BFILE := BFILENAME(p_dir, p_file);
       dst_file                      BLOB;
       lgh_file                      BINARY_INTEGER;
       lb_debug                      BOOLEAN;
       lc_error_loc                  VARCHAR2(4000);
       lc_error_debug                VARCHAR2(4000);
    BEGIN
       IF p_debug_flag = 'Y' THEN
          lb_debug  := TRUE;
       ELSE
          lb_debug  := FALSE;
       END IF;
       lc_error_loc    := 'Updating Empty Blob file in to the table';
       lc_error_debug  := 'File : '     || p_file     || CHR(13) ||
                          'File ID : '  || p_file_id  || CHR(13) ||
                          'Trans ID : ' || p_trans_id || CHR(13) ;
       UPDATE    XX_AR_EBL_FILE
       SET       file_data         = EMPTY_BLOB()
       WHERE     file_id           = p_file_id
       AND       transmission_id   = p_trans_id
       RETURNING file_data INTO dst_file;
       lc_error_loc := 'File processing has started for the file :' || p_file;
       XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                              ,FALSE
                                              ,lc_error_loc
                                              );
       lc_error_loc := 'Opening the file';
       XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                              ,FALSE
                                              ,lc_error_loc
                                              );
       DBMS_LOB.FILEOPEN(src_file, dbms_lob.file_readonly);
       lc_error_loc := 'Calculating the Length of the file';
       XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                              ,FALSE
                                              ,lc_error_loc
                                              );
       lgh_file := DBMS_LOB.GETLENGTH(src_file);
       lc_error_loc := 'Calling the Load form file procedure';
       XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                              ,FALSE
                                              ,lc_error_loc
                                              );
       DBMS_LOB.LOADFROMFILE(dst_file, src_file, lgh_file);
       lc_error_loc := 'Updating the Original file into the table';
       XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                              ,FALSE
                                              ,lc_error_loc
                                              );
       UPDATE xx_ar_ebl_file
       SET    file_data          = dst_file
             ,status             = 'RENDERED'
             ,last_updated_by    = fnd_global.user_id
             ,last_update_date   = sysdate
             ,last_update_login  = fnd_global.user_id
       WHERE  file_id            = p_file_id
       AND    transmission_id    = p_trans_id
       AND    status             = 'RENDER';
       lc_error_loc := 'The file is being closed';
       XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                              ,FALSE
                                              ,lc_error_loc
                                              );
       DBMS_LOB.FILECLOSE(src_file);
       x_err_count     := 0;
       EXCEPTION
          WHEN OTHERS THEN
             x_err_count    := 1;
             UPDATE xx_ar_ebl_file
             SET    status             = 'RENDER_ERROR'
                   ,last_updated_by    = fnd_global.user_id
                   ,last_update_date   = sysdate
                   ,last_update_login  = fnd_global.user_id
                   ,status_detail      = 'Error while : '||lc_error_loc
             WHERE  file_id            = p_file_id
             AND    transmission_id    = p_trans_id
             AND    status             = 'RENDER';
             XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                    ,TRUE
                                                    ,'Error While : '|| lc_error_loc || CHR(13) ||SQLERRM
                                                    );
             XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                    ,TRUE
                                                    ,'Error For : '|| lc_error_debug || CHR(13)
                                                    );
    END insert_blob_file;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       -- Made changes as part of R12 upgrade                                         |
-- +===================================================================================+
-- | Name        : BILL_FROM_DATE                                                      |
-- | Description : This function is used to get the bill from date for given billing cycle     |
-- |               based on the billing cycle setup                                                              |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 04-NOV-2013   Arun Gannarapu     Initial draft version               |
-- +===================================================================================+
  FUNCTION bill_from_date( p_payment_term              IN VARCHAR2 --Added for the Defect# 9632
                          ,p_invoice_creation_date     IN DATE
  )  RETURN DATE IS

   ld_billable_date ar_cons_bill_cycle_dates.billable_date%TYPE;
  BEGIN
    SELECT MAX(bcd.billable_date)  -- +1 removed for defect #27239
    INTO ld_billable_date
    FROM ar_cons_bill_cycle_dates bcd,
         ar_cons_bill_cycles_b bc,
         ra_terms t
    WHERE t.name = p_payment_term --'EM-BI16EOMN30'
    AND t.billing_cycle_id = bc.billing_cycle_id
    AND bc.bill_cycle_type = 'RECURRING'
    AND bcd.billing_cycle_id = t.billing_cycle_id
    AND bcd.billable_date < p_invoice_creation_date ;

    RETURN(ld_billable_date);

  EXCEPTION
    WHEN OTHERS
    THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Get the bill from date for payment term '||p_payment_term || 'P_invoice_creation_date '|| p_invoice_creation_date);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while getting Bill from date : '||SQLERRM);
      RETURN (NULL);
  END BILL_FROM_DATE;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : BILL_FROM_DATE                                                      |
-- | Description : This function is used to get the bill from date for the current     |
-- |               cycle.                                                              |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 11-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
FUNCTION bill_from_date_old(
                                    --p_extension_id              IN    NUMBER    --Commented for the Defect# 9632
                                    p_payment_term   IN VARCHAR2 --Added for the Defect# 9632
                                   ,p_invoice_creation_date     IN    DATE
                                   )  RETURN DATE IS
        lc_cur_frequency              VARCHAR2(1000);
        lc_cur_payment_term           VARCHAR2(1000);
        lc_cur_daynumber              VARCHAR2(10);
        lc_cur_day                    VARCHAR2(50);
        lc_cur_month                  VARCHAR2(50);
        lc_cur_quarter                VARCHAR2(10);
        lc_cur_year                   VARCHAR2(10);
        lc_frequency                  VARCHAR2(1000);
        lc_payment_term               VARCHAR2(1000);
        lc_daynumber                  VARCHAR2(10);
        lc_day                        VARCHAR2(50);
        lc_month                      VARCHAR2(50);
        lc_quarter                    VARCHAR2(10);
        lc_year                       VARCHAR2(10);
        lc_daynumber_eff              VARCHAR2(50);
        lc_month_eff                  VARCHAR2(50);
        lc_year_eff                   VARCHAR2(50);
        ld_date_eff                   DATE;
        --For the Month frquency of FIRST_MONTH, SECOND_MONTH, THIRD_MONTH, FOURTH, LAST_MONTH
        lc_first_day_of_month         VARCHAR2(50);
        ln_first_monday_daynumber     NUMBER;
        ln_monday_daynumber           NUMBER;
        lc_last_day_of_month          VARCHAR2(50);
        ld_last_date_month            DATE;
        ld_last_monday_date           DATE;
        ln_first_sunday_daynumber     NUMBER;
        ld_last_sunday_date           DATE;
        ln_sunday_daynumber           NUMBER;
        ln_first_tuesday_daynumber    NUMBER;
        ld_last_tuesday_date          DATE;
        ln_tuesday_daynumber          NUMBER;
        ln_first_wednesday_daynumber  NUMBER;
        ld_last_wednesday_date        DATE;
        ln_wednesday_daynumber        NUMBER;
        ln_first_thursday_daynumber   NUMBER;
        ld_last_thursday_date         DATE;
        ln_thursday_daynumber         NUMBER;
        ln_first_friday_daynumber     NUMBER;
        ld_last_friday_date           DATE;
        ln_friday_daynumber           NUMBER;
        ln_first_saturday_daynumber   NUMBER;
        ld_last_saturday_date         DATE;
        ln_saturday_daynumber         NUMBER;
        --For the WEEK frequency of SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY
        lc_day_of_week                VARCHAR2(50);
        ld_week_date_eff              DATE;
        --For the SEMI frequency
        ld_start_period_date          DATE;
        ld_end_period_date            DATE;
        ln_semi_start_date            NUMBER := NULL;  --Added for the Defect# 8350
        ln_semi_end_date              NUMBER := NULL;  --Added for the Defect# 8350
        --Exceptions
        lc_frequency_valid            VARCHAR2(1) := 'N';
        lc_payment_term_valid         VARCHAR2(1) := 'N';
        lc_error_loc                  VARCHAR2(4000);
        lc_error_debug                VARCHAR2(4000);
        gc_concurrent_program_name    fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
    BEGIN
        BEGIN
            lc_error_loc := 'Getting the Concurrent Program name';
            lc_error_debug := 'Concurrent Program id: '||fnd_global.conc_program_id;
          /*  SELECT FCPT.user_concurrent_program_name   --Commented to improve Performance.
            INTO   gc_concurrent_program_name
            FROM   fnd_concurrent_programs_tl FCPT
            WHERE  FCPT.concurrent_program_id = fnd_global.conc_program_id
            AND    FCPT.language = 'US';
        EXCEPTION WHEN NO_DATA_FOUND THEN
            gc_concurrent_program_name := NULL;*/  --Commented to improve Performance.
            gc_concurrent_program_name := 'XX_AR_INV_FREQ_PKG.COMPUTE_EFFECTIVE_DATE - Billing';
        END;
        --To get the Day details of Current Date
        SELECT
             TO_CHAR(SYSDATE,'DD')
            ,TO_CHAR(SYSDATE,'DAY')
            ,TO_CHAR(SYSDATE,'MM')
            ,TO_CHAR(SYSDATE,'Q')
            ,TO_CHAR(SYSDATE,'YYYY')
        INTO
             lc_cur_daynumber
            ,lc_cur_day
            ,lc_cur_month
            ,lc_cur_quarter
            ,lc_cur_year
        FROM DUAL;
        --To get the Day details of Current Date
        SELECT
             TO_CHAR(p_invoice_creation_date,'DD')
            ,TO_CHAR(p_invoice_creation_date,'DAY')
            ,TO_CHAR(p_invoice_creation_date,'MM')
            ,TO_CHAR(p_invoice_creation_date,'Q')
            ,TO_CHAR(p_invoice_creation_date,'YYYY')
        INTO
             lc_daynumber
            ,lc_day
            ,lc_month
            ,lc_quarter
            ,lc_year
        FROM DUAL;
        --Comment for the Defect# 9632
        /*lc_error_loc := 'Getting the Frequency, Payment Term';
        lc_error_debug := 'Extension id: '||p_extension_id;
        SELECT RT.attribute1, RT.attribute2
        INTO   lc_frequency, lc_payment_term
        FROM   xx_cdh_a_ext_billdocs_v XCAEB
               ,ra_terms               RT                   --Defect 2952.
        WHERE  XCAEB.extension_id = p_extension_id
               and RT.name = XCAEB.billdocs_payment_term;   --Defect 2952.*/
        --Added for the Defect# 9632
        lc_error_loc := 'Getting the Frequency, Payment Term';
        lc_error_debug := 'Billing Payment Term: '||p_payment_term;
        BEGIN
           SELECT RT.attribute1, RT.attribute2
           INTO   lc_frequency, lc_payment_term
           FROM   ra_terms RT
           WHERE  RT.name = p_payment_term;
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Location: '||lc_error_loc);
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Payment Term is not defined in RA_TERMS table.');
        END;
        --Start of addition for the new Frequencies
        IF (lc_frequency = 'MNTHDAY') THEN
            lc_frequency_valid := 'Y';
            --Sunday Frequencies
            IF ((lc_payment_term = 'SUNDAY1') OR (lc_payment_term = 'SUNDAY2') OR (lc_payment_term = 'SUNDAY3') OR (lc_payment_term = 'SUNDAY4')) THEN
                lc_payment_term_valid := 'Y';
                lc_payment_term_valid := 'Y';
                lc_first_day_of_month := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),0),'DY'));
                lc_month := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),0),'MM'));
                lc_year := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),0),'YYYY'));
                SELECT DECODE(lc_first_day_of_month
                              ,'SUN',1
                              ,'MON',7
                              ,'TUE',6
                              ,'WED',5
                              ,'THU',4
                              ,'FRI',3
                              ,'SAT',2)
                INTO   ln_first_sunday_daynumber
                FROM DUAL;
                SELECT DECODE(lc_payment_term
                              ,'SUNDAY1',ln_first_sunday_daynumber
                              ,'SUNDAY2',ln_first_sunday_daynumber+7
                              ,'SUNDAY3',ln_first_sunday_daynumber+14
                              ,'SUNDAY4',ln_first_sunday_daynumber+21)
                INTO   ln_sunday_daynumber
                FROM DUAL;
       IF (lc_daynumber <= ln_sunday_daynumber ) THEN
                lc_first_day_of_month := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),-1),'DY'));
                lc_month := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),-1),'MM'));
                lc_year := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),-1),'YYYY'));
                SELECT DECODE(lc_first_day_of_month
                              ,'SUN',1
                              ,'MON',7
                              ,'TUE',6
                              ,'WED',5
                              ,'THU',4
                              ,'FRI',3
                              ,'SAT',2)
                INTO   ln_first_sunday_daynumber
                FROM DUAL;
                SELECT DECODE(lc_payment_term
                              ,'SUNDAY1',ln_first_sunday_daynumber
                              ,'SUNDAY2',ln_first_sunday_daynumber+7
                              ,'SUNDAY3',ln_first_sunday_daynumber+14
                              ,'SUNDAY4',ln_first_sunday_daynumber+21)
                INTO   ln_sunday_daynumber
                FROM DUAL;
        END IF;
                 lc_daynumber_eff  := ln_sunday_daynumber;
                lc_month_eff      := lc_month;
                lc_year_eff       := lc_year;
            END IF;
            IF ((lc_payment_term = 'SUNDAYL')) THEN
                lc_payment_term_valid := 'Y';
                ld_last_date_month := LAST_DAY(ADD_MONTHS(p_invoice_creation_date,0));
                lc_last_day_of_month := to_char(ld_last_date_month,'DY');
                SELECT    DECODE(lc_last_day_of_month
                            ,'SUN',ld_last_date_month
                            ,'MON',ld_last_date_month-1
                            ,'TUE',ld_last_date_month-2
                            ,'WED',ld_last_date_month-3
                            ,'THU',ld_last_date_month-4
                            ,'FRI',ld_last_date_month-5
                            ,'SAT',ld_last_date_month-6)
                INTO   ld_last_sunday_date
                FROM   DUAL;
      IF (lc_daynumber <=ld_last_sunday_date) THEN
                ld_last_date_month := LAST_DAY(ADD_MONTHS(p_invoice_creation_date,-1));
                lc_last_day_of_month := to_char(ld_last_date_month,'DY');
                SELECT    DECODE(lc_last_day_of_month
                            ,'SUN',ld_last_date_month
                            ,'MON',ld_last_date_month-1
                            ,'TUE',ld_last_date_month-2
                            ,'WED',ld_last_date_month-3
                            ,'THU',ld_last_date_month-4
                            ,'FRI',ld_last_date_month-5
                            ,'SAT',ld_last_date_month-6)
                INTO   ld_last_sunday_date
                FROM   DUAL;
      END IF;
               ld_last_sunday_date :=ld_last_sunday_date+1;
                lc_daynumber_eff := to_char(ld_last_sunday_date,'DD');          --Day
                lc_month_eff := to_char(ld_last_sunday_date,'MM');
                lc_year_eff := to_char(ld_last_sunday_date,'YYYY');
            END IF;
            --Monday Frequencies
            IF ((lc_payment_term = 'MONDAY1') OR (lc_payment_term = 'MONDAY2') OR (lc_payment_term = 'MONDAY3') OR (lc_payment_term = 'MONDAY4')) THEN
                lc_payment_term_valid := 'Y';
                lc_first_day_of_month := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),0),'DY'));
                lc_month := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),0),'MM'));
                lc_year := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),0),'YYYY'));
                SELECT DECODE(lc_first_day_of_month
                              ,'SUN',2
                              ,'MON',1
                              ,'TUE',7
                              ,'WED',6
                              ,'THU',5
                              ,'FRI',4
                              ,'SAT',3)
                INTO   ln_first_monday_daynumber
                FROM DUAL;
                SELECT DECODE(lc_payment_term
                              ,'MONDAY1',ln_first_monday_daynumber
                              ,'MONDAY2',ln_first_monday_daynumber+7
                              ,'MONDAY3',ln_first_monday_daynumber+14
                              ,'MONDAY4',ln_first_monday_daynumber+21)
                INTO   ln_monday_daynumber
                 FROM DUAL;
                IF (lc_daynumber <= ln_monday_daynumber) THEN
                lc_first_day_of_month := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),-1),'DY'));
                lc_month := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),-1),'MM'));
                lc_year := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),-1),'YYYY'));
                SELECT DECODE(lc_first_day_of_month
                              ,'SUN',2
                              ,'MON',1
                              ,'TUE',7
                              ,'WED',6
                              ,'THU',5
                              ,'FRI',4
                              ,'SAT',3)
                INTO   ln_first_monday_daynumber
                FROM DUAL;
                SELECT DECODE(lc_payment_term
                              ,'MONDAY1',ln_first_monday_daynumber
                              ,'MONDAY2',ln_first_monday_daynumber+7
                              ,'MONDAY3',ln_first_monday_daynumber+14
                              ,'MONDAY4',ln_first_monday_daynumber+21)
                INTO   ln_monday_daynumber
                FROM DUAl;
                END IF;
                lc_daynumber_eff  := ln_monday_daynumber;
                lc_month_eff      := lc_month;
                lc_year_eff       := lc_year;
            END IF;
            IF ((lc_payment_term = 'MONDAYL')) THEN
                lc_payment_term_valid := 'Y';
                ld_last_date_month := LAST_DAY(ADD_MONTHS(p_invoice_creation_date,0));
                lc_last_day_of_month := to_char(ld_last_date_month,'DY');
                SELECT    DECODE(lc_last_day_of_month
                            ,'SUN',ld_last_date_month-6
                            ,'MON',ld_last_date_month
                            ,'TUE',ld_last_date_month-1
                            ,'WED',ld_last_date_month-2
                            ,'THU',ld_last_date_month-3
                            ,'FRI',ld_last_date_month-4
                            ,'SAT',ld_last_date_month-5)
                INTO   ld_last_monday_date
                FROM   DUAL;
                IF (lc_daynumber <= to_char(ld_last_monday_date,'DY')) THEN
                ld_last_date_month := LAST_DAY(ADD_MONTHS(p_invoice_creation_date,-1));
                lc_last_day_of_month := to_char(ld_last_date_month,'DY');
                SELECT    DECODE(lc_last_day_of_month
                            ,'SUN',ld_last_date_month-6
                            ,'MON',ld_last_date_month
                            ,'TUE',ld_last_date_month-1
                            ,'WED',ld_last_date_month-2
                            ,'THU',ld_last_date_month-3
                            ,'FRI',ld_last_date_month-4
                            ,'SAT',ld_last_date_month-5)
                INTO   ld_last_monday_date
                FROM   DUAL;
                END IF;
                lc_daynumber_eff := to_char(ld_last_monday_date,'DD');          --Day
                lc_month_eff := to_char(ld_last_monday_date,'MM');
                lc_year_eff := to_char(ld_last_monday_date,'YYYY');
            END IF;
            --Tuesday Frequencies
            IF ((lc_payment_term = 'TUESDAY1') OR (lc_payment_term = 'TUESDAY2') OR (lc_payment_term = 'TUESDAY3') OR (lc_payment_term = 'TUESDAY4')) THEN
                lc_payment_term_valid := 'Y';
                lc_first_day_of_month := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),0),'DY'));
                lc_month := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),0),'MM'));
                lc_year := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),0),'YYYY'));
                SELECT DECODE(lc_first_day_of_month
                              ,'SUN',3
                              ,'MON',2
                              ,'TUE',1
                              ,'WED',7
                              ,'THU',6
                              ,'FRI',5
                              ,'SAT',4)
                INTO   ln_first_tuesday_daynumber
                FROM DUAL;
                SELECT DECODE(lc_payment_term
                              ,'TUESDAY1',ln_first_tuesday_daynumber
                              ,'TUESDAY2',ln_first_tuesday_daynumber+7
                              ,'TUESDAY3',ln_first_tuesday_daynumber+14
                              ,'TUESDAY4',ln_first_tuesday_daynumber+21)
                INTO   ln_tuesday_daynumber
                FROM DUAL;
         IF (lc_daynumber <= ln_tuesday_daynumber) THEN
                lc_first_day_of_month := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),-1),'DY'));
                lc_month := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),-1),'MM'));
                lc_year := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),-1),'YYYY'));
                SELECT DECODE(lc_first_day_of_month
                              ,'SUN',3
                              ,'MON',2
                              ,'TUE',1
                              ,'WED',7
                              ,'THU',6
                              ,'FRI',5
                              ,'SAT',4)
                INTO   ln_first_tuesday_daynumber
                FROM DUAL;
                SELECT DECODE(lc_payment_term
                              ,'TUESDAY1',ln_first_tuesday_daynumber
                              ,'TUESDAY2',ln_first_tuesday_daynumber+7
                              ,'TUESDAY3',ln_first_tuesday_daynumber+14
                              ,'TUESDAY4',ln_first_tuesday_daynumber+21)
                INTO   ln_tuesday_daynumber
                FROM DUAL;
         END IF;
                lc_daynumber_eff  := ln_tuesday_daynumber;
                lc_month_eff      := lc_month;
                lc_year_eff       := lc_year;
            END IF;
            IF ((lc_payment_term = 'TUESDAYL')) THEN
                lc_payment_term_valid := 'Y';
                ld_last_date_month := LAST_DAY(ADD_MONTHS(p_invoice_creation_date,0));
                lc_last_day_of_month := to_char(ld_last_date_month,'DY');
                SELECT    DECODE(lc_last_day_of_month
                            ,'SUN',ld_last_date_month-5
                            ,'MON',ld_last_date_month-6
                            ,'TUE',ld_last_date_month
                            ,'WED',ld_last_date_month-1
                            ,'THU',ld_last_date_month-2
                            ,'FRI',ld_last_date_month-3
                            ,'SAT',ld_last_date_month-4)
                INTO   ld_last_tuesday_date
                FROM   DUAL;
                IF (lc_daynumber <= to_char(ld_last_tuesday_date,'DY')) THEN
                ld_last_date_month := LAST_DAY(ADD_MONTHS(p_invoice_creation_date,-1));
                lc_last_day_of_month := to_char(ld_last_date_month,'DY');
                SELECT    DECODE(lc_last_day_of_month
                            ,'SUN',ld_last_date_month-5
                            ,'MON',ld_last_date_month-6
                            ,'TUE',ld_last_date_month
                            ,'WED',ld_last_date_month-1
                            ,'THU',ld_last_date_month-2
                            ,'FRI',ld_last_date_month-3
                            ,'SAT',ld_last_date_month-4)
                INTO   ld_last_tuesday_date
                FROM   DUAL;
                END IF;
                lc_daynumber_eff := to_char(ld_last_tuesday_date,'DD');          --Day
                lc_month_eff := to_char(ld_last_tuesday_date,'MM');
                lc_year_eff := to_char(ld_last_tuesday_date,'YYYY');
            END IF;
            --Wednesday Frequencies
            IF ((lc_payment_term = 'WEDNESDAY1') OR (lc_payment_term = 'WEDNESDAY2') OR (lc_payment_term = 'WEDNESDAY3') OR (lc_payment_term = 'WEDNESDAY4')) THEN
                lc_payment_term_valid := 'Y';
                lc_first_day_of_month := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),0),'DY'));
                lc_month := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),0),'MM'));
                lc_year := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),0),'YYYY'));
                SELECT DECODE(lc_first_day_of_month
                              ,'SUN',4
                              ,'MON',3
                              ,'TUE',2
                              ,'WED',1
                              ,'THU',7
                              ,'FRI',6
                              ,'SAT',5)
                INTO   ln_first_wednesday_daynumber
                FROM DUAL;
                SELECT DECODE(lc_payment_term
                              ,'WEDNESDAY1',ln_first_wednesday_daynumber
                              ,'WEDNESDAY2',ln_first_wednesday_daynumber+7
                              ,'WEDNESDAY3',ln_first_wednesday_daynumber+14
                              ,'WEDNESDAY4',ln_first_wednesday_daynumber+21)
                INTO   ln_wednesday_daynumber
                FROM DUAL;
         IF (lc_daynumber <= ln_wednesday_daynumber) THEN
                lc_first_day_of_month := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),-1),'DY'));
                lc_month := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),-1),'MM'));
                lc_year := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),-1),'YYYY'));
                SELECT DECODE(lc_first_day_of_month
                              ,'SUN',4
                              ,'MON',3
                              ,'TUE',2
                              ,'WED',1
                              ,'THU',7
                              ,'FRI',6
                              ,'SAT',5)
                INTO   ln_first_wednesday_daynumber
                FROM DUAL;
                SELECT DECODE(lc_payment_term
                              ,'WEDNESDAY1',ln_first_wednesday_daynumber
                              ,'WEDNESDAY2',ln_first_wednesday_daynumber+7
                              ,'WEDNESDAY3',ln_first_wednesday_daynumber+14
                              ,'WEDNESDAY4',ln_first_wednesday_daynumber+21)
                INTO   ln_wednesday_daynumber
                FROM DUAL;
         END IF;
                lc_daynumber_eff  := ln_wednesday_daynumber;
                lc_month_eff      := lc_month;
                lc_year_eff       := lc_year;
            END IF;
            IF ((lc_payment_term = 'WEDNESDAYL')) THEN
                lc_payment_term_valid := 'Y';
                ld_last_date_month := LAST_DAY(ADD_MONTHS(p_invoice_creation_date,0));
                lc_last_day_of_month := to_char(ld_last_date_month,'DY');
                SELECT    DECODE(lc_last_day_of_month
                            ,'SUN',ld_last_date_month-4
                            ,'MON',ld_last_date_month-5
                            ,'TUE',ld_last_date_month-6
                            ,'WED',ld_last_date_month
                            ,'THU',ld_last_date_month-1
                            ,'FRI',ld_last_date_month-2
                            ,'SAT',ld_last_date_month-3)
                INTO   ld_last_wednesday_date
                FROM   DUAL;
                IF (lc_daynumber <= to_char(ld_last_wednesday_date,'DY')) THEN
                ld_last_date_month := LAST_DAY(ADD_MONTHS(p_invoice_creation_date,-1));
                lc_last_day_of_month := to_char(ld_last_date_month,'DY');
                SELECT    DECODE(lc_last_day_of_month
                            ,'SUN',ld_last_date_month-4
                            ,'MON',ld_last_date_month-5
                            ,'TUE',ld_last_date_month-6
                            ,'WED',ld_last_date_month
                            ,'THU',ld_last_date_month-1
                            ,'FRI',ld_last_date_month-2
                            ,'SAT',ld_last_date_month-3)
                INTO   ld_last_wednesday_date
                FROM   DUAL;
                END IF;
                lc_daynumber_eff := to_char(ld_last_wednesday_date,'DD');          --Day
                lc_month_eff := to_char(ld_last_wednesday_date,'MM');
                lc_year_eff := to_char(ld_last_wednesday_date,'YYYY');
            END IF;
            --Thursday Frequencies
            IF ((lc_payment_term = 'THURSDAY1') OR (lc_payment_term = 'THURSDAY2') OR (lc_payment_term = 'THURSDAY3') OR (lc_payment_term = 'THURSDAY4')) THEN
                lc_payment_term_valid := 'Y';
                lc_first_day_of_month := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),0),'DY'));
                lc_month := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),0),'MM'));
                lc_year := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),0),'YYYY'));
                SELECT DECODE(lc_first_day_of_month
                              ,'SUN',5
                              ,'MON',4
                              ,'TUE',3
                              ,'WED',2
                              ,'THU',1
                              ,'FRI',7
                              ,'SAT',6)
                INTO   ln_first_thursday_daynumber
                FROM DUAL;
                SELECT DECODE(lc_payment_term
                              ,'THURSDAY1',ln_first_thursday_daynumber
                              ,'THURSDAY2',ln_first_thursday_daynumber+7
                              ,'THURSDAY3',ln_first_thursday_daynumber+14
                              ,'THURSDAY4',ln_first_thursday_daynumber+21)
                INTO   ln_thursday_daynumber
                FROM DUAL;
         IF (lc_daynumber <= ln_thursday_daynumber) THEN
                lc_first_day_of_month := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),-1),'DY'));
                lc_month := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),-1),'MM'));
                lc_year := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),-1),'YYYY'));
                SELECT DECODE(lc_first_day_of_month
                              ,'SUN',5
                              ,'MON',4
                              ,'TUE',3
                              ,'WED',2
                              ,'THU',1
                              ,'FRI',7
                              ,'SAT',6)
                INTO   ln_first_thursday_daynumber
                FROM DUAL;
                SELECT DECODE(lc_payment_term
                              ,'THURSDAY1',ln_first_thursday_daynumber
                              ,'THURSDAY2',ln_first_thursday_daynumber+7
                              ,'THURSDAY3',ln_first_thursday_daynumber+14
                              ,'THURSDAY4',ln_first_thursday_daynumber+21)
                INTO   ln_thursday_daynumber
                FROM DUAL;
         END IF;
               lc_daynumber_eff  := ln_thursday_daynumber;
                lc_month_eff      := lc_month;
                lc_year_eff       := lc_year;
            END IF;
            IF ((lc_payment_term = 'THURSDAYL')) THEN
                lc_payment_term_valid := 'Y';
                ld_last_date_month := LAST_DAY(ADD_MONTHS(p_invoice_creation_date,0));
                lc_last_day_of_month := to_char(ld_last_date_month,'DY');
                SELECT    DECODE(lc_last_day_of_month
                            ,'SUN',ld_last_date_month-3
                            ,'MON',ld_last_date_month-4
                            ,'TUE',ld_last_date_month-5
                            ,'WED',ld_last_date_month-6
                            ,'THU',ld_last_date_month
                            ,'FRI',ld_last_date_month-1
                            ,'SAT',ld_last_date_month-2)
                INTO   ld_last_thursday_date
                FROM   DUAL;
                IF (lc_daynumber <= to_char(ld_last_thursday_date,'DY')) THEN
                ld_last_date_month := LAST_DAY(ADD_MONTHS(p_invoice_creation_date,-1));
                lc_last_day_of_month := to_char(ld_last_date_month,'DY');
                SELECT    DECODE(lc_last_day_of_month
                            ,'SUN',ld_last_date_month-3
                            ,'MON',ld_last_date_month-4
                            ,'TUE',ld_last_date_month-5
                            ,'WED',ld_last_date_month-6
                            ,'THU',ld_last_date_month
                            ,'FRI',ld_last_date_month-1
                            ,'SAT',ld_last_date_month-2)
                INTO   ld_last_thursday_date
                FROM   DUAL;
                END IF;
                --If the Invoice Creation Date is falling after the LAST Thursday then , get the LAST Thursday of the Next month
                lc_daynumber_eff := to_char(ld_last_thursday_date,'DD');          --Day
                lc_month_eff := to_char(ld_last_thursday_date,'MM');
                lc_year_eff := to_char(ld_last_thursday_date,'YYYY');
            END IF;
            --Friday Frequencies
            IF ((lc_payment_term = 'FRIDAY1') OR (lc_payment_term = 'FRIDAY2') OR (lc_payment_term = 'FRIDAY3') OR (lc_payment_term = 'FRIDAY4')) THEN
                lc_payment_term_valid := 'Y';
                lc_first_day_of_month := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),0),'DY'));
                lc_month := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),0),'MM'));
                lc_year := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),0),'YYYY'));
                SELECT DECODE(lc_first_day_of_month
                              ,'SUN',6
                              ,'MON',5
                              ,'TUE',4
                              ,'WED',3
                              ,'THU',2
                              ,'FRI',1
                              ,'SAT',7)
                INTO   ln_first_friday_daynumber
                FROM DUAL;
                SELECT DECODE(lc_payment_term
                              ,'FRIDAY1',ln_first_friday_daynumber
                              ,'FRIDAY2',ln_first_friday_daynumber+7
                              ,'FRIDAY3',ln_first_friday_daynumber+14
                              ,'FRIDAY4',ln_first_friday_daynumber+21)
                INTO   ln_friday_daynumber
                FROM DUAL;
         IF (lc_daynumber <= ln_friday_daynumber) THEN
                lc_first_day_of_month := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),-1),'DY'));
                lc_month := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),-1),'MM'));
                lc_year := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),-1),'YYYY'));
                SELECT DECODE(lc_first_day_of_month
                              ,'SUN',6
                              ,'MON',5
                              ,'TUE',4
                              ,'WED',3
                              ,'THU',2
                              ,'FRI',1
                              ,'SAT',7)
                INTO   ln_first_friday_daynumber
                FROM DUAL;
                SELECT DECODE(lc_payment_term
                              ,'FRIDAY1',ln_first_friday_daynumber
                              ,'FRIDAY2',ln_first_friday_daynumber+7
                              ,'FRIDAY3',ln_first_friday_daynumber+14
                              ,'FRIDAY4',ln_first_friday_daynumber+21)
                INTO   ln_friday_daynumber
                FROM DUAL;
         END IF;
                lc_daynumber_eff  := ln_friday_daynumber;
                lc_month_eff      := lc_month;
                lc_year_eff       := lc_year;
            END IF;
            IF ((lc_payment_term = 'FRIDAYL')) THEN
                lc_payment_term_valid := 'Y';
                ld_last_date_month := LAST_DAY(ADD_MONTHS(p_invoice_creation_date,0));
                lc_last_day_of_month := to_char(ld_last_date_month,'DY');
                SELECT    DECODE(lc_last_day_of_month
                            ,'SUN',ld_last_date_month-2
                            ,'MON',ld_last_date_month-3
                            ,'TUE',ld_last_date_month-4
                            ,'WED',ld_last_date_month-5
                            ,'THU',ld_last_date_month-6
                            ,'FRI',ld_last_date_month
                            ,'SAT',ld_last_date_month-1)
                INTO   ld_last_friday_date
                FROM   DUAL;
                IF (lc_daynumber <= to_char(ld_last_friday_date,'DY')) THEN
                ld_last_date_month := LAST_DAY(ADD_MONTHS(p_invoice_creation_date,-1));
                lc_last_day_of_month := to_char(ld_last_date_month,'DY');
                SELECT    DECODE(lc_last_day_of_month
                            ,'SUN',ld_last_date_month-2
                            ,'MON',ld_last_date_month-3
                            ,'TUE',ld_last_date_month-4
                            ,'WED',ld_last_date_month-5
                            ,'THU',ld_last_date_month-6
                            ,'FRI',ld_last_date_month
                            ,'SAT',ld_last_date_month-1)
                INTO   ld_last_friday_date
                FROM   DUAL;
                END IF;
                lc_daynumber_eff := to_char(ld_last_friday_date,'DD');          --Day
                lc_month_eff := to_char(ld_last_friday_date,'MM');
                lc_year_eff := to_char(ld_last_friday_date,'YYYY');
            END IF;
            --Saturday Frequencies
            IF ((lc_payment_term = 'SATURDAY1') OR (lc_payment_term = 'SATURDAY2') OR (lc_payment_term = 'SATURDAY3') OR (lc_payment_term = 'SATURDAY4')) THEN
                lc_payment_term_valid := 'Y';
                lc_first_day_of_month := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),0),'DY'));
                lc_month := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),0),'MM'));
                lc_year := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),0),'YYYY'));
                SELECT DECODE(lc_first_day_of_month
                              ,'SUN',7
                              ,'MON',6
                              ,'TUE',5
                              ,'WED',4
                              ,'THU',3
                              ,'FRI',2
                              ,'SAT',1)
                INTO   ln_first_saturday_daynumber
                FROM DUAL;
                SELECT DECODE(lc_payment_term
                              ,'SATURDAY1',ln_first_saturday_daynumber
                              ,'SATURDAY2',ln_first_saturday_daynumber+7
                              ,'SATURDAY3',ln_first_saturday_daynumber+14
                              ,'SATURDAY4',ln_first_saturday_daynumber+21)
                INTO   ln_saturday_daynumber
                FROM DUAL;
         IF (lc_daynumber <= ln_saturday_daynumber) THEN
                lc_first_day_of_month := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),-1),'DY'));
                lc_month := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),-1),'MM'));
                lc_year := trim(to_char(ADD_MONTHS(to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY'),-1),'YYYY'));
                SELECT DECODE(lc_first_day_of_month
                              ,'SUN',7
                              ,'MON',6
                              ,'TUE',5
                              ,'WED',4
                              ,'THU',3
                              ,'FRI',2
                              ,'SAT',1)
                INTO   ln_first_saturday_daynumber
                FROM DUAL;
                SELECT DECODE(lc_payment_term
                              ,'SATURDAY1',ln_first_saturday_daynumber
                              ,'SATURDAY2',ln_first_saturday_daynumber+7
                              ,'SATURDAY3',ln_first_saturday_daynumber+14
                              ,'SATURDAY4',ln_first_saturday_daynumber+21)
                INTO   ln_saturday_daynumber
                FROM DUAL;
         END IF;
                lc_daynumber_eff  := ln_saturday_daynumber;
                lc_month_eff      := lc_month;
                lc_year_eff       := lc_year;
            END IF;
            END IF;
            IF ((lc_payment_term = 'SATURDAYL')) THEN
                lc_payment_term_valid := 'Y';
                ld_last_date_month := LAST_DAY(ADD_MONTHS(p_invoice_creation_date,0));
                lc_last_day_of_month := to_char(ld_last_date_month,'DY');
                SELECT    DECODE(lc_last_day_of_month
                            ,'SUN',ld_last_date_month-1
                            ,'MON',ld_last_date_month-2
                            ,'TUE',ld_last_date_month-3
                            ,'WED',ld_last_date_month-4
                            ,'THU',ld_last_date_month-5
                            ,'FRI',ld_last_date_month-6
                            ,'SAT',ld_last_date_month)
                INTO   ld_last_saturday_date
                FROM   DUAL;
                IF (lc_daynumber <= to_char(ld_last_saturday_date,'DY')) THEN
                ld_last_date_month := LAST_DAY(ADD_MONTHS(p_invoice_creation_date,-1));
                lc_last_day_of_month := to_char(ld_last_date_month,'DY');
                SELECT    DECODE(lc_last_day_of_month
                            ,'SUN',ld_last_date_month-1
                            ,'MON',ld_last_date_month-2
                            ,'TUE',ld_last_date_month-3
                            ,'WED',ld_last_date_month-4
                            ,'THU',ld_last_date_month-5
                            ,'FRI',ld_last_date_month-6
                            ,'SAT',ld_last_date_month)
                INTO   ld_last_saturday_date
                FROM   DUAL;
                END IF;
                lc_daynumber_eff := to_char(ld_last_saturday_date,'DD');          --Day
                lc_month_eff := to_char(ld_last_saturday_date,'MM');
                lc_year_eff := to_char(ld_last_saturday_date,'YYYY');
        END IF;
        IF (lc_frequency = 'WDAY') THEN
            lc_frequency_valid := 'Y';
            lc_day_of_week := to_char(p_invoice_creation_date,'DY');
            lc_payment_term_valid := 'Y';
            --Getting the date of the next coming Monday
            SELECT  DECODE(lc_day_of_week
                    ,'SUN',p_invoice_creation_date-3
                    ,'MON',p_invoice_creation_date-4
                    ,'TUE',p_invoice_creation_date-1
                    ,'WED',p_invoice_creation_date-1
                    ,'THU',p_invoice_creation_date-1
                    ,'FRI',p_invoice_creation_date-1
                    ,'SAT',p_invoice_creation_date-2)
            INTO   ld_week_date_eff
            FROM   DUAL;
            RETURN (ld_week_date_eff);
        END IF;
        IF (lc_frequency = 'MNTH') THEN
            lc_frequency_valid := 'Y';
            IF (lc_payment_term = '1') THEN
                lc_payment_term_valid := 'Y';
                    lc_daynumber_eff := 1;          --Day
                    lc_month_eff := lc_month-1;
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                END IF;
            IF (lc_payment_term = '2') THEN
                lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 2) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 2;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 2;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                  END IF;
            IF (lc_payment_term = '3') THEN
                lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 3) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 3;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 3;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                  END IF;
            IF (lc_payment_term = '4') THEN
                lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 4) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 4;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 4;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                  END IF;
            IF (lc_payment_term = '5') THEN
                lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 5) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 5;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 5;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                  END IF;
             IF (lc_payment_term = '6') THEN
                lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 6) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 6;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 6;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                  END IF;
            IF (lc_payment_term = '7') THEN
                lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 7) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 7;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 7;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                  END IF;
             IF (lc_payment_term = '8') THEN
                lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 8) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 8;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 8;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                  END IF;
             IF (lc_payment_term = '9') THEN
                lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 9) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 9;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 9;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                  END IF;
              IF (lc_payment_term = '10') THEN
                lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 10) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 10;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 10;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                  END IF;
             IF (lc_payment_term = '11') THEN
                lc_payment_term_valid := 'Y';
               IF (lc_daynumber <=11) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 11;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 11;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                  END IF;
             IF (lc_payment_term = '12') THEN
                lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 12) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 12;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 12;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                  END IF;
             IF (lc_payment_term = '13') THEN
                lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 13) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 13;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 13;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                  END IF;
             IF (lc_payment_term = '14') THEN
                lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 14) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 14;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 14;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                  END IF;
             IF (lc_payment_term = '15') THEN
                lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 15) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 15;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 15;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                  END IF;
             IF (lc_payment_term = '16') THEN
                lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 16) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 16;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 16;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                  END IF;
             IF (lc_payment_term = '17') THEN
                lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 17) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 17;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 17;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                  END IF;
              IF (lc_payment_term = '18') THEN
                lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 18) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 18;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 18;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                  END IF;
             IF (lc_payment_term = '19') THEN
                lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 19) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 19;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 19;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                  END IF;
             IF (lc_payment_term = '20') THEN
                lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 20) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 20;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 20;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                  END IF;
             IF (lc_payment_term = '21') THEN
                lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 21) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 21;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 21;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                  END IF;
             IF (lc_payment_term = '22') THEN
                lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 22) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 22;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 22;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                  END IF;
             IF (lc_payment_term = '23') THEN
                lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 23) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 23;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 23;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                  END IF;
             IF (lc_payment_term = '24') THEN
                lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 24) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 24;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 24;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                  END IF;
              IF (lc_payment_term = '25') THEN
                lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 25) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 25;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 25;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                  END IF;
             IF (lc_payment_term = '26') THEN
                lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 26) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 26;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 26;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                  END IF;
             IF (lc_payment_term = '27') THEN
                lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 27) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 27;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 27;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                  END IF;
             IF (lc_payment_term = '28') THEN
                lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 28) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 28;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 28;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                  END IF;
             IF (lc_payment_term = '29') THEN
                lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 29) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 29;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 29;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                 ld_last_date_month   := LAST_DAY(TO_DATE('01-'||lc_month_eff||'-'||lc_year_eff,'DD-MM-YY'));  -- Added for defect 1375
                lc_last_day_of_month := TO_CHAR(ld_last_date_month,'DD');
                IF lc_payment_term > lc_last_day_of_month THEN
                   lc_daynumber_eff := lc_last_day_of_month;                    -- For Feb29 , set as Feb 28(EOM)
                END IF;
                  -- End of Changes for Defect 1375
            END IF;
            IF (lc_payment_term = '30') THEN
                 lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 30) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 30;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 30;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                 ld_last_date_month   := LAST_DAY(TO_DATE('01-'||lc_month_eff||'-'||lc_year_eff,'DD-MM-YY'));  -- Added for defect 1375
                lc_last_day_of_month := TO_CHAR(ld_last_date_month,'DD');
                IF lc_payment_term > lc_last_day_of_month THEN
                   lc_daynumber_eff := lc_last_day_of_month;                    -- For Feb29 , set as Feb 28(EOM)
                END IF;
                  -- End of Changes for Defect 1375
            END IF;
            IF (lc_payment_term = '31') THEN
                 lc_payment_term_valid := 'Y';
               IF (lc_daynumber <= 31) THEN      --Day
                    lc_month_eff := lc_month-1;
                    lc_daynumber_eff := 31;       --Day
                    lc_year_eff := lc_year;
                     IF (lc_month_eff< 1) THEN
                        lc_month_eff := 12;
                        lc_year_eff := lc_year-1;
                      END IF;
                    ELSE
                    lc_daynumber_eff := 31;          --Day
                    lc_month_eff := lc_month;
                    lc_year_eff := lc_year;
                    END IF;
                 ld_last_date_month   := LAST_DAY(TO_DATE('01-'||lc_month_eff||'-'||lc_year_eff,'DD-MM-YY'));  -- Added for defect 1375
                lc_last_day_of_month := TO_CHAR(ld_last_date_month,'DD');
                IF lc_payment_term > lc_last_day_of_month THEN
                   lc_daynumber_eff := lc_last_day_of_month;                    -- For Feb29 , set as Feb 28(EOM)
                END IF;
                  -- End of Changes for Defect 1375
                END IF;
        ELSIF (lc_frequency like 'DAIL%') THEN
           lc_frequency_valid := 'Y';
            lc_payment_term_valid := 'Y';
      SELECT
             TO_CHAR(p_invoice_creation_date-1,'DD')
            ,TO_CHAR(p_invoice_creation_date-1,'MM')
            ,TO_CHAR(p_invoice_creation_date-1,'YYYY')
        INTO
             lc_daynumber_eff
            ,lc_month_eff
            ,lc_year_eff
        FROM DUAL;
         ELSIF (lc_frequency = 'QUAR') THEN
            lc_frequency_valid := 'Y';
            lc_payment_term_valid := 'Y';
            --Fourth Quarter
            IF (lc_month >= 9) THEN
                lc_daynumber_eff := '30';
                lc_month_eff     := '06';
                lc_year_eff      := lc_year;
            --Third Quarter
            ELSIF (lc_month >= 6) THEN
                lc_daynumber_eff := '31';
                lc_month_eff     := '03';
                lc_year_eff      := lc_year;
            --Second Quarter
            ELSIF (lc_month >= 3) THEN
                lc_daynumber_eff := '31';
                lc_month_eff     := '12';
                lc_year_eff      := lc_year;
            --First Quarter
            ELSE
                lc_daynumber_eff := '30';
                lc_month_eff     := '09';
                lc_year_eff      := lc_year;
            END IF;
        ELSIF (lc_frequency = 'WEEK') THEN
            lc_frequency_valid := 'Y';
            lc_day_of_week := to_char(p_invoice_creation_date,'DY');
            -- below if block added for defect 352
            IF (lc_payment_term = 'SUNDAY') THEN
                lc_payment_term_valid := 'Y';
                --Getting the date of the next coming SUNDAY
                SELECT  DECODE(lc_day_of_week
                        ,'SUN',p_invoice_creation_date
                        ,'MON',p_invoice_creation_date+6
                        ,'TUE',p_invoice_creation_date+5
                        ,'WED',p_invoice_creation_date+4
                        ,'THU',p_invoice_creation_date+3
                        ,'FRI',p_invoice_creation_date+2
                        ,'SAT',p_invoice_creation_date+1)-7
                INTO   ld_week_date_eff
                FROM   DUAL;
            END IF;
        --    IF (lc_payment_term = 'SUNDAY' OR lc_payment_term = 'MONDAY') THEN  commented for defect 352
           IF (lc_payment_term = 'MONDAY')  THEN  --added for defect 352
                lc_payment_term_valid := 'Y';
                --Getting the date of the next coming Monday
                SELECT  DECODE(lc_day_of_week
                        ,'SUN',p_invoice_creation_date+1
                        ,'MON',p_invoice_creation_date
                        ,'TUE',p_invoice_creation_date+6
                        ,'WED',p_invoice_creation_date+5
                        ,'THU',p_invoice_creation_date+4
                        ,'FRI',p_invoice_creation_date+3
                        ,'SAT',p_invoice_creation_date+2)-7
                INTO   ld_week_date_eff
                FROM   DUAL;
            END IF;
            IF (lc_payment_term = 'TUESDAY') THEN
                lc_payment_term_valid := 'Y';
                --Getting the date of the next coming Monday
                SELECT  DECODE(lc_day_of_week
                        ,'SUN',p_invoice_creation_date+2
                        ,'MON',p_invoice_creation_date+1
                        ,'TUE',p_invoice_creation_date
                        ,'WED',p_invoice_creation_date+6
                        ,'THU',p_invoice_creation_date+5
                        ,'FRI',p_invoice_creation_date+4
                        ,'SAT',p_invoice_creation_date+3)-7
                INTO   ld_week_date_eff
                FROM   DUAL;
            END IF;
            IF (lc_payment_term = 'WEDNESDAY') THEN
                lc_payment_term_valid := 'Y';
                --Getting the date of the next coming Monday
                SELECT  DECODE(lc_day_of_week
                        ,'SUN',p_invoice_creation_date+3
                        ,'MON',p_invoice_creation_date+2
                        ,'TUE',p_invoice_creation_date+1
                        ,'WED',p_invoice_creation_date
                        ,'THU',p_invoice_creation_date+6
                        ,'FRI',p_invoice_creation_date+5
                        ,'SAT',p_invoice_creation_date+4)-7
                INTO   ld_week_date_eff
                FROM   DUAL;
            END IF;
            IF (lc_payment_term = 'THURSDAY') THEN
                lc_payment_term_valid := 'Y';
                --Getting the date of the next coming Monday
                SELECT  DECODE(lc_day_of_week
                        ,'SUN',p_invoice_creation_date+4
                        ,'MON',p_invoice_creation_date+3
                        ,'TUE',p_invoice_creation_date+2
                        ,'WED',p_invoice_creation_date+1
                        ,'THU',p_invoice_creation_date
                        ,'FRI',p_invoice_creation_date+6
                        ,'SAT',p_invoice_creation_date+5)-7
                INTO   ld_week_date_eff
                FROM   DUAL;
            END IF;
            IF (lc_payment_term = 'FRIDAY') THEN
                lc_payment_term_valid := 'Y';
                --Getting the date of the next coming Monday
                SELECT  DECODE(lc_day_of_week
                        ,'SUN',p_invoice_creation_date+5
                        ,'MON',p_invoice_creation_date+4
                        ,'TUE',p_invoice_creation_date+3
                        ,'WED',p_invoice_creation_date+2
                        ,'THU',p_invoice_creation_date+1
                        ,'FRI',p_invoice_creation_date
                        ,'SAT',p_invoice_creation_date+6)-7
                INTO   ld_week_date_eff
                FROM   DUAL;
            END IF;
            IF (lc_payment_term = 'SATURDAY') THEN
                lc_payment_term_valid := 'Y';
                --Getting the date of the next coming Monday
                SELECT  DECODE(lc_day_of_week
                        ,'SUN',p_invoice_creation_date+6
                        ,'MON',p_invoice_creation_date+5
                        ,'TUE',p_invoice_creation_date+4
                        ,'WED',p_invoice_creation_date+3
                        ,'THU',p_invoice_creation_date+2
                        ,'FRI',p_invoice_creation_date+1
                        ,'SAT',p_invoice_creation_date)-7
                INTO   ld_week_date_eff
                FROM   DUAL;
            END IF;
            IF (lc_payment_term_valid = 'N') THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Payment Term: '||lc_payment_term||' is not valid; '||'Frequency: '||lc_frequency||'; Billing Payment Term: '||p_payment_term);
            END IF;
            RETURN (ld_week_date_eff);
        END IF;
        IF (lc_frequency = 'SEMI') THEN
            lc_frequency_valid := 'Y';
            /*IF (lc_payment_term = '1-16') THEN
                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('01'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                ld_end_period_date   := to_date('16'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                IF (p_invoice_creation_date <= ld_start_period_date) THEN
                    ld_week_date_eff := ld_start_period_date;
                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN
                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);
                ELSE
                    ld_week_date_eff := ld_end_period_date;
                END IF;
            END IF;
            IF (lc_payment_term = '2-17') THEN
                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('02'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                ld_end_period_date   := to_date('17'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                IF (p_invoice_creation_date <= ld_start_period_date) THEN
                    ld_week_date_eff := ld_start_period_date;
                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN
                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);
                ELSE
                    ld_week_date_eff := ld_end_period_date;
                END IF;
            END IF;
            IF (lc_payment_term = '3-18') THEN
                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('03'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                ld_end_period_date   := to_date('18'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                IF (p_invoice_creation_date <= ld_start_period_date) THEN
                    ld_week_date_eff := ld_start_period_date;
                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN
                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);
                ELSE
                    ld_week_date_eff := ld_end_period_date;
                END IF;
            END IF;
            IF (lc_payment_term = '4-19') THEN
                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('04'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                ld_end_period_date   := to_date('19'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                IF (p_invoice_creation_date <= ld_start_period_date) THEN
                    ld_week_date_eff := ld_start_period_date;
                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN
                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);
                ELSE
                    ld_week_date_eff := ld_end_period_date;
                END IF;
            END IF;
            IF (lc_payment_term = '5-20') THEN
                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('05'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                ld_end_period_date   := to_date('20'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                IF (p_invoice_creation_date <= ld_start_period_date) THEN
                    ld_week_date_eff := ld_start_period_date;
                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN
                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);
                ELSE
                    ld_week_date_eff := ld_end_period_date;
                END IF;
            END IF;
            IF (lc_payment_term = '6-21') THEN
                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('06'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                ld_end_period_date   := to_date('21'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                IF (p_invoice_creation_date <= ld_start_period_date) THEN
                    ld_week_date_eff := ld_start_period_date;
                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN
                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);
                ELSE
                    ld_week_date_eff := ld_end_period_date;
                END IF;
            END IF;
            IF (lc_payment_term = '7-22') THEN
                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('07'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                ld_end_period_date   := to_date('22'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                IF (p_invoice_creation_date <= ld_start_period_date) THEN
                    ld_week_date_eff := ld_start_period_date;
                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN
                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);
                ELSE
                    ld_week_date_eff := ld_end_period_date;
                END IF;
            END IF;
            IF (lc_payment_term = '8-23') THEN
                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('08'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                ld_end_period_date   := to_date('23'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                IF (p_invoice_creation_date <= ld_start_period_date) THEN
                    ld_week_date_eff := ld_start_period_date;
                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN
                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);
                ELSE
                    ld_week_date_eff := ld_end_period_date;
                END IF;
            END IF;
            IF (lc_payment_term = '9-24') THEN
                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('09'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                ld_end_period_date   := to_date('24'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                IF (p_invoice_creation_date <= ld_start_period_date) THEN
                    ld_week_date_eff := ld_start_period_date;
                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN
                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);
                ELSE
                    ld_week_date_eff := ld_end_period_date;
                END IF;
            END IF;
            IF (lc_payment_term = '10-25') THEN
                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('10'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                ld_end_period_date   := to_date('25'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                IF (p_invoice_creation_date <= ld_start_period_date) THEN
                    ld_week_date_eff := ld_start_period_date;
                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN
                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);
                ELSE
                    ld_week_date_eff := ld_end_period_date;
                END IF;
            END IF;
            IF (lc_payment_term = '11-26') THEN
                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('11'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                ld_end_period_date   := to_date('26'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                IF (p_invoice_creation_date <= ld_start_period_date) THEN
                    ld_week_date_eff := ld_start_period_date;
                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN
                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);
                ELSE
                    ld_week_date_eff := ld_end_period_date;
                END IF;
            END IF;
            IF (lc_payment_term = '12-27') THEN
                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('12'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                ld_end_period_date   := to_date('27'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                IF (p_invoice_creation_date <= ld_start_period_date) THEN
                    ld_week_date_eff := ld_start_period_date;
                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN
                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);
                ELSE
                    ld_week_date_eff := ld_end_period_date;
                END IF;
            END IF;
            IF (lc_payment_term = '13-28') THEN
                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('13'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                ld_end_period_date   := to_date('28'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                IF (p_invoice_creation_date <= ld_start_period_date) THEN
                    ld_week_date_eff := ld_start_period_date;
                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN
                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);
                ELSE
                    ld_week_date_eff := ld_end_period_date;
                END IF;
            END IF;
            IF (lc_payment_term = '14-29') THEN
                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('14'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                --if February month and leap year, last date of the month as 29th Feb
                IF (lc_month = '02' AND (MOD(lc_year,4) = 0 )) THEN
                    ld_end_period_date := LAST_DAY(p_invoice_creation_date);
                --if February month and leap year, last date of the month as 29th Feb
                ELSIF (lc_month = '02' AND MOD(lc_year,4) <> 0 ) THEN
                    ld_end_period_date := LAST_DAY(p_invoice_creation_date)+1;
                ELSE
                    ld_end_period_date   := to_date('29'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                END IF;
                IF (p_invoice_creation_date <= ld_start_period_date) THEN
                    ld_week_date_eff := ld_start_period_date;
                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN
                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);
                ELSE
                    ld_week_date_eff := ld_end_period_date;
                END IF;
            END IF;
            IF (lc_payment_term LIKE '15-3%') THEN
                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('15'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                 --if February month and leap year, last date of the month as 29th Feb
                IF (lc_month = '02' AND (MOD(lc_year,4) = 0 )) THEN
                    ld_end_period_date := LAST_DAY(p_invoice_creation_date)+1;
                --if February month and leap year, last date of the month as 29th Feb
                ELSIF (lc_month = '02' AND MOD(lc_year,4) <> 0 ) THEN
                    ld_end_period_date := LAST_DAY(p_invoice_creation_date)+2;
                ELSE
                    ld_end_period_date   := to_date('30'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                END IF;
                IF (p_invoice_creation_date <= ld_start_period_date) THEN
                    ld_week_date_eff := ld_start_period_date;
                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN
                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);
                ELSE
                    ld_week_date_eff := ld_end_period_date;
                END IF;
            END IF;*/
            --Commented for the Defect# 8350
            /*IF (lc_payment_term LIKE '15-E%') THEN
                lc_payment_term_valid := 'Y';
                ld_start_period_date := to_date('15'||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                ld_end_period_date := LAST_DAY(p_invoice_creation_date);
                IF (p_invoice_creation_date < ld_start_period_date) THEN
                    ld_week_date_eff := ld_start_period_date;
                ELSIF (p_invoice_creation_date > ld_end_period_date) THEN
                    ld_week_date_eff := ADD_MONTHS(ld_start_period_date,1);
                ELSE
                    ld_week_date_eff := ld_end_period_date;
                END IF;
            END IF;*/
            /*Start of Addition for the Defect# 8350, for the new Payment Term 16-EOM*/
            IF (lc_payment_term LIKE '%-EOM') THEN
                lc_payment_term_valid := 'Y';
                lc_error_loc := 'Getting the Start for SEMI term type (EOM)';
                ln_semi_start_date := SUBSTR(lc_payment_term,1,INSTR(lc_payment_term,'-',1,1)-1 );
                ld_start_period_date := TO_DATE(ln_semi_start_date||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                ld_end_period_date := LAST_DAY(p_invoice_creation_date);
                IF (p_invoice_creation_date <= ld_start_period_date) THEN
                    ld_week_date_eff := ADD_MONTHS(ld_end_period_date,-1);
                ELSE
                    ld_week_date_eff := ld_start_period_date;
                END IF;
            ELSIF (lc_payment_term LIKE '%-%') THEN
                lc_payment_term_valid := 'Y';
                ln_semi_start_date := SUBSTR(lc_payment_term,1,INSTR(lc_payment_term,'-',1,1)-1 );
                ln_semi_end_date := SUBSTR(lc_payment_term,INSTR(lc_payment_term,'-',1,1)+1 );
                ld_last_date_month   := LAST_DAY(p_invoice_creation_date);                -- Added for Defect 1375
                lc_last_day_of_month := TO_CHAR(ld_last_date_month,'DD');                  -- Added for Defect 1375
                ld_start_period_date := to_date(ln_semi_start_date||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                --Commented for the Defect# 9278
                --ld_end_period_date   := to_date(ln_semi_end_date||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                --if February month and leap year, last date of the month as 29th Feb
                IF (ln_semi_end_date = 29) THEN
                  /*IF (lc_month = '02' AND (MOD(lc_year,4) = 0 )) THEN
                        ld_end_period_date := LAST_DAY(p_invoice_creation_date);
                    --if February month and leap year, last date of the month as 29th Feb
                    ELSIF (lc_month = '02' AND MOD(lc_year,4) <> 0 ) THEN
                        ld_end_period_date := LAST_DAY(p_invoice_creation_date)+1;
                    ELSE
                        ld_end_period_date   := to_date(ln_semi_end_date||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                    END IF;*/             --commented for defect 1375
                     -- Start of Changes for Defect 1375
                    IF ln_semi_end_date > lc_last_day_of_month THEN
                       ld_end_period_date   := TO_DATE(lc_last_day_of_month||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                    ELSE
                       ld_end_period_date   := TO_DATE(ln_semi_end_date||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                    END IF;
                    -- End of Changes for Defect 1375
                ELSIF (ln_semi_end_date = 30) THEN
                  /*IF (lc_month = '02' AND (MOD(lc_year,4) = 0 )) THEN
                        ld_end_period_date := LAST_DAY(p_invoice_creation_date)+1;
                    --if February month and leap year, last date of the month as 29th Feb
                    ELSIF (lc_month = '02' AND MOD(lc_year,4) <> 0 ) THEN
                        ld_end_period_date := LAST_DAY(p_invoice_creation_date)+2;
                    ELSE
                        ld_end_period_date   := to_date(ln_semi_end_date||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                    END IF;*/                  --commented for defect 1375
                    -- Start of Changes for Defect 1375
                    IF ln_semi_end_date > lc_last_day_of_month THEN
                       ld_end_period_date   := TO_DATE(lc_last_day_of_month||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                    ELSE
                       ld_end_period_date   := TO_DATE(ln_semi_end_date||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                    END IF;
                    -- End of Changes for Defect 1375
                ELSE
                        ld_end_period_date   := to_date(ln_semi_end_date||'-'||lc_month||'-'||lc_year,'DD-MM-YYYY');
                END IF;
                IF (p_invoice_creation_date <= ld_start_period_date) THEN
                    ld_week_date_eff := ADD_MONTHS(ld_end_period_date,-1);
                ELSE
                    ld_week_date_eff := ld_start_period_date;
                END IF;
                IF (ln_semi_start_date >= ln_semi_end_date) THEN
                    lc_payment_term_valid := 'N';
                    ld_week_date_eff := NULL;
                END IF;
            END IF;
            /*End of Addition for the Defect# 8350, for the new Payment Term 16-EOM*/
            IF (lc_payment_term_valid = 'N') THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Payment Term: '||lc_payment_term||' is not valid; '||'Frequency: '||lc_frequency||'; Billing Payment Term: '||p_payment_term);
            END IF;
            RETURN(ld_week_date_eff);
        END IF;
        --If the Frequency is invalid
        IF (lc_frequency_valid = 'N') THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Frequency: '||lc_frequency||' is not valid; '||'Payment Term: '||lc_payment_term||'; Billing Payment Term: '||p_payment_term);
-- Commented for defect # 2308
/*            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'CONCURRENT PROGRAM'
                ,p_program_name            => gc_concurrent_program_name
                ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                ,p_module_name             => 'AR'
                ,p_error_location          => ''
                ,p_error_message_count     => 1
                ,p_error_message_code      => 'E'
                ,p_error_message           => 'Frequency: '||lc_frequency||' is not valid'
                ,p_error_message_severity  => 'Major'
                ,p_notify_flag             => 'N'
                ,p_object_type             => 'AR Frequency ');
*/
            RETURN (NULL);
        END IF;
        --If the Payment term is invalid
        IF (lc_payment_term_valid = 'N') THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Payment Term: '||lc_payment_term||' is not valid; '||'Frequency: '||lc_frequency||'; Billing Payment Term: '||p_payment_term);
-- Commented for defect # 2308
/*            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'CONCURRENT PROGRAM'
                ,p_program_name            => gc_concurrent_program_name
                ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                ,p_module_name             => 'AR'
                ,p_error_location          => ''
                ,p_error_message_count     => 1
                ,p_error_message_code      => 'E'
                ,p_error_message           => 'Payment Term: '||lc_payment_term||' is not valid'
                ,p_error_message_severity  => 'Major'
                ,p_notify_flag             => 'N'
                ,p_object_type             => 'AR Frequency ');
*/
            RETURN (NULL);
        END IF;
        --FND_FILE.PUT_LINE(FND_FILE.LOG, lc_payment_term);
        --FND_FILE.PUT_LINE(FND_FILE.LOG, 'lc_month_eff :'||lc_month);
        --FND_FILE.PUT_LINE(FND_FILE.LOG, lc_daynumber_eff||'-'||lc_month_eff||'-'||lc_year_eff);
        SELECT TO_DATE(lc_daynumber_eff||'-'||lc_month_eff||'-'||lc_year_eff,'DD-MM-YYYY')
        INTO ld_date_eff
        FROM DUAL;
        RETURN (ld_date_eff);
    EXCEPTION WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Location: '||lc_error_loc);
        --FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Debug: '||lc_error_debug);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Debug: '||SQLERRM);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Frequency: '||lc_frequency||'Payment Term: '||lc_payment_term||'Billing Payment Term: '||p_payment_term);
-- Commented for defect # 2308
/*        XX_COM_ERROR_LOG_PUB.LOG_ERROR (
             p_program_type            => 'CONCURRENT PROGRAM'
            ,p_program_name            => gc_concurrent_program_name
            ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
            ,p_module_name             => 'AR'
            ,p_error_location          => ''
            ,p_error_message_count     => 1
            ,p_error_message_code      => 'E'
            ,p_error_message           => SQLERRM
            ,p_error_message_severity  => 'Major'
            ,p_notify_flag             => 'N'
            ,p_object_type             => 'AR Frequency ');
*/
        RETURN (NULL);
    END BILL_FROM_DATE_old;
FUNCTION GET_BILLING_ASSOCIATE_NAME (p_associate_code IN NUMBER)
RETURN VARCHAR2
AS
lc_name varchar2(2000);
BEGIN
        SELECT  meaning
        INTO    lc_name
        FROM    fnd_lookup_values_vl
        WHERE   lookup_type = 'XXOD_EBL_ASSOCIATE'
        AND     lookup_code= p_associate_code
        AND     enabled_flag='Y'
        AND     TRUNC(SYSDATE) BETWEEN TRUNC(start_date_active) AND TRUNC(NVL(end_date_active,SYSDATE+1));
       RETURN lc_name;
 EXCEPTION WHEN OTHERS THEN
lc_name:=NULL;
RETURN lc_name;
END;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : update_Data_extract_status                                          |
-- | Description : This procedure is used by exls render to update error status.       |
-- | Parameters  : p_file_id                                                           |
-- |              ,p_doc_type                                                          |
-- |              ,p_status                                                            |
-- |              ,p_request_id                                                        |
-- |              ,p_debug_flag                                                        |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 10-Jun-2010  Parameswaran SN         Initial draft version for CR 586 -  |
-- |                                               Defect 2811                         |
-- +===================================================================================+
    PROCEDURE update_Data_extract_status ( p_file_id             NUMBER
                                          ,p_doc_type            VARCHAR2
                                          ,p_status              VARCHAR2 :='ERROR'
                                          ,p_request_id          NUMBER   :=fnd_global.conc_request_id
                                          ,p_debug_flag          VARCHAR2 :='N'
                                         )
    AS
       lb_debug                  BOOLEAN;
    BEGIN
       IF p_debug_flag = 'Y' THEN
          lb_debug := TRUE;
       ELSE
       lb_debug := FALSE;
       END IF;
       IF( p_doc_type = 'IND') THEN
          UPDATE xx_ar_ebl_ind_hdr_main
          SET    status                   = p_status,
                 request_id               = p_request_id
          WHERE  file_id                  = p_file_id;
       ELSIF( p_doc_type = 'CONS') THEN
          UPDATE xx_ar_ebl_cons_hdr_main
          SET    status                   = p_status,
                 request_id               = p_request_id
          WHERE  file_id                  = p_file_id;
       END IF;
       gc_put_log := 'Updated the status for document type: ' || p_doc_type || 'as' || p_status || 'for the request ID' || p_request_id
                                                              || 'and for the file ID:' || p_file_id;
       PUT_LOG_LINE( lb_debug
                    ,FALSE
                    ,gc_put_log
                   );
    END update_Data_extract_status ;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : XX_AR_IND_SUM_AMOUNT                                                |
-- | Description : This function is used to get the total amount for all the individual|
-- |               method based on the transaction ID that is passed.                  |
-- | Parameters  : p_trx_id                                                            |
-- |              ,p_paydoc_flag                                                       |
-- | Returns     : ln_total_amount                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 10-Jun-2010  Parameswaran SN         Initial draft version for CR 586 -  |
-- |                                               Defect 2811                         |
-- +===================================================================================+
   FUNCTION  XX_AR_IND_SUM_AMOUNT (p_trx_id      IN NUMBER
                                  ,p_paydoc_flag IN VARCHAR2
                                   )
   RETURN NUMBER
   AS
      ln_total_amount NUMBER :=0;
      lc_trx_type     ra_cust_trx_types_all.TYPE%TYPE;
      ln_gc_amt      NUMBER :=0;
   BEGIN
      IF (p_paydoc_flag = 'Y') THEN
         SELECT NVL(SUM(RACTL.extended_amount),0)
         INTO   ln_total_amount
         FROM   ra_customer_trx_lines_all RACTL
         WHERE  RACTL.customer_trx_id = p_trx_id;

         SELECT  RCTT.type
         INTO    lc_trx_type
         FROM    ra_customer_trx_all RCT
                ,ra_cust_trx_types_all  RCTT
         WHERE   RCT.cust_trx_type_id            = RCTT.cust_trx_type_id
         AND     RCT.customer_trx_id             = p_trx_id;

         IF (lc_trx_type = 'INV') THEN
            SELECT  NVL(SUM(OP.payment_amount),0)
            INTO    ln_gc_amt
            FROM    oe_payments OP
                   ,ra_customer_trx_all RCT
            WHERE   OP.header_id        = RCT.attribute14
            AND     RCT.customer_trx_id = p_trx_id;
            ln_total_amount := ln_total_amount - ln_gc_amt;
         ELSIF (lc_trx_type = 'CM') THEN
            SELECT  NVL(SUM(ORT.credit_amount),0)
            INTO    ln_gc_amt
            FROM    xx_om_return_tenders_all ORT
                   ,ra_customer_trx_all RCT
            WHERE   ORT.header_id       = RCT.attribute14
            AND     RCT.customer_trx_id = p_trx_id;
            ln_total_amount := ln_total_amount + ln_gc_amt;
         END IF;

         RETURN ln_total_amount;
      ELSE
         RETURN 0;
      END IF;
   END XX_AR_IND_SUM_AMOUNT;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : XX_AR_CONS_SUM_AMOUNT                                               |
-- | Description : This function is used to get the total amount for all the individual|
-- |               method based on the transaction ID that is passed.                  |
-- | Parameters  : p_cbi_id                                                            |
-- | Returns     : ln_total_amount                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 10-Jun-2010  Parameswaran SN         Initial draft version for CR 586 -  |
-- |                                               Defect 2811                         |
-- +===================================================================================+
   FUNCTION  XX_AR_CONS_SUM_AMOUNT (p_cbi_id IN  NUMBER
                                    )
   RETURN NUMBER
   AS
      ln_total_amount NUMBER :=0;
      ln_gc_inv_amt   NUMBER :=0;
      ln_gc_cm_amt    NUMBER :=0;
   BEGIN
         SELECT NVL(SUM(RACTL.extended_amount),0)
         INTO   ln_total_amount
         FROM   ar_cons_inv_trx_all   ACIT
               ,ra_customer_trx_lines_all RACTL
         WHERE  1                    = 1
         AND    ACIT.cons_inv_id     = p_cbi_id
         AND    ACIT.customer_trx_id = RACTL.customer_trx_id;

         SELECT  NVL(SUM(OP.payment_amount),0)
         INTO    ln_gc_inv_amt
         FROM    oe_payments OP
                ,ra_customer_trx_all RCT
                ,ar_cons_inv_trx_all ACIT
         WHERE   OP.header_id          = RCT.attribute14
         AND     RCT.customer_trx_id   = ACIT.customer_trx_id
         AND     ACIT.cons_inv_id      = p_cbi_id
         AND     ACIT.transaction_type = 'INVOICE';

         SELECT  NVL(SUM(ORT.credit_amount),0)
         INTO    ln_gc_cm_amt
         FROM    xx_om_return_tenders_all ORT
                ,ra_customer_trx_all RCT
                ,ar_cons_inv_trx_all ACIT
         WHERE   ORT.header_id         = RCT.attribute14
         AND     RCT.customer_trx_id   = ACIT.customer_trx_id
         AND     ACIT.cons_inv_id      = p_cbi_id
         AND     ACIT.transaction_type = 'CREDIT_MEMO';

         ln_total_amount := ln_total_amount - ln_gc_inv_amt + ln_gc_cm_amt;

         RETURN ln_total_amount;
   END XX_AR_CONS_SUM_AMOUNT;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : XX_OD_EBL_DEL_MTD                                                   |
-- | Description : This function returns a value 1 if the given delivery method exists |
-- | Parameters  : p_del_mtd, lc_del_mtd                                               |
-- | Returns     : ln_c                                                                |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 10-Jun-2010  Parameswaran SN         Initial draft version for CR 586 -  |
-- |                                               Defect 2811                         |
-- +===================================================================================+
    FUNCTION XX_OD_EBL_DEL_MTD(p_del_mtd IN VARCHAR2
                             ,lc_del_mtd IN VARCHAR2)
    RETURN NUMBER
    IS
      ln_c NUMBER;
    BEGIN
       SELECT INSTR(',' || p_del_mtd || ',',',' || lc_del_mtd || ',')
       INTO ln_c
       FROM dual;

       RETURN ln_c;
    END XX_OD_EBL_DEL_MTD;
    PROCEDURE get_parent_details(p_customer_id IN NUMBER
                           ,p_account_number OUT VARCHAR2
                           ,p_aops_acct_number OUT VARCHAR2
                           ,p_customer_name OUT VARCHAR2
                           )
    IS
    lc_account_number hz_cust_Accounts_all.account_number%TYPE;
    lc_aops_acct_number hz_cust_Accounts_all.orig_system_reference%TYPE;
    lc_customer_name  hz_parties.party_name%TYPE;
    BEGIN
       SELECT hca.account_number,
              SUBSTR(hca.orig_system_reference,1,8),
              hzp.party_name
       INTO lc_account_number
           ,lc_aops_Acct_number
           , lc_customer_name
       FROM hz_cust_Accounts_All hca
           ,hz_parties hzp
       WHERE hca.party_id = hzp.party_id
       AND   hca.cust_Account_id = p_customer_id;

       p_account_number :=lc_account_number;
       p_aops_acct_number:=lc_aops_acct_number;
       p_customer_name:=lc_customer_name;

    END;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : UPDATE_FILE_TABLE                                                   |
-- | Description : Procedure to reset file and transmission statuses                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 19-Jun-2010  Ranjith Thangasamay     Initial draft version               |
-- +===================================================================================+
PROCEDURE update_file_table(x_errbuf          OUT VARCHAR2
                           ,x_retcode         OUT VARCHAR2
                           ,p_type            VARCHAR2
                           ,p_cust_doc_id     VARCHAR2
                           ,p_batch_id        VARCHAR2
                           ,p_file_id         VARCHAR2
                           ,p_transmission_id          VARCHAR2
                           ,p_status          VARCHAR2
                           ) AS
   lc_table       VARCHAR2(1000);
   lc_cust_doc_id VARCHAR2(1000);
   lc_batch_id    VARCHAR2(1000);
   lc_file_id     VARCHAR2(1000);
   lc_sql         VARCHAR2(4000);
BEGIN
   fnd_file.put_line(fnd_file.log,'Parameters:');
   fnd_file.put_line(fnd_file.log,'Bill Type: '||p_type);
   fnd_file.put_line(fnd_file.log,'Cust Doc Id: '||p_cust_doc_id);
   fnd_file.put_line(fnd_file.log,'Batch Id: '||p_batch_id);
   fnd_file.put_line(fnd_file.log,'File Id: '||p_file_id);
   fnd_file.put_line(fnd_file.log,'Transmission Id: '||p_transmission_id);
   fnd_file.put_line(fnd_file.log,'Status: '||p_status);


   IF p_type = 'CONS' THEN
      lc_table := ' xx_ar_ebl_cons_hdr_main';
   ELSE
      lc_table := ' xx_ar_ebl_ind_hdr_main';
   END IF;

   IF nvl((p_cust_doc_id || p_batch_id || p_file_id|| p_transmission_id)
         ,'XX') = 'XX' THEN
      fnd_file.put_line(fnd_file.log
                       ,'********** Terminating Program : All the parameters cannot be null **********');
      x_retcode := 2;
      RETURN;
   END IF;

   IF (p_transmission_id IS NULL) THEN
      IF p_cust_doc_id IS NOT NULL THEN
         lc_cust_doc_id := 'INSTR (:2,'',''||parent_cust_doc_id||'','')>0';
      ELSE
         lc_cust_doc_id := '(1=1 OR ''xx''=:2)';
      END IF;
      IF p_batch_id IS NOT NULL THEN
         lc_batch_id := 'INSTR (:3,'',''||extract_batch_id||'','')>0';
      ELSE
         lc_batch_id := '(1=1 OR ''xx''=:3)';
      END IF;

      IF p_file_id IS NOT NULL THEN
         lc_file_id := 'INSTR (:4,'',''||file_id||'','')>0';
      ELSE
         lc_file_id := '(1=1 OR ''xx''=:4)';
      END IF;

      lc_sql := 'UPDATE XX_AR_EBL_FILE
   SET STATUS = DECODE(:1,NULL ,DECODE(FILE_TYPE,''XLS'',''MANIP_READY''
                              ,''PDF'',''RENDER'',''TXT'',''MANIP_READY''
                    ),:1)
        ,STATUS_DETAIL = NULL
WHERE FILE_ID IN (SELECT FILE_ID FROM ' || lc_table || '
WHERE ' || lc_cust_doc_id || '
AND ' || lc_batch_id || '
AND ' || lc_file_id || ' )';

      IF (p_file_id IS NOT NULL) THEN
         UPDATE xx_ar_ebl_file
         SET    status        = decode(p_status
                                      ,NULL
                                      ,decode(file_type
                                             ,'XLS'
                                             ,'MANIP_READY'
											 ,'TXT'
                                             ,'MANIP_READY'
                                             ,'PDF'
                                             ,'RENDER')
                                      ,p_status)
               ,status_detail = NULL
         WHERE  instr(',' || p_file_id || ','
                     ,',' || file_id || ',') > 0;
         fnd_file.put_line(fnd_file.log
                          ,'File ID not nulL - Records Executed : ' || SQL%ROWCOUNT);
      END IF;


      IF (p_file_id IS NULL) THEN
      fnd_file.put_line(fnd_file.log
                       ,'Executing SQL : ' || lc_sql);
         EXECUTE IMMEDIATE lc_sql
            USING p_status, p_status, ',' || p_cust_doc_id || ',', ',' || p_batch_id || ',', ',' || p_file_id || ',';
         fnd_file.put_line(fnd_file.log
                          ,'Records Executed : ' || SQL%ROWCOUNT);
      END IF;
   ELSE
      UPDATE xx_ar_ebl_transmission
      SET    status        = p_status
            ,status_detail = NULL
      WHERE  instr(',' || p_transmission_id || ','
                  ,',' || transmission_id || ',') > 0;
        fnd_file.put_line(fnd_file.log
                          ,'Updating Transmission ID - Records Executed : ' || SQL%ROWCOUNT);
   END IF;
END;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : UPDATE_HDR_TABLE                                                    |
-- | Description : Procedure to reset status in HDR tables                             |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 19-Jun-2010  Ranjith Thangasamay     Initial draft version               |
-- +===================================================================================+
PROCEDURE UPDATE_HDR_TABLE ( x_errbuf OUT VARCHAR2
                                ,x_retcode OUT VARCHAR2
                                ,p_type VARCHAR2
                                ,p_batch_id VARCHAR2
                                ) AS

   gc_debug_msg VARCHAR2(2000);
   BEGIN

  /*   IF p_type = 'CONS' THEN
      gc_debug_msg := 'Calling populate_trans_details';
      xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                            ,TRUE
                                            ,gc_debug_msg);
      xx_ar_ebl_cons_invoices.populate_trans_details(p_batch_id);
      gc_debug_msg := 'Calling populate_file_name';
      xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                            ,TRUE
                                            ,gc_debug_msg);
      xx_ar_ebl_cons_invoices.populate_file_name(p_batch_id);
      gc_debug_msg := 'Calling insert_transmission_details';
      xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                            ,TRUE
                                            ,gc_debug_msg);
      xx_ar_ebl_cons_invoices.insert_transmission_details(p_batch_id);
    ELSE
      gc_debug_msg := 'Calling populate_trans_details';
      xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                            ,TRUE
                                            ,gc_debug_msg);
      xx_ar_ebl_ind_invoices_pkg.populate_trans_details(p_batch_id);
      gc_debug_msg := 'Calling populate_file_name';
      xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                            ,TRUE
                                            ,gc_debug_msg);
      xx_ar_ebl_ind_invoices_pkg.populate_file_name(p_batch_id);
      gc_debug_msg := 'Calling insert_transmission_details';
      xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                            ,TRUE
                                            ,gc_debug_msg);
      xx_ar_ebl_ind_invoices_pkg.insert_transmission_details(p_batch_id);
    END IF;*/
          xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                            ,TRUE
                                            ,'This program does not do anything. Intended as a future enhancement');
   END;
    FUNCTION get_discount_date (p_trx_id IN NUMBER)


     RETURN DATE IS
     ld_discount_Date DATE;
     BEGIN
       SELECT  TRUNC(DECODE(TLD.DISCOUNT_DAYS ,NULL ,NVL(TLD.DISCOUNT_DATE, DECODE ( LEAST(TO_NUMBER(TO_CHAR(PS.TRX_DATE,'DD')), NVL(T.DUE_CUTOFF_DAY,32)) ,T.DUE_CUTOFF_DAY,LAST_DAY( ADD_MONTHS(PS.TRX_DATE, TLD.DISCOUNT_MONTHS_FORWARD) ) + LEAST(TLD.DISCOUNT_DAY_OF_MONTH, TO_NUMBER(TO_CHAR(LAST_DAY(ADD_MONTHS(PS.TRX_DATE, TLD.DISCOUNT_MONTHS_FORWARD+1)),'DD'))) , LAST_DAY(ADD_MONTHS(PS.TRX_DATE,TLD.DISCOUNT_MONTHS_FORWARD-1)) + LEAST(TLD.DISCOUNT_DAY_OF_MONTH ,TO_NUMBER(TO_CHAR(LAST_DAY( ADD_MONTHS(PS.TRX_DATE,TLD.DISCOUNT_MONTHS_FORWARD)),'DD'))) ) ) , PS.TRX_DATE + TLD.DISCOUNT_DAYS)) DISCOUNT_DATE
       INTO ld_discount_date
       FROM RA_TERMS_LINES_DISCOUNTS TLD ,
       RA_TERMS T ,
       AR_PAYMENT_SCHEDULES PS
       WHERE T.TERM_ID              = TLD.TERM_ID
       AND PS.TERM_ID               = T.TERM_ID
       AND PS.TERMS_SEQUENCE_NUMBER = TLD.SEQUENCE_NUM
       AND ps.customer_Trx_id = p_trx_id
       AND ROWNUM <2;

       RETURN ld_discount_date;
   EXCEPTION
      WHEN OTHERS THEN

              PUT_LOG_LINE( TRUE
                    ,TRUE
                    ,'Exception when calculating discount Date :' || SQLERRM
                   );
              RETURN NULL;
      END;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : GET_HEADER_DISCOUNT                                                 |
-- | Description : To get the Discount Information                                     |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |DRAFT 1.0 30-NOV-2015  Havish Kasina        Initial draft version                  |
-- +===================================================================================+
FUNCTION GET_HEADER_DISCOUNT
    (
      p_customer_trx_id     NUMBER )
    RETURN VARCHAR2
AS

   CURSOR c_discount_info IS
   SELECT discount_percent,
          discount_date
    FROM  AR_TRX_DISCOUNTS_V
   WHERE  customer_trx_id = p_customer_trx_id;

   l_config_details_rec    xx_fin_translatevalues%ROWTYPE;
   lc_translation_name     xx_fin_translatedefinition.translation_name%TYPE := 'XX_AR_EBL_DISCOUNT_TEXT';
   lc_discount_info        VARCHAR2(32000);
   lc_discount_info1       VARCHAR2(32000);
   lc_discount             VARCHAR2(32000);
   i                       NUMBER := 0;
   ln_discount_percent     NUMBER;
   ld_discount_date        DATE;

BEGIN
      -- To get the Translation Values
      BEGIN
        SELECT  xftv.*
          INTO  l_config_details_rec
          FROM  xx_fin_translatevalues xftv
               ,xx_fin_translatedefinition xftd
         WHERE xftv.translate_id = xftd.translate_id
           AND xftd.translation_name = lc_translation_name
           AND SYSDATE BETWEEN xftv.start_date_active AND NVL (xftv.end_date_active, SYSDATE + 1)
           AND SYSDATE BETWEEN xftd.start_date_active AND NVL (xftd.end_date_active, SYSDATE + 1)
           AND xftv.enabled_flag = 'Y'
           AND xftd.enabled_flag = 'Y';

      EXCEPTION
        WHEN OTHERS THEN
          l_config_details_rec := NULL;
      END;

      -- To get the Discount Information
    BEGIN
      lc_discount_info  := NULL;
      lc_discount_info1 := NULL;
      lc_discount       := NULL;

      OPEN c_discount_info;
           LOOP
           ln_discount_percent := NULL;
           ld_discount_date   := NULL;
           FETCH c_discount_info INTO ln_discount_percent,ld_discount_date;
           EXIT WHEN c_discount_info%NOTFOUND;
           i := i+ 1;

           IF ln_discount_percent > 0
           THEN
             IF i =1
             THEN
               lc_discount_info :=  l_config_details_rec.source_value1||' '||ln_discount_percent||l_config_details_rec.source_value2||' '||ld_discount_date;
             ELSE
               lc_discount_info1 := lc_discount_info1||' '||l_config_details_rec.source_value3||' '||ln_discount_percent||l_config_details_rec.source_value2||' '||ld_discount_date;
             END IF;
           END IF;
          END LOOP;
     CLOSE c_discount_info;

     IF lc_discount_info IS NOT NULL
     THEN
          lc_discount := lc_discount_info || lc_discount_info1;
     ELSE
        lc_discount := NULL;
     END IF;
   EXCEPTION
      WHEN OTHERS THEN
        lc_discount := NULL;
   END;
   RETURN lc_discount;

EXCEPTION
   WHEN OTHERS THEN
      lc_discount := NULL;
      RETURN lc_discount;
END GET_HEADER_DISCOUNT;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : GET_HEADER_DISCOUNT                                                 |
-- | Description : To get the Discount Information                                     |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |DRAFT 1.0 16-DEC-2015  Suresh N             Initial draft version                  |
-- |2.0		  24-MAY-2016  Rohit Gupta			Select max of trx_id for a cons_inv_id |
-- |											instead of 1st record. Defect #37807   |
-- +===================================================================================+
FUNCTION GET_HEADER_DISCOUNT
    (
      p_cons_inv_id     IN  NUMBER
     ,p_customer_trx_id IN  NUMBER  )
    RETURN VARCHAR2
AS
   lc_discount_info        VARCHAR2(32000);
   ln_customer_trx_id      NUMBER;
BEGIN
     IF p_customer_trx_id IS NULL THEN
     BEGIN
        /*SELECT customer_trx_id						--commented for defect #37807
		INTO ln_customer_trx_id
        FROM  AR_CONS_INV_TRX_ALL
        WHERE  cons_inv_id = p_cons_inv_id
        AND rownum = 1;*/
		SELECT 	max(ACIT.customer_trx_id)					--added for defect 37807
        INTO 	ln_customer_trx_id
        FROM  	AR_CONS_INV_TRX_ALL ACIT,
				RA_CUSTOMER_TRX_ALL RCT
        WHERE	ACIT.cons_inv_id 			= p_cons_inv_id
		AND 	ACIT.transaction_type 		= 'INVOICE'
		AND		ACIT.customer_trx_id		= RCT.customer_trx_id
		AND		RCT.billing_date			= (SELECT 	MAX(RCT1.billing_date)
												FROM     AR_CONS_INV_TRX_ALL	ACIT1
														,RA_CUSTOMER_TRX_ALL	RCT1
												WHERE	ACIT1.cons_inv_id 			= p_cons_inv_id
												AND 	ACIT1.transaction_type 		= 'INVOICE'
												AND		ACIT1.customer_trx_id		= RCT1.customer_trx_id);


      EXCEPTION WHEN OTHERS THEN
        ln_customer_trx_id := NULL;
      END;
        lc_discount_info := XX_AR_EBL_COMMON_UTIL_PKG.GET_HEADER_DISCOUNT(ln_customer_trx_id);
      ELSIF p_customer_trx_id IS NOT NULL THEN
        lc_discount_info := XX_AR_EBL_COMMON_UTIL_PKG.GET_HEADER_DISCOUNT(p_customer_trx_id);
      END IF;
      RETURN lc_discount_info;
EXCEPTION
   WHEN OTHERS THEN
      lc_discount_info := NULL;
      RETURN lc_discount_info;
END GET_HEADER_DISCOUNT;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : GET_KIT_EXTENDED_AMOUNT                                             |
-- | Description : To get the KIT extended amount and KIT Unit Price                   |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |DRAFT 1.0 23-JUN-2016  Havish Kasina        Initial draft version for Kitting      |
-- |                                            (Defect 37670)                         |
-- +===================================================================================+
PROCEDURE get_kit_extended_amount ( p_customer_trx_id      IN  NUMBER ,
		                            p_sales_order_line_id  IN  VARCHAR2 ,
									p_kit_quantity         IN  NUMBER ,
									x_kit_extended_amt     OUT NUMBER ,
									x_kit_unit_price       OUT NUMBER
							      )
IS
BEGIN
	fnd_file.put_line(fnd_file.log,' Get the Kit Extended Amount and Kit Unit Price for Customer Transaction ID : '||p_customer_trx_id);
	SELECT SUM(rctl.extended_amount)
	  INTO x_kit_extended_amt
	  FROM ra_customer_trx_lines_all rctl
	 WHERE rctl.customer_trx_id = p_customer_trx_id
	   AND rctl.line_type <> 'TAX'
	   AND rctl.interface_line_attribute6 IN ( SELECT line_id
			                                     FROM xx_om_line_attributes_all xola
												WHERE xola.link_to_kit_line_id = p_sales_order_line_id);
	x_kit_unit_price := x_kit_extended_amt/p_kit_quantity;

EXCEPTION
    WHEN OTHERS
    THEN
        x_kit_extended_amt:= NULL;
        x_kit_unit_price  := NULL;
	    fnd_file.put_line(fnd_file.log,' Unable to get the Kit Extended Amount and Kit Unit Price for Customer Transaction ID : '||p_customer_trx_id);
END get_kit_extended_amount;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : GET_CONS_MSG_BCC                                                    |
-- | Description : To display custom message for bill complete customer for delivery   |
-- | 			   method ePDF and ePRINT.	   										   |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |1.0       23-Oct-2018  SravanKumar           Initial draft version (NAIT-65564)    |
-- |1.1       14-Nov-2018  P Jadhav              NAIT- 65564: updated GET_CONS_MSG_BCC |
-- |										  	 display  message for bill complete    |
-- |                                             customer and Paydoc method only       |
-- |1.2       06-DEC-2018	P Jadhav 			 NAIT-74893: updated GET_CONS_MSG_BCC  |
-- |											 changed custom message		           |
-- +===================================================================================+
FUNCTION get_cons_msg_bcc
	     ( p_cust_doc_id 		IN NUMBER
		  ,p_cust_account_id 	IN NUMBER
		  ,p_billing_number  	IN VARCHAR2
	     )
  RETURN VARCHAR2
AS
  lc_bill_flag 				VARCHAR2(5)    := 'N';
  lc_cons_msg_bcc   		VARCHAR2(2000) := TO_CHAR(NULL);
  lc_child_order_number 	VARCHAR2(300)  := NULL;
  lc_parent_order_number 	VARCHAR2(300)  := NULL;
  lb_debug               	BOOLEAN;
  ln_bill_cnt 				NUMBER:=0;
  ln_pay_doc_cnt  			NUMBER:=0;
 BEGIN
	BEGIN
          ln_pay_doc_cnt:= 0;

        SELECT COUNT(1)
			INTO ln_pay_doc_cnt
			FROM xx_cdh_cust_acct_ext_b
          WHERE n_ext_attr2=p_cust_doc_id
            AND c_ext_attr2 IN('Y','B') -- condition to pick Paydoc/bill complete customer
		    AND attr_group_id=(SELECT attr_group_id
								FROM   ego_attr_groups_v
								WHERE  attr_group_type = 'XX_CDH_CUST_ACCOUNT'
								AND    attr_group_name = 'BILLDOCS');
	EXCEPTION
		WHEN OTHERS	THEN
			ln_pay_doc_cnt:= 0;
	END;
	IF ln_pay_doc_cnt = 1	THEN

		--Condition to check Bill complete customer flag
		BEGIN
			ln_bill_cnt := 0;

			SELECT COUNT(1)
			INTO ln_bill_cnt
			FROM hz_customer_profiles
				WHERE cust_account_id = p_cust_account_id
				AND cons_inv_flag     = 'Y'
				AND attribute6 IN ('Y','B')
				AND site_use_id IS NULL;
		EXCEPTION
			WHEN OTHERS	THEN
			ln_bill_cnt := 0;
		END;
		IF ln_bill_cnt = 1	THEN

			BEGIN
			lc_child_order_number 	:= NULL;
			lc_parent_order_number 	:= NULL;

			IF LENGTH(p_billing_number) = 9 THEN
					BEGIN
						lc_cons_msg_bcc := NULL;
						SELECT LISTAGG(child_order_number, ', ') within GROUP (ORDER BY child_order_number) AS child_order_number
						  INTO lc_child_order_number
						  FROM xx_scm_bill_signal
						 WHERE parent_order_number = p_billing_number
						   AND shipped_flag='N'
						   AND NOT EXISTS (SELECT 1
											 FROM ra_customer_trx_all
											WHERE trx_number = child_order_number
										  );

							   gc_put_log := 'lc_child_order_number : ' || lc_child_order_number;
							   PUT_LOG_LINE( lb_debug,FALSE,gc_put_log);
					EXCEPTION
						WHEN OTHERS	THEN
							lc_child_order_number:= NULL;
					END;

						IF lc_child_order_number IS NOT NULL THEN
						    lc_cons_msg_bcc := 'Order '||lc_child_order_number ||' are pending shipment and will be billed separately, as an exception.';
						ELSE
						   lc_cons_msg_bcc:='X';
						END IF;

					RETURN(lc_cons_msg_bcc);

			ELSIF LENGTH(p_billing_number) = 12 THEN

				BEGIN
					lc_cons_msg_bcc := NULL;
					SELECT parent_order_number
					  INTO lc_parent_order_number
					  FROM xx_scm_bill_signal
					 WHERE child_order_number = p_billing_number;

					 gc_put_log := 'lc_parent_order_number : ' || lc_parent_order_number;
					 PUT_LOG_LINE(lb_debug,FALSE,gc_put_log );
				EXCEPTION
					WHEN OTHERS THEN
					lc_parent_order_number:= NULL;
				END;

				IF lc_parent_order_number IS NOT NULL THEN
				    lc_cons_msg_bcc := 'Order # '||p_billing_number ||' is part of Parent Order # '||lc_parent_order_number||'.';
				ELSE
				   lc_cons_msg_bcc:='X';
				END IF;

				RETURN(lc_cons_msg_bcc);
			ELSE
				RETURN('X');
			END IF;

			EXCEPTION
				WHEN OTHERS THEN
				RETURN('X');
			END;

		ELSE

			BEGIN
			lc_child_order_number := NULL;
			lc_parent_order_number:= NULL;

			IF LENGTH(p_billing_number) = 9 THEN
					BEGIN
						lc_cons_msg_bcc := NULL;
						SELECT LISTAGG(child_order_number, ', ') within GROUP (ORDER BY child_order_number) AS child_order_number
						  INTO lc_child_order_number
						  FROM xx_scm_bill_signal
						 WHERE parent_order_number = p_billing_number
						   AND shipped_flag='N'
						   AND NOT EXISTS (SELECT 1
											 FROM ra_customer_trx_all
											WHERE trx_number = child_order_number
										  );

							   gc_put_log := 'lc_child_order_number : ' || lc_child_order_number;
							   PUT_LOG_LINE( lb_debug,FALSE,gc_put_log);
					EXCEPTION
						WHEN OTHERS	THEN
							lc_child_order_number:= NULL;
					END;

						IF lc_child_order_number IS NOT NULL THEN
						    lc_cons_msg_bcc := 'Order '||lc_child_order_number ||' are pending shipment and will be billed separately, as an exception.';
						ELSE
						   lc_cons_msg_bcc:='X';
						END IF;

					RETURN(lc_cons_msg_bcc);

			ELSIF LENGTH(p_billing_number) = 12 THEN

				BEGIN
					lc_cons_msg_bcc := NULL;
					SELECT parent_order_number
					  INTO lc_parent_order_number
					  FROM xx_scm_bill_signal
					 WHERE child_order_number = p_billing_number;

					 gc_put_log := 'lc_parent_order_number : ' || lc_parent_order_number;
					 PUT_LOG_LINE(lb_debug,FALSE,gc_put_log );
				EXCEPTION
					WHEN OTHERS THEN
					lc_parent_order_number:= NULL;
				END;

					IF lc_parent_order_number IS NOT NULL THEN
					    lc_cons_msg_bcc:='Order # '||p_billing_number ||' is part of Parent Order # '||lc_parent_order_number||'.';
					ELSE
					   lc_cons_msg_bcc:='X';
					END IF;

				RETURN(lc_cons_msg_bcc);
			ELSE
				RETURN('X');
			END IF;

			EXCEPTION
				WHEN OTHERS THEN
				RETURN('X');
		END;
		END IF;
	ELSE
	RETURN('X');
	END IF; --End of Main IF

 EXCEPTION
	WHEN OTHERS THEN
	RETURN('X');
 END get_cons_msg_bcc;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : GET_POD_MSG_IND_REPRINT                                             |
-- | Description : To get the blurb message for Individual Reprint report              |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- | 1.0      23-JUN-2016  Aarthi               Initial draft version for adding Blurb |
-- |                                            message for POD Ind Reprint report     |
-- +===================================================================================+
FUNCTION GET_POD_MSG_IND_REPRINT ( p_customer_trx_id      IN  NUMBER ,
		                           p_bill_to_customer_id  IN  NUMBER
							     )
RETURN VARCHAR2
AS
    lc_pod_blurb_msg VARCHAR2(1000):= NULL;
    ln_pod_cnt       NUMBER :=0;
	ln_pod_tab_cnt   NUMBER :=0;
	ln_pay_doc       NUMBER :=0;
	ln_pay_doc_cons  NUMBER :=0;
BEGIN

	 ln_pod_cnt      := 0;
	 ln_pod_tab_cnt	 := 0;
	 ln_pay_doc      := 0;

	 BEGIN
       SELECT COUNT(1)
		 INTO ln_pod_cnt
		 FROM hz_customer_profiles HCP
		WHERE HCP.cust_account_id = p_bill_to_customer_id
		  AND HCP.site_use_id        IS NULL
		  AND Hcp.Status              = 'A'
		  AND HCP.attribute6         IN ('Y','P');

     EXCEPTION
	   WHEN OTHERS THEN
	     FND_FILE.PUT_LINE(FND_FILE.LOG,'XX_AR_EBL_COMMON_UTIL_PKG: Error while fetching the attribute6 value : '||Sqlerrm);
		 ln_pod_cnt := 0;
	 END;

     BEGIN
       SELECT COUNT(1)
		 INTO ln_pod_tab_cnt
		 FROM xx_ar_ebl_pod_dtl
		WHERE 1                   =1
		  AND customer_trx_id       = p_customer_trx_id
		  AND ( pod_image           IS NOT NULL
		        OR delivery_date    IS NOT NULL
		        OR consignee        IS NOT NULL);
	 EXCEPTION
	   WHEN OTHERS THEN
	     FND_FILE.PUT_LINE(FND_FILE.LOG,'XX_AR_EBL_COMMON_UTIL_PKG: Error while fetching details from XX_AR_EBL_POD_DTL : '||Sqlerrm);
		 ln_pod_tab_cnt := 0;
	 END;

     BEGIN
	   SELECT COUNT(1)
		 INTO ln_pay_doc
		 FROM xx_ar_ebl_ind_hdr_hist
		WHERE document_type = 'Paydoc'
		  AND billdocs_delivery_method IN ('ePDF','eXLS')
		  AND customer_trx_id = p_customer_trx_id;
	 EXCEPTION
	   WHEN OTHERS THEN
	     FND_FILE.PUT_LINE(FND_FILE.LOG,'XX_AR_EBL_COMMON_UTIL_PKG: Error while fetching details from xx_ar_ebl_ind_hdr_hist table : '||Sqlerrm);
		 ln_pay_doc := 0;
	 END;

     BEGIN
	   SELECT COUNT(1)
		 INTO ln_pay_doc_cons
		 FROM xx_ar_ebl_cons_hdr_hist
		WHERE document_type = 'Paydoc'
		  AND billdocs_delivery_method IN ('ePDF','eTXT','eXLS')
		  AND customer_trx_id = p_customer_trx_id;
	 EXCEPTION
	   WHEN OTHERS THEN
	     FND_FILE.PUT_LINE(FND_FILE.LOG,'XX_AR_EBL_COMMON_UTIL_PKG: Error while fetching details from xx_ar_ebl_cons_hdr_hist table : '||Sqlerrm);
		 ln_pay_doc_cons := 0;
	 END;

    IF ln_pod_cnt >= 1 AND ln_pod_tab_cnt = 0 AND (ln_pay_doc >= 1 OR ln_pay_doc_cons >= 1)  THEN
	    lc_pod_blurb_msg:= 'Delivery Details Not Available.';
    ELSE
        lc_pod_blurb_msg := NULL;
    END IF;


	RETURN(lc_pod_blurb_msg);

EXCEPTION
WHEN OTHERS	THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while returning l_pod_blurb_msg in GET_POD_MSG : '||Sqlerrm);
	lc_pod_blurb_msg := NULL;
	RETURN(lc_pod_blurb_msg);
END GET_POD_MSG_IND_REPRINT;

 -- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : GET_FEE_AMOUNT                                                      |
-- | Description : To get fee amount for particular transaction                        |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- | 1.0      23-MAR-2020  Divyansh Saini       Initial draft version                  |
-- +===================================================================================+
FUNCTION get_line_fee_amount ( p_customer_trx_id      IN  NUMBER)
RETURN NUMBER
AS
    ln_fee_amount       NUMBER :=0;
BEGIN

	 ln_fee_amount      := 0;

	 BEGIN
      SELECT NVL(sum(RCTL.unit_selling_price*
						 CASE WHEN aps.class = 'CM' THEN rctl.quantity_credited
						 else NVL(rctl.quantity_ordered,rctl.quantity_invoiced) end
						 ),0) FEE_AMT
		    INTO ln_fee_amount
			  FROM ra_customer_trx_lines_All RCTL
				     ,fnd_lookup_values flv
             ,ar_payment_schedules_all aps
		   WHERE 1=1
			 AND flv.lookup_type = 'OD_FEES_ITEMS'
			 AND flv.LANGUAGE='US'
			 AND flv.attribute6= rctl.INVENTORY_ITEM_ID
			 AND FLV.enabled_flag = 'Y'
			 AND SYSDATE BETWEEN NVL(FLV.start_date_active,SYSDATE) AND NVL(FLV.end_date_active,SYSDATE+1)
			 AND FLV.attribute7 NOT IN ('DELIVERY','MISCELLANEOUS','HEADER')
			 AND aps.customer_trx_id = rctl.customer_trx_id
			 AND rctl.customer_trx_id = p_customer_trx_id;

     EXCEPTION
	   WHEN OTHERS THEN
	     FND_FILE.PUT_LINE(FND_FILE.LOG,'XX_AR_EBL_COMMON_UTIL_PKG: Error while fetching the Fee Amount : '||Sqlerrm);
		 ln_fee_amount := 0;
	 END;


	RETURN(ln_fee_amount);

EXCEPTION
WHEN OTHERS	THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while returning fee_amount in get_line_fee_amount : '||Sqlerrm);
	RETURN(0);
END get_line_fee_amount;

 -- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : GET_HEA_FEE_AMOUNT                                                      |
-- | Description : To get fee amount for particular transaction                        |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- | 1.0      23-MAR-2020  Divyansh Saini       Initial draft version                  |
-- +===================================================================================+
FUNCTION get_hea_fee_amount ( p_customer_trx_id      IN  NUMBER)
RETURN NUMBER
AS
    ln_fee_amount       NUMBER :=0;
BEGIN

	 ln_fee_amount      := 0;

	 BEGIN
      SELECT NVL(sum(RCTL.unit_selling_price*
						 CASE WHEN aps.class = 'CM' THEN rctl.quantity_credited
						 else NVL(rctl.quantity_ordered,rctl.quantity_invoiced) end
						 ),0) FEE_AMT
		    INTO ln_fee_amount
			  FROM ra_customer_trx_lines_All RCTL
				    ,fnd_lookup_values flv
					,ar_payment_schedules_all aps
		   WHERE 1=1
			 AND flv.lookup_type = 'OD_FEES_ITEMS'
			 AND flv.LANGUAGE='US'
			 AND flv.attribute6= rctl.INVENTORY_ITEM_ID
			 AND FLV.enabled_flag = 'Y'
			 AND SYSDATE BETWEEN NVL(FLV.start_date_active,SYSDATE) AND NVL(FLV.end_date_active,SYSDATE+1)
			 AND FLV.attribute7 IN ('HEADER')
			 AND aps.customer_trx_id = rctl.customer_trx_id
			 AND rctl.customer_trx_id = p_customer_trx_id;

   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       dbms_output.put_line('Data not present');
       return 0;
	   WHEN OTHERS THEN
	     FND_FILE.PUT_LINE(FND_FILE.LOG,'XX_AR_EBL_COMMON_UTIL_PKG: Error while fetching the Fee Amount : '||Sqlerrm);
		   ln_fee_amount := 0;
	 END;


	RETURN(ln_fee_amount);

EXCEPTION
WHEN OTHERS	THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while returning fee_amount in get_hea_fee_amount : '||Sqlerrm);
	RETURN(0);
END get_hea_fee_amount;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : GET_FEE_LINE_NUMBER                                                 |
-- | Description : To get line number for particular transaction                       |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- | 1.0      23-MAR-2020  Divyansh Saini       Initial draft version                  |
-- +===================================================================================+

FUNCTION get_fee_line_number(p_customer_trx_id NUMBER,p_description IN VARCHAR2,p_organization IN NUMBER,p_line_number IN NUMBER) RETURN NUMBER
IS

ln_line_number NUMBER;
ln_org_id      NUMBER;
lv_header_line VARCHAR2(2):= 'N';

BEGIN

   BEGIN
      SELECT 'Y'
        INTO lv_header_line
          FROM ra_customer_trx_lines_All RCTL
                ,fnd_lookup_values flv
       WHERE 1=1
         AND flv.lookup_type = 'OD_FEES_ITEMS'
         AND flv.LANGUAGE='US'
         AND flv.attribute6= rctl.INVENTORY_ITEM_ID
         AND FLV.enabled_flag = 'Y'
         AND SYSDATE BETWEEN NVL(FLV.start_date_active,SYSDATE) AND NVL(FLV.end_date_active,SYSDATE+1)
         AND FLV.attribute7 IN ('HEADER')
         AND customer_trx_id = p_customer_trx_id
         AND line_number = p_line_number;

   IF lv_header_line = 'Y' THEN
     SELECT count(0)
       INTO ln_line_number
       FROM ra_customer_trx_lines_All
      WHERE customer_trx_id = p_customer_trx_id;
   END IF;
   EXCEPTION WHEN NO_DATA_FOUND THEN
      ln_line_number :=0;
      lv_header_line := 'N';
    WHEN OTHERS THEN
      ln_line_number :=0;
      lv_header_line := 'N';
   END;
   
   IF lv_header_line != 'Y' THEN
       BEGIN
           SELECT to_number(attribute12)
             INTO ln_line_number
             FROM ra_customer_trx_lines_all rctl
            WHERE 1=1
              AND line_number = p_line_number
              AND rctl.customer_trx_id = p_customer_trx_id
              AND rownum=1;
       EXCEPTION WHEN OTHERS THEN
          ln_line_number := 0 ;
       END;
   END IF;
   IF ln_line_number =0 THEN
      RETURN p_line_number;
   ELSIF ln_line_number IS NULL THEN
      RETURN p_line_number;
   ELSE
      RETURN ln_line_number||'.'||p_line_number;
   END IF;


EXCEPTION
WHEN OTHERS	THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while returning fee_amount in get_fee_amount : '||Sqlerrm);
	RETURN(p_line_number);
END get_fee_line_number;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : GET_FEE_OPTION                                                 |
-- | Description : To get fee option for particular transaction                       |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- | 1.0      23-MAR-2020  Divyansh Saini       Initial draft version                  |
-- +===================================================================================+
FUNCTION get_fee_option (p_cust_doc_id IN NUMBER,
                         p_mbs_doc_type  IN VARCHAR2,
						 p_cust_account_id IN NUMBER,
						 p_del_method IN VARCHAR2 default 'ePDF') RETURN NUMBER IS

ln_attr_group_id NUMBER := 0;
ln_fee_option    NUMBER := 0;
BEGIN

	BEGIN
		SELECT attr_group_id
		INTO   ln_attr_group_id
		FROM   ego_attr_groups_v
		WHERE  attr_group_type = 'XX_CDH_CUST_ACCOUNT'
		AND    attr_group_name = 'BILLDOCS' ;
	 EXCEPTION
		WHEN NO_DATA_FOUND THEN
		   ln_attr_group_id := 0;
		WHEN OTHERS THEN
		   ln_attr_group_id := 0;
	 END;

	BEGIN
		 SELECT NVL(fee_option,0)
		   INTO ln_fee_option
		   FROM xx_cdh_cust_acct_ext_b
		  WHERE n_ext_attr2   = p_cust_doc_id
		    AND d_ext_attr2 is null
			and c_ext_attr1 = NVL(p_mbs_doc_type,c_ext_attr1)
			AND attr_group_id = ln_attr_group_id
			AND rownum =1;
	 EXCEPTION
		WHEN NO_DATA_FOUND THEN
		   ln_fee_option := -1;
		WHEN OTHERS THEN
		   ln_fee_option := 0;
	 END;

   IF ln_fee_option = -1 THEN
      BEGIN
		 SELECT NVL(fee_option,0)
		   INTO ln_fee_option
		   FROM xx_cdh_cust_acct_ext_b
		  WHERE cust_account_id   = p_cust_account_id
			AND c_ext_attr3 = p_del_method
			AND attr_group_id = ln_attr_group_id
            and c_ext_attr1 = p_mbs_doc_type
			AND c_ext_attr16 = 'COMPLETE'
			AND d_ext_attr2 is null
			AND d_ext_attr1 = (select max(d_ext_attr1)
			                     FROM xx_cdh_cust_acct_ext_b
			                     WHERE cust_account_id   = p_cust_account_id
								   AND c_ext_attr3 = p_del_method
								   AND attr_group_id = ln_attr_group_id
                                   and c_ext_attr1 = p_mbs_doc_type
								   AND c_ext_attr16 = 'COMPLETE'
								   AND d_ext_attr2 is null);
	 EXCEPTION
		WHEN NO_DATA_FOUND THEN
		   ln_fee_option := 0;
		WHEN OTHERS THEN
		   ln_fee_option := 0;
	 END;
   END IF;

return ln_fee_option;

EXCEPTION
WHEN OTHERS	THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while returning fee_option in get_fee_option : '||Sqlerrm);
	RETURN(ln_fee_option);
END;

FUNCTION get_fee_option (p_cust_doc_id IN NUMBER,
                         p_mbs_doc_type  IN VARCHAR2,
						 p_cust_account_id IN NUMBER,
						 p_del_method IN VARCHAR2 default 'ePDF',
             p_cons_inv_id IN NUMBER,
             p_customer_trx_id IN NUMBER) RETURN NUMBER IS

ln_attr_group_id NUMBER := 0;
ln_fee_option    NUMBER := 0;
ln_cust_doc_id   NUMBER :=0;
BEGIN

ln_cust_doc_id:= p_cust_doc_id;
	BEGIN
		SELECT attr_group_id
		INTO   ln_attr_group_id
		FROM   ego_attr_groups_v
		WHERE  attr_group_type = 'XX_CDH_CUST_ACCOUNT'
		AND    attr_group_name = 'BILLDOCS' ;
	 EXCEPTION
		WHEN NO_DATA_FOUND THEN
		   ln_attr_group_id := 0;
		WHEN OTHERS THEN
		   ln_attr_group_id := 0;
	 END;
   IF ln_cust_doc_id IS NULL AND p_cons_inv_id IS NOT NULL THEN
     BEGIN
      SELECT cust_doc_id
        INTO ln_cust_doc_id
        FROM xx_ar_ebl_cons_hdr_hist
       WHERE cons_inv_id = p_cons_inv_id
         AND customer_trx_id = p_customer_trx_id
         AND billdocs_delivery_method = 'ePDF' 
         AND DOCUMENT_TYPE = 'Paydoc'
         AND exists (SELECT 1
                       FROM xx_cdh_cust_acct_ext_b
                      WHERE n_ext_attr2 = cust_doc_id
                        AND d_ext_attr2 is null);
     EXCEPTION
        WHEN NO_DATA_FOUND THEN
           ln_cust_doc_id := null;
        WHEN OTHERS THEN
           ln_cust_doc_id := null;
       END;
   END IF;
   
   IF ln_cust_doc_id IS NULL AND p_customer_trx_id IS NOT NULL THEN
   
     BEGIN
      SELECT cust_doc_id
        INTO ln_cust_doc_id
        FROM (
          SELECT cust_doc_id
            FROM xx_ar_ebl_cons_hdr_hist
           WHERE customer_trx_id = p_customer_trx_id
             AND billdocs_delivery_method = 'ePDF' 
             AND DOCUMENT_TYPE = 'Paydoc'
             AND exists (SELECT 1
                           FROM xx_cdh_cust_acct_ext_b
                          WHERE n_ext_attr2 = cust_doc_id
                            AND d_ext_attr2 is null)
             AND rownum=1
          UNION
          SELECT cust_doc_id
            FROM xx_ar_ebl_ind_hdr_hist
           WHERE customer_trx_id = p_customer_trx_id
             AND billdocs_delivery_method = 'ePDF' 
             AND DOCUMENT_TYPE = 'Paydoc'
             AND exists (SELECT 1
                           FROM xx_cdh_cust_acct_ext_b
                          WHERE n_ext_attr2 = cust_doc_id
                            AND d_ext_attr2 is null)
             AND rownum=1 );
     EXCEPTION
        WHEN NO_DATA_FOUND THEN
           ln_cust_doc_id := null;
        WHEN OTHERS THEN
           ln_cust_doc_id := null;
       END;
   
   END IF;

	BEGIN
		 SELECT NVL(fee_option,0)
		   INTO ln_fee_option
		   FROM xx_cdh_cust_acct_ext_b
		  WHERE n_ext_attr2   = ln_cust_doc_id
		    AND d_ext_attr2 is null
			and c_ext_attr1 = NVL(p_mbs_doc_type,c_ext_attr1)
			AND attr_group_id = ln_attr_group_id
			AND rownum =1;
	 EXCEPTION
		WHEN NO_DATA_FOUND THEN
		   ln_fee_option := -1;
		WHEN OTHERS THEN
		   ln_fee_option := 0;
	 END;

   IF ln_fee_option = -1 THEN
      BEGIN
		 SELECT NVL(fee_option,0)
           INTO ln_fee_option
           FROM xx_cdh_cust_acct_ext_b
          WHERE cust_account_id   = p_cust_account_id
            AND c_ext_attr3 = p_del_method
            AND attr_group_id = ln_attr_group_id
            and c_ext_attr1 = p_mbs_doc_type
            AND c_ext_attr16 = 'COMPLETE'
            AND C_EXT_ATTR2 = 'Y' --paydoc
            AND d_ext_attr2 is null
            AND d_ext_attr1 = (select max(d_ext_attr1)
                                 FROM xx_cdh_cust_acct_ext_b
                                 WHERE cust_account_id   = p_cust_account_id
                                   AND c_ext_attr3 = p_del_method
                                   AND attr_group_id = ln_attr_group_id
                                   and c_ext_attr1 = p_mbs_doc_type
                                   AND c_ext_attr16 = 'COMPLETE'
                                   AND C_EXT_ATTR2 = 'Y' --paydoc
                                   AND d_ext_attr2 is null);
	 EXCEPTION
		WHEN NO_DATA_FOUND THEN
		   ln_fee_option := 0;
		WHEN OTHERS THEN
		   ln_fee_option := 0;
	 END;
   END IF;
   
   IF ln_fee_option <= 0 THEN
      BEGIN
		 SELECT NVL(fee_option,0)
           INTO ln_fee_option
           FROM xx_cdh_cust_acct_ext_b
          WHERE cust_account_id   = p_cust_account_id
            AND c_ext_attr3 = p_del_method
            AND attr_group_id = ln_attr_group_id
            and c_ext_attr1 = p_mbs_doc_type
            AND c_ext_attr16 = 'COMPLETE'
            AND d_ext_attr2 is null
            AND CREATION_DATE = (select max(CREATION_DATE)
                                 FROM xx_cdh_cust_acct_ext_b
                                 WHERE cust_account_id   = p_cust_account_id
                                   AND c_ext_attr3 = p_del_method
                                   AND attr_group_id = ln_attr_group_id
                                   and c_ext_attr1 = p_mbs_doc_type
                                   AND c_ext_attr16 = 'COMPLETE'
                                   AND d_ext_attr2 is null);
	 EXCEPTION
		WHEN NO_DATA_FOUND THEN
		   ln_fee_option := 0;
		WHEN OTHERS THEN
		   ln_fee_option := 0;
	 END;   
   
   END IF; 
   IF ln_fee_option <= 0 THEN
      ln_fee_option := 0 ;
   END IF;
      

return ln_fee_option;

EXCEPTION
WHEN OTHERS	THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while returning fee_option in get_fee_option : '||Sqlerrm);
	RETURN(ln_fee_option);
END;


-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_softhdr_amount                                                  |
-- | Description : To get Soft Header Amount for particular transaction                |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- | 1.0      23-JUN-2020  Divyansh Saini       Initial draft version                  |
-- +===================================================================================+
FUNCTION get_softhdr_amount(p_line_type IN VARCHAR2
                            ,p_sft_text IN VARCHAR2
                            ,p_cons_id IN NUMBER
                            ,p_cust_doc_id IN NUMBER
                            ,p_request_id IN NUMBER
							              ,p_customer_trx_id IN VARCHAR2) RETURN NUMBER IS
ln_fee_amount NUMBER :=0;
lv_sft_txt    VARCHAR2(100);
lv_sft_hdr    VARCHAR2(100);
lv_where      VARCHAR2(100);
lv_sql        VARCHAR2(2000);
lv_doc_level  VARCHAR2(100);
BEGIN

    select a.DOC_DETAIL_LEVEL 
      INTO lv_doc_level
      from XX_CDH_MBS_DOCUMENT_MASTER a,
           xx_cdh_cust_acct_ext_b b
     where b.n_ext_attr2 = p_cust_doc_id
       and a.DOCUMENT_ID = b.n_ext_attr1 AND rownum=1;

    IF p_line_type = 'BILL_TO_TOTAL' THEN
       SELECT NVL(SUM(XX_AR_EBL_COMMON_UTIL_PKG.get_line_fee_amount(customer_trx_id) + XX_AR_EBL_COMMON_UTIL_PKG.get_hea_fee_amount(customer_trx_id)),0)
         INTO ln_fee_amount
         FROM xx_ar_ebl_cons_hdr_main
        WHERE cons_inv_id = p_cons_id and cust_doc_id = p_cust_doc_id;
    ELSIF p_line_type = 'SOFTHDR_TOTAL' AND lv_doc_level = 'SUMMARIZE' THEN
      SELECT trim(substr(p_sft_text,INSTR(p_sft_text,':')+1))
        INTO lv_sft_txt
        FROM DUAL;
		
        IF lv_sft_txt IS NOT NULL THEN
           
		   		SELECT DECODE(lv_sft_txt,sfdata1, ' AND sfdata1 = '''||sfdata1||'''',
			                     sfdata2, ' AND sfdata1 = '''||sfdata1||''' AND sfdata2='''||sfdata2||'''',
								 sfdata3, ' AND sfdata1 = '''||sfdata1||''' AND sfdata2='''||sfdata2||''' AND sfdata3='''||sfdata3||'''',
								 sfdata4, ' AND sfdata1 = '''||sfdata1||''' AND sfdata2='''||sfdata2||''' AND sfdata3='''||sfdata3||''' AND sfdata4='''||sfdata4||'''',
								 sfdata5, ' AND sfdata1 = '''||sfdata1||''' AND sfdata2='''||sfdata2||''' AND sfdata3='''||sfdata3||''' AND sfdata4='''||sfdata4||''' AND sfdata5='''||sfdata5||'''',
								 sfdata6, ' AND sfdata1 = '''||sfdata1||''' AND sfdata2='''||sfdata2||''' AND sfdata3='''||sfdata3||''' AND sfdata4='''||sfdata4||''' AND sfdata5='''||sfdata5||'''AND sfdata6='''||sfdata6||'''')
				  INTO lv_where
				  FROM xx_ar_ebl_cons_trx_stg 
				 WHERE request_id = p_request_id and CUSTOMER_TRX_ID = p_customer_trx_id
				   AND INV_TYPE not in ('SOFTHDR_TOTALS','BILLTO_TOTALS','GRAND_TOTAL');	
		   
		   lv_sql := 'SELECT NVL(SUM(XX_AR_EBL_COMMON_UTIL_PKG.get_line_fee_amount(customer_trx_id) + XX_AR_EBL_COMMON_UTIL_PKG.get_hea_fee_amount(customer_trx_id)),0) FROM xx_ar_ebl_cons_trx_stg where request_id = '||p_request_id||' AND INV_TYPE not in (''SOFTHDR_TOTALS'',''BILLTO_TOTALS'',''GRAND_TOTAL'')'||lv_where;
		   EXECUTE IMMEDIATE lv_sql INTO ln_fee_amount;
        ELSIF   lv_sft_txt IS NULL THEN
           SELECT NVL(SUM(XX_AR_EBL_COMMON_UTIL_PKG.get_line_fee_amount(customer_trx_id) + XX_AR_EBL_COMMON_UTIL_PKG.get_hea_fee_amount(customer_trx_id)),0)
             INTO ln_fee_amount
             FROM xx_ar_ebl_cons_hdr_main
            WHERE cons_inv_id = p_cons_id and cust_doc_id = p_cust_doc_id
              AND COST_CENTER_SFT_DATA IS NULL;
        END IF;
    ELSIF p_line_type = 'SOFTHDR_TOTAL' AND lv_doc_level = 'ONE' THEN
       SELECT NVL(trim(substr(p_sft_text,INSTR(p_sft_text,':')+1)),'X'),REPLACE(trim(substr(p_sft_text,1,INSTR(p_sft_text,':')+1)),'TOTAL FOR ')
         INTO lv_sft_txt,lv_sft_hdr
         FROM DUAL;
         
       SELECT CASE WHEN sfhdr1 = lv_sft_hdr AND NVL(sfdata1,'X') like lv_sft_txt||'%' THEN
              ' AND NVL(sfdata1,''X'') = NVL('''||sfdata1||''',''X'')'
              WHEN sfhdr2 = lv_sft_hdr AND NVL(sfdata2,'X') like lv_sft_txt||'%' THEN
              ' AND NVL(sfdata2,''X'') = NVL('''||sfdata2||''',''X'')'
              WHEN sfhdr3 = lv_sft_hdr AND NVL(sfdata3,'X') like lv_sft_txt||'%' THEN
              ' AND NVL(sfdata3,''X'') = NVL('''||sfdata3||''',''X'')'
              WHEN sfhdr4 = lv_sft_hdr AND NVL(sfdata4,'X') like lv_sft_txt||'%' THEN
              ' AND NVL(sfdata4,''X'') = NVL('''||sfdata4||''',''X'')'
              WHEN sfhdr5 = lv_sft_hdr AND NVL(sfdata5,'X') like lv_sft_txt||'%' THEN
              ' AND NVL(sfdata5,''X'') = NVL('''||sfdata5||''',''X'')'
              WHEN sfhdr6 = lv_sft_hdr AND NVL(sfdata6,'X') like lv_sft_txt||'%' THEN
              ' AND NVL(sfdata6,''X'') = NVL('''||sfdata6||''',''X'')'
              END
         INTO lv_where
         FROM xx_ar_ebl_cons_trx_stg
        WHERE request_id = p_request_id
          AND INV_TYPE not in ('SOFTHDR_TOTALS','BILLTO_TOTALS','GRAND_TOTAL') AND rownum =1
          AND ((sfhdr1 = lv_sft_hdr AND NVL(sfdata1,'X') like lv_sft_txt||'%') OR
               (sfhdr2 = lv_sft_hdr AND NVL(sfdata2,'X') like lv_sft_txt||'%') OR
               (sfhdr3 = lv_sft_hdr AND NVL(sfdata3,'X') like lv_sft_txt||'%') OR
               (sfhdr4 = lv_sft_hdr AND NVL(sfdata4,'X') like lv_sft_txt||'%') OR
               (sfhdr5 = lv_sft_hdr AND NVL(sfdata5,'X') like lv_sft_txt||'%') OR
               (sfhdr6 = lv_sft_hdr AND NVL(sfdata6,'X') like lv_sft_txt||'%') );
       lv_sql := 'SELECT NVL(SUM(XX_AR_EBL_COMMON_UTIL_PKG.get_line_fee_amount(customer_trx_id) + XX_AR_EBL_COMMON_UTIL_PKG.get_hea_fee_amount(customer_trx_id)),0) FROM xx_ar_ebl_cons_trx_stg where request_id = '||p_request_id||' AND INV_TYPE not in (''SOFTHDR_TOTALS'',''BILLTO_TOTALS'',''GRAND_TOTAL'')'||lv_where;
       EXECUTE IMMEDIATE lv_sql INTO ln_fee_amount;          
         
    END IF;

    return ln_fee_amount;

EXCEPTION WHEN OTHERS THEN
return 0;
END;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_softhdr_amount                                                  |
-- | Description : To get Soft Header Amount for particular transaction                |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- | 1.0      23-JUN-2020  Divyansh Saini       Initial draft version                  |
-- +===================================================================================+
FUNCTION get_softhdr_amount_fis(p_line_type IN VARCHAR2
                            ,p_sft_text IN VARCHAR2
                            ,p_cons_id IN NUMBER
                            ,p_request_id IN NUMBER
							              ,p_customer_trx_id IN VARCHAR2) RETURN NUMBER IS
ln_fee_amount NUMBER :=0;
lv_sft_txt    VARCHAR2(100);
lv_where      VARCHAR2(100);
lv_sql        VARCHAR2(2000);
BEGIN

   IF p_line_type = 'BILL_TO_TOTAL' THEN
       SELECT NVL(SUM(XX_AR_EBL_COMMON_UTIL_PKG.get_line_fee_amount(customer_trx_id) + XX_AR_EBL_COMMON_UTIL_PKG.get_hea_fee_amount(customer_trx_id)),0)
         INTO ln_fee_amount
         FROM xx_ar_cbi_trx_all
        WHERE cons_inv_id = p_cons_id and request_id = p_request_id;
   ELSIF p_line_type = 'SOFTHDR_TOTAL' THEN
      SELECT trim(substr(p_sft_text,INSTR(p_sft_text,':')+1))
        INTO lv_sft_txt
        FROM DUAL;
		
        IF lv_sft_txt IS NOT NULL THEN
           
		   		SELECT DECODE(lv_sft_txt,sfdata1, ' AND sfdata1 = '''||sfdata1||'''',
			                     sfdata2, ' AND sfdata1 = '''||sfdata1||''' AND sfdata2='''||sfdata2||'''',
								 sfdata3, ' AND sfdata1 = '''||sfdata1||''' AND sfdata2='''||sfdata2||''' AND sfdata3='''||sfdata3||'''',
								 sfdata4, ' AND sfdata1 = '''||sfdata1||''' AND sfdata2='''||sfdata2||''' AND sfdata3='''||sfdata3||''' AND sfdata4='''||sfdata4||'''',
								 sfdata5, ' AND sfdata1 = '''||sfdata1||''' AND sfdata2='''||sfdata2||''' AND sfdata3='''||sfdata3||''' AND sfdata4='''||sfdata4||''' AND sfdata5='''||sfdata5||'''',
								 sfdata6, ' AND sfdata1 = '''||sfdata1||''' AND sfdata2='''||sfdata2||''' AND sfdata3='''||sfdata3||''' AND sfdata4='''||sfdata4||''' AND sfdata5='''||sfdata5||'''AND sfdata6='''||sfdata6||'''')
				  INTO lv_where
				  FROM xx_ar_cbi_trx_all 
				 WHERE request_id = p_request_id and CUSTOMER_TRX_ID = p_customer_trx_id
				   AND INV_TYPE not in ('SOFTHDR_TOTALS','BILLTO_TOTALS','GRAND_TOTAL');	
		   
		   lv_sql := 'SELECT NVL(SUM(XX_AR_EBL_COMMON_UTIL_PKG.get_line_fee_amount(customer_trx_id) + XX_AR_EBL_COMMON_UTIL_PKG.get_hea_fee_amount(customer_trx_id)),0) FROM xx_ar_cbi_trx_all where request_id = '||p_request_id||' AND INV_TYPE not in (''SOFTHDR_TOTALS'',''BILLTO_TOTALS'',''GRAND_TOTAL'')'||lv_where;
		   EXECUTE IMMEDIATE lv_sql INTO ln_fee_amount;
        ELSIF   lv_sft_txt IS NULL THEN
           SELECT NVL(SUM(XX_AR_EBL_COMMON_UTIL_PKG.get_line_fee_amount(customer_trx_id) + XX_AR_EBL_COMMON_UTIL_PKG.get_hea_fee_amount(customer_trx_id)),0)
             INTO ln_fee_amount
             FROM xx_ar_cbi_trx_all
            WHERE cons_inv_id = p_cons_id and request_id = p_request_id;
             -- AND COST_CENTER_SFT_DATA IS NULL;
        END IF;
    END IF;

    return ln_fee_amount;

EXCEPTION WHEN OTHERS THEN
return 0;
END;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_softhdr_rep_amount                                              |
-- | Description : To get Soft Header Amount for reprint    transaction                |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- | 1.0      23-JUN-2020  Divyansh Saini       Initial draft version                  |
-- +===================================================================================+
FUNCTION get_softhdr_rep_amount(p_line_type IN VARCHAR2,p_sft_text IN VARCHAR2,p_cons_id IN NUMBER
                                ,p_request_id IN NUMBER
							    ,p_customer_trx_id IN VARCHAR2
                                ,p_template_type IN VARCHAR2 DEFAULT NULL) RETURN NUMBER IS
ln_fee_amount NUMBER :=0;
lv_sft_txt    VARCHAR2(100);
lv_where      VARCHAR2(100);
lv_sql        VARCHAR2(2000);
lv_sft_hdr    VARCHAR2(100);
BEGIN

   IF p_line_type = 'BILL_TO_TOTAL' THEN
       SELECT NVL(SUM(XX_AR_EBL_COMMON_UTIL_PKG.get_line_fee_amount(customer_trx_id) + XX_AR_EBL_COMMON_UTIL_PKG.get_hea_fee_amount(customer_trx_id)),0)
         INTO ln_fee_amount
         FROM (SELECT DISTINCT attribute3 customer_trx_id
		 FROM xx_ar_cbi_rprn_rows
        WHERE request_id = p_request_id 
		  AND cons_inv_id = p_cons_id
		  AND LINE_TYPE not in ('SOFTHDR_TOTALS','BILLTO_TOTALS','GRAND_TOTAL'));
   ELSIF p_line_type = 'SOFTHDR_TOTAL' AND p_template_type IS NULL THEN
      SELECT NVL(trim(substr(p_sft_text,INSTR(p_sft_text,':')+1)),'X'),REPLACE(trim(substr(p_sft_text,1,INSTR(p_sft_text,':')+1)),'TOTAL FOR ')
         INTO lv_sft_txt,lv_sft_hdr
         FROM DUAL;
		
        IF lv_sft_txt IS NOT NULL THEN
           
		   	SELECT CASE WHEN sfhdr1 = lv_sft_hdr AND NVL(sfdata1,'X') like lv_sft_txt||'%' THEN
                          ' AND NVL(sfdata1,''X'') = NVL('''||sfdata1||''',''X'')'
                          WHEN sfhdr2 = lv_sft_hdr AND NVL(sfdata2,'X') like lv_sft_txt||'%' THEN
                          ' AND NVL(sfdata1,''X'') = NVL('''||sfdata1||''',''X'')'||' AND NVL(sfdata2,''X'') = NVL('''||sfdata2||''',''X'')'
                          WHEN sfhdr3 = lv_sft_hdr AND NVL(sfdata3,'X') like lv_sft_txt||'%' THEN
                          ' AND NVL(sfdata1,''X'') = NVL('''||sfdata1||''',''X'')'||' AND NVL(sfdata2,''X'') = NVL('''||sfdata2||''',''X'')'||' AND NVL(sfdata3,''X'') = NVL('''||sfdata3||''',''X'')'
                          WHEN sfhdr4 = lv_sft_hdr AND NVL(sfdata4,'X') like lv_sft_txt||'%' THEN
                          ' AND NVL(sfdata1,''X'') = NVL('''||sfdata1||''',''X'')'||' AND NVL(sfdata2,''X'') = NVL('''||sfdata2||''',''X'')'||' AND NVL(sfdata3,''X'') = NVL('''||sfdata3||''',''X'')'||' AND NVL(sfdata4,''X'') = NVL('''||sfdata4||''',''X'')'
                          WHEN sfhdr5 = lv_sft_hdr AND NVL(sfdata5,'X') like lv_sft_txt||'%' THEN
                          ' AND NVL(sfdata1,''X'') = NVL('''||sfdata1||''',''X'')'||' AND NVL(sfdata2,''X'') = NVL('''||sfdata2||''',''X'')'||' AND NVL(sfdata3,''X'') = NVL('''||sfdata3||''',''X'')'||' AND NVL(sfdata4,''X'') = NVL('''||sfdata4||''',''X'')'||' AND NVL(sfdata5,''X'') = NVL('''||sfdata5||''',''X'')'
                          END
				  INTO lv_where
				  FROM xx_ar_cbi_rprn_trx
				 WHERE request_id = p_request_id and customer_trx_id = p_customer_trx_id
				   AND INV_TYPE not in ('SOFTHDR_TOTALS','BILLTO_TOTALS','GRAND_TOTAL');	
		   
		   lv_sql := 'SELECT NVL(SUM(XX_AR_EBL_COMMON_UTIL_PKG.get_line_fee_amount(customer_trx_id) + XX_AR_EBL_COMMON_UTIL_PKG.get_hea_fee_amount(customer_trx_id)),0) FROM xx_ar_cbi_rprn_trx where request_id = '||p_request_id||' AND INV_TYPE not in (''SOFTHDR_TOTAL'',''BILL_TO_TOTAL'',''GRAND_TOTAL'')'||lv_where;
		   EXECUTE IMMEDIATE lv_sql INTO ln_fee_amount;
        ELSIF   lv_sft_txt IS NULL THEN
             ln_fee_amount := 0;
        END IF;
    ELSIF p_line_type = 'SOFTHDR_TOTAL' AND p_template_type ='ONE' THEN
       SELECT NVL(trim(substr(p_sft_text,INSTR(p_sft_text,':')+1)),'X'),REPLACE(trim(substr(p_sft_text,1,INSTR(p_sft_text,':')+1)),'TOTAL FOR ')
         INTO lv_sft_txt,lv_sft_hdr
         FROM DUAL;
         
       SELECT CASE WHEN sfhdr1 = lv_sft_hdr AND NVL(sfdata1,'X') like lv_sft_txt||'%' THEN
              ' AND NVL(sfdata1,''X'') = NVL('''||sfdata1||''',''X'')'
              WHEN sfhdr2 = lv_sft_hdr AND NVL(sfdata2,'X') like lv_sft_txt||'%' THEN
              ' AND NVL(sfdata2,''X'') = NVL('''||sfdata2||''',''X'')'
              WHEN sfhdr3 = lv_sft_hdr AND NVL(sfdata3,'X') like lv_sft_txt||'%' THEN
              ' AND NVL(sfdata3,''X'') = NVL('''||sfdata3||''',''X'')'
              WHEN sfhdr4 = lv_sft_hdr AND NVL(sfdata4,'X') like lv_sft_txt||'%' THEN
              ' AND NVL(sfdata4,''X'') = NVL('''||sfdata4||''',''X'')'
              WHEN sfhdr5 = lv_sft_hdr AND NVL(sfdata5,'X') like lv_sft_txt||'%' THEN
              ' AND NVL(sfdata5,''X'') = NVL('''||sfdata5||''',''X'')'
              END
         INTO lv_where
         FROM xx_ar_cbi_rprn_trx
        WHERE request_id = p_request_id
          AND INV_TYPE not in ('SOFTHDR_TOTALS','BILLTO_TOTALS','GRAND_TOTAL') AND rownum =1
          AND ((sfhdr1 = lv_sft_hdr AND NVL(sfdata1,'X') like lv_sft_txt||'%') OR
               (sfhdr2 = lv_sft_hdr AND NVL(sfdata2,'X') like lv_sft_txt||'%') OR
               (sfhdr3 = lv_sft_hdr AND NVL(sfdata3,'X') like lv_sft_txt||'%') OR
               (sfhdr4 = lv_sft_hdr AND NVL(sfdata4,'X') like lv_sft_txt||'%') OR
               (sfhdr5 = lv_sft_hdr AND NVL(sfdata5,'X') like lv_sft_txt||'%') );
       lv_sql := 'SELECT NVL(SUM(XX_AR_EBL_COMMON_UTIL_PKG.get_line_fee_amount(customer_trx_id) + XX_AR_EBL_COMMON_UTIL_PKG.get_hea_fee_amount(customer_trx_id)),0) FROM xx_ar_cbi_rprn_trx where request_id = '||p_request_id||' AND INV_TYPE not in (''SOFTHDR_TOTAL'',''BILL_TO_TOTAL'',''GRAND_TOTAL'')'||lv_where;
       EXECUTE IMMEDIATE lv_sql INTO ln_fee_amount;   
    END IF;

    return ln_fee_amount;

EXCEPTION WHEN OTHERS THEN
return 0;
END;


END XX_AR_EBL_COMMON_UTIL_PKG;
/