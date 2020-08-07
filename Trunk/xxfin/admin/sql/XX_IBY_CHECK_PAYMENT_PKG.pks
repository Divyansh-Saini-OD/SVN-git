CREATE OR REPLACE PACKAGE XX_IBY_CHECK_PAYMENT_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |           Office Depot Organization                               |
-- +===================================================================+
-- | Name  : XX_IBY_CHECK_PAYMENT_PKG                                  |
-- | Description      :  Package contains program units which will be  | 
-- |                     used in check payment process                 | 
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author           Remarks                   |
-- |=======   ==========   =============    ===========================|
-- |1.0       17-Sep-2013   Satyajeet M     I1207--Initial draft version|
-- |1.1       12-Feb-2014   Veronica M      Added procedure to submit  |
-- |                                        record print for defect 27993|
-- |1.2       19-Feb-2014   Paddy Sanjeevi  Defect 28312               |
-- |1.3       26-Feb-2014   Paddy Sanjeevi  Defect 28602               |
-- +===================================================================+
AS
--+=====================================================================================================+
--|Function    :  record_printer_status                                                                 |
--|Description :  Function which will be used in the business event subscription . This function will   |
--|               submit standard program record print status after the successfull completion of Format|
--|               Payment instructions program                                                          |
--|Parameters  :                                                                                        |
--|    p_sub_guid  input parameter .                                                                    |
--|    p_event     input parameter to get the event details.                                            |
--+=====================================================================================================+
   FUNCTION record_printer_status (
                                   p_sub_guid IN RAW,
                                   p_event    IN OUT WF_EVENT_T
                                 ) RETURN VARCHAR2;

-- V1.1 Added procedure submit_print_status for defect 27993 
--+=====================================================================================================+
--|Procedure   :  submit_print_status                                                                   |
--|Description :  Procedure that will be called from the wrapper concurrent program. This will          |
--|               submit standard program record print status after the successfull completion of Format|
--|               Payment instructions program                                                          |
--|Parameters  :                                                                                        |
--|    p_request_id  input parameter. The request id of the payment format program                      |
--|                                                                                                     |
--+=====================================================================================================+

PROCEDURE submit_print_status ( x_error_buff         OUT VARCHAR2
                               ,x_ret_code           OUT NUMBER
                               ,p_request_id         IN NUMBER);




-- V1.2 Added procedure submit_manual_print_status for defect 
--+=====================================================================================================+
--|Procedure   :  submit_manual_print_status                                                            |
--|Description :  Procedure that will be called from the wrapper concurrent program. This will          |
--|               submit standard program record print status after the successfull                     |
--|Parameters  :                                                                                        |
--|    p_checkrun_id  The checkrun_id of the payment batch for checks                                   |
--|                                                                                                     |
--+=====================================================================================================+

PROCEDURE submit_manual_print_status ( x_error_buff         OUT VARCHAR2
                                      ,x_ret_code           OUT NUMBER
				      ,p_payment_type	     IN VARCHAR2
                                      ,p_pay_instruc_id      IN NUMBER);

END XX_IBY_CHECK_PAYMENT_PKG;
/
