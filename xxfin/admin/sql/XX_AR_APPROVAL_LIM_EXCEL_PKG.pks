create or replace
PACKAGE XX_AR_APPROVAL_LIM_EXCEL_PKG
AS
-- +============================================================================+
-- |                  Office Depot - Project Simplify                           |
-- |                                                                            |
-- +============================================================================+
-- | Name         : XX_AR_APPROVAL_LIM_EXCEL_PKG                                |
-- | RICE ID      : QC 19561                                                    |
-- | Description  : This package is the executable of the wrapper program       |
-- |                that used for submitting the                                |
-- |                OD: AR Approval Limits report with the desirable            |
-- |                format of the user, and the default format is EXCEL         |
-- |                                                                            |
-- | Change Record:                                                             |
-- |===============                                                             |
-- |Version   Date              Author              Remarks                     |
-- |======   ==========     =============        =======================        |
-- |  1.0    2012-09-26     Joe Klein             Defect 19561 Initial version. |
-- +============================================================================+

-- +============================================================================+
-- | Name        : XX_AR_APPROVAL_LIM_WRAP_PROC                                 |
-- | Description : The procedure will submit the                                |
-- |               OD: AR Approval Limits program in EXCEL format.              |
-- | Parameters  : none                                                         |
-- | Returns     : x_err_buff,x_ret_code                                        |
-- +============================================================================+

PROCEDURE XX_AR_APPROVAL_LIM_WRAP_PROC( x_err_buff  OUT VARCHAR2
                                       ,x_ret_code  OUT NUMBER
                                      );

END XX_AR_APPROVAL_LIM_EXCEL_PKG;

/