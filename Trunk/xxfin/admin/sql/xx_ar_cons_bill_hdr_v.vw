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
CREATE OR REPLACE VIEW XX_AR_CONS_BILL_HDR_V AS
         SELECT TRIM(SUBSTR(ARSP.TAX_REGISTRATION_NUMBER,1,16)) TAX_ID,
          DECODE
           (
              ARCI.CURRENCY_CODE
             ,'USD'
             ,'FEDERAL ID #:'
             ,'CAD'
             ,'GST REGISTRATION #:'
           )                                              TAX_ID_DESC,         
          TRIM(SUBSTR(ARSP.ATTRIBUTE5 ,1 ,16))            ACCOUNT_CONTACT, 
          TRIM(SUBSTR(ARSP.ATTRIBUTE3 ,1 ,16))            ORDER_CONTACT,
          ARCI.CURRENCY_CODE                              CURRENCY,
          ARCI.CUSTOMER_ID                                CUSTOMER_ID,
          ARCI.CONS_INV_ID                                CONS_INV_ID,
          ARCI.SITE_USE_ID                                SITE_USE_ID,
          ARCI.ORG_ID                                     CONS_INV_ORG,          
          ARCI.CONS_BILLING_NUMBER                        BILLING_NO,
          ARCI.CREATION_DATE                              IMPORTED_DATE,         
          TO_CHAR (ARCI.ISSUE_DATE, 'MM/DD/RRRR')         ISSUE_DATE,
          TO_CHAR (ARCI.CUT_OFF_DATE, 'MM/DD/RRRR')       CUT_OFF_DATE,
          TO_CHAR (ARCI.DUE_DATE, 'MM/DD/RRRR')           DUE_DATE,
          HZP.PARTY_NAME                                  CUSTOMER_NAME, 
          HZCA.ACCOUNT_NUMBER                             CUSTOMER_NUMBER,
          SUBSTR(HZCA.ORIG_SYSTEM_REFERENCE ,1 ,8)        LEGACY_CUSTOMER,          
          DECODE(ARCI.CURRENCY_CODE, 'USD', 'US', 'CAD', 'CA')      BILL_TO_COUNTRY,
          TRIM(XX_AR_UTILITIES_PKG.GET_FIELD
           ( '|', 
             1, 
             XX_AR_UTILITIES_PKG.ADDR_FMT
             (ARCI.SITE_USE_ID,
              DECODE(ARCI.CURRENCY_CODE, 'USD', 'US', 'CAD', 'CA', NULL), 
              DECODE(ARCI.CURRENCY_CODE, 'USD', 'UNITED STATES', 'CAD', 'CANADA', NULL),
              'BILL-TO'              
             )
           ))                                             ADDRESS1,                            
          TRIM(XX_AR_UTILITIES_PKG.GET_FIELD
           ( '|', 
             2, 
             XX_AR_UTILITIES_PKG.ADDR_FMT
             (ARCI.SITE_USE_ID,
              DECODE(ARCI.CURRENCY_CODE, 'USD', 'US', 'CAD', 'CA', NULL), 
              DECODE(ARCI.CURRENCY_CODE, 'USD', 'UNITED STATES', 'CAD', 'CANADA', NULL),
              'BILL-TO'              
             )
           ))                                             ADDRESS2,           
          TRIM(XX_AR_UTILITIES_PKG.GET_FIELD
           ( '|', 
             3, 
             XX_AR_UTILITIES_PKG.ADDR_FMT
             (ARCI.SITE_USE_ID,
              DECODE(ARCI.CURRENCY_CODE, 'USD', 'US', 'CAD', 'CA', NULL), 
              DECODE(ARCI.CURRENCY_CODE, 'USD', 'UNITED STATES', 'CAD', 'CANADA', NULL),
              'BILL-TO'              
             )
           ))                                             CITY,   
          DECODE(ARCI.CURRENCY_CODE, 'CAD',TRIM(XX_AR_UTILITIES_PKG.GET_FIELD(' ',2,
           TRIM(XX_AR_UTILITIES_PKG.GET_FIELD
           ( '|', 
             3, 
             XX_AR_UTILITIES_PKG.ADDR_FMT
             (ARCI.SITE_USE_ID,
              DECODE(ARCI.CURRENCY_CODE, 'USD', 'US', 'CAD', 'CA', NULL), 
              DECODE(ARCI.CURRENCY_CODE, 'USD', 'UNITED STATES', 'CAD', 'CANADA', NULL),
              'BILL-TO'              
             )
           )))),'USD',NULL)                               PROVINCE,                       
          TRIM(XX_AR_UTILITIES_PKG.GET_FIELD
           ( '|', 
             1, 
             XX_AR_UTILITIES_PKG.ADDR_FMT
             (ARCI.SITE_USE_ID,
              DECODE(ARCI.CURRENCY_CODE, 'USD', 'US', 'CAD', 'CA', NULL), 
              DECODE(ARCI.CURRENCY_CODE, 'USD', 'UNITED STATES', 'CAD', 'CANADA', NULL),
              'REMIT'              
             )
           ))                                             RADDRESS1,                            
          TRIM(XX_AR_UTILITIES_PKG.GET_FIELD
           ( '|', 
             2, 
             XX_AR_UTILITIES_PKG.ADDR_FMT
             (ARCI.SITE_USE_ID,
              DECODE(ARCI.CURRENCY_CODE, 'USD', 'US', 'CAD', 'CA', NULL), 
              DECODE(ARCI.CURRENCY_CODE, 'USD', 'UNITED STATES', 'CAD', 'CANADA', NULL),
              'REMIT'              
             )
           ))                                             RADDRESS2,           
          TRIM(XX_AR_UTILITIES_PKG.GET_FIELD
           ( '|', 
             3, 
             XX_AR_UTILITIES_PKG.ADDR_FMT
             (ARCI.SITE_USE_ID,
              DECODE(ARCI.CURRENCY_CODE, 'USD', 'US', 'CAD', 'CA', NULL), 
              DECODE(ARCI.CURRENCY_CODE, 'USD', 'UNITED STATES', 'CAD', 'CANADA', NULL),
              'REMIT'              
             )
           ))                                             RCITY,                      
          ARCI.BEGINNING_BALANCE                          CD_BEGINNING_BALANCE,
          ARCI.ENDING_BALANCE                             CD_ENDING_BALANCE, 
          APPS.XX_AR_UTILITIES_PKG.GET_PERIOD_RECEIPTS
                                                   (ARCI.CONS_INV_ID,
                                                    ARCI.CUSTOMER_ID,
                                                    ARCI.SITE_USE_ID
                                                   )      CD_PERIOD_RECEIPTS,
          APPS.XX_AR_UTILITIES_PKG.GET_TAX_AMOUNT  (ARCI.CONS_INV_ID,
                                                    ARCI.CUSTOMER_ID,
                                                    ARCI.SITE_USE_ID
                                                   )      CD_PERIOD_TAX, 
          APPS.XX_AR_UTILITIES_PKG.GET_GROSS_AMOUNT (ARCI.CONS_INV_ID,
                                                     ARCI.CUSTOMER_ID,
                                                     ARCI.SITE_USE_ID
                                                   )      CD_PERIOD_BILLED,                                                               
          INITCAP ('ORIGINAL SUMMARY BILL')               PRINT_INSTANCE,
          INITCAP('TO RETURN SUPPLIES, PLEASE REPAIR IN ORIGINAL BOX AND INSERT OUR PACKING LIST OR A COPY OF THIS INVOICE. PLEASE NOTE PROBLEM SO WE MAY ISSUE CREDIT OR REPLACEMENT, WHICHEVER YOU PREFER. PLEASE DO NOT SHIP COLLECT. PLEASE DO NOT RETURN FURNITURE OR MACHINES UNTIL YOU CALL US FIRST FOR INSTRUCTIONS. SHORTAGE OR DAMAGE MUST BE REPORTED WITHIN 5DAYS AFTER DELIVERY.')
                                                          PAYSTUB_UPPER_TEXT
     FROM AR_CONS_INV          ARCI,
          HZ_CUST_ACCOUNTS     HZCA,
          HZ_PARTIES           HZP,
          AR_SYSTEM_PARAMETERS ARSP                 
    WHERE HZCA.CUST_ACCOUNT_ID = ARCI.CUSTOMER_ID
      AND HZP.PARTY_ID = HZCA.PARTY_ID 
      AND ARSP.TAX_CURRENCY_CODE =ARCI.CURRENCY_CODE   
/ 