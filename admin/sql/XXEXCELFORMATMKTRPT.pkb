create or replace
package BODY XXEXCELFORMATMKTRPT 
IS
-- +============================================================================================|
--    Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XXEXCELFORMATMKTRPT                                                                |
-- |  Description:     OD: CS Marketing Report                                                  |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         13-MAR-2013  HIMANSHU KATHURIA        Initial version                          |
-- |                            |
-- +============================================================================================+

-- +============================================================================================+
-- |                                                       |
-- |  Description: This pkg.procedure will extract the report in excel format                   |
-- |  for concurrent program OD: CS Marketing Report(Excel)                                         
-- |  Name: XXEXCELFORMATMKTRPT.XX_CS_MKT_XLS_PROC                                              |
-- |                                                                                            |
-- |                                                                                            |
-- =============================================================================================|

PROCEDURE XX_CS_MKT_XLS_PROC(
                                   x_err_buff      OUT VARCHAR2
                                  ,x_ret_code      OUT NUMBER
                                  ,p_start_date varchar2
                                  ,p_end_date varchar2
                                  
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
 v_start_date varchar2(50);
 v_end_date varchar2(50);
BEGIN 
v_start_date:=nvl((p_start_date),to_char(trunc(sysdate-7),'RRRR/MON/DD'));
--v_start_date:=p_start_date;
v_end_date:=nvl((p_end_date),to_char(trunc(sysdate-1),'RRRR/MON/DD'));
--v_end_date:=p_end_date;
 lb_print_option := FND_REQUEST.SET_PRINT_OPTIONS(
                                                       printer           => 'XPTR_CRM'
                                                      ,copies            => 1
                                                     );
 

  lb_layout := fnd_request.add_layout(
                                             'XXCRM'
                                            ,'XX_CS_MKT_RPT'
                                            ,'en'
                                            ,'US'
                                            ,'EXCEL'
                                     );

  ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
  application  =>    'XXCRM'
              ,program      => 'XX_CS_MKT_RPT'
               ,start_time   => SYSDATE
              ,sub_request  =>  NULL
              ,argument1    =>  v_start_date
              ,argument2    =>  v_end_date                                       
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


END XX_CS_MKT_XLS_PROC;

END XXEXCELFORMATMKTRPT;
/