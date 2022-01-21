SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET TERM ON

CREATE OR REPLACE
PACKAGE BODY XX_AR_DUNNING_TRANSMISSION_PKG
AS
-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                       WIPRO Technologies                               |
-- +========================================================================+
-- | Name : XX_AR_DUNNING_TRANSMISSION_PKG                                  |
-- | RICE ID :  R0530                                                       |
-- | Description :This package is the executable of the wrapper program     |
-- |              that used for submitting the OD: AR Dunning Transmission  |
-- |              report with the desirable format of the user, and the     |
-- |              default format is EXCEL and also does the necessary       |
-- |              validations and processing needed for the report R0530    |
-- | Change Record:                                                         |
-- |===============                                                         |
-- |Version   Date              Author              Remarks                 |
-- |======   ==========     =============        =======================    |
-- |Draft 1A  20-JAN-09      Jennifer Jegam         Initial version         |
-- |1.1       09-FEB-09      Ganesan JV             Changed for defect 11571|
-- |                                                                        |
-- +========================================================================+
-- +========================================================================+
-- | Name :  XX_AR_DUN_TRANS_PROC                                |
-- | Description : The procedure will submit the OD: AR Default             |
-- |               Collector report in the specified format                 |
-- | Parameters :  p_trans_date_from, p_trans_date_to, p_trans_method,      |
-- |               p_trans_status, p_collector_name                         |
-- | Returns :  x_err_buff,x_ret_code                                       |
-- +========================================================================+
PROCEDURE XX_AR_DUN_TRANS_PROC(
                               x_err_buff           OUT VARCHAR2
                               ,x_ret_code           OUT NUMBER
				               ,p_trans_date_from    IN VARCHAR2
				               ,p_trans_date_to      IN VARCHAR2
					           ,p_trans_method       IN VARCHAR2
					           ,p_trans_status       IN VARCHAR2
					           ,p_collector_name     IN VARCHAR2
                                  )
AS
  -- Local Variable declaration
   ln_request_id        NUMBER(15);
   lb_layout            BOOLEAN;
   lb_req_status        BOOLEAN;
   lc_status_code       VARCHAR2(10);
   lc_phase             VARCHAR2(50);
   lc_status            VARCHAR2(50);
   lc_devphase          VARCHAR2(50);
   lc_devstatus         VARCHAR2(50);
   lc_message           VARCHAR2(50);
BEGIN
  lb_layout := fnd_request.add_layout(
                                      'XXFIN'
                                     ,'XXARDUNTRANS'
                                     ,'en'
                                     ,'US'
                                     ,'EXCEL'
                                     );
  lb_layout := fnd_request.set_print_options('XPTR',   NULL,   '1',   TRUE,   'N');
  ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                                              'XXFIN'
                                             ,'XXARDUNTRANS'
                                             ,NULL
                                             ,NULL
                                             ,FALSE
					     ,p_trans_date_from    
				             ,p_trans_date_to     
					     --,p_trans_method       
					     ,p_trans_status      
					     ,p_collector_name     
                         ,p_trans_method            -- Added by Ganesan for defect 11571
                                              );
  COMMIT;
     lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST(
                                                      request_id  => ln_request_id
                                                     ,interval    => '2'
                                                     ,max_wait    => ''
                                                     ,phase       => lc_phase
                                                     ,status      => lc_status
                                                     ,dev_phase   => lc_devphase
                                                     ,dev_status  => lc_devstatus
                                                     ,message     => lc_message
                                                     );
  IF ln_request_id <> 0 THEN
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The report has been submitted and the request id is: '||ln_request_id);
            IF lc_devstatus ='E' THEN
              x_err_buff := 'PROGRAM COMPLETED IN ERROR';
              x_ret_code := 2;
            ELSIF lc_devstatus ='G' THEN
              x_err_buff := 'PROGRAM COMPLETED IN WARNING';
              x_ret_code := 1;
            ELSE
                  x_err_buff := 'PROGRAM COMPLETED NORMAL';
                  x_ret_code := 0;
            END IF;
  ELSE FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The report did not get submitted');
  END IF;
END XX_AR_DUN_TRANS_PROC;
END XX_AR_DUNNING_TRANSMISSION_PKG;
/
SHO ERR