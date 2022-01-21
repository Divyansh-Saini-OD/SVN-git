
CREATE OR REPLACE TRIGGER apps.XX_PO_vendor_site_AUR1 AFTER
UPDATE ON apps.po_vendor_sites_all FOR EACH ROW

  -- +===============================================================================+
  -- |                  Office Depot - Project Simplify                              |
  -- |                Oracle NAIO Consulting Organization                            |
  -- +===============================================================================+
  -- | Name        : XX_PO_vendor_site_AUR1.trg                                      |
  -- | Description : Trigger created per defect 13794,  Trigger will replace flash-  |
  -- |               back designed for E1375.                                        | 
  -- |                                                                               |
  -- |                                                                               |
  -- |                                                                               |
  -- |                                                                               |
  -- |Change Record:                                                                 |
  -- |===============                                                                |
  -- |Version   Date           Author                      Remarks                   |
  -- |========  =========== ================== ======================================|
  -- |DRAFT 1a  05-APR-2009 Peter Marco        Initial draft version                 |
  -- +===============================================================================+


DECLARE 

-- PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN


 
   insert into xx_po_vendor_sites_all_aud (  VENDOR_SITE_ID_AUD  
                                            ,VERSIONS_OPERATION  
                                            ,VERSION_TIMESTAMP  
                                            ,VENDOR_SITE_ID
                                            ,LAST_UPDATE_DATE
                                            ,LAST_UPDATED_BY
                                            ,VENDOR_ID
                                            ,VENDOR_SITE_CODE
                                            ,LAST_UPDATE_LOGIN
                                            ,CREATION_DATE
                                            ,CREATED_BY
                                            ,PURCHASING_SITE_FLAG
                                            ,RFQ_ONLY_SITE_FLAG
                                            ,PAY_SITE_FLAG
                                            ,ATTENTION_AR_FLAG
                                            ,ADDRESS_LINE1
                                            ,ADDRESS_LINE2
                                            ,ADDRESS_LINE3
                                            ,CITY
                                            ,STATE
                                            ,ZIP
                                            ,COUNTRY
                                            ,CUSTOMER_NUM
                                            ,SHIP_TO_LOCATION_ID
                                            ,BILL_TO_LOCATION_ID
                                            ,SHIP_VIA_LOOKUP_CODE
                                            ,FREIGHT_TERMS_LOOKUP_CODE
                                            ,INACTIVE_DATE
                                            ,PAYMENT_METHOD_LOOKUP_CODE
                                            ,TERMS_DATE_BASIS
                                            ,PAY_GROUP_LOOKUP_CODE
                                            ,PAYMENT_PRIORITY
                                            ,TERMS_ID
                                            ,INVOICE_AMOUNT_LIMIT
                                            ,PAY_DATE_BASIS_LOOKUP_CODE
                                            ,ALWAYS_TAKE_DISC_FLAG
                                            ,INVOICE_CURRENCY_CODE
                                            ,PAYMENT_CURRENCY_CODE
                                            ,HOLD_ALL_PAYMENTS_FLAG
                                            ,HOLD_FUTURE_PAYMENTS_FLAG
                                            ,HOLD_REASON
                                            ,HOLD_UNMATCHED_INVOICES_FLAG
                                            ,ATTRIBUTE7
                                            ,ATTRIBUTE8
                                            ,ATTRIBUTE9
                                            ,ATTRIBUTE13
                                            ,SUPPLIER_NOTIF_METHOD
                                            ,EMAIL_ADDRESS 
                                            ,REMITTANCE_EMAIL
                                            ,PRIMARY_PAY_SITE_FLAG
                                            ,AREA_CODE
                                            ,PHONE
                                            ,PROVINCE
                                            ,MATCH_OPTION
                                            ,ACCTS_PAY_CODE_COMBINATION_ID
                                            ,BANK_ACCOUNT_NAME
                                            ,BANK_ACCOUNT_NUM
                                            ,TAX_REPORTING_SITE_FLAG
                                            ,CREATE_DEBIT_MEMO_FLAG
                                           )
                                           VALUES
                                           ( XX_PO_VENDOR_SITE_AUDIT_SEQ.NEXTVAL
                                            , 'U' 
                                            , cast(:new.LAST_UPDATE_DATE as timestamp(6))--sysdate --systimestamp
                                            , :new.VENDOR_SITE_ID
                                            , :new.LAST_UPDATE_DATE
                                            , :new.LAST_UPDATED_BY
                                            , :new.VENDOR_ID
                                            , :new.VENDOR_SITE_CODE
                                            , :new.LAST_UPDATE_LOGIN
                                            , :new.CREATION_DATE
                                            , :new.CREATED_BY
                                            , :new.PURCHASING_SITE_FLAG
                                            , :new.RFQ_ONLY_SITE_FLAG
                                            , :new.PAY_SITE_FLAG
                                            , :new.ATTENTION_AR_FLAG
                                            , :new.ADDRESS_LINE1
                                            , :new.ADDRESS_LINE2
                                            , :new.ADDRESS_LINE3
                                            , :new.CITY
                                            , :new.STATE
                                            , :new.ZIP
                                            , :new.COUNTRY
                                            , :new.CUSTOMER_NUM
                                            , :new.SHIP_TO_LOCATION_ID
                                            , :new.BILL_TO_LOCATION_ID
                                            , :new.SHIP_VIA_LOOKUP_CODE
                                            , :new.FREIGHT_TERMS_LOOKUP_CODE
                                            , :new.INACTIVE_DATE
                                            , :new.PAYMENT_METHOD_LOOKUP_CODE
                                            , :new.TERMS_DATE_BASIS
                                            , :new.PAY_GROUP_LOOKUP_CODE
                                            , :new.PAYMENT_PRIORITY
                                            , :new.TERMS_ID
                                            , :new.INVOICE_AMOUNT_LIMIT
                                            , :new.PAY_DATE_BASIS_LOOKUP_CODE
                                            , :new.ALWAYS_TAKE_DISC_FLAG
                                            , :new.INVOICE_CURRENCY_CODE
                                            , :new.PAYMENT_CURRENCY_CODE
                                            , :new.HOLD_ALL_PAYMENTS_FLAG
                                            , :new.HOLD_FUTURE_PAYMENTS_FLAG
                                            , :new.HOLD_REASON
                                            , :new.HOLD_UNMATCHED_INVOICES_FLAG
                                            , :new.ATTRIBUTE7
                                            , :new.ATTRIBUTE8
                                            , :new.ATTRIBUTE9
                                            , :new.ATTRIBUTE13
                                            , :new.SUPPLIER_NOTIF_METHOD
                                            , :new.EMAIL_ADDRESS 
                                            , :new.REMITTANCE_EMAIL
                                            , :new.PRIMARY_PAY_SITE_FLAG
                                            , :new.AREA_CODE
                                            , :new.PHONE
                                            , :new.PROVINCE
                                            , :new.MATCH_OPTION
                                           ,  to_char(:new.ACCTS_PAY_CODE_COMBINATION_ID)
                                            , :new.BANK_ACCOUNT_NAME
                                            , :new.BANK_ACCOUNT_NUM
                                            , :new.TAX_REPORTING_SITE_FLAG
                                            , :new.CREATE_DEBIT_MEMO_FLAG
                                          );
                                              
                                                

END;
/
