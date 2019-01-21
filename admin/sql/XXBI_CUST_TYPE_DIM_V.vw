-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE VIEW XXBI_CUST_TYPE_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_CUST_TYPE_DIM_V.vw                            |
-- | Description :  Customer Type  based on lkup                       |
-- |                   -XXBI_CUST_TYPE                                 |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       20-Mar-2009 Indra Varada       Initial draft version     |
-- |                                                                   | 
-- +===================================================================+
AS
SELECT lookup_code ID, Meaning Value
FROM fnd_lookup_values
WHERE lookup_type = 'XXBI_CUST_TYPE'
AND enabled_flag = 'Y'
UNION ALL
SELECT 'XX' ID, 'Not Available' Value
FROM DUAL

/
SHOW ERRORS;
EXIT;