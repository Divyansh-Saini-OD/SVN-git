SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

-- +=======================================================================+
-- |                  Office Depot - Project Simplify                      |
-- |                       WIPRO Technologies                              |
-- +=======================================================================+
-- | Name        : UPDATE_TRANSLATION_BURST_PATH.sql                       |
-- |                                                                       |
-- | Description : Script to update the rtf path in translations           |
-- |                                                                       |
-- |Change Record:                                                         |
-- |===============                                                        |
-- |Version   Date         Author               Remarks                    |
-- |=======  ===========   ==================   =============================|
-- |1.0      09-SEP-2016   Suresh Naragam       Initial version(One time Fix)|
-- +=========================================================================+

UPDATE xx_fin_translatevalues
SET target_value1 = 'java/od/oracle/apps/xxfin/ar/statements',
last_update_date = sysdate
WHERE translate_id = (select translate_id from xx_fin_translatedefinition
WHERE translation_name   = 'XX_EBL_COMMON_TRANS')
AND    sysdate                 BETWEEN start_date_active AND nvl(end_date_active,sysdate+1)
AND    enabled_flag       = 'Y'
AND    source_value1      = 'BPATH';
/
COMMIT;
/