CREATE OR REPLACE  VIEW XXOD_CRM_SR_STORE_V (NAME
                                              ,ORGANIZATION_ID
                                               ,REGION
                                               ,DISTRICT
                                               ,OPERATING_UNIT
                                               ,ATTRIBUTE1)
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name         : XXOD_CRM_SR_STORE_V                                |
-- | Rice ID      : CTR Reports                                        |
-- | Description  : This view is used to fetch the Warehouse details.  |
-- |Change Record :                                                    |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A  23-OCT-2007 Gokila T           Initial draft version     |
-- |                                                                   |
-- +===================================================================+
AS 
  SELECT HOU.NAME
         ,HOU.organization_id
         ,HL.region_2
         ,HL.region_1
         ,HOI.org_information3
         ,HOU.attribute1
   FROM mtl_parameters MP,
          hr_organization_units HOU,
          hr_organization_information HOI,
          hr_locations HL
   WHERE MP.organization_id                = HOU.organization_id
   AND   HOI.organization_id               = HOU.organization_id
   AND   HL.location_id                    = HOU.location_id
   AND  (HOU.date_to                       IS NULL OR HOU.date_to >= SYSDATE)
   AND  (HOI.org_information_context || '') = 'Accounting Information';
