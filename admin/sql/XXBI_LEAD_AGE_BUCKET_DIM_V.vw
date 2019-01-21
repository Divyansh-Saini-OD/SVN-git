-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE VIEW XXBI_LEAD_AGE_BUCKET_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_LEAD_AGE_BUCKET_DIM_V.vw                      |
-- | Description :  Age Bucket Dimension based on lkup                 |
-- |                   -XXBI_LEAD_AGE_BUCKET                           |
-- |                                                                   |
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
WHERE lookup_type = 'XXBI_LEAD_AGE_BUCKET'
AND enabled_flag = 'Y'

/
SHOW ERRORS;
EXIT;