SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Function XX_AR_CBI_INFOCOPY_ORDER_STMNT

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |  Providge Consulting                                                                       |
-- +============================================================================================+
-- |  Name:  xx_ar_cbi_infocopy_order_stmnt                                                     |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         03-Jun-2008  Balaguru Seshadri Initial version                                 |
-- | 1.1         31-MAR-2009  Ramya Priya       Modified for the defect 13937                   |
-- | 1.2         02-SEP-2009  Vinaykumar S      Modified for R1.1 Defect # 1451 (CR 626)        |
-- | 1.3         18-APR-2018  Punit Gupta CG    Retrofit OD AR Reprint Summary/Consolidated     |
-- |                                            Bills - Defect NAIT-31695                       |
-- +============================================================================================+
CREATE OR REPLACE FUNCTION xx_ar_cbi_infocopy_order_stmnt(
                                                           p_trx_id              IN NUMBER
                                                          ,p_ministmnt_line_type IN VARCHAR2 --EXTAMT_PLUS_DELVY, DISCOUNT ,DELIVERY ,TAX and TOTAL
                                                          ) RETURN NUMBER AS

 ln_ext_amt_plus_delvy       NUMBER := 0;
 ln_promo_and_disc           NUMBER := 0;
 ln_tax_amount               NUMBER := 0;
 ln_total_amount             NUMBER := 0;
 ln_delvy_chrgs              NUMBER := 0;
 ln_gc_amt                   NUMBER;        -- Added for R1.1 Defect # 1451 (CR 626)
 lc_trx_type                 RA_CUST_TRX_TYPES_ALL.TYPE%TYPE;   -- Added for R1.1 Defect # 1451 (CR 626)

BEGIN

----------------------------------------
-----------------------------------------------------------------------
  /*  Commented for the Defect 13937 
BEGIN   
 IF p_ministmnt_line_type ='EXTAMT_PLUS_DELVY' THEN
   BEGIN
   SELECT SUM(extamt) INTO ln_ext_amt_plus_delvy
   FROM (
    SELECT SUM(NVL(RACTL.EXTENDED_AMOUNT ,0)) extamt
    FROM   RA_CUSTOMER_TRX_LINES RACTL
    WHERE  1 = 1  
      AND RACTL.CUSTOMER_TRX_ID =p_trx_id
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
    UNION ALL            
    SELECT SUM(NVL(RACTL.EXTENDED_AMOUNT ,0)) extamt
    FROM   RA_CUSTOMER_TRX_LINES RACTL
    WHERE  1 = 1   
      AND (ractl.interface_line_context != 'ORDER ENTRY' OR ractl.interface_line_context IS NULL)
--                       AND NVL (ractl.interface_line_context, '?') !=
--                                                                 'ORDER ENTRY'    
      AND RACTL.LINE_TYPE = 'LINE'
      AND RACTL.DESCRIPTION != 'Tiered Discount'   
      AND (RACTL.INTERFACE_LINE_ATTRIBUTE11 IS NULL OR RACTL.INTERFACE_LINE_ATTRIBUTE11 = 0)      
      AND RACTL.CUSTOMER_TRX_ID =p_trx_id
    );   
      lc_return_amount :=NVL(ln_ext_amt_plus_delvy ,0); 
      RETURN lc_return_amount;            
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     RETURN 0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error in xx_ar_cbi_infocopy_order_stmnt in formula EXTAMT+DELVY');
     RETURN 0;   
   END;               
 ELSIF p_ministmnt_line_type ='TAX' THEN
   BEGIN
        SELECT SUM(NVL(RACTL.EXTENDED_AMOUNT ,0))
        INTO   ln_tax_amount
        FROM   RA_CUSTOMER_TRX_LINES RACTL
        WHERE  1 = 1
          AND RACTL.customer_trx_id =p_trx_id        
          AND RACTL.LINE_TYPE = 'TAX';
      lc_return_amount :=NVL(ln_tax_amount ,0); 
      RETURN lc_return_amount;
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     RETURN 0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error in xx_ar_cbi_infocopy_order_stmnt in formula TAX');
     RETURN 0;   
   END;       
 ELSIF p_ministmnt_line_type ='DISCOUNT' THEN
   BEGIN
        SELECT SUM(DISCOUNT.AMOUNT)
        INTO   ln_promo_and_disc
        FROM (
        SELECT SUM(NVL(RACTL.EXTENDED_AMOUNT ,0)) AMOUNT
        FROM   RA_CUSTOMER_TRX_LINES RACTL
		       ,OE_PRICE_ADJUSTMENTS  OEPA
        WHERE  1 = 1
          AND RACTL.CUSTOMER_TRX_ID =p_trx_id
          AND RACTL.LINE_TYPE = 'LINE' 
          AND RACTL.INTERFACE_LINE_CONTEXT ='ORDER ENTRY'  --For release 1 we need invoices sourced from AOPS only           
          AND to_number(RACTL.INTERFACE_LINE_ATTRIBUTE11)   =OEPA.PRICE_ADJUSTMENT_ID                                                 
        UNION ALL
        SELECT SUM(NVL(RACTL.EXTENDED_AMOUNT ,0))
        FROM   RA_CUSTOMER_TRX_LINES RACTL
        WHERE  1 = 1
          AND RACTL.CUSTOMER_TRX_ID =p_trx_id        
          AND ractl.line_type = 'LINE'
          AND (ractl.interface_line_context != 'ORDER ENTRY' OR ractl.interface_line_context IS NULL)
--                       AND NVL (ractl.interface_line_context, '?') !=
--                                                                 'ORDER ENTRY'
          AND ractl.description = 'Tiered Discount'                                          
        ) DISCOUNT;
      lc_return_amount :=NVL(ln_promo_and_disc ,0);
      RETURN lc_return_amount;        
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     RETURN 0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error in xx_ar_cbi_infocopy_order_stmnt in formula DISCOUNTS');
     RETURN 0;                
   END;
 ELSIF p_ministmnt_line_type ='TOTAL' THEN
   BEGIN
    lc_return_amount :=0;
   SELECT SUM(extamt) INTO ln_ext_amt_plus_delvy
   FROM (
    SELECT SUM(NVL(RACTL.EXTENDED_AMOUNT ,0)) extamt
    FROM   RA_CUSTOMER_TRX_LINES RACTL
    WHERE  1 = 1  
      AND RACTL.CUSTOMER_TRX_ID =p_trx_id
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
    UNION ALL            
    SELECT SUM(NVL(RACTL.EXTENDED_AMOUNT ,0)) extamt
    FROM   RA_CUSTOMER_TRX_LINES RACTL
    WHERE  1 = 1   
      AND (ractl.interface_line_context != 'ORDER ENTRY' OR ractl.interface_line_context IS NULL)
--                       AND NVL (ractl.interface_line_context, '?') !=
--                                                                 'ORDER ENTRY'    
      AND RACTL.LINE_TYPE = 'LINE'
      AND RACTL.DESCRIPTION != 'Tiered Discount'   
      AND (RACTL.INTERFACE_LINE_ATTRIBUTE11 IS NULL OR RACTL.INTERFACE_LINE_ATTRIBUTE11 =0)      
      AND RACTL.CUSTOMER_TRX_ID =p_trx_id
    ); 
      lc_return_amount :=lc_return_amount + NVL(ln_ext_amt_plus_delvy ,0);
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     lc_return_amount :=lc_return_amount+0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error in xx_ar_cbi_infocopy_order_stmnt in formula EXTAMT+DELVY');
     lc_return_amount :=lc_return_amount+0;
   END;      
   BEGIN
        SELECT SUM(NVL(RACTL.EXTENDED_AMOUNT ,0))
        INTO   ln_tax_amount
        FROM   RA_CUSTOMER_TRX_LINES RACTL
        WHERE  1 = 1
          AND RACTL.customer_trx_id =p_trx_id        
          AND RACTL.LINE_TYPE = 'TAX';
      lc_return_amount :=lc_return_amount + NVL(ln_tax_amount ,0);
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     lc_return_amount :=lc_return_amount+0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error in xx_ar_cbi_infocopy_order_stmnt in formula TAX');
     lc_return_amount :=lc_return_amount+0;
   END;      
   BEGIN
        SELECT SUM(DISCOUNT.AMOUNT)
        INTO   ln_promo_and_disc
        FROM (
        SELECT SUM(NVL(RACTL.EXTENDED_AMOUNT ,0)) AMOUNT
        FROM   RA_CUSTOMER_TRX_LINES RACTL
		       ,OE_PRICE_ADJUSTMENTS  OEPA
        WHERE  1 = 1
          AND RACTL.CUSTOMER_TRX_ID =p_trx_id
          AND RACTL.LINE_TYPE = 'LINE' 
          AND RACTL.INTERFACE_LINE_CONTEXT ='ORDER ENTRY'  --For release 1 we need invoices sourced from AOPS only           
          AND to_number(RACTL.INTERFACE_LINE_ATTRIBUTE11)   =OEPA.PRICE_ADJUSTMENT_ID                                                 
        UNION ALL
        SELECT SUM(NVL(RACTL.EXTENDED_AMOUNT ,0))
        FROM   RA_CUSTOMER_TRX_LINES RACTL
        WHERE  1 = 1
          AND RACTL.CUSTOMER_TRX_ID =p_trx_id        
          AND ractl.line_type = 'LINE'
          AND (ractl.interface_line_context != 'ORDER ENTRY' OR ractl.interface_line_context IS NULL)
--                       AND NVL (ractl.interface_line_context, '?') !=
--                                                                 'ORDER ENTRY'
          AND ractl.description = 'Tiered Discount'                                         
        ) DISCOUNT;
      lc_return_amount :=lc_return_amount + NVL(ln_promo_and_disc ,0);
      RETURN lc_return_amount;        
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     lc_return_amount :=lc_return_amount+0;
      RETURN lc_return_amount;     
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error in xx_ar_cbi_infocopy_order_stmnt in formula DISCOUNTS');
     lc_return_amount :=lc_return_amount+0;
      RETURN lc_return_amount;     
   END;    
 ELSIF p_ministmnt_line_type ='DELIVERY' THEN
   SELECT NVL(SUM(nvl(RACTL.EXTENDED_AMOUNT ,0)) ,0)
   INTO   ln_delvy_chrgs
   FROM   RA_CUSTOMER_TRX_LINES RACTL
        ,oe_order_lines oeol       
        ,(
             SELECT DISTINCT TO_NUMBER(attribute6) odf_item_id
             FROM   fnd_lookup_values 
             WHERE  lookup_type='OD_FEES_ITEMS' 
               AND  attribute7 ='DELIVERY' 
               AND  LANGUAGE   =USERENV('LANG')            
         ) OD_FEES_ITEM   
        ,(
          SELECT mtlsi.inventory_item_id inv_item_id ,mtlsi.segment1 item_number
          FROM mtl_system_items mtlsi
          WHERE EXISTS
           ( 
             SELECT odef.organization_id   
             FROM   org_organization_definitions odef
             WHERE  odef.organization_id   =mtlsi.organization_id
               AND  odef.organization_name ='OD_ITEM_MASTER'
           )  
         ) MSIB    
     WHERE  1 = 1
       AND RACTL.customer_trx_id =p_trx_id              
       AND RACTL.LINE_TYPE = 'LINE'
       AND RACTL.DESCRIPTION != 'Tiered Discount'  
       AND RACTL.INTERFACE_LINE_CONTEXT ='ORDER ENTRY'       
       AND to_number(RACTL.interface_line_attribute6)  =OEOL.line_id
       AND RACTL.inventory_item_id          =OD_FEES_ITEM.odf_item_id      
       AND MSIB.inv_item_id                 =RACTL.inventory_item_id;     
--       AND RACTL.CUSTOMER_TRX_LINE_ID NOT IN 
--       (
--          SELECT RACTL.CUSTOMER_TRX_LINE_ID
--          FROM   RA_CUSTOMER_TRX_LINES  RACTLI
--                ,OE_PRICE_ADJUSTMENTS OEPA
--          WHERE  1 = 1
--          AND RACTL.INTERFACE_LINE_ATTRIBUTE11 = OEPA.PRICE_ADJUSTMENT_ID
--          AND RACTLI.CUSTOMER_TRX_LINE_ID = RACTL.CUSTOMER_TRX_LINE_ID
--       );
    RETURN ln_delvy_chrgs;
 ELSE
      RETURN(0);
 END IF;
EXCEPTION
 WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log ,'Error in function xx_ar_cbi_infocopy_ministmnt');
  fnd_file.put_line(fnd_file.log ,'Transaction ID :'||p_trx_id);  
  fnd_file.put_line(fnd_file.log ,'Type           :'||p_ministmnt_line_type  );
      RETURN(0);     

    Commented for the Defect 13937 

END xx_ar_cbi_infocopy_order_stmnt;
/       Commented for the Defect 13937  */

----------------------------------------

--=================================================================--
       --Start of changes for the defect 13937       
--=================================================================--

   IF (p_ministmnt_line_type ='EXTAMT_PLUS_DELVY') THEN

      BEGIN

         SELECT NVL(SUM(RACTL.extended_amount),0)
         INTO   ln_ext_amt_plus_delvy
         FROM   ra_customer_trx_lines RACTL
         WHERE  RACTL.customer_trx_id            = p_trx_id
         AND    RACTL.line_type                  = 'LINE'
         AND    RACTL.interface_line_attribute11 = '0'; -- Delivery Line/Line with out Discounts

         RETURN ln_ext_amt_plus_delvy;

      EXCEPTION
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error in xx_ar_cbi_infocopy_order_stmnt in formula EXTAMT+DELVY '||' Error : '||SQLERRM);
            RETURN(0);
      END;

   ELSIF (p_ministmnt_line_type ='TAX') THEN

      BEGIN
         SELECT NVL(SUM(RACTL.extended_amount),0)
         INTO   ln_tax_amount
         FROM   ra_customer_trx_lines RACTL
         WHERE  RACTL.customer_trx_id = p_trx_id
         AND    RACTL.line_type       = 'TAX';

         RETURN ln_tax_amount;

      EXCEPTION
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error in xx_ar_cbi_infocopy_order_stmnt in formula TAX '||' Error : '||SQLERRM);
            RETURN(0);
      END;

   ELSIF (p_ministmnt_line_type ='DISCOUNT') THEN

      BEGIN
         SELECT NVL(SUM(RACTL.extended_amount),0)
         INTO   ln_promo_and_disc
         FROM   ra_customer_trx_lines_all RACTL
		        ,xx_oe_price_adjustments_v OEPA  -- Commented and Changed by Punit CG on 18-APR-2018 for Defect NAIT-31695
               --,oe_price_adjustments  OEPA
         WHERE  RACTL.customer_trx_id                       = p_trx_id
         AND    RACTL.line_type                             = 'LINE'
         AND    TO_NUMBER(RACTL.interface_line_attribute11) = OEPA.price_adjustment_id;

       -- Added for R1.1 Defect # 1451 (CR 626)

        SELECT  RCTT.type
        INTO    lc_trx_type
        FROM    ra_customer_trx_all RCT
               ,ra_cust_trx_types_all  RCTT
        WHERE    RCT.cust_trx_type_id            = RCTT.cust_trx_type_id
        AND      RCT.customer_trx_id             = p_trx_id;
     

        IF (lc_trx_type = 'INV') THEN
           SELECT  NVL(SUM(OP.payment_amount),0)
           INTO    ln_gc_amt
           FROM    --apps.oe_payments OP
		          xx_oe_payments_v OP -- Commented and Changed by Punit CG on 18-APR-2018 for Defect NAIT-31695
                  ,ra_customer_trx_all RCT
           WHERE   OP.header_id        = RCT.attribute14
           AND     RCT.customer_trx_id = p_trx_id;

           ln_promo_and_disc := ln_promo_and_disc - ln_gc_amt;

        ELSIF (lc_trx_type = 'CM') THEN
           SELECT  NVL(SUM(ORT.credit_amount),0) 
           INTO    ln_gc_amt
           FROM    apps.xx_om_return_tenders_all ORT
                  ,ra_customer_trx_all RCT
           WHERE   ORT.header_id       = RCT.attribute14
           AND     RCT.customer_trx_id = p_trx_id;

           ln_promo_and_disc := ln_promo_and_disc + ln_gc_amt;

        END IF;

        -- End of updates for R1.1 Defect # 1451(CR 626)

      RETURN ln_promo_and_disc;

   EXCEPTION
    WHEN OTHERS THEN
     FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error in xx_ar_cbi_infocopy_order_stmnt in formula DISCOUNTS '||' Error : '||SQLERRM);
     RETURN(0);
   END;

   ELSIF (p_ministmnt_line_type ='TOTAL') THEN

      BEGIN
         SELECT NVL(SUM(RACTL.extended_amount),0)
         INTO   ln_total_amount
         FROM   ra_customer_trx_lines_all RACTL
         WHERE  RACTL.customer_trx_id = p_trx_id;

       -- Added for R1.1 Defect # 1451 (CR 626)

        SELECT  RCTT.type
        INTO    lc_trx_type
        FROM    ra_customer_trx_all RCT
               ,ra_cust_trx_types_all  RCTT
        WHERE    RCT.cust_trx_type_id            = RCTT.cust_trx_type_id
        AND      RCT.customer_trx_id             = p_trx_id;
     

        IF (lc_trx_type = 'INV') THEN
           SELECT  NVL(SUM(OP.payment_amount),0)
           INTO    ln_gc_amt
           FROM    --apps.oe_payments OP
		           xx_oe_payments_v OP -- Commented and Changed by Punit CG on 18-APR-2018 for Defect NAIT-31695
                  ,ra_customer_trx_all RCT
           WHERE   OP.header_id        = RCT.attribute14
           AND     RCT.customer_trx_id = p_trx_id;

           ln_total_amount := ln_total_amount - ln_gc_amt;

        ELSIF (lc_trx_type = 'CM') THEN
           SELECT  NVL(SUM(ORT.credit_amount),0) 
           INTO    ln_gc_amt
           FROM    apps.xx_om_return_tenders_all ORT
                  ,ra_customer_trx_all RCT
           WHERE   ORT.header_id       = RCT.attribute14
           AND     RCT.customer_trx_id = p_trx_id;

           ln_total_amount := ln_total_amount + ln_gc_amt;

        END IF;

        -- End of updates for R1.1 Defect # 1451(CR 626)

         RETURN ln_total_amount;

      EXCEPTION
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error in xx_ar_cbi_infocopy_order_stmnt in formula TOTAL '||' Error : '||SQLERRM);
            RETURN (0);
      END;

   ELSIF (p_ministmnt_line_type ='DELIVERY') THEN

      BEGIN

         SELECT NVL(SUM(RCTL.extended_amount),0)
         INTO   ln_delvy_chrgs
         FROM   ra_customer_trx_lines_all   RCTL
         WHERE  RCTL.customer_trx_id     = p_trx_id
         AND EXISTS ( SELECT 1
                      FROM   fnd_lookup_values
                      WHERE  lookup_type = 'OD_FEES_ITEMS'
                      AND    attribute7  = 'DELIVERY'
                      AND    TO_NUMBER(attribute6)  = RCTL.inventory_item_id
                      AND    LANGUAGE               = USERENV ('LANG')
                     );

         RETURN ln_delvy_chrgs;

      EXCEPTION
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error in xx_ar_cbi_infocopy_order_stmnt in formula DELIVERY '||' Error : '||SQLERRM);
            RETURN (0);
      END;

   ELSE -- Others

      RETURN(0);

    END IF;

EXCEPTION
   WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG ,'Error in function xx_ar_cbi_infocopy_ministmnt '||' Error : '||SQLERRM);
      FND_FILE.PUT_LINE(FND_FILE.LOG ,'Transaction ID :'||p_trx_id);  
      FND_FILE.PUT_LINE(FND_FILE.LOG ,'Type           :'||p_ministmnt_line_type  );
       RETURN(0);

END XX_AR_CBI_INFOCOPY_ORDER_STMNT;
/

SHOW ERRORS