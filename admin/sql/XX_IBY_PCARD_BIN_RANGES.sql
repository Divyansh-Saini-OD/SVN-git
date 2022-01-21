SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- |  Backup Table Creation Script for bin ranges                             |
-- |             Table  : xx_iby_pcard_bin_ranges                             |
-- |                      For I1039,Settlement and Payment Processing         |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | V1.0     27-JAN-2009  Rama Krishna K       Initial version               |
-- |                                                                          |
-- +==========================================================================+

CREATE TABLE XXFIN.xx_iby_pcard_bin_ranges(
as     select * from iby_pcard_bin_range 
       where  1 <> 1;

SHOW ERROR;
