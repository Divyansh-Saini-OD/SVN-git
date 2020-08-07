SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
create or replace PACKAGE BODY XX_AR_FIN_VPS_BKUP_BURST 
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                          	  |
  -- +============================================================================================+
  -- |  Name:  XX_AR_FIN_VPS_BKUP_BURST                                                      	  |
  -- |                                                                                            |
  -- |  Description:  This package is used to burst backup email.        	                      |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         21-JUNE-2017  Thejaswini Rajula    Initial version                             |
  -- +============================================================================================+
  
g_conc_request_id                       NUMBER:= fnd_global.conc_request_id;
g_total_records                         NUMBER;


FUNCTION Bkup_Burst
RETURN BOOLEAN
IS
v_request_id         NUMBER;
v_sub_req            NUMBER := 0;
l_req_return_status  BOOLEAN;
lc_phase             VARCHAR2(50);
lc_status            VARCHAR2(50);
lc_dev_phase         VARCHAR2(50);
lc_dev_status        VARCHAR2(50);
lc_message           VARCHAR2(50);
BEGIN

SELECT fnd_global.conc_request_id 
  INTO v_request_id
  FROM apps.fnd_user, v$instance
  WHERE user_id = fnd_global.user_id;

fnd_file.put_line (fnd_file.LOG,'v_request_id =' || v_request_id);

 v_sub_req :=  fnd_request.submit_request(application => 'XDO',
                                                             program => 'XDOBURSTREP',
                                                       description =>  '',
                                                       start_time => to_char(sysdate + 1/1440,'DD-MON-YYYY HH24:MI:SS'),
                                                        argument1 =>    'N' ,
                                                        argument2 => v_request_id,
                                                        argument3 => 'Yes'
                                                      );
              IF v_sub_req <= 0
              THEN
                   fnd_file.put_line(fnd_file.log,'Failed to submit Bursting XML Publisher Request');
                   NULL;
                   RETURN (FALSE);
              ELSE
                COMMIT;
                      fnd_file.put_line(fnd_file.log,'XDOBURSTREP :'||lc_status);
                      fnd_file.put_line(fnd_file.log,'XDOBURSTREP :'||lc_phase);
                  RETURN (TRUE);    
              END IF;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line (fnd_file.LOG, 'ORA exception occurred while ' || 'executing the XDO Program - ' || SQLERRM );
RETURN (FALSE);
END Bkup_Burst;
END XX_AR_FIN_VPS_BKUP_BURST;
/
SHOW ERRORS;