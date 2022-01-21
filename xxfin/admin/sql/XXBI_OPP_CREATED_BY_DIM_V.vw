SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW XXBI_OPP_CREATED_BY_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_OPP_CREATED_BY_DIM_V.vw                       |
-- | Description :  View to create dimension object for created by     |
-- |                filter                                             |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       31-Aug-2010 Lokesh Kumar       Initial draft version     |
-- |2.0       24-Dec-2010 Gokila Tamilselvam Modified the schema name. |
-- |                                                                   |
-- +===================================================================+
AS
SELECT  b.oppty_created_by id , a.source_name value
FROM apps.jtf_rs_resource_extns a,
     (select distinct oppty_created_by
      from xxcrm.XXBI_SALES_OPPTY_FCT_MV MV/* Apps Schema replaced with xxcrm schema for XXBI_SALES_OPPTY_FCT_MV Gokila*/, APPS.XXBI_GROUP_MBR_INFO_V H
      WHERE MV.resource_id = h.resource_id
      AND MV.role_id = h.role_id
      AND MV.group_id = h.group_id) b
WHERE a.user_id = b.oppty_created_by;

/
SHOW ERRORS;
EXIT;