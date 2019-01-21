SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating FUNCTION XX_AR_CBI_PAYDOC_MINISTMNT

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : Paydoc   Ministmnt                                                  |
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
-- |1.2       07-Feb-2009  Ranjith Prabhu        Logs added as part of                 |
-- |                                             Defect # 10750                        |
-- |1.3       23-Feb-2009  Ranjith Prabu         Changes for defect 12925              |
-- |1.4       01-APR-2009  Ranjith Prabu         Changes for defect 13937              |
-- |1.5       02-SEP-2009  Ranjith Prabu         Changes for defect 1451 CR 626        |
-- |1.6       18-APR-2018  Punit Gupta CG        Retrofit OD AR Reprint Summary/       |
-- |                                             Consolidated Bills- Defect NAIT-31695 |
-- +===================================================================================+


CREATE OR REPLACE FUNCTION XX_AR_CBI_PAYDOC_MINISTMNT ( p_cbi_id IN           NUMBER
                                                       ,p_ministmnt_line_type VARCHAR2 --EXTAMT_PLUS_DELVY, DISCOUNT ,TAX and TOTAL...               
                                                       )
RETURN NUMBER AS
   ln_ext_amt_plus_delvy NUMBER :=0;
   ln_promo_and_disc     NUMBER :=0;
   ln_tax_amount         NUMBER :=0;
   ln_total_amount       NUMBER :=0;
   ln_return_amount      NUMBER :=0;
   lc_error_location    VARCHAR2(2000);  -- added for defect 10750
   lc_debug              VARCHAR2(1000);  -- added for defect 10750
   ln_gc_inv_amt         NUMBER;          -- added for defect 1451 CR 626
   ln_gc_cm_amt          NUMBER;          -- added for defect 1451 CR 626

BEGIN  
/**************/
-- below if block commented
-- for code cleanup as part of defect 13937, since there were lots of commented code.
/**************/
/* IF p_ministmnt_line_type ='EXTAMT_PLUS_DELVY' THEN
   BEGIN
   lc_error_location := 'Getting Extended amount plus Delivery'; -- added for defect 10750
   lc_debug          := 'p_cbi_id : '|| to_char(p_cbi_id);       -- added for defect 10750

  -- Commented For the Defect 12925 -- Start
/*   SELECT SUM(extamt) INTO ln_ext_amt_plus_delvy
   FROM (
    SELECT --SUM(NVL(RACTL.EXTENDED_AMOUNT ,0)) extamt  -- Commented for Defect # 10750
           NVL(SUM(RACTL.EXTENDED_AMOUNT),0) extamt  -- Added for Defect # 10750
    FROM   RA_CUSTOMER_TRX_LINES RACTL
          ,AR_CONS_INV_TRX_LINES CONSINV_LINES    --Added for the defect 12925
    WHERE  1 = 1   
      AND RACTL.interface_line_context ='ORDER ENTRY'
      AND RACTL.LINE_TYPE = 'LINE'
      AND RACTL.DESCRIPTION != 'Tiered Discount' 
      AND RACTL.CUSTOMER_TRX_ID = CONSINV_LINES.CUSTOMER_TRX_ID  --Added for the defect 12925
      AND CONSINV_LINES.CONS_INV_ID = p_cbi_id
--      AND RACTL.CUSTOMER_TRX_LINE_ID NOT IN 
--      (
--         SELECT RACTL.CUSTOMER_TRX_LINE_ID
--         FROM   RA_CUSTOMER_TRX_LINES  RACTLI
--               ,OE_PRICE_ADJUSTMENTS OEPA
--         WHERE  1 = 1         
--         AND RACTL.INTERFACE_LINE_ATTRIBUTE11 = OEPA.PRICE_ADJUSTMENT_ID
--         AND RACTLI.CUSTOMER_TRX_LINE_ID = RACTL.CUSTOMER_TRX_LINE_ID
--      )    
    /*  AND RACTL.CUSTOMER_TRX_ID IN (       Commented for the defect 12925
            SELECT CONSINV_LINES.CUSTOMER_TRX_ID
            FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
            WHERE CONSINV_LINES.CONS_INV_ID                  =p_cbi_id
            ) 
    UNION ALL            
    SELECT --SUM(NVL(RACTL.EXTENDED_AMOUNT ,0)) extamt  -- Commented for Defect # 10750
           NVL(SUM(RACTL.EXTENDED_AMOUNT),0) extamt  -- Added for Defect # 10750
    FROM   RA_CUSTOMER_TRX_LINES RACTL
          ,AR_CONS_INV_TRX_LINES CONSINV_LINES    --Added for the defect 12925
    WHERE  1 = 1   
      AND NVL(RACTL.interface_line_context ,'?') !='ORDER ENTRY'    
      AND RACTL.LINE_TYPE = 'LINE'
      AND RACTL.DESCRIPTION != 'Tiered Discount'
      AND RACTL.CUSTOMER_TRX_ID = CONSINV_LINES.CUSTOMER_TRX_ID    --Added for the defect 12925
      AND CONSINV_LINES.CONS_INV_ID =p_cbi_id
/*      AND RACTL.CUSTOMER_TRX_ID IN (            Commented for the defect 12925
            SELECT CONSINV_LINES.CUSTOMER_TRX_ID
            FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
            WHERE CONSINV_LINES.CONS_INV_ID =p_cbi_id
            )
      AND (ractl.interface_line_attribute11 IS NULL OR ractl.interface_line_attribute11 =0)
    );    */    -- Commented For the Defect 12925 -- END
    
      -- Added For the Defect 12925

  /*  SELECT NVL (SUM(ractl.extended_amount), 0)
              INTO ln_ext_amt_plus_delvy
              FROM ra_customer_trx_lines_all RACTL
                  ,ar_cons_inv_trx_all CONSINV_LINES
             WHERE 1 = 1
               AND RACTL.line_type = 'LINE'
               AND RACTL.description != 'Tiered Discount'
               AND RACTL.customer_trx_id = CONSINV_LINES.customer_trx_id
               AND CONSINV_LINES.cons_inv_id = p_cbi_id;

  lc_return_amount :=ln_ext_amt_plus_delvy; 
      RETURN lc_return_amount;            
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     RETURN 0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_paydoc_ministmnt in formula EXTAMT+DELVY');
     fnd_file.put_line(fnd_file.log , 'Error While: ' || lc_error_location||' '|| SQLERRM);     --Added for defect # 10750
     fnd_file.put_line(fnd_file.log , 'Debug:' || lc_debug);                                    --Added for defect # 10750

     RETURN 0;   
   END;               
 ELSIF p_ministmnt_line_type ='TAX' THEN
   BEGIN 
     /*
        SELECT SUM(RACTL.EXTENDED_AMOUNT)
        INTO   ln_tax_amount
        FROM   RA_CUSTOMER_TRX_LINES RACTL 
        WHERE  1 = 1               
          AND RACTL.LINE_TYPE = 'TAX'
          --AND RACTL.INTERFACE_LINE_CONTEXT ='ORDER ENTRY'  --For release 1 we need invoices sourced from AOPS only        
          AND RACTL.CUSTOMER_TRX_ID IN (
                SELECT CONSINV_LINES.CUSTOMER_TRX_ID
                FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
                WHERE CONSINV_LINES.CONS_INV_ID            =p_cbi_id
                ); 
     */                 
  /*         lc_error_location := 'Getting TAX'; -- added for defect 10750
           lc_debug          := 'p_cbi_id : '|| to_char(p_cbi_id);       -- added for defect 10750

        SELECT --SUM(nvl(tax_original ,0)) -- Commented for Defect # 10750
               NVL(SUM(tax_original),0) -- Added for Defect # 10750
        INTO   ln_tax_amount
        FROM ar_cons_inv_trx
        WHERE cons_inv_id =p_cbi_id 
          AND transaction_type IN
                       (
                         'INVOICE'
                        ,'CREDIT_MEMO'
                        --,'ADJUSTMENT'                        
                       );                                       
      lc_return_amount :=ln_tax_amount; 
      RETURN lc_return_amount;
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     RETURN 0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_paydoc_ministmnt in formula TAX');
     fnd_file.put_line(fnd_file.log , 'Error While: ' || lc_error_location||' '|| SQLERRM);     --Added for defect # 10750
     fnd_file.put_line(fnd_file.log , 'Debug:' || lc_debug);                                    --Added for defect # 10750

     RETURN 0;   
   END;       
 ELSIF p_ministmnt_line_type ='DISCOUNT' THEN
   BEGIN
           lc_error_location := 'Getting DISCOUNT'; -- added for defect 10750
           lc_debug          := 'p_cbi_id : '|| to_char(p_cbi_id);       -- added for defect 10750

     -- Commented For the Defect 12925 -- Start
/*        SELECT --SUM(nvl(DISCOUNT.AMOUNT ,0)) -- Commented for Defect # 10750
               NVL(SUM(DISCOUNT.AMOUNT),0) -- Added for Defect # 10750
        INTO   ln_promo_and_disc
        FROM (
        SELECT --SUM(RACTL.EXTENDED_AMOUNT) AMOUNT -- Commented for Defect # 10750
               NVL(SUM(RACTL.EXTENDED_AMOUNT),0) AMOUNT -- Added for Defect # 10750
        FROM   RA_CUSTOMER_TRX_LINES RACTL
              ,OE_PRICE_ADJUSTMENTS  OEPA
        WHERE  1 = 1
          AND RACTL.LINE_TYPE = 'LINE' 
          AND RACTL.INTERFACE_LINE_CONTEXT ='ORDER ENTRY'  --For release 1 we need invoices sourced from AOPS only           
          AND RACTL.INTERFACE_LINE_ATTRIBUTE11 =to_char(OEPA.PRICE_ADJUSTMENT_ID) 
          AND RACTL.CUSTOMER_TRX_LINE_ID IN (
                SELECT CONSINV_LINES.CUSTOMER_TRX_LINE_ID
                FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
                WHERE CONSINV_LINES.CONS_INV_ID                  =p_cbi_id
                )                
        UNION ALL
        SELECT --SUM(nvl(RACTL.EXTENDED_AMOUNT ,0))  --Commented for Defect # 10750
               NVL(SUM(RACTL.EXTENDED_AMOUNT),0)  --Added for Defect # 10750
        FROM   RA_CUSTOMER_TRX_LINES RACTL
        WHERE  1 = 1
          AND ractl.line_type = 'LINE'
          AND NVL(ractl.interface_line_context, '?') != 'ORDER ENTRY'
          AND ractl.description = 'Tiered Discount'  
          AND ractl.customer_trx_line_id IN (
            SELECT CONSINV_LINES.CUSTOMER_TRX_LINE_ID
            FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
            WHERE CONSINV_LINES.CONS_INV_ID                  =p_cbi_id
            )  
        ) DISCOUNT;

     */   -- Commented For the Defect 12925 -- Start

       ---Added for perf defect # 12925

/*        SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
        INTO   ln_promo_and_disc
        FROM   ar_cons_inv_trx_all ACIT
              ,ra_customer_trx_lines_all RACTL
              ,oe_price_adjustments  OEPA
        WHERE  1 = 1
          AND ACIT.cons_inv_id = p_cbi_id
          AND ACIT.customer_trx_id = RACTL.customer_trx_id
          AND RACTL.line_type = 'LINE'
          AND RACTL.interface_line_attribute11 =OEPA.price_adjustment_id;

      lc_return_amount :=ln_promo_and_disc;
      RETURN lc_return_amount;        
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     RETURN 0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_paydoc_ministmnt in formula DISCOUNTS');
     fnd_file.put_line(fnd_file.log , 'Error While: ' || lc_error_location||' '|| SQLERRM);     --Added for defect # 10750
     fnd_file.put_line(fnd_file.log , 'Debug:' || lc_debug);                                    --Added for defect # 10750

     RETURN 0;                
   END;
 ELSIF p_ministmnt_line_type ='TOTAL' THEN
   BEGIN
           lc_error_location := 'Getting TOTAL'; -- added for defect 10750
           lc_debug          := 'p_cbi_id : '|| to_char(p_cbi_id);       -- added for defect 10750

   -- Commented For the Defect 12925 -- Start
 /*  SELECT SUM(extamt) INTO ln_ext_amt_plus_delvy
   FROM (
    SELECT --SUM(nvl(RACTL.EXTENDED_AMOUNT ,0)) extamt  -- Commented for defect # 10750
           NVL(SUM(RACTL.EXTENDED_AMOUNT),0) extamt  -- Added for defect # 10750
    FROM   RA_CUSTOMER_TRX_LINES RACTL
          ,AR_CONS_INV_TRX_LINES CONSINV_LINES --Added for the defect 12925
    WHERE  1 = 1   
      AND RACTL.interface_line_context ='ORDER ENTRY'
      AND RACTL.LINE_TYPE = 'LINE'
      AND RACTL.DESCRIPTION != 'Tiered Discount'  
      AND RACTL.CUSTOMER_TRX_ID = CONSINV_LINES.CUSTOMER_TRX_ID       --Added for the defect 12925
      AND CONSINV_LINES.CONS_INV_ID =p_cbi_id                         --Added for the defect 12925
--      AND RACTL.CUSTOMER_TRX_LINE_ID NOT IN 
--      (
--         SELECT RACTL.CUSTOMER_TRX_LINE_ID
--         FROM   RA_CUSTOMER_TRX_LINES  RACTLI
--               ,OE_PRICE_ADJUSTMENTS OEPA
--         WHERE  1 = 1         
--         AND RACTL.INTERFACE_LINE_ATTRIBUTE11 = OEPA.PRICE_ADJUSTMENT_ID
--         AND RACTLI.CUSTOMER_TRX_LINE_ID = RACTL.CUSTOMER_TRX_LINE_ID
--      )    
/*      AND RACTL.CUSTOMER_TRX_ID IN (             --Commented for the defect 12925
            SELECT CONSINV_LINES.CUSTOMER_TRX_ID
            FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
            WHERE CONSINV_LINES.CONS_INV_ID                  =p_cbi_id
            )
    UNION ALL            
    SELECT --SUM(nvl(RACTL.EXTENDED_AMOUNT ,0)) extamt  -- Commneted for defect # 10750
           NVL(SUM(RACTL.EXTENDED_AMOUNT),0) extamt  -- Added for defect # 10750
    FROM   RA_CUSTOMER_TRX_LINES RACTL
          ,AR_CONS_INV_TRX_LINES CONSINV_LINES      --Added for the defect 12925
    WHERE  1 = 1   
      AND NVL(RACTL.interface_line_context ,'?') !='ORDER ENTRY'    
      AND RACTL.LINE_TYPE = 'LINE'
      AND RACTL.DESCRIPTION != 'Tiered Discount'
      AND RACTL.CUSTOMER_TRX_ID = CONSINV_LINES.CUSTOMER_TRX_ID       --Added for the defect 12925
      AND CONSINV_LINES.CONS_INV_ID =p_cbi_id
/*      AND RACTL.CUSTOMER_TRX_ID IN (                     Commented for the defect 12925
            SELECT CONSINV_LINES.CUSTOMER_TRX_ID
            FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
            WHERE CONSINV_LINES.CONS_INV_ID =p_cbi_id
            ) 
      AND (ractl.interface_line_attribute11 IS NULL OR ractl.interface_line_attribute11 =0)
    ); 


      lc_return_amount :=lc_return_amount + ln_ext_amt_plus_delvy;
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     lc_return_amount :=lc_return_amount+0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_paydoc_ministmnt in formula EXTAMT+DELVY');
     lc_return_amount :=lc_return_amount+0;
     fnd_file.put_line(fnd_file.log , 'Error While: ' || lc_error_location||' '|| SQLERRM);     --Added for defect # 10750
     fnd_file.put_line(fnd_file.log , 'Debug:' || lc_debug);                                    --Added for defect # 10750

   END;      
   BEGIN
    /*    
        SELECT SUM(RACTL.EXTENDED_AMOUNT)
        INTO   ln_tax_amount
        FROM   RA_CUSTOMER_TRX_LINES RACTL
        WHERE  1 = 1
          AND RACTL.LINE_TYPE = 'TAX'
          AND RACTL.INTERFACE_LINE_CONTEXT ='ORDER ENTRY'  --For release 1 we need invoices sourced from AOPS only           
          AND RACTL.CUSTOMER_TRX_ID IN (
                SELECT CONSINV_LINES.CUSTOMER_TRX_ID
                FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
                WHERE CONSINV_LINES.CONS_INV_ID            =p_cbi_id
                );
                   
       
           lc_error_location := 'Getting TAX -- TOTAL'; -- added for defect 10750
           lc_debug          := 'p_cbi_id : '|| to_char(p_cbi_id);       -- added for defect 10750

        SELECT --SUM (nvl(tax_original ,0)) --Commented for Defect # 10750
               NVL(SUM (tax_original),0) --Added for Defect # 10750
        INTO   ln_tax_amount
        FROM ar_cons_inv_trx
        WHERE cons_inv_id =p_cbi_id 
          AND transaction_type IN
                       (
                         'INVOICE'
                        ,'CREDIT_MEMO'
                        --,'ADJUSTMENT'                        
                       );                
      lc_return_amount :=lc_return_amount + ln_tax_amount;
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     lc_return_amount :=lc_return_amount+0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_paydoc_ministmnt in formula TAX');
     lc_return_amount :=lc_return_amount+0;
     fnd_file.put_line(fnd_file.log , 'Error While: ' || lc_error_location||' '|| SQLERRM);     --Added for defect # 10750
     fnd_file.put_line(fnd_file.log , 'Debug:' || lc_debug);                                    --Added for defect # 10750

   END;      
   BEGIN
           lc_error_location := 'Getting Promo and discount'; -- added for defect 10750
           lc_debug          := 'p_cbi_id : '|| to_char(p_cbi_id);       -- added for defect 10750

/*        SELECT --SUM(nvl(DISCOUNT.AMOUNT ,0))  --Commented for Defect # 10750
               NVL(SUM(DISCOUNT.AMOUNT),0)  --Added for Defect # 10750
        INTO   ln_promo_and_disc
        FROM (
        SELECT --SUM(RACTL.EXTENDED_AMOUNT) AMOUNT  --Commented for Defect # 10750
               NVL(SUM(RACTL.EXTENDED_AMOUNT),0) AMOUNT  --Added for Defect # 10750
        FROM   RA_CUSTOMER_TRX_LINES RACTL
              ,OE_PRICE_ADJUSTMENTS  OEPA
        WHERE  1 = 1        
          AND RACTL.LINE_TYPE = 'LINE' 
          AND RACTL.INTERFACE_LINE_CONTEXT ='ORDER ENTRY'  --For release 1 we need invoices sourced from AOPS only           
          AND RACTL.INTERFACE_LINE_ATTRIBUTE11 =to_char(OEPA.PRICE_ADJUSTMENT_ID) 
          AND RACTL.CUSTOMER_TRX_LINE_ID IN (
                SELECT CONSINV_LINES.CUSTOMER_TRX_LINE_ID
                FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
                WHERE CONSINV_LINES.CONS_INV_ID                  =p_cbi_id
                )                                 
        UNION ALL
        SELECT --SUM(nvl(RACTL.EXTENDED_AMOUNT ,0))  --Commented for Defect # 10750
               NVL(SUM(RACTL.EXTENDED_AMOUNT),0)  --Added for Defect # 10750
        FROM   RA_CUSTOMER_TRX_LINES RACTL
        WHERE  1 = 1
          AND ractl.line_type = 'LINE'
          AND NVL(ractl.interface_line_context, '?') != 'ORDER ENTRY'
          AND ractl.description = 'Tiered Discount'  
          AND ractl.customer_trx_line_id IN (
            SELECT CONSINV_LINES.CUSTOMER_TRX_LINE_ID
            FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
            WHERE CONSINV_LINES.CONS_INV_ID                  =p_cbi_id
            )                           
        ) DISCOUNT;
  */  -- Commented For the Defect 12925 -- End

   ---Added for perf defect # 12925
 /*        SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
        INTO   lc_return_amount
        FROM   ar_cons_inv_trx_all ACIT
              ,ra_customer_trx_lines RACTL
        WHERE  1 = 1
          AND ACIT.cons_inv_id = p_cbi_id
          AND ACIT.customer_trx_id = RACTL.customer_trx_id;

  lc_return_amount :=lc_return_amount + ln_promo_and_disc;
      RETURN lc_return_amount;        
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     lc_return_amount :=lc_return_amount+0;
      RETURN lc_return_amount;     
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_paydoc_ministmnt in formula DISCOUNTS');
     lc_return_amount :=lc_return_amount+0;
      RETURN lc_return_amount;     
   END; 
          /*
       BEGIN
        SELECT SUM(amount_original)
        INTO   ln_total_amount
        FROM   ar_cons_inv_trx        
        WHERE  cons_inv_id =p_cbi_id        
          AND  transaction_type IN ('INVOICE' ,'CREDIT_MEMO');
          lc_return_amount :=ln_total_amount; 
          RETURN lc_return_amount;                   
       EXCEPTION
        WHEN NO_DATA_FOUND THEN
         RETURN 0;
        WHEN OTHERS THEN
         fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_get_paydoc_ministmnt in formula TOTAL');
         RETURN 0;   
       END;
          */       
/* ELSE
      RETURN(0);
 END IF;*/

  -- changes for defect 13937 starts
   IF (p_ministmnt_line_type ='EXTAMT_PLUS_DELVY') THEN
      BEGIN
         lc_error_location := 'Getting Extended amount plus Delivery';
         lc_debug          := 'p_cbi_id : '|| to_char(p_cbi_id);

         SELECT NVL (SUM(ractl.extended_amount), 0)
         INTO   ln_ext_amt_plus_delvy
         FROM   ra_customer_trx_lines_all RACTL
               ,ar_cons_inv_trx_all       CONSINV_LINES
         WHERE 1 = 1
         AND   RACTL.line_type                  = 'LINE'
         AND   RACTL.INTERFACE_LINE_ATTRIBUTE11 = 0   -- avoids discounts
         AND   RACTL.customer_trx_id            = CONSINV_LINES.customer_trx_id
         AND   CONSINV_LINES.cons_inv_id        = p_cbi_id;

         RETURN ln_ext_amt_plus_delvy;
      EXCEPTION
         WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'Error at xx_ar_cbi_paydoc_ministmnt in formula EXTAMT+DELVY');
            fnd_file.put_line(fnd_file.log , 'Error While: ' || lc_error_location||' '|| SQLERRM);
            fnd_file.put_line(fnd_file.log , 'Debug:' || lc_debug);

            RETURN 0;
      END;
   ELSIF (p_ministmnt_line_type ='TAX') THEN
      BEGIN 
         lc_error_location := 'Getting TAX';
         lc_debug          := 'p_cbi_id : '|| to_char(p_cbi_id);

         SELECT NVL(SUM(tax_original),0)
         INTO   ln_tax_amount
         FROM   ar_cons_inv_trx_all
         WHERE  cons_inv_id = p_cbi_id 
         AND transaction_type IN ('INVOICE','CREDIT_MEMO');

         RETURN ln_tax_amount;

      EXCEPTION
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error at xx_ar_cbi_paydoc_ministmnt in formula TAX');
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error While: ' || lc_error_location||' '|| SQLERRM);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Debug:' || lc_debug);

            RETURN 0;
      END;
   ELSIF (p_ministmnt_line_type ='DISCOUNT') THEN
      BEGIN
         lc_error_location := 'Getting DISCOUNT';
         lc_debug          := 'p_cbi_id : '|| to_char(p_cbi_id);

         SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
         INTO   ln_promo_and_disc
         FROM   ar_cons_inv_trx_all ACIT
               ,ra_customer_trx_lines_all RACTL
			   ,xx_oe_price_adjustments_v OEPA  -- Commented and Changed by Punit CG on 18-APR-2018 for Defect NAIT-31695
               --,oe_price_adjustments      OEPA
         WHERE  1                                = 1
         AND    ACIT.cons_inv_id                 = p_cbi_id
         AND    ACIT.customer_trx_id             = RACTL.customer_trx_id
         AND    RACTL.line_type                  = 'LINE'
         AND    RACTL.interface_line_attribute11 = OEPA.price_adjustment_id;

          -- added for defect 1451 CR 626

           SELECT  NVL(SUM(OP.payment_amount),0)
           INTO    ln_gc_inv_amt
           FROM    xx_oe_payments_v OP -- Commented and Changed by Punit CG on 18-APR-2018 for Defect NAIT-31695
		           --apps.oe_payments OP
                  ,ra_customer_trx_all RCT
                  ,ar_cons_inv_trx_all ACIT
           WHERE   OP.header_id        = RCT.attribute14
           AND     RCT.customer_trx_id = ACIT.customer_trx_id
           AND     ACIT.cons_inv_id    = p_cbi_id
           AND     ACIT.transaction_type = 'INVOICE';


           SELECT  NVL(SUM(ORT.credit_amount),0) 
           INTO    ln_gc_cm_amt
           FROM    apps.xx_om_return_tenders_all ORT
                  ,ra_customer_trx_all RCT
                  ,ar_cons_inv_trx_all ACIT
           WHERE   ORT.header_id       = RCT.attribute14
           AND     RCT.customer_trx_id = ACIT.customer_trx_id
           AND     ACIT.cons_inv_id    = p_cbi_id
           AND     ACIT.transaction_type = 'CREDIT_MEMO';
         
         
           ln_promo_and_disc := ln_promo_and_disc - ln_gc_inv_amt + ln_gc_cm_amt;

           -- end of changes for defect 1451 CR 626

         RETURN ln_promo_and_disc;
      EXCEPTION
         WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'Error at xx_ar_cbi_paydoc_ministmnt in formula DISCOUNTS');
            fnd_file.put_line(fnd_file.log , 'Error While: ' || lc_error_location||' '|| SQLERRM);
            fnd_file.put_line(fnd_file.log , 'Debug:' || lc_debug);

            RETURN 0;
      END;

   ELSIF (p_ministmnt_line_type ='TOTAL') THEN

      BEGIN
         lc_error_location := 'Getting TOTAL';
         lc_debug          := 'p_cbi_id : '|| to_char(p_cbi_id);

         SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
         INTO   ln_return_amount
         FROM   ar_cons_inv_trx_all   ACIT
               ,ra_customer_trx_lines_all RACTL
         WHERE  1                    = 1
         AND    ACIT.cons_inv_id     = p_cbi_id
         AND    ACIT.customer_trx_id = RACTL.customer_trx_id;

          -- added for defect 1451 CR 626

           SELECT  NVL(SUM(OP.payment_amount),0)
           INTO    ln_gc_inv_amt
           FROM    xx_oe_payments_v OP -- Commented and Changed by Punit CG on 18-APR-2018 for Defect NAIT-31695
		           --apps.oe_payments OP
                  ,ra_customer_trx_all RCT
                  ,ar_cons_inv_trx_all ACIT
           WHERE   OP.header_id        = RCT.attribute14
           AND     RCT.customer_trx_id = ACIT.customer_trx_id
           AND     ACIT.cons_inv_id    = p_cbi_id
           AND     ACIT.transaction_type = 'INVOICE';


           SELECT  NVL(SUM(ORT.credit_amount),0) 
           INTO    ln_gc_cm_amt
           FROM    apps.xx_om_return_tenders_all ORT
                  ,ra_customer_trx_all RCT
                  ,ar_cons_inv_trx_all ACIT
           WHERE   ORT.header_id       = RCT.attribute14
           AND     RCT.customer_trx_id = ACIT.customer_trx_id
           AND     ACIT.cons_inv_id    = p_cbi_id
           AND     ACIT.transaction_type = 'CREDIT_MEMO';

           ln_return_amount := ln_return_amount - ln_gc_inv_amt + ln_gc_cm_amt;

           -- end of changes for defect 1451 CR 626

         RETURN ln_return_amount;

      EXCEPTION
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error at xx_ar_cbi_paydoc_ministmnt in formula TOTAL');
            RETURN 0;
      END;

   ELSE
      RETURN(0);
   END IF;
 -- changes for defect 13937 ends
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'NODATA at xx_ar_cbi_paydoc_ministmnt...'||SQLERRM); 
      RETURN(0);
   WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error at xx_ar_cbi_paydoc_ministmnt...'||SQLERRM); 
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error While: ' || lc_error_location||' '|| SQLERRM);     --Added for defect # 10750
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Debug:' || lc_debug);                                    --Added for defect # 10750

      RETURN(0);
END xx_ar_cbi_paydoc_ministmnt; 
/
SHOW ERR