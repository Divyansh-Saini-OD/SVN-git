SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE VIEW XXBI_AGE_BUCKETS_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_AGE_BUCKETS_DIM_V.vw                          |
-- | Description :  Age Bucket Dimension based on lkup-XXBI_AGE_BUCKETS|
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       03-Apr-2007 Indra Varada       Initial draft version     |
-- |                                                                   | 
-- +===================================================================+
AS
SELECT lookup_code ID, Meaning Value
FROM fnd_lookup_values
WHERE lookup_type = 'XXBI_AGE_BUCKETS'
AND enabled_flag = 'Y';

/
SHOW ERRORS;
EXIT;