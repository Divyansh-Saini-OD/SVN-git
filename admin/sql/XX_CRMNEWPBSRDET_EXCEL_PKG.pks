create or replace
PACKAGE XX_CRMNEWPBSRDET_EXCEL_PKG
AS
-- +============================================================================+
-- |                  Office Depot - Project Simplify                           |
-- |                                                                            |
-- +============================================================================+
-- | Name         : XX_CRMNEWPBSRDET_EXCEL_PKG                                  |
-- | RICE ID      : QC 17836                                                    |
-- | Description  : This package is the executable of the wrapper program       |
-- |                that used for submitting the                                |
-- |                OD: CRM Private Brand SR Details Report with the desirable  |
-- |                format of the user, and the default format is EXCEL         |
-- |                                                                            |
-- | Change Record:                                                             |
-- |===============                                                             |
-- |Version   Date              Author              Remarks                     |
-- |======   ==========     =============        =======================        |
-- |  1.0    2012-08-29     Joe Klein             Defect 17836 Initial version. |
-- +============================================================================+

-- +============================================================================+
-- | Name        : XX_CRMNEWPBSRDET_WRAP_PROC                                   |
-- | Description : The procedure will submit the                                |
-- |               OD: CRM Private Brand SR Details Report program in EXCEL     |
-- |               format.                                                      |
-- | Parameters  : p_from_date                                                  |
-- |               p_to_date                                                    |
-- |               p_group_name                                                 |
-- |               p_sr_type                                                    |
-- |               p_problem_code                                               |
-- |               p_resolution_code                                            |
-- |               p_csr                                                        |
-- |               p_channel                                                    |
-- |               p_status                                                     |
-- |               p_sr_number                                                  |
-- |               p_to_date                                                    |
-- | Returns     : x_err_buff,x_ret_code                                        |
-- +============================================================================+

PROCEDURE XX_CRMNEWPBSRDET_WRAP_PROC( x_err_buff       OUT VARCHAR2
                                     ,x_ret_code       OUT NUMBER
                                     ,p_from_date       IN VARCHAR2
                                     ,p_to_date         IN VARCHAR2
                                     ,p_group_name      IN VARCHAR2
                                     ,p_sr_type         IN VARCHAR2
                                     ,p_problem_code    IN VARCHAR2
                                     ,p_resolution_code IN VARCHAR2
                                     ,p_csr             IN VARCHAR2
                                     ,p_channel         IN VARCHAR2
                                     ,p_status          IN VARCHAR2
                                     ,p_sr_number       IN VARCHAR2
                                    );

END XX_CRMNEWPBSRDET_EXCEL_PKG;

/