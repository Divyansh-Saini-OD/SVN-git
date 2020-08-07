 
 -- +==========================================================================+
 -- |                  Office Depot - Project Simplify                         |
 -- |                                                                          |
 -- +==========================================================================+
 -- | SQL Script to create Grants for the following tables                     |
 -- |                                                                          |
 -- |                      TABLE:  XXFIN.XX_AR_OPEN_CREDITS_ITM                |
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
 -- | V1.0     26-MAR-2010  Venkatesh B          Initial version               |
 -- |                                                                          |
 -- +==========================================================================+

 SET SHOW         OFF
 SET VERIFY       OFF
 SET ECHO         OFF
 SET TAB          OFF
 SET FEEDBACK     ON


 GRANT SELECT, INSERT, UPDATE, DELETE ON XXFIN.XX_AR_OPEN_CREDITS_ITM TO APPS;

 SHOW ERROR





