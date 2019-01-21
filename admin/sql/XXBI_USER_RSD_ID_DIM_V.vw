SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW APPS.XXBI_USER_RSD_ID_DIM_V AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_USER_RSD_ID_DIM_V.VW                           |
-- | Description :  RSD Id Dimension for  Dashboard    |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  ============      ==========`================|
-- |1.0       03/04/2010  Prasad Devar      Initial Version            |
-- |                                                                   | 
-- +===================================================================+
SELECT rsd_user_id id ,rsd_user_id value
FROM   APPS.XXBI_group_mbr_info_mv;
SHOW ERRORS;
EXIT;
