SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF 
SET FEEDBACK OFF
SET TERM ON  

PROMPT Creating Package Body XX_AR_INC_CONS_BILL_TERMS_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE 
PACKAGE BODY XX_AR_INC_CONS_BILL_TERMS_PKG
AS
 -- +==================================================================+
 -- |                  Office Depot - Project Simplify                 |
 -- |                       WIPRO Technologies                         |
 -- +==================================================================+
 -- | Name :    XX_AR_INC_CONS_BILL_TERMS_PKG                          |
 -- | RICE :    E0269(Applicable only in Dev/Sit ENV)                  |
 -- | Description : This package is used to submit the Program         |
 -- |              'OD: AR Increment Consolidated Billing Terms        |
 -- |               Wrapper Program'                                   |
 -- |Change Record:                                                    |
 -- |===============                                                   |
 -- |Version   Date         Author               Remarks               |
 -- |=======   ==========   =============        ======================|
 -- |1.0       22-FEB-10    DHANYA V             Initial version       |
 -- |1.1       03-FEB-12    Ray Strauss          Do NOT execute in PROD| 
 -- |                                      Do NOT assign responsibility|
 -- |1.2       14-May-12    Jay Gupta            defect 18353, Need to |
 -- |                                        remove cond to run in Prod| 
 -- +==================================================================+
 -- +==================================================================+
 -- | Name        : AR_INCREMENT_PROGRAM                               |
 -- | Description : The procedure is used to  submit the Program       |
 -- |             'OD: AR Increment Consolidated Billing Terms         |
 -- |              from the wrapper                                    |
 -- |                                                                  |
 -- | Parameters  :   p_start_date IN VARCHAR2                         |
 -- |                ,p_end_date   IN VARCHAR2                         |
 -- |     Returns :   x_error_buff                                     |
 -- |                ,x_ret_code                                       |
 -- +==================================================================+

  PROCEDURE AR_INCREMENT_PROGRAM ( x_error_buff  OUT   VARCHAR2
                                  ,x_ret_code    OUT   NUMBER
                                  ,p_start_date  IN    VARCHAR2
                                  ,p_end_date    IN    VARCHAR2
                                  )

  IS
     ld_present_date         DATE;
     ln_req_id               NUMBER;
     ln_number               NUMBER;
     ln_loop_number          NUMBER;
     lc_start_number         NUMBER; 
     ld_start_date           DATE;
     ld_end_date             DATE;
     lc_conc_phase           VARCHAR2(1000);
     lc_conc_status          VARCHAR2(1000);
     lc_dev_phase            VARCHAR2(1000);
     lc_req_data             VARCHAR2(1000);
     lc_dev_status           VARCHAR2(1000);
     lc_conc_message         VARCHAR2(1000);
     lc_object_type          xx_com_error_log.object_type%TYPE   := 'CONSOLIDATED BILLING WRAPPER';
     ln_object_id            xx_com_error_log.object_id%TYPE     := 0;
     lc_error_msg            xx_com_error_log.error_message%TYPE := NULL;
     lc_error_loc            VARCHAR2(2000)                      := NULL;
     lb_wait                 BOOLEAN;
     ln_print_option         BOOLEAN;
     ln_instance_name        VARCHAR2(9)		DEFAULT NULL;
BEGIN

     lc_req_data := FND_CONC_GLOBAL.REQUEST_DATA;

     IF (NVL(lc_req_data,'FIRST') = 'FIRST') THEN

       ld_start_date  := FND_DATE.CANONICAL_TO_DATE(p_start_date);
       ld_end_date    := FND_DATE.CANONICAL_TO_DATE(p_end_date);

       SELECT (ld_end_date - ld_start_date) 
       INTO    ln_number
       FROM    dual;

       ln_loop_number := ln_number + 1;

       FND_FILE.PUT_LINE(fnd_file.log,'Number of children to be submitted = '||ln_loop_number);

       FND_FILE.PUT_LINE(FND_FILE.LOG,'*************************** START ********************************************');

       FOR ln_start_number in 1..ln_loop_number
       LOOP

          lc_error_loc    := 'Submitting the OD: Increment Non-Monthly Consolidated Billing Terms';

          ln_print_option := FND_REQUEST.SET_PRINT_OPTIONS(
                                                           copies    => 0
                                                          );

          ln_req_id       := FND_REQUEST.SUBMIT_REQUEST(application  => 'xxfin'
                                                       ,program      => 'XXAR_INCR_CB_TERM'
                                                       ,description  => ''
                                                       ,start_time   => ''
                                                       ,sub_request  => FALSE
                                                       ,argument1    => ld_start_date
                                                          );
          COMMIT;

          FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID '||':'||ln_Req_ID ||' <--> '|| 'Effective Date ' ||':'||ld_start_date);

          IF ln_req_id > 0 THEN
             lb_wait := fnd_concurrent.wait_for_request
                                       (
                                        ln_req_id,
                                        10,
                                         0,
                                        lc_conc_phase,
                                        lc_conc_status,
                                        lc_dev_phase,
                                        lc_dev_status,
                                        lc_conc_message
                                       );
           END IF;

           ld_present_date  := ld_start_date+1;
           ld_start_date    := ld_present_date;

       END LOOP; 

     END IF; -- lc_req_data

     FND_FILE.PUT_LINE(FND_FILE.LOG,'***************************** END *******************************************');

   EXCEPTION

     WHEN OTHERS THEN
      lc_error_msg       := 'Error occured in OD: AR Increment Consolidated Billing  Terms Wrapper Program 
                            '||lc_error_loc||'. The Oracle error is '||SQLERRM||' : '||SQLCODE;

          XX_COM_ERROR_LOG_PUB.LOG_ERROR(
                                         p_program_type              => 'CONCURRENT PROGRAM'
                                        ,p_program_id                => fnd_global.conc_program_id
                                        ,p_module_name               => 'AR'
                                        ,p_error_location            => 'Error at ' || lc_error_loc
                                        ,p_error_message_count       => 1
                                        ,p_error_message_code        => 'E'
                                        ,p_error_message             => lc_error_msg
                                        ,p_error_message_severity    => 'Warning'
                                        ,p_notify_flag               => 'N'
                                        ,p_object_type               => lc_object_type
                                        ,p_object_id                 => ln_object_id
                                        );

      x_ret_code  := 2;

   END AR_INCREMENT_PROGRAM;

END XX_AR_INC_CONS_BILL_TERMS_PKG;
/
SHOW ERR