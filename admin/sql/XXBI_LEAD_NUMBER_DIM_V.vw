SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW XXBI_LEAD_NUMBER_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_LEAD_NUMBER_DIM_V.vw                          |
-- | Description :  View to create dimension object for lead number    |
-- |                filter                                             |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       21-Jul-2010 Lokesh Kumar       Initial draft version     |  
-- |                                                                   | 
-- +===================================================================+
AS
    SELECT DISTINCT sales_lead_id id, lead_number value
      from XXBI_SALES_LEADS_FCT_MV mv,
           XXBI_GROUP_MBR_INFO_V H
  WHERE 
    MV.resource_id = h.resource_id
    AND MV.role_id = h.role_id
    AND MV.group_id = h.group_id;
/
SHOW ERRORS;
EXIT;    
