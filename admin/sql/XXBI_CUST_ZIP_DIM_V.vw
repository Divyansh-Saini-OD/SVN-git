-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE VIEW XXBI_CUST_ZIP_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_CUST_ZIP_DIM_V.vw                             |
-- | Description :  Postal Code Dimension View                         |
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
SELECT distinct cmv.postal_code ID, cmv.postal_code VALUE
FROM 
     apps.XXBI_ICUST_PROSP_V cmv
UNION ALL
SELECT 'XX' ID, 'Not Available' VALUE
FROM DUAL
/
SHOW ERRORS;
EXIT;