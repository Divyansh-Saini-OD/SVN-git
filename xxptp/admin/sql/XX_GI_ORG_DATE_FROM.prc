-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | SQL Script to update HR_ALL_ORGANIZATION_UNITS from_date column          |
-- |                                                                          |
-- | Script Name        : XX_GI_UPD_ORG_DATE_FROM                             |
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
   set attribute20 = date_from,
       date_from = to_date('28-DEC-2008','DD-MON-YYYY')
where organization_id in (select organization_id 
                            from mtl_parameters);

commit;
/
EXIT
