SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_CM_CB_AIA_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

create or replace PACKAGE  BODY XX_CM_CB_AIA_PKG  
AS

-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                       WIPRO Technologies                               |
-- +========================================================================+
-- | Name : XX_CM_CB_AIA_PKG                                                |
-- | RICE ID :  R0541                                                       |
-- | Description :This package is the executable of the wrapper program     |
-- |              that used for submitting the OD: CM Closing Balance
 --|               on Active Internal Bank Accounts of the user,            |
-- |                                                                        |
-- |              and the default format is EXCEL                           |
-- |                                                                        |
-- | Change Record:                                                         |
-- |===============                                                         |
-- |Version   Date              Author              Remarks                 |
-- |======   ==========     =============        =======================    |
-- |Draft 1A  09-FEB-09     Usha Ramachandran        Initial version        |
-- |                                                                        |
-- +========================================================================+

-- +=====================================================================+  |
-- | Name :  XX_CM_CB_AIA_PKG                                               |
-- | Description : The procedure will submit the OD: CM Closing Balance     |
 --               on Active Internal Bank Accounts           |
-- | Parameters : P_BANK_NAME,P_BANK_ACCOUNT_NAME,P_BANK_BRANCH_NAME,       |
-- |               P_STATEMENT_NUMBER                   |
-- | Returns :  x_err_buff,x_ret_code                                       |
-- +=====================================================================+

PROCEDURE XX_CM_CB_AIA_PROC(
                                          x_err_buff           OUT VARCHAR2
                                         ,x_ret_code           OUT NUMBER
				         ,P_BANK_NAME		IN  VARCHAR2
				         ,P_BANK_ACCOUNT_NAME	 IN VARCHAR2
					 ,P_BANK_BRANCH_NAME  IN VARCHAR2
					 ,P_STATEMENT_NUMBER   IN VARCHAR2
                 
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
                                     ,'XXCMCBAIA'
                                     ,'en'
                                     ,'US'
                                     ,'EXCEL'
                                     );
 

  ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                                              'XXFIN'
                                             ,'XXCMCBAIA'
                                             ,NULL
                                             ,NULL
                                             ,FALSE
					    ,P_BANK_NAME	
					    ,P_BANK_ACCOUNT_NAME
					    ,P_BANK_BRANCH_NAME
					    ,P_STATEMENT_NUMBER 
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
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Completed Sucessfully ');


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



END XX_CM_CB_AIA_PROC;

END XX_CM_CB_AIA_PKG;
/

SHO ERR;