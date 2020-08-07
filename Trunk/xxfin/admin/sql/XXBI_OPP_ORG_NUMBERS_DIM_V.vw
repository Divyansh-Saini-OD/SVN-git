SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW  APPS.XXBI_OPP_ORG_NUMBERS_DIM_V 
AS
SELECT DISTINCT party_id id, org_number value  
from XXCRM.XXBI_SALES_OPPTY_FCT_MV mv,   -- Modified APPS Schema to XXCRM Schema Gokila
APPS.XXBI_GROUP_MBR_INFO_V H
WHERE 
  MV.resource_id = h.resource_id
  AND MV.role_id = h.role_id
  AND MV.group_id = h.group_id;

SHOW ERRORS;
EXIT;