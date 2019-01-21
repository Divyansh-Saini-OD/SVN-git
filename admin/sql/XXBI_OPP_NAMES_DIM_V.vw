SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW  APPS.XXBI_OPP_NAMES_DIM_V 
AS
SELECT DISTINCT opp_id id, opp_name value  
from xxcrm.XXBI_SALES_OPPTY_FCT_MV mv,  -- APPS schema modified with XXCRM schema Gokila
APPS.XXBI_GROUP_MBR_INFO_V H
WHERE 
  MV.resource_id = h.resource_id
  AND MV.role_id = h.role_id
  AND MV.group_id = h.group_id;
XBI_OPP_NAMES_DIM_V TO XXCRM;

SHOW ERRORS;
EXIT;