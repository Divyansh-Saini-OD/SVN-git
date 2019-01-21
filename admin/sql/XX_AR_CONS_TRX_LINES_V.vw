---+========================================================================================================+        
---|                                        Office Depot - Project Simplify                                 |
---|                             Oracle NAIO/WIPRO/Office Depot/Consulting Organization                     |
---+========================================================================================================+
---|    Application             :       AR                                                                  |
---|                                                                                                        |
---|    Name                    :       xx_ar_print_summbill.pkb                                      |
---|                                                                                                        |
---|    Description             :                                                                           |
---|                                                                                                        |
---|                                                                                                        |
---|                                                                                                        |
---|    Change Record                                                                                       |
---|    ---------------------------------                                                                   |
---|    Version         DATE              AUTHOR             DESCRIPTION                                     |
---|    ------------    ----------------- ---------------    ---------------------                           |
---|    1.0             02-AUG-2007       Balaguru Seshadri  Initial Version                                 |
---|                                                                                                        |
---+========================================================================================================+
CREATE OR REPLACE VIEW APPS.XX_AR_CONS_TRX_LINES_V 
AS
SELECT
       ARCIT.CONS_INV_ID                                        CONSINV_ID
      ,ARCIT.CONS_INV_LINE_NUMBER                               CONSINV_LNUM
      ,CONSINV_LINES.LINE_NUMBER                                CONS_LINES_LNUM
      ,ARCIT.TRX_NUMBER                                         INVOICE_NUMBER
      ,TO_CHAR(ARCIT.TRANSACTION_DATE,'MM/DD/RRRR')             INV_DATE
      ,DECODE
         (
          ARCIT.TRANSACTION_TYPE
          ,'INVOICE'
          ,'INV'
          ,'CREDIT_MEMO'
          ,'CM'
          ,NULL
         )                                                      TYPE     
      ,XX_AR_REPRINT_SUMMBILL.GET_PO_NUMBER
         ( ARCIT.CONS_INV_ID
          ,ARCIT.CONS_INV_LINE_NUMBER
         )                                                      PO_NUMBER 
      ,CONSINV_LINES.CUSTOMER_TRX_ID                            TRX_ID
      ,CONSINV_LINES.CUSTOMER_TRX_LINE_ID                       TRX_LINE_ID
      ,CONSINV_LINES.INVENTORY_ITEM_ID
      ,XX_AR_REPRINT_SUMMBILL.GET_ITEM_NUMBER
        (
          CONSINV_LINES.INVENTORY_ITEM_ID 
        )                                                       ITEM_NUMBER
      ,CONSINV_LINES.DESCRIPTION                                DESCRIPTION
      ,CONSINV_LINES.UOM_CODE                                   UNIT_OF_MEASURE        
      ,TO_CHAR(CONSINV_LINES.TAX_AMOUNT,'999990.90')            LINE_TAX_AMT
      ,CONSINV_LINES.QUANTITY_INVOICED                          QUANTITY      
      ,TO_CHAR(CONSINV_LINES.UNIT_SELLING_PRICE,'999990.90')    PRICE      
      ,TO_CHAR(CONSINV_LINES.EXTENDED_AMOUNT,'999990.90')       EACH_LINE_AMOUNT
      ,TO_CHAR
       (
        (  CONSINV_LINES.EXTENDED_AMOUNT
          +
           CONSINV_LINES.TAX_AMOUNT
        ),'999990.90'
       )                                                        LINE_TOT_AMT            
FROM   
       AR_CONS_INV_TRX       ARCIT 
      ,AR_CONS_INV_TRX_LINES CONSINV_LINES
WHERE CONSINV_LINES.CONS_INV_ID          =ARCIT.CONS_INV_ID
  AND CONSINV_LINES.CONS_INV_LINE_NUMBER =ARCIT.CONS_INV_LINE_NUMBER
  AND ARCIT.TRANSACTION_TYPE IN 
 (
   'INVOICE'
  ,'CREDIT_MEMO'
 )
UNION ALL
SELECT
       ARCIT.CONS_INV_ID                                        
      ,TO_NUMBER(NULL)                                          
      ,TO_NUMBER(NULL)                                          
      ,ARCIT.TRX_NUMBER                                         
      ,TO_CHAR(ARCIT.TRANSACTION_DATE,'MM/DD/RRRR')             
      ,DECODE
         (
          ARCIT.TRANSACTION_TYPE
          ,'ADJUSTMENT'
          ,'ADJ'
          ,NULL
         )                                                          
      ,TO_CHAR(NULL)  
      ,TO_NUMBER(NULL)
      ,TO_NUMBER(NULL)
      ,TO_NUMBER(NULL)
      ,TO_CHAR(NULL)
      ,TO_CHAR(NULL)
      ,TO_CHAR(NULL)        
      ,TO_CHAR(ARCIT.TAX_ORIGINAL, '999990.90')
      ,TO_NUMBER(NULL)      
      ,TO_CHAR(NULL)      
      ,TO_CHAR(ARCIT.AMOUNT_ORIGINAL,'999990.90')
      ,TO_CHAR( (ARCIT.AMOUNT_ORIGINAL + ARCIT.TAX_ORIGINAL),'999990.90')                                                                                                        
FROM   
       AR_CONS_INV_TRX       ARCIT 
WHERE ARCIT.TRANSACTION_TYPE ='ADJUSTMENT'
/