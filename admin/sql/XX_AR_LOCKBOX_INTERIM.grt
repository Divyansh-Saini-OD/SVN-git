 
 -- +==========================================================================+
 -- |                  Office Depot - Project Simplify                         |
 -- |                                                                          |
 -- +==========================================================================+
 -- | SQL Script to create Grants for the following tables                     |
 -- |                                                                          |
 -- |                      TABLE:  XXFIN.XX_AR_LOCKBOX_INTERIM                 |
 -- |                                                                          |
 -- |                                                                          |
 -- |                                                                          |
 -- |                                                                          |
 -- |                                                                          |
 -- |                                                                          |
 -- |Change Record:                                                            |
 -- |===============                                                           |
 -- |Version   Date         Author               Remarks                       |
 -- |=======   ==========   ================     ==============================|
 -- | V1.0     28-OCT-2011  P.Sankaran           Initial version               |
 -- |                                                                          |
 -- +==========================================================================+

 SET SHOW         OFF
 SET VERIFY       OFF
 SET ECHO         OFF
 SET TAB          OFF
 SET FEEDBACK     ON


 GRANT SELECT, INSERT, UPDATE, DELETE ON XXFIN.XX_AR_LOCKBOX_INTERIM TO APPS;
 
 GRANT SELECT ON XXFIN.XX_AR_LOCKBOX_INTERIM TO XX_FIN_SELECT_FINDEV_R;

 SHOW ERROR





