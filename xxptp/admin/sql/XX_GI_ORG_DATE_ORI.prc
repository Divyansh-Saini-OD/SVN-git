-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | SQL Script to update HR_ALL_ORGANIZATION_UNITS from_date column with     |
-- |    original date                                                         |
-- |                                                                          |
-- | Script Name        : XX_GI_ORG_DATE_FROM_ORI                             |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date          Author               Remarks                      |
-- |=======   ==========    ================     =============================|
-- | V1.0     05-feb-2009   Rama Dwibhashyam     Initial version              |
-- |                                                                          |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

update hr_all_organization_units
   set date_from = to_date(attribute20,'DD-MON-RRRR'),
       attribute20 = null
where organization_id in (select organization_id 
                            from mtl_parameters);

commit;
/
EXIT