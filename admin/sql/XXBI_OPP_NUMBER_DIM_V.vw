SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW XXBI_OPP_NUMBER_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_OPP_NUMBER_DIM_V.vw                           |
-- | Description :  View to create dimension object for opp. number    |
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
    SELECT DISTINCT opp_id id, opp_number value
      from xxcrm.XXBI_SALES_OPPTY_FCT_MV mv,     -- Modified APPS schema to XXCRM Schema Gokila
           XXBI_GROUP_MBR_INFO_V H
  WHERE 
    MV.resource_id = h.resource_id
    AND MV.role_id = h.role_id
    AND MV.group_id = h.group_id;
/
SHOW ERRORS;
EXIT;    
