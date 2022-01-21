-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XX_AP_SUPP_SITE_CONT_LOAD.ctl                                               |
-- | Rice Id      : Defect 32542                                                                |
-- | Description  : I2170_One time vendor conversion for customer rebate checks                 |
-- | Purpose      : Insret into Custom Table XX_AP_SUPP_SITE_CONTACT_STG                                 |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author                Remarks                                      |
-- |=======    ==========    =================    ==============================================+
-- |DRAFT 1A   06-JAN-2015   Amarnath Modium      Initial Version                               |
-- |                                                                                            |
-- +============================================================================================+
OPTIONS(SKIP=1)
LOAD DATA
APPEND
INTO TABLE XXFIN.XX_AP_SUPP_SITE_CONTACT_STG
FIELDS TERMINATED BY ","
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
    (  SUPPLIER_NAME                         CHAR"TRIM(:SUPPLIER_NAME)"
      ,SITE_NUMBER                           CHAR"TRIM(:SITE_NUMBER)"
      ,COUNTRY                               CHAR"TRIM(:COUNTRY)"
      ,ADDRESS_LINE1                         CHAR"TRIM(:ADDRESS_LINE1)"
      ,ADDRESS_LINE2                         CHAR"TRIM(:ADDRESS_LINE2)"
      ,CITY                                  CHAR"TRIM(:CITY)"
      ,STATE		                     CHAR"TRIM(:STATE)"
      ,PROVINCE                     	     CHAR"TRIM(:PROVINCE)"
      ,POSTAL_CODE                           CHAR"TRIM(:POSTAL_CODE)"
      ,ADDRESS_NAME_PREFIX                   CHAR"TRIM(:ADDRESS_NAME_PREFIX)"
      ,PHONE_AREA_CODE                       CHAR"TRIM(:PHONE_AREA_CODE)"
      ,PHONE_NUMBER                          CHAR"TRIM(:PHONE_NUMBER)"
      ,FAX_AREA_CODE                         CHAR"TRIM(:FAX_AREA_CODE)"
      ,FAX_NUMBER                            CHAR"TRIM(:FAX_NUMBER)"
      ,EMAIL_ADDRESS                         CHAR"TRIM(:EMAIL_ADDRESS)"
      ,ADDRESS_PURPOSE                       CHAR"TRIM(:ADDRESS_PURPOSE)"
      ,OPERATING_UNIT                        CHAR"TRIM(:OPERATING_UNIT)"
      ,CONT_FIRST_NAME                       CHAR"TRIM(:CONT_FIRST_NAME)"
      ,CONT_LAST_NAME                        CHAR"TRIM(:CONT_LAST_NAME)"
      ,CONT_ALTERNATE_NAME                   CHAR"TRIM(:CONT_ALTERNATE_NAME)"
      ,CONT_DEPARTMENT                       CHAR"TRIM(:CONT_DEPARTMENT)"
      ,CONT_EMAIL_ADDRESS                    CHAR"TRIM(:CONT_EMAIL_ADDRESS)"
      ,CONT_PHONE_AREA_CODE                  CHAR"TRIM(:CONT_PHONE_AREA_CODE)"
      ,CONT_PHONE_NUMBER                     CHAR"TRIM(:CONT_PHONE_NUMBER)"
      ,CONT_FAX_AREA_CODE                    CHAR"TRIM(:CONT_FAX_AREA_CODE)"
      ,CONT_FAX_NUMBER                       CHAR"TRIM(:CONT_FAX_NUMBER)"
      ,CONT_ADDRESS_NAME                     CHAR"TRIM(:CONT_ADDRESS_NAME)"
      ,LIABILITY_ACCOUNT                     CHAR"TRIM(:LIABILITY_ACCOUNT)"
      ,REPORTING_NAME                        CHAR"TRIM(:REPORTING_NAME)"
      ,VERFICATION_DATE                      DATE "MM/DD/YYYY"
      ,ORGANIZATION_TYPE                     CHAR"TRIM(:ORGANIZATION_TYPE)"
      ,INCOME_TAX_REP_SITE                   CHAR"TRIM(:INCOME_TAX_REP_SITE)"
      ,SHIP_TO_LOCATION                      CHAR"TRIM(:SHIP_TO_LOCATION)"
      ,BILL_TO_LOCATION                      CHAR"TRIM(:BILL_TO_LOCATION)"
      ,SHIP_VIA_CODE                         CHAR"TRIM(:SHIP_VIA_CODE)"
      ,CREATE_DEB_MEMO_FRM_RTS               CHAR"TRIM(:CREATE_DEB_MEMO_FRM_RTS)"
      ,FOB                                   CHAR"TRIM(:FOB)"
      ,FREIGHT_TERMS                         CHAR"TRIM(:FREIGHT_TERMS)"
      ,PAYMENT_METHOD                        CHAR"TRIM(:PAYMENT_METHOD)"
      ,INVOICE_TOLERANCE                     CHAR"TRIM(:INVOICE_TOLERANCE)"
      ,INVOICE_MATCH_OPTION                  CHAR"TRIM(:INVOICE_MATCH_OPTION)"
      ,INVOICE_CURRENCY                      CHAR"TRIM(:INVOICE_CURRENCY)"
      ,HOLD_FROM_PAYMENT                     CHAR"TRIM(:HOLD_FROM_PAYMENT)"
      ,PAYMENT_CURRENCY                      CHAR"TRIM(:PAYMENT_CURRENCY)"
      ,PAYMENT_PRIORITY                      CHAR"TRIM(:PAYMENT_PRIORITY)"
      ,PAY_GROUP                             CHAR"TRIM(:PAY_GROUP)"
      ,DEDUCT_FRM_BANK_CHRG                  CHAR"TRIM(:DEDUCT_FRM_BANK_CHRG)"
      ,TERMS_CODE                            CHAR"TRIM(:TERMS_CODE)"
      ,TERMS_DATE_BASIS                      CHAR"TRIM(:TERMS_DATE_BASIS)"
      ,PAY_DATE_BASIS                        CHAR"TRIM(:PAY_DATE_BASIS)"
      ,ALWAYS_TAKE_DISC_FLAG                 CHAR"TRIM(:ALWAYS_TAKE_DISC_FLAG)"
      ,PRIMARY_PAY_FLAG			     CHAR"TRIM(:PRIMARY_PAY_FLAG)"	
      ,REFERENCE_NUM                         CHAR"TRIM(:REFERENCE_NUM)"
      ,DUNS_NUM                              CHAR"TRIM(:DUNS_NUM)"
      ,SITE_CATEGORY                         CHAR"TRIM(:SITE_CATEGORY)"
      ,RELATED_PAY_SITE			     CHAR"TRIM(:RELATED_PAY_SITE)"
      ,FUTURE_USE			     CHAR"TRIM(:FUTURE_USE)"
      ,LEAD_TIME                             CHAR"TRIM(:LEAD_TIME)"
      ,BACK_ORDER_FLAG                       CHAR"TRIM(:BACK_ORDER_FLAG)"
      ,DELIVERY_POLICY                       CHAR"TRIM(:DELIVERY_POLICY)"
      ,MIN_PREPAID_CODE                      CHAR"TRIM(:MIN_PREPAID_CODE)"
      ,VENDOR_MIN_AMT                        CHAR"TRIM(:VENDOR_MIN_AMT)"
      ,SUPPLIER_SHIP_TO                      CHAR"TRIM(:SUPPLIER_SHIP_TO)"
      ,INVENTORY_TYPE_CODE                   CHAR"TRIM(:INVENTORY_TYPE_CODE)"
      ,VERTICAL_MRKT_INDICATOR               CHAR"TRIM(:VERTICAL_MRKT_INDICATOR)"
      ,ALLOW_AUTO_RECEIPT                    CHAR"TRIM(:ALLOW_AUTO_RECEIPT)"
      ,MASTER_VENDOR_ID                      CHAR"TRIM(:MASTER_VENDOR_ID)"
      ,PI_PACK_YEAR                          CHAR"TRIM(:PI_PACK_YEAR)"
      ,OD_DATE_SIGNED                        DATE "DD-MON-YY"
      ,VENDOR_DATE_SIGNED                    DATE "DD-MON-YY"
      ,DEDUCT_FROM_INV_FLAG                  CHAR"TRIM(:DEDUCT_FROM_INV_FLAG)"
      ,COMBINE_PICK_TICKET                   CHAR"TRIM(:COMBINE_PICK_TICKET)"
      ,NEW_STORE_FLAG                        CHAR"TRIM(:NEW_STORE_FLAG)"
      ,NEW_STORE_TERMS                       CHAR"TRIM(:NEW_STORE_TERMS)"
      ,SEASONAL_FLAG                         CHAR"TRIM(:SEASONAL_FLAG)"
      ,START_DATE                            DATE "DD-MON-YY"
      ,END_DATE                              DATE "DD-MON-YY"
      ,SEASONAL_TERMS                        CHAR"TRIM(:SEASONAL_TERMS)"
      ,LATE_SHIP_FLAG                        CHAR"TRIM(:LATE_SHIP_FLAG)"
      ,EDI_850                               CHAR"TRIM(:EDI_850)"
      ,EDI_860                               CHAR"TRIM(:EDI_860)"
      ,EDI_855                               CHAR"TRIM(:EDI_855)"
      ,EDI_856                               CHAR"TRIM(:EDI_856)"
      ,EDI_846                               CHAR"TRIM(:EDI_846)"
      ,EDI_810                               CHAR"TRIM(:EDI_810)"
      ,EDI_832                               CHAR"TRIM(:EDI_832)"
      ,EDI_820                               CHAR"TRIM(:EDI_820)"
      ,EDI_861                               CHAR"TRIM(:EDI_861)"
      ,EDI_852                               CHAR"TRIM(:EDI_852)"
      ,EDI_DISTRIBUTION                      CHAR"TRIM(:EDI_DISTRIBUTION)"
      ,RTV_OPTION                            CHAR"TRIM(:RTV_OPTION)"
      ,RTV_FRT_PMT_METHOD                    CHAR"TRIM(:RTV_FRT_PMT_METHOD)"
      ,PERMANENT_RGA                         CHAR"TRIM(:PERMANENT_RGA)"
      ,DESTROY_ALLOW_AMT                     CHAR"TRIM(:DESTROY_ALLOW_AMT)"
      ,PAYMENT_FREQUENCY                     CHAR"TRIM(:PAYMENT_FREQUENCY)"
      ,MIN_RETURN_QTY                        CHAR"TRIM(:MIN_RETURN_QTY)"
      ,MIN_RETURN_AMOUNT                     CHAR"TRIM(:MIN_RETURN_AMOUNT)"
      ,DAMAGE_DESTROY_LIMIT                  CHAR"TRIM(:DAMAGE_DESTROY_LIMIT)"
      ,RTV_INSTRUCTIONS                      CHAR"TRIM(:RTV_INSTRUCTIONS)"
      ,ADDNL_RTV_INSTRUCTIONS                CHAR"TRIM(:ADDNL_RTV_INSTRUCTIONS)"
      ,RGA_MARKED_FLAG                       CHAR"TRIM(:RGA_MARKED_FLAG)"
      ,REMOVE_PRICE_STICKER_FLAG             CHAR"TRIM(:REMOVE_PRICE_STICKER_FLAG)"
      ,CONTACT_SUPPLIER_FOR_RGA              CHAR"TRIM(:CONTACT_SUPPLIER_FOR_RGA)"
      ,DESTROY_FLAG                          CHAR"TRIM(:DESTROY_FLAG)"
      ,SERIAL_REQUIRED_FLAG                  CHAR"TRIM(:SERIAL_REQUIRED_FLAG)"
      ,OBSOLETE_ITEM                         CHAR"TRIM(:OBSOLETE_ITEM)"
      ,OBSOLETE_ALLOW_PERNTG                 CHAR"TRIM(:OBSOLETE_ALLOW_PERNTG)"
      ,OBSOLETE_DAYS                         CHAR"TRIM(:OBSOLETE_DAYS)"
      ,RTV_RELATED_SITE                      CHAR"TRIM(:RTV_RELATED_SITE)"
      ,REQUEST_ID                            "FND_GLOBAL.CONC_REQUEST_ID"
      ,DFF_PROCESS_FLAG                      CONSTANT "N"
      ,SUPP_SITE_PROCESS_FLAG                CONSTANT "1"
      ,SUPP_SITE_ERROR_FLAG                  CONSTANT "N"
      ,CONT_PROCESS_FLAG                     CONSTANT "1"
      ,CONT_ERROR_FLAG                       CONSTANT "N"
      ,CREATED_BY                            "FND_GLOBAL.USER_ID"
      ,CREATION_DATE                         SYSDATE
      ,LAST_UPDATED_BY                       "FND_GLOBAL.USER_ID"
      ,LAST_UPDATE_DATE                      SYSDATE
)

-- +=====================================
-- | END OF SCRIPT
-- +=====================================
