SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE VIEW XXBI_STATUS_CATEGORY_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_STATUS_CATEGORY_DIM_V.vw                      |
-- | Description :  Status Category Dim Based on lkup                  |
-- |                -XXBI_LEAD_STATUS_CATEGORY                         |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       10-Mar-2009 Indra Varada       Initial draft version     |
-- |                                                                   | 
-- +===================================================================+
AS
SELECT lookup_code ID, Meaning Value
FROM fnd_lookup_values
WHERE lookup_type = 'XXBI_LEAD_STATUS_CATEGORY'
AND enabled_flag = 'Y';

/
SHOW ERRORS;
EXIT;