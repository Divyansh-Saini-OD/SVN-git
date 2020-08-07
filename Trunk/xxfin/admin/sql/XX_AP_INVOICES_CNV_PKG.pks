--WHENEVER SQLERROR CONTINUE
REM ============================================================================
REM Create the package:
REM ============================================================================
PROMPT Creating package APPS.XX_AP_INVOICES_CNV_PKG . . .

CREATE OR REPLACE PACKAGE APPS.XX_AP_INVOICES_CNV_PKG 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                            Providge                               |
-- +===================================================================+
-- | Name             :    XX_AP_INVOICES_CNV_PKG                     |
-- | Description      :    Package for AP Open Invoice Conversion      |
-- |                                                                   |
-- |                                                                   | 
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author              Remarks                 |
-- |=======   ===========  ================    ========================|
-- |1.0       02-JAN-2007  Sarat Uppalapati    Initial version         |
-- | 1.0      02-JUN-2007  Sarat Uppalapati    Added Validation        |
-- | 1.0      07-NOV-2007  Sarat Uppalapati    Updated Table name in   |
-- |                                            comments               |
-- +===================================================================+

IS
-- +===================================================================+
-- | Name : AP_INVOICES_MASTER_CNV                                     |
-- | Description : To create the batches of AP transactions from the   |
-- |      custom staging table XX_AP_INV_HDR_INTF_CNV_STG based on the|
-- |      Invoice type name. It will call the "OD: AP Open Invoices    |
-- |    Conversion Child Program", "OD Conversion Exception Log        |
-- |      Report", "OD Conversion Processing Summary Report" for each  |
-- |      batch. This procedure will be the executable of Concurrent   |
-- |      program "OD: AP Open Invoices Conversion Master Program"     |
-- | Parameters : x_error_buff, x_ret_code,p_process_name,             |
-- |              ,p_validate_only_flag,p_reset_status_flag            |
-- +===================================================================+
PROCEDURE AP_INVOICES_MASTER (
   x_error_buff            OUT      VARCHAR2
   ,x_ret_code             OUT      NUMBER
   ,p_process_name         IN       VARCHAR2
   ,p_validate_only_flag   IN       VARCHAR2
   ,p_reset_status_flag    IN       VARCHAR2
   );

-- +===================================================================+
-- | Name : AP_INVOICES_CHILD_CNV                                      |
-- | Description :To perform  validations and Import of Open Invoices  |
-- |          information from Peoplesoft to AP systems for each batch.|
-- |          This procedure will be the executable of Concurrent      |
-- |          Program "OD : AP Open Invoices Conversion Child Program" |
-- | Parameters : x_error_buff, x_ret_code,p_process_name,             |
-- |              ,p_validate_only_flag,p_reset_status_flag,p_batch_id |
-- +===================================================================+


PROCEDURE AP_INVOICES_CHILD(
    x_error_buff         OUT VARCHAR2
   ,x_ret_code           OUT NUMBER
   ,p_process_name       IN VARCHAR2
   ,p_validate_only_flag IN VARCHAR2
   ,p_reset_status_flag  IN VARCHAR2
   ,p_batch_id           IN NUMBER
   );


-- +===================================================================+
-- | Name : AP_INVOICES_HOLD_CNV                                       |
-- | Description :To perform  validations and Import of Open Invoices  |
-- |      old information from Peoplesoft to AP systems for each batch.|
-- |          This procedure will be the executable of Concurrent      |
-- |          Program "OD : AP Open Invoices Hold Conversion  Program" |
-- | Parameters : x_error_buff, x_ret_code                             |
-- |                                                                   |
-- +===================================================================+ 
PROCEDURE AP_INVOICES_HOLD(
    x_error_buff         OUT VARCHAR2
   ,x_ret_code           OUT NUMBER
   ,p_process_name       IN VARCHAR2);
PROCEDURE AP_CA_INVOICES(
    x_error_buff         OUT VARCHAR2
   ,x_ret_code           OUT NUMBER
   );
   
  
END XX_AP_INVOICES_CNV_PKG;
/

