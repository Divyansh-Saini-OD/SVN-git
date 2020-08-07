SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET TERM ON

PROMPT Creating PACKAGE Body XX_AR_PROMO_CODE_PKG
PROMPT Program exits IF the creation is not successful

WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE PACKAGE BODY XX_AR_PROMO_CODE_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        : Promo Codes                                         |
-- | RICE ID     : E0997                                               |
-- | Description : This Extenstion will derive the Promotional Codes   |
-- |               for credit cards on the basis of promotion criteria.|
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======  ==========   ==================    =======================|
-- |1.0       01-MAR-2007  Shabbar/Sowmya,      Initial version        |
-- |                       Wipro Technologies                          |
-- |1.1       21-JAN-2008  Mano                 Added code for         |
-- |                       Wipro Technologies   defect 2859            |
-- |1.2       27-MAR-2008  Manovinayak          Added code for the     |
-- |                       Wipro Technologies   defect#5461            |
-- |1.3       07-APR-2008  Raji Natarajan       Fixed defect 5943      |
-- |1.4       09-APR-2008  Manovinayak          Added code for the     |
-- |                       Wipro Technologies   defect#6064            |
-- |1.5       02-MAY-2008  Manovinayak          Modified the code for  |
-- |                       Wipro Technologies   performance tuning as  |
-- |                                            per the directions of  |
-- |                                            Aravind A              |
-- |1.6       21-MAY-2008 Manovinayak           Performance fixes      |
-- |1.7       21-MAY-2008 Manovinayak           Perfromance fixes by   |
-- |                      Wipro Technologies    Srividya               |
-- |1.8       03-JUN-2008  Manovinayak          Performance tuning done|
-- |                       Wipro Technologies   on 2 dept queries      |
-- |                                            in the dept loop       |
-- |1.9       09-JUN-2008  Manovinayak          Performance tunning    |
-- |                       Wipro Technologies   on dept query as per   |
-- |                                            the suggestions of     |
-- |                                            Samy Jayagopalan       |
-- |2.1       09-JUN-2008  Manovinayak          Performance tunning    |
-- |                       Wipro Technologies   done on dept query     |
-- |                                            by splitting it into 3 |
-- |                                            queries as per the     |
-- |                                             suggestions of        |
-- |                                            Samy Jayagopalan       |
-- |2.2       10-OCT-2008  Raji Natarajan       Changed log message to |
-- |                                            display bank acc no in |
-- |                                            encrypted format -     |
-- |                                            defect 11864           |
-- |2.3       22-OCT-2015  Vasu Raparla         Removed Schema 
-- |                                            References for R12.2   |
-- |2.4       12-MAY-2016  Suresh Naragam       Changes related to     |
-- |                                            defect#37861           |
-- +===================================================================+

    gc_debug             xx_fin_translatevalues.target_value1%TYPE := 'N';
    gc_debug_file        xx_fin_translatevalues.target_value1%TYPE;

-- +===================================================================+
-- | Name : DISPLAY_LOG                                                |
-- | Description : To display UTL_FILE log messages                    |
-- | Parameters :  p_debug_file, p_debug_msg                           |
-- +===================================================================+

    PROCEDURE DISPLAY_LOG (
                           p_debug_file      IN  VARCHAR2
                          ,p_debug_msg       IN  VARCHAR2
                           )
    IS

       lf_out_file       UTL_FILE.file_type;
       ln_chunk_size     BINARY_INTEGER := 32767;
       lc_error_loc      VARCHAR2(4000);
       lc_datetimestamp  VARCHAR2(25);

    BEGIN
       lc_error_loc := 'Opening the UTL FILE : ' || p_debug_file ;

       SELECT TO_CHAR(SYSDATE,'DD-MON-YYYY:HH24MISS')
       INTO   lc_datetimestamp
       FROM   dual;

       lf_out_file := UTL_FILE.FOPEN ('XXFIN_OUTBOUND', p_debug_file,'a',ln_chunk_size);
       UTL_FILE.PUT_LINE(lf_out_file,lc_datetimestamp||' - '||p_debug_msg);
       UTL_FILE.FCLOSE(lf_out_file);

    EXCEPTION
       WHEN OTHERS THEN

          XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                  p_program_type            => 'Receipt Remittance- Debug'
                 ,p_program_name            => 'DISPLAY_LOG'
                 ,p_program_id              => NULL
                 ,p_module_name             => 'IBY'
                 ,p_error_message_count     => 1
                 ,p_error_message_code      => 'E'
                 ,p_error_message           => 'Error at : ' || lc_error_loc ||' - '||SQLERRM
                 ,p_error_message_severity  => 'Major'
                 ,p_notify_flag             => 'N'
                 ,p_object_type             => ''
                 ,p_object_id               => NULL);
    END DISPLAY_LOG;

-- +====================================================================+
-- | Name : XX_AR_GETPROMO_PROC                                         |
-- | Description : This Procedure is to assign the promotion code to    |
-- |               the credit cards with the help of the promotion      |
-- |               criterias of the card selected.                      |
-- |                                                                    |
-- | Parameters :  p_receipt_id,x_promo_code                            |
-- |                                                                    |
-- +====================================================================+
    PROCEDURE XX_AR_GETPROMO_PROC(
                                  p_receipt_id   IN   NUMBER
                                 ,x_promo_code   OUT  NUMBER
                                 )
    AS
    EX_NO_PROMO_PLAN           EXCEPTION;
    EX_PROMO_PLAN_FAIL         EXCEPTION;
    ln_receipt_id              ar_cash_receipts_all.cash_receipt_id%TYPE;
    ln_receipt_amount          ar_cash_receipts_all.amount%TYPE;
    ln_category_set_id         NUMBER := NULL;
    ln_customer_trx_id         ra_customer_trx_all.customer_trx_id%TYPE;
    ln_trx_id_count            NUMBER ;
    --ln_bank_account_id         ap_bank_accounts_all.bank_account_id%TYPE;
	ln_bank_account_id         iby_ext_bank_accounts.ext_bank_account_id%TYPE;
    ln_promo_eligible_rec_id   ar_cash_receipts_all.cash_receipt_id%TYPE;
    ln_line_id                 oe_order_lines_all.line_id%TYPE;
    ln_organization_id         NUMBER := NULL;
    ln_promo_id                xx_ar_promo_header.promo_id%TYPE;
    ln_promo_plan_code         xx_ar_promo_header.promo_plan_code%TYPE;
    ln_min_amount              xx_ar_promo_header.minimum_amount%TYPE;
    lc_receipt_type            ar_cash_receipts_all.type%TYPE;
    lc_refund                  ar_cash_receipts_all.attribute11%TYPE;
    lc_card_type               xx_ar_promo_cardtypes.card_type %TYPE;
    lc_returns_flag            xx_ar_promo_header.returns_enabled_flag%TYPE;
    ld_eff_start_date          xx_ar_promo_header.effective_start_date%TYPE;
    ld_eff_end_date            xx_ar_promo_header.effective_end_date%TYPE;
    ld_receipt_date            ar_cash_receipts_all.receipt_date%TYPE;
    lc_pymt_name               VARCHAR2(50);
    ln_count                   NUMBER;
    ln_check1                  NUMBER;
    ln_check2                  NUMBER;
    lc_name                    ar_receipt_methods.name%TYPE;
    lc_merch_ref               ar_receipt_methods.merchant_ref%TYPE;
    ln_payeeid                 iby_payee.payeeid%TYPE;
    lc_type                    ar_cash_receipts_all.type%TYPE;
    lc_order_type              ra_customer_trx_all.interface_header_attribute2%TYPE;
    lc_district                fnd_flex_value_norm_hierarchy.parent_flex_value%TYPE;
    lc_location                ar_cash_receipts_all.attribute2%TYPE;
    lc_receipt_district        fnd_flex_value_norm_hierarchy.parent_flex_value%TYPE;
    lc_decrypted_card_num      VARCHAR2(50);
    lc_bank_account_no         VARCHAR2(50);
    lc_sku_exist               VARCHAR2(10) := 'N';
    lc_dept_exist              VARCHAR2(10) := 'N';
    lc_loc_exist               VARCHAR2(10) := 'N';
    lc_dist_exist              VARCHAR2(10) := 'N';
    lc_regn_exist              VARCHAR2(10) := 'N';
    lc_set1                    VARCHAR2(10) := 'N';
    lc_set2                    VARCHAR2(10) := 'N';
    lc_rec_num                 ar_cash_receipts_all.receipt_number %TYPE;
    lc_ref_type                ar_receivable_applications_all.application_ref_type%TYPE; -- added for defect 2859
    lc_ref_num                 ar_receivable_applications_all.application_ref_num%TYPE;  -- added for defect 2859
    lc_item                    oe_order_lines_all.ordered_item%TYPE;           -- added for defect 2859
    ln_inventory_item_id       oe_order_lines_all.inventory_item_id%TYPE;     -- added for defect 2859
    ln_order_type_id           so_order_types_all.ORDER_TYPE_ID%TYPE;        -- added for defect 2859
    ln_flex_valueset_id        fnd_flex_value_sets.flex_value_set_id%TYPE;   -- added for defect 2859

    --Cursor to fetch the invoice details
    CURSOR invoice_cur(p_receipt_id NUMBER) IS
        SELECT  PS_INV.trx_number
               ,PS_INV.trx_date
               ,PS_INV.customer_trx_id
               ,ACRA.attribute2
               ,ACRA.attribute1
               ,NVL(ACRA.attribute1,ACRA.attribute2) sale_location    -- added for defect 2859
               ,NVL(APP.application_ref_type,0)  app_ref_type        -- added for defect 2859
               ,NVL(APP.application_ref_num,0) app_ref_num           -- added for defect 2859
               ,ACRA.receipt_number
        FROM    ar_receivable_applications_all APP
               ,ar_payment_schedules_all PS_INV
               ,ar_cash_receipts_all ACRA
        WHERE   APP.applied_payment_schedule_id = PS_INV.payment_schedule_id
        AND     ACRA.cash_receipt_id            = APP.cash_receipt_id
        AND     ACRA.cash_receipt_id            = p_receipt_id
        AND     APP.display                     = 'Y';

    --Cursor to fetch the promo card
    CURSOR promo_card_cur IS
        SELECT GREATEST(LENGTH(bin_start),LENGTH(bin_end)) lc_length
        FROM   xx_ar_promo_cardtypes
        WHERE  LENGTH(bin_start) >= 6
           OR  LENGTH(bin_end)   >= 6;

    --Cursor to fetch the promo details
    CURSOR promo_detail_cur(p_promo_id NUMBER, p_promo_column VARCHAR2) IS
        SELECT APD.promo_id
              ,APD.promo_column
              ,APD.promo_values
        FROM   xx_ar_promo_detail APD
        WHERE  APD.promo_id     = p_promo_id
        AND    APD.promo_column = p_promo_column;

    --Cursor to fetch promo plan header details for overlapping date ranges added on 09-Apr-08
    CURSOR promo_header_cur(p_card_type xx_ar_promo_cardtypes.card_type %TYPE,p_receipt_date ar_cash_receipts_all.receipt_date%TYPE) IS
        SELECT APH.promo_id
              ,APH.promo_plan_code
              ,APH.minimum_amount
              ,APH.effective_start_date
              ,APH.effective_end_date
              ,APH.returns_enabled_flag
        FROM   xx_ar_promo_header APH
        WHERE  APH.card_type = p_card_type
        AND    p_receipt_date BETWEEN APH.effective_start_date
        AND    APH.effective_end_date;

      BEGIN
        ln_receipt_id := p_receipt_id;

      BEGIN
        SELECT NVL(XFTV.target_value1,'N')
        INTO   gc_debug
        FROM   xx_fin_translatedefinition XFTD
              ,xx_fin_translatevalues XFTV
        WHERE  XFTD.translate_id = xftv.translate_id
        AND    XFTD.translation_name = 'FTP_DETAILS_AJB'
        AND    XFTV.source_value1 = 'Debug_Flag'
        AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
        AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
        AND    XFTV.enabled_flag = 'Y'
        AND    XFTD.enabled_flag = 'Y';
      EXCEPTION
         WHEN OTHERS THEN
            gc_debug := 'N';
      END;

      BEGIN
        SELECT LTRIM(SUBSTR(XFTV.target_value1,INSTR(XFTV.target_value1,'/',-1)),'/')
        INTO   gc_debug_file
        FROM   xx_fin_translatedefinition XFTD
              ,xx_fin_translatevalues XFTV
        WHERE  XFTD.translate_id = xftv.translate_id
        AND    XFTD.translation_name = 'FTP_DETAILS_AJB'
        AND    XFTV.source_value1 = 'Debug_Path'
        AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
        AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
        AND    XFTV.enabled_flag = 'Y'
        AND    XFTD.enabled_flag = 'Y';
      EXCEPTION
         WHEN OTHERS THEN
            gc_debug_file := NULL;
      END;
--Added the IF statement for DISPLAY_LOG on 2-MAY-08 by Manovinayak
      IF (gc_debug = 'Y') THEN     
      DISPLAY_LOG(gc_debug_file,'PROMO CODE DERIVATION STARTS');
      END IF;
        BEGIN
            --To find the receipt type and amount
            SELECT ACR.type
                  ,nvl(ACR.attribute11,0)
                  ,ACR.amount
            INTO   lc_type
                  ,lc_refund
                  ,ln_receipt_amount
            FROM   ar_cash_receipts_all ACR
            WHERE  ACR.cash_receipt_id = ln_receipt_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                  RAISE EX_NO_PROMO_PLAN;
            WHEN TOO_MANY_ROWS THEN
                  RAISE EX_NO_PROMO_PLAN;
        END;
 IF (gc_debug = 'Y') THEN
        DISPLAY_LOG(gc_debug_file,'Receipt type '|| lc_type);
        DISPLAY_LOG(gc_debug_file,'Refund  '|| lc_refund);
        DISPLAY_LOG(gc_debug_file,'Receipt amount '|| ln_receipt_amount);
END IF;

        BEGIN
            IF UPPER(lc_refund) LIKE 'REFUND%' AND UPPER(lc_type) = 'CASH' AND ln_receipt_amount = 0  THEN

                SELECT OOL.line_id
                INTO   ln_line_id
                FROM   xx_iby_cc_refunds ICR
                      ,oe_order_lines_all OOL
                WHERE  OOL.header_id       = ICR.om_header_id
                AND    ICR.cash_receipt_id = ln_receipt_id
                AND    rownum < 2;
             -- Added the code for performance tuning
                BEGIN

                SELECT  ACR.cash_receipt_id
                       ,ACR.receipt_date
                       ,ACR.customer_bank_account_id
                INTO    ln_promo_eligible_rec_id
                       ,ld_receipt_date
                       ,ln_bank_account_id
                FROM    ar_payment_schedules_all APS
                       ,ar_receivable_applications_all ARA
                       ,ar_cash_receipts_all ACR
                       ,xx_om_line_attributes_all OLA
                       ,ra_customer_trx_all RCT
                WHERE   ARA.applied_payment_schedule_id = APS.payment_schedule_id
                AND     ACR.cash_receipt_id             = ARA.cash_receipt_id
                AND     APS.customer_trx_id             = RCT.customer_trx_id
                AND     OLA.ret_orig_order_num          = RCT.trx_number
                AND     RCT.interface_header_context    = 'ORDER ENTRY'
                AND     OLA.line_id                     = ln_line_id;

                EXCEPTION
                WHEN NO_DATA_FOUND THEN
                BEGIN

                     SELECT ACR.cash_receipt_id
                           ,ACR.receipt_date
                           ,ACR.customer_bank_account_id
                     INTO   ln_promo_eligible_rec_id
                           ,ld_receipt_date
                           ,ln_bank_account_id
                     FROM   ar_cash_receipts_all ACR
                     WHERE  ACR.cash_receipt_id = ln_receipt_id;

                     EXCEPTION
                     WHEN OTHERS THEN
                     RAISE EX_NO_PROMO_PLAN;
                     END;

                WHEN TOO_MANY_ROWS THEN
                     RAISE EX_NO_PROMO_PLAN;
                END;

            ELSIF UPPER(lc_refund) LIKE 'REFUND%' AND UPPER(lc_type) = 'MISC' THEN
                SELECT ORIG_REC.cash_receipt_id
                       ,ORIG_REC.receipt_date
                       ,ORIG_REC.customer_bank_account_id
                INTO    ln_promo_eligible_rec_id
                       ,ld_receipt_date
                       ,ln_bank_account_id
                FROM    ar_cash_receipts_all ACR
                       ,ar_cash_receipts_all ORIG_REC
                WHERE   ORIG_REC.cash_receipt_id = ACR.reference_id
                AND     ACR.reference_type  = 'RECEIPT'
                AND     ACR.cash_receipt_id = ln_receipt_id;

            ELSE
                SELECT ACR.cash_receipt_id
                      ,ACR.receipt_date
                      ,ACR.customer_bank_account_id
                INTO   ln_promo_eligible_rec_id
                      ,ld_receipt_date
                      ,ln_bank_account_id
                FROM   ar_cash_receipts_all ACR
                WHERE  ACR.cash_receipt_id = ln_receipt_id;

            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE EX_NO_PROMO_PLAN;
            WHEN TOO_MANY_ROWS THEN
                RAISE EX_NO_PROMO_PLAN;
        END;

 IF (gc_debug = 'Y') THEN
       DISPLAY_LOG(gc_debug_file,'Receipt date '|| ld_receipt_date);
       DISPLAY_LOG(gc_debug_file,'Promo eliglible record id '|| ln_promo_eligible_rec_id);
END IF;

        BEGIN
            --To get the bank account number
            /*SELECT ABA.bank_account_num
            INTO   lc_bank_account_no
            FROM iby_ext_bank_accounts ABA
            WHERE  ABA.bank_account_id = ln_bank_account_id;*/

            SELECT ABA.bank_account_num
            INTO   lc_bank_account_no
            FROM iby_ext_bank_accounts ABA
            WHERE  ABA.ext_bank_account_id = ln_bank_account_id;
IF (gc_debug = 'Y') THEN
          DISPLAY_LOG(gc_debug_file, 'Bank Account Number : '|| SUBSTR(lc_bank_account_no,1,4)||'*****************'||SUBSTR(lc_bank_account_no,-4)); -- Defect 11864
END IF;
            lc_decrypted_card_num:= XX_IBY_SECURITY_PKG.DECRYPT_CREDIT_CARD(p_cc_segment_ref =>lc_bank_account_no);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE EX_NO_PROMO_PLAN;
            WHEN TOO_MANY_ROWS THEN
                RAISE EX_NO_PROMO_PLAN;
        END;
          --Added the below query for fetch fetching the card type for performance tunning
            SELECT  APC.card_type
            INTO    lc_card_type
            FROM    xx_ar_promo_cardtypes APC
            WHERE   SUBSTR(lc_decrypted_card_num, 1, length(bin_end))
            BETWEEN TO_CHAR(APC.bin_start)
            AND     TO_CHAR(APC.bin_end);

IF (gc_debug = 'Y') THEN
        DISPLAY_LOG(gc_debug_file,'lc_card type '|| lc_card_type );
END IF;
--Added the below query for performance tunning of dept query on 09-JUN-08 by Manovinayak A
         BEGIN
            SELECT category_set_id
            INTO   ln_category_set_id
            FROM   mtl_category_sets
            WHERE  category_set_name = 'Inventory';
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ln_category_set_id := NULL;
            WHEN OTHERS THEN
              ln_category_set_id := NULL;
         END;
--Added the below query for performance tunning of dept query on 09-JUN-08 by Manovinayak A
         BEGIN
            SELECT organization_id
            INTO   ln_organization_id
            FROM   mtl_parameters
            WHERE  organization_code  = 'M1';
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ln_organization_id := NULL;
            WHEN OTHERS THEN
              ln_category_set_id := NULL;
         END;

<<MAIN_LOOP>>
     FOR promo_header_rec IN promo_header_cur(lc_card_type,ld_receipt_date)
     LOOP
            --added assignment statements below for to fetch promo plan header details for overlapping date ranges on 09-Apr-08
            IF lc_refund LIKE 'REFUND%' THEN
               IF (promo_header_rec.returns_enabled_flag ='Y') THEN
                  ln_promo_id        := promo_header_rec.promo_id;
                  ln_promo_plan_code := promo_header_rec.promo_plan_code;
                  ln_min_amount      := promo_header_rec.minimum_amount;
                  ld_eff_start_date  := promo_header_rec.effective_start_date;
                  ld_eff_end_date    := promo_header_rec.effective_end_date;
                  lc_returns_flag    := promo_header_rec.returns_enabled_flag;
               ELSE
                  RAISE EX_NO_PROMO_PLAN;
               END IF;
            ELSE
                IF (ln_receipt_amount >= promo_header_rec.minimum_amount) THEN
                   ln_promo_id        := promo_header_rec.promo_id;
                   ln_promo_plan_code := promo_header_rec.promo_plan_code;
                   ln_min_amount      := promo_header_rec.minimum_amount;
                   ld_eff_start_date  := promo_header_rec.effective_start_date;
                   ld_eff_end_date    := promo_header_rec.effective_end_date;
                   lc_returns_flag    := promo_header_rec.returns_enabled_flag;
                   ln_min_amount      := promo_header_rec.minimum_amount;
                ELSE
                  RAISE EX_NO_PROMO_PLAN;
                END IF;
            END IF;

IF (gc_debug = 'Y') THEN

        DISPLAY_LOG(gc_debug_file,'Promo id '||ln_promo_id );
        DISPLAY_LOG(gc_debug_file,'Plan code '|| ln_promo_plan_code);
        DISPLAY_LOG(gc_debug_file,'Minimum Amount '|| ln_min_amount);
        DISPLAY_LOG(gc_debug_file,'Effective start date '|| ld_eff_start_date);
        DISPLAY_LOG(gc_debug_file,'Effective end date '|| ld_eff_end_date);
        DISPLAY_LOG(gc_debug_file,'Returns flag '|| lc_returns_flag);

END IF;

<<INVOICE_LOOP>>
        --Invoice loop
        FOR invoice_rec IN invoice_cur(ln_promo_eligible_rec_id)
        LOOP
            ln_customer_trx_id := invoice_rec.customer_trx_id;
            lc_ref_num         := invoice_rec.app_ref_num;
            lc_ref_type        := invoice_rec.app_ref_type;
            lc_rec_num         := invoice_rec.receipt_number;
            IF (gc_debug = 'Y') THEN
            DISPLAY_LOG(gc_debug_file,'Cust_trx_id ' || ln_customer_trx_id );
            END IF;

            --To check Sku
            FOR promo_detail_rec IN promo_detail_cur(ln_promo_id, 'Sku')
            LOOP
                ln_count := 0;
                lc_set1 := 'Y';
                IF (lc_refund<>'SA_DEPOSIT' AND lc_ref_type<>'OM') OR ln_customer_trx_id >0  THEN

--Added the query on 09-JUN-08 for replacing the sub-query for fetching organization_id with the variable ln_organization_id
                    SELECT /*+ parallel(RCTL 8) parallel(MSI 8)*/
                    COUNT(MSI.segment1)
                    INTO   ln_count
                    FROM   ra_customer_trx_lines_all RCTL
                          ,mtl_system_items_b MSI
                    WHERE  MSI.inventory_item_id  = RCTL.inventory_item_id
                    AND    MSI.organization_id    = ln_organization_id
                    AND    RCTL.inventory_item_id IS NOT NULL
                    AND    RCTL.customer_trx_id   = ln_customer_trx_id
                    AND    MSI.segment1           = promo_detail_rec.promo_values;

                    -- added for defect 2859
                ELSIF (lc_refund = 'SA_DEPOSIT' AND lc_ref_type = 'OM') OR (lc_refund <> 'SA_DEPOSIT' AND lc_ref_type = 'OM') THEN
--Added the below query for removing mtl_parameters table and using the local variable ln_organization_id on 09-JUN-08 by Manovinayak A

                    SELECT /*+ parallel(OOL 8) parallel(MSI 8) parallel(OOH 8) parallel(MP 8) */
                    COUNT(MSI.segment1)
                    INTO   ln_count
                    FROM   oe_order_lines_all OOL
                          ,mtl_system_items_b MSI
                          ,oe_order_headers_all OOH
                    WHERE  MSI.inventory_item_id  = OOL.inventory_item_id
                    AND    MSI.organization_id    = ln_organization_id
                    AND    OOL.inventory_item_id IS NOT NULL
                    AND    MSI.segment1           = promo_detail_rec.promo_values
                    AND    OOH.header_id          = OOL.header_id
                    AND    OOH.order_number       = lc_ref_num;

                ELSE
                    SELECT /*+ parallel(XXI 8) */
                    COUNT(XXI.WS_SKU)
                    INTO   ln_count
                    FROM   XX_IBY_DEPOSIT_AOPS_ORDER_DTLS XXI
                    WHERE  trunc(XXI.ws_sku)   = promo_detail_rec.promo_values
                    AND    XXI.receipt_number  = lc_rec_num;

                END IF;
                IF  ln_count > 0 THEN
                    lc_sku_exist := 'Y';
                    IF (gc_debug = 'Y') THEN
                    DISPLAY_LOG(gc_debug_file,'SKU flag has been set to YES' );
                    END IF;
                    EXIT;
                END IF;
            END LOOP;

        --To check Department
        FOR promo_detail_rec IN promo_detail_cur(ln_promo_id, 'Department')
        LOOP
                ln_count := 0;
                EXIT WHEN lc_sku_exist = 'Y';           --Added for performance tuning
                lc_set1 := 'Y';
                IF (lc_refund <> 'SA_DEPOSIT' AND lc_ref_type <> 'OM') OR ln_customer_trx_id >0 THEN

--Added below query for performance tuning after splitting the above query into three on 09-JUN-08 by Manovinayak A

                    SELECT COUNT(MCV.segment3)
                    INTO   ln_count
                    FROM   ra_customer_trx_lines_all RCTL
                          ,mtl_item_categories MIC
                          ,mtl_categories_b MCV
                    WHERE  MIC.inventory_item_id = RCTL.inventory_item_id
                    AND    MIC.category_id       = MCV.category_id
                    AND    MIC.category_set_id   = ln_category_set_id
                    AND    MIC.organization_id   = ln_organization_id
                    AND    RCTL.customer_trx_id  = ln_customer_trx_id
                    AND    MCV.segment3          = promo_detail_rec.promo_values;

                    -- added for defect 2859
                ELSIF (lc_refund = 'SA_DEPOSIT' AND lc_ref_type = 'OM') OR (lc_refund <> 'SA_DEPOSIT' AND lc_ref_type = 'OM') THEN
--Added the below query for performance tuning on 09-JUN-2008 by Manovinayak A-After splitting into 3 queries

                      SELECT /*+ ordered */ count(MCV.SEGMENT3)
                      INTO   ln_count
                      FROM   oe_order_headers_all OOH
                            ,oe_order_lines_all OOL
                            ,mtl_item_categories MIC
                            ,mtl_categories_b MCV
                      WHERE  MIC.inventory_item_id = OOL.inventory_item_id
                      AND    MIC.category_id       = MCV.category_id
                      AND    MIC.category_set_id   = ln_category_set_id
                      AND    MIC.organization_id   = ln_organization_id
                      AND    MCV.segment3          = promo_detail_rec.promo_values
                      AND    OOH.header_id         = OOL.header_id
                      AND    OOH.order_number      = lc_ref_num;

                ELSE
                    SELECT /*+ parallel(XXI 8)*/
                    COUNT(XXI.ws_merch_dept )
                    INTO   ln_count
                    FROM   XX_IBY_DEPOSIT_AOPS_ORDER_DTLS XXI
                    WHERE  TRUNC(XXI.ws_merch_dept)  = promo_detail_rec.promo_values
                    AND    XXI.receipt_number =  lc_rec_num;

                END IF;
                IF ln_count > 0 THEN
                    lc_dept_exist := 'Y' ;
                    IF (gc_debug = 'Y') THEN
                    DISPLAY_LOG(gc_debug_file,'Department flag has been set to YES' );
                    END IF;
                    EXIT;
                END IF;
        END LOOP;

        --To check Location
        FOR promo_detail_rec IN promo_detail_cur(ln_promo_id, 'Location')
        LOOP
                ln_count := 0;
                lc_set2 := 'Y';
            BEGIN
                IF lc_refund <> 'SA_DEPOSIT' AND lc_ref_type <> 'OM' THEN
                    -- To find the AOPS/POS receipts
                   SELECT interface_header_attribute2
                    INTO   lc_order_type
                    FROM   ra_customer_trx_all
                    WHERE  customer_trx_id = ln_customer_trx_id;

                    IF (gc_debug = 'Y') THEN
                    DISPLAY_LOG(gc_debug_file,'order_type'||lc_order_type);
                    END IF;
                    IF ((lc_order_type = 'SA US Standard')OR(lc_order_type = 'SA CA Standard')
                            OR(lc_order_type = 'SA US Return') OR (lc_order_type = 'SA CA Return')) THEN
                                --AOPS Receipts
                        lc_location :=  invoice_rec.attribute2;

                    ELSIF ((lc_order_type ='SA US POS Standard') OR (lc_order_type = 'SA CA POS Standard')
                                OR (lc_order_type ='SA US POS Return') OR (lc_order_type = 'SA CA POS Return')) THEN
                                --POS Receipts
                        lc_location :=  invoice_rec.attribute1;

                    ELSE
                                 --IReceivables Receipts
                        SELECT DISTINCT ARM.name
                              ,ARM.merchant_ref
                        INTO   lc_name
                              ,lc_merch_ref
                        FROM   ar_receipt_methods  ARM
                              ,ar_cash_receipts_all ACR
                        WHERE  ARM.receipt_method_id =ACR.receipt_method_id
                        AND    ARM.receipt_class_id IN (SELECT receipt_class_id
                                                        FROM ar_receipt_classes
                                                        WHERE name LIKE '%CC%IRECEIVABLES%')
                        AND    ACR.cash_receipt_id = ln_receipt_id;

                    END IF;
                    -- added for defect 2859
                ELSIF lc_ref_type = 'OM' AND lc_refund <> 'SA_DEPOSIT'  THEN

                  --Added the query to get order type for performance tunning
                        SELECT /*+ parallel(OOH 8) parallel(OTT 8)*/
                        name
                        INTO   lc_order_type
                        FROM   oe_transaction_types_tl OTT
                              ,oe_order_headers_all OOH
                        WHERE  OTT.transaction_type_id = OOH.order_type_id
                        AND    OTT.language            = USERENV('LANG')
                        AND    OOH.order_number        = lc_ref_num;

                    IF ((lc_order_type = 'SA US Standard')OR(lc_order_type = 'SA CA Standard')
                            OR(lc_order_type = 'SA US Return') OR (lc_order_type = 'SA CA Return')) THEN
                            --AOPS Receipts
                        lc_location :=  invoice_rec.attribute2;

                    ELSIF ((lc_order_type ='SA US POS Standard') OR (lc_order_type = 'SA CA POS Standard')
                            OR (lc_order_type ='SA US POS Return') OR (lc_order_type = 'SA CA POS Return')) THEN
                            --POS Receipts
                        lc_location :=  invoice_rec.attribute1;

                    ELSE
                        --IReceivables Receipts
                        SELECT /*+ parallel(ARM 8) parallel(ACR 8)*/
                        DISTINCT ARM.name
                              ,ARM.merchant_ref
                        INTO   lc_name
                              ,lc_merch_ref
                        FROM   ar_receipt_methods  ARM
                              ,ar_cash_receipts_all ACR
                        WHERE  ARM.receipt_method_id =ACR.receipt_method_id
                        AND    ARM.receipt_class_id IN (SELECT receipt_class_id
                                                        FROM ar_receipt_classes
                                                        WHERE name LIKE '%CC%IRECEIVABLES%')
                        AND ACR.cash_receipt_id = ln_receipt_id;

                    END IF;
                    -- added for defect 2859
                ELSIF lc_refund = 'SA_DEPOSIT' THEN
                        lc_location :=  invoice_rec.sale_location;
                END IF;
            EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                         RAISE EX_NO_PROMO_PLAN ;
                    WHEN TOO_MANY_ROWS THEN
                          RAISE EX_NO_PROMO_PLAN ;
            END;

                IF lc_name IS NOT NULL THEN
                IF (gc_debug = 'Y') THEN
                    DISPLAY_LOG(gc_debug_file,'Location is for irec receipts');
                END IF;
                END IF;

            IF promo_detail_rec.promo_values = 'All - US with Puerto Rico' THEN
                   -- added query for the defect#5461
                    SELECT /*+ parallel(HOI 8) parallel(HOU 8) parallel(HLO 8)*/
                    COUNT(1)
                    INTO   ln_count
                    FROM   hr_organization_information HOI
                          ,hr_organization_units HOU
                          ,hr_locations HLO
                    WHERE  HOI.org_information1 = 'INV'
                    AND    HOU.organization_id = HOI.organization_id
                    AND    substr(HLO.location_code,1,6)=substr(HOU.name,1,6)
                    AND    HLO.country = 'US'
                    AND    substr(HOU.name,1,6) = lc_location;

            ELSIF promo_detail_rec.promo_values = 'All - US without Puerto Rico' THEN

                  -- added query for the defect#5461
                    SELECT /*+ parallel(HOI 8) parallel(HOU 8) parallel(HLO 8)*/
                    COUNT(1)
                    INTO   ln_count
                    FROM   hr_organization_information HOI
                          ,hr_organization_units HOU
                          ,hr_locations HLO
                    WHERE  HOU.organization_id = HOI.organization_id
                    AND    HOI.org_information1 = 'INV'
                    AND    HLO.country = 'US'
                    AND    nvl(HLO.region_2,0) <>'PR'
                    AND    substr(HLO.location_code,1,6)=substr(HOU.name,1,6)
                    AND    substr(HOU.name,1,6) = lc_location;

            ELSIF promo_detail_rec.promo_values = 'All - Canada' THEN

                   -- added query for the defect#5461
                    SELECT /*+ parallel(HOI 8) parallel(HOU 8) parallel(HLO 8)*/
                    COUNT(1)
                    INTO   ln_count
                    FROM   hr_organization_information HOI
                          ,hr_organization_units HOU
                          ,hr_locations HLO
                    WHERE  HOU.organization_id = HOI.organization_id
                    AND    HOI.org_information1 = 'INV'
                    AND    substr(HLO.location_code,1,6)=substr(HOU.name,1,6)
                    AND    HLO.country = 'CA'
                    AND    substr(HOU.name,1,6) = lc_location;

            ELSIF promo_detail_rec.promo_values = 'All - Puerto Rico (only)' THEN
                    -- added query for the defect#5461
                    SELECT /*+ parallel(HOI 8) parallel(HOU 8) parallel(HLO 8)*/
                    COUNT(1)
                    INTO   ln_count
                    FROM   hr_organization_information HOI
                          ,hr_organization_units HOU
                          ,hr_locations HLO
                    WHERE  HOU.organization_id = HOI.organization_id
                    AND    HOI.org_information1 = 'INV'
                    AND    HLO.region_2 = 'PR'
                    AND    substr(HLO.location_code,1,6)=substr(HOU.name,1,6)
                    AND    substr(HOU.name,1,6) = lc_location;
            ELSE
                    -- added query for the defect#5461
                    SELECT /*+ parallel(HOI 8) parallel(HOU 8) parallel(HLO 8)*/
                    COUNT(1)
                    INTO   ln_count
                    FROM   hr_organization_information HOI
                          ,hr_organization_units HOU
                          ,hr_locations HLO
                    WHERE  HOU.organization_id          = HOI.organization_id
                    AND    HOI.org_information1         = 'INV'
                    AND    substr(HLO.location_code,1,6)= lc_location
                    AND    lc_location = promo_detail_rec.promo_values;

            END IF;
            IF ln_count > 0 THEN
                lc_loc_exist := 'Y' ;
                IF (gc_debug = 'Y') THEN
                DISPLAY_LOG(gc_debug_file,'Location flag has been set to YES' );
                END IF;
                EXIT;
            END IF;
        END LOOP;

        --To check District
        FOR promo_detail_rec IN promo_detail_cur(ln_promo_id, 'District')
        LOOP
            ln_count := 0;
            EXIT WHEN lc_loc_exist = 'Y' ;                          --Added for performance tuning
            lc_set2 := 'Y';
            BEGIN
                IF lc_refund <> 'SA_DEPOSIT' AND lc_ref_type <> 'OM' THEN
                    -- To find the AOPS/POS receipts
            
                    SELECT interface_header_attribute2
                    INTO   lc_order_type
                    FROM   ra_customer_trx_all
                    WHERE  customer_trx_id = ln_customer_trx_id;
                    IF (gc_debug = 'Y') THEN
                    DISPLAY_LOG(gc_debug_file,'Order type'||lc_order_type );
                    END IF;
                    IF ((lc_order_type = 'SA US Standard')OR(lc_order_type = 'SA CA Standard')
                      OR(lc_order_type = 'SA US Return') OR (lc_order_type = 'SA CA Return')) THEN
                        --AOPS Receipts
                          lc_location :=  invoice_rec.attribute2;

                    ELSIF ((lc_order_type ='SA US POS Standard') OR (lc_order_type = 'SA CA POS Standard')
                       OR (lc_order_type ='SA US POS Return') OR (lc_order_type = 'SA CA POS Return')) THEN
                        --POS Receipts
                        lc_location :=  invoice_rec.attribute1;
                    ELSE
                        --IReceivables Receipts
                        SELECT DISTINCT ARM.name
                              ,ARM.merchant_ref
                        INTO   lc_name
                              ,lc_merch_ref
                        FROM   ar_receipt_methods  ARM
                              ,ar_cash_receipts_all ACR
                        WHERE  ARM.receipt_method_id =ACR.receipt_method_id
                        AND    ARM.receipt_class_id IN (SELECT receipt_class_id
                                                        FROM ar_receipt_classes
                                                        WHERE name LIKE '%CC%IRECEIVABLES%')
                        AND    ACR.cash_receipt_id   = ln_receipt_id;

                      END IF;
                    -- added for defect 2859
                ELSIF lc_ref_type = 'OM' AND lc_refund <> 'SA_DEPOSIT'  THEN

                  --Added the query to get order type for performance tunning
                        SELECT name
                        INTO   lc_order_type
                        FROM   oe_transaction_types_tl OTT
                              ,oe_order_headers_all OOH
                        WHERE  OTT.transaction_type_id = OOH.order_type_id
                        AND    OTT.language            = USERENV('LANG')
                        AND    OOH.order_number        = lc_ref_num;

                    IF ((lc_order_type = 'SA US Standard')OR(lc_order_type = 'SA CA Standard')
                      OR(lc_order_type = 'SA US Return') OR (lc_order_type = 'SA CA Return')) THEN
                        --AOPS Receipts
                        lc_location := invoice_rec.attribute2;

                    ELSIF ((lc_order_type ='SA US POS Standard') OR (lc_order_type = 'SA CA POS Standard')
                        OR (lc_order_type ='SA US POS Return') OR (lc_order_type = 'SA CA POS Return')) THEN
                        --POS Receipts
                        lc_location := invoice_rec.attribute1;

                    ELSE
                        --IReceivables Receipts
                        SELECT DISTINCT ARM.name
                              ,ARM.merchant_ref
                        INTO   lc_name
                              ,lc_merch_ref
                        FROM   ar_receipt_methods  ARM
                              ,ar_cash_receipts_all ACR
                        WHERE  ARM.receipt_method_id =ACR.receipt_method_id
                        AND    ARM.receipt_class_id IN (SELECT receipt_class_id
                                                        FROM   ar_receipt_classes
                                                        WHERE  name LIKE '%CC%IRECEIVABLES%')
                        AND    ACR.cash_receipt_id = ln_receipt_id;

                    END IF;
                    -- added for defect 2859
                ELSIF lc_refund = 'SA_DEPOSIT' THEN
                    lc_location :=  invoice_rec.sale_location;

                END IF;
                IF (gc_debug = 'Y') THEN
                    DISPLAY_LOG(gc_debug_file,' Location' || lc_location);
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                     RAISE EX_NO_PROMO_PLAN ;
                WHEN TOO_MANY_ROWS THEN
                     RAISE EX_NO_PROMO_PLAN ;
            END;
            BEGIN
                IF (NVL(lc_name,0) = 0) THEN-- IS NULL THEN
                --Gets the District based on Location
                    --Added query for the defect#5461
                    SELECT  /*+ parallel(HOI 8) parallel(HOU 8)*/
                    COUNT(HOU.attribute2)
                    INTO   ln_count
                    FROM   hr_organization_information HOI
                          ,hr_organization_units HOU
                    WHERE  HOU.organization_id  = HOI.organization_id
                    AND    HOI.org_information1 = 'INV'
                    AND    substr(HOU.name,1,6) = lc_location
                    AND    HOU.attribute2       = promo_detail_rec.promo_values;

                    IF ln_count > 0 THEN
                       lc_dist_exist := 'Y' ;
                       IF (gc_debug = 'Y') THEN
                       DISPLAY_LOG(gc_debug_file,'District flag has been set to YES' );
                       END IF;
                       EXIT;
                    END IF;

                ELSE
                    lc_dist_exist := 'Y' ;
                    IF (gc_debug = 'Y') THEN
                    DISPLAY_LOG(gc_debug_file,'District flag has been set to YES' );
                    END IF;
                    EXIT;
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE EX_NO_PROMO_PLAN ;
                WHEN TOO_MANY_ROWS THEN
                    RAISE EX_NO_PROMO_PLAN ;
            END;
        END LOOP;

        --To check Region
        FOR promo_detail_rec IN promo_detail_cur(ln_promo_id, 'Region')
        LOOP
            ln_count := 0;
            EXIT WHEN (lc_loc_exist ='Y' OR lc_dist_exist = 'Y');       --Added for performance tuning
            lc_set2 := 'Y';
            BEGIN
                IF lc_refund <> 'SA_DEPOSIT' AND lc_ref_type <> 'OM' THEN
                    -- To find the AOPS/POS receipts
                    SELECT interface_header_attribute2
                    INTO   lc_order_type
                    FROM   ra_customer_trx_all
                    WHERE  customer_trx_id = ln_customer_trx_id;

                    IF ((lc_order_type = 'SA US Standard')OR(lc_order_type = 'SA CA Standard')
                      OR(lc_order_type = 'SA US Return') OR (lc_order_type = 'SA CA Return')) THEN
                        --AOPS Receipts
                        lc_location :=  invoice_rec.attribute2;

                    ELSIF ((lc_order_type ='SA US POS Standard') OR (lc_order_type = 'SA CA POS Standard')
                        OR (lc_order_type ='SA US POS Return') OR (lc_order_type = 'SA CA POS Return')) THEN
                        --POS Receipts
                        lc_location :=  invoice_rec.attribute1;

                    ELSE
                        --IReceivables Receipts
                        SELECT DISTINCT ARM.name
                              ,ARM.merchant_ref
                        INTO   lc_name
                              ,lc_merch_ref
                        FROM   ar_receipt_methods  ARM
                              ,ar_cash_receipts_all ACR
                        WHERE  ARM.receipt_method_id = ACR.receipt_method_id
                        AND    ARM.receipt_class_id IN (SELECT receipt_class_id
                                                        FROM ar_receipt_classes
                                                        WHERE name LIKE '%CC%IRECEIVABLES%')
                        AND    ACR.cash_receipt_id   = ln_receipt_id;

                    END IF;
                    -- added for defect 2859
                ELSIF lc_ref_type = 'OM' AND lc_refund <> 'SA_DEPOSIT'  THEN

                 --Added the query to get order type for performance tunning
                        SELECT name
                        INTO   lc_order_type
                        FROM   oe_transaction_types_tl OTT
                              ,oe_order_headers_all OOH
                        WHERE  OTT.transaction_type_id = OOH.order_type_id
                        AND    OTT.language            = USERENV('LANG')
                        AND    OOH.order_number        = lc_ref_num;

                    IF ((lc_order_type = 'SA US Standard')OR(lc_order_type = 'SA CA Standard')
                      OR(lc_order_type = 'SA US Return') OR (lc_order_type = 'SA CA Return')) THEN
                        --AOPS Receipts
                        lc_location :=  invoice_rec.attribute2;

                    ELSIF ((lc_order_type ='SA US POS Standard') OR (lc_order_type = 'SA CA POS Standard')
                        OR (lc_order_type ='SA US POS Return') OR (lc_order_type = 'SA CA POS Return')) THEN
                        --POS Receipts
                        lc_location :=  invoice_rec.attribute1;

                    ELSE
                        --IReceivables Receipts
                        SELECT DISTINCT ARM.name
                              ,ARM.merchant_ref
                        INTO   lc_name
                              ,lc_merch_ref
                        FROM   ar_receipt_methods  ARM
                              ,ar_cash_receipts_all ACR
                        WHERE  ARM.receipt_method_id =ACR.receipt_method_id
                        AND    ARM.receipt_class_id IN (SELECT receipt_class_id
                                                        FROM   ar_receipt_classes
                                                        WHERE  name LIKE '%CC%IRECEIVABLES%')
                        AND    ACR.cash_receipt_id = ln_receipt_id;

               END IF;
                    -- added for defect 2859
                ELSIF lc_refund  = 'SA_DEPOSIT' THEN
                    lc_location := invoice_rec.sale_location;

                END IF;
                IF (gc_debug = 'Y') THEN
                    DISPLAY_LOG(gc_debug_file,' Location' || lc_location);
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE EX_NO_PROMO_PLAN ;
                WHEN TOO_MANY_ROWS THEN
                     RAISE EX_NO_PROMO_PLAN ;
            END;
             --Gets the District based on Location
            BEGIN

                IF (NVL(lc_name,0) = 0) THEN
                    --Added query for the defect#5461
                    SELECT  /*+ parallel(HOI 8) parallel(HOU 8)*/
                    HOU.attribute2
                    INTO   lc_district
                    FROM   hr_organization_information HOI
                          ,hr_organization_units HOU
                    WHERE  HOU.organization_id  = HOI.organization_id
                    AND    HOI.org_information1 = 'INV'
                    AND    substr(HOU.name,1,6) = lc_location;

                    --Gets the Region based on District
                    --Added query for the defect#5461 - modified by Raji 29/Mar/08
                    SELECT /*+ parallel(FFV 8) parallel(FFVS 8)*/
                    count(FFV.attribute1)
                    INTO   ln_count
                    FROM   FND_FLEX_VALUES_VL FFV
                          ,fnd_flex_value_sets FFVS
                    WHERE  FFV.flex_value_set_id    = FFVS.flex_value_set_id
                    AND    FFV.flex_value_meaning   = lc_district
                    AND    FFV.value_category       = FFVS.flex_value_set_name
                    AND    FFVS.flex_value_set_name = ( SELECT target_value1
                                                        FROM   xx_fin_translatedefinition XXFTD,
                                                               xx_fin_translatevalues XXFTV
                                                        WHERE  XXFTD.translation_name = 'XX_AR_DISTRICT_VALUE'
                                                        AND    XXFTD.translate_id     = XXFTV.translate_id)
                    AND   FFV.attribute1            = promo_detail_rec.promo_values;
                    IF ln_count > 0 THEN
                        lc_regn_exist := 'Y' ;
                        IF (gc_debug = 'Y') THEN
                        DISPLAY_LOG(gc_debug_file,'Region flag has been set to YES' );
                        END IF;
                        EXIT;
                    END IF;
                ELSE
                    lc_regn_exist := 'Y' ;
                    IF (gc_debug = 'Y') THEN
                    DISPLAY_LOG(gc_debug_file,'Region flag has been set to YES' );
                    END IF;
                    EXIT;

                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                     RAISE EX_NO_PROMO_PLAN ;
                WHEN TOO_MANY_ROWS THEN
                     RAISE EX_NO_PROMO_PLAN ;
            END;
        END LOOP;
        --Added IF statements for the defect#6064
        IF(lc_set1 = 'Y' AND lc_set2 ='Y') THEN

           IF ((lc_sku_exist = 'Y' ) OR (lc_dept_exist ='Y')) AND ((lc_loc_exist ='Y') OR
              (lc_dist_exist ='Y') OR (lc_regn_exist ='Y')) THEN
              x_promo_code := ln_promo_plan_code;
              IF (gc_debug = 'Y') THEN
              DISPLAY_LOG(gc_debug_file,'Promotion Plan Code is for the cash_receipt_id ' ||ln_receipt_id||' is ' || x_promo_code);
              DISPLAY_LOG(gc_debug_file,'PROMO CODE DERIVATION ENDS');-- Added on 02-May-08 By Manovinayak
              END IF;
              EXIT MAIN_LOOP;
           ELSE lc_set1       := 'N';
                lc_set2       := 'N';
                lc_sku_exist  := 'N';
                lc_dept_exist := 'N';
                lc_loc_exist  := 'N';
                lc_dist_exist := 'N';
                lc_regn_exist := 'N';
           END IF;

        ELSIF (lc_set1 ='Y' AND lc_set2<>'y') THEN

           IF ((lc_sku_exist = 'Y' ) OR (lc_dept_exist ='Y')) THEN
               x_promo_code := ln_promo_plan_code;
               IF (gc_debug = 'Y') THEN
               DISPLAY_LOG(gc_debug_file,'Promotion Plan Code is for the cash_receipt_id ' ||ln_receipt_id||' is ' || x_promo_code);
               DISPLAY_LOG(gc_debug_file,'PROMO CODE DERIVATION ENDS');-- Added on 02-May-08 By Manovinayak
               END IF;
               EXIT MAIN_LOOP;
           ELSE lc_set1       := 'N';
                lc_set2       := 'N';
                lc_sku_exist  := 'N';
                lc_dept_exist := 'N';
                lc_loc_exist  := 'N';
                lc_dist_exist := 'N';
                lc_regn_exist := 'N';
           END IF;

        ELSIF (lc_set2 ='Y' AND lc_set1<>'Y') THEN

           IF ((lc_loc_exist ='Y') OR (lc_dist_exist ='Y') OR (lc_regn_exist ='Y')) THEN
               x_promo_code := ln_promo_plan_code;
               IF (gc_debug = 'Y') THEN
               DISPLAY_LOG(gc_debug_file,'Promotion Plan Code is for the cash_receipt_id ' ||ln_receipt_id||' is ' || x_promo_code);
               DISPLAY_LOG(gc_debug_file,'PROMO CODE DERIVATION ENDS');-- Added on 02-May-08 By Manovinayak
               END IF;
               EXIT MAIN_LOOP;
           ELSE lc_set1       := 'N';
                lc_set2       := 'N';
                lc_sku_exist  := 'N';
                lc_dept_exist := 'N';
                lc_loc_exist  := 'N';
                lc_dist_exist := 'N';
                lc_regn_exist := 'N';
           END IF;

        END IF;

    END LOOP;
END LOOP;

        IF (lc_sku_exist = 'N' ) AND (lc_dept_exist ='N') AND (lc_loc_exist ='N') AND
           (lc_dist_exist ='N') AND (lc_regn_exist ='N') THEN
            RAISE EX_NO_PROMO_PLAN;
        END IF;
  
    EXCEPTION
        WHEN EX_NO_PROMO_PLAN THEN
            x_promo_code := NULL;
            IF (gc_debug = 'Y') THEN
            DISPLAY_LOG(gc_debug_file,'Promotion Plan Code is not available for the receipt with cash_receipt_id: ' || ln_receipt_id);
            DISPLAY_LOG(gc_debug_file,'PROMO CODE DERIVATION ENDS');-- Added on 02-May-08 By Manovinayak
            END IF;
        WHEN OTHERS THEN
         x_promo_code := NULL;
        IF (gc_debug = 'Y') THEN
            DISPLAY_LOG(gc_debug_file,'Promotion Plan Code is not available for cash_receipt_id: ' || ln_receipt_id);
            DISPLAY_LOG(gc_debug_file,'PROMO CODE DERIVATION ENDS');
    END IF;

    END XX_AR_GETPROMO_PROC;
END XX_AR_PROMO_CODE_PKG;
/
SHOW ERR;