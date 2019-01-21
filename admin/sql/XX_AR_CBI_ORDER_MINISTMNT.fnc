SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Function XX_AR_CBI_ORDER_MINISTMNT

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE
-- +====================================================================================+
-- |                  Office Depot - Project Simplify                                   |
-- |                       WIPRO Technologies                                           |
-- +====================================================================================+
-- | Name :      AR Invoice Frequency synchronization                                   |
-- | Description : To pupulate the invoices according to the customer                   |
-- |                documents                                                           |
-- |                                                                                    |
-- |                                                                                    |
-- |Change Record:                                                                      |
-- |===============                                                                     |
-- |Version   Date          Author              Remarks                                 |
-- |=======   ==========   =============        ========================================|
-- |1.0                                         Initial Version                         |
-- |1.1       04-Feb-2009  Sambasiva Reddy D    Modified for the Defect # 10750         |
-- |1.2       06-Feb-2009  Shobana S            Added the Log Messages. Defect 10750    |
-- |1.3       31-MAR-2009  Ramya Priya          Modified for the Defect# 13937          |
-- |1.4       02-SEP-2009  Ranjith Prabu        Modified for defect 1451 CR 626         |
-- |1.5       18-APR-2018  Punit Gupta CG       Retrofit OD AR Reprint Summary/         |
-- |                                            Consolidated Bills - Defect NAIT-31695  |
-- +====================================================================================+

CREATE OR REPLACE FUNCTION  XX_AR_CBI_ORDER_MINISTMNT (
                                                       p_cbi_id IN           NUMBER
                                                      ,p_trx_id IN           NUMBER
                                                      ,p_ministmnt_line_type VARCHAR2 --EXTAMT_PLUS_DELVY, DISCOUNT ,DELIVERY ,TAX and TOTAL...               
                                                      ) RETURN NUMBER AS
 ln_ext_amt_plus_delvy NUMBER :=0;             
 ln_promo_and_disc     NUMBER :=0;
 ln_tax_amount         NUMBER :=0;
 ln_total_amount       NUMBER :=0;
 --lc_return_amount      NUMBER :=0;  Commented for the defect# 13937
 ln_delvy_chrgs        NUMBER :=0;
 lc_error_location     VARCHAR2(4000); -- Addef for the defect 10750
 lc_error_debug        VARCHAR2(4000); -- Addef for the defect 10750
 ln_gc_amt             NUMBER :=0;     -- Added for defect 1451 CR 626
 lc_trx_type           RA_CUST_TRX_TYPES_ALL.TYPE%TYPE;     -- Added for defect 1451 CR 626

 --SO_ORGANIZATION_ID NUMBER;  --Added for Defect 10750  --Commented as a part of the defect# 13937
BEGIN  
--=================================================================--
-- below if block commented
-- for code cleanup as part of defect# 13937, since there were lots of commented code.
--=================================================================--
/* IF p_ministmnt_line_type ='EXTAMT_PLUS_DELVY' THEN

   BEGIN
    lc_error_location := ' P_MINISTMNT_LINE_TYPE - EXTAMT_PLUS_DELVY' ;
    lc_error_debug    := ' Trx_id : ' ||p_trx_id || 'Cbi_Id : ' || p_cbi_id ;

/*    SELECT --SUM(nvl(RACTL.EXTENDED_AMOUNT ,0))  --Commented for Defect # 10750
           NVL(SUM(RACTL.EXTENDED_AMOUNT),0)  --Added for Defect # 10750
    INTO   ln_ext_amt_plus_delvy
    FROM   RA_CUSTOMER_TRX_LINES RACTL
    WHERE  1 = 1
      AND RACTL.customer_trx_id =p_trx_id        
      --AND RACTL.INTERFACE_LINE_CONTEXT ='ORDER ENTRY'  --For release 1 we need invoices sourced from AOPS only      
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
      AND RACTL.CUSTOMER_TRX_ID IN (
            SELECT CONSINV_LINES.CUSTOMER_TRX_ID
            FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
            WHERE CONSINV_LINES.CONS_INV_ID                  = p_cbi_id
            );
  */
  
  --Added for perf Defect 10750
 /* SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
    INTO   ln_ext_amt_plus_delvy
    FROM    ar_cons_inv_trx_all arct
           ,RA_CUSTOMER_TRX_LINES RACTL
    WHERE  1 = 1
      AND arct.cons_inv_id=p_cbi_id
      and arct.customer_trx_id=ractl.customer_trx_id
      AND RACTL.customer_trx_id =p_trx_id        
      AND RACTL.LINE_TYPE = 'LINE'
      AND RACTL.DESCRIPTION != 'Tiered Discount';  

  lc_return_amount :=NVL(ln_ext_amt_plus_delvy ,0); 
      RETURN lc_return_amount;            
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     RETURN 0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_order_ministmnt in formula EXTAMT+DELVY');
     fnd_file.put_line(fnd_file.log,  lc_error_location || lc_error_debug ||' Error Message : ' || SQLERRM ); -- Addef for the defect 10750
     RETURN 0;   
   END;               
 ELSIF p_ministmnt_line_type ='TAX' THEN
   BEGIN

       lc_error_location := ' P_MINISTMNT_LINE_TYPE - TAX' ;
       lc_error_debug    := ' Trx_id : ' ||p_trx_id || 'Cbi_Id : ' || p_cbi_id ;

      /*  SELECT --SUM(nvl(RACTL.EXTENDED_AMOUNT ,0)) --Commneted for Defect # 10750
              NVL(SUM(RACTL.EXTENDED_AMOUNT),0) -- Added for Defect # 10750
        INTO   ln_tax_amount
        FROM   RA_CUSTOMER_TRX_LINES RACTL
        WHERE  1 = 1
          AND RACTL.customer_trx_id =p_trx_id        
          AND RACTL.LINE_TYPE = 'TAX'
          --AND RACTL.INTERFACE_LINE_CONTEXT ='ORDER ENTRY'  --For release 1 we need invoices sourced from AOPS only          
          AND RACTL.CUSTOMER_TRX_ID IN (
                SELECT CONSINV_LINES.CUSTOMER_TRX_ID
                FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
                WHERE CONSINV_LINES.CONS_INV_ID            =p_cbi_id
                );
      */
      --Added for perf defect # 10750
     /* SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
      INTO   ln_tax_amount
        FROM   ar_cons_inv_trx_all arct
              ,RA_CUSTOMER_TRX_LINES RACTL
        WHERE  1 = 1
          AND arct.cons_inv_id=p_cbi_id
          and arct.customer_trx_id=ractl.customer_trx_id
          AND RACTL.customer_trx_id =p_trx_id        
          AND RACTL.LINE_TYPE = 'TAX';
          
          lc_return_amount :=NVL(ln_tax_amount ,0); 
      RETURN lc_return_amount;
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     RETURN 0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_order_ministmnt in formula TAX');
     fnd_file.put_line(fnd_file.log,  lc_error_location || lc_error_debug ||' Error Message : ' || SQLERRM ); -- Addef for the defect 10750
     RETURN 0;   
   END;       
 ELSIF p_ministmnt_line_type ='DISCOUNT' THEN
   BEGIN

       lc_error_location := ' P_MINISTMNT_LINE_TYPE - DISCOUNT' ;
       lc_error_debug    := ' Trx_id : ' ||p_trx_id || 'Cbi_Id : ' || p_cbi_id ;

/*        SELECT --SUM(DISCOUNT.AMOUNT)  --Commented for Defect # 10750
                NVL(SUM(DISCOUNT.AMOUNT),0)  --Added for Defect # 10750
        INTO   ln_promo_and_disc
        FROM (
        SELECT SUM(nvl(RACTL.EXTENDED_AMOUNT ,0)) AMOUNT
        FROM   RA_CUSTOMER_TRX_LINES RACTL
              ,OE_PRICE_ADJUSTMENTS  OEPA
        WHERE  1 = 1
          AND RACTL.customer_trx_id =p_trx_id             
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
          AND RACTL.customer_trx_id =p_trx_id
          AND ractl.line_type = 'LINE'
          AND NVL(ractl.interface_line_context, '?') != 'ORDER ENTRY'
          AND ractl.description = 'Tiered Discount'  
          AND ractl.customer_trx_line_id IN (
            SELECT CONSINV_LINES.CUSTOMER_TRX_LINE_ID
            FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
            WHERE CONSINV_LINES.CONS_INV_ID                  =p_cbi_id
            )          
        ) DISCOUNT;
  */

    -- Added for Defect # 10750 perf
     /*   SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
        INTO   ln_promo_and_disc
        FROM   ar_cons_inv_trx_lines_all acit
              ,RA_CUSTOMER_TRX_LINES RACTL
              ,OE_PRICE_ADJUSTMENTS  OEPA
        WHERE  1 = 1
          AND acit.cons_inv_id = p_cbi_id
          AND acit.customer_trx_line_id = ractl.customer_trx_line_id
          AND RACTL.customer_trx_id =p_trx_id
          AND RACTL.LINE_TYPE = 'LINE' 
          AND RACTL.INTERFACE_LINE_ATTRIBUTE11 =OEPA.PRICE_ADJUSTMENT_ID;

  lc_return_amount :=NVL(ln_promo_and_disc ,0);
      RETURN lc_return_amount;        
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     RETURN 0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_order_ministmnt in formula DISCOUNTS');
     fnd_file.put_line(fnd_file.log,  lc_error_location || lc_error_debug ||' Error Message : ' || SQLERRM ); -- Addef for the defect 10750
     RETURN 0;                
   END;

 ELSIF p_ministmnt_line_type ='TOTAL' THEN

   BEGIN
    lc_return_amount :=0;

    lc_error_location := ' P_MINISTMNT_LINE_TYPE - TOTAL' ;
    lc_error_debug    := ' Trx_id : ' ||p_trx_id || 'Cbi_Id : ' || p_cbi_id ;

    /*SELECT --SUM(nvl(RACTL.EXTENDED_AMOUNT ,0))  --Commented for defect # 10750
           NVL(SUM(RACTL.EXTENDED_AMOUNT),0)  --Added for defect # 10750
    INTO   ln_ext_amt_plus_delvy
    FROM   RA_CUSTOMER_TRX_LINES RACTL
    WHERE  1 = 1
      AND RACTL.customer_trx_id =p_trx_id        
      AND RACTL.LINE_TYPE = 'LINE'
     -- AND RACTL.INTERFACE_LINE_CONTEXT ='ORDER ENTRY'  --For release 1 we need invoices sourced from AOPS only       
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
      AND RACTL.CUSTOMER_TRX_ID IN (
            SELECT CONSINV_LINES.CUSTOMER_TRX_ID
            FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
            WHERE CONSINV_LINES.CONS_INV_ID                  = p_cbi_id
            );
    */
    --Added for Defect # 10750 perf
   /* SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
    INTO   ln_ext_amt_plus_delvy
    FROM    ar_cons_inv_trx_all arct
           ,RA_CUSTOMER_TRX_LINES RACTL
    WHERE  1 = 1
      AND arct.cons_inv_id=p_cbi_id
      and arct.customer_trx_id=ractl.customer_trx_id
      AND RACTL.customer_trx_id =p_trx_id        
      AND RACTL.LINE_TYPE = 'LINE'
      AND RACTL.DESCRIPTION != 'Tiered Discount';  


      lc_return_amount :=lc_return_amount + NVL(ln_ext_amt_plus_delvy ,0);
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     lc_return_amount :=lc_return_amount+0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_order_ministmnt in formula TOTAL');
     fnd_file.put_line(fnd_file.log,  lc_error_location || lc_error_debug ||' Error Message : ' || SQLERRM ); -- Addef for the defect 10750
     lc_return_amount :=lc_return_amount+0;
   END;      

   BEGIN

        lc_error_location := ' P_MINISTMNT_LINE_TYPE - TOTAL - TAX' ;
        lc_error_debug    := ' Trx_id : ' ||p_trx_id || 'Cbi_Id : ' || p_cbi_id ;

    /*    SELECT --SUM(nvl(RACTL.EXTENDED_AMOUNT ,0))  --Commented for Defect # 10750
              NVL(SUM(RACTL.EXTENDED_AMOUNT),0)  --Added for Defect # 10750
        INTO   ln_tax_amount
        FROM   RA_CUSTOMER_TRX_LINES RACTL
        WHERE  1 = 1
          AND RACTL.customer_trx_id =p_trx_id             
          AND RACTL.LINE_TYPE = 'TAX'
          --AND RACTL.INTERFACE_LINE_CONTEXT ='ORDER ENTRY'  --For release 1 we need invoices sourced from AOPS only           
          AND RACTL.CUSTOMER_TRX_ID IN (
                SELECT CONSINV_LINES.CUSTOMER_TRX_ID
                FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
                WHERE CONSINV_LINES.CONS_INV_ID            =p_cbi_id
                );
      */
            --Added for perf defect # 10750
   /*   SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
      INTO   ln_tax_amount
        FROM   ar_cons_inv_trx_all arct
              ,RA_CUSTOMER_TRX_LINES RACTL
        WHERE  1 = 1
          AND arct.cons_inv_id=p_cbi_id
          and arct.customer_trx_id=ractl.customer_trx_id
          AND RACTL.customer_trx_id =p_trx_id        
          AND RACTL.LINE_TYPE = 'TAX';
          

      lc_return_amount :=lc_return_amount + NVL(ln_tax_amount ,0);
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     lc_return_amount :=lc_return_amount+0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_order_ministmnt in formula TOTAL - TAX');
     fnd_file.put_line(fnd_file.log,  lc_error_location || lc_error_debug ||' Error Message : ' || SQLERRM ); -- Addef for the defect 10750
     lc_return_amount :=lc_return_amount+0;
   END;      

   BEGIN

        lc_error_location := ' P_MINISTMNT_LINE_TYPE - TOTAL - DISCOUNTS' ;
        lc_error_debug    := ' Trx_id : ' ||p_trx_id || 'Cbi_Id : ' || p_cbi_id ;

/*        SELECT --SUM(DISCOUNT.AMOUNT)  --Commented for Defect # 10750
               NVL(SUM(DISCOUNT.AMOUNT),0)  --Added for Defect # 10750
        INTO   ln_promo_and_disc
        FROM (
        SELECT SUM(nvl(RACTL.EXTENDED_AMOUNT ,0)) AMOUNT
        FROM   RA_CUSTOMER_TRX_LINES RACTL
              ,OE_PRICE_ADJUSTMENTS  OEPA                            
        WHERE  1 = 1
          AND RACTL.customer_trx_id =p_trx_id                
          AND RACTL.LINE_TYPE = 'LINE' 
          AND RACTL.INTERFACE_LINE_CONTEXT ='ORDER ENTRY'  --For release 1 we need invoices sourced from AOPS only           
          AND RACTL.INTERFACE_LINE_ATTRIBUTE11   = TO_CHAR(OEPA.PRICE_ADJUSTMENT_ID)
          AND RACTL.CUSTOMER_TRX_LINE_ID IN (
                SELECT CONSINV_LINES.CUSTOMER_TRX_LINE_ID
                FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
                WHERE CONSINV_LINES.CONS_INV_ID                  =p_cbi_id
                )                             
        UNION ALL
        SELECT --SUM(RACTL.EXTENDED_AMOUNT)   --Commented for Defect # 10750
               NVL(SUM(RACTL.EXTENDED_AMOUNT),0)   --Added for Defect # 10750
        FROM   RA_CUSTOMER_TRX_LINES RACTL
        WHERE  1 = 1
          AND RACTL.customer_trx_id =p_trx_id
          AND ractl.line_type = 'LINE'
          AND NVL(ractl.interface_line_context, '?') != 'ORDER ENTRY'
          AND ractl.description = 'Tiered Discount'  
          AND ractl.customer_trx_line_id IN (
            SELECT CONSINV_LINES.CUSTOMER_TRX_LINE_ID
            FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
            WHERE CONSINV_LINES.CONS_INV_ID                  =p_cbi_id
            )              
        ) DISCOUNT;
  */

  --Added for defect # 10750 perf
     /*     SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
        INTO   ln_promo_and_disc
        FROM   ar_cons_inv_trx_lines_all acit
              ,RA_CUSTOMER_TRX_LINES RACTL
              ,OE_PRICE_ADJUSTMENTS  OEPA
        WHERE  1 = 1
          AND acit.cons_inv_id = p_cbi_id
          AND acit.customer_trx_line_id = ractl.customer_trx_line_id
          AND RACTL.customer_trx_id =p_trx_id
          AND RACTL.LINE_TYPE = 'LINE' 
          AND RACTL.INTERFACE_LINE_ATTRIBUTE11 =OEPA.PRICE_ADJUSTMENT_ID;

  lc_return_amount :=lc_return_amount + NVL(ln_promo_and_disc ,0);
      RETURN lc_return_amount;        
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     lc_return_amount :=lc_return_amount+0;
      RETURN lc_return_amount;     
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_order_ministmnt in formula TOTAL - DISCOUNTS');
     fnd_file.put_line(fnd_file.log,  lc_error_location || lc_error_debug ||' Error Message : ' || SQLERRM ); -- Addef for the defect 10750
     lc_return_amount :=lc_return_amount+0;
      RETURN lc_return_amount;     
   END;    

 ELSIF p_ministmnt_line_type ='DELIVERY' THEN

   BEGIN 
    lc_error_location := ' P_MINISTMNT_LINE_TYPE - DELIVERY ' ;
    lc_error_debug    := ' Trx_id : ' ||p_trx_id || 'Cbi_Id : ' || p_cbi_id ;

/*   SELECT --SUM(nvl(RACTL.EXTENDED_AMOUNT ,0))  --Commented for Defect # 10750
          NVL(SUM(RACTL.EXTENDED_AMOUNT),0)  --Added for Defect # 10750
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
       AND RACTL.interface_line_attribute6  =to_char(OEOL.line_id)
       AND RACTL.inventory_item_id          =OD_FEES_ITEM.odf_item_id      
       AND MSIB.inv_item_id                 =RACTL.inventory_item_id      
--       AND RACTL.CUSTOMER_TRX_LINE_ID NOT IN 
--       (
--          SELECT RACTL.CUSTOMER_TRX_LINE_ID
--          FROM   RA_CUSTOMER_TRX_LINES  RACTLI
--                ,OE_PRICE_ADJUSTMENTS OEPA
--          WHERE  1 = 1
--          AND RACTL.INTERFACE_LINE_ATTRIBUTE11 = OEPA.PRICE_ADJUSTMENT_ID
--          AND RACTLI.CUSTOMER_TRX_LINE_ID = RACTL.CUSTOMER_TRX_LINE_ID
--       )    
       AND RACTL.CUSTOMER_TRX_ID IN (
             SELECT CONSINV_LINES.CUSTOMER_TRX_ID
             FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
             WHERE CONSINV_LINES.CONS_INV_ID =p_cbi_id
            );
  */

--Added for Defect 10750 perf
/*  oe_profile.get('SO_ORGANIZATION_ID',SO_ORGANIZATION_ID);

            SELECT    NVL(SUM(RCTL.extended_amount),0)
            INTO      ln_delvy_chrgs
            FROM       ar_cons_inv_trx_all arci
                      ,ra_customer_trx_lines   RCTL
                      ,mtl_system_items       MSI
            WHERE     arci.cons_inv_id=p_cbi_id
            AND       arci.customer_trx_id=rctl.customer_trx_id
            AND       RCTL.customer_trx_id     = p_trx_id
            AND       RCTL.inventory_item_id    = MSI.inventory_item_id (+)
            AND       MSI.organization_id(+)    = so_organization_id
            AND       EXISTS (SELECT attribute6
                              FROM   fnd_lookup_values FLV
                              WHERE  FLV.lookup_type='OD_FEES_ITEMS'
                              AND    FLV.attribute7  ='DELIVERY'
                              AND    NVL(FLV.attribute6,0) = rctl.inventory_item_id);

  
    RETURN ln_delvy_chrgs;

    EXCEPTION 
     WHEN NO_DATA_FOUND THEN
     ln_delvy_chrgs :=ln_delvy_chrgs+0;
     RETURN ln_delvy_chrgs;     
     WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_order_ministmnt in formula DELIVERY');
     fnd_file.put_line(fnd_file.log,  lc_error_location || lc_error_debug ||' Error Message : ' || SQLERRM ); -- Addef for the defect 10750
     ln_delvy_chrgs :=ln_delvy_chrgs+0;
     RETURN ln_delvy_chrgs;     
   END;    

 ELSE
   RETURN(0);

 END IF;

 EXCEPTION
 WHEN NO_DATA_FOUND THEN
     fnd_file.put_line(fnd_file.log, 'NODATA @ xx_ar_cbi_order_ministmnt...'||SQLERRM); 
     fnd_file.put_line(fnd_file.log,  lc_error_location || lc_error_debug ); -- Addef for the defect 10750
     RETURN(0);
 WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_order_ministmnt...'||SQLERRM);  
     fnd_file.put_line(fnd_file.log,  lc_error_location || lc_error_debug ); -- Addef for the defect 10750
     RETURN(0);    
END xx_ar_cbi_order_ministmnt; 
       Commented for the Defect 13937  */

--=================================================================--
       --Start of changes for the defect 13937       
--=================================================================--
   IF (p_ministmnt_line_type ='EXTAMT_PLUS_DELVY') THEN
      BEGIN
         lc_error_location := 'P_MINISTMNT_LINE_TYPE - EXTAMT_PLUS_DELVY';
         lc_error_debug    := 'Trx_id : ' ||p_trx_id || 'Cbi_Id : ' || p_cbi_id;

         SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
         INTO   ln_ext_amt_plus_delvy
         FROM   ar_cons_inv_trx_all   ARCT
               ,ra_customer_trx_lines_all RACTL
         WHERE  ARCT.cons_inv_id=p_cbi_id
         AND    ARCT.customer_trx_id             = ractl.customer_trx_id
         AND    RACTL.customer_trx_id            = p_trx_id
         AND    RACTL.LINE_TYPE                  = 'LINE'
         AND    RACTL.interface_line_attribute11 = '0';

         RETURN ln_ext_amt_plus_delvy;
      EXCEPTION
         WHEN OTHERS THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error at xx_ar_cbi_order_ministmnt in formula -- EXTAMT+DELVY');
              FND_FILE.PUT_LINE(FND_FILE.LOG,  lc_error_location || lc_error_debug ||' Error Message : ' || SQLERRM );
         RETURN (0);   
      END;               
   ELSIF (p_ministmnt_line_type ='TAX') THEN
      BEGIN
         lc_error_location := 'P_MINISTMNT_LINE_TYPE - TAX';
         lc_error_debug    := ' Trx_id : ' ||p_trx_id || 'Cbi_Id : ' || p_cbi_id;

         SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
         INTO   ln_tax_amount
         FROM   ar_cons_inv_trx_all   ARCT
               ,ra_customer_trx_lines_all RACTL
         WHERE  ARCT.cons_inv_id       = p_cbi_id
         AND    ARCT.customer_trx_id   = ractl.customer_trx_id
         AND    RACTL.customer_trx_id  = p_trx_id
         AND    RACTL.LINE_TYPE        = 'TAX';

         RETURN ln_tax_amount;
      EXCEPTION
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error at xx_ar_cbi_order_ministmnt in formula -- TAX');
            FND_FILE.PUT_LINE(FND_FILE.LOG,  lc_error_location || lc_error_debug ||' Error Message : ' || SQLERRM );
            RETURN (0);
      END;
   ELSIF (p_ministmnt_line_type ='DISCOUNT') THEN
      BEGIN

         lc_error_location := 'P_MINISTMNT_LINE_TYPE - DISCOUNT';
         lc_error_debug    := ' Trx_id : ' ||p_trx_id || 'Cbi_Id : ' || p_cbi_id;

         SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
         INTO   ln_promo_and_disc
         FROM   ar_cons_inv_trx_lines_all ACIT
               ,ra_customer_trx_lines_all     RACTL
			   ,xx_oe_price_adjustments_v OEPA  -- Commented and Changed by Punit CG on 18-APR-2018 for Defect NAIT-31695
               --,oe_price_adjustments      OEPA
         WHERE ACIT.cons_inv_id                            = p_cbi_id
         AND   ACIT.customer_trx_line_id                   = RACTL.customer_trx_line_id
         AND   RACTL.customer_trx_id                       = p_trx_id
         AND   RACTL.LINE_TYPE                             = 'LINE'
         AND   TO_NUMBER(RACTL.interface_line_attribute11) = OEPA.price_adjustment_id;
         
        
       -- Start of changes for defect 1451 CR 626

         lc_error_location := 'Getting transaction type for gift card transactions';
         lc_error_debug    := ' Trx_id : ' ||p_trx_id;
         SELECT  RCTT.type
         INTO    lc_trx_type
         FROM    ra_customer_trx_all RCT
                ,ra_cust_trx_types_all  RCTT
         WHERE   RCT.cust_trx_type_id            = RCTT.cust_trx_type_id
         AND     RCT.customer_trx_id             = p_trx_id;
 
         IF (lc_trx_type = 'INV') THEN
            lc_error_location := 'Getting total amount for gift card invoices';
            lc_error_debug    := ' Trx_id : ' ||p_trx_id;
            SELECT  NVL(SUM(OP.payment_amount),0)
            INTO    ln_gc_amt
            FROM    xx_oe_payments_v OP -- Commented and Changed by Punit CG on 18-APR-2018 for Defect NAIT-31695
			        --apps.oe_payments OP
                   ,ra_customer_trx_all RCT
            WHERE   OP.header_id        = RCT.attribute14
            AND     RCT.customer_trx_id = p_trx_id;

            ln_promo_and_disc := ln_promo_and_disc - ln_gc_amt;

         ELSIF (lc_trx_type = 'CM') THEN

            lc_error_location := 'Getting total amount for gift card credit memos';
            lc_error_debug    := ' Trx_id : ' ||p_trx_id;
            SELECT  NVL(SUM(ORT.credit_amount),0) 
            INTO    ln_gc_amt
            FROM    apps.xx_om_return_tenders_all ORT
                   ,ra_customer_trx_all RCT
            WHERE   ORT.header_id       = RCT.attribute14
            AND     RCT.customer_trx_id = p_trx_id;

            ln_promo_and_disc := ln_promo_and_disc + ln_gc_amt;

         END IF;

        -- End of changes for defect 1451 CR 626

         RETURN ln_promo_and_disc;

      EXCEPTION
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error at xx_ar_cbi_order_ministmnt in formula -- DISCOUNTS');
            FND_FILE.PUT_LINE(FND_FILE.LOG, lc_error_location || lc_error_debug ||' Error Message : ' || SQLERRM );
            RETURN (0);
      END;

   ELSIF (p_ministmnt_line_type ='TOTAL')THEN

      BEGIN
         ln_gc_amt := 0;   -- Added for R1.1 Defect # 1451 (CR 626)
         lc_error_location := ' P_MINISTMNT_LINE_TYPE - TOTAL' ;
         lc_error_debug    := ' Trx_id : ' ||p_trx_id || 'Cbi_Id : ' || p_cbi_id ;

         SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
         INTO   ln_total_amount
         FROM   ar_cons_inv_trx_all ACIT
               ,ra_customer_trx_lines_all RACTL
         WHERE ACIT.cons_inv_id      = p_cbi_id
         AND   ACIT.customer_trx_id  = RACTL.customer_trx_id
         AND   RACTL.customer_trx_id = p_trx_id;

       -- Start of changes for defect 1451 CR 626

         lc_error_location := 'Getting transaction type for gift card transactions';
         lc_error_debug    := ' Trx_id : ' ||p_trx_id;
         SELECT  RCTT.type
         INTO    lc_trx_type
         FROM    ra_customer_trx_all RCT
                ,ra_cust_trx_types_all  RCTT
         WHERE   RCT.cust_trx_type_id            = RCTT.cust_trx_type_id
         AND     RCT.customer_trx_id             = p_trx_id;
 
         IF (lc_trx_type = 'INV') THEN
            lc_error_location := 'Getting total amount for gift card invoices';
            lc_error_debug    := ' Trx_id : ' ||p_trx_id;
            SELECT  NVL(SUM(OP.payment_amount),0)
            INTO    ln_gc_amt
            FROM    xx_oe_payments_v OP -- Commented and Changed by Punit CG on 18-APR-2018 for Defect NAIT-31695
			        --apps.oe_payments OP
                   ,ra_customer_trx_all RCT
            WHERE   OP.header_id        = RCT.attribute14
            AND     RCT.customer_trx_id = p_trx_id;

            ln_total_amount := ln_total_amount - ln_gc_amt;

         ELSIF (lc_trx_type = 'CM') THEN
            lc_error_location := 'Getting total amount for gift card credit memos';
            lc_error_debug    := ' Trx_id : ' ||p_trx_id;
            SELECT  NVL(SUM(ORT.credit_amount),0) 
            INTO    ln_gc_amt
            FROM    apps.xx_om_return_tenders_all ORT
                   ,ra_customer_trx_all RCT
            WHERE   ORT.header_id       = RCT.attribute14
            AND     RCT.customer_trx_id = p_trx_id;

            ln_total_amount := ln_total_amount + ln_gc_amt;

         END IF;

       -- End of changes for defect 1451 CR 626

         RETURN ln_total_amount;
      EXCEPTION
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error at xx_ar_cbi_order_ministmnt in formula -- TOTAL');
            FND_FILE.PUT_LINE(FND_FILE.LOG,  lc_error_location || lc_error_debug ||' Error Message : ' || SQLERRM );
            RETURN (0);
      END;

   ELSIF (p_ministmnt_line_type ='DELIVERY') THEN

      BEGIN 
         lc_error_location := ' P_MINISTMNT_LINE_TYPE - DELIVERY ' ;
         lc_error_debug    := ' Trx_id : ' ||p_trx_id || 'Cbi_Id : ' || p_cbi_id ;

         SELECT NVL(SUM(RCTL.extended_amount),0)
         INTO   ln_delvy_chrgs
         FROM   ar_cons_inv_trx_all   ARCI
               ,ra_customer_trx_lines_all RCTL
         WHERE  ARCI.cons_inv_id = p_cbi_id
         AND    ARCI.customer_trx_id = rctl.customer_trx_id
         AND    RCTL.customer_trx_id = p_trx_id
         AND    EXISTS ( SELECT 1
                         FROM  fnd_lookup_values
                         WHERE lookup_type         = 'OD_FEES_ITEMS'
                         AND attribute7            = 'DELIVERY'
                         AND TO_NUMBER(attribute6) = RCTL.inventory_item_id
                         AND LANGUAGE = USERENV ('LANG')
                         );

         RETURN ln_delvy_chrgs;

      EXCEPTION 
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error at xx_ar_cbi_order_ministmnt in formula -- DELIVERY');
            FND_FILE.PUT_LINE(FND_FILE.LOG,  lc_error_location || lc_error_debug ||' Error Message : ' || SQLERRM );
            RETURN (0);
      END;

   ELSE
      RETURN (0);
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error at xx_ar_cbi_order_ministmnt...'||SQLERRM);
      FND_FILE.PUT_LINE(FND_FILE.LOG,  lc_error_location || lc_error_debug );
      RETURN (0);

END XX_AR_CBI_ORDER_MINISTMNT;
/

SHOW ERRORS