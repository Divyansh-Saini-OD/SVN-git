SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW XXBI_OPP_LINE_COMPTTR_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_OPP_LINE_COMPTTR_DIM_V.vw                     |
-- | Description :  View to create dimension object for lead line      |
-- |                competitor                                         |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       30-Aug-2010 Luis Mazuera       Initial draft version     |
-- |2.0       24-Dec-2010 Gokila Tamilselvam Modified the Schema.      |
-- |                                                                   |
-- +===================================================================+
AS
SELECT DISTINCT mv.competitor_party_id id,
  mv.competitor_party_name value
from xxcrm.XXBI_SALES_OPPTY_FCT_MV mv,  -- APPS schema modified with XXCRM Schema Gokila
APPS.XXBI_GROUP_MBR_INFO_V H
WHERE
  MV.resource_id = h.resource_id
  AND MV.role_id = h.role_id
  AND MV.group_id = h.group_id
  AND mv.competitor_party_id <> -1
union all
select -1, 'None' from dual;
/
SHOW ERRORS;
EXIT;
