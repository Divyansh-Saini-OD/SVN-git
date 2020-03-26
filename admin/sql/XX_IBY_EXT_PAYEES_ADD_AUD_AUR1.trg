CREATE OR REPLACE TRIGGER "APPS"."XX_IBY_EXT_PAYEES_ADD_AUD_AUR1" AFTER
  UPDATE ON "APPS"."IBY_EXTERNAL_PAYEES_ALL" FOR EACH ROW
  
  -- +===============================================================================+
    -- |                  Office Depot - Project Simplify                              |
    -- +===============================================================================+
    -- | Name        : XX_IBY_EXT_PAYEES_ADD_AUD_AUR1.trg                              |
    -- | Description : Trigger created per jira NAIT-103952                            |
    -- |Change Record:                                                                 |
    -- |===============                                                                |
    -- |Version   Date           Author                      Remarks                   |
    -- |========  =========== ================== ======================================|
    -- |DRAFT 1a  22-JAN-2020 Bhargavi Ankolekar Initial draft version                 |
    -- |                                                                               |
    -- +===============================================================================+
    
    DECLARE 
      CURSOR c1 IS
  SELECT assa1.vendor_site_id
  FROM ap_supplier_sites_all assa1
  WHERE assa1.VENDOR_SITE_ID = :new.supplier_site_id;
  
   r1 ap_supplier_sites_all.vendor_site_id%type;
  BEGIN
OPEN c1;
    loop
    FETCH c1 INTO r1;
   EXIT WHEN c1%notfound;
   
      insert into XX_IBY_EXT_PAYEES_ALL_AUD_V1(EXT_PAYEE_AUDIT_ID
,VERSIONS_OPERATION
,VERSION_TIMESTAMP
,SUPPLIER_SITE_ID
,LAST_UPDATE_DATE
,LAST_UPDATED_BY
,LAST_UPDATE_LOGIN
,CREATION_DATE
,CREATED_BY
,PAYMENT_FORMAT_CODE
,PAYMENT_REASON_CODE
,PAYMENT_REASON_COMMENTS
,REMIT_ADVICE_DELIVERY_METHOD
,REMIT_ADVICE_EMAIL
,REMIT_ADVICE_FAX)
values (XXFIN.XX_IBY_EXT_PAY_ALL_AUD_SEQ_V1.nextval,
'U',
systimestamp
,:NEW.SUPPLIER_SITE_ID
,:NEW.LAST_UPDATE_DATE
,:NEW.LAST_UPDATED_BY
,:NEW.LAST_UPDATE_LOGIN
,:NEW.CREATION_DATE
,:NEW.CREATED_BY
,:NEW.PAYMENT_FORMAT_CODE
,:NEW.PAYMENT_REASON_CODE
,:NEW.PAYMENT_REASON_COMMENTS
,:NEW.REMIT_ADVICE_DELIVERY_METHOD
,:NEW.REMIT_ADVICE_EMAIL
,:NEW.REMIT_ADVICE_FAX);

END LOOP;
  END;
