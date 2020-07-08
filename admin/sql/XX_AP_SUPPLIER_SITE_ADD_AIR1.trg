CREATE OR REPLACE TRIGGER "APPS"."XX_AP_SUPPLIER_SITE_ADD_AIR1" AFTER
  INSERT ON "AP"."AP_SUPPLIER_SITES_ALL#" FOR EACH ROW 


  -- +===============================================================================+
  -- |                  Office Depot - Project Simplify                              |
  -- +===============================================================================+
  -- | Name        : XX_AP_SUPPLIERS_ADD_AIR1.trg                                          |
  -- | Description : Trigger created per jira NAIT-103952  			     |
  -- |Change Record:                                                                 |
  -- |===============                                                                |
  -- |Version   Date           Author                      Remarks                   |
  -- |========  =========== ================== ======================================|
  -- |DRAFT 1a  22-JAN-2020 Bhargavi Ankolekar Initial draft version                 |
  -- |                                            	                             |
  -- +===============================================================================+


  DECLARE 
  BEGIN
  INSERT
  INTO XX_PO_VDSITES_ADD_AUD_V1
    (
      VENDOR_SITE_ID_AUD,
      VERSIONS_OPERATION,
      VERSION_TIMESTAMP,
      VENDOR_SITE_ID,
      LAST_UPDATE_DATE,
      LAST_UPDATED_BY,
      VENDOR_ID,
      LAST_UPDATE_LOGIN,
      CREATION_DATE,
      CREATED_BY,
      ATTRIBUTE4,
      ATTRIBUTE5,
      ATTRIBUTE8,
      ORG_ID,
      TELEX,
      VENDOR_SITE_CODE_ALT,
	  LANGUAGE
    )
    VALUES
    (
      XXFIN.XX_PO_VDSITES_ADD_AUD_SEQ_V1.NEXTVAL ,
      'I' ,
      systimestamp,--CAST(:NEW.LAST_UPDATE_DATE AS TIMESTAMP(6))  --- changing cast(:new.LAST_UPDATE_DATE as timestamp(6)) to systimestamp as per the jira #133497
      :new.VENDOR_SITE_ID ,
      :new.LAST_UPDATE_DATE ,
      :new.LAST_UPDATED_BY ,
      :new.VENDOR_ID ,
      :new.LAST_UPDATE_LOGIN ,
      :new.CREATION_DATE ,
      :new.CREATED_BY ,
      :new.ATTRIBUTE4,
      :new.ATTRIBUTE5,
      :new.ATTRIBUTE8,
      :new.ORG_ID,
      :new.TELEX,
      :new.VENDOR_SITE_CODE_ALT,
	  :new.LANGUAGE
    );
END;
/