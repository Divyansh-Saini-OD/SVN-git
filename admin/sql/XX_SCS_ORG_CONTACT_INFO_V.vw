-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- +=======================================================================+
-- | Name             : XX_SCS_ORG_CONTACT_INFO_V                        |
-- | Description      : Named Account Territory Current Assignments        |
-- |                                                                       |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Change Record:                                                         |
-- |===============                                                        |
-- |Version   Date         Author             Remarks                      |
-- |=======   ===========  =================  =============================|
-- |DRAFT 1A  13-Sep-2007  Prasad          Initial draft version        |
-- |                                                                       |
-- +=======================================================================+

-- ---------------------------------------------------------------------
--      Create Custom View XX_SCS_ORG_CONTACT_INFO_V               --
-- ---------------------------------------------------------------------

  CREATE OR REPLACE FORCE VIEW "APPS"."XX_SCS_ORG_CONTACT_INFO_V" ("CONTACT_ID", "CONTACT_FULL_NAME", "FIRST_NAME", "LAST_NAME", "PHONE", "EMAIL_ADDRESS", "LEGCY_ID") AS 
  select 
con.org_contact_id contact_id,
substr(pcon.party_name,0,instr(pcon.party_name,'-')-1) Contact_Full_Name,
substr(substr(pcon.party_name,0,instr(pcon.party_name,'-')-1),0,instr(substr(pcon.party_name,0,instr(pcon.party_name,'-')-1),' ')-1) first_name,
substr(substr(pcon.party_name,0,instr(pcon.party_name,'-')-1),instr(substr(pcon.party_name,0,instr(pcon.party_name,'-')-1),' ')+1) last_name,
pcon.primary_phone_country_code || '-' || pcon.primary_phone_area_code || '-' || pcon.primary_phone_number Phone,
pcon.email_address
,pcon.orig_system_reference legcy_id
from 
hz_parties porg, 
hz_relationships rel,
hz_org_contacts con,
hz_parties pcon
where porg.party_id = rel.subject_id
AND   con.party_relationship_id = rel.relationship_id
AND  rel.relationship_code = 'CONTACT'
AND  rel.direction_code = 'C'
AND  subject_type = 'ORGANIZATION'
AND pcon.party_id = rel.party_id;
   
SHOW ERRORS;