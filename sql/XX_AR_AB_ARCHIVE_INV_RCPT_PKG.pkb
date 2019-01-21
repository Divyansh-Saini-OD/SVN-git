CREATE OR REPLACE
PACKAGE BODY XX_AR_AB_ARCHIVE_INV_RCPT_PKG
  --+======================================================================+
  --|      Office Depot -                                                  |
  --+======================================================================+
  --|Name       : XX_AR_AB_ARCHIVE_INV_RCPT_PKG.pkb                        |
  --|Description: This Package is used for fetching all the likely         |
  --|             AB invoices/CMs and receipts for archiving               |
  --|                                                                      |
  --|                                                                      |
  --|                                                                      |
  --|Change Record:                                                        |
  --|===============                                                       |
  --| 05-Apr-2018   Capgemini  Intial Draft                                |
  --+======================================================================+
  --+=======================================================================+
  --| Name : POPULATE_AB_INV_RCPT                                           |
  --| Description : The POPULATE_AB_INV_RCPT proc will perform the following|
  --|                                                                       |
  --|             1. Fetch all the receipts for a particular set of         |
  --|                invoices                                               |
  --|             2. In the recursive fashion, pick all the corresponding   |
  --|                invoices/CMs                                           |
  --|             3. Check if the entire invoice-CM-receipt transaction     |
  --|                chain is fetched                                       |
  --|                                                                       |
  --| Parameters : p_lvl1_rowcnt   -- This parameter is used to fetch the   |
  --|                                 initial first level data, based on    |
  --|                                 this the further chain will be fetched|
  --+=======================================================================+
AS
PROCEDURE POPULATE_AB_INV_RCPT(
    x_errbuf OUT VARCHAR2 ,
    x_retcode OUT VARCHAR2 ,
    p_lvl1_rowcnt IN NUMBER)
IS
  ln_user_id        NUMBER := NVL(FND_GLOBAL.USER_ID,-1);
  ln_count          NUMBER := 0;
  ln_total_count    NUMBER := 0;
  ln_level1_count   NUMBER := 0;
  ln_level_num      NUMBER := 0;
  ln_prev_level_num NUMBER := 0;
  l_exeception      EXCEPTION;
BEGIN
  FND_FILE.Put_line(FND_FILE.LOG,'Begin of program');
  FND_FILE.Put_line(FND_FILE.LOG,'1st Level Insert');
  DELETE FROM XX_AR_INVOICES_CAND;
  COMMIT;
  IF p_lvl1_rowcnt  IS NULL THEN
    ln_level1_count := 10;
  ELSE
    ln_level1_count := p_lvl1_rowcnt;
  END IF;
  --level 1 insert query
  BEGIN
    INSERT
    INTO XX_AR_INVOICES_CAND
      (
        CUSTOMER_TRX_ID ,
        TRX_NUMBER ,
        TRX_DATE ,
        TYPE ,
        POST_TO_GL ,
        ORG_ID ,
        CONS_INV_ID ,
        COMPLETE_FLAG,
        BATCH_SOURCE_ID ,
        CASH_RECEIPT_ID ,
        RECEIPT_NUMBER ,
        REVERSAL_DATE,
        STATUS ,
        FACTOR_FLAG,
        POSTING_CONTROL_ID,
        GL_DATE ,
        RECEIPT_ORG_ID,
        pay_from_customer ,
        RECEIVABLE_APPLICATION_ID ,
        applied_customer_trx_id ,
        RECE_APPL_STATUS,
        APPLICATION_TYPE,
        level_num,
        level_type
      )
    SELECT DISTINCT CUSTOMER_TRX_ID,
      TRX_NUMBER,
      TRX_DATE,
      TYPE,
      POST_TO_GL,
      ORG_ID,
      CONS_INV_ID,
      COMPLETE_FLAG,
      BATCH_SOURCE_ID,
      cash_receipt_id,
      RECEIPT_NUMBER,
      REVERSAL_DATE,
      STATUS,
      FACTOR_FLAG,
      POSTING_CONTROL_ID,
      GL_DATE,
      RECEIPT_ORG_ID,
      pay_from_customer,
      RECEIVABLE_APPLICATION_ID,
      applied_customer_Trx_id,
      RECE_APPL_STATUS,
      application_type,
      1,
      'FIRST'
    FROM
      (SELECT
        /*+ index(ooh, OE_ORDER_HEADERS_N7) index(acit, AR_CONS_INV_TRX_T1) use_nl(aci acit) */
        CT.CUSTOMER_TRX_ID,
        CT.TRX_NUMBER,
        CT.TRX_DATE,
        ctt.type ,
        NVL(ctt.post_to_gl,'N') post_to_gl,
        CT.ORG_ID,
        ACI.CONS_INV_ID,
        CT.complete_flag,
        CT.BATCH_SOURCE_ID,
        araa.cash_receipt_id,
        araa.receipt_number,
        araa.reversal_Date,
        acrha.status status,
        acrha.factor_flag,
        acrha.posting_control_id,
        acrha.gl_date gl_date,
        araa.org_id RECEIPT_ORG_ID,
        araa.pay_from_customer,
        acra.receivable_application_id,
        acra.applied_customer_Trx_id,
        acra.status RECE_APPL_STATUS,
        acra.application_type
      FROM APPS.RA_CUST_TRX_TYPES_ALL CTT,
        APPS.RA_CUSTOMER_TRX_ALL CT,
        --APPS.RA_CUSTOMER_TRX_ALL PARTITION (RA_CUSTOMER_TRX_200907) CT,
        APPS.RA_TERMS_TL RT,
        APPS.AR_CONS_INV_ALL ACI,
        APPS.AR_CONS_INV_TRX_ALL ACIT,
        APPS.OE_ORDER_HEADERS_ALL OOH,
        APPS.ar_cash_receipts_all araa,
        APPS.AR_CASH_RECEIPT_HISTORY_ALL acrha,
        APPS.ar_receivable_applications_all acra
      WHERE ct.trx_date               <= TRUNC(sysdate-(365*4),'YEAR')-1
      AND ct.cust_Trx_type_id          = ctt.cust_Trx_type_id
      AND NVL(ct.org_id,-1)            = NVL(ctt.org_id,-1)
      AND ooh.payment_term_id          = rt.term_id
      AND ooh.orig_sys_document_ref    = ct.trx_number
      AND ct.customer_Trx_id           = acit.customer_trx_id (+)
      AND acit.cons_inv_id             = aci.cons_inv_id (+)
      AND rt.name NOT                 IN ('CONVERSION','IMMEDIATE','SA_DEPOSIT' )
      AND batch_source_id NOT         IN (1007,1003,1008,3041)
      AND araa.cash_receipt_id         = acra.cash_receipt_id
      AND acra.applied_customer_Trx_id = ct.customer_Trx_id
      AND araa.type                   <> 'MISC'
      AND acrha.current_record_flag    = 'Y'
      AND araa.cash_receipt_id         = acrha.cash_receipt_id
      AND TRUNC(acrha.gl_date)        <= TRUNC(SYSDATE-(365*4),'YEAR')-1
      AND TRUNC(acra.gl_date)         <= TRUNC(sysdate-(365*4),'YEAR')-1
      AND ACRA.STATUS                                IN ('APP', 'ACTIVITY')
      AND NOT EXISTS
        (SELECT 1
        FROM APPS.xx_ar_intstorecust_otc XAIO
        WHERE XAIO.cust_account_id = ct.bill_to_customer_id
        )
      AND rownum < ln_level1_count
      );
    ln_total_count := SQL%ROWCOUNT;
  EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.Put_line(FND_FILE.LOG,'Exception in 1st level Insert: ' || SQLERRM);
    RAISE l_exeception;
  END;
  COMMIT;
  FND_FILE.Put_line(FND_FILE.LOG,'1st level data inserted successfully');
  ln_count          := 1;
  ln_level_num      := 2;
  ln_prev_level_num := 1;
  WHILE ln_count    <>0
  LOOP
    BEGIN
      INSERT
      INTO xx_ar_invoices_cand
        (
          LEVEL_NUM,
          cash_receipt_id,
          CUSTOMER_TRX_ID
        )
        ( SELECT DISTINCT LEVEL_NUM,
            CASH_RECEIPT_ID,
            CUSTOMER_TRX_ID
          FROM
            (SELECT ln_level_num level_num,
              cash_receipt_id,
              customer_trx_id
            FROM AR_RECEIVABLE_APPLICATIONS_ALL ARAA
            WHERE araa.applied_customer_trx_id IN
              (SELECT customer_trx_id
              FROM xx_ar_invoices_cand
              WHERE level_num = ln_prev_level_num
              )
            AND araa.status                        IN ('APP','ACTIVITY')
            AND TRUNC(araa.gl_date) <= TRUNC(sysdate-(365*4),'YEAR')-1
            AND NOT EXISTS
              (SELECT 1 FROM xx_ar_invoices_cand WHERE CASH_RECEIPT_ID = araa.CASH_RECEIPT_ID
              )
            UNION ALL
            SELECT ln_level_num level_num,
              cash_receipt_id,
              customer_trx_id
            FROM ar_receivable_applications_all araa
            WHERE APPLIED_CUSTOMER_TRX_ID IN
              (SELECT customer_trx_id
              FROM xx_ar_invoices_cand
              WHERE level_num = ln_prev_level_num
              )
            AND araa.status                        IN ('APP','ACTIVITY')
            AND TRUNC(araa.gl_date) <= TRUNC(sysdate-(365*4),'YEAR')-1
            AND NOT EXISTS
              (SELECT 1 FROM xx_ar_invoices_cand WHERE customer_trx_id = araa.customer_trx_id
              )
            UNION ALL
            SELECT ln_level_num,
              cash_receipt_id,
              applied_customer_trx_id customer_trx_id
            FROM ar_receivable_applications_all araa
            WHERE CUSTOMER_TRX_ID IN
              (SELECT
                /*+ cardinality (b,10) */
                customer_trx_id
              FROM xx_ar_invoices_cand b
              WHERE level_num = ln_prev_level_num
              )
            AND araa.status                        IN ('APP','ACTIVITY')
            AND TRUNC(araa.gl_date) <= TRUNC(sysdate-(365*4),'YEAR')-1
            AND NOT EXISTS
              (SELECT 1 FROM xx_ar_invoices_cand WHERE CASH_RECEIPT_ID = araa.CASH_RECEIPT_ID
              )
            UNION ALL
            SELECT ln_level_num,
              cash_receipt_id,
              applied_customer_trx_id customer_trx_id
            FROM ar_receivable_applications_all araa
            WHERE CUSTOMER_TRX_ID IN
              (SELECT
                /*+ cardinality (b,10) */
                customer_trx_id
              FROM xx_ar_invoices_cand b
              WHERE level_num = ln_prev_level_num
              )
            AND araa.status                        IN ('APP','ACTIVITY')
            AND TRUNC(araa.gl_date) <= TRUNC(sysdate-(365*4),'YEAR')-1
            AND NOT EXISTS
              (SELECT 1 FROM xx_ar_invoices_cand WHERE customer_trx_id = araa.customer_trx_id
              )
            UNION ALL
            SELECT ln_level_num,
              NULL cash_receipt_id,
              applied_customer_trx_id customer_trx_id
            FROM ar_receivable_applications_all araa
            WHERE CASH_RECEIPT_ID IN
              (SELECT cash_receipt_id
              FROM xx_ar_invoices_cand
              WHERE level_num = ln_prev_level_num
              )
            AND araa.status                        IN ('APP','ACTIVITY')
            AND TRUNC(araa.gl_date) <= TRUNC(sysdate-(365*4),'YEAR')-1
            AND NOT EXISTS
              (SELECT 1 FROM xx_ar_invoices_cand WHERE CASH_RECEIPT_ID = araa.CASH_RECEIPT_ID
              )
            UNION ALL
            SELECT ln_level_num,
              NULL cash_receipt_id,
              applied_customer_trx_id customer_trx_id
            FROM ar_receivable_applications_all araa
            WHERE CASH_RECEIPT_ID IN
              (SELECT cash_receipt_id
              FROM xx_ar_invoices_cand
              WHERE level_num = ln_prev_level_num
              )
            AND araa.status                        IN ('APP','ACTIVITY')
            AND TRUNC(araa.gl_date) <= TRUNC(sysdate-(365*4),'YEAR')-1
            AND NOT EXISTS
              (SELECT 1 FROM xx_ar_invoices_cand WHERE customer_trx_id = araa.customer_trx_id
              )
            ) xx_inv_rcp
          WHERE NOT EXISTS
            (SELECT 1 FROM xx_ar_invoices_cand WHERE CUSTOMER_TRX_ID = xx_inv_rcp.CUSTOMER_TRX_ID
            )
          AND NOT EXISTS
            (SELECT 1 FROM xx_ar_invoices_cand WHERE CASH_RECEIPT_ID = xx_inv_rcp.CASH_RECEIPT_ID
            )
        );
      ln_count := SQL%ROWCOUNT;
      FND_FILE.Put_line(FND_FILE.LOG,'ln_count '|| ln_count);
      COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
      FND_FILE.Put_line(FND_FILE.LOG,'Exception: Level '||ln_level_num||' Insert for Receipts ::' || SQLERRM);
      RAISE l_exeception;
    END;
    FND_FILE.Put_line(FND_FILE.LOG,'Completed Level '||ln_level_num||' , ln_count'|| ln_count);
    IF ln_count = 0 THEN
      EXIT;
    ELSE
      ln_prev_level_num := ln_level_num;
      ln_level_num      := ln_level_num + 1;
    END IF;
  END LOOP;
EXCEPTION
WHEN l_exeception THEN
  FND_FILE.Put_line(FND_FILE.LOG,'Exception Occcured inside '||ln_level_num||' level Insert'||SQLERRM);
WHEN OTHERS THEN
  FND_FILE.Put_line(FND_FILE.LOG,'Unexpected Error Occured'||SQLERRM);
END POPULATE_AB_INV_RCPT;
END XX_AR_AB_ARCHIVE_INV_RCPT_PKG;