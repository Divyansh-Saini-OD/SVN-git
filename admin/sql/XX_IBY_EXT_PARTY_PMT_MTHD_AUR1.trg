CREATE OR REPLACE TRIGGER apps.XX_IBY_EXT_PARTY_PMT_MTHD_AUR1 AFTER
UPDATE ON apps.iby_ext_party_pmt_mthds FOR EACH ROW WHEN (new.primary_flag = 'Y' and ((new.inactive_date IS NULL) or (new.inactive_date > sysdate)))

  -- +===============================================================================+
  -- |                  Office Depot - Project Simplify                              |
  -- |                Oracle NAIO Consulting Organization                            |
  -- +===============================================================================+
  -- | Name        : XX_IBY_EXT_PARTY_PMT_MTHDS_AIR1.trg                             |
  -- | Description : Trigger created per defect 30042 to populate payment method in  |
  -- |               audit table                                                     |
  -- |                                                                               |
  -- |Change Record:                                                                 |
  -- |===============                                                                |
  -- |Version   Date           Author                      Remarks                   |
  -- |========  =========== ================== ======================================|
  -- |1.0	19-MAY-2014 Avinash Baddam     Initial version                 	     |
  -- +===============================================================================+


DECLARE 

-- PRAGMA AUTONOMOUS_TRANSACTION;
   CURSOR c1 IS
     	SELECT assa.vendor_site_id,assa.last_update_date,
	       assa.last_updated_by,assa.vendor_id,assa.vendor_site_code,assa.last_update_login,
	       assa.creation_date,assa.created_by,assa.purchasing_site_flag,
	       assa.rfq_only_site_flag,assa.pay_site_flag,assa.attention_ar_flag,assa.address_line1,
	       assa.address_line2,assa.address_line3,assa.city,assa.state,assa.zip,assa.country,
	       assa.customer_num,assa.ship_to_location_id,assa.bill_to_location_id,assa.ship_via_lookup_code,
	       assa.freight_terms_lookup_code,assa.inactive_date,assa.payment_method_lookup_code,
	       assa.terms_date_basis,assa.pay_group_lookup_code,assa.payment_priority,
	       assa.terms_id,assa.invoice_amount_limit,assa.pay_date_basis_lookup_code,
	       assa.always_take_disc_flag,assa.invoice_currency_code,assa.payment_currency_code,
	       assa.hold_all_payments_flag,assa.hold_future_payments_flag,
	       assa.hold_reason,assa.hold_unmatched_invoices_flag,assa.attribute7,
	       assa.attribute8,assa.attribute9,assa.attribute13,assa.supplier_notif_method,
	       assa.email_address,assa.remittance_email,assa.primary_pay_site_flag,
	       assa.area_code,assa.phone,assa.province,assa.match_option,assa.accts_pay_code_combination_id,
	       assa.bank_account_name,assa.bank_account_num,assa.tax_reporting_site_flag,
	       assa.create_debit_memo_flag
      	  FROM ap_supplier_sites_all assa,
               iby_external_payees_all iepa
       	 WHERE assa.pay_site_flag = 'Y'
           AND assa.vendor_site_id = iepa.supplier_site_id
   	   AND iepa.ext_payee_id = :new.ext_pmt_party_id;
   r1 	c1%rowtype;   	   

BEGIN
   --Check its coming from vendor sites
   OPEN c1;
   FETCH c1 INTO r1;
   CLOSE c1;
   
   IF r1.vendor_site_id IS NOT NULL THEN   
   
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
	                                            , r1.VENDOR_SITE_ID
	                                            , :new.LAST_UPDATE_DATE
	                                            , :new.LAST_UPDATED_BY
	                                            , r1.VENDOR_ID
	                                            , r1.VENDOR_SITE_CODE
	                                            , r1.LAST_UPDATE_LOGIN
	                                            , r1.CREATION_DATE
	                                            , r1.CREATED_BY
	                                            , r1.PURCHASING_SITE_FLAG
	                                            , r1.RFQ_ONLY_SITE_FLAG
	                                            , r1.PAY_SITE_FLAG
	                                            , r1.ATTENTION_AR_FLAG
	                                            , r1.ADDRESS_LINE1
	                                            , r1.ADDRESS_LINE2
	                                            , r1.ADDRESS_LINE3
	                                            , r1.CITY
	                                            , r1.STATE
	                                            , r1.ZIP
	                                            , r1.COUNTRY
	                                            , r1.CUSTOMER_NUM
	                                            , r1.SHIP_TO_LOCATION_ID
	                                            , r1.BILL_TO_LOCATION_ID
	                                            , r1.SHIP_VIA_LOOKUP_CODE
	                                            , r1.FREIGHT_TERMS_LOOKUP_CODE
	                                            , r1.INACTIVE_DATE
	                                            , :new.payment_method_code
	                                            , r1.TERMS_DATE_BASIS
	                                            , r1.PAY_GROUP_LOOKUP_CODE
	                                            , r1.PAYMENT_PRIORITY
	                                            , r1.TERMS_ID
	                                            , r1.INVOICE_AMOUNT_LIMIT
	                                            , r1.PAY_DATE_BASIS_LOOKUP_CODE
	                                            , r1.ALWAYS_TAKE_DISC_FLAG
	                                            , r1.INVOICE_CURRENCY_CODE
	                                            , r1.PAYMENT_CURRENCY_CODE
	                                            , r1.HOLD_ALL_PAYMENTS_FLAG
	                                            , r1.HOLD_FUTURE_PAYMENTS_FLAG
	                                            , r1.HOLD_REASON
	                                            , r1.HOLD_UNMATCHED_INVOICES_FLAG
	                                            , r1.ATTRIBUTE7
	                                            , r1.ATTRIBUTE8
	                                            , r1.ATTRIBUTE9
	                                            , r1.ATTRIBUTE13
	                                            , r1.SUPPLIER_NOTIF_METHOD
	                                            , r1.EMAIL_ADDRESS 
	                                            , r1.REMITTANCE_EMAIL
	                                            , r1.PRIMARY_PAY_SITE_FLAG
	                                            , r1.AREA_CODE
	                                            , r1.PHONE
	                                            , r1.PROVINCE
	                                            , r1.MATCH_OPTION
	                                            , to_char(r1.ACCTS_PAY_CODE_COMBINATION_ID)
	                                            , r1.BANK_ACCOUNT_NAME
	                                            , r1.BANK_ACCOUNT_NUM
	                                            , r1.TAX_REPORTING_SITE_FLAG
	                                            , r1.CREATE_DEBIT_MEMO_FLAG
                                          );

   END IF;   
END;
/
