SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- +=======================================================================+
-- | Name        : XX_CE_MRKTPLC_GRANT                                 |
-- | Description : I3123 CM Market Place Expansion Settlement and Reconciliation-Redesign                |
-- |Change History:                                                        |
-- |---------------                                                        |
-- | RICE ID : I3091                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- | 1.0     18-Jun-2018  M K Pramod Kumar.         Original                       |
-- +=======================================================================+
WHENEVER SQLERROR CONTINUE;

SET TERM OFF

SET TERM ON

GRANT SELECT ON XX_CE_MPL_SETTLEMENT_HDR TO ERP_SYSTEM_TABLE_SELECT_ROLE;
GRANT SELECT ON XX_CE_MPL_SETTLEMENT_DTL TO ERP_SYSTEM_TABLE_SELECT_ROLE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
