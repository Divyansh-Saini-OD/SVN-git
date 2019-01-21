CREATE OR REPLACE
PACKAGE BODY XX_AR_GET_PROMO_PKG IS
PROCEDURE XX_AR_GETPROMO_PROC(
     x_error_buff       OUT VARCHAR2
    ,x_ret_code         OUT NUMBER
    ,p_receipt_number   IN   VARCHAR2    
)
AS
-- +====================================================================+
-- |                  Office Depot - Project Simplify                   |
-- |                       WIPRO Technologies                           |
-- +====================================================================+
-- | Name :  Promo Codes - E0997                                        |
-- | Description : This Extenstion will derive the Pormotional Codes    |
-- | for credit cards on the basis of promotion criteria                |
-- |                                                                    |
-- |                                                                    |
-- |Change Record:                                                      |
-- |===============                                                     |
-- |Version   Date          Author              Remarks                 |
-- |=======   ==========   =============        ========================|
-- |1.0       01-MAR-2007  Raji Natarajan,      Initial version         |
-- |                       Wipro Technologies                           |
-- +====================================================================+
-- +====================================================================+
-- | Name : xx_ar_get_promo_pkg                                         |
-- | Description : This Procedure is to assign                          |
-- | the promotion code to the credit cards with the help of the        |
-- | promotion criterias of the card selected.                          |
-- |                                                                    |
-- | Parameters :  p_receipt_number                                     |
-- |                                                                    |
-- +====================================================================+

lc_rec_num VARCHAR2(50);
x_promo_code NUMBER;
lc_trx_number VARCHAR2(50);
lc_card_type VARCHAR2(150);
ln_promo_id xx_ar_promo_header.promo_id%TYPE;
ln_promo_plan_code xx_ar_promo_header.promo_plan_code%TYPE;
ln_minimum_amount xx_ar_promo_header.minimum_amount%TYPE;
ln_invoice_amount ra_customer_trx_lines_all.extended_amount%TYPE;
lc_promo_sku VARCHAR2(50);
lc_promo_dept VARCHAR2(50);
lc_promo_location VARCHAR2(50);
lc_promo_district VARCHAR2(50);
lc_promo_region VARCHAR2(50);
ln_customer_trx_id NUMBER;
ld_trx_date DATE;
ln_card_type_id NUMBER;
ln_inv_item_id NUMBER;
lc_location VARCHAR2(50);
lc_district VARCHAR2(50);
lc_region VARCHAR2(50);
lc_err_msg            VARCHAR2(250);
----cursor to fetch the invoice number 
CURSOR lcu_inv_num(lc_rec_num1 VARCHAR2) IS
   SELECT  PS_INV.trx_number
          ,PS_INV.trx_date 
   FROM    ar_receivable_applications_all APP
          ,ar_payment_schedules_all PS_INV
          ,ar_cash_receipts_all ACRA
   WHERE   APP.applied_payment_schedule_id = PS_INV.payment_schedule_id
   AND     ACRA.cash_receipt_id=APP.cash_receipt_id
   AND     ACRA.receipt_number = lc_rec_num;
----cursor to fetch the credit card number
CURSOR lcu_card_num(lc_rec_num2 VARCHAR2) IS
   SELECT SUBSTR(ABA.bank_account_num,1,4)
         ,APC.card_type
   FROM   ar_cash_receipts_all ACRA
         ,ap_bank_accounts_all ABA
         ,xx_ar_promo_cardtypes APC
   WHERE  ACRA.receipt_number = lc_rec_num
   AND    ACRA.customer_bank_account_id = ABA.bank_account_id
   AND    ABA.account_type = 'EXTERNAL'
   AND    SUBSTR(ABA.bank_account_num,1,4) BETWEEN APC.bin_start AND APC.bin_end;
----cursor to fetch the card details
CURSOR lcu_promo(lc_card_type VARCHAR2,ld_trx_date DATE) IS
   SELECT APH.promo_id
              ,APH.promo_plan_code
              ,APH.minimum_amount
              ,APH.effective_start_date
              ,APH.effective_end_date
   FROM   xx_ar_promo_header APH
   WHERE  APH.card_type = lc_card_type
   AND ld_trx_date BETWEEN APH.effective_start_date AND APH.effective_end_date
   AND APH.last_update_date=(SELECT MAX(last_update_date) FROM xx_ar_promo_header
                             WHERE card_type = lc_card_type);
----cursor to fetch the department values
CURSOR lcu_dept(lc_trx_number VARCHAR2) IS
   SELECT DISTINCT segment12 
   FROM   xx_om_headers_attributes_all OHAL
         ,oe_order_headers_all OHA
         ,ra_customer_trx_all RCT
   WHERE OHA.attribute6 = OHAL.combination_id
   AND   OHA.order_number = RCT.interface_header_attribute1
   AND   RCT.trx_number = lc_trx_number
   AND   OHA.attribute6 IS NOT NULL
   AND   OHAL.segment12 IS NOT NULL;
----cursor to fetch the Sku values
CURSOR lcu_sku(lc_trx_number VARCHAR2) IS
   SELECT DISTINCT MSI.segment1
   FROM   mtl_system_items_b MSI
         ,ra_customer_trx_lines_all RCTL,
         ra_customer_trx_all RCT
   WHERE  MSI.inventory_item_id = RCTL.inventory_item_id 
   AND RCTL.customer_trx_id = RCT.customer_trx_id
   AND RCT.trx_number = lc_trx_number
   AND RCTL.inventory_item_id IS NOT NULL;
----cursor to fetch the location details
CURSOR lcu_location(lc_trx_number VARCHAR2) IS
   SELECT DISTINCT segment13 
   FROM   xx_om_headers_attributes_all OHAL
         ,oe_order_headers_all OHA
         ,ra_customer_trx_all RCT
   WHERE OHA.attribute6 = OHAL.combination_id
   AND   OHA.order_number = RCT.interface_header_attribute1
   AND   RCT.trx_number = lc_trx_number
   AND   OHA.attribute6 IS NOT NULL
   AND   OHAL.segment13 IS NOT NULL;
BEGIN
  lc_rec_num := p_receipt_number;
  FOR lcu_inv_num_rec IN lcu_inv_num(lc_rec_num)
   LOOP
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Invoice Number '|| lcu_inv_num_rec.trx_number);
   FOR lcu_card_num_rec IN lcu_card_num(lc_rec_num)
    LOOP
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Card Type '|| lcu_card_num_rec.card_type);
      FOR lcu_promo_rec IN lcu_promo(lcu_card_num_rec.card_type,lcu_inv_num_rec.trx_date)
      LOOP
      BEGIN
        SELECT SUM(RCTL.extended_amount)
        INTO   ln_invoice_amount
        FROM   ra_customer_trx_lines_all RCTL
              ,ra_customer_trx_all RCT
        WHERE  RCTL.line_type = 'LINE'
        AND    RCTL.customer_trx_id = RCT.customer_trx_id
        AND    RCT.trx_number = lcu_inv_num_rec.trx_number;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Invoice Amt '|| ln_invoice_amount || ' for ' || lcu_inv_num_rec.trx_number);
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
              /*FND_MESSAGE.SET_NAME('XXFIN','XX_AR_PROMOBINDUP');
              lc_err_msg := FND_MESSAGE.GET;
              fnd_file.put_line(fnd_file.log, lc_err_msg||': '||SQLERRM);*/
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No Invoice Amt for ' || lcu_inv_num_rec.trx_number);
      END;
    IF(ln_invoice_amount >= lcu_promo_rec.minimum_amount) THEN
       FOR lcu_dept_rec IN lcu_dept(lcu_inv_num_rec.trx_number)
        LOOP
        BEGIN
            SELECT DISTINCT APD.promo_values
            INTO   lc_promo_dept
            FROM   xx_ar_promo_header APH
                  ,xx_ar_promo_detail APD
            WHERE APH.promo_id = APD.promo_id
            AND   APD.promo_id = lcu_promo_rec.promo_id
            AND   APD.promo_values IN(lcu_dept_rec.segment12)
            AND   APD.promo_column LIKE 'Dep%';
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Promo Dept for '|| lcu_dept_rec.segment12|| ' is ' || lc_promo_dept);
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No Promo Dept for '|| lcu_dept_rec.segment12);
            END;
        END LOOP;
        FOR lcu_sku_rec in lcu_sku (lcu_inv_num_rec.trx_number)
        LOOP
         BEGIN
            SELECT DISTINCT APD.promo_values
            INTO   lc_promo_sku
            FROM   xx_ar_promo_header APH
                  ,xx_ar_promo_detail APD
            WHERE  APH.promo_id = APD.promo_id
             AND   APD.promo_id = lcu_promo_rec.promo_id
             AND   APH.card_type = lcu_card_num_rec.card_type
             AND   APD.promo_values IN(lcu_sku_rec.segment1)
             AND   APD.promo_column = 'Sku';
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Promo Sku for '|| lcu_sku_rec.segment1 || ' is ' || lc_promo_sku);
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
                FND_MESSAGE.SET_NAME('XXFIN','XX_AR_PROMOBINDUP');
              lc_err_msg := FND_MESSAGE.GET;
              fnd_file.put_line(fnd_file.log, lc_err_msg||': '||SQLERRM);
         --   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No Promo Sku for '|| lcu_sku_rec.segment1);
          END;
        END LOOP;
        FOR lcu_location_rec IN lcu_location(lcu_inv_num_rec.trx_number)
        LOOP
            BEGIN
              SELECT APD.promo_values
              INTO   lc_promo_location
              FROM   xx_ar_promo_header APH
                    ,xx_ar_promo_detail APD
              WHERE  APH.promo_id = APD.promo_id
               AND   APD.promo_id = lcu_promo_rec.promo_id
               AND   APD.promo_column = 'Location'
               AND   APD.promo_values IN(lcu_location_rec.segment13);
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Promo Location for '|| lcu_location_rec.segment13 || 'is' || lc_promo_location);
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No Promo Location ' || lcu_location_rec.segment13);
            END;
            BEGIN
              SELECT FFVN.parent_flex_value
              INTO   lc_district
              FROM   fnd_flex_value_norm_hierarchy FFVN
              WHERE  FFVN.flex_value_set_id = (SELECT FFVL.flex_value_set_id
                                               FROM   fnd_flex_values_vl FFVL
                                               WHERE  FFVL.flex_value = lcu_location_rec.segment13)
              AND    FFVN.child_flex_value_low = lcu_location_rec.segment13
              AND    FFVN.range_attribute = 'C';
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'District for '|| lcu_location_rec.segment13 || 'is' || lc_district);
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No District for '|| lcu_location_rec.segment13);
            END;
            BEGIN
              SELECT FFVN.parent_flex_value
              INTO   lc_region
              FROM   fnd_flex_value_norm_hierarchy FFVN
              WHERE  FFVN.flex_value_set_id = (SELECT FFVL.flex_value_set_id
                                               FROM fnd_flex_values_vl FFVL
                                               WHERE FFVL.flex_value = lcu_location_rec.segment13)
              AND    FFVN.child_flex_value_low = lc_district
              AND    FFVN.range_attribute = 'P';
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Region for '|| lcu_location_rec.segment13 || 'is' || lc_region);
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No Region for '|| lcu_location_rec.segment13);
            END;
            BEGIN
              SELECT APD.promo_values
              INTO   lc_promo_district
              FROM   xx_ar_promo_header APH
                    ,xx_ar_promo_detail APD
              WHERE  APH.promo_id = APD.promo_id
              AND    APD.promo_id = lcu_promo_rec.promo_id
              AND    APD.promo_column = 'District'
              AND    APD.promo_values IN(lc_district);
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Promo District for '|| lc_district ||'is'|| lc_promo_district);
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No Promo District for '|| lcu_location_rec.segment13);
            END;
            BEGIN
              SELECT APD.promo_values
              INTO   lc_promo_region
              FROM   xx_ar_promo_header APH
                    ,xx_ar_promo_detail APD
              WHERE  APH.promo_id = APD.promo_id
               AND   APD.promo_id = lcu_promo_rec.promo_id
               AND   APD.promo_column = 'Region'
               AND   APD.promo_values IN (lc_region);
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Promo Region for '|| lcu_location_rec.segment13 ||'is' || lc_promo_region);
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No Promo Region for '||lcu_location_rec.segment13);
            END;
        END LOOP;
   --  END LOOP;
           IF  (lc_promo_location IS NULL AND lc_promo_district IS NULL 
                AND lc_promo_region IS NULL AND lc_promo_dept IS NOT NULL) THEN
                x_promo_code := lcu_promo_rec.promo_plan_code;
                fnd_file.put_line(fnd_file.output,x_promo_code);
           ELSIF(lc_promo_location IS NULL AND lc_promo_district IS NULL 
                 and lc_promo_region IS NULL AND lc_promo_sku IS NOT NULL) THEN
                x_promo_code := lcu_promo_rec.promo_plan_code;
                fnd_file.put_line(fnd_file.output,x_promo_code);
           ELSIF(lc_promo_location IS NULL AND lc_promo_district IS NULL 
                 AND lc_promo_region IS NULL AND lc_promo_dept IS NOT NULL
                 AND lc_promo_sku IS NOT NULL) THEN
                x_promo_code := lcu_promo_rec.promo_plan_code;
                fnd_file.put_line(fnd_file.output,x_promo_code);
           ELSE
                x_promo_code := NULL;
                fnd_file.put_line(fnd_file.output,x_promo_code);
          END IF;
     END IF;
  END LOOP;
  END LOOP;
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Promotion not available for this card');
END;
end;
/
SHOW ERROR
