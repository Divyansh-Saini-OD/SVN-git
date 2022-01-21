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
-- | Name :          XXFIN.XX_AP_RECEIPT_PO_TEMP_218                           |
-- | Description :   Script to drop XXFIN.XX_AP_RECEIPT_PO_TEMP_218  table     |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version      Date           Author                  Remarks                |
-- |=======    ==========     =============             ====================== |
-- | DRAFT 1.0 18-Aug-2016   Priyam Parmar          Initial draft version      |
-- | DRAFT 1.1 26-May-2018   Rakesh Reddy 			Defect#44853			   |	
-- +===========================================================================+

 


--+=====================================================================+
--+      DROP  TABLE        XX_AP_RECEIPT_PO_TEMP_218                +
--+=====================================================================+

--Drop table XX_AP_RECEIPT_PO_TEMP_218;
--Dropping table to create Global temporary table for Defect#44853
DROP TABLE XXFIN.XX_AP_RECEIPT_PO_TEMP_218;

show error