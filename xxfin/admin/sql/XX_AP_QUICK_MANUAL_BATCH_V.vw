SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name             :  XX_AP_QUICK_MANUAL_BATCH_V                    |
-- | RICE ID          :  I1207                                         |
-- | Description      :  This View is used to create value set for     |
-- |                     submitting record print status for Quick      |
-- |                     payment                                       |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============    ============================|
-- |1.0       26-Feb-2014 Paddy Sanjeeevi  Defect 28602                |
-- |                                                                   |
-- +===================================================================+
CREATE OR REPLACE VIEW XX_AP_QUICK_MANUAL_BATCH_V
(PAYMENT_PROCESS_REQUEST_NAME, PAYMENT_INSTRUCTION_ID)
AS 
select distinct b.payment_process_request_name,b.payment_instruction_id
  from apps.iby_pay_instructions_all c, apps.iby_payments_all b, apps.iby_pay_service_requests a
 where b.payment_service_request_id=a.payment_service_request_id
   and c.payment_instruction_id=b.payment_instruction_id
   and a.creation_date>sysdate-7
   and a.created_by NOT IN (select user_id from apps.fnd_user   where user_name='SVC_ESP_FIN');
/
SHOW ERROR
