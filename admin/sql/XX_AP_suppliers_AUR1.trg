
CREATE OR REPLACE TRIGGER apps.XX_AP_suppliers_AUR1 BEFORE
--UPDATE ON apps.po_vendors FOR EACH ROW
UPDATE ON apps.ap_suppliers FOR EACH ROW   --Commented/Added for R12 Upgrade retrofit

  -- +===============================================================================+
  -- |                  Office Depot - Project Simplify                              |
  -- |                Oracle NAIO Consulting Organization                            |
  -- +===============================================================================+
  -- | Name        : XX_AP_suppliers_AUR1.trg                                      |
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
  -- |1.0       10-DEC-2013 Veronica Mairembam E1375: Changed table po_vendors to    |
  -- |                                         ap_suppliers for R12 upgrade retrofit |
  -- +===============================================================================+


DECLARE 

-- PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN


 
        insert into xx_po_vendors_all_aud (  PO_VENDOR_AUDIT_ID
                                            ,VERSIONS_OPERATION
                                            ,VERSION_TIMESTAMP
                                            ,VENDOR_ID
                                            ,LAST_UPDATE_DATE
                                            ,LAST_UPDATED_BY
                                            ,VENDOR_NAME
                                            ,VENDOR_NAME_ALT
                                            ,LAST_UPDATE_LOGIN
                                            ,CREATION_DATE
                                            ,CREATED_BY
                                            ,EMPLOYEE_ID
                                            ,VENDOR_TYPE_LOOKUP_CODE
                                            ,CUSTOMER_NUM
                                            ,ONE_TIME_FLAG
                                            ,PARENT_VENDOR_ID
                                            ,MIN_ORDER_AMOUNT
                                            ,SHIP_TO_LOCATION_ID
                                            ,BILL_TO_LOCATION_ID
                                            ,TERMS_ID
                                            ,SET_OF_BOOKS_ID
                                            ,CREDIT_STATUS_LOOKUP_CODE
                                            ,CREDIT_LIMIT
                                            ,ALWAYS_TAKE_DISC_FLAG
                                            ,PAY_GROUP_LOOKUP_CODE
                                            ,PAYMENT_PRIORITY
                                            ,INVOICE_CURRENCY_CODE
                                            ,PAYMENT_CURRENCY_CODE
                                            ,INVOICE_AMOUNT_LIMIT
                                            ,HOLD_ALL_PAYMENTS_FLAG
                                            ,HOLD_FUTURE_PAYMENTS_FLAG
                                            ,HOLD_REASON
                                            ,DISTRIBUTION_SET_ID
                                            ,ACCTS_PAY_CODE_COMBINATION_ID
                                            ,DISC_LOST_CODE_COMBINATION_ID
                                            ,DISC_TAKEN_CODE_COMBINATION_ID
                                            ,EXPENSE_CODE_COMBINATION_ID
                                            ,PREPAY_CODE_COMBINATION_ID
                                            ,START_DATE_ACTIVE
                                            ,END_DATE_ACTIVE
                                            ,PAYMENT_METHOD_LOOKUP_CODE
                                            ,STATE_REPORTABLE_FLAG
                                            ,FEDERAL_REPORTABLE_FLAG
                                            ,VAT_REGISTRATION_NUM
                                            ,TYPE_1099
                                            ,SEGMENT1
                                            ,NUM_1099

                                           )
                                           VALUES
                                           ( XX_PO_VENDORS_AUD_SEQ.NEXTVAL
                                            , 'U' 
                                            , cast(:NEW.LAST_UPDATE_DATE as timestamp(6))
                                            , :NEW.VENDOR_ID
                                            , :NEW.LAST_UPDATE_DATE
                                            , :NEW.LAST_UPDATED_BY
                                            , :NEW.VENDOR_NAME
                                            , :NEW.VENDOR_NAME_ALT
                                            , :NEW.LAST_UPDATE_LOGIN
                                            , :NEW.CREATION_DATE
                                            , :NEW.CREATED_BY
                                            , :NEW.EMPLOYEE_ID
                                            , :NEW.VENDOR_TYPE_LOOKUP_CODE
                                            , :NEW.CUSTOMER_NUM
                                            , :NEW.ONE_TIME_FLAG
                                            , :NEW.PARENT_VENDOR_ID
                                            , :NEW.MIN_ORDER_AMOUNT
                                            , :NEW.SHIP_TO_LOCATION_ID
                                            , :NEW.BILL_TO_LOCATION_ID
                                            , :NEW.TERMS_ID
                                            , :NEW.SET_OF_BOOKS_ID
                                            , :NEW.CREDIT_STATUS_LOOKUP_CODE
                                            , :NEW.CREDIT_LIMIT
                                            , :NEW.ALWAYS_TAKE_DISC_FLAG
                                            , :NEW.PAY_GROUP_LOOKUP_CODE
                                            , :NEW.PAYMENT_PRIORITY
                                            , :NEW.INVOICE_CURRENCY_CODE
                                            , :NEW.PAYMENT_CURRENCY_CODE
                                            , :NEW.INVOICE_AMOUNT_LIMIT
                                            , :NEW.HOLD_ALL_PAYMENTS_FLAG
                                            , :NEW.HOLD_FUTURE_PAYMENTS_FLAG
                                            , :NEW.HOLD_REASON
                                            , :NEW.DISTRIBUTION_SET_ID
                                            , :NEW.ACCTS_PAY_CODE_COMBINATION_ID
                                            , :NEW.DISC_LOST_CODE_COMBINATION_ID
                                            , :NEW.DISC_TAKEN_CODE_COMBINATION_ID
                                            , :NEW.EXPENSE_CODE_COMBINATION_ID
                                            , :NEW.PREPAY_CODE_COMBINATION_ID
                                            , :NEW.START_DATE_ACTIVE
                                            , :NEW.END_DATE_ACTIVE
                                            , :NEW.PAYMENT_METHOD_LOOKUP_CODE
                                            , :NEW.STATE_REPORTABLE_FLAG
                                            , :NEW.FEDERAL_REPORTABLE_FLAG
                                            , :NEW.VAT_REGISTRATION_NUM
                                            , :NEW.TYPE_1099
                                            , :NEW.SEGMENT1
                                            , :NEW.NUM_1099
                                           );
                                              
                                                

END;
/
