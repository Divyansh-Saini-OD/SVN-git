SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AR_TENDER_AMT_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE or REPLACE PACKAGE  BODY XX_AR_TENDER_AMT_PKG  
AS

-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                       WIPRO Technologies                               |
-- +========================================================================+
-- | Name        :XX_AR_TENDER_AMT_PKG                                      |
-- | RICE ID     :E1022                                                    |
-- | Description :This package is the executable of the wrapper program     |
-- |              that used for submitting the OD: AR Payment Extraction    |
 --|              Report and the default format is XML                      |
-- |                                                                        |
-- | Change Record:                                                         |
-- |===============                                                         |
-- |Version   Date              Author              Remarks                 |
-- |======   ==========     =============        =======================    |
-- |Draft 1A  06-JUN-09     Ganga Devi R        Initial version             |
-- +========================================================================+

-- +=====================================================================+  |
-- | Name        : XX_AR_TENDER_AMT_PROC                                    |
-- | Description : The procedure will submit the OD: AR Payment Extraction  |
 --|               Report                                                   |
-- | Parameters  : P_TRXN_DATE_FROM,P_TRXN_DATE_TO                          |
-- | Returns     : x_err_buff,x_ret_code                                    |
-- +========================================================================+

PROCEDURE XX_AR_TENDER_AMT_PROC(
                                  x_err_buff           OUT VARCHAR2
                                 ,x_ret_code           OUT NUMBER
                                 ,P_TRXN_DATE_FROM     IN  VARCHAR2
                                 ,P_TRXN_DATE_TO       IN  VARCHAR2
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
   lc_trx_date_to       VARCHAR2(50);

BEGIN

lc_trx_date_to := TO_CHAR(TO_DATE(P_TRXN_DATE_TO,'YYYY/MM/DD HH24:MI:SS'),'YYYY/MM/DD')||' 23:59:59';

lb_print_option := FND_REQUEST.SET_PRINT_OPTIONS(
                                                   printer           => 'XPTR'
                                                   ,copies           => 1
                                                  );
  
  
  lb_layout := fnd_request.add_layout(
                                      'XXFIN'
                                     ,'XXARGIFTCARDEXTRACTION'
                                     ,'en'
                                     ,'US'
                                     ,'EXCEL'
                                     );
 

  ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                                              'XXFIN'
                                             ,'XXARGIFTCARDEXTRACTION'
                                             ,NULL
                                             ,NULL
                                             ,FALSE
                                             ,P_TRXN_DATE_FROM
                                             ,lc_trx_date_to
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

    FND_FILE.PUT_LINE(FND_FILE.LOG,'The report has been submitted and the request id is: '||ln_request_id||' Completed Sucessfully ');
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



END XX_AR_TENDER_AMT_PROC;

END XX_AR_TENDER_AMT_PKG;
/

SHO ERR;