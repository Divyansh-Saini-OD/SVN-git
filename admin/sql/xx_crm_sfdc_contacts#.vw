-- +========================================================================+
-- |                  Office Depot                                          |
-- +========================================================================+
-- | Name        : xx_crm_sfdc_contacts#.vw                                 |
-- | Description : Added new field in the existing xx_crm_sfdc_contacts#    |
-- |               table   ACCT_ORIG_SYS_REFERENCE                          |
-- |                                                                        |
-- |Change Record:                                                          |
-- |===============                                                         |
-- |Version   Date        Author           Remarks                          |
-- |=======  ===========  =============    =================================|
-- |1.0      20-Oct-2020  Divyansh Saini    Initial Version                 |
-- +========================================================================+
CREATE OR REPLACE EDITIONING VIEW xxcrm.xx_crm_sfdc_contacts# AS
SELECT ID ID,
  SFDC_ACCOUNT_ID SFDC_ACCOUNT_ID,
  SFDC_MESSAGE_VERSION SFDC_MESSAGE_VERSION,
  PARTY_ID PARTY_ID,
  CONTACT_ROLE CONTACT_ROLE,
  CONTACT_SALUTATION CONTACT_SALUTATION,
  CONTACT_FIRST_NAME CONTACT_FIRST_NAME,
  CONTACT_LAST_NAME CONTACT_LAST_NAME,
  CONTACT_JOB_TITLE CONTACT_JOB_TITLE,
  CONTACT_PHONE_NUMBER CONTACT_PHONE_NUMBER,
  CONTACT_FAX_NUMBER CONTACT_FAX_NUMBER,
  CONTACT_EMAIL_ADDR CONTACT_EMAIL_ADDR,
  CUST_ACCOUNT_ID CUST_ACCOUNT_ID,
  ORG_CONTACT_ID ORG_CONTACT_ID,
  PERSON_PARTY_OSR PERSON_PARTY_OSR,
  EMAIL_OSR EMAIL_OSR,
  PHONE_OSR PHONE_OSR,
  FAX_OSR FAX_OSR,
  CREATION_DATE CREATION_DATE,
  CREATED_BY CREATED_BY,
  LAST_UPDATE_DATE LAST_UPDATE_DATE,
  LAST_UPDATED_BY LAST_UPDATED_BY,
  LAST_UPDATE_LOGIN LAST_UPDATE_LOGIN,
  IMPORT_STATUS IMPORT_STATUS,
  IMPORT_ERROR IMPORT_ERROR,
  IMPORT_WARNINGS IMPORT_WARNINGS,
  IMPORT_ATTEMPT_COUNT IMPORT_ATTEMPT_COUNT,
  PRIMARY_CONTACT_FLAG PRIMARY_CONTACT_FLAG,
  ACCT_ORIG_SYS_REFERENCE
FROM "XXCRM"."XX_CRM_SFDC_CONTACTS";