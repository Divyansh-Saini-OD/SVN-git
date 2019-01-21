-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW XXBI_CS_POT_PCODE_DIM_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_CS_POT_PCODE_DIM_V.vw                         |
-- | Description :  View for Contact Strategy Postal Code Dimension    |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author           Remarks                   |
-- |=======   ==========    =============    ==========================|
-- |1.0       15-Mar-2009   Sreekanth Rao    Initial version           |
-- |                                                                   | 
-- +===================================================================+
AS
  SELECT DISTINCT
    nvl(SUBSTR(postal_code,1,5),   'XX') id,
    nvl(SUBSTR(postal_code,1,5),   'Not Available') value
  FROM 
    apps.XXBI_CS_POTENTIAL_V
/
SHOW ERRORS;
EXIT;