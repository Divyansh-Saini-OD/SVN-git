
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : XXPOCREATECONTEXT.sql                                                |
-- | Description      : SQL Script to create custom context for the VPD Poloicy              |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    | 
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1A   25-May-2007       Vikas Raina      Initial draft version                      |
-- |DRAFT 1B                                      Changes as per RCL Id NNNN                 |
-- |1.0                                           Baselined after testing                    |
-- +=========================================================================================+

SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

WHENEVER SQLERROR CONTINUE
-- ************************************************
-- Creating context for the VPD Policy 
-- ************************************************

CREATE CONTEXT xx_vpd_ctx USING XX_PO_RESTRICT_POTYPE_PKG;
/   

SHOW ERRORS

EXIT;

-- ************************************
-- *          END OF SCRIPT           *
-- ************************************
