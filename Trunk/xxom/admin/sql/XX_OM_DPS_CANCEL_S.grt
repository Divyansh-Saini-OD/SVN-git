SET VERIFY OFF;
SET SHOW OFF;
SET TAB OFF;
SET ECHO OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
 -- +================================================================+
 -- |                  Office Depot - Project Simplify                               
 -- |    Oracle NAIO/WIPRO/Office Depot/Consulting Organization          
 -- +================================================================+
 -- | Name  :    XX_OM_DPS_CANCEL_S.grt
 -- | Rice ID :          I1151  DPS cancel order                                                                   
 -- | Description: This file  gives grant to  the sequences                              
 -- |              required for DPS cancel order Interface.
 -- |              To be executed from XXOM schema                                                                            
 -- |                                                                                          
 -- |                                                                                         
 -- |Change Record:                                                                     
 -- |===============                                                              
 -- |Version   Date          Author              Remarks                            
 -- |=======   ==========  =============    =========================|
 -- |Draft 1A  27-May-2007   mohan          Initial draft Version |
 -- +================================================================+

GRANT ALL ON xx_om_dps_cancel_s TO apps
/
SHOW ERROR