-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE VIEW XXBI_CUST_COUNTRY_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_CUST_COUNTRY_DIM_V.vw                         |
-- | Description :  Country Dimension View                             |
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
SELECT distinct cmv.country ID, cmv.country VALUE
FROM 
     XXBI_CUSTOMER_FCT_MV cmv,
     XXBI_SITE_CURR_ASSIGN_MV smv
WHERE cmv.party_site_id = smv.party_site_id
AND   smv.user_id = fnd_global.user_id
/
SHOW ERRORS;
EXIT;