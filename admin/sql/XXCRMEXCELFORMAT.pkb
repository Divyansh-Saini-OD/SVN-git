create or replace
PACKAGE BODY XXCRMEXCELFORMAT AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XXCRMEXCELFORMAT                                                                   |
-- |  Description:     OD: TDS Vendor Subscription Report                                       |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         14-MAR-2013  POOJA MEHRA       Initial version                                 |
-- +============================================================================================+

-- +============================================================================================+
-- |  Name: XXCRMEXCELFORMAT.XX_CS_VND_SUBS_RPT                                                 |
-- |  Description: This pkg.procedure will extract the report in excel format                   |
-- |  for concurrent program OD: TDS Vendor Subscription Report (Excel)                                 | 
-- =============================================================================================|

PROCEDURE XX_CS_VND_SUBS_RPT( x_err_buff      OUT VARCHAR2
                             ,x_ret_code      OUT NUMBER
                             ,start_date      IN  VARCHAR2
                             ,end_date  	    IN  VARCHAR2
                            )
AS
  p_start_date    VARCHAR2(20);
  p_end_date    VARCHAR2(20);
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
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'DATE: '||start_date);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'DATE: '||fnd_date.canonical_to_date(start_date));

   lb_print_option := FND_REQUEST.SET_PRINT_OPTIONS(
                                                       printer           => 'XPTR_CRM'
                                                      ,copies            => 1
                                                     );
  
   lb_layout := fnd_request.add_layout(  'XXCRM'
                                        ,'XX_CS_VND_SUBS_RPT'
                                        ,'en'
                                        ,'US'
                                        ,'EXCEL'
                                       );
                                       

p_start_date:=nvl((start_date),to_char((trunc(trunc(sysdate,'MM')-1,'MM')), 'RRRR/MM/DD'));
p_end_date:=nvl((end_date),to_char((trunc(sysdate,'MM')-1), 'RRRR/MM/DD'));


   ln_request_id := FND_REQUEST.SUBMIT_REQUEST(   application 	=> 'XXCRM'
												, program 		=> 'XX_CS_VND_SUBS_RPT'
												, description 	=> NULL
												, sub_request 	=> FALSE
												, argument1 	=> p_start_date 
												, argument2 	=> p_end_date 
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

END XX_CS_VND_SUBS_RPT;

END XXCRMEXCELFORMAT;
/