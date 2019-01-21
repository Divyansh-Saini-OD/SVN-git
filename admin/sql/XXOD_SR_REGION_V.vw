CREATE OR REPLACE VIEW xxod_sr_region_v("REGION") AS
/******************************************************************************
   NAME:       XXOD_SR_REGION_V
   PURPOSE:    Created for the valueset XXOD_SR_REGION
   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        16-Jun-2008 Senthil Kumar  Created for the defect# 7992
******************************************************************************/
SELECT DISTINCT ffv.attribute1
FROM fnd_flex_values ffv,
  fnd_flex_value_sets ffvs,
  hr_organization_units hou,
  hr_organization_information hoi
WHERE hoi.organization_id(+) = hou.organization_id
 AND ffv.flex_value = hou.attribute2
 AND ffvs.flex_value_set_id = ffv.flex_value_set_id
 AND ffvs.flex_value_set_name = 'XX_GI_DISTRICT_VS'
 AND hoi.org_information3 = fnd_profile.VALUE('ORG_ID');