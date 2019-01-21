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
-- | Name        :  DROP_XXBI_CS_POTENTIAL_CDH_MV.vw                   |
-- | Description :  MV DROP Script for Contact Strategy Potentials     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author           Remarks                   |
-- |=======   ==========    =============    ==========================|
-- |1.0       08-Apr-2009   indra varada    Initial version            |
-- |                                                                   | 
-- +===================================================================+

DROP MATERIALIZED VIEW XXBI_CS_POTENTIAL_CDH_MV

/
SHOW ERRORS;
EXIT;
