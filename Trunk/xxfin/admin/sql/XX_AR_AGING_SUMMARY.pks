CREATE OR REPLACE PACKAGE xx_ar_aging_bucket_summary 
-- +===================================================================+
-- | Name  : xx_ar_aging_bucket_summary                                |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author          Remarks                    |
-- |=======   ==========   =============   ============================|
-- |1.0       08-APR-2014  Veronica M      Initial version for defect  |
-- |                                       29220 to provide AR Aging   |
-- |                                       bucket summary.             |
-- +===================================================================+
AS

PROCEDURE xx_aging_bal_proc ( x_err_buff            OUT VARCHAR2
                             ,x_ret_code            OUT NUMBER
                             ,p_as_of_date          IN  VARCHAR2);

END xx_ar_aging_bucket_summary;
/