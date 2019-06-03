-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                             Office Depot                          |
-- +===================================================================+
-- | Name  : APPS.XX_MTL_CATEGORIES_B_BU_TRG                           |
-- | Description: CUSTOM TRIGGER BEFORE INSERT OF  COLUMNS             |
-- |             SEGMENT1 TO SEGMENT5  IN TABLE          	       |
-- |            MTL_CATEGORIES_B FOR MERCH RECLASSIFICATION            |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0      15-MAR-2013  SARITHA M        INITAL CODE                 |
-- +===================================================================+
 CREATE OR REPLACE TRIGGER APPS.XX_MTL_CATEGORIES_B_BI_TRG
 BEFORE INSERT
     ON APPS.MTL_CATEGORIES_B
 REFERENCING NEW AS NEW OLD AS OLD FOR EACH ROW

 DECLARE              

 BEGIN
 
   IF :new.segment1 IS NULL and :new.segment2 IS NULL and :new.segment3 IS NULL and :new.segment4 IS NULL and :new.segment5 IS NULL
   THEN
   raise_application_error( -20001, 'All the segment values can not be NULL');

   END IF;
 END;  