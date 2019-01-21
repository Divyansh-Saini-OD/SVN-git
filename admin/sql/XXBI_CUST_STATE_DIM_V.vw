-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE VIEW XXBI_CUST_STATE_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_CUST_STATE_DIM_V.vw                           |
-- | Description :  State Dimension View                               |
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
SELECT distinct lk.lookup_code ID, lk.meaning VALUE
FROM fnd_lookup_values lk,
     XXBI_CUSTOMER_FCT_MV cmv,
     XXBI_SITE_CURR_ASSIGN_MV smv
WHERE cmv.state = lk.lookup_code
AND   cmv.party_site_id = smv.party_site_id
AND   smv.user_id = fnd_global.user_id
AND   lk.lookup_type = 'US_STATE'
AND   lk.enabled_flag = 'Y'
UNION ALL
SELECT 'XX' ID, 'Not Available' VALUE
FROM DUAL

/
SHOW ERRORS;
EXIT;