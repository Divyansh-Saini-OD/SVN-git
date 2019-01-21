create or replace
PACKAGE XXEXCELFORMATMKTRPT
AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XXCRMEXCELFORMAT Package Specification                                             |
-- |  Description:     OD: CS Marketing Report                              |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author                   Remarks                                          |
-- | =========   ===========  =============          =========================================  |
-- | 1.0         13-MAR-2013  HIMANSHU KATHURIA       Initial version                                |
-- +============================================================================================+

-- +============================================================================================+
-- |  Name: XXEXCELFORMATMKTRPT.XX_CS_MKT_XLS_PROC                                                |
-- |  Description: This pkg.procedure will extract the report in excel format                   |
-- |  for concurrent program OD: CS Marketing Report(Excel)                                |
-- =============================================================================================|
PROCEDURE XX_CS_MKT_XLS_PROC(
    x_err_buff OUT VARCHAR2 ,
    x_ret_code OUT NUMBER ,
    p_start_date IN varchar2 ,
    p_end_date   IN varchar2 );
END XXEXCELFORMATMKTRPT ;
/