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
CREATE OR REPLACE VIEW APPS.XX_AR_CONS_BILL_ONE_V
AS 
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
          ARCI.ORG_ID                                     CONS_INV_ORG,          
          ARCI.CONS_BILLING_NUMBER                        BILLING_NO,
          TO_CHAR (ARCI.CREATION_DATE, 'MM/DD/RRRR')      IMPORT_DATE,         
          TO_CHAR (ARCI.ISSUE_DATE, 'MM/DD/RRRR')         ISSUE_DATE,
          TO_CHAR (ARCI.CUT_OFF_DATE, 'MM/DD/RRRR')       CUT_OFF_DATE,
          TO_CHAR (ARCI.DUE_DATE, 'MM/DD/RRRR')           DUE_DATE,
          HZP.PARTY_NAME                                  CUSTOMER_NAME,
          TRIM(SUBSTR(HZCA.ORIG_SYSTEM_REFERENCE, 1 ,8))  ACCOUNT_NUMBER,
          HZCA.ACCOUNT_NUMBER                             CUSTOMER_NUMBER,
          HZLO.ADDRESS1                                   ADDRESS1,                            
          HZLO.ADDRESS2                                   ADDRESS2,
          DECODE
           (
             HZLO.COUNTRY
            ,'US'
            ,HZLO.CITY||' ,'||HZLO.STATE||' '||HZLO.POSTAL_CODE
            ,'CA'
            ,HZLO.CITY||' '||HZLO.PROVINCE||' '||HZLO.POSTAL_CODE        
           )                                              CITY,                    
           HZLO.PROVINCE                                  PROVINCE,
           FTL.TERRITORY_SHORT_NAME                       COUNTRY,
           RHZLO.ADDRESS1                                 RADDRESS1,                            
           RHZLO.ADDRESS2                                 RADDRESS2,       
           DECODE
            (
              RHZLO.COUNTRY
             ,'US'
             ,RHZLO.CITY||' ,'||RHZLO.STATE||' '||RHZLO.POSTAL_CODE
             ,'CA'
             ,RHZLO.CITY||' '||RHZLO.PROVINCE||' '||RHZLO.POSTAL_CODE        
            )                                             RCITY,        
          RFTL.TERRITORY_SHORT_NAME                       RCOUNTRY,            
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
     FROM AR_CONS_INV          ARCI
         ,HZ_CUST_ACCOUNTS     HZCA
         ,HZ_PARTIES           HZP
         ,AR_SYSTEM_PARAMETERS ARSP 
         ,HZ_CUST_ACCT_SITES   HZAS
         ,HZ_CUST_SITE_USES    HZSU
         ,HZ_PARTY_SITES       HZPS
         ,HZ_LOCATIONS         HZLO
         ,HZ_CUST_ACCT_SITES   RHZCA
         ,HZ_PARTY_SITES       RHZPS
         ,HZ_LOCATIONS         RHZLO 
         ,FND_TERRITORIES_TL   FTL
         ,FND_TERRITORIES_TL   RFTL                              
    WHERE HZCA.CUST_ACCOUNT_ID    =ARCI.CUSTOMER_ID
      AND HZP.PARTY_ID            =HZCA.PARTY_ID 
      AND ARSP.TAX_CURRENCY_CODE  =ARCI.CURRENCY_CODE 
      AND HZAS.CUST_ACCOUNT_ID    =HZCA.CUST_ACCOUNT_ID
      AND HZSU.CUST_ACCT_SITE_ID  =HZAS.CUST_ACCT_SITE_ID
      AND HZSU.SITE_USE_ID        =ARCI.SITE_USE_ID
      AND HZPS.PARTY_SITE_ID      =HZAS.PARTY_SITE_ID
      AND HZLO.LOCATION_ID        =HZPS.LOCATION_ID
      AND RHZCA.CUST_ACCT_SITE_ID =XX_AR_UTILITIES_PKG.GET_REMITADDRESSID(ARCI.SITE_USE_ID)
      AND RHZPS.PARTY_SITE_ID     =RHZCA.PARTY_SITE_ID
      AND RHZLO.LOCATION_ID       =RHZPS.LOCATION_ID
      AND FTL.TERRITORY_CODE      =DECODE
                                    (
                                     ARCI.CURRENCY_CODE,
                                     'USD',
                                     'US',
                                     'CAD',
                                     'CA',
                                     HZLO.COUNTRY
                                    )
      AND FTL.LANGUAGE           ='US'
      AND RFTL.TERRITORY_CODE    =DECODE
                                   (
                                    ARCI.CURRENCY_CODE,
                                    'USD',
                                    'US',
                                    'CAD',
                                    'CA',
                                    RHZLO.COUNTRY
                                   )
      AND RFTL.LANGUAGE          ='US'      
      /