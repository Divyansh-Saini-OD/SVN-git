create or replace
TRIGGER apps.XX_AP_supplier_site_AUR1 AFTER
--UPDATE ON apps.po_vendor_sites_all FOR EACH ROW
UPDATE ON apps.ap_supplier_sites_all FOR EACH ROW     --Commented/Added for R12 Upgrade retrofit

  -- +===============================================================================+
  -- |                  Office Depot - Project Simplify                              |
  -- |                Oracle NAIO Consulting Organization                            |
  -- +===============================================================================+
  -- | Name        : XX_AP_supplier_site_AUR1.trg                                      |
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
  -- |1.0       10-DEC-2013 Veronica Mairembam E1375: Changed table po_vendor_sites_all to|
  -- |                                         ap_supplier_sites_all for R12 upgrade retrofit |
  ---|1.1       30-DEC-2013 Srinivas           Modified for the Defect#26972         |
  -- |1.2       16-JUN-2014 Avinash            For defect#30042
  -- +===============================================================================+


DECLARE 

-- PRAGMA AUTONOMOUS_TRANSACTION;

l_count number;                    --Added for Defect#26972
l_payment_method_code VARCHAR2(30);

CURSOR pay_method_cur IS
   SELECT ieppm.payment_method_code
     FROM iby_external_payees_all iepa,
          iby_ext_party_pmt_mthds ieppm
    WHERE iepa.ext_payee_id = ieppm.ext_pmt_party_id
      AND( (ieppm.inactive_date IS NULL)or (ieppm.inactive_date > sysdate))
      AND ieppm.primary_flag = 'Y'
      AND iepa.supplier_site_id= :new.VENDOR_SITE_ID;
      
CURSOR default_pay_method_cur IS
   SELECT payment_method_code 
     FROM  iby_payment_rules 
    WHERE application_id = 200;

BEGIN
                --Added for Defect#26972
 SELECT COUNT(*) INTO L_COUNT FROM XX_PO_VENDOR_SITES_ALL_AUD   WHERE  NVL(VENDOR_SITE_ID,0)=NVL(:NEW.VENDOR_SITE_ID,0)
                                         --AND   LAST_UPDATE_DATE= :new.LAST_UPDATE_DATE	
                                         AND   LAST_UPDATED_BY=:new.LAST_UPDATED_BY	
                                         AND   NVL(VENDOR_ID,0)=NVL(:NEW.VENDOR_ID,0)
                                         AND   NVL(VENDOR_SITE_CODE,'N')=NVL(:NEW.VENDOR_SITE_CODE,'N')
                                         AND   NVL(LAST_UPDATE_LOGIN,0)=NVL(:NEW.LAST_UPDATE_LOGIN,0)
                                        -- AND   CREATION_DATE=:new.CREATION_DATE	
                                         AND   CREATED_BY=:new.CREATED_BY	
                                         AND   NVL(PURCHASING_SITE_FLAG,'N')=NVL(:NEW.PURCHASING_SITE_FLAG,'N')
                                         AND   NVL(RFQ_ONLY_SITE_FLAG,'N')=NVL(:NEW.RFQ_ONLY_SITE_FLAG,'N')
                                         AND   NVL(PAY_SITE_FLAG,'N')=NVL(:NEW.PAY_SITE_FLAG,'N')
                                         AND   NVL(ATTENTION_AR_FLAG,'N')=NVL(:NEW.ATTENTION_AR_FLAG,'N')
                                         AND   NVL(ADDRESS_LINE1,'N')=NVL(:NEW.ADDRESS_LINE1,'N')
                                         AND   NVL(ADDRESS_LINE2,'N')=NVL(:NEW.ADDRESS_LINE2,'N')
                                         AND   NVL(ADDRESS_LINE3,'N')=NVL(:NEW.ADDRESS_LINE3,'N')
                                         AND   NVL(CITY,'N')=NVL(:NEW.CITY,'N')
                                         AND   NVL(STATE,'N')=NVL(:NEW.STATE,'N')
                                         AND   NVL(ZIP,'N')=NVL(:NEW.ZIP,'N')
                                         AND   NVL(COUNTRY,'N')=NVL(:NEW.COUNTRY,'N')
                                         AND   NVL(CUSTOMER_NUM,0)=NVL(:NEW.CUSTOMER_NUM,0)
                                         AND   NVL(SHIP_TO_LOCATION_ID,0)=NVL(:NEW.SHIP_TO_LOCATION_ID,0)
                                         AND   NVL(BILL_TO_LOCATION_ID,0)=NVL(:NEW.BILL_TO_LOCATION_ID,0)
                                         AND   NVL(SHIP_VIA_LOOKUP_CODE,'N')=NVL(:NEW.SHIP_VIA_LOOKUP_CODE,'N')
                                         AND   NVL(FREIGHT_TERMS_LOOKUP_CODE,'N')=NVL(:NEW.FREIGHT_TERMS_LOOKUP_CODE,'N')
                                         AND   NVL(INACTIVE_DATE,sysdate)=NVL(:NEW.INACTIVE_DATE,sysdate)
                                         AND   NVL(PAYMENT_METHOD_LOOKUP_CODE,'N')=NVL(:NEW.PAYMENT_METHOD_LOOKUP_CODE,'N')
                                         AND   NVL(TERMS_DATE_BASIS,'N')=NVL(:NEW.TERMS_DATE_BASIS,'N')
                                         AND   NVL(PAY_GROUP_LOOKUP_CODE,'N')=NVL(:NEW.PAY_GROUP_LOOKUP_CODE,'N')
                                         AND   NVL(PAYMENT_PRIORITY,0)=NVL(:NEW.PAYMENT_PRIORITY,0)
                                         AND   NVL(TERMS_ID,0)=NVL(:NEW.TERMS_ID,0)
                                         AND   NVL(INVOICE_AMOUNT_LIMIT,0)=NVL(:NEW.INVOICE_AMOUNT_LIMIT,0)
                                         AND   NVL(PAY_DATE_BASIS_LOOKUP_CODE,'N')=NVL(:NEW.PAY_DATE_BASIS_LOOKUP_CODE,'N')
                                         AND   NVL(ALWAYS_TAKE_DISC_FLAG,'N')=NVL(:NEW.ALWAYS_TAKE_DISC_FLAG,'N')
                                         AND   NVL(INVOICE_CURRENCY_CODE,'N')=NVL(:NEW.INVOICE_CURRENCY_CODE,'N')
                                         AND   NVL(PAYMENT_CURRENCY_CODE,'N')=NVL(:NEW.PAYMENT_CURRENCY_CODE,'N')
                                         AND   NVL(HOLD_ALL_PAYMENTS_FLAG,'N')=NVL(:NEW.HOLD_ALL_PAYMENTS_FLAG,'N')
                                         AND   NVL(HOLD_FUTURE_PAYMENTS_FLAG,'N')=NVL(:NEW.HOLD_FUTURE_PAYMENTS_FLAG,'N')
                                         AND   NVL(HOLD_REASON,'N')=NVL(:NEW.HOLD_REASON,'N')
                                         AND   NVL(HOLD_UNMATCHED_INVOICES_FLAG,'N')=NVL(:NEW.HOLD_UNMATCHED_INVOICES_FLAG,'N')
                                         AND   NVL(ATTRIBUTE7,'N')=NVL(:NEW.ATTRIBUTE7,'N')
                                         AND   NVL(ATTRIBUTE8,'N')=NVL(:NEW.ATTRIBUTE8,'N')
                                         AND   NVL(ATTRIBUTE9,'N')=NVL(:NEW.ATTRIBUTE9,'N')
                                         AND   NVL(ATTRIBUTE13,'N')=NVL(:NEW.ATTRIBUTE13,'N')
                                         AND   NVL(SUPPLIER_NOTIF_METHOD,'N')=NVL(:NEW.SUPPLIER_NOTIF_METHOD,'N')
                                         AND   NVL(EMAIL_ADDRESS,'N') =NVL(:NEW.EMAIL_ADDRESS,'N')
                                         AND   NVL(REMITTANCE_EMAIL,'N')=NVL(:NEW.REMITTANCE_EMAIL,'N');  
                                         
                                  
                                         
  IF L_COUNT=0 THEN                                                                                --Added for Defect#26972
   
   --For defect# 30042
   IF trunc(:new.last_update_date) = trunc(sysdate) THEN
   
    --For defect 30042
    l_payment_method_code := null;
    OPEN pay_method_cur;
    FETCH pay_method_cur INTO l_payment_method_code;
    CLOSE pay_method_cur;
    
    IF l_payment_method_code IS NULL THEN
       OPEN default_pay_method_cur;
       FETCH default_pay_method_cur INTO l_payment_method_code;
       CLOSE default_pay_method_cur;
    END IF;
    
    
    
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
                                            , systimestamp --cast(:new.LAST_UPDATE_DATE as timestamp(6))--sysdate --systimestamp  --Modified for the defect#26972
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
                                            , l_payment_method_code --:new.PAYMENT_METHOD_LOOKUP_CODE
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
                                            , to_char(:new.ACCTS_PAY_CODE_COMBINATION_ID)
                                            , :new.BANK_ACCOUNT_NAME
                                            , :new.BANK_ACCOUNT_NUM
                                            , :new.TAX_REPORTING_SITE_FLAG
                                            , :new.CREATE_DEBIT_MEMO_FLAG
                                          );
      END IF;                                          
  END IF;                                     
                                                
END;
/