SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET ECHO        OFF

-- +===================================================================+
-- |                        Office Depot Inc.                          |
-- +===================================================================+
-- | Synonym Name:  AR_CASH_RECEIPTS_V.VW                              |
-- | Rice Id     :                                                     |
-- |                                                                   |
-- | Change Record:                                                    |
-- | ===============                                                   |
-- | Version   Date         Author             Remarks                 |
-- | =======   ===========  =================  ========================|
-- |   1.0     19-FEB-2016  Manikant Kasu      Initial Version         |
-- +===================================================================+

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT 'CREATE OR REPLACE VIEW XXAPPS_HISTORY_COMBO.AR_CASH_RECEIPTS_V....'
PROMPT   

CREATE OR REPLACE VIEW XXAPPS_HISTORY_COMBO.AR_CASH_RECEIPTS_V 
AS 
SELECT * FROM APPS.AR_CASH_RECEIPTS_V
UNION ALL
SELECT * FROM XXAPPS_HISTORY_QUERY.AR_CASH_RECEIPTS_V
;

PROMPT
PROMPT 'Exiting....'
PROMPT

SET FEEDBACK ON

SHOW ERRORS;
EXIT;

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
