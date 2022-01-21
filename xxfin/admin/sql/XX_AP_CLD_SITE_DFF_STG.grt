 
 -- +==========================================================================+
 -- |                  Office Depot - Project Simplify                         |
 -- |                                                                          |
 -- +==========================================================================+
 -- | SQL Script to create Grants for the following tables                     |
 -- |                                                                          |
 -- |                      TABLE:  XXFIN.XX_AP_CLD_SITE_DFF_STG                |
 -- |                                                                          |
 -- |Change Record:                                                            |
 -- |===============                                                           |
 -- |Version   Date         Author               Remarks                       |
 -- |=======   ==========   ================     ==============================|
 -- | 1.0      06-JUN-2019  Dinesh Nagapuri      Initial draft version  	   |
 -- |                                                                          |
 -- +==========================================================================+

 SET SHOW         OFF
 SET VERIFY       OFF
 SET ECHO         OFF
 SET TAB          OFF
 SET FEEDBACK     ON


 GRANT SELECT, INSERT, UPDATE, DELETE ON XXFIN.XX_AP_CLD_SITE_DFF_STG TO APPS;

 SHOW ERROR
