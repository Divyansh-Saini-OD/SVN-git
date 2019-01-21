-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- |                                                                          |
-- | SQL Script to create trigger on the follwing object                      |
-- |             Table       : AS_ACCESSES_ALL_ALL                            |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | V1.0     04-JUN-2010  Anitha Devarajulu    Initial version               |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

CREATE OR REPLACE TRIGGER XX_AS_ACCESSES_ALL_ALL_BIR1
BEFORE INSERT ON AS_ACCESSES_ALL_ALL
FOR EACH ROW
DECLARE
  lc_error_message VARCHAR2(4000);
BEGIN
    IF :NEW.sales_group_id IS NULL THEN
      lc_error_message := 'User name try to Create Error Record:'|| fnd_global.user_name;
      lc_error_message := lc_error_message ||' by conc program id '|| fnd_global.conc_program_id;
      lc_error_message := lc_error_message ||' by conc request id '|| fnd_global.conc_request_id;
      lc_error_message := lc_error_message ||' in Responsibility '|| fnd_global.resp_name;
      XX_COM_ERROR_LOG_PUB.log_error_crm(
                     p_application_name        => 'Test'
                    ,p_program_type            => 'Trigger'
                    ,p_program_name            => 'XX_AS_ACCESSES_ALL_ALL_BIR1'
                    ,p_program_id              => fnd_global.conc_program_id
                    ,p_module_name             => 'XXCRM'
                    ,p_error_location          => 'XX_AS_ACCESSES_ALL_ALL_BIR1'
                    ,p_error_message_code      => 'TRG'
                    ,p_error_message           => lc_error_message
                    ,p_error_status            => 'ERROR'
                    ,p_notify_flag             => 'N'
                    ,p_error_message_severity  =>'MAJOR'
                    );
      Raise_application_error(-20100,lc_error_message);
    END IF;
END AS_ACCESSES_ALL_ALL_TRG;

/
SHOW ERROR;