SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- +=======================================================================+
-- | Name             : XXOD_SFO_USERS_V                                   |
-- | Description      : View that defines the users of Offline application |
-- |                                                                       |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Change Record:                                                         |
-- |===============                                                        |
-- |Version   Date         Author             Remarks                      |
-- |=======   ===========  =================  =============================|
-- |DRAFT 1A  03-Mar-2008  Sreekanth          Initial draft version        |
-- |                                                                       |
-- +=======================================================================+

-- ---------------------------------------------------------------------
--      Create Custom View XXOD_SFO_USERS_V                           --
-- ---------------------------------------------------------------------


CREATE OR REPLACE FORCE VIEW APPS.XXOD_SFO_USERS_V AS
  SELECT DISTINCT
  FNDU.user_name,
  JTFR.category,
  JTFR.source_number EmpID,
  source_name        FullName,
  source_first_name  Fname,
  source_middle_name MName,
  source_last_name   LName,
  source_job_title   JobTitle,
  source_email       EMail,
  source_phone       Phone,
  source_mgr_name    MGRName,
  FNDU.creation_date User_Creation_Date
from
  apps.FND_USER               FNDU,
  apps.JTF_RS_DEFRESOURCES_VL JTFR,
  apps.FND_USER_RESP_GROUPS   FNDRG,
  apps.FND_RESPONSIBILITY     FNDR,
  apps.FND_LOOKUP_VALUES      FNDL
where
     FNDU.user_id = JTFR.user_id
and JTFR.user_id = FNDRG.user_id 
and FNDRG.responsibility_id = FNDR.responsibility_id
and FNDR.responsibility_key = FNDL.lookup_code
and FNDL.lookup_type = 'XXOD_SALES_OFFLINE_RESPS'
and sysdate between trunc(nvl(FNDL.start_date_active,sysdate-1)) and trunc(nvl(FNDL.end_date_active,sysdate+1))
and sysdate between trunc(nvl(FNDR.start_date,sysdate-1)) and trunc(nvl(FNDR.end_date,sysdate+1))
and sysdate between trunc(nvl(FNDRG.start_date,sysdate-1)) and trunc(nvl(FNDRG.end_date,sysdate+1));
 
GRANT select on APPS.XXOD_SFO_USERS_V to XXCOURION;

SHOW ERRORS;