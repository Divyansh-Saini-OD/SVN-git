create or replace 
PACKAGE BODY XX_AR_LBX_BAT_RPT_PKG AS
gn_org_id                     NUMBER :=FND_PROFILE.VALUE ('ORG_ID');


-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_AR_LBX_BAT_RPT_PKG                                                              |
-- |  Description:  OD: AR Lockbox Batch Report                                                 |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         20-Apr-2010  Joe Klein        Initial version                                  |
-- | 1.1         11-Sep-2013  Ramya Kuttappa   R1165 - Included changes for R12 Upgrade retrofit|
-- | 1.2         26-Oct-2015  Vasu Raparla     Removed Schema References for R12.2              |
-- | 1.3         28-Jun-2017  Rohit Nanda      Defect# - 42504 - Performance Issue resolved     |
-- | 1.4         30-JUL-2018  Sripal Reddy     Defect# - 45209 - All Parameter issue Resolved   |
-- +============================================================================================+

-- +============================================================================================+
-- |  Name: XX_AR_LBX_BAT_RPT_PKG.XX_MAIN_RPT                                                   |
-- |  Description: This pkg.procedure will extract Lockbox data for reporting.                  |
-- =============================================================================================|
  PROCEDURE XX_MAIN_RPT
  (errbuff OUT NOCOPY VARCHAR2,
   retcode OUT NOCOPY NUMBER,
   p_bank_acct_num IN VARCHAR2 DEFAULT NULL,
   p_lockbox_number IN VARCHAR2 DEFAULT NULL,
   p_gl_date_from IN VARCHAR2 DEFAULT NULL,
   p_gl_date_to IN VARCHAR2 DEFAULT NULL,
   p_deposit_date_from IN VARCHAR2 DEFAULT NULL,
   p_deposit_date_to IN VARCHAR2 DEFAULT NULL,
   p_batch_status IN VARCHAR2 DEFAULT NULL)
  IS
    v_out_header1  VARCHAR2(1000);
    v_out_header2  VARCHAR2(1000);
    v_out_header3  VARCHAR2(1000);
    v_log_msg      VARCHAR2(100);
    v_profile_value VARCHAR2(100);
    v_oper_unit VARCHAR2(100);
    v_lang VARCHAR2(100);
    v_period_num_from gl_period_statuses.effective_period_num%TYPE;
    v_period_num_to   gl_period_statuses.effective_period_num%TYPE;
    i NUMBER;

/***************************************************
 Start commented by Rohit Nanda on 28-Jun-2017 V1.3
***************************************************/

/*    CURSOR c_out IS
    SELECT out_rec
    FROM
      (SELECT bv.gl_date||chr(9)||
              bv.batch_date||chr(9)||
              bv.deposit_date||chr(9)||
              lb.lockbox_number||chr(9)||
              bv.control_amount||chr(9)||
              bv.control_count||chr(9)||
              NVL((SELECT SUM(ra.amount_applied)
                 FROM ar_receivable_applications_all ra,
                      ar_cash_receipt_history_all crh1,
                      ar_batches_all b1
                WHERE b1.batch_id = bv.batch_id
                  AND crh1.batch_id = b1.batch_id
                  AND crh1.current_record_flag = 'Y'
                  AND ra.cash_receipt_id = crh1.cash_receipt_id
                  AND ra.status IN ('APP','ACTIVITY')
                GROUP BY b1.batch_id),0)||chr(9)||
              (SELECT COUNT(*) FROM ar_cash_receipts_v WHERE batch_id = bv.batch_id AND receipt_status IN ('APP','ACTIVITY'))||chr(9)||
              NVL((SELECT SUM(ra.amount_applied)
                 FROM ar_receivable_applications_all ra,
                      ar_cash_receipt_history_all crh1,
                      ar_batches_all b1
                WHERE b1.batch_id = bv.batch_id
                  AND crh1.batch_id = b1.batch_id
                  AND crh1.current_record_flag = 'Y'
                  AND ra.cash_receipt_id = crh1.cash_receipt_id
                  AND ra.status = 'UNAPP'
                GROUP BY b1.batch_id),0)||chr(9)||
              (SELECT COUNT(*) FROM ar_cash_receipts_v WHERE batch_id = bv.batch_id AND receipt_status = 'UNAPP')||chr(9)||
              NVL((SELECT SUM(ra.amount_applied)
                 FROM ar_receivable_applications_all ra,
                      ar_cash_receipt_history_all crh1,
                      ar_batches_all b1
                WHERE b1.batch_id = bv.batch_id
                  AND crh1.batch_id = b1.batch_id
                  AND crh1.current_record_flag = 'Y'
                  AND ra.cash_receipt_id = crh1.cash_receipt_id
                  AND ra.status = 'UNID'
                GROUP BY b1.batch_id),0)||chr(9)||
              (SELECT COUNT(*) FROM ar_cash_receipts_v WHERE batch_id = bv.batch_id AND receipt_status = 'UNID')||chr(9)||
              bv.name||chr(9)||
              bv.type||chr(9)||
              bv.batch_source_name||chr(9)||
              bv.batch_status_meaning||chr(9)||
              bv.transmission_name||chr(9)||
              bv.comments||chr(9)||
              bv.bank_name||chr(9)||
              bv.bank_account_number out_rec
       FROM ar_batches_v bv, ar_lockboxes lb
      WHERE bv.receipt_method_id = lb.receipt_method_id
        AND  (   (p_bank_acct_num IS NOT NULL AND bv.bank_account_number = p_bank_acct_num)
                    OR
                 (p_bank_acct_num IS NULL AND bv.bank_account_number IN (SELECT DISTINCT c.bank_account_num
                                                                          FROM ar_lockboxes_all a,
                                                                               ar_batch_sources_all b,
                                                                               --apps.ap_bank_accounts c            --Commented/Added by Ramya Kuttappa on 11-Sep-2013 for R12 Retrofit
                                                                               ce_bank_accounts c,
                                                                               ce_bank_acct_uses_all d
                                                                            WHERE a.status = 'A'
                                                                            AND b.batch_source_id = a.batch_source_id
                                                                            --AND c.bank_account_id = b.default_remit_bank_account_id
                                                                            AND c.bank_account_id = d.bank_account_id
                                                                            AND d.bank_acct_use_id = b.remit_bank_acct_use_id
                                                                         )
                 )
             )

        AND  (   (p_lockbox_number IS NOT NULL AND lb.lockbox_number = p_lockbox_number)
                    OR
                 (p_lockbox_number IS NULL)
             )

        AND  (   (p_gl_date_from IS NOT NULL AND p_gl_date_to IS NOT NULL AND bv.gl_date BETWEEN FND_DATE.CANONICAL_TO_DATE(p_gl_date_from) AND FND_DATE.CANONICAL_TO_DATE(p_gl_date_to))
                    OR
                 (p_gl_date_from IS NOT NULL AND p_gl_date_to IS NULL AND bv.gl_date >= FND_DATE.CANONICAL_TO_DATE(p_gl_date_from))
                    OR
                 (p_gl_date_from IS NULL AND p_gl_date_to IS NOT NULL AND bv.gl_date <= FND_DATE.CANONICAL_TO_DATE(p_gl_date_to))
                    OR
                 (p_gl_date_from IS NULL AND p_gl_date_to IS NULL)
             )

        AND  (   (p_deposit_date_from IS NOT NULL AND p_deposit_date_to IS NOT NULL AND bv.deposit_date BETWEEN FND_DATE.CANONICAL_TO_DATE(p_deposit_date_from) AND FND_DATE.CANONICAL_TO_DATE(p_deposit_date_to))
                    OR
                 (p_deposit_date_from IS NOT NULL AND p_deposit_date_to IS NULL AND bv.deposit_date >= FND_DATE.CANONICAL_TO_DATE(p_deposit_date_from))
                    OR
                 (p_deposit_date_from IS NULL AND p_deposit_date_to IS NOT NULL AND bv.deposit_date <= FND_DATE.CANONICAL_TO_DATE(p_deposit_date_to))
                    OR
                 (p_deposit_date_from IS NULL AND p_deposit_date_to IS NULL)
             )

        AND  (   (p_batch_status <> 'All' AND bv.batch_status_meaning = p_batch_status)
                    OR
                 (p_batch_status = 'All')
             )
      );*/
/***************************************************
 End commented by Rohit Nanda on 28-Jun-2017 V1.3
***************************************************/

/***************************************************
 Start Added by Rohit Nanda on 28-Jun-2017 V1.3
***************************************************/

    CURSOR c_out IS
    with BV as
    (
    select /*+ MATERIALIZE */ BV1.BATCH_ID 
        ,BV1.GL_DATE,
        BV1.BATCH_DATE,
        BV1.DEPOSIT_DATE,
        LB.LOCKBOX_NUMBER,
        BV1.CONTROL_AMOUNT,
        BV1.CONTROL_COUNT,
        BV1.NAME,
        BV1.TYPE,
        BV1.BATCH_SOURCE_NAME,
        BV1.BATCH_STATUS_MEANING,
        BV1.TRANSMISSION_NAME,
        BV1.COMMENTS,
        BV1.BANK_NAME,
        BV1.BANK_ACCOUNT_NUMBER    
    FROM   AR_BATCHES_V BV1, AR_LOCKBOXES LB
            WHERE  BV1.RECEIPT_METHOD_ID = LB.RECEIPT_METHOD_ID
            AND    (   (p_bank_acct_num IS NOT NULL AND BV1.BANK_ACCOUNT_NUMBER = p_bank_acct_num)
                    OR (    p_bank_acct_num IS NULL
                        AND BV1.BANK_ACCOUNT_NUMBER IN (
                               SELECT DISTINCT C.BANK_ACCOUNT_NUM
                               FROM            AR_LOCKBOXES_ALL A
                                             , AR_BATCH_SOURCES_ALL B
                                             , CE_BANK_ACCOUNTS C
                                             , CE_BANK_ACCT_USES_ALL D
                               WHERE           A.STATUS = 'A'
                               AND             B.BATCH_SOURCE_ID = A.BATCH_SOURCE_ID
                               AND             C.BANK_ACCOUNT_ID = D.BANK_ACCOUNT_ID
                               AND             D.BANK_ACCT_USE_ID = B.REMIT_BANK_ACCT_USE_ID)
                       )
                   )
            AND    ((p_lockbox_number IS NOT NULL AND LB.LOCKBOX_NUMBER = p_lockbox_number) OR (p_lockbox_number IS NULL))
            AND    (   (    p_gl_date_from IS NOT NULL
                        AND p_gl_date_to IS NOT NULL
                        AND BV1.GL_DATE BETWEEN FND_DATE.CANONICAL_TO_DATE (p_gl_date_from) AND FND_DATE.CANONICAL_TO_DATE
                                                                                                              (p_gl_date_to)
                       )
                    OR (p_gl_date_from IS NOT NULL AND p_gl_date_to IS NULL AND BV1.GL_DATE >= FND_DATE.CANONICAL_TO_DATE (p_gl_date_from))
                    OR (p_gl_date_from IS NULL AND p_gl_date_to IS NOT NULL AND BV1.GL_DATE <= FND_DATE.CANONICAL_TO_DATE (p_gl_date_to))
                    OR (p_gl_date_from IS NULL AND p_gl_date_to IS NULL)
                   )
            AND    (   (    p_deposit_date_from IS NOT NULL
                        AND p_deposit_date_to IS NOT NULL
                        AND BV1.DEPOSIT_DATE BETWEEN FND_DATE.CANONICAL_TO_DATE (p_deposit_date_from)
                                                AND FND_DATE.CANONICAL_TO_DATE (p_deposit_date_to)
                       )
                    OR (p_deposit_date_from IS NOT NULL AND p_deposit_date_to IS NULL AND BV1.DEPOSIT_DATE >= FND_DATE.CANONICAL_TO_DATE (p_deposit_date_from))
                    OR (p_deposit_date_from IS NULL AND p_deposit_date_to IS NOT NULL AND BV1.DEPOSIT_DATE <= FND_DATE.CANONICAL_TO_DATE (p_deposit_date_to))
                    OR (p_deposit_date_from IS NULL AND p_deposit_date_to IS NULL)
                   )
                   -- and BV1.BATCH_STATUS_MEANING = p_batch_status  commented by sripal for #45209 )
				   --change start for #45209
                     AND  (   (P_BATCH_STATUS <> 'All' AND BV1.BATCH_STATUS_MEANING = P_BATCH_STATUS)
                              OR(p_batch_status = 'All')  --change End  for #45209
					      )
				 )				   
				   
    SELECT OUT_REC
    FROM   (SELECT    BV.GL_DATE
                   || CHR (9)
                   || BV.BATCH_DATE
                   || CHR (9)
                   || BV.DEPOSIT_DATE
                   || CHR (9)
                   || BV.LOCKBOX_NUMBER
                   || CHR (9)
                   || BV.CONTROL_AMOUNT
                   || CHR (9)
                   || BV.CONTROL_COUNT
                   || CHR (9)
                   || NVL ((SELECT   SUM (RA.AMOUNT_APPLIED)
                            FROM     AR_RECEIVABLE_APPLICATIONS_ALL RA
                                   , AR_CASH_RECEIPT_HISTORY_ALL CRH1
                                   , AR_BATCHES_ALL B1
                            WHERE    B1.BATCH_ID = BV.BATCH_ID
                            AND      CRH1.BATCH_ID = B1.BATCH_ID
                            AND      CRH1.CURRENT_RECORD_FLAG = 'Y'
                            AND      RA.CASH_RECEIPT_ID = CRH1.CASH_RECEIPT_ID
                            AND      RA.STATUS IN ('APP', 'ACTIVITY')
                            GROUP BY B1.BATCH_ID)
                         , 0
                          )
                   || CHR (9)
                   || (SELECT COUNT (*)
                       FROM   AR_CASH_RECEIPTS_V
                       WHERE  BATCH_ID = BV.BATCH_ID AND RECEIPT_STATUS IN ('APP', 'ACTIVITY'))
                   || CHR (9)
                   || NVL ((SELECT   SUM (RA.AMOUNT_APPLIED)
                            FROM     AR_RECEIVABLE_APPLICATIONS_ALL RA
                                   , AR_CASH_RECEIPT_HISTORY_ALL CRH1
                                   , AR_BATCHES_ALL B1
                            WHERE    B1.BATCH_ID = BV.BATCH_ID
                            AND      CRH1.BATCH_ID = B1.BATCH_ID
                            AND      CRH1.CURRENT_RECORD_FLAG = 'Y'
                            AND      RA.CASH_RECEIPT_ID = CRH1.CASH_RECEIPT_ID
                            AND      RA.STATUS = 'UNAPP'
                            GROUP BY B1.BATCH_ID)
                         , 0
                          )
                   || CHR (9)
                   || (SELECT COUNT (*)
                       FROM   AR_CASH_RECEIPTS_V
                       WHERE  BATCH_ID = BV.BATCH_ID AND RECEIPT_STATUS = 'UNAPP')
                   || CHR (9)
                   || NVL ((SELECT   SUM (RA.AMOUNT_APPLIED)
                            FROM     AR_RECEIVABLE_APPLICATIONS_ALL RA
                                   , AR_CASH_RECEIPT_HISTORY_ALL CRH1
                                   , AR_BATCHES_ALL B1
                            WHERE    B1.BATCH_ID = BV.BATCH_ID
                            AND      CRH1.BATCH_ID = B1.BATCH_ID
                            AND      CRH1.CURRENT_RECORD_FLAG = 'Y'
                            AND      RA.CASH_RECEIPT_ID = CRH1.CASH_RECEIPT_ID
                            AND      RA.STATUS = 'UNID'
                            GROUP BY B1.BATCH_ID)
                         , 0
                          )
                   || CHR (9)
                   || (SELECT COUNT (*)
                       FROM   AR_CASH_RECEIPTS_V
                       WHERE  BATCH_ID = BV.BATCH_ID AND RECEIPT_STATUS = 'UNID')
                   || CHR (9)
                   || BV.NAME
                   || CHR (9)
                   || BV.TYPE
                   || CHR (9)
                   || BV.BATCH_SOURCE_NAME
                   || CHR (9)
                   || BV.BATCH_STATUS_MEANING
                   || CHR (9)
                   || BV.TRANSMISSION_NAME
                   || CHR (9)
                   || BV.COMMENTS
                   || CHR (9)
                   || BV.BANK_NAME
                   || CHR (9)
                   || BV.BANK_ACCOUNT_NUMBER OUT_REC
            FROM   bv
            );

/***************************************************
 End Added by Rohit Nanda on 28-Jun-2017 V1.3
***************************************************/

  BEGIN
    --v_log_msg := 'Starting BEGIN block';
    --FND_FILE.PUT_LINE(FND_FILE.LOG, v_log_msg);
    
    mo_global.set_policy_context('S',gn_org_id);        -- Added for R12 Retrofit Upgrade by Ramya on 10-Sep-2013

    v_profile_value := FND_PROFILE.value('ORG_ID');
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'org_id = ' || v_profile_value);

    v_lang := USERENV('LANG');
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'LANG = ' || v_lang);

    SELECT name
    INTO v_oper_unit
    FROM  hr_organization_units
    WHERE organization_id = v_profile_value;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Operating Unit = ' || v_oper_unit);

    v_out_header1 := 'GL DATE'||chr(9)||'BATCH DATE'||chr(9)||'DEPOSIT DATE'||chr(9)||'LOCKBOX NUMBER'||chr(9)||'CONTROL AMOUNT'||chr(9)||'COUNTROL COUNT'||chr(9)||
                     'APPLIED AMOUNT'||chr(9)||'APPLIED COUNT'||chr(9)||'UNAPPLIED AMOUNT'||chr(9)||'UNAPPLIED COUNT'||chr(9)||'UNIDENTIFIED AMOUNT'||chr(9)||
                     'UNIDENTIFIED COUNT'||chr(9)||'BATCH NAME'||chr(9)||'BATCH TYPE'||chr(9)||'BATCH SOURCE'||chr(9)||'STATUS'||chr(9)||'TRANSMISSION NAME'||chr(9)||
                     'COMMENTS'||chr(9)||'REMITTANCE BANK'||chr(9)||'REMITTANCE ACCOUNT';

    v_out_header2 := 'Office Depot, Inc'||chr(9)||'OD: AR Lockbox Batch Report'||chr(9)||'Date: '||TO_CHAR(sysdate,'YYYY-MM-DD HH24:MI:SS');
    v_out_header3 := v_oper_unit;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_bank_acct_num = ' || p_bank_acct_num);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_lockbox_number = ' || p_lockbox_number);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_gl_date_from = ' || p_gl_date_from);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_gl_date_to = ' || p_gl_date_to);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_deposit_date_from = ' || p_deposit_date_from);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_deposit_date_to = ' || p_deposit_date_to);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_batch_status = ' || p_batch_status);

    i := 0;
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, v_out_header2);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, v_out_header3);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, v_out_header1);
    FOR c_out_rec IN c_out LOOP
      i := i + 1;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, c_out_rec.out_rec);
    END LOOP;
    IF i = 0 THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '*** No Data Found ***');
    END IF;
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'output record count = ' || i);

  END XX_MAIN_RPT;

END XX_AR_LBX_BAT_RPT_PKG;
/
