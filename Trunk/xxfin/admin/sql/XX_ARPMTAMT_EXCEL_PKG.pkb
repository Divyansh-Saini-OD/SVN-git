create or replace
PACKAGE  BODY XX_ARPMTAMT_EXCEL_PKG
AS

-- +============================================================================+
-- |                  Office Depot - Project Simplify                           |
-- |                                                                            |
-- +============================================================================+
-- | Name         : XXARPMTAMT_EXCEL_PKG                                        |
-- | RICE ID      : QC 18618                                                    |
-- | Description  : This package is the executable of the wrapper program       |
-- |                that used for submitting the                                |
-- |                OD: AR POS Contactless Payment Amounts report with the      |
-- |                default format of EXCEL                                     |
-- |                                                                            |
-- | Change Record:                                                             |
-- |===============                                                             |
-- |Version   Date              Author              Remarks                     |
-- |======   ==========     =============        =======================        |
-- |  1.0    2012-08-17     Joe Klein             Defect 18618 Initial version. |
-- |  2.0    2013-09-04     Vamshi Katta          Added new parameter           |
-- +============================================================================+

-- +============================================================================+
-- | Name        : XX_ARPMTAMT_WRAP_PROC                                        |
-- | Description : The procedure will submit the                                |
-- |               OD: AR POS Contactless Payment Amounts program in EXCEL      |
-- |               format.                                                      |
-- | Parameters  : p_from_date,p_to_date,p_store_number                         |
-- | Returns     : x_err_buff,x_ret_code                                        |
-- +============================================================================+

PROCEDURE XX_ARPMTAMT_WRAP_PROC( x_err_buff  OUT VARCHAR2
                                ,x_ret_code  OUT NUMBER
                                ,p_from_date  IN VARCHAR2
                                ,p_to_date    IN VARCHAR2
                                ,p_store_number IN VARCHAR2 -- Added new parameter by Vamshi Katta on 04-Sep-2013
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

  --lb_print_option := FND_REQUEST.SET_PRINT_OPTIONS(printer => 'XPTR',copies => 1);
  
  lb_layout := fnd_request.add_layout(
                                      'XXFIN'
                                     ,'XXARPMTAMT'
                                     ,'en'
                                     ,'US'
                                     ,'EXCEL'
                                     );

  ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                                              'XXFIN'
                                             ,'XXARPMTAMT'
                                             ,NULL
                                             ,NULL
                                             ,FALSE
                                             ,p_from_date 
                                             ,p_to_date
                                             ,p_store_number  -- Added new parameter by Vamshi Katta on 04-Sep-2013
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
END XX_ARPMTAMT_WRAP_PROC;
END XX_ARPMTAMT_EXCEL_PKG;

/