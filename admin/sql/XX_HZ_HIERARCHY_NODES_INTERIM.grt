 
 -- +==========================================================================+
 -- |                  Office Depot - Project Simplify                         |
 -- |                                                                          |
 -- +==========================================================================+
 -- | SQL Script to create Grants for the following tables                     |
 -- |                                                                          |
 -- |                      TABLE:  XXFIN.XX_HZ_HIERARCHY_NODES_INTERIM         |
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
 -- | V1.0     10-NOV-2011  P.Sankaran           Initial version               |
 -- |                                                                          |
 -- | V2.0     31-AUG-2016  Arun G               added grant option            |
 -- +==========================================================================+

 SET SHOW         OFF
 SET VERIFY       OFF
 SET ECHO         OFF
 SET TAB          OFF
 SET FEEDBACK     ON


 GRANT SELECT, INSERT, UPDATE, DELETE ON XXFIN.XX_HZ_HIERARCHY_NODES_INTERIM TO APPS WITH GRANT OPTION;
 
 GRANT SELECT ON XXFIN.XX_HZ_HIERARCHY_NODES_INTERIM TO XX_FIN_SELECT_FINDEV_R;

 GRANT SELECT, INSERT, UPDATE, DELETE ON XXFIN.XX_HZ_HIERARCHY_NODES_INTERIM# TO APPS WITH GRANT OPTION;
 
 SHOW ERROR





