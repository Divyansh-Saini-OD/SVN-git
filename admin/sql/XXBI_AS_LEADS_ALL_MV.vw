-- $HeadURL: https://svn.na.odcorp.net/od/crm/trunk/xxcrm/admin/sql/XXBI_AS_LEADS_ALL_MV.vw $

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE MATERIALIZED VIEW "APPS"."XXBI_AS_LEADS_ALL_MV"
  BUILD IMMEDIATE
  USING INDEX 
  REFRESH FAST
  WITH ROWID 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_AS_LEADS_ALL_MV.vw                            |
-- | Description :  MV sales leads all                                 |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author           Remarks                   |
-- |=======   ==========    =============    ==========================|
-- |1.0       31-Mar-2010   Luis Mazuera     Initial version           |
-- |                                                                   | 
-- +===================================================================+
AS
SELECT ROWID ROW_ID, LDS.* FROM OSM.AS_LEADS_ALL LDS;

----------------------------------------------------------
-- Grant to XXCRM
----------------------------------------------------------
GRANT ALL ON APPS.XXBI_AS_LEADS_ALL_MV TO XXCRM;

SHOW ERRORS;
EXIT;