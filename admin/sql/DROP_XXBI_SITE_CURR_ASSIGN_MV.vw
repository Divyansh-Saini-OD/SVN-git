-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  DROP_XXBI_SITE_CURR_ASSIGN_MV.vw                   |
-- | Description :  MV for Party Site Current Assignments              |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author           Remarks                   |
-- |=======   ==========    =============    ==========================|
-- |1.0       16-Mar-2009   Indra Varada     Initial version           |
-- |                                                                   | 
-- +===================================================================+

DROP MATERIALIZED VIEW APPS.XXBI_SITE_CURR_ASSIGN_MV;

SHOW ERRORS;
EXIT;