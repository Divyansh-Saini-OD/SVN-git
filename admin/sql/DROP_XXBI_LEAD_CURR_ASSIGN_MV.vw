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
-- | Name        :  DROP_XXBI_LEAD_CURR_ASSIGN_MV.vw                   |
-- | Description :  DROP for Lead Current Assignments MV               |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author           Remarks                   |
-- |=======   ==========    =============    ==========================|
-- |1.0       16-Mar-2009   indra Varada    Initial version            |
-- |                                                                   | 
-- +===================================================================+


DROP MATERIALIZED VIEW APPS.XXBI_LEAD_CURR_ASSIGN_MV;

SHOW ERRORS;
EXIT;