SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | SQL Script to create the following object                                |
-- |             Grant    : xx_twe_iso_usetax_tmp                             |
-- |                        For R0504: Tax - AR Internal Sales Orders         |
-- |                        Use Tax Validation Report                         |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date              Author               Remarks               |
-- |=======      ==========        =============        ===================== |
-- | V1.0        09-Jan-09         Ganga Devi R         Initial version       |
-- |                                                                          |
-- +==========================================================================+

GRANT ALL ON xxfin.xx_twe_iso_usetax_tmp TO apps;

SHOW ERROR