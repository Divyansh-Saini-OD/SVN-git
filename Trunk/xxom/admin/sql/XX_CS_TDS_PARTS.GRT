SET VERIFY OFF;
SET SHOW OFF;
SET TAB OFF;
SET ECHO OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +==========================================================================+
-- |                  Office Depot - Project TDS PARTS                        |
-- +==========================================================================+
-- | Name             : XX_CS_TDS_PARTS.grt                                   |
-- | Rice ID          : E3017                                                 |
-- | Description      : This script creates the grant for the custom table    |
-- |                    XX_CS_TDS_PARTS              in the APPS schema       |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version Date        Author           Remarks                              |
-- |======= =========== ===============  =====================================|
-- |1.0     26-Jul-2011 Gaurav Agarwal   Initial Version                      |
-- |                                                                          |
-- +==========================================================================+

PROMPT
PROMPT Providing grant on custom table XX_CS_TDS_PARTS
PROMPT

GRANT ALL ON  XXOM.XX_CS_TDS_PARTS TO APPS;       

SHOW ERROR