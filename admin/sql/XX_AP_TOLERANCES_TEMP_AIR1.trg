create or replace TRIGGER "APPS"."XX_AP_TOLERANCES_TEMP_AIR1" AFTER
INSERT
 ON  "AP"."AP_SUPPLIER_SITES_ALL#"  FOR EACH ROW


  -- +===============================================================================+
    -- |                  Office Depot - Project Simplify                              |
    -- +===============================================================================+
    -- | Name        : XX_AP_TOLERANCES_TEMP_AIR1.trg                              |
    -- | Description : Trigger created per jira NAIT-103952                            |
    -- |Change Record:                                                                 |
    -- |===============                                                                |
    -- |Version   Date           Author                      Remarks                   |
    -- |========  =========== ================== ======================================|
    -- |DRAFT 1a  04-FEB-2020 Bhargavi Ankolekar Initial draft version                 |
    -- |                                                                               |
    -- +===============================================================================+
  

  DECLARE
  
  l_tol_name  varchar(200);
  
  CURSOR lcu_template is
 select tolerance_name from ap_tolerance_templates
 where tolerance_id in (select tolerance_id from ap_supplier_sites_all where tolerance_id = :NEW.tolerance_id);

  
  BEGIN
  

   OPEN lcu_template;
   FETCH lcu_template INTO l_tol_name;
   CLOSE lcu_template;
   

INSERT INTO XX_AP_TOLERANCE_TEMP_AUD_V1(TOLERANCE_AUDIT_ID
,VERSIONS_OPERATION
,VERSION_TIMESTAMP
,TOLERANCE_ID
,LAST_UPDATE_DATE
,LAST_UPDATED_BY
,LAST_UPDATE_LOGIN
,CREATION_DATE
,CREATED_BY
,TOLERANCE_NAME
,VENDOR_SITE_ID)
VALUES (XXFIN.XX_AP_TOLERANCE_TEMP_SEQ_V1.nextval
,'I'
,systimestamp
,:NEW.TOLERANCE_ID
,:NEW.LAST_UPDATE_DATE
,:NEW.LAST_UPDATED_BY
,:NEW.LAST_UPDATE_LOGIN
,:NEW.CREATION_DATE
,:NEW.CREATED_BY
,l_tol_name
,OLD.VENDOR_SITE_ID);

END;
/