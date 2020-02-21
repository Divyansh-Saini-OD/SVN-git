create or replace TRIGGER "APPS"."XX_AP_TOLERANCES_TEMP_AUR1" AFTER
UPDATE
 ON  "AP"."AP_SUPPLIER_SITES_ALL#"  FOR EACH ROW
 

  -- +===============================================================================+
    -- |                  Office Depot - Project Simplify                              |
    -- +===============================================================================+
    -- | Name        : XX_AP_TOLERANCES_TEMP_AUR1.trg                              |
    -- | Description : Trigger created per jira NAIT-103952                            |
    -- |Change Record:                                                                 |
    -- |===============                                                                |
    -- |Version   Date           Author                      Remarks                   |
    -- |========  =========== ================== ======================================|
    -- |DRAFT 1a  04-FEB-2020 Bhargavi Ankolekar Initial draft version                 |
    -- |                                                                               |
    -- +===============================================================================+
  

DECLARE

l_count number;
l_tol_name  varchar(200);

cursor lcu_tol_name is 
select tolerance_name from ap_tolerance_templates
where tolerance_id= :NEW.tolerance_id;

  
BEGIN

open lcu_tol_name;
fetch lcu_tol_name into l_tol_name;
close lcu_tol_name;

                                                                          

SELECT COUNT(*) INTO L_COUNT FROM XX_AP_TOLERANCE_TEMP_AUD
WHERE 
 NVL(TOLERANCE_ID,0)=NVL(:NEW.TOLERANCE_ID,0)
 AND   LAST_UPDATED_BY =:new.LAST_UPDATED_BY
 AND   NVL(LAST_UPDATE_LOGIN,0)=NVL(:NEW.LAST_UPDATE_LOGIN,0)
AND   CREATED_BY=:new.CREATED_BY
  AND   NVL(SUPPLIER_SITE_ID,0)= NVL(:NEW.VENDOR_SITE_ID,0);
  
  IF l_count=0 THEN 
 
   IF trunc(:new.last_update_date) = trunc(sysdate) THEN

                 
INSERT INTO XX_AP_TOLERANCE_TEMP_AUD(TOLERANCE_AUDIT_ID
,VERSIONS_OPERATION
,VERSION_TIMESTAMP
,TOLERANCE_ID
,LAST_UPDATE_DATE
,LAST_UPDATED_BY
,LAST_UPDATE_LOGIN
,CREATION_DATE
,CREATED_BY
,TOLERANCE_NAME
,SUPPLIER_SITE_ID) 
VALUES (XX_AP_TOLERANCE_TEMP_SEQ.nextval
,'U'
,systimestamp
,:NEW.TOLERANCE_ID
,:NEW.LAST_UPDATE_DATE
,:NEW.LAST_UPDATED_BY
,:NEW.LAST_UPDATE_LOGIN
,:NEW.CREATION_DATE
,:NEW.CREATED_BY
,l_tol_name
,:NEW.vendor_site_id);

 end if;
 end if;
		
END;