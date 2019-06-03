CREATE OR REPLACE
PACKAGE BODY XX_AR_CREDIT_CHECK_WRAPPER_PKG AS
---+========================================================================================================+
---|                                        Office Depot - Project Simplify                                 |
---|                                             Providge Consulting                                        |
---+========================================================================================================+
---|    Application             :       AR                                                                  |
---|                                                                                                        |
---|    Name                    :       xx_ar_credit_check_wrapper                                        
---|                                    XXARCREDITCHECKWRAP
---|                                    Credit Check Wrapper
---|                                                                                                        |
---|    Description             :                                                                           |
---|                                                                                                        |
---|                                                                                                        |
---|                                                                                                        |
---|    Change Record                                                                                       |
---|    ---------------------------------                                                                   |
---|    Version         DATE              AUTHOR            DESCRIPTION                                     |
---|    ------------    ----------------- ---------------   ---------------------                           |
---|    1.0             26-JUL-2012       Ray Strauss       Initial Version                                 |
--_|    1.1             03-JUN-2019       Havish Kasina     Changed the v$database to DB_NAME               |
---+========================================================================================================+

PROCEDURE CREDIT_CHECK_WRAPPER (errbuf          OUT NOCOPY VARCHAR2,
                                retcode         OUT NOCOPY NUMBER,
                                p_store_num     IN  VARCHAR2,
                                p_register_num  IN  VARCHAR2,
                                p_sale_tran     IN  VARCHAR2,
                                p_order_num     IN  VARCHAR2,
                                p_sub_order_num IN  VARCHAR2,
                                p_account_num   IN  VARCHAR2,
                                p_amt           IN  NUMBER,
                                p_updt_flag     IN  VARCHAR2) 
IS
---+===============================================================================================
---|  This procedure is used to test the XX_AR_CREDIT_CHECK_PKG real time credit check.
---+===============================================================================================
x_error_message		VARCHAR2(2000)	DEFAULT NULL;
x_return_status		VARCHAR2(20)	DEFAULT NULL;
x_msg_count		NUMBER		DEFAULT NULL;
x_msg_data			VARCHAR2(4000)	DEFAULT NULL;
x_return_flag		VARCHAR2(1)	DEFAULT NULL;

---+================================================================
---| Credit Check execution information
---+================================================================
lc_start_date        VARCHAR2(22);
lc_end_date          VARCHAR2(22);
lc_duration          VARCHAR2(10);
lc_instance_name     VARCHAR2(9);
lc_updt_flag         VARCHAR2(1);
---+================================================================
---| Results of Credit Check per OTB table
---+================================================================
lc_cust_num          VARCHAR2(12);
lc_spc_card_num      VARCHAR2(12);
lc_store_num         VARCHAR2(05);
lc_reg_num           VARCHAR2(02);
lc_order_num         VARCHAR2(11);
lc_amt               NUMBER;
lc_creation_date     VARCHAR2(22);
lc_last_update_date  VARCHAR2(22);
lc_response_act      VARCHAR2(1);
lc_response_code     VARCHAR2(2);
lc_response_text     VARCHAR2(150);
lc_crd_lim_1         NUMBER;
lc_party_id          NUMBER;
lc_open_ar			NUMBER;
---+================================================================
---| Credit Check data verification
---+================================================================
lc_account_num       VARCHAR2(12);
lc_account_number    VARCHAR2(12);
lc_parent_account    VARCHAR2(12);
ln_party_id          NUMBER;
ln_profile_days      NUMBER;
ln_spc_trx_limit     NUMBER;
ln_spc_daily_limit   NUMBER;
ln_spc_trans_limit   NUMBER;
lc_ach_flag          VARCHAR2(01);
ln_ach_days          NUMBER;
lc_crd_lim_2         NUMBER;
lc_hold_flag         VARCHAR2(1);
ln_sum_open_ar        NUMBER;
ln_sum_otb            NUMBER;
ln_sum_ach_amt        NUMBER;
ln_otb_before         NUMBER;
ln_otb_after          NUMBER;

BEGIN

---+===============================================================================================
---|  REPORT parameters
---+===============================================================================================
      BEGIN
	    -- Commented by Havish Kasina as per Version 1.1
		/*
		SELECT name
		INTO	 lc_instance_name
		FROM   v$database;
        */
		-- Added by Havish Kasina as per Version 1.1
		SELECT SUBSTR(SYS_CONTEXT('USERENV','DB_NAME'),1,8)         -- Changed from V$database to DB_NAME
		  INTO lc_instance_name
          FROM dual;   
		EXCEPTION
               WHEN NO_DATA_FOUND THEN
                    FND_FILE.PUT_LINE(fnd_file.log,'Error - instance name not found in v$database ');
	END;

	IF lc_instance_name = 'GSIPRDGB' THEN
         lc_updt_flag := 'N';
      ELSE
         lc_updt_flag := UPPER(p_updt_flag);
	END IF;

	FND_FILE.PUT_LINE(fnd_file.log,'XX_AR_CREDIT_CHECK_WRAPPER_PKG.CREDIT_CHECK_WRAPPER START - parameters: (Instance = '||lc_instance_name||')');
	FND_FILE.PUT_LINE(fnd_file.log,'   ');
	FND_FILE.PUT_LINE(fnd_file.log,'       P_STORE_NUM            = '||p_store_num);
	FND_FILE.PUT_LINE(fnd_file.log,'       P_REGISTER_NUM         = '||p_register_num);
	FND_FILE.PUT_LINE(fnd_file.log,'       P_SALE_TRAN            = '||p_sale_tran);
	FND_FILE.PUT_LINE(fnd_file.log,'       P_ORDER_NUM            = '||p_order_num);
	FND_FILE.PUT_LINE(fnd_file.log,'       P_SUB_ORDER_NUM        = '||p_sub_order_num);
	FND_FILE.PUT_LINE(fnd_file.log,'       P_ACCOUNT_NUM          = '||p_account_num);
	FND_FILE.PUT_LINE(fnd_file.log,'       P_AMT                  = '||p_amt);
	FND_FILE.PUT_LINE(fnd_file.log,'       P_UPDT_FLAG            = '||lc_updt_flag);

      SELECT TO_CHAR(sysdate, 'YYYY-MM-DD HH24:MI:SS')
      INTO   lc_start_date
      FROM   DUAL;

---+===============================================================================================
---|  CALL credit check.
---+===============================================================================================
      IF lc_updt_flag = 'Y' THEN

         XX_AR_CREDIT_CHECK_PKG.credit_check
                       (p_store_num          => p_store_num
                       ,p_register_num       => p_register_num
                       ,p_sale_tran          => p_sale_tran
                       ,p_order_num          => p_order_num
                       ,p_sub_order_num      => p_sub_order_num
                       ,p_account_num        => p_account_num
                       ,p_amt                => p_amt
                       ,p_response_act       => lc_response_act
                       ,p_response_code      => lc_response_code
                       ,p_response_text      => lc_response_text);

         SELECT TO_CHAR(sysdate, 'YYYY-MM-DD HH24:MI:SS'), 
                TO_CHAR(((SYSDATE - TO_DATE(lc_start_date,'YYYY-MM-DD HH24:MI:SS')) * 86400),'999.99')
         INTO   lc_end_date,
                lc_duration
         FROM   DUAL;

	    FND_FILE.PUT_LINE(fnd_file.log,'   ');
	    FND_FILE.PUT_LINE(fnd_file.log,'****** BEFORE CALL TIMESTAMP  = '||lc_start_date);

         FND_FILE.PUT_LINE(fnd_file.log,'   ');
         FND_FILE.PUT_LINE(fnd_file.log,'****** AFTER CALL TIMESTAMP   = '||lc_end_date);
         FND_FILE.PUT_LINE(fnd_file.log,'       DURATION (in seconds)  = '||lc_duration);

      END IF;

---+===============================================================================================
---|  Get Credit Check Results
---+===============================================================================================
      IF lc_updt_flag = 'Y' THEN
           BEGIN
            SELECT cust_num,
                   spc_card_num,
                   store_num,
                   register_num,
                   order_num,
                   order_amt,
                   TO_CHAR(creation_date,'YYYY-MM-DD HH24:MI:SS'),
                   TO_CHAR(last_update_date,'YYYY-MM-DD HH24:MI:SS'),
                   response_action,
                   response_code,
                   response_text,
                   credit_limit,
                   parent_party_id,
                   total_amount_due
            INTO   lc_cust_num,
                   lc_spc_card_num,
                   lc_store_num,
                   lc_reg_num,
                   lc_order_num,
                   lc_amt,
                   lc_creation_date,
                   lc_last_update_date,
                   lc_response_act,
                   lc_response_code,
                   lc_response_text,
                   lc_crd_lim_1,
                   lc_party_id,
                   lc_open_ar
            FROM   xx_ar_otb_transactions
            WHERE  TO_CHAR(NVL(CUST_NUM,-1))     = TO_CHAR(decode(p_register_num,'99',p_account_num,-1))
            AND    TO_CHAR(NVL(SPC_CARD_NUM,-1)) = TO_CHAR(decode(p_register_num,'99',-1,p_account_num))
            AND    creation_date BETWEEN TO_DATE(lc_start_date,'YYYY-MM-DD HH24:MI:SS') 
                                 AND     TO_DATE(lc_end_date,'YYYY-MM-DD HH24:MI:SS');

            EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                       FND_FILE.PUT_LINE(fnd_file.log,'   ');
                       FND_FILE.PUT_LINE(fnd_file.log,'No data found for parameters entered ');
                  WHEN OTHERS THEN
                       FND_FILE.PUT_LINE(fnd_file.log,'ERROR; SELECT OTB - '||SQLCODE||' '||SQLERRM);
         END;
      ELSE
         BEGIN
            SELECT cust_num,
                   spc_card_num,
                   store_num,
                   register_num,
                   order_num,
                   order_amt,
                   TO_CHAR(creation_date,'YYYY-MM-DD HH24:MI:SS'),
                   TO_CHAR(last_update_date,'YYYY-MM-DD HH24:MI:SS'),
                   response_action,
                   response_code,
                   response_text,
                   credit_limit,
                   parent_party_id,
                   total_amount_due
            INTO   lc_cust_num,
                   lc_spc_card_num,
                   lc_store_num,
                   lc_reg_num,
                   lc_order_num,
                   lc_amt,
                   lc_creation_date,
                   lc_last_update_date,
                   lc_response_act,
                   lc_response_code,
                   lc_response_text,
                   lc_crd_lim_1,
                   lc_party_id,
                   lc_open_ar
            FROM   xx_ar_otb_transactions
            WHERE  TO_CHAR(NVL(CUST_NUM,-1))     = TO_CHAR(decode(p_register_num,'99',p_account_num,-1))
            AND    TO_CHAR(NVL(SPC_CARD_NUM,-1)) = TO_CHAR(decode(p_register_num,'99',-1,p_account_num))
            AND    CREATION_DATE = (SELECT MAX(CREATION_DATE)
                                    FROM   XX_AR_OTB_TRANSACTIONS
                                    WHERE  TO_CHAR(NVL(CUST_NUM,-1))     = TO_CHAR(decode(p_register_num,'99',p_account_num,-1))
                                    AND    TO_CHAR(NVL(SPC_CARD_NUM,-1)) = TO_CHAR(decode(p_register_num,'99',-1,p_account_num)));

            EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                       FND_FILE.PUT_LINE(fnd_file.log,'   ');
                       FND_FILE.PUT_LINE(fnd_file.log,'No data found for parameters entered ');
                  WHEN OTHERS THEN
                       FND_FILE.PUT_LINE(fnd_file.log,'ERROR; SELECT OTB - '||SQLCODE||' '||SQLERRM);
         END;
      END IF;

      IF lc_updt_flag = 'N' THEN
         SELECT TO_CHAR(((TO_DATE(lc_last_update_date,'YYYY-MM-DD HH24:MI:SS') - 
                TO_DATE(lc_creation_date,'YYYY-MM-DD HH24:MI:SS')) * 86400),'999.99')
         INTO   lc_duration
         FROM   DUAL;

 	    FND_FILE.PUT_LINE(fnd_file.log,'   ');
 	    FND_FILE.PUT_LINE(fnd_file.log,'****** BEFORE CALL TIMESTAMP  = '||lc_creation_date);

         FND_FILE.PUT_LINE(fnd_file.log,'   ');
         FND_FILE.PUT_LINE(fnd_file.log,'****** AFTER CALL TIMESTAMP   = '||lc_last_update_date);
         FND_FILE.PUT_LINE(fnd_file.log,'       DURATION (in seconds)  = '||lc_duration);
      END IF;

         FND_FILE.PUT_LINE(fnd_file.log,'   ');
         FND_FILE.PUT_LINE(fnd_file.log,'       CUSTOMER NUMBER        = '||lc_cust_num);
         FND_FILE.PUT_LINE(fnd_file.log,'       SPC CARD NUMBER        = '||lc_spc_card_num);
         FND_FILE.PUT_LINE(fnd_file.log,'       STORE NUMBER           = '||lc_store_num);
         FND_FILE.PUT_LINE(fnd_file.log,'       REGISTER NUMBER        = '||lc_reg_num);
         FND_FILE.PUT_LINE(fnd_file.log,'       ORDER NUMBER           = '||lc_order_num);
         FND_FILE.PUT_LINE(fnd_file.log,'       ORDER AMOUNT           = '||TO_CHAR(lc_amt,'$999,999,999.99'));
         FND_FILE.PUT_LINE(fnd_file.log,'       CREATION DATE          = '||lc_creation_date);
         FND_FILE.PUT_LINE(fnd_file.log,'       CREDIT LIMIT           = '||TO_CHAR(lc_crd_lim_1,'$999,999,999.99'));
         FND_FILE.PUT_LINE(fnd_file.log,'       PARENT PARTY ID        = '||lc_party_id);
--       FND_FILE.PUT_LINE(fnd_file.log,'       OPEN AR                = '||TO_CHAR(lc_open_ar,'$999,999,999.99'));

         FND_FILE.PUT_LINE(fnd_file.log,'   ');
         FND_FILE.PUT_LINE(fnd_file.log,'Credit Check call results:');
         FND_FILE.PUT_LINE(fnd_file.log,'   ');
         FND_FILE.PUT_LINE(fnd_file.log,'       RESPONSE_ACT           = '||lc_response_act);
         FND_FILE.PUT_LINE(fnd_file.log,'       RESPONSE_CODE          = '||lc_response_code);
         FND_FILE.PUT_LINE(fnd_file.log,'       RESP0NSE_TEXT          = '||lc_response_text);
         FND_FILE.PUT_LINE(fnd_file.log,'   ');

---+===============================================================================================
---|  Get SPC card limit information
---+===============================================================================================
      IF lc_spc_card_num IS NOT NULL THEN
         BEGIN

             SELECT SUBSTR(A.orig_system_reference,1,8),
                    n_ext_attr2,
                    n_ext_attr3,
                    n_ext_attr4
             INTO   lc_account_num,
                    ln_spc_trx_limit,
                    ln_spc_daily_limit,
                    ln_spc_trans_limit
             FROM   xx_cdh_cust_acct_ext_b X,
                    ego_fnd_dsc_flx_ctx_ext F,
                    hz_cust_accounts        A
             WHERE  X.cust_account_id               = A.cust_account_id
             AND    X.attr_group_id                 = F.attr_group_id
             AND    F.descriptive_flex_context_code = 'SPC_INFO'
             AND    X.c_ext_attr1                   = 'A'
             AND    X.n_ext_attr1                   = lc_spc_card_num;

             EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                      ln_spc_trx_limit    := 0;
                      ln_spc_daily_limit  := 0;
                      ln_spc_trans_limit  := 0;
         END;
      END IF; 

         FND_FILE.PUT_LINE(fnd_file.log,'       SPC Trans Amt Limit    = '||ln_spc_trx_limit);
         FND_FILE.PUT_LINE(fnd_file.log,'       SPC Daily Limit        = '||ln_spc_daily_limit);
         FND_FILE.PUT_LINE(fnd_file.log,'       SPC Transaction Limit  = '||ln_spc_trans_limit);

---+===============================================================================================
---|  Get parent account number if there is a relationship, otherwise original account and party_id
---+===============================================================================================

         IF  lc_account_num IS NOT NULL THEN
             lc_account_number := lc_account_num;
         ELSE
             lc_account_number := p_account_num;
         END IF;

         BEGIN
                 SELECT NVL((SELECT DISTINCT(DECODE(r.relationship_code,'GROUP_SUB_PARENT',  SUBSTR(C1.orig_system_reference,1,8),
                                                                        'GROUP_SUB_MEMBER_OF',SUBSTR(C2.orig_system_reference,1,8))) AS PARENT_ACCT
                 FROM   hz_cust_accounts C1,
                        hz_relationships R,
                        hz_cust_accounts C2
                 WHERE  R.subject_id             = C1.party_id
                 AND    R.object_id              = C2.party_id
                 AND    R.relationship_type      = 'OD_FIN_HIER'
                 AND    R.relationship_code      like'GROUP_SUB_%'
                 AND    C1.orig_system_reference like lc_account_number ||'%'), lc_account_number) AS LEGACY_ACCT 
                 INTO   lc_parent_account
                 FROM   DUAL;

                 SELECT C.party_id
                 INTO   ln_party_id
                 FROM   hz_cust_accounts C
                 WHERE  C.orig_system_reference like lc_parent_account||'%';

             EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                      lc_parent_account := '';
                      ln_party_id := 0;
         END;

         FND_FILE.PUT_LINE(fnd_file.log,'  ');
         FND_FILE.PUT_LINE(fnd_file.log,'       Parent / Orig Account  = '||lc_parent_account);
         FND_FILE.PUT_LINE(fnd_file.log,'       Party_id               = '||ln_party_id);

---+===============================================================================================
---|  Get credit auth exceptions flag
---+===============================================================================================

         BEGIN
                 SELECT NVL((SELECT xcca.C_EXT_ATTR1  

                            FROM   xx_cdh_cust_acct_ext_b  xcca,
                                   ego_fnd_dsc_flx_ctx_ext eag,
                                   hz_cust_accounts        hca
                            WHERE  xcca.cust_account_id              = hca.cust_account_id
                            AND    xcca.attr_group_id                = eag.attr_group_id
                            AND    eag.descriptive_flex_context_code = 'CREDIT_AUTH_GROUP'
                            AND    hca.orig_system_reference like RTRIM(lc_parent_account)||'%'),'N')
                 INTO   lc_ach_flag
                 FROM DUAL;

             EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                      lc_ach_flag := '';
         END;

         FND_FILE.PUT_LINE(fnd_file.log,'       CREDIT_AUTH_GROUP      = '||lc_ach_flag);

         ln_profile_days := FND_PROFILE.VALUE('XX_AR_ACH_RECEIPT_CLEARING_DAYS');

         SELECT (CASE RTRIM(to_char(sysdate,'DAY'))
                      WHEN 'MONDAY'    THEN ln_profile_days + 2
                      WHEN 'TUESDAY'   THEN ln_profile_days + 2
                      WHEN 'WEDNESDAY' THEN ln_profile_days + 2
                      WHEN 'THURSDAY'  THEN ln_profile_days
                      WHEN 'FRIDAY'    THEN ln_profile_days 
                      WHEN 'SATURDAY'  THEN ln_profile_days + 1
                      WHEN 'SUNDAY'    THEN ln_profile_days + 2
                      END) + (SELECT COUNT(V.source_value2)
                              FROM   xx_fin_translatedefinition D,
                                     xx_fin_translatevalues     V
                              WHERE D.translate_id     = V.translate_id
                              AND   D.translation_name = 'AR_RECEIPTS_BANK_HOLIDAYS'
                              AND   V.source_value2 BETWEEN (sysdate - (SELECT CASE RTRIM(to_char(sysdate,'DAY'))
                                                                               WHEN 'MONDAY'    THEN ln_profile_days + 2
                                                                               WHEN 'TUESDAY'   THEN ln_profile_days + 2
                                                                               WHEN 'WEDNESDAY' THEN ln_profile_days + 2
                                                                               WHEN 'THURSDAY'  THEN ln_profile_days 
                                                                               WHEN 'FRIDAY'    THEN ln_profile_days
                                                                               WHEN 'SATURDAY'  THEN ln_profile_days + 1
                                                                               WHEN 'SUNDAY'    THEN ln_profile_days + 2
                                                                               END
                                                                        FROM DUAL))
                                                    AND sysdate) AS BUSINESS_DAYS
         INTO ln_ach_days
         FROM  DUAL;

         FND_FILE.PUT_LINE(fnd_file.log,'       ACH Number of Days     = '||TO_CHAR(ln_ach_days,'9'));

---+===============================================================================================
---|  Get parent credit limit
---+===============================================================================================

         BEGIN
             SELECT NVL(A.overall_credit_limit,0),
                    P.credit_hold
             INTO   lc_crd_lim_2,
                    lc_hold_flag
             FROM   hz_cust_profile_amts A,
                    hz_customer_profiles P,
                    hz_cust_accounts_all C
             WHERE  P.cust_account_profile_id  = A.cust_account_profile_id
             AND    P.cust_account_id          = C.cust_account_id
             AND    P.site_use_id             IS NULL
             AND    A.currency_code            = 'USD'
             AND    P.status                   = 'A'
             AND    C.orig_system_reference LIKE lc_parent_account||'%';


             EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                      lc_crd_lim_2 := '';
         END;

         FND_FILE.PUT_LINE(fnd_file.log,'       Credit Hold flag       = '||lc_hold_flag);
         FND_FILE.PUT_LINE(fnd_file.log,'       Credit Limit           = '||TO_CHAR(lc_crd_lim_2,'$999,999,999.99'));

---+===============================================================================================
---|  Get open AR for all accounts
---+===============================================================================================

         BEGIN
             SELECT NVL(SUM(P.amount_due_remaining),0)
             INTO   ln_sum_open_ar
             FROM   ar_payment_schedules_all P
             WHERE  P.customer_id in (
                                      SELECT C2.cust_account_id
                                      FROM   hz_cust_accounts C2
                                      WHERE  C2.party_id = ln_party_id
                                      UNION
                                      SELECT C1.cust_account_id
                                      FROM   hz_cust_accounts C1,
                                             hz_relationships R1
                                      WHERE  C1.party_id          = R1.object_id
                                      AND    R1.relationship_type = 'OD_FIN_HIER'
                                      AND    R1.relationship_code like 'GROUP_SUB%'
                                      AND    R1.subject_id        = ln_party_id 
                                      AND    TRUNC(SYSDATE)       BETWEEN TRUNC(R1.start_date)
                                                                  AND     TRUNC(NVL(R1.end_date,SYSDATE))
                                      );

             EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                      ln_sum_open_ar := 0;
         END;

         FND_FILE.PUT_LINE(fnd_file.log,'  ');
         FND_FILE.PUT_LINE(fnd_file.log,'       Total Open AR          = '||TO_CHAR(ln_sum_open_ar,'$999,999,999.99'));

---+===============================================================================================
---|  Get ACH receipts total
---+===============================================================================================

      IF lc_ach_flag = 'N' THEN

         BEGIN
             SELECT NVL(SUM(CR.amount),0)
             INTO   ln_sum_ach_amt
             FROM   ar_cash_receipts_all    CR, 
                    ar_receipt_methods      RM
             WHERE  CR.receipt_method_id    = RM.receipt_method_id
             AND    RM.name                 = 'US_IREC ECHECK_OD'
             AND    CR.status               = 'APP'
             AND    CR.creation_date        > SYSDATE - ln_ach_days
             AND    CR.pay_from_customer   IN (
                                               SELECT C2.cust_account_id
                                               FROM   hz_cust_accounts C2
                                               WHERE  C2.party_id = ln_party_id
                                               UNION
                                               SELECT C1.cust_account_id
                                               FROM   hz_cust_accounts C1,
                                                      hz_relationships R1
                                               WHERE  C1.party_id          = R1.object_id
                                               AND    R1.relationship_type = 'OD_FIN_HIER'
                                               AND    R1.relationship_code like 'GROUP_SUB%'
                                               AND    R1.subject_id        = ln_party_id 
                                               AND    TRUNC(SYSDATE)       BETWEEN TRUNC(R1.start_date)
                                                                           AND     TRUNC(NVL(R1.end_date,SYSDATE))
                                               );

             EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                      ln_sum_ach_amt := 0;
         END;
      END IF;

         FND_FILE.PUT_LINE(fnd_file.log,'       Total ACH receipts     = '||TO_CHAR(ln_sum_ach_amt,'$999,999,999.99'));

---+===============================================================================================
---|  Get OTB for all accounts
---+===============================================================================================

         BEGIN
             SELECT NVL(SUM(P.order_amt),0)
             INTO   ln_sum_otb
             FROM   xx_ar_otb_transactions P
             WHERE  P.response_code = '0'
             AND    P.creation_date < TO_DATE(lc_start_date,'YYYY-MM-DD HH24:MI:SS')
             AND    P.customer_id in (
                                      SELECT C2.cust_account_id
                                      FROM   hz_cust_accounts C2
                                      WHERE  C2.party_id = ln_party_id
                                      UNION
                                      SELECT C1.cust_account_id
                                      FROM   hz_cust_accounts C1,
                                             hz_relationships R1
                                      WHERE  C1.party_id          = R1.object_id
                                      AND    R1.relationship_type = 'OD_FIN_HIER'
                                      AND    R1.relationship_code like 'GROUP_SUB%'
                                      AND    R1.subject_id        = ln_party_id 
                                      AND    TRUNC(SYSDATE)       BETWEEN TRUNC(R1.start_date)
                                                                  AND     TRUNC(NVL(R1.end_date,SYSDATE))
                                      );


             EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                      ln_sum_otb := 0;
         END;

         IF lc_updt_flag = 'N' THEN
            ln_sum_otb := ln_sum_otb - lc_amt;
         END IF;

         ln_otb_before := ((lc_crd_lim_2) - (ln_sum_open_ar + ln_sum_otb + ln_sum_ach_amt));
         ln_otb_after  := ((lc_crd_lim_2) - (ln_sum_open_ar + ln_sum_otb + ln_sum_ach_amt + lc_amt));

         FND_FILE.PUT_LINE(fnd_file.log,'       Total OTB TBL B4 call  = '||TO_CHAR(ln_sum_otb,'$999,999,999.99'));
         FND_FILE.PUT_LINE(fnd_file.log,'       Order Amount           = '||TO_CHAR(lc_amt,'$999,999,999.99'));
         FND_FILE.PUT_LINE(fnd_file.log,'   ');
         FND_FILE.PUT_LINE(fnd_file.log,'       Open-to-buy before     = '||TO_CHAR(ln_otb_before,'$999,999,999.99'));
         FND_FILE.PUT_LINE(fnd_file.log,'       Open-to-buy after      = '||TO_CHAR(ln_otb_after,'$999,999,999.99'));
         FND_FILE.PUT_LINE(fnd_file.log,'   ');

EXCEPTION
    WHEN OTHERS THEN
	   FND_FILE.PUT_LINE(fnd_file.log,'   ');
	   FND_FILE.PUT_LINE(fnd_file.log,'       EXCEPTION - OTHERS:');
	   FND_FILE.PUT_LINE(fnd_file.log,'       SQLCODE               = '||SQLCODE);
	   FND_FILE.PUT_LINE(fnd_file.log,'       SQLERRM               = '||SQLERRM);

END CREDIT_CHECK_WRAPPER ;

END XX_AR_CREDIT_CHECK_WRAPPER_PKG ;
/
