CREATE OR REPLACE PACKAGE BODY XXEXCELFORMAT AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XXEXCELFORMAT                                                                      |
-- |  Description:     OD: AR Flat Discount Table - Excel                                       |
-- |  Description:     OD: AR Receipt Posting Timing Variances - Excel                          |
-- |  Description:     OD: AR WC Failed Transactions Report - Excel                             |                        
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         05-FEB-2013  DIVYA SIDHAIYAN        Initial version                            |
-- +============================================================================================+

-- +============================================================================================+
-- |  Name: XXEXCELFORMAT.XX_AR_FDT_PROC                                                        |
-- |  Description: This pkg.procedure will extract the report in excel format                   |
-- |  for concurrent program OD: AR Flat Discount Table                                         |
-- |  Name: XXEXCELFORMAT.XX_AR_RPTVRPT_PROC                                                    |
-- |  Description: This pkg.procedure will extract the report in excel format                   |
-- |  for concurrent program OD: AR Receipt Posting Timing Variances                            |
-- |  Name: XXEXCELFORMAT.XXARWCRPT_PROC                                                        |
-- |  Description: This pkg.procedure will extract the report in excel format                   |
-- |  for concurrent program OD: AR WC Failed Transactions Report                               |                       
-- =============================================================================================|

PROCEDURE XX_AR_FDT_PROC( x_err_buff      OUT VARCHAR2
                         ,x_ret_code      OUT NUMBER
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
   lb_print_option      BOOLEAN;

BEGIN

  
   lb_layout := fnd_request.add_layout(  'XXFIN'
                                        ,'XXARFDTRPT'
                                        ,'en'
                                        ,'US'
                                        ,'EXCEL'
                                       );

   ln_request_id := FND_REQUEST.SUBMIT_REQUEST(   'XXFIN'
                                                 ,'XXARFDTRPT'
                                                 ,NULL
                                                 ,NULL
                                                 ,FALSE
                                              );

   COMMIT;

   lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST(  request_id  => ln_request_id
                                                     ,interval    => '2'
                                                     ,max_wait    => ''
                                                     ,phase       => lc_phase
                                                     ,status      => lc_status
                                                     ,dev_phase   => lc_devphase
                                                     ,dev_status  => lc_devstatus
                                                     ,message     => lc_message
                                                   );

    IF ln_request_id <> 0   THEN

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
    
EXCEPTION WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'EXCEPTION : ' || SQLERRM);

END XX_AR_FDT_PROC;

PROCEDURE XX_AR_RPTVRPT_PROC( x_err_buff      OUT VARCHAR2
                             ,x_ret_code      OUT NUMBER
                             ,p_period_name   IN  VARCHAR2
                             ,p_receipt_type  IN  VARCHAR2
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
   lb_print_option      BOOLEAN;

BEGIN

    lb_layout := fnd_request.add_layout( 'XXFIN'
                                        ,'XXARRPTVRPT'
                                        ,'en'
                                        ,'US'
                                        ,'EXCEL'
                                       );

    ln_request_id := FND_REQUEST.SUBMIT_REQUEST( 'XXFIN'
                                                ,'XXARRPTVRPT'
                                                ,NULL
                                                ,NULL
                                                ,FALSE
                                                ,p_period_name 
                                                ,p_receipt_type
                                               );

    COMMIT;

    lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST(     request_id  => ln_request_id
                                                         ,interval    => '2'
                                                         ,max_wait    => ''
                                                         ,phase       => lc_phase
                                                         ,status      => lc_status
                                                         ,dev_phase   => lc_devphase
                                                         ,dev_status  => lc_devstatus
                                                         ,message     => lc_message
                                                     );

    IF ln_request_id <> 0   THEN

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

EXCEPTION WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'EXCEPTION : ' || SQLERRM);
    
END XX_AR_RPTVRPT_PROC;

PROCEDURE XXARWCRPT_PROC(
                                   x_err_buff      OUT VARCHAR2
                                  ,x_ret_code      OUT NUMBER	
                                  ,P_START_DATE IN VARCHAR2
                                  ,P_END_DATE IN VARCHAR2									  
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
   lb_print_option      BOOLEAN;

BEGIN

  lb_print_option := FND_REQUEST.SET_PRINT_OPTIONS(
                                                       printer           => 'XPTR'
                                                      ,copies            => 1
                                                     );



  lb_layout := fnd_request.add_layout(
                                             'XXFIN'
                                            ,'XXARWCRPT'
                                            ,'en'
                                            ,'US'
                                            ,'EXCEL'
                                     );

  ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                                              'XXFIN'
                                             ,'XXARWCRPT'
                                             ,NULL
                                             ,NULL
                                             ,FALSE       
                                             ,P_START_DATE
                                             ,P_END_DATE											 
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

IF ln_request_id <> 0   THEN

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

EXCEPTION WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'EXCEPTION : ' || SQLERRM);

END XXARWCRPT_PROC;


END XXEXCELFORMAT;

/

SHOW ERROR