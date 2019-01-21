CREATE OR REPLACE VIEW xxod_sr_district_v("DISTRICT","REGION") AS
/******************************************************************************
   NAME:       XXOD_SR_DISTRICT_V
   PURPOSE:    Created for the valueset XXOD_SR_DISTRICT
   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        16-Jun-2008 Senthil Kumar  Created for the defect# 7992
******************************************************************************/
  SELECT DISTINCT FFV.flex_value,
     FFV.attribute1
   FROM fnd_flex_values FFV,
     fnd_flex_value_sets FFVS,
     hr_organization_units HOU,
     hr_organization_information HOI
   WHERE HOI.organization_id(+) = HOU.organization_id
   AND FFV.flex_value = HOU.attribute2
   AND FFVS.flex_value_set_name = 'XX_GI_DISTRICT_VS'
    AND HOI.org_information3 = fnd_profile.VALUE('ORG_ID');