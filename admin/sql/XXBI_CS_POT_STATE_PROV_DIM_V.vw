-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW XXBI_CS_POT_STATE_PROV_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_CS_POT_STATE_PROV_DIM_V.vw                    |
-- | Description :  MV for Contact Strategy State/Province Dim         |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author           Remarks                   |
-- |=======   ==========    =============    ==========================|
-- |1.0       19-Mar-2009   Sreekanth Rao    Initial version           |
-- |                                                                   | 
-- +===================================================================+
AS
  SELECT 
    DISTINCT 
    nvl(state_province,'XX') id,
    nvl(state_province,'Not Available') value
  FROM 
    apps.XXBI_CS_POTENTIAL_V
/
SHOW ERRORS;
EXIT;