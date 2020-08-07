CREATE OR REPLACE
PROCEDURE xx_ar_getpromo_proc(
 p_receipt_number  IN   VARCHAR2
,x_promo_code     OUT  NUMBER
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
-- |                                                                    |
-- +====================================================================+
-- +====================================================================+
-- | Name : xx_ar_getpromo_proc                                         |
-- | Description : This Procedure is to assign                          |
-- | the promotion code to the credit cards with the help of the        |
-- | promotion criterias of the card selected.                           |
-- |                                                                    |
-- | Parameters :  p_receipt_number,x_promo_code                        |
-- |                                                                    |
-- +====================================================================+
lc_rec_num ar_cash_receipts_all.receipt_number%TYPE;
lc_trx_number ra_customer_trx_all.trx_number%TYPE;
ld_trx_date DATE;
ln_card_type_id NUMBER;
lc_card_type xx_ar_promo_header.card_type%TYPE;
ln_promo_id xx_ar_promo_header.promo_id%TYPE;
ln_promo_plan_code xx_ar_promo_header.promo_plan_code%TYPE;
ln_minimum_amount xx_ar_promo_header.minimum_amount%TYPE;
ln_invoice_amount ra_customer_trx_lines_all.extended_amount%TYPE;
ln_customer_trx_id NUMBER;
ln_inv_item_id NUMBER;
lc_location VARCHAR2(50);
lc_promo_sku xx_ar_promo_detail.promo_values%TYPE;
lc_promo_dept xx_ar_promo_detail.promo_values%TYPE;
lc_district VARCHAR2(50);
lc_region VARCHAR2(50);
lc_promo_location xx_ar_promo_detail.promo_values%TYPE;
lc_promo_district xx_ar_promo_detail.promo_values%TYPE;
lc_promo_region xx_ar_promo_detail.promo_values%TYPE;
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
   AND APH.last_update_date=(SELECT MAX(last_update_date) FROM xx_ar_promo_header);
----cursor to fetch the department values
/*CURSOR lcu_dept(lc_trx_number VARCHAR2) IS
   SELECT DISTINCT created_by_store_id
   FROM   xx_om_header_attributes_all OHAL
         ,oe_order_headers_all OHA
         ,ra_customer_trx_all RCT
   WHERE OHA.header_id = OHAL.header_id
   AND   OHA.order_number = RCT.interface_header_attribute1
   AND   RCT.trx_number = lc_trx_number
   AND   OHAL.created_by_store_id IS NOT NULL;*/
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
   SELECT DISTINCT paid_at_store_id 
   FROM   xx_om_header_attributes_all OHAL
         ,oe_order_headers_all OHA
         ,ra_customer_trx_all RCT
   WHERE OHA.header_id = OHAL.header_id
   AND   OHA.order_number = RCT.interface_header_attribute1
   AND   RCT.trx_number = lc_trx_number
   AND   OHAL.paid_at_store_id IS NOT NULL;
BEGIN
  lc_rec_num := p_receipt_number;
  FOR lcu_inv_num_rec IN lcu_inv_num(lc_rec_num)
   LOOP
     DBMS_OUTPUT.PUT_LINE('Invoice Number '|| lcu_inv_num_rec.trx_number);
   FOR lcu_card_num_rec IN lcu_card_num(lc_rec_num)
    LOOP
      DBMS_OUTPUT.PUT_LINE('Card Type '|| lcu_card_num_rec.card_type);
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
        DBMS_OUTPUT.PUT_LINE('Invoice Amt '|| ln_invoice_amount || ' for ' || lcu_inv_num_rec.trx_number);
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No Invoice Amt for ' || lcu_inv_num_rec.trx_number);
      END;
    IF(ln_invoice_amount >= lcu_promo_rec.minimum_amount) THEN
       /* FOR lcu_dept_rec IN lcu_dept(lcu_inv_num_rec.trx_number)
        LOOP
          BEGIN
            SELECT DISTINCT APD.promo_values
            INTO   lc_promo_dept
            FROM   xx_ar_promo_header APH
                  ,xx_ar_promo_detail APD
            WHERE APH.promo_id = APD.promo_id
            AND   APD.promo_id = lcu_promo_rec.promo_id
            AND   APD.promo_values IN(lcu_dept_rec.created_by_store_id)
            AND   APD.promo_column LIKE 'Dep%';
            DBMS_OUTPUT.PUT_LINE('Promo Dept for '|| lcu_dept_rec.created_by_store_id|| ' is ' || lc_promo_dept);
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No Promo Dept for '|| lcu_dept_rec.created_by_store_id);
         END LOOP;*/
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
             DBMS_OUTPUT.PUT_LINE('Promo Sku for '|| lcu_sku_rec.segment1 || ' is ' || lc_promo_sku);
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No Promo Sku for '|| lcu_sku_rec.segment1);
          END;
          END LOOP;
         /*FOR lcu_location_rec IN lcu_location(lcu_inv_num_rec.trx_number)
          LOOP
            BEGIN
              SELECT APD.promo_values
              INTO   lc_promo_location
              FROM   xx_ar_promo_header APH
                    ,xx_ar_promo_detail APD
              WHERE  APH.promo_id = APD.promo_id
               AND   APD.promo_id = lcu_promo_rec.promo_id
               AND   APD.promo_column = 'Location'
               AND   APD.promo_values IN(lcu_location_rec.paid_at_store_id);
               DBMS_OUTPUT.PUT_LINE('Promo Location for '|| lcu_location_rec.paid_at_store_id || 'is' || lc_promo_location);
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
              DBMS_OUTPUT.PUT_LINE('No Promo Location ' || lcu_location_rec.paid_at_store_id);
            END;
            BEGIN
              SELECT FFVN.parent_flex_value
              INTO   lc_district
              FROM   fnd_flex_value_norm_hierarchy FFVN
              WHERE  FFVN.flex_value_set_id = (SELECT FFVL.flex_value_set_id
                                               FROM   fnd_flex_values_vl FFVL
                                               WHERE  FFVL.flex_value = lcu_location_rec.paid_at_store_id)
              AND    FFVN.child_flex_value_low = lcu_location_rec.paid_at_store_id
              AND    FFVN.range_attribute = 'C';
              DBMS_OUTPUT.PUT_LINE('District for '|| lcu_location_rec.paid_at_store_id || 'is' || lc_district);
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
              DBMS_OUTPUT.PUT_LINE('No District for '|| lcu_location_rec.paid_at_store_id);
            END;
            BEGIN
              SELECT FFVN.parent_flex_value
              INTO   lc_region
              FROM   fnd_flex_value_norm_hierarchy FFVN
              WHERE  FFVN.flex_value_set_id = (SELECT FFVL.flex_value_set_id
                                               FROM fnd_flex_values_vl FFVL
                                               WHERE FFVL.flex_value = lcu_location_rec.paid_at_store_id)
              AND    FFVN.child_flex_value_low = lc_district
              AND    FFVN.range_attribute = 'P';
              DBMS_OUTPUT.PUT_LINE('Region for '|| lcu_location_rec.paid_at_store_id || 'is' || lc_region);
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
              DBMS_OUTPUT.PUT_LINE('No Region for '|| lcu_location_rec.paid_at_store_id);
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
              DBMS_OUTPUT.PUT_LINE('Promo District for '|| lc_district ||'is'|| lc_promo_district);
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
              DBMS_OUTPUT.PUT_LINE('No Promo District for '|| lcu_location_rec.paid_at_store_id);
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
               DBMS_OUTPUT.PUT_LINE('Promo Region for '|| lcu_location_rec.paid_at_store_id ||'is' || lc_promo_region);
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
              DBMS_OUTPUT.PUT_LINE('No Promo Region for '||lcu_location_rec.paid_at_store_id);
            END;
          END LOOP;*/
        -- END LOOP;
           IF lc_promo_sku IS NOT NULL THEN
                x_promo_code := lcu_promo_rec.promo_plan_code;
           ELSE
                x_promo_code := NULL;
           END IF;
    END IF;
    END LOOP;
    END LOOP;
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
   DBMS_OUTPUT.PUT_LINE('Promotion not available for this card');
END xx_ar_getpromo_proc;

/

SHOW ERROR