-- $Id:  $
-- $Rev: $
-- $HeadURL:  $
-- $Author:  $
-- $Date: $

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

  CREATE OR REPLACE FORCE VIEW XXBI_LAST_SITE_CONTACT_V
 ("PARTY_ID", "PARTY_NAME", "PARTY_SITE_ID", "CONTACT_POINT_ID", "C_LAST_DT", "PERSON_FIRST_NAME", "PERSON_LAST_NAME", "PHONE_COUNTRY_CODE", "PHONE_AREA_CODE", "PHONE_NUMBER", "PHONE_EXTENSION", "RAW_PHONE_NUMBER","FORMATED_PHONE","JOB_TITLE","mcp_row_id","ct_row_id") 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_LAST_SITE_CONTACT_V.vw                                |
-- | Description : Last Updated Contact      |
-- |                                                              |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       10-Mar-2010 Prasad Devar       Initial draft version     |
-- |                                                                   | 
-- +===================================================================+
AS
  select ct.party_id, ct.party_name, mcp.party_site_id, mcp.contact_point_id, ct.c_last_dt, ct.person_first_name, ct.person_last_name, ct.phone_country_code, ct.phone_area_code, ct.phone_number, ct.phone_extension, ct.raw_phone_number,ct.phone_country_code||''||'('||ct.phone_area_code||')'|| ct.phone_number ||' '||ct.phone_extension as FORMATED_PHONE ,ct.job_title,mcp.rowid mcp_row_id,ct.rowid ct_row_id  from
xxcrm.XXBI_LAST_SITE_CPOINT_MV mcp,
xxcrm.xxbi_contacts_mv_tbl  ct
where ct.contact_point_id=mcp.contact_point_id
and ct.relationship_id=mcp.relationship_id;
/
SHOW ERRORS;
EXIT;