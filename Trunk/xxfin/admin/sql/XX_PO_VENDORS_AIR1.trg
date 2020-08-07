
CREATE OR REPLACE TRIGGER apps.XX_PO_vendors_AIR1 AFTER
INSERT ON apps.po_vendors FOR EACH ROW

  -- +===============================================================================+
  -- |                  Office Depot - Project Simplify                              |
  -- |                Oracle NAIO Consulting Organization                            |
  -- +===============================================================================+
  -- | Name        : XX_PO_vendors_AIR1.trg                                          |
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
                                            , 'I' 
                                            , cast(:new.LAST_UPDATE_DATE as timestamp(6))
                                            , :new.VENDOR_ID
                                            , :new.LAST_UPDATE_DATE
                                            , :new.LAST_UPDATED_BY
                                            , :new.VENDOR_NAME
                                            , :new.VENDOR_NAME_ALT
                                            , :new.LAST_UPDATE_LOGIN
                                            , :new.CREATION_DATE
                                            , :new.CREATED_BY
                                            , :new.EMPLOYEE_ID
                                            , :new.VENDOR_TYPE_LOOKUP_CODE
                                            , :new.CUSTOMER_NUM
                                            , :new.ONE_TIME_FLAG
                                            , :new.PARENT_VENDOR_ID
                                            , :new.MIN_ORDER_AMOUNT
                                            , :new.SHIP_TO_LOCATION_ID
                                            , :new.BILL_TO_LOCATION_ID
                                            , :new.TERMS_ID
                                            , :new.SET_OF_BOOKS_ID
                                            , :new.CREDIT_STATUS_LOOKUP_CODE
                                            , :new.CREDIT_LIMIT
                                            , :new.ALWAYS_TAKE_DISC_FLAG
                                            , :new.PAY_GROUP_LOOKUP_CODE
                                            , :new.PAYMENT_PRIORITY
                                            , :new.INVOICE_CURRENCY_CODE
                                            , :new.PAYMENT_CURRENCY_CODE
                                            , :new.INVOICE_AMOUNT_LIMIT
                                            , :new.HOLD_ALL_PAYMENTS_FLAG
                                            , :new.HOLD_FUTURE_PAYMENTS_FLAG
                                            , :new.HOLD_REASON
                                            , :new.DISTRIBUTION_SET_ID
                                            , :new.ACCTS_PAY_CODE_COMBINATION_ID
                                            , :new.DISC_LOST_CODE_COMBINATION_ID
                                            , :new.DISC_TAKEN_CODE_COMBINATION_ID
                                            , :new.EXPENSE_CODE_COMBINATION_ID
                                            , :new.PREPAY_CODE_COMBINATION_ID
                                            , :new.START_DATE_ACTIVE
                                            , :new.END_DATE_ACTIVE
                                            , :new.PAYMENT_METHOD_LOOKUP_CODE
                                            , :new.STATE_REPORTABLE_FLAG
                                            , :new.FEDERAL_REPORTABLE_FLAG
                                            , :new.VAT_REGISTRATION_NUM
                                            , :new.TYPE_1099
                                            , :new.SEGMENT1
                                            , :new.NUM_1099
                                           );
                                              
                                                

END;
/
