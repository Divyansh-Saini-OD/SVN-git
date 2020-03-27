CREATE OR REPLACE TRIGGER "APPS"."XX_AP_SUPPLIERS_ADD_AUR1" BEFORE
  UPDATE ON "AP"."AP_SUPPLIERS#" FOR EACH ROW
    -- +===============================================================================+
    -- |                  Office Depot - Project Simplify                              |
    -- +===============================================================================+
    -- | Name        : XX_AP_SUPPLIERS_ADD_AUR1.trg                                          |
    -- | Description : Trigger created per jira NAIT-103952          |
    -- |Change Record:                                                                 |
    -- |===============                                                                |
    -- |Version   Date           Author                      Remarks                   |
    -- |========  =========== ================== ======================================|
    -- |DRAFT 1a  22-JAN-2020 Bhargavi Ankolekar Initial draft version                 |
    -- |                                                                          |
    -- +===============================================================================+
    DECLARE 

	
    BEGIN
	
  INSERT
  INTO XX_PO_VENDOR_ADD_AUD_V1
    (
      PO_VENDOR_AUDIT_ID,
      VERSIONS_OPERATION,
      VERSION_TIMESTAMP,
      VENDOR_ID,
      LAST_UPDATE_DATE,
      LAST_UPDATED_BY,
      LAST_UPDATE_LOGIN,
      CREATION_DATE,
      CREATED_BY,
      TAX_REPORTING_NAME,
      TAX_VERIFICATION_DATE,
      ORGANIZATION_TYPE_LOOKUP_CODE,
	  INDIVIDUAL_1099
    )
    VALUES
    (
      XXFIN.XX_PO_VENDOR_ADD_AUD_SEQ_V1.NEXTVAL ,
      'U' ,
      CAST(:NEW.LAST_UPDATE_DATE AS TIMESTAMP(6)) ,
      :NEW.VENDOR_ID ,
      :NEW.LAST_UPDATE_DATE ,
      :NEW.LAST_UPDATED_BY ,
      :NEW.LAST_UPDATE_LOGIN ,
      :NEW.CREATION_DATE ,
      :NEW.CREATED_BY ,
      :NEW.TAX_REPORTING_NAME ,
      :NEW.TAX_VERIFICATION_DATE ,
      :NEW.organization_type_lookup_code,
	  :NEW.INDIVIDUAL_1099
    );
END;
/