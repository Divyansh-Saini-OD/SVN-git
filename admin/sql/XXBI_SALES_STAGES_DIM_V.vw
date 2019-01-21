SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW XXBI_SALES_STAGES_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_SALES_STAGES_DIM_V.vw                     |
-- | Description :  View to create dimension object for lead line      |
-- |                competitor                                         |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       02-Sep-2010 Luis Mazuera       Initial draft version     |  
-- |                                                                   | 
-- +===================================================================+
AS
select sales_stage_id id, name value from AS_SALES_STAGES_ALL_vl where enabled_flag = 'Y';
/
SHOW ERRORS;
EXIT; 