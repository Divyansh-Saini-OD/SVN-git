----------------------------------------------------
-- CR 490 Script xx_ar_tax_line_update_alt.tbl will 
-- be  used to alter table
----------------------------------------------------

ALTER TABLE xxfin.xx_ar_tax_line_update 
ADD ( SHIP_TO_LOC       VARCHAR2(150)
     ,SHIP_FROM_LOC     VARCHAR2(150)
     ,PICK_UP_STORE     VARCHAR2(60)
     ,ERROR_MESSAGE     VARCHAR2(250));
