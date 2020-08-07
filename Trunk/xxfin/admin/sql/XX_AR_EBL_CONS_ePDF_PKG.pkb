create or replace
PACKAGE BODY XX_AR_EBL_CONS_EPDF_PKG
 AS

    gc_error_location       VARCHAR2(2000);
    gc_debug                VARCHAR2(1000);

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : XX_AR_EBL_CONS_EPDF_PKG                                             |
-- | Description : This Package is used to get the Consolidated Bills through ePDF.    |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 15-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- |      1.1 15-MAR-2010  Vasu Raparla            Removed Schema References for R12.2 |
-- |      1.2 08-DEC-2015  Havish Kasina           Updated 3 new fields dept_code,     |
-- |                                               dept_desc and dept_sft_hdr fields   |
-- |                                               Defect 36437 ()MOD4B Release 3)     |
-- |      1.3 26-JAN-2016  Havish Kasina           Changed the value from 25 to 44 in  |
-- |                                               INSERT_SUMM_ONE_TOTALS as per MOD4B |
-- |                                               Rel 3 changes Defect 1994 (SUMSUM)  |
-- |                                               Changed the value from 20 to 44 in  |
-- |                                               INSERT_TRX_TOTALS as per MOD4B Rel 3|
-- |                                               changes Defect 1994 (SUMDETAIL)     |
-- |      1.4 03-JUN-2016  Havish Kasina           Kitting Changes (Defect 37675)      |
-- |      1.5 17-OCT-2016  Suresh Naragam          Changes done to fix the Defect 39707|
-- |      1.6 29-AUG-2018  Sravan Basireddy        Changes done for SKU Level Tax,     |
-- |                                               NAIT-58403                          |
-- +===================================================================================+

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : MULTI_THREAD_ePDF                                                   |
-- | Description : This Procedure is used to multi thread the bills getting printed    |
-- |               through ePDF. The number of consolidated bills in each thread is    |
-- |               controlled using the batch size.                                    |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 15-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- |      1.1 09-Apr-2012  Rajeshkumar M R         Defect#18432                        |
-- +===================================================================================+
    PROCEDURE MULTI_THREAD_EPDF ( x_error_buff                 OUT VARCHAR2
                                 ,x_retcode                    OUT NUMBER
                                 ,p_batch_size                 IN  NUMBER
                                 ,p_thread_count               IN  NUMBER
                                 ,p_debug_flag                 IN  VARCHAR2
                                 ,p_del_meth                   IN  VARCHAR2
                                 ,p_doc_type                   IN  VARCHAR2
                                 ,p_cycle_date                 IN  VARCHAR2
                                 )
    AS

       CURSOR  lcu_batch_bills ( p_doc_level   IN   VARCHAR2
                                ,p_status      IN   VARCHAR2
                                ,p_org_id      IN   NUMBER
                                ,p_cycle_date  IN   DATE
                                )
       IS
       SELECT  DISTINCT XAECHM.parent_cust_doc_id   parent_cust_doc_id
                       ,XAECHM.extract_batch_id     extract_batch_id
       FROM     xx_ar_ebl_cons_hdr_main      XAECHM
               ,xx_ar_ebl_file                XAEF
       WHERE    XAECHM.billdocs_delivery_method   =  p_del_meth
       AND      XAECHM.epdf_doc_level             =  p_doc_level
       AND      XAECHM.org_id                     =  p_org_id
       AND      XAECHM.bill_to_date               <= p_cycle_date
       AND      XAEF.file_id                      = XAECHM.file_id
       AND      XAEF.status                       = p_status;

       CURSOR  lcu_batch_id (p_org_id    IN   NUMBER)
       IS
       SELECT  DISTINCT XAECHM.batch_id
              ,XAECHM.ePDF_doc_level
       FROM    xx_ar_ebl_cons_hdr_main    XAECHM
       WHERE   XAECHM.billdocs_delivery_method    = p_del_meth
       AND     XAECHM.org_id                      = p_org_id
       AND     XAECHM.status                      = 'MARKED_FOR_RENDER';

     /*Added as per Defect# 18432 to resolve Render error issue */
      CURSOR lcu_file_status
      IS
      SELECT invoice_type,cust_doc_id,file_id,transmission_id,status 
	  from xx_ar_ebl_file where status='RENDER_ERROR' and invoice_type='CONS'; --Removed apps schema References

       TYPE batch_id_tbl_type      IS TABLE OF lcu_batch_bills%ROWTYPE INDEX BY BINARY_INTEGER;
       lt_batch_id                 batch_id_tbl_type;

       ln_custdoc_count            NUMBER := 0;
       ln_batch_count              NUMBER := 1;
       ln_batch_id                 NUMBER := 0;
       ln_doc_count                NUMBER := 1;
       ln_batch_size               NUMBER;
       ln_count                    NUMBER;

       lc_status                   VARCHAR2(10)     := 'RENDER';
       ln_org_id                   NUMBER(10);

       lc_appl_short_name          VARCHAR2(10)     := 'XXFIN';
       lc_child_pgm_name           VARCHAR2(30)     := 'XX_AR_EBL_SUBMIT_ePDF_CHILD';
       lc_conc_pgm_name            VARCHAR2(20); --Increased size to 20 from 15 as part of SKU Level Tax, NAIT-58403
       ln_request_id               NUMBER  := 0;
       ln_parent_req_id            NUMBER;
       ln_err_req_cnt              NUMBER;
       ln_thread_count             NUMBER  := 0;

       lc_doc_detail_level         xx_ar_ebl_cons_hdr_main.ePDF_doc_level%TYPE;

       lc_request_data             VARCHAR2(15);
       lb_debug                    BOOLEAN;

       lc_cm_text1                 VARCHAR2(50);
       lc_cm_text2                 VARCHAR2(50);
       lc_gift_card_text1          VARCHAR2(50);
       lc_gift_card_text2          VARCHAR2(50);
       lc_gift_card_text3          VARCHAR2(50);

       ld_cycle_date               DATE;

       ex_user_exception           EXCEPTION; 
	   /*Added as per Defect# 18432 to resolve Render error issue */
       lc_errbuf    VARCHAR2(2000);
       lc_retcode   VARCHAR2(2000);
	   ln_error_rec_count Number:=0;

    BEGIN

       IF p_debug_flag = 'Y' THEN
          lb_debug  := TRUE;
       ELSE
          lb_debug  := FALSE;
       END IF;

       ln_parent_req_id       := FND_GLOBAL.CONC_REQUEST_ID;
       lc_request_data        := FND_CONC_GLOBAL.REQUEST_DATA;
       ln_org_id              := FND_PROFILE.VALUE('ORG_ID');
       ld_cycle_date          := FND_CONC_DATE.STRING_TO_DATE(p_cycle_date);

       XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug
                                              ,TRUE
                                              ,'Cycle Date : '||TO_CHAR(ld_cycle_date,'DD_MON_YYYY HH24:MI:SS')
                                              );

       IF lc_request_data IS NULL THEN

          /* Calculate Batching Logic. */
          BEGIN

             gc_error_location := 'Inside Threading Program';
             gc_debug          := NULL;

             XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug
                                                    ,FALSE
                                                    ,gc_error_location || CHR(13) || gc_debug
                                                    );

             /* Loop through the ePDF document level Detail, Summary and One and do the batching logic */
             LOOP

                IF ln_doc_count = 1 THEN
                   lc_doc_detail_level := 'ONE';
                ELSIF ln_doc_count = 2 THEN
                   lc_doc_detail_level := 'SUMMARIZE';
                ELSIF ln_doc_count = 3 THEN
                   lc_doc_detail_level := 'DETAIL';
				ELSIF ln_doc_count = 4 THEN           --Added for SKU Level Tax, NAIT-58403
				lc_doc_detail_level := 'DETAILSKU';   --Added for SKU Level Tax, NAIT-58403
                ELSE
                   NULL;
                END IF;

                IF (p_thread_count IS NOT NULL) THEN

                   gc_error_location   := 'Get the Distinct count of valid parent cust doc id';
                   SELECT  COUNT(1)
                   INTO    ln_count
                   FROM    (SELECT DISTINCT XAECHM.parent_cust_doc_id
                                           ,XAECHM.extract_batch_id
                            FROM    xx_ar_ebl_cons_hdr_main      XAECHM
                                   ,xx_ar_ebl_file               XAEF
                            WHERE   XAECHM.billdocs_delivery_method   = p_del_meth
                            AND     XAECHM.epdf_doc_level             = lc_doc_detail_level
                            AND     XAECHM.org_id                     = ln_org_id
                            AND     XAECHM.bill_to_date               <= ld_cycle_date
                            AND     XAEF.file_id                      = XAECHM.file_id
                            AND     XAEF.status                       = lc_status
                            );

                   gc_error_location   := 'Calculate the batch size based on the thread count.';
                   IF (ln_count <> 0) THEN
                      ln_batch_size := CEIL(ln_count/p_thread_count);
                   ELSE
                      ln_batch_size := -1;
                      XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug
                                                             ,TRUE
                                                             ,'No records to process ePDF Billing for document level : '||lc_doc_detail_level
                                                             );
                   END IF;

                ELSE
                   ln_batch_size := NVL(p_batch_size,1000);
                END IF;

                IF ln_batch_size <> - 1 THEN

                   gc_error_location := 'Batching for ePDF_doc_level : ';
                   gc_debug          := lc_doc_detail_level;

                   XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug
                                                          ,FALSE
                                                          ,gc_error_location || gc_debug
                                                          );

                  /* Calculate and update batch id for the given batch size for each ePDF document level. */
                   OPEN lcu_batch_bills( lc_doc_detail_level
                                        ,lc_status
                                        ,ln_org_id
                                        ,ld_cycle_date
                                        );
                      LOOP
                         FETCH lcu_batch_bills BULK COLLECT INTO lt_batch_id LIMIT NVL(ln_batch_size,1000);
                            EXIT WHEN lt_batch_id.COUNT = 0;

                            ln_batch_id := ln_parent_req_id || '.' || LPAD (ln_batch_count, 5, '0');

                            gc_error_location := 'Updating batch id for the parent cust doc ids :';
                            gc_debug          := 'Batch ID :' || ln_batch_id || ' Parent Cust Doc ID From :' ||lt_batch_id(lt_batch_id.FIRST).parent_cust_doc_id
                                                 || ' Parent Cust Doc ID To :' || lt_batch_id(lt_batch_id.LAST).parent_cust_doc_id;
                            XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug
                                                                   ,FALSE
                                                                   ,gc_error_location || CHR(13) ||gc_debug
                                                                   );

                            FOR i IN lt_batch_id.FIRST..lt_batch_id.LAST
                            LOOP
                               SELECT COUNT(1)
                               INTO   ln_custdoc_count
                               FROM   xx_ar_ebl_cons_hdr_main   XAECHM
                                     ,xx_ar_ebl_file            XAEF
                               WHERE  XAECHM.billdocs_delivery_method   = p_del_meth
                               AND    XAECHM.org_id                     = ln_org_id
                               AND    XAECHM.file_id                    = XAEF.file_id(+)
                               AND    UPPER( NVL(XAEF.status,'XXX'))   != lc_status
                               AND    XAECHM.parent_cust_doc_id         = lt_batch_id(i).parent_cust_doc_id
                               AND    XAECHM.extract_batch_id           = lt_batch_id(i).extract_batch_id;

                               IF(ln_custdoc_count = 0) THEN
                                  gc_error_location := 'Updating batch ID and Status for the Customer Dcoument : '||lt_batch_id(i).parent_cust_doc_id
                                                        ||' for the Extract Batch ID :' || lt_batch_id(i).extract_batch_id;
                                  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug
                                                                         ,FALSE
                                                                         ,gc_error_location || CHR(13) ||gc_debug
                                                                         );
                                  UPDATE xx_ar_ebl_cons_hdr_main
                                  SET    batch_id                   = ln_batch_id
                                        ,status                     = 'MARKED_FOR_RENDER'
                                  WHERE  parent_cust_doc_id         = lt_batch_id(i).parent_cust_doc_id
                                  AND    extract_batch_id           = lt_batch_id(i).extract_batch_id
                                  AND    billdocs_delivery_method   = p_del_meth
                                  AND    epdf_doc_level             = lc_doc_detail_level
                                  AND    org_id                     = ln_org_id;

                               ELSE
                                  gc_error_location := 'Customer Document '||lt_batch_id(i).parent_cust_doc_id||' is rejected for the Extract Batch ID : '
                                                       ||lt_batch_id(i).extract_batch_id;
                                  XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug
                                                                         ,FALSE
                                                                         ,gc_error_location || CHR(13) ||gc_debug
                                                                         );
                               END IF;

                            END LOOP;

                            ln_batch_count   := ln_batch_count + 1;

                      END LOOP;
                   CLOSE lcu_batch_bills;
                   COMMIT;

                END IF;

                ln_doc_count       := ln_doc_count + 1;

                --EXIT WHEN ln_doc_count = 4;
				EXIT WHEN ln_doc_count = 5;
				--Added for SKU Level Tax, NAIT-58403

             END LOOP;

          EXCEPTION
             WHEN OTHERS THEN
                gc_debug := 'Error in ePDF Threading Logic :' || CHR(13) || gc_error_location || CHR(13) ||gc_debug;
                RAISE EX_USER_EXCEPTION;
          END;
          /* End of Batching Logic */

          gc_error_location := 'Get all the common parameters for the child thread to submit';
          gc_debug          := NULL;

          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug
                                                 ,FALSE
                                                 ,gc_error_location || CHR(13) ||gc_debug
                                                 );

          /* Get the Applied Credit Memo Verbiage. */
          BEGIN
             SELECT  SUBSTR(description,1,50)
             INTO    lc_cm_text1
             FROM    fnd_lookup_values_vl --Removed apps schema Reference
             WHERE   lookup_type        = 'OD_BILLING_CM_LINE_TEXT'
             AND     enabled_flag       = 'Y'
             AND     TRUNC(SYSDATE)     BETWEEN TRUNC(start_date_active) AND TRUNC(NVL(end_date_active,SYSDATE+1))
             AND     lookup_code        = 'TEXT1';

             SELECT  SUBSTR(description,1,50)
             INTO    lc_cm_text2
             FROM    fnd_lookup_values_vl ----Removed apps schema Reference
             WHERE   lookup_type        = 'OD_BILLING_CM_LINE_TEXT'
             AND     enabled_flag       = 'Y'
             AND     TRUNC(SYSDATE)     BETWEEN TRUNC(start_date_active) AND TRUNC(NVL(end_date_active,SYSDATE+1))
             AND     lookup_code        = 'TEXT2';
          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug
                                                       ,TRUE
                                                       ,'No data found in lookup OD_BILLING_CM_LINE_TEXT for the TEXT1 and TEXT2'
                                                       );
                lc_cm_text1 := NULL;
                lc_cm_text2 := NULL;
             WHEN OTHERS THEN
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug
                                                       ,TRUE
                                                       ,'When Others Exception : TEXT1 and TEXT2-> OD_BILLING_CM_LINE_TEXT lookup'
                                                       );
                lc_cm_text1 := NULL;
                lc_cm_text2 := NULL;
          END;

          /* Get the Gift Card Verbiage. */
          BEGIN
             SELECT  SUBSTR(description,1,50)
             INTO    lc_gift_card_text1
             FROM    fnd_lookup_values_vl  --Removed apps schema Reference
             WHERE   lookup_type        = 'OD_BILLING_TENDER_PAYMENT_TEXT'
             AND     enabled_flag       = 'Y'
             AND     TRUNC(SYSDATE)     BETWEEN TRUNC(start_date_active) AND TRUNC(NVL(end_date_active,SYSDATE+1))
             AND     lookup_code        = 'TEXT1';

             SELECT  SUBSTR(description,1,50)
             INTO    lc_gift_card_text2
             FROM    fnd_lookup_values_vl --Removed apps schema Reference
             WHERE   lookup_type        = 'OD_BILLING_TENDER_PAYMENT_TEXT'
             AND     enabled_flag       = 'Y'
             AND     TRUNC(SYSDATE)     BETWEEN TRUNC(start_date_active) AND TRUNC(NVL(end_date_active,SYSDATE+1))
             AND     lookup_code        = 'TEXT2';

             SELECT  SUBSTR(description,1,50)
             INTO    lc_gift_card_text3
             FROM    fnd_lookup_values_vl --Removed apps schema Reference
             WHERE   lookup_type        = 'OD_BILLING_TENDER_PAYMENT_TEXT'
             AND     enabled_flag       = 'Y'
             AND     TRUNC(SYSDATE)     BETWEEN TRUNC(start_date_active) AND TRUNC(NVL(end_date_active,SYSDATE+1))
             AND     lookup_code        = 'TEXT3';

          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug
                                                       ,TRUE
                                                       ,'No data found in lookup OD_BILLING_TENDER_PAYMENT_TEXT for the TEXT1, TEXT2 and TEXT3'
                                                       );
                lc_gift_card_text1 := NULL;
                lc_gift_card_text2 := NULL;
                lc_gift_card_text3 := NULL;
             WHEN OTHERS THEN
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug
                                                       ,TRUE
                                                       ,'When Others Exception : TEXT1, TEXT2 and TEXT3 -> OD_BILLING_TENDER_PAYMENT_TEXT lookup'
                                                       );
                lc_gift_card_text1 := NULL;
                lc_gift_card_text2 := NULL;
                lc_gift_card_text3 := NULL;
          END;

          gc_error_location := 'Values of all the default parameters are : ';
          gc_debug          := 'ACM Text1 :'|| lc_cm_text1 || CHR(13) || 'ACM Text2 :' || lc_cm_text2 || CHR(13) || 'Gift Card Text1 :' || lc_gift_card_text1
                                || CHR(13) || 'Gift Card Text2 :' || lc_gift_card_text2 || CHR(13) || 'Gift Card Text3 :' || lc_gift_card_text3;

          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug
                                                 ,FALSE
                                                 ,gc_error_location || CHR(13) || gc_debug
                                                 );

          BEGIN

             /* Submit appropriate Child Program for distinct batch IDs */
             FOR doc_batch_id IN lcu_batch_id (ln_org_id)
             LOOP

                IF doc_batch_id.ePDF_doc_level = 'ONE' THEN
                   lc_conc_pgm_name    := 'XXAREBLCONSONE';
                ELSIF doc_batch_id.ePDF_doc_level = 'SUMMARIZE' THEN
                   lc_conc_pgm_name    := 'XXAREBLCONSSUM';
                ELSIF doc_batch_id.ePDF_doc_level = 'DETAIL' THEN
                   lc_conc_pgm_name    := 'XXAREBLCONSDTL';
				ELSIF doc_batch_id.ePDF_doc_level = 'DETAILSKU' THEN --Added for SKU Level Tax, NAIT-58403
                   lc_conc_pgm_name    := 'XXAREBLCONSSKU';  --XXAREBLCONSDTLSKU   --Added for SKU Level Tax, NAIT-58403					
                END IF;

                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug
                                                       ,TRUE
                                                       ,'Submit The concurrent Program : ' || lc_conc_pgm_name || ' for the batch id : ' || doc_batch_id.batch_id
                                                       );

                ln_thread_count   := ln_thread_count + 1;

                ln_request_id := FND_REQUEST.SUBMIT_REQUEST ( application         => lc_appl_short_name
                                                             ,program             => lc_child_pgm_name
                                                             ,description         => NULL
                                                             ,start_time          => NULL
                                                             ,sub_request         => TRUE
                                                             ,argument1           => lc_appl_short_name
                                                             ,argument2           => lc_conc_pgm_name
                                                             ,argument3           => doc_batch_id.batch_id
                                                             ,argument4           => p_debug_flag
                                                             ,argument5           => lc_cm_text1
                                                             ,argument6           => lc_cm_text2
                                                             ,argument7           => lc_gift_card_text1
                                                             ,argument8           => lc_gift_card_text2
                                                             ,argument9           => lc_gift_card_text3
                                                             ,argument10          => p_del_meth
                                                             ,argument11          => p_doc_type
                                                             ,argument12          => p_cycle_date
                                                             );

             END LOOP;

          EXCEPTION
             WHEN OTHERS THEN
                gc_debug  := 'Error in Submitting ePDF Document Level Program';
                RAISE EX_USER_EXCEPTION;
          END;

          IF ln_thread_count > 0 THEN
             FND_CONC_GLOBAL.SET_REQ_GLOBALS(conc_status => 'PAUSED', request_data => 'COMPLETE');
          END IF;

       ELSE

          /* Check for any child program completed in Error */
          SELECT COUNT(1)
          INTO   ln_err_req_cnt
          FROM   fnd_concurrent_requests
          WHERE  parent_request_id   = ln_parent_req_id
          AND    phase_code          = 'C'
          AND    status_code         = 'E';

          /* Action taken to the main program in any of the child program completed in error. */
          IF ln_err_req_cnt <> 0 THEN
             gc_debug   := ln_err_req_cnt ||' Child Requests are Errored Out.Please, Check the Child Requests LOG for Details';
             XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                    ,TRUE
                                                    ,gc_debug
                                                    );
             x_retcode := 2;
          ELSE
             gc_debug   := 'All the Child Programs Completed Normal...';
             XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                    ,TRUE
                                                    ,gc_debug
                                                    );
          END IF;

       END IF;
	   /*Added for defect 18432 */
		FOR ren_err IN lcu_file_status
		LOOP
			ln_error_rec_count :=ln_error_rec_count+1;
			XX_AR_EBL_COMMON_UTIL_PKG.update_file_table (lc_errbuf
                                                   ,lc_retcode
                                                   ,ren_err.invoice_type 
                                                    ,''
                                                    ,''
                                                    ,ren_err.FILE_ID
                                                    ,''
                                                    ,'' );
													

		END LOOP;
		COMMIT;
		fnd_file.put_line(fnd_file.log,'ln_error_rec_count'||ln_error_rec_count);
		IF (ln_error_rec_count > 0) THEN 
		x_retcode := 2;
		END IF;
	   /*End of code Added for defect 18432 */
    EXCEPTION
       WHEN EX_USER_EXCEPTION THEN
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug
                                                 ,TRUE
                                                 ,gc_debug
                                                 );
          x_retcode := 2;

       WHEN OTHERS THEN
          gc_debug  := ' Exception raised in Multi Thread procedure '|| SQLERRM;
          XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                 ,TRUE
                                                 ,gc_debug
                                                 );
          x_retcode := 2;

    END MULTI_THREAD_EPDF;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : SUBMIT_ePDF_CHILD                                                   |
-- | Description : This Procedure is used to submit the exact ePDF pgm and the         |
-- |               bursting program.                                                   |
-- | Parameters   :                                                                    |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 14-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE SUBMIT_EPDF_CHILD ( x_error_buff                 OUT VARCHAR2
                                 ,x_retcode                    OUT NUMBER
                                 ,p_appl_name                  IN  VARCHAR2
                                 ,p_conc_name                  IN  VARCHAR2
                                 ,p_batch_id                   IN  NUMBER
                                 ,p_debug_flag                 IN  VARCHAR2
                                 ,p_cm_text1                   IN  VARCHAR2
                                 ,p_cm_text2                   IN  VARCHAR2
                                 ,p_gift_card_text1            IN  VARCHAR2
                                 ,p_gift_card_text2            IN  VARCHAR2
                                 ,p_gift_card_text3            IN  VARCHAR2
                                 ,p_del_meth                   IN  VARCHAR2
                                 ,p_doc_type                   IN  VARCHAR2
                                 ,p_cycle_date                 IN  VARCHAR2
                                 )
    AS

       CURSOR lcu_file_name
       IS
       SELECT DISTINCT SUBSTR( file_name
                              ,1,INSTR(file_name,'.PDF',1)-1
                              )||'_'||file_id||'.PDF'           bill_file_name
             ,file_id                                           bill_file_id
             ,transmission_id                                   bill_trans_id
       FROM   xx_ar_ebl_cons_hdr_main
       WHERE  batch_id                     = p_batch_id
       AND    status                       = 'MARKED_FOR_RENDER';

       lc_request_data        VARCHAR2(25);

       lb_debug               BOOLEAN;
       lc_burst_path          xx_fin_translatevalues.target_value1%TYPE;
       lc_font_path           xx_fin_translatevalues.target_value1%TYPE;
       lc_cons_opath          xx_fin_translatevalues.target_value1%TYPE;

       ln_ePDF_req_id         NUMBER;
       ln_burst_req_id        NUMBER;

       ln_blob_err_cnt        NUMBER       := 0;
       ln_blob_err            NUMBER       := 0;

       lc_appl_name           VARCHAR2(5)     := 'XXFIN';
       lc_file_type           VARCHAR2(5)     := 'PDF';
       lc_burst_java_name     VARCHAR2(15)    := 'XXARXMLCOMBURST';
       lc_burst_file          VARCHAR2(25)    := 'XXAREBLCONSEPDFBURST.xml';
       lc_rtf_type            VARCHAR2(5)     := 'rtf';
       lc_ofile_name          VARCHAR2(10)    := 'FILE_NAME';

       lc_update_flag         VARCHAR2(1)     := 'N';
       ln_error               NUMBER          := 0 ;
       lc_output_path         dba_directories.directory_path%TYPE;


    BEGIN

       lc_request_data        := FND_CONC_GLOBAL.REQUEST_DATA;

       IF p_debug_flag = 'Y' THEN
          lb_debug  := TRUE;
       ELSE
          lb_debug  := FALSE;
       END IF;

       IF lc_request_data IS NULL THEN

          gc_error_location := 'Submitting the ePDF Program for batch ID : '||p_batch_id||' and concurrent pgm : '||p_conc_name;
          ln_ePDF_req_id := FND_REQUEST.SUBMIT_REQUEST ( application         => p_appl_name
                                                        ,program             => p_conc_name
                                                        ,description         => NULL
                                                        ,start_time          => NULL
                                                        ,sub_request         => TRUE
                                                        ,argument1           => p_appl_name
                                                        ,argument2           => p_conc_name
                                                        ,argument3           => p_batch_id
                                                        ,argument4           => p_debug_flag
                                                        ,argument5           => p_cm_text1
                                                        ,argument6           => p_cm_text2
                                                        ,argument7           => p_gift_card_text1
                                                        ,argument8           => p_gift_card_text2
                                                        ,argument9           => p_gift_card_text3
                                                        );

          fnd_conc_global.set_req_globals(conc_status => 'PAUSED', request_data => TO_CHAR(ln_ePDF_req_id)||'-ePDF');

       ELSIF (SUBSTR(lc_request_data,INSTR(lc_request_data,'-')+1) = 'ePDF') THEN

          SELECT COUNT(1)
          INTO   ln_error
          FROM   fnd_concurrent_requests
          WHERE  request_id          = SUBSTR(lc_request_data,1,INSTR(lc_request_data,'-')-1)
          AND    phase_code          = 'C'
          AND    status_code         = 'E';

          IF ln_error = 0 THEN

             gc_error_location   := 'Getting the Burst Path for Bursting Prgoram';
             XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                    ,FALSE
                                                    ,gc_error_location
                                                    );

             SELECT XFTV.TARGET_value1
             INTO   lc_burst_path
             FROM   xx_fin_translatedefinition XFTD    --Removed xxfin schema Reference
                   ,xx_fin_translatevalues     XFTV    --Removed xxfin schema Reference
             WHERE  XFTD.translate_id       = XFTV.translate_id
             AND    XFTD.translation_name   = 'XX_EBL_COMMON_TRANS'
             AND    XFTV.source_value1      = 'BPATH'
             AND    SYSDATE                 BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
             AND    SYSDATE                 BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
             AND    XFTV.enabled_flag       = 'Y'
             AND    XFTD.enabled_flag       = 'Y';

             gc_error_location   := 'Getting the font Path for Bursting Prgoram';
             XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                    ,FALSE
                                                    ,gc_error_location
                                                    );

             SELECT XFTV.TARGET_value1
             INTO   lc_font_path
             FROM   xx_fin_translatedefinition XFTD  --Removed xxfin schema Reference
                   ,xx_fin_translatevalues     XFTV  --Removed xxfin schema Reference
             WHERE  XFTD.translate_id       = XFTV.translate_id
             AND    XFTD.translation_name   = 'XX_EBL_COMMON_TRANS'
             AND    XFTV.source_value1      = 'FPATH'
             AND    SYSDATE                 BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
             AND    SYSDATE                 BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
             AND    XFTV.enabled_flag       = 'Y'
             AND    XFTD.enabled_flag       = 'Y';

             -- below select added for defect 7397
             gc_error_location   := 'Getting the output file path';
             XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                    ,FALSE
                                                    ,gc_error_location
                                                    );
             SELECT directory_path
             INTO   lc_output_path
             FROM   dba_directories
             WHERE  directory_name = 'XXFIN_EBL_'||p_doc_type;

             gc_error_location   := 'Submiting the Bursting prgoram.';
             XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                    ,FALSE
                                                    ,gc_error_location
                                                    );

             ln_burst_req_id  := FND_REQUEST.SUBMIT_REQUEST ( lc_appl_name
                                                             ,lc_burst_java_name
                                                             ,NULL
                                                             ,NULL
                                                             ,TRUE
                                                             ,SUBSTR(lc_request_data,1,INSTR(lc_request_data,'-')-1)
                                                             ,lc_burst_path||'/'||lc_burst_file
                                                             ,lc_font_path
                                                             ,lc_output_path  -- Added for defct 7397
                                                             --,lc_burst_path||'/'||p_doc_type commented for defct 7397
                                                             ,lc_burst_path||'/'||p_conc_name||'.rtf'
                                                             ,LOWER(lc_file_type)
                                                             ,lc_rtf_type
                                                             ,lc_ofile_name
                                                             );

             fnd_conc_global.set_req_globals(conc_status => 'PAUSED', request_data => SUBSTR(lc_request_data,1,INSTR(lc_request_data,'-')-1));

          ELSE
             gc_error_location   := 'Error in Data Template Program';
             XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                    ,TRUE
                                                    ,gc_error_location
                                                    );
             lc_update_flag    := 'Y';
             x_retcode         := 2;
          END IF;

       ELSE

          SELECT COUNT(1)
          INTO   ln_error
          FROM   fnd_concurrent_requests
          WHERE  parent_request_id   = fnd_global.conc_request_id
          AND    phase_code          = 'C'
          AND    status_code         = 'E';

          IF ln_error = 0 THEN

             gc_error_location   := 'Getting the Individual Output Path for Bursting Prgoram';
             XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                    ,FALSE
                                                    ,gc_error_location
                                                    );

             SELECT XFTV.TARGET_value1
             INTO   lc_cons_opath
             FROM   xx_fin_translatedefinition XFTD     --Removed xxfin schema Reference
                   ,xx_fin_translatevalues     XFTV     --Removed xxfin schema Reference
             WHERE  XFTD.translate_id       = XFTV.translate_id
             AND    XFTD.translation_name   = 'XX_EBL_COMMON_TRANS'
             AND    XFTV.source_value1      = 'CONS_OPATH'
             AND    SYSDATE                 BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
             AND    SYSDATE                 BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
             AND    XFTV.enabled_flag       = 'Y'
             AND    XFTD.enabled_flag       = 'Y';

             gc_error_location := 'Updating xx_ar_ebl_file table for batch ID : '||p_batch_id||' and concurrent pgm : '||p_conc_name||
                                  ' and request ID : '||ln_ePDF_req_id;
             FOR file_name IN lcu_file_name
             LOOP

                XX_AR_EBL_COMMON_UTIL_PKG.insert_blob_file ( lc_cons_opath
                                                            ,file_name.bill_file_name
                                                            ,lc_file_type
                                                            ,file_name.bill_trans_id
                                                            ,file_name.bill_file_id
                                                            ,p_debug_flag
                                                            ,ln_blob_err
                                                            );

                ln_blob_err_cnt := ln_blob_err_cnt + ln_blob_err;
                IF ln_blob_err > 0 THEN
                   XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                          ,TRUE
                                                          ,'File '||file_name.bill_file_name||' is not updated in the xx_ar_ebl_file table'
                                                          );

                   UPDATE xx_ar_ebl_cons_hdr_main   XAECHM
                   SET    status             = 'File '||file_name.bill_file_name||' is not updated in the xx_ar_ebl_file table'
                         ,request_id         = fnd_global.conc_request_id
                         ,last_updated_by    = fnd_global.user_id
                         ,last_updated_date  = SYSDATE
                         ,last_updated_login = fnd_global.user_id
                   WHERE  file_id            = file_name.bill_file_id
                   AND    transmission_id    = file_name.bill_trans_id
                   AND    batch_id           = p_batch_id;

                END IF;
             END LOOP;

             gc_error_location := 'Calling common function for updting standard table and deleting custom table for batch ID : '||p_batch_id;
             XX_AR_EBL_COMMON_UTIL_PKG.update_bill_status( p_batch_id
                                                          ,p_doc_type
                                                          ,p_del_meth
                                                          ,lc_request_data
                                                          ,p_debug_flag
                                                          );

          ELSE

             XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                    ,TRUE
                                                    ,'Error While : ' || gc_error_location
                                                    );
             lc_update_flag    := 'Y';
             x_retcode         := 2;

          END IF;

          IF ln_blob_err_cnt > 0 THEN
             XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                    ,TRUE
                                                    ,'Some of the files are not updated into the xx_ar_ebl_file table'
                                                    );

             IF x_retcode IS NULL THEN
                x_retcode := 1;
             END IF;

          END IF;

       END IF;

       IF lc_update_flag = 'Y' THEN

          UPDATE xx_ar_ebl_file   XAEF
          SET    status_detail      = 'Error Location : '||gc_error_location
                ,status             = 'RENDER_ERROR'
                ,last_updated_by    = fnd_global.user_id
                ,last_update_date   = SYSDATE
                ,last_update_login  = fnd_global.user_id
          WHERE  EXISTS            (SELECT file_id
                                    FROM   xx_ar_ebl_cons_hdr_main
                                    WHERE  batch_id           = p_batch_id
                                    AND    file_id            = XAEF.file_id
                                    );

          UPDATE xx_ar_ebl_cons_hdr_main   XAECHM
          SET    status             = 'Error Location : '||gc_error_location
                ,request_id         = fnd_global.conc_request_id
                ,last_updated_by    = fnd_global.user_id
                ,last_updated_date  = SYSDATE
                ,last_updated_login = fnd_global.user_id
          WHERE  batch_id           = p_batch_id;

          COMMIT;

       END IF;

    EXCEPTION
    WHEN OTHERS THEN

       ROLLBACK;

       gc_error_location := 'ERROR in SUBMIT_ePDF_CHILD. Error While :'||gc_error_location||CHR(13)||' SQLERRM : '||SQLERRM;

       XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                              ,TRUE
                                              ,gc_error_location
                                              );

       UPDATE xx_ar_ebl_file   XAEF
       SET    status_detail      = 'Error Location : '||gc_error_location
             ,status             = 'RENDER_ERROR'
             ,last_updated_by    = fnd_global.user_id
             ,last_update_date   = sysdate
             ,last_update_login  = fnd_global.user_id
       WHERE  EXISTS            (SELECT file_id
                                 FROM   xx_ar_ebl_cons_hdr_main
                                 WHERE  batch_id           = p_batch_id
                                 AND    file_id            = XAEF.file_id
                                 );

       UPDATE xx_ar_ebl_cons_hdr_main   XAECHM
       SET    status             = 'Error Location : '||gc_error_location
             ,request_id         = fnd_global.conc_request_id
             ,last_updated_by    = fnd_global.user_id
             ,last_updated_date  = sysdate
             ,last_updated_login = fnd_global.user_id
       WHERE  batch_id           = p_batch_id;

       DELETE xx_ar_ebl_cons_trx_hist
       WHERE  request_id    = p_batch_id;

       DELETE xx_ar_ebl_cons_lines_hist
       WHERE  request_id    = p_batch_id;

       DELETE xx_ar_ebl_cons_trx_total_hist
       WHERE  request_id    = p_batch_id;

       DELETE xx_ar_ebl_cons_trx_rows_hist
       WHERE  request_id    = p_batch_id;

       COMMIT;

       x_retcode := 2;
    END SUBMIT_EPDF_CHILD;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : BEFOREREPORT                                                        |
-- | Description : This function is used to insert records into the custom tables      |
-- |               according to the document level.                                    |
-- | Parameters  :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 16-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- |1.1       08-DEC-2015  Havish Kasina           Added 3 new fields dept_code,       |
-- |                                               dept_desc and dept_sft_hdr fields   |
-- |                                               Defect 36437 (MOD4B Release 3)      |
-- |1.2       03-JUN-2016  Havish Kasina           Added new field kit_sku for Kitting |
-- |                                               changes (Defect 37675)              |
-- +===================================================================================+
    FUNCTION BEFOREREPORT
    RETURN BOOLEAN
    AS

       CURSOR lcu_cons_bill
       IS
       SELECT  DISTINCT cons_inv_id      CONS_INV_ID
              ,parent_cust_doc_id        PARENT_CUST_DOC_ID
              ,cust_doc_id               CUST_DOC_ID
              ,bill_to_site_use_id       SITE_USE_ID
              ,ePDF_doc_level
              ,consolidated_bill_number  CONS_INV_NUM
              ,infocopy_tag
              ,oracle_account_number     BILLING_ID
       FROM    xx_ar_ebl_cons_hdr_main
       WHERE   batch_id                  = p_batch_id;
       /*AND     p_spl_handling_flag     = 'Y'
       UNION ALL
       SELECT cons_inv_id                CONS_IV_ID
             ,parent_cust_doc_id         CUST_DOC_ID
             ,bill_to_site_use_id        SITE_USE_ID
             ,ePDF_doc_level
             ,consolidated_bill_number   CONS_INV_NUM
             ,infocopy_tag
             ,oracle_account_number      BILLING_ID
       FROM   xx_ar_ebl_cons_hdr_hist
       WHERE  p_spl_handling_flag      = 'N'
       AND    consolidated_bill_number = NVL(p_cons_bill_num,consolidated_bill_number)
       AND    cust_account_id          = NVL(p_cust_account_id,cust_account_id)
       AND    bill_from_date           BETWEEN NVL(p_date_from,bill_from_date) AND NVL(p_date_to,bill_from_date)
       --AND    Multiple bills
       AND    ((p_cust_doc_id          IS NULL AND infocopy_tag = 'PAYDOC')
                OR p_cust_doc_id       = cust_doc_id);*/-- Needs to be verified

       CURSOR lcu_trx_lines ( p_customer_trx_id IN NUMBER
                             ,p_cust_doc_id     IN NUMBER
                             )
       IS
       SELECT inventory_item_number                    ITEM_CODE
             ,translated_description                   CUST_PROD_CODE
             ,item_description                         ITEM_NAME
             ,vendor_product_code                      MANUF_CODE
             ,NVL(quantity_invoiced,quantity_credited) QTY
             ,unit_of_measure                          UOM
             ,unit_price                               UNIT_PRICE
             ,ext_price                                EXTENDED_PRICE
             ,line_level_comment                       LINE_COMMENTS
             ,gsa_comments                             GSA_COMMENTS
			 ,dept_code                                DEPT_CODE -- Added for Defect 36437
			 ,dept_desc                                DEPT_DESC -- Added for Defect 36437
			 ,dept_sft_hdr                             DEPT_SFT_HDR -- Added for Defect 36437
			 ,kit_sku                                  KIT_SKU   -- Added for Kitting, Defect# 37675
			 ,kit_sku_desc                             KIT_SKU_DESC -- Added for Kitting, Defect# 37675
			 ,NVL(sku_level_tax,0)                     SKU_LEVEL_TAX -- Added for SKU Level Tax NAIT-58403
       FROM   xx_ar_ebl_cons_dtl_main
       WHERE  customer_trx_id          =  p_customer_trx_id
       AND    cust_doc_id              =  p_cust_doc_id
	   ORDER BY trx_line_number; -- Changed done for defect#39707
       /*AND    p_spl_handling_flag      = 'Y'
       UNION ALL
       SELECT inventory_item_number                    ITEM_CODE
             ,translated_description                   CUST_PROD_CODE
             ,'Item Name'                              ITEM_NAME
             ,vendor_procuct_code                      MANUF_CODE
             ,NVL(quantity_invoiced,quantity_credited) QTY
             ,unit_of_measure                          UOM
             ,unit_price                               UNIT_PRICE
             ,ext_price                                EXTENDED_PRICE
             ,line_level_comment                       LINE_COMMENTS
       FROM   xx_ar_ebl_cons_dtl_hist
       WHERE  customer_trx_id          =  p_customer_trx_id
       AND    cust_doc_id              =  p_cust_doc_id
       AND    'Item Name'              <> 'Tiered Discount' -- Confirm with Ranjith
       AND    p_spl_handling_flag      = 'N'; -- Confirm with Ranjith*/

       CURSOR lcu_misc_crmemo ( p_trx_id          IN NUMBER
                               ,p_cust_doc_id     IN NUMBER
                               )
       IS
       SELECT  2                    data_type
              ,'MISC CR MEMO'       item_name
              ,(XAECHM.sku_lines_subtotal
                + XAECHM.total_coupon_amount
                + XAECHM.total_bulk_amount
                + XAECHM.total_freight_amount
                + XAECHM.total_miscellaneous_amount
                + XAECHM.total_association_discount
                + XAECHM.total_tiered_discount_amount
                )                  extended_price
       FROM   xx_ar_ebl_cons_hdr_main   XAECHM
       WHERE  XAECHM.customer_trx_id    = p_trx_id
       AND    XAECHM.cust_doc_id        = p_cust_doc_id
       UNION ALL
       SELECT  1                             data_type
              ,'Tax'                         item_name
              ,(XAECHM.total_us_tax_amount
                + XAECHM.total_gst_amount
                + XAECHM.total_pst_amount
                + XAECHM.total_qst_amount
                )
       FROM   xx_ar_ebl_cons_hdr_main   XAECHM
       WHERE  XAECHM.customer_trx_id    = p_trx_id
       AND    XAECHM.cust_doc_id        = p_cust_doc_id
       ORDER BY data_type;

       CURSOR lcu_trx_sum ( p_cons_inv_id  IN NUMBER
                           ,p_cust_doc_id  IN NUMBER
                           ,p_site_use_id  IN NUMBER
                           ,p_doc_type     IN VARCHAR2
                           )
       IS
       SELECT customer_trx_id                  TRX_ID
             ,inv_number                       INVOICE_NUM
             ,TO_CHAR(order_date ,'DD-MON-YY') ORDER_DATE
             ,sfdata1
             ,sfdata2
             ,sfdata3
             ,sfdata4
             ,sfdata5
             ,NVL(subtotal_amount ,0)          SUBTOTAL
             ,NVL(delivery_charges ,0)         DELIVERY
             ,NVL(promo_and_disc ,0)           DISCOUNTS
             ,NVL(tax_amount ,0)               US_TAX_AMT
             ,NVL(cad_county_tax_amount,0)     CA_COUNTY_TAX_AMT
             ,NVL(cad_state_tax_amount,0)      CA_STATE_TAX_AMT
             ,(NVL(subtotal_amount ,0)
               + NVL(delivery_charges ,0)
               + NVL(promo_and_disc ,0)
               )                               ORDER_TOTAL
             ,insert_seq                       INSERT_SEQ
       FROM  xx_ar_ebl_cons_trx_stg
       WHERE request_id            = p_batch_id
       AND   cons_inv_id           = p_cons_inv_id
       AND   cust_doc_id           = p_cust_doc_id
       AND   doc_type              = p_doc_type
       AND   bill_to_site_use_id   = p_site_use_id
       AND   inv_type              NOT IN ('SOFTHDR_TOTALS' ,'BILLTO_TOTALS' ,'GRAND_TOTAL')
       ORDER BY insert_seq;

       CURSOR get_softheader_totals( p_cbi_id             IN NUMBER
                                    ,p_cust_doc_id        IN NUMBER
                                    ,p_trx_id             IN NUMBER
                                    ,p_site_use_id        IN NUMBER
                                    )
       IS
       SELECT  sumz.insert_seq
              ,'TOTAL FOR '||sumz.inv_source_name               summarize_text
              ,DECODE( sumz.order_header_id
                      ,1
                      ,TO_CHAR(sumz.order_header_id)||' ORDER'
                      ,TO_CHAR(sumz.order_header_id)||' ORDERS'
                      )                                         total_orders
              ,NVL(sumz.tax_code ,'N')                          pg_break
              ,sumz.subtotal_amount                             summarize_subtotal
              ,sumz.delivery_charges                            summarize_delivery
              ,sumz.promo_and_disc                              summarize_discounts
              ,sumz.tax_amount                                  summarize_tax
              ,( sumz.subtotal_amount
                +sumz.delivery_charges
                +sumz.promo_and_disc
                +sumz.tax_amount
                )                                               summarize_total
       FROM  xx_ar_ebl_cons_trx_stg sumz
       WHERE request_id              = p_batch_id
       AND   cons_inv_id             = p_cbi_id
       AND   cust_doc_id             = p_cust_doc_id
       AND   customer_trx_id         = p_trx_id
       AND   bill_to_site_use_id     = p_site_use_id
       AND   inv_type                = 'SOFTHDR_TOTALS'
       UNION ALL
       SELECT  sumz.insert_seq
              ,'TOTAL FOR '||sumz.inv_source_name               summarize_text
              ,DECODE( sumz.order_header_id
                      ,1,TO_CHAR(sumz.order_header_id)||' ORDER'
                      ,TO_CHAR(sumz.order_header_id)||' ORDERS'
                      )                                         total_orders
              ,NVL(sumz.tax_code ,'N')                          pg_break
              ,sumz.subtotal_amount  summarize_subtotal
              ,sumz.delivery_charges summarize_delivery
              ,sumz.promo_and_disc   summarize_discounts
              ,sumz.tax_amount       summarize_tax
              ,( sumz.subtotal_amount
                + sumz.delivery_charges
                + sumz.promo_and_disc
                + sumz.tax_amount
               )                                                summarize_total
       FROM  xx_ar_ebl_cons_trx_stg sumz
       WHERE request_id              = p_batch_id
       AND   cons_inv_id             = p_cbi_id
       AND   cust_doc_id             = p_cust_doc_id
       AND   customer_trx_id         = p_trx_id
       AND   bill_to_site_use_id     = p_site_use_id
       AND   inv_type                = 'BILLTO_TOTALS'
       UNION ALL
       SELECT  sumz.insert_seq                                  insert_seq
              ,'GRAND TOTAL :'                                  summarize_text
              ,DECODE( sumz.order_header_id
                      ,1,TO_CHAR(sumz.order_header_id)||' ORDER'
                      ,TO_CHAR(sumz.order_header_id)||' ORDERS'
                     )                                          total_orders
              ,NVL(sumz.tax_code ,'N')                          pg_break
              ,TO_NUMBER(NULL)                                  summarize_subtotal
              ,TO_NUMBER(NULL)                                  summarize_delivery
              ,TO_NUMBER(NULL)                                  summarize_discounts
              ,TO_NUMBER(NULL)                                  summarize_tax
              ,sumz.subtotal_amount                             summarize_total
       FROM  xx_ar_ebl_cons_trx_stg sumz
       WHERE request_id              = p_batch_id
       AND   cons_inv_id             = p_cbi_id
       AND   cust_doc_id             = p_cust_doc_id
       AND   customer_trx_id         = p_trx_id
       AND   bill_to_site_use_id     = p_site_use_id
       AND   inv_type                = 'GRAND_TOTAL'
       ORDER BY insert_seq;

       CURSOR get_softheader_ONE_totals ( p_cbi_id      IN NUMBER
                                         ,p_cust_doc_id IN NUMBER
                                         ,p_site_use_id IN NUMBER
                                         )
       IS
       SELECT  sumz.insert_seq
              ,'TOTAL FOR '||sumz.inv_source_name              summarize_text
              ,DECODE( sumz.order_header_id
                      ,1
                      ,TO_CHAR(sumz.order_header_id)||' ORDER'
                      ,TO_CHAR(sumz.order_header_id)||' ORDERS'
                     )                                         total_orders
              ,NVL(sumz.tax_code ,'N')                         pg_break
              ,sumz.subtotal_amount                            summarize_subtotal
              ,sumz.delivery_charges                           summarize_delivery
              ,sumz.promo_and_disc                             summarize_discounts
              ,sumz.tax_amount                                 summarize_tax
              ,( sumz.subtotal_amount
                + sumz.delivery_charges
                + sumz.promo_and_disc
                + sumz.tax_amount
                )                                              summarize_total
       FROM  xx_ar_ebl_cons_trx_stg sumz
       WHERE request_id              = p_batch_id
       AND   cons_inv_id             = p_cbi_id
       AND   cust_doc_id             = p_cust_doc_id
       AND   bill_to_site_use_id     = p_site_use_id
       AND   inv_type                = 'SOFTHDR_TOTALS'
       UNION ALL
       SELECT sumz.insert_seq
             ,'TOTAL FOR '||sumz.inv_source_name              summarize_text
             ,DECODE( sumz.order_header_id
                     ,1,TO_CHAR(sumz.order_header_id)||' ORDER'
                     ,TO_CHAR(sumz.order_header_id)||' ORDERS'
                    )                                         total_orders
             ,NVL(sumz.tax_code ,'N')                         pg_break
             ,sumz.subtotal_amount                            summarize_subtotal
             ,sumz.delivery_charges                           summarize_delivery
             ,sumz.promo_and_disc                             summarize_discounts
             ,sumz.tax_amount                                 summarize_tax
             ,( sumz.subtotal_amount
               + sumz.delivery_charges
               + sumz.promo_and_disc
               + sumz.tax_amount
              )                                              summarize_total
       FROM  xx_ar_ebl_cons_trx_stg sumz
       WHERE request_id              = p_batch_id
       AND   cons_inv_id             = p_cbi_id
       AND   cust_doc_id             = p_cust_doc_id
       AND   bill_to_site_use_id     = p_site_use_id
       AND   inv_type                = 'BILLTO_TOTALS'
       UNION ALL
       SELECT sumz.insert_seq                                  insert_seq
             ,'GRAND TOTAL:'                                   summarize_text
             ,DECODE( sumz.order_header_id
                     ,1
                     ,TO_CHAR(sumz.order_header_id)||' ORDER'
                     ,TO_CHAR(sumz.order_header_id)||' ORDERS'
                    )                                          total_orders
             ,NVL(sumz.tax_code ,'N')                          pg_break
             ,TO_NUMBER(NULL)                                  summarize_subtotal
             ,TO_NUMBER(NULL)                                  summarize_delivery
             ,TO_NUMBER(NULL)                                  summarize_discounts
             ,TO_NUMBER(NULL)                                  summarize_tax
             ,sumz.subtotal_amount                             summarize_total
       FROM  xx_ar_ebl_cons_trx_stg sumz
       WHERE request_id              = p_batch_id
       AND   cons_inv_id             = p_cbi_id
       AND   cust_doc_id             = p_cust_doc_id
       AND   bill_to_site_use_id     = p_site_use_id
       AND   inv_type                = 'GRAND_TOTAL'
       ORDER BY insert_seq;

       lc_description fnd_territories_vl.territory_short_name%TYPE;

       sql_stmnt                VARCHAR2(32000) := TO_CHAR(NULL);
       orderby_stmnt            VARCHAR2(8000)  := TO_CHAR(NULL);
       ln_total_gst_amount      NUMBER;
       ln_total_pst_amount      NUMBER;
       ln_total_qst_amount      NUMBER;
       ln_total_us_tax_amount   NUMBER;
       lc_sort                  xx_cdh_mbs_document_master.doc_sort_order%TYPE;
       lc_sort_by               xx_cdh_mbs_document_master.doc_sort_order%TYPE;
       lc_total_by              xx_cdh_mbs_document_master.doc_sort_order%TYPE;
       lc_page_by               xx_cdh_mbs_document_master.doc_sort_order%TYPE;

       TYPE trx_csr_type        IS REF CURSOR;
       lcu_trx                  trx_csr_type;
       trx_row                  trx_rec;

       lc_us_tax_code           VARCHAR2(10);
       lc_gst_tax_code          VARCHAR2(10);
       lc_prov_tax_code         VARCHAR2(10);

       lc_line_comments_sub     VARCHAR2(35)                                 := NULL;
       lc_line_comments_final   VARCHAR2(300)                                := NULL;
       ln_line_comments         NUMBER                                       := 0;
       ln_count                 NUMBER                                       := 0;

       lc_gift_card             VARCHAR2(15);
       ln_tax_amount            NUMBER;
       ln_trx_amount            NUMBER;
       lc_line_type             VARCHAR2(20);

       lc_bill_to_address       VARCHAR2(500);
       lc_remit_address         VARCHAR2(500);

       lb_debug                 BOOLEAN;

    BEGIN

       IF p_debug_flag = 'Y' THEN
          lb_debug := TRUE;
       ELSE
          lb_debug := FALSE;
       END IF;

       gc_error_location     := 'Before Entering the Main Cursor : lcu_cons_bill' ;
       FOR cons_bill IN lcu_cons_bill
       LOOP

          gc_error_location  := 'Get the document level infomarion for the Parent Cust Doc ID';
          gc_debug           := 'Parent Doc ID :' || cons_bill.cust_doc_id
                                ||CHR(10)||'Cons Inv ID :' || cons_bill.cons_inv_id
                                ||CHR(10)||'Site Use ID :' || cons_bill.site_use_id;
          BEGIN
          

             SELECT XCMDM.doc_sort_order
                   ,SUBSTR( XCMDM.doc_sort_order
                           ,1,INSTR(XCMDM.doc_sort_order ,XCMDM.total_through_field_id)
                           )||'1'
                   ,SUBSTR( XCMDM.doc_sort_order
                           ,1,INSTR(XCMDM.doc_sort_order ,XCMDM.page_break_through_id)
                           )||'1'
             INTO  lc_sort
                  ,lc_total_by
                  ,lc_page_by
             FROM  xx_cdh_mbs_document_master XCMDM
                  ,xx_ar_ebl_cons_hdr_main    XAECHM
             WHERE XCMDM.document_id                 = XAECHM.mbs_doc_id
             AND   XAECHM.cons_inv_id                = cons_bill.cons_inv_id
             AND   XAECHM.parent_cust_doc_id         = cons_bill.parent_cust_doc_id
             AND   XAECHM.cust_doc_id                = cons_bill.cust_doc_id
             AND   XAECHM.bill_to_site_use_id        = cons_bill.site_use_id
             AND   XAECHM.batch_id                   = p_batch_id
             AND   ROWNUM                            < 2;

             SELECT NVL2(REPLACE(lc_sort ,'B1' ,'') ,REPLACE(lc_sort ,'B1' ,'') ,'S1U1D1R1L1')
             INTO   lc_sort_by
             FROM   dual;

          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20000, 'Error in fetching template, sort ,total and page break details');
             WHEN OTHERS THEN
                RAISE_APPLICATION_ERROR(-20000, 'Error in fetching template, sort ,total and page break details');
          END;

          gc_error_location  := 'Frame the Dynamic Select clause for the particular cons_inv_id - GET_DYNAMIC_SQL';
          sql_stmnt     := GET_DYNAMIC_SQL( lc_sort_by
                                           ,'XAECH'
                                           ,'Y'--p_spl_handling_flag
                                           );

          gc_error_location  := 'Frame the Dynamic Order By clause for the particular cons_inv_id - GET_ORDER_BY_SQL';
          orderby_stmnt := GET_ORDER_BY_SQL( lc_sort_by
                                            ,'XAECH'
					    ,lc_sort
                                            );

          gc_error_location  := 'Concatenate the Select Clause and the Order By Clause';
          sql_stmnt     := sql_stmnt||orderby_stmnt;

          XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                 ,FALSE
                                                 ,'Dyanmic SQL ' || CHR(13) || sql_stmnt
                                                 );

          BEGIN

             gc_error_location  := 'Open the Cursor for the Dynamic SQL framed';
             OPEN lcu_trx FOR sql_stmnt USING cons_bill.cons_inv_id
                                             ,cons_bill.parent_cust_doc_id
                                             ,cons_bill.cust_doc_id
                                             ,cons_bill.site_use_id
                                             ,p_batch_id;
             LOOP
                FETCH lcu_trx INTO trx_row;
                EXIT WHEN lcu_trx%NOTFOUND;

                IF trx_row.bill_to_country = 'CA' THEN
                
                   BEGIN
                      SELECT UPPER(territory_short_name)
                      INTO   lc_description
                      FROM   fnd_territories_vl
                      WHERE  territory_code = trx_row.bill_to_country;

                   EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                         lc_description := trx_row.bill_to_country;
                   END;

                   IF lc_description IS NULL THEN
                      lc_description := trx_row.bill_to_country;
                   END IF;

                ELSE
                   lc_description := '';
                END IF;

                gc_error_location  := 'Calculate the Bill To Address Details for the cons bill';
                lc_bill_to_address := XX_AR_EBL_COMMON_UTIL_PKG.GET_CONCAT_ADDR( trx_row.bill_to_address1
                                                                                ,trx_row.bill_to_address2
                                                                                ,trx_row.bill_to_address3
                                                                                ,trx_row.bill_to_address4
                                                                                ,trx_row.bill_to_city
                                                                                ,trx_row.bill_to_state
                                                                                ,trx_row.bill_to_zip
                                                                                ,lc_description
                                                                                );

                gc_error_location  := 'Calculate the Remit To Address Details for the Cons bill';
                lc_remit_address   :=  XX_AR_EBL_COMMON_UTIL_PKG.GET_CONCAT_ADDR( trx_row.remit_address1
                                                                                 ,trx_row.remit_address2
                                                                                 ,trx_row.remit_address3
                                                                                 ,trx_row.remit_address4
                                                                                 ,trx_row.remit_city
                                                                                 ,trx_row.remit_state
                                                                                 ,trx_row.remit_zip
                                                                                 ,trx_row.remit_country
                                                                                 );

                gc_error_location  := 'Get the Tax amount for the cons bill';
                SELECT total_gst_amount
                      ,total_pst_amount
                      ,total_qst_amount
                      ,total_us_tax_amount
                      ,DECODE( trx_row.bill_to_country
                              ,'US','SALES TAX'
                              ,NULL
                              )
                      ,DECODE( trx_row.bill_to_country
                              ,'CA','GST / HST'
                              ,NULL
                              )
                      ,DECODE( trx_row.bill_to_country
                              ,'CA',DECODE( trx_row.bill_to_state
                                           ,'QC','QST'
                                           ,'PQ','QST'
                                           ,'PST'
                                           )
                              ,NULL
                              )
                INTO   ln_total_gst_amount
                      ,ln_total_pst_amount
                      ,ln_total_qst_amount
                      ,ln_total_us_tax_amount
                      ,lc_us_tax_code
                      ,lc_gst_tax_code
                      ,lc_prov_tax_code
                FROM   xx_ar_ebl_cons_hdr_main
                WHERE  cons_inv_id           = cons_bill.cons_inv_id
                AND    parent_cust_doc_id    = cons_bill.parent_cust_doc_id
                AND    cust_doc_id           = cons_bill.cust_doc_id
                AND    customer_trx_id       = trx_row.customer_trx_id
                AND    batch_id              = p_batch_id;
                
                gc_error_location  := 'Insert Data into trx staging table for the cons bill';
                INSERT_TRANSACTIONS ( trx_row.sfdata1
                                     ,trx_row.sfdata2
                                     ,trx_row.sfdata3
                                     ,trx_row.sfdata4
                                     ,trx_row.sfdata5
                                     ,trx_row.sfdata6
                                     ,trx_row.sfhdr1||' :'
                                     ,trx_row.sfhdr2||' :'
                                     ,trx_row.sfhdr3||' :'
                                     ,trx_row.sfhdr4||' :'
                                     ,trx_row.sfhdr5||' :'
                                     ,trx_row.sfhdr6
                                     ,trx_row.customer_trx_id
                                     ,trx_row.order_header_id
                                     --,trx_row.inv_source_id
                                     ,trx_row.inv_number
                                     ,trx_row.inv_type
                                     ,trx_row.inv_source
                                     ,trx_row.order_date
                                     ,trx_row.ship_date
                                     ,cons_bill.cons_inv_id
                                     ,cons_bill.cust_doc_id
                                     ,p_batch_id
                                     ,trx_row.order_subtotal
                                     ,trx_row.delvy_charges
                                     ,trx_row.order_discount
                                     ,ln_total_us_tax_amount
                                     ,ln_total_gst_amount
                                     ,(ln_total_pst_amount + ln_total_qst_amount)
                                     ,lc_us_tax_code
                                     ,lc_gst_tax_code
                                     ,lc_prov_tax_code
                                     ,GET_TRX_SEQ()
                                     ,cons_bill.infocopy_tag
                                     ,cons_bill.cons_inv_num
                                     ,cons_bill.site_use_id   -- Final Bill to site_use_id
                                     ,lc_bill_to_address
                                     ,lc_remit_address
                                     );

                -- Insert SPC card info
                gc_error_location  := 'Insert SPC Info into trx lines staging table';
                IF trx_row.spc_comment IS NOT NULL THEN
                   INSERT_TRX_LINES ( p_batch_id
                                     ,cons_bill.cons_inv_id
                                     ,cons_bill.cust_doc_id
                                     ,trx_row.customer_trx_id
                                     ,GET_TRX_SEQ()
                                     ,'SPC_CARD_INFO'
                                     ,NULL
                                     ,trx_row.spc_comment
                                     ,NULL
                                     ,NULL
                                     ,NULL
                                     ,NULL
                                     ,NULL
                                     ,NULL
                                     ,cons_bill.site_use_id
                                     ,NULL
									 ,NULL -- Added for the Defect 36437
									 ,NULL -- Added for the Defect 36437
									 ,NULL -- Added for the Defect 36437
									 ,NULL -- Added for Kitting, Defect# 37675
									 ,NULL -- Added for Kitting, Defect# 37675
									 ,NULL -- Added for SKU Level Tax NAIT-58403
                                     );
                END IF;

                -- Insert trx lines info
                gc_error_location  := 'Insert trx lines info into trx lines staging table';
                FOR trx_lines IN lcu_trx_lines ( trx_row.customer_trx_id
                                                ,cons_bill.cust_doc_id
                                                )
                LOOP
                   ln_line_comments       := NVL(CEIL(LENGTH(trx_lines.line_comments)/35),0);
                   lc_line_comments_final := NULL;

                   IF ln_line_comments > 0 THEN
                   
                      FOR i IN 1..ln_line_comments
                      LOOP
                         ln_count := (35*(i-1)) + 1;
                         lc_line_comments_sub := SUBSTR(trx_lines.line_comments,ln_count,35);

                         IF i = 1 THEN
                            lc_line_comments_final := lc_line_comments_final||lc_line_comments_sub;
                         ELSE
                            lc_line_comments_final := lc_line_comments_final||CHR(13)||lc_line_comments_sub;
                         END IF;

                      END LOOP;

                   END IF;

                   INSERT_TRX_LINES ( p_batch_id
                                     ,cons_bill.cons_inv_id
                                     ,cons_bill.cust_doc_id
                                     ,trx_row.customer_trx_id
                                     ,GET_TRX_SEQ()
                                     ,trx_lines.item_code
                                     ,trx_lines.cust_prod_code
                                     ,trx_lines.item_name
                                     ,trx_lines.manuf_code
                                     ,trx_lines.qty
                                     ,trx_lines.uom
                                     ,trx_lines.unit_price
                                     ,trx_lines.extended_price
                                     ,lc_line_comments_final
                                     ,cons_bill.site_use_id
                                     ,trx_lines.gsa_comments
									 ,trx_lines.dept_code -- Added for the Defect 36437
									 ,trx_lines.dept_desc -- Added for the Defect 36437
									 ,trx_lines.dept_sft_hdr -- Added for the Defect 36437
									 ,trx_lines.kit_sku   -- Added for Kitting, Defect# 37675
									 ,trx_lines.kit_sku_desc   -- Added for Kitting, Defect# 37675
									 ,trx_lines.sku_level_tax  -- Added for SKU Level Tax NAIT-58403
                                     );
                END LOOP;

                -- Insert TD
                gc_error_location  := 'Insert TD Info into trx lines staging table';
                IF trx_row.td_amount <> 0 THEN
                   INSERT_TRX_LINES ( p_batch_id
                                     ,cons_bill.cons_inv_id
                                     ,cons_bill.cust_doc_id
                                     ,trx_row.customer_trx_id
                                     ,GET_TRX_SEQ()
                                     ,'TD'
                                     ,NULL
                                     ,NULL
                                     ,NULL
                                     ,NULL
                                     ,NULL
                                     ,NULL
                                     ,trx_row.td_amount
                                     ,NULL
                                     ,cons_bill.site_use_id
                                     ,NULL
									 ,NULL -- Added for the Defect 36437
									 ,NULL -- Added for the Defect 36437
									 ,NULL -- Added for the Defect 36437
									 ,NULL -- Added for Kitting, Defect# 37675
									 ,NULL -- Added for Kitting, Defect# 37675
									 ,NULL -- Added for SKU Level Tax NAIT-58403
                                     );
                END IF;

                -- Insert ACM
                gc_error_location  := 'Insert ACM Info into trx lines staging table';
                IF trx_row.original_order_number IS NOT NULL THEN
                
                   INSERT_TRX_LINES ( p_batch_id
                                     ,cons_bill.cons_inv_id
                                     ,cons_bill.cust_doc_id
                                     ,trx_row.customer_trx_id
                                     ,GET_TRX_SEQ()
                                     ,'ACM'
                                     ,trx_row.original_order_number
                                     ,NULL
                                     ,NULL
                                     ,NULL
                                     ,NULL
                                     ,NULL
                                     ,trx_row.original_invoice_amount
                                     ,NULL
                                     ,cons_bill.site_use_id
                                     ,NULL
									 ,NULL -- Added for the Defect 36437
									 ,NULL -- Added for the Defect 36437
									 ,NULL -- Added for the Defect 36437
									 ,NULL -- Added for Kitting, Defect# 37675
									 ,NULL -- Added for Kitting, Defect# 37675
									 ,NULL -- Added for SKU Level Tax NAIT-58403
                                     );
                                     
                END IF; 
                -- Insert Gift Card Info
                gc_error_location  := 'Insert Gift Card Info into trx lines staging table';
                IF trx_row.gift_amount <> 0 THEN
                
                   IF trx_row.inv_type = 'Invoice' THEN
                      lc_gift_card := 'GIFT_CARD_INV';
                   ELSIF trx_row.inv_type = 'Credit Memo' THEN
                      lc_gift_card := 'GIFT_CARD_CM';
                   END IF;
                   
                   INSERT_TRX_LINES ( p_batch_id
                                     ,cons_bill.cons_inv_id
                                     ,cons_bill.cust_doc_id
                                     ,trx_row.customer_trx_id
                                     ,GET_TRX_SEQ()
                                     ,lc_gift_card
                                     ,trx_row.inv_number
                                     ,NULL
                                     ,NULL
                                     ,NULL
                                     ,NULL
                                     ,NULL
                                     ,trx_row.gift_amount
                                     ,NULL
                                     ,cons_bill.site_use_id
                                     ,NULL
									 ,NULL -- Added for the Defect 36437
									 ,NULL -- Added for the Defect 36437
									 ,NULL -- Added for the Defect 36437
									 ,NULL -- Added for Kitting, Defect# 37675
									 ,NULL -- Added for Kitting, Defect# 37675
									 ,NULL -- Added for SKU Level Tax NAIT-58403
                                     );
                END IF;
                
                -- Insert Miscellaneous credit Memo
                IF trx_row.inv_type = 'Credit Memo' AND trx_row.inv_source IN ('MANUAL_CA' ,'MANUAL_US' ,'SERVICE') THEN
                
                   FOR misc_crmemo IN lcu_misc_crmemo ( trx_row.customer_trx_id
                                                       ,cons_bill.cust_doc_id
                                                       )
                   LOOP
                        INSERT_TRX_LINES ( p_batch_id
                                        ,cons_bill.cons_inv_id
                                        ,cons_bill.cust_doc_id
                                        ,trx_row.customer_trx_id
                                        ,GET_TRX_SEQ()
                                        ,NULL
                                        ,NULL
                                        ,misc_crmemo.item_name
                                        ,NULL
                                        ,NULL
                                        ,NULL
                                        ,NULL
                                        ,NULL
                                        ,misc_crmemo.extended_price
                                        ,cons_bill.site_use_id
                                        ,NULL
										,NULL -- Added for the Defect 36437
										,NULL -- Added for the Defect 36437
										,NULL -- Added for the Defect 36437
										,NULL -- Added for Kitting, Defect# 37675
										,NULL -- Added for Kitting, Defect# 37675
										,NULL -- Added for SKU Level Tax NAIT-58403
                                        );
                   END LOOP;
                END IF;
             END LOOP;
             CLOSE lcu_trx;

                gc_error_location  := 'Call Sub-Totals package according to the document Level';
                IF cons_bill.ePDF_doc_level = 'DETAIL' THEN

                   gc_error_location  := 'Inside Detail Document Level Validation and Insert data into trx_subtotals staging table';
                   GENERATE_DETAIL_SUBTOTALS ( cons_bill.billing_id
                                              ,cons_bill.cons_inv_id
                                              ,cons_bill.cust_doc_id
                                              ,cons_bill.site_use_id
                                              ,p_batch_id
                                              ,lc_total_by
                                              ,lc_page_by
                                              ,cons_bill.infocopy_tag
                                              );

                ELSE

                -- Call Summ_one_subtotals
                   gc_error_location  := 'Insert Summary and One Document Level Validation and insert data into trx staging table';
                   GENERATE_SUMM_ONE_SUBTOTALS ( cons_bill.billing_id
                                                ,cons_bill.cons_inv_id
                                                ,cons_bill.cust_doc_id
                                                ,cons_bill.site_use_id
                                                ,p_batch_id
                                                ,lc_total_by
                                                ,lc_page_by
                                                ,cons_bill.infocopy_tag
                                                );

                   IF cons_bill.ePDF_doc_level = 'SUMMARIZE' THEN

                      gc_error_location  := 'Open lcu_trx_sum cursor to get the data for summary document level';
                      FOR trx_sum IN lcu_trx_sum ( cons_bill.cons_inv_id
                                                  ,cons_bill.cust_doc_id
                                                  ,cons_bill.site_use_id
                                                  ,cons_bill.infocopy_tag
                                                  )
                      LOOP

                         gc_error_location  := 'Calculate tax amount';
                         IF xx_fin_country_defaults_pkg.f_org_id('CA') = FND_PROFILE.VALUE('ORG_ID') THEN

                            ln_tax_amount := trx_sum.ca_state_tax_amt + trx_sum.ca_county_tax_amt;
                            ln_trx_amount := trx_sum.order_total + ln_tax_amount;

                         ELSIF xx_fin_country_defaults_pkg.f_org_id('US') = FND_PROFILE.VALUE('ORG_ID') THEN

                            ln_tax_amount := trx_sum.us_tax_amt;
                            ln_trx_amount := trx_sum.order_total + ln_tax_amount;

                         END IF;

                         gc_error_location  := 'Insert trx level info into trx row staging table';
                         INSERT_TRX_ROWS ( p_batch_id
                                          ,cons_bill.cons_inv_id
                                          ,cons_bill.cust_doc_id
                                          ,'TRX_REC'
                                          ,GET_ROWS_SEQ()
                                          ,NULL
                                          ,'N'
                                          ,RPAD(trx_sum.invoice_num ,15 ,' ')
                                          ,RPAD(trx_sum.order_date ,9 ,' ')
                                          ,trx_sum.subtotal
                                          ,trx_sum.delivery
                                          ,trx_sum.discounts
                                          ,ln_tax_amount
                                          ,ln_trx_amount
                                          ,trx_sum.sfdata1
                                          ,trx_sum.sfdata2
                                          ,trx_sum.sfdata3
                                          ,trx_sum.sfdata4
                                          ,trx_sum.sfdata5
                                          ,trx_sum.trx_id
                                          ,cons_bill.site_use_id
                                          );

                         gc_error_location  := 'Insert SOC Info into trx row staging table';
                         FOR spc_rec IN (SELECT item_description spc_card_details
                                         FROM   xx_ar_ebl_cons_lines_stg XAECLS
                                         WHERE  XAECLS.request_id      = p_batch_id
                                         AND    XAECLS.cons_inv_id     = cons_bill.cons_inv_id
                                         AND    XAECLS.cust_doc_id     = cons_bill.cust_doc_id
                                         AND    XAECLS.customer_trx_id = trx_sum.trx_id
                                         AND    XAECLS.item_code       = 'SPC_CARD_INFO'
                                         )
                         LOOP
                            INSERT_TRX_ROWS ( p_batch_id
                                             ,cons_bill.cons_inv_id
                                             ,cons_bill.cust_doc_id
                                             ,'SPC_REC'
                                             ,GET_ROWS_SEQ()
                                             ,RPAD(' ' ,8 ,' ')||spc_rec.spc_card_details||RPAD(' ' ,8 ,' ')
                                             ,'N'
                                             ,NULL
                                             ,NULL
                                             ,NULL
                                             ,NULL
                                             ,NULL
                                             ,NULL
                                             ,NULL
                                             ,NULL
                                             ,NULL
                                             ,NULL
                                             ,NULL
                                             ,NULL
                                             ,trx_sum.trx_id
                                             ,cons_bill.site_use_id
                                             );
                         END LOOP;

                         gc_error_location  := 'Insert TD Info into trx row staging table';
                         FOR td_rec IN (SELECT extended_price td_amount
                                         FROM   xx_ar_ebl_cons_lines_stg XAECLS
                                         WHERE  XAECLS.request_id      = p_batch_id
                                         AND    XAECLS.cons_inv_id     = cons_bill.cons_inv_id
                                         AND    XAECLS.cust_doc_id     = cons_bill.cust_doc_id
                                         AND    XAECLS.customer_trx_id = trx_sum.trx_id
                                         AND    XAECLS.item_code       = 'TD'
                                         )
                         LOOP

                            INSERT_TRX_ROWS ( p_batch_id
                                             ,cons_bill.cons_inv_id
                                             ,cons_bill.cust_doc_id
                                             ,'TD_REC'
                                             ,GET_ROWS_SEQ()
                                             ,RPAD(' ' ,8 ,' ')
                                               ||'Note: A Discount of '
                                               ||RPAD(NVL(TO_CHAR(td_rec.td_amount ,'9G999D99') ,' ') ,11 ,' ')
                                               ||' has been applied to your order.'
                                               ||RPAD(' ' ,8 ,' ')
                                             ,'N'
                                             ,NULL
                                             ,NULL
                                             ,NULL
                                             ,NULL
                                             ,NULL
                                             ,NULL
                                             ,NULL
                                             ,NULL
                                             ,NULL
                                             ,NULL
                                             ,NULL
                                             ,NULL
                                             ,trx_sum.trx_id
                                             ,cons_bill.site_use_id
                                             );
                         END LOOP;

                         gc_error_location  := 'Open the Soft Header totals cusrsor for the cons bill and the cust doc ID combination';
                         FOR subtotal_records IN get_softheader_totals( cons_bill.cons_inv_id
                                                                       ,cons_bill.cust_doc_id
                                                                       ,trx_sum.trx_id
                                                                       ,cons_bill.site_use_id
                                                                       )
                         LOOP
                            IF TRIM(subtotal_records.summarize_text) LIKE 'GRAND TOTAL%' THEN
                               lc_line_type :='GRAND_TOTAL';
                            ELSIF TRIM(subtotal_records.summarize_text) LIKE 'TOTAL FOR BILL%' THEN
                               lc_line_type :='BILL_TO_TOTAL';
                            ELSE
                               lc_line_type :='SOFTHDR_TOTAL';
                            END IF;

                            gc_error_location  := 'Insert softheader totals info into trx row staging table';
                            INSERT_TRX_ROWS ( p_batch_id
                                             ,cons_bill.cons_inv_id
                                             ,cons_bill.cust_doc_id
                                             ,lc_line_type
                                             ,GET_ROWS_SEQ()
                                             ,subtotal_records.summarize_text
                                             ,subtotal_records.pg_break
                                             ,RPAD(subtotal_records.total_orders ,27 ,' ')
                                             ,NULL
                                             ,NVL(subtotal_records.summarize_subtotal ,0)
                                             ,NVL(subtotal_records.summarize_delivery ,0)
                                             ,NVL(subtotal_records.summarize_discounts ,0)
                                             ,NVL(subtotal_records.summarize_tax ,0)
                                             ,NVL(subtotal_records.summarize_total ,0)
                                             ,NULL
                                             ,NULL
                                             ,NULL
                                             ,NULL
                                             ,NULL
                                             ,trx_sum.trx_id
                                             ,cons_bill.site_use_id
                                             );

                         END LOOP;

                      END LOOP;

                   ELSIF cons_bill.ePDF_doc_level = 'ONE' THEN

                      gc_error_location  := 'Open the Cursor for One Document Level';
                      FOR subtotal_records IN get_softheader_ONE_totals ( cons_bill.cons_inv_id
                                                                         ,cons_bill.cust_doc_id
                                                                         ,cons_bill.site_use_id
                                                                         )
                      LOOP
                         IF TRIM(subtotal_records.summarize_text) LIKE 'GRAND TOTAL%' THEN
                            lc_line_type :='GRAND_TOTAL';
                         ELSIF TRIM(subtotal_records.summarize_text) LIKE 'TOTAL FOR BILL%' THEN
                            lc_line_type :='BILL_TO_TOTAL';
                         ELSE
                            lc_line_type :='SOFTHDR_TOTAL';
                         END IF;

                         gc_error_location  := 'Insert data into trx row staging table for the Cons bill and cust doc id combination';
                         INSERT_TRX_ROWS ( p_batch_id
                                          ,cons_bill.cons_inv_id
                                          ,cons_bill.cust_doc_id
                                          ,lc_line_type
                                          ,GET_ROWS_SEQ()
                                          ,RPAD(' ' ,20 ,' ')||RPAD(subtotal_records.summarize_text ,50 ,' ')
                                          ,subtotal_records.pg_break
                                          ,RPAD(subtotal_records.total_orders ,27 ,' ')
                                          ,NULL
                                          ,NVL(subtotal_records.summarize_subtotal ,0)
                                          ,NVL(subtotal_records.summarize_delivery ,0)
                                          ,NVL(subtotal_records.summarize_discounts ,0)
                                          ,NVL(subtotal_records.summarize_tax ,0)
                                          ,NVL(subtotal_records.summarize_total ,0)
                                          ,NULL
                                          ,NULL
                                          ,NULL
                                          ,NULL
                                          ,NULL
                                          ,NULL
                                          ,cons_bill.site_use_id
                                          );

                      END LOOP;

                   END IF;

                END IF;
          END;
       END LOOP;

       RETURN TRUE;

    EXCEPTION
       WHEN OTHERS THEN

          XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                 ,TRUE
                                                 ,'Error While: ' || gc_error_location||' '|| SQLERRM
                                                 );
          XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                 ,TRUE
                                                 ,CHR(13)||'Debug:' || gc_debug
                                                 );
          RETURN FALSE;

    END BEFOREREPORT;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : GET_DYNAMIC_SQL                                                     |
-- | Description : This function is used to get the dynamic sql for the consolidated   |
-- |               bill numnber.                                                       |
-- | Parameters  :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 16-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- |      1.1 08-DEC-2015  Havish Kasina           Changes added for the Defect 36437  |
-- |                                               ()MOD 4B Release 3)                 |
-- +===================================================================================+

    FUNCTION GET_DYNAMIC_SQL( p_sort_order            IN VARCHAR2
                             ,p_master_alias          IN VARCHAR2
                             ,p_spl_handling_flag     IN VARCHAR2
                             )
    RETURN VARCHAR2
    AS

       lc_sql_by           VARCHAR2(32000);
       lc_prefix           VARCHAR2(32000);

       TYPE lv_sort_arr    IS VARRAY(80) OF VARCHAR2(32000);
       lv_sort_units       lv_sort_arr      := lv_sort_arr();

       lb_go_fwd           BOOLEAN          := TRUE;

       ln_sort_idx         NUMBER           := 0;
       sfdata_seq          NUMBER           := 1;
       ln_counter          NUMBER           := 1;

       ln_sort_idx1        NUMBER           := 0;
       sfdata_seq1         NUMBER           := 0;
       ln_counter1         NUMBER           := 1;

       p_def_sort          VARCHAR2(20)     := 'S1U1D1R1L1';
       lc_enter            VARCHAR2(1)      := '
';

       lc_ship_hdr         VARCHAR2(20)     := ''''||'SHIP TO ID'||'''';
       lc_cust_hdr         VARCHAR2(20)     := ''''||'Customer :'||'''';

       lc_blank_fields     VARCHAR2(32000);

       lc_remaining_select VARCHAR2(32000)  := ' ,XAECH.customer_trx_id
 ,XAECH.order_header_id
 ,XAECH.invoice_number                 INV_NUMBER
 ,XAECH.transaction_class              INV_TYPE
 ,XAECH.transaction_source             INV_SOURCE
 ,XAECH.order_date
 ,XAECH.order_source_code              ORDER_TYPE_CODE
 ,XAECH.reconcile_date                 SHIP_DATE
 ,XAECH.original_order_number
 ,XAECH.original_invoice_amount
 ,XAECH.order_level_spc_comment        SPC_COMMENT
 ,XAECH.total_gift_card_amount         GIFT_AMOUNT
 ,(XAECH.total_tiered_discount_amount
   + XAECH.total_association_discount) TD_AMOUNT
 ,XAECH.bill_to_address1
 ,XAECH.bill_to_address2
 ,XAECH.bill_to_address3
 ,XAECH.bill_to_address4
 ,XAECH.bill_to_state
 ,XAECH.bill_to_city
 ,XAECH.bill_to_zip
 ,XAECH.bill_to_country
 ,XAECH.remit_address1
 ,XAECH.remit_address2
 ,XAECH.remit_address3
 ,XAECH.remit_address4
 ,XAECH.remit_state
 ,XAECH.remit_city
 ,XAECH.remit_zip
 ,XAECH.remit_country
 ,(XAECH.sku_lines_subtotal
   + XAECH.total_coupon_amount
   + XAECH.total_bulk_amount
   + XAECH.total_freight_amount
   ) ORDER_SUBTOTAL
 ,XAECH.total_freight_amount     ORDER_DELVY
 ,(
  + XAECH.total_miscellaneous_amount
  + XAECH.total_association_discount
  + XAECH.total_tiered_discount_amount
  - XAECH.total_gift_card_amount
  )                               ORDER_DISC
 ,(XAECH.total_us_tax_amount
  + XAECH.total_gst_amount
  + XAECH.total_pst_amount
  + XAECH.total_qst_amount
  )                               ORDER_TAX';

       lc_from_clause      VARCHAR2(50);
       lc_where_clause     VARCHAR2(250)    := 'WHERE XAECH.cons_inv_id         = :cons_inv_id
 AND   XAECH.parent_cust_doc_id  = :parent_cust_doc_id
 AND   XAECH.cust_doc_id         = :cust_doc_id
 AND   XAECH.bill_to_site_use_id = :site_use_id
 AND   XAECH.batch_id            = :batch_id';

       gc_error_location   VARCHAR2(2000);
       gc_debug            VARCHAR2(1000);

    BEGIN
       lv_sort_units.EXTEND;

       gc_error_location := 'Check for Special Handling Flag';

       IF p_spl_handling_flag = 'Y' THEN
          lc_from_clause := 'FROM  xx_ar_ebl_cons_hdr_main      XAECH';
       ELSE
          lc_from_clause := 'FROM  xx_ar_ebl_cons_hdr_hist      XAECH';
       END IF;

      gc_error_location := 'Before While Loop to get the sort data';
       -- The below loop is used to get the soft header data for the sort order parameter passed.
       WHILE (lb_go_fwd)
       LOOP

          gc_error_location := 'Inside While Loop to get the soft data';

          IF ln_counter = 1 THEN
             lc_prefix := 'SELECT '||lc_enter||'  ';
          ELSE
             lc_prefix := lc_enter||' ,';
          END IF;

          ln_sort_idx := ln_sort_idx + 1;

          SELECT
          CASE
             WHEN SUBSTR(p_sort_order, ln_counter ,2)='B1' THEN lc_prefix||p_master_alias||'.oracle_account_number SFDATA'||sfdata_seq
             WHEN SUBSTR(p_sort_order, ln_counter ,2)='L1' THEN lc_prefix||p_master_alias||'.desktop_sft_data SFDATA'||sfdata_seq
             WHEN SUBSTR(p_sort_order, ln_counter ,2)='U1' THEN lc_prefix||p_master_alias||'.po_number_sft_data SFDATA'||sfdata_seq
             WHEN SUBSTR(p_sort_order, ln_counter ,2)='D1' THEN lc_prefix||p_master_alias||'.cost_center_sft_data||DECODE(rtrim(ltrim(dept_desc)),null,null,'' - ''||dept_desc) SFDATA'||sfdata_seq
             WHEN SUBSTR(p_sort_order, ln_counter ,2)='R1' THEN lc_prefix||p_master_alias||'.release_number_sft_data SFDATA'||sfdata_seq
             WHEN SUBSTR(p_sort_order, ln_counter ,2)='S1' THEN lc_prefix||p_master_alias||'.ship_to_abbreviation SFDATA'||sfdata_seq
          END CASE
          INTO lv_sort_units(ln_sort_idx)
          FROM DUAL;

          lv_sort_units.EXTEND;

          sfdata_seq := sfdata_seq + 1;
          ln_counter := ln_counter + 2;

          IF ln_counter > 11 THEN
             lb_go_fwd := FALSE;
          EXIT;
          END IF;

       END LOOP;

       lc_sql_by := lv_sort_units(1)
                    || lv_sort_units(2)
                    || lv_sort_units(3)
                    || lv_sort_units(4)
                    || lv_sort_units(5)
                    || lv_sort_units(6);

       gc_error_location := 'Get Sort data for the remaining soft header values other than the sort by value';

       IF (LENGTH(p_sort_order)/2) <5 THEN
          ln_counter := 1;
          FOR posn IN 1..(LENGTH(p_sort_order)/2)
          LOOP
             p_def_sort  := REPLACE(p_def_sort ,SUBSTR(p_sort_order ,ln_counter ,2) ,'');
             ln_counter  := ln_counter + 2;
          END LOOP;

          sfdata_seq1  := (LENGTH(p_sort_order)/2)+1;
          ln_counter1  := 1;

          <<outer_loop1>>
          FOR rec IN 1..(LENGTH(p_def_sort)/2)
          LOOP
             IF SUBSTR(p_def_sort ,ln_counter1 ,2) = 'S1' THEN
                IF outer_loop1.rec = 1 THEN
                   lc_blank_fields := lc_sql_by||lc_enter||' ,'||p_master_alias||'.ship_to_abbreviation SFDATA'||sfdata_seq1;
                ELSE
                   lc_blank_fields := lc_blank_fields||lc_enter||' ,'||p_master_alias||'.ship_to_abbreviation SFDATA'||sfdata_seq1;
                END IF;
             ELSIF SUBSTR(p_def_sort ,ln_counter1 ,2) = 'U1' THEN
                IF outer_loop1.rec = 1 THEN
                   lc_blank_fields := lc_sql_by||lc_enter||' ,'||p_master_alias||'.po_number_sft_data SFDATA'||sfdata_seq1;
                ELSE
                   lc_blank_fields := lc_blank_fields||lc_enter||' ,'||p_master_alias||'.po_number_sft_data SFDATA'||sfdata_seq1;
                END IF;
             ELSIF SUBSTR(p_def_sort ,ln_counter1 ,2) = 'D1' THEN
                IF outer_loop1.rec =1 THEN
                   lc_blank_fields := lc_sql_by||lc_enter||' ,'||p_master_alias||'.cost_center_sft_data||DECODE(rtrim(ltrim(dept_desc)),null,null,'' - ''||dept_desc) SFDATA'||sfdata_seq1;
                ELSE
                   lc_blank_fields := lc_blank_fields||lc_enter||' ,'||p_master_alias||'.cost_center_sft_data||DECODE(rtrim(ltrim(dept_desc)),null,null,'' - ''||dept_desc) SFDATA'||sfdata_seq1;
                END IF;
             ELSIF SUBSTR(p_def_sort ,ln_counter1 ,2) = 'R1' THEN
                IF outer_loop1.rec =1 THEN
                   lc_blank_fields := lc_sql_by||lc_enter||' ,'||p_master_alias||'.release_number_sft_data SFDATA'||sfdata_seq1;
                ELSE
                   lc_blank_fields := lc_blank_fields||lc_enter||' ,'||p_master_alias||'.release_number_sft_data SFDATA'||sfdata_seq1;
                END IF;
             ELSIF SUBSTR(p_def_sort ,ln_counter1 ,2) = 'L1' THEN
                IF outer_loop1.rec = 1 THEN
                   lc_blank_fields := lc_sql_by||lc_enter||' ,'||p_master_alias||'.desktop_sft_data SFDATA'||sfdata_seq1;
                ELSE
                   lc_blank_fields := lc_blank_fields||lc_enter||' ,'||p_master_alias||'.desktop_sft_data SFDATA'||sfdata_seq1;
                END IF;
             END IF;
              sfdata_seq1 := sfdata_seq1 + 1;
              ln_counter1 := ln_counter1 + 2;
          END LOOP;

       ELSE
          lc_blank_fields := lc_sql_by;
       END IF;

       lc_sql_by := lc_blank_fields||lc_enter||',TO_CHAR(NULL) SFDATA6';

       gc_error_location := 'Before While Loop to get the soft hdeader data';

       lb_go_fwd  := TRUE;
       ln_counter := 1;
       sfdata_seq := 1;
       lv_sort_units.EXTEND;
       WHILE (lb_go_fwd)
       LOOP
          IF ln_counter = 1 THEN
             lc_prefix := lc_sql_by||lc_enter||' ,';
          ELSE
             lc_prefix := lc_enter||' ,';
          END IF;
          ln_sort_idx := ln_sort_idx +1;
          SELECT
          CASE
             WHEN SUBSTR(p_sort_order, ln_counter ,2)='B1' THEN lc_prefix||lc_cust_hdr||' SFHDR'||sfdata_seq
             WHEN SUBSTR(p_sort_order, ln_counter ,2)='L1' THEN lc_prefix||p_master_alias||'.desktop_sft_hdr'||' SFHDR'||sfdata_seq
             WHEN SUBSTR(p_sort_order, ln_counter ,2)='U1' THEN lc_prefix||p_master_alias||'.po_number_sft_hdr'||' SFHDR'||sfdata_seq
             WHEN SUBSTR(p_sort_order, ln_counter ,2)='D1' THEN lc_prefix||p_master_alias||'.cost_center_sft_hdr'||' SFHDR'||sfdata_seq
             WHEN SUBSTR(p_sort_order, ln_counter ,2)='R1' THEN lc_prefix||p_master_alias||'.release_number_sft_hdr'||' SFHDR'||sfdata_seq
             WHEN SUBSTR(p_sort_order, ln_counter ,2)='S1' THEN lc_prefix||lc_ship_hdr||' SFHDR'||sfdata_seq
          END CASE
          INTO lv_sort_units(ln_sort_idx)
          FROM DUAL;

          lv_sort_units.EXTEND;

          sfdata_seq := sfdata_seq + 1;
          ln_counter := ln_counter + 2;

          IF ln_counter > 11 THEN
             lb_go_fwd := FALSE;
          EXIT;
          END IF;

       END LOOP;
       lc_sql_by := lv_sort_units(7)
                    || lv_sort_units(8)
                    || lv_sort_units(9)
                    || lv_sort_units(10)
                    || lv_sort_units(11)
                    || lv_sort_units(12);

       gc_error_location := 'Get the remaining value of the soft header data ';

       IF (LENGTH(p_sort_order)/2) < 5 THEN
          ln_counter := 1;
          FOR posn IN 1..(LENGTH(p_sort_order)/2)
          LOOP
             p_def_sort := REPLACE(p_def_sort ,substr(p_sort_order ,ln_counter ,2) ,'');
             ln_counter := ln_counter +2;
          END LOOP;
          sfdata_seq1  := (LENGTH(p_sort_order)/2)+1;
          ln_counter1  := 1;
          <<outer_loop>>
          FOR rec IN 1..(LENGTH(p_def_sort)/2)
          LOOP
             IF SUBSTR(p_def_sort ,ln_counter1 ,2) = 'S1' THEN
                IF outer_loop.rec = 1 THEN
                   lc_blank_fields := lc_sql_by||lc_enter||' ,'||lc_ship_hdr||' SFHDR'||sfdata_seq1;
                ELSE
                   lc_blank_fields := lc_blank_fields||lc_enter||' ,'||lc_ship_hdr||' SFHDR'||sfdata_seq1;
                END IF;
             ELSIF SUBSTR(p_def_sort ,ln_counter1 ,2) ='U1' THEN
                IF outer_loop.rec = 1 THEN
                   lc_blank_fields := lc_sql_by||lc_enter||' ,'||p_master_alias||'.po_number_sft_hdr'||' SFHDR'||sfdata_seq1;
                ELSE
                   lc_blank_fields :=lc_blank_fields||lc_enter||' ,'||p_master_alias||'.po_number_sft_hdr'||' SFHDR'||sfdata_seq1;
                END IF;
             ELSIF SUBSTR(p_def_sort ,ln_counter1 ,2) = 'D1' THEN
                IF outer_loop.rec = 1 THEN
                   lc_blank_fields := lc_sql_by||lc_enter||' ,'||p_master_alias||'.cost_center_sft_hdr'||' SFHDR'||sfdata_seq1;
                ELSE
                   lc_blank_fields := lc_blank_fields||lc_enter||' ,'||p_master_alias||'.cost_center_sft_hdr'||' SFHDR'||sfdata_seq1;
                END IF;
             ELSIF SUBSTR(p_def_sort ,ln_counter1 ,2) = 'R1' THEN
                IF outer_loop.rec = 1 THEN
                   lc_blank_fields := lc_sql_by||lc_enter||' ,'||p_master_alias||'.release_number_sft_hdr'||' SFHDR'||sfdata_seq1;
                ELSE
                   lc_blank_fields :=lc_blank_fields||lc_enter||' ,'||p_master_alias||'.release_number_sft_hdr'||' SFHDR'||sfdata_seq1;
                END IF;
             ELSIF SUBSTR(p_def_sort ,ln_counter1 ,2) = 'L1' THEN
                IF outer_loop.rec = 1 THEN
                   lc_blank_fields := lc_sql_by||lc_enter||' ,'||p_master_alias||'.desktop_sft_hdr'||' SFHDR'||sfdata_seq1;
                ELSE
                   lc_blank_fields := lc_blank_fields||lc_enter||' ,'||p_master_alias||'.desktop_sft_hdr'||' SFHDR'||sfdata_seq1;
                END IF;
             END IF;

             sfdata_seq1 := sfdata_seq1 + 1;
             ln_counter1 := ln_counter1 + 2;

          END LOOP;

       ELSE
          lc_blank_fields := lc_sql_by;
       END IF;

       gc_error_location := 'Return the Dynamic SQL';

       RETURN lc_blank_fields
              || lc_enter
              || ',TO_CHAR(NULL) SFHDR6'
              || lc_enter
              || lc_remaining_select
              || lc_enter
              || lc_from_clause
              || lc_enter
              || lc_where_clause
              || lc_enter;

    EXCEPTION
       WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log,gc_error_location||': SQL Error : '||SQLERRM);
          RETURN TO_CHAR(NULL);

    END GET_DYNAMIC_SQL;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : GET_ORDER_BY_SQL                                                    |
-- | Description : This function is used to get the order by clause for the dynamic    |
-- |               sql.                                                                |
-- | Parameters  :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 16-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+

    FUNCTION GET_ORDER_BY_SQL( p_sort_order   IN VARCHAR2
                              ,p_master_alias IN VARCHAR2
                              ,p_lc_sort      IN VARCHAR2 DEFAULT ''
                              )
    RETURN VARCHAR2 AS
    lc_order_by      VARCHAR2(8000) := TO_CHAR(NULL);
    lc_prefix        VARCHAR2(40)   := TO_CHAR(NULL);
    TYPE lv_sort_arr IS VARRAY(10) OF VARCHAR2(100);
    lv_sort_units    lv_sort_arr    := lv_sort_arr();
    ln_counter       NUMBER         := 1;
    lb_go_fwd        BOOLEAN        := TRUE;
    ln_sort_idx      NUMBER         := 0;
    lc_enter         VARCHAR2(1)    :='
';
    BEGIN
       lv_sort_units.EXTEND;

        IF p_lc_sort = 'B1' THEN
            lc_order_by := 'ORDER BY '||p_master_alias||'.invoice_number ,  '||p_master_alias||'.trx_number';
            RETURN lc_order_by;
        END IF;


       WHILE (lb_go_fwd)
       LOOP

          IF ln_counter = 1 THEN
             lc_prefix := 'ORDER BY '||lc_enter||'  ';
          ELSE
            lc_prefix := lc_enter||' ,';
          END IF;

             ln_sort_idx := ln_sort_idx + 1;

          SELECT
          CASE
             WHEN SUBSTR(p_sort_order, ln_counter ,2)='B1' THEN lc_prefix||p_master_alias||'.oracle_account_number NULLS FIRST'
             WHEN SUBSTR(p_sort_order, ln_counter ,2)='L1' THEN lc_prefix||p_master_alias||'.desktop_sft_data NULLS FIRST'
             WHEN SUBSTR(p_sort_order, ln_counter ,2)='U1' THEN lc_prefix||p_master_alias||'.po_number_sft_data NULLS FIRST'
             WHEN SUBSTR(p_sort_order, ln_counter ,2)='D1' THEN lc_prefix||p_master_alias||'.cost_center_sft_data NULLS FIRST'
             WHEN SUBSTR(p_sort_order, ln_counter ,2)='R1' THEN lc_prefix||p_master_alias||'.release_number_sft_data NULLS FIRST'
             WHEN SUBSTR(p_sort_order, ln_counter ,2)='S1' THEN lc_prefix||p_master_alias||'.ship_to_abbreviation NULLS FIRST'
          END CASE
          INTO lv_sort_units(ln_sort_idx)
          FROM DUAL;

          lv_sort_units.EXTEND;
          ln_counter := ln_counter + 2;

          IF ln_counter > 11 THEN
             lb_go_fwd := FALSE;
          EXIT;
          END IF;
       END LOOP;

       lc_order_by := lv_sort_units(1)
                      ||lv_sort_units(2)
                      ||lv_sort_units(3)
                      ||lv_sort_units(4)
                      ||lv_sort_units(5)
                      ||lv_sort_units(6)||lc_enter||' ,'||p_master_alias||'.invoice_number'
                                        ||lc_enter||' ,'||p_master_alias||'.trx_number';

       RETURN lc_order_by;

    EXCEPTION
       WHEN OTHERS THEN

          RETURN TO_CHAR(NULL);
    END GET_ORDER_BY_SQL;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : GENERATE_DETAIL_SUBTOTALS                                           |
-- | Description : This Procedure is used to calculate the subtotals for detail        |
-- |               document type.                                                      |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 17-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
     PROCEDURE GENERATE_DETAIL_SUBTOTALS  ( p_billing_id              IN VARCHAR2
                                           ,p_cons_id                 IN NUMBER
                                           ,p_cust_doc_id             IN NUMBER
                                           ,p_site_use_id             IN NUMBER
                                           ,p_reqs_id                 IN NUMBER
                                           ,p_total_by                IN VARCHAR2
                                           ,p_page_by                 IN VARCHAR2
                                           ,p_doc_type                IN VARCHAR2
                                           )
    AS
       TYPE US_rec_type IS RECORD( current_value   VARCHAR2(400)
                                  ,prior_value     VARCHAR2(400)
                                  ,prior_header    VARCHAR2(400)
                                  ,current_header  VARCHAR2(400)
                                  ,order_count     NUMBER
                                  ,subtotal        NUMBER
                                  ,discounts       NUMBER
                                  ,tax             NUMBER
                                  ,total_amount    NUMBER
                                  ,pg_break        VARCHAR2(1)
                                  ,site_use_id     NUMBER
                                  );

       TYPE CA_rec_type IS RECORD( current_value   VARCHAR2(400)
                                  ,prior_value     VARCHAR2(400)
                                  ,prior_header    VARCHAR2(400)
                                  ,current_header  VARCHAR2(400)
                                  ,order_count     NUMBER
                                  ,subtotal        NUMBER
                                  ,discounts       NUMBER
                                  ,prov_tax        NUMBER
                                  ,gst_tax         NUMBER
                                  ,total_amount    NUMBER
                                  ,pg_break        VARCHAR2(1)
                                  ,site_use_id     NUMBER
                                  );

       TYPE vr_US_rec_type IS TABLE OF US_rec_type
       INDEX BY BINARY_INTEGER;
       lr_records          vr_US_rec_type;

       TYPE vr_CA_rec_type IS TABLE OF CA_rec_type
       INDEX BY BINARY_INTEGER;
       lr_CA_records          vr_CA_rec_type;

       CURSOR US_cur_data
       IS
       SELECT  sfdata1
              ,sfdata2
              ,sfdata3
              ,sfdata4
              ,sfdata5
              ,sfdata6
              ,tax_code
              ,sfhdr1
              ,sfhdr2
              ,sfhdr3
              ,sfhdr4
              ,sfhdr5
              ,sfhdr6
              ,customer_trx_id trx_id
              ,inv_number
              ,NVL(subtotal_amount ,0)       subtotal_amount
              ,NVL(promo_and_disc ,0)        promo_and_disc
              ,NVL(tax_amount ,0)            tax_amount
              ,(NVL(subtotal_amount ,0)
                + NVL(promo_and_disc ,0)
                + NVL(tax_amount ,0)
                )                            amount
       FROM   xx_ar_ebl_cons_trx_stg  --Removed apps schema Reference
       WHERE  request_id                 = p_reqs_id
       AND    cons_inv_id                = p_cons_id
       AND    doc_type                   = p_doc_type
       AND    cust_doc_id                = p_cust_doc_id
       AND    bill_to_site_use_id        = p_site_use_id
       ORDER BY insert_seq;

       CURSOR B1_cur_data
       IS
       SELECT  customer_trx_id trx_id
              ,inv_number
       FROM    xx_ar_ebl_cons_trx_stg  --Removed apps schema Reference
       WHERE   request_id                = p_reqs_id
       AND     cons_inv_id               = p_cons_id
       AND     doc_type                  = p_doc_type
       AND     cust_doc_id               = p_cust_doc_id
       AND     bill_to_site_use_id       = p_site_use_id
       AND     insert_seq                = (SELECT MAX(insert_seq)
                                            FROM   xx_ar_ebl_cons_trx_stg  --Removed apps schema Reference
                                            WHERE  request_id           = p_reqs_id
                                            AND    cons_inv_id          = p_cons_id
                                            AND    doc_type             = p_doc_type
                                            AND    cust_doc_id          = p_cust_doc_id
                                            AND    bill_to_site_use_id  = p_site_use_id
                                           );

       CURSOR US_B1_totals
       IS
       SELECT NVL(SUM(subtotal_amount),0)                 subtotal_amount
             ,NVL(SUM(promo_and_disc),0)                  promo_and_disc
             ,NVL(SUM(tax_amount),0)                      tax_amount
             ,(NVL(SUM(subtotal_amount),0)
               + NVL(SUM(promo_and_disc),0)
               + NVL(SUM(tax_amount),0)
              )                                           amount
             ,COUNT(1)                                    total_orders
       FROM   xx_ar_ebl_cons_trx_stg   --Removed apps schema Reference
       WHERE  request_id               = p_reqs_id
       AND    cons_inv_id              = p_cons_id
       AND    doc_type                 = p_doc_type
       AND    cust_doc_id              = p_cust_doc_id
       AND    bill_to_Site_use_id      = p_site_use_id;

       CURSOR CA_B1_totals
       IS
       SELECT NVL(SUM(subtotal_amount) ,0)                            subtotal_amount
             ,NVL(SUM(promo_and_disc) ,0)                             promo_and_disc
             ,NVL(SUM(cad_county_tax_amount) ,0)                      cad_county_tax_amount
             ,NVL(SUM(cad_state_tax_amount) ,0)                       cad_state_tax_amount
             ,(NVL(SUM(subtotal_amount) ,0)
               + NVL(SUM(promo_and_disc) ,0)
               + NVL(SUM(cad_county_tax_amount) ,0)
               + NVL(SUM(cad_state_tax_amount) ,0)
              )                                                       amount
             ,COUNT(1)                                                total_orders
       FROM   xx_ar_ebl_cons_trx_stg   --Removed apps schema Reference
       WHERE  request_id                 = p_reqs_id
       AND    cons_inv_id                = p_cons_id
       AND    doc_type                   = p_doc_type
       AND    cust_doc_id                = p_cust_doc_id
       AND    bill_to_site_use_id        = p_site_use_id;

       CURSOR CA_cur_data
       IS
       SELECT  sfdata1
              ,sfdata2
              ,sfdata3
              ,sfdata4
              ,sfdata5
              ,sfdata6
              ,sfhdr1
              ,sfhdr2
              ,sfhdr3
              ,sfhdr4
              ,sfhdr5
              ,sfhdr6
              ,cad_county_tax_code
              ,cad_state_tax_code
              ,customer_trx_id trx_id
              ,inv_number
              ,NVL(subtotal_amount ,0)             subtotal_amount
              ,NVL(delivery_charges ,0)            delivery_charges
              ,NVL(promo_and_disc ,0)              promo_and_disc
              ,NVL(cad_county_tax_amount ,0)       cad_county_tax_amount
              ,NVL(cad_state_tax_amount ,0)        cad_state_tax_amount
              ,(NVL(subtotal_amount ,0)
                + NVL(promo_and_disc ,0)
                + NVL(cad_county_tax_amount ,0)
                + NVL(cad_state_tax_amount ,0)
               )                                   amount
       FROM   xx_ar_ebl_cons_trx_stg        --Removed apps schema Reference
       WHERE  request_id                   = p_reqs_id
       AND    cons_inv_id                  = p_cons_id
       AND    doc_type                     = p_doc_type
       AND    cust_doc_id                  = p_cust_doc_id
       AND    bill_to_site_use_id          = p_site_use_id
       ORDER BY insert_seq;

       lr_cur_rec     US_cur_data%ROWTYPE;
       lr_CA_cur_rec  CA_cur_data%ROWTYPE;

       lb_first_record             BOOLEAN      := TRUE;
       lb_B1_first_record          BOOLEAN      := TRUE;
       ln_curr_index               NUMBER;
       ln_min_changed_index        NUMBER;
       ln_grand_total              NUMBER       := 0;
       prev_inv_num                VARCHAR2(80) :=NULL;
       prev_inv_id                 NUMBER;
       last_inv_num                VARCHAR2(80) :=NULL;
       last_inv_id                 NUMBER;
       prev_ca_prov_code           VARCHAR2(80) :=NULL;
       prev_ca_state_code          VARCHAR2(80) :=NULL;
       ln_billto_subtot            NUMBER       :=0;
       ln_billto_discounts         NUMBER       :=0;
       ln_billto_tax               NUMBER       :=0;
       ln_billto_total             NUMBER       :=0;
       ln_billto_ca_prov_tax       NUMBER       :=0;
       ln_billto_ca_state_tax      NUMBER       :=0;
       ln_order_count              NUMBER       :=1;
       ln_grand_total_orders       NUMBER       :=0;
       ln_prov_tax_code            VARCHAR2(80);
       gc_error_location           VARCHAR2(2000);
       gc_debug                    VARCHAR2(1000);
       ln_number_of_sft_hdr        NUMBER       := 0;


    BEGIN

       IF p_total_by <> 'B1' THEN
          ln_number_of_sft_hdr := LENGTH(REPLACE(p_total_by, 'B1' ,''))/2;
       ELSE
          ln_number_of_sft_hdr := LENGTH(p_total_by)/2;
       END IF;

       gc_error_location := 'Before US_cur_data';
       gc_debug          := 'number of soft headers :'||ln_number_of_sft_hdr;

       IF xx_fin_country_defaults_pkg.f_org_id('US') =FND_PROFILE.VALUE('ORG_ID') THEN
          IF p_total_by <>'B1' THEN
             FOR cur_data_rec IN US_cur_data LOOP
                lr_cur_rec          := cur_data_rec;
                ln_grand_total      := NVL(ln_grand_total ,0) + NVL(cur_data_rec.amount ,0);
                ln_billto_subtot    := NVL(ln_billto_subtot ,0) + NVL(cur_data_rec.subtotal_amount ,0);
                ln_billto_discounts := NVL(ln_billto_discounts ,0) + NVL(cur_data_rec.promo_and_disc ,0);
                ln_billto_tax       := NVL(ln_billto_tax ,0) + NVL(cur_data_rec.tax_amount ,0);
                ln_billto_total     := (NVL(ln_billto_total ,0) +(NVL(cur_data_rec.subtotal_amount ,0)
                                                                  + NVL(cur_data_rec.promo_and_disc ,0)
                                                                  + NVL(cur_data_rec.tax_amount ,0)
                                                                  )
                                        );

                ln_grand_total_orders :=ln_grand_total_orders +1;

                IF lb_first_record THEN
                   lb_first_record := FALSE;
                      FOR i IN 1..ln_number_of_sft_hdr LOOP
                         ln_curr_index := (ln_number_of_sft_hdr-i)+1;
                         SELECT DECODE( ln_curr_index
                                       ,1, cur_data_rec.sfdata1
                                       ,2, cur_data_rec.sfdata2
                                       ,3, cur_data_rec.sfdata3
                                       ,4, cur_data_rec.sfdata4
                                       ,5, cur_data_rec.sfdata5
                                       ,6, cur_data_rec.sfdata6
                                        )
                         INTO    lr_records(ln_curr_index).current_value
                         FROM    dual;

                         lr_records(ln_curr_index).total_amount := cur_data_rec.amount;
                         lr_records(ln_curr_index).subtotal     := cur_data_rec.subtotal_amount;
                         lr_records(ln_curr_index).discounts    := cur_data_rec.promo_and_disc;
                         lr_records(ln_curr_index).tax          := cur_data_rec.tax_amount;
                         lr_records(ln_curr_index).order_count  := ln_order_count;

                         prev_inv_num :=cur_data_rec.inv_number;
                         prev_inv_id  :=cur_data_rec.trx_id;

                         gc_error_location := 'Getting header info';
                         gc_debug := NULL;

                         SELECT DECODE( ln_curr_index
                                       ,1, cur_data_rec.sfhdr1
                                       ,2, cur_data_rec.sfhdr2
                                       ,3, cur_data_rec.sfhdr3
                                       ,4, cur_data_rec.sfhdr4
                                       ,5, cur_data_rec.sfhdr5
                                       ,6, cur_data_rec.sfhdr6
                                       )
                         INTO    lr_records(ln_curr_index).current_header
                         FROM    dual;

                      END LOOP;
                   ELSE
                      ln_min_changed_index := 0;
                      FOR i IN 1..ln_number_of_sft_hdr LOOP
                         ln_curr_index := (ln_number_of_sft_hdr-i)+1;
                         lr_records(ln_curr_index).prior_value := lr_records(ln_curr_index).current_value;
                         lr_records(ln_curr_index).prior_header:= lr_records(ln_curr_index).current_header;

                         gc_error_location := 'Getting header data info';
                         gc_debug := NULL;

                         SELECT DECODE( ln_curr_index
                                       ,1, cur_data_rec.sfdata1
                                       ,2, cur_data_rec.sfdata2
                                       ,3, cur_data_rec.sfdata3
                                       ,4, cur_data_rec.sfdata4
                                       ,5, cur_data_rec.sfdata5
                                       ,6, cur_data_rec.sfdata6
                                       )
                         INTO    lr_records(ln_curr_index).current_value
                         FROM    dual;

                         SELECT DECODE(ln_curr_index,
                                       1, cur_data_rec.sfhdr1,
                                       2, cur_data_rec.sfhdr2,
                                       3, cur_data_rec.sfhdr3,
                                       4, cur_data_rec.sfhdr4,
                                       5, cur_data_rec.sfhdr5,
                                       6, cur_data_rec.sfhdr6
                                       )
                         INTO    lr_records(ln_curr_index).current_header
                         FROM    dual;

                         IF NVL(lr_records(ln_curr_index).current_value, '?') != NVL(lr_records(ln_curr_index).prior_value, '?') THEN
                            ln_min_changed_index := ln_curr_index;

                            IF p_page_by !='B1' THEN
                               fnd_file.put_line(fnd_file.log,'Page By:'||p_page_by);

                               IF ln_min_changed_index <= (LENGTH(REPLACE(p_page_by ,'B1' ,''))/2) THEN
                                  fnd_file.put_line(fnd_file.log,'Setting page break @ soft data:'||lr_records(ln_curr_index).current_value);
                                  lr_records(ln_curr_index).pg_break :='Y';
                               ELSE
                                  lr_records(ln_curr_index).pg_break :='';
                               END IF;

                            ELSE
                               lr_records(ln_curr_index).pg_break :='';
                            END IF;
                         END IF;

                      END LOOP;
                      FOR i IN 1..ln_number_of_sft_hdr LOOP
                         ln_curr_index := (ln_number_of_sft_hdr-i)+1;
                         IF ln_min_changed_index != 0 AND ln_min_changed_index <= ln_curr_index THEN

                         gc_error_location := 'Calling INSERT_TRX_TOTALS for SOFTHDR_SUBTOTAL - prior';
                         gc_debug          := NULL;
                         INSERT_TRX_TOTALS( p_reqs_id
                                           ,p_cons_id
                                           ,p_cust_doc_id
                                           ,prev_inv_id
                                           ,'SOFTHDR_SUBTOTAL'
                                           ,GET_TRX_SEQ()
                                           ,prev_inv_num
                                           --,RPAD(lr_records(ln_curr_index).prior_header , 20 ,' ')
                                           --||RPAD(lr_records(ln_curr_index).prior_value, 20 ,' ')  -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
                                           ,RPAD(lr_records(ln_curr_index).prior_header , 20 ,' ')
                                           ||RPAD(lr_records(ln_curr_index).prior_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                           ,lr_records(ln_curr_index).subtotal
                                           ,lr_records(ln_curr_index).pg_break
                                           ,lr_records(ln_curr_index).order_count
                                           ,NULL
                                           ,p_site_use_id
                                           );

                         gc_error_location := 'Calling INSERT_TRX_TOTALS for SOFTHDR_DISCOUNTS- prior';
                         gc_debug          := NULL;
                         INSERT_TRX_TOTALS( p_reqs_id
                                           ,p_cons_id
                                           ,p_cust_doc_id
                                           ,prev_inv_id
                                           ,'SOFTHDR_DISCOUNTS'
                                           ,GET_TRX_SEQ()
                                           ,prev_inv_num
                                           --,RPAD(lr_records(ln_curr_index).prior_header , 20 ,' ')
                                           --||RPAD(lr_records(ln_curr_index).prior_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
                                           ,RPAD(lr_records(ln_curr_index).prior_header , 20 ,' ')
                                           ||RPAD(lr_records(ln_curr_index).prior_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                           ,lr_records(ln_curr_index).discounts
                                           ,lr_records(ln_curr_index).pg_break
                                           ,lr_records(ln_curr_index).order_count
                                           ,NULL
                                           ,p_site_use_id
                                           );

                         gc_error_location := 'Calling INSERT_TRX_TOTALS for SOFTHDR_TAX- prior';
                         gc_debug          := NULL;
                         INSERT_TRX_TOTALS( p_reqs_id
                                           ,p_cons_id
                                           ,p_cust_doc_id
                                           ,prev_inv_id
                                           ,'SOFTHDR_TAX'
                                           ,GET_TRX_SEQ()
                                           ,prev_inv_num
                                           --,RPAD(lr_records(ln_curr_index).prior_header , 20 ,' ')
                                           --||RPAD(lr_records(ln_curr_index).prior_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
                                           ,RPAD(lr_records(ln_curr_index).prior_header , 20 ,' ')
                                           ||RPAD(lr_records(ln_curr_index).prior_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                           ,lr_records(ln_curr_index).tax
                                           ,lr_records(ln_curr_index).pg_break
                                           ,lr_records(ln_curr_index).order_count
                                           ,NULL
                                           ,p_site_use_id
                                           );

                         gc_error_location := 'Calling INSERT_TRX_TOTALS for SOFTHDR_TOTAL- prior';
                         gc_debug          := NULL;
                         INSERT_TRX_TOTALS( p_reqs_id
                                           ,p_cons_id
                                           ,p_cust_doc_id
                                           ,prev_inv_id
                                           ,'SOFTHDR_TOTAL'
                                           ,GET_TRX_SEQ()
                                           ,prev_inv_num
                                           --,RPAD(lr_records(ln_curr_index).prior_header , 20 ,' ')
                                           --||RPAD(lr_records(ln_curr_index).prior_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
                                           ,RPAD(lr_records(ln_curr_index).prior_header , 20 ,' ')
                                           ||RPAD(lr_records(ln_curr_index).prior_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                           ,lr_records(ln_curr_index).total_amount
                                           ,lr_records(ln_curr_index).pg_break
                                           ,lr_records(ln_curr_index).order_count
                                           ,NULL
                                           ,p_site_use_id
                                           );

                         lr_records(ln_curr_index).total_amount := cur_data_rec.amount;
                         lr_records(ln_curr_index).subtotal     := cur_data_rec.subtotal_amount;
                         lr_records(ln_curr_index).discounts    := cur_data_rec.promo_and_disc;
                         lr_records(ln_curr_index).tax          := cur_data_rec.tax_amount;
                         lr_records(ln_curr_index).order_count  := 1;
                      ELSE
                         lr_records(ln_curr_index).total_amount := cur_data_rec.amount + lr_records(ln_curr_index).total_amount;
                         lr_records(ln_curr_index).subtotal     := cur_data_rec.subtotal_amount + lr_records(ln_curr_index).subtotal;
                         lr_records(ln_curr_index).discounts    := cur_data_rec.promo_and_disc + lr_records(ln_curr_index).discounts;
                         lr_records(ln_curr_index).tax          := cur_data_rec.tax_amount + lr_records(ln_curr_index).tax;
                         lr_records(ln_curr_index).order_count  := lr_records(ln_curr_index).order_count + 1;
                      END IF;
                   END LOOP;
                   prev_inv_num := lr_cur_rec.inv_number;
                   prev_inv_id  := lr_cur_rec.trx_id;
                END IF;

                last_inv_num := lr_cur_rec.inv_number;
                last_inv_id  := lr_cur_rec.trx_id;

             END LOOP;
             FOR i IN 1..ln_number_of_sft_hdr LOOP
                ln_curr_index     := (ln_number_of_sft_hdr-i)+1;

                gc_error_location := 'Calling INSERT_TRX_TOTALS for SOFTHDR_SUBTOTAL -- current';
                gc_debug          := NULL;
                INSERT_TRX_TOTALS( p_reqs_id
                                  ,p_cons_id
                                  ,p_cust_doc_id
                                  ,prev_inv_id
                                  ,'SOFTHDR_SUBTOTAL'
                                  ,GET_TRX_SEQ()
                                  ,prev_inv_num
                                  --,RPAD(lr_records(ln_curr_index).current_header, 20 ,' ')
                                  --||RPAD(lr_records(ln_curr_index).current_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
                                  ,RPAD(lr_records(ln_curr_index).current_header, 20 ,' ')
                                  ||RPAD(lr_records(ln_curr_index).current_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                  ,lr_records(ln_curr_index).subtotal
                                  ,lr_records(ln_curr_index).pg_break
                                  ,lr_records(ln_curr_index).order_count
                                  ,NULL
                                  ,p_site_use_id
                                  );

                gc_error_location := 'Calling INSERT_TRX_TOTALS for SOFTHDR_DISCOUNTS-- current';
                gc_debug          := NULL;
                INSERT_TRX_TOTALS( p_reqs_id
                                  ,p_cons_id
                                  ,p_cust_doc_id
                                  ,prev_inv_id
                                  ,'SOFTHDR_DISCOUNTS'
                                  ,GET_TRX_SEQ()
                                  ,prev_inv_num
                                  --,RPAD(lr_records(ln_curr_index).current_header , 20 ,' ')
                                  --||RPAD(lr_records(ln_curr_index).current_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
                                  ,RPAD(lr_records(ln_curr_index).current_header , 20 ,' ')
                                  ||RPAD(lr_records(ln_curr_index).current_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                  ,lr_records(ln_curr_index).discounts
                                  ,lr_records(ln_curr_index).pg_break
                                  ,lr_records(ln_curr_index).order_count
                                  ,NULL
                                  ,p_site_use_id
                                  );

                gc_error_location := 'Calling INSERT_TRX_TOTALS for SOFTHDR_TAX-- current';
                gc_debug          := NULL;
                INSERT_TRX_TOTALS( p_reqs_id
                                  ,p_cons_id
                                  ,p_cust_doc_id
                                  ,prev_inv_id
                                  ,'SOFTHDR_TAX'
                                  ,GET_TRX_SEQ()
                                  ,prev_inv_num
                                  --,RPAD(lr_records(ln_curr_index).current_header, 20 ,' ')
                                  -- ||RPAD(lr_records(ln_curr_index).current_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
                                  ,RPAD(lr_records(ln_curr_index).current_header, 20 ,' ')
                                   ||RPAD(lr_records(ln_curr_index).current_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                  ,lr_records(ln_curr_index).tax
                                  ,lr_records(ln_curr_index).pg_break
                                  ,lr_records(ln_curr_index).order_count
                                  ,NULL
                                  ,p_site_use_id
                                  );

                gc_error_location := 'Calling INSERT_TRX_TOTALS for SOFTHDR_TOTAL-- current';
                gc_debug          := NULL;
                INSERT_TRX_TOTALS( p_reqs_id
                                  ,p_cons_id
                                  ,p_cust_doc_id
                                  ,prev_inv_id
                                  ,'SOFTHDR_TOTAL'
                                  ,GET_TRX_SEQ()
                                  ,prev_inv_num
                                  --,RPAD(lr_records(ln_curr_index).current_header, 20 ,' ')
                                  -- ||RPAD(lr_records(ln_curr_index).current_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
                                  ,RPAD(lr_records(ln_curr_index).current_header, 20 ,' ')
                                   ||RPAD(lr_records(ln_curr_index).current_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                  ,lr_records(ln_curr_index).total_amount
                                  ,lr_records(ln_curr_index).pg_break
                                  ,lr_records(ln_curr_index).order_count
                                  ,NULL
                                  ,p_site_use_id
                                  );
             END LOOP;

             gc_error_location := 'Calling INSERT_TRX_TOTALS for BILLTO_SUBTOTAL -- SUBSTR(p_total_by ,1 ,2) =B1';
             gc_debug          := NULL;
             IF SUBSTR(p_total_by ,1 ,2) ='B1' THEN

                INSERT_TRX_TOTALS( p_reqs_id
                                  ,p_cons_id
                                  ,p_cust_doc_id
                                  ,last_inv_id
                                  ,'BILLTO_SUBTOTAL'
                                  ,GET_TRX_SEQ()
                                  ,last_inv_num
                                  ,RPAD('BILL TO:', 20 ,' ')||p_billing_id
                                  ,ln_billto_subtot
                                  ,'N'
                                  ,ln_grand_total_orders
                                  ,NULL
                                  ,p_site_use_id
                                  );

                gc_error_location := 'Calling INSERT_TRX_TOTALS for BILLTO_DISCOUNTS -- SUBSTR(p_total_by ,1 ,2) =B1';    -- added for defect 11993
                gc_debug          := NULL;
                INSERT_TRX_TOTALS( p_reqs_id
                                  ,p_cons_id
                                  ,p_cust_doc_id
                                  ,last_inv_id
                                  ,'BILLTO_DISCOUNTS'
                                  ,GET_TRX_SEQ()
                                  ,last_inv_num
                                  ,RPAD('BILL TO:' ,20 ,' ')||p_billing_id
                                  ,ln_billto_discounts
                                  ,'N'
                                  ,ln_grand_total_orders
                                  ,NULL
                                  ,p_site_use_id
                                  );

                gc_error_location := 'Calling INSERT_TRX_TOTALS for BILLTO_TAX -- SUBSTR(p_total_by ,1 ,2) =B1';    -- added for defect 11993
                gc_debug          := NULL;
                INSERT_TRX_TOTALS( p_reqs_id
                                  ,p_cons_id
                                  ,p_cust_doc_id
                                  ,last_inv_id
                                  ,'BILLTO_TAX'
                                  ,GET_TRX_SEQ()
                                  ,last_inv_num
                                  ,RPAD('BILL TO:', 20 ,' ')||p_billing_id
                                  ,ln_billto_tax
                                  ,'N'
                                  ,ln_grand_total_orders
                                  ,NULL
                                  ,p_site_use_id
                                  );

                gc_error_location := 'Calling INSERT_TRX_TOTALS for BILLTO_TOTAL -- SUBSTR(p_total_by ,1 ,2) =B1';
                gc_debug          := NULL;
                INSERT_TRX_TOTALS( p_reqs_id
                                  ,p_cons_id
                                  ,p_cust_doc_id
                                  ,last_inv_id
                                  ,'BILLTO_TOTAL'
                                  ,GET_TRX_SEQ()
                                  ,last_inv_num
                                  ,RPAD('BILL TO:', 20 ,' ')||p_billing_id
                                  ,ln_billto_total
                                  ,'N'
                                  ,ln_grand_total_orders
                                  ,NULL
                                  ,p_site_use_id
                                  );
             ELSE
                NULL;
             END IF;

             gc_error_location := 'Calling INSERT_TRX_TOTALS for GRAND_TOTAL';
             gc_debug          := NULL;
             INSERT_TRX_TOTALS( p_reqs_id
                               ,p_cons_id
                               ,p_cust_doc_id
                               ,last_inv_id
                               ,'GRAND_TOTAL'
                               ,GET_TRX_SEQ()
                               ,last_inv_num
                               ,'GRAND_TOTAL:'
                               ,ln_grand_total
                               ,'N'
                               ,ln_grand_total_orders
                               ,NULL
                               ,p_site_use_id
                               );

          ELSE

             gc_error_location := 'Before B1_cur_data';
             FOR cur_data_rec IN B1_cur_data LOOP
                ln_grand_total         := TO_NUMBER(NULL);
                ln_billto_subtot       := TO_NUMBER(NULL);
                ln_billto_discounts    := TO_NUMBER(NULL);
                ln_billto_tax          := TO_NUMBER(NULL);
                ln_grand_total_orders  := TO_NUMBER(NULL);

                IF (lb_B1_first_record) THEN
                   gc_error_location := 'Before US_B1_totals';
                    FOR B1_total_rec IN US_B1_totals LOOP
                       ln_grand_total        := B1_total_rec.amount;
                       ln_billto_subtot      := B1_total_rec.subtotal_amount;
                       ln_billto_discounts   := B1_total_rec.promo_and_disc;
                       ln_billto_tax         := B1_total_rec.tax_amount;
                       ln_grand_total_orders := B1_total_rec.total_orders;
                    END LOOP;

                    gc_error_location := 'Calling INSERT_TRX_TOTALS for BILLTO_SUBTOTAL -- only B1 totals';
                    gc_debug          := NULL;
                    INSERT_TRX_TOTALS( p_reqs_id
                                      ,p_cons_id
                                      ,p_cust_doc_id
                                      ,cur_data_rec.trx_id
                                      ,'BILLTO_SUBTOTAL'
                                      ,GET_TRX_SEQ()
                                      ,cur_data_rec.inv_number
                                      ,RPAD('BILL TO:', 20 ,' ')||p_billing_id
                                      ,ln_billto_subtot
                                      ,'N'
                                      ,ln_grand_total_orders
                                      ,NULL
                                      ,p_site_use_id
                                      );

                    gc_error_location := 'Calling INSERT_TRX_TOTALS for BILLTO_DISCOUNTS-- only B1 totals';
                    gc_debug          := NULL;
                    INSERT_TRX_TOTALS( p_reqs_id
                                      ,p_cons_id
                                      ,p_cust_doc_id
                                      ,cur_data_rec.trx_id
                                      ,'BILLTO_DISCOUNTS'
                                      ,GET_TRX_SEQ()
                                      ,cur_data_rec.inv_number
                                      ,RPAD('BILL TO:' ,20 ,' ')||p_billing_id
                                      ,ln_billto_discounts
                                      ,'N'
                                      ,ln_grand_total_orders
                                      ,NULL
                                      ,p_site_use_id
                                      );

                    gc_error_location := 'Calling INSERT_TRX_TOTALS for BILLTO_TAX-- only B1 totals';
                    gc_debug          := NULL;
                    INSERT_TRX_TOTALS( p_reqs_id
                                      ,p_cons_id
                                      ,p_cust_doc_id
                                      ,cur_data_rec.trx_id
                                      ,'BILLTO_TAX'
                                      ,GET_TRX_SEQ()
                                      ,cur_data_rec.inv_number
                                      ,RPAD('BILL TO:', 20 ,' ')||p_billing_id
                                      ,ln_billto_tax
                                      ,'N'
                                      ,ln_grand_total_orders
                                      ,NULL
                                      ,p_site_use_id
                                      );

                    gc_error_location := 'Calling INSERT_TRX_TOTALS for BILLTO_TOTAL-- only B1 totals';
                    gc_debug          := NULL;
                    INSERT_TRX_TOTALS( p_reqs_id
                                      ,p_cons_id
                                      ,p_cust_doc_id
                                      ,cur_data_rec.trx_id
                                      ,'BILLTO_TOTAL'
                                      ,GET_TRX_SEQ()
                                      ,cur_data_rec.inv_number
                                      ,RPAD('BILL TO:', 20 ,' ')||p_billing_id
                                      ,ln_grand_total
                                      ,'N'
                                      ,ln_grand_total_orders
                                      ,NULL
                                      ,p_site_use_id
                                      );

                    gc_error_location := 'Calling INSERT_TRX_TOTALS for GRAND_TOTAL-- only B1 totals';
                    gc_debug          := NULL;
                    INSERT_TRX_TOTALS( p_reqs_id
                                      ,p_cons_id
                                      ,p_cust_doc_id
                                      ,cur_data_rec.trx_id
                                      ,'GRAND_TOTAL'
                                      ,GET_TRX_SEQ()
                                      ,cur_data_rec.inv_number
                                      ,'GRAND_TOTAL:'
                                      ,ln_grand_total
                                      ,'N'
                                      ,ln_grand_total_orders
                                      ,NULL
                                      ,p_site_use_id
                                      );
                    lb_B1_first_record :=FALSE;
                   EXIT;
                ELSE
                   NULL;
                END IF;
             END LOOP;
          END IF;
       ELSIF xx_fin_country_defaults_pkg.f_org_id('CA') =FND_PROFILE.VALUE('ORG_ID') THEN
          IF p_total_by <>'B1' THEN
             FOR cur_data_rec IN CA_cur_data
             LOOP
                lr_CA_cur_rec          := cur_data_rec;
                ln_prov_tax_code       := lr_CA_cur_rec.cad_county_tax_code;
                ln_grand_total         := NVL(ln_grand_total ,0) + NVL(cur_data_rec.amount ,0);
                ln_billto_subtot       := NVL(ln_billto_subtot ,0) + NVL(cur_data_rec.subtotal_amount ,0);
                ln_billto_discounts    := NVL(ln_billto_discounts ,0) + NVL(cur_data_rec.promo_and_disc ,0);
                ln_billto_ca_state_tax := NVL(ln_billto_ca_state_tax ,0) + NVL(cur_data_rec.cad_state_tax_amount ,0);
                ln_billto_ca_prov_tax  := NVL(ln_billto_ca_prov_tax ,0) + NVL(cur_data_rec.cad_county_tax_amount ,0);
                ln_billto_total        := (NVL(ln_billto_total ,0) + (NVL(cur_data_rec.subtotal_amount ,0)
                                                                      + NVL(cur_data_rec.promo_and_disc ,0)
                                                                      + NVL(cur_data_rec.cad_state_tax_amount ,0)
                                                                      + NVL(cur_data_rec.cad_county_tax_amount ,0)
                                                                      )
                                          );
                ln_grand_total_orders := ln_grand_total_orders +1;

                IF lb_first_record THEN
                   lb_first_record := FALSE;
                   FOR i IN 1..ln_number_of_sft_hdr
                   LOOP
                      ln_curr_index := (ln_number_of_sft_hdr-i)+1;

                      SELECT DECODE(ln_curr_index
                                    ,1, cur_data_rec.sfdata1
                                    ,2, cur_data_rec.sfdata2
                                    ,3, cur_data_rec.sfdata3
                                    ,4, cur_data_rec.sfdata4
                                    ,5, cur_data_rec.sfdata5
                                    ,6, cur_data_rec.sfdata6
                                    )
                      INTO    lr_CA_records(ln_curr_index).current_value
                      FROM    dual;

                      lr_CA_records(ln_curr_index).total_amount := cur_data_rec.amount;
                      lr_CA_records(ln_curr_index).subtotal     := cur_data_rec.subtotal_amount;
                      lr_CA_records(ln_curr_index).discounts    := cur_data_rec.promo_and_disc;
                      lr_CA_records(ln_curr_index).prov_tax     := cur_data_rec.cad_county_tax_amount;
                      lr_CA_records(ln_curr_index).gst_tax      := cur_data_rec.cad_state_tax_amount;
                      lr_CA_records(ln_curr_index).order_count  := ln_order_count;
                      prev_inv_num                              := cur_data_rec.inv_number;
                      prev_inv_id                               := cur_data_rec.trx_id;

                      SELECT DECODE(ln_curr_index
                                    ,1, cur_data_rec.sfhdr1
                                    ,2, cur_data_rec.sfhdr2
                                    ,3, cur_data_rec.sfhdr3
                                    ,4, cur_data_rec.sfhdr4
                                    ,5, cur_data_rec.sfhdr5
                                    ,6, cur_data_rec.sfhdr6
                                    )
                      INTO    lr_CA_records(ln_curr_index).current_header
                      FROM    dual;

                   END LOOP;
                ELSE
                   ln_min_changed_index := 0;
                   FOR i IN 1..ln_number_of_sft_hdr LOOP

                      ln_curr_index := (ln_number_of_sft_hdr-i)+1;
                      lr_CA_records(ln_curr_index).prior_value := lr_CA_records(ln_curr_index).current_value;
                      lr_CA_records(ln_curr_index).prior_header:= lr_CA_records(ln_curr_index).current_header;
                      SELECT DECODE(ln_curr_index
                                    ,1, cur_data_rec.sfdata1
                                    ,2, cur_data_rec.sfdata2
                                    ,3, cur_data_rec.sfdata3
                                    ,4, cur_data_rec.sfdata4
                                    ,5, cur_data_rec.sfdata5
                                    ,6, cur_data_rec.sfdata6
                                    )
                      INTO    lr_CA_records(ln_curr_index).current_value
                      FROM    dual;

                      SELECT DECODE(ln_curr_index
                                    ,1, cur_data_rec.sfhdr1
                                    ,2, cur_data_rec.sfhdr2
                                    ,3, cur_data_rec.sfhdr3
                                    ,4, cur_data_rec.sfhdr4
                                    ,5, cur_data_rec.sfhdr5
                                    ,6, cur_data_rec.sfhdr6
                                    )
                      INTO    lr_CA_records(ln_curr_index).current_header
                      FROM    dual;

                      IF NVL(lr_CA_records(ln_curr_index).current_value, '?') != NVL(lr_CA_records(ln_curr_index).prior_value, '?') THEN
                         ln_min_changed_index := ln_curr_index;
                         IF p_page_by !='B1' THEN
                            IF ln_min_changed_index <= (LENGTH(REPLACE(p_page_by ,'B1' ,''))/2) THEN
                               lr_CA_records(ln_curr_index).pg_break :='Y';
                            ELSE
                               lr_CA_records(ln_curr_index).pg_break :='';
                            END IF;
                         ELSE
                            lr_CA_records(ln_curr_index).pg_break :='';
                         END IF;
                      END IF;
                   END LOOP;

                   FOR i IN 1..ln_number_of_sft_hdr
                   LOOP
                      ln_curr_index := (ln_number_of_sft_hdr-i)+1;
                      IF ln_min_changed_index != 0 AND ln_min_changed_index <= ln_curr_index THEN

                         gc_error_location := 'Calling INSERT_TRX_TOTALS for SOFTHDR_SUBTOTAL -- Canadian Invoices prior';
                         gc_debug          := NULL;
                         INSERT_TRX_TOTALS( p_reqs_id
                                           ,p_cons_id
                                           ,p_cust_doc_id
                                           ,prev_inv_id
                                           ,'SOFTHDR_SUBTOTAL'
                                           ,GET_TRX_SEQ()
                                           ,prev_inv_num
                                           --,RPAD(lr_CA_records(ln_curr_index).prior_header , 20 ,' ')
                                           --||RPAD(lr_CA_records(ln_curr_index).prior_value, 20 ,' ')  -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
                                           ,RPAD(lr_CA_records(ln_curr_index).prior_header , 20 ,' ')
                                           ||RPAD(lr_CA_records(ln_curr_index).prior_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                           ,lr_CA_records(ln_curr_index).subtotal
                                           ,lr_CA_records(ln_curr_index).pg_break
                                           ,lr_CA_records(ln_curr_index).order_count
                                           ,NULL
                                           ,p_site_use_id
                                           );

                         gc_error_location := 'Calling INSERT_TRX_TOTALS for SOFTHDR_DISCOUNTS -- Canadian Invoices prior';
                         gc_debug          := NULL;
                         INSERT_TRX_TOTALS( p_reqs_id
                                           ,p_cons_id
                                           ,p_cust_doc_id
                                           ,prev_inv_id
                                           ,'SOFTHDR_DISCOUNTS'
                                           ,GET_TRX_SEQ()
                                           ,prev_inv_num
                                           --,RPAD(lr_CA_records(ln_curr_index).prior_header , 20 ,' ')
                                           --||RPAD(lr_CA_records(ln_curr_index).prior_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
                                           ,RPAD(lr_CA_records(ln_curr_index).prior_header , 20 ,' ')
                                           ||RPAD(lr_CA_records(ln_curr_index).prior_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                           ,lr_CA_records(ln_curr_index).discounts
                                           ,lr_CA_records(ln_curr_index).pg_break
                                           ,lr_CA_records(ln_curr_index).order_count
                                           ,NULL
                                           ,p_site_use_id
                                           );

                         gc_error_location := 'Calling INSERT_TRX_TOTALS for SOFTHDR_PROV_TAX-- Canadian Invoices prior';
                         gc_debug          := NULL;
                         INSERT_TRX_TOTALS( p_reqs_id
                                           ,p_cons_id
                                           ,p_cust_doc_id
                                           ,prev_inv_id
                                           ,'SOFTHDR_PROV_TAX'
                                           ,GET_TRX_SEQ()
                                           ,prev_inv_num
                                           --,RPAD(lr_CA_records(ln_curr_index).prior_header , 20 ,' ')
                                           --||RPAD(lr_CA_records(ln_curr_index).prior_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
                                           ,RPAD(lr_CA_records(ln_curr_index).prior_header , 20 ,' ')
                                           ||RPAD(lr_CA_records(ln_curr_index).prior_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                           ,lr_CA_records(ln_curr_index).prov_tax
                                           ,lr_CA_records(ln_curr_index).pg_break
                                           ,lr_CA_records(ln_curr_index).order_count
                                           ,'PST'
                                           ,p_site_use_id
                                           );

                         gc_error_location := 'Calling INSERT_TRX_TOTALS for SOFTHDR_STATE_TAX-- Canadian Invoices prior';
                         gc_debug          := NULL;
                         INSERT_TRX_TOTALS( p_reqs_id
                                           ,p_cons_id
                                           ,p_cust_doc_id
                                           ,prev_inv_id
                                           ,'SOFTHDR_STATE_TAX'
                                           ,GET_TRX_SEQ()
                                           ,prev_inv_num
                                           --,RPAD(lr_CA_records(ln_curr_index).prior_header , 20 ,' ')
                                           --||RPAD(lr_CA_records(ln_curr_index).prior_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
                                           ,RPAD(lr_CA_records(ln_curr_index).prior_header , 20 ,' ')
                                           ||RPAD(lr_CA_records(ln_curr_index).prior_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                           ,lr_CA_records(ln_curr_index).gst_tax
                                           ,lr_CA_records(ln_curr_index).pg_break
                                           ,lr_CA_records(ln_curr_index).order_count
                                           ,'GST / HST'
                                           ,p_site_use_id
                                           );

                         gc_error_location := 'Calling INSERT_TRX_TOTALS for SOFTHDR_TOTAL-- Canadian Invoices prior';
                         gc_debug          := NULL;
                         INSERT_TRX_TOTALS( p_reqs_id
                                           ,p_cons_id
                                           ,p_cust_doc_id
                                           ,prev_inv_id
                                           ,'SOFTHDR_TOTAL'
                                           ,GET_TRX_SEQ()
                                           ,prev_inv_num
                                           --,RPAD(lr_CA_records(ln_curr_index).prior_header , 20 ,' ')
                                           --||RPAD(lr_CA_records(ln_curr_index).prior_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
                                           ,RPAD(lr_CA_records(ln_curr_index).prior_header , 20 ,' ')
                                           ||RPAD(lr_CA_records(ln_curr_index).prior_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                           ,lr_CA_records(ln_curr_index).total_amount
                                           ,lr_CA_records(ln_curr_index).pg_break
                                           ,lr_CA_records(ln_curr_index).order_count
                                           ,NULL
                                           ,p_site_use_id
                                           );

                         lr_CA_records(ln_curr_index).total_amount := cur_data_rec.amount;
                         lr_CA_records(ln_curr_index).subtotal     := cur_data_rec.subtotal_amount;
                         lr_CA_records(ln_curr_index).discounts    := cur_data_rec.promo_and_disc;
                         lr_CA_records(ln_curr_index).prov_tax     := cur_data_rec.cad_county_tax_amount;
                         lr_CA_records(ln_curr_index).gst_tax      := cur_data_rec.cad_state_tax_amount;
                         lr_CA_records(ln_curr_index).order_count  := 1;
                      ELSE
                         lr_CA_records(ln_curr_index).total_amount := cur_data_rec.amount + lr_CA_records(ln_curr_index).total_amount;
                         lr_CA_records(ln_curr_index).subtotal     := cur_data_rec.subtotal_amount + lr_CA_records(ln_curr_index).subtotal;
                         lr_CA_records(ln_curr_index).discounts    := cur_data_rec.promo_and_disc + lr_CA_records(ln_curr_index).discounts;
                         lr_CA_records(ln_curr_index).prov_tax     := cur_data_rec.cad_county_tax_amount + lr_CA_records(ln_curr_index).prov_tax;
                         lr_CA_records(ln_curr_index).gst_tax      := cur_data_rec.cad_state_tax_amount + lr_CA_records(ln_curr_index).gst_tax;
                         lr_CA_records(ln_curr_index).order_count  := lr_CA_records(ln_curr_index).order_count + 1;
                      END IF;
                   END LOOP;

                   prev_inv_num := lr_CA_cur_rec.inv_number;
                   prev_inv_id  := lr_CA_cur_rec.trx_id;
                END IF;

             last_inv_num := lr_CA_cur_rec.inv_number;
             last_inv_id  := lr_CA_cur_rec.trx_id;

             END LOOP;

             FOR i IN 1..ln_number_of_sft_hdr
             LOOP
                ln_curr_index := (ln_number_of_sft_hdr-i)+1;

                gc_error_location := 'Calling INSERT_TRX_TOTALS for SOFTHDR_SUBTOTAL -- Canadian Invoices current';
                gc_debug          := NULL;
                INSERT_TRX_TOTALS( p_reqs_id
                                  ,p_cons_id
                                  ,p_cust_doc_id
                                  ,prev_inv_id
                                  ,'SOFTHDR_SUBTOTAL'
                                  ,GET_TRX_SEQ()
                                  ,prev_inv_num
                                 -- ,RPAD(lr_CA_records(ln_curr_index).current_header, 20 ,' ')
                                 -- ||RPAD(lr_CA_records(ln_curr_index).current_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
                                   ,RPAD(lr_CA_records(ln_curr_index).current_header, 20 ,' ')
                                  ||RPAD(lr_CA_records(ln_curr_index).current_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                  ,lr_CA_records(ln_curr_index).subtotal
                                  ,lr_CA_records(ln_curr_index).pg_break
                                  ,lr_CA_records(ln_curr_index).order_count
                                  ,NULL
                                  ,p_site_use_id
                                  );

                gc_error_location := 'Calling INSERT_TRX_TOTALS for SOFTHDR_DISCOUNTS-- Canadian Invoices current';
                gc_debug := NULL;
                INSERT_TRX_TOTALS( p_reqs_id
                                  ,p_cons_id
                                  ,p_cust_doc_id
                                  ,prev_inv_id
                                  ,'SOFTHDR_DISCOUNTS'
                                  ,GET_TRX_SEQ()
                                  ,prev_inv_num
                                  --,RPAD(lr_CA_records(ln_curr_index).current_header , 20 ,' ')
                                  --||RPAD(lr_CA_records(ln_curr_index).current_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
                                  ,RPAD(lr_CA_records(ln_curr_index).current_header , 20 ,' ')
                                  ||RPAD(lr_CA_records(ln_curr_index).current_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                  ,lr_CA_records(ln_curr_index).discounts
                                  ,'N'
                                  ,lr_CA_records(ln_curr_index).order_count
                                  ,NULL
                                  ,p_site_use_id
                                  );

                gc_error_location := 'Calling INSERT_TRX_TOTALS for SOFTHDR_PROV_TAX-- Canadian Invoices current';
                gc_debug          := NULL;
                INSERT_TRX_TOTALS( p_reqs_id
                                  ,p_cons_id
                                  ,p_cust_doc_id
                                  ,prev_inv_id
                                  ,'SOFTHDR_PROV_TAX'
                                  ,GET_TRX_SEQ()
                                  ,prev_inv_num
                                 -- ,RPAD(lr_CA_records(ln_curr_index).current_header, 20 ,' ')
                                 --  ||RPAD(lr_CA_records(ln_curr_index).current_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
                                  ,RPAD(lr_CA_records(ln_curr_index).current_header, 20 ,' ')
                                   ||RPAD(lr_CA_records(ln_curr_index).current_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                  ,lr_CA_records(ln_curr_index).prov_tax
                                  ,lr_CA_records(ln_curr_index).pg_break
                                  ,lr_CA_records(ln_curr_index).order_count
                                  ,'PST'
                                  ,p_site_use_id
                                  );

                gc_error_location := 'Calling INSERT_TRX_TOTALS for SOFTHDR_STATE_TAX-- Canadian Invoices current';
                gc_debug          := NULL;
                INSERT_TRX_TOTALS( p_reqs_id
                                  ,p_cons_id
                                  ,p_cust_doc_id
                                  ,prev_inv_id
                                  ,'SOFTHDR_STATE_TAX'
                                  ,GET_TRX_SEQ()
                                  ,prev_inv_num
                                  --,RPAD(lr_CA_records(ln_curr_index).current_header, 20 ,' ')
                                  -- ||RPAD(lr_CA_records(ln_curr_index).current_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
                                  ,RPAD(lr_CA_records(ln_curr_index).current_header, 20 ,' ')
                                   ||RPAD(lr_CA_records(ln_curr_index).current_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                  ,lr_CA_records(ln_curr_index).gst_tax
                                  ,lr_CA_records(ln_curr_index).pg_break
                                  ,lr_CA_records(ln_curr_index).order_count
                                  ,'GST / HST'
                                  ,p_site_use_id
                                  );

                gc_error_location := 'Calling INSERT_TRX_TOTALS for SOFTHDR_TOTAL-- Canadian Invoices current';
                gc_debug          := NULL;
                INSERT_TRX_TOTALS( p_reqs_id
                                   ,p_cons_id
                                   ,p_cust_doc_id
                                   ,prev_inv_id
                                   ,'SOFTHDR_TOTAL'
                                   ,GET_TRX_SEQ()
                                   ,prev_inv_num
                                   --,RPAD(lr_CA_records(ln_curr_index).current_header, 20 ,' ')
                                   -- ||RPAD(lr_CA_records(ln_curr_index).current_value, 20 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
                                   ,RPAD(lr_CA_records(ln_curr_index).current_header, 20 ,' ')
                                    ||RPAD(lr_CA_records(ln_curr_index).current_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                   ,lr_CA_records(ln_curr_index).total_amount
                                   ,lr_CA_records(ln_curr_index).pg_break
                                   ,lr_CA_records(ln_curr_index).order_count
                                   ,NULL
                                   ,p_site_use_id
                                   );

             END LOOP;

             gc_error_location := 'Calling INSERT_TRX_TOTALS for BILLTO_SUBTOTAL -- Canadian Invoices SUBSTR(p_total_by ,1 ,2) =B1';
             gc_debug          := NULL;
             IF SUBSTR(p_total_by ,1 ,2) ='B1' THEN
                INSERT_TRX_TOTALS( p_reqs_id
                                  ,p_cons_id
                                  ,p_cust_doc_id
                                  ,last_inv_id
                                  ,'BILLTO_SUBTOTAL'
                                  ,GET_TRX_SEQ()
                                  ,last_inv_num
                                  ,RPAD('BILL TO:', 20 ,' ')||p_billing_id
                                  ,ln_billto_subtot
                                  ,'N'
                                  ,ln_grand_total_orders
                                  ,NULL
                                  ,p_site_use_id
                                   );

                gc_error_location := 'Calling INSERT_TRX_TOTALS for BILLTO_DISCOUNTS-- Canadian Invoices SUBSTR(p_total_by ,1 ,2) =B1';
                gc_debug          := NULL;
                INSERT_TRX_TOTALS( p_reqs_id
                                  ,p_cons_id
                                  ,p_cust_doc_id
                                  ,last_inv_id
                                  ,'BILLTO_DISCOUNTS'
                                  ,GET_TRX_SEQ()
                                  ,last_inv_num
                                  ,RPAD('BILL TO:' ,20 ,' ')||p_billing_id
                                  ,ln_billto_discounts
                                  ,'N'
                                  ,ln_grand_total_orders
                                  ,NULL
                                  ,p_site_use_id
                                  );

                gc_error_location := 'Calling INSERT_TRX_TOTALS for BILLTO_PROV_TAX-- Canadian Invoices SUBSTR(p_total_by ,1 ,2) =B1';
                gc_debug          := NULL;
                INSERT_TRX_TOTALS( p_reqs_id
                                  ,p_cons_id
                                  ,p_cust_doc_id
                                  ,last_inv_id
                                  ,'BILLTO_PROV_TAX'
                                  ,GET_TRX_SEQ()
                                  ,last_inv_num
                                  ,RPAD('BILL TO:', 20 ,' ')||p_billing_id
                                  ,ln_billto_ca_prov_tax
                                  ,'N'
                                  ,ln_grand_total_orders
                                  ,'PST'
                                  ,p_site_use_id
                                  );

                gc_error_location := 'Calling INSERT_TRX_TOTALS for BILLTO_STATE_TAX-- Canadian Invoices SUBSTR(p_total_by ,1 ,2) =B1';
                gc_debug          := NULL;
                INSERT_TRX_TOTALS( p_reqs_id
                                  ,p_cons_id
                                  ,p_cust_doc_id
                                  ,last_inv_id
                                  ,'BILLTO_STATE_TAX'
                                  ,GET_TRX_SEQ()
                                  ,last_inv_num
                                  ,RPAD('BILL TO:', 20 ,' ')||p_billing_id
                                  ,ln_billto_ca_state_tax
                                  ,'N'
                                  ,ln_grand_total_orders
                                  ,'GST / HST'
                                  ,p_site_use_id
                                  );

                gc_error_location := 'Callng INSERT_TRX_TOTALS for BILLTO_TOTAL-- Canadian Invoices SUBSTR(p_total_by ,1 ,2) =B1';
                gc_debug := NULL;
                INSERT_TRX_TOTALS( p_reqs_id
                                  ,p_cons_id
                                  ,p_cust_doc_id
                                  ,last_inv_id
                                  ,'BILLTO_TOTAL'
                                  ,GET_TRX_SEQ()
                                  ,last_inv_num
                                  ,RPAD('BILL TO:', 20 ,' ')||p_billing_id
                                  ,ln_billto_total
                                  ,'N'
                                  ,ln_grand_total_orders
                                  ,NULL
                                  ,p_site_use_id
                                  );
             ELSE
                NULL;
             END IF;

             gc_error_location := 'Calling INSERT_TRX_TOTALS for GRAND_TOTAL-- Canadian Invoices SUBSTR(p_total_by ,1 ,2) =B1';
             gc_debug          := NULL;
             INSERT_TRX_TOTALS( p_reqs_id
                               ,p_cons_id
                               ,p_cust_doc_id
                               ,last_inv_id --p_cons_id||6
                               ,'GRAND_TOTAL'
                               ,GET_TRX_SEQ()
                               ,last_inv_num
                               ,'GRAND_TOTAL:'
                               ,ln_grand_total
                               ,'N'
                               ,ln_grand_total_orders
                               ,NULL
                               ,p_site_use_id
                               );
          ELSE

             FOR cur_data_rec IN B1_cur_data
             LOOP
                ln_grand_total         := TO_NUMBER(NULL);
                ln_billto_subtot       := TO_NUMBER(NULL);
                ln_billto_discounts    := TO_NUMBER(NULL);
                ln_billto_ca_prov_tax  := TO_NUMBER(NULL);
                ln_billto_ca_state_tax := TO_NUMBER(NULL);
                ln_grand_total_orders  := TO_NUMBER(NULL);

                IF (lb_B1_first_record) THEN
                   FOR B1_total_rec IN CA_B1_totals LOOP
                      ln_grand_total         := B1_total_rec.amount;
                      ln_billto_subtot       := B1_total_rec.subtotal_amount;
                      ln_billto_discounts    := B1_total_rec.promo_and_disc;
                      ln_billto_ca_prov_tax  := B1_total_rec.cad_county_tax_amount;
                      ln_billto_ca_state_tax := B1_total_rec.cad_state_tax_amount;
                      ln_grand_total_orders  := B1_total_rec.total_orders;
                   END LOOP;

                   gc_error_location := 'Calling INSERT_TRX_TOTALS for BILLTO_SUBTOTAL -- Canadian Invoices - only B1 totals';
                   gc_debug          := NULL;
                   INSERT_TRX_TOTALS( p_reqs_id
                                     ,p_cons_id
                                     ,p_cust_doc_id
                                     ,cur_data_rec.trx_id
                                     ,'BILLTO_SUBTOTAL'
                                     ,GET_TRX_SEQ()
                                     ,cur_data_rec.inv_number
                                     ,RPAD('BILL TO:', 20 ,' ')||p_billing_id
                                     ,ln_billto_subtot
                                     ,'N'
                                     ,ln_grand_total_orders
                                     ,NULL
                                     ,p_site_use_id
                                     );

                   gc_error_location := 'Calling INSERT_TRX_TOTALS for BILLTO_DISCOUNTS-- Canadian Invoices - only B1 totals';
                   gc_debug          := NULL;
                   INSERT_TRX_TOTALS( p_reqs_id
                                     ,p_cons_id
                                     ,p_cust_doc_id
                                     ,cur_data_rec.trx_id
                                     ,'BILLTO_DISCOUNTS'
                                     ,GET_TRX_SEQ()
                                     ,cur_data_rec.inv_number
                                     ,RPAD('BILL TO:' ,20 ,' ')||p_billing_id
                                     ,ln_billto_discounts
                                     ,'N'
                                     ,ln_grand_total_orders
                                     ,NULL
                                     ,p_site_use_id
                                     );

                   gc_error_location := 'Calling INSERT_TRX_TOTALS for BILLTO_PROV_TAX-- Canadian Invoices - only B1 totals';
                   gc_debug := NULL;
                   INSERT_TRX_TOTALS( p_reqs_id
                                     ,p_cons_id
                                     ,p_cust_doc_id
                                     ,cur_data_rec.trx_id
                                     ,'BILLTO_PROV_TAX'
                                     ,GET_TRX_SEQ()
                                     ,cur_data_rec.inv_number
                                     ,RPAD('BILL TO:', 20 ,' ')||p_billing_id
                                     ,ln_billto_ca_prov_tax
                                     ,'N'
                                     ,ln_grand_total_orders
                                     ,'PST'
                                     ,p_site_use_id
                                    );

                   gc_error_location := 'Calling INSERT_TRX_TOTALS for BILLTO_STATE_TAX-- Canadian Invoices - only B1 totals';
                   gc_debug := NULL;
                   INSERT_TRX_TOTALS( p_reqs_id
                                     ,p_cons_id
                                     ,p_cust_doc_id
                                     ,cur_data_rec.trx_id
                                     ,'BILLTO_STATE_TAX'
                                     ,GET_TRX_SEQ()
                                     ,cur_data_rec.inv_number
                                     ,RPAD('BILL TO:', 20 ,' ')||p_billing_id
                                     ,ln_billto_ca_state_tax
                                     ,'N'
                                     ,ln_grand_total_orders
                                     ,'GST / HST'
                                     ,p_site_use_id
                                     );

                   gc_error_location := 'Calling INSERT_TRX_TOTALS for BILLTO_TOTAL-- Canadian Invoices - only B1 totals';
                   gc_debug := NULL;
                   INSERT_TRX_TOTALS( p_reqs_id
                                     ,p_cons_id
                                     ,p_cust_doc_id
                                     ,cur_data_rec.trx_id
                                     ,'BILLTO_TOTAL'
                                     ,GET_TRX_SEQ()
                                     ,cur_data_rec.inv_number
                                     ,RPAD('BILL TO:', 20 ,' ')||p_billing_id
                                     ,ln_grand_total
                                     ,'N'
                                     ,ln_grand_total_orders
                                     ,NULL
                                     ,p_Site_use_id
                                    );

                   gc_error_location := 'Calling INSERT_TRX_TOTALS for GRAND_TOTAL-- Canadian Invoices - only B1 totals';
                   gc_debug := NULL;
                   INSERT_TRX_TOTALS( p_reqs_id
                                     ,p_cons_id
                                     ,p_cust_doc_id
                                     ,cur_data_rec.trx_id
                                     ,'GRAND_TOTAL'
                                     ,GET_TRX_SEQ()
                                     ,cur_data_rec.inv_number
                                     ,'GRAND_TOTAL:'
                                     ,ln_grand_total
                                     ,'N'
                                     ,ln_grand_total_orders
                                     ,NULL
                                     ,p_site_use_id
                                    );
                   lb_B1_first_record :=FALSE;
                   EXIT;
                ELSE
                   NULL;
                END IF;
             END LOOP;
          END IF;
       ELSE
          NULL;
       END IF;
    END GENERATE_DETAIL_SUBTOTALS;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : GENERATE_SUMM_ONE_SUBTOTALS                                         |
-- | Description : This Procedure is used to calculate the subtotals for summary and   |
-- |               one document type.                                                  |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 17-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE GENERATE_SUMM_ONE_SUBTOTALS ( p_billing_id              IN VARCHAR2
                                           ,p_cons_id                 IN NUMBER
                                           ,p_cust_doc_id             IN NUMBER
                                           ,p_site_use_id             IN NUMBER
                                           ,p_reqs_id                 IN NUMBER
                                           ,p_total_by                IN VARCHAR2
                                           ,p_page_by                 IN VARCHAR2
                                           ,p_doc_type                IN VARCHAR2
                                           )
    AS
       TYPE us_rec_type IS RECORD ( current_value   VARCHAR2(400)
                                   ,prior_value     VARCHAR2(400)
                                   ,prior_header    VARCHAR2(400)
                                   ,current_header  VARCHAR2(400)
                                   ,order_count     NUMBER
                                   ,subtotal        NUMBER
                                   ,delivery        NUMBER
                                   ,discounts       NUMBER
                                   ,tax             NUMBER
                                   ,total_amount    NUMBER
                                   ,pg_break        VARCHAR2(1)
                                   );

       TYPE ca_rec_type IS RECORD ( current_value   VARCHAR2(400)
                                   ,prior_value     VARCHAR2(400)
                                   ,prior_header    VARCHAR2(400)
                                   ,current_header  VARCHAR2(400)
                                   ,order_count     NUMBER
                                   ,subtotal        NUMBER
                                   ,delivery        NUMBER
                                   ,discounts       NUMBER
                                   ,prov_tax        NUMBER
                                   ,gst_tax         NUMBER
                                   ,total_amount    NUMBER
                                   ,pg_break        VARCHAR2(1)
                                   );

       TYPE vr_us_rec_type IS TABLE OF us_rec_type
       INDEX BY BINARY_INTEGER;
       lr_records          vr_us_rec_type;

       TYPE vr_ca_rec_type IS TABLE OF ca_rec_type
       INDEX BY BINARY_INTEGER;
       lr_ca_records          vr_ca_rec_type;

       CURSOR us_cur_data
       IS
       SELECT sfdata1
             ,sfdata2
             ,sfdata3
             ,sfdata4
             ,sfdata5
             ,sfdata6
             ,tax_code
             ,sfhdr1
             ,sfhdr2
             ,sfhdr3
             ,sfhdr4
             ,sfhdr5
             ,sfhdr6
             ,customer_trx_id trx_id
             ,inv_number
             ,(NVL(subtotal_amount ,0) - NVL(delivery_charges ,0))                    subtotal_amount
             ,NVL(delivery_charges ,0)                                                delivery
             ,NVL(promo_and_disc ,0)                                                  promo_and_disc
             ,NVL(tax_amount ,0)                                                      tax_amount
             ,(NVL(subtotal_amount ,0) + NVL(promo_and_disc ,0) + NVL(tax_amount ,0)) amount
       FROM   xx_ar_ebl_cons_trx_stg       --Removed apps schema Reference
       WHERE  request_id                 = p_reqs_id
       AND    cons_inv_id                = p_cons_id
       AND    doc_type                   = p_doc_type
       AND    cust_doc_id                = p_cust_doc_id
       AND    bill_to_site_use_id        = p_site_use_id
       ORDER BY insert_seq;

       CURSOR us_b1_totals
       IS
       SELECT (NVL(SUM(subtotal_amount),0) - NVL(SUM(delivery_charges),0))  subtotal_amount
             ,NVL(SUM(delivery_charges),0)                                  delivery
             ,NVL(SUM(promo_and_disc),0)                                    promo_and_disc
             ,NVL(SUM(tax_amount),0)                                        tax_amount
             ,(NVL(SUM(subtotal_amount),0)
               + NVL(SUM(promo_and_disc),0)
               + nvl(SUM(tax_amount),0)
               )                                                            amount
             ,COUNT(1)                                                      total_orders
       FROM   xx_ar_ebl_cons_trx_stg      --Removed apps schema Reference
       WHERE  request_id                 = p_reqs_id
       AND    cons_inv_id                = p_cons_id
       AND    doc_type                   = p_doc_type
       AND    cust_doc_id                = p_cust_doc_id
       AND    bill_to_site_use_id        = p_site_use_id;

       CURSOR CA_B1_totals
       IS
       SELECT (NVL(SUM(subtotal_amount),0) - NVL(SUM(delivery_charges),0)) subtotal_amount
             ,NVL(SUM(delivery_charges),0)                                 delivery
             ,NVL(SUM(promo_and_disc),0)                                   promo_and_disc
             ,NVL(SUM(cad_county_tax_amount),0)                            cad_county_tax_amount
             ,NVL(SUM(cad_state_tax_amount),0)                             cad_state_tax_amount
             ,(NVL(SUM(subtotal_amount),0)
               + NVL(SUM(promo_and_disc),0)
               + NVL(SUM(cad_county_tax_amount),0)
               + NVL(SUM(cad_state_tax_amount),0)
               )                                                          amount
             ,COUNT(1) total_orders
       FROM   xx_ar_ebl_cons_trx_stg          --Removed apps schema Reference
       WHERE  request_id                 = p_reqs_id
       AND    cons_inv_id                = p_cons_id
       AND    doc_type                   = p_doc_type
       AND    cust_doc_id                = p_cust_doc_id
       AND    bill_to_site_use_id        = p_site_use_id;

       CURSOR B1_cur_data
       IS
       SELECT customer_trx_id trx_id
             ,inv_number
       FROM   xx_ar_ebl_cons_trx_stg       --Removed apps schema Reference
       WHERE  request_id                 = p_reqs_id
       AND    cons_inv_id                = p_cons_id
       AND    doc_type                   = p_doc_type
       AND    cust_doc_id                = p_cust_doc_id
       AND    bill_to_site_use_id        = p_site_use_id
       AND    insert_seq                 = (SELECT MAX(insert_seq)
                                            FROM   xx_ar_ebl_cons_trx_stg        --Removed apps schema Reference
                                            WHERE  request_id                 = p_reqs_id
                                            AND    cons_inv_id                = p_cons_id
                                            AND    doc_type                   = p_doc_type
                                            AND    cust_doc_id                = p_cust_doc_id
                                            AND    bill_to_site_use_id        = p_site_use_id
                                            );

       CURSOR CA_cur_data
       IS
       SELECT sfdata1
             ,sfdata2
             ,sfdata3
             ,sfdata4
             ,sfdata5
             ,sfdata6
             ,sfhdr1
             ,sfhdr2
             ,sfhdr3
             ,sfhdr4
             ,sfhdr5
             ,sfhdr6
             ,cad_county_tax_code
             ,cad_state_tax_code
             ,customer_trx_id                                            trx_id
             ,inv_number
             ,(nvl(subtotal_amount,0) - nvl(delivery_charges,0))         subtotal_amount
             ,nvl(delivery_charges,0)                                    delivery
             ,nvl(promo_and_disc,0)                                      promo_and_disc
             ,nvl(cad_county_tax_amount,0)                               cad_county_tax_amount
             ,nvl(cad_state_tax_amount,0)                                cad_state_tax_amount
             ,(nvl(subtotal_amount,0)
               + nvl(promo_and_disc,0)
               + nvl(cad_county_tax_amount,0)
               + nvl(cad_state_tax_amount,0)
               )                                                         amount
       FROM  xx_ar_ebl_cons_trx_stg                                                 --Removed apps schema Reference
       WHERE request_id                 = p_reqs_id
       AND   cons_inv_id                = p_cons_id
       AND   doc_type                   = p_doc_type
       AND   cust_doc_id                = p_cust_doc_id
       AND   bill_to_site_use_id        = p_site_use_id
       ORDER BY insert_seq;

       lr_cur_rec                  US_cur_data%ROWTYPE;
       lr_CA_cur_rec               CA_cur_data%ROWTYPE;

       lb_first_record             BOOLEAN := TRUE;
       lb_B1_first_record          BOOLEAN := TRUE;
       ln_curr_index               NUMBER;
       ln_min_changed_index        NUMBER;
       ln_grand_total              NUMBER := 0;
       prev_inv_num                VARCHAR2(80) :=NULL;
       prev_inv_id                 NUMBER;
       last_inv_num                VARCHAR2(80) :=NULL;
       last_inv_id                 NUMBER;
       prev_ca_prov_code           VARCHAR2(80) :=NULL;
       prev_ca_state_code          VARCHAR2(80) :=NULL;
       ln_billto_subtot            NUMBER :=0;
       ln_billto_delivery          NUMBER :=0;
       ln_billto_discounts         NUMBER :=0;
       ln_billto_tax               NUMBER :=0;
       ln_billto_total             NUMBER :=0;
       ln_billto_ca_prov_tax       NUMBER :=0;
       ln_billto_ca_state_tax      NUMBER :=0;
       ln_order_count              NUMBER :=1;
       ln_grand_total_orders       NUMBER :=0;
       ln_number_of_sft_hdr        NUMBER := 0;

    BEGIN

       gc_error_location := 'Calculate the length of soft header';

       IF p_total_by <> 'B1' THEN
          ln_number_of_sft_hdr := LENGTH(REPLACE(p_total_by, 'B1' ,''))/2;
       ELSE
          ln_number_of_sft_hdr := LENGTH(p_total_by)/2;
       END IF;

       gc_debug          := ln_number_of_sft_hdr;

       gc_error_location := 'IF Condition to check the country = US';
       fnd_file.put_line(fnd_file.log ,gc_error_location);

       IF xx_fin_country_defaults_pkg.f_org_id('US') = FND_PROFILE.VALUE('ORG_ID') THEN
          IF p_total_by <>'B1' THEN
             FOR cur_data_rec IN US_cur_data
             LOOP
                lr_cur_rec              := cur_data_rec;
                ln_grand_total          := ln_grand_total + cur_data_rec.amount;
                ln_billto_subtot        := ln_billto_subtot + cur_data_rec.subtotal_amount;
                ln_billto_delivery      := ln_billto_delivery + cur_data_rec.delivery;
                ln_billto_discounts     := ln_billto_discounts + cur_data_rec.promo_and_disc;
                ln_billto_tax           := ln_billto_tax + cur_data_rec.tax_amount;
                ln_billto_total         := (ln_billto_total
                                            + cur_data_rec.subtotal_amount
                                            + cur_data_rec.promo_and_disc
                                            + cur_data_rec.tax_amount
                                            + cur_data_rec.delivery
                                            );
                ln_grand_total_orders := ln_grand_total_orders +1;
                IF lb_first_record THEN
                   lb_first_record := FALSE;
                   FOR i IN 1..ln_number_of_sft_hdr LOOP
                      ln_curr_index := (ln_number_of_sft_hdr-i)+1;
                      SELECT DECODE( ln_curr_index
                                    ,1, cur_data_rec.sfdata1
                                    ,2, cur_data_rec.sfdata2
                                    ,3, cur_data_rec.sfdata3
                                    ,4, cur_data_rec.sfdata4
                                    ,5, cur_data_rec.sfdata5
                                    ,6, cur_data_rec.sfdata6
                                    )
                      INTO    lr_records(ln_curr_index).current_value
                      FROM    dual;
                      lr_records(ln_curr_index).total_amount :=cur_data_rec.amount;
                      lr_records(ln_curr_index).subtotal     :=cur_data_rec.subtotal_amount;
                      lr_records(ln_curr_index).delivery     :=cur_data_rec.delivery;
                      lr_records(ln_curr_index).discounts    :=cur_data_rec.promo_and_disc;
                      lr_records(ln_curr_index).tax          :=cur_data_rec.tax_amount;
                      lr_records(ln_curr_index).order_count  :=ln_order_count;

                      prev_inv_num :=cur_data_rec.inv_number;
                      prev_inv_id  :=cur_data_rec.trx_id;

                      SELECT DECODE( ln_curr_index
                                    ,1, cur_data_rec.sfhdr1
                                    ,2, cur_data_rec.sfhdr2
                                    ,3, cur_data_rec.sfhdr3
                                    ,4, cur_data_rec.sfhdr4
                                    ,5, cur_data_rec.sfhdr5
                                    ,6, cur_data_rec.sfhdr6
                                    )
                      INTO    lr_records(ln_curr_index).current_header
                      FROM    dual;

                   END LOOP;
                ELSE
                   ln_min_changed_index := 0;
                   FOR i IN 1..ln_number_of_sft_hdr
                   LOOP
                      ln_curr_index := (ln_number_of_sft_hdr-i)+1;

                      lr_records(ln_curr_index).prior_value   := lr_records(ln_curr_index).current_value;
                      lr_records(ln_curr_index).prior_header  := lr_records(ln_curr_index).current_header;

                      SELECT DECODE( ln_curr_index
                                    ,1, cur_data_rec.sfdata1
                                    ,2, cur_data_rec.sfdata2
                                    ,3, cur_data_rec.sfdata3
                                    ,4, cur_data_rec.sfdata4
                                    ,5, cur_data_rec.sfdata5
                                    ,6, cur_data_rec.sfdata6
                                    )
                      INTO    lr_records(ln_curr_index).current_value
                      FROM    dual;

                      SELECT DECODE( ln_curr_index
                                    ,1, cur_data_rec.sfhdr1
                                    ,2, cur_data_rec.sfhdr2
                                    ,3, cur_data_rec.sfhdr3
                                    ,4, cur_data_rec.sfhdr4
                                    ,5, cur_data_rec.sfhdr5
                                    ,6, cur_data_rec.sfhdr6
                                    )
                      INTO    lr_records(ln_curr_index).current_header
                      FROM    dual;

                      IF NVL(lr_records(ln_curr_index).current_value, '?') != NVL(lr_records(ln_curr_index).prior_value, '?') THEN
                         ln_min_changed_index := ln_curr_index;

                         IF p_page_by !='B1' THEN
                            IF ln_min_changed_index <=(LENGTH(REPLACE(p_page_by ,'B1' ,''))/2) THEN
                               fnd_file.put_line(fnd_file.log,'Setting page break @ soft data:'||lr_records(ln_curr_index).current_value);
                               lr_records(ln_curr_index).pg_break :='Y';
                            ELSE
                               lr_records(ln_curr_index).pg_break :='';
                            END IF;
                         ELSE
                            lr_records(ln_curr_index).pg_break :='';
                         END IF;

                      END IF;

                   END LOOP;

                   FOR i IN 1..ln_number_of_sft_hdr
                   LOOP
                      ln_curr_index := (ln_number_of_sft_hdr-i)+1;
                      IF ln_min_changed_index != 0 AND ln_min_changed_index <= ln_curr_index THEN

                         gc_error_location := 'Calling INSERT_SUMM_ONE_TOTALS for SOFTHDR_TOTALS -- p_page_by !=B1 ';
                         gc_debug          := NULL;
                         fnd_file.put_line(fnd_file.log ,gc_error_location);

                         INSERT_SUMM_ONE_TOTALS ( p_reqs_id
                                                 ,p_cons_id
                                                 ,p_cust_doc_id
                                                 ,prev_inv_id
                                                 ,prev_inv_num
                                                 ,GET_TRX_SEQ()
                                                 ,'SOFTHDR_TOTALS'
                                                 --,RPAD(lr_records(ln_curr_index).prior_header , 20 ,' ')
                                                 -- ||RPAD(lr_records(ln_curr_index).prior_value, 25 ,' ')  -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
                                                 ,RPAD(lr_records(ln_curr_index).prior_header , 20 ,' ')
                                                  ||RPAD(lr_records(ln_curr_index).prior_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                                 ,lr_records(ln_curr_index).subtotal
                                                 ,lr_records(ln_curr_index).delivery
                                                 ,lr_records(ln_curr_index).discounts
                                                 ,lr_records(ln_curr_index).tax
                                                 ,lr_records(ln_curr_index).pg_break
                                                 ,lr_records(ln_curr_index).order_count
                                                 ,p_site_use_id
                                                 );

                         lr_records(ln_curr_index).total_amount := cur_data_rec.amount;
                         lr_records(ln_curr_index).subtotal     := cur_data_rec.subtotal_amount;
                         lr_records(ln_curr_index).delivery     := cur_data_rec.delivery;
                         lr_records(ln_curr_index).discounts    := cur_data_rec.promo_and_disc;
                         lr_records(ln_curr_index).tax          := cur_data_rec.tax_amount;
                         lr_records(ln_curr_index).order_count  := 1;
                      ELSE
                         lr_records(ln_curr_index).total_amount := cur_data_rec.amount + lr_records(ln_curr_index).total_amount;
                         lr_records(ln_curr_index).subtotal     := cur_data_rec.subtotal_amount + lr_records(ln_curr_index).subtotal;
                         lr_records(ln_curr_index).delivery     := cur_data_rec.delivery + lr_records(ln_curr_index).delivery;
                         lr_records(ln_curr_index).discounts    := cur_data_rec.promo_and_disc + lr_records(ln_curr_index).discounts;
                         lr_records(ln_curr_index).tax          := cur_data_rec.tax_amount + lr_records(ln_curr_index).tax;
                         lr_records(ln_curr_index).order_count  := lr_records(ln_curr_index).order_count + 1;
                      END IF;
                   END LOOP;
                      prev_inv_num := lr_cur_rec.inv_number;
                      prev_inv_id  := lr_cur_rec.trx_id;
                END IF;

                last_inv_num := lr_cur_rec.inv_number;
                last_inv_id  := lr_cur_rec.trx_id;

             END LOOP;
             FOR i IN 1..ln_number_of_sft_hdr
             LOOP
                ln_curr_index     := (ln_number_of_sft_hdr-i)+1;
                gc_error_location := 'Calling INSERT_SUMM_ONE_TOTALS for SOFTHDR_TOTALS -- p_page_by =B1 ';
                gc_debug          := NULL;
                fnd_file.put_line(fnd_file.log ,gc_error_location);

                INSERT_SUMM_ONE_TOTALS ( p_reqs_id
                                        ,p_cons_id
                                        ,p_cust_doc_id
                                        ,prev_inv_id
                                        ,prev_inv_num
                                        ,GET_TRX_SEQ()
                                        ,'SOFTHDR_TOTALS'
                                        --,RPAD(lr_records(ln_curr_index).current_header, 20 ,' ')
                                        -- ||RPAD(lr_records(ln_curr_index).current_value, 25 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
                                        ,RPAD(lr_records(ln_curr_index).current_header, 20 ,' ')
                                         ||RPAD(lr_records(ln_curr_index).current_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                        ,lr_records(ln_curr_index).subtotal
                                        ,lr_records(ln_curr_index).delivery
                                        ,lr_records(ln_curr_index).discounts
                                        ,lr_records(ln_curr_index).tax
                                        ,lr_records(ln_curr_index).pg_break
                                        ,lr_records(ln_curr_index).order_count
                                        ,p_site_use_id
                                        );
             END LOOP;
             gc_error_location := 'Calling INSERT_SUMM_ONE_TOTALS for SOFTHDR_TOTALS -- SUBSTR(p_total_by ,1 ,2) =B1 ';    -- added for defect 11993
             gc_debug          := NULL;
             fnd_file.put_line(fnd_file.log ,gc_error_location);

             IF SUBSTR(p_total_by ,1 ,2) ='B1' THEN
                INSERT_SUMM_ONE_TOTALS ( p_reqs_id
                                        ,p_cons_id
                                        ,p_cust_doc_id
                                        ,last_inv_id
                                        ,last_inv_num
                                        ,GET_TRX_SEQ()
                                        ,'BILLTO_TOTALS'
                                        ,RPAD('BILL TO:', 10 ,' ')||p_billing_id
                                        ,ln_billto_subtot
                                        ,ln_billto_delivery
                                        ,ln_billto_discounts
                                        ,ln_billto_tax
                                        ,''
                                        ,ln_grand_total_orders
                                        ,p_site_use_id
                                        );
             ELSE
                NULL;
             END IF;

             INSERT_SUMM_ONE_TOTALS ( p_reqs_id
                                     ,p_cons_id
                                     ,p_cust_doc_id
                                     ,last_inv_id
                                     ,last_inv_num
                                     ,GET_TRX_SEQ()
                                     ,'GRAND_TOTAL'
                                     ,''
                                     ,ln_grand_total
                                     ,TO_NUMBER(NULL)
                                     ,TO_NUMBER(NULL)
                                     ,TO_NUMBER(NULL)
                                     ,''
                                     ,ln_grand_total_orders
                                     ,p_site_use_id
                                     );

          ELSE

             FOR cur_data_rec IN B1_cur_data LOOP
                ln_grand_total         := TO_NUMBER(NULL);
                ln_billto_subtot       := TO_NUMBER(NULL);
                ln_billto_delivery     := TO_NUMBER(NULL);
                ln_billto_discounts    := TO_NUMBER(NULL);
                ln_billto_tax          := TO_NUMBER(NULL);
                ln_grand_total_orders  := TO_NUMBER(NULL);

                IF (lb_B1_first_record) THEN

                   FOR B1_total_rec IN US_B1_totals
                   LOOP

                      ln_grand_total        := B1_total_rec.amount;
                      ln_billto_subtot      := B1_total_rec.subtotal_amount;
                      ln_billto_delivery    := B1_total_rec.delivery;
                      ln_billto_discounts   := B1_total_rec.promo_and_disc;
                      ln_billto_tax         := B1_total_rec.tax_amount;
                      ln_grand_total_orders := B1_total_rec.total_orders;

                   END LOOP;

                   gc_error_location := 'Calling INSERT_SUMM_ONE_TOTALS for BILLTO_TOTALS -- only B1 totals ';
                   gc_debug := NULL;
                   fnd_file.put_line(fnd_file.log ,gc_error_location);

                   INSERT_SUMM_ONE_TOTALS ( p_reqs_id
                                           ,p_cons_id
                                           ,p_cust_doc_id
                                           ,cur_data_rec.trx_id
                                           ,cur_data_rec.inv_number
                                           ,GET_TRX_SEQ()
                                           ,'BILLTO_TOTALS'
                                           ,RPAD('BILL TO :', 10 ,' ')||p_billing_id
                                           ,ln_billto_subtot
                                           ,ln_billto_delivery
                                           ,ln_billto_discounts
                                           ,ln_billto_tax
                                           ,''
                                           ,ln_grand_total_orders
                                           ,p_site_use_id
                                           );

                   gc_error_location := 'Calling INSERT_SUMM_ONE_TOTALS for GRAND_TOTAL -- only B1 totals ';
                   gc_debug := NULL;
                   fnd_file.put_line(fnd_file.log ,gc_error_location);

                   INSERT_SUMM_ONE_TOTALS ( p_reqs_id
                                           ,p_cons_id
                                           ,p_cust_doc_id
                                           ,cur_data_rec.trx_id
                                           ,cur_data_rec.inv_number
                                           ,GET_TRX_SEQ()
                                           ,'GRAND_TOTAL'
                                           ,''
                                           ,ln_grand_total
                                           ,TO_NUMBER(NULL)
                                           ,TO_NUMBER(NULL)
                                           ,TO_NUMBER(NULL)
                                           ,''
                                           ,ln_grand_total_orders
                                           ,p_site_use_id
                                           );

                   lb_B1_first_record :=FALSE;
                   EXIT;
                ELSE
                   NULL;
                END IF;
             END LOOP;
          END IF;
       ELSIF xx_fin_country_defaults_pkg.f_org_id('CA') =FND_PROFILE.VALUE('ORG_ID') THEN
          IF p_total_by <> 'B1' THEN
             FOR cur_data_rec IN CA_cur_data
             LOOP
                lr_CA_cur_rec          := cur_data_rec;
                ln_grand_total         := ln_grand_total + cur_data_rec.amount;
                ln_billto_subtot       := ln_billto_subtot + cur_data_rec.subtotal_amount;
                ln_billto_delivery     := ln_billto_delivery + cur_data_rec.delivery;
                ln_billto_discounts    := ln_billto_discounts + cur_data_rec.promo_and_disc;
                ln_billto_ca_state_tax := ln_billto_ca_state_tax + cur_data_rec.cad_state_tax_amount;
                ln_billto_ca_prov_tax  := ln_billto_ca_prov_tax + cur_data_rec.cad_county_tax_amount;
                ln_billto_total        := (ln_billto_total
                                          + cur_data_rec.subtotal_amount
                                          + cur_data_rec.promo_and_disc
                                          + cur_data_rec.cad_state_tax_amount
                                          + cur_data_rec.cad_county_tax_amount
                                          + cur_data_rec.delivery
                                          );
                ln_grand_total_orders :=ln_grand_total_orders +1;
                IF lb_first_record THEN
                   lb_first_record := FALSE;
                   FOR i IN 1..ln_number_of_sft_hdr
                   LOOP
                      ln_curr_index := (ln_number_of_sft_hdr-i)+1;
                      SELECT DECODE( ln_curr_index
                                    ,1, cur_data_rec.sfdata1
                                    ,2, cur_data_rec.sfdata2
                                    ,3, cur_data_rec.sfdata3
                                    ,4, cur_data_rec.sfdata4
                                    ,5, cur_data_rec.sfdata5
                                    ,6, cur_data_rec.sfdata6
                                    )
                      INTO    lr_CA_records(ln_curr_index).current_value
                      FROM    dual;
                         lr_CA_records(ln_curr_index).total_amount := cur_data_rec.amount;
                         lr_CA_records(ln_curr_index).subtotal     := cur_data_rec.subtotal_amount;
                         lr_CA_records(ln_curr_index).delivery     := cur_data_rec.delivery;
                         lr_CA_records(ln_curr_index).discounts    := cur_data_rec.promo_and_disc;
                         lr_CA_records(ln_curr_index).prov_tax     := cur_data_rec.cad_county_tax_amount;
                         lr_CA_records(ln_curr_index).gst_tax      := cur_data_rec.cad_state_tax_amount;
                         lr_CA_records(ln_curr_index).order_count  := ln_order_count;
                         prev_inv_num                              := cur_data_rec.inv_number;
                         prev_inv_id                               := cur_data_rec.trx_id;

                      SELECT DECODE(ln_curr_index,
                                    1, cur_data_rec.sfhdr1,
                                    2, cur_data_rec.sfhdr2,
                                    3, cur_data_rec.sfhdr3,
                                    4, cur_data_rec.sfhdr4,
                                    5, cur_data_rec.sfhdr5,
                                    6, cur_data_rec.sfhdr6
                                    )
                      INTO    lr_CA_records(ln_curr_index).current_header
                      FROM    dual;

                   END LOOP;
                ELSE
                   ln_min_changed_index := 0;
                   FOR i IN 1..ln_number_of_sft_hdr
                   LOOP
                      ln_curr_index := (ln_number_of_sft_hdr-i)+1;

                      lr_CA_records(ln_curr_index).prior_value   := lr_CA_records(ln_curr_index).current_value;
                      lr_CA_records(ln_curr_index).prior_header  := lr_CA_records(ln_curr_index).current_header;

                      SELECT DECODE( ln_curr_index
                                    ,1, cur_data_rec.sfdata1
                                    ,2, cur_data_rec.sfdata2
                                    ,3, cur_data_rec.sfdata3
                                    ,4, cur_data_rec.sfdata4
                                    ,5, cur_data_rec.sfdata5
                                    ,6, cur_data_rec.sfdata6
                                    )
                      INTO    lr_CA_records(ln_curr_index).current_value
                      FROM    dual;

                      SELECT DECODE( ln_curr_index
                                    ,1, cur_data_rec.sfhdr1
                                    ,2, cur_data_rec.sfhdr2
                                    ,3, cur_data_rec.sfhdr3
                                    ,4, cur_data_rec.sfhdr4
                                    ,5, cur_data_rec.sfhdr5
                                    ,6, cur_data_rec.sfhdr6
                                    )
                      INTO    lr_CA_records(ln_curr_index).current_header
                      FROM    dual;

                      IF NVL(lr_CA_records(ln_curr_index).current_value, '?') != NVL(lr_CA_records(ln_curr_index).prior_value, '?') THEN
                          ln_min_changed_index := ln_curr_index;
                          IF p_page_by !='B1' THEN
                             IF ln_min_changed_index <=(LENGTH(REPLACE(p_page_by ,'B1' ,''))/2) THEN
                                lr_CA_records(ln_curr_index).pg_break :='Y';
                             ELSE
                                lr_CA_records(ln_curr_index).pg_break :='';
                             END IF;
                          ELSE
                             lr_CA_records(ln_curr_index).pg_break :='';
                          END IF;
                      END IF;
                   END LOOP;

                   FOR i IN 1..ln_number_of_sft_hdr
                   LOOP
                      ln_curr_index := (ln_number_of_sft_hdr-i)+1;
                      IF ln_min_changed_index != 0 AND ln_min_changed_index <= ln_curr_index THEN

                         gc_error_location := 'Calling INSERT_SUMM_ONE_TOTALS for SOFTHDR_TOTALS -- Canadian Invoices --p_total_by !=B1 ';
                         gc_debug          := NULL;

                         INSERT_SUMM_ONE_TOTALS ( p_reqs_id
                                                 ,p_cons_id
                                                 ,p_cust_doc_id
                                                 ,prev_inv_id
                                                 ,prev_inv_num
                                                 ,GET_TRX_SEQ()
                                                 ,'SOFTHDR_TOTALS'
                                                 --,RPAD(lr_CA_records(ln_curr_index).prior_header , 20 ,' ')
                                                 -- ||RPAD(lr_CA_records(ln_curr_index).prior_value, 25 ,' ') -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
                                                 ,RPAD(lr_CA_records(ln_curr_index).prior_header , 20 ,' ')
                                                  ||RPAD(lr_CA_records(ln_curr_index).prior_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                                 ,lr_CA_records(ln_curr_index).subtotal
                                                 ,lr_CA_records(ln_curr_index).delivery
                                                 ,lr_CA_records(ln_curr_index).discounts
                                                 ,(lr_CA_records(ln_curr_index).prov_tax + lr_CA_records(ln_curr_index).gst_tax)
                                                 ,lr_CA_records(ln_curr_index).pg_break
                                                 ,lr_CA_records(ln_curr_index).order_count
                                                 ,p_site_use_id
                                                 );

                         lr_CA_records(ln_curr_index).total_amount := cur_data_rec.amount;
                         lr_CA_records(ln_curr_index).subtotal     := cur_data_rec.subtotal_amount;
                         lr_CA_records(ln_curr_index).delivery     := cur_data_rec.delivery;
                         lr_CA_records(ln_curr_index).discounts    := cur_data_rec.promo_and_disc;
                         lr_CA_records(ln_curr_index).prov_tax     := cur_data_rec.cad_county_tax_amount;
                         lr_CA_records(ln_curr_index).gst_tax      := cur_data_rec.cad_state_tax_amount;
                         lr_CA_records(ln_curr_index).order_count  := 1;
                      ELSE
                         lr_CA_records(ln_curr_index).total_amount := cur_data_rec.amount + lr_CA_records(ln_curr_index).total_amount;
                         lr_CA_records(ln_curr_index).subtotal     := cur_data_rec.subtotal_amount + lr_CA_records(ln_curr_index).subtotal;
                         lr_CA_records(ln_curr_index).delivery     := cur_data_rec.delivery + lr_CA_records(ln_curr_index).delivery;
                         lr_CA_records(ln_curr_index).discounts    := cur_data_rec.promo_and_disc + lr_CA_records(ln_curr_index).discounts;
                         lr_CA_records(ln_curr_index).prov_tax     := cur_data_rec.cad_county_tax_amount + lr_CA_records(ln_curr_index).prov_tax;
                         lr_CA_records(ln_curr_index).gst_tax      := cur_data_rec.cad_state_tax_amount + lr_CA_records(ln_curr_index).gst_tax;
                         lr_CA_records(ln_curr_index).order_count  := lr_CA_records(ln_curr_index).order_count + 1;
                      END IF;
                   END LOOP;
                   prev_inv_num := lr_CA_cur_rec.inv_number;
                   prev_inv_id  := lr_CA_cur_rec.trx_id;
                END IF;

                last_inv_num := lr_CA_cur_rec.inv_number;
                last_inv_id  := lr_CA_cur_rec.trx_id;

             END LOOP;

             FOR i IN 1..ln_number_of_sft_hdr
             LOOP
                ln_curr_index     := (ln_number_of_sft_hdr-i)+1;
                gc_error_location := 'Calling INSERT_SUMM_ONE_TOTALS for SOFTHDR_TOTALS -- 1 -- Canadian Invoices  ';
                gc_debug          := NULL;

                INSERT_SUMM_ONE_TOTALS ( p_reqs_id
                                        ,p_cons_id
                                        ,p_cust_doc_id
                                        ,prev_inv_id
                                        ,prev_inv_num
                                        ,GET_TRX_SEQ()
                                        ,'SOFTHDR_TOTALS'
                                        --,RPAD(lr_CA_records(ln_curr_index).current_header, 20 ,' ')
                                        -- ||RPAD(lr_CA_records(ln_curr_index).current_value, 25 ,' ') -- -- Commented as per Defect 1994 (MOD4B Release 3 Changes)
                                        ,RPAD(lr_CA_records(ln_curr_index).current_header, 20 ,' ')
                                         ||RPAD(lr_CA_records(ln_curr_index).current_value, 44 ,' ') -- Added as per Defect 1994 (MOD4B Release 3 Changes)
                                        ,lr_CA_records(ln_curr_index).subtotal
                                        ,lr_CA_records(ln_curr_index).delivery
                                        ,lr_CA_records(ln_curr_index).discounts
                                        ,(lr_CA_records(ln_curr_index).prov_tax  + lr_CA_records(ln_curr_index).gst_tax)
                                        ,lr_CA_records(ln_curr_index).pg_break
                                        ,lr_CA_records(ln_curr_index).order_count
                                        ,p_site_use_id
                                        );
             END LOOP;

             IF SUBSTR(p_total_by ,1 ,2) ='B1' THEN

                gc_error_location := 'Calling INSERT_SUMM_ONE_TOTALS for BILLTO_TOTALS -- Canadian Invoices -- SUBSTR(p_total_by ,1 ,2) =B1 ';
                gc_debug          := NULL;

                INSERT_SUMM_ONE_TOTALS ( p_reqs_id
                                        ,p_cons_id
                                        ,p_cust_doc_id
                                        ,last_inv_id
                                        ,last_inv_num
                                        ,GET_TRX_SEQ()
                                        ,'BILLTO_TOTALS'
                                        ,RPAD('BILL TO:', 10 ,' ')||p_billing_id
                                        ,ln_billto_subtot
                                        ,ln_billto_delivery
                                        ,ln_billto_discounts
                                        ,(ln_billto_ca_prov_tax  + ln_billto_ca_state_tax)
                                        ,'N'
                                        ,ln_grand_total_orders
                                        ,p_site_use_id
                                        );
             ELSE
                NULL;
             END IF;

             gc_error_location := 'Calling INSERT_SUMM_ONE_TOTALS for GRAND_TOTAL -- Canadian Invoices -- SUBSTR(p_total_by ,1 ,2) =B1 ';
             gc_debug          := NULL;

             INSERT_SUMM_ONE_TOTALS ( p_reqs_id
                                     ,p_cons_id
                                     ,p_cust_doc_id
                                     ,last_inv_id
                                     ,last_inv_num
                                     ,GET_TRX_SEQ()
                                     ,'GRAND_TOTAL'
                                     ,NULL
                                     ,ln_grand_total
                                     ,TO_NUMBER(NULL)
                                     ,TO_NUMBER(NULL)
                                     ,TO_NUMBER(NULL)
                                     ,'N'
                                     ,ln_grand_total_orders
                                     ,p_site_use_id
                                     );

          ELSE
             FOR cur_data_rec IN B1_cur_data
             LOOP
                ln_grand_total         := TO_NUMBER(NULL);
                ln_billto_subtot       := TO_NUMBER(NULL);
                ln_billto_delivery     := TO_NUMBER(NULL);
                ln_billto_discounts    := TO_NUMBER(NULL);
                ln_billto_ca_prov_tax  := TO_NUMBER(NULL);
                ln_billto_ca_state_tax := TO_NUMBER(NULL);
                ln_grand_total_orders  := TO_NUMBER(NULL);
                IF (lb_B1_first_record) THEN
                   FOR B1_total_rec IN CA_B1_totals
                   LOOP
                      ln_grand_total         := B1_total_rec.amount;
                      ln_billto_subtot       := B1_total_rec.subtotal_amount;
                      ln_billto_delivery     := B1_total_rec.delivery;
                      ln_billto_discounts    := B1_total_rec.promo_and_disc;
                      ln_billto_ca_prov_tax  := B1_total_rec.cad_county_tax_amount;
                      ln_billto_ca_state_tax := B1_total_rec.cad_state_tax_amount;
                      ln_grand_total_orders  := B1_total_rec.total_orders;
                   END LOOP;
                   gc_error_location := 'Calling INSERT_SUMM_ONE_TOTALS for BILLTO_TOTALS -- Canadian Invoices -- Only B1';
                   gc_debug := NULL;

                   INSERT_SUMM_ONE_TOTALS ( p_reqs_id
                                           ,p_cons_id
                                           ,p_cust_doc_id
                                           ,cur_data_rec.trx_id
                                           ,cur_data_rec.inv_number
                                           ,GET_TRX_SEQ()
                                           ,'BILLTO_TOTALS'
                                           ,RPAD('BILL TO :', 10 ,' ')||p_billing_id
                                           ,ln_billto_subtot
                                           ,ln_billto_delivery
                                           ,ln_billto_discounts
                                           ,(ln_billto_ca_prov_tax  + ln_billto_ca_state_tax)
                                           ,''
                                           ,ln_grand_total_orders
                                           ,p_site_use_id
                                           );
                   gc_error_location := 'Calling INSERT_SUMM_ONE_TOTALS for GRAND_TOTAL -- Canadian Invoices -- Only B1';
                   gc_debug := NULL;

                   INSERT_SUMM_ONE_TOTALS ( p_reqs_id
                                           ,p_cons_id
                                           ,p_cust_doc_id
                                           ,cur_data_rec.trx_id
                                           ,cur_data_rec.inv_number
                                           ,GET_TRX_SEQ()
                                           ,'GRAND_TOTAL'
                                           ,''
                                           ,ln_grand_total
                                           ,TO_NUMBER(NULL)
                                           ,TO_NUMBER(NULL)
                                           ,TO_NUMBER(NULL)
                                           ,''
                                           ,ln_grand_total_orders
                                           ,p_site_use_id
                                           );
                   lb_B1_first_record :=FALSE;
                   EXIT;
                ELSE
                   NULL;
                END IF;
             END LOOP;
          END IF;
       ELSE
          NULL;
       END IF;
    END GENERATE_SUMM_ONE_SUBTOTALS;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : INSERT_TRANSACTIONS                                                 |
-- | Description : This Procedure is used to insert the transaction information into   |
-- |               the custom table XX_AR_EBL_CONS_TRX_STG.                            |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 17-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE INSERT_TRANSACTIONS( p_sfdata1              IN VARCHAR2
                                  ,p_sfdata2              IN VARCHAR2
                                  ,p_sfdata3              IN VARCHAR2
                                  ,p_sfdata4              IN VARCHAR2
                                  ,p_sfdata5              IN VARCHAR2
                                  ,p_sfdata6              IN VARCHAR2
                                  ,p_sfhdr1               IN VARCHAR2
                                  ,p_sfhdr2               IN VARCHAR2
                                  ,p_sfhdr3               IN VARCHAR2
                                  ,p_sfhdr4               IN VARCHAR2
                                  ,p_sfhdr5               IN VARCHAR2
                                  ,p_sfhdr6               IN VARCHAR2
                                  ,p_inv_id               IN NUMBER
                                  ,p_ord_id               IN NUMBER
                                  --,p_src_id               IN NUMBER
                                  ,p_inv_num              IN VARCHAR2
                                  ,p_inv_type             IN VARCHAR2
                                  ,p_inv_src              IN VARCHAR2
                                  ,p_ord_dt               IN DATE
                                  ,p_ship_dt              IN DATE
                                  ,p_cons_id              IN NUMBER
                                  ,p_cust_doc_id          IN NUMBER
                                  ,p_reqs_id              IN NUMBER
                                  ,p_subtot               IN NUMBER
                                  ,p_delvy                IN NUMBER
                                  ,p_disc                 IN NUMBER
                                  ,p_US_tax_amt           IN NUMBER
                                  ,p_CA_gst_amt           IN NUMBER
                                  ,p_CA_tax_amt           IN NUMBER
                                  ,p_US_tax_id            IN VARCHAR2
                                  ,p_CA_gst_id            IN VARCHAR2
                                  ,p_CA_prov_id           IN VARCHAR2
                                  ,p_insert_seq           IN NUMBER
                                  ,p_doc_tag              IN VARCHAR2
                                  ,p_cbi_num              IN VARCHAR2
                                  ,p_site_use_id          IN NUMBER
                                  ,p_bill_to_address      IN VARCHAR2
                                  ,p_remit_address        IN VARCHAR2
                                  )
    AS
    BEGIN

       INSERT INTO XX_AR_EBL_CONS_TRX_STG ( sfdata1                                   --Removed apps schema Reference
                                                ,sfdata2
                                                ,sfdata3
                                                ,sfdata4
                                                ,sfdata5
                                                ,sfdata6
                                                ,sfhdr1
                                                ,sfhdr2
                                                ,sfhdr3
                                                ,sfhdr4
                                                ,sfhdr5
                                                ,sfhdr6
                                                ,customer_trx_id
                                                ,order_header_id
                                                --,inv_source_id
                                                ,inv_number
                                                ,inv_type
                                                ,inv_source_name
                                                ,order_date
                                                ,ship_date
                                                ,cons_inv_id
                                                ,cust_doc_id
                                                ,request_id
                                                ,subtotal_amount
                                                ,delivery_charges
                                                ,promo_and_disc
                                                ,tax_code
                                                ,tax_amount
                                                ,cad_county_tax_code
                                                ,cad_county_tax_amount
                                                ,cad_state_tax_code
                                                ,cad_state_tax_amount
                                                ,insert_seq
                                                ,doc_type
                                                ,cons_inv_num
                                                ,bill_to_site_use_id
                                                ,bill_to_address
                                                ,remit_to_address
                                                )
                                        VALUES ( p_sfdata1
                                                ,p_sfdata2
                                                ,p_sfdata3
                                                ,p_sfdata4
                                                ,p_sfdata5
                                                ,p_sfdata6
                                                ,p_sfhdr1
                                                ,p_sfhdr2
                                                ,p_sfhdr3
                                                ,p_sfhdr4
                                                ,p_sfhdr5
                                                ,p_sfhdr6
                                                ,p_inv_id
                                                ,p_ord_id
                                                --,p_src_id
                                                ,p_inv_num
                                                ,p_inv_type
                                                ,p_inv_src
                                                ,p_ord_dt
                                                ,p_ship_dt
                                                ,p_cons_id
                                                ,p_cust_doc_id
                                                ,p_reqs_id
                                                ,p_subtot
                                                ,p_delvy
                                                ,p_disc
                                                ,p_US_tax_id
                                                ,p_US_tax_amt
                                                ,p_CA_prov_id
                                                ,p_CA_tax_amt
                                                ,p_CA_gst_id
                                                ,p_CA_gst_amt
                                                ,p_insert_seq
                                                ,p_doc_tag
                                                ,p_cbi_num
                                                ,p_site_use_id
                                                ,p_bill_to_address
                                                ,p_remit_address
                                               );
    END INSERT_TRANSACTIONS;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : INSERT_TRX_LINES                                                    |
-- | Description : This Procedure is used to insert the transaction lines information  |
-- |               into the custom table XX_AR_EBL_CONS_LINES_STG.                     |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 17-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- |      1.1 08-DEC-2015  Havish Kasina           Added new parameters p_dept_code,   |
-- |                                               p_dept_desc and p_dept_sft_hdr      |
-- |                                               Defect 36437 (MOD 4B Release 3)     |
-- |      1.2 03-JUN-2016  Havish Kasina           Added a new parameter p_kit_sku for |
-- |                                               kitting changes (Defect 37675)      |
-- +===================================================================================+
    PROCEDURE INSERT_TRX_LINES ( p_reqs_id                   IN NUMBER
                                ,p_cons_id                   IN NUMBER
                                ,p_cust_doc_id               IN NUMBER
                                ,p_inv_id                    IN NUMBER
                                ,p_line_seq                  IN NUMBER
                                ,p_item_code                 IN VARCHAR2
                                ,p_customer_product_code     IN VARCHAR2
                                ,p_item_description          IN VARCHAR2
                                ,p_manuf_code                IN VARCHAR2
                                ,p_qty                       IN NUMBER
                                ,p_uom                       IN VARCHAR2
                                ,p_unit_price                IN NUMBER
                                ,p_extended_price            IN NUMBER
                                ,p_line_comments             IN VARCHAR2
                                ,p_site_use_id               IN NUMBER
                                ,p_gsa_comments              IN VARCHAR2
								,p_dept_code                 IN VARCHAR2 -- Added for the Defect 36437
								,p_dept_desc                 IN VARCHAR2 -- Added for the Defect 36437
								,p_dept_sft_hdr              IN VARCHAR2 -- Added for the Defect 36437
								,p_kit_sku                   IN VARCHAR2 -- Added for Kitting, Defect# 37675
								,p_kit_sku_desc              IN VARCHAR2 -- Added for Kitting, Defect# 37675
								,p_sku_level_tax             IN NUMBER -- Added for SKU Level Tax NAIT-58403
                                )
    AS
    BEGIN
       INSERT INTO XX_AR_EBL_CONS_LINES_STG ( request_id
                                             ,cons_inv_id
                                             ,cust_doc_id
                                             ,customer_trx_id
                                             ,line_seq
                                             ,item_code
                                             ,customer_product_code
                                             ,item_description
                                             ,manuf_code
                                             ,qty
                                             ,uom
                                             ,unit_price
                                             ,extended_price
                                             ,line_comments
                                             ,bill_to_site_use_id
                                             ,gsa_comments
											 ,dept_code -- Added for the Defect 36437
											 ,dept_desc -- Added for the Defect 36437
											 ,dept_sft_hdr -- Added for the Defect 36437
											 ,kit_sku     -- Added for Kitting, Defect# 37675
											 ,kit_sku_desc -- Added for Kitting, Defect# 37675
											 ,sku_level_tax -- Added for SKU Level Tax NAIT-58403  
                                             )
                                     VALUES ( p_reqs_id
                                             ,p_cons_id
                                             ,p_cust_doc_id
                                             ,p_inv_id
                                             ,p_line_seq
                                             ,p_item_code
                                             ,p_customer_product_code
                                             ,p_item_description
                                             ,p_manuf_code
                                             ,p_qty
                                             ,p_uom
                                             ,p_unit_price
                                             ,p_extended_price
                                             ,p_line_comments
                                             ,p_site_use_id
                                             ,p_gsa_comments
											 ,p_dept_code -- Added for the Defect 36437
											 ,p_dept_desc -- Added for the Defect 36437
											 ,p_dept_sft_hdr -- Added for the Defect 36437
											 ,p_kit_sku   -- Added for Kitting, Defect# 37675
											 ,p_kit_sku_desc -- Added for Kitting, Defect# 37675
											 ,p_sku_level_tax -- Added for SKU Level Tax NAIT-58403
                                             );
    END INSERT_TRX_LINES;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : INSERT_TRX_ROWS                                                     |
-- | Description : This Procedure is used to insert the transaction lines information  |
-- |               into the custom table XX_AR_EBL_CONS_TRX_ROWS_STG.                  |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 17-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE INSERT_TRX_ROWS ( p_reqs_id         IN NUMBER
                               ,p_cons_id         IN NUMBER
                               ,p_cust_doc_id     IN NUMBER
                               ,p_line_type       IN VARCHAR2
                               ,p_line_seq        IN NUMBER
                               ,p_sf_text         IN VARCHAR2
                               ,p_pg_brk          IN VARCHAR2
                               ,p_ordnum_attr1    IN VARCHAR2
                               ,p_ord_dt_attr2    IN VARCHAR2
                               ,p_subtotal        IN VARCHAR2
                               ,p_delivery        IN VARCHAR2
                               ,p_discounts       IN VARCHAR2
                               ,p_tax             IN VARCHAR2
                               ,p_total           IN VARCHAR2
                               ,p_sf_data1        IN VARCHAR2
                               ,p_sf_data2        IN VARCHAR2
                               ,p_sf_data3        IN VARCHAR2
                               ,p_sf_data4        IN VARCHAR2
                               ,p_sf_data5        IN VARCHAR2
                               ,p_invoice_id      IN NUMBER
                               ,p_site_use_id     IN NUMBER
                               )
    AS
    BEGIN
       INSERT INTO XX_AR_EBL_CONS_TRX_ROWS_STG ( request_id
                                                ,cons_inv_id
                                                ,cust_doc_id
                                                ,line_type
                                                ,line_seq
                                                ,sf_text
                                                ,page_break
                                                ,attribute1
                                                ,attribute2
                                                ,subtotal
                                                ,delivery
                                                ,discounts
                                                ,tax
                                                ,total
                                                ,sfdata1
                                                ,sfdata2
                                                ,sfdata3
                                                ,sfdata4
                                                ,sfdata5
                                                ,attribute3
                                                ,bill_to_site_use_id
                                                )
                                        VALUES ( p_reqs_id
                                                ,p_cons_id
                                                ,p_cust_doc_id
                                                ,p_line_type
                                                ,p_line_seq
                                                ,p_sf_text
                                                ,p_pg_brk
                                                ,p_ordnum_attr1
                                                ,p_ord_dt_attr2
                                                ,p_subtotal
                                                ,p_delivery
                                                ,p_discounts
                                                ,p_tax
                                                ,p_total
                                                ,p_sf_data1
                                                ,p_sf_data2
                                                ,p_sf_data3
                                                ,p_sf_data4
                                                ,p_sf_data5
                                                ,p_invoice_id
                                                ,p_site_use_id
                                                );
    END INSERT_TRX_ROWS;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : INSERT_TRX_TOTALS                                                   |
-- | Description : This Procedure is used to insert the transaction's sub total        |
-- |               information into the custom table XX_AR_EBL_CONS_TRX_TOTAL_STG.     |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 17-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE INSERT_TRX_TOTALS ( p_reqs_id        IN NUMBER
                                 ,p_cons_id        IN NUMBER
                                 ,p_cust_doc_id    IN NUMBER
                                 ,p_inv_id         IN NUMBER
                                 ,p_linetype       IN VARCHAR2
                                 ,p_line_seq       IN NUMBER
                                 ,p_trx_num        IN VARCHAR2
                                 ,p_sftext         IN VARCHAR2
                                 ,p_sfamount       IN NUMBER
                                 ,p_page_brk       IN VARCHAR2
                                 ,p_ord_count      IN NUMBER
                                 ,p_prov_tax       IN VARCHAR2
                                 ,p_site_use_id    IN NUMBER
                                 )
    AS
    BEGIN
       INSERT INTO XX_AR_EBL_CONS_TRX_TOTAL_STG ( request_id
                                                 ,cons_inv_id
                                                 ,cust_doc_id
                                                 ,customer_trx_id
                                                 ,line_type
                                                 ,line_seq
                                                 ,trx_number
                                                 ,sf_text
                                                 ,sf_amount
                                                 ,page_break
                                                 ,order_count
                                                 ,ca_prov_tax_code
                                                 ,bill_to_site_use_id
                                                 )
                                         VALUES ( p_reqs_id
                                                 ,p_cons_id
                                                 ,p_cust_doc_id
                                                 ,p_inv_id
                                                 ,p_linetype
                                                 ,p_line_seq
                                                 ,p_trx_num
                                                 ,p_sftext
                                                 ,p_sfamount
                                                 ,p_page_brk
                                                 ,p_ord_count
                                                 ,p_prov_tax
                                                 ,p_site_use_id
                                                 );
    END INSERT_TRX_TOTALS;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : INSERT_SUMM_ONE_TOTALS                                              |
-- | Description : This Procedure is used to insert the transaction information into   |
-- |               the custom table XX_AR_EBL_CONS_TRX_STG for Summary and One format. |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 17-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE INSERT_SUMM_ONE_TOTALS ( p_reqs_id       IN NUMBER
                                      ,p_cons_id       IN NUMBER
                                      ,p_cust_doc_id   IN NUMBER
                                      ,p_inv_id        IN NUMBER
                                      ,p_inv_num       IN VARCHAR2
                                      ,p_line_seq      IN NUMBER
                                      ,p_total_type    IN VARCHAR2
                                      ,p_inv_source    IN VARCHAR2
                                      ,p_subtotl       IN NUMBER
                                      ,p_delvy         IN NUMBER
                                      ,p_discounts     IN NUMBER
                                      ,p_tax           IN NUMBER
                                      ,p_page_brk      IN VARCHAR2
                                      ,p_ord_count     IN NUMBER
                                      ,p_site_use_id   IN NUMBER
                                      )
    AS
    BEGIN
       INSERT INTO XX_AR_EBL_CONS_TRX_STG ( request_id
                                           ,cons_inv_id
                                           ,cust_doc_id
                                           ,customer_trx_id
                                           ,inv_number
                                           ,insert_seq
                                           ,inv_type
                                           ,inv_source_name
                                           ,subtotal_amount
                                           ,delivery_charges
                                           ,promo_and_disc
                                           ,tax_amount
                                           ,tax_code
                                           ,order_header_id
                                           ,bill_to_site_use_id
                                           )
                                    VALUES ( p_reqs_id
                                            ,p_cons_id
                                            ,p_cust_doc_id
                                            ,p_inv_id
                                            ,p_inv_num
                                            ,p_line_seq
                                            ,p_total_type
                                            ,p_inv_source
                                            ,p_subtotl
                                            ,p_delvy
                                            ,p_discounts
                                            ,p_tax
                                            ,p_page_brk
                                            ,p_ord_count
                                            ,p_site_use_id
                                            );
    END INSERT_SUMM_ONE_TOTALS;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : RETURN_ADDRESS                                                      |
-- | Description : This funciton is used to get the return address for the Consolidated|
-- |               Bill.                                                               |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 01-APR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    FUNCTION RETURN_ADDRESS RETURN VARCHAR2
    IS
       lc_address1       VARCHAR2(40);
       lc_address2       VARCHAR2(40);
       lc_address3       VARCHAR2(40);
       lc_address4       VARCHAR2(40);
       lc_city           VARCHAR2(40);
       lc_state          VARCHAR2(40);
       lc_postal_code    VARCHAR2(40);
       lc_province       VARCHAR2(40);
       lc_country        VARCHAR2(10);

       lc_description    fnd_territories_vl.territory_short_name%TYPE;
       lc_postal         VARCHAR2(25);
       lc_state_pr       VARCHAR2(25);
       lc_address        VARCHAR2(1000);
       gc_error_location VARCHAR2(2000);
       gc_debug          VARCHAR2(1000);

    BEGIN

       gc_error_location := 'Getting RETURN ADDRESS';
       gc_debug := '';

       SELECT return_address_line1 return_address_line1
             ,return_address_line2 return_address_line2
             ,return_city          return_city
             ,return_state         return_state
             ,return_postal_code   return_postal_code
       INTO   lc_address1
             ,lc_address2
             ,lc_city
             ,lc_state
             ,lc_postal_code
       FROM   xx_ar_sys_info;         --Removed apps schema Reference

       IF (LENGTH(lc_postal_code) <= 5) THEN
          lc_postal := lc_postal_code;
       ELSE
          lc_postal := SUBSTR(lc_postal_code,1,5)||'-'||SUBSTR(REPLACE(lc_postal_code ,'-'),6);
       END IF;

       IF (lc_address1 IS NOT NULL) THEN
          lc_address :=lc_address1;
       END IF;

       IF (lc_address2 IS NOT NULL) THEN
          lc_address := lc_address||chr(10)||lc_address2;
       END IF;
       RETURN (lc_address
               ||chr(10)||lc_city||' '||lc_state
               ||'  '||lc_postal||chr(10)
               );
    EXCEPTION
       WHEN NO_DATA_FOUND THEN
          fnd_file.put_line(fnd_file.log ,SQLERRM);
          RETURN NULL;
       WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log , 'Error While: ' || gc_error_location||' '|| SQLERRM);
          fnd_file.put_line(fnd_file.log , 'Debug:' || gc_debug);
          fnd_file.put_line(fnd_file.log ,SQLERRM); RETURN NULL;
    END RETURN_ADDRESS;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : GET_TRX_SEQ                                                         |
-- | Description : This funciton is used to sequence number from                       |
-- |               XX_AR_EBL_CONS_TRX_STG_s sequence.                                  |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 01-APR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    FUNCTION GET_TRX_SEQ
    RETURN NUMBER
    IS
       ln_trx_seq NUMBER :=0;
    BEGIN
       SELECT XX_AR_EBL_CONS_TRX_STG_s.NEXTVAL
       INTO   ln_trx_seq
       FROM   dual;
       RETURN ln_trx_seq;
    EXCEPTION
       WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log ,'Error occured in GET_TRX_SEQ.when others');
          fnd_file.put_line(fnd_file.log ,SQLERRM);
          RETURN 0;
    END GET_TRX_SEQ;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : GET_ROWS_SEQ                                                        |
-- | Description : This funciton is used to sequence number from                       |
-- |               XX_AR_EBL_CONS_TRX_ROWS_STG_S sequence.                             |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 01-APR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    FUNCTION GET_ROWS_SEQ
    RETURN NUMBER
    IS
       ln_rows_seq NUMBER :=0;
    BEGIN
       SELECT XX_AR_EBL_CONS_TRX_ROWS_STG_S.NEXTVAL
       INTO   ln_rows_seq
       FROM   dual;
       RETURN ln_rows_seq;
    EXCEPTION
       WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log ,'Error occured in GET_TRX_SEQ.when others');
          fnd_file.put_line(fnd_file.log ,SQLERRM);
          RETURN 0;
    END GET_ROWS_SEQ;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : AFTERREPORT                                                         |
-- | Description : This function is used to do all the post processing like bursting   |
-- |               inserting BLOB file into table after the XML data is generated      |
-- |               for the current thread.                                             |
-- | Parameters  :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 16-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- |      1.1 08-DEC-2015  Havish Kasina           Changes added for the Defect 36437  |
-- |                                               ()MOD 4B Release 3)                 |
-- |      1.2 03-JUN-2016  Havish Kasina           Changes added for the Defect 37675  |
-- |                                               (Kitting Changes)                   |
-- +===================================================================================+
    FUNCTION afterreport
    RETURN BOOLEAN
    AS

       ln_request_id     NUMBER;
       lb_debug          BOOLEAN;

    BEGIN

       IF p_debug_flag = 'Y' THEN
          lb_debug := TRUE;
       ELSE
          lb_debug := FALSE;
       END IF;

       ln_request_id  := FND_GLOBAL.CONC_REQUEST_ID;

       gc_error_location := 'Insert Data into xx_ar_ebl_cons_trx_hist Table';
       INSERT INTO xx_ar_ebl_cons_trx_hist
       SELECT  request_id
              ,cons_inv_id
              ,cust_doc_id
              ,customer_trx_id
              ,order_header_id
              ,inv_number
              ,inv_type
              ,inv_source_id
              ,inv_source_name
              ,order_date
              ,ship_date
              ,sfhdr1
              ,sfdata1
              ,sfhdr2
              ,sfdata2
              ,sfhdr3
              ,sfdata3
              ,sfhdr4
              ,sfdata4
              ,sfhdr5
              ,sfdata5
              ,sfhdr6
              ,sfdata6
              ,subtotal_amount
              ,delivery_charges
              ,promo_and_disc
              ,tax_code
              ,tax_amount
              ,cad_county_tax_code
              ,cad_county_tax_amount
              ,cad_state_tax_code
              ,cad_state_tax_amount
              ,insert_seq
              ,attribute1
              ,attribute2
              ,attribute3
              ,attribute4
              ,attribute5
              ,attribute6
              ,attribute7
              ,attribute8
              ,attribute9
              ,attribute10
              ,attribute11
              ,attribute12
              ,attribute13
              ,attribute14
              ,attribute15
              ,org_id
              ,cons_inv_num
              ,bill_to_site_use_id
              ,doc_type
              ,bill_to_address
              ,remit_to_address
              ,SYSDATE
              ,ln_request_id
       FROM    xx_ar_ebl_cons_trx_stg
       WHERE   request_id    = p_batch_id;

       gc_error_location := 'Insert Data into xx_ar_ebl_cons_lines_hist Table';
       INSERT INTO xx_ar_ebl_cons_lines_hist
       SELECT  request_id
              ,cons_inv_id
              ,cust_doc_id
              ,customer_trx_id
              ,line_seq
              ,item_code
              ,customer_product_code
              ,item_description
              ,manuf_code
              ,qty
              ,uom
              ,unit_price
              ,extended_price
              ,org_id
              ,line_comments
              ,bill_to_site_use_id
              ,gsa_comments
              ,SYSDATE
              ,ln_request_id
			  ,dept_code -- Added for Defect 36437
			  ,dept_desc -- Added for Defect 36437
			  ,dept_sft_hdr -- Added for Defect 36437
			  ,kit_sku   -- Added for Kitting, Defect# 37675
			  ,kit_sku_desc   -- Added for Kitting, Defect# 37675
			  ,sku_level_tax  -- Added for SKU Level Tax NAIT-58403
       FROM    xx_ar_ebl_cons_lines_stg
       WHERE   request_id     = p_batch_id;

       gc_error_location := 'Insert Data into xx_ar_ebl_cons_trx_total_hist Table';
       INSERT INTO xx_ar_ebl_cons_trx_total_hist
       SELECT  request_id
              ,cons_inv_id
              ,cust_doc_id
              ,customer_trx_id
              ,line_type
              ,line_seq
              ,trx_number
              ,sf_text
              ,sf_amount
              ,page_break
              ,order_count
              ,bill_to_site_use_id
              ,org_id
              ,ca_prov_tax_code
              ,SYSDATE
              ,ln_request_id
       FROM    xx_ar_ebl_cons_trx_total_stg
       WHERE   request_id    = p_batch_id;

       gc_error_location := 'Insert Data into xx_ar_ebl_cons_trx_rows_hist Table';
       INSERT INTO xx_ar_ebl_cons_trx_rows_hist
       SELECT  request_id
              ,cons_inv_id
              ,cust_doc_id
              ,line_type
              ,line_seq
              ,sf_text
              ,sfdata1
              ,sfdata2
              ,sfdata3
              ,sfdata4
              ,sfdata5
              ,subtotal
              ,delivery
              ,discounts
              ,tax
              ,total
              ,page_break
              ,attribute1
              ,attribute2
              ,attribute3
              ,attribute4
              ,attribute5
              ,attribute6
              ,attribute7
              ,attribute8
              ,attribute9
              ,attribute10
              ,bill_to_site_use_id
              ,org_id
              ,SYSDATE
              ,ln_request_id
       FROM    xx_ar_ebl_cons_trx_rows_stg
       WHERE   request_id    = p_batch_id;

       gc_error_location := 'Delete Data from xx_ar_ebl_cons_trx_stg Table';
       DELETE xx_ar_ebl_cons_trx_stg
       WHERE  request_id = p_batch_id;

       gc_error_location := 'Delete Data from xx_ar_ebl_cons_lines_stg Table';
       DELETE xx_ar_ebl_cons_lines_stg
       WHERE  request_id = p_batch_id;

       gc_error_location := 'Delete Data from xx_ar_ebl_cons_trx_rows_stg Table';
       DELETE xx_ar_ebl_cons_trx_rows_stg
       WHERE  request_id = p_batch_id;

       gc_error_location := 'Delete Data from xx_ar_ebl_cons_trx_total_stg Table';
       DELETE xx_ar_ebl_cons_trx_total_stg
       WHERE  request_id = p_batch_id;

       RETURN TRUE;

    EXCEPTION
       WHEN OTHERS THEN

          XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                 ,TRUE
                                                 ,'Error While: ' || gc_error_location||' '|| SQLERRM
                                                 );
          XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                 ,TRUE
                                                 ,CHR(13)||'Debug:' || gc_debug
                                                 );

          RETURN FALSE;
    END afterreport;

 END XX_AR_EBL_CONS_EPDF_PKG;
/
SHOW ERRORS;