-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE VIEW XXBI_CUST_WCW_RANGE_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_CUST_WCW_RANGE_DIM_V.vw                       |
-- | Description :  WCW Bucket Dimension based on lkup                 |
-- |                   -XXBI_CUST_WCW_RANGE                            |
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
SELECT lookup_code ID, meaning Value, 
to_number(substr(tag, 1, instr(tag, '-')-1)) low_val,  
to_number(substr(tag, instr(tag, '-')+1)) high_val
FROM fnd_lookup_values
WHERE lookup_type = 'XXBI_CUST_WCW_RANGE'
AND enabled_flag = 'Y'
UNION ALL
SELECT 'XX' ID, 'Not Available', -1, -1 VALUE
FROM DUAL;

SHOW ERRORS;
EXIT;