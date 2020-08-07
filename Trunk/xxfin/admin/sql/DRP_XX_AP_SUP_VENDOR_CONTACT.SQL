SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- +===========================================================================+
-- | Name :          XX_AP_SUP_VENDOR_CONTACT                                  |
-- | Description :   Script to drop XX_AP_SUP_VENDOR_CONTACT  table            |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version      Date           Author                  Remarks                |
-- |=======    ==========     =============             ====================== |
-- | DRAFT 1.0 28-Mar-2017   Sunil Kalal           Initial draft version       |
-- +===========================================================================+

 


--+=====================================================================+
--+      DROP  TABLE        XX_AP_SUP_VENDOR_CONTACT                    +
--+=====================================================================+

Drop table XX_AP_SUP_VENDOR_CONTACT;

show error