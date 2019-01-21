SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating FUNCTION XX_AR_CBI_INFOCOPY_MINISTMNT

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : Infocopy Ministmnt                                                  |
-- | Description : To pupulate the invoices according to the customer                  |
-- |                documents                                                          |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |1.0                                          Initial Version                       |
-- |1.1       04-Feb-2009  Sambasiva Reddy D     Modified for the Defect # 10750       |
-- |1.2       07-Feb-2009  Ranjith Prabu         Logs added as part of                 |
-- |                                             Defect # 10750                        |
-- |1.3       01-APR-2009  Ranjith Prabu         Changes for defect 13937              |
-- |1.4       02-SEP-2009  Tamil Vendhan L       Modified for R1.1 Defect # 1451       |
-- |                                             (CR 626)                              |
-- |1.5       18-APR-2018  Punit Gupta CG        Retrofit OD AR Reprint Summary/       |
-- |                                             Consolidated Bills- Defect NAIT-31695 |
-- +===================================================================================+


CREATE OR REPLACE FUNCTION XX_AR_CBI_INFOCOPY_MINISTMNT( p_cbi_id              IN NUMBER
                                                        ,p_request_id          IN NUMBER
                                                        ,p_doc_id              IN NUMBER
                                                        ,p_ministmnt_line_type IN VARCHAR2 --EXTAMT_PLUS_DELVY, DISCOUNT ,TAX and TOTAL...
                                                       ) RETURN NUMBER AS
   ln_ext_amt_plus_delvy NUMBER :=0;
   ln_promo_and_disc     NUMBER :=0;
   ln_tax_amount         NUMBER :=0;
   ln_total_amount       NUMBER :=0;
   ln_return_amount      NUMBER :=0;
   lc_error_location     VARCHAR2(2000);  -- added for defect 10750
   lc_debug              VARCHAR2(1000);  -- added for defect 10750
   ln_gc_inv_amt         NUMBER :=0;      -- added for the R1.1 defect # 1451 (CR 626)
   ln_gc_cm_amt          NUMBER :=0;      -- added for the R1.1 defect # 1451 (CR 626)

BEGIN
/**************/
-- below if block commented
-- for code cleanup as part of defect 13937, since there were lots of commented code.
/**************/
/*
 IF p_ministmnt_line_type ='EXTAMT_PLUS_DELVY' THEN
   BEGIN
   lc_error_location := 'Getting Extended amount plus Delivery'; -- added for defect 10750
   lc_debug          := 'p_cbi_id : '|| to_char(p_cbi_id);       -- added for defect 10750
/*   SELECT NVL(SUM(extamt),0) INTO ln_ext_amt_plus_delvy  --Modified for defect # 10750
   FROM (
    SELECT --SUM(NVL(RACTL.EXTENDED_AMOUNT ,0)) extamt   --Commneted for Defcet # 10750
           NVL(SUM(RACTL.EXTENDED_AMOUNT),0) extamt   --Added for Defcet # 10750
    FROM   RA_CUSTOMER_TRX_LINES RACTL
    WHERE  1 = 1
      AND RACTL.interface_line_context ='ORDER ENTRY'
      AND RACTL.LINE_TYPE = 'LINE'
      AND RACTL.DESCRIPTION != 'Tiered Discount'
--      AND RACTL.CUSTOMER_TRX_LINE_ID NOT IN
--      (
--         SELECT RACTL.CUSTOMER_TRX_LINE_ID
--         FROM   RA_CUSTOMER_TRX_LINES  RACTLI
--               ,OE_PRICE_ADJUSTMENTS OEPA
--         WHERE  1 = 1
--         AND RACTL.INTERFACE_LINE_ATTRIBUTE11 = OEPA.PRICE_ADJUSTMENT_ID
--         AND RACTLI.CUSTOMER_TRX_LINE_ID = RACTL.CUSTOMER_TRX_LINE_ID
--      )
   AND EXISTS
        ( SELECT 1
          FROM xx_ar_cons_bills_history od_summbills
          WHERE 1 =1
           --AND od_summbills.attribute13  =p_request_id  --Commneted for defect # 10750
           AND od_summbills.thread_id  =p_request_id  --Added for defect # 10750
           AND od_summbills.cons_inv_id  =p_cbi_id
           AND od_summbills.attribute1   =TO_CHAR(RACTL.customer_trx_id)
           AND od_summbills.attribute8   ='INV_IC'
           AND od_summbills.document_id  =p_doc_id
           AND od_summbills.process_flag !='Y'
          )
    UNION ALL
    SELECT --SUM(NVL(RACTL.EXTENDED_AMOUNT ,0)) extamt  --Commented for Defect # 10750
           NVL(SUM(RACTL.EXTENDED_AMOUNT),0) extamt  --Added for Defect # 10750
    FROM   RA_CUSTOMER_TRX_LINES RACTL
    WHERE  1 = 1
      AND NVL(RACTL.interface_line_context ,'?') !='ORDER ENTRY'
      AND RACTL.LINE_TYPE = 'LINE'
      AND RACTL.DESCRIPTION != 'Tiered Discount'
      AND (RACTL.INTERFACE_LINE_ATTRIBUTE11 IS NULL OR RACTL.INTERFACE_LINE_ATTRIBUTE11 =0)
      AND EXISTS
        ( SELECT 1
          FROM xx_ar_cons_bills_history od_summbills
          WHERE 1 =1
           --AND od_summbills.attribute13  =p_request_id  --Commneted for defect # 10750
           AND od_summbills.thread_id  =p_request_id  --Added for defect # 10750
           AND od_summbills.cons_inv_id  =p_cbi_id
           AND od_summbills.attribute1   =TO_CHAR(RACTL.customer_trx_id)
           AND od_summbills.attribute8   ='INV_IC'
           AND od_summbills.document_id  =p_doc_id
           AND od_summbills.process_flag !='Y'
          )
    );
  */
 /*    --Added for Defect 10750 perf
      SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
      INTO   ln_ext_amt_plus_delvy
      FROM   RA_CUSTOMER_TRX_LINES RACTL
      WHERE  1 = 1
      AND RACTL.LINE_TYPE = 'LINE'
      AND RACTL.DESCRIPTION != 'Tiered Discount'
      AND (RACTL.INTERFACE_LINE_ATTRIBUTE11 IS NULL OR RACTL.INTERFACE_LINE_ATTRIBUTE11 =0)
      AND EXISTS
        ( SELECT 1
          FROM apps.xx_ar_cons_bills_history od_summbills
          WHERE 1 =1
           AND od_summbills.thread_id  = p_request_id
           AND od_summbills.cons_inv_id  =p_cbi_id
           AND od_summbills.attribute1   =RACTL.customer_trx_id
           AND od_summbills.attribute8   ='INV_IC'
           AND od_summbills.document_id  =p_doc_id
           AND od_summbills.process_flag <> 'Y'
          );

  ln_return_amount :=ln_ext_amt_plus_delvy;

      RETURN ln_return_amount;
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     RETURN 0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_infocopy_ministmnt in formula EXTAMT+DELVY');
     fnd_file.put_line(fnd_file.log , 'Error While: ' || lc_error_location||' '|| SQLERRM);     --Added for defect # 10750
     fnd_file.put_line(fnd_file.log , 'Debug:' || lc_debug);                                    --Added for defect # 10750
     RETURN 0;
   END;
 ELSIF p_ministmnt_line_type ='TAX' THEN
   BEGIN
           lc_error_location := 'Getting TAX'; -- added for defect 10750
           lc_debug          := 'p_cbi_id : '|| to_char(p_cbi_id);       -- added for defect 10750

        SELECT --SUM(NVL(RACTL.EXTENDED_AMOUNT ,0))  --Commented for Defect # 10750
               NVL(SUM(RACTL.EXTENDED_AMOUNT),0)  --Added for Defect # 10750
        INTO   ln_tax_amount
        FROM   RA_CUSTOMER_TRX_LINES RACTL
        WHERE  1 = 1
          AND RACTL.LINE_TYPE = 'TAX'
          AND EXISTS
        ( SELECT 1
          FROM xx_ar_cons_bills_history od_summbills
          WHERE 1 =1
           --AND od_summbills.attribute13  =p_request_id  --Commented for defect # 10750
           AND od_summbills.thread_id  =p_request_id  --Added for defect # 10750
           AND od_summbills.cons_inv_id  =p_cbi_id
           AND od_summbills.attribute1   =RACTL.customer_trx_id
           AND od_summbills.attribute8   ='INV_IC'
           AND od_summbills.document_id  =p_doc_id
           AND od_summbills.process_flag !='Y'
          );
      ln_return_amount :=ln_tax_amount;
      RETURN ln_return_amount;
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     RETURN 0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_infocopy_ministmnt in formula TAX');
     fnd_file.put_line(fnd_file.log , 'Error While: ' || lc_error_location||' '|| SQLERRM);     --Added for defect # 10750
     fnd_file.put_line(fnd_file.log , 'Debug:' || lc_debug);                                    --Added for defect # 10750

     RETURN 0;
   END;
 ELSIF p_ministmnt_line_type ='DISCOUNT' THEN
   BEGIN
           lc_error_location := 'Getting DISCOUNT'; -- added for defect 10750
           lc_debug          := 'p_cbi_id : '|| to_char(p_cbi_id);       -- added for defect 10750

    
/*        SELECT --SUM(NVL(DISCOUNT.AMOUNT,0))  --Commented for Defect # 10750
               NVL(SUM(DISCOUNT.AMOUNT),0)  --Added for Defect # 10750
        INTO   ln_promo_and_disc
        FROM (
        SELECT --SUM(NVL(RACTL.EXTENDED_AMOUNT ,0)) AMOUNT  --Commented for Defect # 10750
               NVL(SUM(RACTL.EXTENDED_AMOUNT),0) AMOUNT  --Added for Defect # 10750
        FROM   RA_CUSTOMER_TRX_LINES RACTL
              ,OE_PRICE_ADJUSTMENTS  OEPA
        WHERE  1 = 1
          AND RACTL.LINE_TYPE = 'LINE'
          AND RACTL.INTERFACE_LINE_CONTEXT ='ORDER ENTRY'  --For release 1 we need invoices sourced from AOPS only
          AND RACTL.INTERFACE_LINE_ATTRIBUTE11   = to_char(OEPA.PRICE_ADJUSTMENT_ID)
          AND EXISTS
        ( SELECT 1
          FROM xx_ar_cons_bills_history od_summbills
          WHERE 1 =1
           --AND od_summbills.attribute13  =p_request_id  --Commented for defect # 10750
           AND od_summbills.thread_id  =p_request_id  --Added for defect # 10750
           AND od_summbills.cons_inv_id  =p_cbi_id
           AND od_summbills.attribute1   =TO_CHAR(RACTL.customer_trx_id)
           AND od_summbills.attribute8   ='INV_IC'
           AND od_summbills.document_id  =p_doc_id
           AND od_summbills.process_flag !='Y'
          )
        UNION ALL
        SELECT --SUM(NVL(RACTL.EXTENDED_AMOUNT ,0))  --Commented for Defect # 10750
               NVL(SUM(RACTL.EXTENDED_AMOUNT),0)  --Commented for Defect # 10750
        FROM   RA_CUSTOMER_TRX_LINES RACTL
        WHERE  1 = 1
          AND ractl.line_type = 'LINE'
          AND NVL(ractl.interface_line_context, '?') != 'ORDER ENTRY'
          AND ractl.description = 'Tiered Discount'
          AND EXISTS
        ( SELECT 1
          FROM xx_ar_cons_bills_history od_summbills
          WHERE 1 =1
           --AND od_summbills.attribute13  =p_request_id  --Commented for defect # 10750
           AND od_summbills.thread_id  =p_request_id  --Added for defect # 10750
           AND od_summbills.cons_inv_id  =p_cbi_id
           AND od_summbills.attribute1   =TO_CHAR(RACTL.customer_trx_id)
           AND od_summbills.attribute8   ='INV_IC'
           AND od_summbills.document_id  =p_doc_id
           AND od_summbills.process_flag !='Y'
          )
        ) DISCOUNT;
  */

       --Added for Defect 10750 perf

 /*       SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
        INTO   ln_promo_and_disc
        FROM   RA_CUSTOMER_TRX_LINES RACTL
              ,OE_PRICE_ADJUSTMENTS  OEPA
        WHERE  1 = 1
          AND RACTL.LINE_TYPE = 'LINE'
          AND RACTL.INTERFACE_LINE_ATTRIBUTE11   = OEPA.PRICE_ADJUSTMENT_ID
          AND EXISTS
        ( SELECT 1
          FROM apps.xx_ar_cons_bills_history od_summbills
          WHERE 1 =1
           AND od_summbills.thread_id  =p_request_id
           AND od_summbills.cons_inv_id  =p_cbi_id
           AND od_summbills.attribute1   =RACTL.customer_trx_id
           AND od_summbills.attribute8   ='INV_IC'
           AND od_summbills.document_id  =p_doc_id
           AND od_summbills.process_flag !='Y'
          );

     ln_return_amount :=ln_promo_and_disc;
      RETURN ln_return_amount;
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     RETURN 0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_infocopy_ministmnt in formula DISCOUNTS');
     fnd_file.put_line(fnd_file.log , 'Error While: ' || lc_error_location||' '|| SQLERRM);     --Added for defect # 10750
     fnd_file.put_line(fnd_file.log , 'Debug:' || lc_debug);                                    --Added for defect # 10750

     RETURN 0;
   END;
 ELSIF p_ministmnt_line_type ='TOTAL' THEN

   BEGIN
           lc_error_location := 'Getting TOTAL'; -- added for defect 10750
           lc_debug          := 'p_cbi_id : '|| to_char(p_cbi_id);       -- added for defect 10750

   /*SELECT NVL(SUM(extamt),0) INTO ln_ext_amt_plus_delvy  --Modified for the Defect # 10750
   FROM (
    SELECT --SUM(NVL(RACTL.EXTENDED_AMOUNT ,0)) extamt  -- Commented for Defect # 10750
           NVL(SUM(RACTL.EXTENDED_AMOUNT),0) extamt  -- Added for Defect # 10750
    FROM   RA_CUSTOMER_TRX_LINES RACTL
    WHERE  1 = 1
      AND RACTL.interface_line_context ='ORDER ENTRY'
      AND RACTL.LINE_TYPE = 'LINE'
      AND RACTL.DESCRIPTION != 'Tiered Discount'
--      AND RACTL.CUSTOMER_TRX_LINE_ID NOT IN
--         (
--          SELECT RACTL.CUSTOMER_TRX_LINE_ID
--          FROM   RA_CUSTOMER_TRX_LINES  RACTLI
--                ,OE_PRICE_ADJUSTMENTS OEPA
--          WHERE  1 = 1
--          AND RACTL.INTERFACE_LINE_ATTRIBUTE11 = OEPA.PRICE_ADJUSTMENT_ID
--          AND RACTLI.CUSTOMER_TRX_LINE_ID = RACTL.CUSTOMER_TRX_LINE_ID
--         )
     AND EXISTS
        ( SELECT 1
          FROM xx_ar_cons_bills_history od_summbills
          WHERE 1 =1
           --AND od_summbills.attribute13  =p_request_id  --Commnted for defect # 10750
           AND od_summbills.thread_id  =p_request_id  --Added for defect # 10750
           AND od_summbills.cons_inv_id  =p_cbi_id
           AND od_summbills.attribute1   =TO_CHAR(RACTL.customer_trx_id)
           AND od_summbills.attribute8   ='INV_IC'
           AND od_summbills.document_id  =p_doc_id
           AND od_summbills.process_flag !='Y'
          )
    UNION ALL
    SELECT --SUM(NVL(RACTL.EXTENDED_AMOUNT ,0)) extamt  --Commented for Defect # 10750
           NVL(SUM(RACTL.EXTENDED_AMOUNT),0) extamt  --Added for Defect # 10750
    FROM   RA_CUSTOMER_TRX_LINES RACTL
    WHERE  1 = 1
      AND NVL(RACTL.interface_line_context ,'?') !='ORDER ENTRY'
      AND RACTL.LINE_TYPE = 'LINE'
      AND RACTL.DESCRIPTION != 'Tiered Discount'
      AND (RACTL.INTERFACE_LINE_ATTRIBUTE11 IS NULL OR RACTL.INTERFACE_LINE_ATTRIBUTE11 =0)
      AND EXISTS
        ( SELECT 1
          FROM xx_ar_cons_bills_history od_summbills
          WHERE 1 =1
           --AND od_summbills.attribute13  =p_request_id  --samba
           AND od_summbills.thread_id  =p_request_id  --samba
           AND od_summbills.cons_inv_id  =p_cbi_id
           AND od_summbills.attribute1   =TO_CHAR(RACTL.customer_trx_id)
           AND od_summbills.attribute8   ='INV_IC'
           AND od_summbills.document_id  =p_doc_id
           AND od_summbills.process_flag !='Y'
          )
    );
    */
    
/*         --Added for Defect 10750 perf
      SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
      INTO   ln_ext_amt_plus_delvy
      FROM   RA_CUSTOMER_TRX_LINES RACTL
      WHERE  1 = 1
      AND RACTL.LINE_TYPE = 'LINE'
      AND RACTL.DESCRIPTION != 'Tiered Discount'
      AND (RACTL.INTERFACE_LINE_ATTRIBUTE11 IS NULL OR RACTL.INTERFACE_LINE_ATTRIBUTE11 =0)
      AND EXISTS
        ( SELECT 1
          FROM apps.xx_ar_cons_bills_history od_summbills
          WHERE 1 =1
           AND od_summbills.thread_id  = p_request_id
           AND od_summbills.cons_inv_id  =p_cbi_id
           AND od_summbills.attribute1   =RACTL.customer_trx_id
           AND od_summbills.attribute8   ='INV_IC'
           AND od_summbills.document_id  =p_doc_id
           AND od_summbills.process_flag <> 'Y'
          );
 
    ln_return_amount :=ln_return_amount + ln_ext_amt_plus_delvy;
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     ln_return_amount :=ln_return_amount+0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_infocopy_ministmnt in formula EXTAMT+DELVY');
     ln_return_amount :=ln_return_amount+0;
     fnd_file.put_line(fnd_file.log , 'Error While: ' || lc_error_location||' '|| SQLERRM);     --Added for defect # 10750
     fnd_file.put_line(fnd_file.log , 'Debug:' || lc_debug);                                    --Added for defect # 10750

   END;
   BEGIN
           lc_error_location := 'Getting TAX -- TOTAL'; -- added for defect 10750
           lc_debug          := 'p_cbi_id : '|| to_char(p_cbi_id);       -- added for defect 10750

        SELECT --SUM(NVL(RACTL.EXTENDED_AMOUNT ,0))   --Commented for Defect # 10750
               NVL(SUM(RACTL.EXTENDED_AMOUNT),0)   --Added for Defect # 10750
        INTO   ln_tax_amount
        FROM   RA_CUSTOMER_TRX_LINES RACTL
        WHERE  1 = 1
          AND RACTL.LINE_TYPE = 'TAX'
          AND EXISTS
        ( SELECT 1
          FROM xx_ar_cons_bills_history od_summbills
          WHERE 1 =1
           --AND od_summbills.attribute13  =p_request_id  --Commented for defect # 10750
           AND od_summbills.thread_id  =p_request_id  --Added for defect # 10750
           AND od_summbills.cons_inv_id  =p_cbi_id
           AND od_summbills.attribute1   =RACTL.customer_trx_id
           AND od_summbills.attribute8   ='INV_IC'
           AND od_summbills.document_id  =p_doc_id
           AND od_summbills.process_flag !='Y'
          );
      ln_return_amount :=ln_return_amount + ln_tax_amount;
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     ln_return_amount :=ln_return_amount+0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_infocopy_ministmnt in formula TAX');
     ln_return_amount :=ln_return_amount+0;
     fnd_file.put_line(fnd_file.log , 'Error While: ' || lc_error_location||' '|| SQLERRM);     --Added for defect # 10750
     fnd_file.put_line(fnd_file.log , 'Debug:' || lc_debug);                                    --Added for defect # 10750

   END;
   BEGIN
           lc_error_location := 'Getting Promo and discount'; -- added for defect 10750
           lc_debug          := 'p_cbi_id : '|| to_char(p_cbi_id);       -- added for defect 10750

/*        SELECT --SUM(NVL(DISCOUNT.AMOUNT,0))   -- Commented for Defect # 10750
               NVL(SUM(DISCOUNT.AMOUNT),0)   -- Added for Defect # 10750
        INTO   ln_promo_and_disc
        FROM (
        SELECT --SUM(NVL(RACTL.EXTENDED_AMOUNT ,0)) AMOUNT   -- Commented for Defect # 10750
               NVL(SUM(RACTL.EXTENDED_AMOUNT),0) AMOUNT   -- Commented for Defect # 10750
        FROM   RA_CUSTOMER_TRX_LINES RACTL
              ,OE_PRICE_ADJUSTMENTS  OEPA
        WHERE  1 = 1
          AND RACTL.LINE_TYPE = 'LINE'
          AND RACTL.INTERFACE_LINE_CONTEXT ='ORDER ENTRY'  --For release 1 we need invoices sourced from AOPS only
          AND RACTL.INTERFACE_LINE_ATTRIBUTE11   = to_char(OEPA.PRICE_ADJUSTMENT_ID)
          AND EXISTS
        ( SELECT 1
          FROM xx_ar_cons_bills_history od_summbills
          WHERE 1 =1
           --AND od_summbills.attribute13  =p_request_id  --Commented for defect # 10750
           AND od_summbills.thread_id  =p_request_id  --Added for defect # 10750
           AND od_summbills.cons_inv_id  =p_cbi_id
           AND od_summbills.attribute1   =TO_CHAR(RACTL.customer_trx_id)
           AND od_summbills.attribute8   ='INV_IC'
           AND od_summbills.document_id  =p_doc_id
           AND od_summbills.process_flag !='Y'
          )
        UNION ALL

        SELECT --SUM(NVL(RACTL.EXTENDED_AMOUNT ,0))   -- Commented for Defect # 10750
               NVL(SUM(RACTL.EXTENDED_AMOUNT ),0)   -- Added for Defect # 10750
        FROM   RA_CUSTOMER_TRX_LINES RACTL
        WHERE  1 = 1
          AND ractl.line_type = 'LINE'
          AND NVL(ractl.interface_line_context, '?') != 'ORDER ENTRY'
          AND ractl.description = 'Tiered Discount'
          AND EXISTS
        ( SELECT 1
          FROM xx_ar_cons_bills_history od_summbills
          WHERE 1 =1
           --AND od_summbills.attribute13  =p_request_id  --Commented for defect # 10750
           AND od_summbills.thread_id  =p_request_id  --Added for defect # 10750
           AND od_summbills.cons_inv_id  =p_cbi_id
           AND od_summbills.attribute1   =TO_CHAR(RACTL.customer_trx_id)
           AND od_summbills.attribute8   ='INV_IC'
           AND od_summbills.document_id  =p_doc_id
           AND od_summbills.process_flag !='Y'
          )
        ) DISCOUNT;
  */
  
         --Added for Defect 10750 perf

/*        SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
        INTO   ln_promo_and_disc
        FROM   RA_CUSTOMER_TRX_LINES RACTL
              ,OE_PRICE_ADJUSTMENTS  OEPA
        WHERE  1 = 1
          AND RACTL.LINE_TYPE = 'LINE'
          AND RACTL.INTERFACE_LINE_ATTRIBUTE11   = OEPA.PRICE_ADJUSTMENT_ID
          AND EXISTS
        ( SELECT 1
          FROM apps.xx_ar_cons_bills_history od_summbills
          WHERE 1 =1
           AND od_summbills.thread_id  =p_request_id
           AND od_summbills.cons_inv_id  =p_cbi_id
           AND od_summbills.attribute1   =RACTL.customer_trx_id
           AND od_summbills.attribute8   ='INV_IC'
           AND od_summbills.document_id  =p_doc_id
           AND od_summbills.process_flag !='Y'
          );

  ln_return_amount :=ln_return_amount + ln_promo_and_disc;
      RETURN ln_return_amount;
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     ln_return_amount :=ln_return_amount+0;
      RETURN ln_return_amount;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_infocopy_ministmnt in formula DISCOUNTS');
     ln_return_amount :=ln_return_amount+0;
     fnd_file.put_line(fnd_file.log , 'Error While: ' || lc_error_location||' '|| SQLERRM);     --Added for defect # 10750
     fnd_file.put_line(fnd_file.log , 'Debug:' || lc_debug);                                    --Added for defect # 10750

      RETURN ln_return_amount;
   END;
 ELSE
      RETURN(0);
 END IF;*/
   -- changes for defect 13937 starts
   IF (p_ministmnt_line_type ='EXTAMT_PLUS_DELVY') THEN

      BEGIN

         lc_error_location := 'Getting Extended amount plus Delivery';
         lc_debug          := 'p_cbi_id : '|| to_char(p_cbi_id);

         SELECT NVL(SUM(RACTL.extended_amount),0)
         INTO   ln_ext_amt_plus_delvy
         FROM   ra_customer_trx_lines_all RACTL
         WHERE  1                                = 1
         AND    RACTL.line_type                  = 'LINE'
         AND    RACTL.interface_line_attribute11 = '0'      -- avoids discounts
         AND    EXISTS (SELECT 1
                        FROM apps.xx_ar_cons_bills_history od_summbills
                        WHERE 1                       = 1
                        AND od_summbills.thread_id    = p_request_id
                        AND od_summbills.cons_inv_id  = p_cbi_id
                        AND od_summbills.attribute1   = RACTL.customer_trx_id
                        AND od_summbills.attribute8   = 'INV_IC'
                        AND od_summbills.document_id  = p_doc_id
                        AND od_summbills.process_flag <> 'Y'
                       );

         RETURN ln_ext_amt_plus_delvy;

      EXCEPTION
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error at xx_ar_cbi_infocopy_ministmnt in formula EXTAMT+DELVY');
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error While: ' || lc_error_location||' '|| SQLERRM);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Debug:' || lc_debug);
            RETURN 0;

      END;

   ELSIF (p_ministmnt_line_type ='TAX') THEN

      BEGIN

         lc_error_location := 'Getting TAX';
         lc_debug          := 'p_cbi_id : '|| to_char(p_cbi_id);

         SELECT NVL(SUM(RACTL.extended_amount),0)
         INTO   ln_tax_amount
         FROM   RA_CUSTOMER_TRX_LINES_ALL RACTL
         WHERE  1               = 1
         AND    RACTL.LINE_TYPE = 'TAX'
         AND    EXISTS ( SELECT 1
                         FROM xx_ar_cons_bills_history od_summbills
                         WHERE 1                       = 1
                         AND od_summbills.thread_id    = p_request_id
                         AND od_summbills.cons_inv_id  = p_cbi_id
                         AND od_summbills.attribute1   = RACTL.customer_trx_id
                         AND od_summbills.attribute8   = 'INV_IC'
                         AND od_summbills.document_id  = p_doc_id
                         AND od_summbills.process_flag !='Y'
                       );

         RETURN ln_tax_amount;

      EXCEPTION
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error at xx_ar_cbi_infocopy_ministmnt in formula TAX');
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error While: ' || lc_error_location||' '|| SQLERRM);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Debug:' || lc_debug);
         RETURN 0;

      END;

   ELSIF (p_ministmnt_line_type ='DISCOUNT') THEN

      BEGIN
         lc_error_location := 'Getting DISCOUNT';
         lc_debug          := 'p_cbi_id : '|| to_char(p_cbi_id);

         SELECT NVL(SUM(RACTL.extended_amount),0)
         INTO   ln_promo_and_disc
         FROM   ra_customer_trx_lines_all RACTL
		        ,xx_oe_price_adjustments_v OEPA  -- Commented and Changed by Punit CG on 18-APR-2018 for Defect NAIT-31695
               --,oe_price_adjustments  OEPA
         WHERE  1                               = 1
         AND RACTL.line_type                    = 'LINE'
         AND RACTL.interface_line_attribute11   = OEPA.price_adjustment_id
         AND EXISTS ( SELECT 1
                      FROM apps.xx_ar_cons_bills_history od_summbills
                      WHERE 1 =1
                      AND od_summbills.thread_id    = p_request_id
                      AND od_summbills.cons_inv_id  = p_cbi_id
                      AND od_summbills.attribute1   = RACTL.customer_trx_id
                      AND od_summbills.attribute8   = 'INV_IC'
                      AND od_summbills.document_id  = p_doc_id
                      AND od_summbills.process_flag != 'Y'
                    );
-- Start of changes for R1.1 Defect # 1451 (CR 626)

         lc_error_location := 'Getting the total gift card amount for Invoices';
         lc_debug          := 'p_cbi_id : '|| to_char(p_cbi_id);
         SELECT  NVL(SUM(OP.payment_amount),0)
         INTO    ln_gc_inv_amt
         FROM    --apps.oe_payments OP
		         xx_oe_payments_v OP -- Commented and Changed by Punit CG on 18-APR-2018 for Defect NAIT-31695
                ,ra_customer_trx_all RCT
                ,apps.xx_ar_cons_bills_history od_summbills
                ,ra_cust_trx_types_all RCTT
         WHERE   OP.header_id              =  RCT.attribute14
         AND     od_summbills.attribute1   =  RCT.customer_trx_id
         AND     RCT.cust_trx_type_id      =  RCTT.cust_trx_type_id 
         AND     od_summbills.thread_id    =  p_request_id
         AND     od_summbills.cons_inv_id  =  p_cbi_id
         AND     od_summbills.document_id  =  p_doc_id
         AND     RCTT.type                 =  'INV'
         AND     od_summbills.attribute8   =  'INV_IC'
         AND     od_summbills.process_flag != 'Y';

         lc_error_location := 'Getting the total gift card amount for credit memos';
         lc_debug          := 'p_cbi_id : '|| to_char(p_cbi_id);
         SELECT  NVL(SUM(ORT.credit_amount),0) 
         INTO    ln_gc_cm_amt
         FROM    apps.xx_om_return_tenders_all ORT
                ,ra_customer_trx_all RCT
                ,ra_cust_trx_types_all RCTT
                ,apps.xx_ar_cons_bills_history od_summbills
         WHERE   ORT.header_id             =  RCT.attribute14
         AND     od_summbills.thread_id    =  p_request_id
         AND     od_summbills.cons_inv_id  =  p_cbi_id
         AND     od_summbills.attribute1   =  RCT.customer_trx_id
         AND     RCT.cust_trx_type_id      =  RCTT.cust_trx_type_id 
         AND     od_summbills.document_id  =  p_doc_id
         AND     RCTT.type                 =  'CM'
         AND     od_summbills.attribute8   =  'INV_IC'
         AND     od_summbills.process_flag != 'Y';

         ln_promo_and_disc := ln_promo_and_disc - ln_gc_inv_amt + ln_gc_cm_amt;

--End of changes for R1.1 Defect # 1451 (CR 626)

         RETURN ln_promo_and_disc;

      EXCEPTION
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error at xx_ar_cbi_infocopy_ministmnt in formula DISCOUNTS');
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error While: ' || lc_error_location||' '|| SQLERRM); 
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Debug:' || lc_debug);
            RETURN 0;
      END;

   ELSIF p_ministmnt_line_type ='TOTAL' THEN

      BEGIN

         lc_error_location := 'Getting TOTAL';
         lc_debug          := 'p_cbi_id : '|| to_char(p_cbi_id);

         SELECT NVL(SUM(RACTL.extended_amount),0)
         INTO   ln_return_amount
         FROM   ra_customer_trx_lines_all RACTL
         WHERE  1 = 1
         AND EXISTS ( SELECT 1
                      FROM apps.xx_ar_cons_bills_history od_summbills
                      WHERE 1 =1
                      AND od_summbills.thread_id    = p_request_id
                      AND od_summbills.cons_inv_id  = p_cbi_id
                      AND od_summbills.attribute1   = RACTL.customer_trx_id
                      AND od_summbills.attribute8   = 'INV_IC'
                      AND od_summbills.document_id  = p_doc_id
                      AND od_summbills.process_flag <> 'Y'
                     );

-- Start of changes for R1.1 Defect # 1451 (CR 626)

         lc_error_location := 'Getting the total gift card amount for Invoices';
         lc_debug          := 'p_cbi_id : '|| to_char(p_cbi_id);
         SELECT  NVL(SUM(OP.payment_amount),0)
         INTO    ln_gc_inv_amt
         FROM    --apps.oe_payments OP
		         xx_oe_payments_v OP -- Commented and Changed by Punit CG on 18-APR-2018 for Defect NAIT-31695
                ,ra_customer_trx_all RCT
                ,apps.xx_ar_cons_bills_history od_summbills
                ,ra_cust_trx_types_all RCTT
         WHERE   OP.header_id              =  RCT.attribute14
         AND     od_summbills.attribute1   =  RCT.customer_trx_id
         AND     RCT.cust_trx_type_id      =  RCTT.cust_trx_type_id 
         AND     od_summbills.thread_id    =  p_request_id
         AND     od_summbills.cons_inv_id  =  p_cbi_id
         AND     od_summbills.document_id  =  p_doc_id
         AND     RCTT.type                 =  'INV'
         AND     od_summbills.attribute8   =  'INV_IC'
         AND     od_summbills.process_flag != 'Y';

         lc_error_location := 'Getting the total gift card amount for credit memos';
         lc_debug          := 'p_cbi_id : '|| to_char(p_cbi_id);
         SELECT  NVL(SUM(ORT.credit_amount),0) 
         INTO    ln_gc_cm_amt
         FROM    apps.xx_om_return_tenders_all ORT
                ,ra_customer_trx_all RCT
                ,ra_cust_trx_types_all RCTT
                ,apps.xx_ar_cons_bills_history od_summbills
         WHERE   ORT.header_id             =  RCT.attribute14
         AND     od_summbills.thread_id    =  p_request_id
         AND     od_summbills.cons_inv_id  =  p_cbi_id
         AND     od_summbills.attribute1   =  RCT.customer_trx_id
         AND     RCT.cust_trx_type_id      =  RCTT.cust_trx_type_id 
         AND     od_summbills.document_id  =  p_doc_id
         AND     RCTT.type                 =  'CM'
         AND     od_summbills.attribute8   =  'INV_IC'
         AND     od_summbills.process_flag != 'Y';

         ln_return_amount := ln_return_amount - ln_gc_inv_amt + ln_gc_cm_amt;

--End of changes for R1.1 Defect # 1451 (CR 626)

         RETURN ln_return_amount;
      EXCEPTION
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error at xx_ar_cbi_infocopy_ministmnt in formula TOTAL');
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error While: ' || lc_error_location||' '|| SQLERRM);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Debug:' || lc_debug);
            RETURN 0;
      END;
   ELSE

      RETURN(0);

   END IF;

-- Changes for defect 13937 ends
EXCEPTION
   WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in function xx_ar_cbi_infocopy_ministmnt');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Request           ID :'||p_request_id);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Infocopy Cons Inv ID :'||p_cbi_id);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Document          ID :'||p_doc_id);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Type                 :'||p_ministmnt_line_type  );
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error While: ' || lc_error_location||' '|| SQLERRM);     --Added for defect # 10750
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Debug:' || lc_debug);                                    --Added for defect # 10750

   RETURN 0;

END xx_ar_cbi_infocopy_ministmnt;
/
SHOW ERR