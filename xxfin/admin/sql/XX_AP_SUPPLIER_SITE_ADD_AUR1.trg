create or replace TRIGGER "APPS"."XX_AP_SUPPLIER_SITE_ADD_AUR1" AFTER
UPDATE
 ON  "AP"."AP_SUPPLIER_SITES_ALL#"  FOR EACH ROW   

 -- +===============================================================================+
  -- |                  Office Depot - Project Simplify                              |
  -- +===============================================================================+
  -- | Name        : XX_AP_SUPPLIER_SITE_ADD_AUR1.trg                                          |
  -- | Description : Trigger created per jira NAIT-103952  			     |
  -- |Change Record:                                                                 |
  -- |===============                                                                |
  -- |Version   Date           Author                      Remarks                   |
  -- |========  =========== ================== ======================================|
  -- |DRAFT 1a  22-JAN-2020 Bhargavi Ankolekar Initial draft version                 |
  -- |                                            	                             |
  -- +===============================================================================+


DECLARE

L_COUNT number; 

BEGIN

                                                                        

SELECT COUNT(*) INTO L_COUNT FROM XX_PO_VDSITES_ADD_AUD_V1
WHERE 
 NVL(VENDOR_SITE_ID,0)=NVL(:NEW.VENDOR_SITE_ID,0)
 AND   LAST_UPDATED_BY =:new.LAST_UPDATED_BY
 AND   NVL(VENDOR_ID,0)= NVL(:NEW.VENDOR_ID,0)
 AND   NVL(LAST_UPDATE_LOGIN,0)=NVL(:NEW.LAST_UPDATE_LOGIN,0)
AND   CREATED_BY=:new.CREATED_BY
 AND   NVL(ATTRIBUTE4,'N')= NVL(:NEW.ATTRIBUTE4,'N')
  AND   NVL(ATTRIBUTE5,'N')= NVL(:NEW.ATTRIBUTE5,'N')
   AND   NVL(ATTRIBUTE8,'N')= NVL(:NEW.ATTRIBUTE8,'N')
    AND   NVL(ORG_ID,0)= NVL(:NEW.ORG_ID,0)
AND   NVL(VENDOR_SITE_CODE_ALT,'N')=NVL(:NEW.VENDOR_SITE_CODE_ALT,'N')
AND   NVL(TELEX,'N')=NVL(:NEW.TELEX,'N')
AND NVL(LANGUAGE,'N')=NVL(:NEW.LANGUAGE,'N');
 
   IF L_COUNT=0 THEN  
   IF trunc(:new.last_update_date) = trunc(sysdate) THEN

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
      'U' ,
      systimestamp,--CAST(:NEW.LAST_UPDATE_DATE AS TIMESTAMP(6))  --- changing cast(:new.LAST_UPDATE_DATE as timestamp(6)) to systimestamp as per the jira #133497
      :old.VENDOR_SITE_ID ,
      :new.LAST_UPDATE_DATE ,
      :new.LAST_UPDATED_BY ,
      :old.VENDOR_ID ,
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
 
 END IF;
 END IF;

END;
/
  