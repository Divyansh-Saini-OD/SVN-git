-- +==============================================================================+
-- |                                  Office Depot                                |
-- |                                                                              |
-- +==============================================================================+
-- | Script Name: XX_HR_PER_ALL_PEOPLE_F_V.vw                                     |
-- | View Name  : apps.xx_hr_per_all_people_f_v                                   |
-- | RICE #     : E3084 - EBS_Database_Roles                                      |
-- | Description: View created to hide senstive data in table PER_ALL_PEOPLE_F.   |
-- |                                                                              |
-- |                  Columns excluded: several,see below for columns displayed   |
-- |                                                                              |
-- |Change Record:                                                                |
-- |===============                                                               |
-- |Version  Date         Author                 Comments                         |
-- |=======  ===========  =====================  =================================|
-- |  1.0    16-MAR-2014  R.Aldridge             Initial version                  |
-- |  1.1    30-DEC-2015  Harvinder Rakhra       R12.2 Retrofit                   |
-- |                                                                              |
-- +==============================================================================+
CREATE OR REPLACE FORCE VIEW XX_HR_PER_ALL_PEOPLE_F_V
AS
SELECT PERSON_ID
      ,EFFECTIVE_START_DATE
      ,EFFECTIVE_END_DATE
      ,PERSON_TYPE_ID
      ,START_DATE
      ,EMAIL_ADDRESS
      ,EMPLOYEE_NUMBER
      ,LAST_NAME
      ,FIRST_NAME
      ,FULL_NAME
      ,TITLE
      ,VENDOR_ID
      ,LAST_UPDATE_DATE
      ,LAST_UPDATED_BY
      ,CREATED_BY
      ,CREATION_DATE
      ,ORIGINAL_DATE_OF_HIRE
  FROM PER_ALL_PEOPLE_F;
