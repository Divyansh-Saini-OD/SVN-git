SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AR_SHORT_PAY_WRAP_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

create or replace PACKAGE  BODY XX_AR_SHORT_PAY_WRAP_PKG
AS

-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                       WIPRO Technologies                               |
-- +========================================================================+
-- | Name : XX_AR_SHORT_PAY_WRAP_PKG                                        |
-- | RICE ID :  R0531                                                       |
-- | Description :This package is the executable of the wrapper program     | 
-- |              that used for submitting the OD: AR Productivity Short    |
-- |              Pay Queue Report with the desirable format of the         |
-- |              user, and the default format is EXCEL                     |
-- |                                                                        |
-- | Change Record:                                                         |
-- |===============                                                         |
-- |Version   Date              Author              Remarks                 |
-- |======   ==========     =============        =======================    |
-- |Draft 1A  07-FEB-09      Trisha Saxena         Initial version          |
-- |                                                                        |
-- +========================================================================+

--- +=======================================================================+
-- | Name :  XX_SHORT_PAY_WRAP_PROC                                         |
-- | Description : The procedure will submit the OD: AR Productivity Short  |
-- |               Pay Queue report in the specified format                 |
-- | Parameters : p_short_pay_date_low, p_short_pay_date_high               |  
-- |              ,p_date_task_closed_low, p_date_task_closed_high          |
-- |              ,p_drt_member, p_task_status, p_open_balance_low          |
-- |              ,p_open_balance_high, p_account_manager, p_dsm, p_rsd     |
-- | Returns :  x_err_buff,x_ret_code                                       |
-- +========================================================================+

PROCEDURE XX_SHORT_PAY_WRAP_PROC(x_err_buff                OUT VARCHAR2
                                 ,x_ret_code               OUT NUMBER
				 ,p_short_pay_date_low     IN VARCHAR2
				 ,p_short_pay_date_high    IN VARCHAR2
				 ,p_date_task_closed_low   IN VARCHAR2
				 ,p_date_task_closed_high  IN VARCHAR2
				 ,p_drt_member             IN VARCHAR2  
				 ,p_task_status            IN VARCHAR2
				 ,p_open_balance_low       IN VARCHAR2 
				 ,p_open_balance_high      IN VARCHAR2 
				 ,p_account_manager        IN VARCHAR2
				 ,p_dsm                    IN VARCHAR2
				 ,p_rsd                    IN VARCHAR2
				)
AS

  -- Local Variable declaration
   ln_request_id        NUMBER(15);
   lb_layout            BOOLEAN;
   lb_req_status        BOOLEAN;
   lb_print_option      BOOLEAN;
   lc_status_code       VARCHAR2(10);
   lc_phase             VARCHAR2(50);
   lc_status            VARCHAR2(50);
   lc_devphase          VARCHAR2(50);
   lc_devstatus         VARCHAR2(50);
   lc_message           VARCHAR2(50);

BEGIN

  lb_print_option := FND_REQUEST.SET_PRINT_OPTIONS(
                                                   printer           => 'XPTR'
                                                   ,copies           => 1
                                                  );

  
  lb_layout := fnd_request.add_layout(
                                      'XXFIN'
                                      ,'XXARSHORTPAY'
                                      ,'en'
                                      ,'US'
                                      ,'EXCEL'
                                     );

  ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                                              'XXFIN'
                                              ,'XXARSHORTPAY'
                                              ,NULL
                                              ,NULL
                                              ,FALSE
					      ,p_short_pay_date_low
             				      ,p_short_pay_date_high
				              ,p_date_task_closed_low
				              ,p_date_task_closed_high
				              ,p_drt_member           
				              ,p_task_status          
				              ,p_open_balance_low     
				              ,p_open_balance_high    
				              ,p_account_manager      
				              ,p_dsm                  
				              ,p_rsd                  
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

END XX_SHORT_PAY_WRAP_PROC;

END XX_AR_SHORT_PAY_WRAP_PKG;
/

SHO ERR;