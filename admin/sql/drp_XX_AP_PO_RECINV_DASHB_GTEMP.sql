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
-- | Name :          XXFIN.XX_AP_PO_RECINV_DASHB_GTEMP                         |
-- | Description :   Script to drop XXFIN.XX_AP_PO_RECINV_DASHB_GTEMP  table   |
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
--+      DROP  TABLE        XX_AP_PO_RECINV_DASHB_GTEMP                 +
--+=====================================================================+

--Dropping table to create Global temporary table for defect#44853
Drop table XX_AP_PO_RECINV_DASHB_GTEMP;




show error

/