REM================================================================================================
REM                                 Start Of Script
REM================================================================================================
SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     OFF
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |      Oracle NAIO/Office Depot/Consulting Organization                 |
-- +=======================================================================+
-- | Name             :XX_GI_TXN_RSN_NAME_V.sql                            |
-- | Description      :Custom View for Transaction Reason Names            |
-- |                   for E0352_MiscTransaction                           |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |Draft1a  04-May-2007 Remya Sasi         Initial Draft Version          |
-- |1.0      16-Aug-2007 Remya Sasi         Baselined                      |
-- +=======================================================================+


PROMPT
PROMPT Creating or Replacing View xx_gi_txn_rsn_name_v....
PROMPT

-- ===========================
-- -- Creating custom View
-- ===========================

CREATE OR REPLACE VIEW xx_gi_txn_rsn_name_v
(transaction_reason_id
,transaction_reason_name
,description
,display_sequence
,adjustment_sign
,legacy_transaction_type
,natural_account
)
AS
SELECT
    MTR.reason_id
   ,MTR.reason_name
   ,MTR.description
   ,MTR.attribute5
   ,MTR.attribute3
   ,MTR.attribute1
   ,MTR.attribute2
FROM
    mtl_transaction_reasons MTR
WHERE
     MTR.attribute3 IS NOT NULL
AND  MTR.attribute5 IS NOT NULL
AND  MTR.attribute1 IS NOT NULL 
AND  MTR.attribute3  IN ('+','-','+/-')
AND (MTR.disable_date IS NULL OR MTR.disable_date > sysdate)
ORDER BY MTR.attribute5;

/
SHOW ERRORS;

EXIT;
REM=================================================================================================
REM                                   End Of Script
REM=================================================================================================
