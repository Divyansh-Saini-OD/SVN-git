-- +===========================================================================+
-- |                              Office Depot                                 |
-- |                                                                           |
-- +===========================================================================+
-- | Name         : XX_DEFECT27042_DEL.sql                                     |
-- | Rice Id      : DEFECT 27042                                               | 
-- | Description  :                                                            |  
-- | Purpose      : To remove personalization on 'Cridit Limit' and            |
-- |                'Order Credit Limit’ for Responsibilities -                |
-- |                 OD (US) Credit Analyst and OD (CA) Credit Analyst         |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version    Date          Author               Remarks                      | 
-- |=======    ==========    =================    =============================+
-- |1.0        20-Dec-2013   Darshini G           Initial Version              |
-- |                                                                           |
-- +===========================================================================+
SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT Deleting Document XX_DEFECT27042_DEL.sql
PROMPT

begin
jdr_utils.deletedocument('/oracle/apps/ar/hz/components/account/customer/webui/customizations/responsibility/51728/HzPuiCurrRatesViewRN');
jdr_utils.deletedocument('/oracle/apps/ar/hz/components/account/customer/webui/customizations/responsibility/51729/HzPuiCurrRatesViewRN');
commit;
end;
/

SHOW ERR
