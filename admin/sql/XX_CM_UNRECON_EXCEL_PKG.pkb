create or replace
PACKAGE  BODY XX_CM_UNRECON_EXCEL_PKG
AS

-- +============================================================================+
-- |                  Office Depot - Project Simplify                           |
-- |                       WIPRO Technologies                                   |
-- +============================================================================+
-- | Name         : XX_CM_UNRECON_EXCEL_PKG                                     |
-- | RICE ID      : R0542                                                       |
-- | Description  : This package is the executable of the wrapper program       |
-- |                that used for submitting the OD: OD:CM Unreconciled         |
-- |                Lines on Active Accounts Report with the desirable          |
-- |                format of the user, and the default format is EXCEL         |
-- |                                                                            |
-- | Change Record:                                                             |
-- |===============                                                             |
-- |Version   Date              Author              Remarks                     |
-- |======   ==========     =============        =======================        |
-- |Draft 1A  20-FEB-09     Kantharaja Velayutham Initial version               |
-- |                                                                            |
-- |          18-JUL-12     Joe Klein             Defect 18359.  Added          |
-- |                                              parameters                    |
-- |                                              p_transaction_status and      |
-- |                                              p_transaction_code.           |
-- +============================================================================+

-- +============================================================================+
-- | Name        : XX_CM_UNRECON_WRAP_PROC                                      |
-- | Description : The procedure will submit the OD:CM Unreconciled             |
-- |               Lines on Active Accounts Report - Pdf in the specified format|
-- | Parameters  : p_bank_name,p_bank_branch_name,p_bank_account_name,          |
-- |               p_bank_account_number,p_transaction_type,                    |
-- |               p_statement_from_date,p_statement_to_date                    |
-- | Returns     : x_err_buff,x_ret_code                                        |
-- +============================================================================+

PROCEDURE XX_CM_UNRECON_WRAP_PROC( x_err_buff            OUT VARCHAR2
                                  ,x_ret_code            OUT NUMBER
                                  ,p_bank_name           IN VARCHAR2
                                  ,p_bank_branch_name    IN VARCHAR2
                                  ,p_bank_account_name   IN VARCHAR2
                                  ,p_bank_account_number IN VARCHAR2
                                  ,p_transaction_type    IN VARCHAR2
                                  ,p_statement_from_date IN VARCHAR2
                                  ,p_statement_to_date   IN VARCHAR2
                                  ,p_transaction_status  IN VARCHAR2
                                  ,p_transaction_code    IN VARCHAR2
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
                                                   ,copies           => 1
                                                  );
  

  lb_layout := fnd_request.add_layout(
                                      'XXFIN'
                                     ,'XXCMACTIVE'
                                     ,'en'
                                     ,'US'
                                     ,'EXCEL'
                                     );

  ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                                              'XXFIN'
                                             ,'XXCMACTIVE'
                                              ,NULL
                                              ,NULL
                                              ,FALSE
                                              ,p_bank_name           
                                              ,p_bank_branch_name    
                                              ,p_bank_account_name   
                                              ,p_bank_account_number 
                                              ,p_transaction_type    
                                              ,p_statement_from_date 
                                              ,p_statement_to_date 
                                              ,p_transaction_status
                                              ,p_transaction_code
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
END XX_CM_UNRECON_WRAP_PROC;
END XX_CM_UNRECON_EXCEL_PKG;


/