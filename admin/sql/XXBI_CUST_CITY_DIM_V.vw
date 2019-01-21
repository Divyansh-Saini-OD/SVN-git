-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE VIEW XXBI_CUST_CITY_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_CUST_CITY_DIM_V.vw                            |
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
SELECT distinct cmv.city ID, cmv.city VALUE
FROM 
     apps.XXBI_ICUST_PROSP_V cmv
UNION ALL
SELECT 'XX' ID, 'Not Available' VALUE
FROM DUAL
/
SHOW ERRORS;
EXIT;