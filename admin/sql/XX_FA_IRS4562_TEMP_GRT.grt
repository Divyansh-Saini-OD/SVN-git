SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | Table Script to create the following object                              |
-- | Grant  : XXFIN.XX_FA_IRS4562_TEMP                                        |
-- | For R1048 , OD: FA IRS4562 Form report                                   |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | V1.0     22-Sep-2009  Priyanka Nagesh       Initial version              |
-- |                                                                          |
-- +==========================================================================+

GRANT SELECT,UPDATE,INSERT ON  XXFIN.XX_FA_IRS4562_TEMP   TO APPS;

SHOW ERROR;