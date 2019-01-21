-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE VIEW XXBI_CUST_SITE_SEQ_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_CUST_SITE_SEQ_DIM_V.vw                        |
-- | Description :  Site Seq Dimension                                 |
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
SELECT distinct cmv.LEGACY_SITE_SEQ ID, cmv.SITE_ORIG_SYSTEM_REFERENCE VALUE
FROM 
    apps.XXBI_ICUST_PROSP_V cmv
UNION ALL
SELECT '-1' ID, 'Not Available' VALUE
FROM DUAL
/
SHOW ERRORS;
EXIT;