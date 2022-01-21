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
-- | Grant  : xx_gl_high_volume_jrnl_control_grt                              |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | V1.0     06-Jan-2010  Sneha Anand           Initial version              |
-- |                                             Created for Defect 2851      |
-- +==========================================================================+

GRANT SELECT,UPDATE,INSERT ON  XXFIN.xx_gl_high_volume_jrnl_control TO APPS;

